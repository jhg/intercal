# rustc, in shape

rustc is the Rust compiler. The source lives at <https://github.com/rust-lang/rust>. The authoritative companion document for anyone reading or modifying the compiler is the [rustc-dev-guide](https://rustc-dev-guide.rust-lang.org/), which the rest of this chapter assumes you will eventually read.

rustc is interesting as a third reference point because it has neither LLVM's single IR nor GCC's three. It has *four*: HIR, THIR, MIR, and (via codegen) LLVM IR. Each layer exists to make a specific job easier.

## The pipeline, end to end

Rust source goes through this sequence:

    source
      → tokens          (lexer)
      → AST             (parser)
      → HIR             (lowering, after macro expansion and name resolution)
      → THIR            (lowering, after type checking)
      → MIR             (lowering, for borrow checking and optimisation)
      → LLVM IR         (codegen)
      → machine code    (LLVM)

Six lowering steps, four named IRs. Each is the right shape for the work that happens at that level.

## What each IR is for

**AST** is what the user wrote. Macros are not yet expanded. Names are not yet resolved. The parser produces it; almost nothing else touches it.

**HIR** (High-level Intermediate Representation) is the AST after macro expansion, name resolution, and minor desugaring. Lifetimes that the user elided are now explicit. HIR is what most compiler passes see during type checking. It is still close enough to the source that error messages can point at sensible spans.

**THIR** (Typed High-level IR) is HIR after type checking. Method calls are resolved to specific function references, autoref/autoderef coercions are inserted, overloaded operators are replaced with explicit calls. THIR exists as a stepping stone: it is fully typed but still tree-shaped, which makes it the right starting point for building MIR.

**MIR** (Mid-level IR) is the most distinctive piece of rustc's design. MIR is a control-flow graph in basic blocks, each containing simple typed statements with explicit drops, moves, and references. This is where Rust's *borrow checker* runs. Borrow checking on MIR (rather than on HIR or AST) is what made non-lexical lifetimes possible. MIR is also the IR for a growing set of compiler-internal optimisations, constant evaluation, and the recent const-generic and dataflow analyses.

**LLVM IR** is what rustc emits when it is finally ready to hand off to the LLVM backend. The codegen layer (`rustc_codegen_llvm`) walks MIR and emits LLVM IR. There are alternative codegen backends: `rustc_codegen_cranelift` for fast debug builds, and `rustc_codegen_gcc` for using GCC as the backend instead of LLVM.

## Why so many IRs

Each lowering removes ambiguity that was useful at a higher level but inconvenient at a lower one.

- AST → HIR removes macros and name ambiguities. A pass at HIR level does not have to worry about whether `vec!` is a macro or a function call.
- HIR → THIR removes type ambiguities. A pass at THIR level does not have to re-do trait resolution.
- THIR → MIR turns the tree into a control-flow graph. A pass at MIR level can use dataflow algorithms naturally. The borrow checker, in particular, is much easier to express on MIR than on HIR.
- MIR → LLVM IR removes Rust-specific concerns (drop semantics, panics, generics). LLVM does not need to know about lifetimes or traits.

Compare this with LLVM (one IR for everything) and GCC (three IRs at different levels of abstraction). rustc sits closer to GCC's school of thought than to LLVM's, but with more semantic information preserved at each level.

## Repo layout

The Rust workspace is a Cargo monorepo. The compiler proper is in `compiler/` as a set of crates:

    compiler/
      rustc_lexer/             Token-level scanning
      rustc_parse/             AST construction
      rustc_ast/               AST data structures
      rustc_expand/            Macro expansion
      rustc_resolve/           Name resolution
      rustc_hir/               HIR data structures
      rustc_hir_typeck/        Type checking on HIR
      rustc_mir_build/         THIR → MIR construction
      rustc_borrowck/          Borrow checking on MIR
      rustc_mir_transform/     MIR optimisation passes
      rustc_codegen_ssa/       Backend-independent codegen scaffolding
      rustc_codegen_llvm/      LLVM backend
      rustc_driver/            The CLI driver, `rustc` itself
      rustc_session/           Compilation-session state, error reporting
      ...
    library/                   Standard library and core
    src/tools/                 Cargo, rustfmt, clippy, miri, ...
    src/doc/                   User-facing documentation
    src/etc/                   Build infrastructure and helpers

