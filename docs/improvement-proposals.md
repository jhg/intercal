# Improvement proposals: applying Part VII and Part VIII

This is the synthesis chapter: every concrete improvement we could bring back to the INTERCAL compiler from the production-compiler chapters of Part VII and the technique catalogues of Part VIII.

The chapter is organised in three tiers by effort. Tier 1 is "single-session" work, Tier 2 is "one to several weeks", Tier 3 is "multi-month, architecturally significant". The closing section recommends a sequence and names what is deliberately out of scope.

For each proposal: what it is, where the lesson comes from, where we would implement it, the algorithm or design sketch, the effort estimate, the test strategy under our existing TDD contract, the risks, and references for further reading.

These are proposals, not plans. The user picks which to act on.

# Tier 1: quick wins

Low effort (one focused session each), low risk, immediately useful.

## 1. `--emit-tokens` flag

**What it is.** A read-only inspection flag that prints the tokenised statement table to stdout, completing the trilogy with the existing `--emit-3addr` and `--emit-cfg` flags. Output is one line per statement listing index, label, type, polite flag, negated flag, and a truncated body.

**Lesson source.** Every compiler in Part VII exposes per-phase intermediate output. rustc's `-Zdump-mir` family, Go's `-d=ssa/<phase>`, GHC's `-ddump-parsed-ast`/`-ddump-rn-ast`/`-ddump-tc-ast`, V8's `--print-bytecode`, OCaml's `-dparsetree`. The pattern is universal: a healthy compiler exposes its model of the program at every layer.

**Where in our codebase.** `src/bootstrap/intercalc.sh`: add a new `emit_tokens()` function next to `emit_cfg` and `emit_3addr`, plus the `--emit-tokens` argument parsing and dispatch in `main()`. Add a corresponding test in `tests/test_emit_tokens.sh`.

**Algorithm.** Walk `stmt_count` once. For each statement, format and print:

    stmt N: [(label X)] TYPE [PLEASE] [NOT] body...

Use the existing `stmt_label[]`, `stmt_type[]`, `stmt_polite[]`, `stmt_negated[]`, `stmt_body[]` arrays.

**Effort.** ~30 lines zsh + ~50 lines for the test script. One session.

**Dependencies.** None; every needed datum is computed by `tokenize()` and the existing analysis passes.

**Test strategy.** TDD: write `tests/test_emit_tokens.sh` first asserting the format on three small programs (linear, COME FROM, syslib). Verify the script fails (no implementation yet), implement, verify pass. Add to `.githooks/pre-push` and `.github/workflows/ci.yml`.

**Risks.** Low. Read-only, does not affect codegen. Worst case is bad formatting that gets fixed.

**Educational value.** Teaches that tokenisation is its own inspectable layer, distinct from parsing. Surfaces the politeness/negation classification decisions for inspection.

**References.**
- rustc's `-Zdump-mir`, Go's `-d=ssa/<phase>=<level>`, GHC `-ddump-parsed-ast`.
- The pattern is described in [techniques-we-use.md](techniques-we-use.md) under "IR inspection flags".

---

## 2. `--time-report` flag

**What it is.** Per-phase timing breakdown at compile time. Reports milliseconds spent in each pass: read_source, tokenize, check_politeness, check_labels, resolve_come_from, detect_syslib, compute_flag_checks, codegen_program, peephole_optimize, plus the final cc invocation.

**Lesson source.** Zig's `--time-report` is the closest model. rustc has `-Zself-profile` plus `summarize`, GCC has `-ftime-report`, GHC has `-v3` for phase-by-phase wall-clock. The motivation is the same everywhere: when compile time regresses, the only way to localise the cause is per-phase timing.

**Where in our codebase.** `src/bootstrap/intercalc.sh`: wrap each top-level phase call in `main()` with start/end time captures. Pull the data from `$EPOCHREALTIME` (zsh built-in providing sub-second precision).

**Algorithm.**

    typeset -A phase_times
    typeset -F start
    
    time_phase() {
      local name=$1; shift
      start=$EPOCHREALTIME
      "$@"
      phase_times[$name]=$(( EPOCHREALTIME - start ))
    }
    
    # In main():
    time_phase tokenize tokenize
    time_phase politeness check_politeness
    time_phase labels check_labels
    # ... etc
    
    if (( TIME_REPORT )); then
      print -u2 "=== Compile-time breakdown ==="
      for name in "${(@k)phase_times}"; do
        printf "  %-20s %.3f s\n" "$name" "${phase_times[$name]}" >&2
      done
    fi

**Effort.** ~60 lines zsh (phase wrappers + reporting), plus a test that runs `--time-report` on a small program and asserts the format and that the times sum approximately to the total.

**Dependencies.** None. zsh's `$EPOCHREALTIME` is available since 5.0.0 (we already require zsh).

**Test strategy.** TDD: `tests/test_time_report.sh` checks that the output contains every expected phase name, that the format `phase_name N.NNN s` is consistent, and that no individual phase takes more than the total wall-clock.

**Risks.** Low. Output goes to stderr to avoid interfering with `--emit-*` flags that go to stdout. Edge case: `cc` invocation timing must be inside the wrapper too if the user wants total accountability.

**Educational value.** Makes the pipeline tangible. A reader who runs `--time-report` on `tests/test_syslib.i` sees concrete numbers for which phases dominate (codegen, almost certainly).

**References.**
- Zig's `--time-report` documentation.
- rustc-dev-guide chapter on profiling (`-Zself-profile` documentation).
- Linux's `time` command, conceptually parallel.

---

## 3. `--opt-bisect-limit=N` flag

**What it is.** A flag that limits how many optimisation transformations the compiler is allowed to apply. Setting `--opt-bisect-limit=5` runs only the first five optimisations that *would have* fired, then disables the rest. By binary-searching N, a developer finds the optimisation responsible for a miscompile.

**Lesson source.** LLVM's `-mllvm -opt-bisect-limit=N` is the canonical implementation. The mechanism is described in detail in `llvm/lib/Transforms/Utils/BugDriver.cpp` and the `OptBisect` class.

**Where in our codebase.** `src/bootstrap/intercalc.sh`: add a global counter `OPT_BISECT_COUNT` that every optional transformation increments and consults. The transformations are: each rule in `peephole_optimize`, each fold in `eval_const`, each statement-level dead-flag elimination in `compute_flag_checks`, each upcoming inline of a runtime primitive (proposal 5).

**Algorithm.**

    # Globals
    typeset -i OPT_BISECT_LIMIT=-1   # -1 = no limit
    typeset -i OPT_BISECT_COUNT=0
    
    opt_bisect_check() {
      local name=$1
      OPT_BISECT_COUNT=$((OPT_BISECT_COUNT + 1))
      if (( OPT_BISECT_LIMIT >= 0 && OPT_BISECT_COUNT > OPT_BISECT_LIMIT )); then
        (( OPT_BISECT_VERBOSE )) && print -u2 "BISECT: SKIP #$OPT_BISECT_COUNT $name"
        return 1
      fi
      (( OPT_BISECT_VERBOSE )) && print -u2 "BISECT: APPLY #$OPT_BISECT_COUNT $name"
      return 0
    }
    
    # In each transformation:
    if opt_bisect_check "eval_const_unary_and"; then
      # apply transformation
    fi

**Effort.** ~100 lines: the helper plus per-call updates across `eval_const`, `peephole_optimize`, and `compute_flag_checks`.

**Dependencies.** None.

