!cpu 6510
scr 		= $0a
dst		= $0c
val		= $0e
clrm		= $10
st		= $12
tabpos		= $14

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
signal		= link_music_init_side3b + $3f
}

main		= $e400
bitmap		= $c000
screen 		= $e000
coltab_hi	= $0400
coltab_lo	= $0500
		* = main

		jsr gen
		jsr clr_scr

		;and turn on gfx
		lda #$3b
		sta $d011
		lda #$80
		sta $d018
		sta $dd00
		lda #$16
		sta $d016

--
		jsr wait
		jsr wait

start		ldx #$00
		inc start+1
		ldy curve,x
                lda coltab_lo,y
		sta $d021
		sta $d020
		lda #$ff
		tax
		jsr fader

		lda start+1
		cmp #$0a
		bne --
!ifdef release {
		jmp $0100
} else {
		jmp *
}

clr_scr
		lda #$11
		ldx #$00
-
		sta screen + $000,x
		sta screen + $100,x
		sta screen + $200,x
		sta screen + $2f8,x
		inx
		bne -
wait
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		rts

curve
		!byte $0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$06

fader
!src "fade_gen.asm"

		* = screen
coltab
		!byte $00,$00,$00,$00,$00,$00,$00,$0b,$0c,$0f,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$0b,$0c,$0f,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$00,$00,$02,$08,$0a,$0f,$07,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$06,$04,$0e,$03,$01,$01,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$00,$06,$04,$0e,$03,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$09,$0c,$05,$0f,$0d,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$00,$00,$06,$04,$0e,$03,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$09,$08,$0a,$0f,$07,$01,$01,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$00,$09,$08,$0a,$0f,$07,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$00,$00,$09,$08,$0a,$0f,$07,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$09,$08,$0a,$0f,$07,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$00,$00,$0b,$0c,$0f,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$00,$0b,$0c,$0f,$01,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$0b,$0c,$05,$03,$0d,$01,$01,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$06,$04,$0e,$03,$01,$01,$01,$01,$01,$01,$01,$01
		!byte $00,$00,$00,$00,$0b,$0c,$0f,$01,$01,$01,$01,$01,$01,$01,$01,$01
gen
clr_d800
		lda #$11
		ldx #$00
-
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		inx
		bne -
		sta $d021

		;generate high tab
-
		lda coltab,x
		ora #$f0
		sta coltab_lo,x
		asl
		asl
		asl
		asl
		ora #$0f
		sta coltab_hi,x
		inx
		bne -
!ifdef release {
		ldx #stackcode_end-stackcode_start
-
		lda stackcode,x
		sta $0100,x
		dex
		bpl -
		rts
stackcode_start
stackcode
		+setup_sync $48
		jsr link_load_next_comp
		+sync
		jmp link_exit
stackcode_end
} else {
		rts
}



		* = bitmap
!bin "tiles1.kla",$1f40,2
