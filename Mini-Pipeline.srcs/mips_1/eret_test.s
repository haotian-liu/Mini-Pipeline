j start;
INT:
    j INT;
start:
    lui $t0, 0x8000
    addi $t0, $t0, 0x510     # with lui, get 0x80000510 = vram addr
    addi $t1, $zero, 0x41    # char 'A'
    addi $t2, $zero, 0x1     # load 1
    addi $t3, $zero, 0x5b    # load 'Z' + 1
    sw $t1, ($t0)            # write vram
loop:
    add $t1, $t1, $t2        # 'A' to 'Z'
    slt $t4, $t1, $t3        # if $t1 is not smaller than 'Z' + 1
    bne $t4, $t2, start      # reset if larger than 'Z'
    sw $t1, ($t0)            # write vram
    j loop                   # loop

