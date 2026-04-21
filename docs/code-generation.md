# Code generation

Most compilers lower their parse tree into an intermediate representation, optimise that, and then lower again into target code. Our compiler skips the middle step entirely. Every statement of INTERCAL is turned directly into a block of ARM64 or x86-64 assembly, one function-shaped fragment per statement, glued together inside `_main`.

This chapter explains why the direct approach works for INTERCAL, what the emitted code looks like, and where each piece lives in `src/bootstrap/intercalc.sh`.

## Why no intermediate representation

An IR pays off when you want to share optimisations across source languages or backends, or when you want to apply classical optimisations (constant folding, dead-code elimination, register allocation). We have none of those needs:

- One source language, INTERCAL, that is silly enough that optimisation is mostly a non-goal.
- Two backends — ARM64 and x86-64 — handled by two codegen modules. Three if you count the macOS/Linux ARM64 split, but that is just a `sed` pass at the end.
- A runtime that already encapsulates the complicated bits (Roman numerals, the Turing tape, mingle/select, error exits) as callable routines. Each INTERCAL statement degenerates to a handful of moves plus a call.

Without an IR, every codegen function is a string template that interpolates the variable numbers and the expression tree's root node. That keeps the compiler well under 2000 lines of zsh and makes each emitted fragment trivially inspectable with `INTERCAL_ASM_ONLY=1`.

## The emitted program layout

After codegen finishes, the generated assembly looks like this, regardless of the input:

    .section __TEXT,__text
    .align 2
    .global _main
    _main:
      ; save argc / argv for Label 666 syscalls 5 and 6
      ; install a nonzero value at _stmt_flags[i] for every statement whose
      ;   stmt_negated was 1 at compile time
      b _stmt_0_start
    _stmt_0_start:
      ; check _stmt_flags[0]; if set, jump to _stmt_0_end
      ; optionally roll a probability
      ; ... emitted body for statement 0 ...
      ; if a COME FROM targets statement 0's label, jump to its body here
    _stmt_0_end:
    _stmt_1_start:
      ; same shape
    _stmt_1_end:
    ...
    _stmt_N_start:
      ; statement N body
    _stmt_N_end:
      ; fallthrough past the last statement → ICL633I
      bl _rt_error_E633

    .section __DATA,__data
    ; per-program data: roman numeral table pointers etc.

    .section __DATA,__bss
    _stmt_flags: .space N_STATEMENTS
    _spot_1:     .space 4
    _spot_1_ign: .space 1
    _twospot_1:  .space 4
    ; ... one pair (value, ignore-flag) per used variable ...
    _tail_1_ptr: .space 8
    _tail_1_dims: .space 64    ; up to 16 dimensions
    ; ... one per used array ...

The key invariants:

- Each statement has a contiguous `_stmt_i_start` → `_stmt_i_end` block. Jumps from `NEXT`, `ABSTAIN`, `COME FROM` target the `_start` labels.
- Scalar variables get a 4-byte slot and a 1-byte "ignored" flag. The codegen emits a check of the ignored flag before every write, silently discarding stores if set.
- Arrays get a pointer slot (set by the dimensioning statement via `_rt_mmap`) and a fixed-size dimensions table.
- `_stmt_flags` is a byte per statement: zero means "live", nonzero means "abstained".

## The dispatch: `codegen_statement`

The statement dispatcher sits at `codegen_statement`, around line 791 of `intercalc.sh`. Its skeleton:

    codegen_statement() {
      local i=$1
      emit "_stmt_${i}_start:"
      # abstain flag check
      emit "  adrp x0, _stmt_flags@PAGE"
      emit "  add x0, x0, _stmt_flags@PAGEOFF"
      emit "  ldrb w1, [x0, #${i}]"
      emit "  cbnz w1, _stmt_${i}_end"
      # probability roll if stmt_prob < 100
      (( stmt_prob[i] < 100 )) && codegen_probability $i
      # dispatch on stmt_type
      case "${stmt_type[$i]}" in
        ASSIGN)      codegen_assign $i ;;
        READ_OUT)    codegen_read_out $i ;;
        WRITE_IN)    codegen_write_in $i ;;
        NEXT)        codegen_next $i ;;
        RESUME)      codegen_resume $i ;;
        FORGET)      codegen_forget $i ;;
        ABSTAIN)     codegen_abstain $i ;;
        ...
        GIVE_UP)     codegen_give_up ;;
        UNKNOWN)     emit "  bl _rt_error_E000" ;;
      esac
      # if any COME FROM targets this statement's label, jump to its body
      if [[ -n "${come_from_target[${stmt_label[$i]}]}" ]]; then
        local tgt="${come_from_target[${stmt_label[$i]}]}"
        emit "  b _stmt_${tgt}_start"
      fi
      emit "_stmt_${i}_end:"
    }

