!cpu 6510

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}

screen		= $fc00
charset		= $f800


sin		= $20
trig		= $22

.val		= $00

		* = $f000

		sei
		lda #$35
		sta $01
		ldx #$00
		stx trig
		lda #$0f
-
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		dex
		bne -

		ldy #$00
		anc #0
-
		sta screen + 05 * 40,y
		sta screen + 13 * 40,y
		sta screen + 21 * 40,y
		adc #1
		sta screen + 06 * 40,y
		sta screen + 14 * 40,y
		sta screen + 22 * 40,y
		adc #1
		sta screen + 07 * 40,y
		sta screen + 15 * 40,y
		sta screen + 23 * 40,y
		adc #1
		sta screen + 00 * 40,y
		sta screen + 08 * 40,y
		sta screen + 16 * 40,y
		sta screen + 24 * 40,y
		adc #1
		sta screen + 01 * 40,y
		sta screen + 09 * 40,y
		sta screen + 17 * 40,y
		adc #1
		sta screen + 02 * 40,y
		sta screen + 10 * 40,y
		sta screen + 18 * 40,y
		adc #1
		sta screen + 03 * 40,y
		sta screen + 11 * 40,y
		sta screen + 19 * 40,y
		adc #1
		sta screen + 04 * 40,y
		sta screen + 12 * 40,y
		sta screen + 20 * 40,y
		adc #8
		anc #$38
		iny
		cpy #$28
		bne -

		lda #$00 xor .val
		ldx #$00
-
		sta charset + $000,x
		sta charset + $100,x
		sta charset + $200,x
		sta charset + $300,x
		dex
		bne -

		bit $d011
		bpl *-3
		bit $d011
		bmi *-3

		lda #$fe
		sta $d018
		lda #$00
		sta $dd00
		lda #$01
		sta $d020
		lda #$08
		sta $d021
		lda #$08
		sta $d016

		lda #$e0
		sta $d012
		lda #$1b
		sta $d011
		lda #$7f
		sta $dc0d
		lda $dc0d
		lda #$01
		sta $d019
		sta $d01a
		lda #<irq
		sta $fffe
		lda #>irq
		sta $ffff
		cli
