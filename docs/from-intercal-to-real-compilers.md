# From INTERCAL to real compilers

The previous chapters built up a complete picture of one small compiler. This chapter is the bridge from that picture to the much larger one a contributor to LLVM, rustc, GCC, Go, GHC, OCaml, Cranelift, Zig, Swift, or V8 has to hold in their head. The aim is to make the transfer as cheap as possible: most of the conceptual work has already been done.

If you have read Parts I through V of this book, the table below names what you already know in production-compiler vocabulary, and what you do not yet.

## What you already know

| Concept in this book | Same concept in production compilers |
|----------------------|----------------------------------------|
| Lexer (`tokenize` in `intercalc.sh`) | Clang's `clang/lib/Lex`, rustc's `rustc_lexer`, GCC's per-frontend lexer, Go's `cmd/compile/internal/syntax`, GHC's `compiler/GHC/Parser/Lexer.x` |
| Parser (`parse_expr`, hand-written recursive descent) | All compilers in this Part use hand-written recursive descent. rustc's `rustc_parse`, Clang's `Parser`, GCC's per-language parsers, Go's `syntax.Parser`, OCaml's Menhir-generated parser. |
| AST in parallel arrays | LLVM does not have a long-lived AST. rustc has `rustc_ast`, then HIR, then THIR. GCC has GENERIC. Swift's AST is rich and evolves through phases. GHC's HsSyn is parametrised by phase. |
| Semantic analysis (politeness, label checks, COME FROM resolution) | rustc's `rustc_resolve` + `rustc_hir_typeck`; Clang's Sema; GCC's tree-level type checks; OCaml's Hindley-Milner inferencer; GHC's OutsideIn(X); Zig's Sema. |
| Code generation (direct ARM64/x86-64 emission) | LLVM's IR + LLVM backends; rustc's `rustc_codegen_llvm` lowering MIR; GCC's RTL → assembly; Go's SSA + per-arch lowering; OCaml's hand-written native backend; Swift's SIL + IRGen + LLVM. |
| Runtime (`_rt_*` functions) | libc + per-language runtime: libstdc++, libcxx, Rust's `core`/`std`, GCC's libgcc, Go's runtime (with GC + scheduler), GHC's RTS (with GC + STG machine), OCaml's runtime, Swift's runtime, V8's heap + scheduler. |
| System library (labels 1000–1999) | The "intrinsics" each compiler ships: `__builtin_*` in GCC and Clang, `core::intrinsics::*` in rustc, `internal/runtime` in Go, GHC primops, OCaml primitives. |
| Constant folding (`eval_const`) | LLVM's `InstSimplify`, rustc's `interpret`/MIR const-eval (miri), GCC's tree-level folder, Go's `.rules` rewrites, GHC's simplifier. |
| Dead-flag elimination (`compute_flag_checks`) | Generic dead-code elimination on SSA / GIMPLE / MIR. |
| Peephole pass | Same pass exists at multiple levels in each compiler. |
| Self-hosting (3-generation fixpoint) | rustc bootstraps in three stages; OCaml has done so continuously since 1985; Zig went stage1 (C++) → stage2 (Zig); Go went 6g/8g (C) → cmd/compile (Go) in 2015. |
| Differential testing (pure vs native syslib) | LLVM has fuzzers (libFuzzer, csmith integration); rustc has crater runs; GCC has its testsuite plus randomised testing; Go has fuzzing built in. |
| Reproducible builds (`tools/rewrite_uuid.py`, `SOURCE_DATE_EPOCH`) | All major compilers work with reproducible-builds.org and embed deterministic outputs. |
| Trusting Trust (DDC reflection) | The same threat model. LLVM, GCC, Go, OCaml have all begun publishing reproducible self-builds for this reason. |

The first column is a chapter or two of this book. The second column is the rest of your career in compiler engineering, but it is the *same conceptual skill*.

## Distinguishing features per compiler

Each compiler in Part VII has a defining feature that other compilers do not have, or have only at much smaller scale:

