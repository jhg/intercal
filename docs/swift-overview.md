# Swift, in shape

The Swift compiler (`swiftc`) lives at <https://github.com/swiftlang/swift> (the project moved from `apple/swift` to the `swiftlang` organisation in mid-2024). Swift is Apple's modern systems-language project, used for application development on Apple platforms and increasingly for server-side code, machine-learning frameworks, and embedded targets. The compiler is interesting in this Part for one reason above others: SIL.

SIL stands for Swift Intermediate Language. It is a SSA-form IR that sits between Swift's typed AST and LLVM IR, and it carries language-level semantics that no other production IR carries to the same degree. Reference counting operations are first-class instructions. Generic functions exist as polymorphic SIL definitions before specialisation. Protocols and witness tables are explicit. Memory ownership is annotated. Errors and traps are visible.

This means SIL passes can do things ordinary LLVM IR passes cannot. ARC optimisation eliminates redundant retain/release pairs by reasoning about ownership at SIL level, before LLVM ever sees a load or store. Generic specialisation produces a concrete instantiation as a SIL function, avoiding LLVM's per-translation-unit duplication. Protocol dispatch is devirtualised at SIL level when types are known, before the call has been lowered to an indirect jump.

For a reader, Swift is the canonical example of "preserve language semantics in the IR". The contrast with rustc (which strips Rust-level information into MIR and then LLVM IR, with the borrow checker doing its work on MIR) and Go (which has SSA but no language-specific high-level IR) makes Swift's choice visible.

## The pipeline

A Swift source file goes through this sequence:

    source                 program.swift
      → tokens             lib/Parse/Lexer.cpp
      → AST                lib/Parse/Parser.cpp + lib/AST/
      → Sema-checked AST   lib/Sema/
      → Raw SIL            lib/SILGen/
      → Canonical SIL      lib/SILOptimizer/Mandatory/
      → Optimised SIL      lib/SILOptimizer/ (under -O)
      → LLVM IR            lib/IRGen/
      → machine code       LLVM
      → linked binary      LLD or system linker

Eight stages, two distinct SIL forms, an LLVM-IR step, then LLVM's own backend pipeline. Each transition is explicit and named.

The frontend (Parse + AST + Sema) is conventional but rich. Swift's AST captures the source quite faithfully; module structure, inheritance, generic constraints, protocols, property wrappers all live as AST nodes. Sema typechecks the AST, resolving overloads, inferring types, applying coercions, checking conformances.

SILGen lowers the typed AST to raw SIL. "Raw" means the SIL has not yet been canonicalised; it may contain constructs that the rest of the pipeline rejects. Mandatory passes turn raw SIL into canonical SIL, fixing those issues and emitting diagnostics.

After canonical SIL, the optional Performance passes (-O) optimise the SIL. Then IRGen translates SIL to LLVM IR, which goes through LLVM's pipeline, ending in machine code.

## Sema and the constraint solver

Swift's type checker, in `lib/Sema/`, is constraint-based. Each expression generates a constraint system: the type of `e` is unknown; the type of `e.foo()` requires `e`'s type to have a `foo` method; the type of `1 + x` requires the result type to satisfy `Numeric` constraints; and so on.

The constraint solver searches for a substitution that satisfies all constraints, with backtracking when ambiguities arise. Where multiple overloads of `+` exist, the solver tries each, propagating constraints, picking the one that succeeds (or reporting ambiguity if multiple succeed).

The sophistication of the solver is the source of two kinds of pleasures and two kinds of pain. The pleasures: Swift can infer types in DSL-like contexts (SwiftUI, result builders) where many languages would require annotations. The function `View.background(_:)` overloads on multiple types; the solver picks the right one based on what the surrounding context needs.

The pains: type-checking time can blow up. For complex expressions, the solver may explore many possibilities before settling. The infamous "expression too complex" errors come from this; when the solver hits a configurable timeout, it gives up and asks the user to break the expression apart. Swift evolution has spent years making the solver faster and more predictable; it remains one of the most CPU-intensive parts of the compiler.

