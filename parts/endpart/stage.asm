			processor 6502
			incdir "../../util/dasm/include"
			include "standard.asm"

;to do:
;interleave animations to textscroller shift

			ifnconst release
			org $0801
			;basic sys line
			dc.b $0b,$08,$00,$00,$9e,$32,$30,$36
			dc.b $31,$00,$00,$00
			sei
			cld
			lda #$35
			sta $01
			ldx #$ff
			txs
			jmp fadein
			else
			org $0808
			include "../../bitfire/loader/loader_acme.inc"
			include "../../bitfire/macros/link_macros_dasm.inc"
			endif
			
;------------------------------------------------------------------------------
;global settings
;------------------------------------------------------------------------------
volumesupport		equ 1			;0=no global volume support 1=turn on global volume support

globalfilter		equ $00			;global filter setting for 6581 $d418 output + sid

use3bit			equ 0			;0=4bit output 1=3bit output volumes 8-15
					
detachmixer		equ 1			;0=mixing in main thread, no loading possible 1=detach mixer from irq, mustn't use more than one frame to mix!
						;set to 0 to avoid crashing of too long mixing times

fastjitter		equ 0			;0=use safe 8 cycle jitter 1=use faster 7 cycle jitter
						;might crash depending on sid replayer
					
			ifnconst release
timingcolors		equ 0			;0=no colors 1=display rastertiming
			else
timingcolors		equ 0			;0=no colors 1=display rastertiming
			endif

geninterleave		equ 0			;generate interleave data during replay

echodistance		equ 15			;fast delay buffer distance from 1 to 15

external		equ 0			;0=use internal settings 1=include external settings

;------------------------------------------------------------------------------
;internal settings
;------------------------------------------------------------------------------
			if external=1
			include "thc_settings.asm"
			else			;external=1
preset			equ 2			;0=user defined 1=4ch ProTracker 2=MLC1 3=MLC2 Loop Station
						;4 = Fast delay

includesid		equ 1			;0=no sid tune 1=play sid
volumeboost		equ 0			;possible values are 0, 25 ,50 , 75, 100 ,125, 150, 175, 200
sampleoutput		equ 0			;0=waveform 8bit 1=digimax for emulator 2=4bit $d418  3=7bit $d418  4=$d020 colors  5=$d021 colors 6=pwm gate
						;if sampleoutput=2 or 3 then volumeboost has to be 0 !!!
replayrate		equ 0			;0=7812hz (1=11718hz 2=15624hz stablenmi has to be 0!)
bitdepth		equ 4			;0=4 bit samples 1=5 bit samples 2=6bit samples 3=7bit samples 4=8bit samples mixing
signed			equ 0			;0=unsigned samples 1=signed samples, needed for loop station mixing
loopstation		equ 0 			;0=disbale loop station 1=enable loop station with sample 31 as loop buffer
digivoices		equ 3			;2, 3 or 4 digi voices
sampleoffsetsupport	equ 1			;0=no global sampleoffset support 1=turn on global sampleoffset support
stablenmi		equ 1			;0=use normal nmi 1=use stable nmi
screen			equ 0			;0=screen off 1=screen on
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
deltacoding		equ 0			;0=normal samples 1=delta packed samples

;------------------------------------------------------------------------------
;channel specs
;thc_chn?vol	 	0=volume always max				1=volume support on
;thc_chn?per	 	0=always play period @ replay rate		1=period support on
;thc_chn?off		0=sampleoffset support off			1=sampleoffset support on
;------------------------------------------------------------------------------
			
			if preset=2		;MLC1
thc_chn1vol		equ 1
thc_chn1per		equ 1
thc_chn1off		equ 1

thc_chn2vol		equ 0
thc_chn2per		equ 1
thc_chn2off		equ 1

thc_chn3vol		equ 0
thc_chn3per		equ 0
thc_chn3off		equ 1
			endif	;preset=2
			
			endif	;external
;------------------------------------------------------------------------------
;zeropage
;------------------------------------------------------------------------------
zeropagecode		equ $02		;start of zeropage routines up to $ed
zp			equ $ae		;normal $ee (8 channels a 2 bytes)

goatlo			equ $fe		;used by sid replayer
goathi			equ $ff

;------------------------------------------------------------------------------
;volumetable vars
prodlo			equ goatlo	;only for init needed

;------------------------------------------------------------------------------
;replayer vars

clearstart		equ zp

voice1active		equ zp+$00				;4 bytes=4 voices - sample on $01, looped $ff or off $00
voice2active		equ zp+$01
voice3active		equ zp+$02
sample1frac		equ zp+$03
sample2frac		equ zp+$04
sample3frac		equ zp+$05
framecount		equ zp+$06
xscroll			equ zp+$07
xscroll8		equ zp+$08			
areg			equ zp+$09
xreg			equ zp+$0a
yreg			equ zp+$0b
			
clearend		equ zp+$0c


;------------------------------------------------------------------------------
;constants
;------------------------------------------------------------------------------
periodsteplength	equ 39				;39 stepbytes per note

mixingbufferlength	equ 156				;312 rasterlines/2
nmifreq			equ $007d
			
samples			equ 31				;samples 0-31
nmidest			equ $0102 			;destination of nmi1 routine

;------------------------------------------------------------------------------
;tables
;------------------------------------------------------------------------------
notestablelo		equ $0608			;max 124 periods
notestablehi		equ $0684
notesaddlo		equ $0708
notesaddfrac		equ $0784

mixingbuffer1		equ $0408
mixingbuffer2		equ $0508

spritefont		equ $e800			;- $ec00
stagesprites		equ $ec00			;- $ee00
stagescreen		equ $c400
spritetext		equ stagescreen+$03e8
spritepointer		equ stagescreen+$03f8

stagefont		equ $c000			;-$c400
charset1		equ $c800
charset2		equ $d000
charset3		equ $d800
charset4		equ $e000
colorram		equ $d800

silentbuffer		equ $ba00			;shares the safety margin of the last sample
volumetable		equ $ba00			;up to 32 tables for different volume, first volume is silent, last volume is max. $1f

firstsprite		equ [stagesprites-$c000]/64


			if bitdepth=4
periodtable		equ $f000			;6 periodtables per page 96 pages up to $ffff
			endif
			
;------------------------------------------------------------------------------
main			subroutine
;------------------------------------------------------------------------------
			jsr initsamples
			jsr volumetablegen	;trahses init routines
.waitfade		lda lastline+1
			bpl .waitfade

;			jsr fadeinfix

			ifconst release
			stop_music_nmi
			endif
			jsr vblank
			jsr clearsid
			jsr periodtablegen
			jsr javainit
			jsr initnmi

			ldx #$00
			lda #$00
.clear			sta stagesprites,x
			sta stagesprites+$100,x
			inx
			bne .clear

			lda #$00
			jsr sidfile

			if sampleoutput=0
			lda #$f0		;set sustain to max on voice 3
			sta $d414
			endif
			
			jsr vblank
			
			ifnconst release
			lda #$7f
			sta $dc0d
			lda $dc0d

			lda #$01
			sta $d019
			sta $d01a
			endif
			
			lda #<irq0
			sta $fffe
			lda #>irq0
			sta $ffff	
			
			lda #$2d
			sta $d012
			lda #$2b
.wait1			cmp $d012
			bne .wait1
.wait2			cmp $d012
			beq .wait2
			lda $dd0d
			lda #$81
			sta $dd0d
			cli
			
			if detachmixer=0
			
startmixing		lda #$00
			beq startmixing
			
			lda #$00
			sta startmixing+1
			
			if timingcolors=1
			lda #$0b
			sta $d020
			endif
			
			jsr mixer
		
			if timingcolors=1
			lda #$00
			sta $d020
			endif
			
			jmp startmixing
			
			else	;detachmixer=1
			
domain			lda #$00
			beq domain
			lda #$00
			sta domain+1
			
			if timingcolors=1
			inc $d020
			endif
			jsr textscroller

			if timingcolors=1
			inc $d020
			endif

			jsr doanim
			
			if timingcolors=1
			dec $d020
			endif
			
			ifconst crt
			lda #$7f                        ;space pressed?
			sta $dc00
			lda $dc01
			and #$10
			beq .exit                       ;yes, exit
                
			lda #$fd
			sta $dc00
			lda $dc01
exitflag		and #$00
			bpl domain

.exit			
;			jmp .exit
			sei
			ldx #$00
			stx $d01a
			lda #$7f
			sta $dd0d
			sta $dc0d
			lda $dd0d
			lda $dc0d
			stx $d015
			stx $d011

.crt_loop		lda $de00
			ldx #$04

.nextchar		lda $df04,x
			cmp signature,x
			bne .crt_loop			;not the same char? do next page
			dex
			bpl .nextchar
			
			inx
.copy			lda $df00,x
			sta $8000,x
			inx
			bne .copy
			
			lda #$37
			sta $01
			jmp ($fffc)
signature
			dc.b $c3 ;c
			dc.b $c2 ;b
			dc.b $cd ;m
			dc.b $38 ;8
			dc.b $30 ;0

			endif
			jmp domain
			endif			;detachmixer=0

;------------------------------------------------------------------------------
;nmi-replayer
;------------------------------------------------------------------------------
nmi_start
	 		rorg zeropagecode
;------------------------------------------------------------------------------
nmiplay			subroutine
;------------------------------------------------------------------------------
			; inc $d020
			; nop
			; dec $d020
			; jmp $dd0c			;40 takte für waveform output + 6-13 für init +3 für jmp + 7 für interrupt=56 - 63 cycles je nmi=9828 cycles worst case

			if stablenmi=1
			nop
			endif
