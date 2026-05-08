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
