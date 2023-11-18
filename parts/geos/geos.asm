!cpu 6510

src		= $20
dst		= $22
start		= $24
endl		= $25
endh		= $26
yh		= $27

xl		= $28
xh		= $29
xendl		= $2a
xendh		= $2b
y		= $2c
yend		= $2d
xlenl		= $2e
xlenh		= $2f
pixs		= $30
pixe		= $31
temp		= $32
pattern		= $33
font		= $34
src_		= $35
dst_		= $37
srcp		= $39

bitmap		= $4000
screen		= $6000
sprites		= $6400

!ifdef release {
                !src "../../bitfire/loader/loader_acme.inc"
                !src "../../bitfire/macros/link_macros_acme.inc"
} else {
		* = $1000
sidfile		!bin "../../music/JammicroV1_AnythingGEOSPRG.prg",,2
}

!ifndef release {
startmusic
		ldx #<.nmi
		lda #>.nmi

		stx $fffa
		sta $fffb
		lda #$00
		sta $dd0e
		lda $dd0d
		lda #$c7
		sta $dd04
		lda #$4c
		sta $dd05
		lda #$81
		sta $dd0d

		jsr sidfile

		lda #$ff
-		cmp $d012
		bne -

		lda #$11
		sta $dd0e
		rts
.nmi
		pha
		txa
		pha
		tya
		pha
		lda $01
		pha
		lda #$35
		sta $01
		lda $dd0d
		jsr sidfile+3
		pla
		sta $01
		pla
		tay
		pla
		tax
		pla
		rti
}

		* = $2000
!ifdef release {
	!ifndef crt {
		lda #$f2
		jsr bitfire_send_byte_
	} else {
		+setup_sync $d48
	}
}
		sei
		lda #$35
		sta $01
		jsr populate_width
		jsr vsync

		jsr startmusic

!ifndef release {
		lda #$7f
		sta $dc0d
		lda $dc0d
}
		lda #<poll
		sta $fffe
		lda #>poll
		sta $ffff

		ldx #$2f
-
		lda vic_conf,x
		sta $d000,x
		dex
		bpl -

;		lda #$00
;		sta $d020
;		lda #$08
;		sta $d016
;		lda #$80
;		sta $d018
		lda #$02
		sta $dd00
;
;		lda #<304
;		sta $d004
;		sta $d006
;		sta $d008
;		sta $d00a
;
;		lda #$e8
;		sta $d002
;		lda #$62
;		sta $d003
;		lda #200
;		sta $d005
;		sta $d007
;
;		lda #179 + 4
;		sta $d009
;		sta $d00b
;
;		lda #$fc
;		sta $d010
;
;		lda #$00
;		sta $d017
;		sta $d01b
;		sta $d01d
;		sta $d015
;		lda #$20
;		sta $d01c
;		lda #$a
;		sta $d025
;		lda #$08
;		sta $d026
;
;		lda #$06
;		sta $d027
;		lda #$06
;		sta $d028
;		lda #$0f
;		sta $d029
;		lda #$0b
;		sta $d02a
;		lda #$00
;		sta $d02b
;		lda #$02
;		sta $d02c
;
;		lda #$18
;		sta $d000
;		lda #$32
;		sta $d001

!ifdef release {
		cli
}

		lda #$00
		sta desktop_done + 1
		jsr render_desktop
		inc desktop_done + 1
		;jsr loading_bar
		jsr wait_20

		lda #<mv_disk
		ldx #>mv_disk
		jsr move_pointer

		jsr click_disk_popup

		jsr wait_20

		lda #<mv_csdb
		ldx #>mv_csdb
		jsr move_pointer

		jsr wait_20
		jsr move_cont

		ldx #$18
		jsr wait

		ldx #14
		jsr invert_icon

		jsr wait_08

		ldx #14
		jsr ok_icon

		jsr wait_08

		inc is_csdb + 1
		jsr show_csdb
		dec is_csdb + 1
		dec desktop_done + 1
		jsr render_desktop
		inc desktop_done + 1
		jsr wait_20

		lda #$ff
		sta yend
		jsr move_cont
		jsr click_disk_popup

		ldx #$60
		jsr wait

		jsr dump_bonzai
		ldx #$60
		jsr wait

		jsr move_cont
loop
		jsr click_disk_popup

		jsr wait_40

		lda #<mv_porn
		sta srcp
		lda #>mv_porn
		sta srcp + 1
		jsr move_cont

		ldx #$18
		jsr wait

		ldx #12
		jsr invert_icon

		jsr wait_08

		ldx #12
		jsr ok_icon

		jsr wait_10
		jsr show_popup

		jsr wait_20
		jsr move_cont

		jsr wait_10
		jsr remove_popup
		jsr wait_40
		jsr move_cont
		jmp loop

vic_conf
!byte $18,$32,$e8,$62,<304,200,<304,200
!byte <304,183,<304,183,$00,$00,$00,$00
!byte $fc,$3b,$00,$00,$00,$00,$08,$00
!byte $80,$01,$01,$00,$20,$00,$00,$00
!byte $00,$00,$00,$00,$00,$0a,$08,$06
!byte $06,$0f,$0b,$00,$02,$00,$00,$00

clean_up
		lda #<(screen)
		sta dst
		lda #>(screen)
		sta dst + 1
		jmp clear_screen
dump_bonzai
		lda #<mv_bonzai
		ldx #>mv_bonzai
		jsr move_pointer
		jsr wait_20
		lda $d015
		ora #$02
		sta $d015
-
		ldy #$00
		lda (srcp),y
		cmp #$80
		beq ++
		jsr move_single
		lda $d000
		sta $d002
		lda $d001
		sta $d003
		lax $d010
		lsr
		txa
		and #$fd
		bcc +
		adc #1
+
		sta $d010

		lda $d003
		sec
		sbc #$0a
		sta $d003
		lda $d002
		sec
		sbc #$0a
		sta $d002
		bcs +
		lda $d010
		and #$fd
		sta $d010
+

		jmp -
++
		inc srcp
		bne +
		inc srcp + 1
+
		jsr wait_20
		lda $d015
		eor #$02
		sta $d015
		ldx #$37
		lda #$00
-
		sta 6*$140 + 192 + bitmap,x
		sta 7*$140 + 192 + bitmap,x
		sta 8*$140 + 192 + bitmap,x
		sta 9*$140 + 192 + bitmap,x
		sta 10*$140 + 192 + bitmap,x
		dex
		bpl -
		rts

click_disk_popup
		jsr wait_08

		jsr invert_disk

		jsr wait_08

		jsr ok_disk
		ldx #$08
		jsr wait

		jsr show_popup

		ldx #$10
		jsr wait

		lda #<mv_ok
		ldx #>mv_ok
		jsr move_pointer

		jsr wait_10
		jmp remove_popup
ok_icon
		lda #$00
		top
invert_icon
		lda #$ff
		sta pattern
		lda icon_pos,x
		sta dst
		lda icon_pos + 1,x
		sta dst + 1
		lda icon_data,x
		sta src
		lda icon_data + 1,x
		sta src + 1
		jmp copy_icon
ok_disk
		lda #$00
		top
invert_disk
		lda #$ff
		sta pattern
		lda #<(3*$140 +  280 + bitmap)
		sta dst
		lda #>(3*$140 +  280 + bitmap)
		sta dst + 1
		lda #<disk_icon
		sta src
		lda #>disk_icon
		sta src + 1
		jmp copy_icon
render_desktop
		lda #$00
		sta xl
		lda #$00
		sta xh

		lda #<319
		sta xendl
		lda #>319
		sta xendh

		lda #$00
		sta y
		lda #199
		sta yend
-
.pattern
		lda #$aa
		sta pattern
		jsr draw_line_horizontal
		lda .pattern + 1
		eor #$ff
		sta .pattern + 1
		lda y
		inc y
		cmp yend
		bne -

		lda #$01
		sta $d015

		jsr wait_40

		lda #$3d
		sta $d015

		lda #$00
		sta xl
		lda #$00
		sta xh

		lda #201
		sta xendl
		lda #$00
		sta xendh

		lda #$00
		sta y
		lda #12
		sta yend

		lda #$00
		sta pattern

		jsr draw_box
		jsr draw_outline

		lda #26
		sta xl
		lda #$00
		sta xh
		jsr draw_dotted_line
		lda #48
		sta xl
		jsr draw_dotted_line
		lda #77
		sta xl
		jsr draw_dotted_line
		lda #101
		sta xl
		jsr draw_dotted_line
		lda #133
		sta xl
		jsr draw_dotted_line
		lda #161
		sta xl
		jsr draw_dotted_line

		lda #03
		sta y

		lda #4
		sta xl
		lda #<geos
		ldx #>geos
		jsr draw_font7

		lda #33
		sta xl
		;lda #<file
		;ldx #>file
		jsr draw_font7 + 4

		lda #53
		sta xl
		;lda #<view
		;ldx #>view
		jsr draw_font7 + 4

		lda #82
		sta xl
		;lda #<disk
		;ldx #>disk
		jsr draw_font7 + 4

		lda #106
		sta xl
		;lda #<select
		;ldx #>select
		jsr draw_font7 + 4

		lda #138
		sta xl
		;lda #<page
		;ldx #>page
		jsr draw_font7 + 4

		lda #166
		sta xl
		;lda #<options
		;ldx #>options
		jsr draw_font7 + 4

		lda #$00
		sta pattern

		lda #$00
		sta y

		lda #220
		sta xl
		lda #$00
		sta xh

		lda #$3f
		sta xendl
		lda #$01
		sta xendh
		jsr draw_box
		jsr draw_outline

		lda #03
		sta y

		lda #227
		sta xl
		lda #<date
		ldx #>date
		jsr draw_font7

		lda #$00
		sta pattern

		lda #16
		sta y

		lda #143
		sta yend

		lda #8
		sta xl
		lda #$00
		sta xh

		lda #<264
		sta xendl
		lda #>264
		sta xendh
		jsr draw_box
		jsr draw_outline

		lda #18
		sta y
		jsr draw_dotted

		lda #40
		sta y
		jsr draw_line_horizontal
		lda #141
		sta y
		jsr draw_line_horizontal
		lda #143
		sta y
		jsr draw_line_horizontal

		lda #23
		sta xl
		lda #139
		sta y
		jsr draw_line_horizontal
		lda #$08
		sta xl
		lda #124
		sta y
		lda #23
		sta xendl
		lda #$00
		sta xendh
		jsr draw_line_horizontal

		lda #23
		sta xl
		lda #139
		sta yend
		jsr draw_line_vertical

		lda #$08
		sta xl