**Test strategy.** Deliberately add a buggy "fold rule" behind a feature flag, build a test program where it fires, assert that `--opt-bisect-limit=0` produces correct output and the buggy rule's fold count identifies it. Then remove the deliberate bug.

**Risks.** Care needed that the bisect is *deterministic*: same input + same limit must always make the same decision. Use a stable enumeration order.

**Educational value.** Teaches the bisection-as-debugging technique that is fundamental to compiler engineering. Most contributors learn it the first time a miscompile appears.

**References.**
- LLVM's `-mllvm -opt-bisect-limit=N` documentation.
- "Debugging LLVM" page at <https://llvm.org/docs/DebuggingLLVM.html>.
- Cooper and Torczon's chapter on testing optimisations.

---

## 4. Expanded peephole rules

**What it is.** Extend `peephole_optimize` from its current single rule (drop unconditional branches immediately followed by their target label) to cover several more patterns that arise mechanically in our generated assembly. The rules are local, syntactic, low-risk.

**Lesson source.** Every backend in Part VII has dozens to hundreds of peephole rules. LLVM's `lib/CodeGen/PeepholeOptimizer.cpp`, GCC's `define_peephole2` patterns in machine descriptions, Cranelift's late-stage cleanups.

**Where in our codebase.** `src/bootstrap/intercalc.sh`: extend `peephole_optimize`. Each rule is a sed-substitution-or-loop on the `asm` variable. Per the `--opt-bisect-limit` proposal, each rule should call `opt_bisect_check` before firing.

**Specific rules to add.**

a) **Load-after-store cancellation.** A `str x0, [SP, #N]` followed immediately by `ldr x1, [SP, #N]` can become `str x0, [SP, #N]; mov x1, x0`. The load is replaced by a register copy. Net win: removes a memory access, possibly enables further moves to be optimised.

b) **Redundant `mov` collapse.** `mov x0, x0` (identity move) is dead. Drop it.

c) **Branch-to-branch (jmp-to-jmp).** A `b LABEL1` where `LABEL1`'s only instruction is `b LABEL2` can become `b LABEL2`. (We currently handle the simpler "branch immediately followed by its target" case; this generalises.)

d) **Dead store elimination.** `str x0, [SP, #N]` followed by another `str x1, [SP, #N]` with no intervening load: drop the first.

e) **mov + load coalesce on x86_64.** `mov rax, rdi; mov rcx, rax` where `rax` is not subsequently used: `mov rcx, rdi`.

**Effort.** ~150-300 lines for five rules plus per-rule tests.

**Dependencies.** Proposal 3 (opt-bisect-limit) is helpful for debugging but not strictly required.

**Test strategy.** Per rule: write a small INTERCAL program that produces assembly triggering the pattern (use `INTERCAL_ASM_ONLY=1` to inspect). Verify the pre-rule assembly contains the pattern; verify the post-rule assembly does not. Verify the binary still produces correct output.

**Risks.** Medium. Peephole rules that look local can change semantics if context is wrong (e.g., load-after-store can be wrong if the load value is used to detect aliasing across calls). Each rule needs careful predicate.

**Educational value.** Concrete examples of how production compilers accumulate small optimisations into measurable wins. The growth pattern (one rule, then five, then dozens) mirrors LLVM and GCC.

**References.**
- LLVM's `lib/CodeGen/PeepholeOptimizer.cpp`.
- GCC's `define_peephole2` documentation in the gccint manual.
- Cooper and Torczon's chapter on local optimisation.

---

## 5. Inline runtime primitives

**What it is.** For short, frequently-called runtime helpers, replace the `bl _rt_*` call site with the body of the helper inline. Targets:

- `_rt_syslib_1020` (in-place increment): currently `bl _rt_syslib_1020` plus stack save/restore for `.1`, `.3`, `.4`. The actual increment is two instructions. Inlining removes the call overhead and the stack dance.
- Unary `&` (AND of adjacent bits): a tight loop in the runtime; for short statements this can become an unrolled inline sequence.
- Unary `V` (OR of adjacent bits): same.
- Unary `?` (XOR of adjacent bits): same.

Already mentioned as a TODO in [middle-end-and-optimisation.md](middle-end-and-optimisation.md).

**Lesson source.** Inlining is fundamental to every production optimiser. LLVM's `Inliner` class with cost analysis. rustc's `rustc_mir_transform/inline.rs`. Go's unified inliner with budget-based decisions. GHC inlines aggressively, including across module boundaries.

**Where in our codebase.** `src/bootstrap/intercalc.sh`:

- `codegen_next`: when the target is a known small syslib label (1020 first, others as they prove valuable), emit the inline body instead of a `bl` plus stack management.
- `codegen_expr` for unary operators: when the operand size and target architecture make the unrolled form competitive (e.g., 16-bit on ARM64), emit the unrolled body.

**Algorithm sketch (for syslib 1020).** Currently:

    bl _rt_syslib_1020   // increments .1 in place

Inline form:

    adrp x0, _var_dot_1@PAGE
    add  x0, x0, _var_dot_1@PAGEOFF
    ldrh w1, [x0]
    add  w1, w1, #1
    and  w1, w1, #0xFFFF   // wrap at 16 bits
    strh w1, [x0]

Five instructions versus the call + save/restore + return.

**Effort.** ~100-200 lines for the first inlining (1020), with a framework that other inlines can plug into. Each subsequent inline is ~30 lines.

**Dependencies.** Proposal 3 (opt-bisect-limit) is useful so each inline can be individually disabled.

**Test strategy.** Programs that exercise the inlined operations should still produce correct output. Add tests with `INTERCAL_ASM_ONLY=1` that check the absence of `bl _rt_syslib_1020` in the generated assembly when the optimisation applies.

**Risks.** Medium. Register clobbering: the inline must respect the calling-convention assumptions of surrounding code. The body must use only registers that are scratch in the calling convention.

**Educational value.** Inlining is the single optimisation that buys the most performance in real compilers. A small version of it makes the cost-benefit calculation concrete (number of instructions saved, number of bytes added per call site).

**References.**
- [middle-end-and-optimisation.md](middle-end-and-optimisation.md) "What we leave on the table" section, "Inlining the runtime primitives".
- Cooper and Torczon's chapter on inter-procedural optimisation.
- "Choosing the Best Heuristic for a NLPP" research papers on inliner cost models.

---

## 6. Ignore-flag dead-code elimination

**What it is.** Mirror `compute_flag_checks` (which eliminates dead per-statement abstain checks) for variable-level ignore flags. Currently every scalar assignment begins with a check of the variable's `_ign` flag; if the variable is never `IGNORE`d in the program, the check is dead code.

**Lesson source.** Same dataflow-DCE pattern as `compute_flag_checks`. The general technique is described in every compiler textbook; LLVM's ADCE, GCC's `tree-ssa-dce.cc`.

**Where in our codebase.** `src/bootstrap/intercalc.sh`: add a `compute_ignore_checks` pass that mirrors `compute_flag_checks` but tracks per-variable ignore-flag mutations. Result is a `var_needs_ignore_check` associative array keyed by variable. `codegen_assign` consults it before emitting the prologue.

**Algorithm.**

    compute_ignore_checks() {
      typeset -A var_ignored
      # Walk every statement; for IGNORE / REMEMBER, mark every named variable
      for (( i=1; i<=stmt_count; i++ )); do
        case "${stmt_type[$i]:-}" in
          IGNORE|REMEMBER)
            for v in $(extract_var_list "${stmt_body[$i]}"); do
              var_ignored[$v]=1
            done
            ;;
        esac
      done
      # Result: var_needs_ignore_check[var] = ${var_ignored[var]:-0}
    }

