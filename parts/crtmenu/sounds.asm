;demo instructions 
;press 1-9 and 0 for samples 1-10
;press space to stop replay using NMI and IRQ


;for binary blob inclusion in your code set release variable and use jmp table @ $6000

;thc_init		$6000
;inits NMI and raster IRQ for replay. Raster IRQ starts at line $fd and NMI occupies every 2nd (even) raster line. You could for example wait for line $fb and do your stuff inside the main thread.
;Before calling thc_init IRQ's and NMI's should be disabled and $01 has to be set to $01. Kernal is not availabe during replay and sprites will be turned off for timing reasons.
;Maybe 1 or 2 spriteslots are possible, but the code has to be adjusted to it.

;thc_playsmpl		$6003
;triggers sample number in akku, triggering a new sample while a sample is already playing overwrites the currently played sample

;thc_stop		$6006
;stops NMI, IRQ and clears SID output

;You can't use the screen @ $0400. The replayer occupies the beginning of each page from $0000 - $0800. You could move it to $0c00.
;Free memory is from $0808-$5fff and $d000-$fffd and zeropage is at least free from $40-$df


			processor 6502
			incdir "../../util/dasm/include"
			include "standard.asm"

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
			inx
			jsr vblank
			jsr thc_init

.forever		lda #$fb
.wl1			cmp $d012
			bne .wl1

			jsr checkkeyboard
			beq .noeffect
			bmi .stopreplay
			jsr thc_playsmpl
.noeffect		jmp .forever
						
.stopreplay		jsr thc_stop
.forever2		inc $d020
			jmp .forever2
			
;------------------------------------------------------------------------------
checkkeyboard		subroutine
;------------------------------------------------------------------------------
			lda #%01111111		;row 1,2
			sta $dc00
			lda $dc01
			cmp #%11111110		;1
			beq .key1
			cmp #%11110111		;2
			beq .key2
			cmp #%11101111		;space
			beq .keyspace
		
			lda #%11111101		;row 3,4
			sta $dc00
			lda $dc01
			cmp #%11111110		;3
			beq .key3
			cmp #%11110111		;4
			beq .key4
			
			lda #%11111011		;row 5,6
			sta $dc00
			lda $dc01
			cmp #%11111110		;5
			beq .key5
			cmp #%11110111		;6
			beq .key6
			
			lda #%11110111		;row 7,8
			sta $dc00
			lda $dc01
			cmp #%11111110		;7
			beq .key7
			cmp #%11110111		;8
			beq .key8
			lda #%11101111		;row 9,0
			sta $dc00
			lda $dc01
			cmp #%11111110		;9
			beq .key9
			cmp #%11110111		;0
			beq .key0
		
.nokey			lda #$00		;$00 no key 
			rts
			
.key1			lda #$01
			rts
.key2			lda #$02
			rts
.keyspace		lda #$80
			rts
.key3			lda #$03
			rts
.key4			lda #$04
			rts
.key5			lda #$05
			rts
.key6			lda #$06
			rts
.key7			lda #$07
			rts
.key8			lda #$08
			rts
.key9			lda #$09
			rts
.key0			lda #$0a
			rts

			else
			include "../../bitfire/loader/loader_acme.inc"
			include "../../bitfire/macros/link_macros_dasm.inc"
			endif
			; jmp thc_init		;$2000
			; jmp thc_playsmpl	;$2003

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
						
timingcolors		equ 1			;0=no colors 1=display rastertiming

debug			equ 0			;enable decompression counter

echodistance		equ 15			;fast delay buffer distance from 1 to 15

external		equ 0			;0=use internal settings 1=include external settings

;------------------------------------------------------------------------------
;internal settings
;------------------------------------------------------------------------------
			if external=1
			include "thc_settings.asm"
			else			;external=1
preset			equ 0			;0 = user defined
						;1 = 4ch ProTracker
						;2 = MLC1
						;3 = SCC Loop Station
						;4 = Fast delay
						;5 = 4ch 8bit signed
						;6 = other specs
						;7 = Fantasmolytic
						;8 = MLC1+
						;9 = MLC1 Foldback
						;10 = Fantasmolytic+
						
