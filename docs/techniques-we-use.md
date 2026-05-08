# Advanced techniques we use

A small compiler can afford only a handful of the techniques production compilers carry. This chapter takes inventory: every advanced compiler technique present in our codebase, what it is, why it is here, and which production compilers in Part VII use the same idea at scale. The aim is to make the connection visible. If you can locate a technique in our 2,000-line `intercalc.sh`, you can recognise it in a million-line LLVM tree.

Each section follows the same structure: the technique, where it lives in our code, the production-compiler equivalent, and a pointer for further reading.

## Constant folding

What it is: when an expression has only compile-time-known operands, the compiler computes the result at compile time and emits the literal value, replacing a runtime computation with a constant load.

Where it lives in our code: `eval_const` in `src/bootstrap/intercalc.sh`. The function recursively walks an expression node, returning a numeric value if every leaf is a constant, or `nil` if any subexpression is runtime-determined. When it returns a value, the caller (`codegen_expr`) emits a single `mov` of the literal instead of recursive call sequences for the operators.

Operators we fold: unary `&` (AND of adjacent bits with wrap), unary `V` (OR), unary `?` (XOR), binary `$` (mingle), binary `~` (select). Together these are all the INTERCAL operators, so any wholly-constant expression collapses to a single literal.

Why it matters here specifically: the Turing Text Model encoder, used for character output, is built from many small constant manipulations of mingle and select. Without folding, every character emitted incurs a small runtime cost. With folding, the output array values are computed once, at compile time, and emitted as literal integers. Folding measurably shrinks the assembly for any non-trivial `READ OUT` of a string.

Production-compiler equivalents:
- LLVM's `InstSimplify` and `InstCombine` passes do constant folding plus algebraic simplification. `llvm/lib/Analysis/InstructionSimplify.cpp` is the smaller cousin, "this expression has a known result". `llvm/lib/Transforms/InstCombine/` is the larger one, "this expression has a simpler form".
- rustc has miri, the MIR interpreter, which does compile-time evaluation of `const fn` calls. The interpreter is much more general than constant folding (it handles loops, function calls, allocations) but the leaf case is the same operation we do.
- GCC has tree-level folding in `gcc/fold-const.cc`, one of the oldest pieces of the compiler.
- Go folds at SSA level via `.rules` files: `(Add64 (Const64 [c]) (Const64 [d])) => (Const64 [c+d])`.
- GHC's simplifier does it via the same mechanism it uses for everything else, RULES + beta reduction.

Where to read more: Cooper and Torczon, *Engineering a Compiler*, chapter on local optimisation; LLVM's `InstSimplify` source; `eval_const` in our own source. The textbook treatment plus our 100-line implementation plus the production version is the cleanest staircase.

## Sparse conditional constant propagation: what we do not do

For completeness, the version of constant folding we do *not* do is **sparse conditional constant propagation** (SCCP, Wegman and Zadeck 1991). SCCP combines constant folding with dataflow: when a comparison evaluates to a known constant, the branch it controls is propagated as dead, which lets more values be marked constant in a fixpoint loop. Our compiler does only the leaf case (an expression built solely from literals); we do not propagate constants across statement boundaries. See [techniques-we-lack.md](techniques-we-lack.md) for the full version.

## Dead-flag elimination

What it is: removing checks that the analysis can prove are always trivially true or always trivially false.

Where it lives in our code: `compute_flag_checks` in `src/bootstrap/intercalc.sh`. Every INTERCAL statement has an "abstain flag" that, when set, causes the statement to skip its body at runtime. The codegen used to emit a three-instruction sequence at the start of every statement: load the flag, test against zero, branch if non-zero. For statements whose flag is never modified by any `ABSTAIN`, `REINSTATE`, or initial `NOT`, the check is dead code. `compute_flag_checks` analyses the program at compile time and marks each statement as needs-check or skip-check; the codegen then emits the prologue conditionally.

