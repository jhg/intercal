# TODO - Working notes

## Estado actual (2026-03-24)

### Completado

- Phase 1: intercalc.sh bootstrap compiler (1656 lines, 25/25 tests)
- Phase 1.5: runtime .s separation, Label 666 (8 syscalls), syslib.i (9065 lines), --pure-syslib
- Phase 3: CI workflows (macOS ARM64, Linux ARM64, Linux x86_64)
- Multi-platform: runtime y syslib para 3 plataformas
- Security audit: SECURITY.md con hallazgos y fixes
- codegen_x86_64.sh: backend x86_64 para Linux
- compiler.i Stage 1-2: I/O round-trip + copy/uppercase/length

### En progreso

- Linux ARM64 CI: debugging errores de assembly (relocations, syscall numbers, mmap flags)
- compiler.i Stage 3+: lexer y mas alla

### Pendiente

- compiler.i Stages 3-8: lexer, parser, semantica, codegen, fixpoint
- bootstrap.sh funcional (requiere compiler.i Stage 8)
- Release workflow con .deb/.rpm/zip
- Organizacion del codigo (src/ directory)

## Notas tecnicas

### Plataformas soportadas

| Plataforma | Runtime | Syslib | Codegen | CI |
|------------|---------|--------|---------|-----|
| macOS ARM64 | runtime_macos_arm64.s | syslib_native_macos_arm64.s | ARM64 (default) | macos-14 |
| Linux ARM64 | runtime_linux_arm64.s | syslib_native_linux_arm64.s | ARM64 + sed conversion | ubuntu-24.04-arm |
| Linux x86_64 | runtime_linux_x86_64.s | syslib_native_linux_x86_64.s | codegen_x86_64.sh | ubuntu-latest |

### Lecciones aprendidas

- GNU as en aarch64 Linux: `adrp` NO necesita `:pg_hi21:` (lo infiere), solo `add` necesita `:lo12:`
- mmap flags difieren: macOS 0x1002 vs Linux 0x22
- Linux usa openat (syscall 56) con AT_FDCWD (-100), no open
- .global solo para labels en columna 0 (funciones), no datos ni instrucciones
- DON'T NOTE para comentarios INTERCAL (PLEASE NOTE ejecutaria como UNKNOWN -> E000)
- Expresiones INTERCAL: nunca anidar sparks dentro de sparks, usar variables intermedias
- syslib.i: la reconstruccion de bits usa bit-reversal mingle, no mingle jerarquico naive
