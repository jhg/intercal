# Semantic analysis

By the time the lexer finishes, the compiler knows enough about every statement to start checking program-wide properties. Three checks run in `src/bootstrap/intercalc.sh` between tokenisation and codegen:

- `check_politeness` — the PLEASE ratio must be in [1/5, 1/3] (programs of fewer than five statements bypass the rule).
- `check_labels` — labels must be in the range 1–65535 and unique; build the label → statement-index map.
- `resolve_come_from` — match every `COME FROM (N)` to the labelled statement it targets, rejecting duplicate targets.

These are almost the entirety of the static analysis the compiler performs. Everything else in the INTERCAL error catalogue (undefined variable, dimension zero, bad subscript, overflow, ...) fires at runtime, because INTERCAL's statement-level activation model makes most conditions undecidable at compile time.

## Politeness: why it matters to the compiler

The politeness rule is, in compiler-theory terms, a whole-program static check. It is also the only way for the compiler to reject a syntactically well-formed program. Because it is the only compile-time check, the test suites spend real effort on it: `tests/test_errors_rude.i` exercises the "too rude" branch and `tests/test_errors_polite.i` the "too polite" branch. Both fail deliberately with ICL079I and ICL099I respectively, and the harness grep-checks stderr for the code.

The implementation in `check_politeness` is short: count the number of statements whose `stmt_polite` is 1, compare `polite*5 >= total` and `polite*3 <= total`, fire `die_compile 079` or `die_compile 099` otherwise.

The check is bypassed entirely when the program has fewer than five statements. The 1972 manual is silent on this corner; we follow the C-INTERCAL precedent of letting tiny programs through. This is why `tests/test_give_up.i`, a single-statement program with no `PLEASE`, compiles cleanly even though 0/1 = 0% is well below the 20% lower bound.

### Why the bounds are asymmetric

The spec says *at least* 1/5 and *at most* 1/3. At 5 statements one PLEASE is enough (lower bound met) but two is one too many (upper bound exceeded). At 12 statements you need between 3 and 4 PLEASEs. The compiler uses integer arithmetic with the cross-multiplied form to avoid floating point:

    polite * 5 >= total     ≡   polite/total >= 1/5
    polite * 3 <= total     ≡   polite/total <= 1/3

Off-by-one errors here would silently accept or reject programs that are on the boundary. The cross-multiplied form is exact.

### What counts as polite

`stmt_polite[i]` is set during tokenisation when the verb is `PLEASE` or `PLEASE DO` (or `PLEASE DON'T`). Anything starting with `DO` (or `DON'T`) counts as 0. This matches the language specification: `PLEASE DO` is politer than `DO`, but `DO` is identical to nothing.

Comments do not exist in INTERCAL, so there is no debate about whether a comment statement counts. `DON'T NOTE ...` is a real statement; it just never executes. It is still included in the denominator.

## Label uniqueness and the label map

`check_labels` walks `stmt_label` and registers each non-empty label in the associative array `label_to_stmt`. Two failure modes:

- A label outside the 1–65535 range fires `ICL197I LABEL VALUE OUTSIDE PERMITTED RANGE`. This catches typos like `(0)` or `(70000)`.
- A duplicate label (the same number on two statements) fires `ICL182I DUPLICATE LINE LABEL DETECTED`.

The map is essential for the phases that follow:

- `NEXT` codegen needs to turn the numeric label into the address of the corresponding `_stmt_i_body` symbol.
- `COME FROM` resolution needs to find the statement with that label so it can install the back-edge.
- `ABSTAIN FROM (N)` and `REINSTATE (N)` codegen need the statement index to locate the bit in `_stmt_flags`.

Labels 1000–1999 are reserved for the syslib. `check_labels` does not enforce this today — that is a latent consistency gap we rely on programmers to respect. If user code defines a label in 1000–1999, the syslib's own definition of the same label will either override or conflict depending on link order. The syslib is always concatenated after the user code, so the user's label wins; if the user did not also define the syslib's internal jumps, the syslib itself may break. A compile-time check for this is listed in the TODO.

## COME FROM resolution

`COME FROM (N)` is the inverse of `GOTO`: the targeted statement doesn't know it has a follower. Our implementation resolves the relationship statically so the runtime cost is a single unconditional jump appended to statement `N`'s body.

The algorithm:

1. For each statement `i` of type `COME_FROM`, extract the target label from `stmt_body[i]` and look it up in `label_to_stmt`.
2. If the label doesn't exist, this will fire ICL129I at runtime; we defer the error. (Compile-time detection is viable but not done yet.)
3. Record `come_from_target[target_index] = i`.
4. During codegen, after emitting statement `target_index`'s body, emit an unconditional `b _stmt_i_body` to the COME FROM's body.