The analysis: walk every `ABSTAIN`, `REINSTATE`, and `DON'T`/`NOT` modifier; record which statement labels and gerunds they target; mark every reachable statement accordingly. Statements not covered by any modifier survive as immutable, and skip the runtime check. The result is typically that 60-90% of statements in a typical program need no flag check.

Why it matters here specifically: the per-statement check was three ARM64 instructions (load, test, branch). A program with 100 statements and no `ABSTAIN` saved 300 instructions plus the data-section flag bytes. Once the analysis was added, the overhead became proportional to the number of statements actually subject to abstention.

Production-compiler equivalents:
- The general technique is **dead-code elimination on dataflow analysis**. Every production compiler has a DCE pass: LLVM's `ADCE.cpp` (Aggressive Dead Code Elimination), GCC's `tree-ssa-dce.cc`, rustc's `rustc_mir_transform/dead_store_elimination.rs`, GHC's simplifier, Go's `dse` SSA pass.
- The conceptual analysis (which writes/reads of the flag are reachable) is the same shape as classical liveness analysis. Our version is a static analysis on a known bit-of-state, where production compilers do it on values flowing through SSA.
- Dead-store elimination, dead-argument elimination, dead-block elimination: each is a variation on the same theme. The pass discovers something that contributes nothing and removes it.

Where to read more: Cooper and Torczon's chapter on dataflow, LLVM's ADCE source, GHC's `Demand` analysis (a richer version that classifies values by how strictly they are demanded), rustc's `dead_code` lint at the diagnostic level.

## Peephole optimisation

What it is: scanning the emitted assembly for patterns that can be locally replaced by simpler equivalents. The "peephole" is a small window over the instruction stream; the optimiser slides the window and fires rules.

Where it lives in our code: `peephole_optimize` in `src/bootstrap/intercalc.sh`. Currently the function recognises one pattern: an unconditional branch (`b LABEL` on ARM64, `jmp LABEL` on x86-64) immediately followed by the label it targets. The branch is dead because fall-through reaches the label anyway. The pass drops the branch.

Where the pattern comes from: the codegen used to emit a per-statement trampoline label after every statement, plus a branch back to it from the `aedone` epilogue. Eliminating the trampoline and adding this peephole keeps the emitted code compact.

Why it matters here specifically: the pattern arises mechanically, hundreds of times per compiled program. Without the peephole, every compiled INTERCAL binary carries a `b NEXT_STMT` followed immediately by `NEXT_STMT:` for every statement.

Production-compiler equivalents:
- LLVM's `MachineInstr`-level peephole passes in `llvm/lib/CodeGen/PeepholeOptimizer.cpp` plus per-target peephole files. Every backend has them.
- GCC has `define_peephole` and `define_peephole2` in machine description (`.md`) files, which fire after register allocation.
- Go's `genssa` phase plus the per-architecture lowering rules effectively do peephole at SSA level.
- All major backends have peephole passes; the LLVM and GCC ones are the most extensive.

What we leave on the table: only one peephole rule. Productive additions would include load-after-store cancellation (when a store followed by a load of the same address can be combined), redundant `mov` (when two adjacent moves to/from the same register pair are no-ops), jump-to-jump short-circuiting (when a branch targets a block whose only instruction is another branch, skip the middleman). Each is a small rule, each fires occasionally, none is essential.

Where to read more: Cooper and Torczon's section on peephole; LLVM's `lib/CodeGen/PeepholeOptimizer.cpp`; the `.md` files for any GCC backend.

## Direct-to-assembly codegen (no IR)

What it is: the choice to lower from the parse tree directly to target assembly, with no intermediate representation in between.

Where it lives in our code: every `codegen_*` function in `intercalc.sh`. They walk the parse tree node by node, emitting assembly text into the `asm` variable.

Why this is a "technique": most compiler textbooks treat IRs as a given. They are not. Many production compilers have an IR because the frontend and backend are decoupled, the language is rich enough that IR-level analysis matters, and the backend has many targets. None of those apply to us. INTERCAL is small, our targets are few, and our optimisations are local enough that they fit in the parse tree walk.

Production-compiler equivalents and contrasts:
- LLVM, GCC, rustc, Go, GHC all have at least one IR. They make different choices about how many.
- Cranelift has CLIF as its only IR. The compiler is small partly because it commits to one well-designed IR.
- Some real compilers historically had no IR. Old Pascal compilers, the early Borland C compilers, the very first Lisp implementations. The pattern is "one source language, one target, optimisations are local". When any of those constraints fails, an IR appears.
- Our `--emit-cfg` and `--emit-3addr` flags expose IR-shaped views of the program for debugging and teaching, but the codegen does not consume them. The flags are inspection only. See [middle-end-and-optimisation.md](middle-end-and-optimisation.md) for what real IR introduction would entail.

The lesson: "no IR" is a design choice. It buys simplicity at the cost of optimisation power and target breadth. For our scale, the tradeoff is right. For LLVM's, it would be wrong.

## Reproducible builds

What it is: the property that compiling the same source with the same compiler version twice produces byte-identical binaries. Sounds trivial; it is not. Build timestamps, randomly-generated UUIDs, ordered hash maps with non-deterministic iteration, file-system-walk orderings, and toolchain-injected metadata all break it.

Where it lives in our code:
- `INTERCAL_REPRODUCIBLE=1` environment variable opt-in.
- On Linux: `cc -Wl,--build-id=none -Wl,-s` strips the build ID and debugging metadata.
- On macOS: a multi-step sequence around `cc`. Linkers on Apple Silicon ad-hoc-codesign every binary, and the codesign signature includes a random UUID. We:
  1. Tell `cc` to skip the auto-codesign with `-Wl,-no_adhoc_codesign`.
  2. Run `strip` to remove temp-file names that crept into the symbol table.
  3. Run `tools/rewrite_uuid.py` to overwrite the random UUID in the LC_UUID Mach-O command with a content-derived hash.
  4. Re-codesign deterministically: `codesign -fs - --identifier intercal --digest-algorithm=sha256`.

The result: identical input source produces byte-identical binary across runs.

Why it matters here specifically: a self-hosting compiler that reaches a 3-generation fixpoint (compiler compiles itself, that compiler compiles itself again, second-generation compiler reproduces the first one) requires reproducible builds. Without them, the fixpoint test would never pass; the build IDs alone would diverge.

Production-compiler equivalents:
- The Reproducible Builds project at <https://reproducible-builds.org> documents the principles. Most of GNU/Linux is reproducible-buildable now.
- LLVM, GCC, rustc, Go all have reproducibility as a goal. Each has accumulated build-time flags and source-level fixes for non-determinism.
- The Diverse Double-Compilation (DDC) technique by David A. Wheeler builds on reproducibility to defend against the Trusting Trust attack. See "Reflections on Trusting Trust" (Thompson, 1984) for the original scenario.

Where to read more: <https://reproducible-builds.org/docs/>; "Fully Countering Trusting Trust through Diverse Double-Compiling" (Wheeler 2009); our own `tools/rewrite_uuid.py` for the macOS-specific dance.

## Self-hosting via bootstrap

What it is: the property that the compiler is written in the language it compiles, plus the procedure for getting a working compiler when none exists.

Where it lives in our code:
- `src/bootstrap/intercalc.sh`: the zsh-script bootstrap compiler. The "primordial spark". Implements enough INTERCAL to compile the self-hosted compiler.
- `src/compiler/compiler.i`: the MVP self-hosted compiler, in INTERCAL. Currently a template-passthrough dispatcher (recognises known tests by `cksum` and emits the corresponding pre-generated assembly).
- `src/compiler/stage3.i`: the evolving self-hosted compiler, in INTERCAL. Implements real lexing/parsing piece by piece.
- `bootstrap.sh`: the orchestration. Runs `intercalc.sh` to produce stage1 from `compiler.i`, runs stage1 against `compiler.i` to produce stage2, runs stage2 against `compiler.i` to produce stage3, byte-compares stage2 and stage3.

