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

## A skill ladder, week by week

The reading plan above answers "what". This section answers "what does my first month actually look like". Treat the schedule as a guide, not a contract. Some weeks compress; others stretch.

**Week 1: vocabulary acquisition.** Read this book's Parts I-V if you have not already. Run through the exercises in [getting-started.md](getting-started.md). Compile a few of `tests/test_*.i` and trace the output back to the source through `intercalc.sh`. By the end of the week you should be able to point at any line in `intercalc.sh` and say which phase of compilation it belongs to. The goal is fluency in the vocabulary: lexer, parser, semantic analysis, codegen, runtime.

**Week 2: pick a target and build it.** Choose one of the ten production compilers. Build the project from source as documented in [contributing-to-production-compilers.md](contributing-to-production-compilers.md). Set aside a full day; it will take longer than you expect. Run the project's test suite. Verify your build can compile a hello-world in the project's source language. The goal is having a development environment that works.

**Week 3: read your way around.** Pick the corresponding overview chapter ([llvm-overview.md](llvm-overview.md), [gcc-overview.md](gcc-overview.md), [rustc-overview.md](rustc-overview.md), [go-overview.md](go-overview.md), [ghc-overview.md](ghc-overview.md), [ocaml-overview.md](ocaml-overview.md), [cranelift-overview.md](cranelift-overview.md), [zig-overview.md](zig-overview.md), [swift-overview.md](swift-overview.md), or [v8-overview.md](v8-overview.md)). Then read the project's own developer guide (rustc-dev-guide, gccint, LLVM docs, GHC Commentary). The goal is internal-vocabulary fluency: when you read "MIR" or "STG" or "SIL", you know what is meant.

**Week 4: read source until something feels obvious.** Pick a small subsystem and read it line by line until you understand it. Good first targets per project: a single LLVM pass under `llvm/lib/Transforms/Scalar/`; a single GIMPLE pass in GCC; a single MIR transform in rustc; a single SSA pass under `cmd/compile/internal/ssa/` in Go; a single mandatory SIL pass in Swift; the regalloc2 spill heuristic in Cranelift; one Sema function in Zig. The goal is the moment when reading a function in the project's source feels like reading any other code, not like deciphering a foreign language.

**Weeks 5-6: small contribution.** Find a `good first issue` (or equivalent label) that touches the subsystem you read. Reproduce the bug locally. Write a failing test (every project requires this). Implement the fix. Run the test suite. Open the PR (or send the patch). Iterate on review feedback. The goal is your first merged change.

The whole sequence is six weeks of part-time work. Some people compress it to two; others stretch to six months. Either is fine.

## Mental-model shifts

Moving from this compiler's codebase to a production compiler requires several mental shifts. Naming them up front shortens the adjustment period.

**From "every line is comprehensible" to "you only ever see the part you are working on".** Our `intercalc.sh` is 2,000 lines. You can read it in a sitting. LLVM, GCC, rustc are millions of lines. Nobody reads them top to bottom. Production-compiler work is "find the file, understand the function, leave the rest unread". The skill is locating the file fast. Project-internal documentation, dev guides, and `git log` for the area you care about are how you do this.

**From "no IR" to "many IRs".** Our compiler turns the parse tree directly into assembly. Every production compiler has at least one IR; some have four (rustc, GHC). Each IR has a purpose: name resolution, type checking, optimisation, codegen. Tracking which IR you are looking at, and what it does and does not contain, is a constant low-grade effort. Asking "is this MIR or HIR?" should be a reflex.

**From "shell script glue" to "library architecture".** Our compiler is a shell script with assembly templates. Production compilers are libraries with stable internal APIs, plugin points, and pass managers that orchestrate hundreds of transformations. The infrastructure is itself the bulk of the code; the actual transformations are often shorter. Reading "the architecture" is reading the pass manager, the IR builders, the analysis caches, the diagnostic system. The transformations sit on top.

**From "one platform per build" to "every build is a target choice".** We compile on macOS ARM64 or Linux ARM64 or Linux x86-64; the choice is the platform we are running on. Production compilers cross-compile by construction. Every build picks a target triple. Backends are selected per target. Calling conventions, ABIs, and instruction set details parameterise everything. A change that "works on my machine" can break on a target you have never personally seen.

**From "we test functionality" to "we test invariants".** Our tests run a compiled program and check stdout. Production compilers also do this, but layered on top of invariant tests: the IR after this pass is well-formed; the SSA invariants hold; the type checker accepts known-good programs and rejects known-bad; the borrow checker satisfies the formal properties of NLL. The bulk of the test infrastructure is invariant checking, not end-to-end functional testing. Adding a new pass means adding new invariant tests.

