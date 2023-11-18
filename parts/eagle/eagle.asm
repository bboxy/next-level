!cpu 6510
bitmap			= $6000
bitmap_d		= $2000
screen 			= $0400
main			= $3f40


mask			= $10
src			= $12
dst			= $14
addr			= $16
y			= $18
xl			= $19
xh			= $1a
mask_			= $1c
src_			= $1e
y_			= $20
height			= $21
width			= $22
stream1			= $23
stream2			= $25
y1			= $27
xl1			= $28
xh1			= $29
y2			= $2a
xl2			= $2b
xh2			= $2c

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}
			* = bitmap_d
			!fill $1f40,0

			* = main
			sei
			jsr vsync
			lda #$00
			sta $d011
			lda #$03
			sta $dd00
			lda #$00
			sta $d021
			lda #$00
			sta $d020
			lda #$18
			sta $d018
			sta $d016
start
			ldx #$00
-
			lda screen_ + $000,x
			sta screen  + $000,x
			lda screen_ + $100,x
			sta screen  + $100,x
			lda screen_ + $200,x
			sta screen  + $200,x
			lda screen_ + $300,x
			sta screen  + $300,x
			lda colram_ + $000,x
			sta $d800   + $000,x
			lda colram_ + $100,x
			sta $d800   + $100,x
			lda colram_ + $200,x
			sta $d800   + $200,x
			lda colram_ + $300,x
			sta $d800   + $300,x
			dex
			bne -

			lda #00
			sta y1
			lda #00
			sta xl1
			lda #$00
			sta xh1

			lda #$d1
			sta y2
			lda #$55
			sta xl2
			lda #$01
			sta xh2

			lda #<stream_data
			sta stream1
			lda #>stream_data
			sta stream1 + 1
			lda #<stream_data2
			sta stream2
			lda #>stream_data2
			sta stream2 + 1

			jsr vsync
			lda #$3b
			sta $d011
			lda #$fb
			sta $d012
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
			cli
!ifdef release {
			jsr link_load_next_raw
			dec $01
			jsr link_decomp
			inc $01
			lda #$0c
-
			cmp effects + 3
			bne -
			jsr link_load_next_comp
trig			lda #$00
			beq trig
			jsr vsync
			lda #$00
			sta $d011
			sei
			jsr link_exit
} else {
			jmp *
}


irq
			pha
			txa
			pha
			tya
			pha
			lda $01
			pha
			lda #$35
			sta $01
			dec $d019
effects
			jmp colin
			jmp fadein
			jmp wait
			jmp fadeout
			jmp colout
irq_end
			pla
			sta $01
			pla
			tay
			pla
			tax
			pla
			rti
fadein
			jsr do_paint1
			cmp stream1
			lda stream2 + 1
			sbc stream1 + 1
			bcc +
			jmp irq_end
+
			ldx #$00
			lda #$49
			jsr setup
			inx
			lda #$ff
			jsr setup
			inx
			lda #$31
			jsr setup

			lda #$d1
			sta y1
			lda #00
			sta xl1
			lda #$00
			sta xh1

			lda #$00
			sta y2
			lda #$55
			sta xl2
			lda #$01
			sta xh2

			lda #<stream_data
			sta stream1
			lda #>stream_data
			sta stream1 + 1
			lda #<stream_data2
			sta stream2
			lda #>stream_data2
			sta stream2 + 1
			lda #$0c
			sta effects + 3
			jmp irq_end
fadeout
			lda #$20
			;enable music fadeout
			sta $018f
			jsr do_paint2
			cmp stream1
			lda stream2 + 1
			sbc stream1 + 1
			bcc +
			jmp irq_end
+
			lda #$0c
			sta effects + 9
			jmp irq_end
wait
			ldy #$00
			dey
			sty wait + 1
			bne +
			lda #$0c
			sta effects + 6
+
			jmp irq_end

colin
			ldx #$00
			lda colors,x
			sta $d021
			inc colin + 1
			lda colin + 1
			cmp #$20
			bne +
			lda #$0c
			sta effects + 0
+
			jmp irq_end
