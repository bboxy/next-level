!convtab scr
!cpu 6510

COL_FLOOR	= $0f
COL_SHADOW	= $0b

;XXX TODO enough to set new charblocks at scroll_screen + 38 and shift 38..0
;XXX TODO update on fpp also needs to be done one block more to the left, also mostright block can be omitted

;free
;0400 - 0800
;ec80 - f400

charsets	= $4000
charset00	= charsets + 0 * $0800
charset01	= charsets + 1 * $0800
charset02	= charsets + 2 * $0800
charset03	= charsets + 3 * $0800
charset04	= charsets + 4 * $0800
charset05	= charsets + 5 * $0800
charset06	= charsets + 6 * $0800
charset07	= charsets + 7 * $0800
screen 		= $f400

screen0		= charset00 + $280
screen1		= charset00 + $680
screen2		= charset01 + $280
screen3		= charset01 + $680
screen4		= charset02 + $280
screen5		= charset02 + $680
screen6		= charset03 + $680
screen7		= charset04 + $280

numpre		= 328
fact_x		= 55

prepix		= $2000		;generated code up to $4000
ysource		= $3cb0
cnttab		= $3cf0
modulo58	= $3d00
modulo58plus	= $3d58
font_widths	= $3dc0
shifttab	= $3e00
font_lo		= $3e60
font_hi		= $3ea0
shift5r		= $3f00


lines		= $8000		;free memory for init code up to $9800
main2		= $9800		;$cc00 gen code
main3		= $ec80		;$f400
main4		= $f680		;$f800
main5		= $cd00		;$d000

