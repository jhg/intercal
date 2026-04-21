# INTERCAL primer for compiler readers

This is a minimal introduction to INTERCAL. Its purpose is not to teach you to write INTERCAL programs but to let you read the source files in `tests/` and follow the compiler chapters that come after this one. For the complete language reference see `AGENTS.md`, section "INTERCAL language reference".

## A program, stripped down

    DO .1 <- #5
    PLEASE READ OUT .1
    DO GIVE UP

That program assigns 5 to the scalar variable `.1`, writes it out in Roman numerals (so you see `V`), and exits. Three statements, two of them starting with `DO`, one with `PLEASE`, and a mandatory `GIVE UP` at the end.

All you need to know to read INTERCAL as a compiler writer is what each of those tokens does and why they matter for the compiler.

## Statement shape

Every statement has five optional-or-required pieces in this order:

1. An optional label in parentheses: `(1000)`. Labels are 1–65535 and must be unique. The range 1000–1999 is reserved for the system library.
2. A required verb: `DO`, `PLEASE`, or `PLEASE DO`. Functionally they are equivalent. The only thing that matters to the compiler is whether `PLEASE` is present, because `PLEASE` is how you satisfy the politeness rule.
3. An optional negation: `NOT` or `N'T`. A negated statement starts as abstained (inactive) and has no effect until `REINSTATE`d. `DON'T` is a tokenised form of `DO NOT`.
4. An optional probability: `%50`. The statement executes half the time.
5. The statement body: an assignment, a control-flow action, an I/O action, etc.

The compiler stores each statement as a tuple `(label, polite, negated, probability, type, body)`. This lives across the parallel arrays `stmt_label`, `stmt_polite`, `stmt_negated`, `stmt_prob`, `stmt_type`, `stmt_body` in `intercalc.sh`.

## Variables and constants

There are four variable prefixes:

| Prefix | Name | Type |
|--------|------|------|
| `.`  | onespot | 16-bit unsigned |
| `:`  | twospot | 32-bit unsigned |
| `,`  | tail array | array of 16-bit values |
| `;`  | hybrid array | array of 32-bit values |

Constants have the prefix `#` and are always 16-bit: `#42`, `#65535`. To get a 32-bit constant you have to construct it with operators.

All four prefixes share the same numbering: `.1` and `,1` and `:1` are three unrelated variables. There are up to 65535 of each kind.

Each variable starts at zero. Assigning a value larger than 65535 to a onespot variable is a runtime error (ICL275I).

## Operators and grouping

There is no operator precedence. Every subexpression that could be ambiguous must be grouped, and the grouping alternates between two kinds of brackets: sparks `'` and rabbit-ears `"`. Where a C programmer would write `(a + (b * c))`, an INTERCAL programmer writes `'a op "b op c"'` — same-kind nesting is not allowed.

Two binary operators:

- `$` (big money) — mingle. Takes two 16-bit values and interleaves their bits into a 32-bit result. Left operand to odd bit positions, right operand to even positions.
- `~` (sqiggle) — select. Given a value and a mask, extract the bits of the value where the mask has a 1 and pack them into a right-justified result.

Three unary operators, placed between the prefix and the number (`&.1`, `V:2`, `?,1 SUB #3`):

- `&` — AND each bit with its right neighbour (wrapping).
- `V` (uppercase V, not ∨) — OR each bit with its right neighbour (wrapping).
- `?` — XOR each bit with its right neighbour (wrapping).

The unary operators work on the bits of *one* value, not between two values. A common trick used throughout the compiler is: to AND two 16-bit values A and B, first mingle them into a single 32-bit value `A$B`, then apply unary `&`, then select the even-position bits out. That pattern appears many times in `syslib.i`.

## Assignment

    DO .1 <- #5

The `<-` is called angle-worm. Left-hand side is always a variable or an array element; right-hand side is an expression. The compiler generates code that evaluates the RHS, possibly checks for the 32-bit-into-16-bit overflow, and stores into the target.

