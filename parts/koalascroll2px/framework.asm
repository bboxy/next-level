
#if LINK
.import source "../../config.asm"
#else
	.var music = LoadSid("JammicroV1_HardRestartSID.sid")
	.var music_init = music.init
	.var music_play = music.play
	.var framecount = $02
	//*=music.location "Music"
    //.fill music.size, music.getData(i)
#endif



.macro testMode(mainStart){
	
	.pc = $0801 "Basic Upstart"
	:BasicUpstart($0810)
	.pc = $0810 "dummyIRQ"
	:dummyIRQ(mainStart)
	playmusic:
	jsr $0a03
	rts
}



.macro dummyIRQ (startAddress) {
			
setdummyirq:

		sei
		lda #$35
		sta $01
		lda #0
		tax
		tay
		//jsr music_init
		ldx #<irq_black
		ldy #>irq_black
		stx $fffe
		sty $ffff
		lda #$f9
		sta $d012
		lda #$0b
		sta $d011
#if !release
		lda #<dummynmi
		sta $fffa
		lda #>dummynmi
		sta $fffb
#endif
		lda #$01
		sta $d01a
		lda #$7f
		sta $dc0d
		bit $dc0d
#if !release
		sta $dd0d
		bit $dd0d
#endif
		dec $d019
		 lda #$18
     	sta $d016
		cli
		jmp bgthread

irq_black:
		pha
		txa
		pha
		tya
		pha
		lda $01
		pha
		lda #$35
		sta $01
		inc $d019
		//inc $d020
		//jsr music_play
		//dec $d020
		inc framecount		
		bit $dc0d
		pla
		sta $01
		pla
		tay
		pla
		tax
		pla

dummynmi:	rti
	
bgthread:
!:	
		
		jsr startAddress
		inc $d020
		jmp *-3	
		
}
