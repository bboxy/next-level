!cpu 6510

dst		= $02

xendl		= $04
xendh		= $05
yend		= $06
pixs		= $07
pixe		= $08
temp		= $09
pattern		= $0a
src_		= $0b
srcp		= $0d
yand7		= $0f
font		= $10
page_num	= $12
xl_		= $13
width		= $14

zp_code		= $20

bitmap		= $2000
volatile	= bitmap
screen		= $0400
sprites		= $3f40
music		= $0800
main		= $4000

PRA		= $dc00
DDRA		= $dc02

PRB		= $dc01
DDRB		= $dc03

		* = music
!bin "../../music/AnythingNext.prg",,2


!macro shift_right .x {
	!if .x = 7 {
		lda #$00
		rol
	}
	!if .x = 6 {
		lda shift6r,x
		;asr #$03
		;ror
		;ror
	}
	!if .x = 5 {
		lda shift5r,x
		;asr #$07
		;ror
		;ror
		;ror
		;lsr
		;lsr
		;lsr
		;lsr
		;lsr
	}
	!if .x = 4 {
		lda shift4r,x
		;lsr
		;lsr
		;lsr
		;lsr
	}
	!if .x = 3 {
		lda shift3r,x
		;lsr
		;lsr
		;lsr
	}
	!if .x = 2 {
		lsr
		asr #$fe
	}
	!if .x = 1 {
		asr #$fe
	}
	!if .x = 0 {
	}
}

		* = sprites
!bin "geos_pointer.spr"
!bin "dustbin_bright_single.spr"
!bin "dustbin_dark_single.spr"

		* = volatile
		jmp .start
zp_code_start
!pseudopc zp_code {
shift7_w
fheight7w	ldy font5_height,x
		;XXX TODO could now work with preshifted font and load appropriate preshifted chunk?
findex_l7w	lda font5_chr_ptr,x
		sta <font7w + 1
		;XXX TODO, update on dst += 8 globally?
		anc #$07
		ora <xpos
		sta <dst__ + 0
		adc #8
		sta <dst_ + 0
		lda <dst__ + 1
		adc #0
		sta <dst_ + 1
findex_h7w
		lda font5_chr_ptr_,x		;XXX TODO in fact this does not chnage at all when using lowercase chars. We could at least do one code path for lowercase and one for remaining?
		sta <font7w + 2
-
font7w		lda $0000,y
		asl
dst_ = * + 1
		eor $0000,y			;XXX TODO, we could write through in certain cases, but we have a frame around our textbox and would else overwrite it on write through
		sta (dst_),y
		bcc +
		isc (dst__),y
		;lda (dst__),y
		;adc #$00
		;sta (dst__),y
+
		dey
		bpl -
		clc
fwidth7w	lda font5_width,x
		bcc char_end_
shift3
.fheight_	ldy font5_height,x
.findex_l	lda font5_chr_ptr,x
		stx <fwidth + 1
		sta <.font + 1

		anc #$07			;extract offset in y
		ora <xpos			;compine with current linepos
		sta <dst__ + 0
.findex_h
		lda font5_chr_ptr_,x
		sta <.font + 2
-
.font 		ldx $0000,y
		+shift_right 3
dst__ = * + 1
		eor $0000,y
		sta (dst__),y
		dey
		bpl -
char_end
fwidth		lda font5_width
char_end_
xl = * + 1
		adc #$00
		;sta xl
		;ldx xpostab
		;stx xpos
		;
		bcc draw_line
.incdst
xpos = * + 1
		ldx plus8tab			;results in xpos = xpos + 8, not destroying A
		stx <xpos
		beq .incdsthi
-
		sbc #$10			;need to respect char widths >= 8 :-(
		bcs .incdst
draw_line
		sta <xl
draw_line_entry
src = * + 1
		ldx $0000
		inc <src
		beq .incsrchi
.width8		and font5_width_mul8,x
		;cpx #$20
		;bcs dynamic_font_ptr		;code duplication, once with highbyte handling on font ptr and once with fixed highbyte, enough for most chars
		sta <.jump + 1
.jump		jmp (.shifttab)			;handles also space, that is why no further stuff is set yet, but in speedcode

.incdsthi
		inc <dst__ + 1
		bne -
.incsrchi
		inc <src + 1
		bne .width8
space
		lda #$06
		cpx #$fe
		bcc char_end_			;< $fe
		bne .end_text			;> $fe == $ff, end
						;line break
y = * + 1
		ldx plus8tab			;y = y + 8
		stx <y
		lda bitmap_tabl,x
		sta <xpos
		;XXX TODO linelength stuff could be prelacled beforehand, with a table that contains chars per line, needs a first pass/preprocessing
		lda bitmap_tabh,x
		sta <dst__ + 1
		lda #<($fa * 2)
		jmp draw_line
draw_text_
		ldy <y
		lax <xl
		and #$f8
		clc
		adc bitmap_tabl,y
		sta <xpos
		;XXX TODO linelength stuff could be prelacled beforehand, with a table that contains chars per line, needs a first pass/preprocessing
xh = * + 1
		lda #$00
		adc bitmap_tabh,y
		sta <dst__ + 1
		txa
		ora #$f8
		asl
		jmp draw_line

.end_text
		rts
}
zp_code_end
!warn zp_code_end - zp_code_start

;make jump even more detailed:
;XXX per shift and per width?

!macro shift .x, ~.findex_h, ~.fwidth, ~.fheight, ~.findex_l {
.fheight	ldy font5_height,x
.findex_l	lda font5_chr_ptr,x
		;XXX TODO contains index into shifttable not current char?
		;XXX TODO font in einzelne unique zeilen zerlegen -> das ist alles was man geshiftet holen muss
		;offset auf dst aufrechnen und y nach null runterzählen?
		;danach lda dst and #$f8 adc #8 sta dst
		sta .font + 1

		anc #$07
		ora <xpos
		sta <dst__ + 0
.findex_h
		lda font5_chr_ptr_,x
		sta .font + 2
		;do this conditionally where it applies to be cheaper?
!if .x = 0 or .x = 1 or .x = 2 or .x = 7 {
.normal
-
.font		lda $0000,y
} else {
		stx <fwidth + 1
.normal
-
.font		lax $0000,y
}
		+shift_right .x
		eor (dst__),y		;XXX TODO could write to a buffer on normal operation? and eor this buffer on first char? dst_ -> write to new buffer instead? but need to flush then on line end and what happens if we end at a char pos 8?
		sta (dst__),y
+
		dey
		bpl -
!if >* != >.normal { !warn "branch crosses page! ", *, " ", .normal, " ", .x  }

!if .x = 0 or .x = 1 or .x = 2 or .x = 7 {
.fwidth		lda font5_width,x
		jmp char_end_
} else {
		jmp char_end
}
}