-
		jsr draw_dot
		inc xl
		lda y
		inc y
		cmp yend
		bne -

		lda #116
		sta xl
		lda #155
		sta xendl
		lda #17
		sta y
		lda #27
		sta yend

		lda #$00
		sta pattern
		jsr draw_box

		lda #121
		sta xl
		lda #18
		sta y
		lda #<system
		ldx #>system
		jsr draw_font7

		lda #240
		sta xl
		lda #255
		sta xendl
		lda #17
		sta y
		lda #27
		sta yend
		lda #$ff
		sta pattern
		jsr draw_box

		inc xl
		dec xendl
		inc y
		dec yend

		lda #$00
		sta pattern
		jsr draw_box

		lda #245
		sta xl
		lda #250
		sta xendl
		lda #21
		sta y
		lda #23
		sta yend
		lda #$ff
		sta pattern
		jsr draw_box

		jsr draw_icons

		lda #$ff
		sta pattern
		lda #30
		sta y

		lda #17
		sta xl
		lda #<_45_files
		ldx #>_45_files
		jsr draw_font7

		lda #62
		sta xl
		;lda #<_0_selected
		;ldx #>_0_selected
		jsr draw_font7 + 4

		lda #114
		sta xl
		;lda #<_136_kbytes
		;ldx #>_136_kbytes
		jsr draw_font7 + 4

		lda #193
		sta xl
		;lda #<_29_kbytes
		;ldx #>_29_kbytes
		jsr draw_font7 + 4

		lda #136
		sta xl
		lda #0
		sta xh
		lda #120
		sta  y
		;lda #<_1
		;ldx #>_1
		jsr draw_font7 + 4

		jsr ok_disk

		lda #<276
		sta xl
		lda #>276
		sta xh

		lda #48
		sta y

		lda #<307
		sta xendl
		lda #>307
		sta xendh
		lda #53
		sta yend

		lda #$ff
		sta pattern
		jsr draw_box

		lda #<282
		sta xl
		lda #>282
		sta xh
		lda #<demo
		sta src
		lda #>demo
		sta src + 1
		lda #$00
		jmp draw_font5 + 2

vsync
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		rts
wait_08
		ldx #$08
		top
wait_10
		ldx #$10
		top
wait_20
		ldx #$20
		top
wait_40
		ldx #$40
wait
-
		jsr vsync
		dex
		bpl -
		rts

draw_icons
		lda #$00
		sta xh
		sta .icon_num + 1
-
.icon_num	ldx #$00

		txa
		asl
		tax
		lda icon_pos + 0,x
		sta dst
		lda icon_pos + 1,x
		sta dst + 1
		lda icon_data + 0,x
		sta src
		lda icon_data + 1,x
		sta src + 1

		lda #$00
		sta pattern
		jsr copy_icon

		ldx .icon_num + 1
		lda icon_xl,x
		sta xl
		lda icon_y,x
		sta y
		txa
		asl
		tax
		lda icon_text + 0,x
		sta src
		lda icon_text + 1,x
		sta src + 1
		jsr draw_font5

		ldy .icon_num + 1
		ldx icon_wait,y
		jsr wait

		iny
		sty .icon_num + 1
		cpy #$08
		bne -
		rts

icon_wait
		!byte 5,4,8,3,6,4,3,5
icon_xl
		!byte 199,155,100,39
		!byte 202,155,98,44
icon_y
		!byte 112,112,112,112
		!byte 72,72,72,72
icon_text
		!word bob_spycam
		!word acme
		!word dali
		!word bitfire
		!word demo_plans
		!word dasm
		!word porn
		!word csdb
icon_data
		!word bob_spycam_icon
		!word acme_icon
		!word dali_icon
		!word bitfire_icon
		!word demo_plans_icon
		!word dasm_icon
		!word porn_icon
		!word csdb_icon
icon_pos
		!word (11*$140 + 208 + bitmap)
		!word (11*$140 + 152 + bitmap)
		!word (11*$140 +  96 + bitmap)
		!word (11*$140 +  40 + bitmap)
		!word (6*$140 + 208 + bitmap)
		!word (6*$140 + 152 + bitmap)
		!word (6*$140 +  96 + bitmap)
		!word (6*$140 +  40 + bitmap)
show_popup
		jsr swap_pop
		lda #$0b
		jmp set_pop_shadow
set_pop_shadow
		ldx #$13
		sta screen + 09*40 + 11,x
		sta screen + 10*40 + 11,x
		sta screen + 11*40 + 11,x
		sta screen + 12*40 + 11,x
		sta screen + 13*40 + 11,x
		sta screen + 14*40 + 11,x
-
		sta screen + 15*40 + 11,x
		dex
		bpl -
		rts

remove_popup
		lda #$fb
		ldx #$05
-
		sta screen + 12*40 + $17,x
		sta screen + 13*40 + $17,x
		dex
		bpl -
		jsr wait_08
		lda #$bf
		ldx #$05
-
		sta screen + 12*40 + $17,x
		sta screen + 13*40 + $17,x
		dex
		bpl -
		ldx #$04
		jsr wait
		jsr set_pop_shadow
		jmp swap_pop

draw_dotted_line
		lda #$ff
		sta pattern
		lda y
		pha
		jsr draw_dot
		inc y
		inc y
		jsr draw_dot
		inc y
		inc y
		jsr draw_dot
		inc y
		inc y
		jsr draw_dot
		inc y
		inc y
		jsr draw_dot
		inc y
		inc y
		jsr draw_dot
		pla
		sta y
		rts

draw_dotted
		lda #$ff
		sta pattern
		lda y
		pha
		jsr draw_line_horizontal
		inc y
		inc y
		jsr draw_line_horizontal
		inc y
		inc y
		jsr draw_line_horizontal
		inc y
		inc y
		jsr draw_line_horizontal
		inc y
		inc y
		jsr draw_line_horizontal
		inc y
		inc y
		jsr draw_line_horizontal
		pla
		sta y
		rts

draw_outline
		lda #$ff
		sta pattern
		jsr draw_line_horizontal

		jsr draw_line_vertical

		lda xl
		pha
		lda xh
		pha
		lda y
		pha
		lda yend
		sta y

		jsr draw_line_horizontal

		lda xendl
		sta xl
		lda xendh
		sta xh
		pla
		sta y
		jsr draw_line_vertical
		pla
		sta xh
		pla
		sta xl
		rts



draw_dot
		lda y
		lsr
		lsr
		lsr
		tax
		lda xl
		and #$f8
		clc
		adc bitmap_tabl,x
		sta dst + 0

		lda xh
		adc bitmap_tabh,x
		sta dst + 1

		lda y
		and #$07
		tay
		lda xl + 0
		eor #$07
		and #$07
		tax
		lda pixtab_,x
		and (dst),y
		sta (dst),y
		lda pattern
		and pixtab,x
		ora (dst),y
		sta (dst),y
		rts

draw_line_vertical
		lda y
		pha
-
		jsr draw_dot
		lda y
		inc y
		cmp yend
		bne -
		pla
		sta y
		rts

show_csdb
		jsr show_webpage
		jsr wait_20
		lda #<mv_vote
		ldx #>mv_vote
		jsr move_pointer
		jsr wait_20
		jsr select_vote
		jsr init_webpage

		lda #<result_bitmap
		sta src
		lda #>result_bitmap
		sta src + 1
		lda #<bitmap
		sta dst
		lda #>bitmap
		sta dst + 1

		ldx #$18
--
		ldy #$00
-
		lda (src),y
		sta (dst),y
		iny
		cpy #$f0
		bne -

		lda src
		clc
		adc #$f0
		sta src
		lda src + 1
		adc #0
		sta src + 1
		lda dst
		clc
		adc #$40
		sta dst
		lda dst + 1
		adc #1
		sta dst + 1
		dex
		bpl --

		lda #<result_screen
		sta src_
		lda #>result_screen
		sta src_ + 1
		lda #<screen
		sta dst_
		lda #>screen
		sta dst_ + 1

		jsr fade_bitmap

		ldx #$60
		jsr wait
		lda #$ff
		sta yend
		jsr move_cont
		jsr wait_10
		lda #$fb
		sta screen + $26
		jsr wait_08
		lda #$bf
		sta screen + $26

clean_desktop
		jsr clean_up

		lda #<bitmap
		sta dst
		lda #>bitmap
		sta dst + 1
		ldy #$00
		ldx #$1f
		lda #$00
-
		sta (dst),y
		dey
		bne -
		inc src + 1
		inc dst + 1
		dex
		bpl -
		lda #$bf
		ldx #$00
-
		sta screen,x
		sta screen+$100,x
		sta screen+$200,x
		sta screen+$2e8,x
		dex
		bne -
		rts
		;show_commit
		;close_browser -> back to grey on whole screen ($ff), clear bitmap, set screen to $bf
		;XXX TODO needs move until y == val, easy
select_vote
		jsr show_vote
		lda #$a4
		sta yend
		jsr move_cont
		lda #<screen + 14 * 40 + 31
		sta dst
		lda #>screen + 14 * 40 + 31
		sta dst + 1
		jsr flip_color

		lda #$ac
		sta yend
		jsr move_cont
		jsr color_down
		lda #$b4
		sta yend
		jsr move_cont
		jsr color_down
		lda #$bc
		sta yend
		jsr move_cont
		jsr color_down
		lda #$c4
		sta yend
		jsr move_cont
		jsr color_down
		lda #$cc
		sta yend
		jsr move_cont
		jsr color_down
		lda #$d4
		sta yend
		jsr move_cont
		jsr color_down
		lda #$dc
		sta yend
		jsr move_cont
		jsr color_down
		lda #$e4
		sta yend
		jsr move_cont
		jsr color_down
		jsr move_single
		jsr move_single
		jsr move_single
-
		jsr move_single
		lda #$e2
		cmp $d001
		bcc -
		jsr color_up
-
		jsr move_single
		lda #$da
		cmp $d001
		bcc -
		jsr color_up
