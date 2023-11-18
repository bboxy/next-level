;to do:
;improve replay quality?
;write scrolltext

;ideas:
;Performers don't use VSP!!!
;DANCE!!! SHAKE YOUR BOOBIES!!!
;15,6khz for the masses honoring the work and life of maxi jazz
;when i was young, my family looked at me like a was an alien
;over 35 years later where nearly anyone has a small computer in his pocket, they still look the same when they get into my office and see a demon running on my sx-64
;cilf - commodore i like to fuck with
;now we're old as hell it's all about remembering the good old times
;for us kids the world couldn't have been better and working on a demo with friends is like turning back time

			processor 6502
			incdir "../../util/dasm/include"
			include "standard.asm"
			
;------------------------------------------------------------------------------
;global settings
;------------------------------------------------------------------------------
			ifnconst release
timingcolors		equ 1			;0=no colors 1=display rastertiming
			else
timingcolors		equ 0			;always 0, no colors wanted on release
			endif

volumesupport		equ 0			;0=no global volume support 1=turn on global volume support

globalfilter		equ $00			;global filter setting for 6581 $d418 output + sid

use3bit			equ 0			;0=4bit output 1=3bit output volumes 8-15
					
detachmixer		equ 0			;0=mixing in main thread, no loading possible 1=detach mixer from irq, mustn't use more than one frame to mix!
						;set to 0 to avoid crashing of too long mixing times

fastjitter		equ 0			;0=use safe 8 cycle jitter 1=use faster 7 cycle jitter
						;might crash depending on sid replayer
external		equ 1			;0=use internal settings 1=include external settings

skipsid			equ 0			;skip sid testing

;------------------------------------------------------------------------------
;internal settings
;------------------------------------------------------------------------------
			if external=1
			include "thc_settings.asm"ß
			else			;external=1
preset			equ 5			;0 = user defined
						;1 = 4ch ProTracker
						;2 = MLC1
						;3 = SCC Loop Station
						;4 = Fast delay
						;5 = 4ch 8bit signed
						;6 = other specs
						;7 = Fantasmolytic
						;8 = MLC1+
						;9 = MLC1 Foldback
						
includesid		equ 0			;0=no sid tune 1=play sid
volumeboost		equ 0			;possible values are 0-8 for 0, 25 ,50 , 75, 100 ,125, 150, 175, 200% boost, 9 for global volume / foldback tables
sampleoutput		equ 3			;0=waveform 8bit 1=digimax for emulator 2=4bit $d418  3=7bit $d418  4=$d020 colors  5=$d021 colors 6=pwm gate
						;if sampleoutput=2 or 3 then volumeboost has to be 0 !!!
replayrate		equ 2			;0=7812hz (1=11718hz 2=15624hz stablenmi has to be 0!)
bitdepth		equ 3			;0=4 bit samples 1=5 bit samples 2=6bit samples 3=7bit samples 4=8bit samples mixing
signed			equ 0			;0=unsigned samples 1=signed samples, needed for loop station mixing
loopstation		equ 0 			;0=disbale loop station 1=enable loop station with sample 31 as loop buffer
digivoices		equ 2			;2, 3 or 4 digi voices
sampleoffsetsupport	equ 1			;0=no global sampleoffset support 1=turn on global sampleoffset support
stablenmi		equ 0			;0=use normal nmi 1=use stable nmi
screen			equ 1			;0=screen off 1=screen on
controlchannel		equ 0			;0=no control channel 1=use last channel as control channel
siddelay		equ 8			;first delay of the modplay to sync goatracker sid and protracker module
			    			;values from 0 to 127 are valid
						;Fanta (Goat) uses delay of 7
						;Mahoney (Goat) uses delay of 1
						;LMan (Cheesecutter) uses delay of 4
multispeed		equ 1			;1=single speed, 2=double speed, 3=triple speed
rleimproved		equ 0			;enables better rle mode decompression	
cc2patch		equ 0			;0=do nothing 1=try to prevent cheesecutter2 from playing 3rd voice
						;uses a simple check to identify a cheesecutter sid file, only set to 0 to save space
playinterleave		equ 0			;replay using interleaved data
playlzstream		equ 0			;replay lz compressed interleaved data, needs playinterleave=1
deltacoding		equ 1			;0=normal samples 1=delta coded samples
;------------------------------------------------------------------------------
;channel specs
;thc_chn?vol	 	0=volume always max				1=volume support on
;thc_chn?per	 	0=always play period @ replay rate		1=period support on
;thc_chn?off		0=sampleoffset support off			1=sampleoffset support on
;------------------------------------------------------------------------------
			
			if preset=7		;Fantasmolytic Style
thc_chn1vol		equ 0
thc_chn1per		equ 1
thc_chn1off		equ 1

thc_chn2vol		equ 0
thc_chn2per		equ 0
thc_chn2off		equ 1

			endif	;preset=7
			endif	;external
;------------------------------------------------------------------------------
;zeropage
;------------------------------------------------------------------------------
zeropagecode		equ $02		;start of zeropage routines up to $ed
zeropage		equ $a0		;normal $ee (8 channels a 2 bytes)

;------------------------------------------------------------------------------
;volumetable vars
prodlo			equ zeropage+$00
;------------------------------------------------------------------------------
;replayer vars

zp			set zeropage
clearstart		equ zp

voice1active		equ zp				;4 bytes=4 voices - sample on $01, looped $ff or off $00
zp			set zp+1			
			if digivoices>1
voice2active		equ zp
zp			set zp+1			
			endif
			if digivoices>2
voice3active		equ zp
zp			set zp+1			
			endif
			if digivoices>3
voice4active		equ zp
zp			set zp+1			
			endif
			if digivoices>4
voice5active		equ zp
zp			set zp+1			
			endif
			if digivoices>5
voice6active		equ zp
zp			set zp+1			
			endif
			if digivoices>6
voice7active		equ zp
zp			set zp+1			
			endif
			if digivoices>7
voice8active		equ zp
zp			set zp+1			
			endif
			
			if thc_chn1per=1
sample1frac		equ zp
zp			set zp+1
			endif
			if digivoices>1
			if thc_chn2per=1
sample2frac		equ zp
zp			set zp+1
			endif
			endif
			if digivoices>2
			if thc_chn3per=1
sample3frac		equ zp
zp			set zp+1
			endif
			endif
			if digivoices>3
			if thc_chn4per=1
sample4frac		equ zp
zp			set zp+1
			endif
			endif
			if digivoices>4
			if thc_chn5per=1
sample5frac		equ zp
zp			set zp+1
			endif
			endif
			if digivoices>5
			if thc_chn6per=1
sample6frac		equ zp
zp			set zp+1
			endif
			endif
			if digivoices>6
			if thc_chn7per=1
sample7frac		equ zp
zp			set zp+1
			endif
			endif
			if digivoices>7
			if thc_chn8per=1
sample8frac		equ zp
zp			set zp+1
			endif
			endif
			
stacksave		equ zp+$00
areg			equ zp+$01			
xreg			equ zp+$02
yreg			equ zp+$03			
copyflag		equ zp+$04
finescroll		equ zp+$05
rasterpoi		equ zp+$06
logo1pos		equ zp+$07
logo2pos		equ zp+$08
sineptr1		equ zp+$09
sineptr2		equ zp+$0a
sinesprlo1		equ zp+$0b
sinesprlo2		equ zp+$0c
curchar			equ zp+$0d
fadeflag		equ zp+$0e	;0=no fade 1=fade in 128=fade out
flashpoi		equ zp+$0f

logo1col0		equ zp+$10	;p offset 42-15 length 6
logo1col1		equ zp+$11	;e offset 49-15 length 5
logo1col2		equ zp+$12	;r offset 55-15 length 6 
logo1col3		equ zp+$13	;f offset 62-15 length 6
logo1col4		equ zp+$14	;o offset 68-15 length 6
logo1col5		equ zp+$15	;r offset 75-15 length 6
logo1col6		equ zp+$16	;m offset 82-15 length 6
logo1col7		equ zp+$17	;e offset 89-15 length 5
logo1col8		equ zp+$18	;r offset 95-15 length 6
logo1col9		equ zp+$19	;s offset 102-15 length 6

logo2col0		equ zp+$1a	;n offset 46-15 length 6
logo2col1		equ zp+$1b	;e offset 53-15 length 5
logo2col2		equ zp+$1c	;x offset 58-15 length 7
logo2col3		equ zp+$1d	;t offset 65-15 length 6
logo2col4		equ zp+$1e	;l offset 75-15 length 5
logo2col5		equ zp+$1f	;e offset 81-15 length 5
logo2col6		equ zp+$20	;v offset 86-15 length 7
logo2col7		equ zp+$21	;e offset 93-15 length 5
logo2col8		equ zp+$22	;l offset 99-15 length 5

logo1off0		equ zp+$23	;p offset 42-15 length 6
logo1off1		equ zp+$24	;e offset 49-15 length 5
logo1off2		equ zp+$25	;r offset 55-15 length 6 
logo1off3		equ zp+$26	;f offset 62-15 length 6
logo1off4		equ zp+$27	;o offset 68-15 length 6
logo1off5		equ zp+$28	;r offset 75-15 length 6
logo1off6		equ zp+$29	;m offset 82-15 length 6
logo1off7		equ zp+$2a	;e offset 89-15 length 5
logo1off8		equ zp+$2b	;r offset 95-15 length 6
logo1off9		equ zp+$2c	;s offset 102-15 length 6

logo2off0		equ zp+$2d	;n offset 46-15 length 6
logo2off1		equ zp+$2e	;e offset 53-15 length 5
logo2off2		equ zp+$2f	;x offset 58-15 length 7
logo2off3		equ zp+$30	;t offset 65-15 length 6
logo2off4		equ zp+$31	;l offset 75-15 length 5
logo2off5		equ zp+$32	;e offset 81-15 length 5
logo2off6		equ zp+$33	;v offset 86-15 length 7
logo2off7		equ zp+$34	;e offset 93-15 length 5
logo2off8		equ zp+$35	;l offset 99-15 length 5

clearend		equ zp+$36

goatlo			equ $fe
goathi			equ $ff

;------------------------------------------------------------------------------
;constants
;------------------------------------------------------------------------------
periodsteplength	equ 52				;52 stepbytes per note

mixingbufferlength	equ periodsteplength*2		;104 rasterlines + 104 lines direct play + 104 lines on stack
nmifreq			equ $003e
			
samples			equ 31				;samples 0-31

mixline			equ $ff
mixlineoffset		equ 0

logoline		equ 78

rasterframes		equ 8

scrollbgcol		equ 0

emptysprite		equ (spritedata0-vicbase)/64

;------------------------------------------------------------------------------
;tables
;------------------------------------------------------------------------------
stack			equ $0100			;holds 104 bytes mixing data until $0167
stackcode		equ stack+periodsteplength*2
periodtable		equ $0400			;first page of periodtables
							;$0400-$04cf
							;$0500-$05cf
							;$ea00-$eacf
							
notestablelo		equ $04d0			;max 16 periods, 10 used
notestablehi		equ $04e0
notesaddlo		equ $05d0
notesaddfrac		equ $05e0

mixingbuffer		equ $0600			;-$0667
lzshistory		equ $0700

silentbuffer		equ $0800			;-$0833

colorram		equ $d800

charset0		equ $d000			;$200 bytes per charset
charset1		equ $d800
charset2		equ $e000
charset3		equ $e800
charset4		equ $f000
charset5		equ $f800

font0			equ $d200			;$200 bytes per charset
font1			equ $da00
font2			equ $e200

