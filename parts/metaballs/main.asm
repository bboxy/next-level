.import source "framework/framework.asm"
.import source "codeGeneratorInclude.asm"

.var screen1 = $0400
.var screen2 = $2400

.var charset = $2000
.var charoffset = $0c
.var bankswitch = $0b
.var byteHolder1 = $1e
.var byteHolder2 = $0e
.var stackpointer = $10
.var counter3 = $14
.var sineValue1 = $12
.var sineValue2 = $13
.var blobLookup = $e000
.var blobSize = $0441
.var waitForIRQ = $ea

.var speedCodeStart = unpackedSpeedCodeResident

.var blob3 = $3410
.var blob4 = $3410 + blobSize

.var codeRenderBeforeMoved = $4000
.var blob3and4AddressBeforeMoved = $4b00


.if(screen1 != $0400){
	*=screen1 "screen1" virtual
	.fill 40*25,0
}
*=screen2 "screen2" virtual
	.fill 40*25,0

*= charset "charset" virtual
.fill 256*8, 0

*= blobLookup "bloblookup" virtual
.fill blobSize, 0


*= unpackedSpeedCodeResident "speedCode" virtual
.fill unpackedSpeedCodeSize, 0

*=blob3 "blob3" virtual
.fill blobSize, 0

*=blob4 "blob4" virtual
.fill blobSize, 0

#if release
.var link_exit = cmdLineVars.get("link_exit").asNumber();
#endif


.macro getSpriteSingle(spritePic, spriteNoX, spriteNoY) {
	.for (var y=0; y<21; y++){
		.for (var x=0; x<3; x++){
			.byte $ff - spritePic.getSinglecolorByte(x + spriteNoX * 3, y + spriteNoY * 21)
		}			
	}	
	.byte 0
}

.pc = $3d00
//Slammer's example, but adapted by Cruzer
//.var spriteData = $3000
//.pc = spriteData "spriteData"
.var spritePic = LoadPicture("balloon1.png")
.for (var i=0; i<4; i++)
	:getSpriteSingle(spritePic, i, 0)
//.fill 64, $ff

*=$2880 "Start"

start: // entry point
	jmp init

.import source "framework/common.asm"



init:
#if !release

	f $dd00 : 0
	f $d018 : $fe
	f $d016 : $8
	f16 $d020 : $0801
	f $d800 : $d800+$03e8 : $0f
	lda #$1b
	sta $d011
#endif
	
	m codeRenderBeforeMoved :codeRenderBeforeMoved + packedSpeedCodeSize : unpackerResident
	//m blob3and4AddressBeforeMoved : blob3and4AddressBeforeMoved + blobSize*2 : blob3
	
	//inc $d020
	//jmp *-3
	//lda #$00
	//sta $d015
	ldx #$34
	txs
	stx $01
	jsr unpackerResident
	inc $01
#if release
!t:
	lda $22
	beq !t-
#endif

	ldx #<blob
	ldy #>blob
	jsr prepareData
	// create screen data
	prepareScreens:
	lda #25
	sta $11
	!b:
	ldx #$00
	!a:
	lda #$08
	clc
	!add:
	adc #$00
	!set:
	sta screen2,x
	sec 
	sbc #$08
	!set2:
	sta screen1,x
	ldy !add- +1
	iny
	tya
	and #%00000111
	sta !add- +1
	inx
	cpx #$28
	bne !a-
	lda !a- +1
	clc
	adc #$10
	and #%01111111
	sta !a- +1
	lda !set- +1
	clc
	adc #$28
	bcc !+
	inc !set- +2
	inc !set2- +2
	!:
	sta !set- +1
	sta !set2- +1
	dec $11
	bne !b-
	//jsr createSpeedCode
	lda #$00
	sta $d01c
	sta $d017
	sta $d01d
	sta $d015
	sta $d010
	lda #$ff
	sta $d01b
	ldx #$06
	!:


	lda #0//#$04 + 8*8 - 20
	sta $d000,x
	lda #$3a + 8*8
	sta $d001,x
	dex
	dex
	bpl !-

	lda #$00
	sta waitForIRQ
	lda #$01
	sta $d02a
	lda #$02
	sta $d029
	lda #$0f
	sta $d028
	lda #$06
	sta $d027
	ldx #$00
	lda # $3d00/64 +3
	!:
	sta screen2 + $03f8,x
	sta screen1 + $03f8,x
	sec
	sbc #$01
	inx
	cpx #$04
	bne !-
	f $d011 : $1b
	f $d012 : $01

	f16 $fffe : IRQ	
	#if release
	lda #$7f
	sta $dc0d
	lda $dc0d
	lda #$01
	sta $d019
	sta $d01a
	cli
	#endif
	jsr waitframe
	jsr waitvblank
	
	f16 $d020 : $0801
	lda #$8*8
	sta charoffset
	lda #$00
	sta bankswitch
	//:SetScreenAndCharLocation(screen1, $2000)
	//:SetScreenMode(SCREENMODE_HIRES_TEXT)
	lda #$ff
	sta counter3

