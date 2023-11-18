;todo

			processor 6502
			incdir "../../util/dasm/include"
			include "standard.asm"
			
;------------------------------------------------------------------------------
;constants
;------------------------------------------------------------------------------
			ifnconst release
timingcolors		equ 0			;0=no colors 1=display rastertiming
			else
timingcolors		equ 0			;always 0, no colors wanted on release
			endif

yaddlo			equ $40

toplines		equ 38
topoffset		equ 63*toplines
topline			equ $2d-toplines
bottomline		equ $f7

mapsizex		equ 4096 				;muss durch 32 teilbar sein
mapsizey		equ 2048

blocksizex		equ 4
blocksizey		equ 2

parsizex		equ 32/8
parsizey		equ 32

firstparchar		equ 256-parsizex*parsizey/16 
parbase0		equ charset0+firstparchar*8
parbase1		equ charset1+firstparchar*8

blocksize		equ blocksizex*blocksizey*2

charsx			equ mapsizex/8 			;anzahl chars in x und y
charsy			equ mapsizey/16

blocksx			equ charsx/blocksizex 		;anzahl 4x4 char blöcke in x und y
blocksy			equ charsy/blocksizey

spriteoverlap		equ 2
spritelength		equ 21-spriteoverlap
spriteoffset		equ spritelength-1

;------------------------------------------------------------------------------
;zeropage
;------------------------------------------------------------------------------
zeropage		equ $02

areg			equ zeropage+$00
xreg			equ zeropage+$01
yreg			equ zeropage+$02
viewportxlo		equ zeropage+$03
viewportxhi		equ zeropage+$04
viewportylo		equ zeropage+$05
viewportyhi		equ zeropage+$06
temp			equ zeropage+$07

maplo			equ zeropage+$08
maphi			equ zeropage+$09
offset0			equ zeropage+$0a			;special offset for line 0
offset			equ zeropage+$0b			;normal offset
bal0			equ zeropage+$0c
bah0			equ zeropage+$0d
bal1			equ zeropage+$0e
bah1			equ zeropage+$0f
bal2			equ zeropage+$10
bah2			equ zeropage+$11
bal3			equ zeropage+$12
bah3			equ zeropage+$13
parxoffset		equ zeropage+$14
paryoffset		equ zeropage+$15
spritemapy		equ zeropage+$16
spritemapx		equ zeropage+$17
fadeflag		equ zeropage+$18
fadepos			equ zeropage+$19

;------------------------------------------------------------------------------
;memorymap
;------------------------------------------------------------------------------
stack			equ $0120

nmidest			equ $0200

vicbase			equ $c000
pattern1		equ $9800
pattern2		equ $a000
pattern3		equ $a800
pattern4		equ $b000
pattern5		equ $b800
screen			equ $c000				;16 Sprites frei ($c400-$c7ff)
spritepointer		equ screen+$03f8
charset0		equ $c800
pattern6		equ $d000
charset1		equ $d800
colorram		equ $d800
pattern7		equ $e000
pattern8		equ $e800
spritemap1		equ $f000

			ifnconst release
			org $0801
			;basic sys line
			dc.b $0b,$08,$00,$00,$9e,$32,$30,$36
			dc.b $31,$00,$00,$00
			jmp main

			else
			include "../../bitfire/loader/loader_acme.inc"
			include "../../bitfire/macros/link_macros_dasm.inc"
			endif

;------------------------------------------------------------------------------
			ifnconst release
			org $1000
sidfile			incbin "../../music/PREV2.PRG",2
			endif

;------------------------------------------------------------------------------
;detect cia type
;------------------------------------------------------------------------------
			org $2000
			
			ifconst release
			;setup_sync $30
			;jsr link_load_next_comp
			;sync
			jmp main
			endif
			
;------------------------------------------------------------------------------
;vblank - wait for vertical blank
;------------------------------------------------------------------------------
vblank			subroutine
.wait1			bit $d011
			bpl .wait1
.wait2			bit $d011
			bmi .wait2
delay12			rts				;delay 12 cycles if called by jsr
;------------------------------------------------------------------------------
;main
;------------------------------------------------------------------------------
main			subroutine
			ifnconst release
			sei
			cld
			ldx #$ff
			txs
			lda #$35
			sta $01
			endif
			
			jsr vblank
			lda #$06
			sta colorblock0
			sta colorblock4
			sta colorblock1
			sta colorblock5
			sta colorblock2
			sta colorblock6
			sta colorblock3
			sta colorblock7

			ifconst release
			ldx #$0f
.sau1			lda $0200,x
			sta save2,x
			lda $0300,x
			sta save3,x
			dex
			bpl .sau1
			switch_to_irq
			inc $d019
			lda #$01
			sta $d01a
			
			cli
			endif

;			jsr vblank
			jsr initnmi

			jsr vblank
			jsr initscreen
			dec $01
			jsr genparallax
			inc $01
			
			ifnconst release
			ldx #$00
			jsr sidfile
			endif

			jsr vblank
			lda #<bottomirq
			sta $fffe
			lda #>bottomirq
			sta $ffff
			lda #bottomline
			sta $d012

			ifnconst release
			inc $d019
			lda #$01
			sta $d01a
.forever		jmp .forever
			else
			lda #200
.waitline		cmp $d012			
			bne .waitline
			jsr link_music_play
			
endflag			lda #$01
			bne endflag

			ldx #<link_player
			lda #>link_player

			stx $fffe
			sta $ffff
			lda #$ff
			sta $d012

			lda #$7f			;clear irq masks
			sta $dc0d
			sta $dd0d

			lda #$00
			sta $dc0e			;stop timers
			sta $dc0f
			sta $dd0e
			sta $dd0f

			bit $dc0d			;ack pending irqs
			bit $dd0d

			jsr vblank
			lda #$00
			sta $d020
			sta $d011
			sta $d015
			
			ldx #$00
.stackloop		lda stackcodestart,x
			sta stack,x
			inx
			cpx #stackcodeend-stackcodestart
			bne .stackloop
			jmp stack_start
			
;------------------------------------------------------------------------------
stackcodestart		
			rorg stack
			subroutine
stack_start
			ldx #$0f
.sau2			lda save2,x
			sta $0200,x
			lda save3,x
			sta $0300,x
			dex
			bpl .sau2

;			start_music_nmi
			setup_sync $20
			jsr link_load_next_comp
			sync
			jmp link_exit
			
save2			equ *
save3			equ *+$10
			rend
stackcodeend
			endif

;------------------------------------------------------------------------------
;firstnmi
;------------------------------------------------------------------------------
			align 256,0
mainnmi			subroutine
			jmp ($dc05)
;-----------------------		
firstnmi		sta .areg+1		;handle not doubling line 0
			nop
			lda #<mainnmi
			lsr $d018
			sta $fffa
.areg			lda #$ff
			jmp $dd0c

;------------------------------------------------------------------------------
;topirq
;------------------------------------------------------------------------------
;{1} row number
;{2} row number + 1
			mac setspriterow
;			lda spritemapy
;			if {1}>0
;			clc
;			adc #21*{1}
;			endif
			
			if {1}=0
			else
spry{1}			lda #$00
			endif
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f
			clc
			if {2}<7
			adc #spriteoffset+spritelength*{1}-21*{1}
			else
			adc #spriteoffset+spritelength*{1}-21*{1}+1
			endif

			sta $d012
			
			lda #$fe
			ldx #[spritemap1-vicbase]/64+8*{1}+1
			sax spritepointer
			stx spritepointer+1
			ldx #[spritemap1-vicbase]/64+8*{1}+1+2
			sax spritepointer+2
			stx spritepointer+3
			ldx #[spritemap1-vicbase]/64+8*{1}+1+2+2
			sax spritepointer+4
			stx spritepointer+5
			ldx #[spritemap1-vicbase]/64+8*{1}+1+2+2+2
			sax spritepointer+6
			stx spritepointer+7

			endm
;-----------------------
topirq			subroutine
			sta areg
			stx xreg
			lda #<topirqb
			sta $fffe
			inc $d012
			inc $d019
			tsx
			cli

			repeat 18			;amount of nops depend on code before
			nop
			repend
			
topirqb			txs
			jsr delay12			;do something here?
			jsr delay12
			nop
			nop
			nop
			nop
			
			inc $d019

			lda #$ff
			sta $d015
			
			lda $d012
			cmp $d012
			beq .waitcycle
			
.waitcycle		lda #<spriteirq1
			sta $fffe
			lda #>spriteirq1
			sta $ffff
		
			lda #%01010001			;start the timers
			sta $dc0e
			sta $dc0f

ciatype			lda #$00			;adjust for older cia models which
			bne .next			;trigger interrupts one cycle late.
			
.next			lda #%00010001
			sta $dd0e
			sta $dd0f

			lda #63*2-1			;set timer
			sta $dc04
			lda #8-1
			sta $dc06

			lda #<[63*16-1]
			sta $dd04
			lda #>[63*16-1]
			sta $dd05

			lda #<[63*8-1]
			sta $dd06
			lda #>[63*8-1]
			sta $dd07

			lda #%10000011			;enable irqs
			sta $dd0d

			; if timingcolors=1
			; inc $d020
			; dec $d020
			; endif

			ldx #$00
spriteirq0		lda #112+34		;y= 33 sprite invisible, 34 last line visible, 246 sprite invisible, 245 first line visible
			sec
.sub			sbc spritemapx
			sta $d000
			clc
			adc #24
			sta $d002
			adc #24
			sta $d004
			adc #24
			sta $d006
			adc #24
			sta $d008
			adc #24
			sta $d00a
			bcc .over1
			ldx #%11100000
			adc #23
			sta $d00c
			adc #24
			sta $d00e
			jmp .exitirq

.over1			adc #24
			sta $d00c
			bcc .over2
			ldx #%11000000
			adc #23
			sta $d00e
			jmp .exitirq

.over2			adc #24
			sta $d00e
			bcc .exitirq
			ldx #%10000000
			clc
.exitirq		stx $d010
			
			lax spritemapy
			adc #21
			sta spry1+1
			adc #21
			sta spry2+1
			adc #21
			sta spry3+1
			adc #21
			sta spry4+1
			adc #21
			sta spry5+1
			adc #21
			sta spry6+1
			txa
			setspriterow 0,1
			lda areg
			ldx xreg
			rti
;------------------------------------------------------------------------------
;spriteirqs
;------------------------------------------------------------------------------
;Don't change size of IRQ routines, or it might crash
			align 256,0
spriteirq1		subroutine
			sta areg
			stx xreg

			inc $d019

			lda #<spriteirq2
			sta $fffe
			setspriterow 1,2

			lda areg
			ldx xreg
			rti
;-----------------------		
spriteirq2		subroutine
			sta areg
			stx xreg
			
			inc $d019
			setspriterow 2,3

			lda #<spriteirq3
			sta $fffe

			lda areg
			ldx xreg
			rti
;-----------------------		
spriteirq3		subroutine
			sta areg
			stx xreg

			setspriterow 3,4
			inc $d019

			lda #<spriteirq4
			sta $fffe

			lda areg
			ldx xreg
			rti
;-----------------------
spriteirq4		subroutine
			sta areg
			stx xreg

			setspriterow 4,5
			inc $d019

			lda #<spriteirq5
			sta $fffe
			inc $ffff

			lda areg
			ldx xreg
			rti
;-----------------------
spriteirq5		subroutine
			sta areg
			stx xreg

			setspriterow 5,6
			inc $d019

			lda #<spriteirq6
			sta $fffe

			lda areg
			ldx xreg
			rti
;-----------------------
spriteirq6		subroutine
			sta areg
			stx xreg
			
			setspriterow 6,7
			inc $d019

			lda #<spriteirq7
			sta $fffe
			
			lda areg
			ldx xreg
			rti
;-----------------------
spriteirq7		subroutine
			sta areg
			
			lda #[emptysprite-vicbase]/64
			sta spritepointer+0
			sta spritepointer+1
			sta spritepointer+2
			sta spritepointer+3
			sta spritepointer+4
			sta spritepointer+5
			sta spritepointer+6
			sta spritepointer+7

;position spritemap
;x 0,0 bis 3775 ($ebf)
;y 0,0 bis 1847 ($737)

;position spritemap on screen
;x left 31 right 143 (0-112)
;y top 54 bottom 92 (0-37)

			lda viewportylo
			and #$c0
			sta temp
			lda viewportyhi		;y/64
			asr #$3f
			ora temp
			rol
			rol
			rol			;c = 0
			eor #$ff
			adc #93
			sta spritemapy

.over			lda #bottomline
			sta $d012
			lda #<bottomirq
			sta $fffe
			inc $ffff
			inc $d019

			lda areg
			rti

;------------------------------------------------------------------------------
;bottomirq 
;------------------------------------------------------------------------------
bottomirq		subroutine
			sta .areg+1
			stx .xreg+1
			sty .yreg+1
			
bottomirq2		if timingcolors=1 
			inc $d020
			endif

			lda #%00010000			;stop all timers
			sta $dd0e
			sta $dd0f
			sta $dc0e
			sta $dc0f

			lda #$00			;turn off all sprites
			sta $d015

			bit $dd0d

			lda #63*2+21
			sta $dc04
			lda #(toplines>>1)&7
			sta $dc06

			lda #<[topoffset+63*8-9]
			sta $dd04
			lda #>[topoffset+63*8-9]
			sta $dd05

			lax viewportylo
			and #%00001000
			bne .early

.late			lda #<[topoffset+63*4-12]			;double line 0
			sta $dd06
			lda #>[topoffset+63*4-12]
			sta $dd07
			jmp .continue

.early			lda #<[topoffset+63*4-12-63*8]		;double line 1
			sta $dd06
			lda #>[topoffset+63*4-12-63*8]
			sta $dd07

			lda #<firstnmi
			sta $fffa

.continue		txa
			and #%00001111
			tax
			lsr
			ora #%00000011
			sta $d018

			lda viewportxlo
			and #%00000111
d016switch		eor #%00010111
			sta $d016

			txa
			and #%00000111
			eor #%00010111
			sta $d011

			txa
			eor #%00000111
			clc
			adc #topline
			sta $d012

			lda #<topirq
			sta $fffe
			lda #>topirq
			sta $ffff
			inc $d019
			
			cli			;allow next raster irqs to trigger early
			
			dec $01
			jsr moveparallax
			inc $01

			jsr doscroll

			if timingcolors=1 
			inc $d020
			endif

			ifnconst release
			jsr sidfile+3
			else
			jsr link_music_play 
			endif

.dofadeout		ldx fadeflag
			bne .fadeit
			jmp .nofade
			
.fadeit			lda #$e4
.wline			cmp $d012
			bcs .wline
			
			ldx fadeflag
			bpl .fadein
			
.fadeout		ldx fadepos
			lda .d800fade,x
			sta colorblock0
			sta colorblock4
			sta colorblock1
			sta colorblock5
			sta colorblock2
			sta colorblock6
			sta colorblock3
			sta colorblock7
			lda .d016switch,x
			sta d016switch+1
			lda .d01bswitch,x
			sta $d01b
			lda .spritecol,x
			sta $d027
			sta $d028
			sta $d029
			sta $d02a
			sta $d02b
			sta $d02c
			sta $d02d
			sta $d02e
			lda .spritemc1col,x
			sta $d025
			lda .spritemc2col,x
			sta $d026
	
			dex
			bpl .fade1
			
			ifconst release
			inx
			stx endflag+1
			stx fadeflag
			endif
			
			jmp .nomove
			
.fadein			ldx fadepos
			lda .d800fade,x
			sta colorblock0
			sta colorblock4
			sta colorblock1
			sta colorblock5
			sta colorblock2
			sta colorblock6
			sta colorblock3
			sta colorblock7
			lda .d016switch,x
			sta d016switch+1
			lda .d01bswitch,x
			sta $d01b
			lda .spritecol,x
			sta $d027
			sta $d028
			sta $d029
			sta $d02a
			sta $d02b
			sta $d02c
			sta $d02d
			sta $d02e
			lda .spritemc1col,x
			sta $d025
			lda .spritemc2col,x
			sta $d026
						
			inx
			cpx #$10
			bne .fade1
			lda #$00
			sta fadeflag
			beq .nomove
.fade1			stx fadepos		
			jmp .nomove

.nofade
.lopoi			ldy #$00			
.hipoi1			lda spe_datax0,y
			cmp #$7f
			bne .move
			dec fadeflag
			jmp .fadeit
			
.move			ldx #$00
			bcc .nodex1
			dex
			clc
			
.nodex1			adc viewportxlo
			sta viewportxlo
			txa
			adc viewportxhi
			sta viewportxhi

			ldx #$00
.hipoi2			lda spe_datay0,y
			bpl .nodex2
			dex

.nodex2			clc			
			adc viewportylo
			sta viewportylo
			txa
			adc viewportyhi
			sta viewportyhi

			iny
			sty .lopoi+1
			bne .nomove
			inc .hipoi1+2
			inc .hipoi2+2
			
.nomove			ifnconst release
			lda $d012
rline			cmp #$00	;max $de
			bcc .lower
			sta rline+1
.lower
			endif
			
			if timingcolors=1
			lda #$00
			sta $d020
			endif

.areg			lda #$00
.xreg			ldx #$00
.yreg			ldy #$00
			rti
			
			;dc.b $00,$06,$09,$02,$0b,$04,$08,$0c,$0e,$05,$0a,$03,$0f,$07,$0d,$01
.d800fade		dc.b $06,$09,$02,$0b,$04,$08,$0c,$0e,$05,$0a,$03,$05,$0e,$0c,$08,$04
.d016switch		dc.b $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$17
.d01bswitch		dc.b $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$00,$00,$00,$00
.spritecol		dc.b $06,$09,$02,$0b,$04,$08,$0c,$0e,$05,$0a,$03,$0f,$07,$0d,$01,$01
.spritemc1col		dc.b $06,$09,$02,$0b,$04,$08,$0c,$0e,$05,$0a,$03,$0f,$0f,$0f,$0f,$0f
.spritemc2col		dc.b $06,$09,$02,$0b,$04,$08,$0c,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e

;------------------------------------------------------------------------------
;scroll macros
;------------------------------------------------------------------------------
;x 0-7 off 4
;0    1    ... 9
;0123 0123     0123
;
;x 8-15 off 3
;0   1    ... 9    10
;123 0123     0123  0
;
;x 16-23 off 2
;0  1    ... 9     10
;23 0123     0123  01
;
;x 24-31 off 1
;0 1    ... 9     10
;3 0123     0123  012

			mac filldoublefirst
			ldy #$00
			lax (maplo),y		;adjust first 4 bytes @ start of the line
			ldy offset0
		