The fixpoint property: when stage2 produces a binary byte-identical to stage3, the compiler has reached a fixed point. From here on, the compiler can build itself indefinitely without reverting to the bootstrap script.

Why it matters here specifically: it is the demonstration that the INTERCAL compiler is real. A compiler that requires the original implementation language forever is incomplete. A self-hosted compiler is autonomous.

Production-compiler equivalents:
- rustc bootstraps in three stages. Stage 0 is the previous stable rustc. Stage 1 is rustc compiled by stage 0 against the current source. Stage 2 is rustc compiled by stage 1, the production-equivalent compiler. Stage 3 (optional) is the fixpoint check.
- OCaml has been self-hosting continuously since the late 1980s. The repo carries a bytecode `boot/ocamlc` that bootstraps from any platform with a C compiler.
- GHC has a similar bootstrap chain via older GHC versions.
- Go bootstrapped from C (the 6c/8c compilers) until 1.5, then transitioned to self-hosting. Today it bootstraps from a previous Go release.
- Zig went from a C++ stage1 to a self-hosted stage2 around 2022. The repo carries a `zig1.wasm` blob to start the chain.

The pattern is universal. Every serious compiler in this Part is self-hosted. The bootstrap mechanism varies; the goal is the same.

Where to read more: "Reflections on Trusting Trust" (Thompson 1984); our [self-hosting.md](self-hosting.md); the rustc-dev-guide chapter on stages; OCaml's `boot/` directory.

## Differential testing (pure vs native syslib)

What it is: comparing the outputs of two implementations of the same operation to detect bugs in either. Production compilers use it to fuzz themselves: csmith generates random C programs, compiles with multiple compilers, compares results. We use a smaller version: every syslib operation has a hand-written native assembly version and a pure-INTERCAL version, and we verify they produce identical results.

Where it lives in our code: `tests/test_syslib_pure.sh`. Three small INTERCAL programs that exercise syslib operations (add, multiply, divide). Each is compiled twice, once normally (using `src/syslib/native/<platform>.s`) and once with `--pure-syslib` (using `src/syslib/syslib.i`). The outputs are compared byte for byte. Failure means one of the implementations diverged.

Why it matters here specifically: the native syslib is hand-written assembly per platform; the pure syslib is INTERCAL source compiled by our own compiler. The pure version exists partly as documentation of the algorithm in INTERCAL terms, and partly as a check on the native version. If the two diverge, either the native code has a bug or the compiler is mistranslating the INTERCAL. Either is information.

Production-compiler equivalents:
- LLVM has csmith integration and libFuzzer harnesses. Bugs found by csmith have been some of the most embarrassing in LLVM's history.
- rustc has crater, which compiles every public crate on crates.io against a candidate rustc and compares results. Crater runs are how rustc team validates language changes.
- GCC has its own test suite plus integrations with various fuzzers.
- The "differential testing of compilers" subfield is well-documented in academic literature.
- Our pure-vs-native is a much smaller version of the same idea.

Where to read more: "Finding and Understanding Bugs in C Compilers" (Yang, Chen, Eide, Regehr, PLDI 2011); the csmith repo at <https://github.com/csmith-project/csmith>; the crater documentation.

## Compile-time validation

What it is: detecting errors at compile time that other compilers might catch only at runtime. Pushing checks earlier in the pipeline means faster diagnostics and clearer error messages.