## SILGen: AST to raw SIL

`lib/SILGen/` lowers the typed AST to raw SIL. The lowering preserves Swift semantics in SIL form:

- A class has a v-table (lookup of inherited methods).
- A protocol has a witness table per conforming type, holding pointers to the protocol's required methods for that type.
- A reference assignment becomes `strong_retain`/`strong_release` instructions explicitly.
- A captured variable becomes either a closure box (if it is captured mutably and lives longer than the closure) or a direct capture (if it is shared by value).
- An optional value becomes a tagged union with `enum_element` instructions.

The SIL after SILGen is "raw" because some constructs are tentative. The compiler may have emitted instructions that are valid in SIL grammar but disallowed in canonical SIL: for instance, a `mark_uninitialized` instruction marking a variable as not-yet-initialised, which the Definite Initialisation pass must resolve before any code runs.

## Mandatory SIL passes

The mandatory passes (`lib/SILOptimizer/Mandatory/`) are required for correctness. They run regardless of optimisation level. Their job is to turn raw SIL into canonical SIL, emitting diagnostics where the source program is incorrect.

Notable mandatory passes:

- **Definite Initialisation**: every variable must be assigned before it is used. The pass tracks initialisation through control flow and emits errors where the rule is violated.
- **Diagnostic Constant Propagation**: constant folds, with the side effect of detecting overflow in arithmetic that would crash at runtime.
- **Mandatory Inlining**: inlines functions marked `@_transparent` (a compiler-internal annotation, not user-facing). These are functions whose semantics are part of the language definition; they cannot be left as calls.
- **Diagnose Invalid Escaping Captures**: closures that capture variables in ways the language disallows are caught here.

The split between mandatory and performance passes is a Swift-specific design choice worth noting. Mandatory passes are part of the language definition; running them produces canonical SIL, which is what the rest of the compiler defines its semantics on. Performance passes are pure optimisations; they do not change observable behaviour and can be skipped under -O0.

For a reader, this is the cleanest example of "correctness vs performance" passes being explicitly distinguished in the pass pipeline. Most compilers run the same passes at all optimisation levels and rely on heuristics to skip expensive ones at -O0; Swift draws a hard line.

## Performance SIL passes (under -O)

The performance passes (`lib/SILOptimizer/`) include:

- **GenericSpecialization**: a generic function `func max<T: Comparable>(_ a: T, _ b: T) -> T` is one definition in SIL. When called with `Int`, the specialiser produces a separate `max_specialized_to_Int` SIL function with type substitutions applied. The original generic version remains, for use in non-specialisable contexts.
- **Devirtualization**: a method call on a class becomes a v-table lookup; if the receiver's exact type is known statically, the lookup is replaced by a direct call.
- **ARC Optimisation**: the headline pass. Every reference assignment in raw SIL has explicit `strong_retain`/`strong_release` operations. ARC optimisation analyses the lifetimes of references and eliminates retain/release pairs that are guaranteed to balance. The result is significant runtime speedup for reference-heavy code.
- **Inlining**: budget-based, similar to GHC's or Go's.
- **Closure Specialisation**: when a closure is passed to a function and the function is called with that specific closure, the compiler can specialise the function for that closure, sometimes inlining the closure body.
- **Cross-Module Optimisation (CMO)**: with `-cross-module-optimization`, optimisations that cross module boundaries are enabled. Like LTO but specific to SIL.
- **SROA, mem2reg, simplify-cfg, dead-code-elim**: conventional passes adapted for SIL.

The most distinctive of these is ARC optimisation. Reading the code in `lib/SILOptimizer/Transforms/ARCOptimization/` is a way to see how reference-counting elimination really works. The algorithms (RR-Code-Motion, Lifetime Lengthening, Block Argument Removal) have a literature of their own, originally Apple's invention.

## Generics: specialisation vs preservation

Generics in Swift are interesting because they survive into SIL.

