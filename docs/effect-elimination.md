# Effect-driven elimination

INTERCAL has 16 documented runtime errors. Every assignment,
RESUME, RETRIEVE, NEXT, ARRAY_DIM, and array access can in
principle hit one of them. The native compiler emits the
corresponding check at every site by default. When a static
analysis can prove the check unreachable, the codegen omits it.

This is the same shape of optimisation production compilers run:
LLVM's `InstCombine` simplifies bound checks when the index is
known in range; GCC's `tree-vrp` (value-range propagation) does
similar work; rustc's MIR drops bounds checks behind `unsafe`
guarantees.

This chapter documents the seven elision passes this compiler
implements, the soundness conditions for each, and where in
`intercalc.sh` the analysis lives.

## The seven elisions

| Pass | Check elided | Soundness condition |
|------|--------------|---------------------|
| E275 | 32-bit value into spot (cmp+b.hi) | RHS literal #N with N ≤ 65535, or var-to-var copy of same width, or spot→twospot widening, or SCCP-bounded var copy |
| E621 | RESUME #0 (cbz) | Argument is literal #N with N ≠ 0 |
| E436 | RETRIEVE without prior STASH (load+test) | Earlier STASH of same vars on every reachable path; no intervening RETRIEVE / NEXT / COME FROM |
| E123 | NEXT stack overflow (cmp+b.ge) | Loop-free program (no COME FROM, no NEXT FROM, no REINSTATE), forward-only NEXTs (target is past the NEXT site), total NEXT count below the 79-entry limit |
| E240 | ARRAY_DIM dim of 0 (cbz) | All dim expressions are literal nonzero #N |
| E241 | Array subscript out of bounds (cmp+b.hs) | Subscript is literal #M and the array's dim is statically known with 1 ≤ M ≤ dim |
| E632 | RESUME pops past stack bottom (b.mi) | RESUME #1 placed in a labelled block reachable only via NEXT (no COME FROM, no NEXT FROM, no REINSTATE in the program) |

Each pass populates a hash `stmt_eNNN_safe[i]` keyed by the
statement index. Each codegen site reads its safety flag and, if
set, also calls `opt_bisect_check "elim_eNNN_stmt_$i"` so
`--opt-bisect-limit=K` can disable any subset of elisions for
debugging.

## Where in the codebase

Every pass lives in `compute_e275_safety()` in
`src/bootstrap/intercalc.sh`. The function name is misleading;
it is the home of every elision analysis. The structure is one
case-arm per statement type with a final post-pass for cases that
need the full dim map. The function runs after
`compute_var_constants` so SCCP-style results inform E275.

The codegen sites that consult these flags:

- `codegen_assign` for E275 (and IGNORE check elision via a
  separate analysis).
- `codegen_resume` for E621 and E632.
- `codegen_retrieve_var` for E436.
- `codegen_next` for E123.
- `codegen_array_dim` for E240.
- `codegen_array_elem_assign` and the array-load path in
  `codegen_expr` for E241 (consults `stmt_e241_safe[current_stmt_idx]`).

## How to verify

`--emit-opt-summary` prints counts per pass:

    ASSIGN stmts:                       12
      E275 elided (cmp+b.hi skipped):   8 / 12
    RESUME stmts:                       2
      E621 elided (cbz skipped):        1 / 2
      E632 elided (b.mi skipped):       1 / 2
    RETRIEVE stmts:                     3
      E436 elided (empty-stash skip):   2 / 3
    NEXT stmts:                         5
      E123 elided (stack-depth skip):   5 / 5
    ARRAY_DIM stmts:                    1
      E240 elided (zero-dim skip):      1 / 1
    Array-access stmts E241 elided:     2

`tests/test_effect_elim_more.sh` has 11 cases covering each pass
in two flavours: a positive case where the elision should fire
(emitted assembly contains zero references to `_rt_error_eNNN`)
and a negative case where the runtime check must stay (at least
one reference). The two flavours guard against unsound elision
slipping in.

## SCCP-WZ feed

Setting `INTERCAL_SCCP_WZ_FEED=1` runs a silent Wegman-Zadeck
SCCP pass and merges its CONST results into `stmt_var_const`,
which the simpler analysis didn't catch. The most common
beneficiary is E275 elision on programs that flow constants
through arithmetic syslib calls (1009/1010/1530/etc.) — the
simpler analysis bottoms on syslib calls; SCCP-WZ models them.

The feed is sound only when the program contains no STASH or
RETRIEVE, since SCCP-WZ doesn't model the stash stacks. The
feed checks this and skips entirely on STASH/RETRIEVE programs
to avoid miscompiling.

## Production-compiler analogues

| Pass | LLVM analogue | GCC analogue |
|------|---------------|--------------|
| E275 | `InstCombine` truncation patterns | `tree-vrp` value range |
| E621 | `SimplifyCFG` constant condition | `tree-cfg` |
| E436 | `MemorySSA`-driven dead-store elim | `tree-dse` |
| E123 | call-graph based stack-depth analysis | `tree-call-cdce` |
| E240 | `LoopUnswitch` constant condition | similar |
| E241 | `IndVarSimplify` + `SCEV` known range | `graphite` |
| E632 | function-summary SCC analysis | IPA |

The shape is the same in every production compiler: an analysis
proves a property at a site; a codegen pass uses the property to
omit a runtime check; a flag disables the elision for debugging.
The scale and the depth of the analyses are different — LLVM's
ScalarEvolution is thousands of lines, our E241 analysis is fifty.
But a reader who has done one can read the other.

## Adding a new elision

The pattern is fixed:

1. Add `typeset -A stmt_eNNN_safe` near the existing maps.
2. Add a clause to `compute_e275_safety` that populates the map
   per statement, using whatever upstream analysis is needed.
3. Add `opt_bisect_check "elim_eNNN_stmt_$i"` at the codegen site
   that reads the map.
4. Add two tests to `tests/test_effect_elim_more.sh`: a positive
   case the elision should catch, a negative case it must not.
5. Add a counter to `emit_opt_summary` and a row in this chapter.

Item 4 is the load-bearing one. An unsound elision compiled a
program incorrectly is silent until someone notices a wrong
output. Two flavours of test (must elide / must not elide) make
the boundary visible.