The dev guide and the in-repo `compiler/rustc_*/README.md` files are the doors into each crate. A guided reading order (from the rustc-dev-guide):

1. `compiler/rustc_lexer/`: a tiny scanner, easy to read.
2. `compiler/rustc_parse/`: hand-written recursive-descent parser at production scale.
3. `compiler/rustc_hir_typeck/expr.rs`: type-checking expressions, conceptually accessible.
4. `compiler/rustc_borrowck/`: the borrow checker, where Rust's distinctive ideas live.
5. `compiler/rustc_codegen_llvm/`: LLVM IR emission.

## How rustc compares to LLVM and GCC

| Aspect | rustc | LLVM (used by Clang) | GCC |
|--------|-------|----------------------|-----|
| Frontend language | Rust only | Many (Clang, Swift, Julia, ...) | Many (C, C++, Fortran, Ada, ...) |
| IR layers | 4 (HIR, THIR, MIR, LLVM IR) | 1 (LLVM IR) | 3 (GENERIC, GIMPLE, RTL) |
| Distinctive analyses | Borrow checker on MIR | None Rust-specific | None Rust-specific |
| Backends | LLVM (default), Cranelift, GCC | Many | Many |
| Implementation language | Rust (self-hosted) | C++ | C and C++ |
| Codebase | ~3 million lines Rust | ~10 million lines C++ | ~15 million lines mixed |

rustc is an unusual case: it is itself self-hosted (the compiler is written in Rust), like our INTERCAL ambition. rustc bootstrapped through OCaml; it now compiles itself in three stages, the first of which uses a previous stable rustc.

## How rustc compares to our INTERCAL compiler

The INTERCAL compiler bootstraps the same way rustc does. zsh plays the role OCaml played for early Rust. After self-hosting, both projects can build themselves.

The differences are scale and the existence of an IR pipeline. rustc has four levels of IR; our compiler has none. rustc has a borrow checker and a type system; we have four numeric types and the politeness rule. rustc emits LLVM IR; we emit ARM64 or x86-64 assembly directly.

The conceptual map is the same. Lex, parse, check, lower, emit. Reading rustc with the vocabulary from this book in mind, you will see the same shape, just with each phase greatly enlarged and each IR level made explicit.

## Reading the rustc-dev-guide

The [rustc-dev-guide](https://rustc-dev-guide.rust-lang.org/) is the single most useful document for understanding rustc. It is maintained alongside the compiler, kept in sync with the source, and explicitly written for new contributors. A reasonable order:

1. *Overview of the Compiler*: the front-to-back tour.
2. *The HIR*, *The THIR*, *The MIR*: the IR descriptions.
3. *Type Checking* and *Trait Solving*: the conceptual core of the type system.
4. *Borrow Checking* and *Drop elaboration*: the Rust-specific bits.
5. *Code Generation*: how MIR becomes LLVM IR and then machine code.

After this book and the dev guide, you have the vocabulary to start opening compiler issues and reading the code that fixes them.

## Where to go next

- [contributing-to-production-compilers.md](contributing-to-production-compilers.md) for how to land a first patch on rustc.
- [llvm-overview.md](llvm-overview.md) for the backend rustc uses by default.
- [gcc-overview.md](gcc-overview.md) for the alternative backend (`rustc_codegen_gcc`).
- [from-intercal-to-real-compilers.md](from-intercal-to-real-compilers.md) for the bridge from this book's content to production-compiler work.