nmiplaybuf		sta abuf+1			;3
nmiplaynobuf	
			if sampleoutput=0
      			lda #$11
			sta $d412
			lda #$09
			sta $d412
			endif
			
			if sampleoutput=4
			lda #$11
			sta $d020
			lda #$09
			sta $d020
			endif

			if sampleoutput=5
			lda #$11
			sta $d021
			lda #$09
			sta $d021
			endif

fetch			lda mixingbuffer1

			if sampleoutput=4
			sta $d020
			lda #$03
			sta $d020
			endif

			if sampleoutput=5
			sta $d021
			lda #$03
			sta $d021
			endif
			
			if sampleoutput=6
			sta $d410
			lda #$49
			sta $d412
			lda #$41
			sta $d412
			endif

			if sampleoutput=0
			sta $d40f
			lda #$01
			sta $d412
   			endif

			if sampleoutput=1
;			inc $d020
;			dec $d020
			sta $de00
   			endif

			if sampleoutput=2 | sampleoutput=3
			sta $d418
   			endif

			inc fetch+1

abuf			lda #$00
			jmp $dd0c			;40 takte für waveform output + 6-13 für init +3 für jmp + 7 für interrupt=56 - 63 cycles je nmi=9828 cycles worst case

;------------------------------------------------------------------------------
;preset 2 - MLC1 specs
;------------------------------------------------------------------------------
			if preset=2
			
			;add 3 8 bit samples with proper clipping
;2x carry clear = 0
;1x carry set = akku
;2x carry set = 255			

notefetch1		ldy periodtable,x		;4
samplefetch1a		lda silentbuffer,y 		;4.5
			sta mix1a+1			;3
samplefetch1b		lda silentbuffer,y 		;4.5
			sta mix1b+1			;3
samplefetch1c		lda silentbuffer,y 		;4.5
			sta mix1c+1			;3
samplefetch1d		lda silentbuffer,y 		;4.5
			sta mix1d+1			;3=34
			
notefetch2		ldy periodtable,x		;4
			
mix1a			lda silentbuffer		;4
samplefetch2a		adc silentbuffer,y 		;4.5
			bcs .carry1a
samplefetch3a		adc silentbuffer,x 		;4.5
			bcs mixswitch1
			lda #$00			;carry 0
			bcc mixswitch1
.carry1a		
samplefetch3aa		adc silentbuffer,x 		;4.5
			bcc mixswitch1			;carry 1x set
			lda #$ff			;carry 2x set
mixswitch1		sta mixingbuffer2,x		;4=20

mix1b			lda silentbuffer		;4
samplefetch2b		adc silentbuffer,y 		;4.5
			bcs .carry1b
samplefetch3b		adc silentbuffer,x 		;4.5
			bcs mixswitch2
			lda #$00			;carry 0
			bcc mixswitch2
.carry1b
samplefetch3ba		adc silentbuffer,x 		;4.5
			bcc mixswitch2			;carry 1x set
			lda #$ff			;carry 2x set
mixswitch2		sta mixingbuffer2+periodsteplength,x		;4=20

mix1c			lda silentbuffer		;4
samplefetch2c		adc silentbuffer,y 		;4.5
			bcs .carry1c
samplefetch3c		adc silentbuffer,x 		;4.5
			bcs mixswitch3
			lda #$00			;carry 0
			bcc mixswitch3
.carry1c
samplefetch3ca		adc silentbuffer,x 		;4.5
			bcc mixswitch3			;carry 1x set
			lda #$ff			;carry 2x set
mixswitch3		sta mixingbuffer2+periodsteplength*2,x		;4=20

mix1d			lda silentbuffer		;4
samplefetch2d		adc silentbuffer,y 		;4.5
			bcs .carry1d
samplefetch3d		adc silentbuffer,x 		;4.5
			bcs mixswitch4
			lda #$00			;carry 0
			bcc mixswitch4
.carry1d
samplefetch3da		adc silentbuffer,x 		;4.5
			bcc mixswitch4			;carry 1x set
			lda #$ff			;carry 2x set
mixswitch4		sta mixingbuffer2+periodsteplength*3,x		;4=20

			dex				;2
			bmi .exit			;2 55,75 cycles je sample bzw. 61,75 bei volumetab
			jmp notefetch1			;3
.exit			rts
		
			endif	;preset=2
			
			rend
nmi_end
;-------------------------------------------------------
			if volumesupport=1
;if you need to implement volume artificially, just multiply by the volume and shift right 6 times.
; multiply routine 8x8=>16 unsigned

;{1}=tablelength
;{2]=midpoint (tablelength/2)
			mac voltabgen
.voladd1		ldy #$01
			lda volumestable,y
			bmi .exit
			
			asl
			asl
			clc
			adc #$03
			tax
			stx .moreamp+1
			lda #{2}
			lsr		;multiply a*x -> a=hi prodlo=lo
			sta prodlo
			stx .factor1+1
			lda #$00
			ldx #$08
			
.loop1			bcc .noadd1
			clc       	
.factor1		adc #$00
			
.noadd1			ror
			ror prodlo	
			dex		
			bne .loop1
			sta .zeroref+1

			ldy #$00
.moreamp		ldx #$07		;the desired volume for volume table #0
			tya
			
			lsr			;multiply a*x -> a=hi prodlo=lo
			sta prodlo
			stx .factor2+1
			lda #$00
			ldx #$08
			
.loop2			bcc .noadd2
			clc       	
.factor2		adc #$00
			
.noadd2			ror
			ror prodlo	
			dex		
			bne .loop2
			sec
.zeroref		sbc #$00

			if signed=0
			clc
			adc #{2}
.ampdest		sta volumetable+$100,y
			else
.ampdest		sta volumetable+$180
			inc .ampdest+1
			endif

			iny
			if bitdepth=4
			else
			cpy #{1}
			endif
			bne .moreamp
			inc .voladd1+1
			inc .ampdest+2
			inc .amppatch+2
			jmp .voladd1

.exit			if signed=0
			lda #$00		;patches last volumetable because of accuracy bugs
.amppatch		sta volumetable
			else
			lda #$80
.amppatch		sta volumetable+$80
			endif
			endm
			
;------------------------------------------------------------------------------
volumetablegen		subroutine
;------------------------------------------------------------------------------
			if bitdepth=4			;8bit volumetable mixing
			voltabgen $00,$80
			endif	;bitdepth=4

			if bitdepth=3			;7bit volumetable mixing
			if digivoices=3
			voltabgen $56,$2a
			else
			voltabgen $80,$40
			endif	;digivoices=3
			endif	;bitdepth=3
			
			if bitdepth=2			;6bit volumetable mixing
			if digivoices<5
			voltabgen $40,$20
			endif
			if digivoices=5
			voltabgen $34,$19
			endif
			if digivoices=6
			voltabgen $2b,$15
			endif
			endif				;bitdepth=2

			if bitdepth=1			;5bit volumetable mixing
			voltabgen $20,$10
			endif

			if bitdepth=0			;4bit volumetable mixing
			voltabgen $10,$08
			endif
			
			rts
			endif	;volumesupport=1

;---------------------------------------
; irq's
;---------------------------------------
			align 256,0
irq0			subroutine
			sta .areg+1
			stx .xreg+1
			sty .yreg+1
			
			inc $d019
			
			ldx #>mixingbuffer1
bufferpointer		lda #$00
			beq .buf1
			ldx #>mixingbuffer2
.buf1			stx fetch+2
			ldx #<mixingbuffer1		;lobyte of mixingbuffers
			stx fetch+1
			eor #$01
			sta bufferpointer+1

			lda #$1b
			sta $d011
			
			lda #6*8+50
			sta $d012
			
			lda #%00010010
			sta $d018
			
			lda #$18
			sta $d016
			
			if timingcolors=1
			lda #$0f
			sta $d020
			endif
			
			jsr sidfile+3

 			; lda #$0a
 			; sta $d020

 			; ldy #$19				;25 Lines free
; .loop2			ldx #$0b			;each delay loop takes 62 cycles ~ 1 raster line
; .loop			dex
 			; bne .loop
 			; dey
 			; bne .loop2

			; lda #$00
			; sta $d020
			
			lda #<irq1
			sta $fffe
;			lda #>irq1
;			sta $ffff
			
			cli
;maintask			
			if timingcolors=1
			lda #$0c
			sta $d020
			endif

			jsr mixer

			ifnconst release
			lda $d011
			bmi .lower
			lda $d012
rline			cmp #$00
			bcc .lower
			sta rline+1
.lower			endif

			if timingcolors=1
			lda #$0b
			sta $d020
			endif
			
.areg			lda #$00
.xreg			ldx #$00
.yreg			ldy #$00
barerti			rti

;---------------------------------------
irq1			subroutine
			lda #%00010100
			sta $d018
			lda abuf+1
		
			sta .areg+1
			lda #10*8+50
			sta $d012
			lda #<irq2
			sta $fffe
;			lda #>irq2
;			sta $ffff
			
			inc $d019
			
.areg			lda #$00
			rti
;---------------------------------------
irq2			subroutine
			lda #%00010110
			sta $d018
			lda abuf+1
		
			sta .areg+1
			lda #14*8+50
			sta $d012
			lda #<irq3
			sta $fffe
;			lda #>irq2
;			sta $ffff
			inc $d019
			
.areg			lda #$00
			rti
;---------------------------------------
irq3			subroutine
			lda #%00011000
			sta $d018
			lda abuf+1
			
			sta .areg+1
			lda #21*8+50+4
			sta $d012

			lda xscroll		;shift sprites x
			sta $d00a
			ora #$08
			sta xscroll8
			clc
			adc #$50
			sta $d00c
			adc #$18
			sta $d00e
			adc #$70
			sta $d008

			lda #<irq4
			sta $fffe
;			lda #>irq3
;			sta $ffff
			
			inc $d019
.areg			lda #$00
			rti

