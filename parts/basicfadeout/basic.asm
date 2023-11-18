!cpu 6510

spr		= $10
spr_		= $12
dst		= $14
!ifdef release {
main		= $2000
} else {
main		= $2000
}

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}
!ifndef release {
		;!src "../../bitfire/music.inc"
		;* = link_music_init_side3
		;!bin "../../music/music.prg",,2
}

		* = main
		sei
                lda #$35
                sta $01
!ifndef release {
		jsr vblank
		lda #$0b
		sta $d011
}
		lda #$03
		sta $dd00
		lda #$20
		ldx #$00
-
		sta $0400,x
		sta $0500,x
		sta $0600,x
		sta $0700,x
		dex
		bne -

		lda #$7f
		sta $dc0d
		sta $dd0d
		lda $dc0d
		lda $dd0d
		sei
!ifdef release {
		+to_nmi
		lda #<link_music_play_side3b
		sta link_music_addr + 0
		lda #>link_music_play_side3b
		sta link_music_addr + 1
		jsr link_load_next_comp
		lxa #0
		tay
		jsr link_music_init_side3b
		+start_music_nmi
}
		jsr vblank
		ldx #$00
-
		lda vic_data,x
		sta $d000,x
		inx
		cpx #$30
		bne -
		lda #<irq1
		sta $fffe
		lda #>irq1
		sta $ffff

		ldx #$58
		stx .last_spx1 + 1
		dex
		stx .last_spx2 + 1

		ldx #$07
		ldy #(sprites & $3fff) / 64 + 7
-
		tya
		sta $07f8,x
		dey
		dex
		bpl -

		jsr do_dots

		cli
!ifdef release {
		jsr link_load_next_comp
		jsr link_load_next_comp
.trig		lda #$00
		beq .trig
		jmp link_exit
} else {
		jmp *
}
vblank
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		rts
irq1
		pha
		lda #$b8
		sta $d001
		sta $d009
.last_spx1	lda #$00
		sta $d000
.last_spx2	lda #$00
		sta $d008
		lda #$ff
		sta $d01d
		lda #(sprites & $3fff) / 64 + 0
		sta $07f8
		lda #(sprites & $3fff) / 64 + 4
		sta $07fc
		lda #$fa
		sta $d012
		lda #<irq2
		sta $fffe
		lda #>irq2
		jmp ++
irq2
		pha
		txa
		pha
		tya
		pha
		dec $d019
		lda #$a0
		sta $d001
		sta $d009
		lda #$ac
		sta $d000
		sta $d008
		lda #$00
		sta $d01d

.type		ldx #(sprites & $3fff) / 64 + 10
		stx $07f8
		inx
		stx $07fc
		lda #$34
		sta $d012
		lda #$9b
		sta $d011
		lda #<irq3
		sta $fffe
		lda #>irq3
		sta $ffff
		cli
.effect		jmp (effect_tgts)
.back
		pla
		tay
		pla
		tax
		pla
		rti
irq3
		pha
		lda #$b6
		sta $d012
		lda #$1b
		sta $d011
.d020		lda #$02
		sta $d020
		lda #<irq1
		sta $fffe
		lda #>irq1
++
		dec $d019
		sta $ffff
		pla
		rti



volume_up
.cnt		lda #$30
		dec .cnt + 1
		bne +
		lda #$02
		sta .cnt + 1
		lda .num_dots + 1
		cmp #44
		beq ++
		inc .num_dots + 1
		jsr do_dots
+
		jmp .back
++
		inc .effect + 1
		inc .effect + 1
		jmp .back

volume_stay
.cnt2		lda #$18
		dec .cnt2 + 1
		beq +
		jmp .back
+
		inc .effect + 1
		inc .effect + 1
		jmp .back

volume_vanish
		lda #$00
		sta $d015
		sta $07f8
		lda #22
		sta .num_dots + 1
		jsr do_dots
.cnt3		lda #$18
		dec .cnt3 + 1
		beq +
		jmp .back
+
		inc .effect + 1
		inc .effect + 1
		lda #(sprites & $3fff) / 64 + 8
		sta .type + 1
		lda #$00
		sta $d02b
		sta $d02c
		sta $d02d
		sta $d02e
		jmp .back

bright_up
		lda #$ff
		sta $d015
