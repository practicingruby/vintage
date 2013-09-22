; SOURCE: http://skilldrick.github.io/easy6502/#snake
;  ___           _        __ ___  __ ___
; / __|_ _  __ _| |_____ / /| __|/  \_  )
; \__ \ ' \/ _` | / / -_) _ \__ \ () / /
; |___/_||_\__,_|_\_\___\___/___/\__/___|

; Change direction: W A S D

; $00-01 => screen location of apple
; $10-11 => screen location of snake head
; $12-?? => snake body (in byte pairs)
; $02    => direction (1 => up, 2 => right, 4 => down, 8 => left)
; $03    => snake length


  jsr init
  jsr loop

init:
  jsr initSnake
  jsr generateApplePosition
  rts


initSnake:
  lda #$02  ;start direction
  sta $02
  lda #$04  ;start length
  sta $03
  lda #$11
  sta $10
  lda #$10
  sta $12
  lda #$0f
  sta $14
  lda #$04
  sta $11
  sta $13
  sta $15
  rts


generateApplePosition:
  ;load a new random byte into $00
  lda $fe
  sta $00

  ;load a new random number from 2 to 5 into $01
  lda $fe
  and #$03 ;mask out lowest 2 bits
  clc
  adc #$02
  sta $01

  rts


loop:
  jsr readKeys
  jsr checkCollision
  jsr updateSnake
  jsr drawApple
  jsr drawSnake
  jsr spinWheels
  jmp loop


readKeys:
  lda $ff
  cmp #$77
  beq upKey
  cmp #$64
  beq rightKey
  cmp #$73
  beq downKey
  cmp #$61
  beq leftKey
  rts
upKey:
  lda #$04
  bit $02
  bne illegalMove

  lda #$01
  sta $02
  rts
rightKey:
  lda #$08
  bit $02
  bne illegalMove

  lda #$02
  sta $02
  rts
downKey:
  lda #$01
  bit $02
  bne illegalMove

  lda #$04
  sta $02
  rts
leftKey:
  lda #$02
  bit $02
  bne illegalMove

  lda #$08
  sta $02
  rts
illegalMove:
  rts


checkCollision:
  jsr checkAppleCollision
  jsr checkSnakeCollision
  rts


checkAppleCollision:
  lda $00
  cmp $10
  bne doneCheckingAppleCollision
  lda $01
  cmp $11
  bne doneCheckingAppleCollision

  ;eat apple
  inc $03
  inc $03 ;increase length
  jsr generateApplePosition
doneCheckingAppleCollision:
  rts


checkSnakeCollision:
  ldx #$02 ;start with second segment
snakeCollisionLoop:
  lda $10,x
  cmp $10
  bne continueCollisionLoop

maybeCollided:
  lda $11,x
  cmp $11
  beq didCollide

continueCollisionLoop:
  inx
  inx
  cpx $03          ;got to last section with no collision
  beq didntCollide
  jmp snakeCollisionLoop

didCollide:
  jmp gameOver
didntCollide:
  rts


updateSnake:
  ldx $03 ;location of length
  dex
  txa
updateloop:
  lda $10,x
  sta $12,x
  dex
  bpl updateloop

  lda $02
  lsr
  bcs up
  lsr
  bcs right
  lsr
  bcs down
  lsr
  bcs left
up:
  lda $10
  sec
  sbc #$20
  sta $10
  bcc upup
  rts
upup:
  dec $11
  lda #$01
  cmp $11
  beq collision
  rts
right:
  inc $10
  lda #$1f
  bit $10
  beq collision
  rts
down:
  lda $10
  clc
  adc #$20
  sta $10
  bcs downdown
  rts
downdown:
  inc $11
  lda #$06
  cmp $11
  beq collision
  rts
left:
  dec $10
  lda $10
  and #$1f
  cmp #$1f
  beq collision
  rts
collision:
  jmp gameOver


drawApple:
  ldy #$00
  lda $fe
  sta ($00),y
  rts


drawSnake:
  ldx #$00
  lda #$01
  sta ($10,x)
  ldx $03
  lda #$00
  sta ($10,x)
  rts


spinWheels:
  ldx #$00
spinloop:
  nop
  nop
  dex
  bne spinloop
  rts


gameOver:
