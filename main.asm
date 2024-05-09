; Josh Gillum
; Calculator

.orig x3000

and r1, r1, #0
sti r1, mathError
    
ld r1, input ; Gets input from the user
jsrr r1

ld r1, parse ; Parses the input
jsrr r1

ld r1, perform ; Performs the operations
jsrr r1

ld r1, print ; Prints the results
jsrr r1

end halt

input .fill getInput
parse .fill parseString
perform .fill performOperations
print .fill display
mathError .fill xfcff
    

; r1 + r2 = r3
addition:
    add r3, r1, r2
    ret

; r1 - r2 = r3
subtract:
    not r3, r2
    add r3, r3, #1
    add r3, r1, r3
    ret

; inverts r4 for each negative number in r1 and r2. Inverts r1 and/or r2 if they negative
; r4 is all 0's if the output should be positive, and all 1's if it should be negative
checkNegative:
    and r4, r4, #0
    add r1, r1, #0 
    brzp checkNegative_r2 ; r1 is not negative
    not r1, r1 ; inverts r1
    add r1, r1, #1
    not r4, r4
    
    checkNegative_r2 add r2, r2, #0
    brzp checkNegative_exit
    not r2, r2
    add r2, r2, #1
    not r4, r4
    
    checkNegative_exit ret
    

multiply: ; r3 = r1 * r2

    ; Saves registers that are changed.
    st r1, multiply_saveR1
    st r2, multiply_saveR2
    st r4, multiply_saveR4
    st r7, multiply_saveR7
    
    
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
    
    multiply_exit 
    ; Restores registers
    ld r1, multiply_saveR1
    ld r2, multiply_saveR2
    ld r4, multiply_saveR4
    ld r7, multiply_saveR7
    ret
    
    multiply_zero and r3, r3, #0 ; r3 is set to 0
    brnzp multiply_exit

    ; Stores register values from before function changed them
    multiply_saveR1 .blkw 1
    multiply_saveR2 .blkw 1
    multiply_saveR4 .blkw 1
    multiply_saveR7 .blkw 1

; Performs integer division of r3 = r1 / r2
divide:
    ; Register storage
    st r1, divide_saveR1
    st r2, divide_saveR2
    st r4, divide_saveR4
    st r7, divide_saveR7

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

    divide_exit 
    ; Restores registers
    ld r1, divide_saveR1
    ld r2, divide_saveR2
    ld r4, divide_saveR4
    ld r7, divide_saveR7
    ret

    divide_zero and r3, r3, #0 ; r3 is set to 0
    brnzp divide_exit
    
    divide_zeroError and r3, r3, #0 ; Occurs when attempting to divide by 0.
    not r3, r3
    sti r3, divide_mathError ; Sets flag mathError flag to -1 to indicate an error occured
    brnzp divide_exit

    ; Stores register values from before function changed them
    divide_saveR1 .blkw 1
    divide_saveR2 .blkw 1
    divide_saveR4 .blkw 1
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
    brnp getInput_storeChar ; Change to checkDigit to only allow 0-9
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
; getInput_checkDigit ld r4, getInput_0
;     add r4, r4, r0 ; Checks if the ascii value is less than that of "0"
;     brn getInput_loop
;     ld r4, getInput_9 
;     add r4, r4, r0 ; Checks if the ascii value is greater than that of "9"
;     brp getInput_loop
    
    
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
;r3 Sum returned
;r4 used
;r5 used
;r6 used
asciiToInt:
; Saves Registers
st r0, asciiToInt_saveR0
st r1, asciiToInt_saveR1
st r2, asciiToInt_saveR2
st r4, asciiToInt_saveR4
st r5, asciiToInt_saveR5
st r6, asciiToInt_saveR6

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
brnz asciiToInt_exit ; If negative or zero, stack is empty
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

and r3, r3, #0 ; Applies new power to r3
add r3, r3, r4

brnzp asciiToInt_mainLoop


