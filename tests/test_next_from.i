        DON'T NOTE NEXT FROM extension regression test.
        DON'T NOTE Loops 5 iterations and prints V (Roman 5).

        DO .1 <- #5
        PLEASE DO .50 <- #0

(10)    DO STASH .1 .2 .3 .4
        DO .1 <- .50
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .50 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO STASH .2 .3 .4
        DO .2 <- #1
        PLEASE DO (1010) NEXT
        DO .1 <- .3
        DO RETRIEVE .2 .3 .4

        PLEASE DO .60 <- '.1 ~ .1'
        DO .61 <- '.60 ~ #1'
        PLEASE DO (10) NEXT FROM .61

        DO READ OUT .50
        DO GIVE UP
