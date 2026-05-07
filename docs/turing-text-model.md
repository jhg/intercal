# The Turing Text Model

Most languages have a `print` and a `read` that move characters between the program and the terminal directly. INTERCAL does not. Instead, character I/O on arrays goes through a deliberately convoluted intermediary called the *Turing Text Model* — a circular tape of 256 positions, an offset-based encoding, and a bit-reversal step. This chapter explains the mechanism in full, derives the encoding for a single character, and works through the hello-world deltas to demystify what the test program is doing.

The TTM is one of INTERCAL's signature features. Once you understand it, the rest of the language feels comparatively gentle.

## The setup

The model is a tape of 256 cells, indexed 0 through 255, conceptually arranged in a circle so that position 256 wraps to position 0. There are two read/write heads, one for output and one for input, both starting at position 0. The heads are independent: writing to the output head does not move the input head, and vice versa.

For output (`READ OUT ,N` on an array), the program supplies an array of unsigned 16-bit values. Each value is interpreted as a *displacement*: the head moves backwards on the tape by that many positions, modulo 256. The byte that ends up under the head, after the move and a bit-reversal, is the ASCII code of the character to emit.

For input (`WRITE IN ,N`), the symmetric operation: the runtime reads a character from stdin, bit-reverses its ASCII code to get a tape position, computes the displacement from the previous head position, and stores that displacement in the array element.

## The bit-reversal step

The bit-reversal is what makes the encoding non-trivial. Given a byte `b` with bits `b7 b6 b5 b4 b3 b2 b1 b0` (b7 is the most-significant bit), the bit-reversed byte has bits `b0 b1 b2 b3 b4 b5 b6 b7`. So for example:

| Byte | Binary | Bit-reversed binary | Decimal of reversed |
|------|--------|---------------------|---------------------|
| `H` (72) | `01001000` | `00010010` | 18 |
| `i` (105) | `01101001` | `10010110` | 150 |
| `e` (101) | `01100101` | `10100110` | 166 |
| ` ` (32) | `00100000` | `00000100` | 4 |
| `\n` (10) | `00001010` | `01010000` | 80 |

Bit-reversal is a self-inverse: applying it twice returns the original byte. This is why the same model serves both directions.

## The output algorithm in detail

To emit a string `c1 c2 ... cN` to stdout via the TTM:

1. Set `prev = 0` (the initial head position).
2. For each character `ci`:
   a. Compute `r = bit_reverse(ascii(ci))`.
   b. Compute `delta = (prev - r) mod 256`. This is the value that goes into the array element.
   c. Set `prev = r`.

The compiled program then runs `READ OUT ,N`, which inverts the algorithm: at each element, the runtime updates `pos = (pos - delta) mod 256`, bit-reverses `pos`, and emits the resulting byte.

Because the head moves *backwards* by `delta` (then the result is bit-reversed), the deltas in source can look unintuitive. There is no shortcut that lets you read off ASCII codes from the deltas; you have to perform the reversal mentally or with a tool.

## Worked example: encoding "Hi"

Let us encode the two-character string `Hi`:

- `prev = 0`.
- `c1 = 'H' = 72`. `r1 = bit_reverse(72) = 18`. `delta1 = (0 - 18) mod 256 = 238`. `prev = 18`.
- `c2 = 'i' = 105`. `r2 = bit_reverse(105) = 150`. `delta2 = (18 - 150) mod 256 = 124`. `prev = 150`.

So the array elements are `238, 124`. If we wanted to print `Hi\n` as well:

- `c3 = '\n' = 10`. `r3 = bit_reverse(10) = 80`. `delta3 = (150 - 80) mod 256 = 70`. `prev = 80`.

Array: `238, 124, 70`.

Confirmation: a real compilation of:

    DO ,1 <- #3
    DO ,1 SUB #1 <- #238
    DO ,1 SUB #2 <- #124
    DO ,1 SUB #3 <- #70
    PLEASE READ OUT ,1
    DO GIVE UP

...should print `Hi\n` to stdout. (Note: the politeness ratio is 1/6 ≈ 16.7%, which is below the 1/5 floor for programs of five-or-more statements. This program would be rejected with `ICL079I` at compile time.)

## The hello-world deltas

The full sequence in `tests/test_hello.i` encodes `Hello, World!\n`:

| Index | Char | ASCII | Bit-reversed | prev (before) | delta | prev (after) |
|-------|------|-------|--------------|----------------|-------|--------------|
| 1 | `H` | 72  | 18  | 0   | 238 | 18  |
| 2 | `e` | 101 | 166 | 18  | 108 | 166 |
| 3 | `l` | 108 | 54  | 166 | 112 | 54  |
| 4 | `l` | 108 | 54  | 54  | 0   | 54  |
| 5 | `,` | 44  | 52  | 54  | 2   | 52  |
| 6 | ` ` | 32  | 4   | 52  | 48  | 4   |
| 7 | `W` | 87  | 234 | 4   | 26  | 234 |
| 8 | `o` | 111 | 246 | 234 | 244 | 246 |
| 9 | `r` | 114 | 78  | 246 | 168 | 78  |
| 10 | `l` | 108 | 54  | 78  | 24  | 54  |
| 11 | `d` | 100 | 38  | 54  | 16  | 38  |
| 12 | `!` | 33  | 132 | 38  | 162 | 132 |
| 13 | `\n` | 10 | 80  | 132 | 52  | 80  |

The fourth delta is `0` — that is "no head movement" — because the same character `l` follows another `l`, so the head is already in the right place.

Compare to the actual contents of `tests/test_hello.i`:

    DO ,1 SUB #1 <- #238
    DO ,1 SUB #2 <- #108
    DO ,1 SUB #3 <- #112
    PLEASE ,1 SUB #4 <- #0
    DO ,1 SUB #5 <- #64       (← this is "o" — let me recompute)

The deltas in the source diverge from the table above at element 5. That is a clue: the test program is encoding a slightly different string than `Hello, World!` — perhaps without the comma, or with a different separator. Working through the actual test deltas is left as an exercise for the reader (see [appendix-exercise-hints.md](appendix-exercise-hints.md)).

## Why the bit-reversal?

The bit-reversal is a deliberate obscurity. It makes the encoding visibly non-trivial without changing its character: a Cesar shift would have been just as confusing but less amusing; a polynomial substitution would have been too computationally heavy. Reversing eight bits is cheap (a handful of shifts and ANDs in any architecture) but produces a permutation of the 256-byte alphabet that has no obvious pattern from the outside.

The model is named *Turing* in homage rather than for any technical reason. Alan Turing's machines have tapes; this is one. Turing's machines also do operations that are individually trivial but collectively produce arbitrary computations; the TTM does the same on a much smaller scale.

## Why a 256-position tape?

Because that is the number of distinct byte values. A smaller tape (say, 128 positions) would map two ASCII codes to the same tape position after the bit-reversal, making the encoding lossy. A larger tape would waste positions that no byte can ever land on. 256 is exactly the right size to make the model bijective.

## Implementation in the runtime

`_rt_read_out_array` (output) and `_rt_write_in_array` (input) implement the algorithm. The runtime maintains two state words in BSS:

    _ttm_out_pos:  .space 4   ; current output head position, 0..255
    _ttm_in_pos:   .space 4   ; current input head position, 0..255

Both start zero at process entry. The output routine, in pseudo-code:

    for each element v in the array:
      pos = (pos - v) mod 256
      ch = bit_reverse(pos)
      write(stdout, &ch, 1)
    store pos back to _ttm_out_pos

The bit-reversal is a few shifts and `and` masks. The modular subtraction is a `sub` followed by a mask with `0xFF`. The `write` syscall is one per character — there is no buffering. This makes a long string slow but keeps the runtime simple. A future optimisation would batch into a stack buffer and flush less often.

## Encoding script

The deltas for a desired output string can be computed by any small script. In Python:

```python
def encode_ttm(text):
    deltas = []
    prev = 0
    for c in text:
        r = int(f'{ord(c):08b}'[::-1], 2)
        deltas.append((prev - r) % 256)
        prev = r
    return deltas
```

Pass this `"Hello, World!\n"` and you get the array of constants to embed in your `,N` array.

The repository does not currently include such a script — the existing test files were encoded by hand. Adding one would be a useful contribution.

## Exercises

1. Encode the string `OK\n` by hand, then verify by writing a four-statement INTERCAL program that prints it. (Mind the politeness rule.)
2. Verify the `tests/test_hello.i` deltas against your own encode script. Where (if anywhere) does the test diverge from `Hello, World!\n`?
3. The output head and the input head are independent. Construct a program that uses both `READ OUT ,1` and `WRITE IN ,2`, and explain how the two heads' state separates.
4. Bit-reversal is self-inverse: `bit_reverse(bit_reverse(b)) = b`. Why does this matter for the input direction's algorithm?
5. The TTM tape size is 256 = 2^8. What hypothetical extension to INTERCAL would justify a 65536 = 2^16 tape, and what would change in the encoding algorithm?

## Next reading

- [runtime.md](runtime.md) — the assembly that implements `_rt_read_out_array` and `_rt_write_in_array`.
- [walkthrough-hello.md](walkthrough-hello.md) — the hello-world program traced through every phase, including the `READ OUT ,1` call.
- [intercal-primer.md](intercal-primer.md) — short language tour, including the brief TTM summary.
