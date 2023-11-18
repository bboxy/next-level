;to do
;if movement stays with combined x, reuse x pos


;credits

;code
;Axis
;Bitbreaker
;Knut
;Mahoney
;Peiselulli
;THCM
;YPS

;graphics
;Bitbreaker
;DK
;Facet
;Joe
;Prowler
;ptoing
;redcrab
;Veto

;music
;dEViLOCk
;Jammer
;Linus
;LMan


			processor 6502
			incdir "../../util/dasm/include"
			include "standard.asm"

;------------------------------------------------------------------------------
;global settings
;------------------------------------------------------------------------------
			ifnconst release
timingcolors		equ 0			;0=no colors 1=display rastertiming
			else
timingcolors		equ 0			;always 0, no colors wanted on release
			endif

volumesupport		equ 0			;0=no global volume support 1=turn on global volume support

globalfilter		equ $00			;global filter setting for 6581 $d418 output + sid

use3bit			equ 0			;0=4bit output 1=3bit output volumes 8-15
					

;------------------------------------------------------------------------------
;internal settings
;------------------------------------------------------------------------------
preset			equ 7			;0=user defined 1=4ch ProTracker 2=MLC1 3=MLC2 Loop Station
						;4 = Fast delay

includesid		equ 1			;0=no sid tune 1=play sid
volumeboost		equ 0			;possible values are 0, 25 ,50 , 75, 100 ,125, 150, 175, 200
sampleoutput		equ 3			;0=waveform 8bit 1=digimax for emulator 2=4bit $d418  3=7bit $d418  4=$d020 colors  5=$d021 colors 6=pwm gate
						;if sampleoutput=2 or 3 then volumeboost has to be 0 !!!
replayrate		equ 0			;0=7812hz (1=11718hz 2=15624hz stablenmi has to be 0!)
bitdepth		equ 3			;0=4 bit samples 1=5 bit samples 2=6bit samples 3=7bit samples 4=8bit samples mixing
signed			equ 0			;0=unsigned samples 1=signed samples, needed for loop station mixing
digivoices		equ 3			;2, 3 or 4 digi voices
sampleoffsetsupport	equ 1			;0=no global sampleoffset support 1=turn on global sampleoffset support
controlchannel		equ 0			;0=no control channel 1=use last channel as control channel
;siddelay		equ 8			;first delay of the modplay to sync goatracker sid and protracker module
			    			;values from 0 to 127 are valid
						;Fanta (Goat) uses delay of 7
						;Mahoney (Goat) uses delay of 1
						;LMan (Cheesecutter) uses delay of 4
rleimproved		equ 0			;enables better rle mode decompression	
playinterleave		equ 0			;replay using interleaved data
playlzstream		equ 0			;replay lz compressed interleaved data, needs playinterleave=1
deltacoding		equ 1			;0=normal samples 1=delta packed samples
;------------------------------------------------------------------------------
;channel specs
;thc_chn?vol	 	0=volume always max				1=volume support on
;thc_chn?per	 	0=always play period @ sampleoutputrate		1=period support on
;thc_chn?off		0=sampleoffset support off			1=sampleoffset support on
;------------------------------------------------------------------------------

thc_chn1vol		equ 0
thc_chn1per		equ 1
thc_chn1off		equ 1

thc_chn2vol		equ 0
thc_chn2per		equ 0
thc_chn2off		equ 1

thc_chn3vol		equ 0
thc_chn3per		equ 0
thc_chn3off		equ 1

;------------------------------------------------------------------------------
;constants
;------------------------------------------------------------------------------

mapsizex		equ 6144
mapsizey		equ 192
mapoffsetx		equ 0	;312			;offset for fill new chars on right side

blocksizex		equ 4
blocksizey		equ 2

compareval		equ 21			
topline			equ 37			;normally 35!!!
firstdoubleline		equ 47
midline			equ 112
midline2		equ 166
bottomline		equ 243
mixline			equ 269

cloudsy			equ 40

nmifreq1		equ 63*2-1		;every 2nd raster line
nmifreq2		equ 63*8-1		;every 8th raster line

copysplit		equ 30

startbuffer		equ 0
;-----------------------
periodsteplength	equ 39			;39 stepbytes per note

mixingbufferlength	equ 156-39		;312 rasterlines/2
nmifreq			equ $007d
		
samples			equ 31			;samples 0-31

;------------------------------------------------------------------------------
;zeropage
;------------------------------------------------------------------------------
zeropagecode		equ $02			;start of zeropage routines up to $ed

zeropage		equ $80
clearstart		equ zeropage
;runtime vars
voice1active		equ zeropage+$00
voice2active		equ zeropage+$01
voice3active		equ zeropage+$02
sample1frac		equ zeropage+$03

areg			equ zeropage+$04
xreg			equ zeropage+$05
yreg			equ zeropage+$06
nmiareg			equ zeropage+$07
nmixreg			equ zeropage+$08
nmiyreg			equ zeropage+$09

viewportxlo		equ zeropage+$0a
viewportxhi		equ zeropage+$0b

maplo			equ zeropage+$0c
maphi			equ zeropage+$0d

sprxlo1			equ zeropage+$0e	;department
sprxhi1			equ zeropage+$0f

sprxlo2			equ zeropage+$10	;credit
sprxhi2			equ zeropage+$11

sprxlo3			equ zeropage+$12	;ship
sprxhi3			equ zeropage+$13
sprylo3			equ zeropage+$14

sprpoi1			equ zeropage+$15
sprpoi2			equ zeropage+$16
sprpoi3			equ zeropage+$17

sprstripe1		equ zeropage+$18
sprstripe2		equ zeropage+$19

sprscrollreg		equ zeropage+$1a	;0-47
sprmappos		equ zeropage+$1b	;0-23

fadeflag		equ zeropage+$1c
fadepos			equ zeropage+$1d
d010temp		equ zeropage+$1e

clearend		equ zeropage+$1f

;init vars will be cleared after use
dest1lo			equ zeropage+$00
dest1hi			equ zeropage+$01
dest2lo			equ zeropage+$02
dest2hi			equ zeropage+$03
dest3lo			equ zeropage+$04
dest3hi			equ zeropage+$05
dest4lo			equ zeropage+$06
dest4hi			equ zeropage+$07


bal			equ $fe			;temp pointer
bah			equ $ff
goatlo			equ $fe			;used by sid replayer
goathi			equ $ff

;------------------------------------------------------------------------------
;memorymap
;------------------------------------------------------------------------------
;testbuffer		equ $ce00
stack			equ $0100
stackcode		equ $0100+mixingbufferlength

colorram		equ $d800
screen			equ $c000
screen2			equ $c400		;for empty first line
sprites			equ $c400		;$c000 to $e7ff=143 (one sprite gap from $c7c0-$c7ff), $f800 to $ffc0 = 31 Sprites (175 overall)
sprites2		equ $f800		;$f800 to $ffc0 = 31 sprites
charset0		equ $e800		;buffer0
charset1		equ $f000		;buffer1
spritepointer		equ screen+$03f8
spritepointer2		equ screen2+$03f8
emptysprite		equ $c400

;-----------------------

silentbuffer		equ $0400		;-$044f

notestablelo		equ $0460		;-$0467 max 18 periods
notestablehi		equ $0480		;-$047f
notesaddlo		equ $04a0		;-$0497
notesaddfrac		equ $04c0		;-$04ff

d418tab			equ $0500

mixingstackpos		equ $017f
mixingbuffer		equ $0100		;3*39=117 bytes

periodtable		equ $0600		;6 periodtables per page 3 pages up to $17ff


;------------------------------------------------------------------------------
;vblank - wait for vertical blank
;------------------------------------------------------------------------------
			org $0450
vblank			subroutine
.wait1			bit $d011
			bpl .wait1
.wait2			bit $d011
			bmi .wait2
wait14			nop			
wait12			rts				;delay 12 cycles if called by jsr

			ifnconst release
			org $04f0
			hex 12 15 0e 3a
			else
			include "../../bitfire/loader/loader_acme.inc"
			include "../../bitfire/macros/link_macros_dasm.inc"
			endif
			
			org d418tab
d418tab8580		include "Volumetables/volume_table_common_8580_096_of_256.s"
d418tab6581		include "Volumetables/volume_table_common_6581_096_of_256.s"
;------------------------------------------------------------------------------
;detect cia type
;------------------------------------------------------------------------------
			align 256,0
initnmi			subroutine
			lda #$40	;opcode rti
			sta $dd0c
			lda #$00
;			sta .cia_type+1	;not needed if run once
			sta $d01a
			sta $dd05
			sta $dc0e	;stop all timers
			sta $dc0f
			sta $dd0e
			sta $dd0f
			ldy #$7f	;forbid all timer IRQs
			sty $dc0d
			lda $dc0d
			sty $dd0d
			lda $dd0d
			inc $d019
			lda #$04	;prepare detection (timer=4 cycles)
			sta $dd04
			jsr vblank

			lda #<.cia_detect
			sta $fffa
			lda #>.cia_detect
			sta $fffb
			lda #$81
			ldx #%00011001
			stx $dd0e
			sta $dd0d
			bit $dd0d
			dec .cia_type+1
.cia_detect		pla
			pla
			pla
			sty $dd0d	;deactivate NMI
			lda $dd0d

			ldx #$05
.waitline		cpx $d012
			bne .waitline
			jsr .waitcycles
			bit $ea
			cpx $d012
			beq .skip1
			nop
			nop
.skip1			jsr .waitcycles
			bit $ea
			cpx $d012
			beq .skip2
			bit $ea
.skip2			jsr .waitcycles
			nop
			nop
			cpx $d012
			bne .onecycle
			
.onecycle		lda #<nmifreq1
			sta $dd04	
			lda #>nmifreq1
			sta $dd05	
			
			lda #<nmifreq2
			sta $dd06
			lda #>nmifreq2
			sta $dd07	

			lda #<nmiplay			;set nmi vector
			sta $fffa
			lda #>nmiplay
			sta $fffb

			lda #%00010001	;start timer CIA B

			jsr wait14
			jsr wait14
			
.cia_type		ldx #$00	
			bpl .stable			

.stable
			jsr wait12
			sta $dd0f
			nop
			nop
			nop
			bit $00
			nop
			jsr wait12
			jsr wait12
			jsr wait12
			sta $dd0e	;waveform stable @ line 10 cycle 11 (can be repositioned)
	
			rts
;-----------------------			
.waitcycles		ldy #$06
.loop1		     	dey
			bne .loop1
			inx
			nop
			nop
			nop
.wait12			rts

;------------------------------------------------------------------------------
;start / will be trashed by periodtablegen
;------------------------------------------------------------------------------
			ifnconst release
			org $0801
			;basic sys line
			dc.b $0b,$08,$00,$00,$9e,$32,$30,$36
			dc.b $31,$00,$00,$00
			else
			org $0800
			endif
			
start			subroutine
			ifnconst release
			sei
			cld
			ldx #$ff
			txs
			lda #$35
			sta $01
			jsr vblank
			inx	
			stx $d011
			stx $d020
			stx $d015
			endif
			
			jsr initsamples		;has to be called before javastart
			jsr javainit		;trashes some of the upper initroutines
			jsr sidinit
			jsr initnmi		;has to be called before javastart
			
			lda #<mixirq
			sta $fffe
			lda #>mixirq
			sta $ffff
			
			lda #$8b
			sta $d011
			lda #<mixline
			sta $d012

			ldx #$00
.stackloop		lda stackcodestart,x
			sta stackcode,x
			inx
			cpx #stackcodeend-stackcodestart
			bne .stackloop
			cli
			
			jmp main
			
			
			align 256,0
;------------------------------------------------------------------------------
stackcodestart		
			rorg stackcode
			ifconst release
			subroutine
			sei
			dec $d019
			;lda #$7f
			;sta $dd0d
			;lda $dd0d
			;sta $d01a
			;lda #$01
			;jsr link_load_comp
			jsr link_load_next_comp

			to_nmi
			set_music_addr link_music_play_side1c
			lxa #$00
			tay
			jsr link_music_init_side1c
			start_music_nmi

			;lda #16
			jsr link_load_next_comp
			;jsr link_load_comp
			;jsr link_load_next_comp
			;jsr link_load_next_raw
			;dec $01
			;jsr link_decomp
			;inc $01
			jmp link_exit
			else
			jmp *
			endif
			rend
stackcodeend

;------------------------------------------------------------------------------
;nmi-replayer
;------------------------------------------------------------------------------
nmiplaystart
	 		rorg zeropagecode
nmiplay			subroutine
			stx xbuf+1			;3+7
fetch			ldx mixingbuffer		;4
			stx $d418			;4
			inc fetch+1			;5
xbuf			ldx #$00			;2
			jmp $dd0c			;3+6 34 cycles

;------------------------------------------------------------------------------
;standard mixing routines
;------------------------------------------------------------------------------
			if preset=7				;2 channels fantasmolytic style + 2 channels for effects

.waitline		lda $d012
			and #$01
			bne .waitline
								;first sample @ line 270
mixer								;1ch period, 3ch @ base pitch
notefetch1		ldy periodtable,x			;4
samplefetch1a		lda silentbuffer,y 			;4.5
samplefetch2a		adc silentbuffer,x			;4.5
samplefetch3a		adc silentbuffer,x			;4.5
;samplefetch4a		adc silentbuffer,x			;4.5
;			bit $00
			sta mix1+1				;3
mix1			lda d418tab				;4
;			lda testbuffer,x
			sta $d418				;4=27-30

samplefetch1b		lda silentbuffer,y 			;4.5
samplefetch2b		adc silentbuffer,x			;4.5
samplefetch3b		adc silentbuffer,x			;4.5
;samplefetch4b		adc silentbuffer,x			;4.5
;			bit $00
			sta mix2+1				;3
mix2			lda d418tab				;4
;			lda testbuffer+periodsteplength,x
			sta mixingbuffer,x			;5=24-27

samplefetch1c		lda silentbuffer,y 			;4.5
samplefetch2c		adc silentbuffer,x			;4.5
samplefetch3c		adc silentbuffer,x			;4.5
;samplefetch4c		adc silentbuffer,x			;4.5
;			bit $00
			sta mix3+1				;3
mix3			lda d418tab				;4
;			lda testbuffer+periodsteplength*2,x
			sta mixingbuffer+periodsteplength,x	;5=24-27
			
