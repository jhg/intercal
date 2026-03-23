# TODO - Working notes

## Estado actual (2026-03-24)

### Phase 1.5 (Bootstrap Hardening) - EN PROGRESO

Steps completados:
- [x] Step 1-3: 12 nuevos tests, overbar, fix parse_var_list (22/22 -> 23/23)
- [x] Step 4a: Runtime y syslib nativo extraidos a .s independientes
  - runtime_macos_arm64.s (650 lines) + symlink runtime.s
  - syslib_native_macos_arm64.s (311 lines) + symlink syslib_native.s
  - intercalc.sh reducido de 2585 a 1656 lines
- [x] Step 4b: Label 666 syscall extension (8 syscalls: open/read/write/close/argc/argv/exit/getrand)
  - test_syscall_readself.i: programa que lee su propio source via 666
  - 23/23 tests pasando
- [x] Step 5-6: --pure-syslib flag + syslib.i inicial
  - syslib.i tiene labels 1009, 1000, 1010, 1020, 1520, 1900, 1910, 1999
  - KNOWN BUG: addition (1009) produce 0 para inputs > 2 bits. Funciona para 1-bit y 2-bit.
    El algoritmo bit-by-bit es correcto (verificado inline). El bug es en como las expressions
    se parsean cuando syslib.i se appends al source via --pure-syslib. Debugging en progreso.
  - Native syslib sigue siendo el default y funciona perfectamente
- [x] Fix tokenizer: DON'T reconocido como keyword (antes se mergeaba con stmt anterior)

Steps pendientes:
- [ ] Step 5: Fix syslib.i bug (addition produces 0 at scale)
- [ ] Step 5: Completar syslib.i (falta 1030/1039/1040/1050/1500-1550)
- [ ] Step 7: test_syslib_pure.sh verification
- [ ] Step 8: Actualizar AGENTS.md y .gitignore

### Phase 2 (Self-Hosted Compiler) - PENDIENTE

Ver plan en .claude/plans/cheerful-jingling-sketch.md

### Phase 3 (GitHub Workflows) - PENDIENTE

## Arquitectura actual

Chispa primigenea (trio de archivos):
- intercalc.sh (1656 lines) - lexer, parser, codegen
- runtime.s -> runtime_macos_arm64.s (650 lines) - runtime ARM64 + Label 666
- syslib_native.s -> syslib_native_macos_arm64.s (311 lines) - syslib nativo

Pipeline: `cat runtime.s syslib_native.s <(asm del programa) | cc -x assembler - -o binary`

Label 666 syscalls: .1=numero, .2=fd/param, .3=resultado, .4=secundario, ,65535=buffer
