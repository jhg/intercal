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


_stmt_1:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #0]
  tbnz w1, #0, _stmt_1_end
  mov w0, #6
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_1_ign@PAGE
  add x1, x1, _spot_1_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_1_end
  adrp x1, _spot_1@PAGE
  add x1, x1, _spot_1@PAGEOFF
  str w0, [x1]
_stmt_1_end:

_stmt_2:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #1]
  tbnz w1, #0, _stmt_2_end
  mov w0, #1
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_2_ign@PAGE
  add x1, x1, _spot_2_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_2_end
  adrp x1, _spot_2@PAGE
  add x1, x1, _spot_2@PAGEOFF
  str w0, [x1]
_stmt_2_end:

_stmt_3:  // NEXT
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #2]
  tbnz w1, #0, _stmt_3_end
  adrp x0, _next_sp@PAGE
  add x0, x0, _next_sp@PAGEOFF
  ldr w1, [x0]
  cmp w1, #79
  b.ge _rt_error_E123
  adrp x2, _next_stack@PAGE
  add x2, x2, _next_stack@PAGEOFF
  adrp x3, _stmt_3_end@PAGE
  add x3, x3, _stmt_3_end@PAGEOFF
  str x3, [x2, x1, lsl #3]
  add w1, w1, #1
  str w1, [x0]
  b _rt_syscall_666
_stmt_3_end:

_stmt_4:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #3]
  tbnz w1, #0, _stmt_4_end
  mov w0, #1
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_1_ign@PAGE
  add x1, x1, _spot_1_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_4_end
  adrp x1, _spot_1@PAGE
  add x1, x1, _spot_1@PAGEOFF
  str w0, [x1]
_stmt_4_end:

_stmt_5:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #4]
  tbnz w1, #0, _stmt_5_end
  mov w0, #0
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_2_ign@PAGE
  add x1, x1, _spot_2_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_5_end
  adrp x1, _spot_2@PAGE
  add x1, x1, _spot_2@PAGEOFF
  str w0, [x1]
_stmt_5_end:

_stmt_6:  // NEXT
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #5]
  tbnz w1, #0, _stmt_6_end
  adrp x0, _next_sp@PAGE
  add x0, x0, _next_sp@PAGEOFF
  ldr w1, [x0]
  cmp w1, #79
  b.ge _rt_error_E123
  adrp x2, _next_stack@PAGE
  add x2, x2, _next_stack@PAGEOFF
  adrp x3, _stmt_6_end@PAGE
  add x3, x3, _stmt_6_end@PAGEOFF
  str x3, [x2, x1, lsl #3]
  add w1, w1, #1
  str w1, [x0]
  b _rt_syscall_666
_stmt_6_end:

_stmt_7:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #6]
  tbnz w1, #0, _stmt_7_end
  adrp x1, _spot_3@PAGE
  add x1, x1, _spot_3@PAGEOFF
  ldr w0, [x1]
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_10_ign@PAGE
  add x1, x1, _spot_10_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_7_end
  adrp x1, _spot_10@PAGE
  add x1, x1, _spot_10@PAGEOFF
  str w0, [x1]
_stmt_7_end:

_stmt_8:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #7]
  tbnz w1, #0, _stmt_8_end
  mov w0, #2
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_1_ign@PAGE
  add x1, x1, _spot_1_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_8_end
  adrp x1, _spot_1@PAGE
  add x1, x1, _spot_1@PAGEOFF
  str w0, [x1]
_stmt_8_end:

_stmt_9:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #8]
  tbnz w1, #0, _stmt_9_end
  adrp x1, _spot_10@PAGE
  add x1, x1, _spot_10@PAGEOFF
  ldr w0, [x1]
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_2_ign@PAGE
  add x1, x1, _spot_2_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_9_end
  adrp x1, _spot_2@PAGE
  add x1, x1, _spot_2@PAGEOFF
  str w0, [x1]
_stmt_9_end:

_stmt_10:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #9]
  tbnz w1, #0, _stmt_10_end
  mov w0, #60000
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_3_ign@PAGE
  add x1, x1, _spot_3_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_10_end
  adrp x1, _spot_3@PAGE
  add x1, x1, _spot_3@PAGEOFF
  str w0, [x1]
_stmt_10_end:

_stmt_11:  // NEXT
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #10]
  tbnz w1, #0, _stmt_11_end
  adrp x0, _next_sp@PAGE
  add x0, x0, _next_sp@PAGEOFF
  ldr w1, [x0]
  cmp w1, #79
  b.ge _rt_error_E123
  adrp x2, _next_stack@PAGE
  add x2, x2, _next_stack@PAGEOFF
  adrp x3, _stmt_11_end@PAGE
  add x3, x3, _stmt_11_end@PAGEOFF
  str x3, [x2, x1, lsl #3]
  add w1, w1, #1
  str w1, [x0]
  b _rt_syscall_666
_stmt_11_end:

_stmt_12:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #11]
  tbnz w1, #0, _stmt_12_end
  adrp x1, _spot_4@PAGE
  add x1, x1, _spot_4@PAGEOFF
  ldr w0, [x1]
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_11_ign@PAGE
  add x1, x1, _spot_11_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_12_end
  adrp x1, _spot_11@PAGE
  add x1, x1, _spot_11@PAGEOFF
  str w0, [x1]
_stmt_12_end:

_stmt_13:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #12]
  tbnz w1, #0, _stmt_13_end
  mov w0, #3
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_1_ign@PAGE
  add x1, x1, _spot_1_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_13_end
  adrp x1, _spot_1@PAGE
  add x1, x1, _spot_1@PAGEOFF
  str w0, [x1]
_stmt_13_end:

_stmt_14:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #13]
  tbnz w1, #0, _stmt_14_end
  mov w0, #1
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_2_ign@PAGE
  add x1, x1, _spot_2_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_14_end
  adrp x1, _spot_2@PAGE
  add x1, x1, _spot_2@PAGEOFF
  str w0, [x1]
_stmt_14_end:

_stmt_15:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #14]
  tbnz w1, #0, _stmt_15_end
  adrp x1, _spot_11@PAGE
  add x1, x1, _spot_11@PAGEOFF
  ldr w0, [x1]
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_3_ign@PAGE
  add x1, x1, _spot_3_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_15_end
  adrp x1, _spot_3@PAGE
  add x1, x1, _spot_3@PAGEOFF
  str w0, [x1]
_stmt_15_end:

_stmt_16:  // NEXT
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #15]
  tbnz w1, #0, _stmt_16_end
  adrp x0, _next_sp@PAGE
  add x0, x0, _next_sp@PAGEOFF
  ldr w1, [x0]
  cmp w1, #79
  b.ge _rt_error_E123
  adrp x2, _next_stack@PAGE
  add x2, x2, _next_stack@PAGEOFF
  adrp x3, _stmt_16_end@PAGE
  add x3, x3, _stmt_16_end@PAGEOFF
  str x3, [x2, x1, lsl #3]
  add w1, w1, #1
  str w1, [x0]
  b _rt_syscall_666
_stmt_16_end:

_stmt_17:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #16]
  tbnz w1, #0, _stmt_17_end
  mov w0, #4
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_1_ign@PAGE
  add x1, x1, _spot_1_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_17_end
  adrp x1, _spot_1@PAGE
  add x1, x1, _spot_1@PAGEOFF
  str w0, [x1]
_stmt_17_end:

_stmt_18:  // ASSIGN
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #17]
  tbnz w1, #0, _stmt_18_end
  adrp x1, _spot_10@PAGE
  add x1, x1, _spot_10@PAGEOFF
  ldr w0, [x1]
  mov w1, #65535
  cmp w0, w1
  b.hi _rt_error_E275
  adrp x1, _spot_2_ign@PAGE
  add x1, x1, _spot_2_ign@PAGEOFF
  ldrb w2, [x1]
  cbnz w2, _stmt_18_end
  adrp x1, _spot_2@PAGE
  add x1, x1, _spot_2@PAGEOFF
  str w0, [x1]
_stmt_18_end:

_stmt_19:  // NEXT
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #18]
  tbnz w1, #0, _stmt_19_end
  adrp x0, _next_sp@PAGE
  add x0, x0, _next_sp@PAGEOFF
  ldr w1, [x0]
  cmp w1, #79
  b.ge _rt_error_E123
  adrp x2, _next_stack@PAGE
  add x2, x2, _next_stack@PAGEOFF
  adrp x3, _stmt_19_end@PAGE
  add x3, x3, _stmt_19_end@PAGEOFF
  str x3, [x2, x1, lsl #3]
  add w1, w1, #1
  str w1, [x0]
  b _rt_syscall_666
_stmt_19_end:

_stmt_20:  // GIVE_UP
  adrp x0, _stmt_flags@PAGE
  add x0, x0, _stmt_flags@PAGEOFF
  ldrb w1, [x0, #19]
  tbnz w1, #0, _stmt_20_end
  mov x0, #0
  mov x16, #1
  svc #0x80
_stmt_20_end:
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
  .byte 0
  .byte 0
  .byte 0
  .byte 0
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
_spot_11: .space 4
_spot_11_ign: .space 1
.align 3
_spot_11_stash_ptr: .space 8
_spot_11_stash_sp: .space 4
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
_spot_10: .space 4
_spot_10_ign: .space 1
.align 3
_spot_10_stash_ptr: .space 8
_spot_10_stash_sp: .space 4
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