samplefetch1d		lda silentbuffer,y 			;4.5
samplefetch2d		adc silentbuffer,x			;4.5
samplefetch3d		adc silentbuffer,x			;4.5
;samplefetch4d		adc silentbuffer,x			;4.5
;			bit $00
;			sta mix4+1				;3
			tay					;2
mix4			lda d418tab,y				;4
;			lda testbuffer+periodsteplength*3,x
			sta mixingbuffer+periodsteplength*2,x	;5=23-26
			inx					;2
compare			cpx #compareval				;2
			bne .waitline				;3=7  (105-117) with 4 channels 121-133 cycles using 2 pha's 117-129 cycles

exitmixer		
fadeblue		lda #$00				;06 blue
			sta $d021
			lda #periodsteplength
			sta compare+1
			lda #$60
			sta exitmixer
			jmp mixer
;			jmp mixerend

; notefetch1		ldy periodtable,x				;4
; samplefetch1a		lda silentbuffer,y 				;4.5	lda xxxy,y $b9
			; sta mix1a+1					;3
; samplefetch1b		lda silentbuffer,y 				;4.5
			; sta mix1b+1					;3
; samplefetch1c		lda silentbuffer,y 				;4.5
			; sta mix1c+1					;3
; samplefetch1d		lda silentbuffer,y 				;4.5
			; sta mix1d+1					;3	= 34 cycles (32-36)

; samplefetch2a		ldy silentbuffer,x 				;4.5	ldy xxxx,y $bc
; mix1a			lda d418tab,y					;4
; mixswitch1		sta mixingbuffer,x				;5
; samplefetch2b		ldy silentbuffer,x 				;4.5
; mix1b			lda d418tab,y					;4
; mixswitch2		sta mixingbuffer+periodsteplength,x		;5
; samplefetch2c		ldy silentbuffer,x 				;4.5
; mix1c			lda d418tab,y					;4
; mixswitch3		sta mixingbuffer+periodsteplength*2,x		;5
; samplefetch2d		ldy silentbuffer,x 				;4.5
; mix1d			lda d418tab,y					;4
; mixswitch4		sta mixingbuffer+periodsteplength*3,x		;5	=54 cycles (52-56)

			; dex						;2
			; bpl notefetch1					;3
			; rts
			endif	;preset=7
			rend
nmiplayend

;------------------------------------------------------------------------------
;sampleheader
;------------------------------------------------------------------------------
			org $0b00
			include "thc_sampleheader.asm"
			echo "End of Init:", *
	
;------------------------------------------------------------------------------
;initscreen2
;------------------------------------------------------------------------------
initscreen2		subroutine
			if mapoffsetx>0		;start with filled screen
			lda #<blockmap
			sta maplo
			lda #>blockmap
			sta maphi
			
			lda #<screen
			sta dest1lo
			lda #<screen+80
			sta dest2lo

			lda #>screen
			sta dest1hi
			sta dest2hi
			
			lda #<colorram
			sta dest3lo
			lda #<colorram+80
			sta dest4lo

			lda #>colorram
			sta dest3hi
			sta dest4hi

.linecount		ldx #$00
.nextline		ldy #$00
.nextblock		lax (maplo),y
			tya
			asl
			asl
			tay
			
			lda charblock0,x
			sta (dest1lo),y
			lda charblock4,x
			sta (dest2lo),y

			lda colorblock0,x
			sta (dest3lo),y
			lda colorblock4,x
			sta (dest4lo),y
			iny
			
			lda charblock1,x
			sta (dest1lo),y
			lda charblock5,x
			sta (dest2lo),y

			lda colorblock1,x
			sta (dest3lo),y
			lda colorblock5,x
			sta (dest4lo),y
			iny

			lda charblock2,x
			sta (dest1lo),y
			lda charblock6,x
			sta (dest2lo),y

			lda colorblock2,x
			sta (dest3lo),y
			lda colorblock6,x
			sta (dest4lo),y
			iny

			lda charblock3,x
			sta (dest1lo),y
			lda charblock7,x
			sta (dest2lo),y
			
			lda colorblock3,x
			sta (dest3lo),y
			lda colorblock7,x
			sta (dest4lo),y
			
			ldy .nextline+1
			iny
			sty .nextline+1
			cpy #10
			bne .nextblock

doof			lda maplo
			clc
			adc #<[mapsizex/32]
			sta maplo
			
			bcc .over1
			inc maphi
			clc

.over1			lda dest1lo
			adc #160
			sta dest1lo
			
			bcc .over2
			inc dest1hi
			clc
			
.over2			lda dest2lo
			adc #160
			sta dest2lo
			
			bcc .over3
			inc dest2hi
			clc

.over3			lda dest3lo
			adc #160
			sta dest3lo
			
			bcc .over4
			inc dest3hi
			clc

.over4			lda dest4lo
			adc #160
			sta dest4lo
			
			bcc .over5
			inc dest4hi
			clc

.over5			ldy #$00
			sty .nextline+1
			
			ldx .linecount+1
			inx
			stx .linecount+1
			cpx #mapsizey/32
			beq .done
			jmp .nextline
			
			else
			
			ldx #$00
.clear			lda #$00
			sta screen,x			
			sta screen+$100,x			
			sta screen+$200,x			
			sta screen+$300,x			
			; lda #$03
			; sta colorram,x
			; sta colorram+$100,x
			; sta colorram+$200,x
			; sta colorram+$300,x
			inx
			bne .clear
			
			endif
			
.done			rts

;------------------------------------------------------------------------------
;main
;------------------------------------------------------------------------------
main			subroutine
			jsr periodtablegen	;has to be called before javastart
			jsr initscreen
			jsr javarestart
			jsr vblank
			
			inc $d019
			lda #$01
			sta $d01a
			cli
			
startloading		lda #$00
			beq startloading
			jsr vblank
			sei
			lda #$00
			sta $d418
			sta $d020
			sta $d021
			sta $d011
			sta $d015
			jmp stackcode

; .forever		inc $ce80,x
			; bpl .forever2
; .forever2		inx
			; bit $00
			; lda $ce80
			; sta $ce80
			; nop
			; inc $ce80,x
			; inx
			; jmp .forever
		
;------------------------------------------------------------------------------
;topirq - line 47
;------------------------------------------------------------------------------
topirq			subroutine
			sta areg

doublebuffer		lda #$00			;buffer 0-1
			bne .over1

			lda #<nmifld00
			sta $fffa
			lda #>nmifld00
			sta $fffb
			jmp .over2
			
.over1			lda #<nmiblank00
			sta $fffa
			lda #>nmiblank00
			sta $fffb
.over2
			if timingcolors=1
			inc $d020
			endif
			
			lda #$00
			sta $ffff
	
			lda #$ff
			sta $d01b
	
			lda #<mixingbuffer+$68
			sta fetch+1
	
			lda #cloudsy+21
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f
			
			lda #<topirq2
			sta $fffe
;			lda #>midirq
;			sta $ffff

			lda #81-2
			sta $d012

			; lda #59
			; sta $d012
			
			; lda #<topirq2
			; sta $fffe
			; lda #>topirq2
			; sta $ffff

			inc $d019

			if timingcolors=1
			dec $d020
			endif
			
			lda areg
			rti
			
;------------------------------------------------------------------------------
;topirq - line 78
;------------------------------------------------------------------------------
topirq2			subroutine
			sta areg
			stx xreg
			sty yreg

			if timingcolors=1
			inc $d020
			endif

			ldy sprpoi1
			lda #$5a
		
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f

			lax spe_dataxlo0,y
			sta sprxlo1
			lda spe_dataxhi0,y
			sta sprxhi1
			beq .noclipx
			bmi .clipleft
			cmp #$02
			bcs .clipright
			cpx #$50
			bcc .noclipx2
			bcs .clipright

.clipleft		ldy #$00
			sty $d000

			lda #$ff
			sbx #-24
			bcs .noclipleft1
			sty $d002
			sbx #-24
			bcs .noclipleft2
			sty $d004
			sbx #-24
			bcs .noclipleft3
			sty $d006
			sbx #-24
			bcs .noclipleft4
			sty $d008
			sbx #-24
			bcs .noclipleft5
			sty $d00a
			sbx #-24
			bcs .noclipleft6
			sty $d00c
			sbx #-24
			bcs .noclipleft7
			sty $d00e
			jmp .clipxend

.clipright		ldx #$4f
.noclipx2
			ldy #$ff
			tya
			stx $d000
			sbx #-24

.noclipleft1		stx $d002
			sbx #-24
.noclipleft2
			stx $d004
			sbx #-24
.noclipleft3
			stx $d006
			sbx #-24
.noclipleft4
			stx $d008
			sbx #-24
.noclipleft5
			stx $d00a
			sbx #-24
.noclipleft6
			stx $d00c
			sbx #-24
.noclipleft7		stx $d00e
			jmp .clipxend

.noclipx
			tay
			lda #$ff
			stx $d000
			sbx #-24
			stx $d002
			bcc .over1
			ldy #%11111110
.over1
			sbx #-24
			stx $d004
			bcc .over2
			ldy #%11111100
.over2
			sbx #-24
			stx $d006
			bcc .over3
			ldy #%11111000
.over3
			sbx #-24
			stx $d008
			bcc .over4
			ldy #%11110000
.over4
			sbx #-24
			stx $d00a
			bcc .over5
			ldy #%11100000
.over5
			sbx #-24
			stx $d00c
			bcc .over6
			ldy #%11000000
.over6
			sbx #-24
			stx $d00e
			bcc .over7
			ldy #%10000000
.over7

.clipxend		sty $d010
			sty handled010+1

			ldy sprstripe1
			ldx department,y
			lda spritemc1,x
			sta $d025
			lda spritemc2,x
			sta $d026
			lda spritecol,x
			sta $d027
			sta $d028
			sta $d029
			sta $d02a
			sta $d02b
			sta $d02c
			sta $d02d
			sta $d02e
			
			ldx department,y
			txa
			asl
			asl
			asl
			tax
			lda spritemap,x
			sta spritepointer
			lda spritemap+1,x
			sta spritepointer+1
			lda spritemap+2,x
			sta spritepointer+2
			lda spritemap+3,x
			sta spritepointer+3
			lda spritemap+4,x
			sta spritepointer+4
			lda spritemap+5,x
			sta spritepointer+5
			lda spritemap+6,x
			sta spritepointer+6
			lda spritemap+7,x
			sta spritepointer+7
			
			ldx #$00
			stx $d01d
			stx $d01b
			dex
			stx $d01c

			ldy sprstripe1
			cpy #20
			beq .nomoresprites

			ldx sprpoi1
			inx
			cpx #144
			bne .over
			iny
			sty sprstripe1

			ldx #$00
.over			stx sprpoi1

.nomoresprites		lda $d000
			sta handled000+1
			lda $d002
			sta handled002+1
			lda $d004
			sta handled004+1
			lda $d006
			sta handled006+1
			lda $d008
			sta handled008+1
			lda $d00a
			sta handled00a+1
			lda $d00c
			sta handled00c+1
			lda $d00e
			sta handled00e+1

			lda #<midirq
			sta $fffe
			lda #>midirq
			sta $ffff

			lda #midline-3
			sta $d012

			inc $d019
			
			if timingcolors=1
			dec $d020
			endif
			
			lda areg
			ldx xreg
			ldy yreg
			rti

;------------------------------------------------------------------------------
;midirq - line 110
;------------------------------------------------------------------------------
midirq			subroutine
			sta areg
			stx xreg
			sty yreg

			if timingcolors=1
			inc $d020
			endif
	
			ldy sprpoi3
.datagety		lda spe_datay2,y
			sta .datagety2+1
			clc
			adc sprylo3
			sta sprylo3
			;tay
			sta $d001
			sta $d003
			clc
			adc #21
			sta $d005
			sta $d007

.datagetx		lax spe_datax2,y
			bmi .nodey
			ldx #$00

.nodey			adc sprxlo3
			sta sprxlo3
			tay
			txa
			adc sprxhi3
			sta sprxhi3

			beq .noclipx
			bmi .clipleft
			ldx #%00001111
			cmp #$02
			bcs .clipright
			cmp #$50
			bcc .noclipx + 1
.clipright		lda #$4f
			jmp .noclipx2

.clipleft		tya
			stx $d000
			stx $d004
			adc #24
			bcs .noclipleft1
			stx $d002
			stx $d006
			jmp .clipxend

.noclipleft1		sta $d002
			sta $d006
			jmp .clipxend

.noclipx
			tax
			tya
.noclipx2		sta $d000
			sta $d004
			clc
			adc #24
			sta $d002
			sta $d006
			bcc .clipxend
			ldx #%00001010
.clipxend		stx .d010top+1
;-----------------------
			ldy #$00
			lax sprxlo3
			sbx #$10
			lda sprxhi3
			sbc #$00
sucks			beq .noclipx3
			bmi .clipleft2
			ldy #%00110000
			cmp #$02
			bcs .clipright2
			cmp #$50
			bcc .noclipx3
.clipright2		ldx #$4f
			jmp .noclipx3

.clipleft2		txa
			sty $d00a
			clc
			adc #$08
			bcs .noclipleft2
			sty $d008
			jmp .clipxend2
.noclipleft2		sta $d008
			sta $d00a
			jmp .clipxend2

.noclipx3		txa
			sta $d00a
			sbx #$f8
			stx $d008
			bcc .clipxend2
			ldy  #%00010000

.clipxend2		tya
.d010top		ora #$00
			sta $d010
			lda #2
			sta $d025
			lsr
			sta $d02b
			sta $d02c

			lda #10
			sta $d026

			lda #$07
			sta $d027
			sta $d028
			sta $d029
			sta $d02a

.engineframe		lda #$00
			;clc
			adc #$01
			and #%00000111
			sta .engineframe+1
			asr #$fe
			adc #[shipsprites-$c000]/64+20
			sta spritepointer+4
			sta spritepointer+5

planephase		ldy #$0b

.datagety2		lda #$00
			beq .steady
			bmi .noseup
			iny
			cpy #$10
			bcc .over2
			clc
.noseup			dey
			bpl .over2
			ldy #$00
.over2			sty planephase+1

.steady			lax .planeframes,y
			adc #[shipsprites-$c000]/64
			sta spritepointer
			adc #$01
			sta spritepointer+1
			adc #$01
			sta spritepointer+2
			adc #$01
			sta spritepointer+3

			lda sprylo3
			adc .engineyoff1,x
			sta $d009
			adc .engineyoff2,x
			sta $d00b

			ldx sprpoi3
			inx
			cpx #144
			bne .over

			ldx #$00
			lda sprstripe1
			cmp #20
			bne .looping

			lda #<spe_datay4
			sta .datagety+1
			lda #>spe_datay4
			sta .datagety+2

			lda #<spe_datax4
			sta .datagetx+1
			lda #>spe_datax4
			sta .datagetx+2
			jmp .over

