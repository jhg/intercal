# Testing and workflow

A compiler is a program whose output is another program. That gives it an inconveniently large surface area: a bug can live in the lexer, the parser, the semantic analyser, the code generator, the runtime, the syslib, or the glue between any two of those. A single mistake can pass compilation unchecked and fire only at runtime on a specific platform with a specific input. Testing is therefore not optional; it is the primary mechanism by which this project asserts that anything works.

This chapter describes the four test suites, the TDD contract that governs changes, how differential testing between the bootstrap and the self-hosted compiler is arranged, and the pre-commit / pre-push / CI cadence that enforces everything.

## The four test suites

| Suite | File | Scope | Count |
|-------|------|-------|-------|
| Bootstrap | `tests/run_tests.sh` | Full language, via `intercalc.sh` | 25 |
| Pure syslib | `tests/test_syslib_pure.sh` | Pure vs native syslib equivalence | 3 |
| Self-hosted MVP | `tests/run_self_tests.sh` | Template-dispatch `compiler.i` end-to-end | 25 |
| Evolving | `tests/run_stage3_tests.sh` | `stage3.i` diagnostics | 3 |

The four together comprise 56 tests. They run in sequence on every push, on every platform: three platforms × 56 tests = 168 distinct test executions per CI run, give or take a handful of platform-skipped cases.

### `run_tests.sh` — the ground truth

This suite is the source of truth. Each entry is an INTERCAL program under `tests/test_<name>.i` with an expected output (inline or in a sibling file). The runner compiles the program with `intercalc.sh`, executes it, captures stdout, and compares to the expected value. Failures surface with the actual vs expected diff.

The tests are grouped by what they exercise:

- Language primitives: `test_variables.i`, `test_nested_expr.i`.
- I/O: `test_hello.i`, `test_read_out_num.i`, `test_read_out_multi.i`, `test_overbar.i`, `test_write_in.i`.
- Control flow: `test_control.i`, `test_come_from.i`, `test_forget.i`, `test_give_up.i`.
- State management: `test_stash.i`, `test_ignore_remember.i`, `test_abstain.i`, `test_abstain_gerund.i`.
- Arithmetic via syslib: `test_syslib.i`, `test_divide.i`, `test_multiply.i`, `test_multidim_array.i`.
- Politeness: `test_errors_rude.i`, `test_errors_polite.i` — each expects a specific ICL error on stderr.
- Runtime errors: `test_error_e123.i`, `test_error_e621.i`, `test_error_e633.i` — each must terminate with the matching ICL code.
- Label 666: `test_syscall_readself.i` — the program reads its own source via argv[0] and Label 666, then prints metrics about it.

A new language feature or codegen path requires a new entry. A bug fix requires a reproducer that fails before the fix and passes after. These rules are binding; see "TDD contract" below.

### `test_syslib_pure.sh` — differential testing

The pure-vs-native syslib split (see [syslib.md](syslib.md)) is the basis of our strongest differential test. Three programs — add, multiply, divide — are compiled twice, once with `intercalc.sh` (native syslib) and once with `intercalc.sh --pure-syslib` (syslib expressed in INTERCAL and fed through the full pipeline). Both binaries are run, and their outputs are compared byte for byte.

Any divergence is a fail. The failure modes this catches include:

- A native assembly routine that silently disagrees with its INTERCAL reference (wrong algorithm, missing edge case).
- A compiler change that mishandles some INTERCAL construct used by the pure syslib but not by the test programs.
- A runtime change (e.g. to `_rt_mingle` or `_rt_select`) that affects only one of the two paths.

Differential testing is cheap and high-value because the two implementations are independent. A bug that hides in both — a miscompilation of the shared runtime operator primitives — survives this test but fails the bootstrap suite.

### `run_self_tests.sh` — self-hosted MVP

This suite runs the same 25 INTERCAL programs as `run_tests.sh` but compiles them with the self-hosted `intercal` wrapper instead of the bootstrap script. Because the MVP's "compilation" is template dispatch, the test harness confirms three things simultaneously:

1. The pre-generated assembly template for each program is correct (i.e. it is byte-for-byte what the bootstrap produces today).
2. The wrapper correctly identifies the input program by content hash and selects the right template.
3. The self-hosted compiler binary itself — `intercal_core`, produced by compiling `src/compiler/compiler.i` with the bootstrap — correctly reads its argv, opens the source file, reads it via Label 666, and writes the template to stdout.

Drift is caught through the template integrity manifest (`src/compiler/templates/manifest.txt`, SHA-256 checksums) and verified by `tools/verify_manifest.sh` before the tests run. If anybody changes an INTERCAL test program or an `intercalc.sh` codegen detail, the template must be regenerated and re-manifested; otherwise the manifest check fails.

### `run_stage3_tests.sh` — the evolving compiler

Three programs today, and growing. They exercise the diagnostic instrumentation in `src/compiler/stage3.i` — byte count, first byte, last byte — and will grow as the evolving compiler acquires a real lexer, parser, and codegen. Each new sub-stage adds one or two tests before the implementation lands (the TDD red-green cadence is strict here).

