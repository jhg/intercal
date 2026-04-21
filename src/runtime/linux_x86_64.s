// runtime_linux_x86_64.s - INTERCAL runtime for Linux x86_64
// Part of the primordial spark (chispa primigenea)

.intel_syntax noprefix

.section .text
.align 16

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

// _rt_mingle: interleave two 16-bit values into 32-bit
// Input: edi=left (16-bit), esi=right (16-bit)
// Output: eax=result (32-bit)
// Left bits go to odd positions (1,3,5...), right bits to even (0,2,4...)
_rt_mingle:
    push rbx
    xor eax, eax
    xor r8d, r8d           // bit counter (0..15)
.Lmingle_loop:
    cmp r8d, 16
    jge .Lmingle_done
    // Extract bit r8d from esi (right), place at position r8d*2
    mov ecx, r8d
    mov edx, esi
    shr edx, cl
    and edx, 1
    lea ecx, [r8d*2]       // ecx = r8d*2
    shl edx, cl
    or eax, edx
    // Extract bit r8d from edi (left), place at position r8d*2+1
    mov ecx, r8d
    mov edx, edi
    shr edx, cl
    and edx, 1
    lea ecx, [r8d*2 + 1]   // ecx = r8d*2+1
    shl edx, cl
    or eax, edx
    inc r8d
    jmp .Lmingle_loop
.Lmingle_done:
    pop rbx
    ret

// _rt_select: extract bits via mask
// Input: edi=value, esi=mask, edx=width (16 or 32)
// Output: eax=result
_rt_select:
    xor eax, eax           // result
    xor r8d, r8d           // output bit position
    xor ecx, ecx           // loop counter
.Lselect_loop:
    cmp ecx, edx
    jge .Lselect_done
    // Check if mask bit ecx is set
    bt esi, ecx
    jnc .Lselect_next
    // Extract bit ecx from value
    bt edi, ecx
    jnc .Lselect_zero
    bts eax, r8d
.Lselect_zero:
    inc r8d
.Lselect_next:
    inc ecx
    jmp .Lselect_loop
.Lselect_done:
    ret

// _rt_unary_and_16: rotate right 1, AND with original, mask to 16 bits
// Input: edi; Output: eax
_rt_unary_and_16:
    mov eax, edi
    shr eax, 1
    mov edx, edi
    shl edx, 15
    or eax, edx
    and eax, 0xFFFF
    and eax, edi
    and eax, 0xFFFF
    ret

// _rt_unary_or_16
_rt_unary_or_16:
    mov eax, edi
    shr eax, 1
    mov edx, edi
    shl edx, 15
    or eax, edx
    and eax, 0xFFFF
    or eax, edi
    and eax, 0xFFFF
    ret

// _rt_unary_xor_16
_rt_unary_xor_16:
    mov eax, edi
    shr eax, 1
    mov edx, edi
    shl edx, 15
    or eax, edx
    and eax, 0xFFFF
    xor eax, edi
    and eax, 0xFFFF
    ret

// _rt_unary_and_32
_rt_unary_and_32:
    mov eax, edi
    ror eax, 1
    and eax, edi
    ret

// _rt_unary_or_32
_rt_unary_or_32:
    mov eax, edi
    ror eax, 1
    or eax, edi
    ret

// _rt_unary_xor_32
_rt_unary_xor_32:
    mov eax, edi
    ror eax, 1
    xor eax, edi
    ret

// _rt_write_roman: output value in Roman numerals
// Input: edi=value (32-bit unsigned)
_rt_write_roman:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    mov ebx, edi           // value
    test ebx, ebx
    jz .Lroman_done
    lea r12, [rip + _rtable]
.Lroman_loop:
    mov eax, [r12]
    test eax, eax
    jz .Lroman_done
    cmp ebx, eax
    jb .Lroman_next
    sub ebx, eax
    mov eax, [r12 + 4]     // string offset
    lea r13, [rip + _rstrings]
    add r13, rax
    // strlen
    xor ecx, ecx