Where it lives in our code: many places, all in `intercalc.sh`. Examples:
- Politeness ratio: `check_politeness` rejects programs with `ICL079I` (under 1/5 PLEASE) or `ICL099I` (over 1/3 PLEASE) at compile time. The ratio is a property of the whole program, computable from the parse tree, no need to wait for runtime.
- Duplicate label: `check_labels` walks the statement list and emits `ICL182I` if the same label appears twice.
- Undefined label in `NEXT`: `ICL129I` at compile time. Originally a runtime error in INTERCAL specifications; we surface it earlier because we already have the labelled-statement table.
- Undefined or reserved label in `ABSTAIN`/`REINSTATE`: `ICL139I` at compile time.
- Unknown gerund in `ABSTAIN`/`REINSTATE` list: `ICL017I` at compile time.
- Spark-inside-spark or rabbit-ears-inside-rabbit-ears: `ICL017I` at parse time. Standard INTERCAL forbids same-bracket-inside-same-bracket nesting; we enforce it during parse rather than letting it pass to codegen.
- Multiple `COME FROM` to the same label: `ICL555I` at compile time.

Why it matters here specifically: the INTERCAL spec treats most errors as runtime, in part because abstained statements should not trigger compile-time errors. We push checks to compile time when the analysis is sound regardless of abstention (a statically undefined label is undefined whether or not the statement runs).

Production-compiler equivalents:
- The general principle is "shift left": catch errors as early in the pipeline as possible. Type checkers, linters, borrow checkers all embody it.
- rustc's diagnostic infrastructure is famously thorough about phrasing: errors point at specific spans, suggest fixes, often reference language reference.
- Clang's diagnostics are similar quality.
- Lints (Clippy for Rust, clang-tidy for C/C++, vet for Go) catch likely-but-not-definite errors at compile time without rejecting the program.

Where to read more: the rustc-dev-guide chapter on diagnostics; *Compiler Construction* by Wirth on principles of error reporting; our [error-messages.md](error-messages.md) for the conventions we follow.

## IR inspection flags (`--emit-cfg`, `--emit-3addr`)

What it is: read-only flags that print an IR-shaped view of the parsed program, for debugging and teaching, without affecting codegen.

Where it lives in our code: `emit_cfg` and `emit_3addr` functions in `intercalc.sh`, plus the `--emit-cfg` and `--emit-3addr` command-line flags. Both run after parsing, label resolution, and dead-flag analysis, but before codegen. They print the result to stdout and exit.

`--emit-cfg`: identifies basic-block leaders (first statement, labelled statements, statements after `NEXT`/`RESUME`/`GIVE_UP`, COME FROM sources, statements after a labelled statement that has a COME FROM), groups statements into blocks, and prints the outgoing edges (fall-through, NEXT to label, COME FROM source, RESUME dynamic, exit). The output looks like:

    B0: stmts 1..2
      stmt   1: ASSIGN
      stmt   2: NEXT
      -> B2 (NEXT to label 10)

`--emit-3addr`: prints a flat three-address listing, one statement per line, with the operation name plus the body and modifiers. GIMPLE-shaped.

Why it matters here specifically: the chapters in Part VII reference IR concepts constantly. Without an IR view of an INTERCAL program, the reader has only the source text and the assembly. The flags fill the gap. They also serve as a debugging tool when the codegen produces unexpected assembly: confirm the parse-tree-level model first, then look at codegen.

Production-compiler equivalents:
- LLVM's `-emit-llvm` for Clang prints LLVM IR. `opt -print-after-all` shows the IR after every pass.
- rustc's `-Z dump-mir=all` and `-Z unpretty=mir` dump MIR. `-Z hir=...` dumps HIR.
- Go's `-gcflags='-d=ssa/<phase>=2'` dumps SSA at any named phase.
- GHC's `-ddump-simpl`, `-ddump-stg`, `-ddump-cmm` dump each IR after each transformation.
- Every production compiler has a comparable suite of diagnostic flags.

Our flags are dramatically simpler than any of these (we have only two; LLVM has dozens). The shape is the same.

Where to read more: [middle-end-and-optimisation.md](middle-end-and-optimisation.md) explains the implementation; the LLVM `opt` tool's `-print-after-all` output is the most heavyweight production version.

## Cache mode for the syslib

