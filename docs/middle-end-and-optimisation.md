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

So we skip the middle end on principle. The compiler stays at 1825 lines of zsh instead of 5000 lines with an IR.

## What obvious speedups we leave on the table

If we ever needed to make compiled programs faster, here is what we would attack first. This is roughly an ordered list of low-hanging fruit.

### 1. Constant folding at codegen time

Every `mov w0, #<constant>; bl _rt_mingle; ...` pattern where both operands of the operator are compile-time constants could be replaced with the precomputed result. Our codegen does not check for this; a call to `_rt_mingle` emits the call even when the result could be computed at compile time.

The cost to add this: an optional fold step inside `codegen_expr` that, when both children of a binary node are `NODE_CONST`, computes the result directly in zsh and emits a single `mov` instead of the call. Maybe 50 lines. The benefit: small — most INTERCAL programs have few wholly-constant expressions.

### 2. Peephole optimisation on the emitted assembly

Consecutive instructions that cancel out, such as `str w0, [x1]; ldr w0, [x1]`, appear occasionally in our output because we emit each statement independently and do not track register state across statement boundaries. A peephole pass would eliminate them.

The cost: perhaps 100 lines of an assembly post-processing script. The benefit: measurable on programs with many assignments to the same variable, negligible on anything else.

### 3. Register allocation for expression trees

When an expression has multiple sub-results, we spill to the stack between them rather than keeping them in registers. For example, `.1 $ '.2 ~ .3'` requires evaluating `.2 ~ .3` first, stacking the result, evaluating `.1`, then restoring the stack and calling `_rt_mingle`. A simple register allocator with even two registers would eliminate the spill in small cases.

The cost: substantial. Register allocation is a well-understood problem but requires tracking liveness across the tree. Probably 300 lines minimum, with a real risk of bugs.

### 4. Inlining the runtime primitives

`_rt_mingle`, `_rt_select`, and the three unary operators are called many times during a program's execution. Inlining their bodies at each call site would eliminate the `bl`/`ret` overhead. For mingle in particular, where the routine is a tight 16-iteration loop, inlining is the difference between ~15 cycles per call and ~40 cycles.

The cost: minor. Each routine is short enough to inline unconditionally. The benefit: depends heavily on how often the program calls them.

### 5. The abstain-flag check on every statement

Every compiled statement begins with a three-instruction sequence that loads the abstain flag, tests it, and jumps over the body if set. If we could prove at compile time that a given statement is never abstained (no `ABSTAIN FROM (N)` refers to it, either directly or through gerunds, and it is not marked with `NOT` / `N'T`), we could skip the check entirely.

The cost: a new analysis that walks the statement list and computes for each statement whether its flag is ever touched. Maybe 200 lines. The benefit: a few percent improvement on programs without abstain, zero improvement on programs that use abstain.

### 6. The ignore-flag check on every scalar assignment

Every scalar assignment begins with a similar three-instruction sequence checking the variable's `_ign` flag. If the variable is never `IGNORE`d in the program, the check is dead code.

Similar cost and benefit to the abstain case.

## What a real IR would let us do

If we ever wanted to take optimisation seriously, the first step would be to introduce an IR. SSA form is the standard choice: every variable is assigned exactly once, and uses are explicit. In SSA, most classical optimisations become one-pass tree rewrites.

A plausible roadmap:

- Phase A: introduce a naive three-address IR between parsing and codegen. Each INTERCAL expression becomes a sequence of three-address instructions (`t3 = t1 MINGLE t2`). Codegen lowers the IR to assembly one instruction at a time. Compile speed should be unaffected; program speed will be slightly worse because the IR-to-assembly lowering is less sophisticated than the current direct codegen.
- Phase B: convert the three-address IR to SSA. Introduce φ-functions at control-flow joins (INTERCAL has few of these, so the φ count stays low).
- Phase C: implement constant folding on SSA. Measure the speedup. Iterate.
- Phase D: implement dead-code elimination on SSA.
- Phase E: revisit the codegen, now producing native assembly from optimised SSA.

Each phase is a significant effort, and each introduces new test coverage requirements. We should not contemplate this road until stage3 (the pure-INTERCAL compiler) is self-hosted, because the IR would have to be expressed in INTERCAL too. Introducing complexity into a codebase that is not yet self-sufficient is premature.

## Optimisations that INTERCAL itself resists

Several standard optimisations do not apply well to INTERCAL:

- **Function inlining.** INTERCAL has no functions, only NEXT-labelled jumps. Inlining a "function call" means inlining a whole statement that includes the NEXT + a corresponding RESUME somewhere. This is possible but tricky, because RESUMEs can be dynamically reached through abstention changes.
- **Loop unrolling.** INTERCAL loops are implicit: a NEXT back to the top of a body, with a RESUME-like exit. Detecting a loop requires reverse-engineering the control flow. Unrolling is then a rewrite of the entire statement list. Feasible but non-trivial.
- **Escape analysis.** INTERCAL has no notion of allocation other than the once-per-array `_rt_mmap`. There is nothing to escape-analyse.

The optimisations that apply best are the local ones: constant folding, peephole, dead-code elimination on runtime-flag checks. These are the ones the list above prioritises.

## The `--pure-syslib` thought experiment

One optimisation that would be genuinely useful: when compiling with `--pure-syslib`, the syslib's INTERCAL source is appended to the user program and runs through the whole pipeline. That takes our ~0.1s compile time to ~30s for typical programs. Most of that time is in `tokenize`, `check_politeness`, and `codegen_program` processing 9000 lines of INTERCAL.

A middle-end pass that memoised the compiled syslib (an `.o` file containing the syslib's codegen output, produced once and cached) would reduce the per-compile cost to near the native-syslib level. This is a mechanical change — no semantic analysis required — but it is a significant change to how `intercalc.sh` structures its output pipeline.

We have not done it. The `--pure-syslib` flag is opt-in, only used by the differential test, and the test runs fast enough without the optimisation.

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
3. The abstain-flag check is three instructions per statement. On a program with 100 statements, how many instructions would we save by eliminating the check where it is provably dead? Is that meaningful on modern hardware, where branch prediction handles the dead case well?
4. Sketch the shape of a three-address IR for INTERCAL. How many instruction opcodes would it need? Compare to LLVM IR's ~60 opcodes.
5. SSA form requires φ-functions at control-flow joins. INTERCAL's control flow is NEXT and COME FROM. How many φ-functions would a realistic INTERCAL program have, roughly, per 100 lines of source?

## Next reading

- [code-generation.md](code-generation.md) — the current direct-emission codegen.
- [self-hosting.md](self-hosting.md) — why we are not in a position to add a middle end yet.
- [further-reading.md](further-reading.md) — the books to read (Cooper & Torczon, Appel) if you want to implement one anyway.
