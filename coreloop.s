DEF %TILE_MEM_BASE 3E8 -- the base of the tile mem in hex
DEF %LEFT_EDGE 12 -- value of the edge tile in hex
DEF %RIGHT_EDGE 13 -- value of right edge in hex
DEF %COLLISION 8 -- greater than this is a collision
DEF %NE 1 -- up to the right vector 
DEF %NW 3 -- up to the left vector
DEF %SW 5 -- down to the left
DEF %SE 7 -- down to the right
DEF %RESET_VECTOR FFFFFFF8 -- set the vector to "000"
DEF %LEAVE_Y 3FF000 -- leaves only YPos
DEF %PADDLE_WIDTH 8C -- 92 dec
DEF %HALF_PADDLE_WIDTH 2E -- 46 dec
NOP -- Init nop
LOAD R7, #C0060006 -- Ball 1 change ending 06 to 46 for speed
LOAD R8, #C02E0002 -- Ball 2 (02 -> 42 for speed)
-- main loop
BRA #:AOP -- Init: goto as often as possible

-- once per logical tick
: OLT

-- (0) update ball pos
BRA #:UPDATE_POS
: CORE1

-- (1) send reset signal to VGA_MOTOR
-- BRA #:RESET_COLLISION TODO REMOVE COMMENT
: CORE2
LOAD R1, #0
BRA #:SHOW_SCORE
: SHOW_SCORE_RET_0
LOAD R1, #1
BRA #:SHOW_SCORE
: SHOW_SCORE_RET_1

-- as often as posible
: AOP

BRT #:OLT -- Branch on tick

-- (2) collsion with padle
-- BRA #:PADDLE_COLLISION TODO REMOVE COMMENT
: CORE3

-- (3) resolve collisions with blocks
-- BRA #:TILE_COLLISION TODO REMOVE COMMENT
: CORE4

BRA #:AOP

-- -----------------------------
-- (0)
: UPDATE_POS

-- Update ball 1
UPD R7, #0 -- ball regitser 1

-- Update ball 2
UPD R8, #0 -- ball register 2

BRA #:CORE1
-- ----------------------------
-- (1)
: RESET_COLLISION
-- remember to send the reset signal through hardware when the tick 
-- goes over. (but after the position is updated)
LOAD R6, #0

BRA #:CORE2

-- ----------------------------
-- (2)
: PADDLE_COLLISION

-- ball 1
MOV R0, R7
AND R0, #%LEAVE_Y 
-- ASR R0, #C -- TODO: Make into 12 ASR or implement looping
ASR R0, #0
ASR R0, #0
ASR R0, #0
ASR R0, #0
ASR R0, #0
ASR R0, #0
ASR R0, #0
ASR R0, #0
ASR R0, #0
ASR R0, #0
ASR R0, #0
ASR R0, #0

LOAD R2, #8
CMP R0, R2
BMI #:NOT_PADDLE_ONE

MOV R1, R7
-- ASR R1, #16 -- shift away all but the XPos by 22 steps
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0

MOV R3, R1 -- copy ball 1 XPos 
MOV R4, R9 -- copy paddle 1 pos

CMP R3, R4
BMI #:NOT_PADDLE_ONE
ADD R4, #%HALF_PADDLE_WIDTH
CMP R3, R4
BMI #:PADDLE_ONE_LEFT
ADD R4, #%HALF_PADDLE_WIDTH
CMP R3, R4
BMI #:PADDLE_ONE_RIGHT
BRA #:NOT_PADDLE_ONE

: PADDLE_ONE_LEFT
AND R7, #%RESET_VECTOR -- remove the balls hedding
-- Collision with paddle 1 left
OR R7, #%SW
BRA #:NOT_PADDLE_ONE

: PADDLE_ONE_RIGHT
AND R7, #%RESET_VECTOR -- remove the balls hedding
-- Collision with paddle 1 right
OR R7, #%SE 

