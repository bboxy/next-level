!cpu 6510
bitmap			= $2000
screen 			= $0400
main			= $3f40


!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}
			* = main
			sei
			jsr vsync
			lda #$00
			sta $d011
			ldx #$00
-
			lda screen_ + $000,x
			sta screen  + $000,x
			lda screen_ + $100,x
			sta screen  + $100,x
			lda screen_ + $200,x
			sta screen  + $200,x
			lda screen_ + $300,x
			sta screen  + $300,x
			dex
			bne -
			ldy #$03
-
			lda #$06
			sta $d020
			ldx #$20
			jsr wait
			lda #$02
			sta $d020
			ldx #$20
			jsr wait
			dey
			bpl -

			lda #$3b
			sta $d011
			lda #$03
			sta $dd00
			lda #$00
			sta $d020
			lda #$18
			sta $d018
			lda #$08
			sta $d016

			jmp *

vsync
			ldx #$00
wait
-
			bit $d011
			bpl *-3
			bit $d011
			bmi *-3
			dex
			bpl -
			rts

screen_
			!bin "bitmap.prg",$3e8,$1f42

			* = bitmap
			!bin "bitmap.prg",$1f40,2