spritedata0		equ $d400			;$400 bytes up to 16 sprites
spritedata1		equ $dc00			;$400 bytes up to 16 sprites
spritedata2		equ $e400			;$400 bytes up to 16 sprites, used until $e6ff

vicbase			equ $c000
screen1			equ $f400
logo1line		equ screen1+160
scrollline		equ screen1+440
logo2line		equ screen1+600

logo1color		equ colorram+160
logo2color		equ colorram+600	
spritepointer		equ screen1+$03f8
			
disposable		equ $eb00			;will be deleted by periodtablegen

sidfile			equ $f200			;loading tune

;free mem
;$c500-$cfff
;$e6b3-$e6ff
;$f400-$f7f7		;can be partly used, if colors are set correctly
;$ffec-$fff9

			org $0500
initscreen2		subroutine
			lxa #$00
.clear			sta screen1,x
			sta screen1+$0100,x
			sta screen1+$0200,x
			sta screen1+$02e8,x
			inx
			bne .clear
dumb
			ldx #$27
.fill			lda #$00
			sta logo1color,x
			sta logo2color,x
			lda #scrollbgcol
			sta colorram+440,x
			lda #$81
			sta logo1line,x
			sta logo2line,x
			lda #$00+$40
			sta scrollline,x

			dex
			bpl .fill
			rts

			org $0600
;------------------------------------------------------------------------------
initnmi			subroutine
;------------------------------------------------------------------------------
			lda #$40
			sta $dd0c
			lda #$00
;			sta .cia_type+1	;not needed if run once
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
			lda #$04	;prepare detection (timer=4 cycles)
			sta $dd04
.sync1			lda $d011
			bpl .sync1
.sync2			lda $d011
			bmi .sync2

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

			ldx #$04
.waitline		cpx $d012
			bne .waitline
			jsr .waitcycles
			bit $ea
			nop
			cpx $d012
			beq .skip1
			nop
			nop
.skip1			jsr .waitcycles
			bit $ea
			nop
			cpx $d012
			beq .skip2
			bit $ea
.skip2			jsr .waitcycles
			nop
			nop
			nop
			cpx $d012
			bne .onecycle
			
.onecycle		lda .cia_type+1	;line 07 cycle3
			bpl .skip3	
	
.skip3			lda #$07		;63-1	
			sta $dc06	
			lda #nmifreq
			sta $dd04	
			lda #$00	
			sta $dc07	
			sta $dd05	
			
			lda #<nmiplay
			sta $fffa
			lda #>nmiplay
			sta $fffb

			lda #$11	
			jsr .wait12
			jsr .wait12
			jsr .wait16
			
sucks			sta $dd0e	;waveform stable @ line 8 cycle 23 (can be repositioned)
	
.cia_type		ldx #$00	
			bmi .skip4
.skip4			delay 13
			
sucks2			sta $dc0f	;write must be stable @ line 8 cylce 34
			rts
			
.waitcycles		ldy #$06
.loop1		     	dey
			bne .loop1
			inx
.wait16			nop
.wait14			nop
.wait12			rts

;------------------------------------------------------------------------------
;small helper routines
;------------------------------------------------------------------------------
vblank			subroutine
.1			bit $d011
			bpl .1
.2			bit $d011
			bmi .2
wait14			nop
wait12			rts
;------------------------------------------------------------------------------
stoptune		subroutine
;stop replay
			lda #$7f
			sta $dd0d
			lda #$08
			sta $dd0e
			
clearsid		subroutine
			ldx #$18
			lda #$00
.loop1			sta $d400,x
			dex
			bpl .loop1
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

			lda .tableset+1
			sta notestablelo,x
			clc
			adc #periodsteplength
			sta .tableset+1
			adc #periodsteplength
			bcc .overinc

			lda #<periodtable
			sta .tableset+1

.pagepoi		ldy #$00
			iny
			sty .pagepoi+1
			lda .periodpages,y
			sta .tableset+2
.overinc		inx
			cpx #lastperiod
			beq .exit
			jmp .loop2
.exit			rts


.periodpages		dc.b >periodtable
			dc.b >periodtable+1
			dc.b $ea
			dc.b $ec
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
;------------------------------------------------------------------------------
;nmi-replayer
;------------------------------------------------------------------------------
nmi_start
	 		rorg zeropagecode
;------------------------------------------------------------------------------
nmiplay			subroutine
;------------------------------------------------------------------------------
nmiplaybuf		sta abuf+1			;3+7
fetch			lda mixingbuffer		;4
			sta $d418			;4

			; lda $d012			;4
; fetch			sta mixingbuffer1		;4

			inc fetch+1			;5
abuf			lda #$00			;2
			jmp $dd0c			;3+6 34 Takte

;------------------------------------------------------------------------------
;preset 7 - 15,6khz 2 channels fantasmolytic style
;------------------------------------------------------------------------------
			if preset=7	
mixer
notefetch1a		ldy periodtable,x				;4
samplefetch1a		lda silentbuffer,y 				;4
			sta mix1a+1					;3 = 11

samplefetch1c		lda silentbuffer,y 				;4
samplefetch2c		adc silentbuffer,x 				;4
			sta .vol1+1					;3
.vol1			lda d418tab					;4
			sta mixingbuffer,x				;5 = 20 3rd part will be written to buffer @ 0

samplefetch1d		lda silentbuffer,y 				;4
samplefetch2d		adc silentbuffer,x 				;4
			pha						;3 = 11 4th part will be written backwards to the stack, has to be moved to 52
;mixswitch4		sta mixingbuffer1+periodsteplength,x

samplefetch2a		ldy silentbuffer,x 				;4
mix1a			lda d418tab,y					;4
mixswitch1		sta $d418					;4 = 12 first chunk of 52 will be played directly

			inx						;2
			cpx #periodsteplength				;2
			bne notefetch1a					;3 7 = 61 + 6 cycles / 2x d418tab reads extern
	
fadeslice0		lda #$00					;$0b
			sta $d020
			sta $d021
	
mid			ldx #$00
			lda #periodsteplength-2
.wait			cmp $d012
			bcs .wait

mixer2
notefetch1b		ldy periodtable,x				;4
samplefetch1b		lda silentbuffer,y 				;4
			sta mix1b+1					;3 = 11

samplefetch1e		lda silentbuffer,y 				;4
samplefetch2e		adc silentbuffer,x 				;4
			pha						;3 = 11 5th part will be written backwards to the stack, has to be moved to 104
;			sta mixingbuffer+periodsteplength*2,x		;5 = 

samplefetch1f		lda silentbuffer,y 				;4
samplefetch2f		adc silentbuffer,x 				;4
			sta .vol2+1					;3
.vol2			lda d418tab					;4
mixswitch6		sta mixingbuffer+periodsteplength,x		;5= 20 6th part will be written to buffer @ 52 skipping 102 bytes stack mixing

samplefetch2b		ldy silentbuffer,x 				;4
mix1b			lda d418tab,y					;4
mixswitch2		sta $d418					;4 = 12 2nd chunk of 52 will be played directly

			inx						;2
			cpx #periodsteplength				;2
			bne notefetch1b					;3 7 = 61 + 6 cycles / 2x d418tab reads extern
			jmp mixerend
			endif	;preset=7
			rend
nmi_end

;------------------------------------------------------------------------------
			ifnconst release
			org $0801
			;basic sys line
			dc.b $0b,$08,$00,$00,$9e,$32,$30,$36
			dc.b $31,$00,$00,$00
;.jump			jmp .jump			
			else
			org $0800
			include "../../bitfire/loader/loader_acme.inc"
			include "../../bitfire/macros/link_macros_dasm.inc"
			endif
;------------------------------------------------------------------------------
main			subroutine
;------------------------------------------------------------------------------
			ifnconst release
			sei
			cld
			lda #$35
			sta $01
			ldx #$ff
			txs
			inx
			jsr vblank
			
			stx $d011
			stx $d021
			stx $d020
			stx $d015

			lda #$00
			jsr sidfile
			ldx #<sidnmi
			lda #>sidnmi

			stx $fffa
			sta $fffb
			lda #$00
			sta $dd0e
			lda $dd0d
			lda #$c7
			sta $dd04
			lda #$4c
			sta $dd05
			lda #$81
			sta $dd0d

			lda #$ff
.waitl			cmp $d012
			bne .waitl

			lda #$11
			sta $dd0e
			endif
			
			jsr vblank
			ldy #$7f
			sty $dd0d
			lda $dd0d
			
			sty $dc0d
			lda $dc0d

			lda #$01
			sta $d019
			sta $d01a
			
			lda #<sidirq
			sta $fffe
			lda #>sidirq
			sta $ffff	
			lda #mixline-mixlineoffset
			sta $d012
			cli

			jsr initsamples
			jsr initnmi
			cli
			jsr javarestart
			jsr initscreen
			jsr initscreen2
			jsr periodtablegen

			if skipsid=0
;.wait2			lda $e7
;			beq .wait2
.wait3			lda $e7
			bne .wait3
			endif

			ldx #$04
.wait4			jsr vblank
			dex
			bpl .wait4
			
			sei
			jsr initsid
			
			lda #$7f
			sta $dc0d
			lda $dc0d

			lda #$01
			sta $d019
			sta $d01a
			
			lda #<mixirq
			sta $fffe
			lda #>mixirq
			sta $ffff	
			lda #mixline-mixlineoffset
			sta $d012
			
			jmp main2
			

sidirq			subroutine
			sta areg
			stx xreg
			sty yreg
;			inc $d020
			
			jsr sidfile+3
;			dec $d020
			
			inc $d019
			lda areg
			ldx xreg
			ldy yreg
			rti


			ifnconst release
sidnmi			subroutine
			pha
			txa
			pha
			tya
			pha
			lda $01
			pha
			lda #$35
			sta $01
			lda $dd0d
			jsr sidfile+3
			pla
			sta $01
			pla
			tay
			pla
			tax
			pla
			rti
			endif

			echo "Initcode before main2: ", *
			
;			org $0a00
;------------------------------------------------------------------------------
main2			subroutine
;------------------------------------------------------------------------------
			lda #$20
			ldx #periodsteplength-1
.loop1			sta silentbuffer,x
			dex
			bpl .loop1

			asl			;$80 7 bit mixing
			ldx #mixingbufferlength-1
.mixbuffer		sta mixingbuffer,x
			dex
			bpl .mixbuffer

			jsr vblank

			lda #mixline-2-mixlineoffset
.wait1			cmp $d012
			bne .wait1
.wait2			cmp $d012
			beq .wait2
			lda $dd0d
			lda #$81
			sta $dd0d
			cli

			ifconst release
endflag			lda #$00
			beq endflag

			jsr vblank
			lda #$00
			sta $d011
			sta $d015
			sta $d020
			sta $d021
			
			jsr stoptune
			
			ldx #$0f
.loop2			jsr vblank
			jsr vblank
			lda cyclered,x
			sta $d020
			sta $d021
			dex
			bpl .loop2
			
			jmp stackcode
			else

.forever		
			cmp $ce80,x
			bpl .forever2
.forever2		inx
			bit $00
			lda $ce80
			adc $0100
			bcc .next
.next			nop
			cmp $ce80,x
			inx
endflag			lda #$00
			beq .forever
			
.forever3		jsr vblank
			lda #$00
			sta $d011
			sta $d015
			sta $d020
			sta $d021
			jmp .forever3
			endif
;------------------------------------------------------------------------------
;macros
;------------------------------------------------------------------------------
			mac playsample
			lda mixingbuffer+{1}
			sta $d418
			endm

			mac playstack
			ldx stack+{1}
			lda d418tab,x
			sta $d418
			endm

			mac playnextsample
			lda mixingbuffer+playpos
			sta $d418
