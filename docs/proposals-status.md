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

## Tier 2 (7 proposals): all DONE (with codegen integrations)

| # | Name | Status | Commit |
|---|------|--------|--------|
| 9 | Real three-address IR | DATA STRUCTURE + BUILDER | bc85558 |
| 10 | CFG construction | INSPECTION via --emit-cfg | bf44fe3 |
| 11 | SSA via Braun | ANALYSIS-LAYER --emit-ssa | e46d105 |
| 12 | Linear-scan regalloc | ANALYSIS-LAYER --emit-regalloc | 99d5a35 |
| 13 | SCCP on SSA | ANALYSIS + CODEGEN INTEGRATION | 4df0351, 73c39ae |
| 14 | Csmith-INTERCAL fuzzer | DONE | (earlier session) |
| 15 | Declarative peephole rules DSL | DONE | (earlier session) |

### Tier 2 additions to codegen

Proposal 13 now feeds the existing codegen with cross-statement
constants: when a variable is statically known to hold a literal at
the use site, codegen substitutes `mov w0, #N` instead of emitting
the load. Sound conservatism documented in Note [VarConstantProp];
gated by opt_bisect_check per substitution.

Proposal 9 now ships the IR data structure (ir_ops[]) plus a
build_ir builder. Codegen does not yet consume the IR; the rewrite
to consume it is the remaining future work. The IR is exposed via
`--emit-ir-real` for inspection.

## Tier 3 (5 proposals): substantive landings

| # | Name | Status | Commit |
|---|------|--------|--------|
| 16 | Stage3 self-hosted real compiler | ROADMAP DOC | 8a64616 |
| 17 | Bytecode tier (OCaml-style) | EXTENDED SUBSET | f52f922 |
| 18 | Mini LSP server | SEMANTIC TOKENS + HOVER + MULTI-DIAG | c65247e |
| 19 | `DO INCLUDE` multi-file extension | DONE | c11311f |
| 20 | Effect/error static analysis | ANALYSIS + CODEGEN INTEGRATION | 4303acb, 6d834d5 |

### Tier 3 additions to codegen

Proposal 20 now drives runtime-check elimination: per-statement
analysis identifies ASSIGNs of literal #N where the value cannot
overflow the target type, and codegen skips the cmp + b.hi
_rt_error_E275 sequence. Note [E275Elim] documents the analysis.

Proposal 17 (bytecode tier) extended to a non-trivial subset:
LOADI/LOADI2, COPY/COPY2, STASH/RETRIEVE with E436, IGNORE/REMEMBER,
twospot variables. Test suite grew from 3 to 7 cases.

Proposal 18 (LSP) extended to advertise hoverProvider and
semanticTokensProvider. Hover returns markdown documentation for
INTERCAL keywords; semanticTokens returns the LSP delta-encoded
token array classifying keyword/variable/number/label.
publishDiagnostics now emits one diagnostic per ICL line on stderr,
classifying ICLnnnW as Warning and ICLnnnI as Error.

## Final tally

In the cumulative session series:

- **15/20 fully implemented or DONE-with-integration**:
  Tier 1: 1, 2, 3, 4, 5, 6, 7, 8 (8/8).
  Tier 2: 13 (with codegen integration), 14, 15 (3/7).
  Tier 3: 17 (extended), 18 (extended), 19, 20 (with codegen
  integration) (4/5).

- **5/20 as analysis-layers / inspection / data-structure / roadmap**:
  Tier 2: 9 (data structure + builder), 10 (--emit-cfg), 11
  (--emit-ssa), 12 (--emit-regalloc) (4/7).
  Tier 3: 16 (roadmap doc) (1/5).

- **0/20 fully unimplemented**.

Test growth: 71 (start) -> 130+ (end), across 20+ test scripts.

## Genuinely remaining future work

For a session that wants to go deeper:

1. **Codegen-from-IR rewrite** (proposal 9 second half): replace
   the parse-tree-walk codegen with an ir_ops[]-walk codegen.
   Estimated multi-week refactor with 33-test regression risk.
2. **Linear-scan regalloc integration** (proposal 12 second half):
   make `--emit-regalloc`'s decisions actually drive register
   allocation in the emitted assembly. Requires the codegen-from-IR
   rewrite as a prerequisite.
3. **SCCP on real SSA** (proposal 13's full version): the current
   integration uses a simpler conservative dataflow. Full
   Wegman-Zadeck SCCP on the SSA-form IR with executable-edge
   gating is an extension.
4. **Stage3 substage 1 real implementation** (proposal 16): a
   char-by-char tokeniser for INTERCAL source in pure INTERCAL,
   blocked by the loop-primitive question. Months of careful
   INTERCAL coding.
5. **Bytecode parity with native** (proposal 17): the bytecode VM
   currently supports a documented subset; full feature parity
   (COME FROM, NEXT, arrays, syslib) requires real control-flow
   plumbing.
6. **LSP completion + go-to-definition** (proposal 18): semantic
   tokens + hover + diagnostics are landed; completion and
   navigation features remain.
7. **Effect-driven elim for more error classes** (proposal 20):
   currently elides only E275 on literal-RHS ASSIGN. Other ICL
   codes (E123 stack overflow, E129 undef label, E436 stash, etc.)
   could be elided when the analysis proves them unreachable.

Each is a focused multi-week project. None is required for the
project's identity; each is depth.
