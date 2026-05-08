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

## GENERIC in detail

GENERIC is GCC's language-independent tree-form IR. Each node is a `tree`, a tagged union represented at the C level as a pointer with type tag bits.

What GENERIC captures:

- Declarations (variables, functions, types, namespaces).
- Expressions (binary, unary, calls, references, conversions).
- Statements (compound, if, loops, returns).
- Types (integer, floating, pointer, struct, function, ...).
- Scopes and bindings.

The shape preserves the source-level structure. A C `if (a < b) x++; else y++;` becomes a `COND_EXPR` node with three children. A C++ template instantiation produces GENERIC trees for the instantiation.

What is unusual: GENERIC is the same data structure regardless of source language. All of C, C++, Fortran, Ada, Go, D produce GENERIC. Each frontend may extend the node set with language-specific nodes, but the core tree representation is shared. This is part of what enables language interoperability in GCC: the runtime FFI layers can be expressed in GENERIC.

Because GENERIC stays close to the source, it is not optimised aggressively. Most algorithmic work happens after lowering to GIMPLE.

## GIMPLE in detail

GIMPLE is GCC's three-address IR. The lowering from GENERIC to GIMPLE is called "gimplification" and happens in `gcc/gimplify.cc`. The job of gimplification: take the structured tree representation and break it into simple statements with at most three operands.

GIMPLE has three sub-forms:

- **High GIMPLE**: structured control flow (compound statements, if/else, loops) is preserved. Easier to transform without losing source-level reasoning.
- **Low GIMPLE**: control flow is lowered to gotos and conditional gotos; structured constructs are gone. Closer to the eventual control-flow graph.
- **SSA GIMPLE**: variables are renamed so each definition is unique. Phi nodes appear at control-flow joins. This is where most optimisations operate.

GIMPLE statements are simpler than GENERIC nodes: an assignment `t = a + b * c` decomposes into `tmp = b * c; t = a + tmp`. The result is a flat list of three-address operations within each function.

Conversion to SSA: GCC's algorithm is a variant of Cytron-style iterated dominance frontiers, but with refinements specific to GIMPLE (handling memory references, partial updates, variable scoping). The implementation lives in `gcc/tree-into-ssa.cc`.

## GIMPLE optimisation passes

The list of GIMPLE-level optimisations in GCC is enormous. Around 250 passes are defined in `gcc/passes.def`, organised into a pipeline.

The categories:

- **Tree-SSA passes**: operate on SSA-form GIMPLE. CCP (constant propagation), DSE (dead store elimination), DCE (dead code elimination), DOM (dominator-based optimisations), VRP (value range propagation), reassoc (associative reordering), forwprop (forward propagation), backprop (backward propagation), TER (temporary expression replacement).
- **Loop optimisations**: LIM (loop-invariant motion), unroll, ivcanon (induction variable canonicalisation), vect (vectoriser), parloops (auto-parallelisation), graphite (polyhedral, optional).
- **Inter-procedural (IPA)**: cross-function passes.
- **Lowering passes**: progressively lower abstractions (e.g., `expand_omp_for` for OpenMP loops).

Reading a single GIMPLE pass is approachable. Reading the whole pipeline is a long-term project.

## IPA: inter-procedural analysis

What distinguishes GCC's middle-end is the depth of inter-procedural analysis. IPA passes see the entire program (or a large chunk of it via LTO) and reason across function boundaries:

- **inline**: function inlining. Heuristic-driven, cost-modelled, with feedback from later passes.
- **cp** (constant propagation across calls): if a function is always called with the same constant argument, propagate it.
- **devirt** (devirtualisation): determine which virtual function call resolves to which concrete callee, replace indirect calls with direct ones.
- **icf** (identical code folding): merge functions with identical machine code.
- **pure-const**: classify functions as pure (no side effects) or const (no observable behaviour beyond return value), enabling further optimisations at call sites.
- **sra** (scalar replacement of aggregates): split a struct argument into separate scalar arguments when only some fields are used.
- **fnsplit**: split a function into hot and cold parts to improve inlining decisions.
- **WHOPR** (Whole-Program Optimisation): the LTO pipeline. Partitions the program for parallel optimisation, runs IPA across all partitions, merges results.

LTO in GCC predates LLVM's by years. The relevant flag is `-flto`. The pipeline is sufficiently mature that GCC LTO is the default for many production Linux distros.

