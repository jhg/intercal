# Contributing to intercal

Thanks for your interest. This project is maintained as a hobby, so responses may be slow, but contributions are welcome. The rules below aren't meant to be barriers; they exist because this compiler targets native assembly on three platforms simultaneously and it's easy to ship something that works on one machine and segfaults on another.

## Setup

    git clone https://github.com/jhg/intercal.git
    cd intercal
    sh tools/install_hooks.sh

The hooks run tests on every commit and push. Don't skip them with `--no-verify` without a good reason.

You need `zsh` and a C compiler. Docker is optional but strongly recommended if you're on macOS, since it lets you reproduce the Linux CI jobs locally.

## Quick checks before you touch anything

    zsh tests/run_tests.sh          # 25 tests, ~5s
    zsh tests/test_syslib_pure.sh   # 3 tests, ~1s
    zsh tests/run_self_tests.sh     # 25 tests, ~3s
    zsh tests/run_stage3_tests.sh   # 3 tests, ~3s

If any of these fails on a clean checkout, please open an issue rather than assuming your setup is fine.

## Workflow

This project follows TDD. See AGENTS.md for the full rules; the short version:

1. Write a failing test first. For the bootstrap/self-hosted, that's a `tests/test_<name>.i` plus a line in `run_tests.sh` / `run_self_tests.sh`. For stage3.i, it's a fixture in `tests/run_stage3_tests.sh`. For a bug fix, it's a minimal reproducer.
2. Make it pass with the smallest change that works.
3. Don't regress anything else. The pre-push hook covers this.
4. One sub-stage per commit. Don't batch "Stage 3.1 complete" into one commit — split into 3.1.a, 3.1.b, etc.

## Multi-platform

Three platforms must stay green in CI:

- macOS ARM64 (Apple Silicon)
- Linux ARM64 (ubuntu-24.04-arm)
- Linux x86-64 (ubuntu-latest)

To reproduce a Linux job locally from macOS:

    zsh tests/cross_test.sh linux_x86_64
    zsh tests/cross_test.sh linux_arm64

If you don't have a Docker image cached, add `--image <image>` with any Linux image you do have (e.g. a locally-built application image). The wrapper auto-detects the package manager.

When you change anything under `src/runtime/`, `src/syslib/native/`, `src/bootstrap/`, or the assembly-generating code, the templates under `src/compiler/templates/` probably need to be regenerated. CI will tell you via `verify_manifest` failing.

## Commits

Subject line under 70 chars, imperative mood, no "**bold**" in markdown.

Body explains the WHY, not the WHAT. A reviewer can see the what from the diff.

If you skip the test-first rule for a valid reason (docs, CI, pure rename), say so in the commit message.

## Reporting bugs

Open an issue with:

- What you ran.
- What you expected.
- What you got (exact error including any ICLnnnI code).
- Platform (`uname -sm`).
- Output of `sh setup_platform.sh`.

If you can reproduce with a minimal `.i` program, please include it. `tools/pipeline_dump.sh program.i` generates a full snapshot of the compilation for bug reports.

## Submitting changes

1. Fork, branch, commit with tests.
2. Run the 4 suites + cross-test on at least one Linux platform.
3. Open a pull request with a clear description.
4. Be patient with reviews; maintainers may be slow.

Style: see AGENTS.md section "Best practices for INTERCAL development" for the project's INTERCAL conventions (politeness, variable ranges, NEXT stack discipline, STASH/RETRIEVE, idioms).

## What kinds of contributions are welcome

High priority:
- Bugs, especially platform-specific assembler errors or segfaults.
- Better error messages from the compiler.
- Documentation corrections.
- Additional test programs that stress real features.

Medium priority:
- Progress on the stage3.i evolving compiler (see AGENTS.md roadmap).
- Performance improvements to the bootstrap.
- Linting improvements.
- Additional shells / packaging formats.

Lower priority but considered:
- New features in extended INTERCAL (computed COME FROM, NEXT FROM, threading, TriINTERCAL, wimpmode, MAYBE).
- Windows support.
- Editor integrations.

Please check AGENTS.md "Roadmap" before picking something large; the infrastructure may not be ready yet (Phase 4 compiler work in particular depends on the loop-pattern research).

## Code of Conduct

See CODE_OF_CONDUCT.md. In short: be kind, be constructive, and assume good faith.
