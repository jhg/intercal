# Tests directory tour

The `tests/` directory holds the regression suites that keep the compiler honest. Each `test_<name>.i` is a small INTERCAL program with an expected output (or expected `ICL___I` error code); the harness runners compare actual against expected and fail loudly on any divergence.

This chapter is a one-paragraph-per-test reference so a contributor can find the right existing test before adding a new one.

For the test infrastructure (runners, suites, CI) see [testing-and-workflow.md](testing-and-workflow.md).

## Language primitives

- `test_variables.i`: assigns to a scalar and reads it back. The smallest meaningful proof-of-life for the assign + READ OUT path.
- `test_nested_expr.i`: a nested expression with sparks and rabbit-ears. Verifies the parser respects alternation and the codegen produces correct mingle / select sequences.
- `test_32bit_arith.i`: exercises 32-bit syslib labels (1500, 1530) with `:N` variables. Catches regressions in the 32-bit codegen that 16-bit tests miss.

## Control flow

- `test_control.i`: basic NEXT / RESUME pair. The smallest subroutine call.
- `test_come_from.i`: exercises `COME FROM`. Confirms the static back-edge is emitted and the targeted statement does not fall through.
- `test_forget.i`: `FORGET` pops NEXT-stack frames without transferring. Used in loop patterns to prevent stack growth.
- `test_give_up.i`: single-statement `DO GIVE UP`. The minimum legal program. Also exercises the politeness-rule's 5-statement floor (with one statement and zero `PLEASE`, the program would otherwise fail `ICL079I`).

## State management

- `test_stash.i`: STASH and RETRIEVE round-trip. Confirms the per-variable stash stack works end-to-end.
- `test_ignore_remember.i`: `IGNORE` makes a variable read-only; `REMEMBER` reverses it. Verifies the per-variable ignore-flag check is emitted at every store.
- `test_abstain.i`: `ABSTAIN FROM (label)` deactivates a specific statement; `REINSTATE` reverses. Verifies the `_stmt_flags` byte is loaded and tested at every statement entry.
- `test_abstain_gerund.i`: `ABSTAIN FROM CALCULATING` deactivates all assignments. Exercises the gerund-name resolution and the bulk flag-update codegen.

## Arithmetic via syslib

- `test_syslib.i`: basic addition through label 1000.
- `test_multiply.i`: multiplication through label 1030.
- `test_divide.i`: division through label 1040.
- `test_multidim_array.i`: 2D array dimensioned with `BY`, then per-element access. Covers the linear-index calculation in `codegen_array_ref`.

## I/O

- `test_hello.i`: prints `Hello, World!` via the Turing Text Model. The canonical TTM exercise. See [walkthrough-hello.md](walkthrough-hello.md) for the full trace.
- `test_read_out_num.i`: single scalar output as a Roman numeral. Exercises `_rt_write_roman`.
- `test_read_out_multi.i`: multiple scalars in a single `READ OUT` statement. Verifies the parser handles variable lists.
- `test_overbar.i`: output of values above 4000, exercising the overbar (vinculum) notation in `_rt_write_roman`.
- `test_write_in.i`: read a number from stdin in spelled-out English digit names. Exercises `_rt_write_in_scalar`.

## Politeness errors

- `test_errors_rude.i`: a program with too few `PLEASE`s. Expected to fail compilation with `ICL079I`. The runner asserts the error fires and the binary is not produced.
- `test_errors_polite.i`: too many `PLEASE`s. Expected to fail with `ICL099I`.

## Runtime errors

- `test_error_e123.i`: recursive NEXT without `FORGET` until the 80-deep stack overflows. Expected to fire `ICL123I` at runtime.
- `test_error_e182.i`: duplicate label. Compile-time error `ICL182I`.
- `test_error_e240.i`: array dimensioned to zero. Runtime error `ICL240I`.
- `test_error_e241.i`: out-of-bounds array subscript. Runtime error `ICL241I`.
- `test_error_e275.i`: assignment of a 32-bit value to a 16-bit slot. Runtime error `ICL275I`.
- `test_error_e436.i`: RETRIEVE with no preceding STASH. Runtime error `ICL436I`.
- `test_error_e621.i`: `RESUME #0`. Runtime error `ICL621I`.
- `test_error_e632.i`: `RESUME` when the NEXT stack is empty. Runtime error `ICL632I`.
- `test_error_e633.i`: fall off the end of the program without `GIVE UP`. Runtime error `ICL633I`.

## Probabilities

- `test_probability_zero.i`: `%0` modifier; the statement is dead code. Verifies the compiler emits the random-roll check correctly and the body never executes when the threshold is zero.

## Label 666

- `test_syscall_readself.i`: opens its own source file via syscall 1, reads the first byte via syscall 2, prints it as a Roman numeral. The end-to-end exercise of Label 666 plus `,65535` plus argv access.

## How to add a new test

The TDD workflow lives in `AGENTS.md`. The mechanical recipe:

1. Create `tests/test_<feature>.i` with the minimal INTERCAL program that exercises the new behaviour.
2. Open `tests/run_tests.sh` and add a `_run_test` (or `_run_error_test`) line at the appropriate place.
3. Set the expected output as a literal string, or write `tests/test_<feature>.expected` for multi-line output.
4. Run `zsh tests/run_tests.sh --filter <feature>`. The test should fail (red).
5. Implement the feature in `intercalc.sh` (and runtime / syslib if needed).
6. Run again. The test should pass (green).
7. Run the full suite. Nothing else should regress.

For a self-hosted compiler change, repeat the cycle in `tests/run_self_tests.sh` or `tests/run_stage3_tests.sh`. Templates may need regenerating via `tools/gen_manifest.sh`.

## Cross-suite test parity

The bootstrap suite (`run_tests.sh`) and the self-hosted MVP suite (`run_self_tests.sh`) cover the same set of test programs by design, every program that the bootstrap can compile has a pre-generated template that the MVP can dispatch to. When you add a new bootstrap test, you should also add (or accept that you cannot yet add) the matching self-hosted entry. The stage3 suite is independent: it tests the evolving compiler's small range of supported features only.

## Exercises

1. Run a single test: `zsh tests/run_tests.sh --filter come_from`. What is the expected output? Compare with the actual output by inspection.
2. Modify `tests/test_hello.i` to print "Hello," followed by a different name. Compute the new TTM deltas with the encoder from [turing-text-model.md](turing-text-model.md), update the test, and run.
3. The runtime-error tests share a pattern: each fails deliberately with a specific `ICL___I` code. Construct the smallest INTERCAL program that fires `ICL129I` (NEXT to unknown label, now compile-time). Why does the test set not currently include it?
4. `test_syscall_readself.i` reads its own source. Trace which Label 666 syscalls fire, in which order, and what the expected output looks like.
5. The 30 bootstrap tests are not exhaustive. INTERCAL has surface that no test covers. Pick one (e.g. `WRITE IN ,1` for an array, or `%50` probability) and write a test for it.

## Next reading

- [testing-and-workflow.md](testing-and-workflow.md): the runners and the TDD discipline that makes the suite useful.
- [debugging.md](debugging.md): what to do when a test fails.
- [your-first-contribution.md](your-first-contribution.md): the broader walkthrough of which a test addition is one step.