.looping		lda #<spe_datay3
			sta .datagety+1
			lda #>spe_datay3
			sta .datagety+2

			lda #<spe_datax3
			sta .datagetx+1
			lda #>spe_datax3
			sta .datagetx+2

.over			stx sprpoi3

			lda #<midirq2
			sta $fffe
			lda #>midirq2
			sta $ffff

			lda #midline2+3
			sta $d012

			inc $d019
			
			if timingcolors=1
			dec $d020
			endif
			
			lda areg
			ldx xreg
			ldy yreg
			rti
			
.planeframes		dc.b $00,$00,$04,$04,$08,$08,$08,$08,$08,$08,$08,$08,$0c,$0c,$10,$10

.engineyoff1		dc.b $0a,0,0,0,$08,0,0,0,$06,0,0,0,$02,0,0,0,$00
.engineyoff2		dc.b $08,0,0,0,$0c,0,0,0,$0e,0,0,0,$15,0,0,0,$18

;------------------------------------------------------------------------------
;midirq2 - line 150
;------------------------------------------------------------------------------
midirq2			subroutine
			sta areg
			stx xreg
			sty yreg

			if timingcolors=1
			inc $d020
			endif

handled000		lda #$00
			sta $d000
handled002		lda #$00
			sta $d002
handled004		lda #$00
			sta $d004
handled006		lda #$00
			sta $d006
handled008		lda #$00
			sta $d008
handled00a		lda #$00
			sta $d00a
handled00c		lda #$00
			sta $d00c
handled00e		lda #$00
			sta $d00e
handled010		lda #$00
			sta $d010

			; ldx sprpoi2
			; lda spe_dataxlo0,x
			; sta sprxlo2
			; lda spe_dataxhi0,x
			; sta sprxhi2
			
			; ldy #$00
			; ldx sprxlo2
			; lda sprxhi2
			; beq .noclipx
			; bmi .clipleft
			; dey
			; cmp #$02
			; bcs .clipright
			; txa
			; cmp #$50
			; bcc .noclipx2
; .clipright		lda #$4f
			; jmp .noclipx2

; .clipleft		sty $d000
			
			; txa
			; clc
			; adc #24
			; bcs .noclipleft1
			; sty $d002
			; adc #24
			; bcs .noclipleft2
			; sty $d004
			; adc #24
			; bcs .noclipleft3
			; sty $d006
			; adc #24
			; bcs .noclipleft4
			; sty $d008
			; adc #24
			; bcs .noclipleft5
			; sty $d00a
			; adc #24
			; bcs .noclipleft6
			; sty $d00c
			; adc #24
			; bcs .noclipleft7
			; sty $d00e
			; jmp .clipxend
			
; .noclipleft1		sta $d002
			; adc #24-1
; .noclipleft2		clc			
			; sta $d004
			; adc #24
; .noclipleft3		clc
			; sta $d006
			; adc #24
; .noclipleft4		clc
			; sta $d008
			; adc #24
; .noclipleft5		clc
			; sta $d00a
			; adc #24
; .noclipleft6		clc
			; sta $d00c
			; adc #24
; .noclipleft7		sta $d00e	
			; jmp .clipxend
			
; .noclipx		txa
; .noclipx2		sta $d000
			; clc
			; adc #24
			; sta $d002
			; bcc .over1
			; ldy #%11111110
			; clc
; .over1
			; adc #24
			; sta $d004
			; bcc .over2
			; ldy #%11111100
			; clc
; .over2
			; adc #24
			; sta $d006
			; bcc .over3
			; ldy #%11111000
			; clc
; .over3
			; adc #24
			; sta $d008
			; bcc .over4
			; ldy #%11110000
			; clc
; .over4
			; adc #24
			; sta $d00a
			; bcc .over5
			; ldy #%11100000
			; clc
; .over5
			; adc #24
			; sta $d00c
			; bcc .over6
			; ldy #%11000000
			; clc
; .over6
			; adc #24
			; sta $d00e
			; bcc .over7
			; clc
			; ldy #%10000000
; .over7

; .clipxend		sty $d010

			ldx sprstripe2
			lda spritemc1,x
			sta $d025
			lda spritemc2,x
			sta $d026
			lda spritecol,x
			sta $d027
			sta $d028
			sta $d029
			sta $d02a
			sta $d02b
			sta $d02c
			sta $d02d
			sta $d02e
			txa
			asl
			asl
			asl
			tax
			lda spritemap,x
			sta spritepointer
			lda spritemap+1,x
			sta spritepointer+1
			lda spritemap+2,x
			sta spritepointer+2
			lda spritemap+3,x
			sta spritepointer+3
			lda spritemap+4,x
			sta spritepointer+4
			lda spritemap+5,x
			sta spritepointer+5
			lda spritemap+6,x
			sta spritepointer+6
			lda spritemap+7,x
			sta spritepointer+7
						
			ldx sprpoi2
			lda spe_dataylo0,x
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f

			ldy sprstripe2
			cpy #23
			beq .nomoresprites
			
			inx
			cpx #144
			bne .over
			iny
			sty sprstripe2
			
			ldx #$00
.over			stx sprpoi2			

.nomoresprites		lda #bottomline
			sta $d012
			
			lda #<bottomirq
			sta $fffe
			lda #>bottomirq
			sta $ffff

			inc $d019

			if timingcolors=1
			dec $d020
			endif
			
			lda areg
			ldx xreg
			ldy yreg
			rti
;------------------------------------------------------------------------------
;bottomirq - line 243
;------------------------------------------------------------------------------
bottomirq		subroutine
			sta areg
			lda #$7f
			sta $dd0d
			lda $dd0d
				
			lda #<nmiplay
			sta $fffa
			lda #>nmiplay
			sta $fffb

			lda #$81
			sta $dd0d

			if timingcolors=1
			inc $d020
			endif

exitflag		lda #$00
			beq .over

			; lda #$60		;rts
			; sta doscroll
			; sta thcplay

			lda #$7f
			sta $dd0d
			lda $dd0d
			
			inc startloading+1

			lda #$00
			sta $d01a
			beq .exitirq
		
.over			lda viewportxhi
			cmp #>[mapsizex-32]
			bne .doscroll
			lda viewportxlo
			cmp #<[mapsizex-32]
			bne .doscroll

			lda #$0f
			sta fadepos
			dec fadeflag
			
.doscroll		lda viewportxlo
			clc
			adc #$02
			sta viewportxlo
			bcc .over3
			inc viewportxhi
.over3			and #%000001000
			lsr
			lsr
			lsr
			sta doublebuffer+1
.noscroll
			lda #<bottomirq2
			sta $fffe
			lda #>bottomirq2
			sta $ffff

			lda #$f9
			sta $d012

			inc $d019

.exitirq		if timingcolors=1
			dec $d020
			endif
			lda areg
			rti
			
;------------------------------------------------------------------------------
;bottomirq2 - line 249
;------------------------------------------------------------------------------
bottomirq2		subroutine
			sta areg
			lda #$ff
			sta $ffff
			if timingcolors=1
			inc $d020
			endif

			lda #<bottomirq3
			sta $fffe

			lda #$02
			sta $d012

			inc $d019

			lda #$93
			sta $d011

			lda #cloudsy
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f

			if timingcolors=1
			dec $d020
			else
			delay 6
			endif
			
			lda #$00
			sta $d021
			
			stx xreg
			ldx fadeflag
			beq .nofade
			bpl .fadein
			
.fadeout		ldx fadepos
			lda fadetocyan,x
			sta fadecyan+1
			lda fadetoblue,x
			sta fadeblue+1
			lda fadetopurple,x
			sta fadepurple+1
			lda fadetolightblue,x
			sta fadelightblue+1
			lda fadetolightred,x
			sta fadelightred+1
			lda fadetoyellow,x
			sta fadeyellow+1
			lda fadetowhite,x
			sta fadewhite+1
			sta fadewhite2+1
			dex
			bpl .fade1
			stx exitflag+1
			jmp .nofade		
			
.fadein			ldx fadepos
			lda fadetocyan,x
			sta fadecyan+1
			lda fadetoblue,x
			sta fadeblue+1
			lda fadetopurple,x
			sta fadepurple+1
			lda fadetolightblue,x
			sta fadelightblue+1
			lda fadetolightred,x
			sta fadelightred+1
			lda fadetoyellow,x
			sta fadeyellow+1
			lda fadetowhite,x
			sta fadewhite+1
			sta fadewhite2+1
			inx
			cpx #$10
			bne .fade1
			lda #$00
			sta fadeflag
			beq .nofade
.fade1			stx fadepos		
			
.nofade			lda #>bottomirq3
			sta $ffff
			
			lda areg
			ldx xreg
			rti

;------------------------------------------------------------------------------
;bottomirq3 - line 258
;------------------------------------------------------------------------------
bottomirq3		subroutine
			sta areg
			stx xreg
			sty yreg

			if timingcolors=1
			inc $d020
			endif

			lda #<mixirq
			sta $fffe
			lda #>mixirq
			sta $ffff

			lda #<mixline
			sta $d012

			inc $d019

			lda #$00
			sta $d015

			ldx #$ff
			stx $d01d
			inx
			stx $d01c
			  
fadewhite		ldx #$01		;$01 white
			stx $d027
			stx $d028
			stx $d029
			stx $d02a
			stx $d02b
			stx $d02c
			stx $d02d
			stx $d02e
			  
			ldx sprscrollreg	;scroll map
			dex
			bpl .over
			ldy sprmappos
			iny
			cpy #16
			bne .noreset
			ldy #$00
.noreset		sty sprmappos
			ldx #47
.over			stx sprscrollreg

			ldy #%11000000
			txa		;scrollreg
			sec
			sbc #$18
			bcs .noset1
			ldy #%11000001
			sec
			sbc #$08
			cmp #$e0
			bcs .noset1
			lda #$e0
.noset1			sta $d000

			txa		;scrollreg
			clc
			adc #$18
			sta $d002
			adc #$30
			sta $d004
			adc #$30
			sta $d006
			adc #$30
			sta $d008
			adc #$30
			sta $d00a
			tax
			bcc .noset2
			tya
			ora #%00100000
			tay
			clc
.noset2			txa
			adc #$30
			sta $d00c
			clc
			adc #$30
			cmp #$58
			bcc .noset3
			lda #$58
			clc			;needed for below
.noset3			sta $d00e
			sty $d010
			
			ldx sprmappos
			lda spriteline0,x
			sta spritepointer
			sta spritepointer2
			lda spriteline0+1,x
			sta spritepointer+1
			sta spritepointer2+1
			lda spriteline0+2,x
			sta spritepointer+2
			sta spritepointer2+2
			lda spriteline0+3,x
			sta spritepointer+3
			sta spritepointer2+3
			lda spriteline0+4,x
			sta spritepointer+4
			sta spritepointer2+4
			lda spriteline0+5,x
			sta spritepointer+5
			sta spritepointer2+5
			lda spriteline0+6,x
			sta spritepointer+6
			sta spritepointer2+6
			lda spriteline0+7,x
			sta spritepointer+7
			sta spritepointer2+7

			lda spriteline1,x
			sta sprpoi0a+1
			sta sprpoi0b+1
			lda spriteline1+1,x
			sta sprpoi1a+1
			sta sprpoi1b+1
			lda spriteline1+2,x
			sta sprpoi2a+1
			sta sprpoi2b+1
			lda spriteline1+3,x
			sta sprpoi3a+1
			sta sprpoi3b+1
			lda spriteline1+4,x
			sta sprpoi4a+1
			sta sprpoi4b+1
			lda spriteline1+5,x
			sta sprpoi5a+1
			sta sprpoi5b+1
			lda spriteline1+6,x
			sta sprpoi6a+1
			sta sprpoi6b+1
			lda spriteline1+7,x
			sta sprpoi7a+1
			sta sprpoi7b+1

			lda #$9b+$40
			sta $d011
			lda #$00
			sta $d016

			if timingcolors=1
			dec $d020
			endif
			lda areg
			ldx xreg
			ldy yreg
			rti

;------------------------------------------------------------------------------
;mixirq - line 269
;------------------------------------------------------------------------------
mixirq			subroutine
			stx .xreg+1
			ldx #$7f
			stx $dd0d
			ldx $dd0d
;			tsx
;			stx stacksave
;			ldx #<mixingstackpos
;			txs
			
			if timingcolors=1
			ldx #$02
			stx $d020
			endif

			sta .areg+1
			sty .yreg+1
			
			lda #<topirq
			sta $fffe
			lda #>topirq
			sta $ffff
			
			lda #<mixingbuffer
			sta fetch+1

			ldx #$00
			clc
			jsr mixer
;-----------------------			
;			align 256,0
mixerend			
;			ldx stacksave
;			txs
			
			ldx #$81
			stx $dd0d

			lda #compareval
			sta compare+1
			lda #$a9		;lda #imm
			sta exitmixer

			if timingcolors=1
			inc $d020
			endif

			lda #$ff
			sta $d015

			lda #$1b+$40
			sta $d011
			lda #firstdoubleline
			sta $d012

			if timingcolors=1
			lda #$0b
			sta $d020
			endif
			inc $d019
			cli			;fast detach

.scrolltask		if timingcolors=1
			lda #$05
			sta $d020
			endif
			lda viewportxlo
			and #%00000111
			eor #%00010111
			sta setd016a+1
			sta setd016b+1

			jsr doanim
			
			if timingcolors=1
			inc $d020
			endif
			
			jsr doscroll
endscroll			
			if timingcolors=1
			lda #$04
			sta $d020
			endif
			jsr thcplay
			if timingcolors=1
			lda #$0b
			sta $d020
			endif
			
			; inc $d020
			; ldx #24
; .nextloop		jsr wait12
			; jsr wait12
			; jsr wait12
			; jsr wait12
			; jsr wait12
			; dex
			; bpl .nextloop
			; dec $d020
			
.areg			lda #$00
.xreg			ldx #$00
.yreg			ldy #$00
			rti
;------------------------------------------------------------------------------
;nmi routines fld
;------------------------------------------------------------------------------
			align 256,0
			subroutine
