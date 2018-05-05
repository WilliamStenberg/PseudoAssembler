-- Set the score; update level with new score tiles
DEF %SCORE_NUM1 0F0 -- Adress of score variable, 32bit
DEF %SCORE_NUM2 0F4 -- Is the 4-offset correct here?
DEF %TILE_BASE  0D0 -- Base tilemem adress.
-- Setting initial scores
LOAD R1, #0
STORE R1, $%SCORE_NUM1
STORE R1, $%SCORE_NUM2
: SHOW_SCORE
-- Function to update level map score tiles
-- Input:
--  R1: Binary player ID
-- Destructive to R1, R2, R3
LOAD R2, #0 -- Counter
CMP R1, #1
BEQ $:SCORE_PLAYER_ONE
LOAD R3, $%SCORE_NUM1   -- R3 holds score data
LOAD R15, #0             -- GR15 is jump offset, for tile map selecting
BRA $:LOOP_100 -- Jump down
: SCORE_PLAYER_ONE
LOAD R3, $%SCORE_NUM2
LOAD R15, #118          -- High jump offset for bottom row
: LOOP_100
SUB R3, #64             -- Remove 100
BMI $:END_100            -- Branch if negative
ADD R2, #1              -- Increment counter
BRA $:LOOP_100
: END_100
ADD R3, #64             -- Add 100 (because we removed one too many times)
-- If counter is 0, we need to add 10 to it, 
-- because tiles[1] = 1, but tiles[10] = 0
CMP R2, #0
BNE $:SET_100
LOAD R2, #A
: SET_100
STORE R2, (%TILE_BASE)  -- Set tile memory

LOAD R2, #0             -- Reset counter
: LOOP_10
SUB R3, #A
BMI $:END_10
ADD R2, #1
BRA $:LOOP_10
: END_10

ADD R3, #A              -- Restore last removed
CMP R2, #0              -- if 0, add 10
BNE $:SET_10
LOAD R2, #A
: SET_10
ADD R15, #1             -- Increment indexing register (next tile)
STORE R2, (%TILE_BASE)

LOAD R2, #0             -- Reset counter
: LOOP_1
SUB R3, #1
BMI $:END_1
ADD R2, #1
BRA $:LOOP_1
: END_1
ADD R3, #1
CMP R2, #0
BNE $:SET_1
LOAD R2, #A
: SET_1
ADD R15, #1
STORE R2, (%TILE_BASE)