Then `codegen_assign` emits the ignore-flag check only when `var_needs_ignore_check[$target_var]` is set.

**Effort.** ~100 lines for the pass plus codegen change plus tests.

**Dependencies.** None.

**Test strategy.** Programs that never use IGNORE should produce assembly without `_ign` flag checks. Programs that IGNORE some variables should retain checks only on those.

**Risks.** Low if the analysis is correct. Soundness check: any variable mentioned in any IGNORE/REMEMBER statement, including dynamic ones reached through an UNKNOWN gerund, must be conservatively flagged.

**Educational value.** Second example of "static analysis to eliminate runtime checks" in our codebase. Together with `compute_flag_checks`, the two demonstrate the dataflow-DCE pattern at the statement level and the variable level.

**References.**
- Our own `compute_flag_checks`.
- LLVM's `lib/Transforms/Scalar/ADCE.cpp`.
- GCC's `gcc/tree-ssa-dce.cc`.

---

## 7. DCE of unreferenced labels

**What it is.** A pass that detects labels that no statement targets via `NEXT`, `RESUME`, `COME FROM`, `ABSTAIN FROM (label)`, or `REINSTATE (label)`, then drops the label slot. Currently every labelled statement emits a `_stmt_LABEL_N:` symbol whether or not anyone references it.

**Lesson source.** Link-time DCE (`-ffunction-sections -Wl,--gc-sections`) is the production analogue. Every compiler at our scale has *some* pass that drops unreferenced symbols.

**Where in our codebase.** `src/bootstrap/intercalc.sh`: add a `compute_label_references` pass after `resolve_come_from` and `detect_syslib`. Output is a `label_referenced` associative array. `codegen_*` functions consult it before emitting `_stmt_LABEL_N:`.

**Algorithm.**

    compute_label_references() {
      typeset -A label_referenced
      for (( i=1; i<=stmt_count; i++ )); do
        local body="${stmt_body[$i]}"
        case "${stmt_type[$i]:-}" in
          NEXT)
            label_referenced[${stmt_next_target[$i]:-}]=1
            ;;
          COME_FROM)
            label_referenced[${stmt_cf_target[$i]:-}]=1
            ;;
          ABSTAIN|REINSTATE)
            # Parse body for parenthesised numbers
            for n in $(extract_label_targets "$body"); do
              label_referenced[$n]=1
            done
            ;;
        esac
      done
      # Mark gerund-targeted statement types as referenced too
      # (since ABSTAIN FROM CALCULATING affects every ASSIGN)
    }

**Effort.** ~80 lines.

**Dependencies.** None.

**Test strategy.** Generate a program with several labelled statements where most are never referenced. Verify the assembly omits the unreferenced labels. Verify the binary still produces correct output.

**Risks.** Low if the gerund-based ABSTAIN/REINSTATE conservatively marks all matching statements. The analysis must be over-conservative, never under.

**Educational value.** Concrete use of the visitor pattern at compile time to compute reachability of named entities.

**References.**
- The `--gc-sections` linker flag.
- Cooper and Torczon's chapter on dead-code elimination.

---

## 8. The `Note [...]` documentation convention

**What it is.** Adopt GHC's longstanding convention of writing each cross-cutting design decision as a `Note [Name]: explanation` block in the source code, with grep as the index. Our existing docs/ chapters cover much of this material at a higher level; the Notes pattern moves the most subtle "why" comments back into the source where they can be evaluated next to the code.

**Lesson source.** GHC's source is famous for this pattern. Every major design decision in `compiler/GHC/Core/Opt/Simplify/Iteration.hs` and the rest of the optimiser is annotated with a `Note`. The pattern is mentioned in [ghc-overview.md](ghc-overview.md) as one of the "common gotchas" for new contributors.

**Where in our codebase.** `src/bootstrap/intercalc.sh` and `src/runtime/<platform>.s` are the highest-yield targets. Specific places that would benefit:

- The politeness ratio computation in `check_politeness` (why 1/5 to 1/3, where the rule comes from, what the boundary cases are).
- The COME FROM resolution in `resolve_come_from` (why COME FROM creates an implicit edge after the labelled statement, why multiple COME FROMs to one label are rejected).
- The branchless conditional ADD pattern (already documented in `intercal_patterns.md`, but a Note in the source where it is first used would make it discoverable).
- The sed-based platform conversion for Linux ARM64 (why sed is sufficient, why the order matters: `@PAGEOFF` before `@PAGE`).
- The `_aedone` trampoline removal and corresponding peephole rule (why the trampoline existed, why removing it requires the peephole).
- Why `compute_flag_checks` is necessary at all (the cost it removes, the conservatism it requires).

**Algorithm.** None; this is documentation work. Rough form:

    # Note [PoliteRatioBoundary]
    #   The 1/5..1/3 boundary uses inclusive integer arithmetic:
    #   "polite >= count/5" means "polite*5 >= count", computed as
    #   `(( polite * 5 >= count ))`. The asymmetry between lower and
    #   upper bound is intentional: the upper bound is "polite > count/3"
    #   (strict) per the INTERCAL-72 manual; the lower bound is inclusive
    #   ("at least 1/5", per the same source).

The convention: every Note has a `[Name]` tag, the name appears nowhere else in the source, and a contributor uses `grep -n 'Note \[Name\]'` to find references.

**Effort.** ~5 minutes per Note. Aim for ten Notes in the first pass; let more accumulate organically.

**Dependencies.** None. Update `AGENTS.md` to document the convention.

**Test strategy.** No test code, but a lint that grep-checks every `Note [Name]:` definition has at least one `Note [Name]` reference somewhere (or vice versa).

**Risks.** Low. Wrong-direction risk: Notes that lie or go stale. Mitigation: include the date the Note was written; re-read on touch.

**Educational value.** Establishes a culture of documenting *why* in source. Makes the code self-explanatory at the level production compilers achieve.

**References.**
- GHC source, especially `compiler/GHC/Core/`. Try `git grep -n 'Note \[' compiler/GHC/Core/`.
- The "Notes in Hawaiian" GHC commentary chapter (informal documentation of the convention).

---

# Tier 2: medium investments

One to several weeks each. Higher educational value; require some refactoring or new infrastructure.

## 9. Real three-address IR feeding codegen (Phase A)

**What it is.** Today our `codegen_*` functions walk the parse tree and emit assembly directly. The `--emit-3addr` flag prints a three-address listing that is *parallel* to but not consumed by codegen. This proposal makes the three-address form a real IR: codegen consumes it instead of the parse tree.

**Lesson source.** Every compiler in Part VII has at least one IR. GIMPLE for GCC, LLVM IR for LLVM-based compilers, MIR for rustc, CLIF for Cranelift, ZIR/AIR for Zig. The benefit is universal: passes are easier to write on a flat instruction list than on a tree, and the IR becomes the natural extension point for future optimisations.

**Where in our codebase.** A substantial reorganisation of `src/bootstrap/intercalc.sh`. The shape:

- New module: `build_ir()` runs after analysis, walks the parse tree, emits a flat IR represented as parallel arrays:

      ir_op[]      # operation names (assign, load, mingle, select, unary_and, ...)
      ir_dst[]     # destination operand
      ir_src1[]    # first source
      ir_src2[]    # second source (where applicable)
      ir_src3[]    # third source (rare)
      ir_stmt[]    # back-pointer to source statement for diagnostics
      ir_count     # total instructions

