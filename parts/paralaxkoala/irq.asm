
IRQ1:
jsr push
lda #$35
sta $01
inc $d019

ldx d011counter
lda $d011
and #240
ora d011vals,x
sta $d011
inc d011counter
lda d011counter

cmp #$10
bne !+
lda #$00
sta d011counter
lda $9f
clc
adc #$08
sta $9f
inc bufferswitch
!:
lda d011counter
and #$01
bne mus
lda bufferswitch
and #$01
bne !+

dec $01
jsr mockupdate
inc $01
jmp mus
!:

dec $01
jsr mockupdate2
inc $01
mus:

jsr updatebuffers
//inc $d020
#if !release
//jsr music_play
#endif

inc framecount
jsr pop
rti


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

d011vals:
.byte 7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0

d011counter:
.byte 0

.macro renderImg(image, charwidth){
.pc = * "renderimg"

inc $9f

.for(var i = 0;i<10;i+=5){
	ldy $9f
	ldx #$08
	!:
	.for(var t = 0 ; t< charwidth;t++){
		.for(var it = 0;it<5;it++){
			lda  logobuffer+(i+it)*8 + t*$200,y
			sta -1 + image +  t*8 +(i+it)*8*40+ 32*8,x
		}
				
	}
	dey
	dex 
	beq !+
	jmp !-
	!:	
}
.pc = * "part2"
ldy $9f
.for(var i = 10;i<25;i+=1){	
	.for(var t = 0 ; t< charwidth;t++){
		.for(var yy = 0;yy<8;yy++){
			lda  logobuffer+i*8 + t*$200 +yy -7,y
			sta image +  t*8 +i*8*40+ 32*8 +yy
		}			
	}	
}


}

.pc = $8e00
mockupdate:
.var charwidth = 8
:renderImg(image1location, charwidth)
rts
mockupdate2:
:renderImg(image2location, charwidth)
rts

updatebuffers:
lda #$34
sta $01
lda $91
pha
ldy #$00
lda $90
clc
adc #192
tax
.for(var t = 0;t<9;t++){
	lda ($90),y
	sta logobuffer  + (t*$200),x
	sta logobuffer + (t*$200) + $100,x
	inc $91
	inc $91
}

pla
sta $91
inc $90
bne !+
inc $91
!:
lda $91
cmp #>(logostart + $200)
bne !+
jsr initzp
!:
inc $01
rts


