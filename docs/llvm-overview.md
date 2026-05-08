# LLVM, in shape

LLVM is the modular compiler infrastructure that powers Clang, Swift, Rust (by default), Julia, Crystal, and a long tail of language frontends and analysis tools. If you have used `clang` to compile C, you have used LLVM. The codebase lives at <https://github.com/llvm/llvm-project>.

This chapter is an orientation map. Enough to walk into the LLVM source tree and know what each directory is for, what to read first, and how the architecture maps to the smaller compiler in this repository.

The single most useful framing of LLVM is: it is not a compiler. It is a kit of compiler parts, with one IR connecting them, and a discipline that anything which speaks LLVM IR can be plugged in. Clang, rustc, Swift, and the rest are consumers of the kit, each contributing their own frontend and consuming the IR plus backends LLVM provides.

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

## LLVM IR in more detail

LLVM IR has a hierarchical structure:

- **Module**: a translation unit. One file in, one Module out. Contains functions, global variables, type declarations, metadata.
- **Function**: a single function. Contains basic blocks, parameter list, return type, attributes, debug info.
- **BasicBlock**: a maximal sequence of instructions with a single entry point and a single exit point (terminator). A function is a directed graph of BasicBlocks.
- **Instruction**: an SSA operation, with operands (other Values) and a result Value (or void).
- **Value**: anything that can be referenced as an operand. Includes Instructions, Constants, function arguments, basic block addresses, etc.

Types in LLVM IR are explicit:

- Integers `i1`, `i8`, `i16`, `i32`, `i64`, `i128`, with signedness expressed by the operation rather than the type.
- Floating-point: `half`, `float`, `double`, `fp128`, and a few platform-specific exotics.
- `ptr` (opaque pointer, since LLVM 15; before that, typed pointers like `i32*` carried the pointee type).
- Aggregate types: arrays `[N x T]`, structs `{T1, T2, ...}`, vectors `<N x T>`.
- Function types `T (Args)`.
- Metadata `!N` for non-semantic information attached to instructions.

The opaque pointer transition is itself a useful piece of LLVM history. Until LLVM 15, pointers carried their pointee type, which seemed natural but was the source of many bugs (loads would type-mismatch with stores in subtle ways during optimisation). The IR was changed to make pointers untyped; loads and stores carry their type explicitly. The transition took years and required rewriting many optimisation passes.

Memory model: LLVM IR has a memory model based on C/C++11. Loads and stores can be marked atomic with an ordering (relaxed, acquire, release, acquire-release, sequentially-consistent). Non-atomic accesses can race; atomic accesses cannot.

SSA with a twist: LLVM IR uses explicit `alloca` instructions in function entry blocks plus `load`/`store` to model variables that have addresses. This avoids requiring the frontend to insert phi nodes for normal local variables. The `mem2reg` pass promotes alloca'd locals to SSA registers when possible, eliminating the loads and stores. This is a famous trick: frontends emit "easy" IR, the optimiser cleans it up.

## The pass manager

LLVM optimisations are organised as a pipeline of *passes*, each a class that takes an IR module (or function, or basic block) and rewrites it. The pass manager runs them in a configured order. Some examples:

- Constant folding (we do a tiny version of this in `eval_const`).
- Dead-code elimination (we have a dedicated form for the abstain flag).
- Common subexpression elimination, loop-invariant code motion, induction-variable simplification, register promotion of stack slots.
- Inlining, scalar replacement of aggregates, sparse conditional constant propagation, global value numbering.
- Vectorisation, loop unrolling, auto-vectorisation.

LLVM has had two pass managers in its history. The **Legacy Pass Manager** (LPM) was the original, used until LLVM 13. The **New Pass Manager** (NPM) was developed in parallel since 2015 and became default in 2021. Both still ship; LPM is being phased out.

The differences matter for somebody reading or writing LLVM passes:

- LPM: passes inherit from `FunctionPass`, `ModulePass`, `LoopPass`, etc. Order and analysis dependencies are declared via `getAnalysisUsage`.
- NPM: passes are mixin classes implementing `run(Function&, FunctionAnalysisManager&)` and friends. Analysis caching is more explicit. Pipeline construction is more flexible (a `PassBuilder` produces the pipeline programmatically).

A typical pipeline at `-O2` runs roughly 200 passes, in carefully chosen order, often with several passes repeated. The default pipeline is built in `llvm/lib/Passes/PassBuilderPipelines.cpp`. For somebody learning the optimiser, reading that file is the fastest way to see what production really runs.

The phases of the pipeline:

1. **Early simplification**: `mem2reg`, `simplifyCFG`, `instcombine`. Cleans the frontend's output.
2. **Canonicalisation**: bring code into a normalised form so later passes can pattern-match.
3. **Scalar optimisations**: CSE, GVN, SCCP, DCE. The classical optimisations.
4. **Loop optimisations**: LICM, indvar simplification, loop unrolling, loop vectorisation.
5. **Inlining + interprocedural**: function inlining, argument promotion, dead-argument elimination.
6. **Late simplification**: clean up after inlining.
7. **Vectorisation**: SLP and loop vectorisers.
8. **Lowering**: prepare for backend.

Each phase has multiple passes; the order within a phase is itself a topic. Adding a new optimisation usually means inserting it in the right place, which depends on what the surrounding passes need to see.

A new pass is a few hundred lines of C++ that subclasses one of the pass base classes and overrides `runOnFunction` or its newer pass-manager equivalent. Reading an existing pass is the standard way to learn how to write one. `llvm/lib/Transforms/Scalar/` is a good directory to browse for short, self-contained examples. `ADCE.cpp` (Aggressive Dead Code Elimination), `ConstantHoisting.cpp`, `GVN.cpp`, `SimplifyCFG.cpp` are all approachable.

## Backends: SelectionDAG and GlobalISel

LLVM has two complete backend infrastructures, coexisting:

**SelectionDAG** is the original. Pipeline: LLVM IR → SelectionDAG → SelectionDAG (legalised) → SelectionDAG (combined) → MachineInstr → MCInst → object file.

The DAG is a directed acyclic graph representation of one basic block at a time. Pattern-matching during selection picks instructions from the target's instruction set, with patterns specified in TableGen. Multiple per-target passes (legalize, combine, select) progressively narrow the DAG until everything maps to a target instruction.

SelectionDAG is the way most older LLVM backends do instruction selection. The downside: per-block scope limits the optimisations possible during selection, and global decisions (register allocation, instruction scheduling) happen on the post-DAG MachineInstr representation.

**GlobalISel** is the newer infrastructure, started around 2016. Pipeline: LLVM IR → MIR (Machine IR, generic) → MIR (legalised) → MIR (regbank-selected) → MIR (instruction-selected) → object.

GlobalISel works on Machine IR (an SSA-form IR with target-generic operations) throughout. Each pass is explicit (not a phase of the DAG). The result is more uniform across targets and amenable to global optimisations during selection.

Adoption: AArch64 uses GlobalISel by default. x86-64 and others are gradually transitioning. Some targets still use only SelectionDAG.

For a reader, the contrast between the two is illuminating. SelectionDAG is older and has more accumulated wisdom; GlobalISel is newer and has cleaner architecture. Both are still in production. The transition is a multi-year effort.

## TableGen

A unique LLVM technology: TableGen is a domain-specific language for describing target machines. It is used for instruction definitions, register sets, calling conventions, instruction scheduling, and pattern-matching rules.

A TableGen instruction definition looks like:

    def ADD32rr : I<0x01, MRMDestReg, (outs GR32:$dst),
                    (ins GR32:$src1, GR32:$src2),
                    "add{l}\t{$src2, $dst|$dst, $src2}",
                    [(set GR32:$dst, (add GR32:$src1, GR32:$src2))]>;

