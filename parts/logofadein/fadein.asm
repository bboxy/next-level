!cpu 6510

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}


;fade out logo with triangle, first pixelwise expansion, then wen top and bottom border is reached, do it faster by not just deleting pixels, but whole chunk + 1 adjacent byte for larger steps
;;
;
;
;    xx
;    xx
;  xxxxxx
;  xxxxxx
;xxxxxxxxxx
;xxxxxxxxxx
;steps of 2, each even number, inc/dec x of slopw, unten, linie malen

START_COL	= 2

areg		= $10
xreg		= $11
yreg		= $12
.trig		= $13

csize		= 9
bitmap		= $2000
screen		= $0400
screen_		= $4000
colram		= $4400
main		= $c000


coltab1_lo_0	= coltab1_lo + $0 * csize
coltab1_lo_1	= coltab1_lo + $1 * csize
coltab1_lo_2	= coltab1_lo + $2 * csize
coltab1_lo_3	= coltab1_lo + $3 * csize
coltab1_lo_4	= coltab1_lo + $4 * csize
coltab1_lo_5	= coltab1_lo + $5 * csize
coltab1_lo_6	= coltab1_lo + $6 * csize
coltab1_lo_7	= coltab1_lo + $7 * csize
coltab1_lo_8	= coltab1_lo + $8 * csize
coltab1_lo_9	= coltab1_lo + $9 * csize
coltab1_lo_a	= coltab1_lo + $a * csize
coltab1_lo_b	= coltab1_lo + $b * csize
coltab1_lo_c	= coltab1_lo + $c * csize
coltab1_lo_d	= coltab1_lo + $d * csize
coltab1_lo_e	= coltab1_lo + $e * csize
coltab1_lo_f	= coltab1_lo + $f * csize

coltab1_hi_0	= coltab1_hi + $0 * csize
coltab1_hi_1	= coltab1_hi + $1 * csize
coltab1_hi_2	= coltab1_hi + $2 * csize
coltab1_hi_3	= coltab1_hi + $3 * csize
coltab1_hi_4	= coltab1_hi + $4 * csize
coltab1_hi_5	= coltab1_hi + $5 * csize
coltab1_hi_6	= coltab1_hi + $6 * csize
coltab1_hi_7	= coltab1_hi + $7 * csize
coltab1_hi_8	= coltab1_hi + $8 * csize
coltab1_hi_9	= coltab1_hi + $9 * csize
coltab1_hi_a	= coltab1_hi + $a * csize
coltab1_hi_b	= coltab1_hi + $b * csize
coltab1_hi_c	= coltab1_hi + $c * csize
coltab1_hi_d	= coltab1_hi + $d * csize
coltab1_hi_e	= coltab1_hi + $e * csize
coltab1_hi_f	= coltab1_hi + $f * csize


		* = bitmap
!for .y, 0, 8 {
	!for .x, 0, 39 {
        	;!if (.x = 0 or .x = 39) {
		;	!bin "clean1.kla", 8, .x * 8 + .y * $140 + 2
            	;} else {
			!bin "clean1.kla", 8, .x * 8 + .y * $140 + 2
        	;}
	}
}
!for .y, 9, 15 {
	!for .x, 0, 39 {
        	;!if (.x = 0 or .x = 39) {
		;	!bin "clean1.kla", 8, .x * 8 + .y * $140 + 2
            	;} else {
			!bin "clean1.kla", 8, .x * 8 + .y * $140 + 2
        	;}
	}
}
!for .y, 0, 8 {
	!for .x, 0, 39 {
        	;!if (.x = 0 or .x = 39) {
		;	!bin "clean1.kla", 8, .x * 8 + .y * $140 + 2
            	;} else {
			!bin "clean1.kla", 8, .x * 8 + .y * $140 + 2
        	;}
	}
}
;sprite
;!for .x, 0, 20 {
;		!byte $f0,$00,$00
;}

;!bin "clean1.kla",$03e8,$1f42 + $03e8

		* = main
;		ldx #$00
;-
;		txa
;!for .y,0,25 {
;		sta $0400 + .y * 40,x
;}
;		inx
;		cpx #$28
;		bne -
;		jam
!ifndef release {
		lda #$0b
		sta $d011
		lda #$00
		sta $d020
		sta $d021
}
;		ldx #$00
;		ldy #$00
;-
;		ldy colred + $28,x
;		jsr vsync
;		sty $d020
;		ldy colred + $20,x
;		lda #$48
;		jsr waitras
;		ldy colred + $18,x
;		lda #$80
;		jsr waitras
;		ldy colred + $10,x
;		lda #$b8
;		jsr waitras
;		ldy colred + $08,x
;		lda #$f0
;		jsr waitras
;		ldy colred + $00,x
;		lda #$28
;		jsr waitras
;		inx
;		tya
;		bpl -

		lda #$03
		sta $dd00
		lda #$18
		sta $d016
		lda #$18
		sta $d018

		ldx #$00
		stx .trig

