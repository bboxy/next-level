!cpu 6510

main		= $9c00		;move up to $c000 later on, easy, same for original data, can start @e000
hires_		= $b000
hires		= $4000
screen_		= $ac00
screen		= $6000
sprites		= $6400


;gegenläufig logo von unten nach oben und effekt von oben nach unten einfaden
;dann random die sprites einfaden indem in die spritedaten geschrieben wird
;ausfaden dann über farbe bei den rasters und screen von links nach rechts wipen? char + colram
;bei effekt nur colram setzen wie im original.
;überall wo char im screen 0 0 -> colram auch auf 1 setzen?
;ganze spalte mit festem pattern setzen, dann über screen udn colram farbe setzen? oder nur screen bei 4 pixel breit?
;dann 0-3 bg color spalten und dann echter content?

!ifdef release {
                !src "../../bitfire/loader/loader_acme.inc"
                !src "../../bitfire/macros/link_macros_acme.inc"
}

		* = screen_
!for .x,0,24 {
	!bin "clean.kla",$28,$1f40
}

		* = hires_
!bin "clean.kla",$1f40

!macro framesync {
		bit $d011
		bmi *-3
		bit $d011
		bpl *-3
}

		* = main
!ifdef release {
		+switch_to_nmi
}
		sei
		lda #$35
		sta $01
		lda #$0b
		sta $d011

		+framesync

		ldx #$00
-
		lda #$ee
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		sta screen + $000,x
		sta screen + $100,x
		sta screen + $200,x
		sta screen + $300,x
		lda sprite_data + $000,x
		sta sprites + $000,x
		lda sprite_data + $100,x
		sta sprites + $100,x
		dex
		bne -

		txa
-
.dst1		sta hires,x
		inx
		bne -
		inc .dst1 + 2
		ldy .dst1 + 2
		cpy #>(hires + $2000)
		bne -

		lda #((sprites & $3fff) / $40) + 0
		sta screen + $3f8
		lda #((sprites & $3fff) / $40) + 4
		sta screen + $3f9
		lda #((sprites & $3fff) / $40) + 1
		sta screen + $3fa
		lda #((sprites & $3fff) / $40) + 5
		sta screen + $3fb
		lda #((sprites & $3fff) / $40) + 2
		sta screen + $3fc
		lda #((sprites & $3fff) / $40) + 6
		sta screen + $3fd
		lda #((sprites & $3fff) / $40) + 3
		sta screen + $3fe
		lda #((sprites & $3fff) / $40) + 7
		sta screen + $3ff

		lda #$7f
		sta $dc0d
		lda $dc0d
		lda #$01
		sta $d019
		sta $d01a
		lda #$fb
		sta $d012
		lda #$0b
		sta $d011
		lda #<irq1
		sta $fffe
		lda #>irq1
		sta $ffff
		lda #$18
		sta $d016
		lda #$80
		sta $d018
		lda #$02
		sta $dd00
		lda #$ff
		sta $d015
		lda #$32
		sta $d001
		sta $d003
		clc
		adc #$2a
		sta $d005
		sta $d007
		adc #$2a
		sta $d009
		sta $d00b
		adc #$2a
		sta $d00d
		sta $d00f
		lda #$b1
		sta $d000
		sta $d004
		sta $d008
		sta $d00c
		lda #$a7
		sta $d002
		sta $d006
		sta $d00a
		sta $d00e
		lda #$00
		sta $d010
		lda #$00
		sta $d01c
		sta $d01b
		sta $d01d
		lda #$ff
		sta $d017
		lda #$00
		sta $d027
		sta $d028
		sta $d029
		sta $d02a
		sta $d02b
		sta $d02c
		sta $d02d
		sta $d02e
		cli

		ldx #$00
--
		ldy #$04
-
		+framesync
		dey
		bne -

		lda bgcol_tab,x
		sta .bgcol + 1
		sta $d027
		sta $d028
		sta $d029
		sta $d02a
		sta $d02b
		sta $d02c
		sta $d02d
		sta $d02e
		lda col_tab1,x
		sta .col1 + 1
		lda col_tab2,x
		sta .col2 + 1
		lda col_tab3,x
		sta .col3 + 1

		inx
		cpx #$12
		bne --

		ldx #$00