For a reader, IPA is the area most clearly distinguishing GCC from LLVM. LLVM has IPA passes (`lib/Transforms/IPO/`) but the framework is less developed; GCC's IPA infrastructure has decades of polish.

## RTL in detail

After GIMPLE optimisation, GCC lowers to RTL: Register Transfer Language. This is the low-level IR.

An RTL expression looks like:

    (set (reg:SI 100) (plus:SI (reg:SI 101) (const_int 1)))

Read aloud: "set the 32-bit register 100 to the sum of register 101 and the constant 1". The Lisp-like syntax is original; RTL was modelled on a 1980s register-transfer notation.

RTL has two phases:

- **Pre-reload RTL**: uses pseudo-registers (virtual registers, unbounded numbering). Optimisations like CSE, GVN, jump optimisation, loop optimisation operate here.
- **Post-reload RTL**: physical registers assigned. Spill code inserted. Closer to assembly.

The transition is driven by **register allocation**. Until 2013, GCC used a pass called "reload" that rewrote pre-reload RTL to post-reload RTL by allocating registers and inserting spills. Reload was complicated and a frequent source of bugs. In 2013, GCC introduced **LRA** (Local Register Allocator) as a simpler replacement. LRA is the default register allocator now.

RTL passes in roughly the order they run:

- **expand**: GIMPLE to RTL, the initial conversion.
- **cse**: common subexpression elimination on RTL.
- **combine**: combine multiple RTL instructions into one when the target supports it. The famous "combiner" pass.
- **mode-switching**: insert mode changes (e.g., x87 floating-point control word).
- **regmove**: move pseudo-registers to make register allocation easier.
- **ira/lra**: register allocation.
- **postreload**: post-allocation cleanup.
- **machine-reorg**: per-target reorganisation (e.g., delay slot filling on architectures that have them).
- **final**: emit assembly.

For a reader, RTL is harder to read than LLVM IR. The Lisp-like syntax is unfamiliar; the side-effect semantics are subtle (RTL expressions describe what happens, with explicit `set`s, but also implicit modifications via attributes); the per-pass mutations are intricate.

The reward for reading RTL: GCC can describe target-specific behaviour at this layer in ways LLVM IR does not naturally support. Conditional execution on ARM, predicated execution on Itanium, x86's complex addressing modes: all are first-class in RTL.

## Machine descriptions (.md files)

Each target architecture has a `gcc/config/<arch>/` directory containing a *machine description*: a Lisp-like text file (`.md`) that names every instruction the architecture supports.

A machine description entry:

    (define_insn "addsi3"
      [(set (match_operand:SI 0 "register_operand" "=r")
            (plus:SI (match_operand:SI 1 "register_operand" "%r")
                     (match_operand:SI 2 "register_operand" "r")))]
      ""
      "add %0,%1,%2")

The `addsi3` rule matches: a `set` of an SI (32-bit integer) register operand to the sum of two SI register operands. When matched, it emits `add %0,%1,%2` as assembly.

Machine descriptions also encode:

- **Operand predicates**: what kinds of operands are valid for an instruction (register, memory, immediate).
- **Operand constraints**: which physical registers, address forms, immediate ranges are valid.
- **Insn attributes**: type (load, store, alu, ...), latency, pipeline stage. Used for scheduling.
- **Peephole patterns**: late-stage rewrites of one instruction sequence to another.

The `.md` format is older than TableGen and somewhat simpler. A complete machine description for a target is tens of thousands of lines, but each individual rule is a few lines.

For a reader, machine descriptions are the GCC alternative to TableGen. They capture the same information (instruction definitions, operand classes, scheduling) in a different syntax. Reading a small `.md` file (e.g., for an embedded target) is a quick way to learn the format.

## Frontends

GCC supports several frontends, each living in its own subdirectory:

    gcc/c-family/    Shared C/C++/ObjC infrastructure
    gcc/c/           C frontend
    gcc/cp/          C++ frontend
    gcc/fortran/     Fortran (gfortran)
    gcc/ada/         Ada (GNAT)
    gcc/d/           D
    gcc/go/          Go (gccgo)
    gcc/rust/        Rust (gccrs, in active development)
    gcc/m2/          Modula-2 (added in GCC 13)

Each frontend parses its language and emits GENERIC trees. From that point onwards the pipeline is shared. A bug fix in GIMPLE-level dead-code elimination benefits every frontend simultaneously.