!ifdef release {
		jsr link_load_next_comp
		jmp link_exit
} else {
-
		lda #$00
		beq -
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
		lda #$00
		sta sin + 1

.line		ldx #$c0
		bmi +
		cpx #$40
		beq .no_line
		ldy #$20
		txa
		eor #$3f
		and #$f8
		asl
		asl
		rol sin + 1
		asl
		rol sin + 1
		sta sin + 0
		lda sin + 1
		clc
		adc #>charset
		sta sin + 1
		lda .mirror,x
		sec
		rol
		sta (sin),y
+
		inc .line + 1
		jmp .done
.no_line
-
.num		ldx #$00
		lda .sinheight,x
		bpl +
		ldx #$00
		stx .num + 1
		beq -
+
		inc .num + 1
		asl
		asl
		asl
		asl
		rol sin + 1
		asl
		rol sin + 1
		adc #<.sinus
		sta sin + 0
		lda sin + 1
		adc #>.sinus
		sta sin + 1

		ldy #$00
-
		lax (sin),y

		lsr
		asr #$0c
		sta .jmp + 1
		lda .pixtab,x
.jmp		jmp (.target)
.back
		iny
		cpy #$20
		bne -

;		ldx .num + 1
;		cpx #$10
;		bcs +
;		lda .color,x
;		sta $d021
;+
		lda #$ff xor .val
-
		sta charset + $000,y
		sta charset + $040,y
		sta charset + $080,y
		sta charset + $0c0,y
		sta charset + $100,y
		sta charset + $140,y
		sta charset + $180,y
		sta charset + $1c0,y
		iny
		cpy #$40
		bne -

		ldy #$30
-
.num2		ldx #$00
		lda #$3e
		sec
		sbc .thickness,x
		tay
		inc .num2 + 1
		ldx #$3f
		cpy #$1f
		beq ++
-
		lda #$00 xor .val
		sta charset + $000,x
		sta charset + $040,x
		sta charset + $080,x
		sta charset + $0c0,x
		sta charset + $100,x
		sta charset + $140,x
		sta charset + $180,x
		sta charset + $1c0,x
		dex
		dey
		cpy #$1f
		bne -
++
-
		lda charset + $000,x
!if .val = $ff {
		eor #$ff
}
		eor charset + $000,y
		sta charset + $000,x
		lda charset + $040,x
!if .val = $ff {
		eor #$ff
}
		eor charset + $040,y
		sta charset + $040,x
		lda charset + $080,x
!if .val = $ff {
		eor #$ff
}
		eor charset + $080,y
		sta charset + $080,x
		lda charset + $0c0,x
!if .val = $ff {
		eor #$ff
}
		eor charset + $0c0,y
		sta charset + $0c0,x
		lda charset + $100,x
!if .val = $ff {
		eor #$ff
}
		eor charset + $100,y
		sta charset + $100,x
		lda charset + $140,x
!if .val = $ff {
		eor #$ff
}
		eor charset + $140,y
		sta charset + $140,x
		lda charset + $180,x
!if .val = $ff {
		eor #$ff
}
		eor charset + $180,y
		sta charset + $180,x
		lda charset + $1c0,x
!if .val = $ff {
		eor #$ff
}
		eor charset + $1c0,y
		sta charset + $1c0,x
		dex
		dey
		bpl -
.end
		ldx .num2 + 1
		lda .thickness,x
		bpl +
		sta trig
		lda #$00
		sta $d01a
		sta .num2 + 1
+
.done
		pla
		sta $01
		pla
		tay
		pla
		tax
		pla
		rti

!align 255,0
.target
		!word .char1
		!word .char2
		!word .char3
		!word .char4

.char1
		sta charset + $000,y
		lda .mirror,x
		sta charset + $1c0,y
		lda #$00 xor .val
		sta charset + $040,y
		sta charset + $080,y
		sta charset + $0c0,y
		sta charset + $100,y
		sta charset + $140,y
		sta charset + $180,y
		jmp .back
.char2
		sta charset + $040,y
		lda .mirror,x
		sta charset + $180,y
		lda #$ff xor .val
		sta charset + $000,y
		sta charset + $1c0,y
		lda #$00 xor .val
		sta charset + $080,y
		sta charset + $0c0,y
		sta charset + $100,y
		sta charset + $140,y
		jmp .back
.char3
		sta charset + $080,y
		lda .mirror,x
		sta charset + $140,y
		lda #$ff xor .val
		sta charset + $000,y
		sta charset + $040,y
		sta charset + $180,y
		sta charset + $1c0,y
		lda #$00 xor .val
		sta charset + $0c0,y
		sta charset + $100,y
		jmp .back
.char4
		sta charset + $0c0,y
		lda .mirror,x
		sta charset + $100,y
		lda #$ff xor .val
		sta charset + $000,y
		sta charset + $040,y
		sta charset + $080,y
		sta charset + $140,y
		sta charset + $180,y
		sta charset + $1c0,y
		jmp .back
.mirror
!for .x,0,7 {
		!byte $00 xor .val
		!byte $01 xor .val
		!byte $03 xor .val
		!byte $07 xor .val
		!byte $0f xor .val
		!byte $1f xor .val
		!byte $3f xor .val
		!byte $7f xor .val
}

.pixtab
!for .x,0,7 {
		!byte $00 xor .val
		!byte $80 xor .val
		!byte $c0 xor .val
		!byte $e0 xor .val
		!byte $f0 xor .val
		!byte $f8 xor .val
		!byte $fc xor .val
		!byte $fe xor .val
}

.sinus
		!bin "sinus.bin"

.sinheight
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e
		!byte $0f,$0e,$0f,$0e,$0d,$0e,$0f,$0e,$0d,$0c,$0d,$0e,$0f,$0e,$0d,$0c,$0b,$0c,$0d,$0e,$0f,$0e,$0d,$0c,$0b,$0a
		!byte $0b,$0c,$0d,$0e,$0f,$0e,$0d,$0c,$0b,$0a,$09,$0a,$0b,$0c,$0d,$0e,$0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$09,$0a
		!byte $0b,$0c,$0d,$0e,$0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e
		!byte $0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a
		!byte $0b,$0c,$0d,$0e,$0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00,$01,$02,$03,$04,$05,$06
		!byte $06,$07,$07,$07,$08,$08,$08,$09,$09,$09,$09,$0a,$0a,$0a,$0a,$0a,$ff

.thickness
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02
		!byte $02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$04,$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06,$06
		!byte $06,$07,$07,$07,$07,$07,$07,$08,$08,$08,$08,$09,$09,$09,$0a,$0a,$0a,$0b,$0b,$0c,$0c,$0d,$0e,$0f,$10,$11
		!byte $12,$13,$14,$15,$15,$16,$17,$18,$1a,$1b,$1c,$1d,$1e,$1f,$1f,$1f,$1f,$1e,$1d,$1c,$1b,$1a,$19,$18,$17,$16
		!byte $15,$14,$13,$12,$11,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f,$1f,$1f,$1f,$1f,$1f
		!byte $1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$ff

;.color
;		!byte $08,$08,$0a,$0a,$0f,$0f,$07,$07,$01,$01,$07,$07,$0f,$0f,$0f,$0f
;0
;1
;2
;3
;4
;5
;6
;7
;100
;101
;102
;103
;104
;105
;106
;107