The abstain check is uniform across every statement, so it sits in the dispatcher, not inside each `codegen_<type>`. Same for the probability roll.

## A small example end to end

Take the three-line program:

    DO .1 <- #5
    PLEASE READ OUT .1
    DO GIVE UP

After lexing, `stmt_count=3` and:

    stmt_type  = (ASSIGN READ_OUT GIVE_UP)
    stmt_body  = (".1 <- #5" "READ OUT .1" "GIVE UP")
    stmt_polite= (0 1 0)

`check_politeness` sees 1 polite out of 3 total: `1*5=5 >= 3` ✓, `1*3=3 <= 3` ✓, so we pass. There are no labels or COME FROMs. No syslib range labels are targeted, so `needs_syslib=0`.

`codegen_program` emits the prologue. `codegen_statement(0)` dispatches to `codegen_assign`, which parses `#5` into a single constant node, calls `codegen_expr` on that node to emit:

    mov w0, #5

and then emits the 32→16-bit overflow check, the ignore-flag check, and the store:

    mov w1, #65535
    cmp w0, w1
    b.hi _rt_error_E275
    adrp x1, _spot_1_ign@PAGE
    add x1, x1, _spot_1_ign@PAGEOFF
    ldrb w2, [x1]
    cbnz w2, _stmt_0_end
    adrp x1, _spot_1@PAGE
    add x1, x1, _spot_1@PAGEOFF
    str w0, [x1]

`codegen_statement(1)` dispatches to `codegen_read_out`, which recognises `.1` as a scalar expression, parses it, emits a load of `_spot_1` into `w0`, and then emits:

    bl _rt_write_roman

`codegen_statement(2)` dispatches to `codegen_give_up`, which on macOS ARM64 emits:

    mov x0, #0
    mov x16, #1
    svc #0x80

On Linux ARM64 the `sed` conversion later rewrites `mov x16, #1` into `mov x8, #93` and `svc #0x80` into `svc #0`. On Linux x86-64 the equivalent function in `codegen_x86_64.sh` emits:

    mov rdi, 0
    mov rax, 60
    syscall

That is all three statements compiled. The only thing left is `emit_data`, which appends the BSS section with `_stmt_flags: .space 3`, `_spot_1: .space 4`, `_spot_1_ign: .space 1`, and a handful of data symbols used by the runtime (the roman numeral table pointer, etc.).

## Expressions: `codegen_expr`

Expressions are tree-walked by `codegen_expr`, which takes the index of a tree node and emits code that leaves the value in `w0` (or `x0` for 32-bit-wide values). The recursion:

- `NODE_CONST` → `mov w0, #VAL`.
- `NODE_VAR` → load the variable into `w0`, checking bounds where applicable.
- `NODE_MINGLE` → codegen left into `w0`, push `w0`, codegen right into `w0`, pop into `w1`, swap, call `_rt_mingle`. Result in `x0` (32-bit).
- `NODE_SELECT` → similar, call `_rt_select`.
- `NODE_UNARY_AND/OR/XOR` → codegen child, call `_rt_unary_and_16` etc.
- `NODE_ARRAY_REF` → codegen each subscript onto the stack, call the array-index helper, load the element.

All operator evaluation is delegated to the runtime. The codegen doesn't try to inline mingle or select. This keeps the emitted code short and means that bug-fixing or optimising `_rt_mingle` affects every compiled program without re-running the compiler.

### Tree shape matters

Because there is no precedence in INTERCAL, the shape of the expression tree is fully determined by the explicit grouping in the source. That means the tree that comes out of `parse_expr` is already in the order we want to evaluate it in. No dependency-ordering, no reassociation.

## Per-statement codegen, in detail

Here is what each `codegen_<type>` emits, in condensed form:

| Statement | Emitted behaviour |
|-----------|-------------------|
| `ASSIGN scalar` | Eval RHS into `w0`, check ≤ 65535 (ICL275I if 16-bit target), check ignore flag, store. |
| `ASSIGN array elem` | Eval subscripts, compute offset, eval RHS, store via the array pointer. |
| `ASSIGN array dim` | Eval dimensions, call `_rt_mmap` for new storage, store pointer + dims table. |
| `READ_OUT` var | If scalar, load + `bl _rt_write_roman`. If array, `bl _rt_read_out_array`. |
| `WRITE_IN` var | If scalar, `bl _rt_write_in_scalar`, store result. If array, `bl _rt_write_in_array`. |
| `NEXT (N)` | Push return address onto the NEXT stack, check overflow (ICL123I), branch to `_stmt_<target>_start`. |
| `RESUME expr` | Eval expr into `w0`, call `_rt_resume_1` which pops K entries and returns. Zero fires ICL621I. |
| `FORGET expr` | Eval expr, subtract from the NEXT stack pointer, saturate at zero. |
| `ABSTAIN FROM (N)` | `_stmt_flags[<idx>]` ← 1. |
| `ABSTAIN FROM gerund-list` | For each gerund, loop over all statements of that type at compile-time and emit one store each. |
| `REINSTATE ...` | Same but store zero. |
| `IGNORE var-list` | `_<type>_N_ign` ← 1 for each listed variable. |
| `REMEMBER var-list` | Same but store zero. |
| `STASH var-list` | For each var, push current value onto the per-variable stash stack. Overflow guarded. |
| `RETRIEVE var-list` | Pop from the per-variable stash stack; underflow fires ICL436I. |
| `COME FROM (N)` | No body is emitted — the previous statement's body already jumps here. |
| `GIVE UP` | Exit 0. |
| `UNKNOWN` | `bl _rt_error_E000`. |

Each one lives in its own `codegen_<type>` function, lines 853–1621.

## Ignore flags: a small trick

A statement is abstained at the *statement* level; a variable is ignored at the *variable* level. Both are per-entity bitmaps in BSS:

- `_stmt_flags[i]` — one byte per statement.
- `_<type>_<n>_ign` — one byte per used variable.

The codegen checks both. The statement-level flag is checked once at the top of the block (by the dispatcher). The variable-level flag is checked inside the store sequence for that variable, so a write is discarded silently but an expression that reads an ignored variable still reads the last value written.

This dual-level flag pattern is one of the small non-obvious pieces of the compiler. When we get to `stage3.i`, the same layout is reproduced in INTERCAL arrays, because it compiles to exactly the same underlying BSS layout.

## The x86-64 backend

`src/bootstrap/codegen_x86_64.sh` is sourced by `intercalc.sh` when the platform is `linux_x86_64`. It redefines the `codegen_*` functions with x86-64 equivalents, using Intel syntax (`.intel_syntax noprefix`), RIP-relative addressing, and the System V AMD64 calling convention. The ARM64 codegen in the base file is untouched; zsh's last-function-wins semantics is what makes the override work.

Two platform-specific pitfalls worth surfacing here:

- x86-64 GNU-as does not accept `//` as a comment delimiter; use `#`. The codegen override is careful about this.
- x86-64 supports at most `[base + index*scale + disp]`, so three-register expressions like `[r12 + r14 + rcx]` are illegal. The generated code uses `lea` first to pre-compute a two-register base.

The full catalogue of platform pitfalls is in `AGENTS.md`, "Assembly pitfalls by platform".

## Observability

The two ways to see what codegen produced:

    INTERCAL_ASM_ONLY=1 zsh src/bootstrap/intercalc.sh < program.i > program.s
    tools/pipeline_dump.sh program.i

The first gives you the generated assembly *after* the Linux ARM64 `sed` conversion (if applicable). The second is a higher-level dump that shows each phase. Use them when you are adding a new statement type or chasing a codegen bug; do not use them as a verification tool, because the assembly output can be legitimately different across platforms.

## Next reading

- [runtime.md](runtime.md) — every `_rt_*` routine the emitted code calls.
- [syslib.md](syslib.md) — how NEXT to labels 1000–1999 fits into the codegen model.
- [platforms.md](platforms.md) — the full list of emitted-assembly differences per target.
