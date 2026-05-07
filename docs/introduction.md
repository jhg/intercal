# Introduction

A book about compilers, built around one small enough to read end to end.

The compiler targets INTERCAL, a programming language Donald Woods and James Lyon invented in 1972 specifically to resemble nothing else. Most compiler textbooks pick a mini-C or a mini-Lisp because the syntax stays out of the way. INTERCAL goes the other direction. Its grammar has no operator precedence. Its arithmetic is bitwise only. It rejects programs that are too rude or too polite at compile time. `READ OUT` prints Roman numerals; array I/O goes through a 256-position tape with bit-reversed addressing. Writing a compiler for it forces you to think about every classical phase, because the language never lets you reuse a familiar shortcut.

The compiler in this repository is real and self-hosting. About two thousand lines of zsh do the bootstrap; a few hundred per platform of hand-written assembly do the runtime; ten thousand lines of pure INTERCAL form a system library that the compiler verifies against a fast native rewrite. Every example in the book points at code you can clone, edit, and run.

## How the book is organised

Six parts plus a reference appendix.

Part I is the first-contact tour. Install the toolchain, compile hello-world, learn the language vocabulary, meet the syscall extension that makes self-hosting possible. By the end you have a working compiler and enough INTERCAL to read the test programs.

Parts II through V follow the compiler front to back. Part II is the layout map and a one-pass walk of the whole pipeline. Part III is the front end: scanning, parsing, semantic analysis. Part IV is the back end: code generation, runtime, system library, calling conventions, executable formats. Part IV.5 is one chapter each for the four most distinctive INTERCAL features (the politeness rule, `COME FROM`, the Turing Text Model, and Roman-numeral I/O). Part V covers platforms, self-hosting, testing, debugging, and how the compiler reports errors.

Part VI steps back from the implementation. It compares INTERCAL to conventional languages, places it within the broader genre of esoteric languages, and weighs it against the canonical language-design advice of Hoare and Wirth. It also documents how to land a first contribution and how to work on the codebase alongside an AI agent.

The reference appendix is for lookup, not reading: a statement cheatsheet, the EBNF grammar, a glossary, exercise hints, and an annotated bibliography.

## Who should read what

New to compilers and want a complete worked example? Read Parts I through V in order. You finish with a working understanding of every phase of a real compiler.

Already comfortable with compilers, here for INTERCAL specifically? Skim Part I and dwell in Parts III and IV. The exercises at the end of each chapter are calibrated for somebody testing an explanation, not for a beginner.

Here to modify the compiler? Your home is Part V (platforms, testing, debugging) plus the reference appendix. The map in Part II is where you find any specific routine.

## A note on the project

The compiler is also a small experiment in AI-assisted development. Most of the code came from a large language model working with one human collaborator: the human picked the goals, made the first commits, supplied references, and reviewed the result; the day-to-day implementation was the model's. INTERCAL fits the experiment because off-the-shelf code patterns rarely apply to it, and any divergence from the spec is detectable.

## Where to go next

The shortest path from clone to running hello-world is [getting-started.md](getting-started.md).

For the language tour, [intercal-primer.md](intercal-primer.md).

For the shape of the compiler in two short chapters, [overview.md](overview.md) followed by [pipeline.md](pipeline.md).

The full chapter list is in the right-hand sidebar (or in [README.md](README.md) if you are reading on GitHub).

The source lives at <https://github.com/jhg/intercal>. Issues, pull requests, and discussion happen there.