colout
			ldx colin + 1
			lda colors,x
			sta $d021
			;txa
			;lsr
			;ora #$30
			;sta $d418
			dec colin + 1
			bpl +
			lda #$0c
			sta effects + 12
!ifdef release {
			inc trig + 1
}
+
			jmp irq_end
colors
			!byte $00,$00,$00,$00
			!byte $00,$00,$09,$09
			!byte $09,$09,$09,$09
			!byte $08,$08,$08,$08
			!byte $08,$08,$0a,$0a
			!byte $0a,$0a,$0a,$0a
			!byte $0f,$0f,$0f,$0f
			!byte $0f,$0f,$0f,$0f
			!byte $0f


setup
			sta .eor0,x
			sta .eor1,x
			sta .eor2,x
			sta .eor3,x
			sta .eor4,x
			sta .eor5,x
			sta .eor6,x
			sta .eor7,x
			rts

do_paint1
			lda y1
			ldx xl1
			ldy xh1
			jsr draw_bob
			lda y2
			ldx xl2
			ldy xh2
			jsr draw_bob

			ldy #$00

			lax (stream1),y
			clc
			bmi x_neg11
			adc xl1
			bcc +
			inc xh1
			jmp +
x_neg11
			adc xl1
			bcs +
			dec xh1
+
			sta xl1
			iny
			lda (stream1),y
			clc
			adc y1
			sta y1
			lda stream1
			clc
			adc #2
			sta stream1
			bcc +
			inc stream1 + 1
+

			ldy #$00

			lax (stream2),y
			eor #$ff
			sec
			bmi x_neg21
			adc xl2
			bcc +
			inc xh2
			jmp +
x_neg21
			adc xl2
			bcs +
			dec xh2
+
			sta xl2
			iny
			lda (stream2),y
			eor #$ff
			sec
			adc y2
			sta y2
			lda stream2
			sec
			sbc #2
			sta stream2
			bcs +
			dec stream2 + 1
+
			rts

do_paint2
			lda y1
			ldx xl1
			ldy xh1
			jsr draw_bob
			lda y2
			ldx xl2
			ldy xh2
			jsr draw_bob

			ldy #$00

			lax (stream1),y
			clc
			bmi x_neg12
			adc xl1
			bcc +
			inc xh1
			jmp +
x_neg12
			adc xl1
			bcs +
			dec xh1
+
			sta xl1
			iny
			lda (stream1),y
			eor #$ff
			sec
			adc y1
			sta y1
			lda stream1
			clc
			adc #2
			sta stream1
			bcc +
			inc stream1 + 1
+

			ldy #$00

			lax (stream2),y
			eor #$ff
			sec
			bmi x_neg22
			adc xl2
			bcc +
			inc xh2
			jmp +
x_neg22
			adc xl2
			bcs +
			dec xh2
+
			sta xl2
			iny
			lda (stream2),y
			clc
			adc y2
			sta y2
			lda stream2
			sec
			sbc #2
			sta stream2
			bcs +
			dec stream2 + 1
+
			rts
vsync
			bit $d011
			bpl *-3
			bit $d011
			bmi *-3
			rts

draw_bob
			sta y
			stx xl
			sty xh
			lda xh
			beq .x_okay
			cmp #$01
			beq +
			rts
+
			lda xl
			cmp #$68
			bcc .x_okay
			rts
.x_okay
			lda y
			cmp #$e8
			bcc .y_okay
			rts
.y_okay
			lda xl
			and #$07
			tay
			lda mask_tab_l,y
			sta mask_
			lda mask_tab_h,y
			sta mask_ + 1

			lda y
			lsr
			lsr
			lsr
			tay

			lda xh
			lsr
			lda xl
			ror
			lsr
			asr #$fe
			tax

			lda tab_width,x
			sta width
			lda tab_height,y
			sta height

			lda tabx_l,x
			adc tab_l,y
			sta src_
			lda tabx_h,x
			adc tab_h,y
			sta src_ + 1

			lda y
			and #$07
			sta y_
			eor #$ff
			sec
			adc mask_
			bcs +
			dec mask_ + 1
