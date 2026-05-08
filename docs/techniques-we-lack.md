# Advanced techniques we lack

This chapter is the catalogue of major compiler techniques our INTERCAL compiler does not implement. Each section names a technique, explains what it is, where it lives in production compilers, why we do not have it, and what it would take to add it. The chapter is organised by phase: front-end, IR design, middle-end optimisations, back-end, runtime, execution model, tooling.

The motivation for the chapter is the symmetric one to [techniques-we-use.md](techniques-we-use.md). Knowing what you do not have is half the battle when planning future work. Knowing what you cannot have without committing to a serious design change is the other half.

A reader who wants every technique with full theoretical depth should read Cooper and Torczon's *Engineering a Compiler* (3rd edition 2023) cover to cover. This chapter is a faster orientation map. Each section points at a production compiler that exemplifies the technique, plus a textbook reference for further study.

## Conventions

For each technique, the structure is:

- **What it is**: a one-paragraph definition.
- **Production examples**: which Part VII compilers use it and where in their codebase.
- **Why we do not have it**: the design or scope reason.
- **What it would take**: a rough estimate of effort and prerequisites.
- **Where to read more**: pointer to the textbook chapter or paper.

Some techniques are categorical mismatches with INTERCAL (lazy evaluation runtime; we are strict). Others are scope decisions (auto-vectorisation; pointless without numerical loops). Others are deferred (real CFG construction; the Phase A roadmap in [middle-end-and-optimisation.md](middle-end-and-optimisation.md)).

# Front-end techniques

## Macro expansion (hygienic macros)

What it is: source-level transformation that lets users define their own syntactic forms. Hygienic macros handle scope correctly, so a macro-introduced variable cannot accidentally shadow a user variable.

Production examples:
- rustc has `macro_rules!` (declarative) and proc-macros (procedural, in user crates). Both are hygienic. Implementation in `compiler/rustc_expand/`.
- GHC has Template Haskell, a procedural macro system that runs Haskell at compile time.
- Clang has C/C++ preprocessor (non-hygienic) plus templates (hygienic for some purposes).
- Lisp's hygienic macros (`syntax-rules`, `syntax-case`) are the original form.

Why we do not have it: INTERCAL has no macro construct. The language as specified does not extend syntactically; user programs are sequences of statements with the documented operators.

What it would take: a non-standard extension to the language plus a separate phase before lexing. Not happening; would break compatibility with the spec.

Where to read more: "Hygienic Macros for ALGOL 60" (Kohlbecker et al. 1986) for the original; the rustc-dev-guide chapter on macro expansion; *Beautiful Racket* (Butterick) for a modern Scheme-style treatment.

## Type inference (Hindley-Milner and beyond)

What it is: deducing the types of program variables and expressions from how they are used, without requiring annotations. Hindley-Milner (1969-1978) is the canonical algorithm: walk the AST, generate constraints, solve them by unification.

Production examples:
- OCaml is the canonical implementation. `typing/typecore.ml` plus the level-based generalisation in `typing/btype.ml`. ~4,000 lines of dense but readable OCaml.
- GHC implements OutsideIn(X), a constraint-based generalisation that handles type families and GADTs. `compiler/GHC/Tc/`.
- rustc has a bidirectional inferencer that mixes HM with explicit annotations, plus trait dispatch. `compiler/rustc_hir_typeck/`.
- Swift has a constraint-based solver with backtracking, optimised for DSL-shaped expressions. `lib/Sema/`.

Why we do not have it: INTERCAL is monomorphically typed. Each variable's type is fixed by its prefix character (`.` for spot, `:` for two-spot, `,` for tail array, `;` for hybrid array). There is nothing to infer.

What it would take: a richer type system on top of INTERCAL. Possible but pointless given the language as designed.

Where to read more: "A Theory of Type Polymorphism in Programming" (Milner 1978); "Principal Type-Schemes for Functional Programs" (Damas and Milner 1982); Pierce's *Types and Programming Languages* for the full theoretical treatment; OCaml's source for a production reference.

## Trait/typeclass resolution

What it is: matching a type-class constraint (e.g., `T: Eq`) to a specific implementation, often involving search across multiple modules and complex coherence rules.

Production examples:
- GHC turns `class Eq a where (==) :: a -> a -> Bool` into a record type, each `instance Eq T` into a value of that record (a "dictionary"), and each use of a constraint into explicit dictionary passing. After Core, type classes are gone.
- rustc's trait solver (`rustc_trait_selection`, gradually being replaced by a new solver). Coherence rules guarantee at most one impl per (Type, Trait) pair.
- Swift's witness tables play a similar role for protocols.
- Scala, Haskell, Rust, Swift all have variants of this idea.

Why we do not have it: INTERCAL has no type classes, no protocols, no traits. Operations on values are determined by the operator, not by the type.

What it would take: an extension that bears no resemblance to standard INTERCAL. Not feasible.

Where to read more: "How to make ad-hoc polymorphism less ad hoc" (Wadler and Blott 1989); the Haskell 2010 report; the rustc-dev-guide chapter on traits.

## Borrow checking and ownership

What it is: a static analysis that rejects programs containing memory-safety bugs (use after free, double free, data races) by tracking the lifetime of every reference.

Production examples:
- rustc's borrow checker on MIR. NLL (Non-Lexical Lifetimes) since 2018; Polonius is the next iteration. Implementation in `compiler/rustc_borrowck/`, around 50,000 lines including diagnostics.
- gccrs has integrated Polonius as its production borrow checker since GCC 15.

Why we do not have it: INTERCAL has no references, no pointers, no allocation lifetime to track. Variables are 16- or 32-bit integers; arrays are dimensioned and resized but ownership is implicit. There is nothing to check.

What it would take: a different language. Borrow checking is the central feature of Rust; it does not retrofit onto an unrelated semantics.

Where to read more: the rustc-dev-guide chapter on borrow checking; "Stacked Borrows" (Jung et al. 2019) for the formal semantics that ground the checker; "Polonius: A Datalog-based borrow checker" by Niko Matsakis (blog series).

## Effect systems and capability tracking

What it is: type-system extensions that classify functions by what *effects* they perform (I/O, exceptions, state mutation) and let callers reason about which effects propagate.

Production examples:
- OCaml 5.0 added effect handlers (algebraic effects), partially as a research direction and partially as the basis for the multicore runtime. `runtime/effects.c`.
- Rust's `Send` and `Sync` traits play a capability role for thread-safety.
- Java's checked exceptions are a coarse effect system.
- Research languages (Eff, Frank, Koka) have full effect systems.

Why we do not have it: INTERCAL has no effects to track in the technical sense. Side effects (I/O via Label 666) are explicit at the call site; there is nothing to abstract over.

What it would take: a different language plus a different runtime.

Where to read more: "Algebraic Effects and Effect Handlers" (Plotkin and Pretnar 2009); the OCaml 5.0 release notes; Daan Leijen's papers on Koka.

## Dependent types

What it is: a type system where types can depend on values, making `Vec<n>` (a vector of length `n`, where `n` is a value) a first-class type.

Production examples:
- Idris, Agda, Lean, Coq are the major full-dependent-typing languages.
- Rust's const generics are a restricted form: types parameterised by const values.
- Zig's comptime allows types-as-values, achieving similar expressiveness without formal dependent typing.

Why we do not have it: INTERCAL's type system is a four-element discrete set. Dependent typing is irrelevant.

What it would take: a research project. Years of work for a different language.

Where to read more: Pierce's *Advanced Topics in Types and Programming Languages*; the Idris documentation; the Lean language manual.

# IR design techniques

## Three-address IR (real, feeding codegen)

What it is: an intermediate representation where every operation has at most three operands (typically two inputs and one output). Replaces tree-shaped expressions with a linear sequence of simple operations. Standard in compilers since the 1970s.

Production examples:
- GCC's GIMPLE is three-address-form. `gcc/gimple.cc` and surrounding files.
- LLVM IR is three-address-form (with named SSA values).
- rustc's MIR is three-address-form.
- Cranelift's CLIF is three-address-form.

Why we do not have it: our codegen walks the parse tree directly. The expression `'.1 ~ #65535'` is recursively codegen'd in one pass; we never materialise an intermediate three-address form.

What it would take: introduce a three-address IR between parsing and codegen. Phase A in [middle-end-and-optimisation.md](middle-end-and-optimisation.md). Roughly 500 lines of zsh to introduce the data structure and rewrite codegen to consume it.

Our `--emit-3addr` flag prints a three-address-shaped *view* of the parsed program but does not feed codegen. It is inspection only.

Where to read more: Cooper and Torczon's chapter on intermediate representations; Aho-Sethi-Ullman ("Dragon book") on three-address code; the GIMPLE chapter in the gccint manual.

## SSA via Cytron's algorithm

What it is: Static Single Assignment form, where every variable is assigned exactly once. At control-flow joins, "phi" instructions merge values from incoming edges. SSA simplifies most analyses because every use names a unique definition. Cytron, Ferrante, Rosen, Wegman, Zadeck (1991) gave the canonical efficient algorithm.

The algorithm has two parts:
1. Compute the dominance frontier of every basic block.
2. Place phi-functions at dominance frontiers, then rename variables.

Production examples:
- LLVM IR is in SSA form. The transition from "alloca + load/store" to SSA is the `mem2reg` pass, which uses the Cytron algorithm.
- GCC's GIMPLE has a SSA form (Tree-SSA) that uses iterated dominance frontiers.
- rustc's MIR is technically not SSA in name, but it is in practice (each MIR local has a single point of definition by construction).
- Go's SSA backend uses a Cytron variant with adaptations for the rules-based optimiser.

Why we do not have it: we have no IR. SSA is a property of an IR. Without one, SSA is inapplicable.

What it would take: prerequisites are a CFG (Phase A) and the three-address IR. Then implement Cytron's algorithm: dominance computation (Lengauer-Tarjan), iterated dominance frontiers, phi placement, variable renaming. Total maybe 400 lines on top of the prerequisites.

Where to read more: "Efficiently Computing Static Single Assignment Form and the Control Dependence Graph" (Cytron et al. 1991), the canonical paper; Cooper and Torczon's chapter on SSA construction; LLVM's `mem2reg` source.

## SSA via Braun's algorithm

What it is: an alternative SSA construction algorithm (Braun et al. 2013) that builds SSA on the fly during IR construction, without computing dominance frontiers upfront. The frontend feeds basic blocks one at a time; SSA structure emerges as a side effect.

Production examples:
- Cranelift's `FunctionBuilder` API uses Braun's algorithm via the `cranelift_frontend` crate.
- Some smaller backends and JITs also use it because the per-block API is simpler than Cytron's whole-program one.

Why we do not have it: we have no IR.

What it would take: alternative path to SSA, mechanically simpler than Cytron for incremental IR builders. Same prerequisites.

Where to read more: "Simple and Efficient Construction of Static Single Assignment Form" (Braun et al., CC 2013); the Cranelift source for a production reference.

## Sea of Nodes

What it is: an IR where data and control flow are unified into a single graph. Many nodes "float" without a fixed position in any basic block; their position is determined later by a scheduler. Cliff Click's 1995 thesis.

Production examples:
- V8's TurboFan uses sea of nodes. `src/compiler/`.
- HotSpot's C2 (Java's top-tier JIT) uses sea of nodes; same lineage from Click.
- GraalVM uses it.
- LLVM IR is *not* sea of nodes; it is conventional SSA with explicit basic blocks.

Why we do not have it: even if we wanted SSA, a sea-of-nodes IR is significantly more complex than block-based SSA. It is not the natural choice for a small AOT compiler.

What it would take: substantial. Sea-of-nodes IRs require a scheduler that places floating nodes back into specific blocks before codegen, plus careful management of the control-flow side of the graph.

Where to read more: "Combining Analyses, Combining Optimizations" (Click 1995, PhD thesis); "A Simple Graph-Based Intermediate Representation" (Click and Paleczny 1995); the V8 source for production-grade.