**From "I understand every error" to "this error came from a system I have not seen".** When something fails in our compiler, you can trace it to a specific zsh function in 20 minutes. In production compilers, failures cross subsystem boundaries. A bug in instruction selection might surface as a misoptimised loop reported by a user who is debugging their game. Diagnostic tools (LLVM's `--debug-only=`, rustc's `-Z` flags, Go's `-d=ssa/<phase>=N`) become essential. Learning the diagnostic surface is a project of its own.

**From "the language is small" to "the language has a 30-year history".** INTERCAL has fifteen statement types and four data types. C++ has hundreds of features, decades of accreted decisions, and ABI commitments to thirty years of binaries. The conservatism of production compilers reflects this. A change that "looks obvious" might break a kernel module compiled in 2010. The review process is calibrated for this risk.

## Concrete bridges per compiler

Each compiler has specific exercises that bridge from "I read the chapter" to "I can edit the source". The exercises below are deliberately small. Each is doable in an afternoon if you know where to look. None requires submitting a patch.

### LLVM bridge exercise

Goal: write your first LLVM pass.

1. Build LLVM and Clang locally (see [contributing-to-production-compilers.md](contributing-to-production-compilers.md)).
2. Pick `llvm/lib/Transforms/Utils/HelloPass.cpp` (or the equivalent template) and study it.
3. Write a pass that counts the number of `add` instructions per function and prints the count.
4. Run it on `clang -O0 -c -emit-llvm` output for a small C file.
5. Verify the count matches what `opt -print-instructions` reports.

The point is not the pass itself; it is the loop "edit C++, rebuild, run, iterate". By the time you have done this, you have absorbed the LLVM build system, the pass-manager API, the IR walking idioms, and the diagnostic flags. Future passes are variations on the same loop.

The closest analog in our compiler: writing a new function in `intercalc.sh` that walks `stmt_*` arrays and prints something. Same shape, different language.

### Cranelift bridge exercise

Goal: write your first ISLE rule.

1. Build Cranelift (`cargo build -p cranelift-codegen`).
2. Open `cranelift/codegen/src/isa/x64/lower.isle` and read existing rules until they feel familiar.
3. Pick a small operation (say, `iadd`) and add a rule that recognises a specific pattern (e.g., adding zero) and rewrites it to a no-op.
4. Add a filetest in `cranelift/filetests/filetests/runtests/i32-add.clif` that triggers the rule.
5. Run `cargo test -p cranelift-filetests` and watch your rule fire.

The point is that ISLE is declarative: a pattern plus a result. Once one rule lands, every other rule is the same mental shape. Production-grade work in Cranelift is mostly adding such rules and refining heuristics.

The closest analog in our compiler: adding a constant-folding case in `eval_const`. Same shape (pattern: input form → output form), different syntax.

### Go bridge exercise

Goal: write your first SSA optimisation rule.

1. Build Go from source (`./make.bash`).
2. Open `src/cmd/compile/internal/ssa/gen/generic.rules` and read the first 200 lines.
3. Add a rule that simplifies a pattern (start with something like `(Mul64 x (Const64 [1])) => x`).
4. Run `go run gen/*.go` to regenerate the rule-handler Go code.
5. Build the compiler and run `go test -run TestSSA` to verify nothing breaks.
6. Compile a small program that triggers your pattern and dump SSA with `-gcflags='-d=ssa/opt=2'` to see the rewrite happen.

Go's `.rules` files are conceptually the same as ISLE. The dialect differs but the shape is identical.

The closest analog in our compiler: adding a rule to the (currently small) peephole_optimize. We do peephole on emitted assembly text rather than on SSA, but the "match a pattern, rewrite it" idea is the same.

### rustc bridge exercise

Goal: write your first MIR transformation.

1. Build rustc (`./x.py build`).
2. Open `compiler/rustc_mir_transform/src/simplify.rs` and read it.
3. Pick a tiny structural simplification (e.g., remove unreachable blocks). Either improve an existing pass or write a new one in the same directory.
4. Wire it into the pipeline in `compiler/rustc_mir_transform/src/lib.rs`.
5. Add a regression test under `tests/codegen/` that exercises the change.
6. Run `./x.py test tests/codegen` and `./x.py test tests/ui`.

rustc's MIR transforms are straightforward Rust. The barrier is build time (the bootstrap), not the code itself.

The closest analog in our compiler: adding a new pass to the `main()` function in `intercalc.sh`. Same idea (transform after parsing, before codegen), production scale.

### GHC bridge exercise

Goal: add a Core simplifier rule.

1. Build GHC (`hadrian/build`).
2. Open `compiler/GHC/Core/Opt/Simplify.hs` and surrounding files.
3. Find an existing rule and read it carefully. The simplifier has hundreds; pick one that is small and self-contained.
4. Write a regression test in `testsuite/tests/simplify/` that exercises a simplification GHC currently does.
5. Run `hadrian/build test --only=simplify`.

The simplifier is the heart of GHC's optimiser. Once one rule is comprehensible, the rest become tractable.

The closest analog in our compiler: `eval_const` constant-folding. Conceptually a tiny simplifier, operating on a tiny expression language.

### OCaml bridge exercise

Goal: trace type inference on a tricky program.

1. Build OCaml (`./configure && make`).
2. Open `typing/typecore.ml`. Find `type_expression`.
3. Compile a small program with `-dtypedtree` to see the typed AST OCaml produced. Find an expression and trace it through `type_expression`.
4. Now write a program that triggers a polymorphic generalisation (e.g., `let id x = x in ...`). Trace through the level mechanism in `typing/btype.ml`.
5. Add a comment to the source explaining what you found.

OCaml's type checker is the canonical Hindley-Milner implementation. Reading it is reading the algorithm.

The closest analog in our compiler: `check_politeness` and `check_labels`. Conceptually they do the same kind of work (analyse properties of the parsed program), at a much simpler level.

### Zig bridge exercise

Goal: trace one comptime evaluation through Sema.

1. Build Zig.
2. Write a tiny comptime function: `fn double(comptime x: u32) u32 { return x * 2; }`.
3. Compile with `-femit-zir` to see the ZIR.
4. Open `src/Sema.zig` and find where `double` is called: search for the relevant operation handler.
5. Add a `std.debug.print` call inside Sema's handler for `mul` and rebuild Zig.
6. Recompile your test program. You should see the print fire when the comptime call evaluates `2 * 2`.

The point is that comptime is just Sema interpreting the IR. Once you have done one trace, the rest of Sema is the same kind of code.

The closest analog in our compiler: `eval_const`. We do a tiny version of Zig's comptime: walk the parse tree, evaluate sub-expressions where all operands are constant.

### Swift bridge exercise

Goal: trace a SIL optimisation pass.

1. Build Swift (allocate hours and ~50 GB).
2. Compile a small Swift file with `-emit-sil` and look at the output.
3. Pick an optimisation (e.g., `lib/SILOptimizer/Transforms/SimplifyCFG.cpp`). Read the pass.
4. Modify a Swift program until you can see the pass change SIL output. Add a `// CHECK:` comment for FileCheck.
5. Add the regression test under `test/SILOptimizer/`.

Swift's SIL is the most semantically rich IR in this Part. Reading SIL output for a generic function with protocol witnesses is a course in itself.

The closest analog in our compiler: nothing direct. We have no IR. The lesson is conceptual: production IRs preserve language semantics, and passes operate on those semantics.

### V8 bridge exercise

Goal: see speculation in action.

1. Build V8 (`fetch v8 && cd v8 && gn gen out/x64.optdebug && ninja -C out/x64.optdebug`).
2. Run d8 (the standalone V8 shell) on a script that has a hot loop with a polymorphic property access.
3. Watch with `--trace-opt --trace-deopt`.
4. Modify the script to break the IC's assumption (suddenly write a different shape). Watch the deoptimisation fire.
5. Adjust the script until it exercises tier promotion: Ignition → Sparkplug → Maglev → TurboFan.

The point is to internalise that speculation is a compiler-runtime contract. The optimiser bets; the runtime collects the bet or pays out.

The closest analog in our compiler: nothing. AOT compilers do not speculate. The lesson is purely conceptual.

### GCC bridge exercise

Goal: read one GIMPLE pass deeply.

1. Build GCC (`./configure --enable-languages=c && make`).
2. Open `gcc/tree-ssa-dce.cc`. Read it.
3. Compile a small C program with `-fdump-tree-all` and find the dead-code-elimination dump.
4. Modify the C source until you can see DCE remove a specific statement.
5. Trace the removal in the GIMPLE dump.

The point is to learn how dumps tie source code to the IR. Once you can read GIMPLE dumps, every later GIMPLE pass is approachable.

The closest analog in our compiler: `compute_flag_checks`. We do a similar dataflow (per-statement analysis of "is this flag ever touched") with the result removing dead code.

## What to read while building

A reading list ordered by when you are likely to need each item.

**While picking a target compiler**: each per-compiler chapter in this Part. They are deliberately self-contained.

**While building the project**: the project's developer guide. rustc-dev-guide is the gold standard; LLVM has the docs at <https://llvm.org/docs/>; GCC has gccint; GHC has the Commentary; Go has the in-source READMEs.

**While reading source**: the relevant overview chapter (in this book) plus the project's IR specification. LangRef.rst for LLVM. The MIR specification in rustc-dev-guide. The GHC Commentary's Core chapter. The SIL.md file in the Swift repo.

**While writing your first patch**: the project's coding style guide and contribution guide. Not optional. Production compilers reject patches that violate style on first review. Save yourself the back-and-forth.

**For the long run**: a textbook. *Engineering a Compiler* (Cooper and Torczon, 3rd edition 2023) is the modern reference. *Modern Compiler Implementation in ML* (Appel) is the academic counterpart. Read alongside the source as you encounter concepts in the wild.

## Exit criteria for a first patch

You are ready to submit a first patch when:

- You can build the compiler in under five minutes from a clean tree (assuming a warm `ccache`/incremental cache).
- You can run the test suite for the area you are touching.
- You have read at least three previous patches in the same area, observed how they were structured, and learned the conventions.
- You can explain, in two sentences, what your patch does and what test would fail without it.
- You have a regression test that fails on `main` and passes with your patch.
- You have read the project's contribution guide for the specific area.

If any of these are not yet true, you are still in the preparation phase. Do not rush. The cost of a thoroughly-prepared first patch is a week. The cost of an under-prepared first patch is a month of review thread, a withdrawn contribution, and a bruised relationship with the maintainers.

## Cross-references to advanced techniques

The chapters that follow this one go much deeper into specific compiler techniques:

- [techniques-we-use.md](techniques-we-use.md): every advanced technique present in this compiler, explained in production-compiler vocabulary. If you understand our `eval_const`, you understand a slice of LLVM's `InstCombine`. If you understand our `compute_flag_checks`, you understand a slice of GCC's tree-level DCE. The chapter names the correspondences.
- [techniques-we-lack.md](techniques-we-lack.md): every advanced technique missing from this compiler, organised by phase. SSA construction, register allocation, garbage collection, JIT speculation, polyhedral optimisation. The chapter is a roadmap of the design space, with pointers into each production compiler that exemplifies a technique.
- [improvement-proposals.md](improvement-proposals.md): twenty concrete proposals (eight Tier 1 quick wins, seven Tier 2 medium investments, five Tier 3 major undertakings) for which Part VII and Part VIII techniques to bring back to our compiler. Each proposal carries its own algorithm sketch, where in the codebase it would live, effort estimate, dependencies, test strategy, risks, educational value, and references.

Treat the four chapters (this one plus the other three) as the bridge in four layers: this one for the conceptual map, "we use" for "what you already know in production-compiler vocabulary", "we lack" for "what to read next", "improvement-proposals" for "what to actually do".

## After the first patch: the medium term

The skill ladder above tops out at landing your first PR. Production-compiler engineering is a much longer game. The medium-term picture, organised by ambition.

### The "ten patches" plateau

Most contributors plateau here. You have landed a handful of changes, are subscribed to the right mailing lists or labels, the maintainers know your name. Your changes are typically incremental: a missing pattern in instruction selection, a small correctness fix in a pass, an improvement to a diagnostic message. The work is satisfying and the cadence is sustainable.

The skill being honed at this stage is *navigating the codebase quickly*. By patch ten, you should be able to find any subsystem you have not yet touched in under five minutes via a combination of `grep`, mailing-list archives, `git log -p`, and the project's developer documentation. You should also have a rough mental map of who owns what, which areas welcome refactoring and which to leave alone, and what the maintainers' aesthetic preferences are (does this project like long names or short ones; does it run linters strictly; does the review process tolerate large diffs).

How to deepen at this stage: read other contributors' patches, especially the ones that get extended review discussions. The friction in the discussion is where the project's values surface. A patch that gets immediate approval taught you what was correct; a patch that took ten rounds of review taught you what is contentious.

### The "owns a subsystem" plateau

A handful of contributors per project go further. They become the de facto owner of a subsystem: regalloc2 in Cranelift, the borrow checker in rustc, the inliner in LLVM, the constraint solver in Swift. The role is not formal in most projects (LLVM has no "owner" titles); the recognition emerges from sustained contribution.

The skill at this stage is *system-level design*. Reviews you give are no longer "this looks right"; they are "this changes the contract between the inliner and the optimiser; have you considered the case where the inlined function has effects?". Patches you write are not bug fixes; they are architecture changes that might span thousands of lines and require coordinating with several other subsystems.

How to reach this stage: pick a subsystem that is undersupported and adopt it. The path is not glamorous; you are reading old code, fixing technical debt, writing tests for things nobody tested, documenting things nobody documented. Two years of patient work in one subsystem usually produces ownership-level expertise; one year is rare.

### The "designs a feature" plateau

A few contributors design new compiler features end to end: a new optimiser pass that did not exist; a new IR layer; a new type-system extension. This is rare and high-stakes; it requires alignment with the project's leadership, not just the code reviewers.

The skill at this stage is *organisational design*. You write an RFC. You convince several maintainers it is worth doing. You implement a prototype. You adjust based on review. You shepherd the feature to stable. The work is mostly meetings and writing, less coding.

How to reach this stage: be one of the recognised owners of a related subsystem first. The trust required to land a major design comes from years of credibility. Some projects have a more open process (Rust's RFC procedure, GHC's Haskell Foundation tech proposal); others are more closed (Apple drives Swift evolution from inside).

## Maintaining a fork

A specific senior task that comes up often: maintaining a fork of a production compiler.

Reasons companies fork:
- **Vendor patches**: a chip vendor adds optimisations specific to their target before they are upstream.
- **Stability lock-in**: a downstream project pins to a known-good revision and backports critical fixes.
- **Feature divergence**: a product needs functionality not aligned with upstream priorities (e.g., heavy compile-time configuration).
- **License-driven divergence**: less common, mostly historical.

Notable forks in production:
- Apple maintains a fork of LLVM/Clang for Xcode, with patches that go upstream eventually but lag main.
- Google maintains internal LLVM/Clang forks, partly for stability and partly for security tooling.
- Many embedded vendors fork GCC for specific instruction-set extensions.
- Mozilla forked rustc briefly during the 2018 edition transition.

The skills involved:
- *Cherry-picking* upstream commits cleanly. `git cherry-pick -x` to record provenance.
- *Conflict resolution* when downstream patches and upstream changes touch the same files.
- *Re-baseline strategy*: how often do you rebase the fork on upstream `main`? Yearly? Per-LLVM-release? Continuous?
- *Test infrastructure*: a fork needs its own CI, often inheriting upstream test counts plus fork-specific tests.
- *Communication with upstream*: aim to land patches upstream over time so the fork shrinks.

For our INTERCAL compiler the analog is small but real: when somebody packages our compiler in a Linux distro, they are effectively maintaining a fork (with a delta of distro-specific build flags). The principles transfer.

Reading: Chromium's "How we maintain a fork of LLVM" blog posts; Apple's tracked fork in their public llvm-project mirror; GCC's vendor branches.

## Backporting

A subset of fork-maintenance: bringing fixes from one branch to another. Production compilers have multiple branches in flight: `main`, `release/X.Y` for the current stable, `release/X.Y-1` for the previous. A regression in stable means cherry-picking the fix from `main` to the release branch.

Conventions vary:
- LLVM has `release/<X>.x` branches with `[X.x]` prefixed PRs for backports.
- rustc has stable, beta, and nightly. Most fixes land in nightly; some are explicitly nominated for backport via the `beta-nominated` and `stable-nominated` labels.
- GHC has `ghc-X.Y-stable` branches.
- Go's release process backports critical fixes to the previous two minor versions.

The trade-off: backporting a fix improves the stable release, but every backport is a divergence from main and a risk of new regressions. Maintainers are conservative.

For our INTERCAL compiler: we have one branch (`main`) and tags (`v0.1.0`). The lesson transfers if the project ever ships maintenance releases.

## Designing new optimisations

Designing an optimisation that has not been built before is the most senior compiler-engineering task. Most production compilers have a hundred optimisations; the rare twentieth-or-so addition is a serious project.

The shape of the work:

1. *Identify a class of programs that are slower than they should be*. Either by reading benchmarks (SPEC, PolyBench), profiling production code, or noticing a pattern that repeats in user-reported issues.
2. *Hypothesise an optimisation*. The hypothesis must be both *correct* (preserves observable behaviour) and *profitable* (saves time or space measurably).
3. *Build a prototype*. Single-pass implementation, narrow scope. Run on a small benchmark suite.
4. *Measure carefully*. Optimisations almost always trade compile time for runtime. The trade-off must be net positive on representative code.
5. *Generalise*. Handle all the edge cases the prototype skipped. Add tests for each.
6. *Submit*. Expect deep review; the project's senior engineers will have opinions about whether your optimisation belongs in the canonical pipeline, with what cost model, in what phase order.

Examples of recent optimisation additions and the work they entailed:
- *LLVM's LoopVectorize*: years of incremental additions starting around 2013. Major rewrites multiple times. The current code is the work of dozens of contributors over a decade.
- *rustc's GenericSpecialization improvements*: ongoing for years, with each release tightening the specialiser.
- *Cranelift's egraph optimiser*: introduced in 2022 by Chris Fallin, replacing several smaller optimisers with one e-graph-based pass.
- *Go's PGO support*: introduced in Go 1.21, refined incrementally.

The lesson: senior optimisation work is a multi-year arc, not a single PR.

## Influencing language design

The deepest level. The compiler is the language's implementation; whoever owns the compiler also influences the language. In open-source projects, this influence is usually shared with a language-design committee or a benevolent dictator.

How influence is exercised:
- Publishing RFCs (Rust's RFC repo, Swift's evolution repo, Haskell's prime track).
- Implementing experimental features behind unstable feature gates (rustc's `#![feature(...)]`, GHC's `{-# LANGUAGE ... #-}`).
- Engaging in design discussions on the language's primary forum (rust-lang discourse, swift-evolution mailing list, haskell.org committee).
- Authoring papers that propose new features with prototypes (common in OCaml and Haskell history).

For somebody on this path, the compiler is the medium for a language-design conversation. The commits become arguments in the discussion. Effectiveness comes from the commits being correct, well-reviewed, and demonstrating the proposed feature works in practice.

For our INTERCAL compiler: the language is fixed by the 1972 specification. We do not get to influence INTERCAL. The lesson is conceptual: in projects where language design is alive, the compiler is the front line.

## Long-term reading

A reading list for somebody who has reached the "owns a subsystem" stage and wants to deepen:

- *Engineering a Compiler* (Cooper and Torczon, 3rd edition 2023). The modern textbook reference.
- *Modern Compiler Implementation in ML* (Andrew Appel). The academic counterpart, goes deeper on type theory.
- *Optimizing Compilers for Modern Architectures* (Allen and Kennedy 2001). The reference for loop optimisation and vectorisation.
- *The Garbage Collection Handbook* (Jones, Hosking, Moss, 2nd edition 2023). The reference for runtime memory management.
- *Advanced Compiler Design and Implementation* (Muchnick 1997). Pre-SSA but still the reference for many classical algorithms.
- *Types and Programming Languages* (Pierce 2002). Type-system theory.
- *Practical Foundations for Programming Languages* (Harper, 2nd edition 2016). The deeper theoretical grounding.

Plus, depending on specialisation:
- *Compiling with Continuations* (Appel 1992) for functional-language back ends.
- *Hacker's Delight* (Warren 2nd ed.) for low-level bit manipulation, branchless code.
- *Linkers and Loaders* (Levine 1999) for the post-codegen world.
- *Computer Architecture: A Quantitative Approach* (Hennessy and Patterson 6th ed.) for the target side.
- *Programming Language Pragmatics* (Scott 4th ed.) for survey-level breadth.

Plus, conference proceedings:
- *PLDI* (Programming Language Design and Implementation) annually.
- *POPL* (Principles of Programming Languages).
- *CC* (Compiler Construction).
- *CGO* (Code Generation and Optimization).
- *ICFP* for functional-language work.
- *OOPSLA* for object-oriented and dynamic-language work.

Most major compiler features were proposed in one of these venues before being engineered into production. Reading current proceedings is reading where the next decade's compilers will go.

## Compiler engineering specialisations in 2026

"Compiler engineer" is one job title hiding ten distinct careers. The skills overlap; the day-to-day work, target codebases, and hiring pipelines do not. A reader picking a track benefits from naming the choice early.

### Frontend engineer

Lexers, parsers, name resolution, type checking, diagnostics. The work is closest to the early chapters of this book. A frontend engineer at Apple writes Clang's Sema; at rustc, the borrow checker and trait solver; at TypeScript, the structural-typing inference; at Swift, the constraint solver. Diagnostics quality is half the work; an unhelpful error message is a bug. Prerequisites: parsing, type theory, language semantics. Pierce's *Types and Programming Languages* is the standard text. Apple, Microsoft (TypeScript, C#), Mozilla, JetBrains (Kotlin) and the Rust project hire here.

### Optimiser engineer

The middle end: SSA, dataflow, loop analyses, vectorisation, inlining, partial redundancy elimination. The work is reading benchmarks, hypothesising transformations, prototyping passes, fighting compile-time regressions. Optimiser engineers tend to congregate at LLVM (Apple, Google, ARM), GCC (Red Hat, SUSE, AdaCore), rustc, Go, and GHC. Prerequisites: SSA construction, dataflow analysis, the classical optimisation literature. Cooper and Torczon, then Muchnick.

### Backend engineer

Instruction selection, register allocation, instruction scheduling, machine descriptions, calling conventions. The work parameterises by ISA: x86-64, ARM64, RISC-V, GPU dialects, custom accelerators. Vendor work dominates here. NVIDIA, AMD, Intel, ARM, Qualcomm, Apple Silicon all run large backend teams. Embedded vendors maintain GCC and LLVM forks for niche targets. Prerequisites: computer architecture (Hennessy and Patterson), the target's ISA reference, register allocation papers (Chaitin, Poletto-Sarkar, Wimmer linear scan, regalloc2 SSA-based).

### Runtime engineer

Garbage collectors, schedulers, linkers, dynamic loaders, ABIs, exception handling. The runtime is half the language's behaviour at execution time. Go's GC team, V8's Orinoco, GHC's RTS, OCaml's runtime, .NET's CoreCLR, the JVM (Oracle, Azul, Amazon Corretto), Swift's ARC and concurrency runtime are all runtime engineering. Prerequisites: *The Garbage Collection Handbook*, knowledge of the target OS's memory model, lock-free programming.

### ML compiler engineer

The fastest-growing track. Take a neural network expressed in PyTorch or JAX, lower it through MLIR or a custom IR, fuse operations, tile for the target's memory hierarchy, generate kernels for GPU, TPU, or NPU. The toolchains are XLA, TVM, IREE, Triton, Mojo, the Modular stack. NVIDIA, Google, Meta, Apple, Modular, Anthropic, OpenAI, Cerebras, Tenstorrent, AWS Annapurna, Groq, Graphcore, Qualcomm AI all hire heavily. Compensation is the highest in the field. Prerequisites: linear algebra, GPU programming (CUDA or its analogues), MLIR, plus standard compiler skills. The combination of compiler and ML background is rare; either alone is not enough.

### GPU compiler engineer

Adjacent to ML compilers but distinct. The work is shader compilation (Vulkan, Metal, DirectX), CUDA backend, ROCm, ray-tracing intrinsics, warp-level optimisation. NVIDIA's NVPTX backend in LLVM, AMD's ROCm, Apple's Metal, Intel's compute stack. Prerequisites: SIMT execution, the target GPU's microarchitecture, divergence analysis, register pressure under massive parallelism.

### Security and sanitizer engineer

ASan, MSan, UBSan, TSan, LSan, CFI, ShadowCallStack, fuzzing harnesses, hardening transformations. Compilers as the last line of defence. Google's sanitizer team, Apple's PAC and CFI work, Microsoft's CFG and CET enablement. Constant-time codegen for cryptography sits here too: the Clangover attack of 2024 showed that a compiler can turn constant-time source into secret-dependent machine code, opening cryptographic implementations to timing side-channels. Prerequisites: knowledge of common vulnerability classes, dynamic analysis instrumentation, the target's hardware-security features.

### HLS engineer

High-Level Synthesis: compiling C, C++, or domain-specific languages to FPGA bitstreams. Xilinx (now AMD) Vivado HLS, Intel HLS, Cadence Stratus. The IR pipeline ends at hardware, not software. Smaller community than software compilers, but well-paid and aging slowly. Prerequisites: digital logic, Verilog or VHDL, polyhedral analysis for loop transformations.

### Language designer

The track with the fewest jobs but the longest reach. Designs evolution proposals, drives RFC processes, shepherds feature acceptance. Most language designers are also senior compiler engineers; the job rarely exists in isolation. Apple drives Swift evolution from inside; Rust has an open RFC process; Haskell's GHC Steering Committee gates language extensions; the Go team is small and centralised. Prerequisites: years of credibility on the implementation side, plus writing skill.

### Compiler verification engineer

Formal proofs that a compiler preserves semantics. CompCert (the verified C compiler) qualified for DO-178C avionics certification in March 2026. CakeML for ML. The CertiCoq line of work for Coq. The track is small but growing as safety-critical and cryptographic deployment forces more rigorous guarantees. Prerequisites: a proof assistant (Coq/Rocq, Lean, Isabelle), operational semantics, the published verification literature. Most jobs here are in research labs (INRIA, MPI-SWS) or at companies with regulated safety profiles (AbsInt, Galois, Adelard).

## Industry hiring landscape

The CompilerJobs directory ([mgaudet.github.io/CompilerJobs](https://mgaudet.github.io/CompilerJobs/)) tracks more than 200 organisations with compiler teams. The headline employers in 2026:

- Apple: Clang, LLVM, Swift, GPU compilers, JavaScriptCore. Multiple sites.
- Google: Go, V8, Dart, MLIR, Tink, internal LLVM forks for production.
- Meta: PyTorch compiler, HHVM, Cinder (Python), HipHop, BOLT, internal LLVM contributions.
- Microsoft: MSVC, C#, F#, TypeScript, the Rust compiler, Python acceleration.
- NVIDIA: PTX backend, Triton, MLIR, CUDA toolchain, deep-learning compilers. Listings open through 2026 for LLVM and MLIR engineers, with deep-learning compiler salaries quoted at 144k to 270k base for senior roles.
- AMD: ROCm, Vivado HLS, internal LLVM work, GPU codegen.
- Intel: oneAPI, ISPC, GPU compiler, classical x86 backend tuning.
- ARM: LLVM/GCC backend tuning for Neoverse and Cortex, autovectorisation.
- Qualcomm: NPU compiler stack, deep-learning toolchains, LLVM downstream.
- Mozilla: SpiderMonkey, contributions to Rust.
- Bytecode Alliance: Wasmtime, Cranelift, the WebAssembly Component Model. Cranelift is the entry-point recommendation for new compiler engineers in this Part because the codebase is small and the maintainers are welcoming.
- Modular: Mojo, MAX. ML-compiler-first company.
- Anthropic: language and compiler work supporting model serving and infrastructure.
- Cerebras, Tenstorrent, Groq, Graphcore, SambaNova: ML accelerator compilers.
- AWS Annapurna: Inferentia and Trainium toolchains.
- Jane Street: OxCaml, the internal OCaml fork.
- Embedded vendors: STMicro, NXP, Renesas, Espressif. Mostly GCC, increasingly LLVM.

Role expectations layer roughly:

- *Entry-level / new grad*: a CS degree (bachelor or master), an open-source contribution to a compiler or runtime project, comfort with C++ or Rust, and the textbook material from one of *Engineering a Compiler*, *Modern Compiler Implementation*, or a graduate course. Internships are the dominant pipeline; NVIDIA and Apple run large compiler-internship programmes, and most of the senior engineers came in that way. Total compensation in the US ranges roughly 130k to 200k for new-grad compiler roles at FAANG-tier companies, with stock and bonuses pushing the higher number.
- *Mid-level (3 to 7 years)*: independent ownership of a subsystem (one inliner, one register allocator, one ISA backend), a track record of shipped patches reviewed by maintainers, and the ability to write design documents that hold up to scrutiny. Compensation 200k to 350k at established compilers companies, with a long tail higher at ML-compiler startups.
- *Senior and staff*: cross-subsystem design ownership, RFC authorship, the ability to mentor mid-level engineers and hold the codebase's invariants in their head. The job is mostly review, design, and dispute resolution. Compensation 350k to 700k+ at FAANG, with ML-compiler equity packages occasionally outpacing the rest.

The ratio of open positions to qualified candidates remains skewed toward demand. Compiler engineering is one of the few subfields where senior hires routinely command above-market offers because the supply of people who have shipped a working IR pass is small.

## Reading academic papers effectively

Compiler engineering is one of the few industrial fields where the production code and the research literature share authors. A patch in LLVM's loop vectoriser is often the implementation of a recent paper. The skill of reading papers fluently pays back through the rest of the career.

### The conferences worth tracking

- *PLDI* (Programming Language Design and Implementation): the flagship venue, annual. PLDI 2026 is in Boulder, Colorado, June 17 to 19. Compiler optimisations, IR designs, and implementation results dominate.
- *POPL* (Principles of Programming Languages): more theoretical, type systems, semantics, verification. POPL 2026 is in Rennes, France.
- *OOPSLA*: object-oriented, dynamic-language, GC and runtime work. Part of the SPLASH umbrella.
- *CC* (Compiler Construction): smaller, more focused on compiler-engineering papers without the theoretical heft.
- *CGO* (Code Generation and Optimization): backend, register allocation, instruction selection, profile-guided work. CGO 2026 is in Sydney, co-located with HPCA, PPoPP, and CC.
- *ASPLOS*: architectural support for programming languages and operating systems. The cross-cut between hardware and compilers.
- *MICRO*: microarchitecture. Less PL-focused but where many backend ideas originate.
- *ICFP*: functional programming. The natural home for GHC and OCaml work, plus type-system advances.

The PACMPL series ([dl.acm.org/journal/pacmpl](https://dl.acm.org/journal/pacmpl)) publishes accepted papers from PLDI, POPL, ICFP, and OOPSLA in open-access form. ACM SIGPLAN sponsors the major venues; member access is cheap relative to the value.

### How to skim a paper

The standard technique, attributed to S. Keshav, is the three-pass approach. The first pass takes ten minutes: read the title, abstract, introduction, section headings, conclusions, and skim the references. After this pass you should know what the paper claims, what kind of paper it is (theoretical, engineering, or empirical), and whether it is worth a second pass.

The second pass takes an hour. Read the paper end to end, pay attention to figures and tables, mark passages you do not understand. After the second pass you should be able to summarise the main thrust of the paper and its supporting evidence to somebody else.

The third pass takes several hours and is for papers you intend to implement or build on. Reconstruct the paper as if you were the author. Where would you have made different choices? What did the authors leave unsaid? At the end of the third pass you should be able to identify the paper's strengths and weaknesses and notice the assumptions the authors made implicitly.

For a working compiler engineer, most papers stop at the first pass. A handful per year merit the second; one or two a year the third.

### Finding the implementation

Modern compiler papers usually come with code. The artifact-evaluation tracks at PLDI, POPL, OOPSLA and CGO publish reproducibility badges, and the artifacts themselves often live on GitHub or Zenodo. The conference's papers track lists each accepted paper with a separate "Artifact Available" badge; the badge links to the repository.

Outside the artifact track, search GitHub for the paper title or the authors' names. Production compiler patches often cite the paper number directly in the commit message; `git log --grep="paper title"` against LLVM, rustc, or GHC frequently finds the implementation. The Cliff Click sea-of-nodes paper, the Cytron SSA paper, the Chaitin register-allocation paper all have multiple implementations findable this way.

When the artifact does not run as advertised (a frequent outcome), the paper itself is usually still readable. The skill of reading the algorithm and reimplementing it from scratch is what most compiler-engineering work demands.

## Open problems in compiler research circa 2026

Five or six themes dominate the current research landscape. Reading work in any of them is a credible specialisation.

### AI-driven compiler optimisation

Meta released the LLM Compiler in 2024, a model trained on 546 billion tokens of LLVM IR and assembly, achieving 77% of the optimisation benefit of full autotuning search. Compiler-R1 and Reasoning Compiler, both from NeurIPS 2025, push reinforcement-learning agents into the pass-selection problem. The open question is whether LLM-driven optimisation can be made *correct enough* to ship in production toolchains; current systems generate incorrect code on large inputs frequently enough that human review or formal verification is required. The cross-pollination with verified-compiler research is active.

### Verified runtime systems

CompCert verifies the compiler. The runtime it links against is conventional C. Recent work pushes verification into the runtime: verified GC (CertiKOS line, the Iris-based work), verified concurrency primitives, verified memory allocators. The motivation is that an unverified runtime undermines the verified compiler's guarantees. CompCert 3.17, released February 2026, integrates with the Rocq proof assistant; Cornell researchers used clightgen to formally verify a modular-inverse implementation in libsecp256k1, the cryptographic library underpinning Bitcoin.

### Heterogeneous compute

CPUs, GPUs, TPUs, NPUs, FPGAs, and accelerators all coexist in modern systems. The compiler problem is taking a single high-level program and lowering it to multiple targets, partitioning work across them, and managing the data movement. MLIR is the platform of record; the open problems are how to express partitioning policies, how to schedule across heterogeneous memory hierarchies, and how to handle dynamic shape information without hand-tuning per target. ONNX Runtime, Apache TVM, IREE, and Modular MAX all sit in this space.

### Energy-efficient codegen

The IEEE study "Program energy efficiency: the impact of language, compiler, and implementation choices" remains the canonical empirical reference. Distributed Green Compiler approaches save 30 to 40% of clock cycles via scheduling adjustments; EnerJ-style approximate computing can save up to 90% on permissive workloads. The open question is how to expose energy as a first-class optimisation objective alongside speed and code size. Most production compilers still treat it as a side-effect of speed optimisation.

### Post-quantum cryptography compilation

NIST standardised Kyber, Dilithium, and SPHINCS+ between 2022 and 2024; deployment is now under way. The compiler problem is generating constant-time code for the new algorithms. The KyberSlash attack of late 2023 and the Clangover attack of 2024 both showed that compiler optimisations break constant-time guarantees written in source. liboqs (the Open Quantum Safe project) is the open-source reference implementation; production deployment requires careful coordination between the cryptographic implementation and the compiler. Active research targets compile-time verification that constant-time properties survive optimisation.

### Formally-verified ABIs

The C ABI is specified informally per platform. Mismatches cause real bugs (the recent zlib 1.3 ABI break, the historical libstdc++ ABI churn). Recent work formalises ABIs at the level of register usage, alignment, exception unwinding, and TLS access. The CompCert qualification for avionics included a partial ABI formalisation. The open problem is unifying these per-vendor formalisations into a verified contract that linkers and dynamic loaders honour.

### Persistent-memory codegen

Intel Optane shipped, then was discontinued; the persistent-memory programming model survives in CXL-attached storage and battery-backed DRAM. The compiler problem is reasoning about durability boundaries: which writes have committed to persistent storage, which have not, where to insert flush and fence instructions. PMDK and the C++ persistent memory programming model are the production targets.

## War stories from production transitions

A handful of historical cases hold most of the lessons compiler engineers need. The patterns repeat.

### Python 2 to 3 (2008 to 2020, twelve years)

The transition was announced with Python 3.0 in 2008 and effectively completed when Python 2.7 lost upstream support in January 2020. Twelve years from announcement to completion. The official rollout assumed the community would migrate quickly given automated tooling (`2to3`); the reality involved years of dual-version compatibility shims (`six`, `__future__` imports), a long period of community uncertainty over whether Python 3 was the future, and large industrial codebases (Dropbox, Instagram) carrying the migration cost late into the 2010s. Guido van Rossum's own 2018 retrospective acknowledged that Dropbox's migration was still under way a decade after Python 3.0 shipped. Lesson: a migration that breaks every working program at the language-syntax level cannot be hurried by tooling alone. The community must be convinced *and* supported with libraries that work on both versions long enough for the dependency graph to migrate.

### Go's compatibility promise (2012 to ongoing)

Go 1, released in March 2012, included an explicit compatibility promise: programs that compile against the Go 1 specification will continue to compile and run unchanged. Twelve years later the promise has held. The 2023 GODEBUG mechanism (Go 1.21) extends this further: subtle behavioural changes that the Go 1 promise permits are gated behind GODEBUG settings that programs can opt out of, with each setting maintained for at least two years and four releases. The result is that Go upgrades are routinely *boring*, which the team treats as the highest design virtue. Lesson: backward compatibility is not free; it requires a process for handling the genuine breaking changes that arise (security fixes, specification clarifications) without abandoning the promise. GODEBUG is the engineering mechanism that makes the philosophy work.

### Rust 2018 edition (2018 onwards, ongoing)

Rust introduced the *edition* mechanism in 2018 to allow non-source-compatible language changes (new keywords, syntax shifts) without forking the ecosystem. Each crate declares its edition; editions interoperate at the compiled-library level. Migration is via `cargo fix --edition`, which mechanically rewrites code where it can. The 2018 edition migration shipped largely successfully, but the postmortems documented real friction: doctests are not auto-migrated, idiom lints sometimes give wrong suggestions, macros can generate code that does not work in the new edition, and corner cases requiring manual edits were common. The Rust team explicitly acknowledged that organisational project-management around editions needed improvement. Subsequent editions (2021, 2024) refined the process. Lesson: the edition mechanism is genuine progress over the Python 2/3 model, but only if migration tooling is honest about its limitations and the project commits to keeping editions interoperable indefinitely. Rust did both.

### Swift 5 ABI stability (2019)

Swift 5 declared ABI stability on Apple platforms in March 2019. Before Swift 5, every app embedded the Swift standard library inside its bundle, because the runtime made no compatibility guarantee across compiler versions. After Swift 5, the runtime ships in the OS, app bundles shrank, and binary frameworks built with Swift 5.1 work in any project using Swift 5.1 or later (with the build settings configured for distribution). Module stability followed in Swift 5.1. Lesson: ABI stability is a one-way commitment with a long preparation phase. Apple spent years documenting the runtime layout, polishing the standard library, and writing the ABI Stability Manifesto before flipping the switch. The reward is permanent; the preparation is multi-year. Compilers that do not commit to ABI stability (rustc most prominently) cite the Swift example as the cost of doing it right.

### C++ modules (2019 to ongoing)

C++20 standardised modules in 2019. Six years later, adoption is still partial: a 2024 community survey found only 29% of respondents allowing modules in their projects. Tooling support across GCC, Clang, and MSVC remains inconsistent; build-system integration with CMake, Bazel, and Meson is fragmented; third-party libraries lag because users lag because libraries lag. By 2026 the major compilers can build module-using code, but the chicken-and-egg problem persists. Lesson: language-level features that change the build model (rather than just the source language) face an ecosystem-coordination problem that is qualitatively different from migrating syntax. The C++ committee can standardise; only build-system maintainers can deploy.

### GCC's switch to C++ (2008 to 2012)

GCC was implemented in C until version 4.8. The transition to C++ as an implementation language was announced in 2008, completed in 2012, and has been the status quo since. The move was contentious; long-time GCC contributors objected to the dependency on a more complex language. The benefits proved modest in performance (1 to 2% compile-time reduction on hash-table conversions) but significant in maintainability and contributor growth. Lesson: a compiler's own implementation language is a long-running political question, not just a technical one. The conversation took four years; the retroactive judgement is broadly that the move was correct, but the process taught GCC's leadership how to coordinate divisive changes through a community of long-tenured contributors.

The recurring pattern across all these stories: every successful transition combined three ingredients. A clear technical mechanism for migration (cargo fix, GODEBUG, ABI stability manifesto). A long timeline measured in years, not releases. And a credible commitment from project leadership to sustain the migration through to completion. Transitions that lacked any one of these (the early Python 3 rollout, C++ modules so far) accumulated cost without paying off.

## Closing

The skill of reading a compiler is a smaller skill than the skill of writing one from scratch. This book has tried to teach both, by writing one from scratch and explaining each piece in plain enough language that the same vocabulary works on a much larger codebase.

The ten chapters of LLVM, GCC, rustc, Go, GHC, OCaml, Cranelift, Zig, Swift, and V8 are the bridge. Cross any one of them when you are ready.
