// syslib_native_linux_arm64.s - Native syslib for Linux ARM64
// Labels 1000-1999: arithmetic, random

.text

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

.align 2

_rt_syslib_1000:
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w1, [x0]
  adrp x0, _spot_2
  add x0, x0, :lo12:_spot_2
  ldr w2, [x0]
  add w3, w1, w2
  mov w4, #65535
  cmp w3, w4
  b.hi _rt_syslib_1999
  adrp x0, _spot_3
  add x0, x0, :lo12:_spot_3
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1009:
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w1, [x0]
  adrp x0, _spot_2
  add x0, x0, :lo12:_spot_2
  ldr w2, [x0]
  add w3, w1, w2
  mov w4, #65535
  cmp w3, w4
  mov w5, #1
  mov w6, #2
  csel w5, w5, w6, ls
  and w3, w3, w4
  adrp x0, _spot_3
  add x0, x0, :lo12:_spot_3
  str w3, [x0]
  adrp x0, _spot_4
  add x0, x0, :lo12:_spot_4
  str w5, [x0]
  b _rt_resume_1

_rt_syslib_1010:
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w1, [x0]
  adrp x0, _spot_2
  add x0, x0, :lo12:_spot_2
  ldr w2, [x0]
  sub w3, w1, w2
  and w3, w3, #0xFFFF
  adrp x0, _spot_3
  add x0, x0, :lo12:_spot_3
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1020:
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w1, [x0]
  add w1, w1, #1
  and w1, w1, #0xFFFF
  str w1, [x0]
  b _rt_resume_1

_rt_syslib_1030:
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w1, [x0]
  adrp x0, _spot_2
  add x0, x0, :lo12:_spot_2
  ldr w2, [x0]
  mul w3, w1, w2
  mov w4, #65535
  cmp w3, w4
  b.hi _rt_syslib_1999
  adrp x0, _spot_3
  add x0, x0, :lo12:_spot_3
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1039:
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w1, [x0]
  adrp x0, _spot_2
  add x0, x0, :lo12:_spot_2
  ldr w2, [x0]
  mul w3, w1, w2
  mov w4, #65535
  cmp w3, w4
  mov w5, #1
  mov w6, #2
  csel w5, w5, w6, ls
  and w3, w3, w4
  adrp x0, _spot_3
  add x0, x0, :lo12:_spot_3
  str w3, [x0]
  adrp x0, _spot_4
  add x0, x0, :lo12:_spot_4
  str w5, [x0]
  b _rt_resume_1

_rt_syslib_1040:
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w1, [x0]
  adrp x0, _spot_2
  add x0, x0, :lo12:_spot_2
  ldr w2, [x0]
  cbz w2, .Lsys1040_zero
  udiv w3, w1, w2
  b .Lsys1040_store
.Lsys1040_zero:
  mov w3, #0
.Lsys1040_store:
  adrp x0, _spot_3
  add x0, x0, :lo12:_spot_3
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1050:
  adrp x0, _twospot_1
  add x0, x0, :lo12:_twospot_1
  ldr w1, [x0]
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w2, [x0]
  cbz w2, .Lsys1050_zero
  udiv w3, w1, w2
  mov w4, #65535
  cmp w3, w4
  b.hi _rt_syslib_1999
  b .Lsys1050_store
.Lsys1050_zero:
  mov w3, #0
.Lsys1050_store:
  adrp x0, _spot_2
  add x0, x0, :lo12:_spot_2
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1500:
  adrp x0, _twospot_1
  add x0, x0, :lo12:_twospot_1
  ldr w1, [x0]
  adrp x0, _twospot_2
  add x0, x0, :lo12:_twospot_2
  ldr w2, [x0]
  adds w3, w1, w2
  b.cs _rt_syslib_1999
  adrp x0, _twospot_3
  add x0, x0, :lo12:_twospot_3
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1509:
  adrp x0, _twospot_1
  add x0, x0, :lo12:_twospot_1
  ldr w1, [x0]
  adrp x0, _twospot_2
  add x0, x0, :lo12:_twospot_2
  ldr w2, [x0]
  adds w3, w1, w2
  mov w5, #1
  mov w6, #2
  csel w5, w5, w6, cc
  adrp x0, _twospot_3
  add x0, x0, :lo12:_twospot_3
  str w3, [x0]
  adrp x0, _twospot_4
  add x0, x0, :lo12:_twospot_4
  str w5, [x0]
  b _rt_resume_1