-
		jsr move_single
		lda #$d2
		cmp $d001
		bcc -
		jsr color_up
-
		jsr move_single
		lda #$ca
		cmp $d001
		bcc -
		jsr color_up
-
		jsr move_single
		lda #$c2
		cmp $d001
		bcc -
		jsr color_up
-
		jsr move_single
		lda #$ba
		cmp $d001
		bcc -
		jsr color_up
-
		jsr move_single
		lda #$b2
		cmp $d001
		bcc -
		jsr color_up
-
		jsr move_cont
		jsr wait_20
		jsr remove_vote
		jsr wait_20
		jsr move_cont
		jmp wait_10

color_up
		jsr reset_color
		lda dst
		sec
		sbc #$28
		sta dst
		bcs +
		dec dst + 1
+
		jmp flip_color
color_down
		jsr reset_color
		lda dst
		clc
		adc #$28
		sta dst
		bcc +
		inc dst + 1
+
		jmp flip_color
reset_color
		ldy #$05
-
		lda (dst),y
		ldx #$f0
		sbx #$10
		bne +
		eor #$e0
+
		ldx #$0f
		sbx #$01
		bne +
		eor #$0e
+
		ldx #$f0
		sbx #$c0
		bne +
		eor #$70
+
		ldx #$0f
		sbx #$0c
		bne +
		eor #$07
+
		sta (dst),y
		dey
		bpl -
		rts
flip_color
		ldy #$05
-
		lda (dst),y
		ldx #$f0
		sbx #$f0
		bne +
		eor #$e0
+
		ldx #$0f
		sbx #$0f
		bne +
		eor #$0e
+
		ldx #$f0
		sbx #$b0
		bne +
		eor #$70
+
		ldx #$0f
		sbx #$0b
		bne +
		eor #$07
+
		sta (dst),y
		dey
		bpl -
		rts

init_webpage
		lda #$01
		sta $d015

		jsr vsync
		ldy #$00
-
		lda csdb_bitmap,y
		sta bitmap,y
		lda csdb_bitmap + $40,y
		sta bitmap + $40,y
		dey
		bne -
		ldy #$27
-
		lda csdb_screen,y
		sta screen,y
		dey
		bpl -
		lda #<(screen + 40)
		sta dst
		lda #>(screen + 40)
		sta dst + 1
		jmp clear_screen

clear_screen
--
		jsr vsync
		lda #$ff
		ldy #$27
-
		sta (dst),y
		dey
		bpl -
		lda dst
		clc
		adc #$28
		sta dst
		bcc +
		inc dst + 1
+
		cmp #$e8
		bne --
		rts
show_webpage
		jsr init_webpage

		lda #<csdb_bitmap
		sta src
		lda #>csdb_bitmap
		sta src + 1
		lda #<bitmap
		sta dst
		lda #>bitmap
		sta dst + 1

		lda #<csdb_screen
		sta src_
		lda #>csdb_screen
		sta src_ + 1
		lda #<screen
		sta dst_
		lda #>screen
		sta dst_ + 1

copy_bitmap
		ldy #$00
		ldx #$1f
-
		lda (src),y
		sta (dst),y
		dey
		bne -
		inc src + 1
		inc dst + 1
		dex
		bpl -

fade_bitmap
--
		jsr vsync

		ldy #$27
-
		lda (src_),y
		sta (dst_),y
		dey
		bpl -
		lda src_
		clc
		adc #$28
		sta src_
		bcc +
		inc src_ + 1
+
		lda dst_
		clc
		adc #$28
		sta dst_
		bcc +
		inc dst_ + 1
+
		cmp #$e8
		bne --
		rts

remove_vote
		lda #<csdb_no_vote_bmp
		sta src
		lda #>csdb_no_vote_bmp
		sta src + 1

		lda #<csdb_no_vote_scr
		sta src_
		lda #>csdb_no_vote_scr
		sta src_ + 1
		jsr vote_cp
copy_awful
		ldy #$1e
-
		lda csdb_vote_bmp + $31,y
		cpy #$08
		bcs +
		ora #$80
+
		sta bitmap + 13 * $140 + 248,y
		dey
		bpl -
		rts

show_vote
		lda #<csdb_vote_bmp
		sta src
		lda #>csdb_vote_bmp
		sta src + 1

		lda #<csdb_vote_scr
		sta src_
		lda #>csdb_vote_scr
		sta src_ + 1
vote_cp
		lda #<(bitmap + 14 * $140 + 248)
		sta dst
		lda #>(bitmap + 14 * $140 + 248)
		sta dst + 1

		lda #<(screen + 14 * 40 + 31)
		sta dst_
		lda #>(screen + 14 * 40 + 31)
		sta dst_ + 1
		lda #11
		sta temp
--
		jsr vsync

		ldy #$2f
-
		lda (src),y
		sta (dst),y
		dey
		bpl -

		ldy #$05
-
		lda (src_),y
		sta (dst_),y
		dey
		bpl -
		lda src
		clc
		adc #$30
		sta src
		bcc +
		inc src + 1
+
		lda dst_
		clc
		adc #$28
		sta dst_
		bcc +
		inc dst_ + 1
+
		lda dst
		clc
		adc #$40
		sta dst
		lda dst + 1
		adc #1
		sta dst + 1

		lda src_
		clc
		adc #6
		sta src_
		bcc +
		inc src_ + 1
+
		dec temp
		bne --
		rts

swap_pop
		lda #<(bitmap + 8 * $140 + 80)
		sta dst + 0
		lda #>(bitmap + 8 * $140 + 80)
		sta dst + 1
		lda #<geos_popup
		sta .src1 + 1
		sta .src2 + 1
		lda #>geos_popup
		sta .src1 + 2
		sta .src2 + 2
		lda #$06
		sta temp
--
		ldy #$00
-
.src1		lax geos_popup + 0 * $a0,y
		lda (dst),y
.src2		sta geos_popup + 0 * $a0,y
		txa
		sta (dst),y
		iny
		cpy #$a0
		bne -
		lda dst + 0
		clc
		adc #$40
		sta dst + 0
		lda dst + 1
		adc #1
		sta dst + 1
		lda .src1 + 1
		clc
		adc #$a0
		sta .src1 + 1
		sta .src2 + 1
		bcc +
		inc .src1 + 2
		inc .src2 + 2
+
		dec temp
		bpl --
		rts

copy_line
		pha
		sta endh
		sty endl
		ldy #$00
		sty yh
.loop
		lda (src),y
		sta (dst),y
		clc
		tya
		adc #8
		tay
		bne +
		inc yh
		inc src + 1
		inc dst + 1
+
		cpy endl
		bne .loop
		lda yh
		cmp endh
		bne .loop
		inc src + 0
		bne +
		inc src + 1
+
		inc dst + 0
		bne +
		inc dst + 1
+
		lda src + 0
		and #$07
		bne +
		lda src + 0
		clc
		adc #$38
		sta src + 0
		lda src + 1
		adc #1
		sta src + 1
+
		lda dst + 0
		and #$07
		bne +
		lda dst + 0
		clc
		adc #$38
		sta dst + 0
		lda dst + 1
		adc #1
		sta dst + 1
+

		lda src + 1
		sec
		sbc yh
		sta src + 1
		lda dst + 1
		sec
		sbc yh
		sta dst + 1
		pla
		dex
		bne copy_line
		rts

copy_icon
		ldx #2
--
		ldy #$17
-
		lda (src),y
		eor pattern
		sta (dst),y
		dey
		bpl -
		lda src
		clc
		adc #$18
		sta src
		bcc +
		inc src + 1
+
		lda dst
		clc
		adc #$40
		sta dst
		lda dst + 1
		adc #1
		sta dst + 1
		dex
		bpl --
.df7_end
		rts
draw_font7
		sta src
		stx src + 1
		lda #$ff
		sta pattern
.df7_next
		ldy #$00
		sty font + 1
		lax (src),y
		inc src
		bne +
		inc src + 1
+
		txa
		beq .df7_end
		jsr convert_char
		sta font
		tax
		asl
		rol font + 1
		asl
		rol font + 1
		asl
		rol font + 1
		adc font
		sta font
		lda font + 1
		adc #$00
		sta font + 1

		lda font
		adc #<font7
		sta font
		lda font + 1
		adc #>font7
		sta font + 1

		lda y
		pha
		lda font7_width,x
		sta .char7
--
.char7 = * + 1
		ldx #$00
		lda xl
		pha
		lda xh
		pha
		lda (font),y
-
		asl
		bcc +
		pha
		txa
		pha
		tya
		pha
		jsr draw_dot
		pla
		tay
		pla
		tax
		pla
+
		inc xl
		bne +
		inc xh
+
		dex
		bpl -
		inc y
		pla
		sta xh
		pla
		sta xl
		iny
		cpy #$09
		bne --
		inc .char7
		inc .char7
		lda xl
		clc
		adc .char7
		sta xl
		lda xh
		adc #$00
		sta xh
		pla
		sta y
		jmp .df7_next
convert_char
		cmp #'.'
		bne +
		lda #$4d
		bne ++
+
		cmp #','
		bne +
		lda #$4a
		bne ++
+
		cmp #'/'
		bne +
		lda #$4b
		bne ++
+
		cmp #':'
		bne +
		lda #$4c
		bne ++
+
		cmp #$30
		bcc +
		cmp #$3a
		bcs +
		adc #$10
		bne ++
+
		cmp #$40
		bcc +
		sec
		sbc #$20
+
++
.df5_end
		rts
draw_font5
		lda #$ff
		sta pattern
.df5_next
		ldy #$00
		sty font + 1
		lda (src),y
		beq .df5_end
		jsr convert_char
		sta font
		tax
		asl
		rol font + 1
		adc font
		sta font
		lda font + 1
		adc font + 1
		asl font
		rol font + 1
		lda font
		adc #<font5
		sta font
		lda font + 1
		adc #>font5
		sta font + 1

		lda y
		pha
		lda font5_width,x
		sta .char5
--
.char5 = * + 1
		ldx #$00
		lda xl
		pha
		lda xh
		pha
		lda (font),y
-
		asl
		bcc +
		pha
		txa
		pha
		tya
		pha
		jsr draw_dot
		pla
		tay
		pla
		tax
		pla
+
		inc xl
		bne +
		inc xh
