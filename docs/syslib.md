# The system library

INTERCAL has no infix arithmetic. There is no `+`, no `*`, no `/`. The only operators the grammar exposes are bitwise: mingle, select, and the three unary rotate-and-combine variants. Addition, subtraction, multiplication, division, and random-number generation are all supplied as subroutines at reserved labels 1000–1999, via `NEXT`.

This chapter explains how those labels work, why we maintain two parallel implementations (pure INTERCAL and native assembly), and how the compiler decides which one to link against.

## The arithmetic interface

The convention is uniform across all 20 routines:

- Inputs go in `.1` and `.2` for 16-bit operations, or `:1` and `:2` for 32-bit.
- Outputs go in `.3` and optionally `.4` (for overflow flag), or `:3` and `:4`.
- The caller is responsible for `STASH`ing any of `.1–.4` or `:1–:4` that it needs to preserve, and for `RETRIEVE`ing them after the return.
- The routine ends with `RESUME #1`, which pops one NEXT frame and returns.

The full table:

| Label | Operation | Overflow? |
|-------|-----------|-----------|
| 1000 | `.3 = .1 + .2` (16-bit) | Error ICL533I on overflow |
| 1009 | `.3 = .1 + .2`, `.4 = #1` no overflow or `#2` overflow | Flag in `.4` |
| 1010 | `.3 = .1 - .2` (wraps) | No error |
| 1020 | `.1 = .1 + 1` (in-place, wraps) | No error |
| 1030 | `.3 = .1 * .2` (16-bit) | Error on overflow |
| 1039 | `.3 = .1 * .2`, `.4` overflow flag | Flag in `.4` |
| 1040 | `.3 = .1 / .2` (integer) | `.3 = 0` if `.2 = 0` |
| 1050 | `.2 = :1 / .1` (32/16 → 16) | Error on quotient overflow |
| 1500 | `:3 = :1 + :2` (32-bit) | Error on overflow |
| 1509 | `:3 = :1 + :2`, `:4` overflow flag | Flag in `:4` |
| 1510 | `:3 = :1 - :2` (32-bit, wraps) | No error |
| 1520 | `:1 = .1 $ .2` (mingle, explicit) | No overflow possible |
| 1530 | `:1 = .1 * .2` (16×16 → 32) | No overflow possible |
| 1540 | `:3 = :1 * :2` (32-bit) | Error on overflow |
| 1549 | `:3 = :1 * :2`, `:4` overflow flag | Flag in `:4` |
| 1550 | `:3 = :1 / :2` (32-bit) | `:3 = 0` if `:2 = 0` |
| 1900 | `.1 = uniform random 0..65535` | — |
| 1910 | `.2 = gaussian-ish random 0..`.1 | — |

Two internal labels exist but should not be called directly: 1525 (a shift helper) and 1999 (the overflow error exit). They are not part of the public interface.

## Why two implementations

This repository keeps two complete copies of the syslib:

- `src/syslib/syslib.i` — 9065 lines of pure INTERCAL, demonstrating that every arithmetic primitive is in fact implementable in a Turing-complete language with only bitwise operators.
- `src/syslib/native/<platform>.s` — the same 20 labels written in ~300 lines of platform-specific assembly, executing in microseconds rather than seconds.

The existence of both is not redundancy. It is a correctness and a pedagogy decision.

### Correctness: the two implementations verify each other

Each native routine is a direct translation of the bit-level pseudocode that `syslib.i` uses to compute the result, plus a few algebraic simplifications that are sound only because of the unsigned 16- or 32-bit arithmetic model. Running the same INTERCAL program with both versions and diffing the outputs is a powerful differential test: if the two disagree on any input, one of them is wrong.

That is what `tests/test_syslib_pure.sh` exercises. It compiles three programs twice, once with each syslib, and asserts the outputs match byte for byte. Any divergence is a fail.

This pattern — two independent implementations crosschecked against each other — is a standard technique in compiler testing. The Dafny, GraalVM and LLVM projects all use variants of it. Our version is small, cheap, and catches drift whenever somebody modifies the native syslib without updating the pure one (or vice versa).

### Pedagogy: the pure syslib is the specification

Somebody reading `src/syslib/syslib.i` sees, in literal INTERCAL, what addition means. The native assembly in `src/syslib/native/<platform>.s` is the fast implementation; the INTERCAL file is the reference. When you are unsure whether the spec says "subtract wraps on underflow" or "overflow is an error for 1000 but a flag for 1009", read the INTERCAL. It cannot lie, because every claim it makes is expressed in terms of operators whose semantics the language defines.

