# GHC (Haskell), in shape

The Glasgow Haskell Compiler is the reference implementation of Haskell. Source at <https://gitlab.haskell.org/ghc/ghc>. It is the compiler in this Part with the most distinctive shape: four intermediate representations, each with formal semantics, and a runtime that implements lazy evaluation rather than eager. None of the other compilers here have either property at the same depth.

GHC matters in a book about compilers because its IRs are designed objects in a way most production IRs are not. Core is a tiny lambda-calculus, perhaps ten constructors, with a published formal semantics. STG is a simpler abstract machine model for lazy evaluation. Cmm is portable assembly with garbage-collection cooperation built in. Each was the subject of one or more papers by Simon Peyton Jones and his collaborators. Reading the GHC source means reading those papers turned into engineering, which is rare in production compilers.

The runtime story is just as distinctive. Lazy evaluation forces a particular runtime architecture: thunks, sharing, weak head normal forms, a stack discipline different from eager-evaluation languages. The Haskell runtime ("the RTS") has accumulated decades of work on this. None of the eager-language runtimes in this Part has the equivalent.

For a reader, GHC is the compiler that pushes the IR concept to its strongest form. If the LLVM chapter teaches you that an IR can be a portable assembly, the GHC chapter teaches you that an IR can also be a typed lambda calculus with a published semantics, lowered through several stages each of which preserves type and meaning.

## The pipeline

Haskell source goes through more lowering steps than any other compiler in this Part:

    source                              Foo.hs
      → tokens                         compiler/GHC/Parser/Lexer.x
      → HsSyn (parsed)                 compiler/GHC/Hs (phase GhcPs)
      → HsSyn (renamed)                compiler/GHC/Rename, phase GhcRn
      → HsSyn (typechecked)            compiler/GHC/Tc, phase GhcTc
      → Core                           compiler/GHC/HsToCore (the desugarer)
      → Core (after Simplifier)        compiler/GHC/Core/Opt
      → STG                            compiler/GHC/CoreToStg
      → Cmm                             compiler/GHC/StgToCmm
      → assembly or LLVM IR            compiler/GHC/CmmToAsm or compiler/GHC/Driver/Backend/Llvm
      → object via system as           compiler/GHC/Linker
      → executable                      via system linker

Six lowering steps producing four intermediate representations. The shape: front-end, several IR layers, back-end.

The frontend (HsSyn through Core) is what is unusual. HsSyn is the AST and is parametrised by a "phase" type so the same data structure represents the program at different stages of frontend processing. Core is the typed lambda calculus. STG and Cmm are progressively lower abstractions that preserve enough semantic information for the runtime to do its job.

## HsSyn: the phased AST

HsSyn (`compiler/GHC/Hs/`) is GHC's source AST. The signature data type is called `HsExpr`, parameterised by a `pass` parameter:

    data HsExpr (p :: Pass) = HsVar    (XVar p)    (LIdP p)
                            | HsLit    (XLit p)    Lit
                            | HsApp    (XApp p)    (LHsExpr p) (LHsExpr p)
                            | ...

The `XVar p`, `XLit p`, `XApp p` fields are extension points. For each constructor, the type-family `XVar` pulls in a different type depending on whether `p` is `GhcPs` (parsed), `GhcRn` (renamed), or `GhcTc` (typechecked).

This is the "Trees that Grow" pattern (Najd and Peyton Jones, 2017). The same data structure changes shape gradually as the compilation phase progresses. A typed AST has type info at each node; a renamed AST has resolved names; a parsed AST has neither. The same recursive walks work on all three forms because the constructor names are stable; only the extension fields differ.

The pattern is GHC-specific in production compilers (rustc has separate AST/HIR/THIR types for each stage; Swift has one richly-typed AST evolved in place). Haskell as a language is good enough at type-level programming to make the Trees-that-Grow pattern feasible; in less type-rich languages it is not natural.

## Renaming: scope and qualification

The renamer (`compiler/GHC/Rename/`) resolves names. Every identifier in the source has potentially many bindings (defined here, imported from there, qualified differently); the renamer picks the right one, or reports an error.

Why renaming is its own phase rather than merged with type checking: because Haskell has open imports (`import Data.List`, brings everything in), qualified imports, hiding clauses, name shadowing rules, and several layers of namespaces (term-level vs type-level vs class-level). A separate phase makes the rules tractable.

After renaming, the AST is `GhcRn`. Each name is a unique identifier ("name") rather than a textual binding. Subsequent phases never need to worry about scope.

## Type checking: OutsideIn(X) and constraint-based inference