+
		dex
		bpl -
		inc y
		pla
		sta xh
		pla
		sta xl
		iny
		cpy #$06
		bne --
		inc .char5
		lda xl
		sec
		adc .char5
		sta xl
		bne +
		inc xh
+
		pla
		sta y
		inc src
		bne +
		inc src + 1
+
		jmp .df5_next

geos
		!scr "geos"
		!byte 0
file
		!scr "file"
		!byte 0
view
		!scr "view"
		!byte 0
disk
		!scr "disk"
		!byte 0
select
		!scr "select"
		!byte 0
page
		!scr "page"
		!byte 0
options
		!scr "options"
		!byte 0
_45_files
		!scr "45 files,"
		!byte 0
_0_selected
		!scr "0 selected"
		!byte 0
_136_kbytes
		!scr "136 Kbytes used"
		!byte 0
_29_kbytes
		!scr "29 Kbytes free"
		!byte 0
_1
		!byte $31, $00
system
		!scr "System"
		!byte 0

loading
		!scr "Loading..."
		!byte 0

csdb
		!scr "CSDb"
		!byte $00
porn
		!scr "PORN"
		!byte $00
dasm
		!scr "DASM"
		!byte $00
demo_plans
		!scr "Demo plans"
		!byte $00
bitfire
		!scr "BITFIRE"
		!byte $00
dali
		!scr "DALI"
		!byte $00
acme
		!scr "ACME"
		!byte $00
bob_spycam
		!scr "Bob spycam"
		!byte $00

date
		!scr "06/03/23 10:23 PM"
		!byte $00
demo
		!scr "DEMO:"
		!byte $00

csdb_icon
	!bin "geos_desktop.prg",24,6*$140 +  40 + 2
	!bin "geos_desktop.prg",24,7*$140 +  40 + 2
	!bin "geos_desktop.prg",24,8*$140 +  40 + 2
porn_icon
	!bin "geos_desktop.prg",24,6*$140 +  96 + 2
	!bin "geos_desktop.prg",24,7*$140 +  96 + 2
	!bin "geos_desktop.prg",24,8*$140 +  96 + 2
dasm_icon
	!bin "geos_desktop.prg",24,6*$140 + 152 + 2
	!bin "geos_desktop.prg",24,7*$140 + 152 + 2
	!bin "geos_desktop.prg",24,8*$140 + 152 + 2
demo_plans_icon
	!bin "geos_desktop.prg",24,6*$140 + 208 + 2
	!bin "geos_desktop.prg",24,7*$140 + 208 + 2
	!bin "geos_desktop.prg",24,8*$140 + 208 + 2
bitfire_icon
	!bin "geos_desktop.prg",24,11*$140 +  40 + 2
	!bin "geos_desktop.prg",24,12*$140 +  40 + 2
	!bin "geos_desktop.prg",24,13*$140 +  40 + 2
dali_icon
	!bin "geos_desktop.prg",24,11*$140 +  96 + 2
	!bin "geos_desktop.prg",24,12*$140 +  96 + 2
	!bin "geos_desktop.prg",24,13*$140 +  96 + 2
acme_icon
	!bin "geos_desktop.prg",24,11*$140 + 152 + 2
	!bin "geos_desktop.prg",24,12*$140 + 152 + 2
	!bin "geos_desktop.prg",24,13*$140 + 152 + 2
bob_spycam_icon
	!bin "geos_desktop.prg",24,11*$140 + 208 + 2
	!bin "geos_desktop.prg",24,12*$140 + 208 + 2
	!bin "geos_desktop.prg",24,13*$140 + 208 + 2
disk_icon
	!bin "geos_desktop.prg",24, 3*$140 + 280 + 2
	!bin "geos_desktop.prg",24, 4*$140 + 280 + 2
	!bin "geos_desktop.prg",24, 5*$140 + 280 + 2
blank_icon
	!byte 24*3,0
geos_popup
	!bin "geos_popup.prg",160, 0*$140 + 2
	!bin "geos_popup.prg",8, 1*$140 + 2
	!fill 8,0
	!bin "geos_popup.prg",144, 1*$140 + 16 + 2
	!bin "geos_popup.prg",8, 2*$140 + 2
	!fill 8,0
	!bin "geos_popup.prg",144, 2*$140 + 16 + 2
	!bin "geos_popup.prg",8, 3*$140 + 2
	!fill 144,0
	!bin "geos_popup.prg",8, 3*$140 + 152 + 2
	!bin "geos_popup.prg",8, 4*$140 + 2
	!fill 96,0
	!bin "geos_popup.prg",56, 4*$140 + 104 + 2
	!bin "geos_popup.prg",8, 5*$140 + 2
	!fill 96,0
	!bin "geos_popup.prg",56, 5*$140 + 104 + 2
	!bin "geos_popup.prg",160, 6*$140 + 2

populate_width
	ldy #$00
	sty temp
	lda #<font5
	sta src + 0
	lda #>font5
	sta src + 1
---
	ldy #$06
--
	dey
	bmi +
	lda (src),y
	beq --
	ldx #8
-
	dex
	lsr
	bcc -
	txa
	ldx temp
	cmp font5_width,x
	bcc --
	sta font5_width,x
	jmp --
+
	lda src + 0
	clc
	adc #6
	sta src + 0
	bcc +
	inc src + 1
+
	inc temp
	lda temp
	cmp #$40
	bne ---
	lda #0		;space width
	sta font5_width + $20



	ldy #$00
	sty temp
	lda #<font7
	sta src + 0
	lda #>font7
	sta src + 1
---
	ldy #$09
--
	dey
	bmi +
	lda (src),y
	beq --
	ldx #8
-
	dex
	lsr
	bcc -
	txa
	ldx temp
	cmp font7_width,x
	bcc --
	sta font7_width,x
	jmp --
+
	lda src + 0
	clc
	adc #9
	sta src + 0
	bcc +
	inc src + 1
+
	inc temp
	lda temp
	cmp #$50
	bne ---
	lda #3		;space width
	sta font7_width + $20
	rts



font5
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %01100000
	!byte %10100000
	!byte %10100000
	!byte %01100000
	!byte %00000000

	!byte %10000000
	!byte %11000000
	!byte %10100000
	!byte %10100000
	!byte %11000000
	!byte %00000000

	!byte %00000000
	!byte %01100000
	!byte %10000000
	!byte %10000000
	!byte %01100000
	!byte %00000000

	!byte %00100000
	!byte %01100000
	!byte %10100000
	!byte %10100000
	!byte %01100000
	!byte %00000000

	!byte %00000000
	!byte %01000000
	!byte %10100000
	!byte %11000000
	!byte %01100000
	!byte %00000000

	!byte %01000000
	!byte %10000000
	!byte %11000000
	!byte %10000000
	!byte %10000000
	!byte %00000000

	!byte %00000000
	!byte %01100000
	!byte %10100000
	!byte %10100000
	!byte %00100000
	!byte %11000000

	!byte %10000000
	!byte %11000000
	!byte %10100000
	!byte %10100000
	!byte %10100000
	!byte %00000000

	!byte %10000000
	!byte %00000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %00000000

	!byte %01000000
	!byte %00000000
	!byte %01000000
	!byte %01000000
	!byte %01000000
	!byte %10000000

	!byte %10000000
	!byte %10000000
	!byte %10100000
	!byte %11000000
	!byte %10100000
	!byte %00000000

	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %00000000

	!byte %00000000
	!byte %11110000
	!byte %10101000
	!byte %10101000
	!byte %10101000
	!byte %00000000

	!byte %00000000
	!byte %11000000
	!byte %10100000
	!byte %10100000
	!byte %10100000
	!byte %00000000

	!byte %00000000
	!byte %01000000
	!byte %10100000
	!byte %10100000
	!byte %01000000
	!byte %00000000

	!byte %00000000
	!byte %11000000
	!byte %10100000
	!byte %10100000
	!byte %11000000
	!byte %10000000

	!byte %00000000
	!byte %01100000
	!byte %10100000
	!byte %10100000
	!byte %01100000
	!byte %00100000

	!byte %00000000
	!byte %01000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %00000000

	!byte %00000000
	!byte %01100000
	!byte %10000000
	!byte %01100000
	!byte %11000000
	!byte %00000000

	!byte %10000000
	!byte %11000000
	!byte %10000000
	!byte %10000000
	!byte %01000000
	!byte %00000000

	!byte %00000000
	!byte %10100000
	!byte %10100000
	!byte %10100000
	!byte %01000000
	!byte %00000000

	!byte %00000000
	!byte %10100000
	!byte %10100000
	!byte %01000000
	!byte %01000000
	!byte %00000000

	!byte %00000000
	!byte %10101000
	!byte %10101000
	!byte %10101000
	!byte %01010000
	!byte %00000000

	!byte %00000000
	!byte %10100000
	!byte %10100000
	!byte %01000000
	!byte %10100000
	!byte %00000000

	!byte %00000000
	!byte %10100000
	!byte %10100000
	!byte %10100000
	!byte %01100000
	!byte %01000000

	!byte %00000000
	!byte %11100000
	!byte %00100000
	!byte %11000000
	!byte %11100000
	!byte %00000000
;27
	!byte %00000000
	!byte %10000000
	!byte %00000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
