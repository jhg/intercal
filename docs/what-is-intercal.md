# What is INTERCAL?

INTERCAL is a programming language invented at Princeton in 1972 by Donald Woods and James Lyon. Its full name, in keeping with the era, is *Compiler Language With No Pronounceable Acronym*. Since that does not yield a pronounceable acronym either, everyone calls it INTERCAL.

This chapter is for somebody who has never seen the language. No code, no compiler theory, just what it is and why people still write compilers for it fifty years on.

## The short version

INTERCAL was designed to be unlike every other language of its time. Where Fortran has `IF`, INTERCAL has no conditional statement. Where C has `+`, `*`, `/`, INTERCAL has bitwise operators only. Where Java has objects, INTERCAL has numbered variables. Where Python prints with `print("hello")`, INTERCAL prints in Roman numerals.

It is Turing-complete. Given time and patience it can compute anything any other language can compute. It just refuses to make any of it convenient.

That sounds like a terrible language. It is. That is the point.

## Why INTERCAL exists

INTERCAL was written as a critique. Programming-language design in 1972 was in a phase of rapid proliferation, with a new language every year claiming to be better than the last. Woods and Lyon wrote a manual that parodied the genre, describing a language that included every feature they found irritating and excluded every feature they found useful.

Some highlights of the spec:

- The verbs are `DO`, `PLEASE`, and `PLEASE DO`, all functionally equivalent.
- A program must use `PLEASE` on between 1/5 and 1/3 of its statements. Too few, and the compiler refuses to compile it as "insufficiently polite". Too many, and it complains that you are "overly polite".
- Variables are not named, they are numbered: `.1`, `.2`, `:1`, and so on.
- There is no arithmetic. Addition, subtraction, multiplication and division are bitwise tricks that have to be called as subroutines.
- Number output is in Roman numerals. Text output goes through a simulated tape loop where each character is encoded as a tape-head displacement.
- Number input arrives one digit at a time, spelled out in English: `ONE TWO THREE` for 123.
- Punctuation has names. `.` is "spot", `:` is "two-spot", `,` is "tail", `$` is "big money".

Every choice is internally consistent. The language works. You can write programs in it, read them back, and run them. In a technical sense it is not broken. In a design sense it is perfectly wrong.

## The `COME FROM` statement

INTERCAL's most-quoted invention is `COME FROM`. It was not in the 1972 manual, but later implementations adopted it and it has stuck. `COME FROM` is the inverse of `GOTO`: instead of saying "go to that statement", you say "come back here after that statement runs".

The cursed consequence is that a statement elsewhere in the program can hook itself onto any labelled statement without the labelled statement knowing. Reading an INTERCAL program top to bottom tells you only part of the story. You also have to scan for `COME FROM` lines that might secretly redirect the flow.

`COME FROM` has been rediscovered several times outside INTERCAL, including in a serious 1973 proposal by R. Lawrence Clark and as a Perl module. It remains one of the more subversive ideas in control flow.

## Why anyone still writes INTERCAL compilers

A small community has maintained INTERCAL implementations continuously since the original. The main ones today:

- **C-INTERCAL** by Eric S. Raymond (1990 onwards), written in C, still actively maintained.
- **CLC-INTERCAL** by Claudio Calvelli (1999 onwards), written in Perl, with extensions including quantum primitives.
- **This implementation**, written in zsh and INTERCAL, targeting native ARM64 and x86-64 binaries with no C intermediate.

Why? Four reasons, in decreasing order of seriousness:

- **It is a clean test case for compiler construction.** INTERCAL is small enough that a full implementation fits in a single person's head, but weird enough that writing the compiler forces you to engage with every classical compiler-theory topic. It is a good teaching language precisely because it is bad.
- **Self-hosting INTERCAL is a feat in its own right.** Writing a compiler for a language in that same language is a rite of passage; doing it for INTERCAL is particularly absurd. As of this writing, nobody has ever produced a self-hosted INTERCAL compiler whose own source is written in INTERCAL. This repository is trying.
- **It is a useful proving ground for AI-driven development.** Most of the code in this repository was written by a large language model paired with one human collaborator: the human set the goals, made the first commits, supplied references, and reviewed; the compiler, runtime, syslib, and tests came from the model. INTERCAL fits the experiment because off-the-shelf code patterns rarely apply to it, and any divergence from the spec is detectable.
- **It is funny.** Some of the most influential programming languages (Lisp, Smalltalk, Forth) were invented partly as jokes and partly as serious experiments. INTERCAL sits squarely in that tradition. Reading a long INTERCAL program is a kind of performance art.

## What INTERCAL is not

Not a golf language like J or APL. Not a brain-teaser language like Brainfuck. Not obfuscated to be hard to read; most INTERCAL is legible once you know the conventions.

And, despite appearances, not contrarianism for its own sake. The language has internal logic. Once you accept that conventional features are suspect, every decision follows.

## A glimpse of what a program looks like

The hello-world program from this repository:

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

It prints `Hello, World!`. Each `,1 SUB #N <- #V` puts value V into the Nth slot of array `,1`. The constants 238, 108, 112, 0, and so on encode the letters H, e, l, l, o, and the rest, through a scheme called the Turing Text Model (see [runtime.md](runtime.md)). The first statement dimensions the array to 14 slots; `READ OUT ,1` walks them and prints the result.

The program has 17 statements and 4 of them start with `PLEASE`, giving a politeness ratio of about 24%, comfortably inside the required [20%, 33.3%] range.

## What to read next

- [getting-started.md](getting-started.md): install the compiler and run this program.
- [intercal-primer.md](intercal-primer.md): a programmer-focused language tour.
- [design-rationale.md](design-rationale.md): a FAQ on why this compiler is shaped the way it is.
- [history-and-context.md](history-and-context.md): the longer historical treatment.
