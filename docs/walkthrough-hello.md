# Walkthrough: Hello, World!

This chapter takes one specific INTERCAL program — `tests/test_hello.i` — and follows it through every phase of the compiler, capturing the state at each step. If the per-phase chapters are the reference material, this is the capstone worked example.

The source, `tests/test_hello.i`:

    DO ,1 <- #14
    DO ,1 SUB #1 <- #238
    DO ,1 SUB #2 <- #108
    DO ,1 SUB #3 <- #112
    PLEASE ,1 SUB #4 <- #0
    DO ,1 SUB #5 <- #64
    DO ,1 SUB #6 <- #194
    DO ,1 SUB #7 <- #48
    PLEASE ,1 SUB #8 <- #26
    DO ,1 SUB #9 <- #244
    DO ,1 SUB #10 <- #168
    DO ,1 SUB #11 <- #24
    PLEASE ,1 SUB #12 <- #16
    DO ,1 SUB #13 <- #162
    DO ,1 SUB #14 <- #52
    PLEASE READ OUT ,1
    DO GIVE UP

Seventeen statements. The program dimensions the array `,1` to 14 elements, assigns a precomputed Turing tape delta to each element, reads the array out (which prints "Hello, World!"), and exits.

## What the source is actually saying

Each constant on the right-hand side is the distance on a 256-entry tape that the tape head has to move, starting from the previous head position, such that the new head position — after all eight bits are reversed — equals the ASCII code of the character to print.

The sequence 238, 108, 112, 0, 64, 194, 48, 26, 244, 168, 24, 16, 162, 52 decodes to the letters H-e-l-l-o-comma-space-W-o-r-l-d-exclamation-newline. The bit-reversal is what makes the numbers look unpredictable: `238` is `0b11101110`, which reverses to `0b01110111` = 119, and `0 - 119 mod 256 = 137`; then `137 - 238 mod 256 = 155`... no, the arithmetic is the other direction, see [intercal-primer.md](intercal-primer.md) for the precise formula. The point is that every element is a tape-distance, not a character.

## Phase 1: read the source

`read_source` reads the file into `SOURCE`, collapses whitespace, uppercases. Result (truncated):

    SOURCE="DO ,1 <- #14 DO ,1 SUB #1 <- #238 DO ,1 SUB #2 <- #108 ... DO GIVE UP"

All 17 statements now live as a single space-separated string.

## Phase 2: tokenise

`tokenize` splits `SOURCE` into statements. The parallel arrays after this phase:

    stmt_count = 17

    stmt_label      (17 empty strings)
    stmt_polite     (0 0 0 0 1 0 0 0 1 0 0 0 1 0 0 1 0)
    stmt_negated    (17 zeros)
    stmt_prob       (17 × 100)
    stmt_type       (ASSIGN ASSIGN ASSIGN ASSIGN ASSIGN ASSIGN ASSIGN ASSIGN
                     ASSIGN ASSIGN ASSIGN ASSIGN ASSIGN ASSIGN ASSIGN READ_OUT GIVE_UP)
    stmt_body       (",1 <- #14"  ",1 SUB #1 <- #238"  ",1 SUB #2 <- #108"
                     ",1 SUB #3 <- #112"  ",1 SUB #4 <- #0"  ",1 SUB #5 <- #64"
                     ",1 SUB #6 <- #194"  ",1 SUB #7 <- #48"  ",1 SUB #8 <- #26"
                     ",1 SUB #9 <- #244"  ",1 SUB #10 <- #168"  ",1 SUB #11 <- #24"
                     ",1 SUB #12 <- #16"  ",1 SUB #13 <- #162"  ",1 SUB #14 <- #52"
                     "READ OUT ,1"  "GIVE UP")

Only four statements used `PLEASE` (indices 4, 8, 12, 15). The rest used `DO`.

## Phase 3: collect variables

`scan_variables` walks every body and records which variable numbers appear:

    used_tail=( [1]=1 )          # only ,1 is used

