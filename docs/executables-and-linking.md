# Executables and linking

When we say "the compiler produces a binary", the sequence of events behind that claim is: generate assembly text; feed it to an assembler; the assembler produces relocatable object code; a linker resolves symbols and arranges the object into an executable file in the format the operating system's loader understands. Our compiler does not perform these last steps itself — it shells out to `cc -x assembler -`, which invokes the system assembler and linker as a pipeline.

This chapter explains what that pipeline produces, what the resulting file looks like, and what it means for a program to be linked against our runtime.

## Executable file formats

Every operating system defines its own executable format. The format encodes how the program's code and data are laid out on disk, where the loader should place them in memory, what symbols the program exports, which dynamic libraries the loader should resolve before jumping to the entry point, and a small amount of metadata about the target architecture.

We encounter two formats in this project:

- **Mach-O**, on macOS (and on Darwin-based platforms generally). The name stands for "Mach Object", after the Mach kernel. Every binary `intercalc.sh` produces on macOS is a Mach-O file.
- **ELF**, the Executable and Linkable Format, on Linux (and on most other Unix-like systems). Every binary produced on Linux is an ELF file.

We do not produce PE/COFF (Windows) or XCOFF (IBM AIX) binaries today. Windows support is on the roadmap.

Both Mach-O and ELF are segmented formats. A binary is partitioned into named sections, each holding a category of content: `.text` for executable code, `.data` for initialised data, `.bss` for zero-initialised data, and several metadata sections that the loader consults but the program cannot introspect.

## The three sections our binaries use

Every binary we produce has the same three sections, regardless of platform:

### `.text`

Executable machine code. This is where every `_main`, `_rt_*`, and `_stmt_N_*` symbol lives. The loader maps this section into read-and-execute-only memory and jumps to the entry point after setup.

The size of `.text` is proportional to the source program's statement count plus the size of the runtime. A small program like `tests/test_hello.i` produces a `.text` of roughly 20 KB; most of that is the runtime, about 1 KB is the statement bodies.

### `.data`

Initialised data. This is where string constants (such as the 16 preformatted `_errmsg_*` messages) and the Roman-numeral table live. The loader maps this section read-write, copying its on-disk contents into memory at program startup.

Our `.data` is small. The error messages are the bulk; they total roughly 1 KB across all 16 codes.

### `.bss`

Block Started by Symbol: zero-initialised data. The critical property of `.bss` is that it takes no on-disk space — the file only records how many bytes of zeroed memory the loader should allocate. For a program with 1000 statements and 100 used variables, `.bss` might be 5 KB in memory but cost only a few dozen bytes of metadata on disk.

Every one of our per-statement `_stmt_flags` bytes and per-variable slot lives in `.bss`. The NEXT stack (80 × 8 = 640 bytes), the stash stacks, the TTM tape positions, the reserved `,65535` buffer — all of them are `.bss`. This is why the compiled binaries are small despite the runtime reserving many kilobytes of working memory.

See [runtime.md](runtime.md) for the full BSS layout and the reason each symbol exists.

## What the assembler does

`cc -x assembler -` is a shell-invocation pattern that tells the system's C compiler driver to interpret the piped input as assembly and produce an executable.

Inside `cc`, the pipeline is roughly:

1. Parse the assembly text.
2. Emit a relocatable object file (a `.o` file on disk, or an in-memory equivalent).
3. Invoke the linker, passing the object file and any implicit libraries (`libc`, the C runtime startup `crt1.o`, etc.).
4. The linker combines the objects and produces the final executable.

For our purposes, steps 2 and 3 are the interesting ones.

### The assembler

The assembler's job is to turn human-readable assembly into machine code. For every line of assembly, the assembler produces the corresponding machine instruction bytes. For labels and symbols, it produces a table of references and definitions that the linker will later resolve.

A relocatable object file has three logical parts:

- The raw instruction bytes and data bytes, one per section.
- A symbol table: every label defined in the file, with its section and offset.
- A relocation table: every place where a label is referenced, with instructions for how to patch that reference once the label's final address is known.

Our generated assembly contains hundreds of symbol references. Every `bl _rt_mingle` generates a relocation entry saying "at offset N in .text, patch a 26-bit branch displacement to the address of `_rt_mingle`". The linker later walks this table and fills in the actual displacements.

### The linker

The linker's job is symbol resolution. It reads every object file, builds a global symbol table, checks that every referenced symbol is defined exactly once somewhere, and writes out the final executable with all relocations applied.

For a compiled INTERCAL program, the linker has to resolve references between:

- The program's `_stmt_N_*` symbols (internal to the input).
- The `_rt_*` and `_sys666_*` symbols (defined in the runtime assembly that was prepended to the program).
- Standard entry-point symbols (`_main` on macOS, `main` on Linux) and C runtime startup symbols that `crt1.o` provides.

