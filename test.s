-- Test file
LOAD R2, #C4
STORE R2, $FE  -- Comment

ADD.R R2, R1
BRA $AB
LOAD R1, I(AA)
NOP
NOP
HALT


