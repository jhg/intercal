# Security Audit - INTERCAL Compiler

Audit date (original pass): 2026-04-21
Initial scope: intercalc.sh, runtime_macos_arm64.s, syslib_native_macos_arm64.s

## Status / updates

- 2026-04-21 (same day, later): fixed a real SIGSEGV in
  `src/runtime/linux_x86_64.s`: `_rt_sys666_open` and `_rt_sys666_write`
  saved `alloc_size` at `[rbp - 32]` which for certain buffer lengths
  overlapped the C-string copy region. A filename of ~47 characters
  overwrote the saved size; the subsequent `add rsp, alloc_size` then
  restored rsp to a corrupted value and the function crashed on return.
  Fix: move `alloc_size` to the callee-saved `r14` register. Commit
  1d8e5b7. Verified fixed under `qemu linux/amd64` emulation and on
  the Linux x86-64 CI runner.
- The Linux ARM64 and Linux x86-64 runtimes (`src/runtime/linux_arm64.s`,
  `src/runtime/linux_x86_64.s`) and their native syslibs have NOT yet
  been given a line-by-line equivalent of the macOS audit below. They
  are known to pass all 53 functional tests on every platform. A full
  per-platform audit is on the roadmap.
- `tools/lint_assembly.sh` (added 2026-04-21) flags platform-specific
  mistakes (svc number, relocation syntax, comment syntax, three-register
  addressing). Runs in CI before tests, serves as a regression guard.

## Reporting

For suspected vulnerabilities or questions, open a GitHub issue with
the "security" label, or contact the maintainer through the address
listed in the repository metadata. Please include a minimal reproducing
`.i` program if one applies.

## Security Model

This compiler produces native executables from INTERCAL source. The security boundary is:

- Trusted: the compiler itself (intercalc.sh) running on the developer machine
- Untrusted: INTERCAL source programs (.i files) provided as input
- No sandboxing: compiled executables run with full user privileges
- Label 666 syscalls: provide unrestricted file system and process access to compiled programs

What is NOT protected:
- File system access (Label 666 open/read/write have no restrictions)
- Path traversal (no validation of filenames)
- Resource consumption (no memory or CPU limits)

What IS protected:
- The compiler shell script does not execute arbitrary code from .i files at compile time
- NEXT stack overflow is detected (limit 79)
- Array bounds are checked on element access
- 16-bit overflow on assignment is detected (E275)

## Findings

### 1. Buffer Overflows in Runtime

#### 1.1 _rt_write_in_scalar: Stack buffer bounds (MEDIUM)

Location: runtime_macos_arm64.s lines 232-342

The function allocates 272 bytes on the stack (256 usable + alignment) and reads from stdin one byte at a time into positions 0..254 (the loop checks `cmp w20, #255` and branches on `b.lt`). The maximum bytes stored is 255 (indices 0-254), plus a null terminator at position 255, totaling 256 bytes within the 272-byte allocation.

Verdict: Safe. The buffer cannot overflow. The comparison `cmp w20, #255; b.lt .Lwi_read` stops reading at index 254, null-terminator goes at index 255 max.

#### 1.2 _rt_syscall_666 open: Filename copy from array to stack (LOW)

Location: runtime_macos_arm64.s lines 575-632

The filename length comes from `_tail_65535_dims` (the dimension of array ,65535). The stack allocation is computed as `add w3, w2, #16; and w3, w3, #-16; sub sp, sp, x3`. This correctly allocates enough space for the filename plus null terminator. However:

Issue: No maximum length check. A program could set ,65535 to a very large array (e.g., 65535 elements) and the stack would grow by that amount. On macOS, the default stack size is 8MB; a 65535-byte allocation is safe, but repeated nested calls could exhaust the stack.

Suggested fix: Cap filename length (e.g., to 4096 bytes, PATH_MAX) and error if exceeded.

#### 1.3 _rt_read_out_array: TTM tape position (NONE)

Location: runtime_macos_arm64.s lines 136-179

The TTM output position (`w23`) is always masked with `and w23, w23, #0xFF` (line 159), constraining it to 0-255. The `rbit w0, w0; lsr w0, w0, #24` bit-reversal produces an 8-bit value. Output is one byte at a time to fd 1. No overflow possible.

Verdict: Safe.

#### 1.4 _rt_select/_rt_mingle: Edge cases (NONE)

- `_rt_mingle`: Loops 16 iterations exactly. With inputs 0 and 0, produces 0. With inputs 0xFFFF and 0xFFFF, produces 0xFFFFFFFF. Both correct.
- `_rt_select`: Loop bounded by `w2` (bit width: 16 or 32). With mask 0, result is 0 (loop body never triggers). With all-ones mask, all bits are extracted. Correct.