: NOT_PADDLE_ONE
-- -----------------------------------------------------------------------------
LOAD R2, #1D8 -- 472 dec
CMP R0, R2
BMI #:NOT_PADDLE_TWO
 
 MOV R4, R10 -- copy paddle 2 pos

 CMP R3, R4
 BMI #:NOT_PADDLE_TWO
 ADD R4, #%HALF_PADDLE_WIDTH
 CMP R3, R4
 BMI #:PADDLE_TWO_LEFT
 ADD R4, #%HALF_PADDLE_WIDTH
 CMP R3, R4
 BMI #:PADDLE_TWO_RIGHT
 BRA #:NOT_PADDLE_TWO

 : PADDLE_TWO_LEFT
 AND R7, #%RESET_VECTOR -- remove the balls hedding
 -- Collision with paddle 2 left
 OR R7, #%NW
 BRA #:NOT_PADDLE_TWO

 : PADDLE_TWO_RIGHT
 AND R7, #%RESET_VECTOR -- remove the balls hedding
 -- Collision with paddle 2 right
 OR R7, #%NE 

 : NOT_PADDLE_TWO
 -- ---------------------------------------------------------------------------
 -- ball 2
 MOV R0, R8
 AND R0, #%LEAVE_Y 
 -- ASR R0, #12
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 ASR R0, #0
 LOAD R2, #8
 CMP R0, R2
 BMI #:NOT_PADDLE_ONE_2

 MOV R1, R8
-- ASR R1, #16 -- shift away all but the XPos 22 steps
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0
ASR R1, #0

 MOV R3, R0 -- copy ball 1 XPos 
 MOV R4, R9 -- copy paddle 1 pos

 CMP R3, R4
 BMI #:NOT_PADDLE_ONE_2
 ADD R4, #%HALF_PADDLE_WIDTH
 CMP R3, R4
 BMI #:PADDLE_ONE_LEFT
 ADD R4, #%HALF_PADDLE_WIDTH
 CMP R3, R4
 BMI #:PADDLE_ONE_RIGHT
 BRA #:NOT_PADDLE_ONE_2

 : PADDLE_ONE_LEFT
 AND R8, #%RESET_VECTOR -- remove the balls hedding
 -- Collision with paddle 1 left
 OR R8, #%SW
 BRA #:NOT_PADDLE_ONE_2

 : PADDLE_ONE_RIGHT
 AND R8, #%RESET_VECTOR -- remove the balls hedding
 -- Collision with paddle 1 right
 OR R8, #%SE 

 : NOT_PADDLE_ONE_2
 -- -----------------------------------------------------------------------------
 LOAD R2, #1D8 -- 472 dec
 CMP R0, R2
 BMI #:NOT_PADDLE_TWO_2
  
  MOV R4, R10 -- copy paddle 2 pos

  CMP R3, R4
  BMI #:NOT_PADDLE_TWO_2
  ADD R4, #%HALF_PADDLE_WIDTH
  CMP R3, R4
  BMI #:PADDLE_TWO_LEFT
  ADD R4, #%HALF_PADDLE_WIDTH
  CMP R3, R4
  BMI #:PADDLE_TWO_RIGHT
  BRA #:NOT_PADDLE_TWO_2

  : PADDLE_TWO_LEFT
  AND R8, #%RESET_VECTOR -- remove the balls hedding
  -- Collision with paddle 2 left
  OR R8, #%NW
  BRA #:NOT_PADDLE_TWO_2

  : PADDLE_TWO_RIGHT
  AND R8, #%RESET_VECTOR -- remove the balls hedding
  -- Collision with paddle 2 right
  OR R8, #%NE 

  : NOT_PADDLE_TWO_2
  BRA #:CORE3
  --------------------------------

  -- (3)
  : TILE_COLLISION

  -- Ball 1 collision if it exists and is not allready dealt with.
  -- If dealt with continue otherwise reflect the ball and call block
  -- destructor (4).

  LOAD R5, #3
  CMP R6, R5
  BEQ #:BOTH_COLLIDED

  LOAD R5, #1
  CMP R6, R5
  BEQ #:NOT_ONE

  LOAD R0, #%COLLISION
  CMP R11, R0 -- collsion 1
  BMI #:NOT_ONE -- It has not collided
  MOV R3, R11
  AND R3, #7
  REF R7, R3 -- reflect 1
  ADD R6, #1 -- set coll flag 1
  MOV R0, R13 -- in argument to tile destructor (collsion adress)
  BRA #:TILE_DESTRUCTOR

  -- Ball 2 collision if it exists and is not allready dealt with.
  -- If dealt with continue otherwise reflect the ball and call block
  -- destructor (4).
  : NOT_ONE

  LOAD R0, #%COLLISION
  CMP R12, R0 -- collision 2
  BMI #:NOT_TWO -- It has not collided
  MOV R4, R12
  AND R4, #7
  REF R8, R4 -- reflect 2
  ADD R6, #2 -- set coll flag 2
  MOV R0, R13 -- in argument to tile destructor (collsion adress)
  BRA #:TILE_DESTRUCTOR

  : NOT_TWO
  : BOTH_COLLIDED
  BRA #:CORE3
  -- ----------------------------------------------------------------
  -- (4) Tile destructor
  : TILE_DESTRUCTOR
  MOV R15, R0
  LOAD R1, (%TILE_MEM_BASE)
  LOAD R2, #%LEFT_EDGE
  CMP R1, R2 -- Compare the tile with the edge.
  BEQ #:POINT
  LOAD R2, #%RIGHT_EDGE
  CMP R1, R2
  BEQ #:POINT
  LOAD R3, #0
  STORE R3, (%TILE_MEM_BASE) -- store an empty tile to the tile addr
  : POINT
  BRA #:AOP

  -- ---------------------------------------------
  -- (5) Update score