A few frontends deserve attention:

- **gccgo**: an alternative Go frontend that uses GCC's optimiser instead of the standard `gc` compiler's SSA backend. Slower to compile, sometimes produces faster code, supports architectures `gc` does not. The Go ecosystem effectively maintains two production compilers.
- **gccrs** (GCC Rust): an in-progress Rust frontend in GCC. Motivation: certifications and safety-critical environments where rustc/LLVM cannot be used. Active development through 2024-2026, included in the GCC distribution since GCC 13. The Polonius borrow-check library, originally developed by the rustc project, was integrated into gccrs for GCC 15. In rustc itself, Polonius is opt-in and still being stabilised; the production borrow checker remains NLL.
- **GNAT (Ada)**: the most complete free-software Ada compiler. Used for high-integrity software (avionics, defence). The GCC Ada frontend is the only practically viable Ada implementation outside proprietary tools.
- **gfortran**: the most widely used free Fortran compiler. Numerical computing in Linux and HPC environments depends heavily on it.

For a reader, the frontend diversity is a teachable point. GCC supports more languages than any other compiler in this Part, and the languages span generations and paradigms (Ada from 1983, Fortran with FORTRAN-77 origins, modern Rust, the languages in between). The shared GENERIC representation is what makes that possible.

## libgcc, libstdc++, libsanitizer

GCC ships with several runtime libraries:

- **libgcc**: the low-level runtime support. Provides functions the compiler emits calls to, even for "freestanding" environments. Examples: 64-bit integer arithmetic on 32-bit targets, soft-float emulation, exception unwinding, stack overflow checks.
- **libstdc++**: the GNU C++ standard library. The reference implementation of the standard.
- **libsanitizer**: the runtime support for AddressSanitizer, ThreadSanitizer, UndefinedBehaviorSanitizer, and others. Shared with LLVM's compiler-rt.
- **libgomp**: OpenMP runtime.
- **libitm**: transactional memory runtime.

The libsanitizer share with LLVM is interesting: GCC and LLVM both emit calls into the same sanitizer runtime, with the runtime implementing the actual checking and reporting. The compiler-side instrumentation is independent; the runtime is shared. This is a mostly cooperative relationship between the two projects.

## libgccjit and JIT users

`libgccjit` is GCC's JIT API, a C-callable library for emitting code at runtime. As of GCC 11+ it is past alpha and ABI-stable. Active production users include the Ravi (Lua-derived language) JIT, an experimental Octave JIT, the Coconut JIT, and the rustc-codegen-gcc backend (which uses libgccjit even for AOT despite the name). Bindings exist for Python, Perl, and Rust.

For a learner, libgccjit is the smaller alternative to LLVM's ORC for embedding GCC's optimiser as a JIT. It reuses GCC's middle-end (GIMPLE passes, IPA, RTL) and emits machine code directly to memory.

## Reload and LRA

GCC 4.8 (2013) introduced LRA (Local Register Allocator) as a planned successor to the older "reload" pass. In 2025 GCC 15 was the last release where the old reload code was still available; **LRA is now the only register allocator going into GCC 16 and onwards**. The migration was decade-long; the old reload pass had accumulated complexity that LRA simplifies dramatically.

For a contributor, the lesson is that production register allocators rewrite themselves in place over years, with the old and new coexisting before the old is finally removed. LLVM had a similar arc with greedy replacing the linear-scan-on-MachineInstr allocator, though more incrementally.

## New frontends in GCC 15-16

GCC 16's frontend list (alongside the long-standing C, C++, Fortran, Ada, Go, D, Modula-2, Objective-C, Rust-via-gccrs):

- **COBOL**: a new frontend, in tree.
- **Algol 68**: continued maturation.
- **Modula-2**: in-tree since GCC 13.1, healthy and maintained.

The GCC Steering Committee formally widened the door for new language frontends in 2025. The result was COBOL and Algol 68 alongside the older work on Rust.

## gccrs status update (GCC 15-16)

gccrs (the GCC Rust frontend) had a productive 2025 cycle. GCC 15.1 (April 2025) merged about 145 gccrs patches; the headline was integration of the Polonius borrow checker. Through 2025, gccrs reached real-code milestones: `try` blocks, `while let` loops, and a working SipHash implementation pulled from `core`. Funding from Open Source Security Inc. extends through GCC 16.1 stage 1.

