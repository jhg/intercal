# Cranelift, in shape

Cranelift is the deliberate counterpoint to LLVM: a code-generation library, written in Rust, designed for fast generation rather than aggressive optimisation. Source lives at <https://github.com/bytecodealliance/wasmtime> under `cranelift/`. It is not a complete compiler. There is no frontend, no parser, no linker. It takes its own intermediate representation as input and produces machine code or object files as output. Embedders write the frontend.

The reason to read about it in this book is that it inverts the LLVM defaults. LLVM is "as much optimisation as you can afford"; Cranelift is "as little optimisation as you can get away with, and as fast as possible". Both are correct answers to different questions. A reader who only knows LLVM will treat its tradeoffs as natural law; reading Cranelift is the easiest way to see those tradeoffs as choices.

About 50,000 lines of Rust cover x86-64, AArch64, RISC-V 64-bit, and s390x targets. By comparison, LLVM is roughly 200 times that. The size difference is not because Cranelift is half-finished; it is because Cranelift is doing less by design.

## Who uses it

Cranelift was created at Mozilla in the SpiderMonkey timeframe and is now developed under the Bytecode Alliance. The major consumers:

- **Wasmtime**: the reference WebAssembly runtime. Cranelift compiles each WASM module on first use. Compile time matters because users wait for it.
- **rustc** as an alternative debug-mode codegen backend, enabled with `-Zcodegen-backend=cranelift`. Speeds debug builds by 2-3x because Cranelift is much faster to run than LLVM.
- **Wasmer**: another WASM runtime, supports Cranelift among multiple backends.
- **Lucet** (deprecated): Fastly's edge-WASM runtime, originally Cranelift-based.

The pattern is that Cranelift wins where compile time per function dominates total time: JIT scenarios, ahead-of-time compilation of many small functions, debug builds where iteration speed matters more than emitted code quality.

## CLIF: Cranelift's IR

CLIF (Cranelift Intermediate Format) is the IR. It is SSA-form, typed, organised into basic blocks. The instruction set has roughly 200 opcodes covering integer and floating-point arithmetic, memory access, vector operations, control flow, and ABI-related operations.

A small CLIF function looks like this:

    function %add(i32, i32) -> i32 {
    block0(v0: i32, v1: i32):
        v2 = iadd v0, v1
        return v2
    }

Three things to notice. First, function arguments are block parameters of `block0`, the entry block, not separate parameters of the function as in LLVM. Second, control-flow joins use block parameters everywhere, not phi nodes. A block can be jumped to from multiple predecessors with different argument values; the receiving block names them as its parameters. Third, types are part of every value definition; CLIF has no implicit promotions.

Block parameters instead of phi nodes is one of the design decisions worth pausing on. LLVM and most other SSA-form IRs use phi instructions at the start of each block to merge values from predecessors. Cranelift represents the same information as block arguments. The two are isomorphic, but block-arguments form is easier to reason about for some algorithms and easier to maintain through transformations: there are no special "phi must come first" rules, no need to update phi inputs separately when adding a predecessor edge, no risk of breaking SSA by inserting code before phis.

