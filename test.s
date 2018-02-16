-- Test file
LOAD R2, #C4
: FUNC          -- 0x4 if no offset
STORE R2, $FE
DEF %i 2
ADD.R R%i, R1   -- Adds R2 to R1
BRA $:FUNC      -- Becomes BRA $04
LOAD R1, I(AA)
NOP
NOP
HALT


