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

        DON'T NOTE Dimension ,10 to source length
        DO ,10 <- .50

        DON'T NOTE Handle empty file: skip copy if .50 is zero
        DO .22 <- "'.50 ~ .50' ~ #1"
        PLEASE DO :20 <- '.22 $ #1'
        DO .23 <- '?:20 ~ #3'
        DON'T NOTE .23 = 1 if empty, 2 if not empty
        DO (152) NEXT
        DON'T NOTE RESUME #2: not empty
        PLEASE DO (154) NEXT
        DO FORGET #1
(152)   DO (153) NEXT
        DON'T NOTE RESUME #1: empty
        DO (180) NEXT
        PLEASE DO FORGET #1
(153)   DO RESUME .23
(154)   DO FORGET #1

        PLEASE DO .20 <- #1

        DON'T NOTE Copy loop with uppercasing
(160)   DO COME FROM (159)

        DON'T NOTE Read one byte from source
        DO .21 <- ,65535 SUB .20

        DON'T NOTE Uppercase check: is .21 in 97-122?
        DON'T NOTE Subtract 97, then add 65510; overflow means >= 26
        PLEASE DO STASH .1 + .2 + .3 + .4
        DO .1 <- .21
        DO .2 <- #97
        DO (1010) NEXT
        DON'T NOTE .3 = .21 - 97 mod 65536
        PLEASE DO .1 <- .3
        DO .2 <- #65510
        DO (1009) NEXT
        DON'T NOTE .4 = 1 if .3 < 26 (lowercase), 2 if >= 26 (not lowercase)
        PLEASE DO .25 <- .4
        DO RETRIEVE .1 + .2 + .3 + .4

        DON'T NOTE Branch: .25=1 lowercase (RESUME #1), .25=2 not (RESUME #2)
        DO (162) NEXT
        DON'T NOTE RESUME #2: not lowercase, skip
        PLEASE DO (164) NEXT
        DO FORGET #1
(162)   DO (163) NEXT
        DON'T NOTE RESUME #1: lowercase, subtract 32
        DO STASH .1 + .2 + .3
        PLEASE DO .1 <- .21
        DO .2 <- #32
        DO (1010) NEXT
        DO .21 <- .3
        PLEASE DO RETRIEVE .1 + .2 + .3
        DO (164) NEXT
        DO FORGET #1
(163)   DO RESUME .25
(164)   DO FORGET #1

        DON'T NOTE Store byte
        PLEASE DO ,10 SUB .20 <- .21

        DON'T NOTE Check done: .20 == .50
        DO STASH .1 + .2 + .3 + .4
        DO .1 <- .20
        PLEASE DO .2 <- .50
        DO .1 <- .20
        DO (1010) NEXT
        DON'T NOTE .3 = .20 - .50; zero if equal
        DO .22 <- "'.3 ~ .3' ~ #1"
        DON'T NOTE .22 = 0 if done, 1 if not done
        DON'T NOTE Use add-with-overflow to convert: .22 + 65535 overflows iff .22=1
        PLEASE DO .1 <- .22
        DO .2 <- #65535
        DO (1009) NEXT
        DON'T NOTE .4 = 1 if .22=0 (done, no overflow), 2 if .22=1 (not done, overflow)
        PLEASE DO .23 <- .4
        DO RETRIEVE .1 + .2 + .3 + .4

        DON'T NOTE Branch: .23=1 done (RESUME #1), .23=2 not done (RESUME #2)
        DO (170) NEXT
        DON'T NOTE RESUME #2: not done, continue
        PLEASE DO (174) NEXT
        DO FORGET #1
(170)   DO (171) NEXT
        DON'T NOTE RESUME #1: done, break
        DO ABSTAIN FROM (160)
        DO FORGET #1
        PLEASE DO (174) NEXT
        DO FORGET #1
(171)   DO RESUME .23

        DON'T NOTE Increment .20
(174)   PLEASE DO FORGET #1
        DO STASH .1
        DO .1 <- .20
        DO (1020) NEXT
        PLEASE DO .20 <- .1
        DO RETRIEVE .1

(159)   DO .99 <- #0

        DON'T NOTE Output length as Roman numeral
(180)   DO FORGET #1
        PLEASE DO READ OUT .50
        DO GIVE UP