sel{3}			bcc *
			
			lda charblock0,x	;0
			sta screen+{1}-4,y
			lda colorblock0,x
			sta colorram+{1}-4,y
			lda charblock1,x	;12
			sta screen+{1}-3,y
			lda colorblock1,x
			sta colorram+{1}-3,y
			lda charblock2,x	;24
			sta screen+{1}-2,y
			lda colorblock2,x
			sta colorram+{1}-2,y
			lda charblock3,x	;36
			sta screen+{1}-1,y
			lda colorblock3,x
			sta colorram+{1}-1,y
			
			ldy offset
			
sel{4}			bcc *			
			
			lda charblock4,x	;0
			sta screen+{2}-4,y
			lda colorblock4,x
			sta colorram+{2}-4,y
			lda charblock5,x	;12
			sta screen+{2}-3,y
			lda colorblock5,x
			sta colorram+{2}-3,y
			lda charblock6,x	;24
			sta screen+{2}-2,y
			lda colorblock6,x
			sta colorram+{2}-2,y
			lda charblock7,x	;36
			sta screen+{2}-1,y
			lda colorblock7,x
			sta colorram+{2}-1,y
;-----------------------
x			set 0			
			repeat 9
			ldy #x+1
			lax (maplo),y
			ldy offset0

			lda charblock0,x
			sta screen+{1}+blocksizex*x,y
			lda charblock1,x
			sta screen+{1}+blocksizex*x+1,y
			lda charblock2,x
			sta screen+{1}+blocksizex*x+2,y
			lda charblock3,x
			sta screen+{1}+blocksizex*x+3,y

			lda colorblock0,x
			sta colorram+{1}+blocksizex*x,y
			lda colorblock1,x
			sta colorram+{1}+blocksizex*x+1,y
			lda colorblock2,x
			sta colorram+{1}+blocksizex*x+2,y
			lda colorblock3,x
			sta colorram+{1}+blocksizex*x+3,y

			ldy offset
			
			lda charblock4,x
			sta screen+{2}+blocksizex*x,y
			lda charblock5,x
			sta screen+{2}+blocksizex*x+1,y
			lda charblock6,x
			sta screen+{2}+blocksizex*x+2,y
			lda charblock7,x
			sta screen+{2}+blocksizex*x+3,y

			lda colorblock4,x
			sta colorram+{2}+blocksizex*x,y
			lda colorblock5,x
			sta colorram+{2}+blocksizex*x+1,y
			lda colorblock6,x
			sta colorram+{2}+blocksizex*x+2,y
			lda colorblock7,x
			sta colorram+{2}+blocksizex*x+3,y
x			set x+1			
			repend
;-----------------------
			ldy #$0a
			lax (maplo),y		;adjust last 0-3 bytes @ end of the line
			ldy offset0
		
sel{5}			bcc *		
			
;			lda charblock2,x	;0
;			sta screen+{1}+38,y
;			lda colorblock2,x
;			sta colorram+{1}+38,y
			lda charblock1,x	;12	0
			sta screen+{1}+37,y
			lda colorblock1,x
			sta colorram+{1}+37,y
			lda charblock0,x	;24	12
			sta screen+{1}+36,y
			lda colorblock0,x
			sta colorram+{1}+36,y
;36
			ldy offset

sel{6}			bcc *			
;			lda charblock6,x	;0
;			sta screen+{2}+38,y
;			lda colorblock6,x
;			sta colorram+{2}+38,y
			lda charblock5,x	;12	0
			sta screen+{2}+37,y
			lda colorblock5,x
			sta colorram+{2}+37,y
			lda charblock4,x	;24	12
			sta screen+{2}+36,y
			lda colorblock4,x
			sta colorram+{2}+36,y
;36
			endm
			
;------------------------------------------------------------------------------
			mac filldouble
			ldy #$00
			lax (maplo),y		;adjust first 4 bytes @ start of the line
			ldy offset
		
sel{4}			bcc *		
			
			lda charblock0,x	;0
			sta screen+{1}*160+{2}-4,y
			lda colorblock0,x
			sta colorram+{1}*160+{2}-4,y
			lda charblock4,x	
			sta screen+{1}*160+{3}-4,y
			lda colorblock4,x
			sta colorram+{1}*160+{3}-4,y
			lda charblock1,x	;24
			sta screen+{1}*160+{2}-3,y
			lda colorblock1,x
			sta colorram+{1}*160+{2}-3,y
			lda charblock5,x
			sta screen+{1}*160+{3}-3,y
			lda colorblock5,x
			sta colorram+{1}*160+{3}-3,y
			lda charblock2,x	;48
			sta screen+{1}*160+{2}-2,y
			lda colorblock2,x
			sta colorram+{1}*160+{2}-2,y
			lda charblock6,x
			sta screen+{1}*160+{3}-2,y
			lda colorblock6,x
			sta colorram+{1}*160+{3}-2,y
			lda charblock3,x	;72
			sta screen+{1}*160+{2}-1,y
			lda colorblock3,x
			sta colorram+{1}*160+{2}-1,y
			lda charblock7,x
			sta screen+{1}*160+{3}-1,y
			lda colorblock7,x
			sta colorram+{1}*160+{3}-1,y
;96		
;-----------------------
x			set 0
			repeat 9
			ldy #x+1
			lax (maplo),y
			ldy offset

			lda charblock0,x
			sta screen+{1}*160+{2}+blocksizex*x,y
			lda charblock1,x
			sta screen+{1}*160+{2}+blocksizex*x+1,y
			lda charblock2,x
			sta screen+{1}*160+{2}+blocksizex*x+2,y
			lda charblock3,x
			sta screen+{1}*160+{2}+blocksizex*x+3,y

			lda colorblock0,x
			sta colorram+{1}*160+{2}+blocksizex*x,y
			lda colorblock1,x
			sta colorram+{1}*160+{2}+blocksizex*x+1,y
			lda colorblock2,x
			sta colorram+{1}*160+{2}+blocksizex*x+2,y
			lda colorblock3,x
			sta colorram+{1}*160+{2}+blocksizex*x+3,y

			lda charblock4,x
			sta screen+{1}*160+{3}+blocksizex*x,y
			lda charblock5,x
			sta screen+{1}*160+{3}+blocksizex*x+1,y
			lda charblock6,x
			sta screen+{1}*160+{3}+blocksizex*x+2,y
			lda charblock7,x
			sta screen+{1}*160+{3}+blocksizex*x+3,y

			lda colorblock4,x
			sta colorram+{1}*160+{3}+blocksizex*x,y
			lda colorblock5,x
			sta colorram+{1}*160+{3}+blocksizex*x+1,y
			lda colorblock6,x
			sta colorram+{1}*160+{3}+blocksizex*x+2,y
			lda colorblock7,x
			sta colorram+{1}*160+{3}+blocksizex*x+3,y
x			set x+1			
			repend
;-----------------------
			ldy #$0a
			lax (maplo),y		;adjust last 0-3 bytes @ end of the line
			ldy offset
		
sel{5}			bcc *		
			
			; lda charblock2,x	;0
			; sta screen+{1}*160+{2}+38,y
			; lda colorblock2,x
			; sta colorram+{1}*160+{2}+38,y
			; lda charblock6,x
			; sta screen+{1}*160+{3}+38,y
			; lda colorblock6,x
			; sta colorram+{1}*160+{3}+38,y
			lda charblock1,x	;24	0
			sta screen+{1}*160+{2}+37,y
			lda colorblock1,x
			sta colorram+{1}*160+{2}+37,y
			lda charblock5,x
			sta screen+{1}*160+{3}+37,y
			lda colorblock5,x
			sta colorram+{1}*160+{3}+37,y
			lda charblock0,x	;48	24
			sta screen+{1}*160+{2}+36,y
			lda colorblock0,x
			sta colorram+{1}*160+{2}+36,y
			lda charblock4,x
			sta screen+{1}*160+{3}+36,y
			lda colorblock4,x
			sta colorram+{1}*160+{3}+36,y
;72
			endm
;------------------------------------------------------------------------------
			mac fillevenlast
			ldy #$00
			lax (maplo),y		;adjust first 4 bytes @ start of the line
			ldy offset
		
sel{4}			bcc *			
			
			lda charblock0,x	;0
			sta screen+{1}*160+{2}-4,y
			lda colorblock0,x
			sta colorram+{1}*160+{2}-4,y
			lda charblock1,x	;12
			sta screen+{1}*160+{2}-3,y
			lda colorblock1,x
			sta colorram+{1}*160+{2}-3,y
			lda charblock2,x	;24
			sta screen+{1}*160+{2}-2,y
			lda colorblock2,x
			sta colorram+{1}*160+{2}-2,y
			lda charblock3,x	;36
			sta screen+{1}*160+{2}-1,y
			lda colorblock3,x
			sta colorram+{1}*160+{2}-1,y

x			set 0
			repeat 9
			ldy #x+1
			lax (maplo),y
			ldy offset

			lda charblock0,x
			sta screen+{1}*160+{2}+blocksizex*x,y
			lda charblock1,x
			sta screen+{1}*160+{2}+blocksizex*x+1,y
			lda charblock2,x
			sta screen+{1}*160+{2}+blocksizex*x+2,y
			lda charblock3,x
			sta screen+{1}*160+{2}+blocksizex*x+3,y

			lda colorblock0,x
			sta colorram+{1}*160+{2}+blocksizex*x,y
			lda colorblock1,x
			sta colorram+{1}*160+{2}+blocksizex*x+1,y
			lda colorblock2,x
			sta colorram+{1}*160+{2}+blocksizex*x+2,y
			lda colorblock3,x
			sta colorram+{1}*160+{2}+blocksizex*x+3,y
x			set x+1
			repend
;-----------------------
			ldy #$0a
			lax (maplo),y		;adjust last 0-3 bytes @ end of the line
			ldy offset
	
sel{5}			bcc *			
			
			; lda charblock2,x	;0
			; sta screen+{1}*160+{2}+38,y
			; lda colorblock2,x
			; sta colorram+{1}*160+{2}+38,y
			lda charblock1,x	;12	0
			sta screen+{1}*160+{2}+37,y
			lda colorblock1,x
			sta colorram+{1}*160+{2}+37,y
			lda charblock0,x	;24	12
			sta screen+{1}*160+{2}+36,y
			lda colorblock0,x
			sta colorram+{1}*160+{2}+36,y
;36
			endm
;------------------------------------------------------------------------------
			mac filloddfirst
			ldy #$00
			lax (maplo),y		;adjust first 4 bytes @ start of the line
			ldy offset0		;4,3,2,1

sel{4}			bcc *			
			
			lda charblock4,x	;0
			sta screen+{1}*160+{2}-4,y
			lda colorblock4,x
			sta colorram+{1}*160+{2}-4,y
			lda charblock5,x	;12
			sta screen+{1}*160+{2}-3,y
			lda colorblock5,x
			sta colorram+{1}*160+{2}-3,y
			lda charblock6,x	;24
			sta screen+{1}*160+{2}-2,y
			lda colorblock6,x
			sta colorram+{1}*160+{2}-2,y
			lda charblock7,x	;36
			sta screen+{1}*160+{2}-1,y
			lda colorblock7,x
			sta colorram+{1}*160+{2}-1,y

x			set 0
			repeat 9
			ldy #x+1
			lax (maplo),y
			ldy offset0

			lda charblock4,x
			sta screen+{1}*160+{2}+blocksizex*x,y
			lda charblock5,x
			sta screen+{1}*160+{2}+blocksizex*x+1,y
			lda charblock6,x
			sta screen+{1}*160+{2}+blocksizex*x+2,y
			lda charblock7,x
			sta screen+{1}*160+{2}+blocksizex*x+3,y

			lda colorblock4,x
			sta colorram+{1}*160+{2}+blocksizex*x,y
			lda colorblock5,x
			sta colorram+{1}*160+{2}+blocksizex*x+1,y
			lda colorblock6,x
			sta colorram+{1}*160+{2}+blocksizex*x+2,y
			lda colorblock7,x
			sta colorram+{1}*160+{2}+blocksizex*x+3,y
x			set x+1			
			repend
;-----------------------
			ldy #$0a
			lax (maplo),y		;adjust last 0-3 bytes @ end of the line
			ldy offset0		;4,3,2,1
			
sel{5}			bcc *			

			; lda charblock6,x	;0
			; sta screen+{1}*160+{2}+38,y
			; lda colorblock6,x
			; sta colorram+{1}*160+{2}+38,y
			lda charblock5,x	;12	0
			sta screen+{1}*160+{2}+37,y
			lda colorblock5,x
			sta colorram+{1}*160+{2}+37,y
			lda charblock4,x	;24	12
			sta screen+{1}*160+{2}+36,y
			lda colorblock4,x
			sta colorram+{1}*160+{2}+36,y
;36
			endm
;------------------------------------------------------------------------------
			mac advanceline
			if mapsizex=8192
			inc maphi
			endif
			
			if mapsizex=4096
			lda maplo
			eor #$80
			sta maplo
			bmi .noinc1
			inc maphi
.noinc1			endif
			
			if mapsizex!=4096 && mapsizex!=8192
			lda maplo
			adc #blocksx
			sta maplo
			bcc .noinc2
			inc maphi
			clc
.noinc2
			endif
			endm
			
;------------------------------------------------------------------------------
;scroll
;------------------------------------------------------------------------------
;scroller done at max line 120 unrolled

jmptableft		dc.b $ff,36,24,12,0	;offset0 1-4 (0=draw 4 blocks) 
jmptabright		dc.b $ff,0,12,24,24


doscroll		subroutine
			lda viewportyhi
			sta temp

			lax viewportylo		;needs to be adjusted depending on size of map
			lsr
			asr #$0c
			adc #<.jmptab
			sta .select+1
			txa
			and #%11100000
			asl
			rol temp
			asl
			rol temp
			;clc			;bit 7 of viewporthi not set, so always c = 0
			adc #<blockmap
			sta maplo
			lda #>blockmap
			adc temp
			sta maphi

;-----------------------
			lda viewportxhi
			asl
			asl
			asl
			sta .or+1
			lda viewportxlo
			lsr
			lsr
			lsr
			tax			;x/8
			lsr
			asr #$fe		;c = 0
.or			ora #$00		;x/32
			sta spritemapx

			adc maplo
			sta maplo
;			lda maphi		;high byte add can be removd, if width of playfiels is <8192
;			adc temp
;			sta maphi

			txa
			and #%00000011
			eor #%00000011
			adc #$01

			sta offset0
			tay
			lda jmptableft,y
			sta sel00+1
			sta sel01+1
			sta sel14+1
			sta sel16+1

			asl
			sta sel04+1
;			sta sel06+1
			sta sel08+1
;			sta sel10+1
			sta sel12+1
			sta sel18+1
;			sta sel20+1
			sta sel22+1
;			sta sel24+1
			sta sel26+1
;			sta sel28+1
			
			lda jmptabright,y
			sta sel02+1
			sta sel03+1
			sta sel15+1
			sta sel17+1

			asl
			sta sel05+1
;			sta sel07+1
			sta sel09+1
;			sta sel11+1
			sta sel13+1
			sta sel19+1
;			sta sel21+1
			sta sel23+1
;			sta sel25+1
			sta sel27+1
;			sta sel29+1

			tya
			; clc 			;carry should be clear here at all times!
.select			jmp (.jmptab)
;-----------------------
;$5d19, $478a
;XXX ATTENTION, this tab must not cross a page			
.jmptab			dc.w .scroll0, .scroll1, .scroll2, .scroll3
;.jmptablo		dc.b <.scroll0,<.scroll1,<.scroll2,<.scroll3
;.jmptabhi		dc.b >.scroll0,>.scroll1,>.scroll2,>.scroll3
			
.scroll0		adc #40
.scroll1		sta offset
			
.scroll1b
			filldoublefirst 0,40,00,01,02,03	;0	40
			advanceline

.repeat1		filldouble 0,120,200,04,05		;120	200
			advanceline

			lda offset
			adc #160
			bcs .next1
			sta offset
			jmp .repeat1
.next1			sbc #$40
			sta offset
			clc
			
;			filldouble 1,120,200,06,07		;280	360
;			advanceline
.repeat2		filldouble 2,120,200,08,09		;440	520
			advanceline

			lda offset
			adc #160
			bcs .next2
			sta offset
			jmp .repeat2
.next2			sbc #$40
			sta offset
			clc

;			filldouble 3,120,200,10,11		;600	680
;			advanceline
			filldouble 4,120,200,12,13		;760	840
			advanceline
			fillevenlast 5,120,200,14,15		;760	840
			rts

.scroll2		adc #40
.scroll3		sta offset

.scroll3b
			filloddfirst 0,0,40,16,17		;24
			advanceline
.repeat3		filldouble 0,40,120,18,19
			advanceline

			lda offset
			adc #160
			bcs .next3
			sta offset
			jmp .repeat3
.next3			sbc #$40
			sta offset
			clc

;			filldouble 1,40,120,20,21
;			advanceline
.repeat4		filldouble 2,40,120,22,23
			advanceline

			lda offset
			adc #160
			bcs .next4
			sta offset
			jmp .repeat4
.next4			sbc #$40
			sta offset
			clc

;			filldouble 3,40,120,24,25
;			advanceline
.repeat5		filldouble 4,40,120,26,27
			advanceline

			lda offset
			adc #160
			bcs .next5
			sta offset
			jmp .repeat5
.next5			
;			filldouble 5,40,120,28,29
.over			rts

;------------------------------------------------------------------------------
genparallax		subroutine
			ldx #>pattern1
			jsr .genframe
			ldx #>pattern2
			jsr .genframe
			ldx #>pattern3
			jsr .genframe
			ldx #>pattern4
			jsr .genframe
			ldx #>pattern5
			jsr .genframe
			ldx #>pattern6
			jsr .genframe
			ldx #>pattern7
			jsr .genframe
			ldx #>pattern8
			
.genframe		stx .rot1+2
			stx .rot2+2
			stx .rot4+2
			stx .rot6+2
;			stx .rot8+2
			inx
			stx .rot3+2
			stx .rot5+2
			stx .rot7+2
			stx .rot9+2

			lda #$06
			sta temp
.loop1			ldy #parsizey*2-1
.rot1			lax prow00,y					;fetch leftmost pixel
			rol
.rot2			lda prow30,y
			rol
.rot3			sta prow31,y
.rot4			lda prow20,y
			rol
.rot5			sta prow21,y
.rot6			lda prow10,y
			rol
.rot7			sta prow11,y
			txa
			rol
.rot9			sta prow01,y
			dey
			bpl .rot1

			inc .rot1+2
			inc .rot2+2
			inc .rot3+2
			inc .rot4+2
			inc .rot5+2
			inc .rot6+2
			inc .rot7+2
;			inc .rot8+2
			inc .rot9+2
			dec temp
			bpl .loop1

			rts
			
;------------------------------------------------------------------------------
			mac fillrow
			lda (bal0),y
			sta parbase0+{1}
			lda (bal1),y
			sta parbase0+{2}
			lda (bal2),y
			sta parbase0+{3}
			lda (bal3),y
			sta parbase0+{4}
			iny
			lda (bal0),y
			sta parbase0+{1}+1
			lda (bal1),y
			sta parbase0+{2}+1
			lda (bal2),y
			sta parbase0+{3}+1
			lda (bal3),y
			sta parbase0+{4}+1
			iny
			lda (bal0),y
			sta parbase0+{1}+2
			lda (bal1),y
			sta parbase0+{2}+2
			lda (bal2),y
			sta parbase0+{3}+2
			lda (bal3),y
			sta parbase0+{4}+2
			iny
			lda (bal0),y
			sta parbase0+{1}+3
			lda (bal1),y
			sta parbase0+{2}+3
			lda (bal2),y
			sta parbase0+{3}+3
			lda (bal3),y
			sta parbase0+{4}+3
			iny
			lda (bal0),y
			sta parbase1+{1}+4
			lda (bal1),y
			sta parbase1+{2}+4
			lda (bal2),y
			sta parbase1+{3}+4
			lda (bal3),y
			sta parbase1+{4}+4
			iny        
			lda (bal0),y
			sta parbase1+{1}+5
			lda (bal1),y
			sta parbase1+{2}+5
			lda (bal2),y
			sta parbase1+{3}+5
			lda (bal3),y
			sta parbase1+{4}+5
			iny        
			lda (bal0),y
			sta parbase1+{1}+6
			lda (bal1),y
			sta parbase1+{2}+6
			lda (bal2),y
			sta parbase1+{3}+6
			lda (bal3),y
			sta parbase1+{4}+6
			iny        
			lda (bal0),y
			sta parbase1+{1}+7
			lda (bal1),y
			sta parbase1+{2}+7
			lda (bal2),y
			sta parbase1+{3}+7
			lda (bal3),y
			sta parbase1+{4}+7
			iny

			lda (bal0),y
			sta parbase1+{1}
			lda (bal1),y
			sta parbase1+{2}
			lda (bal2),y
			sta parbase1+{3}
			lda (bal3),y
			sta parbase1+{4}
			iny        
			lda (bal0),y
			sta parbase1+{1}+1
			lda (bal1),y
			sta parbase1+{2}+1
			lda (bal2),y
			sta parbase1+{3}+1
			lda (bal3),y
			sta parbase1+{4}+1
			iny        
			lda (bal0),y
			sta parbase1+{1}+2
			lda (bal1),y
			sta parbase1+{2}+2
			lda (bal2),y
			sta parbase1+{3}+2
			lda (bal3),y
			sta parbase1+{4}+2
			iny        
			lda (bal0),y
			sta parbase1+{1}+3
			lda (bal1),y
			sta parbase1+{2}+3
			lda (bal2),y
			sta parbase1+{3}+3
			lda (bal3),y
			sta parbase1+{4}+3
			iny        
				   
			lda (bal0),y
			sta parbase0+{1}+4
			lda (bal1),y
			sta parbase0+{2}+4
			lda (bal2),y
			sta parbase0+{3}+4
			lda (bal3),y
			sta parbase0+{4}+4
			iny
			lda (bal0),y
			sta parbase0+{1}+5
			lda (bal1),y
			sta parbase0+{2}+5
			lda (bal2),y
			sta parbase0+{3}+5
			lda (bal3),y
			sta parbase0+{4}+5
			iny
			lda (bal0),y
			sta parbase0+{1}+6
			lda (bal1),y
			sta parbase0+{2}+6
			lda (bal2),y
			sta parbase0+{3}+6
			lda (bal3),y
			sta parbase0+{4}+6
			iny
			lda (bal0),y
			sta parbase0+{1}+7
			lda (bal1),y
			sta parbase0+{2}+7
			lda (bal2),y
			sta parbase0+{3}+7
			lda (bal3),y
			sta parbase0+{4}+7
			iny
;-----------------------
			lda (bal0),y
			sta parbase0+{1}+8
			lda (bal1),y
			sta parbase0+{2}+8
			lda (bal2),y
			sta parbase0+{3}+8
			lda (bal3),y
			sta parbase0+{4}+8
			iny
			lda (bal0),y
			sta parbase0+{1}+8+1
			lda (bal1),y
			sta parbase0+{2}+8+1
			lda (bal2),y
			sta parbase0+{3}+8+1
			lda (bal3),y
			sta parbase0+{4}+8+1
			iny
			lda (bal0),y
			sta parbase0+{1}+8+2
			lda (bal1),y
			sta parbase0+{2}+8+2
			lda (bal2),y
			sta parbase0+{3}+8+2
			lda (bal3),y
			sta parbase0+{4}+8+2
			iny
			lda (bal0),y
			sta parbase0+{1}+8+3
			lda (bal1),y
			sta parbase0+{2}+8+3
			lda (bal2),y
			sta parbase0+{3}+8+3
			lda (bal3),y
			sta parbase0+{4}+8+3
			iny
			
			lda (bal0),y
			sta parbase1+{1}+8+4
			lda (bal1),y
			sta parbase1+{2}+8+4
			lda (bal2),y
			sta parbase1+{3}+8+4
			lda (bal3),y
			sta parbase1+{4}+8+4
			iny        
			lda (bal0),y
			sta parbase1+{1}+8+5
			lda (bal1),y
			sta parbase1+{2}+8+5
			lda (bal2),y
			sta parbase1+{3}+8+5
			lda (bal3),y
			sta parbase1+{4}+8+5
			iny        
			lda (bal0),y
			sta parbase1+{1}+8+6
			lda (bal1),y
			sta parbase1+{2}+8+6
			lda (bal2),y
			sta parbase1+{3}+8+6
			lda (bal3),y
			sta parbase1+{4}+8+6
			iny        
			lda (bal0),y
			sta parbase1+{1}+8+7
			lda (bal1),y
			sta parbase1+{2}+8+7
			lda (bal2),y
			sta parbase1+{3}+8+7
			lda (bal3),y
			sta parbase1+{4}+8+7
			iny

			lda (bal0),y
			sta parbase1+{1}+8
			lda (bal1),y
			sta parbase1+{2}+8
			lda (bal2),y
			sta parbase1+{3}+8
			lda (bal3),y
			sta parbase1+{4}+8
			iny        
			lda (bal0),y
			sta parbase1+{1}+8+1
			lda (bal1),y
			sta parbase1+{2}+8+1
			lda (bal2),y
			sta parbase1+{3}+8+1
			lda (bal3),y
			sta parbase1+{4}+8+1
			iny        
			lda (bal0),y
			sta parbase1+{1}+8+2
			lda (bal1),y
			sta parbase1+{2}+8+2
			lda (bal2),y
			sta parbase1+{3}+8+2
			lda (bal3),y
			sta parbase1+{4}+8+2
			iny        
			lda (bal0),y
			sta parbase1+{1}+8+3
			lda (bal1),y
			sta parbase1+{2}+8+3
			lda (bal2),y
			sta parbase1+{3}+8+3
			lda (bal3),y
			sta parbase1+{4}+8+3
			iny        
				   
			lda (bal0),y
			sta parbase0+{1}+8+4
			lda (bal1),y
			sta parbase0+{2}+8+4
			lda (bal2),y
			sta parbase0+{3}+8+4
			lda (bal3),y
			sta parbase0+{4}+8+4
			iny
			lda (bal0),y
			sta parbase0+{1}+8+5
			lda (bal1),y
			sta parbase0+{2}+8+5
			lda (bal2),y
			sta parbase0+{3}+8+5
			lda (bal3),y
			sta parbase0+{4}+8+5
			iny
			lda (bal0),y
			sta parbase0+{1}+8+6
			lda (bal1),y
			sta parbase0+{2}+8+6
			lda (bal2),y
			sta parbase0+{3}+8+6
			lda (bal3),y
			sta parbase0+{4}+8+6
			iny
			lda (bal0),y
			sta parbase0+{1}+8+7
			lda (bal1),y
			sta parbase0+{2}+8+7
			lda (bal2),y
			sta parbase0+{3}+8+7
			lda (bal3),y
			sta parbase0+{4}+8+7
			endm
;------------------------------------------------------------------------------
moveparallax		subroutine
;147/36 143/53
.framepointer		ldx #$00		
.again			ldy .anim,x
			bpl .goon
			ldx #$00
			ldy .anim,x			
.goon			stx .framepointer+1

.framespeed		ldx #$4
			dex
			bpl .goon2
			ldx #$4
			inc .framepointer+1
.goon2			stx .framespeed+1			
			
			lda viewportxlo
			asr #$fe			;remove for static x
			eor #%11111111
			tax
			and #%00000111
			adc .frames,y			;carry clear from asr
			sta bah0			;page is always the same
			sta bah1
			sta bah2
			sta bah3

			txa
			and #%00011000
			asl
			asl
			asl
			
			sta bal0
			adc #$40
			sta bal1
			clc
			adc #$40
			sta bal2
			clc
			adc #$40
			sta bal3

			lda viewportylo
			lsr				;remove for static y
			eor #%11111111
			and #%00011111
			tay
			
			fillrow 0,16,32,48

			rts
			
.frames			dc.b >pattern1,>pattern2,>pattern3,>pattern4,>pattern5,>pattern6,>pattern7,>pattern8
.anim			dc.b $00,$01,$02,$03,$04,$05,$06,$07,$ff

			echo "Code end before map @$5000: ", *

;------------------------------------------------------------------------------
			org $5000
charblock0
 hex F8F8F8F8F8F8F803 080A0A03030DF803 03F8F81C0A0A1E13 F820220B03F80610 F810F8030A0A1301 0A030BF8F8F83233 36333B0A32F83EF8 3F0A0F11010A0A13
 hex 0A0A0A0D11F8015E 0A606421200A680A 6B0A176C036D0A0F 716B0A21603301F8 150A950BF8200A0A 6DF832F86B0A330A 035015F815F80B0A F841310A210A680A
 hex F80801F86D950AF8 010A0A130A5EB5F8 5E130A0BF80A330A 0AB91EF8F8F8F813 41136BB50AC7CB10 F80A03F810F80A0A 10150A0EF8D7F801 B40AF8F8105EF806
 hex DF10E15E01031A0A 0A530B0BF80A0AF8 0AE2F8F81AF80AEE F85EF8F806320AF8 5E5EF80BF8F8130A 0AF80AB40A03F817 F8F8500B6DF81E01 5C010FF8010AED00

charblock1
 hex FAFAFAFAFAFA0502 090A0A02020EFA02 07FAFA1B0A0A1414 050A230C04FA0411 FA11FA020A0A1F02 0A022EFAFA051634 37343C0A3D1007FA 400AFA11180A0A14
 hex 0A0A0A0E0EFA025F 0A61340A0A656921 340AFA0402096EFA 7234220A743407FA 090A0A16FA0A962F 09A6165234A7342F 041409FA0905160A FA0AAD190A65AE2F
 hex FA0902FA09B20AFA 1D190A5F0A5FB652 145F0A0CFA19340A 0A0A1F05FAFAFA14 0A1434C3C4C8CC12 100A04FA0EFA0A19 D6090AFAFAD8A602 072F055211DE0504
 hex 5FE0FA14181D020A 0A2F2E2EFA0A0AA6 5B2DFAFA04FA0AFA 101F52FA022E0A52 1414FA1652FA1434 0AFA34070A07FAFA 52FA5F2DEBFA1407 FA1DFA05020A9D00

charblock2
 hex FCFCFCFCFCFC0603 0A0A0B0303FCFC03 0FFCFC1C0A0A1313 060A2403FCFCFC11 FC1101080A0BFC03 0B08FCFCFC311735 3835350A0E110FFC 410B100E530A0B17
 hex 0A0A0AFCFCFC0341 0A62350A0A666A0A 350BFCFC030A6FFC 7335750A0A350FFC 0A930A13FC0A971E 0A411715350A351E FC130A5E0A31170B FC0A536C0A660A5C
 hex FC0B08FC0AB30BFC 26B40A410B413815 15410A035E1A350A 0A0AFCBA10106D13 0A13350AC5C90A13 0E0AFC01FC6D0A6C 410B0BFCFCD94103 0F1EDD150E4106FC
 hex 2EDD1013E5E5030B 0A1EFCFC100A0A41 0A06FC6DFC010AEF F0FC13FC03FC0A15 1313FC1313FC1335 0A5E350F0B0F5EFC 13FCE203ECFC1731 FCE5FC06080BF500

charblock3
 hex FEFEFEFEFEFE0702 0A0A0C0702FE0502 FEFEFE1D0A0A141F 02212502FEFEFE0E FE0E02090A16FE02 2E09FEFEFE09FE0A 393A0A0AFE11FE10 2F420EFE540A16FE
 hex 0A0A0AFEFEFE020A 0A633A2021670A0A 0A16FEFE070A70FE 743A760A213AFE52 0A940A140521981F 0A0AFE090A0A0A1F FE140A140A09FE16 A60A540220670AFE
 hex 051609FE0A0A16A6 0A040A0A0C0AB7AD 090A0A045F1B3A0A B80AFE420EBB095F 0A140A20C6CA0A14 FE0AFE02FE090A04 0A163DFEA6DA0A04 FE14FEADFE0A0710
 hex FEFE0E1FE6E6022E 0A1FFEFEBB0A0A0A 0A04FE09FE020A1F 04FE1FA602FE0A09 5F1F52145FFEF239 545F3AFE16FE14FE 40FE42020EFEFE09 FE2DFE18093D0700

charblock4
 hex F9010303F9111013 0A0A0A0A1317010A 0A03F90A0B1317F9 01270A0A0BF913F9 F911030A0A13F908 0A150B0EF9031343 47274C0A13F950F9 F91351F955150BF9
 hex 0A590A5CF9F95DF9 1377797D270A860A 890AF90B0A6D0A6C 0A898F999A2708F9 5E0A0A13F99FA313 08031EF9890A2732 0BF96DF9AA010B0A 03261315270A860A
 hex F90A5D0F5D0A1EF9 6D0A13F90AF90AF9 F9F9260AF90A990A BF681701F9F9F9F9 13F989CD0AD10A11 10130BF9F9010A0A F9521EF9F9DB01DC 0A0A01F9F9F90113
 hex F9F9E4F9550A0A0A 0A1E320BF9E71EF9 0A13ECF9EDF913E4 F9F903F9411E15F9 F9F90F0BF93EF9F3 0AF98F0A53150F01 F901F9595E11173F 176D5CF91D0A5E00

charblock5
 hex FB020202FB111214 0A0A0A0A14FB070A 1904FB0A1614FBFB 1D282B0A2DFB1FFB 1011020A2F14FB09 0A092DFB051D1F44 48294D0A1FFB14FB 521411FB140916FB
 hex 565A5BFBFBFB0952 14287A7E8083872B 7A2FFB2E0A098C02 8D7A907A28299DFB 5F0A0A1FFBA0A414 091D1FFB7A0A2816 2EFB09FBAB1D2E0A 020A140929AFB02F
 hex FB5409FB090A14FB 090A5F520A522BFB FB520A0AFB0A4D0A C0C2FB1DFBFB05FB 14FB4DCE0AD20A11 11142D05FB020A0A A61314FBFBA51D09 192F1DFB10A6181F
 hex A6A60EFB140A0A0A 6E142E2DFBE814A6 5B400EFB2EFBF10E FBFB02FB0A1F09FB FBFBFB2EFB07FB7A 0AFB901954F4FB02 FB04525A140EFB14 FB09FB5256541400

charblock6
 hex FD030303FD111315 0A0A0A0B13FD060A 1AFD100A1313FDFD 26292C0A0301FDFD 110E080A1E13FD0A 0B0A30FD0626FD45 494A4E0BFDFD51FD 13131110130A13FD
 hex 570A0AFDFD100A13 13297B7F8184882C 8A1EFDFD0A0A0A03 8E7B917B299B9EFD 410A0AFD01A1A517 0A26FD6DA80A0A17 FDFD0AFDAC26FD0B 030A130A9B84B19E
 hex FD320AFD0A0A13FD 0A0B41150B132C6D 6D130A0BFD0A4EBD C10AFD26FDFD31FD 13FD4E9BCFD30A11 0E150FD4FD08D50B 411413FDFDA7260B 1A5C2E5E1141E2FD
 hex E3E3FDFD130A0A0B 6F17FD0FFDE91341 0AE2FD6DFD5EE2FD 5EFD03010AFD0B5E FD10FDFDFD06FD7B 0AFD91B4326CFD03 FDFD130A17FDFDED FD0AFD1357321300

charblock7
 hex FF020204100E1409 0A0A0A1614FF180A 1BFF0E0A1414FFFF 0A2A0A0A0402FFFF 11FF090A141FFF0A 0C0A04FF070AFF46 474B4F16FFFF11FF 14141111140A1FFF
 hex 580A0AFFFF110A14 5F787C2A82850A0A 8B1FFFFF190A0A02 0A7C928B2A9C0EFF 0A0A0AFF1DA20AFF 0A0AFF09A90A0AFF FFFF0AFF5F0AFF2E 1D0A140A9C850A0E
 hex A62E0AFF0A0A1F52 0A2E0AAD165F0A16 AD140A2D520ABCBE 670AFF2FFF520952 14FF4F9CD00A0A0E FF09FF09FF090A0C 0A1F1FFFA60A0A0C 1BFFFF140E0A16FF
 hex 0404FFFF140A0A2E 70FFFFFFA6EA140A 0AEBFF09FF1416FF 1FFF021D0AFF165F A6E0FFFFA607FF7C 2FA692042E04FF07 52FF140AFFFFFF09 FF2FFF14582E1400

colorblock0
 hex 040404040404040C 0C00000C0C0C040C 0C04040C00000C0C 040F0F040C040C0C 040C040C00000C0C 000C04040404040F 0F0F0F0004040C04 0C000C0C0C00000C
 hex 0000000C0C040C0C 00050F0F0F000800 0F000C0C0C0C000C 0F0F000F050F0C04 0C000004040F0000 0C0404040F000F00 0C0C0C040C040400 04040C000F000800
 hex 040C0C040C000004 0C00000C000C0F04 0C0C000404000F00 00080C040404040C 040C0F0F0008080C 04000C040C040000 0C0C000C0409040C 0C0004040C0C040C
 hex 0C0C0C0C0C0C0C00 0004040404000004 000404040C04000C 040C04040C040004 0C0C040404040C00 0004000C000C040C 04040C040C040C0C 0C0C0C040C000C00

colorblock1
 hex 0404040404040C0C 0400000C0C0C040C 0C04040C00000C0C 0C000F0C0C040C0C 040C040C00000C0C 000C0C04040C0C09 0F0909000C0C0C04 0C00040C0C00000C
 hex 0000000C0C040C0C 000909000008080F 0900040C0C040F04 05090F0009090C04 0400000C04000F04 040C0C0C09080904 0C0C0404040C0C00 0400040400080804
 hex 04040C0404000004 0C04000C000C0F0C 0C0C000C04040900 00000C0C0404040C 000C09090508000C 0C000C040C040004 0C040004040F0C0C 0C040C0C0C0C0C0C
 hex 0C0C040C0C0C0C00 00040C0C0400000C 080C04040C040004 0C0C0C040C0C000C 0C0C040C0C040C09 0004090C000C0404 0C040C0C0C040C0C 040C040C0C000400

colorblock2
 hex 0404040404040C0C 0000040C0C04040C 0C04040C00000C0C 0C000F0C0404040C 040C0C0C0004040C 040C0404040C0C0F 090F0F000C0C0C04 04040C0C0400040C
 hex 0000000404040C04 000F0F0000080500 0F0404040C000904 0F0F0900000F0C04 0000000C0400080C 00040C0C0F000F0C 040C000C000C0C04 0400040C0008000C
 hex 04040C0400080404 040C00040404090C 0C04000C0C0C0F00 0000040C0C0C0C0C 000C0F000808000C 0C00040C040C000C 04040404040F040C 0C0C0C0C0C040C04
 hex 0C0C0C0C04040C04 000C04040C000004 000C040C040C000C 0C040C040C04000C 0C0C040C0C040C0F 000C0F0C040C0C04 0C04040C0C040C0C 0404040C0C040C00

colorblock3
 hex 0404040404040C0C 00000C0C0C040C0C 0404040C00000C0C 0C0F0F0C0404040C 040C0C04000C040C 0C04040404040400 0F0F0000040C040C 040C0C0404000C04
 hex 0000000404040C00 00050F0F0F090000 000C04040C000F04 090F0F000F0F040C 0000000C0C0F080C 000004040000000C 040C000C0004040C 0C00040C0F090004
 hex 0C0C040400000C0C 000C00000C000F04 0400000C0C0C0F00 0800040C0C0C040C 000C000F0908000C 0400040C0404000C 000C0C040C05000C 040C040404000C0C
 hex 04040C0C0C0C0C0C 000C04040C000000 000C0404040C000C 0C040C0C0C040004 0C0C0C0C0C040C0F 040C0F040C040C04 0C040C0C0C040404 040C040C040C0C00

blockmap
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0001020300000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000040506 0708090A0B0C0D00 00000E0F10110000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 000000001206070F 1314151617000000 001808191A1B1C00 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000001D11 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 000000061E1F0000 002021121D222324 25260000001D270F 0F08090909092811 0000000000000000
 hex 0000000000000000 0000000000000000 000000000006292A 0000000000000000 00061E1D2B000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0020210012000000 0000002C2D09242E 00001D022723091A 2F30312F321A3334 0000000000000000
 hex 0000000000040535 3605000000000000 0000000000373839 3A2B000000000000 00000000202B0000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 00001D221C000000 0000000000000000 000000353B2B0006 1E00043C3D3E3F00 180F230909090909 0940414209090A43 000000000000001D
 hex 2243060D00000037 4400000000000000 000000000000000E 0F0F1C0000000000 0000000045460F1C 202B000000000000 20460F0F0F1C0000 0000000000000000
 hex 0000000000000000 1D2723090A100211 0000000000000006 0C1E001F00000000 0000003538340000 474831494A4B4909 4C4D4E4F502F5152 0000000000000629
 hex 0953000000000000 0000000000000000 0000000000180F08 0933391E00001D27 541C00000055560A 5702220F0F0F0F10 220858595A0A0B1E 0000000000000000
 hex 0000000000000037 29314B5B325C5D1B 1C00000000060C0D 001D03002C5E4521 0037360500000000 005F600956094209 0961620909332E00 0000000000000047
 hex 63261F0000000000 00000000042B0000 0000000064086559 650A10270F0F2309 090A57220F086649 1A5A594C2F090909 4041090909336700 0000000000000000
 hex 0000000000000001 6809090909420909 0A57030000000000 06290A10696A001D 0300000000000000 00006B0966494F5D 5B4F6C191A0A0D00 0000000000000000
 hex 0000000000000000 0000001D5E000000 0000001D2D090940 4109090909090909 0942090909096D09 404109090942096E 4D4E504B326F0000 0000000000000000
 hex 0000000012060708 494C1A594C4F5909 09420A0F0F1C1D22 707172093E52043C 672C11202B000000 000073746D090909 0909404109241E00 0000000000000000
 hex 0000000000000000 0000007576000000 000064230950194D 4E5D4B3209495D1A 5B4F4C2F0931494C 4D4E5D49304F5009 6162090977260000 0000000000000000
 hex 000000060D1D7879 0940410942090931 5D4F595D090A2377 26067A6326120000 453C7B0F10110000 0000005F724A495D 7C497D7E2F7F0000 0000000000000000
 hex 0000000000000000 000080812600001D 5E20820909420961 6209090909090909 0909090942090909 6162090909090909 091A2F7C0A108300 0000000000000000
 hex 000000000E230909 504D4E324F4C2F09 495D1A091A4C4A0A 1C00000000000000 00067A3D091B1C00 0000004584090909 40410985863F0000 0000000000000000
 hex 0000000000000000 000087391E452B88 8900473D194F1A30 2F4C09655D491A19 094A2F324F6C4C2F 5D32093230493219 09248A0933255200 000037362B000000
 hex 0000000484321A2F 0961620909090909 0909090909094041 0A0F0F0F1011000E 0B1E00718B098C0D 00000064085B2F30 4D4E4C3E52000000 0000000000000000
 hex 0000000000000000 0000000000015E8D 0A1C005509090909 0909090909090909 09090958495B5B2F 8E09090909090909 142E8F15391E0000 0000000000000000
 hex 000000129009093E 914892302F6C4932 1A8E5B2F09194D4E 7C4B1A5909932208 6F000000943D2811 0000007509090909 6162862600000000 0000000000000000
 hex 1D220F0F0F0F1003 0000001D22089513 096F640896494B7C 4C2F50191A09502F 4C32595D09979899 090931494C4A4933 9A009B439C000000 00009D1E00000000
 hex 000000009E146326 005F9FA03D090909 0909090909426162 6E595D502F0986A1 260000002C683334 000004845BA25C33 25A1520000000000 0000000000000000
 hex 75A32F4C594C1467 641C0E2309090956 091B234209090909 0909424041090909 0909090996A4A5A6 5A2F090933151539 1E00555300000000 00001F0000000000
 hex 00000045A7261F00 000000008D094C59 321A495B6C4F4909 09090909093E5206 1E0000008F146700 0000800809093E17 00000000A8015E00 000000000000002C
 hex 680914A909099302 2D0A08595D960966 4F4C4C4F32190958 4F324F4D4E4C0932 5032090909090909 090909096F000000 0004841BAA000000 001F00061E000000
 hex 0000354400000000 00000000873D0909 0942090909090909 4A5D423325260000 00AB1C007326AC00 0000873D09512600 00000000067A2E00 0000000000001D69
 hex 09149AAD09965B49 507C09090909096D 096C595B4A090909 09090961620909AE 1A5D5009315D2F1A 5A2F5B339A000000 00008D09AF830000 0000000035440000
 hex 0000000000000000 00000000008D097C 4C4F6C191A320965 4B5D596F00000000 00B0285E00120000 00000071B13F0000 0000000000000000 00000000001D2D09
 hex 339A048433153D32 4B4C092FA3502F32 320909090909495D 1A321A491A2F0940 4109090909095B59 6C4F50B2B3000000 00005F743E520000 0000000000000000
 hex 0000000000000000 0000000000B492B5 968E1A2F32090909 0909099303000000 00B609761DB71100 0000000000000000 0000000000000000 0000000000750909
 hex 2811004767800809 0909090940410909 09505D2F321A0909 090909420909194D 4E49A32F5D320942 094209B802110000 0000005F26000000 0000000000000000
 hex 0000000000000000 000000060D5F7209 090909090909A349 30315B2F0A1C0000 2C68091B23099311 0000000000000000 0000000000000000 0000000000476360
 hex B926000064130950 49302F5B4D4E1A09 0909090909090909 495B964F594C0961 620942090909324F 5B4F50594C2A042B 000000009C000000 0000000000000000
 hex 0000000000000000 0000000000458450 59582F5D1A090909 0909090942285E00 B00919583250339A 0000000000000000 0000000000000000 0000BA00000012BB
 hex 2E00006423094209 0909090961620909 090949968E323209 0909505D2F65095B 49A34F1A8E095B4F 304F1A2F4A2883BC 0000000000000000 0000000000000000
 hex 0000000000000000 000000000000BD09 964F1A5931320949 5D7C494C4FA3891D 6909505D2F650A10 1100000000000000 0000000000000000 BEBFC0000000C11D
 hex 830122231A5D4F49 4A09094C594C4930 2F09090909090909 0909090909090909 0942404109090940 410909094233C29C 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000006B42 0909090909090909 095B499632090A23 09090909143D0977 2600000000000000 0000000000000000 C345C40D1D27C523
 hex C608094209094041 0909090909090909 09321A8E5B2F09A3 498E49A309321A49 5D4F4D4E4C09964D 4E4C5A494FC70045 0500000000000000 0000000000000000
 hex 0000000000000000 000000000000AD4F 50594C0909304B5B 1A4F321A8E5B2F09 304A6C339A719167 0000000000000000 0000000000000000 0000000075094A2F
 hex 5B8E324F4A097D7E 5B494C502F0914A9 0909090909090909 4041090909090909 090961620909C861 6209090909C90000 061E000000000000 0000000000000000
 hex 0000000000000000 00000000006408A2 5C0909305D420909 0909420909090909 090933390C0D0000 0000000000000000 0000000000000000 000045460833153D
 hex 143D090909096185 153D0909093E26AD 095D49962F4C494B 7D7E2F09A32F4C1A 49A309095D2F665B 2FA3093363520000 00AC000000000000 0000000000000000
 hex 0000000000000000 00000000009E0909 09090909324F4A09 09584F965D494C1A 3224670000000000 0000000000000000 0000000000000000 00001D6809C70090
 hex CA47585D5A336317 0071740909CBCC08 0909090942090909 6185094041090909 CD09090942096D09 CE15A96F00000000 BC00000000000000 0000000000000000
 hex 0000000000000000 0000000000CF652F 5B5B2FD009090909 0909090909420909 863F000000000000 000102031D021100 0000000000000000 AB0F233315670094
 hex D1D2473DCE671D02 02035F72097F5F60 2F5B8E324F4B3009 5B2F304D4E4C0932 595B4B1A4F594C77 529CD3931100001D 5E00000000000000 0000000000000000
 hex 0000000000000000 00000000006B092F 5D4A96495B5B0931 5D5932594C4FA33E 5200000000000000 1D68090A23099311 0000000000000000 8809336700000000
 hex 8FC20047D4D52949 6E5B0F0809891D69 0940410909090909 0909096162090909 0909090909090928 221C004734002C2D 6A00000000000000 0000000000000000
 hex 0000000000000000 0000000000738B09 0909094209090909 0909090909093E26 00000000000000AB 230909090909421B 1C00000000000000 47D6670000000006
 hex D70000D8D9004715 4809A25C090A2349 5B7D7E591A2F5019 094A2F7C494A2F4C 502F09A32F4C594C 09CB00000004A7A1 5200000000000000 0000000000000000
 hex 0000000000000000 0000000000007372 30494C4F49503209 14A9491A49862600 00000000000000B0 491A5B494C1A4F32 C700000000000000 1DDA0202270F0F70
 hex 0000000000000000 DB792F582F5D0909 4261850909090909 4209404109090940 4109090909090909 09AF1100000037B3 0000000000000000 0000000000000000
 hex 0000000000000000 00000000000000BD B54C594F322F3363 2673918A77520000 00000000000000BB 3D09090909090914 6700000000000064 230940410909421B
 hex 1011CCDC0F10031D 2D0909090909495D 4F322F095B2F3132 4F094D4EA38E5D4D 4E4C092FA31A2F4C 4A09DD0000000000 0000000000000000 0000000000000000
 hex 0000000000000000 00000000000000BB DE48090909336700 000000DF28D20000 0000000000000000 E009090933152526 0000000000001D2D 096E4D4E32324F5B
 hex 091B130942090A23 09095D595B2FB991 15489209094A2F09 0909090909979899 0909090909420909 0977520000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 E1E260966EC70000 0000008763520000 0000000000000000 5F8B0909C7000000 0000000000642340 4109616209420909
 hex 0919595D4F5A594C 09E38B090909AF11 005F911515154892 4A491A494AA4A5A6 5D094A2F324F5D2F 1467A80000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 5F52E47909281100 00000020E5030000 0000000000000000 007391A90AAA0000 000000000482097D 7E2F4C2F324F3240
 hex 4109090909090909 092A873D491A2F1B 0F1C000000005F8B 0909090933151548 0909C80933480986 2600000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 00005F749209CB00 180B0D0071E63605 0000000000000000 00000073912E0000 0000000000550961 8509420909315D4D
 hex 4EE72F501A095B6C 490AAA8D92964F1A E8B24400000000E9 797CEA33C900005F 725B661A28E2B152 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000005F9FA07B0F 0828110000000000 0000000000000000 0000000000000000 0000000045842F5B 8E324F4B30090961
 hex 6209094209090909 4209AFE28B090933 635200000000005F 8B09E88652000000 8DCE6D0909B81100 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 000000000000719F A0A91B1C00000000 0000000000000000 0000000000000000 00000000008D9209 0909090909495050
 hex 2F32324F594C0958 4F502FEB94A98617 0000000000000000 5F60EC5200000000 5F5255143D097F00 0000AB7000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 00739139ED000E0F 5457110000000000 0000000000000000 00000000005F913D 324930495D090909
 hex 420909090909091A 2F49300A10EEEFD2 0000000000000000 00F067F100000000 0000473447253F00 0000BB3400000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 00000000F207084B 3140F30F10110000 0000000000000000 0000000000000047 1563911563913D32
 hex 4F4C6C4B5B495D09 0909090942C68152 0000000000000000 000000F400000000 004521009C000000 000000373B2B0000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000AD5D59 4B7D7E19091B0F1C 0000000000000000 0000000000000000 0000000000008D92
 hex 0909094041090909 091A5D324F246700 0000000000000000 0000000000000000 00373BF500000000 00A800009C000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 000000001D680942 09090909501A5D0A 5711000000000000 0000000000000000 0000000000005F72
 hex 5D2F324D4E4B5D50 2F09090914F60000 0000000000000000 0000000000000000 00373BF500000000 015E00452B000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 00000000D309324F 2F321A4909090909 0993110000000000 0000000000000000 00000000000000E1
 hex 9209096162420909 0909093E26000000 0000000000000000 0000000000000000 00009D0C1E000006 7A2E1D5E0000009D 1E001D1100000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 00000004F7090909 0940410949968E32 3240F30F1C000000 0000000000000000 000000000000005F
 hex 7492494C504F2F4C 1A32E8DD00000000 0000000000000000 0000000000000000 0000003736050000 0000733F373B2B00 0006292A00000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000073720909 504D4E4C4C2F501A 4F4D4E4C0A1C0000 0000000000000000 0000000000000000
 hex 873D090909090909 090933F800000000 0000000000000000 0000000000000000 000000009D0C3A05 0000000000000000 00004739071C0000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000473D09 0961620909090956 C8616209096F0000 0000000000000000 0000000000000000
 hex 1D685B2F1A19495D 6C8E281100000000 0000000000000000 0000000000000000 0000000000000000 0000BC00060D0000 0000000073A14400 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 000000000000473D 321A8E5B2F095966 662F4C502FDD0000 0000000000000000 0000000000000000
 hex 7509090909404142 0909243400000000 0000000000000000 0000000000000000 0000000000000000 0000000000009C0E 1C0000C100000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000047 3D0909090909096D 6D090909B9520000 0000000000000000 0000000000000004
 hex 84094A30497D7E4F 5014F600001D5E00 0000000000000000 0000000000000000 0000000000000000 000000000E102208 0A1C00F9FA000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 8D968E1A2F5D4931 2F5D32E86A000000 0000000000000000 0000000000000000
 hex 8D92090909618509 7726000080236A00 0000000000000000 0000000000000000 0000000000000000 00001D2208321949 312F0F08B8110000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 B479090940410909 0909336352000000 0000000000000000 0000000000000000
 hex 5F60E74B4A4932E8 B2B30000FB635200 0000000000000000 0000000000000000 0000000000000000 0001FC4109090909 09404109092A0000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 DB791A5D4D4E318E A3CE670000000000 0000000000000000 0000000000000000
 hex 006B090909090951 5200000000000000 0000000000000000 0000000000000000 0000000000000000 AB084D4E4C325B49 4B7D7E191A0AAA00 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 D309090961624209 33F8000000000000 0000000000000000 0000000000000000
 hex 00737250325024F6 0000000000000000 0000000000000000 0000000000000000 0000000000000000 B009616209090909 0961850909098900 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 9E495D322F4C4F50 6F00000000000000 0000000000000000 0000000000000000
 hex 0000BD090924F600 0000000000000000 0000000000000000 0000000000000000 0000000000000000 CF09315B4B321909 30498E4A498EFDB3 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 CF09090909093315 9A00000000000000 0000000000000000 0000000000000000
 hex 0000BB15253F0000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 88E8CE151515A909 090909090909C900 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 CF2FA3594C511700 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000037 3816520000007315 153D582F4C3E5200 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 88090909332E0000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 1D680909249A0000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 55315830C9000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 5F911515F6000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 473DE88652000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 4584775200000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000060D00000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 04848C1E00000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 00000000060D0000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0055281100000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000452B00000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0047A9CB00000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 00061E0000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 000073FE1E000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
 hex 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000

;------------------------------------------------------------------------------
spe_xstart0		equ 4
spe_ystart0		equ 1
spe_numcoords0		equ 3264

;8 bit delta x,y
			align 256,0
