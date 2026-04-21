# Platforms

The compiler targets three platforms today:

- macOS on Apple Silicon (ARM64, Mach-O).
- Linux on AArch64 (ARM64, ELF).
- Linux on x86-64 (ELF, Intel syntax).

Windows is on the roadmap but not implemented. The macOS ARM64 target is the primary development platform; the others are validated in CI on every push. This chapter surveys what each platform demands, how the compiler satisfies those demands, and the pitfalls we have encountered.

## What "supporting a platform" entails

Supporting a new target for this compiler means providing three things, all of which live in the repository as hand-written assembly:

1. A runtime — `src/runtime/<platform>.s` — with every `_rt_*` routine listed in [runtime.md](runtime.md).
2. A native syslib — `src/syslib/native/<platform>.s` — with all 20 arithmetic labels.
3. Either a codegen module that directly emits the target assembly (as in `src/bootstrap/codegen_x86_64.sh`), or a source-to-source conversion from the macOS ARM64 assembly produced by `intercalc.sh` (as in the `sed` pipeline inside `main` for Linux ARM64).

The first two are mechanical translations. The third is the real design decision, and we have made it differently for Linux ARM64 than for Linux x86-64.

## Syntactic and syscall differences

A compressed version of the table in `AGENTS.md`:

| Aspect | macOS ARM64 | Linux ARM64 | Linux x86-64 |
|--------|-------------|-------------|--------------|
| Format | Mach-O | ELF | ELF |
| Assembler | Apple `as` (lenient) | GNU `as` (strict) | GNU `as`, Intel syntax |
| Entry point | `_main` | `main` | `main` |
| Symbol prefix | `_` | none | none |
| `.global` required | no | yes | yes |
| Text section | `.section __TEXT,__text` | `.text` | `.text` |
| Comment delimiter | `//` or `#` | `//` or `#` | `#` only |
| Syscall instruction | `svc #0x80` | `svc #0` | `syscall` |
| Syscall number register | `x16` | `x8` | `rax` |
| Syscall error detection | carry flag (`b.cs`) | negative return | negative return |
| Relocation (ADRP/ADR) | `sym@PAGE`, `sym@PAGEOFF` | bare `sym`, `:lo12:sym` | RIP-relative `sym(%rip)` |
| `exit` syscall number | 1 | 93 | 60 |
| `read` | 3 | 63 | 0 |
| `write` | 4 | 64 | 1 |
| `open` | 5 | — (use `openat` = 56) | 2 |
| `close` | 6 | 57 | 3 |
| `mmap` | 197 | 222 | 9 |
| `MAP_ANON` \| `MAP_PRIVATE` | 0x1002 | 0x22 | 0x22 |
| `O_WRONLY` \| `O_CREAT` \| `O_TRUNC` | 0x601 | 0x241 | 0x241 |
| Randomness source | `getentropy` (500) | `getrandom` (278) | `getrandom` (318) |

Every one of those lines is a past bug waiting to happen. The pitfalls section below is the bug history.

## Two strategies for platform support

There are two ways to add a new backend to a compiler: translate after the fact, or emit different output in the first place. Both are legitimate, and we use both.

### Post-hoc translation: Linux ARM64

The Linux ARM64 path produces macOS ARM64 assembly from `intercalc.sh`, then translates it with `sed` as a final step. The relevant lines in `main`:

    asm_combined=$(print -r -- "$asm_combined" | sed \
      -e 's/\.section __TEXT,__text/.text/' \
      -e 's/\([_a-zA-Z][_a-zA-Z0-9]*\)@PAGEOFF/:lo12:\1/g' \
      -e 's/\([_a-zA-Z][_a-zA-Z0-9]*\)@PAGE/\1/g' \
      -e 's/svc #0x80/svc #0/g' \
      -e 's/mov x16, #1$/mov x8, #93/' \
      ...
      -e 's/\.global _main/.global main/' \
      -e 's/^_main:/main:/')

The advantage: the codegen phase does not branch on the platform. One emission strategy, one post-processing pass. The `.s` files under `src/runtime/` and `src/syslib/native/` are pre-translated versions of their macOS counterparts and are committed to the repository, not generated.

The risk: the `sed` order is fragile. Matching `@PAGE` first and `@PAGEOFF` afterwards would corrupt `_sym@PAGEOFF` into `_sym:lo12:OFF`, because `@PAGE` is a prefix of `@PAGEOFF`. Our real history has at least one bug of this exact shape. The fix is the order shown above: `@PAGEOFF` first, then `@PAGE`.

### Fresh emission: Linux x86-64

The Linux x86-64 path replaces every `codegen_*` function. `src/bootstrap/codegen_x86_64.sh` is sourced when the platform is `linux_x86_64`; because zsh lets a later function definition silently override an earlier one, every ARM64 emission function is replaced.

The advantage: the emitted assembly is idiomatic x86-64 from the start. No source-to-source translation step is necessary. Intel syntax (`.intel_syntax noprefix`), RIP-relative addressing, System V AMD64 calling convention.