asciiToInt_exit
and r3, r3, #0
add r3, r3, r1
ld r0, asciiToInt_saveR0
ld r1, asciiToInt_saveR1
ld r2, asciiToInt_saveR2
ld r4, asciiToInt_saveR4
ld r5, asciiToInt_saveR5
ld r6, asciiToInt_saveR6
ret

asciiToInt_stack .fill x4200 ; Stack starting address
asciiToInt_offset .fill x-30 ; Offset from ASCII to int

; Register storage
asciiToInt_saveR0 .blkw 1
asciiToInt_saveR1 .blkw 1
asciiToInt_saveR2 .blkw 1
asciiToInt_saveR4 .blkw 1
asciiToInt_saveR5 .blkw 1
asciiToInt_saveR6 .blkw 1


;r0 points to start of string
;r1 points to start of number
;r2 points to end of number
;r3 stores current value
;
;   character / value   /   operation code:
;   NULL        x0          0   (END OF Instruction)
;   (           x28         1
;   )           x29         2
;   +           x2B         10
;   -           x2D         11
;   *           x2A         12
;   /           x2F         13
;
parseString:
st r0, parseString_inputStart
st r1, parseString_saveR1
st r2, parseString_saveR2
st r7, parseString_saveReturn
and r1, r1, #0
and r2, r2, #0
parseString_getNumbers ldr r3, r0, #0
brz parseString_getParenthesis ; end of string reached

ld r4, parseString_zero
add r4, r4, r3 ; Checks if the ascii value is less than that of "0"
brn parseString_notNumber
ld r4, parseString_nine 
add r4, r4, r3 ; Checks if the ascii value is greater than that of "9"
brp parseString_notNumber

add r1, r1, #0
brnp parseStringNumbers_incrementR2
add r1, r1, r0
and r2, r2, #0
add r2, r2, r0
add r0, r0, #1
brnzp parseString_getNumbers
parseStringNumbers_incrementR2
    add r2, r2, #1
    add r0, r0, #1
    brnzp parseString_getNumbers



parseString_notNumber 
    add r1, r1, #0
    brz parseString_jumpGetNumbers
    jsr asciiToInt
    ld r5, parseString_valuesLast
    str r3, r5, #0 ; Stores r3 in the values array
    str r5, r1, #0 ; Stores the address of the value into r1
    add r5, r5, #1 ; Increments end of values array pointer and stores in memory
    st r5, parseString_valuesLast
    add r1, r1, #1
    
    not r2, r2 ; Inverses r2, to see when r1 is equal to it
    add r2, r2, #1
parseString_notNumberAddress ; Fills the rest of the input up to r2 with space (x20)
    add r3, r1, r2 ; Checks if r1 has filled in r2 yet
    brp parseString_notNumberResetPointers
    ld r3, parseString_normalspace ; Otherwise fills r1's addres with a space and increments r1
    str r3, r1, #0
    add r1, r1, #1
    brnzp parseString_notNumberAddress

parseString_notNumberResetPointers
    and r1, r1, #0
    and r2, r2, #0
    
    
parseString_jumpGetNumbers
    add r0, r0, #1 ; Moves r0 to next character of input
    brnzp parseString_getNumbers


parseString_getParenthesis
    add r1, r1, #0
    brz parseString_getParenthesisStart
    and r4, r4, #0
    str r4, r0, #1
    brnzp parseString_notNumber
parseString_getParenthesisStart
    ld r0, parseString_inputStart
    and r1, r1, #0
    add r1, r1, r0
    and r2, r2, #0
    and r3, r3, #0

parseString_parenthesisStart
    ldr r7, r0, #0 ; loads current character
    brz parseString_checkSyntaxError
    
    
    ld r6, parseString_space ; mask for space
    add r6, r6, r7
    brz parseString_parenthesisIncrementR0 ; If space, skip other checks