-
		lda #START_COL << 4 | START_COL
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		sta screen  + $000,x
		sta screen  + $100,x
		sta screen  + $200,x
		sta screen  + $300,x
		dex
		bne -
		jsr prepare_coltabs
		;jsr init_sprites
		jsr init_irq
!ifdef release {
		jsr link_load_next_comp
		jsr link_load_next_raw
}
-
		lda .trig
		beq -

		jsr vsync
		ldx #$27
-
		lda screen + $0000 +  0 * 40,x
		sta screen + $0280 +  0 * 40,x
		lda screen + $0000 +  1 * 40,x
		sta screen + $0280 +  1 * 40,x
		lda screen + $0000 +  2 * 40,x
		sta screen + $0280 +  2 * 40,x
		lda screen + $0000 +  3 * 40,x
		sta screen + $0280 +  3 * 40,x
		lda screen + $0000 +  4 * 40,x
		sta screen + $0280 +  4 * 40,x
		lda screen + $0000 +  5 * 40,x
		sta screen + $0280 +  5 * 40,x
		lda screen + $0000 +  6 * 40,x
		sta screen + $0280 +  6 * 40,x
		lda screen + $0000 +  7 * 40,x
		sta screen + $0280 +  7 * 40,x
		lda screen + $0000 +  8 * 40,x
		sta screen + $0280 +  8 * 40,x
		lda $d800  + $0000 +  0 * 40,x
		sta $d800  + $0280 +  0 * 40,x
		lda $d800  + $0000 +  1 * 40,x
		sta $d800  + $0280 +  1 * 40,x
		lda $d800  + $0000 +  2 * 40,x
		sta $d800  + $0280 +  2 * 40,x
		lda $d800  + $0000 +  3 * 40,x
		sta $d800  + $0280 +  3 * 40,x
		lda $d800  + $0000 +  4 * 40,x
		sta $d800  + $0280 +  4 * 40,x
		lda $d800  + $0000 +  5 * 40,x
		sta $d800  + $0280 +  5 * 40,x
		lda $d800  + $0000 +  6 * 40,x
		sta $d800  + $0280 +  6 * 40,x
		lda $d800  + $0000 +  7 * 40,x
		sta $d800  + $0280 +  7 * 40,x
		lda $d800  + $0000 +  8 * 40,x
		sta $d800  + $0280 +  8 * 40,x
		dex
		bpl -

		jsr vsync
		lda #<nonfld
		sta .end1 + 1
		lda #>nonfld
		sta .end2 + 1
		lda #$c0
		cmp $d012
		bne *-3

		lda #START_COL << 4 | START_COL
		ldx #$00
-
		sta screen,x
		sta $d800,x
		inx
		bne -
-
		sta screen + $100,x
		sta $d900,x
		inx
		bne -

		lda #$ff
-
		sta $2000,x
		sta $2100,x
		sta $2200,x
		sta $2300,x
		sta $2400,x
		sta $2500,x
		sta $2600,x
		sta $2700,x
		inx
		bne -

		lda #$1b
		sta .char + 1
		jsr vsync
		lda #$0a
-
		sta $d800,x
		sta $d900,x
		inx
		bne -
!ifdef release {
		;decomp $2c00-$3400
		jsr link_decomp
		jsr vsync
		jmp link_exit
} else {
		jmp *
}

vsync
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
.rts
		rts
prepare_coltabs
		ldx #(csize * $10) - 1
-
		lda coltab1_lo,x
		ora #$f0
		sta coltab1_lo,x
		asl
		asl
		asl
		asl
		ora #$0f
		sta coltab1_hi,x
		dex
		cpx #$ff
		bne -
		rts

;waitras
;		cmp $d012
;		bne *-3
;		jsr .rts
;		jsr .rts
;		jsr .rts
;		jsr .rts
;		nop
;		nop
;		nop
;		nop
;		sty $d020
;		rts
;colred
;		!byte $00,$00,$00,$00,$00,$00,$00,$00
;		!byte $00,$00,$00,$00,$00,$00,$00,$00
;		!byte $00,$00,$00,$00,$00,$00,$00,$00
;		!byte $00,$00,$00,$00,$00,$00,$00,$00
;		!byte $00,$00,$00,$00,$00,$00,$00,$00
;		!byte $00,$00,$00,$00,$00,$00,$00,$00
;		!byte $00,$09,$08,$0a,$0f,$0a,$04,$f2
;		!byte $f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2
;		!byte $f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2
;		!byte $f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2
;		!byte $f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2
;		!byte $f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2
;		!byte $f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2
col_a
		!byte $02,$04,$0a,$0a,$0a,$0a,$0a,$0a,$fa
