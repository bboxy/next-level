;XXX TODO try to do things with a single lookup?
;cxxxyyy.
;-> 1/2 columns, 3 bit x shift for correct bob data selection, y for correct y shift -> depending on and/ora clear for current char
;check if 1/2 chars high? how? mybe use 8th bit for that?
;other positions: place in second stream byte? -> lookup via tables to get scr + 0 and scr + 1
;256 chunks? a bit much?
;check beforehand and copy 8+8 8+0 0+8 0+0 bytes?


;todo
;optimize some stuff like shifting (tables?) and so on

;provide data as delta, maybe with matches? -> y/x can be stored, so provide severall precaled lines + tabs that increase size as a line? (non linear) so quadarants and x/y can be mirrored
;would save data and enable 9 bit x resolution, check on end of line for clipping
;also check if data can be processed easily or if gay things are done already due to optimizations
;size 1: use one of 64 preset chars first, on and case: copy over char if one of preset chars and do an and


;XXX TODO charsets only partly used, can place stuff there


;$20 hohe charsets

;-> davor test, ob char noch in chunk passt. -> y - size darf nicht negativ sein, falls doch: malen bis negativ (einfach passend in eine unrolled loop einspringen und dann nochmal für den rest?) sonst komplett kopieren bis ycounter < 0 ?
;how to clear?

