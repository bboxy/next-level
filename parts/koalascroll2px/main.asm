.var startbufferrender = 37
.var charsInSecondKoala = 64
.var framecount = $02
.var d016count = $81
.var screenBufferCount = $82
.var tileSize = $83

.var screenBufferCount2 = $84

.var screenBufferCount3 = $85

.var screenBufferCount4 = $86

.var screenBufferCount5 = $87

.var tileCounter = $88

.var zpa = $89
.var zpx = $8a
.var zpy = $8b
.var zp1 = $8c

#if release
.var link_exit = cmdLineVars.get("link_exit").asNumber();
.import source "../../bitfire/macros/link_macros_kickass.inc"
.import source "../../bitfire/loader/loader_kickass.inc"
#endif

/*
bitmapBufferCount:
.byte 0
screenBufferCount:
.byte 0
colorRamBufferCount:
.byte $02
*/


#if !release
.var music = LoadSid("assets/JammicroV1_FinallyAsleepSID (9).sid")
	.var music_init = music.init
	.var music_play = music.play
	*=music.location "Music"
    //.fill music.size, music.getData(i)
.pc = $0801 "Basic Upstart"
:BasicUpstart(init)
#endif


.macro SetScreenAndCharLocation(screen, charset) {
	lda	#[[screen & $3FFF] / 64] | [[charset & $3FFF] / 1024]
	sta	$D018
}
// $DD00 = %xxxxxx11 -> bank0: $0000-$3fff
// $DD00 = %xxxxxx10 -> bank1: $4000-$7fff
// $DD00 = %xxxxxx01 -> bank2: $8000-$bfff
// $DD00 = %xxxxxx00 -> bank3: $c000-$ffff
.macro SetVICBank0() {
	lda $DD00
	and #%11111100
	ora #%00000011
	sta $DD00
}

.macro SetVICBank1() {
	lda $DD00
	and #%11111100
	ora #%00000010
	sta $DD00
}

.macro SetVICBank2() {
	lda $DD00
	and #%11111100
	ora #%00000001
	sta $DD00
}

.macro SetVICBank3() {
	lda $DD00
	and #%11111100
	ora #%00000000
	sta $DD00
}