.Lroman_slen:
    cmp byte ptr [r13 + rcx], 0
    je .Lroman_gotlen
    inc ecx
    jmp .Lroman_slen
.Lroman_gotlen:
    // write(1, r13, ecx)
    mov eax, 1             // sys_write
    mov edi, 1             // fd=stdout
    mov rsi, r13           // buf
    mov edx, ecx          // len
    syscall
    jmp .Lroman_loop
.Lroman_next:
    add r12, 8
    jmp .Lroman_loop
.Lroman_done:
    // write newline
    lea rsi, [rip + _nl]
    mov eax, 1
    mov edi, 1
    mov edx, 1
    syscall
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

// _rt_read_out_array: Turing Text Model output
// Input: rdi=array_ptr, esi=count, edx=elem_size (2=16bit, 4=32bit)
_rt_read_out_array:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi           // array ptr
    mov r13d, esi          // count
    mov r14d, edx          // elem size
    lea r15, [rip + _ttm_out_pos]
    mov ebx, [r15]         // current TTM position
    xor ecx, ecx          // index
    mov [rbp - 48], ecx   // store index on stack
    sub rsp, 16           // scratch space
.Lttm_loop:
    mov ecx, [rbp - 48]
    cmp ecx, r13d
    jge .Lttm_done
    // Load element
    cmp r14d, 2
    je .Lttm_load16
    mov eax, [r12 + rcx*4]
    jmp .Lttm_loaded
.Lttm_load16:
    movzx eax, word ptr [r12 + rcx*2]
.Lttm_loaded:
    sub ebx, eax
    and ebx, 0xFF
    // Reverse 8 bits of ebx to get character
    mov eax, ebx
    // Bit reverse 8-bit value in eax
    xor edx, edx
    mov ecx, 8
.Lttm_rev:
    shr eax, 1
    rcl edx, 1
    dec ecx
    jnz .Lttm_rev
    and edx, 0xFF
    // Write character
    mov byte ptr [rsp], dl
    mov eax, 1            // sys_write
    mov edi, 1            // stdout
    lea rsi, [rsp]
    mov edx, 1
    // edx clobbered by bit reverse, reload
    mov edx, 1
    syscall
    mov ecx, [rbp - 48]
    inc ecx
    mov [rbp - 48], ecx
    jmp .Lttm_loop
.Lttm_done:
    mov [r15], ebx
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

// _rt_write_in_array: Turing Text Model input
// Input: rdi=array_ptr, esi=count, edx=elem_size
_rt_write_in_array:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 24
    mov r12, rdi           // array ptr
    mov r13d, esi          // count
    mov r14d, edx          // elem size
    lea r15, [rip + _ttm_in_pos]
    mov ebx, [r15]         // current TTM position
    xor ecx, ecx
    mov [rbp - 48], ecx   // index
.Lttm_in_loop:
    mov ecx, [rbp - 48]
    cmp ecx, r13d
    jge .Lttm_in_done
    // Read 1 byte from stdin
    xor eax, eax          // sys_read
    xor edi, edi          // fd=stdin
    lea rsi, [rsp]
    mov edx, 1
    syscall
    test eax, eax
    jz .Lttm_in_eof
    // Reverse bits of input byte
    movzx eax, byte ptr [rsp]
    xor edx, edx
    mov ecx, 8
.Lttm_in_rev:
    shr eax, 1
    rcl edx, 1
    dec ecx
    jnz .Lttm_in_rev
    and edx, 0xFF
    // Compute array value: (reversed - prev_pos) mod 256
    mov eax, edx
    sub eax, ebx
    and eax, 0xFF
    // Store
    mov ecx, [rbp - 48]
    cmp r14d, 2
    je .Lttm_in_store16
    mov [r12 + rcx*4], eax
    jmp .Lttm_in_stored
.Lttm_in_store16:
    mov [r12 + rcx*2], ax
