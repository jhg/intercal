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

The two chapters that follow this one go much deeper into specific compiler techniques:

- [techniques-we-use.md](techniques-we-use.md): every advanced technique present in this compiler, explained in production-compiler vocabulary. If you understand our `eval_const`, you understand a slice of LLVM's `InstCombine`. If you understand our `compute_flag_checks`, you understand a slice of GCC's tree-level DCE. The chapter names the correspondences.
- [techniques-we-lack.md](techniques-we-lack.md): every advanced technique missing from this compiler, organised by phase. SSA construction, register allocation, garbage collection, JIT speculation, polyhedral optimisation. The chapter is a roadmap of the design space, with pointers into each production compiler that exemplifies a technique.

Treat the three chapters (this one plus those two) as the bridge in three layers: this one for the conceptual map, "we use" for "what you already know in production-compiler vocabulary", "we lack" for "what to read next".

## Closing

The skill of reading a compiler is a smaller skill than the skill of writing one from scratch. This book has tried to teach both, by writing one from scratch and explaining each piece in plain enough language that the same vocabulary works on a much larger codebase.

The ten chapters of LLVM, GCC, rustc, Go, GHC, OCaml, Cranelift, Zig, Swift, and V8 are the bridge. Cross any one of them when you are ready.
