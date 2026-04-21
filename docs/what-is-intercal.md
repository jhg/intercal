# What is INTERCAL?

INTERCAL is a programming language invented in 1972 at Princeton University by Donald Woods and James Lyon. Its full name, in the joke tradition of its era, is *Compiler Language With No Pronounceable Acronym*; since that does not produce a pronounceable acronym either, the name was shortened to INTERCAL.

This chapter is a plain-English introduction for somebody who has never seen INTERCAL before. No code. No compiler theory. Just what it is and why people still write compilers for it fifty-plus years later.

## The short version

INTERCAL is a programming language designed to be exactly unlike every other programming language. Where Fortran has `IF`, INTERCAL has no conditional statement at all. Where C has `+`, `*`, `/`, INTERCAL has only bitwise operators. Where Java has object-oriented abstractions, INTERCAL has only numbered variables. Where Python prints to stdout with `print("hello")`, INTERCAL prints numbers in Roman numerals.

The language is Turing-complete. Given enough time and patience, it can compute anything any other programming language can compute. But it refuses to make any of it convenient.

That sounds like a terrible language. It is. That is the point.

## Why INTERCAL exists

INTERCAL was written as a critique. In 1972, programming language design was in an age of rapid proliferation: every year brought a new language claiming to be better than the last. Woods and Lyon wrote a manual that parodied this style, describing a language that included every feature they found irritating and excluded every feature they found useful.

Some highlights of the original specification:

- The main verbs are `DO`, `PLEASE`, and `PLEASE DO`, all functionally equivalent.
- A program must use `PLEASE` on between 1/5 and 1/3 of its statements. Too few, and the compiler rejects the program as "insufficiently polite". Too many, and it rejects it as "overly polite".
- Variables cannot be named; they are numbered. `.1`, `.2`, `:1`, and so on.
- There is no arithmetic. Addition, subtraction, multiplication and division are all expressed through bitwise tricks on 16- and 32-bit integers, and have to be called as subroutines.
- Output of a number is in Roman numerals. Output of text is through a simulated tape loop that requires each character to be encoded as a tape-head displacement.
- Input of a number is read one digit at a time, each spelled out in English (`ONE TWO THREE` for 123).
- Punctuation characters have their own names: `.` is "spot", `:` is "two-spot", `,` is "tail", `$` is "big money", and so on.

The humour is that every one of these choices is internally consistent. The language works. You can solve problems in it. You can read and write it. It is, in a technical sense, not broken — it is, in a design sense, perfectly wrong.

## The `COME FROM` statement

One of INTERCAL's contributions to programming language mythology is the `COME FROM` statement. It was added by later implementations (not part of the original 1972 manual, but universally adopted). `COME FROM` is the inverse of `GOTO`: instead of saying "go here", you say "come here after that other statement runs".

The cursed consequence: a statement elsewhere in the program can attach itself to any labelled statement without the labelled statement knowing. Reading an INTERCAL program forwards tells you only part of the story; you also have to scan for `COME FROM` statements that might affect the lines you're reading.

`COME FROM` has been rediscovered several times outside INTERCAL, including a serious 1973 proposal by R. Lawrence Clark for programming language design, and a brief appearance in Perl as a module. It remains one of the more subversive ideas in control flow.

## Why anyone still writes INTERCAL compilers

A small community of programmers has maintained INTERCAL implementations continuously since the original. The main ones are:

- **C-INTERCAL** by Eric S. Raymond (1990 onwards), written in C, still actively maintained.
- **CLC-INTERCAL** by Claudio Calvelli (1999 onwards), written in Perl, with extensions including quantum computing primitives.
- **This implementation**, written in zsh + INTERCAL, targeting native ARM64 and x86-64 binaries without a C intermediate step.

Why? Three reasons, in decreasing order of seriousness:

- **Because it is a clean test case for compiler construction.** INTERCAL is small enough that a full implementation fits in a single person's head, but weird enough that writing the compiler forces you to engage with every classical compiler-theory topic. It is a good teaching language precisely because it is bad.
- **Because self-hosting INTERCAL is a flex.** Writing a compiler for a language in that language is a rite of passage; writing one for INTERCAL is particularly absurd. As of this writing, nobody has ever produced a self-hosted INTERCAL compiler where the compiler itself is written in INTERCAL. This repository is trying.
- **Because it is funny.** Some of the most influential programming languages (Lisp, Smalltalk, Forth) were invented partly as jokes and partly as serious experiments in language design. INTERCAL sits squarely in that tradition. Reading a long INTERCAL program is a kind of performance art.

## What INTERCAL is not

It is not a golf language (like J or APL). It is not a brain-teaser language (like Brainfuck). It is not obfuscated to be hard to read — most INTERCAL is actually legible once you learn the conventions.

It is also not, despite appearances, an exercise in contrarianism for its own sake. The language's design has internal logic: once you accept the premise that conventional features are suspect, every decision follows from that premise.

## A glimpse of what a program looks like

Here is the hello-world program from this repository:

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

This prints `Hello, World!`. Each `,1 SUB #N <- #V` assigns the value V to the Nth element of the array `,1`. The constants 238, 108, 112, 0, and so on encode the letters H, e, l, l, o, and the rest, through a scheme called the Turing Text Model which we explain in [runtime.md](runtime.md). The first statement dimensions the array to 14 elements, and `READ OUT ,1` walks the array and prints the encoded text.

That program has 17 statements total and 4 of them start with `PLEASE`, giving a politeness ratio of about 24% — comfortably in the required [20%, 33.3%] range.

## What to read next

- [getting-started.md](getting-started.md) — install the compiler and run this program.
- [intercal-primer.md](intercal-primer.md) — a programmer-focused language tour.
- [design-rationale.md](design-rationale.md) — a FAQ on why this compiler is shaped the way it is.
- [history-and-context.md](history-and-context.md) — the longer historical treatment.
