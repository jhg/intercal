// runtime_linux_arm64.s - INTERCAL runtime for Linux ARM64
// Part of the primordial spark (chispa primigenea)

.text

// Global symbol declarations for GNU linker
.global _rt_mingle
.global _rt_select
.global _rt_unary_and_16
.global _rt_unary_or_16
.global _rt_unary_xor_16
.global _rt_unary_and_32
.global _rt_unary_or_32
.global _rt_unary_xor_32
.global _rt_write_roman
.global _rt_read_out_array
.global _rt_write_in_array
.global _rt_write_in_scalar
.global _rt_mmap
.global _rt_resume_1
.global _rt_error_E000
.global _rt_error_E017
.global _rt_error_E123
.global _rt_error_E129
.global _rt_error_E139
.global _rt_error_E200
.global _rt_error_E240
.global _rt_error_E241
.global _rt_error_E275
.global _rt_error_E436
.global _rt_error_E533
.global _rt_error_E562
.global _rt_error_E579
.global _rt_error_E621
.global _rt_error_E632
.global _rt_error_E633
.global _rt_syscall_666
.global _rt_sys666_open
.global _rt_sys666_read
.global _rt_sys666_write
.global _rt_sys666_close
.global _rt_sys666_argc
.global _rt_sys666_argv
.global _rt_sys666_exit
.global _rt_sys666_getrand
.global _rtable
.global _rstrings
.global _nl: .byte 10
.global _errmsg_000: .asciz "ICL000I STATEMENT NOT RECOGNIZED DURING EXECUTIONn"
.global _errmsg_017: .asciz "ICL017I EXPRESSION CONTAINS UNRESOLVABLE SYNTAXn"
.global _errmsg_123: .asciz "ICL123I PROGRAM HAS DISAPPEARED INTO THE BLACK LAGOONn"
.global _errmsg_129: .asciz "ICL129I NEXT TARGET DOES NOT EXISTn"
.global _errmsg_139: .asciz "ICL139I ABSTAIN TARGET DOES NOT EXISTn"
.global _errmsg_200: .asciz "ICL200I VARIABLE REFERENCE NOT RECOGNIZEDn"
.global _errmsg_240: .asciz "ICL240I ARRAY DIMENSION MUST NOT BE ZEROn"
.global _errmsg_241: .asciz "ICL241I ARRAY SUBSCRIPT OUT OF BOUNDSn"
.global _errmsg_275: .asciz "ICL275I VALUE EXCEEDS 16 BIT CAPACITYn"
.global _errmsg_436: .asciz "ICL436I NOTHING TO RETRIEVE FROM STASHn"
.global _errmsg_533: .asciz "ICL533I RESULT EXCEEDS 32 BIT CAPACITYn"
.global _errmsg_562: .asciz "ICL562I INPUT DATA EXHAUSTED PREMATURELYn"
.global _errmsg_579: .asciz "ICL579I INPUT FORMAT NOT RECOGNIZEDn"
.global _errmsg_621: .asciz "ICL621I RESUME WITH VALUE ZERO IS FORBIDDENn"
.global _errmsg_632: .asciz "ICL632I PROGRAM ENDED VIA RESUME INSTEAD OF GIVE UPn"
.global _errmsg_633: .asciz "ICL633I EXECUTION REACHED END WITHOUT GIVE UPn"
.global _digit_names
.global _digit_values
.global _next_stack: .space 632
.global _next_sp: .space 4
.global _ttm_out_pos: .space 4
.global _ttm_in_pos: .space 4
.global _rt_argc: .space 4
.global _rt_argv: .space 8

.align 2

_rt_mingle:
  mov x2, #0
  mov w3, #0
.Lmingle_loop:
  cmp w3, #16
  b.ge .Lmingle_done
  lsr w4, w1, w3
  and w4, w4, #1
  lsl w5, w3, #1
  lsl w4, w4, w5
  orr x2, x2, x4
  lsr w4, w0, w3
  and w4, w4, #1
  add w5, w5, #1
  lsl w4, w4, w5
  orr x2, x2, x4
  add w3, w3, #1
  b .Lmingle_loop
.Lmingle_done:
  mov x0, x2
  ret

_rt_select:
  mov x3, #0
  mov w4, #0
  mov w5, #0