+
			cpy #$04
			bcs ++
			adc mask_clip_y,y
			bcc +
			inc mask_ + 1
+
			ldy #$00
			sty y_
++
			cpx #$05
			bcs +
			adc mask_clip_x,x
			bcc +
			inc mask_ + 1
+
			sta mask_
			jmp .draw_clm

jump_back
			dec width
			bpl +
			rts
+
			lda mask_
			adc #$28
			sta mask_
			bcc +
			inc mask_ + 1
			clc
+
			lda src_
			adc #8
			sta src_
			bcc +
			inc src_ + 1
			clc
+
.draw_clm
			lda mask_
			sta mask
			lda mask_ + 1
			sta mask + 1

			lda src_
			sta src
			sta dst
			lax src_ + 1
			ora #>bitmap
			sta src + 1
			txa
			ora #>bitmap_d
			sta dst + 1

			lda y_
			tay
			asl
			sta jump + 1
			ldx height
jump			jmp (ytab)


mask_tab_l
			!byte <(mask0),<(mask0),<(mask1),<(mask1),<(mask2),<(mask2),<(mask3),<(mask3)
mask_tab_h
			!byte >(mask0),>(mask0),>(mask1),>(mask1),>(mask2),>(mask2),>(mask3),>(mask3)
-
			lda src
			adc #$38
			sta src
			sta dst
			lda src + 1
			adc #$01
			sta src + 1
			and #$1f
			ora #>bitmap_d
			sta dst + 1
yp0
			lda (mask),y
.eor0			and (src),y
			ora (dst),y
			sta (dst),y
			iny
yp1
			lda (mask),y
.eor1			and (src),y
			ora (dst),y
			sta (dst),y
			iny
yp2
			lda (mask),y
.eor2			and (src),y
			ora (dst),y
			sta (dst),y
			iny
yp3
			lda (mask),y
.eor3			and (src),y
			ora (dst),y
			sta (dst),y
			iny
yp4
			lda (mask),y
.eor4			and (src),y
			ora (dst),y
			sta (dst),y
			iny
yp5
			lda (mask),y
.eor5			and (src),y
			ora (dst),y
			sta (dst),y
			iny
yp6
			lda (mask),y
.eor6			and (src),y
			ora (dst),y
			sta (dst),y
			iny
yp7
			;add nothing to mask afterwards and add 8 less to rest afterwards, so y can just continue
			lda (mask),y
.eor7			and (src),y
			ora (dst),y
			sta (dst),y
			iny

			dex
			bpl -
			jmp jump_back

screen_
			!bin "eagleDISKfinal.kla",$3e8,$1f42
colram_
			!bin "eagleDISKfinal.kla",$3e8,$1f42 + $3e8

!warn "mask0 ",*
mask0
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000011
			!byte %00000011
			!byte %00001111
			!byte %00001111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %00001111
			!byte %00001111
			!byte %00000011
			!byte %00000011
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00001111
			!byte %00111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %00111111
			!byte %00001111
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11110000
			!byte %11111100
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111100
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
			!byte %11000000
			!byte %11000000
			!byte %11110000
			!byte %11110000
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11110000
			!byte %11110000
			!byte %11000000
			!byte %11000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

!warn "mask1 ",*
mask1
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000011
			!byte %00000011
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %00111111
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00000011
			!byte %00000011
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000011
			!byte %00001111
			!byte %00111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %00111111
			!byte %00001111
			!byte %00000011
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %00111111

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11000000
			!byte %11111100
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111100
			!byte %11000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11000000
			!byte %11110000
			!byte %11110000
			!byte %11111100
			!byte %11111100
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111100
			!byte %11111100
			!byte %11110000
			!byte %11110000
			!byte %11000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

!warn "mask2 ",*
mask2
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00001111
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000011
			!byte %00001111
			!byte %00111111
			!byte %00111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %00111111
			!byte %00111111
			!byte %00001111
			!byte %00000011
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00001111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %00001111

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11110000
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
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
			!byte %11000000
			!byte %11110000
			!byte %11111100
			!byte %11111100
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111100
			!byte %11111100
			!byte %11110000
			!byte %11000000
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %11000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