;XXX TODO place one shift part in zeropage to also have dst_ there
!macro shift2 .x, ~.findex_h, ~.fwidth, ~.fheight, ~.findex_l {
.fheight	ldy font5_height,x
		;XXX TODO could now work with preshifted font and load appropriate preshifted chunk?
.findex_l	lda font5_chr_ptr,x
		sta .font + 1
		;XXX TODO, update on dst += 8 globally?
		anc #$07
		ora <xpos
		sta <dst__ + 0
		adc #8
		sta <dst_ + 0
		lda <dst__ + 1
		adc #0
		sta <dst_ + 1
.findex_h
		lda font5_chr_ptr_,x
		sta .font + 2
!if .x = 1 or .x = 7 {
.normal
-
.font		lda $0000,y
} else {
.normal
		stx <fwidth + 1
-
.font		lax $0000,y
}
;!if .x == 7 {
;		asl
;		eor (dst_),y		;XXX TODO, we could write through in certain cases, but we have a frame around our textbox and would else overwrite it on write through
;		sta (dst_),y
;		bcc +
;		jam
;		lda (dst__),y
;		adc #$00
;		sta (dst__),y
;		;isc (dst__),y
;		;clc
!if .x == 6 {
		lda shift6r,x
		eor (dst__),y
		sta (dst__),y
		lda shift2l,x
		eor (dst_),y
		sta (dst_),y
} else if .x == 5 {
		lda shift5r,x
		eor (dst__),y
		sta (dst__),y
		lda shift3l,x
		eor (dst_),y
		sta (dst_),y
		;sax (dst - $xval ,x)
		;same as:
		;sax (dst),0
} else if .x == 4 {
		lda shift4r,x
		eor (dst__),y
		sta (dst__),y
		lda shift4l,x
		eor (dst_),y
		sta (dst_),y
} else if .x == 3 {
		lda shift3r,x
		eor (dst__),y
		sta (dst__),y
		lda shift5l,x
		eor (dst_),y
		sta (dst_),y
} else if .x == 2 {
		lsr
		asr #$fe
		eor (dst__),y
		sta (dst__),y
		lda shift6l,x
		eor (dst_),y
		sta (dst_),y
} else if .x == 1 {
		lsr
		eor (dst__),y
		sta (dst__),y
		arr #$00
		eor (dst_),y
		sta (dst_),y
}
+
		dey
		bpl -
!if >* != >.normal { !warn "branch crosses page! ", *, " ", .normal, " ",.x  }
!if .x = 1 or .x = 7 {
.fwidth		lda font5_width,x
		jmp char_end_
} else {
		jmp char_end
}
}

.start
		lxa #0
		tay
		jsr music
		sei
		ldx #$01
		jsr wait
		lda #$35
		sta $01
		lda #<musicirq
		sta $fffe
		lda #>musicirq
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

		ldy #$00
		ldx #<((sprites) / $40)
-
		txa
		sta screen + $3f8,y
		inx
		iny
		cpy #$08
		bne -

		jsr populate_width
		jsr vsync
		ldx #$00
-
		lda zp_code_start,x
		sta+2 zp_code,x
		inx
		cpx #zp_code_end - zp_code_start
		bne -

		ldx #$00
		lda #$bf
-
		sta screen + $000,x
		sta screen + $100,x
		sta screen + $200,x
		sta screen + $2f8,x
		dex
		bne -

		lda #$00
		sta page_num

		lda #$00
		sta $d020
		lda #$08
		sta $d016
		lda #$18
		sta $d018
		lda #$03
		sta $dd00

		lda #<304
		sta $d002
		sta $d004

		lda #200
		sta $d003
		sta $d005

		lda #$06
		sta $d010

		lda #$00
		sta $d017
		sta $d01b
		sta $d01d
		sta $d015
		sta $d01c

		lda #$06
		sta $d027
		lda #$0f
		sta $d028
		lda #$0b
		sta $d029

		lda #$18
		sta $d000
		lda #$32
		sta $d001
		lda #$3b
		sta $d011
		jmp main

populate_width

!macro do_width .font, .height, .chr_ptr, .width, .width_mul8, .max {
		ldy #$00
		sty temp
		lda #<.font
		sta <src + 0
		lda #>.font
		sta <src + 1
---
		ldy #$00
-
		lax (src),y
		bne +
		iny
		cpy #.max + 1
		bne -
		dey
+
		ldx temp
		tya
		sta .height,x
		clc
		adc .chr_ptr,x
		sta .chr_ptr,x

		ldy #.max
-
		lda (src),y
		bne +
		dey
		bpl -
		iny
+
		tya
		sec
		sbc .height,x
		sta .height,x

		ldy #.max + 1
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
		cmp .width,x
		bcc --
		sta .width,x
		asl
		asl
		asl
		asl
		ora #$0e
		sta .width_mul8,x
		jmp --
+
		inc .width,x
		inc .width,x
		asl .width,x

		lda <src + 0
		clc
		adc #8
		sta <src + 0
		bcc +
		inc <src + 1
+
		inc temp
		bne ---

		lda #$00
		sta .width_mul8 + $fe
		sta .width_mul8 + $ff
		sta .width_mul8 + $20
		sta .width_mul8 + $a0
		lda #$00
		sta .width + $20
		sta .width + $a0
		sta .width + $ff
		sta .width + $fe
}

		+do_width font_note, font_note_height, font_note_chr_ptr, font_note_width, font_note_width_mul8, 7
		+do_width font_geos5, font5_height, font5_chr_ptr, font5_width, font5_width_mul8, 7

		lda #<note
		sta <src
		lda #>note
		sta <src + 1
		jmp find_line_lengths
.fldone_
		;XXX TODO, preproc, set $00 instead of space where line is > $140 beforehand, all done then
		ldy <width
		lda #$fe
		tax
		sta (src),y
.fldone
		tya
		sec
		adc <src
		sta <src
		lda <src + 1
		adc #0
		sta <src + 1
		cpx #$ff
		beq .flend_text				;end of page
find_line_lengths
		lda #$02
		sta <xl_
		ldy #$00
		sty <width
		clc
		bcc +
		;loop until C = 1 -> first $100 width reached
--
		adc <xl_
		sta <xl_
		iny
		bcs ++
+
		lax (src),y
		lda font_note_width,x
		lsr
		bne --

		cpx #$fe
		bcs .fldone
		sty <width
		lda #$03
		jmp --

		;remaining $40 to go
--
		adc <xl_
		sta <xl_
		iny
++
		cmp #$40		;fall through on first loop run and cmp does a clc
		bcs .fldone_
		lax (src),y
		lda font_note_width,x
		lsr
		bne --
		cpx #$fe
		bcs .fldone
		sty <width
		lda #$03
		jmp --
.flend_text
		lda <src
		cmp #<note_end
		bne find_line_lengths
		lda <src + 1
		cmp #>note_end
		bne find_line_lengths

		ldy #$00
		sty temp
		lda #<font_geos7
		sta <src + 0
		lda #>font_geos7
		sta <src + 1
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
		lda <src + 0
		clc
		adc #9
		sta <src + 0
		bcc +
		inc <src + 1
+
		inc temp
		lda temp
		cmp #$50
		bne ---
		lda #3		;space width
		sta font7_width + $20
		rts

		* = main

		jsr render_desktop
		lda #$00
		sta <xl
		lda #$00
		sta xh

		lda #<319
		sta xendl
		lda #>319
		sta xendh

		lda #14
		sta y
		lda #199
		sta yend


		lda #$01
		sta $d015

		jsr draw_outline
		lda #187
		sta y
		lda #198
		sta yend

		inc pattern
		inc <xl
		dec xendl
		jsr draw_box

		dec pattern
		lda #187
		sta y
		jsr draw_line_horizontal
		jsr setup_font_note

		lda #189
		sta y
		lda #<245
		sta <xl
		lda #>245
		sta xh
		lda #<cursor
		sta <src
		lda #>cursor
		sta <src + 1
		jsr draw_font7

		lda #<note
		sta <src
		lda #>note
		sta <src + 1

		ldx #$00
.redraw
		stx page_num
		txa
		lsr
		adc #1
double
		tay
		lax tabnum,y
		and #$0f
		ora #$30
		sta page + 1
		cpy #$0a
		bcc single
		txa
		lsr
		lsr
		lsr
		lsr
		ora #$30
		top
single
		lda #$20
		sta page + 0

		jsr draw_box_

		lda #187
		sta y
		lda <src + 1
		pha
		lda <src
		pha
		jsr draw_page_num

		ldx page_num
		pla
		sta <src
		sta page_ptr + 0,x
		pla
		sta <src + 1
		sta page_ptr + 1,x
		lda #<2
		sta <xl
		lda #>0
		sta xh
		lda #$10
		sta y
		jsr start_timer
		jsr draw_text_
		jsr stop_timer
-
		jsr scan
		txa
		beq -
		dex
		bne down
up
		lax page_num
		beq -
		sbx #2
		lda page_ptr + 0,x
		sta <src
		lda page_ptr + 1,x
		sta <src + 1
		jmp .redraw
down
		ldy #$00
		lax (src),y
		inx
		beq -
		lax page_num
		sbx #-2
		jmp .redraw
draw_page_num
		lda #<5
		sta <xl
		lda #>5
		sta xh

		lda #<20
		sta xendl
		lda #>20
		sta xendh

		lda #190
		sta y
		lda #198
		sta yend

		lda #$00
		sta pattern

		jsr draw_box

		lda #<page
		sta <src
		lda #>page
		sta <src + 1

		jsr draw_font7
		dec y
		rts

draw_box_
		lda #16
		sta y
		lda #186
		sta yend
		lda #<bitmap + 1 * $140 + 7
		sta dst
		lda #>bitmap + 1 * $140 + 7
		sta dst + 1
.loop_
		ldy #$00
		lda #$80
		sta (dst),y
		asl
	!for .x,1,31 {
		ldy #.x * 8
		sta (dst),y
	}
		inc dst + 1
	!for .x,0,6 {
		ldy #.x * 8
		sta (dst),y
	}
		ldy #$38
		lda #$01
		sta (dst),y
		dec dst + 1
		lax dst
		clc
		adc #1
		sta dst
		and #$07
		beq .inc_
		cmp #$03
		bne +
		lda dst + 1
		cmp #>bitmap + 23 * $140
		beq .out_
+
		jmp .loop_
.inc_
		lda dst
		clc
		adc #$38
		sta dst
		lda dst + 1
		adc #1
		sta dst + 1
		jmp .loop_
.out_
		rts


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
                sta <src
                lda #>disk_icon
                sta <src + 1
                jmp copy_icon
render_desktop
		lda #$00
		sta <xl
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

		ldx #$40
		jsr wait

		lda #$07
		sta $d015

		lda #$00
		sta <xl
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
		sta <xl
		lda #$00
		sta xh
		jsr draw_dotted_line
		lda #48
		sta <xl
		jsr draw_dotted_line
		lda #77
		sta <xl
		jsr draw_dotted_line
		lda #101
		sta <xl
		jsr draw_dotted_line
		lda #133
		sta <xl
		jsr draw_dotted_line
		lda #161
		sta <xl
		jsr draw_dotted_line

		lda #03
		sta y

		lda #4
		sta <xl
		lda #<geos
		sta <src
		lda #>geos
		sta <src + 1
		jsr draw_font7

		lda #33
		sta <xl
		lda #<file
		sta <src
		lda #>file
		sta <src + 1
		jsr draw_font7

		lda #53
		sta <xl
		lda #<view
		sta <src
		lda #>view
		sta <src + 1
		jsr draw_font7

		lda #82
		sta <xl
		lda #<disk
		sta <src
		lda #>disk
		sta <src + 1
		jsr draw_font7

		lda #106
		sta <xl
		lda #<select
		sta <src
		lda #>select
		sta <src + 1
		jsr draw_font7

		lda #138
		sta <xl
		lda #<page_
		sta <src
		lda #>page_
		sta <src + 1
		jsr draw_font7

		lda #166
		sta <xl
		lda #<options
		sta <src
		lda #>options
		sta <src + 1
		jsr draw_font7

		lda #$00
		sta pattern

		lda #$00
		sta y

		lda #220
		sta <xl
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
		sta <xl
		lda #<date
		sta <src
		lda #>date
		sta <src + 1
		jsr draw_font7

		lda #$00
		sta pattern

		lda #16
		sta y

		lda #143
		sta yend

		lda #8
		sta <xl
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
		sta <xl
		lda #139
		sta y
		jsr draw_line_horizontal
		lda #$08
		sta <xl
		lda #124
		sta y
		lda #23
		sta xendl
		lda #$00
		sta xendh
		jsr draw_line_horizontal

		lda #23
		sta <xl
		lda #139
		sta yend
		jsr draw_line_vertical

		lda #$08
		sta <xl
-
		jsr draw_dot
		inc <xl
		lda y
		inc y
		cmp yend
		bne -

		lda #116
		sta <xl
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
		sta <xl
		lda #18
		sta y
		lda #<system
		sta <src
		lda #>system
		sta <src + 1
		jsr draw_font7

		lda #240
		sta <xl
		lda #255
		sta xendl
		lda #17
		sta y
		lda #27
		sta yend
		lda #$ff
		sta pattern
		jsr draw_box

		inc <xl
		dec xendl
		inc y
		dec yend

		lda #$00
		sta pattern
		jsr draw_box

		lda #245
		sta <xl
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
		sta <xl
		lda #<_45_files
		sta <src
		lda #>_45_files
		sta <src + 1
		jsr draw_font7

		lda #62
		sta <xl
		lda #<_0_selected
		sta <src
		lda #>_0_selected
		sta <src + 1
		jsr draw_font7

		lda #114
		sta <xl
		lda #<_136_kbytes
		sta <src
		lda #>_136_kbytes
		sta <src + 1
		jsr draw_font7

		lda #193
		sta <xl
		lda #<_29_kbytes
		sta <src
		lda #>_29_kbytes
		sta <src + 1
		jsr draw_font7

		lda #136
		sta <xl
		lda #0
		sta xh
		lda #120
		sta  y
		lda #<_1
		sta <src
		lda #>_1
		sta <src + 1
		jsr draw_font7

		jsr ok_disk

		lda #<276
		sta <xl
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
		sta <xl
		lda #>282
		sta xh
		lda #<demo
		sta <src
		lda #>demo
		sta <src + 1
		jmp draw_text_

vsync
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		rts
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
		sta <src
		lda icon_data + 1,x
		sta <src + 1

		lda #$00
		sta pattern
		jsr copy_icon

		ldx .icon_num + 1
		lda icon_xl,x
		sta <xl
		lda icon_y,x
		sta y
		txa
		asl
		tax
		lda icon_text + 0,x
		sta <src
		lda icon_text + 1,x
		sta <src + 1
		jsr draw_text_

		ldy .icon_num + 1
		ldx icon_wait,y
		jsr wait

		iny
		sty .icon_num + 1
		cpy #$08
		bne -
		rts

setup_font_note
		lda #>font_note_height
		sta <.fheight_ + 2
		sta fheight0 + 2
		sta fheight1 + 2
		sta fheight2 + 2
		sta fheight4 + 2
		sta fheight5 + 2
		sta fheight6 + 2
		sta fheight7 + 2
		sta fheight1w + 2
		sta fheight2w + 2
		sta fheight3w + 2
		sta fheight4w + 2
		sta fheight5w + 2
		sta fheight6w + 2
		sta fheight7w + 2

		lda #>font_note_chr_ptr
		sta <.findex_l + 2
		sta findex_l0 + 2
		sta findex_l1 + 2
		sta findex_l2 + 2
		sta findex_l4 + 2
		sta findex_l5 + 2
		sta findex_l6 + 2
		sta findex_l7 + 2
		sta findex_l1w + 2
		sta findex_l2w + 2
		sta findex_l3w + 2
		sta findex_l4w + 2
		sta findex_l5w + 2
		sta findex_l6w + 2
		sta findex_l7w + 2

		lda #>font_note_chr_ptr_
		sta <.findex_h + 2
		sta findex_h0 + 2
		sta findex_h1 + 2
		sta findex_h2 + 2
		sta findex_h4 + 2
		sta findex_h5 + 2
		sta findex_h6 + 2
		sta findex_h7 + 2
		sta findex_h1w + 2
		sta findex_h2w + 2
		sta findex_h3w + 2
		sta findex_h4w + 2
		sta findex_h5w + 2
		sta findex_h6w + 2
		sta findex_h7w + 2
		;sta .findex_ + 2

		lda #>font_note_width_mul8
		sta <.width8 + 2

		lda #>font_note_width
		sta fwidth0 + 2
		sta fwidth1 + 2
		sta fwidth2 + 2
		sta fwidth7 + 2
		sta fwidth1w + 2
		sta fwidth7w + 2
		sta <fwidth + 2
		rts
icon_wait
		!byte 5,4,8,3,6,4,3,5
icon_xl
		!byte 200,155,101,40
		!byte 202,155,100,44
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

start_timer
                lda #$00
                sta $dd0e
                lda #$40
                sta $dd0f
                lda #$ff
                sta $dd04
                sta $dd05
                sta $dd06
                sta $dd07
                lda #$01
                sta $dd0e
                lda #$41
                sta $dd0f
                rts
stop_timer
                lda #$00
                sta $dd0e
                lda #$40
                sta $dd0f

                lda $dd04
                eor #$ff
                sta $0203
                lda $dd05
                eor #$ff
                sta $0202
                lda $dd06
                eor #$ff
                sta $0201
                lda $dd07
                eor #$ff
                sta $0200
                rts

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

		lda <xl
		pha
		lda xh
		pha
		lda y
		pha
		lda yend
		sta y

		jsr draw_line_horizontal

		lda xendl
		sta <xl
		lda xendh
		sta xh
		pla
		sta y
		jsr draw_line_vertical
		pla
		sta xh
		pla
		sta <xl
		rts
draw_dot
		ldx y
		lda <xl
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
		lda <xl + 0
		and #$07
		tax
		lda pixfont_,x
		and (dst),y
		sta (dst),y
		lda pattern
		and pixfont,x
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
		lda <src
		clc
		adc #$18
		sta <src
		bcc +
		inc <src + 1
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
		lda #$ff
		sta pattern
.df7_next
		ldy #$00
		sty font + 1
		lda (src),y
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
		adc #<font_geos7
		sta font
		lda font + 1
		adc #>font_geos7
		sta font + 1

		lda y
		pha
		lda font7_width,x
		sta .char7
--
.char7 = * + 1
		ldx #$00
		lda <xl
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
		inc <xl
		bne +
		inc xh
+
		dex
		bpl -
		inc y
		pla
		sta xh
		pla
		sta <xl
		iny
		cpy #$09
		bne --
		inc .char7
		inc .char7
		lda <xl
		clc
		adc .char7
		sta <xl
		lda xh
		adc #$00
		sta xh
		pla
		sta y
		inc <src
		bne +
		inc <src + 1
+
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
		rts
musicirq
		pha
		txa
		pha
		tya
		pha
		dec $d019
		jsr music + 3
		pla
		tay
		pla
		tax
		pla
		rti

tabnum
!for .x,0,99 {
		!byte .x % 10 + (.x / 10) * 16
}
page
		!byte $20,$20,$00
cursor
		!scr "cursor up/down"
		!byte 0
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
page_
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
system
		!scr "System"
		!byte 0

csdb
		!scr "CSDb"
		!byte $ff
porn
		!scr "PORN"
		!byte $ff
dasm
		!scr "DASM"
		!byte $ff
demo_plans
		!scr "Demo plans"
		!byte $ff
bitfire
		!scr "BITFIRE"
		!byte $ff
dali
		!scr "DALI"
		!byte $ff
acme
		!scr "ACME"
		!byte $ff
bob_spycam
		!scr "Bob spycam"
		!byte $ff
_1
		!byte $31, $00

date
		!scr "06/03/23 13:37 PM"
		!byte $00
demo
		!scr "DEMO:"
		!byte $ff


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
		lda <xl + 0
		eor #$07
		sax pixs
		lda xendl
		sax pixe
		lda xendl
+
		sec
		sbc <xl
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

		ldx y
		lda <xl
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
pixfont
		!byte $80,$40,$20,$10,$08,$04,$02,$01
pixfont_
		!byte $7f,$bf,$df,$ef,$f7,$fb,$fd,$fe




!align 255,0
shift0
		+shift 0, ~findex_h0, ~fwidth0, ~fheight0, ~findex_l0
shift1
		+shift 1, ~findex_h1, ~fwidth1, ~fheight1, ~findex_l1
shift2
		+shift 2, ~findex_h2, ~fwidth2, ~fheight2, ~findex_l2
shift4
		+shift 4, ~findex_h4, ~fwidth4, ~fheight4, ~findex_l4
shift5
		+shift 5, ~findex_h5, ~fwidth5, ~fheight5, ~findex_l5
shift6
		+shift 6, ~findex_h6, ~fwidth6, ~fheight6, ~findex_l6
!align 255, 0
shift7
		+shift 7, ~findex_h7, ~fwidth7, ~fheight7, ~findex_l7

shift1_w
		+shift2 1, ~findex_h1w, ~fwidth1w, ~fheight1w, ~findex_l1w
shift2_w
		+shift2 2, ~findex_h2w, ~fwidth2w, ~fheight2w, ~findex_l2w
shift3_w
		+shift2 3, ~findex_h3w, ~fwidth3w, ~fheight3w, ~findex_l3w
!align 255, 0
shift4_w
		+shift2 4, ~findex_h4w, ~fwidth4w, ~fheight4w, ~findex_l4w
shift5_w
		+shift2 5, ~findex_h5w, ~fwidth5w, ~fheight5w, ~findex_l5w
shift6_w
		+shift2 6, ~findex_h6w, ~fwidth6w, ~fheight6w, ~findex_l6w

!align 255,0
!warn "tabl ",*
bitmap_tabl
!for .x,0,24 {
		!byte <(bitmap + .x * $140)
		!byte <(bitmap + .x * $140)
		!byte <(bitmap + .x * $140)
		!byte <(bitmap + .x * $140)
		!byte <(bitmap + .x * $140)
		!byte <(bitmap + .x * $140)
		!byte <(bitmap + .x * $140)
		!byte <(bitmap + .x * $140)
}
!align 255,0
bitmap_tabh
!for .x,0,24 {
		!byte >(bitmap + .x * $140)
		!byte >(bitmap + .x * $140)
		!byte >(bitmap + .x * $140)
		!byte >(bitmap + .x * $140)
		!byte >(bitmap + .x * $140)
		!byte >(bitmap + .x * $140)
		!byte >(bitmap + .x * $140)
		!byte >(bitmap + .x * $140)
}
!align 255,0

;XXX TODO umbau auf diese Tabellen statt statischer Höhe/Ypos
;später wenn das geht, Tabellen auffüllen und belegen für mehr Performance

;add_tab
;		!byte $f0,$f1,$f2,$f3,$f4,$f5,$f6,$f7,$f8.$f9,$fa,$fb,$fc,$fd,$fe,$ff	$f0


font_note_height
	!fill 256,0
font_note_chr_ptr
!for .x,0,255 {
		!byte <(font_note + .x * 8)
}
font_note_chr_ptr_
!for .x,0,255 {
		!byte >(font_note + .x * 8)
}
font_note_width
	!fill 256,0
font_note_width_mul8
	!fill 256,0


font5_height
	!fill 256,0
font5_chr_ptr
!for .x,0,255 {
		!byte <(font_geos5 + .x * 8)
}
font5_chr_ptr_
!for .x,0,255 {
		!byte >(font_geos5 + .x * 8)
}

font5_width
	!fill 256,0
font5_width_mul8
	!fill 256,0

font7_width
	!fill 256,0

shift2l
!for .x,0,255 {
		!byte <(.x << 2)
}
shift3l
!for .x,0,255 {
		!byte <(.x << 3)
}
shift4l
!for .x,0,255 {
		!byte <(.x << 4)
}
shift5l
!for .x,0,255 {
		!byte <(.x << 5)
}
shift6l
!for .x,0,255 {
		!byte <(.x << 6)
}

shift3r
!for .x,0,255 {
		!byte <(.x >> 3)
}
shift4r
!for .x,0,255 {
		!byte <(.x >> 4)
}
shift5r
!for .x,0,255 {
		!byte <(.x >> 5)
}
shift6r
!for .x,0,255 {
		!byte <(.x >> 6)
}
!warn "plus8tab ",*
plus8tab
!for .x,0,31 {
		!byte <((.x + 1) * 8)
		!byte <((.x + 1) * 8)
		!byte <((.x + 1) * 8)
		!byte <((.x + 1) * 8)
		!byte <((.x + 1) * 8)
		!byte <((.x + 1) * 8)
		!byte <((.x + 1) * 8)
		!byte <((.x + 1) * 8)
}
!align 255,0

font_note
!bin "font_note.chr",32*8,224*8
!bin "font_note.chr",32*8,160*8
!bin "font_note.chr",32*8,192*8
!fill 32*8,0
!bin "font_note.chr",32*8,96*8
!bin "font_note.chr",32*8,32*8
!bin "font_note.chr",32*8,64*8

.shifttab
		!word space,  shift1  , shift2  , shift3  , shift4  , shift5  , shift6  , shift7
		!word shift0, shift1  , shift2  , shift3  , shift4  , shift5  , shift6  , shift7_w
		!word shift0, shift1  , shift2  , shift3  , shift4  , shift5  , shift6_w, shift7_w
		!word shift0, shift1  , shift2  , shift3  , shift4  , shift5_w, shift6_w, shift7_w
		!word shift0, shift1  , shift2  , shift3  , shift4_w, shift5_w, shift6_w, shift7_w
		!word shift0, shift1  , shift2  , shift3_w, shift4_w, shift5_w, shift6_w, shift7_w
		!word shift0, shift1  , shift2_w, shift3_w, shift4_w, shift5_w, shift6_w, shift7_w
		!word shift0, shift1_w, shift2_w, shift3_w, shift4_w, shift5_w, shift6_w, shift7_w

font_geos5
!for .x,0,255 {
!bin "font5.chr",8,.x * 8
}

font_geos7
	!byte %00000000
	!byte %00000000
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

scan
		ldx #$00

		lda #%11111111
		sta DDRA

		lda #%00000000
		sta DDRB

		;crsr down
		lda #%11111110
		sta PRA

		lda PRB
		and #%10000000
		beq +
		rts
+
		ldx #$02

		;shift left
		lda #%11111101
		sta PRA

		lda PRB
		and #%10000000
		beq +

		;shift right
		lda #%10111111
		sta PRA

		lda PRB
		and #%00010000
		bne ++
+
		ldx #1
++
		rts
page_ptr
		!fill 256,0

!macro newline {
		!byte $fe
}
!macro newpage {
		!byte $ff
}
!macro bold .string {
!ct "bold.ct" { !tx .string }
}
note
!ct "bold.ct"
		!tx "Welcome to the note!"
		!byte $fe
		!byte $fe
		!scr "You are about to "
		!tx "ruin "
		!scr "your eyes with that tiny ugly font. Our pleasure! :-D "
		!byte $fe
		!scr "After C-Bit '18 we sat together to have a look on our leftovers, prototypes and ideas, a few new parts emerged from that and while pondering on the team to do this project with, "
		!scr "we came back to our old group Oxyron. They were about to celebrate their 30th anniversary, so this would have been called 30 years Oxyron initially. "
		!scr "After an attempt to pull this project off with our old groupmates, it turned out that they are just a bunch of dead zombies, and so we gave up on that and regathered the old dream team of "
		!scr "PERFORMERS!"
		!byte $fe
		!scr "Back in October also the so called Pumpkins, a loose bunch of unskilled coders and other jobless creatures emerged, with their only goal, to piss on our fame."
		!byte $fe
		!byte $fe
		!tx "It is time to strike back!"
		!byte $fe
		!byte $fe
		!scr "In fact, we are happy to compete at X with so many awesome other groups and are happy to drink beer with you!"
		!byte $ff

		!scr "Quite some years have passed since we released a demo, but we were not dead or lazy, just busy with creating new astonishing parts and effects. After C=Bit'18 Axis and me (Bitbreaker) came up with the idea of doing a shadow scroller. We first did jokes on each other, as we did not believe it would be possible. Then Axis and me came up with a bunch of tries and prototypes to finally try it, but failed for 2 years. In the end i managed to get a first prototype up and running and it turned out it will be able to do all stuff needed in 50fps."
		!byte $fe
		!scr "I concentrated then on improving bitfire and bring it to the next level, meanwhile demos from the Seniors and Pumpkins emerged and i noticed the puns towards Performers there. I was all out and about to do some jokes on those groups, when suddely after an invitation Trap popped up in our slack. That opened a lot more funny ideas and gave us the chance to have also access to their graphician Facet who deliveres at light speed and made another pun possible. The mighty hunter got our fanboy! :-D"
		!byte $fe
		!byte $fe
		!scr "Now for some elaborate credits, we all deserved the praise for sweating blood!"
		!byte $ff

		!tx "Credits Side 1:"
		!byte $fe
		!byte $fe

		!tx "Basic Fadeout (vortex)"
		!byte $fe
		!scr "Code: YPS"
		!byte $fe
		!scr "GFX: YPS"
		!byte $fe
		!scr "Music: dEViLOCk"
		!byte $fe
		!scr "Let's schwurbel the shit out of this machine while doing heavy loading to fire off this demo."
		!byte $fe
		!byte $fe

		!tx "Performers Intro (intro)"
		!byte $fe
		!scr "Code: Peiselulli"
		!byte $fe
		!scr "GFX: Facet"
		!byte $fe
		!scr "Music: dEViLOCk"
		!byte $fe
		!scr "Transitions with hunter: Bitbreaker"
		!byte $fe
		!scr "Peiselulli sweat a lot on this part, sprite multiplexing galore, priority clashing, bitmap copy, all needed to be sewed together nicely. Now all traumatic experience from the past is ceased and cured! :-D"
		!byte $ff

		!tx "Make some noise for Performers (makenoise)"
		!byte $fe
		!scr "Code: THCM, Plotter: Bitbreaker"
		!byte $fe
		!scr "GFX: Joe, NUFLI fix: Deekay"
		!byte $fe
		!scr "Loadingmusic/Speech: LMan"
		!byte $fe
		!scr "Time to bring NUFLI to a next level, there's all kind of sprite, switch, FLI and DMA-action going on each rasterline while consuming vast memory? No problem, let's still squeeze in samples and a plotter!"
		!byte $fe
		!byte $fe
		!tx "Credits (banzai)"
		!byte $fe
		!scr "Code: THCM"
		!byte $fe
		!scr "GFX: Facet"
		!byte $fe
		!scr "Music: Jammer"
		!byte $fe
		!scr "Vivid gaming action, smooth and fast scrolling with parallaxing clouds, samples, what else could you ask for?"
		!byte $fe
		!byte $fe

		!tx "Greetings (greetings)"
		!byte $fe
		!scr "Code: THCM"
		!byte $fe
		!scr "GFX: Veto"
		!byte $fe
		!scr "Music: dEViLOCk"
		!byte $fe
		!scr "Greetings go out to all the sceners spread over this world, thus a world map is the best base."
		!byte $ff

		!tx "Spaceship pic (Gekkigheid)"
		!byte $fe
		!scr "Code: Yps"
		!byte $fe
		!scr "GFX: Facet"
		!byte $fe
		!scr "Music: dEViLOCk"
		!byte $fe
		!scr "Another yet unseen piece of art from Facet."
		!byte $fe
		!byte $fe

		!tx "Noisefader (noisefader)"
		!byte $fe
		!scr "Code: Mahoney"
		!byte $fe
		!scr "GFX: Mahoney, redcrab"
		!byte $fe
		!scr "Font: redcrab"
		!byte $fe
		!scr "Music: dEViLOCk"
		!byte $fe
		!scr "Make some noiiiiisefader, mothafucka! 2 layers blending softly, wait, was there some secret message in that glitchframe in between? Oh, look, there's a scroller in the lower border and it looks like more than 8 sprites!"
		!byte $ff

		!tx "Textrotator / Turn Disk (textrotator)"
		!byte $fe
		!scr "Code: Mahoney"
		!byte $fe
		!scr "GFX: Mahoney"
		!byte $fe
		!scr "Font: redcrab"
		!byte $fe
		!scr "Music: dEViLOCk"
		!byte $fe
		!scr "It spins, it rotates, but it does not spin meat, it is pure code-beef!"
		!byte $fe
		!byte $fe

		!tx "Lazy Torus (lazy)"
		!byte $fe
		!scr "Code: David Whittaker, Mahoney"
		!byte $fe
		!scr "GFX: David Whittaker, Mahoney"
		!byte $fe
		!scr "Music: Mahoney"
		!byte $fe
		!scr "The mighty torus is breaking all borders! And love is there to see through it all."
		!byte $ff

		!tx "Credits Side 2:"
		!byte $fe
		!byte $fe

		!tx "100-best-moments-of-our-lives (overload)"
		!byte $fe
		!scr "Code: Mahoney"
		!byte $fe
		!scr "GFX: Mahoney"
		!byte $fe
		!scr "Add. code: Krill (petscii during stay a while)"
		!byte $fe
		!scr "100 games pure nostalgia and childhood memories packed for you onto a single disk side, this parts stays a while, stays forever!"
		!byte $fe
		!byte $fe
		!tx "Geos / Turn Disk (geos)"
		!byte $fe
		!scr "Code: Bitbreaker"
		!byte $fe
		!scr "GFX: Bitbreaker"
		!byte $fe
		!scr "Sprites: redcrab"
		!byte $fe
		!scr "Music: Jammer"
		!byte $fe
		!scr "Must be some evil villain who is on the controls here, downvoting Performers, sabotaging Bonzai by deleting their demo plans and spying on Censor. Better turn the disk fast to stop the evil deeds!"
		!byte $ff

		!tx "Credits Side 3:"
		!byte $fe
		!byte $fe

		!tx "Faithless (faithless)"
		!byte $fe
		!scr "Code: THCM"
		!byte $fe
		!scr "GFX: Deekay"
		!byte $fe
		!scr "Music: Jammer"
		!byte $fe
		!scr "This starts so with those wellknown chords, but then, wait, there's a jump in quailty out of a sudden? Samples and some oldschool screen action with moving logos, rasterbars and a scroller."
		!byte $fe
		!byte $fe

		!tx "Volume Up Transition"
		!byte $fe
		!scr "Code: Bitbreaker"
		!byte $fe
		!scr "GFX: Bitbreaker"
		!byte $fe
		!scr "Music: Linus"
		!byte $fe
		!scr "We need to load music and a whole next demopart, so let's keep the attraction level high. Smart overlay enables a broader display than 8 sprites."
		!byte $ff

		!tx "Bobby (bobvector)"
		!byte $fe
		!scr "Code: Bitbreaker"
		!byte $fe
		!scr "GFX: Deekay"
		!byte $fe
		!scr "Music: Linus"
		!byte $fe
		!scr "Transitions: Bitbreaker"
		!byte $fe
		!scr "98 bobs build one cube. Though it might appear swedish, it is done by ze krauts. Pumpkins can't even do proper poking with lda/sta as you can see, eat this!"
		!byte $fe
		!byte $fe

		!tx "Shadowscroller (shadow)"
		!byte $fe
		!scr "Code: Bitbreaker"
		!byte $fe
		!scr "GFX: Bitbreaker"
		!byte $fe
		!scr "Font: ptoing"
		!byte $fe
		!scr "Sprites: redcrab"
		!byte $fe
		!scr "Music: Linus"
		!byte $fe
		!scr "This part is already a few years old, but now finally brought onto stage for showtime. A lot of emotional color-discussions emerged with it. The scroller can render any char's shadow, the respective lines are stretched by permamanent pixel stuffing which creates also those nice moire-patterns. Sheering plus stretching does the rest. It is close to frameskip, but 50fps. Sorry for scrolling slow."
		!byte $ff

		!tx "Nonconvex Vectors (Sierpinsky)"
		!byte $fe
		!scr "Code: Axis"
		!byte $fe
		!scr "GFX: Deekay"
		!byte $fe
		!scr "Music: Linus"
		!byte $fe
		!scr "Transitions: Bitbreaker"
		!byte $fe
		!scr "This part started as Oxyron part, a lot of nagging and convincing was needed, but now this is a gem, all realtime, and did i already mention that all is done realtime? Thanks to Axis to make this possible! :-)"
		!byte $fe
		!byte $fe

		!tx "Schwurbel (schwurbel)"
		!byte $fe
		!scr "Code: Peiselulli"
		!byte $fe
		!scr "GFX: Deekay"
		!byte $fe
		!scr "Sprites: redcrab"
		!byte $fe
		!scr "Music: Linus"
		!byte $fe
		!scr "FPP action with ECS and HIRES mixed up. Memory fragmented by charsets as much as possible. :-)"
		!byte $ff

		!tx "Ribbons (ribbons)"
		!byte $fe
		!scr "Code: Bitbreaker"
		!byte $fe
		!scr "GFX: Veto"
		!byte $fe
		!scr "Music: Linus"
		!byte $fe
		!scr "8 stretched sprite ribbons, moving, with different colors on backside over a koala picture, well, with some not so obvious limitation."
		!byte $fe
		!byte $fe

		!tx "Meatballs (metaballs)"
		!byte $fe
		!scr "Code: Knut"
		!byte $fe
		!scr "GFX: Knut"
		!byte $fe
		!scr "Sprites: redcrab"
		!byte $fe
		!scr "Music: Linus"
		!byte $fe
		!scr "Transition: Bitbreaker"
		!byte $fe
		!scr "Meatballs and metaballs are just a typo away from each other. They are smooth, they are fast, this is the way to Kottbullar!"
		!byte $ff

		!tx "Double Vector (doublevec)"
		!byte $fe
		!scr "Code: Bitbreaker"
		!byte $fe
		!scr "GFX: Deekay"
		!byte $fe
		!scr "Objects: Bitbreaker"
		!byte $fe
		!scr "Music: Linus"
		!byte $fe
		!scr "Double the vector, twice the fun! We have seen those 16x16 grid vectors, oh, wait, there's a second one. Glued together in different ways we can get all kind of colorful objects. The renderer can render a sprite and charset-layer. Note that each layer clips nicely on any border!"
		!byte $fe
		!byte $fe

		!tx "Shrine Hunter / Turn Disk (hunter)"
		!byte $fe
		!scr "Code: Bitbreaker"
		!byte $fe
		!scr "GFX: Facet"
		!byte $fe
		!scr "Music: Linus"
		!byte $fe
		!scr "As facet joined forces, the mighty hunter got our new fanboy, he is now following his new God and guidance: Performers"
		!byte $ff

		!tx "Credits Side 4:"
		!byte $fe
		!byte $fe

		!tx "Transbox"
		!byte $fe
		!scr "Code: Trap"
		!byte $fe
		!scr "Music: Jammer"
		!byte $fe
		!scr "Trap's debut for Performers, welcome to slavery!"
		!byte $fe
		!byte $fe

		!tx "2pixel Scroller"
		!byte $fe
		!scr "Code: Knut"
		!byte $fe
		!scr "GFX: Joe"
		!byte $fe
		!scr "Music: Jammer"
		!byte $fe
		!scr "We have seen many sCRAWLers in the past, pushing around Koala with 1px per frame or even less. Time to speed this up to 2px per frame!"
		!byte $fe
		!byte $fe

		!tx "Vertical Scroller"
		!byte $fe
		!scr "Code: Knut"
		!byte $fe
		!scr "GFX: Prowler (stam), Redcrab (logo)"
		!byte $fe
		!scr "Music: Jammer"
		!byte $fe
		!scr "And just because we can, we all of a sudden split up and go vertical and parallax!"
		!byte $ff

		!tx "The thievish eagle"
		!byte $fe
		!scr "Code: Bitbreaker"
		!byte $fe
		!scr "GFX: Redcrab"
		!byte $fe
		!scr "Music: Jammer"
		!byte $fe
		!scr "And again another yet unseen piece of art from redcrab. This eagle stole disk, now the hunting continues and demo ends. :-/"
		!byte $fe
		!byte $fe

		!tx "Endpart (endpart)"
		!byte $fe
		!scr "Code: THCM"
		!byte $fe
		!scr "GFX: Veto"
		!byte $fe
		!scr "Music: LMan"
		!byte $fe
		!scr "Game over! But let's still celebrate what we achieved and take the party to the next level! Did i just spot some suspects from other demos?!"
		!byte $fe
		!byte $fe
		!tx "Testing"
		!byte $fe
		!scr "Ikwai did a a crazy amount of testing, copying over disk-images to real floppy disks, watching the daily builds on all kind of machines and hardware. He helped debugging down to signal tracing and grabbing all action on bus by a logic analyzer, helping to tackle down bugs we had with old/new CIAs. This is so awesome!"
		!byte $ff

		!tx "Note"
		!byte $fe
		!scr "Code: Bitbreaker"
		!byte $fe
		!scr "GFX: Bitbreaker"
		!byte $fe
		!scr "Sprites: redcrab"
		!byte $fe
		!scr "Font: Retrofan"
		!byte $fe
		!scr "Music: Jammer"
		!byte $fe
		!scr "Text: $randompeople"
		!byte $fe
		!scr "The text renderer from the geos part was taken to the next level, maybe noone will even notice the speed, but it was fun to do so. First page renders in 10 frames."
		!byte $fe
		!byte $fe
		!tx "Tools"
		!byte $fe
		!scr "SplineEd: THCM"
		!byte $fe
		!scr "Char converter: Bitbreaker"
		!byte $fe
		!scr "Sprite converter: Bitbreaker"
		!byte $fe
		!scr "Mufflon: Bitbreaker"
		!byte $fe
		!scr "Bitfire: Bitbreaker"
		!byte $fe
		!byte $fe
		!tx "Finally, how transition work and linking feels like doing just a second demo on top in the end! :-)"
		!byte $ff



		!tx "Ode to the Noble Commodore 64"
		!byte $fe
		!byte $fe
		!scr "When, in the midst of Time's swift race,"
		!byte $fe
		!scr "Did mortals first spy Cyberspace,"
		!byte $fe
		!scr "And in their humble dwellings brought"
		!byte $fe
		!scr "Machines to weave their cyber-thought?"
		!byte $fe
		!scr "From whence did spring this wond'rous beast,"
		!byte $fe
		!scr "This great enabler of the least,"
		!byte $fe
		!scr "Which now in every corner dwells,"
		!byte $fe
		!scr "From city scapes to country fells?"
		!byte $fe
		!scr "'Twas Commodore, that mighty source,"
		!byte $fe
		!scr "Whence our first cyber-steed did course."
		!byte $fe
		!byte $fe

		!scr "Hail, Commodore! Thou potent sage,"
		!byte $fe
		!scr "Whose wisdom spans the cyber age,"
		!byte $fe
		!scr "Thy humble frame, a treasury"
		!byte $fe
		!scr "Of knowledge vast, didst set us free."
		!byte $fe
		!scr "Thy sixty-four, a magic sum,"
		!byte $fe
		!scr "Which did the minds of men become,"
		!byte $fe
		!scr "A number now with reverence spake,"
		!byte $fe
		!scr "Which didst the cyber kingdom make."
		!byte $ff

		!scr "Within thy visage, hues of blue"
		!byte $fe
		!scr "And white didst mingle, secrets true"
		!byte $fe
		!scr "To share with all who ventured near,"
		!byte $fe
		!scr "And dared thy mystic code to hear."
		!byte $fe
		!scr "Thy keyboard, like a lute, didst sing,"
		!byte $fe
		!scr "And to our ears, sweet music bring,"
		!byte $fe
		!scr "Whilst in thy depths, a world revealed,"
		!byte $fe
		!scr "Where once were truths and dreams concealed."
		!byte $fe
		!byte $fe

		!scr "O noble sprite! How oft we roamed"
		!byte $fe
		!scr "Through lands where pixels brightly bloomed,"
		!byte $fe
		!scr "Where sprites and lines did dance and play,"
		!byte $fe
		!scr "And 'cross thy screen, their stories lay."
		!byte $fe
		!scr "Thy SID chip, like a siren's call,"
		!byte $fe
		!scr "Didst weave a spell o'er one and all,"
		!byte $fe
		!scr "And in thy code, a world beguiled,"
		!byte $fe
		!scr "Where art and science sweetly smiled."
		!byte $ff

		!scr "Alas, the march of Time proceeds,"
		!byte $fe
		!scr "And newer steeds do fill our needs,"
		!byte $fe
		!scr "Yet still, dear Commodore, we find,"
		!byte $fe
		!scr "In mem'ry's vault, thy place enshrined."
		!byte $fe
		!scr "For thou, the first to bear us hence,"
		!byte $fe
		!scr "To realms of cyber eloquence,"
		!byte $fe
		!scr "Shall ever live, in honour's hall,"
		!byte $fe
		!scr "The greatest cyber steed of all."
		!byte $fe
		!byte $fe

		!scr "So let us raise our voices high,"
		!byte $fe
		!scr "To Commodore, the first to fly"
		!byte $fe
		!scr "Upon the winds of Cyberspace,"
		!byte $fe
		!scr "And sing the praises of its grace:"
		!byte $fe
		!scr "For though the years may fade away,"
		!byte $fe
		!scr "Thy mem'ry lives, and shall not sway,"
		!byte $fe
		!scr "As long as hearts remember thee,"
		!byte $fe
		!scr "O Commodore, our liberty!"
		!byte $ff
		!tx "Some personal messages for you to enjoy!"
		!byte $fe
		!byte $fe
		!tx "Jammer:"
		!byte $fe
		!scr "my soul is empty - i have nothing to share xD"
		!byte $fe
		!byte $fe
		!tx "Mahoney:"
		!byte $fe
		!scr "The high resolution borderscroller during the noisefader and textrotator parts was drawn by redcrab. It was inspired by Adam \"Trident\" Dunkel's presentation at Fjalldata 2023. Coded by Pex Mahoney Tufvesson, based on ghostbytes, sprite shine through, rasterbars and multicolour."
		!byte $fe
		!scr "That was a bit too boring, wasn't it? I want to write scrolltexts again! Noters, for me is a too modern way of telling things. So if you'd really like to read up on what's cooking, load the next level demo and just don't insert disk 2, keep reading my scrolltext there instead! Take care! /Pex"
		!byte $fe
		!byte $fe
		!tx "Knut:"
		!byte $fe
		!scr "Thanks to Bitbreaker for help and ideas with optimising, and thanks to the whole team for letting me be a part of this. (I'm not much of a scroll text writer)"
		!byte $ff

		!tx "Bitbreaker:"
		!byte $fe
		!scr "Thanks to "
		!tx " The Human Code Machine "
		!scr "for buggering me so many many times to double the vectors, despite all my excuses and concerns. I felt like i couldn't been arsed to bring this to the next level and did though in the end. Also thanks for the endlessly and tedious testing of all my broken bitfire trials end for keeping calm when i preferred optimizing the note text renderer instead of doing urgently needed work for the demo :-D So over all human should be underlined in his handle. <3"
		!byte $fe
		!scr "Thanks to"
		!tx " Mahoney "
		!scr "for tolerating my rough and sometimes rude habits and for welcoming me to fiddle around in his code, thanks also for giving me confidence that we will finish in time. :-)"
		!byte $fe
		!scr "Thanks to"
		!tx " Redcrab "
		!scr "for the many inspiring chats and inisghts to his work as book artist!"
		!byte $fe
		!scr "Thanks to"
		!tx " Peiselulli "
		!scr "for allowing me to vaporize his concerns on the intro part, it turned out great in the end and you managed to get further than you expected with adding all the extra wishes! :-)"
		!byte $fe
		!scr "Thanks to"
		!tx " Jammer "
		!scr "for all the funny chats, dirty thoughts, snickering and blazing fast work and response you give! There's already new creative ideas to think and work on after this demo! :-)"
		!byte $ff
		!scr "Thanks to"
		!tx " Trap "
		!scr "for appearing with a popping sound to the project, we had many deep chats and found out a lot of things we have in common. Would have loved to work together more with you!"
		!byte $fe
		!scr "Thanks to"
		!tx " Facet "
		!scr "for really kind of rescuing this project graphics-wise. You are a pixel-machine and you know it! I know that you also had made you experience and learned new stuff about drawing with very certain limitations and restrictions. :-)"
		!byte $fe
		!scr "Thanks to"
		!tx " dEViLOCk "
		!scr "for caring about my constant rant and whining about SDI. :-)"
		!byte $fe
		!scr "Thanks to"
		!tx " Knut "
		!scr "for all the nice talks, for bringing the idea of camping in Norway closer to me, for sharing stories about fossils! :-)"
		!byte $fe
		!scr "Thanks to"
		!tx " Axis "
		!scr "for finally contributing his non-convex vector-part, working together with you always feels like a dream team, which peaked in Comaland. Hope we can grill some dozends of sausages again at the Nordlicht-BBQ, a bit sad that your life drifts away from demoscene in the past."
		!byte $fe
		!scr "Thanks to"
		!tx " all those "
		!scr "who are not named directly, you did as much of an awesome contribution to this demo, just that we had not that intense contact in the end to write something more personal here. :-)"
		!byte $ff

		!tx "Linus:"
		!byte $fe
		!scr "You don't want to hear my personal story, it's a mess, damnit! :)"
		!byte $fe
		!scr "The demo is OK! I am very proud of it and... damn, I can't read my own cheat sheet... you're an amazing crowd."
		!byte $fe
		!byte $fe
		!tx "Redcrab:"
		!byte $fe
		!scr "You actually WERE found in a wicker basket by your grandma druglord?"
		!byte $fe
		!scr "It's been a total blast working on this. This really is a demo to be proud of! Except for that hidden porn part - I still can't believe it."
		!byte $fe
		!byte $fe
		!tx "dEViLOCk:"
		!byte $fe
		!scr "Fuckings to rastertime. Thanx to THCM, faker and GRG for patience and fixing problems with countless compiled tune previews. And ! Covert Bitops make an Apple silicon build of goattracker with HardSID USB support. Prettyyyy pleaaaaase now!!!"
		!byte $ff

		!tx "THCM:"
		!byte $fe
		!scr "Thx guys!!! That was one hell of a ride!"   
		!byte $fe
		!scr "Never thought that we could push the limits once again to the NEXT LEVEL! Some Performers were sadly missing this time, but others came to the rescue and filled the missing spots. I hope that you're still around for the next demo." 
		!byte $fe
		!byte $fe
		!scr "My personal thx go to:"
		!byte $fe
		!byte $fe
		!tx "Facet:"
		!scr " For coming out of nowhere and pixeling your ass off for us."
		!byte $fe
		!tx "Joe:"
		!scr " For delivering on time and enduring endless pain finishing the NUFLI picture."
		!byte $fe
		!tx "Veto:"
		!scr " For keeping your promise and getting things done right before the party. Nevertheless I hope your still proud of your work."
		!byte $fe
		!tx "LMan:"
		!scr " For being professional and as always delivering top notch ThcMOD magic."
		!byte $fe
		!tx "Deekay:"
		!scr " For doing the unusual stuff with special restrictions and limitations."
		!byte $fe
		!tx "Jammer:"
		!scr" For being our Swiss Army knife musician."
		!byte $fe
		!tx "Mahoney:"
		!scr" For simply being Mahoney and always having weird ideas which turn into wonderful parts!"
		!byte $ff
		
		!tx "redcrab:"
		!scr" For your lovely NEXT LEVEL logo and helping out with lots of small things even as you said you had no time."
		!byte $fe
		!tx "YPS:"
		!scr" For being our basic fadeout master. Hope to see some real demo parts from you soon."
		!byte $fe
		!tx "Ikwai:"
		!scr" For testing our demo in a way nobody ever thought of."
		!byte $fe
		!tx "Linus:"
		!scr" For bringing your talent and coming out with such a marvelous soundtrack."
		!byte $fe
		!tx "Krill:"
		!scr" For your ongoing criticism letting Waldorf and Statler looking like greenhorns!"
		!byte $fe
		!tx "dEViLOCk:"
		!byte $fe
		!scr"For another great soundtrack and not spending too much raster time!"
		!byte $fe
		!tx "Knut:"
		!byte $fe
		!scr"For being on the team and doing more then we hoped. You don't have to do everything alone anymore..."
		!byte $fe
		!tx "Axis:"
		!byte $fe
		!scr"For your ace realtime part. We miss you... hope to see you at Nordlicht!"
		!byte $fe
		!tx "Peiselulli:"
		!byte $fe
		!scr"For doing more than expected. You are definitly our sprite fiddling timing expert! Cheers!"
		!byte $fe
		!tx "Prowler:"
		!byte $fe
		!scr"For your excellent last minute work! We want more..."
		!byte $ff

		!scr "My special thanks goes to"
		!tx " Bitbreaker"
		!scr " for being our firefighter and always nagging around getting things done!"
		!byte $fe
		!byte $fe
		!scr "Being master of tool chains... (literally)... :-)"   
		!byte $fe
		!byte $fe
		!scr "...and don't forget: We are "
		!tx "PERFORMERS!!!"
		!byte $fe
		!byte $fe
		!byte $fe
		!byte $fe
		!byte $fe

		!tx "And always remember:"
		!byte $fe
		!scr "If you're happy and you know it, overthink"
		!byte $fe
		!scr "If you're happy and you know it, overthink"
		!byte $fe
		!scr "If you're happy and you know it,"
		!byte $fe
		!scr "give your brain a chance to blow it."
		!byte $fe
		!scr "If you're happy and you know it, overthink."
		!byte $ff
		
		!byte $ff
note_end

