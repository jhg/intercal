        DON'T NOTE Assigning a value larger than 65535 to a spot variable
        DON'T NOTE should raise ICL275I

        DO :1 <- #65535
        DO .1 <- #1
        DO :2 <- .1
        PLEASE DO (1500) NEXT
        DO .9 <- :3
        PLEASE DO READ OUT .9
        DO GIVE UP
