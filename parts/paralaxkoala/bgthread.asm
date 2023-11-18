.var scrollWidth = 40
.var excludeWidth = 9


.macro movebitmap (bitmapsrc, bitmapdest, screensrc, screendest) {
	
	lda #$34
	sta $01
	
	ldx #$07
	!:
	.for(var t = 0;t<24;t++){
		.for(var i = 0;i< scrollWidth;i++){
			.if(i < 32){
				lda bitmapsrc + t*40*8 + i*8 + 40*8,x
				sta bitmapdest + t*40*8 + i*8,x
			}
			
		}
	}
	.for(var i = 0;i< scrollWidth;i++){
		.if(i < 32){
			lda bitmapsrc + i*8,x
			sta bitmapdest + 24*40*8 + i*8,x
		}
		}
	dex
	bmi !+
	jmp !-
	!:

	/*.for(var t = 0 ; t<24;t++){
	.for(var i = 0;i<scrollWidth;i++){
		lda screensrc  + t*40 + i + 40
		sta screendest + t*40 + i 

	}	
}*/
.for(var i = 0;i<scrollWidth;i++){
	.if(i < 32){
		lda screensrc  + i
		sta screendest + 24*40 + i 
		}
	}
	ldx #$00
	!:
	lda screensrc + 40,x
	sta screendest,x
	lda screensrc + $100 + 40,x
	sta screendest + $100,x
	lda screensrc + $200 + 40,x
	sta screendest + $200,x
	lda screensrc + $2e8,x
	sta screendest + $2e8 - 40,x
	inx
	bne !-	
	lda #$35
	sta $01	
}
jmp next


.pc = $6400 "bgthread"
next:
/*
ldx #$80
!:
jsr waitframe
dex
bne !-*/
st:

:movebitmap(image1location, image2location, screen1location, screen2location)
!:
lda d011counter
cmp #$01
bne !-
:SetScreenAndCharLocation(screen2location,image2location)
//inc $d020
lda #$00
sta $dd00
jsr moved800
//dec $d020
:movebitmap(image2location, image1location, screen2location, screen1location)
!:
lda d011counter
cmp #$01
bne !-
:SetScreenAndCharLocation(screen1location,image1location)
lda #$02
sta $dd00
jsr moved800
counter:
lda #$18
bne !+
//
lda #$00
sta fadeflag +1
!:
cmp #$00 - 13
bne !+
jmp endpart
!:
dec counter + 1

jmp st


waitframe:
lda $02
cmp $02
beq *-2
rts

initzp:
lda #<logostart
sta $90
lda #>logostart
sta $91
rts


.pc = * "move d800"
moved800:


ldx #$00
!:
lda $d800,x
sta $a0,x
inx
cpx #scrollWidth
bne !-

.for(var t = 0 ; t<25;t++){
	ldx #scrollWidth -1
	!:	
	lda $d800 + t*40 + 40,x
	sta $d800 + t*40,x  
	dex
	//cpx #scrollWidth
	bpl !-
}

fadeflag:
lda #$01
beq !fade+

ldx #$00
!:
lda $a0,x
sta $d800 + 24*40,x
inx
cpx #scrollWidth
bne !-
rts
!fade:

lax #$00
!:
sta $d800 + 24*40,x
inx
cpx #scrollWidth
bne !-
lda #$34
sta $01
lda #$00
ldx #$28
!:
sta screen1location + 24*40,x
sta screen2location + 24*40,x
dex
bpl !-
lda #$35
sta $01
rts

endpart:
	lda #$0b
	sta $d011
	sei
#if !release
	inc $d020
	jmp endpart
#else
//	lda #$00
//	sta $d418
	ldx #stackcode_end - stackcode
!:
	lda stackcode,x
	sta $0100,x
	dex
	bpl !-
	jmp $0100
stackcode:
	jsr link_load_next_comp
	//jsr link_load_next_comp
	//jsr link_load_next_comp
	jmp link_exit
stackcode_end:
#endif
