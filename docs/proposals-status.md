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

## Updates in 2026-05-09 session

| # | Name | Status | Commit |
|---|------|--------|--------|
| 11 | IR-driven codegen | INCREMENTAL OPT-IN (`INTERCAL_NEW_IR=1`) | c1c8ac3 |
| 12 | Linear-scan integration | DECISIONS EXPOSED + HINTS (`INTERCAL_REGALLOC_HINTS=1`) | b2ea50d |
| 13 | Wegman-Zadeck SCCP | FULL ALGO behind `--emit-sccp-wz` | d3bde03 |
| 16 | Stage3 loop primitive | DECIDED (NEXT FROM, see docs/loop-extension.md) | bd008c9, b26b824 |
| 17 | Bytecode tier | + ARITHMETIC OPERATORS (mingle, select, unary) | ebc2d87 |
| 18 | LSP server v0.3.0 | + COMPLETION + GO-TO-DEFINITION | eacb5ef |
| 20 | Effect-driven elim | EXTENDED to E621 + E436 | 8724fba |

Substantive deltas:

- **NEXT FROM extension (#16)**: chose Option B (CLC-INTERCAL-style)
  over scaffolding or new ABSTAIN-loop syntax. Both unconditional
  and conditional forms emit a single `b` or `tbnz` with no
  NEXT-stack push, so finite loops are now sound (no E123 risk
  on the 80th iteration). docs/loop-extension.md captures the
  rationale; tests/test_next_from.i and tests/test_stage3_loop.i
  exercise a counter loop and a 5-byte array scan.

- **IR-driven codegen scaffold (#11)**: the legacy tree-walk path
  remains the source of truth. INTERCAL_NEW_IR=1 routes supported
  statement types through lower_ir_for_stmt() and falls back to
  legacy for unsupported types. Currently only GIVE_UP is wired
  through. The migration pattern is one statement type at a time,
  each gated independently, so future PRs can extend without
  disturbing the legacy path.

- **Regalloc hints (#12)**: compute_regalloc_decisions populates
  `var_reg[<varspec>]` and `var_spilled[<varspec>]`. With
  INTERCAL_REGALLOC_HINTS=1, codegen prefixes spot-variable stores
  with `// regalloc: spot_N -> R<n>` comments (visible in the
  intermediate assembly). Behavioural codegen change deferred.

- **Wegman-Zadeck SCCP (#13)**: emit_sccp_wz implements the proper
  worklist algorithm: TOP/CONST/BOTTOM lattice, executable-edge
  gating (exec_into[i] = 1 when an incoming edge is proven
  reachable), monotone meet at confluence points, and per-stmt
  outgoing[] tracking. The simpler emit_sccp linear-walk dump
  remains as a teaching variant.

## Genuinely remaining future work

For a session that wants to go deeper:

1. **Stage3 substage 1 wired into stage3.i** (proposal 16
   continuation): the loop mechanic is verified end-to-end in
   tests/test_stage3_loop.i; replacing the byte-probe scaffolding
   in src/compiler/stage3.i with a real tokeniser pass using
   NEXT FROM is the next stage. Substages 2-8 of the roadmap
   follow.
2. **IR-driven codegen for more statement types** (proposal 11
   continuation): extend lower_ir_for_stmt() to handle
   STASH/RETRIEVE/IGNORE/REMEMBER/READ_OUT, then ASSIGN. Each is
   independently guarded by INTERCAL_NEW_IR.
3. **Regalloc behavioural codegen** (proposal 12 continuation):
   when var_reg[X] is set and there's no intervening control-flow
   stopper between the def and the use, emit `mov w_dst, w<r>`
   instead of `ldr w_dst, [_spot_X]`. Requires a register-state
   cache that resets at every NEXT/COME FROM/RESUME boundary.
4. **SCCP-WZ extension to syslib results** (proposal 13
   continuation): currently arithmetic syslib calls collapse to
   BOTTOM. Modelling them in the lattice (e.g., 1009 of two
   constants is a constant) would feed the codegen-side
   const-prop. Also: COME FROM source edges are not yet in
   preds[], so the meet at COME FROM target sites is not full.
5. **Bytecode parity with native** (proposal 17): the bytecode VM
   has arithmetic operators but lacks COME FROM, NEXT, arrays.
   Each requires real control-flow plumbing in the VM dispatch.
6. **Effect-driven elim for more error classes** (proposal 20):
   already extended to E621 and E436. E123 (stack overflow), E129
   (undef label), E632 (resume past stack bottom) are candidates
   when static depth analysis is feasible.

Each is a focused multi-week project. None is required for the
project's identity; each is depth.
