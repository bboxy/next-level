		* = $2000

sprites01	= $0400
sprites02	= $0040
sprites03	= $0100
target		= $f800

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}

		jsr vsync
		lda #$00
		sta $d011
		sta $d016
		lda #$0f
		sta $d020
		sta $d021
		ldx #$00
-
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		dex
		bne -
-
		lda sprites + $000,x
		sta $0400,x
		lda sprites + $100,x
		sta $0500,x
		lda sprites + $200,x
		sta $0600,x
		lda sprites + $300,x
		sta $0700,x
		lda .tgt + $000,x
		sta target + $000,x
		dex
		bne -

		ldx #$7f
-
		lda sprites_zp,x
		sta $0040,x
		lda sprites_stack,x
		sta $0100,x
		dex
		bpl -

		ldx #$27
		lda #$64
-
		sta $0400 + 23 * 40,x
		dex
		bpl -
		;lda #$00
		;jsr i.color
		lda #$03
		sta $dd00
		lda #$15
		sta $d018
		lda #$00
		sta $d016
		lda #$03
		sta $d015
		sta $d01c
		lda #$00
		sta $d017
		sta $d019
		sta $d01b
		sta $d01d

		lda #$00
		sta $d000
		sta $d002
		sta $d010
		lda #$cd
		sta $d001
		clc
		adc #21
		sta $d003

		lda #$04
		sta $d027
		sta $d028
		lda #$00
		sta $d025
		lda #$06
		sta $d026

		jsr vsync
		sei
		lda #$1a
		sta $d011
		lda #$00
		sta $d012
		lda #$35
		sta $01
		lda #$01
		sta $d019
		sta $d01a
		lda #$7f
		sta $dc0d
		lda $dc0d
		lda #<.irq
		sta $fffe
		lda #>.irq
		sta $ffff
		cli
		jmp target
.tgt
!pseudopc target {
!ifdef release {
		jsr link_load_next_comp
		lda #$70
-
		cmp .pos + 1
		bne -
		jmp link_exit

}
		jmp *

.color
		ldx #$27
-
		sta $d800 + 23 * 40,x
		dex
		bpl -
		rts


.irq
		pha
		txa
		pha
		tya
		pha
.pos		ldy #$00
		jsr .move
		sty .pos + 1
		dec $d019
		pla
		tay
		pla
		tax
		pla
		rti



.move
		cpy #$70
		bne +
		rts
+
.ctr		lda #$00
		clc
.speed		adc #1
		and #$03
		sta .ctr + 1
		bne .end
		cpy #$40
		bcc .walk
		cpy #$58
		bne +
		inc .speed + 1
+
		bcs .walk
.look
		ldx #<((sprites02 / $40))
		cpy #$48
		bcc +
		ldx #<((sprites03 / $40))
		cpy #$54
		bcc +
		ldx #<((sprites02 / $40))
+
		stx $07f8
		inx
		stx $07f9
		iny
		rts

.walk
.ptr
		ldx #<((sprites01 / $40))
		stx $07f8
		inx
		stx $07f9
		inx
		cpx #<((sprites01 / $40)) + 14
		bne +
		ldx #<((sprites01 / $40))
+
		stx .ptr + 1
		lda $d000
		clc
		adc #$04
		sta $d000
		sta $d002
		bcc +
		lda #$03
		sta $d010
+
		iny
		cpy #$38
		bcc +
		cpy #$40
		bcs +
		lda colortab - $38,y
		jsr .color
+
.end
		rts
colortab
		!byte $0f,$0f,$0e,$04,$06,$00,$00,$00
}
!warn "target size: ", * - .tgt

vsync
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		rts

sprites
!bin "bunny.spr",$40, 00 * $40
!bin "bunny.spr",$40, 10 * $40
!bin "bunny.spr",$40, 01 * $40
!bin "bunny.spr",$40, 11 * $40
!bin "bunny.spr",$40, 02 * $40
!bin "bunny.spr",$40, 12 * $40
!bin "bunny.spr",$40, 03 * $40
!bin "bunny.spr",$40, 13 * $40
!bin "bunny.spr",$40, 04 * $40
!bin "bunny.spr",$40, 14 * $40
!bin "bunny.spr",$40, 05 * $40
!bin "bunny.spr",$40, 15 * $40
!bin "bunny.spr",$40, 06 * $40
!bin "bunny.spr",$40, 16 * $40
;!bin "bunny.spr",$40, 07 * $40
;!bin "bunny.spr",$40, 17 * $40
sprites_zp
!bin "bunny.spr",$40, 08 * $40
!bin "bunny.spr",$40, 18 * $40
sprites_stack
!bin "bunny.spr",$40, 09 * $40
!bin "bunny.spr",$40, 19 * $40