nmifld00		stx nmixreg		;3+7	line 48
			ldx #[>[screen-$c000]<<2] | [>[charset0-$c000]>>2]	;2	screen2
			stx $d018		;4
			ldx mixingbuffer+6	;4
			stx $d418		;4
			ldx #<nmifld01		;2
			stx $fffa		;4
			ldx nmixreg		;3
			jmp $dd0c		;3+6

nmifld01		stx nmixreg		;3+7	line 50
			ldx #$1f;+$40		;2
			stx $d011		;4
			ldx mixingbuffer+7	;4
			stx $d418		;4
			ldx #<nmifld02		;2
			stx $fffa		;4
			ldx nmixreg		;3
			jmp $dd0c		;3+6

nmifld02		stx nmixreg		;3+7	line 52
			ldx #$1b		;2
			stx $d011		;4
			ldx mixingbuffer+8	;4
			stx $d418		;4
			ldx #<nmifld03		;2
			stx $fffa		;4
			ldx nmixreg		;3
			jmp $dd0c		;3+6

nmifld03		stx nmixreg		;3+7	line 54
			ldx mixingbuffer+9	;4
			stx $d418		;4
			ldx #<nmifld04		;2
			stx $fffa		;4
			ldx nmixreg		;3
			jmp $dd0c		;3+6
			
nmifld04		stx nmixreg		;3+7	line 56
			ldx mixingbuffer+10	;4
			stx $d418		;4
			ldx #<nmifld05		;2
			stx $fffa		;4
setd016a		ldx #$d8
			stx $d016
			ldx nmixreg		;3
			jmp $dd0c		;3+6

nmifld05		stx nmixreg		;3+7	line 58
			ldx #[>[screen-$c000]<<2] | [>[charset0-$c000]>>2]	;2
			stx $d018		;4
			ldx mixingbuffer+11	;4
			stx $d418		;4
			ldx #<nmifld06		;2
			stx $fffa		;4
			ldx nmixreg		;3
			jmp $dd0c		;3+6

nmifld06		stx nmixreg		;3+7	line 60
			ldx mixingbuffer+12	;4
			stx $d418		;4
			nop
			nop
			sta nmiareg
			sty nmiyreg
sprpoi0a		lda #[emptysprite-$c000]/64
sprpoi1a		ldx #[emptysprite-$c000]/64
sprpoi2a		ldy #[emptysprite-$c000]/64
			sta spritepointer
			stx spritepointer+1
			sty spritepointer+2
sprpoi3a		ldx #[emptysprite-$c000]/64
			stx spritepointer+3
sprpoi4a		ldx #[emptysprite-$c000]/64
			stx spritepointer+4
sprpoi5a		ldx #[emptysprite-$c000]/64
			stx spritepointer+5
sprpoi6a		ldx #[emptysprite-$c000]/64
			stx spritepointer+6
sprpoi7a		ldx #[emptysprite-$c000]/64
			stx spritepointer+7
			ldx #$83		;2
			stx $dd0d		;4
			lda nmiareg
			ldy nmiyreg
			ldx #<nmifld07	;2
			stx $fffa		;4
;			ldx nmixreg		;3
;			jmp $dd0c		;3+6
			
nmifld07		;stx nmixreg		;3+7	line 62
			ldx mixingbuffer+13	;4
			stx $d418		;4
			ldx #<nmi000		;2
			stx $fffa		;4
			ldx #>nmi000		;2
			stx $fffb		;4
			ldx #>topirq2
			stx $ffff
			ldx nmixreg		;3
			jmp $dd0c		;3+6
;------------------------------------------------------------------------------
;nmi routines blank
;------------------------------------------------------------------------------
			align 256,0
			subroutine
nmiblank00		stx nmixreg		;3+7	line 48
			ldx #$1b		;2
			stx $d011		;4
			ldx mixingbuffer+6	;4
			stx $d418		;4
			ldx #<nmiblank01	;2
			stx $fffa		;4
			ldx nmixreg		;3
			jmp $dd0c		;3+6

nmiblank01		stx nmixreg		;3+7	line 50
			ldx #[>[screen2-$c000]<<2] | [>[charset0-$c000]>>2]	;2	screen2
			stx $d018		;4
			ldx mixingbuffer+7	;4
			stx $d418		;4
			ldx #<nmiblank02	;2
			stx $fffa		;4
			ldx nmixreg		;3
			jmp $dd0c		;3+6

nmiblank02		stx nmixreg		;3+7	line 52
			ldx mixingbuffer+8	;4
			stx $d418		;4
			ldx #<nmiblank03	;2
			stx $fffa		;4
			ldx nmixreg		;3
			jmp $dd0c		;3+6

nmiblank03		stx nmixreg		;3+7	line 54
			ldx mixingbuffer+9	;4
			stx $d418		;4
			ldx #<nmiblank04	;2
			stx $fffa		;4
			ldx nmixreg		;3
			jmp $dd0c		;3+6
			
nmiblank04		stx nmixreg		;3	line 56
			ldx mixingbuffer+10	;4
			stx $d418		;4
			ldx #<nmiblank05	;2
			stx $fffa		;6
			sta nmiareg		;3
setd016b		lda #$d8
			sta $d016
			lda #$1b		;2
			bit $dd0d		;4
			tsx			;2
			delay 42
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop
			
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop
;			nop

;			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop

			; nop
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop

sucker3			inc $d020
			jmp sucker3

nmiblank05		txs			;2+7	line 58
			ldx #[>[screen-$c000]<<2] | [>[charset0-$c000]>>2]	;2
			stx $d018		;4
			ldx mixingbuffer+11	;4
			stx $d418		;4
			ldx #<nmiblank06	;2
			stx $fffa		;6
			bit $dd0d		;4
			sta $d011		;4
			ldx nmixreg		;3
			lda nmiareg		;3
			rti			;6

nmiblank06		stx nmixreg		;3+7	line 60
			ldx mixingbuffer+12	;4
			stx $d418		;4
			nop
			sta nmiareg
			sty nmiyreg
sprpoi0b		lda #[emptysprite-$c000]/64
sprpoi1b		ldx #[emptysprite-$c000]/64
sprpoi2b		ldy #[emptysprite-$c000]/64
			sta spritepointer
			stx spritepointer+1
			sty spritepointer+2
sprpoi3b		ldx #[emptysprite-$c000]/64
			stx spritepointer+3
sprpoi4b		ldx #[emptysprite-$c000]/64
			stx spritepointer+4
sprpoi5b		ldx #[emptysprite-$c000]/64
			stx spritepointer+5
sprpoi6b		ldx #[emptysprite-$c000]/64
			stx spritepointer+6
sprpoi7b		ldx #[emptysprite-$c000]/64
			stx spritepointer+7
			ldx #$83		;2
			stx $dd0d		;4
			lda nmiareg
			ldy nmiyreg
;			ldx #<nmiblank07	;2
;			stx $fffa		;4
;			ldx nmixreg		;3
;			jmp $dd0c		;3+6
			
nmiblank07
;			stx nmixreg		;3+7	line 62
			ldx mixingbuffer+13	;4
			stx $d418		;4
			ldx #<nmi000		;2
			stx $fffa		;4
			ldx #>nmi000		;2
			stx $fffb		;4
			ldx #>topirq2
			stx $ffff
			ldx nmixreg		;3
			jmp $dd0c		;3+6
;------------------------------------------------------------------------------
;nmi routines line doubling
;------------------------------------------------------------------------------
			mac nmidouble
			subroutine
nmi{1}0			stx nmixreg		;3+7	line 64
			ldx pointer		;4
			incpointer
			stx $d418		;4
			ldx #<nmipre{1}1	;2
			stx $fffa		;4
			if {1}=0
;setd016			ldx #$d8
;			stx $d016
			nop
			nop
			nop
			nop
fadepurple		ldx #$00		;$04 purple
			stx $d021
			endif

			if {1}=1
			delay 8
fadewhite2		ldx #$00		;$01 white
			stx $d021
			endif

			ldx nmixreg		;3
			jmp $dd0c		;3+6

;-----------------------			
nmipre{1}1		stx nmixreg		;3+7	line 65
			ldx #<nmi{1}1		;2
			stx $fffa		;4
			sta nmiareg		;3
			bit $dd0d		;4
			tsx			;2

			if {1}=0
			nop
			nop
			nop
			nop
			nop
;.bam2			inc $d020
;			jmp .bam2
			else
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop

			nop
			nop
			nop
			nop
			
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop
			; nop


.bam2			inc $d020
			jmp .bam2
			endif
			
;-----------------------			
nmi{1}1			txs			;2+7	line 66
			ldx pointer		;4
			incpointer
			stx $d418		;4
			ldx #<nmi{1}2		;2
			stx $fffa		;4
			ldx #[>[screen-$c000]<<2] | [>[charset1-$c000]>>2]	;2
			bit $dd0d		;4
			lda #$1a		;2
			sta $d011		;4
			stx $d018		;4
			ldx nmixreg		;3
			lda nmiareg		;3
			rti			;6
;-----------------------			
nmi{1}2			if {2}=0
			stx nmixreg		;3+7	line 68
			ldx pointer		;4
			incpointer
			stx $d418		;4
			ldx #<nmi{1}3		;2
			stx $fffa		;4
			if {1}=0
			delay 8
fadelightblue		ldx #$00		;$0e light blue
			stx $d021
			endif
			if {1}=1
			delay 8
fadecyan		ldx #$00		;$03 cyan
			stx $d021
			endif
			ldx nmixreg		;3
			jmp $dd0c		;3+6
;-----------------------			
nmi{1}3			stx nmixreg		;3+7	line 70
			ldx pointer		;4
			incpointer
			stx $d418		;4
			ldx #<nmi{1}4		;2
			stx $fffa		;4
			ldx nmixreg		;3
			inc $d011		;6
			jmp $dd0c		;3+6
;-----------------------			
nmi{1}4			stx nmixreg		;3+7	line 72
			ldx pointer		;4
			incpointer
			stx $d418		;4
			ldx #<nmipre{1}5	;2
			stx $fffa		;6
			if {1}=0
			delay 8
fadelightred		ldx #$00		;$0a light red
			stx $d021
			endif
			ldx nmixreg		;3
			jmp $dd0c		;3+6
;-----------------------			
			
nmipre{1}5		stx nmixreg		;3	line 73
			ldx #<nmi{1}5		;2
			stx $fffa		;4
			bit $dd0d		;4
			tsx			;2
			if {1}=0
			nop
			nop
			nop
			nop
			nop
			nop
;.bam1			inc $d020
;			jmp .bam1
			else

			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			
			nop
			nop
			nop
			nop
			nop
			nop
			; nop
			; nop
			; nop
			; nop

.bam1			inc $d020
			jmp .bam1
			endif
;-----------------------			
nmi{1}5			txs			;2+7	line 74
			ldx pointer		;4
			incpointer
			stx $d418		;4
			ldx #<nmi{1}6		;2
			stx $fffa		;4
			ldx #[>[screen-$c000]<<2] | [>[charset0-$c000]>>2]	;2
			bit $dd0d		;4
			nop			;2
			nop			;2
			stx $d018		;4
			ldx nmixreg		;3
			rti			;6
;-----------------------			
nmi{1}6			stx nmixreg		;3+7	line 76
			ldx pointer		;4
			incpointer
			stx $d418		;4
			ldx #<nmi{1}7		;2
			stx $fffa		;4
			if {1}=0
			delay 8
fadeyellow		ldx #$00		;$07 yellow
			stx $d021
			endif
			ldx nmixreg		;3
			jmp $dd0c		;3+6
;-----------------------			
nmi{1}7			stx nmixreg		;3+7	line 78
			ldx pointer		;4
			incpointer
			stx $d418		;4
			ldx #$00		;2
			stx $fffa		;4
			inc $fffb		;6
			ldx nmixreg		;3
			inc $d011		;6
			jmp $dd0c		;3+6
			endif
			
			endm
;-----------------------
pointer			set mixingbuffer+14			
			mac incpointer
pointer			set pointer+1
			endm
;-----------------------			
;{1} = number of nmi routine
;{2} = endflag for last routine

			align 256,0
			nmidouble 00,0
			align 256,0
			nmidouble 01,0
			align 256,0
			nmidouble 02,0
			align 256,0
			nmidouble 03,0
			align 256,0
			nmidouble 04,0
			align 256,0
			nmidouble 05,0
			align 256,0
			nmidouble 06,0
			align 256,0
			nmidouble 07,0
			align 256,0
			nmidouble 08,0
			align 256,0
			nmidouble 09,0
			align 256,0
			nmidouble 10,0
			align 256,0
			nmidouble 11,1
			
;------------------------------------------------------------------------------
;scroll routine
;------------------------------------------------------------------------------
nocopy			jmp doscroll2
doscroll		subroutine
			lda viewportxlo
			and #%00001111
			tay
			ldx copyoffset,y
			cpx #255
			beq nocopy
			lda copyoffset+1,y
			tay
			
;-----------------------
.copy0to1
i			set 0
			repeat copysplit
			lda screen+i+1,x
			sta screen+i,y
			lda screen+i+240+1,x
			sta screen+i+240,y
			lda screen+i+480+1,x
			sta screen+i+480,y
			lda screen+i+720+1,x
			sta screen+i+720,y

			lda colorram+i+1,x
			sta colorram+i,y
			lda colorram+i+240+1,x
			sta colorram+i+240,y
			lda colorram+i+480+1,x
			sta colorram+i+480,y
			lda colorram+i+720+1,x
			sta colorram+i+720,y
			
i			set i+1			
			repend
			rts

copyoffset		dc.b 0,40,80,120,160,200,255,255,40,0,120,80,200,160,255,255
;(xpos+312) / 32 = block offset

nocopy2			jmp fillchars
doscroll2		subroutine
			sec
			sbc #$06
			tay
.next			sty .pointer+1
			
			ldx copyoffset,y
			cpx #255
			beq nocopy2
			lda copyoffset+1,y
			tay

i			set copysplit
			repeat 38-copysplit
			lda screen+i+1,x
			sta screen+i,y
			lda screen+i+240+1,x
			sta screen+i+240,y
			lda screen+i+480+1,x
			sta screen+i+480,y
			lda screen+i+720+1,x
			sta screen+i+720,y

			lda colorram+i+1,x
			sta colorram+i,y
			lda colorram+i+240+1,x
			sta colorram+i+240,y
			lda colorram+i+480+1,x
			sta colorram+i+480,y
			lda colorram+i+720+1,x
			sta colorram+i+720,y
			