The type checker (`compiler/GHC/Tc/`) is the compiler's most sophisticated frontend phase. It implements OutsideIn(X), a constraint-based inference algorithm parameterised over a theory `X` of type-equality reasoning.

How it works in outline:

1. Walk the AST, generating constraints (equalities, class memberships, subsumptions).
2. Solve the constraints, simplifying and resolving until a fixpoint.
3. For each `let`-bound function, generalise: any free type variable not appearing in the surrounding environment becomes universally quantified.
4. The "X" is the theory plug-in: GADT equalities, type families (functions at type level), kind polymorphism, etc.

The data structures are intricate. `Type`, `Kind`, `TyCon` (type constructors), `TyVar` (type variables), `Coercion` (evidence of type equality), `Class`, `DFun` (dictionary function for an instance). Each is shared with Core, because Core needs to represent the same types after type checking.

Type-class resolution: `class Eq a where (==) :: a -> a -> Bool` is the user-level definition. The type checker turns this into a record type plus a function dispatching through that record. An instance like `instance Eq Int where ...` becomes a value of that record type. A use of `==` at type `Int` finds the right instance and elaborates the call to pass the dictionary explicitly. By the time we reach Core, type classes are gone; only dictionary passing remains.

GADTs and type families: these are where the OutsideIn algorithm earns its keep. A pattern match on a GADT constructor refines the local type; the constraint solver tracks this. Type families are functions at type level whose reductions are themselves constraints. The X-theory plug-in handles these uniformly with ordinary equalities.

For a reader who wants to learn type-system implementation, GHC's type checker is the deepest treatment available in production. It is also dense; the Trees-that-Grow encoding plus the constraint solver plus the rich data structures combine to a learning curve. The corresponding chapter in the GHC documentation is the right preparation.

## Core: System FC, the centre of the compiler

Once type checking is done, the desugarer (`compiler/GHC/HsToCore/`) translates HsSyn to Core. Core is the most important IR in GHC. It is a typed lambda calculus, called System FC ("System F with Coercions"), a variant of Girard-Reynolds System F augmented with type-equality coercions to support GADTs and type families.

Core is small. The data type for expressions is roughly:

    data Expr b = Var Id
                | Lit Literal
                | App (Expr b) (Arg b)
                | Lam b (Expr b)
                | Let (Bind b) (Expr b)
                | Case (Expr b) b Type [Alt b]
                | Cast (Expr b) Coercion
                | Tick (Tickish Id) (Expr b)
                | Type Type
                | Coercion Coercion

Ten constructors. That is the entire core language. Everything Haskell expresses gets desugared into trees built from these ten.

What makes this powerful:

- **Typed**: every Core expression has a type. After every pass, you can run `Core Lint` to verify that types remain consistent.
- **Total** (or as close as a non-total language can be): the language itself is a calculus with reduction rules. Optimisations are reductions plus rewrites that preserve meaning.
- **Sufficient**: every Haskell program desugars to Core. There is nothing in the source language that requires a different IR.
- **Coercion-bearing**: GADT equalities and type-family applications generate `Cast` expressions with explicit coercion evidence. The runtime never inspects coercions; they are erased before code generation. But the type checker uses them to encode the proof that the equality holds.

The simplifier (`compiler/GHC/Core/Opt/Simplify/`) is the optimisation engine. It performs:

- **Inlining**: based on the function's "unfolding" (Core source) and a set of heuristics. Aggressive: GHC inlines much more than most compilers.
- **Beta reduction**: `(\x -> e1) e2` becomes `e1[x := e2]`.
- **Case-of-case**: `case (case e of ...) of ...` becomes `case e of ...` after rewriting alternatives. Often unblocks further simplifications.
- **Let-floating**: moves `let`-bindings outside of functions or inwards as needed for sharing or evaluation order.
- **Eta-expansion**: `f` becomes `\x -> f x` when an argument shape is needed.
- **Constant folding** for primitive operations.
- **RULES application**: user-declared rewrite rules from `{-# RULES "name" forall x. f x = g x #-}` are applied during simplification.

All of these run within a single fixpoint loop: the simplifier does not have separate passes for each optimisation; it does one walk that applies them all and iterates until stable. In production GHC, the simplifier runs multiple times in the pipeline, between other passes.

The relevance for somebody learning compilers: Core plus its simplifier is the cleanest production example of optimising a typed language. Each pass is a meaning-preserving rewrite. The IR is small enough to understand fully; the optimiser is sophisticated enough to teach modern techniques.

## Strictness analysis and worker/wrapper

