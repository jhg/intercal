# Cross-compiler cheatsheet

If you have worked on LLVM, GCC, rustc, or another production
compiler and want to find the matching concept here, this table is
the one-page index. Each row points to a file or symbol; the file
is the place to start reading.

## Front end

| Production-compiler concept | This compiler | File / function |
|-----------------------------|---------------|-----------------|
| Lexer / tokeniser | Inline tokeniser | `intercalc.sh:tokenize` |
| Parser | Inline statement classifier | `intercalc.sh:classify_statement` |
| AST | Parallel arrays per statement | `stmt_type[]`, `stmt_body[]`, `stmt_label[]`, ... |
| Expression tree | Parallel arrays per expression node | `expr_type[]`, `expr_left[]`, `expr_right[]`, ... |
| Diagnostics | `die_compile` / `print_warning` | `intercalc.sh` |
| Format-on-save | `tools/format_intercal.sh` | external |

## Middle end

| Production-compiler concept | This compiler | File / function |
|-----------------------------|---------------|-----------------|
| GIMPLE / MIR / Cranelift CLIF | Three-address IR | `build_ir`, `ir_ops[]` |
| SSA construction | Block-parameter SSA | `emit_ssa` (read-only dump) |
| Pass manager | Sequential `time_phase` calls | `intercalc.sh:main` |
| Constant propagation | SCCP-WZ + chain-copy var-const | `emit_sccp_wz`, `compute_var_constants` |
| Dead-code elimination | Per-statement abstain-flag DCE | `compute_flag_checks`, `stmt_needs_flag[]` |
| Register allocation | Linear-scan (Poletto-Sarkar) | `emit_regalloc`, `compute_regalloc_decisions` |
| Effect analysis | Per-statement ICL-code reachability | `emit_effects`, `stmt_e275_safe[]`, ... |
| Peephole | Sed-pass on emitted assembly | `intercalc.sh:peephole_optimize` |
| Optimisation bisect | `--opt-bisect-limit=N` | LLVM-style |

## Back end

| Production-compiler concept | This compiler | File / function |
|-----------------------------|---------------|-----------------|
| Instruction selection | Per-statement-type emit functions | `codegen_*` |
| Calling convention | INTERCAL has no functions; the convention is the syslib labels | `src/syslib/syslib.i` |
| Linker driver | `cc -x assembler -` | inline in `intercalc.sh` |
| Per-platform target | `src/runtime/{macos_arm64,linux_arm64,linux_x86_64}.s` | hand-written runtime |
| Assembler post-processing | sed (ARM64 macOS → Linux), separate codegen for x86_64 | inline in `intercalc.sh` |

## Tooling

| Production-compiler concept | This compiler | File / function |
|-----------------------------|---------------|-----------------|
| Compiler driver | `intercal` wrapper | shell script |
| Build system | None (single zsh script) | n/a |
| LSP | LSP v0.4.0 | `src/lsp/intercal_lsp.sh` |
| Linter | Static checks | `tools/lint_intercal.sh` |
| Formatter | Indent + uppercase | `tools/format_intercal.sh` |
| CI matrix | 3 platforms | `.github/workflows/ci.yml` |
| Differential testing | csmith-style program generator | `tools/csmith_intercal.sh` + `tests/run_csmith_diff.sh` |
| Bytecode tier | Stack VM | `src/bytecode/intercalc_bc.sh` + `intercalc_vm.sh` |

## Migration patterns

If you have done one of these in another compiler, this is where to
start in ours:

| You have done | Start reading |
|---------------|---------------|
| Added an LLVM IR opcode | `lower_ir_for_stmt` and the `case` in `codegen_statement` (NEXT_FROM was added the same way) |
| Added a GCC tree-ssa pass | `compute_*` analyses in `intercalc.sh` |
| Migrated a compiler from one IR to another (HIR → MIR; AST → GIMPLE) | `INTERCAL_NEW_IR=1` opt-in flag and `lower_ir_for_stmt`'s per-type fallback |
| Implemented Wegman-Zadeck SCCP | `emit_sccp_wz` — the algorithm in 200 lines |
| Built linear-scan regalloc | `emit_regalloc` (the algorithm) and `compute_regalloc_decisions` (the same algorithm without the trace, populating globals) |
| Wrote an LSP server | `src/lsp/intercal_lsp.sh` is one zsh file; jsonrpc framing is hand-rolled |

## Reading order

Three suggestions depending on your goal:

1. **Adding a feature.** Read `learning-by-extending.md` first. Then
   pick the smallest possible analogue from this cheatsheet and
   trace through it end to end.

2. **Understanding the codegen path.** Read `pipeline.md` →
   `code-generation.md` → `lower_ir_for_stmt` and follow the
   feature-flag fork from `codegen_statement`.

3. **Bridging to a production compiler.** Read the relevant Part VII
   chapter (LLVM, GCC, rustc, Go, GHC, ...) alongside the matching
   row in this cheatsheet. The shape of the change is the same; the
   diff size is two orders of magnitude larger but the steps map.
