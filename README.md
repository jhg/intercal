# intercal

A self-hosting compiler for the INTERCAL language.

## Status

- Bootstrap compiler (src/bootstrap/intercalc.sh): complete, 25/25 tests on macOS ARM64, Linux ARM64, Linux x86_64.
- Pure-INTERCAL syslib (src/syslib/syslib.i): 9065 lines, 20 labels, verified byte-identical to the native syslib.
- Self-hosted MVP (src/compiler/compiler.i + src/compiler/templates/): 22/22 tests pass via content-hash dispatch to pre-generated per-platform templates.
- Three-generation fixpoint: pending (requires real lexer+codegen in INTERCAL, not templates).

## Building and testing

Bootstrap compiler (primary):

    zsh src/bootstrap/intercalc.sh < program.i > binary && chmod +x binary
    ./binary

Self-hosted compiler (MVP):

    zsh src/bootstrap/intercalc.sh < src/compiler/compiler.i > intercal_core
    chmod +x intercal_core
    ./intercal program.i -o binary
    ./binary

Run the test suites:

    zsh tests/run_tests.sh         # bootstrap, 25 tests
    zsh tests/test_syslib_pure.sh  # pure vs native syslib, 3 tests
    zsh tests/run_self_tests.sh    # self-hosted MVP, 22 tests

## Architecture

INTERCAL source compiles directly to a native executable. No C or other intermediate language. The pipeline is:

1. Compiler emits ARM64 or x86_64 program assembly.
2. The wrapper concatenates platform runtime (src/runtime/<platform>.s) + native syslib (src/syslib/native/<platform>.s) + program assembly.
3. cc assembles and links to produce the final binary.

The runtime is a small assembly library that provides I/O (Roman numerals, Turing Text Model, English digit names), operators (mingle, select, unary AND/OR/XOR), memory (mmap), NEXT/RESUME stack, error handlers (16 runtime errors), and a Label 666 syscall dispatcher with 8 primitives (open, read, write, close, argc, argv, exit, getrand).

The syslib provides arithmetic at labels 1000-1999 (16-bit and 32-bit add/sub/mul/div, random). It exists in two forms: a native assembly version for performance and a pure-INTERCAL version (syslib.i) used when the compiler needs to compile syslib code itself.

See AGENTS.md for the full architecture, platform pitfalls, and INTERCAL language reference.

## Platform support

- macOS ARM64 (primary): uses Mach-O sections, svc #0x80, x16 syscall number register, @PAGE/@PAGEOFF relocations.
- Linux ARM64: GNU ELF, svc #0, x8 syscall number, bare adrp + :lo12: relocations, openat instead of open.
- Linux x86_64: Intel syntax, System V AMD64 ABI, RIP-relative addressing, separate codegen backend.

CI validates all three platforms via GitHub Actions.

## License

This project is released into the public domain. See LICENSE.