## CPS and ANF

What it is: alternative IR styles for functional languages. Continuation-Passing Style (CPS) makes control flow explicit as continuation arguments. A-Normal Form (ANF) is a relative; every intermediate value gets a name.

Production examples:
- GHC's STG is conceptually a constrained ANF.
- The MLton compiler uses CPS internally.
- Most Scheme compilers (Larceny, Chez) use CPS.
- Various research compilers in the ML and Scheme families.

Why we do not have it: not relevant for an imperative language with explicit gotos and jumps. Our control flow is INTERCAL's control flow.

Where to read more: "Compiling with Continuations" (Andrew Appel 1992); "The Essence of Compiling with Continuations" (Flanagan et al. 1993); the MLton compiler documentation.

## Block parameters vs phi nodes

What it is: a design choice for representing control-flow joins in SSA. Phi nodes attach merge logic to the receiving block. Block parameters express the same as parameters of the block, like function parameters. Mathematically isomorphic; engineering-wise quite different.

Production examples:
- LLVM, GCC, rustc, Go use phi nodes (the older choice).
- Cranelift uses block parameters.
- MLIR uses block parameters.
- Webkit's B3 uses block parameters.

Why we do not have it: no IR.

The lesson if we ever build one: block parameters are easier to maintain through transformations because they avoid "phi must come first" rules and special-cased phi-input updates. The newer designs prefer them.

Where to read more: the MLIR Language Reference for the block-parameter formalisation; Cranelift's docs for the engineering rationale.

## Multi-level IRs (the IR-stacking idea)

What it is: instead of a single IR between front-end and back-end, a stack of IRs at progressively lower levels of abstraction. Each lowering step preserves enough information for the work that happens at that level.

Production examples:
- GCC: GENERIC → GIMPLE → RTL.
- rustc: HIR → THIR → MIR → LLVM IR (four layers).
- GHC: HsSyn → Core → STG → Cmm (four layers, each with formal semantics).
- Swift: AST → SIL (raw) → SIL (canonical) → SIL (optimised) → LLVM IR.
- MLIR generalises the idea: arbitrary "dialects" coexist in the same module, each lowered to the next.

Why we do not have it: we have one parse-tree-shaped representation. No IR stack.

What it would take: full re-architecture. Each new IR is hundreds of lines plus the lowering pass between it and its predecessor. Worthwhile only at scale.

Where to read more: Cooper and Torczon on intermediate representations; the rustc-dev-guide on HIR/THIR/MIR; the GHC Commentary on Core/STG/Cmm; the MLIR documentation on dialects.

# Middle-end optimisations

## Sparse Conditional Constant Propagation (SCCP)

What it is: a dataflow algorithm that combines constant propagation with reachability analysis. When a comparison evaluates to a known constant, the unreachable branch is propagated as dead, which lets more values be marked constant. Runs to fixpoint. Wegman and Zadeck (1991).

Production examples:
- LLVM has SCCP and IPSCCP (interprocedural). `llvm/lib/Transforms/Scalar/SCCP.cpp` and `llvm/lib/Transforms/IPO/SCCP.cpp`.
- GCC has tree-level constant propagation in `gcc/tree-ssa-ccp.cc`.
- rustc has constant propagation passes on MIR.
- Most production optimisers have a variant.

Why we do not have it: SCCP requires SSA form, control-flow graph, and dataflow infrastructure. We have a leaf-level constant folder (`eval_const`) which is the simplest case but does not propagate across statement boundaries.

What it would take: prerequisites are CFG and SSA. Then SCCP is roughly 200 lines of dataflow on top.

Where to read more: "Constant Propagation with Conditional Branches" (Wegman and Zadeck 1991); LLVM's `SCCP.cpp` source; Cooper and Torczon on dataflow.

## Common Subexpression Elimination (CSE)

What it is: detecting that the same expression is computed twice on a path through the program, replacing the second computation with the first one's result.

Production examples:
- LLVM's `EarlyCSE` (`llvm/lib/Transforms/Scalar/EarlyCSE.cpp`) and `GVN` (a more powerful version, see below).
- GCC has CSE on RTL (`gcc/cse.cc`).
- Go has CSE as an SSA pass (`cmd/compile/internal/ssa/cse.go`).
- Most production compilers have CSE.

Why we do not have it: we do not detect repeated expressions. INTERCAL programs are short enough that the wins would be small.

What it would take: SSA form, then a hash-based scan over expressions to find duplicates. Small.

Where to read more: Cooper and Torczon's chapter on local optimisation; Muchnick's *Advanced Compiler Design and Implementation* for the depth.

## Global Value Numbering (GVN)

What it is: a more powerful CSE that recognises *equivalent* expressions even if textually different. Assigns each value a "number"; two computations producing equal values get the same number; redundant ones can be removed.

Production examples:
- LLVM's `GVN` pass (`llvm/lib/Transforms/Scalar/GVN.cpp`). One of the larger and more sophisticated optimisers.
- GCC has tree-level GVN (`gcc/tree-ssa-pre.cc` for partial redundancy elimination, which generalises GVN).
- Cranelift's egraph-based optimiser is a modern relative.

Why we do not have it: not enough numerical computation in INTERCAL programs to justify the complexity.

Where to read more: "Detecting Equality of Variables in Programs" (Alpern, Wegman, Zadeck 1988) for value numbering; "Global Value Numbers and Redundant Computations" (Rosen, Wegman, Zadeck 1988); LLVM's `GVN` source.

## Loop-Invariant Code Motion (LICM)

What it is: moving computations whose result does not change across loop iterations out of the loop body. The classical example: lifting a `2 * x` computation out of a loop where `x` does not change.

Production examples:
- LLVM's `LICM` pass (`llvm/lib/Transforms/Scalar/LICM.cpp`).
- GCC's tree-level LICM (`gcc/tree-ssa-loop-im.cc`).
- All production optimisers have it.

Why we do not have it: INTERCAL has no formal loop construct. Loops are emergent from `NEXT`/`COME FROM` patterns. Detecting them is non-trivial.

What it would take: loop detection (a separate analysis on the CFG) plus the LICM transformation. Loop detection alone is significant; the transformation is small once you have it.

Where to read more: Cooper and Torczon's chapter on loop optimisation; Muchnick's chapters on natural-loop detection and LICM.

## Induction Variable optimisation

What it is: recognising loop-induction variables (variables that change by a fixed amount per iteration) and simplifying expressions involving them. Includes strength reduction (replacing multiplications with additions) and induction variable elimination.

Production examples:
- LLVM's `IndVars` pass (`llvm/lib/Transforms/Scalar/IndVarSimplify.cpp`) on top of `ScalarEvolution`.
- GCC's tree-level `tree-ssa-loop-ivopts.cc`.
- A classic optimisation; every numerically-oriented compiler does it.

Why we do not have it: same reason as LICM. INTERCAL loops are emergent and rare.

Where to read more: Allen and Cocke's classical papers on loop optimisation; Cooper and Torczon's chapter; LLVM's `IndVars` and `ScalarEvolution`.

## Loop unrolling

What it is: replacing a loop body with several copies in sequence, reducing branch overhead and enabling further optimisation across the unrolled iterations. The unroll factor is typically chosen by heuristic.

Production examples:
- LLVM's `LoopUnroll` pass.
- GCC's `tree-ssa-loop-unswitch.cc` plus the unroll-related machinery.
- Go does unrolling at SSA level.
- Compiler intrinsics (`#pragma unroll`) let the user override the heuristic.

Why we do not have it: same as LICM.

Where to read more: Cooper and Torczon; "Optimal Loop Unrolling" by Davidson and Jinturkar (1995); LLVM's `LoopUnroll` source.

## Loop fusion, fission, interchange

What they are: structural loop transformations. Fusion combines adjacent loops into one. Fission splits a loop into multiple. Interchange swaps nested loop order to improve memory access patterns. Each enables specific further optimisations and is sensitive to memory hierarchy.

