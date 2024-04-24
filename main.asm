; Josh Gillum
; Calculator

.orig x3000
jsr calculator ; will jump to subroutine for 16 bit calculator
end halt

.end

.orig x3010 ; Settings
prettyPrint? .fill x0000 ; adds commas to numbers greater than 999
.end


.orig x3020
calculator:
    st r7, calculator_saveR7
    
    ld r0, inputAddr
    jsrr r0

    jsr asciiToInt
    
    
    ld r7, calculator_saveR7
    ret
    
    calculator_saveR7 .blkw 1
    one .fill #10
    two .fill #3
    inputAddr .fill getInput

addition:
    add r3, r1, r2
    ret

subtract:
    not r3, r2
    add r3, r3, #1
    add r3, r1, r3
    ret

; inverts r4 for each negative number in r1 and r2. Inverts the r1 or r2 if it is negative
checkNegative:
    add r1, r1, #0
    brzp checkNegative_r2
    not r1, r1
    add r1, r1, #1
    not r4, r4
    
    checkNegative_r2 add r2, r2, #0
    brzp checkNegative_exit
    not r2, r2
    add r2, r2, #1
    not r4, r4
    
    checkNegative_exit ret
    

multiply:
    st r4, multiply_saveR4 ; Saves value of r4
    st r7, multiply_saveR7 ; saves value of r7
    and r4, r4, #0
    
    add r1, r1, #0 ; Used to check state of r1
    brz multiply_zero ; output will be 0
    
    ; Does same as what was just done to r1, but with r2
    multiply_checkR2 add r2, r2, #0
    brz multiply_zero
    
    
    jsr checkNegative ; converts r1 and r2 to positive numbers. r4 is negative 1 if product is to be negative
    multiply_performCheck not r3, r2 ; Checks if r2 is larger or smaller than r1
    add r3, r3, #1 ; r3 is the negative of r2
    add r3, r1, r3 ; positive = r1 bigger, negative = r2 bigger, zero = they are the same
    brzp multiply_perform
    
    ; Swaps the position of r1 and r2. r2 is the loop counter, so having a smaller value in r2 means that
    ; less iterations are required.
    and r3, r3, #0 ; r3 will temporarily store the value of r2
    add r3, r3, r2
    
    and r2, r2, #0 ; r2 stores the value of r1
    add r2, r1, #0
    
    and r1, r1, #0 ; r1 stores the value of r2
    add r1, r1, r3
    
    multiply_perform and r3, r3, #0 ; Resets r3 to 0, so that it can store the product
    multiply_loop add r3, r3, r1 ; Multiplication is done by repeatedly adding r1 to the sum, while decrementing r2 until it is equal to 0
    add r2, r2, #-1
    brp multiply_loop ; Loops so long as r2 is positive
    
    add r4, r4, #0 ; Used to check state of r4. If 0, then product is positive, otherwise it is negative
    brz multiply_exit
    not r3, r3 ; r3 is negated
    add r3, r3, #1
    
    multiply_exit ld r4, multiply_saveR4 ; Reverts the value of r4
    ld r7, multiply_saveR7
    ret
    
    multiply_zero and r3, r3, #0 ; r3 is set to 0
    brnzp multiply_exit

    multiply_saveR4 .blkw 1 ; stores the value of r4 from before the function call
    multiply_saveR7 .blkw 1

; Performs integer division of r3 = r1 / r2
divide:
    st r4, divide_saveR4 ; Saves value of r4
    st r7, divide_saveR7 ; saves value of r7
    and r4, r4, #0

    add r1, r1, #0 ; Used to check state of r1
    brz divide_zero ; output will be 0
    
    add r2, r2, #0 ; Used to check state of r2
    brz divide_zeroError ; sets mathError flag

    jsr checkNegative ; Converts r1 and r2 to positive. r4 indicates negativity state

    divide_perform and r3, r3, #0 ; Sets r3 to 0, so that it can store the product
    not r2, r2
    add r2, r2, #1
    divide_loop add r3, r3, #1 ; Division is performed by repeatedly subtracting r2 from r1. Ends when r1 is negative
    add r1, r1, r2 
    brzp divide_loop 
    add r3, r3, #-1
    
    
    add r4, r4, #0 ; Used to check state of r4. If 0, then product is positive, otherwise it is negative
    brz divide_exit
    not r3, r3 ; r3 is negated
    add r3, r3, #1

    divide_exit ld r4, divide_saveR4 ; Reverts the value of r4
    ld r7, divide_saveR7
    ret

    divide_zero and r3, r3, #0 ; r3 is set to 0
    brnzp divide_exit
    
    divide_zeroError and r3, r3, #0 ; Occurs when attempting to divide by 0.
    not r3, r3
    sti r3, divide_mathError ; Sets flag mathError flag to -1 to indicate an error occured
    brnzp divide_exit


    divide_saveR4 .blkw 1 ; stores the value of r4 from before the function call
    divide_saveR7 .blkw 1
    divide_mathError .fill xfcff