Verdict: Safe.

### 2. Stack Safety

#### 2.1 _main stack frame (LOW)

Location: intercalc.sh codegen_program(), line 769

Generated code:
```
_main:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
```

The frame pointer and link register are saved. However, the compiler never emits a corresponding `ldp x29, x30, [sp], #16` because programs must end with `GIVE UP` (which calls `exit` via `svc #0x80`) or fall through to `_rt_error_E633` (which also exits). If RESUME somehow returns to a point that tries to fall off main, there is no epilogue.

Verdict: Acceptable. All exit paths terminate the process, so the missing epilogue is harmless.

#### 2.2 stp/ldp balance in runtime (NONE in normal paths, LOW in error paths)

All runtime functions that save registers restore them before returning:
- `_rt_write_roman`: saves x19/x20/x29/x30, restores correctly
- `_rt_read_out_array`: saves 4 pairs, restores 4 pairs (correct)
- `_rt_write_in_array`: saves 5 pairs, restores 5 pairs (correct, but error path at .Lttm_in_eof calls `add sp, sp, #16` then branches to `_rt_error_E562` which exits the process)
- `_rt_write_in_scalar`: saves 3 pairs + sub sp 272, restores correctly in all three exit paths (normal, bad token, eof)

Issue: Error handlers (`_rt_error_E*`) all terminate the process, so unbalanced stack on error paths is acceptable.

Verdict: Safe.

#### 2.3 Stack alignment (LOW)

ARM64 requires 16-byte stack alignment. All stack operations in the runtime use multiples of 16:
- `sub sp, sp, #272` (272 = 17*16, aligned)
- `sub sp, sp, #16` (aligned)
- Dynamic allocations in syscall 666 use `and w3, w3, #-16` to round up

In generated code, the compiler pushes values as `str w0, [sp, #-16]!` (16-byte aligned push).

Verdict: Safe. Alignment is maintained.

### 3. Integer Overflow

#### 3.1 E275 overflow check (CORRECT)

Location: intercalc.sh codegen_assign(), lines 1070-1072

Generated code compares `w0` to 65535 and branches to `_rt_error_E275` if higher. Since w0 holds a 32-bit unsigned result, this correctly detects values that do not fit in 16 bits.

Verdict: Correct.

#### 3.2 mmap failure check (MEDIUM)

Location: runtime_macos_arm64.s lines 344-355

```
_rt_mmap:
  ...
  svc #0x80
  cmn x0, #1
  b.eq _rt_error_E000
  ret
```

The mmap call checks if the return value is -1 (MAP_FAILED on macOS arm64, where errors return the negated errno via carry flag is NOT how macOS mmap works). On macOS, mmap returns MAP_FAILED (which is -1 cast to void*) on error.

Issue: macOS syscalls set the carry flag on error and return the errno in x0 (positive). The `cmn x0, #1` check (testing if x0 == -1) may not correctly detect mmap failure on macOS. The correct check should be `b.cs _rt_error_E000` (branch if carry set), consistent with how `_rt_sys666_open` checks for errors (line 621: `b.cs .Lopen_err`).

Suggested fix: Replace `cmn x0, #1; b.eq _rt_error_E000` with `b.cs _rt_error_E000` to use the carry flag, consistent with macOS syscall conventions.

#### 3.3 Array bounds checks (CORRECT for reads, CORRECT for writes)

The 1D array bounds check uses `cmp w0, w2; b.hs _rt_error_E241` where w0 is the 0-based index and w2 is the dimension. The unsigned comparison `b.hs` (branch if higher or same) correctly catches both out-of-bounds (index >= size) and negative wraparound (large unsigned values).

For multi-dimensional arrays, the bounds check on the total linear index is NOT performed in the generated code -- only individual dimension checks are absent. The linear index computation does not verify that each subscript is within its dimension.

Issue: Multi-dimensional array access does not bounds-check individual subscripts against their respective dimensions. Only the 1D fast path has a bounds check. A malicious program could compute a valid linear index from invalid subscripts.

Suggested fix: Add per-dimension bounds checking for multi-dimensional arrays.

### 4. Memory Safety

#### 4.1 Stash stack overflow (HIGH)

Location: intercalc.sh codegen_stash_var(), lines 1549-1575; runtime _rt_mmap

Each variable's stash is allocated 4096 bytes via mmap. Each stash entry is 4 bytes (one `str w5, [x1, x3, lsl #2]`). This allows 1024 stash operations per variable before writing past the allocated region.

