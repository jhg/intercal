# History and context

The INTERCAL language, the compilers that have implemented it, and the design choices that brought us here. This chapter is the historical and comparative context that the technical chapters assume but do not spell out.

## INTERCAL, 1972

The language was designed by Donald R. Woods and James M. Lyon at Princeton University in 1972. The original reference manual, titled *The INTERCAL Programming Language Revised Reference Manual*, was the first formal specification; it circulated in typewritten form before being scanned and republished online. The manual's tone is a parody of the technical writing conventions of the era, but the language it specifies is a complete, Turing-complete programming language with deliberate and consistent semantics.

INTERCAL's defining design choice is to avoid every feature then fashionable. No keywords shared with any other language (no `IF`, no `GOTO`, no `WHILE`). Grouping with two alternating bracket types. Arithmetic only through bitwise operators. Politeness as a compile-time check. The result is a language that is Turing-complete, specifiable in a few dozen pages, and pleasant to read after one gets over the first hour.

The earliest implementation, by Woods and Lyon themselves, was written in SPITBOL (a Snobol dialect) and compiled INTERCAL-72 programs on a mainframe. It is not publicly available today.

## C-INTERCAL (ick), 1990

Eric S. Raymond rewrote and extended INTERCAL in C in 1990, producing a more portable implementation under the name *C-INTERCAL* (often abbreviated *ick*, from the compiler binary's name). The C-INTERCAL distribution added several extensions to INTERCAL-72:

- The `COME FROM` statement, now considered canonical INTERCAL despite being absent from the 1972 manual.
- External function calls via the `-e` flag.
- A test suite, release tooling, and documentation.

C-INTERCAL is still the reference implementation. Raymond's documentation at http://catb.org/~esr/intercal/ remains the clearest exposition of the language's pragmatic semantics, and many programmers learn INTERCAL through his version first.

Our compiler is clean-room: it has been written without reading C-INTERCAL's source or copying fragments of its documentation. The language reference in `AGENTS.md` and the grammar in [appendix-grammar.md](appendix-grammar.md) were written from first principles against the INTERCAL-72 manual.

## CLC-INTERCAL

CLC-INTERCAL, maintained by Claudio Calvelli, is a later implementation in Perl with further extensions: quantum computing primitives, an object system, Baudot-coded text I/O, and a syscall mechanism via a reserved label called `666`. The CLC-INTERCAL project is hosted at https://uilebheist.srht.site/.

Label 666 is the feature of CLC-INTERCAL we borrowed most directly. Its parameter-passing convention — "call by vague resemblance to the last assignment" — is idiosyncratic and obscurely documented (see [666.md](666.md)). Our version of Label 666 uses a simpler fixed-register convention: `.1` as syscall number, `.2`/`.3`/`.4` as parameters and results, and `,65535` as the data buffer. This is not CLC-INTERCAL compatible, and we make that clear to any reader.

The decision to adopt something Label-666-shaped rather than inventing a new mechanism was driven by the fact that `666` is already mentally associated with "syscall gate" for anybody familiar with CLC-INTERCAL. Using it for the same purpose, even with a different calling convention, reduces confusion.

## Why write another INTERCAL compiler

Three existing implementations are described above. A fourth is therefore not strictly necessary. The reasons we built this one anyway:

- **Educational.** None of the existing implementations were designed to be read as compiler construction tutorials. C-INTERCAL is pragmatic C from 1990 with three decades of accretion; CLC-INTERCAL is Perl. The INTERCAL-72 original is lost to most developers. A small, clean, single-language-per-file implementation in a working codebase serves a role the others do not.

- **Self-hosting in pure INTERCAL.** To our knowledge, no historical INTERCAL compiler has been self-hosted in INTERCAL. C-INTERCAL is written in C; CLC-INTERCAL is written in Perl. The attempt to express the full compiler in INTERCAL is, partly, an exercise in whether INTERCAL is practically (not just theoretically) capable of such a program.

- **Native-binary output on modern platforms.** Both C-INTERCAL and CLC-INTERCAL transpile to C and rely on `cc` to produce the final binary. We wanted to see what a direct-to-assembly path looks like for a language this small. Skipping C as an intermediate removed a dependency and forced us to confront the platform differences directly.

- **Own the clean-room implementation.** A from-scratch compiler for a specified language, written without reference to any existing implementation, is a clean starting point for whatever extensions or experiments we want to try.

## Comparative notes

A short catalogue of how our design decisions differ from other INTERCAL implementations and, more broadly, from the C compilers most readers will be familiar with.

### Transpilation vs direct emission

C-INTERCAL emits C; CLC-INTERCAL emits Perl; we emit ARM64 or x86-64 assembly. The transpilation path trades one layer of complexity (dealing with machine code) for another (dealing with the target language's constraints). In practice, transpiling to C is the less risky choice — C compilers are well-tested — but it forces the INTERCAL implementer to match INTERCAL's semantics to C's, and some mismatches are awkward (C's signed-overflow undefined behaviour versus INTERCAL's unsigned wrap semantics).

### Operator implementation

All three implementations implement mingle and select as subroutines in the runtime. The difference is how the subroutine is called: C-INTERCAL inlines them as C function calls, CLC-INTERCAL as Perl subroutines, and we as `bl _rt_mingle` / `bl _rt_select` native calls. The semantics are identical.

### Syslib

C-INTERCAL ships a pure-INTERCAL syslib called `syslib.i`, analogous to ours. CLC-INTERCAL has a similar library but with different label conventions. Our `src/syslib/syslib.i` was written clean-room, but the label numbering follows the INTERCAL-72 convention (1000–1999 reserved, specific labels for add/sub/mul/div) because that is the specification.

### Self-hosting ambition

C-INTERCAL and CLC-INTERCAL do not aim to be self-hosted. Our project does. That forces several specific design decisions:

- The Label 666 syscall mechanism must exist in the compiler's output, because the self-hosted compiler needs to read files at runtime (no `argc`/`argv` parsing in pure INTERCAL).
- `,65535` must be reserved. Any program we ever compile cannot use that array, because the self-hosted compiler does.
- The compiler's output must match the bootstrap's output for the same inputs, at least up to observable program behaviour. If the two compilers produce different binaries, the fixpoint test cannot converge.

### Extensions

We deliberately avoid most extensions:

- No MAYBE / backtracking.
- No computed COME FROM.
- No threading via multiple COME FROMs to the same label.
- No Wimpmode (decimal I/O).
- No TriINTERCAL (base 3).

The rationale is to keep the core language surface small enough that `compiler.i` can realistically be built in INTERCAL. Every extension we add is another codegen function to write in INTERCAL, and at the current pace of stage3 development every kilobyte of INTERCAL source is expensive.

## How a C compiler would handle the same tasks

A reader familiar with C compilers might find it useful to know what the INTERCAL compiler does differently, and why.

### Lexing

A C lexer has to handle strings, character constants, escape sequences, preprocessor directives, numeric literals in three bases, and trigraphs. Our lexer handles none of those — no strings, no literals other than decimal, no preprocessor. On the other hand, we handle `DON'T` as a single token, which no C lexer has to deal with.

### Parsing

A C parser is LL(k)-untractable in several places; most C compilers use hand-written recursive descent with unbounded lookahead or occasional LR(1) tables (yacc/bison style). Our parser is LL(1) because INTERCAL's expression grammar has no operator precedence: every operator must be explicitly grouped, so there is no ambiguity to resolve.

C's type system is the main reason C compilers have a dedicated semantic analysis phase. INTERCAL has four types (onespot, twospot, tail, hybrid) and no type inference; the type of every expression is determined by its root node. We have essentially no type-checking to do.

### Code generation

C compilers emit one instruction per source token is a pointer-poor model. Modern C compilers emit SSA IR, run 20+ optimisation passes, and only then lower to target instructions. Our compiler emits ~10 instructions per INTERCAL statement, directly, without optimisation.

The cost of our approach is that the emitted assembly is not optimal: we call `_rt_mingle` even when the operands are constants we could fold. The benefit is that the codegen is transparent. You can read `codegen_assign` and see, line by line, what assembly will come out.

### Runtime

C's runtime is largely the C library: `malloc`, `printf`, file I/O, and so on. Our runtime is much smaller because INTERCAL asks for less: Roman-numeral output, Turing-tape arrays, mingle, select, unary operators, plus the Label 666 syscalls. A C runtime for an INTERCAL-sized program would be at least 100KB; ours is ~40KB per platform.

## How a Lisp compiler would handle the same tasks

Lisp compilers present a useful contrast because they invert several of the assumptions a C-style compiler makes.

### Lexing and parsing

Lisp's syntax is so simple that lexing and parsing fuse into a single `read` function. Parentheses, symbols, and numbers; nothing else. Our lexer is more involved than a Lisp lexer but has exactly the same shape: token-by-token consumption with a small switch.

### Semantic analysis

A Lisp-with-macros compiler has to handle macro expansion as part of semantic analysis: the program is transformed by user-defined rewrites before any codegen happens. We have nothing comparable. INTERCAL has no macros, and the closest thing we have to compile-time expansion is the gerund resolution in `ABSTAIN FROM CALCULATING`.

### Runtime

Lisp runtimes universally include a garbage collector. Ours does not: INTERCAL allocates arrays once via `_rt_mmap` and never frees them. For the programs we run this is acceptable; for a Lisp program it would not be.

## Where this project sits in the compiler-construction literature

There are, roughly, four genres of compiler-construction text:

1. **Theory first.** The Dragon Book, Appel's Modern Compiler Implementation. Full formal treatment of grammars, parsing tables, IR, optimisation.
2. **Hands-on build.** Crafting Interpreters, Thain's Introduction to Compilers, Crenshaw's Let's Build a Compiler. Take the reader through a complete compiler, one phase at a time.
3. **Technique catalogues.** Cooper & Torczon's Engineering a Compiler, Muchnick's Advanced Compiler Design. Surveys of modern techniques, with deep treatment of specific optimisations.
4. **Case studies.** Project-specific writeups — the CHICKEN Scheme implementation notes, the Go compiler internals talks, the LLVM documentation.

This repository's `docs/` directory belongs to genre (4), with elements of genre (2). It is a case study of a small self-hosting compiler, narrated phase by phase, with exercises and cross-references to the classical literature for the reader who wants depth beyond what we provide here.

The design choice to remain small — no IR, no optimisation, hand-written runtime — is what makes this case-study role feasible. A full modern compiler could not be documented this way; it is too big. INTERCAL, and this compiler specifically, are small enough.
