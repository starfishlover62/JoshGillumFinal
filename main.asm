; Josh Gillum
; Calculator

.orig x3000
ld r1, sixtyFourBit?
brnp sixtyFourBit
sixteenBit jsr calculator16 ; will jump to subroutine for 16 bit calculator
brnzp end
sixtyFourBit .fill x0 ; will jump to subroutine for 64 bit calculator
end halt

.end

.orig x3010 ; Settings
sixtyFourBit? .fill x0000
prettyPrint? .fill x0000
.end


.orig x3020
calculator16:
    st r7, calculator16_saveR7
    
    ld r0, inputAddr
    jsrr r0
    
    ld r1, one
    ld r2, two
    and r3, r3, x0

    jsr divide16
    
    
    ld r7, calculator16_saveR7
    ret
    
    calculator16_saveR7 .blkw 1
    one .fill #10
    two .fill #3
    inputAddr .fill getInput

add16:
    add r3, r1, r2
    ret

subtract16:
    not r3, r2
    add r3, r3, #1
    add r3, r1, r3
    ret

; inverts r4 for each negative number in r1 and r2. Inverts the r1 or r2 if it is negative
checkNegative16:
    add r1, r1, #0
    brzp checkNegative16_r2
    not r1, r1
    add r1, r1, #1
    not r4, r4
    
    checkNegative16_r2 add r2, r2, #0
    brzp checkNegative16_exit
    not r2, r2
    add r2, r2, #1
    not r4, r4
    
    checkNegative16_exit ret
    

multiply16:
    st r4, multiply16_saveR4 ; Saves value of r4
    st r7, multiply16_saveR7 ; saves value of r7
    and r4, r4, #0
    
    add r1, r1, #0 ; Used to check state of r1
    brz multiply16_zero ; output will be 0
    
    ; Does same as what was just done to r1, but with r2
    multiply16_checkR2 add r2, r2, #0
    brz multiply16_zero
    
    
    jsr checkNegative16 ; converts r1 and r2 to positive numbers. r4 is negative 1 if product is to be negative
    multiply16_performCheck not r3, r2 ; Checks if r2 is larger or smaller than r1
    add r3, r3, #1 ; r3 is the negative of r2
    add r3, r1, r3 ; positive = r1 bigger, negative = r2 bigger, zero = they are the same
    brzp multiply16_perform
    
    ; Swaps the position of r1 and r2. r2 is the loop counter, so having a smaller value in r2 means that
    ; less iterations are required.
    and r3, r3, #0 ; r3 will temporarily store the value of r2
    add r3, r3, r2
    
    and r2, r2, #0 ; r2 stores the value of r1
    add r2, r1, #0
    
    and r1, r1, #0 ; r1 stores the value of r2
    add r1, r1, r3
    
    multiply16_perform and r3, r3, #0 ; Resets r3 to 0, so that it can store the product
    multiply16_loop add r3, r3, r1 ; Multiplication is done by repeatedly adding r1 to the sum, while decrementing r2 until it is equal to 0
    add r2, r2, #-1
    brp multiply16_loop ; Loops so long as r2 is positive
    
    add r4, r4, #0 ; Used to check state of r4. If 0, then product is positive, otherwise it is negative
    brz multiply16_exit
    not r3, r3 ; r3 is negated
    add r3, r3, #1
    
    multiply16_exit ld r4, multiply16_saveR4 ; Reverts the value of r4
    ld r7, multiply16_saveR7
    ret
    
    multiply16_zero and r3, r3, #0 ; r3 is set to 0
    brnzp multiply16_exit

    multiply16_saveR4 .blkw 1 ; stores the value of r4 from before the function call
    multiply16_saveR7 .blkw 1

; Performrs integer division of r3 = r1 / r2
divide16:
    st r4, divide16_saveR4 ; Saves value of r4
    st r7, divide16_saveR7 ; saves value of r7
    and r4, r4, #0

    add r1, r1, #0 ; Used to check state of r1
    brz divide16_zero ; output will be 0
    
    add r2, r2, #0 ; Used to check state of r2
    brz divide16_zeroError ; sets mathError flag

    jsr checkNegative16 ; Converts r1 and r2 to positive. r4 indicates negativity state

    divide16_perform and r3, r3, #0 ; Sets r3 to 0, so that it can store the product
    not r2, r2
    add r2, r2, #1
    divide16_loop add r3, r3, #1 ; Division is performed by repeatedly subtracting r2 from r1. Ends when r1 is negative
    add r1, r1, r2 
    brzp divide16_loop 
    add r3, r3, #-1
    
    
    add r4, r4, #0 ; Used to check state of r4. If 0, then product is positive, otherwise it is negative
    brz divide16_exit
    not r3, r3 ; r3 is negated
    add r3, r3, #1

    divide16_exit ld r4, divide16_saveR4 ; Reverts the value of r4
    ld r7, divide16_saveR7
    ret

    divide16_zero and r3, r3, #0 ; r3 is set to 0
    brnzp divide16_exit
    
    divide16_zeroError and r3, r3, #0 ; Occurs when attempting to divide by 0.
    not r3, r3
    sti r3, divide16_mathError ; Sets flag mathError flag to -1 to indicate an error occured
    brnzp divide16_exit


    divide16_saveR4 .blkw 1 ; stores the value of r4 from before the function call
    divide16_saveR7 .blkw 1
    divide16_mathError .fill xfcff

.end

.orig x5000
.blkw x101
getInput:
    ld r1 getInput_storage
    ld r2, getInput_max ; Limit Address for storage. Storage can go x5000 to r2, not including r2. Max character limit is 255
    getInput_loop trap x20
    
    ld r4, getInput_enter
    add r4, r4, r0
    brz getInput_exit
    
    ld r4, getInput_carriageReturn
    add r4, r4, r0
    brz getInput_exit
    
    ld r4, getInput_backspace
    add r4, r4, r0
    brnp getInput_storeChar
    and r0, r0, #0
    ld r2, getInput_storage
    not r2, r2
    add r2, r2, #1
    add r2, r2, r1
    brnz getInput_backspaceReset
    add r1, r1, #-1
    
    str r0, r1, #0
    add r0, r0, #8
    
    getInput_backspaceReset
    ld r2, getInput_max
    brnzp getInput_display
    
    
    
    getInput_storeChar str r0, r1, #0
    add r1, r1, #1
    
    getInput_display trap x21
    add r3, r2, r1
    brn getInput_loop
    
    getInput_exit ret
    
    getInput_storage .fill x5000
    getInput_max .fill x-5100
    
    ; Negative ASCII values of control characters
    getInput_enter .fill #-10
    getInput_carriageReturn .fill #-13
    getInput_backspace .fill #-8
    getInput_delete .fill #-127
    getInput_escape .fill #-27






.end