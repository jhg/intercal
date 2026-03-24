# TODO - Working notes

## Estado actual (2026-03-24)

### Phase 1.5 - COMPLETADO

- [x] Steps 1-3: 12 nuevos tests, overbar, fix parse_var_list
- [x] Step 4a: Runtime y syslib nativo en .s independientes
- [x] Step 4b: Label 666 syscall extension (8 syscalls)
- [x] Step 5-6: syslib.i completo (9065 lines, 20 labels), --pure-syslib flag
- [x] Step 7: test_syslib_pure.sh verificacion (native == pure)
- [x] Step 8: .gitignore, TODO.md actualizados
- [x] Fix tokenizer: DON'T como keyword
- [x] Fix ldrb offset overflow para programas >4096 stmts
- 25/25 tests pasando

### Phase 2 (Self-Hosted Compiler) - PENDIENTE

Siguiente paso: crear compiler.i (compilador INTERCAL en INTERCAL)
- Stage 1: I/O round-trip via Label 666
- Stage 2: Lexer
- Stage 3: Parser
- Stage 4: Semantica
- Stage 5-7: Codegen incremental
- Stage 8: Fixpoint 3 generaciones

### Phase 3 (GitHub Workflows) - PENDIENTE

## Arquitectura

Chispa primigenea:
- intercalc.sh (1656 lines) - lexer, parser, codegen
- runtime.s -> runtime_macos_arm64.s (900+ lines) - runtime + Label 666
- syslib_native.s -> syslib_native_macos_arm64.s (311 lines)

syslib.i (9065 lines) - INTERCAL puro para --pure-syslib
