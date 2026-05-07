# The politeness rule

INTERCAL's politeness rule is a unique compile-time check: every program must use `PLEASE` on between 1/5 and 1/3 of its statements. Too few and the compiler rejects the program as insufficiently polite. Too many and it rejects the program as overly polite. There is no other language whose compiler refuses to translate a program because its statements show the wrong amount of deference.

This chapter is the politeness rule's tour: what the specification says, how our compiler implements it, where the boundaries are, and why the check exists at all.

## The specification

From the 1972 reference manual, the rule is a property of the whole program:

- Fewer than one in five statements use `PLEASE` → `ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE`.
- More than one in three statements use `PLEASE` → `ICL099I PROGRAMMER IS OVERLY POLITE`.

The bounds are inclusive at the lower end, exclusive at the upper end. A program where exactly one in five statements is polite passes; a program where exactly one in three is polite passes; a program where more than one in three is polite fails.

The specification does not explicitly carve out a tiny-program exception, but every implementation we know of (C-INTERCAL, CLC-INTERCAL, ours) bypasses the check for programs of fewer than five statements. The pragmatic reason is that the bounds are mathematically infeasible at small sizes. With three statements, you would need 0.6 to 1 polite statements, which means exactly 1, which is also above the upper bound (1/3 = 33.3%, but 1/3 = 33.3% so 1 is exactly at the boundary). The corner cases for tiny N are unintuitive enough that all implementations punt.

## Our implementation

`check_politeness` lives in `src/bootstrap/intercalc.sh`:

    check_politeness() {
      if (( stmt_count < 5 )); then return; fi
      local polite=0
      local i
      for (( i=1; i<=stmt_count; i++ )); do
        if (( stmt_polite[$i] )); then
          (( polite++ )) || true
        fi
      done
      if (( polite * 5 < stmt_count )); then
        die_compile "079" "PROGRAMMER IS INSUFFICIENTLY POLITE"
      fi
      if (( polite * 3 > stmt_count )); then
        die_compile "099" "PROGRAMMER IS OVERLY POLITE"
      fi
    }

Three things to notice:

- **Tiny-program shortcut**: programs with fewer than five statements skip the check entirely. This is why `tests/test_give_up.i` (one statement, zero `PLEASE`) compiles cleanly even though 0/1 = 0% is well below the 20% lower bound.
- **Cross-multiplied comparison**: rather than compute the ratio as a float, we use `polite*5 < total` and `polite*3 > total`. This is integer arithmetic, exact at every boundary, and avoids any floating-point rounding. The cross-multiplication is the standard technique for testing rational inequalities without leaving the integers.
- **Strict at the upper end**: `polite*3 > total` fires only when the ratio strictly exceeds 1/3. A program with exactly 1/3 polite statements passes. The lower bound is similarly strict (`< stmt_count`); 1/5 polite statements exactly passes.

## Boundary table

The pass/fail boundaries for representative program sizes:

| Total statements | Min PLEASE for pass | Max PLEASE for pass |
|------------------|---------------------|---------------------|
| 5  | 1 | 1 |
| 6  | 2 | 2 |
| 7  | 2 | 2 |
| 8  | 2 | 2 |
| 9  | 2 | 3 |
| 10 | 2 | 3 |
| 11 | 3 | 3 |
| 12 | 3 | 4 |
| 13 | 3 | 4 |
| 14 | 3 | 4 |
| 15 | 3 | 5 |
| 17 | 4 | 5 |
| 20 | 4 | 6 |
| 25 | 5 | 8 |
| 30 | 6 | 10 |
| 100 | 20 | 33 |

Reading the table: at 17 statements (the size of `tests/test_hello.i`), you need between 4 and 5 inclusive `PLEASE`s. The actual program has 4. One more `PLEASE` would still pass (5 = 5/17 ≈ 29.4% ≤ 33.3%); two more would fail with `ICL099I` (6/17 ≈ 35.3% > 33.3%).

For programs at multiples of 15, the bounds widen smoothly, at 30 statements you have between 6 and 10 `PLEASE`s, a range of 4. At 1500, the range would be 200.

## Boundary cases at exactly 1/5 and 1/3