What it is: a content-hashed cache of the compiled syslib, keyed by SHA-256 of the source. First compile populates the cache; subsequent compiles read it.

Where it lives in our code: `ensure_syslib_cache` in `intercalc.sh`. Activated by `INTERCAL_SYSLIB=cache` environment variable. The cache lives at `$XDG_CACHE_HOME/intercal/syslib-<platform>-<hash>.s`, defaulting to `~/.cache/intercal/`.

Pipeline: when the user compiles a program that needs syslib, the compiler hashes `src/syslib/syslib.i`, looks up the cache, finds (or generates) the corresponding compiled `.s` file, then concatenates it with the runtime and program assembly as usual.

Why it matters here specifically: pure-INTERCAL syslib compilation is slow. The 9,000-line `src/syslib/syslib.i` takes 30-100 seconds to compile through `intercalc.sh`. Recompiling it on every user build (which happens with `--pure-syslib`) is unacceptable in normal use. Caching reduces the cold-cache cost (paid once per source change) to near-zero subsequent cost. The cached output is verified byte-identical to a fresh compilation.

Production-compiler equivalents:
- Build-system caches like Cargo's target directory, Bazel's content-addressed cache, ccache for C/C++, sccache for Rust. All use a content hash to key cached outputs.
- rustc's incremental compilation is conceptually similar: per-query caching. The granularity is finer (per-function instead of per-syslib-module) but the pattern is the same.
- LLVM's ThinLTO writes summary files that allow subsequent builds to skip re-analysing unchanged modules.

The general technique: identify a unit of work that is expensive and pure (depends only on its inputs), hash the inputs, cache the output. We applied it to one specific unit (the syslib); production compilers apply it everywhere.

Where to read more: the Bazel build system documentation; sccache's README; rustc-dev-guide on incremental compilation.

## Cross-platform codegen via assembly conversion

What it is: generating assembly for one platform and rewriting it via `sed` to match a different platform's syntax conventions.

Where it lives in our code: the `_INTERCAL_PLATFORM == linux_arm64` block in `main()`. After codegen produces macOS-style ARM64 assembly, a series of `sed` substitutions converts it to Linux-style:
- `__TEXT,__text` → `.text`
- `sym@PAGEOFF` → `:lo12:sym` (for `add` instructions)
- `sym@PAGE` → `sym` (for `adrp` instructions)
- `svc #0x80` → `svc #0`
- mmap/syscall numbers (1 → 93 for exit, 4 → 64 for write, etc.)
- `_main` → `main`

For Linux x86-64, we have a separate codegen backend (`src/bootstrap/codegen_x86_64.sh`) rather than converting from ARM64. The two are different enough that conversion would be more brittle than rewriting.

Why this is a "technique": cross-platform codegen normally means writing per-platform backends. We do that for x86-64. For Linux ARM64, we cheat: macOS and Linux ARM64 share enough of the assembly syntax that `sed` is sufficient. The cheat is documented in [platforms.md](platforms.md). Knowing where the cheat leaks (the platform-specific instruction encoding for syscalls, the relocation syntax, the section names) is the work.

Production-compiler equivalents:
- LLVM has per-target backend infrastructure with shared MC layer for low-level encoding. The "sed" approach would be impossible at LLVM's scale.
- GCC similarly has per-target machine descriptions.
- Our approach is viable only because we generate text assembly, not binary, and only because the platforms share an architecture.

Where to read more: [platforms.md](platforms.md) for the assembly differences; the AArch64 ABI documentation.

## Label 666 syscall extension

What it is: a custom mechanism for invoking OS syscalls from INTERCAL programs. Standard INTERCAL has no syscall facility; we add one.

Where it lives in our code: `src/runtime/<platform>.s` defines the runtime handler at label 666. INTERCAL programs invoke syscalls by setting `.1` (syscall number), `.2`-`.4` (parameters), optionally writing to `,65535` (data buffer), and executing `DO (666) NEXT`. The handler dispatches by syscall number to one of eight handlers (open, read, write, close, argc, argv, exit, getrand).

