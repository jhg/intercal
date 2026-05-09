# Learning by extending: a guided tour

The shortest path from "I read the chapters" to "I can change the
compiler" is to follow a real change end to end. This chapter walks
through three landings from the 2026-05-09 session, each one a
different kind of compiler work, and each chosen so the analogue in
a production compiler is direct.

The three changes:

1. A new statement form (NEXT FROM) added to lexer, parser, analyses,
   and codegen. The mirror in production compilers: any frontend
   feature, from a new keyword to a new operator.
2. An IR migration scaffold (`INTERCAL_NEW_IR=1`) that routes one
   statement type at a time through a new lowering path. The mirror:
   GCC's GIMPLE introduction, rustc's MIR migration, V8's TurboFan
   replacing Crankshaft.
3. A real Wegman-Zadeck SCCP behind `--emit-sccp-wz`. The mirror:
   every production compiler ships a constant-propagation pass; the
   1991 paper is the canonical reference.

If you read these in order you will see the same shape of change at
three different layers of the compiler. Each section ends with a
"now do this" suggestion: a small extension you can pick up to
practise the technique.

## 1. Adding a new statement: NEXT FROM

The motivating problem is documented in `loop-extension.md`. Standard
INTERCAL has no `for`, no `while`, and the standard COME FROM dance
needs ten or more statements per logical loop because conditional
ABSTAIN itself recurses the same control-flow problem.

We adopted Option B from CLC-INTERCAL: `(LABEL) NEXT FROM <expr>`,
a backward branch that does not push the NEXT stack and is
conditioned on bit 0 of an expression.

The change touched, in order:

- The classifier in `intercalc.sh:classify_statement` learned two new
  body shapes:
  - `(N) NEXT FROM <expr>` for the conditional form,
  - `(N) NEXT FROM` for the unconditional form.
  Both set `stmt_type[$idx]="NEXT_FROM"` and store the optional
  expression in a new parallel array `stmt_next_from_expr[]`.
- Every analysis pass that enumerated control-flow stoppers
  (`is_leader[]` for basic-block detection, the predecessor
  computation in `compute_var_constants`, the STASH/RETRIEVE
  soundness analysis) gained `NEXT_FROM` to its case alternation.
- A new `codegen_next_from()` emits a single `b _stmt_<ref>` for the
  unconditional form, or evaluates the expression and emits a `tbnz
  w0, #0, _stmt_<ref>` for the conditional form. No NEXT-stack push.
- The `check_unreferenced_labels()` pass added NEXT_FROM to the list
  of references so a label used only by NEXT FROM is not flagged.
- A regression test, `tests/test_next_from.i`, exercises a counter
  loop that prints "V" after exactly five iterations.

Production-compiler analogue. When LLVM gains a new IR opcode (e.g.,
`freeze`) the change is shaped identically: parser/builder
extension, every pass that switches on opcode learns the new case,
SelectionDAG/GlobalISel codegen gains the lowering, verifier gains
a check. The diff is bigger because LLVM has more passes; the shape
is the same.

Now do this. Add a third NEXT FROM form: `(LABEL) NEXT FROM AT
MOST <const>` that branches at most `const` times and then falls
through unconditionally. You will need a new BSS counter per such
statement, an increment-then-compare in codegen, and a test that
shows the branch fires exactly `const` times.

## 2. Migrating codegen to consume an IR

The motivating problem comes from middle-end-and-optimisation.md.
The legacy codegen walks the parse tree directly and emits assembly
in one pass. There is no IR for an optimiser to chew on, so passes
like SCCP, GVN, and DCE have nowhere to live.

We did not rewrite codegen. We installed a *scaffold* for an
incremental migration. The shape of that scaffold is the same one
GCC, rustc, and V8 used:

- A new IR data structure already exists (`ir_ops[]`, populated by
  `build_ir()`, dumped by `--emit-ir-real`). Read-only at first.
- A feature flag (`INTERCAL_NEW_IR=1`) gates the new path. Off by
  default; the legacy path is the source of truth.
