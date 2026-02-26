# INTERCAL Compiler Project Memory

## Status (2026-02-27)

CLC-INTERCAL investigated and documented. Results saved in **666.md** (no /tmp).

Documentation updated:
- AGENTS.md: Phases clarified, Syscall extension explains approach
- TODO.md: Phases updated, no Label 666 in Phase 1
- 666.md: Complete investigation report with all findings

**Key decision**: Do NOT implement CLC-INTERCAL compatibility.
- CLC's "call by vague resemblance" is deliberately obscure
- Only syscall #1 documented, rest requires reverse-engineering
- Phase 1: stdin/stdout filter (pure INTERCAL, no syscalls)
- Phase 2: custom simplified syscalls (our own design)

Next: Design intercalc.sh architecture and begin implementation.

## Bootstrap Strategy

**Three-phase approach:**

1. **Phase 1: Shell script bootstrap (`intercalc.sh`)**
   - Single bash/zsh file implementing a basic INTERCAL compiler
   - Takes normal CLI args: `intercalc.sh program.i -o output`
   - Generates native binaries with embedded runtime
   - Supports syscalls/extern calls (implementation TBD)
   - Simple enough to write in shell, complex enough to be useful
   - Not a stdin/stdout pipe filter — normal compiler tool

2. **Phase 2: INTERCAL self-compiler**
   - Write the actual compiler in INTERCAL (with runtime support)
   - Bootstrap it with the shell compiler from Phase 1
   - Same CLI interface: `./intercal program.i -o output`
   - Generates binaries with embedded runtime
   - Now has syscall/extern call support

3. **Phase 3: Iteration & improvement**
   - Use self-compiler to improve itself
   - Optimize, add features, refactor
   - GitHub workflow: bootstrap → compile compiler → test → release

## Key Insight

Don't try to make a stdin/stdout pipe filter in INTERCAL puro. Instead:
- Bootstrap solves the runtime embedding problem in shell
- INTERCAL compiler uses the syscall extension mechanism (to be decided)
- Second version is a normal compiler, not a filter

## Decisions Made

- **Syscall mechanism**: Label 666 (CLC-INTERCAL style)
  - `DO (666) NEXT` makes a syscall
  - Syscall number in .1, args in .2-.4, :1-:4
  - Results returned in .1
  - Handler in assembly reads .1, executes syscall, returns result
  - Idiomatically extends NEXT (minimal parser changes)

- **Platform target**: macOS arm64 (v1)

- **Runtime features in Phase 1**:
  - READ OUT (Roman numerals + Turing Text Model)
  - WRITE IN (parse English digit names)
  - Arrays (dynamic allocation)
  - STASH/RETRIEVE (unbounded stacks)
  - Random (via /dev/urandom or syscall)
  - Exit handling
