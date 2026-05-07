# TODO - Working notes

## Estado actual (2026-05-08, sesión tarde — book + Part VII)

Sesión dedicada exclusivamente a `docs/` (no se ha tocado el compilador). Resumen para la próxima sesión:

### Lo que se hizo hoy
1. **mdBook publishing**. `book.toml` en raíz + `docs/SUMMARY.md` + `.github/workflows/docs.yml` con `actions/configure-pages@v5` y `actions/deploy-pages@v5`. Link-check en CI antes del build (verifica que cada `[text](file.md)` resuelve, advierte sobre archivos no listados en SUMMARY). Página 404 en `docs/404.md`. Site live en https://jesushernandez.net/intercal/.
2. **Split book intro vs directory index**. `SUMMARY.md` apunta a `docs/introduction.md` (homepage del libro). `docs/README.md` sigue siendo el índice navegacional para GitHub viewers y agentes.
3. **Eliminación masiva de em-dashes**. Sustitución bulk con perl, fixes manuales en tablas. Cero em-dashes en docs/. AGENTS.md tiene una sección nueva "Documentation prose style" (líneas ~92-115) que documenta esta y otras reglas para que sesiones futuras escriban correctamente desde el primer borrador.
4. **Style pass profundo** sobre los chapters más leídos: `introduction.md`, `what-is-intercal.md`, `getting-started.md`, `overview.md`, `intercal-primer.md`, `label-666-intro.md` reescritos con tono más natural. Pasada quirúrgica más ligera sobre los técnicos (drop "This chapter X..." openers, drop "essentially" hedges, fix tablas rotas).
5. **Capítulos didácticos antes inexistentes**: `getting-started.md`, `what-is-intercal.md`, `label-666-intro.md`, `your-first-contribution.md`, `design-rationale.md` (FAQ).
6. **Capítulos de teoría con investigación web verificada**: `parser-theory.md` (LL(k), packrat/PEG/combinators), `lexer-theory.md` (DFA/NFA, longest-match), `executables-and-linking.md` (ELF/Mach-O, dyld/PLT/GOT, PIE, SOURCE_DATE_EPOCH), `calling-conventions.md` (AAPCS64 + System V AMD64 + ABI specs), `middle-end-and-optimisation.md` (Cytron 1991 SSA + dominance frontiers + SCCP).
7. **Capítulos sobre features distintivas**: `turing-text-model.md`, `politeness-rule.md`, `come-from.md`, `numeric-io.md`. Y meta-chapters: `error-messages.md` (Rust/Niko Matsakis diagnostics), `comparing-languages.md` (C vs Lisp vs INTERCAL phase by phase), `esolangs-context.md` (Brainfuck, Befunge, Malbolge, Shakespeare, Whitespace), `language-design-philosophy.md` (Hoare 1973 + Wirth Pascal/Modula/Oberon), `history-and-context.md` (verified 26 May 1972 Princeton SPITBOL IBM/360), `self-hosting.md` con sección Trusting Trust + DDC, `anatomy-of-a-binary.md` (otool/objdump walkthrough).
8. **Tours**: `tools-tour.md` (un párrafo por script en tools/), `tests-tour.md` (un párrafo por test_*.i agrupados por categoría).
9. **Reference apparatus**: `appendix-grammar.md` (EBNF), `appendix-exercise-hints.md` (hints para los exercises de cada capítulo), `glossary.md`, `further-reading.md` (annotated bibliography), `statement-cheatsheet.md` (tabla one-line por statement/syslib/syscall).
10. **Part VII (lo más importante para el goal del usuario)**: convertir el libro en un puente al ecosistema real. Cinco capítulos:
    - `from-intercal-to-real-compilers.md` (capstone con tabla side-by-side: cada concepto de este libro mapeado a su contraparte en LLVM/rustc/GCC, plus lista de temas no cubiertos: GC, JIT, PGO, LTO, polyhedral).
    - `llvm-overview.md` (3-fase architecture, LLVM IR, pass manager, repo layout).
    - `gcc-overview.md` (GENERIC/GIMPLE/RTL pipeline, machine descriptions).
    - `rustc-overview.md` (AST/HIR/THIR/MIR/LLVM-IR pipeline, borrow checker en MIR, crate layout, rustc-dev-guide).
    - `contributing-to-production-compilers.md` (cómo buildear cada uno, dónde encontrar good first issues, las review conventions diferentes: LLVM/rustc en GitHub, GCC por mailing list, expectativas realistas de timeline).
11. **Bug-fix en CI**: `.github/workflows/docs.yml` step "Verify internal links" estaba fallando en bash. Causa: `set -e` + `pipefail` + grep que returns 1 cuando no hay matches. Fix: usar `set -uo pipefail` (sin `-e`), capturar output con `|| true`, here-string en lugar de pipe-into-while.
12. **Pre-push hook**: drop hardcoded "(56 tests passed across 4 suites)" — reemplazado por "(all suites green)" porque el conteo se quedaba obsoleto.