- New module: `lower_ir()` walks `ir_*` and emits assembly. The existing `codegen_*` functions are decomposed: the parse-tree walk that produces them becomes `build_ir`, the assembly emission becomes `lower_ir`.

The IR vocabulary is small. INTERCAL operations:

- `assign`: `dst = src1`
- `load`: `dst = LOAD(src1)` (load named variable)
- `store`: `STORE(dst, src1)` (store to named variable)
- `mingle`: `dst = MINGLE(src1, src2)`
- `select`: `dst = SELECT(src1, src2)` (mask, value)
- `unary_and`, `unary_or`, `unary_xor`: `dst = UNARY_*(src1, width)`
- `dim`: dimension array
- `subscript`: `dst = ARRAY[src1, src2, ...]`
- `next`: control transfer to label
- `resume`: control transfer pop N
- `forget`: pop N from NEXT stack
- `come_from`: implicit edge marker
- `abstain`, `reinstate`: flag manipulation
- `ignore`, `remember`: variable flag manipulation
- `stash`, `retrieve`: variable stack ops
- `read_out`, `write_in`: I/O
- `give_up`: program termination

Roughly 20 ops; matches the GIMPLE-shaped vocabulary.

**Algorithm.** `build_ir` is a recursive-descent walk: each parse-tree node produces a sequence of IR instructions, with the last instruction's destination being the value of the subexpression. Temporaries are auto-numbered: `t0`, `t1`, etc.

`lower_ir` walks the IR linearly. Each op has a per-op codegen that takes the IR record and emits assembly. For most ops this is mechanical translation. The existing `codegen_expr`, `codegen_assign`, etc. are decomposed.

**Effort.** Significant. ~600-900 lines of zsh net change: new IR data structures (~50 lines), `build_ir` (~400 lines as a refactor of existing tree-walking logic), `lower_ir` (~300 lines as a refactor of existing emission logic), small adjustments to all 71 existing tests. One to two weeks of focused work.

**Dependencies.** None at the source-code level. Conceptually depends on having `--emit-3addr` already as the read-only version (which we have).

**Test strategy.** The big win: the existing 71 tests still pass byte-for-byte if the IR is correct. A regression test compares assembly output from a small set of programs before and after the refactor. Plus new tests that check IR shape directly via a `--emit-ir-pre-codegen` flag.

**Risks.** High. The refactor touches every codegen path. Risks of subtle assembly differences: IR's expression linearisation may differ from the parse-tree walker's evaluation order in ways that change the generated code. Mitigation: stage the migration. Implement IR + lowering for one statement type at a time (start with `GIVE_UP`, the simplest), keep the old codegen for the rest, gate each migration behind a flag, validate against the test suite, then delete the old path.

**Educational value.** Massive. After this proposal, our compiler genuinely has an IR. We can teach IR design, IR transformations, and the value of decoupling parsing from codegen in our own source.

**References.**
- GCC's GIMPLE: `gcc/gimple.h`, `gcc/gimplify.cc`.
- LLVM IR: the LangRef.
- rustc's MIR: `compiler/rustc_middle/src/mir/`.
- Cranelift's CLIF: `cranelift/codegen/src/ir/`.
- Cooper and Torczon's chapter on intermediate representations.

---

## 10. CFG construction feeding codegen

**What it is.** With Phase A's IR in place, group IR instructions into basic blocks and represent control flow explicitly as edges between blocks. The codegen then iterates over the block graph rather than the linear IR.

**Lesson source.** Every compiler in Part VII works on a CFG. Even our existing `--emit-cfg` flag computes a CFG view; this proposal makes it *the* representation codegen consumes.

**Where in our codebase.** Extends Phase A. Add:

    bb_first[]   # first IR instruction in each block
    bb_last[]    # last IR instruction in each block
    bb_succ[]    # successors (comma-separated block IDs)
    bb_pred[]    # predecessors
    bb_label[]   # label associated with the block (if any)
    bb_count     # number of blocks
    ir_to_bb[]   # IR instruction -> block ID

`build_cfg` runs after `build_ir`. `lower_ir` is restructured to iterate blocks and emit each block's instructions in linear order, with explicit block-end terminators (branches).

**Algorithm.** Standard leader detection plus block construction:

1. Mark IR instruction 0 as a leader.
2. For every branching instruction (next, resume, give_up, come_from), the immediately following instruction is a leader. The targets of branches are also leaders.
3. Walk from each leader until the next leader; the inclusive range is a block.
4. Compute successors per block from the terminator's targets.
5. Compute predecessors as the inverse.

**Effort.** ~300 lines on top of Phase A. One week.

**Dependencies.** Proposal 9 (Phase A IR).

**Test strategy.** All 71 existing tests still pass. New tests directly check the CFG structure on canonical programs (linear, COME FROM, NEXT loops).

**Risks.** Medium. Edge case: COME FROM inserts an *implicit* edge after a labelled statement, with semantics that the labelled statement's normal fall-through is replaced. The CFG must model this correctly.

**Educational value.** High. Now we have a CFG that codegen actually uses. A reader can connect "what `--emit-cfg` shows" with "what gets emitted".

**References.**
- Cooper and Torczon's chapter on CFG construction.
- LLVM's `llvm/lib/IR/CFG.h` and `llvm/lib/Analysis/CFG.cpp`.
- The original "Definition of Basic Block" papers (1959 onwards).

---

## 11. SSA construction via Braun's algorithm

**What it is.** Convert the CFG-based IR into Static Single Assignment form using Braun et al.'s on-the-fly algorithm (2013). Each variable definition is fresh; every use names a unique definition. Block parameters (Cranelift's choice; mathematically isomorphic to phi nodes) handle merges.

**Lesson source.** SSA is the foundation of every modern optimisation pipeline. Cytron et al. 1991 is the classical algorithm; Braun et al. 2013 is the simpler on-the-fly variant that Cranelift's `FunctionBuilder` uses. Block parameters in place of phi nodes are MLIR's and Cranelift's design choice, more mutation-friendly.

**Where in our codebase.** Extends Phases A and B. Add per-variable, per-block versioning:

    var_defs[var:bb_id]   # current SSA-version of var in this block
    block_params[bb_id]   # ordered list of block parameters (var, type)

`build_ir` is augmented to call `read_variable(var, bb)` and `write_variable(var, bb, value)` instead of direct variable access.

**Algorithm.** Braun et al. (2013), the canonical implementation. The interface is exactly four operations: `writeVariable`, `readVariable`, `sealBlock`, plus the internal `addPhiOperands` and `tryRemoveTrivialPhi`.

    writeVariable(variable, block, value):
        currentDef[variable][block] = value
    
    readVariable(variable, block):
        if currentDef[variable].has(block):       # local value numbering
            return currentDef[variable][block]
        return readVariableRecursive(variable, block)
    
    readVariableRecursive(variable, block):
        if block not in sealedBlocks:
            val = newPhi(block)                    # placeholder
            incompletePhis[block][variable] = val
        elif len(block.preds) == 1:
            val = readVariable(variable, block.preds[0])
        else:
            val = newPhi(block)
            writeVariable(variable, block, val)    # break cycles BEFORE recursion
            val = addPhiOperands(variable, val)
        writeVariable(variable, block, val)
        return val
    
    addPhiOperands(variable, phi):
        for pred in phi.block.preds:
            phi.appendOperand(readVariable(variable, pred))
        return tryRemoveTrivialPhi(phi)
    
    sealBlock(block):
        for variable in incompletePhis[block]:
            addPhiOperands(variable, incompletePhis[block][variable])
        sealedBlocks.add(block)

