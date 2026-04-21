# syslib_native_linux_x86_64.s - Native INTERCAL syslib for Linux x86_64
# Labels 1000-1999: arithmetic, random

.intel_syntax noprefix

.section .text
.align 16

.global _rt_syslib_1000
.global _rt_syslib_1009
.global _rt_syslib_1010
.global _rt_syslib_1020
.global _rt_syslib_1030
.global _rt_syslib_1039
.global _rt_syslib_1040
.global _rt_syslib_1050
.global _rt_syslib_1500
.global _rt_syslib_1509
.global _rt_syslib_1510
.global _rt_syslib_1520
.global _rt_syslib_1530
.global _rt_syslib_1540
.global _rt_syslib_1549
.global _rt_syslib_1550
.global _rt_syslib_1900
.global _rt_syslib_1910
.global _rt_syslib_1999

# Label 1000: .3 = .1 + .2 (error on overflow)
_rt_syslib_1000:
    lea rax, [rip + _spot_1]
    mov ecx, [rax]
    lea rax, [rip + _spot_2]
    mov edx, [rax]
    add ecx, edx
    cmp ecx, 65535
    ja _rt_syslib_1999
    lea rax, [rip + _spot_3]
    mov [rax], ecx
    jmp _rt_resume_1

# Label 1009: .3 = .1 + .2, .4 = overflow flag
_rt_syslib_1009:
    lea rax, [rip + _spot_1]
    mov ecx, [rax]
    lea rax, [rip + _spot_2]
    mov edx, [rax]
    add ecx, edx
    mov ebx, 1            # no overflow
    cmp ecx, 65535
    jbe .Lsys1009_ok
    mov ebx, 2            # overflow
.Lsys1009_ok:
    and ecx, 0xFFFF
    lea rax, [rip + _spot_3]
    mov [rax], ecx
    lea rax, [rip + _spot_4]
    mov [rax], ebx
    jmp _rt_resume_1

# Label 1010: .3 = .1 - .2 (wraps)
_rt_syslib_1010:
    lea rax, [rip + _spot_1]
    mov ecx, [rax]
    lea rax, [rip + _spot_2]
    mov edx, [rax]
    sub ecx, edx
    and ecx, 0xFFFF
    lea rax, [rip + _spot_3]
    mov [rax], ecx
    jmp _rt_resume_1

# Label 1020: .1 = .1 + 1 (wraps)
_rt_syslib_1020:
    lea rax, [rip + _spot_1]
    mov ecx, [rax]
    inc ecx
    and ecx, 0xFFFF
    mov [rax], ecx
    jmp _rt_resume_1

# Label 1030: .3 = .1 * .2 (error on overflow)
_rt_syslib_1030:
    lea rax, [rip + _spot_1]
    mov ecx, [rax]
    lea rax, [rip + _spot_2]
    mov edx, [rax]
    imul ecx, edx
    cmp ecx, 65535
    ja _rt_syslib_1999
    lea rax, [rip + _spot_3]
    mov [rax], ecx
    jmp _rt_resume_1

# Label 1039: .3 = .1 * .2, .4 = overflow flag
_rt_syslib_1039:
    lea rax, [rip + _spot_1]
    mov ecx, [rax]
    lea rax, [rip + _spot_2]
    mov edx, [rax]
    imul ecx, edx
    mov ebx, 1
    cmp ecx, 65535
    jbe .Lsys1039_ok
    mov ebx, 2
.Lsys1039_ok:
    and ecx, 0xFFFF
    lea rax, [rip + _spot_3]
    mov [rax], ecx
    lea rax, [rip + _spot_4]
    mov [rax], ebx
    jmp _rt_resume_1

# Label 1040: .3 = .1 / .2 (0 if .2=0)
_rt_syslib_1040:
    lea rax, [rip + _spot_1]
    mov eax, [rax]
    lea rcx, [rip + _spot_2]
    mov ecx, [rcx]
    test ecx, ecx
    jz .Lsys1040_zero
    xor edx, edx
    div ecx
    jmp .Lsys1040_store
.Lsys1040_zero:
    xor eax, eax
.Lsys1040_store:
    lea rcx, [rip + _spot_3]
    mov [rcx], eax
    jmp _rt_resume_1

# Label 1050: .2 = :1 / .1 (error on overflow, 0 if .1=0)
_rt_syslib_1050:
    lea rax, [rip + _twospot_1]
    mov eax, [rax]
    lea rcx, [rip + _spot_1]
    mov ecx, [rcx]
    test ecx, ecx
    jz .Lsys1050_zero
    xor edx, edx
    div ecx
    cmp eax, 65535
    ja _rt_syslib_1999
    jmp .Lsys1050_store
.Lsys1050_zero:
    xor eax, eax
.Lsys1050_store:
    lea rcx, [rip + _spot_2]
    mov [rcx], eax
    jmp _rt_resume_1