-
.src2		lda hires_,x
.dst2		sta hires,x
		inx
		bne -
		inc .src2 + 2
		inc .dst2 + 2
		ldy .dst2 + 2
		cpy #>(hires + $2000)
		bne -
		lda #$20
		sta .fade
!ifdef release {
		+setup_sync $b8/2
		jsr link_load_next_comp
		+sync
		lda #$2c
		sta .fade
		jmp $6a00
} else {
		jmp *
}

fade
.xpos		ldy #$a0
-
		jsr update_sprites
		jsr move_waves
		tya
		beq +
		lsr
		lsr
		lsr
		tax
		jsr set_column
		txa
		eor #$ff
		clc
		adc #$28
		tax
		jsr set_column
		dey
		dey
		sty .xpos + 1
+
		rts
bgcol_tab
		!byte $00,$09,$08,$0a,$0f,$07,$01,$0d,$03,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
col_tab1
		!byte $00,$09,$08,$0a,$0f,$07,$01,$01,$01,$01,$01,$01,$0d,$03,$05,$05,$05,$05,$05,$05
col_tab2
		!byte $00,$09,$08,$0a,$0f,$07,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0d,$03,$05,$05,$05
col_tab3
		!byte $00,$09,$08,$0a,$0f,$07,$01,$0d,$03,$0e,$04,$06,$00,$00,$00,$00,$00,$00,$00,$00
irq1
		pha
		dec $d019
		lda #$34
		sta $d012
		lda #$3b + $80
		sta $d011
		lda #<irq2
		sta $fffe
		lda #>irq2
		sta $ffff
		nop
		nop
		nop
		nop
		nop
		nop
.col1		lda #$00
		sta $d020
		lda #$32
		sta $d001
		sta $d003
		pla
		rti
irq2
		pha
		dec $d019
		lda #$31
		sta $d012
		lda #$3b
		sta $d011
		lda #<irq3
		sta $fffe
.col2		lda #$00
		sta $d020
		lda #>irq3
		sta $ffff
		pla
		rti
irq3
		pha
		dec $d019
		lda #$d8
		sta $d012
		lda #$3b
		sta $d011
		lda #<irq3_
		sta $fffe
		lda #>irq3_
		sta $ffff
.bgcol		lda #$00
		sta $d021
		nop
		nop
		nop
		nop
		nop
.col3		lda #$00
		sta $d020
		tya
		pha
		txa
		pha
.fade		bit fade
		pla
		tax
		pla
		tay
		pla
		rti
irq3_
		pha
		dec $d019
		lda #$fb
		sta $d012
		lda #<irq1
		sta $fffe
		lda #>irq1
		sta $ffff
		lda #$da
		sta $d001
		sta $d003
		pla
		rti

set_column
	!for .x,0,24 {
		lda colram + .x * 40,x
		sta $d800  + .x * 40,x
		lda screen_ + .x * 40,x
		sta screen  + .x * 40,x
	}
		rts
update_sprites
		lda $d000
		beq ++
		dec $d000
		dec $d004
		dec $d008
		dec $d00c
		inc $d002
		inc $d006
		inc $d00a
		inc $d00e
		bne +
		lda #$aa
		sta $d010
+
		lda $d000
		beq ++
		dec $d000
		dec $d004
		dec $d008
		dec $d00c
		inc $d002
		inc $d006
		inc $d00a
		inc $d00e
++
		rts
move_waves
		lda sprites + $1fc
		pha
		lda sprites + $1fd
		pha

		ldx #$39
-
		lda sprites + $1c0 + 0,x
		sta sprites + $1c0 + 3,x
		lda sprites + $1c0 + 1,x
		sta sprites + $1c0 + 4,x
		dex
		dex
		dex
		bpl -

		lda sprites + $1bc
		sta sprites + $1c0
		lda sprites + $1bd
		sta sprites + $1c1

		ldx #$39
