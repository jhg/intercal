# Label 666: a gentle introduction

INTERCAL has no file I/O, no access to command-line arguments, no way to ask the operating system for the time of day or a random number. The language as specified in 1972 was complete without these features — every program read from stdin and wrote to stdout, and that was that.

Fifty years later this is constraining. A compiler written in INTERCAL needs to open a source file by name, not hope that the user remembered to pipe it in. A self-hosted compiler needs to know its own name to print usage messages. A serious program needs a reliable random number. The 1972 specification offers none of this.

The solution in this compiler is a feature called *Label 666*. This chapter explains what it is, why we needed it, and how to use it. It is the friendly version; the deep design rationale is in [666.md](666.md).

## The problem, concretely

Consider the INTERCAL program that wants to open a file. In standard INTERCAL:

- Filenames are strings. INTERCAL has no string type.
- File operations (open, read, write, close) are operating-system calls. INTERCAL has no syscall mechanism.
- Command-line arguments arrive in `argv[]`. INTERCAL has no reference to `argv`.

So the direct answer is: it can't. A standard INTERCAL program cannot open a file. Period.

## The solution: a syscall extension

Label 666 is an extension that adds a tiny amount of operating-system access to INTERCAL, just enough to make useful programs possible. Here is the central idea:

1. The runtime reserves the label `666` as a special target.
2. When a program executes `DO (666) NEXT`, the runtime does not jump to user code. Instead, it reads a few predetermined variables (`.1`, `.2`, `.3`, `.4`, and the array `,65535`), performs the corresponding syscall, and returns.
3. The user program reads the results from the same variables.

So instead of "jump to label 666", the programmer sees "invoke a syscall based on what I put in `.1`".

## The syscall numbers

Eight syscalls are currently supported. Each is identified by the number you put in `.1` before executing `DO (666) NEXT`:

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

The parameters and results live in pre-agreed variables:

- `.1` = syscall number (input).
- `.2` = primary parameter (file descriptor, arg index, exit code, random-range limit).
- `.3` = primary result (new file descriptor, byte count, arg count, random number).
- `.4` = secondary result (bytes actually read / written).
- `,65535` = data buffer for file contents, argument strings, filenames. Reserved exclusively for Label 666.

## A short worked example

Here is a program that reads the first command-line argument and prints it as a byte count:

    DO ,65535 <- #65535

    PLEASE DO .1 <- #6
    PLEASE DO .2 <- #1
    DO (666) NEXT
    PLEASE DO .10 <- .3

    DO READ OUT .10
    DO GIVE UP

Line by line:

- `DO ,65535 <- #65535` — dimension the data buffer `,65535` to the maximum size. You do this exactly once at program entry.
- `PLEASE DO .1 <- #6` — set the syscall number to 6 (argv).
- `PLEASE DO .2 <- #1` — set the primary parameter to 1 (the first argument, 0-indexed).
- `DO (666) NEXT` — invoke the syscall. The runtime reads the argument into `,65535` and stores its length in `.3`.
- `PLEASE DO .10 <- .3` — save the length so we don't lose it.
- `DO READ OUT .10` — print the length in Roman numerals.
- `DO GIVE UP` — exit.

If you compile this program and run it as `./program foo`, it prints `III` (3, the length of "foo"). If you run it as `./program hello`, it prints `V` (5).

## The reserved `,65535` array

One of Label 666's design decisions is to reserve a specific array — `,65535` — for syscall data. Every syscall that needs a buffer (filenames for `open`, contents for `read`, arguments for `argv`) uses this array. The choice of 65535 is deliberate: it is the largest 16-bit array index, far from any number a realistic program would use naturally.

The runtime auto-dimensions `,65535` on the first use if you haven't explicitly. However, the convention across this project is for programs to dimension it explicitly at entry:

    DO ,65535 <- #65535

This reserves 65535 bytes of buffer. Programs that use Label 666 must not use `,65535` for any other purpose.

## Why not just extend INTERCAL with real syscalls?

