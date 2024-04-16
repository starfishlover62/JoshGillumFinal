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
    add r2, r2, #-4
    jsr subtract16
    
    
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
    ; Checkes if either of the operands are 0
    add r1, r1, #0
    brz multiply16_zero
    brn multiply16_negativeR1
    multiply16_checkR2 add r2, r2, #0
    brz multiply16_zero
    brn multiply16_negativeR2
    
    multiply16_performCheck not r3, r2 ; Checks if r2 is larger or smaller than r1
    add r3, r3, #1
    add r3, r1, r3
    brzp multiply16_perform
    
    and r3, r3, #0 ; r3 will temporarily store the value of r2, so r1 and r2 can be swapped
    add r3, r3, r2
    
    and r2, r2, #0 ; r2 stores the value of r1
    add r2, r1, #0
    
    and r1, r1, #0 ; r1 stores the value of r2
    add r1, r1, r3
    
    multiply16_perform and r3, r3, #0
    multiply16_loop add r3, r3, r1
    add r2, r2, #-1
    brp multiply16_loop
    
    
    
    st r4, multiply16_saveR4
    ld r4, multiply16_negativeValue
    brz multiply16_exit
    not r3, r3
    add r3, r3, #1
    
    multiply16_exit ld r4, multiply16_saveR4
    ret
    
    multiply16_saveR4 .blkw 1
    
    
    
    
    multiply16_zero and r3, r3, #0
    ret
    
    multiply16_negativeR1 not r1, r1 ; Makes r1 positive
    add r1, r1, #1
    ld r3, multiply16_negativeValue ; Inverts the value of multiply16_negativeValue
    not r3, r3
    st r3, multiply16_negativeValue
    brnzp multiply16_checkR2
    
    multiply16_negativeR2 not r2, r2 ; Makes r2 positive
    add r2, r2, #1
    ld r3, multiply16_negativeValue ; Inverts the value of multiply16_negativeValue
    not r3, r3
    st r3, multiply16_negativeValue
    brnzp multiply16_performCheck
    
    multiply16_negativeValue .fill x0000























.end