.Lselect_loop:
  cmp w5, w2
  b.ge .Lselect_done
  lsr x6, x1, x5
  tbz x6, #0, .Lselect_next
  lsr x6, x0, x5
  and x6, x6, #1
  lsl x6, x6, x4
  orr x3, x3, x6
  add w4, w4, #1
.Lselect_next:
  add w5, w5, #1
  b .Lselect_loop
.Lselect_done:
  mov x0, x3
  ret

_rt_unary_and_16:
  lsr w1, w0, #1
  lsl w2, w0, #15
  orr w1, w1, w2
  and w1, w1, #0xFFFF
  and w0, w0, w1
  and w0, w0, #0xFFFF
  ret

_rt_unary_or_16:
  lsr w1, w0, #1
  lsl w2, w0, #15
  orr w1, w1, w2
  and w1, w1, #0xFFFF
  orr w0, w0, w1
  and w0, w0, #0xFFFF
  ret

_rt_unary_xor_16:
  lsr w1, w0, #1
  lsl w2, w0, #15
  orr w1, w1, w2
  and w1, w1, #0xFFFF
  eor w0, w0, w1
  and w0, w0, #0xFFFF
  ret

_rt_unary_and_32:
  ror w1, w0, #1
  and w0, w0, w1
  ret

_rt_unary_or_32:
  ror w1, w0, #1
  orr w0, w0, w1
  ret

_rt_unary_xor_32:
  ror w1, w0, #1
  eor w0, w0, w1
  ret

_rt_write_roman:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  mov w19, w0
  cbz w19, .Lroman_done
  adrp x20, :pg_hi21:_rtable
  add x20, x20, :lo12:_rtable