# Label 1500: :3 = :1 + :2 (error on overflow)
_rt_syslib_1500:
    lea rax, [rip + _twospot_1]
    mov ecx, [rax]
    lea rax, [rip + _twospot_2]
    mov edx, [rax]
    add ecx, edx
    jc _rt_syslib_1999
    lea rax, [rip + _twospot_3]
    mov [rax], ecx
    jmp _rt_resume_1

# Label 1509: :3 = :1 + :2, :4 = overflow flag
_rt_syslib_1509:
    lea rax, [rip + _twospot_1]
    mov ecx, [rax]
    lea rax, [rip + _twospot_2]
    mov edx, [rax]
    add ecx, edx
    mov ebx, 1
    jnc .Lsys1509_ok
    mov ebx, 2
.Lsys1509_ok:
    lea rax, [rip + _twospot_3]
    mov [rax], ecx
    lea rax, [rip + _twospot_4]
    mov [rax], ebx
    jmp _rt_resume_1

# Label 1510: :3 = :1 - :2 (wraps)
_rt_syslib_1510:
    lea rax, [rip + _twospot_1]
    mov ecx, [rax]
    lea rax, [rip + _twospot_2]
    mov edx, [rax]
    sub ecx, edx
    lea rax, [rip + _twospot_3]
    mov [rax], ecx
    jmp _rt_resume_1

# Label 1520: :1 = .1 $ .2 (mingle)
_rt_syslib_1520:
    push rbx
    lea rax, [rip + _spot_1]
    mov edi, [rax]
    lea rax, [rip + _spot_2]
    mov esi, [rax]
    call _rt_mingle
    lea rcx, [rip + _twospot_1]
    mov [rcx], eax
    pop rbx
    jmp _rt_resume_1

# Label 1530: :1 = .1 * .2 (16x16->32)
_rt_syslib_1530:
    lea rax, [rip + _spot_1]
    mov ecx, [rax]
    lea rax, [rip + _spot_2]
    mov edx, [rax]
    imul ecx, edx
    lea rax, [rip + _twospot_1]
    mov [rax], ecx
    jmp _rt_resume_1

# Label 1540: :3 = :1 * :2 (error on overflow)
_rt_syslib_1540:
    lea rax, [rip + _twospot_1]
    mov eax, [rax]
    lea rcx, [rip + _twospot_2]
    mov ecx, [rcx]
    # 32x32 -> 64, check upper 32
    mov edx, eax
    imul rdx, rcx
    mov rax, rdx
    shr rdx, 32
    test edx, edx
    jnz _rt_syslib_1999
    lea rcx, [rip + _twospot_3]
    mov [rcx], eax
    jmp _rt_resume_1

# Label 1549: :3 = :1 * :2, :4 = overflow flag
_rt_syslib_1549:
    lea rax, [rip + _twospot_1]
    mov eax, [rax]
    lea rcx, [rip + _twospot_2]
    mov ecx, [rcx]
    mov edx, eax
    imul rdx, rcx
    mov rax, rdx
    shr rdx, 32
    mov ebx, 1
    test edx, edx
    jz .Lsys1549_ok
    mov ebx, 2
.Lsys1549_ok:
    lea rcx, [rip + _twospot_3]
    mov [rcx], eax
    lea rcx, [rip + _twospot_4]
    mov [rcx], ebx
    jmp _rt_resume_1

# Label 1550: :3 = :1 / :2 (0 if :2=0)
_rt_syslib_1550:
    lea rax, [rip + _twospot_1]
    mov eax, [rax]
    lea rcx, [rip + _twospot_2]
    mov ecx, [rcx]
    test ecx, ecx
    jz .Lsys1550_zero
    xor edx, edx
    div ecx
    jmp .Lsys1550_store
.Lsys1550_zero:
    xor eax, eax
.Lsys1550_store:
    lea rcx, [rip + _twospot_3]
    mov [rcx], eax
    jmp _rt_resume_1

# Label 1900: .1 = uniform random 0-65535
_rt_syslib_1900:
    sub rsp, 16
    lea rdi, [rsp]         # buf
    mov esi, 2             # count=2 bytes
    xor edx, edx          # flags=0
    mov eax, 318           # sys_getrandom
    syscall
    movzx eax, word ptr [rsp]
    add rsp, 16
    lea rcx, [rip + _spot_1]
    mov [rcx], eax
    jmp _rt_resume_1

# Label 1910: .2 = random in range 0-.1
_rt_syslib_1910:
    sub rsp, 16
    lea rdi, [rsp]         # buf
    mov esi, 4             # count=4 bytes
    xor edx, edx          # flags=0
    mov eax, 318           # sys_getrandom
    syscall
    mov eax, [rsp]
    add rsp, 16
    lea rcx, [rip + _spot_1]
    mov ecx, [rcx]
    test ecx, ecx
    jz .Lsys1910_zero
    inc ecx
    xor edx, edx
    div ecx
    mov eax, edx          # remainder
    jmp .Lsys1910_store
.Lsys1910_zero:
    xor eax, eax
.Lsys1910_store:
    lea rcx, [rip + _spot_2]
    mov [rcx], eax
    jmp _rt_resume_1

# Label 1999: overflow error
_rt_syslib_1999:
    jmp _rt_error_E275
