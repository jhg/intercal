# TODO - Working notes

## Estado actual (2026-04-21)

Phase 2 MVP en marcha. compiler.i es un dispatcher basado en cksum:
- 25 templates x 3 plataformas = 75 archivos bajo src/compiler/templates/
- Wrapper ./intercal hace cksum del source y selecciona el template
- intercal_core (compiler.i compilado por bootstrap) lee el template y lo emite
- Tests: 22/22 self-hosted pasan (faltan politeness_rude, politeness_polite, syscall_readself)

Bootstrap sigue siendo el compilador REAL. 25/25 tests bootstrap + 3/3 syslib pure + 22/22 self-hosted MVP.

Escala realista del self-hosted completo (investigada): sin precedentes historicos, nadie ha hecho un compilador INTERCAL self-hosted en INTERCAL. Estimacion: 5k-15k lineas de INTERCAL, trabajo de meses. El MVP template-dispatch es la via pragmatica. Evolucion posible: implementar lexer y codegen real en INTERCAL para sustituir la dispatch por cksum.

## Estado previo (2026-03-24)

CI: 3/3 jobs GREEN (macOS ARM64, Linux ARM64, Linux x86_64) - 25/25 tests cada uno

### Que es este proyecto

Un compilador de INTERCAL self-compiled. El compilador compila INTERCAL source (.i) a binarios nativos ARM64/x86_64. La meta es que el compilador pueda compilarse a si mismo (bootstrap).

### Que esta completado

Phase 1 - Bootstrap compiler (src/bootstrap/intercalc.sh):
- Compilador shell (1660 lineas zsh) que lee INTERCAL de stdin, genera ARM64 assembly, lo concatena con runtime.s y syslib_native.s, y lo pasa a cc para producir un binario nativo
- Para x86_64 Linux: carga codegen_x86_64.sh que override las funciones de codegen con x86_64 assembly
- Para ARM64 Linux: aplica conversion sed del assembly generado (section names, relocations, syscall numbers)
- 25/25 tests pasando en 3 plataformas
- Soporta todas las 14 sentencias INTERCAL, expresiones, arrays, TTM I/O, Roman numerals

Phase 1.5 - Hardening:
- Runtime separado por plataforma en src/runtime/{macos_arm64,linux_arm64,linux_x86_64}.s
- Syslib nativo separado en src/syslib/native/{platform}.s
- syslib.i (9065 lineas): syslib completo en INTERCAL puro con 20 labels (add, sub, mul, div, 16/32-bit, random via Label 666)
- --pure-syslib flag para usar syslib.i en vez del nativo (verificado: resultados identicos)
- Label 666 syscall extension: 8 syscalls (open, read, write, close, argc, argv, exit, getrand)
- ,65535 reservado como buffer de datos para Label 666
- DON'T reconocido como keyword del tokenizer
- Fix ldrb offset overflow para programas >4096 statements
- Security fixes: write bounds check en ,65535, stash overflow guard

Phase 3 - CI/CD:
- ci.yml: 3 jobs (macOS ARM64 macos-14, Linux ARM64 ubuntu-24.04-arm, Linux x86_64 ubuntu-latest)
- release.yml: builds .zip (macOS), .tar.gz + .deb (Linux), release via REST API

Phase 2 - Self-hosted compiler (src/compiler/compiler.i):
- Stage 1 COMPLETE: I/O round-trip (lee archivo via Label 666, escribe a stdout)
- Stage 2 COMPLETE: copia source a ,10 con uppercasing, output source length como Roman numeral

### Que falta

Phase 2 Stages 3-8 (el grueso del trabajo pendiente):
- Stage 3: Lexer - escanear ,10 buscando DO/PLEASE/DON'T, contar statements, registrar boundaries en ,11-,12
- Stage 4: Parser - clasificar tipo de cada statement, parse expresiones en arbol ,20-,23
- Stage 5: Semantica - politeness check, labels, COME FROM resolution
- Stage 6: Codegen minimo - emitir assembly para GIVE UP (probar pipeline assembly completo)
- Stage 7: Codegen incremental - anadir un tipo de statement a la vez (ASSIGN, READ OUT, NEXT/RESUME, etc.)
- Stage 8: Fixpoint - compilar compiler.i consigo mismo, verificar que gen2 == gen3

