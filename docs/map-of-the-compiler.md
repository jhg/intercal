# Map of the compiler

This chapter maps the classical compiler phases (scanner, parser, semantic analysis, code generation, runtime) onto the files and line ranges of this repository. Use it to find the right file to read or modify.

For the narrative explanation of each phase, follow the links into the per-phase chapters.

## Phase overview

The bootstrap compiler lives almost entirely in a single zsh file, `src/bootstrap/intercalc.sh`. It is organised into numbered sections. The table below lists the sections and how they map to the standard compiler phases.

| Phase (textbook name) | Our implementation | File | Approx. lines |
|-----------------------|--------------------|------|---------------|
| Driver / entry | `main()` | `src/bootstrap/intercalc.sh` | 1717–1825 |
| Source reader | `read_source()` | `src/bootstrap/intercalc.sh` | 59–66 |
| Lexer (scanner) | `tokenize()` | `src/bootstrap/intercalc.sh` | 68–261 |
| Symbol collection | `scan_variables()` | `src/bootstrap/intercalc.sh` | 262–294 |
| Semantic analysis | `check_politeness()`, `check_labels()`, `resolve_come_from` | `src/bootstrap/intercalc.sh` | 295–398 |
| Parser (numbers) | `parse_number()` | `src/bootstrap/intercalc.sh` | 399–414 |
| Parser (expressions) | `parse_expr()` | `src/bootstrap/intercalc.sh` | 415–602 |
| Codegen (expressions) | `codegen_expr()`, `codegen_array_ref()` | `src/bootstrap/intercalc.sh` | 603–762 |
| Codegen (program entry) | `codegen_program()`, `codegen_statement()` | `src/bootstrap/intercalc.sh` | 763–852 |
| Codegen (per statement type) | `codegen_give_up`, `codegen_read_out`, `codegen_write_in`, `codegen_assign`, `codegen_array_dim`, `codegen_next`, `codegen_resume`, `codegen_forget`, `codegen_abstain`, `codegen_reinstate`, `codegen_gerund_modify`, `codegen_ignore`, `codegen_remember`, `codegen_stash`, `codegen_retrieve` | `src/bootstrap/intercalc.sh` | 853–1621 |
| Data emission (.data, .bss) | `emit_data()` | `src/bootstrap/intercalc.sh` | 1622–1716 |

Counts are approximate line numbers in the current version; they are there as a navigation aid, not a contract.

## Runtime and syslib

The runtime is platform-specific hand-written assembly. It provides everything the generated code calls out to: I/O, operators, error handling, the Label 666 syscall dispatcher.

    src/runtime/macos_arm64.s       Runtime for Apple Silicon macOS (Mach-O, svc #0x80).
    src/runtime/linux_arm64.s       Runtime for Linux aarch64 (ELF, svc #0, openat).
    src/runtime/linux_x86_64.s      Runtime for Linux x86-64 (ELF, syscall, Intel syntax).
    src/syslib/syslib.i             Pure INTERCAL arithmetic library, 9065 lines, 20 labels.
    src/syslib/native/<platform>.s  Native-assembly version of the same 20 labels, ~300 lines.

Inside each runtime file, routines follow the naming convention `_rt_<name>`. The key entry points on `macos_arm64.s`:

    _rt_mingle, _rt_select                 Operator primitives ($, ~)
    _rt_unary_and_16, _rt_unary_or_16, _rt_unary_xor_16    &, V, ? on 16-bit
    _rt_unary_and_32, _rt_unary_or_32, _rt_unary_xor_32    same on 32-bit
    _rt_write_roman                        READ OUT for scalars (Roman numerals)
    _rt_read_out_array                     READ OUT for arrays (Turing Text Model)
    _rt_write_in_array                     WRITE IN for arrays
    _rt_write_in_scalar                    WRITE IN for scalars (English digit names)
    _rt_mmap                               Memory allocation wrapper
    _rt_resume_1                           RESUME helper
    _rt_error_E000 ... _rt_error_E633      16 runtime error exits
    _rt_syscall_666                        Label 666 dispatcher
    _rt_sys666_open/read/write/close       File I/O syscalls
    _rt_sys666_argc/argv                   Argument access
    _rt_sys666_exit                        Program exit with code
    _rt_sys666_getrand                     Randomness for syslib 1900/1910

The Linux ARM64 and Linux x86-64 runtimes are translated versions of the same logic. See [platforms.md](platforms.md) for the differences.

## Self-hosted compiler

    src/compiler/compiler.i                  Self-hosted MVP — template-dispatch passthrough.
    src/compiler/stage3.i                    Evolving real compiler — Phase 4 work-in-progress.
    src/compiler/templates/<platform>/*.s    Pre-generated assembly per test program per platform.
    src/compiler/templates/manifest.txt      SHA-256 manifest for integrity checking.

The MVP classifies incoming programs by content hash and emits the matching pre-generated assembly. It is not a real compiler — it's just enough of one to prove the self-hosted pipeline end-to-end (read a `.i` file via Label 666, emit assembly to stdout, let the wrapper link it). See [self-hosting.md](self-hosting.md).

`stage3.i` is where the real lexer / parser / codegen is slowly being rewritten in pure INTERCAL. Today (2026-04-21) it only reads the source file and prints byte-count and first/last byte diagnostics.

## Wrapper scripts

    intercal                 Self-hosted compiler wrapper (uses intercal_core + templates).
    bootstrap.sh             Three-generation fixpoint bootstrap (requires a real compiler.i).
    setup_platform.sh        Print the detected platform name for sanity check.

## Tests

    tests/run_tests.sh               Bootstrap compiler, 25 tests, full language coverage.
    tests/test_syslib_pure.sh        Pure vs native syslib equivalence, 3 tests.
    tests/run_self_tests.sh          Self-hosted MVP dispatcher, 25 tests.
    tests/run_stage3_tests.sh        Evolving compiler (stage3.i), 3 tests.
    tests/cross_test.sh              Docker wrapper to reproduce Linux CI jobs locally.
    tests/test_<name>.i              Individual INTERCAL programs driving the suites.

See [testing-and-workflow.md](testing-and-workflow.md).

## Tools

    tools/gen_manifest.sh        Regenerate the SHA-256 template manifest.
    tools/verify_manifest.sh     Verify templates have not drifted.
    tools/pipeline_dump.sh       Dump the intermediate assembly for debugging.
    tools/install_hooks.sh       Install the repo's pre-commit and pre-push git hooks.
    tools/lint_intercal.sh       Lint .i files (politeness balance, basic sanity).
    tools/lint_assembly.sh       Lint .s files for platform-specific pitfalls.

## Git hooks and CI

    .githooks/pre-commit         verify_manifest + run_tests.
    .githooks/pre-push           all four test suites.
    .github/workflows/ci.yml     3-platform CI (macOS ARM64, Linux ARM64, Linux x86-64).
    .github/workflows/release.yml 9-artifact release on v* tags (zip / tar.gz / deb / rpm).

## Top-level files worth knowing

| File | Purpose |
|------|---------|
| `README.md` | Quick start, install, test counts, repo layout. |
| `AGENTS.md` (symlinked as `CLAUDE.md`) | Authoritative contributor reference: language, pitfalls, TDD workflow. |
| `SECURITY.md` | Security model, known limitations, threat-model notes. |
| `TODO.md` | Working notes between sessions (not project documentation). |
| `CODE_OF_CONDUCT.md` | Standard Contributor Covenant. |
| `LICENSE` | Public domain (Unlicense). |