parseString_checkParenthesisOpen
    ld r6, parseString_parenthesisOpen
    add r6, r6, r7
    brnp parseString_checkParenthesisClose ; checks next character if this one is not open parenthesis
    add r3, r3, #-1 ; increments depth counter
    add r4, r2, r3 ; checks if current depth is greater than found max depth
    brzp parseString_parenthesisIncrementR0
    and r2, r2, #0
    add r2, r2, r3 ; sets found max depth to value of current depth
    not r2, r2
    add r2, r2, #1
    and r1, r1, #0 ; stores address of deepest open parenthesis
    add r1, r1, r0
    

parseString_checkParenthesisClose
    ld r6, parseString_parenthesisClose
    add r6, r6, r7
    brnp parseString_parenthesisIncrementR0
    add r3, r3, #1 ; lowers current depth by 1
    brnzp parseString_parenthesisIncrementR0

parseString_parenthesisIncrementR0 ; Increments r0 by 1 and returns to the start of the loop
    add r0, r0, #1
    brnzp parseString_parenthesisStart


parseString_checkSyntaxError
    add r3, r3, #0
    brz parseString_getInstructions
    ld r1, parseString_syntaxError
    and r2, r2, #0
    add r2, r2, #-1
    str r2, r1, #0
    


parseString_getInstructions
    and r0, r0, #0
    add r0, r0, r1 ; Sets r0 to the value of r1
    ; Check for unary "-" aka a negative number
    ; when find + or -, check if previous value is an operator or greater than 127.
    ; if operator, then unary, else if greater than 127, then binary
    ; check if x28 through x2e to see if operator
    
    ; R0 stores start of string
    ; R1 stores current number. Will hold location of unary minus sign when checking
    ; R2 stores pointer to previous addresses, for determining if sign is unary.
    ; R3 is temp
    ; r4 stores masks and offsets
    ; r5 stores the items that are stored at the memory locations
    and r2, r2, #0
    add r2, r2, r1
parseString_loadDash ; Checks the element at the memory pointed to by r2
    ldr, r4, r1, #0
    brz parseString_checkOperators ; End of string has been reached
    ld r4, parseString_parenthesisClose
    ldr, r3, r2, #0
    add r3, r3, r4
    brz parseString_checkOperators ; Reached a close parenthesis
    ld r4, parseString_dash
    ldr, r3, r2, #0
    add r3, r3, r4
    brnp parseString_addR1 ; Not a minus sign
parseString_minusR2 add r2, r2, #-1 ; Goes back a location
    not r2, r2 ; Converts r2 to negative
    add r2, r2, #1
    add r3, r0, r2 ; Checks if r2 is before r0
    not r2, r2 ; Converts r2 back to positive
    add r2, r2, #1
    add r3, r3, #0 ; R3 stores whether r0 or r2 is greater
    brp parseString_unaryInstruction ; R0 is greater, therefore the last element has been checked
    ld r4, parseString_endOfASCII ; Checks if r2 points to an address or an operator
    ldr r3, r2, #0
    add r3, r3, r4
    brzp parseString_addR1 ; R1 points to an address storing a number
    ld r4, parseString_space ; Checks if r2 points to a space
    ldr r3, r2, #0
    add r3, r3, r4
    brz parseString_minusR2 ; R2 points to a space
    
parseString_unaryInstruction
    and r2, r2, #0
    add r2, r2, r1
    
parseString_unarySpace add r2, r2, #1
    ld r4, parseString_space
    ldr r3, r2, #0
    add r3, r3, r4
    brz parseString_unarySpace
    ld r4, parseString_endOfASCII ; Checks if next item after r1 points to an address or an operator
    ldr r3, r2, #0
    add r3, r3, r4
    brn parseString_addR1 ; Next item is not an address
    
    ld r6, parseString_InstructionsLast ; Push operation to array
    and r3, r3, #0
    str r3, r6, #0 ; Pushes 0 to instruction
    add r6, r6, #1
    
    add r3, r3, #11
    str r3, r6, #0 ; Pushes the minus operation code
    add r6, r6, #1
    
    ldr r3, r2, #0
    str r3, r6, #0 ; Pushes the address of the number
    add r6, r6, #2
    
    st r6, parseString_InstructionsLast
    add r6, r6, #-1
    str r6, r1, #0
    ld r3, parseString_normalSpace
    str r3, r2, #0
    and r1, r1, #0
    add r1, r1, r2
    brnzp parseString_addR1

