# The runtime

Everything the generated code calls into lives in a single platform-specific assembly file under `src/runtime/`. The runtime is written by hand, once per target, and never generated. This chapter is a guided tour of what is inside it, why each routine exists, and how the memory model is organised.

The three supported platforms each get their own file:

    src/runtime/macos_arm64.s       972 lines
    src/runtime/linux_arm64.s      1016 lines
    src/runtime/linux_x86_64.s     1023 lines

They implement the same interface with platform-specific assembly. The INTERCAL compiler is unaware of which one will be linked in — it emits symbolic calls like `bl _rt_write_roman`, and the platform decides at link time.

## Naming conventions

Every exported symbol begins with `_rt_`. Inside each file the routines are grouped into roughly five categories:

| Category | Examples | Purpose |
|----------|----------|---------|
| Operator primitives | `_rt_mingle`, `_rt_select`, `_rt_unary_and_16`, `_rt_unary_or_32` | The bit-level operators the INTERCAL grammar exposes (`$`, `~`, `&`, `V`, `?`). |
| Numeric I/O | `_rt_write_roman`, `_rt_write_in_scalar` | Roman numeral output, English digit-name input. |
| Character I/O | `_rt_read_out_array`, `_rt_write_in_array` | Turing Text Model tape, both directions. |
| Memory and control | `_rt_mmap`, `_rt_resume_1` | Allocation wrapper and the NEXT-stack helper. |
| Error exits | `_rt_error_E000` through `_rt_error_E633` | The 16 runtime error codes. |
| Syscall dispatch | `_rt_syscall_666`, `_rt_sys666_open`, `_rt_sys666_read`, ... | The Label 666 extension and its eight handlers. |

Internal helpers and data live under the same file without the `_rt_` prefix; they are `.Lxxx` local labels or anonymous data.

## Memory model

The per-program memory layout is composed by the codegen (see [code-generation.md](code-generation.md)) and backed by fixed-size BSS reservations declared in the runtime. At runtime the layout looks like this:

                    ┌─────────────────────────────────────────────┐
    .text           │  _main, all _stmt_i_start/end, all _rt_*    │
                    ├─────────────────────────────────────────────┤
    .data           │  _roman_table, _errmsg_*, _ttm_heads init   │
                    ├─────────────────────────────────────────────┤
    .bss            │  _stmt_flags      (one byte per statement)  │
                    │  _spot_N          (4 bytes, one per scalar) │
                    │  _spot_N_ign      (1 byte,  one per scalar) │
                    │  _twospot_N       (4 bytes)                 │
                    │  _twospot_N_ign   (1 byte)                  │
                    │  _tail_N_ptr      (8 bytes, array pointer)  │
                    │  _tail_N_dims     (64 bytes, up to 16 dims) │
                    │  _tail_N_ign      (1 byte)                  │
                    │  (same triplet for every used ;N)           │
                    │  _stash_spot_N     (stash stack + sp)       │
                    │  _next_stack       (80×8 bytes return addrs)│
                    │  _next_sp          (4 bytes)                │
                    │  _ttm_out_pos      (4 bytes)                │
                    │  _ttm_in_pos       (4 bytes)                │
                    │  _argc             (4 bytes)                │
                    │  _argv             (8 bytes pointer)        │
                    │  _sys666_buf       (fixed allocation for    │
                    │                     the ,65535 data buffer) │
                    └─────────────────────────────────────────────┘

A 16-bit onespot occupies four bytes because ARM64 zero-extends `ldr w`; using a 32-bit slot simplifies loads. A twospot already is 32-bit, so one slot suffices. An array has three pieces: an 8-byte pointer set by `_rt_mmap`, a 64-byte dimensions table supporting up to 16 dimensions, and a one-byte ignore flag.

Arrays are heap-allocated lazily. The first `DO ,N <- #K` calls `_rt_mmap` to reserve K×2 bytes (or K×4 for a hybrid `;N`), stores the returned pointer in `_tail_N_ptr`, and writes the dimensions table. Redimensioning re-mmaps and drops the previous allocation. The previous contents are discarded, as specified.

## Operator primitives

The two binary operators, mingle (`$`) and select (`~`), are implemented as tight loops:

- `_rt_mingle` takes two 16-bit values in `w0` and `w1`, iterates i=0..15, and places the bit `w1[i]` at position `2*i` and the bit `w0[i]` at position `2*i+1` of the 32-bit result. The emitted code uses shifts and ORs; no branches inside the loop body.
- `_rt_select` takes a value in `x0` and a mask in `x1`, iterates over the mask's 32 bits, and packs the corresponding value bits right-justified. The result width depends on how many mask bits were set: if ≤16, the caller treats the result as 16-bit, otherwise as 32-bit. This is why `expr_width` is tracked on the tree: codegen needs to know whether to emit a 16-bit overflow check on the result.

The three unary operators each have a 16-bit and a 32-bit variant. The 32-bit variants exploit the ARM64 `ror` instruction (rotate right by one, wrapping the LSB to the MSB) to express "shift right by 1 with wrap-around" in a single cycle. The 16-bit variants cannot use `ror` directly because ARM64 does not offer `ror` on 16-bit sub-registers; they shift-and-mask instead.

These primitives never allocate and never branch to error handlers. They are called many times during a program's execution and are on the hot path for any arithmetic program.

## Numeric I/O

`_rt_write_roman` takes a 32-bit integer in `w0` and writes its Roman numeral representation to stdout. The routine walks a table of (value, symbol) pairs, subtracting where possible, emitting characters into a stack buffer, and finally calling the platform `write` syscall once for the whole string. Values above 3999 use the vinculum (overbar) convention: a thousand is notated `_I` and so on. Values ≥ 4000000 are not supported; the routine clamps silently, which is a latent issue listed in the TODO.

`_rt_write_in_scalar` reads stdin, skipping whitespace, until it has the sequence of English digit names that compose the number. `ONE` is 1, `TWO` is 2, and so on up to `NINER` which is 9 (per the spec; `NINE` is not recognised). Each digit is folded into the running value modulo 10. End of input before any digit is ICL562I; an unrecognised token is ICL579I.

## Character I/O: the Turing tape

READ OUT and WRITE IN on array variables operate via a Turing Text Model tape: a circular buffer of 256 positions, one "head" per direction (`_ttm_out_pos`, `_ttm_in_pos`), and a relative-offset encoding that ties the head's movement to a bit-reversed ASCII code.

For output (`_rt_read_out_array`):

1. For each element `v` of the array, subtract from the current output head position, modulo 256.
2. The new position, after bit-reversing its 8 bits, is the ASCII code to emit.
3. Update the head, emit the character, move on.

For input (`_rt_write_in_array`), the symmetric process: read a character, bit-reverse its code, compute the delta from the previous head position, store that delta in the array element.

The two heads do not share state. Reads and writes are independent. The tape's role is not to buffer text but to make text-as-arithmetic: writing "H" is expressed as the tape-distance from the previous head position to the bit-reversed value of `H`'s ASCII code.

This is the reason the hello-world test file starts with constants like `#238`, `#108`, `#112`. Each is the delta from the previous head position (starting at 0) to the bit-reversed ASCII code of a character. The compiler does not compute these deltas — the programmer must.

## Memory allocation

`_rt_mmap` is a thin wrapper around the platform's `mmap` system call. On macOS ARM64 it requests `MAP_ANON|MAP_PRIVATE` (0x1002) with prot `PROT_READ|PROT_WRITE` (3). On Linux ARM64 the flags differ (0x22 instead of 0x1002) and the syscall number is 222 instead of 197. On Linux x86-64 the convention is the System V AMD64 ABI, with syscall 9.

The returned pointer is stored in the array's `_tail_N_ptr` slot and accessed by every subsequent read/write of that array. No free call exists: arrays are never reclaimed during program execution. For the programs INTERCAL runs this is acceptable, and the OS reclaims everything at process exit.

## The NEXT stack

INTERCAL's `NEXT/RESUME` pair is implemented by a fixed-size array of return addresses plus a stack pointer:

    _next_stack: .space 80*8      ; 80 slots of 8 bytes each
    _next_sp:    .space 4          ; current depth, 0 = empty