includesid		equ 0			;0=no sid tune 1=play sid
volumeboost		equ 0			;possible values are 0-8 for 0, 25 ,50 , 75, 100 ,125, 150, 175, 200% boost, 9 for global volume / foldback tables
sampleoutput		equ 0			;0=waveform 8bit 1=digimax for emulator 2=4bit $d418  3=7bit $d418  4=$d020 colors  5=$d021 colors 6=pwm gate
						;if sampleoutput=2 or 3 then volumeboost has to be 0 !!!
replayrate		equ 0			;0=7812hz (1=11718hz 2=15624hz stablenmi has to be 0!)
bitdepth		equ 4			;0=4 bit samples 1=5 bit samples 2=6bit samples 3=7bit samples 4=8bit samples mixing
signed			equ 0			;0=unsigned samples 1=signed samples, needed for loop station mixing
loopstation		equ 0 			;0=disbale loop station 1=enable loop station with sample 31 as loop buffer
digivoices		equ 1			;2, 3 or 4 digi voices
sampleoffsetsupport	equ 0			;0=no global sampleoffset support 1=turn on global sampleoffset support
stablenmi		equ 1			;0=use normal nmi 1=use stable nmi
screen			equ 1			;0=screen off 1=screen on
controlchannel		equ 0			;0=no control channel 1=use last channel as control channel
siddelay		equ 7			;first delay of the modplay to sync goatracker sid and protracker module
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
			if preset<2		;0=user defined, 1=4ch Protracker
thc_chn1vol		equ 0
thc_chn1per		equ 0
thc_chn1off		equ 0

thc_chn2vol		equ 1
thc_chn2per		equ 1
thc_chn2off		equ 1

thc_chn3vol		equ 1
thc_chn3per		equ 1
thc_chn3off		equ 1

thc_chn4vol		equ 1
thc_chn4per		equ 1
thc_chn4off		equ 1

thc_chn5vol		equ 1
thc_chn5per		equ 1
thc_chn5off		equ 1

thc_chn6vol		equ 1
thc_chn6per		equ 1
thc_chn6off		equ 1

thc_chn7vol		equ 1
thc_chn7per		equ 1
thc_chn7off		equ 1

thc_chn8vol		equ 1
thc_chn8per		equ 1
thc_chn8off		equ 1
			endif	;preset<2
			
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
			
			if preset=3		;MLC2
thc_chn1vol		equ 1
thc_chn1per		equ 1
thc_chn1off		equ 1

thc_chn2vol		equ 0
thc_chn2per		equ 1
thc_chn2off		equ 1

thc_chn3vol		equ 0
thc_chn3per		equ 0
thc_chn3off		equ 1
			endif	;preset=3

			if preset=4		;Fast delay
thc_chn1vol		equ 1
thc_chn1per		equ 1
thc_chn1off		equ 1
thc_chn2vol		equ 0
thc_chn2per		equ 1
thc_chn2off		equ 1
			endif	;preset=4
			
			if preset=5
thc_chn1vol		equ 0
thc_chn1per		equ 1
thc_chn1off		equ 1
thc_chn2vol		equ 0
thc_chn2per		equ 0
thc_chn2off		equ 1
			endif	;preset=5
			
			if preset=6
thc_chn1vol		equ 0
thc_chn1per		equ 1
thc_chn1off		equ 1

thc_chn2vol		equ 0
thc_chn2per		equ 0
thc_chn2off		equ 1

			endif	;preset=6
			
			if preset=7		;Fantasmolytic Style
thc_chn1vol		equ 0
thc_chn1per		equ 1
thc_chn1off		equ 1

thc_chn2vol		equ 0
thc_chn2per		equ 0
thc_chn2off		equ 1

			endif	;preset=7

			if preset=8		;MLC1+
