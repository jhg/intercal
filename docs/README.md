# Documentation

This directory is the narrative companion to the compiler. The root `README.md` is the quick start, `AGENTS.md` is the full reference and contributor contract, and `docs/` is the book-length walkthrough: how each phase works, why the code is organised the way it is, and what the design tradeoffs were.

The target audiences are four:

1. A complete beginner who has never seen INTERCAL or worked on a compiler before.
2. A reader who wants to understand compiler construction using this repository as a teaching example.
3. A contributor (human or AI) who needs to locate the right file or phase to modify.
4. An experienced developer who wants quick answers about the design decisions.

## Four reading paths

### Absolute beginner path

You have never touched this before. Follow these in order.

1. [what-is-intercal.md](what-is-intercal.md) — what INTERCAL is and why anyone still writes it.
2. [getting-started.md](getting-started.md) — install, build, compile hello world in thirty minutes.
3. [intercal-primer.md](intercal-primer.md) — the language tour.
4. [label-666-intro.md](label-666-intro.md) — the friendly explanation of our syscall extension.

### Compiler-construction student path

You want to learn how compilers work. Use this repository as the running example.

1. [overview.md](overview.md) — what this compiler is.
2. [map-of-the-compiler.md](map-of-the-compiler.md) — source layout mapped to compiler phases.
3. [pipeline.md](pipeline.md) — the end-to-end trip from source to binary.
4. [lexer-theory.md](lexer-theory.md) and [lexing-and-parsing.md](lexing-and-parsing.md) — scanning.
5. [parser-theory.md](parser-theory.md) — recursive descent and the LL(1) grammar.
6. [semantic-analysis.md](semantic-analysis.md) — politeness, labels, COME FROM.
7. [code-generation.md](code-generation.md) — direct-to-assembly codegen.
8. [runtime.md](runtime.md) — what the emitted assembly calls into.
9. [syslib.md](syslib.md) — arithmetic labels 1000–1999.
10. [calling-conventions.md](calling-conventions.md) — AAPCS64 and System V AMD64 in our code.
11. [executables-and-linking.md](executables-and-linking.md) — Mach-O, ELF, and `cc` as driver.
12. [middle-end-and-optimisation.md](middle-end-and-optimisation.md) — the middle end we don't have.
13. [self-hosting.md](self-hosting.md) — the 3-generation bootstrap strategy.
14. [walkthrough-hello.md](walkthrough-hello.md) — the capstone: hello world through every phase.
15. [appendix-grammar.md](appendix-grammar.md) — the formal grammar.

### Contributor / maintainer path

You want to change a phase or fix a bug.

1. [map-of-the-compiler.md](map-of-the-compiler.md) — find the right file.
2. [your-first-contribution.md](your-first-contribution.md) — if you are new, this is the shortest concrete walkthrough.
3. The phase chapter for the area you are touching — see the table below.
4. [debugging.md](debugging.md) — symptom-to-phase debugging taxonomy.
5. [testing-and-workflow.md](testing-and-workflow.md) — the four test suites and the TDD contract.
6. [platforms.md](platforms.md) — the per-platform syntactic and syscall differences.
7. [AGENTS.md](../AGENTS.md) — authoritative contributor rules.

### Design-rationale / quick-answer path

You want to know *why* something is the way it is.

1. [design-rationale.md](design-rationale.md) — the FAQ covering every major decision.
2. [history-and-context.md](history-and-context.md) — INTERCAL's history and how this compiler relates to the existing implementations.
3. [666.md](666.md) — the deep rationale for Label 666.
4. [further-reading.md](further-reading.md) — external resources for deeper study.

## Full chapter index

### Introduction layer

| File | Purpose |
|------|---------|
| [getting-started.md](getting-started.md) | Beginner tutorial: install, build, hello world |
| [what-is-intercal.md](what-is-intercal.md) | Plain-English introduction to INTERCAL |
| [overview.md](overview.md) | Technical overview of this compiler |
| [map-of-the-compiler.md](map-of-the-compiler.md) | Source layout mapped to compiler phases |
| [intercal-primer.md](intercal-primer.md) | INTERCAL language tour for compiler readers |