;---------------------------------------
irq4			subroutine
			lda #$7f		;stop nmi playing
			sta $dd0d
			lda abuf+1
			sta areg3+1
			stx xreg3+1
			sty yreg3+1
			
			lda fetch+2
			cmp #>mixingbuffer1
			beq .buf1
			jmp irq4buf2
						
.buf1			jmp irq4buf1		;233 cycle 26

;------------------------------------------------------------------------------
;sid-player
;------------------------------------------------------------------------------
			if includesid=1
sidfile			org $0d00
			incbin "thc_sid.bin"
			endif

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
javainit		subroutine
;------------------------------------------------------------------------------
			lda #$00
			
			ldx #clearend-clearstart-1
.loop1			sta clearstart,x
			dex
			bpl .loop1

			tax

			if sampleoutput=2 & globalfilter>0
.loop1b			lda d418tab,x

			if use3bit=1
			lsr
			clc
			adc #$08
			endif
			
			ora #globalfilter
			sta d418tab,x
			inx
			bne .loop1b
			endif
						
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
			
			if sampleoutput > 1	;all modes except waveform
			jsr clearsid
                        lda #$ff		;check sid type
.wait                   cmp $d012
                        bne .wait

                        lda #$ff
                        sta $d412
                        sta $d40e
                        sta $d40f
                        lda #$20
                        sta $d412
                        ldx $d41b
                        txa
                        lsr
			bcs .oldsid
			endif

			if sampleoutput=2	;normal $d418 output using 8580
			jsr clearsid
                        lda #$f0		;sample boost
                        sta $d406
                        sta $d40d
                        sta $d414
                        lda #$49
                        sta $d404
                        sta $d40b
                        sta $d412
			lda #$08
			sta $d417
			bne .newsid
			endif
			
			if sampleoutput=3	;7bit $d418 output
			ldx #$00		;switch to 8580 table
.copyloop		lda d418tab8580,x
			sta d418tab,x
			inx
			bne .copyloop
			endif

.oldsid			jsr clearsid		;waveform or digimax

.newsid			if sampleoutput=3	;7bit $d418 output
			if includesid=0		;no sid playing
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
			
			else	;includesid=1	sid voices 1 and 2 playing
			
			lda #$49
			sta $d412
			lda #$ff
			sta $d414

			sta $d415
			sta $d416

			lda #$04   		;Enable filter on voice #3
			sta $d417
			
			; lda #$2c		;patch goat gommo
			; sta $0e2b
			; sta $0e30
			; sta $0e37
			
			; lda #$2c		;patch goat cl13
			; sta $0e22
			; sta $0e27
			; sta $0e2e
			
			endif	;includesid=0
			endif	;sampleoutput=3
			
			if sampleoutput=0	;waveform

			lda #$08
			sta $d417
			lda #$0f
			sta $d418
			
			endif	;sampleoutput=0
			
			if sampleoutput=6	;pwm gate
			lda #$1f		;Volume + filter
			sta $d418
		
			lda #$00		;Set SID freq registers
			sta $d40e
			lda #$40		;$4000 --> the wave accu is
			sta $d40f
			lda #$f0		;maximum sustain level for all chns
			sta $d414
		
			endif	;sampleoutput=6
		
			ldx #$00
			
			if signed=0
			lda #$80		;clear all mixingbuffers
			else
			txa
			endif	;signed=0
			
.mixbuffer		sta mixingbuffer1,x
			sta mixingbuffer2,x
			if replayrate=2
			sta mixingbuffer1b,x
			sta mixingbuffer2b,x
			endif
			inx
			cpx #mixingbufferlength
			bne .mixbuffer
				
			if preset=4
.exitclear		ldy #>echobuffer
.loop5			sty .mixbuffer2+2
			ldx #$00
.mixbuffer2		sta echobuffer,x
			inx
			cpx #mixingbufferlength
			bne .mixbuffer2
			iny
			cpy #>echobuffer+echobuffers
			bne .loop5
			endif

			ldx #$00	
			
			if bitdepth=4
			if signed=0
			lda #$80
			else
			txa
			endif	;signed=0
			endif	;bitdepth=4

			if bitdepth=3
			if digivoices=3
			lda #$2a
			else
			lda #$40
			endif	;digivoices=3
			endif	;bitdepth=3
			
			if bitdepth=2
			if digivoices<5
			lda #$20
			endif
			if digivoices=5
			lda #$19
			endif
			if digivoices=6
			lda #$15
			endif
			endif	;bitdepth=2
			
			if bitdepth=1
			lda #$10
			endif
			if bitdepth=0
			lda #$08
			endif
			
.loop4			sta silentbuffer,x
			inx
			bne .loop4
			
			if includesid=1
			if siddelay>0
			ldx #siddelay
			bne .over
			endif
			endif
			
javarestart		ldx #$00
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
						
			if includesid=1
			if cc2patch=1
;------------------------------------------------------------------------------
ccpatch			subroutine
			lda sidfile+6
			cmp #$0a		;asl imm
			bne .exit
			
			lda #<sidfile
			sta goatlo
			lda #>sidfile
			sta goathi
			
			ldx #$01		;max 2 block search range
.loop			ldy #$00
			lda (goatlo),y
			cmp #$a2
			bne .nextbyte
			iny
			lda (goatlo),y
			cmp #$02
			bne .nextbyte
			iny
			lda (goatlo),y
			cmp #$bd
			beq .found
			
.nextbyte		inc goatlo
			bne .loop
			inc goathi
.over			dex
			bpl .loop
;not found !?		
.forever		inc $d020
			jmp .forever

.found			dey
			lda #$01
			sta (goatlo),y

.exit			rts
			endif	;cc2patch=1
;-----------------------
			if sampleoutput=2	;d418
goatpatch		subroutine
			lda #<sidfile
			sta goatlo
			lda #>sidfile
			sta goathi
			
			ldx #$01		;max 2 block search range
.loop			ldy #$00
			lda (goatlo),y
			cmp #$8d
			bne .nextbyte
			iny
			lda (goatlo),y
			cmp #$18
			bne .nextbyte
			iny
			lda (goatlo),y
			cmp #$d4
			beq .found
			
.nextbyte		inc goatlo
			bne .loop
			inc goathi
.over			dex
			bpl .loop
;not found !?		
.forever		inc $d020
			jmp .forever

.found			dey
			dey
			lda #$2c	;bit
			sta (goatlo),y

.exit			rts
			endif 	;sampleoutput=2
			endif	;includesid=1
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
			if geninterleave=1
putbyte			subroutine
			php
.put			sta samplememstart
			inc .put+1
			bne .exit
			inc .put+2
.exit			plp
			rts
			endif
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
.endofsong		ifconst crt
			lda #$80
			sta exitflag+1
			else
			jsr javarestart
			jmp mixrestart
			endif
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
			lda trigtablo,x
			sta .store+1
			lda trigtabhi,x
			sta .store+2
			lda #$00
.store			sta $0100
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
			
			if replayrate>1
			bcc .preppart7
			else
			bcc .nextvoice
			endif

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
			
			if replayrate>1
			clc
;------------------------------------------------------------------------------
.preppart7		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}f+1
			adc notesaddlo,x
			sta samplefetch{1}g+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}g+2

			else	;{3}=0

			lda samplefetch{1}f+1
			adc #periodsteplength
			sta samplefetch{1}g+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}g+2
			endif	;{3}=0
			
			lda samplefetch{1}g+1
			cmp sampleendlo,y
			lda samplefetch{1}g+2
			sbc sampleendhi,y
			bcc .preppart8

			lda voice{1}active
			bmi .loop7

			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice7

.loop7			lda samplefetch{1}g+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}g+1
			lda samplefetch{1}g+2
			sbc looplengthhi,y
			sta samplefetch{1}g+2
			clc
;------------------------------------------------------------------------------
.preppart8		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}g+1
			adc notesaddlo,x
			sta samplefetch{1}h+1
			lda samplefetch{1}g+2
			adc #$00
			sta samplefetch{1}h+2

			else	;{3}=0

			lda samplefetch{1}g+1
			adc #periodsteplength
			sta samplefetch{1}h+1
			lda samplefetch{1}g+2
			adc #$00
			sta samplefetch{1}h+2
			endif	;{3}=0
			
			lda samplefetch{1}h+1
			cmp sampleendlo,y
			lda samplefetch{1}h+2
			sbc sampleendhi,y
			bcc .nextvoice

			lda voice{1}active
			bmi .loop8

			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice8

.loop8			lda samplefetch{1}h+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}h+1
			lda samplefetch{1}h+2
			sbc looplengthhi,y
			sta samplefetch{1}h+2
			endif	;replayrate>1
			
.nextvoice		if playlzstream=1
lzsysave{1}		if digivoices={1}
			lda #$00		;last channel usa akku to save 2 cycles
			else
			ldy #$00
			endif			;digivoices={1}
			endif			;playlzstream=1
			endm
;------------------------------------------------------------------------------
mixer			subroutine
;------------------------------------------------------------------------------
;{1}=voice number
;{2]=0 - volume off 1=volume on
;{3}=0 - period always 453 1 - periods on
;{4}=0 - sampleoffset off  1 - sampleoffset on
			lda #>mixingbuffer2
			if replayrate=2
			ldx #>mixingbuffer2b
			endif
			ldy bufferpointer+1	;set mixing buffer
			bne .buf1
			lda #>mixingbuffer1
			if replayrate=2
			ldx #>mixingbuffer1b
			endif
		
.buf1			sta mixswitch1+2
			sta mixswitch2+2
			sta mixswitch3+2
			sta mixswitch4+2
			if replayrate=1
			sta mixswitch5+2
			sta mixswitch6+2
			endif
			if replayrate=2
			stx mixswitch5+2
			stx mixswitch6+2
			stx mixswitch7+2
			stx mixswitch8+2
			endif

			if preset=4
