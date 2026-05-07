# GCC, in shape

GCC is the GNU Compiler Collection, the original free-software compiler suite. It has compiled most of the Linux kernel, most of the GNU userland, and a sizeable fraction of every Unix-shaped piece of software for thirty-five years. Its source lives at <https://gcc.gnu.org/git.html> (mirrored on GitHub at <https://github.com/gcc-mirror/gcc>).

LLVM is the modular newcomer. GCC is the older system that was already there, and its design is correspondingly different. The single most important difference: GCC uses *three* intermediate representations stacked on top of each other, not one.

## The three IRs

A C source file goes through this pipeline inside GCC:

    source → AST → GENERIC → GIMPLE → RTL → assembly

Each arrow is a translation pass, sometimes a sequence of them. Each box on the left is more abstract; each box on the right is closer to the target machine.

- **GENERIC** is the language-independent abstract syntax tree. The frontend (C, C++, Fortran, Ada, Go, D, Rust-via-gccrs) produces GENERIC trees that capture the program's shape and types. GENERIC is still recognisably what the user wrote: scopes, expressions, declarations.
- **GIMPLE** is a three-address form derived from GENERIC. Every expression is broken down into operations of at most three operands, and control flow is normalised. This is where most language-independent optimisations happen: constant propagation, dead-code elimination, loop transformations, vectorisation, link-time optimisation. GIMPLE itself has multiple sub-forms (high gimple, low gimple) that progressively expose more of the eventual machine model.
- **RTL** (Register Transfer Language) is GCC's low-level IR. It is much closer to the actual instruction set and is where instruction selection, register allocation, and scheduling happen. RTL describes individual machine operations with precise side-effect information, drawn from each target's `.md` machine description file.

Compare with LLVM, which has only LLVM IR between frontends and backends. GCC's choice means more translation steps, but also more places to apply optimisations at the right level of abstraction.

## How frontends fit in

GCC supports several frontends, each living in its own subdirectory:

    gcc/c-family/    Shared C/C++/ObjC infrastructure
    gcc/c/           C frontend
    gcc/cp/          C++ frontend
    gcc/fortran/     Fortran (gfortran)
    gcc/ada/         Ada (GNAT)
    gcc/d/           D
    gcc/go/          Go (gccgo)
    gcc/rust/        Rust (gccrs, in active development)

Each frontend parses its language and emits GENERIC trees. From that point onwards the pipeline is shared. A bug fix in GIMPLE-level dead-code elimination benefits every frontend simultaneously.

## How backends fit in

Each target architecture has a `gcc/config/<arch>/` directory containing a *machine description*: a Lisp-like text file (`.md`) that names every instruction the architecture supports, the patterns it can match against RTL, the costs to attach to it, and the constraints on operand placement. A separate C source file implements target-specific hooks that the rest of GCC calls into for things like calling-convention details and pipeline scheduling.

Adding a new target is "write the machine description and the hooks". Adding a new instruction within an existing target is "edit the machine description". Both are non-trivial but bounded.

## Repo layout

    gcc/                   Compiler proper
      c-family/, c/, cp/, fortran/, ada/, ...   Frontends
      tree-*.c, gimple-*.c, ipa-*.c              GIMPLE-level optimisation passes
      rtl-*.c, cse.c, combine.c, ira.c, lra.c   RTL-level passes (CSE, register allocation)
      config/<arch>/                             Per-target machine description and hooks
      doc/                                        User and internals documentation
    libstdc++-v3/         The GNU C++ standard library
    libgcc/               Low-level runtime support
    libsanitizer/         AddressSanitizer, ThreadSanitizer, etc.
    contrib/              Tooling and helpers

The `gcc/doc/` directory is the canonical reference. The `gccint` manual (also viewable at <https://gcc.gnu.org/onlinedocs/gccint/>) documents GIMPLE, RTL, and the internal APIs.

## How GCC compares to LLVM

The big architectural distinction is one IR versus many. LLVM optimises everything in LLVM IR; GCC optimises some things at the GIMPLE level (where the program is still abstract) and others at the RTL level (where machine model matters). The result is similar end-to-end, but the locus of work is different.

A few practical consequences:

- GCC's GIMPLE-level passes are often easier to write than the equivalent LLVM passes because GIMPLE is closer to the source.
- GCC's RTL handles target-specific concerns at a layer LLVM puts inside its backends. Reading a GCC backend means reading a `.md` file; reading an LLVM backend means reading a TableGen file plus C++.
- LLVM's pass manager and modular library design make it easier to embed in tools (linters, static analysers, incremental builds). GCC is more monolithic.
- GCC has stronger support for some legacy languages (Fortran, Ada) and target architectures.

Neither is "better". They are different points in the design space.

## How GCC compares to our INTERCAL compiler

| Aspect | INTERCAL compiler | GCC |
|--------|-------------------|-----|
| IR levels | 1 (parse tree, transient) | 3 (GENERIC → GIMPLE → RTL) |
| Frontends | 1 (INTERCAL) | 8+ (C, C++, Fortran, Ada, Go, D, Rust-via-gccrs, Modula-2) |
| Backends | 2 (ARM64, x86-64) | 50+ (everything from x86-64 to obscure embedded chips) |
| Optimisation | a few local passes | hundreds of GIMPLE and RTL passes |
| Codebase | ~2000 lines zsh + assembly | ~15 million lines, mostly C++ |
| Build | `cc -x assembler -` | autoconf + make, ~hours |

Same shape, different scale. Same conceptual phases, more layers of optimisation, more frontends, more backends.

## Reading GCC source for the first time

A practical order:

1. Read `gcc/doc/gccint.texi` (the gccint manual), specifically the chapters on GENERIC, GIMPLE, and RTL. Roughly equivalent to reading [appendix-grammar.md](appendix-grammar.md), [code-generation.md](code-generation.md), and [calling-conventions.md](calling-conventions.md) in this book.
2. Browse `gcc/tree-cfg.c` for a sense of how GIMPLE control-flow graphs are built. ~1500 lines, well-commented.
3. Read one of the GIMPLE optimisation passes. `gcc/tree-ssa-dce.c` (dead-code elimination on SSA) is a good candidate.
4. For backends, `gcc/config/aarch64/aarch64.md` is a relatively modern machine description and is more readable than older ones.

## Where to go next

- [The GCC Internals manual](https://gcc.gnu.org/onlinedocs/gccint/) is the canonical reference; treat the rest of this chapter as orientation.
- [contributing-to-production-compilers.md](contributing-to-production-compilers.md) for how to interact with the GCC mailing-list-driven review process, which differs from LLVM's GitHub-PR model.
- [llvm-overview.md](llvm-overview.md) and [rustc-overview.md](rustc-overview.md) for the alternatives.