## The TDD contract

The project's `AGENTS.md` is explicit: before modifying the compiler, the syslib, or the runtime, add or extend a test that captures the expected behaviour, and verify it fails before you write code and passes after. This is not a suggestion; it is the project's working protocol.

Three categories of change, and the corresponding tests:

- A new language feature or codegen path → a new `tests/test_<name>.i` with expected output, registered in `tests/run_tests.sh`.
- A bug fix → the smallest reproducer that fails in the current state, committed separately or in the same commit as the fix.
- A self-hosted compiler extension → a new entry in `tests/run_stage3_tests.sh` that fails against the current stage3 binary and passes after the implementation.

Exceptions are enumerated and narrow: documentation-only changes, CI workflow edits, renames that do not affect behaviour, formatting. Any exception is called out in the commit message with a one-line justification.

## Pre-commit, pre-push, CI

Three layers of verification, increasingly expensive and increasingly thorough. They exist because fast feedback is more valuable than complete feedback.

### Pre-commit (~30 seconds)

Installed via `tools/install_hooks.sh`. Runs `tools/verify_manifest.sh` and `tests/run_tests.sh` if anything under `src/`, `tests/`, `tools/`, `intercal`, `bootstrap.sh`, or `setup_platform.sh` is staged. Documentation-only commits (like this one) are skipped.

Fast enough to run on every commit. Catches about 90 percent of issues before they reach the tree.

### Pre-push (~1–2 minutes)

Runs all four suites: bootstrap, pure syslib, self-hosted MVP, stage3. Rebuilds `intercal_core` and `stage3_bin` from scratch so tests aren't coloured by stale binaries. A pre-push failure means the push is aborted.

This is the last line of defence before CI takes over. It is slower than pre-commit but still runs locally in the time it takes to drink half a coffee.

### Continuous integration (~15 minutes)

`.github/workflows/ci.yml` runs on every push and every pull request. Three jobs, one per platform, each executing the full pre-push sequence. The platforms are:

- `macos-14` for macOS ARM64.
- `ubuntu-24.04-arm` for Linux ARM64.
- `ubuntu-latest` for Linux x86-64.

A regression that is platform-specific — different syscall convention, different assembler syntax — lands in exactly the job that catches it. All three must be green for the branch to be mergeable.

### Release validation

`.github/workflows/release.yml` builds 9 artifacts (`.zip`, `.tar.gz`, `.deb`, `.rpm` across three platforms) on every version tag. A separate `release-smoke.yml` installs each artifact in a clean container and runs the test suite, confirming that the packaged binary actually works on a user's machine. This catches packaging bugs that would otherwise ship to users.

## Writing a new test

Six steps, in order, for a new INTERCAL feature:

1. Create `tests/test_<feature>.i` with a minimal program that exercises the feature.
2. Write the expected output as a literal string in `tests/run_tests.sh`, or as a sibling `.expected` file if the output is multi-line.
3. Register the test by adding a line to the `_run_test` calls in `tests/run_tests.sh`.
4. Run `zsh tests/run_tests.sh --filter <feature>`. The test should fail (red).
5. Implement the feature in `intercalc.sh`.
6. Re-run. The test should pass (green).

The `--filter`, `--verbose`, and `--keep` flags on the runner speed up the iterate-and-inspect loop. `--keep` preserves failed-test artifacts under `/tmp/intercal_failures/` so you can re-run `cc` by hand.

## Docker cross-platform reproduction

The `tests/cross_test.sh` harness spins up a Docker container for a chosen target platform, mounts the repository, and runs the suite inside. Use it whenever a Linux-only bug needs reproducing from a macOS machine:

    zsh tests/cross_test.sh linux_x86_64
    zsh tests/cross_test.sh linux_arm64 --image ubuntu:24.04

The containers install `zsh` and `gcc` from the distro, mount the repo read-write (so any test output they produce is visible from the host), and run the full four-suite stack. A five-second `docker info` preamble verifies that Docker is actually running before the slower setup begins.

## Exercises

1. Read `tests/run_tests.sh` and list the five flags it supports. For each flag, describe one situation in which it saves time.
2. Write an INTERCAL test that would catch a bug in `codegen_assign` that swaps the 32-bit overflow check with the ignore-flag check. Why is it important that the test catches both orderings?
3. The pure-vs-native syslib test uses only three programs. Construct a fourth program whose inclusion would materially broaden coverage, and explain what class of bug it would catch that the existing three miss.
4. Pre-commit skips the test suite for documentation-only changes. Argue for or against extending the same skip to `.github/` workflow edits.
5. Compare the bootstrap suite running locally to the same suite running inside `tests/cross_test.sh linux_x86_64`. What portion of the slowdown is x86-64 emulation on ARM64, and how could you measure that independently?

## Next reading

- [platforms.md](platforms.md) — the per-platform syscall and syntax details that CI exercises.
- [self-hosting.md](self-hosting.md) — the fixpoint test that will eventually join the test suites.
- `AGENTS.md` — the authoritative TDD contract and commit discipline.
