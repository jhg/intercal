# Numeric I/O: Roman numerals and English digit names

INTERCAL's numeric I/O is, like everything else in the language, a parody of common practice. Numbers are output in Roman numerals; numbers are read in spelled-out English digit names (`ONE TWO THREE` for 123). Neither convention is what a programmer expects, and neither is incidental, they are first-class language features documented in the original 1972 manual.

Both directions in detail: the algorithms, the overbar (vinculum) notation for values above the classical Roman range, and the corner cases that have given the runtime trouble.

## Roman numeral output

Calling `READ OUT .N` (or `READ OUT :N`) on a scalar variable outputs its value in Roman numeral notation. The implementation lives in `_rt_write_roman` in each runtime file.

The classical Roman numeral system covers values from 1 to 3999 using the seven standard symbols:

| Symbol | Value |
|--------|-------|
| I | 1 |
| V | 5 |
| X | 10 |
| L | 50 |
| C | 100 |
| D | 500 |
| M | 1000 |

The classical *subtractive* notation reserves six special pairs:

| Pair | Value | Example |
|------|-------|---------|
| IV | 4 | (instead of IIII) |
| IX | 9 | (instead of VIIII) |
| XL | 40 | (instead of XXXX) |
| XC | 90 | (instead of LXXXX) |
| CD | 400 | (instead of CCCC) |
| CM | 900 | (instead of DCCCC) |

So 42 is `XLII`, 99 is `XCIX`, 1994 is `MCMXCIV`. The algorithm is greedy: walk a table of (value, symbol) pairs from largest to smallest, subtract while you can, emit the corresponding symbols, and continue.

### Overbar notation for larger values

Values in the range 4000 to 4,000,000 are written using the *vinculum* (overbar) convention: a horizontal bar over a numeral multiplies its value by 1000. So `V̄` (V with overbar) means 5000, `X̄ X̄` means 20000, and so on.

In ASCII output, we approximate the overbar with a leading underscore. `_V` is read as "V with overbar" = 5000. Our runtime writes:

| Decimal | Output |
|---------|--------|
| 4000 | `_IV` |
| 5000 | `_V` |
| 6000 | `_VI` |
| 10000 | `_X` |
| 1000000 | `_M` |
| 1234 | `MCCXXXIV` |
| 5678 | `_VDCLXXVIII` |

Programs that need to verify overbar handling can use `tests/test_overbar.i`.

### The zero corner case

Roman numerals have no symbol for zero. The convention adopted by every modern INTERCAL implementation, including ours, is to emit nothing, a literal empty output, when `READ OUT` is called on a variable holding zero. This is silent rather than an error, on the grounds that the spec is silent on the question and an error message would be more annoying than useful.

Programs that need to distinguish "zero output" from "no output" can pad their output with another non-zero `READ OUT` call before or after.

### The algorithm

In pseudo-code, `_rt_write_roman` is:

```
romans = [
  (1000000, "_M"), (900000, "_CM"), (500000, "_D"), (400000, "_CD"),
  (100000, "_C"),  (90000, "_XC"),  (50000, "_L"),  (40000, "_XL"),
  (10000, "_X"),   (9000, "_IX"),   (5000, "_V"),   (4000, "_IV"),
  (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
  (100, "C"),  (90, "XC"),  (50, "L"),  (40, "XL"),
  (10, "X"),   (9, "IX"),   (5, "V"),   (4, "IV"),
  (1, "I")
]

function write_roman(n):
  if n == 0: return  # silent
  buffer = []
  for (value, symbol) in romans:
    while n >= value:
      append symbol to buffer
      n -= value
  write(stdout, buffer)
  write(stdout, "\n")
```

The actual ARM64 implementation walks a table in `.data` and emits one syscall per output. There is no buffering, character at a time, which is slow but simple.

## English digit-name input

Calling `WRITE IN .N` reads a number from stdin where each digit is spelled out as an English word. `ONE TWO THREE` is 123; `FOUR ZERO ZERO` is 400; `NINER FIVE` is 95.

The supported tokens, with their digit values:

| Token | Value |
|-------|-------|
| `ZERO` or `OH` | 0 |
| `ONE` | 1 |
| `TWO` | 2 |
| `THREE` | 3 |
| `FOUR` | 4 |
| `FIVE` | 5 |
| `SIX` | 6 |
| `SEVEN` | 7 |
| `EIGHT` | 8 |
| `NINER` | 9 |