brnzp parseString_endStorage    ; Had to centrally locate storage, so whole function can access
parseString_normalSpace .fill x20
parseString_space .fill x-20
parseString_parenthesisOpen .fill x-28
parseString_parenthesisClose .fill x-29
parseString_cross .fill x-2B ; plus
parseString_dash .fill x-2D ; minus
parseString_star .fill x-2A ; times
parseString_slash .fill x-2F ; divide
parseString_zero .fill x-30
parseString_nine .fill x-39
parseString_endOfASCII .fill #-128

parseString_inputStart .blkw 1
parseString_saveReturn .blkw 1
parseString_saveR1 .blkw 1
parseString_saveR2 .blkw 1
parseString_values .fill x5000
parseString_valuesLast .fill x5000 ; Address of last value in array
parseString_Instructions .fill x6000
parseString_InstructionsLast .fill x6000 ; Address of last value in array
parseString_syntaxError .fill x3011

parseString_endStorage

    
parseString_addR1
    add r1, r1, #1 ; Increments r1, to next item, and brings r2 along with it
    and r2, r2, #0
    add r2, r2, r1
    brnzp parseString_loadDash
    
parseString_subtractR2
    add r2, r2, #-1
    brnzp parseString_loadDash 
    
    
    
parseString_checkOperators
    and r1, r1, #0
    and r2, r2, #0
    add r1, r0, r1
    add r2, r0, r2
    
parseString_loadStar
    ldr, r4, r1, #0
    brz parseString_addSubtract ; End of string has been reached
    
    ld r4, parseString_parenthesisClose
    ldr, r3, r2, #0
    add r3, r3, r4
    brz parseString_addSubtract ; Reached a close parenthesis
    
    ld r4, parseString_star
    ldr, r3, r2, #0
    add r3, r3, r4
    brz parseString_multiplyMinusR2 ; not a multiplication sign
    
    ld r4, parseString_slash
    ldr, r3, r2, #0
    add r3, r3, r4
    brnp parseString_multiplyAddR1 ; Not a divide sign
    
    
parseString_multiplyMinusR2 add r2, r2, #-1 ; Goes back a location
    not r2, r2 ; Converts r2 to negative
    add r2, r2, #1
    add r3, r0, r2 ; Checks if r2 is before r0
    not r2, r2 ; Converts r2 back to positive
    add r2, r2, #1
    add r3, r3, #0 ; R3 stores whether r0 or r2 is greater
    brp parseString_multiplyAddR1 ; R0 is greater, therefore the last element has been checked
    
    ld r4, parseString_space ; Checks if r2 points to a space
    ldr r3, r2, #0
    add r3, r3, r4
    brz parseString_multiplyMinusR2 ; R2 points to a space
    ld r4, parseString_endOfASCII ; Checks if r2 points to an address or an operator
    ldr r3, r2, #0
    add r3, r3, r4
    brn parseString_multiplyAddR1 ; R2 points to something other than an address
    
    
    and r5, r5, #0 ; R5 will check if there is a number succeeding
    add r5, r5, r1
parseString_multiplyAddR5 add r5, r5, #1 ; Goes forward a location

    ldr, r3, r5, #0
    brz parseString_multiplyAddR1 ; End of string has been reached
    
    ld r4, parseString_parenthesisClose
    ldr, r3, r5, #0
    add r3, r3, r4
    brz parseString_multiplyAddR1 ; Reached a close parenthesis
    
    ld r4, parseString_space ; Checks if r5 points to a space
    ldr r3, r5, #0
    add r3, r3, r4
    brz parseString_multiplyAddR5 ; R5 points to a space
    ld r4, parseString_endOfASCII ; Checks if r5 points to an address or an operator
    ldr r3, r5, #0
    add r3, r3, r4
    brn parseString_multiplyAddR1 ; R5 points to something other than an address
    
    