.Lttm_in_stored:
    mov ebx, edx          // update position
    mov ecx, [rbp - 48]
    inc ecx
    mov [rbp - 48], ecx
    jmp .Lttm_in_loop
.Lttm_in_eof:
    jmp _rt_error_E562
.Lttm_in_done:
    mov [r15], ebx
    add rsp, 24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

// _rt_write_in_scalar: parse English digit names from stdin
// Output: eax=parsed number
_rt_write_in_scalar:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 280           // buffer space
    lea r12, [rbp - 328]  // buffer start (adjusted for pushes)
    // Actually let's use rsp as buffer base
    mov r12, rsp
    xor r13d, r13d        // bytes read
.Lwi_read:
    xor eax, eax          // sys_read
    xor edi, edi          // stdin
    lea rsi, [r12 + r13]
    mov edx, 1
    syscall
    test eax, eax
    jz .Lwi_parse
    movzx eax, byte ptr [r12 + r13]
    cmp eax, 10           // newline
    je .Lwi_parse
    inc r13d
    cmp r13d, 255
    jl .Lwi_read
.Lwi_parse:
    test r13d, r13d
    jz .Lwi_eof
    mov byte ptr [r12 + r13], 0    // null terminate
    // Uppercase the buffer
    xor ecx, ecx
.Lwi_upper:
    movzx eax, byte ptr [r12 + rcx]
    test eax, eax
    jz .Lwi_tokenize
    cmp eax, 97           // 'a'
    jl .Lwi_upper_next
    cmp eax, 122          // 'z'
    jg .Lwi_upper_next
    sub eax, 32
    mov byte ptr [r12 + rcx], al
.Lwi_upper_next:
    inc ecx
    jmp .Lwi_upper
.Lwi_tokenize:
    xor ebx, ebx          // result
    xor r14d, r14d        // pos in buffer
.Lwi_tok_loop:
    movzx eax, byte ptr [r12 + r14]
    test eax, eax
    jz .Lwi_tok_done
    cmp eax, 32           // space
    jne .Lwi_match
    inc r14d
    jmp .Lwi_tok_loop
.Lwi_match:
    // Try each digit name
    lea r8, [rip + _digit_names]
    lea r9, [rip + _digit_values]
    xor r10d, r10d        // name index
.Lwi_try_name:
    cmp r10d, 12
    jge .Lwi_bad_token
    // Compare token at r12+r14 with name at r8
    xor ecx, ecx
.Lwi_cmp:
    movzx eax, byte ptr [r8 + rcx]
    movzx edx, byte ptr [r12 + r14 + rcx]
    test eax, eax
    jz .Lwi_cmp_end
    cmp eax, edx
    jne .Lwi_next_name
    inc ecx
    jmp .Lwi_cmp
.Lwi_cmp_end:
    // Name matched. Check boundary.
    movzx edx, byte ptr [r12 + r14 + rcx]
    test edx, edx
    jz .Lwi_matched
    cmp edx, 32
    je .Lwi_matched
    // Not a boundary, fall through to next name
.Lwi_next_name:
    // Advance r8 past current name (find null)
    movzx eax, byte ptr [r8]
    inc r8
    test eax, eax
    jnz .Lwi_next_name
    inc r10d
    jmp .Lwi_try_name
.Lwi_matched:
    // result = result * 10 + digit_value
    imul ebx, ebx, 10
    movzx eax, byte ptr [r9 + r10]
    add ebx, eax
    add r14d, ecx         // advance past token
    jmp .Lwi_tok_loop
.Lwi_tok_done:
    mov eax, ebx
    add rsp, 280
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
.Lwi_bad_token:
    add rsp, 280
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    jmp _rt_error_E579
.Lwi_eof:
    add rsp, 280
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    jmp _rt_error_E562