playpos			set playpos+1
			endm

			mac convsample
			ldx stack+convsrc
			lda d418tab,x
			sta mixingbuffer+convdst
convsrc			set convsrc-1
convdst			set convdst+1			
			endm

			mac copybyte
			lda scrollline+{1},y
			sta scrollline+{1}
			endm

			mac perscrbyte
			lda charline0+{1},y
			sta logo1line+{1}
			endm

			mac nexscrbyte
			lda charline1+{1},y
			sta logo2line+{1}
			endm

			mac percolbyte
			lda colorline0+{1},y
			sta logo1color+{1}
			endm

			mac nexcolbyte
			lda colorline1+{1},y
			sta logo2color+{1}
			endm

;1 = char number
;2 = char position
;3 = char length (5-7)

			mac flashchar1
			lax logo1col{1}		;23 cycles
			ora logo1off{1}
			tay
			lda flashtable,y
			sta colorline0+{2}
			sta colorline0+1+{2}
			sta colorline0+2+{2}
			sta colorline0+3+{2}
			sta colorline0+4+{2}	;23+20=43 cycles
			if {3} > 5
			sta colorline0+5+{2}	;23+34=47 cycles
			endif
			if {3} > 6
			sta colorline0+6+{2}	;23+34+51 cycles
			endif
			
			dex
			txa
			anc #$ff
			adc #$00
			sta logo1col{1}
			endm

			mac flashchar2
			lax logo2col{1}		;23 cycles
			ora logo2off{1}
			tay
			lda flashtable,y
			sta colorline1+{2}
			sta colorline1+1+{2}
			sta colorline1+2+{2}
			sta colorline1+3+{2}
			sta colorline1+4+{2}	;23+20=43 cycles
			if {3} > 5
			sta colorline1+5+{2}	;23+34=47 cycles
			endif
			if {3} > 6
			sta colorline1+6+{2}	;23+34+51 cycles
			endif
			
			dex
			txa
			anc #$ff
			adc #$00
			sta logo2col{1}
			endm


;------------------------------------------------------------------------------
;mixirq - Line $ff
;------------------------------------------------------------------------------
mixirq			subroutine
			sta .areg+1
			stx .xreg+1
			sty .yreg+1

			clc

			lda #$5b
			sta $d011
			
			ldx #$7f			;will be interrupted by last nmi with last sample 
			stx $dd0d
			ldx $dd0d
			
			tsx
			stx stacksave
			ldx #periodsteplength*2-1	;place for 104 bytes
			txs

			ldx #$00
;			dec $d020			;need to play line $ff here
			nop
			nop
			nop
			jmp mixer
;-----------------------
mixerend		ldx stacksave
			txs

			lda #<mixingbuffer		;lobyte of mixingbuffers
			sta fetch+1

			inc $d019

			lda #periodsteplength*2-56-1-mixlineoffset
.wait2			cmp $d012
			bcs .wait2
			
			lda #logoline	;$da
			sta $d012
			
			lda #<logoirq
			sta $fffe
			lda #>logoirq
			sta $ffff

			ldx #$81
			stx $dd0d				;nmi kicks in and plays @ line $30 cylce ~47

			lda #[>[screen1-vicbase]<<2] | [>[charset0-vicbase]>>2]	;2
			sta $d018

fadeslice2a		lda #$00				;$0c
			sta $d022
			sta $d023
			sta $d024
			
			cli					;allow reentrant irq
			
;			dec $d020
			jsr replayer
			lda #$00
;			sta $d020
			
.areg			lda #$00
.xreg			ldx #$00
.yreg			ldy #$00
			rti
;------------------------------------------------------------------------------
;logoirq - Line $52 the line before the badline, sample 33 played before
;from sample 52 on needs to be converted
;------------------------------------------------------------------------------
logoirq			subroutine
			sta areg
			lda #$7f			;will be interrupted by last nmi with last sample 
			sta $dd0d
			lda $dd0d

			lda $dc06
			eor #$07
			sta *+4
			bpl *+2
			lda #$a9
			lda #$a9
			lda $eaa5			

ps30			playsample 30			;stable 78@42
			stx xreg
			sty yreg
fadeslice1		lda #$00			;$01
			sta $d021
			sta $d020

			lda #$54
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f
			lda #$ff
			sta $d015

ps31			playsample 31			;stable 79@43
			ldy copyflag
			delay 4
fadeslice2b		lda #$00			;$0c
			sta $d020
			sta $d021
			sta $d027
			sta $d028
			sta $d029
			sta $d02a
			sta $d02b
			sta $d02c
			sta $d02d
			sta $d02e
scrollreg1		lda #$00
			sta $d016
			
ps32			playsample 32			;stable 80@43
			copybyte 0			;start of textscroller
			copybyte 1
			copybyte 2
			copybyte 3
			copybyte 4
			copybyte 5
			copybyte 6
;			delay 7
ps33			playsample 33			;stable 81@43
			copybyte 7
			copybyte 8
			copybyte 9
			copybyte 10
			copybyte 11
			copybyte 12
			delay 6
ps34			playsample 34			;stable 82@43
			copybyte 13
			copybyte 14
			copybyte 15

ps35			playsample 35			;stable 83@12 83 badline 
			copybyte 16
			copybyte 17
			copybyte 18
			copybyte 19
fadeslice2d		ldx #$00			;$01
fadeslice2e		ldy #$00			;$0d
			delay 6

ps36			playsample 36			;stable 84@41
fadeslice2g		lda #$00			;$03
			delay 2
			sty $d022			;store @ cycle 55
			stx $d021
			sta $d024
fadeslice2f		lda #$00			;$08		
			sta $d023
			ldy copyflag
			copybyte 20
			delay 6
			
ps37			playsample 37			;stable 85@43			

			lda #$54+21
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f

ps38			playsample 38			;stable 86@41
			copybyte 21
			copybyte 22
			copybyte 23
			copybyte 24
			delay 4
			
ps39			playsample 39			;stable 87@41			
			copybyte 25
			copybyte 26
			copybyte 27
			copybyte 28
			delay 4

ps40			playsample 40			;stable 88@41			
			copybyte 29
			copybyte 30
			copybyte 31
			copybyte 32
			delay 4

ps41			playsample 41			;stable 89@41
			copybyte 33
			copybyte 34
			copybyte 35
			delay 9

			ldx #[>[screen1-vicbase]<<2] | [>[charset1-vicbase]>>2]	;2
ps42			playsample 42			;stable 90@40

stable1			dec $d011			;write at line $5a cycle 54/48
			stx $d018
			copybyte 36
			copybyte 37
			copybyte 38			;end of textscroller
rasterpos		ldy #$00

ps43			playsample 43			;stable 91@41
			lda rastercolors+192,y
			sta col00+1
			lda rastercolors+144+3,y
			sta col01+1
			lda rastercolors+96+5,y
			sta col02+1
			lda rastercolors+48+6,y
			sta col03+1
			delay 4

ps44			playsample 44			;stable 92@40

stable2			inc $d011			;write at line 92 cycle 54/48
			lda rastercolors+7,y
			sta col04+1
			lda rastercolors+48+8,y
			sta col05+1
			lda rastercolors+9,y
			sta col06+1
			lda rastercolors+9,y
			sta col07+1
		
ps45			playsample 45			;stable 93@42
			lda rastercolors+10,y
			sta col08+1
			lda rastercolors+10,y
			sta col09+1
			lda rastercolors+11,y
			sta col10+1
			lda rastercolors+11,y
			sta col11+1
			delay 4
			
ps46			playsample 46			;stable 94@42
			lda rastercolors+12,y
			sta col12+1
			lda rastercolors+12,y
			sta col13+1
			lda rastercolors+13,y
			sta col14+1
			lda rastercolors+13,y
			sta col15+1
			delay 4
			
ps47			playsample 47			;stable 95@42
			lda rastercolors+14,y
			sta col16+1
			lda rastercolors+14,y
			sta col17+1
			lda rastercolors+48+15,y
			sta col18+1
			lda rastercolors+16,y
			sta col19+1
			delay 4
			
ps48			playsample 48			;stable 96@42
			lda rastercolors+48+17,y
			sta col20+1
			lda rastercolors+96+18,y
			sta col21+1
			lda rastercolors+144+20,y
			sta col22+1
			lda rastercolors+192+23,y
			sta col23+1
			ldy logo1pos
			
ps49			playsample 49			;stable 97@42
			perscrbyte 0
			perscrbyte 1
			perscrbyte 2
			delay 9
			
			ldy #[>[screen1-vicbase]<<2] | [>[charset2-vicbase]>>2]	;2
ps50			playsample 50			;stable 98@40

stable3			dec $d011			;write at line 98 cycle 54/48
			sty $d018
			ldy logo1pos
			perscrbyte 3
			perscrbyte 4
			perscrbyte 5
			delay 2

ps51			playsample 51			;stable 99@43
			perscrbyte 6
			perscrbyte 7
			perscrbyte 8
			delay 5

pst103			playstack 103			;stable 100@36 write backwards
stable4			inc $d011			;write at line 100 cycle 54/48
			perscrbyte 9
			perscrbyte 10
			perscrbyte 11
			delay 5
			
pst102			playstack 102			;stable 101@39 write backwards
			perscrbyte 12
			perscrbyte 13
			perscrbyte 14
			perscrbyte 15
			
pst101			playstack 101			;stable 102@39 write backwards
			perscrbyte 16
			perscrbyte 17
			perscrbyte 18
			perscrbyte 19
			
pst100			playstack 100			;stable 103@39 write backwards
			perscrbyte 20
			perscrbyte 21
			perscrbyte 22
			perscrbyte 23
			
pst99			playstack 99			;stable 104@39 write backwards
						
sprl1p0			lda #emptysprite
sprl1p1			ldx #emptysprite
sprl1p2			ldy #emptysprite
sync1			sta spritepointer+0		;105@17
			stx spritepointer+1
			sty spritepointer+2
sprl1p3			lda #emptysprite
			sta spritepointer+3
sprl1p4			lda #emptysprite
			sta spritepointer+4
sprl1p5			lda #emptysprite
			sta spritepointer+5
sprl1p6			lda #emptysprite
			sta spritepointer+6
sprl1p7			lda #emptysprite
			sta spritepointer+7
pst98			playstack 98			;stable 105@55 write backwards
			delay 12

			ldy #[>[screen1-vicbase]<<2] | [>[charset3-vicbase]>>2]	;2
pst97			playstack 97			;stable 106@36 write backwards
stable5			dec $d011			;write at line 106 cycle 54/48
			sty $d018
			ldy logo1pos
			perscrbyte 24
			perscrbyte 25
			perscrbyte 26
			
pst96			playstack 96			;stable 107@39 write backwards
			perscrbyte 27
			perscrbyte 28
			perscrbyte 29
			delay 3
			
ps95			playstack 95			;stable 108@36 write backwards
stable6			inc $d011			;write at line 108 cycle 54/48
			perscrbyte 30
			perscrbyte 31
			perscrbyte 32
			delay 5

pst94			playstack 94			;stable 109@39 write backwards
			perscrbyte 33
			perscrbyte 34
			perscrbyte 35
			perscrbyte 36
			
pst93			playstack 93			;stable 110@39 write backwards
			perscrbyte 37
			perscrbyte 38
			percolbyte 0
			percolbyte 1
			
pst92			playstack 92			;stable 111@39 write backwards
			percolbyte 2
			percolbyte 3
			percolbyte 4
			percolbyte 5
			
