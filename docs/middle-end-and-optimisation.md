# The middle end we don't have

A modern production compiler has three parts: a front end that parses and analyses the source language, a back end that emits the target code, and a middle end in between that operates on a language-neutral intermediate representation. Our compiler has only a front end and a back end. This chapter explains what we forgo by omitting the middle end, what we would gain by adding one, and where the existing codegen leaves obvious performance on the table.

## What is a middle end, concretely

A middle end typically contains:

- An intermediate representation (IR): a data structure that captures the program's semantics independently of any source or target language. Popular IRs include three-address code, static single-assignment form (SSA), and continuation-passing style.
- A set of optimisation passes that read the IR, rewrite it, and produce a new IR with the same observable behaviour but (usually) lower cost.
- Instrumentation and analyses that support the passes: dataflow analysis, alias analysis, control-flow graph construction, dominance trees.

A program that crosses the middle end gets transformed in ways the source language would not naturally express. Dead code is removed. Common subexpressions are factored out. Loops are unrolled. Constants are folded. Register pressure is reduced. What emerges at the back end is faster to execute and usually smaller than what a front end would have emitted directly.

## Why our compiler has none of this

Four reasons, in increasing order of honesty:

1. **INTERCAL programs are small.** The largest program we routinely compile is `syslib.i` at 9065 lines. Compilation time is dominated by the cost of running `cc` on the generated assembly, not by the cost of the codegen. Optimising 9065 lines of INTERCAL would not meaningfully change anybody's experience.
2. **Optimisation is hard to keep correct.** Every optimisation pass is a place where a bug can silently change the program's behaviour. For a compiler we want to self-host and reach a fixpoint, adding optimisation passes is adding surface area without clear benefit.
3. **We have no production users for whom performance matters.** Compiler performance becomes important when somebody is waiting for a build, or when the compiled program is on a hot path. Our compiler is an educational artifact. Neither constraint applies.
4. **Optimising an esoteric language is poorly-rewarded.** The classical optimisations assume that the source language has features (`if`, `for`, call sites with known targets) whose improved handling translates to real speedups. INTERCAL's constructs don't map onto those assumptions cleanly, and the idiomatic performance traps in INTERCAL programs (deep STASH stacks, large TTM arrays) are not what loop unrolling or constant folding address.

So we skip the middle end on principle. The compiler stays at roughly 2100 lines of zsh instead of 5000 lines with a real IR. A handful of local optimisations (constant folding, peephole, dead-flag elimination, see below) live as small passes that operate directly on the parse tree or the emitted assembly, without an IR layer in between.

## Optimisations the compiler already performs

A handful of local optimisations have been added incrementally. Each lives as a small pass over the parse tree or the emitted assembly, without the overhead of an IR.

### Constant folding (implemented)

When both operands of `$` (mingle) or `~` (select), or the child of a unary operator (`&`, `V`, `?`), are compile-time constants, the codegen computes the result directly and emits a single `mov` instead of a call into the runtime. The fold lives inside `codegen_expr` and adds a few dozen lines per operator.

The benefit is small in absolute terms, most INTERCAL programs have few wholly-constant expressions, but the savings on TTM-encoded text output (where every character is a constant manipulated by mingle / select before being stored) are visible.

In compiler-theory terms, our `eval_const` is an instance of the broader *constant propagation* family. The full version of the technique computes, for each program point, the set of variables whose values are statically known, then replaces uses of those variables with the literal values. Constant folding is the leaf-level case, when an expression is built only from literals, evaluate it. The next step up is *sparse conditional constant propagation* (SCCP), which combines folding with reachability analysis to eliminate dead branches whose conditions evaluate to compile-time constants. We do not run SCCP because we do not have control-flow constructs of the right shape; the `%N` probability check is technically reachable from any value of N, and the abstain-flag check is conditional on runtime state.

### Dead-flag elimination (implemented)