// _rt_mmap: allocate memory via mmap
// Input: rdi=size; Output: rax=pointer
_rt_mmap:
    mov rsi, rdi           // length
    xor edi, edi           // addr=NULL
    mov edx, 3             // PROT_READ|PROT_WRITE
    mov r10d, 0x22         // MAP_PRIVATE|MAP_ANONYMOUS
    mov r8, -1             // fd=-1
    xor r9d, r9d          // offset=0
    mov eax, 9             // sys_mmap
    syscall
    cmp rax, -1
    je _rt_error_E000
    ret

// _rt_resume_1: pop NEXT stack and jump
_rt_resume_1:
    lea rax, [rip + _next_sp]
    mov ecx, [rax]
    test ecx, ecx
    jz _rt_error_E632
    dec ecx
    mov [rax], ecx
    lea rdx, [rip + _next_stack]
    mov rax, [rdx + rcx*8]
    jmp rax

// Error handlers - write to stderr and exit with code 1
_rt_error_E000:
    lea rsi, [rip + _errmsg_000]
    mov edx, 50
    jmp .Lerror_exit

_rt_error_E017:
    lea rsi, [rip + _errmsg_017]
    mov edx, 48
    jmp .Lerror_exit

_rt_error_E123:
    lea rsi, [rip + _errmsg_123]
    mov edx, 54
    jmp .Lerror_exit

_rt_error_E129:
    lea rsi, [rip + _errmsg_129]
    mov edx, 35
    jmp .Lerror_exit

_rt_error_E139:
    lea rsi, [rip + _errmsg_139]
    mov edx, 38
    jmp .Lerror_exit

_rt_error_E200:
    lea rsi, [rip + _errmsg_200]
    mov edx, 42
    jmp .Lerror_exit

_rt_error_E240:
    lea rsi, [rip + _errmsg_240]
    mov edx, 41
    jmp .Lerror_exit

_rt_error_E241:
    lea rsi, [rip + _errmsg_241]
    mov edx, 38
    jmp .Lerror_exit

_rt_error_E275:
    lea rsi, [rip + _errmsg_275]
    mov edx, 38
    jmp .Lerror_exit

_rt_error_E436:
    lea rsi, [rip + _errmsg_436]
    mov edx, 39
    jmp .Lerror_exit

_rt_error_E533:
    lea rsi, [rip + _errmsg_533]
    mov edx, 39
    jmp .Lerror_exit

_rt_error_E562:
    lea rsi, [rip + _errmsg_562]
    mov edx, 41
    jmp .Lerror_exit

_rt_error_E579:
    lea rsi, [rip + _errmsg_579]
    mov edx, 36
    jmp .Lerror_exit

_rt_error_E621:
    lea rsi, [rip + _errmsg_621]
    mov edx, 44
    jmp .Lerror_exit

_rt_error_E632:
    lea rsi, [rip + _errmsg_632]
    mov edx, 52
    jmp .Lerror_exit

_rt_error_E633:
    lea rsi, [rip + _errmsg_633]
    mov edx, 46
    jmp .Lerror_exit

.Lerror_exit:
    mov eax, 1             // sys_write
    mov edi, 2             // stderr
    syscall
    mov eax, 60            // sys_exit
    mov edi, 1
    syscall


// ========== Label 666 Syscall Handler ==========

_rt_syscall_666:
    // Read .1 (syscall number)
    lea rax, [rip + _spot_1]
    mov eax, [rax]
    cmp eax, 1
    je _rt_sys666_open
    cmp eax, 2
    je _rt_sys666_read
    cmp eax, 3
    je _rt_sys666_write
    cmp eax, 4
    je _rt_sys666_close
    cmp eax, 5
    je _rt_sys666_argc
    cmp eax, 6
    je _rt_sys666_argv
    cmp eax, 8
    je _rt_sys666_exit
    cmp eax, 9
    je _rt_sys666_getrand
    jmp _rt_error_E000

