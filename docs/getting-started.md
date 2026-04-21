# Getting started

This chapter assumes nothing. You do not need to know INTERCAL. You do not need to have read the rest of these docs. If you can install software on your computer and type commands into a terminal, you can follow along here. The goal is to have a working compiler and a compiled hello-world within thirty minutes.

If you are an experienced developer who wants to skim the pipeline, skip to [overview.md](overview.md) instead. This chapter moves slowly on purpose.

## What you need

One of these three computers:

- A Mac with Apple Silicon (any M-series chip).
- A Linux machine with an Intel or AMD 64-bit processor.
- A Linux machine with an ARM 64-bit processor (Raspberry Pi 4 or 5, or a cloud ARM VM).

On that computer you need two programs installed: `zsh` (a shell) and `gcc` (a C compiler, used here only as an assembler and linker). Both come pre-installed on macOS. On Ubuntu or Debian Linux:

    sudo apt install zsh gcc

On Fedora or similar:

    sudo dnf install zsh gcc

That is the full dependency list. We do not need Python, we do not need Node, we do not need any programming language other than INTERCAL itself.

If you plan to run the Linux cross-platform tests from a macOS laptop, you will also want Docker Desktop. This is optional — the tests that matter for this chapter do not need it.

## Get the code

    git clone https://github.com/jhg/intercal.git
    cd intercal

This takes a few seconds. The repository is about a megabyte on disk.

## Run your first compilation

The simplest possible INTERCAL program lives in `tests/test_give_up.i`:

    cat tests/test_give_up.i

You should see something like:

    DO GIVE UP

That is a one-statement program: "do give up", meaning exit. Compile it:

    zsh src/bootstrap/intercalc.sh < tests/test_give_up.i > my_program
    chmod +x my_program
    ./my_program
    echo "Exit code was: $?"

Expected output:

    Exit code was: 0

Your first INTERCAL program compiled. It did nothing. It exited cleanly. That is, in fact, the whole story.

What happened in the middle:

1. `zsh src/bootstrap/intercalc.sh` ran the bootstrap compiler.
2. `< tests/test_give_up.i` piped the INTERCAL source in on the compiler's standard input.
3. `> my_program` redirected the compiler's standard output (a native executable binary) to a file called `my_program`.
4. `chmod +x` marked the file as runnable.
5. `./my_program` ran it.
6. The program exited with status 0 (success).

## Run hello world

Now something more interesting:

    zsh src/bootstrap/intercalc.sh < tests/test_hello.i > hello
    chmod +x hello
    ./hello

You should see:

    Hello, World!

The source of that program is seventeen statements that look alien. Open `tests/test_hello.i` and glance at it. If you cannot make sense of what the constants mean, that is fine — most of INTERCAL is designed to resist sense at first. The [walkthrough-hello.md](walkthrough-hello.md) chapter decodes it when you're ready.

## Run the test suite

The repository ships with 25 INTERCAL programs, each with an expected output. The test runner compiles each, runs it, and compares stdout:

    zsh tests/run_tests.sh

You should see 25 lines of `PASS`, and the last line:

    Results: 25 passed, 0 failed, 0 skipped

If anything failed, stop here and ask. Something about your setup is off.

## Tweak your first program

Let me convince you the compiler is doing real work. Open `tests/test_hello.i` and find this line:

    DO ,1 SUB #4 <- #0

That is the fifth element of the array `,1`, and its value is what produces the comma `,` in "Hello, World!". Change `#0` to something else — say, `#50` — save the file, and recompile:

    zsh src/bootstrap/intercalc.sh < tests/test_hello.i > hello
    chmod +x hello
    ./hello

The output changes. The character at position 5 is no longer a comma. Exactly which character appears depends on the new delta modulo the Turing Text Model tape's 256-position wraparound. Try a few values and notice that the rest of the output (everything before and after the comma) stays the same.

Revert your change when you're done:

    git checkout tests/test_hello.i

## Understand what just happened

The compiler is a zsh script at `src/bootstrap/intercalc.sh`. You can open it in any text editor. It is 1825 lines. Do not try to read the whole thing; just note that it is there, that it is one file, and that everything you just did flowed through it.

The runtime — the code that every compiled INTERCAL program links against — is in `src/runtime/<your-platform>.s`. On Mac, that is `src/runtime/macos_arm64.s`. Open it briefly. It is hand-written assembly, about 970 lines. Do not try to read it either. It is there, it is one file per platform, and your `hello` binary contains a copy.

The system library is in `src/syslib/syslib.i` (for the pure-INTERCAL version) and `src/syslib/native/<platform>.s` (for the fast native version). These provide arithmetic. Hello world does not use arithmetic, so neither was linked into your binary.

## A tiny map of the territory

You just ran three pieces:

- A compiler. Takes INTERCAL source, emits a binary.
- A runtime. Provides low-level routines (print, exit, arithmetic primitives) that the emitted binary calls into.
- A test suite. Confirms that everything works.

Every other file in the repository is in support of those three pieces. The separate `docs/` directory you are reading is one example; `AGENTS.md` is another; the CI workflows under `.github/` are another.

## What to read next

If you are curious about the language:

- [what-is-intercal.md](what-is-intercal.md) — INTERCAL in plain English, no code.
- [intercal-primer.md](intercal-primer.md) — a tighter, programmer-oriented tour.

If you are curious about the compiler:

- [overview.md](overview.md) — a slightly more technical "what this repo is".
- [pipeline.md](pipeline.md) — how source becomes binary, step by step.

If you are curious about the unusual design decisions:

- [design-rationale.md](design-rationale.md) — a FAQ covering why every major choice was made.
- [666.md](666.md) — the deep dive on the Label 666 syscall extension.

If you want to make a change:

- [your-first-contribution.md](your-first-contribution.md) — a concrete walkthrough of adding a small feature.
- `AGENTS.md` (in the repo root) — the authoritative contributor guide.

## If you got stuck

- `intercalc.sh: command not found` — you are probably running from a directory other than the repo root. `cd` into it.
- `ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE` — you got an error at compile time because the program you gave it is too impolite. We will explain later. For now, go back to a test program that passes.
- `zsh: bad interpreter` on Linux — install zsh (`sudo apt install zsh`).
- Nothing prints when you run `./hello` — check that the file exists (`ls -l hello`) and that it is executable (`chmod +x hello`).

For anything else, open `AGENTS.md` or ask.