i			set i+1			
			repend
			
.pointer		ldy #$00
			iny
			iny
			jmp .next

;00011111 01234567
;      11111012

fillchars		subroutine
			lda viewportxlo
			
			if mapoffsetx>0
			clc
			adc #<mapoffsetx
			sta maplo
			php
			else
			sta maplo
			endif
		
			lsr
			lsr
			lsr
			and #%00000011	;blockpos 0-3
			tax
			
			if mapoffsetx>0
			plp
			lda viewportxhi
			adc #>mapoffsetx
			else
			lda viewportxhi
			endif

			asl maplo
			rol
			asl maplo
			rol
			asl maplo
			rol
			tay		;offset for blockmap
			
test			lda doublebuffer+1
			beq .over
		
			lda .jumptablo,x
			sta .jump+1
			lda .jumptabhi,x
			sta .jump+2
.jump			jmp .jump
			
.over			lda .jumptablo+4,x
			sta .jump2+1
			lda .jumptabhi+4,x
			sta .jump2+2
.jump2			jmp .jump2

			mac fillcol
			ldx blockmap,y
			lda charblock{1},x
			sta screen+38+{3}
			lda charblock{2},x
			sta screen+80+38+{3}
			lda colorblock{1},x
			sta colorram+38+{3}
			lda colorblock{2},x
			sta colorram+80+38+{3}
			
			ldx blockmap+mapsizex/32,y
			lda charblock{1},x
			sta screen+160+38+{3}
			lda charblock{2},x
			sta screen+240+38+{3}
			lda colorblock{1},x
			sta colorram+160+38+{3}
			lda colorblock{2},x
			sta colorram+240+38+{3}
			
			ldx blockmap+mapsizex/32*2,y
			lda charblock{1},x
			sta screen+320+38+{3}
			lda charblock{2},x
			sta screen+400+38+{3}
			lda colorblock{1},x
			sta colorram+320+38+{3}
			lda colorblock{2},x
			sta colorram+400+38+{3}
			
			ldx blockmap+mapsizex/32*3,y
			lda charblock{1},x
			sta screen+480+38+{3}
			lda charblock{2},x
			sta screen+560+38+{3}
			lda colorblock{1},x
			sta colorram+480+38+{3}
			lda colorblock{2},x
			sta colorram+560+38+{3}
			
			ldx blockmap+mapsizex/32*4,y
			lda charblock{1},x
			sta screen+640+38+{3}
			lda charblock{2},x
			sta screen+720+38+{3}
			lda colorblock{1},x
			sta colorram+640+38+{3}
			lda colorblock{2},x
			sta colorram+720+38+{3}

			ldx blockmap+mapsizex/32*5,y
			lda charblock{1},x
			sta screen+800+38+{3}
			lda charblock{2},x
			sta screen+880+38+{3}
			lda colorblock{1},x
			sta colorram+800+38+{3}
			lda colorblock{2},x
			sta colorram+880+38+{3}
			rts
			endm
			
.column0a		fillcol 0,4,0
.column1a		fillcol 1,5,0
.column2a		fillcol 2,6,0
.column3a		fillcol 3,7,0

.column0b		fillcol 0,4,40
.column1b		fillcol 1,5,40
.column2b		fillcol 2,6,40
.column3b		fillcol 3,7,40

.jumptablo		dc.b <.column0a,<.column1a,<.column2a,<.column3a
			dc.b <.column0b,<.column1b,<.column2b,<.column3b
.jumptabhi		dc.b >.column0a,>.column1a,>.column2a,>.column3a
			dc.b >.column0b,>.column1b,>.column2b,>.column3b

;------------------------------------------------------------------------------
;java-replayer-init
;------------------------------------------------------------------------------
;{1}=voice number
;{2]=voice number - 1
			mac initvoice
			if playinterleave=0
			lda sampleslo+{2}
			sta sample{1}datapointer+1
			lda sampleshi+{2}
			sta sample{1}datapointer+2
			stx sample{1}delay+1
			else
			stx sample{1}delay+1
			endif
			
			if thc_chn{1}per=1
			if playinterleave=0
			lda periodslo+{2}	;voice2
			sta period{1}datapointer+1
			lda periodshi+{2}
			sta period{1}datapointer+2
			stx period{1}delay+1
			else
			stx period{1}delay+1
			endif
			endif
			
			if volumesupport=1 & thc_chn{1}vol=1
			if playinterleave=0
			lda volumeslo+{2}
			sta volume{1}datapointer+1
			lda volumeshi+{2}
			sta volume{1}datapointer+2
			stx volume{1}delay+1
			else
			stx volume{1}delay+1
			endif
			endif
			
			if sampleoffsetsupport=1 & thc_chn{1}off=1
			if playinterleave=0
			lda offsetslo+{2}
			sta offset{1}datapointer+1
			lda offsetshi+{2}
			sta offset{1}datapointer+2
			stx offset{1}delay+1
			else
			stx offset{1}delay+1
			endif
			endif
			endm
;-----------------------
javarestart		subroutine
			ldx #$00
.over			
			initvoice 1,0
			if digivoices>1
			initvoice 2,1
			endif
			if digivoices>2
			initvoice 3,2
			endif
			if digivoices>3
			initvoice 4,3
			endif
			if digivoices>4
			initvoice 5,4
			endif
			if digivoices>5
			initvoice 6,5
			endif
			if digivoices>6
			initvoice 7,6
			endif
			if digivoices>7
			initvoice 8,7
			endif

			if playinterleave=1
			if playlzstream=1
			lda #<songdata
			sta lzsfetch1+1
			sta lzsfetch2+1
			sta lzsfetch3+1
			lda #>songdata
			sta lzsfetch1+2
			sta lzsfetch2+2
			sta lzsfetch3+2
			lda #<lzshistory	;always zero
			sta lzsput+1
			sta lzsrepeat+1	;clear index
			sta lzsystart+1
			lda #>lzshistory	;can be removed
			sta lzsput+2
			else
			lda #<songdata
			sta getstream+1
			lda #>songdata
			sta getstream+2
			endif			;playlzstream=1
			endif			;playinterleave=1
			
			if controlchannel=1
			stx controldelay+1
			lda #<controldata
			sta controldatapointer+1
			lda #>controldata
			sta controldatapointer+2
			endif
			
			rts
			
;---------------------------------------
			if playinterleave=1
			if playlzstream=1
lzsgetbyte		subroutine
;y has to start with 0 and needs to be saved between calls
;x will be trashed, but may be used outside safely
;a is decrunched byte
			
lzsrepeat		ldx #$00			;$00 - fetch nextbyte $01-$7f copy literal/match
.branchflag		bne .copymatch			;change relative to copymatch or copyliterals

lzsfetch1
.fetchbyte		lax $beef,y		;if positive -> lz sequence
			bpl .startmatch
			sbx #$c0
			bcs .shortmatch

.startliterals		sbx #$80
			lda #<.copyliterals-.branchflag-2
			sta .branchflag+1
			iny
lzsfetch2
.copyliterals		lda $beef,y
			iny
			jmp lzsput

.shortmatch		ldx #$02
			jmp .copymatchiny

.startmatch		iny

			;calculate adress of lz sequence
lzsfetch3
.overinc3		lda $beef,y
;			beq .end		;end check can be removed for modplayer
			clc
.copymatchiny		adc lzsput+1
			sta .copymatch+1

			lda #<.copymatch-.branchflag-2
			sta .branchflag+1
			iny

.copymatch		lda lzshistory
			inc .copymatch+1
lzsput			sta lzshistory
			inc lzsput+1
			dex
			stx lzsrepeat+1
			rts

;.end			inc endflag+1
;			rts

			else	;playlzstream=0
			
lzsgetbyte		subroutine
getstream		lda songdata
			inc getstream+1
			bne .exit
			inc getstream+2
.exit			rts
			endif	;playlzstream=1
			endif	;playinterleave=1
;---------------------------------------
;---------------------------------------
;mixing routine
;bcs springt wenn 1. wert größer oder gleich
;bcc springt wenn 1. wert kleiner ist

;wenn voiceactive=0 spiele silentbuffer
;wenn voiceactive=1 prüfe ob neue note getriggered wurde bzw. spiele alt note weiter
;
;------------------------------------------------------------------------------
;mixer macros
;{1}=voice number
;{2]=0 - volume off 1=volume on
;{3}=0 - period always 453 1 - periods on
;{4}=0 - sampleoffset off  1 - sampleoffset on

;------------------------------------------------------------------------------
			mac mixvoice
			if {3}=1	;period on
period{1}delay		lda #$00
			bne .exitperioddelay

			if playinterleave=0
period{1}datapointer	lax $1000
			else
			jsr lzsgetbyte
			tax
			endif
			
			bmi .setperioddelay

			if {1}=1
			cmp #$7f
			beq .endofsong
			endif

			sta note{1}+1
			lda notestablelo,x
			sta notefetch{1}+1
			lda notestablehi,x
			sta notefetch{1}+2
			
			if playinterleave=0
			inc period{1}datapointer+1
			bne .volumedepack
			inc period{1}datapointer+2
			bne .volumedepack
			else
			jmp .volumedepack
			endif
			
			if {1}=1
.endofsong		lda #$60
			sta thcplay
			rts
			endif			;{1}=1

.setperioddelay		and #%01111111
;			sec
;			sbc #$01
			sta period{1}delay+1
			
			if playinterleave=0
			inc period{1}datapointer+1
			bne .volumedepack
			inc period{1}datapointer+2
			bne .volumedepack
			else
			jmp .volumedepack
			endif
			
.exitperioddelay	dec period{1}delay+1

			endif	;{3}=1	period on
.volumedepack		
;------------------------------------------------------------------------------
			if {2}=1
volume{1}delay		lda #$00
			bne .exitvolumedelay
			
			if playinterleave=0
volume{1}datapointer	lax $1000
			else
			jsr lzsgetbyte
			tax
			endif	
			
			if rleimproved=1
			bpl .setvolume
			else
			bpl .setvolume3
			endif

			and #%01111111
			sta volume{1}delay+1

			if playinterleave=0
			inc volume{1}datapointer+1
			bne .offsetdepack
			inc volume{1}datapointer+2
			bne .offsetdepack
			else
			jmp .offsetdepack
			endif
			
			if rleimproved=1
prev{1}volume1		dc.b $00
prev{1}volume2		dc.b $00
prev{1}volume3		dc.b $00
		
.setvolume		and #%01100000
			beq .setvolume2
			asl
			asl
			rol
			rol
			stx .xsave1+1
			tax
			lda prev{1}volume1-1,x
			sta .storevolume+1
.xsave1			ldx #$00
			inx
			lda #%00011111
			sax volume{1}delay+1
			jmp .storevolume
			
.setvolume2		lda prev{1}volume2
			sta prev{1}volume3
			lda prev{1}volume1
			sta prev{1}volume2
			stx prev{1}volume1
			stx .storevolume+1

.storevolume		lda #$00
			endif			;rleimproved=1
			
.setvolume3		clc
			adc #>volumetable
			sta mix{1}a+2
			sta mix{1}b+2
			sta mix{1}c+2
			sta mix{1}d+2
			if replayrate>0
			sta mix{1}e+2
			sta mix{1}f+2
			endif
			if replayrate>1
			sta mix{1}g+2
			sta mix{1}h+2
			endif

			if playinterleave=0
			inc volume{1}datapointer+1
			bne .offsetdepack
			inc volume{1}datapointer+2
			bne .offsetdepack
			else
			jmp .offsetdepack
			endif
			
.exitvolumedelay	dec volume{1}delay+1

			endif	;{2]=1
;------------------------------------------------------------------------------
.offsetdepack		if sampleoffsetsupport=1
			if {4}=1
			lda #$00
			sta offsethi{1}+1
			sta offsetlo{1}+1

offset{1}delay		lda #$00
			bne .exitoffsetdelay
			if playinterleave=0
offset{1}datapointer	lda $1000
			else
			jsr lzsgetbyte
			tax
			endif
			
			bpl .setoffset

			and #%01111111
;			sec
;			sbc #$01
			sta offset{1}delay+1

			if playinterleave=0
			inc offset{1}datapointer+1
			bne .sampledepack
			inc offset{1}datapointer+2
			bne .sampledepack
			else
			jmp .sampledepack
			endif
			
.setoffset		sta offsethi{1}+1
			
			if playinterleave=0
			lda offset{1}datapointer+1
			sta goatlo
			lda offset{1}datapointer+2
			sta goathi
			
			ldy #$01
			lda (goatlo),y
			else
			jsr lzsgetbyte
			endif
			
			sta offsetlo{1}+1
			
			if playinterleave=0
			lda offset{1}datapointer+1
			clc
			adc #$02
			sta offset{1}datapointer+1
			bcc .sampledepack
			inc offset{1}datapointer+2
			bne .sampledepack
			else
			jmp .sampledepack
			endif
			
.exitoffsetdelay	dec offset{1}delay+1
			endif	;{4}=1
			endif	;sampleoffsetsupport=1
;------------------------------------------------------------------------------
.sampledepack
sample{1}delay		lda #$00
			if rleimproved=1
			beq preserve{1}sample
			else
			beq sample{1}datapointer
			endif
			
			dec sample{1}delay+1
			jmp .nonewnote

			if rleimproved=1
prev{1}sample1		dc.b $00
prev{1}sample2		dc.b $00
prev{1}sample3		dc.b $00
			
preserve{1}sample	lda #$00
			beq sample{1}datapointer
			ldx #$00
			stx preserve{1}sample+1
			jmp .storesample
			endif
			
			if playinterleave=0
sample{1}datapointer	lax $1000
			else
sample{1}datapointer	jsr lzsgetbyte
			tax
			endif
			
			if rleimproved=1
			bpl .triggersample
			else
			bpl .setsample
			endif
						
			and #%01111111
			sta sample{1}delay+1
			
			if rleimproved=1
			jmp .zeroinc2

.triggersample		and #%01100000
			beq .setsample
			asl
			asl
			rol
			rol
			stx .xsave2+1
			tax
			lda prev{1}sample1-1,x
			sta preserve{1}sample+1
.xsave2			ldx #$00
			lda #%00011111
			sax sample{1}delay+1
			endif				;rleimproved=1
			
.zeroinc2		if playinterleave=0
			inc sample{1}datapointer+1
			bne .nonewnote
			inc sample{1}datapointer+2
			bne .nonewnote
			else
			jmp .nonewnote
			endif				;playinterleave=0
			