pst91			playstack 91			;stable 112@39 write backwards
			percolbyte 6
			percolbyte 7
			percolbyte 8
			percolbyte 9
			
pst90			playstack 90			;stable 113@39 write backwards
			percolbyte 10
			percolbyte 11
			percolbyte 12
			delay 3
			
			ldy #[>[screen1-vicbase]<<2] | [>[charset4-vicbase]>>2]	;2
pst89			playstack 89			;stable 114@36 write backwards

stable7			dec $d011			;write at line 114 cycle 54/48
			sty $d018
			ldy logo1pos
			percolbyte 13
			percolbyte 14
			delay 5
			
pst88			playstack 88			;stable 115@39 write backwards
			percolbyte 15
			percolbyte 16
			percolbyte 17
			delay 6
			
pst87			playstack 87			;stable 116@36 write backwards
stable8			inc $d011			;write at line 116 cycle 54/48
			percolbyte 18
			percolbyte 19
			percolbyte 20
			delay 5
			
pst86			playstack 86			;stable 117q39 write backwards
			percolbyte 21
			percolbyte 22
			percolbyte 23
			percolbyte 24
			
pst85			playstack 85			;stable 118@39 write backwards
			percolbyte 25
			percolbyte 26
			percolbyte 27
			percolbyte 28

pst84			playstack 84			;stable 119@39 write backwards
			percolbyte 29
			percolbyte 30
			percolbyte 31
			percolbyte 32
			
pst83			playstack 83			;stable 120@39 write backwards
			percolbyte 33
			percolbyte 34
			percolbyte 35
			percolbyte 36

pst82			playstack 82			;stable 121@39 write backwards
			percolbyte 37
			percolbyte 38
			delay 11
			
			ldy #[>[screen1-vicbase]<<2] | [>[charset5-vicbase]>>2]	;2
pst81			playstack 81			;stable 122@36 write backwards

stable9			dec $d011			;write at line 122 cycle 54/48
			sty $d018
			delay 25
			
pst80			playstack 80			;stable 123@39 write backwards
			delay 29
pst79			playstack 79			;stable 124@36 write backwards
stable10		inc $d011			;write at line 124 cycle 54/48
			delay 29
pst78			playstack 78			;stable 125q39 write backwards
			delay 32
pst77			playstack 77			;stable 126@39 write backwards
stable10a
fadeslice2c		lda #$00			;$0c stable 126@62
			sta $d021
			sta $d022
			sta $d023
			sta $d024
			delay 33
			
pst76			playstack 76			;stable 127@39 write backwards
			flashchar2 2,58-15,7		;x offset 58 length 7
pst75			playstack 75			;stable 128@39 write backwards
			flashchar2 6,86-15,7		;v offset 86 length 7
pst74			playstack 74			;stable 129@39 write backwards
			flashchar2 3,65-15,6		;t offset 65 length 6
			delay 4
pst73			playstack 73			;stable 130@39 write backwards
			delay 24
pst72			playstack 72			;stable 131@55 write backwards 131 badline
			delay 35
pst71			playstack 71			;stable 132@39 write backwards
			flashchar2 0,46-15,6		;n offset 46 length 6
			delay 4
pst70			playstack 70			;stable 133@39 write backwards
			delay 8
fadeslice3		lda #$00			;$01
			sta $d020
			sta $d021
			delay 33
pst69			playstack 69			;stable 134@39 write backwards
			delay 8
			lda #scrollbgcol
			sta $d020
			sta $d021
			delay 33
pst68			playstack 68			;stable 135@39 write backwards
			flashchar1 9,102-15,6		;s offset 102 length 6
			delay 4
pst67			playstack 67			;stable 136@39 write backwards
			flashchar1 8,95-15,6		;r offset 95 length 6
			delay 4
pst66			playstack 66			;stable 137@39 write backwards
			flashchar1 6,82-15,6		;m offset 82 length 6
			delay 4
			
pst65			playstack 65			;stable 138@39 write backwards
col00			lda #$01
			sta $d021
			lda #[>[screen1-vicbase]<<2] | [>[font0-vicbase]>>2]	;2
			sta $d018
			lda #$1b
			sta $d011
scrollreg3		lda #$00			;textscroller
			sta $d016
col01			lda #$02
			sta $d021
pst64			playstack 64			;stable 139@60 write backwards 139 badline
			delay 30
pst63			playstack 63			;stable 140@39 write backwards
col02			lda #$03
			sta $d021
			flashchar2 8,99-15,5		;l offset 99 length 5
			delay 2
pst62			playstack 62			;stable 141@39 write backwards
col03			lda #$04
			sta $d021
			flashchar2 7,93-15,5		;e offset 93 length 5
			delay 2
pst61			playstack 61			;stable 142@39 write backwards
col04			lda #$05
			sta $d021
			flashchar2 5,81-15,5		;e offset 81 length 5
			delay 2
pst60			playstack 60			;stable 143@39 write backwards
col05			lda #$06
			sta $d021
			flashchar2 4,75-15,5		;l offset 75 length 5
			delay 2
pst59			playstack 59			;stable 144@39 write backwards
col06			lda #$07
			sta $d021
testp			flashchar1 0,42-15,5		;p offset 42 length 6
			delay 2
pst58			playstack 58			;stable 145@39 write backwards
col07			lda #$08
			sta $d021
			
			lda flashtable,y
			sta colorline0+42-15+5
			
			delay 32
			
			ldy #[>[screen1-vicbase]<<2] | [>[font1-vicbase]>>2]	;2
pst57			playstack 57			;stable 146@36 write backwards
stable11		dec $d011			;write at line 146 cycle 54/48
			sty $d018
col08			lda #$09
			sta $d021
			delay 38
pst56			playstack 56			;stable 147@39 write backwards
col09			lda #$0a
			sta $d021
			delay 42
pst55			playstack 55			;stable 148@36 write backwards
stable12		inc $d011			;write at line 148 cycle 54/48
col10			lda #$0b
			sta $d021
			delay 42
pst54			playstack 54			;stable 149@39 write backwards
col11			lda #$0c
			sta $d021
			flashchar2 1,53-15,5		;e offset 53 length 5
			delay 2
pst53			playstack 53			;stable 150@39 write backwards
col12			lda #$0d
			sta $d021
			flashchar1 7,89-15,5		;e offset 89 length 5
			delay 2
pst52			playstack 52			;stable 151@39 write backwards
col13			lda #$0e
			sta $d021
			flashchar1 1,49-15,5		;e offset 49 length 5
			delay 2
pst51			playstack 51			;stable 152@39 write backwards
col14			lda #$0f
			sta $d021
			flashchar1 2,55-15,5 		;r offset 55 length 6 
			delay 2
pst50			playstack 50			;stable 153@39 write backwards
col15			lda #$00
			sta $d021
			lda flashtable,y
			sta colorline0+55-15+5
			delay 32
			
			ldy #[>[screen1-vicbase]<<2] | [>[font2-vicbase]>>2]	;2
pst49			playstack 49			;stable 154@36 write backwards
stable13		dec $d011			;write at line 154 cycle 54/48
			sty $d018
col16			lda #$01
			sta $d021
			delay 38
pst48			playstack 48			;stable 155@39 write backwards
col17			lda #$02
			sta $d021
			delay 42
pst47			playstack 47			;stable 156@36 write backwards
stable14		inc $d011			;write at line 156 cycle 54/48
col18			lda #$03
			sta $d021
			delay 42
pst46			playstack 46			;stable 157@39 write backwards
col19			lda #$04
			sta $d021
			flashchar1 3,62-15,5		;f offset 62 length 6
			delay 2
pst45			playstack 45			;stable 158@39 write backwards
col20			lda #$05
			sta $d021
			lda flashtable,y
			sta colorline0+62-15+5
			delay 37
pst44			playstack 44			;stable 159@39 write backwards
col21			lda #$06
			sta $d021
			delay 45
pst43			playstack 43			;stable 160@39 write backwards
col22			lda #$07
			sta $d021
			delay 45
pst42			playstack 42			;stable 161@39 write backwards
col23			lda #$08
			sta $d021
			delay 45
pst41			playstack 41			;stable 162@39 write backwards
			lda #scrollbgcol
			sta $d021
			delay 18
pst40			playstack 40			;stable 163@55 write backwards 163 badline
			delay 35
pst39			playstack 39			;stable 164@39 write backwards
			flashchar1 5,75-15,6		;r offset 75 length 6
			delay 4
pst38			playstack 38			;stable 165@39 write backwards
			flashchar1 4,68-15,6		;o offset 68 length 6
			delay 4
pst37			playstack 37			;stable 166@39 write backwards
			delay 7
fadeslice4		lda #$00			;$01
			sta $d020
			sta $d021
fadeslice5a		lda #$00			;$0a
			sta $d027
			sta $d028
			sta $d029
			sta $d02a
			sta $d02b
			sta $d02c
			sta $d02d
			sta $d02e
			
			
pst36			playstack 36			;stable 167@39 write backwards
			delay 8
fadeslice5b		lda #$00			;$0a
			sta $d020
			sta $d021
			sta $d022
			sta $d023
			sta $d024
			
scrollreg2		lda #$00
			sta $d016

			ldx stack+31
			lda d418tab,x
			sta pst31+1

			delay 3
pst35			playstack 35			;stable 168@39
			lda #$54+$58
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f
sprx6			lda #$00
			sta $d00c
sprx7			lda #$00
			sta $d00e
			delay 5

pst34			playstack 34			;stable 169@39

sprl2p0			lda #emptysprite
			sta spritepointer+0
sprl2p1			lda #emptysprite
			sta spritepointer+1
sprl2p2			lda #emptysprite
			sta spritepointer+2
sprl2p3			lda #emptysprite
			sta spritepointer+3
sprl2p4			lda #emptysprite
			sta spritepointer+4
sprl2p5			lda #emptysprite
			sta spritepointer+5
sprl2p6			lda #emptysprite
			sta spritepointer+6
sprl2p7			lda #emptysprite
			sta spritepointer+7
			
			delay 3
pst33			playstack 33			;stable 170@39

sprxhi			lda #$00
			sta $d010
;2nd logo badline start
			lda #[>[screen1-vicbase]<<2] | [>[charset0-vicbase]>>2]	;2
			sta $d018
			ldx #$5b
			stx $d011
sprx0			lda #$00
			sta $d000
			nop
			
pst32			playstack 32			;stable 171@56 171 badline 
sprx1			lda #$00
			sta $d002
sprx2			lda #$00
			sta $d004
sprx3			lda #$00
			sta $d006
sprx4			lda #$00
			sta $d008
sprx5			lda #$00
			sta $d00a
			delay 4

pst31			lda #$00			;playstack 31			;stable 172@40
fadeslice5e		ldy #$00			;$07
fadeslice5d		ldx #$00			;$01
			sta $d418
			delay 4
			sty $d022			;store @ cycle 55
			stx $d021
fadeslice5g		lda #$00			;$0f
			sta $d024
fadeslice5f		lda #$00			;$04		
			sta $d023
			
			ldy logo2pos
			nexscrbyte 0
			
pst30			playstack 30			;stable 173@39

			lda #$54+$58+21
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f
			
pst29			playstack 29			;stable 174@41
			nexscrbyte 1
			nexscrbyte 2
			nexscrbyte 3
			nexscrbyte 4
			
pst28			playstack 28			;stable 175@41			
			nexscrbyte 5
			nexscrbyte 6
			nexscrbyte 7
			nexscrbyte 8

pst27			playstack 27			;stable 176@41			
			nexscrbyte 9
			nexscrbyte 10
			nexscrbyte 11
			nexscrbyte 12

