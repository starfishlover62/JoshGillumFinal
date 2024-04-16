; Josh Gillum
; Calculator

.orig x3000

ld r1, sixtyFourBit?
brnp sixtyFourBit
sixteenBit .fill x0 ; will jump to subroutine for 16 bit calculator
brnzp end
sixtyFourBit .fill x0 ; will jump to subroutine for 64 bit calculator
end halt

.end

.orig x3010 ; Settings
sixtyFourBit? .fill x0000
prettyPrint? .fill x0000
.end