That is the x86 ADD32rr (32-bit register-to-register add) instruction. The fields name encoding bits, operand classes, assembly text, and a SelectionDAG pattern. The TableGen compiler reads files like this and produces C++ that LLVM links.

TableGen is large. The x86 backend's TableGen sources alone are ~50,000 lines describing every x86 instruction LLVM supports. Reading TableGen is its own skill; the syntax is dense and the resolution rules are non-obvious. The benefit is that the same description drives instruction selection, encoding, scheduling, disassembly, and assembly parsing. A single source of truth for "what does this CPU do".

For a reader, TableGen is one of LLVM's distinctive features. The same idea is reinvented elsewhere (Cranelift's ISLE, Go's `.rules` files, GCC's machine descriptions) but TableGen is the most baroque and the most complete.

## Register allocators

LLVM ships multiple register allocators, selectable per build:

- **greedy** (default): the production allocator, sophisticated, written for code quality.
- **basic**: simpler, mostly historical.
- **fast**: very fast, low quality, used in `-O0` debug builds.
- **PBQP**: a partitioned-Boolean-quadratic-programming allocator, more research than production.

The greedy allocator is the heart of `-O2` codegen. Algorithm sketch: prioritise live ranges by spill cost; for each, try to assign a register; if conflicts arise, split the range or spill it. The algorithm is not pure graph-colouring (Chaitin's classical formulation); it is "register allocation as a sequence of decisions ordered by priority".

For a reader who wants to learn register allocation, the LLVM greedy allocator is large (>10,000 lines) and dense. Cranelift's `regalloc2` is more legible; OCaml's linear-scan is the simplest production example. Reading them in that order is a good progression.

## MC layer

The MC layer (`llvm/lib/MC`) handles low-level encoding and decoding of instructions. It is what turns MachineInstr into bytes (or assembly text), and what parses assembly text back into MachineInstr.

Why a separate layer? Because there are many places where instruction-level work happens: the assembler (`llvm-mc`), the disassembler, the inline assembler in Clang, the JIT (which encodes instructions directly to memory), the integrated assembler (which emits object code from LLVM directly without going through `as`).

The MC layer is a clean abstraction over "instruction in bytes vs instruction in text vs instruction as a structured object", with each consumer parameterising what it needs.

## MLIR: the IR generalised

MLIR (Multi-Level IR) was added to the LLVM project in 2019. It is a framework for describing IRs, with multiple "dialects" coexisting in the same module.

The key ideas:

- A dialect is a namespace of operations. The `arith` dialect has `arith.addi`, `arith.mulf`. The `affine` dialect has `affine.for`, `affine.if`. The `linalg` dialect has high-level linear-algebra operations. Each dialect has its own semantics.
- Dialects can be lowered into other dialects. `linalg` lowers to `affine`, `affine` lowers to `scf`, `scf` lowers to standard control flow, eventually everything lowers to LLVM dialect, which is one-to-one with LLVM IR.
- The same MLIR module can simultaneously contain multiple dialects, each capturing the right level of abstraction for the part of the program it describes.

MLIR is used in TensorFlow (for tensor algebra), IREE (for ML compilation), Mojo (the language), Flang (the Fortran frontend). It is the framework people are reaching for when they want to build a domain-specific compiler that benefits from LLVM's infrastructure.

For a reader, MLIR is the next step beyond "IR design". It generalises the idea of "lower from one IR to another" into a framework, parametrising both the source and target IRs. The dialect and lowering machinery is a useful study even if you do not immediately need to use MLIR.

## Subprojects

The LLVM project (`llvm-project`) is now a monorepo containing multiple related subprojects:

- **llvm/**: the IR, optimiser, backends, MC layer.
- **clang/**: C/C++/Objective-C/CUDA/HIP/HLSL frontend.
- **clang-tools-extra/**: clang-tidy, clang-format, clang-include-fixer.
- **lld/**: the LLVM linker, drop-in replacement for ld with much better speed.
- **lldb/**: the LLVM debugger.
- **compiler-rt/**: runtime libraries (sanitisers, profile, builtins).
- **libcxx/**: C++ standard library.
- **libcxxabi/**: low-level C++ runtime support.
- **libunwind/**: stack unwinding.
- **mlir/**: Multi-Level IR.
- **flang/**: Fortran frontend.
- **polly/**: polyhedral loop optimiser.
- **bolt/**: Binary OptimisaTion (post-link binary optimiser; profile-guided basic-block reordering for already-compiled binaries).
- **openmp/**: OpenMP runtime.
- **libc/**: an experimental LLVM-based libc.
- **cross-project-tests/**: integration tests across subprojects.

Each subproject is a candidate for its own chapter in a more ambitious treatment. For our purposes, knowing they exist and what they do is enough.

## Repo layout, briefly

The main directories in `llvm-project`:

    clang/                 The C/C++/Objective-C frontend
    llvm/                  The middle end and backends
      lib/IR/              The IR data structures
      lib/Transforms/      Optimisation passes (Scalar, IPO, Vectorize, ...)
      lib/CodeGen/         Target-independent backend infrastructure
      lib/Target/<arch>/   Per-target backend (X86, AArch64, RISCV, AMDGPU, ...)
      lib/Analysis/        Analyses passes use (alias, scalar evolution, ...)
      lib/MC/              Instruction-level encoding/decoding
      lib/Passes/          Pipeline construction
      docs/                User-facing documentation
      utils/TableGen/      The TableGen compiler
    lld/                   The LLVM linker
    lldb/                  The LLVM debugger
    mlir/                  Multi-Level IR
    flang/                 The Fortran frontend
    polly/                 Polyhedral loop optimisations
    bolt/                  Post-link binary optimiser
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
5. For the pass manager, read `llvm/lib/Passes/PassBuilderPipelines.cpp` to see what `-O2` actually does.
6. For TableGen, pick a small target description like `llvm/lib/Target/RISCV/RISCV.td` and trace a simple instruction definition.

## How to contribute

Since 2024, LLVM uses GitHub PRs. The migration from Phabricator was completed that year. The contributing flow:

    git clone https://github.com/llvm/llvm-project
    cd llvm-project
    git checkout -b my-fix
    # ... edit, test ...
    git push fork my-fix
    # open PR on GitHub

Reviewers are subscribed by area; tag the right ones based on the file paths you touched. Every patch needs at least one approval before merge. Style is enforced by clang-format. Tests live in `llvm/test/` (lit-based, FileCheck-driven) or `clang/test/` etc.

Beginner-friendly issues are tagged `good first issue` on <https://github.com/llvm/llvm-project/issues>. Categories:

- Documentation patches.
- Small optimiser bugs (often missing patterns in `InstCombine` or `SimplifyCFG`).
- Missing diagnostics or improved diagnostics in Clang.
- TableGen rule additions (target-specific instruction selection).
- Simple test additions.

LLVM has a Discourse forum at <https://discourse.llvm.org/> where new contributors ask questions and architecture discussions happen.

## Where to go next

- The official [Getting Started with LLVM](https://llvm.org/docs/GettingStarted.html) page if you want to build LLVM locally.
- [The Architecture of Open Source Applications: LLVM](https://aosabook.org/en/v1/llvm.html), an essay by Chris Lattner, the original LLVM author. Ten pages, very readable, complements this chapter.
- The LLVM Developer Meetings (twice yearly, on YouTube) for talks on every part of the project.
- LLVM Weekly newsletter at <https://llvmweekly.org/> for the active development cadence.
- "Engineering a Compiler" by Cooper and Torczon for the textbook treatment of what LLVM does.
- [contributing-to-production-compilers.md](contributing-to-production-compilers.md) for how to land a first patch.
- [cranelift-overview.md](cranelift-overview.md) for the deliberate counterpoint to LLVM.
- [gcc-overview.md](gcc-overview.md) and [rustc-overview.md](rustc-overview.md) for the two compilers most beginners will reach for next.