.Lroman_loop:
  ldr w0, [x20]
  cbz w0, .Lroman_done
  cmp w19, w0
  b.lo .Lroman_next
  sub w19, w19, w0
  ldr w1, [x20, #4]
  adrp x2, :pg_hi21:_rstrings
  add x2, x2, :lo12:_rstrings
  add x1, x2, w1, uxtw
  mov x3, x1
  mov w4, #0
.Lroman_slen:
  ldrb w5, [x3, x4]
  cbz w5, .Lroman_gotlen
  add w4, w4, #1
  b .Lroman_slen
.Lroman_gotlen:
  mov x0, #1
  uxtw x2, w4
  mov x8, #64
  svc #0
  b .Lroman_loop
.Lroman_next:
  add x20, x20, #8
  b .Lroman_loop
.Lroman_done:
  adrp x1, :pg_hi21:_nl
  add x1, x1, :lo12:_nl
  mov x0, #1
  mov x2, #1
  mov x8, #64
  svc #0
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  ret

_rt_read_out_array:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  stp x23, x24, [sp, #-16]!
  mov x19, x0
  mov w20, w1
  mov w21, w2
  adrp x22, :pg_hi21:_ttm_out_pos
  add x22, x22, :lo12:_ttm_out_pos
  ldr w23, [x22]
  mov w24, #0
.Lttm_loop:
  cmp w24, w20
  b.ge .Lttm_done
  cmp w21, #2
  b.eq .Lttm_load16
  ldr w25, [x19, x24, lsl #2]
  b .Lttm_loaded
.Lttm_load16:
  ldrh w25, [x19, x24, lsl #1]
.Lttm_loaded:
  sub w23, w23, w25
  and w23, w23, #0xFF
  mov w0, w23
  rbit w0, w0
  lsr w0, w0, #24
  sub sp, sp, #16
  strb w0, [sp]
  mov x1, sp
  mov x0, #1
  mov x2, #1
  mov x8, #64
  svc #0
  add sp, sp, #16
  add w24, w24, #1
  b .Lttm_loop
.Lttm_done:
  str w23, [x22]
  ldp x23, x24, [sp], #16
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  ret

_rt_write_in_array:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  stp x23, x24, [sp, #-16]!
  stp x25, x26, [sp, #-16]!
  mov x19, x0
  mov w20, w1
  mov w21, w2
  adrp x22, :pg_hi21:_ttm_in_pos
  add x22, x22, :lo12:_ttm_in_pos
  ldr w23, [x22]
  mov w24, #0
.Lttm_in_loop:
  cmp w24, w20
  b.ge .Lttm_in_done
  sub sp, sp, #16
  mov x0, #0
  mov x1, sp
  mov x2, #1
  mov x8, #63
  svc #0
  cbz x0, .Lttm_in_eof
  ldrb w25, [sp]
  add sp, sp, #16
  rbit w25, w25
  lsr w25, w25, #24
  sub w26, w25, w23
  and w26, w26, #0xFF
  cmp w21, #2
  b.eq .Lttm_in_store16
  str w26, [x19, x24, lsl #2]
  b .Lttm_in_stored
.Lttm_in_store16:
  strh w26, [x19, x24, lsl #1]
.Lttm_in_stored:
  mov w23, w25
  add w24, w24, #1
  b .Lttm_in_loop
.Lttm_in_eof:
  add sp, sp, #16
  b _rt_error_E562
.Lttm_in_done:
  str w23, [x22]
  ldp x25, x26, [sp], #16
  ldp x23, x24, [sp], #16
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  ret

_rt_write_in_scalar:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  sub sp, sp, #272
  mov x19, sp
  mov w20, #0
.Lwi_read:
  mov x0, #0
  add x1, x19, w20, uxtw
  mov x2, #1
  mov x8, #63
  svc #0
  cbz x0, .Lwi_parse
  ldrb w1, [x19, w20, uxtw]
  cmp w1, #10
  b.eq .Lwi_parse
  add w20, w20, #1
  cmp w20, #255
  b.lt .Lwi_read
.Lwi_parse:
  cbz w20, .Lwi_eof
  strb wzr, [x19, w20, uxtw]
  // Uppercase
  mov w1, #0
.Lwi_upper:
  ldrb w2, [x19, w1, uxtw]
  cbz w2, .Lwi_tokenize
  cmp w2, #97
  b.lt .Lwi_upper_next
  cmp w2, #122
  b.gt .Lwi_upper_next
  sub w2, w2, #32
  strb w2, [x19, w1, uxtw]
.Lwi_upper_next:
  add w1, w1, #1
  b .Lwi_upper
.Lwi_tokenize:
  mov w21, #0     // result
  mov w22, #0     // pos in buffer
.Lwi_tok_loop:
  // Skip spaces
  ldrb w0, [x19, w22, uxtw]
  cbz w0, .Lwi_tok_done
  cmp w0, #32
  b.ne .Lwi_match
  add w22, w22, #1
  b .Lwi_tok_loop
.Lwi_match:
  // Try each digit name
  adrp x10, :pg_hi21:_digit_names
  add x10, x10, :lo12:_digit_names
  adrp x11, :pg_hi21:_digit_values
  add x11, x11, :lo12:_digit_values
  mov w12, #0    // digit name index
  mov w13, #12   // total names
.Lwi_try_name:
  cmp w12, w13
  b.ge .Lwi_bad_token
  // Compare token at x19+w22 with name at x10
  mov w14, #0   // char index in name
  add x15, x19, w22, uxtw
.Lwi_cmp:
  ldrb w16, [x10, w14, uxtw]
  ldrb w17, [x15, w14, uxtw]
  cbz w16, .Lwi_cmp_end   // end of name
  cmp w16, w17
  b.ne .Lwi_next_name
  add w14, w14, #1
  b .Lwi_cmp
.Lwi_cmp_end:
  // Name matched fully. Check token boundary (next char must be space, null, or end)
  ldrb w17, [x15, w14, uxtw]
  cbz w17, .Lwi_matched
  cmp w17, #32
  b.eq .Lwi_matched
  // Not a boundary, try next name
.Lwi_next_name:
  // Advance x10 past current name (find null)
  ldrb w16, [x10]
  add x10, x10, #1
  cbnz w16, .Lwi_next_name
  add w12, w12, #1
  b .Lwi_try_name
.Lwi_matched:
  // result = result * 10 + digit_value
  mov w0, #10
  mul w21, w21, w0
  ldrb w0, [x11, w12, uxtw]
  add w21, w21, w0
  add w22, w22, w14   // advance past matched token
  b .Lwi_tok_loop
.Lwi_tok_done:
  mov w0, w21
  add sp, sp, #272
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  ret
.Lwi_bad_token:
  add sp, sp, #272
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  b _rt_error_E579
.Lwi_eof:
  add sp, sp, #272
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  b _rt_error_E562

_rt_mmap:
  mov x5, #0
  mov x4, #-1
  mov x3, #0x22
  mov x2, #3
  mov x1, x0
  mov x0, #0
  mov x8, #222
  svc #0
  cmn x0, #1
  b.eq _rt_error_E000
  ret

_rt_resume_1:
  adrp x0, :pg_hi21:_next_sp
  add x0, x0, :lo12:_next_sp
  ldr w1, [x0]
  cbz w1, _rt_error_E632
  sub w1, w1, #1
  str w1, [x0]
  adrp x2, :pg_hi21:_next_stack
  add x2, x2, :lo12:_next_stack
  ldr x3, [x2, x1, lsl #3]
  br x3

_rt_error_E000:
  adrp x1, :pg_hi21:_errmsg_000
  add x1, x1, :lo12:_errmsg_000
  mov x2, #50
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E017:
  adrp x1, :pg_hi21:_errmsg_017
  add x1, x1, :lo12:_errmsg_017
  mov x2, #48
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E123:
  adrp x1, :pg_hi21:_errmsg_123
  add x1, x1, :lo12:_errmsg_123
  mov x2, #54
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E129:
  adrp x1, :pg_hi21:_errmsg_129
  add x1, x1, :lo12:_errmsg_129
  mov x2, #35
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E139:
  adrp x1, :pg_hi21:_errmsg_139
  add x1, x1, :lo12:_errmsg_139
  mov x2, #38
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E200:
  adrp x1, :pg_hi21:_errmsg_200
  add x1, x1, :lo12:_errmsg_200
  mov x2, #42
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E240:
  adrp x1, :pg_hi21:_errmsg_240
  add x1, x1, :lo12:_errmsg_240
  mov x2, #41
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E241:
  adrp x1, :pg_hi21:_errmsg_241
  add x1, x1, :lo12:_errmsg_241
  mov x2, #38
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E275:
  adrp x1, :pg_hi21:_errmsg_275
  add x1, x1, :lo12:_errmsg_275
  mov x2, #38
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E436:
  adrp x1, :pg_hi21:_errmsg_436
  add x1, x1, :lo12:_errmsg_436
  mov x2, #39
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E533:
  adrp x1, :pg_hi21:_errmsg_533
  add x1, x1, :lo12:_errmsg_533
  mov x2, #39
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E562:
  adrp x1, :pg_hi21:_errmsg_562
  add x1, x1, :lo12:_errmsg_562
  mov x2, #41
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E579:
  adrp x1, :pg_hi21:_errmsg_579
  add x1, x1, :lo12:_errmsg_579
  mov x2, #36
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E621:
  adrp x1, :pg_hi21:_errmsg_621
  add x1, x1, :lo12:_errmsg_621
  mov x2, #44
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E632:
  adrp x1, :pg_hi21:_errmsg_632
  add x1, x1, :lo12:_errmsg_632
  mov x2, #52
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0

_rt_error_E633:
  adrp x1, :pg_hi21:_errmsg_633
  add x1, x1, :lo12:_errmsg_633
  mov x2, #46
  mov x0, #2
  mov x8, #64
  svc #0
  mov x0, #1
  mov x8, #93
  svc #0



// ========== Label 666 Syscall Handler ==========

_rt_syscall_666:
  // Read .1 (syscall number)
  adrp x0, :pg_hi21:_spot_1
  add x0, x0, :lo12:_spot_1
  ldr w0, [x0]
  cmp w0, #1
  b.eq _rt_sys666_open
  cmp w0, #2
  b.eq _rt_sys666_read
  cmp w0, #3
  b.eq _rt_sys666_write
  cmp w0, #4
  b.eq _rt_sys666_close
  cmp w0, #5
  b.eq _rt_sys666_argc
  cmp w0, #6
  b.eq _rt_sys666_argv
  cmp w0, #8
  b.eq _rt_sys666_exit
  cmp w0, #9
  b.eq _rt_sys666_getrand
  b _rt_error_E000

// Syscall 1: open file
// .2=mode (0=read,1=write), ,65535=filename (ASCII codes)
// Output: .3=fd (0=error)
_rt_sys666_open:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  // Read mode from .2
  adrp x0, :pg_hi21:_spot_2
  add x0, x0, :lo12:_spot_2
  ldr w19, [x0]
  // Read filename from ,65535: get ptr and dims
  adrp x0, :pg_hi21:_tail_65535_ptr
  add x0, x0, :lo12:_tail_65535_ptr
  ldr x1, [x0]
  cbz x1, .Lopen_err
  adrp x0, :pg_hi21:_tail_65535_dims
  add x0, x0, :lo12:_tail_65535_dims
  ldr w2, [x0]        // filename length
  // Convert array elements to C-string on stack
  // Allocate stack space (round up to 16)
  add w3, w2, #16
  and w3, w3, #-16
  sub sp, sp, x3
  mov w4, #0
.Lopen_copy:
  cmp w4, w2
  b.ge .Lopen_copied
  ldrh w5, [x1, x4, lsl #1]
  strb w5, [sp, x4]
  add w4, w4, #1
  b .Lopen_copy
.Lopen_copied:
  strb wzr, [sp, x4]  // null terminate
  // Save stack size for restore
  add w20, w2, #16
  and w20, w20, #-16
  // Compute open flags for Linux openat
  mov w2, #0           // O_RDONLY
  cmp w19, #1
  b.ne .Lopen_do
  mov w2, #0x241       // O_WRONLY|O_CREAT|O_TRUNC (Linux)
  mov w3, #0x1B6       // 0666 permissions
.Lopen_do:
  mov x0, #-100        // AT_FDCWD
  mov x1, sp           // pathname
  mov x8, #56          // openat
  svc #0
  // Restore stack
  add sp, sp, x20
  // Check error (negative return on Linux)
  cmp x0, #0
  b.lt .Lopen_err
  mov w20, w0          // save fd
  b .Lopen_store
.Lopen_err:
  mov w20, #0
.Lopen_store:
  adrp x0, :pg_hi21:_spot_3
  add x0, x0, :lo12:_spot_3
  str w20, [x0]
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  b _rt_resume_1

// Syscall 2: read
// .2=fd, .3=max bytes
// Output: .4=bytes read, ,65535=data (auto-dimensioned)
_rt_sys666_read:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  // Get fd from .2
  adrp x0, :pg_hi21:_spot_2
  add x0, x0, :lo12:_spot_2
  ldr w19, [x0]
  // Get max bytes from .3
  adrp x0, :pg_hi21:_spot_3
  add x0, x0, :lo12:_spot_3
  ldr w20, [x0]
  // Allocate buffer via mmap
  mov x0, x20
  add x0, x0, #4096    // extra space
  bl _rt_mmap
  mov x21, x0           // buffer ptr
  // Read from fd
  mov x0, x19            // fd
  mov x1, x21            // buffer
  uxtw x2, w20           // max bytes
  mov x8, #63            // read
  svc #0
  mov w22, w0            // bytes actually read
  // Auto-dimension ,65535
  adrp x0, :pg_hi21:_tail_65535_ptr
  add x0, x0, :lo12:_tail_65535_ptr
  // Allocate array for elements (2 bytes each)
  lsl x0, x22, #1
  add x0, x0, #16
  bl _rt_mmap
  mov x1, x0
  adrp x0, :pg_hi21:_tail_65535_ptr
  add x0, x0, :lo12:_tail_65535_ptr
  str x1, [x0]
  adrp x0, :pg_hi21:_tail_65535_ndim
  add x0, x0, :lo12:_tail_65535_ndim
  mov w2, #1
  str w2, [x0]
  adrp x0, :pg_hi21:_tail_65535_dims
  add x0, x0, :lo12:_tail_65535_dims
  str w22, [x0]
  // Copy bytes to array elements
  mov w3, #0
.Lread_copy:
  cmp w3, w22
  b.ge .Lread_done
  ldrb w4, [x21, x3]
  strh w4, [x1, x3, lsl #1]
  add w3, w3, #1
  b .Lread_copy
.Lread_done:
  // Store bytes read in .4
  adrp x0, :pg_hi21:_spot_4
  add x0, x0, :lo12:_spot_4
  str w22, [x0]
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  b _rt_resume_1

// Syscall 3: write
// .2=fd, .3=count, ,65535=data
// Output: .4=bytes written
_rt_sys666_write:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  // Get fd from .2
  adrp x0, :pg_hi21:_spot_2
  add x0, x0, :lo12:_spot_2
  ldr w19, [x0]
  // Get count from .3
  adrp x0, :pg_hi21:_spot_3
  add x0, x0, :lo12:_spot_3
  ldr w20, [x0]
  // Get array ptr and validate bounds
  adrp x0, :pg_hi21:_tail_65535_ptr
  add x0, x0, :lo12:_tail_65535_ptr
  ldr x1, [x0]
  cbz x1, .Lwrite_zero
  // Clamp count to array dimension
  adrp x0, :pg_hi21:_tail_65535_dims
  add x0, x0, :lo12:_tail_65535_dims
  ldr w2, [x0]
  cmp w20, w2
  csel w20, w2, w20, hi    // clamp to dim if count > dim
  // Convert array elements to bytes on stack
  add w2, w20, #16
  and w2, w2, #-16
  sub sp, sp, x2
  mov w3, #0
.Lwrite_copy:
  cmp w3, w20
  b.ge .Lwrite_do
  ldrh w4, [x1, x3, lsl #1]
  strb w4, [sp, x3]
  add w3, w3, #1
  b .Lwrite_copy
.Lwrite_do:
  mov x0, x19           // fd
  mov x1, sp            // buffer
  uxtw x2, w20          // count
  mov x8, #64           // write
  svc #0
  mov w19, w0            // bytes written
  add w2, w20, #16
  and w2, w2, #-16
  add sp, sp, x2
  b .Lwrite_store
.Lwrite_zero:
  mov w19, #0
.Lwrite_store:
  adrp x0, :pg_hi21:_spot_4
  add x0, x0, :lo12:_spot_4
  str w19, [x0]
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  b _rt_resume_1

// Syscall 4: close
// .2=fd
_rt_sys666_close:
  adrp x0, :pg_hi21:_spot_2
  add x0, x0, :lo12:_spot_2
  ldr w0, [x0]
  mov x8, #57           // close
  svc #0
  b _rt_resume_1

// Syscall 5: argc
// Output: .3=count
_rt_sys666_argc:
  adrp x0, :pg_hi21:_rt_argc
  add x0, x0, :lo12:_rt_argc
  ldr w0, [x0]
  adrp x1, :pg_hi21:_spot_3
  add x1, x1, :lo12:_spot_3
  str w0, [x1]
  b _rt_resume_1

// Syscall 6: argv
// .2=index, Output: .3=length, ,65535=chars (auto-dim)
_rt_sys666_argv:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  // Get index from .2
  adrp x0, :pg_hi21:_spot_2
  add x0, x0, :lo12:_spot_2
  ldr w19, [x0]
  // Get argv pointer
  adrp x0, :pg_hi21:_rt_argv
  add x0, x0, :lo12:_rt_argv
  ldr x0, [x0]
  // argv[index]
  ldr x20, [x0, x19, lsl #3]
  // strlen
  mov x21, x20
  mov w22, #0
.Largv_strlen:
  ldrb w0, [x21, x22]
  cbz w0, .Largv_got_len
  add w22, w22, #1
  b .Largv_strlen
.Largv_got_len:
  // Auto-dimension ,65535
  lsl x0, x22, #1
  add x0, x0, #16
  bl _rt_mmap
  mov x1, x0
  adrp x0, :pg_hi21:_tail_65535_ptr
  add x0, x0, :lo12:_tail_65535_ptr
  str x1, [x0]
  adrp x0, :pg_hi21:_tail_65535_ndim
  add x0, x0, :lo12:_tail_65535_ndim
  mov w2, #1
  str w2, [x0]
  adrp x0, :pg_hi21:_tail_65535_dims
  add x0, x0, :lo12:_tail_65535_dims
  str w22, [x0]
  // Copy chars
  mov w3, #0
.Largv_copy:
  cmp w3, w22
  b.ge .Largv_done
  ldrb w4, [x20, x3]
  strh w4, [x1, x3, lsl #1]
  add w3, w3, #1
  b .Largv_copy
.Largv_done:
  adrp x0, :pg_hi21:_spot_3
  add x0, x0, :lo12:_spot_3
  str w22, [x0]
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  b _rt_resume_1

// Syscall 8: exit
// .2=exit code
_rt_sys666_exit:
  adrp x0, :pg_hi21:_spot_2
  add x0, x0, :lo12:_spot_2
  ldr w0, [x0]
  mov x8, #93
  svc #0

// Syscall 9: getrand
// .2=0: uniform 16-bit; .2>0: range 0-.2
// Output: .3=random value
_rt_sys666_getrand:
  sub sp, sp, #16
  mov x0, sp
  mov x1, #2
  mov x8, #278         // getentropy
  svc #0
  ldrh w0, [sp]
  add sp, sp, #16
  adrp x1, :pg_hi21:_spot_2
  add x1, x1, :lo12:_spot_2
  ldr w1, [x1]
  cbz w1, .Lrand_store
  add w2, w1, #1
  udiv w3, w0, w2
  msub w0, w3, w2, w0
.Lrand_store:
  adrp x1, :pg_hi21:_spot_3
  add x1, x1, :lo12:_spot_3
  str w0, [x1]
  b _rt_resume_1


.data
.align 2

_rtable:
  .long 1000000, 0
  .long 900000,  3
  .long 500000,  7
  .long 400000,  10
  .long 100000,  14
  .long 90000,   17
  .long 50000,   21
  .long 40000,   24
  .long 10000,   28
  .long 9000,    31
  .long 5000,    35
  .long 4000,    38
  .long 1000,    42
  .long 900,     44
  .long 500,     47
  .long 400,     49
  .long 100,     52
  .long 90,      54
  .long 50,      57
  .long 40,      59
  .long 10,      62
  .long 9,       64
  .long 5,       67
  .long 4,       69
  .long 1,       72
  .long 0,       0

_rstrings:
  .asciz "_M"
  .asciz "_CM"
  .asciz "_D"
  .asciz "_CD"
  .asciz "_C"
  .asciz "_XC"
  .asciz "_L"
  .asciz "_XL"
  .asciz "_X"
  .asciz "_IX"
  .asciz "_V"
  .asciz "_IV"
  .asciz "M"
  .asciz "CM"
  .asciz "D"
  .asciz "CD"
  .asciz "C"
  .asciz "XC"
  .asciz "L"
  .asciz "XL"
  .asciz "X"
  .asciz "IX"
  .asciz "V"
  .asciz "IV"
  .asciz "I"

_nl: .byte 10

_errmsg_000: .asciz "ICL000I STATEMENT NOT RECOGNIZED DURING EXECUTION\n"
_errmsg_017: .asciz "ICL017I EXPRESSION CONTAINS UNRESOLVABLE SYNTAX\n"
_errmsg_123: .asciz "ICL123I PROGRAM HAS DISAPPEARED INTO THE BLACK LAGOON\n"
_errmsg_129: .asciz "ICL129I NEXT TARGET DOES NOT EXIST\n"
_errmsg_139: .asciz "ICL139I ABSTAIN TARGET DOES NOT EXIST\n"
_errmsg_200: .asciz "ICL200I VARIABLE REFERENCE NOT RECOGNIZED\n"
_errmsg_240: .asciz "ICL240I ARRAY DIMENSION MUST NOT BE ZERO\n"
_errmsg_241: .asciz "ICL241I ARRAY SUBSCRIPT OUT OF BOUNDS\n"
_errmsg_275: .asciz "ICL275I VALUE EXCEEDS 16 BIT CAPACITY\n"
_errmsg_436: .asciz "ICL436I NOTHING TO RETRIEVE FROM STASH\n"
_errmsg_533: .asciz "ICL533I RESULT EXCEEDS 32 BIT CAPACITY\n"
_errmsg_562: .asciz "ICL562I INPUT DATA EXHAUSTED PREMATURELY\n"
_errmsg_579: .asciz "ICL579I INPUT FORMAT NOT RECOGNIZED\n"
_errmsg_621: .asciz "ICL621I RESUME WITH VALUE ZERO IS FORBIDDEN\n"
_errmsg_632: .asciz "ICL632I PROGRAM ENDED VIA RESUME INSTEAD OF GIVE UP\n"
_errmsg_633: .asciz "ICL633I EXECUTION REACHED END WITHOUT GIVE UP\n"

_digit_names:
  .asciz "ZERO"
  .asciz "OH"
  .asciz "ONE"
  .asciz "TWO"
  .asciz "THREE"
  .asciz "FOUR"
  .asciz "FIVE"
  .asciz "SIX"
  .asciz "SEVEN"
  .asciz "EIGHT"
  .asciz "NINE"
  .asciz "NINER"

_digit_values:
  .byte 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9

.bss
.align 3
_next_stack: .space 632
_next_sp: .space 4

_ttm_out_pos: .space 4
_ttm_in_pos: .space 4

_rt_argc: .space 4
_rt_argv: .space 8