A program with exactly five statements and one `PLEASE`: `polite*5 = 5 = stmt_count`, so `polite*5 < stmt_count` is false. The lower bound just barely passes. `polite*3 = 3 < 5 = stmt_count`, so the upper bound passes. The program is accepted.

A program with exactly three `PLEASE`s out of nine: `polite*3 = 9 = stmt_count`, so `polite*3 > stmt_count` is false. The upper bound just barely passes. `polite*5 = 15 > 9`, so the lower bound passes. Accepted.

Off-by-one sensitivity is real here. Adding one statement (any kind, polite or not) to a program at the upper boundary can push it from passing to failing or vice versa. Removing a `PLEASE` from a program at the lower boundary can do the same. The two test programs `tests/test_errors_rude.i` and `tests/test_errors_polite.i` exist specifically to confirm that the boundary detection still works correctly after every code change.

## Why the rule exists

INTERCAL was written as a parody. The politeness rule is its single best joke: a feature that takes a real concept (politeness in programming) and turns it into a hard compile-time constraint. The deeper joke is that the rule is internally consistent, the compiler has a precise definition of "polite enough" and "too polite", and it enforces that definition rigorously. The 1972 manual states the rule as a serious specification; the parody is in the reader's reaction, not in the rule itself.

A second-order benefit of the rule, which the manual does not advertise, is that it forces the programmer to space out `PLEASE`s through the program. A reader of an INTERCAL program sees `PLEASE` distributed roughly every fourth statement, and that visual rhythm is part of why INTERCAL programs feel different to read.

## Implications for code generation

The politeness rule is the only compile-time error our compiler reports for a syntactically well-formed program. Every other failure (undecodable statement, NEXT-stack overflow, RESUME of zero, end without `GIVE UP`) is a runtime condition.

The reason the others are runtime is that INTERCAL allows abstention: an unrecognised statement may be marked `DON'T` and never execute, so the compiler cannot reject the program just because the source contains a problem. The politeness rule is different: it is a property of the *whole program text*, regardless of which statements run. Static enforcement is the only place it can live.

## How the rule has evolved across implementations

C-INTERCAL adopted the rule unchanged from the 1972 spec. CLC-INTERCAL added some softening: it can be configured to warn instead of error. Our compiler adopts the strict 1972 behaviour, with the 5-statement floor described above. That makes us slightly less permissive than CLC-INTERCAL but identical to C-INTERCAL on programs with five or more statements.

## Common mistakes when writing INTERCAL

The two errors that fire most often during interactive editing:

- **Adding a `PLEASE` to clarify a comment-like statement, then forgetting to balance it.** A program that hovers near the upper bound can be flipped above 1/3 by a single `PLEASE` insertion.
- **Removing a statement (because it became redundant) without checking that the politeness ratio still holds.** Both removing a polite statement (which decreases the numerator faster than the denominator) and removing a non-polite statement (which can push the ratio over 1/3) are common.

The lint tool `tools/lint_intercal.sh` reports the politeness ratio as a hint, before the compiler errors out. Use it on long INTERCAL files where the ratio is non-obvious.

## Exercises

1. Write the smallest INTERCAL program (in number of statements) that is rejected with `ICL079I`. Now write the smallest one rejected with `ICL099I`.
2. The 5-statement floor means a 4-statement program with no `PLEASE` is accepted. Construct an example. Is its behaviour at runtime well-defined?
3. Compute the maximum polite count at 100 statements. Then compute the same at 1000 statements. The ratio of the two ranges (100-statement vs 1000-statement) shrinks as N grows. Explain why.
4. The check uses cross-multiplied comparison instead of floating-point ratios. Construct an integer overflow case where the cross-multiplied form would silently give the wrong answer. Is there a realistic INTERCAL program that hits it?
5. Suppose we wanted to relax the rule for programs over 1000 statements (where the ratio constraint is genuinely too tight). Sketch a modified `check_politeness` that loosens the bounds for large programs.

## Next reading

- [semantic-analysis.md](semantic-analysis.md): the broader context of compile-time checks.
- [intercal-primer.md](intercal-primer.md): the language tour, including a shorter politeness summary.
- [design-rationale.md](design-rationale.md): why we chose to enforce the rule rather than warn.
