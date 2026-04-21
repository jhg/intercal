# Calling conventions

A calling convention is the contract that governs how a caller and a callee transfer control and data. Which registers hold arguments, which registers survive a call, who cleans the stack, where the return value lands. Every platform we target specifies one, and our generated code has to respect it at every `bl` or `call` boundary.

This chapter describes the conventions for the three targets — AAPCS64 on macOS and Linux ARM64, System V AMD64 on Linux x86-64 — and shows where each one surfaces in our code.

## Why calling conventions matter to this compiler

The emitted code for an INTERCAL statement usually ends with one or more subroutine calls into the runtime: `bl _rt_mingle`, `bl _rt_write_roman`, `bl _rt_read_out_array`. Every one of those is a place where the calling convention applies. A codegen mistake that violates the convention — passing the wrong argument in the wrong register, clobbering a callee-saved register, imbalancing the stack — produces a runtime crash whose cause is not visible in the source program.

The runtime itself is also a collection of callees. Each `_rt_*` routine has to preserve the registers the convention says it must preserve, restore the stack pointer on exit, and return values in the right place.

Finally, the `main` entry point of a compiled program is itself a callee of the C runtime startup code that calls it. Getting main's prologue and epilogue wrong breaks every program.

## AAPCS64 — ARM64 on macOS and Linux

AAPCS64 is the ARM Architecture Procedure Call Standard for 64-bit. Both macOS and Linux follow it, with small platform-specific addenda.

### Register roles

| Register | Role |
|----------|------|
| `x0`–`x7` | Integer argument and return registers. Up to 8 arguments fit in registers; further arguments spill to the stack. `x0` holds the primary return value; `x0`–`x1` hold 128-bit returns. |
| `x8` | Indirect result location register, also used on Linux as the syscall number. |
| `x9`–`x15` | Caller-saved temporaries. The callee can clobber these freely. |
| `x16`, `x17` | Intra-procedure-call scratch, also the syscall number register on macOS (`x16`). |
| `x18` | Platform-reserved. Apple uses it; Linux user code generally does not. |
| `x19`–`x28` | Callee-saved. If a callee uses any of these it must restore them before returning. |
| `x29` | Frame pointer. |
| `x30` | Link register. `bl` writes the return address here. `ret` reads it. |
| `sp` | Stack pointer. Must be 16-byte aligned at every call site. |

On macOS, our generated `_main` follows the convention: at entry, `argc` is in `x0` and `argv` is in `x1`. On Linux, the `_start` / `main` contract is slightly different — `libc` wraps `main` — but we observe the same register contents.

### What the codegen has to respect

- Pass INTERCAL-level expression results through `x0` / `w0`. Every `bl _rt_*` that takes one argument places it in `x0`.
- The NEXT stack helper `_rt_resume_1` is called with the count in `w0` and does its own branch via `br x3` (the target address popped from `_next_stack`). The helper is aware it is not a normal callee and bypasses the usual return convention.
- The `_rt_mingle`, `_rt_select` and unary routines preserve `x0`–`x7` only as documented; the codegen must save any value in `x1`–`x7` across them if needed.
- `sp` must be 16-byte aligned before every `bl`. The emitted code does not allocate per-statement stack frames, so this invariant is maintained by the runtime entry prologue, not by codegen.

### Small AAPCS64 traps

- `x16` changes role between macOS (syscall number) and Linux (intra-procedure scratch). The `sed` pipeline in `intercalc.sh` rewrites `mov x16, #N` into `mov x8, #M` when translating for Linux, along with the syscall number itself.
- `stp` / `ldp` operate on 16-byte pairs. Forgetting to use these instead of pairs of `str` / `ldr` is a common bug; the pair forms are cheaper and also maintain 16-byte alignment implicitly.
- Floating-point arguments go in `v0`–`v7`. Our compiler emits no floating-point code, so we never touch those registers. If we ever do, AAPCS64's full rules for mixed integer/float argument passing become relevant.

## System V AMD64 — Linux x86-64

The System V AMD64 ABI governs Linux, FreeBSD, macOS (for user code), and essentially every x86-64 Unix. We target it directly for Linux x86-64; macOS on x86-64 is not a platform we support today.

### Register roles

| Register | Role |
|----------|------|
| `rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9` | Integer argument registers, in that order. |
| `rax`, `rdx` | Return value registers (`rax` for 64-bit, `rax:rdx` for 128-bit). |
| `r10` | Used by the ABI as a static chain for nested functions; in our code, a caller-saved scratch. |
| `r11` | Caller-saved scratch. |
| `rbx`, `rbp`, `r12`–`r15` | Callee-saved. |
| `rsp` | Stack pointer. Must be 16-byte aligned *before* a `call` instruction is executed; on entry to a function it is 8-byte-aligned-past-16 because `call` pushed an 8-byte return address. |

The alignment rule is a frequent source of bugs. The idiomatic prologue is `push rbp; mov rbp, rsp; sub rsp, N` for some 16-byte-multiple N, which restores 16-byte alignment at the first nested `call`.

### What the codegen has to respect

- `codegen_x86_64.sh` places the first integer argument in `rdi`, not `rax`. This is the most common source of bugs when translating from ARM64 codegen (where the first argument is `x0`): the direct register correspondence is `rdi` ↔ `x0`.
- Call sites must align the stack. The `codegen_*` functions in the x86-64 backend allocate 16-byte frames for every statement that makes a call, to be safe.
- `r12`–`r15` are callee-saved. The runtime's `_rt_sys666_open` and `_rt_sys666_write` use `r14` to hold a buffer size across a syscall, because a caller-saved register would not survive the syscall's internal register clobbering.
- Syscalls on Linux x86-64 use the `syscall` instruction, with the syscall number in `rax` and arguments in `rdi`, `rsi`, `rdx`, `r10`, `r8`, `r9` (note: `r10` replaces `rcx`, because `syscall` clobbers `rcx`). This is almost the System V AMD64 convention but not identical — `rcx` is replaced by `r10` for syscalls specifically.