### Performance

The native syslib is substantially faster. A timing run on macOS ARM64 shows:

- Native: ~0.09s to compile a 300-statement program that calls syslib routines.
- Pure: ~30s for the same program, because the native output has to compile `syslib.i` alongside the user code, and `syslib.i` is 9065 lines of INTERCAL that themselves go through the whole pipeline.

Binary size grows from ~40 KB to ~1.3 MB in the pure case, since every syslib statement becomes its own block of assembly. The pure mode is not intended for day-to-day use.

## How the compiler decides

`detect_syslib` (in `intercalc.sh`) scans every `NEXT` target. If any lies in [1000, 1999], `needs_syslib=1`. If so:

- With the default flag layout (no `--pure-syslib`), the native assembly `src/syslib/native/<platform>.s` is concatenated with the runtime and the program, so the calls resolve at link time against hand-written routines.
- With `--pure-syslib`, the pure INTERCAL `src/syslib/syslib.i` is appended to the user's source *before* tokenisation, and its labels flow through the compiler like any other user-level statement. The final linking step no longer includes `src/syslib/native/<platform>.s`.

The `--pure-syslib` path is what verifies that the compiler, the runtime, and the syslib together are internally consistent: if the pure version computes the same answer as the native version across all three arithmetic test cases, then by construction the compiler handles the pure-INTERCAL syslib's constructs correctly. It is a regression sentinel for the language features the syslib actually uses.

## Why the pure syslib is big

Nine thousand lines to express twenty arithmetic routines is a lot. The size is not accidental.

Consider addition. Without `+`, you add two 16-bit integers a and b by repeating, for each bit position i, "if a_i and b_i, the carry propagates; if a_i xor b_i, the result bit is 1 unless the carry was 1 from below; ..." expressed entirely through `$`, `~`, `&`, `V`, `?`. The book-standard INTERCAL idiom for bitwise AND of two separate values goes via mingle followed by a unary `&` followed by a select — three statements and two temporaries just for "a AND b". Addition built atop that is twenty-plus statements for each of sixteen bit positions.

Once you have addition, subtraction is "add the two's complement", multiplication is repeated shift-and-add, division is repeated compare-and-subtract. Each step inherits the verbosity of the one below it.

The payoff for accepting the verbosity is that the language becomes complete. No `+` is ever needed. A compiler that accepts the subset of INTERCAL our syslib actually uses is complete enough to compile arbitrary arithmetic programs, which is precisely what makes self-hosting possible.

## The random routines need the runtime

Labels 1900 and 1910 stand apart. You cannot implement a true random-number generator in pure INTERCAL, because INTERCAL has no access to environmental entropy. `syslib.i`'s implementation of 1900 invokes the Label 666 syscall `getrand` (syscall number 9) to obtain a random number from the OS.

Inside `syslib.i`:

    (1900) PLEASE DO STASH .1 .2
           DO .1 <- #9
           DO .2 <- #0
           DO (666) NEXT
           DO .1 <- .3
           DO RETRIEVE .2

This is the single point where the pure syslib cannot pretend the runtime does not exist. Every other routine uses only INTERCAL's own operators.

## Exercises

1. Compile `tests/test_divide.i` with both syslibs and compare the emitted binary sizes. Explain the difference without reading the pure-mode output.
2. Write a three-statement INTERCAL program that verifies `1000 (addition) + 1010 (subtraction)` satisfies `(a + b) - b == a` for `.1 = 10`, `.2 = 20`.
3. Run `tests/test_syslib_pure.sh` under `time`. How does the wall-clock ratio correspond to the per-program 330× slowdown figure quoted above?
4. Read the implementation of label 1900 in `syslib.i`. How many statements execute per call in the common case where `.2 = 0`? How does that compare to the native version?
5. Suppose we wanted to add a new label 1700 for gcd. What has to change in the pure syslib, the native syslib, and the compiler's auto-detection?

## Next reading

- [runtime.md](runtime.md) — the native assembly that the native syslib links against for I/O and random.
- [666.md](666.md) — Label 666, which is what label 1900 uses to reach the OS.
- [self-hosting.md](self-hosting.md) — how the syslib factors into the 3-generation bootstrap.
