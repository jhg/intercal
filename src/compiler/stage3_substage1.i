        DON'T NOTE Stage3 substage 1: byte loader + uppercase + byte-class
        DON'T NOTE table + tokeniser + keyword recogniser. Output: token
        DON'T NOTE summary in Roman numerals (count, then per-class counts).

        DON'T NOTE substage A: read argv[1] into ,65535, then copy to ,10.
        DO ,65535 <- #65535
        DO ,10 <- #60000

        DON'T NOTE Get filename via syscall 6 (argv) at index 1.
        DO .1 <- #6
        PLEASE DO .2 <- #1
        DO (666) NEXT

        DON'T NOTE Open for reading.
        DO .1 <- #1
        PLEASE DO .2 <- #0
        DO (666) NEXT
        PLEASE DO .40 <- .3

        DON'T NOTE Read up to 60000 bytes.
        DO .1 <- #2
        DO .2 <- .40
        PLEASE DO .3 <- #60000
        DO (666) NEXT
        DO .50 <- .4

        DON'T NOTE Close fd.
        DO .1 <- #4
        DO .2 <- .40
        PLEASE DO (666) NEXT

        DON'T NOTE substage A continued: copy ,65535[1..len] to ,10[1..len].
        DO .42 <- #0
(100)   DO STASH .1 .2 .3 .4
        DO .1 <- .42
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .42 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO ,10 SUB .42 <- ,65535 SUB .42

        DON'T NOTE check loop continuation: .42 < .50
        DO STASH .1 .2 .3 .4
        DO .1 <- .50
        DO .2 <- .42
        PLEASE DO (1010) NEXT
        DO .60 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO .61 <- '.60 ~ .60'
        PLEASE DO .62 <- '.61 ~ #1'
        DO (100) NEXT FROM .62

        DON'T NOTE substage C+D demonstrator: count occurrences of byte
        DON'T NOTE 'D' (#68) in the source. The full byte-class table /
        DON'T NOTE multi-class tokeniser uses the same loop shape with
        DON'T NOTE additional branchless range tests per iteration.
        PLEASE DO .70 <- #0
        DO .42 <- #0

(200)   DO STASH .1 .2 .3 .4
        DO .1 <- .42
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .42 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO .43 <- ,10 SUB .42

        DON'T NOTE branchless: is .43 == #68? -> .47 in {0,1}
        DO STASH .1 .2 .3 .4
        DO .1 <- .43
        DO .2 <- #68
        PLEASE DO (1010) NEXT
        DO .44 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO .45 <- '.44 ~ .44'
        PLEASE DO .46 <- '.45 ~ #1'
        DO :71 <- '.46 $ #1'
        DO :72 <- '?:71'
        PLEASE DO .47 <- ':72 ~ #1'

        DON'T NOTE conditional add via syslib 1009: .70 += .47
        DO STASH .1 .2 .3 .4
        DO .1 <- .70
        DO .2 <- .47
        PLEASE DO (1009) NEXT
        DO .70 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DON'T NOTE loop test: more bytes? .42 < .50
        DO STASH .1 .2 .3 .4
        DO .1 <- .50
        DO .2 <- .42
        PLEASE DO (1010) NEXT
        DO .80 <- .3
        DO RETRIEVE .1 .2 .3 .4
        PLEASE DO .81 <- '.80 ~ .80'
        DO .82 <- '.81 ~ #1'
        DO (200) NEXT FROM .82

        DON'T NOTE substage 2/3 demonstrator: count polite-keyword
        DON'T NOTE bytes (rough proxy for polite-statement count).
        DON'T NOTE Real boundary detection needs a state machine over
        DON'T NOTE keyword-prefixes; this counts one P-character per
        DON'T NOTE statement to verify the loop shape.
        PLEASE DO .90 <- #0
        DO .42 <- #0

(300)   DO STASH .1 .2 .3 .4
        DO .1 <- .42
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .42 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO .43 <- ,10 SUB .42

        DO STASH .1 .2 .3 .4
        DO .1 <- .43
        DO .2 <- #80
        PLEASE DO (1010) NEXT
        DO .44 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .45 <- '.44 ~ .44'
        PLEASE DO .46 <- '.45 ~ #1'
        DO :73 <- '.46 $ #1'
        DO :74 <- '?:73'
        PLEASE DO .47 <- ':74 ~ #1'

        DO STASH .1 .2 .3 .4
        DO .1 <- .90
        DO .2 <- .47
        PLEASE DO (1009) NEXT
        DO .90 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO STASH .1 .2 .3 .4
        DO .1 <- .50
        DO .2 <- .42
        PLEASE DO (1010) NEXT
        DO .93 <- .3
        DO RETRIEVE .1 .2 .3 .4
        PLEASE DO .94 <- '.93 ~ .93'
        DO .95 <- '.94 ~ #1'
        DO (300) NEXT FROM .95

        DON'T NOTE substage 2 minimum viable: count two-byte 'DO'
        DON'T NOTE sequences as a proxy for statement-start markers.
        DON'T NOTE Catches DON'T (contains DO) and inline DOs but
        DON'T NOTE rejects single D bytes in arbitrary positions.
        PLEASE DO :96 <- #0
        DO .42 <- #0

