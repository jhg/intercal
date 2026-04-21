.intel_syntax noprefix
.section .text
.global main
.align 16

main:
  push rbp
  mov rbp, rsp
  # Save argc/argv for Label 666
  lea rcx, [rip + _rt_argc]
  mov [rcx], edi
  lea rcx, [rip + _rt_argv]
  mov [rcx], rsi


_stmt_1:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 0]
  test ecx, ecx
  jnz _stmt_1_end
  mov eax, 7
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_1_end
  lea rcx, [rip + _spot_1]
  mov [rcx], eax
_stmt_1_end:

_stmt_2:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 1]
  test ecx, ecx
  jnz _stmt_2_end
  mov eax, 99
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_2_end
  lea rcx, [rip + _spot_1]
  mov [rcx], eax
_stmt_2_end:
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 4]
  test ecx, ecx
  jnz _stmt_2_nocf
  jmp _stmt_5
_stmt_2_nocf:

_stmt_3:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 2]
  test ecx, ecx
  jnz _stmt_3_end
  mov eax, 55
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_3_end
  lea rcx, [rip + _spot_1]
  mov [rcx], eax
_stmt_3_end:

_stmt_4:  # GIVE_UP
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 3]
  test ecx, ecx
  jnz _stmt_4_end
  xor edi, edi
  mov eax, 60
  syscall
_stmt_4_end:

_stmt_5:  # COME_FROM
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 4]
  test ecx, ecx
  jnz _stmt_5_end
_stmt_5_end:

_stmt_6:  # READ_OUT
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 5]
  test ecx, ecx
  jnz _stmt_6_end
  lea rcx, [rip + _spot_1]
  mov eax, [rcx]
  mov edi, eax
  call _rt_write_roman
_stmt_6_end:

_stmt_7:  # GIVE_UP
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 6]
  test ecx, ecx
  jnz _stmt_7_end
  xor edi, edi
  mov eax, 60
  syscall
_stmt_7_end:
  jmp _rt_error_E633


# ========== Program Data ==========
.section .data
_stmt_flags:
  .byte 0
  .byte 0
  .byte 0
  .byte 0
  .byte 0
  .byte 0
  .byte 0

.section .bss

.align 4
_spot_3: .space 4
_spot_3_ign: .space 1
.align 8
_spot_3_stash_ptr: .space 8
_spot_3_stash_sp: .space 4
.align 4
_spot_4: .space 4
_spot_4_ign: .space 1
.align 8
_spot_4_stash_ptr: .space 8
_spot_4_stash_sp: .space 4
.align 4
_spot_5: .space 4
_spot_5_ign: .space 1
.align 8
_spot_5_stash_ptr: .space 8
_spot_5_stash_sp: .space 4
.align 4
_spot_1: .space 4
_spot_1_ign: .space 1
.align 8
_spot_1_stash_ptr: .space 8
_spot_1_stash_sp: .space 4
.align 4
_spot_2: .space 4
_spot_2_ign: .space 1
.align 8
_spot_2_stash_ptr: .space 8
_spot_2_stash_sp: .space 4
.align 4
_twospot_3: .space 4
_twospot_3_ign: .space 1
.align 8
_twospot_3_stash_ptr: .space 8
_twospot_3_stash_sp: .space 4
.align 4
_twospot_4: .space 4
_twospot_4_ign: .space 1
.align 8
_twospot_4_stash_ptr: .space 8
_twospot_4_stash_sp: .space 4
.align 4
_twospot_1: .space 4
_twospot_1_ign: .space 1
.align 8
_twospot_1_stash_ptr: .space 8
_twospot_1_stash_sp: .space 4
.align 4
_twospot_2: .space 4
_twospot_2_ign: .space 1
.align 8
_twospot_2_stash_ptr: .space 8
_twospot_2_stash_sp: .space 4
.align 8
_tail_65535_ptr: .space 8
_tail_65535_ndim: .space 4
_tail_65535_dims: .space 32
_tail_65535_ign: .space 1
.align 8
_tail_65535_stash_ptr: .space 8
_tail_65535_stash_sp: .space 4