### Small System V AMD64 traps

- The red zone: the 128 bytes below `rsp` are available to leaf functions without adjusting the stack pointer. Our runtime uses this in a few places to avoid prologue overhead. Windows x64 does not have a red zone; if we ever target Windows, the optimisation has to be reverted.
- `syscall` vs `call`: `syscall` does not touch the stack. No return address is pushed. The kernel arranges the return via a privileged instruction.
- Intel syntax destination-first, AT&T syntax source-first. Our emitted code is uniformly Intel. Mixing the two in the same `.s` file confuses GNU `as`.

## macOS ARM64 specifics

The macOS ABI is AAPCS64 with a few deviations:

- `_main` is the entry point symbol, not `main`. The underscore is mandatory for every external symbol (this is a Mach-O convention, not strictly AAPCS64).
- The Apple linker (`ld`) is more lenient about `.global` declarations than GNU `ld`. We still emit `.global` for every top-level symbol; this is the intersection of what both linkers accept.
- The syscall mechanism uses `svc #0x80` with the syscall number in `x16`. No other ABI uses `0x80`.

These are all tabulated alongside the Linux equivalents in [platforms.md](platforms.md).

## Linux ARM64 specifics

Standard AAPCS64 with these corners:

- Syscalls via `svc #0` (not `#0x80`), with the number in `x8` (not `x16`). This is a Linux ABI convention, not AAPCS64.
- `openat` is used instead of `open` because the kernel no longer exposes `open`. The first argument is `AT_FDCWD` (-100), which shifts every subsequent argument's register by one.
- Negative return values indicate errors. The check is `cmp x0, #0; b.lt error_handler`, not `b.cs`.

## Our callee discipline

Every `_rt_*` routine in the runtime files follows the same discipline, which is the intersection of AAPCS64 and System V AMD64:

1. Preserve all callee-saved registers. If the routine needs any of `x19`–`x28` / `r12`–`r15`, it saves them in the prologue.
2. Preserve the frame pointer and restore the stack pointer on exit. The prologue is `stp x29, x30, [sp, #-16]!` on ARM64, `push rbp; mov rbp, rsp` on x86-64.
3. Return via `ret` (ARM64) or `ret` (x86-64), which reads the return address from the link register or the stack respectively.

Several routines that use the `syscall` instruction internally save and restore `rcx` and `r11` on x86-64, because those registers are clobbered by `syscall`. A bug that predated the current runtime assumed the compiler's caller code could rely on them; the fix was to make the syscall wrappers preserve them.

## Worked example: `bl _rt_write_roman`

The generated code for `DO READ OUT .1`, after stripping the abstain check and label framing:

    ; ARM64
    adrp x0, _spot_1@PAGE
    add x0, x0, _spot_1@PAGEOFF
    ldr w0, [x0]         ; value now in w0 (zero-extended to x0)
    bl _rt_write_roman   ; call runtime

The `bl` is the instruction that enforces the convention. At this point, `x0` holds the argument (the scalar value), `x30` will be overwritten with the return address, and `sp` is 16-byte aligned.

Inside `_rt_write_roman`:

    _rt_write_roman:
      stp x29, x30, [sp, #-32]!
      mov x29, sp
      ; ... routine body ...
      ldp x29, x30, [sp], #32
      ret

The prologue saves the frame pointer and link register, allocating 32 bytes of frame (enough for the stack-local roman-numeral buffer the routine uses). The epilogue restores them and returns.

The x86-64 equivalent looks similar structurally, with different mnemonics:

    ; x86-64
    lea rdi, [rip + _spot_1]    ; address in rdi
    mov edi, dword ptr [rdi]    ; value now in edi/rdi
    call _rt_write_roman

    _rt_write_roman:
      push rbp
      mov rbp, rsp
      sub rsp, 32
      ; ... routine body ...
      mov rsp, rbp
      pop rbp
      ret

The same structure — save frame pointer, allocate local frame, restore, return — with different instruction names.

## Why we do not reinvent the wheel

Writing a compiler that targets a custom calling convention is possible, but not a good idea. Every such compiler ends up needing to interoperate with the system linker, the C runtime, and the kernel, all of which already agree on a convention. The right answer is to match the host platform's convention so that:

- `main`, `_main`, and every `_rt_*` symbol can be linked by `cc`.
- The `write`, `read`, `open`, `close`, `mmap`, `exit` syscalls can be invoked correctly.
- Future interoperability (calling C from INTERCAL, calling INTERCAL from a test harness written in another language) remains straightforward.

This is the same reasoning behind the `--pure-syslib` design: we match the native side's calling convention even in pure-INTERCAL code, because the alternative would fork the interface.

## Exercises

1. Trace `DO READ OUT .5` from the emitted assembly through `_rt_write_roman` to the `write` syscall. How many times does a value move between registers? How many times is a value on the stack?
2. Suppose a future runtime routine needs to preserve `x19` across a call to a helper. Write the minimal prologue/epilogue pair that correctly follows AAPCS64.
3. The System V AMD64 ABI reserves `r10` as a static chain register for nested functions. Our compiler has no nested functions. Does the runtime ever touch `r10`? If so, why?
4. On Linux x86-64, the `syscall` instruction clobbers `rcx` and `r11`. Find every place in `src/runtime/linux_x86_64.s` where this matters, and describe what the surrounding code does to cope.
5. Why does the AAPCS64 calling convention require 16-byte stack alignment rather than 8-byte? Give a concrete reason tied to the instruction set.
