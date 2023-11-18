.pc = * "code includes"

.macro StableRasterTimer() {
				lda #8
				sec
				sbc $dc04
				sta _StableBranch+1
_StableBranch:	bcs _StableBranch2
_StableBranch2: .fill 7,$a2
				bit $ea
}

.function CalcFontScreen(Font, Screen) {
	.return ((Screen & $3c00)/64) + ((Font & $3800)/1024)
}

.function CalcBank(Adr) {
	.return $3c+(Adr/$4000)
}

.macro SetXXAA(val) {
	lda #<val
	ldx #>val
}

.macro SetupFontScreen(Font, Screen) {		// Sets both VIC_ScreenMemory and BankSelect
	lda #CalcFontScreen(Font, Screen)
	sta $d018

	lda #CalcBank(Screen)
	sta $dd00
}

//.macro CopyBlocks(from, to, len) {
//	lda #>from
//	ldx #>to
//	ldy #>len
//	jsr DEMOSYS_CopyBlocks
//}

.macro BeginIRQ() {
  pha
  txa
  pha
  tya
  pha
  lda $01
  pha
  lda #$35
  sta $01
  lda #1
  sta $d019
}

.macro NextIRQ(IRQ, YPos) {
	lda #<IRQ
	ldx #>IRQ
	ldy #YPos
	jmp IRQSetAXYRTI
}

.macro StoreWord(ad, word) {
	lda #<word
	sta ad
	lda #>word
	sta ad+1
}

.macro WordAdd(ad, b) {
	lda ad
	clc
	adc #<b
	sta ad
	lda ad+1
	adc #>b
	sta ad+1
}

.macro WordSub(ad, b) {
	lda ad
	sec
	sbc #<b
	sta ad
	lda ad+1
	sbc #>b
	sta ad+1
}

IRQSetAXYRTI:
					sta $fffe
					stx $ffff
					sty $d012
StackRTI:
					pla
					sta $01
					pla
					tay
					pla
					tax
					pla
					rti

WaitForRetrace:
!:					bit $d011
					bpl !-						// Branch when raster is $00xx

!:					bit $d011
					bmi !-						// Branch when raster is $01xx

					rts							// We are now on the very first raster line :)

/**********************************************************************
							Copy blocks
**********************************************************************&

/*
		Copies block (a number of $100 bytes blocks starting in $xx00)
		from source A to destination X for a total of Y blocks

		E.g.

			lda #$90		// Copy from $9000
			ldx #$10		// Copy to $1000
			ldy #$12		// Copy 18 blocks ($1200 bytes)

*/
//DEMOSYS_CopyBlocks:	sta internal_CopyFrom+2
//					stx internal_CopyTo+2
//					ldx #0
//internal_CopyFrom:	lda $9000,x
//internal_CopyTo:	sta $1000,x
//					inx
//					bne internal_CopyFrom
//					inc internal_CopyFrom+2
//					inc internal_CopyTo+2
//					dey
//					bne internal_CopyFrom
//					rts

