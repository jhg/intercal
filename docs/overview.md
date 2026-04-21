# Overview

This repository is a small, complete, self-hosting compiler for INTERCAL. It takes a `.i` source file and produces a native Mach-O (macOS ARM64) or ELF (Linux ARM64 and x86-64) executable, with no C or Rust intermediate step.

It is also, on purpose, an educational artifact. INTERCAL is an esoteric language designed in 1972 as a parody of the languages that existed at the time. That heritage makes it small enough to implement in one weekend of concentrated reading, but weird enough that doing so forces you to meet almost every classic concept in compiler construction:

- A scanner that tokenises a whitespace-insensitive, case-insensitive source.
- A parser whose grammar has no operator precedence and uses two alternating grouping characters instead.
- A compile-time check (the politeness rule) that rejects a program that is statistically too polite or not polite enough.
- A `COME FROM` statement, the celebrated inverse of `GOTO`, which is resolved at link-time inside the compiler rather than at parse-time.
- A runtime that does I/O in Roman numerals and a Turing Text Model tape, not printf.
- A self-hosting strategy that goes through a shell-script bootstrap, a template-dispatch MVP, and finally a real INTERCAL compiler written in INTERCAL itself.

Our pipeline is deliberately unfashionable: source goes straight through tokenisation, parsing, a handful of static checks, and straight into target assembly. There is no intermediate representation, no bytecode, no virtual machine. The only backend we talk to is `cc -x assembler -`, and the only runtime is a few hundred lines of hand-written assembly per platform. That makes every phase short enough to read end-to-end in one sitting, and it makes the whole system a reasonable first example for somebody learning how compilers actually work.

## What is in the repo

High level:

    src/bootstrap/intercalc.sh     The shell compiler. This is the "chispa primigenea".
    src/bootstrap/codegen_x86_64.sh Backend override for Linux x86-64.
    src/runtime/<platform>.s       Native runtime per platform (Mach-O or ELF, ARM64 or x86-64).
    src/syslib/syslib.i            Arithmetic library written in pure INTERCAL (9065 lines).
    src/syslib/native/<platform>.s Same arithmetic written in native assembly (faster).
    src/compiler/compiler.i        Self-hosted MVP using template dispatch.
    src/compiler/stage3.i          Evolving real compiler, Phase 4 work-in-progress.
    src/compiler/templates/        Pre-generated assembly per test per platform (MVP fuel).
    tests/                         Four test suites plus individual .i programs.
    tools/                         Manifests, hooks, lint, cross-platform Docker tests.
    docs/                          You are here.

## The compilation pipeline at a glance

There is no IR. The pipeline is:

1. **Read** the `.i` source from stdin or argv.
2. **Tokenise** into statements with their modifiers (PLEASE, NOT, %probability).
3. **Classify** each statement (assignment, NEXT, RESUME, READ OUT, etc.) and parse its body — for expressions, into a tree.
4. **Check** politeness (between 1/5 and 1/3 of statements must use PLEASE), label uniqueness, and resolve `COME FROM` targets.
5. **Emit** ARM64 or x86-64 assembly directly, one function-like block per statement.
6. **Concatenate** the generated assembly with the pre-written runtime and syslib for the platform.
7. **Invoke** the system's `cc -x assembler -` to link and produce the final executable.

That's the whole story. See [pipeline.md](pipeline.md) for the details, and [map-of-the-compiler.md](map-of-the-compiler.md) for where each phase lives in the source.

## Why INTERCAL makes a good teaching example

Most compiler textbooks build a mini-C or a mini-Lisp. Those are practical, but they also let you skip parts of the problem. INTERCAL doesn't let you skip anything:

| Concept | How INTERCAL forces you to think about it |
|---------|-------------------------------------------|
| Tokenisation | Case-insensitive, whitespace-agnostic, no statement terminator. `DON'T` must be one token. |
| Grammar | Grouping with sparks `'` and rabbit-ears `"` that must alternate — two families of brackets, not one. |
| Operator semantics | Unary operators work on adjacent bits of the same value, not between two values. |
| Static analysis | Politeness is a property of the whole program, not any single statement. |
| Non-local control flow | `COME FROM` reverses the caller/callee relationship — the target statement doesn't know it has a follower. |
| Calling convention | The system library is itself INTERCAL source, glued into the program via labels 1000–1999. |
| Runtime | Output is Roman numerals (READ OUT a scalar) or a Turing tape (READ OUT an array). Neither is free. |
| Self-hosting | The compiler's own source is INTERCAL, and it must reach a three-generation fixpoint. |
| Bootstrap | Before the compiler exists, a shell script has to do its job — and the shell script must emit the same assembly the INTERCAL compiler will eventually emit. |

A C compiler teaches you the happy path. INTERCAL teaches you the full shape.

## The fact you will probably want to know first

There is **no intermediate representation** in this compiler. Each statement is turned directly into a block of target assembly. That choice costs us the ability to do classical optimisations easily, but it buys transparency: if you want to see what `DO .1 <- #5` compiles to, you can `INTERCAL_ASM_ONLY=1 zsh src/bootstrap/intercalc.sh < one_line.i` and read the assembly out. See [code-generation.md](code-generation.md).

## Next reading

- Want the language first? → [intercal-primer.md](intercal-primer.md).
- Want to see the pipeline? → [pipeline.md](pipeline.md).
- Want to find a specific piece of code? → [map-of-the-compiler.md](map-of-the-compiler.md).
- Want to understand the self-hosting plan? → [self-hosting.md](self-hosting.md).