Notas sobre Stage 3 (lexer):
- Se intento dos veces con agentes y ambas produjeron bugs (E000 y E123)
- El bug principal fue que syslib.i se prependia (ejecutando syslib antes del programa). Fix: appendear
- Otro bug: DON'T NOTE no se parseaba como keyword separado. Fix: tokenizer ahora reconoce DON'T
- El proximo intento debe ser cuidadoso, testeando incrementalmente

Post-fixpoint:
- Optimizaciones: constant folding, dead code elimination, peephole optimizer
- Release automatico con tag
- RPM packaging

### Estructura del proyecto

```
src/
  bootstrap/
    intercalc.sh              Compilador bootstrap (chispa primigenea, 1660 lineas)
    codegen_x86_64.sh         Backend x86_64 (955 lineas, sourced condicionalmente)
  runtime/
    macos_arm64.s             Runtime ARM64 macOS (966 lineas)
    linux_arm64.s             Runtime ARM64 Linux (conversiones: svc#0, openat, mmap 0x22)
    linux_x86_64.s            Runtime x86_64 Linux (Intel syntax, RIP-relative)
  syslib/
    syslib.i                  Syslib puro INTERCAL (9065 lineas, 20 labels)
    native/
      macos_arm64.s           Syslib nativo ARM64 macOS
      linux_arm64.s           Syslib nativo ARM64 Linux
      linux_x86_64.s          Syslib nativo x86_64 Linux
  compiler/
    compiler.i                Compilador self-hosted (Stage 2/8, 33 lineas)
docs/
  666.md                      Diseño de Label 666: analisis CLC-INTERCAL y decisiones
tests/
  run_tests.sh                Test runner (25 tests)
  test_syslib_pure.sh         Verificacion pure vs native syslib
  test_*.i                    25 programas de test
.github/workflows/
  ci.yml                      CI: 3 plataformas
  release.yml                 Release: .zip, .tar.gz, .deb
AGENTS.md (= CLAUDE.md)      Documentacion principal del proyecto
SECURITY.md                   Auditoria de seguridad
README.md                     Intro del proyecto
LICENSE                       Unlicense (dominio publico)
bootstrap.sh                  Bootstrap 3-generaciones (requiere Stage 8)
intercal                      Wrapper script para compilador self-hosted
setup_platform.sh             Deteccion de plataforma
```

### Lecciones aprendidas (bugs criticos resueltos)

Compilador:
- DON'T debe ser keyword del tokenizer (sino se merge con el statement anterior)
- PLEASE NOTE ejecuta como UNKNOWN (usar DON'T NOTE para comentarios)
- syslib.i debe appendearse al source (no prependearse, o se ejecuta primero)
- Expresiones: nunca anidar sparks dentro de sparks. Usar variables intermedias twospot
- syslib.i bit reconstruction: usar bit-reversal mingle (no naive hierarchical)
- --pure-syslib: no registrar labels syslib como "syslib_NNNN" (dejar que sean labels normales del source)

Multi-plataforma:
- GNU as ARM64: adrp NO necesita :pg_hi21: (lo infiere). Solo add necesita :lo12:
- sed: procesar @PAGEOFF ANTES de @PAGE (evitar match parcial)
- Linux mmap: flags 0x22 (no 0x1002 de macOS)
- Linux open: usar openat (syscall 56) con AT_FDCWD (-100)
- Linux error detection: valor negativo (no carry flag)
- .global: solo labels en columna 0 (funciones), no datos ni instrucciones con ':'
- x86_64: comentarios con # (no //), no three-register addressing [r12+r14+rcx]
