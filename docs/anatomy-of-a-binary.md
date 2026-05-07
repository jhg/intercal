# Anatomy of a compiled binary

A practical guide to reading the binary your compiler just produced. We compile `tests/test_hello.i`, then dissect the resulting executable with the standard tooling. The goal is to make every byte traceable back to a chapter of these docs.

For the format-level theory see [executables-and-linking.md](executables-and-linking.md).

## Build the example

    zsh src/bootstrap/intercalc.sh < tests/test_hello.i > hello
    chmod +x hello
    ./hello

If `hello` printed `Hello, World!`, you have a working binary to dissect. Keep it around for the rest of this chapter.

## What format is it?

    file ./hello

On macOS Apple Silicon you should see something like:

    hello: Mach-O 64-bit executable arm64

On Linux ARM64:

    hello: ELF 64-bit LSB pie executable, ARM aarch64, ...

On Linux x86-64:

    hello: ELF 64-bit LSB pie executable, x86-64, ...

`file` reads the magic bytes at the head of the binary and identifies the format. Mach-O on Apple platforms, ELF on Linux. Both are segmented formats with a header that names the architecture and entry point.

## How big is it?

    ls -l ./hello
    size ./hello

`size` (where available) prints the in-memory size of each section:

    text	data	bss	dec	hex	filename
    20096	1024	1480	22600	5848	hello

For our hello-world binary, expect ~20 KB of code, ~1 KB of read-only data, ~1.5 KB of zero-initialised data, totalling ~22.5 KB in memory. The on-disk size is smaller because the BSS section reserves space without storing it.

## Read the header

    # macOS
    otool -h ./hello

    # Linux
    readelf -h ./hello

The header tells you the file format version, the target architecture, the entry-point symbol, and the offsets of the section table and other metadata. Two pieces are worth noting:

- The entry point is `_main` on macOS, `main` on Linux. This is where the OS hands control after loading the binary.
- The architecture matches your platform: `arm64`, `aarch64`, or `x86_64`.

## Read the section table

    # macOS
    otool -l ./hello | head -80

    # Linux
    readelf -S ./hello

You will see, among others:

| Section | Purpose | Approximate size |
|---------|---------|------------------|
| `__TEXT,__text` (Mach-O) or `.text` (ELF) | Executable code | ~20 KB |
| `__DATA,__data` or `.data` | Initialised data (Roman table, error messages) | ~1 KB |
| `__DATA,__bss` or `.bss` | Zero-initialised data (variable slots, NEXT stack, TTM positions) | ~1.5 KB |
| `__DATA_CONST,__got` (Mach-O) | Global offset table | small |

The `.bss` section is special: it has a memory size larger than its file size. The loader allocates `bss_size` bytes of zeroed memory at startup; the file does not store those zeros.

## List the symbols

    nm ./hello | sort

You will see ~100–300 symbols, in three categories:

### Runtime routines

    _rt_mingle
    _rt_select
    _rt_unary_and_16
    _rt_unary_or_16
    _rt_unary_xor_16
    _rt_write_roman
    _rt_read_out_array
    ...
    _rt_error_E000
    _rt_error_E123
    _rt_error_E275
    _rt_error_E633
    ...
    _rt_syscall_666
    _rt_sys666_open
    _rt_sys666_read
    _rt_sys666_write
    _rt_sys666_close
    _rt_sys666_argc
    _rt_sys666_argv
    _rt_sys666_exit
    _rt_sys666_getrand

These are all defined in `src/runtime/<platform>.s` and concatenated into the binary at compile time. They are present in every compiled INTERCAL program, regardless of whether that program uses them.

### Statement bodies

For hello world, 17 pairs:

    _stmt_0_start, _stmt_0_end
    _stmt_1_start, _stmt_1_end
    ...
    _stmt_16_start, _stmt_16_end

Each pair brackets the codegen output for one INTERCAL statement. NEXT instructions in the source would have produced inter-pair branches; hello world has none, so each pair runs once and falls through to the next.

### BSS data

Per-variable slots:

    _tail_1_ptr      ; 8-byte pointer set by _rt_mmap
    _tail_1_dims     ; 64-byte dimensions table

For hello world, only the array `,1` is used, so only the `_tail_1_*` symbols appear. A program with more variables would have correspondingly more BSS symbols.

Per-statement flags:

    _stmt_flags      ; one byte per statement

For hello world, this is 17 bytes. Each byte is the abstain flag for the corresponding statement. All start zeroed (active) at runtime.

### Global state

    _next_stack      ; 80×8 bytes for return addresses
    _next_sp         ; 4 bytes, current depth
    _ttm_out_pos     ; 4 bytes, output tape head
    _ttm_in_pos      ; 4 bytes, input tape head
    _argc            ; 4 bytes, saved argc
    _argv            ; 8 bytes, saved argv pointer
    _sys666_buf      ; reserved buffer for ,65535