The asymmetry is what makes `COME FROM` interesting from a compiler standpoint. A `GOTO` only touches its own statement; a `COME FROM` modifies the generated code of a statement somewhere else. The resolver pass is what lets codegen remain single-pass over the statement list: by the time codegen visits statement `N`, the reverse edge is already recorded.

### What about multiple COME FROMs to the same label

The INTERCAL spec says this is `ICL555I`. Our `resolve_come_from` enforces it: the second COME FROM that registers the same target label fires `ICL555I MULTIPLE COME FROM TARGETING SAME LABEL` and the compile aborts. This was a latent bug in earlier versions of the compiler (the second registration overwrote the first silently); the check is now in place and exercised by the test suite.

### COME FROM and probabilities

A COME FROM statement can itself have `%N` and can be abstained. Both are handled uniformly by the codegen: the COME FROM body checks its abstain flag and rolls its probability before jumping. That is, the original flow of statement `N` ends with:

    b _stmt_come_from_body     ; unconditional jump to the COME FROM
    _stmt_come_from_body:
    ; abstain flag check
    ; probability roll
    ; (the COME FROM body itself is empty — it just falls through)
    ; continue at _stmt_come_from+1

If the abstain flag is set, the COME FROM body jumps back to `_stmt_N+1`, i.e. to normal flow. If the probability roll fails, same thing. Only when both checks pass does control stay at the COME FROM body and continue with the statement after it.

## Other semantic checks that live in codegen, not here

Several checks that a textbook would call "semantic" happen during codegen because they depend on knowing how the expression is shaped:

- 32-bit-into-16-bit overflow (ICL275I) is emitted as a runtime check: the codegen produces code that compares the computed value against 65535 and jumps to `_rt_error_E275` if it is larger.
- Array dimension zero (ICL240I) is checked at runtime in the dimensioning code, not at compile time. The RHS of `DO ,1 <- #N` may be an expression that evaluates to zero only conditionally.
- Invalid subscript (ICL241I) is a runtime range check emitted per access.

This is not a coincidence. INTERCAL allows the full expression language wherever a value is expected, and many of these checks depend on runtime values. What looks like a compile-time guard in a C-like language has to be a runtime check here.

A handful of checks that used to live at runtime have been promoted to compile time:

- `NEXT (N)`, `ABSTAIN FROM (N)`, and `REINSTATE (N)` with an undefined label `N` used to emit a runtime branch into `_rt_error_E129` or `_rt_error_E139`. The label set is known at compile time, so the check now fires `ICL129I` or `ICL139I` at compile time and refuses to produce a binary.
- `ABSTAIN FROM gerund-list` (and the matching `REINSTATE`) used to silently ignore unknown gerund names. The check is now a compile-time rejection: `DO ABSTAIN FROM PROCRASTINATING` fails with a diagnostic naming the unknown gerund.

The pattern — fold a runtime structural check into compile time once we are sure the relevant data is available — is a small but real form of optimisation. Each check moved removes both a per-emitted-statement cost and a class of late-firing bugs.

## `scan_variables`

Not strictly a check, but run in the same pass group. `scan_variables` records which `.N`, `:N`, `,N`, `;N` numbers appear anywhere in the program. The result is four associative arrays keyed by number. Codegen uses them to emit exactly the BSS symbols it needs.

For a variable that appears in an expression but is never assigned, we still record it as "used" — reading it is well-defined (value 0), and we need the BSS slot.

## Exercises

1. Compute the politeness boundaries for a 7-statement program, a 12-statement program, and a 100-statement program. For each, what is the minimum and maximum number of `PLEASE` statements that satisfy the rule?
2. The compiler stores `label_to_stmt` as an associative array. Suppose the maximum label number were reduced from 65535 to 999. What part of the compiler would need to change? What about the runtime?
3. `resolve_come_from` overwrites silently when two COME FROMs target the same label. Write the smallest INTERCAL program that triggers this latent bug. What does the program currently do, and what should it do per the specification?
4. `scan_variables` records a variable as "used" when it is read but never written. Why is this important? What would happen if we instead only recorded written variables?
5. The politeness check is the only compile-time error the compiler reports for a syntactically well-formed program. Argue for or against adding a compile-time check for `RESUME #0` (currently a runtime error).

## Next reading

- [code-generation.md](code-generation.md) — what we do with the resolved label map and the come_from_target entries.
- [runtime.md](runtime.md) — the `_rt_error_*` targets that codegen emits for the runtime-side checks listed here.