Every compiled statement used to begin with a three-instruction sequence that loaded the abstain flag, tested it, and jumped over the body if set. The compiler now analyses the statement list at compile time and computes, for each statement, whether its abstain bit is ever touched by an `ABSTAIN FROM (N)`, an `ABSTAIN FROM gerund-list`, or an initial `NOT` / `N'T` / `DON'T`. Statements that survive this analysis as immutable skip the check entirely. The analysis lives in `compute_flag_checks` and traces through both label-based and gerund-based modifiers.

### Peephole pass (implemented)

A post-codegen pass walks the emitted assembly looking for one specific pattern: an unconditional branch (`b LABEL` on ARM64, `jmp LABEL` on x86-64) immediately followed by the label it targets. The branch is dead, fall-through reaches the label anyway, so the pass drops it. Lives in `peephole_optimize`. The pattern arises naturally from the way the dispatcher used to emit a trampoline label after every statement; eliminating the trampoline plus this peephole keeps the emitted code compact.

More elaborate peephole rules (load-after-store cancellation, redundant `mov`, jump-to-jump short-circuiting) are within reach but not yet implemented.

## What we still leave on the table

### Register allocation for expression trees

When an expression has multiple sub-results, we spill to the stack between them rather than keeping them in registers. For example, `.1 $ '.2 ~ .3'` requires evaluating `.2 ~ .3` first, stacking the result, evaluating `.1`, then restoring the stack and calling `_rt_mingle`. A simple register allocator with even two registers would eliminate the spill in small cases.

The cost: substantial. Register allocation is a well-understood problem but requires tracking liveness across the tree. Probably 300 lines minimum, with a real risk of bugs.

### Inlining the runtime primitives

`_rt_mingle`, `_rt_select`, and the three unary operators are called many times during a program's execution. Inlining their bodies at each call site would eliminate the `bl`/`ret` overhead. For mingle in particular, where the routine is a tight 16-iteration loop, inlining is the difference between ~15 cycles per call and ~40 cycles.

The cost: minor. Each routine is short enough to inline unconditionally. The benefit: depends heavily on how often the program calls them.

### The ignore-flag check on every scalar assignment

Every scalar assignment begins with a three-instruction sequence checking the variable's `_ign` flag. If the variable is never `IGNORE`d in the program, the check is dead code. The same kind of compile-time analysis used for dead-flag elimination on statements would catch this; we have not extended it to ignore flags yet.

## What a real IR would enable

If we ever wanted to take optimisation seriously, the first step would be to introduce an IR. SSA form is the standard choice: every variable is assigned exactly once, and every use names exactly which definition reaches it. In SSA, most classical optimisations become local tree rewrites.

The textbook construction is Cytron, Ferrante, Rosen, Wegman and Zadeck (1991), *Efficiently Computing Static Single Assignment Form and the Control Dependence Graph*. The algorithm has two parts:

1. Compute the control-flow graph and its dominance relation. Then compute the *dominance frontier* of every node, the set of nodes Y where the current node X dominates a predecessor of Y but does not strictly dominate Y. This is where φ-functions belong.
2. Place φ-functions at the dominance frontiers, then rename variables so that every definition has a unique name and every use names the dominating definition.

The result is in worst-case linear time in the size of the program, which is what made SSA practical for production compilers. LLVM, GCC's GIMPLE, and most modern back-ends rely on it.

A plausible roadmap for our compiler, if SSA were ever justified:

- Phase A: introduce a naive three-address IR between parsing and codegen. Each INTERCAL expression becomes a sequence of three-address instructions (`t3 = t1 MINGLE t2`). Codegen lowers the IR to assembly one instruction at a time.
- Phase B: convert the three-address IR to SSA via the Cytron algorithm. INTERCAL has few control-flow joins (NEXT/RESUME pairs and COME FROM back-edges), so the φ count stays low.
- Phase C: implement *sparse conditional constant propagation* (Wegman and Zadeck, 1991) on the SSA form. SCCP combines our existing constant folding with reachability analysis: when a comparison evaluates to a known constant, the branch it controls is propagated as dead, which in turn lets more values be marked constant. Iterate until fixpoint.
- Phase D: dead-code elimination on SSA. Easy in SSA: a definition is dead if its variable name has no live uses.
- Phase E: revisit the codegen to produce native assembly from optimised SSA. This is also where register allocation lives, traditionally via Chaitin-style graph colouring.

Each phase is a significant effort and introduces new test coverage requirements. We should not contemplate this road until stage3 (the pure-INTERCAL compiler) is self-hosted, because the IR would have to be expressed in INTERCAL too. Introducing complexity into a codebase that is not yet self-sufficient is premature.

## Optimisations that INTERCAL itself resists

Several standard optimisations do not apply well to INTERCAL:

- **Function inlining.** INTERCAL has no functions, only NEXT-labelled jumps. Inlining a "function call" means inlining a whole statement that includes the NEXT + a corresponding RESUME somewhere. This is possible but tricky, because RESUMEs can be dynamically reached through abstention changes.
- **Loop unrolling.** INTERCAL loops are implicit: a NEXT back to the top of a body, with a RESUME-like exit. Detecting a loop requires reverse-engineering the control flow. Unrolling is then a rewrite of the entire statement list. Feasible but non-trivial.
- **Escape analysis.** INTERCAL has no notion of allocation other than the once-per-array `_rt_mmap`. There is nothing to escape-analyse.

The optimisations that apply best are the local ones: constant folding, peephole, dead-code elimination on runtime-flag checks. These are the ones already implemented above.

## IR inspection flags: `--emit-cfg` and `--emit-3addr` (implemented)

Following Part VII's chapters on LLVM, GCC, rustc, Go, and Cranelift, the bootstrap compiler now ships two inspection flags that print an IR-shaped view of the parsed program. Both are read-only; codegen still walks the parse tree directly. The flags exist for teaching and for compiler-internals debugging, not as input to a future pipeline.

`--emit-cfg` prints the program's control-flow graph. The pass identifies basic-block leaders (the first statement, any labeled statement, any statement immediately after a `NEXT`, `RESUME`, or `GIVE UP`, any statement that is the source of a `COME FROM` to a labeled statement, and the statement after a labeled statement that has a `COME FROM`). Each block lists its statements and outgoing edges. Edge kinds: `fall-through`, `NEXT to label N` (with target block), `RESUME` (modelled as dynamic, since the target depends on the runtime stack), `COME FROM source` (the implicit edge inserted by `COME FROM`), and `exit` (after `GIVE UP` or running off the end).

For the program

    DO .1 <- #5
    DO (10) NEXT
    PLEASE GIVE UP
    (10) DO .1 <- #3
    PLEASE RESUME #1

the dump is roughly:

    === Control flow graph ===
    blocks:    3
    stmts:     5

    B0: stmts 1..2
      stmt   1: ASSIGN
      stmt   2: NEXT
      -> B2 (NEXT to label 10)

    B1: stmts 3..3
      stmt   3: GIVE_UP  PLEASE
      -> exit

    B2: stmts 4..5  [label 10]
      stmt   4: ASSIGN  (label 10)
      stmt   5: RESUME  PLEASE
      -> dynamic (RESUME pops NEXT stack)

The same shape, blocks plus statements plus edges, is what LLVM IR, MIR (rustc), Maglev (V8), and CLIF (Cranelift) all expose. Reading the dump after experimenting with INTERCAL programs is the smallest way to internalise the CFG concept that every chapter in Part VII depends on.

