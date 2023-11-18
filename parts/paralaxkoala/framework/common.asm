waitframe:
lda framecount
cmp framecount
beq *-2
rts
waitvblank:
bit $d011 
bpl waitvblank 
waitvb2:
bit $d011 
bmi waitvb2 
rts
push:
sta !a+ +1
stx !x+ +1
sty !y+ +1
lda $01
sta !zp+ +1
rts
pop:
!zp:
lda #$00
sta $01
!a:
lda #$00
!x:
ldx #$00
!y:
ldy #$00
rts