;***********************getInput***************************
;This subroutine gets input from the user. It only accepts the digits
;0-9 for each character
;
;R0 (modified - Points to the user's input (as an array)
;R1 - Points to the current storage location for the input
;R2 - Stores the negative of the boundary address of the storage array
;R3 - Used for checking if the array's bounds are overflown
;R4 - Used as for loading check values for determining which key was pressed
;R7 - Stores the return address for this subroutine.
;************************************************************
getInput:

    ; Saves the registers used
    st r1, getInput_saveR1
    st r2, getInput_saveR2
    st r3, getInput_saveR3
    st r4, getInput_saveR4

    ld r1 getInput_storage
    ld r2, getInput_max ; Limit Address for storage. Storage can go x5000 to r2, not including r2. Max character limit is 255
    
    ld r1 getInput_storage
    
getInput_loop trap x20 ; Gets a character from the user
    
    ld r4, getInput_enter ; Loop ends if enter is pressed
    add r4, r4, r0
    brz getInput_exit
    
    ld r4, getInput_carriageReturn ; Loop ends if carriage return is pressed (unsure if necessary. May depend on keyboard)
    add r4, r4, r0
    brz getInput_exit
    
    ld r4, getInput_escape ; Loop ends if escape key is pressed. Terminates program
    add r4, r4, r0
    brz getInput_exitEscape
    
    ld r4, getInput_backspace ; Last input character will be removed from storage if backspace is pressed
    add r4, r4, r0
    brnp getInput_checkDigit
    and r0, r0, #0 ; Will be used to store 0 over the last character
    ld r2, getInput_storage ; Used to determine if r1 is at the first character of storage
    not r2, r2
    add r2, r2, #1
    add r2, r2, r1
    brnz getInput_backspaceReset ; If positive, then at least one character is already in storage
    add r1, r1, #-1 ; Moves pointer to previous character
    str r0, r1, #0 ; Writes 0 over it
    add r0, r0, #8 ; backspace ASCII code for displaying
    
getInput_backspaceReset ld r2, getInput_max ; Resets r2
    brnzp getInput_display
    
    ; Checks if the character is a digit. Does not store it if it isnt
getInput_checkDigit ld r4, getInput_0
    add r4, r4, r0 ; Checks if the ascii value is less than that of "0"
    brn getInput_loop
    ld r4, getInput_9 
    add r4, r4, r0 ; Checks if the ascii value is greater than that of "9"
    brp getInput_loop
    
    
getInput_storeChar str r0, r1, #0 ; Stores character to array
    add r1, r1, #1
    
getInput_display trap x21
    add r3, r2, r1 ; If zero or positive, the array is out of space
    brn getInput_loop
    
getInput_exit and r0, r0, #0
    str r0, r1, #0
    ld r0, getInput_storage
    ld r1, getInput_saveR1
    ld r2, getInput_saveR2
    ld r3, getInput_saveR3
    ld r4, getInput_saveR4
    ret
    
getInput_exitEscape and r0, r0, #0
    str r0, r1, #0
    and r0, r0, #0
    add r0, r0, #-1
    ld r1, getInput_saveR1
    ld r2, getInput_saveR2
    ld r3, getInput_saveR3
    ld r4, getInput_saveR4
    ret
    
getInput_storage .fill x4000
getInput_max .fill x-4100
    
    ; Negative ASCII values of 0 and 9
getInput_0 .fill #-48
getInput_9 .fill #-57
    
    ; Negative ASCII values of control characters
getInput_enter .fill #-10
getInput_carriageReturn .fill #-13
getInput_backspace .fill #-8
getInput_delete .fill #-127
getInput_escape .fill #-27
    
    ; Register storage space
getInput_saveR1 .fill x0000
getInput_saveR2 .fill x0000
getInput_saveR3 .fill x0000
getInput_saveR4 .fill x0000

;r1 is address of first element
;r2 is address of last element
asciiToInt:
not r2, r2
add r2, r2, #1 ; Inverses r2, for checking if the last element is reached
ld r6, asciiToInt_stack

asciiToInt_loadStack add r3, r1, r2
brp asciiToInt_unwindStack
ldr r3, r1, #0 ; Gets r3 from address in r1
str r3, r6, #0 ; Pushes to stack
add r6, r6, #1 ; Moves stack pointer
add r1, r1, #1
brnzp asciiToInt_loadStack

asciiToInt_unwindStack and r1, r1, #0 ; sum
and r3, r3, #0 ; r3 is power, r2 is current value
add r3, r3, #1 ; r4 is used for multiplying
ld r5, asciiToInt_stack ; r5 is inverse of start of stack
not r5, r5 ; Used for checking if stack is empty
add r5, r5, #1

asciiToInt_mainLoop add r4, r5, r6
brnz asciiToInt_exit ; If negative, then stack is empty
add r6, r6, #-1
ldr r2, r6, #0 ; Gets current ascii value

ld r4, asciiToInt_offset
add r2, r2, r4 ; Applies offset to r2

asciiToInt_addLoop brnz asciiToInt_power ; Adds the power to the sum r2 times
add r1, r1, r3 ; ex 400 = 4 (r2) * 100 (r3) or 100 + 100 + 100 + 100
add r2, r2, #-1
brnzp asciiToInt_addLoop

; Multiplies r3 (power) by 10, for moving to the next digit
asciiToInt_power and r2, r2, #0
add r2, r2, #10 ; Number of times to increment r3
and r4, r4, #0 ; r4 is the running total for incrementing r3
asciiToInt_powerLoop 
add r4, r4, r3 ; r4 will be equal to r3 added 10 times
add r2, r2, #-1
brp asciiToInt_powerLoop 

and r3, r3, #0
add r3, r3, r4

brnzp asciiToInt_mainLoop


asciiToInt_exit
ret
asciiToInt_stack .fill x4200
asciiToInt_offset .fill x-30


;r0 points to start of string
parseString:


parseString_values .fill x5000
parseString_Instructions .fill x6000
    
.end