: POINTS_PLAYER_0
£ 64
: POINTS_PLAYER_1
£ 64
: SHOW_SCORE
-- Provide player ID (0 or 1) in R1
LOAD R2, #0 -- Counter
CMP R1, R2
BEQ #:SCORE_PLAYER_0
LOAD R3, $:POINTS_PLAYER_1
LOAD R15, #118          -- High tile offset for bottom row
BRA #:LOOP_100
: SCORE_PLAYER_0
LOAD R3, $:POINTS_PLAYER_0
LOAD R15, #0            -- First row tiles
: LOOP_100
SUB R3, #64 -- Remove 100
BMI #:END_100
ADD R2, #1
BRA #:LOOP_100
: END_100
ADD R3, #64  -- Add 100 (because removing one too many times)
-- If counter == 0, we add 10 because zero-tile is index 10
LOAD R4, #0 -- trash register
CMP R2, R4
BNE #:SET_100
LOAD R2, #A
: SET_100

STORE R2, (%TILE_MEM_BASE)
LOAD R2, #0 -- Reset counter
: LOOP_10
SUB R3, #A
BMI #:END_10
ADD R2, #1
BRA #:LOOP_10
: END_10
ADD R3, #A -- Restore last removed
CMP R2, R4
BNE #:SET_10
LOAD R2, #A
: SET_10
ADD R15, #1 -- Increment tile pos
STORE R2, (%TILE_MEM_BASE)

LOAD R2, #0 -- Reset counter
: LOOP_1
SUB R3, #1
BMI #:END_1
ADD R2, #1
BRA #:LOOP_1
: END_1
ADD R3, #1
CMP R2, R4
BNE #:SET_1
LOAD R2, #A
: SET_1
ADD R15, #1 -- Increment tile pos
STORE R2, (%TILE_MEM_BASE)

-- Switch return addr on R1 player ID
LOAD R2, #0
CMP R1, R2
BEQ #:SHOW_SCORE_RET_0
BRA #:SHOW_SCORE_RET_1
  ------------------------------------------------


  -- registers
  -- R0:    anything
  -- R1:    anything 
  -- R2:    anything
  -- R3:    anything
  -- R4:    anything
  -- R5:    anything
  -- R6:    allready collided
  -- R7:    ball 1
  -- R8:    ball 2
  -- R9:    paddle 1
  -- R10:    paddle 2
  -- R11:    collision 1
  -- R12: collision 2
  -- R13: collision adress 1
  -- R14: collision adress 2
  -- R15: index

  -- TODO:
  -- Create state machine that sends out a one puls reset signal when R6
  -- becomes 0.