; ypos + size -> ystart
; ystart & 7 -> first chunk, size -= ystart & 7
; while size > 7 size -= 8, ystart = 7 -> full block copy
; else ystart = 7 und rest von size = laufzeit
; je block: screen kopieren oder ora? rest von chars dann aber auch noch löschen?
; mehrere spalten kopieren jede spalte kann aber anders sein im handling :-(
; immer max 8 uznrolled copies



;XXX TODO
;duplicate all code for all sizes? or at least for size 1?

;$28 blocks available -> use for either logo or 32 blocks of star size 1 (4 shifts per line = 4 * 8)


;18.07.19 only need one or two columns, so could do code duplication and eitehr do one column or two? saves 16 cycles per plot?

!cpu 6510

;free mem from ab50 - c100
;XXX TODO move d0xx handling into irqs? but would need to inc/dec $01
SYNC		= 1
COL1		= $01
BOB_COL		= $00

;CREATE_MAPS	= 1

bobs		= $10
clr		= bobs
diff		= $12
columns		= $13
num		= $14

off		= $14
lo		= $16
temp		= $18
temp_		= $19

map1		= bobs
map2		= diff

bank		= $17
yand7		= $18
frames		= $19

str_lo		= bobs
str_off		= diff
xand7		= num
addr		= frames
size		= bank

a_reg		= $1b
x_reg		= $1c
y_reg		= $1d
sprite		= $1e

zp_code 	= $20

!ifndef release {
maxnum		= $e2
}

;$d600-$e000 free

;rearrange things here
maincode	= $3400
charset1	= $e000
charset2	= $e800
volatile	= charset1 + $3f8
screen1		= $f000
screen2		= $f400
sprite_data	= $f800
bob_data	= $fa00
clear1		= $c100
help_char	= $2000
help_screen	= $2800
help_code	= $2c00

sprpos		= $6b+4

;SIZE3

!ifdef release {
		!src "../../bitfire/loader/loader_acme.inc"
		!src "../../bitfire/macros/link_macros_acme.inc"
}

		* = help_char
!bin "gfx/help.chr"
		* = help_char + $740
!bin "gfx/help_sprites.spr"
		* = help_screen
!bin "gfx/help.scr"
		* = help_screen + $3f8
		!byte <(help_char + $740) / $40
		!byte <(help_char + $7c0) / $40
		!byte <(help_char + $780) / $40
		!byte <(help_char + $7c0) / $40

		* = help_code
part_tab
		!word .part1
		!word .part2
		!word .part3
		!word .part4
		!word .part5
		!word .part6
		!word .part7
		!word .part8
		!word .part9
		!word .done
help_start
		sei
		ldx #$00
		lda #$01
-
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		dex
		bne -

		lda #$03
		sta $dd00
		jsr vsync
		ldx #$2f
-
		lda vic_conf2,x
		sta $d000,x
		dex
		bpl -
		dec $d019
		lda #<.irq
		sta $fffe
		lda #>.irq
		sta $ffff
		cli
;
!ifdef release {
		jsr link_load_next_raw
		dec $01
		jsr link_decomp
		inc $01
		jsr link_load_next_comp
}
;		;+setup_sync $80		;$5a
;		;jsr link_load_next_comp
;		;+sync
		lda #$09
-
		cmp .part + 1
		bne -
!ifdef release {
		jmp link_exit
} else {
		jmp *
}
.irq
		pha
		txa
		pha
		tya
		pha
		inc $01
		dec $d019
.part		lda #$00
		asl
		sta .jmpp + 1
.jmpp		jmp (part_tab)
.part1
		ldx #$00
		cpx #$10
		bcc +
		lda .color_frame - $10,x
		ldx #$27
-
		sta $d800 +  8*40,x
		sta $d800 + 19*40,x
		dex
		bpl -
		inx
		top
-
		ldx #$27
		jsr .set_d800
		dex
		bmi -
		tax
		bpl +
		jmp .next_part
+
		inc .part1 + 1
		jmp .done
.part2
		ldx #$00
		cpx #$10
		bcc +
		lda .color_sprite - $10,x
		sta $d027
		lda .color_strunk - $10,x
		sta $d028
		lda .color_black - $10,x
		ldx #$0a
-
		sta $d800 +  9*40 + 9,x
		sta $d800 + 10*40 + 9,x
		sta $d800 + 11*40 + 9,x
		sta $d800 + 12*40 + 9,x
		sta $d800 + 13*40 + 3,x
		sta $d800 + 14*40 + 3,x
		sta $d800 + 15*40 + 3,x
		sta $d800 + 16*40 + 3,x
		sta $d800 + 17*40 + 3,x
		sta $d800 + 18*40 + 3,x
		dex
		bpl -
		tax
		bpl +
		jmp .next_part
+
		inc .part2 + 1
		jmp .done
.part3
		ldx #$00
		cpx #$10
		bcc +
		lda .color_black - $10,x
		sta $d800 +  9*40 + 8
		sta $d800 + 10*40 + 8
		tax
		bpl +
		jmp .next_part
+
		inc .part3 + 1
		jmp .done
.part4
		ldx #$00
		lda .color_black,x
		;sta $d800 +  9*40 + 6
		;sta $d800 + 10*40 + 6
		sta $d800 +  9*40 + 7
		sta $d800 + 10*40 + 7
		tax
		bpl +
		jmp .next_part
+
		inc .part4 + 1
		jmp .done
.part5
		ldx #$00
		lda .color_black,x
		ldx #$04
-
		sta $d800 +  9*40 + 2,x
		sta $d800 + 10*40 + 2,x
		sta $d800 + 11*40 + 2,x
		sta $d800 + 12*40 + 2,x
		dex
		bne -
		tax
		bpl +
		jmp .next_part
+
		inc .part5 + 1
		jmp .done
.part6
		ldx #$00
		cpx #$10
		bcc +
		lda .color_black-$10,x
		ldx #$19
-
		sta $d800 + 5*40,x
		sta $d800 + 6*40,x
		sta $d800 + 7*40,x
		dex
		bne -
		tax
		bpl +
		jmp .next_part
+
		inc .part6 + 1
		jmp .done
.part7
		ldx #$00
		cpx #$40
		bcc +
		lda .color_sprite - $40,x
		sta $d029
		lda .color_strunk - $40,x
		sta $d02a
		lda .color_black - $40,x
		ldx #20+18
-
		jsr .set_d800
		dex
		cpx #17
		bne -
		tax
		bpl +
		jmp .next_part
+
		inc .part7 + 1
		jmp .done
.part8
		ldx #$00
		cpx #$10
		bcc +
		lda .color_black-$10,x
		ldx #$0e
-
		sta $d800 + 5*40+$19,x
		sta $d800 + 6*40+$19,x
		sta $d800 + 7*40+$19,x
		dex
		bne -
		tax
		bpl +
		jmp .next_part
+
		inc .part8 + 1
		jmp .done
.part9
		ldx #$00
		cpx #$60
		bcs +
		jmp ++
+
		lda .color_sprite_out - $60,x
		sta $d027
		sta $d029
		lda .color_strunk_out - $60,x
		sta $d028
		sta $d02a

		lda .color_frame_out - $60,x
		ldx #$27
		jsr .set_d800
-
		sta $d800 +  8*40,x
		sta $d800 + 19*40,x
		dex
		bpl -
		inx
		jsr .set_d800
+
		ldx .part9 + 1
		lda .color_black_out - $60,x
		ldx #$26
-
		sta $d800 +  5*40,x
		sta $d800 +  6*40,x
		sta $d800 +  7*40,x
		jsr .set_d800
		dex
		bne -
		tax
		bpl ++
		jmp .next_part
++
		inc .part9 + 1
		jmp .done
.next_part
		inc .part + 1
.done
		dec $01
		pla
		tay
		pla
		tax
		pla
		rti
vic_conf2
		!byte $61,$81,$61,$7c,$d1,$80,$d1,$7c
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$1b,$00,$00,$00,$0f,$08,$00
		!byte $a8,$01,$01,$ff,$00,$0f,$00,$00
		!byte $01,$01,$00,$00,$00,$00,$00,$01
		!byte $01,$01,$01,$00,$00,$00,$00,$00

.color_frame
		!byte $01,$07,$07,$07,$0f,$0f,$0f,$ff
.color_black
		!byte $01,$07,$07,$07,$0f,$0f,$0f,$0a,$0a,$0a,$08,$08,$08,$09,$09,$09,$f0
.color_sprite
		!byte $01,$01,$01,$01,$01,$07,$07,$07,$0f,$0f,$0f,$0a,$0a,$0a,$08,$08,$f8
.color_strunk
		!byte $01,$01,$01,$01,$01,$01,$01,$01,$0d,$0d,$0d,$0f,$0f,$0f,$05,$05,$f5


.color_frame_out
		!byte $0f,$0f,$0f,$07,$07,$07,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
.color_black_out
		!byte $00,$09,$09,$09,$08,$08,$08,$0a,$0a,$0a,$0f,$0f,$0f,$07,$07,$07,$f1
.color_sprite_out
		!byte $08,$0a,$0a,$0a,$0f,$0f,$0f,$07,$07,$07,$01,$01,$01,$01,$01,$01,$f1
.color_strunk_out
		!byte $05,$0f,$0f,$0f,$0d,$0d,$0d,$01,$01,$01,$01,$01,$01,$01,$01,$01,$f1

		* = charset1
colram
clear_map
!bin "gfx/map.col"
		* = charset2 + $bb * 8
!bin "gfx/screen.chr",,$bb*8
		* = screen1
!bin "gfx/screen.scr"
!fill $10,0
!byte (sprite_data & $3fff) / $40 + 0
!byte (sprite_data & $3fff) / $40 + 1
!byte (sprite_data & $3fff) / $40 + 2
!byte (sprite_data & $3fff) / $40 + 3
!byte (sprite_data & $3fff) / $40 + 4
!byte (sprite_data & $3fff) / $40 + 5
!byte (sprite_data & $3fff) / $40 + 6
!byte (sprite_data & $3fff) / $40 + 7

		* = screen2
!bin "gfx/screen.scr"
!fill $10,0
!byte (sprite_data & $3fff) / $40 + 0
!byte (sprite_data & $3fff) / $40 + 1
!byte (sprite_data & $3fff) / $40 + 2
!byte (sprite_data & $3fff) / $40 + 3
!byte (sprite_data & $3fff) / $40 + 4
!byte (sprite_data & $3fff) / $40 + 5
!byte (sprite_data & $3fff) / $40 + 6
!byte (sprite_data & $3fff) / $40 + 7

		* =  volatile
		sei
		jsr gen_data
!ifndef release {
		lda #$35
		sta $01
}
init_fadein
		jsr vvsync
		;XXX TODO ini code can be placed in charset or screen and wiped out afterwrads, it is run once
!ifndef release {
		lda #$0b
		sta $d011
}

!ifdef CREATE_MAPS {
		lxa #0
-
		sta $b000,x
		sta $b100,x
		sta $b200,x
		sta $b300,x
		sta $b400,x
		sta $b500,x
		sta $b600,x
		sta $b700,x
		dex
		bne -
}
		ldx #$00
		stx bank
		lda #$01
!ifndef release {
		stx frames
		stx frames+1
		sta maxnum
}
-
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		dex
		bne -
-
		lda zp_begin,x
		sta zp_code,x
		inx
		cpx #zp_end-zp_begin
		bne -
!ifndef release {
		lda #$7f
		sta $dc0d
		lda $dc0d
}
		lda #<fade_irq
		sta $fffe
		lda #>fade_irq
		sta $ffff

		jsr vvsync
		ldx #$2e
-
		lda vic_conf,x
		sta $d000,x
		dex
		bpl -

		lda #$00
		sta $dd00

		jsr vvsync
		lda #$1b
		sta $d011
		dec $d019
		cli
!ifdef release {
		jsr link_load_next_comp
}

.trig		lda #$00
		beq .trig
		sei
		jsr vvsync
		lda #$1b
		sta $d011
		lda #$3f
		sta $d015

		jmp maincode
.speed_table
		!byte $01
		!byte $01
		!byte $00
		!byte $01
		!byte $01
		!byte $01
		!byte $01
		!byte $01
		!byte $00
.effect_table
		!word .fade_dk
		!word .fade_man
		!word .draw_frame
		!word .draw_box
		!word .draw_bob
		!word .draw_cube
		!word .draw_bobby
		!word .move_bobby
		!word .draw_done

gen_data
!warn "stream_lo ",stream_lo
		lda #<stream_lo
		sta lo
		lda #>stream_lo
		sta lo + 1

		lda #<stream_off
		sta off
		lda #>stream_off
		sta off + 1

		ldy #$00
-
		lax (off),y
		eor (lo),y
		and #$3f
		eor (lo),y
		sta (off),y
		stx temp

		rol temp
		rla (lo),y
		rol temp
		rla (lo),y

		iny
		bne +
		inc lo + 1
		inc off + 1
+
		cpy #<(stream_end - stream_off)
		bne -
		lda off + 1
		cmp #>(stream_end - <(stream_end - stream_off))
		bne -
		rts

fade_irq_
		pha
		lda $d011
		eor #$08
		sta $d011
		lda #$fc
		cmp $d012
		bne *-3
		lda #$1b
		sta $d011
		lda #$00
		sta $d012
		;lda #$00
		sta $d015
		lda #<fade_irq2
		sta $fffe
		lda #>fade_irq2
		sta $ffff
		dec $d019
		pla
		rti
fade_irq2_
		pha
		txa
		pha
		tya
		pha
		dec $d019
		lda #<fade_irq
		sta $fffe
		lda #>fade_irq
		sta $ffff
		lda #$fa
		sta $d012
		lda #$3f
		sta $d015
.counter	lda #$00
.speed		and #$01
		bne +
.effect		jsr .fade_dk
+
		pla
		tay
		pla
		tax
		pla
		rti
.next_effect
		inc .effect_num + 1
.effect_num	ldx #$00
		lda #$00
		sta .counter + 1
		lda .speed_table,x
		sta .speed + 1
		txa
		asl
		tax
		lda .effect_table + 0,x
		sta .effect + 1
		lda .effect_table + 1,x
		sta .effect + 2
.rts
		rts

.draw_done
		lda #$01
		sta .trig + 1
		rts
.fade_dk
		lda #$0f
		;sta $d800 + 23 * 40 + 38
-
		jmp .next_effect
.fade_man
		ldx #$00
		inc .fade_man + 1
		lda .fade_man_col,x
		bmi -
		jmp set_man

.draw_frame
		ldx #$ff
		inc .draw_frame + 1
		ldy #$00
.loop_df
		inx
		bne +
start_pos	= $d800 + 16 * 40 + 7
		lda #<start_pos
		sta map1 + 0
		sta map2 + 0
		lda #>start_pos
		sta map1 + 1
		sta map2 + 1
+
		lda #$0c
		sta (map1),y
		sta (map2),y
		lda char_map1,x
		cmp #$ff
		beq .end_df
		adc map1 + 0
		sta map1 + 0
		lda char_map1,x
		bpl +
		lda map1 + 1
		sbc #0
		jmp ++
+
		lda map1 + 1
		adc #0
++
		sta map1 + 1

		lda char_map2,x
		clc
		adc map2 + 0
		sta map2 + 0
		lda char_map2,x
		bpl +
		lda map2 + 1
		sbc #0
		jmp ++
+
		lda map2 + 1
		adc #0
++
		sta map2 + 1
		cpx #$21
		bcc ++
		cpx #$27
		bcs ++
		txa
		sbc #$20
		lsr
		tax
		lda #$f0
		bcc +
		lda #$ff
+
		sta sprite_data + $40 * 5 + 0,x
++
		rts
.end_df
-
		jmp .next_effect
.draw_box
		ldx #$00
		inc .draw_box + 1
		lda .draw_box_col,x
		bmi -
		jmp set_box
.fade_man_col
.draw_bob_col
.draw_bobby_col
.draw_cube_col
		!byte $0f,$0c,$0b,$00,$ff
.draw_box_col
		!byte $0f,$0c,$ff
.draw_bob
		ldx #$00
		inc .draw_bob + 1
		lda .draw_bob_col,x
		bmi -
		jmp .set_bob
.draw_cube
		ldx #$00
		inc .draw_cube + 1
		lda .draw_cube_col,x
		bmi -
		jmp .set_cube
.draw_bobby
		ldx #$00
		inc .draw_bobby + 1
		lda .draw_bobby_col,x
		bmi -
		sta $d027
		sta $d028
		sta $d029
		sta $d02a
		rts
.move_bobby
.x_bb		ldx #$00
		inc .move_bobby + 1
		lda tab_bb,x
		sta .y_sb + 1
		bmi -
		ldx #$00
.y_sb
		lda #$00
		sec
		sbc #$16
		bcs +
		lda #$3f
		sec
		sbc .y_sb + 1
		sbc .y_sb + 1
		sbc .y_sb + 1
		tax
+
		ldy #$00
-
		lda bobby_data +  $00,x
		sta sprite_data + $00,y
		lda bobby_data +  $40,x
		sta sprite_data + $40,y
		lda bobby_data +  $80,x
		sta sprite_data + $80,y
		lda bobby_data +  $c0,x
		sta sprite_data + $c0,y
		iny
		inx
		cpx #$3f
		bcc -

		lda #$00
		cpy #$3f
		beq .normal
-
		sta sprite_data + $00,y
		sta sprite_data + $40,y
		sta sprite_data + $80,y
		sta sprite_data + $c0,y
		iny
		cpy #$3f
		bcc -
		lda #$00
		jmp ++
.normal
		lda .y_sb + 1
		sec
		sbc #$16
++
		sta $d001
		sta $d003
		sta $d005
		sta $d007
		rts
vvsync
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		rts
.set_bob
		ldy #$04
		ldx #$01
-
		jmp .set_
.set_cube
		ldy #$04
		sta $d027 + 4
		ldx #$06
.set_
-
		;sta $d800 + 4  * 40,x
		sta $d800 + 5  * 40,x
		sta $d800 + 6  * 40,x
		sta $d800 + 7  * 40,x
		sta $d800 + 8  * 40,x
		sta $d800 + 9  * 40,x
		sta $d800 + 10 * 40,x
		sta $d800 + 11 * 40,x
		;sta $d800 + 12 * 40,x
		inx
		dey
		bpl -
		rts

tab_bb
		!byte $00
		!byte $04
		!byte $08
		!byte $0c
		!byte $10
		!byte $14
		!byte $18
		!byte $1c
		!byte $1f
		!byte $22
		!byte $25
		!byte $28
		!byte $2a
		!byte $2c
		!byte $2e
		!byte $2f
		!byte $30
		!byte $31
		!byte $32
		!byte $33
		!byte $34
		!byte $35
		!byte $36
		!byte $37
		!byte $38
		!byte $39
		!byte $3a
		!byte $3b
		!byte $3c
		!byte $3d
		!byte $3e
		!byte $3f
		!byte $40
		!byte $41
		!byte $42
		!byte $43
		!byte $44
		!byte $45
		!byte $46
		!byte $47
		!byte $48
		!byte $ff

char_map1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 0
		!byte 0
		!byte 0
		!byte 0
		!byte 5
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 40
		!byte 40
		!byte 40
		!byte 40
		!byte 40
		!byte 40
		!byte 40
		!byte 40
		!byte $ff

char_map2
		!byte 1
		!byte 40
		!byte 1
		!byte 1
		!byte 1
		!byte 40
		!byte 1
		!byte 1
		!byte $28
		!byte $28
		!byte $28
		!byte $28
		!byte $28
		!byte $28
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte 1
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28
		!byte -$28


		;XXX TODO merge clear_map with map
gen_clear
		lda #<clear_map
		sta <scr
		lda #>clear_map
		sta <scr+1

		lda #<clear1
		sta <clr
		lda #>clear1
		sta <clr+1
		jsr gen

		lda <clr
		sta clear2_+1
		sta clear2__+1
		lda <clr+1
		sta clear2_+2
		sta clear2__+2

		lda #<clear_map
		sta <scr
		lda #>clear_map
		sta <scr+1
		lda #>screen2
		sta .ora+1
gen
		ldx <clr
-
		ldy #$00
		lda (scr),y
		;cmp #$07
		bne +
		lda #$8d
		sta (clr),y
		iny
		lda <scr
		sta (clr),y
		iny
		lda <scr+1
		and #$03
.ora		ora #>screen1
		sta (clr),y
		txa
		sbx #-3
		stx <clr
		bcc +
		inc <clr+1
+
		inc <scr
		bne -
		inc <scr+1
		lda <scr+1
		cmp #>(clear_map+$0400)
		bne -

		ldy #$00
		lda #$60
		sta (clr),y
		inc <clr
		bne +
		inc <clr+1
+
		rts

vic_conf
		!byte $18,$32,$30,$32,$48,$32,$60,$32					;sprite positions
		!byte $56,$64,$d8,$32,$00,$00,$00,$00
		!byte $00,$0b,$fa,$00,$00,$00,$08,$00
		!byte ((charset2 & $3fff) / $800) * 2 + ((screen1 & $3c00) / $40)
		!byte     $01,$01,$00,$00,$20,$00,$00
		!byte $01								;border
		!byte $01								;bg
		!byte $00								;char mc1
		!byte $00								;char mc2
		!byte $00								;mc3/ecm
		!byte COL1								;sprite mc1
		!byte COL1								;sprite mc2
		!byte $01								;sprite 1 col
		!byte $01								;sprite 2 col
		!byte $01								;sprite 3 col
		!byte $01								;sprite 4 col
		!byte $01								;sprite 5 col
		!byte $0c    								;sprite 6 col
		!byte BOB_COL								;sprite 7 col
		!byte BOB_COL								;sprite 8 col

zp_begin
!pseudopc zp_code {
ysize1_1_ands
		;this case happens rather seldom
		lda cset_lo,x
		sta <cset_o
bank01s		lda cset_hi_1,x
		sta <cset_o+1

		ldy #$00
		;reuse set up pointer to fetch right pattern, y is still 0
		lda (bob_size1),y
		ldy <cset	;contains y and 7 component
		ora (cset_o),y
cset_o = * + 1
		sta $1000,y
		ldy <yc
		beq esc
size1_loop
		dey
start_size1
		sty <yc
coords_off = * + 1
		;ssxxxyyy
		ldx stream_off,y
coords_lo = * + 1
		lda stream_lo,y
		tay

		;XXX TODO would be nice to have that as index
		stx <bob_size1
		lda #$07
		;set y and 7 component in lowbyte of cset
		sax <cset

screen_b1
		lda scr_hi2,x
		sta <scr + 1
		;XXX TODO we could then switch to x as index here and do ldy stream_lo,x \o/

		;specialcase for size 1

		;block already in use?
scr = * + 1
		lax $1000,y
		bne ysize1_1_ands

		lax <num
		;carry is clear here
		inc <num
		sta (scr),y

		;we can afford that here, as it will only happen for size = 1
		ldy cset_lo,x
		beq cset_inc	;XXX TODO only happens each 32 chars, can be omitted
cset_inc_
		;XXX TODO also useful elsewhere, even with a jsr call?
		;only needs 40 cycles

		lda #$00
		;clear 8 lines, no check on line to be writen, too expensive
cl1		sta charset1+0,y
cl2		sta charset1+1,y
cl3		sta charset1+2,y
cl4		sta charset1+3,y
cl5		sta charset1+4,y
cl6		sta charset1+5,y
cl7		sta charset1+6,y
cl8		sta charset1+7,y

		;ldy yand7 -> cset
		;y contains cset low component and cset contains yand7 component \o/

		;now set new plot
bob_size1 = * + 1
		lda bob_1_0
cset = * + 1
		sta charset2,y
next_plot1
yc = * + 1
		ldy #$00
		bne size1_loop
esc
		jmp next_size
cset_inc
		inc <cl1+2
		inc <cl2+2
		inc <cl3+2
		inc <cl4+2
		inc <cl5+2
		inc <cl6+2
		inc <cl7+2
		inc <cl8+2
		inc <cset+1
		jmp cset_inc_
coords_poi
		!word stream_poi - 1
fade_irq
		jmp fade_irq_
fade_irq2
		jmp fade_irq2_
!warn "zp code goes up to: ", *
}
zp_end

bobby_data
!bin "gfx/sprites.spr",$40 * 4

!warn "end of volatile code: ",*

		* = maincode
		jsr gen_clear
		lda #$bb
		jsr clear1
clear2__	jsr clear1

		ldx #$00
-
		lda colram + $000,x
		and $d800 + $000,x
		sta $d800 + $000,x
+
		lda colram + $100,x
		and $d800 + $100,x
		sta $d800 + $100,x
+
		lda colram + $200,x
		and $d800 + $200,x
		sta $d800 + $200,x
+
		lda colram + $300,x
		and $d800 + $300,x
		sta $d800 + $300,x
+
		dex
		bne -

		sei
!ifndef release {
		lda #$35
		sta $01
}
		txa
		ldx #$08
-
		sta charset1 - 1,x
		sta charset2 - 1,x
		dex
		bne -

		;kill volatile code and copy over charset into second buffer
-
		lda charset2 + $0500,x
		sta charset1 + $0500,x
		lda charset2 + $0600,x
		sta charset1 + $0600,x
		lda charset2 + $0700,x
		sta charset1 + $0700,x
		lda #$00
		sta charset2 + $0000,x
		sta charset2 + $0100,x
		dex
		bne -
		jsr vsync
		jmp next
fadeout
		ldx #$26
--
		lda #$31
-
		cmp $d012
		bne *-3
		bit $d011
		bpl -
		jsr clear_column
		dex
		cpx #$0d
		bne --
;		ldx #$00
;		txa
;-
;		sta screen1 + $000,x
;		sta screen1 + $100,x
;		sta screen1 + $200,x
;		sta screen1 + $2e8,x
;		dex
;		bne -

		jsr vsync
		lda #$01
		jsr set_dk
		ldy #$0f
		lda #$0b
		jsr fade_down
		jsr vsync
		jsr vsync
		ldy #$01
		lda #$0c
		jsr fade_down
		jsr vsync
		jsr vsync
		ldy #$01
		lda #$0f
		jsr fade_down
		jsr vsync
		jsr vsync
		lda #$0b
		sta $d011
		ldy #$01
		lda #$01
		jmp fade_down
vsync
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		rts
wait
-
		jsr vsync
		dey
		bne -
		rts



fade_bg
		!byte $00,$09,$08,$0a,$0f,$07
;sprite_dst
;		!byte <sprite_data + $c0	;fc
;		!byte <sprite_data + $00	;xxx
;		!byte <sprite_data + $00	;fc
;		!byte <sprite_data + $01	;xxx
;		!byte <sprite_data + $01	;fc
;		!byte <sprite_data + $02	;xxx
;		!byte <sprite_data + $02	;fc
;		!byte <sprite_data + $40	;xxx
;		!byte <sprite_data + $40	;fc
;		!byte <sprite_data + $41	;xxx
;		!byte <sprite_data + $41	;fc
;		!byte <sprite_data + $42	;xxx
;		!byte <sprite_data + $42	;fc
;		!byte <sprite_data + $c0	;fc
;sprite_dst2
;		!byte <sprite_data + $00	;3f
;		!byte <sprite_data + $00	;xxx
;		!byte <sprite_data + $01	;3f
;		!byte <sprite_data + $01	;xxx
;		!byte <sprite_data + $02	;3f
;		!byte <sprite_data + $02	;xxx
;		!byte <sprite_data + $40	;3f
;		!byte <sprite_data + $40	;xxx
;		!byte <sprite_data + $41	;3f
;		!byte <sprite_data + $41	;xxx
;		!byte <sprite_data + $42	;3f
;		!byte <sprite_data + $42	;xxx
;		!byte <sprite_data + $80	;3f
;		!byte <sprite_data + $c0	;fc

;random einfaden die rasters!!! pos, color?

reset
!ifndef release {
		lda frames
		sta $e0
		lda frames+1
		sta $e1

		lda #$00
		sta frames
		sta frames+1
		;jam
}

		lda #<frame_lo018
		sta <coords_lo
		sta coords_lo_
		lda #>frame_lo018
		sta <coords_lo + 1
		sta coords_lo_ + 1

		lda #<frame_off018
		sta <coords_off
		sta coords_off_
		lda #>frame_off018
		sta <coords_off + 1
		sta coords_off_ + 1

		lda #<(.frame_poi018 - 1)
		sta <coords_poi
		lda #>(.frame_poi018 - 1)
		sta <coords_poi+1

		dec .count + 1
.count		lda #$02
		bne next
		jsr fadeout
		sei
		lda #$0b
		sta $d011
		lda #$00
		sta $d015
		jmp help_start
next
!ifndef release {
		lda num
		cmp maxnum
		bcc +
		sta maxnum
+
}
		lda #$07
		ldy bank
		bne *+5
		jmp do_bank1
do_bank2
		ldy #((charset1 & $3fff) / $800) * 2 + ((screen1 & $3c00) / $40)
!ifndef SYNC {
--
-
		lax $d012
		and #$07
		cmp #$01
		bne -
-
		cpx $d012
		beq -
} else {
-
		lda $d011
		bmi .u
		lda $d012
		cmp #$f2
		bcs .u
		cmp #$32
		bcs -
.u
}
		lda #>scr_hi2
		sta screen_b + 2
		sta screen_b1 + 2

		lda #>cset_hi_2
		sta bank01s+2
		sta bank02s+2
		sta bank03s+2
		sta bank04s+2
		sta bank05s+2
		sta bank06s+2
		sta bank07s+2
		sty $d018
		sta bank08s+2
		sta bank03+2
		sta bank04+2
!ifdef SIZE3 {
		sta bank07+2
		sta bank08+2
		sta bank09+2
}

		lda #>charset2
		sta <cset+1
		sta <cl1+2
		sta <cl2+2
		sta <cl3+2
		sta <cl4+2
		sta <cl5+2
		sta <cl6+2
		sta <cl7+2
		sta <cl8+2

!ifdef CREATE_MAPS {
		ldx #$00
-
		lda screen2 + $000,x
		ora $b000,x
		sta $b000,x
		lda screen2 + $100,x
		ora $b100,x
		sta $b100,x
		lda screen2 + $200,x
		ora $b200,x
		sta $b200,x
		lda screen2 + $300,x
		ora $b300,x
		sta $b300,x
		dex
		bne -
}

		lda #$00
clear2_
		jsr clear1
		jmp exit_clear2
do_bank1
		ldy #((charset2 & $3fff) / $800) * 2 + ((screen2 & $3c00) / $40)
!ifndef SYNC {
--
-
		lax $d012
		and #$07
		cmp #$01
		bne -
-
		cpx $d012
		beq -
} else {
-
		lda $d011
		bmi .u2
		lda $d012
		cmp #$f2
		bcs .u2
		cmp #$32
		bcs -
.u2
}
		lda #>scr_hi1
		sta screen_b + 2
		sta screen_b1 + 2

		lda #>cset_hi_1
		sta bank01s+2
		sta bank02s+2
		sta bank03s+2
		sta bank04s+2
		sta bank05s+2
		sta bank06s+2
		sta bank07s+2
		sty $d018
		sta bank08s+2
		sta bank03+2
		sta bank04+2
!ifdef SIZE3 {
		sta bank07+2
		sta bank08+2
		sta bank09+2
}

		lda #>charset1
		sta <cset+1
		sta <cl1+2
		sta <cl2+2
		sta <cl3+2
		sta <cl4+2
		sta <cl5+2
		sta <cl6+2
		sta <cl7+2
		sta <cl8+2

!ifdef CREATE_MAPS {
		ldx #$00
-
		lda screen1 + $000,x
		ora $b000,x
		sta $b000,x
		lda screen1 + $100,x
		ora $b100,x
		sta $b100,x
		lda screen1 + $200,x
		ora $b200,x
		sta $b200,x
		lda screen1 + $300,x
		ora $b300,x
		sta $b300,x
		dex
		bne -
}

		lda #$00
		jsr clear1
exit_clear2
		sta <scr

		ldy #$01
		sty num
		sty size_01 + 1
		tya
		eor <bank
		sta <bank
		lda (<coords_poi),y		;load ammount of plots for size 1
		beq skip_size1			;no plots in size 1
		sta <diff			;store amount
		tay				;set count down
		jmp start_size1			;plot size 1
next_size
		lax <diff
		clc
		adc <coords_lo
		sta <coords_lo
		sta coords_lo_
		bcc +
		inc <coords_lo + 1
		inc coords_lo_ + 1
		clc
+
		txa
		adc <coords_off
		sta <coords_off
		sta coords_off_
		bcc +
		inc <coords_off + 1
		inc coords_off_ + 1
+
		ldy size_01 + 1
.skip
		cpy #$09
		beq frame
skip_size1
		iny
-
		lda (<coords_poi),y		;load ammount of plots for size y
		beq .skip			;none
		sta <diff			;store amount
		sta <yc				;and counter
		sty size_01 + 1			;and current size
!ifdef SIZE3 {
		sty size_02 + 1
}
+
		;XXX TODO max $1e dots in size 1 + $10 oras into those chars

bigger_than1
		tya
		;clc
		sbc #$09
		sta sizesub + 1
		lda cset_lo - 2,y ;-> y * 8)
		sty size__
		sta size_

		lda ysize1_jtab_l - 2,y
		sta ysize1_jmp + 1
		lda ysize1_jtab_h - 2,y
		sta ysize1_jmp + 2

		;we have all shifts per size in one page \o/
		lda size_tab_h - 2,y
		sta <bobs + 1