spe_datax0
 dc.b $00,$00,$00,$FF,$00,$00,$FF,$00,$FF,$00,$00,$FF,$00,$00,$00,$01,$00,$01,$00,$01,$01,$01,$01,$01,$02,$01,$01,$02,$01,$02,$01,$02
 dc.b $01,$01,$02,$01,$02,$01,$02,$02,$01,$02,$02,$02,$01,$02,$02,$02,$02,$02,$02,$02,$01,$02,$02,$02,$02,$02,$02,$02,$03,$03,$03,$04
 dc.b $04,$04,$05,$05,$05,$06,$05,$06,$06,$06,$07,$07,$07,$07,$07,$08,$07,$08,$09,$0A,$0A,$0A,$0A,$0B,$0B,$0A,$0A,$0A,$0A,$09,$08,$08
 dc.b $06,$06,$05,$04,$04,$03,$03,$02,$02,$02,$02,$02,$01,$02,$02,$03,$02,$03,$02,$03,$02,$02,$03,$02,$02,$03,$02,$03,$02,$03,$03,$04
 dc.b $03,$04,$04,$03,$04,$04,$04,$05,$04,$05,$04,$05,$05,$06,$05,$06,$05,$06,$07,$07,$07,$08,$08,$07,$08,$08,$08,$07,$08,$07,$06,$07
 dc.b $05,$06,$05,$04,$05,$04,$05,$03,$04,$04,$03,$03,$03,$03,$02,$02,$02,$02,$01,$00,$01,$00,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$00
 dc.b $01,$01,$02,$02,$02,$02,$03,$02,$03,$02,$03,$02,$01,$02,$01,$00,$00,$FF,$FF,$FE,$FE,$FD,$FD,$FD,$FC,$FD,$FD,$FC,$FD,$FD,$FD,$FD
 dc.b $FE,$FE,$FE,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FF,$FF,$00,$FF,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$03,$04,$03,$04,$04,$05,$04
 dc.b $04,$05,$05,$06,$06,$06,$06,$06,$07,$06,$07,$06,$07,$06,$06,$06,$05,$06,$05,$05,$05,$05,$05,$04,$05,$05,$04,$05,$04,$05,$05,$05
 dc.b $04,$05,$05,$06,$05,$05,$05,$05,$06,$05,$05,$05,$05,$05,$04,$05,$04,$05,$04,$05,$05,$04,$05,$05,$04,$04,$04,$03,$03,$03,$02,$02
 dc.b $01,$01,$00,$FF,$FF,$FF,$FE,$FE,$FE,$FE,$FD,$FD,$FD,$FD,$FC,$FD,$FD,$FC,$FC,$FD,$FB,$FC,$FC,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FA,$FB
 dc.b $FA,$FB,$FA,$FA,$FA,$FA,$FA,$FA,$F9,$FA,$FA,$F9,$FA,$F9,$F9,$FA,$F9,$FA,$F9,$F9,$F9,$F8,$F9,$F9,$F9,$F8,$F9,$F9,$F9,$FA,$F9,$FA
 dc.b $FA,$FB,$FA,$FB,$FB,$FC,$FB,$FB,$FC,$FC,$FB,$FC,$FC,$FB,$FC,$FB,$FB,$FC,$FB,$FB,$FC,$FB,$FB,$FB,$FC,$FB,$FB,$FB,$FB,$FB,$FB,$FB
 dc.b $FA,$FA,$FA,$F9,$F8,$F9,$F8,$F8,$F8,$F9,$F9,$FA,$FB,$FB,$FD,$FE,$FF,$00,$01,$02,$02,$03,$03,$05,$05,$06,$06,$07,$08,$09,$09,$0A
 dc.b $0B,$0B,$0D,$0F,$0F,$10,$11,$11,$12,$12,$13,$12,$12,$12,$11,$10,$10,$0F,$0F,$0F,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0F,$10,$0F
 dc.b $10,$12,$12,$13,$14,$14,$14,$15,$14,$14,$14,$13,$12,$11,$0F,$0E,$0D,$0B,$09,$07,$07,$06,$04,$04,$04,$03,$03,$04,$03,$04,$05,$06
 dc.b $06,$08,$08,$09,$09,$09,$0A,$0A,$0A,$0A,$09,$09,$08,$08,$06,$06,$05,$03,$03,$02,$01,$00,$00,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF
 dc.b $00,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$00,$FF,$00,$FF,$FF,$FE,$FF,$FE,$FE,$FE,$FD,$FE,$FD,$FE,$FD,$FD,$FE,$FD,$FD,$FE
 dc.b $FE,$FD,$FE,$FE,$FD,$FE,$FE,$FE,$FD,$FE,$FE,$FD,$FE,$FD,$FE,$FD,$FD,$FE,$FD,$FD,$FC,$FD,$FD,$FD,$FC,$FD,$FD,$FD,$FC,$FD,$FD,$FD
 dc.b $FD,$FE,$FD,$FE,$FD,$FD,$FE,$FE,$FD,$FE,$FE,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FF,$FE,$FE,$FF,$FE,$FE
 dc.b $FF,$FE,$FE,$FE,$FD,$FE,$FE,$FD,$FE,$FE,$FF,$FE,$00,$FF,$00,$01,$01,$02,$03,$04,$04,$04,$05,$05,$05,$06,$05,$06,$05,$06,$05,$05
 dc.b $04,$04,$05,$04,$05,$04,$05,$04,$04,$04,$04,$04,$04,$03,$03,$02,$02,$02,$02,$01,$01,$00,$01,$00,$00,$00,$00,$FF,$00,$00,$FF,$FF
 dc.b $00,$FF,$FF,$00,$FF,$FE,$FF,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FD,$FE,$FE,$FE,$FE,$FE,$FE
 dc.b $FF,$FE,$FF,$FE,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FE,$FD,$FE,$FE,$FD,$FE,$FD,$FD,$FD,$FD,$FE,$FD,$FD,$FD,$FD,$FD
 dc.b $FD,$FE,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FE,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FE,$FE
 dc.b $FD,$FE,$FE,$FD,$FD,$FE,$FD,$FE,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FC,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FC,$FD,$FC,$FC,$FB,$FB,$FA,$FA
 dc.b $F9,$F8,$F8,$F6,$F6,$F5,$F5,$F5,$F5,$F4,$F5,$F5,$F6,$F6,$F7,$F7,$F9,$FA,$FA,$FA,$FB,$FB,$FC,$FB,$FD,$FC,$FD,$FD,$FD,$FE,$FD,$FE
 dc.b $FD,$FE,$FF,$FE,$FF,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$01,$01,$00,$01,$01,$01,$01,$00,$01,$01
 dc.b $00,$01,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 dc.b $00,$00,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$00,$00,$00,$01,$01,$02,$01,$02,$02,$02,$03,$02,$02,$03,$03,$02,$03,$03,$02
 dc.b $03,$02,$03,$02,$03,$03,$02,$03,$03,$03,$03,$02,$03,$03,$04,$03,$03,$03,$04,$03,$04,$04,$04,$04,$04,$04,$03,$04,$04,$04,$03,$04
 dc.b $03,$03,$04,$03,$03,$03,$04,$03,$03,$03,$02,$03,$03,$02,$03,$02,$02,$01,$02,$01,$02,$01,$01,$01,$01,$00,$01,$01,$00,$01,$00,$01
 dc.b $00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$00,$01,$01,$01,$02
 dc.b $02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$04,$03,$04,$04,$04,$04,$05,$04,$05,$05,$05,$05,$05,$05,$06,$05,$06,$06,$06,$06,$06
 dc.b $06,$06,$07,$06,$07,$07,$07,$07,$07,$07,$07,$08,$07,$07,$08,$07,$08,$07,$08,$08,$08,$08,$08,$09,$08,$08,$08,$08,$07,$08,$07,$07
 dc.b $06,$06,$06,$06,$06,$05,$06,$05,$05,$04,$05,$05,$04,$04,$04,$04,$04,$04,$03,$02,$02,$02,$02,$02,$02,$02,$02,$03,$03,$03,$04,$05
 dc.b $05,$06,$07,$08,$08,$08,$09,$0A,$09,$09,$09,$09,$09,$08,$08,$08,$06,$07,$05,$06,$06,$05,$05,$05,$04,$05,$04,$04,$04,$04,$04,$04
 dc.b $04,$04,$04,$04,$03,$03,$04,$03,$03,$03,$03,$02,$03,$03,$03,$02,$03,$03,$02,$03,$02,$03,$02,$03,$02,$02,$03,$02,$01,$02,$02,$01
 dc.b $01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$01,$01,$00,$01,$01,$01,$01,$02,$01,$01,$02,$01,$02,$02
 dc.b $02,$02,$02,$03,$02,$03,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$03,$03,$03,$04,$03,$04,$03,$03,$04,$03,$04
 dc.b $03,$04,$04,$04,$03,$04,$04,$04,$04,$04,$04,$04,$03,$04,$04,$03,$03,$03,$04,$03,$03,$02,$03,$03,$03,$02,$03,$03,$02,$02,$03,$02
 dc.b $02,$02,$02,$01,$02,$01,$01,$02,$01,$01,$01,$02,$01,$02,$01,$02,$02,$02,$03,$02,$03,$04,$03,$03,$03,$03,$03,$02,$02,$02,$01,$01
 dc.b $00,$FF,$FF,$FF,$FE,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$FF,$FE,$FE,$FE,$FD,$FD,$FD,$FD,$FC,$FC,$FC,$FB,$FC,$FB,$FC,$FB,$FC,$FB,$FC
 dc.b $FB,$FC,$FB,$FB,$FB,$FB,$FB,$FB,$FA,$FB,$FB,$FC,$FB,$FB,$FC,$FC,$FC,$FD,$FD,$FC,$FD,$FD,$FE,$FD,$FD,$FE,$FE,$FD,$FE,$FE,$FD,$FE
 dc.b $FE,$FE,$FE,$FE,$FE,$FF,$FE,$FE,$FF,$FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FE,$FD,$FE,$FE,$FD,$FE,$FD,$FD,$FE,$FD,$FD,$FD,$FE,$FD,$FD
 dc.b $FD,$FD,$FD,$FD,$FD,$FD,$FC,$FD,$FD,$FD,$FC,$FD,$FC,$FC,$FC,$FB,$FC,$FB,$FA,$FA,$FA,$F9,$F9,$FA,$F9,$F9,$FA,$FA,$FB,$FB,$FC,$FC
 dc.b $FE,$FE,$FE,$FF,$FF,$00,$00,$00,$01,$01,$01,$02,$02,$03,$03,$03,$04,$04,$05,$05,$06,$07,$07,$07,$07,$07,$08,$07,$07,$07,$07,$07
 dc.b $06,$06,$06,$06,$06,$05,$06,$06,$06,$05,$06,$05,$06,$05,$06,$05,$06,$05,$05,$06,$05,$06,$05,$05,$05,$05,$05,$05,$05,$05,$04,$05
 dc.b $04,$04,$04,$04,$04,$03,$04,$03,$03,$03,$04,$03,$03,$03,$03,$03,$02,$03,$03,$02,$02,$03,$02,$02,$02,$02,$03,$02,$02,$03,$02,$03
 dc.b $02,$03,$03,$02,$03,$03,$02,$03,$03,$03,$03,$04,$03,$04,$04,$04,$04,$05,$05,$06,$06,$06,$06,$06,$06,$06,$07,$06,$05,$06,$05,$05
 dc.b $04,$04,$04,$04,$04,$04,$03,$03,$03,$03,$03,$02,$03,$02,$02,$02,$02,$01,$02,$01,$01,$00,$01,$00,$00,$01,$00,$00,$00,$FF,$00,$00
 dc.b $00,$00,$FF,$00,$00,$FF,$00,$FF,$FF,$00,$FF,$FF,$FF,$FE,$FF,$FF,$FE,$FF,$FE,$FE,$FE,$FD,$FE,$FE,$FD,$FE,$FD,$FE,$FD,$FE,$FD,$FE
 dc.b $FE,$FE,$FE,$FE,$FE,$FF,$FE,$FE,$FF,$FE,$FD,$FE,$FE,$FD,$FC,$FD,$FC,$FB,$FC,$FA,$FB,$FA,$FA,$FA,$FA,$FA,$FA,$F9,$FA,$FA,$FA,$FA
 dc.b $FA,$FA,$FA,$FB,$FA,$FA,$FA,$FA,$FB,$FA,$FA,$FA,$FB,$FA,$FA,$FB,$FA,$FB,$FA,$FB,$FB,$FA,$FB,$FB,$FB,$FA,$FB,$FB,$FA,$FA,$FB,$FA
 dc.b $FA,$F9,$F9,$F9,$F9,$F8,$F9,$F8,$F9,$F8,$F9,$F9,$FA,$FA,$FB,$FB,$FC,$FC,$FD,$FD,$FE,$FD,$FF,$FE,$FF,$FF,$FF,$FF,$00,$FF,$00,$00
 dc.b $00,$00,$01,$00,$01,$02,$01,$02,$01,$02,$02,$02,$02,$02,$02,$02,$02,$02,$03,$02,$03,$02,$03,$03,$02,$03,$03,$03,$03,$03,$03,$03
 dc.b $03,$02,$03,$03,$03,$03,$02,$03,$03,$03,$03,$03,$04,$03,$04,$03,$04,$04,$05,$04,$05,$05,$05,$05,$05,$05,$05,$05,$04,$05,$05,$04
 dc.b $04,$05,$04,$04,$04,$04,$04,$04,$04,$04,$03,$04,$03,$04,$03,$03,$03,$02,$02,$03,$01,$02,$02,$02,$01,$02,$01,$02,$02,$03,$02,$03
 dc.b $03,$03,$04,$04,$04,$04,$04,$04,$05,$04,$05,$04,$04,$04,$05,$03,$04,$04,$03,$04,$03,$03,$04,$03,$03,$03,$04,$03,$03,$04,$03,$04
 dc.b $03,$04,$03,$04,$04,$04,$03,$04,$04,$04,$04,$04,$03,$04,$04,$04,$03,$04,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$04,$04,$04,$05
 dc.b $05,$06,$05,$06,$07,$06,$07,$07,$07,$07,$07,$07,$07,$07,$07,$06,$07,$06,$07,$06,$06,$06,$06,$06,$07,$06,$06,$06,$07,$06,$07,$06
 dc.b $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$08,$07,$07,$07,$08,$07,$07,$08,$07,$07,$08,$07,$07,$08,$07,$08,$07,$08,$08,$08,$08,$08
 dc.b $08,$09,$09,$09,$0A,$09,$0A,$09,$0A,$0A,$09,$09,$09,$09,$09,$08,$08,$07,$08,$07,$07,$07,$06,$07,$06,$07,$06,$06,$06,$06,$06,$06
 dc.b $06,$06,$05,$06,$06,$06,$05,$06,$05,$06,$05,$05,$04,$05,$04,$05,$03,$04,$03,$04,$02,$03,$03,$02,$03,$02,$02,$02,$02,$03,$02,$02
 dc.b $03,$02,$02,$03,$02,$03,$02,$02,$03,$02,$02,$02,$02,$02,$02,$01,$02,$01,$02,$01,$00,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$02
 dc.b $01,$01,$01,$02,$01,$01,$02,$01,$02,$01,$02,$02,$02,$02,$02,$02,$03,$02,$03,$02,$03,$03,$03,$03,$04,$03,$03,$04,$03,$04,$03,$04
 dc.b $03,$04,$04,$03,$04,$04,$04,$04,$04,$04,$04,$04,$05,$04,$05,$04,$05,$05,$06,$06,$06,$06,$06,$06,$06,$06,$05,$06,$05,$05,$04,$04
 dc.b $03,$03,$03,$02,$03,$01,$02,$02,$01,$01,$00,$01,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FE,$FE,$FE,$FD,$FE,$FD,$FC,$FD,$FC,$FD,$FC,$FB
 dc.b $FC,$FB,$FB,$FB,$FB,$FA,$FA,$FA,$FA,$F9,$F9,$FA,$F9,$F9,$F9,$F8,$F9,$F8,$F9,$F8,$F8,$F7,$F8,$F7,$F8,$F7,$F7,$F7,$F7,$F7,$F8,$F7
 dc.b $F7,$F7,$F7,$F6,$F7,$F7,$F6,$F7,$F6,$F7,$F6,$F7,$F7,$F7,$F8,$F8,$F7,$F9,$F8,$F9,$F8,$F9,$F9,$F9,$FA,$F9,$F9,$F9,$F9,$F9,$F9,$F9
 dc.b $F9,$F9,$F8,$F9,$F8,$F9,$F9,$F8,$F9,$F8,$F9,$F8,$F9,$F9,$F8,$F9,$F9,$F9,$F9,$F8,$F9,$F9,$F9,$F9,$F8,$F9,$FA,$F9,$F9,$F9,$FA,$FA
 dc.b $FA,$FA,$FA,$FB,$FB,$FB,$FA,$FC,$FB,$FB,$FB,$FA,$FB,$FB,$FA,$FB,$FA,$FA,$F9,$FA,$F9,$FA,$F9,$F9,$F9,$F9,$FA,$F9,$FA,$F9,$FA,$FA
 dc.b $FA,$FA,$FA,$FA,$FA,$FA,$FB,$FA,$FB,$FA,$FB,$FB,$FB,$FB,$FC,$FB,$FC,$FC,$FC,$FC,$FC,$FD,$FD,$FC,$FD,$FD,$FD,$FE,$FD,$FE,$FE,$FE
 dc.b $FE,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$01,$00,$01,$01,$01,$01,$01,$01,$02,$01,$02,$02,$01,$02,$02
 dc.b $03,$02,$02,$03,$03,$02,$03,$03,$03,$03,$04,$03,$03,$03,$04,$03,$04,$03,$03,$04,$03,$04,$03,$04,$04,$04,$04,$04,$04,$04,$04,$05
 dc.b $05,$04,$05,$06,$05,$05,$06,$05,$06,$06,$05,$06,$06,$05,$06,$06,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$06,$05,$06,$07,$06,$07
 dc.b $08,$08,$08,$09,$09,$0A,$09,$0A,$0A,$0A,$09,$0A,$0A,$09,$09,$08,$08,$08,$08,$08,$08,$07,$08,$07,$08,$07,$06,$07,$07,$06,$06,$06
 dc.b $05,$05,$05,$05,$04,$04,$04,$04,$04,$03,$04,$04,$03,$04,$03,$04,$04,$04,$04,$04,$04,$04,$04,$04,$03,$04,$04,$03,$04,$03,$03,$02
 dc.b $03,$02,$02,$02,$01,$01,$02,$01,$01,$01,$01,$01,$02,$01,$02,$02,$03,$03,$02,$03,$04,$03,$03,$04,$03,$03,$04,$03,$04,$03,$03,$03
 dc.b $03,$03,$03,$03,$02,$03,$02,$03,$03,$02,$03,$03,$02,$03,$03,$03,$04,$03,$03,$04,$03,$04,$04,$04,$03,$04,$04,$04,$04,$04,$03,$04
 dc.b $04,$04,$05,$04,$05,$05,$04,$05,$05,$04,$04,$04,$03,$03,$02,$02,$01,$00,$01,$FF,$00,$FE,$FF,$FE,$FF,$FE,$FD,$FE,$FE,$FE,$FE,$FD
 dc.b $FE,$FE,$FF,$FE,$FE,$FE,$FE,$FD,$FE,$FD,$FE,$FC,$FD,$FC,$FC,$FB,$FB,$FA,$FA,$FA,$F9,$FA,$F8,$F9,$F8,$F9,$F8,$F7,$F8,$F8,$F7,$F8
 dc.b $F7,$F7,$F7,$F6,$F7,$F6,$F6,$F6,$F6,$F6,$F5,$F6,$F6,$F5,$F6,$F6,$F6,$F5,$F5,$F6,$F5,$F5,$F5,$F5,$F5,$F5,$F5,$F6,$F5,$F7,$F6,$F7
 dc.b $F7,$F7,$F8,$F7,$F8,$F8,$F9,$F8,$F9,$F9,$F9,$F9,$F9,$F9,$FA,$F9,$FA,$F9,$FA,$F9,$FA,$FA,$FA,$FA,$FA,$FB,$FA,$FB,$FB,$FC,$FC,$FC
 dc.b $FC,$FD,$FD,$FD,$FD,$FE,$FE,$FE,$FE,$FF,$FE,$FF,$FF,$00,$FF,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$01,$03,$02,$02,$03,$03
 dc.b $02,$04,$03,$04,$04,$04,$04,$04,$05,$04,$05,$05,$04,$05,$05,$04,$05,$04,$05,$04,$05,$04,$05,$04,$05,$05,$05,$05,$06,$06,$06,$06
 dc.b $07,$07,$07,$08,$09,$08,$09,$08,$09,$09,$08,$09,$08,$08,$08,$07,$07,$07,$07,$06,$07,$06,$06,$06,$06,$06,$06,$05,$06,$05,$05,$05
 dc.b $05,$05,$05,$04,$05,$04,$04,$04,$04,$04,$04,$04,$03,$04,$03,$04,$03,$03,$03,$03,$03,$03,$02,$03,$02,$03,$02,$03,$02,$02,$02,$03
 dc.b $02,$02,$03,$02,$02,$02,$03,$02,$02,$02,$01,$02,$01,$01,$01,$01,$00,$01,$00,$00,$01,$00,$FF,$00,$FF,$FF,$FF,$FE,$FE,$FE,$FD,$FC
 dc.b $FC,$FC,$FB,$FB,$FA,$FA,$F9,$F9,$F9,$F9,$F8,$F9,$F8,$F9,$F8,$F9,$F8,$F8,$F8,$F7,$F7,$F7,$F6,$F7,$F7,$F7,$F7,$F8,$F8,$F9,$F9,$FA
 dc.b $FA,$FB,$FB,$FB,$FC,$FC,$FD,$FD,$FD,$FD,$FE,$FE,$FE,$FF,$FF,$FF,$00,$00,$01,$01,$01,$02,$02,$03,$02,$03,$03,$02,$03,$02,$03,$02
 dc.b $02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$03,$02,$03,$03,$04,$04,$04,$04,$05,$05,$06,$05,$06,$06,$06,$06,$06,$07,$07,$06,$07
 dc.b $07,$08,$07,$08,$08,$08,$08,$08,$09,$08,$09,$08,$09,$09,$09,$08,$09,$0A,$09,$0A,$0B,$0A,$0A,$0B,$0A,$0A,$09,$09,$09,$08,$07,$07
 dc.b $05,$05,$05,$04,$04,$03,$03,$03,$02,$02,$02,$01,$01,$01,$01,$01,$00,$01,$FF,$00,$FF,$FE,$FF,$FE,$FF,$FE,$FE,$FE,$FF,$FE,$FE,$FF
 dc.b $FF,$FF,$FE,$FF,$FE,$FF,$FF,$FE,$FF,$FF,$FE,$FF,$00,$FF,$FF,$00,$00,$00,$00,$FF,$00,$01,$00,$00,$01,$01,$01,$01,$01,$02,$02,$03
 dc.b $03,$03,$03,$04,$04,$04,$05,$05,$05,$05,$05,$05,$05,$06,$05,$06,$05,$06,$06,$06,$07,$06,$07,$06,$07,$07,$06,$07,$06,$06,$06,$06
 dc.b $05,$05,$06,$04,$05,$05,$05,$04,$05,$04,$05,$04,$05,$05,$04,$05,$05,$05,$06,$05,$06,$06,$06,$06,$05,$05,$05,$04,$04,$03,$02,$02
 dc.b $01,$FF,$FF,$FF,$FD,$FE,$FC,$FD,$FC,$FC,$FC,$FD,$FC,$FC,$FD,$FD,$FE,$FD,$FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FD,$FE,$FC,$FD,$FC,$FB
 dc.b $FB,$FB,$FA,$FA,$FA,$F9,$F9,$F9,$F8,$F9,$F8,$F7,$F8,$F7,$F7,$F7,$F7,$F6,$F5,$F6,$F5,$F4,$F5,$F4,$F4,$F5,$F4,$F4,$F4,$F4,$F5,$F4
 dc.b $F5,$F5,$F5,$F6,$F5,$F5,$F6,$F5,$F5,$F5,$F5,$F4,$F4,$F4,$F4,$F3,$F3,$F2,$F1,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F1,$F1,$F1,$F3,$F3,$F4
 dc.b $F5,$F6,$F6,$F7,$F7,$F8,$F8,$F9,$F9,$F9,$FA,$FA,$FA,$FA,$FA,$FB,$FB,$FB,$FC,$FC,$FC,$FC,$FD,$FD,$FD,$FE,$FD,$FE,$FE,$FE,$FF,$FE
 dc.b $7f

			align 256,0