.setsample		if rleimproved=1
			txa
			endif
			
			if playinterleave=0
			inc sample{1}datapointer+1
			bne .noinc2
			inc sample{1}datapointer+2
			endif
			
.noinc2			if rleimproved=1
			ldx prev{1}sample2
			stx prev{1}sample3
			ldx prev{1}sample1
			stx prev{1}sample2
			sta prev{1}sample1
			endif

.storesample		sta sound{1}+1
			tax
			
; ;------------------------------------------------------------------------------

			if sampleoffsetsupport=1
			
			if {4}=1
			lda samplestartlo,x
			clc
offsetlo{1}		adc #$00			
			sta samplefetch{1}a+1
			lda samplestarthi,x
offsethi{1}		adc #$00
			sta samplefetch{1}a+2
			else
			lda samplestarthi,x
			sta samplefetch{1}a+2
			lda samplestartlo,x
			sta samplefetch{1}a+1
			endif	;{4}=1
			
			else	;sampleoffset=0

			lda samplestarthi,x
			sta samplefetch{1}a+2
			lda samplestartlo,x
			sta samplefetch{1}a+1

			endif	;sampleoffset=1
			
			if playlzstream=1
			sty lzsysave{1}+1
			endif
			lda loopposhi,x
			beq .noloop2

			if {3}=1
			lda #$00
			sta sample{1}frac
			endif
			lda #$ff
			sta voice{1}active
			jmp .preppart2

.noloop2		if {3}=1
			sta sample{1}frac
			endif
			lda #$01
			sta voice{1}active
			jmp .preppart2
			
.nonewnote		if playlzstream=1
			sty lzsysave{1}+1
			endif
			ldx voice{1}active
			bne .preppart1

.stopvoice1		lda #>silentbuffer
			stx samplefetch{1}a+1
			sta samplefetch{1}a+2
.stopvoice2		stx samplefetch{1}b+1
			sta samplefetch{1}b+2
.stopvoice3		stx samplefetch{1}c+1
			sta samplefetch{1}c+2
.stopvoice4		stx samplefetch{1}d+1
			sta samplefetch{1}d+2
			if replayrate>0
.stopvoice5		stx samplefetch{1}e+1
			sta samplefetch{1}e+2
.stopvoice6		stx samplefetch{1}f+1
			sta samplefetch{1}f+2
			endif	;replayrate=0
			if replayrate>1
.stopvoice7		stx samplefetch{1}g+1
			sta samplefetch{1}g+2
.stopvoice8		stx samplefetch{1}h+1
			sta samplefetch{1}h+2
			endif
			stx voice{1}active
			jmp .nextvoice
		
.preppart1
sound{1}		ldy #$00
			
			if {3}=1
note{1}			ldx #$00			
			lda sample{1}frac
			clc
			adc notesaddfrac,x
			sta sample{1}frac
			
			if replayrate=0
			lda samplefetch{1}d+1
			adc notesaddlo,x
			sta samplefetch{1}a+1
			lda samplefetch{1}d+2
			adc #$00
			sta samplefetch{1}a+2
			endif
			
			if replayrate=1
			lda samplefetch{1}f+1
			adc notesaddlo,x
			sta samplefetch{1}a+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}a+2
			endif

			if replayrate=2
			lda samplefetch{1}h+1
			adc notesaddlo,x
			sta samplefetch{1}a+1
			lda samplefetch{1}h+2
			adc #$00
			sta samplefetch{1}a+2
			endif
			
			else	;{3}=0

			if replayrate=0
			lda samplefetch{1}d+1
			clc
			adc #periodsteplength
			sta samplefetch{1}a+1
			lda samplefetch{1}d+2
			adc #$00
			sta samplefetch{1}a+2
			endif
			if replayrate=1
			lda samplefetch{1}f+1
			clc
			adc #periodsteplength
			sta samplefetch{1}a+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}a+2
			endif
			if replayrate=2
			lda samplefetch{1}h+1
			clc
			adc #periodsteplength
			sta samplefetch{1}a+1
			lda samplefetch{1}h+2
			adc #$00
			sta samplefetch{1}a+2
			endif
			endif	;{3}=0
			
			lda samplefetch{1}a+1
			cmp sampleendlo,y
			lda samplefetch{1}a+2
			sbc sampleendhi,y
			bcc .preppart2

.checkloop1		lda voice{1}active
			bmi .loop1

			ldx #$00
			jmp .stopvoice1
		
.loop1			lda samplefetch{1}a+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}a+1
			lda samplefetch{1}a+2
			sbc looplengthhi,y
			sta samplefetch{1}a+2
			clc
			
.preppart2		ldy sound{1}+1

			if {3}=1
			ldx note{1}+1

			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac
					
			lda samplefetch{1}a+1
			adc notesaddlo,x
			sta samplefetch{1}b+1
			lda samplefetch{1}a+2
			adc #$00
			sta samplefetch{1}b+2

			else	;{3}=0

			lda samplefetch{1}a+1	;always playing period 453
			adc #periodsteplength
			sta samplefetch{1}b+1
			lda samplefetch{1}a+2
			adc #$00
			sta samplefetch{1}b+2
			endif	;{3}=0
			
			lda samplefetch{1}b+1
			cmp sampleendlo,y
			lda samplefetch{1}b+2
			sbc sampleendhi,y
			bcc .preppart3

.checkloop2		lda voice{1}active
			bmi .loop2

			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice2

.loop2			lda samplefetch{1}b+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}b+1
			lda samplefetch{1}b+2
			sbc looplengthhi,y
			sta samplefetch{1}b+2
			clc
			
;------------------------------------------------------------------------------
.preppart3		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}b+1
			adc notesaddlo,x
			sta samplefetch{1}c+1
			lda samplefetch{1}b+2
			adc #$00
			sta samplefetch{1}c+2

			else	;{3}=0

			lda samplefetch{1}b+1
			adc #periodsteplength
			sta samplefetch{1}c+1
			lda samplefetch{1}b+2
			adc #$00
			sta samplefetch{1}c+2
			endif	;{3}=0
			
			lda samplefetch{1}c+1
			cmp sampleendlo,y
			lda samplefetch{1}c+2
			sbc sampleendhi,y
			bcc .preppart4

.checkloop3		lda voice{1}active
			bmi .loop3

			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice3

.loop3			lda samplefetch{1}c+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}c+1
			lda samplefetch{1}c+2
			sbc looplengthhi,y
			sta samplefetch{1}c+2
			clc
;------------------------------------------------------------------------------
.preppart4		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}c+1
			adc notesaddlo,x
			sta samplefetch{1}d+1
			lda samplefetch{1}c+2
			adc #$00
			sta samplefetch{1}d+2

			else	;{3}=0

			lda samplefetch{1}c+1
			adc #periodsteplength
			sta samplefetch{1}d+1
			lda samplefetch{1}c+2
			adc #$00
			sta samplefetch{1}d+2
			endif	;{3}=0
			
			lda samplefetch{1}d+1
			cmp sampleendlo,y
			lda samplefetch{1}d+2
			sbc sampleendhi,y
			
			if replayrate>0
			bcc .preppart5
			else
			bcc .nextvoice
			endif
			
			lda voice{1}active
			bmi .loop4

			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice4

.loop4			lda samplefetch{1}d+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}d+1
			lda samplefetch{1}d+2
			sbc looplengthhi,y
			sta samplefetch{1}d+2

.nextvoice		if playlzstream=1
lzsysave{1}		if digivoices={1}
			lda #$00		;last channel usa akku to save 2 cycles
			else
			ldy #$00
			endif			;digivoices={1}
			endif			;playlzstream=1
			endm
;------------------------------------------------------------------------------
thcplay			subroutine
;------------------------------------------------------------------------------
;{1}=voice number
;{2]=0 - volume off 1=volume on
;{3}=0 - period always 453 1 - periods on
;{4}=0 - sampleoffset off  1 - sampleoffset on
;------------------------------------------------------------------------------
;selector code
;------------------------------------------------------------------------------
			; jsr checkkeyboard
			; beq .noeffect
			; sta soundeffect3+1
.noeffect			
			if controlchannel=1
			getcontrol
			endif

mixrestart		if playlzstream=1
lzsystart		ldy #$00		;always start clean
			endif

			mixvoice 1,thc_chn1vol,thc_chn1per,thc_chn1off
			if digivoices>1
			mixvoice 2,thc_chn2vol,thc_chn2per,thc_chn2off
			endif
			if digivoices>2
			mixvoice 3,thc_chn3vol,thc_chn3per,thc_chn3off
			endif
			if digivoices>3
			mixvoice 4,thc_chn4vol,thc_chn4per,thc_chn4off
			endif
			if digivoices>4
			mixvoice 5,thc_chn5vol,thc_chn5per,thc_chn5off
			endif
			if digivoices>5
			mixvoice 6,thc_chn6vol,thc_chn6per,thc_chn6off
			endif
			if digivoices>6
			mixvoice 7,thc_chn7vol,thc_chn7per,thc_chn7off
			endif
			if digivoices>7
			mixvoice 8,thc_chn8vol,thc_chn8per,thc_chn8off
			endif

			if playlzstream=1
			bpl .noadd		;last opcode before 	lzsysave{1}	ldy #$00
			clc
			adc lzsfetch1+1
			sta lzsfetch1+1
			sta lzsfetch2+1
			sta lzsfetch3+1
			bcc .noinc
			inc lzsfetch1+2
			inc lzsfetch2+2
			inc lzsfetch3+2
.noinc			lda #$00
.noadd			sta lzsystart+1
			endif
			
			rts
			
			
;------------------------------------------------------------------------------
;modfile - protracker module
;------------------------------------------------------------------------------
			echo "Samplestart: ",*
			include "thc_samples.asm"

			echo "Songstart: ",*
			
			if playinterleave=0
			include "thc_header00.asm"
			include "thc_song00.asm"
			else
			
songdata		if playlzstream=1
			incbin "thc_stream.lzs"
			else
			incbin "thc_stream.rle"
			endif
			endif
songdataend	
			if controlchannel=1
			include "thc_control.asm"		
			endif
			
;------------------------------------------------------------------------------
;map data
;------------------------------------------------------------------------------
			align 256,0
charblock0
 hex 000000001A232426 2A24003000303000 360024243C3E3B3D 3E3F00003E242500 006700000800266B 3D00000030646473 007778003D7F8183 850000888CA6AA00
 hex AE613E9D000000AF 00AAB18181B3B7B8 007FBA000003033D 030303BB3ED403B8 8385D96803303DB1 030300000303EDDF BB68F40303030000 0000000000000000

charblock1
 hex 000000181B242427 2B252D312D33342D 373924243D40243E 3D3F42443D242426 003D00000906696C 6E00104231717174 00787B7E41808078 860000898DA7AB00
 hex 863F3F9E000000B0 00ABB28080B42AB9 00803D0000020241 020202BC3DD502B9 7886DA3F39313EB2 0202000002027AF0 BC3DF50202020000 0000000000000000

charblock2
 hex 000000191C252428 2C242E322E003235 383A24243E3F243D 3D3E43453F242329 003E00680A076A6D 6F00115532727275 00797C0400818184 8700008A8EA8AC00
 hex 7C403D009D0000AF 00AC818181B560B8 00813E0303036803 030303BD3DD6B803 84D8DB403A323D81 000003030303EEF1 BD3DF60300000000 0000000000000000

charblock3
 hex 0000001A00242429 2A232F002F000000 002F243B3F41243D 413F2F4641240000 003D003D0B00293D 7000120000000076 007A7D050080827C 7D00008B2AA9AD00
 hex 863D41009E1700B0 00AD808082B661B9 00803D0202023D02 020202BED3D7B902 7C7DDC412F023D80 000002020202EFF2 BEF3F70200000000 0000000000000000

charblock4
 hex 00001D1D20004748 4C25005100515300 5100475B5D5F5B5E 5F6000005F472300 008F5B680C90488F 5E41000050000096 730000995E9A8100 7A9D5A9FA3BBBFA6
 hex 9AC55FB89D907360 5BC8CCCDCDCE9A03 5B9A8F030303685E DDDDA6BB5FE20303 037AE65D03505EEB 0000030303DDF8FA 035DFC0303000000 0000000000000000

charblock5
 hex 00001D1E21004749 4D23425142525442 5658475C5E5E625F 5E6064425E470048 005E623D0D914D5E 5E00139550959597 7400009161808000 9C9E5BA0A4BCC0A7
 hex C36060B99E9174C7 5CC9CDCDCD2A4C02 5BCD5E0202023D61 DEDEA7BC5EE30202 029CE76064505FEC 0000020202DEF9FB 025EFD0202000000 0000000000000000

charblock6
 hex 001D1D1F2223474A 4E004F524F005255 57595A5A5F60475E 5E5F65666047004B 5A5F005D0E924E94 5E00145252525296 730000923F81819B 009D5BA1A5BDC1A8
 hex C45E609DB8927360 5ACACDCDCDCFD103 5BCD5F0000035D3F DFDFA8BD5EE40303 9B03E85EEA525E81 0303000003DF4CDF 035EFE0003030000 0000000000000000

charblock7
 hex 001D1D201D25474B 4C00500051000000 00505B5B6061475E 6360515163250000 5B5E005E0F934B5E 6300150000001698 7400009341809A7A 009E5CA24CBEC2A9
 hex 9A5E619EB9C67460 5BCBCDCD9AD0D202 5BCD5E0000025E41 E0E1A9BE63E50202 7A02E96150025E80 0202000002E0C4F0 0263FF0002020000 0000000000000000

colorblock0
 hex 000000000F070709 0A07000900090F00 090007070D0D070F 0F0D00000D070700 000F000001000909 0F0000000F080809 000D0D000F0E0A0D 0D00000D09090D00
 hex 0F0D0D0900000009 000D0E0A0A0D0D0F 000E0800000D0D0F 0D0D0D090F0E0D0F 0D0D0E0D0D0F0F0E 0D0D000009090F09 090D0E09090F0000 0000000000000000

colorblock1
 hex 0000000F0F070709 0907090F090D0F09 0D090707090F070F 0F0D0F0D09070709 000900000901010F 0900090D0F09090D 000D0F0F0D0A0A0D 0D00000D0F090D00
 hex 0D0D0D0F0000000D 000D0D0A0A0D0A08 000A0900000D0D0D 0D0D0D0F0F0E0D08 0D0D0E0D090F0F0D 0D0D000009090D09 0F090E09090F0000 0000000000000000

