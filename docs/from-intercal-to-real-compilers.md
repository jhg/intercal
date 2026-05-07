# From INTERCAL to real compilers

The previous chapters built up a complete picture of one small compiler. This chapter is the bridge from that picture to the much larger one a contributor to LLVM, rustc, or GCC has to hold in their head. The aim is to make the transfer as cheap as possible: most of the conceptual work has already been done.

If you have read Parts I through V of this book, the table below names what you already know in production-compiler vocabulary, and what you do not yet.

## What you already know

| Concept in this book | Same concept in production compilers |
|----------------------|----------------------------------------|
| Lexer (`tokenize` in `intercalc.sh`) | LLVM Clang's `clang/lib/Lex`, rustc's `rustc_lexer`, GCC's per-frontend lexer |
| Parser (`parse_expr`, hand-written recursive descent) | All three compilers use hand-written recursive descent. rustc's `rustc_parse`, Clang's `Parser`, GCC's per-language parsers. |
| AST in parallel arrays | LLVM does not have a long-lived AST. rustc has `rustc_ast` (the AST proper), then HIR. GCC has GENERIC. |
| Semantic analysis (politeness, label checks, COME FROM resolution) | rustc's name resolution (`rustc_resolve`) and type checking (`rustc_hir_typeck`); Clang's Sema; GCC's tree-level type checks. |
| Code generation (direct ARM64/x86-64 emission) | LLVM IR + LLVM backends; rustc's `rustc_codegen_llvm` lowering MIR to LLVM IR; GCC's RTL → assembly path. |
| Runtime (`_rt_*` functions) | libc + per-language runtime: libstdc++, libcxx, Rust's `core`/`std`, GCC's libgcc. |
| System library (labels 1000–1999) | The "intrinsics" each compiler ships: `__builtin_*` in GCC and Clang, `core::intrinsics::*` in rustc. |
| Constant folding (`eval_const`) | LLVM's `InstSimplify`, rustc's `interpret`/MIR const-eval, GCC's tree-level folder. |
| Dead-flag elimination (`compute_flag_checks`) | Generic dead-code elimination on SSA / GIMPLE / MIR. |
| Peephole pass | Same pass exists at multiple levels in each compiler. |
| Self-hosting (3-generation fixpoint) | rustc bootstraps in three stages; GCC and LLVM are self-hosting in C++. |
| Differential testing (pure vs native syslib) | LLVM has fuzzers (libFuzzer, csmith integration); rustc has crater runs over crates.io; GCC has its testsuite plus randomised testing. |
| Reproducible builds (`tools/rewrite_uuid.py`, `SOURCE_DATE_EPOCH`) | All three projects work with reproducible-builds.org and embed deterministic outputs. |
| Trusting Trust (DDC reflection) | The same threat model. LLVM and GCC have begun publishing reproducible self-builds for this reason. |

The first column is a chapter or two of this book. The second column is the rest of your career in compiler engineering, but it is the *same conceptual skill*.

## What you do not yet know, and where to learn it

A production compiler differs from this one in degree on most axes. A few axes deserve named follow-up reading.

### Modern intermediate representations

Our compiler has no IR. Production compilers have at least one and often several. The big concepts you will meet:

- *SSA form* (Static Single Assignment): every variable is assigned exactly once. We touched this in [middle-end-and-optimisation.md](middle-end-and-optimisation.md). The Cytron et al. (1991) paper is the canonical reference.
- *Control-Flow Graph*: the program as a graph of basic blocks. Most analyses operate on the CFG, not on tree-shaped IR.
- *Dataflow analysis*: figuring out what is true at every program point, computed iteratively until a fixpoint. Constant propagation and dead-code elimination both use it.
- *Type systems*: most production languages are typed. Type checking is a different kind of work from anything our INTERCAL compiler does.

These are textbook material. Cooper and Torczon's *Engineering a Compiler* (3rd edition) is a thorough modern reference; Appel's *Modern Compiler Implementation* is the academic counterpart. Both are listed in [further-reading.md](further-reading.md).

### Optimisation pipelines

Our compiler has a handful of small optimisations. Real compilers have hundreds, organised into pipelines that run them in carefully chosen orders, often several times each.

The classical optimisations to read about: dead-code elimination, common subexpression elimination, global value numbering, loop-invariant code motion, induction-variable simplification, scalar replacement of aggregates, function inlining, partial redundancy elimination. Each has its own paper or two.