Two GHC-specific optimisations deserve their own attention because they are central to making Haskell fast.

**Strictness analysis** (`compiler/GHC/Core/Opt/DmdAnal.hs`): Haskell is lazy by default, but many functions are strict in some of their arguments (always evaluate them). The compiler analyses each function to determine which arguments are demanded and how (head-normal-form, fully evaluated, etc.). The result is a "demand signature" attached to each function.

The analysis is dataflow over Core, computing for each variable the "demand" that the function places on it. The lattice is rich (lazy, used once, used once strictly, strict and unboxed, etc.). The result enables the next optimisation.

**Worker/wrapper transformation**: with strictness information in hand, the compiler splits functions into two parts:

- The **worker** takes unboxed (raw) values and does the actual computation.
- The **wrapper** takes boxed (heap-allocated) values, unboxes them where appropriate, calls the worker, and reboxes the result.

The wrapper is small and gets inlined everywhere; the worker is the real work. After enough simplification, the boxes/unboxes around the worker often cancel out with operations elsewhere, leaving direct unboxed calls. This is the difference between "Haskell allocates everything" and "Haskell allocates only when it has to".

For a reader, strictness analysis is the cleanest example of a non-trivial dataflow analysis on a typed lambda calculus. It is also the optimisation that makes lazy evaluation practical in a production language; without it, the constant factor would be unfavourable.

## STG: the abstract machine for laziness

After Core simplification ends, Core is translated to STG (Spineless Tagless G-machine, Peyton Jones 1992). STG is closer to the runtime than Core: it makes evaluation explicit, allocations explicit, and the abstract machine model concrete.

The STG syntax is even smaller than Core. From `compiler/GHC/Stg/Syntax.hs`:

    data StgExpr = StgApp Id [StgArg]
                 | StgLit Literal
                 | StgConApp DataCon [StgArg] [Type]
                 | StgOpApp StgOp [StgArg] Type
                 | StgCase StgExpr ...
                 | StgLet (StgBinding) StgExpr
                 | StgLetNoEscape (StgBinding) StgExpr
                 | StgTick (Tickish Id) StgExpr

The names match Core but the semantics are different. `StgApp f args` is "apply function f to args"; in Core `App` was "form a tree"; in STG it is "perform an application". `StgLet` introduces a thunk on the heap; the let-bound value is allocated as a closure with code pointer plus free variables.

The "spineless" part: there is no AST spine of nested applications; applications are saturated where possible (all arguments at once), so allocations are minimised. The "tagless" part: closures in the heap don't carry a tag distinguishing thunks from values from constructors; the code pointer at the start of the closure dictates how to interpret it, and the interpreter (or generated code) jumps to that pointer to evaluate.

This design decision is the centre of GHC's evaluation model. A thunk and an evaluated value have the same shape in the heap; evaluation just means jumping to the code pointer, which (for a thunk) computes the value and updates the code pointer to be a "return this value" stub, and (for an already-evaluated value) jumps straight to the consumer.

The architectural simplicity buys a lot: no need for tags, no need for evaluators that switch on tag, sharing happens automatically through the in-place update.

For a reader, STG is the most distinctive piece of GHC's design and the hardest to compare to anything else. The Spineless Tagless G-machine paper from 1992 is required reading.

## Cmm: portable assembly with cooperative GC

After STG, GHC translates to Cmm (`compiler/GHC/Cmm/`). Cmm is GHC's portable assembly. The lineage: it descends from C-- (Peyton Jones, Ramsey, and Reig, 1999), a portable assembly designed to support garbage-collected languages.

What Cmm has that LLVM IR does not:

- **Calling-convention awareness** for the language's GC: every Cmm procedure declares which of its arguments and live variables are GC-managed pointers. The runtime can scan these without disassembling the code.
- **Stack management primitives**: explicit stack-frame layout, stack pointer manipulation, stack overflow checks. The Haskell runtime is cooperative with the compiler about stack use.
- **First-class globals**: globally-shared registers like `Sp` (stack pointer), `Hp` (heap pointer) are syntactically distinguished.
- **Multiple return**: Cmm procedures can return multiple values directly to multiple destinations, avoiding allocation.

Cmm passes (in `compiler/GHC/Cmm/Opt/`):
- Stack layout (allocate slots for live variables across calls)
- Sinking (move computations to where they are used)
- Constant folding
- Common-block elimination
- Dead-code elimination

These passes are conventional but operate on a representation that knows about garbage collection, which conventional optimisers do not. Reading Cmm passes is a way to see what optimisation looks like when GC cooperation is a first-class concern.

