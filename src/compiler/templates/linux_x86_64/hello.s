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
  mov eax, 14
  push rax
  mov r10d, 1
  mov r11d, [rsp + 0]
  test r11d, r11d
  jz _rt_error_E240
  lea r12, [rip + _tail_1_dims]
  mov [r12 + 0], r11d
  imul r10d, r11d
  add rsp, 8
  lea r12, [rip + _tail_1_ndim]
  mov dword ptr [r12], 1
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
  mov eax, 238
  push rax
  mov eax, 1
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
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

_stmt_3:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 2]
  test ecx, ecx
  jnz _stmt_3_end
  mov eax, 108
  push rax
  mov eax, 2
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_3_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_3_aedone
_stmt_3_aeskip:
  add rsp, 8
_stmt_3_aedone:
_stmt_3_end:

_stmt_4:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 3]
  test ecx, ecx
  jnz _stmt_4_end
  mov eax, 112
  push rax
  mov eax, 3
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_4_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_4_aedone
_stmt_4_aeskip:
  add rsp, 8
_stmt_4_aedone:
_stmt_4_end:

_stmt_5:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 4]
  test ecx, ecx
  jnz _stmt_5_end
  mov eax, 0
  push rax
  mov eax, 4
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_5_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_5_aedone
_stmt_5_aeskip:
  add rsp, 8
_stmt_5_aedone:
_stmt_5_end:

_stmt_6:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 5]
  test ecx, ecx
  jnz _stmt_6_end
  mov eax, 64
  push rax
  mov eax, 5
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_6_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_6_aedone
_stmt_6_aeskip:
  add rsp, 8
_stmt_6_aedone:
_stmt_6_end:

_stmt_7:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 6]
  test ecx, ecx
  jnz _stmt_7_end
  mov eax, 194
  push rax
  mov eax, 6
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_7_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_7_aedone
_stmt_7_aeskip:
  add rsp, 8
_stmt_7_aedone:
_stmt_7_end:

_stmt_8:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 7]
  test ecx, ecx
  jnz _stmt_8_end
  mov eax, 48
  push rax
  mov eax, 7
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_8_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_8_aedone
_stmt_8_aeskip:
  add rsp, 8
_stmt_8_aedone:
_stmt_8_end:

_stmt_9:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 8]
  test ecx, ecx
  jnz _stmt_9_end
  mov eax, 26
  push rax
  mov eax, 8
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_9_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_9_aedone
_stmt_9_aeskip:
  add rsp, 8
_stmt_9_aedone:
_stmt_9_end:

_stmt_10:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 9]
  test ecx, ecx
  jnz _stmt_10_end
  mov eax, 244
  push rax
  mov eax, 9
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_10_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_10_aedone
_stmt_10_aeskip:
  add rsp, 8
_stmt_10_aedone:
_stmt_10_end:

_stmt_11:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 10]
  test ecx, ecx
  jnz _stmt_11_end
  mov eax, 168
  push rax
  mov eax, 10
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_11_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_11_aedone
_stmt_11_aeskip:
  add rsp, 8
_stmt_11_aedone:
_stmt_11_end:

_stmt_12:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 11]
  test ecx, ecx
  jnz _stmt_12_end
  mov eax, 24
  push rax
  mov eax, 11
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_12_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_12_aedone
_stmt_12_aeskip:
  add rsp, 8
_stmt_12_aedone:
_stmt_12_end:

_stmt_13:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 12]
  test ecx, ecx
  jnz _stmt_13_end
  mov eax, 16
  push rax
  mov eax, 12
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_13_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_13_aedone
_stmt_13_aeskip:
  add rsp, 8
_stmt_13_aedone:
_stmt_13_end:

_stmt_14:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 13]
  test ecx, ecx
  jnz _stmt_14_end
  mov eax, 162
  push rax
  mov eax, 13
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_14_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_14_aedone
_stmt_14_aeskip:
  add rsp, 8
_stmt_14_aedone:
_stmt_14_end:

_stmt_15:  # ASSIGN
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 14]
  test ecx, ecx
  jnz _stmt_15_end
  mov eax, 52
  push rax
  mov eax, 14
  push rax
  pop rax
  dec eax
  lea rcx, [rip + _tail_1_dims]
  mov edx, [rcx]
  cmp eax, edx
  jae _rt_error_E241
  lea rcx, [rip + _tail_1_ign]
  movzx edx, byte ptr [rcx]
  test edx, edx
  jnz _stmt_15_aeskip
  lea rcx, [rip + _tail_1_ptr]
  mov rcx, [rcx]
  pop rdx
  mov [rcx + rax*2], dx
  jmp _stmt_15_aedone
_stmt_15_aeskip:
  add rsp, 8
_stmt_15_aedone:
_stmt_15_end:

_stmt_16:  # READ_OUT
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 15]
  test ecx, ecx
  jnz _stmt_16_end
  lea rax, [rip + _tail_1_ptr]
  mov rdi, [rax]
  lea rax, [rip + _tail_1_dims]
  mov esi, [rax]
  mov edx, 2
  call _rt_read_out_array
_stmt_16_end:

_stmt_17:  # GIVE_UP
  lea rax, [rip + _stmt_flags]
  movzx ecx, byte ptr [rax + 16]
  test ecx, ecx
  jnz _stmt_17_end
  xor edi, edi
  mov eax, 60
  syscall
_stmt_17_end:
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