| Compiler | Defining feature(s) you learn here |
|----------|-------------------------------------|
| LLVM | Modular pass infrastructure, single SSA IR, TableGen, MLIR generalisation |
| GCC | Three-IR stack (GENERIC/GIMPLE/RTL), mature LTO, machine descriptions, plugin system, mailing-list culture |
| rustc | Borrow checker on MIR, query-based incremental compilation, alternative codegen backends (Cranelift/GCC), four-IR stack |
| Go | Self-contained (no LLVM), declarative `.rules` DSL, escape analysis for stack/heap, fast compile times as design goal |
| GHC | Four IRs with formal semantics, lazy evaluation runtime (STG), type classes via dictionary passing, Cmm portable assembly |
| OCaml | Hindley-Milner type inference (the canonical implementation), functor module system, dual bytecode + native backends, unbroken bootstrap chain since 1985 |
| Cranelift | Backend-as-library, ISLE declarative DSL, regalloc2 SSA-based linear scan, "fast compile" as explicit goal |
| Zig | Comptime as unifying primitive, Sema as the largest phase, stage1→stage2 self-hosting parallel to ours, multiple self-hosted backends |
| Swift | SIL as semantic IR (ARC, generics, witness tables explicit), Mandatory vs Performance pass distinction, ARC optimisation |
| V8 | Tiered JIT, sea-of-nodes IR, speculation + deoptimisation, hidden classes for JS dynamic objects |

A reader who picks one and goes deep gets a skill set that transfers to compilers in the same family. A reader who reads several gets a sense of the design space.

## Comparison table across all ten

| Aspect | LLVM | GCC | rustc | Go | GHC | OCaml | Cranelift | Zig | Swift | V8 |
|--------|------|-----|-------|-----|-----|-------|-----------|-----|-------|-----|
| IR levels | 1 | 3 | 4 | 2 | 4 | 5 | 1 | 2 | 2 (+LLVM) | 3 (BC, Maglev SSA, SoN) |
| Backend | Self | Self | LLVM | Self | NCG or LLVM | Self | Self | LLVM or self | LLVM | Self (per tier) |
| Compilation model | AOT | AOT | AOT | AOT | AOT | AOT + bytecode | AOT/JIT | AOT | AOT | JIT (4 tiers) |
| GC | No (host) | No (host) | No (compile-time) | Yes | Yes | Yes | No | No | Yes (ARC) | Yes (Orinoco) |
| Self-hosted | C++ (no) | C++ (no) | Rust (yes) | Go (yes) | Haskell (yes) | OCaml (yes, since 1985) | Rust (no, library) | Zig (yes, since 2022) | C++ (no) | C++ (no) |
| Codebase size | ~10M C++ | ~15M mixed | ~3M Rust | ~50K Go | ~700K Haskell+C | ~200K OCaml | ~50K Rust | ~500K Zig | ~3M C++ | ~3M C++ |
| Build time | ~30 min | ~1 hour | ~1 hour | minutes | ~30 min | minutes | seconds | ~30 min | hours | ~1 hour |
| Frontends | Many | Many | Rust only | Go only | Haskell only | OCaml only | None (library) | Zig only | Swift only | JS + WASM |
| Targets | 50+ | 50+ | LLVM's | 15+ | x86-64, ARM64, +others | x86-64, ARM64, +others | x86-64, ARM64, RISC-V, s390x | LLVM's + 4 self | LLVM's | x86-64, ARM64 |
| Distinguishing IR feature | LLVM IR (typed SSA, opaque ptrs) | RTL (machine-level) | MIR (CFG with explicit drops) | SSA + .rules | Core (System FC), STG | Lambda + Cmm | CLIF (block params, not phis) | ZIR + AIR | SIL (ARC explicit) | TurboFan SoN |

Reading across the rows, you can see the design clusters:

- LLVM, GCC, Go, OCaml, Cranelift, Zig (when self-hosted backend), V8 all build their own backends. rustc and Swift use LLVM. GHC has both options.
- LLVM and rustc share LLVM IR; OCaml, Go, GHC's NCG, V8 have their own; Cranelift's CLIF is a portable middle ground.
- GC is in Go, GHC, OCaml, V8 (Orinoco), Swift (ARC). rustc's borrow checker eliminates the need. LLVM and GCC delegate to the host language.
- JIT is V8 alone among the ten. The other nine are AOT.

## What you do not yet know, and where to learn it

A production compiler differs from this one in degree on most axes. A few axes deserve named follow-up reading.

### Modern intermediate representations