No spots, twospots or hybrids. Array ,1 will get a pointer and dimensions table in BSS.

## Phase 4: check politeness

4 polite out of 17 total. `4*5 = 20 >= 17` ✓ (lower bound), `4*3 = 12 <= 17` ✓ (upper bound). Politeness is satisfied. If any of the four `PLEASE`s were changed to `DO`, we would have 3/17 = 17.6%, below the 20% lower bound, and the compiler would fire ICL079I. If three more `DO`s became `PLEASE`, we would have 7/17 = 41.2%, above the 33.3% upper bound, and the compiler would fire ICL099I.

## Phases 5–7: labels, COME FROM, syslib

No labels in the source, so `label_to_stmt` is empty. No COME FROMs, so `come_from_target` is empty. No NEXTs in the range 1000–1999, so `needs_syslib = 0`. The syslib will not be linked.

## Phase 8: code generation

`codegen_program` emits the entry-point skeleton. `codegen_statement(i)` walks each of the 17 statements. The first statement, `DO ,1 <- #14`, has type `ASSIGN`, an array dimensioning form (the target is `,1` without a SUB). `codegen_array_dim` emits (approximately):

    _stmt_0_start:
      ; abstain check
      adrp x0, _stmt_flags@PAGE
      add x0, x0, _stmt_flags@PAGEOFF
      ldrb w1, [x0, #0]
      cbnz w1, _stmt_0_end

      ; evaluate RHS (#14) into w0
      mov w0, #14

      ; check that dimension > 0
      cbz w0, _rt_error_E240

      ; store dimension table
      adrp x1, _tail_1_dims@PAGE
      add x1, x1, _tail_1_dims@PAGEOFF
      str w0, [x1]
      mov w2, #1      ; number of dimensions
      str w2, [x1, #60]

      ; allocate 14 × 2 bytes via mmap
      mov w0, #28
      bl _rt_mmap

      ; store pointer
      adrp x1, _tail_1_ptr@PAGE
      add x1, x1, _tail_1_ptr@PAGEOFF
      str x0, [x1]
    _stmt_0_end:

The next fourteen statements are element assignments (`,1 SUB #N <- #V`). Each compiles to:

    _stmt_N_start:
      ; abstain check
      ; evaluate subscript #N into w3
      ; evaluate RHS #V into w0
      ; bounds check: subscript must be 1..14
      ; compute address: _tail_1_ptr + (subscript - 1) * 2
      ; store half-word
    _stmt_N_end:

The sixteenth statement, `PLEASE READ OUT ,1`, has type `READ_OUT` with a whole-array target. `codegen_read_out` detects the array form and emits:

    _stmt_15_start:
      ; abstain check
      adrp x0, _tail_1_ptr@PAGE
      add x0, x0, _tail_1_ptr@PAGEOFF
      ldr x0, [x0]
      adrp x1, _tail_1_dims@PAGE
      add x1, x1, _tail_1_dims@PAGEOFF
      ldr w1, [x1]
      mov w2, #2          ; element size in bytes
      bl _rt_read_out_array
    _stmt_15_end:

The seventeenth statement, `DO GIVE UP`, compiles to three instructions on macOS ARM64:

    _stmt_16_start:
      ; abstain check
      mov x0, #0
      mov x16, #1
      svc #0x80
    _stmt_16_end:

After the last statement, `codegen_program` emits a safety-net `bl _rt_error_E633` so falling past the end without `GIVE UP` is caught.

`emit_data` appends the BSS reservations:

    .section __DATA,__bss
    _stmt_flags: .space 17
    _tail_1_ptr: .space 8
    _tail_1_dims: .space 64
    _tail_1_ign: .space 1

## Phase 9: assemble and link

The generated assembly is concatenated with `src/runtime/macos_arm64.s` and piped through `cc`:

    cat runtime.s emitted.s | cc -x assembler - -o hello

`cc` invokes the system linker (`ld` on macOS), which resolves every `_rt_*` reference against the runtime symbols, and produces a Mach-O executable.

## Running it

    $ ./hello
    Hello, World!

What actually happens at runtime, step by step:

1. Process entry at `_main`. The runtime saves argc/argv.
2. Statement 0 executes. `mmap` allocates 28 bytes; pointer stored in `_tail_1_ptr`.
3. Statements 1–14 execute. Each stores a halfword into the allocated buffer.
4. Statement 15 executes. `_rt_read_out_array` is called with the pointer, count=14, size=2.
5. Inside `_rt_read_out_array`: for each of 14 elements, subtract from `_ttm_out_pos`, bit-reverse, emit the resulting ASCII code via the `write` syscall. One character at a time, or batched — the current implementation batches into a 256-byte stack buffer and flushes on boundaries.
6. Statement 16 executes. `exit(0)` via `svc #0x80` with `x16 = 1`.

The whole execution takes microseconds.

## On Linux ARM64, the same program

The `sed` post-processing step translates the generated assembly. The differences visible in the final binary:

- `_main` becomes `main`.
- `svc #0x80` becomes `svc #0`.
- `mov x16, #1` becomes `mov x8, #93` (Linux exit syscall number).
- Every `sym@PAGE` and `sym@PAGEOFF` is rewritten.

The runtime file `src/runtime/linux_arm64.s` was pre-translated the same way and is committed separately.

## On Linux x86-64, the same program

`codegen_x86_64.sh` overrides every codegen function. The emitted assembly is entirely different — Intel syntax, different register conventions, different syscall numbers — but the behaviour of the compiled binary is identical.

The array dimensioning statement 0, for instance, becomes:

    _stmt_0_start:
      ; abstain check
      lea rax, [rip + _stmt_flags]
      movzx ecx, byte ptr [rax]
      test ecx, ecx
      jnz _stmt_0_end

      ; evaluate #14
      mov eax, 14

      ; dimension check, store dimensions...
      ; mmap via syscall 9
      ; store pointer
    _stmt_0_end:

Different assembly, same semantics. Running `./hello` on a Linux x86-64 machine prints the same `Hello, World!`.

## What this example does not exercise

Hello world is small. It touches:

- Array dimensioning and element assignment.
- Array-based READ OUT (the Turing Text Model).
- GIVE UP.
- The politeness rule in its passing case.

It does not touch:

- Scalars, unary operators, mingle, select.
- Control flow (NEXT, RESUME, FORGET, COME FROM).
- Statement modifiers (ABSTAIN, REINSTATE, IGNORE, REMEMBER).
- STASH/RETRIEVE.
- The syslib.
- Label 666 syscalls.
- WRITE IN (numeric or character).
- Runtime errors.

Each of those is exercised by one or more of the 25 tests in `tests/run_tests.sh`. The reader who has followed the hello-world walkthrough is equipped to step into any of them and understand the emitted code.

## Exercises

1. The program has exactly 17 statements and 4 PLEASEs, giving a politeness ratio of 4/17 ≈ 0.235. What is the minimum number of `DO`s we could flip to `PLEASE` without breaking the upper politeness bound?
2. Regenerate the assembly by running `INTERCAL_ASM_ONLY=1 zsh src/bootstrap/intercalc.sh < tests/test_hello.i > hello.s`. Count the number of instructions emitted per statement. Is the per-statement overhead what you expect?
3. Change `PLEASE READ OUT ,1` to `DO READ OUT ,1` and recompile. The politeness is now 3/17 ≈ 0.176. Run the compiler. Which ICL code fires?
4. Compile hello-world with both `intercalc.sh` and `intercalc.sh --pure-syslib`. Why does the flag have no effect on the output?
5. The array is dimensioned to 14, not 13. What would break if the programmer reduced the dimension to 13? What if the programmer increased it to 30?

## Next reading

- [pipeline.md](pipeline.md) — the general pipeline, now with one concrete traversal behind you.
- [runtime.md](runtime.md) — `_rt_read_out_array` and the Turing Text Model in depth.
- [code-generation.md](code-generation.md) — all the other statement types we did not see here.
