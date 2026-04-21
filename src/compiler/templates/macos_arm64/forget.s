.section __TEXT,__text
.global _main
.align 2

_main:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  // Save argc/argv for Label 666
  adrp x2, _rt_argc@PAGE
  add x2, x2, _rt_argc@PAGEOFF
  str w0, [x2]
  adrp x2, _rt_argv@PAGE
  add x2, x2, _rt_argv@PAGEOFF
  str x1, [x2]


_stmt_1:  // NEXT
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #0]
  tbnz w1, #0, _stmt_1_end
  adrp x0, _next_sp@PAGE
  add x0, x0, _next_sp@PAGEOFF
  ldr w1, [x0]
  cmp w1, #79
  b.ge _rt_error_E123
  adrp x2, _next_stack@PAGE
  add x2, x2, _next_stack@PAGEOFF
  adrp x3, _stmt_1_end@PAGE
  add x3, x3, _stmt_1_end@PAGEOFF
  str x3, [x2, x1, lsl #3]
  add w1, w1, #1
  str w1, [x0]
  b _stmt_5
_stmt_1_end:

_stmt_2:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #1]
  tbnz w1, #0, _stmt_2_end
  mov w0, #99
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_1_ign@PAGE
  add x1, x1, _spot_1_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_2_end
  adrp x1, _spot_1@PAGE
  add x1, x1, _spot_1@PAGEOFF
  str w0, [x1]
_stmt_2_end:

_stmt_3:  // READ_OUT
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #2]
  tbnz w1, #0, _stmt_3_end
  adrp x1, _spot_1@PAGE
  add x1, x1, _spot_1@PAGEOFF
  ldr w0, [x1]
  bl _rt_write_roman
_stmt_3_end:

_stmt_4:  // GIVE_UP
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #3]
  tbnz w1, #0, _stmt_4_end
  mov x0, #0
  mov x16, #1
  svc #0x80
_stmt_4_end:

_stmt_5:  // FORGET
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #4]
  tbnz w1, #0, _stmt_5_end
  mov w0, #1
  adrp x1, _next_sp@PAGE
  add x1, x1, _next_sp@PAGEOFF
  ldr w2, [x1]
  subs w2, w2, w0
  csel w2, wzr, w2, mi
  str w2, [x1]
_stmt_5_end:

_stmt_6:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #5]
  tbnz w1, #0, _stmt_6_end
  mov w0, #42
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_1_ign@PAGE
  add x1, x1, _spot_1_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_6_end
  adrp x1, _spot_1@PAGE
  add x1, x1, _spot_1@PAGEOFF
  str w0, [x1]
_stmt_6_end:

_stmt_7:  // READ_OUT
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #6]
  tbnz w1, #0, _stmt_7_end
  adrp x1, _spot_1@PAGE
  add x1, x1, _spot_1@PAGEOFF
  ldr w0, [x1]
  bl _rt_write_roman
_stmt_7_end:

_stmt_8:  // GIVE_UP
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #7]
  tbnz w1, #0, _stmt_8_end
  mov x0, #0
  mov x16, #1
  svc #0x80
_stmt_8_end:
  b _rt_error_E633


// ========== Program Data ==========
.section __DATA,__data
_stmt_flags:
  .byte 0
  .byte 0
  .byte 0
  .byte 0
  .byte 0
  .byte 0
  .byte 0
  .byte 0

.section __DATA,__bss

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