Production examples:
- LLVM's `LoopFusion`, `LoopFission` (less mature), `LoopInterchange`.
- GCC's tree-level loop transformations.
- Polly (LLVM's polyhedral optimiser) does these comprehensively.
- HPC compilers (`icc`, `xlc`) do them aggressively.

Why we do not have it: INTERCAL has neither matrix algorithms nor numerical loops where these matter.

Where to read more: *Optimizing Compilers for Modern Architectures* (Allen and Kennedy 2001), the canonical reference for loop transformations; Polly's documentation.

## Auto-vectorisation (loop and SLP)

What it is: automatically converting scalar operations to vector (SIMD) operations. Two flavours: loop vectorisation (run multiple loop iterations in parallel using SIMD lanes) and SLP (Superword-Level Parallelism, finding parallelism across straight-line code).

Production examples:
- LLVM's `LoopVectorize` and `SLPVectorizer` passes.
- GCC's auto-vectoriser.
- Polly for polyhedral-driven vectorisation.

Why we do not have it: INTERCAL has no SIMD-friendly operations. `mingle` and `select` operate on bit patterns that have nothing to do with SIMD lanes.

Where to read more: "Vectorization in OpenMP" papers; "Loop Vectorization in LLVM" by Hal Finkel; SLP literature beginning with "Exploiting Superword Level Parallelism with Multimedia Instruction Sets" (Larsen and Amarasinghe 2000).

## Inlining (with heuristics)

What it is: replacing a function call with the function body at the call site. The heuristic part is *when* to inline: small functions are obvious wins, but inlining everything would explode binary size and hurt instruction-cache performance.

Production examples:
- LLVM's `Inliner` pass with cost analysis in `InlineCost.cpp`.
- GCC has inlining heuristics in `gcc/ipa-inline.cc`.
- rustc's `rustc_mir_transform/inline.rs`.
- Go's unified inliner with budget-based decisions and PGO bias.
- GHC inlines aggressively, including across module boundaries.
- Swift's optimiser inlines with `@inlinable` annotations.

Why we do not have it: INTERCAL has no functions. `NEXT` to a label is a goto-with-stack, not a function call. Inlining a labelled section means inlining a whole code region that includes the corresponding `RESUME`, with care for abstention. Possible but tricky.

What it would take: detection of "call sites" (`NEXT` followed eventually by `RESUME #1` patterns), then careful inlining preserving the abstain-and-COME-FROM semantics. Hundreds of lines minimum.

Where to read more: "Choosing the Best Heuristic for a NLPP" research; LLVM's `Inliner` source; the rustc-dev-guide on inlining decisions.

## Function specialisation and devirtualisation

What they are: function specialisation generates a tailored version of a function for specific argument values or types. Devirtualisation replaces an indirect (virtual) call with a direct one when the target is known.

Production examples:
- Swift's generic specialisation at SIL level. `lib/SILOptimizer/Transforms/GenericSpecializer.cpp`.
- rustc's monomorphisation specialises every generic call site at MIR level.
- LLVM has specialisation infrastructure in `lib/Transforms/IPO/FunctionSpecialization.cpp`.
- Devirtualisation is a separate pass in most compilers.

Why we do not have it: no generics, no virtual calls.

Where to read more: Swift's SIL documentation on specialisation; the rustc-dev-guide chapter on monomorphisation.

## Escape analysis

What it is: a static analysis to determine whether a value's lifetime can be bounded by its current scope (stack-allocatable) or it might "escape" to outlive the current frame (heap-allocatable). Used by GC'd languages to elide heap allocation when safe.

Production examples:
- Go's `cmd/compile/internal/escape/`. The decision drives stack vs heap allocation.
- HotSpot's escape analysis is one of its sophisticated optimisations.
- GCC has escape-analysis infrastructure for some C++ patterns.
- GraalVM's escape analysis is part of its partial-evaluation framework.

Why we do not have it: INTERCAL has no GC, no closures, no heap-allocated data structures (arrays go through `mmap` directly, not through a heap). There is nothing to escape.

Where to read more: "Escape Analysis: Correctness Proof, Implementation and Experimental Results" (Choi et al. 1999); Go's escape analysis source; HotSpot's escape analyser.

## Alias analysis

What it is: determining whether two memory references could possibly refer to the same location. Critical for almost every optimisation that involves loads and stores: if two pointers might alias, you cannot reorder a load past a store between them.

Production examples:
- LLVM has multiple alias analyses: `BasicAA`, `TBAA` (Type-Based AA), `ScopedNoAliasAA`, `CFLAA`. Composed into a sophisticated infrastructure.
- GCC has tree-ssa-alias.cc.
- Cranelift has simpler heuristics.

Why we do not have it: INTERCAL has no general aliasing. Variables and array elements are addressed by index, not by pointer.

Where to read more: Hind's "Pointer Analysis: Haven't We Solved This Problem Yet?" (PASTE 2001); LLVM's alias-analysis documentation.

## Polyhedral optimisation

What it is: a mathematical framework for representing and transforming nested loops over multidimensional arrays. Loop transformations become operations on integer polyhedra. Enables sophisticated fusion, interchange, tiling, and parallelisation.

Production examples:
- LLVM's Polly (`polly/`).
- GCC's Graphite (`gcc/graphite.cc`).
- HPC-targeted research compilers (Pluto, PoCC).
- Used in scientific computing toolchains.

Why we do not have it: INTERCAL has no nested loops over multi-dimensional arrays. Polyhedral optimisation is irrelevant.

Where to read more: "The Polyhedron Model" (chapter in Cooper and Torczon, or in Allen and Kennedy); the Polly documentation; "Pluto: A Practical and Fully Automatic Polyhedral Program Optimization System".

## Profile-Guided Optimisation (PGO)

What it is: collecting runtime profile data (which branches taken, which functions hot) on a representative workload, then feeding that data into a subsequent compilation to bias optimisation decisions.

Production examples:
- LLVM has PGO via `-fprofile-instr-generate` and `-fprofile-instr-use`.
- GCC has it via `-fprofile-generate` and `-fprofile-use`.
- Go has PGO since 1.21.
- Swift has it.
- Most production toolchains support it.

Why we do not have it: INTERCAL programs are not performance-critical at scale. PGO is an answer to "this program runs for hours; help me make it faster". We do not have programs of that shape.

What it would take: instrumentation pass (count branches/calls), runtime support to dump counters at exit, second compilation pass that reads the dump and biases inlining/branch-layout decisions. Significant infrastructure.

Where to read more: "Profile-Guided Code Positioning" (Pettis and Hansen 1990) for the original; LLVM's PGO documentation; Go's PGO documentation.

## Link-Time Optimisation (LTO)

What it is: optimisations that span translation units. Normally each `.c` file is compiled in isolation; LTO defers final code generation to link time, when the whole program is visible.

Production examples:
- LLVM's `ThinLTO` (incremental, parallel) and `FullLTO` (slower, more thorough).
- GCC's `lto1`.
- Swift's Cross-Module Optimisation (CMO).
- Standard in production builds of large C++ projects.

Why we do not have it: INTERCAL programs are usually one source file. The closest analog (separate compilation of `syslib.i` and the user program) is what `INTERCAL_SYSLIB=cache` does, but only for the syslib, and without cross-unit optimisation.

Where to read more: "ThinLTO: Scalable and Incremental LTO" (Johnson et al. 2017); the GCC LTO documentation; Swift's CMO documentation.

## BOLT-style post-link optimisation

What it is: optimisations applied to already-compiled binaries, using profile data to reorder basic blocks for better branch prediction and instruction-cache locality.

Production examples:
- LLVM's BOLT (`bolt/`). Reorders basic blocks in already-compiled binaries based on profile.
- Propeller (an LLVM-related project) takes a similar approach with finer-grained profile data.
- AutoFDO is the profile collection side.

Why we do not have it: INTERCAL programs are not large enough that block ordering matters. BOLT is most relevant for binaries of millions of basic blocks.

Where to read more: the BOLT documentation; "BOLT: A Practical Binary Optimizer for Data Centers" (Panchenko et al. 2018); Facebook/Meta's blog posts on production BOLT use.

# Back-end techniques

## Real CFG construction (feeding optimisation)

What it is: building an explicit control-flow graph data structure as a first-class IR, with basic blocks as vertices and branches as edges, that subsequent passes consume.

Production examples: every production compiler in Part VII builds a CFG.

Why we do not have it: our `--emit-cfg` flag computes a CFG view but does not feed codegen with it. Codegen still walks the parse tree.

What it would take: Phase A in [middle-end-and-optimisation.md](middle-end-and-optimisation.md). Replace the parse-tree walk with a CFG walk in codegen. Roughly 500 lines of zsh.

Where to read more: any compiler textbook chapter on CFG construction; LLVM's `lib/IR/BasicBlock.cpp`.

## Liveness analysis (forward/backward dataflow)

What it is: at every program point, the set of variables that are *live*, meaning their current value will be used before being overwritten. Liveness is a backward dataflow analysis.

Production examples:
- LLVM's `LiveVariables` analysis.
- GCC's tree-ssa-live.cc.
- The foundation of register allocation everywhere.

Why we do not have it: we do not allocate registers (we always use stack slots). Without register allocation, liveness is unnecessary.

What it would take: SSA form, then standard backward dataflow. ~100 lines.

Where to read more: Cooper and Torczon's chapter on dataflow; the classical paper "Compilers and Computer Architecture" by Aho.

## Instruction selection (BURS, DAG-based, ISLE, GlobalISel)

What it is: choosing which target instructions to emit for an IR-level operation. The choice is non-trivial because most architectures have many ways to compute the same operation, with different costs.

Production examples:
- LLVM's SelectionDAG (DAG-based, pattern-matched via TableGen).
- LLVM's GlobalISel (pass-based, in transition).
- GCC's `define_insn` and `define_expand` patterns in `.md` files.
- Cranelift's ISLE rules in `.isle` files.
- Go's `.rules` files for arch-specific lowering.

Each compiler has a domain-specific language for describing instruction selection rules. The languages differ; the idea is the same.

Why we do not have it: we hand-write per-statement assembly templates. No instruction-selection logic.

What it would take: an IR (preferably SSA), then a pattern-matcher and a rules table. Significant. Easier in a clean rewrite than as a retrofit.

Where to read more: Cooper and Torczon's chapter on instruction selection; "BURS Instruction Selection" by Pelegri-Llopart and Graham (1988); LLVM's TableGen documentation; the Cranelift ISLE documentation.

## Instruction scheduling

What it is: reordering instructions within a basic block to minimise pipeline stalls. The optimal order depends on per-instruction latency and the target's pipeline structure.

Production examples:
- LLVM's `MachineScheduler`. Per-target scheduling models live in TableGen.
- GCC's machine description specifies pipeline behaviour, used by `gcc/sched-*.cc`.
- Most production backends do scheduling.

Why we do not have it: we emit instructions in the natural order from the codegen walk. Modern out-of-order CPUs handle most of what an instruction scheduler would care about, but the technique is still important on ARM, RISC-V, and embedded targets.

Where to read more: Allen-Cocke; "List Scheduling" papers; LLVM's `MachineScheduler` source.

## Register allocation (graph coloring, linear scan, SSA-based, backtracking, PBQP)

What it is: deciding which IR values live in which physical registers, and inserting spill/reload code when there are not enough registers. Multiple algorithms, each with tradeoffs.

Production examples:

- **Graph coloring (Chaitin 1981, Briggs 1989)**: build an interference graph, colour it with N colours where N is the number of available registers. NP-hard in general, but graph-coloring heuristics work well.
  - GCC's old register allocator used graph coloring.
  - GHC's NCG uses graph coloring.

- **Linear scan (Poletto-Sarkar 1999)**: walk live ranges in start-point order, assign registers greedily, spill when necessary.
  - OCaml's `asmcomp/linscan.ml` (~330 lines).
  - LLVM's `fast` allocator is a variant.

- **SSA-based linear scan**: linear scan that operates on SSA form, with phi/block-parameter handling on edges.
  - regalloc2's underlying machinery (though regalloc2 itself uses backtracking, not pure linear scan).

- **Backtracking (Ion-derived)**: regalloc2's actual algorithm. Live ranges grouped into bundles; bundles assigned with eviction and splitting on conflict.
  - Cranelift's regalloc2.

- **PBQP (Partitioned Boolean Quadratic Programming)**: an OR-style formulation that solves the allocation as an optimisation problem.
  - LLVM's `pbqp` allocator (mostly research).

- **LLVM greedy**: prioritise live ranges by spill cost, assign registers in priority order, split on conflict.
  - LLVM's default allocator in `lib/CodeGen/RegAllocGreedy.cpp`.

- **GCC LRA (Local Register Allocator)**: replaced the older "reload" pass in 2013. Multi-pass: virtual-to-physical assignment, spill code insertion, post-allocation cleanup.
  - GCC's `gcc/lra-constraints.cc` and friends.

Why we do not have it: we use stack slots for everything. `.1`, `.2`, etc. are statically-located memory addresses. No register pressure to manage.

What it would take: SSA form, liveness analysis, then one of the algorithms. Linear scan is the easiest entry point (~400 lines for a reasonable implementation, using OCaml's `linscan.ml` as reference).

Where to read more: Chaitin's "Register Allocation and Spilling via Graph Coloring" (1982); Poletto-Sarkar's "Linear Scan Register Allocation" (1999); Briggs's "Coloring Heuristics for Register Allocation" (1989); Chris Fallin's "Cranelift, Part 4: A New Register Allocator" blog post (2022); LLVM's `RegAllocGreedy.cpp`.

## Tail-call optimisation

What it is: when the last action of a function is a call, reuse the current stack frame for the called function instead of pushing a new one. Critical for recursion-based languages; important enough that some languages mandate it (Scheme).

Production examples:
- GHC mandates tail-call optimisation.
- OCaml mandates it.
- Scala has `@tailrec`.
- Rust has it as a long-discussed feature, no stable implementation.
- LLVM has `tailcc` calling convention; languages using LLVM can opt in.

Why we do not have it: INTERCAL has no functions in the modern sense. `NEXT`+`RESUME` is the closest analog, and the stack is part of the language semantics; we cannot transform it away without changing semantics.

Where to read more: "Programming Language Implementation Techniques for Continuation-Passing Style" (Steele 1978); GHC's discussion of TCO.

## Calling convention specialisation

What it is: choosing per-function how arguments and return values are passed in registers. Default conventions are stable ABIs; specialised ones can be faster but are private to a single program.

Production examples:
- LLVM has many calling conventions (`fastcc`, `coldcc`, `ghccc`, `tailcc`, etc.).
- GHC's `ghccc` is its own calling convention optimised for the lazy-evaluation runtime.
- Production compilers commonly use private conventions for inlined or specialised functions.

Why we do not have it: we follow standard System V AMD64 / AAPCS64 conventions for our runtime calls. INTERCAL's syslib calls go through standard registers.

Where to read more: the System V ABI documentation; LLVM's calling conventions list.

# Runtime techniques

## Garbage collection

What it is: automatic memory management. The runtime tracks which heap objects are reachable from program roots and reclaims unreachable ones.

Algorithms in production:

- **Reference counting**: increment per assignment, decrement per scope-exit. Simple but cannot handle cycles.
  - Swift's ARC (with weak references for cycle breaking).
  - Python's CPython (with cycle collector).

- **Mark-sweep**: walk the heap from roots marking reachable objects, then sweep unmarked ones into a free list. Single-pass.
  - Some old Lisp systems.
  - Often used as the major heap collector in modern systems.

- **Mark-compact**: like mark-sweep but compacts surviving objects to eliminate fragmentation.
  - Ruby's MRI uses mark-sweep with optional compaction.

- **Copying / generational**: divide heap into generations; new objects in the young generation; promote survivors. Young-generation GC is fast (copying); old-generation GC is rare.
  - Java's HotSpot uses several generational collectors (Parallel, G1, Shenandoah, ZGC).
  - V8's Orinoco is generational.
  - GHC, OCaml, Go all use generational copying for the young generation.

- **Concurrent / incremental**: the GC runs concurrently with the program, with write barriers cooperating between them.
  - Go's GC is concurrent tri-color mark-sweep.
  - V8's Orinoco has concurrent marking.
  - Java's ZGC and Shenandoah are concurrent compacting collectors.
  - GHC has an optional concurrent GC.

- **Region-based / arena**: explicit regions; objects allocated in a region; whole region freed at once.
  - Common in C-style allocators.
  - Cyclone language has region inference.
  - Mesa, Cyclone, Cylinder languages had region types.

Production examples per algorithm above.

Why we do not have it: INTERCAL has no garbage collection. Arrays are allocated via `mmap` directly; there is no general-purpose heap. The language has no closures, no recursive data structures (no pointers), no allocation lifetime management to do.

What it would take: a different language. Adding GC to INTERCAL would mean adding language features (object types, references) that are not in the spec.

Where to read more: *The Garbage Collection Handbook* (Jones, Hosking, Moss 2nd ed. 2023), the canonical reference. Per-runtime documentation for Go, GHC, V8.

## Automatic Reference Counting (ARC)

What it is: compile-time-inserted reference-count operations (retain/release) that the runtime executes. ARC is between full GC and manual memory management: the compiler does the bookkeeping; the runtime executes simple atomic counter updates.

Production examples:
- Swift's ARC, with the SIL-level ARC optimisation pass that eliminates redundant retain/release pairs.
- Objective-C 2.0+ ARC.

Why we do not have it: no reference types in INTERCAL.

Where to read more: Apple's ARC documentation; the LLVM-level ARC optimisation passes; Swift's SIL ARC optimisation source.

## Exception handling (zero-cost via DWARF)

What it is: a mechanism for non-local error propagation. "Zero-cost" exceptions encode unwinding information in metadata tables (DWARF on Unix, similar formats elsewhere) so the happy-path code pays nothing; only the throw walks the tables.

Production examples:
- C++ exceptions on Itanium ABI.
- Rust panics (with `panic = "unwind"`).
- Swift error propagation.
- OCaml exceptions (lighter implementation, no DWARF tables).

Why we do not have it: INTERCAL has no exceptions. Errors are runtime-fatal (`ICL...I` codes); the program prints and exits. No unwinding.

Where to read more: the Itanium C++ ABI specification (sections on exception handling); the libunwind documentation; Bjarne Stroustrup's papers on C++ exception design.

## Coroutines / fibers / green threads

What they are: lightweight execution contexts that the runtime multiplexes onto a smaller pool of OS threads. Concurrent programming without per-task OS thread overhead.

Production examples:
- Go's goroutines: M:N scheduling, runtime-managed stacks.
- Haskell's Control.Concurrent threads on top of GHC's RTS.
- Erlang/OTP processes (not the same as OS processes).
- Rust's async/await with a runtime like `tokio` (no language-level fibers; the runtime provides the scheduling).
- Crystal fibers.
- Lua coroutines.

Why we do not have it: INTERCAL has no concurrency.

Where to read more: Go's runtime source for the production-grade implementation; "Cooperative Threads in Lua" papers; Erlang/OTP design documents.

## Stack growth

What it is: the runtime mechanism by which a function's stack can grow beyond its initial allocation. Critical for languages that nest deeply (functional languages) or that start with small stacks (goroutines).

Production examples:
- Go's split-stacks (until 1.2) and now contiguous-copy-and-grow stacks. Goroutines start with 2KB stacks.
- Erlang's per-process stacks grow dynamically.
- GHC's RTS manages thread stacks.

Why we do not have it: our compiled binaries use the OS stack, which is large enough for INTERCAL programs and grows on demand via OS facilities.

Where to read more: the Go runtime source on `morestack`; "Goroutines: A Brief Tour".

# Execution model techniques

## JIT compilation (single-tier)

What it is: compiling code at runtime, often from bytecode or directly from source. Distinct from AOT compilation, which produces an executable beforehand.

Production examples:
- LuaJIT (a single-tier tracing JIT).
- LLVM's MCJIT and ORC (general-purpose JIT infrastructure).
- HotSpot's C1 and C2 (multiple JIT tiers).

Why we do not have it: we compile ahead of time. INTERCAL has no use case demanding runtime compilation.

What it would take: significant infrastructure. JIT requires runtime memory management for code, instruction-cache flushing, deoptimisation paths.

Where to read more: "Implementing a Tracing JIT" (Mike Pall's LuaJIT writings); LLVM's ORC documentation; HotSpot's source.

## Tiered JIT compilation

What it is: multiple JIT tiers operating on the same code, with promotion based on hotness. A function starts interpreted, gets baseline-JIT'd if warm, gets optimising-JIT'd if hot.

Production examples:
- V8 has Ignition, Sparkplug, Maglev, TurboFan (four tiers).
- HotSpot has Interpreter, C1, C2.
- JavaScriptCore has LLInt, Baseline, DFG, FTL.
- LuaJIT has interpreter and trace JIT.

Why we do not have it: AOT only.

Where to read more: V8's blog posts on each tier; "Crankshaft" papers from V8's history; Mike Pall's LuaJIT writings on trace selection.

## Speculation and deoptimisation

What it is: optimised code generated under runtime assumptions ("this property is always at this offset"; "this variable is always SmallInt"). Deoptimisation is the safety net: when an assumption fails, control returns to a less-optimised tier, with state reconstructed from the optimised code.

Production examples:
- V8's TurboFan emits deoptimisation checkpoints. Lazy deopt vs eager deopt.
- HotSpot's C2 has the same machinery.
- LuaJIT's traces have side exits with reconstruction.

Why we do not have it: AOT only. Deoptimisation requires a runtime to fall back to.

Where to read more: "Self: An Object-Oriented Self-Reflective Programming Language" (Ungar and Smith 1987); Cliff Click's papers on HotSpot C2; V8 design docs on deoptimisation.

## On-Stack Replacement (OSR)

What it is: replacing a currently-executing function with a more-optimised version mid-execution. Critical for hot loops where the function will not return for a long time.

Production examples:
- V8's TurboFan supports OSR.
- HotSpot supports OSR.
- LLVM has experimental support.

Why we do not have it: AOT only.

Where to read more: "Optimizing Java with Compile-Time Information" (Holzle 1994); HotSpot OSR documentation.

## Inline caches

What it is: per-call-site type caches. A property access `x.foo` on first use is uncached; second use looks up the IC; if the receiver is the same shape, the cached field offset is used directly.

Production examples:
- V8's IC machinery.
- JavaScriptCore's polymorphic ICs.
- Self's monomorphic ICs (where the technique was invented).
- HotSpot uses inline caches for virtual calls.

Why we do not have it: INTERCAL is statically typed; there are no dynamic dispatch sites that would benefit.

Where to read more: "Customization: Optimizing Compiler Technology for Self, a Dynamically-Typed Object-Oriented Programming Language" (Chambers and Ungar 1989); V8's IC source.

## Hidden classes / shape inference

What it is: the runtime tracks each object's structural shape, so that property accesses can be specialised to direct field loads when the shape is known.

Production examples:
- V8's Maps (the runtime structure, not the JS Map type).
- JavaScriptCore's structures.
- HotSpot's klassOop.

Why we do not have it: no dynamic objects.

Where to read more: "Customization" (Chambers and Ungar 1989); V8 design docs on Maps and transitions.

# Tooling and infrastructure

## Incremental compilation (queries, Salsa-style)

What it is: caching compilation work at fine granularity (per-function or per-query) so that small source changes do not require recompiling the world.

Production examples:
- rustc's query system: every cacheable computation is a `Query`. The system tracks dependencies between queries automatically. `compiler/rustc_query_system/`.
- The Salsa library (used by rust-analyzer and inspired by rustc).
- Bazel's content-addressed caching.
- Roslyn (C#'s compiler) for incremental compilation.

Why we do not have it: our compiler runs in milliseconds. Incremental compilation would help a project with hundreds of source files; we have none.

What it would take: substantial infrastructure. Each computation must be made into a memoised query, with input hashing and dependency tracking. ~1000 lines minimum.

Where to read more: the rustc-dev-guide chapter on the query system; Salsa's documentation; "Incremental Computation" by Niko Matsakis (blog series).

## Parallel compilation

What it is: compiling different parts of a program in parallel, on multiple cores.

Production examples:
- Cargo runs `rustc` invocations in parallel (one per crate).
- Bazel parallelises by build action.
- Go compiles packages in parallel.
- LLVM's ThinLTO parallelises module-level optimisation.

Why we do not have it: we compile one file. There is nothing to parallelise.

What it would take: a multi-file INTERCAL extension first, then per-file parallel compilation.

Where to read more: the Cargo documentation; Bazel internals; "ThinLTO: Scalable and Incremental LTO" (Johnson et al. 2017).

## Distributed compilation

What it is: distributing compilation work across a cluster, with content-addressed caching shared between machines.

Production examples:
- `sccache`: shared compilation cache for Rust and C/C++.
- `distcc`: distributed C/C++ compilation.
- `goma`: Google's distributed compilation service.
- Bazel remote execution.

Why we do not have it: irrelevant at our scale.

Where to read more: sccache's README; the Bazel remote-execution documentation.

## Language Server Protocol (LSP) integration

What it is: a protocol between IDEs and language servers. Editors implement the client; the language vendor implements the server.

Production examples:
- rust-analyzer for Rust.
- gopls for Go.
- haskell-language-server for Haskell.
- ZLS for Zig.
- clangd for C/C++.
- swift-tools/SourceKit-LSP for Swift.

Why we do not have it: nobody types INTERCAL inside an IDE. The cost-benefit is poor.

What it would take: an LSP server that wraps our parser and produces hover info, diagnostics, completions. Probably 1000+ lines.

Where to read more: the LSP specification at <https://microsoft.github.io/language-server-protocol/>; the rust-analyzer source; "Three Architectures for a Responsive IDE" by Aleksey Kladov (rust-analyzer's author).

## Sanitizers

What they are: runtime-instrumented checking that detects classes of bugs at execution time. Each sanitizer targets a specific class.

Production examples:
- AddressSanitizer (ASan): use after free, buffer overflow, double free.
- ThreadSanitizer (TSan): data races.
- UndefinedBehaviorSanitizer (UBSan): undefined behaviour patterns.
- MemorySanitizer (MSan): uninitialised reads.
- All ship with both LLVM and GCC. Implementation in `compiler-rt/lib/`.

Why we do not have it: INTERCAL has no concept of memory safety to violate. Variables are integers; arrays are bounds-checked at runtime; there is no pointer arithmetic to misbehave. The bugs sanitizers find do not exist in INTERCAL programs.

Where to read more: "AddressSanitizer: A Fast Address Sanity Checker" (Serebryany et al. 2012); "ThreadSanitizer" papers; the compiler-rt source in LLVM.

## Fuzzing infrastructure

What it is: feeding random or mutation-generated inputs to a target to find crashes and undefined behaviour.

Production examples:
- libFuzzer (LLVM project).
- AFL and AFL++.
- syzkaller for kernel fuzzing.
- Google's OSS-Fuzz.
- Csmith for compiler fuzzing.

Why we do not have it: limited but possible. Csmith-style differential testing for INTERCAL would mean generating random INTERCAL programs and comparing our compiler's output against another INTERCAL implementation (C-INTERCAL, CLC-INTERCAL).

What it would take: a generator for valid INTERCAL programs, plus the comparator. Possible weekend project.

Where to read more: "AFL: American Fuzzy Lop" papers; "Finding and Understanding Bugs in C Compilers" (Yang et al. 2011); the libFuzzer documentation.

## Differential testing at scale (csmith-like)

What it is: using a property-preserving program generator to find compiler bugs by compiling the same program with multiple compilers and comparing outputs.

Production examples:
- Csmith for C compilers. Found hundreds of bugs in GCC and LLVM.
- Crater for rustc (compiles every crates.io crate against a candidate rustc).
- Yarpgen (newer C generator).

Why we do not have it: our differential testing is much smaller (pure-vs-native syslib in `tests/test_syslib_pure.sh`). Csmith-scale would require a real INTERCAL program generator and another reference compiler to compare against.

Where to read more: the Csmith paper (Yang et al. 2011); Crater documentation; the OSS-Fuzz blog posts on compiler bugs.

# Additional GC algorithms

The GC section above covered the algorithm families. The taxonomy hides a lot of important specific algorithms each with distinct trade-offs.

## ZGC (Z Garbage Collector)

What it is: a scalable, low-latency collector for the JVM that performs nearly all work concurrently, achieving consistent pause times in the 0.1-0.5 ms range regardless of heap size, scaling to terabyte heaps. Uses 64-bit colored pointers (metadata stored in unused virtual address bits) plus load barriers to relocate objects while application threads run. JEP 439 added a generational variant.

Production: OpenJDK (default for many low-latency Java workloads).

Where to read more: JEP 333 and JEP 439 on openjdk.org; "Deep Dive into ZGC" (TOPLAS 2022).

## Shenandoah

What it is: Red Hat's region-based concurrent compacting collector that performs evacuation while application threads run, using Brooks-style forwarding pointers and read/write barriers; pauses are independent of live-set size.

Production: OpenJDK since JDK 12, Red Hat Enterprise Linux Java workloads.

Where to read more: Flood et al., "Shenandoah" (PPPJ 2016); Red Hat developer guide on Shenandoah.

## G1 (Garbage First)

What it is: region-partitioned, generational, mostly-concurrent collector that prioritises evacuating regions with the most garbage to meet a soft pause-time goal. Default in HotSpot since Java 9. The algorithmic ancestor of Shenandoah, ZGC, and Azul C4.

Production: OpenJDK default for general-purpose workloads.

Where to read more: Detlefs et al., "Garbage-First Garbage Collection" (ISMM 2004); Oracle's G1 tuning guide; "Deconstructing the Garbage-First Collector" (VEE 2020).

## Immix (mark-region collector)

What it is: a mark-region collector that allocates into contiguous lines (128 B) within blocks (32 KB), reclaims at line and block granularity, and opportunistically evacuates fragmented blocks in a single pass. Combines the throughput of mark-sweep with the locality of copying collectors.

Production: Rubinius (Ruby), Crystal's experimental GC, MMTk (Memory Management Toolkit, used by V8 and OpenJDK research integrations).

Where to read more: Blackburn and McKinley, "Immix" (PLDI 2008).

## Boehm-Demers-Weiser GC

What it is: a conservative mark-sweep collector for C/C++ that scans the stack and globals as untyped roots, treating any bit pattern that looks like a pointer as one. Trades precision for the ability to retrofit GC onto languages without type metadata.

Production: Mono (legacy), GNU Objective-C, Crystal, GCJ, GNU Guile, many embedded language runtimes.

Where to read more: hboehm.info/gc/ (the canonical site); Boehm and Weiser, "Garbage collection in an uncooperative environment" (SP&E 1988).

## Deferred reference counting

What it is: Deutsch-Bobrow's optimisation that omits RC updates for stack and register references, then periodically reconciles by scanning roots against a zero-count table. Cuts roughly 99% of RC operations in Lisp/ML-like workloads, at the cost of delayed reclamation.

Production: original LISP implementations; conceptual basis for many modern RC systems.

Where to read more: Deutsch and Bobrow, "An Efficient, Incremental, Automatic Garbage Collector" (CACM 1976).

## Biased reference counting

What it is: each object is "owned" by one thread; the owner uses non-atomic increments while other threads update a separate atomic counter, merged on ownership transfer. Halves RC cost in the common case where most updates come from one thread.

Production: Swift runtime since iOS/macOS 14 timeframe.

Where to read more: Choi, Shull, Torrellas, "Biased Reference Counting" (PACT 2018); Swift Forums design discussion.

## Bacon cycle collection (trial deletion)

What it is: a concurrent algorithm that detects cycles by colouring potential roots "purple" on RC decrement, then performing trial decrement traversal to find self-sustaining subgraphs unreachable from outside. Avoids global heap walks.

Production: PHP since 5.3, IBM Recycler (Jalapeño JVM), conceptually CPython's `gc` module.

Where to read more: Bacon and Rajan, "Concurrent Cycle Collection in Reference Counted Systems" (ECOOP 2001).

# Additional execution-model techniques

## Trace JIT vs method JIT

What they are: two main JIT strategies. *Method JITs* (HotSpot C1/C2, V8 TurboFan) compile whole methods using profile data. *Trace JITs* (LuaJIT, early TraceMonkey, PyPy with tracing) compile linear hot paths starting at loop edges, inlining across function boundaries by following execution. Trace JITs excel at tight loops in dynamic languages but suffer at branch-heavy code.

Production: LuaJIT (Mike Pall) is the canonical trace JIT; PyPy uses a meta-tracing approach; HotSpot and V8 are method-based.

Where to read more: Mike Pall's LuaJIT design notes; Gal et al., "Trace-based Just-in-Time Type Specialization" (PLDI 2009).

## Polymorphic inline caches (PICs)

What they are: extension of monomorphic ICs that record several (receiver-type, target) pairs per call site, enabling fast dispatch for sites with multiple but bounded receiver types and exposing concrete type information to the recompiler.

Production: Self, Strongtalk, HotSpot, V8, JavaScriptCore.

Where to read more: Hölzle, Chambers, Ungar, "Optimizing Dynamically-Typed OO Languages with Polymorphic Inline Caches" (ECOOP 1991); the foundational paper.

## Stack maps for precise GC

What they are: per-call-site metadata recording exactly which stack slots and registers hold live GC pointers, enabling collectors to relocate objects without scanning untyped memory. The alternative (conservative scanning, Boehm-style) over-retains and forbids moving collectors.

Production: HotSpot OopMaps, .NET CLR GCInfo, LLVM `gc.statepoint`.

Where to read more: LLVM Statepoints documentation; LLVM GarbageCollection guide.

## Safepoints

What they are: compiler-inserted polls (typically a load from a page that is unmapped to trigger SIGSEGV when GC is needed) that let mutator threads cooperatively pause at known points where stack maps are valid. Loop back-edges and method entries/exits are typical poll sites.

Production: HotSpot uses page-protected polling; V8 and .NET have similar mechanisms.

Where to read more: Aleksey Shipilev's "JVM Anatomy Quark #22: Safepoint Polls"; LLVM Statepoints.

## Class hierarchy analysis (CHA)

What it is: static analysis of the loaded class graph that proves a virtual call has only one possible target (the method has no overrides), enabling devirtualisation. In dynamic systems it must be invalidated when classes are loaded.

Production: HotSpot, GraalVM, Soot, Go's `golang.org/x/tools/go/callgraph/cha`.

Where to read more: Dean, Grove, Chambers, "Optimization of Object-Oriented Programs Using Static Class Hierarchy Analysis" (ECOOP 1995).

## Speculative devirtualisation

What it is: inline a likely target guarded by a type check (or rely on CHA plus a deopt trap if a new class is loaded), backed by deoptimisation when speculation fails. Bridges PICs and full inlining.

Production: HotSpot C2, GraalVM, V8 TurboFan.

Where to read more: Ishizaki et al., "A Study of Devirtualization Techniques for a Java JIT Compiler" (OOPSLA 2000); Shipilev, "Black Magic of Java Method Dispatch".

## Inline cache repair and IC miss handling

What it is: on a cache miss, the runtime patches the call site (monomorphic to polymorphic to megamorphic) atomically, often by writing into JIT-generated stubs. Megamorphic sites may bail out to a method-table lookup.

Production: V8 (feedback vectors), JavaScriptCore (LLInt + Baseline tiers), HotSpot.

Where to read more: Brunthaler, "Inline caching meets quickening" (ECOOP 2010); Mathias Bynens's V8 ICs blog series.

## Two-tier compilation (C1 + C2)

What it is: methods start in the interpreter, get promoted to the fast-compiling C1 (client) for profiling, and only the hottest are recompiled by the slower-but-better C2 (server). HotSpot defines five levels (interpreter through full C2). Balances startup latency against peak throughput.

Production: OpenJDK HotSpot (the original two-tier model), Azul Zing/Falcon, V8 with its four-tier extension (Ignition, Sparkplug, Maglev, TurboFan).

Where to read more: Microsoft's "How Tiered Compilation works in OpenJDK"; InfoQ's "What the JIT!?".

## AutoFDO

What it is: sample-based PGO that consumes hardware counter (`perf record`) data from production, normalises it to a profile format, and feeds it into LLVM/GCC. No instrumented build needed.

Production: Google datacentre fleet (5-15% wins), Android kernel (up to 10% gains), the LLVM toolchain itself.

Where to read more: Chen et al., "AutoFDO: Automatic Feedback-Directed Optimization" (CGO 2016); Linux kernel AutoFDO docs.

## Case studies in JIT compilation

A few production JIT stories worth singling out, because they illustrate different points in the design space:

**PHP JIT (PHP 8.0)**: implemented "as an almost independent part of OPcache" using DynASM, the lightweight code generator from LuaJIT. Rather than introducing a separate IR, the system generates native code directly from PHP bytecode combined with SSA-framework analysis. Supports x86, x86_64, ARM. Performance varies by workload: ~4x on Mandelbrot, ~2x on general microbenchmarks, ~1.3x on PHP-Parser, near-zero on WordPress (typical web workloads are I/O-bound, not CPU-bound). The approval vote was 50-2 for PHP 8.0; an earlier 7.4 attempt had failed (18-36) due to engine-stability concerns. Lesson: JIT is high-payoff for CPU-intensive workloads, low-payoff for typical web workloads, and the maintenance cost is real (debugging requires reading machine code dumps). See <https://wiki.php.net/rfc/jit>.

**Octave JIT (removed 2021)**: an LLVM-based JIT for the Octave numerical-computing language, originally implemented in Google Summer of Code 2012 by Max Brister. The implementation built an intermediate IR for type inference before converting to LLVM IR, because Octave's untyped AST cannot lower to LLVM IR directly. JIT only triggered at loop entry points, with fallback to the interpreter on compilation failure. Removed in 2021 because of LLVM API instability (each LLVM version broke the build) and the maintenance burden of a niche component. Lesson: JIT-via-LLVM trades simplicity (you reuse the LLVM optimiser) for sustainability (you commit to chasing the LLVM API forever). See <https://wiki.octave.org/JIT>.

**LuaJIT**: a from-scratch tracing JIT, no LLVM, no third-party backend. Hand-written x86/x64/ARM/ARM64/PPC/MIPS code generation with extreme attention to per-instruction quality. By many accounts the fastest JIT for any dynamic language, ahead of V8 on numerical workloads. Lesson: a full custom JIT can outperform LLVM-based ones if the language semantics are narrow enough that the optimiser can be tightly tuned to them.

The general lesson across these three: there is no one JIT design. The right choice depends on language semantics, target user base, maintenance willingness, and what existing infrastructure you can lean on. JIT writeups in *The c2 Wiki* (<https://wiki.c2.com/?JustInTimeCompiler>) and the Wikipedia article are useful jumping-off points before reading the production sources.

# Security techniques in production compilers

Compilers are increasingly responsible for memory-safety enforcement at the binary level. Our INTERCAL compiler does none of these because INTERCAL has no memory-safety bugs to mitigate (no pointer arithmetic, no buffer overruns possible in the source language). But every modern toolchain ships them.

## Stack canaries

What it is: a random word placed between local variables and the return address; verified on function exit. `-fstack-protector` covers functions with char buffers; `-fstack-protector-strong` extends to any function with arrays, address-taken locals, or local register variables, covering ~20% of functions at ~2% size cost.

Production: Linux kernel, glibc, every major distro, Chrome, Firefox.

Where to read more: Red Hat's "Use compiler flags for stack protection"; Kees Cook's "-fstack-protector-strong" blog post.

## Control Flow Integrity (CFI)

What it is: at indirect calls, checks the target against a per-function-type bit vector built at LTO time; targets are rerouted through canonical jump-table entries. Defends against forward-edge hijacking.

Production: Android (kernel + userspace), Chrome OS, parts of iOS.

Where to read more: Clang's `ControlFlowIntegrity.html`; "CFI Design" doc in Clang source.

## SafeStack

What it is: splits the stack into a "safe stack" (return addresses, spills, scalars accessed safely) at a randomised hidden address, and an "unsafe stack" (buffers, address-taken locals). Backward-edge protection without runtime checks.

Production: Clang's `-fsanitize=safe-stack`, Fuchsia OS.

Where to read more: Clang SafeStack documentation; Kuznetsov et al., "Code-Pointer Integrity" (OSDI 2014).

## Shadow stacks

What it is: hardware- or compiler-maintained second stack holding only return addresses, checked on RET. Hardware variant (Intel CET SHSTK) has the CPU push to both stacks on CALL and trap on mismatch.

Production: Intel CET on 11th gen Core / Zen 3+; Windows 10/11 Hardware-enforced Stack Protection; Linux 6.4+.

Where to read more: Intel CET technical overview; Linux `shstk` docs.

## ARM Pointer Authentication (PAC)

What it is: ARMv8.3-A instructions (`PAC*`/`AUT*`) sign pointers with a tweak (typically the SP) and a key, storing a MAC in unused upper address bits. Tampered pointers fail authentication and fault.

Production: Apple A12+/M1+ (arm64e ABI; XNU kernel uses a hardened variant), Linux kernel.

Where to read more: ARM "Pointer Authentication" learn module; Project Zero "Examining Pointer Authentication on iPhone XS"; Liljestrand et al., "PAC it up" (USENIX Security 2019).

## Branch Target Identification (BTI)

What it is: ARMv8.5-A landing-pad scheme. Indirect branches (BR/BLR) trap unless the target is a `BTI` instruction of the matching kind (c/j/jc). Forward-edge counterpart to PAC.

Production: aarch64 Linux since 5.8 with PROT_BTI; Fedora aarch64; Apple silicon. NSA reported a 50x reduction in usable ROP gadgets.

Where to read more: LWN "ARMv8.5-A: Branch Target Identification support"; ARM developer guide on PAC, BTI, MTE.

## ASLR and codegen interaction

What it is: Address Space Layout Randomization works best when the compiler emits position-independent code (PIC/PIE) and avoids absolute addresses; codegen must materialise globals via GOT/PLT or PC-relative `lea`. Static initialisers, JIT-emitted code, and TLS interact in subtle ways.

Production: every modern OS userspace, KASLR in Linux/Windows kernels.

Where to read more: PaX team's original design document; glibc Hardening manual.

## RELRO and full RELRO

What it is: linker reorders ELF segments so relocations sit in a region that is `mprotect`'d read-only after dynamic loading. Partial RELRO protects `.got` but not `.got.plt`; full RELRO (`-Wl,-z,relro,-z,now`) resolves all PLT entries eagerly and freezes the entire GOT, blocking GOT overwrite attacks.

Production: every major distribution's hardened build flags.

Where to read more: Red Hat's "Hardening ELF binaries using RELRO"; Tk's original RELRO article.

## Stack-clash mitigation

What it is: the compiler emits a probe (`mov` to `[sp]` or similar) every page when allocating large stack frames or `alloca`, ensuring the kernel guard page is touched and a stack-heap collision fails fast.

Production: GCC `-fstack-clash-protection` since 8; Clang since 12 on x86/SystemZ/PPC; default in RHEL 8+, Fedora 27+.

Where to read more: Red Hat's "Stack clash mitigation in GCC"; LLVM blog "Bringing Stack Clash Protection to Clang/X86".

## -fcf-protection (Intel CET in GCC/Clang)

What it is: inserts ENDBR64 at all indirect-branch targets (IBT) and emits shadow-stack-aware prologues/epilogues. On non-CET CPUs ENDBR is a NOP, so binaries are forward-compatible.

Production: Linux kernel (IBT enforced since 6.2), Fedora, Ubuntu, Windows.

Where to read more: GCC Instrumentation Options manual page; Intel CET overview.

# Additional middle-end optimisations

## CSSPGO (Context-Sensitive Sample PGO)

What it is: extends AutoFDO with synchronised LBR + stack sampling to reconstruct calling contexts, plus pseudo-instrumentation pseudo-probes that make sample-to-IR mapping precise without runtime overhead. Roughly +2% over AutoFDO at -4% text size on SPEC2006.

Production: Meta uses CSSPGO on >75% of datacentre cycles; upstream LLVM.

Where to read more: He, Yu et al., "Revamping Sampling-Based PGO with Context-Sensitivity and Pseudo-instrumentation" (CGO 2024).

## Propeller (post-link block reordering)

What it is: emits one ELF section per basic block (`-fbasic-block-sections`), then relinks using a fresh profile to lay out hot blocks contiguously, split cold blocks out, and reorder functions. Avoids binary rewriting (unlike BOLT).

Production: Google datacentre fleet, Clang itself (~7%), MySQL (~1%), kernels.

Where to read more: Shen et al., "Propeller" (ASPLOS 2023); google/llvm-propeller on GitHub.

## Spectre mitigations: retpoline and LFENCE

What they are: *Retpoline* replaces indirect call/jmp with a return-trap that traps speculation in an infinite loop on the BTB-poisoning path. *LFENCE-after-load* serialises load address resolution before dependent branches.

Production: Linux kernel (`CONFIG_MITIGATION_RETPOLINE`), Windows kernel, hypervisors. Compiler flags: `-mretpoline` (Clang), `-mindirect-branch=thunk` (GCC).

Where to read more: Intel's "Retpoline" whitepaper; LWN "Retpoline" coverage; Linux Spectre kernel docs.

## Branch divergence analysis (GPU)

What it is: dataflow analysis classifying values as *uniform* (same across a warp/wavefront) or *divergent*; branches on divergent conditions force SIMT serialisation. Used to skip divergence-handling code, drive control-flow linearisation, and inform register allocation.

Production: NVCC/PTX, AMD ROCm/HIPCC, LLVM `LegacyDivergenceAnalysis` and the newer `UniformityAnalysis`.

Where to read more: Han and Abdelrahman, "Reducing Branch Divergence in GPU Programs" (GPGPU 2011); LLVM UniformityAnalysis docs.

## Memory dependence analysis

What it is: per-instruction queries answering "which prior store could this load see?" built on top of alias analysis. LLVM's `MemoryDependenceAnalysis` (and the newer `MemorySSA`) underpins GVN, DSE, LICM, and memcpy optimisation. SCEV-AA improves precision inside loops by reasoning about induction variables symbolically.

Production: LLVM, GCC's tree-SSA, Java HotSpot C2 (ideal graph).

Where to read more: LLVM Alias Analysis Infrastructure; LLVM MemorySSA documentation.

# Concurrency primitives

## Memory ordering models (SC, TSO, RC)

What they are: *Sequential Consistency* (textbook, expensive on hardware), *Total Store Order* (x86, SPARC: stores can be buffered past loads), *Relaxed/Release-Consistency* (ARM, POWER, RISC-V: loads and stores reorder freely without barriers). C++11/C/Rust atomics expose these via `memory_order_*`; the compiler picks the cheapest implementation per target.

Production: every multi-core compiler.

Where to read more: Sewell et al., "x86-TSO: A Rigorous and Usable Programmer's Model"; Boehm-Adve mappings to processors.

## Atomics codegen: cmpxchg vs LL/SC

What it is: on x86 (TSO + locked instructions) the compiler emits `LOCK CMPXCHG` and `XCHG`; on ARM/POWER/RISC-V (LL/SC) it emits a load-exclusive / store-conditional retry loop, often expanded late (after register allocation) to satisfy hardware constraints on the loop body. Acquire/release become barriers (`DMB ISH` on ARMv7, `LDAR/STLR` on ARMv8).

Production: LLVM `AtomicExpandPass`, GCC `__atomic_*` builtins.

Where to read more: LLVM Atomics Concurrency Guide; Boehm-Adve C++0x mappings.

## Lock elision / hardware transactional memory (TSX)

What it is: hardware speculatively executes a critical section without taking the lock; on conflict it aborts and retries non-speculatively. Compiler exposed via `XACQUIRE`/`XRELEASE` prefixes (HLE) or `_xbegin`/`_xend` intrinsics (RTM). HLE is now deprecated by Intel; RTM remains but has been disabled or sandboxed by microcode in many parts after MDS-class attacks.

Production: glibc had `pthread_mutex` HLE paths; mostly removed in 2019+.

Where to read more: Intel TSX Wikipedia summary with microcode-disable history.

# Embedded and specialised techniques

## -Oz code-size optimisation

What it is: Clang's most aggressive size pass. Like `-Os` (which is `-O2` with size-tuned inliner and merge thresholds) but trades further runtime for smaller text. Disables loop unrolling, prefers `tail-call` over inlining, enables outliner. Roughly 15% smaller than `-Os` typically, with measurable perf loss.

Production: iOS apps default to `-Os`; embedded firmware uses `-Oz`.

Where to read more: Clang command guide; LLVM machine-outliner docs.

## ROM placement

What it is: linker scripts and section attributes (`__attribute__((section(".rodata.foo")))`) place constants and code in flash/ROM regions, with RAM reserved for `.data`/`.bss`. Toolchain support includes copy-to-RAM stubs in startup code and XIP (execute-in-place) flash configurations.

Production: every embedded GCC/LLVM target; ARM Keil, IAR, Zephyr, FreeRTOS.

Where to read more: GCC linker script docs; Zephyr linker script architecture.

## Link-time DCE for embedded (`--gc-sections`)

What it is: `-ffunction-sections -fdata-sections -Wl,--gc-sections` puts each function/variable in its own section so the linker can prove unreferenced ones unreachable and drop them. Combined with `--print-gc-sections` to audit.

Production: every embedded GCC build, Linux kernel (LTO mode), Android NDK.

Where to read more: MaskRay's "Linker garbage collection"; LWN "Shrinking the kernel with link-time garbage collection".

## Fixed-point arithmetic

What it is: embedded DSP code uses Q-format integers (`Q15`, `Q31`) representing fractional values; compilers expose this via `_Fract`/`_Accum` types from ISO/IEC TR 18037 (Embedded C), or library intrinsics. Codegen emits scaled multiply-shift sequences and saturating ops.

Production: GCC fixed-point, TI C2000 codegen, ARM CMSIS-DSP.

Where to read more: ISO/IEC TR 18037 Embedded C; GCC fixed-point types docs.

## Saturating arithmetic intrinsics

What they are: LLVM's `@llvm.sadd.sat`, `@llvm.usub.sat`, `@llvm.ssub.sat`, and target-specific intrinsics clamp on overflow rather than wrapping. Lower to `SSAT`/`USAT`/`QADD`/`QSUB` on ARM, `PADDSB`/`PSUBSB` on x86 SIMD, dedicated DSP ops on Hexagon.

Production: image/audio codecs, neural network kernels (XNNPACK, ARM Compute Library).

Where to read more: LLVM LangRef saturation intrinsics; ARM ACLE saturation.

# WebAssembly-specific techniques

## Wasm-specific optimisations

What they are: beyond MVP, the toolchain now exploits *relaxed-SIMD* (implementation-defined fast paths for FMA, swizzle), *exception handling* (lowering to native EH instead of branchy returncodes), and the *GC proposal* (typed `(ref struct)`/`(ref array)` instead of linear-memory shadow heaps).

Production: Binaryen (wasm-opt), Emscripten, Kotlin/Wasm, Dart Wasm backend; WasmGC enabled in V8/SpiderMonkey/JavaScriptCore and Wasmtime.

Where to read more: WebAssembly proposals tracker on GitHub; Binaryen optimisation docs.

## Wasm Component Model

What it is: typed interfaces, resources, and a binary "component" format that wraps multiple core modules with strongly-typed shared-nothing linking driven by the Canonical ABI and WIT (Wasm Interface Types). Cross-language linking without C ABI compromises.

Production: Wasmtime (full support, late 2024), `wit-bindgen` for Rust/Go/Python/JS, jco.

Where to read more: component-model.bytecodealliance.org; WebAssembly/component-model repo.

## WASI evolution

What it is: *Preview 1* (snapshot of POSIX-flavoured syscalls) is now legacy; *Preview 2* (WASI 0.2, January 2024) is built on the Component Model with capability-typed worlds (`wasi:cli`, `wasi:http`, `wasi:io`); *Preview 3* (0.3, in flight 2025) adds native async via component-model streams and futures.

Production: Wasmtime, JCo, Spin, Wasmer; cloud platforms (Fastly, Fermyon).

Where to read more: WASI 0.2 announcement; WebAssembly/WASI repo.

# Modern frontend infrastructure

## Token-based diagnostic localisation

What it is: older compilers report errors by `(file, line, column)` derived from raw character offsets, which break on multibyte UTF-8 and re-tokenisation. Modern frontends attach diagnostics to *token ranges* (Roslyn `SyntaxToken`, Clang `SourceRange`, rust-analyzer `TextRange`), letting IDEs map them back through edits and macros.

Production: Roslyn, Clang/LLVM, rust-analyzer, swift-syntax.

Where to read more: Clang SourceManager design; Roslyn syntax overview.

## Recovery parsing for IDE responsiveness

What it is: "resilient" parsers (Tree-sitter's GLR, Roslyn's hand-written, rust-analyzer's `ungrammar`-driven) produce a partial tree even with syntax errors using approaches like phrase-level recovery, synchronisation tokens, and inserted dummy nodes. Critical for syntax highlighting, completion, and inlay hints during typing.

Production: Tree-sitter (GitHub semantic, Neovim, Helix, Atom), Roslyn, rust-analyzer, swift-syntax.

Where to read more: Aleksey Kladov's "Resilient LL Parsing Tutorial"; Tree-sitter creator's design notes.

## Semantic highlighting

What it is: LSP's `textDocument/semanticTokens` lets servers annotate tokens with type-derived categories (`parameter`, `enumMember`, `unusedVariable`) instead of relying on the editor's regex-based highlighter. Requires the type checker to emit per-token classification and supports incremental delta updates.

Production: clangd, rust-analyzer, gopls, OmniSharp, the TypeScript language server.

Where to read more: LSP `semanticTokens` spec; VS Code semantic highlight guide.

## Macro hygiene algorithms

What they are: the *Kohlbecker-Friedman-Felleisen-Duba* (KFFD) timestamp algorithm renames identifiers introduced by a macro so they cannot capture user names; *syntax-case* (Dybvig) records syntax objects with marks; *Set of Scopes* (Flatt, Racket 6.3+) replaces linear timestamps with a set of scope tags per identifier. Rust uses a hygienic but simpler `SyntaxContext`-based scheme for `macro_rules!`.

Production: Racket, Chez Scheme, Rust, Clojure, Scala 3 macros.

Where to read more: Flatt, "Bindings as Sets of Scopes" (POPL 2016); KFFD original (ACM 1986).

## Effect inference (research)

What it is: type-and-effect systems annotate function types with the side effects they perform (`io`, `exn`, `div`, `alloc`, user-defined). Koka uses row-polymorphic effects with Hindley-Milner-style inference, so most effect annotations are inferred. Algebraic effect handlers generalise exceptions, generators, and async.

Production: Koka (research/Microsoft), Eff, Frank, Effekt; OCaml 5 (handlers without inference).

Where to read more: Leijen, "Koka: Programming with Row-polymorphic Effect Types" (MSFP 2014); Leijen, "Type Directed Compilation of Row-Typed Algebraic Effects" (POPL 2017); Pretnar tutorial on algebraic effects.

# Verifying compilers and formal methods

A subfield of compiler engineering that our INTERCAL compiler does not touch at all: the work of producing compilers (or compiler components) with mathematical proofs of correctness. The proofs are typically discharged in a proof assistant (Coq, HOL4, Lean) and cover the property "for every input source, the produced binary computes the same observable behaviour as the source did under the language's formal semantics".

## CompCert

What it is: a Coq-verified optimising C compiler for a subset of C99. Written by Xavier Leroy and INRIA collaborators since 2005. About 100,000 lines of Coq plus generated OCaml. Targets PowerPC, ARM, x86-32, x86-64, RISC-V, Kalray K1.

Production: used in safety-critical avionics (Airbus, MTU Aero Engines), automotive (some Renault and PSA components), and security-sensitive kernel work. Commercially distributed by AbsInt.

What is verified: the entire pipeline from C AST to assembly. Every transformation, including standard optimisations (constant propagation, CSE, register allocation), is proved correct under CompCert's formal C semantics.

What is not verified: the parser (uses Menhir, separately verified by the Menhir-CompCertCASM project), the assembler/linker, the C library.

Lessons: building a verified compiler is a decade-plus project. CompCert produces code roughly 5-15% slower than `gcc -O2` on representative benchmarks. The trade-off is "you get a proof, you lose some optimisation". For safety-critical software, that is acceptable; for general use, it is not.

Where to read more: compcert.org; Leroy's papers ("Formal verification of a realistic compiler", CACM 2009).

## CakeML

What it is: a HOL4-verified ML compiler. Targets x86-64, ARM, MIPS, RISC-V. Self-bootstrapped: the bootstrap proof shows that CakeML (running CakeML's own source on its own runtime) produces a binary equivalent to the one verified to compile to.

Production: research/teaching primarily; growing presence in CHERI verification work and in academic projects requiring fully verified toolchains.

Where to read more: cakeml.org; "CakeML: A Verified Implementation of ML" (Kumar et al., POPL 2014).

## RustBelt

What it is: a Coq-verified semantic model of Rust's type system, plus proofs that several core unsafe-Rust libraries (Arc, Mutex, RwLock, Cell) are sound. Built on the Iris separation-logic framework.

Production: not integrated into rustc directly. Influences the compiler through papers and through the `rust-lang/unsafe-code-guidelines` working group's decisions.

Where to read more: rustbelt project page; "RustBelt: Securing the Foundations of the Rust Programming Language" (Jung et al., POPL 2018).

## Iris

What it is: a higher-order concurrent separation logic implemented in Coq. The framework underlying RustBelt and many other verified-software projects. The "right" tool for reasoning about heap-manipulating concurrent programs in 2026.

Where to read more: iris-project.org; tutorial at the Iris site; "Iris: Monoids and Invariants as an Orthogonal Basis for Concurrent Reasoning" (Jung et al., POPL 2015).

## Verified parsers (Menhir, CompCertCASM)

What they are: parser generators (or hand-written parsers) that come with proofs of correctness against an LR grammar specification. Menhir's `--coq` mode generates Coq code that can be verified to be correct. The CompCertCASM project verified Menhir's output.

Where to read more: Menhir documentation, "Validating LR(1) parsers" (Jourdan, Pottier, Leroy, ESOP 2012).

## Alive2

What it is: an automated tool for verifying LLVM IR-level optimisations are correct. Uses an SMT solver to check that a transformed function is observably equivalent to the original under LLVM's IR semantics.

Production: integrated into LLVM's CI in some configurations. Has found dozens of bugs in LLVM optimisations.

Where to read more: github.com/AliveToolkit/alive2; "Alive2: Bounded Translation Validation for LLVM" (Lopes et al., PLDI 2021).

## Csmith and YarpGen

What they are: random C program generators that produce well-defined C programs with known expected outputs. Used to fuzz compilers via differential testing: compile with multiple compilers, compare outputs, file bugs on divergence.

Production: Csmith found hundreds of bugs in GCC and LLVM. YarpGen is the newer generator with better coverage of vector and floating-point code.

Where to read more: Csmith on github.com/csmith-project/csmith; "Finding and Understanding Bugs in C Compilers" (Yang et al., PLDI 2011).

## KLEE, CBMC, SeaHorn

What they are: tools that turn programs into logical formulas and feed them to SMT solvers, looking for bugs.

- **KLEE**: symbolic execution on LLVM IR. Generates test inputs that trigger different execution paths.
- **CBMC**: bounded model checker for C. Unrolls loops to a fixed depth, then checks for assertion violations.
- **SeaHorn**: LLVM-based verification framework that combines abstract interpretation with model checking.

Production: KLEE is used in security research; CBMC in safety-critical software; SeaHorn in research.

Where to read more: klee.github.io; cbmc.org; seahorn.github.io.

## Frama-C

What it is: a static analysis platform for C with multiple plug-ins (Eva for value analysis, WP for weakest-precondition reasoning, RTE for runtime-error checking). Uses ACSL (ANSI/ISO C Specification Language) for annotations.

Production: avionics (Airbus), defence software, automotive embedded.

Where to read more: frama-c.com; the Frama-C tutorial.

# Advanced type systems beyond what we have

## Refinement types

What they are: types augmented with logical predicates that constrain values. `{x: Int | x >= 0}` is a refined integer; the compiler emits SMT queries to verify that operations preserve the refinement.

Production:
- Liquid Haskell: refinement types for Haskell. Verifies properties like array-index safety, division by zero.
- F* (FStar): Microsoft's verification-oriented language combining refinement types with SMT.
- Refinement types in Idris 2.

Where to read more: "Refinement Types for Haskell" (Vazou et al., ICFP 2014); fstar-lang.org.

## Dependent types in production

What they are: types that can depend on values. `Vec n A` is a vector of `n` elements of type `A`, where `n` is a value. The compiler must prove that operations preserve length constraints.

Production:
- **Idris 2**: a general-purpose programming language with dependent types. Compiles to native code via Chez Scheme or to JavaScript.
- **Lean 4**: a theorem prover with a usable native code generator. Compiles via C.
- **Coq's Extraction**: Coq programs can be extracted to OCaml or Haskell, then compiled normally.

Where to read more: idris-lang.org; lean-lang.org; "Programming in Lean 4" (Avigad).

## Linear types vs affine types

What they are: type-system extensions that constrain how often a value can be used. *Linear*: exactly once. *Affine*: at most once. Useful for resources (file handles, mutex locks, memory) that must not be duplicated or forgotten.

Production:
- Linear Haskell (extension to GHC since 9.0).
- Granule (research linear/graded types).
- ATS (linear types for systems programming).
- Rust's affine types (a value can be moved, after which the original is invalidated).

Where to read more: "Linear Haskell" (Bernardy et al., POPL 2018); the Granule project.

## Session types

What they are: types that describe communication protocols. A session type `!Int.?Bool.End` means "send an Int, receive a Bool, terminate". Communication that does not match the session type is a type error.

Production:
- Scribble (a protocol-description language with backends for Java, Erlang, Go).
- Session-typed APIs in Rust (the `session` crate).
- Research languages like Pikelet.

Where to read more: scribble.org; "Multiparty Session Types" papers (Honda, Yoshida).

## Capability and ownership systems beyond Rust

What they are: type-system features that track who can do what to a value.

- **Pony's reference capabilities**: `iso`, `val`, `ref`, `box`, `tag`, `trn`. Each capability constrains aliasing and mutation. Pony's runtime is data-race-free by construction.
- **Project Verona** (Microsoft Research): regions plus reference capabilities, aimed at gradual ownership.
- **Alms**: ML extension with linear types and capabilities.
- **Mezzo**: ML-family language with permission-based ownership.

Where to read more: ponylang.io; project-verona on GitHub.

## F* (FStar)

What it is: a typed lambda calculus combining dependent types, refinement types, monadic effects, and SMT-aided proof. Compiles to OCaml, F#, or C (via KreMLin/Karamel).

Production: Microsoft Project Everest's verified TLS stack (HACL\*, EverParse, EverCrypt). Linux kernel's WireGuard adopted HACL* code.

Where to read more: fstar-lang.org; the Everest project; "F\*: A Tour de Force" papers.

# GPU and HPC compilation

## NVPTX backend

What it is: LLVM's NVIDIA GPU backend. Targets PTX (NVIDIA's intermediate assembly), which the NVIDIA driver JITs to actual GPU machine code. Used by CUDA Clang, CUTLASS, OpenAI's Triton, and the entire NVIDIA toolchain.

Where to read more: LLVM's `lib/Target/NVPTX/`; the PTX ISA reference manual; the OpenAI Triton compiler source.

## AMDGPU backend

What it is: LLVM's AMD GPU backend. Targets GCN, RDNA, CDNA architectures. Used by ROCm/HIP, AMD OpenCL, and increasingly by ML frameworks.

Where to read more: LLVM's `lib/Target/AMDGPU/`; the AMD GPU ISA documentation.

## SPIR-V codegen

What it is: SPIR-V is a portable IR for GPU shaders and compute kernels, used by Vulkan, OpenCL 2.1+, and OpenGL extensions. Compilers targeting SPIR-V (Clang OpenCL, glslang for GLSL, DXC for HLSL, IREE) emit SPIR-V; vendors translate it to their hardware.

Where to read more: KhronosGroup/SPIRV-Cross; the Vulkan specification.

## Variable-length vectorisation: SVE, RVV, AVX-512

What they are: vector-instruction-set extensions where the vector length is a runtime parameter rather than fixed at compile time. The compiler emits length-agnostic loops that work for any vector width the CPU supports.

- **SVE/SVE2** (ARM): Scalable Vector Extension. Aimed at HPC; widely deployed in 2024+ ARM chips.
- **RVV** (RISC-V): Vector Extension. The RISC-V analogue.
- **AVX-512** (Intel): not technically variable-length but has length-masking that achieves similar flexibility.

LLVM has been adding length-agnostic vectorisation since around 2020. The work has produced the `vscale` concept and the `<vscale x N x i32>` vector type, where length is parameterised.

Where to read more: the ARM SVE programmer's guide; LLVM's vector predication proposal documents.

## Halide

What it is: a domain-specific language and compiler for image-processing pipelines. The user writes the *algorithm* (what to compute) separately from the *schedule* (how to compute it: tiling, parallelism, vectorisation, fusion). Halide handles the schedule transformation, freeing the user from low-level optimisation.

Production: Adobe Photoshop, Google Pixel camera pipelines, embedded vision systems.

Where to read more: halide-lang.org; "Halide: Decoupling Algorithms from Schedules for High-Performance Image Processing" (Ragan-Kelley et al., PLDI 2013).

## TVM

What it is: a tensor compiler that takes ML models (TensorFlow, PyTorch, ONNX) and lowers them through a TIR (Tensor IR) to optimised CPU/GPU/accelerator kernels. Uses learning-based schedule auto-tuning.

Production: AWS, ARM, Qualcomm, OctoML's commercial offerings.

Where to read more: tvm.apache.org; "TVM: An Automated End-to-End Optimizing Compiler for Deep Learning" (Chen et al., OSDI 2018).

## MLIR linalg dialect

What it is: a high-level tensor-operation dialect in MLIR. Operations like matrix multiply, convolution, and element-wise apply are expressed structurally; lowering passes turn them into nested loops, GPU kernels, or vendor-specific calls.

Production: TensorFlow's MLIR backend, IREE, parts of OpenXLA.

Where to read more: MLIR linalg documentation; the IREE compiler source.

## CIRCT (hardware synthesis with MLIR)

What it is: an LLVM/MLIR project for hardware design. Provides dialects for HDL (HardWare Description Language) representations and lowering paths from high-level descriptions (like Chisel's FIRRTL) to gate-level or Verilog output.

Production: emerging in academic and industrial hardware design flows.

Where to read more: circt.llvm.org; the CIRCT documentation.

## Polly

What it is: LLVM's polyhedral loop optimiser. Represents loop nests as integer polyhedra, applies transformations (tiling, fusion, interchange) on the polyhedral representation, lowers back to LLVM IR. Optional pass; not on by default.

Production: enabled in some HPC builds; not default in Clang.

Where to read more: polly.llvm.org; the Polly tutorial.

# Differentiable programming and DSL compilation

## Enzyme

What it is: an LLVM-IR-level automatic differentiation framework. Transforms LLVM IR functions into their derivative functions, enabling autodiff for any LLVM-targeting language without source-language support.

Production: research, with growing adoption in scientific computing and ML.

Where to read more: enzyme.mit.edu; "Instead of Rewriting Foreign Code for Machine Learning, Automatically Synthesize Fast Gradients" (Moses and Churavy, NeurIPS 2020).

## Swift autodiff

What it is: Swift had built-in automatic differentiation as a language feature (added in Swift 5.x, in the `_Differentiation` module). Different from Enzyme: Swift autodiff operates at SIL level, exploiting Swift's type system to ensure differentiability properties.

Status: actively maintained but not as visible as it once was; the Swift for TensorFlow project (which drove much of the original work) has wound down.

Where to read more: Swift-evolution proposal SE-0419; the Swift Differentiable Programming Manifesto.

## JAX and XLA HLO

What they are: JAX is a Python library for differentiable numerical computing. Internally, JAX traces Python code to produce XLA HLO (High Level Operations), an IR for tensor computations. XLA compiles HLO to GPU/TPU/CPU code.

Production: Google internally; Anthropic for Claude training; Google DeepMind; many ML research labs.

Where to read more: jax.readthedocs.io; the XLA documentation.

## Halide schedule auto-tuning

What it is: searching the space of possible schedules (orderings of loop transformations) for a Halide algorithm to find the fastest. Uses search heuristics, machine learning, or brute force depending on the variant.

Production: Halide's auto-scheduler; commercial offerings build on this idea.

Where to read more: "Learning to Optimize Halide with Tree Search and Random Programs" (Adams et al., SIGGRAPH 2019).

# Build infrastructure

## Bazel hermetic builds

What it is: Google's open-source build system. Hermetic by construction: every action declares its inputs (files, tools, env vars), and Bazel guarantees the action's output depends only on those inputs. Enables aggressive remote caching.

Production: Google internally, many large open-source projects (TensorFlow, gRPC, Kubernetes parts, Envoy).

Where to read more: bazel.build; the Bazel rules documentation.

## Buck2

What it is: Meta's modern build system, written in Rust. Successor to Buck, with first-class support for incremental rebuilds, remote execution, and per-target caching.

Production: Meta internally; growing open-source adoption.

Where to read more: buck2.build; the Buck2 documentation.

## Nix-based reproducible builds

What it is: Nix (the package manager) and NixOS (the OS) build everything from declarative descriptions, with builds isolated in sandboxes. Reproducible by construction. Build outputs hash-keyed.

Production: NixOS, the Nixpkgs project (>100,000 packages), some companies internally.

Where to read more: nixos.org; "Functional Package Management with Nix" (PhD thesis, Dolstra 2006).

## sccache

What it is: a distributed cache for compiler invocations. Hashes the compile command plus inputs, caches the output (object file), serves cached outputs to other machines.

Production: Mozilla, many large Rust projects.

Where to read more: github.com/mozilla/sccache.

## ABI tools (abidiff, abicompat)

What they are: tools that compare two versions of a shared library to detect ABI breaks. `abidiff` produces a diff; `abicompat` checks that an application built against one library version is compatible with another.

Production: Red Hat (libabigail), Linux distribution maintainers.

Where to read more: sourceware.org/libabigail; the Fedora ABI tracker.

## Symbol versioning

What it is: a feature of ELF dynamic linkers that lets a library expose multiple versions of a symbol with different ABIs. Old binaries link to the old version; new binaries to the new. Critical for ABI-stable libraries like glibc.

Production: glibc, GTK+, many GNU libraries.

Where to read more: the LSB ABI documentation; "How to Write Shared Libraries" (Drepper 2003).

## DWARF debug info generation

What it is: the standard format for embedding source-level debug information in compiled binaries. The compiler emits DWARF tables describing types, variable locations, line-number information, and call frames.

Production: every modern Unix-shaped toolchain. DWARF 5 is the current standard.

Where to read more: dwarfstd.org; "Introduction to the DWARF Debugging Format" by Eager.

## CTF (Compact C Type Format)

What it is: a Sun/Oracle alternative to DWARF, much smaller, used in Solaris and FreeBSD kernels for type-aware debugging without the DWARF size cost. Linux's BPF subsystem also uses it.

Where to read more: the CTF specification at illumos.org; the BPF Type Format (BTF), Linux's adaptation.

# Why we lack all of this

The reasons are not all equivalent.

For verifying compilers: INTERCAL has no formal semantics worth proving. The language is a parody; nobody is building safety-critical systems in it. Verified compilation would be silly here.

For advanced type systems: INTERCAL's type system is four numeric types. There is nothing to extend.

For GPU/HPC: INTERCAL programs do no useful numerical computation. SIMD is irrelevant.

For DSL/autodiff: same.

For build infrastructure: our build is one shell script. Bazel/Nix-scale infrastructure would be absurd.

The lesson: techniques exist for specific problems. A small esoteric-language compiler does not have those problems. Knowing the techniques exist, and what they solve, is the valuable thing.

# What we deliberately exclude

Some techniques are not just absent but actively out of scope. Naming them prevents future confusion.

- **Lazy evaluation runtime**: GHC-specific. INTERCAL is strict.
- **First-class continuations**: Scheme-specific. INTERCAL has no closures or coroutines.
- **First-class macros**: not in the spec.
- **Reflection**: INTERCAL has no introspection.
- **Modules with separate compilation**: INTERCAL is one source file.
- **Generics**: INTERCAL is monomorphic.
- **Type system extensions** (subtyping, variance, GADTs, kind polymorphism): INTERCAL has no type system to extend.
- **AOT to multiple targets simultaneously**: INTERCAL programs target one platform per build.

These are all ways of being a different compiler. The commitment to INTERCAL means accepting them as out of scope.

# What we might add (the realistic roadmap)

Of all the techniques in this chapter, a manageable subset would meaningfully improve our compiler without redefining its scope. In rough priority order:

1. **Real CFG construction** (Phase A in [middle-end-and-optimisation.md](middle-end-and-optimisation.md)). Enables every later optimisation.
2. **SSA via Cytron's algorithm**. Standard form for IR-based optimisations.
3. **SCCP**. The natural extension of our existing constant folding.
4. **Liveness analysis + linear-scan register allocation**. Eliminates stack-slot spills for short-lived values.
5. **Inlining of runtime primitives**. Mentioned in [middle-end-and-optimisation.md](middle-end-and-optimisation.md) as a TODO.
6. **Real loop detection**. Prerequisite for LICM and unrolling.
7. **Csmith-style differential testing**. Improves bug-finding without major architecture changes.

Each of these would be a multi-week project. None requires moving away from "small AOT compiler for an esoteric language". The largest of them (1-4 combined) would roughly double the compiler's size; the project would still be a teaching artifact, not a production toolchain.

# Closing

The list above is what production compilers contain that we do not. It is also approximately the curriculum of a compiler-engineering career. Each technique has a literature, a textbook chapter, a production reference, and a place in the broader puzzle.

A reader who is done with our compiler and wants more depth has an embarrassment of riches: pick a technique, read its papers, find it in a production compiler from Part VII, study how that compiler implements it, then sketch what it would look like in our compiler. The exercise is uniformly enlightening.

The other direction (read this chapter to know what you are missing) is the practical view. When you encounter "GVN" or "tail-call optimisation" or "ARC" in another compiler's documentation, you will have at least seen the term, the rough idea, and the reference to Part VII's example.