-
		lda sprites + $180 + 0,x
		sta sprites + $180 + 3,x
		lda sprites + $180 + 1,x
		sta sprites + $180 + 4,x
		dex
		dex
		dex
		bpl -

		lda sprites + $17c
		sta sprites + $180
		lda sprites + $17d
		sta sprites + $181

		ldx #$39
-
		lda sprites + $140 + 0,x
		sta sprites + $140 + 3,x
		lda sprites + $140 + 1,x
		sta sprites + $140 + 4,x
		dex
		dex
		dex
		bpl -

		lda sprites + $13c
		sta sprites + $140
		lda sprites + $13d
		sta sprites + $141

		ldx #$39
-
		lda sprites + $100 + 0,x
		sta sprites + $100 + 3,x
		lda sprites + $100 + 1,x
		sta sprites + $100 + 4,x
		dex
		dex
		dex
		bpl -

		pla
		sta sprites + $101
		pla
		sta sprites + $100



		lda sprites + 1
		pha
		lda sprites + 2
		pha

		ldx #$00
-
		lda sprites + $00 + 5,x
		sta sprites + $00 + 2,x
		lda sprites + $00 + 4,x
		sta sprites + $00 + 1,x
		inx
		inx
		inx
		cpx #$3c
		bne -

		lda sprites + $42
		sta sprites + $3e
		lda sprites + $41
		sta sprites + $3d

		ldx #$00
-
		lda sprites + $40 + 5,x
		sta sprites + $40 + 2,x
		lda sprites + $40 + 4,x
		sta sprites + $40 + 1,x
		inx
		inx
		inx
		cpx #$3c
		bne -

		lda sprites + $82
		sta sprites + $7e
		lda sprites + $81
		sta sprites + $7d

		ldx #$00
-
		lda sprites + $80 + 5,x
		sta sprites + $80 + 2,x
		lda sprites + $80 + 4,x
		sta sprites + $80 + 1,x
		inx
		inx
		inx
		cpx #$3c
		bne -

		lda sprites + $c2
		sta sprites + $be
		lda sprites + $c1
		sta sprites + $bd

		ldx #$00
-
		lda sprites + $c0 + 5,x
		sta sprites + $c0 + 2,x
		lda sprites + $c0 + 4,x
		sta sprites + $c0 + 1,x
		inx
		inx
		inx
		cpx #$3c
		bne -

		pla
		sta sprites + $fe
		pla
		sta sprites + $fd


		rts
colram
!for .x,0,24 {
	!bin "clean.kla",$28,$1f40 + $28
}

