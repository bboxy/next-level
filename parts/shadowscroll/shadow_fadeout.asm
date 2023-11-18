!cpu 6510
irq_code	= $10

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}

zpcode		= $02
screen          = $f400

!src "coltab_defs.asm"

		* = $8000


		ldx #irq_jmps_ - irq_jmps
-
		lda irq_jmps,x
		sta zpcode,x
		dex
		bpl -

                inx
!ifdef release {
		+sync
}
		jsr wait

		sei
!ifndef release {
		lda #$35
		sta $01
}
		lda #$03
		sta $d021
		lda #$02
		sta $d016
		stx $dd00
		stx $d023
		stx $d022
		stx $d015
!ifndef release {
		lda #$7f
		sta $dc0d
		lda $dc0d
		lda #$01
		sta $d019
		sta $d01a
}
		lda #<irq1
		sta $fffe
		stx $ffff
		lda #$32
		sta $d012
		lda #$1b
		sta $d011
		cli
		lda #$0e
		jsr col_lower

		jsr link_load_next_comp
		jsr link_load_next_comp

.trig		lda #$00
		beq .trig
		jsr wait
		sei
		lda #$0b
		sta $d011

!ifdef release {
		jmp link_exit
} else {
		jmp *
}

effect

.cnt		lda #$03
		dec .cnt + 1
		beq +
		rts
+
		lda #$03
		sta .cnt + 1
.start          ldx #$05
		cpx #$0a
		bcs +
                ldy curve,x
                lda coltab_lo_3,y
                sta .col07 + 1
                lda coltab_lo_5,y
                sta .col0a + 1
                jsr $4801
		ldx .start + 1
		jmp .lower
+
		lda #$f2
                sta coltab_lo_e + 0
                sta coltab_lo_e + 1
                sta coltab_lo_e + 2
                sta coltab_lo_7 + 0
		lda #$2f
                sta coltab_hi_e + 0
                sta coltab_hi_e + 1
                sta coltab_hi_e + 2
		lda #$1b
		sta .gfx1 + 1

		cpx #$14
		beq .start4
                ldy curve,x
		lda coltab_lo_e,y
		and coltab_hi_e,y
                sta .col07 + 1
		sta .col0a + 1
		ldy #$00
-
		sta $d800,y
		sta $d900,y
		dey
		bne -
.lower
                ldy curve,x
                lda coltab_lo_e,y
                sta .col0b + 1
                inc .start + 1
col_lower
                ldx #$27
-
                sta $d800 + 16 * 40,x
                sta $d800 + 17 * 40,x
                sta $d800 + 18 * 40,x
                sta $d800 + 19 * 40,x
                sta $d800 + 20 * 40,x
                sta $d800 + 21 * 40,x
                sta $d800 + 22 * 40,x
                sta $d800 + 23 * 40,x
                sta $d800 + 24 * 40,x
		dex
		bpl -
		rts


.start4		ldx #$00
		cpx #$17
		beq +
                inc .start4 + 1
                ldy curve,x
                lda coltab_lo_7,y
                sta .colframe + 1
		rts
+
		inc .trig + 1
		rts

curve
		!byte $01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00,$00,$00,$00

wait
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
.rts
		rts

irq_jmps
!pseudopc zpcode {
irq0		jmp irq0_
irq1		jmp irq1_
irq2		jmp irq2_
irq3		jmp irq3_
irq4		jmp irq4_
}
irq_jmps_

irq0_
		pha
		lda #$32
		sta $d012
		lda #<irq1
		sta $fffe
.colframe	lda #$00
		sta $d020
.col07		lda #$03
		jmp .common1
irq1_
		pha
		lda #$82
		sta $d012
		lda #<irq2
		sta $fffe
		jsr .rts
		jsr .rts
.gfx1		lda #$3b
		jmp .common2
irq2_
		pha
		lda #<irq3
		sta $fffe
		lda #$b1
		sta $d012
		jsr .rts
		jsr .rts
.col0a		lda #$05
.common1
		sta $d021
		lda #$1b
.common2
		sta $d011
.common3
		dec $d019
		pla
		rti
irq3_
		pha
		lda #$fa
		sta $d012
		lda #<irq4
		sta $fffe
		jsr .rts
		jsr .rts
.col0b		lda #$0e
		sta $d021
		jmp .common3
irq4_
		pha
		txa
		pha
		tya
		pha
		lda #$00
		sta $d012
		lda #$13
		sta $d011
		lda #<irq0
		sta $fffe
		dec $d019
		cli
		jsr effect
		pla
		tay
		pla
		tax
		pla
		rti
fade
