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
  mov eax, 6
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
  mov eax, 1
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_2_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_2_end
  lea rcx, [rip + _spot_2]
  mov [rcx], eax
_stmt_2_end:

_stmt_3:  # NEXT
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 2]
  test ecx, ecx
  jnz _stmt_3_end
  lea rax, [rip + _next_sp]
  mov ecx, [rax]
  cmp ecx, 79
  jge _rt_error_E123
  lea rdx, [rip + _next_stack]
  lea r8, [rip + _stmt_3_end]
  mov [rdx + rcx*8], r8
  inc ecx
  mov [rax], ecx
  jmp _rt_syscall_666
_stmt_3_end:

_stmt_4:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 3]
  test ecx, ecx
  jnz _stmt_4_end
  mov eax, 1
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_4_end
  lea rcx, [rip + _spot_1]
  mov [rcx], eax
_stmt_4_end:

_stmt_5:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 4]
  test ecx, ecx
  jnz _stmt_5_end
  mov eax, 0
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_2_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_5_end
  lea rcx, [rip + _spot_2]
  mov [rcx], eax
_stmt_5_end:

_stmt_6:  # NEXT
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 5]
  test ecx, ecx
  jnz _stmt_6_end
  lea rax, [rip + _next_sp]
  mov ecx, [rax]
  cmp ecx, 79
  jge _rt_error_E123
  lea rdx, [rip + _next_stack]
  lea r8, [rip + _stmt_6_end]
  mov [rdx + rcx*8], r8
  inc ecx
  mov [rax], ecx
  jmp _rt_syscall_666
_stmt_6_end:

_stmt_7:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 6]
  test ecx, ecx
  jnz _stmt_7_end
  lea rcx, [rip + _spot_3]
  mov eax, [rcx]
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_10_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_7_end
  lea rcx, [rip + _spot_10]
  mov [rcx], eax
_stmt_7_end:

_stmt_8:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 7]
  test ecx, ecx
  jnz _stmt_8_end
  mov eax, 2
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_8_end
  lea rcx, [rip + _spot_1]
  mov [rcx], eax
_stmt_8_end:

_stmt_9:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 8]
  test ecx, ecx
  jnz _stmt_9_end
  lea rcx, [rip + _spot_10]
  mov eax, [rcx]
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_2_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_9_end
  lea rcx, [rip + _spot_2]
  mov [rcx], eax
_stmt_9_end:

_stmt_10:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 9]
  test ecx, ecx
  jnz _stmt_10_end
  mov eax, 60000
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_3_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_10_end
  lea rcx, [rip + _spot_3]
  mov [rcx], eax
_stmt_10_end:

_stmt_11:  # NEXT
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 10]
  test ecx, ecx
  jnz _stmt_11_end
  lea rax, [rip + _next_sp]
  mov ecx, [rax]
  cmp ecx, 79
  jge _rt_error_E123
  lea rdx, [rip + _next_stack]
  lea r8, [rip + _stmt_11_end]
  mov [rdx + rcx*8], r8
  inc ecx
  mov [rax], ecx
  jmp _rt_syscall_666
_stmt_11_end:

_stmt_12:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 11]
  test ecx, ecx
  jnz _stmt_12_end
  lea rcx, [rip + _spot_4]
  mov eax, [rcx]
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_11_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_12_end
  lea rcx, [rip + _spot_11]
  mov [rcx], eax
_stmt_12_end:

_stmt_13:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 12]
  test ecx, ecx
  jnz _stmt_13_end
  mov eax, 3
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_13_end
  lea rcx, [rip + _spot_1]
  mov [rcx], eax
_stmt_13_end:

_stmt_14:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 13]
  test ecx, ecx
  jnz _stmt_14_end
  mov eax, 1
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_2_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_14_end
  lea rcx, [rip + _spot_2]
  mov [rcx], eax
_stmt_14_end:

_stmt_15:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 14]
  test ecx, ecx
  jnz _stmt_15_end
  lea rcx, [rip + _spot_11]
  mov eax, [rcx]
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_3_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_15_end
  lea rcx, [rip + _spot_3]
  mov [rcx], eax
_stmt_15_end:

_stmt_16:  # NEXT
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 15]
  test ecx, ecx
  jnz _stmt_16_end
  lea rax, [rip + _next_sp]
  mov ecx, [rax]
  cmp ecx, 79
  jge _rt_error_E123
  lea rdx, [rip + _next_stack]
  lea r8, [rip + _stmt_16_end]
  mov [rdx + rcx*8], r8
  inc ecx
  mov [rax], ecx
  jmp _rt_syscall_666
_stmt_16_end:

_stmt_17:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 16]
  test ecx, ecx
  jnz _stmt_17_end
  mov eax, 4
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_17_end
  lea rcx, [rip + _spot_1]
  mov [rcx], eax
_stmt_17_end:

_stmt_18:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 17]
  test ecx, ecx
  jnz _stmt_18_end
  lea rcx, [rip + _spot_10]
  mov eax, [rcx]
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_2_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_18_end
  lea rcx, [rip + _spot_2]
  mov [rcx], eax
_stmt_18_end:

_stmt_19:  # NEXT
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 18]
  test ecx, ecx
  jnz _stmt_19_end
  lea rax, [rip + _next_sp]
  mov ecx, [rax]
  cmp ecx, 79
  jge _rt_error_E123
  lea rdx, [rip + _next_stack]
  lea r8, [rip + _stmt_19_end]
  mov [rdx + rcx*8], r8
  inc ecx
  mov [rax], ecx
  jmp _rt_syscall_666
_stmt_19_end:

_stmt_20:  # GIVE_UP
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 19]
  test ecx, ecx
  jnz _stmt_20_end
  xor edi, edi
  mov eax, 60
  syscall
_stmt_20_end:
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

.section .bss

.align 4
_spot_11: .space 4
_spot_11_ign: .space 1
.align 8
_spot_11_stash_ptr: .space 8
_spot_11_stash_sp: .space 4
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
_spot_10: .space 4
_spot_10_ign: .space 1
.align 8
_spot_10_stash_ptr: .space 8
_spot_10_stash_sp: .space 4
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