;31
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %01100000
	!byte %10010000
	!byte %11110000
	!byte %10010000
	!byte %10010000
	!byte %00000000

	!byte %11100000
	!byte %10010000
	!byte %11100000
	!byte %10010000
	!byte %11100000
	!byte %00000000

	!byte %01100000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %01100000
	!byte %00000000

	!byte %11100000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %11100000
	!byte %00000000

	!byte %11100000
	!byte %10000000
	!byte %11100000
	!byte %10000000
	!byte %11100000
	!byte %00000000

	!byte %11100000
	!byte %10000000
	!byte %11000000
	!byte %10000000
	!byte %10000000
	!byte %00000000

	!byte %01110000
	!byte %10000000
	!byte %10010000
	!byte %10010000
	!byte %01100000
	!byte %00000000

	!byte %10010000
	!byte %10010000
	!byte %11110000
	!byte %10010000
	!byte %10010000
	!byte %00000000

	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %00000000

	!byte %00100000
	!byte %00100000
	!byte %00100000
	!byte %00100000
	!byte %00100000
	!byte %11000000

	!byte %10010000
	!byte %10100000
	!byte %11000000
	!byte %10100000
	!byte %10010000
	!byte %00000000

	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %11100000
	!byte %00000000

	!byte %10001000
	!byte %11011000
	!byte %10101000
	!byte %10001000
	!byte %10001000
	!byte %00000000

	!byte %10010000
	!byte %11010000
	!byte %11010000
	!byte %10110000
	!byte %10010000
	!byte %00000000

	!byte %01100000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %01100000
	!byte %00000000

	!byte %11100000
	!byte %10010000
	!byte %10010000
	!byte %11100000
	!byte %10000000
	!byte %00000000

	!byte %01100000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %01110000
	!byte %00000000

	!byte %11100000
	!byte %10010000
	!byte %10010000
	!byte %11100000
	!byte %10010000
	!byte %00000000

	!byte %01100000
	!byte %10000000
	!byte %01000000
	!byte %00100000
	!byte %11000000
	!byte %00000000

	!byte %11100000
	!byte %01000000
	!byte %01000000
	!byte %01000000
	!byte %01000000
	!byte %00000000

	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %01100000

	!byte %10100000
	!byte %10100000
	!byte %10100000
	!byte %01000000
	!byte %01000000
	!byte %00000000

	!byte %10001000
	!byte %10001000
	!byte %10101000
	!byte %11011000
	!byte %10001000
	!byte %00000000

	!byte %10100000
	!byte %10100000
	!byte %01000000
	!byte %10100000
	!byte %10100000
	!byte %00000000

	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %01110000
	!byte %00100000
	!byte %11000000

	!byte %11110000
	!byte %00100000
	!byte %01000000
	!byte %10000000
	!byte %11110000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %10000000
	!byte %00000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %10000000
	!byte %00000000

font7
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %01110000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %01010000
	!byte %00000000
	!byte %00000000

	!byte %10000000
	!byte %10000000
	!byte %11100000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %11100000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %01100000
	!byte %10010000
	!byte %10000000
	!byte %10000000
	!byte %01110000
	!byte %00000000
	!byte %00000000

	!byte %00010000
	!byte %00010000
	!byte %01110000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %01110000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %01100000
	!byte %10010000
	!byte %11110000
	!byte %10000000
	!byte %01110000
	!byte %00000000
	!byte %00000000

	!byte %01000000
	!byte %10000000
	!byte %11000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %01110000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %01110000
	!byte %00010000
	!byte %00100000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %10000000
	!byte %00000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %10000000
	!byte %10000000
	!byte %10010000
	!byte %10100000
	!byte %11000000
	!byte %10100000
	!byte %10010000
	!byte %00000000
	!byte %00000000

	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %11101100
	!byte %10010010
	!byte %10010010
	!byte %10010010
	!byte %10010010
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %11100000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %01110000
	!byte %10001000
	!byte %10001000
	!byte %10001000
	!byte %01110000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %11100000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %11100000
	!byte %10000000
	!byte %10000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %01000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %01100000
	!byte %10000000
	!byte %01000000
	!byte %00100000
	!byte %11000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %10000000
	!byte %11000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %01000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %01110000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %10001000
	!byte %10001000
	!byte %10001000
	!byte %01010000
	!byte %00100000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %10010010
	!byte %10010010
	!byte %10010010
	!byte %10010010
	!byte %01101100
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %01110000
	!byte %00010000
	!byte %00100000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
;32
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %10001000
	!byte %10010000
	!byte %10100000
	!byte %11000000
	!byte %10100000
	!byte %10010000
	!byte %10001000
	!byte %00000000
	!byte %00000000

	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %10000000
	!byte %11111000
	!byte %00000000
	!byte %00000000

	!byte %10000010
	!byte %11000110
	!byte %10101010
	!byte %10010010
	!byte %10000010
	!byte %10000010
	!byte %10000010
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %11100000
	!byte %10010000
	!byte %10010000
	!byte %10010000
	!byte %11100000
	!byte %10000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %01110000
	!byte %10000000
	!byte %01000000
	!byte %00100000
	!byte %00010000
	!byte %00010000
	!byte %11100000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
;0123456789 , / :
	!byte %01100000
	!byte %10010000
	!byte %10110000
	!byte %11010000
	!byte %10010000
	!byte %10010000
	!byte %01100000
	!byte %00000000
	!byte %00000000

	!byte %01000000
	!byte %11000000
	!byte %01000000
	!byte %01000000
	!byte %01000000
	!byte %01000000
	!byte %01000000
	!byte %00000000
	!byte %00000000

	!byte %11000000
	!byte %00100000
	!byte %00100000
	!byte %01000000
	!byte %10000000
	!byte %10000000
	!byte %11100000
	!byte %00000000
	!byte %00000000

	!byte %11000000
	!byte %00100000
	!byte %00100000
	!byte %01000000
	!byte %00100000
	!byte %00100000
	!byte %11000000
	!byte %00000000
	!byte %00000000

	!byte %00010000
	!byte %00110000
	!byte %01010000
	!byte %10010000
	!byte %11110000
	!byte %00010000
	!byte %00010000
	!byte %00000000
	!byte %00000000

	!byte %11100000
	!byte %10000000
	!byte %11000000
	!byte %00100000
	!byte %00100000
	!byte %00100000
	!byte %11000000
	!byte %00000000
	!byte %00000000

	!byte %00100000
	!byte %01000000
	!byte %10000000
	!byte %11100000
	!byte %10010000
	!byte %10010000
	!byte %01100000
	!byte %00000000
	!byte %00000000

	!byte %11110000
	!byte %00010000
	!byte %00100000
	!byte %01000000
	!byte %01000000
	!byte %01000000
	!byte %01000000
	!byte %00000000
	!byte %00000000

	!byte %01100000
	!byte %10010000
	!byte %10010000
	!byte %01100000
	!byte %10010000
	!byte %10010000
	!byte %01100000
	!byte %00000000
	!byte %00000000

	!byte %01100000
	!byte %10010000
	!byte %10010000
	!byte %01110000
	!byte %00010000
	!byte %00100000
	!byte %01000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %01000000
	!byte %10000000
	!byte %00000000

	!byte %00000000
	!byte %00000100
	!byte %00001000
	!byte %00010000
	!byte %00100000
	!byte %01000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %10000000
	!byte %00000000
	!byte %00000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %10000000
	!byte %00000000
	!byte %00000000

font5_width
	!fill $50,0

font7_width
	!fill $50,0

;8 bit delta x,y interleaved
move_pointer
		sta srcp
		stx srcp + 1
		lda #$ff
		sta yend
		jsr vsync
		ldy #$00
		lda (srcp),y
		sta $d000
		iny
		lda $d010
		and #$fe
		ora (srcp),y
		sta $d010
		iny
		lda (srcp),y
		sta $d001
		lda srcp
		clc
		adc #3
		sta srcp
		bcc +
		inc srcp + 1
+
move_cont
		jsr move_single
		cmp yend
		bne move_cont
		rts
move_single
		jsr vsync
		ldy #$00
		ldx #$00
		lda (srcp),y
		cmp #$80
		beq move_end
		bcc +
		dex
+
		clc
		adc $d000
		sta $d000
		txa
		adc $d010
		sta $d010
		iny
		lda (srcp),y
		lda $d001
		clc
		adc (srcp),y
		sta $d001
		jsr inc_poi_pos
inc_poi_pos
		inc srcp
		bne +
		inc srcp + 1
+
		rts
move_end
		pla
		pla
		jmp inc_poi_pos

loading_bar
!ifdef release {
		inc start_loading + 1
}
		cli
		;lda #$00
		;sta $d015
is_csdb		lda #$00
		beq +
		jsr clean_desktop
		jsr render_desktop
+
		lda #80
		sta xl
		lda #00
		sta xh
		sta pattern

		lda #<239
		sta xendl
		lda #>239
		sta xendh

		lda #80
		sta y
		lda #119
		sta yend

		lda #$ff
		jsr set_lbox

		jsr draw_box
		lda #$bf
		jsr set_lbox

		jsr draw_outline
		ldy #$13
		lda #$0b
		sta screen + 11*40 + 11,y
		sta screen + 12*40 + 11,y
		sta screen + 13*40 + 11,y
		sta screen + 14*40 + 11,y
-
		sta screen + 15*40 + 11,y
		dey
		bpl -

		lda #<142
		sta xl
		lda #85
		sta y
		lda #<loading
		ldx #>loading
		jsr draw_font7

		lda #86
		sta xl

		lda #<233
		sta xendl

		lda #97
		sta y
		lda #102
		sta yend

		jsr draw_outline
		lda #%11111110
		sta pattern
!ifdef release {
		jmp start_side_3
}
set_lbox
		ldx #$13
-
		sta screen + 10*40 + 10,x
		sta screen + 11*40 + 10,x
		sta screen + 12*40 + 10,x
		sta screen + 13*40 + 10,x
		sta screen + 14*40 + 10,x
		dex
		bpl -
		rts
draw_box
		lda y
		pha
-
		jsr draw_line_horizontal
		lda y
		inc y
		cmp yend
		bne -
		pla
		sta y
		rts

draw_line_horizontal
		ldx #$07
		lda xl + 0
		eor #$07
		sax pixs
		lda xendl
		sax pixe
		lda xendl
+
		sec
		sbc xl
		tax
		lda xendh
		sbc xh
		tay

		txa
		sec
		sbc pixe
		bcs +
		dey
+
		sec
		sbc pixs
		bcs +
		dey
+
		sty temp
		lsr temp
		ror
		lsr temp
		ror
		lsr temp
		ror
		sta temp

		lda y
		lsr
		lsr
		lsr
		tax
		lda xl
		and #$f8
		clc
		adc bitmap_tabl,x
		sta dst + 0

		lda xh
		adc bitmap_tabh,x
		sta dst + 1

		lda y
		and #$07
		tay
		ldx pixs
		lda pixstab_,x
		and (dst),y
		sta (dst),y
		lda pattern
		and pixstab,x
		ora (dst),y
		sta (dst),y
.dl_loop
		lda dst + 0
		clc
		adc #8
		sta dst + 0
		bcc +
		inc dst + 1
+
		lda temp
		beq .dl_done
		lda pattern
		sta (dst),y
		dec temp
		jmp .dl_loop
