
.data XX
LS_s: .word 0x200
LS_l: .word 0x2
Exit_s: .word 0x210
Exit_l: .word 0x4

.data 0x200

# Hello world
.word 0x48 # H
.word 0x65 # e
.word 0x6c # l
.word 0x6c # l
.word 0x6f # o
.word 0x20 #
.word 0x77 # w
.word 0x6f # o
.word 0x72 # r
.word 0x6c # l
.word 0x64 # d
.word 0x21 # !

# ls
.data 0x240
.word 0x4c # L
.word 0x53 # S

# exit
.data 0x250
.word 0x65 # E
.word 0x78 # X
.word 0x69 # I
.word 0x74 # T