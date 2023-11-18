.const col1 = 1
.const col2 = 15
.const col3 = 14
.const col4 = 6
.const col5 = 0

///////////////////////////////////////////////////////////////////////////////////

//.pc =$0801 "Basic Upstart Program"
//:BasicUpstart(start)

///////////////////////////////////////////////////////////////////////////////////

#if release
.var link_exit = cmdLineVars.get("link_exit").asNumber();
.import source "../../bitfire/loader/loader_kickass.inc"
//.import source "../../bitfire/macros/link_macros_kickass.inc"
#endif


.pc = $2000
					// This has to be .align $800 to fit in a font bank
					// It is a lie, it can also be aligned to other values and we can make use of an char offset :-D Faker
.pc = * "screen"
screen:
.const charset = screen + $0400
.const char_off = (charset & $3fff)/ 8
				.fill $3f8,char_off + 4
				.fill 8,sprites/64+2

.pc = * "charset"
					.import c64 "assets/charset_box.prg"


performerscolors:	.byte 9,9,2,2,8,8,10,10,15,15,7,7,1,1,7,7,15,15,10,10,8,8,2,2,9,9
					.fill 20,col5

wormcolors:			.byte col4,col4,col3,col3,col2,col2,col1,col1,col1
					.fill 20,col1
wormcolorsreverse:	.byte col1,col1,col2,col2,col3,col3,col4,col4,col5
					.fill 20,col5

.pc = * "sprites"
sprites:			.fill 16,[255,255,255] //48
					.fill 5,[0,0,0]
					.byte 0

					.fill 16,[255,255,%11110000] //40
					.fill 5,[0,0,0]
					.byte 0

					.fill 16,[255,255,%00000000] //32 + 16unexp
					.fill 5,[0,0,0]
					.byte 0

					.pc = * "Main Program"
start:
					lda #col5
					sta $d020
					lda #col5
					sta $d021
					ldx #0
!:					sta $d800,x
					sta $d900,x
					sta $da00,x
					sta $daf8,x
					inx
					bne !-
					lda #col1
					sta $d027
					sta $d028
					lda #col2
					sta $d029
					sta $d02a
					lda #col3
					sta $d02b
					sta $d02c
					lda #col4
					sta $d02d
					sta $d02e
					txa
					sta $d017
					sta $d01d
					sta $d01b
					sta $d01c
					ldx #$10
!:					sta $d000,x
					dex
					bpl !-
					stx $d015

					sei
					lda #$35
					sta $01
#if !release
					lda #$7f
					sta $dc0d
					sta $dd0d
					lda $dc0d
					lda $dd0d
#endif
					lda #$01
					sta $d019
					sta $d01a
					lda #0
              				sta $d011
					ldx #<irq0
					ldy #>irq0
					sta $d012
					stx $fffe
					sty $ffff
					cli
#if release
					jsr link_load_next_raw
					dec $01
					jsr link_decomp
					inc $01
					jsr link_load_next_comp
					jsr link_load_next_comp
					//jsr link_load_next_raw
					ldx #$00
!:
					lda stackcode,x
					sta $0100,x
					inx
					cpx #stackcode_end-stackcode
					bne !-
#endif
!:					lda FLAG_ExitPart
					beq !-
					sei
					ldx #$00
					stx $d011
//!:
					jsr WaitForRetrace
//					jsr WaitForRetrace
//					jsr WaitForRetrace
//					lda colorslast,x
//					sta $d020
//					inx
//					cpx #$06
//					bne !-
#if release
					jmp $0100
stackcode:
					//jsr link_decomp
					jmp link_exit
stackcode_end:
#else
					inc $d020 // Exit part ... you need to restore IRQ and blank the screen here ;)
					jmp *-3
#endif
colorslast:
					.byte $01,$0d,$03,$0e,$04,$06

//////////////////////////////////////////////////////////////////////////////////////////////////////////

FLAG_VSYNC:			.byte 0
FLAG_ExitPart:		.byte 0
FLAG_EnableJumper:	.byte 1 //1
FLAG_EnableStretch:	.byte 0
FLAG_EnableRasters:	.byte 0
FLAG_EnableBeamIRQ:	.byte 0

//////////////////////////////////////////////////////////////////////////////////////////////////////////

PlayMusic:			rts

//////////////////////////////////////////////////////////////////////////////////////////////////////////

irq0:				BeginIRQ()
					lda #1
					sta FLAG_VSYNC
Bankdd00:			lda #$3
					sta $dd00
