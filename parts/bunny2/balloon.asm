!cpu 6510
		* = $0800

BG_COL		= $0f
sprites01	= $0400
sprites02	= $0040
sprites03	= $0100

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}

		jsr vsync
		sei
		lda #$35
		sta $01


!ifndef release {
		lda #BG_COL
-
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		dex
		bne -
}
-
		lda sprites + $000,x
		sta $0400,x
		lda sprites + $100,x
		sta $0500,x
		lda sprites + $200,x
		sta $0600,x
		lda sprites + $280,x
		sta $0680,x
		dex
		bne -

		ldx #<(($0040 / $40))
		stx $07fa
		inx
		stx $07fb
		ldx #<(($0100 / $40))
		stx $07fc
		inx
		stx $07fd


		ldx #$7f
-
		lda sprites_zp,x
		sta sprites02,x
		lda sprites_stack,x
		sta sprites03,x
		dex
		bpl -
!ifndef release {
		ldx #$27
-
		lda #$64
		sta $0400 + 23 * 40,x
		lda #$00
		sta $d800 + 23 * 40,x
		dex
		bpl -
}

		jsr vsync
		ldx #$2f
-
		lda vicconf,x
		sta $d000,x
		dex
		bpl -

!ifndef release {
		lda #$7f
		sta $dc0d
		lda $dc0d
		lda #$03
		sta $dd00
}
		lda #<.irq
		sta $fffe
		lda #>.irq
		sta $ffff
		cli
!ifdef release {
		dec $01
		jsr link_decomp
		inc $01
		jsr link_load_next_comp
		jsr link_load_next_comp
		lda #$64
-
		cmp .pos + 1
		bne -
		jsr vsync
		sei
		lda #$00
		sta $d011
		jmp link_exit
}
		jmp *
vicconf
		!byte $90,$cd,$90,$e2,$50,$c0,$50,$c0
		!byte $50,$c0,$50,$c0,$00,$00,$00,$00
		!byte $3f,$12,$00,$00,$00,$3f,$00,$00
		!byte $15,$01,$01,$00,$03,$00,$00,$00
		!byte BG_COL, BG_COL,$00,$00,$00,$00,$06,$04
		!byte $04,$06,$0f,$02,$01,$00,$00,$00

.irq
		pha
		txa
		pha
		tya
		pha
		lda $01
		pha
		lda #$35
		sta $01
.pos		ldy #$00
		jsr .move
		sty .pos + 1
		dec $d019
		pla
		sta $01
		pla
		tay
		pla
		tax
		pla
		rti

.move
		cpy #$64
		bne +
		rts
+
		lda $d004
		sec
		sbc #$02
		bcs +
		lax $d010
		and #$3c
		beq ++
		txa
		and #$03
		sta $d010
+
		lda $d004
		sec
		sbc #$02
		sta $d004
		sta $d006
		sta $d008
		sta $d00a
		and #$07
		bne ++
		dec $d005
		dec $d007
		dec $d009
		dec $d00b
++
		lda $d016
		eor #$4
		and #$07
		sta $d016
		beq +
		cpy #$3c
		bcc +
.posb
		ldx #$27
		lda #BG_COL
		sta $d800 + 23 * 40,x
		dec .posb + 1
		bpl +
		inc .posb + 1
+
.ctr		lda #$00
		clc
.speed		adc #2
		and #$03
		sta .ctr + 1
		bne .end
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
		sec
		sbc #$04
		sta $d000
		sta $d002
		bcs +
		lda $d010
		and #$fc
		sta $d010
+
		iny
.end
		rts

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
!bin "balloon.spr",$40, 3 * $40
!bin "balloon.spr",$40, 2 * $40
sprites_stack
!bin "balloon.spr",$40, 1 * $40
!bin "balloon.spr",$40, 0 * $40