`tryRemoveTrivialPhi` collapses any phi whose operands are all equal (modulo the phi itself) into a single value, then re-checks all users (which may also become trivial). This is what gives "minimal" SSA without dominance frontiers.

Common implementation pitfalls (drawn from Cranelift's `cranelift-frontend/src/ssa.rs` and Saarland's reference):

- Forgetting `writeVariable(variable, block, val)` *before* `addPhiOperands` causes infinite recursion in loops.
- `tryRemoveTrivialPhi` must rewrite users in place; if you skip the recursive re-check on users, you get cascades of redundant phis.
- A block must be sealed only when *all* preds are known. For irreducible CFGs constructed in DFS order, sealing happens after the back-edge target's loop is finished.

**Effort.** ~500 lines on top of CFG. One to two weeks.

**Dependencies.** Proposal 9 (IR), Proposal 10 (CFG).

**Test strategy.** Verify SSA invariants programmatically: every `ir_dst` is unique across the IR. Existing 71 tests still pass with SSA-form IR feeding codegen.

**Risks.** Medium-high. Easy to get block-parameter handling wrong on irregular control flow (COME FROM creates joins that look unusual). Sealing blocks at the right moment is subtle.

**Educational value.** Very high. The first time a contributor watches our compiler produce SSA-form IR for a small program is a milestone. Every later optimisation lives on this foundation.

**References.**
- Braun et al., "Simple and Efficient Construction of Static Single Assignment Form" (CC 2013), <https://pp.ipd.kit.edu/uploads/publikationen/braun13cc.pdf>.
- Cranelift's `cranelift_frontend::FunctionBuilder` source.
- Cytron et al. 1991, the canonical paper for the dominance-frontier-based version.

---

## 12. Liveness analysis + linear-scan register allocation

**What it is.** Replace our current "every value goes on the stack" approach with register allocation. Compute live ranges per IR value via backward dataflow, then assign physical registers using Poletto-Sarkar linear scan (1999).

**Lesson source.** OCaml's `asmcomp/linscan.ml` is the cleanest production implementation, around 330 lines. Cranelift's regalloc2 is the modern backtracking variant. Every production backend has some register allocator; linear scan is the most pedagogically friendly entry point.

**Where in our codebase.** Add two passes after Phase B (SSA):

- `compute_liveness`: backward dataflow on the SSA-form IR. For each program point, the set of live values.
- `linear_scan`: assign physical registers by Poletto-Sarkar.

Then `lower_ir` emits register references instead of stack slots wherever possible.

**Algorithm.** Poletto-Sarkar (1999), verbatim:

    LinearScanRegisterAllocation:
      active <- {}
      for each live interval i, in order of increasing start point:
        ExpireOldIntervals(i)
        if length(active) == R:
          SpillAtInterval(i)
        else:
          register[i] <- a register removed from pool of free registers
          add i to active, sorted by increasing end point
    
    ExpireOldIntervals(i):
      for each interval j in active, in order of increasing end point:
        if endpoint[j] >= startpoint[i]: return
        remove j from active
        add register[j] to pool of free registers
    
    SpillAtInterval(i):
      spill <- last interval in active        # the one with farthest endpoint
      if endpoint[spill] > endpoint[i]:
        register[i] <- register[spill]
        location[spill] <- new stack location
        remove spill from active
        add i to active, sorted by increasing end point
      else:
        location[i] <- new stack location     # spill the new interval itself

The spill heuristic: spill the interval in `active` with the farthest endpoint, on the theory that it ties up a register the longest. If the new interval `i` outlives every active interval, spill `i` itself.

Pitfalls (from V8 Crankshaft's `lithium-allocator.cc` and IonMonkey's historical `LinearScan.cpp`):

- Computing live intervals naively bloats them across non-uses and forces unnecessary spills. Use lifetime holes / split intervals (Wimmer-Mössenböck extension) for production quality.
- `active` must stay sorted by endpoint; a hash set kills correctness.
- When a spilled value is reloaded for a use, you need a scratch register reserved or you need to insert spill-and-reload pairs.
- Two-address machines (x86) need extra care: the destination of an `add` clobbers a source, so register hints or move insertion are required.

**Effort.** ~400-600 lines. Two weeks.

**Dependencies.** Proposals 9, 10, 11.

**Test strategy.** Existing tests still pass. New tests verify that simple expressions avoid stack spills (use `INTERCAL_ASM_ONLY=1` and grep for absence of unnecessary `str`/`ldr` pairs).

**Risks.** Medium. The hard part is correctness around calls (callee-saved vs caller-saved registers) and around the fact that our runtime expects specific registers for syslib calls.

**Educational value.** Very high. Register allocation is one of the classical compiler problems, and seeing it implemented over our SSA is real. The contrast with regalloc2 (backtracking) and with graph coloring (Chaitin-Briggs) becomes concrete.

**References.**
- Poletto and Sarkar, "Linear Scan Register Allocation" (TOPLAS 1999), <https://dl.acm.org/doi/10.1145/330249.330250>.
- OCaml's `asmcomp/linscan.ml` for the canonical small implementation.
- Cranelift's regalloc2 docs for the modern backtracking variant.
- Briggs et al., "Coloring Heuristics for Register Allocation" for the graph-coloring alternative.

---

## 13. Sparse Conditional Constant Propagation (SCCP)

**What it is.** Wegman-Zadeck's SCCP (1991) extends our existing `eval_const` (which folds whole-constant subexpressions) with a dataflow that propagates constants across statement boundaries and prunes unreachable branches.

**Lesson source.** SCCP is the canonical example of a flow-sensitive constant-folding optimisation. Wegman-Zadeck's paper. LLVM's `lib/Transforms/Scalar/SCCP.cpp`. GCC's `tree-ssa-ccp.cc`.

**Where in our codebase.** A new pass after Phase B (SSA) and before lowering. Operates on SSA-form IR.

**Algorithm.** Wegman-Zadeck. Three-element lattice per SSA value:

    TOP < CONST(c) < BOTTOM

`TOP` means "not yet visited", `CONST(c)` means "proven equal to c", `BOTTOM` means "non-constant or runtime-dependent".

Meet operator (used at phis):
- `TOP ⊓ x = x`
- `BOTTOM ⊓ x = BOTTOM`
- `CONST(c) ⊓ CONST(c) = CONST(c)`
- `CONST(c) ⊓ CONST(d) = BOTTOM` when `c ≠ d`