.pc = * "bgthread"
bgthread:
	
	lda #$34
	sta $01
	lda #$00
	sta charoffset
	jsr create
	lda #$8*8
	sta charoffset
	jsr create
	lda #$35
	sta $01
	jsr waitvblank
	lda #$03
	sta $dd00
	jsr render
	
	ldx #<blob2
	ldy #>blob2
	jsr prepareData	

	lda #$06
	sta $d021
	jsr render
	ldx #<blob4
	ldy #>blob4
	jsr prepareData	
	lda #$04
	sta $d021
	jsr render
	ldx #<blob3
	ldy #>blob3
	jsr prepareData	
	lda #$0a
	sta $d021
	lda #$1





	sta counter3
	lda #$01
	sta moveSprite +1
	lda #%00001111
	sta $d015

	jsr render
	lda #$46
	sta counter3
	jsr render
	

	jsr render2
	jsr waitvblank
	lda #$0f
	sta $d021
	f charset : charset+8 : 0
	f screen1 : screen1 + $03e8 : 0
	f screen2 : screen2 + $03e8 : 0
	f $d800 : $d800 + $03e8 : $f
	m $3d00 : $3d00 + $40*4 : (screen1 + $40)
	:SetScreenAndCharLocation(screen2, charset)



	ldx #$00
	lda # (screen1 + $40)/64 + 3
	!:
	sta screen2 + $03f8,x
	sta screen1 + $03f8,x
	sec
	sbc #$01
	inx
	cpx #$04
	bne !-




	#if !release
	jmp *
        #else
	ldx #$40
stcp:	lda stack,x
	sta $0100,x
	dex
	bpl stcp
	//sei
	jmp $0100
stack:
	

	jsr link_load_next_comp
	jsr link_load_next_comp
	jsr link_load_next_raw
   !:
    //inc $d020
    
     
    lda waitForIRQ
    beq !-
    


	jmp link_exit
	#endif
//	jsr render
//	jsr render

render:
jsr waitframe
jsr switchAndCreate
dec counter3
bne render
rts
clearCount:
.byte 0
render2:
jsr waitframe
jsr switchAndCreate
lda #$ff
ldx clearCount
.for(var t = 0;t<16;t++){
sta blobLookup + t*$100,x
sta blobLookup +1 + t*$100,x
}
inc clearCount
inc clearCount
dec counter3
lda counter3
cmp #$7f
bne render2
rts

switchAndCreate:
	
	//jmp *-3
	lda bankswitch
	and #$01
	beq !+
	lda #$0
	sta charoffset
	:SetScreenAndCharLocation(screen2, charset)
	jmp !c+
	!:

	lda #$8*8
	sta charoffset
	:SetScreenAndCharLocation(screen1, charset)
	
	!c:
	inc bankswitch
	//inc $d020
	lda #$34
	sta $01
	jsr create
	lda #$35
	sta $01

	//dec $d020
	rts
