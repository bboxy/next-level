
#if release
#else
	.var music = LoadSid("music.sid")
	.var music_init = music.init
	.var music_play = music.play
	.var framecount = $02
	*=music.location "Music"
    .fill music.size, music.getData(i)
#endif



.macro testMode(mainStart){
	
#if !release
	.pc = $0801 "Basic Upstart"
	:BasicUpstart($0900)
	.pc = $0900 "dummyIRQ"
	:dummyIRQ(mainStart)
	playmusic:
	jsr $0a03
	rts
#endif
}



.macro dummyIRQ (startAddress) {
			
setdummyirq:

		sei
		lda #$35
		sta $01
#if !release
		lda #0
		tax
		tay
		ldx #0
		jsr music_init
#endif
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
#if !release
		jsr music_play
#endif
		//dec $d020
		inc framecount		
#if !release
		bit $dc0d
#endif
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