echofillbuffer		ldy #$ff
			iny
			tya
			and #$0f
			sta echofillbuffer+1
			tay
			clc
			adc #>echobuffer
			sta echofill1a+2
			sta echofill1b+2
			sta echofill2a+2
			sta echofill2b+2
			sta echofill3a+2
			sta echofill3b+2
			sta echofill4a+2
			sta echofill4b+2
			tya
			sec
			sbc #echodistance
			and #$0f
			adc #>echobuffer
			sta echofetch1a+2
			sta echofetch1b+2
			sta echofetch2a+2
			sta echofetch2b+2
			sta echofetch3a+2
			sta echofetch3b+2
			sta echofetch4a+2
			sta echofetch4b+2
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
doof			clc
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
			
			if preset=2 | preset=8	;MLC1 and MLC1+
			lda samplefetch3a+1
			sta samplefetch3aa+1
			lda samplefetch3a+2
			sta samplefetch3aa+2
			
			lda samplefetch3b+1
			sta samplefetch3ba+1
			lda samplefetch3b+2
			sta samplefetch3ba+2

			lda samplefetch3c+1
			sta samplefetch3ca+1
			lda samplefetch3c+2
			sta samplefetch3ca+2

			lda samplefetch3d+1
			sta samplefetch3da+1
			lda samplefetch3d+2
			sta samplefetch3da+2
			endif	;preset=2
	
			ldx #periodsteplength-1
			clc
			jmp notefetch1
;------------------------------------------------------------------------------
;modfile - protracker module
;------------------------------------------------------------------------------
			echo "Samplestart: ",*
			include "thc_samples.asm"

			align 256,0
			echo "Sampleheaderstart: ",*
			include "thc_sampleheader.asm"

			echo "Songstart: ",*
			include "thc_init.asm"
			
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
;------------------------------------------------------------------------------
;demopart code
;------------------------------------------------------------------------------
			mac playsamplea
			if sampleoutput=0
      			lda #$11
			sta $d412
			lda #$09
			sta $d412
			endif

			if sampleoutput=4
      			lda #$11
			sta $d020
			lda #$09
			sta $d020
			endif

			if sampleoutput=5
      			lda #$11
			sta $d021
			lda #$09
			sta $d021
			endif

			lda {1}

			if sampleoutput=4
			sta $d020
			lda #$03
			sta $d020
			endif

			if sampleoutput=5
			sta $d021
			lda #$03
			sta $d021
			endif
			
			if sampleoutput=0
			sta $d40f
			lda #$01
			sta $d412
   			endif

			endm
;-----------------------
			mac playsamplex
			if sampleoutput=0
      			ldx #$11
			stx $d412
			ldx #$09
			stx $d412
			endif

			if sampleoutput=4
      			ldx #$11
			stx $d020
			ldx #$09
			stx $d020
			endif

			if sampleoutput=5
      			ldx #$11
			stx $d021
			ldx #$09
			stx $d021
			endif

			ldx {1}

			if sampleoutput=4
			stx $d020
			ldx #$03
			stx $d020
			endif

			if sampleoutput=5
			stx $d021
			ldx #$01
			stx $d021
			endif
			
			if sampleoutput=0
			stx $d40f
			ldx #$01
			stx $d412
			endif
			endm


;------------------------------------------------------------------------------
irq4buf1		subroutine
			nop
			bit $00

spritechar0bpos		ldx #$80
spritechar0b		ldy #$80

			lda spritefont,y
			sta stagesprites+$100+3,x
			lda spritefont+1,y
			sta stagesprites+$100+6,x
			lda spritefont+2,y
			sta stagesprites+$100+9,x
			lda spritefont+3,y
			sta stagesprites+$100+12,x
;line 224 cycle 19
line224			playsamplea mixingbuffer1+$59	;100 cycles free (10) Patch 0 1
			
			lda spritefont+$100,y
			sta stagesprites+$100+15,x
			lda spritefont+$100+1,y
			sta stagesprites+$100+18,x
			lda spritefont+$100+2,y
			sta stagesprites+$100+21,x
			lda spritefont+$100+3,y
			sta stagesprites+$100+24,x

			lda spritefont+$200,y
			sta stagesprites+$100+27,x
			lda spritefont+$200+1,y
			sta stagesprites+$100+30,x
			lda spritefont+$200+2,y
			sta stagesprites+$100+33,x
			lda spritefont+$200+3,y
			sta stagesprites+$100+36,x

			lda spritefont+$300,y
			sta stagesprites+$100+39,x
			lda spritefont+$300+1,y
			sta stagesprites+$100+42,x

			lda #>mixingbuffer1
			sta patchbuf0+12
			sta patchbuf1+12
			
;line 226 cycle 19 (227 badline)
			playsamplea mixingbuffer1+$5a	;51 cycles free

			lda spritefont+$300+2,y
			sta stagesprites+$100+45,x
			lda spritefont+$300+3,y
			sta stagesprites+$100+48,x
			inx
			
spritechar1b		ldy #$80
			lda spritefont,y
			sta stagesprites+$100+3,x
			lda spritefont+1,y
			sta stagesprites+$100+6,x
			lda spritefont+2,y
			sta stagesprites+$100+9,x

			lda #%00010000
			sta $d018
			nop
;line 228 cycle 19
			playsamplea mixingbuffer1+$5b	;100 cycles free (10) Patch 2 3

			lda spritefont+3,y
			sta stagesprites+$100+12,x

			lda spritefont+$100,y
			sta stagesprites+$100+15,x
			lda spritefont+$100+1,y
			sta stagesprites+$100+18,x
			lda spritefont+$100+2,y
			sta stagesprites+$100+21,x
			lda spritefont+$100+3,y
			sta stagesprites+$100+24,x

			lda spritefont+$200,y
			sta stagesprites+$100+27,x
			lda spritefont+$200+1,y
			sta stagesprites+$100+30,x
			lda spritefont+$200+2,y
			sta stagesprites+$100+33,x
			lda spritefont+$200+3,y
			sta stagesprites+$100+36,x

			lda spritefont+$300,y
			sta stagesprites+$100+39,x
			
			lda #>mixingbuffer1
			sta patchbuf2+12
			sta patchbuf3+12
;line 230 cycle 19
			playsamplea mixingbuffer1+$5c	;100 cycles free (6) Patch 4

			lda spritefont+$300+1,y
			sta stagesprites+$100+42,x
			lda spritefont+$300+2,y
			sta stagesprites+$100+45,x
			lda spritefont+$300+3,y
			sta stagesprites+$100+48,x
			inx

spritechar2b		ldy #$80
			lda spritefont,y
			sta stagesprites+$100+3,x
			lda spritefont+1,y
			sta stagesprites+$100+6,x
			lda spritefont+2,y
			sta stagesprites+$100+9,x
			lda spritefont+3,y
			sta stagesprites+$100+12,x
			
			lda spritefont+$100,y
			sta stagesprites+$100+15,x
			lda spritefont+$100+1,y
			sta stagesprites+$100+18,x
			lda spritefont+$100+2,y
			sta stagesprites+$100+21,x

			lda #>mixingbuffer1
			sta patchbuf4+12
;line 232 cycle 19
			playsamplea mixingbuffer1+$5d	;89 cycles free (90 cycles because of write cycle?) (9) Patch 5
			lda spritefont+$100+3,y
			sta stagesprites+$100+24,x

			lda spritefont+$200,y
			sta stagesprites+$100+27,x
			lda spritefont+$200+1,y
			sta stagesprites+$100+30,x
			lda spritefont+$200+2,y
			sta stagesprites+$100+33,x
			lda spritefont+$200+3,y
			sta stagesprites+$100+36,x

			lda spritefont+$300,y
			sta stagesprites+$100+39,x
			lda spritefont+$300+1,y
			sta stagesprites+$100+42,x
			lda spritefont+$300+2,y
			sta stagesprites+$100+45,x
			lda spritefont+$300+3,y
			sta stagesprites+$100+48,x
			
			lda fetch+2
			sta patchbuf5+12
			nop
;line 234 cycle 19
			playsamplex mixingbuffer1+$5e	;11 cycles free Patch 6 7

			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016
			
			sta $d015,x	;badline
			sty $d016

			lda fetch+2
			sta patchbuf6+12
			sta patchbuf7+12
;line 236 cycle 19
			playsamplex mixingbuffer1+$5f	;41 cycles free Patch 8

			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016

			ldx #>mixingbuffer1
			stx patchbuf8+12
			jmp irq3exit

;------------------------------------------------------------------------------
irq4buf2		subroutine
			bit $00
			bit $00

spritechar0apos		ldx #$00
spritechar0a		ldy #$80
			lda spritefont,y
			sta stagesprites+3,x
			lda spritefont+1,y
			sta stagesprites+6,x
			lda spritefont+2,y
			sta stagesprites+9,x
			lda spritefont+3,y
			sta stagesprites+12,x

;line 224 cycle 19
			playsamplea mixingbuffer2+$59	;100 cycles free (10) Patch 0 1

			lda spritefont+$100,y
			sta stagesprites+15,x
			lda spritefont+$100+1,y
			sta stagesprites+18,x
			lda spritefont+$100+2,y
			sta stagesprites+21,x
			lda spritefont+$100+3,y
			sta stagesprites+24,x

			lda spritefont+$200,y
			sta stagesprites+27,x
			lda spritefont+$200+1,y
			sta stagesprites+30,x
			lda spritefont+$200+2,y
			sta stagesprites+33,x
			lda spritefont+$200+3,y
			sta stagesprites+36,x

			lda spritefont+$300,y
			sta stagesprites+39,x
			lda spritefont+$300+1,y
			sta stagesprites+42,x
			
			lda #>mixingbuffer2
			sta patchbuf0+12
			sta patchbuf1+12
			