Our compiler has no IR. Production compilers have at least one and often several. The big concepts you will meet:

- *SSA form* (Static Single Assignment): every variable is assigned exactly once. We touched this in [middle-end-and-optimisation.md](middle-end-and-optimisation.md). The Cytron et al. (1991) paper is the canonical reference.
- *Control-Flow Graph*: the program as a graph of basic blocks. Most analyses operate on the CFG, not on tree-shaped IR.
- *Dataflow analysis*: figuring out what is true at every program point, computed iteratively until a fixpoint. Constant propagation and dead-code elimination both use it.
- *Type systems*: most production languages are typed. Type checking is a different kind of work from anything our INTERCAL compiler does.
- *Sea of nodes*: an alternative IR where control and data flow are unified into a single graph. Used by V8's TurboFan and HotSpot's C2. Cliff Click 1995.

For the first three, Cooper and Torczon's *Engineering a Compiler* (3rd edition) is a thorough modern reference; Appel's *Modern Compiler Implementation* is the academic counterpart. For type systems specifically, Pierce's *Types and Programming Languages*. All are listed in [further-reading.md](further-reading.md).

### Optimisation pipelines

Our compiler has a handful of small optimisations. Real compilers have hundreds, organised into pipelines that run them in carefully chosen orders, often several times each.

The classical optimisations to read about: dead-code elimination, common subexpression elimination, global value numbering, loop-invariant code motion, induction-variable simplification, scalar replacement of aggregates, function inlining, partial redundancy elimination. Each has its own paper or two.

The *meta*-question of pass ordering ("which order should we run optimisations in, and how often") is itself an active research area. The Cornell course CS 6120 (linked from [further-reading.md](further-reading.md)) is the best free entry point.

### Backend code generation

Our backend is a per-statement template. A production backend selects target instructions from an IR-level description, schedules them to use the pipeline efficiently, and allocates physical registers under tight constraints.

The major topics: instruction selection (greedy, BURS-style, or DAG-based), instruction scheduling (list scheduling, software pipelining), register allocation (graph colouring per Chaitin, linear scan, second-chance bin packing, SSA-based as in regalloc2).

LLVM's `lib/CodeGen/` directory is the most readable production-grade implementation. GCC's RTL machinery is older and more opaque. Cranelift's `regalloc2` is the most legible modern register allocator. OCaml's linear-scan implementation is the most pedagogically friendly.

### Type systems

Almost every production compiler has a richer type system than INTERCAL's "spot, twospot, tail, hybrid". Modern type systems include polymorphism, subtyping, traits or interfaces, lifetime tracking (in rustc), effect tracking (in some research compilers), gradual typing (some Python tools).

The research literature is enormous. Pierce's *Types and Programming Languages* is the standard textbook. For specific systems:

- Rust ownership and lifetimes: the rustc-dev-guide chapters on Borrow Checking and the Polonius RFC.
- Haskell's System FC and constraint-based inference: Vytiniotis et al. 2011 on OutsideIn(X).
- Swift's constraint solver: Apple's documentation plus the Lattner papers on SIL.
- OCaml's Hindley-Milner: Didier Rémy's "Using, Understanding, and Unraveling the OCaml Language" (free PDF).
- Zig's comptime + types-as-values: Andrew Kelley's blog posts.

### Concurrency, incremental compilation, IDE integration

A compiler that runs only as a batch job is a 1980s compiler. Modern compilers integrate with IDEs (via the Language Server Protocol or per-vendor protocols), respond to single-keystroke edits incrementally, and parallelise themselves across cores.

These concerns are mostly invisible in our INTERCAL compiler because the compiler runs in milliseconds and nobody types in INTERCAL inside an IDE. They will be the bulk of the work you see in production-compiler PRs.

The rustc-dev-guide chapter on *Queries* and *Salsa* is the best free explanation of how a modern compiler structures itself for incremental compilation.

### Memory management strategies

Different compilers handle memory differently:

- **No GC, type-system-managed**: Rust (ownership + lifetimes).
- **No GC, manual**: C, C++, Zig (allocator-aware standard library).
- **Reference counting, compile-time-inserted**: Swift (ARC).
- **Generational GC**: Go, OCaml, GHC, V8.
- **Concurrent GC**: Go, V8 (concurrent marker), GHC (optional concurrent collector).

