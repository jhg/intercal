        DON'T NOTE stage3.i Phase 4 substage 3.1.d
        DON'T NOTE Adds boolean is_first_byte_D test to existing diagnostics

        PLEASE DO ,65535 <- #65535

        DO .1 <- #6
        DO .2 <- #1
        PLEASE DO (666) NEXT

        DO .1 <- #1
        DO .2 <- #0
        DO (666) NEXT
        DO .10 <- .3

        DO .1 <- #2
        DO .2 <- .10
        DO .3 <- #60000
        PLEASE DO (666) NEXT
        PLEASE DO .20 <- .4

        DO .1 <- #4
        DO .2 <- .10
        DO (666) NEXT

        PLEASE DO .21 <- ,65535 SUB #1
        PLEASE DO .22 <- ,65535 SUB .20

        DON'T NOTE Compute .23 = 1 if first byte equals D ascii 68 else 0
        PLEASE DO STASH .1 .2 .3 .4
        DO .1 <- .21
        DO .2 <- #68
        PLEASE DO (1010) NEXT
        DO .40 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DON'T NOTE Inverse of zero test gives 1 when difference is 0
        DO .91 <- '.40 ~ .40'
        DO .92 <- '.91 ~ #1'
        DO :93 <- '.92 $ #1'
        DO :94 <- '?:93'
        PLEASE DO .23 <- ':94 ~ #1'

        PLEASE DO READ OUT .20
        DO READ OUT .21
        DO READ OUT .22
        PLEASE DO READ OUT .23

        DO GIVE UP
