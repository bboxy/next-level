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

main		= $2000
bitmap		= $4000
screen 		= $6400
sprites		= $6000
sprinkle	= $6800
textline	= screen + $148
textline2	= screen + $348

sprbase		= <(sprinkle / $40)


bubble_ypos	= $a1
bubble_xpos	= $20

		* = main



		lda #$00
		sta $d011
		lda #$00
		sta $d012
;!ifndef release {
		lda #$01
		sta $d019
		sta $d01a
		lda #$7f
		sta $dc0d
		lda $dc0d
;}
		lda #<irq0
		sta $fffe
		lda #>irq0
		sta $ffff

		lda #$00
		sta tabpos
		sta $d010
		sta $d02d
		sta $d02e
		sta $d025
		sta $d026

		cli

		ldx #$00
		;generate high tab
-
		lda coltab_lo,x
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

		;clear screen
		jsr clr_scr
		;sync
		jsr wait

		;and turn on gfx
		lda #$02
		sta $dd00
		lda #$3b
		sta $d011
		lda #$90
		sta $d018
		lda #$18
		sta $d016

--
		jsr wait
		jsr wait

start		ldx #$00
		inc start+1
		ldy curve,x
                lda coltab_lo,y
		sta $d021
		lda coltab_lo + $10,y
		sta .bubcol + 1
		sta .txtcol + 1
		lda #$ff
		tax
		jsr fader

		lda start+1
		cmp #$21
		bne .fade1
!ifdef release {
-
		lda .fadem + 1
		cmp #$40
		bcc -
		lda #$00
		sta $d015
		+stop_music_nmi
		;XXX TODO music fadeout
		;can even preload more
		;ldx #$00
;-
;		lda .stackcode,x
;		sta $0100,x
;		inx
;		cpx #.stackcode_end - .stackcode
;		bne -
		jmp link_exit

;.stackcode
;		sei
;		dec $01
;		jsr link_decomp
;		inc $01
;		jmp link_exit
.stackcode_end
} else {
		sei
		jmp *
}
.fade1
		cmp #$19
		bne --
!ifdef release {
		lda #$00
		sta signal
		sta .signum + 1
}
		lda #$cf
		sta $d015
		lda #$01
		sta .bubcol + 1
		sta .txtcol + 1
-
		jsr wait
		jsr addline
		lda .liney + 1
		bpl -
		lda #$ff
		sta $d015
		jsr add_text
		inc .enable + 1

!ifdef release {
	!ifdef crt {
  		+crt_request_disk $4e2
	} else {
		+request_disk 3
	}
} else {
		jsr space
}
		lda #$20
		sta .enable_spr
!ifdef release {
		jsr link_load_next_raw
		inc .fadem + 1
}
-
		lda tabpos
		cmp #$28
		bne -

		lda .ctr + 1
		bmi +
		cmp #$78
		bcs .wait
		lda #$78
		bne ++
+
		cmp #$f8
		bcs .wait
		lda #$f8
++
		sta .ctr + 1
.wait
		lda .ctr + 1
		and #$0f
		cmp #$0f
		bne .wait
		dec .enable + 1
		;ldy #$00
-
		;jsr wait
		;jsr wait
		;jsr wait
		;jsr wait
		;lda bubblecoli,y
		;sta .bubcol + 1
		;sta .txtcol + 1
		;iny
		;cpy #$08
		;bne -
.fade2
		jmp --

!ifndef release {
space
		lda #$10
		bit $dc01
		bne *-3
		bit $dc01
		beq *-3
		rts
}

irq0
		pha
		txa
		pha
		tya
		pha
.enable_spr	top set_sprinkle
		lda #bubble_ypos - $18
		sta $d012
		lda #<irq0_
		sta $fffe
		lda #>irq0_
		sta $ffff
		dec $d019
		pla
		tay
		pla
		tax
		pla
		rti
irq0_
		pha
		txa
		pha
		tya
		pha
		lda #$00
		sta $d02d
		sta $d02e
		lda #$d0	;b8
		sta $d00c
		clc
		adc #24
		sta $d00e
		lda #$94	;60
		sta $d00d
		sta $d00f

		ldx #<(bgspr / $40)
		stx screen + $3fc
		stx screen + $3fd

		ldx #<(csign / $40)
		stx screen + $3fe
		inx
		stx screen + $3ff

		lda #$c0
		sta $d01c
		lda #$30
		sta $d01d
		sta $d017

		lda #$c0
		sta $d01b