This is the same design choice MLIR made (block arguments in MLIR's SSA dialects), and the same one Webkit's B3 made. It is a quiet but real architectural difference from the LLVM lineage.

## SSA construction on the fly

Frontends do not build CLIF directly; they use `cranelift_frontend::FunctionBuilder`. This API maintains SSA form incrementally as the frontend emits instructions, using the algorithm from Braun et al., "Simple and Efficient Construction of Static Single Assignment Form" (CC 2013).

The Braun algorithm avoids the explicit dominance-frontier computation that classical SSA construction (Cytron 1991) requires. Instead, it lazily inserts block parameters whenever a variable read needs a value the current block does not have, walking predecessors as needed and inserting parameters on the fly.

The practical consequence: a frontend can emit CLIF top-down without computing dominators or planning where phi-nodes belong. The SSA structure emerges as a side effect of the build. This is much friendlier than LLVM's typical pattern of "emit allocas, store/load to model variables, run mem2reg later".

For a contributor, this means the frontend code is short and direct. For a reader, it is a different intuition for SSA construction than the textbook algorithm.

## Optimisation passes (the deliberately small list)

Cranelift's optimiser is intentionally minimal. The passes that run by default:

- Simple constant folding
- Simple dead-code elimination
- Branch threading (jump-to-jump elimination)
- Simple CSE (common subexpression elimination)
- Egraph-based simplification (`cranelift_codegen::egraph`, since 2022): a single pass that combines GVN, simplification, and limited rewriting through an e-graph data structure

What is missing, by design: aggressive inlining, loop optimisations, vectorisation, polyhedral, profile-guided. Cranelift is not the place to do those; LLVM is.

The egraph rewriter deserves a footnote. E-graphs (equivalence graphs) are a data structure where each node represents an equivalence class of values, and rewrites add to the class without losing the original form. After applying rewrites, an "extraction" phase picks the cheapest representative from each class. Cranelift's optimiser uses a custom implementation tailored for SSA, with rewrites declared in `.isle` rule files (see below). The whole thing is a single pass that does the work of several conventional passes.

Reading `cranelift/codegen/src/opts/` is a way to learn about e-graphs without diving into egg or other research libraries. It is a production e-graph applied to a real backend.

## Lowering via ISLE

Once optimisation is done, Cranelift lowers CLIF to architecture-specific instructions. The lowering is described in ISLE (Instruction Selection Lowering Expressions), a domain-specific language for pattern-matching rewrites.

An ISLE rule looks like this:

    (rule (lower (has_type $I32 (iadd x y)))
          (x64_add $OperandSize.Size32 x y))

The left side is a CLIF pattern. The right side is a machine-instruction expression. ISLE compiles to Rust by `cranelift-isle`, which is itself a small standalone tool.

ISLE is conceptually similar to LLVM's TableGen, GHC's pattern matcher, and Go's `.rules` files. Each project has reinvented the same idea: a declarative DSL for instruction selection rules, compiled into the host language. ISLE is by far the smallest and most readable of the four. The grammar fits in a page; the compiler is roughly 5,000 lines of Rust.

For a contributor who wants to add a new instruction selection rule, the workflow is: edit `cranelift/codegen/src/isa/<arch>/lower.isle`, add a test in `cranelift/filetests/`, run `cargo test`. No C++, no Tablegen-generated code to debug, no manual phi insertion. The friction is genuinely low.

## VCode: post-lowering, pre-regalloc

After ISLE lowering, the IR is no longer CLIF; it is `VCode`, a representation of architecture-specific instructions with virtual registers. VCode lives in `cranelift/codegen/src/machinst/`.

VCode is designed for the register allocator to consume. It has:

- ordered instructions with explicit operand kinds (use, def, mod)
- explicit virtual register numbers
- block layout with terminators
- spill/reload slots reserved by the allocator

The split between CLIF and VCode is a clean boundary: CLIF for portable optimisations, VCode for architecture-specific concerns. LLVM has a similar split between LLVM IR and MachineInstr; Cranelift's VCode is lighter and more uniform across architectures.

## regalloc2

Register allocation is delegated to the `regalloc2` crate, a separate library used by Cranelift and potentially by other backends. The crate exposes a function-level allocator interface: input is a SSA function in a regalloc2-specific IR, output is the same function with virtual registers replaced by physical ones, plus spill/reload code.

The algorithm is a SSA-based variant of linear scan. Live ranges are computed in a single pass. Each range is assigned a register greedily, in order of start point, with conflicts resolved by spilling or splitting. The allocator preserves SSA invariants throughout: phi-nodes (block parameters in Cranelift's case) are handled by insertion of move instructions on incoming edges.

The result is allocation that is roughly comparable in quality to LLVM's `greedy` allocator but several times faster to run. For Cranelift's use case, that tradeoff is right.

regalloc2 is independently published, has its own paper (Chris Fallin, "regalloc2: A SSA-Based Register Allocator", 2022), and is a self-contained way to learn modern register allocation. It is one of the most legible production register allocators available.

## Object emission and JIT

Cranelift can produce object files (for AOT compilation) or executable code in memory (for JIT). The crates split is:

- `cranelift_module`: trait definitions for declaring functions, data, and resolving symbols.
- `cranelift_object`: implements `Module` for AOT, output is a real ELF/Mach-O/COFF file via the `object` crate.
- `cranelift_jit`: implements `Module` for JIT, allocates memory pages with `mmap`, emits code into them, marks them executable.

The same `cranelift_module` interface drives both. An embedder writes a frontend that emits CLIF and calls `Module::define_function`; whether the result is a file or in-memory code depends on which `Module` impl is used.

For a learner, this is a clean illustration of the API design: AOT and JIT differ only at the boundary, not in the compiler proper. LLVM's MCJIT and ORC architectures had to grow into a similar shape but the seams show.

## Comparison with LLVM (the central comparison)

| Aspect | Cranelift | LLVM |
|--------|-----------|------|
| Lines of code | ~50,000 Rust | ~10,000,000 C++ |
| Build time of compiler | ~30 s from scratch | ~30 minutes |
| Targets | x86-64, AArch64, RISC-V 64, s390x | 50+ |
| Optimisation depth | Minimal (egraph + a handful of passes) | Hundreds of passes, deep |
| Compile time per function | ~10 ms typical | 100 ms - 1 s typical |
| Code quality vs LLVM | 0.7-0.85x speedup baseline | 1.0x baseline |
| Instruction selection DSL | ISLE | TableGen |
| Register allocator | regalloc2 (linear scan, SSA-based) | Greedy, basic, fast (selectable) |
| IR | CLIF (SSA, block params, ~200 ops) | LLVM IR (SSA, phi nodes, ~60 core ops + intrinsics) |
| API style | Embed-as-library from day 1 | Embed-as-library, retrofitted |

The right reading of this table is not that Cranelift is "worse" than LLVM. It is that Cranelift made different choices and lives in a different niche. For a JIT compiling untrusted WASM modules in the hot path of every request, "10ms per function" matters more than "5% better generated code". For a release build of a Linux distro, the priorities flip and LLVM wins.

This is a frequent shape in compiler engineering: the same mature problem (instruction selection, register allocation) admits multiple production-quality answers, each optimised for a different use case. Reading both Cranelift and LLVM in the same week is the fastest way to internalise that.

## Repo layout

    cranelift/
      codegen/                 The backend proper
        src/ir/                CLIF data structures
        src/machinst/          VCode + machinst infrastructure
        src/isa/<arch>/        Per-architecture lowering
          lower.isle           ISLE rules for that architecture
        src/opts/              Optimisation passes (egraph, etc.)
        src/regalloc/          Glue to regalloc2
      frontend/                FunctionBuilder API for IR construction
      object/                  AOT output via the `object` crate
      jit/                     JIT output to executable memory
      module/                  Module abstraction shared by AOT and JIT
      isle/                    ISLE compiler (a separate tool)
      filetests/               Filetest framework + per-feature tests
      reader/, parser/         CLIF text format parser (for testing)
      docs/                    Internal documentation

The rest of the wasmtime repo (the runtime, the WASM frontend, etc.) sits next to `cranelift/` but is logically separate.

## Reading order

A practical path for a reader:

1. Read `docs/ir.md` and `docs/isle.md` in the repo. Short, well-written, concrete.
2. Walk through `cranelift/codegen/src/ir/instructions.rs` to see the CLIF instruction set.
3. Read `cranelift/codegen/src/isa/x64/lower.isle` for x86-64 instruction selection rules. The patterns are explicit and the right side is the assembly.
4. Read `regalloc2`'s README and the linked paper if you want to understand allocation.
5. Read `cranelift/codegen/src/opts/`'s egraph implementation if you are curious about optimisation.

## How to contribute

GitHub PRs to <https://github.com/bytecodealliance/wasmtime>. The community is small and welcoming. The Bytecode Alliance is the umbrella; review happens via GitHub. Code style: `rustfmt`, idiomatic Rust, no `unsafe` outside small well-justified spots.

Beginner-friendly categories:

- ISLE rule additions or refinements: each rule is small, testable in isolation, and immediately useful.
- regalloc2 improvements: the codebase is small enough that a careful contributor can land changes quickly.
- CLIF instruction additions: when a missing operation prevents a frontend from emitting efficient code.
- Documentation: `docs/` is incomplete in places.

The core maintainers (Chris Fallin, Andrew Brown, and others) are responsive and willing to mentor. Compared to LLVM's volume of contributors, Cranelift is small enough that you will likely get review from someone who has read every line of the file you are changing.

## Where to go next

- Cranelift documentation in <https://github.com/bytecodealliance/wasmtime/tree/main/cranelift/docs>.
- Chris Fallin's blog at <https://cfallin.org/> for design notes on regalloc2 and ISLE.
- The Bytecode Alliance Zulip at <https://bytecodealliance.zulipchat.com/> for live discussion.
- [llvm-overview.md](llvm-overview.md) for the contrast Cranelift was designed against.
- [rustc-overview.md](rustc-overview.md) for the project that uses Cranelift as an alternative debug backend.