The semantics are documented in [666.md](666.md). The convention is loosely inspired by CLC-INTERCAL's Label 666 mechanism but simplified.

Why it matters here specifically: a self-compiling compiler that reads INTERCAL source needs to read files, write files, and parse arguments. None of these are expressible in standard INTERCAL. Label 666 makes them accessible without changing the language's syntax. The same mechanism gives user programs file I/O, exit codes, and randomness.

Production-compiler equivalents:
- C's `<sys/syscall.h>` plus the `syscall()` libc wrapper plays a similar role for C: a generic interface to OS facilities.
- C-INTERCAL's `-e` flag enables external function calls to C code.
- Go's `syscall` package exposes raw syscall access alongside the higher-level `os` package.
- The general pattern is "language X wants to call into the OS; provide a small, well-defined gateway".

Where to read more: [666.md](666.md) for the design rationale; the syscall number tables in `src/runtime/<platform>.s`; CLC-INTERCAL's documentation for the historical version.

## Hash-keyed template dispatch (compiler.i MVP)

What it is: a lookup table from `cksum` of source content to a pre-compiled assembly template. The MVP self-hosted compiler `compiler.i` is a switch on this hash: if the source matches a known test, emit the corresponding template; otherwise fail with a "not implemented" message.

Where it lives in our code: `src/compiler/compiler.i`. The structure is a long sequence of conditional branches comparing `cksum(stdin)` to a known constant, jumping to the corresponding emit code if matched. Templates live in `src/compiler/templates/<test>-<platform>.s`.

Why this is a "technique": it solves a specific bootstrap problem. Real lexing/parsing in INTERCAL is non-trivial (see `stage3.i` for the in-progress implementation). The MVP needed to pass the self-hosted test suite without full source compilation. Hash-keyed dispatch achieves that: as long as the test inputs are stable, their hashes are stable, and pre-generated assembly is correct.

It is a placeholder for a real compiler. Stage3 is the path to replacing it. But as a placeholder, it works: 25 self-hosted tests pass, the bootstrap chain is closed, the project is provably self-hosted in a meaningful sense.

Production-compiler equivalents:
- None directly. Real compilers do not dispatch on input hashes.
- The closest analog is **memoisation** at finer granularity: rustc's query system, ccache for C/C++, content-addressed Bazel caches. They cache by hash, but they cache *outputs* of real computations, not pre-computed answers to known inputs.
- Another loose analog: **profile-guided optimisation** specialises code paths for known-common inputs. We specialise compiler paths for known-common test inputs.

The lesson: when a real implementation is hard, a precomputed lookup may be a viable stopgap. We are not the first compiler to ship one; older compilers shipped tables of "if input matches X, emit Y" for specific corner cases. Modern compilers tend to formalise the cases as optimisations rather than as raw hash tables.

Where to read more: `src/compiler/compiler.i` itself; [self-hosting.md](self-hosting.md) for the bootstrap context.

## Branchless conditional ADD (stage3.i)

What it is: a way to compute "add x to y if condition c is true, leave y alone if c is false" using only INTERCAL's bit-twiddling operators, without a runtime branch.

Where it lives in our code: `src/compiler/stage3.i`. The technique is documented in [intercal_patterns.md](intercal_patterns.md) under "Conditional ADD without a branch".

The mechanism, in outline: build a mask from the condition (all-ones if true, all-zero if false), AND the value-to-add with the mask, then add. INTERCAL's mingle and select operators turn out to be sufficient to build the mask, given a 0/1 condition.

Why it matters here specifically: INTERCAL has no `if`. The standard idiom for two-way branches is the "computed RESUME" pattern: push two NEXT addresses, compute a 1/2 selector, RESUME on the selector. This idiom requires the surrounding code to be inside a function (so RESUME has somewhere to return), and it does not branch in the same scope; it only unwinds. Three attempts to build a "loop with conditional break" in stage3.i confirmed empirically that the unwind dance does not work at top level (the error code `ICL632I` always fires).

