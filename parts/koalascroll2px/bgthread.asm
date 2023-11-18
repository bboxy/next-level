

jmp two
st:
!:
lda d016count
cmp #15
bne !-
jsr move15
!:
two:
lda d016count 
cmp #7
bne !-
:move(screen3, bitmap3, screen0, screen1, bitmap0, bitmap1)
endFlag:
lda #$00
beq !+
jmp endpart
!:
jmp st
move15:
:move(screen1, bitmap1, screen2, screen3, bitmap2, bitmap3)
rts

endpart:
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
	lda #$00
	sta $d011
	jsr link_load_next_comp
	jsr link_load_next_comp
	jmp link_exit
stackcode_end:
#endif

.macro move(sourceScreen, sourceBitmap, destinationScreen0, destinationScreen1, destinationBitmap0, destinationBitmap1){
	
	.var iheight = 25
	lda $01
	sta !en+ +1
	lda #$34
	sta $01
	ldx #$07
	!:
	.for(var t = 0;t<25;t++){
		lda sourceBitmap + 8 + t*40*8 ,x
		sta destinationBitmap0 + t*40*8,x
	}
	dex
	bmi !+
	jmp !-
	!:
	ldx #$93
	ldy #$4c
	!start:
	sty !end+ - 3
	ldy #$2c
	!:
	beq !start-
	.for(var t = 0;t<25;t++){
		lda sourceBitmap + 16 + t*40*8 ,x
		sta destinationBitmap0 + 8 +t*40*8,x
		sta destinationBitmap1 + t*40*8,x
	}
	.for(var t = 0;t<25;t++){
		lda sourceBitmap + 16 + t*40*8  + $94,x
		sta destinationBitmap0 + 8 +t*40*8  + $94,x
		sta destinationBitmap1 + t*40*8  + $94,x
	}
	dex
	bit !-
	!end:

	.for(var t = 0;t<25;t++){
		lda sourceScreen +1 + 40*t
		sta destinationScreen0 + 40*t
	}
	ldx#37
	!:
	.for(var t = 0;t<25;t++){
		lda sourceScreen +2 + 40*t,x
		sta destinationScreen0 +1 + 40*t,x
		sta destinationScreen1 + 40*t,x
	}
	dex
	bmi !+
	jmp !-

	!:

	// propagate new data:

	ldy screenBufferCount

	.for(var t = 0;t<iheight-20;t++){
		lda bufferScreenRam + t*charsInSecondKoala,y
		sta destinationScreen0 +(startbufferrender +1) + t*40
		sta destinationScreen1 +startbufferrender + t*40
	
	}
	iny
	.for(var t = 0;t<iheight-20;t++){
		lda bufferScreenRam + t*charsInSecondKoala ,y
		sta destinationScreen1 +(startbufferrender +1) + t*40
	}

	ldy screenBufferCount2
	.for(var t = iheight-20;t<iheight-15;t++){
		lda bufferScreenRam + t*charsInSecondKoala,y
		sta destinationScreen0 +(startbufferrender +1) + t*40
		sta destinationScreen1 +startbufferrender + t*40
	}
	iny
	.for(var t = iheight-20;t<iheight-15;t++){
		lda bufferScreenRam + t*charsInSecondKoala ,y
		sta destinationScreen1 +(startbufferrender +1) + t*40
	}

	ldy screenBufferCount3
	.for(var t = iheight-15;t<iheight-10;t++){
		lda bufferScreenRam + t*charsInSecondKoala,y
		sta destinationScreen0 +(startbufferrender +1) + t*40
		sta destinationScreen1 +startbufferrender + t*40
	
	}
	iny
	.for(var t = iheight-15;t<iheight-10;t++){
		lda bufferScreenRam + t*charsInSecondKoala ,y
		sta destinationScreen1 +(startbufferrender +1) + t*40
	}


	ldy screenBufferCount4
	.for(var t = iheight-10;t<iheight-5;t++){
		lda bufferScreenRam + t*charsInSecondKoala,y
		sta destinationScreen0 +(startbufferrender +1) + t*40
		sta destinationScreen1 +startbufferrender + t*40
	
	}
	iny
	.for(var t = iheight-10;t<iheight-5;t++){
		lda bufferScreenRam + t*charsInSecondKoala ,y
		sta destinationScreen1 +(startbufferrender +1) + t*40
	}


	ldy screenBufferCount5
	.for(var t = iheight-5;t<iheight-0;t++){
		lda bufferScreenRam + t*charsInSecondKoala,y
		sta destinationScreen0 +(startbufferrender +1) + t*40
		sta destinationScreen1 +startbufferrender + t*40
	
	}
	iny
	.for(var t = iheight-5;t<iheight-0;t++){
		lda bufferScreenRam + t*charsInSecondKoala ,y
		sta destinationScreen1 +(startbufferrender +1) + t*40
	}

	ldy screenBufferCount
	ldx times4Loookup,y
	ldy #$00 -4
	!:
	.for(var yy = 0; yy<iheight-20;yy++){
		lda addressBitmap(yy*2),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 0,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 0,y

		lda addressBitmap(yy*2+1),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 4,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 4,y


		lda addressBitmap(yy*2) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 0,y

		lda addressBitmap(yy*2+1) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 4,y
	}
	inx
	iny
	beq !+
	jmp !-
	!:

	ldy screenBufferCount2
	ldx times4Loookup,y
	ldy #$00 -4
	!:
	.for(var yy = iheight -20; yy<iheight-15;yy++){
		lda addressBitmap(yy*2),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 0,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 0,y

		lda addressBitmap(yy*2+1),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 4,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 4,y


		lda addressBitmap(yy*2) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 0,y

		lda addressBitmap(yy*2+1) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 4,y
	}
	inx
	iny
	beq !+
	jmp !-
	!:
	ldy screenBufferCount3
	ldx times4Loookup,y
	ldy #$00 -4
	!:
	.for(var yy = iheight -15; yy<iheight-10;yy++){
		lda addressBitmap(yy*2),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 0,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 0,y

		lda addressBitmap(yy*2+1),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 4,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 4,y


		lda addressBitmap(yy*2) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 0,y

		lda addressBitmap(yy*2+1) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 4,y
	}
	inx
	iny
	beq !+
	jmp !-
	!:

	ldy screenBufferCount4
	ldx times4Loookup,y
	ldy #$00 -4
	!:
	.for(var yy = iheight -10; yy<iheight-5;yy++){
		lda addressBitmap(yy*2),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 0,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 0,y

		lda addressBitmap(yy*2+1),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 4,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 4,y


		lda addressBitmap(yy*2) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 0,y

		lda addressBitmap(yy*2+1) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 4,y
	}
	inx
	iny
	beq !+
	jmp !-
	!:


	ldy screenBufferCount5
	ldx times4Loookup,y
	ldy #$00 -4
	!:
	.for(var yy = iheight -5; yy<iheight-0;yy++){
		lda addressBitmap(yy*2),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 0,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 0,y

		lda addressBitmap(yy*2+1),x
		sta -($100-4) +destinationBitmap0 + yy*40*8 + (startbufferrender +1)*8 + 4,y
		sta -($100-4) +destinationBitmap1 + yy*40*8 + startbufferrender*8 + 4,y


		lda addressBitmap(yy*2) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 0,y

		lda addressBitmap(yy*2+1) +4,x
		sta -($100-4) +destinationBitmap1 + yy*40*8 + (startbufferrender +1)*8 + 4,y
	}
	inx
	iny
	beq !+
	jmp !-
	!:
	
	
	
	!en:
	lda #$35
	sta $01
}