;line 226 cycle 19 (227 badline)
			playsamplea mixingbuffer2+$5a	;51 cycles free	
			
			lda spritefont+$300+2,y
			sta stagesprites+45,x
			lda spritefont+$300+3,y
			sta stagesprites+48,x
			inx

spritechar1a		ldy #$80
			lda spritefont,y
			sta stagesprites+3,x
			lda spritefont+1,y
			sta stagesprites+6,x
			lda spritefont+2,y
			sta stagesprites+9,x

			lda #%00010000
			sta $d018
			nop
;line 228 cycle 19
			playsamplea mixingbuffer2+$5b	;100 cycles free (10) Patch 2 3
			lda spritefont+3,y
			sta stagesprites+12,x

			lda spritefont+$100,y
			sta stagesprites+15,x
			lda spritefont+$100+1,y
			sta stagesprites+18,x
			lda spritefont+$100+2,y
			sta stagesprites+21,x
			lda spritefont+$100+3,y
			sta stagesprites+24,x

			lda spritefont+$200,y
			sta stagesprites+27,x
			lda spritefont+$200+1,y
			sta stagesprites+30,x
			lda spritefont+$200+2,y
			sta stagesprites+33,x
			lda spritefont+$200+3,y
			sta stagesprites+36,x

			lda spritefont+$300,y
			sta stagesprites+39,x
			
			lda #>mixingbuffer2
			sta patchbuf2+12
			sta patchbuf3+12
;line 230 cycle 19
			playsamplea mixingbuffer2+$5c	;100 cycles free (6) Patch 4

			lda spritefont+$300+1,y
			sta stagesprites+42,x
			lda spritefont+$300+2,y
			sta stagesprites+45,x
			lda spritefont+$300+3,y
			sta stagesprites+48,x
			inx

spritechar2a		ldy #$80
			lda spritefont,y
			sta stagesprites+3,x
			lda spritefont+1,y
			sta stagesprites+6,x
			lda spritefont+2,y
			sta stagesprites+9,x
			lda spritefont+3,y
			sta stagesprites+12,x
			
			lda spritefont+$100,y
			sta stagesprites+15,x
			lda spritefont+$100+1,y
			sta stagesprites+18,x
			lda spritefont+$100+2,y
			sta stagesprites+21,x

			lda #>mixingbuffer2
			sta patchbuf4+12

;line 232 cycle 19
			playsamplea mixingbuffer2+$5d	;89 cycles free (90 cycles because of write cycle?) (9) Patch 5

			lda spritefont+$100+3,y
			sta stagesprites+24,x

			lda spritefont+$200,y
			sta stagesprites+27,x
			lda spritefont+$200+1,y
			sta stagesprites+30,x
			lda spritefont+$200+2,y
			sta stagesprites+33,x
			lda spritefont+$200+3,y
			sta stagesprites+36,x

			lda spritefont+$300,y
			sta stagesprites+39,x
			lda spritefont+$300+1,y
			sta stagesprites+42,x
			lda spritefont+$300+2,y
			sta stagesprites+45,x
			lda spritefont+$300+3,y
			sta stagesprites+48,x

			lda fetch+2
			sta patchbuf5+12
			nop
;line 234 cycle 19
			playsamplex mixingbuffer2+$5e	;11 cycles free Patch 6 7
			
			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016
			
			sta $d015,x	;badline
			sty $d016
			
			lda fetch+2
			sta patchbuf6+12
			sta patchbuf7+12
;line 236 cycle 19
			playsamplex mixingbuffer2+$5f	;41 cycles free Patch 8

			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016

			ldx #>mixingbuffer2
			stx patchbuf8+12
			bit $00
			
;-----------------------
;jump here from first buf
;-----------------------
irq3exit
			lda framecount
			clc
			adc #$01
			and #$07
			sta framecount

			jsr wait12			;17 cycles free
			bit $00
			nop
			
			ldy xscroll8
			lda xscroll
			sta $d016
			sty $d016
			ldx #<mixingbuffer1+$69
			stx fetch+1
			nop				;6 cycles
			nop
			nop
;line 238 cycle 19
patchbuf0		playsamplex mixingbuffer2+$60

			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016

			jsr wait12			;41 cycles
			jsr wait12
			jsr wait12
			bit $00
			nop
			
			lda xscroll
			sta $d016
			sty $d016
			bit $00		;11 cycles
			nop
			nop
			nop
			nop
;line 240 cycle 19
patchbuf1		playsamplex mixingbuffer2+$61

			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016

			jsr wait12	;41 cycles
			jsr wait12
			jsr wait12
			bit $00
			nop
			
			lda xscroll
			sta $d016
			sty $d016
			bit $00		;11 cycles
			nop
			nop
			nop
			nop
;line 242 cycle 19
patchbuf2		playsamplex mixingbuffer2+$62

			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016
			
			sta $d015,x	;badline
			sty $d016
			bit $00		;11 cycles
			nop
			nop
			nop
			nop
;line 244 cycle 19
patchbuf3		playsamplex mixingbuffer2+$63

			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016

			jsr wait12	;41 cycles
			jsr wait12
			jsr wait12
			bit $00
			nop
			
			lda xscroll
			sta $d016
			sty $d016
			bit $00		;11 cycles
			nop
			nop
			nop
			nop
;line 246 cycle 19
patchbuf4		playsamplex mixingbuffer2+$64

			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016

			jsr wait12	;41 cycles
			jsr wait12
			jsr wait12
			bit $00
			nop
			
			lda xscroll
			sta $d016
			sty $d016
			bit $00		;11 cycles
			nop
			nop
			nop
			nop
;line 248 cycle 19
patchbuf5		playsamplex mixingbuffer2+$65

			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016

			jsr wait12	;41 cycles
			jsr wait12
			jsr wait12
			nop
			bit $00
			lda xscroll
			sta $d016
			sty $d016
			; lda #$17
			; sta $d011
			nop		;11 cycles
			nop
			nop
			nop
			bit $00
;line 250 cycle 19
patchbuf6		playsamplex mixingbuffer2+$66
			ldy xscroll8
			lda xscroll
			sta $d015,x
			sty $d016

			ldy framecount			;27 cycles from here it's safe to switch sprite pointers and xscroll
			lda spriteoffsettab,y
			sta spritepointer+4
			clc
			adc #$01
			sta spritepointer+6
			adc #$03
			sta spritepointer+5
			adc #$01
			sta spritepointer+7

			lda xscrolltab,y
			sta xscroll

			jsr wait12
			jsr wait12
			nop
;line 252 cycle 19
patchbuf7		playsamplea mixingbuffer2+$67
			jsr wait12	;78 cycles
			jsr wait12
			jsr wait12
			jsr wait12
			nop
			
			lda #$2d
			sta $d012
			sta domain+1
			lda #<irq0
			sta $fffe
;			lda #>irq0
;			sta $ffff
			inc $d019
			
			lda $dd0d
			ldx #$81
			
;line 254 cycle 19 (protect NMI from sprites until here!)
patchbuf8		playsamplea mixingbuffer2+$68
;-----------------------
			stx $dd0d

areg3			lda #$00
xreg3			ldx #$00
yreg3			ldy #$00
			rti
;--------------------------------------
doanim			subroutine
;tiggerd anims

;Lautsprecher links
trigleft		set *+1
.anim04			ldx #$06
.back04			ldy animlist04hi,x
			beq .anim05

.over04			sty .gosub04+2
			ldy animlist04lo,x
			sty .gosub04+1
			inx
			stx .anim04+1

			ldx #$01
			lda #$fe
.gosub04		jsr $1000
;-----------------------
;Lautsprecher rechts
trigright		set *+1
.anim05			ldx #$06
.back05			ldy animlist05hi,x
			beq .anim08

.over05			sty .gosub05+2
			ldy animlist05lo,x
			sty .gosub05+1
			inx
			stx .anim05+1

			ldx #$01
			lda #$fe
.gosub05		jsr $1000

;-----------------------
;Lautsprecher links unten
trigbottomleft		set *+1
.anim08			ldx #$06
.back08			ldy animlist08hi,x
			beq .anim09

.over08			sty .gosub08+2
			ldy animlist08lo,x
			sty .gosub08+1
			inx
			stx .anim08+1

			ldx #$01
			lda #$fe
.gosub08		jsr $1000
;-----------------------
;Lautsprecher rechts unten
trigbottomright		set *+1
.anim09			ldx #$06
.back09			ldy animlist09hi,x
			beq .anims

.over09			sty .gosub09+2
			ldy animlist09lo,x
			sty .gosub09+1
			inx
			stx .anim09+1

			ldx #$01
			lda #$fe
.gosub09		jsr $1000

;-----------------------
;cyclic anims
.anims
			lax .animjmp + 1
			sbx #-2
			cpx #$60
			bne .animo
			ldx #$00
.animo
			stx .animjmp + 1
			ldx #$01
			lda #$fe
.animjmp		jmp (animframe)
;------------------------------------------------------------------------------
			align 256,0
animframe
;			dc.w barerts	;need to be at $xx00
;Lautsprecher Flammen links
;			dc.w .anim06
;Flammen links
;			dc.w .anim02
;Hand links
;			dc.w .anim00
;			dc.w barerts
;Hand rechts
;			dc.w .anim01
;Flammen rechts
;			dc.w .anim03
;Lautsprecher Flammen rechts
;			dc.w .anim07

			dc.w barerts
			dc.w anim06_03
			dc.w anim02_01
			dc.w anim00_03
			dc.w barerts
			dc.w anim01_01
			dc.w anim03_03
			dc.w anim07_01

			dc.w barerts
			dc.w anim06_02
			dc.w anim02_00
			dc.w anim00_02
			dc.w barerts
			dc.w anim01_00
			dc.w anim03_02
			dc.w anim07_00

			dc.w barerts
			dc.w anim06_01
			dc.w anim02_01
			dc.w anim00_01
			dc.w barerts
			dc.w anim01_01
			dc.w anim03_01
			dc.w anim07_01

			dc.w barerts
			dc.w anim06_00
			dc.w anim02_02
			dc.w anim00_00
			dc.w barerts
			dc.w anim01_02
			dc.w anim03_00
			dc.w anim07_02

			dc.w barerts
			dc.w anim06_01
			dc.w anim02_03
			dc.w anim00_01
			dc.w barerts
			dc.w anim01_03
			dc.w anim03_01
			dc.w anim07_03

			dc.w barerts
			dc.w anim06_02
			dc.w anim02_02
			dc.w anim00_02
			dc.w barerts
			dc.w anim01_02
			dc.w anim03_02
			dc.w anim07_02