.cnt4		lda #$28
		dec .cnt4 + 1
		bne +
		lda #$02
		sta .cnt4 + 1
		lda .num_dots + 1
		cmp #44
		beq ++
		inc .num_dots + 1
		jsr set_colors
		jsr do_dots
+
		jmp .back
++
		inc .effect + 1
		inc .effect + 1
		inc .effect + 1
		inc .effect + 1
		lda #$20
		ldx #$00
-
		sta $0400,x
		sta $0500,x
		sta $0600,x
		sta $06f8,x
		dex
		bne -
		lda #(5 << 3)
		sta .bg + 1
		sta .border + 1
		jmp .back


bright_down
.cnt5		lda #$10
		dec .cnt5 + 1
		bne +
		lda #$04
		sta .cnt5 + 1
		lda .num_dots + 1
		cmp #22
		beq ++
		dec .num_dots + 1
		jsr set_colors
		jsr do_dots
+
		jmp .back
++
		inc .effect + 1
		inc .effect + 1
		jmp .back

bright_vanish
.cnt6		lda #$28
		dec .cnt6 + 1
		beq +
		jmp .back
+
		lda #$00
		sta $d015
!ifdef release {
		lda #$01
		sta .trig + 1
}
		jmp .back

set_colors
		ldy .num_dots + 1
		ldx tl_tab,y
.bg		lda coltab_0,x
		sta $d021
.border		lda coltab_0,x
		sta .d020 + 1
		;jsr fader
		rts
do_dots
		ldx #$00
-
		lda pos_tab + 0,x
		sta spr + 0
		sta spr_ + 0
		lda pos_tab + 1,x
		sta spr + 1
		clc
		adc #1
		sta spr_ + 1
.num_dots	cpx #00
		stx .xsave + 1
		bcs +
		jsr set
		jmp ++
+
		jsr clear
++
.xsave		ldx #$00
		inx
		inx
		cpx #44
		bne -
		rts

set
		txa
		lsr
		lsr
		bcc set2
set1
		ldx #$00
		ldy #$00
-
		lda (spr),y
		and #$0f
		ora set1_data,x
		sta (spr),y
		lda (spr_),y
		and #$0f
		ora set1_data + 6,x
		sta (spr_),y
		iny
		iny
		iny
		inx
		cpx #6
		bne -
		rts
set2
		ldx #$00
		ldy #$00
-
		lda (spr),y
		and #$f0
		ora set2_data,x
		sta (spr),y
		lda (spr_),y
		and #$f0
		ora set2_data + 6,x
		sta (spr_),y
		iny
		iny
		iny
		inx
		cpx #6
		bne -
		rts

clear
		txa
		lsr
		lsr
		bcc clear2
clear1
		ldx #$00
		ldy #$00
-
		lda (spr),y
		and #$0f
		ora clear1_data,x
		sta (spr),y
		lda (spr_),y
		and #$0f
		ora clear1_data + 6,x
		sta (spr_),y
		iny
		iny
		iny
		inx
		cpx #6
		bne -
		rts
clear2
		ldx #$00
		ldy #$00
-
		lda (spr),y
		and #$f0
		ora clear2_data,x
		sta (spr),y
		lda (spr_),y
		and #$f0
		ora clear2_data + 6,x
		sta (spr_),y
		iny
		iny
		iny
		inx
		cpx #6
		bne -
		rts

set1_data
		!byte %00000000
		!byte %11100000
		!byte %11100000
		!byte %11100000
		!byte %11100000
		!byte %00000000

		!byte %11110000
		!byte %11110000
		!byte %11110000
		!byte %11110000
		!byte %11110000
		!byte %11110000
set2_data
		!byte %00000000
		!byte %00001110
		!byte %00001110
		!byte %00001110
		!byte %00001110
		!byte %00000000

		!byte %00001111
		!byte %00001111
		!byte %00001111
		!byte %00001111
		!byte %00001111
		!byte %00001111
clear1_data
		!byte %00000000
		!byte %00000000
		!byte %01000000
		!byte %01000000
		!byte %00000000
		!byte %00000000

		!byte %00000000
		!byte %01100000
		!byte %01100000
		!byte %01100000
		!byte %01100000
		!byte %00000000