pst26			playstack 26			;stable 177@41
			nexscrbyte 13
			nexscrbyte 14
			delay 9

			ldy #[>[screen1-vicbase]<<2] | [>[charset1-vicbase]>>2]	;2
pst25			playstack 25			;stable 178@36

stable1b		dec $d011			;write at line 178 cycle 54/48
			sty $d018
			ldy logo2pos
			nexscrbyte 15
			nexscrbyte 16
			delay 6

pst24			playstack 24			;stable 179@43
			nexscrbyte 17
			nexscrbyte 18
			nexscrbyte 19
			delay 5
pst23			playstack 23			;stable 180@36

stable2b		inc $d011			;write at line 180 cycle 54/48
			nexscrbyte 20
			nexscrbyte 21
			nexscrbyte 22
			delay 5
			
pst22			playstack 22			;stable 181@39
			nexscrbyte 23
			nexscrbyte 24
			nexscrbyte 25
			nexscrbyte 26
			
pst21			playstack 21			;stable 182@39
			nexscrbyte 27
			nexscrbyte 28
			nexscrbyte 29
			nexscrbyte 30
			
pst20			playstack 20			;stable 183@39
			nexscrbyte 31
			nexscrbyte 32
			nexscrbyte 33
			nexscrbyte 34
			
pst19			playstack 19			;stable 184@39
			nexscrbyte 35
			nexscrbyte 36
			nexscrbyte 37
			nexscrbyte 38
			
pst18			playstack 18			;stable 185@39
			nexcolbyte 0
			nexcolbyte 1
			nexcolbyte 2
			delay 3
			
			ldy #[>[screen1-vicbase]<<2] | [>[charset2-vicbase]>>2]	;2
pst17			playstack 17			;stable 186@36

stable3b		dec $d011			;write at line 186 cycle 54/48
			sty $d018
			ldy logo2pos
			nexcolbyte 3
			nexcolbyte 4
			delay 6

pst16			playstack 16			;stable 187@39
			nexcolbyte 5
			nexcolbyte 6
			nexcolbyte 7
			delay 5
			
pst15			playstack 15			;stable 188@36 write backwards
stable4b		inc $d011			;write at line 188 cycle 54/48
			nexcolbyte 8
			nexcolbyte 9
			nexcolbyte 10
			delay 5
			
pst14			playstack 14			;stable 189@39 write backwards
			nexcolbyte 11
			nexcolbyte 12
			nexcolbyte 13
			nexcolbyte 14
			
pst13			playstack 13			;stable 190@39 write backwards
			nexcolbyte 15
			nexcolbyte 16
			nexcolbyte 17
			nexcolbyte 18
			
pst12			playstack 12			;stable 191@39 write backwards
			nexcolbyte 19
			nexcolbyte 20
			nexcolbyte 21
			nexcolbyte 22
			
pst11			playstack 11			;stable 192@39 write backwards
						
sprl3p0			lda #emptysprite
sprl3p1			ldx #emptysprite
sprl3p2			ldy #emptysprite
sync3			sta spritepointer+0		;193@17
			stx spritepointer+1
			sty spritepointer+2
sprl3p3			lda #emptysprite
			sta spritepointer+3
sprl3p4			lda #emptysprite
			sta spritepointer+4
sprl3p5			lda #emptysprite
			sta spritepointer+5
sprl3p6			lda #emptysprite
			sta spritepointer+6
sprl3p7			lda #emptysprite
			sta spritepointer+7
pst10			playstack 10			;stable 193@55 write backwards
			delay 12

			ldy #[>[screen1-vicbase]<<2] | [>[charset3-vicbase]>>2]	;2
pst9			playstack 9			;stable 194@36 write backwards
stable5b		dec $d011			;write at line 194 cycle 54/48
			sty $d018
			ldy logo2pos
			nexcolbyte 23
			nexcolbyte 24
			delay 6
			
pst8			playstack 8			;stable 195@39 write backwards
			nexcolbyte 25
			nexcolbyte 26
			nexcolbyte 27
			delay 5

pst7			playstack 7			;stable 196@36 write backwards
stable6b		inc $d011			;write at line 196 cycle 54/48
			nexcolbyte 28
			nexcolbyte 29
			nexcolbyte 30
			delay 5
			
pst6			playstack 6			;stable 197@39 write backwards
			nexcolbyte 31
			nexcolbyte 32
			nexcolbyte 33
			nexcolbyte 34
			
pst5			playstack 5			;stable 198@39 write backwards
			nexcolbyte 35
			nexcolbyte 36
			nexcolbyte 37
			nexcolbyte 38

pst4			playstack 4			;stable 199@39 write backwards
			delay 32
pst3			playstack 3			;stable 200@39 write backwards
			delay 32
pst2			playstack 2			;stable 201@39 write backwards
			delay 27
			ldy #[>[screen1-vicbase]<<2] | [>[charset4-vicbase]>>2]	;2
pst1			playstack 1			;stable 202@36 write backwards

stable7b		dec $d011			;write at line 202 cycle 54/48
			sty $d018
			delay 25
pst0			playstack 0			;stable 203@39 write backwards
			delay 33

;switch to play from 2nd half of mixingbuffer beginning hat offset 52
ps52			playsample 52			;stable 204@40 write backwards
stable8b		inc $d011			;write at line 204 cycle 54/48
			delay 33
ps53			playsample 53			;stable 205@43 write backwards
			delay 36
ps54			playsample 54			;stable 206@41 write backwards
			delay 36
ps55			playsample 55			;stable 207@41 write backwards
			delay 36
ps56			playsample 56			;stable 208@41 write backwards
			delay 36
ps57			playsample 57			;stable 209@41 write backwards
			delay 33
			ldy #[>[screen1-vicbase]<<2] | [>[charset5-vicbase]>>2]	;2
ps58			playsample 58			;stable 210@40 write backwards

stable9b		dec $d011			;write at line 210 cycle 54/48
			sty $d018
			delay 29
ps59			playsample 59			;stable 211@43 write backwards
			delay 33
ps60			playsample 60			;stable 212@40 write backwards
stable10b		inc $d011			;write at line 212 cycle 54/48
	
			delay 33
			
ps61			playsample 61			;stable 213@43 write backwards
			ldy sineptr2
			ldx #%00000111
			lda sinesprhiscrlo,y
			sax scrollreg2+1
			lsr
			lsr
			lsr
			tay
			delay 15
			
ps62			playsample 62			;stable 214@43 write backwards
stable10ab
fadeslice5c		lda #$00			;$0a stable 214@62
			sta $d021
			sta $d022
			sta $d023
			sta $d024
			lda spritemap2,y
			sta sprl2p0+1
			lda spritemap2+1,y
			sta sprl2p1+1
			lda spritemap2+2,y
			sta sprl2p2+1
			lda spritemap2+3,y
			sta sprl2p3+1
			delay 4
			
ps63			playsample 63			;stable 215@42 write backwards
			lda spritemap2+4,y
			sta sprl2p4+1
			lda spritemap2+5,y
			sta sprl2p5+1
			lda spritemap2+6,y
			sta sprl2p6+1
			lda spritemap2+7,y
			sta sprl2p7+1
			
			lda spritemap3,y
			sta sprl3p0+1
			lda spritemap3+1,y
			sta sprl3p1+1
			lda spritemap3+2,y
			sta sprl3p2+1

ps64			playsample 64			;stable 216@43 write backwards
			lda spritemap3+3,y
			sta sprl3p3+1
			lda spritemap3+4,y
			sta sprl3p4+1
			lda spritemap3+5,y
			sta sprl3p5+1
			lda spritemap3+6,y
			sta sprl3p6+1
			lda spritemap3+7,y
			sta sprl3p7+1

			ldy sineptr2
			lda sinesprlo,y
			sta sinesprlo2
			delay 5
			
ps65			playsample 65			;stable 217@43 write backwards
			iny
			sty sineptr2
			
			lda sinescrhi,y		;screen needs to be one frame ahead of the rest
			sta logo2pos
			ldy sineptr1
			ldx #%00000111
			lda sinesprhiscrlo,y
			sax scrollreg1+1

			lsr
			lsr
			lsr
			tay

			lda spritemap0,y
			sta spritepointer+0
			lda spritemap0+1,y
			sta spritepointer+1
			
			delay 6
ps66			playsample 66			;stable 218@43 write backwards
			lda spritemap0+2,y
			sta spritepointer+2
			lda spritemap0+3,y
			sta spritepointer+3
			lda spritemap0+4,y
			sta spritepointer+4
			delay 4
			
ps67			playsample 67			;stable 219@58 write backwards 131 badline
			lda spritemap0+5,y
			sta spritepointer+5
			lda spritemap0+6,y
			sta spritepointer+6
			lda spritemap0+7,y
			sta spritepointer+7

			lda spritemap1,y
			sta sprl1p0+1
			lda spritemap1+1,y
			sta sprl1p1+1
			
ps68			playsample 68			;stable 220@43 write backwards
			lda spritemap1+2,y
			sta sprl1p2+1

			lda spritemap1+3,y
			sta sprl1p3+1
			lda spritemap1+4,y
			sta sprl1p4+1
			lda spritemap1+5,y
			sta sprl1p5+1
			lda spritemap1+6,y
			sta sprl1p6+1
			lda spritemap1+7,y
			sta sprl1p7+1
			
			ldy sineptr1
			lda sinesprlo,y
			sta sinesprlo1
			
ps69			playsample 69		;stable 221@46 write backwards
			iny
			sty sineptr1
fadeslice6		lda #$00		;$01
			sta $d020
			sta $d021

			lda #<mixirq
			sta $fffe
			lda #>mixirq
			sta $ffff	
			lda #mixline-mixlineoffset
			sta $d012

			lda #74			;lobyte of mixingbuffers
			sta.w fetch+1

			inc $d019
			lda sinescrhi,y		;screen needs to be one frame ahead of the rest
			sta logo1pos

ps70			playsample 70		;stable 222@43 write backwards

			ldy flashpoi
			lda globalflash0b,y	;dark grey
fadeslice7		ldx #$00			;$02
			stx $d020
			stx $d021
			sta fadeslice0+1
			lda globalflash01,y	;white
			sta fadeslice1+1

			lda globalflash0c,y	;mid grey
			sta fadeslice2a+1
			sta fadeslice2b+1
			sta fadeslice2c+1
			lda globalflash01+4,y	;white
			sta fadeslice2d+1
			delay 2
			
ps71			playsample 71		;stable 223@42 write backwards
			
			lda globalflash0d,y	;light green
			sta fadeslice2e+1
			lda globalflash08,y	;orange
			sta fadeslice2f+1
			lda globalflash03,y	;orange
			sta fadeslice2g+1
			lda globalflash01+8,y	;white
			sta fadeslice3+1
			lda globalflash01+12,y	;white
			sta fadeslice4+1

			lda globalflash0a,y	;light red
			sta fadeslice5a+1
			sta fadeslice5b+1
			delay 3

ps72			ldx mixingbuffer+72	;stable 224@43 write backwards
			stx $d418

			sta fadeslice5c+1
	
			lda globalflash01+20,y	;white
			sta fadeslice5d+1
			lda globalflash07,y	;yellow
			sta fadeslice5e+1
			lda globalflash04,y	;purple
			sta fadeslice5f+1
			lda globalflash0f,y	;light grey
			sta fadeslice5g+1

			lda globalflash01+24,y	;white
			sta fadeslice6+1
			lda globalflash02,y	;red
			sta fadeslice7+1
			ldx #$00