col_1
		!byte $02,$04,$0a,$0f,$07,$01,$01,$01,$f1
col_9
		!byte $02,$08,$0a,$0f,$0a,$08,$09,$09,$f9

fadein1
!src "fade_gen1.asm"

;fadein2
;!src "fade_gen2.asm"

fld_start	= $30
fld_max		= $78
init_irq
		sei
		lda #$7f
		sta $dc0d
		lda $dc0d
		lda #$01
		sta $d019
		sta $d01a
		lda #$3b
		sta $d011
		lda #$00
		sta $d012
		lda #<pos1
		sta $fffe
		lda #>pos1
		sta $ffff
		lda #$35
		sta $01
		lda #$00
		sta $7fff
		cli
		rts
pos1
		pha
		txa
		pha
ras0		lda #START_COL
		sta $d020
.char		lda #$3b
		sta $d011
		ldx .sinpos + 1
		cpx #$f5
		bne +
.xc		lda #$00
		lsr
		lsr
		tax
		lda col_1,x
		sta ras1 + 1
		lda col_9,x
		sta ras0 + 1
		sta ras4 + 1
		bmi .t
		inc .xc + 1
		bne ++
.t
		sta <.trig
		jmp ++
+
		inc .sinpos + 1
++
		dec $d019
		lda #fld_start
		sta $d012
.end1		lda #<fld
		sta $fffe
.end2		lda #>fld
		sta $ffff
		pla
		tax
		pla
		rti

nonfld
		pha
		txa
		pha
		tya
		pha

		ldx #2
		stx $d021
		lda ras1 + 1
		ldy #$11
		dey
		bpl *-1

		sta $d020

		ldy #$0b
		dey
		bpl *-1
		stx $d020
		stx $d021

		lda #$7d
		clc
		adc $d012
		cmp $d012
		bne *-3
		clc
		lda $d011
		ora #$20
		sta $d011
		nop
		lda #$f9
		jmp skip_fld

fld
		pha
		txa
		pha
		tya
		pha


.sinpos		ldy #$00
		lda sintab,y
		clc
		adc #8
		tax

ras1		ldy #START_COL

		lda $d012
		cmp $d012	;clears carry
		beq *-3

		and #$07
		eor #$04
		ora #$38
		sta $d011
		lda $d012

		dex

		jsr .rts
		jsr .rts
		jsr .rts
		bit $ea
		nop
		nop
		sty $d020

		and #$07
		eor #$04
		ora #$38
		sta $d011
		lda $d012

		dex

		nop
		nop
		nop
		nop
		nop
		jsr .rts
		jsr .rts
		bit $ea
		ldy #START_COL
		sty $d020
		sty $d021


		and #$07
		eor #$04
		ora #$38
		sta $d011

		dex

-
		lda $d012
		cmp $d012	;clears carry
		beq *-3

		and #$07
		eor #$04
		ora #$38
		sta $d011

		dex
		bne -
		lda $d012
		adc #8*9 + 1
skip_fld
		sta $d012
		ldx #$05
		dex
		bpl *-1

ras2		lda #START_COL
		sta $d020
		sta $d021

		ldx #$09
		dex
		bpl *-1
		nop

ras_bg		lda #START_COL
		sta $d020
		sta $d021

		dec $d019

		lda #<reset
		sta $fffe
		lda #>reset
		sta $ffff

		pla
		tay
		pla
		tax
		pla
		rti
reset
		pha
		txa
		pha
		tya
		pha

		lda $d012
		cmp #$f6
		bcs +
		ldy #$21
		top
+
		ldy #$2a
		dey
		bpl *-1
ras3		lda #START_COL
		sta $d020
		sta $d021
ras4		ldy #START_COL

		ldx #$0a
		dex
		bpl *-1

		sty $d020
		sty $d021

		lda #$00
		sta $d012


		lda #<pos1
		sta $fffe
		lda #>pos1
		sta $ffff
		dec $d019
		cli
		jsr setcols
		pla
		tay
		pla
		tax
		pla
		rti

setcols
.wait		lda #$00
		inc .wait + 1
		and #$03
		beq +
		rts
+
fadein
fadeinpos	ldy #$00
		cpy #csize
		beq done
		lda col_1,y
		sta ras2 + 1
		sta ras3 + 1
		lda col_a,y
		sta ras_bg + 1
		lda #$ff
		jsr fadein1
		inc fadeinpos + 1
		rts
