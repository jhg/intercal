        DON'T NOTE stage3.i Phase 4
        DON'T NOTE Current substage 3.1.c source byte count first byte last byte
        DON'T NOTE Reads argv 1 as INTERCAL source emits diagnostic info

        PLEASE DO ,65535 <- #65535

        DON'T NOTE Read argv 1 into ,65535
        DO .1 <- #6
        DO .2 <- #1
        PLEASE DO (666) NEXT

        DON'T NOTE Open source file
        DO .1 <- #1
        DO .2 <- #0
        DO (666) NEXT
        DO .10 <- .3

        DON'T NOTE Read contents into ,65535
        DO .1 <- #2
        DO .2 <- .10
        DO .3 <- #60000
        PLEASE DO (666) NEXT
        PLEASE DO .20 <- .4

        DON'T NOTE Close source
        DO .1 <- #4
        DO .2 <- .10
        DO (666) NEXT

        DON'T NOTE Read first byte into .21
        PLEASE DO .21 <- ,65535 SUB #1

        DON'T NOTE Read last byte at index .20 into .22
        PLEASE DO .22 <- ,65535 SUB .20

        DON'T NOTE Output count first byte last byte
        PLEASE DO READ OUT .20
        DO READ OUT .21
        DO READ OUT .22

        PLEASE DO GIVE UP
