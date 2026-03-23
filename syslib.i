        DON'T NOTE syslib.i - Pure INTERCAL system library
        DON'T NOTE Labels 1000-1999: arithmetic and random
        DON'T NOTE All algorithms are original implementations

        DON'T NOTE ============================================
        DON'T NOTE Label 1009: 16-bit add with overflow flag
        DON'T NOTE .3 = .1 + .2, .4 = #1 if ok, #2 if overflow
        DON'T NOTE Bit-by-bit unrolled with carry propagation
        DON'T NOTE ============================================

(1009)  DO STASH .10 .11 .12 .13 .14 .15 .16 .17 .18 .19
        DO STASH .20
        DO STASH .30 .31 .32 .33 .34 .35 .36 .37
        DO STASH .38 .39 .40 .41 .42 .43 .44 .45
        PLEASE DO STASH :13 :14 :15
        PLEASE DO .12 <- #0
        DO .13 <- #0

        DON'T NOTE Bit 0 (mask #1)
        DO .15 <- '.1 ~ #1'
        DO .16 <- '.2 ~ #1'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        PLEASE DO .18 <- '"?:13" ~ #1'
        DO .30 <- .18
        PLEASE DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        PLEASE DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 1 (mask #2)
        DO .15 <- '.1 ~ #2'
        DO .16 <- '.2 ~ #2'
        DO :13 <- .15 $ .16
        PLEASE DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        PLEASE DO .18 <- '"?:13" ~ #1'
        DO .31 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        PLEASE DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 2 (mask #4)
        PLEASE DO .15 <- '.1 ~ #4'
        DO .16 <- '.2 ~ #4'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        PLEASE DO :13 <- .17 $ .12
        DO .18 <- '"?:13" ~ #1'
        DO .32 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        PLEASE DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 3 (mask #8)
        DO .15 <- '.1 ~ #8'
        PLEASE DO .16 <- '.2 ~ #8'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        DO .18 <- '"?:13" ~ #1'
        PLEASE DO .33 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        PLEASE DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 4 (mask #16)
        DO .15 <- '.1 ~ #16'
        DO .16 <- '.2 ~ #16'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        PLEASE DO .18 <- '"?:13" ~ #1'
        DO .34 <- .18
        PLEASE DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        PLEASE DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 5 (mask #32)
        DO .15 <- '.1 ~ #32'
        DO .16 <- '.2 ~ #32'
        DO :13 <- .15 $ .16
        PLEASE DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        PLEASE DO .18 <- '"?:13" ~ #1'
        DO .35 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        PLEASE DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 6 (mask #64)
        PLEASE DO .15 <- '.1 ~ #64'
        DO .16 <- '.2 ~ #64'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        PLEASE DO :13 <- .17 $ .12
        DO .18 <- '"?:13" ~ #1'
        DO .36 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        PLEASE DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 7 (mask #128)
        DO .15 <- '.1 ~ #128'
        PLEASE DO .16 <- '.2 ~ #128'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        DO .18 <- '"?:13" ~ #1'
        PLEASE DO .37 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        PLEASE DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 8 (mask #256)
        DO .15 <- '.1 ~ #256'
        DO .16 <- '.2 ~ #256'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        PLEASE DO .18 <- '"?:13" ~ #1'
        DO .38 <- .18
        PLEASE DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        PLEASE DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 9 (mask #512)
        DO .15 <- '.1 ~ #512'
        DO .16 <- '.2 ~ #512'
        DO :13 <- .15 $ .16
        PLEASE DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        PLEASE DO .18 <- '"?:13" ~ #1'
        DO .39 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        PLEASE DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 10 (mask #1024)
        PLEASE DO .15 <- '.1 ~ #1024'
        DO .16 <- '.2 ~ #1024'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        PLEASE DO :13 <- .17 $ .12
        DO .18 <- '"?:13" ~ #1'
        DO .40 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        PLEASE DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 11 (mask #2048)
        DO .15 <- '.1 ~ #2048'
        PLEASE DO .16 <- '.2 ~ #2048'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        DO .18 <- '"?:13" ~ #1'
        PLEASE DO .41 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        PLEASE DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 12 (mask #4096)
        DO .15 <- '.1 ~ #4096'
        DO .16 <- '.2 ~ #4096'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        PLEASE DO .18 <- '"?:13" ~ #1'
        DO .42 <- .18
        PLEASE DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        PLEASE DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 13 (mask #8192)
        DO .15 <- '.1 ~ #8192'
        DO .16 <- '.2 ~ #8192'
        DO :13 <- .15 $ .16
        PLEASE DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        PLEASE DO .18 <- '"?:13" ~ #1'
        DO .43 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        PLEASE DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 14 (mask #16384)
        PLEASE DO .15 <- '.1 ~ #16384'
        DO .16 <- '.2 ~ #16384'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        PLEASE DO :13 <- .17 $ .12
        DO .18 <- '"?:13" ~ #1'
        DO .44 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        PLEASE DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Bit 15 (mask #32768)
        DO .15 <- '.1 ~ #32768'
        PLEASE DO .16 <- '.2 ~ #32768'
        DO :13 <- .15 $ .16
        DO .17 <- '"?:13" ~ #1'
        DO :13 <- .17 $ .12
        DO .18 <- '"?:13" ~ #1'
        PLEASE DO .45 <- .18
        DO :13 <- .15 $ .16
        DO .19 <- '"&:13" ~ #1'
        DO :13 <- .15 $ .12
        PLEASE DO .20 <- '"&:13" ~ #1'
        DO :13 <- .16 $ .12
        DO :14 <- "&:13"
        DO .11 <- ':14 ~ #1'
        DO :13 <- .19 $ .20
        PLEASE DO .12 <- '"V:13" ~ #1'
        PLEASE DO :13 <- .12 $ .11
        DO .12 <- '"V:13" ~ #1'

        DON'T NOTE Reconstruct 16-bit result from individual bits
        DON'T NOTE Level 1: pairs of bits -> 2-bit values
        DO :15 <- .31 $ .30
        DO .46 <- ':15 ~ #3'
        DO :15 <- .33 $ .32
        PLEASE DO .47 <- ':15 ~ #3'
        DO :15 <- .35 $ .34
        DO .48 <- ':15 ~ #3'
        DO :15 <- .37 $ .36
        PLEASE DO .49 <- ':15 ~ #3'
        DO :15 <- .39 $ .38
        DO .50 <- ':15 ~ #3'
        DO :15 <- .41 $ .40
        PLEASE DO .51 <- ':15 ~ #3'
        DO :15 <- .43 $ .42
        PLEASE DO .52 <- ':15 ~ #3'
        DO :15 <- .45 $ .44
        DO .53 <- ':15 ~ #3'

        DON'T NOTE Level 2: 2-bit -> 4-bit
        DO :15 <- .47 $ .46
        DO .54 <- ':15 ~ #15'
        PLEASE DO :15 <- .49 $ .48
        PLEASE DO .55 <- ':15 ~ #15'
        DO :15 <- .51 $ .50
        DO .56 <- ':15 ~ #15'
        DO :15 <- .53 $ .52
        DO .57 <- ':15 ~ #15'

        DON'T NOTE Level 3: 4-bit -> 8-bit
        PLEASE DO :15 <- .55 $ .54
        DO .58 <- ':15 ~ #255'
        DO :15 <- .57 $ .56
        PLEASE DO .59 <- ':15 ~ #255'

        DON'T NOTE Level 4: 8-bit -> 16-bit
        DO :15 <- .59 $ .58
        DO .3 <- ':15 ~ #65535'

        DON'T NOTE Set overflow flag
        DON'T NOTE .4 = #1 if no overflow, #2 if overflow
        DON'T NOTE .12 is the final carry (0 or 1)
        DO :13 <- .12 $ #1
        DO .4 <- '"?:13" ~ #3'

        DO RETRIEVE :15 :14 :13
        PLEASE DO RETRIEVE .45 .44 .43 .42 .41 .40 .39 .38
        DO RETRIEVE .37 .36 .35 .34 .33 .32 .31 .30
        PLEASE DO RETRIEVE .20
        DO RETRIEVE .19 .18 .17 .16 .15 .14 .13 .12 .11 .10
        DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1000: 16-bit add with overflow error
        DON'T NOTE .3 = .1 + .2, error on overflow
        DON'T NOTE ============================================

(1000)  DO (1009) NEXT
        DO .10 <- '.4 ~ #2'
        DO :13 <- .10 $ #1
        PLEASE DO .10 <- '"?:13" ~ #3'
(1800)  DO (1801) NEXT
        DO (1802) NEXT
        DO RESUME .10
        PLEASE DO (1999) NEXT
(1801)  DO FORGET #1
(1802)  DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1010: 16-bit subtract (wraps)
        DON'T NOTE .3 = .1 - .2
        DON'T NOTE Two's complement: .1 + NOT(.2) + 1
        DON'T NOTE ============================================

(1010)  DO STASH .1 .2 .10 .11
        DO STASH :13
        DON'T NOTE Complement .2: XOR each bit with 1
        DO :13 <- '.2 $ #65535'
        DO .10 <- "?:13" ~ '#0 $ #65535'
        DON'T NOTE Add .1 + complement
        DO .2 <- .10
        PLEASE DO (1009) NEXT
        DON'T NOTE Add 1
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DON'T NOTE Mask to 16 bits (already 16-bit from 1009)
        PLEASE DO RETRIEVE :13
        DO RETRIEVE .11 .10 .2 .1
        DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1020: 16-bit increment (wraps)
        DON'T NOTE .1 = .1 + 1
        DON'T NOTE ============================================

(1020)  DO STASH .2
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .1 <- .3
        PLEASE DO RETRIEVE .2
        DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1520: mingle
        DON'T NOTE :1 = .1 $ .2
        DON'T NOTE ============================================

(1520)  DO :1 <- '.1 $ .2'
        PLEASE DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1900: random 16-bit via Label 666
        DON'T NOTE .1 = uniform random 0-65535
        DON'T NOTE ============================================

(1900)  DO STASH .2 .3
        DO .1 <- #9
        DO .2 <- #0
        PLEASE DO (666) NEXT
        DO .1 <- .3
        PLEASE RETRIEVE .2 .3
        DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1910: random in range via Label 666
        DON'T NOTE .2 = random 0-.1
        DON'T NOTE ============================================

(1910)  DO STASH .3 .10
        DO .10 <- .1
        DO .1 <- #9
        DO .2 <- .10
        PLEASE DO (666) NEXT
        PLEASE DO .2 <- .3
        DO .1 <- .10
        PLEASE RETRIEVE .3 .10
        DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1999: overflow error
        DON'T NOTE ============================================

(1999)  DO .10 <- #0
        DON'T NOTE This triggers a runtime error by assigning
        DON'T NOTE a value > 65535 to a 16-bit variable
        DON'T NOTE We use READ OUT to signal the error and exit
        DO STASH .1
        DO .1 <- #0
        DO GIVE UP
