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


_stmt_1:  // ARRAY_DIM
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #0]
  tbnz w1, #0, _stmt_1_end
  mov w0, #14
  str w0, [sp, #-16]!
  mov w10, #1
  ldr w11, [sp, #0]
  cbz w11, _rt_error_E240
  adrp x12, _tail_1_dims
  add x12, x12, :lo12:_tail_1_dims
  str w11, [x12, #0]
  mul w10, w10, w11
  add sp, sp, #16
  adrp x12, _tail_1_ndim
  add x12, x12, :lo12:_tail_1_ndim
  mov w11, #1
  str w11, [x12]
  lsl x0, x10, #1
  bl _rt_mmap
  adrp x12, _tail_1_ptr
  add x12, x12, :lo12:_tail_1_ptr
  str x0, [x12]
_stmt_1_end:

_stmt_2:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #1]
  tbnz w1, #0, _stmt_2_end
  mov w0, #238
  str w0, [sp, #-16]!
  mov w0, #1
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_2_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_2_aedone
_stmt_2_aeskip:
  add sp, sp, #16
_stmt_2_aedone:
_stmt_2_end:

_stmt_3:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #2]
  tbnz w1, #0, _stmt_3_end
  mov w0, #108
  str w0, [sp, #-16]!
  mov w0, #2
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_3_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_3_aedone
_stmt_3_aeskip:
  add sp, sp, #16
_stmt_3_aedone:
_stmt_3_end:

_stmt_4:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #3]
  tbnz w1, #0, _stmt_4_end
  mov w0, #112
  str w0, [sp, #-16]!
  mov w0, #3
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_4_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_4_aedone
_stmt_4_aeskip:
  add sp, sp, #16
_stmt_4_aedone:
_stmt_4_end:

_stmt_5:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #4]
  tbnz w1, #0, _stmt_5_end
  mov w0, #0
  str w0, [sp, #-16]!
  mov w0, #4
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_5_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_5_aedone
_stmt_5_aeskip:
  add sp, sp, #16
_stmt_5_aedone:
_stmt_5_end:

_stmt_6:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #5]
  tbnz w1, #0, _stmt_6_end
  mov w0, #64
  str w0, [sp, #-16]!
  mov w0, #5
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_6_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_6_aedone
_stmt_6_aeskip:
  add sp, sp, #16
_stmt_6_aedone:
_stmt_6_end:

_stmt_7:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #6]
  tbnz w1, #0, _stmt_7_end
  mov w0, #194
  str w0, [sp, #-16]!
  mov w0, #6
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_7_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_7_aedone
_stmt_7_aeskip:
  add sp, sp, #16
_stmt_7_aedone:
_stmt_7_end:

_stmt_8:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #7]
  tbnz w1, #0, _stmt_8_end
  mov w0, #48
  str w0, [sp, #-16]!
  mov w0, #7
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_8_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_8_aedone
_stmt_8_aeskip:
  add sp, sp, #16
_stmt_8_aedone:
_stmt_8_end:

_stmt_9:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #8]
  tbnz w1, #0, _stmt_9_end
  mov w0, #26
  str w0, [sp, #-16]!
  mov w0, #8
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_9_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_9_aedone
_stmt_9_aeskip:
  add sp, sp, #16
_stmt_9_aedone:
_stmt_9_end:

_stmt_10:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #9]
  tbnz w1, #0, _stmt_10_end
  mov w0, #244
  str w0, [sp, #-16]!
  mov w0, #9
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_10_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_10_aedone
_stmt_10_aeskip:
  add sp, sp, #16
_stmt_10_aedone:
_stmt_10_end:

_stmt_11:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #10]
  tbnz w1, #0, _stmt_11_end
  mov w0, #168
  str w0, [sp, #-16]!
  mov w0, #10
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_11_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_11_aedone
_stmt_11_aeskip:
  add sp, sp, #16
_stmt_11_aedone:
_stmt_11_end:

_stmt_12:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #11]
  tbnz w1, #0, _stmt_12_end
  mov w0, #24
  str w0, [sp, #-16]!
  mov w0, #11
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_12_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_12_aedone
_stmt_12_aeskip:
  add sp, sp, #16
_stmt_12_aedone:
_stmt_12_end:

_stmt_13:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #12]
  tbnz w1, #0, _stmt_13_end
  mov w0, #16
  str w0, [sp, #-16]!
  mov w0, #12
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_13_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_13_aedone
_stmt_13_aeskip:
  add sp, sp, #16
_stmt_13_aedone:
_stmt_13_end:

_stmt_14:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #13]
  tbnz w1, #0, _stmt_14_end
  mov w0, #162
  str w0, [sp, #-16]!
  mov w0, #13
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_14_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_14_aedone
_stmt_14_aeskip:
  add sp, sp, #16
_stmt_14_aedone:
_stmt_14_end:

_stmt_15:  // ASSIGN
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #14]
  tbnz w1, #0, _stmt_15_end
  mov w0, #52
  str w0, [sp, #-16]!
  mov w0, #14
  str w0, [sp, #-16]!
  ldr w0, [sp], #16
  sub w0, w0, #1
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w2, [x1]
  cmp w0, w2
  b.hs _rt_error_E241
  adrp x1, _tail_1_ign
  add x1, x1, :lo12:_tail_1_ign
  ldrb w2, [x1]
  cbnz w2, _stmt_15_aeskip
  adrp x1, _tail_1_ptr
  add x1, x1, :lo12:_tail_1_ptr
  ldr x1, [x1]
  ldr w2, [sp], #16
  strh w2, [x1, x0, lsl #1]
  b _stmt_15_aedone
_stmt_15_aeskip:
  add sp, sp, #16
_stmt_15_aedone:
_stmt_15_end:

_stmt_16:  // READ_OUT
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #15]
  tbnz w1, #0, _stmt_16_end
  adrp x0, _tail_1_ptr
  add x0, x0, :lo12:_tail_1_ptr
  ldr x0, [x0]
  adrp x1, _tail_1_dims
  add x1, x1, :lo12:_tail_1_dims
  ldr w1, [x1]
  mov w2, #2
  bl _rt_read_out_array
_stmt_16_end:

_stmt_17:  // GIVE_UP
  adrp x0, _stmt_flags
  add x0, x0, :lo12:_stmt_flags
  ldrb w1, [x0, #16]
  tbnz w1, #0, _stmt_17_end
  mov x0, #0
  mov x8, #93
  svc #0
_stmt_17_end:
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
.align 3
_tail_1_ptr: .space 8
_tail_1_ndim: .space 4
_tail_1_dims: .space 32
_tail_1_ign: .space 1
.align 3
_tail_1_stash_ptr: .space 8
_tail_1_stash_sp: .space 4
