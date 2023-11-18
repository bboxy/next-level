!cpu 6510
bitmap			= $2000
screen			= $4000
colram			= $4400
main			= $f800

dst			= $02
xh			= $05
y			= $06
xs			= $08
xe			= $09
ys			= $0a
ye			= $0b

dstl			= $10
dstr			= $12
xl			= $14
lines			= $16

dstl_			= $18
dstl__			= $1a
dstr_			= $1c
dstr__			= $1e
coll			= $20
colr			= $22

FILL_COL		= $04
!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}
			* = main
!ifndef release {
			ldx #$00
-
			lda screen + $000,x
			sta $0400,x
			lda screen + $100,x
			sta $0500,x
			lda screen + $200,x
			sta $0600,x
			lda screen + $300,x
			sta $0700,x
			lda colram + $000,x
			sta $d800,x
			lda colram + $100,x
			sta $d900,x
			lda colram + $200,x
			sta $da00,x
			lda colram + $300,x
			sta $db00,x
			dex
			bne -

			jsr vsync
			ldx #$00
-
			lda #$00
			sta $0400,x
			sta $0500,x
			sta $0580,x
			lda #$02
			sta $d800,x
			sta $d900,x
			sta $d980,x
			dex
			bne -
}
			jsr vsync
			sei
!ifdef release {
			ldx #07
			lda #$00
			sta $d015
-
			sta bitmap + $0000,x
			dex
			bne -
}
!ifndef release {
			lda #$35
			sta $01
			lda #$03
			sta $dd00
			lda #$18
			sta $d016
			lda #$7f
			sta $dc0d
			lda $dc0d
			lda #$01
			sta $d019
			sta $d01a
}
			lda #$31
			sta $d012
			lda #<irq1
			sta $fffe
			lda #>irq1
			sta $ffff
			cli
!ifdef release {
			lda #$0c
-
			cmp .state
			bne -
			jsr link_load_next_comp
}
			jmp *

raster
			ldy #$00
			lax curve,y
			cmp #$80
			beq .end
			clc
			adc .ras1 + 1
			bpl +
			lda #$00
+
			sta .ras1 + 1

			txa
			clc
			adc .ras2 + 1
			cmp #$c0
			bcs .disable1
			cmp #$02
			bcs +
.disable1
			lda #<irq2
			sta .irq1 + 1
			lda #>irq2
			sta .irq1_ + 1
			jmp ++
+
			sta .ras2 + 1
++
			txa
			clc
			adc .ras3 + 1
			cmp #$fd
			bcs .disable2
			cmp #$02
			bcs +
.disable2
			lda #<irq3
			sta .irq1 + 1
			sta $fffe
			lda #>irq3
			sta .irq1_ + 1
			sta $ffff
			jmp ++
+
			sta .ras3 + 1
++
			inc raster + 1
			rts
.end
			sei
			ldx #$ff
			txs

			inx
-
			ldy colred + $28,x
			jsr vsync
			sty $d020
			ldy colred + $20,x
			lda #$48
			jsr waitras
			ldy colred + $18,x
			lda #$80
			jsr waitras
			ldy colred + $10,x
			lda #$b8
			jsr waitras
			ldy colred + $08,x
			lda #$f0
			jsr waitras
			ldy colred + $00,x
			lda #$28
			jsr waitras
			inx
			tya
			bpl -

!ifdef release {
			+switch_to_irq
			cli
			jmp link_exit
} else {
			jmp *
}

waitras
			cmp $d012
			bne *-3
			jsr .rts
			jsr .rts
			jsr .rts
			jsr .rts
			nop
			nop
			nop
			nop
			sty $d020
.rts
			rts
colred
	                !byte $09,$09,$09,$09,$09,$09,$09,$09
	                !byte $09,$09,$09,$09,$09,$09,$09,$09
	                !byte $09,$09,$09,$09,$09,$09,$09,$09
	                !byte $09,$09,$09,$09,$09,$09,$09,$09
	                !byte $09,$09,$09,$09,$09,$09,$09,$09
	                !byte $09,$09,$09,$09,$09,$09,$09,$09
	                !byte $09,$08,$0a,$0f,$0a,$04,$02,$f0
	                !byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	                !byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	                !byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	                !byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	                !byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	                !byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0

