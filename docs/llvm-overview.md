# LLVM, in shape

LLVM is the modular compiler infrastructure that powers Clang, Swift, Rust (by default), Julia, and a long tail of language frontends and analysis tools. If you have used `clang` to compile C, you have used LLVM. The codebase lives at <https://github.com/llvm/llvm-project>.

This chapter is an orientation map. Enough to walk into the LLVM source tree and know what each directory is for, what to read first, and how the architecture maps to the smaller compiler in this repository.

## Three phases, one IR

LLVM organises a compiler into three phases connected by a single intermediate representation called *LLVM IR*.

- A **frontend** turns source code into LLVM IR. Clang is the C/C++/Objective-C frontend. The Rust compiler uses LLVM as a backend; its frontend produces a Rust-specific IR called MIR, which the Rust codegen layer then lowers to LLVM IR.
- A **middle end** runs optimisation passes on LLVM IR. The IR is the same regardless of source language, so the optimisations apply to every frontend.
- A **backend** lowers LLVM IR to machine code for a specific target (x86-64, ARM64, RISC-V, GPU, WebAssembly).

The big architectural idea is that a frontend and a backend never have to know about each other. Adding a new language means writing a frontend that emits LLVM IR. Adding a new processor means writing a backend that consumes it. Every existing optimisation comes for free.

In our compiler, the three phases collapse onto one host. The frontend, middle end (such as it is), and backend all live in `intercalc.sh`, and the IR is ad hoc: a parse tree in parallel arrays, used once and thrown away. LLVM trades that simplicity for the modularity that makes it usable across hundreds of language and target combinations.

## What LLVM IR looks like

LLVM IR is a typed, low-level, SSA-form language that resembles a portable assembly. A trivial example:

    define i32 @add(i32 %a, i32 %b) {
      %r = add i32 %a, %b
      ret i32 %r
    }

The same IR can be printed as text (`.ll`), serialised as a binary bitcode file (`.bc`), or held in memory as a C++ object graph. About sixty instruction opcodes cover the ground from loads and stores through arithmetic, control flow, and aggregate manipulation. SSA form (each variable is assigned exactly once) makes most optimisation passes simpler to write.

Our INTERCAL compiler has nothing like this. Every statement becomes assembly directly, with no IR step in between. [middle-end-and-optimisation.md](middle-end-and-optimisation.md) explains why we made that choice and what it costs us.

## The pass manager

LLVM optimisations are organised as a pipeline of *passes*, each a class that takes an IR module (or function, or basic block) and rewrites it. The pass manager runs them in a configured order. Some examples:

- Constant folding (we do a tiny version of this in `eval_const`).
- Dead-code elimination (we have a dedicated form for the abstain flag).
- Common subexpression elimination, loop-invariant code motion, induction-variable simplification, register promotion of stack slots.
- Inlining, scalar replacement of aggregates, sparse conditional constant propagation, global value numbering.
- Vectorisation, loop unrolling, auto-vectorisation.

A new pass is a few hundred lines of C++ that subclasses one of the pass base classes and overrides `runOnFunction` or its newer pass-manager equivalent. Reading an existing pass is the standard way to learn how to write one. `llvm/lib/Transforms/Scalar/` is a good directory to browse for short, self-contained examples.

## Repo layout, briefly

The main directories in `llvm-project`:

    clang/                 The C/C++/Objective-C frontend
    llvm/                  The middle end and backends
      lib/IR/              The IR data structures
      lib/Transforms/      Optimisation passes (Scalar, IPO, Vectorize, ...)
      lib/CodeGen/         Target-independent backend infrastructure
      lib/Target/<arch>/   Per-target backend (X86, AArch64, RISCV, AMDGPU, ...)
      lib/Analysis/        Analyses passes use (alias, scalar evolution, ...)
      docs/                User-facing documentation
    lld/                   The LLVM linker
    lldb/                  The LLVM debugger
    mlir/                  Multi-Level IR, a higher-level extensible IR framework
    flang/                 The Fortran frontend
    polly/                 Polyhedral loop optimisations
    libcxx/, libc/         Runtime libraries

Most of what a beginner cares about is in `llvm/lib/Transforms/` (passes), `llvm/lib/Target/` (backends), and `clang/lib/` (the C++ frontend). The `docs/` directory has a reference for every feature; `llvm/docs/LangRef.rst` is the IR specification.

## How LLVM compares to our INTERCAL compiler

| Aspect | INTERCAL compiler (this repo) | LLVM |
|--------|-------------------------------|------|
| IR | None (parse tree only) | LLVM IR, SSA-form, typed |
| Frontends | One (INTERCAL) | Many (Clang, rustc, Swift, ...) |
| Backends | Two (ARM64, x86-64) | Many (X86, AArch64, RISC-V, GPU, WASM, ...) |
| Optimisations | Constant folding, dead-flag elimination, peephole | Hundreds of passes |
| Codebase size | ~2000 lines zsh + a few thousand lines assembly | ~10 million lines C++ |
| Build | `cc -x assembler -` | CMake + ninja, ~30 minutes |

The right way to read this table is not "INTERCAL is small, LLVM is big" but "everything LLVM does, our INTERCAL compiler also does, just at orders of magnitude less effort, with orders of magnitude less to optimise". The same conceptual machinery is in both.

## How to read LLVM source for the first time

A short order of attack:

1. Read `llvm/docs/LangRef.rst` to learn the IR vocabulary. Roughly the same effort as reading our [appendix-grammar.md](appendix-grammar.md).
2. Browse `llvm/lib/Transforms/Scalar/` for a small pass like `ADCE.cpp` (Aggressive Dead Code Elimination) or `ConstantHoisting.cpp`. Each is a self-contained ~500-line file.
3. Read one of the per-target backends. `llvm/lib/Target/RISCV/` is comparatively new and concise.
4. For Clang, start with `clang/lib/Parse/Parser.cpp` to see a real recursive-descent parser at production scale. A pleasant continuity with our [parser-theory.md](parser-theory.md).

## Where to go next

- The official [Getting Started with LLVM](https://llvm.org/docs/GettingStarted.html) page if you want to build LLVM locally.
- [The Architecture of Open Source Applications: LLVM](https://aosabook.org/en/v1/llvm.html), an essay by Chris Lattner, the original LLVM author. Ten pages, very readable, complements this chapter.
- [contributing-to-production-compilers.md](contributing-to-production-compilers.md) for how to land a first patch.
- [gcc-overview.md](gcc-overview.md) and [rustc-overview.md](rustc-overview.md) for the two compilers most beginners will reach for next.