thc_chn1vol		equ 1
thc_chn1per		equ 1
thc_chn1off		equ 1

thc_chn2vol		equ 1
thc_chn2per		equ 1
thc_chn2off		equ 1

thc_chn3vol		equ 0
thc_chn3per		equ 0
thc_chn3off		equ 1
			endif	;preset=8

			if preset=9		;MLC1 Foldback
thc_chn1vol		equ 1
thc_chn1per		equ 1
thc_chn1off		equ 1

thc_chn2vol		equ 0
thc_chn2per		equ 1
thc_chn2off		equ 1

thc_chn3vol		equ 0
thc_chn3per		equ 0
thc_chn3off		equ 1
			endif	;preset=8
			if preset=10		;Fantasmolytic+ Style
thc_chn1vol		equ 0
thc_chn1per		equ 1
thc_chn1off		equ 1

thc_chn2vol		equ 0
thc_chn2per		equ 0
thc_chn2off		equ 1

thc_chn3vol		equ 0
thc_chn3per		equ 0
thc_chn3off		equ 1
			endif	;preset=10
			endif	;external
;------------------------------------------------------------------------------
;zeropage
;------------------------------------------------------------------------------
zeropagecode		equ $02		;start of zeropage routines up to $ed
			if loopstation=1
zeropage		equ $f6		;only 8 bytes zp
			else
zeropage		equ $3d		;normal $ee (8 channels a 2 bytes)
			endif

goatlo			equ $fe		;used by sid replayer
goathi			equ $ff

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
			
clearend		equ zp

;------------------------------------------------------------------------------
;constants
;------------------------------------------------------------------------------
periodsteplength	equ 39				;39 stepbytes per note

			if replayrate=0
mixingbufferlength	equ 156				;312 rasterlines/2
nmifreq			equ $007d
			endif

			if replayrate=1
mixingbufferlength	equ 234				;312 rasterlines/1.33
nmifreq			equ $0053
			endif

			if replayrate=2
mixingbufferlength	equ 156				;312 rasterlines
nmifreq			equ $003e
			endif
			
samples			equ 31				;samples 0-31
nmidest			equ $0102 			;destination of nmi1 routine


			if loopstation=1
loopframes		equ [sample31end-sample31]/mixingbufferlength				
			echo "LoopFrames", loopframes
			endif

;------------------------------------------------------------------------------
;tables
;------------------------------------------------------------------------------
debuglo			equ $0110
debughi			equ $0111
debuglo2		equ $0112
debughi2		equ $0113

debugmem		equ $4000

notestablelo		equ $0608			;max 124 periods
notestablehi		equ $0684
notesaddlo		equ $0708
notesaddfrac		equ $0784

mixingbuffer1		equ $0408
mixingbuffer2		equ $0508

			if preset=4			;Fast delay
echobuffer		equ $c000			;16 pages of delay data
echobuffers 		equ 16				;max. 16 buffers allowed
			if playlzstream=1
lzshistory		equ $bf00
			endif
			else
			if playlzstream=1
lzshistory		equ $cf00
			endif
			endif	;end preset4

silentbuffer		equ $e000			;shares the safety margin of the last sample
volumetable		equ $e000			;up to 32 tables for different volume, first volume is silent, last volume is max. $1f

			if bitdepth=0
periodtable		equ $e110			;6 periodtables per page 124 pages up to $ffff
			endif
			if bitdepth=1
periodtable		equ $e120			;5 periodtables per page 124 pages up to $ffff
			endif
			if bitdepth=2
			if digivoices<5
periodtable		equ $e140			;4 periodtables per page 124 pages up to $ffff
			endif
			if digivoices=5
periodtable		equ $e134			;5 periodtables per page 124 pages up to $ffff
			endif
			if digivoices=6
periodtable		equ $e12b			;5 periodtables per page 124 pages up to $ffff
			endif
			endif				;bitdepth=2
			if bitdepth=3
			if digivoices=3
periodtable		equ $e156			;4 periodtables per page 124 pages up to $ffff
			else