Bankd018:			lda #((screen & $3fff)/$0400 <<4) + ((charset & $3fff) / $400)
					sta $d018
					lda #$c8
					sta $d016
					lda #$1b
					sta $d011

					lda #$ff
					sta $d015

					lda FLAG_EnableHorizontal
					bne EnableHorizontal
					lda FLAG_EnableJumper
					bne EnableJumper
					jmp StackRTI

EnableHorizontal:	NextIRQ(irqHorizontaltop,146)

EnableJumper:		NextIRQ(irqJumper2,248)

//////////////////////////////////////////////////////////////////////////////////////////////////////////

irqHorizontaltop:	BeginIRQ()
					ldx #3
					dex
					bpl *-1
horiborder:			lda #col5
					sta $d020
lowerraster:		ldy #162
					lda #<irqHorizontalbottom
					ldx #>irqHorizontalbottom
					jmp IRQSetAXYRTI

irqHorizontalbottom:
					BeginIRQ()
					ldx #3
					dex
					bpl *-1
topbotbordercol:	lda #col5
					sta $d020
					jsr PlayMusic
disable:			jsr MoveHorizontal
					lda Flag_Boxes
					beq !+
					jsr Boxes
!:
upperraster:		ldy #146
					lda #<irqHorizontaltop
					ldx #>irqHorizontaltop
					jmp IRQSetAXYRTI

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Flag_Boxes:			.byte 0
					
Boxes:				lda upperraster+1
					cmp #50
					beq !+
					dec upperraster+1
!:
					lda lowerraster+1
					cmp #250
					beq finalboxes
					inc lowerraster+1
					rts
finalboxes:			ldx #0
					beq upperrightbox
					dex
					beq JMPlowerleftbox
					dex
					beq JMPRemovePERFBoxes
					rts
JMPlowerleftbox:	jmp lowerleftbox
JMPRemovePERFBoxes:	jmp RemovePERFBoxes

upperrightbox: {		ldx #18
!:					.for(var i=0; i<11; i++) {
						lda $d814+(i*40),x
						sta $d815+(i*40),x
					}
					dex
					bpl !-
cnt:				ldx #0
					lda wormcolors,x
					.for(var i=0; i<11; i++) {
						sta $d800+20+(i*40)
					}
					lda cnt+1
					cmp #26
					beq !+
					inc cnt+1
					rts
!:					//lda #1
					inc finalboxes+1
					rts
}

lowerleftbox: {		ldx #0
!:					.for(var i=15; i<25; i++) {
						lda $d801+(i*40),x
						sta $d800+(i*40),x
					}
					inx
					cpx #19
					bne !-
cnt:				ldx #0
					lda wormcolors,x
					.for(var i=15; i<25; i++) {
						sta $d800+(i*40)+19
					}
					lda cnt+1
					cmp #25
					beq !+
					inc cnt+1
					rts
!:					//lda #2
					inc finalboxes+1
					rts
}

RemovePERFBoxes:	ldx #79
					lda #char_off + 4
!:					sta screen+480,x
					dex
					bpl !-
					inx
!:					lda $d800+480+1,x
					sta $d800+480,x
					lda $d800+520+1,x
					sta $d800+520,x
					inx
					cpx #20
					bne !-
					ldx #18
!:					lda $d800+480+20,x
					sta $d800+480+20+1,x
					lda $d800+520+20,x
					sta $d800+520+20+1,x
					dex
					bpl !-
cnt:				lda #0
					cmp #25
					beq !+
					inc cnt+1
					rts