.enable
		lda #$00
		bne +
		jmp .not_yet
+

.speed		lda #$00
		inc .speed + 1
		and #$01
		bne .skip2
+
		ldy #$00
.ctr		ldx #$00
		bmi .text2
		cpx #$08
		bcs +
		ldy bubblecoli,x
+
		cpx #$78
		bcc +
		ldy bubblecolo - $78,x
+
		ldx #<(bubble / $40)
		stx .text1_ptr + 1
		ldx #<(bubble / $40) + 4
		stx .text2_ptr + 1
		jmp .skip
.text2
		cpx #$88
		bcs +
		ldy bubblecoli - $80,x
+
		cpx #$f8
		bcc +
		ldy bubblecolo - $f8,x
+
		ldx #<(bubble / $40) + 8
		stx .text1_ptr + 1
		ldx #<(bubble / $40) + 8 + 4
		stx .text2_ptr + 1
.skip
		sty .txtcol + 1
		inc .ctr + 1
.skip2
!ifdef release {
		lda signal
		beq +
.signum		lda #$20
		sta .cnt + 1
		sta signal
+
}
.cnt
		lda #$20
		lsr
		lsr
		tax
		lda .cnt + 1
		and #$03
		bne +
		cpx #$20
		bne +
!ifdef release {
		ldx #$20
} else {
		ldx #$00
}
		stx .cnt + 1
+
		lda color_0,x
		sta $d025
		lda color_6,x
		sta $d026
		lda color_b,x
		sta $d02d
		sta $d02e
		inc .cnt + 1
.not_yet
		lda #bubble_xpos
		clc
		sta $d000
		adc #24
		sta $d002
		adc #24
		sta $d004
		adc #24
		sta $d006

		lda #bubble_ypos + 5
		sta $d009
		sta $d00b

		lda #bubble_xpos + 6
		sta $d008
		clc
		adc #40
		sta $d00a


.text1_ptr	ldx #<(bubble / $40)
		stx screen + $3f8
		inx
		stx screen + $3f9
		inx
		stx screen + $3fa
		inx
		stx screen + $3fb

		lda #bubble_ypos
		sta $d001
		sta $d003
		sta $d005
		sta $d007

.txtcol		lda #$00
		sta $d02b
		sta $d02c

.bubcol		lda #$00
		sta $d027
		sta $d028
		sta $d029
		sta $d02a

		lda #bubble_ypos - 1 + 21
		sta $d012
		lda #<irq1
		sta $fffe
		lda #>irq1
		sta $ffff
		dec $d019
		pla
		tay
		pla
		tax
		pla
		rti

irq1
		pha
		txa
		pha
		tya
		pha

		lda #bubble_ypos + 21
		sta $d001
		sta $d003
		sta $d005
		sta $d007

		lda #<irq0
		sta $fffe
		lda #>irq0
		sta $ffff

		lda #$00
		sta $d012

.text2_ptr	ldx #<(bubble / $40) + 4
		stx screen + $3f8
		inx
		stx screen + $3f9
		inx
		stx screen + $3fa
		inx
		stx screen + $3fb

		dec $d019

!ifdef release {
.fadem		lda #$ff
		bmi ++
		lsr
		lsr
		cmp #$0f
		bcc +
		lda #$0f
+
		eor #$0f
		jsr link_music_fade_side3b
		inc .fadem + 1
++
}
		pla
		tay
		pla
		tax
		pla
		rti

clr_scr
		lxa #0
-
		sta screen + $000,x
		sta screen + $100,x
		sta screen + $200,x
		sta screen + $2f8,x
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		inx
		bne -
		rts
bubblecoli
		!byte $01,$07,$0f,$0a,$08,$09,$00,$00
bubblecolo
		!byte $00,$09,$08,$0a,$0f,$07,$01,$01
curve
		!byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06
		!byte $06,$06,$05,$04,$03,$02,$01,$00,$00
		;!byte $07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00,$00

wait
		bit $d011
		bmi *-3
		bit $d011
		bpl *-3
		rts

coltab_lo
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

color_0
	!byte $00,$00,$00,$06,$04,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
color_b
	!byte $00,$06,$04,$0e,$0f,$0e,$04,$06,$00,$00,$00,$00,$00,$00,$00,$00
	!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
color_6
	!byte $00,$00,$06,$04,$0e,$04,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00
	!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
color_e
	!byte $0e,$0e,$03,$03,$03,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
	!byte $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
color_6_
	!byte $60,$40,$40,$40,$40,$40,$40,$60,$60,$60,$60,$60,$60,$60,$60,$60
	!byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
color_f
	!byte $0f,$0f,$03,$03,$03,$03,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
color_c_
	!byte $c0,$c0,$e0,$e0,$e0,$e0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
	!byte $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0

coltab_hi
!fill 256,0
fader
!src "fade_gen.asm"

set_sprinkle
.num
			lda #$00
			inc .num + 1
			and #$03
			bne set
			ldx #$07
-
			lda sprcnt,x
			bmi .new
			dex
			bpl -
			jmp set
.new
			lda #$1f
			sta sprcnt,x
			ldy tabpos
			lda sprtabx,y
			sta sprposx,x
			lda sprtaby,y
			sta sprposy,x
			iny
			cpy #$28
			bne +
			lda #$0c
			sta .enable_spr
+
			sty tabpos
set
			ldx #$07
-
			lda sprcnt,x
			bmi +
			lsr
			clc
			adc #sprbase
			sta screen + $3f8,x
			dec sprcnt,x
+
			lda sprcnt,x
			bpl +
			lda #$00
+
			lsr
			tay
			lda colors,y
			sta $d027,x
			txa
			asl
			tay
			lda sprposx,x
			sta $d000,y
			lda sprposy,x
			sta $d001,y
			dex
			bpl -
			lda #$00
			sta $d01c
			sta $d01b
			sta $d017
			sta $d01d
			rts

sprposx
			!byte $00,$00,$00,$00,$00,$00,$00,$00
sprposy
			!byte $00,$00,$00,$00,$00,$00,$00,$00
colors
			!byte $09,$08,$0a,$0f,$07,$01,$01,$01,$01,$01,$01,$07,$0f,$0a,$08,$09

sprtabx
			!byte $a8,$b8,$c8,$d8,$e8,$f8
			!byte $fc,$ec,$dc,$cc,$bc,$ac
			!byte $c4,$c4
			!byte $c8,$cc
			!byte $d0,$d4,$d8,$dc,$dc,$dc,$dc,$dc
			!byte $00,$00,$00,$00,$00,$00,$00,$00
			!byte $00,$00,$00,$00,$00,$00,$00,$00
sprtaby
			!byte $4d,$4c,$4b,$4a,$49,$48
			!byte $42,$43,$44,$45,$46,$47
			!byte $40,$3c
			!byte $38,$34
			!byte $34,$32,$32,$32,$34,$38,$3c,$40
			!byte $00,$00,$00,$00,$00,$00,$00,$00
			!byte $00,$00,$00,$00,$00,$00,$00,$00

sprcnt
			!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

addline
.liney			ldy #$7c
			bpl +
			rts
+
			cpy #$40
			bcs .second
			lda bubble_src + $00,y
			sta bubble + $00,y
			lda bubble_src + $01,y
			sta bubble + $01,y
			lda bubble_src + $02,y
			sta bubble + $02,y

			lda bubble_src + $40,y
			sta bubble + $40,y
			lda bubble_src + $41,y
			sta bubble + $41,y
			lda bubble_src + $42,y
			sta bubble + $42,y

			lda bubble_src + $80,y
			sta bubble + $80,y
			lda bubble_src + $81,y
			sta bubble + $81,y
			lda bubble_src + $82,y
			sta bubble + $82,y

			lda bubble_src + $c0,y
			sta bubble + $c0,y
			lda bubble_src + $c1,y
			sta bubble + $c1,y
			lda bubble_src + $c2,y
			sta bubble + $c2,y

			jmp .cpdone
.second
			tya
			and #$3f
			tay
			lda bubble_src + $100,y
			sta bubble + $100,y
			lda bubble_src + $101,y
			sta bubble + $101,y
			lda bubble_src + $102,y
			sta bubble + $102,y

			lda bubble_src + $140,y
			sta bubble + $140,y
			lda bubble_src + $141,y
			sta bubble + $141,y
			lda bubble_src + $142,y
			sta bubble + $142,y

			lda bubble_src + $180,y
			sta bubble + $180,y
			lda bubble_src + $181,y
			sta bubble + $181,y
			lda bubble_src + $182,y
			sta bubble + $182,y

			lda bubble_src + $1c0,y
			sta bubble + $1c0,y
			lda bubble_src + $1c1,y
			sta bubble + $1c1,y
			lda bubble_src + $1c2,y
			sta bubble + $1c2,y

.cpdone
			dec .liney + 1
			dec .liney + 1
			dec .liney + 1
			lda .liney + 1
			cmp #$3d
			bne +
			dec .liney + 1
+
			rts

add_text
			ldy #$00
-
			lda text + $000,y
			eor bubble + $000,y
			sta bubble + $000,y

			lda text + $100,y
			eor bubble + $100,y
			sta bubble + $100,y

			lda text + $200,y
			eor bubble + $200,y
			sta bubble + $200,y

			lda text + $300,y
			eor bubble + $300,y
			sta bubble + $300,y

			dey
			bne -
			rts


		* = bitmap
!bin "clean.kla",$1f40,2
bgspr
!fill 15*3,$ff
!fill 6*3+1,00
csign
!bin "csign.spr"
		* = sprites
bubble
!fill $200,0
bubble_src
!bin "bubble.spr"
;!bin "bubble.spr"
		* = sprinkle
!bin "sprinkle.spr"
text
!bin "text.spr",$100
!bin "text.spr",$100,$200
!bin "text.spr",$100,$100
!bin "text.spr",$100,$300



		* = screen
!bin "lyric.chr", $140,0
		* = screen + 11 * 40
		!byte $27,$27
!bin "lyric.scr", $26,0
		!byte $4f,$4f
!bin "lyric.scr", $26,$28
		* = screen + 13 * 40
!bin "lyric.chr",$140,$140
		* = screen + $3f8
		!fill $8, sprbase

		* = textline
		sei
		lda #$35
		sta $01
		lxa #0
!ifndef release {
		sta $d020
		sta $d021
}
-
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		dex
		bne -
		ldx #$27
-
		lda screen + 11 * 40,x
		eor #$80
		sta screen + 11 * 40,x
		lda screen + 12 * 40,x
		clc
		adc #$99
		sta screen + 12 * 40,x
		dex
		bpl -
		lda #$02
		sta $dd00
		lda #$1b
		sta $d011
		lda #$98
		sta $d018
		lda #$08
		sta $d016
		jmp textline2
wait_
		bit $d011
		bmi *-3
		bit $d011
		bpl *-3
		rts

		* = textline2
		jsr wait_
		lda #<irq
		sta $fffe
		lda #>irq
		sta $ffff
		lda #$01
		sta $d019
		sta $d01a
		lda #$7f
		sta $dc0d
		lda $dc0d
		lda #$00
		sta $d012
		cli
!ifdef release {
		jsr link_load_next_comp
}
trig		lda #$0f
		bne trig
		jmp main
irq
		pha
		txa
		pha
		tya
		pha
		dec $d019
text_disable
		jmp do_text1
		jmp do_wait
		jmp do_text1
do_text1
		lda #$0f
do_text_col_y1	ldy #$00
		cpy #$28
		bne +
		sta trig + 1
		lda #$00
		sta do_text1 + 1
		sta do_text_col_y1 + 1
		lda #$0c
		sta text_disable + 0
		bpl text_irq_end
+
		inc do_text_col_y1 + 1
do_text_col
		sta $d800 + 11 * 40,y
		sta $d800 + 12 * 40,y
		bpl text_irq_end
do_wait
		ldy #$80
		bne +
		lda #$0c
		sta text_disable + 3
		bpl text_irq_end
+
		dec do_wait + 1
text_irq_end
		pla
		tay
		pla
		tax
		pla
		rti

