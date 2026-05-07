# INTERCAL primer

A minimal introduction to INTERCAL aimed at two readers: a programmer who wants to read the test programs under `tests/`, and a compiler reader who needs the language vocabulary before approaching the per-phase chapters. The aim is not to teach you to write INTERCAL programs from scratch; for that, follow the resources in [further-reading.md](further-reading.md). The complete language reference lives in `AGENTS.md`, section "INTERCAL language reference".

If you have not built the compiler, start with [getting-started.md](getting-started.md). If you want a non-technical introduction first, [what-is-intercal.md](what-is-intercal.md).

## A program, stripped down

    DO .1 <- #5
    PLEASE READ OUT .1
    DO GIVE UP

Three statements. The first assigns 5 to the scalar variable `.1`. The second writes it out in Roman numerals (so you see `V`). The third exits. Two statements start with `DO`, one with `PLEASE`, and `GIVE UP` is mandatory.

To read INTERCAL as a compiler writer, you only need to know what each token does and why it matters for the compiler.

## Statement shape

Every statement has five pieces in this order, three of them optional:

1. An optional label in parentheses: `(1000)`. Labels are 1–65535 and must be unique. Labels 1000–1999 are reserved for the system library.
2. A required verb: `DO`, `PLEASE`, or `PLEASE DO`. Functionally identical. The compiler only cares whether `PLEASE` is present, because that is how you satisfy the politeness rule.
3. An optional negation: `NOT` or `N'T`. A negated statement starts abstained and has no effect until `REINSTATE`d. `DON'T` is a tokenised form of `DO NOT`.
4. An optional probability: `%50`. The statement executes half the time.
5. The body: assignment, control-flow, I/O, etc.

The compiler stores each statement as a tuple `(label, polite, negated, probability, type, body)`, spread across the parallel arrays `stmt_label`, `stmt_polite`, `stmt_negated`, `stmt_prob`, `stmt_type`, `stmt_body` in `intercalc.sh`.

## Variables and constants

Four variable prefixes:

| Prefix | Name | Type |
|--------|------|------|
| `.`  | onespot | 16-bit unsigned |
| `:`  | twospot | 32-bit unsigned |
| `,`  | tail array | array of 16-bit values |
| `;`  | hybrid array | array of 32-bit values |

Constants have prefix `#` and are always 16-bit: `#42`, `#65535`. For 32-bit constants, build them with operators.

The four prefixes share a numbering namespace: `.1`, `,1`, and `:1` are three unrelated variables. Up to 65535 of each kind.

Variables start at zero. Assigning above 65535 to a onespot is a runtime error (ICL275I).

## Operators and grouping

No operator precedence. Every subexpression that could be ambiguous must be grouped, and the grouping alternates between two characters: sparks `'` and rabbit-ears `"`. Where a C programmer writes `(a + (b * c))`, an INTERCAL programmer writes `'a op "b op c"'`. Same-kind nesting is not allowed.

Two binary operators:

- `$` (big money), mingle. Interleaves the bits of two 16-bit values into a 32-bit result. Left operand to odd bit positions, right operand to even.
- `~` (sqiggle), select. Given a value and a mask, extract the bits of the value where the mask has a 1, and pack them right-justified.

Three unary operators, placed between the prefix and the number (`&.1`, `V:2`, `?,1 SUB #3`):

- `&`: AND each bit with its right neighbour (wrapping).
- `V` (uppercase V, not ∨): OR each bit with its right neighbour.
- `?`: XOR each bit with its right neighbour.

The unary operators work on the bits of one value, not between two values. A common trick used throughout the compiler: to AND two 16-bit values A and B, mingle them into one 32-bit value `A$B`, apply unary `&`, then select the even-position bits out. The pattern appears many times in `syslib.i`.

## Assignment

    DO .1 <- #5

The `<-` is angle-worm. Left side is a variable or array element. Right side is an expression. The compiler evaluates the RHS, optionally checks for 32-into-16-bit overflow, and stores into the target.

For array elements: `,1 SUB #3 <- #42`. `SUB` is the subscript operator, space-separated.

## Control flow

No `if`, no `while`, no `for`, no `goto`. The transfer-of-control primitives are:

- `DO (N) NEXT`: push the current position onto the NEXT stack (max depth 79, ICL123I if you exceed) and jump to label `N`.
- `DO RESUME #K`: pop K entries from the NEXT stack and jump to the last one popped. `RESUME #1` is a clean subroutine return. `RESUME #0` is a runtime error.
- `DO FORGET #K`: pop K entries without transferring.
- `DO COME FROM (N)`: after the statement at label `N` executes, control transfers here. Resolved at compile time.
- `DO GIVE UP`: exit.

The absence of `if` is not a problem in practice. Convert a truthy value into "1 or 2", push two NEXT targets for the two branches, and `RESUME` with the 1-or-2 variable. See the idioms section in `AGENTS.md` ("Essential idioms").

## Abstain / reinstate / ignore / remember

Four modifiers control what is live at runtime:

- `DO ABSTAIN FROM (N)`: skip statement `N` from now on.
- `DO ABSTAIN FROM gerund-list`: same, but by category. `CALCULATING` covers all assignments, `NEXTING` all NEXTs, etc.
- `DO REINSTATE ...`: reverse an ABSTAIN.
- `DO IGNORE var-list`: make variables read-only. Writes are silently discarded.
- `DO REMEMBER var-list`: reverse an IGNORE.

The compiler tracks abstention as a bit per statement in BSS, in a region called `_stmt_flags`. Each statement starts with a flag check that jumps over its body if abstained.

## STASH and RETRIEVE

    DO STASH .1 .2
    ...
    DO RETRIEVE .1 .2

Per-variable stacks. Used whenever you call a syslib routine that might clobber `.1`–`.4` or `:1`–`:4`. Calling RETRIEVE without a prior STASH fires ICL436I.

## I/O

Numeric:

- `DO READ OUT .1`: print the value of `.1` in Roman numerals.
- `DO WRITE IN .1`: read a number whose digits are spelled in English (`ONE TWO THREE` is 123).

Character (Turing Text Model):

- `DO READ OUT ,1`: walk the tape forwards and backwards, printing characters.
- `DO WRITE IN ,1`: the inverse, reading characters and converting to tape-offset deltas.

The Turing Text Model (TTM) encoding is what makes `tests/test_hello.i` look the way it does. You cannot just put `H e l l o` in the source. Each character has to be precomputed as a tape-offset delta whose effect, after the tape head's bit-reversed position, lands at the ASCII code you want. The compiler does not care; it just emits calls to `_rt_read_out_array`. The encoding matters when you read the test programs. See [runtime.md](runtime.md) for the algorithm in full.

## Politeness

Between one-fifth and one-third of all statements must use `PLEASE` or `PLEASE DO`. The compiler counts during semantic analysis and rejects programs outside the range:

- Fewer than 1/5 → ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE.
- More than 1/3 → ICL099I PROGRAMMER IS OVERLY POLITE.

A whole-program property; you cannot decide politeness per statement. See [semantic-analysis.md](semantic-analysis.md) for the implementation.

## What else exists that the compiler treats uniformly

A few features the spec treats as important but which our compiler handles uniformly enough not to need their own chapter:

- Statement probabilities (`%50`): the compiler emits a random-roll check and skips the body if the roll fails.
- Gerunds (`CALCULATING`, `NEXTING`, etc.): `ABSTAIN FROM CALCULATING` is just "flip the abstain bit on every statement of type assignment", a loop in codegen.
- Comments: there are none in standard INTERCAL. `DON'T NOTE ...` is the idiomatic fake-comment, a negated `UNKNOWN` statement that is skipped at runtime and never executed. The compiler classifies it as `UNKNOWN_NEGATED` and emits nothing.

That is enough to read the test programs and the source. Next: [pipeline.md](pipeline.md).

## Exercises

1. The hello-world program in `tests/test_hello.i` has 17 statements and 4 `PLEASE`s. Compute its politeness ratio. By how much could you shrink the program before falling below the 1/5 threshold, assuming you do not touch the `PLEASE`s?
2. Write the smallest INTERCAL program that uses `STASH` and `RETRIEVE` correctly. What goes wrong if you swap their order?
3. The unary operators `&`, `V`, `?` operate on adjacent bits of one value. Compute, on paper, the result of `&#5` (unary AND applied to the constant 5, treated as 16-bit).
4. INTERCAL has no `if`. Look up the conversion idiom in `AGENTS.md` (section "Essential idioms") and explain in one paragraph how it lets you express a two-way branch.
5. `DON'T NOTE foo bar` is the idiomatic comment. What other constructions could be used to comment out a line, and why are they worse?