next_plot
		ldy <yc
		beq next_size
		dey
		sty <yc

coords_lo_ = * + 1
		lda stream_lo,y
		sta <scr

		;ssxxxyyy
coords_off_ = * + 1
		ldx stream_off,y
screen_b
		lda scr_hi2,x
		sta <scr + 1

		ldy xoffset,x
size__ = * + 1
		lda size_sh_tab,y
		sta <columns

		lda #$07
		sax <yand7
size_ = * + 1
		;XXX TODO no need to subtract y from bobs if we add it to cset and start with y = 0
		;XXX TODO could use a combined tab here that involves yand7 and x, saves 5 cycles with 2 optimizations
		lda size_tab_l,y
		sbc <yand7
		sta <bobs

;offset 1:  size
;yand7size
;		!byte $00,$01,$02,$03,$04,$05,$06,$07,$08,,$09,$0a,$0b,$0c,$0d,$0f,$10,$11,$12


;XXX TODO have duplicate code per column so we can reuse all stuff and check on column = 1 2 3?
		lax <yand7
sizesub		adc #$00
		bpl ysize2
ysize1
		;x = yand7
		;y = yand7 + size

		;a = 1..9
ysize1_jmp	jmp $1000
!ifdef SIZE3 {
ysize3_jmp
		jmp ysize3
}
frame
		lda <coords_poi
		adc #8
		sta <coords_poi
		bcc +
		inc <coords_poi + 1
