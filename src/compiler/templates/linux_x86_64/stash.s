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

_stmt_2:  # STASH
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 1]
  test ecx, ecx
  jnz _stmt_2_end
  lea rax, [rip + _spot_1_stash_ptr]
  mov rcx, [rax]
  test rcx, rcx
  jnz .Lstash_ok_1
  push rax
  mov rdi, 4096
  call _rt_mmap
  pop rdx
  mov [rdx], rax
  mov rcx, rax
.Lstash_ok_1:
  lea rdx, [rip + _spot_1_stash_sp]
  mov r8d, [rdx]
  lea r9, [rip + _spot_1]
  mov r10d, [r9]
  mov [rcx + r8*4], r10d
  inc r8d
  mov [rdx], r8d
_stmt_2_end:

_stmt_3:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 2]
  test ecx, ecx
  jnz _stmt_3_end
  mov eax, 99
  cmp eax, 65535
  ja _rt_error_E275
  lea rcx, [rip + _spot_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_3_end
  lea rcx, [rip + _spot_1]
  mov [rcx], eax
_stmt_3_end:

_stmt_4:  # RETRIEVE
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 3]
  test ecx, ecx
  jnz _stmt_4_end
  lea rdx, [rip + _spot_1_stash_sp]
  mov r8d, [rdx]
  test r8d, r8d
  jz _rt_error_E436
  dec r8d
  mov [rdx], r8d
  lea rax, [rip + _spot_1_stash_ptr]
  mov rcx, [rax]
  mov r10d, [rcx + r8*4]
  lea r9, [rip + _spot_1]
  mov [r9], r10d
_stmt_4_end:

_stmt_5:  # READ_OUT
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 4]
  test ecx, ecx
  jnz _stmt_5_end
  lea rcx, [rip + _spot_1]
  mov eax, [rcx]
  mov edi, eax
  call _rt_write_roman
_stmt_5_end:

_stmt_6:  # GIVE_UP
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 5]
  test ecx, ecx
  jnz _stmt_6_end
  xor edi, edi
  mov eax, 60
  syscall
_stmt_6_end:
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

