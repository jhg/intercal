# Debugging the compiler

A compiler bug manifests as a difference between what you wrote and what the binary does. Because our pipeline is short and largely side-effect-free, diagnosing that difference is usually a matter of following the bug from symptom to phase to specific line. This chapter collects the techniques we actually use.

## The symptom taxonomy

Every compiler bug we have hit in this project falls into one of these buckets:

- *Compile-time crash.* The compiler prints an unexpected error, or fails silently. Either the lexer, the politeness check, or the label resolver is upset.
- *Link-time failure.* `cc -x assembler -` rejects the generated assembly. The codegen or the platform translation is producing invalid assembly.
- *Runtime error (ICL).* The binary runs and exits with an `ICLnnnI` message. The runtime is behaving as designed; the bug is in the user program or in the code that should have prevented this condition at compile time.
- *Runtime crash (SIGSEGV).* The binary dies violently, usually inside the runtime. The codegen emitted something that looks right but violates an assembly invariant.
- *Wrong output.* The binary runs, exits cleanly, and prints the wrong answer. The hardest category, because everything else "works". Either the codegen mis-evaluated an expression, a runtime routine miscomputed a result, or a state bit (abstain, ignore) was mishandled.

Each requires different instrumentation.

## Compile-time crashes

When `intercalc.sh` itself fails, the fastest path is:

1. Re-run with `zsh -x src/bootstrap/intercalc.sh < program.i > /dev/null 2>trace`. Every line executed is logged to `trace`.
2. Find the last executed function before the crash.
3. Inspect the relevant arrays at that point with `print -l ${stmt_type[@]}` (or equivalent).

The most common compile-time bug is a tokeniser misclassification: a statement whose body contains unexpected content is classified as `UNKNOWN` and the codegen emits `bl _rt_error_E000`. You catch this by listing `stmt_type` and seeing the unexpected `UNKNOWN`.

The second most common is a politeness miscount: we thought we had 1/5 but have 1/6 because a DON'T NOTE wasn't counted. List `stmt_polite` and sum.

## Link-time failures

When `cc -x assembler -` rejects the output, the relevant information is on stderr. Strategy:

1. Reproduce with `INTERCAL_ASM_ONLY=1 zsh src/bootstrap/intercalc.sh < program.i > failing.s`. Now you have the assembly as a file.
2. `cc -x assembler -c failing.s -o /dev/null` isolates the assembler error without running the linker.
3. Read the error: GNU `as` and Apple `as` differ in their messages. GNU is usually more specific (`line 42: Error: junk at end of line, first unrecognized character is ...`).
4. Open `failing.s` at the reported line. The generated assembly includes line-directive-like comments that match the `codegen_*` function that emitted each block; use those to navigate back into `intercalc.sh`.

Platform-specific assembler errors almost always point at one of the pitfalls listed in [platforms.md](platforms.md): wrong comment delimiter, wrong relocation syntax, three-register addressing, forgotten `.global`. Match the error against that table first.

## Runtime ICL errors

ICL errors fire when a runtime-detected condition is met. The error codes are enumerated in [runtime.md](runtime.md). Some of them are legitimate user-program bugs (ICL275I on a 32-bit value being stored into a 16-bit slot), some indicate a compiler bug (ICL123I NEXT stack overflow when the program has no obvious loop), and some are spec-compliance failures (ICL633I for a program missing its GIVE UP).

The debug workflow:

1. Note which ICL code fired.
2. Read the codegen for the statement type that triggers that particular ICL. For example, ICL275I is emitted by `codegen_assign` for scalars; the check is `cmp w0, #65535; b.hi _rt_error_E275`.
3. Trace backwards from the failing statement: what RHS expression produced the oversized value?
4. If the answer is "nothing should have produced this value", the bug is in the runtime or in the expression evaluator. Keep going.

A useful crutch: modify the source program to precede the suspect statement with `DO READ OUT .N` for the scalar in question. Roman-numeral output of an intermediate value reveals the arithmetic step where the error originates.

## Runtime crashes

`SIGSEGV` in the compiled binary is usually one of:

- The codegen emitted an addressing expression that the assembler accepted but the CPU rejects (exceedingly rare — three-register addressing on x86-64 is usually caught by the assembler).
- The runtime mis-manages the stack: a saved register is not restored, or a stack-local buffer was sized incorrectly.
- The codegen overwrote a callee-saved register without saving it.

The fastest diagnosis tool is `lldb` or `gdb`:

    lldb ./failing
    (lldb) run
    (lldb) bt

The backtrace reveals the fault address and the call chain. Match the fault address against the disassembly (`otool -tv ./failing` on macOS, `objdump -d ./failing` on Linux). The bug is usually the instruction or two *before* the fault, not the fault itself.

The Linux x86-64 Label 666 open/write bug described in `memory/bugs_learned.md` is a representative case. A local on-stack buffer for a C string collided with a previously-stored `alloc_size`, because both used the same `[rbp-32]` slot. The symptom was `SIGSEGV` on `ret` in `_rt_sys666_open`. The fix was to move `alloc_size` into a callee-saved register (`r14`). The diagnosis came from reading the disassembly alongside the runtime source and spotting the shared slot.

