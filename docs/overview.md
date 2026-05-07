# Overview

A small, complete, self-hosting compiler for INTERCAL. It takes a `.i` source file and produces a native Mach-O (macOS ARM64) or ELF (Linux ARM64 and x86-64) executable, with no C or Rust intermediate step.

It is also, deliberately, an educational artefact. INTERCAL is an esoteric language designed in 1972 to parody the languages of its time. That heritage makes it small enough to implement in a weekend of concentrated reading, and weird enough that doing so forces you to meet almost every classical concept in compiler construction:

- A scanner that tokenises a whitespace-insensitive, case-insensitive source.
- A parser whose grammar has no operator precedence and uses two alternating grouping characters instead.
- A compile-time check (the politeness rule) that rejects programs that are statistically too polite or not polite enough.
- A `COME FROM` statement, the celebrated inverse of `GOTO`, resolved during semantic analysis so the runtime cost is one unconditional jump.
- A runtime that does I/O in Roman numerals and a Turing Text Model tape, not printf.
- A self-hosting strategy that goes shell-script bootstrap → template-dispatch MVP → real INTERCAL compiler written in INTERCAL.

The pipeline is deliberately unfashionable. Source goes straight through tokenisation, parsing, a handful of static checks, and on into target assembly. No intermediate representation, no bytecode, no virtual machine. The only backend we talk to is `cc -x assembler -`, and the only runtime is a few hundred lines of hand-written assembly per platform. Each phase is short enough to read end to end in one sitting; the whole system is a reasonable first example for somebody learning how compilers actually work.

## What is in the repo

High level:

    src/bootstrap/intercalc.sh     The shell compiler. The "chispa primigenea".
    src/bootstrap/codegen_x86_64.sh Backend override for Linux x86-64.
    src/runtime/<platform>.s       Native runtime per platform (Mach-O or ELF, ARM64 or x86-64).
    src/syslib/syslib.i            Arithmetic library written in pure INTERCAL (9065 lines).
    src/syslib/native/<platform>.s Same arithmetic in native assembly (faster).
    src/compiler/compiler.i        Self-hosted MVP using template dispatch.
    src/compiler/stage3.i          Evolving real compiler, Phase 4 work-in-progress.
    src/compiler/templates/        Pre-generated assembly per test per platform (MVP fuel).
    tests/                         Four test suites plus individual .i programs.
    tools/                         Manifests, hooks, lint, cross-platform Docker tests.
    docs/                          You are here.

## The compilation pipeline at a glance

No IR. The pipeline:

1. **Read** the `.i` source from stdin or argv.
2. **Tokenise** into statements with their modifiers (PLEASE, NOT, %probability).
3. **Classify** each statement (assignment, NEXT, RESUME, READ OUT, etc.) and parse its body. Expression bodies become trees.
4. **Check** politeness (PLEASE on between 1/5 and 1/3 of statements), label uniqueness, COME FROM resolution.
5. **Emit** ARM64 or x86-64 assembly directly, one function-shaped block per statement.
6. **Concatenate** the generated assembly with the platform's runtime and syslib.
7. **Invoke** the system's `cc -x assembler -` to assemble and link.

That is the whole story. See [pipeline.md](pipeline.md) for the details and [map-of-the-compiler.md](map-of-the-compiler.md) for where each phase lives in the source.

## Why INTERCAL makes a good teaching example

Most compiler textbooks build a mini-C or a mini-Lisp. Those are practical, but they let you skip parts of the problem. INTERCAL does not let you skip anything:

| Concept | How INTERCAL forces you to think about it |
|---------|-------------------------------------------|
| Tokenisation | Case-insensitive, whitespace-agnostic, no statement terminator. `DON'T` must be one token. |
| Grammar | Grouping with sparks `'` and rabbit-ears `"` that must alternate. Two families of brackets, not one. |
| Operator semantics | Unary operators work on adjacent bits of the same value, not between two values. |
| Static analysis | Politeness is a property of the whole program, not any single statement. |
| Non-local control flow | `COME FROM` reverses the caller/callee relationship. The target statement does not know it has a follower. |
| Calling convention | The system library is itself INTERCAL source, glued in via labels 1000–1999. |
| Runtime | Output is Roman numerals (READ OUT a scalar) or a Turing tape (READ OUT an array). Neither is free. |
| Self-hosting | The compiler's own source is INTERCAL, and it must reach a three-generation fixpoint. |
| Bootstrap | Before the compiler exists, a shell script has to do its job, and emit the same assembly the INTERCAL compiler will eventually emit. |

A C compiler teaches you the happy path. INTERCAL teaches you the full shape.

## The fact you will probably want to know first

There is **no intermediate representation** in this compiler. Each statement is turned directly into a block of target assembly. That choice costs us classical optimisations, but it buys transparency: to see what `DO .1 <- #5` compiles to, run

    INTERCAL_ASM_ONLY=1 zsh src/bootstrap/intercalc.sh < one_line.i

and read the assembly. See [code-generation.md](code-generation.md).

## Next reading

- Want the language first? [intercal-primer.md](intercal-primer.md).
- Want the pipeline? [pipeline.md](pipeline.md).
- Want a specific piece of code? [map-of-the-compiler.md](map-of-the-compiler.md).
- Want the self-hosting plan? [self-hosting.md](self-hosting.md).