.macro moveD800(buffer1, buffer2){
	//inc $d020
	ldx screenBufferCount

	.for(var y = 0;y<5;y++){
		.for(var x = 0;x<39;x++){
			.if(x != startbufferrender+1){
				lda $d801 + y*40 + x
				sta $d800 + y*40 + x
			}
			else
			{
				.var buffer = buffer1
				.var addRow = y/2
				
				.if(mod(y,2) == 0){
					ldy buffer + addRow*(charsInSecondKoala),x
					sty $d800 + startbufferrender+1 + y*40

				}
				else{
					lda d800Lookup,y
					sta $d800 + startbufferrender+1 + (y)*40
				}
			}
			
		}
		
	}	
	ldx screenBufferCount2

	.for(var y = 5;y<10;y++){
		.for(var x = 0;x<39;x++){
			.if(x != startbufferrender+1){
				lda $d801 + y*40 + x
				sta $d800 + y*40 + x
			}
			else
			{
				.var buffer = buffer1
				.var addRow = y/2
				
				.var first = 5
				.if(y == first){
					.eval addRow = (y-1)/2
					ldy buffer + addRow*(charsInSecondKoala),x
					lda d800Lookup,y
					sta $d800 + startbufferrender+1 + (y)*40
				}
				else{
					.if(mod(y,2) == 0){
						ldy buffer + addRow*(charsInSecondKoala),x
						sty $d800 + startbufferrender+1 + y*40
					}
					else{
						
						lda d800Lookup,y
						sta $d800 + startbufferrender+1 + (y)*40
						
					}

				}
				
			}
			
		}
		
	}	

	ldx screenBufferCount3

	.for(var y = 10;y<15;y++){
		.for(var x = 0;x<39;x++){
			.if(x != startbufferrender+1){
				lda $d801 + y*40 + x
				sta $d800 + y*40 + x
			}
			else
			{
				.var buffer = buffer1
				.var addRow = y/2
				
				.if(mod(y,2) == 0){
					ldy buffer + addRow*(charsInSecondKoala),x
					sty $d800 + startbufferrender+1 + y*40

				}
				else{
					
					lda d800Lookup,y
					sta $d800 + startbufferrender+1 + (y)*40
				}
			}
			
		}
		
	}	

	ldx screenBufferCount4

	.for(var y = 15;y<20;y++){
		.for(var x = 0;x<39;x++){
			.if(x != startbufferrender+1){
				lda $d801 + y*40 + x
				sta $d800 + y*40 + x
			}
			else
			{
				.var buffer = buffer1
				.var addRow = y/2
				
				.var first = 15
				.if(y == first){
					.eval addRow = (y-1)/2
					ldy buffer + addRow*(charsInSecondKoala),x
					lda d800Lookup,y
					sta $d800 + startbufferrender+1 + (y)*40
				}
				else{
					.if(mod(y,2) == 0){
						ldy buffer + addRow*(charsInSecondKoala),x
						sty $d800 + startbufferrender+1 + y*40
					}
					else{
						
						lda d800Lookup,y
						sta $d800 + startbufferrender+1 + (y)*40
						
					}

				}
			}
			
		}
		
	}	

	ldx screenBufferCount5

	.for(var y = 20;y<25;y++){
		.for(var x = 0;x<39;x++){
			.if(x != startbufferrender+1){
				lda $d801 + y*40 + x
				sta $d800 + y*40 + x
			}
			else
			{
				.var buffer = buffer1
				.var addRow = y/2
				.if(y>21){
					.eval buffer = buffer2
					.eval addRow -= 11
				}
				.if(mod(y,2) == 0){
					ldy buffer + addRow*(charsInSecondKoala),x
					sty $d800 + startbufferrender+1 + y*40

				}
				else{
					.if(y != 24){
						lda d800Lookup,y
						sta $d800 + startbufferrender+1 + (y)*40
					}

				}
			}
			
		}
		
	}	

	
	inc screenBufferCount5
	inc screenBufferCount4
	inc screenBufferCount3
	inc screenBufferCount2
	inc screenBufferCount
	dec tileSize
	bne !+
	ldx tileCounter
	lda tiles1,x
	sta screenBufferCount
	lda tiles2,x
	sta screenBufferCount2
	lda tiles3,x
	sta screenBufferCount3
	lda tiles4,x
	sta screenBufferCount4
	lda tiles5,x
	sta screenBufferCount5
	lda tileSizes,x
	sta tileSize
	//inc tileCounter
	//lda tileCounter
	inx 
	txa
	and #%01111111
	sta tileCounter
	dec partcounter
	bne !+
	lda #$01
	sta endFlag
	//stx screenBufferCount
	!:
	
	
	//dec $d020
}

.pc = $0810 "tiles"
tiles1:
tiles2:
tiles3:
tiles4:
tiles5:
.byte 6,12,18,24,30,36,42,48,54,12,18,24,30,36,42,48,54,12,18,24,30,36,42,48,54,12,18,24,30,36,42,48,54
.fill 11, 60

tileSizes:
.fill 40-9, 6
.fill 11,4

partcounter:
.byte 52-9


.pc = $bfc0 "times4Loookup"
times4Loookup:
.fill 256/4, i*4

//.import source "framework.asm"

.var bitmap0 = $a000// shift 8 px
.var bitmap1 = $c000// shift 16 px
.var bitmap2 = $2000// shift 8 px
.var bitmap3 = $4000// shift 16 px

.var screen0 = $8c00
.var screen1 = $e000
.var screen2 = $0400
.var screen3 = $6000