colorblock2
 hex 0000000F0F070709 09070D090D000F0D 0D0D07070D0D0709 0F0D0D0D0D070709 000F000D01010909 0F00090D0F0D0D09 000F0D09000A0A0F 0D00000D0F0F0E00
 hex 0D0F0A0009000009 000E0A0A0A0D0D0F 000A0F0D0D0D0D0F 0D0D0D0F0F0E0F0D 0F0D0E0F0D090F0A 00000F0909090D09 0F0F0E0900000000 0000000000000000

colorblock3
 hex 0000000F00070709 0A0709000F000000 000F07070D0D070F 0D0D0F090D070000 000F00090900090F 0900090000000008 000D0D0F000A0E0D 0D00000D0A0F0E00
 hex 0D090D000F09000D 000E0A0A0E0F0D08 000A0F0D0D0D090F 0D0D0D0F080E080D 0D0D0E0D0F0D0F0A 00000F0909090D0F 0F0D0E0900000000 0000000000000000

colorblock4
 hex 000007070F00070F 0E07000D000D0900 0D00070F0D0D0F0F 0F0D00000D070700 00080F0D090D0F08 0F0D000008000009 0900000D0F0E0A00 0D09090808090909
 hex 0E0D0D0F090D090D 0F0D0E0E0E0D0E0F 090E080D0F0F0D0F 090909090F0E0F0F 0F0D0E0D0F080F0E 00000F0909090E09 090D0E0909000000 0000000000000000

colorblock5
 hex 0000070F0F00070F 0F070F0D0F090D0F 0909070D0F0F0D0F 0F0D080F0F07000F 000F0D0F090F0F0F 0900090D080D0D0A 0C00000F0D0A0A00 0D0F0F0D0F0F0F09
 hex 0A0D0D080F0F0D0D 0D0D0E0A0A0A0E0F 0F0A0F0D0F0F0F0D 0F0F090F0F0E0F0F 0F0D0E0D08080F0A 00000F09090F0E0F 090F0E0909000000 0000000000000000

colorblock6
 hex 0007070F0F07070F 090009090900090F 090D09090D0D070F 0F0D0F0D0D07000F 090F000D0F0E0909 0F00090909090909 0900000E0D0A0A0D 00090F080F0F0F0F
 hex 0C0F0D090F0E090D 090D0A0E0E0D0E0F 090E0F00000F0D0D 09090F0F0F0E0F0F 0D0F0E0F0F0F0F0A 0F0D000009090E09 090F0E00090F0000 0000000000000000

colorblock7
 hex 0007070F07070709 0E0008000D000000 00080F0F0D0D070F 080D0D0D08070000 0F0F000F0F0E090F 080009000000090E 0D00000E0D0A0E0D 000F0D0D0E0F0F0F
 hex 0E0F0D0F080D0C0D 0F0D0E0A0E0C0D0F 0F0A0F00000F0F0D 09090F0F080E0F0F 0D0F0E0D080F0F0A 0F0D000009090C09 09080E00090F0000 0000000000000000

blockmap
 hex 0001020202020202 0202020202020202 0202020202020202 0202020202020202 0202020202020202 0202020202020202 0202020202020202 0304030403040304
 hex 0304030403040203 0403040304020202 0202020202020202 0202020202020202 0202020202020202 0202020202020202 0202020202020202 0202020202020202
 hex 0202020203040202 0202030402020202 0202020202020202 0202020202020202 0202020202020202 0202020202020202 0202020202000000 0000000000000000
 hex 0000050606060606 0606060606060606 0606060606060606 0606060606060607 0807060606060606 0606060606060606 0606060606060609 0A0B0C0D0C0E0C0D
 hex 0F0F0C0E0F0C100C 0D0C0E1110050606 0606060606060606 1213141516060607 0606060606061417 1806060606060606 0606141919150606 0606060606060606
 hex 06060609001A1005 091B0B0005061213 1415160606060606 0606060606141C14 1915060606060606 0606060606060606 0606061D1E000000 0000000000000000
 hex 0000000000000000 001F071F00000000 2021182200002315 2200240000002500 2600202728220000 2400000023152200 231C1415292A0000 2B001A2C2B2D2B00
 hex 1A0B2B2E2B2B2B1A 2C2B2D1A2C000000 002F300000240024 0000313200003300 0023193400203526 3622002400233400 0000370808380023 2839392728000024
 hex 0000001F07001A10 1B2C00071F000000 3132002319283A27 1C0024002735363B 3C38000000000000 2400000000330000 0000000000000000 0000000000000000
 hex 0000000000000033 0000000000000024 2008082224003132 00003D0000003E00 0000003132002A00 3F00000031320000 37403C4041424339 394414192829302A
 hex 0000004500070000 4600201415433944 14474715223F003F 00003F2048144934 00373C3800004A4B 4C00003F204D4E22 212822002500204A 4C4F4F4D3C205014
 hex 152200001B101B2C 1A101B1000002400 3F00274D403C404D 38003F0037513C38 5228000000002400 3D00000023491500 0000000000000000 0000000000000000
 hex 0000535454555649 575555585959593D 55514C553D555555 5A555B555A555B55 5555561919194255 5B55561919195755 2717175C5D3C5E4F 4F5F60403C414742
 hex 5555553E55555514 471555514C5E4F5F 513C514C595B595B 59555B5514195C61 555A552317175C62 5217155B55626255 4A3C55553E555562 6255145C62555560
 hex 6155555963646555 5564656359553D55 5B55603C52665C61 55595B215C525C59 6708212859593D55 5B555555603C6155 5568686900000000 0000000000000000
 hex 00536A6B6C6D4D6E 4E6D6F6F6F6F6F6F 6D6D6C6C6C6D6D6C 706C6C6C706C6C6C 6C716E6E3C6E616C 706C603C40724E57 600808616C211728 6C27175C525C0861
 hex 6C3D6C706C3D6C70 70706C6D21286D27 175C52175C6F6F6F 6F6D706C603C616D 6D706C603C40616C 604061706C6C2717 5C4C6C6C706D3D6D 3D6D60616C6C3D6D
 hex 6D3D6F6F4B6D6C6C 6C6C6D4B6F6F5B6D 6D6C6C6C4A084C3D 6D6C6D4A084B4C6D 6C6D4A4C6F6F5B59 5927286C6C6C6C6C 6C73747569000000 0000000000000000


			align 256,0
animframe		dc.w frame0
			dc.w frame1
			dc.w frame2
			dc.w frame3



spritemap		incbin "gfx/handles.map"
spritemapend

fadetowhite		dc.b $00,$06,$09,$02,$0b,$04,$08,$0c,$0e,$05,$0a,$03,$0f,$07,$0d,$01
fadetoblue		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$06
fadetopurple		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$09,$02,$04,$0b,$04
fadetocyan		dc.b $00,$00,$00,$00,$06,$09,$02,$0b,$04,$08,$0c,$0e,$05,$03,$0a,$03
fadetolightblue		dc.b $00,$00,$00,$00,$00,$00,$00,$06,$09,$02,$0b,$04,$08,$0e,$0c,$0e
fadetolightred		dc.b $00,$00,$00,$00,$00,$06,$09,$02,$0b,$04,$08,$0c,$0e,$0a,$05,$0a
fadetoyellow		dc.b $00,$00,$06,$09,$02,$0b,$04,$08,$0c,$0e,$05,$0a,$03,$07,$0f,$07

department		hex 03 00000000 00000001 01010101 01010102 02020202

; spritemc1		hex 0a0f0e09 050e0504 0a0f0e09 050e0504 0a0f0e09 050e0a
; spritemc2		hex 01010101 010d0107 01010101 010d0107 01010101 010d01
				                                             
; spritecol		hex 070d030d 0d030d03 070d030d 0d030d03 070d030d 0d0307

spritemc1		hex 020b0609 0b060b04 02050609 05060404 0a020609 0b060a
spritemc2		hex 0f010101 010d0107 07010101 010d0707 01070101 010d01
				                                            
spritecol		hex 0a05030d 05030503 0a03030d 0d030a03 070a030d 05030f

;spritemc1		hex 04090b0c 0c060809 08020e04 090b040c 06080908 020e
;spritemc2		hex 01010101 01010701 0d070101 01010101 0107010d 0701 
									 
;spritecol		hex 070d0f04 0d030f07 0e0a0307 0d0f030d 030f070e 0a03

;handle
spe_dataxlo0
 dc.b $5C,$59,$57,$53,$4F,$4B,$47,$43,$3E,$39,$34,$2F,$29,$24,$1E,$19,$13,$0E,$09,$03,$FE,$FA,$F5,$F0,$EC,$E8,$E4,$E1,$DD,$D9,$D5,$D2,$CE,$CB,$C7,$C4,$C0,$BD,$BA,$B6,$B3,$B0,$AD,$AA,$A6,$A3,$A0,$9D
 dc.b $9A,$97,$94,$91,$8E,$8B,$88,$85,$83,$80,$7D,$7A,$77,$75,$72,$6F,$6D,$6A,$67,$64,$62,$5F,$5C,$59,$57,$54,$51,$4E,$4B,$49,$46,$43,$40,$3E,$3B,$38,$35,$33,$30,$2D,$2A,$27,$24,$21,$1E,$1B,$18,$15
 dc.b $12,$0F,$0C,$08,$05,$02,$FF,$FC,$F8,$F5,$F2,$EE,$EB,$E8,$E4,$E1,$DD,$DA,$D6,$D2,$CE,$CB,$C7,$C3,$BF,$BA,$B6,$B1,$AC,$A7,$A1,$9C,$97,$91,$8C,$86,$81,$7C,$77,$72,$6D,$69,$64,$60,$5D,$59,$57,$54
 
spe_dataxhi0
 dc.b $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 dc.b $00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
 
spe_dataylo0
 dc.b $EE,$ED,$EC,$EB,$E9,$E8,$E6,$E4,$E3,$E1,$DF,$DD,$DB,$D9,$D7,$D5,$D3,$D1,$CF,$CD,$CC,$CA,$C8,$C7,$C6,$C5,$C4,$C3,$C2,$C1,$C0,$BF,$BE,$BE,$BD,$BC,$BC,$BB,$BA,$BA,$B9,$B9,$B8,$B8,$B8,$B7,$B7,$B6
 dc.b $B6,$B5,$B5,$B5,$B4,$B4,$B4,$B4,$B3,$B3,$B3,$B3,$B3,$B3,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B2,$B3,$B3,$B3,$B3,$B3,$B3,$B4,$B4,$B4,$B4,$B5,$B5,$B5,$B6
 dc.b $B6,$B7,$B7,$B8,$B8,$B8,$B9,$B9,$BA,$BA,$BB,$BC,$BC,$BD,$BE,$BE,$BF,$C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$CA,$CC,$CD,$CF,$D1,$D3,$D5,$D7,$D9,$DB,$DD,$DF,$E1,$E3,$E4,$E6,$E8,$E9,$EB,$EC,$ED,$EE
 
;department
; spe_dataxlo1
 ; dc.b $5C,$59,$57,$53,$4F,$4B,$47,$43,$3E,$39,$34,$2F,$29,$24,$1E,$19,$13,$0E,$09,$03,$FE,$FA,$F5,$F0,$EC,$E8,$E4,$E1,$DD,$D9,$D5,$D2,$CE,$CB,$C7,$C4,$C0,$BD,$BA,$B6,$B3,$B0,$AD,$AA,$A6,$A3,$A0,$9D
 ; dc.b $9A,$97,$94,$91,$8E,$8B,$88,$85,$83,$80,$7D,$7A,$77,$75,$72,$6F,$6D,$6A,$67,$64,$62,$5F,$5C,$59,$57,$54,$51,$4E,$4B,$49,$46,$43,$40,$3E,$3B,$38,$35,$33,$30,$2D,$2A,$27,$24,$21,$1E,$1B,$18,$15
 ; dc.b $12,$0F,$0C,$08,$05,$02,$FF,$FC,$F8,$F5,$F2,$EE,$EB,$E8,$E4,$E1,$DD,$DA,$D6,$D2,$CE,$CB,$C7,$C3,$BF,$BA,$B6,$B1,$AC,$A7,$A1,$9C,$97,$91,$8C,$86,$81,$7C,$77,$72,$6D,$69,$64,$60,$5D,$59,$57,$54
 
; spe_dataxhi1
 ; dc.b $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 ; dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 ; dc.b $00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
 
; spe_dataylo1
 ; dc.b $5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D
 ; dc.b $5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D
 ; dc.b $5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D
 

spe_xstart2	equ -172+24		;added by hand
spe_ystart2	equ 123
spe_numcoords2	equ 144

;plane fly in
spe_datax2
 dc.b $00,$01,$01,$02,$01,$02,$02,$02,$02,$02,$02,$02,$03,$02,$02,$03,$02,$03,$02,$02,$03,$02,$02,$02,$02,$02,$02,$03,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$03,$02,$02,$02
 dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01
 dc.b $02,$02,$02,$01,$02,$02,$01,$02,$01,$02,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$01,$02,$01,$02,$01,$02,$01,$02,$01,$01,$02,$01,$02,$01,$02,$01,$01,$01,$02,$01,$01,$01,$01,$01,$00,$01
 dc.b $80

spe_datay2
 dc.b $00,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00
 dc.b $00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00
 dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$00,$00,$FF,$00,$00
 dc.b $80

spe_xstart3	equ 88
spe_ystart3	equ 118
spe_numcoords3	equ 144

;plane loop
spe_datax3
 dc.b $00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00
 dc.b $00,$00,$00,$00,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$00,$FF,$00,$00,$FF
 dc.b $00,$FF,$00,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$01,$00
 dc.b $80

spe_datay3
 dc.b $00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$01,$00,$01,$00,$00,$01
 dc.b $00,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00
 dc.b $00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00
 dc.b $80
 
spe_xstart4	equ 88
spe_ystart4	equ 118
spe_numcoords4	equ 144

;plane fly out

spe_datax4
 dc.b $00,$01,$01,$01,$01,$01,$02,$01,$02,$01,$02,$01,$02,$02,$02,$01,$02,$02,$02,$01,$02,$02,$01,$02,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$01,$02,$01,$01,$01,$02,$01,$01,$02,$01,$01
 dc.b $01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$02
 dc.b $01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$01,$02,$01,$02,$01,$01,$02,$01,$02,$01,$01,$02,$01,$02,$01,$02,$01,$02,$02,$02,$01,$02,$02,$02,$02,$01,$02,$02,$02,$01,$02,$01,$02,$01,$01,$01,$01,$01
 dc.b $80