When a Swift function is generic, SILGen produces one polymorphic SIL function. The body operates on values of "abstract type" T (or more precisely, takes an extra parameter that points to type metadata). Calls into the function pass the concrete type's metadata; operations on values of type T use the metadata to dispatch.

This contrasts with C++, which monomorphises generics at instantiation: each `vector<int>` and `vector<string>` is a separate set of template instantiations duplicated through the codebase. Swift's polymorphic SIL does not require that duplication. The runtime metadata makes the polymorphic version work.

But polymorphic SIL is slower than monomorphised SIL: every operation on a T value goes through metadata dispatch. So the performance pass `GenericSpecialization` looks for call sites where the concrete type is known and produces a specialised SIL function for them.

The result: Swift gets the binary-size benefits of polymorphic generics by default and the speed of monomorphisation where it matters. The tradeoff is per-call-site, computable, and tuneable.

For a reader, this is the most concrete demonstration of why preserving language semantics in the IR matters. A different compiler that lowered generics at SILGen time (say, with a C++-style monomorphiser) could not later choose to keep them polymorphic when binary size mattered. SIL keeps the option open.

## Witness tables and protocol dispatch

A Swift protocol describes a set of methods (and types) a type must provide. A type conforms to a protocol by declaring an `extension Foo: Bar { ... }` block. The compiler produces a "witness table" for the (Foo, Bar) pair: a record with pointers to Foo's implementation of each Bar method.

In SIL, a protocol-typed value is an "existential": a tagged record containing the value plus a pointer to its witness table. When code calls a protocol method on the existential, SIL emits an `apply` through the witness table.

This is similar to Rust's trait objects (`dyn Trait`) but explicit at the SIL level. A trait object in Rust is an LLVM-level construct, fat pointer plus vtable. A Swift existential is a SIL-level construct visible to optimisations.

Optimisations can devirtualise: if the existential's underlying type is known, the witness lookup is replaced by a direct call. They can specialise: if the same existential is used multiple times, the witness can be hoisted. They can avoid existential allocation entirely: if the existential never escapes, it can be stack-allocated.

Reading SIL output (which the compiler can dump with `-emit-sil`) on a small Swift program with `protocol`s makes this all visible. Each `apply` instruction is annotated with witness or direct-call information.

## IRGen: SIL to LLVM IR

After SIL optimisation, IRGen (`lib/IRGen/`) lowers SIL to LLVM IR. This is where Swift's high-level constructs become standard LLVM:

- Class instances become heap-allocated structs with a v-table pointer.
- ARC operations become calls to runtime functions (`swift_retain`, `swift_release`).
- Metadata accesses become loads from the type metadata table.
- Witness lookups become calls through witness tables (loads + indirect call).
- Generic instantiations either become specialised functions (if specialised earlier) or remain polymorphic with metadata-driven dispatch.

LLVM then optimises the resulting IR through its conventional pipeline. The optimisations LLVM runs are mostly orthogonal to what SIL did, focused on machine-level concerns: register pressure, instruction scheduling, loop transformations, vectorisation.

This two-stage optimisation (SIL passes for language-level, LLVM passes for machine-level) is one of Swift's defining architectural choices. The benefit: each level optimises what it understands. The cost: more total compiler work, longer compile times, two optimisers to maintain.

## Recent additions: ownership, noncopyable types, OSSA

Swift 6 promoted ownership annotations from compiler-internal SIL concepts to first-class language features. The relevant proposals:

- **SE-0377: parameter ownership modifiers** introduced `borrowing` and `consuming` as parameter modifiers, mutually exclusive with each other and with `inout`. `borrowing` is a temporary read-only reference. `consuming` transfers ownership; the original binding is invalidated, and the callee may even mutate the value.
- **SE-0390: noncopyable types** (`~Copyable`) lets a type opt out of the implicit `Copyable` conformance every type otherwise has. Noncopyable types model resources whose ownership must not be silently duplicated (file handles, mutexes, hardware buffers).
- **SE-0432: noncopyable pattern matching** added borrowing/consuming patterns in `switch`.

