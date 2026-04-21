# Statement cheatsheet

A one-stop reference for every INTERCAL statement this compiler recognises, with syntax, a minimal example, the codegen function that handles it, and the runtime errors each can trigger. Aimed at somebody who knows INTERCAL and wants to look up a specific statement quickly.

For the pedagogical introduction see [intercal-primer.md](intercal-primer.md). For the formal grammar see [appendix-grammar.md](appendix-grammar.md).

## Conventions used below

- `<expr>`: an arithmetic expression producing a 16- or 32-bit value.
- `<var>`: a variable reference (`.N`, `:N`, `,N`, `;N`).
- `<label>`: a number in parentheses, `(N)` where 1 ≤ N ≤ 65535.
- `<n>`, `<k>`: decimal number literals.
- `<gerund>`: one of `CALCULATING`, `NEXTING`, `FORGETTING`, `RESUMING`, `STASHING`, `RETRIEVING`, `IGNORING`, `REMEMBERING`, `ABSTAINING`, `REINSTATING`, `COMING FROM`, `READING OUT`, `WRITING IN`.

Every statement can optionally be prefixed with a label and the verb can be `DO` / `PLEASE` / `PLEASE DO`; any of these can optionally be negated with `NOT` / `N'T` / `DON'T`; and any can take a `%N` probability. The table below shows the bare form.

## Assignments

| Statement | Example | Codegen function | Errors |
|-----------|---------|-----------------|--------|
| `<var> <- <expr>` | `DO .1 <- #5` | `codegen_assign` | ICL275I (32→16 overflow), ICL533I (arithmetic overflow) |
| `<array> <- <expr>` | `DO ,1 <- #10` | `codegen_array_dim` | ICL240I (zero dimension), ICL533I |
| `<array> <- <expr> BY <expr>` | `DO ,1 <- #3 BY #4` | `codegen_array_dim` | ICL240I, ICL533I |
| `<array> SUB <expr> ... <- <expr>` | `DO ,1 SUB #2 <- #42` | `codegen_array_elem_assign` | ICL241I (bad subscript), ICL275I, ICL533I |

## Control flow

| Statement | Example | Codegen function | Errors |
|-----------|---------|-----------------|--------|
| `<label> NEXT` | `DO (100) NEXT` | `codegen_next` | ICL123I (stack overflow), ICL129I (unknown label) |
| `RESUME <expr>` | `DO RESUME #1` | `codegen_resume` | ICL621I (RESUME 0), ICL632I (stack underflow) |
| `FORGET <expr>` | `DO FORGET #1` | `codegen_forget` | none |
| `COME FROM <label>` | `DO COME FROM (100)` | implicit in target statement | ICL555I (duplicate, not yet enforced) |
| `GIVE UP` | `DO GIVE UP` | `codegen_give_up` | none |

## Modifiers

| Statement | Example | Codegen function | Errors |
|-----------|---------|-----------------|--------|
| `ABSTAIN FROM <label>` | `DO ABSTAIN FROM (100)` | `codegen_abstain` | ICL139I (unknown label) |
| `ABSTAIN FROM <gerund>[+<gerund>]*` | `DO ABSTAIN FROM CALCULATING` | `codegen_gerund_modify` | none |
| `REINSTATE <label>` | `DO REINSTATE (100)` | `codegen_reinstate` | ICL139I |
| `REINSTATE <gerund>[+<gerund>]*` | `DO REINSTATE NEXTING + RESUMING` | `codegen_gerund_modify` | none |
| `IGNORE <var>[ <var>]*` | `DO IGNORE .1 :2` | `codegen_ignore` | none |
| `REMEMBER <var>[ <var>]*` | `DO REMEMBER .1 :2` | `codegen_remember` | none |

## Stash / retrieve

| Statement | Example | Codegen function | Errors |
|-----------|---------|-----------------|--------|
| `STASH <var>[ <var>]*` | `DO STASH .1 .2` | `codegen_stash` | ICL999I (stash overflow, not yet enforced) |
| `RETRIEVE <var>[ <var>]*` | `DO RETRIEVE .1 .2` | `codegen_retrieve` | ICL436I (retrieve without stash) |

## I/O

| Statement | Example | Codegen function | Errors |
|-----------|---------|-----------------|--------|
| `READ OUT <var>[ <var>]*` | `DO READ OUT .1` | `codegen_read_out` | none (scalar) |
| `READ OUT <array>` | `DO READ OUT ,1` | `codegen_read_out` | none (array) |
| `WRITE IN <var>[ <var>]*` | `DO WRITE IN .1` | `codegen_write_in` | ICL562I (end of input), ICL579I (bad format) |
| `WRITE IN <array>` | `DO WRITE IN ,1` | `codegen_write_in` | ICL562I |

## Whole-program

| Statement type | Example | Codegen function | Errors |
|---------------|---------|-----------------|--------|
| Any unknown form | `DO WOT A HULLABALOO` | dispatcher fallthrough | ICL000I (executed unknown statement) |
| Fallthrough past last statement | (missing `GIVE UP`) | implicit epilogue | ICL633I (fell off the end) |
| Politeness out of range | (whole program) | `check_politeness` at compile time | ICL079I (rude), ICL099I (polite) |
| Duplicate label | (whole program) | `check_labels` at compile time | ICL182I |