`--emit-3addr` prints a flat three-address listing of statements. It is a GIMPLE-shaped view (Cooper and Torczon ch. 5; the same shape GCC's GIMPLE has, conceptually). Each statement appears as one line tagged with its operation (`ASSIGN`, `NEXT`, `RESUME`, `COME_FROM`, `GIVE_UP`, etc.) plus its body and any modifiers (PLEASE, NOT, label, COME FROM target).

Both flags route through the same prepass machinery the codegen uses: tokenisation, politeness check, label resolution, COME FROM resolution, syslib detection, dead-flag analysis. The dumps thus reflect the compiler's actual model of the program, not a separate parse.

The flags are deliberately scoped down. They do not print SSA form (we have no SSA), they do not print typed values (INTERCAL's "type system" is the prefix character on each variable), and they do not constitute an IR the rest of the compiler reads. They are inspection only. A future change that introduces a real IR would replace these flags with a richer dump driven from the IR data structure itself.

## The `INTERCAL_SYSLIB=cache` mode (implemented)

When the compiler is invoked with `INTERCAL_SYSLIB=cache` (env var), the syslib's INTERCAL source is compiled once and reused. The flow is:

1. The compiler hashes `src/syslib/syslib.i` with SHA-256.
2. It looks for a pre-compiled artifact at `$XDG_CACHE_HOME/intercal/syslib-<platform>-<hash>.s` (default `$HOME/.cache/intercal/`).
3. If present, the artifact is concatenated with the runtime and the program, same shape as the native path.
4. If absent, `intercalc.sh --emit-syslib` is invoked recursively to produce the artifact, which is then placed in the cache and used.

The artifact is a stand-alone assembly file with all internal `_stmt_*` symbols renamed to `_syslib_stmt_*` (avoiding link-time clash with the user program), BSS variables emitted as `.comm` (mergeable across translation units), and `.global _rt_syslib_NNNN` aliases for every labelled syslib routine.

This collapses pure-syslib compile time from ~30 s per build to ~0 s per build after one warming pass. `tools/build_syslib.sh` warms the cache for the current platform; running it once after cloning eliminates the cold-cache penalty on the first real compile.

Native remains the default. Cache mode is opt-in via env var because the cache directory is per-user state and most users do not need it.

The result is a three-way design: native (fast, hand-written), cache (fast and pure-INTERCAL), `--pure-syslib` (slow but unconditional). All three are byte-equivalent for the arithmetic test cases by construction. The differential test exercises `--pure-syslib`; production builds use native or cache; the regression test in CI exercises cache mode to catch any drift between the cached artifact and a fresh compilation.

## When to add a middle end

Concrete triggers, roughly in order of priority, that would justify the effort:

- Compile time exceeds 30 seconds on any program we regularly compile, with `--pure-syslib` disabled.
- Runtime of a compiled program is within 10% of our ability to tolerate, and measurable improvements are available via known optimisations.
- stage3 becomes self-hosting, at which point we have the opportunity to design an IR in INTERCAL once and maintain it alongside the codegen.
- The language grows a new feature (threading via multiple COME FROMs, maybe) whose efficient implementation is not obvious from a direct-codegen approach.

None of these apply today. The compiler stays frontend-backend-only.

## Exercises

1. Measure the compile time of `tests/test_syslib.i` with and without `--pure-syslib`. What is the ratio? Is constant folding or the syslib-size multiplication the dominant cost?
2. Identify three consecutive statements in the emitted assembly of `tests/test_variables.i` that could be collapsed by a peephole pass. What would the peephole rule look like?
3. The abstain-flag check is three instructions per statement, and `compute_flag_checks` already eliminates it where the analysis can prove the flag is never touched. On a program with 100 statements that does not use ABSTAIN at all, what fraction of statements survive with no flag check? On a program that ABSTAINs from CALCULATING, what fraction survive?
4. Sketch the shape of a three-address IR for INTERCAL. How many instruction opcodes would it need? Compare to LLVM IR's ~60 opcodes.
5. SSA form requires φ-functions at control-flow joins. INTERCAL's control flow is NEXT and COME FROM. How many φ-functions would a realistic INTERCAL program have, roughly, per 100 lines of source?

## Next reading

- [code-generation.md](code-generation.md): the current direct-emission codegen.
- [self-hosting.md](self-hosting.md): why we are not in a position to add a middle end yet.
- [techniques-we-use.md](techniques-we-use.md): every advanced technique present in our compiler, mapped to its production equivalents.
- [techniques-we-lack.md](techniques-we-lack.md): every major technique missing from our compiler, organised by phase, with production references and reading pointers.
- [improvement-proposals.md](improvement-proposals.md): twenty concrete proposals (Tier 1 quick wins, Tier 2 medium, Tier 3 major) for what we could bring back to our compiler from Part VII and Part VIII, with algorithm sketches, effort estimates, dependencies, test strategies, risks, and references per proposal.
- [further-reading.md](further-reading.md): the books to read (Cooper & Torczon, Appel) if you want to implement one anyway.