spe_datay0
 dc.b $00,$03,$04,$04,$05,$06,$06,$06,$06,$06,$07,$06,$07,$06,$05,$06,$05,$05,$04,$05,$04,$04,$04,$04,$04,$03,$04,$04,$04,$04,$04,$05
 dc.b $04,$05,$04,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$06,$05,$05,$05,$06,$06,$06,$06,$06,$06,$06,$06,$05,$06,$05,$06,$04,$05
 dc.b $04,$04,$03,$03,$02,$02,$02,$02,$02,$02,$01,$02,$02,$02,$02,$03,$03,$03,$03,$03,$02,$03,$03,$03,$03,$04,$04,$04,$05,$06,$06,$07
 dc.b $08,$09,$0A,$0B,$0C,$0C,$0D,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0C,$0D,$0D,$0C,$0D,$0D,$0D,$0C,$0D,$0C,$0D,$0C,$0C,$0C,$0C,$0C
 dc.b $0B,$0C,$0B,$0C,$0B,$0B,$0B,$0B,$0B,$0A,$0B,$0A,$09,$0A,$09,$08,$08,$08,$08,$08,$08,$07,$08,$06,$07,$06,$05,$05,$04,$04,$02,$02
 dc.b $01,$00,$FE,$FE,$FD,$FC,$FB,$FA,$FB,$F9,$FA,$FA,$F9,$FA,$FA,$FA,$FB,$FB,$FB,$FA,$FB,$FB,$FA,$FB,$FB,$FA,$FB,$FA,$FB,$FB,$FA,$FB
 dc.b $FB,$FA,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FA,$FB,$FB,$FB,$FB,$FB,$FA,$FB,$FA,$FB,$FA,$FA,$FA,$FB,$FA,$FB,$FA,$FB,$FB,$FB,$FC
 dc.b $FC,$FC,$FC,$FD,$FD,$FE,$FD,$FD,$FE,$FE,$FE,$FD,$FE,$FE,$FD,$FE,$FD,$FD,$FD,$FC,$FD,$FC,$FC,$FD,$FC,$FD,$FC,$FD,$FD,$FD,$FE,$FE
 dc.b $FE,$FE,$FF,$00,$FF,$00,$00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$00,$00,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$00,$00,$00,$FF
 dc.b $00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FE,$FE,$FE,$FD,$FE,$FD,$FD,$FC,$FD,$FC,$FC,$FB,$FC,$FC,$FC,$FB,$FC,$FC,$FC,$FC
 dc.b $FD,$FC,$FD,$FC,$FD,$FD,$FC,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FE,$FD,$FE,$FE,$FD,$FE,$FF,$FE,$FE,$FF,$FE,$FF,$FE,$FF,$FF,$FE,$FF,$FE
 dc.b $FF,$FE,$FF,$FE,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FF,$FE,$FE,$FF,$FE,$FE,$FE,$FD,$FE,$FE,$FD,$FE,$FD,$FE,$FD,$FD,$FD,$FD,$FD,$FE,$FD
 dc.b $FD,$FD,$FC,$FD,$FD,$FC,$FD,$FC,$FD,$FC,$FD,$FC,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FD,$FE,$FD,$FC
 dc.b $FC,$FC,$FC,$FB,$FC,$FB,$FA,$FB,$FB,$FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA,$F9,$F9,$F9,$F9,$F9,$F8,$F9,$F9,$F9,$F9,$F9,$F9,$FA,$FB
 dc.b $FA,$FB,$FC,$FC,$FB,$FD,$FC,$FD,$FC,$FD,$FD,$FD,$FE,$FD,$FD,$FD,$FE,$FD,$FD,$FD,$FE,$FD,$FE,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FF,$FF
 dc.b $FF,$FF,$00,$00,$00,$00,$01,$00,$01,$01,$01,$00,$01,$01,$00,$01,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$01
 dc.b $00,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$02,$01,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04,$03,$04,$04,$03,$04,$04,$03,$04,$03
 dc.b $04,$03,$03,$03,$03,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$03
 dc.b $04,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$03,$03,$03,$03,$03,$03,$03,$04,$03,$04,$04,$04,$04,$03,$03,$03,$03,$02,$02,$01
 dc.b $00,$00,$FF,$FF,$FE,$FE,$FE,$FD,$FD,$FD,$FD,$FC,$FD,$FD,$FC,$FD,$FC,$FD,$FD,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FB,$FC,$FC
 dc.b $FC,$FC,$FC,$FC,$FB,$FC,$FC,$FB,$FC,$FC,$FB,$FC,$FC,$FD,$FC,$FD,$FC,$FD,$FD,$FD,$FC,$FD,$FD,$FD,$FD,$FD,$FE,$FE,$FF,$FF,$00,$00
 dc.b $01,$02,$02,$03,$03,$04,$04,$05,$05,$05,$05,$06,$06,$06,$06,$05,$06,$06,$06,$05,$06,$06,$06,$06,$06,$07,$07,$08,$08,$08,$09,$0A
 dc.b $0A,$0C,$0C,$0E,$0E,$0F,$0F,$0F,$10,$10,$0F,$10,$0E,$0F,$0D,$0D,$0B,$0B,$0B,$0A,$0A,$0A,$09,$09,$08,$08,$08,$08,$07,$07,$06,$06
 dc.b $06,$06,$04,$05,$03,$04,$02,$03,$03,$02,$02,$03,$02,$03,$03,$03,$04,$04,$04,$04,$05,$04,$05,$04,$05,$04,$05,$04,$05,$04,$04,$04
 dc.b $04,$03,$04,$03,$03,$04,$03,$03,$03,$02,$03,$03,$03,$02,$03,$03,$03,$02,$03,$02,$03,$02,$03,$02,$02,$03,$02,$03,$02,$03,$02,$03
 dc.b $03,$03,$03,$02,$04,$03,$03,$03,$03,$03,$04,$03,$03,$04,$03,$03,$04,$03,$03,$03,$03,$03,$03,$04,$03,$03,$04,$04,$04,$04,$05,$06
 dc.b $06,$06,$07,$08,$08,$09,$09,$09,$09,$09,$09,$09,$09,$08,$08,$08,$07,$06,$06,$06,$06,$05,$05,$05,$05,$05,$05,$05,$04,$05,$05,$04
 dc.b $05,$05,$05,$04,$05,$04,$05,$04,$04,$05,$04,$05,$04,$05,$05,$05,$05,$06,$06,$06,$06,$06,$06,$07,$06,$06,$07,$06,$06,$06,$06,$06
 dc.b $05,$06,$05,$05,$04,$05,$04,$04,$05,$04,$05,$05,$05,$05,$05,$06,$07,$06,$07,$07,$08,$07,$08,$08,$08,$08,$09,$08,$09,$09,$09,$09
 dc.b $09,$09,$0B,$0B,$0B,$0C,$0C,$0C,$0B,$0C,$0B,$0A,$0A,$09,$08,$07,$06,$04,$04,$02,$02,$02,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
 dc.b $FF,$FF,$FF,$FF,$FF,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FD,$FD,$FD,$FD,$FD,$FC,$FD,$FB,$FC,$FC,$FB,$FB,$FB,$FB,$FB,$FA,$FB,$FA,$FB,$FA
 dc.b $FA,$FA,$FA,$FA,$F9,$F9,$FA,$F9,$F9,$F9,$F9,$F9,$F9,$F9,$FA,$F9,$FA,$FA,$FA,$FA,$FA,$FB,$FA,$FA,$FB,$FA,$FA,$FB,$FA,$FB,$FA,$FB
 dc.b $FA,$FB,$FA,$FB,$FB,$FB,$FB,$FB,$FA,$FB,$FB,$FB,$FA,$FB,$FA,$FA,$FA,$FA,$F9,$F9,$F9,$F9,$F9,$F9,$F9,$F8,$F9,$F9,$FA,$F9,$FA,$FB
 dc.b $FA,$FB,$FC,$FB,$FC,$FC,$FC,$FC,$FC,$FD,$FC,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FE,$FD,$FE,$FE,$FD,$FE,$FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE
 dc.b $FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FF,$FE,$FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FF,$FE,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FF,$FE,$FE,$FF,$FF
 dc.b $FF,$FF,$FF,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$00,$00,$00,$01
 dc.b $00,$01,$00,$01,$01,$01,$01,$01,$02,$01,$01,$02,$01,$02,$01,$02,$02,$01,$02,$02,$02,$02,$02,$02,$02,$03,$02,$03,$02,$03,$02,$03
 dc.b $03,$03,$03,$03,$03,$03,$04,$03,$03,$04,$04,$03,$04,$04,$04,$04,$05,$04,$05,$05,$05,$05,$05,$05,$06,$05,$06,$05,$05,$06,$05,$05
 dc.b $05,$05,$04,$05,$04,$05,$04,$04,$05,$04,$05,$04,$05,$05,$05,$05,$05,$05,$06,$06,$05,$06,$06,$06,$06,$06,$06,$07,$06,$06,$06,$05
 dc.b $06,$06,$06,$07,$06,$07,$06,$06,$07,$06,$05,$06,$05,$05,$04,$04,$03,$03,$02,$02,$02,$01,$01,$01,$00,$00,$00,$00,$00,$00,$FF,$00
 dc.b $00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FE,$FE,$FE,$FD,$FE,$FD,$FE,$FD,$FC,$FD,$FC,$FD,$FC,$FC,$FC,$FC,$FD,$FC,$FC,$FC
 dc.b $FD,$FC,$FC,$FC,$FD,$FC,$FC,$FC,$FC,$FC,$FD,$FC,$FC,$FC,$FC,$FC,$FC,$FD,$FC,$FC,$FC,$FC,$FC,$FC,$FD,$FC,$FC,$FC,$FC,$FD,$FC,$FC
 dc.b $FD,$FC,$FC,$FD,$FC,$FD,$FD,$FC,$FD,$FD,$FC,$FD,$FC,$FD,$FD,$FC,$FD,$FC,$FC,$FD,$FC,$FC,$FC,$FD,$FC,$FC,$FD,$FC,$FC,$FD,$FC,$FD
 dc.b $FD,$FC,$FD,$FD,$FD,$FC,$FD,$FD,$FD,$FD,$FD,$FD,$FE,$FD,$FE,$FD,$FE,$FE,$FE,$FE,$FF,$FE,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
 dc.b $FF,$FE,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FF,$FE,$FE,$FF,$FE,$FF,$FE
 dc.b $FE,$FF,$FE,$FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FD,$FE,$FD,$FE,$FD,$FD,$FC,$FD,$FC,$FD,$FC,$FC,$FC,$FD,$FC,$FD,$FC,$FD,$FD
 dc.b $FE,$FD,$FE,$FE,$FE,$FF,$FE,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FD,$FE,$FE,$FE,$FD,$FE,$FD,$FE,$FD,$FE,$FD,$FD
 dc.b $FE,$FD,$FD,$FC,$FD,$FC,$FD,$FC,$FD,$FC,$FD,$FD,$FD,$FD,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$01,$00,$00,$01,$00
 dc.b $00,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$02,$01,$01,$02,$01,$02,$01,$02,$02,$02,$01,$02,$02,$02,$02,$02
 dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$03,$02,$02,$03,$02,$03,$03,$02,$03,$03,$03,$03,$04,$03,$03,$04,$03,$04,$03,$04,$03,$04,$03
 dc.b $04,$03,$04,$04,$04,$04,$05,$04,$04,$04,$03,$04,$03,$04,$02,$03,$02,$02,$02,$01,$01,$02,$00,$01,$01,$00,$00,$00,$00,$00,$FF,$FF
 dc.b $00,$FE,$FF,$FE,$FE,$FD,$FE,$FD,$FD,$FE,$FD,$FD,$FD,$FD,$FE,$FD,$FE,$FE,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FD,$FE,$FE,$FD,$FE,$FD,$FD
 dc.b $FD,$FE,$FD,$FC,$FD,$FD,$FD,$FD,$FC,$FD,$FC,$FC,$FC,$FC,$FB,$FB,$FB,$FB,$FB,$FA,$FA,$FA,$F9,$FA,$F9,$FA,$F9,$F9,$FA,$F9,$F9,$FA
 dc.b $FA,$F9,$FA,$F9,$FA,$F9,$F9,$FA,$F9,$F9,$FA,$FA,$F9,$FA,$FA,$FB,$FA,$FB,$FA,$FB,$FA,$FB,$FB,$FB,$FB,$FC,$FB,$FC,$FC,$FC,$FD,$FC
 dc.b $FE,$FD,$FE,$FE,$FF,$FE,$FF,$FF,$00,$FF,$FF,$00,$FF,$FF,$00,$FF,$FE,$FF,$FF,$FE,$FF,$FE,$FF,$FF,$FE,$FF,$FE,$FF,$FF,$FF,$FF,$FF
 dc.b $00,$FF,$00,$00,$01,$00,$01,$00,$01,$00,$00,$00,$00,$00,$FF,$FF,$FE,$FE,$FF,$FE,$FD,$FE,$FD,$FE,$FD,$FD,$FC,$FD,$FC,$FB,$FC,$FB
 dc.b $FB,$FA,$FA,$F9,$F9,$F9,$F8,$F8,$F8,$F8,$F8,$F9,$F8,$FA,$F9,$FA,$FB,$FB,$FC,$FC,$FC,$FC,$FD,$FD,$FC,$FD,$FE,$FD,$FD,$FD,$FD,$FD
 dc.b $FD,$FD,$FD,$FD,$FD,$FC,$FD,$FD,$FD,$FE,$FD,$FE,$FD,$FF,$FE,$FE,$FF,$00,$FF,$FF,$00,$00,$00,$00,$01,$00,$01,$01,$02,$01,$02,$02
 dc.b $02,$03,$03,$04,$04,$04,$04,$04,$05,$05,$04,$05,$05,$04,$04,$04,$04,$04,$03,$04,$03,$04,$03,$03,$04,$03,$03,$04,$04,$03,$04,$04
 dc.b $04,$05,$05,$05,$05,$05,$05,$05,$05,$05,$06,$05,$05,$04,$05,$04,$04,$04,$04,$03,$03,$03,$03,$03,$03,$03,$02,$04,$03,$03,$04,$04
 dc.b $05,$04,$05,$06,$05,$06,$06,$06,$05,$06,$06,$06,$06,$05,$05,$05,$05,$04,$05,$04,$04,$04,$04,$04,$03,$04,$04,$03,$04,$03,$03,$04
 dc.b $03,$03,$03,$03,$02,$03,$03,$02,$03,$02,$03,$02,$03,$02,$03,$03,$03,$03,$03,$03,$03,$04,$03,$03,$03,$04,$03,$03,$03,$03,$03,$03
 dc.b $03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$02,$02,$02,$02,$02,$01,$02,$01,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$00,$01
 dc.b $00,$01,$00,$01,$00,$00,$01,$00,$00,$00,$00,$00,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FE,$FF,$FD,$FE,$FD,$FC,$FD
 dc.b $FB,$FB,$FB,$FA,$F9,$F9,$F9,$F9,$F8,$F9,$F9,$F8,$F9,$F9,$F9,$FA,$FA,$FB,$FA,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FC,$FB,$FB,$FC
 dc.b $FB,$FC,$FB,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FB,$FB,$FB,$FA,$FA,$FA,$F9,$F9,$F9,$F8,$F8,$F8,$F8,$F8,$F8,$F8,$F9,$F8,$F8,$F9
 dc.b $F8,$F9,$F9,$F8,$F9,$F8,$F9,$F9,$F8,$F9,$F9,$F9,$FA,$F9,$F9,$FA,$FA,$FA,$FA,$FA,$FB,$FA,$FB,$FA,$FB,$FB,$FB,$FB,$FC,$FB,$FC,$FB
 dc.b $FC,$FD,$FC,$FD,$FD,$FD,$FD,$FE,$FD,$FD,$FD,$FE,$FD,$FC,$FD,$FC,$FC,$FC,$FC,$FB,$FB,$FB,$FC,$FB,$FA,$FB,$FB,$FB,$FB,$FB,$FB,$FC
 dc.b $FB,$FB,$FB,$FB,$FB,$FC,$FB,$FB,$FB,$FC,$FB,$FC,$FC,$FC,$FC,$FD,$FD,$FD,$FE,$FD,$FE,$FE,$FE,$FE,$FF,$FE,$FF,$FF,$FF,$FF,$00,$FF
 dc.b $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$00,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01
 dc.b $00,$01,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00
 dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$01,$02
 dc.b $01,$02,$02,$01,$02,$02,$02,$02,$03,$02,$02,$03,$02,$02,$03,$02,$03,$02,$03,$03,$03,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
 dc.b $03,$03,$03,$02,$03,$03,$03,$02,$03,$03,$03,$03,$03,$03,$04,$03,$04,$03,$04,$04,$04,$04,$04,$04,$04,$04,$04,$05,$04,$05,$04,$05
 dc.b $04,$05,$05,$06,$05,$05,$06,$05,$06,$05,$06,$05,$05,$05,$05,$05,$04,$04,$04,$04,$03,$04,$03,$03,$03,$04,$03,$04,$04,$05,$04,$06
 dc.b $05,$06,$07,$07,$08,$08,$07,$08,$08,$08,$08,$08,$07,$08,$06,$06,$06,$06,$05,$05,$04,$05,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
 dc.b $04,$04,$04,$04,$04,$05,$04,$04,$03,$04,$04,$04,$03,$04,$03,$03,$03,$03,$03,$03,$02,$03,$02,$03,$02,$02,$02,$02,$02,$02,$02,$02
 dc.b $01,$02,$02,$02,$02,$02,$02,$02,$01,$02,$01,$01,$00,$01,$00,$FF,$FF,$FF,$FE,$FE,$FE,$FD,$FD,$FD,$FC,$FD,$FD,$FC,$FD,$FD,$FD,$FD
 dc.b $FD,$FD,$FE,$FD,$FE,$FD,$FE,$FD,$FE,$FD,$FD,$FE,$FD,$FD,$FD,$FD,$FC,$FD,$FD,$FC,$FC,$FD,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FB,$FC
 dc.b $FC,$FB,$FC,$FC,$FB,$FC,$FB,$FC,$FB,$FB,$FB,$FB,$FB,$FB,$FA,$FA,$FA,$FA,$F9,$F9,$F9,$F9,$F8,$F9,$F8,$F8,$F9,$F9,$F8,$F9,$FA,$F9
 dc.b $FA,$FA,$FB,$FA,$FB,$FA,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FC,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
 dc.b $FB,$FA,$FA,$FA,$FA,$FA,$FA,$F9,$FA,$FA,$FB,$FA,$FB,$FB,$FC,$FD,$FD,$FD,$FE,$FE,$FF,$FE,$00,$FF,$FF,$00,$00,$00,$FF,$00,$00,$FF
 dc.b $00,$FF,$FF,$00,$00,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$01,$01,$00,$01
 dc.b $00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$02,$01,$02,$01,$02,$02,$02,$01,$02,$02,$02,$02,$02,$03
 dc.b $02,$02,$02,$03,$02,$03,$03,$02,$03,$03,$02,$03,$03,$03,$03,$03,$02,$03,$03,$03,$03,$02,$03,$03,$03,$03,$04,$03,$03,$04,$03,$04
 dc.b $04,$04,$05,$04,$05,$04,$05,$05,$04,$05,$05,$06,$05,$05,$06,$05,$06,$05,$06,$06,$07,$06,$06,$06,$07,$06,$07,$06,$07,$06,$07,$06
 dc.b $06,$07,$06,$07,$07,$07,$06,$07,$07,$06,$06,$07,$06,$05,$06,$05,$05,$05,$05,$05,$04,$04,$04,$04,$04,$04,$03,$03,$03,$03,$03,$02
 dc.b $02,$02,$01,$02,$01,$01,$01,$01,$00,$00,$00,$00,$FF,$FE,$FF,$FD,$FE,$FC,$FD,$FB,$FC,$FB,$FB,$FA,$FA,$FA,$FA,$FA,$F9,$FA,$FA,$FA
 dc.b $FA,$F9,$F9,$F9,$F9,$F9,$F9,$F8,$F9,$F9,$F8,$F9,$FA,$F9,$FA,$FA,$FA,$FB,$FB,$FB,$FC,$FB,$FC,$FC,$FC,$FC,$FB,$FC,$FC,$FC,$FB,$FC
 dc.b $FB,$FB,$FA,$FB,$FA,$FB,$FA,$FA,$FB,$FA,$FB,$FB,$FB,$FC,$FB,$FC,$FD,$FC,$FD,$FD,$FE,$FD,$FE,$FD,$FE,$FE,$FE,$FF,$FE,$FF,$FE,$FF
 dc.b $FF,$FF,$FF,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$01,$01,$00,$02,$01,$01,$01,$02,$02,$01,$02,$02,$02,$03,$02,$03
 dc.b $02,$03,$04,$03,$04,$04,$03,$04,$04,$04,$04,$04,$04,$04,$04,$04,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$04,$04,$05
 dc.b $04,$05,$05,$05,$05,$06,$05,$06,$06,$06,$06,$07,$06,$07,$07,$07,$08,$07,$08,$08,$08,$08,$08,$09,$08,$09,$0A,$09,$0A,$0A,$0A,$0B
 dc.b $0B,$0C,$0B,$0D,$0C,$0D,$0D,$0D,$0E,$0D,$0E,$0D,$0E,$0D,$0E,$0D,$0D,$0E,$0D,$0E,$0E,$0E,$0E,$0E,$0D,$0E,$0D,$0D,$0D,$0C,$0C,$0B
 dc.b $0B,$0A,$0B,$0A,$09,$0A,$09,$08,$09,$08,$08,$08,$07,$07,$07,$07,$06,$05,$05,$05,$04,$04,$04,$03,$03,$04,$03,$04,$04,$04,$04,$05
 dc.b $05,$05,$05,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$05,$06,$07,$06,$06,$06,$06,$07,$06,$05,$06,$05,$06,$04,$05,$04
 dc.b $03,$03,$03,$02,$02,$01,$01,$02,$01,$01,$01,$02,$01,$02,$02,$03,$03,$03,$04,$04,$04,$05,$04,$05,$04,$05,$04,$04,$04,$03,$03,$03
 dc.b $02,$02,$02,$02,$02,$01,$02,$01,$01,$00,$00,$00,$00,$FF,$FF,$FF,$FE,$FE,$FD,$FD,$FD,$FC,$FC,$FC,$FB,$FC,$FB,$FB,$FB,$FC,$FB,$FB
 dc.b $FB,$FB,$FB,$FB,$FA,$FA,$FA,$FA,$FB,$FA,$FB,$FA,$FC,$FB,$FC,$FC,$FD,$FD,$FD,$FE,$FE,$FF,$FE,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FE
 dc.b $FE,$FF,$FE,$FE,$FF,$FE,$FE,$FF,$FE,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$FF,$00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$01,$01
 dc.b $01,$00,$01,$01,$00,$01,$00,$01,$01,$02,$01,$02,$03,$03,$03,$04,$05,$05,$06,$07,$08,$07,$08,$08,$09,$08,$07,$08,$07,$06,$05,$05
 dc.b $04,$03,$03,$02,$02,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$02,$01,$01,$02,$01,$02,$01,$01,$01,$02,$01,$01,$01,$00,$01