_rt_syslib_1510:
  adrp x0, _twospot_1
  add x0, x0, :lo12:_twospot_1
  ldr w1, [x0]
  adrp x0, _twospot_2
  add x0, x0, :lo12:_twospot_2
  ldr w2, [x0]
  sub w3, w1, w2
  adrp x0, _twospot_3
  add x0, x0, :lo12:_twospot_3
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1520:
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w0, [x0]
  adrp x1, _spot_2
  add x1, x1, :lo12:_spot_2
  ldr w1, [x1]
  bl _rt_mingle
  adrp x1, _twospot_1
  add x1, x1, :lo12:_twospot_1
  str w0, [x1]
  b _rt_resume_1

_rt_syslib_1530:
  adrp x0, _spot_1
  add x0, x0, :lo12:_spot_1
  ldr w1, [x0]
  adrp x0, _spot_2
  add x0, x0, :lo12:_spot_2
  ldr w2, [x0]
  mul w3, w1, w2
  adrp x0, _twospot_1
  add x0, x0, :lo12:_twospot_1
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1540:
  adrp x0, _twospot_1
  add x0, x0, :lo12:_twospot_1
  ldr w1, [x0]
  adrp x0, _twospot_2
  add x0, x0, :lo12:_twospot_2
  ldr w2, [x0]
  umull x3, w1, w2
  lsr x4, x3, #32
  cbnz x4, _rt_syslib_1999
  adrp x0, _twospot_3
  add x0, x0, :lo12:_twospot_3
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1549:
  adrp x0, _twospot_1
  add x0, x0, :lo12:_twospot_1
  ldr w1, [x0]
  adrp x0, _twospot_2
  add x0, x0, :lo12:_twospot_2
  ldr w2, [x0]
  umull x3, w1, w2
  lsr x4, x3, #32
  mov w5, #1
  mov w6, #2
  cmp x4, #0
  csel w5, w5, w6, eq
  adrp x0, _twospot_3
  add x0, x0, :lo12:_twospot_3
  str w3, [x0]
  adrp x0, _twospot_4
  add x0, x0, :lo12:_twospot_4
  str w5, [x0]
  b _rt_resume_1

_rt_syslib_1550:
  adrp x0, _twospot_1
  add x0, x0, :lo12:_twospot_1
  ldr w1, [x0]
  adrp x0, _twospot_2
  add x0, x0, :lo12:_twospot_2
  ldr w2, [x0]
  cbz w2, .Lsys1550_zero
  udiv w3, w1, w2
  b .Lsys1550_store
.Lsys1550_zero:
  mov w3, #0
.Lsys1550_store:
  adrp x0, _twospot_3
  add x0, x0, :lo12:_twospot_3
  str w3, [x0]
  b _rt_resume_1

_rt_syslib_1900:
  sub sp, sp, #16
  mov x0, sp
  mov x1, #2
  mov x8, #278
  svc #0
  ldrh w0, [sp]
  add sp, sp, #16
  adrp x1, _spot_1
  add x1, x1, :lo12:_spot_1
  str w0, [x1]
  b _rt_resume_1

_rt_syslib_1910:
  sub sp, sp, #16
  mov x0, sp
  mov x1, #4
  mov x8, #278
  svc #0
  ldr w0, [sp]
  add sp, sp, #16
  adrp x1, _spot_1
  add x1, x1, :lo12:_spot_1
  ldr w1, [x1]
  cbz w1, .Lsys1910_zero
  add w2, w1, #1
  udiv w3, w0, w2
  msub w0, w3, w2, w0
  b .Lsys1910_store
.Lsys1910_zero:
  mov w0, #0
.Lsys1910_store:
  adrp x1, _spot_2
  add x1, x1, :lo12:_spot_2
  str w0, [x1]
  b _rt_resume_1

_rt_syslib_1999:
  b _rt_error_E275


