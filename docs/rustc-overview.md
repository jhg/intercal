# rustc, in shape

rustc is the Rust compiler. The source lives at <https://github.com/rust-lang/rust>. The authoritative companion document for anyone reading or modifying the compiler is the [rustc-dev-guide](https://rustc-dev-guide.rust-lang.org/), which the rest of this chapter assumes you will eventually read.

rustc is interesting as a third reference point because it has neither LLVM's single IR nor GCC's three. It has *four*: HIR, THIR, MIR, and (via codegen) LLVM IR. Each layer exists to make a specific job easier.

## The pipeline, end to end

Rust source goes through this sequence:

    source
      → tokens          (lexer)
      → AST             (parser)
      → HIR             (lowering, after macro expansion and name resolution)
      → THIR            (lowering, after type checking)
      → MIR             (lowering, for borrow checking and optimisation)
      → LLVM IR         (codegen)
      → machine code    (LLVM)

Six lowering steps, four named IRs. Each is the right shape for the work that happens at that level.

## What each IR is for

**AST** is what the user wrote. Macros are not yet expanded. Names are not yet resolved. The parser produces it; almost nothing else touches it.

**HIR** (High-level Intermediate Representation) is the AST after macro expansion, name resolution, and minor desugaring. Lifetimes that the user elided are now explicit. HIR is what most compiler passes see during type checking. It is still close enough to the source that error messages can point at sensible spans.

**THIR** (Typed High-level IR) is HIR after type checking. Method calls are resolved to specific function references, autoref/autoderef coercions are inserted, overloaded operators are replaced with explicit calls. THIR exists as a stepping stone: it is fully typed but still tree-shaped, which makes it the right starting point for building MIR.

**MIR** (Mid-level IR) is the most distinctive piece of rustc's design. MIR is a control-flow graph in basic blocks, each containing simple typed statements with explicit drops, moves, and references. This is where Rust's *borrow checker* runs. Borrow checking on MIR (rather than on HIR or AST) is what made non-lexical lifetimes possible. MIR is also the IR for a growing set of compiler-internal optimisations, constant evaluation, and the recent const-generic and dataflow analyses.

**LLVM IR** is what rustc emits when it is finally ready to hand off to the LLVM backend. The codegen layer (`rustc_codegen_llvm`) walks MIR and emits LLVM IR. There are alternative codegen backends: `rustc_codegen_cranelift` for fast debug builds, and `rustc_codegen_gcc` for using GCC as the backend instead of LLVM.

## Why so many IRs

Each lowering removes ambiguity that was useful at a higher level but inconvenient at a lower one.

- AST → HIR removes macros and name ambiguities. A pass at HIR level does not have to worry about whether `vec!` is a macro or a function call.
- HIR → THIR removes type ambiguities. A pass at THIR level does not have to re-do trait resolution.
- THIR → MIR turns the tree into a control-flow graph. A pass at MIR level can use dataflow algorithms naturally. The borrow checker, in particular, is much easier to express on MIR than on HIR.
- MIR → LLVM IR removes Rust-specific concerns (drop semantics, panics, generics). LLVM does not need to know about lifetimes or traits.

Compare this with LLVM (one IR for everything) and GCC (three IRs at different levels of abstraction). rustc sits closer to GCC's school of thought than to LLVM's, but with more semantic information preserved at each level.

## The borrow checker on MIR

The borrow checker (`rustc_borrowck`) is rustc's most distinctive piece. It runs on MIR, after type checking and after MIR construction. Its job: reject programs that would create undefined behaviour by violating Rust's ownership and borrowing rules, and accept everything else.

The history is worth knowing:

- **Pre-2018**: lexical borrow checker on HIR (in `rustc_borrowck`'s old form). Borrows lived for the entire enclosing lexical scope. Infamously rejected programs that "felt" correct, like splitting a struct into two disjoint borrows.
- **2018**: NLL (Non-Lexical Lifetimes) on MIR. Borrows live for as long as needed, computed via dataflow. Many previously-rejected programs become valid. The "NLL" name is historical; the system is now just "the borrow checker".
- **In progress (2024-2026)**: **Polonius**, originally a Datalog reformulation of the borrow checker, currently being rewritten as a "Polonius alpha" location-sensitive analysis that is a strict superset of NLL. It accepts the NLL "problem case 3" and lending iterators that NLL rejects. The 2026 project goal is to stabilise Polonius alpha behind a feature gate; the team will accept 10-20% borrow-checking compile-time overhead for the expressiveness gains. NLL remains the production default; gccrs uses a separate Polonius integration as its production borrow checker since GCC 15.

How NLL works in outline:

1. For each borrow in the function, compute the **region** (set of MIR points) where the borrow must remain valid.
2. For each variable, compute the **liveness** information: at which points the variable is live (its value will be used).
3. Check that no two conflicting borrows overlap in their regions.
4. Check that moves out of variables happen only when no borrows of those variables are live.

The algorithm is dataflow on the MIR control-flow graph. The implementation in `rustc_borrowck` is around 50,000 lines, including diagnostics, but the algorithmic core is much smaller.

Polonius (in progress) reformulates this as Datalog rules:

    borrow_alive(L, P) :- borrow_introduced(L, P).
    borrow_alive(L, Q) :- borrow_alive(L, P), edge(P, Q), !borrow_killed(L, Q).
    error :- borrow_alive(L, P), conflicting_access(L, P).

The advantage: the rules are declarative, easier to extend, easier to reason about. The Polonius engine then computes the fixpoint. The transition to Polonius has been gradual, with Polonius results currently used for some warnings while NLL drives the actual error reporting.

For a reader, the borrow checker is one of the most concrete examples of a non-trivial static analysis applied to a practical problem. Reading the high-level overview in the rustc-dev-guide and then the implementation gives a full picture.

## The trait solver

The trait solver (`rustc_trait_selection`, gradually being replaced by a new solver) is rustc's other distinctive analysis. Its job: given a trait constraint like `T: Eq` or `Vec<T>: Iterator`, find the implementation (or implementations) that satisfy it.

The hard cases:

- **Multiple impls**: a type might satisfy a trait in multiple ways. Coherence rules (one impl per (type, trait) pair) prevent this in user code, but compiler-internal reasoning sometimes encounters non-deterministic states.
- **Higher-ranked traits**: `for<'a> Fn(&'a u32) -> &'a u32` requires reasoning about all lifetimes simultaneously.
- **Associated types**: `<T as Iterator>::Item` is a type that depends on which impl is chosen.
- **Specialisation** (unstable): a more specific impl can override a less specific one. Coherence rules become more complex.
- **GATs (Generic Associated Types)**: trait associated types parameterised by lifetimes or types. New as of 2022.

The old solver is imperative: a loop tries impls one at a time, with backtracking and special-cased handling. The new solver (started 2022, work in progress through 2026) is based on a proof tree: explicit goal-seeking with structured search and improved error reporting.

For a reader, the trait solver is the closest production analog to a Prolog-style logical inference engine. The trade-offs (completeness vs decidability, expressiveness vs error-message clarity) are studies in their own right.

## The query system

rustc's compilation is structured as a graph of **queries**. Each query is a function from input to output that the compiler can ask for and that gets cached. Examples:

- `tcx.type_of(def_id)`: what is the type of this definition?
- `tcx.borrowck(def_id)`: borrowcheck this function.
- `tcx.optimized_mir(def_id)`: produce the optimised MIR for this function.

When a query is asked for the first time, rustc computes it and caches the result. Subsequent calls return the cached value. The query system also tracks dependencies: query A depends on query B if computing A asks for B.

Why this matters: **incremental compilation**. When a file changes, rustc invalidates only the queries whose dependencies changed. Unchanged queries reuse cached results. The result is incremental builds that touch only what is necessary, not the full pipeline.

The query system is implemented in `rustc_query_system`. The approach is influenced by the [Salsa](https://github.com/salsa-rs/salsa) library (used by rust-analyzer), though the rustc implementation is older.

For a reader, the query system is the cleanest production example of "compiler architected as memoising graph". Modern languages targeting fast iteration (Java's javac, Kotlin's compiler, TypeScript's tsc) have moved to similar designs.

## Crates inside rustc

The rustc compiler is a Cargo monorepo with many crates. The full list:

    rustc_lexer/             Token-level scanning (also used by rustfmt, rust-analyzer)
    rustc_parse/             Parser (recursive descent, ~30K lines)
    rustc_ast/               AST data structures
    rustc_expand/            Macro expansion (declarative + procedural)
    rustc_resolve/           Name resolution
    rustc_hir/               HIR data structures
    rustc_hir_pretty/        HIR pretty-printer
    rustc_hir_typeck/        Type checking on HIR (expression-level)
    rustc_trait_selection/   Trait solver (old)
    rustc_next_trait_solver/ Trait solver (new, in progress)
    rustc_mir_build/         THIR → MIR construction
    rustc_borrowck/          Borrow checker on MIR
    rustc_const_eval/        Constant evaluation (miri-based)
    rustc_mir_transform/     MIR-level optimisations
    rustc_codegen_ssa/       Codegen scaffolding (backend-independent)
    rustc_codegen_llvm/      LLVM backend
    rustc_codegen_cranelift/ Cranelift backend (separate repo, integrated)
    rustc_codegen_gcc/       GCC backend (separate repo, integrated)
    rustc_driver/            CLI driver, the entry point
    rustc_session/           Compilation-session state
    rustc_query_system/      Query infrastructure
    rustc_query_impl/        Query implementations (generated)
    rustc_metadata/          Crate metadata format and reading
    rustc_save_analysis/     Save-analysis data (for IDEs)
    rustc_target/            Target descriptions
    ...                      Plus 50+ more

The crate boundaries are real: each crate compiles independently, depends on the others through stable interfaces, and has its own README. The `compiler/rustc_*/README.md` files are the entry points for new contributors looking at a particular area.

## Alternative codegen backends

rustc supports multiple backends, selectable per build:

- **rustc_codegen_llvm**: production default. LLVM backend.
- **rustc_codegen_cranelift**: fast debug-mode codegen. Roughly 2-3x faster than LLVM for debug builds.
- **rustc_codegen_gcc**: experimental GCC backend. Uses GCC's optimiser instead of LLVM. Useful for targets where LLVM is weak or where GCC's mature LTO matters.

The backends share `rustc_codegen_ssa`, the scaffolding crate. Each backend implements a trait that defines what it means to "lower MIR to machine code". The shared trait is large (~50 methods) but well-defined; new backends can be added in a focused way.

For a reader, the multi-backend story is rustc's strongest argument for its design. Where Swift is "swift + LLVM", rustc is "rustc + (LLVM | Cranelift | GCC)". The flexibility is partly because MIR is far enough from LLVM IR that the lowering is non-trivial; the lowering is replaceable.

## miri as a standalone tool

miri (`rustc_const_eval`) is the MIR interpreter that powers `const fn` evaluation in rustc. It also runs as a standalone tool (`cargo miri`) for detecting undefined behaviour in Rust code.

What miri does standalone: interpret a program's MIR rather than executing the compiled binary, with strict checks for UB. Detects:

- Memory safety violations (use after free, double free, out-of-bounds access).
- Type confusion (transmuting incompatible types).
- Uninitialised memory reads.
- Dangling references.
- Race conditions (with the `experimental-data-race-detector` flag).

miri is much slower than running compiled code (~100x), but catches subtle bugs that escape testing on optimised builds. It is the standard tool for Rust unsafe-code review.

The shared engine: when rustc evaluates a `const fn`, it runs miri internally on the function's MIR. When the user runs `cargo miri`, it runs miri on the whole program's MIR. The same interpreter handles both cases.

For a reader, miri is the most concrete example of "abstract interpretation as a tool". The engine is well-engineered (handles memory provenance, allocator semantics, interior mutability) and worth studying as a production interpreter.

## Bootstrap stages

rustc bootstraps in three required stages plus an optional fixpoint stage:

- **Stage 0**: rustc beta from the previous release. Used to build stage 1.
- **Stage 1**: rustc compiled by stage 0, using the current source. The result is a working compiler but with some limitations.
- **Stage 2**: rustc compiled by stage 1. This is the production-equivalent compiler. The most thoroughly tested.
- **Stage 3** (optional): rustc compiled by stage 2. Used to verify that stage 2 reproduces itself (the fixpoint check).

The stages are conceptually equivalent to our 3-generation fixpoint, just with the addition of the beta-version starting point.

The build orchestration: `x.py build` is a Python wrapper that handles the multi-stage build. `x.py test`, `x.py check`, `x.py doc` are the related commands. Reading the bootstrap documentation in the rustc-dev-guide is the right preparation for working on rustc itself.

## Ecosystem in the same monorepo

rust-lang/rust is unusual in being a single repository for the language ecosystem:

- **library/{core,alloc,std,test}**: the standard library.
- **src/tools/cargo**: the build tool.
- **src/tools/rustfmt**: the formatter.
- **src/tools/clippy**: the linter.
- **src/tools/rust-analyzer**: the LSP server (mirrored from a separate repo).
- **src/tools/miri**: standalone miri.
- **src/tools/rustdoc**: the documentation tool.
- **src/tools/error_index_generator**: generates error code documentation.

The decision to keep these together (rather than as separate repos) is part of the project's "everything in lock-step" philosophy. Changes that span the language and the tools can be landed atomically. The cost: huge repository, slow CI.

For a reader, the monorepo structure means that learning rustc means learning more than the compiler. Cargo, rustdoc, the standard library: all are part of the same project, with the same review process.

## How rustc compares to LLVM and GCC

| Aspect | rustc | LLVM (used by Clang) | GCC |
|--------|-------|----------------------|-----|
| Frontend language | Rust only | Many (Clang, Swift, Julia, ...) | Many (C, C++, Fortran, Ada, ...) |
| IR layers | 4 (HIR, THIR, MIR, LLVM IR) | 1 (LLVM IR) | 3 (GENERIC, GIMPLE, RTL) |
| Distinctive analyses | Borrow checker on MIR | None Rust-specific | None Rust-specific |
| Backends | LLVM (default), Cranelift, GCC | Many | Many |
| Implementation language | Rust (self-hosted) | C++ | C and C++ |
| Codebase | ~3 million lines Rust | ~10 million lines C++ | ~15 million lines mixed |
| Incremental compilation | Query-based, mature | None at compiler level | None at compiler level |

rustc is an unusual case: it is itself self-hosted (the compiler is written in Rust), like our INTERCAL ambition. rustc bootstrapped through OCaml; it now compiles itself in three stages, the first of which uses a previous stable rustc.

## How rustc compares to our INTERCAL compiler

The INTERCAL compiler bootstraps the same way rustc does. zsh plays the role OCaml played for early Rust. After self-hosting, both projects can build themselves.

The differences are scale and the existence of an IR pipeline. rustc has four levels of IR; our compiler has none. rustc has a borrow checker and a type system; we have four numeric types and the politeness rule. rustc emits LLVM IR; we emit ARM64 or x86-64 assembly directly.

The conceptual map is the same. Lex, parse, check, lower, emit. Reading rustc with the vocabulary from this book in mind, you will see the same shape, just with each phase greatly enlarged and each IR level made explicit.

## If you only read five files

For getting your bearings in rustc's source:

1. `compiler/rustc_driver_impl/src/lib.rs`: the driver. Shows the phase pipeline end to end.
2. `compiler/rustc_middle/src/query/mod.rs`: the query DAG. Every cacheable computation lives here.
3. `compiler/rustc_borrowck/src/lib.rs`: the borrow checker entry point.
4. `compiler/rustc_next_trait_solver/src/solve/mod.rs`: the new trait solver.
5. `compiler/rustc_codegen_ssa/src/back/write.rs`: the codegen back-end shared layer between the LLVM, Cranelift, and GCC backends.

## Common contributor gotchas

- `./x.py check` before `./x.py build` saves hours.
- Adding a new query requires touching `rustc_middle/src/query/mod.rs` AND implementing the provider; the macro errors are cryptic.
- `tcx.lifetime` of inferred regions is meaningless outside the borrow checker.
- UI tests need exact stderr; run `./x.py test --bless` to update expected outputs.
- Using `-Znext-solver=globally` may hide bugs that only show with `coherence` mode.
- Do not add `tracing::info!` in hot query paths; use `debug!` and run with `RUSTC_LOG`.

## Area specialists

- lcnr: next solver, NLL.
- compiler-errors: trait solver, diagnostics.
- Nilstrieb: parser, span machinery.
- oli-obk: const eval, opaque types.
- petrochenkov: resolver, macros.
- Mark Rousskov: perf infrastructure.
- Zalathar: coverage, rollups.

## Notable recent PRs to read

- PR #145244 (lcnr): "non-defining uses of opaques in borrowck". Demonstrates how opaque-type subtlety surfaces in borrow checking.
- PR #140306: specialization in the new solver.
- PR #126614: next-solver uplift.

## Diagnostic flags worth knowing

- `-Zdump-mir=all`, `-Zdump-mir-graphviz`: MIR snapshots.
- `-Zverbose-internals`, `-Zprint-type-sizes`: type-system inspection.
- `-Zself-profile` plus `summarize`: per-query timing.
- `-Zthreads=1`: deterministic ICE reproduction.
- `RUSTC_LOG=rustc_borrowck=debug`: scoped tracing.
- `RUSTC_BACKTRACE=full`: see where an ICE was raised.
- `-Ztrack-diagnostics`: trace which compiler code emitted each diagnostic.

For nightly-regression bisection: `cargo bisect-rustc`. For incremental-compilation issues: `-Zincremental-verify-ich`.

## Reading the rustc-dev-guide

The [rustc-dev-guide](https://rustc-dev-guide.rust-lang.org/) is the single most useful document for understanding rustc. It is maintained alongside the compiler, kept in sync with the source, and explicitly written for new contributors. A reasonable order:

1. *Overview of the Compiler*: the front-to-back tour.
2. *The HIR*, *The THIR*, *The MIR*: the IR descriptions.
3. *Type Checking* and *Trait Solving*: the conceptual core of the type system.
4. *Borrow Checking* and *Drop elaboration*: the Rust-specific bits.
5. *Code Generation*: how MIR becomes LLVM IR and then machine code.
6. *Queries and the query system*: how incremental compilation works.

After this book and the dev guide, you have the vocabulary to start opening compiler issues and reading the code that fixes them.

## How to contribute

GitHub PRs to <https://github.com/rust-lang/rust>. Every PR needs an `r=<reviewer>` comment from a designated reviewer; bors is the merge bot. Mentored issues come with a designated `r?@<reviewer>` already assigned.

Beginner-friendly issues:

- `E-easy` and `E-mentor` labels: explicitly identified for new contributors.
- `A-diagnostics`: diagnostic-message improvements, often small and high-value.
- `A-clippy`: lints in the Clippy linter.
- `A-rustdoc`: rustdoc improvements.
- `A-incr-comp`: incremental compilation improvements (smaller scope, bounded).

Build:

    git clone https://github.com/rust-lang/rust
    cd rust
    cp config.example.toml config.toml
    # edit config.toml: set profile = "compiler"
    ./x.py build

The first build is slow (an hour or so) because of the multi-stage bootstrap. Incremental builds of single crates take seconds.

## Where to go next

- The [rustc-dev-guide](https://rustc-dev-guide.rust-lang.org/) is the single most important document.
- *The Rustonomicon* at <https://doc.rust-lang.org/nomicon/> for unsafe Rust details that the compiler enforces.
- "Stupid Stupid xargs" by Niko Matsakis (and other Niko blog posts at <https://smallcultfollowing.com/babysteps/>) for the design history of the borrow checker.
- [contributing-to-production-compilers.md](contributing-to-production-compilers.md) for how to land a first patch on rustc.
- [llvm-overview.md](llvm-overview.md) for the backend rustc uses by default.
- [cranelift-overview.md](cranelift-overview.md) for the alternative debug backend.
- [gcc-overview.md](gcc-overview.md) for the alternative production backend (`rustc_codegen_gcc`).
- [from-intercal-to-real-compilers.md](from-intercal-to-real-compilers.md) for the bridge from this book's content to production-compiler work.