;animframe		dc.b $ff,$06,$02,$00,$ff,$01,$03,$07
;xscrolltab		dc.b $07,$05,$03,$01,$07,$05,$03,$01

;Lautsprecher links
animlist04lo		dc.b <anim04_01,<anim04_02,<anim04_03,<anim04_02,<anim04_01,<anim04_00
animlist04hi		dc.b >anim04_01,>anim04_02,>anim04_03,>anim04_02,>anim04_01,>anim04_00,$00

;Lautsprecher rechts
animlist05lo		dc.b <anim05_01,<anim05_02,<anim05_03,<anim05_02,<anim05_01,<anim05_00
animlist05hi		dc.b >anim05_01,>anim05_02,>anim05_03,>anim05_02,>anim05_01,>anim05_00,$00


;Lautsprecher links unten
animlist08lo		dc.b <anim08_01,<anim08_02,<anim08_03,<anim08_02,<anim08_01,<anim08_00
animlist08hi		dc.b >anim08_01,>anim08_02,>anim08_03,>anim08_02,>anim08_01,>anim08_00,$00

;Lautsprecher rechts unten
animlist09lo		dc.b <anim09_01,<anim09_02,<anim09_03,<anim09_02,<anim09_01,<anim09_00
animlist09hi		dc.b >anim09_01,>anim09_02,>anim09_03,>anim09_02,>anim09_01,>anim09_00,$00

trigtablo		dc.b $00
			dc.b $00
			dc.b <trigbottomleft
			dc.b <trigbottomright
			dc.b <trigbottomleft
			dc.b <trigright
			dc.b <trigbottomright
			dc.b $00
			dc.b <trigleft
			dc.b <trigleft

			dc.b <trigleft
			dc.b $00
			dc.b $00
			dc.b $00
			dc.b $00
			dc.b <trigright
			dc.b <trigright
			dc.b <trigright
			dc.b <trigright
			dc.b <trigright

			dc.b <trigright
			dc.b <trigright
			dc.b <trigright
			dc.b $00
			dc.b $00
			dc.b $00
			dc.b $00
			dc.b $00
			dc.b $00
			dc.b $00

			dc.b $00
			dc.b $00

trigtabhi		dc.b $01
			dc.b $01
			dc.b >trigbottomleft
			dc.b >trigbottomright
			dc.b >trigbottomleft
			dc.b >trigright
			dc.b >trigbottomright
			dc.b $01
			dc.b >trigleft
			dc.b >trigleft
			       
			dc.b >trigleft
			dc.b $01
			dc.b $01
			dc.b $01
			dc.b $01
			dc.b >trigright
			dc.b >trigright
			dc.b >trigright
			dc.b >trigright
			dc.b >trigright

			dc.b >trigright
			dc.b >trigright
			dc.b >trigright
			dc.b $01
			dc.b $01
			dc.b $01
			dc.b $01
			dc.b $01
			dc.b $01
			dc.b $01

			dc.b $01
			dc.b $01

; doanim			subroutine
			; lda framecount
			; asl
			; adc #<.animframe
			; sta .animjmp + 1
; .animjmp		jmp (.animframe)

; .step10			ldx #$00
			; lda step2tab,x
			; sta .step10 + 1
			; adc #<.animtgts10
			; sta .anim10jmp + 1
			; ldx #$01
			; lda #$fe
; .anim10jmp		jmp (.animtgts)
			; ;jmp .anim11

; ;-----------------------
; .anim00
; .step00			ldx #$00
			; lda step2tab,x
			; sta .step00 + 1
			; ;adc #0*12
			; sta .anim00jmp + 1
			; ldx #$01
			; lda #$fe
; .anim00jmp		jmp (.animtgts)
; ;-----------------------
; .anim01
; .step01			ldx #$00
			; lda step2tab,x
			; sta .step01 + 1
			; adc #<.animtgts01
			; sta .anim01jmp + 1
			; ldx #$01
			; lda #$fe
; .anim01jmp		jmp (.animtgts)

; ;-----------------------
; .anim02
; .step02			ldx #$00
			; lda step2tab,x
			; sta .step02 + 1
			; adc #<.animtgts02
			; sta .anim02jmp + 1
			; ldx #$01
			; lda #$fe
; .anim02jmp		jmp (.animtgts)
; .gosub02		jsr $1000
			; ;jmp .anim04
; ;-----------------------
; .anim03
; .step03			ldx #$00
			; lda step2tab,x
			; sta .step03 + 1
			; adc #<.animtgts03
			; sta .anim03jmp + 1
			; ldx #$01
			; lda #$fe
; .anim03jmp		jmp (.animtgts)
; .gosub03		jsr $1000
			; ;jmp .anim05

; ;-----------------------
; .anim06
; .step06			ldx #$00
			; lda step2tab,x
			; sta .step06 + 1
			; adc #<.animtgts06
			; sta .anim06jmp + 1
			; ldx #$01
			; lda #$fe
; .anim06jmp		jmp (.animtgts)
; .gosub06		jsr $1000
			; ;jmp .anim08
; ;-----------------------
; .anim07
; .step07			ldx #$00
			; lda step2tab,x
			; sta .step07 + 1
			; adc #<.animtgts07
			; sta .anim07jmp + 1
			; ldx #$01
			; lda #$fe
; .anim07jmp		jmp (.animtgts)
; .gosub07		jsr $1000
			; ;jmp .anim09
; ;-----------------------
; .anim08
; .step08			ldx #$00
			; lda step2tab,x
			; sta .step08 + 1
			; adc #<.animtgts08
			; sta .anim08jmp + 1
			; ldx #$01
			; lda #$fe
; .anim08jmp		jmp (.animtgts)
; ;-----------------------

; step2tab		dc.b $02,$02,$04,$04,$06,$06,$08,$08,$0a,$0a,$00,$00
; animframe		dc.b $ff,$00,$02,$06,$ff,$01,$03,$07
; ;xscrolltab		dc.b $07,$05,$03,$01,$07,$05,$03,$01

			; align 256,0
; .animtgts
; ;Hand links
; .animtgts00
			; dc.w anim00_03,anim00_02,anim00_01,anim00_00,anim00_01,anim00_02

; ;Hand rechts
; .animtgts01
			; dc.w anim01_03,anim01_02,anim01_01,anim01_00,anim01_01,anim01_02

; ;Flammen links
; .animtgts02
			; dc.w anim02_03,anim02_02,anim02_01,anim02_00,anim02_01,anim02_02

; ;Flammen rechts
; .animtgts03
			; dc.w anim03_03,anim03_02,anim03_01,anim03_00,anim03_01,anim03_02

; ;Lautsprecher links
; .animtgts04
			; dc.w anim04_03,anim04_02,anim04_01,anim04_00,anim04_01,anim04_02

; ;Lautsprecher rechts
; .animtgts05
			; dc.w anim05_03,anim05_02,anim05_01,anim05_00,anim05_01,anim05_02

; ;Lautsprecher Flammen links
; .animtgts06
			; dc.w anim06_03,anim06_02,anim06_01,anim06_00,anim06_01,anim06_02

; ;Lautsprecher Flammen rechts
; .animtgts07
			; dc.w anim07_03,anim07_02,anim07_01,anim07_00,anim07_01,anim07_02

; ;Lautsprecher links unten
; .animtgts08
			; dc.w anim08_03,anim08_02,anim08_01,anim08_00,anim08_01,anim08_02

; ;Lautsprecher rechts unten
; .animtgts09
			; dc.w anim09_03,anim09_02,anim09_01,anim09_00,anim09_01,anim09_02

; ;Hunter Fackel oben
; .animtgts10
			; dc.w anim10_03,anim10_02,anim10_01,anim10_00,anim10_01,anim10_02

; ;Hunter Fackel unte
; .animtgts11
			; dc.w anim11_03,anim11_02,anim11_01,anim11_00,anim11_01,anim11_02
; .animframe
			; dc.w .step10
			; dc.w .step00
			; dc.w .step02
			; dc.w .step06
			; dc.w .step10
			; dc.w .step01
			; dc.w .step03
			; dc.w .step07


;--------------------------------------
textscroller		subroutine
;sprite xpos 
;$d008 $e0-$e7
;$d00a $00-$07
;$d00a $58-$5f
;$d00e $70-$77

;bytes to copy in 4 frames
;45 bytes text copy + 1 new byte
;5*16=80 bytes sprite copy + 16 new bytes
		
			ldy framecount
			lda xscroll
			cmp #$07
			beq .doshift	;carry is set!
			jmp .overshift

.doshift
			ldx #%10111111
			lda spritetext+1
			sta spritetext+0
			lda spritetext+2
			sta spritetext+1
			lda spritetext+3
			sta spritetext+2
			lda spritetext+4
			sta spritetext+3
			lda spritetext+5
			sta spritetext+4

			lda stagescreen+24*40+1
			sta stagescreen+24*40+0
			sax stagescreen+23*40+0
			asl
			asl
			sta spritetext+5