parseString_multiplyInstruction
    
    ld r6, parseString_InstructionsLast ; Push operation to array
    ldr r3, r2, #0
    str r3, r6, #0 ; Pushes the address of the first number
    add r6, r6, #1
    
    ld r4, parseString_slash ; Checks if the operation is multiply or divide
    ldr r3, r1, #0
    add r3, r3, r4
    brz parseString_divideSave
    and r3, r3, #0
    add r3, r3, #12
    str r3, r6, #0 ; Pushes the multiply operation code
    add r6, r6, #1
    brnzp parseString_multiplySecond
    
parseString_divideSave
    and r3, r3, #0
    add r3, r3, #13
    str r3, r6, #0 ; Pushes the divide operation code
    add r6, r6, #1
    
parseString_multiplySecond
    ldr r3, r5, #0
    str r3, r6, #0 ; Pushes the address of the second number
    add r6, r6, #2
    
    st r6, parseString_InstructionsLast
    add r6, r6, #-1
    str r6, r1, #0
    ld r3, parseString_normalSpace
    str r3, r2, #0
    str r3, r5, #0
    and r1, r1, #0
    add r1, r1, r5
    brnzp parseString_multiplyAddR1
    
    
    

parseString_multiplyAddR1
    add r1, r1, #1 ; Increments r1, to next item, and brings r2 along with it
    and r2, r2, #0
    add r2, r2, r1
    brnzp parseString_loadStar  
    

parseString_AddSubtract
    and r1, r1, #0
    and r2, r2, #0
    add r1, r0, r1
    add r2, r0, r2
    
parseString_loadCross
    ldr, r4, r1, #0
    brz parseString_repeat ; End of string has been reached
    
    ld r4, parseString_parenthesisClose
    ldr, r3, r2, #0
    add r3, r3, r4
    brz parseString_repeat ; Reached a close parenthesis
    
    ld r4, parseString_cross
    ldr, r3, r2, #0
    add r3, r3, r4
    brz parseString_addMinusR2 ; an addition sign
    
    
    ld r4, parseString_dash
    ldr, r3, r2, #0
    add r3, r3, r4
    brnp parseString_addAddR1 ; Not a minus sign
    
    
parseString_addMinusR2 add r2, r2, #-1 ; Goes back a location
    not r2, r2 ; Converts r2 to negative
    add r2, r2, #1
    add r3, r0, r2 ; Checks if r2 is before r0
    not r2, r2 ; Converts r2 back to positive
    add r2, r2, #1
    add r3, r3, #0 ; R3 stores whether r0 or r2 is greater
    brp parseString_addAddR1 ; R0 is greater, therefore the last element has been checked
    
    ld r4, parseString_space ; Checks if r2 points to a space
    ldr r3, r2, #0
    add r3, r3, r4
    brz parseString_addMinusR2 ; R2 points to a space
    ld r4, parseString_endOfASCII ; Checks if r2 points to an address or an operator
    ldr r3, r2, #0
    add r3, r3, r4
    brn parseString_addAddR1 ; R2 points to something other than an address
    
    
    and r5, r5, #0 ; R5 will check if there is a number succeeding
    add r5, r5, r1
parseString_addAddR5 add r5, r5, #1 ; Goes forward a location

    ldr, r3, r5, #0
    brz parseString_addAddR1 ; End of string has been reached
    
    ld r4, parseString_parenthesisClose
    ldr, r3, r5, #0
    add r3, r3, r4
    brz parseString_addAddR1 ; Reached a close parenthesis
    
    ld r4, parseString_space ; Checks if r5 points to a space
    ldr r3, r5, #0
    add r3, r3, r4
    brz parseString_addAddR5 ; R5 points to a space
    ld r4, parseString_endOfASCII ; Checks if r5 points to an address or an operator
    ldr r3, r5, #0
    add r3, r3, r4
    brn parseString_addAddR1 ; R5 points to something other than an address
    
    