+
		;XXX TODO load first byte from stream and do and #$7f -> ignores frame
		;XXX TODO use snum to add
		lda <coords_off
		cmp #<stream_end
		bne +
		lda <coords_off + 1
		cmp #>stream_end
		bne +
		jmp reset
+
		jmp next
;		cmp #$08	;10..1f	;XXX can be skipped until size reaches 9
;		bcs ysize3_jmp


		;XXX TODO possibly move to ZP if we cn save 4 or more cycles by that
		;spend own scr pointer and use stx $1000 instead of sta (scr),y
		;save 1 cycle on jmp setup
		;3 extra cycles to jump to ZP code
		;XXX TODO maybe even have next_plot in ZP
;-------------------------------------------------------------------------------------------
;
; 2 Chars high!
;
;-------------------------------------------------------------------------------------------
-
		inc <cset+1
		bne +
ysize2
		;sbc #$08
		asl
		;we work with pointers here, cheaper as asl tay lda table,y jmp chunk is more expensive, chunk_first table has an offset of $12 to get rid of the sbc #9 component
		sta ysize2_2_jmp+1
		sta yo2b2+1

		;and only with lowbyte here, all chunks start in the same page	;XXX TODO could be moved to direct case only, not needed for and-case
		lda tab_chunk_first,x
		sta ysize2_1_jmp+1
ysize2_
		ldy #$00
		lax (scr),y		;block already in use?
		bne ysize2_1_and

		lax <num
		sta (scr),y
		lda cset_lo,x
		sta <cset
		beq -
+
		inc <num

ysize2_1_jmp
		;all chunks in one page \o/
		jmp chunk_first

ysize2_1_and
		lda cset_lo,x
		sta <cset_o
bank03		lda cset_hi_1,x
		sta <cset_o+1

		;XXX TODO also solve with jmp (tab) set up by asl + sta jmp? just inverted?
		ldy yand7
		lda m7r,y
		sta yo2b1+1

yo2b1		bpl *
		lda (bobs),y		;happens at least 1 times
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
y2_1_pback
		ldy #$28
		lax (scr),y		;block already in use?
		bne ysize2_2_and	;XXX TODO prefer non and case by inverting branch condition and moving upcoming code to jmp ()
ysize2_2_
		lax num
		sta (scr),y
		inc num

		ldy #$08
ysize2_2_jmp
		;takes 2 additional cycles with indirect jump, but setup is 4 cycles faster
		jmp (tab_chunk_last)

y2_last
		;execute always, except for last column
		lda <bobs
size_01		adc #$00
		sta <bobs
		inc <scr
		bne ysize2_
		inc <scr+1
		jmp ysize2_
last_end
		lda cset_lo,x
		sta <cset
		beq +
-
		dec columns
		bpl y2_last
		jmp next_plot
+
		inc <cset+1
		bne -
ysize2_2_and
		lda cset_lo-1,x
		sta <cset_o
bank04		lda cset_hi_1-1,x
		sta <cset_o+1

		;refetch index and set branch by that, this cas happens seldom anyway
		;lda ysize2_2_jmp+1

		ldy #$08
yo2b2		jmp (yand2tab)
y2and07
		lda (bobs),y		;happens at least 1 times
		ora (cset_o),y
		sta (cset_o),y
		iny
y2and06
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
y2and05
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
y2and04
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
y2and03
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
y2and02
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
y2and01
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
y2and00
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		dec columns
		bpl y2_last
		jmp next_plot
		;XXX TODO could be added to chunk_last? but it would then not fit on one page with entry points?! but doesn't matter as it is called with pointers?


;only params needed:
;ypos & 7
;(ypos + size) & 7

;generate a map and see what is free -> gen clear depending on map -> copy code from lines

