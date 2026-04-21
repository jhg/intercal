# Your first contribution

This chapter walks a new collaborator through landing their first change on this project. It assumes you have cloned the repository and can build and test it (see [getting-started.md](getting-started.md)). The target is a small, well-scoped change that exercises the entire workflow — branch, write a test, implement, run tests locally, commit, push — without requiring deep understanding of any single component.

We will pick one specific example: adding a new error message to the runtime. This change is realistic, touches both the runtime assembly and the test suite, and produces something useful that the project would actually want.

## The change, in plain English

The runtime today fires errors for many conditions: `ICL275I` for assigning a 32-bit value to a 16-bit slot, `ICL123I` for a NEXT stack overflow, and so on. Suppose we want to add a new error for a hypothetical condition that is not yet detected — say, `ICL888I` for "PROGRAM CONTAINS A FIXME THAT SHOULD HAVE BEEN ADDRESSED BY NOW". This is a deliberately fictitious error; the point is to practise the mechanics.

The steps:

1. Create a branch.
2. Write a failing test that expects `ICL888I` on stderr.
3. Add the error message to the runtime.
4. Add a codegen path that emits the error.
5. Run the tests locally.
6. Commit and push.
7. (Optionally) open a pull request.

## Step 1: Create a branch

    git checkout -b my-first-contribution

Branch names in this project are informal. Something descriptive is enough.

## Step 2: Write the failing test

We need an INTERCAL program that triggers `ICL888I`. Since there is no trigger yet, the test will fail.

Create `tests/test_error_e888.i`:

    DO FIXME
    DO GIVE UP

The exact contents depend on what `FIXME` is supposed to mean. For now, assume we will teach the compiler to recognise `FIXME` as a keyword that emits a runtime error unconditionally.

Register the test by adding a line near the bottom of `tests/run_tests.sh`:

    _run_error_test "error_e888" "ICL888I"

The `_run_error_test` helper is already defined in the runner; it compiles the program, runs it, and asserts that the specified ICL code appears on stderr.

Now run the suite:

    zsh tests/run_tests.sh --filter error_e888

The test should fail. The compiler does not know what `FIXME` means, so it will classify `DO FIXME` as an UNKNOWN statement, which emits `_rt_error_E000` (not E888). You will see:

    FAIL error_e888 (expected ICL888I, got ICL000I)

Good. Failing test in hand, we can proceed.

## Step 3: Add the error message to the runtime

Open `src/runtime/macos_arm64.s`. Find the block of `_rt_error_*` routines (around line 369). They all look like:

    _rt_error_E123:
      adrp x1, _errmsg_123@PAGE
      add x1, x1, _errmsg_123@PAGEOFF
      mov x2, #54                    ; message length in bytes
      mov x0, #2                     ; fd 2 (stderr)
      mov x16, #4                    ; write syscall
      svc #0x80
      mov x0, #1                     ; exit status 1
      mov x16, #1                    ; exit syscall
      svc #0x80

Add a new block:

    _rt_error_E888:
      adrp x1, _errmsg_888@PAGE
      add x1, x1, _errmsg_888@PAGEOFF
      mov x2, #MESSAGE_LENGTH
      mov x0, #2
      mov x16, #4
      svc #0x80
      mov x0, #1
      mov x16, #1
      svc #0x80

Where `MESSAGE_LENGTH` is the length of your new error string. Let's use:

    ICL888I PROGRAM CONTAINS A FIXME\n

Count the bytes, including the newline: 35.

Find the block of `_errmsg_*` definitions in the `.data` section (near the bottom of the file). Add:

    _errmsg_888: .ascii "ICL888I PROGRAM CONTAINS A FIXME\n"

Repeat this change in `src/runtime/linux_arm64.s` and `src/runtime/linux_x86_64.s`. Note that Linux ARM64 uses `svc #0`, `mov x8, #93` for exit and `mov x8, #64` for write; x86-64 uses entirely different syntax. See [platforms.md](platforms.md) for the syntactic differences. The three files must stay in sync.

## Step 4: Add the codegen path