## NCG and the LLVM exit

After Cmm passes, GHC has two backends:

- **NCG (Native Code Generator)**: compiler/GHC/CmmToAsm/. GHC's own backend, hand-written per architecture (x86-64, AArch64, PowerPC, RISC-V are supported in various states). Each backend is small relative to LLVM: roughly the order of ten thousand lines per architecture. The default for most platforms.
- **LLVM**: compiler/GHC/Driver/Backend/. Translate Cmm to LLVM IR, hand off to LLVM. Produces faster code in some cases (~5-15% improvement on numeric code), slower compile times.

The choice is per-build: `ghc -fllvm` selects LLVM, default is NCG. The NCG is small, fast to run, and produces reasonable code. LLVM is the production choice for tightly-optimised numeric Haskell.

Why does NCG exist alongside an LLVM option? Compile speed (NCG is much faster), distribution simplicity (no LLVM dependency), and platform support (NCG works on platforms where bringing up an LLVM target is its own project).

## The runtime (RTS)

`rts/` is GHC's runtime system, on the order of a hundred thousand lines of C plus assembly. It is the largest non-Haskell part of GHC.

What it provides:

- **Garbage collector**: generational, copying for the young generation, mark-compact for the older. An optional concurrent variant exists for low-pause applications.
- **Thread scheduler**: Haskell threads are green threads (M:N over OS threads). The RTS schedules them, handling context switches in user space.
- **Sparks**: speculative parallel evaluation. `par a b` creates a "spark" for `a`, allowing the runtime to evaluate it on another thread if available; otherwise `a` is just lazy as usual.
- **STM (Software Transactional Memory)**: transactional memory primitives, with the runtime managing log-based concurrency.
- **Bytecode interpreter**: GHCi (the interactive interpreter) executes bytecode directly; the bytecode interpreter is part of the RTS.
- **FFI**: bridges to C libraries, both calling C from Haskell and being called from C.

The GC deserves a footnote. Generational copying with a minor GC tuned for very fast allocation is the right design for a language that allocates as much as Haskell does. Every thunk is an allocation. Every list cons is an allocation. Every closure is an allocation. The minor GC must keep up with this. Most Haskell programs spend more time in the GC than in any non-trivial part of the program; tuning the GC is a routine performance activity.

For a reader, the RTS is the part of GHC most worth studying for understanding what a runtime has to provide for a high-level language. The contrast with Go's runtime (which has goroutines and a GC but no thunks) and with Rust's runtime (which has neither, beyond the stack and OS facilities) is sharp.

## Concurrent (non-moving) garbage collector

GHC 8.10 (2020) added an optional concurrent mark-and-sweep collector for the old generation. By 2026 it is the standard low-latency option for Haskell production deployments. Real-world adopters (Mercury, Pusher, the IOG team) report sub-millisecond pauses on large heaps at the cost of slightly higher CPU on a spare core. There is no public 2025-2026 set of benchmarks superseding Ben Gamari's original numbers; ongoing work in 2025 has been around finalisers and weak references rather than a redesign.