clear2_data
		!byte %00000000
		!byte %00000000
		!byte %00000100
		!byte %00000100
		!byte %00000000
		!byte %00000000

		!byte %00000000
		!byte %00000110
		!byte %00000110
		!byte %00000110
		!byte %00000110
		!byte %00000000
effect_tgts
		!word volume_up
		!word volume_stay
		!word volume_vanish
		!word bright_up
		!word bright_down
		!word bright_vanish

pos_tab
		!word sprites + $000 +  09
		!word sprites + $000 +  10
		!word sprites + $000 +  10
		!word sprites + $000 +  11
		!word sprites + $000 +  11

		!word sprites + $040 +  09
		!word sprites + $040 +  09
		!word sprites + $040 +  10
		!word sprites + $040 +  10
		!word sprites + $040 +  11
		!word sprites + $040 +  11

		!word sprites + $080 +  09
		!word sprites + $080 +  09
		!word sprites + $080 +  10
		!word sprites + $080 +  10
		!word sprites + $080 +  11
		!word sprites + $080 +  11

		!word sprites + $0c0 +  09
		!word sprites + $0c0 +  09
		!word sprites + $0c0 +  10
		!word sprites + $0c0 +  10
		!word sprites + $0c0 +  11

tl_tab
		!byte $00
		!byte $00
		!byte $00
		!byte $00

		!byte $00
		!byte $00
		!byte $00
		!byte $00
		!byte $00
		!byte $00

		!byte $00
		!byte $00
		!byte $00
		!byte $00
		!byte $00
		!byte $00

		!byte $00
		!byte $00
		!byte $00
		!byte $00
		!byte $00
		!byte $00

		!byte $00
		!byte $00
		!byte $00
		!byte $00
		!byte $00
		!byte $00

		!byte $01
		!byte $01
		!byte $01
		!byte $02
		!byte $02
		!byte $02

		!byte $03
		!byte $03
		!byte $03
		!byte $04
		!byte $04
		!byte $04

		!byte $05
		!byte $05
		!byte $05
		!byte $06
		!byte $06
		!byte $06

		!byte $07
		!byte $07
		!byte $07
		!byte $07