Open `src/bootstrap/intercalc.sh` and find the `tokenize()` function. Add recognition of the `FIXME` keyword (around the existing statement-type detection logic):

    elif [[ "$body" == "FIXME" || "$body" == FIXME* ]]; then
      stmt_type[stmt_count]="FIXME"
      stmt_body[stmt_count]="$body"

Then find `codegen_statement` and add a case for `FIXME`:

    FIXME) emit "  bl _rt_error_E888" ;;

The x86-64 backend in `src/bootstrap/codegen_x86_64.sh` does not need changes for this particular case because the `bl` instruction is architecture-specific — but the x86-64 backend does need to emit `call _rt_error_E888` instead. Find `codegen_x86_64.sh`'s equivalent dispatch and add the override.

## Step 5: Run the tests locally

    zsh tests/run_tests.sh --filter error_e888

Expected: `PASS error_e888 (runtime error 888)`.

Then run the full suite to make sure nothing else broke:

    zsh tests/run_tests.sh

If any test that previously passed now fails, your change has unintended consequences. Common causes:

- A token that was previously valid (`FIXME` as a variable name, say) now matches your new keyword. Unlikely for this specific word, but real for more ordinary keywords.
- The runtime `.data` section alignment was broken by inserting a new message at the wrong byte offset. Review the Mach-O / ELF section directives.

Iterate until the full suite is green.

## Step 6: Commit

    git add tests/test_error_e888.i tests/run_tests.sh src/runtime/*.s src/bootstrap/intercalc.sh src/bootstrap/codegen_x86_64.sh
    git commit -m "Add ICL888I runtime error for FIXME statements

    Introduces a new runtime error code 888 fired when a program contains
    a FIXME statement. Motivation: give programmers a way to explicitly
    mark incomplete work so the compiler enforces addressing it at runtime
    rather than silently accepting.

    Co-Authored-By: Your Name <email@example.com>
    "

Commit messages in this project describe the *why*, not the *what*. A diff shows what changed; the message should explain the motivation.

The project's pre-commit hook will now run: it will verify the template manifest (no changes there, should pass) and run the bootstrap test suite. If the tests are green, the commit succeeds.

## Step 7: Push

    git push -u origin my-first-contribution

The pre-push hook will run all four test suites before pushing to the remote. Depending on your machine, this takes 1–2 minutes. If any suite fails, the push is aborted; fix and try again.

Once the push succeeds, you can open a pull request on GitHub targeting `main`.

## What you just did

You touched every layer of the project:

- A test that articulates the expected new behaviour.
- The runtime assembly, in three platform variants.
- The compiler's tokeniser and codegen.
- The test runner registration.

That pattern — test first, touch every affected file, iterate until green — is the workflow the project expects for any non-trivial change. Smaller changes follow the same pattern with fewer files.

## Common stumbling blocks

- **The three runtime files drift out of sync.** If `src/runtime/macos_arm64.s` gets a new error but the Linux files do not, CI will pass on macOS and fail on Linux. Always edit all three (or explicitly skip the Linux ones with a TODO if the feature is genuinely macOS-specific, which is rare).
- **The pre-commit hook's template-manifest check fails.** This happens if you touched `src/compiler/templates/` without regenerating the manifest via `zsh tools/gen_manifest.sh`. Usually a signal that you changed something you didn't intend to.
- **The test runner's assertion pattern misfires.** If your error message contains special regex characters or Roman numerals that also match other error codes, the runner may match the wrong string. Debug with `zsh tests/run_tests.sh --verbose --filter your_test` to see the raw output.

## Where to go next

- For changes to the front end (lexer, parser, semantic analysis), start with [lexing-and-parsing.md](lexing-and-parsing.md) and [semantic-analysis.md](semantic-analysis.md).
- For changes to the back end (codegen, runtime, syslib), start with [code-generation.md](code-generation.md) and [runtime.md](runtime.md).
- For changes to the self-hosted compiler (`compiler.i`, `stage3.i`), start with [self-hosting.md](self-hosting.md) and be especially careful about the TDD rule.
- For changes to the testing infrastructure, start with [testing-and-workflow.md](testing-and-workflow.md).
- For AI-assisted work specifically, see [ai-collaboration.md](ai-collaboration.md) and `AGENTS.md`.

Welcome aboard.