A common production gotcha: `-with-rtsopts=-N` (use all cores) is poor as a library default because it grabs every core whether the consuming program wants that or not. Stack tracks an open issue (commercialhaskell/stack#680) about this.

## JavaScript backend

GHC has a JavaScript backend, still labelled "technology preview" in the GHC 9.14 user's guide and not shipped in bindists. Users must build a cross-compiler. The 2025 discussion focused on output size; compiled bundles are large compared to GHCJS (the older, separate Haskell-to-JS compiler).

For somebody studying compilers, the GHC JS backend is interesting because it is a non-LLVM, non-NCG path: GHC's pipeline goes Cmm → JavaScript directly, treating JS as the target machine. Reading `compiler/GHC/StgToJS/` shows what that lowering looks like.

## Plugin ecosystem

GHC's plugin system supports plugins at several levels: parser plugins, renamer plugins, typechecker plugins, Core plugins, Cmm plugins. The most consequential plugin in production is **Liquid Haskell**, which adds refinement types to Haskell. Tweag's March 2025 release was a structural milestone: Liquid Haskell now consumes GHC's post-typecheck AST directly instead of re-parsing and re-typechecking the module. A GSoC 2025 project added qualified-import and alias resolution.

## Repo layout

    compiler/
      GHC/
        Hs/              Source AST (HsSyn) with phased extension fields
        Parser/          Lexer (Alex) and parser (Happy)
        Rename/          Name resolution
        Tc/              Type checker (OutsideIn algorithm, constraint solver)
        HsToCore/        Desugaring HsSyn → Core
        Core/            Core IR + simplifier
          Opt/           Optimisations (simplifier, demand analysis, etc.)
        CoreToStg/       Core → STG
        Stg/             STG IR
        StgToCmm/        STG → Cmm
        Cmm/             Cmm IR + passes
        CmmToAsm/        NCG (Native Code Generator)
        Driver/          Top-level compiler driver, backend selection
    rts/                 Runtime system in C + assembly
    libraries/           Standard library packages (base, ghc-prim, etc.)
    testsuite/           Test programs
    docs/users_guide/    User-facing documentation
    docs/comm/           "Commentary": developer documentation

The `docs/comm/` (commentary) directory is the developer documentation, sometimes outdated, but the only narrative explanation of many internals.

## Comparison with other compilers

| Aspect | GHC | rustc | OCaml |
|--------|-----|-------|-------|
| IRs | HsSyn, Core, STG, Cmm | HIR, THIR, MIR, LLVM IR | Parsetree, Typedtree, Lambda, Cmm, Mach |
| Type system | HM + System F + classes + GADTs + families | HM-derived + traits + lifetimes | HM + functors + GADTs |
| Evaluation | Lazy (call-by-need) | Eager | Eager |
| Backend | NCG (default) or LLVM | LLVM | Self-hosted per-arch |
| Runtime | RTS with GC, scheduler, STM, sparks | Minimal (libstd, no GC) | C runtime with GC, exceptions |
| Self-hosted | Yes | Yes | Yes |
| Distinguishing piece | Lazy evaluation runtime | Borrow checker | Functor module system |

GHC stands out on every row. Lazy evaluation alone changes everything: how arguments are passed, what allocation patterns look like, what optimisations matter, what the runtime has to do.

## Reading order

A practical path:

1. Read the [GHC user guide](https://downloads.haskell.org/ghc/latest/docs/users_guide/) for context on the language and tooling.
2. Read the [GHC Commentary](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary), the developer documentation.
3. Browse `compiler/GHC/Hs/Expr.hs` to see HsSyn.
4. Read `compiler/GHC/Core/Syntax.hs` (or the equivalent) for Core. Ten constructors, easy to absorb.
5. Read "Implementing Lazy Functional Languages on Stock Hardware: The Spineless Tagless G-Machine" (Peyton Jones 1992) before diving into STG code.
6. Read `compiler/GHC/Cmm/Syntax.hs` for Cmm.
7. Read `compiler/GHC/Core/Opt/Simplify/Iteration.hs` to see the simplifier.
8. For runtime, `rts/sm/Storage.c` is the heap manager, `rts/sm/GC.c` is the major collector.

## How to contribute

GHC uses GitLab merge requests at <https://gitlab.haskell.org/ghc/ghc>. The community is active, with weekly devops calls, open mailing lists, and a strong tradition of academic-paper-followed-by-implementation. The contribution guide is in `MAINTAINERS.md`.

Beginner-friendly categories:

- Error message improvements: GHC has been investing in user-facing diagnostics; small additions are welcome.
- Library additions to `base` (the standard library) following the Core Libraries Committee's process.
- Documentation in `docs/`.
- Simplifier or demand-analysis improvements: each one is a small PR, with rich opportunities.

Build:

    git clone https://gitlab.haskell.org/ghc/ghc
    cd ghc
    ./boot
    ./configure
    hadrian/build

Build time is significant (~30 minutes from scratch). Bootstrapping requires an older GHC, downloadable via `ghcup`. Hadrian has been the only supported build system since GHC 9.6 (2023); the legacy Make-based build was removed.

## Where to go next

- "The Implementation of Functional Programming Languages" by Simon Peyton Jones (1987), free PDF at <https://www.microsoft.com/en-us/research/publication/the-implementation-of-functional-programming-languages/>. Older but still relevant on lazy evaluation and graph reduction.
- "Implementing Lazy Functional Languages on Stock Hardware: The Spineless Tagless G-Machine" (Peyton Jones 1992), the canonical STG reference.
- "Modern Compiler Implementation in ML" by Andrew Appel; the ML-flavoured cousin to the Haskell story.
- The GHC Commentary at <https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary>.
- "OutsideIn(X): Modular type inference with local assumptions" (Vytiniotis et al. 2011) for the type-checker algorithm.
- [ocaml-overview.md](ocaml-overview.md) for the other major ML-family compiler.
- [rustc-overview.md](rustc-overview.md) for the type-system descendant that took different decisions.