i			set 1
			repeat 38
			lda stagescreen+24*40+1+i
			sta stagescreen+24*40+i
			sax stagescreen+23*40+i
i			set i+1
			repend

.buf1			lda #$80
			sec
			ror		;carry is set -> ora #$80 + lsr = ora #$40
			lsr
			sta stagescreen+24*40+39
			sax stagescreen+23*40+39


			lda spritetext+6
			sta .buf1+1
			lda spritetext+7
			sta spritetext+6
			lda spritetext+8
			sta spritetext+7
			lda spritetext+9
			sta spritetext+8
			lda spritetext+10
			sta spritetext+9
			lda spritetext+11
			sta spritetext+10

.get			lda scrolltext
			bne .newchar

.inittext		lda #<scrolltext
			sta .get+1
			lda #>scrolltext
			sta .get+2
			lda #$80
			jmp .noinc

.newchar		inc .get+1
			bne .noinc
			inc .get+2

.noinc			sta spritetext+11
.overshift		ldx textoffsettab,y
			lda copyalternatetab,y
			bne .spritecopyb

;mixingbuffer2 playback
.spritecopya		lda spritetext,x
			sta spritechar0a+1
			lda spritetext+1,x
			sta spritechar1a+1
			lda spritetext+2,x
			sta spritechar2a+1
			ldx posoffsettab,y
			stx spritechar0apos+1
			rts

;mixingbuffer1 playback
.spritecopyb		lda spritetext,x
			sta spritechar0b+1
			lda spritetext+1,x
			sta spritechar1b+1
			lda spritetext+2,x
			sta spritechar2b+1
			ldx posoffsettab,y
			stx spritechar0bpos+1
			rts
;sprites
;04 15
;26 37
;01 23 
;45 67
			align 256,0
xscrolltab		dc.b $07,$05,$03,$01,$07,$05,$03,$01
textoffsettab		dc.b $00,$03,$06,$09,$00,$03,$06,$09
posoffsettab		dc.b $00,$00,$40,$40,$80,$80,$c0,$c0
copyalternatetab	dc.b $00,$01,$00,$01,$00,$01,$00,$01
spriteoffsettab		dc.b firstsprite+2,firstsprite+2,firstsprite+2,firstsprite+2,firstsprite,firstsprite,firstsprite,firstsprite
			
			
animcode		include "gfx/animcode.asm"


scrolltext
 scru "                "
 scru "       next level by performers"
 scru "       released at x 2023"
 scru "       could only happen because of these awesome people:"
 scru "       johannes bjerregaard (RIP) composed this song"
 scru "       lman made this cool cover"
 scru "       thcm combined sample-music with sideborder-scrollers + samples+nufli + fullscreen-scrolling-no-vsp + greetings-world-map"
 scru "       bitbreaker made disk-loading, double-3d-vectors, shrine-hunter, eagle-fader, ikea-bobby, ribbons, geos-fun + shadowscroller"
 scru "       pex mahoney tufvesson made noisefader, torus-fighter and reminded you of the 100-best-moments-of-our-lives"
 scru "       knut made world-first two-pixels-per-frame-koala-scroller + koala-parallax + metaballs"
 scru "       yps made chess-zoomer-schwurbel-scroller + spaceship-fader"
 scru "       redcrab drew the noisefader-border-font-graphics, various sprites graphics throughout the demo + the thievish eagle"
 scru "       devilock made in-demo-musics"
 scru "       linus made the in-demo-musics on disk 3"
 scru "       jammer made various digi and tiny musics"
 scru "       facet made the shrine, spaceship, intro, credits + bunny-graphics"
 scru "       axis made those nonconvex-sierpinsky-3d-triangles"
 scru "       veto made this performers stage + greetings-world-map"
 scru "       peiselulli made the falling-logo-intro + next-level-fpp"
 scru "       joe made the koala-scrolling-graphics + harlequin-portrait"
 scru "       dk made gfx for ikea + faithless + performers-sierpinsky-logo + double-vector + harlequin-nufli-digi-fixes"
 scru "       ptoing made the shadowscroller-font"
 scru "       trap made the we-don't-need-this-transition-but-we'll-keep-it-anyway on disk 4"
 scru "       krill made the huge-petscii-font-enlarger"
 scru "                      "
 scru "every day you use the c64 a pokemon dies"
 scru "                      "
 scru "never too late to have a happy childhood"
 scru "                      "
 scru "another visitor. stay a while. stay forever."
 scru "                      "
 scru "thanks for watching"
 scru "                      "

; scru  " 0.001GHz, 0.00000005GB memory, 16 cols "
; scru "                      "
; scru  "Every day you use the C64 a pokemon dies"
; scru "                      "
; scru  "  this is the thrust concert demo 2016  "
; scru "                      "
; scru  "    still rocking c64 after 30 years    "
; scru "                      "
; scru  "tnx to the organizers of X-2016. Cheers!"
; scru "                      "
; scru  " Facebook is the root of so much nothing"
; scru "                      "
; scru  " 1GB = download this demo 2500000 times "
; scru "                      "
; scru  " Internet is just a bigger floppy disk  "
; scru "                      "
; scru  "  People who likes sports are useless   "
; scru "                      "
; scru  "Vacuum cleaning is another form of yoga "
; scru "                      "
; scru  " 1MHz, enough to get Mankind on the moon"
; scru "                      "
; scru  "Faster computers is the root of all evil"
; scru "                      "
; scru  "Achievement unlocked: VSP crash in 2017 "
; scru "                      "
; scru  "              We love LFT               "
; scru "                      "
; scru  "Don't be evil, your mom wouldn't like it"
; scru "                      "
; scru  " Have you ever had a sense of Deja Vu?  "
; scru "                      "
; scru  "Is Game of Thrones some kind chess game?"
; scru "                      "
; scru  "  Your new computer won't be at X'2046  "
; scru "                      "
; scru  "Imagine all you can do without Cable-TV "
; scru "                      "
; scru  "Reality is a sign of too little alcohol "
; scru "                      "
; scru  " Have you ever had a sense of Deja Vu?  "
; scru "                      "
; scru  "Deja Fu - I've been hit like this before"
; scru "                      "
; scru  "Achievement unlocked: Gestampte muisjes "
; scru "                      "
; scru  "    My C64 is CIA safe. How's yours?    "
; scru "                      "
; scru  "Internet of Things: the start of Skynet!"
; scru "                      "
; scru  " Help the scene. Teach your kids BASIC! "
; scru "                      "
; scru  "      Too much SID is good for you.     "
; scru "                      "
; scru  "            Oxymorons isn't             "
; scru "                      "
; scru  "  Let's Censor Booze Design into Shape  "
; scru "                      "
; scru  "C64 - free from NSA backdoors since 1982"
; scru "                      "
; scru  "        Dane is a coder who isn't       "
; scru "                      "
; scru  " Your children are crying: IRQ or NMI?  "
; scru "                      "
; scru  "When swapping demos today, stamps back? "
; scru "                      "
; scru  "  Why is everyone here wearing black?   "
; scru "                      "
; scru  " When Twitter goes bankrupt: use noters "
; scru "                      "
; scru  "Only C64 will survive a nuclear disaster"
; scru "                      "
; scru  "Never too late to have a happy childhood"
; scru "                      "
; scru  " Coffe is toxic. You knew that already. "
; scru "                      "
; scru  "      Bitterballen is good for you.     "
; scru "                      "
; scru  " We make CSDB one-liners look like poop "
; scru "                      "
; scru  "-intentionally blank until HCL delivers-"
; scru "                      "
; scru  " 48516 SIDs made so far. Where's yours? "
; scru "                      "
; scru  "in-demo-purchase: $$ to speed up loading"
; scru "                      "
; scru  "  like us on fb to see the hidden part  "
; scru "                      "
; scru  "in a 1541 dream, spindle bitfires krill "
; scru "                      "
; scru  "     Doctors Without Side-borders       "
; scru "                      "
; scru  "If I agreed with you we'd both be wrong."
; scru "                      "
; scru  " Who got the release points for PacMan? "
; scru "                      "
; scru  "   Nostalgia isn't what it used to be.  "
; scru "                      "
 dc.b $00
			echo "Democode end before $ba00: ",*

;------------------------------------------------------------------------------
;gfx data
;------------------------------------------------------------------------------
			org stagefont
;			incbin "gfx/1x2font.prg",2
			incbin "gfx/stage_font_upper.chr",0,1024
			
			org stagescreen
stagecolor		incbin "gfx/_stage_split_1.col",0,6*40
			incbin "gfx/_stage_split_2.col",6*40,4*40
			incbin "gfx/_stage_split_3.col",10*40,4*40
			incbin "gfx/_stage_split_4.col",14*40,11*40
			
			org charset1
			incbin "gfx/_stage_split_1.chr",0,$0600


;------------------------------------------------------------------------------
;fadein code
;------------------------------------------------------------------------------
;{1} = line number
			mac do_line
			if {1}=20
lastline
			endif
			
.x			ldx #$27+[{1}/2]
			lda #$27
			sec
			sbc .x+1
			tay
			
			lda .off1+1
			clc
			adc #$40
			sta .off1+1
			cmp #<[screendata+[{1}*40]]
			bne .noinc
			dec .x + 1
.noinc
			cpy #$28
			bcs .nextline
			
.off1			lda screendata+[{1}*40],x
			sta stagescreen+[{1}*40],x

			lda .off2+1
			clc
			adc #$40
			sta .off2+1

.off2			lda screendata+[{1}*40]+40,y
			sta stagescreen+[{1}*40]+40,y

.nextline		
			endm
			
;-----------------------
fadelines		subroutine	
			do_line 0
			do_line 2
			do_line 4
			do_line 6
			do_line 8
			do_line 10
			do_line 12
			do_line 14
			jmp fadelines2
;			do_line 16
;			do_line 18
;			do_line 20
			