!warn "mask3 ",*
mask3
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00000011
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000011
			!byte %00001111
			!byte %00001111
			!byte %00111111
			!byte %00111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %00111111
			!byte %00111111
			!byte %00001111
			!byte %00001111
			!byte %00000011
			!byte %00000000
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000011
			!byte %00111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %00111111
			!byte %00000011

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11111100
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111100

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11000000
			!byte %11110000
			!byte %11111100
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111111
			!byte %11111100
			!byte %11110000
			!byte %11000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %11000000
			!byte %11000000
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11111100
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11110000
			!byte %11000000
			!byte %11000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000
			!byte %00000000

!align 255,0
ytab
			!word yp0, yp1, yp2, yp3, yp4, yp5, yp6, yp7
mask_clip_x
			!byte $c8,$a0,$78,$50,$28
mask_clip_y
			!byte $20,$18,$10,$08,$00
tab_width
			!byte $00,$01,$02,$03,$04
!for .x,0,34 {
			!byte $05
}
			!byte $04,$03,$02,$01,$00

tabx_l
			!byte $00,$00,$00,$00,$00
!for .x,0,39 {
			!byte <(.x * 8)
}

tabx_h
			!byte $00,$00,$00,$00,$00
!for .x,0,39 {
			!byte >(.x * 8)
}
tab_height
			!byte $00,$01,$02,$03,$04
	!for .x,0,18 {
			!byte $05
	}
			!byte $04,$03,$02,$01,$00
tab_l
			!byte $00,$00,$00,$00
	!for .x,0,24 {
			!byte <(.x * $140)
	}
tab_h
			!byte $00,$00,$00,$00
	!for .x,0,24 {
			!byte >(.x * $140)
	}

