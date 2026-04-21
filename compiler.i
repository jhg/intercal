        DON'T NOTE compiler.i - INTERCAL compiler written in INTERCAL
        DON'T NOTE Stage 2: Read source, copy to ,10, uppercase, output length

        DON'T NOTE Read argv[1] (source filename) into ,65535
(100)   DO .1 <- #6
        PLEASE DO .2 <- #1
        DO (666) NEXT

        DON'T NOTE Open the file for reading
        DO .1 <- #1
        PLEASE DO .2 <- #0
        DO (666) NEXT

        DON'T NOTE Save fd in .10
        DO .10 <- .3

        DON'T NOTE Read file contents (up to 60000 bytes)
        PLEASE DO .1 <- #2
        DO .2 <- .10
        DO .3 <- #60000
        DO (666) NEXT

        DON'T NOTE Save bytes read count in .50
        PLEASE DO .50 <- .4

        DON'T NOTE Close the file
        DO .1 <- #4
        DO .2 <- .10
        PLEASE DO (666) NEXT

        DON'T NOTE Write contents to stdout (fd=1)
        DO .1 <- #3
        DO .2 <- #1
        PLEASE DO .3 <- .50
        DO (666) NEXT

        DON'T NOTE Exit
        PLEASE DO GIVE UP