done
		rts

sintab
!byte $6B,$69,$68,$67,$65,$64,$63,$61,$60,$5E,$5D,$5B,$5A,$58,$57,$55
!byte $54,$52,$51,$4F,$4E,$4C,$4A,$49,$47,$46,$44,$42,$41,$3F,$3E,$3C
!byte $3A,$39,$37,$36,$34,$33,$31,$2F,$2E,$2C,$2B,$29,$28,$26,$25,$24
!byte $22,$21,$1F,$1E,$1D,$1B,$1A,$19,$17,$16,$15,$14,$13,$12,$10,$0F
!byte $0E,$0D,$0C,$0B,$0B,$0A,$09,$08,$07,$07,$06,$05,$05,$04,$04,$03
!byte $03,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02
!byte $02,$02,$03,$03,$04,$04,$05,$06,$06,$07,$08,$09,$0A,$0B,$0C,$0D
!byte $0E,$0F,$11,$12,$13,$15,$16,$18,$19,$1B,$1D,$1E,$20,$22,$24,$26
!byte $28,$2A,$2C,$2E,$30,$32,$34,$37,$39,$3B,$3E,$40,$43,$45,$48,$4B
!byte $4D,$50,$53,$56,$58,$5B,$5E,$61,$64,$67,$6A,$6D,$70,$73,$77,$78
!byte $78,$77,$77,$76,$75,$75,$74,$73,$73,$72,$71,$71,$70,$70,$6F,$6E
!byte $6E,$6D,$6D,$6C,$6B,$6B,$6A,$6A,$69,$69,$69,$68,$68,$67,$67,$67
!byte $66,$66,$66,$65,$65,$65,$65,$64,$64,$64,$64,$64,$64,$64,$64,$64
!byte $64,$64,$64,$64,$64,$64,$64,$65,$65,$65,$65,$66,$66,$67,$67,$67
!byte $68,$68,$69,$69,$6A,$6B,$6B,$6C,$6D,$6D,$6E,$6F,$70,$71,$71,$72
!byte $73,$74,$75,$76,$77,$78,$77,$76,$75,$73,$72,$71,$70,$6F,$6D,$6C

;init_sprites
		;lda #$ff
		;sta $d015
		;sta $d017
		;sta $d01d
		;lda #$00
		;sta $d01b
		;sta $d01c
		;lda #$18
		;sta $d000
		;sta $d002
		;sta $d004
		;sta $d006
		;lda #$50
		;sta $d008
		;sta $d00a
		;sta $d00c
		;sta $d00e
		;lda #$f0
		;sta $d010
		;lda #$02
		;sta $d001
		;sta $d009
		;lda #$2c
		;sta $d003
		;sta $d00b
		;lda #$56
		;sta $d005
		;sta $d00d
		;lda #$f7
		;sta $d001
		;sta $d009
		;lda #$80
		;sta $d007
		;sta $d00f
		;lda #$01
		;sta $d027
		;sta $d02b
		;;lda #$02
		;sta $d028
		;sta $d02c
		;;lda #$03
		;sta $d029
		;sta $d02d
		;;lda #$04
		;sta $d02a
		;sta $d02e
		;rts

coltab1_lo
         !byte $02,$04,$08,$09,$00,$0b,$0c,$0b,$00
         !byte $02,$04,$0f,$07,$01,$01,$01,$01,$01
         !byte $02,$04,$0a,$0a,$02,$08,$0a,$08,$02
         !byte $02,$04,$0a,$0f,$03,$0d,$01,$0d,$03
         !byte $02,$04,$0a,$0a,$04,$0e,$03,$0e,$04
         !byte $02,$04,$0a,$0a,$05,$0f,$0d,$0f,$05
         !byte $02,$04,$0a,$04,$06,$04,$0e,$04,$06
         !byte $02,$04,$0a,$0f,$07,$01,$01,$01,$07
         !byte $02,$04,$0a,$0a,$08,$0a,$0f,$0a,$08
         !byte $02,$04,$0a,$08,$09,$08,$0a,$08,$09
         !byte $02,$04,$0a,$0a,$0a,$0f,$07,$0f,$0a
         !byte $02,$04,$0a,$08,$0b,$0c,$0f,$0c,$0b
         !byte $02,$04,$0a,$0a,$0c,$0f,$01,$0f,$0c
         !byte $02,$04,$0a,$0f,$0d,$01,$01,$01,$0d
         !byte $02,$04,$0a,$0a,$0e,$03,$0d,$03,$0e
         !byte $02,$04,$0a,$0a,$0f,$07,$01,$07,$0f
coltab1_hi