ps73			playsample 73		;stable 225@43 write backwards

			stx $d015

			ldy rasterpoi
			dey
			bpl .nowrap
			ldy #63
.nowrap			sty rasterpoi			
			lda rastersine,y
			sta rasterpos+1

			ldy flashpoi

			ldx #$81
			stx $dd0d			;nmi kicks in and plays @ line 226 cylce ~47

test			lda fadeflag
			beq .nofade
			bpl .fadein

.fadeout		dey
			bpl .store1
;			ifconst  release
			sty endflag+1
;			endif
			iny
			sty $d01a
			lda #$7f
			sta $dd0d
			lda $dd0d
			jmp .nofade
			
.fadein			iny
			cpy #$2c
			bne .store1
			lda #$00
			sta fadeflag
			dey
.store1			sty flashpoi

.nofade
;scroller code
			lda copyflag
.branchflag		beq .nonewtext

.columnptr		ldx #$02
			inx
.columnsize		cpx #$03
			bne .goon
.charptr		lda scrolltext
			bpl .goon2
			lda #$01
			sta copyflag
			lda #$40
			sta scrollline+39
			lda #.noscroll-.columnptr
			sta .branchflag+1
			bne .noscroll

.goon2			;sec			;carry is set by cpx #3 and beq -> carry set
			sbc #$20
			tay
			ldx charsizes,y
			stx .columnsize+1
			ldx #$00

			inc .charptr+1
			bne .skip
			inc .charptr+2

.skip			sta curchar
			clc
.goon
			stx .columnptr+1
			txa
			adc curchar
			adc curchar
			adc curchar
			tax
			lda charmap,x
			ora #$40
			sta scrollline+39

.nonewtext		lax finescroll
			sta scrollreg3+1
			asr #4
			lsr
			sta copyflag
			txa
			eor #$04
			sta finescroll
.noscroll
;-----------------------
;position sprite logo 1 x
			lax sinesprlo1
			ldy #%11000000
			;clc
			sbc #$17
			bcs .noset1
			iny
			;ldy #%11000001
			;sec
			sbc #$07
			cmp #$e0
			bcs .noset1
			lda #$e0
.noset1			sta $d000

			lda #$ff
			sbx #-$18
			stx $d002
			sbx #-$30
			stx $d004
			sbx #-$30
			stx $d006
			sbx #-$30
			stx $d008
			sbx #-$30
			stx $d00a
			bcc .noset2
			ldy #%11100000
.noset2
			sbx #-$30
			stx $d00c
			sbx #-$30
			cpx #$58
			bcc .noset3
			clc
			ldx #$58
.noset3			stx $d00e
			sty $d010

;-----------------------
;position sprite logo 2 x
			lax sinesprlo2
			ldy #%11000000
			;clc sec
			sbc #$17
			bcs .noset1b
			;ldy #%11000001
			iny
			;clcsec
			sbc #$07
			cmp #$e0
			bcs .noset1b
			lda #$e0
.noset1b		sta sprx0+1

			lda #$ff
			sbx #-$18
			stx sprx1+1
			sbx #-$30
			stx sprx2+1
			sbx #-$30
			stx sprx3+1
			sbx #-$30
			stx sprx4+1
			sbx #-$30
			stx sprx5+1
			bcc .noset2b
			ldy #%11100000
.noset2b
			sbx #-$30
			stx sprx6+1
			sbx #-$30
			cpx #$58
			bcc .noset3b
			ldx #$58
.noset3b		stx sprx7+1
			sty sprxhi+1
			
			; lda #$04
			; sta $d020
			; lda #$03
			; sta $d021

			lda areg
			ldx xreg
			ldy yreg
			rti
			
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
.fetchbyte		lax $beef,y			;if positive -> lz sequence
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
;			beq .end			;end check can be removed for modplayer
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
			sta notefetch{1}a+1
			sta notefetch{1}b+1
			lda notestablehi,x
			sta notefetch{1}a+2
			sta notefetch{1}b+2
			
			if playinterleave=0
			inc period{1}datapointer+1
			bne .volumedepack
			inc period{1}datapointer+2
			bne .volumedepack
			else
			jmp .volumedepack
			endif
			
			if {1}=1
.endofsong		lda #$60		;rtrs
			sta replayer
			dec fadeflag
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
			; if replayrate>1
			; sta mix{1}g+2
			; sta mix{1}h+2
			; endif

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
			ldx fadeflag
			bne .faderunning

;$12 triggers next and $15 triggers level
;$17 - PER $18 - FOR $19 - MERS

			tax
			lda sampleslots,x
			beq .faderunning
			bmi .nextlevel
			cmp #$10
			beq .per
			cmp #$20
			beq .for
			cmp #$30
			bne .nospeech1
			
.mers			lda #$0f
			sta logo1col6
			sta logo1col7
			sta logo1col8
			sta logo1col9
			bne .faderunning
			
.per			lda #$0f
			sta logo1col0
			sta logo1col1
			sta logo1col2
			bne .faderunning

.for			lda #$0f
			sta logo1col3
			sta logo1col4
			sta logo1col5
			bne .faderunning

.nospeech1		sta .add1+1

			ldx logo1pos
			lda peroffsets-$13,x
			clc
.add1			adc #$00
			tax
			lda #$0f
			sta logo1col0,x
			bne .faderunning

.nextlevel		and #%01111111
			cmp #$10
			beq .next
			cmp #$20
			bne .nospeech2
.level			lda #$0f
			sta logo2col4
			sta logo2col5
			sta logo2col6
			sta logo2col7
			sta logo2col8
			bne .faderunning
.next			lda #$0f
			sta logo2col0
			sta logo2col1
			sta logo2col2
			sta logo2col3
			bne .faderunning
			
.nospeech2		sta .add2+1

			ldx logo2pos
			lda nexoffsets-$13,x
			clc
.add2			adc #$00
			tax
			lda #$0f
			sta logo2col0,x
.faderunning		ldx sound{1}+1
;------------------------------------------------------------------------------
			
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
			; if replayrate>1
; .stopvoice7		stx samplefetch{1}g+1
			; sta samplefetch{1}g+2
; .stopvoice8		stx samplefetch{1}h+1
			; sta samplefetch{1}h+2
			; endif
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
			
			; if replayrate=0
			; lda samplefetch{1}d+1
			; adc notesaddlo,x
			; sta samplefetch{1}a+1
			; lda samplefetch{1}d+2
			; adc #$00
			; sta samplefetch{1}a+2
			; endif
			
;			if replayrate=1
			lda samplefetch{1}f+1
			adc notesaddlo,x
			sta samplefetch{1}a+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}a+2
;			endif

			; if replayrate=2
			; lda samplefetch{1}h+1
			; adc notesaddlo,x
			; sta samplefetch{1}a+1
			; lda samplefetch{1}h+2
			; adc #$00
			; sta samplefetch{1}a+2
			; endif
			
			else	;{3}=0

			; if replayrate=0
			; lda samplefetch{1}d+1
			; clc
			; adc #periodsteplength
			; sta samplefetch{1}a+1
			; lda samplefetch{1}d+2
			; adc #$00
			; sta samplefetch{1}a+2
			; endif

;			if replayrate=1
			lda samplefetch{1}f+1
			clc
			adc #periodsteplength
			sta samplefetch{1}a+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}a+2
;			endif
			; if replayrate=2
			; lda samplefetch{1}h+1
			; clc
			; adc #periodsteplength
			; sta samplefetch{1}a+1
			; lda samplefetch{1}h+2
			; adc #$00
			; sta samplefetch{1}a+2
			; endif
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

			lda samplefetch{1}a+1		;always playing period 453
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

			if replayrate>0
			clc
;------------------------------------------------------------------------------
.preppart5		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}d+1
			adc notesaddlo,x
			sta samplefetch{1}e+1
			lda samplefetch{1}d+2
			adc #$00
			sta samplefetch{1}e+2

			else	;{3}=0

			lda samplefetch{1}d+1
			adc #periodsteplength
			sta samplefetch{1}e+1
			lda samplefetch{1}d+2
			adc #$00
			sta samplefetch{1}e+2
			endif	;{3}=0
			
			lda samplefetch{1}e+1
			cmp sampleendlo,y
			lda samplefetch{1}e+2
			sbc sampleendhi,y
			bcc .preppart6

			lda voice{1}active
			bmi .loop5

			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice5

.loop5			lda samplefetch{1}e+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}e+1
			lda samplefetch{1}e+2
			sbc looplengthhi,y
			sta samplefetch{1}e+2
			clc
;------------------------------------------------------------------------------
.preppart6		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}e+1
			adc notesaddlo,x
			sta samplefetch{1}f+1
			lda samplefetch{1}e+2
			adc #$00
			sta samplefetch{1}f+2

			else	;{3}=0

			lda samplefetch{1}e+1
			adc #periodsteplength
			sta samplefetch{1}f+1
			lda samplefetch{1}e+2
			adc #$00
			sta samplefetch{1}f+2
			endif	;{3}=0
			
			lda samplefetch{1}f+1
			cmp sampleendlo,y
			lda samplefetch{1}f+2
			sbc sampleendhi,y
			
;			if replayrate>1
;			bcc .preppart7
;			else
			bcc .nextvoice
;			endif

			lda voice{1}active
			bmi .loop6

			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice6

.loop6			lda samplefetch{1}f+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}f+1
			lda samplefetch{1}f+2
			sbc looplengthhi,y
			sta samplefetch{1}f+2
			endif	;replayrate>0
			
			; if replayrate>1
			; clc
; ;------------------------------------------------------------------------------
; .preppart7		if {3}=1
			; lda sample{1}frac
			; adc notesaddfrac,x
			; sta sample{1}frac

			; lda samplefetch{1}f+1
			; adc notesaddlo,x
			; sta samplefetch{1}g+1
			; lda samplefetch{1}f+2
			; adc #$00
			; sta samplefetch{1}g+2

			; else	;{3}=0

			; lda samplefetch{1}f+1
			; adc #periodsteplength
			; sta samplefetch{1}g+1
			; lda samplefetch{1}f+2
			; adc #$00
			; sta samplefetch{1}g+2
			; endif	;{3}=0
			
			; lda samplefetch{1}g+1
			; cmp sampleendlo,y
			; lda samplefetch{1}g+2
			; sbc sampleendhi,y
			; bcc .preppart8

			; lda voice{1}active
			; bmi .loop7

			; ldx #$00
			; lda #>silentbuffer
			; jmp .stopvoice7

; .loop7			lda samplefetch{1}g+1
			; sec
			; sbc looplengthlo,y
			; sta samplefetch{1}g+1
			; lda samplefetch{1}g+2
			; sbc looplengthhi,y
			; sta samplefetch{1}g+2
			; clc
; ;------------------------------------------------------------------------------
; .preppart8		if {3}=1
			; lda sample{1}frac
			; adc notesaddfrac,x
			; sta sample{1}frac

			; lda samplefetch{1}g+1
			; adc notesaddlo,x
			; sta samplefetch{1}h+1
			; lda samplefetch{1}g+2
			; adc #$00
			; sta samplefetch{1}h+2

			; else	;{3}=0

			; lda samplefetch{1}g+1
			; adc #periodsteplength
			; sta samplefetch{1}h+1
			; lda samplefetch{1}g+2
			; adc #$00
			; sta samplefetch{1}h+2
			; endif	;{3}=0
			
			; lda samplefetch{1}h+1
			; cmp sampleendlo,y
			; lda samplefetch{1}h+2
			; sbc sampleendhi,y
			; bcc .nextvoice

			; lda voice{1}active
			; bmi .loop8

			; ldx #$00
			; lda #>silentbuffer
			; jmp .stopvoice8

