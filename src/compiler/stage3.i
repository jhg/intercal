        DON'T NOTE stage3.i Phase 4 substage 3.2.a
        DON'T NOTE Branchless equality probes and 2-char keyword detector

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
        PLEASE DO .27 <- ,65535 SUB #2

        DON'T NOTE is_first_D
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

        DON'T NOTE is_first_O
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

        DON'T NOTE is_first_P
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

        DON'T NOTE is_first_A
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

        DON'T NOTE is_second_O
        DO STASH .1 .2 .3 .4
        DO .1 <- .27
        DO .2 <- #79
        PLEASE DO (1010) NEXT
        DO .40 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .91 <- '.40 ~ .40'
        DO .92 <- '.91 ~ #1'
        DO :93 <- '.92 $ #1'
        DO :94 <- '?:93'
        PLEASE DO .28 <- ':94 ~ #1'

        DON'T NOTE is_DO via bitwise AND of is_first_D and is_second_O
        DON'T NOTE Use mingle + unary AND + select to AND two booleans
        DO :95 <- '.23 $ .28'
        DO :96 <- '&:95'
        PLEASE DO .29 <- ':96 ~ #1'

        PLEASE DO READ OUT .20
        DO READ OUT .21
        DO READ OUT .22
        PLEASE DO READ OUT .23
        DO READ OUT .24
        DO READ OUT .25
        PLEASE DO READ OUT .26
        DO READ OUT .29

        DO GIVE UP