!align 63,0
sprites
		!byte %00000000,%00000000,%00000000
		!byte %01100000,%00000000,%00000000
		!byte %01100000,%00000000,%00000000
		!byte %01000000,%00000000,%00000000
		!byte %01000000,%00000000,%00000000
		!byte %01000000,%00000000,%00000000
		!byte %01000000,%00000000,%00000000
		!byte %01000000,%00000000,%00000000
		!byte %01000000,%00000000,%00000000
		!byte %01100000,%00000000,%00000000
		!byte %01100000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00001100
		!byte %00000000,%00000000,%00001100
		!byte %00000000,%00000000,%00000100
		!byte %00000000,%00000000,%00000100
		!byte %00000000,%00000000,%00000100
		!byte %00000000,%00000000,%00000100
		!byte %00000000,%00000000,%00000100
		!byte %00000000,%00000000,%00000100
		!byte %00000000,%00000000,%00001100
		!byte %00000000,%00000000,%00001100
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %01110000,%00000000,%00000000
		!byte %01110000,%00000000,%00000000
		!byte %01110000,%00000000,%00000000
		!byte %01110000,%00000000,%00000000
		!byte %01100000,%00000000,%00000000
		!byte %01100000,%00000000,%00000000
		!byte %01100000,%00000000,%00000000
		!byte %01100000,%00000000,%00000000
		!byte %01110000,%00000000,%00000000
		!byte %01110000,%00000000,%00000000
		!byte %01110000,%00000000,%00000000
		!byte %01110000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %00000000,%00000000,%00001110
		!byte %00000000,%00000000,%00001110
		!byte %00000000,%00000000,%00001110
		!byte %00000000,%00000000,%00001110
		!byte %00000000,%00000000,%00000110
		!byte %00000000,%00000000,%00000110
		!byte %00000000,%00000000,%00000110
		!byte %00000000,%00000000,%00000110
		!byte %00000000,%00000000,%00001110
		!byte %00000000,%00000000,%00001110
		!byte %00000000,%00000000,%00001110
		!byte %00000000,%00000000,%00001110
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00001000,%00000000
		!byte %00000000,%00001000,%00000000
		!byte %00000100,%00001000,%00010000
		!byte %00000010,%00000000,%00100000
		!byte %00000000,%00111110,%00000000
		!byte %00000000,%11111111,%10000000
		!byte %00000000,%11111111,%10000000
		!byte %00000001,%11111111,%11000000
		!byte %00000001,%11111111,%11000000
		!byte %00011101,%11111111,%11011100
		!byte %00000001,%11111111,%11000000
		!byte %00000001,%11111111,%11000000
		!byte %00000000,%11111111,%10000000
		!byte %00000000,%11111111,%10000000
		!byte %00000000,%00111110,%00000000
		!byte %00000010,%00000000,%00100000
		!byte %00000100,%00001000,%00010000
		!byte %00000000,%00001000,%00000000
		!byte %00000000,%00001000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %00000000,%00011100,%00000000
		!byte %00000000,%00011100,%00000000
		!byte %00001100,%00011100,%00011000
		!byte %00001110,%00011100,%00111000
		!byte %00000111,%00111110,%01110000
		!byte %00000011,%11111111,%11100000
		!byte %00000001,%11111111,%11000000
		!byte %00000001,%11111111,%11000000
		!byte %00000011,%11111111,%11100000
		!byte %00111111,%11111111,%11111110
		!byte %00111111,%11111111,%11111110
		!byte %00111111,%11111111,%11111110
		!byte %00000011,%11111111,%11100000
		!byte %00000001,%11111111,%11000000
		!byte %00000001,%11111111,%11000000
		!byte %00000011,%11111111,%11100000
		!byte %00000111,%00111110,%01110000
		!byte %00001110,%00011100,%00111000
		!byte %00001100,%00011100,%00011000
		!byte %00000000,%00011100,%00000000
		!byte %00000000,%00011100,%00000000
		!byte $00
		!byte %00000000,%00000000,%00000000
		!byte %00000000,%00011000,%00000000
		!byte %00000000,%00111000,%00000000
		!byte %00000000,%01101000,%00010000
		!byte %00000000,%11011000,%00001000
		!byte %00000001,%10011000,%01000100
		!byte %00000011,%00011000,%00100100
		!byte %01111110,%00011001,%00100010
		!byte %01101100,%00011000,%10010010
		!byte %01101100,%00011000,%10010010
		!byte %01101100,%00011000,%10010010
		!byte %01101100,%00011000,%10010010
		!byte %01101100,%00011000,%10010010
		!byte %01111110,%00011001,%00100010
		!byte %00000011,%00011000,%00100100
		!byte %00000001,%10011000,%01000100
		!byte %00000000,%11011000,%00001000
		!byte %00000000,%01101000,%00010000
		!byte %00000000,%00111000,%00000000
		!byte %00000000,%00011000,%00000000
		!byte %00000000,%00000000,%00000000
		!byte $00
		!byte %00000000,%00011100,%00000000
		!byte %00000000,%00111100,%00000000
		!byte %00000000,%01111100,%00110000
		!byte %00000000,%11111100,%00111000
		!byte %00000001,%11111100,%11111100
		!byte %00000011,%11111100,%11101110
		!byte %11111111,%10111111,%11111110
		!byte %11111111,%00111111,%11110111
		!byte %11111110,%00111101,%11111111
		!byte %11111110,%00111101,%11111111
		!byte %11111110,%00111101,%11111111
		!byte %11111110,%00111101,%11111111
		!byte %11111110,%00111101,%11111111
		!byte %11111111,%00111111,%11110111
		!byte %11111111,%10111111,%11111110
		!byte %00000011,%11111100,%11101110
		!byte %00000001,%11111100,%11111100
		!byte %00000000,%11111100,%00111000
		!byte %00000000,%01111100,%00110000
		!byte %00000000,%00111100,%00000000
		!byte %00000000,%00011100,%00000000
		!byte $00

coltab_0
		!byte $02,$02,$08,$0a,$0f,$07,$01,$01
vic_data
		!byte $58,$b8,$88,$b8,$b8,$b8,$e8,$b8
		!byte $57,$b8,$87,$b8,$b7,$b8,$e7,$b8
		!byte $00,$1b,$b6,$00,$00,$ff,$08,$00
		!byte $14,$01,$01,$00,$00,$ff,$00,$00
		!byte $02,$02,$00,$00,$00,$00,$00,$0d
		!byte $0d,$0d,$0d,$00,$00,$00,$00,$00