; .loop8			lda samplefetch{1}h+1
			; sec
			; sbc looplengthlo,y
			; sta samplefetch{1}h+1
			; lda samplefetch{1}h+2
			; sbc looplengthhi,y
			; sta samplefetch{1}h+2
			; endif	;replayrate>1
			
.nextvoice		if playlzstream=1
lzsysave{1}		if digivoices={1}
			lda #$00		;last channel usa akku to save 2 cycles
			else
			ldy #$00
			endif			;digivoices={1}
			endif			;playlzstream=1
			endm
;------------------------------------------------------------------------------
			mac getfoldcontrol
controldelay		ldy #$00
			bne .exitvolumedelay
			
controldatapointer	lax $1000
			bpl .setcommand

			and #%01111111
			sta controldelay+1
			jmp .exit2

.setcommand		clc
			adc #>d418tab-1
			sta volget1+2
			sta volget2+2
			sta volget3+2
			sta volget4+2
			
.exit2			inc controldatapointer+1
			bne .exit
			inc controldatapointer+2
			bne .exit
				
.exitvolumedelay	dey
			sty controldelay+1
.exit
			endm
;------------------------------------------------------------------------------
replayer		subroutine
;------------------------------------------------------------------------------
;{1}=voice number
;{2]=0 - volume off 1=volume on
;{3}=0 - period always 453 1 - periods on
;{4}=0 - sampleoffset off  1 - sampleoffset on
			if controlchannel=1
			if loopstation=1
			getloopcontrol
			endif
			if volumeboost=9
			getfoldcontrol
			endif
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
			echo "Songend: ",*

			     ;01234567890123456789
scrolltext		text "                    "

			text "we're not here to sleep...    so dance and shake your boobies!!!    "
			text "15,6khz mixing power honoring "
			text "the life and work of maxi jazz. he will be missed like many others. "
			text "seeing friends and heroes go... that's the price of getting older. "
			text "nobody knows when time's up, but we shall meet again in the next level! "
			text "as kids the world couldn't have been better. working on a demo with friends is like "
			text "reliving the good times. "
			text "and never forget: performers don't use vsp..."
			text "                            "
			echo "Dataend before $cf80: ",*
	
			org $cf80
d418tab6581		include "Volumetables/volume_table_common_6581_096_of_128.s"
			echo "end of 6581: ", *
			
;------------------------------------------------------------------------------
;gfx
;------------------------------------------------------------------------------
			org charset0		;$d000
i			set 0
			repeat 64
			incbin "gfx/ECM-Samplepartgfx-chars.chr",i*48,8
i			set i+1
			repend
			
			org font0		;$d200
i			set 0
			repeat 64
			incbin "gfx/font.chr",i*24,8
i			set i+1
			repend

			org spritedata0		;$d400
			incbin "gfx/ECM-Samplepartgfx-sprites.spr",0,16*64
			
			org charset1		;$d800
i			set 0
			repeat 64
			incbin "gfx/ECM-Samplepartgfx-chars.chr",i*48+8,8
i			set i+1
			repend

			org font1		;$da00
i			set 0
			repeat 64
			incbin "gfx/font.chr",i*24+8,8
i			set i+1
			repend
			
			org spritedata1		;$dc00
			incbin "gfx/ECM-Samplepartgfx-sprites.spr",16*64,16*64
			
			org charset2		;$e000
i			set 0
			repeat 64
			incbin "gfx/ECM-Samplepartgfx-chars.chr",i*48+16,8
i			set i+1
			repend

			org font2		;$e200
i			set 0
			repeat 64
			incbin "gfx/font.chr",i*24+16,8
i			set i+1
			repend

			org spritedata2		;$e400
			incbin "gfx/ECM-Samplepartgfx-sprites.spr",32*64,16*64

;$1b und niedriger $00
peroffsets		hex 00 00	;offsets $13-$1a, load table with -$13

			hex 00 00 00 00 00 00 00		;p offset 42-15 length 6	$1b
			hex 01 01 01 01 01 01			;e offset 49-15 length 5
			hex 02 02 02 02 02 02 02 		;r offset 55-15 length 6 
			hex 03 03 03 03 03 03 			;f offset 62-15 length 6 kein Leerzeichen!
			hex 04 04 04 04 04 04 04		;o offset 68-15 length 6
			hex 05 05 05 05 05 05 			;r offset 75-15 length 6
								;67 values, $13-$3b sine hi

nexoffsets		hex 00 00 00 00 00 00 00 
			hex 00 00 00 00 00 00 00		;n offset 46-15 length 6
			hex 01 01 01 01 01 01			;e offset 53-15 length 5
			hex 02 02 02 02 02 02 02 02 		;x offset 58-15 length 7
			hex 03 03 03 03 03 03 03 03 	  	;t offset 65-15 length 6
			hex 04 04 04 04 04 04 			;l offset 75-15 length 5

; 2-6 control performers
; 7-16 control next level
;$17 - PER $18 - FOR $19 - MERS
			;   00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 
sampleslots		hex 00 00 01 02 03 04 05 81 82 83 84 81 82 83 84 81
			;   16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
			hex 82 00 90 00 00 a0 00 10 20 30 00 00 00 00 00 00


;------------------------------------------------------------------------------
initsid			subroutine
;------------------------------------------------------------------------------
			ifconst release
			lda link_chip_types
			else
			lda #$01		;$00 old sid $01 new sid
			endif
			and #%00000001
			bne .newsid

			ldx #$7f
.copyloop2		lda d418tab6581,x
			sta d418tab,x
			dex
			bpl .copyloop2

.newsid			jsr clearsid

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

			align 256,0
sinesprhiscrlo
 hex 494949494A4A4B4B 4C4D4E4F48494A4C 4D4F494A4C4E484A 4C4F494B4E484346 4043464144474246 41444043463A3E39 3D383C383C3F3B3F 3B3F333733373236
 hex 3236323632362A2E 2A2E292D292D282C 282B2F2226212520 2326222520232620 2326191B1E181A1D 1F191B1D1F181A1C 1D1E18191A1B1C1D 1E1E1F1F18181818
 hex 1818181F1F1E1E1D 1C1B1A19181F1D1C 1A191F1D1B191F1D 1B181E1B19262421 2623202522272420 252226232F2C282C 292D292E2A2E2A2E 2A36333733373337
 hex 33373337333F3B38 3C383C383D393D3A 3E3A474340454146 4340444146444146 43414E4C494F4D4A 484E4C4A494F4D4C 4B49484F4E4D4C4B 4B4A4A4949494949


			; align 256,0
; sinesprhiscrlo
 ; hex 8F8F8F8F8F8F8F8F 898C8E898C8F8B8E 8A8F8B8885828785 838187867C7B7A7A 7979717171717273 6B6C6D6F68626365 67615B5D5F595C56 515356504B4E484B
 ; hex 46404345403B3D38 3A3537313336282A 2B2D2F2022232425 1E1F1F1818181017 171615140B09080E 0C090F0C01060206 0206020500030507 0103050607070000
 ; hex 0000070605030200 0503000502070307 0306020D0F0A0C0F 090A0C1516171010 1111191918181F26 25242321282E2D2B 2937353230363B39 3E3C39474441474C
 ; hex 494F4C4A57545257 5D5B585E5C626066 646369686F6D6C74 73727272727A7A7B 7B7C7D8680828386 808285888C8F8B8F 8B8F8C898E8C8A88 8F8F8F8F8F8F8F8F
			
			org charset3		;$e800
i			set 0
			repeat 64
			incbin "gfx/ECM-Samplepartgfx-chars.chr",i*48+24,8
i			set i+1
			repend
			
			org charset4		;$f000
i			set 0
			repeat 64
			incbin "gfx/ECM-Samplepartgfx-chars.chr",i*48+32,8
i			set i+1
			repend
			
			org charset5		;$f800
i			set 0
			repeat 64
			incbin "gfx/ECM-Samplepartgfx-chars.chr",i*48+40,8
i			set i+1
			repend
		
			
;------------------------------------------------------------------------------
;disposable stuff starts here
;------------------------------------------------------------------------------
			org $eb00
rastercolors
			;bright
			dc.b $0d, $03, $03, $03, $03, $0d, $01, $01, $01, $01, $01, $01, $0f, $0a, $0a, $0a, $0a, $0f, $01, $01, $01, $01, $01, $01
			dc.b $0d, $03, $03, $03, $03, $0d, $01, $01, $01, $01, $01, $01, $0f, $0a, $0a, $0a, $0a, $0f, $01, $01, $01, $01, $01, $01

			;slightly darker
			dc.b $03, $05, $05, $05, $05, $03, $0d, $0d, $0d, $0d, $0d, $0d, $0a, $0c, $0c, $0c, $0c, $0a, $0d, $0d, $0d, $0d, $0d, $0d
			dc.b $03, $05, $05, $05, $05, $03, $0d, $0d, $0d, $0d, $0d, $0d, $0a, $0c, $0c, $0c, $0c, $0a, $0d, $0d, $0d, $0d, $0d, $0d

			;darker
			dc.b $05, $0c, $0c, $0c, $0c, $05, $0f, $0f, $0f, $0f, $0f, $0f, $0c, $08, $08, $08, $08, $0c, $0f, $0f, $0f, $0f, $0f, $0f
			dc.b $05, $0c, $0c, $0c, $0c, $05, $0f, $0f, $0f, $0f, $0f, $0f, $0c, $08, $08, $08, $08, $0c, $0f, $0f, $0f, $0f, $0f, $0f

			;yet darker
			dc.b $0c, $0b, $0b, $0b, $0b, $0c, $0c, $0c, $0c, $0c, $0c, $0c, $08, $02, $02, $02, $02, $08, $0c, $0c, $0c, $0c, $0c, $0c
			dc.b $0c, $0b, $0b, $0b, $0b, $0c, $0c, $0c, $0c, $0c, $0c, $0c, $08, $02, $02, $02, $02, $08, $0c, $0c, $0c, $0c, $0c, $0c

			;darkest
			dc.b $0b, $09, $09, $09, $09, $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, $09, $09, $09, $09, $0b, $0b, $0b, $0b, $0b, $0b, $0b
			dc.b $0b, $09, $09, $09, $09, $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, $09, $09, $09, $09, $0b, $0b, $0b, $0b, $0b, $0b, $0b			

rastersine		org $ec34		;$ec00-$ec33 reserved for last period
			dc.b 12,10,9,8,7,6,5,4,3,2,1,1,0,0,0,0
			dc.b 0,0,0,0,1,1,2,3,3,4,5,6,7,9,10,11
			dc.b 12,13,14,16,17,18,19,20,20,21,22,22,23,23,23,23
			dc.b 23,23,23,23,22,22,21,20,19,18,17,16,15,14,13,12

			org $ec80
			echo "Sampleheaderstart: ",*
			include "thc_sampleheader.asm"

			echo "Songstart: ",*
			include "thc_init.asm"
			echo "end of songdata before $ee00: ", *
			
			org $ee00
			
			align 256,0
sinesprlo
 hex 090909090A0A0B0B 0C0D0E0F10111214 1517191A1C1E2022 2427292B2E300306 080B0E1114171A1E 2124282B2E020609 0D1014181C1F2327 2B2F03070B0F1216
 hex 1A1E22262A2E0206 0A0E1115191D2024 282B2F0206090D10 13161A1D20232628 2B2E010306080A0D 0F11131517181A1C 1D1E202122232425 2626272728282828
 hex 2828282727262625 24232221201F1D1C 1A19171513110F0D 0B080603012E2C29 2623201D1A171410 0D0A06032F2C2824 211D1916120E0A06 022E2B27231F1B17
 hex 130F0B07032F2B28 24201C1815110D0A 06022F2B2825211E 1B1814110E0C0906 03012E2C29272522 201E1C1A19171514 1311100F0E0D0C0B 0B0A0A0909090909


			align 256,0