These are present in every binary.

### Static data

    _roman_table     ; the Roman numeral output table
    _errmsg_*        ; one preformatted error message per error code

These are stored in `.data` (read-only at runtime).

## Disassemble the entry point

    # macOS
    otool -tv ./hello | head -40

    # Linux
    objdump -d ./hello | grep -A 20 '<main>:'

The disassembly of `_main` looks roughly like:

    _main:
      stp x29, x30, [sp, #-16]!
      mov x29, sp
      str w0, [_argc]              ; save argc
      str x1, [_argv]              ; save argv
      bl _stmt_0_start             ; first statement
      ; ... falls through to next ...

Each `_stmt_N_start` block follows a uniform shape:

    _stmt_N_start:
      adrp x0, _stmt_flags@PAGE
      add x0, x0, _stmt_flags@PAGEOFF
      ldrb w1, [x0, #N]
      cbnz w1, _stmt_N_end         ; abstain check
      ; ... statement body ...
    _stmt_N_end:

For statement 0 (`DO ,1 <- #14`), the body dimensions the array. For statement 16 (`DO GIVE UP`), the body issues the exit syscall.

## Trace a single instruction back to the source

Pick any address in the disassembly and trace it back:

1. Address falls inside `_stmt_N_start`–`_stmt_N_end`. → It came from the Nth statement of the input source.
2. Address falls inside `_rt_*`. → It came from the runtime, specifically the corresponding routine in `src/runtime/<platform>.s`.
3. Address falls inside `_main` before any `_stmt_*`. → It came from the codegen prologue.
4. Address falls inside `_errmsg_*` or `_roman_table`. → It is data, not code; it came from the `.data` section of the runtime.

There is a one-to-one correspondence between every byte of the binary and a place in the project source. No dependency injects unknown code.

## What the loader does at startup

When you run `./hello`:

1. The kernel loader reads the binary's header.
2. It maps `__TEXT`/`.text` into read-execute memory.
3. It maps `__DATA`/`.data` into read-write memory and copies in the on-disk contents.
4. It allocates `__DATA,__bss` / `.bss` as read-write zeroed memory.
5. It runs the C runtime startup (from `crt1.o` or equivalent), which sets up the stack, registers signal handlers, and ultimately calls `main`.
6. Our `_main` (or `main`) starts executing.

The whole sequence takes microseconds. By the time the first INTERCAL statement begins, the process already has its full memory layout, command-line arguments, and signal handlers in place.

## What the program does at exit

Eventually the program reaches `DO GIVE UP`, which translates to:

    mov x0, #0          ; exit status 0
    mov x16, #1         ; exit syscall (macOS)
    svc #0x80           ; trap to kernel

The kernel reclaims every page of mapped memory, every open file descriptor, every pending I/O. The process is gone.

If the program had instead fallen off the end without `GIVE UP`, the codegen-emitted `bl _rt_error_E633` after the last statement would print `ICL633I PROGRAM FELL OFF THE EDGE` to stderr and exit with status 1.

## Reproducible builds

Take the hello-world binary, save it, then recompile it and `diff` the two binaries. Are they identical?

On Linux, yes — by construction. The build pipeline strips the linker's per-build UUID and timestamp via `tools/rewrite_uuid.py`, so a recompilation of the same source on the same toolchain version produces a byte-identical binary. CI verifies this property on every push.

On macOS the situation is similar in spirit: most of the binary is deterministic, but the Mach-O LC_UUID load command is rewritten to a stable derived value at the same step.

If you do get a diff anyway, the usual culprits are: a stale build cache mixed with fresh output, an Xcode update that shifted the linker version (which feeds into the rewrite step), or a system-library symbol whose absolute address moved. Running the rewrite tool by hand against the diff is usually the quickest way to localise the source of nondeterminism.

## Exercises

1. Compile a slightly different program — say, change one constant in `tests/test_hello.i` — and `diff` the two binaries. Where is the change visible?
2. Use `otool -tv` (or `objdump -d`) to find where `_rt_write_roman` is called from. How many times is it called in the hello-world binary? In `tests/test_read_out_num.i`?
3. Estimate the memory footprint of a compiled INTERCAL program with 1000 statements and 100 used scalar variables. Compare to the hello-world figure.
4. Strip the binary with `strip ./hello`. How much smaller does it get? What was removed?
5. Run the binary under `dtrace` (macOS) or `strace` (Linux) and capture the syscall trace. How many syscalls does hello world make?

## Next reading

- [executables-and-linking.md](executables-and-linking.md) — the format-level theory of Mach-O and ELF.
- [runtime.md](runtime.md) — what each `_rt_*` routine does.
- [debugging.md](debugging.md) — how to use `otool` and `objdump` while chasing bugs.