Issue: There is NO bounds check on the stash stack pointer (`_stash_sp`). A program that STASHes a variable more than 1024 times without RETRIEVE will write beyond the 4096-byte mmap region. This is a heap buffer overflow that could corrupt adjacent memory or cause a segfault (if the next page is unmapped).

Suggested fix: Add a bounds check before the stash store operation. Either:
- Check `cmp w3, #1023; b.hi _rt_error_E000` before the store
- Or allocate a larger stash (e.g., 64K) and add a check
- Or implement dynamic reallocation when the stash is full

#### 4.2 Array writes without total bounds check on multi-dim (LOW)

As noted in 3.3, multi-dimensional array element writes compute a linear index but do not verify each subscript against its dimension. This could allow writing to any offset within the allocated array memory, but not beyond it (assuming the subscripts produce a value that happens to be within total size). Since the total allocation is the product of all dimensions, any combination of valid-looking subscripts could address any element.

Verdict: This is a correctness issue more than a security issue. The array memory is allocated correctly for the total size; only out-of-range linear indices would cause a problem, but those would require subscript values that produce a total index beyond total_elements, which IS possible.

Suggested fix: Add per-dimension bounds checking.

#### 4.3 close() with invalid fd (NONE)

Location: runtime_macos_arm64.s lines 752-758

The close syscall handler reads .2 and calls close(fd). If fd is invalid, macOS returns an error (EBADF) via carry flag, but the result is ignored. This is standard behavior -- closing an invalid fd is not a security issue; the kernel handles it safely.

Verdict: Not a security concern.

### 5. Label 666 Security

#### 5.1 Unrestricted file access (HIGH - by design)

The Label 666 open syscall (syscall number 1) allows opening ANY file path that the process has OS-level permission to access. There is:
- No path validation
- No path traversal protection
- No allowlist/denylist
- No chroot or sandbox

A malicious INTERCAL program can:
- Read /etc/passwd, SSH keys, or any user-readable file
- Overwrite any user-writable file (mode=1 uses O_WRONLY|O_CREAT|O_TRUNC)
- Create files anywhere the user has write access

This is the same security model as any compiled native program (C, Rust, etc.). The compiled INTERCAL executable runs with full user privileges.

Suggested mitigations (optional, for future consideration):
- Add a `--sandbox` flag that restricts Label 666 to specific directories
- Use pledge/unveil on OpenBSD or sandbox_init on macOS
- Document that compiled INTERCAL programs are native executables with full OS access

#### 5.2 No path traversal protection (HIGH - by design)

Filenames are taken directly from the ,65535 array contents. Path components like `../`, absolute paths like `/etc/shadow`, and symbolic links are all passed through to the kernel without sanitization.

Verdict: Expected for a native compiler. Same as C compiler output.

#### 5.3 write can overwrite critical files (HIGH - by design)

The write syscall (number 3) writes to any open file descriptor. Combined with open (mode=1, O_WRONLY|O_CREAT|O_TRUNC), a program can overwrite critical user files.

Verdict: Expected for native executables. Same security model as any compiler.

#### 5.4 ,65535 buffer validation (MEDIUM)

In each syscall handler, the ,65535 array is accessed via `_tail_65535_ptr`:

- open (syscall 1): Checks for null pointer (`cbz x1, .Lopen_err`). Uses `_tail_65535_dims` as length. Safe within the allocated array.
- read (syscall 2): Does not validate ,65535 before overwriting it (it allocates a new array via mmap). Safe.
- write (syscall 3): Checks for null pointer (`cbz x1, .Lwrite_zero`). Uses .3 as byte count, not the array dimension.

Issue in write: The byte count (.3) is taken from the caller, not from the actual array dimension. If .3 exceeds the allocated size of ,65535, the copy loop will read beyond the array's allocated memory.

```
.Lwrite_copy:
  cmp w3, w20         // w20 = .3 (caller-supplied count)
  b.ge .Lwrite_do
  ldrh w4, [x1, x3, lsl #1]  // reads from array
```

If .3 > actual array size, this reads past the allocated buffer.

Suggested fix: Clamp .3 to min(.3, array_dimension) before the copy loop:
```
ldr w_dim, [_tail_65535_dims]
cmp w20, w_dim
csel w20, w_dim, w20, hi
```

### 6. Compiler (intercalc.sh) Security

#### 6.1 Tokenizer handling of malformed input (SAFE)