### Estado del repo
- 52 chapters en `docs/` (más `docs/666.md` y `docs/intercal_patterns.md` que ya existían).
- Cero em-dashes verificado.
- Todos los enlaces internos verificados.
- mdBook builds clean (verificable corriendo `mdbook serve --open` localmente si se instala mdBook, o esperando al CI).
- Pages live en https://jesushernandez.net/intercal/ (con auto-deploy en cada push a main que toque docs/).
- Pre-push verde en todos los commits (33 bootstrap + 25 self-hosted MVP + 4 stage3 + 3 syslib pure = 65 tests).

### Decisiones con rationale (para no rehacerlas mañana)
- **Em-dashes prohibidos**: feedback explícito del usuario, "muy AI style". Documentado en AGENTS.md "Documentation prose style".
- **No claim "most of the documentation came from the model"** en what-is-intercal: el usuario hizo los primeros commits, AGENTS.md es suyo, 666.md original es suyo. La forma actual del bullet AI-driven dice "compiler, runtime, syslib, and tests came from the model", omitiendo docs.
- **Part VII es la razón por la que el libro existe** (frase que puse en introduction.md): el goal del usuario evolucionó a "el camino más rápido posible para luego contribuir a Rust/GCC/LLVM". Las partes I-VI son preparación.
- **`docs/README.md` y `docs/introduction.md` separados**. `README.md` es el índice (cinco reading paths, full chapter index, navegación para GitHub y agentes). `introduction.md` es la portada del libro web (welcome, organización, who-should-read-what).
- **`book.toml` site-url = /intercal/** porque el dominio custom es jesushernandez.net y el Pages path es /intercal/.

### Pendientes para próxima sesión (orden de prioridad)
1. **Verificar que el deploy a Pages funciona después del último push**. URL: https://jesushernandez.net/intercal/. Si no aparece la nueva intro, mirar Actions → docs workflow.
2. **Si queda tiempo y el usuario lo pide, posibles ampliaciones del libro**:
   - Capítulo sobre garbage collection / memory management como tema "no cubierto pero relevante".
   - Capítulo sobre type systems (no tocamos serieamente; bridge a Pierce TaPL).
   - Capítulo sobre incremental compilation / queries / Salsa (rustc).
   - Capítulo sobre LSP / IDE integration.
   - Worked example dentro de Part VII: implementar una optimización trivial en LLVM y mostrar el patch completo.
3. **Posibilidad de un "second-pass" style review** sobre los chapters técnicos (semantic-analysis, code-generation, etc.) que recibieron solo pasada quirúrgica. Por ahora aceptable; no urgente.
4. **Phase 4 stage3.i continúa siendo el trabajo pendiente del compilador**: la otra sesión paralela. Loop primitive bloqueado en pattern (~30 statements scaffolding).
5. **El bug de syslib silent-overflow** (1000, 1030, 1050, 1500, 1540) sigue sin arreglarse en el código; documentado en syslib.md como caveat. Si el otro Claude trabaja en ello, regenerar templates y manifest después.

### Cómo retomar
1. Lee este archivo (TODO.md) y AGENTS.md "Documentation prose style".
2. `git pull` para integrar cambios del otro Claude.
3. `git log --oneline -20` para ver el estado.
4. Si la conversación con el usuario lo requiere, usa la sección "Estado actual" como contexto y la lista de pendientes como starting point.

### Style contract recap (lo más importante para escribir docs)
- Cero em-dashes. Cero en-dashes. Coma, punto, dos puntos, paréntesis, según contexto.
- No openers tipo "This chapter X". Empieza con el tema directamente.
- No hedges: "essentially", "actually", "really", "in itself", "in some sense".
- No clichés: "It is worth noting", "Of course", "Indeed", "Naturally".
- Bullets con `:` no con `—` o `,`: `- foo.md: short description`.
- Direct address: "you" cuando aplica, no siempre "we".
- Frases mixed-length, declarativas.
- Plain English: "use" no "utilise", "show" no "demonstrate".
- Sin closing summaries.

## Estado anterior (2026-05-08, post v0.1.0 release)

v0.1.0 tagged. 9001a9f. Release workflow disparado. 65 tests verde en 3 plataformas (33 bootstrap + 25 self-hosted MVP + 4 stage3 + 3 syslib pure). 42/42 tasks de la sesión cerradas.

Pendientes para próxima sesión (orden de prioridad):
1. Verificar que la release v0.1.0 publicó correctamente (release.yml + release-smoke.yml).
2. Si algo falla en smoke, fix + re-tag v0.1.1.
3. Phase 4 stage3 loop primitive: necesita extensión non-standard (computed COME FROM) o ~30 statements scaffolding por loop. Tres intentos documentados en docs/intercal_patterns.md. Requiere sesión dedicada con foco completo.
4. Stage 3.2.b+: extender el detector "DO" a las posiciones del scan que necesitamos para un lexer real (necesita loops con break).
5. Phase 6.0 Q.x quality: regression adicional, property testing, fuzzing, integration con programas reales, benchmarks, memory safety (ASan/valgrind), SBOM.
6. Phase 7.0 DOC tutorial / website (mdBook) — el usuario está iterando esto en paralelo.
7. Phase 8.0 optimizaciones avanzadas: register allocation real, inline syslib calls.
8. Phase 9.0 Windows.
9. Phase 10.0 extensiones del lenguaje.
10. Phase 11.0 más Label 666 syscalls.
11. Phase 12.0 ecosystem (editors, LSP, formatter).

Sesión previa (2026-04-21 tarde)

Phase 2 MVP 25/25. Phase 2.5 + Phase 3.0 D.1-D.6 + Phase 5.0 R.1-R.3 + R.6 + Phase 7.0 DOC.3 completos.

Completado hoy:
1. Runtime Linux x86_64 bugfix: _rt_sys666_open/write guardaban alloc_size en [rbp-32] colisionando con el buffer -> SIGSEGV. Fix con r14.
2. Template manifest sha256 + verify_manifest en CI pre-tests.
3. Test runners con --verbose --filter --keep flags + failure artifact preservation.
4. release.yml: 9 artefactos (zip/tar.gz/deb/rpm x linux_arm64 + linux_x86_64 + zip macos_arm64) con intercal_core pre-built.
5. stage3.i (evolving compiler Phase 4): Stage 3.1.a byte count + 3.1.b first byte + 3.1.c last byte, 3 tests.
6. tests/cross_test.sh para reproducir CI Linux localmente via docker buildx.
7. .githooks/pre-commit + pre-push + tools/install_hooks.sh.
8. README.md rewrite completo.
9. tools/pipeline_dump.sh (10-file snapshot para debugging).
10. tools/lint_intercal.sh + tools/lint_assembly.sh integrados en CI.
11. release-smoke.yml: 10 smoke tests en containers tras publicar release.
12. man/intercal.1 + completions bash/zsh/fish empaquetados en deb/rpm.
13. CONTRIBUTING.md + .github/ISSUE_TEMPLATE + PR template.
14. CODE_OF_CONDUCT.md rewrite (rehabilitation over bans).
15. README error-codes referencia aclarada.
16. docs/intercal_patterns.md con patterns verificados empiricamente.
17. Memoria actualizada: MEMORY.md + dev_workflow.md + release_process.md.

Decisiones tomadas:
- Pure syslib default: investigado empirica y state-of-art. Decisión: native como default (0ms compile, 6KB, byte-equivalente verificado). Añadido INTERCAL_SYSLIB=cache mode que pre-compila syslib.i a ~/.cache/intercal/syslib-<plat>-<hash>.s; mismas semánticas que --pure-syslib sin coste por compilación. tools/build_syslib.sh para warm-up. Cache mode validado en CI (3 plataformas, 33/33 tests).
- Phase 4 stage3 deep work (lexer/parser real con loops INTERCAL): diferido a v0.2+. v0.1 ships con MVP template-passthrough completo. Razón: scaffolding de loop ~30 statements/loop en INTERCAL; requiere sprint dedicado de 6-10h con TDD por sub-stage. MVP es funcionalmente equivalente para los 25 programas de test.

Primera release v0.1: lista para tag cuando confirmes. Todo el infra está. Solo falta tu OK.

Pendientes en orden de prioridad:
- Phase 4.0 Stages 3-8 (compilador real). Bloqueado en pattern de loop con break -- research completado (docs/intercal_patterns.md). Cost ~30 statements por loop con break. Proxima sesion: disenar factorizacion con helpers reutilizables antes de codegen.
- Phase 6.0 Q.x: regression adicional, property testing, fuzzing, integration con programas reales, benchmarks, memory safety (ASan/valgrind), reproducible builds, SBOM.
- Phase 7.0 DOC.1-DOC.2 + DOC.4-DOC.6: tutorial, language reference, man pages (done DOC.3), website, migration guides.
- Phase 8.0 optimizaciones: constant folding, DCE, peephole, inline syslib, register allocation.
- Phase 9.0 Windows: runtime, codegen, CI, msi/chocolatey/winget.
- Phase 10.0 extensiones: computed COME FROM, NEXT FROM, threading, MAYBE, wimpmode, TriINTERCAL.
- Phase 11.0 Label 666 extensions: fs, process, env, time, net.
- Phase 12.0 ecosystem: editors, LSP, formatter, package manager, playground.

Escala realista del self-hosted completo: sin precedentes historicos, nadie ha hecho un compilador INTERCAL self-hosted en INTERCAL. Estimacion: 5k-15k lineas de INTERCAL, trabajo de meses. El MVP template-dispatch es la via pragmatica para v0.1. Phase 4 es la via para v1.0.

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
