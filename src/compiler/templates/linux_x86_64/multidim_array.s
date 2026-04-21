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


_stmt_1:  # ARRAY_DIM
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 0]
  test ecx, ecx
  jnz _stmt_1_end
  mov eax, 3
  push rax
  mov eax, 4
  push rax
  mov r10d, 1
  mov r11d, [rsp + 8]
  test r11d, r11d
  jz _rt_error_E240
  lea r12, [rip + _tail_1_dims]
  mov [r12 + 0], r11d
  imul r10d, r11d
  mov r11d, [rsp + 0]
  test r11d, r11d
  jz _rt_error_E240
  lea r12, [rip + _tail_1_dims]
  mov [r12 + 4], r11d
  imul r10d, r11d
  add rsp, 16
  lea r12, [rip + _tail_1_ndim]
  mov dword ptr [r12], 2
  mov edi, r10d
  shl rdi, 1
  call _rt_mmap
  lea r12, [rip + _tail_1_ptr]
  mov [r12], rax
_stmt_1_end:

_stmt_2:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 1]
  test ecx, ecx
  jnz _stmt_2_end
  mov eax, 42
  push rax
  mov eax, 2
  push rax
  mov eax, 3
  push rax
  xor eax, eax
  mov edx, [rsp + 8]
  dec edx
  add eax, edx
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx + 4]
  imul eax, edx
  mov edx, [rsp + 0]
  dec edx
  add eax, edx
  add rsp, 16
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_2_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_2_aedone
_stmt_2_aeskip:
  add rsp, 8
_stmt_2_aedone:
_stmt_2_end:

_stmt_3:  # READ_OUT
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 2]
  test ecx, ecx
  jnz _stmt_3_end
  mov eax, 2
  push rax
  mov eax, 3
  push rax
  xor eax, eax
  mov edx, [rsp + 8]
  dec edx
  add eax, edx
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx + 4]
  imul eax, edx
  mov edx, [rsp + 0]
  dec edx
  add eax, edx
  add rsp, 16
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  movzx eax, word ptr [rcx + rax*2]
  mov edi, eax
  call _rt_write_roman
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
  jmp _rt_error_E633


# ========== Program Data ==========
.section .data
_stmt_flags:
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
.align 8
_tail_1_ptr: .space 8
_tail_1_ndim: .space 4
_tail_1_dims: .space 32
_tail_1_ign: .space 1
.align 8
_tail_1_stash_ptr: .space 8
_tail_1_stash_sp: .space 4