sinescrhi
 hex 3B3B3B3B3B3B3B3B 3B3B3B3B3A3A3A3A 3A3A393939393838 3838373737363636 3535353434343333 323231313130302F 2F2E2E2D2D2D2C2C 2B2B2A2A29292828
 hex 2727262625252424 2323222221212020 1F1F1F1E1E1D1D1C 1C1C1B1B1A1A1A19 1919181818171717 1716161616151515 1515141414141414 1414141413131313
 hex 1313131414141414 1414141414151515 1515161616161717 1717181818191919 1A1A1A1B1B1C1C1C 1D1D1E1E1F1F1F20 2021212222232324 2425252626272728
 hex 2829292A2A2B2B2B 2C2C2D2D2E2E2F2F 3030313131323233 3333343435353536 3636373737383838 38393939393A3A3A 3A3A3A3B3B3B3B3B 3B3B3B3B3B3B3B3B
			
 		
			org sidfile		;$f200
			incbin "../../music/JammicroV1_FaithlessInsomniaPRG.prg",2
			echo "End of Sidfile ",*
			
			org screen1
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
			
javarestart		subroutine
			ldx #$00
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
			sta lzsrepeat+1		;clear index
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
;------------------------------------------------------------------------------
initscreen		subroutine
;------------------------------------------------------------------------------
			lda #$00
			ldx #clearend-clearstart-1
.loop1			sta clearstart,x
			dex
			bpl .loop1

			tax

			if [nmi_end-nmi_start] < $100
.loop2			lda nmi_start,x
			sta.wx nmiplay,x
			inx
			cpx #nmi_end-nmi_start
			bne .loop2
			
			else
.loop2			lda nmi_start,x
			sta.wx nmiplay,x
			inx
			bne .loop2

.loop2b			lda nmi_start+$100,x
			sta.wx nmiplay+$100,x
			inx
			cpx #[nmi_end-nmi_start]-$100
			bne .loop2b
			
			endif

			ldx #$00
			stx $d017
			stx $d01c
			stx $dd00
			; stx copyflag
			; stx rasterpoi
			; stx logo1pos
			; stx logo2pos
			; stx sineptr1
			dex
			stx $d01d
			stx $d01b
			
			lda #$10
			sta logo2off0
			sta logo2off1
			sta logo2off2
			sta logo2off3
			sta logo2off4
			sta logo2off5
			sta logo2off6			
			sta logo2off7
			sta logo2off8
			
			lda #$03
			sta finescroll
			
			lda #$80
;			sta sineptr2
			sta sineptr1

			lda #$01
			sta fadeflag


			; ldy #19			;adjust spritemaps
			
; .loop			lax spritemap0,y
			; and #%00110000
			; asl
			; sta .add0+1
			; txa
			; and #%00001111
			; adc #(spritedata0-vicbase)/64
; .add0			adc #$00
			; sta spritemap0,y
			
			; lax spritemap1,y
			; and #%00110000
			; asl
			; sta .add1+1
			; txa
			; and #%00001111
			; adc #(spritedata0-vicbase)/64
; .add1			adc #$00
			; sta spritemap1,y
			
			; lax spritemap2,y
			; and #%00110000
			; asl
			; sta .add2+1
			; txa
			; and #%00001111
			; adc #(spritedata0-vicbase)/64
; .add2			adc #$00
			; sta spritemap2,y
			
			; lax spritemap3,y
			; and #%00110000
			; asl
			; sta .add3+1
			; txa
			; and #%00001111
			; adc #(spritedata0-vicbase)/64
; .add3			adc #$00
			; sta spritemap3,y
			
			; dey
			; bpl .loop

			ifconst release
			ldx #$00
.stackloop		lda stackcodestart,x
			sta stackcode,x
			inx
			cpx #stackcodeend-stackcodestart
			bne .stackloop
			rts
;-----------------------
stackcodestart		
			rorg stackcode
			subroutine
			jsr link_load_next_comp
			;jsr link_load_next_comp
			jmp link_exit
			rend
stackcodeend
			else
			rts
			endif

			echo "End of Disposable: ",*


			org screen1+1000
			;	1,7,D,F,3,5,A,C,E,4,8,2,B,6,9,0	
cyclered		hex 02 04 0c 0a 07 01 01 07 0a 0c 04 02 0b 09 00 00

			org spritepointer
			ds.b 8,emptysprite
			
			org $fa00
charmap			incbin "gfx/font.scr"	;177 bytes

;font sizes
;1 char: !,',Komma,Punkt, Doppelpunkt, I
;2chars: Space, ", (, ), -,/,1,J
;3 chars: Rest
			    ;  ! " # $ % & ' ( ) * + , - . /	59 bytes
charsizes		dc.b 2,2,2,3,3,3,3,1,2,2,3,3,1,2,1,2
			   ; 0 1 2 3 4 5 6 7 8 9 : ; < = > ?
			dc.b 3,2,3,3,3,3,3,3,3,3,1,3,3,3,3,3
			   ; @ A B C D E F G H I J K L M N O
			dc.b 3,3,3,3,3,3,3,3,3,1,2,3,3,3,3,3
			   ; P Q R S T U V W X Y Z
			dc.b 3,3,3,3,3,3,3,3,3,3,3

			align 256,0			;$fb00 144 bytes
d418tab
d418tab8580		include "Volumetables/volume_table_common_8580_048_of_128.s"
			echo "end of 8580: ", *
; rastercolors
			; hex 00 00 00 09 09 09
			; hex 00 00 0b 0b 0b 00
			; hex 00 0b 0b 0b 00 00
			; hex 08 08 08 06 06 06
			; hex 0c 0c 06 06 06 0c
			; hex 0c 06 06 06 0c 0c
			; hex 0b 06 06 0f 0f 0f
			; hex 04 0b 0f 0f 0f 04
			; hex 0e 07 07 07 0e 0e
			; hex 01 01 01 0e 0e 0e
			; hex 01 01 0e 0e 0e 01
			; hex 01 0e 0e 0e 01 01
			; hex 0e 0e 0e 01 01 01
			; hex 0e 0e 01 01 01 0e
			; hex 0e 07 07 07 0e 0e
			; hex 0f 0f 0f 0e 0e 0e
			; hex 0f 0f 0e 0e 0e 0f
			; hex 0c 06 0b 04 0c 0c
			; hex 06 06 06 0c 0c 0c
			; hex 06 06 08 08 08 06
			; hex 06 0b 0b 0b 06 06
			; hex 0b 0b 0b 00 00 00
			; hex 09 09 00 00 00 09
			; hex 09 00 00 00 09 09			
			
;25 bytes for 24 sprites a 48 pixel = 1200 pixel width
; spritemap0		incbin "gfx/ECM-Samplepartgfx-sprites.map",0,20

; spritemap1		incbin "gfx/ECM-Samplepartgfx-sprites.map",20,20

; spritemap2		incbin "gfx/ECM-Samplepartgfx-sprites.map",40,20

; spritemap3		incbin "gfx/ECM-Samplepartgfx-sprites.map",60,20

spritemap0		incbin "gfx/spmap.bin",2,20

spritemap1		incbin "gfx/spmap.bin",22,20

spritemap2		incbin "gfx/spmap.bin",42,20

spritemap3		incbin "gfx/spmap.bin",62,20

flashtable		hex 00 09 0b 08 0c 03 0d 01 01 01 01 01 01 0d 03 08
			hex 00 06 0b 04 0a 0f 07 01 01 01 01 01 01 07 0a 04			

			align 256,0
charline0		incbin "gfx/ECM-Samplepartgfx-chars.scr",0,120
charline1		incbin "gfx/ECM-Samplepartgfx-chars.scr",120,120

			align 256,0
colorline0		ds.b 120,$00
colorline1		ds.b 120,$00

;			align 256,0
;	1,7,D,F,3,5,A,C,E,4,8,2,B,6,9,0	
globalflash0b		hex 00 00 00 00 00 00 00 00  00 00 00 00	;$00
			hex 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
			hex 00 06 09 02 0b 0b 0b 0b  0b 0b 0b 0b 0b 0b 0b 0b
			 
globalflash01		hex 00 00 00 00 00 00 00 00  00 00 00 00	;$04,$08,$0c,$10,$14
			hex 00 00 00 00 00 00 00 00  00 00 00 00 00 06 09 02
			hex 0b 04 08 0c 0e 05 0a 03  0f 07 0d 01 01 01 01 01
			hex 01 01 01 01 01 01 01 01  01 01 01 01 01 01 01 01
			hex 01 01 01 01 01 01 01 01
			
globalflash0c		hex 00 00 00 00 00 00 00 00  00 00 00 00	;$08
			hex 00 00 00 00 00 00 00 00  00 06 09 02 0b 04 08 0c
			hex 0c 0c 0c 0c 0c 0c 0c 0c  0c 0c 0c 0c 0c 0c 0c 0c                      

globalflash0d		hex 00 00 00 00 00 00 00 00  00 00 00 00	;$08
			hex 00 00 00 00 00 00 00 00  00 06 09 02 0b 04 08 0c
			hex 0e 05 0a 03 0f 07 0d 0d  0d 0d 0d 0d 0d 0d 0d 0d

globalflash08		hex 00 00 00 00 00 00 00 00  00 00 00 00	;$08
			hex 00 00 00 00 00 00 00 00  00 06 09 02 0b 04 08 08
			hex 08 08 08 08 08 08 08 08  08 08 08 08 08 08 08 08                      

globalflash03		hex 00 00 00 00 00 00 00 00  00 00 00 00	;$08
			hex 00 00 00 00 00 00 00 00  00 06 09 02 0b 04 08 0c
			hex 0e 05 0a 03 03 03 03 03  03 03 03 03 03 03 03 03

globalflash0a		hex 00 00 00 00 00 00 00 00  00 06 09 02	;$14
			hex 0b 04 08 0c 0e 05 0a 0a  0a 0a 0a 0a 0a 0a 0a 0a
			hex 0a 0a 0a 0a 0a 0a 0a 0a  0a 0a 0a 0a 0a 0a 0a 0a

globalflash07		hex 00 00 00 00 00 00 00 00  00 06 09 02	;$14
			hex 0b 04 08 0c 0e 05 0a 03  0f 07 07 07 07 07 07 07
			hex 07 07 07 07 07 07 07 07  07 07 07 07 07 07 07 07

globalflash0f		hex 00 00 00 00 00 00 00 00  00 06 09 02	;$14
			hex 0b 04 08 0c 0e 05 0a 03  0f 0f 0f 0f 0f 0f 0f 0f
			hex 0f 0f 0f 0f 0f 0f 0f 0f  0f 0f 0f 0f 0f 0f 0f 0f

globalflash04		hex 00 00 00 00 00 00 00 00  00 06 09 02	;$14
			hex 0b 04 04 04 04 04 04 04  04 04 04 04 04 04 04 04
			hex 04 04 04 04 04 04 04 04  04 04 04 04 04 04 04 04

globalflash02		hex 00 06 09 02 02 02 02 02  02 02 02 02 	;$1c
			hex 02 02 02 02 02 02 02 02  02 02 02 02 02 02 02 02
			hex 02 02 02 02 02 02 02 02  02 02 02 02 02 02 02 02

			echo "End of memory: ",*