stream_data
 !byte $00,$00,$03,$FE,$05,$FE,$06,$FD,$06,$FD,$05,$FD
 !byte $04,$FF,$03,$00,$03,$00,$02,$01,$01,$02,$01,$02
 !byte $00,$02,$FF,$03,$FE,$03,$FE,$04,$FD,$03,$FE,$04
 !byte $FD,$03,$FD,$03,$FE,$02,$FD,$02,$FD,$02,$FD,$03
 !byte $FD,$03,$FB,$06,$FA,$07,$F9,$07,$FB,$07,$FC,$05
 !byte $00,$02,$04,$FF,$07,$FC,$09,$FB,$0A,$F9,$09,$F9
 !byte $07,$FA,$07,$F8,$06,$F8,$06,$F7,$05,$F7,$05,$F9
 !byte $04,$FB,$05,$FC,$05,$FD,$05,$FE,$03,$00,$02,$02
 !byte $00,$03,$FD,$07,$FB,$0A,$F9,$0B,$F9,$0C,$F9,$0A
 !byte $FB,$08,$FC,$04,$FC,$03,$FD,$02,$FD,$01,$FD,$03
 !byte $FB,$04,$FA,$06,$F9,$08,$F8,$08,$F9,$08,$FB,$07
 !byte $FE,$04,$00,$03,$03,$01,$04,$00,$06,$FF,$05,$FE
 !byte $05,$FE,$04,$FB,$05,$FA,$05,$FA,$05,$F9,$06,$F9
 !byte $06,$F9,$07,$FA,$07,$F9,$07,$FA,$08,$F9,$06,$FA
 !byte $06,$FA,$04,$FA,$04,$F9,$03,$F9,$03,$FB,$02,$FB
 !byte $04,$FD,$04,$FD,$04,$FF,$05,$FF,$04,$01,$02,$03
 !byte $00,$04,$FD,$07,$FC,$09,$FA,$0B,$F9,$0B,$F9,$0A
 !byte $FA,$09,$F9,$07,$F9,$06,$F9,$07,$F9,$06,$F9,$06
 !byte $FA,$06,$F9,$07,$F9,$07,$FA,$07,$F9,$07,$FB,$07
 !byte $FB,$05,$FC,$05,$FB,$05,$FD,$04,$FD,$04,$FF,$03
 !byte $00,$01,$03,$01,$04,$00,$05,$FF,$05,$FE,$06,$FD
 !byte $05,$FD,$05,$FC,$05,$FB,$05,$FA,$05,$F9,$05,$FA
 !byte $05,$FB,$05,$FB,$04,$FC,$04,$FC,$04,$FB,$06,$F9
 !byte $07,$F7,$0A,$F5,$0B,$F1,$0C,$F1,$0B,$F1,$0A,$F4
 !byte $07,$F7,$04,$F9,$04,$FC,$02,$FC,$01,$FF,$01,$00
 !byte $00,$02,$01,$03,$FF,$06,$00,$07,$FE,$08,$FE,$08
 !byte $FC,$08,$FA,$09,$F9,$08,$F9,$0A,$F8,$09,$F8,$09
 !byte $F9,$09,$F9,$08,$FA,$08,$F9,$08,$F9,$09,$F9,$08
 !byte $F7,$09,$F5,$0A,$F4,$0A,$F4,$0A,$F5,$0A,$F6,$09
 !byte $F9,$07,$FB,$07,$FC,$07,$FE,$05,$FF,$04,$01,$03
 !byte $02,$00,$05,$FE,$07,$FC,$09,$FA,$09,$FA,$08,$FA
 !byte $07,$FA,$07,$FA,$07,$FA,$06,$F9,$07,$F9,$06,$F9
 !byte $06,$FA,$06,$F9,$05,$FA,$06,$F9,$06,$F9,$08,$F7
 !byte $09,$F4,$0B,$F2,$0E,$EF,$0E,$EF,$0D,$EF,$0B,$F3
 !byte $08,$F6,$05,$F9,$03,$FB,$02,$FD,$01,$FF,$01,$FF
 !byte $01,$00,$01,$02,$00,$03,$00,$04,$FF,$04,$FF,$05
 !byte $FE,$04,$FF,$04,$FD,$04,$FE,$04,$FD,$05,$FC,$05
 !byte $FC,$05,$FB,$06,$FB,$07,$FA,$07,$FA,$07,$F9,$08
 !byte $F9,$09,$F9,$0A,$F8,$0C,$F7,$0B,$F8,$0C,$F8,$0B
 !byte $F9,$09,$F8,$09,$F8,$08,$F8,$08,$F9,$08,$FA,$06
 !byte $FB,$07,$FB,$07,$FC,$07,$FC,$06,$FF,$05,$01,$02
 !byte $05,$FE,$08,$FA,$0C,$F7,$0D,$F6,$0D,$F5,$0C,$F5
 !byte $09,$F7,$08,$F7,$06,$F6,$07,$F7,$06,$F7,$06,$F7
 !byte $06,$F8,$07,$F8,$06,$F8,$06,$F9,$07,$F8,$06,$F7
 !byte $06,$F6,$07,$F4,$06,$F3,$06,$F2,$06,$F4,$06,$F7
 !byte $06,$F9,$06,$FB,$07,$FE,$06,$FF,$04,$00,$03,$02
 !byte $01,$03,$FE,$06,$FC,$07,$FC,$08,$FA,$09,$FB,$08
 !byte $FC,$08,$FB,$07,$FC,$07,$FB,$06,$FB,$08,$FA,$08
 !byte $F9,$09,$F8,$0A,$F8,$0B,$F7,$0B,$F7,$0C,$F8,$0B
 !byte $F7,$0C,$F7,$0C,$F6,$0D,$F7,$0D,$F8,$0C,$FA,$09
 !byte $FE,$06,$00,$05,$01,$04,$04,$02,$04,$FF,$06,$FD
 !byte $06,$FA,$07,$F6,$0A,$F3,$09,$F1,$0A,$F2,$09,$F3
 !byte $07,$F7,$07,$F8,$06,$F9,$06,$FA,$07,$F8,$07,$F7
 !byte $08,$F4,$0B,$F1,$0B,$EF,$0B,$EF,$0A,$F0,$09,$F3
 !byte $05,$F7,$03,$F9,$01,$FC,$00,$FD,$01,$FE,$01,$FE
 !byte $03,$FE,$06,$FD,$07,$FE,$06,$FF,$05,$01,$01,$04
 !byte $FE,$08,$FA,$0C,$F7,$10,$F6,$11,$F6,$10,$F7,$0E
 !byte $F8,$0A,$FA,$09,$FA,$06,$FA,$06,$FA,$07,$F9,$08
 !byte $F7,$0A,$F6,$0C,$F5,$0E,$F5,$0D,$F6,$0D,$F8,$0B
 !byte $FA,$09,$FB,$08,$FC,$07,$FE,$05,$FF,$04,$00,$02
 !byte $03,$FF,$06,$FD,$08,$FA,$09,$F9,$09,$F8,$08,$F8
 !byte $07,$F9,$06,$F7,$06,$F6,$07,$F7,$06,$F6,$06,$F7
 !byte $07,$F9,$06,$F9,$06,$FA,$07,$FA,$06,$F9,$08,$F6
 !byte $08,$F3,$0A,$EF,$0A,$ED,$0A,$EC,$09,$EF,$07,$F3
 !byte $06,$F9,$05,$FD,$04,$FF,$02,$02,$02,$03,$01,$03
 !byte $00,$04,$FF,$04,$FF,$05,$FD,$06,$FC,$08,$FB,$0A
 !byte $F8,$0D,$F5,$10,$F3,$12,$F3,$13,$F4,$11,$F5,$10
 !byte $F8,$0C,$F9,$0B,$FA,$09,$FB,$08,$FB,$08,$FB,$07
 !byte $FB,$08,$FB,$07,$FA,$07,$FC,$07,$FC,$05,$FF,$04
 !byte $01,$03,$03,$02,$04,$01,$06,$00,$06,$FF,$05,$FD
 !byte $05,$FB,$05,$F9,$06,$F7,$05,$F6,$06,$F7,$05,$F7
 !byte $05,$F9,$05,$F9,$04,$F9,$05,$F9,$04,$FA,$04,$FA
 !byte $04,$FB,$03,$FB,$03,$FB,$03,$FC,$03,$FB,$03,$FB
 !byte $05,$FA,$05,$F8,$05,$F9,$06,$F8,$05,$F9,$05,$FB
 !byte $05,$FC,$06,$FD,$05,$FE,$05,$FF,$05,$FF,$03,$01
 !byte $02,$01,$01,$02,$01,$03,$FF,$03,$FE,$05,$FD,$07
 !byte $F9,$09,$F8,$0A,$F5,$0C,$F5,$0D,$F5,$0E,$F6,$0C
 !byte $F7,$0E,$F6,$0F,$F7,$0F,$F8,$0E,$F9,$0C,$FC,$09
 !byte $00,$06,$03,$02,$04,$00,$06,$FF,$06,$FD,$05,$FD
 !byte $03,$FD,$03,$FB,$03,$FB,$03,$F9,$03,$F9,$04,$FA
 !byte $04,$F8,$04,$F8,$04,$F8,$04,$F7,$05,$F8,$05,$F9
 !byte $05,$FA,$06,$FB,$06,$FA,$06,$FC,$05,$FD,$04,$FE
 !byte $03,$00,$02,$02,$01,$03,$01,$04,$01,$05,$FF,$04
 !byte $FF,$04,$FE,$03,$FE,$04,$FD,$05,$FC,$05,$FB,$06
 !byte $FA,$07,$F9,$08,$F8,$08,$F8,$09,$F9,$08,$FB,$07
 !byte $FD,$06,$FE,$06,$FF,$05,$00,$04,$02,$03,$02,$00
 !byte $04,$FD,$07,$F9,$08,$F8,$07,$F8,$07,$F9,$05,$FD
 !byte $02,$00,$01,$04,$00,$04,$FF,$05,$FF,$05,$00,$03
stream_data2 = * - 2


			* = bitmap
			!bin "eagleDISKfinal.kla",$1f40,2
