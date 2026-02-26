# TODO - Working notes

## Estado actual (2026-02-27)

- AGENTS.md actualizado: arquitectura, bootstrap strategy, syscall extension, viabilidad
- Decidido: three-phase bootstrap (shell → INTERCAL → improvement cycle)
- Target: macOS arm64
- Syscall mechanism: Label 666 (inspirado en CLC-INTERCAL)
- No se ha escrito codigo aun

## CLC-INTERCAL Investigation (COMPLETADO)

Resultado: `/Users/jesus/Repos/intercal/666.md`

**Key Findings**:
- CLC-INTERCAL uses label 666 for syscalls via hidden "PLEASE NEXT FROM (666)"
- Parameter passing: "call by vague resemblance to last assignment" (%OS binding) - deliberadamente obscuro
- Only syscall #1 (version info) is publicly documented
- Full syscall list NOT publicly available (reverse-engineering required)
- **Decision**: NO retrocompatibility con CLC-INTERCAL

**Plan adjustment**:
- Fase 1 (bootstrap shell): stdin/stdout filter, sin syscalls
- Fase 2 (compilador INTERCAL): syscalls propios simplificados (no CLC-compatible)

## Plan de fases

### Fase 1: Shell script bootstrap (`intercalc.sh`)
Compilador shell que funciona como filtro stdin/stdout: `intercalc.sh < source.i > binary`

- [ ] Disenar arquitectura del compilador (lexer, parser, codegen, linker)
- [ ] Implementar lexer/parser en bash/zsh
- [ ] Implementar codegen (machine code generation para arm64)
- [ ] Implementar runtime en ensamblador arm64 (embebido, mínimo)
  - [ ] I/O routines (READ OUT, WRITE IN, Roman numerals, Turing Text Model)
  - [ ] Memory management (array allocation, STASH stacks)
  - [ ] Random source (via /dev/urandom)
  - [ ] Process exit handling
  - [ ] (NO syscall handler en Fase 1 — simplificar)
- [ ] Soporte para syslib (auto-include labels 1000-1999)
- [ ] Politeness checking
- [ ] Error reporting
- [ ] Testing con hello world y ejemplos basicos

### Fase 2: Compilador INTERCAL (self-hosted) + Syscalls propios
- [ ] Disenar mecanismo de syscalls simplificado (inspirado en Label 666, no CLC-compatible)
- [ ] Escribir compilador en INTERCAL (usando intercalc.sh como bootstrap)
- [ ] Compilador genera binarios con runtime que soporte syscalls
- [ ] CLI normal: `./intercal program.i -o output`
- [ ] Documentar completamente: qué syscalls, qué parámetros, qué retorna

### Fase 3: Iteración
- [ ] Optimizaciones
- [ ] Nuevas features
- [ ] GitHub workflow (bootstrap → compile → test → release)

## Proximo paso inmediato

1. Disenar la arquitectura de intercalc.sh (lexer, parser, codegen, linker)
2. Empezar a escribir intercalc.sh