- The codegen dispatch in `codegen_statement` now has two branches:
  - With the flag set, try `lower_ir_for_stmt(i)` first. Return on
    success.
  - Otherwise (or on fall-through from an unsupported op), use the
    legacy `case "${stmt_type[$i]}" in ... esac` dispatch.
- The new lowering supports exactly one statement type today:
  `GIVE_UP`. Each platform (`macos_arm64`, `linux_arm64`,
  `linux_x86_64`) has a per-platform exit-syscall sequence.
- A regression test (`tests/test_new_ir.sh`) confirms three things:
  the legacy path still works, the IR-driven path produces the
  same output, and a program mixing supported and unsupported
  statement types compiles correctly via the per-type fallback.

The flag is the load-bearing piece of the migration. It lets the
next slice (say, ASSIGN) be added by writing `lower_ir_for_stmt`
support for ASSIGN and a test for it, without touching the legacy
codegen at all.

Production-compiler analogue. GCC's GIMPLE was introduced this way
in 2003: a new IR layered between the frontend and the existing
RTL backend. RTL did not go away; for years GIMPLE-aware passes
ran first, then the result was lowered to RTL for the rest of the
pipeline. rustc's MIR migration in 2016-2018 followed the same
shape: borrow checking moved from HIR to MIR one query at a time,
gated by a query-cache flag, with the old path remaining as a
fallback until parity was reached.

Now do this. Add `lower_ir_for_stmt` support for the next-easiest
statement type. Candidates in increasing complexity:

- `STASH` (one-store-per-var, no expression evaluation).
- `IGNORE` / `REMEMBER` (one bit flip per var, no expression).
- `READ_OUT` for scalars (call into the runtime's Roman-numeral
  routine).
- `ASSIGN` of a literal RHS (no expression tree to walk).

Pick one. Add an op to `build_ir()`. Add a case to
`lower_ir_for_stmt()`. Extend `tests/test_new_ir.sh`. The legacy
path stays in place; if you break the new path the flag stays off
and nothing else suffers.

## 3. Implementing a textbook algorithm: Wegman-Zadeck SCCP

The motivating problem is the standard one: const-prop should follow
the CFG faithfully so it can prove unreachable branches dead and
propagate constants across them. The 1991 Wegman-Zadeck paper is the
canonical algorithm.

The change added `emit_sccp_wz`, separate from the simpler
`emit_sccp` linear-walk dump. The new function is a faithful
implementation of the paper at a small scale:

- Three-element lattice `TOP < CONST(c) < BOTTOM`. `meet_lattice()`
  implements the pointwise meet:
  - `TOP ∧ x = x`,
  - `BOTTOM ∧ x = BOTTOM`,
  - `CONST(c) ∧ CONST(c) = CONST(c)`,
  - `CONST(c1) ∧ CONST(c2) = BOTTOM` for `c1 ≠ c2`.
- Per-statement outgoing values stored in
  `outgoing[<stmt>_<varspec>]`.
- Executable-edge gating via `exec_into[i] = 1` when an incoming
  edge has been proven reachable. Statements with no executable
  predecessors are not visited.
- A worklist (`worklist=()` array) of statement indices. Each pop
  re-evaluates the meet of executable predecessors and updates
  outgoing values; when something changes, successors are
  enqueued.
- Predecessor edges include fall-through plus NEXT and NEXT_FROM
  source edges. (COME FROM source edges are still future work.)

The output is a teaching dump: per-statement lattice values,
listing every variable seen at each program point. It is not yet
consumed by codegen, but the data structure (`outgoing[]`) is the
exact thing a codegen pass would consult.

Production-compiler analogue. LLVM's `SCCP` transform in
`Transforms/Scalar/SCCP.cpp` is the same algorithm at production
scale; `IPSCCP` is the interprocedural variant. GCC's
`tree-ssa-ccp.c` is the GIMPLE counterpart. The shape is
identical: lattice + worklist + per-value tracking. The
production versions add: more lattice values (e.g., bit-level
known-value), broader value-evaluation rules (covering the full
operator set), and integration with the surrounding pass
manager.

Now do this. Extend `emit_sccp_wz` to model two more cases:

1. The arithmetic syslib calls 1009 (add with carry flag) and
   1010 (subtract). When the inputs are both `CONST(N)`, evaluate
   the operation and produce `CONST(N+M)` (mod 65536) for 1009.
2. COME FROM source edges in `preds[i]`. Today, statements with
   an incoming COME FROM only see the fall-through predecessor;
   the lattice should meet with the source statement's outgoing
   value too.

Each is ten lines or so and exercises a different facet of the
algorithm.

## A common pattern across all three

The three changes have the same shape:

- A small change to one or two data structures.
- A new code path gated behind a flag, environment variable, or
  separate function name.
- A regression test that exercises the new path end to end.
- The legacy path left in place as the source of truth.

This pattern shows up in every production compiler. The pre-MIR
borrow checker stayed live in rustc for a year after MIR landed.
GCC's `tree-ssa-uninit.c` runs alongside the older
`tree-ssa-strlen.c` even though both touch the same warning
class. LLVM has both `SimplifyCFG` and `JumpThreading` for
overlapping cleanups. They coexist because the cost of removing
the old path early is higher than the cost of carrying it.

When you propose a change, default to this shape: feature flag,
new path alongside the old path, regression test that proves the
new path works on at least one input. The reviewers will thank
you. The bisect log will be cleaner. The rollback is one boolean.

## Inspection flags worth knowing about

While extending the compiler you will often want to see what an
analysis pass actually produced. Each flag below answers a specific
question, exits before codegen, and prints to stdout so you can
pipe to grep or save for diff.

| Flag | Question it answers |
|------|---------------------|
| `--diagnose` | How many statements? Politeness ratio? Label and syslib summary? |
| `--emit-tokens` | What did the lexer see? Token stream by category. |
| `--emit-3addr` | What does each statement become at the GIMPLE-shaped flat IR level? |
| `--emit-cfg` | Basic blocks and their edges, in the LLVM/MIR vocabulary. |
| `--emit-ir-real` | The real three-address IR (CONST, LOADV, STORE, MINGLE, etc.) used by the IR-driven codegen path. |
| `--emit-ssa` | Block-parameter SSA form (Cranelift-style). |
| `--emit-sccp` | Linear-walk lattice values (simpler teaching dump). |
| `--emit-sccp-wz` | Faithful Wegman-Zadeck SCCP with executable-edge gating and meet at confluence points. Models syslib 1009/1010/1020/1030 in the lattice. |
| `--emit-regalloc` | Linear-scan register allocation trace (live intervals, spills). |
| `--emit-effects` | Per-statement set of ICL error codes the statement could raise. |
| `--emit-opt-summary` | Summary counts: how many E275/E621/E436 elisions fired, abstain-flag eliminations, constant-prop entries. |
| `--time-report` | Per-phase timing breakdown. |
| `--opt-bisect-limit=N` | Disable any optimisation past the N-th, for finding miscompile by bisection. |

Two environment variables also gate behaviour:

| Variable | Effect |
|----------|--------|
| `INTERCAL_NEW_IR=1` | Try the IR-driven lowering path before legacy. |
| `INTERCAL_REGALLOC_HINTS=1` | Emit `// regalloc:` comments at variable assignments. |

The pattern is the same for every flag: run the analysis, dump
what it computed, exit. No flag changes generated code (with the
sole exception of the two environment variables, which gate
opt-in codegen paths).

## What to read next

If you finish all three "now do this" exercises, you have a
pattern you can apply to almost any compiler change. From here:

- Read `from-intercal-to-real-compilers.md` for the bridge to the
  ten production compilers covered in Part VII.
- Pick the production compiler closest to your interest (LLVM if
  you want hands-on optimisation work; rustc if you want a
  query-driven model; Cranelift if you want a small one to read
  end to end). Read its chapter, then start by following its
  `CONTRIBUTING.md`'s "good first issue" path.
- Come back to this compiler periodically. The point of a small
  compiler is that the round-trip is short: write the analysis,
  run it, debug it, in minutes. Production compilers reward
  patience; this one rewards iteration.
