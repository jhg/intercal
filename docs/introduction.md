# Introduction

This is a practical book about compilers, written around a small but complete one.

The compiler in question targets INTERCAL, a 1972 programming language designed to be unlike every other language of its time. The choice is deliberate: most compilers textbooks build a mini-C or a mini-Lisp, languages familiar enough that the reader can skim past the parts they already understand. INTERCAL never lets you skim. Its grammar has no operator precedence. Its arithmetic is bitwise only. Its compile-time check rejects programs that show the wrong amount of deference. Its `READ OUT` statement prints Roman numerals, and its array I/O goes through a 256-position tape with bit-reversed addressing. Working through a compiler for INTERCAL forces you to engage with every classical phase, because the language gives you nothing for free.

The companion source is a real, self-hosting compiler. The bootstrap is roughly two thousand lines of zsh. The runtime is hand-written assembly for three platforms (macOS ARM64, Linux ARM64, Linux x86-64). The system library exists in two parallel implementations, pure INTERCAL and native assembly, that verify each other through a differential test. None of these pieces is hypothetical. Every example in the book points at code you can read, modify, and run.

## How the book is organised

The book is in six parts plus a reference apparatus.

Part I is a first-contact tour. If you have never seen INTERCAL, start there. You install the toolchain, compile a hello-world, learn the language vocabulary, and meet the syscall extension that makes self-hosting possible. By the end of Part I you have a working compiler and enough INTERCAL to read the test programs.

Parts II through V follow the compiler from front to back, then out to platforms and process. Part II maps the source layout onto classical compiler phases and walks the entire pipeline once. Part III drills into scanning, parsing, and semantic analysis. Part IV covers code generation, the runtime, the system library, calling conventions, and executable formats. Part IV.5 spends a chapter each on INTERCAL's four most distinctive features: the politeness rule, `COME FROM`, the Turing Text Model, and Roman-numeral I/O. Part V looks at platform porting, self-hosting, testing, debugging, and the design of error messages.

Part VI steps back. It compares INTERCAL's design choices to those of conventional languages, places INTERCAL among the broader family of esoteric languages, and weighs the language against Hoare's and Wirth's canonical advice on language design. It also documents how to land a first contribution and how to work on this codebase with an AI agent.

The reference apparatus at the end is for lookup rather than reading: a one-line cheatsheet for every statement, the formal EBNF grammar, a glossary of INTERCAL symbols and compiler-theory terms, hints for the chapter exercises, and an annotated bibliography of free external resources.

## Who the book is for

Three readers in particular will find a path here:

A reader new to compilers, looking for a complete worked example small enough to hold in mind, can read Parts I through V in order and finish with a working understanding of every phase of a real compiler.

A reader already comfortable with compilers, curious about INTERCAL specifically or about the design tradeoffs of an unusual language, can skim the introduction layer and dwell in Parts III and IV. The exercise at the end of each chapter is sized for a reader who wants to test the explanation, not a beginner.

A contributor or AI agent who needs to modify the compiler will spend most of their time in Part V (platforms, testing, debugging) and the reference apparatus. The map of the compiler in Part II is the entry point for finding any specific routine.

## A note on the project itself

This compiler is also a small experiment in AI-assisted software development. Most of the code, the runtime, the syslib, the tests, and the chapters of this book were written by a large language model working with a single human collaborator. The collaborator chose the goals, made the first commits, supplied reference material, and reviewed the result; the day-to-day implementation work was the model's. INTERCAL turned out to be a useful proving ground for that mode of work, small enough to fit comfortably in a model's context, weird enough that off-the-shelf code patterns rarely apply, and well-specified enough that any divergence from the spec is detectable.

The book documents both the compiler and, by being itself one of the artifacts the model produced, the experiment. Whether that succeeds is best judged by reading on.

## Where to go next

If you have not yet built the compiler, start with [getting-started.md](getting-started.md). It is the shortest path from cloning the repository to running hello-world.

If you have already built it and want the language tour, read [intercal-primer.md](intercal-primer.md).

If you want to know the shape of the compiler before reading any phase in detail, [overview.md](overview.md) and then [pipeline.md](pipeline.md) give it to you in two short chapters.

If you are looking for a specific topic, the chapter index on the right-hand sidebar (or in [README.md](README.md) if you are reading on GitHub) lists every chapter with a one-line description.