parseString_addInstruction
    
    ld r6, parseString_InstructionsLast ; Push operation to array
    ldr r3, r2, #0
    str r3, r6, #0 ; Pushes the address of the first number
    add r6, r6, #1
    
    ld r4, parseString_dash ; Checks if the operation is multiply or divide
    ldr r3, r1, #0
    add r3, r3, r4
    brz parseString_minusSave
    and r3, r3, #0
    add r3, r3, #10
    str r3, r6, #0 ; Pushes the multiply operation code
    add r6, r6, #1
    brnzp parseString_addSecond
    
parseString_minusSave
    and r3, r3, #0
    add r3, r3, #11
    str r3, r6, #0 ; Pushes the divide operation code
    add r6, r6, #1
    
parseString_addSecond
    ldr r3, r5, #0
    str r3, r6, #0 ; Pushes the address of the second number
    add r6, r6, #2
    
    st r6, parseString_InstructionsLast
    add r6, r6, #-1
    str r6, r1, #0
    ld r3, parseString_normalSpace
    str r3, r2, #0
    str r3, r5, #0
    and r1, r1, #0
    add r1, r1, r5
    brnzp parseString_addAddR1

parseString_addAddR1
    add r1, r1, #1 ; Increments r1 to next item, and brings r2 along with it
    and r2, r2, #0
    add r2, r2, r1
    brnzp parseString_loadCross


parseString_repeat
    ld r4, parseString_parenthesisOpen ; Replaces first character with space, if it is open parenthesis
    ldr r3, r0, #0
    add r3, r3, r4
    brnp parseString_repeatClose
    ld r3, parseString_normalSpace
    str r3, r0, #0
    
parseString_repeatClose ; Replaces last character with space, if it is close parenthesis
    ld r4, parseString_parenthesisClose
    ldr r3, r1, #0
    add r3, r3, r4
    brnp parseString_repeatCheck
    ld r3, parseString_normalSpace
    str r3, r1, #0

parseString_repeatCheck ; R5 is storage value
    and r5, r5, #0
    ld r0, parseString_inputStart
parseString_repeatLoop
    ldr r3, r0, #0
    brz parseString_checkValidity ; End of string reached
    ld r4, parseString_space
    add r4, r3, r4
    brz parseString_checkIncrement
    ld r4, parseString_endOfASCII
    add r4, r3, r4
    brn parseString_fail ; Not an address
parseString_checkR5
    add r5, r5, #0
    brnp parseString_fail ; Not the first number
    ldr r5, r0, #0
parseString_checkIncrement
    add r0, r0, #1
    brnzp parseString_repeatLoop

parseString_fail
    ld r0, parseString_inputStart
    ld r1, parseString_returnToParenthesis
    jsrr r1
parseString_returnToParenthesis .fill parseString_getParenthesisStart


parseString_checkValidity
    add r5, r5, #0
    brz parseString_fail
    
    
    

parseString_exit 
    ld r6, parseString_instructions
    ld r7, parseString_saveReturn
    ret


performOperations:
    st r7, performOperations_saveReturn
    not r5, r5
    add r5, r5, #1
loop
    add r4, r5, r6
    brp performOperations_endOfArray ; End of operations
    ldr r1, r6, #0 ; Loads r1 with first operand
    brz #1
    ldr r1, r1, #0 ; R1 stores an address, so go to that address and get value
    
    ldr r2, r6, #2 ; Loads r2 with second operand
    brz #1
    ldr r2, r2, #0
    
    and r3, r3, #0 ; Checks which operation is stored
    ldr r4, r6, #1
    add r3, r3, #-10
    add r4, r3, r4
    brnp minus
    ld r4, performOperations_add
    jsrr r4
    brnzp performOperations_store
    
    
    
