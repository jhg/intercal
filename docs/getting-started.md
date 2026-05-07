# Getting started

Nothing assumed here. You do not need to know INTERCAL or anything about compilers. If you can install software and use a terminal, you can follow along. The aim is a working compiler and a compiled hello-world, in about thirty minutes.

If you are already an experienced developer and just want to skim the pipeline, jump to [overview.md](overview.md).

## What you need

One of these computers:

- A Mac with Apple Silicon (any M-series chip).
- A Linux box with an Intel or AMD 64-bit CPU.
- A Linux box with an ARM 64-bit CPU (Raspberry Pi 4 or 5, a cloud ARM VM).

And two programs: `zsh` (a shell) and `gcc` (a C compiler, used here only as an assembler and linker). Both ship with macOS. On Ubuntu or Debian:

    sudo apt install zsh gcc

On Fedora and similar:

    sudo dnf install zsh gcc

That is the full list. No Python, no Node, no other language toolchain. INTERCAL is the only language we add.

If you plan to reproduce the Linux CI tests from a Mac, install Docker Desktop too. It is optional; the steps in this chapter do not need it.

## Get the code

    git clone https://github.com/jhg/intercal.git
    cd intercal

A few seconds. The repository is roughly a megabyte on disk.

## Run your first compilation

The simplest possible INTERCAL program lives in `tests/test_give_up.i`:

    cat tests/test_give_up.i

You should see:

    DO GIVE UP

A one-statement program: "do give up", meaning exit. Compile it:

    zsh src/bootstrap/intercalc.sh < tests/test_give_up.i > my_program
    chmod +x my_program
    ./my_program
    echo "Exit code was: $?"

Expected:

    Exit code was: 0

Your first INTERCAL program compiled. It did nothing. It exited cleanly. That is the whole story.

What happened along the way:

1. `zsh src/bootstrap/intercalc.sh` ran the bootstrap compiler.
2. `< tests/test_give_up.i` piped the INTERCAL source into the compiler's standard input.
3. `> my_program` redirected the compiler's standard output (a native executable binary) into a file.
4. `chmod +x` marked the file as runnable.
5. `./my_program` ran it.
6. The program exited with status 0.

## Run hello world

Something more interesting:

    zsh src/bootstrap/intercalc.sh < tests/test_hello.i > hello
    chmod +x hello
    ./hello

You should see:

    Hello, World!

The source has seventeen statements that look alien. Open `tests/test_hello.i` and glance at it. If you cannot make sense of the constants, that is fine; most of INTERCAL resists sense at first. The chapter [walkthrough-hello.md](walkthrough-hello.md) decodes it when you are ready.

## Run the test suite

The repository ships 33 INTERCAL programs, each with an expected output. The runner compiles each, runs it, and compares stdout:

    zsh tests/run_tests.sh

You should see 33 lines of `PASS` and a final line:

    Results: 33 passed, 0 failed

If anything failed, stop and ask. Something about your setup is off.

## Tweak your first program

To convince yourself the compiler is doing real work, open `tests/test_hello.i` and look at this line:

    DO ,1 SUB #4 <- #0

It is the fifth element of array `,1`, and its value is what produces the comma in "Hello, World!". Change `#0` to something else (try `#50`), save, recompile:

    zsh src/bootstrap/intercalc.sh < tests/test_hello.i > hello
    chmod +x hello
    ./hello

The output changes. The fifth character is no longer a comma. Which character it becomes depends on the new delta modulo the Turing Text Model tape's 256-position wraparound. Try a few values; notice that everything before and after the changed character stays put.

Revert when you are done:

    git checkout tests/test_hello.i

## Understand what just happened

The compiler is the zsh script `src/bootstrap/intercalc.sh`. Open it in any text editor. It is roughly two thousand lines. Do not try to read it end to end. Just notice that it is one file, and that everything you ran went through it.

The runtime, the code that every compiled INTERCAL program links against, lives in `src/runtime/<your-platform>.s`. On macOS that is `src/runtime/macos_arm64.s`. Glance at it. About 970 lines of hand-written assembly. Do not try to read this end to end either. It is one file per platform, and your `hello` binary contains a copy.

The system library is in `src/syslib/syslib.i` (the pure-INTERCAL version) and `src/syslib/native/<platform>.s` (the fast native one). Both provide arithmetic. Hello world does not do arithmetic, so neither was linked into your binary.

## A tiny map of the territory

You just exercised three pieces:

- A compiler. Reads INTERCAL, emits a native binary.
- A runtime. Provides print, exit, and arithmetic primitives the binary calls into.
- A test suite. Confirms the first two work.

Every other file in the repository supports those three. The `docs/` directory you are reading is one example, `AGENTS.md` is another, the CI workflows under `.github/` a third.

## What to read next

If you are curious about the language:

- [what-is-intercal.md](what-is-intercal.md): INTERCAL in plain English, no code.
- [intercal-primer.md](intercal-primer.md): a tighter, programmer-oriented tour.

If you are curious about the compiler:

- [overview.md](overview.md): a more technical "what this repo is".
- [pipeline.md](pipeline.md): how source becomes binary, step by step.

If you are curious about the design:

- [design-rationale.md](design-rationale.md): a FAQ on every major choice.
- [666.md](666.md): the deep dive on the Label 666 syscall extension.

If you want to make a change:

- [your-first-contribution.md](your-first-contribution.md): a concrete walkthrough of adding a small feature.
- `AGENTS.md` (in the repo root): the authoritative contributor guide.

## If you got stuck

- `intercalc.sh: command not found`: you are running from a directory other than the repo root. `cd` into it.
- `ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE`: the program you fed in is too impolite. Stay with the test programs for now; we will explain politeness later.
- `zsh: bad interpreter` on Linux: install zsh (`sudo apt install zsh`).
- Nothing prints when you run `./hello`: check that the file exists (`ls -l hello`) and is executable (`chmod +x hello`).

For anything else, read `AGENTS.md` or open an issue.
