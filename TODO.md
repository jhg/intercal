# TODO - Working notes

## Estado actual

- AGENTS.md documentado con: referencia del lenguaje, best practices, arquitectura, viabilidad
- Viabilidad confirmada: compilador self-compiled es posible via stdin/stdout como filtro
- No se ha escrito codigo aun

## Decisiones pendientes

- Revisar opciones de extensiones para I/O mas alla de stdin/stdout:
  - C-INTERCAL external calls (-e) para enlazar C
  - CLC-INTERCAL syscalls via label (666) -- mas idiomatico
  - Decidir si adoptar un mecanismo similar propio de este compilador
- Definir plataforma target inicial (macOS arm64 o Linux x86_64)
- Definir lenguaje del bootstrap compiler (C, Rust, otro)

## Proximo paso

- Disenar la estructura del compilador: que modulos, que labels, como organizar el codigo INTERCAL
- Escribir el bootstrap compiler en otro lenguaje que genere el primer ejecutable
- Escribir un programa INTERCAL de prueba simple (hello world) para validar el bootstrap