minus
    ldr r4, r6, #1
    add r3, r3, #-1
    add r4, r3, r4
    brnp times
    ld r4, performOperations_subtract
    jsrr r4
    brnzp performOperations_store
    
    
times
    ldr r4, r6, #1
    add r3, r3, #-1
    add r4, r3, r4
    brnp division
    ld r4, performOperations_multiply
    jsrr r4
    brnzp performOperations_store

division
    ldr r4, r6, #1
    add r3, r3, #-1
    add r4, r3, r4
    brnp none
    ld r4, performOperations_divide
    jsrr r4
    brnzp performOperations_store
none
    and r3, r3, #0
    brnzp performOperations_store
    
performOperations_store
    add r6, r6, #4 ; jumps one operation in the array
    str r3, r6, #-1 ; stores output in output section of previous operation
    brnzp loop
    
    
    
    
    
performOperations_endOfArray
    add r6, r6, #-1 ; r6 points to output of last operation
    ldr r5, r6, #0 ; r5 stores the answer
    ld r7, performOperations_saveReturn
    ret

performOperations_saveReturn .blkw 1
performOperations_add .fill addition
performOperations_subtract .fill subtract
performOperations_multiply .fill multiply
performOperations_divide .fill divide



display: ; Takes number in r5

    st r7, display_saveReturn ; Checks if a math error occured (dividing by zero)
    ldi r6, display_mathError
    brz display_noError
    and r0, r0, #0
    add r0, r0, #10 ; Displays newline
    trap x21
    lea r0, display_errorText
    trap x22
    brnzp display_return
    
display_noError
    lea r6, display_stack ; Stack for storing numbers, since this function works from the right to the left
    add r6, r6, #1
    
    and r0, r0, #0
    add r0, r0, #10 ; Displays newline
    trap x21
    ld r0, display_equal ; prints equal sign
    trap x21
    ld r0, display_space ; prints a space
    trap x21
    
    add r5, r5, #0 ; Prints a negative sign if r5 is negative
    brzp display_loop
    not r5, r5 ; Then converts it to positive
    add r5, r5, #1
    ld r0, display_dash
    trap x21
    
    
display_loop 
    and r1, r1, #0
    and r2, r2, #0
    add r2, r2, #10 ; r2 is used for changing power (multiplying or dividing by 10)
    and r4, r4, #0
    
    add r1, r1, r5 ; r1 stores original
    
    ld r0, display_divide
    jsrr r0
    
    
    
    and r1, r1, #0
    add r1, r1, r3
    ld r0, display_multiply
    jsrr r0 ; r3 stores (original / 10) * 10
    
    and r2, r2, #0
    add r2, r2, r3 ; r2 = (original / 10) * 10
    and r4, r4, #0 ; r4 stores r1 aka original / 10
    add r4, r1, r4
    and r1, r1, #0 ; r1 = original
    add r1, r1, r5
    ld r0, display_minus
    jsrr r0 ; r3 stores modulus of original / 10
    
    and r5, r5, #0
    ld r1, display_offset
    add r3, r3, r1
    str r3, r6, #0
    add r6, r6, #1
    add r5, r4, r5 ; r5 = original / 10
    brnp display_loop
    
    
    
    add r6, r6, #-1
display_print 
    ldr r0, r6, #0
    brz display_return; end of stack
    trap x21
    add r6, r6, #-1
    brnzp display_print


display_return
    and r0, r0, #0
    add r0, r0, #10 ; Displays newline
    trap x21
    ld r7, display_saveReturn
    ret

display_saveReturn .blkw 1
display_divide .fill divide
display_multiply .fill multiply
display_minus .fill subtract
display_dash .fill #45
display_offset .fill x30
display_equal .fill x3D
display_space .fill x20
display_mathError .fill xfcff
display_errorText .stringz "MATH ERROR"
display_stack .blkw x100


    
.end