.dl_done
		ldx pixe
		lda pixetab_,x
		and (dst),y
		sta (dst),y
		lda pattern
		and pixetab,x
		ora (dst),y
		sta (dst),y
		rts
;shadow
;		sty temp
;		tax
;		and #$0f
;		tay
;		txa
;		lsr
;		lsr
;		lsr
;		lsr
;		tax
;		lda tab_shadow,x
;		asl
;		asl
;		asl
;		asl
;		ora tab_shadow,y
;		ldy temp
;		rts
;tab_shadow
;		!byte $00
;		!byte $0c
;		!byte $00
;		!byte $0e
;		!byte $06
;		!byte $0b
;		!byte $00
;		!byte $0a
;		!byte $09
;		!byte $00
;		!byte $08
;		!byte $00
;		!byte $00
;		!byte $05
;		!byte $06
;		!byte $0b

csdb_vote_bmp
!bin "csdb_vote.prg",6*8,2 + 14*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 15*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 16*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 17*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 18*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 19*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 20*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 21*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 22*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 23*$140 + 248
!bin "csdb_vote.prg",6*8,2 + 24*$140 + 248
csdb_vote_scr
!bin "csdb_vote.prg",6,2 + 14*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 15*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 16*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 17*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 18*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 19*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 20*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 21*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 22*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 23*40 + 31 + $1f40
!bin "csdb_vote.prg",6,2 + 24*40 + 31 + $1f40
csdb_no_vote_bmp
!bin "csdb2.prg",6*8,2 + 14*$140 + 248
!bin "csdb2.prg",6*8,2 + 15*$140 + 248
!bin "csdb2.prg",6*8,2 + 16*$140 + 248
!bin "csdb2.prg",6*8,2 + 17*$140 + 248
!bin "csdb2.prg",6*8,2 + 18*$140 + 248
!bin "csdb2.prg",6*8,2 + 19*$140 + 248
!bin "csdb2.prg",6*8,2 + 20*$140 + 248
!bin "csdb2.prg",6*8,2 + 21*$140 + 248
!bin "csdb2.prg",6*8,2 + 22*$140 + 248
!bin "csdb2.prg",6*8,2 + 23*$140 + 248
!bin "csdb2.prg",6*8,2 + 24*$140 + 248
csdb_no_vote_scr
!bin "csdb2.prg",6,2 + 14*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 15*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 16*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 17*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 18*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 19*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 20*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 21*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 22*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 23*40 + 31 + $1f40
!bin "csdb2.prg",6,2 + 24*40 + 31 + $1f40

!warn *
!if * > bitmap {
	!error "out of memory"
}
		* = sprites
!bin "geos_pointer.spr"
!bin "bonzai_icon.spr"
!bin "dustbin_bright.spr"
!bin "dustbin_dark.spr"
!bin "pumpkin1.spr"
!bin "pumpkin2.spr"

!ifdef release {
startmusic
		lda #<link_music_play_side2
		sta link_music_addr + 0
		lda #>link_music_play_side2
		sta link_music_addr + 1
		lxa #0
		tay
		jsr link_music_init_side2
		;+start_music_nmi
		rts
}
!ifdef release {
start_side_3
		inc start_loading + 1
		jsr link_load_next_raw
		lda #$0c
		sta .stop_music
		lda #$00
		sta $d418
		;+stop_music_nmi
		jmp link_exit
} else {
		jmp *
}
poll
		pha
		txa
		pha
		tya
		pha
!ifdef release {
.stop_music	jsr link_music_play
		inc $01
}
		dec $d019
!ifdef release {
	!ifdef crt {
                lda #$7f                        ;space pressed?
                sta $dc00
                lda $dc01
                and #$10
                beq .start                      ;yes, exit
                lda link_frame_count + 1        ;check counter
                bpl +
                sta .fc + 1
+
                lda #$fd                        ;shift lock pressed?
                sta $dc00
                lda $dc01
.fc             and #$00                        ;timer elapsed?
                bpl anim_load_
.start
	} else {
		lax $dd00
		bpl anim_load_
	}
		dec $01
}
start_loading
!ifdef release {
		lda #$00
} else {
		lda #$02
}
		bne anim_load
desktop_done	lda #$00
		beq .skip
		ldx #$ff
		txs
		jmp loading_bar
anim_load_
		dec $01
anim_load
		lda start_loading + 1
		cmp #$02
		bne .skip

!ifdef crt {
} else {
		txa
		bpl +
}

		lda .size + 1
		cmp #$88
		beq +
		inc .size + 1
+
		lda #<(bitmap + 12 * $140 + 91)
		sta dst
		lda #>(bitmap + 12 * $140 + 91)
		sta dst + 1

.pat1		lda #%11111110
		jsr .draw_line
		inc dst
.pat2		lda #%11111101
		jsr .draw_line
.slow		lda #$00
		clc
		adc #1
		and #$01
		sta .slow + 1
		bne .skip
		lda .pat1 + 1
		lsr
		ror .pat1 + 1
		lda .pat2 + 1
		lsr
		ror .pat2 + 1
.skip
		pla
		tay
		pla
		tax
		pla
		rti

.draw_line
		sta pattern
.size		lda #$00
		tax
		lda #$f8
		sax .len + 1

		ldy #$00
-
.len		cpy #$00
		beq .last

		lda pattern
		sta (dst),y
		tya
		clc
		adc #8
		tay
		jmp -
.last
		lda #$07
		sbx #$00
		lda pixetab,x
		and pattern
		sta (dst),y
		rts
pixetab
		!byte $80,$c0,$e0,$f0,$f8,$fc,$fe,$ff
pixstab
		!byte $01,$03,$07,$0f,$1f,$3f,$7f,$ff
pixstab_
		!byte $fe,$fc,$f8,$f0,$e0,$c0,$80,$00
pixetab_
		!byte $7f,$3f,$1f,$0f,$07,$03,$01,$00
pixtab
		!byte $01,$02,$04,$08,$10,$20,$40,$80
pixtab_
		!byte $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f

bitmap_tabl
!for .x,0,24 {
		!byte <(bitmap + .x * $140)
}
bitmap_tabh
!for .x,0,24 {
		!byte >(bitmap + .x * $140)
}

mv_bonzai
 !byte 228,$00,158
 !byte $00,$00,$01,$FF,$00,$FF,$01,$FE,$01,$FF,$01,$FE,$01,$FE,$01,$FE,$01,$FE,$01,$FE,$02,$FE,$01,$FE,$01,$FE,$01,$FE,$01,$FE,$00,$FF
 !byte $01,$FE,$01,$FE,$00,$FE,$01,$FF,$00,$FE,$00,$FE,$01,$FE,$00,$FE,$00,$FF,$00,$FE,$00,$FF,$01,$FE,$00,$FF,$00,$FF,$00,$FF,$01,$FF
 !byte $80
 !byte $00,$00,$00,$00,$01,$00,$00,$00,$01,$01,$00,$01,$00,$00,$01,$01,$00,$01,$01,$02,$00,$01,$01,$01,$00,$01,$01,$02,$00,$01,$01,$01
 !byte $00,$01,$01,$01,$00,$02,$01,$01,$00,$01,$01,$01,$00,$02,$01,$01,$00,$02,$01,$01,$00,$01,$01,$02,$00,$01,$01,$02,$01,$01,$00,$01
 !byte $01,$01,$01,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$01,$01,$01,$01
 !byte $01,$02,$01,$01,$01,$01,$01,$02,$01,$02,$01,$01,$01,$02,$01,$02,$01,$01,$02,$02,$01,$02,$01,$01,$01,$02,$01,$02,$00,$01,$01,$01
 !byte $01,$02,$01,$01,$01,$01,$02,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01
 !byte $00,$00,$01,$01,$00,$01,$01,$01,$00,$01,$00,$01,$01,$01,$00,$01,$00,$01,$00,$01,$01,$01,$00,$00,$00,$01,$00,$00,$01,$00,$00,$00
 !byte $80
 !byte $00,$00,$01,$FF,$00,$FF,$00,$00,$01,$FE,$00,$FF,$00,$FF,$01,$FF,$00,$FE,$00,$FE,$01,$FF,$00,$FE,$00,$FE,$01,$FF,$00,$FE,$00,$FE
 !byte $00,$FF,$00,$FE,$00,$FF,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FF,$00,$FE,$00,$FE,$FF,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE
 !byte $00,$FF,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$01,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE
 !byte $00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$FF,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FF,$00,$FE,$00,$FE,$FF,$FE,$00,$FE,$00,$FF,$00,$FE
 !byte $00,$FF,$00,$FE,$00,$FF,$FF,$FE,$00,$FF,$00,$FF,$00,$FE,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$FF
 !byte $80

mv_disk
 !byte $18,$00
 !byte $32
 !byte $00,$00,$01,$01,$00,$01,$01,$01,$01,$02,$01,$01,$01,$02,$02,$01,$01,$02,$01,$02,$02,$02,$01,$02,$02,$02,$02,$02,$01,$02,$02,$02
 !byte $02,$02,$02,$02,$03,$03,$02,$02,$02,$03,$03,$02,$03,$03,$03,$03,$02,$03,$03,$02,$03,$03,$03,$03,$03,$02,$03,$02,$03,$03,$03,$02
 !byte $02,$01,$03,$02,$03,$01,$03,$01,$03,$02,$03,$01,$03,$01,$02,$00,$03,$01,$03,$01,$03,$00,$02,$01,$03,$01,$02,$00,$03,$00,$02,$01
 !byte $01,$00,$02,$00,$01,$01,$02,$00,$01,$00,$01,$00,$01,$00,$01,$FF,$00,$00,$01,$00,$01,$00,$00,$FF,$01,$00,$00,$00,$01,$00,$01,$FF
 !byte $00,$00,$01,$00,$00,$FF,$01,$00,$01,$FF,$00,$00,$01,$FF,$00,$00,$01,$FF,$00,$00,$00,$FF,$01,$00,$01,$FF,$00,$00,$01,$FF,$01,$FF
 !byte $00,$00,$01,$FF,$01,$00,$00,$FF,$01,$FF,$01,$00,$01,$FF,$01,$FF,$00,$00,$01,$FF,$01,$FF,$01,$00,$02,$FF,$01,$00,$01,$FF,$02,$FF
 !byte $02,$00,$02,$FF,$02,$00,$02,$FF,$02,$00,$03,$FF,$02,$00,$03,$FF,$02,$00,$03,$FF,$03,$00,$02,$FF,$03,$00,$03,$FF,$03,$00,$03,$FF
 !byte $02,$00,$03,$FF,$03,$FF,$03,$00,$03,$FF,$03,$FF,$04,$00,$03,$FF,$03,$FF,$03,$FF,$03,$00,$03,$FF,$04,$FF,$03,$00,$03,$FF,$03,$FF
 !byte $03,$00,$03,$FF,$03,$FF,$03,$00,$03,$FF,$03,$00,$03,$FF,$03,$00,$04,$FF,$02,$FF,$03,$00,$03,$00,$03,$FF,$02,$00,$02,$FF,$02,$00
 !byte $02,$00,$02,$00,$02,$FF,$01,$00,$01,$00,$02,$00,$01,$FF,$01,$00,$01,$00,$00,$00,$01,$00,$01,$00,$00,$01,$00,$00,$00,$00
 !byte $80