#if !release
.var picture = LoadBinary("assets/tiles1.kla", BF_KOALA)
*=screen1 "screen1";            .fill picture.getScreenRamSize() /*- 40*3*/, picture.getScreenRam(i)
//.fill 40*3, 0
*=bitmap0 "bitmap0"; colorRam:  .fill picture.getColorRamSize() /*- 40*3*/, picture.getColorRam(i)
.fill 40*8*25 - picture.getColorRamSize(), 0
//.fill 40*3, 0
*=bitmap1 "bitmap1";            .fill picture.getBitmapSize() /*- 40*8*3*/, picture.getBitmap(i)
#endif

*=bitmap2 "bitmap2" virtual
.fill 40*8*25, 0
*=bitmap3 "bitmap3" virtual
.fill 40*8*25, 0

*=screen3 "screen3" virtual
.fill 40*25, 0
*=screen2 "screen2" virtual
.fill 40*25, 0
*=screen0 "screen0" virtual
.fill 40*25, 0

/*
*=bitmap0 + $1c00; .fill 20*8*3, 0
//*=bitmap1 + $1c00; .fill 20*8*3, 0
*=bitmap2 + $1c00; .fill 20*8*3, 0
*=bitmap3 + $1c00; .fill 20*8*3, 0
*/ 




*=bitmap3 + 40*25*8 "Init"
init:
sei
lda #12
sta d016count

lda #$00
sta tileCounter

lda #$6
sta tileSize

ldx #$0
stx screenBufferCount

ldx #$0
stx screenBufferCount2

ldx #$0
stx screenBufferCount3


ldx #$0
stx screenBufferCount4

ldx #$0
stx screenBufferCount5

lda #$35
sta $01
#if !release
lda #$f6
sta $d016
lda #$0b
sta $d011
lda #0
sta $d020
tax
tay
//jsr music_init


lda #picture.getBackgroundColor()
sta $d021
ldx #0
!loop:
.for (var i=0; i<3; i++) {
   lda colorRam+i*$100,x
   sta $d800+i*$100+0 ,x
}
lda colorRam+$2f0,x
sta $d800+$2f0 +0,x
inx
bne !loop-
#endif
jsr move15
#if !release
:SetScreenAndCharLocation(screen1, bitmap1)
:SetVICBank3()
#endif

jsr waitframe2
lda #$3b
sta $d011
ldx #$c0-$84 + $a//#$d8
!:
jsr waitframe2
#if release
//jsr link_music_play_side4_micro
#endif
#if !release
//jsr music_play
#endif
dec !- -1
bne !-
lda #<IRQ1
sta $fffe
lda #>IRQ1
sta $ffff
lda #$fb
sta $d012
lda #$7f
sta $dc0d
lda $dc0d
#if !release
sta $dd0d
lda $dd0d
#endif
lda #$01
sta $d019
sta $d01a
cli
jmp bgthread

*= bitmap2 + 40*8*25 "IRQ"
.import source "irq.asm"


.pc = $ea40 "Bgthread"
bgthread:

.import source "bgthread.asm"

waitframe2:
jsr !+
jsr !+
lda $d012
cmp #$f9
bne waitframe2
!:
rts


.pc = $63e8 "move colorram"

moveColorRam:
lda tableD018,x
sta $d018
lda tableDD00,x
sta $dd00
:moveD800(bufferColorRam, bufferColorRam2)
endIRQ:
lda zp1
sta $01
lda zpa
ldx zpx
ldy zpy
rti

.pc = $0900 "d800Lookup"

d800Lookup:
.fill $100, (i >>4)


.function addressBitmap(y){
	.if(y<16){
		.return bufferbitmap1 + y*charsInSecondKoala*4
	}
	.if(y<32){
		.eval y = y-16
		.return bufferbitmap2 + y*charsInSecondKoala*4
	}
	.eval y = y-32
	.return bufferbitmap3 + y*charsInSecondKoala*4
}
.var bufferpic = LoadBinary("assets/tiles2.kla", BF_KOALA)
.var bufferpic2 = LoadBinary("assets/tiles3.kla", BF_KOALA)

.pc = $7c00 "bufferbitmap1"