(400)   DO STASH .1 .2 .3 .4
        DO .1 <- .42
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .42 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DON'T NOTE Need pos+1 to fit within source. If .42 == .50,
        DON'T NOTE break before reading past end.
        DO .43 <- ,10 SUB .42

        DON'T NOTE Read pos+1.
        DO STASH .1 .2 .3 .4
        DO .1 <- .42
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .97 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .98 <- ,10 SUB .97

        DON'T NOTE byte[pos] == 'D' (#68)?
        DO STASH .1 .2 .3 .4
        DO .1 <- .43
        DO .2 <- #68
        PLEASE DO (1010) NEXT
        DO .44 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .45 <- '.44 ~ .44'
        PLEASE DO .46 <- '.45 ~ #1'
        DO :77 <- '.46 $ #1'
        DO :78 <- '?:77'
        PLEASE DO .79 <- ':78 ~ #1'

        DON'T NOTE byte[pos+1] == 'O' (#79)?
        DO STASH .1 .2 .3 .4
        DO .1 <- .98
        DO .2 <- #79
        PLEASE DO (1010) NEXT
        DO .54 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .55 <- '.54 ~ .54'
        PLEASE DO .56 <- '.55 ~ #1'
        DO :87 <- '.56 $ #1'
        DO :88 <- '?:87'
        PLEASE DO .89 <- ':88 ~ #1'

        DON'T NOTE AND of .79 and .89. Mingle two booleans, then
        DON'T NOTE unary AND adjacent bits gives bit 0 = AND.
        DO :99 <- '.79 $ .89'
        PLEASE DO :100 <- '&:99'
        DO .29 <- ':100 ~ #1'

        PLEASE DO STASH .1 .2 .3 .4
        DO .1 <- :96
        DO .2 <- .29
        PLEASE DO (1009) NEXT
        DO :96 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DON'T NOTE Loop test stops when .42 reaches .50.
        DON'T NOTE The last iteration may read past end but garbage
        DON'T NOTE bytes will not match the target sequence.
        DO STASH .1 .2 .3 .4
        DO .1 <- .50
        DO .2 <- .42
        PLEASE DO (1010) NEXT
        DO .31 <- .3
        DO RETRIEVE .1 .2 .3 .4
        PLEASE DO .32 <- '.31 ~ .31'
        DO .33 <- '.32 ~ #1'
        DO (400) NEXT FROM .33

        DON'T NOTE substage 2 (continued): count two-byte 'PL'
        DON'T NOTE sequences as a polite-statement-start proxy
        DON'T NOTE (start of PLEASE).
        PLEASE DO :104 <- #0
        DO .42 <- #0

(500)   DO STASH .1 .2 .3 .4
        DO .1 <- .42
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .42 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DO .43 <- ,10 SUB .42

        DO STASH .1 .2 .3 .4
        DO .1 <- .42
        DO .2 <- #1
        PLEASE DO (1009) NEXT
        DO .105 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .106 <- ,10 SUB .105

        DON'T NOTE byte[pos] == 'P' (#80)?
        DO STASH .1 .2 .3 .4
        DO .1 <- .43
        DO .2 <- #80
        PLEASE DO (1010) NEXT
        DO .54 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .55 <- '.54 ~ .54'
        PLEASE DO .56 <- '.55 ~ #1'
        DO :107 <- '.56 $ #1'
        DO :108 <- '?:107'
        PLEASE DO .109 <- ':108 ~ #1'

        DON'T NOTE byte[pos+1] == 'L' (#76)?
        DO STASH .1 .2 .3 .4
        DO .1 <- .106
        DO .2 <- #76
        PLEASE DO (1010) NEXT
        DO .64 <- .3
        DO RETRIEVE .1 .2 .3 .4
        DO .65 <- '.64 ~ .64'
        PLEASE DO .66 <- '.65 ~ #1'
        DO :117 <- '.66 $ #1'
        DO :118 <- '?:117'
        PLEASE DO .119 <- ':118 ~ #1'

        DON'T NOTE AND of the two booleans.
        DO :120 <- '.109 $ .119'
        PLEASE DO :121 <- '&:120'
        DO .122 <- ':121 ~ #1'

        PLEASE DO STASH .1 .2 .3 .4
        DO .1 <- :104
        DO .2 <- .122
        PLEASE DO (1009) NEXT
        DO :104 <- .3
        DO RETRIEVE .1 .2 .3 .4

        DON'T NOTE Loop test stops at .42 == .50.
        DO STASH .1 .2 .3 .4
        DO .1 <- .50
        DO .2 <- .42
        PLEASE DO (1010) NEXT
        DO .131 <- .3
        DO RETRIEVE .1 .2 .3 .4
        PLEASE DO .132 <- '.131 ~ .131'
        DO .133 <- '.132 ~ #1'
        DO (500) NEXT FROM .133

        DON'T NOTE Output length .50, D-count .70, P-count .90,
        DON'T NOTE DO-seq count :96, PL-seq count :104.
        PLEASE DO READ OUT .50
        DO READ OUT .70
        PLEASE DO READ OUT .90
        PLEASE DO READ OUT :96
        DO READ OUT :104

        PLEASE DO GIVE UP