;			do_line 22
;			do_line 24
;			rts

;------------------------------------------------------------------------------
			org charset2
			incbin "gfx/_stage_split_2.chr"

			org charset3
			incbin "gfx/_stage_split_3.chr"

			org charset4
			incbin "gfx/_stage_split_4.chr",0,$700
;-----------------------
fadelines2		subroutine	
			; do_line 0
			; do_line 2
			; do_line 4
			; do_line 6
			; do_line 8
			; do_line 10
			; do_line 12
			; do_line 14
			; jmp fadelines2
			do_line 16
			do_line 18
			do_line 20
			
;			do_line 22
;			do_line 24
			rts
					
;------------------------------------------------------------------------------
;data or code beginning from here will be overwritten
;------------------------------------------------------------------------------
			org spritefont
i			set 0			
			repeat 64
;			incbin "gfx/1x2font.prg",2+i*8,4
			incbin "gfx/stage_font_upper.chr",i*8,4
i			set i+1
			repend

i			set 0			
			repeat 64
			incbin "gfx/stage_font_upper.chr",4+i*8,4
i			set i+1
			repend

i			set 0			
			repeat 64
			incbin "gfx/stage_font_upper.chr",512+i*8,4
i			set i+1
			repend

i			set 0			
			repeat 64
			incbin "gfx/stage_font_upper.chr",512+4+i*8,4
i			set i+1
			repend
			
			
;------------------------------------------------------------------------------
;init part
;------------------------------------------------------------------------------
			org $ec00
initpart		subroutine
			ldx #$27
			lda #$01
.fill1			sta colorram+23*40,x
			sta colorram+24*40,x
			dex
			bpl .fill1

			ldx #$00
.convert1		lda scrolltext,x
			asl
			asl
.convert2		sta scrolltext,x
			beq .done
			inx
			bne .convert1
			inc .convert1+2
			inc .convert2+2
			bne .convert1
			
.done			ldx #$0b
			lda #$80
.clear1			sta spritetext,x
			dex
			bpl .clear1
			
			lda #$00
			sta $d017
			sta $d01d
			sta $d01c
			sta $d01b
			lda #$d0
			sta $d010

			lda #$e0
			sta $d008
			lda #$00
			sta $d00a
			lda #$58
			sta $d00c
			lda #$70
			sta $d00e
			lda #$e9
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f

			ldx #$01
			stx $d02b
			stx $d02c
			stx $d02d
			stx $d02e
			stx $d02f
			
			ldx #[stagesprites-$c000]/64
			stx spritepointer+4
			inx
			stx spritepointer+5
			inx
			stx spritepointer+6
			inx
			stx spritepointer+7

			lda #$07
			sta framecount
			sta xscroll
			ora #$08
			sta xscroll8
			lda #$f0		;233 cycle 26
			sta $d015
			rts
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
			
			align 256,0
;------------------------------------------------------------------------------
initnmi			subroutine
;------------------------------------------------------------------------------
			if stablenmi=1
			jsr copynmi
			endif
			jsr vblank
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
; .sync1			lda $d011
			; bpl .sync1
; .sync2			lda $d011
			; bmi .sync2

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
			cli
			
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
	
.skip3			lda #63-1	
			sta $dc06	
			lda #nmifreq
			sta $dd04	
			lda #$00	
			sta $dc07	
			sta $dd05	
			lda #$4c	
			sta $dc04	
			
			if stablenmi=0
			lda #<nmiplay
			sta $fffa
			lda #>nmiplay
			sta $fffb

			else

			lda #<$dc04
			sta $fffa
			lda #>$dc04
			sta $fffb
			endif
			
			lda #$11	
			if replayrate=2
			jsr .wait12
			jsr .wait12
			nop
			nop
			nop
			nop
			nop
			endif
sucks			sta $dd0e	;waveform stable @ line 7 cycle 52 (can be repositioned)
	
.cia_type		ldx #$00	
			bmi .skip4
			
.skip4			ldx #<nmidest
			stx $dc05
			if fastjitter=1
			nop		;bit $00 = 8 jitter cases nop = 7 jitter cases
			else
			bit $00
			endif
			nop

sucks2			sta $dc0f	;write must be stable @ line 8 cylce 08
			rts
			
.waitcycles		ldy #$06
.loop1		     	dey
			bne .loop1
			inx
			nop
			nop
.wait12			rts

			if stablenmi=1
;------------------------------------------------------------------------------
copynmi			subroutine
;------------------------------------------------------------------------------
			ldy #$00
.copy2			ldx #$00
.copy			lda nmi1,y
.dest			sta nmidest,x
			iny
			inx
.check			cpx .nmilen
			bne .copy
			inc .check+1
			inc .dest+2
			cpy #nmi9-nmi1
			bne .copy2
			rts
			
.nmilen			dc.b nmi2-nmi1,nmi3-nmi2,nmi4-nmi3,nmi5-nmi4	;mustn't cross a page!!!
			dc.b nmi6-nmi5,nmi7-nmi6,nmi8-nmi7,nmi9-nmi8

;------------------------------------------------------------------------------
;nmi entry routines
;------------------------------------------------------------------------------
nmi1			jmp nmiplaybuf			;3 Takte
			
nmi2			sta.w abuf+1			;4 Takte
			jmp nmiplaynobuf
			
nmi3			jmp nmiplay			;5 Takte
			
nmi4			bit $00
			jmp nmiplaybuf			;6 Takte
			
nmi5			nop				;7 Takte
			jmp nmiplay
			
nmi6			bit $00				;8 Takte
			jmp nmiplay

nmi7			nop				;9 Takte
			nop
			jmp nmiplay

nmi8			bit $00				;10 Takte
			nop
			jmp nmiplay
nmi9
			
			endif			;stablenmi=1
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
;---------------------------------------
; fade irq's
;---------------------------------------
			align 256,0
fadeirq0		subroutine
			sta areg
			lda #%00010010
			sta $d018
			
			lda #$18
			sta $d016

			lda #$1b
			sta $d011

			inc $d019
			
			lda #6*8+50
			sta $d012
			
			lda #<fadeirq1
			sta $fffe
;			lda #>irq1
;			sta $ffff
			
			lda areg
			rti

;---------------------------------------
fadeirq1		subroutine
			sta areg
		
			lda #10*8+50
			sta $d012
			lda #<fadeirq2
			sta $fffe
;			lda #>irq2
;			sta $ffff
			
			inc $d019
			
			delay 18
			
			lda #%00010100
			sta $d018
			
			lda areg
			rti
;---------------------------------------
fadeirq2		subroutine
			sta areg
		
			lda #14*8+50
			sta $d012
			lda #<fadeirq3
			sta $fffe
;			lda #>irq2
;			sta $ffff
			inc $d019
			
			delay 18

			lda #%00010110
			sta $d018

			lda areg
			rti
;---------------------------------------
fadeirq3		subroutine
			sta areg
			
			lda #22*8+50
			sta $d012

			lda #<fadeirq4
			sta $fffe
;			lda #>irq3
;			sta $ffff
			
			inc $d019

			delay 18

			lda #%00011000
			sta $d018
			lda areg
			rti
;---------------------------------------
fadeirq4		subroutine
;			inc $d020
			sta areg
			stx xreg
			sty yreg

			jsr fadelines
			
			lda #$2d
			sta $d012

			lda #<fadeirq0
			sta $fffe
;			lda #>irq3
;			sta $ffff
			
			inc $d019
			
			lda areg
			ldx xreg
			ldy yreg
;			dec $d020
			rti

			echo "Initpard End: ",*

;------------------------------------------------------------------------------
			org $f000
screendata		incbin "gfx/_stage_split_1.scr",0,6*40
			incbin "gfx/_stage_split_2.scr",6*40,4*40
			incbin "gfx/_stage_split_3.scr",10*40,4*40
			incbin "gfx/_stage_split_4.scr",14*40,11*40

;------------------------------------------------------------------------------
			org $f400
fadein			subroutine
			jsr vblank
			ldx #$00
			stx $d011
			stx $d020
			stx $d021
			stx $d015
			stx $dd00
			lda #$d8
			sta $d016
			lda #$0e
			sta $d022
			lda #$0f
			sta $d023

.copy1			lda stagecolor,x
			sta colorram,x
			lda stagecolor+$100,x
			sta colorram+$100,x
			lda stagecolor+$200,x
			sta colorram+$200,x
			lda stagecolor+$300,x
			sta colorram+$300,x
			lda #$00
			sta stagescreen,x
			sta stagescreen+$100,x
			sta stagescreen+$200,x
			sta stagescreen+$300,x
			inx
			bne .copy1

			jsr vblank

			lda #$7f
			sta $dc0d
			lda $dc0d

			lda #$01
			sta $d019
			sta $d01a

			lda #<fadeirq0
			sta $fffe
			lda #>fadeirq0
			sta $ffff
			lda #$2d
			sta $d012

			cli

			ifnconst release
;			jsr fadeinfix
;			lda #$ef
;.waitspace		cmp $dc01
;			bne .waitspace

			else
			jsr link_load_next_comp
			;jsr link_load_next_raw
			;stop_music_nmi
			endif

			jsr initpart

			jmp main

;-----------------------
; fadeinfix		ldx #$00
; .copy2			lda screendata,x
			; sta stagescreen,x
			; lda screendata+$100,x
			; sta stagescreen+$100,x
			; lda screendata+$200,x
			; sta stagescreen+$200,x
			; lda screendata+$300-8,x
			; sta stagescreen+$300-8,x
			; inx
			; bne .copy2
			; rts
			
;------------------------------------------------------------------------------
			org $fbea
vblank			subroutine
.1			bit $d011
			bpl .1
.2			bit $d011
			bmi .2
wait14			nop			
barerts
wait12			rts				;delay 12 cycles if called by jsr