spe_datay4
 dc.b $00,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00
 dc.b $00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00
 dc.b $00,$00,$00,$00,$01,$00,$00,$00,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00
 dc.b $80

spriteline0		incbin "gfx/clouds.map",0,16
			incbin "gfx/clouds.map",0,16
spriteline1		incbin "gfx/clouds.map",16,16
			incbin "gfx/clouds.map",16,16


			align 256,0
;-----------------------
;Wasser links
charanim0		
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512,16
i			set i+1
			repend

;Wasser rechts
charanim1
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16,16
i			set i+1
			repend
;-----------------------
;Fackel links
charanim2
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*2,16
i			set i+1
			repend
;Fackel rechts
charanim3
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*3,16
i			set i+1
			repend
;-----------------------
;Denk links
charanim4
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*4,16
i			set i+1
			repend

;Denk rechts
charanim5
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*5,16
i			set i+1
			repend
;-----------------------
;disc oben 0
charanim6
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*6,16
i			set i+1
			repend

;disc oben 1
charanim7
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*7,16
i			set i+1
			repend

;disc oben 2
charanim8
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*8,16
i			set i+1
			repend

;disc oben 3
charanim9
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*9,16
i			set i+1
			repend

;disc unten 0
charanim10
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*10,16
i			set i+1
			repend

;disc unten 1
charanim11
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*11,16
i			set i+1
			repend

;disc unten 2
charanim12
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*12,16
i			set i+1
			repend

;disc unten 3
charanim13
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*13,16
i			set i+1
			repend

;-----------------------
;ball oben 0
charanim14
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*14,16
i			set i+1
			repend

;ball oben 1
charanim15
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*15,16
i			set i+1
			repend

;ball oben 2
charanim16
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*16,16
i			set i+1
			repend

;ball unten 0
charanim17
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*17,16
i			set i+1
			repend

;ball unten 1
charanim18
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*18,16
i			set i+1
			repend

;ball unten 2
charanim19
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*19,16
i			set i+1
			repend
;-----------------------
;skull top
charanim20
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*20,16
i			set i+1
			repend
;skull bottom
charanim21
i			set 0
			repeat 8
			incbin "gfx/charanims.chr",i*512+16*21,16
i			set i+1
			repend


;-----------------------
;{1} charanimx
;{2} dest offset 
			mac copychar
			lda {1},y
			sta charset0+{2}
			lda {1}+1,y
			sta charset0+{2}+1
			lda {1}+2,y
			sta charset0+{2}+2
			lda {1}+3,y
			sta charset0+{2}+3
			lda {1}+4,y
			sta charset0+{2}+4
			lda {1}+5,y
			sta charset0+{2}+5
			lda {1}+6,y
			sta charset0+{2}+6
			lda {1}+7,y
			sta charset0+{2}+7
			
			lda {1}+8,y
			sta charset1+{2}
			lda {1}+9,y
			sta charset1+{2}+1
			lda {1}+10,y
			sta charset1+{2}+2
			lda {1}+11,y
			sta charset1+{2}+3
			lda {1}+12,y
			sta charset1+{2}+4
			lda {1}+13,y
			sta charset1+{2}+5
			lda {1}+14,y
			sta charset1+{2}+6
			lda {1}+15,y
			sta charset1+{2}+7
			endm

doanim			subroutine
.interleave		lda #$00
			tax
			asl
			sta .animjmp+1
			inx
			txa
			and #$03
			sta .interleave+1
.animjmp		jmp (animframe)


frame0			ldx #$00
			ldy .frame0list,x
			inx
			cpx #$08
			bne .over0
			ldx #$00
.over0			stx frame0+1
			copychar charanim0,16	;Wasser links
			copychar charanim1,24	;Wasser rechts

			copychar charanim14,128	;Ball links 0
			copychar charanim15,136	;Ball links 1
			copychar charanim16,144	;Ball links 2
			copychar charanim17,152	;Ball rechts 0
			copychar charanim18,160	;Ball rechts 1
			copychar charanim19,168	;Ball rechts 2

			rts
			
.frame0list		dc.b 0*16,1*16,2*16,3*16,4*16,5*16,6*16,7*16

			
frame1			ldx #$00
			ldy .frame1list,x
			inx
			cpx #$08
			bne .over1
			ldx #$00
.over1			stx frame1+1
			copychar charanim2,32	;Fackel links
			copychar charanim3,40	;Fackel rechts
			
frame1b			ldx #$00
			ldy .frame1blist,x
			inx
			cpx #$11
			bne .over1b
			ldx #$00
.over1b			stx frame1b+1
			copychar charanim20,176	;skull top
			copychar charanim21,184	;skull bottom

			rts
.frame1list		dc.b 0*16,1*16,2*16,3*16,4*16,5*16,6*16,7*16

.frame1blist		dc.b 0*16,0*16,0*16,1*16,1*16,2*16,3*16,4*16
			dc.b 5*16,6*16,5*16,4*16,3*16,2*16,0*16,2*16
			dc.b 0*16
			
;1,1,1,2,2,3,4,5,6,7,6,5,4,3,1,3,1
			
frame2			ldx #$00
			ldy .frame2list,x
			inx
			cpx #$08
			bne .over2
			ldx #$00
.over2			stx frame2+1
			copychar charanim4,48	;Denk links
			copychar charanim5,56	;Denk rechts
			rts
.frame2list		dc.b 0*16,1*16,2*16,3*16,4*16,5*16,6*16,7*16

frame3			ldx #$00
			ldy .frame3list,x
			inx
			cpx #$08
			bne .over3
			ldx #$00
.over3			stx frame3+1
			copychar charanim6,64	;Denk links
			copychar charanim7,72	;Denk links
			copychar charanim8,80	;Denk links
			copychar charanim9,88	;Denk links
			copychar charanim10,96	;Denk rechts
			copychar charanim11,104	;Denk rechts
			copychar charanim12,112	;Denk rechts
			copychar charanim13,120	;Denk rechts

			rts
.frame3list		dc.b 0*16,1*16,2*16,3*16,4*16,5*16,6*16,7*16
;			dc.b 8*16,7*16,6*16,5*16,4*16,3*16,2*16,1*16
			
			echo "Data end before screen @$c000: ",*
			

;testsprite1		ds.b 64,$aa
;testsprite2		ds.b 64,$77

			org screen
;------------------------------------------------------------------------------
;initscreen
;------------------------------------------------------------------------------
initscreen		subroutine
			jsr vblank
			ldx #$00
			stx $d020
			stx $d021
			stx $dd00
			stx $d017
			stx $d01d
			stx $d01b
			dex
			stx $d01c

			lda #$d8
			sta $d016

			if timingcolors=1
			lda #$0b
			sta $d020
			endif
			
			lda #$00
			sta $d022
			lda #$08
			sta $d023

			lda #startbuffer
			sta doublebuffer+1

			; lda #$00
			; sta viewportxlo
			; sta viewportxhi
			; sta sprpoi1
			; sta sprpoi2
			; sta sprstripe1
	
			lda #$03
			sta sprstripe2
			sta fadeflag

			; lda #$00
			; sta sprxlo2
			; lda #$ff
			; sta sprxhi2

			

			lda #<spe_xstart2
			sta sprxlo3
			lda #>spe_xstart2
			sta sprxhi3
			lda #<spe_ystart2
			sta sprylo3
			
			ldx #63
.copy1			lda spriteline0,x
			clc
			adc #[sprites2-$c000]/64
			sta spriteline0,x
			dex
			bpl .copy1

			inx
			
.copy2			lda spritemap,x
			cmp #$0f			;add 1 to spritepointer if sprite is @$c7c0 gap 
.add1			adc #[sprites-$c000]/64
			sta spritemap,x
			inx
			cpx #spritemapend-spritemap
			bne .copy2

			ldx #$07
.loop2
			; lda #[sprites-$c000]/64
			; sta spritepointer,x
			lda #[emptysprite-$c000]/64
			sta spritepointer2,x
			dex
			bpl .loop2
			jmp initscreen2

;------------------------------------------------------------------------------
initsamples		subroutine
;------------------------------------------------------------------------------
;undelta sample data
			if deltacoding=1

			lxa #$00
			if >[samplememend-samplememstart]>0
			ldy #>[samplememend-samplememstart]
			
.loop1			clc
.add1			adc samplememstart,x
.store1			sta samplememstart,x
			inx
			bne .loop1
			inc .add1+2
			inc .store1+2
			dey
			bne .loop1
			endif
			
			if <(samplememend-samplememstart)>0
			ldy #<(samplememend-samplememstart)
			
.add2			clc
			adc samplememstart+[>[samplememend-samplememstart]*256],x
			sta samplememstart+[>[samplememend-samplememstart]*256],x
			inx
			dey
			bne .add2
			endif
			endif	
;generate loopdata
.goon			ldy #samples
.loop			lda loopposhi,y
			beq .nextsample
			sta .getloop+2
			lda loopposlo,y
			sta .getloop+1

			lda sampleendlo,y
			sta .storeloop+1
			lda sampleendhi,y
			sta .storeloop+2

			lda safetymargintable,y
			sta .checker+1
			
			ldx #$00
.getloop		lda samplememstart,x
.storeloop		sta samplememend,x
			inx
.checker		cpx #$00
			bne .getloop

.nextsample		dey
			bpl .loop
			rts
;------------------------------------------------------------------------------
javainit		subroutine
;------------------------------------------------------------------------------
.copynmi		ldx #$00
.copy1			lda nmiplaystart,x
			sta zeropagecode,x
			inx
			cpx #nmiplayend-nmiplaystart
			bne .copy1

			lda #$00
			ldx #clearend-clearstart
.loop1			sta clearstart,x
			dex
			bpl .loop1

			tax
	
			ldx #$00
			lda #$80		;clear all mixingbuffers
.mixbuffer		sta mixingbuffer,x
			inx
			cpx #mixingbufferlength
			bne .mixbuffer
				
			ldx #$4f	
			lda #$2a
.loop4			sta silentbuffer,x
			dex
			bpl .loop4
			rts
;------------------------------------------------------------------------------
sidinit			subroutine
;------------------------------------------------------------------------------
			ifconst release
			lda link_chip_types
			else
			lda #$01		;$00 old sid $01 new sid
			endif
			and #%00000001
			bne .newsid
			
			ldx #$00		;switch to 6581 table
.copyloop		lda d418tab6581,x
			sta d418tab,x
			inx
			bne .copyloop

.newsid			ldx #$18
			lda #$00
.loop1			sta $d400,x
			dex
			bpl .loop1

			lda #$49
			sta $d404
			sta $d40b
			sta $d412
			lda #$ff
			sta $d406
			sta $d40d
			sta $d414

			sta $d415
			sta $d416

			lda #$03   		;Enable filter on voice #1 and #2
			sta $d417
			rts
			
;------------------------------------------------------------------------------
periodtablegen		subroutine
;------------------------------------------------------------------------------
;creates tables for different notes
			ldx #$00

.loop2			ldy #$00
			sty .stepfraclo+1
			sty .stepfracmi+1
			sty .stepfrachi+1
			sty .steplo+1

			lda stepfraclotable,x
			sta .stepfracloadd+1
			lda stepfracmitable,x
			sta .stepfracmiadd+1
			lda stepfrachitable,x
			sta .stepfrachiadd+1
			lda steplotable,x
			sta .steploadd+1

.loop1			lda .steplo+1
			bit .stepfrachi+1
			bpl .tableset
			clc
			adc #$01
;			inc $d020
			
.tableset		sta periodtable,y
			clc
.stepfraclo		lda #$00
.stepfracloadd		adc #$00
			sta .stepfraclo+1
.stepfracmi		lda #$00
.stepfracmiadd		adc #$00
			sta .stepfracmi+1
.stepfrachi		lda #$00
.stepfrachiadd		adc #$00
			sta .stepfrachi+1
.steplo			lda #$00
.steploadd		adc #$00
			sta .steplo+1

			iny
			cpy #periodsteplength
			bne .loop1
;			bpl .loop1	;optimierung für steplength=128

			lda .stepfrachi+1
			sta notesaddfrac,x
			
			lda .steplo+1
			sta notesaddlo,x

			lda .tableset+2
			sta notestablehi,x
			tay

			lda .tableset+1
			sta notestablelo,x
			clc
			adc #periodsteplength
			sta .tableset+1
			adc #periodsteplength
			bcc .overinc

			if lastvolume=$20
			iny
			else
			lda #$00
			iny
			cpy #>periodtable+lastvolume-1
			bcs .overset
			endif

			lda #<periodtable
.overset		sta .tableset+1

			sty .tableset+2
.overinc		inx
			cpx #lastperiod
			beq .exit
			jmp .loop2
.exit			rts
;------------------------------------------------------------------------------
			include "thc_init.asm"
			
			echo "Init end before Sprites @c400: ",*

;------------------------------------------------------------------------------
			org sprites	;$c400
			incbin "gfx/handles.spr",0,$3c0	;until gap @$c7c0
			ds.b 64
			incbin "gfx/handles.spr",$3c0	;after gap from $c800
shipsprites		incbin "gfx/ship.spr"
			echo "Sprite end before charset0 @$e800: ",*
;------------------------------------------------------------------------------
			org charset0	;$e800
i			set 0
			repeat 256
			incbin "gfx/levelmap.chr",i*16,8
i			set i+1
			repend
;-----------------------			
			org charset1	;$f000
i			set 0
			repeat 256
			incbin "gfx/levelmap.chr",i*16+8,8
i			set i+1
			repend
;------------------------------------------------------------------------------
			org sprites2	;$f800
			incbin "gfx/clouds.spr"
			echo "Clouds end : ",*

;------------------------------------------------------------------------------
;screen rows layout
;------------------------------------------------------------------------------
;buffer 0          buffer 1

;empty             00 
;00 offset 00      01 offset 40   
;00                01
;02 offset 80      03 offset 120  
;02                03
;04 offset 160     05 offset 200  
;04                05
;06 offset 240     07 offset 280  
;06                07
;08 offset 320     09 offset 360
;08                09
;10 offset 400     11 offset 440
;10                11
;12 offset 480     13 offset 520
;12                13
;14 offset 560     15 offset 600
;14                15
;16 offset 640     17 offset 680
;16                17
;18 offset 720     19 offset 760
;18                19
;20 offset 800     21 offset 840
;20                21
;22 offset 880     23 offset 920
;22                23
