        DON'T NOTE Stage3 substage 1 prototype: byte-scanner loop.
        DON'T NOTE Counts occurrences of byte #67 (ASCII 'C') in a fixed array.
        DON'T NOTE Demonstrates conditional NEXT FROM as the loop-back primitive.

        DO ,1 <- #5
        DO ,1 SUB #1 <- #65
        PLEASE DO ,1 SUB #2 <- #67
        DO ,1 SUB #3 <- #66
        DO ,1 SUB #4 <- #67
        DO ,1 SUB #5 <- #67

        DO .30 <- #0
        PLEASE DO .31 <- #5
        DO .32 <- #0

(20)    DO STASH .1 .2 .3 .4
        DO .1 <- .32
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .32 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO .40 <- ,1 SUB .32

        DO STASH .1 .2 .3 .4
        DO .1 <- .40
        DO .2 <- #67
        PLEASE DO (1010) NEXT
        DO .50 <- .3
        DO RETRIEVE .1 .2 .3 .4

        PLEASE DO .51 <- '.50 ~ .50'
        PLEASE DO .52 <- '.51 ~ #1'
        DO :60 <- '.52 $ #1'
        DO :61 <- '?:60'
        DO .53 <- ':61 ~ #1'

        DO STASH .1 .2 .3 .4
        DO .1 <- .30
        DO .2 <- .53
        PLEASE DO (1009) NEXT
        DO .30 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO STASH .1 .2 .3 .4
        DO .1 <- .31
        DO .2 <- .32
        PLEASE DO (1010) NEXT
        DO .70 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO .71 <- '.70 ~ .70'
        PLEASE DO .72 <- '.71 ~ #1'
        DO (20) NEXT FROM .72

        PLEASE DO READ OUT .30
        DO GIVE UP
