# Label 666: a gentle introduction

INTERCAL has no file I/O, no command-line arguments, no way to ask the operating system for the time of day or a random number. The 1972 spec was complete without these. Programs read from stdin, wrote to stdout, and that was that.

Five decades later this is constraining. A compiler written in INTERCAL needs to open a source file by name, not hope the user piped it in. A self-hosted compiler needs to know its own argv to print usage messages. A serious program needs a reliable random number. The 1972 specification offers none of this.

This compiler's answer is *Label 666*. The chapter explains what it is, why we need it, and how to use it. It is the friendly version; the deep design rationale is in [666.md](666.md).

## Why a built-in extension at all

Most languages cope with the lack of OS access by providing a way out: an FFI to call C, an inline-assembly form, a way to link against compiled object files, a foreign-function declaration. INTERCAL offers none of that.

It has no inline-assembly construct. There is no equivalent of C's `asm("...")` or Rust's `asm!`, no syntactic place to drop a few raw target instructions into your INTERCAL program. The grammar simply does not have a slot for it.

It has no foreign-function-interface declaration. C lets you `extern int foo(int);` and link against any object file that supplies `foo`. Rust has `extern "C" fn foo(x: i32) -> i32;`. Python has `ctypes`. INTERCAL has no syntax for any of this. There is no way for a programmer to declare "here is a routine I will provide separately".

It has no linker awareness. The 1972 spec assumes the program is a self-contained INTERCAL source file. There is no `#include`, no module import, no way for an INTERCAL program to reference symbols from a separately compiled translation unit. A compiler can choose to link the user's INTERCAL with handwritten assembly (as ours does for the runtime), but the programmer cannot ask for it.

It has no shared-library mechanism. There is no `dlopen` analogue, no concept of a runtime-loaded plugin, nothing like a JVM class loader.

In short, every conventional escape hatch a programmer reaches for to extend their language with native code is absent from INTERCAL. The only way through the wall is a feature that lives inside the language itself. Label 666 is that feature.

## The problem, concretely

Suppose an INTERCAL program wants to open a file. In standard INTERCAL:

- Filenames are strings. INTERCAL has no string type.
- File operations (open, read, write, close) are operating-system calls. INTERCAL has no syscall mechanism.
- Command-line arguments live in `argv[]`. INTERCAL has no reference to `argv`.

So the direct answer is: it cannot. A standard INTERCAL program has no means to open a file at all.

## The solution: a syscall extension

Label 666 is an extension that adds a tiny amount of operating-system access to INTERCAL, just enough for useful programs. The central idea:

1. The runtime reserves the label `666` as a special target.
2. When a program executes `DO (666) NEXT`, the runtime does not jump to user code. It reads a few predetermined variables (`.1`, `.2`, `.3`, `.4`, and the array `,65535`), performs the corresponding syscall, and returns.
3. The user program reads the results from the same variables.

So instead of "jump to label 666", the programmer thinks "invoke a syscall based on what I put in `.1`".

## The syscall numbers

Eight syscalls today. Each is identified by the number you put in `.1` before executing `DO (666) NEXT`:

| `.1` | Syscall | What it does |
|------|---------|--------------|
| 1 | open | Opens a file. Filename is in `,65535`. Result: file descriptor in `.3`. |
| 2 | read | Reads from a file descriptor into `,65535`. Result: byte count in `.4`. |
| 3 | write | Writes from `,65535` to a file descriptor. Result: byte count in `.4`. |
| 4 | close | Closes a file descriptor. |
| 5 | argc | Returns the number of command-line arguments in `.3`. |
| 6 | argv | Reads the Nth argument into `,65535` and its length into `.3`. |
| 8 | exit | Exits the program with the given status code. |
| 9 | getrand | Returns a random number in `.3`. |

Parameters and results live in pre-agreed variables:

- `.1` is the syscall number (input).
- `.2` is the primary parameter (file descriptor, arg index, exit code, random-range limit).
- `.3` is the primary result (new file descriptor, byte count, arg count, random number).
- `.4` is the secondary result (bytes actually read or written).
- `,65535` is the data buffer for file contents, argument strings, filenames. Reserved exclusively for Label 666.

## A short worked example

A program that reads its first command-line argument and prints the length:

    DO ,65535 <- #65535

    PLEASE DO .1 <- #6
    PLEASE DO .2 <- #1
    DO (666) NEXT
    PLEASE DO .10 <- .3

    DO READ OUT .10
    DO GIVE UP

Line by line:

- `DO ,65535 <- #65535` dimensions the data buffer once at program entry.
- `PLEASE DO .1 <- #6` sets the syscall number to 6 (argv).
- `PLEASE DO .2 <- #1` sets the primary parameter to 1 (the first argument, 0-indexed).
- `DO (666) NEXT` invokes the syscall. The runtime reads the argument into `,65535` and stores its length in `.3`.
- `PLEASE DO .10 <- .3` saves the length somewhere we control.
- `DO READ OUT .10` prints the length in Roman numerals.
- `DO GIVE UP` exits.

Compile this and run as `./program foo`: it prints `III` (length 3). Run as `./program hello`: it prints `V` (length 5).

## The reserved `,65535` array

One of Label 666's design decisions is to reserve a specific array for syscall data. Every syscall that needs a buffer (filenames for `open`, contents for `read`, arguments for `argv`) uses `,65535`. The choice of 65535 is deliberate. It is the largest 16-bit array index, far from any number a real program would naturally use.

The runtime auto-dimensions `,65535` on the first use if you do not. By convention, programs in this project dimension it explicitly at entry:

    DO ,65535 <- #65535

That reserves 65535 bytes of buffer. Programs that use Label 666 must not use `,65535` for any other purpose.

## Why not just extend INTERCAL with proper syscalls?

Three alternatives were considered and rejected:

- **Add new statements to the language.** Something like `DO OPEN FILE "foo.txt"` would be the obvious route, but it would break every other INTERCAL compiler, and the extension would need string syntax, which INTERCAL does not have natively.
- **Use CLC-INTERCAL's "call by vague resemblance" convention.** CLC-INTERCAL already has a Label 666 syscall system, but its parameter-passing convention is deliberately obscure: parameters live in whichever register was last assigned to. This is interesting as a curiosity but impractical to use.
- **Invent a wholly new mechanism.** We could have used Label 999, or Label 1, or a new statement like `DO SYSCALL`. Choosing 666 keeps enough cultural memory of CLC-INTERCAL that the construct is recognisable, while our simpler calling convention (fixed `.1` through `.4`) is documented and reproducible.

The current Label 666 design is intentionally simple, intentionally incompatible with CLC-INTERCAL, and intentionally documented end to end. It is "our extension, like CLC-INTERCAL's but clearer".

## Why we need Label 666 at all

Because our compiler is INTERCAL.

The self-hosted compiler in `src/compiler/compiler.i` needs to:

1. Read its arguments to find the source file. Syscalls 5 and 6 (argc / argv).
2. Open the source file. Syscall 1.
3. Read the source into memory. Syscall 2.
4. Close the source. Syscall 4.
5. Write the generated assembly to stdout. Syscall 3.
6. Exit with the right status. Syscall 8.

Without Label 666, none of this is possible. The language has no way to reach the operating system, and a compiler that cannot reach the operating system is useless. Label 666 is the minimum viable extension that makes self-hosting possible.

## What Label 666 is not

- Not a feature of every INTERCAL program. A program that uses only standard INTERCAL (READ OUT, WRITE IN, arithmetic) does not touch Label 666 and remains compatible with any implementation.
- Not CLC-INTERCAL compatible. A program written against this compiler's Label 666 will not work under CLC-INTERCAL and vice versa, because the parameter conventions differ.
- Not a general-purpose FFI. It exposes exactly eight syscalls, carefully chosen. Adding more is possible but not done lightly.

## Reading it in the actual source

Every Label 666 syscall is dispatched by `_rt_syscall_666` in the runtime:

    src/runtime/<platform>.s

Search for `_rt_syscall_666` and you will find the dispatcher, followed by the eight handlers (`_rt_sys666_open`, `_rt_sys666_read`, etc.). Each handler is around 40 lines of platform-specific assembly.

On the INTERCAL side, the minimal usage is what you saw above: set `.1` (and `.2`, `,65535` as appropriate), execute `DO (666) NEXT`, read the result from `.3` and `.4`.

## Exercises

1. Write a program that counts its command-line arguments and prints the count. (Hint: syscall 5.)
2. Write a program that reads the first 10 bytes of `tests/test_hello.i` and prints them as Roman numerals, one per line. (Hint: syscalls 1, 2, 4, and a loop over the bytes.)
3. Why does `,65535` need to be reserved? What happens if a program touches `,65535` between Label 666 calls?
4. Syscall 9 (getrand) takes a range limit in `.2`. What does `.2 = 0` produce? Consult `docs/runtime.md` and the runtime source to find out.
5. The self-hosted compiler in `src/compiler/compiler.i` uses Label 666. Read it (43 lines) and identify which syscalls it uses, and in what order.

## Next reading

- [666.md](666.md): the full design rationale, CLC-INTERCAL analysis, and implementation choices.
- [runtime.md](runtime.md): the dispatcher and handler code in the runtime.
- [self-hosting.md](self-hosting.md): why Label 666 is critical to the self-hosting story.