!macro one_char ~.entry, ~.and_entry, ~.back, .chunk_tab, .chunk, .size {
.back
		lax <bobs
		sbx #-.size
		stx <bobs
		inc <scr
		bne +
		inc <scr + 1
		bne +
.entry
		;XXX TODO should happen later for direct case only
		lda .chunk_tab,x
		sta .jmp+1
+
		ldy #$00
		lax (scr),y		;block already in use?
		bne .and_entry

		lax <num
		sta (scr),y

		lda cset_lo,x
		sta <cset
		beq +

		tya
-
		inc <num
.jmp		jmp .chunk
+
		inc <cset+1
		bne -
.and_entry
}

		;XXX TODO spend even another bit for and/without nad? if we cross a char, do next column?
		;XXX TODO make a table that resolves xxxyyy << 1
		;directly access chunk for correct x and y shift

		+one_char ~ychar1_size2, ~ychar1_size2_and, ~ychar1_size2_, tab_chunk_2, chunk_2, 2

		lda cset_lo,x
		sta <cset_o
bank02s		lda cset_hi_1,x
		sta <cset_o+1

		ldy yand7
		lax (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		dec columns
		bpl ychar1_size2_
		jmp next_plot

		+one_char ~ychar1_size3, ~ychar1_size3_and, ~ychar1_size3_, tab_chunk_3, chunk_3, 3

		lda cset_lo,x
		sta <cset_o
bank03s		lda cset_hi_1,x
		sta <cset_o+1

		ldy yand7
		lax (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		dec columns
		bpl ychar1_size3_
		jmp next_plot

		+one_char ~ychar1_size4, ~ychar1_size4_and, ~ychar1_size4_, tab_chunk_4, chunk_4, 4

		lda cset_lo,x
		sta <cset_o
bank04s		lda cset_hi_1,x
		sta <cset_o+1

		ldy yand7
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lax (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		dec columns
		bpl ychar1_size4_
		jmp next_plot

		+one_char ~ychar1_size5, ~ychar1_size5_and, ~ychar1_size5_, tab_chunk_5, chunk_5, 5

		lda cset_lo,x
		sta <cset_o
bank05s		lda cset_hi_1,x
		sta <cset_o+1

		ldy yand7
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lax (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		dec columns
		bpl ychar1_size5_
		jmp next_plot

		+one_char ~ychar1_size6, ~ychar1_size6_and, ~ychar1_size6_, tab_chunk_6, chunk_6, 6

		lda cset_lo,x
		sta <cset_o
bank06s		lda cset_hi_1,x
		sta <cset_o+1

		ldy yand7
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lax (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		dec columns
		bpl ychar1_size6_
		jmp next_plot

		;have code 8 times for each x-shift? then real values can be used?
		;XXX TODO simplify, we only have two options here!
		+one_char ~ychar1_size7, ~ychar1_size7_and, ~ychar1_size7_, tab_chunk_7, chunk_7, 7

		lda cset_lo,x
		sta <cset_o
bank07s		lda cset_hi_1,x
		sta <cset_o+1

		ldy yand7
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lax (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		dec columns
		bpl ychar1_size7_
		jmp next_plot
-
		inc <cset+1
		bne ++
ychar1_size8
		ldy #$00
		lax (scr),y		;block already in use?
		bne ychar1_size8_and
ychar1_size8_norm
		lax num
		sta (scr),y
		lda cset_lo,x
		sta <cset
		beq -
++
		inc num

		ldy #$00
		lda (bobs),y
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$01
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y

		dec columns
		bpl ychar1_size8_
		jmp next_plot
ychar1_size8_
		lax bobs
		sbx #-8
		stx bobs
		ldy #$01
		lax (scr),y		;block already in use?
		beq ychar1_size8_norm
ychar1_size8_and
		lda cset_lo,x
		sta <cset_o
bank08s		lda cset_hi_1,x
		sta <cset_o+1

		ldy #$00
		lax (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		ldy #$07
		txa
		ora (cset_o),y
		sta (cset_o),y
		dey
		lax (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		ldy #$01
		txa
		ora (cset_o),y
		sta (cset_o),y

		iny
		lax (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		iny
		txa
		ora (cset_o),y
		sta (cset_o),y
		dec columns
		bpl ychar1_size8_
		jmp next_plot

;XXX TODO do one code segment per size and num_rows -> size 1..8 -> numrows 1, 2...16 numrows 2 -> 9 ...16 numrows 3 max 31 segments?!
;XXX TODO 24,5 cycles can be wasted for a clearing that setups a list of targets?

;-> copy scr to zp and clear via sta (zp,x) ? 6 + 12 ? but only max $80 would be possible?
;lda/sta lda/sta -> 7 + 7 + 3 + 3 + 3 + 2 + 4


;size -> index to right pointer into right codesegment with static values encoded

;XXX TODO
;einzeldots als fertige chars ablegen (shceck mit bit auf overflow? oder chars > $c0?
;-> happens max $23 per frame
;falsl dann and fall kommt: copy over von char und inc num, dann merge mit and
;statistik erzeugen welcher typ (1,2,3 chars hoch, je size) am häufigsten auftritt -> da dann optimieren wie bei size 1

!ifdef SIZE3 {
ysize3
		tay
		;setup
		lda m3rs,y
		sta y3b2+1

		lda m5n,y
		sta y3b1+1

		lda m5r,x
		sta y3b4+1

		lda m3n,x
		sta y3b3+1
--
		ldy #$00
		lax (scr),y		;block already in use?
		beq +
ysize3_1_and
		lda cset_lo,x
		sta <cset_o
bank07		lda cset_hi_1,x
		sta <cset_o+1

		ldy yand7
		lda m7r,y
		sta yo3b1+1

yo3b1		bpl *
		lda (bobs),y		;happens at least 1 times
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		jmp y3_1_back
-
		inc <cset+1
		bne ++
+
		lax num
		sta (scr),y
		lda cset_lo,x
		sta <cset
		beq -
++
		;this is still pita
		inc num

		lda #$00
y3b3		beq *			;happens 0 - 7 times
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny

y3b4		bpl *
		lda (bobs),y		;happens at least 1 times
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y

y3_1_back
		lax bobs
		sbx #$f8
		stx bobs

		ldy #$28
		lax (scr),y		;block already in use?
		beq +
		;full block
ysize3_2_and
		lda cset_lo,x
		sta <cset_o
bank08		lda cset_hi_1,x
		sta <cset_o+1

		ldy #$00
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		jmp y3_2_back
-
		inc <cset+1
		bne ++
+
		lax num
		sta (scr),y
		lda cset_lo,x
		sta <cset
		beq -
++
		inc num

		ldy #$00
		lda (bobs),y		;happens at least 1 times
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
y3_2_back
		ldy #$50
		lax (scr),y		;block already in use?
		beq +
ysize_3_3_and
		lda cset_lo-1,x
		sta <cset_o
bank09		lda cset_hi_1-1,x
		sta <cset_o+1

		ldy y3b2+1
		lda m7ns,y
		sta yo3b3+1

		ldy #$08
yo3b3		bpl *
		lda (bobs),y		;happens at least 1 times
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		iny
		lda (bobs),y
		ora (cset_o),y
		sta (cset_o),y
		dec columns
		bpl y3_last
		jmp next_plot
+
		lax num
		sta (scr),y
		inc num

		ldy #$08
y3b1		bpl *
		lda (bobs),y		;happens at least 1 times
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny

		lda #$00
y3b2		beq *			;happenes 0 - 7 times
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y

		;delay setting of cset so that bob pointer increment can be omitted for once and thus y = 8 can be used as start index on copy
		lda cset_lo,x
		sta <cset
		bne y3_3_back
		inc <cset+1
y3_3_back
		dec columns
		bmi ++
y3_last
		;execute always, except for last column
		inc <scr
		bne +
		inc <scr+1
+
		lda <bobs
size_02		adc #$00
		sbc #$07
		sta <bobs

		jmp --
++
		jmp next_plot
}

chunk_last_1_7
		lda (bobs),y
		sta (cset),y
		iny
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		jmp last_end
chunk_last_2_6
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		jmp last_end
chunk_last_3_5
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		jmp last_end
chunk_last_4_4
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		jmp last_end
chunk_last_5_3
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		jmp last_end
chunk_last_6_2
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		jmp last_end
chunk_last_7_1
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda #$00
		sta (cset),y
		jmp last_end
chunk_last_8_0
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		jmp last_end


!align 255,0
size_sh_tab
		!byte $00
		!byte $00
		!byte $00,$00,$00,$00,$00,$00,$00,$01
                !byte $01,$01,$01,$01,$01,$01,$01,$02
		!byte $02,$02,$02,$02,$02,$02,$02,$02

;		!byte $00,$00,$00,$00,$00,$00,$00,$01
;		!byte $00,$00,$00,$00,$00,$00,$01,$01
;		!byte $00,$00,$00,$00,$00,$01,$01,$01
;		!byte $00,$00,$00,$00,$01,$01,$01,$01
;		!byte $00,$00,$00,$01,$01,$01,$01,$01
;		!byte $00,$00,$01,$01,$01,$01,$01,$01
;		!byte $00,$01,$01,$01,$01,$01,$01,$01
;		!byte $01,$01,$01,$01,$01,$01,$01,$02
;		!byte $01,$01,$01,$01,$01,$01,$02,$02
;		!byte $01,$01,$01,$01,$01,$02,$02,$02
data
stream_poi
!src "stream_poi.asm"
!warn "poi-size: ", * - stream_poi
stream_lo
frame_lo018 = * + 18 * 98
!warn "stream-lo:", *
!src "stream_lo.asm"
!warn "lo-size: ", * - stream_lo
stream_off
frame_off018 = * + 18 * 98
!src "stream_off.asm"
!warn "off-size: ", * - stream_off
stream_len = * - stream_off
stream_end
!warn "datasize: ", *-data

!align 255,0
!byte $00
cset_lo
!for .c, 0, 254 {
	!byte <(.c * 8 + charset1)
}
;		* = (* + $ff) & $ff00
!align 255,0
scr_hi1
!for .c, 0, 255 {
	!byte (>screen1) + (.c >> 6)
}

scr_hi2
!for .c, 0, 255 {
	!byte (>screen2) + (.c >> 6)
}

!align 255,0
!byte $00
cset_hi_1
!for .c, 0, 254 {
	!byte >(.c * 8 + charset1)
}
xoffset
!for .c,0,255 {
		!byte (.c >> 3) & 7
}

!align 255,0
!byte $00
cset_hi_2
!for .c, 0, 254 {
	!byte >(.c * 8 + charset2)
}

!align 255,0
chunk_first
chunk_first_1_7
		lda #$00
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		jmp y2_1_pback
chunk_first_2_6
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		jmp y2_1_pback
chunk_first_3_5
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		jmp y2_1_pback
chunk_first_4_4
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		jmp y2_1_pback
chunk_first_5_3
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		jmp y2_1_pback
chunk_first_6_2
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		jmp y2_1_pback
chunk_first_7_1
		lda #$00
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		jmp y2_1_pback
chunk_first_0_8
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		jmp y2_1_pback
!warn "chunk_first from ", chunk_first, " to ", *

chunk_5
chunk_5_0
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$00
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size5_
chunk_5_1
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$01
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size5_
chunk_5_2
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$02
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size5_
chunk_5_3
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		lda (bobs),y
		sta (cset),y
		ldy #$03
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size5_
+
		jmp next_plot
tab_chunk_7
		!byte <chunk_7_0
		!byte <chunk_7_1
tab_chunk_5
		!byte <chunk_5_0
		!byte <chunk_5_1
		!byte <chunk_5_2
		!byte <chunk_5_3
ysize1_jtab_l
		!byte <ychar1_size2
		!byte <ychar1_size3
		!byte <ychar1_size4
		!byte <ychar1_size5
		!byte <ychar1_size6
		!byte <ychar1_size7
		!byte <ychar1_size8
ysize1_jtab_h
		!byte >ychar1_size2
		!byte >ychar1_size3
		!byte >ychar1_size4
		!byte >ychar1_size5
		!byte >ychar1_size6
		!byte >ychar1_size7
		!byte >ychar1_size8
tab_chunk_first
		!byte <chunk_first_0_8
		!byte <chunk_first_1_7
		!byte <chunk_first_2_6
		!byte <chunk_first_3_5
		!byte <chunk_first_4_4
		!byte <chunk_first_5_3
		!byte <chunk_first_6_2
		!byte <chunk_first_7_1
m3n
		!byte 21,18,15,12,9,6,3,0
m5n
;		!byte 7*5,6*5,5*5,4*5,3*5,2*5,1*5,0*5
		!byte 7*5,6*5,5*5,4*5,3*5,2*5,1*5,0*5
		!byte 7*5,6*5,5*5,4*5,3*5,2*5,1*5,0*5
m3rs
;		!byte 0,3,6,9,12,15,18,20
		!byte 0,3,6,9,12,15,18,20
		!byte 0,3,6,9,12,15,18,20


!warn "chunk_5 from ", chunk_5, " to ", *
!align 255,0
yand2tab
		!word y2and00
		!word y2and01
		!word y2and02
		!word y2and03
		!word y2and04
		!word y2and05
		!word y2and06
		!word y2and07
chunk_3
chunk_3_0
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y		;can be dfurtehr optimized by using ldy values and save on tax/lax?
		sta (cset),y
		ldy #$00
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size3_
chunk_3_1
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y		;can be dfurtehr optimized by using ldy values and save on tax/lax?
		sta (cset),y
		ldy #$01
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size3_
chunk_3_2
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y		;can be dfurtehr optimized by using ldy values and save on tax/lax?
		sta (cset),y
		ldy #$02
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size3_
chunk_3_3
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y		;can be dfurtehr optimized by using ldy values and save on tax/lax?
		sta (cset),y
		ldy #$03
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size3_
+
-
		jmp next_plot
chunk_3_4
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		lda (bobs),y		;can be dfurtehr optimized by using ldy values and save on tax/lax?
		sta (cset),y
		ldy #$04
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		dec columns
		bmi -
		jmp ychar1_size3_
chunk_3_5
		sta (cset),y		;0
		iny
		sta (cset),y		;1
		iny
		sta (cset),y		;2
		iny
		sta (cset),y		;3
		iny
		sta (cset),y		;4
		iny
		lda (bobs),y		;can be dfurtehr optimized by using ldy values and save on tax/lax?
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		dec columns
		bmi -
		jmp ychar1_size3_
tab_chunk_6
		!byte <chunk_6_0
		!byte <chunk_6_1
		!byte <chunk_6_2
tab_chunk_3
		!byte <chunk_3_0
		!byte <chunk_3_1
		!byte <chunk_3_2
		!byte <chunk_3_3
		!byte <chunk_3_4
		!byte <chunk_3_5
m5r
		!byte 0*5,1*5,2*5,3*5,4*5,5*5,6*5,7*5

!warn "chunk_3 from ", chunk_3, " to ", *

!align 255,0
tab_chunk_last
		!word chunk_last_1_7
		!word chunk_last_2_6
		!word chunk_last_3_5
		!word chunk_last_4_4
		!word chunk_last_5_3
		!word chunk_last_6_2
		!word chunk_last_7_1
		!word chunk_last_8_0

chunk_4
chunk_4_0
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$00
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size4_
chunk_4_1
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$01
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size4_
chunk_4_2
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$02
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size4_
chunk_4_3
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$03
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size4_
+
-
		jmp next_plot
chunk_4_4
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		lda (bobs),y
		sta (cset),y
		ldy #$04
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi -
		jmp ychar1_size4_
tab_chunk_4
		!byte <chunk_4_0
		!byte <chunk_4_1
		!byte <chunk_4_2
		!byte <chunk_4_3
		!byte <chunk_4_4
tab_chunk_2
		!byte <chunk_2_0
		!byte <chunk_2_1
		!byte <chunk_2_2
		!byte <chunk_2_3
		!byte <chunk_2_4
		!byte <chunk_2_5
		!byte <chunk_2_6
m7ns
		!byte 7*7
		!byte 7*7
		!byte 7*7

		!byte 6*7
		!byte 6*7
		!byte 6*7

		!byte 5*7
		!byte 5*7
		!byte 5*7

		!byte 4*7
		!byte 4*7
		!byte 4*7

		!byte 3*7
		!byte 3*7
		!byte 3*7

		!byte 2*7
		!byte 2*7
		!byte 2*7

		!byte 1*7
		!byte 1*7
		!byte 1*7

		!byte 0*7
		!byte 0*7
		!byte 0*7

m7r
		!byte 0*7,1*7,2*7,3*7,4*7,5*7,6*7,7*7

size_tab_h
		!byte >(bob_2_0)
		!byte >(bob_3_0)
		!byte >(bob_4_0)
		!byte >(bob_5_0)
		!byte >(bob_6_0)
		!byte >(bob_7_0)
		!byte >(bob_8_0)
		!byte >(bob_9_0)
		!byte >(bob_10_0)
		!byte >(bob_11_0)



!warn "chunk_4 from ", chunk_4, " to ", *

!align 255,0
chunk_2
chunk_2_0
		ldy #$02
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$00
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size2_
chunk_2_1
		sta (cset),y
		ldy #$03
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$01
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size2_
chunk_2_2
		sta (cset),y
		iny
		sta (cset),y
		ldy #$04
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$02
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size2_
chunk_2_3
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$05
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$03
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size2_
+
-
		jmp next_plot
chunk_2_4
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$06
		sta (cset),y
		iny
		sta (cset),y
		ldy #$04
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi -
		jmp ychar1_size2_
chunk_2_5
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		sta (cset),y
		ldy #$05
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi -
		jmp ychar1_size2_
chunk_2_6
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi -
		jmp ychar1_size2_
!warn "chunk_2 from ", chunk_2, " to ", *

!align 255,0
chunk_6
chunk_6_0
		ldy #$07
		sta (cset),y
		dey
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$00
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size6_
chunk_6_1
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$01
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size6_
chunk_6_2
		sta (cset),y
		iny
		sta (cset),y
		ldy #$07
		lda (bobs),y
		sta (cset),y
		ldy #$02
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size6_
+
		jmp next_plot

chunk_7
chunk_7_0
		ldy #$07
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$00
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		ldy #$05
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		dey
		sta (cset),y
		dey
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size7_
chunk_7_1
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		ldy #$07
		sta (cset),y
		dey
		lda (bobs),y
		sta (cset),y
		ldy #$02
		sta (cset),y
		iny
		lda (bobs),y
		sta (cset),y
		iny
		sta (cset),y
		iny
		sta (cset),y
		dec columns
		bmi +
		jmp ychar1_size7_
+
		jmp next_plot

!warn "chunk_7 from ", chunk_7, " to ", *
!align 255,0
size_tab_l
;bob_1_lo
;		!byte $00
;		!byte $00
;		!byte $00
;		!byte $00
;		!byte $00
;		!byte $00
;		!byte $00
;		!byte $00

		;XXX TODO
		; new data laout:
		;per page: next column
		;also per shift new arrangement
		;could switch column by doing inc bobs+1 -> isc to compare with column?
		;have endvalue of bobs lowbyte in column to compare and in case to continue with
bob_2_lo
		!byte <(bob_2_0 + 1)
		!byte <(bob_2_1 + 1)
		!byte <(bob_2_2 + 1)
		!byte <(bob_2_3 + 1)
		!byte <(bob_2_4 + 1)
		!byte <(bob_2_5 + 1)
		!byte <(bob_2_6 + 1)
		!byte <(bob_2_7 + 1)

bob_3_lo
		!byte <(bob_3_0 + 1)
		!byte <(bob_3_1 + 1)
		!byte <(bob_3_2 + 1)
		!byte <(bob_3_3 + 1)
		!byte <(bob_3_4 + 1)
		!byte <(bob_3_5 + 1)
		!byte <(bob_3_6 + 1)
		!byte <(bob_3_7 + 1)

bob_4_lo
		!byte <(bob_4_0 + 1)
		!byte <(bob_4_1 + 1)
		!byte <(bob_4_2 + 1)
		!byte <(bob_4_3 + 1)
		!byte <(bob_4_4 + 1)
		!byte <(bob_4_5 + 1)
		!byte <(bob_4_6 + 1)
		!byte <(bob_4_7 + 1)

bob_5_lo
		!byte <(bob_5_0 + 1)
		!byte <(bob_5_1 + 1)
		!byte <(bob_5_2 + 1)
		!byte <(bob_5_3 + 1)
		!byte <(bob_5_4 + 1)
		!byte <(bob_5_5 + 1)
		!byte <(bob_5_6 + 1)
		!byte <(bob_5_7 + 1)

bob_6_lo
		!byte <(bob_6_0 + 1)
		!byte <(bob_6_1 + 1)
		!byte <(bob_6_2 + 1)
		!byte <(bob_6_3 + 1)
		!byte <(bob_6_4 + 1)
		!byte <(bob_6_5 + 1)
		!byte <(bob_6_6 + 1)
		!byte <(bob_6_7 + 1)

bob_7_lo
		!byte <(bob_7_0 + 1)
		!byte <(bob_7_1 + 1)
		!byte <(bob_7_2 + 1)
		!byte <(bob_7_3 + 1)
		!byte <(bob_7_4 + 1)
		!byte <(bob_7_5 + 1)
		!byte <(bob_7_6 + 1)
		!byte <(bob_7_7 + 1)

bob_8_lo
		!byte <(bob_8_0 + 1)
		!byte <(bob_8_1 + 1)
		!byte <(bob_8_2 + 1)
		!byte <(bob_8_3 + 1)
		!byte <(bob_8_4 + 1)
		!byte <(bob_8_5 + 1)
		!byte <(bob_8_6 + 1)
		!byte <(bob_8_7 + 1)

bob_9_lo
		!byte <(bob_9_0 + 1)
		!byte <(bob_9_1 + 1)
		!byte <(bob_9_2 + 1)
		!byte <(bob_9_3 + 1)
		!byte <(bob_9_4 + 1)
		!byte <(bob_9_5 + 1)
		!byte <(bob_9_6 + 1)
		!byte <(bob_9_7 + 1)

bob_10_lo
		!byte <(bob_10_0 + 1)
		!byte <(bob_10_1 + 1)
		!byte <(bob_10_2 + 1)
		!byte <(bob_10_3 + 1)
		!byte <(bob_10_4 + 1)
		!byte <(bob_10_5 + 1)
		!byte <(bob_10_6 + 1)
		!byte <(bob_10_7 + 1)

bob_11_lo
		!byte <(bob_11_0 + 1)
		!byte <(bob_11_1 + 1)
		!byte <(bob_11_2 + 1)
		!byte <(bob_11_3 + 1)
		!byte <(bob_11_4 + 1)
		!byte <(bob_11_5 + 1)
		!byte <(bob_11_6 + 1)
		!byte <(bob_11_7 + 1)
!warn "end of speedcode: ",*
set_bubble
		sta $d027
		sta $d028
		sta $d029
		sta $d02a
		sta $d027 + 4

		tya
		sta $d800 + 16 * 40 + 7
		sta $d800 + 16 * 40 + 8
		sta $d800 + 16 * 40 + 9
		sta $d800 + 16 * 40 + 10
		sta $d800 + 16 * 40 + 11
		sta $d800 + 16 * 40 + 12
		sta $d800 + 16 * 40 + 13

		sta $d800 + 17 * 40 + 7
		sta $d800 + 17 * 40 + 8
		sta $d800 + 17 * 40 + 9
		sta $d800 + 17 * 40 + 10
		sta $d800 + 17 * 40 + 11
		sta $d800 + 17 * 40 + 12

		sta $d800 + 18 * 40 + 11
		sta $d800 + 18 * 40 + 12

		sta $d027 + 5
		ldx #26
-
		sta $d800 +  0 * 40 + 13,x
		sta $d800 +  24 * 40 + 13,x
		dex
		bpl -
		ldx #13
		jsr set_clm
		ldx #39
set_clm
		sta $d800 +  1 * 40,x
		sta $d800 +  2 * 40,x
		sta $d800 +  3 * 40,x
		sta $d800 +  4 * 40,x
		sta $d800 +  5 * 40,x
		sta $d800 +  6 * 40,x
		sta $d800 +  7 * 40,x
		sta $d800 +  8 * 40,x
		jsr .set_d800
.hmpf2
		sta $d800 + 19 * 40,x
		sta $d800 + 20 * 40,x
		sta $d800 + 21 * 40,x
		sta $d800 + 22 * 40,x
		sta $d800 + 23 * 40,x
		rts
set_dk
		sta $d800 + 23 * 40 + 38
		rts
set_box
		ldx #$0b
-
		sta $d800 + 3  * 40,x
		sta $d800 + 13 * 40,x
		dex
		bpl -
		inx
		jsr .hmpf
		ldx #11
.hmpf
		sta $d800 + 4  * 40,x
		sta $d800 + 5  * 40,x
		sta $d800 + 6  * 40,x
		sta $d800 + 7  * 40,x
		sta $d800 + 8  * 40,x
		sta $d800 + 9  * 40,x
		sta $d800 + 10 * 40,x
		sta $d800 + 11 * 40,x
		sta $d800 + 12 * 40,x
		rts
set_man
		ldx #6
-
		sta $d800 + 14 * 40,x
		sta $d800 + 15 * 40,x
		sta $d800 + 16 * 40,x
		sta $d800 + 17 * 40,x
		dex
		bpl -
		inx
		ldx #$a
-
		jsr .hmpf2
		sta $d800 + 18 * 40,x
		sta $d800 + 24 * 40,x
		dex
		bpl -
		rts
set_bob_cube
		ldx #$0a
-
		jsr .hmpf
		dex
		bne -
		rts

.set_d800
		sta $d800 +  9*40,x
		sta $d800 + 10*40,x
		sta $d800 + 11*40,x
		sta $d800 + 12*40,x
		sta $d800 + 13*40,x
		sta $d800 + 14*40,x
		sta $d800 + 15*40,x
		sta $d800 + 16*40,x
		sta $d800 + 17*40,x
		sta $d800 + 18*40,x
		rts
fade_down
		jsr set_man
		jsr set_bob_cube
		jsr set_bubble
		jsr set_box
		rts
clear_column
		lda #$00
	!for .x,1,23 {
	!if .x = 23 {
		cpx #$26
		beq +
	}
		sta screen1 + .x * 40,x
	}
		lda #$01
	!for .x,1,23 {
		sta $d800 + .x * 40,x
	}
+
		rts
!warn "end of fade_stuff: ",*
;		lda #$00
;!for .x, 0, 1000 {
;		sta screen1 + .x
;}
;		rts

;		lda #$00
;!for .x, 0, 1000 {
;		sta screen2 + .x
;}
;		rts

;!for .x,0,24 {
;	!fill 8,255
;	!fill 24,0
;	!fill 8,255
;}
;!fill $18,$ff

		* = sprite_data
!fill $40 * 4, 0
!bin "gfx/sprites.spr",$40, $40 * 4
!fill $40, 0
		* = bob_data
!align 255,0
bob_1_0
!for .y,0,3 {
!for .x,0,7 {
!byte		%10000000
}
!for .x,0,7 {
!byte		%01000000
}
!for .x,0,7 {
!byte		%00100000
}
!for .x,0,7 {
!byte		%00010000
}
!for .x,0,7 {
!byte		%00001000
}
!for .x,0,7 {
!byte		%00000100
}
!for .x,0,7 {
!byte		%00000010
}
!for .x,0,7 {
!byte		%00000001
}
}

!align 255,8
bob_9_0
!byte		%00111110
!byte		%01111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%01111111
!byte		%00111110

!byte		%00000000
!byte		%00000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%00000000
!byte		%00000000
bob_9_1
!byte		%00011111
!byte		%00111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%00111111
!byte		%00011111

!byte		%00000000
!byte		%10000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%10000000
!byte		%00000000
bob_9_2
!byte		%00001111
!byte		%00011111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00011111
!byte		%00001111

!byte		%10000000
!byte		%11000000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11000000
!byte		%10000000
bob_9_3
!byte		%00000111
!byte		%00001111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00001111
!byte		%00000111

!byte		%11000000
!byte		%11100000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11100000
!byte		%11000000
bob_9_4
!byte		%00000011
!byte		%00000111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00000111
!byte		%00000011

!byte		%11100000
!byte		%11110000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11110000
!byte		%11100000
bob_9_5
!byte		%00000001
!byte		%00000011
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000011
!byte		%00000001

!byte		%11110000
!byte		%11111000
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111000
!byte		%11110000
bob_9_6
!byte		%00000000
!byte		%00000001
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000001
!byte		%00000000

!byte		%11111000
!byte		%11111100
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111100
!byte		%11111000
bob_9_7
!byte		%00000000
!byte		%00000000
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000000
!byte		%00000000

!byte		%01111100
!byte		%11111110
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111110
!byte		%01111100
bob_9_8

!align 255,8
bob_10_0
!byte		%00011110
!byte		%00111111
!byte		%01111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%01111111
!byte		%00111111
!byte		%00011110

!byte		%00000000
!byte		%00000000
!byte		%10000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%10000000
!byte		%00000000
!byte		%00000000
bob_10_1
!byte		%00001111
!byte		%00011111
!byte		%00111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%00111111
!byte		%00011111
!byte		%00001111

!byte		%00000000
!byte		%10000000
!byte		%11000000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11000000
!byte		%10000000
!byte		%00000000
bob_10_2
!byte		%00000111
!byte		%00001111
!byte		%00011111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00011111
!byte		%00001111
!byte		%00000111

!byte		%10000000
!byte		%11000000
!byte		%11100000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11100000
!byte		%11000000
!byte		%10000000
bob_10_3
!byte		%00000011
!byte		%00000111
!byte		%00001111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00001111
!byte		%00000111
!byte		%00000011

!byte		%11000000
!byte		%11100000
!byte		%11110000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11110000
!byte		%11100000
!byte		%11000000
bob_10_4
!byte		%00000001
!byte		%00000011
!byte		%00000111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00000111
!byte		%00000011
!byte		%00000001

!byte		%11100000
!byte		%11110000
!byte		%11111000
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111000
!byte		%11110000
!byte		%11100000
bob_10_5
!byte		%00000000
!byte		%00000001
!byte		%00000011
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000011
!byte		%00000001
!byte		%00000000

!byte		%11110000
!byte		%11111000
!byte		%11111100
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111100
!byte		%11111000
!byte		%11110000
bob_10_6
!byte		%00000000
!byte		%00000000
!byte		%00000001
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000001
!byte		%00000000
!byte		%00000000

!byte		%01111000
!byte		%11111100
!byte		%11111110
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111110
!byte		%11111100
!byte		%01111000
bob_10_7
!byte		%00000000
!byte		%00000000
!byte		%00000000
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000000
!byte		%00000000
!byte		%00000000

!byte		%00111100
!byte		%01111110
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%01111110
!byte		%00111100

!byte		%00000000
!byte		%00000000
!byte		%00000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%00000000
!byte		%00000000
!byte		%00000000
bob_10_8

!align 255,8
bob_11_0
!byte		%00011111
!byte		%00111111
!byte		%01111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%01111111
!byte		%00111111
!byte		%00011111

!byte		%00000000
!byte		%10000000
!byte		%11000000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11000000
!byte		%10000000
!byte		%00000000
bob_11_1
!byte		%00001111
!byte		%00011111
!byte		%00111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%00111111
!byte		%00011111
!byte		%00001111

!byte		%10000000
!byte		%11000000
!byte		%11100000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11100000
!byte		%11000000
!byte		%10000000
bob_11_2
!byte		%00000111
!byte		%00001111
!byte		%00011111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00011111
!byte		%00001111
!byte		%00000111

!byte		%11000000
!byte		%11100000
!byte		%11110000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11110000
!byte		%11100000
!byte		%11000000
bob_11_3
!byte		%00000011
!byte		%00000111
!byte		%00001111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00001111
!byte		%00000111
!byte		%00000011

!byte		%11100000
!byte		%11110000
!byte		%11111000
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111000
!byte		%11110000
!byte		%11100000
bob_11_4
!byte		%00000001
!byte		%00000011
!byte		%00000111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00000111
!byte		%00000011
!byte		%00000001

!byte		%11110000
!byte		%11111000
!byte		%11111100
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111100
!byte		%11111000
!byte		%11110000
bob_11_5
!byte		%00000000
!byte		%00000001
!byte		%00000011
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000011
!byte		%00000001
!byte		%00000000

!byte		%11111000
!byte		%11111100
!byte		%11111110
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111110
!byte		%11111100
!byte		%11111000
bob_11_6
!byte		%00000000
!byte		%00000000
!byte		%00000001
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000001
!byte		%00000000
!byte		%00000000

!byte		%01111100
!byte		%11111110
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111110
!byte		%01111100

!byte		%00000000
!byte		%00000000
!byte		%00000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%00000000
!byte		%00000000
!byte		%00000000
bob_11_7
!byte		%00000000
!byte		%00000000
!byte		%00000000
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000000
!byte		%00000000
!byte		%00000000

!byte		%00111110
!byte		%01111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%01111111
!byte		%00111110

!byte		%00000000
!byte		%00000000
!byte		%10000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%10000000
!byte		%00000000
!byte		%00000000
bob_11_8

!align 255,8
bob_2_0
!byte		%11000000
!byte		%11000000
bob_2_1
!byte		%01100000
!byte		%01100000
bob_2_2
!byte		%00110000
!byte		%00110000
bob_2_3
!byte		%00011000
!byte		%00011000
bob_2_4
!byte		%00001100
!byte		%00001100
bob_2_5
!byte		%00000110
!byte		%00000110
bob_2_6
!byte		%00000011
!byte		%00000011
bob_2_7
!byte		%00000001
!byte		%00000001

!byte		%10000000
!byte		%10000000
bob_2_8

bob_3_0
!byte		%01000000
!byte		%11100000
!byte		%01000000
bob_3_1
!byte		%00100000
!byte		%01110000
!byte		%00100000
bob_3_2
!byte		%00010000
!byte		%00111000
!byte		%00010000
bob_3_3
!byte		%00001000
!byte		%00011100
!byte		%00001000
bob_3_4
!byte		%00000100
!byte		%00001110
!byte		%00000100
bob_3_5
!byte		%00000010
!byte		%00000111
!byte		%00000010
bob_3_6
!byte		%00000001
!byte		%00000011
!byte		%00000001

!byte		%00000000
!byte		%10000000
!byte		%00000000
bob_3_7
!byte		%00000000
!byte		%00000001
!byte		%00000000

!byte		%10000000
!byte		%11000000
!byte		%10000000
bob_3_8

bob_4_0
!byte		%01100000
!byte		%11110000
!byte		%11110000
!byte		%01100000
bob_4_1
!byte		%00110000
!byte		%01111000
!byte		%01111000
!byte		%00110000
bob_4_2
!byte		%00011000
!byte		%00111100
!byte		%00111100
!byte		%00011000
bob_4_3
!byte		%00001100
!byte		%00011110
!byte		%00011110
!byte		%00001100
bob_4_4
!byte		%00000110
!byte		%00001111
!byte		%00001111
!byte		%00000110
bob_4_5
!byte		%00000011
!byte		%00000111
!byte		%00000111
!byte		%00000011

!byte		%00000000
!byte		%10000000
!byte		%10000000
!byte		%00000000
bob_4_6
!byte		%00000001
!byte		%00000011
!byte		%00000011
!byte		%00000001

!byte		%10000000
!byte		%11000000
!byte		%11000000
!byte		%10000000
bob_4_7
!byte		%00000000
!byte		%00000001
!byte		%00000001
!byte		%00000000

!byte		%11000000
!byte		%11100000
!byte		%11100000
!byte		%11000000
bob_4_8

bob_5_0
!byte		%01110000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%01110000
bob_5_1
!byte		%00111000
!byte		%01111100
!byte		%01111100
!byte		%01111100
!byte		%00111000
bob_5_2
!byte		%00011100
!byte		%00111110
!byte		%00111110
!byte		%00111110
!byte		%00011100
bob_5_3
!byte		%00001110
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00001110
bob_5_4
!byte		%00000111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00000111

!byte		%00000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%00000000
bob_5_5
!byte		%00000011
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000011

!byte		%10000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%10000000
bob_5_6
!byte		%00000001
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000001

!byte		%11000000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11000000
bob_5_7
!byte		%00000000
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000000

!byte		%11100000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11100000
bob_5_8

bob_6_0
!byte		%01111000
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%01111000
bob_6_1
!byte		%00111100
!byte		%01111110
!byte		%01111110
!byte		%01111110
!byte		%01111110
!byte		%00111100
bob_6_2
!byte		%00011110
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00011110
bob_6_3
!byte		%00001111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00001111

!byte		%00000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%00000000
bob_6_4
!byte		%00000111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00000111

!byte		%10000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%10000000
bob_6_5
!byte		%00000011
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000011

!byte		%11000000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11000000
bob_6_6
!byte		%00000001
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000001

!byte		%11100000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11100000
bob_6_7
!byte		%00000000
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000000

!byte		%11110000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11110000
bob_6_8

!align 255,8
;XXX TODO align data that way that first column is in page 0 and second in page 1 and third in page 2?
;but this would require a set of bobs+1 per plot not per size :-( but therefore no need to add size to bob on each column?
bob_7_0
!byte		%00111000
!byte		%01111100
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%01111100
!byte		%00111000
bob_7_1
!byte		%00011100
!byte		%00111110
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%00111110
!byte		%00011100
bob_7_2
!byte		%00001110
!byte		%00011111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00011111
!byte		%00001110

!byte		%00000000
!byte		%00000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%00000000
!byte		%00000000
bob_7_3
!byte		%00000111
!byte		%00001111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00001111
!byte		%00000111

!byte		%00000000
!byte		%10000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%10000000
!byte		%00000000
bob_7_4
!byte		%00000011
!byte		%00000111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00000111
!byte		%00000011

!byte		%10000000
!byte		%11000000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11000000
!byte		%10000000
bob_7_5
!byte		%00000001
!byte		%00000011
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000011
!byte		%00000001

!byte		%11000000
!byte		%11100000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11100000
!byte		%11000000
bob_7_6
!byte		%00000000
!byte		%00000001
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000001
!byte		%00000000

!byte		%11100000
!byte		%11110000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11110000
!byte		%11100000
bob_7_7
!byte		%00000000
!byte		%00000000
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000000
!byte		%00000000

!byte		%01110000
!byte		%11111000
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111000
!byte		%01110000
bob_7_8

bob_8_0
!byte		%00111100
!byte		%01111110
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%11111111
!byte		%01111110
!byte		%00111100
bob_8_1
!byte		%00011110
!byte		%00111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%01111111
!byte		%00111111
!byte		%00011110

!byte		%00000000
!byte		%00000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%10000000
!byte		%00000000
!byte		%00000000
bob_8_2
!byte		%00001111
!byte		%00011111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00111111
!byte		%00011111
!byte		%00001111

!byte		%00000000
!byte		%10000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%11000000
!byte		%10000000
!byte		%00000000
bob_8_3
!byte		%00000111
!byte		%00001111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00011111
!byte		%00001111
!byte		%00000111

!byte		%10000000
!byte		%11000000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11100000
!byte		%11000000
!byte		%10000000
bob_8_4
!byte		%00000011
!byte		%00000111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00001111
!byte		%00000111
!byte		%00000011

!byte		%11000000
!byte		%11100000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11110000
!byte		%11100000
!byte		%11000000
bob_8_5
!byte		%00000001
!byte		%00000011
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000111
!byte		%00000011
!byte		%00000001

!byte		%11100000
!byte		%11110000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11111000
!byte		%11110000
!byte		%11100000
bob_8_6
!byte		%00000000
!byte		%00000001
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000011
!byte		%00000001
!byte		%00000000

!byte		%11110000
!byte		%11111000
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111100
!byte		%11111000
!byte		%11110000
bob_8_7
!byte		%00000000
!byte		%00000000
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000001
!byte		%00000000
!byte		%00000000

!byte		%01111000
!byte		%11111100
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111110
!byte		%11111100
!byte		%01111000
bob_8_8
!warn "bob data ends @ ", *