!macro inc_line .ptr {
			lda .ptr + 0
			adc #$40
			sta .ptr + 0
			lda .ptr + 1
			adc #1
			sta .ptr + 1
}

!macro do_line {
			ldx xl
			cpx #$50
			bcs +
			lda maskl,x
			sta (dstl__),y
			lda maskr,x
			sta (dstr__),y
+
			cpx #8
			bcc +
			cpx #$58
			bcs +

			lda maskl,x
			and (dstl),y
			sta (dstl),y
			lda maskr,x
			and (dstr),y
			sta (dstr),y
+
			cpx #4
			bcc +
			cpx #$54
			bcs +

			lda maskl,x
			eor #$ff
			sta (dstl_),y
			lda maskr,x
			eor #$ff
			sta (dstr_),y

			lda #FILL_COL
			ldx #0
			sta (coll,x)
			sta (colr,x)
+
			iny
			cpy #$08
			bne .noinc
			ldy #$00
			clc
			+inc_line dstl
			+inc_line dstl_
			+inc_line dstl__
			+inc_line dstr
			+inc_line dstr_
			+inc_line dstr__
			lda colr + 0
			adc #$28
			sta colr + 0
			bcc +
			inc colr + 1
			clc
+
			lda coll + 0
			adc #$28
			sta coll + 0
			bcc +
			inc coll + 1
+
.noinc
}

fade
.xls			lda #$58 + 24
			bpl +
			lda #$0b
			sta .d011_1 + 1
			sta .d011_2 + 1
			lda #$0c
			sta .state
			lda #$20
			sta .state + 3
			rts
+
			sta xl

			lax xl
			anc #$80
			rol
			sta .xlh + 1
			txa
			and #$7c
			asl
			adc #<(bitmap + 16 * $140 - 16)
			sta dstl + 0
			lda #>(bitmap + 16 * $140 - 16)
.xlh			adc #0
			sta dstl + 1

			lda dstl + 0
			clc
			adc #8
			sta dstl_ + 0
			lda dstl + 1
			adc #0
			sta dstl_ + 1

			lda dstl_ + 0
			clc
			adc #8
			sta dstl__ + 0
			lda dstl_ + 1
			adc #0
			sta dstl__ + 1

			lda dstl_
			sta coll
			lda dstl_ + 1
			lsr
			ror coll
			lsr
			ror coll
			lsr
			ror coll
			and #$03
			ora #$d8
			sta coll+1

			lda xl
			eor #$ff
			sec
			sbc #$50
			tax
			anc #$80
			rol
			sta .xrh + 1
			txa
			and #$7c
			asl
			adc #<(bitmap + 16 * $140 - 16)
			sta dstr + 0
			lda #>(bitmap + 16 * $140 - 16)
.xrh			adc #0
			sta dstr + 1
			lda dstr + 0
			sec
			sbc #8
			sta dstr_ + 0
			lda dstr + 1
			sbc #0
			sta dstr_ + 1

			lda dstr_ + 0
			sec
			sbc #8
			sta dstr__ + 0
			lda dstr_ + 1
			sbc #0
			sta dstr__ + 1

			lda dstr_
			sta colr
			lda dstr_ + 1
			lsr
			ror colr
			lsr
			ror colr
			lsr
			ror colr
			and #$03
			ora #$d8
			sta colr+1

			lda #24
			sta lines

			ldy #$00
.next_triple
			+do_line
			+do_line
			+do_line
.skip_line
			lda xl
			and #$03
			bne .no_update
			lda coll
			bne *+4
			dec coll + 1
			dec coll

			lda dstl_ + 1
			sta dstl__ + 1
			lda dstl_ + 0
			sta dstl__ + 0

			lda dstl + 1
			sta dstl_ + 1
			lax dstl + 0
			sta dstl_ + 0

			sbx #8
			stx dstl + 0
			bcs +
			dec dstl + 1