periodtable		equ $e180			;3 periodtables per page 93 pages up to $ffff
			endif
			endif				;bitdepth=3
			if bitdepth=4
periodtable		equ $f000			;6 periodtables per page 96 pages up to $ffff
			endif



			org $6000
;------------------------------------------------------------------------------
thc_init		subroutine
;------------------------------------------------------------------------------
			jmp .initreplay		;$6000 for init
thc_playsmpl		jmp .playsmpl		;$6003 for trigger sample number from akku
thc_stop		jmp stoptune		;$6006 for stop replay/NMI/IRQ

.playsmpl		sta soundeffect1+1
			rts
			
.initreplay		jsr initnmi		;has to be called before javainit
			jsr javainit		;trashes some of the upper initroutines

			if sampleoutput=0
			lda #$f0		;set sustain to max on voice 3
			sta $d414
			endif
			
			jsr vblank
			lda $d011
			and #%01111111
			sta $d011
			
			lda #$7f
			sta $dc0d
			lda $dc0d

			ldx #$00
			stx $d015
			inx
			stx $d019
			stx $d01a
			
			lda #<irq1
			sta $fffe
			lda #>irq1
			sta $ffff	
			lda #$fd
			sta $d012
			
			lda #$fb
.wait1			cmp $d012
			bne .wait1
.wait2			cmp $d012
			beq .wait2
			lda $dd0d
			lda #$81
			sta $dd0d
			cli
			rts


			align 256,0
;------------------------------------------------------------------------------
irq1			subroutine
;------------------------------------------------------------------------------
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

			if detachmixer=0
			stx startmixing+1
			endif
			
			eor #$01
			sta bufferpointer+1
			
			if detachmixer=1
			
;detach mixer task from IRQ
			lda #>.mixtask
			pha
			lda #<.mixtask
			pha
			lda #$00
			pha
			rti

.mixtask		
			if timingcolors=1
			lda #$0b
			sta $d020
			endif
			
			jsr mixer
			
			if timingcolors=1
			lda #$00
			sta $d020
			endif
			endif			;detachmixer=1
			
.areg			lda #$00
.xreg			ldx #$00
.yreg			ldy #$00
			rti

;------------------------------------------------------------------------------
vblank			subroutine
.1			bit $d011
			bpl .1
.2			bit $d011
			bmi .2
			rts

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
			
			endif				;stablenmi=1
			
			align 256,0
;------------------------------------------------------------------------------
initnmi			subroutine
;------------------------------------------------------------------------------
			if stablenmi=1
			jsr copynmi
			endif
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
   			endif

			if sampleoutput=1
;			inc $d020
;			dec $d020
			sta $de00
   			endif

			if sampleoutput=2 | sampleoutput=3
			sta $d418
   			endif

			if sampleoutput=0
			lda #$01
			sta $d412
			endif

			inc fetch+1

abuf			lda #$00
			jmp $dd0c			;40 takte für waveform output + 6-13 für init +3 für jmp + 7 für interrupt=56 - 63 cycles je nmi=9828 cycles worst case

;------------------------------------------------------------------------------
;8bit mixing
;------------------------------------------------------------------------------
samplefetch1a		lda silentbuffer,x 		;4.5
mixswitch1		sta mixingbuffer2,x		;4=20
samplefetch1b		lda silentbuffer,x 		;4.5
mixswitch2		sta mixingbuffer2+periodsteplength,x		;4=20
samplefetch1c		lda silentbuffer,x 		;4.5
mixswitch3		sta mixingbuffer2+periodsteplength*2,x		;4=20
samplefetch1d		lda silentbuffer,x 		;4.5
mixswitch4		sta mixingbuffer2+periodsteplength*3,x		;4=20
			dex				;2
			bpl samplefetch1a		;3
.exit			rts
			rend
nmi_end

;------------------------------------------------------------------------------
javainit		subroutine
;------------------------------------------------------------------------------
			lda #$00
			
			ldx #clearend-clearstart-1
