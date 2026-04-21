.text
.global main
.align 2

main:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  // Save argc/argv for Label 666
  adrp x2, _rt_argc
  add x2, x2, :lo12:_rt_argc
  str w0, [x2]
  adrp x2, _rt_argv
  add x2, x2, :lo12:_rt_argv
  str x1, [x2]


_stmt_1:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #0]
  tbnz w1, #0, _stmt_1_end
  mov w0, #5
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_1_ign
  add x1, x1, :lo12:_spot_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_1_end
  adrp x1, _spot_1
  add x1, x1, :lo12:_spot_1
  str w0, [x1]
_stmt_1_end:

_stmt_2:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #1]
  tbnz w1, #0, _stmt_2_end
  mov w0, #3
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_2_ign
  add x1, x1, :lo12:_spot_2_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_2_end
  adrp x1, _spot_2
  add x1, x1, :lo12:_spot_2
  str w0, [x1]
_stmt_2_end:

_stmt_3:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #2]
  tbnz w1, #0, _stmt_3_end
  adrp x1, _spot_1
  add x1, x1, :lo12:_spot_1
  ldr w0, [x1]
  stp w0, wzr, [sp, #-16]!
  adrp x1, _spot_2
  add x1, x1, :lo12:_spot_2
  ldr w0, [x1]
  mov w1, w0
  ldp w0, wzr, [sp], #16
  bl _rt_mingle
  adrp x1, _twospot_1_ign
  add x1, x1, :lo12:_twospot_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_3_end
  adrp x1, _twospot_1
  add x1, x1, :lo12:_twospot_1
  str w0, [x1]
_stmt_3_end:

_stmt_4:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #3]
  tbnz w1, #0, _stmt_4_end
  adrp x1, _twospot_1
  add x1, x1, :lo12:_twospot_1
  ldr w0, [x1]
  str x0, [sp, #-16]!
  mov w0, #85
  mov x1, x0
  ldr x0, [sp], #16
  mov w2, #32
  bl _rt_select
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_3_ign
  add x1, x1, :lo12:_spot_3_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_4_end
  adrp x1, _spot_3
  add x1, x1, :lo12:_spot_3
  str w0, [x1]
_stmt_4_end:

_stmt_5:  // READ_OUT
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #4]
  tbnz w1, #0, _stmt_5_end
  adrp x1, _spot_3
  add x1, x1, :lo12:_spot_3
  ldr w0, [x1]
  bl _rt_write_roman
_stmt_5_end:

_stmt_6:  // GIVE_UP
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #5]
  tbnz w1, #0, _stmt_6_end
  mov x0, #0
  mov x8, #93
  svc #0
_stmt_6_end:
  b _rt_error_E633


// ========== Program Data ==========
.data
_stmt_flags:
  .byte 0
  .byte 0
  .byte 0
  .byte 0
  .byte 0
  .byte 0

.bss

.align 2
_spot_3: .space 4
_spot_3_ign: .space 1
.align 3
_spot_3_stash_ptr: .space 8
_spot_3_stash_sp: .space 4
.align 2
_spot_4: .space 4
_spot_4_ign: .space 1
.align 3
_spot_4_stash_ptr: .space 8
_spot_4_stash_sp: .space 4
.align 2
_spot_5: .space 4
_spot_5_ign: .space 1
.align 3
_spot_5_stash_ptr: .space 8
_spot_5_stash_sp: .space 4
.align 2
_spot_1: .space 4
_spot_1_ign: .space 1
.align 3
_spot_1_stash_ptr: .space 8
_spot_1_stash_sp: .space 4
.align 2
_spot_2: .space 4
_spot_2_ign: .space 1
.align 3
_spot_2_stash_ptr: .space 8
_spot_2_stash_sp: .space 4
.align 2
_twospot_3: .space 4
_twospot_3_ign: .space 1
.align 3
_twospot_3_stash_ptr: .space 8
_twospot_3_stash_sp: .space 4
.align 2
_twospot_4: .space 4
_twospot_4_ign: .space 1
.align 3
_twospot_4_stash_ptr: .space 8
_twospot_4_stash_sp: .space 4
.align 2
_twospot_1: .space 4
_twospot_1_ign: .space 1
.align 3
_twospot_1_stash_ptr: .space 8
_twospot_1_stash_sp: .space 4
.align 2
_twospot_2: .space 4
_twospot_2_ign: .space 1
.align 3
_twospot_2_stash_ptr: .space 8
_twospot_2_stash_sp: .space 4
.align 3
_tail_65535_ptr: .space 8
_tail_65535_ndim: .space 4
_tail_65535_dims: .space 32
_tail_65535_ign: .space 1
.align 3
_tail_65535_stash_ptr: .space 8
_tail_65535_stash_sp: .space 4