+
			inc colr
			bne *+4
			inc colr + 1

			lda dstr_ + 1
			sta dstr__ + 1
			lda dstr_ + 0
			sta dstr__ + 0

			lda dstr + 1
			sta dstr_ + 1
			lax dstr + 0
			sta dstr_ + 0

			sbx #-8
			stx dstr + 0
			bcc +
			inc dstr + 1
+
.no_update
			dec xl
			dec lines
			beq +
			jmp .next_triple
+
.endloop
			;inc $d020
			dec .xls + 1
			rts

vsync
			bit $d011
			bpl *-3
			bit $d011
			bmi *-3
.wait12
			rts

irq1
			pha
.ras2			lda #$b0
			sta $d012
			lda #<irq2
			sta $fffe
			lda #>irq2
			sta $ffff
			lda #$18
			sta $d018
.d011_2			lda #$1b
			sta $d011
			jsr .wait12
			nop
			lda #$01
			sta $d020
			jsr .wait12
			jsr .wait12
			jsr .wait12
			jsr .wait12
			jsr .wait12
			lda #$02
			sta $d020
			sta $d021
			dec $d019
			pla
			rti
irq2
			pha
.ras3			lda #$fc
			sta $d012
			lda #<irq3
			sta $fffe
			lda #>irq3
			sta $ffff
			jsr .wait12
			jsr .wait12
			nop
			lda #$01
			sta $d020
			sta $d021
			lda #$18
			lda $d018
.d011_1			lda #$3b
			sta $d011
			jsr .wait12
			jsr .wait12
			jsr .wait12
			jsr .wait12
			lda #$0a
			sta $d020
			sta $d021
			dec $d019
			pla
			rti
irq3
			pha
.ras1			lda #$31
			sta $d012
.irq1			lda #<irq1
			sta $fffe
.irq1_			lda #>irq1
			sta $ffff
			jsr .wait12
			jsr .wait12
			nop
			lda #$01
			sta $d020
			jsr .wait12
			jsr .wait12
			jsr .wait12
			jsr .wait12
			jsr .wait12
			lda #$09
			sta $d020
			lda #$02
			sta $d021
			dec $d019
			txa
			pha
			tya
			pha
			cli
.state			jsr fade
			top raster
			pla
			tay
			pla
			tax
			pla
			rti


maskl
!for .x,0,24 {
			!byte %00000000
			!byte %11000000
			!byte %11110000
			!byte %11111100
}
maskr
!for .x,0,24 {
			!byte %00000000
			!byte %00000011
			!byte %00001111
			!byte %00111111
}

curve
			!byte $00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$00,$FF,$00,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00
			!byte $FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FE,$FF,$FE,$FE,$FF,$FE,$FF,$FE,$FE,$FE,$FF,$FE
			!byte $FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FD,$FE,$FE,$FE,$FD,$FE,$FE,$FE,$FD,$FE,$FE,$FD,$FE
			!byte $FD,$FE,$FE,$FD,$FE,$FD,$FE,$FD,$FE,$FD,$FE,$FD,$FD,$FE,$FD,$FE,$FD,$FD,$FE,$FD,$FD,$FD,$FE,$FD,$FD,$FD,$FE,$FD,$FD,$FD,$FD,$FD
			!byte $FD,$FD,$FD,$FC,$FD,$FC,$FD,$FC,$FD,$FD,$FD,$FD,$FD,$FE,$FE,$FE,$80

!ifndef release {
		* = bitmap
!fill 16 * $140,0
!bin "clean1.kla",9*$140, 2
		* = screen
!fill 16 * $28,0
!bin "clean1.kla",9*$28,$1f42
		* = colram
!fill 16 * $28,0
!bin "clean1.kla",9*$28,$1f42 + $3e8
}
