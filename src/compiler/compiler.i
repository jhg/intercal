        DON'T NOTE compiler.i - minimal INTERCAL compiler MVP
        DON'T NOTE Template passthrough emitter
        DON'T NOTE
        DON'T NOTE Reads template file from argv 2 writes to stdout
        DON'T NOTE The wrapper script selects the right template
        DON'T NOTE
        DON'T NOTE Variables:
        DON'T NOTE   .1 .2 .3 .4 ,65535 - Label 666 interface
        DON'T NOTE   .10 - template fd
        DON'T NOTE   .11 - template byte count

(100)   PLEASE DO ,65535 <- #65535

        DON'T NOTE Read argv 2 as template filename
        PLEASE DO .1 <- #6
        PLEASE DO .2 <- #2
        DO (666) NEXT

        DON'T NOTE Open template file for reading
        PLEASE DO .1 <- #1
        DO .2 <- #0
        PLEASE DO (666) NEXT
        DO .10 <- .3

        DON'T NOTE Read template into ,65535
        PLEASE DO .1 <- #2
        DO .2 <- .10
        PLEASE DO .3 <- #60000
        DO (666) NEXT
        PLEASE DO .11 <- .4

        DON'T NOTE Close template
        DO .1 <- #4
        PLEASE DO .2 <- .10
        DO (666) NEXT

        DON'T NOTE Write template to stdout
        PLEASE DO .1 <- #3
        DO .2 <- #1
        PLEASE DO .3 <- .11
        DO (666) NEXT

        PLEASE DO GIVE UP