## Wrong output

The hardest category. The binary compiles, runs, exits, and prints the wrong answer. Nothing flagged anything.

Strategy in order of escalation:

1. Compare the output to the expected. How big is the diff — one byte, one line, one word? One byte usually means an arithmetic off-by-one or a TTM tape miscalculation. Longer suggests a control-flow divergence.
2. Reproduce with the smallest possible input. Delete statements until the divergence no longer reproduces; the last statement whose deletion fixes it is the one the bug lives in.
3. Compile the reduced reproducer with `INTERCAL_ASM_ONLY=1` and read the emitted assembly for that statement. Does it match your mental model of what the codegen should produce?
4. If it does, the bug is in the runtime routine the codegen called. Open the corresponding `_rt_*` routine in the platform assembly file and read it.
5. If it doesn't, the bug is in the codegen. Work back from the mismatched assembly to the codegen function that produced it, and from there to the input state of the statement at that point in the pipeline.

An underused technique for wrong-output bugs: the differential test against `--pure-syslib`. If the bug disappears when switching to the pure syslib, the native syslib is the culprit. If the bug persists, the runtime or the compiler itself is implicated. Running both forms of the same program and comparing outputs is cheap and sharply diagnostic.

## Platform-specific bugs

A bug that reproduces on one platform and not another is almost always one of:

- A syscall number mismatch.
- A calling convention difference (argument passing, preserved registers).
- An assembler syntax that our codegen emits in macOS form and the Linux translation did not fully convert.

The Docker-based reproducer `tests/cross_test.sh` is the primary tool here:

    zsh tests/cross_test.sh linux_arm64
    zsh tests/cross_test.sh linux_x86_64

From a macOS development machine, those commands reproduce the Linux CI job byte-for-byte, locally, in ~3 minutes. Any bug that shows up in CI and not on your laptop is reproducible this way.

## Bisecting across commits

When a previously-green test starts failing, `git bisect` is almost always the right tool:

    git bisect start
    git bisect bad HEAD
    git bisect good <last known good commit>
    git bisect run zsh tests/run_tests.sh --filter <test_name>

`git bisect run` automates the bisect loop, running the filter-test at each commit and classifying as good or bad. Typical bisect depth for this repo's history is 6–8 steps, a few minutes total.

A caveat: the template manifest (`src/compiler/templates/manifest.txt`) is updated in lock-step with template regeneration. A bisect that lands on a commit mid-rebuild of a template may see `verify_manifest.sh` fail independently of the test. Use `--skip` to step past such commits.

## Pipeline dump

`tools/pipeline_dump.sh` is a convenience wrapper:

    tools/pipeline_dump.sh tests/test_hello.i

It prints each intermediate stage of compilation for the given program: the tokenised statement list, the generated assembly, and (optionally) the linked binary's disassembly. Useful for explaining the pipeline to somebody else, less useful as a debugging tool because `INTERCAL_ASM_ONLY=1` already gives you the one stage you usually want.

## Lint checks

`tools/lint_intercal.sh` runs basic sanity checks against `.i` files: politeness balance, obvious typos in verb keywords, unreferenced labels. `tools/lint_assembly.sh` scans `.s` files for known platform pitfalls (three-register x86 addressing, misplaced `//` in x86 source, etc.). Both are invoked in CI but can be run locally:

    zsh tools/lint_intercal.sh src/compiler/*.i
    zsh tools/lint_assembly.sh src/runtime/*.s

A lint failure is not definitive proof of a bug, but it is a strong hint.

## Memory: keeping the bug history

The private `memory/bugs_learned.md` file, per developer, records critical bugs and what we learned from them. The existing entries cover the major regressions: the syslib prepend-vs-append issue, the DON'T tokenisation bug, the Linux x86-64 stack-slot collision.

New bugs worth documenting are those whose fix is non-obvious from the diff — usually a root-cause analysis deeper than "we forgot to handle case X". Updating `memory/bugs_learned.md` after debugging a hard bug is one of the few routine maintenance habits the project has.

## Exercises

1. Deliberately break `intercalc.sh` by changing the politeness ratio bounds from (1/5, 1/3) to (1/4, 1/3). Which tests fail? Reproduce the failure with `zsh tests/run_tests.sh --verbose`.
2. Write an INTERCAL program that fires ICL123I (NEXT stack overflow). How many NEXT statements do you need at minimum?
3. Break `_rt_mingle` in the macOS ARM64 runtime by changing one instruction. Run `zsh tests/run_tests.sh`. Which tests fail first? What does the failure mode tell you about how many tests exercise mingle?
4. Use `git bisect run` to identify the commit where the Linux x86-64 Label 666 open/write bug was fixed. (Check the commit log to find a plausible endpoint; don't rely on your memory.)
5. Run `tools/lint_intercal.sh src/compiler/stage3.i`. Does it flag anything? If so, is the flag a real problem?
