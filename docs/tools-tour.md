# Tools tour

The `tools/` directory holds the supporting scripts that surround the compiler: benchmarks, linters, manifests, hooks, the pipeline introspector, and the reproducible-build helper. None of them are required to build INTERCAL programs (`intercalc.sh` does that on its own), but each addresses a real maintenance need.

This chapter is a one-paragraph-per-tool reference for what every script does, when to use it, and what flags it accepts.

## build_syslib.sh, warm the pure-syslib cache

    tools/build_syslib.sh

Pre-compiles `src/syslib/syslib.i` for the current platform and writes the result into the user's cache directory at `$XDG_CACHE_HOME/intercal/syslib-<platform>-<hash>.s` (default `$HOME/.cache/intercal/`). The cache key is the SHA-256 of `syslib.i`, so the file auto-invalidates whenever the syslib changes.

After running this once, every subsequent compilation with `INTERCAL_SYSLIB=cache` skips the 30–100-second penalty of recompiling the pure syslib. Run in CI / release pipelines so end users do not pay the cold-cache cost. If you never use `INTERCAL_SYSLIB=cache`, you can ignore this script entirely; native (the default) does not touch the cache.

## bench.sh, performance dashboard

    tools/bench.sh                       # default tabular output
    tools/bench.sh --json                # JSON, one record per benchmark
    tools/bench.sh --json > before.json  # save a baseline
    tools/bench.sh --compare before.json # diff the current run against a baseline

Runs a fixed set of compile-and-run benchmarks: bootstrap compile of a single-statement program, bootstrap compile of hello world, full bootstrap test suite, self-hosted-core build, stage3 build, full self-hosted test suite. Each is timed (wall, user, system) by zsh's `time` builtin. The JSON form is structured so you can `jq` it; the compare mode prints percentage deltas. Use it when you have made a compiler change you suspect might have a performance impact, or when you want to track compile-time evolution across releases.

## gen_manifest.sh, regenerate the template SHA-256 manifest

    tools/gen_manifest.sh

Walks every `.s` file under `src/compiler/templates/`, computes its SHA-256, writes the result to `src/compiler/templates/manifest.txt`. Run this once whenever you change one or more templates (because the bootstrap codegen for that test program changed). The manifest is committed alongside the templates so that integrity can be verified later.

The script handles the platform difference between `shasum` (BSD/macOS) and `sha256sum` (GNU/Linux) automatically. It produces deterministic output: same input templates produce a byte-identical manifest.

## verify_manifest.sh, verify the template manifest

    tools/verify_manifest.sh

Verify that every template referenced in `manifest.txt` exists, that no templates exist that the manifest does not list, and that every recorded SHA-256 matches its file. Exit code zero on success, non-zero on any drift. Run automatically by the pre-commit hook and by CI before the test suites; intended to catch the case where somebody edits a template without regenerating the manifest.

## install_hooks.sh, opt into the project's git hooks

    sh tools/install_hooks.sh

Configures `core.hooksPath` to `.githooks/` in the local clone. After running, every commit triggers `verify_manifest.sh` plus a fast bootstrap test run; every push triggers all four test suites. Undo with `git config --unset core.hooksPath`. Run this once after cloning the repo and before your first commit.

## lint_assembly.sh, platform-aware lint for `.s` files

    tools/lint_assembly.sh src/runtime/macos_arm64.s
    find src/compiler/templates -name '*.s' | xargs -I{} tools/lint_assembly.sh {}

Static checks tailored to each target platform: macOS ARM64 wants `_` prefixes on exported symbols, `@PAGE`/`@PAGEOFF` relocations, `svc #0x80` for syscalls; Linux ARM64 wants no underscore prefix, `:lo12:` relocations, `svc #0`; Linux x86-64 wants `#` comments rather than `//`, no three-register addressing, Intel syntax. The platform is auto-detected from the file path or can be passed explicitly. Useful when you have hand-written or modified assembly and want to verify it before running the full test suite.

## lint_intercal.sh, static checks for INTERCAL source

    tools/lint_intercal.sh tests/test_hello.i
    find tests -name 'test_*.i' | xargs tools/lint_intercal.sh

Reports the politeness ratio, flags labels in the syslib reserved range, warns on RESUME with potential zero, warns on missing `GIVE UP`. Output format is `path:line: level: message`. Exit zero if there are no errors (warnings still allowed); exit one if any error is found.

A `.i` file can opt out of specific checks with a magic comment: `DON'T NOTE LINT-SKIP: politeness labels resume`. Supported tokens are `politeness`, `labels`, `resume`, and `all`. Use `all` to silence the linter entirely on a file that is intentionally unusual.

## pipeline_dump.sh, introspect each phase of compilation

    tools/pipeline_dump.sh tests/test_hello.i
    tools/pipeline_dump.sh program.i --platform linux_x86_64
    tools/pipeline_dump.sh program.i --out /tmp/dump

Writes a directory containing every intermediate stage: the source as-is, the whitespace-normalised source, the statement list, the politeness count, the program-only assembly, the platform runtime, and the combined assembly that goes to `cc`. Useful for explaining the pipeline to a newcomer or when debugging a codegen issue that is easier to diagnose by reading the intermediate output rather than the final binary.

The `--out` flag lets you redirect the dump to a specific directory. The default `/tmp/intercal_dump` is wiped between runs.

## rewrite_uuid.py, deterministic Mach-O LC_UUID

    tools/rewrite_uuid.py path/to/binary

Rewrites the `LC_UUID` load command in a Mach-O binary with a SHA-256-derived UUID computed from the binary itself (with the UUID field zeroed during the hash). This makes the binary's identity bytes reproducible across compilation runs. The script handles the structural details of Mach-O, magic check, `nfat`/`ncmds` parsing, finding the right load command, and leaves the rest of the binary untouched.

Caveat: rewriting the UUID invalidates any embedded ad-hoc code signature. Apple Silicon requires that compiled executables be code-signed (even ad-hoc), so the typical sequence is: build → rewrite_uuid → re-sign with `codesign -fs -`. The release pipeline does this automatically.

The script is Python rather than zsh because the Mach-O parsing is structural enough that string-manipulation in shell would be more error-prone than running a small struct-parser. It is the only Python dependency in the repository, and it runs with no third-party packages, only the stdlib.

## When to reach for which tool

| Situation | Tool |
|-----------|------|
| Wrote a new INTERCAL program | `lint_intercal.sh` |
| Modified `intercalc.sh` and want to inspect output | `pipeline_dump.sh` |
| Modified a runtime or syslib `.s` file | `lint_assembly.sh` |
| Modified one or more `templates/*.s` | `gen_manifest.sh`, then `verify_manifest.sh` |
| Suspect a performance regression | `bench.sh --compare` against a saved baseline |
| Cloned the repo for the first time | `install_hooks.sh` |
| Want a reproducible Mach-O binary | `rewrite_uuid.py` (called by the release pipeline) |

## Exercises

1. Run `tools/bench.sh --json` and inspect the output. Which benchmark is the slowest? Why?
2. Take a passing test program, edit it slightly, and run `tools/lint_intercal.sh` on the result. What does the linter say? Does the politeness ratio change as expected?
3. Read `tools/rewrite_uuid.py` (about 100 lines). Identify the load-command magic for `LC_UUID` and the size of its body. What other load commands does Mach-O define that we might one day need to handle?
4. The `bench.sh` benchmarks include `bootstrap_simple` (compile `tests/test_give_up.i`). What fraction of that time is `cc -x assembler -` versus the rest of the pipeline?
5. Write a small INTERCAL program that intentionally violates two distinct lint rules. Verify that `lint_intercal.sh` reports both, and that the magic comment `DON'T NOTE LINT-SKIP: all` silences them.

## Next reading

- [debugging.md](debugging.md): uses `pipeline_dump.sh` and `bench.sh` extensively.
- [testing-and-workflow.md](testing-and-workflow.md): uses `verify_manifest.sh` in pre-commit, runs the test suites that `bench.sh` measures.
- [executables-and-linking.md](executables-and-linking.md): context for `rewrite_uuid.py` and the LC_UUID load command.