## Expression operators

| Operator | Syntax | Meaning | Runtime routine |
|----------|--------|---------|-----------------|
| Binary mingle | `'<a> $ <b>'` | Interleave bits of two 16-bit values → 32-bit | `_rt_mingle` |
| Binary select | `'<a> ~ <b>'` | Select bits from `<a>` where `<b>` has 1s, pack right | `_rt_select` |
| Unary AND | `&<var>` | AND each bit with its right neighbour (wrapping) | `_rt_unary_and_16` or `_rt_unary_and_32` |
| Unary OR | `V<var>` | OR each bit with its right neighbour | `_rt_unary_or_16` or `_rt_unary_or_32` |
| Unary XOR | `?<var>` | XOR each bit with its right neighbour | `_rt_unary_xor_16` or `_rt_unary_xor_32` |

Grouping: `'...'` (sparks) and `"..."` (rabbit-ears). Must alternate. No operator precedence; every subexpression that could be ambiguous must be grouped.

## System library labels (call via NEXT)

16-bit:

| Label | Operation | Inputs | Outputs |
|-------|-----------|--------|---------|
| 1000 | add | `.1`, `.2` | `.3`, fires ICL533I on overflow |
| 1009 | add, with flag | `.1`, `.2` | `.3`, `.4` = 1 if ok / 2 if overflow |
| 1010 | subtract (wraps) | `.1`, `.2` | `.3` |
| 1020 | increment in place | `.1` | `.1` |
| 1030 | multiply | `.1`, `.2` | `.3`, fires ICL533I |
| 1039 | multiply, with flag | `.1`, `.2` | `.3`, `.4` |
| 1040 | divide | `.1`, `.2` | `.3` (0 if divisor 0) |
| 1050 | 32/16 divide | `:1`, `.1` | `.2`, fires ICL533I if quotient > 65535 |

32-bit:

| Label | Operation | Inputs | Outputs |
|-------|-----------|--------|---------|
| 1500 | add | `:1`, `:2` | `:3`, fires ICL533I |
| 1509 | add, with flag | `:1`, `:2` | `:3`, `:4` |
| 1510 | subtract (wraps) | `:1`, `:2` | `:3` |
| 1520 | mingle explicit | `.1`, `.2` | `:1` |
| 1530 | 16×16 → 32 multiply | `.1`, `.2` | `:1` |
| 1540 | 32×32 multiply | `:1`, `:2` | `:3`, fires ICL533I |
| 1549 | 32×32, with flag | `:1`, `:2` | `:3`, `:4` |
| 1550 | 32-bit divide | `:1`, `:2` | `:3` (0 if divisor 0) |

Random:

| Label | Operation | Inputs | Outputs |
|-------|-----------|--------|---------|
| 1900 | uniform random | — | `.1` in [0, 65535] |
| 1910 | bounded random | `.1` | `.2` in [0, `.1`] |

Internal (do not call): 1525 (shift helper), 1999 (overflow exit).

Caller responsibility: STASH every variable in `.1`–`.4` / `:1`–`:4` that the routine will clobber, then RETRIEVE after the return. Failure to STASH leads to silent value loss; failure to RETRIEVE (or RETRIEVE without prior STASH) fires ICL436I.

## Label 666 syscalls

Invoke with `.1` set to the syscall number, then `DO (666) NEXT`. See [label-666-intro.md](label-666-intro.md) for a walkthrough.

| `.1` | Syscall | Inputs | Outputs |
|------|---------|--------|---------|
| 1 | open | `.2` mode (0=read, 1=write), filename in `,65535` | `.3` fd |
| 2 | read | `.2` fd, `.3` max bytes | `.4` bytes read, data in `,65535` |
| 3 | write | `.2` fd, `.3` count, data in `,65535` | `.4` bytes written |
| 4 | close | `.2` fd | — |
| 5 | argc | — | `.3` count |
| 6 | argv | `.2` index (0-based) | `.3` length, arg in `,65535` |
| 8 | exit | `.2` status code | no return |
| 9 | getrand | `.2` 0 = uniform / >0 = range [0, `.2`] | `.3` random |

Program must dimension `,65535 <- #65535` at entry and not use `,65535` for any other purpose.

## Comment

There is no comment syntax in INTERCAL. The idiom for a no-op pseudo-comment is:

    DON'T NOTE whatever you want to say here

This parses as a negated unknown statement, skipped at runtime, ignored by the codegen.

## Statement order inside a body

Every statement body's tokens appear in the order specified above (verb, negation, probability, body), but operator expressions inside the body may be freely nested:

    PLEASE DO %75 .1 <- '.2 $ "#5 ~ #3"' ~ #65535

This is a probabilistic assignment with a nested expression. The parser handles each piece in sequence.

## Next reading

- [intercal-primer.md](intercal-primer.md) — the narrative introduction for each group of statements.
- [code-generation.md](code-generation.md) — how each `codegen_*` function produces assembly.
- [runtime.md](runtime.md) — the `_rt_*` routines the codegen calls.
- [appendix-grammar.md](appendix-grammar.md) — the formal grammar.
