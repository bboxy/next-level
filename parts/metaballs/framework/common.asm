.var link_syncpoint = $a000
.var ATN = 1;
.var DATA = 1;
.pseudocommand release input{
	//??
	.byte >input
	.byte <input
	
}

.import source "../../../bitfire/macros/link_macros_kickass.inc"
.import source "../../../bitfire/loader/loader_kickass.inc"

waitframe:
#if release
	//lda link_frame_count+1
	//!wait:
	//cmp link_frame_count+1
	//beq !wait-
#else
lda framecount
cmp framecount
beq *-2

#endif
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