Symbol resolution fails if any referenced symbol is missing (undefined symbol error) or if any symbol is defined more than once (duplicate symbol error). Both are the kinds of errors that an incorrect `sed` pipeline step, or a renamed runtime routine, can trigger.

## Why `cc -x assembler -` instead of writing our own linker

Writing a linker is hard. Mach-O and ELF both have intricate relocation models, symbol visibility rules, and loader-interaction contracts. A usable linker for even one of the two formats is a substantial project.

Writing an assembler is also hard, but less so, and projects like `sheerass` and Rust's bundled LLD show that it is feasible at small scale.

We punt on both by invoking `cc`. The system C compiler driver handles assembly and linking through well-tested pipelines (`as` plus `ld` on most Unix-likes). Our only contribution is the assembly source; the driver and linker handle everything after that.

The cost of this choice is a dependency: we need a working `cc` on every machine that compiles INTERCAL programs. In practice this is rarely an issue — every platform we target ships with `gcc` or `clang`. The `.deb` and `.rpm` release artifacts declare `gcc` as a runtime dependency, so installers can rely on it being present.

## Static vs dynamic linking

A program can be statically linked (every library's code is copied into the final binary) or dynamically linked (libraries are loaded from disk at program startup). Our compiled programs are mostly statically linked: the runtime assembly is concatenated with the program assembly before `cc` sees them, so there is no "runtime library" the loader has to find at startup.

But the programs are not fully static: they depend on the host's C runtime (`libSystem.dylib` on macOS, `libc.so.6` on Linux) for the actual system calls. Our runtime issues syscalls directly in most cases (`svc #0x80`, `svc #0`, `syscall`), so the dependency is small — typically only the C startup file `crt1.o` that arranges `main` to be called with `argc` and `argv`.

A truly static build (no C runtime dependency) would require writing our own `_start` routine and convincing the linker not to pull in `libc`. We have not needed this. The C runtime dependency is small enough that it does not affect portability meaningfully.

## How a compiled binary starts up

The execution path from `./program` on the command line to the first INTERCAL statement running:

1. The kernel loads the ELF or Mach-O file, mapping each section into memory according to its flags.
2. Control transfers to the ELF/Mach-O entry point, typically inside `crt1.o` or the equivalent `dyld` bootstrap on macOS.
3. The startup code initialises the C runtime's internal state and calls `main` with `argc` and `argv` set correctly.
4. Our `_main` (or `main`) saves `argc` and `argv` for later Label 666 access, initialises `_stmt_flags` (copying the compile-time negation bits), and falls through into the first statement.
5. The first statement's abstain check runs, then its body, then fallthrough to the next statement.
6. Execution ends at `GIVE UP` (which calls `exit(0)`) or falls off the end (which calls `_rt_error_E633`, printing ICL633I and exiting with status 1).

The exit syscall is what terminates the process. The kernel reclaims every allocated page, every open file descriptor, every runtime-allocated array, on behalf of the dying process. This is why our runtime never bothers to `munmap` anything: process exit is the garbage collector.

## Inspecting a produced binary

Several tools come with the platform's developer toolchain and are useful for understanding what we actually produced:

- `file ./program` — prints the file format and architecture.
- `otool -h ./program` (macOS) or `readelf -h ./program` (Linux) — prints the header, showing the target architecture and entry point.
- `otool -l ./program` or `readelf -S ./program` — prints the section table.
- `nm ./program` — lists the symbols. Our binaries typically have 100–300 symbols: one per `_rt_*` routine, one per `_stmt_N_start`/`_end`, one per used variable's BSS slot.
- `otool -tv ./program` or `objdump -d ./program` — disassembles the `.text` section.

These tools are what you reach for when a binary misbehaves and the source-level story does not account for it. See [debugging.md](debugging.md).

## Exercises

1. Run `file ./program` on a hello-world binary built on your platform. Identify the ELF or Mach-O header and the machine architecture.
2. Run `nm ./program` on the same binary. How many `_rt_*` symbols are listed? How many `_stmt_N_*` symbols?
3. Estimate the disk size of a compiled hello-world binary by reading the section table (`readelf -S` or `otool -l`). Compare to the actual on-disk size. What accounts for the difference?
4. What happens if we deliberately remove `bl _rt_error_E633` from the end of the generated assembly, and then run a program that falls off the end? Try it by editing the emitted `.s` and re-assembling.
5. The Linux ARM64 sed pipeline rewrites `.section __TEXT,__text` to `.text`. What is the implicit default section for a `.text` line, and would a program that never emits the directive still work?

## Next reading

- [calling-conventions.md](calling-conventions.md) — the per-architecture rules that the assembler and linker assume.
- [platforms.md](platforms.md) — the table of per-platform syntactic and syscall differences that show up in the emitted assembly.
- [runtime.md](runtime.md) — the `.bss` layout that this chapter describes at the file-format level.