Note: `NINE` is *not* recognised. The 1972 manual specifies `NINER`, the radio-procedural rendering of nine. This is the most common gotcha for new INTERCAL programmers, typing `NINE` produces `ICL579I BAD INPUT`. The convention is preserved in our implementation for spec compatibility.

### Token parsing

The runtime reads input one token at a time, separated by whitespace. Each token is uppercased on read and compared against the table above. Unrecognised tokens fire `ICL579I`. End of input before any token is read fires `ICL562I`.

The runtime accumulates digits into the result variable: each new digit shifts the running value left by one decimal place (multiplies by 10) and adds the digit. The result is stored in the destination variable on the next `WRITE IN` boundary.

For 32-bit destinations (`:N`), the same algorithm runs against a 32-bit accumulator.

### Multi-variable WRITE IN

`WRITE IN .1 .2 .3` reads three space-separated numbers (themselves space-separated word lists). The runtime distinguishes one number from the next by the first whitespace after a non-digit-name token, but in practice users provide explicit separators. Our test suite uses the spec-conformant format.

## Why these specific conventions?

Both Roman numerals and English digit names are deliberate complications. The spec writers chose them because they are universally recognised but inconvenient, a programmer reading Roman output knows what number is meant but cannot read it as fluently as decimal, and a programmer typing English digit names has to think about each digit individually.

This contrasts with typical input/output, where the goal is to be transparent. INTERCAL's I/O is opaque on purpose. The output of `READ OUT .42` (printed as `XLII`) is correct but slightly slow to parse mentally. The input of `WRITE IN .42` (typed as `FOUR TWO`) is correct but slightly slow to type.

The combination forces the programmer to engage with the language at every I/O boundary, which is exactly the behaviour the manual was satirising.

## Implementation notes

`_rt_write_roman` is around 60 lines of platform-specific assembly. The table of (value, symbol) pairs is in `.data`. The routine itself is a tight loop that walks the table.

`_rt_write_in_scalar` is more elaborate, around 150 lines, because it has to lex tokens, compare against the digit-name table, and assemble a numeric value. The lexer is a small state machine that uppercases input on the fly. The digit-name table is in `.data`, with each entry being the token bytes followed by the digit value.

A future optimisation worth noting: `_rt_write_in_scalar` could share its uppercasing logic with the compiler's own `read_source` (which folds source case the same way). They do not today, because the compiler runs in zsh and the scalar reader runs in compiled assembly. After self-hosting (when `stage3.i` becomes the compiler), both could share an INTERCAL-level implementation.

## Implementation gotchas observed in CI

Two specific bugs that have hit the runtime:

- An older version of `_rt_write_roman` would emit a leading newline before the numeral characters, because the buffer-push order was inverted. Caught by `tests/test_overbar.i` which expects exact byte output.
- An older version of `_rt_write_in_scalar` accepted `NINE` as well as `NINER`, which silently passed CI on macOS but failed on Linux because the digit-name table had a different layout. The fix was to remove `NINE` from both platforms; the spec mandates `NINER`.

Both bugs were fixed before any release. They are mentioned here as evidence that even features as simple as numeric I/O have implementation traps.

## Exercises

1. Compute `XLII`, `MMXXIV`, and `_V_DCCXIX` in decimal by hand. Verify with `READ OUT` of the corresponding constant.
2. The Roman numeral system has no zero. Our runtime emits nothing for `READ OUT` of a zero-valued variable. Construct a program that distinguishes "zero output" from "no output". Hint: print a marker character around it.
3. Write an INTERCAL program that reads a number and prints its Roman form. Use only the syslib for arithmetic.
4. The maximum value our runtime handles is roughly 4,000,000 (one cycle of the overbar). What happens for values above that? Read the runtime source and trace.
5. The digit-name `NINER` is required but `NINE` is not accepted. Suppose we wanted to relax this and accept both. What changes are needed in `_rt_write_in_scalar`?

## Next reading

- [runtime.md](runtime.md): the full runtime context for both routines.
- [intercal-primer.md](intercal-primer.md): the language tour with the brief I/O section.
- [turing-text-model.md](turing-text-model.md): the array-based character I/O that complements the scalar numeric I/O described here.
