        DON'T NOTE stage3.i Phase 4 substage 3.1.e
        DON'T NOTE Branchless equality probe of byte 1 against D O P A E

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

        DON'T NOTE Branchless equal probe macro: target byte equals .21
        DON'T NOTE Compute .B = 1 if .21 - candidate is 0 else 0

        DO STASH .1 .2 .3 .4
        DO .1 <- .21
        DO .2 <- #68
        PLEASE DO (1010) NEXT
        DO .40 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .91 <- '.40 ~ .40'
        DO .92 <- '.91 ~ #1'
        DO :93 <- '.92 $ #1'
        DO :94 <- '?:93'
        PLEASE DO .23 <- ':94 ~ #1'

        DO STASH .1 .2 .3 .4
        DO .1 <- .21
        DO .2 <- #79
        PLEASE DO (1010) NEXT
        DO .40 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .91 <- '.40 ~ .40'
        DO .92 <- '.91 ~ #1'
        DO :93 <- '.92 $ #1'
        DO :94 <- '?:93'
        PLEASE DO .24 <- ':94 ~ #1'

        DO STASH .1 .2 .3 .4
        DO .1 <- .21
        DO .2 <- #80
        PLEASE DO (1010) NEXT
        DO .40 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .91 <- '.40 ~ .40'
        DO .92 <- '.91 ~ #1'
        DO :93 <- '.92 $ #1'
        DO :94 <- '?:93'
        PLEASE DO .25 <- ':94 ~ #1'

        DO STASH .1 .2 .3 .4
        DO .1 <- .21
        DO .2 <- #65
        PLEASE DO (1010) NEXT
        DO .40 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .91 <- '.40 ~ .40'
        DO .92 <- '.91 ~ #1'
        DO :93 <- '.92 $ #1'
        DO :94 <- '?:93'
        PLEASE DO .26 <- ':94 ~ #1'

        DON'T NOTE Output count first last is_D is_O is_P is_A
        PLEASE DO READ OUT .20
        DO READ OUT .21
        DO READ OUT .22
        PLEASE DO READ OUT .23
        DO READ OUT .24
        PLEASE DO READ OUT .25
        DO READ OUT .26

        PLEASE DO GIVE UP