;NumPoints(0) = 205
;points(0,0)\x = 163
;points(0,0)\y = 100
;points(0,1)\x = 160
;points(0,1)\y = 188
;points(0,2)\x = 179
;points(0,2)\y = 254
;points(0,3)\x = 206
;points(0,3)\y = 334
;points(0,4)\x = 244
;points(0,4)\y = 422
;points(0,5)\x = 342
;points(0,5)\y = 459
;points(0,6)\x = 492
;points(0,6)\y = 526
;points(0,7)\x = 537
;points(0,7)\y = 731
;points(0,8)\x = 579
;points(0,8)\y = 929
;points(0,9)\x = 652
;points(0,9)\y = 1094
;points(0,10)\x = 766
;points(0,10)\y = 1183
;points(0,11)\x = 824
;points(0,11)\y = 1107
;points(0,12)\x = 826
;points(0,12)\y = 1022
;points(0,13)\x = 854
;points(0,13)\y = 940
;points(0,14)\x = 811
;points(0,14)\y = 855
;points(0,15)\x = 788
;points(0,15)\y = 812
;points(0,16)\x = 836
;points(0,16)\y = 762
;points(0,17)\x = 932
;points(0,17)\y = 761
;points(0,18)\x = 1009
;points(0,18)\y = 764
;points(0,19)\x = 1089
;points(0,19)\y = 741
;points(0,20)\x = 1148
;points(0,20)\y = 679
;points(0,21)\x = 1116
;points(0,21)\y = 630
;points(0,22)\x = 1041
;points(0,22)\y = 604
;points(0,23)\x = 941
;points(0,23)\y = 580
;points(0,24)\x = 831
;points(0,24)\y = 538
;points(0,25)\x = 756
;points(0,25)\y = 485
;points(0,26)\x = 678
;points(0,26)\y = 446
;points(0,27)\x = 583
;points(0,27)\y = 360
;points(0,28)\x = 668
;points(0,28)\y = 252
;points(0,29)\x = 930
;points(0,29)\y = 197
;points(0,30)\x = 1163
;points(0,30)\y = 163
;points(0,31)\x = 1455
;points(0,31)\y = 169
;points(0,32)\x = 1542
;points(0,32)\y = 168
;points(0,33)\x = 1676
;points(0,33)\y = 188
;points(0,34)\x = 1676
;points(0,34)\y = 242
;points(0,35)\x = 1676
;points(0,35)\y = 290
;points(0,36)\x = 1639
;points(0,36)\y = 352
;points(0,37)\x = 1601
;points(0,37)\y = 399
;points(0,38)\x = 1551
;points(0,38)\y = 446
;points(0,39)\x = 1513
;points(0,39)\y = 406
;points(0,40)\x = 1484
;points(0,40)\y = 343
;points(0,41)\x = 1462
;points(0,41)\y = 278
;points(0,42)\x = 1535
;points(0,42)\y = 244
;points(0,43)\x = 1597
;points(0,43)\y = 316
;points(0,44)\x = 1601
;points(0,44)\y = 429
;points(0,45)\x = 1580
;points(0,45)\y = 655
;points(0,46)\x = 1548
;points(0,46)\y = 790
;points(0,47)\x = 1526
;points(0,47)\y = 842
;points(0,48)\x = 1483
;points(0,48)\y = 911
;points(0,49)\x = 1437
;points(0,49)\y = 959
;points(0,50)\x = 1405
;points(0,50)\y = 999
;points(0,51)\x = 1360
;points(0,51)\y = 1050
;points(0,52)\x = 1296
;points(0,52)\y = 1110
;points(0,53)\x = 1137
;points(0,53)\y = 1242
;points(0,54)\x = 1073
;points(0,54)\y = 1325
;points(0,55)\x = 1064
;points(0,55)\y = 1399
;points(0,56)\x = 1074
;points(0,56)\y = 1496
;points(0,57)\x = 1079
;points(0,57)\y = 1575
;points(0,58)\x = 1080
;points(0,58)\y = 1703
;points(0,59)\x = 1073
;points(0,59)\y = 1866
;points(0,60)\x = 1108
;points(0,60)\y = 1874
;points(0,61)\x = 1153
;points(0,61)\y = 1843
;points(0,62)\x = 1212
;points(0,62)\y = 1765
;points(0,63)\x = 1258
;points(0,63)\y = 1659
;points(0,64)\x = 1273
;points(0,64)\y = 1568
;points(0,65)\x = 1274
;points(0,65)\y = 1482
;points(0,66)\x = 1282
;points(0,66)\y = 1375
;points(0,67)\x = 1331
;points(0,67)\y = 1315
;points(0,68)\x = 1416
;points(0,68)\y = 1281
;points(0,69)\x = 1528
;points(0,69)\y = 1252
;points(0,70)\x = 1652
;points(0,70)\y = 1223
;points(0,71)\x = 1732
;points(0,71)\y = 1218
;points(0,72)\x = 1777
;points(0,72)\y = 1215
;points(0,73)\x = 1908
;points(0,73)\y = 1234
;points(0,74)\x = 1985
;points(0,74)\y = 1270
;points(0,75)\x = 2035
;points(0,75)\y = 1326
;points(0,76)\x = 2070
;points(0,76)\y = 1408
;points(0,77)\x = 2074
;points(0,77)\y = 1482
;points(0,78)\x = 2093
;points(0,78)\y = 1576
;points(0,79)\x = 2137
;points(0,79)\y = 1666
;points(0,80)\x = 2190
;points(0,80)\y = 1678
;points(0,81)\x = 2250
;points(0,81)\y = 1657
;points(0,82)\x = 2293
;points(0,82)\y = 1601
;points(0,83)\x = 2317
;points(0,83)\y = 1540
;points(0,84)\x = 2355
;points(0,84)\y = 1479
;points(0,85)\x = 2319
;points(0,85)\y = 1424
;points(0,86)\x = 2316
;points(0,86)\y = 1366
;points(0,87)\x = 2308
;points(0,87)\y = 1319
;points(0,88)\x = 2244
;points(0,88)\y = 1297
;points(0,89)\x = 2168
;points(0,89)\y = 1283
;points(0,90)\x = 2125
;points(0,90)\y = 1260
;points(0,91)\x = 2096
;points(0,91)\y = 1228
;points(0,92)\x = 2054
;points(0,92)\y = 1174
;points(0,93)\x = 1999
;points(0,93)\y = 1145
;points(0,94)\x = 1909
;points(0,94)\y = 1107
;points(0,95)\x = 1920
;points(0,95)\y = 1058
;points(0,96)\x = 2023
;points(0,96)\y = 1055
;points(0,97)\x = 2114
;points(0,97)\y = 1066
;points(0,98)\x = 2195
;points(0,98)\y = 1093
;points(0,99)\x = 2249
;points(0,99)\y = 1129
;points(0,100)\x = 2287
;points(0,100)\y = 1182
;points(0,101)\x = 2337
;points(0,101)\y = 1240
;points(0,102)\x = 2427
;points(0,102)\y = 1249
;points(0,103)\x = 2476
;points(0,103)\y = 1211
;points(0,104)\x = 2483
;points(0,104)\y = 1174
;points(0,105)\x = 2471
;points(0,105)\y = 1116
;points(0,106)\x = 2435
;points(0,106)\y = 1016
;points(0,107)\x = 2399
;points(0,107)\y = 914
;points(0,108)\x = 2307
;points(0,108)\y = 840
;points(0,109)\x = 2215
;points(0,109)\y = 821
;points(0,110)\x = 2128
;points(0,110)\y = 801
;points(0,111)\x = 2021
;points(0,111)\y = 800
;points(0,112)\x = 1996
;points(0,112)\y = 751
;points(0,113)\x = 2019
;points(0,113)\y = 639
;points(0,114)\x = 2062
;points(0,114)\y = 584
;points(0,115)\x = 2111
;points(0,115)\y = 542
;points(0,116)\x = 2186
;points(0,116)\y = 550
;points(0,117)\x = 2246
;points(0,117)\y = 615
;points(0,118)\x = 2279
;points(0,118)\y = 672
;points(0,119)\x = 2344
;points(0,119)\y = 750
;points(0,120)\x = 2398
;points(0,120)\y = 803
;points(0,121)\x = 2458
;points(0,121)\y = 890
;points(0,122)\x = 2514
;points(0,122)\y = 951
;points(0,123)\x = 2619
;points(0,123)\y = 994
;points(0,124)\x = 2720
;points(0,124)\y = 1044
;points(0,125)\x = 2834
;points(0,125)\y = 1080
;points(0,126)\x = 2955
;points(0,126)\y = 1095
;points(0,127)\x = 3101
;points(0,127)\y = 1095
;points(0,128)\x = 3206
;points(0,128)\y = 1066
;points(0,129)\x = 3290
;points(0,129)\y = 960
;points(0,130)\x = 3332
;points(0,130)\y = 880
;points(0,131)\x = 3367
;points(0,131)\y = 809
;points(0,132)\x = 3382
;points(0,132)\y = 689
;points(0,133)\x = 3408
;points(0,133)\y = 576
;points(0,134)\x = 3458
;points(0,134)\y = 493
;points(0,135)\x = 3523
;points(0,135)\y = 443
;points(0,136)\x = 3609
;points(0,136)\y = 366
;points(0,137)\x = 3629
;points(0,137)\y = 295
;points(0,138)\x = 3587
;points(0,138)\y = 269
;points(0,139)\x = 3489
;points(0,139)\y = 280
;points(0,140)\x = 3354
;points(0,140)\y = 292
;points(0,141)\x = 3208
;points(0,141)\y = 300
;points(0,142)\x = 3094
;points(0,142)\y = 299
;points(0,143)\x = 2976
;points(0,143)\y = 301
;points(0,144)\x = 2865
;points(0,144)\y = 317
;points(0,145)\x = 2780
;points(0,145)\y = 351
;points(0,146)\x = 2676
;points(0,146)\y = 397
;points(0,147)\x = 2590
;points(0,147)\y = 444
;points(0,148)\x = 2540
;points(0,148)\y = 510
;points(0,149)\x = 2528
;points(0,149)\y = 593
;points(0,150)\x = 2548
;points(0,150)\y = 655
;points(0,151)\x = 2595
;points(0,151)\y = 771
;points(0,152)\x = 2656
;points(0,152)\y = 841
;points(0,153)\x = 2743
;points(0,153)\y = 902
;points(0,154)\x = 2831
;points(0,154)\y = 939
;points(0,155)\x = 2977
;points(0,155)\y = 959
;points(0,156)\x = 3091
;points(0,156)\y = 915
;points(0,157)\x = 3156
;points(0,157)\y = 872
;points(0,158)\x = 3214
;points(0,158)\y = 810
;points(0,159)\x = 3239
;points(0,159)\y = 733
;points(0,160)\x = 3290
;points(0,160)\y = 620
;points(0,161)\x = 3334
;points(0,161)\y = 536
;points(0,162)\x = 3393
;points(0,162)\y = 457
;points(0,163)\x = 3455
;points(0,163)\y = 369
;points(0,164)\x = 3434
;points(0,164)\y = 353
;points(0,165)\x = 3390
;points(0,165)\y = 349
;points(0,166)\x = 3273
;points(0,166)\y = 358
;points(0,167)\x = 3115
;points(0,167)\y = 369
;points(0,168)\x = 2947
;points(0,168)\y = 397
;points(0,169)\x = 2827
;points(0,169)\y = 439
;points(0,170)\x = 2738
;points(0,170)\y = 489
;points(0,171)\x = 2709
;points(0,171)\y = 566
;points(0,172)\x = 2732
;points(0,172)\y = 666
;points(0,173)\x = 2799
;points(0,173)\y = 767
;points(0,174)\x = 2879
;points(0,174)\y = 827
;points(0,175)\x = 3008
;points(0,175)\y = 831
;points(0,176)\x = 3104
;points(0,176)\y = 747
;points(0,177)\x = 3169
;points(0,177)\y = 637
;points(0,178)\x = 3211
;points(0,178)\y = 565
;points(0,179)\x = 3240
;points(0,179)\y = 483
;points(0,180)\x = 3225
;points(0,180)\y = 447
;points(0,181)\x = 3121
;points(0,181)\y = 444
;points(0,182)\x = 2988
;points(0,182)\y = 470
;points(0,183)\x = 2939
;points(0,183)\y = 529
;points(0,184)\x = 2969
;points(0,184)\y = 582
;points(0,185)\x = 3001
;points(0,185)\y = 676
;points(0,186)\x = 3092
;points(0,186)\y = 817
;points(0,187)\x = 3223
;points(0,187)\y = 1023
;points(0,188)\x = 3371
;points(0,188)\y = 1234
;points(0,189)\x = 3414
;points(0,189)\y = 1372
;points(0,190)\x = 3395
;points(0,190)\y = 1439
;points(0,191)\x = 3377
;points(0,191)\y = 1532
;points(0,192)\x = 3389
;points(0,192)\y = 1622
;points(0,193)\x = 3462
;points(0,193)\y = 1652
;points(0,194)\x = 3562
;points(0,194)\y = 1714
;points(0,195)\x = 3638
;points(0,195)\y = 1726
;points(0,196)\x = 3713
;points(0,196)\y = 1663
;points(0,197)\x = 3670
;points(0,197)\y = 1580
;points(0,198)\x = 3629
;points(0,198)\y = 1553
;points(0,199)\x = 3513
;points(0,199)\y = 1530
;points(0,200)\x = 3333
;points(0,200)\y = 1533
;points(0,201)\x = 3153
;points(0,201)\y = 1557
;points(0,202)\x = 2916
;points(0,202)\y = 1666
;points(0,203)\x = 2795
;points(0,203)\y = 1689
;points(0,204)\x = 2746
;points(0,204)\y = 1708

			echo "Data end before gfx @$9800: ", *

