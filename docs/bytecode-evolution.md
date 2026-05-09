# The bytecode tier

The native compiler in `src/bootstrap/intercalc.sh` produces an
ARM64 (or x86-64) executable. Alongside it lives a second tier in
`src/bytecode/`: a compiler-to-bytecode (`intercalc_bc.sh`) and a
stack-VM interpreter (`intercalc_vm.sh`). Both are implemented in
zsh and run anywhere zsh runs. Together they let any INTERCAL
program execute by two independent paths and cross-validate.

This chapter walks through the design, the op set, and what the
bytecode tier covers today.

## Why two tiers

Production compilers usually run code in two shapes for separate
reasons:

- OCaml compiles to ZINC bytecode for fast development and to
  native code for shipping.
- V8 has Ignition (bytecode interpreter) and TurboFan (optimising
  JIT). New code starts on the interpreter; hot paths migrate to
  the JIT.
- GCC has GIMPLE and RTL. The IRs serve different optimisations.
- Cranelift compiles WebAssembly to its CLIF IR before lowering.

Each compiler trades off in its own dimension. Here the bytecode
tier is not for performance: it is for differential testing,
portability when no native runtime is built, and as a teaching
device for this section's topic.

## Architecture

The compiler reads INTERCAL source and emits a flat sequence of
ops, one per line:

    STMT_ENTER 1
    IPUSH 5
    POPV .1
    ESTMT
    STMT_ENTER 2
    VPUSH .1
    READOUT
    ESTMT
    STMT_ENTER 3
    EXIT
    ESTMT

The VM reads the entire op stream into an in-memory array, then
runs an interpreter loop that dispatches per opcode. A stack
`stack[]` holds intermediate expression values; named storage
holds variables (`spot[]`, `twospot[]`, arrays).

## The op set

Pushed on the stack:

- `IPUSH N` push integer literal
- `VPUSH .N` push spot variable value
- `VPUSH2 :N` push twospot variable value

Stack arithmetic:

- `MINGLE`, `SELECT` — pop two, push result
- `UAND`, `UOR`, `UXOR` — unary operators on adjacent bits

Statement boundaries:

- `STMT_ENTER N` — abstain check, skip to ESTMT if abstained
- `ESTMT` — close the current statement; check for COME FROM
  redirect

Variable I/O:

- `POPV .N`, `POPV2 :N` — store top of stack
- `STASH`, `RETRIEVE`, `IGNORE`, `REMEMBER` — variable lifetime ops

Control flow:

- `LABEL N` — mark a labelled stmt position
- `COMEFROM N` — register a redirect from label N
- `CALL N` — push current PC, jump to label N
- `RESUME N` — pop N entries, branch to last popped PC
- `FORGET N` — drop N entries from the call stack
- `BRANCH N` — unconditional jump to label N (NEXT FROM)
- `BRANCH_NZ N` — pop a value, jump if bit 0 set
- `ABSTAIN_LBL N` / `REINSTATE_LBL N` — set / clear abstain bit
- `ABSTAIN_GER NAME` / `REINSTATE_GER NAME` — by gerund

Arrays:

- `DIM_N <arr> <ndims>` — allocate, store dim list
- `APUT_N <arr> <ndims>` — pop subscripts and value, store
- `AGET_N <arr> <ndims>` — pop subscripts, push element

I/O:

- `READOUT`, `READOUT2` — print Roman numeral
- `READOUT_ARR <arr>` — TTM output (bit-reversed tape head)
- `WRITEIN .N` — read English digit names, store
- `WRITEIN_ARR <arr>` — same, per-element

Probability and exit:

- `PROB N` — roll, skip the rest of the stmt if `RANDOM%100 >= N`
- `EXIT` — terminate

## What it can run

`tests/test_bytecode_equiv.sh` is the differential-testing harness.
It runs every `tests/test_*.i` regression program through both
the native compiler and the bytecode tier and asserts identical
output. As of the most recent landing, **16 of 35** regression
programs pass equivalence. The 19 skips are tests that exercise
features not yet ported (a few error-injection tests that
intentionally trigger ICL codes the bytecode reports differently)
or rely on the WRITE IN harness's stdin plumbing.

The 16 passes include:

- All literal-arithmetic programs.
- Programs using STASH/RETRIEVE/IGNORE/REMEMBER.
- COME FROM control flow.
- NEXT/RESUME with the call stack.
- ABSTAIN/REINSTATE (label + gerund).
- Multi-dimensional arrays.
- TTM string output (Hello, World!).
- Programs invoking syslib arithmetic (1009/1010/1530/etc.).

## Cross-validation as a primary use

The bytecode tier and the native compiler are two independent
implementations of INTERCAL semantics. They share only the source
parser at the front (and even that is reimplemented in
`intercalc_bc.sh`). When they disagree on output, exactly one is
buggy. Running the equivalence sweep on every CI build is a cheap
way to catch regressions in either tier.

This is the same pattern Csmith uses against C compilers: compile
the same program with two compilers, compare outputs, the diff
points to a bug.

## Tracing

`BC_TRACE=1` tells the VM to emit one stderr line per executed op
with the current PC and the data stack:

    [bc-trace pc=1 op=STMT_ENTER 1 stack=]
    [bc-trace pc=2 op=IPUSH 5 stack=]
    [bc-trace pc=3 op=POPV .1 stack=5]

Useful when bytecode and native disagree on a particular program.

## What's deferred

The bytecode tier intentionally lacks features that have low
educational return on investment:

- Two-tier JIT compilation. The bytecode is interpreted, never
  natively compiled. V8 / OCaml do this; we do not.
- The peephole optimisations the native compiler runs. The
  bytecode tier exists to validate semantics, not to be fast.
- Syscalls beyond the Label 666 set already supported.

If a new INTERCAL feature lands in the native compiler, the
bytecode tier should grow a corresponding op so equivalence holds.
The pattern is consistent: a new op, a per-op handler in the VM,
a new bullet in the equivalence sweep's coverage.