gccrs is not expected to be production-ready in GCC 16 but is now a credible non-LLVM Rust path. The parallel route (using rustc with `rustc_codegen_gcc` to reach GCC's backends) is a different project; see [rustc-overview.md](rustc-overview.md).

## Plugins

GCC has a formal plugin system. Plugins can:

- Add new passes to the pipeline.
- Add new attributes interpretable by code generators.
- Provide custom diagnostics.
- Hook into compilation events (e.g., post-pass).

Plugins are GPL-licenced (the `plugin_is_GPL_compatible` symbol must be defined in every plugin), but using a plugin does not GPL-contaminate the user's source code. The licensing distinction is documented in the GCC documentation.

Examples of plugins in production:

- **MELT**: Modular Extension Language Tool, a Lisp-like DSL for GCC plugins.
- **GCC plugins for the Linux kernel**: `randstruct` (randomises struct field layout), `structleak` (zeroes out leaked structures), `stackleak` (clears stack leftover).

For a reader, the plugin system is a clean way to extend GCC without forking. The same is technically possible in LLVM but not as formally supported.

## How GCC compares to LLVM

The big architectural distinction is one IR versus many. LLVM optimises everything in LLVM IR; GCC optimises some things at the GIMPLE level (where the program is still abstract) and others at the RTL level (where machine model matters). The result is similar end-to-end, but the locus of work is different.

A few practical consequences:

- GCC's GIMPLE-level passes are often easier to write than the equivalent LLVM passes because GIMPLE is closer to the source.
- GCC's RTL handles target-specific concerns at a layer LLVM puts inside its backends. Reading a GCC backend means reading a `.md` file; reading an LLVM backend means reading a TableGen file plus C++.
- LLVM's pass manager and modular library design make it easier to embed in tools (linters, static analysers, incremental builds). GCC is more monolithic.
- GCC has stronger support for some legacy languages (Fortran, Ada) and target architectures.
- GCC's IPA infrastructure is more mature than LLVM's, and LTO is more battle-tested.

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
2. Browse `gcc/tree-cfg.cc` for a sense of how GIMPLE control-flow graphs are built. ~1500 lines, well-commented.
3. Read one of the GIMPLE optimisation passes. `gcc/tree-ssa-dce.cc` (dead-code elimination on SSA) is a good candidate.
4. Read `gcc/passes.def` to see the entire pass pipeline at once. Each line names a pass; the order is the order they run in.
5. For backends, `gcc/config/aarch64/aarch64.md` is a relatively modern machine description and is more readable than older ones.
6. For LRA, `gcc/lra-constraints.cc` is the heart of register allocation.

## Mailing-list contribution flow

GCC's review culture is different from GitHub-PR projects. Patches are sent as email to <gcc-patches@gcc.gnu.org>:

    git format-patch -1 HEAD            # produce a .patch file
    # write a description, ChangeLog entry
    git send-email --to=gcc-patches@gcc.gnu.org --to=<reviewer>@... <patchfile>

A maintainer responds. Typical responses: "OK to commit", "needs revision: [comments]", or further questions. Iteration happens in the email thread.

Once the patch is approved, the contributor commits it themselves with their own attribution (or the maintainer commits on their behalf, depending on access). The commit must include a `ChangeLog` entry.

GCC also has Bugzilla at <https://gcc.gnu.org/bugzilla/> for issue tracking. The mailing list is for patches and discussion; Bugzilla is for bugs.

The cadence is slower than GitHub. Build patience into expectations: a small patch might take a week to land; a non-trivial one, a month or more.

For a reader, the GCC contribution flow is a window into pre-GitHub open-source culture. The mailing list, the patch-by-email convention, the ChangeLog discipline: all predate (and outlast) the rise of pull-request workflows.

## Where to go next

- [The GCC Internals manual](https://gcc.gnu.org/onlinedocs/gccint/) is the canonical reference; treat the rest of this chapter as orientation.
- The GCC Summit proceedings (older, 2003-2010) for retrospective views on architectural decisions.
- "An Introduction to GCC" by Brian J. Gough, free at <https://nongnu.askapache.com/gcc-intro/>, for the user-facing perspective.
- [contributing-to-production-compilers.md](contributing-to-production-compilers.md) for how to interact with the GCC mailing-list-driven review process, which differs from LLVM's GitHub-PR model.
- [llvm-overview.md](llvm-overview.md) and [rustc-overview.md](rustc-overview.md) for the alternatives.