### The compiler, phase by phase

| File | Purpose |
|------|---------|
| [pipeline.md](pipeline.md) | End-to-end walk of `intercalc.sh` |
| [lexer-theory.md](lexer-theory.md) | Regular languages, DFA, our hand-written scanner |
| [parser-theory.md](parser-theory.md) | Recursive descent, LL(1), INTERCAL's grammar class |
| [lexing-and-parsing.md](lexing-and-parsing.md) | The concrete implementation |
| [semantic-analysis.md](semantic-analysis.md) | Politeness, labels, COME FROM |
| [code-generation.md](code-generation.md) | Direct-to-assembly emission |
| [middle-end-and-optimisation.md](middle-end-and-optimisation.md) | The middle end we don't have |

### Back-end and system

| File | Purpose |
|------|---------|
| [runtime.md](runtime.md) | Runtime routines, TTM, error codes |
| [syslib.md](syslib.md) | Arithmetic labels 1000–1999 |
| [calling-conventions.md](calling-conventions.md) | AAPCS64 and System V AMD64 |
| [executables-and-linking.md](executables-and-linking.md) | Mach-O, ELF, and the system linker |
| [platforms.md](platforms.md) | macOS ARM64, Linux ARM64, Linux x86-64 |
| [label-666-intro.md](label-666-intro.md) | The syscall extension, friendly version |
| [666.md](666.md) | The syscall extension, deep design rationale |

### Self-hosting and testing

| File | Purpose |
|------|---------|
| [self-hosting.md](self-hosting.md) | 3-generation bootstrap, fixpoint, stage3 roadmap |
| [testing-and-workflow.md](testing-and-workflow.md) | The four test suites, TDD, CI |
| [debugging.md](debugging.md) | Symptom-to-phase debugging guide |

### Worked examples and contribution

| File | Purpose |
|------|---------|
| [walkthrough-hello.md](walkthrough-hello.md) | Hello world through every phase |
| [your-first-contribution.md](your-first-contribution.md) | End-to-end walkthrough of landing a change |
| [ai-collaboration.md](ai-collaboration.md) | Working on this repo with an AI agent |

### Reference apparatus

| File | Purpose |
|------|---------|
| [statement-cheatsheet.md](statement-cheatsheet.md) | One-line reference for every statement, operator, syslib label, and syscall |
| [appendix-grammar.md](appendix-grammar.md) | Formal EBNF grammar |
| [glossary.md](glossary.md) | INTERCAL symbols and compiler jargon |
| [design-rationale.md](design-rationale.md) | FAQ covering major design decisions |
| [history-and-context.md](history-and-context.md) | INTERCAL history and comparative notes |
| [further-reading.md](further-reading.md) | Annotated bibliography of external resources |

## What is not in `docs/`

These live elsewhere on purpose and are referenced rather than duplicated:

- Language reference in depth, error code list, assembly pitfalls per platform, TDD contract → [AGENTS.md](../AGENTS.md).
- Quick start, install, repo layout, test counts → [README.md](../README.md).
- Security model and known limitations → [SECURITY.md](../SECURITY.md).
- Current project state → internal memory at `memory/project_status.md` (per-developer, not committed).

## How this book is meant to be read

Every chapter is designed to be read independently. Cross-references are bidirectional: if chapter A mentions a concept deeply explained in chapter B, it links; if chapter B introduces a concept that is used in chapter A, it links back. The chapter index above is a suggested ordering, but any chapter can be opened first.

The exercises at the end of most chapters are optional. They are not graded and not tested; they exist for the reader who wants to check their understanding before moving on.

## Maintenance

These docs track the code. When a phase changes — a new statement type, a new runtime routine, a new platform — the affected chapters are updated. The maintenance contract is documented in [ai-collaboration.md](ai-collaboration.md) and enforced by convention rather than by tooling.

A docs-only commit skips the test suite in the pre-commit hook. This keeps the barrier to docs updates low and encourages keeping them current.