sprite_data
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111100
	!byte %11111111,%11111111,%11110000
	!byte %11111111,%11111111,%11000000
	!byte %11111111,%11111111,%10000000
	!byte %11111111,%11111111,%10000000
	!byte %11111111,%11111111,%00000000
	!byte %11111111,%11111111,%00000000
	!byte %11111111,%11111111,%00000000
	!byte %11111111,%11111111,%10000000
	!byte %11111111,%11111111,%10000000
	!byte %11111111,%11111111,%11000000
	!byte %11111111,%11111111,%11110000
	!byte %11111111,%11111111,%11111100
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte $00
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111100
	!byte %11111111,%11111111,%11110000
	!byte %11111111,%11111111,%11000000
	!byte %11111111,%11111110,%00000000
	!byte %11111111,%11111000,%00000000
	!byte %11111111,%11000000,%00000000
	!byte %11111111,%10000000,%00000000
	!byte %11111111,%00000000,%00000000
	!byte %11111111,%10000000,%00000000
	!byte %11111111,%11000000,%00000000
	!byte %11111111,%11111000,%00000000
	!byte %11111111,%11111110,%00000000
	!byte %11111111,%11111111,%11000000
	!byte %11111111,%11111111,%11110000
	!byte %11111111,%11111111,%11111100
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte $00
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111100
	!byte %11111111,%11111111,%11110000
	!byte %11111111,%11111111,%11000000
	!byte %11111111,%11111111,%10000000
	!byte %11111111,%11111111,%10000000
	!byte %11111111,%11111111,%00000000
	!byte %11111111,%11111111,%00000000
	!byte %11111111,%11111111,%00000000
	!byte %11111111,%11111111,%10000000
	!byte %11111111,%11111111,%10000000
	!byte %11111111,%11111111,%11000000
	!byte %11111111,%11111111,%11110000
	!byte %11111111,%11111111,%11111100
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte $00
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111100
	!byte %11111111,%11111111,%11110000
	!byte %11111111,%11111111,%11000000
	!byte %11111111,%11111110,%00000000
	!byte %11111111,%11111000,%00000000
	!byte %11111111,%11000000,%00000000
	!byte %11111111,%10000000,%00000000
	!byte %11111111,%00000000,%00000000
	!byte %11111111,%10000000,%00000000
	!byte %11111111,%11000000,%00000000
	!byte %11111111,%11111000,%00000000
	!byte %11111111,%11111110,%00000000
	!byte %11111111,%11111111,%11000000
	!byte %11111111,%11111111,%11110000
	!byte %11111111,%11111111,%11111100
	!byte %11111111,%11111111,%11111110
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte $00
	!byte %11111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %00111111,%11111111,%11111111
	!byte %00001111,%11111111,%11111111
	!byte %00000011,%11111111,%11111111
	!byte %00000001,%11111111,%11111111
	!byte %00000001,%11111111,%11111111
	!byte %00000000,%11111111,%11111111
	!byte %00000000,%11111111,%11111111
	!byte %00000000,%11111111,%11111111
	!byte %00000001,%11111111,%11111111
	!byte %00000001,%11111111,%11111111
	!byte %00000011,%11111111,%11111111
	!byte %00001111,%11111111,%11111111
	!byte %00111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte $00
	!byte %11111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %00111111,%11111111,%11111111
	!byte %00001111,%11111111,%11111111
	!byte %00000011,%11111111,%11111111
	!byte %00000000,%01111111,%11111111
	!byte %00000000,%00011111,%11111111
	!byte %00000000,%00000011,%11111111
	!byte %00000000,%00000001,%11111111
	!byte %00000000,%00000000,%11111111
	!byte %00000000,%00000001,%11111111
	!byte %00000000,%00000011,%11111111
	!byte %00000000,%00011111,%11111111
	!byte %00000000,%01111111,%11111111
	!byte %00000011,%11111111,%11111111
	!byte %00001111,%11111111,%11111111
	!byte %00111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte $00
	!byte %11111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %00111111,%11111111,%11111111
	!byte %00001111,%11111111,%11111111
	!byte %00000011,%11111111,%11111111
	!byte %00000001,%11111111,%11111111
	!byte %00000001,%11111111,%11111111
	!byte %00000000,%11111111,%11111111
	!byte %00000000,%11111111,%11111111
	!byte %00000000,%11111111,%11111111
	!byte %00000001,%11111111,%11111111
	!byte %00000001,%11111111,%11111111
	!byte %00000011,%11111111,%11111111
	!byte %00001111,%11111111,%11111111
	!byte %00111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte $00
	!byte %11111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %00111111,%11111111,%11111111
	!byte %00001111,%11111111,%11111111
	!byte %00000011,%11111111,%11111111
	!byte %00000000,%01111111,%11111111
	!byte %00000000,%00011111,%11111111
	!byte %00000000,%00000011,%11111111
	!byte %00000000,%00000001,%11111111
	!byte %00000000,%00000000,%11111111
	!byte %00000000,%00000001,%11111111
	!byte %00000000,%00000011,%11111111
	!byte %00000000,%00011111,%11111111
	!byte %00000000,%01111111,%11111111
	!byte %00000011,%11111111,%11111111
	!byte %00001111,%11111111,%11111111
	!byte %00111111,%11111111,%11111111
	!byte %01111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte %11111111,%11111111,%11111111
	!byte $00