Each strategy comes with a runtime, a compiler-runtime contract (write barriers, safepoints, root-walking), and a particular set of tradeoffs (latency vs throughput, complexity vs predictability).

For a deep treatment, *The Garbage Collection Handbook* by Jones, Hosking, and Moss is the canonical reference. The shorter summary is in each compiler's runtime documentation.

### JIT compilation

V8 is the only JIT in this Part. The world of JITs includes HotSpot (Java), LuaJIT, .NET CLR, JavaScript Core (Safari's), SpiderMonkey (Firefox's), GraalVM (Polyglot). Each has its own set of tiers, IRs, and design choices.

Key concepts: tiered compilation, on-stack replacement, inline caches, hidden classes (or the equivalent for non-JS dynamic languages), speculation + deoptimisation.

LLVM's ORC is its JIT subsystem; rustc has no JIT. GCC has JIT support via libgccjit. The closest analog to V8 outside V8 itself is HotSpot's C2 (which uses the same sea-of-nodes IR Cliff Click invented for both).

## A reading plan from here

For somebody who wants to land a first patch on a production compiler within a couple of months:

1. Pick one of the ten compilers in this Part. The selection criteria below help.
2. Read the corresponding overview chapter.
3. Read the project's own developer guide (rustc-dev-guide, GCC's gccint manual, LLVM docs, GHC commentary, etc.).
4. Build the project locally. Allow a couple of hours.
5. Find a "good first issue" or equivalent label. Read the issue, reproduce it, attempt a fix.
6. Submit a PR or patch following the project's conventions.

A couple of months is a realistic timeline for a first patch. The first patch is the hardest. The book in your hands has done its job if reading the production compiler's source is no longer intimidating, just larger.

### Selection criteria

If you have no preference, here is a rough ranking by approachability:

- **Easiest to onboard**: rustc (rustc-dev-guide is excellent), Cranelift (small codebase, welcoming community), Go (good docs, fast iteration).
- **Most valuable for general compiler skills**: LLVM (you will encounter it everywhere), Go (clean SSA backend with declarative rules).
- **Deepest theoretical content**: GHC (formal IRs, type theory), OCaml (Hindley-Milner, classical compiler design).
- **Most distinctive niches**: V8 (only JIT here), Swift (only SIL here), Zig (only comptime here).
- **Industry adoption**: LLVM, GCC, Go, rustc, V8 are all in production use at scale.
- **Academic adoption**: GHC, OCaml are the most studied in compiler-research papers.

## What our INTERCAL compiler will never teach you

A few things this book deliberately does not cover. They become relevant only at production scale.

- **Garbage collection.** INTERCAL does not allocate. Every modern dynamic language compiler does. The standard reference is *The Garbage Collection Handbook* (Jones, Hosking, Moss).
- **JIT compilation.** Our compiler runs ahead of time only. JITs are most relevant in V8, HotSpot, LuaJIT, the .NET CLR. LLVM's ORC is its JIT subsystem; rustc has no JIT.
- **Profile-guided optimisation.** PGO collects runtime profiles and feeds them back into the next compilation to inform optimisation decisions. LLVM, GCC, Go, Swift all support it.
- **Link-time optimisation.** LTO defers some optimisations until the linker has visibility across translation units. LLVM (ThinLTO), GCC (lto1), and Swift (CMO) all support it.
- **Polyhedral optimisation, vectorisation, autoparallelisation.** Heavyweight numerical optimisations relevant to HPC. Polly (in LLVM) and Graphite (in GCC) are the open-source representatives.
- **Lazy evaluation runtime.** Specific to GHC (and a handful of research languages). Our compiler is strict.
- **Speculation and deoptimisation.** JIT-specific. Only V8 in this Part.

Each of these is its own subfield. A reader who has finished this book and wants to dive into one of them has the conceptual background to read the relevant Wikipedia page, follow the references, and go from there.

## Closing

The skill of reading a compiler is a smaller skill than the skill of writing one from scratch. This book has tried to teach both, by writing one from scratch and explaining each piece in plain enough language that the same vocabulary works on a much larger codebase.

The ten chapters of LLVM, GCC, rustc, Go, GHC, OCaml, Cranelift, Zig, Swift, and V8 are the bridge. Cross any one of them when you are ready.
