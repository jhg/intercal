# TODO - Working notes

## Estado actual (2026-03-24)

CI: 3/3 jobs GREEN (macOS ARM64, Linux ARM64, Linux x86_64) - 25/25 tests cada uno

### Completado

- Phase 1: src/bootstrap/intercalc.sh (1660 lines, 25/25 tests)
- Phase 1.5: runtime .s separation, Label 666, syslib.i (9065 lines), --pure-syslib
- Phase 3: CI workflows (3 plataformas), release workflow (.zip, .tar.gz, .deb)
- Multi-platform: macOS ARM64, Linux ARM64, Linux x86_64
- Security audit: SECURITY.md
- Code organization: src/ directory structure, no symlinks

### En progreso

- Phase 2: compiler.i Stage 2 de 8 (I/O + copy/uppercase/length)
  - Stage 3 (lexer) es el proximo paso
  - Ver docs/PHASE2.md para detalle de cada stage

### Pendiente

- compiler.i Stages 3-8
- bootstrap.sh funcional (requiere compiler.i Stage 8)
- Release automatico (workflow listo, falta tag)
- RPM packaging

## Estructura del proyecto

```
src/
  bootstrap/     intercalc.sh, codegen_x86_64.sh
  runtime/       macos_arm64.s, linux_arm64.s, linux_x86_64.s
  syslib/        syslib.i + native/ (3 plataformas)
  compiler/      compiler.i (Stage 2/8)
docs/            666.md, PHASE2.md
tests/           25 test files + runners
SECURITY.md      security audit
AGENTS.md        main project documentation
```