`NEXT (N)` codegen produces:

    ldr w0, [_next_sp]
    cmp w0, #79
    b.ge _rt_error_E123
    adr x1, _stmt_after_next     ; return address
    str x1, [_next_stack, w0, uxtw #3]
    add w0, w0, #1
    str w0, [_next_sp]
    b _stmt_<target>_start
    _stmt_after_next:

`RESUME #K` codegen evaluates K into `w0` and calls `_rt_resume_1` with the count. The helper decrements the stack pointer K times, guards against underflow (ICL632I / ICL621I), and branches to the last popped address via `br`.

A stack depth of 79 is the specified limit. Pushing the 80th fires ICL123I. In practice this is a real constraint; deep subroutine chains must `FORGET #1` at loop heads to avoid exhaustion.

## Errors

Each of the 16 runtime errors gets its own exit routine. They all follow the same template: load the address of a preformatted message string, write its bytes to stderr (fd 2), and exit with status 1.

The preformatted messages live in the data section. For example:

    _errmsg_123:  .ascii  "ICL123I PROGRAM HAS DISAPPEARED INTO THE BLACK LAGOON\n"

The full table is:

| Code | Meaning | Emitted by |
|------|---------|------------|
| E000 | UNDECODABLE STATEMENT | codegen for UNKNOWN statements |
| E017 | BAD EXPRESSION | reserved; not currently emitted |
| E123 | NEXT STACK OVERFLOW | NEXT codegen |
| E129 | NEXT TO UNKNOWN LABEL | NEXT codegen (if label lookup fails) |
| E139 | ABSTAIN/REINSTATE OF UNKNOWN LABEL | ABSTAIN/REINSTATE codegen |
| E200 | UNDEFINED VARIABLE | latent; reserved for future checks |
| E240 | ZERO-DIM ARRAY | dimension codegen |
| E241 | BAD SUBSCRIPT | array-access codegen |
| E275 | 32-BIT VALUE TO 16-BIT SLOT | scalar assign codegen |
| E436 | RETRIEVE WITHOUT STASH | RETRIEVE codegen |
| E533 | ARITHMETIC OVERFLOW | reserved for syslib |
| E562 | END OF INPUT | numeric input |
| E579 | BAD INPUT | numeric input |
| E621 | RESUME ZERO | RESUME codegen |
| E632 | PROGRAM ENDED WITHOUT GIVE UP | RESUME helper |
| E633 | FELL OFF THE END | fallthrough past the last statement |

E000, E017, E200 and a few others are runtime endpoints for static conditions that the compiler does not yet flag. The reserved-but-unused codes remain because upgrading the compiler to catch them at compile time requires a proper type/flow analysis, which we have not built.

## Label 666

The Label 666 dispatcher and its eight handlers take up nearly 400 lines at the bottom of the runtime. Because they deserve a chapter of their own, and because the design rationale for choosing Label 666 over CLC-INTERCAL's original "call by vague resemblance" convention is already written up, see the dedicated chapter [666.md](666.md).

At a high level: `bl _rt_syscall_666` reads the syscall number from `.1`, dispatches to the appropriate `_rt_sys666_<name>` handler, and returns. Parameters and results live in `.2/.3/.4` for scalars and in the reserved `,65535` array for buffer data.

## Exercises

1. In `_rt_write_roman`, what happens when `w0` is 0? Read the source and explain why that behaviour is acceptable.
2. The TTM tape is 256 entries, one per byte value. What breaks if the tape were 128 entries instead?
3. Add a mental model: given the program `DO ,1 <- #3 / DO ,1 SUB #1 <- #72 / DO READ OUT ,1`, does it print `H`? Explain.
4. The NEXT stack is 80 entries deep. Suppose we wanted to make it 1024. What needs to change in the runtime, in the compiler, and in the test harness?
5. Write a C program that reads the same `,65535` buffer the Label 666 read handler writes into, and prints its first byte. What calling convention does your C program have to match?
6. The runtime never calls `free`. Is there a program whose execution would leak memory faster than the OS reclaims it? Give one.

## Next reading

- [syslib.md](syslib.md) — arithmetic labels 1000–1999 and the pure-vs-native split.
- [666.md](666.md) — the Label 666 syscall extension in depth.
- [platforms.md](platforms.md) — how the three runtime files differ mechanically.