The tokenizer uses zsh pattern matching and string operations. Unrecognized statements are classified as `UNKNOWN` and generate `b _rt_error_E000` (runtime error). The parser does not crash or behave unexpectedly on malformed input -- it simply fails to classify statements.

Verdict: Safe. Malformed input produces either a compile-time error or a runtime error in the generated binary.

#### 6.2 Shell injection through assembly generation (SAFE)

The critical question: can a malicious .i file inject arbitrary assembly?

The assembly is generated via the `emit()` function which appends to the `$asm` string variable. The content passed to emit comes from:
1. Fixed strings (code templates)
2. Variable numbers extracted from the source (`.1`, `:2`, etc.)
3. Label numbers
4. Computed offsets

Variable and label numbers are extracted via regex patterns like `'^\.[0-9]+$'` or `'^\(([0-9]+)\)$'`, which only match pure digit sequences. These are then interpolated into assembly symbol names like `_spot_${vnum}`.

Issue: The regex `'^\.[0-9]+$'` ensures only digits follow the prefix. However, array number extraction in `codegen_array_elem_assign()` (line 1101) does:
```
local arr_part="${rest%% SUB*}"
arr_part="${arr_part%% *}"
```

This could theoretically contain non-digit characters if the parser fails earlier. However, `scan_variables()` already validated the format, and `classify_statement()` only marks it as ARRAY_DIM if the target matches `'^[,;][0-9]+$'`.

Verdict: Safe. All interpolated values in assembly output are either fixed strings, validated numeric values, or computed numeric expressions. No user-controlled string data flows unvalidated into assembly.

#### 6.3 eval() and command substitution risks (SAFE)

The script does NOT use `eval` anywhere. Command substitution is used in:
- `raw=$(cat)` -- reads stdin (the .i source file), assigns to variable
- `syslib_source=$(cat "$SCRIPT_DIR/syslib.i" ...)` -- reads a known file
- `TMPBIN=$(mktemp ...)` -- creates temp file

None of these execute user-controlled data as commands. The final assembly step:
```
cat "${runtime_files[@]}" <(print -r -- "$asm") | cc -x assembler - -o "$TMPBIN"
```

The `$asm` variable is passed via `print -r` (raw mode, no escape interpretation) through a pipe to `cc -x assembler -` which reads it as assembly source. Since $asm only contains validated assembly text (no shell metacharacters are dangerous in this pipeline), this is safe.

Verdict: Safe. No code injection vectors.

#### 6.4 Temporary file handling (LOW)

```
TMPBIN=$(mktemp /tmp/intercalc.XXXXXX)
trap "rm -f $TMPBIN" EXIT
```

The trap is set with the filename expanded at definition time (`$TMPBIN` is expanded immediately). This is correct. The mktemp creates a unique file safely. However:

Minor issue: The temporary file is created in /tmp with default permissions (likely 0600 from mktemp). Between creation and writing the binary, another process could potentially observe it. This is a minimal TOCTOU window and not practically exploitable.

Verdict: Acceptable.

## Known Limitations

1. Stash stacks can overflow (4096 bytes = 1024 entries max with no bounds check)
2. mmap failure detection uses wrong convention (should check carry flag)
3. Label 666 provides unrestricted OS access (by design)
4. Write syscall does not validate byte count against array dimension
5. Multi-dimensional array subscripts not individually bounds-checked
6. No resource limits on compiled programs (memory, CPU, file descriptors)
7. Compiled programs inherit full user privileges with no sandboxing

## Risk Summary

| Issue | Severity | Exploitable | Fix Effort |
|-------|----------|-------------|------------|
| Stash overflow (4.1) | High | Yes - heap corruption | Low |
| mmap error check (3.2) | Medium | Yes - null deref on OOM | Low |
| Write syscall count (5.4) | Medium | Yes - info leak | Low |
| Open filename length (1.2) | Low | Unlikely - stack growth | Low |
| Multi-dim bounds (3.3/4.2) | Low | Yes - array oob | Medium |
| Label 666 unrestricted (5.1-5.3) | High (design) | N/A | High |

## Recommendations

Priority 1 (should fix):
- Add stash stack bounds check (compare stash_sp against 1023 before store)
- Fix mmap error detection to use carry flag (`b.cs`) instead of `cmn x0, #1`
- Clamp write syscall byte count to min(requested, array_dimension)

Priority 2 (should consider):
- Add per-dimension bounds checking for multi-dimensional array access
- Cap filename length in open syscall to PATH_MAX (4096)

Priority 3 (long-term):
- Consider optional sandboxing for compiled programs
- Document that compiled INTERCAL programs are native executables with full OS access (same as C compiler output)