!: {
cnt:				ldx #0
					lda wormcolors,x
					sta topbotbordercol+1
					lda cnt+1
					cmp #20
					beq Done
					inc cnt+1
					rts
Done:				lda #1
					sta FLAG_ExitPart
					rts
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////

FLAG_EnableHorizontal:	.byte 0
Flag_worms:				.byte 0

MoveHorizontal:		lda Flag_worms
					beq !+
					jmp Worms
!:					
killhori:			//lda #0
					sta $d015
					lda #col1
					sta $d800+480+19
					sta $d800+520+19
					sta $d800+480+20
					sta $d800+520+20

FadeinHor:			ldx #0
					lda fadeincols,x
					sta horiborder+1
					lda fadeincols+8,x
					ldy #4
!:					sta $d800+480+1,y
					sta $d800+520+1,y
					sta $d800+480+34,y
					sta $d800+520+34,y
					dey
					bpl !-
					lda fadeincols+16,x
					ldy #2
!:					sta $d800+480+7,y
					sta $d800+520+7,y
					sta $d800+480+30,y
					sta $d800+520+30,y
					dey
					bpl !-

					lda fadeincols+24,x
					ldy #2
!:					sta $d800+480+11,y
					sta $d800+520+11,y
					sta $d800+480+26,y
					sta $d800+520+26,y
					dey
					bpl !-

					lda fadeincols+32,x
					ldy #2
!:					sta $d800+480+15,y
					sta $d800+520+15,y
					sta $d800+480+22,y
					sta $d800+520+22,y
					dey
					bpl !-

					inx
					cpx #33+12
					beq !+
					inc FadeinHor+1
					rts
!:					lda #$60
					sta killhori
					lda #1
					sta Flag_worms
					rts

fadeincols:			.fill 32,col5
					.fill 4,col4
					.fill 4,col3
					.fill 4,col2
					.fill 33,col1

Worms:				lda wormcontroller
					beq across
					cmp #1
					bne !+
					jmp performers
!:					lda #1
					sta Flag_Boxes
					lda #$ea 
					sta disable
					sta disable+1
					sta disable+2
					rts
across:				ldx #0
!:					lda $d800+440+1,x
					sta $d800+440,x
					lda screen+440+1,x
					sta screen+440,x
					inx
					cpx #39
					bne !-
					ldx #38
!:					lda $d800+560,x
					sta $d800+560+1,x
					lda screen+560,x
					sta screen+560+1,x
					dex
					bpl !-
wcnt1:				ldx #0
					lda wormchars,x
					sta screen+560
					sta screen+479
					lda wormcolors,x
					sta $d800+560
					sta $d800+479
					lda wcnt1+1
					cmp #7
					beq wcnt1done
					inc wcnt1+1
					rts
wcnt1done:			lda #0
					cmp #40
					beq !+
					inc wcnt1done+1
					dec upperraster+1
					inc lowerraster+1
					rts
!:					lda #1
					sta wormcontroller
					rts

wormcontroller:		.byte 0

wormchars:			.byte char_off + $1,char_off + $1,char_off + $2,char_off + $2,char_off + $3,char_off + $3,char_off + $4,char_off + $4

					//     P  E  R  F  O  R  M  E  R  S
letters:				.byte char_off + $5,char_off + $6,char_off + $7,char_off + $8,char_off + $9,char_off + $7,char_off + $a,char_off + $6,char_off + $7,char_off + $b

ShowPerformers:
					lxa #0
					tay
					clc
!:
					lda letters,x
					sta screen+480+6,y
					adc #7
					sta screen+520+6,y
					iny
					iny
					iny
					inx
					cpx #$0a
					bne !-

					ldx #24
!:
					lda $d800+520+6,x
					sta $d800+480+9,x
					sta $d800+520+9,x
					dex
					dex
					dex
					bpl !-

EnableBox2:			lda #0
					bne Box2
					ldx #19
!:					lda $d828,x
					sta $d800,x
					lda $d828+40,x
					sta $d800+40,x
					lda $d828+80,x
					sta $d800+80,x
					lda $d828+120,x
					sta $d800+120,x
					lda $d828+160,x
					sta $d800+160,x
					lda $d828+200,x
					sta $d800+200,x
					lda $d828+240,x
					sta $d800+240,x
					lda $d828+280,x
					sta $d800+280,x
					lda $d828+320,x
					sta $d800+320,x
					lda $d828+360,x
					sta $d800+360,x
					dex
					bpl !-
upcolscnt:			ldx #0
					lda wormcolors,x
					ldx #19
!:					sta $d800+400,x
					dex
					bpl !-
					lda upcolscnt+1
					cmp #20
					beq !+
					inc upcolscnt+1
					rts
!: 					lda #1
					sta EnableBox2+1
					jmp Box2
					
Box2:				
					ldx #19
!:
					lda $d800+940,x
					sta $d800+980,x
					lda $d800+900,x
					sta $d800+940,x
					lda $d800+860,x
					sta $d800+900,x
					lda $d800+820,x
					sta $d800+860,x
					lda $d800+780,x
					sta $d800+820,x
					lda $d800+740,x
					sta $d800+780,x
					lda $d800+700,x
					sta $d800+740,x
					lda $d800+660,x
					sta $d800+700,x
					lda $d800+620,x
					sta $d800+660,x
					lda $d800+580,x
					sta $d800+620,x
					dex
					bpl !-
downcolscnt:		ldx #0
					lda wormcolors,x
					ldx #19
!:					sta $d800+580,x
					dex
					bpl !-
					lda downcolscnt+1
					cmp #20
					beq !+
					inc downcolscnt+1
!:
pccnt:				ldx #0
					lda performerscolors,x
					sta $d800+480+6
					sta $d800+520+6
					inc pccnt+1
					lda pccnt+1
					cmp #40
					beq perfcolsdone
					rts
perfcolsdone:		lda #$60
					sta performers
					lda #1
					sta Flag_Boxes
					rts
remy:	.byte 0

performers:			lda #0
					beq moveblocks
					jmp ShowPerformers

moveblocks:			ldy #0
f:					sty remy
fusrc:				lda fadeup,y
					cmp #99
					beq !+
					tax
fucnt:				ldy #0
					lda wormcolors,y
					sta $d800+480,x
					sta $d800+520,x
!:					ldy remy
					iny
					cpy #8
					bne f

					ldy #0
g:					sty remy
fusrc2:				lda fadedown,y
					cmp #99
					beq !+
					tax
					ldy fucnt+1
					lda wormcolorsreverse,y
					sta $d800+480,x
					sta $d800+520,x
!:					ldy remy
					iny
					cpy #8
					bne g

					lda fucnt+1
					cmp #8
					beq fudone
					inc fucnt+1
					rts
fudone:				lda #0
					sta fucnt+1
					lda fusrc+1
					clc
					adc #8
					sta fusrc+1
					lda fusrc+2
					adc #0
					sta fusrc+2
					lda fusrc2+1
					clc
					adc #8
					sta fusrc2+1
					lda fusrc2+2
					adc #0
					sta fusrc2+2
seqcnt1:			lda #0
					cmp #5
					beq !+
					inc seqcnt1+1
					rts
!:					lda #1
					sta performers+1
					rts

perftable:			.fillword 7,performersline+i*40
performersline:		
fadeup:				.byte  0,6 ,10,14, 25,29,33,39
					.byte  1,7 ,11,99, 99,28,32,38
					.byte  2,8 ,99,99, 99,99,31,37
					.byte  3,99,99,99, 99,99,99,36
					.byte  4,99,99,99, 99,99,99,35
					.byte  5,99,99,99, 99,99,99,34
					.byte 99,99,99,99, 99,99,99,99

fadedown:			.byte  1, 7,11,15, 24,28,32,38
					.byte  2, 8,12,99, 99,27,31,37
					.byte  3, 9,99,99, 99,99,30,36
					.byte  4,99,99,99, 99,99,99,35
					.byte  5,99,99,99, 99,99,99,34
					.byte  6,99,99,99, 99,99,99,33

					.byte 6,9,13,16, 23,26,29,32

.byte 0,1,1,1,1,1,0,1,1,1,0,1,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,1,0,1,1,1,0,1,1,1,1,1,0
.byte 1,0,1,1,1,1,1,0,1,1,1,0,1,1,1,0,1,1,0,1,1,0,1,1,0,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1
.byte 1,1,0,1,1,1,1,1,0,1,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1,0,1,1
.byte 1,1,1,0,1,1,1,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,1,1,1,0,1,1,1

.byte 1,1,1,1,0,1,1,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,1,1,0,1,1,1,1
.byte 1,1,1,1,1,0,1,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1
.byte 1,1,1,1,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,1,1,1,1

//////////////////////////////////////////////////////////////////////////////////////////////////////////

irqJumper2:			BeginIRQ()
					lda #$93
					sta $d011
					NextIRQ(irqJumper3,35)

irqJumper3:			BeginIRQ()
					lda #0
					sta $d015
					jsr Jumper
					lda $d011
					and #$7f
					sta $d011
					NextIRQ(irq0,50)

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Jumper:				
cnty1:				ldx #1
					lda JumpSinY,x
					sta $d00d
					sta $d00f
					lda JumpSinX,x
					sta $d00c
					sta $d00e
					inx
					stx cnty1+1
					lda JumpSinY,x
					sta $d009
					sta $d00b
					lda JumpSinX,x
					sta $d008
					sta $d00a
					lda JumpSinY + 1,x
					sta $d005
					sta $d007
					lda JumpSinX + 1,x
					sta $d004
					sta $d006
					lda JumpSinY + 2,x
					sta $d001
					sta $d003
					lda JumpSinX + 2,x
					sta $d000
					sta $d002
					cpx #220
					beq !+
					rts
!:					ldx #0
					stx FLAG_EnableJumper
					inx
					stx FLAG_EnableHorizontal
					rts


JumpSinY:			.fill 20,40
					.fill 64, 146+140+140*sin(toRadians(180+i*360/256))
					.fill 144, 146
JumpSinX:			.fill 20,0
					.fill 32, 176+64*sin(toRadians(i*360/128))
					.fill 96, 176+64*sin(toRadians(90+i*360/128))
					.fill 32, 176+16*sin(toRadians(i*360/32))
					.fill 48, 176
#import "includes.asm"


//////////////////////////////////////////////////////////////////////////////////////////////////////////
