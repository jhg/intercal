        DON'T NOTE syslib.i - Pure INTERCAL system library
        DON'T NOTE Labels 1000-1999: arithmetic and random
        DON'T NOTE All algorithms are original implementations
        DON'T NOTE Key design: NO nested spark/rabbit-ear expressions
        DON'T NOTE Every complex expression uses simple one-op steps

        DON'T NOTE ============================================
        DON'T NOTE Label 1009: 16-bit add with overflow flag
        DON'T NOTE .3 = .1 + .2, .4 = #1 if ok, #2 if overflow
        DON'T NOTE ============================================

(1009)  DO STASH .10 .11 .12 .15 .16 .17 .18 .19
        DO STASH .20 .21
        DO STASH .30 .31 .32 .33 .34 .35 .36 .37
        PLEASE DO STASH .38 .39 .40 .41 .42 .43 .44 .45
        DO STASH .46 .47 .48 .49 .50 .51 .52 .53
        DO STASH .54 .55 .56 .57 .58 .59
        PLEASE DO STASH :13 :14 :15
        DO .12 <- #0

        DON'T NOTE Bit 0 (mask #1)
        DO .15 <- '.1 ~ #1'
        DO .16 <- '.2 ~ #1'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .30 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 1 (mask #2)
        DO .15 <- '.1 ~ #2'
        DO .16 <- '.2 ~ #2'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .31 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 2 (mask #4)
        DO .15 <- '.1 ~ #4'
        DO .16 <- '.2 ~ #4'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .32 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 3 (mask #8)
        DO .15 <- '.1 ~ #8'
        DO .16 <- '.2 ~ #8'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .33 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 4 (mask #16)
        DO .15 <- '.1 ~ #16'
        DO .16 <- '.2 ~ #16'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .34 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 5 (mask #32)
        DO .15 <- '.1 ~ #32'
        DO .16 <- '.2 ~ #32'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .35 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 6 (mask #64)
        DO .15 <- '.1 ~ #64'
        DO .16 <- '.2 ~ #64'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .36 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 7 (mask #128)
        DO .15 <- '.1 ~ #128'
        DO .16 <- '.2 ~ #128'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .37 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 8 (mask #256)
        DO .15 <- '.1 ~ #256'
        DO .16 <- '.2 ~ #256'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .38 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 9 (mask #512)
        DO .15 <- '.1 ~ #512'
        DO .16 <- '.2 ~ #512'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .39 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 10 (mask #1024)
        DO .15 <- '.1 ~ #1024'
        DO .16 <- '.2 ~ #1024'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .40 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 11 (mask #2048)
        DO .15 <- '.1 ~ #2048'
        DO .16 <- '.2 ~ #2048'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .41 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 12 (mask #4096)
        DO .15 <- '.1 ~ #4096'
        DO .16 <- '.2 ~ #4096'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .42 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 13 (mask #8192)
        DO .15 <- '.1 ~ #8192'
        DO .16 <- '.2 ~ #8192'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .43 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 14 (mask #16384)
        DO .15 <- '.1 ~ #16384'
        DO .16 <- '.2 ~ #16384'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .44 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Bit 15 (mask #32768)
        DO .15 <- '.1 ~ #32768'
        DO .16 <- '.2 ~ #32768'
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '?:13'
        DO .17 <- ':14 ~ #1'
        DO :13 <- '.17 $ .12'
        PLEASE DO :14 <- '?:13'
        DO .18 <- ':14 ~ #1'
        DO .45 <- .18
        PLEASE DO :13 <- '.15 $ .16'
        DO :14 <- '&:13'
        DO .19 <- ':14 ~ #1'
        DO :13 <- '.15 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .20 <- ':14 ~ #1'
        DO :13 <- '.16 $ .12'
        PLEASE DO :14 <- '&:13'
        DO .21 <- ':14 ~ #1'
        DO :13 <- '.19 $ .20'
        PLEASE DO :14 <- 'V:13'
        DO .11 <- ':14 ~ #1'
        DO :13 <- '.11 $ .21'
        PLEASE DO :14 <- 'V:13'
        DO .12 <- ':14 ~ #1'

        DON'T NOTE Reconstruct 16-bit result from individual bits
        DON'T NOTE Using bit-reversal mingle: interleave at each level
        DON'T NOTE so that the final interleaving places each bit at
        DON'T NOTE its correct position in the 16-bit result

        DON'T NOTE Level 1: combine bit pairs using bit-reversal grouping
        DON'T NOTE Each pair combines bits separated by 8 positions
        PLEASE DO :15 <- '.38 $ .30'
        DO .46 <- ':15 ~ #3'
        DO :15 <- '.42 $ .34'
        PLEASE DO .47 <- ':15 ~ #3'
        DO :15 <- '.40 $ .32'
        DO .48 <- ':15 ~ #3'
        PLEASE DO :15 <- '.44 $ .36'
        DO .49 <- ':15 ~ #3'
        DO :15 <- '.39 $ .31'
        PLEASE DO .50 <- ':15 ~ #3'
        DO :15 <- '.43 $ .35'
        DO .51 <- ':15 ~ #3'
        PLEASE DO :15 <- '.41 $ .33'
        DO .52 <- ':15 ~ #3'
        DO :15 <- '.45 $ .37'
        PLEASE DO .53 <- ':15 ~ #3'

        DON'T NOTE Level 2: combine 2-bit values into 4-bit values
        PLEASE DO :15 <- '.47 $ .46'
        DO .54 <- ':15 ~ #15'
        DO :15 <- '.49 $ .48'
        PLEASE DO .55 <- ':15 ~ #15'
        PLEASE DO :15 <- '.51 $ .50'
        DO .56 <- ':15 ~ #15'
        DO :15 <- '.53 $ .52'
        PLEASE DO .57 <- ':15 ~ #15'

        DON'T NOTE Level 3: combine 4-bit values into 8-bit values
        DO :15 <- '.55 $ .54'
        PLEASE DO .58 <- ':15 ~ #255'
        DO :15 <- '.57 $ .56'
        DO .59 <- ':15 ~ #255'

        DON'T NOTE Level 4: combine 8-bit values into 16-bit result
        PLEASE DO :15 <- '.59 $ .58'
        DO .3 <- ':15 ~ #65535'

        DON'T NOTE Set overflow flag
        DON'T NOTE .12 is final carry, 0=no overflow, 1=overflow
        DO :13 <- '.12 $ #1'
        PLEASE DO :14 <- '?:13'
        DO .4 <- ':14 ~ #3'

        DO RETRIEVE :15 :14 :13
        DO RETRIEVE .59 .58 .57 .56 .55 .54
        PLEASE DO RETRIEVE .53 .52 .51 .50 .49 .48 .47 .46
        DO RETRIEVE .45 .44 .43 .42 .41 .40 .39 .38
        DO RETRIEVE .37 .36 .35 .34 .33 .32 .31 .30
        PLEASE DO RETRIEVE .21 .20
        DO RETRIEVE .19 .18 .17 .16 .15 .12 .11 .10
        DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1000: 16-bit add with overflow error
        DON'T NOTE .3 = .1 + .2, error on overflow
        DON'T NOTE ============================================

(1000)  DO STASH .10 :13 :14
        DO (1009) NEXT
        PLEASE DO .10 <- '.4 ~ #2'
        DO :13 <- '.10 $ #1'
        DO :14 <- '?:13'
        PLEASE DO .10 <- ':14 ~ #3'
(1800)  DO (1801) NEXT
        DO (1802) NEXT
        PLEASE DO RESUME .10
(1803)  DO (1999) NEXT
(1801)  DO FORGET #1
        DO RETRIEVE :14 :13 .10
        PLEASE DO RESUME #1
(1802)  DO FORGET #1
        DO RETRIEVE :14 :13 .10
        DO (1803) NEXT

        DON'T NOTE ============================================
        DON'T NOTE Label 1010: 16-bit subtract (wraps)
        DON'T NOTE .3 = .1 - .2
        DON'T NOTE Method: .1 + bitwise_not(.2) + 1
        DON'T NOTE bitwise_not via mingle with 65535, XOR, select even bits
        DON'T NOTE ============================================

(1010)  DO STASH .1 .2 .10
        PLEASE DO STASH :13 :14 :15
        DON'T NOTE Compute ones complement of .2
        DO :13 <- '.2 $ #65535'
        DO :14 <- '?:13'
        PLEASE DO :15 <- '#0 $ #65535'
        DO .10 <- ':14 ~ :15'
        DON'T NOTE Now .10 = bitwise NOT of .2
        DON'T NOTE Add .1 + .10 + 1 = .1 - .2 (mod 65536)
        DO .2 <- .10
        PLEASE DO (1009) NEXT
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO RETRIEVE :15 :14 :13
        PLEASE DO RETRIEVE .10 .2 .1
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
        PLEASE DO .2 <- #0
        DO (666) NEXT
        DO .1 <- .3
        PLEASE DO RETRIEVE .3 .2
        DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1910: random in range via Label 666
        DON'T NOTE .2 = random 0-.1
        DON'T NOTE ============================================

(1910)  DO STASH .3 .10
        DO .10 <- .1
        PLEASE DO .1 <- #9
        DO .2 <- .10
        DO (666) NEXT
        PLEASE DO .2 <- .3
        DO .1 <- .10
        DO RETRIEVE .10 .3
        PLEASE DO RESUME #1


(1525)  DO STASH .1 .2 .4
        PLEASE DO .1 <- .3
        DO .2 <- .3
        DO (1009) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .3
        DO (1009) NEXT
        DO .1 <- .3
        DO .2 <- .3
        DO (1009) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .3
        PLEASE DO (1009) NEXT
        DO .1 <- .3
        DO .2 <- .3
        DO (1009) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .3
        DO (1009) NEXT
        DO .1 <- .3
        DO .2 <- .3
        DO (1009) NEXT
        DO .1 <- .3
        DO .2 <- .3
        PLEASE DO (1009) NEXT
        DO RETRIEVE .4 .2 .1
        DO RESUME #1


(1039)  DO STASH .1 .2
        PLEASE DO STASH .60 .61 .62 .63 .64 .65 .66 .67
        DO STASH .68 .69 .70
        DO STASH :13 :14
        DO .60 <- #0
        PLEASE DO .61 <- #0
        DO .62 <- .1
        DO .63 <- #0
        DO .69 <- .2

        PLEASE DO .64 <- '.69 ~ #1'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #2'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #4'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        DO .64 <- '.69 ~ #8'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #16'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #32'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #64'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        DO .64 <- '.69 ~ #128'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #256'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #512'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #1024'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        DO .64 <- '.69 ~ #2048'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #4096'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #8192'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #16384'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        DO .64 <- '.69 ~ #32768'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3

        DO .3 <- .60
        PLEASE DO .70 <- '.61 ~ .61'
        DO .70 <- '.70 ~ #1'
        DO :13 <- '.70 $ #1'
        DO :14 <- '?:13'
        PLEASE DO .4 <- ':14 ~ #3'

        DO RETRIEVE :14 :13
        DO RETRIEVE .70 .69 .68
        DO RETRIEVE .67 .66 .65 .64 .63 .62 .61 .60
        PLEASE DO RETRIEVE .2 .1
        DO RESUME #1


(1030)  DO (1039) NEXT
        DO .4 <- '.4 ~ #1'
        DO RESUME .4


(1040)  DO STASH .1 .2
        DO STASH .60 .61 .62 .63 .64 .65 .66 .67
        DO STASH .68 .69 .70
        PLEASE DO STASH :13 :14
        DO .60 <- #0
        DO .61 <- #0
        DO .62 <- .2
        PLEASE DO .63 <- .1
        DO .66 <- '.62 ~ .62'
        DO .66 <- '.66 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .66
        DO (1010) NEXT
        DO .66 <- .3

        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #32768'
        DO .1 <- .61
        DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .64 <- '.63 ~ #16384'
        DO .1 <- .61
        DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #8192'
        DO .1 <- .61
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #4096'
        DO .1 <- .61
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #2048'
        DO .1 <- .61
        DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .64 <- '.63 ~ #1024'
        DO .1 <- .61
        DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #512'
        DO .1 <- .61
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #256'
        DO .1 <- .61
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #128'
        DO .1 <- .61
        DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .64 <- '.63 ~ #64'
        DO .1 <- .61
        DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #32'
        DO .1 <- .61
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #16'
        DO .1 <- .61
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .60
        DO .2 <- .60
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #8'
        DO .1 <- .61
        DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .64 <- '.63 ~ #4'
        DO .1 <- .61
        DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #2'
        DO .1 <- .61
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .61 <- .3

        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .64 <- '.63 ~ #1'
        DO .1 <- .61
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .60
        DO .2 <- .60
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .61
        DO .2 <- .69
        DO (1010) NEXT
        DO .61 <- .3

        DO .3 <- '.60 ~ .66'

        PLEASE DO RETRIEVE :14 :13
        DO RETRIEVE .70 .69 .68
        DO RETRIEVE .67 .66 .65 .64 .63 .62 .61 .60
        DO RETRIEVE .2 .1
        PLEASE DO RESUME #1


(1050)  DO STASH .1 .3 .4
        DO STASH .60 .61 .62 .63 .64 .65 .66 .67
        DO STASH .68 .69 .70 .71
        PLEASE DO STASH :10 :13 :14
        DO .60 <- #0
        DO .61 <- #0
        DO .62 <- #0
        DO .63 <- .1
        PLEASE DO .66 <- '.63 ~ .63'
        DO .66 <- '.66 ~ #1'
        DO .1 <- #0
        DO .2 <- .66
        DO (1010) NEXT
        PLEASE DO .66 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#32768 $ #0'
        DO .64 <- ':1 ~ :10'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        PLEASE DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#0 $ #32768'
        DO .64 <- ':1 ~ :10'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#16384 $ #0'
        DO .64 <- ':1 ~ :10'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#0 $ #16384'
        DO .64 <- ':1 ~ :10'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#8192 $ #0'
        DO .64 <- ':1 ~ :10'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#0 $ #8192'
        DO .64 <- ':1 ~ :10'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#4096 $ #0'
        DO .64 <- ':1 ~ :10'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#0 $ #4096'
        DO .64 <- ':1 ~ :10'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO :10 <- '#2048 $ #0'
        DO .64 <- ':1 ~ :10'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#0 $ #2048'
        DO .64 <- ':1 ~ :10'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#1024 $ #0'
        DO .64 <- ':1 ~ :10'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#0 $ #1024'
        DO .64 <- ':1 ~ :10'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#512 $ #0'
        DO .64 <- ':1 ~ :10'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#0 $ #512'
        DO .64 <- ':1 ~ :10'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO :10 <- '#256 $ #0'
        DO .64 <- ':1 ~ :10'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO :10 <- '#0 $ #256'
        DO .64 <- ':1 ~ :10'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .64 <- ':1 ~ #32768'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .64 <- ':1 ~ #16384'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        PLEASE DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .64 <- ':1 ~ #8192'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        DO .62 <- .3
        DO .1 <- .60
        PLEASE DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO .64 <- ':1 ~ #4096'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .64 <- ':1 ~ #2048'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO .64 <- ':1 ~ #1024'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        PLEASE DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .64 <- ':1 ~ #512'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        DO .62 <- .3
        DO .1 <- .60
        PLEASE DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO .64 <- ':1 ~ #256'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .64 <- ':1 ~ #128'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO .64 <- ':1 ~ #64'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        PLEASE DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .64 <- ':1 ~ #32'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        PLEASE DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO .64 <- ':1 ~ #16'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .64 <- ':1 ~ #8'
        PLEASE DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO .64 <- ':1 ~ #4'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        PLEASE DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        PLEASE DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .62 <- .3

        DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO .64 <- ':1 ~ #2'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        PLEASE DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .1 <- .62
        PLEASE DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        PLEASE DO .64 <- ':1 ~ #1'
        DO .1 <- .62
        DO .2 <- .64
        DO (1009) NEXT
        PLEASE DO .62 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .68 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .67 <- ':14 ~ :13'
        DO .1 <- .62
        DO .2 <- .67
        DO (1009) NEXT
        PLEASE DO .68 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .69 <- '.4 ~ #2'
        DO :13 <- '.68 $ .69'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .62
        DO .2 <- .69
        DO (1010) NEXT
        DO .62 <- .3

        DO .65 <- '.60 ~ .66'
        PLEASE DO .71 <- '.61 ~ .61'
        DO .71 <- '.71 ~ #1'
        DO :13 <- '.71 $ .66'
        DO :14 <- '&:13'
        PLEASE DO .71 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .71
        DO (1010) NEXT
        DO .5 <- .65
        PLEASE DO .6 <- .3

        DO RETRIEVE :14 :13 :10
        DO RETRIEVE .71 .70 .69 .68
        DO RETRIEVE .67 .66 .65 .64 .63 .62 .61 .60
        PLEASE DO RETRIEVE .4 .3 .1
        DO .2 <- .5
        DO RESUME .6


(1509)  DO STASH .1 .2 .3 .4
        PLEASE DO STASH .60 .61 .62 .63 .64 .65 .66 .67
        DO STASH :10
        DO STASH .100 .101 .102 .103 .104 .105 .106 .107
        DO STASH .108 .109 .110 .111 .112 .113 .114 .115
        PLEASE DO STASH .116 .117 .118 .119 .120 .121 .122 .123
        DO STASH .124 .125 .126 .127 .128 .129 .130 .131
        DO STASH .132 .133 .134 .135 .136 .137 .138 .139
        DO STASH .140 .141 .142 .143 .144 .145 .146 .147
        DO STASH .148 .149 .150 .151 .152 .153 .154 .155
        DO STASH .156 .157 .158 .159 .160 .161
        PLEASE DO STASH :12
        DO .60 <- ':1 ~ #65535'
        DO .61 <- ':2 ~ #65535'
        DO :10 <- '#65280 $ #65280'
        PLEASE DO .62 <- ':1 ~ :10'
        DO .63 <- ':2 ~ :10'
        DO .1 <- .60
        DO .2 <- .61
        DO (1009) NEXT
        PLEASE DO .64 <- .3
        DO .65 <- '.4 ~ #2'
        DO .1 <- .62
        DO .2 <- .65
        DO (1009) NEXT
        PLEASE DO .66 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- .63
        DO (1009) NEXT
        DO .67 <- '.4 ~ #2'
        PLEASE DO .3 <- .3
        DO .65 <- .3
        PLEASE DO :10 <- '.66 $ .67'
        DO :10 <- 'V:10'
        DO .66 <- ':10 ~ #1'
        DO .100 <- '.64 ~ #1'
        PLEASE DO .101 <- '.64 ~ #2'
        DO .102 <- '.64 ~ #4'
        DO .103 <- '.64 ~ #8'
        DO .104 <- '.64 ~ #16'
        PLEASE DO .105 <- '.64 ~ #32'
        DO .106 <- '.64 ~ #64'
        DO .107 <- '.64 ~ #128'
        DO .108 <- '.64 ~ #256'
        PLEASE DO .109 <- '.64 ~ #512'
        DO .110 <- '.64 ~ #1024'
        DO .111 <- '.64 ~ #2048'
        DO .112 <- '.64 ~ #4096'
        PLEASE DO .113 <- '.64 ~ #8192'
        DO .114 <- '.64 ~ #16384'
        DO .115 <- '.64 ~ #32768'
        DO .116 <- '.65 ~ #1'
        PLEASE DO .117 <- '.65 ~ #2'
        DO .118 <- '.65 ~ #4'
        DO .119 <- '.65 ~ #8'
        DO .120 <- '.65 ~ #16'
        PLEASE DO .121 <- '.65 ~ #32'
        DO .122 <- '.65 ~ #64'
        DO .123 <- '.65 ~ #128'
        DO .124 <- '.65 ~ #256'
        PLEASE DO .125 <- '.65 ~ #512'
        DO .126 <- '.65 ~ #1024'
        DO .127 <- '.65 ~ #2048'
        DO .128 <- '.65 ~ #4096'
        PLEASE DO .129 <- '.65 ~ #8192'
        DO .130 <- '.65 ~ #16384'
        DO .131 <- '.65 ~ #32768'
        DO :12 <- '.116 $ .100'
        DO .132 <- ':12 ~ #3'
        DO :12 <- '.124 $ .108'
        DO .133 <- ':12 ~ #3'
        DO :12 <- '.120 $ .104'
        DO .134 <- ':12 ~ #3'
        DO :12 <- '.128 $ .112'
        DO .135 <- ':12 ~ #3'
        PLEASE DO :12 <- '.118 $ .102'
        DO .136 <- ':12 ~ #3'
        DO :12 <- '.126 $ .110'
        DO .137 <- ':12 ~ #3'
        PLEASE DO :12 <- '.122 $ .106'
        DO .138 <- ':12 ~ #3'
        DO :12 <- '.130 $ .114'
        DO .139 <- ':12 ~ #3'
        PLEASE DO :12 <- '.117 $ .101'
        DO .140 <- ':12 ~ #3'
        DO :12 <- '.125 $ .109'
        DO .141 <- ':12 ~ #3'
        PLEASE DO :12 <- '.121 $ .105'
        DO .142 <- ':12 ~ #3'
        DO :12 <- '.129 $ .113'
        DO .143 <- ':12 ~ #3'
        DO :12 <- '.119 $ .103'
        DO .144 <- ':12 ~ #3'
        PLEASE DO :12 <- '.127 $ .111'
        DO .145 <- ':12 ~ #3'
        DO :12 <- '.123 $ .107'
        DO .146 <- ':12 ~ #3'
        PLEASE DO :12 <- '.131 $ .115'
        DO .147 <- ':12 ~ #3'
        DO :12 <- '.133 $ .132'
        DO .148 <- ':12 ~ #15'
        PLEASE DO :12 <- '.135 $ .134'
        DO .149 <- ':12 ~ #15'
        DO :12 <- '.137 $ .136'
        DO .150 <- ':12 ~ #15'
        PLEASE DO :12 <- '.139 $ .138'
        DO .151 <- ':12 ~ #15'
        DO :12 <- '.141 $ .140'
        DO .152 <- ':12 ~ #15'
        DO :12 <- '.143 $ .142'
        DO .153 <- ':12 ~ #15'
        PLEASE DO :12 <- '.145 $ .144'
        DO .154 <- ':12 ~ #15'
        DO :12 <- '.147 $ .146'
        DO .155 <- ':12 ~ #15'
        PLEASE DO :12 <- '.149 $ .148'
        DO .156 <- ':12 ~ #255'
        DO :12 <- '.151 $ .150'
        DO .157 <- ':12 ~ #255'
        PLEASE DO :12 <- '.153 $ .152'
        DO .158 <- ':12 ~ #255'
        DO :12 <- '.155 $ .154'
        DO .159 <- ':12 ~ #255'
        DO :12 <- '.157 $ .156'
        DO .160 <- ':12 ~ #65535'
        PLEASE DO :12 <- '.159 $ .158'
        DO .161 <- ':12 ~ #65535'
        DO :3 <- '.161 $ .160'
        DO :10 <- '.66 $ #1'
        PLEASE DO :10 <- '?:10'
        DO :4 <- ':10 ~ #3'

        DO RETRIEVE :12
        DO RETRIEVE .161 .160 .159 .158 .157 .156
        PLEASE DO RETRIEVE .155 .154 .153 .152 .151 .150 .149 .148
        DO RETRIEVE .147 .146 .145 .144 .143 .142 .141 .140
        DO RETRIEVE .139 .138 .137 .136 .135 .134 .133 .132
        DO RETRIEVE .131 .130 .129 .128 .127 .126 .125 .124
        PLEASE DO RETRIEVE .123 .122 .121 .120 .119 .118 .117 .116
        DO RETRIEVE .115 .114 .113 .112 .111 .110 .109 .108
        DO RETRIEVE .107 .106 .105 .104 .103 .102 .101 .100
        DO RETRIEVE :10
        DO RETRIEVE .67 .66 .65 .64 .63 .62 .61 .60
        DO RETRIEVE .4 .3 .2 .1
        PLEASE DO RESUME #1


(1500)  DO (1509) NEXT
        DO .1 <- ':4 ~ #1'
        DO RESUME .1


(1510)  DO STASH .1 .2 .3 .4
        PLEASE DO STASH .60 .61 .62 .63 .64 .65 .66
        DO STASH :10 :11
        DO STASH .100 .101 .102 .103 .104 .105 .106 .107
        DO STASH .108 .109 .110 .111 .112 .113 .114 .115
        PLEASE DO STASH .116 .117 .118 .119 .120 .121 .122 .123
        DO STASH .124 .125 .126 .127 .128 .129 .130 .131
        DO STASH .132 .133 .134 .135 .136 .137 .138 .139
        DO STASH .140 .141 .142 .143 .144 .145 .146 .147
        PLEASE DO STASH .148 .149 .150 .151 .152 .153 .154 .155
        DO STASH .156 .157 .158 .159 .160 .161
        DO STASH :12
        DO .60 <- ':1 ~ #65535'
        PLEASE DO .61 <- ':2 ~ #65535'
        DO :10 <- '#65280 $ #65280'
        DO .62 <- ':1 ~ :10'
        DO .63 <- ':2 ~ :10'
        PLEASE DO .1 <- .60
        DO .2 <- .61
        DO (1010) NEXT
        DO .64 <- .3
        DO :10 <- '.61 $ #65535'
        PLEASE DO :11 <- '?:10'
        DO :10 <- '#0 $ #65535'
        DO .66 <- ':11 ~ :10'
        DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .65 <- '.4 ~ #2'
        PLEASE DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        PLEASE DO .66 <- '.4 ~ #2'
        DO :10 <- '.65 $ .66'
        DO :10 <- 'V:10'
        DO .65 <- ':10 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .65
        DO (1010) NEXT
        DO .65 <- .3
        DO .1 <- .62
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .65
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .100 <- '.64 ~ #1'
        DO .101 <- '.64 ~ #2'
        PLEASE DO .102 <- '.64 ~ #4'
        DO .103 <- '.64 ~ #8'
        DO .104 <- '.64 ~ #16'
        DO .105 <- '.64 ~ #32'
        PLEASE DO .106 <- '.64 ~ #64'
        DO .107 <- '.64 ~ #128'
        DO .108 <- '.64 ~ #256'
        DO .109 <- '.64 ~ #512'
        PLEASE DO .110 <- '.64 ~ #1024'
        DO .111 <- '.64 ~ #2048'
        DO .112 <- '.64 ~ #4096'
        DO .113 <- '.64 ~ #8192'
        PLEASE DO .114 <- '.64 ~ #16384'
        DO .115 <- '.64 ~ #32768'
        DO .116 <- '.65 ~ #1'
        DO .117 <- '.65 ~ #2'
        PLEASE DO .118 <- '.65 ~ #4'
        DO .119 <- '.65 ~ #8'
        DO .120 <- '.65 ~ #16'
        DO .121 <- '.65 ~ #32'
        PLEASE DO .122 <- '.65 ~ #64'
        DO .123 <- '.65 ~ #128'
        DO .124 <- '.65 ~ #256'
        DO .125 <- '.65 ~ #512'
        PLEASE DO .126 <- '.65 ~ #1024'
        DO .127 <- '.65 ~ #2048'
        DO .128 <- '.65 ~ #4096'
        DO .129 <- '.65 ~ #8192'
        PLEASE DO .130 <- '.65 ~ #16384'
        DO .131 <- '.65 ~ #32768'
        DO :12 <- '.116 $ .100'
        DO .132 <- ':12 ~ #3'
        PLEASE DO :12 <- '.124 $ .108'
        DO .133 <- ':12 ~ #3'
        DO :12 <- '.120 $ .104'
        DO .134 <- ':12 ~ #3'
        PLEASE DO :12 <- '.128 $ .112'
        DO .135 <- ':12 ~ #3'
        DO :12 <- '.118 $ .102'
        DO .136 <- ':12 ~ #3'
        PLEASE DO :12 <- '.126 $ .110'
        DO .137 <- ':12 ~ #3'
        DO :12 <- '.122 $ .106'
        DO .138 <- ':12 ~ #3'
        PLEASE DO :12 <- '.130 $ .114'
        DO .139 <- ':12 ~ #3'
        DO :12 <- '.117 $ .101'
        DO .140 <- ':12 ~ #3'
        PLEASE DO :12 <- '.125 $ .109'
        DO .141 <- ':12 ~ #3'
        DO :12 <- '.121 $ .105'
        DO .142 <- ':12 ~ #3'
        PLEASE DO :12 <- '.129 $ .113'
        DO .143 <- ':12 ~ #3'
        DO :12 <- '.119 $ .103'
        DO .144 <- ':12 ~ #3'
        PLEASE DO :12 <- '.127 $ .111'
        DO .145 <- ':12 ~ #3'
        DO :12 <- '.123 $ .107'
        DO .146 <- ':12 ~ #3'
        PLEASE DO :12 <- '.131 $ .115'
        DO .147 <- ':12 ~ #3'
        DO :12 <- '.133 $ .132'
        DO .148 <- ':12 ~ #15'
        PLEASE DO :12 <- '.135 $ .134'
        DO .149 <- ':12 ~ #15'
        DO :12 <- '.137 $ .136'
        DO .150 <- ':12 ~ #15'
        PLEASE DO :12 <- '.139 $ .138'
        DO .151 <- ':12 ~ #15'
        DO :12 <- '.141 $ .140'
        DO .152 <- ':12 ~ #15'
        PLEASE DO :12 <- '.143 $ .142'
        DO .153 <- ':12 ~ #15'
        DO :12 <- '.145 $ .144'
        DO .154 <- ':12 ~ #15'
        PLEASE DO :12 <- '.147 $ .146'
        DO .155 <- ':12 ~ #15'
        DO :12 <- '.149 $ .148'
        DO .156 <- ':12 ~ #255'
        PLEASE DO :12 <- '.151 $ .150'
        DO .157 <- ':12 ~ #255'
        DO :12 <- '.153 $ .152'
        DO .158 <- ':12 ~ #255'
        PLEASE DO :12 <- '.155 $ .154'
        DO .159 <- ':12 ~ #255'
        DO :12 <- '.157 $ .156'
        DO .160 <- ':12 ~ #65535'
        PLEASE DO :12 <- '.159 $ .158'
        DO .161 <- ':12 ~ #65535'
        DO :3 <- '.161 $ .160'

        DO RETRIEVE :12
        DO RETRIEVE .161 .160 .159 .158 .157 .156
        DO RETRIEVE .155 .154 .153 .152 .151 .150 .149 .148
        DO RETRIEVE .147 .146 .145 .144 .143 .142 .141 .140
        DO RETRIEVE .139 .138 .137 .136 .135 .134 .133 .132
        DO RETRIEVE .131 .130 .129 .128 .127 .126 .125 .124
        DO RETRIEVE .123 .122 .121 .120 .119 .118 .117 .116
        DO RETRIEVE .115 .114 .113 .112 .111 .110 .109 .108
        DO RETRIEVE .107 .106 .105 .104 .103 .102 .101 .100
        DO RETRIEVE :11 :10
        DO RETRIEVE .66 .65 .64 .63 .62 .61 .60
        DO RETRIEVE .4 .3 .2 .1
        DO RESUME #1


(1530)  DO STASH .1 .2 .3 .4
        PLEASE DO STASH .60 .61 .62 .63 .64 .65 .66 .67
        DO STASH .68 .69
        DO STASH .100 .101 .102 .103 .104 .105 .106 .107
        DO STASH .108 .109 .110 .111 .112 .113 .114 .115
        PLEASE DO STASH .116 .117 .118 .119 .120 .121 .122 .123
        DO STASH .124 .125 .126 .127 .128 .129 .130 .131
        DO STASH .132 .133 .134 .135 .136 .137 .138 .139
        DO STASH .140 .141 .142 .143 .144 .145 .146 .147
        DO STASH .148 .149 .150 .151 .152 .153 .154 .155
        DO STASH .156 .157 .158 .159 .160 .161
        PLEASE DO STASH :12
        DO .60 <- #0
        DO .61 <- #0
        DO .62 <- .1
        DO .63 <- #0
        PLEASE DO .69 <- .2

        DO .64 <- '.69 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        DO .64 <- '.69 ~ #2'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #4'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #8'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #16'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        DO .64 <- '.69 ~ #32'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #64'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #128'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #256'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        DO .64 <- '.69 ~ #512'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #1024'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #2048'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #4096'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        PLEASE DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #8192'
        DO .1 <- #0
        PLEASE DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        DO .64 <- '.69 ~ #16384'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        PLEASE DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        DO .1 <- .60
        DO .2 <- .66
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .62
        DO .2 <- .62
        PLEASE DO (1009) NEXT
        DO .62 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .63
        DO .2 <- .63
        DO (1009) NEXT
        DO .63 <- .3
        DO .1 <- .63
        DO .2 <- .68
        DO (1009) NEXT
        PLEASE DO .63 <- .3

        PLEASE DO .64 <- '.69 ~ #32768'
        DO .1 <- #0
        DO .2 <- .64
        DO (1010) NEXT
        DO .65 <- .3
        DO .66 <- '.62 ~ .65'
        DO .67 <- '.63 ~ .65'
        PLEASE DO .1 <- .60
        DO .2 <- .66
        DO (1009) NEXT
        DO .60 <- .3
        DO .68 <- '.4 ~ #2'
        PLEASE DO .1 <- .61
        DO .2 <- .68
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .67
        DO (1009) NEXT
        DO .61 <- .3

        PLEASE DO .100 <- '.60 ~ #1'
        DO .101 <- '.60 ~ #2'
        DO .102 <- '.60 ~ #4'
        DO .103 <- '.60 ~ #8'
        PLEASE DO .104 <- '.60 ~ #16'
        DO .105 <- '.60 ~ #32'
        DO .106 <- '.60 ~ #64'
        DO .107 <- '.60 ~ #128'
        PLEASE DO .108 <- '.60 ~ #256'
        DO .109 <- '.60 ~ #512'
        DO .110 <- '.60 ~ #1024'
        DO .111 <- '.60 ~ #2048'
        PLEASE DO .112 <- '.60 ~ #4096'
        DO .113 <- '.60 ~ #8192'
        DO .114 <- '.60 ~ #16384'
        DO .115 <- '.60 ~ #32768'
        PLEASE DO .116 <- '.61 ~ #1'
        DO .117 <- '.61 ~ #2'
        DO .118 <- '.61 ~ #4'
        DO .119 <- '.61 ~ #8'
        PLEASE DO .120 <- '.61 ~ #16'
        DO .121 <- '.61 ~ #32'
        DO .122 <- '.61 ~ #64'
        DO .123 <- '.61 ~ #128'
        PLEASE DO .124 <- '.61 ~ #256'
        DO .125 <- '.61 ~ #512'
        DO .126 <- '.61 ~ #1024'
        DO .127 <- '.61 ~ #2048'
        PLEASE DO .128 <- '.61 ~ #4096'
        DO .129 <- '.61 ~ #8192'
        DO .130 <- '.61 ~ #16384'
        DO .131 <- '.61 ~ #32768'
        PLEASE DO :12 <- '.116 $ .100'
        DO .132 <- ':12 ~ #3'
        DO :12 <- '.124 $ .108'
        DO .133 <- ':12 ~ #3'
        PLEASE DO :12 <- '.120 $ .104'
        DO .134 <- ':12 ~ #3'
        DO :12 <- '.128 $ .112'
        DO .135 <- ':12 ~ #3'
        PLEASE DO :12 <- '.118 $ .102'
        DO .136 <- ':12 ~ #3'
        DO :12 <- '.126 $ .110'
        DO .137 <- ':12 ~ #3'
        PLEASE DO :12 <- '.122 $ .106'
        DO .138 <- ':12 ~ #3'
        DO :12 <- '.130 $ .114'
        DO .139 <- ':12 ~ #3'
        PLEASE DO :12 <- '.117 $ .101'
        DO .140 <- ':12 ~ #3'
        DO :12 <- '.125 $ .109'
        DO .141 <- ':12 ~ #3'
        PLEASE DO :12 <- '.121 $ .105'
        DO .142 <- ':12 ~ #3'
        DO :12 <- '.129 $ .113'
        DO .143 <- ':12 ~ #3'
        PLEASE DO :12 <- '.119 $ .103'
        DO .144 <- ':12 ~ #3'
        DO :12 <- '.127 $ .111'
        DO .145 <- ':12 ~ #3'
        PLEASE DO :12 <- '.123 $ .107'
        DO .146 <- ':12 ~ #3'
        DO :12 <- '.131 $ .115'
        DO .147 <- ':12 ~ #3'
        PLEASE DO :12 <- '.133 $ .132'
        DO .148 <- ':12 ~ #15'
        DO :12 <- '.135 $ .134'
        DO .149 <- ':12 ~ #15'
        PLEASE DO :12 <- '.137 $ .136'
        DO .150 <- ':12 ~ #15'
        DO :12 <- '.139 $ .138'
        DO .151 <- ':12 ~ #15'
        PLEASE DO :12 <- '.141 $ .140'
        DO .152 <- ':12 ~ #15'
        DO :12 <- '.143 $ .142'
        DO .153 <- ':12 ~ #15'
        PLEASE DO :12 <- '.145 $ .144'
        DO .154 <- ':12 ~ #15'
        DO :12 <- '.147 $ .146'
        DO .155 <- ':12 ~ #15'
        PLEASE DO :12 <- '.149 $ .148'
        DO .156 <- ':12 ~ #255'
        DO :12 <- '.151 $ .150'
        DO .157 <- ':12 ~ #255'
        PLEASE DO :12 <- '.153 $ .152'
        DO .158 <- ':12 ~ #255'
        DO :12 <- '.155 $ .154'
        DO .159 <- ':12 ~ #255'
        PLEASE DO :12 <- '.157 $ .156'
        DO .160 <- ':12 ~ #65535'
        DO :12 <- '.159 $ .158'
        DO .161 <- ':12 ~ #65535'
        PLEASE DO :1 <- '.161 $ .160'

        DO RETRIEVE :12
        DO RETRIEVE .161 .160 .159 .158 .157 .156
        DO RETRIEVE .155 .154 .153 .152 .151 .150 .149 .148
        DO RETRIEVE .147 .146 .145 .144 .143 .142 .141 .140
        DO RETRIEVE .139 .138 .137 .136 .135 .134 .133 .132
        DO RETRIEVE .131 .130 .129 .128 .127 .126 .125 .124
        DO RETRIEVE .123 .122 .121 .120 .119 .118 .117 .116
        DO RETRIEVE .115 .114 .113 .112 .111 .110 .109 .108
        DO RETRIEVE .107 .106 .105 .104 .103 .102 .101 .100
        DO RETRIEVE .69 .68
        DO RETRIEVE .67 .66 .65 .64 .63 .62 .61 .60
        DO RETRIEVE .4 .3 .2 .1
        DO RESUME #1


(1549)  DO STASH .1 .2 .3 .4
        DO STASH .60 .61 .62 .63 .64 .65 .66 .67
        DO STASH .68 .69 .70 .71 .72 .73 .74
        DO STASH :10
        PLEASE DO STASH .100 .101 .102 .103 .104 .105 .106 .107
        DO STASH .108 .109 .110 .111 .112 .113 .114 .115
        PLEASE DO STASH .116 .117 .118 .119 .120 .121 .122 .123
        DO STASH .124 .125 .126 .127 .128 .129 .130 .131
        DO STASH .132 .133 .134 .135 .136 .137 .138 .139
        DO STASH .140 .141 .142 .143 .144 .145 .146 .147
        PLEASE DO STASH .148 .149 .150 .151 .152 .153 .154 .155
        DO STASH .156 .157 .158 .159 .160 .161
        DO STASH :12
        DO :10 <- '#65280 $ #65280'
        PLEASE DO .60 <- ':1 ~ #65535'
        DO .61 <- ':1 ~ :10'
        DO .62 <- ':2 ~ #65535'
        DO .63 <- ':2 ~ :10'
        DO .74 <- #0
        DO .64 <- '.61 ~ .61'
        DO .64 <- '.64 ~ #1'
        DO .65 <- '.63 ~ .63'
        DO .65 <- '.65 ~ #1'
        DO :10 <- '.64 $ .65'
        PLEASE DO :10 <- '&:10'
        DO .64 <- ':10 ~ #1'
        DO :10 <- '.74 $ .64'
        PLEASE DO :10 <- 'V:10'
        DO .74 <- ':10 ~ #1'
        DO .1 <- .60
        PLEASE DO .2 <- .62
        DO (1530) NEXT
        DO .66 <- ':1 ~ #65535'
        DO :10 <- '#65280 $ #65280'
        DO .67 <- ':1 ~ :10'
        DO .1 <- .61
        PLEASE DO .2 <- .62
        DO (1530) NEXT
        DO .68 <- ':1 ~ #65535'
        DO :10 <- '#65280 $ #65280'
        DO .69 <- ':1 ~ :10'
        DO .1 <- .60
        PLEASE DO .2 <- .63
        DO (1530) NEXT
        DO .70 <- ':1 ~ #65535'
        PLEASE DO :10 <- '#65280 $ #65280'
        DO .71 <- ':1 ~ :10'
        DO .1 <- .68
        DO .2 <- .70
        DO (1009) NEXT
        DO .72 <- .3
        PLEASE DO .73 <- '.4 ~ #2'
        DO .1 <- .69
        DO .2 <- .71
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .65 <- '.4 ~ #2'
        DO .1 <- .64
        DO .2 <- .73
        PLEASE DO (1009) NEXT
        DO .64 <- .3
        DO .65 <- '.4 ~ #2'
        PLEASE DO .65 <- '.64 ~ .64'
        DO .65 <- '.65 ~ #1'
        DO :10 <- '.74 $ .65'
        DO :10 <- 'V:10'
        PLEASE DO .74 <- ':10 ~ #1'
        DO .1 <- .67
        DO .2 <- .72
        DO (1009) NEXT
        DO .65 <- .3
        DO .64 <- '.4 ~ #2'
        DO :10 <- '.74 $ .64'
        PLEASE DO :10 <- 'V:10'
        DO .74 <- ':10 ~ #1'
        DO .100 <- '.66 ~ #1'
        DO .101 <- '.66 ~ #2'
        PLEASE DO .102 <- '.66 ~ #4'
        PLEASE DO .103 <- '.66 ~ #8'
        DO .104 <- '.66 ~ #16'
        DO .105 <- '.66 ~ #32'
        DO .106 <- '.66 ~ #64'
        PLEASE DO .107 <- '.66 ~ #128'
        DO .108 <- '.66 ~ #256'
        DO .109 <- '.66 ~ #512'
        DO .110 <- '.66 ~ #1024'
        PLEASE DO .111 <- '.66 ~ #2048'
        DO .112 <- '.66 ~ #4096'
        DO .113 <- '.66 ~ #8192'
        DO .114 <- '.66 ~ #16384'
        PLEASE DO .115 <- '.66 ~ #32768'
        DO .116 <- '.65 ~ #1'
        DO .117 <- '.65 ~ #2'
        DO .118 <- '.65 ~ #4'
        PLEASE DO .119 <- '.65 ~ #8'
        DO .120 <- '.65 ~ #16'
        DO .121 <- '.65 ~ #32'
        DO .122 <- '.65 ~ #64'
        PLEASE DO .123 <- '.65 ~ #128'
        DO .124 <- '.65 ~ #256'
        DO .125 <- '.65 ~ #512'
        DO .126 <- '.65 ~ #1024'
        PLEASE DO .127 <- '.65 ~ #2048'
        DO .128 <- '.65 ~ #4096'
        DO .129 <- '.65 ~ #8192'
        DO .130 <- '.65 ~ #16384'
        PLEASE DO .131 <- '.65 ~ #32768'
        DO :12 <- '.116 $ .100'
        DO .132 <- ':12 ~ #3'
        DO :12 <- '.124 $ .108'
        DO .133 <- ':12 ~ #3'
        DO :12 <- '.120 $ .104'
        DO .134 <- ':12 ~ #3'
        DO :12 <- '.128 $ .112'
        DO .135 <- ':12 ~ #3'
        DO :12 <- '.118 $ .102'
        DO .136 <- ':12 ~ #3'
        PLEASE DO :12 <- '.126 $ .110'
        DO .137 <- ':12 ~ #3'
        DO :12 <- '.122 $ .106'
        DO .138 <- ':12 ~ #3'
        DO :12 <- '.130 $ .114'
        DO .139 <- ':12 ~ #3'
        PLEASE DO :12 <- '.117 $ .101'
        DO .140 <- ':12 ~ #3'
        DO :12 <- '.125 $ .109'
        DO .141 <- ':12 ~ #3'
        PLEASE DO :12 <- '.121 $ .105'
        DO .142 <- ':12 ~ #3'
        DO :12 <- '.129 $ .113'
        DO .143 <- ':12 ~ #3'
        PLEASE DO :12 <- '.119 $ .103'
        DO .144 <- ':12 ~ #3'
        DO :12 <- '.127 $ .111'
        DO .145 <- ':12 ~ #3'
        DO :12 <- '.123 $ .107'
        DO .146 <- ':12 ~ #3'
        PLEASE DO :12 <- '.131 $ .115'
        DO .147 <- ':12 ~ #3'
        DO :12 <- '.133 $ .132'
        DO .148 <- ':12 ~ #15'
        PLEASE DO :12 <- '.135 $ .134'
        DO .149 <- ':12 ~ #15'
        DO :12 <- '.137 $ .136'
        DO .150 <- ':12 ~ #15'
        PLEASE DO :12 <- '.139 $ .138'
        DO .151 <- ':12 ~ #15'
        DO :12 <- '.141 $ .140'
        DO .152 <- ':12 ~ #15'
        PLEASE DO :12 <- '.143 $ .142'
        DO .153 <- ':12 ~ #15'
        DO :12 <- '.145 $ .144'
        DO .154 <- ':12 ~ #15'
        DO :12 <- '.147 $ .146'
        DO .155 <- ':12 ~ #15'
        PLEASE DO :12 <- '.149 $ .148'
        DO .156 <- ':12 ~ #255'
        DO :12 <- '.151 $ .150'
        DO .157 <- ':12 ~ #255'
        PLEASE DO :12 <- '.153 $ .152'
        DO .158 <- ':12 ~ #255'
        DO :12 <- '.155 $ .154'
        DO .159 <- ':12 ~ #255'
        PLEASE DO :12 <- '.157 $ .156'
        DO .160 <- ':12 ~ #65535'
        DO :12 <- '.159 $ .158'
        DO .161 <- ':12 ~ #65535'
        PLEASE DO :3 <- '.161 $ .160'
        DO :10 <- '.74 $ #1'
        DO :10 <- '?:10'
        DO :4 <- ':10 ~ #3'

        DO RETRIEVE :12
        DO RETRIEVE .161 .160 .159 .158 .157 .156
        PLEASE DO RETRIEVE .155 .154 .153 .152 .151 .150 .149 .148
        DO RETRIEVE .147 .146 .145 .144 .143 .142 .141 .140
        DO RETRIEVE .139 .138 .137 .136 .135 .134 .133 .132
        DO RETRIEVE .131 .130 .129 .128 .127 .126 .125 .124
        PLEASE DO RETRIEVE .123 .122 .121 .120 .119 .118 .117 .116
        DO RETRIEVE .115 .114 .113 .112 .111 .110 .109 .108
        DO RETRIEVE .107 .106 .105 .104 .103 .102 .101 .100
        DO RETRIEVE :10
        PLEASE DO RETRIEVE .74 .73 .72 .71 .70 .69 .68
        DO RETRIEVE .67 .66 .65 .64 .63 .62 .61 .60
        DO RETRIEVE .4 .3 .2 .1
        DO RESUME #1


(1540)  DO (1549) NEXT
        PLEASE DO .1 <- ':4 ~ #1'
        DO RESUME .1


(1550)  DO STASH .1 .2 .3 .4
        DO STASH .60 .61 .62 .63 .64 .65 .66 .67
        DO STASH .68 .69 .70 .71 .72 .73 .74 .75
        PLEASE DO STASH .76 .77 .78 .79 .80 .81
        DO STASH :10 :11 :13 :14
        DO STASH .100 .101 .102 .103 .104 .105 .106 .107
        DO STASH .108 .109 .110 .111 .112 .113 .114 .115
        PLEASE DO STASH .116 .117 .118 .119 .120 .121 .122 .123
        DO STASH .124 .125 .126 .127 .128 .129 .130 .131
        DO STASH .132 .133 .134 .135 .136 .137 .138 .139
        DO STASH .140 .141 .142 .143 .144 .145 .146 .147
        PLEASE DO STASH .148 .149 .150 .151 .152 .153 .154 .155
        DO STASH .156 .157 .158 .159 .160 .161
        DO STASH :12
        PLEASE DO :10 <- '#65280 $ #65280'
        DO .62 <- ':2 ~ #65535'
        DO .63 <- ':2 ~ :10'
        DO .60 <- #0
        PLEASE DO .61 <- #0
        DO .64 <- #0
        DO .65 <- #0
        DO .66 <- '.62 ~ .62'
        PLEASE DO .66 <- '.66 ~ #1'
        DO .67 <- '.63 ~ .63'
        DO .67 <- '.67 ~ #1'
        DO :10 <- '.66 $ .67'
        DO :10 <- 'V:10'
        DO .76 <- ':10 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .76
        DO (1010) NEXT
        DO .76 <- .3
        DO .77 <- .76

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#32768 $ #0'
        DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#0 $ #32768'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#16384 $ #0'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#0 $ #16384'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#8192 $ #0'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#0 $ #8192'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#4096 $ #0'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#0 $ #4096'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#2048 $ #0'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#0 $ #2048'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#1024 $ #0'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#0 $ #1024'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#512 $ #0'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#0 $ #512'
        DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#256 $ #0'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        DO :10 <- '#0 $ #256'
        PLEASE DO .68 <- ':1 ~ :10'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #32768'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #16384'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #8192'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #4096'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #2048'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #1024'
        DO .1 <- .64
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #512'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #256'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #128'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #64'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #32'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #16'
        DO .1 <- .64
        PLEASE DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        PLEASE DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #8'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        PLEASE DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        PLEASE DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        PLEASE DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        PLEASE DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #4'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        PLEASE DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        PLEASE DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        PLEASE DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #2'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        PLEASE DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        PLEASE DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .1 <- .64
        PLEASE DO .2 <- .64
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .64 <- .3
        DO .1 <- .65
        DO .2 <- .65
        DO (1009) NEXT
        DO .65 <- .3
        DO .1 <- .65
        PLEASE DO .2 <- .78
        DO (1009) NEXT
        DO .65 <- .3
        PLEASE DO .68 <- ':1 ~ #1'
        DO .1 <- .64
        DO .2 <- .68
        DO (1009) NEXT
        DO .64 <- .3
        PLEASE DO .1 <- .60
        DO .2 <- .60
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .60 <- .3
        DO .1 <- .61
        DO .2 <- .61
        DO (1009) NEXT
        DO .61 <- .3
        PLEASE DO .1 <- .61
        DO .2 <- .78
        DO (1009) NEXT
        DO .61 <- .3
        DO :13 <- '.62 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #1
        DO .2 <- .70
        DO (1010) NEXT
        PLEASE DO .71 <- .3
        DO :13 <- '.63 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        PLEASE DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .72 <- ':14 ~ #1'
        PLEASE DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        DO .1 <- .3
        DO .2 <- .71
        DO (1010) NEXT
        DO .73 <- .3
        DO :13 <- '.63 $ #65535'
        PLEASE DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        DO .69 <- ':14 ~ :13'
        PLEASE DO .1 <- .65
        DO .2 <- .69
        DO (1009) NEXT
        DO .78 <- '.4 ~ #2'
        DO .1 <- .3
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .79 <- '.4 ~ #2'
        DO :13 <- '.78 $ .79'
        PLEASE DO :14 <- 'V:13'
        DO .74 <- ':14 ~ #1'
        DO .1 <- .65
        DO .2 <- .63
        DO (1010) NEXT
        PLEASE DO .75 <- '.3 ~ .3'
        DO .75 <- '.75 ~ #1'
        DO .1 <- #1
        DO .2 <- .75
        DO (1010) NEXT
        PLEASE DO .75 <- .3
        DO .1 <- #0
        PLEASE DO .2 <- .75
        DO (1010) NEXT
        DO .78 <- .3
        DO :13 <- '.78 $ #65535'
        DO :14 <- '?:13'
        DO :13 <- '#0 $ #65535'
        PLEASE DO .79 <- ':14 ~ :13'
        DO .80 <- '.70 ~ .78'
        PLEASE DO .81 <- '.74 ~ .79'
        DO :13 <- '.80 $ .81'
        DO :14 <- 'V:13'
        DO .70 <- ':14 ~ #1'
        DO .1 <- #0
        DO .2 <- .70
        DO (1010) NEXT
        DO .70 <- .3
        PLEASE DO .68 <- '.70 ~ #1'
        DO .1 <- .60
        DO .2 <- .68
        DO (1009) NEXT
        DO .60 <- .3
        DO .69 <- '.62 ~ .70'
        PLEASE DO .1 <- .64
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .64 <- .3
        DO .69 <- '.63 ~ .70'
        DO .1 <- .65
        DO .2 <- .69
        DO (1010) NEXT
        PLEASE DO .65 <- .3

        DO .60 <- '.60 ~ .76'
        PLEASE DO .61 <- '.61 ~ .77'
        DO .100 <- '.60 ~ #1'
        DO .101 <- '.60 ~ #2'
        DO .102 <- '.60 ~ #4'
        PLEASE DO .103 <- '.60 ~ #8'
        DO .104 <- '.60 ~ #16'
        DO .105 <- '.60 ~ #32'
        DO .106 <- '.60 ~ #64'
        PLEASE DO .107 <- '.60 ~ #128'
        DO .108 <- '.60 ~ #256'
        DO .109 <- '.60 ~ #512'
        DO .110 <- '.60 ~ #1024'
        PLEASE DO .111 <- '.60 ~ #2048'
        DO .112 <- '.60 ~ #4096'
        DO .113 <- '.60 ~ #8192'
        DO .114 <- '.60 ~ #16384'
        PLEASE DO .115 <- '.60 ~ #32768'
        DO .116 <- '.61 ~ #1'
        DO .117 <- '.61 ~ #2'
        DO .118 <- '.61 ~ #4'
        PLEASE DO .119 <- '.61 ~ #8'
        DO .120 <- '.61 ~ #16'
        DO .121 <- '.61 ~ #32'
        DO .122 <- '.61 ~ #64'
        PLEASE DO .123 <- '.61 ~ #128'
        DO .124 <- '.61 ~ #256'
        DO .125 <- '.61 ~ #512'
        DO .126 <- '.61 ~ #1024'
        PLEASE DO .127 <- '.61 ~ #2048'
        DO .128 <- '.61 ~ #4096'
        DO .129 <- '.61 ~ #8192'
        DO .130 <- '.61 ~ #16384'
        PLEASE DO .131 <- '.61 ~ #32768'
        DO :12 <- '.116 $ .100'
        DO .132 <- ':12 ~ #3'
        DO :12 <- '.124 $ .108'
        DO .133 <- ':12 ~ #3'
        DO :12 <- '.120 $ .104'
        DO .134 <- ':12 ~ #3'
        DO :12 <- '.128 $ .112'
        DO .135 <- ':12 ~ #3'
        DO :12 <- '.118 $ .102'
        DO .136 <- ':12 ~ #3'
        PLEASE DO :12 <- '.126 $ .110'
        DO .137 <- ':12 ~ #3'
        DO :12 <- '.122 $ .106'
        DO .138 <- ':12 ~ #3'
        PLEASE DO :12 <- '.130 $ .114'
        DO .139 <- ':12 ~ #3'
        DO :12 <- '.117 $ .101'
        DO .140 <- ':12 ~ #3'
        DO :12 <- '.125 $ .109'
        DO .141 <- ':12 ~ #3'
        PLEASE DO :12 <- '.121 $ .105'
        DO .142 <- ':12 ~ #3'
        DO :12 <- '.129 $ .113'
        DO .143 <- ':12 ~ #3'
        PLEASE DO :12 <- '.119 $ .103'
        DO .144 <- ':12 ~ #3'
        DO :12 <- '.127 $ .111'
        DO .145 <- ':12 ~ #3'
        PLEASE DO :12 <- '.123 $ .107'
        DO .146 <- ':12 ~ #3'
        DO :12 <- '.131 $ .115'
        DO .147 <- ':12 ~ #3'
        PLEASE DO :12 <- '.133 $ .132'
        DO .148 <- ':12 ~ #15'
        DO :12 <- '.135 $ .134'
        DO .149 <- ':12 ~ #15'
        DO :12 <- '.137 $ .136'
        DO .150 <- ':12 ~ #15'
        PLEASE DO :12 <- '.139 $ .138'
        DO .151 <- ':12 ~ #15'
        DO :12 <- '.141 $ .140'
        DO .152 <- ':12 ~ #15'
        PLEASE DO :12 <- '.143 $ .142'
        DO .153 <- ':12 ~ #15'
        DO :12 <- '.145 $ .144'
        DO .154 <- ':12 ~ #15'
        PLEASE DO :12 <- '.147 $ .146'
        DO .155 <- ':12 ~ #15'
        DO :12 <- '.149 $ .148'
        DO .156 <- ':12 ~ #255'
        PLEASE DO :12 <- '.151 $ .150'
        DO .157 <- ':12 ~ #255'
        DO :12 <- '.153 $ .152'
        DO .158 <- ':12 ~ #255'
        DO :12 <- '.155 $ .154'
        DO .159 <- ':12 ~ #255'
        PLEASE DO :12 <- '.157 $ .156'
        DO .160 <- ':12 ~ #65535'
        DO :12 <- '.159 $ .158'
        DO .161 <- ':12 ~ #65535'
        PLEASE DO :3 <- '.161 $ .160'

        DO RETRIEVE :12
        DO RETRIEVE .161 .160 .159 .158 .157 .156
        PLEASE DO RETRIEVE .155 .154 .153 .152 .151 .150 .149 .148
        DO RETRIEVE .147 .146 .145 .144 .143 .142 .141 .140
        DO RETRIEVE .139 .138 .137 .136 .135 .134 .133 .132
        DO RETRIEVE .131 .130 .129 .128 .127 .126 .125 .124
        PLEASE DO RETRIEVE .123 .122 .121 .120 .119 .118 .117 .116
        DO RETRIEVE .115 .114 .113 .112 .111 .110 .109 .108
        DO RETRIEVE .107 .106 .105 .104 .103 .102 .101 .100
        DO RETRIEVE :14 :13 :11 :10
        PLEASE DO RETRIEVE .81 .80 .79 .78 .77 .76
        DO RETRIEVE .75 .74 .73 .72 .71 .70 .69 .68
        DO RETRIEVE .67 .66 .65 .64 .63 .62 .61 .60
        DO RETRIEVE .4 .3 .2 .1
        PLEASE DO RESUME #1

        DON'T NOTE ============================================
        DON'T NOTE Label 1999: overflow error
        DON'T NOTE ============================================

(1999)  DO .10 <- #0
        DON'T NOTE Signal overflow and terminate
        DO STASH .1
        PLEASE DO .1 <- #0
        DO GIVE UP