bufferbitmap1:
.for(var y = 0;y<8;y++){
	.for(var t = 0;t<40;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic.getBitmap(t*8+i + y*8*40)
		}
	}
	.for(var t = 40;t<charsInSecondKoala;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic2.getBitmap((t-40)*8+i + y*8*40)
		}
	}
	

	.for(var t = 0;t<40;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic.getBitmap(t*8+i +4 + y*8*40)
		}
	}
	.for(var t = 40;t<charsInSecondKoala;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic2.getBitmap((t-40)*8+i+4 + y*8*40)
		}
	}
	
}
.pc = $9000 "bufferbitmap2"
bufferbitmap2:
.for(var y = 8;y<16;y++){
	.for(var t = 0;t<40;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic.getBitmap(t*8+i + y*8*40)
		}
	}
	.for(var t = 40;t<charsInSecondKoala;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic2.getBitmap((t-40)*8+i + y*8*40)
		}
	}
	

	.for(var t = 0;t<40;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic.getBitmap(t*8+i +4 + y*8*40)
		}
	}
	.for(var t = 40;t<charsInSecondKoala;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic2.getBitmap((t-40)*8+i+4 + y*8*40)
		}
	}
}
.pc = $0b00 "bufferbitmap3"
bufferbitmap3:
.for(var y = 16;y<25;y++){
	.for(var t = 0;t<40;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic.getBitmap(t*8+i + y*8*40)
		}
	}
	.for(var t = 40;t<charsInSecondKoala;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic2.getBitmap((t-40)*8+i + y*8*40)
		}
	}

	.for(var t = 0;t<40;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic.getBitmap(t*8+i +4 + y*8*40)
		}
	}
	.for(var t = 40;t<charsInSecondKoala;t++){
		.for(var i=0;i<4;i++){
			.byte bufferpic2.getBitmap((t-40)*8+i+4 + y*8*40)
		}
	}
}

.var cols = List().add($11,$22, $33)
.pc = $e400 "bufferscreenram"
bufferScreenRam:
.for(var t = 0;t<25;t++){

	.fill 40, bufferpic.getScreenRam(i + t*40)//cols.get(mod(i, 3))//

	.fill charsInSecondKoala -40, bufferpic2.getScreenRam(i + t*40)
	//.fill 3, picture.getScreenRam(i + t*40)
}

.function combineD800(v1, v2){
	.eval v1 = v1 & $0f
	.eval v2 = (v2<<4) & $f0
	.return v1 | v2

}
.pc = $1d00 "buffercolorram"//$2000 - (charsInSecondKoala+2)*13 - 3 - $100

bufferColorRam:
.for(var t = 0;t<22;t+=2){
	.fill 40, combineD800(bufferpic.getColorRam(i + t*40), bufferpic.getColorRam(i + (t+1)*40))
	.fill charsInSecondKoala -40, combineD800(bufferpic2.getColorRam(i + t*40), bufferpic2.getColorRam(i + (t+1)*40))
}
.pc = bitmap0 + 40*25*8 "buffercolorram2"
bufferColorRam2:
.var t = 22 
.fill 40, combineD800(bufferpic.getColorRam(i + t*40), bufferpic.getColorRam(i + (t+1)*40))
.fill charsInSecondKoala -40, combineD800(bufferpic2.getColorRam(i + t*40), bufferpic2.getColorRam(i + (t+1)*40))
.eval t = 24
.fill 40, combineD800(bufferpic.getColorRam(i + t*40), bufferpic.getColorRam(i + (t)*40))
.fill charsInSecondKoala -40, combineD800(bufferpic2.getColorRam(i + t*40), bufferpic2.getColorRam(i + (t)*40))





//*=screen1;            .fill picture.getScreenRamSize() /*- 40*3*/, picture.getScreenRam(i)
//*=bitmap0; colorRam:  .fill picture.getColorRamSize() /*- 40*3*/, picture.getColorRam(i)
//*=bitmap1;            .fill picture.getBitmapSize() /*- 40*8*3*/, picture.getBitmap(i)