Three alternatives were considered and rejected:

- **Add new statements to the language.** `DO OPEN FILE "foo.txt"` would be the obvious route. But doing so would break compatibility with every other INTERCAL compiler, and the extension would have to learn string syntax, which INTERCAL does not natively have.
- **Use CLC-INTERCAL's "call by vague resemblance" convention.** CLC-INTERCAL already has a Label 666 syscall system, but its parameter-passing convention is deliberately obscure (the parameters live in whichever register was last assigned to, a scheme that has no parallel in any other language). The convention is interesting as a curiosity but impractical for our use.
- **Invent a wholly new mechanism.** We could have used Label 999, or Label 1, or a new statement like `DO SYSCALL`. Choosing Label 666 retains enough cultural memory of CLC-INTERCAL to be recognisable, while our simpler calling convention (fixed registers `.1–.4`) is documented and reproducible.

The current Label 666 design is intentionally simple, intentionally not CLC-INTERCAL-compatible, and intentionally documented end to end. It is "our extension, like CLC-INTERCAL's but clearer".

## Why do we need Label 666 at all?

Because our compiler is INTERCAL.

The self-hosted compiler (the one in `src/compiler/compiler.i`) needs to:

1. Read its arguments: figure out which `.i` file the user asked to compile. This requires syscalls 5 and 6 (argc / argv).
2. Open the source file: without which it cannot read the user's program. Syscall 1 (open).
3. Read the source into memory: syscall 2 (read).
4. Close the source: syscall 4 (close).
5. Write the generated assembly to stdout: syscall 3 (write).
6. Exit with the right status: syscall 8 (exit).

Without Label 666, a pure INTERCAL compiler simply cannot be written. The language provides no means to reach the operating system, and a compiler that cannot reach the operating system is useless.

Label 666 is, in this sense, the minimum viable extension that makes self-hosting possible.

## What Label 666 is not

- It is not a feature of every INTERCAL program. A program that uses only standard INTERCAL features (READ OUT, WRITE IN, arithmetic) does not touch Label 666 and remains compatible with any INTERCAL implementation.
- It is not CLC-INTERCAL compatible. A program written against this compiler's Label 666 will not work under CLC-INTERCAL and vice versa, because the parameter conventions differ.
- It is not a general-purpose FFI. It exposes exactly 8 syscalls, carefully chosen. Extending the list is possible but not casually done.

## Reading it in the actual source

Every Label 666 syscall is dispatched by `_rt_syscall_666` in the runtime:

    src/runtime/<platform>.s

Search for `_rt_syscall_666` and you will see the dispatcher, followed by the eight handlers (`_rt_sys666_open`, `_rt_sys666_read`, etc.). Each handler is ~40 lines of platform-specific assembly.

On the INTERCAL side, the minimal usage is what you saw above: set `.1` (and `.2`, `,65535` as appropriate), execute `DO (666) NEXT`, read the result from `.3` and `.4`.

## Exercises

1. Write a program that counts its command-line arguments and prints the count. (Hint: syscall 5.)
2. Write a program that reads the first 10 bytes of `tests/test_hello.i` and prints them as Roman numerals, one per line. (Hint: syscalls 1, 2, 4, and a loop over the bytes.)
3. Why does `,65535` need to be reserved? What would happen if a program used `,65535` for its own purposes in between Label 666 calls?
4. Syscall 9 (getrand) takes a range limit in `.2`. What happens if you pass `.2 = 0`? Consult `docs/runtime.md` and the runtime source to find out.
5. The self-hosted compiler in `src/compiler/compiler.i` uses Label 666. Read it (43 lines) and identify which syscalls it uses and in what order.

## Next reading

- [666.md](666.md) — the full design rationale, CLC-INTERCAL analysis, and implementation choices.
- [runtime.md](runtime.md) — the dispatcher and handler code in the runtime.
- [self-hosting.md](self-hosting.md) — why Label 666 is critical to the self-hosting story.