mv_ok
 !byte $3d,$01
 !byte $51
 !byte $00,$01
 !byte $00,$00,$FF,$01,$00,$01,$FF,$01,$FF,$01,$FE,$01,$FF,$01,$FF,$01,$FE,$01,$FE,$02,$FF,$01,$FE,$01,$FE,$02,$FF,$01,$FE,$02,$FE,$02
 !byte $FF,$01,$FE,$02,$FF,$02,$FE,$02,$FE,$03,$FE,$02,$FF,$02,$FE,$03,$FE,$02,$FE,$02,$FE,$03,$FE,$02,$FF,$02,$FE,$02,$FE,$02,$FE,$02
 !byte $FE,$01,$FF,$02,$FE,$01,$FE,$01,$FE,$02,$FF,$01,$FE,$01,$FE,$01,$FE,$01,$FE,$01,$FF,$01,$FE,$00,$FE,$01,$FE,$01,$FF,$01,$FE,$01
 !byte $FE,$01,$FF,$01,$FE,$01,$FE,$00,$FE,$01,$FE,$01,$FF,$01,$80

mv_csdb
 !byte 228,0
 !byte 158
 !byte $00,$00,$FF,$01,$FF,$02,$FE,$01,$FE,$02,$FF,$02,$FE,$02,$FE,$03,$FD,$02,$FE,$02,$FE,$03,$FE,$02,$FD,$03,$FE,$02,$FE,$02,$FE,$02
 !byte $FE,$02,$FE,$02,$FE,$02,$FE,$02,$FD,$02,$FE,$01,$FE,$02,$FE,$02,$FE,$02,$FD,$01,$FE,$02,$FE,$02,$FE,$01,$FF,$01,$FE,$02,$FE,$01
 !byte $FF,$01,$FF,$01,$FE,$01,$FF,$01,$00,$01,$FF,$01,$FF,$01,$FF,$01,$00,$01,$FF,$00,$00,$01,$FF,$00,$00,$00,$80
 !byte $FF,$00,$FF,$00,$00,$00
 !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FE,$FE,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FD,$FF,$FE,$FF,$FD,$00,$FE,$FF,$FE
 !byte $00,$FE,$00,$FD,$00,$FE,$00,$FD,$00,$FE,$00,$FD,$01,$FE,$00,$FD,$01,$FE,$00,$FD,$01,$FD,$00,$FE,$01,$FD,$01,$FE,$01,$FD,$00,$FE
 !byte $01,$FD,$01,$FE,$01,$FE,$01,$FD,$02,$FE,$01,$FE,$02,$FE,$01,$FD,$01,$FE,$02,$FE,$01,$FE,$01,$FD,$01,$FE,$01,$FE,$01,$FE,$01,$FE
 !byte $00,$FD,$00,$FE,$00,$FE,$00,$FD,$00,$FE,$00,$FD,$00,$FE,$FF,$FD,$00,$FE,$FF,$FD,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FF
 !byte $FE,$FF,$FF,$FE,$FE,$FF,$FE,$FF,$FE,$00,$FD,$FF,$FE,$FF,$FD,$00,$FD,$FF,$FE,$00,$FD,$00,$FE,$00,$FD,$00,$FE,$01,$FE,$00,$FE,$01
 !byte $FE,$00,$FF,$01,$FE,$01,$FF,$02,$FE,$01,$FF,$02,$FF,$01,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$03,$00,$02,$FF,$02
 !byte $00,$02,$00,$02,$FF,$03,$00,$02,$00,$03,$00,$02,$00,$03,$00,$03,$01,$02,$00,$03,$01,$03,$00,$02,$01,$03,$00,$02,$01,$02,$01,$02
 !byte $00,$02,$01,$02,$01,$01,$01,$02,$01,$02,$01,$01,$01,$01,$01,$02,$02,$01,$01,$01,$02,$01,$01,$01,$02,$01,$01,$01,$02,$01,$02,$01
 !byte $02,$00,$02,$01,$03,$01,$02,$01,$03,$00,$03,$01,$03,$01,$03,$00,$03,$01,$03,$00,$03,$00,$03,$00,$02,$00,$03,$00,$03,$FF,$02,$FF
 !byte $02,$FF,$03,$FF,$02,$FF,$02,$FE,$02,$FE,$03,$FE,$02,$FE,$02,$FE,$02,$FE,$02,$FD,$01,$FE,$02,$FD,$01,$FD,$02,$FE,$01,$FD,$01,$FE
 !byte $00,$FD,$01,$FE,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$00,$FD,$FF,$FD,$00,$FD,$00,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FE,$FF,$FE
 !byte $FF,$FD,$FF,$FE,$FE,$FF,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FF,$FE,$FE,$FE,$FF,$FE,$FF,$FD,$FE,$FE,$FF,$FE,$FF,$FD,$FF,$FE,$FF,$FD,$FF
 !byte $FE,$FF,$FE,$00,$FD,$FF,$FE,$FF,$FD,$00,$FE,$FF,$FD,$00,$FE,$00,$FD,$00,$FD,$FF,$FE,$00,$FD,$00,$FE,$00,$FD,$01,$FE,$00,$FD,$00
 !byte $FE,$00,$FD,$01,$FE,$00,$FD,$01,$FE,$01,$FD,$01,$FE,$00,$FD,$01,$FE,$01,$FE,$01,$FD,$01,$FE,$01,$FE,$01,$FE,$01,$FF,$01,$FE,$01
 !byte $FF,$01,$FF,$01,$FF,$00,$FF,$01,$FF,$01,$00,$01,$FF,$00,$00,$01,$00,$01,$FF,$01,$00,$00,$00,$01,$00,$01,$00,$01,$FF,$01,$00,$01
 !byte $00,$01,$FF,$01,$00,$01,$00,$02,$00,$01,$00,$01,$00,$02,$00,$01,$FF,$02,$00,$01,$00,$01,$00,$01,$00,$02,$00,$00,$00,$01,$00,$01
 !byte $80
mv_vote
 !byte 74,0,108
 !byte $00,$00,$01,$00,$01,$01,$01,$00,$01,$01,$02,$00,$01,$01,$02,$00,$01,$01,$02,$00,$02,$01,$02,$01,$02,$00,$02,$01,$01,$01,$02,$00
 !byte $02,$01,$02,$01,$02,$00,$02,$01,$02,$01,$02,$01,$02,$00,$02,$01,$02,$01,$02,$01,$02,$00,$02,$01,$03,$01,$02,$01,$02,$01,$02,$00
 !byte $02,$01,$02,$01,$02,$01,$03,$00,$02,$01,$02,$01,$02,$01,$02,$00,$02,$01,$03,$01,$02,$01,$02,$00,$02,$01,$02,$01,$03,$01,$02,$00
 !byte $02,$01,$03,$01,$02,$00,$03,$01,$02,$01,$03,$01,$02,$00,$03,$01,$03,$00,$02,$01,$03,$01,$02,$00,$03,$01,$02,$01,$03,$00,$02,$01
 !byte $02,$00,$03,$01,$02,$00,$02,$01,$02,$00,$02,$00,$03,$01,$02,$00,$02,$01,$02,$00,$02,$00,$02,$01,$02,$00,$02,$00,$02,$01,$02,$00
 !byte $01,$00,$02,$00,$02,$00,$02,$01,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$01,$00,$02,$00,$02,$00,$02,$00,$01,$00,$02,$00
 !byte $01,$00,$02,$00,$02,$00,$01,$00,$02,$01,$01,$00,$02,$00,$01,$00,$02,$00,$01,$00,$01,$01,$02,$00,$01,$00,$01,$00,$01,$00,$01,$00
 !byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$FF,$00,$00,$01,$00,$00,$00,$80
 !byte $01,$FF,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00
 !byte $00,$00,$00,$00,$01,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00,$01,$00,$01,$00,$00,$00,$01,$00,$01,$00,$01
 !byte $00,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00,$01,$FF,$00,$00,$01,$00,$01,$00,$01,$00,$00,$00,$01,$FF,$01,$00,$00,$00,$01,$00,$01
 !byte $00,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$01,$FF,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$01
 !byte $00,$00,$00,$01,$00,$01,$00,$00,$FF,$01,$00,$01,$00,$00,$00,$01,$00,$01,$00,$00,$FF,$01,$00,$01,$00,$01,$00,$00,$00,$01,$00,$01
 !byte $00,$00,$00,$01,$00,$01,$00,$01,$00,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$00,$01,$01,$01,$00,$01,$00,$00,$00,$01,$00,$01
 !byte $00,$00,$00,$01,$00,$01,$01,$00,$00,$01,$00,$01,$00,$00,$00,$01,$01,$01,$00,$00,$00,$01,$00,$00,$00,$01,$01,$01,$00,$00,$00,$01
 !byte $00,$00,$00,$01,$01,$01,$00,$00,$00,$01,$01,$01,$00,$00,$00,$01,$00,$01,$01,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00
 !byte $00,$00,$00,$00,$FF,$01,$00,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$00,$FF,$FF,$00
 !byte $00,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$00,$FF,$00,$FF
 !byte $00,$FF,$00,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FE,$00,$FF,$00,$FF,$00,$FF
 !byte $00,$FF,$00,$FF,$00,$FE,$01,$FF,$00,$FE,$00,$FF,$00,$FE,$01,$FF,$00,$FF,$00,$FE,$00,$FF,$01,$FE,$00,$FF,$00,$FF,$00,$FF,$00,$FF
 !byte $00,$FF,$00,$00,$FF,$FF,$00,$FF,$00,$00,$00,$FF,$FF,$00,$00,$00,$FF,$FF,$00,$00,$FF,$00,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00
 !byte $80
 !byte $00,$ff
 !byte $00,$ff
 !byte $00,$ff
 !byte $ff,$ff
 !byte $00,$ff
 !byte $00,$ff
 !byte $00,$ff
 !byte $00,$ff
 !byte $80
