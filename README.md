# intercal

A self-hosting INTERCAL compiler targeting native ARM64 and x86-64 binaries. No C or Rust intermediate step — INTERCAL source goes straight through our toolchain to Mach-O (macOS) or ELF (Linux).

## Status

Phase 1 bootstrap complete. Phase 2 MVP self-hosted dispatcher complete. Phase 4 real lexer/parser/codegen in progress under `src/compiler/stage3.i`.

Test results (3 platforms, all green in CI):

| Suite | Count | What it covers |
|-------|-------|----------------|
| `tests/run_tests.sh` | 25 | Bootstrap compiler, full language |
| `tests/test_syslib_pure.sh` | 3 | Pure INTERCAL syslib vs native assembly |
| `tests/run_self_tests.sh` | 25 | Self-hosted MVP (template-passthrough) |
| `tests/run_stage3_tests.sh` | 3 | Evolving compiler (stage3.i) |

Supported platforms: macOS ARM64, Linux ARM64, Linux x86-64. Windows planned.

## Quick start

Compile a program with the bootstrap compiler:

    zsh src/bootstrap/intercalc.sh < program.i > program && chmod +x program
    ./program

Using the self-hosted wrapper (requires `intercal_core` built once):

    zsh src/bootstrap/intercalc.sh < src/compiler/compiler.i > intercal_core
    chmod +x intercal_core
    ./intercal program.i -o program
    ./program

Run `./intercal tests/test_hello.i -o hello && ./hello` to see `Hello, World!`.

## Installing from a release

Pick the matching artifact from the latest GitHub Release:

- `intercal-macos-arm64.zip` — Apple Silicon macOS.
- `intercal-linux-arm64.{tar.gz,deb,rpm,zip}` — Linux ARM64.
- `intercal-linux-x86_64.{tar.gz,deb,rpm,zip}` — Linux x86-64.

Each archive ships a pre-built `intercal_core`, the wrapper, runtime, syslib, and tests. Packages install the wrapper to `/usr/bin/intercal` (symlink into `/usr/lib/intercal/`).

Dependencies: `zsh` and `gcc` (or any `cc`-compatible compiler driver). Both are declared in the `.deb`/`.rpm` metadata.

## Architecture

Pipeline per compilation:

1. Compiler (bootstrap or self-hosted) emits program assembly for the detected platform.
2. Wrapper concatenates `src/runtime/<platform>.s` + `src/syslib/native/<platform>.s` + program assembly.
3. `cc -x assembler -` produces the final binary.

The runtime provides: I/O (Roman numerals, Turing Text Model, English digit names), operators (mingle, select, unary AND/OR/XOR), mmap-backed allocation, NEXT/RESUME stack, 16 runtime error codes, and a Label 666 syscall dispatcher (open, read, write, close, argc, argv, exit, getrand).

The syslib exposes arithmetic at labels 1000-1999 (16-bit and 32-bit add/sub/mul/div, random). Native assembly is default; `--pure-syslib` swaps to the INTERCAL version for verification.

See [AGENTS.md](AGENTS.md) for complete architecture, INTERCAL language reference, platform-specific assembly pitfalls, and development workflow.

## Development

One-time setup after cloning:

    sh tools/install_hooks.sh   # enable pre-commit and pre-push test hooks

Day-to-day:

    zsh tests/run_tests.sh --filter "give_up"   # run a single test
    zsh tests/run_tests.sh --verbose            # show cc stderr on failure
    zsh tests/run_tests.sh --keep               # preserve artifacts in /tmp/intercal_failures

Reproduce a Linux CI job locally (requires Docker):

    zsh tests/cross_test.sh linux_x86_64
    zsh tests/cross_test.sh linux_arm64 --image ubuntu:24.04

Template integrity:

    zsh tools/gen_manifest.sh     # after regenerating templates
    zsh tools/verify_manifest.sh  # fails if any template is modified or missing

Write new INTERCAL test programs under `tests/test_<name>.i`, register them in `tests/run_tests.sh`, and follow the TDD workflow described in AGENTS.md (red test before code, one sub-stage per commit, no regressions).

## Repository layout

    src/
      bootstrap/intercalc.sh        Bootstrap compiler (zsh, primary)
      bootstrap/codegen_x86_64.sh   x86_64 backend override
      runtime/<platform>.s          Native runtime per platform
      syslib/syslib.i               Pure INTERCAL syslib (9065 lines)
      syslib/native/<platform>.s    Native syslib per platform
      compiler/compiler.i           Self-hosted MVP (template dispatch)
      compiler/stage3.i             Evolving real compiler (Phase 4)
      compiler/templates/           Pre-generated assembly per test per platform
    tests/
      run_tests.sh                  Bootstrap tests
      run_self_tests.sh             Self-hosted MVP tests
      run_stage3_tests.sh           Stage 3 tests
      test_syslib_pure.sh           Pure vs native syslib equivalence
      cross_test.sh                 Docker-based Linux reproduction
      test_<name>.i                 Individual test programs
    tools/
      gen_manifest.sh               Regenerate template sha256 manifest
      verify_manifest.sh            Verify manifest integrity
      install_hooks.sh              Opt into git hooks
    .githooks/
      pre-commit                    verify_manifest + run_tests
      pre-push                      all 4 suites
    .github/workflows/
      ci.yml                        3-platform CI
      release.yml                   9-artifact release on v* tags
    docs/
      666.md                        Label 666 syscall design rationale

## License

This project is released into the public domain. See LICENSE.

## References

- The INTERCAL-72 reference manual (Woods/Lyon, 1973)
- C-INTERCAL documentation at http://catb.org/~esr/intercal/
- CLC-INTERCAL at https://uilebheist.srht.site/

This compiler is a clean-room implementation: no code or text is copied from those distributions. Behavior matches the standard language; error codes follow ICLnnnI convention.
