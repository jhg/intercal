# Documentation

This directory is the narrative companion to the compiler. The root `README.md` is the quick start, `AGENTS.md` is the full reference and contributor contract, and `docs/` is the book-length walkthrough: how each phase works, why the code is organised the way it is, and what the design tradeoffs were.

The target audiences are three:

1. A newcomer who wants to understand what this compiler does before touching the code.
2. A contributor (human or AI) who needs to locate the right file or phase to modify.
3. A reader using the repo as an educational example of a small, complete, self-hosting compiler.

## Three reading paths

### Newcomer path

You want to know what this repo is, roughly how a `.i` source becomes a native binary, and where to look next.

1. [overview.md](overview.md) — what and why.
2. [intercal-primer.md](intercal-primer.md) — the language in 15 minutes, only what the compiler cares about.
3. [pipeline.md](pipeline.md) — the full trip from `.i` to binary in one page.
4. [map-of-the-compiler.md](map-of-the-compiler.md) — pointers into the actual source files.

### Contributor / maintainer path

You already know roughly what INTERCAL is and you want to change a phase or fix a bug.

1. [map-of-the-compiler.md](map-of-the-compiler.md) — find the right file.
2. The phase chapter for the area you are touching: [lexing-and-parsing.md](lexing-and-parsing.md), [semantic-analysis.md](semantic-analysis.md), [code-generation.md](code-generation.md), [runtime.md](runtime.md), [syslib.md](syslib.md).
3. [platforms.md](platforms.md) — differences between macOS, Linux ARM64 and Linux x86-64.
4. [testing-and-workflow.md](testing-and-workflow.md) — how to add a test and run the suites.
5. [AGENTS.md](../AGENTS.md) — authoritative contributor rules: TDD workflow, commit discipline, assembly pitfalls by platform.

### Educator / AI-assisted development path

You want to use this repo as an example of a real small compiler, or you are an AI agent working on it.

1. [overview.md](overview.md) then [map-of-the-compiler.md](map-of-the-compiler.md) to place our code next to textbook phases.
2. [self-hosting.md](self-hosting.md) — the three-phase bootstrap, fixpoint, what "self-hosting" means in practice.
3. [further-reading.md](further-reading.md) — free compiler resources, from Crafting Interpreters to the Dragon Book.
4. [ai-collaboration.md](ai-collaboration.md) — how to brief an AI agent to work on this repo.

## Chapter index

| # | Chapter | Topic |
|---|---------|-------|
| 00 | [overview.md](overview.md) | What this repo is, why INTERCAL is a good teaching example |
| 01 | [map-of-the-compiler.md](map-of-the-compiler.md) | Source layout → compiler phases |
| 02 | [intercal-primer.md](intercal-primer.md) | INTERCAL for compiler readers |
| 03 | [pipeline.md](pipeline.md) | End-to-end compilation pipeline |
| 04 | [lexing-and-parsing.md](lexing-and-parsing.md) | Scanner and parser |
| 05 | [semantic-analysis.md](semantic-analysis.md) | Politeness, labels, COME FROM |
| 06 | [code-generation.md](code-generation.md) | Direct-to-assembly codegen |
| 07 | [runtime.md](runtime.md) | Runtime routines, TTM, error codes |
| 08 | [syslib.md](syslib.md) | Arithmetic labels 1000–1999 |
| 09 | [666.md](666.md) | Label 666 syscall extension (existing) |
| 10 | [self-hosting.md](self-hosting.md) | Bootstrap strategy and fixpoint |
| 11 | [platforms.md](platforms.md) | Multi-platform porting |
| 12 | [testing-and-workflow.md](testing-and-workflow.md) | Test suites and TDD |
| 90 | [glossary.md](glossary.md) | INTERCAL symbols and compiler jargon |
| 91 | [further-reading.md](further-reading.md) | Free external resources |
| 92 | [ai-collaboration.md](ai-collaboration.md) | Working on this repo with an AI agent |

## What is not in `docs/`

These live elsewhere on purpose:

- Language reference in depth, error code list, assembly pitfalls per platform, TDD contract → [AGENTS.md](../AGENTS.md).
- Quick start, install, repo layout, test counts → [README.md](../README.md).
- Security model and known limitations → [SECURITY.md](../SECURITY.md).
- Current project state (what is done, what is next) → internal memory at `memory/project_status.md`.

`docs/` tries never to duplicate those. When it needs to cite them it links.