// Syscall 1: open file
// .2=mode (0=read,1=write), ,65535=filename (ASCII codes)
// Output: .3=fd (0=error)
_rt_sys666_open:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    // Read mode from .2
    lea rax, [rip + _spot_2]
    mov ebx, [rax]
    // Read filename from ,65535
    lea rax, [rip + _tail_65535_ptr]
    mov r12, [rax]
    test r12, r12
    jz .Lopen_err
    lea rax, [rip + _tail_65535_dims]
    mov r13d, [rax]        // filename length
    // Allocate stack space for C string (aligned)
    mov eax, r13d
    add eax, 16
    and eax, -16
    sub rsp, rax
    mov [rbp - 32], eax    // save alloc size
    // Copy array elements to C string
    xor ecx, ecx
.Lopen_copy:
    cmp ecx, r13d
    jge .Lopen_copied
    movzx edx, word ptr [r12 + rcx*2]
    mov byte ptr [rsp + rcx], dl
    inc ecx
    jmp .Lopen_copy
.Lopen_copied:
    mov byte ptr [rsp + rcx], 0    // null terminate
    // Compute flags
    xor esi, esi           // O_RDONLY=0
    xor edx, edx
    cmp ebx, 1
    jne .Lopen_do
    mov esi, 0x241         // O_WRONLY|O_CREAT|O_TRUNC (Linux)
    mov edx, 0x1B6         // 0666
.Lopen_do:
    mov rdi, rsp           // pathname
    mov eax, 2             // sys_open
    syscall
    test rax, rax
    js .Lopen_err
    mov r12d, eax          // fd
    jmp .Lopen_store
.Lopen_err:
    xor r12d, r12d
.Lopen_store:
    lea rax, [rip + _spot_3]
    mov [rax], r12d
    // Restore stack
    mov eax, [rbp - 32]
    add rsp, rax
    pop r13
    pop r12
    pop rbx
    pop rbp
    jmp _rt_resume_1

// Syscall 2: read
// .2=fd, .3=max bytes
// Output: .4=bytes read, ,65535=data
_rt_sys666_read:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    // Get fd from .2
    lea rax, [rip + _spot_2]
    mov ebx, [rax]
    // Get max bytes from .3
    lea rax, [rip + _spot_3]
    mov r12d, [rax]
    // Allocate buffer via mmap
    mov edi, r12d
    add edi, 4096
    call _rt_mmap
    mov r13, rax           // buffer ptr
    // Read from fd
    mov edi, ebx           // fd
    mov rsi, r13           // buffer
    mov edx, r12d          // max
    xor eax, eax          // sys_read
    syscall
    mov r14d, eax          // bytes read
    // Auto-dimension ,65535
    mov edi, r14d
    shl edi, 1
    add edi, 16
    call _rt_mmap
    mov r12, rax
    lea rax, [rip + _tail_65535_ptr]
    mov [rax], r12
    lea rax, [rip + _tail_65535_ndim]
    mov dword ptr [rax], 1
    lea rax, [rip + _tail_65535_dims]
    mov [rax], r14d
    // Copy bytes to array
    xor ecx, ecx
.Lread_copy:
    cmp ecx, r14d
    jge .Lread_done
    movzx edx, byte ptr [r13 + rcx]
    mov word ptr [r12 + rcx*2], dx
    inc ecx
    jmp .Lread_copy
.Lread_done:
    lea rax, [rip + _spot_4]
    mov [rax], r14d
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    jmp _rt_resume_1

// Syscall 3: write
// .2=fd, .3=count, ,65535=data
// Output: .4=bytes written
_rt_sys666_write:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    // Get fd from .2
    lea rax, [rip + _spot_2]
    mov ebx, [rax]
    // Get count from .3
    lea rax, [rip + _spot_3]
    mov r12d, [rax]
    // Get array ptr
    lea rax, [rip + _tail_65535_ptr]
    mov r13, [rax]
    test r13, r13
    jz .Lwrite_zero
    // Allocate stack for byte buffer
    mov eax, r12d
    add eax, 16
    and eax, -16
    sub rsp, rax
    mov [rbp - 32], eax
    // Convert array to bytes
    xor ecx, ecx