For copyable types, `borrowing` and `consuming` are mostly compiler hints. For noncopyable types they are part of the API contract and the compiler enforces single-consumption on every path.

**OSSA** (Ownership SSA) is the SIL form coming out of SILGen since Swift 6. Each non-trivial SIL value is statically tagged `@owned`, `@guaranteed`, `@unowned`, or `@none`, and the verifier proves that owned values are consumed exactly once on every path. OSSA is being pushed further down the optimiser pipeline (more passes operate on OSSA before OSSA is lowered to plain SSA), which catches use-after-free and leak bugs in the optimisation passes themselves rather than in user code. Noncopyable types are checked entirely in OSSA.

The contrast with Rust:

- Rust enforces ownership at the type level, in the borrow checker on MIR, before any IR transformation.
- Swift enforces ownership at the IR level, in the OSSA verifier, after SILGen.
- Both produce the same correctness guarantee for the user. The implementation strategies differ: Rust burns the cost in the type system; Swift burns it in the IR verifier.

## Embedded Swift

Embedded Swift is a *language subset* (not a separate dialect): code that compiles in Embedded Swift must also compile in regular Swift with identical behaviour. The compiler disables runtime reflection, library evolution, generics that need runtime metadata, and most of the dynamic-dispatch machinery to shrink the runtime footprint to fit microcontrollers.

A common misreporting: "Embedded Swift removes ARC". Not quite. Refcount metadata is still 4 or 8 bytes per class instance; weak/unowned still uses side tables. The "no ARC" framing applies to specific embedded modes targeting microcontrollers where the user opts to use only value types and avoid classes. ARC itself is not removed from the language.

Embedded Swift is positioned as a long-term subset, with active 2024-2026 work on better diagnostics and on Swift for embedded Linux (GSoC 2025 project).

## Governance and the swiftlang migration

Apple announced the move to the dedicated `github.com/swiftlang` organization on 10 June 2024. The migration was phased: `swift-evolution` first, then the rest of the repos. Governance now spans multiple steering groups: the Core Team augmented by Language, Platform (new in 2024), and the recently-formed Ecosystem steering group focused on developer experience. The split signals what Apple has stated explicitly: Swift is no longer an Apple-only language project.

For somebody reading the chapter and wanting to contribute, the practical implication is that the repo URLs in older documentation are now stale; everything has moved to `swiftlang/*`. The `swift-driver` package is at `swiftlang/swift-driver`; SwiftPM is at `swiftlang/swift-package-manager`.

## The runtime

Swift has a runtime, in C++, providing:

- ARC primitives (`swift_retain`, `swift_release`, weak/unowned variants).
- Dynamic dispatch helpers (witness lookup, generic dispatch).
- Type metadata (the structures the compiler emits for each type).
- Error handling (try/throw stack unwinding).
- Exclusivity enforcement (Swift's runtime law-of-exclusivity: a value being modified cannot be observed simultaneously through another path).
- The standard-library helpers that cannot be expressed in Swift itself.

The runtime is ~50,000 lines, in `stdlib/public/runtime/` and `stdlib/public/SwiftShims/`. Most of it is C++ for performance, with carefully minimal interaction with the Swift type system.

The standard library proper is in `stdlib/public/core/`, written in Swift itself. `Array`, `Dictionary`, `String`, `Optional`: all defined in Swift, leaning on `unsafe` primitives where direct memory access or type conversion is required. The compiler treats certain library types specially (e.g., `Array` is known to the compiler so that array-literal expressions can be lowered efficiently), but the implementation is still Swift code.

## Comparison with other compilers

| Aspect | Swift | rustc | Go |
|--------|-------|-------|-----|
| High-level IR | SIL (SSA, with semantic annotations) | MIR (SSA, after borrowck) | SSA (no Go-specific high-level IR, ir AST is conventional) |
| Memory management | ARC (compile-time inserted, optimised at SIL level) | Ownership at type level (no runtime) | Concurrent GC |
| Generics | Polymorphic SIL with optional specialisation | Monomorphisation at MIR level | Type parameters since 1.18, monomorphised |
| Backend | LLVM | LLVM (default), Cranelift, GCC | Self (no LLVM) |
| Distinguishing IR | SIL with explicit ARC and witness tables | MIR with explicit moves and borrows | none Go-specific |
| Codebase | ~3M lines C++ | ~3M Rust | ~50K Go (compile only) |

Swift's distinguishing trait is the SIL layer. A reader who learns Swift learns "what does an IR look like when it carries the language's semantic features". A reader who only learns LLVM IR misses this; LLVM IR is deliberately language-agnostic.

## How Swift compares to our INTERCAL compiler

We have no SIL-equivalent. Our pipeline goes from parse tree directly to assembly, with no IR step that preserves INTERCAL-specific semantics.

What would an INTERCAL SIL look like? Plausibly: an IR with explicit `STASH`/`RETRIEVE` as instructions, explicit `ABSTAIN` flags as state, the politeness rule encoded as a node attribute. Optimisations could then operate on this IR: dead-flag elimination becomes "if this statement's `ABSTAIN` flag is provably never set, eliminate the check". Constant folding at INTERCAL semantic level becomes "if a syslib call's arguments are all constant, replace with the result".

We have these optimisations today, but they live as ad-hoc passes over the parse tree. A real INTERCAL SIL would make them more systematic. This is one of the candidates for "what we could bring back from this Part" we will weigh in the closing section of the bridge chapter.

## Repo layout

    lib/
      Parse/                  Lexer + parser
      AST/                    AST data structures
      Sema/                   Type checker (constraint solver)
      SIL/                    SIL data structures, instructions
      SILGen/                 AST → raw SIL
      SILOptimizer/
        Mandatory/            Correctness-required passes
        Transforms/           Performance passes (-O)
        Analysis/             SIL analyses (alias, escape, side effect, etc.)
      IRGen/                  SIL → LLVM IR
      ClangImporter/          Bridge to use C/Objective-C from Swift
      IDE/                    SourceKit support, autocompletion, refactoring
    stdlib/
      public/
        core/                 Swift standard library, in Swift
        runtime/              Runtime, in C++
        SwiftShims/           Mixed C/C++ shims
    tools/                    Driver, debugger support, etc.
    docs/                     Compiler documentation

The `ClangImporter/` deserves a footnote. Swift can import C and Objective-C headers directly: a Swift file can `import Foundation` and use Cocoa APIs. The ClangImporter does this by running an embedded Clang to parse the headers and translate the C/Objective-C declarations into AST nodes Swift's Sema can use. It is one of the engineering tour-de-forces of the compiler and the reason Swift can interoperate with the existing Apple platform code without a C-style FFI layer.

## If you only read five files

For getting oriented in Swift's compiler:

1. `lib/SILGen/SILGenExpr.cpp`: AST to SIL.
2. `lib/SIL/IR/SILFunction.cpp` and `include/swift/SIL/SILInstruction.h`: SIL data structures.
3. `lib/SILOptimizer/Mandatory/DiagnoseLifetimeIssues.cpp`: OSSA verification.
4. `lib/SILOptimizer/Transforms/ARCCodeMotion.cpp` and `lib/SILOptimizer/ARC/ARCOpts.cpp`: ARC optimisation.
5. `lib/IRGen/GenCall.cpp`: SIL to LLVM IR.

## Common contributor gotchas

- SIL has two forms: OSSA (ownership) and lowered. Optimisations must declare which they accept; miscategorising deletes ownership info silently.
- ARC optimisations rely on `RCIdentity` analysis. Breaking that gives you double-frees only at -O.
- `sil-opt` is a separate binary that does not pick up driver flags. You must pass `-enable-sil-ownership` etc. explicitly.
- The Swift compiler uses LLVM but heavily forks include paths. Do not bump LLVM directly.
- Many SIL passes have `-enable-experimental-` flags that gate behaviour. Look at `swift_build_support` to see what is on by default.

## Area specialists

- Andrew Trick: SIL design, OSSA, ARC.
- Erik Eckstein: SILOptimizer, ARC.
- Michael Gottesman: ownership SSA.
- Joe Groff: type system, runtime.
- Slava Pestov: generics, witness tables.
- Doug Gregor: Sema, macros.

## Notable recent reads

- Erik Eckstein commits touching `lib/SILOptimizer/Transforms/`: representative of how performance passes are written.
- OSSA-by-default migration PRs (2024-2025).
- Embedded Swift SIL changes 2024-2025.

## Diagnostic flags worth knowing

- `-Xllvm -sil-print-after=<pass>`, `-sil-print-before=<pass>`, `-sil-print-around=<pass>`: per-pass dumps.
- `-Xllvm -sil-print-all`: every pass.
- `-Xllvm -sil-opt-pass-count=N`: bisect by limiting passes run.
- `-Xllvm -sil-print-types`: include type info in dumps.
- `-Xllvm -sil-verify-all`: abort on first SIL verifier failure (defaults are non-fatal in optimiser).
- `-Xfrontend -debug-cycles`, `-dump-ast`, `-emit-silgen`, `-emit-sil`: frontend dumps.

For miscompiles: bisect with `-sil-opt-pass-count=N`; reduce with `bug_reducer` (Swift's `creduce` for SIL, in `utils/bug_reducer/`).

## Reading order

A practical path:

1. Read the [Swift Language Guide](https://docs.swift.org/swift-book/) for context on the source language.
2. Read the SIL specification at <https://github.com/swiftlang/swift/blob/main/docs/SIL/SIL.md>.
3. Browse `lib/SIL/SILInstructions.def`, the list of SIL instructions. Categorised by purpose.
4. Read one mandatory pass, `lib/SILOptimizer/Mandatory/DefiniteInitialization.cpp`. It is well-commented.
5. Read one performance pass, `lib/SILOptimizer/Transforms/ARCOpts/ReferenceCounting.cpp`. ARC optimisation in concrete form.
6. Read `lib/IRGen/IRGenSIL.cpp` to see how SIL lowers to LLVM.

## How to contribute

GitHub PRs to <https://github.com/swiftlang/swift>. The contribution flow is documented at <https://swift.org/contributing/>. Apple is the primary developer but the project is open source and external contributions are welcome.

Beginner-friendly categories:

- Standard library improvements.
- Diagnostic message improvements.
- SIL pass refinements.
- Documentation in `docs/`.
- Tests in `test/` (lit-based, similar to LLVM).

Build:

The build is large. You need the `swift` repo plus `llvm-project` plus several `swift-corelibs-*` repos. Apple provides `update-checkout` and `build-script` to manage this:

    git clone https://github.com/swiftlang/swift
    cd swift
    ./utils/update-checkout --clone
    ./utils/build-script --release-debuginfo

The first build takes hours and ~50 GB of disk. After that, incremental builds are tractable but never fast.

For prospective contributors who do not want to commit to the full build, the Swift compiler driver is the lowest-friction starting point. It is a separate Swift package at <https://github.com/swiftlang/swift-driver>. Swift evolution proposals live at <https://github.com/swiftlang/swift-evolution>.

## Where to go next

- The Swift compiler documentation at <https://swift.org/swift-compiler/>.
- Joe Groff and Chris Lattner's LLVM Developers' Meeting 2015 talk "Swift's High-Level IR: A Case Study of Complementing LLVM IR with Language-Specific Optimization".
- The Swift evolution proposals at <https://github.com/swiftlang/swift-evolution> document the language's growth and the implementation tradeoffs.
- Apple's WWDC sessions on the Swift compiler (search "swift compiler" on developer.apple.com).
- [llvm-overview.md](llvm-overview.md) for the backend Swift uses.
- [rustc-overview.md](rustc-overview.md) for the comparable system that takes different ownership choices.
