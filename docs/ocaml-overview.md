# OCaml, in shape

OCaml is the production member of the ML family of languages, descendant of Caml Special Light, descendant of Caml Light, descendant of Caml, descendant of LCF/ML. The compiler lives at <https://github.com/ocaml/ocaml>. It is small by production-compiler standards, around 200,000 lines, and has been continuously self-bootstrapped for roughly 35 years through an unbroken chain of source releases. That continuity is itself the lesson: a self-hosting compiler can persist for decades without the bootstrap chain ever breaking, if the project takes care to ship a bootstrap binary alongside source.

OCaml deserves a chapter for three independent reasons. It is the canonical implementation of Hindley-Milner type inference, the algorithm that underlies the type systems of Haskell, Rust (in part), Swift (in part), Scala, and most modern statically-typed functional languages. Its module system with functors is a piece of language design that has not been adopted at the same depth by anyone else in this Part. And it pairs a native compiler with a bytecode compiler that share the same frontend, demonstrating in 200,000 lines what tiered compilation looks like at the design level rather than the JIT level.

For a reader of this book, OCaml is the production parallel to "what if our compiler had a real type system and a real module system but stayed small". It is also genealogically connected to rustc: rustc was first bootstrapped through OCaml (`rustboot`, 2010-2011), and many of rustc's design instincts trace back to OCaml habits.

## The pipeline

OCaml has two output paths from a shared frontend:

    source                program.ml
      → tokens             parsing/lexer.mll (ocamllex)
      → Parsetree          parsing/parser.mly (Menhir/ocamlyacc)
      → Typedtree          typing/
      → Lambda             lambda/translmod.ml + bytecomp/translcore.ml
      → bytecode           bytecomp/bytegen.ml          (ocamlc path)
      → Closure            asmcomp/closure.ml          (ocamlopt path)
      → Cmm                asmcomp/cmmgen.ml
      → Mach (per-arch)    asmcomp/<arch>/selection.ml
      → Linear             asmcomp/linearize.ml
      → assembly           asmcomp/<arch>/emit.mlp

The two paths share everything up to and including Lambda. The bytecode path then turns Lambda into a stack-based bytecode for the OCaml virtual machine (`ocamlrun`). The native path performs closure conversion, lowers to Cmm, picks instructions per architecture (Mach), linearises (Linear), and emits assembly.

`ocamlc` is the bytecode compiler; `ocamlopt` is the native compiler. Both produce executables, but with different runtime characteristics: bytecode runs through a portable VM; native compiles to platform-specific machine code. Both compilers are themselves OCaml programs; the bootstrap problem is solved by shipping a bytecode `boot/ocamlc` in the repository.

## Hindley-Milner in production

OCaml's type checker is the canonical Hindley-Milner inferencer in production. The code lives in `typing/`. The key module is `typing/typecore.ml`, which implements the inference algorithm.

The algorithm, in outline, is Algorithm W. Each expression has a type variable; the algorithm walks the AST, generating substitutions that unify type variables with concrete types. When a `let`-bound expression has a polymorphic type, the algorithm generalises: free type variables in the expression's type that are not free in the surrounding environment become quantified. When the polymorphic value is used, the type is instantiated by replacing the quantified variables with fresh type variables, and inference continues.

What looks simple in the textbook becomes work in production:

- **Level-based generalisation**: a naive algorithm runs in O(n²) on programs with deep `let`-nesting. OCaml uses a level-based scheme (Didier Rémy's invention) that tracks the binding depth of each type variable and generalises lazily.
- **Recursive types**: occurs check prevents infinite types, except where the language deliberately allows them (`-rectypes`).
- **Polymorphic mutability**: the value restriction (Wright 1995) constrains where polymorphism can be generalised in the presence of mutable references. OCaml implements a refined form of the value restriction that allows more programs than the strict one.
- **GADTs**: handled as locally abstract types with equation-based reasoning. Adds significant complexity to inference.
- **First-class modules**: modules can be packed into runtime values (`(module M : S)`) and used as expressions, with their type system contribution preserved.
- **Object types**: structural subtyping with row variables and unification under row constraints.

Reading `typing/typecore.ml` line by line is one of the most productive ways to learn type inference. Roughly 4,000 lines, dense but readable, and it implements a feature set that is broader than most academic presentations cover.

The genealogical link to rustc is visible here: rustc's type checker also descends from Hindley-Milner, with significant departures (bidirectional inference, trait dispatch, lifetimes). But the family resemblance shows in the data structures: type variables, levels, unification, generalisation, instantiation. A reader who has read OCaml's type checker will recognise the moves in rustc's, even if the encoding differs.

## The module system with functors

Modules are the part of OCaml that has the least direct counterpart in this Part. Other compilers have namespaces, classes, traits, packages: OCaml has signatures, structures, and functors.

A signature describes what a module provides:

    module type S = sig
      type t
      val zero : t
      val add : t -> t -> t
    end

A structure implements a signature:

    module IntS : S = struct
      type t = int
      let zero = 0
      let add x y = x + y
    end

A functor takes a module and produces a module:

    module MakeMonoid (M : S) = struct
      let sum = List.fold_left M.add M.zero
    end
    module IntSum = MakeMonoid (IntS)

This is parametric modules: a function from modules to modules, applied at compile time. The `MakeMonoid` functor is a definition; `MakeMonoid (IntS)` is an application that produces a new module.

What this gives you that namespaces or classes do not:

- **Type abstraction at module boundary**: `type t` in the signature is opaque from outside the module unless explicitly exposed.
- **Parametric reuse**: write the data structure or algorithm once over a signature; instantiate it for every type that satisfies the signature.
- **Functor composition**: functors take functors as arguments, producing module pipelines.
- **First-class modules**: a module can be packaged as a runtime value, passed to a function, returned, stored in a list. Compile-time abstraction crosses into runtime.

The compiler implementation lives mostly in `typing/mtype.ml` (module types), `typing/includecore.ml` (signature matching), and `typing/typemod.ml` (module typing). Reading these gives you a feel for what a non-trivial module system looks like at the implementation level. Significantly more complex than Rust's module system; significantly less complex than ML-with-functors theoretical accounts make it sound.

For a reader, the practical lesson is that module-level abstraction is a different kind of thing from value-level abstraction (functions) and type-level abstraction (generics, type classes). Modules sit at a third level. Most languages collapse module-level into one of the other two; OCaml keeps it separate, and the result is unusually expressive.

## Lambda and the dual-target frontend

After type checking, the typed AST is lowered to Lambda, an untyped lambda calculus IR. The types are erased at this point: Lambda does not carry them.

Why erase? Because both the bytecode and the native backends consume Lambda, and neither needs the source-level type structure. Type erasure simplifies the IR and lets the same data structure flow into two very different backends.

Lambda has:

- Variables, applications, lambdas, lets, sequences
- Primitive operations (arithmetic, comparison, allocation)
- Pattern-match compilation (more on this below)
- Exception handling primitives (try/raise)
- Module-level operations (load, store, structure access)

The Lambda layer is also where some early optimisations happen: constant folding, simple inlining, dead-code elimination, basic CSE. Nothing aggressive, but enough to clean up the immediate output of type checking.

Pattern matching: OCaml is a pattern-matching language, and pattern matches in the source AST are compiled to decision trees in Lambda. The compilation is the textbook problem from Maranget's papers ("Compiling Pattern Matching to Good Decision Trees", JFP 2008), implemented in `lambda/matching.ml`. It is one of the more sophisticated parts of the compiler and is worth reading on its own, separate from the rest of OCaml internals.

## The bytecode path: ocamlc

`ocamlc` lowers Lambda to bytecode, a stack-based instruction set executed by `ocamlrun`. The bytecode VM design descends from the ZINC machine (Leroy 1990), simplified.

Key VM characteristics:

- **Stack-based**: most operations consume operands from the stack and push results.
- **Accumulator register**: one designated register for the "current" value, an optimisation over pure stack design.
- **Compact**: each instruction is one byte for the opcode plus 0-2 bytes of operand. A program fits in much less space than its native equivalent.
- **Fast to start**: no compilation to machine code, no linker, no relocation. The VM loads the bytecode and runs.

Why ship a bytecode compiler at all in 2026, when native is faster? Several reasons:

- **Portability**: the bytecode runs on any platform with a `ocamlrun`; the binary is the same.
- **Bootstrap**: `boot/ocamlc` is the bootstrap binary in the repo. Bytecode is platform-independent, so the bootstrap binary works on every target.
- **Compile speed**: `ocamlc` is faster than `ocamlopt`, useful for development cycles.
- **Debug**: the bytecode debugger (`ocamldebug`) works on bytecode programs; debugging native programs is harder in OCaml's ecosystem.

For a reader, this is one of the cleanest examples of "the same language compiled two ways for different tradeoffs". The decisions feel familiar: use bytecode for fast iteration and ship-anywhere portability, use native for production speed.

## The native path: ocamlopt

The native pipeline takes Lambda through closure conversion, Cmm lowering, instruction selection, register allocation, and assembly emission.

**Closure conversion** (`asmcomp/closure.ml`): turns nested functions into top-level functions plus explicit closure data. A free variable in an inner function becomes a field of the closure record.

**Cmm** (`asmcomp/cmm.ml`): a portable assembly IR. Instructions are arithmetic, memory, control flow, calls, allocation. Cmm is conceptually similar to the Cmm in GHC (and shares the lineage from C-- by Peyton Jones), though the implementations are independent. Cmm is target-independent; the same Cmm can be compiled for any supported architecture.

**Mach** (`asmcomp/mach.ml`): a per-architecture intermediate that captures the target's instructions plus pseudo-registers. The Cmm-to-Mach lowering picks instructions; the result is Mach.

**Liveness and register allocation** (`asmcomp/liveness.ml`, `asmcomp/regalloc.ml`, `asmcomp/linscan.ml`): OCaml ships two native register allocators. The default is a graph-colouring allocator (Chaitin-Briggs flavour). An optional linear-scan allocator, the classical Poletto-Sarkar algorithm from "Linear Scan Register Allocation" (1999), is opt-in via `-linscan` (since OCaml 4.06) and lives in `asmcomp/linscan.ml`. The linear-scan implementation is small (~330 lines) and notably readable. It is one of the best educational references for register allocation in any production compiler.

**Linear** (`asmcomp/linear.ml`): the Mach is then linearised, exploring control flow and producing a flat instruction sequence.

**Emission** (`asmcomp/<arch>/emit.mlp`): the linear instructions are formatted as assembly text for the target. The `.mlp` extension is for files preprocessed by `cpp`; the architecture-specific assembly syntax differs between `as` (GNU) and Apple's assembler, and the preprocessor handles those differences.

**Assembling and linking**: OCaml invokes the system assembler (`as`) and linker (`ld` or `cc -o`), like our INTERCAL compiler. There is no LLVM, no LLD; the entire native backend is OCaml code that emits text the system tools consume.

The native backend supports amd64, arm64, riscv, power, s390x, with i386 and a few others retired or deprecated. Each is roughly 1,000 lines. The contrast with LLVM's per-target backends (tens of thousands of lines each) is stark; the price is that OCaml's optimiser is much less aggressive.

## The runtime

`runtime/` is the C-language runtime that supports both bytecode and native programs. Around 30,000 lines of C plus assembly for context switching.

What it provides:

- **Garbage collector**: generational mark-sweep with incremental GC of the major heap. The minor heap is a copying collector. The major heap uses mark-sweep with optional compaction. Designed for low pause time given the era (2.0+ added incremental, 4.0+ added concurrent finalisation, 5.0+ added multicore).
- **Exceptions**: implemented via stack unwinding through OCaml frames. Each `try` sets a handler frame; `raise` walks the stack until a handler matches.
- **FFI**: `external` declarations connect OCaml functions to C implementations via a small set of conventions. The C side uses the `caml_*` API for allocation and value access.
- **Multicore (OCaml 5.0+, 2022)**: `Domain` for parallelism, effects for capability-style concurrency.

The OCaml 5.0 multicore project deserves a footnote. It took about a decade of design work and a major runtime rewrite. The result is parallel OCaml without breaking source compatibility; the same programs run on 4.x and 5.x, but multicore programs use the new `Domain` API. The relevant lesson is that retrofitting concurrency to a runtime that assumed single-threaded was a serious undertaking, comparable in scale to the JIT additions in V8 or Sparkplug.

## The unbroken bootstrap chain

The ML language family traces back to LCF/ML (Edinburgh, 1970s). The Caml lineage is:

- ~1987: Caml (Ascánder Suárez at INRIA), the first Caml implementation, in Lisp.
- 1990: Caml Light (Xavier Leroy and Damien Doligez), bytecode VM, the first widely-used Caml.
- 1995: Caml Special Light, added a native compiler.
- 1996: OCaml 1.0, the unified release that succeeds Caml Special Light.
- continuously since: each release built by the previous.

The mechanism: `boot/ocamlc` is a bytecode binary committed to the repository. It is the previous release's bytecode compiler, capable of compiling the current source. Each release updates `boot/ocamlc` only after a successful self-build.

This is the textbook implementation of "Trusting Trust" considerations applied at production scale. A malicious modification of the OCaml source would have to also modify the boot binary in a self-consistent way; the scrutiny on OCaml releases (and the existence of independent rebuilds) makes that hard to do silently.

For our INTERCAL compiler, the boot binary equivalent is `intercalc.sh` (the zsh script, plus the runtime and syslib it depends on). The chain is: `intercalc.sh` compiles `compiler.i` to produce `intercal_core`, which compiles itself, fixpoint test. The same shape, smaller scale, less scrutiny.

The Caml family chain has been unbroken for roughly 35 years (depending on whether you count from Caml Light's 1990 bytecode self-hosting or earlier prototypes). That is a useful number to remember when thinking about how long a self-hosted compiler can persist.

## Repo layout

    parsing/                    Lexer, parser, AST, Parsetree
    typing/                     Type checker, environment, module typing
      typecore.ml               Expression-level inference
      typemod.ml                Module-level inference
      includecore.ml            Signature matching
    lambda/                     Lambda IR, pattern-match compilation, early opts
    bytecomp/                   Lambda → Bytecode
    asmcomp/                    Lambda → Closure → Cmm → Mach → assembly
      closure.ml                Closure conversion
      cmm.ml, cmmgen.ml         Cmm IR and generation
      <arch>/                   Per-architecture
      linscan.ml                Linear-scan register allocator
    middle_end/                 Optional middle-end (Flambda 1 and 2 inliners)
    runtime/                    C runtime (GC, exceptions, FFI)
    stdlib/                     Standard library
    boot/                       Bootstrap bytecode binaries
    testsuite/                  Tests
    Makefile.config             Build configuration
    configure                   Configure script

The `middle_end/` directory is where Flambda lives. Flambda is OCaml's optional optimising middle-end, off by default in standard releases (Flambda 1) and enabled with `--enable-flambda`. Flambda 2 is in development. Both perform inlining, simplification, and unboxing on a Flambda-specific IR sandwiched between Lambda and the rest of the pipeline. Most production OCaml builds do not use Flambda; it is a research project at this point.

## Comparison with other compilers in this Part

| Aspect | OCaml | rustc | GHC |
|--------|-------|-------|-----|
| Type system family | Hindley-Milner with extensions | HM + ownership + traits | HM + System F + classes + GADTs |
| Module system | Functors (parametric modules) | Crates + traits | Modules but flat |
| IRs | Parsetree, Typedtree, Lambda, Cmm, Mach, Linear | AST, HIR, THIR, MIR, LLVM IR | HsSyn, Core, STG, Cmm |
| Backend | Self-hosted per-arch | LLVM (default) | NCG or LLVM |
| Bytecode target | Yes (ocamlc) | No | No (GHCi has bytecode but for interactive only) |
| Self-bootstrapped | Yes (1985+) | Yes (via OCaml originally, then via LLVM) | Yes |
| GC | Generational mark-sweep | None | Generational copying |
| Codebase | ~200K lines OCaml | ~3M Rust | ~700K Haskell + C |

The shape closest to ours: OCaml's split between bytecode (small, portable, fast to start) and native (larger, target-specific, faster) maps onto our `intercalc.sh` (bytecode-equivalent: portable shell, slow but ubiquitous) and `compiler.i` (native-equivalent: targets specific platforms via Label 666). The analogy is loose but the idea is the same.

The shape closest to rustc: type inference, module-level abstraction, immutable-by-default semantics. Reading OCaml after rustc is reading a smaller cousin.

## Reading order

A practical path for somebody with some functional-programming background:

1. Read [Real World OCaml](https://dev.realworldocaml.org/) for the language. Free online.
2. Read `parsing/parser.mly` for the grammar.
3. Read `typing/typecore.ml` slowly. This is the big one, the canonical Hindley-Milner inferencer.
4. Read `lambda/matching.ml` for pattern-match compilation. Self-contained, beautiful.
5. Read `asmcomp/linscan.ml` for register allocation. Short and pedagogical.
6. Read `runtime/major_gc.c` for the major heap GC.

## How to contribute

GitHub PRs to <https://github.com/ocaml/ocaml>. The project is INRIA-led with a dedicated set of maintainers. Code review is rigorous and code style is conservative. The `CONTRIBUTING.md` in the repo describes the flow.

Beginner-friendly categories:

- Standard library improvements: `stdlib/` is broad and many functions are improvable.
- Small bug fixes in less-touched parts of the compiler.
- Documentation: the manual is extensive but the compiler internals have very little.
- Testsuite additions, especially for less-tested features.

Build:

    git clone https://github.com/ocaml/ocaml
    cd ocaml
    ./configure
    make
    make tests

The build is fast (~5 minutes on a modern machine) compared to LLVM or Swift. The test suite is comprehensive.

## Where to go next

- The OCaml manual at <https://ocaml.org/manual>.
- *Real World OCaml* by Yaron Minsky, Anil Madhavapeddy, and Jason Hickey, free at <https://dev.realworldocaml.org/>.
- Xavier Leroy's papers on the OCaml compiler at <https://xavierleroy.org/publi/>.
- "The ZINC Experiment: An Economical Implementation of the ML Language" (Leroy 1990) for the bytecode VM design.
- "Linear Scan Register Allocation" (Poletto and Sarkar 1999) for the regalloc.
- [rustc-overview.md](rustc-overview.md) for the genealogically-related compiler.
- [ghc-overview.md](ghc-overview.md) for the other major ML-family production compiler.