For array elements the syntax is `,1 SUB #3 <- #42` — `SUB` is the subscript operator, space-separated from the expressions.

## Control flow

There is no `if`, `while`, `for`, or `goto`. The only transfer-of-control primitives are:

- `DO (N) NEXT` — push the current position onto the NEXT stack (max depth 79, else ICL123I) and jump to label `N`.
- `DO RESUME #K` — pop K entries from the NEXT stack and jump to the last one popped. `RESUME #1` is a clean subroutine return. `RESUME #0` is a runtime error.
- `DO FORGET #K` — pop K entries without transferring.
- `DO COME FROM (N)` — after the statement at label `N` executes, control transfers here. This is resolved statically at compile time, not at runtime.
- `DO GIVE UP` — exit.

The absence of `if` is not a problem in practice. You convert a truthy value into "1 or 2", push two NEXT targets for the two branches, and `RESUME` with the 1-or-2 value. See the idioms chapter in `AGENTS.md` ("Essential idioms").

## Abstain / reinstate / ignore / remember

Four statement modifiers control what is live at runtime:

- `DO ABSTAIN FROM (N)` — make statement `N` skipped from now on.
- `DO ABSTAIN FROM gerund-list` — same, but by category: `CALCULATING` abstains all assignments, `NEXTING` all NEXTs, etc.
- `DO REINSTATE ...` — reverse an ABSTAIN.
- `DO IGNORE var-list` — make variables read-only (writes silently discarded).
- `DO REMEMBER var-list` — reverse an IGNORE.

The compiler tracks abstention state as a bit-per-statement in a BSS region called `_stmt_flags`. Each statement starts by checking its flag and jumping over itself if abstained.

## STASH and RETRIEVE

    DO STASH .1 .2
    ...
    DO RETRIEVE .1 .2

Pushes and pops per-variable stacks. Used whenever you call a syslib routine that clobbers `.1–.4` or `:1–:4`. If you RETRIEVE without a prior STASH you get ICL436I.

## I/O

Numeric:

- `DO READ OUT .1` — print the value of `.1` in Roman numerals.
- `DO WRITE IN .1` — read a number whose digits are spelled in English (`ONE TWO THREE` = 123).

Character (Turing Text Model):

- `DO READ OUT ,1` — walk the tape forwards/backwards, printing characters.
- `DO WRITE IN ,1` — the inverse, reading characters and converting to tape-offset deltas.

The TTM encoding is what makes the `tests/test_hello.i` program look like it does. You can't just put `H e l l o` in the source; you have to precompute each character as a tape-offset delta that, after the tape head's bit-reversed position, leaves you at the ASCII code you want. The compiler doesn't care about any of this — it just emits calls to `_rt_read_out_array` — but it is worth knowing when you read the test programs.

## Politeness

Between one-fifth and one-third of all statements in a program must use `PLEASE` or `PLEASE DO`. The compiler counts them during the semantics phase and rejects programs that fall outside the range:

- Fewer than 1/5 → ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE.
- More than 1/3 → ICL099I PROGRAMMER IS OVERLY POLITE.

This is a static whole-program property. You can't decide politeness per statement. See [semantic-analysis.md](semantic-analysis.md) for how we compute it.

## What else exists that the compiler doesn't care about much

INTERCAL has a number of features that the language specification treats as important but that our compiler handles uniformly enough to not warrant their own chapter:

- Statement probabilities (`%50`) — the compiler emits a call to the random routine and skips the statement if the roll fails.
- Gerunds (`CALCULATING`, `NEXTING`, etc.) — `ABSTAIN FROM CALCULATING` maps to "flip the abstain bit on every statement of type assignment". Just a loop in the codegen.
- Comments — there are none in standard INTERCAL. `DON'T NOTE ...` is the idiomatic fake-comment: it's a negated statement that would parse as unknown, so it is skipped at runtime and never executes. The compiler sees it, classifies it as `UNKNOWN_NEGATED`, and emits nothing for it.

That is enough to read the test programs and the source. Go to [pipeline.md](pipeline.md) next.