The cost: every statement's codegen has to be implemented twice, once per architecture. The x86-64 backend is 955 lines (compared to the 970 or so lines of per-statement codegen in ARM64).

The tradeoff between the two approaches depends on how different the target is from the source architecture. ARM64-to-ARM64 can plausibly be done with `sed` (the instruction set is the same; only the assembler syntax and syscall numbers differ). ARM64-to-x86-64 cannot: the instruction set, register conventions, and memory addressing are all different.

## Pitfalls, by platform

This is a distilled version of the platform-pitfalls section of `AGENTS.md`. The canonical list lives there; the purpose of repeating it here is pedagogic.

### ARM64 (both macOS and Linux)

- `adrp sym` computes the page base of `sym`. GNU `as` infers the page relocation automatically, but Apple `as` requires `sym@PAGE`. The `sed` step adds or removes the suffix accordingly.
- `add x0, x0, sym@PAGEOFF` on macOS becomes `add x0, x0, :lo12:sym` on Linux. The `:lo12:` prefix does *not* go on the `adrp` instruction; GNU `as` infers the high bits.
- `:pg_hi21:` never appears in either flavour of our output. Earlier experiments where we emitted it caused GNU `as` to reject the file with "junk at end of line".

### Linux ARM64 only

- Linux AArch64 has no `open` syscall. `openat` (56) is the replacement, with `AT_FDCWD` (-100) as the first argument.
- Error detection returns a negative value, not a carry flag. `cmp x0, #0; b.lt` replaces macOS's `b.cs`.
- `.global` is required for any symbol referenced across translation units. Apple `ld` is lenient about missing declarations; GNU `ld` rejects. We declare every entry-point symbol (`_main` → `main`, `_rt_*`) at column 0. Only labels at column 0 may be declared; attempting to `.global` a data symbol or a label line containing `:lo12:` causes the assembler to choke.

### Linux x86-64 only

- GNU `as` rejects `//` as a comment. Our x86-64 emission uses `#`.
- `[r12 + r14 + rcx]` has three registers. x86-64 addressing allows at most two. Use `lea r15, [r12 + r14]` to flatten, then `[r15 + rcx]`.
- Intel syntax is opted into by `.intel_syntax noprefix` at the top of every `.s` file. Every subsequent line must match; mixing AT&T (`%rax`) with Intel (`rax`) anywhere in the same file breaks the assembler.
- RIP-relative addressing is the idiomatic way to reference data in position-independent code: `lea rax, [rip + symbol]`.

## Platform detection

At the top of `intercalc.sh`:

    _OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    _ARCH=$(uname -m)
    case "${_OS}_${_ARCH}" in
      darwin_arm64)  _INTERCAL_PLATFORM=macos_arm64 ;;
      linux_x86_64)  _INTERCAL_PLATFORM=linux_x86_64 ;;
      linux_aarch64) _INTERCAL_PLATFORM=linux_arm64 ;;
      *)             _INTERCAL_PLATFORM=macos_arm64 ;;
    esac

The fallback to macOS ARM64 is a development convenience; a user on an unsupported platform sees a build error when `cc -x assembler -` refuses the output. `setup_platform.sh` prints the detected platform and confirms the three inputs (runtime, syslib, codegen) exist.

## Cross-platform testing from macOS

To reproduce a Linux CI failure from a macOS development machine, run `tests/cross_test.sh`:

    zsh tests/cross_test.sh linux_x86_64
    zsh tests/cross_test.sh linux_arm64 --image ubuntu:24.04

The script spins up a Docker container for the requested platform, installs zsh and gcc, mounts the repository, and runs the relevant test suite inside. It is slower than a native run (~3 minutes for the full suite on a Docker x86-64 VM), but much faster than waiting for CI and, critically, reproducible locally.

## Exercises

1. `b.cs` on macOS vs `b.lt` on Linux. Construct a one-line INTERCAL program whose generated code exercises this conditional. Trace why the platforms chose different conventions historically.
2. The `sed` pipeline has a substitution `mov x3, #0x1002 → mov x3, #0x22`. Find every place in the macOS runtime where `0x1002` appears. What would happen if the substitution matched inside a comment?
3. Suppose we want to add Windows ARM64 (COFF, different syscall model). Decide whether to go the post-hoc translation route or write a fresh codegen backend, and justify the choice in one paragraph.
4. The x86-64 backend emits Intel syntax. Could we instead emit AT&T syntax without rewriting the codegen? What, mechanically, would that require?
5. Run `tests/cross_test.sh linux_x86_64` locally. Compare the wall-clock time of `tests/run_tests.sh` inside the container to a native macOS run. What fraction of the slowdown is Docker overhead, and what fraction is the x86-64 emulation?

## Next reading

- [runtime.md](runtime.md) — the per-platform runtime routines that this chapter's differences manifest in.
- [testing-and-workflow.md](testing-and-workflow.md) — how the CI job configures each platform.
- `AGENTS.md` sections "Multi-platform porting guide" and "Assembly pitfalls by platform" — the authoritative versions of the tables and pitfalls summarised here.