The *meta*-question of pass ordering ("which order should we run optimisations in, and how often") is itself an active research area. The Cornell course CS 6120 (linked from [further-reading.md](further-reading.md)) is the best free entry point.

### Backend code generation

Our backend is a per-statement template. A production backend selects target instructions from an IR-level description, schedules them to use the pipeline efficiently, and allocates physical registers under tight constraints.

The major topics: instruction selection (greedy, BURS-style, or DAG-based), instruction scheduling (list scheduling, software pipelining), register allocation (graph colouring per Chaitin, linear scan, second-chance bin packing).

LLVM's `lib/CodeGen/` directory is the most readable production-grade implementation. GCC's RTL machinery is older and more opaque.

### Type systems

Almost every production compiler has a richer type system than INTERCAL's "spot, twospot, tail, hybrid". Modern type systems include polymorphism, subtyping, traits or interfaces, lifetime tracking (in rustc), effect tracking (in some research compilers), gradual typing (some Python tools).

The research literature is enormous. Pierce's *Types and Programming Languages* is the standard textbook. For language-specific type systems, the per-compiler dev guide is the right reference: rustc's HIR type-checker chapter, Clang's Sema docs, GCC's tree-level type rules.

### Concurrency, incremental compilation, IDE integration

A compiler that runs only as a batch job is a 1980s compiler. Modern compilers integrate with IDEs (via the Language Server Protocol or per-vendor protocols), respond to single-keystroke edits incrementally, and parallelise themselves across cores.

These concerns are mostly invisible in our INTERCAL compiler because the compiler runs in milliseconds and nobody types in INTERCAL inside an IDE. They will be the bulk of the work you see in production-compiler PRs.

The rustc-dev-guide chapter on *Queries* and *Salsa* is the best free explanation of how a modern compiler structures itself for incremental compilation.

## A reading plan from here

For somebody who wants to land a first patch on a production compiler within a couple of months:

1. Pick one of LLVM, rustc, or GCC. See [contributing-to-production-compilers.md](contributing-to-production-compilers.md) for a comparison.
2. Read the corresponding overview chapter ([llvm-overview.md](llvm-overview.md), [rustc-overview.md](rustc-overview.md), [gcc-overview.md](gcc-overview.md)).
3. Read the project's own dev guide. For rustc, the rustc-dev-guide. For LLVM, the docs at <https://llvm.org/docs/>. For GCC, the gccint manual.
4. Build the project locally. Allow a couple of hours.
5. Find a "good first issue" or equivalent label. Read the issue, reproduce it, attempt a fix.
6. Submit a PR or patch following the project's conventions.

A couple of months is a realistic timeline. The first patch is the hardest. The book in your hands has done its job if reading the production compiler's source is no longer intimidating, just larger.

## What our INTERCAL compiler will never teach you

A few things this book deliberately does not cover. They become relevant only at production scale.

- **Garbage collection.** INTERCAL does not allocate. Every modern dynamic language compiler does. The standard reference is *The Garbage Collection Handbook* (Jones, Hosking, Moss).
- **JIT compilation.** Our compiler runs ahead of time only. JITs are most relevant in V8, HotSpot, LuaJIT, the .NET CLR. LLVM's ORC is its JIT subsystem; rustc has no JIT.
- **Profile-guided optimisation.** PGO collects runtime profiles and feeds them back into the next compilation to inform optimisation decisions. All three production compilers support it.
- **Link-time optimisation.** LTO defers some optimisations until the linker has visibility across translation units. Both LLVM (ThinLTO) and GCC (lto1) support it.
- **Polyhedral optimisation, vectorisation, autoparallelisation.** Heavyweight numerical optimisations relevant to HPC. Polly (in LLVM) and Graphite (in GCC) are the open-source representatives.

Each of these is its own subfield. A reader who has finished this book and wants to dive into one of them has the conceptual background to read the relevant Wikipedia page, follow the references, and go from there.

## Closing

The skill of reading a compiler is a smaller skill than the skill of writing one from scratch. This book has tried to teach both, by writing one from scratch and explaining each piece in plain enough language that the same vocabulary works on a much larger codebase.

The two-page index of LLVM, rustc, and GCC chapters is the bridge. Cross it when you are ready.