sun_sprites	= $d000
cloud_sprites	= $de00
logo_bitmap	= $e000
scroll_screen	= screen
multi_font	= $f800

		;XXX TODO probably one page free ($df00-$e000 -> can place another page in front

multimap	= charset02 + $6a8		;$588 bytes
hiresmap	= charset04 + $2a8		;$588 bytes
xshiftpre	= charset06 + $68
xpospre		= xshiftpre + $480
fadercode	= charset01 + 1
cols_sun	= coltab_lo_a + 1
cols_sun2	= coltab_lo_a + 0

dst		= $02
src		= $04
chr		= $06
num		= $08
tmp		= $10

col_ground	= $0e
col_shadow	= $06
col_sky		= $0a
col_logo1	= $03	;$04	;03
col_logo2	= $06	;06
col_logo3	= $09	;$09	;04
col_logo4	= $02	;$02	;0e

fr8		= $02
fr16		= $03

sscr		= $04
map		= $06
cwidth		= $08
clm		= $09

temp		= $0b
max_d012	= $0d
xt		= $0f
xfr8		= $10

frame		= $12

hmap		= $14
pend		= $16

irqs		= $18

yline		= $2d ;+= $30

xbyte		= $60
charbyte	= $90

!ifndef release {
		* = $0800
music
;!bin "starquest.sid",,$7e
!bin "../../music/music.prg",,2
;!bin "../../music/PREV2.PRG",,2
}
!src "coltab_defs.asm"
!ifdef release {
                !src "../../bitfire/loader/loader_acme.inc"
                !src "../../bitfire/macros/link_macros_acme.inc"
}

.INIT_COL		= $01
.INIT_COL_BORDER	= $01
		;XXX TODO would be nice to have this in higher mem where all generated code resides
		* = fadercode
fade
!src "fade_gen.asm"
fadercode_end
		* = lines
spr_y		= $92

start_part
		sei
		lxa #0
		ldy #$f
-
		lda #$00
.dstch		sta charset00 + $000,x
		txa
.incc		sbx #$01
		bne -
		inc .dstch + 2
		lda .dstch + 2
		and #$08
		beq +
		sta .incc + 1
+
		dey
		bpl -
;-
;		lda fade + $000,x
;		sta charset01 + $001,x
;		lda fade + $100,x
;		sta charset01 + $101,x
;		lda fade + $200,x
;		sta charset01 + $201,x
;		lda fade + $300,x
;		sta charset01 + $301,x
;		lda fade + $400,x
;		sta charset01 + $401,x
;		lda fade + $500,x
;		sta charset01 + $501,x
;		lda fade + $600,x
;		sta charset01 + $601,x
;		lda fade + $700,x
;		sta charset01 + $701,x
;		dex
;		bne -

		ldx #jmps_ - jmps
-
		lda jmps,x
		sta irqs,x
		dex
		bpl-

		txs

		jsr wait
!ifndef release {
		lda #$35
		sta $01
}
		lda #$fc
		sta $d01b
		lda #$0b
		sta $d011
		lda #$00
		sta $d01c
		lda #$02
		sta $dd00
		lda #$08
		sta $d016
		lda #$70
		sta $d018
		sta $d027
		sta $d028
!ifndef release {
		lda #.INIT_COL_BORDER
		sta $d020

		lda #$00
		tax
		tay
		jsr music
}
		lda #$1d
		sta $d005
		sta $d007
		sta $d009
		sta $d00b
		sta $d00d
		sta $d00f
		lda #$20
		sta $d004
		clc
		adc #24
		sta $d006
		adc #24
		sta $d008
		adc #24
		sta $d00a
		adc #24
		sta $d00c
		lda #$38
		sta $d00e
		lda #$01
		sta $d029
		sta $d02a
		sta $d02b
		sta $d02c
		sta $d02d
		sta $d02e
		lda #$80
		sta $d010
		ldx #(<(cloud_sprites / $40)) + 0
		stx scroll_screen + $03fa
		inx
		stx scroll_screen + $03fb
		inx
		stx scroll_screen + $03fc
		inx
		stx scroll_screen + $03fd
		inx
		stx scroll_screen + $03fe
		inx
		stx scroll_screen + $03ff

		;generate unrolled code
		lda #<prepix
		sta dst
		lda #>prepix
		sta dst + 1
		jsr gen_prepix
		jsr gen_gen
		jsr gen_ystretch
		jsr gen_screens
		jsr gen_tabs

		lda #<gencode_tgt
		sta dst
		lda #>gencode_tgt
		sta dst + 1

		jsr gen_xu

		lda start_fpp
		sta pcode

		lda #<start_fpp
		sta pend
		lda #>start_fpp
		sta pend + 1

		ldx #$2f
-
		lda xbytetab,x
		sta xbyte,x
		dex
		bpl -

		lda #$00
		sta frame
		sta clm
		sta cwidth
		sta max_d012

		;calculate first set of frames

		txa
		lda #$aa
		ldy #$07
-
		sta charset00 + $2ff8,y
		sta charset00 + $07f8,y
		dey
		bpl -
;		inx

;		lda #$0b
;-
;		sta scroll_screen + 10 * 40,x
;		inx
;		cpx #$f0
;		bne -

		lda #COL_FLOOR
		jsr col_lower

		ldx #$27
-
		lda #$ff
		sta screen6,x
		lda #$fe
		sta screen7,x
		lda #$08 + 3 ;0c
		sta $d800 + 10 * 40,x
		lda #$08 ;0a
		sta $d800 + 11 * 40,x
		sta $d800 + 12 * 40,x
		sta $d800 + 13 * 40,x
		sta $d800 + 14 * 40,x
		sta $d800 + 15 * 40,x
		lda #.INIT_COL
		sta $d800 + 16 * 40,x
		dex
		bpl -

		;lda #$02;9
		lda #$06
		sta $d022
		lda #$04
		;lda #$02;2
		sta $d023

		lda #<irq4_
		sta $fffe
		lda #>irq4_
		sta $ffff
!ifndef release {
		lda #$7f
		sta $dc0d
		lda $dc0d
		lda #$01
		sta $d019
		sta $d01a
}
		lda #$00
		sta $d012
		lda #$0b
		sta $d011
		lda $d011
		bmi *-3
		lda $d012
		bne *-3

		jmp start
jmps
!pseudopc irqs {
irq4_		jmp irq4
irq5_		jmp irq5
irq6_		jmp irq6
firq0		jmp firq0_
firq4		jmp firq4_
}
jmps_
gen_tabs
		ldx #$40
		lda #$80
-
		sta ysource - 1,x
		dex
		bne -
-
		txa
		lsr
		lsr
		lsr
		lsr
		lsr
		sta shift5r,x
		inx
		bne -

		inx
-
		txa
		sta modulo58 - 1,x
		inx
		cpx #$b0
		bne -
		lda #$00
		sta modulo58 + $57
		lda #$58
		sta modulo58plus + $57

		ldx #$0f
-
		lda cnttab_,x
		sta cnttab,x
		dex
		bpl -

		ldx #$3f
-
		lda font_widths_,x
		sta font_widths,x
		lda font_lo_,x
		sta font_lo,x
		lda font_hi_,x
		sta font_hi,x
		dex
		bpl -

		ldx #$5f
		lda #$00
-
		sta shifttab,x
		dex
		bpl -
		rts

font_widths_
		!byte 0
		!byte 6 ;A
		!byte 6 ;B
		!byte 6 ;C
		!byte 6 ;D
		!byte 6 ;E
		!byte 6 ;F
		!byte 6 ;G
		!byte 6 ;H
		!byte 4 ;I
		!byte 6 ;J
		!byte 6 ;K
		!byte 6 ;L
		!byte 8 ;M
		!byte 6 ;N
		!byte 6 ;O
		!byte 6 ;P
		!byte 6 ;Q
		!byte 6 ;R
		!byte 6 ;S
		!byte 6 ;T
		!byte 6 ;U
		!byte 6 ;V
		!byte 8 ;W
		!byte 6 ;X
		!byte 6 ;Y
		!byte 6 ;Z
		!byte 0;6 ;A
		!byte 0;6 ;A
		!byte 0;6 ;A
		!byte 0;6 ;A
		!byte 0;6 ;A
		!byte 4 ;" "
		!byte 0;2 ;!
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;2 ;'
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;2 ;,
		!byte 0;6 ;
		!byte 0;2 ;.
		!byte 0;6 ;
		!byte 0;6 ;0
		!byte 0;6 ;1
		!byte 0;6 ;2
		!byte 0;6 ;3
		!byte 0;6 ;4
		!byte 0;6 ;5
		!byte 0;6 ;6
		!byte 0;6 ;7
		!byte 0;6 ;8
		!byte 0;6 ;9
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 0;6 ;
		!byte 6 ;?
font_lo_
		!byte 00
		!byte <(000 * 8 + multimap + 2);A
		!byte <(006 * 8 + multimap + 2);B
		!byte <(012 * 8 + multimap + 2);C
		!byte <(018 * 8 + multimap + 2);D
		!byte <(024 * 8 + multimap + 2);E
		!byte <(030 * 8 + multimap + 2);F
		!byte <(036 * 8 + multimap + 2);G
		!byte <(042 * 8 + multimap + 2);H
		!byte <(048 * 8 + multimap + 2);I
		!byte <(052 * 8 + multimap + 2);J
		!byte <(058 * 8 + multimap + 2);K
		!byte <(064 * 8 + multimap + 2);L
		!byte <(070 * 8 + multimap + 2);M
		!byte <(078 * 8 + multimap + 2);N
		!byte <(084 * 8 + multimap + 2);O
		!byte <(090 * 8 + multimap + 2);P
		!byte <(096 * 8 + multimap + 2);Q
		!byte <(102 * 8 + multimap + 2);R
		!byte <(108 * 8 + multimap + 2);S
		!byte <(114 * 8 + multimap + 2);T
		!byte <(120 * 8 + multimap + 2);U
		!byte <(126 * 8 + multimap + 2);V
		!byte <(132 * 8 + multimap + 2);W
		!byte <(140 * 8 + multimap + 2);X
		!byte <(146 * 8 + multimap + 2);Y
		!byte <(152 * 8 + multimap + 2);Z
		!byte $00 ;
		!byte $00 ;
		!byte $00 ;
		!byte $00 ;
		!byte $00 ;
		!byte <(232 * 8 + multimap + 2) ;" "
		!byte $00;<(158 * 8 + multimap + 2) ;!
		!byte $00 ;"
		!byte $00 ;#
		!byte $00 ;$
		!byte $00 ;%
		!byte $00 ;&
		!byte $00;<(170 * 8 + multimap + 2) ;'
		!byte $00 ;(
		!byte $00 ; + 2)
		!byte $00 ;*
		!byte $00 ;+
		!byte $00;<(168 * 8 + multimap + 2) ;,
		!byte $00 ;-
		!byte $00;<(166 * 8 + multimap + 2) ;.
		!byte $00 ;/
		!byte $00;<(172 * 8 + multimap + 2) ;0
		!byte $00;<(178 * 8 + multimap + 2) ;1
		!byte $00;<(184 * 8 + multimap + 2) ;2
		!byte $00;<(190 * 8 + multimap + 2) ;3
		!byte $00;<(196 * 8 + multimap + 2) ;4
		!byte $00;<(202 * 8 + multimap + 2) ;5
		!byte $00;<(208 * 8 + multimap + 2) ;6
		!byte $00;<(214 * 8 + multimap + 2) ;7
		!byte $00;<(220 * 8 + multimap + 2) ;8
		!byte $00;<(226 * 8 + multimap + 2) ;9
		!byte $00 ;/
		!byte $00 ;/
		!byte $00 ;/
		!byte $00 ;/
		!byte $00 ;/
		!byte <(160 * 8 + multimap + 2) ;?
font_hi_
		!byte 00
		!byte >(000 * 8 + multimap + 2);A
		!byte >(006 * 8 + multimap + 2);B
		!byte >(012 * 8 + multimap + 2);C
		!byte >(018 * 8 + multimap + 2);D
		!byte >(024 * 8 + multimap + 2);E
		!byte >(030 * 8 + multimap + 2);F
		!byte >(036 * 8 + multimap + 2);G
		!byte >(042 * 8 + multimap + 2);H
		!byte >(048 * 8 + multimap + 2);I
		!byte >(052 * 8 + multimap + 2);J
		!byte >(058 * 8 + multimap + 2);K
		!byte >(064 * 8 + multimap + 2);L
		!byte >(070 * 8 + multimap + 2);M
		!byte >(078 * 8 + multimap + 2);N
		!byte >(084 * 8 + multimap + 2);O
		!byte >(090 * 8 + multimap + 2);P
		!byte >(096 * 8 + multimap + 2);Q
		!byte >(102 * 8 + multimap + 2);R
		!byte >(108 * 8 + multimap + 2);S
		!byte >(114 * 8 + multimap + 2);T
		!byte >(120 * 8 + multimap + 2);U
		!byte >(126 * 8 + multimap + 2);V
		!byte >(132 * 8 + multimap + 2);W
		!byte >(140 * 8 + multimap + 2);X
		!byte >(146 * 8 + multimap + 2);Y
		!byte >(152 * 8 + multimap + 2);Z
		!byte $00 ;
		!byte $00 ;
		!byte $00 ;
		!byte $00 ;
		!byte $00 ;
		!byte >(232 * 8 + multimap + 2) ;" "
		!byte $00;>(158 * 8 + multimap + 2) ;!
		!byte $00 ;"
		!byte $00 ;#
		!byte $00 ;$
		!byte $00 ;%
		!byte $00 ;&
		!byte $00;>(170 * 8 + multimap + 2) ;'
		!byte $00 ;(
		!byte $00 ; + 2)
		!byte $00 ;*
		!byte $00 ;+
		!byte $00;>(168 * 8 + multimap + 2) ;,
		!byte $00 ;-
		!byte $00;>(166 * 8 + multimap + 2) ;.
		!byte $00 ;/
		!byte $00;>(172 * 8 + multimap + 2) ;0
		!byte $00;>(178 * 8 + multimap + 2) ;1
		!byte $00;>(184 * 8 + multimap + 2) ;2
		!byte $00;>(190 * 8 + multimap + 2) ;3
		!byte $00;>(196 * 8 + multimap + 2) ;4
		!byte $00;>(202 * 8 + multimap + 2) ;5
		!byte $00;>(208 * 8 + multimap + 2) ;6
		!byte $00;>(214 * 8 + multimap + 2) ;7
		!byte $00;>(220 * 8 + multimap + 2) ;8
		!byte $00;>(226 * 8 + multimap + 2) ;9
		!byte $00 ;/
		!byte $00 ;/
		!byte $00 ;/
		!byte $00 ;/
		!byte $00 ;/
		!byte >(160 * 8 + multimap + 2) ;?
cnttab_
		!byte $01,$02,$03,$04,$05,$06,$07,$09,$0a,$0b,$0c,$0d,$0e,$0f,$11,$12
xbytetab
!for .num,0,47 {
		!byte 1 << (((((256 << 8) * (.num ))/fact_x * numpre) / 65536) & 7)
}

gen_xu
		lda dst
		sta xupdate_jmp + 1
		lda dst + 1
		sta xupdate_jmp + 2

		lda #$00
		sta num

		lda #<lines + 1
		sta src
		lda #>lines
		sta src + 1

		lda #<charset00
		sta chr
		lda #>charset00
		sta chr + 1


xu_copy
		lax dst
		sbx #-1
		stx xu_jmp + 1
		lda dst + 1
		adc #$01
		sta xu_jmp + 2

		lax dst
		sbx #-(xu_xposp - xupdate_temp + 1)
		stx xu_xposp_stx + 1
		lda dst + 1
		adc #$00
		sta xu_xposp_stx + 2

		ldy #xupdate_temp_size - 1
-
		lda xupdate_temp,y
		sta (dst),y
		dey
		bpl -

		lax dst
		sbx #-xupdate_temp_size
		stx dst
		bcc +
		inc dst + 1
+
		inc xu_yline + 1
		lax xu_xshift + 1
		sbx #-$18
		stx xu_xshift + 1
		bcc +
		inc xu_xshift + 2
+
		lax xu_xpos + 1
		sbx #-$18
		stx xu_xpos + 1
		bcc +
		inc xu_xpos + 2
+
		lax xu_shifttab + 1
		sbx #-$10
		cpx #$60
		bcc +
		lda #$0f
		sbx #-$02
+
		stx xu_shifttab + 1

		ldx #38
-
		lda num
		cmp #$50
		bne +
		lda #$55
+
		cmp #$d0
		bne +
		lda #$d5
+
		cmp #$fa
		bne +
		lda .cset + 1
		clc
		adc #$08
		sta .cset + 1
		lda #$00
+
		sta num
		sta chr
		lda #$00
		asl chr
		rol
		asl chr
		rol
		asl chr
		rol
.cset		ora #>charset00
		sta chr + 1

		ldy #$05
		sta (dst),y
		dey
		lda chr
		sta (dst),y
		dey
		lda #$8d
		sta (dst),y
		dey
		lda src + 1
		sta (dst),y
		dey
		lda src
		sta (dst),y
		dey
		lda #$bd
		sta (dst),y

		lda #$06
		adc dst
		sta dst
		bcc +
		inc dst + 1
+
		inc num
		inc src
		dex
		bpl -

		inc num

		lda src
		and #$80
		eor #$81
		sta src
		bmi +
		inc src + 1
+

		dec xu_num
		bmi +
		jmp xu_copy
+
end_gen
		ldy #$00
		lda #$60
		sta (dst),y
		inc dst
		bne +
		inc dst + 1
+
		rts

xu_num
!byte		$2f

xupdate_temp
		;XXX TODO combine with Y no need to write shifttabs beyond needed position?
xu_yline	lda yline; + .num
		bmi +
xu_xshift	lda xshiftpre,y; + .num * $18,y
xu_shifttab	sta shifttab; + .shpos

xu_xpos		lax xpospre,y; + .num * $18,y
xu_xposp	cpx #$ff
		bne *+5
+
xu_jmp		jmp $0000
xu_xposp_stx	stx $0000	;xu_xposp + 1
xupdate_temp_end
xupdate_temp_size = xupdate_temp_end - xupdate_temp

gen_gen
		lda dst
		sta gen_jmp + 1
		lda dst + 1
		sta gen_jmp + 2

gen_loop
		lax dst
		sbx #-(g_lo_lda - gen_temp + 1)
		stx g_lo_sta + 1
		lda dst + 1
		adc #$00
		sta g_lo_sta + 2

		lax dst
		sbx #-(g_hi_lda - gen_temp + 1)
		stx g_hi_sta + 1
		lda dst + 1
		adc #$00
		sta g_hi_sta + 2

		lax dst
		sbx #-(g_modx - gen_temp + 1)
		stx g_modx_sty + 1
		lda dst + 1
		adc #$00
		sta g_modx_sty + 2

.glx		ldx #$00
		lda g_lo_lda_tab,x
		sta g_lo_lda + 1
		lda g_lo_adc_tab,x
		sta g_lo_adc + 1
		lda g_hi_lda_tab,x
		sta g_hi_lda + 1
		lda g_hi_adc_tab,x
		sta g_hi_adc + 1
		lda g_modx_tab,x
		sta g_modx + 1

		ldy #gen_temp_size - 1
-
		lda gen_temp,y
		sta (dst),y
		dey
		bpl -

		lda #gen_temp_size
		clc
		adc dst
		sta dst
		bcc +
		inc dst + 1
+

		dec g_charbyte + 1
		inc g_xbyte1 + 1
		inc g_xbyte2 + 1
		inc g_xbyte3 + 1
		inc g_xbyte4 + 1

		lda g_line1 + 1
		eor #$80
		sta g_line1 + 1
		bmi +
		inc g_line1 + 2
+
		lda g_line2 + 1
		eor #$80
		sta g_line2 + 1
		bmi +
		inc g_line2 + 2
+
		sec
		lda #$30
		isc .glx + 1
		beq *+5
		jmp gen_loop
		jmp end_gen

gen_temp
		;xreg is still free
g_xbyte1	lda xbyte
.norm
g_charbyte	rol charbyte + 47
		beq .end
		rol
		;store for later duplication
g_xbyte2	sax xbyte
		bcs .nextblock
-
		tay

		;initial 39 rounds
g_lo_lda	lda #$00
g_lo_adc	adc #$00
g_lo_sta	sta g_lo_lda + 1
g_hi_lda	lda #$00
g_hi_adc	adc #$00
g_hi_sta	sta g_hi_lda + 1

		tya
		bcc .norm
.single
		;duplicate bit or insert clear pixels
		asl
g_xbyte3	ora xbyte
		bcc .norm
		clc
.nextblock
		;initial 39 rounds
		;XXX TODO also use this in prepix?
g_modx		ldy modulo58plus		;Y = Y + 1 % 58
		;use autoincrementing component, wrap is done via table too
g_modx_sty	sty g_modx + 1
		;write from $00 till $58
g_line1		sta lines-$58,y
		bmi +
		;only write first $28 bytes from $58 on, then stop to not write out of bounds
g_line2		sta lines,y
+
		;XXX TODO use the bmi already to branch? and avoid the clc bcc always?
		lda #$01
		bcc .norm
		clc
		bcc -
.end
g_xbyte4	sta xbyte
		;XXX TODO merge again if better idea taht takes either path1 or 2
gen_temp_end
gen_temp_size = gen_temp_end - gen_temp

g_lo_lda_tab
!for .x,0,47 {
		!byte <(((256 << 8) * (.x ))/fact_x * numpre)
}
g_lo_adc_tab
!for .x,0,47 {
		!byte <(((256 << 8) * (.x ))/fact_x)
}
g_hi_lda_tab
!for .x,0,47 {
		!byte >(((256 << 8) * (.x ))/fact_x * numpre)
}
g_hi_adc_tab
!for .x,0,47 {
		!byte >(((256 << 8) * (.x ))/fact_x)
}
g_modx_tab
!for .x,0,47 {
		!byte ((((256 << 8) * (.x ))/fact_x * numpre) / 65536 / 8) + $26 + $58
}

gen_prepix
prepix_loop
.pplx		ldx #$00
		lda g_lo_adc_tab,x
		sta xs_lo_adc + 1
		lda g_hi_adc_tab,x
		sta xs_hi_adc + 1

		lax dst
		sbx #-(xs_lo_lda - xshift_temp + 1)
		stx xs_lo_sta + 1
		lda dst + 1
		adc #$00
		sta xs_lo_sta + 2

		lax dst
		sbx #-(xs_hi_lda - xshift_temp + 1)
		stx xs_hi_sta + 1
		lda dst + 1
		adc #$00
		sta xs_hi_sta + 2

		lax dst
		sbx #-(xs_xp - xshift_temp + 1)
		stx xs_xp_sta + 1
		lda dst + 1
		adc #$00
		sta xs_xp_sta + 2

		lax dst
		sbx #-(xs_xpos - xshift_temp + 1)
		stx xs_xpos_sta + 1
		lda dst + 1
		adc #$00
		sta xs_xpos_sta + 2

		lax dst
		sbx #-(xs_xshift - xshift_temp + 1)
		stx xs_xshift_sta + 1
		lda dst + 1
		adc #$00
		sta xs_xshift_sta + 2

		ldy #xshift_temp_size - 1
		cpx #$2f
		bne +
		ldy #xshift_temp_size2 - 1
+
-
		lda xshift_temp,y
		sta (dst),y
		dey
		bpl -

		lda #xshift_temp_size
		cpx #$2f
		bne +
		lda #xshift_temp_size2
+
		clc
		adc dst
		sta dst
		bcc +
		inc dst + 1
+
		lax xs_xshift_y + 1
		sbx #-$18
		stx xs_xshift_y + 1
		bcc +
		inc xs_xshift_y + 2
+
		lax xs_xpos_y + 1
		sbx #-$18
		stx xs_xpos_y + 1
		bcc +
		inc xs_xpos_y + 2
+
		sec
		lda #$30
		isc .pplx + 1
		beq *+5
		jmp prepix_loop
		jmp end_gen


xshift_temp
		;reverse everything, start with subtraction and sec? to flip meaning of carry?
xs_lo_lda	lda #$00
xs_lo_adc	adc #$00
xs_lo_sta	sta xs_lo_lda + 1
xs_hi_lda	lda #$00
xs_hi_adc	adc #$00
xs_hi_sta	sta xs_hi_lda + 1

		;either subtract one or two?

xs_xshift	lda #$f8
		adc #$01	;add either 1 or 2
		bcc ++
		sbc #$08
		pha
xs_xp 		lda modulo58
xs_xp_sta	sta xs_xp + 1
xs_xpos_sta	sta xs_xpos + 1
		pla
++
xs_xshift_sta	sta xs_xshift + 1
		;clc
		adc shift5r,x
		;add offset bits 0..2 here, on overflow, also add one more on blocks (carry)
		;XXX TODO ungenauigkeit deshalb!!!!
		eor #$07
		;xshift
xs_xshift_y	sta xshiftpre,y

		;doing modulo twice is PITA
		;XXX TODO on each second line we can wrap @ $80 or such as we can subtract $28 and more beforehand without having a penalty
xs_xpos 	lda #$00
		;XXX TODO reload xs_xp + 1?
;!if .num != 0 {
		adc xt
		;max $58 + $58 -> can not overrun
		cmp #$58
		bcc +
		sbc #$58
		clc
+
;}
xs_xpos_y	sta xpospre,y
xshift_temp_end2
		txa
		adc xfr8
		;adc #$00
		tax
		bcc +
		;XXX TODO update of xpospre could be needed here
		inc xt
		clc
+
xshift_temp_end
xshift_temp_size = xshift_temp_end - xshift_temp
xshift_temp_size2 = xshift_temp_end2 - xshift_temp
		;XXX TODO make this more accurate: 16 bit part: first 3 bits = shift + shift down by 3 for block

gen_ystretch
		lda #<start_fpp
		sta src
		lda #>start_fpp
		sta src + 1
		lda dst
		sta ystretch_jmp + 1
		lda dst + 1
		sta ystretch_jmp + 2

		ldx #$00
ys_loop
		ldy #$00
-
		lda (src),y
		iny
		cmp #$8c
		bne -
		tya
		sbc #$03
		adc src
		sta ys_d018 + 1
		lda src + 1
		adc #$00
		sta ys_d018 + 2

		tya
		clc
		adc src
		sta src
		bcc +
		inc src + 1
+

		ldy #ystretch_temp_size2 - 1
		cpx #$12
		bcs +
		ldy #ystretch_temp_size1 - 1
+
-
		lda ystretch_temp,y
		sta (dst),y
		dey
		bpl -

		lda #ystretch_temp_size2
		cpx #$12
		bcs +
		lda #ystretch_temp_size1
+
		clc
		adc dst
		sta dst
		bcc +
		inc dst + 1
+

		ldy #$01
-
		lda ystretch_finish,y
		sta (dst),y
		dey
		bpl -

		lda #$02
		clc
		adc dst
		sta dst
		bcc +
		inc dst + 1
+
		inx
		cpx #$44
		bne ys_loop
		rts



ystretch_temp
		;XXX TODO work on A and X for 16 bit addition? but use nop. nop, inx, nop, inx, inx as for adc fr16? then we can do load on y? but carry?
		tya
		adc fr8
		tay
		txa
		adc fr16
		tax
		lda ysource,x
ys_d018		sta start_fpp + 1
		;XXX TODO set yline to $60 and branch to this byte, saves rts
ystretch_temp_end1
		bpl *+5
		jsr exit
ystretch_temp_end2
		;jsr exit and fetch PC-1 from stack to get .d018+1 value, then subtract, or return .num in y? -> lookup per table
ystretch_finish
		sta yline,x
ystretch_temp_size1 = ystretch_temp_end1 - ystretch_temp
ystretch_temp_size2 = ystretch_temp_end2 - ystretch_temp

gen_screens
		lda #$00
		ldy #$05
--
		ldx #$00
-
.inc		sta screen0,x
		clc
		adc #$01
		cmp #$50
		bne +
		lda #$55
+
		cmp #$d0
		bne +
		lda #$d5
+
		inx
		cpx #$28
		bne -
		tax
		lda .inc + 2
		adc #3
		sta .inc + 2
		txa
		dey
		bpl --
		rts
fadein
		ldx #$00
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
		cpx #$10 * csize
		bne -

		lda #$3b
		sta .start_gfx + 1
		ldx #$0a
--
		jsr wait
		jsr wait
		jsr wait
		lda coltab_lo_0,x
		sta $d020
		dex
		bpl --

		ldx #$0a - 4
--
		jsr wait
		jsr wait
		jsr wait

;		ldy #$27
;		lda coltab_lo_0 + COL_SHADOW * csize + 4,x
;-
;		sta $d800 + 16 * 40,y
		dey
		bpl -
		dex
		bne --

--
		jsr wait
		jsr wait
		jsr wait

.start		ldx #$00
		inc .start+1
		ldy curve,x
		lda coltab_lo_1,y
		sta $d029
		sta $d02a
		sta $d02b
		sta $d02c
		sta $d02d
		sta $d02e
                lda coltab_lo_3,y
		sta .d021_3 + 1
                lda coltab_lo_5,y
		sta .d021_1 + 1
                lda coltab_lo_0 + COL_FLOOR * csize,y
		sta .d021_4 + 1
		lda #$ff
		tax
		jsr fadercode

		lda .start+1
		cmp #$0a
		bne --
--
		jsr wait
		jsr wait
		jsr wait

.start2		ldx #$00
		inc .start2+1
		ldy curve,x
                lda coltab_lo_0 + COL_FLOOR * csize - 1,y
		sta .d021_2 + 1

		lda .start2+1
		cmp #$09
		bne --
		lda #$2c
		sta .en_upd
		rts

curve
		!byte $0a,$0a,$0a,$0a,$0a,$09,$08,$07,$06,$05,$05


coltab
         !byte $00,$00,$00,$00,$00,$00,$0b,$0c,$0f,$01,$01
         !byte $00,$00,$0b,$0c,$0f,$01,$01,$01,$01,$01,$01
         !byte $00,$00,$00,$00,$00,$02,$08,$0a,$0f,$07,$01
         !byte $00,$00,$06,$04,$0e,$03,$01,$01,$01,$01,$01
         !byte $00,$00,$00,$00,$06,$04,$0e,$03,$01,$01,$01
         !byte $00,$00,$00,$09,$0c,$05,$0f,$0d,$01,$01,$01
         !byte $00,$00,$00,$00,$00,$06,$04,$0e,$03,$01,$01
         !byte $00,$09,$08,$0a,$0f,$07,$01,$01,$01,$01,$01
         !byte $00,$00,$00,$00,$09,$08,$0a,$0f,$07,$01,$01
         !byte $00,$00,$00,$00,$00,$09,$08,$0a,$0f,$07,$01
         !byte $00,$00,$00,$09,$08,$0a,$0f,$07,$01,$01,$01
         !byte $00,$00,$00,$00,$00,$0b,$0c,$0f,$01,$01,$01
         !byte $00,$00,$00,$00,$0b,$0c,$0f,$01,$01,$01,$01
         !byte $00,$0b,$0c,$05,$03,$0d,$01,$01,$01,$01,$01
         !byte $00,$00,$00,$06,$04,$0e,$03,$0d,$01,$01,$01
         !byte $00,$00,$00,$0b,$0c,$0f,$07,$01,$01,$01,$01

!warn "end of init code ",*

		* = multimap
!bin "font.scr",,236*6

		* = main2
start
		;jsr update
                cli
		jsr fadein
		jsr precalc
		;jmp *
		jsr clearlines

loop
		jsr fstuff

trig = * + 1
		lda #$01
		beq loop
		lda #$00
		sta trig
		jsr precalc
		jmp loop
irq1
		pha
		txa
		pha
                dec $d019
                lda #<irq2
                sta $fffe
                inc $d012
                tsx
                cli

                !byte $ea,$ea,$ea,$ea,$ea,$ea,$ea,$ea
                !byte $ea,$ea,$ea,$ea,$ea,$ea,$ea,$ea
                ;!byte $ea,$ea,$ea,$ea,$ea,$ea,$ea,$ea
                ;!byte $ea,$ea,$ea,$ea,$ea,$ea,$ea,$ea

irq2
!if (irq1 & $ff00) != (irq2 & $ff00) {
                !error "irq handler not in same page"
}
                txs

		lda #<irq3
		sta $fffe
		lda #>irq3
		sta $ffff
		lda #$f9
		sta $d012
		tya
		pha
		ldx #$07
.en_fpp		jsr fpp
                dec $d019
		lda #$04
		sta $d023

		;sty $d021
		;lda #$80
		;sta $d018

		cli
.en_upd		jmp ++

		ldx frame
		lda yfrac8,x
		sta fr8
		lda yfrac16,x
		sta fr16
		ldy wave_y_s,x
		sty $d001
		sty $d003
		lda #0
		cpy #$30
		adc #0
		cpy #$38
		adc #0
		cpy #$40
		adc #0
		cpy #$48
		adc #0
		;cpy #$58
		;adc #0
		asl
		asl
		asl
		ldy #$08
		cmp #$20
		bcc +
		ldy #$04
+
		clc
		adc #<spr_num
		sta .spr_zoom + 1
		sty .spr_white + 1
		lda wave_x_lo_s,x
		sta $d000
		sta $d002
		ldy #$80
		cpx #$1b
		bcc +
		cpx #$66
		bcs +
		ldy #$83
+
		sty $d010
		inc frame
		dec .d016 + 1
		bpl +
		inc trig
		lda #$07
		sta .d016 + 1
		jsr copyscroll
+
		jsr update
++
		lda $d012
		cmp #$b1
		bcs +
		cmp max_d012
		bcc +
		sta max_d012
+
		pla
		tay
		pla
		tax
		pla
		rti
fpp
		nop
		nop
		nop
start_fpp
		ldy #$00
		sty $d018
.d021_2		lda #.INIT_COL
		lda $d021
		lda #$02
		sta $dd00
		lda shifttab,y
		sax $d016

!macro line .d011, .d018, .c, ~.cset {
!if (.c = 0) {
			;lda #.d011
			;sta $d011
} else {
	!if (.d011 = $18) {
			lda #.d011
			sta $d011
	} else {
			inc $d011
	}
}
		;XXX TODO need a nice trick here to directly load from precalc buffer
.cset		ldy #$80
		sty $d018
		lda shifttab,y
		sax $d016
}

		+line $1b, $00, 0,	~d018_00
		+line $1c, $10, 1,	~d018_01
		+line $1d, $20, 2,	~d018_02
		+line $1e, $30, 3,	~d018_03
		+line $1f, $40, 4,	~d018_04
		+line $18, $50, 5,	~d018_05
		+line $19, $02, 6,	~d018_06
		+line $1a, $12, 7,	~d018_07

		+line $1b, $22, 8,	~d018_08
		+line $1c, $32, 9,	~d018_09
		+line $1d, $42, 10,	~d018_0a
		+line $1e, $52, 11,	~d018_0b
		+line $1f, $04, 12,	~d018_0c
		+line $18, $14, 13,	~d018_0d
		+line $19, $24, 14,	~d018_0e
		+line $1a, $34, 15,	~d018_0f

		+line $1b, $44, 16,	~d018_10
		+line $1c, $54, 17,	~d018_11
		+line $1d, $06, 18,	~d018_12
		+line $1e, $16, 19,	~d018_13
		+line $1f, $26, 20,	~d018_14
		+line $18, $36, 21,	~d018_15
		+line $19, $46, 22,	~d018_16
		+line $1a, $56, 23,	~d018_17

		+line $1b, $08, 24,	~d018_18
		+line $1c, $18, 25,	~d018_19
		+line $1d, $28, 26,	~d018_1a
		+line $1e, $38, 27,	~d018_1b
		+line $1f, $48, 28,	~d018_1c
		+line $18, $58, 29,	~d018_1d
		+line $19, $0a, 30,	~d018_1e
		+line $1a, $1a, 31,	~d018_1f

		+line $1b, $2a, 32,	~d018_20
		+line $1c, $3a, 33,	~d018_21
		+line $1d, $4a, 34,	~d018_22
		+line $1e, $5a, 35,	~d018_23
		+line $1f, $0c, 36,	~d018_24
		+line $18, $1c, 37,	~d018_25
		+line $19, $2c, 38,	~d018_26
		+line $1a, $3c, 39,	~d018_27

		+line $1b, $4c, 40,	~d018_28
		+line $1c, $5c, 41,	~d018_29
		+line $1d, $0e, 42,	~d018_2a
		+line $1e, $1e, 43,	~d018_2b
		+line $1f, $2e, 44,	~d018_2c
		+line $18, $3e, 45,	~d018_2d
		+line $19, $4e, 46,	~d018_2e
		+line $1a, $5e, 47,	~d018_2f

		+line $1b, $80, 47,	~d018_30
		+line $1c, $80, 47,	~d018_31
		+line $1d, $80, 47,	~d018_32
		+line $1e, $80, 47,	~d018_33
		+line $1f, $80, 47,	~d018_34
		+line $18, $80, 47,	~d018_35
		+line $19, $80, 47,	~d018_36
		+line $1a, $80, 47,	~d018_37

		+line $1b, $80, 47,	~d018_38
		+line $1c, $80, 47,	~d018_39
		+line $1d, $80, 47,	~d018_3a
		+line $1e, $80, 47,	~d018_3b
		+line $1f, $80, 47,	~d018_3c
		+line $18, $80, 47,	~d018_3d
		+line $19, $80, 47,	~d018_3e
		+line $1a, $80, 47,	~d018_3f

		+line $1b, $80, 47,	~d018_40
		+line $1c, $80, 47,	~d018_41
		+line $1d, $80, 47,	~d018_42
		+line $1e, $80, 47,	~d018_43
		;+line $1e, $60, 47,	~d018_44
		;+line $1f, $60, 47,	~d018_45
		;+line $18, $60, 47,	~d018_46
		;+line $19, $60, 47,	~d018_47
		rts


;use 8 bit only but on each overflow: add one extra -> add 1 or two -> all possible from 48 to 96 lines? maybe better from 1.5 to 0.5? 256 bytes
;$0080 ... $0400
;-> $0000 -> $0380



;xfrac16
;!for .x,0,255 {
;		!byte <(.x * 6 / 2048)
;}



gencode_tgt
!warn "main2 end ", *

;		* = wave_y
;!bin "sinus.bin",$100,$000

		* = multi_font
!bin "font.chr",148 * 8
!bin "font_hires.chr",86 * 8,148 * 8
;XXX TODO disable update of lines that are not visible due to y stretch (set bits?)

		* = hiresmap
!bin "font_hires.scr",,236*6


;XXX TODO BUG on frameskip rts value of fpp_start is trashed/missed

;XXX TODO try to directly render now, do the prestuff bevor teh other stuff, others can be combined, single addition used again, no peaks anymore?

;XXX TODO use remaining rastertime to prerender already lines that are unused now, but used on next frame?


		* = logo_bitmap
!bin "hill.prg",$140*10,2

		* = main3
precalc
		jsr gen
		lda frame
		and #$f8		;could possibly be omitted
		sta .nfr + 1
		sec
		adc #$08
		sta .nfr2 + 1
-
.nfr		ldx #$00
		lda xfrac8,x
		sta xfr8
		lda yfrac8,x
		sta fr8
		lda yfrac16,x
		sta fr16
prepixel
.xp		ldx #$00
		ldy cnttab,x
		inx
		lda #$0f
		sax .xp + 1

		ldx #$00
		stx xt
		clc

		jsr prepix

		;clc
.nfr2		lda #$09
		isc .nfr + 1
		bne .nfr
		rts

		;XXX TODO combine two updates, by determining linenum speedcode from x? saves check on each line?
update

		lxa #0
		tay
		clc

pcode = * + 1
		lda #$a9
		sta (pend),y
ystretch_jmp	jmp $1000

copyscroll
		ldx #$00
-
;!for .x,0,38 {
		lda scroll_screen + 10 * 40 + 1,x
		sta scroll_screen + 10 * 40,x
		lda scroll_screen + 11 * 40 + 1,x
		sta scroll_screen + 11 * 40,x
		lda scroll_screen + 12 * 40 + 1,x
		sta scroll_screen + 12 * 40,x
		lda scroll_screen + 13 * 40 + 1,x
		sta scroll_screen + 13 * 40,x
		lda scroll_screen + 14 * 40 + 1,x
		sta scroll_screen + 14 * 40,x
		lda scroll_screen + 15 * 40 + 1,x
		sta scroll_screen + 15 * 40,x
;}
		inx
		cpx #39
		bne -
		rts
;!align 255,0
wave_x_lo_s
!bin "sinus.bin",$100,$300
wave_y_s
!bin "sinus.bin",$100,$200
xfrac8
!bin "sinus.bin",$100,$500
yfrac8
!bin "sinus.bin",$100,$600
;	!for .y,0,255 {
;		!byte <($200 * .y / 256.0 + $b8)
;	}
yfrac16
!bin "sinus.bin",$100,$700
;	!for .y,0,255 {
;		!byte >($200 * .y / 256.0 + $b8)
;	}
;!for .x,0,255 {
;		!byte <(.x * 40 / 64) + 18
;}

gen
setup_gen_line
		lda cwidth
		sec
		isc clm
		bcs next_clm
next_char
		inc txtpos + 1
		bne +
		inc txtpos + 2
+
txtpos		ldx scrolltext - 1
		bpl noescape
		cpx #$ff
		beq wrapsc
		lda #$01
		sta ctrig + 1
		sax pattern + 1
		lda ysource
		bpl ++
		lxa #$00
		;clc
-
		sta ysource,x			;populate ysource tab to enable shadow
		adc #$10
		cmp #$60
		bcc +
		;and #$0f
		;adc #1
		adc #$a1
+
		inx
		cpx #$30
		bne -
++
		lda #$ff
		sta en_sun + 1
		;jsr set_col_2
		jmp next_char
wrapsc
!ifdef release {
		lda #$4c
		sta .en_upd
		jmp fadeout
} else {
		lda #<scrolltext
		sta txtpos + 1
		lda #>scrolltext
		sta txtpos + 2
		jmp txtpos
}
noescape
		lda font_lo,x
		sta map
		clc
		adc #<(hiresmap - multimap)
		sta hmap
		lda font_hi,x
		sta map + 1
		adc #>(hiresmap - multimap)
		sta hmap + 1
		lda font_widths,x
		sta cwidth

		lda #$01
		sta clm
next_clm
		ldy #$00
.nextchr
!macro setup_cb_copy .x, .tgt {
		lda (map),y
		sta scroll_screen + (10 + .x) * 40 + 39
		lax (hmap),y
		asl
		asl
		asl
		sta .tgt + 1
		lda shift5r,x
		ora #>multi_font
		sta .tgt + 2
}
		+setup_cb_copy 0, .gl1
		iny
		+setup_cb_copy 1, .gl2
		iny
		+setup_cb_copy 2, .gl3
		iny
		+setup_cb_copy 3, .gl4
		iny
		+setup_cb_copy 4, .gl5
		iny
		+setup_cb_copy 5, .gl6

		ldx #$07
-
.gl1		lda $1000,x
		sta charbyte,x
.gl2		lda $1000,x
		sta charbyte + 8,x
.gl3		lda $1000,x
		sta charbyte + 16,x
.gl4		lda $1000,x
		sta charbyte + 24,x
.gl5		lda $1000,x
		sta charbyte + 32,x
.gl6		lda $1000,x
		sta charbyte + 40,x
		dex
		bpl -

		lax map
		sbx #$f8
		stx map
		stx hmap
		bcc +
		inc map + 1
		inc hmap + 1
+
		sec
pattern		ldx #$01
gen_jmp		jmp $1000

exit
		pla
		sbc #$05
		sta fr8
		pla
		sbc #$00
		sta fr8+1

		ldy #$00
		lax (fr8),y
		sbx #-$a
		iny
		lda (fr8),y
		adc #$00

		stx pend
		sta pend + 1

		dey
		lda (pend),y
		sta pcode
		lda #$60
		sta (pend),y

.xp2		ldx #$00
		ldy cnttab,x
		inx
		lda #$0f
		sax .xp2 + 1

xupdate_jmp	jsr $1000

		lda #$80
!for .x,0,47 {
		sta yline + .x
}
		rts

spr_num
		!byte (((sun_sprites) & $3fff) / $40) + 0
		!byte (((sun_sprites) & $3fff) / $40) + 1
		!byte (((sun_sprites) & $3fff) / $40) + 2
		!byte (((sun_sprites) & $3fff) / $40) + 3
		!byte (((sun_sprites) & $3fff) / $40) + 4
		!byte (((sun_sprites) & $3fff) / $40) + 5
		!byte (((sun_sprites) & $3fff) / $40) + 6
		!byte (((sun_sprites) & $3fff) / $40) + 7
		!byte (((sun_sprites) & $3fff) / $40) + 0 + 16
		!byte (((sun_sprites) & $3fff) / $40) + 1 + 16
		!byte (((sun_sprites) & $3fff) / $40) + 2 + 16
		!byte (((sun_sprites) & $3fff) / $40) + 3 + 16
		!byte (((sun_sprites) & $3fff) / $40) + 4 + 16
		!byte (((sun_sprites) & $3fff) / $40) + 5 + 16
		!byte (((sun_sprites) & $3fff) / $40) + 6 + 16
		!byte (((sun_sprites) & $3fff) / $40) + 7 + 16
		!byte (((sun_sprites) & $3fff) / $40) + 0 + 32
		!byte (((sun_sprites) & $3fff) / $40) + 1 + 32
		!byte (((sun_sprites) & $3fff) / $40) + 2 + 32
		!byte (((sun_sprites) & $3fff) / $40) + 3 + 32
		!byte (((sun_sprites) & $3fff) / $40) + 0 + 32
		!byte (((sun_sprites) & $3fff) / $40) + 1 + 32
		!byte (((sun_sprites) & $3fff) / $40) + 2 + 32
		!byte (((sun_sprites) & $3fff) / $40) + 3 + 32
		!byte (((sun_sprites) & $3fff) / $40) + 0 + 40
		!byte (((sun_sprites) & $3fff) / $40) + 1 + 40
		!byte (((sun_sprites) & $3fff) / $40) + 2 + 40
		!byte (((sun_sprites) & $3fff) / $40) + 3 + 40
		!byte (((sun_sprites) & $3fff) / $40) + 0 + 40
		!byte (((sun_sprites) & $3fff) / $40) + 1 + 40
		!byte (((sun_sprites) & $3fff) / $40) + 2 + 40
		!byte (((sun_sprites) & $3fff) / $40) + 3 + 40
		!byte (((sun_sprites) & $3fff) / $40) + 0 + 48
		!byte (((sun_sprites) & $3fff) / $40) + 1 + 48
		!byte (((sun_sprites) & $3fff) / $40) + 2 + 48
		!byte (((sun_sprites) & $3fff) / $40) + 3 + 48
		!byte (((sun_sprites) & $3fff) / $40) + 0 + 48
		!byte (((sun_sprites) & $3fff) / $40) + 1 + 48
		!byte (((sun_sprites) & $3fff) / $40) + 2 + 48
		!byte (((sun_sprites) & $3fff) / $40) + 3 + 48

!warn "main3 end ",*

		* = main4
irq3
		pha
		tya
		pha
		txa
		pha
		dec $d019
		lda #$fe
		sta $d012
                lda #<irq31
                sta $fffe
                lda #>irq31
                sta $ffff

		lda #$13
		sta $d011
		lda #$de
		sta $d018

		lda #$00
		sta $d015
		sta $d01b
		sta $d017
		sta $d01d
set_colors
.sprnum		lda #$00
		tax
		lsr
		asr #$fe
		tay
.spr_zoom	lda spr_num,y
		sta scroll_screen + $03f8
.spr_white	adc #$08
		sta scroll_screen + $03f9
		inx
		lda #$1f
		sax .sprnum + 1

ctrig		lda #$00
		beq .sc_end
.cy		ldy #$00
		cpy #$08
		beq .sc_end
		lda cols_sun,y
		sta $d027
		lda cols_sun2,y
		sta $d028
		lda cols_shad,y
		ldx #$27
-
		sta $d800 + 16 * 40,x
		dex
		bpl -
		inc .cy + 1
.sc_end
		cli
!ifndef release {
		jsr music + 3
}

		pla
		tax
		pla
		tay
		pla
		rti

irq31
		pha
		dec $d019
		lda #<irq4_
		sta $fffe
		lda #$00
		sta $ffff
		sta $d012
		sta $dd00
		pla
		rti

irq4
		pha
		dec $d019
		lda #$32
		sta $d012
.d021_3		lda #.INIT_COL
		sta $d021
                lda #<irq5_
                sta $fffe
		lda #$07
		sta $d016
                ;lda #>irq5_
                ;sta $ffff
en_sun		lda #$fc
		sta $d015
en_fadeout	top fadeout_irq
		pla
		rti
irq5
		pha
		txa
		pha
		tya
		pha
		dec $d019
		lda #$82
		sta $d012
                lda #<irq6_
                sta $fffe
.start_gfx	lda #$0b
		sta $d011
.d021_1		lda #.INIT_COL
		sta $d021
		cli
		pla
		tay
		pla
		tax
		pla
		rti
irq6
		pha
		txa
		pha

		dec $d019
		lda #$93
		sta $d012
                lda #>irq7
                sta $ffff
                lda #<irq7
                sta $fffe
		nop
		nop
		ldx #$1b
.d016		lda #$07
		ora #$10
		stx $d011
		sta $d016

		pla
		tax
		pla
		rti
irq7
		pha
.d021_4		lda #.INIT_COL
		sta $d021
		dec $d019
		lda #$97
		sta $d012
                lda #>irq8
                sta $ffff
                lda #<irq8
                sta $fffe
		lda #$00
		sta $d015
		nop
		nop
		nop
		nop
		pha
		pla
		pha
		pla
		lda .d021_1 + 1
		sta $d021
		pla
		rti
scrolltext
		;a slow scroller...                       but don't be faster than your shadow 8====>"
		;!text " lame?          "
 		;!byte $80
		!text " "
		;!byte $81
		!text "lame? "
		!byte $80
		!text "do you want to live in the "
		!byte $81
		!text "shadows"
		!byte $80
		!text "?          "
;		!text "do you want to live in the shadows?"
;		!text "but don't be faster than your shadow!"

;		!text "but "
;		!text "don't "
;		!text "be "
;		!byte $81
;		!text "faster "
;		!byte $80
;		!text "than "
;		!text "your "
;		!text "shadow!          "
		!byte $ff

!warn "main4 end ",*
		* = main5
irq8
		pha
		dec $d019
		lda #$99
		sta $d012
                lda #>irq9
                sta $ffff
                lda #<irq9
                sta $fffe
		lda .d021_4 + 1
.irq_
		nop
		pha
		pla
		pha
		pla
		pha
		pla
		pha
		pla
		sta $d021
		pla
		rti
irq9
		pha
		dec $d019
		lda #$9b
		sta $d012
                lda #>irqa
                sta $ffff
                lda #<irqa
                sta $fffe
		lda .d021_1 + 1
		jmp .irq_ + 1
irqa
		pha
		dec $d019
		lda #$9f
		sta $d012
                lda #>irqb
                sta $ffff
                lda #<irqb
                sta $fffe
		lda .d021_4 + 1
		jmp .irq_
irqb
		pha
		dec $d019
		lda #$b1
		sta $d012
                lda #>irq1
                sta $ffff
                lda #<irq1
                sta $fffe
		pha
		pla
		pha
		pla
		pha
		pla
		pha
		pla
		lda .d021_1 + 1
		sta $d021
		lda .d021_4 + 1
		pha
		pla
		pha
		pla
		jmp .irq_

clearlines
		lxa #$00
-
		sta lines + $000,x
		sta lines + $100,x
		sta lines + $200,x
		sta lines + $300,x
		sta lines + $400,x
		sta lines + $500,x
		sta lines + $600,x
		sta lines + $700,x
		sta lines + $800,x
		sta lines + $900,x
		sta lines + $a00,x
		sta lines + $b00,x
		sta lines + $c00,x
		sta lines + $d00,x
		sta lines + $e00,x
		sta lines + $f00,x
		sta lines + $1000,x
		sta lines + $1100,x
		sta lines + $1200,x
		sta lines + $1300,x
		sta lines + $1400,x
		sta lines + $1500,x
		dex
		bne -
		rts

fadeout
                ldx #$00
		jsr wait
		lda #$20
		sta en_fadeout

!ifdef release {
		jsr link_load_next_comp
		jsr link_load_next_comp
}

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
fadeout_irq
		txa
		pha
		tya
		pha
		lda #$07
		sta .d016 + 1
		sta $d016
		jsr effect
		pla
		tay
		pla
		tax
		rts

effect

.cnt		lda #$03
		dec .cnt + 1
		beq +
		rts
+
		lda #$03
		sta .cnt + 1
.start1         ldx #$05
		cpx #$0a
		beq .off
		bcs .down

		ldy fcurve,x
		lda coltab_lo_7,y
		sta $d028
		lda coltab_lo_1,y
		sta $d027
		sta $d029
		sta $d02a
		sta $d02b
		sta $d02c
		sta $d02d
		sta $d02e
                lda coltab_lo_3,y
		sta .d021_3 + 1
		sta $d021
		lda #$ff
		tax
		cli
                jsr fadercode
                lda coltab_lo_5,y
		sta .d021_1 + 1
                lda coltab_lo_0 + COL_FLOOR * csize,y
		sta .d021_4 + 1
                lda coltab_lo_0 + COL_FLOOR * csize - 1,y
		sta .d021_2 + 1

		ldx .start1 + 1
		jmp .lower
.off
		lda #$00
		sta $d015
		sta en_sun + 1
		lda #$fa
		sta $d012
		lda #<firq4
		sta $fffe
		lda #$1b
		sta $d011
		lda #$f2
                sta coltab_lo_7 + 0
                sta coltab_lo_0 + COL_FLOOR * csize + 0
                sta coltab_lo_0 + COL_FLOOR * csize + 1
                sta coltab_lo_0 + COL_FLOOR * csize + 2
		lda #$2f
                sta coltab_hi_0 + COL_FLOOR * csize + 0
                sta coltab_hi_0 + COL_FLOOR * csize + 1
                sta coltab_hi_0 + COL_FLOOR * csize + 2
.down
		cpx #$14
		beq .start4
                ldy fcurve,x
		lda coltab_lo_0 + COL_FLOOR * csize,y
		and coltab_hi_0 + COL_FLOOR * csize,y
                sta .col07 + 1
		ldy #$00
-
		sta $d800,y
		sta $d900,y
		dey
		bne -
.lower
                ldy fcurve,x
                lda coltab_lo_0 + COL_FLOOR * csize,y
                inc .start1 + 1
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
                ldy fcurve,x
                lda coltab_lo_7,y
                sta .colframe + 1
		rts
+
		inc .trig + 1
		rts

fcurve
		!byte $01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00,$00,$00,$00

wait
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
.rts
		rts


firq0_
		pha
		lda #$fa
		sta $d012
		lda #<firq4
		sta $fffe
.colframe	lda #$00
		sta $d020
.col07		lda #$01
		sta $d021
		lda #$1b
		sta $d011
		dec $d019
		pla
		rti
firq4_
		pha
		lda #$13
		sta $d011
		lda #$00
		sta $d012
		lda #<firq0
		sta $fffe
		dec $d019
		txa
		pha
		tya
		pha
		cli
		jsr effect
		pla
		tay
		pla
		tax
		pla
		rti

fstuff
		ldy $d001
		lda $d015
		and #$01
		beq +
		lda #$00
		clc
		cpy #$40
		adc #0
		cpy #$48
		adc #0
		tax
		lda colshine,x
		ldx #$27
-
		sta $d800 + 10 * 40,x
		dex
		bpl -
+
		rts
cols_shad
		!byte $0c,$0c,$0c,$0c,$0c,$0c,$0b,$0b
colshine
		!byte $09,$0f,$0b

!warn "main5 end ",*

		* = sun_sprites
!bin "spr1.spr",$200,$200
!bin "spr1.spr",$200,$000
!bin "spr1.spr",$200,$600
!bin "spr1.spr",$200,$400

!bin "spr1.spr",$100,$a00
!bin "spr1.spr",$100,$800
!bin "spr1.spr",$100,$e00
!bin "spr1.spr",$100,$c00
!bin "spr1.spr",$100,$1200
!bin "spr1.spr",$100,$1000
		* = cloud_sprites
!bin "sky.spr",$200,$000

		* = screen
!fill $190, .INIT_COL | (.INIT_COL << 4)
!fill 40*6,$6