//#if !release
.pc = * "IRQ"
fadeCount:
.byte $07
fadeD020:
.byte $0,$0,$9,$8,$a,$f,$7,$1
fadeD021:
.byte $b,$b,$b,$8,$a,$f,$f,$f
/*
.byte $0,$0,$0,$0,$0,$0,$0,$0
.byte $0,$0,$0,$0,$0,$0,$0,$0
.byte $0,$0,$0,$0,$0,$0,$0,$0
.byte $0,$0,$0,$0,$0,$0,$0,$0
.byte $b,$0,$b,$b,$c,$b,$c,$c
.byte $f,$c,$f,$f,$1,$1,$1,$1
.byte $1,$1,$1,$1,$1,$f,$1,$1
.byte $1,$1,$1,$1,$1,$f,$1,$1*/




/*
.byte $b,$b,$c,$b,$c,$c,$f,$c
.byte $f,$f,$c,$f,$c,$c,$b,$c
.byte $b,$b,$0,$0,$0,$0,$0,$0
.byte $0,$0,$0,$0,$0,$0,$0,$0
.byte $b,$0,$b,$b,$c,$b,$c,$c
.byte $f,$c,$f,$f,$1,$f,$f,$f
.byte $f,$f,$f,$f,$f,$f,$f,$f
.byte $f,$f,$f,$f,$f,$f,$f,$f*/

movesprites:
inc $d000
lda $d000
cmp #$2e + 8*8 -8

bne !+
lda #$00
sta $d01b
!:
inc $d002
inc $d004
inc $d006
bne !+
lda #$ff
sta $d010
!:
lda $d000
cmp #0+80 + 16 + 25
bne !+
lda $d010
cmp #$ff
bne !+
lda #$00
sta moveSprite +1
lda #$01 
sta doFade +1
!:
rts
fadeout:
	lda #$00
	inc fadeout + 1
	and #$03
	bne skipit2
	ldx fadeCount
	lda fadeD020,x
	sta $d020
	lda fadeD021,x
	sta $d021
	cmp #$0a
	bne skipit
	lda #$07
	sta $d016
	lda #$17
	sta $d011
skipit:
	dec fadeCount
	bne !+
	inc fadeCount
	lda #$00
	sta doFade +1
	#if release
		lda #$01
		sta waitForIRQ
		
	#endif
	#if !release
		!b:
		inc $d020
		jmp !b-
	#endif
	!:
skipit2:
	rts
IRQ:
	jsr push
	lda #$35
	sta $01
	//inc $d020
	//jsr music_play
	//dec $d020
	moveSprite:
	lda #$00
	beq !a+
	jsr movesprites
	!a:
	doFade:
	lda #$00
	beq !+
	jsr fadeout
	!:
	//:break()
	inc framecount	
	inc $d019
	jsr pop
	rti
//#endif


.align $100
.pc = * "sines"
sine2:
.fill 256,round(67.5+67.5*sin(toRadians(i*360/256))) & $3f

sine:
.fill 256,(round(47.5+47.5*sin(toRadians(i*360/160))) + round(27.5+27.5*sin(toRadians(i*360/80)))) & $3f

.pc = * "blob 2"
blob2:
.for(var x = 0;x<33;x++){
	.for(var y = 0;y<33;y++){

		.byte( squareWeight(x,y,1))
	}
}
.pc = * "create"
create:
tsx
stx stackpointer
ldx charoffset
txs
.var counter1 = sinep1 + 1
.var counter2 = sinep2 + 1
sinep1:
ldy sine + $72
sinep2:
ldx sine2 + $6c
dec counter2
inc counter1
lda counter1
cmp #160
bne !+
lda #$00
sta counter1
!:
stx sineValue2
sty sineValue1



.pc = * "start_render"
lda #$34
sta $01
clc
jmp speedCodeStart
create_back:
lda #$35
sta $01
ldx stackpointer
txs
rts

.function squareWeight(x,y, factor){
	.var d = 0//16
	.var px =32+d
	.var py = 32+d
	// square
	.var dist = 1/(abs(px-x) + abs(py-y))//1/((px-x)*(px-x) + (py-y)*(py-y))
	.var w = 2880*dist*factor

	.if(w >255){
		.eval w = 255
	}
	.if(w<0){
		.eval w = 0
	}
	.return 255-w
}