;------------------------------------------------------------------------------
;gfxdata
;------------------------------------------------------------------------------
			org pattern1	;$9800
prow00			incbin "gfx/pattern1.chr",parsizey*0,parsizey	;double include smaller than copying
			incbin "gfx/pattern1.chr",parsizey*0,parsizey	
prow10			incbin "gfx/pattern1.chr",parsizey*1,parsizey
			incbin "gfx/pattern1.chr",parsizey*1,parsizey
prow20			incbin "gfx/pattern1.chr",parsizey*2,parsizey
			incbin "gfx/pattern1.chr",parsizey*2,parsizey
prow30			incbin "gfx/pattern1.chr",parsizey*3,parsizey
			incbin "gfx/pattern1.chr",parsizey*3,parsizey
;----------------------
			org prow00+parsizey*8
prow01
			org prow00+parsizey*10
prow11
			org prow00+parsizey*12
prow21
			org prow00+parsizey*14
prow31
 			org prow00+parsizey*64
;----------------------
			org pattern2	;$a000
			incbin "gfx/pattern2.chr",parsizey*0,parsizey	;double include smaller than copying
			incbin "gfx/pattern2.chr",parsizey*0,parsizey	
			incbin "gfx/pattern2.chr",parsizey*1,parsizey
			incbin "gfx/pattern2.chr",parsizey*1,parsizey
			incbin "gfx/pattern2.chr",parsizey*2,parsizey
			incbin "gfx/pattern2.chr",parsizey*2,parsizey
			incbin "gfx/pattern2.chr",parsizey*3,parsizey
			incbin "gfx/pattern2.chr",parsizey*3,parsizey

;----------------------
			org pattern3	;$a800
			incbin "gfx/pattern3.chr",parsizey*0,parsizey	;double include smaller than copying
			incbin "gfx/pattern3.chr",parsizey*0,parsizey	
			incbin "gfx/pattern3.chr",parsizey*1,parsizey
			incbin "gfx/pattern3.chr",parsizey*1,parsizey
			incbin "gfx/pattern3.chr",parsizey*2,parsizey
			incbin "gfx/pattern3.chr",parsizey*2,parsizey
			incbin "gfx/pattern3.chr",parsizey*3,parsizey
			incbin "gfx/pattern3.chr",parsizey*3,parsizey
		
;----------------------
			org pattern4	;$b000
			incbin "gfx/pattern4.chr",parsizey*0,parsizey	;double include smaller than copying
			incbin "gfx/pattern4.chr",parsizey*0,parsizey	
			incbin "gfx/pattern4.chr",parsizey*1,parsizey
			incbin "gfx/pattern4.chr",parsizey*1,parsizey
			incbin "gfx/pattern4.chr",parsizey*2,parsizey
			incbin "gfx/pattern4.chr",parsizey*2,parsizey
			incbin "gfx/pattern4.chr",parsizey*3,parsizey
			incbin "gfx/pattern4.chr",parsizey*3,parsizey
			
;----------------------
			org pattern5	;$b800
			incbin "gfx/pattern5.chr",parsizey*0,parsizey	;double include smaller than copying
			incbin "gfx/pattern5.chr",parsizey*0,parsizey	
			incbin "gfx/pattern5.chr",parsizey*1,parsizey
			incbin "gfx/pattern5.chr",parsizey*1,parsizey
			incbin "gfx/pattern5.chr",parsizey*2,parsizey
			incbin "gfx/pattern5.chr",parsizey*2,parsizey
			incbin "gfx/pattern5.chr",parsizey*3,parsizey
			incbin "gfx/pattern5.chr",parsizey*3,parsizey

			org screen
initnmi			subroutine
			lda #$40			;opcode rti
			sta $dc0c			;ack irq/nmi faster
			sta $dd0c

			ifconst release
			lda link_chip_types
			and #%00000010
			lsr
			sta ciatype+1
			lda #%01111111			;clear irq masks
			sta $dc0d
			sta $dd0d

			lda #$00
			sta $dc0e			;stop timers
			sta $dc0f
			sta $dd0e
			sta $dd0f

			bit $dc0d			;ack pending irqs
			bit $dd0d

			sta $dc05			;reset timer high-bytes
			sta $dc07
			sta $dd05
			sta $dd07

			else
			
			lda #%01111111			;clear irq masks
			sta $dc0d
			sta $dd0d
			lda #$00
			sta $d01a

			sta $dc0e			;stop timers
			sta $dc0f
			sta $dd0e
			sta $dd0f

			bit $dc0d			;ack pending irqs
			bit $dd0d
			inc $d019

			sta $dc05			;reset timer high-bytes
			sta $dc07
			sta $dd05
			sta $dd07

			lda #<.ciadetect
			sta $fffe
			lda #>.ciadetect
			sta $ffff

			lda #$02			;fire one shot irq
			sta $dc04
			lda #%10000001
			sta $dc0d
			lda #%00011001
			sta $dc0e
			cli

			nop
			lda #$01			;new cia
			lda #$00			;old cia

			lda #%01111111			;stop cia1 a 
			sta $dc0d
			endif
			
			;install nmi routines
			ldy #$00
.copy2			ldx #$00
.copy			lda .nmi0,y
.dest			sta nmidest,x
			iny
			inx
.check			cpx .nmilen
			bne .copy
			inc .check+1
			inc .dest+2
			cpy #.nmi6-.nmi0
			bne .copy2

			lda #<mainnmi			;set nmi vector
			sta $fffa
			lda #>mainnmi
			sta $fffb

			lda #%10000011			;enable irq cia2 a & b
			sta $dd0d
			rts
			
			ifnconst release
.ciadetect		sta ciatype+1
			jmp $dc0c
			endif

;------------------------------------------------------------------------------
;nmi entry routines
;------------------------------------------------------------------------------
.nmi0			nop				;$200 set charset 0, reset $d011
			lsr $d018
			inc $d011
			jmp $dd0c

.nmi1			inc $d011			;$300 set charset 0, reset $d011
			lsr $d018
			jmp $dd0c

			
.nmi2			dec $d011			;$400 line double
			jmp $dd0c

.nmi3			bit $dd0d			;$500 line double
			dec $d011
			rti
			
.nmi4			nop				;$600 set charset 1
			asl $d018
			jmp $dd0c

.nmi5			bit $dd0d			;$700 set charset 1
			asl $d018
			rti
.nmi6

.nmilen			dc.b .nmi1-.nmi0
			dc.b .nmi2-.nmi1
			dc.b .nmi3-.nmi2
			dc.b .nmi4-.nmi3
			dc.b .nmi5-.nmi4
			dc.b .nmi6-.nmi5

;------------------------------------------------------------------------------
;initscreen
;------------------------------------------------------------------------------
initscreen		subroutine
			ldx #$00
			stx $d011
			stx $d015
			stx $d017
			stx $d01b
			stx $d01d
			stx $dd00
			dex
			stx $d01c
			
			lda #$06
			sta $d021
			sta $d020
			lda #$05
			sta $d022
			lda #$0d
			sta $d023

;			lda #$00				;x 0,0 bis 3775 ($ebf)
			; sta viewportxlo			;y 0,0 bis 1847 ($737)
			; sta viewportxhi
			; sta viewportyhi
			; sta viewportylo

			lda #<spe_xstart0
			sta viewportxlo
			lda #>spe_xstart0
			sta viewportxhi
			lda #<spe_ystart0
			sta viewportylo
			lda #>spe_ystart0
			sta viewportyhi
		
			lda #$5c
			sta spritemapy
			sta fadeflag
			lda #$00
			sta spritemapx
			sta fadepos
			
			ldx #$09
.loop2			lda #$06
			sta $d025,x
			dex
			bpl .loop2
			rts
			
			org $c400
colorblock4
 hex 040C0C0C040C0C0C 000000000C0C0C00 000C0400040C0C04 0C08000004040C04 040C0C00000C040C 000C040C040C0C08 080808000C040C04 040C0C040C0C0404
 hex 000F000C04040C04 0C08050808000800 08000404000C000C 0008080808080C04 0C00000C0408080C 0C0C0C0408000804 04040C040C0C0400 0C040C0C08000800
 hex 04000C0C0C000C04 0C000C0400040004 0404040004000800 08080C0C04040404 0C0408080008000C 0C0C0404040C0000 040C0C0404000C0C 00000C0404040C0C
 hex 04040C040C000000 000C040404080C04 000C0C040C040C0C 04040C04040C0C04 04040C04040C0408 00040800040C0C0C 040C040F0C0C0C0C 0C0C0C040C000C00

colorblock5
 hex 040C0C0C040C0C0C 000000000C040C00 040C04000C0C0404 0C0808000C040C04 0C0C0C00040C0404 00040C040C0C0C08 080808000C040C04 0C0C0C040C040C04
 hex 0F0F08040404040C 0C08080808080808 0804040C00040F0C 0808080808080404 0C00000C0408080C 040C0C040800080C 0C0404040C0C0C00 0C000C0408080804
 hex 0404040404000C04 04000C0C000C0804 040C000004000800 0808040C04040C04 0C0408080000000C 0C0C0C0C040C0000 0C0C0C0404080C04 04040C040C0C0C0C
 hex 0C0C0C040C000000 0F0C0C0C04080C0C 080C0C040C040C0C 04040C04000C0404 0404040C040C0408 000408040404040C 040C0C0F0C0C040C 0404040C0F040C00

colorblock6
 hex 040C0C0C040C0C0C 000000040C040C00 0C040C000C0C0404 040808000C0C0404 0C0C0C000C0C0400 04000C040C040408 0808080404040C04 0C0C0C0C0C000C04
 hex 0F000004040C000C 0C08080808080808 080C04040000000C 0808080808080C04 040000040C08080C 0004040C0800000C 040400040C040404 0C000C000808090C
 hex 0404000400000C04 0004040C040C080C 0C0C000404000808 0800040404040C04 0C0408080800000C 0C0C0C0C040C0804 040C0C0404080404 0C0C0C0C0C040404
 hex 0C0C04040C000004 090C040C04080C04 0004040C040C0404 0C040C0C0004040C 040C0404040C0408 0004080C040C040C 04040C000C04040C 0400040C0F040C00

colorblock7
 hex 040C0C0C0C0C0C04 0000000C0C040C00 0C040C000C0C0404 000800000C0C0404 0C0404000C0C0400 0C000C040C000408 0808080C04040C04 0C0C0C0C0C000C04
 hex 09000004040C000C 0C08080808080000 080C04040400000C 0008080808080C04 000000040C080004 0000040409000004 040400040C00040C 0C000C000808000C
 hex 0C0C000400000C0C 000C00040C0C000C 040C000C0C000808 09000404040C040C 0C0408080800000C 040404040404000C 000C0C040C00000C 0C04040C0C000C04
 hex 0C0C04040C00000C 0F0404040C080C00 000C0404040C0C04 0C040C0C00040C0C 0C0C04040C0C0408 040C080C0C0C040C 0C040C0004040404 0404040C090C0C00

;----------------------
			org charset0	;c800
i			set 0			
			repeat 256
			incbin "gfx/greetz.chr",i*16,4
			incbin "gfx/greetz.chr",i*16+12,4
i			set i+1
			repend

;----------------------
			org pattern6	;$d000
			incbin "gfx/pattern6.chr",parsizey*0,parsizey	;double include smaller than copying
			incbin "gfx/pattern6.chr",parsizey*0,parsizey	
			incbin "gfx/pattern6.chr",parsizey*1,parsizey
			incbin "gfx/pattern6.chr",parsizey*1,parsizey
			incbin "gfx/pattern6.chr",parsizey*2,parsizey
			incbin "gfx/pattern6.chr",parsizey*2,parsizey
			incbin "gfx/pattern6.chr",parsizey*3,parsizey
			incbin "gfx/pattern6.chr",parsizey*3,parsizey

;----------------------
			org charset1	;$d800
i			set 0			
			repeat 256
			incbin "gfx/greetz.chr",i*16+8,4
			incbin "gfx/greetz.chr",i*16+4,4
i			set i+1
			repend

;----------------------
			org pattern7	;$e000
			incbin "gfx/pattern7.chr",parsizey*0,parsizey	;double include smaller than copying
			incbin "gfx/pattern7.chr",parsizey*0,parsizey	
			incbin "gfx/pattern7.chr",parsizey*1,parsizey
			incbin "gfx/pattern7.chr",parsizey*1,parsizey
			incbin "gfx/pattern7.chr",parsizey*2,parsizey
			incbin "gfx/pattern7.chr",parsizey*2,parsizey
			incbin "gfx/pattern7.chr",parsizey*3,parsizey
			incbin "gfx/pattern7.chr",parsizey*3,parsizey

;----------------------
			org pattern8	;$e800
			incbin "gfx/pattern8.chr",parsizey*0,parsizey	;double include smaller than copying
			incbin "gfx/pattern8.chr",parsizey*0,parsizey	
			incbin "gfx/pattern8.chr",parsizey*1,parsizey
			incbin "gfx/pattern8.chr",parsizey*1,parsizey
			incbin "gfx/pattern8.chr",parsizey*2,parsizey
			incbin "gfx/pattern8.chr",parsizey*2,parsizey
			incbin "gfx/pattern8.chr",parsizey*3,parsizey
			incbin "gfx/pattern8.chr",parsizey*3,parsizey

;----------------------
			org spritemap1	;$f000
			incbin "gfx/spritemap.spr",0,7*8*64
			
			; org spritemap2
			; incbin "gfx/spritemap.spr",0,7*8*64

;spritemap size 7 rows, 135 lines of gfx, last 2 lines have to be empty resulting in 133 lines usable
; 21	21
; 19	2
; 19	4
; 19	6
; 19	8
; 19	10
; 19	12
; 154	
emptysprite		ds.b 64
			
;------------------------------------------------------------------------------
;screen rows layout
;------------------------------------------------------------------------------
;y-scroll 0-15
;y0+            y8+ line doubling
;
;00 offset 00  l1  00 offset 00   l1
;00                01 offset 40   l2
;02 offset 80  l2  01
;02                03 offset 120  l1
;04 offset 160 l1  03
;04                05 offset 200  l2
;06 offset 240 l2  05
;06                07 offset 280  l1
;08                07
;08                09
;10                09
;10                11
;12                11
;12                13
;14                13
;14                15
;16                15
;16                17
;18                17
;18                19
;20                19
;20                21
;22                21
;22                23
;[24               23]