.Lwrite_copy:
    cmp ecx, r12d
    jge .Lwrite_do
    movzx edx, word ptr [r13 + rcx*2]
    mov byte ptr [rsp + rcx], dl
    inc ecx
    jmp .Lwrite_copy
.Lwrite_do:
    mov eax, 1             // sys_write
    mov edi, ebx           // fd
    mov rsi, rsp           // buf
    mov edx, r12d          // count
    syscall
    mov ebx, eax           // bytes written
    mov eax, [rbp - 32]
    add rsp, rax
    jmp .Lwrite_store
.Lwrite_zero:
    xor ebx, ebx
.Lwrite_store:
    lea rax, [rip + _spot_4]
    mov [rax], ebx
    pop r13
    pop r12
    pop rbx
    pop rbp
    jmp _rt_resume_1

// Syscall 4: close
// .2=fd
_rt_sys666_close:
    lea rax, [rip + _spot_2]
    mov edi, [rax]
    mov eax, 3             // sys_close
    syscall
    jmp _rt_resume_1

// Syscall 5: argc
// Output: .3=count
_rt_sys666_argc:
    lea rax, [rip + _rt_argc]
    mov eax, [rax]
    lea rcx, [rip + _spot_3]
    mov [rcx], eax
    jmp _rt_resume_1

// Syscall 6: argv
// .2=index, Output: .3=length, ,65535=chars
_rt_sys666_argv:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    // Get index from .2
    lea rax, [rip + _spot_2]
    mov ebx, [rax]
    // Get argv pointer
    lea rax, [rip + _rt_argv]
    mov rax, [rax]
    // argv[index]
    mov r12, [rax + rbx*8]
    // strlen
    xor r13d, r13d
.Largv_strlen:
    cmp byte ptr [r12 + r13], 0
    je .Largv_got_len
    inc r13d
    jmp .Largv_strlen
.Largv_got_len:
    // Allocate array
    mov edi, r13d
    shl edi, 1
    add edi, 16
    call _rt_mmap
    mov r14, rax
    lea rax, [rip + _tail_65535_ptr]
    mov [rax], r14
    lea rax, [rip + _tail_65535_ndim]
    mov dword ptr [rax], 1
    lea rax, [rip + _tail_65535_dims]
    mov [rax], r13d
    // Copy chars
    xor ecx, ecx
.Largv_copy:
    cmp ecx, r13d
    jge .Largv_done
    movzx edx, byte ptr [r12 + rcx]
    mov word ptr [r14 + rcx*2], dx
    inc ecx
    jmp .Largv_copy
.Largv_done:
    lea rax, [rip + _spot_3]
    mov [rax], r13d
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    jmp _rt_resume_1

// Syscall 8: exit
// .2=exit code
_rt_sys666_exit:
    lea rax, [rip + _spot_2]
    mov edi, [rax]
    mov eax, 60            // sys_exit
    syscall

// Syscall 9: getrand
// .2=0: uniform 16-bit; .2>0: range 0-.2
// Output: .3=random value
_rt_sys666_getrand:
    sub rsp, 16
    lea rdi, [rsp]         // buf
    mov esi, 2             // count=2 bytes
    xor edx, edx          // flags=0
    mov eax, 318           // sys_getrandom
    syscall
    movzx eax, word ptr [rsp]
    add rsp, 16
    lea rcx, [rip + _spot_2]
    mov ecx, [rcx]
    test ecx, ecx
    jz .Lrand_store
    inc ecx
    xor edx, edx
    div ecx
    mov eax, edx          // remainder
.Lrand_store:
    lea rcx, [rip + _spot_3]
    mov [rcx], eax
    jmp _rt_resume_1


// ========== Data Section ==========

.section .data
.align 8

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

// ========== BSS Section ==========

.section .bss
.align 8
_next_stack: .space 632
_next_sp: .space 4

_ttm_out_pos: .space 4
_ttm_in_pos: .space 4

_rt_argc: .space 4
_rt_argv: .space 8