Algorithm:

    init:
      for every SSA value v: lattice[v] = TOP
      for every CFG edge e: executable[e] = false
      CFGWorklist = { entry_edge }
      SSAWorklist = {}
    
    while CFGWorklist not empty or SSAWorklist not empty:
      if CFGWorklist not empty:
        edge (B_pred -> B) = pop()
        if executable[edge]: continue
        executable[edge] = true
        for each phi in B: visitPhi(phi)
        if this is the first executable in-edge of B:
          for each non-phi instruction inst in B: visitInst(inst)
          if B has only one out-edge: push that edge onto CFGWorklist
      else:
        v = pop(SSAWorklist)
        for each use u of v:
          if u is a phi: visitPhi(u)
          else if the block containing u has any executable in-edge: visitInst(u)
    
    visitPhi(phi):
      new = TOP
      for each (pred, val) in phi.operands:
        if executable[pred -> phi.block]:
          new = new ⊓ lattice[val]
      if new != lattice[phi]:
        lattice[phi] = new
        push phi onto SSAWorklist
    
    visitInst(inst):
      if inst is a branch on condition c:
        if lattice[c] == CONST(true): push true-edge
        elif lattice[c] == CONST(false): push false-edge
        elif lattice[c] == BOTTOM: push both edges
        else (TOP): push nothing yet
      else:
        new = evaluate(inst, lattice)        # arithmetic on lattice values
        if new != lattice[inst.result]:
          lattice[inst.result] = new
          push inst.result onto SSAWorklist

Pitfalls (from LLVM's `lib/Transforms/Scalar/SCCP.cpp` and Go's `cmd/compile/internal/ssa/sccp.go`):

- `evaluate` must handle `TOP` operands by returning `TOP` (not `BOTTOM`); otherwise you lose precision on first visit.
- Forgetting to gate the phi meet by `executable[pred -> block]` collapses to ordinary CP; you get fewer constants.
- Once `executable[edge]` flips to `true` it must never flip back. The lattice descends monotonically.
- After SCCP completes, the rewrite step is mandatory: replace `CONST(c)` defs with literals; delete blocks reached only by non-executable edges. Skipping the rewrite makes SCCP a no-op.

**Effort.** ~300-500 lines on top of SSA.

**Dependencies.** Proposals 9, 10, 11.

**Test strategy.** Programs whose constants resolve across statements get folded. Compare assembly before and after.

**Risks.** Medium. Termination: the lattice has finite height (TOP → CONST → BOTTOM is at most 2 steps per value), so termination is guaranteed. Correctness: meet operator must be monotone (TOP ⊓ x = x; BOTTOM ⊓ x = BOTTOM; CONST(c) ⊓ CONST(c) = CONST(c); CONST(c) ⊓ CONST(d) = BOTTOM if c != d).

**Educational value.** SCCP is one of the most cited passes in compiler textbooks. Implementing it on our compiler closes the gap from "we have constant folding" to "we have proper constant propagation".

**References.**
- Wegman and Zadeck, "Constant Propagation with Conditional Branches" (TOPLAS 1991), <https://dl.acm.org/doi/10.1145/103135.103136>.
- LLVM's `lib/Transforms/Scalar/SCCP.cpp` and `IPSCCP.cpp` for production implementation.
- Muchnick's *Advanced Compiler Design and Implementation* covers SCCP in detail.

---

## 14. Csmith-INTERCAL: random program generator + differential testing

