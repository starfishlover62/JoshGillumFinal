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

    and r1, r1, x0
    and r2, r2, x0
    and r3, r3, x0
    add r1, r1, #-7
    add r2, r2, #6
    jsr multiply16
    
    
    ld r7, calculator16_saveR7
    ret
    
    calculator16_saveR7 .blkw 1

add16:
    add r3, r1, r2
    ret

subtract16:
    not r3, r2
    add r3, r3, #1
    add r3, r1, r3
    ret

multiply16:
    st r4, multiply16_saveR4 ; Saves value of r4
    and r4, r4, #0
    
    add r1, r1, #0 ; Used to check state of r1
    brz multiply16_zero ; output will be 0
    brn multiply16_negativeR1 ; Indicates that product should be negative, and makes r1 positive
    
    ; Does same as what was just done to r1, but with r2
    multiply16_checkR2 add r2, r2, #0
    brz multiply16_zero
    brn multiply16_negativeR2 ; If both r1 and r2 are negative, the product will be positive
    
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
    ret
    
    multiply16_zero and r3, r3, #0 ; r3 is set to 0
    ld r4, multiply16_saveR4 ; Reverts the value of r4
    ret
    
    ; Makes r1 positive and negates r4
    multiply16_negativeR1 not r1, r1 
    add r1, r1, #1
    not r4, r4
    brnzp multiply16_checkR2 ; returns to check r2 next
    
    ; Makes r2 positive and negates r4
    multiply16_negativeR2 not r2, r2
    add r2, r2, #1
    not r4, r4
    brnzp multiply16_performCheck ; returns to check whether r2 is smaller or larger than r1

    multiply16_saveR4 .blkw 1 ; stores the value of r4 from before the function call





















.end