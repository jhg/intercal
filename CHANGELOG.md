# Changelog

All notable changes to the intercal compiler are recorded here. The format
loosely follows Keep a Changelog; the project does not yet use SemVer
across feature releases. Tagged releases (v0.1.0+) are listed under their
tag; in-progress work appears under "Unreleased".

## Unreleased

### Added

- NEXT FROM loop primitive (`(LABEL) NEXT FROM` and the conditional
  `(LABEL) NEXT FROM <expr>`). A backward branch with no NEXT-stack push,
  borrowed from CLC-INTERCAL. Documented in `docs/loop-extension.md`.
- LSP server v0.3.0: `textDocument/completion` (keywords + variables +
  labels) and `textDocument/definition` (label-reference resolution).
- Bytecode tier with full arithmetic operators (mingle, select, unary
  AND/OR/XOR), STASH/RETRIEVE, IGNORE/REMEMBER, twospot variables.
- Effect-driven elimination extended to E621 (RESUME #N) and E436
  (RETRIEVE without prior STASH). Each elision is opt-bisect-gated.
- Cross-statement constant propagation through chain copies (#5 → .1 →
  .2 → .3 yields `mov w0, #5` at every use). See Note [VarConstantProp].
- IR-driven codegen migration scaffold: `INTERCAL_NEW_IR=1` routes
  supported statement types through a new lowering path while falling
  back per-type to the legacy tree-walk codegen. First slice covers
  `GIVE_UP` on all three platforms.
- Linear-scan decisions exposed to codegen: `INTERCAL_REGALLOC_HINTS=1`
  emits `// regalloc: spot_N -> R<n>` comments at variable assignment
  sites for future register-keeping work.
- Wegman-Zadeck SCCP behind `--emit-sccp-wz`: faithful executable-edge
  gating, CFG worklist, monotone meet at confluence points,
  TOP/CONST/BOTTOM lattice. Models syslib 1009/1010/1020/1030 add/sub
  and includes COME FROM source edges in the predecessor map.
- `--emit-opt-summary`: diagnostic dump showing the cumulative effect
  of every static analysis pass (counts of E275/E621/E436 elisions,
  abstain-flag eliminations, constant-propagation entries).
- IR-driven codegen now handles literal-RHS ASSIGN and var-to-var
  copy through `lower_ir_for_stmt`. Per-statement-type fallback
  unchanged.
- E275 elision recognises spot-to-twospot widening (always safe) and
  SCCP-bounded var copies. `compute_var_constants` now runs before
  `compute_e275_safety` so the latter can consult the constant map.
- LSP server v0.4.0: `textDocument/documentSymbol` for outline view.
  Editors render labelled statements in the document outline panel.
- LSP hover docs cover COME FROM, READ OUT, WRITE IN, FROM keywords.
- `docs/learning-by-extending.md`: a guided tour of three landings from
  this session, each chosen to mirror a different shape of
  production-compiler work (frontend feature, IR migration, dataflow
  algorithm).

### Fixed

- Audited and patched 31 instances of the latent
  declare-then-for-loop zsh quirk in `intercalc.sh`,
  `intercalc_vm.sh`, and `intercal_lsp.sh`. The bug class fired
  three separate times in this session before the audit; the fix
  prepends an empty assignment so the loop variable is initialised
  on the declaration line rather than at the for-loop init.
- LSP `$'\n'`-inside-parameter-expansion bug: the document text
  unescape was producing literal `$'\n'` 4-char sequences instead
  of real newlines, silently corrupting multi-line documents on
  every didOpen/didChange. Fixed by hoisting the newline to a
  local variable. This was load-bearing for documentSymbol,
  semantic tokens, and hover position calculations.
- `emit_sccp_wz` was unconditionally enqueuing the next statement
  as a successor of GIVE_UP and unconditional NEXT_FROM, which
  marked dead code as executable. Fixed; new test covers
  dead-code-after-GIVE_UP.
- E436 conservative analysis treats NEXT FROM as a control-flow
  stopper for STASH/RETRIEVE soundness.
- `check_unreferenced_labels` now treats NEXT FROM as a label
  reference, so labels used only by NEXT FROM are not flagged as
  unreferenced.
- `compute_var_constants` disables globally on NEXT FROM (backward
  branches break SCCP-style forward propagation).

### Documentation

- man page (`man/intercal.1`): documents `INTERCAL_NEW_IR`,
  `INTERCAL_REGALLOC_HINTS`, and `--emit-sccp-wz`.
- `docs/proposals-status.md`: 2026-05-09 session deltas table; the
  "remaining future work" section rewritten as continuations of
  what landed.
- `docs/SUMMARY.md`: registers `loop-extension.md` and
  `learning-by-extending.md` under Advanced techniques.

## v0.1.0 — 2026-05-08

### Added

- Phase 1 bootstrap compiler (`intercalc.sh`) complete.
- Phase 2 self-hosted MVP (`compiler.i`, template-passthrough).
- Stage 3 evolving compiler scaffolding (`stage3.i`, byte probes).
- 11-chapter Part VII bridge (LLVM, GCC, rustc, Go, GHC, OCaml,
  Cranelift, Zig, Swift, V8, plus the bridge chapter).
- 3-platform CI matrix (macOS-14, ubuntu-24.04-arm,
  ubuntu-latest).
- Release workflow producing 9 artifacts on `v*` tags.
- `--emit-cfg` and `--emit-3addr` inspection flags.

For the complete v0.1.0 feature set see `memory/project_status.md`.