.function weight(x,y, factor){
	.var d = 0//16
	.var px =32+d
	.var py = 32+d
	.var px2 = 60+d
	.var py2 = 60+d



	// square
	/*.var dist = 1/(abs(px-x) + abs(py-y))//1/((px-x)*(px-x) + (py-y)*(py-y))
	.var w = 2880*dist*/


	// circle
	.var dist = 1/((px-x)*(px-x) +(py-y)*(py-y))
	//.if(dist>0.009){
	//	.eval dist = dist*0.1;
	//}
	.var w = 45800*dist*factor



	// eclipse
	/*.var dist = 1/(1.5*(px-x)*(px-x) + (py-y)*(py-y))
	.var w = 45800*dist
*/
	
	.if(w >255){
		.eval w = 255
	}

	

	.return 255-w
}

.function weight2(x,y, factor){
	.var d = 0//16
	.var px =32+d
	.var py = 32+d
	.var px2 = 60+d
	.var py2 = 60+d



	// square
	/*.var dist = 1/(abs(px-x) + abs(py-y))//1/((px-x)*(px-x) + (py-y)*(py-y))
	.var w = 2880*dist*/


	// circle
	.var dist = 1/((px-x)*(px-x) +(py-y)*(py-y))
	//.if(dist>0.009){
	//	.eval dist = dist*0.1;
	//}
	.var w = 45800*dist*factor



	// eclipse
	/*.var dist = 1/(1.5*(px-x)*(px-x) + (py-y)*(py-y))
	.var w = 45800*dist
*/
	
	.if(w >255){
		.eval w = 255
	}

	.var v = 10800*dist*factor
	.if(v >255){
		.eval v = 255
	}
	.eval w = w-v
	.if(w<0) .eval w=0
	/*.if(w > 250){
		.eval w = w - (w-255)*1.5
	}*/
	.if(w<0){
		.eval w = 0
	}

	.return 255-w
}

prepareData:
stx !a+ +1
sty !a+ +2

lda #<(blobLookup)
sta !b+ +1
lda #>(blobLookup)
sta !b+ +2
lda #<(blobLookup+ $20)
sta !c+ +1
lda #>(blobLookup+ $20)
sta !c+ +2
lda #<(blobLookup+ 64*65)
sta !d+ +1
lda #>(blobLookup+ 64*65)
sta !d+ +2
lda #<(blobLookup+ 64*65 + $20)
sta !e+ +1
lda #>(blobLookup+ 64*65 + $20)
sta !e+ +2
lda #$21
sta byteHolder1
!restart:
ldx #$00
ldy #$20
!a:
lda blob,x//overwritten 10 lines over

!b:
sta blobLookup,x //overwritten 10 lines over
!c:
sta blobLookup + $20,y//overwritten 10 lines over
!d:
sta blobLookup + 64*65 ,x//overwritten 10 lines over
!e:
sta blobLookup + 64*65 + $20,y//overwritten 10 lines over
inx
dey
bpl !a-
:addToLabel($21, !a-)
:addToLabel($41, !b-)
:addToLabel($41, !c-)
:subFromLabel($41, !d-)
:subFromLabel($41, !e-)
dec byteHolder1
bne !restart-
rts
/*
.pc = $f800
.import c64 "data.bin"
*/
.pc = $23f0 "blob"
blob:
.for(var x = 0;x<33;x++){
	.var str = "";
	.for(var y = 0;y<33;y++){
		.byte( weight(x,y,1.5))
		//.eval str = str + ", " +  round(weight(x,y));
	}
	//.print(str)
}


/* remove comment to use uncompressed
.pc = $3280
.import c64 "createLoop.prg"
createSpeedCode:
jmp create_back
*/


.pc = codeRenderBeforeMoved "coderenderBeforeMoved"
.import source "codeGeneratorOutput.asm"

.pc = blob3 "blob3and4 before move"

//blob3:
.for(var x = 0;x<33;x++){
	.for(var y = 0;y<33;y++){

		.byte( weight(x,y,1))
	}
}
//blob4:
.for(var x = 0;x<33;x++){
	.for(var y = 0;y<33;y++){

		.byte( weight2(x,y,3))
	}
}





