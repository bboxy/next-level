!cpu 6510
bitmap			= $4000
screen 			= $6000
main			= $0400

dsts			= $10
dstc			= $12
srcs			= $14
srcc			= $16
ypos			= $18
xpos			= $19

stripe_size		= 4

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}
			* = main
			sei
			lda #$35
			sta $01
			jsr vsync
			lda #$00
			sta $d011
			lda #$02
			sta $dd00
			lda #$00
			sta $d021
			sta $d020
			lda #$80
			sta $d018
			lda #$18
			sta $d016

			lxa #0
-
			sta screen + $000,x
			sta screen + $100,x
			sta screen + $200,x
			sta screen + $300,x
			sta $d800,x
			sta $d900,x
			sta $da00,x
			sta $db00,x
			dex
			bne -

			jsr vsync
			lda #$37
			sta $d011
			lda #$fa
			sta $d012
			lda #$7f
			sta $dc0d
			lda $dc0d
			lda #$01
			sta $d01a
			sta $d019
			lda #<irq
			sta $fffe
			lda #>irq
			sta $ffff
			ldy #$00
			sty ypos
			sty xpos
			cli
!ifdef release {
			jsr link_load_next_comp
			jsr link_load_next_comp
			jsr link_load_next_comp
}
-
trig = * + 1
			lda #$00
			beq -
!ifdef release {
			jmp link_exit
} else {
			jmp *
}

irq
			pha
			txa
			pha
			tya
			pha
			lda $01
			pha
			lda #$35
			sta $01
			dec $d019
			jsr do_line
			pla
			sta $01
			pla
			tay
			pla
			tax
			pla
			rti
do_line
			lda xpos
			cmp #$28
			bne +
			lda #$01
			sta trig
			rts
+
			jsr copy_line
			lda xpos
			and #stripe_size
			beq +
			dec ypos
			top
+
			inc ypos
			lda ypos
			bpl +
			inc ypos
			jmp add
+
			cmp #25
			bne +
			dec ypos
add
			lda xpos
			clc
			adc #stripe_size
			sta xpos
+
			rts
vsync
			bit $d011
			bpl *-3
			bit $d011
			bmi *-3
			rts


copy_line
			ldy ypos
			lda tabscrl,y
			sta srcs
			sta srcc
			sta dsts
			sta dstc

			lax tabscrh,y
			clc
			adc #>screen_
			sta srcs + 1

			txa
			adc #>colram_
			sta srcc + 1

			txa
			adc #>screen
			sta dsts + 1

			txa
			adc #$d8
			sta dstc + 1

			ldy xpos
			ldx #stripe_size - 1
-
			lda (srcs),y
			sta (dsts),y
			lda (srcc),y
			sta (dstc),y
			iny
			dex
			bpl -
			rts

tabscrl
!for .x,0,24 {
			!byte <(.x * 40)
}
tabscrh
!for .x,0,24 {
			!byte >(.x * 40)
}

!align 255,0
screen_
!for .x,0,24 {
			!bin "../paralaxkoala/tools/stam.kla",32,$1f42 + .x * 40
			!fill 8,$b0
}
!align 255,0
colram_
!for .x,0,24 {
			!bin "../paralaxkoala/tools/stam.kla",32,$1f42+$3e8 + .x * 40
			!fill 8,0
}
			* = bitmap
!for .x,0,24 {
			!bin "../paralaxkoala/tools/stam.kla",32*8,2 + .x * 320
			;!bin "../paralaxkoala/tools/logo.kla",8*8,2 + .x * 320 + 32 * 8
			!fill 8*8,$00
}