**What it is.** A generator for valid INTERCAL programs that produces well-defined programs with predictable behaviour, then differential-tests our compiler against either C-INTERCAL (via the user's installed `ick`) or against our own pure-vs-native syslib. Bugs surface as output divergence.

**Lesson source.** Csmith (Yang et al., PLDI 2011) found hundreds of bugs in GCC and LLVM. YarpGen (OOPSLA 2020) is the modern successor. Crater is the rustc analogue. The pattern of "generate, compile, run, differential" finds bugs that exhaustive testing misses.

**Where in our codebase.** A new tool: `tools/csmith_intercal.sh` (generator) plus a runner `tests/run_csmith_diff.sh`.

**Algorithm.** Random generation strategies:

1. **Strict subset.** Limit to a "safe" INTERCAL subset that excludes:
   - Integer overflow paths (use only constants in safe ranges).
   - Array indexing without bounds-check guarantees.
   - I/O that depends on user input.
   - The politeness rule risks (target ratios near 1/4 to stay safely in [1/5, 1/3]).
2. **Generate by template.** Build programs from templates: a sequence of `DO .V <- #N` assignments, optional NEXT to a known-safe label, GIVE UP. No COME FROM (introduces complexity), no probability (introduces nondeterminism).
3. **Compute expected output.** Since the generator chose every value, the expected output is computable in pure shell at generation time.
4. **Validate.** Compile with `intercalc.sh`, run, compare actual stdout against expected. Optionally also compile with `--pure-syslib` and compare; optionally compile with `ick` (C-INTERCAL) and compare.

**Effort.** ~600-1000 lines zsh: the generator, the expected-output computer, the differential runner. Two weeks for an MVP, plus ongoing work to expand the language subset coverage.

**Dependencies.** None.

**Test strategy.** Bootstrap by generating programs we know to be correct (pure constant assignments and outputs). Then expand carefully; a generator that produces a divergence is itself a unit of evidence.

**Risks.** Medium-high. Generating UB-free INTERCAL is non-trivial because INTERCAL's runtime errors are many (the ICL000 family) and easily triggered by random programs. The subset must be conservatively chosen.

**Educational value.** Very high. Differential testing is the most powerful debugging technique for compilers. Adding it to our project converts "we have 71 tests" to "we have 71 + an unbounded stream of generated tests".

**References.**
- Yang, Chen, Eide, Regehr, "Finding and Understanding Bugs in C Compilers" (PLDI 2011).
- Livinskii et al., "Random Testing for C and C++ Compilers with YARPGen" (OOPSLA 2020).
- Csmith on GitHub: <https://github.com/csmith-project/csmith>.
- The Crater documentation for rustc.

---

## 15. Declarative peephole rules (Go `.rules` / Cranelift ISLE style)

**What it is.** Replace the ad-hoc `peephole_optimize` function (currently growing as we add rules) with a small declarative DSL. Each rule is a pattern-match plus a rewrite. A rule compiler converts the DSL into zsh code that runs at compile time.

**Lesson source.** Go's `cmd/compile/internal/ssa/gen/*.rules` files (covered in detail in [go-overview.md](go-overview.md)) and Cranelift's `*.isle` files ([cranelift-overview.md](cranelift-overview.md)) are the production examples. The same idea is in GCC's machine descriptions (`define_peephole2`).

**Where in our codebase.** A new directory `tools/peephole/`:

- `peephole/rules.peep`: rule definitions (DSL source).
- `tools/gen_peephole.sh`: rule compiler. Produces `peephole/rules_generated.sh`.
- `peephole/rules_generated.sh`: included by `intercalc.sh` (or sourced as needed).

DSL example:

    # Drop unconditional branch immediately followed by its target
    rule "branch_to_next" {
        pattern: 'b LABEL'
        followed-by: 'LABEL:'
        action: drop
    }
    
    # Redundant identity move
    rule "redundant_mov" {
        pattern: 'mov REG, REG'
        action: drop
    }
    
    # Branch-to-branch
    rule "jmp_to_jmp" {
        pattern: 'b L1'
        match-block-only-instr: 'L1: b L2'
        action: 'b L2'
    }

**Algorithm.** The rule compiler:
1. Parses the `.peep` file into an AST.
2. For each rule, generates a zsh function that detects the pattern in the assembly text and applies the rewrite.
3. The compiled rules are bundled into a single function called by `peephole_optimize`.

**Effort.** ~400-600 lines for the rule compiler plus ~5 initial rules.

**Dependencies.** Proposal 4 (we should have a body of peephole rules to migrate).

**Test strategy.** Per-rule test that constructs assembly matching the pattern, runs the peephole, asserts the rewrite. Plus the existing 71 tests continue to pass.

**Risks.** Medium. The DSL is its own language to maintain; adding "edge case" patterns may require extending the DSL. Mitigation: keep the DSL deliberately restricted; complex rules stay as zsh code.

**Educational value.** Very high. The same idea (declarative pattern matching for compiler transformations) is in three of the production compilers we cover. Building our own teaches the tradeoffs (DSL flexibility vs. complexity, generated code vs. hand code).

**References.**
- Cranelift's ISLE: `cranelift/docs/isle-language-reference.md`.
- Go's `.rules` files: `cmd/compile/internal/ssa/gen/`.
- GCC's `define_peephole2` in the gccint manual.
- Bravenboer and Visser, "Designing Syntax Embeddings and Assimilations for Language Libraries", as background on rule-based DSLs.

---

# Tier 3: major undertakings

Multi-month projects that change the compiler's architecture or scope.

## 16. Stage3 self-hosted real compiler completion

**What it is.** Today `src/compiler/compiler.i` is a template-passthrough MVP: it dispatches by `cksum` of the source to a pre-generated assembly template. `src/compiler/stage3.i` is the evolving real compiler that reads source and emits assembly through an actual lexer/parser/codegen path. Stage3 is currently blocked on implementing a loop primitive in pure INTERCAL.

The proposal: complete stage3 to the point where it can compile our own tests and reach a 3-generation fixpoint.

**Lesson source.** OCaml's `boot/ocamlc` shows that a fully self-hosted compiler in a small language is achievable. Zig's stage1 → stage2 transition is the modern parallel.

**Where in our codebase.** `src/compiler/stage3.i`: extend from byte-probe detectors (current state) through:
- Real character-by-character tokenizer
- Statement classifier
- Expression parser
- Codegen emitting the same assembly templates we pre-generate today
- Eventually, full parity with `intercalc.sh`'s output

**Algorithm.** Several open problems to resolve first:

1. **Loop primitive.** Two paths (per `memory/project_status.md`):
   - Adopt a non-standard extension (e.g., computed COME FROM) that gives us a real conditional loop.
   - Use a ~30-statement "abstain dance" scaffold per logical loop (pure INTERCAL, expensive but works).
2. **String construction.** TTM (Turing Text Model) array building for emitting assembly text.
3. **Hash table or symbol table.** Need to track variables, labels, statement types in a structure that pure INTERCAL can manage.
4. **File I/O.** Already provided by Label 666 syscalls.

**Effort.** Many months of focused INTERCAL-in-INTERCAL work. 5,000-10,000 lines of INTERCAL.

**Dependencies.** Resolving the loop-primitive question. Either:
- Decide to extend the language (one-time decision, deviates from INTERCAL-72 but is well within "language extension" precedent).
- Commit to the abstain-dance approach (multiplies code size).

**Test strategy.** `tests/run_stage3_tests.sh` already exists with 4 tests on the byte-probe detectors. Extend incrementally: each new feature gets tests; reach feature parity with the bootstrap test suite (33 tests) as the long-term milestone.

**Risks.** High. Multi-month, INTERCAL-language constraints are punishing. The loop-primitive question is an architectural fork.

**Educational value.** Reaches the dream the project is named for: a real INTERCAL self-compiling compiler. Without this, the "self-hosted" label is partly aspirational.

**References.**
- `memory/project_status.md` for the current blockers.
- `docs/intercal_patterns.md` for the verified patterns we have.
- OCaml's `boot/ocamlc` and the bootstrapping documentation.
- Zig's `zig1.wasm` blob and the `Goodbye to the C++ Implementation of Zig` post.

---

## 17. Bytecode tier (OCaml-style)

**What it is.** Add a bytecode output mode complementing the native output. Bytecode is a portable instruction stream interpreted by a VM written once and shared across platforms. Compilation is faster (no assembly emission, no `cc` invocation); execution is slower (interpretation overhead). The VM is implemented as platform-specific assembly.

**Lesson source.** OCaml's dual `ocamlc` (bytecode) / `ocamlopt` (native) coexistence since 1996. Java's bytecode + JIT model. Many languages have considered or adopted this split.

**Where in our codebase.**

- `src/bytecode/bytecode.md`: ISA spec.
- `src/bytecode/runtime/<platform>.s`: VM implementation per platform.
- `src/bootstrap/intercalc.sh`: new `--bytecode` flag and `codegen_bytecode_*` functions.

**Algorithm.** Define a small stack-based ISA:

- `LOAD vN`: push variable's value
- `STORE vN`: pop and store
- `MINGLE`, `SELECT`: pop 2, push result
- `UNARY_AND`, `UNARY_OR`, `UNARY_XOR`: pop 1, push result
- `CONST imm`: push immediate
- `BRANCH offset`: conditional/unconditional branch
- `CALL syslib_label`: invoke a syslib routine
- `READ_OUT`, `WRITE_IN`, `GIVE_UP`: I/O and exit
- (about 30 opcodes total)

The bytecode is a simple stream of (opcode byte, operand bytes) tuples. The VM is a switch-on-opcode dispatch loop.

**Effort.** ~1500-2500 lines: ISA spec, VM per platform (3 platforms), codegen, tests. Multi-month.

**Dependencies.** None functionally; conceptually depends on having a stable IR (Phase A, proposal 9) that bytecode codegen can also consume.

**Test strategy.** Programs run identically as bytecode and as native; existing 71 tests are duplicated to run in both modes; new `tests/test_bytecode_*.sh` checks the VM's specific behaviour.

**Risks.** Medium-high. Doubles the testing surface. The VM has its own bug class (interpreter loops, dispatch errors). Maintenance cost for two output paths.

**Educational value.** High. The contrast between bytecode and native compilation is a major theme in compiler design (OCaml's dual-target story is one of its distinguishing features).

**References.**
- Leroy, "The ZINC Experiment: An Economical Implementation of the ML Language" (1990).
- OCaml's `bytecomp/` and `runtime/` directories.
- Java Virtual Machine Specification.

---

## 18. Mini LSP server

**What it is.** A Language Server Protocol implementation for INTERCAL. Provides editor integration: diagnostics, hover, go-to-definition (for labels), find-references, symbol outline.

**Lesson source.** rust-analyzer, gopls, ZLS (Zig Language Server), clangd, Aleksey Kladov's "Three Architectures for a Responsive IDE". LSP is the standard interface for IDE/editor integration.

**Where in our codebase.** New top-level directory: `src/lsp/`. Implementation language is open. Options:
- Pure zsh: doable but unusual.
- Python: easier IPC handling.
- Rust: most natural for LSP given the tooling ecosystem (the `lsp-server` crate).

**Algorithm.** LSP is a JSON-RPC protocol. The server:
1. Reads JSON-RPC messages from stdin.
2. For each request:
   - `textDocument/didOpen`, `didChange`: re-parse the document, store diagnostics.
   - `textDocument/hover`: return INTERCAL-specific info about the symbol under cursor.
   - `textDocument/definition`: for labels, return the location of the labelled statement.
   - `textDocument/references`: find every NEXT/RESUME/COME FROM/etc. that references a label.
3. Writes responses to stdout.

**Effort.** ~1500-2500 lines depending on language choice.

**Dependencies.** The parser needs to be invocable from outside `intercalc.sh`. Either factor it out or run `intercalc.sh --emit-tokens` and parse the output.

**Test strategy.** Integration tests with `tower-lsp-test-fixtures` or equivalent. End-to-end test via VS Code's Extension Test Runner.

**Risks.** High maintenance burden. LSP servers are non-trivial; nobody types INTERCAL inside an IDE today, so the cost-benefit is poor unless we view it primarily as an educational artefact.

**Educational value.** High but specialised. Teaches LSP architecture, incremental parsing, IDE-friendly error recovery. Less directly applicable to compiler engineering specifically.

**References.**
- LSP specification: <https://microsoft.github.io/language-server-protocol/>.
- rust-analyzer source: <https://github.com/rust-lang/rust-analyzer>.
- Aleksey Kladov, "Three Architectures for a Responsive IDE".

---

## 19. `DO INCLUDE` multi-file extension

**What it is.** A non-standard language extension that lets one INTERCAL source file include another. Statement: `DO INCLUDE "other.i"`. The included file is expanded inline at parse time.

**Lesson source.** C's `#include`, Modula-2's `WITH`, Ada's `with`. The simplest form of modular composition.

**Where in our codebase.** `src/bootstrap/intercalc.sh`: the parser detects `DO INCLUDE "..."` statements and recursively expands them before the rest of analysis.

**Algorithm.** Recursive textual expansion in `read_source`:

1. Read the main file.
2. Walk lines; when an `INCLUDE` statement is found, replace it with the contents of the named file.
3. Recurse: included files may include further files.
4. Track a stack of current includes to detect cycles.
5. Process each file at most once (to avoid duplicate label conflicts).

**Effort.** ~200-500 lines depending on label-namespace handling.

**Dependencies.** Depends on a decision about label scoping. Two options:
- **Flat namespace.** All labels share one space; conflicts are errors. Simple, but limits modularity.
- **Per-file namespace.** Labels are scoped to their file. Requires renaming during inclusion.

**Test strategy.** Programs split across files compile correctly; label resolution works across the boundary; cycle detection rejects circular includes.

**Risks.** Medium. Language change; not standard INTERCAL. Once shipped, supporting it forever.

**Educational value.** High. Teaches the simplest form of inter-file composition, the precondition for any real linking story. Without multi-file support, link-time optimisation has nothing to optimise.

**References.**
- C's `#include` semantics in the C standard.
- Module systems in Modula-2, Ada, Standard ML.
- Discussion of include-vs-import in language-design literature.

---

## 20. Effect/error system: static analysis of ICL errors

**What it is.** A type-system-flavour static analysis that computes, for each statement, the set of ICL runtime errors (E000, E017, E123, E129, E139, E200, E240, E241, E275, E436, E533, E555, E562, E579, E621, E632, E633) that the statement could raise. Statements proven to raise no errors of a given class can have their runtime checks removed.

**Lesson source.** Haskell's strictness analysis. Koka's effect system. Rust's `Result`-typed return values. The general idea is "track properties of values through the program by dataflow".

**Where in our codebase.** A new pass after Phase B (SSA) that operates on the IR:

1. For each statement, compute the set of error codes it could raise (based on the operations it performs).
2. Propagate forward through the CFG: a statement's *reachable* error set is the union of its own errors and any caller's errors that pass through.
3. Where the analysis proves a check is unreachable, remove it.

**Algorithm.** A forward dataflow analysis. The lattice is the powerset of error codes. The transfer function: for each statement, add the errors specific to its operation type; propagate to successors.

For example, a `STASH` statement on a never-RETRIEVEd variable cannot raise E436. A `RESUME #N` where `N` is a constant ≠ 0 cannot raise E621.

**Effort.** ~400-700 lines on top of SSA.

**Dependencies.** Proposals 9, 10, 11.

**Test strategy.** Programs that statically cannot raise certain errors should compile to assembly that lacks the corresponding runtime checks. Empirically verify code-size reductions on representative programs.

**Risks.** Medium-high. Soundness: the analysis must over-approximate the error set; missing an error is unsafe. Conservatism: some errors (E000, E017) can theoretically arise from any path; the analysis can prove their absence only in narrow cases.

**Educational value.** Very high. Effect-system-style analysis is the bridge from "imperative compilers" to "research-grade program analysis". The technique transfers to Koka, Eff, OCaml 5 effect handlers, and similar.

**References.**
- "Algebraic Effects and Effect Handlers" (Plotkin and Pretnar 2009).
- Daan Leijen's papers on Koka.
- GHC's strictness analysis: `compiler/GHC/Core/Opt/DmdAnal.hs`.
- Cousot and Cousot, "Abstract Interpretation: A Unified Lattice Model" (POPL 1977).

---

# Out of scope (deliberately)

For completeness, the following are *not* proposed despite appearing in [techniques-we-lack.md](techniques-we-lack.md):

- **Garbage collection**: INTERCAL has no allocation. Arrays go through `mmap` directly; no general-purpose heap.
- **JIT compilation**: AOT serves us. Adding a JIT would mean a runtime mmap-and-emit infrastructure for no application benefit.
- **ML/GPU compiler features**: no numerical workload to justify.
- **Borrow checker / ownership types**: no references in the language.
- **Type inference**: four monomorphic types; nothing to infer.
- **Verifying compiler in Coq**: no formal semantics for INTERCAL exists worth proving against.
- **Polyhedral optimiser**: no nested numerical loops over multidimensional arrays.
- **Tracing JIT**: AOT only.

Each of these is documented with its specific rationale in `techniques-we-lack.md`.

# Recommended sequence

If we adopt several proposals, the order matters because some build on others. A pragmatic sequence:

1. **Tier 1 (one to two sessions).** Proposals 1, 2, 3 (the inspection/timing/bisect flags) in one TDD session. Then 4, 5, 6, 7 (peephole, inlining, ignore-DCE, label-DCE) over a few sessions.
2. **Documentation pass.** Proposal 8 (Notes convention) in parallel; very low cost, accumulates value over time.
3. **Phase A landing (one to two weeks).** Proposals 9 + 10 (real IR + CFG feeding codegen). Architectural lift; do this when the Tier 1 backlog is empty.
4. **SSA + classical optimisations (one month).** Proposals 11 (SSA) + 12 (linear-scan regalloc) + 13 (SCCP) build on Phase A.
5. **Differential testing (one to two weeks, parallel).** Proposal 14 (Csmith-INTERCAL) is orthogonal to Phase A and can land independently.
6. **Declarative rules (parallel).** Proposal 15 (declarative peephole) is orthogonal; valuable once we have several rules in proposal 4.
7. **Tier 3 (multi-month, optional).** Proposals 16-20 are major commitments. None is required for the project's identity. Stage3 (16) is the most defensible if the goal is "true self-hosting"; bytecode (17) if portability; LSP (18) if IDE story; INCLUDE (19) if modularity; effect system (20) if research interest.

Each proposal in this chapter is independently committable. The 71 existing tests are the regression armour for all of them.

# Closing

The picture this chapter paints is not "we should do all twenty". It is "here are the twenty doors; we know what is behind each; we can open the ones that fit our path".

The Tier 1 set, taken together, would extend the compiler's introspection and optimiser surface measurably without changing its shape. The Tier 2 set, particularly Phase A through SSA-based passes, would move the compiler from "no IR" to "real IR with classical optimisations": educationally the largest jump available to us. The Tier 3 set is for when the project's ambitions grow.

Whatever we pick, the discipline is the same: TDD per AGENTS.md, one proposal per commit, regression tests that match production-compiler conventions, documentation chapters as deliverables.

The book is now richer than the compiler. Part VII names ten production compilers; Part VIII catalogues their techniques; this chapter says which of those techniques we could adopt and how much each would cost. The next move is whichever the maintainer wants.