mv_csdb_close
 !byte $00,$ff
 !byte $00,$ff
 !byte $00,$ff
 !byte $01,$fe
 !byte $01,$fe
 !byte $01,$fe
 !byte $01,$fd
 !byte $01,$fd
 !byte $01,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $02,$fc
 !byte $01,$fc
 !byte $01,$fc
 !byte $01,$fc
 !byte $01,$fc
 !byte $01,$fc
 !byte $01,$fc
 !byte $01,$fc
 !byte $01,$fc
 !byte $01,$fd
 !byte $01,$fd
 !byte $01,$fe
 !byte $01,$fe
 !byte $01,$ff
 !byte $01,$ff
 !byte $01,$ff
 !byte $80
;back to disk
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $ff,$01
 !byte $00,$01
 !byte $80
mv_porn
 !byte $00,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FE,$00,$FF,$FF,$FE,$00,$FF,$00,$FE,$FF,$FF,$00,$FE,$FF,$FE,$00
 !byte $FF,$FF,$FE,$FF,$FF,$00,$FE,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FE,$00,$FF,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FF,$FF
 !byte $FE,$FF,$FE,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
 !byte $FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$FF
 !byte $00,$00,$00,$00,$01,$FF,$00,$00,$00,$00,$01,$FF,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00,$00,$01,$01,$00
 !byte $00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$00,$00,$01,$00,$00,$01,$01,$00,$00,$00,$01,$00,$01,$00,$00,$FF,$01,$00,$01
 !byte $00,$00,$FF,$01,$00,$00,$FF,$01,$FF,$01,$FF,$00,$FF,$01,$FF,$01,$FF,$00,$FF,$01,$FF,$01,$FF,$01,$FF,$00,$00,$01,$FF,$01,$FF,$00
 !byte $00,$01,$00,$01,$00,$00,$FF,$01,$00,$00,$01,$01,$00,$00,$00,$01,$00,$01,$00,$00,$01,$01,$00,$00,$01,$01,$00,$01,$00,$01,$01,$01
 !byte $00,$01,$01,$02,$00,$01,$01,$02,$00,$01,$01,$02,$00,$02,$01,$02,$01,$02,$00,$02,$01,$01,$01,$02,$00,$02,$01,$02,$00,$02,$01,$02
 !byte $00,$01,$00,$02,$01,$02,$00,$02,$00,$01,$01,$02,$00,$02,$00,$01,$00,$02,$00,$02,$01,$01,$00,$02,$00,$01,$00,$02,$01,$01,$00,$01
 !byte $00,$01,$00,$01,$01,$01,$00,$01,$00,$01,$01,$01,$00,$00,$00,$01,$01,$01,$00,$00,$01,$01,$00,$00,$00,$01,$01,$00,$00,$00,$01,$01
 !byte $00,$00,$01,$00,$00,$01,$01,$00,$00,$00,$01,$00,$00,$01,$01,$00,$00,$00,$01,$00,$01,$00,$00,$00,$01,$FF,$00,$00,$00,$00,$01,$FF
 !byte $00,$00,$00,$FF,$01,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FE,$00,$FF,$00,$FF,$00,$FE,$00,$FF,$00,$FE,$00,$FF,$00,$FF
 !byte $00,$FF,$00,$FE,$00,$FF,$FF,$FF,$00,$FE,$00,$FF,$00,$FE,$FF,$FF,$00,$FF,$00,$FE,$FF,$FF,$00,$FF,$FF,$FE,$00,$FF,$00,$FF,$FF,$FF
 !byte $00,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$00,$FF,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$FF,$FF
 !byte $FE,$00,$FF,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$00,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$00,$FE,$FF,$FE,$FF,$FE,$00,$FF,$FF
 !byte $FE,$00,$FF,$00,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$01,$FF,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00
 !byte $00,$00,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$00,$00,$FF,$00,$00,$00,$FF,$FF,$00,$00,$FF,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$FF,$FF
 !byte $00,$00,$FF,$FF,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$FF,$00,$00,$FF,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$FF,$FF,$00,$00,$00,$FF
 !byte $00,$00,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$00
 !byte $00,$00,$FF,$00,$00,$00,$00,$01,$FF,$00,$FF,$01,$00,$00,$FF,$01,$00,$01,$FF,$00,$FF,$01,$00,$01,$FF,$01,$00,$01,$FF,$01,$00,$02
 !byte $00,$01,$00,$01,$00,$01,$00,$02,$00,$02,$00,$01,$00,$02,$00,$02,$00,$02,$01,$02,$00,$01,$00,$02,$00,$02,$00,$02,$01,$02,$00,$01
 !byte $00,$02,$00,$02,$01,$01,$00,$02,$00,$02,$00,$01,$01,$02,$00,$02,$00,$01,$00,$02,$01,$01,$00,$02,$00,$02,$01,$01,$00,$02,$01,$01
 !byte $00,$02,$01,$02,$01,$01,$00,$02,$01,$02,$01,$02,$01,$02,$00,$01,$01,$02,$01,$02,$01,$01,$01,$02,$00,$01,$01,$01,$01,$02,$01,$01
 !byte $00,$01,$01,$00,$01,$01,$01,$01,$00,$00,$01,$00,$01,$01,$01,$00,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00
 !byte $00,$00,$01,$00,$00,$FF,$01,$00,$00,$FF,$01,$00,$00,$FF,$01,$FF,$00,$00,$00,$FF,$01,$FF,$00,$00,$00,$FF,$00,$FF,$00,$00,$00,$FF
 !byte $00,$00,$00,$FF,$FF,$00,$00,$00,$FF,$FF,$00,$00,$FF,$00,$FF,$00,$00,$00,$FF,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$FF
 !byte $00,$FF,$FF,$FF,$00,$FF,$00,$FF,$FF,$FF,$00,$FF,$00,$FF,$FF,$FE,$00,$FF,$00,$FF,$00,$FE,$FF,$FF,$00,$FF,$00,$FE,$00,$FF,$00,$FE
 !byte $00,$FF,$00,$FE,$00,$FF,$00,$FF,$01,$FE,$00,$FE,$00,$FF,$00,$FE,$01,$FF,$00,$FE,$00,$FF,$01,$FE,$00,$FE,$00,$FF,$01,$FE,$00,$FE
 !byte $00,$FF,$00,$FE,$01,$FE,$00,$FE,$00,$FE,$01,$FE,$00,$FE,$00,$FE,$00,$FE,$01,$FE,$00,$FE,$00,$FE,$00,$FF,$01,$FE,$00,$FF,$00,$FE
 !byte $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$01,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$00,$01,$FF,$00,$00
 !byte $80
 !byte $00,$00,$01,$00,$00,$00,$01,$00,$00,$01,$00,$00,$01,$01,$00,$00,$01,$01,$01,$00,$00,$01,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01
 !byte $01,$00,$01,$01,$02,$00,$01,$01,$02,$00,$01,$00,$02,$01,$02,$00,$01,$01,$02,$00,$02,$01,$01,$00,$02,$01,$02,$00,$01,$00,$02,$01
 !byte $01,$00,$02,$01,$01,$00,$02,$01,$01,$01,$01,$00,$02,$01,$01,$00,$01,$01,$02,$00,$01,$01,$01,$01,$02,$00,$01,$01,$01,$00,$02,$01
 !byte $01,$01,$02,$00,$01,$01,$02,$00,$02,$01,$01,$01,$02,$00,$01,$01,$02,$01,$02,$00,$01,$01,$02,$01,$01,$01,$01,$00,$02,$01,$01,$01
 !byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00,$00,$01
 !byte $80
 !byte $01,$00,$01,$00,$01,$00,$01,$FF,$01,$00,$02,$FF,$01,$00,$01,$FF,$01,$FF,$02,$FF,$01,$FF,$01,$FF,$02,$FF,$01,$FF,$01,$FF,$02,$FF
 !byte $01,$FF,$02,$FF,$01,$FF,$02,$FF,$02,$FF,$01,$FF,$02,$FF,$02,$FE,$01,$FF,$02,$FF,$02,$FF,$01,$FF,$02,$FE,$02,$FF,$01,$FF,$02,$FF
 !byte $01,$FF,$02,$FF,$02,$FF,$01,$FF,$02,$FF,$02,$FF,$01,$FF,$02,$FF,$01,$FF,$02,$FF,$01,$FF,$02,$FF,$01,$FF,$02,$FF,$01,$FF,$01,$FF
 !byte $01,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$FE,$01,$FF,$00,$FF,$01,$FF,$01,$FF,$00,$FF,$01,$FE,$01,$FF,$00,$FF,$01,$FF,$00,$FF,$01,$FF
 !byte $01,$FF,$00,$FF,$01,$FF,$00,$FF,$01,$FF,$00,$FF,$00,$FF,$01,$FF,$00,$FF,$00,$FF,$01,$FF,$00,$FF,$00,$00,$01,$FF,$00,$FF,$00,$00
 !byte $80

csdb_bitmap
csdb_screen = * + $1f40
!bin "csdb2.prg",,2
result_bitmap
!for .x,0,24 {
	!bin "csdb_done.prg",$f0,2 + .x * $140
}
result_screen
!bin "csdb_done.prg",,$1f42

		* = screen
!fill $3f8,$bf
		!byte <((sprites + 0 * $40) / $40)
		!byte <((sprites + 1 * $40) / $40)
		!byte <((sprites + 2 * $40) / $40)
		!byte <((sprites + 3 * $40) / $40)
		!byte <((sprites + 4 * $40) / $40)
		!byte <((sprites + 5 * $40) / $40)
		!byte <((sprites + 6 * $40) / $40)
		!byte <((sprites + 7 * $40) / $40)