.loop1			sta clearstart,x
			dex
			bpl .loop1

			inx

.loop2			lda nmi_start,x
			sta.wx nmiplay,x
			inx
			cpx #nmi_end-nmi_start
			bne .loop2
			
			jsr clearsid		;waveform or digimax

			lda #$08
			sta $d417
			lda #$0f
			sta $d418
			
			ldx #$00	
			lda #$80		;clear all mixingbuffers
.loop4			sta silentbuffer,x
			inx
			bne .loop4
			
.mixbuffer		sta mixingbuffer1,x
			sta mixingbuffer2,x
			inx
			cpx #mixingbufferlength
			bne .mixbuffer
			rts
			
		
;------------------------------------------------------------------------------
stoptune		subroutine
;stop replay
			lda #$7f
			sta $dd0d
			lda $dd0d
			lda #$08
			sta $dd0e
			lda #$00
			sta $d01a
			inc $d019
			
clearsid		subroutine
			ldx #$18
			lda #$00
.loop1			sta $d400,x
			dex
			bpl .loop1
			rts
						
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
soundeffect{1}		lda #$00			;$00 - don't trigger soundeffect
			beq .nonewnote
			sta sound{1}+1
			tax
			lda #$00
			sta soundeffect{1}+1
			
;------------------------------------------------------------------------------

			lda samplestarthi,x
			sta samplefetch{1}a+2
			lda samplestartlo,x
			sta samplefetch{1}a+1
			
			lda loopposhi,x
			beq .noloop2

			lda #$ff
			sta voice{1}active
			jmp .preppart2

.noloop2		lda #$01
			sta voice{1}active
			jmp .preppart2
			
.nonewnote		ldx voice{1}active
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
			stx voice{1}active
			jmp .nextvoice
		
.preppart1
sound{1}		ldy #$00
			

			lda samplefetch{1}d+1
			clc
			adc #periodsteplength
			sta samplefetch{1}a+1
			lda samplefetch{1}d+2
			adc #$00
			sta samplefetch{1}a+2
			
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

			lda samplefetch{1}a+1		;always playing period 453
			adc #periodsteplength
			sta samplefetch{1}b+1
			lda samplefetch{1}a+2
			adc #$00
			sta samplefetch{1}b+2
			
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
.preppart3		lda samplefetch{1}b+1
			adc #periodsteplength
			sta samplefetch{1}c+1
			lda samplefetch{1}b+2
			adc #$00
			sta samplefetch{1}c+2
			
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
.preppart4		lda samplefetch{1}c+1
			adc #periodsteplength
			sta samplefetch{1}d+1
			lda samplefetch{1}c+2
			adc #$00
			sta samplefetch{1}d+2
			
			lda samplefetch{1}d+1
			cmp sampleendlo,y
			lda samplefetch{1}d+2
			sbc sampleendhi,y
			bcc .nextvoice
			
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

.nextvoice
			endm
;------------------------------------------------------------------------------
mixer			subroutine
;------------------------------------------------------------------------------
;{1}=voice number
;{2]=0 - volume off 1=volume on
;{3}=0 - period always 453 1 - periods on
;{4}=0 - sampleoffset off  1 - sampleoffset on
			lda #>mixingbuffer2
			ldy bufferpointer+1	;set mixing buffer
			bne .buf1
			lda #>mixingbuffer1
		
.buf1			sta mixswitch1+2
			sta mixswitch2+2
			sta mixswitch3+2
			sta mixswitch4+2

mixrestart		mixvoice 1,thc_chn1vol,thc_chn1per,thc_chn1off
	
			ldx #periodsteplength-1
			clc
			jmp samplefetch1a
			
;------------------------------------------------------------------------------
;modfile - protracker module
;------------------------------------------------------------------------------
			align 256,0
			echo "Sampleheaderstart: ",*
			include "thc_sampleheader.asm"

			echo "Samplestart: ",*
			include "thc_samples.asm"