The branchless conditional ADD pattern sidesteps the problem. No control flow, no RESUME, no NEXT stack manipulation. Pure dataflow. Stage 3.1.d, 3.1.e, and 3.2.a (the byte-probe detectors) all use this pattern.

Production-compiler equivalents:
- The general technique is **branchless code generation** to avoid branch mispredictions on hot paths. Compilers do this implicitly via instruction selection (`cmov` on x86, `csel` on ARM64).
- LLVM and GCC both have specific transformations to convert branch-y patterns into branchless ones when profitable.
- Our pattern is forced by the source language, not by performance.

The lesson: when control flow is expensive or unavailable, dataflow can substitute. INTERCAL forces this lesson at the source level; production compilers learn it at the IR level for performance.

Where to read more: `src/compiler/stage3.i`; [intercal_patterns.md](intercal_patterns.md) for the verified patterns; "Hacker's Delight" by Henry S. Warren Jr. for branchless techniques in general computing.

## Compiled-syslib aliasing

What it is: when emitting the syslib as a standalone library (via `--emit-syslib`), the compiler renames internal `_stmt_*` symbols to `_syslib_stmt_*` to avoid collisions with user code, and emits `.global _rt_syslib_NNNN` aliases at every labelled-statement entry point.

Where it lives in our code: the `EMIT_SYSLIB_MODE` branch in `main()`. The renaming uses `sed`; the alias generation iterates over `label_to_stmt` and emits `.global` plus assignment for each label in the 1000-1999 syslib range.

Why it matters here specifically: the cache mode requires a self-contained syslib `.s` file. Without renaming, every user program would conflict with the syslib's internal labels. Without aliases, callers (user-program assembly) could not find the syslib entry points by name.

Production-compiler equivalents:
- The general technique is **symbol mangling** to avoid namespace collisions. C++ does it for templates and overloads. Rust does it for monomorphisations. Linkers have visibility attributes (`hidden`, `internal`, `protected`) for similar reasons.
- Static-library packaging in C does conceptually similar work: prefix internal symbols, expose only the documented API.

Where to read more: the C/C++ ABI documentation on name mangling; our own compiled-syslib emission code.

## Lint integration

What it is: pre-commit and CI checks that catch likely bugs before they reach the test suite.

Where it lives in our code:
- `tools/lint_intercal.sh`: scans `.i` files for politeness imbalance, suspicious keyword typos, unreferenced labels.
- `tools/lint_assembly.sh`: scans `.s` files for known platform pitfalls (three-register x86 addressing, misplaced `//` comments in x86, etc.).
- Both run in CI and are recommended (not enforced) locally via `tools/install_hooks.sh`.

Why it matters here specifically: the assembly-pitfall list grew from real CI failures. Each lint rule corresponds to a real bug we encountered, the kind that shows up cryptically at link time and takes hours to diagnose. The lint catches the pattern at the source level.

Production-compiler equivalents:
- Clippy for Rust, clang-tidy for C/C++, govet for Go, hlint for Haskell. Each has hundreds of lint rules.
- LLVM uses clang-tidy on its own source. rustc uses Clippy.
- The general principle is "if a bug is common, write a lint that detects it".

Where to read more: the Clippy book at <https://doc.rust-lang.org/clippy/>; our own lint scripts.

## Closing

The techniques in this chapter are the visible advanced compiler engineering in our codebase. They are not the most sophisticated possible; they are the ones a 2,000-line shell script can reasonably carry. Each maps directly onto a slice of the production compilers in Part VII.

If you are reading this chapter trying to understand whether a particular technique is "in scope" for our compiler, the answer is roughly: if it is implementable at our scale without an IR pipeline, it might fit. If it requires SSA, register allocation, or a JIT, it does not. The next chapter ([techniques-we-lack.md](techniques-we-lack.md)) is the catalogue of what does not fit and why.
