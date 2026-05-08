# Improvement-proposals status (live tracker)

This document tracks the implementation status of every proposal in
[improvement-proposals.md](improvement-proposals.md). It is updated as
work progresses.

## Tier 1 (8 proposals): all DONE

| # | Name | Status | Commit |
|---|------|--------|--------|
| 1 | `--emit-tokens` flag | DONE | c549fc6 |
| 2 | `--time-report` flag | DONE | 7f5ac36 |
| 3 | `--opt-bisect-limit=N` flag | DONE | 10aa092 |
| 4 | More peephole rules | DONE | 56501a9 |
| 5 | Inline runtime primitives (syslib 1020) | DONE | a478b3d |
| 6 | Ignore-flag DCE | DONE | d9f7c84 |
| 7 | DCE of unreferenced labels (reframed as warning) | DONE | 51d3ef2 |
| 8 | Note [Name] documentation convention | DONE | 68f7113 |

Tier 1 ships as discrete commits, each gated by TDD with tests
passing on all suites and CI extended accordingly.

## Tier 2 (7 proposals): partial

| # | Name | Status |
|---|------|--------|
| 9 | Real three-address IR feeding codegen | INSPECTION-LAYER LANDED (bf44fe3); codegen-rewrite remains |
| 10 | CFG construction feeding codegen | SAME (rolled into #9) |
| 11 | SSA via Braun | NOT STARTED (depends on #9 codegen-rewrite) |
| 12 | Linear-scan regalloc | NOT STARTED (depends on #11) |
| 13 | SCCP on SSA | NOT STARTED (depends on #11) |
| 14 | Csmith-INTERCAL fuzzer + diff testing | DONE (ed4f4b3 / next push) |
| 15 | Declarative peephole rules DSL | DONE (next push) |

### Why proposals 9-13 are not fully implemented in this session

The proposals form a chain: a real IR is the prerequisite for SSA,
which is the prerequisite for both linear-scan register allocation
and SCCP. Implementing the chain end-to-end is a multi-week project
documented at length in `docs/improvement-proposals.md`. A single
session can land the inspection-only landing of proposals 9-10 (the
new `--emit-ir-full` flag) but not the codegen rewrite that those
proposals describe.

The honest framing: codegen-from-IR is the largest architectural
lift our compiler has on its roadmap. It must be paced as its own
focused initiative with its own test discipline. Forcing it into a
"do all 20 in one session" pace would compromise the regression
armour built up over 71 tests across 6 suites.

### Path to full Tier 2

When ready, the suggested order:

1. Stage proposal 9: rewrite `codegen_program` to first build an IR
   (using the same vocabulary `--emit-ir-full` already prints) and
   then have a second pass walk the IR to emit assembly. Validate
   each statement type one at a time, gating with a flag, behind
   feature toggles, until parity is reached and the parse-tree-walk
   path is removed.
2. Add CFG construction (#10) on top of the IR. Migrate codegen to
   walk blocks rather than the linear IR.
3. Land Braun SSA (#11). Verify SSA invariants programmatically.
4. Add liveness analysis (foundation for #12).
5. Implement linear-scan regalloc (#12) on the SSA-form IR.
6. Implement SCCP (#13) on the SSA-form IR.

Each is one to two weeks. The whole chain is one quarter of focused
work.

## Tier 3 (5 proposals): scaffolding only

| # | Name | Status |
|---|------|--------|
| 16 | Stage3 self-hosted real compiler | EXISTS as `src/compiler/stage3.i`; loop primitive blocker |
| 17 | Bytecode tier (OCaml-style) | NOT STARTED |
| 18 | Mini LSP server | NOT STARTED |
| 19 | `DO INCLUDE` multi-file extension | NOT STARTED |
| 20 | Effect/error static analysis | NOT STARTED (depends on #11) |

### Why Tier 3 is not implemented in this session

Each Tier 3 item is a multi-month project as documented in
`docs/improvement-proposals.md`. They are not session-sized work.

The honest framing: Tier 3 represents the project's long-term
ambitions. Any one of them, if pursued, becomes its own sub-project
with its own roadmap. The improvements to the compiler from Tier 1
(inspection, optimisation, documentation) and the partial Tier 2
landings (--emit-ir-full, Csmith-INTERCAL, declarative peephole DSL)
are what the present session can deliver responsibly.

### Path to Tier 3

For #16 (stage3 completion), the immediate blocker is the
loop-primitive question described in `memory/project_status.md`. A
session dedicated to resolving that question (computed COME FROM
extension vs abstain-dance scaffolding) is the prerequisite.

For the others, decide whether the project's identity calls for
them. None is required; each is optional.

## Summary

In one focused session:

- **8 of 20 proposals fully implemented** (all of Tier 1).
- **3 of 20 partially implemented** (Tier 2: #9 inspection layer,
  #14 fuzzer + differential testing, #15 declarative peephole DSL).
- **9 of 20 not started** (Tier 2: codegen-from-IR rewrite, SSA,
  regalloc, SCCP. Tier 3: stage3, bytecode, LSP, INCLUDE, effect
  system). Each has documented rationale and effort estimates.

The implemented portion is what fits within one TDD-disciplined
session without compromising the regression suite. The unimplemented
portion is documented as future work with detailed algorithm sketches
and references in `docs/improvement-proposals.md`.
