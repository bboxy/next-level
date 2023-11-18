			!cpu 6510
!ifndef release {
			!initmem $02
			!convtab scr
			;basic sys line
			*= $0801

			!byte $0b,$08
			!word 2019
			!byte $9e
			!text "2061"
			!byte $00,$00,$00
			lda #$35
			sta $01
			jmp volatile
}

;free space
;$3000-$37c0
;$f4d0-$ffff

;TODO XXX

OCTO		= 1
;DEBUG			;sprite map debug
MOVE		= 1

;only need to adopt bitmap pointers from min_x / 8 on and till max_x / 8, other bmp_p's are not used
;XXX eliminate unusued speedcode segments and do one segment per bank -> symmetric to just add a fixed value to jump? avoid using two tables

!ifdef DEBUG {
spe_xstart0	= 20
spe_ystart0	= 168 ;-150 ;-34

} else {

!ifdef MOVE {
;spe_xstart0	= -96
;spe_ystart0	= -74

} else {

spe_xstart0	= -120 + 24
spe_ystart0	= -120 + 47
}
}

xadd		= 0
yadd		= 0

sprlen		= 21
spryoff		= 47		;should really be 50!!!

data_init	= $2000
data_bg_col	= data_init + 12
data_spr_cols	= data_init + 13
data_chr_cols	= data_init + 16
data_platecol	= data_init + 19
data_plate_num  = data_init + 22
data_plate_x	= data_init + 23
data_pattl	= data_init + 24
data_patth	= data_init + 37
rot_data	= data_init + 50

vicbase		= $4000
charset1	= $5000
charset2	= $5800
screen		= $6c00
sprpointer	= screen + $03f8
sprites1	= $6000		;->6b00 and more gaps to be found!
sprites2	= $7000		;->7b00
volatile	= $5000
movedata1	= $4600
movedata2	= $4b00


platebg0	= $6140		;3 sprites up to $61ff
platefg0a	= $6340		;3 sprites up to $63ff
platefg0b	= $6540		;2 sprites up to $65bf

platebg1	= $6740		;3 sprites up to $61ff
platefg1a	= $6940		;3 sprites up to $63ff
platefg1b	= $6b40		;2 sprites up to $65bf

platebg2	= $7140		;3 sprites up to $61ff
platefg2a	= $7340		;3 sprites up to $63ff
platefg2b	= $7540		;2 sprites up to $65bf

platebg3	= $7740		;3 sprites up to $61ff
platefg3a	= $7940		;3 sprites up to $63ff
platefg3b	= $7b40		;2 sprites up to $65bf



;All free now!
;pattern0	= sprites2 + $140
;pattern1	= sprites2 + $340
;pattern2	= sprites2 + $540
;pattern3	= sprites2 + $740
;pattern4	= sprites2 + $940
;pattern5	= sprites2 + $b40
;pattern6	= sprites1 + $140	platebg0 0-2
;pattern7	= sprites1 + $340	platefg0a 3-5
;pattern8	= sprites1 + $540	platefg0b 6-7 up to $65bf
;pattern9	= sprites1 + $740
;patterna	= sprites1 + $940
;patternb	= sprites1 + $b40

;free
;5780-57ff	will be cleared by init!
;5f80-5fff	will be cleared by init!
;7c00-7fff
;82xx-83ff
;86xx-87ff

;0400 - 0800
;data - 5000

irqs1		= $8020		;$7c00 need to stay below $cfff because of inc/dec $01 optimization
irqs2		= $8420		;$7c00 need to stay below $cfff because of inc/dec $01 optimization

;XXX TODO some tabs can be placed in the gaps where plates are stored, if not all sprite slots are used
tab1		= $8820
tab2		= $8c20
				;$7c00-$7fff and $8020-$83ff can be used for irqs
irqdata		= $65c0
code		= $e000		;c300

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}
;BENCHMARK
MULTI

num_fills	= $2		;can be saved with release
fcnt_l		= $3		;can be saved with release
fcnt_h		= $4		;can be saved with release
tmpa		= $5
tmpx		= $6
tmpy		= $7

verticebuf_x	= $08
verticebuf_y	= $0c

;pattern		= $88
data_y		= $10

l_ynext		= $11		;can be saved if smc is used
r_ynext		= $12		;can be saved if smc is used

data		= $13		;-$14

sprylo		= $15

yscroll		= $16
trig		= $17

clipval		= $18

bal		= $19
bah		= $1a

xlo		= $1b
xhi		= $1c

ylo		= $1d
yhi		= $1e

bal2		= $1f
bah2		= $20

xlo2		= $21
xhi2		= $22

ylo2		= $23
yhi2		= $24

;trig2		= $1f



fill_code	= $25     ;location of inner loop

src		= verticebuf_x
dst		= verticebuf_x + 2

start		= verticebuf_x
end		= verticebuf_x + 1


		* = irqs1
;------------------------------------------------------------------------------
;IRQ HANDLER
;------------------------------------------------------------------------------
topirq			pha
			txa
			pha
			tya
			pha
			;inc $02
			dec $d019
			lda .load_it + 1
			beq .no_ld
.col_bg_new
			lda #$0b
			sta $d021
.col_bg_pos
			lda #$31
			sta $d012
			lda #$10
			sta $d011
			lda #<colirq
			sta $fffe
			;dec $01
			jmp .skip_render
colirq
			pha
			lda $d012
			pha
			jsr delay24
			jsr delay12
			lda #$01
			sta $d021
			lda $d012
			cmp $d012
			beq *-3
.col_bg_old
			lda #$0b
			sta $d021
			dec $d019
			anc #$00
			sta $d012
			lda #<topirq
			sta $fffe
			pla
			adc #4
			bcs +
			sta .col_bg_pos + 1
+
			;dec $01
			pla
			rti
.no_ld

!ifndef DEBUG {
			bit trig
			bmi setup_d016_d011

			;inc trig
			;dec trig2
}
update_chr_spr
off_x_c = * + 1
			lda #$00
			sta chrx_off + 1
off_y_c = * + 1
			lda #$00
			sta chry_off + 1
off_x_s = * + 1
			lda #$00
			sta sprx_off + 1
off_y_s = * + 1
			lda #$00
			sta spry_off + 1
!ifndef DEBUG {

!ifdef BENCHMARK {
			;increment some counter
			inc num_fills
			bne sk_bench

			;print benchmark result
			lda fcnt_h
			sta $200
			lda fcnt_l
			sta $201
			;reset some variables
			lda #$00
			sta fcnt_l
			sta fcnt_h
			;sta num_fills
}
sk_bench
			lda $d018
			eor #$02
			sta $d018
			lda #<(sprites2-vicbase)/64+8*0+1
			ldy #>row_to_ptr1
			cpy bank_1 + 2
			bne +
			iny
			lda #<(sprites1-vicbase)/64+8*0+1
+
			sty bank_1 + 2
			sty bank_3 + 2
			sty bank_4 + 2

			ldx #$f7
			clc
			sta sprp00a+1
			sta sprp00b+1
			adc #10
			sta sprp02a+1
			sta sprp05a+1
			sta sprp02b+1
			sta sprp05b+1
			adc #16
			sax sprp09a+1
			sax sprp09b+1
			sta sprp04a+1
			sta sprp0da+1
			sta sprp0db+1
			adc #16
			sax sprp11a+1
			sax sprp11b+1
			sta sprp15b+1

}
setup_d016_d011
			ldx #$07
chry_off		lda #$00
!ifndef DEBUG {
			clc
			adc <ylo2
			ldy <yhi2
			bcc +
			iny
			clc
+
			sbc #spryoff - 1
			bcs +
			dey
+
			sty ytmpy + 1
			sax <yscroll
			sbx #$f0			;X = A & 7 + $10
			stx $d011
			ldx #$f8
			sax .ylo + 1
} else {

			;lda #$35
			;sta $01
d011			lda #$15
			clc
			adc #$01
			and #$07
			sta d011+1
			sta <yscroll
}
			lda <xlo2
			;clc				;cleared by sbx
chrx_off		adc #$00
!ifndef DEBUG {
			ldy <xhi2
			bcc +
			iny
+
			sax .xlo + 1
			sty ytmpx + 1
			anc #$07
			ora #$10
			sta $d016
}
;-----------------------
;clip x start
			; lda #$00
			; sta $d015

			lda <xlo
			;clc				;cleared by sbx
sprx_off		adc #$00
			ldy <xhi
			bcc +
			clc
			iny
+
.clipright		beq +				;y = $00
			iny
			beq .clipleft			;y = $ff
			dey
			dey
			bne .nospr_			;y != 1, means > $01 and < $ff -> no spr irq
			tax
			bmi .nospr_			;check lowbyte > $180? -> no spr irq
			dey
			;ldy #%11111111
+
			sta $d000
			sta $d00a
			;clc
			adc #24
			sta $d002
			sta $d00c
			bcc +
			ldy #%11011110
			clc
+
			adc #24
			sta $d004
			sta $d00e
			bcc +
			ldy #%10011100
			clc
+
			adc #24
			sta $d006
			bcc +
			ldy #%00011000
			clc
+
			adc #24
			sta $d008
			bcc clipy
			ldy #%00010000
+
			jmp clipy
.nospr_			ldx #$06
			lda #221
			jmp .nosprirq
.clipleft
			;clc
			adc #$78 - 24
			bcs +
			tya
			sec
+
			sta $d008
			sbc #24
			bcs +
			tya
			sec
+
			sta $d006
			sbc #24
			bcs +
			tya
			sec
+
			sta $d004
			sta $d00e
			sbc #24
			bcs +
			tya
			sec
+
			sta $d002
			sta $d00c
			sbc #24
			bcs +
			tya
+
			sta $d000
			sta $d00a

;-----------------------
clipy
			sty $d010

			lda ylo
			clc
spry_off		adc #$00
			sta sprylo
			ldx yhi
			bcc +
			inx
+			stx spryhi+1

			beq .clipbottom		;x == $00?
			inx
			bne .noplateirq		;x is between $01 and $fe
.cliptop
			cmp #$b9
			bcc .nospr_
			cmp #$e3

			inx
			bne +			;BRA		-> results in 1 or 2
.clipbottom
			cmp #$f4		;bottm 38/24
			bcs .noplateirq
			cmp #$0c
+
			bcs .clip0		;results in 0 or 1
.clip1
			inx
.clip0
			eor yscroll
			lsr
			txa
			rol			;-> x = x * 2 + carry
			tax

			lda sprylo
			adc irqofftab,x
.nosprirq		sta $d012

			lda irqtabalo,x
			sta $fffe
			lda irqtabahi,x
			sta $ffff

!ifdef DEBUG {
			lda colortab,x
			sta $d020
}
.spcol3			lda #$08
			sta $d025
.spcol1			lda #$0f
			sta $d026
.spcol2			lda #$0a
			sta $d027
			sta $d028
			sta $d029
			sta $d02a
			sta $d02b
			sta $d02c
			sta $d02d
			sta $d02e
			ldx #$ff
			stx $d01c
			inx
			stx $d01d
			
.noplateirq
			;dec $01
			cli

!ifdef DEBUG {
ylower			lda #$00
			clc
			adc #$08
			sta ylower+1
			bne +

			lda ylo
			clc
			adc #<yadd
			sta ylo
			lda yhi
			adc #>yadd
			sta yhi

			; lda ylo
			; eor #$03
			; sta ylo

			lda xlo
			;clc
			adc #<xadd
			sta xlo
			lda xhi
			adc #>xadd
			sta xhi
+
} else {

			ldy #$00
-			lda (bal),y
			cmp #$80
			beq .skip_move
asi			ldx #$00
			bcc +
			dex
			clc
+			adc xlo
			sta xlo
			txa
			adc xhi
			sta xhi

			ldx #$00
			lda (bal2),y
			bpl +
			dex
+			clc
			adc xlo2
			sta xlo2
			txa
			adc xhi2
			sta xhi2

			iny
			ldx #$00
			lda (bal),y
			bpl +
			dex
+			clc
			adc ylo
			sta ylo
			txa
			adc yhi
			sta yhi

			ldx #$00
			lda (bal2),y
			bpl +
			dex
+			clc
			adc ylo2
			sta ylo2
			txa
			adc yhi2
			sta yhi2

	!ifdef MOVE {
			lda bal
			clc
			adc #$02
			sta bal
			sta bal2
			bcc +
			inc bah
			inc bah2
+
	}
}

!ifdef BENCHMARK {
			inc fcnt_l
			bne +
			inc fcnt_h
+
}

.do_move
!ifndef DEBUG {
			jsr move_vector2	;move chargrid if necessary
.skip_move
			bit trig
			bmi ++
			;now finally move the grid after all values are set (d011, d018, d016)
			inc trig
render
			jsr do_render
			dec trig
++
}
.skip_render
			pla
			tay
			pla
			tax
			pla
			rti

;------------------------------------------------------------------------------
;spr layout a
;a0 a1 a2 a3 a4
;good
;b5 b6 b7 b3 b4
;bad
;c0 c1 c2 c3 c4
;good
;d5 d6 d7 d3 d4
;bad
;e0 e1 e2 e3 e4
;good
;f5 f6 f7 f3 f4

;-----------------------
earlysprirq5a		nop
			nop
			nop
			nop

sprirq5a		sta <tmpa
			bit $00
			clc
			inc $02
			lda sprylo
			adc #sprlen*5
			sta $d007
			sta $d009
			jmp exitsprirq5
;-----------------------
sprirq4aclip		sta <tmpa
			stx <tmpx
			inc $02
			lax sprylo
			sbx #-(sprlen*4)
			stx $d001
			stx $d003
			stx $d005
			stx $d007
			stx $d009
			clc
			adc #sprlen*5
			sta $d00b
			sta $d00d
			sta $d00f
			lda #$ff
			sta $d015

sprp04a			lda #<(sprites1-vicbase)/64+8*3+1+2
			clc
			adc #5
			sta sprpointer+0
			adc #1
			sta sprpointer+1
			adc #1
			sta sprpointer+2
			jmp sprp11a

sprirq4a		sta <tmpa
			stx <tmpx
			inc $02
sprirq4askip		clc
sprp11a			lda #<(sprites1-vicbase)/64+8*4+1+2
			sta sprpointer+3
			adc #1
			sta sprpointer+4
			adc #4
			sta sprpointer+5
			adc #1
			sta sprpointer+6
			adc #1
			sta sprpointer+7

			lda #<sprirq5a
			sta $fffe
!if >sprirq4a != >sprirq5a or >sprirq4aclip != >sprirq5a{
			lda #>sprirq5a
			sta $ffff
}

			lax sprylo
			sbx #-(sprlen*5)
			php
			cpx #$30			;extra check for no badlines @top
			bcc +

			txa
			and #%00000111
			eor yscroll
			bne +

			dex				;badline one line earlier
			lda #<earlysprirq5a
			sta $fffe
!if >sprirq4a != >earlysprirq5a or >sprirq4aclip != >earlysprirq5a {
			lda #>earlysprirq5a
			sta $ffff
}
+
			stx $d012

			ldx <tmpx
			plp
			jmp leavesprirq

;-----------------------
earlysprirq3a
			jsr delay12
sprirq3a
			sta <tmpa
			stx <tmpx
			inc $02

			lda sprylo
			clc
			adc #sprlen*3
			sta $d007
			sta $d009

sprp0da			lda #<(sprites1-vicbase)/64+8*3+1+2
			sta sprpointer+3
			clc
			adc #1
			sta sprpointer+4
			adc #4
			sta sprpointer+0
			adc #1
			sta sprpointer+1
			adc #1
			sta sprpointer+2

			lda #<sprirq4a
			sta $fffe
!if >sprirq4a != >sprirq3a or >sprirq4a != >earlysprirq3a {
			lda #>sprirq4a
			sta $ffff
} else {
}
			lax sprylo
			sbx #-sprlen*5
			clc
			adc #sprlen*4
			sta $d012
			stx $d00b
			stx $d00d
			stx $d00f
			ldx <tmpx

			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009


			jmp leavesprirq

;-----------------------
sprirq2aclip		sta <tmpa
			stx <tmpx
			inc $02

			lda #$ff
			sta $d015

			lax sprylo
			sbx #-(sprlen*2)
			stx $d001
			stx $d003
			stx $d005
			stx $d007
			stx $d009
			clc
			adc #sprlen*3
			sta $d00b
			sta $d00d
			sta $d00f

sprp02a			lda #<(sprites1-vicbase)/64+8*1+1+2
			clc
			adc #5
			sta sprpointer+0
			adc #1
			sta sprpointer+1
			adc #1
			sta sprpointer+2

			jmp sprp09a

sprirq2a		sta <tmpa
			stx <tmpx
			inc $02

sprirq2askip		clc
sprp09a			lda #<(sprites1-vicbase)/64+8*2+1+2
			sta sprpointer+3
			adc #1
			sta sprpointer+4
			adc #4
			sta sprpointer+5
			adc #1
			sta sprpointer+6
			adc #1
			sta sprpointer+7
			lda #<sprirq3a
			sta $fffe
!if >sprirq2a != >sprirq3a or >sprirq2aclip != >sprirq3a {
			lda #>sprirq3a
			sta $ffff
}
			lax sprylo
			sbx #-sprlen*3
			txa
			and #%00000111
			eor yscroll
			bne +
			dex				;badline one line earlier
			lda #<earlysprirq3a
			sta $fffe
!if >earlysprirq3a != >sprirq3a {
			lda #>earlysprirq3a
			sta $ffff
}

+			stx $d012
			ldx <tmpx

			jmp leavesprirq



;spr layout b
;a5 a6 a7 a3 a4
;bad
;b0 b1 b2 b3 b4
;good
;c5 c6 c7 c3 c4
;bad
;d0 d1 d2 d3 d4
;good
;e5 e6 e7 e3 e4
;bad
;f0 f1 f2 f3 f4

!warn "end if new irqs1: ",*
			* = irqs2
;-----------------------
earlysprirq1a		jsr delay12

sprirq1a		sta <tmpa			;b3 b4
			stx <tmpx
			inc $02

			lax sprylo
			sbx #-sprlen
			stx $d007
			stx $d009

			clc
sprp05a			lda #<(sprites1-vicbase)/64+8*1+1+2
			sta sprpointer+3
			adc #1
			sta sprpointer+4
			adc #4
			sta sprpointer+0
			adc #1
			sta sprpointer+1
			adc #1
			sta sprpointer+2

			lda #<sprirq2a
			sta $fffe

!if >earlysprirq1a != >sprirq2a or >sprirq1a != >sprirq2a {
			lda #>sprirq2a
			sta $ffff
			} else {
			nop
			nop
			nop
}
			lax sprylo
			sbx #-sprlen*3
			clc
			adc #sprlen*2
			sta $d012

			stx $d00b
			stx $d00d
			stx $d00f

			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009

			ldx <tmpx
			jmp leavesprirq
;-----------------------
sprirq0a		sta <tmpa
			stx <tmpx
			inc $02

			ldx #$fe
			clc
sprp00a			lda #<(sprites1-vicbase)/64+8*0+1
			sax sprpointer+0
			sta sprpointer+1
			adc #2
			sax sprpointer+2
			sta sprpointer+3
			adc #2
			sax sprpointer+4
			adc #4
			sax sprpointer+5
			sta sprpointer+6
			adc #2
			sax sprpointer+7

			inx
			stx $d015

			lda sprylo
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			adc #sprlen
			sta $d00b
			sta $d00d
			sta $d00f

			ldx #<sprirq1a
			stx $fffe
!if >sprirq0a != >sprirq1a {
			ldx #>sprirq1a
			stx $ffff
}
			tax
			and #%00000111
			eor yscroll
			bne +
			dex				;badline one line earlier
			lda #<earlysprirq1a
			sta $fffe
!if >sprirq1a != >earlysprirq1a {
			lda #>earlysprirq1a
			sta $ffff
}

+			stx $d012
			ldx <tmpx
			jmp leavesprirq
;------------------------------------------------------------------------------
.checklo		lda sprylo
			cmp #223+23
			bcs .gotop
			cmp #221
			bcs .move
			lda platey+1
			sbc #5
			cmp #221
			bcs .move
			lda #221
.move
			sta $d012
			adc #$04
			sta platey+1

			lda #>bottomirq
			sta $ffff
			lda #<bottomirq
			sta $fffe

.exitirq		;dec $01
			lda <tmpa
			rti
;------------------------------------------------------------------------------
sprirq5b		sta <tmpa
			inc $02
exitsprirq5		clc
sprp15b			lda #<(sprites1-vicbase)/64+8*5+1+2
			sta sprpointer+3
			adc #1
			sta sprpointer+4
;------------------------------------------------------------------------------
exitsprirq		inc $d019
			lda sprylo
			clc
			adc #sprlen*6
			sta sprylo
			lda spryhi+1
			adc #$00
			beq .checklo
.gotop
			;fickeriki dec $d020
			lda #>topirq
			sta $ffff
			lda #<topirq
			sta $fffe

			lda #$00
			sta $d012
			sta $d015
			beq .exitirq

;-----------------------
earlysprirq4b		jsr delay24
			nop
			nop

sprirq4b		sta <tmpa
			inc $02

			clc
sprp11b			lda #<(sprites1-vicbase)/64+8*4+1+2
			sta sprpointer+3
			adc #1
			sta sprpointer+4
			adc #4
			sta sprpointer+0
			adc #1
			sta sprpointer+1
			adc #1
			sta sprpointer+2

			lda #<sprirq5b
			sta $fffe
!if >sprirq5b != >sprirq4b or >sprirq5b != >earlysprirq4b {
			lda #>sprirq5b
			sta $ffff
}

			lda sprylo
			adc #sprlen*5
			sta $d012

			sta $d007
			sta $d009

leavesprirq		bcc +
spryhi			lda #$00
			bpl exitsprirq
+			inc $d019
			;dec $01
			lda <tmpa
			rti

;-----------------------
sprirq3b		sta <tmpa
			stx <tmpx
			inc $02

			clc
sprp0db			lda #<(sprites1-vicbase)/64+8*3+1+2
			sta sprpointer+3
			adc #1
			sta sprpointer+4
			adc #4
			sta sprpointer+5
			adc #1
			sta sprpointer+6
			adc #1
			sta sprpointer+7

			lda #<sprirq4b
			sta $fffe
!if >sprirq4b != >sprirq3b {
			lda #>sprirq4b
			sta $ffff
}

			lax sprylo
			sbx #-(sprlen*5)
			stx $d001
			stx $d003
			stx $d005
			clc
			adc #sprlen*4
			sta $d00b
			sta $d00d
			sta $d00f
			sta $d007
			sta $d009
			tax
			and #%00000111
			eor yscroll
			bne +
			dex				;badline one line earlier
			lda #<earlysprirq4b
			sta $fffe
!if >earlysprirq4b != >sprirq4b {
			lda #>earlysprirq4b
			sta $ffff
}
+			stx $d012
			ldx <tmpx

			jmp leavesprirq
;-----------------------
sprirq2bclip		sta <tmpa
			inc $02
			lda #$ff
			sta $d015

			lda sprylo
			clc
			adc #sprlen*2
			sta $d00b
			sta $d00d
			sta $d00f
			sta $d007
			sta $d009
			clc
			adc #sprlen
			sta $d001
			sta $d003
			sta $d005

sprp02b			lda #<(sprites1-vicbase)/64+8*1+1+2
			clc
			adc #5
			sta sprpointer+5
			adc #1
			sta sprpointer+6
			adc #1
			sta sprpointer+7
			jmp sprp09b

earlysprirq2b		jsr delay24
			nop
			nop

sprirq2b		sta <tmpa
			inc $02
			clc
sprp09b			lda #<(sprites1-vicbase)/64+8*2+1+2
			sta sprpointer+3
			adc #1
			sta sprpointer+4
			adc #4
			sta sprpointer+0
			adc #1
			sta sprpointer+1
			adc #1
			sta sprpointer+2
			lda #<sprirq3b
			sta $fffe
!if >sprirq3b != >sprirq2b or >sprirq3b != >earlysprirq2b or >sprirq3b != sprirq2bclip {
			lda #>sprirq3b
			sta $ffff
}
			lda sprylo
			adc #sprlen*3
			sta $d012
			sta $d007
			sta $d009

			jmp leavesprirq

;-----------------------
sprirq1b		sta <tmpa
			stx <tmpx
			inc $02
			clc
sprp05b			lda #<(sprites1-vicbase)/64+8*1+1+2
			sta sprpointer+3
			adc #1
			sta sprpointer+4
			adc #4
			sta sprpointer+5
			adc #1
			sta sprpointer+6
			adc #1
			sta sprpointer+7
			lda #<sprirq2b
			sta $fffe
!if >sprirq2b != >sprirq1b {
			lda #>sprirq2b
			sta $ffff
}
			lax sprylo
			sbx #-(sprlen*3)
			stx $d001
			stx $d003
			stx $d005
			clc
			adc #sprlen*2
			sta $d00b
			sta $d00d
			sta $d00f
			sta $d007
			sta $d009
			tax
			and #%00000111
			eor yscroll
			bne +
			dex				;badline one line earlier
			lda #<earlysprirq2b
			sta $fffe
!if >earlysprirq2b != >sprirq2b {
			lda #>earlysprirq2b
			sta $ffff
}
+			stx $d012
			ldx <tmpx
			jmp leavesprirq

;-----------------------
sprirq0b		sta <tmpa
			stx <tmpx
			inc $02

			lax sprylo
			sta $d00b
			sta $d00d
			sta $d00f
			sta $d007
			sta $d009
			sbx #-sprlen
			stx $d001
			stx $d003
			stx $d005

			ldx #$ff
			stx $d015
			dex
			clc
sprp00b			lda #<(sprites1-vicbase)/64+8*0+1
			sax sprpointer+5		;0
			sta sprpointer+6		;1
			adc #2
			sax sprpointer+7		;2
			sta sprpointer+3		;3
			adc #2
			sax sprpointer+4		;4
			adc #4
			sax sprpointer			;8
			sta sprpointer+1		;9
			adc #2
			sax sprpointer+2		;10

			lda #<sprirq1b
			sta $fffe
!if >sprirq1b != >sprirq0b {
			lda #>sprirq1b
			sta $ffff
} else {
			nop
			nop
			nop
}
			jsr delay24			;do something here?
			jsr delay24

			ldx <tmpx
			lda sprylo
			adc #sprlen
			sta $d012

			sta $d007
			sta $d009
			jmp leavesprirq

;------------------------------------------------------------------------------
bottomirq		sta <tmpa
			;inc $02
	
platey			lda #225+21
			sta $d001
			sta $d003
			sta $d005
			sta $d007
			sta $d009
			sta $d00b
			sta $d00d
			sta $d00f

.plate_0		lda #<(platefg3a-vicbase)/64
			sta sprpointer+0
.plate_1		lda #<(platefg3a-vicbase)/64+1
			sta sprpointer+1
.plate_2		lda #<(platefg3a-vicbase)/64+2
			sta sprpointer+2
.plate_3		lda #<(platefg3b-vicbase)/64
			sta sprpointer+3
.plate_4		lda #<(platefg3b-vicbase)/64+1
			sta sprpointer+4

.plate_5		lda #<(platebg3-vicbase)/64
			sta sprpointer+5
.plate_6		lda #<(platebg3-vicbase)/64+1
			sta sprpointer+6
.plate_7		lda #<(platebg3-vicbase)/64+2
			sta sprpointer+7

			lda #%11100000
			sta $d01c
			sta $d01d
.platecol1		lda #$01
			sta $d025
.platecol2		lda #$0e
			sta $d026
			anc #$00
			sta $d027
			sta $d028
			sta $d029
			sta $d02a
			sta $d02b
.platecol3		lda #$04
			sta $d02c
			sta $d02d
			sta $d02e

.plate_x		lda #207
			sta $d000
			adc #24
			sta $d002
			adc #24
			sta $d004
			adc #24
			sta $d006
			adc #23
			sta $d008

			lda #191
			sta $d00a
			lda #191+48
			sta $d00c
			lda #31
			sta $d00e

			lda #%10011000
			sta $d010

			lda #$ff
			sta $d015

			lda #>topirq
			sta $ffff
			lda #<topirq
			sta $fffe
			inc $d019

			lda #$00
			sta $d012
			;dec $01
			lda <tmpa
			rti
!ifdef release {
vblank
.wait1			bit $d011
			bpl .wait1
.wait2			bit $d011
			bmi .wait2
delay12			rts				;delay 12 cycles if called by jsr
delay24
			jsr delay12
			rts
}
!ifdef release {
irqtabalo
			!byte <sprirq0b
			!byte <sprirq0a
			!byte <sprirq2bclip
			!byte <sprirq2aclip
			!byte <sprirq4aclip
			!byte <sprirq4aclip
			!byte <bottomirq
irqtabahi
			!byte >sprirq0b
			!byte >sprirq0a
			!byte >sprirq2bclip
			!byte >sprirq2aclip
			!byte >sprirq4aclip
			!byte >sprirq4aclip
			!byte >bottomirq
irqofftab
			!byte -2
			!byte -2
			!byte sprlen*2-1
			!byte sprlen*2-1
			!byte sprlen*4-2
			!byte sprlen*4-2
}
!warn "end if new irqs2: ",*
!ifndef release {
			*= irqdata
irqtabalo
			!byte <sprirq0b
			!byte <sprirq0a
			!byte <sprirq2bclip
			!byte <sprirq2aclip
			!byte <sprirq4aclip
			!byte <sprirq4aclip
			!byte <bottomirq
irqtabahi
			!byte >sprirq0b
			!byte >sprirq0a
			!byte >sprirq2bclip
			!byte >sprirq2aclip
			!byte >sprirq4aclip
			!byte >sprirq4aclip
			!byte >bottomirq

irqofftab
			!byte -2
			!byte -2
			!byte sprlen*2-1
			!byte sprlen*2-1
			!byte sprlen*4-2
			!byte sprlen*4-2

!ifdef DEBUG {
colortab		!byte $00
			!byte $01
			!byte $02
			!byte $03
			!byte $04
			!byte $05
}

;------------------------------------------------------------------------------
;vblank - wait for vertical blank
;------------------------------------------------------------------------------
vblank
.wait1			bit $d011
			bpl .wait1
.wait2			bit $d011
			bmi .wait2
delay12
			rts				;delay 12 cycles if called by jsr
delay24
			jsr delay12
			rts
}

;------------------------------------------------------------------------------
;end irq handler
;------------------------------------------------------------------------------


		* = volatile
dither_setup
		sei
		ldx #$ff
		txs
		jsr vblank
		lda #$02
		sta $dd00
		lda #$66
		sta $d018
!ifdef release {
		jsr link_decomp
}
		lda #$21
		sta <clipval
		lda #$ff
!ifndef DEBUG {
		sta $d01c
}

		; lda #$08
		; sta $d025
		; lda #$0f
		; sta $d026
		; lda #$0a
		; sta $d027
		; sta $d028
		; sta $d029
		; sta $d02a
		; sta $d02b
		; sta $d02c
		; sta $d02d
		; sta $d02e

		ldx #$00
		stx $d01b
		stx $d017
		stx $d01d
-
!ifndef release {
		lda #$00
!ifndef DEBUG {
		sta sprites1 + $000,x
;		sta sprites1 + $200,x
;		sta sprites1 + $400,x
;		sta sprites1 + $600,x
;		sta sprites1 + $800,x
		sta sprites1 + $a00,x
		sta sprites2 + $000,x
;		sta sprites2 + $200,x
;		sta sprites2 + $400,x
;		sta sprites2 + $600,x
;		sta sprites2 + $800,x
		sta sprites2 + $a00,x
		sta sprites1 + $040,x
;		sta sprites1 + $240,x
;		sta sprites1 + $440,x
;		sta sprites1 + $640,x
;		sta sprites1 + $840,x
		sta sprites1 + $a40,x
		sta sprites2 + $040,x
;		sta sprites2 + $240,x
;		sta sprites2 + $440,x
;		sta sprites2 + $640,x
;		sta sprites2 + $840,x
		sta sprites2 + $a40,x
}
		dex
		bne -
}
		;lda #$34
		;sta $01
		;generate mask tables
		jsr setup_fill
		jsr gen_clear
		jsr reset_data_ptr
		;jsr reset_move_ptr
		;jsr move_vector2

		;inc $01
!ifndef release {
		lda #$7f
		sta $dc0d
		lda $dc0d
		lda #$01
		sta $d01a
		sta $d019
}
		jsr vblank
		;lda #$13
		;sta $d011
		lda #$00
		sta $d012

		lda #<topirq
		sta $fffe
		lda #>topirq
		sta $ffff

		jsr vblank

		;lda #$0b
		;sta $d021
		;lda #$00
		;sta $d020
		;lda #$02
		;sta $dd00
		lda #((screen & $3f00) / $40) + ((charset2 & $3fff) / $400); xor 2
		sta $d018

		;clear a bunch of variables

!ifdef BENCHMARK {
		lda #$00
		sta num_fills
		;reset frame counter
		sta fcnt_l
		sta fcnt_h
}

		ldy #$10		;copied from main
		lxa #0
		jmp main


		;XXX TODO interleave sprite $180 / $180 per bank
		;XXX TODO or fill gaps with reasonable content
;--------------------------
;CLEAR
;clear screenbuffer, FAST and only necessary areas
;--------------------------

;clear only those blocks that the object rotates in (circle with a radius of 128)
;takes ~$57 rasterlines, so not much to bother about

tabrowl
		!byte $00,$01,$02,$40,$41,$42,$80,$81,$82,$c0,$c1,$c2,$00,$01,$02,$40
tabrowh
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01

		;XXX tabs for dödelkaeder
;tab_s
;                !byte $37, $22, $19, $11, $0d, $09, $08, $07, $07, $08, $09, $0d, $11, $1b, $24, $27
;tab_e
;                !byte $4a, $5e, $67, $6f, $74, $77, $79, $79, $7a, $78, $77, $73, $6f, $66, $5c, $4f

tab_s
		!byte $08, $07, $00, $00, $00, $00, $00, $00, $00, $02, $02, $02, $04, $04, $08, $27
tab_e
		!byte $73, $75, $7b, $7b, $7b, $7b, $7b, $7b, $7b, $7b, $7b, $7b, $79, $78, $74, $4f
;			64, 64, 64, 64, 64, 50, 48, 48,     48, 50, 64, 64, 64, 64, 64, 64

gen_clear
		lda #<clearcode
		sta dst
		sta clear1 + 1
		lda #>clearcode
		sta dst + 1
		sta clear1 + 2
		jsr make_bank_spr
		lda #>charset1
		sta high_chr + 1
		jsr make_bank_chr

		ldy #$00
		lda #$60
		sta (dst),y
		inc dst
		bne +
		inc dst + 1
+
		lda dst
		sta clear2 + 1
		lda dst + 1
		sta clear2 + 2
		lda #>row_to_ptr2
		sta .start_spr2 + 2
		jsr make_bank_spr

		lda #>charset2
		sta high_chr + 1
		jsr make_bank_chr

		ldy #$00
		lda #$60
		sta (dst),y
		inc dst
		bne +
		inc dst + 1
+
		rts
;-> von tab_s bis tab_s+tab_t
;von tab_e - tab_t bis tab_e


make_bank_chr
		dec high_chr + 1
		ldx #$00
nextloop_chr
		txa
		asr #$01
		ror

		bmi +
		inc high_chr + 1
+
		ora tab_s,x
		sta odd_chr + 1

		and #$80
		ora tab_e,x
		sta .chr_end + 1

		jsr do_clm_chr
		inx
		cpx #$0f
		bne nextloop_chr
		rts


do_clm_chr
		;XXX TODO write sta and check after each sta if close to next table, in case create jump to next location
-
		lda dst
		cmp #$fc
		bcc +
		lda dst + 1
		bpl +
		cmp #$bf
		bcc .frickel1
		cmp #$cf
		bcc +
		ldy #$00
		lda #$4c
		sta (dst),y
		iny
		lda #$00
		sta (dst),y
		iny
		lda #$3e
		sta (dst),y
		sta dst + 1
		lda #$00
		sta dst
		beq +
.frickel1
		adc #1
		and #$03
		bne +

		tay
		lda #$10
		sta (dst),y
		iny
.dec1		lda #$1e
		sec
		sbc dst
		sec
		sbc #2
		sta (dst),y
		iny
		inc dst + 1
		lda .dec1 + 1
		sta dst
		beq +
		sec
		sbc #2
		sta .dec1 + 1
		sta .dec2 + 1
+
		ldy #$00
		lda #$8d
		sta (dst),y
		iny
odd_chr		lda #$00
		sta (dst),y
		iny
high_chr	lda #$00
		sta (dst),y
		tya
		sec
		adc dst
		sta dst
		bcc +
		inc dst + 1
+
.chr_end	lda #$00
		sec
		isc odd_chr + 1
		bne -
		rts

make_bank_spr
		ldx #$00
nextloop_spr
		lda tab_s,x
		sta .start_spr2 + 1
		clc
		adc #<row_to_y
		sta .start_spr1 + 1
		lda tab_e,x
		;end position
		sta .end_spr + 1
		lda tabrowl,x
		sta .trowl + 1
		lda tabrowh,x
		sta .trowh + 1

		jsr do_clm_spr

		inx
		cpx #$0f
		bne nextloop_spr
		rts

do_clm_spr
		;XXX TODO write sta and check after each sta if close to next table, in case create jump to next location
-
		lda dst
		cmp #$fc
		bcc +
		lda dst + 1
		bpl +
		cmp #$bf
		bcc .frickel2
		cmp #$cf
		bcc +
		ldy #$00
		lda #$4c
		sta (dst),y
		iny
		lda #$00
		sta (dst),y
		iny
		lda #$3e
		sta (dst),y
		sta dst + 1
		lda #$00
		sta dst
		beq +
.frickel2
		adc #1
		and #$03
		bne +

		tay
		lda #$10
		sta (dst),y
		iny
.dec2		lda #$1e
		sec
		sbc dst
		sec
		sbc #2
		sta (dst),y
		iny
		inc dst + 1
		lda .dec2 + 1
		sta dst
		beq +
		sec
		sbc #2
		sta .dec1 + 1
		sta .dec2 + 1
+
		ldy #$00
		lda #$8d
		sta (dst),y
.trowl		lda #$00
		clc
.start_spr1	adc row_to_y
		iny
		sta (dst),y
.trowh		lda #$00
.start_spr2
		ora row_to_ptr1
		iny
		sta (dst),y
		tya
		sec
		adc dst
		sta dst
		bcc +
		inc dst + 1
+
.end_spr	lda #$00
		inc .start_spr1 + 1
		sec
		isc .start_spr2 + 1
		bne -
		rts

		;check if we can sync safely before clear? If not, do clear beforehand and then recheck + wait?
;--------------------------
;THE VERY INNER LOOP OF OUR FILLER
;(will be placed into zeropage for max. performance)
;--------------------------

fill_start
!pseudopc fill_code {
		;XXX TODO place combined speedcode in ZP to combine pointers with direct code
;clmf		!word charset1 + $80 * $f

f_end_s
f_yend = * + 1
		ldy #$00			;Finding new segment relies on y be yend, not the case with sprites, so we restore it here
f_end_c
		jmp update_edge_
f_inc
		lda <clm0 + 1
		sbc #2
sprhi = * + 1
		cmp #$00
		bcc f_end_s
		bne +				;still not reached last spriterow, sprhi must be < clm0+1
sprlo = * + 1
		ldy #$00			;last spriterow to do, set up endvalue
		sty <f_ynext
+
		tay
		sty <clm0 + 1			;advance pointers
		sty <clm1 + 1
		sty <clm2 + 1

		sty <clm3 + 1
		sty <clm4 + 1
		sty <clm5 + 1

		sty <clm6 + 1
		sty <clm7 + 1
		sty <clm8 + 1

		sty <clm9 + 1
		sty <clma + 1
		sty <clmb + 1
		iny				;preserve set carry this way
		sty <clmc + 1
		sty <clmd + 1
		sty <clme + 1
		ldy #$3c
		bne f_right			;XXX TODO OPTIMIZE ME, branch to f_right/f_right_, but setup is possibly more expensive then thie double branch each 21 lines
						;XXX TODO rewrite code from here on and move entry by two bytes back/forth to avoid extra branch at f_code_b? but f_back must be changed then? :-(
fail
fail2
		jam
clmd		!word 0
clme		!word 0
f_back_0
clm0 = * + 1
		sta $1000,y
f_back_1
clm1 = * + 1
		sta $1000,y
f_back_2
clm2 = * + 1
		sta $1000,y
f_back_3
clm3 = * + 1
		sta $1000,y
f_back_4
clm4 = * + 1
		sta $1000,y
f_back_5
clm5 = * + 1
		sta $1000,y
f_back_6
clm6 = * + 1
		sta $1000,y
f_back_7
clm7 = * + 1
		sta $1000,y
f_back_8
clm8 = * + 1
		sta $1000,y
f_back_9
clm9 = * + 1
		sta $1000,y
f_back_a
clma = * + 1
		sta $1000,y
f_back_b
clmb = * + 1
		sta $1000,y
f_back_c
		and maskr,x
		beq +				;averages to 9,75 (1:4 chance that branch hits in) instead of 10 cycles
clmc = * + 1
		ora $1000,y
		sta (clmc),y
+
;--------ENTRY POINT-----------------------------------------
fill
f_back		;common entry point where all code segments reenter after done
f_ynext = * + 1
		cpy #$00			;will always set carry, needed for later subtraction

		;case chars
;f_dispatch	bne *+4				;3 cycles till dey
;		beq f_end_c
;		dey

		;case sprites
;f_dispatch	beq f_inc			;2 cycles till dey
;		dey
;		dey
;		dey

f_dispatch	bne *+4
		beq f_inc

;--------RIGHT SLOPE STEEP-----------------------------------------
		dey
f_right
f_err = * + 1
		lda #$00
f_dy = * + 1
		sbc #$00			;do that bresenhamthingy for xend, code will be setup for either flat or steep slope
f_code_bcs1	bcs f_left			;changes to bcs f_right_ for flat slopes
f_dx = * + 1
		adc #$00
f_code_dex	dex
f_code_bcs2	bpl f_left			;will be a BRA if entered for flat mode, as x will never exceed $00..$7f

		;sta <f_err			;will be stored on f_left
		;reload counter
f_nvr = * + 1
		ldx #$00
		;directly modify jmp target (+/-2)
f_smc_jmp_4 = * + 1
f_jmodr1	inc <f_jmp_ + 1			;directly modify jmp target (+/-2) by two inc/dec
f_smc_jmp_5 = * + 1
f_jmodr2	inc <f_jmp_ + 1
		bcs f_left
;--------RIGHT SLOPE FLAT------------------------------------
f_right_
-
f_dy_ = * + 1
		sbc #$00			;XXX TODO could subtract dy/2 and therefore do twice dex/inx to compensate or shrink table ttab_b1 to change values each for steps, but introduces more error?
f_code_dex2_	dex
		bcs -
f_dx_ = * + 1
		adc #$00
f_code_dex1_	dex
f_right2_
		sta <f_err
		lda ttab_b1,x			;XXX TODO could also spread the table values over up to $10 bytes each and fill gaps with clear code?
		;lda #$f8			;XXX TODO this would spread tables over 8 byte each
		;sax
;--------LEFT SLOPE STEEP-----------------------------------
f_left
		sta <f_err
		;sta <f_jmp_ + 1		;will be either sta f_jmp_ + 1 or sta <f_err, depending if steep or flat
f_err2 = * + 1
		lda #$00
f_dy2 = * + 1
		sbc #$00
f_code_bcs3	bcs f_draw			;points to either f_draw or f_left_
f_dx2 = * + 1
		adc #$00
f_code_dec	dec <f_x2_
						;XXX TODO try with lsr <mask until bcc? but would need always to have two bits cleared?
f_code_bcs4	bpl f_draw			;points to either f_draw or f_left2_ - only modify jump if needed (each 8 pixels)

		sta <f_err2			;need to store here already, as we taint A in next step
f_nv = * + 1
 		lda #$00			;eor #$f8 would also suffice, but would require load of f_x2_ so reload counter this way
f_smc_x2_1 = * + 1
		sta <f_x2_
f_smc_jmp_2 = * + 1
		lda <f_jmp_ + 2
f_jmod = * + 1
		sbc #$fc			;directly modify jmp target (+/-4)
f_smc_jmp_3 = * + 1
		sta <f_jmp_ + 2
		jmp f_draw + 2			;skip the sta <f_err2
;--------LEFT SLOPE FLAT------------------------------------
f_left_
-
f_dy2_ = * + 1
		sbc #$00
f_code_dec2_	dec <f_x2_
		bcs -
f_dx2_ = * + 1
		adc #$00
f_code_dec1_	dec <f_x2_
f_left2_
		sta <f_err2
		;if we would use and #$7e ora #$80 we would target speedcode with specidifc left position, regarding block and pixelpos (MC that is) -> so 4 times speedcode and mask is implicit given by code
		;same would work for right pixelpos
f_smc_x2_2 = * + 1
		lda <f_x2_
		arr #$78
;--------PATTERN SETUP and ---------------------------------
f_draw
		;either sta <f_jmp + 2 or sta <f_err2 will be set here, depending on f_left odr f_left_ is used
		sta <f_err2
		;sta <f_jmp_ + 2
f_pattern = * + 1
		lda #$00
f_ommit_eor
		eor #$00
		sta f_pattern
f_x2_ = * + 1
		and maskl			;XXX TODO have maskl available in all patterns and no need naymore for f_pattern? needs $0c00 extra memory
;mask		lda #$00			;XXX TODO could have and #$00 as mask in steep cases and use lsr/asl, easy in steep case, but need to derive mask from x in flat case? bad if not indexed?
f_jmp_		jmp ($1000)			;do it! \o/
		;xxx todo, jmp to $8000,$8400 and so on, there do furtehr jump to $speedcode segment depending on x? asr #$f8 lsr lsr sta branch?
		;XXX TODO may use max 7 cycles + 2 for this method to win
		;		sta (clmx),y
		;		lda #$f8
		;		sax branch + 1
		;branch bne +
		;		jmp or directly enter codesegment
		;
;-------------------------------------------------------------
		;rewrite code and move and maskl + jmp 4 bytes up, lots of sta action and also need to rewrite all f_x2_ and f_jmp_ writes
;s1_a_b1


;		lda ttab1,x
;		sta f_jmp + 2			;select $8000/$8200/$8400 ... also okay to look up via table
;
;		lda <f_x2
;		arr #$78
;		sec
;		arr #$3c
;		sta f_jmp + 1
;		adc #clm0
;		sta f_first + 1
;
;f_pattern = * + 1
;		lda #$00
;f_pattern_eor = * + 1
;f_ommit_eor
;		eor #$00
;		sta f_pattern
;f_x2_ = * + 1
;		and maskl
;f_first	sta (clm0),y			;both need to be omitted if f_jmp + 1 = f_jmp + 2
;		lda <f_pattern
;f_jmp		jmp $8000

;		* = $8000
;		nop
;		nop
;		sta (clm1),y
;		sta (clm2),y
;		sta (clm3),y
;		sta (clm4),y
;		sta (clm5),y
;		sta (clm6),y
;		sta (clm7),y
;		sta (clm8),y
;		sta (clm9),y
;		sta (clma),y
;		sta (clmb),y
;		sta (clmc),y
;		sta (clmd),y
;		and maskr,x
;		ora (clme),y
;		sta (clme),y
;		jmp f_back





}
fill_end


;left: prerender vals, store in tab
;right: render vals, sraw span, store in tab

;example
;		branch upon y-check -> decide here if steep or flat
;		txa
;f_dy = * + 1
;		sbx #$00
;		bcs +
;		txa
;f_dx = * + 1
;		sbx #$00
;		inc/dec <f_x
;		bpl +
;		;fix f_x
;		inc jump lowbyte
;		jmp do_mask
;+


;example_flat
;		branch upon y-check -> decide here if steep or flat
;		txa
;-
;f_dy = * + 1
;		sbc #$00
;		inc/dec <f_x
;		bcs -
;		tax
;f_dx = * + 1
;		sbx #$00
;		;fix f_x
;		lda f_x
;		asr #$f8
;		lsr
;		lsr
;		sta f_jmp + 1
;do_mask
;f_x = * + 1	lda maskr
;		sta mask
;+
;just there to be copied to their final destinations @$8000-$bc00
targets
tgt_bank1
		!word s0_f_b1, s0_e_b1, s0_d_b1, s0_c_b1, s0_b_b1, s0_a_b1, s0_9_b1, s0_8_b1, s0_7_b1, s0_6_b1, s0_5_b1, s0_4_b1, s0_3_b1, s0_2_b1, s0_1_b1, s0_0_b1
		!word s1_f_b1, s1_e_b1, s1_d_b1, s1_c_b1, s1_b_b1, s1_a_b1, s1_9_b1, s1_8_b1, s1_7_b1, s1_6_b1, s1_5_b1, s1_4_b1, s1_3_b1, s1_2_b1, s1_1_b1, fail2
		!word s2_f_b1, s2_e_b1, s2_d_b1, s2_c_b1, s2_b_b1, s2_a_b1, s2_9_b1, s2_8_b1, s2_7_b1, s2_6_b1, s2_5_b1, s2_4_b1, s2_3_b1, s2_2_b1, fail2  , fail2
		!word s3_f_b1, s3_e_b1, s3_d_b1, s3_c_b1, s3_b_b1, s3_a_b1, s3_9_b1, s3_8_b1, s3_7_b1, s3_6_b1, s3_5_b1, s3_4_b1, s3_3_b1, fail2  , fail2  , fail2
		!word s4_f_b1, s4_e_b1, s4_d_b1, s4_c_b1, s4_b_b1, s4_a_b1, s4_9_b1, s4_8_b1, s4_7_b1, s4_6_b1, s4_5_b1, s4_4_b1, fail2  , fail2  , fail2  , fail2
		!word s5_f_b1, s5_e_b1, s5_d_b1, s5_c_b1, s5_b_b1, s5_a_b1, s5_9_b1, s5_8_b1, s5_7_b1, s5_6_b1, s5_5_b1, fail2  , fail2  , fail2  , fail2  , fail2
		!word s6_f_b1, s6_e_b1, s6_d_b1, s6_c_b1, s6_b_b1, s6_a_b1, s6_9_b1, s6_8_b1, s6_7_b1, s6_6_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2
		!word s7_f_b1, s7_e_b1, s7_d_b1, s7_c_b1, s7_b_b1, s7_a_b1, s7_9_b1, s7_8_b1, s7_7_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2
		!word s8_f_b1, s8_e_b1, s8_d_b1, s8_c_b1, s8_b_b1, s8_a_b1, s8_9_b1, s8_8_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2
		!word s9_f_b1, s9_e_b1, s9_d_b1, s9_c_b1, s9_b_b1, s9_a_b1, s9_9_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2
		!word sa_f_b1, sa_e_b1, sa_d_b1, sa_c_b1, sa_b_b1, sa_a_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2
		!word sb_f_b1, sb_e_b1, sb_d_b1, sb_c_b1, sb_b_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2
		!word sc_f_b1, sc_e_b1, sc_d_b1, sc_c_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2
		!word sd_f_b1, sd_e_b1, sd_d_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2
		!word se_f_b1, se_e_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2
		!word sf_f_b1, fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2  , fail2

						;XXX TODO fail2 is called on jmp ($b406) :-(
;copy a lot of stuff to there needed location and setup the filler code
setup_fill
		ldx #$00
		stx dst
		stx yscroll
		lda #$bc
		sta dst+1
-
		lda fill_start,x
		sta <fill_code,x
		inx
		cpx #fill_end-fill_start
		bne -

		;generate mask tables
		lxa #$00
-
!ifdef MULTI {
		sta maskr + 1,x		;use offset of 1, as xend has that offset as well
}
		sta maskr,x
		eor #$ff
		;sta maskr+$80,x
!ifdef MULTI {
		sta maskl + 1,x		;add offset of +$80 as it is added to xstart later on as well
}
		sta maskl,x
		lsr
!ifdef MULTI {
		lsr
}
		beq +
		eor #$ff
+
!ifdef MULTI {
		inx
}
		inx
		bpl -

		;copy target pointers for speed_code segments to fit memory layout ($20 pointers each $400 bytes from $c000 on)
		lda #<(tgt_bank1+$1e0)
		sta src
		lda #>(tgt_bank1+$1e0)
		sta src+1
next1
		ldy #$1f
-
		lda (src),y
		sta (dst),y
		dey
		bpl -

		lax src
		sbx #$20
		stx src
		bcs *+4
		dec src+1

		lax dst+1
		sbx #$04
		stx dst+1
		bmi next1
out

init
		lda #$7f
		sta trig
		rts

		!warn "setup code end: ",*

;-------------------------------------------------------------
;
; END OF VOLATILE SETUPCODE
;
;-------------------------------------------------------------

!macro from_ora .f {
	!if .f = 0 {
		ora (clm0),y
	}
	!if .f = 1 {
		ora (clm1),y
	}
	!if .f = 2 {
		ora (clm2),y
	}
	!if .f = 3 {
		ora (clm3),y
	}
	!if .f = 4 {
		ora (clm4),y
	}
	!if .f = 5 {
		ora (clm5),y
	}
	!if .f = 6 {
		ora (clm6),y
	}
	!if .f = 7 {
		ora (clm7),y
	}
	!if .f = 8 {
		ora (clm8),y
	}
	!if .f = 9 {
		ora (clm9),y
	}
	!if .f = 10 {
		ora (clma),y
	}
	!if .f = 11 {
		ora (clmb),y
	}
	!if .f = 12 {
		ora (clmc),y
	}
	!if .f = 13 {
		ora (clmd),y
	}
	!if .f = 14 {
		ora (clme),y
	}
}

!macro from_jmp .f {
	!if .f = $0 {
		jmp f_back_0
	}
	!if .f = $1 {
		jmp f_back_1
	}
	!if .f = $2 {
		jmp f_back_2
	}
	!if .f = $3 {
		jmp f_back_3
	}
	!if .f = $4 {
		jmp f_back_4
	}
	!if .f = $5 {
		jmp f_back_5
	}
	!if .f = $6 {
		jmp f_back_6
	}
	!if .f = $7 {
		jmp f_back_7
	}
	!if .f = $8 {
		jmp f_back_8
	}
	!if .f = $9 {
		jmp f_back_9
	}
	!if .f = $a {
		jmp f_back_a
	}
	!if .f = $b {
		jmp f_back_b
	}
	!if .f = $c {
		jmp f_back_c
	}
}

!macro from_sta .f {
	!if .f = 0 {
		sta (clm0),y
	}
	!if .f = 1 {
		sta (clm1),y
	}
	!if .f = 2 {
		sta (clm2),y
	}
	!if .f = 3 {
		sta (clm3),y
	}
	!if .f = 4 {
		sta (clm4),y
	}
	!if .f = 5 {
		sta (clm5),y
	}
	!if .f 	= 6 {
		sta (clm6),y
	}
	!if .f = 7 {
		sta (clm7),y
	}
	!if .f = 8 {
		sta (clm8),y
	}
	!if .f = 9 {
		sta (clm9),y
	}
	!if .f = 10 {
		sta (clma),y
	}
	!if .f = 11 {
		sta (clmb),y
	}
	!if .f = 12 {
		sta (clmc),y
	}
	!if .f = 13 {
		sta (clmd),y
	}
	!if .f = 14 {
		sta (clme),y
	}
}

;XXX TODO autogen all this, including table, table then only shows what pointers are valid and which should point to fail?
!macro span_code .from, .to {
			;draw left side and reload pattern if needed
	!if .from < $0f and .from < .to {
			+from_sta .from
			!set .from = .from + 1
		!if .from < $0f {
			lda <f_pattern
		}
	}
	!if .to = $0c {
			;use code in ZP
			+from_jmp .from
	} else {
			;generate speedcode segment
		!while (.from < $0f and .from < .to) {
			+from_sta .from
			!set .from = .from + 1
		}
		!if .from < $0f {
			;and final byte with mask
			and maskr,x
			beq +
			+from_ora .from
			+from_sta .from
+
		}
			jmp f_back
	}
}

;!macro norm .start, .num {
;		;left chunck
;		;can be savely removed if faces are drawn from left to right?
;		;ora .addr,y
;!if .start < $0f {
;		sta (clm0 + .start * 2),y
;}
;		!set .start = .start + 1
;
;	!if .start < $0f {
;		lda <f_pattern;(f_pattern),y
;	}
;!if .num > 0 {
;	!for .x, 1, .num {
;	!if .start < $0f {
;		sta (clm0 + .start * 2),y
;	}
;		!set .start = .start + 1
;	}
;}
;		;can be omitted on outer edge, basically, if we could just distinct and would have ram
;		;right chunk
;	!if .start < $0f {
;		and maskr,x
;		ora (clm0 + .start * 2),y
;		sta (clm0 + .start * 2),y
;	}
;		jmp f_back
;}


;--------------------------
;MAINCODE
;
;--------------------------

		* = tab1
bra_clr_tab
		!byte $00 * 3 + 1
		!byte $01 * 3 + 1
		!byte $02 * 3 + 1
		!byte $03 * 3 + 1
		!byte $04 * 3 + 1
		!byte $05 * 3 + 1
		!byte $06 * 3 + 1
		!byte $07 * 3 + 1
		!byte $08 * 3 + 1
		!byte $09 * 3 + 1
		!byte $0a * 3 + 1
		!byte $0b * 3 + 1
		!byte $0c * 3 + 1
		!byte $0d * 3 + 1
		!byte $0e * 3 + 1
		!byte $0f * 3 + 1
bra_set_tab
		!byte $00 * 5 + 1
		!byte $01 * 5 + 1
		!byte $02 * 5 + 1
		!byte $03 * 5 + 1
		!byte $04 * 5 + 1
		!byte $05 * 5 + 1
		!byte $06 * 5 + 1
		!byte $07 * 5 + 1
		!byte $08 * 5 + 1
		!byte $09 * 5 + 1
		!byte $0a * 5 + 1
		!byte $0b * 5 + 1
		!byte $0c * 5 + 1
		!byte $0d * 5 + 1
		!byte $0e * 5 + 1
		!byte $0f * 5 + 1
scr_tab
                !byte $00,$28,$50,$78,$a0,$c8
                !byte $00,$28,$50,$78,$a0,$c8

sa_e_b1
		+span_code 10, 14
sa_f_b1
		+span_code 10, 15

sb_b_b1
		+span_code 11, 11
sb_c_b1
		+span_code 11, 12
sb_d_b1
		+span_code 11, 13
sb_e_b1
		+span_code 11, 14
sb_f_b1
		+span_code 11, 15


sc_c_b1
		+span_code 12, 12
sc_d_b1
		+span_code 12, 13
sc_e_b1
		+span_code 12, 14
s0_0_b1
		+span_code 0, 0

!align 255,0
maskl
		!fill 128,$0
maskr
		!fill 128,$0

!align 255,0
row_to_ptr1
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0
		!byte (>sprites1) + 0

		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2
		!byte (>sprites1) + 2

		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4
		!byte (>sprites1) + 4

		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6
		!byte (>sprites1) + 6

		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8
		!byte (>sprites1) + 8

		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10
		!byte (>sprites1) + 10

row_to_y
		!byte $00,$03,$06,$09,$0c,$0f,$12,$15,$18,$1b,$1e,$21,$24,$27,$2a,$2d,$30,$33,$36,$39,$3c
		!byte $00,$03,$06,$09,$0c,$0f,$12,$15,$18,$1b,$1e,$21,$24,$27,$2a,$2d,$30,$33,$36,$39,$3c
		!byte $00,$03,$06,$09,$0c,$0f,$12,$15,$18,$1b,$1e,$21,$24,$27,$2a,$2d,$30,$33,$36,$39,$3c
		!byte $00,$03,$06,$09,$0c,$0f,$12,$15,$18,$1b,$1e,$21,$24,$27,$2a,$2d,$30,$33,$36,$39,$3c
		!byte $00,$03,$06,$09,$0c,$0f,$12,$15,$18,$1b,$1e,$21,$24,$27,$2a,$2d,$30,$33,$36,$39,$3c
		!byte $00,$03,$06,$09,$0c,$0f,$12,$15,$18,$1b,$1e,$21,$24,$27,$2a,$2d,$30,$33,$36,$39,$3c
!align 255,0
row_to_ptr2
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0
		!byte (>sprites2) + 0

		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2
		!byte (>sprites2) + 2

		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4
		!byte (>sprites2) + 4

		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6
		!byte (>sprites2) + 6

		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8
		!byte (>sprites2) + 8

		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
		!byte (>sprites2) + 10
!align 127,0
clear_line_tab
		!word clear_line_00
		!word clear_line_01
		!word clear_line_02
		!word clear_line_03
		!word clear_line_04
		!word clear_line_05
		!word clear_line_06
		!word clear_line_07
		!word clear_line_08
		!word clear_line_09
		!word clear_line_0a
		!word clear_line_0b
		!word clear_line_0c
		!word clear_line_0d
		!word clear_line_0e
		!word clear_line_0f
		!word clear_line_10
		!word clear_line_11
		!word clear_line_12
		!word clear_line_13
		!word clear_line_14
		!word clear_line_15
		!word clear_line_16
		!word clear_line_17
		!word clear_line_18
		!word clear_line_19

s9_f_b1
		+span_code 9, 15

sa_a_b1
		+span_code 10, 10
sa_b_b1
		+span_code 10, 11
sa_c_b1
		+span_code 10, 12
sa_d_b1
		+span_code 10, 13


		* = tab2
ttab_b1
!for .y,15,0 {
	!for .x,0,7 {
		!byte (.y & $f) * 2
	}
}
cval_tab
		!byte $21
		!byte $31
		!byte $41
		!byte $51
		!byte $61
		!byte $71
		!byte $81
		!byte $91
		!byte $a1
		!byte $b1
		!byte $c1
		!byte $d1
		!byte $e1
		!byte $f1
		!byte $01
		!byte $11

sc_f_b1
		+span_code 12, 15

sd_d_b1
		+span_code 13, 13
sd_e_b1
		+span_code 13, 14
sd_f_b1
		+span_code 13, 15

se_e_b1
		+span_code 14, 14
se_f_b1
		+span_code 14, 15

sf_f_b1
		+span_code 15, 15


!align 255,0
set_line_tab
		!word set_line_00
		!word set_line_01
		!word set_line_02
		!word set_line_03
		!word set_line_04
		!word set_line_05
		!word set_line_06
		!word set_line_07
		!word set_line_08
		!word set_line_09
		!word set_line_0a
		!word set_line_0b
		!word set_line_0c
		!word set_line_0d
		!word set_line_0e
		!word set_line_0f
		!word set_line_10
		!word set_line_11
		!word set_line_12
		!word set_line_13
		!word set_line_14
		!word set_line_15
		!word set_line_16
		!word set_line_17
		!word set_line_18
		!word set_line_19
clearcode

		* = code
spancode
;speedcode chunks that are jumped to from inner loop
s0_1_b1
		+span_code 0, 1
s0_2_b1
		+span_code 0, 2
s0_3_b1
		+span_code 0, 3
s0_4_b1
		+span_code 0, 4
s0_5_b1
		+span_code 0, 5
s0_6_b1
		+span_code 0, 6
s0_7_b1
		+span_code 0, 7
s0_8_b1
		+span_code 0, 8
s0_9_b1
		+span_code 0, 9
s0_a_b1
		+span_code 0, 10
s0_b_b1
		+span_code 0, 11
s0_c_b1
		+span_code 0, 12
s0_d_b1
		+span_code 0, 13
s0_e_b1
		+span_code 0, 14
s0_f_b1
		+span_code 0, 15


s1_1_b1
		+span_code 1, 1
s1_2_b1
		+span_code 1, 2
s1_3_b1
		+span_code 1, 3
s1_4_b1
		+span_code 1, 4
s1_5_b1
		+span_code 1, 5
s1_6_b1
		+span_code 1, 6
s1_7_b1
		+span_code 1, 7
s1_8_b1
		+span_code 1, 8
s1_9_b1
		+span_code 1, 9
s1_a_b1
		+span_code 1, 10
s1_b_b1
		+span_code 1, 11
s1_c_b1
		+span_code 1, 12
s1_d_b1
		+span_code 1, 13
s1_e_b1
		+span_code 1, 14
s1_f_b1
		+span_code 1, 15


s2_2_b1
		+span_code 2, 2
s2_3_b1
		+span_code 2, 3
s2_4_b1
		+span_code 2, 4
s2_5_b1
		+span_code 2, 5
s2_6_b1
		+span_code 2, 6
s2_7_b1
		+span_code 2, 7
s2_8_b1
		+span_code 2, 8
s2_9_b1
		+span_code 2, 9
s2_a_b1
		+span_code 2, 10
s2_b_b1
		+span_code 2, 11
s2_c_b1
		+span_code 2, 12
s2_d_b1
		+span_code 2, 13
s2_e_b1
		+span_code 2, 14
s2_f_b1
		+span_code 2, 15


s3_3_b1
		+span_code 3, 3
s3_4_b1
		+span_code 3, 4
s3_5_b1
		+span_code 3, 5
s3_6_b1
		+span_code 3, 6
s3_7_b1
		+span_code 3, 7
s3_8_b1
		+span_code 3, 8
s3_9_b1
		+span_code 3, 9
s3_a_b1
		+span_code 3, 10
s3_b_b1
		+span_code 3, 11
s3_c_b1
		+span_code 3, 12
s3_d_b1
		+span_code 3, 13
s3_e_b1
		+span_code 3, 14
s3_f_b1
		+span_code 3, 15


s4_4_b1
		+span_code 4, 4
s4_5_b1
		+span_code 4, 5
s4_6_b1
		+span_code 4, 6
s4_7_b1
		+span_code 4, 7
s4_8_b1
		+span_code 4, 8
s4_9_b1
		+span_code 4, 9
s4_a_b1
		+span_code 4, 10
s4_b_b1
		+span_code 4, 11
s4_c_b1
		+span_code 4, 12
s4_d_b1
		+span_code 4, 13
s4_e_b1
		+span_code 4, 14
s4_f_b1
		+span_code 4, 15


s5_5_b1
		+span_code 5, 5
s5_6_b1
		+span_code 5, 6
s5_7_b1
		+span_code 5, 7
s5_8_b1
		+span_code 5, 8
s5_9_b1
		+span_code 5, 9
s5_a_b1
		+span_code 5, 10
s5_b_b1
		+span_code 5, 11
s5_c_b1
		+span_code 5, 12
s5_d_b1
		+span_code 5, 13
s5_e_b1
		+span_code 5, 14
s5_f_b1
		+span_code 5, 15


s6_6_b1
		+span_code 6, 6
s6_7_b1
		+span_code 6, 7
s6_8_b1
		+span_code 6, 8
s6_9_b1
		+span_code 6, 9
s6_a_b1
		+span_code 6, 10
s6_b_b1
		+span_code 6, 11
s6_c_b1
		+span_code 6, 12
s6_d_b1
		+span_code 6, 13
s6_e_b1
		+span_code 6, 14
s6_f_b1
		+span_code 6, 15


s7_7_b1
		+span_code 7, 7
s7_8_b1
		+span_code 7, 8
s7_9_b1
		+span_code 7, 9
s7_a_b1
		+span_code 7, 10
s7_b_b1
		+span_code 7, 11
s7_c_b1
		+span_code 7, 12
s7_d_b1
		+span_code 7, 13
s7_e_b1
		+span_code 7, 14
s7_f_b1
		+span_code 7, 15


s8_8_b1
		+span_code 8, 8
s8_9_b1
		+span_code 8, 9
s8_a_b1
		+span_code 8, 10
s8_b_b1
		+span_code 8, 11
s8_c_b1
		+span_code 8, 12
s8_d_b1
		+span_code 8, 13
s8_e_b1
		+span_code 8, 14
s8_f_b1
		+span_code 8, 15


s9_9_b1
		+span_code 9, 9
s9_a_b1
		+span_code 9, 10
s9_b_b1
		+span_code 9, 11
s9_c_b1
		+span_code 9, 12
s9_d_b1
		+span_code 9, 13
s9_e_b1
		+span_code 9, 14



!warn "spancode size: ", * - spancode
!warn "spancode pos: ", spancode
main
		;clear doublebuffer (init code was there)
-
.b1		sta charset1,x
		dex
		bne -
		inc .b1+2
		dey
		bne -

!ifndef DEBUG {
		;dec $01
		jsr render_frame2
		jsr render_frame1
		lda #$00
		jsr clearcode
		;inc $01
}
		jsr vblank

		;now start with interrupts
		dec $d019

.setup_next_obj
		jsr reset_data_ptr
		jsr reset_move_ptr

		lda .col_bg_new + 1
		sta .col_bg_old + 1
		lda data_bg_col
		sta .col_bg_new + 1
		lda #$31
		sta .col_bg_pos + 1

		lda data_platecol + 0
		sta .platecol1 + 1
		lda data_platecol + 1
		sta .platecol2 + 1
		lda data_platecol + 2
		sta .platecol3 + 1

		lda data_plate_x
		sta .plate_x + 1
		ldy data_plate_num
		sty .plate_5 + 1
		iny
		sty .plate_6 + 1
		iny
		sty .plate_7 + 1
		tya
		clc
		adc #6
		tay
		sty .plate_0 + 1
		iny
		sty .plate_1 + 1
		iny
		sty .plate_2 + 1
		tya
		adc #6
		tay
		sty .plate_3 + 1
		iny
		sty .plate_4 + 1

		lda data_chr_cols + 1
		sta $d023
		lda data_chr_cols + 2
		sta $d022

		lda data_spr_cols + 2
		sta .spcol3 + 1
		lda data_spr_cols + 1
		sta .spcol2 + 1
		lda data_spr_cols + 0
		sta .spcol1 + 1

		lda data_chr_cols + 0
		ora #$08
		ldx #$00
-
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		dex
		bne -

		;dec $01
		dec .load_it + 1
		cli
chk_obj
.load_it	lda #$01
		beq chk_obj

		inc .nextfile + 1
		ldx .nextfile + 1
		cpx #$04
		bne +
		ldx #0
		lda #$ff
-
		sta $7c00,x
		sta $7d00,x
		sta $7e00,x
		sta $7ef8,x
		dex
		bpl -
		lda #(($7c00 & $3f00) / $40) + (($7800 & $3fff) / $400); xor 2
		sta $d018
+

!ifdef release {
		jsr link_load_next_comp
}
-
		lda .col_bg_pos + 1
		clc
		adc #$04
		bcc -
.nextfile	ldx #$ff
		cpx #$04
		beq .end
		jmp .setup_next_obj
.end
!ifdef release {
		sei
		lda #$00
		sta $d021
;		ldx #$00
;-
;		lda stackcode,x
;		sta $0100,x
;		inx
;		cpx #stackcode_end-stackcode
;		bne -
;		jmp $0100
		jmp link_exit
} else {
	!ifndef DEBUG {
		jmp *

		} else {

-		inc $1080,x
		inx
		beq +
+		bne +
+		lda $1000
		dec $1000
		sta $1100,x
		nop
		lda $1000,x
		bit $00
		jmp -
	}
}

reset_move_ptr
		ldx #11
-		lda data_init,x
		sta bal,x
		dex
		bpl -
		rts
!warn "rendercode start: ",*

reset_data_ptr
		lda #<rot_data
		sta data
		lda #>rot_data
		sta data + 1
		rts

clear2		jsr $0000
.second_frame
		jsr render_skip_setup1
render_frame2
		lda #$10		;bpl
		sta update_edge_jmp

		lda #$80
		sta <clm1
		sta <clm3
		sta <clm5
		sta <clm7
		sta <clm9
		sta <clmb
		sta <clmd
		;sta <clmf
		asl			;lda #0, sec
		;sta <clm0
		sta <clm2
		sta <clm4
		sta <clm6
		sta <clm8
		sta <clma
		;sta <clmc
		sta <clme

		lda #$d0
		sta <f_dispatch + 0
		lda #$02
		sta <f_dispatch + 1
		lda #$f0
		sta <f_dispatch + 2
		lda #<(f_end_c - (f_dispatch + 2) - 2)
		sta <f_dispatch + 3

render_skip_setup2
cset_bank = * + 1
		lda #(>charset1) + 1
		ldx #$fe
		sax <clm0 + 1
		sax <clm1 + 1
		sta <clm2 + 1
		sta <clm3 + 1
		adc #$01
		sax <clm4 + 1
		sax <clm5 + 1
		sta <clm6 + 1
		sta <clm7 + 1
		adc #$02
		sax <clm8 + 1
		sax <clm9 + 1
		sta <clma + 1
		sta <clmb + 1
		adc #$02
		sax <clmc + 1
		sax <clmd + 1
		sta <clme + 1
		;sta <clmf + 1
		and #$f9
		eor #$08
		sta cset_bank

		ldy #$00
		;XXX TODO setup code here
		;and back_pointer
		;and set target pointers here

		;set data here according to pointer table
next_face_c
		;XXX TODO depending on xmin/max: only update what is necessary -> been there, seen that, turned out to be slower due to expensive setup
		;fetch last vertice - will be stored in drawface, if necessary

		;faces are already presorted, so the first vertice is the one with highest y position (by value)
		jsr next_face		;sets x

		sty <f_ynext
		ldy <verticebuf_y
		jmp fill

do_render
clear
		lda #$00
		ldy bank_1 + 2
		cpy #>row_to_ptr1
		bne clear2

clear1		jsr $0000
.first_frame
		jsr render_skip_setup2
render_frame1
		lda #$8f
		ldx #$40
		stx <clm3	;40
		;stx <clmf	;40
		;sax <clm0	;00		;always zero, for sprite as well as for chars
		;sax <clmc	;00
		inx
		stx <clm4	;41
		sax <clm1	;01
		sax <clmd	;01
		inx
		stx <clm5	;42
		sax <clm2	;02
		sax <clme	;02
		ldx #$c0
		stx <clm9	;c0
		sax <clm6	;80
		sax update_edge_jmp		;opcode for dop
		inx
		stx <clma	;c1
		sax <clm7	;81
		inx
		stx <clmb	;c2
		sax <clm8	;82

		lda #$f0
		sta <f_dispatch + 0
		lda #<(f_inc - f_dispatch - 2)
		sta <f_dispatch + 1
		lda #$88
		sta <f_dispatch + 2
		sta <f_dispatch + 3

render_skip_setup1
		ldy #$00
next_face_s
		;XXX TODO depending on xmin/max: only update what is necessary -> been there, seen that, turned out to be slower due to expensive setup
		;fetch last vertice - will be stored in drawface, if necessary

		;faces are already presorted, so the first vertice is the one with highest y position (by value)
		jsr next_face		;sets x

		sty <f_yend
bank_1		lda row_to_ptr1,y
		sta <sprhi
		lda row_to_y,y
		sta <sprlo
		sta <f_ynext

		;setup start position
		ldy <verticebuf_y
bank_4		lda row_to_ptr1,y

		sta <clm0 + 1
		sta <clm1 + 1
		sta <clm2 + 1

		sta <clm3 + 1
		sta <clm4 + 1
		sta <clm5 + 1

		sta <clm6 + 1
		sta <clm7 + 1
		sta <clm8 + 1

		sta <clm9 + 1
		sta <clma + 1
		sta <clmb + 1
		clc
		adc #1
		sta <clmc + 1
		sta <clmd + 1
		sta <clme + 1

		sbc <sprhi		;end in same spriterow?
		beq +
		lda #$00		;more than one row, and do f_inc
		sta <f_ynext		;f_ynext is either $00 or sprlo, depending on if we do one spriterow or more
+
		;sta <clmf + 1

		lda row_to_y,y
		tay
		jmp fill
		;no update needed, next face


!macro update_left .y, ~.smc_x2_1, ~.smc_x2_2, ~.jmp {
		lda <verticebuf_y + .y			;l_ynext = y1; dy = -y1 + y2
		sta <l_ynext
		eor #$ff
		adc <verticebuf_y + ((1 + .y) % 3)
		sta <f_dx2
		sta <f_dy2_
		sta <f_dy2

		;calc dx
		;sec					;always set
		lda <verticebuf_x + ((1 + .y) % 3)
.smc_x2_1 = * + 1
		sta <f_x2_
		sbc <verticebuf_x + .y
		bcc .plus				;dx is negative?
.minus
		ldy #$c6				;dex
		bne +
.plus
		ldy #$e6				;inx

		eor #$ff				;yes, do an abs(dx)
		adc #$01
+
		sty <f_code_dec
		cmp <f_dx2				;compare dx with previously saved dy (steep/flat slope decision)
		;beq .steep
		bcc .steep
.flat
		sty <f_code_dec1_
		sty <f_code_dec2_
		sta <f_dx2_
		sta <f_dx2
		ldy <f_smc_jmp_2
		sty <f_draw + 1
		;also need to adapt branch in case x1 is steep
		lda #<f_left_ - f_code_bcs3 - 2		;adopt f_code_bcs* accordingly
		ldy #<f_left2_ - f_code_bcs4 - 2
		bne .merge
.steep
		sta <f_dy2

		lda #$07
		sta <f_nv
		and <verticebuf_x + ((1 + .y) % 3)
		cpy #$c6				;does our sec for free too
		beq +
		ora #$78
		ldy #$78
		sty <f_nv
		ldy #$fc
		top
+
		ldy #$04
.smc_x2_2 = * + 1
		sta <f_x2_
		sty <f_jmod

		lda <verticebuf_x + ((1 + .y) % 3)
		;sec
                arr #$78
.jmp = * + 1
		sta <f_jmp_ + 2				;setup jump initially, as it is not updated on every loop run, but only on changes in x direction

		ldy #f_err2
		sty <f_draw + 1
		;setup err, dy, dx
		lda #<f_draw - f_code_bcs3 - 2		;adopt f_code_bcs* accordingly
		ldy #<f_draw - f_code_bcs4 - 2
.merge
		sta <f_code_bcs3 + 1
		sty <f_code_bcs4 + 1
		lda <f_dx2
		lsr
		sta <f_err2
.merge_skip
}

;/!\ need to preserve x during update
!macro update_right .y, ~.jmp {
		lda <verticebuf_y + 1 +.y
		sta <r_ynext
		eor #$ff
		adc <verticebuf_y + .y
		sta <f_dx
		sta <f_dy_
		sta <f_dy

		;calc dx
		lax <verticebuf_x + .y			;new f_x
		sbc <verticebuf_x + 1 +.y
		bcc .plus				;dx is negative?
.minus
		ldy #$ca				;dex
		bne +
.plus
		ldy #$e8				;inx

		eor #$ff				;yes, do an abs(dx)
		adc #$01
+
		sty <f_code_dex
		cmp <f_dx				;compare dx with previously saved dy (steep/flat slope decision)
		;beq .steep				;on even, prefer steep case too
		bcc .steep
.flat
		sty <f_code_dex1_
		sty <f_code_dex2_
		sta <f_dx_
		sta <f_dx
		lda <f_smc_jmp_4
		sta <f_left + 1
		lda #<f_right_ - f_code_bcs1 - 2
		ldy #<f_right2_ - f_code_bcs2 - 2
		bne .merge
.steep
		;setup err, dy, dx			;swap dx/dy
		sta <f_dy
		lda ttab_b1,x				;setup jmp initially
.jmp = * + 1
		sta <f_jmp_ + 1
		lda #$07
		sbx #0
		cpy #$e8
		bne +
		sbx #-$78
		lda #$78
		ldy #$c6
		top
+
		ldy #$e6
		sta <f_nvr
		sty <f_jmodr1
		sty <f_jmodr2

		lda #<f_err
		sta <f_left + 1
		lda #<f_left - f_code_bcs1 - 2		;adopt f_code_bcs* accordingly
		ldy #<f_left - f_code_bcs2 - 2
.merge
		sta <f_code_bcs1 + 1
		sty <f_code_bcs2 + 1
		lda <f_dx
		lsr
		sta <f_err
}

update_edge_
		cpy <l_ynext
		beq no_update_right
right_
		+update_right 1, ~smc_jmp1_1
		;set initial jump
		;next halt is last halt
		lda <l_ynext
		bpl update_edge_jmp			;BRA
no_update_right
		cpy <r_ynext
		bne left_				;update left
face_done
		ldy <data_y
		bit update_edge_jmp
		bpl +
		jmp next_face_s
+
		jmp next_face_c
left_
		;sec
		+update_left 1, ~smc_x2_1, ~smc_x2_2, ~smc_jmp2_1
		lda <r_ynext
update_edge_jmp
		bpl +					;will be changed to either dop or bpl
		sta <f_yend
		tay
bank_3		lda row_to_ptr1,y
		sta <sprhi
		cmp <clm0 + 1				;end in same spriterow?
		lda row_to_y,y
		sta <sprlo
		bcs +					;basically it is a beq, we either can have <= for the compared values, so bcs is the same condition, and z flag is destroyed by the previous lda, but c is still there
		lda #$00				;more than one row, and do f_inc
+
		ldy <f_ynext				;start from last y
		sta <f_ynext				;end with new y
		jmp f_back
end_frame
		anc #$7f				;clamp off bit 7, clear carry
		bit update_edge_jmp
		bpl +
		stx off_x_s
		sta off_y_s
		bmi ++
+
		stx off_x_c
		sta off_y_c
++
		iny
		lax (data),y				;prefetch next byte in stream and check on EoD
		tya
		adc <data
		sta <data
		bcc +
		inc <data + 1
+
		inx
		bne +					;x == $ff?
		lda #$01
		sta .load_it + 1
+
		pla					;break out from current loop
		pla
		rts
		;XXX TODO pull vertices from stream as needed (left/right) saves a lot of decision machinery? at least update_left/right can be totally generic then? flag for left/right: done to know what to load next from stream, with new face thus automatically two bytes per side are loaded
next_face
		lax (data),y
		iny
		lda (data),y
		bmi end_frame

		stx <verticebuf_y + 0
		sta <verticebuf_x + 0

		iny
		lda (data),y
		lsr
		sta <verticebuf_y + 1
		rol <f_pattern

		iny
		lda (data),y
		lsr
		sta <verticebuf_x + 1
		rol <f_pattern

		iny
		lda (data),y
		lsr
		sta <verticebuf_y + 2
		rol <f_pattern

		iny
		lda (data),y
		lsr
		sta <verticebuf_x + 2
		iny
		sty <data_y
		lda <f_pattern
		rol
		and #$0f
		tay
		lda data_pattl,y
		sta <f_pattern
		lda data_patth,y
		beq +
		sta <f_ommit_eor + 1
		bit <f_ommit_eor + 3
		bmi ++

		ldx #$2d
		stx <f_ommit_eor + 4
		lda #<f_pattern
		sta <f_ommit_eor + 3
		lda #$85
		sta <f_ommit_eor + 2

		ldx #$49
		lda #f_x2_
		ldy #f_jmp_ + 1
		jmp setup_short
+
		lda #$6c
		sta <f_ommit_eor + 3
		lda #>maskl
		sta <f_ommit_eor + 2

		ldx #$2d
		lda #f_x2_ - 4
		ldy #f_jmp_ + 1 - 4
setup_short
		stx <f_ommit_eor + 0
		sta smc_x2_1
		sta smc_x2_2
		sta smc_x2_1_
		sta smc_x2_2_
		sta <f_code_dec + 1
		sta <f_code_dec1_ + 1
		sta <f_code_dec2_ + 1
		sta <f_smc_x2_1
		sta <f_smc_x2_2

		sty smc_jmp1_1
		sty smc_jmp1_2
		sty <f_smc_jmp_4
		sty <f_smc_jmp_5

		iny
		sty smc_jmp2_1
		sty smc_jmp2_2
		sty <f_smc_jmp_2
		sty <f_smc_jmp_3
++
		sec
		+update_right 0, ~smc_jmp1_2
		sec
		+update_left 2, ~smc_x2_1_, ~smc_x2_2_, ~smc_jmp2_2
		;set initial jump

		;determine first halt, left or right?
		ldy <l_ynext
		cpy <r_ynext
		bcs +
		ldy <r_ynext
+
		rts

move_vector2
ytmpx		lda #$00
		asr #$0f
.xlo		ora #$00
		ror
		ror
		ror
.lastx
		cmp #$80		;check for block change in x
		beq .skip_x		;nope, skip whole setup for x
		sta .lastx + 1		;remember new value
		ldy #$00		;clear for later use
		sec
		sbc #3
		bpl .x_positive		;positive number, so if clipping happens, then on right side
.x_negative
		clc
		adc #$10		;positive again, so values range from $00 .. $0f, no and needed
		bcs +
		tya			;limit to 0 in all other cases
+
		tax			;remember
		eor #$0f
		tay			;Y = X eor $0f
		asl
		asl
		asl
		asl
		bcc .x_merge		;BRA as A was < $10 prior to shifting
.x_positive
		sbc #$18		;fully visible?
		bcc .x_positive_
		cmp #$0f
		bcc +
		lda #$0f
+
		tay			;save clipped A
		asr #$00		;A = 0, clear carry
.x_positive_
		adc #$28		;x = $28 ($00 + $28) or xpos + $10 (xpos - $18 + $28)
		tax
		lda #$00
.x_merge
		sta .initval + 1
		stx .xpos + 1
		sty .clip + 1
		inc .tgt + 1		;open up update gate
.skip_x
ytmpy		lda #$00		;highbyte and #$0f (actually $07 would suffice, but thanks to shifing first bit, this also works)
		asr #$0f		;shift first bit out
.ylo		ora #$00		;already masked lowbyte
		ror			;shift remaining bits in in left side
		ror
		ror			;XXX TODO carry would qualify for check on minus or plus, but can't be used after upcoming cmp :-(
.lasty					;check for block change in y
		cmp #$80
.tgt		beq .skip_y
		sta .lasty + 1
		ldy #$00		;init with 0 (startline)
		tax
		bpl .y_positive
.y_negative
		clc
		adc #$10
		bcs +
		tya
+					;limit, x = $00..$0f
		tax
		eor #$0f
		tay
		iny
		lda #$00
		bpl .y_merge		;BRA
.y_positive
		cmp #$19
		bcc .y_positive_
		lda #$19		;A is 19 max now, limited
.y_positive_
		ldx #$10		;it is enough to set numlines to max ($10), as we enter at right spot and end with drawing line 25 anyway, so all branches are taken
		asl			;shift by 2, as position in jumptable needs to be a multiple of 2
		;ldy #$00		;set startline to 0
.y_merge
		sta .set_line_entry + 1
		stx .numlines + 1
		sty .start_line + 1
		dop
.skip_y
		rts
		lda #.skip_y - .tgt - 2
		sta .tgt + 1

.numlines_c	ldx #$00
.xpos_c		ldy #$00
		jsr clear_grid

		;ldy xpos/8 and #$0f?
.clip		ldy #$00
.clip_c		cpy #$00
		bne .setup_bra
set_grid
		lda .set_line_entry + 1
		ora #<clear_line_tab
		sta .clear_line_entry + 1
		clc

.numlines	ldx #$00
		stx .numlines_c + 1
.xpos		ldy #$00
		sty .xpos_c + 1
.initval	lda #$00
.start_line	ora #$00
.set_line_entry
		jmp (set_line_tab)

.setup_bra
		sty .clip_c + 1
		lda bra_set_tab,y
		sta set_bra_line_00
		sta set_bra_line_01
		sta set_bra_line_02
		sta set_bra_line_03
		sta set_bra_line_04
		sta set_bra_line_05
		sta set_bra_line_06
		sta set_bra_line_07
		sta set_bra_line_08
		sta set_bra_line_09
		sta set_bra_line_10
		sta set_bra_line_11
		sta set_bra_line_12
		sta set_bra_line_13
		sta set_bra_line_14
		sta set_bra_line_15
		sta set_bra_line_16
		sta set_bra_line_17
		sta set_bra_line_18
		sta set_bra_line_19
		sta set_bra_line_20
		sta set_bra_line_21
		sta set_bra_line_22
		sta set_bra_line_23
		sta set_bra_line_24

		lda bra_clr_tab,y
		sta clr_bra_line_00
		sta clr_bra_line_01
		sta clr_bra_line_02
		sta clr_bra_line_03
		sta clr_bra_line_04
		sta clr_bra_line_05
		sta clr_bra_line_06
		sta clr_bra_line_07
		sta clr_bra_line_08
		sta clr_bra_line_09
		sta clr_bra_line_10
		sta clr_bra_line_11
		sta clr_bra_line_12
		sta clr_bra_line_13
		sta clr_bra_line_14
		sta clr_bra_line_15
		sta clr_bra_line_16
		sta clr_bra_line_17
		sta clr_bra_line_18
		sta clr_bra_line_19
		sta clr_bra_line_20
		sta clr_bra_line_21
		sta clr_bra_line_22
		sta clr_bra_line_23
		sta clr_bra_line_24
		lda cval_tab,y
		sta clipval		;setup width of grid
		jmp set_grid

clear_grid
		lda #$ff
.clear_line_entry
		jmp (clear_line_tab)

!macro set_screen .x, ~.branch {
		dex
.branch = * + 1
		bpl +
		rts
+
                sta screen + .x * 40 + $0 - $10, y
                adc #$10
                sta screen + .x * 40 + $1 - $10, y
                adc #$10
                sta screen + .x * 40 + $2 - $10, y
                adc #$10
                sta screen + .x * 40 + $3 - $10, y
                adc #$10
                sta screen + .x * 40 + $4 - $10, y
                adc #$10
                sta screen + .x * 40 + $5 - $10, y
                adc #$10
                sta screen + .x * 40 + $6 - $10, y
                adc #$10
                sta screen + .x * 40 + $7 - $10, y
                adc #$10
                sta screen + .x * 40 + $8 - $10, y
                adc #$10
                sta screen + .x * 40 + $9 - $10, y
                adc #$10
                sta screen + .x * 40 + $a - $10, y
                adc #$10
                sta screen + .x * 40 + $b - $10, y
                adc #$10
                sta screen + .x * 40 + $c - $10, y
                adc #$10
                sta screen + .x * 40 + $d - $10, y
                adc #$10
                sta screen + .x * 40 + $e - $10, y
!if .x != 24 {
		;set skipval here with adc skip_val $21 to $f1 and $11 for different widths
		adc <clipval
		clc
}
}

!macro clear_screen .x, ~.branch {
		dex
.branch = * + 1
		bpl +
		rts
+
                sta screen + .x * 40 + $0 - $10, y
                sta screen + .x * 40 + $1 - $10, y
                sta screen + .x * 40 + $2 - $10, y
                sta screen + .x * 40 + $3 - $10, y
                sta screen + .x * 40 + $4 - $10, y
                sta screen + .x * 40 + $5 - $10, y
                sta screen + .x * 40 + $6 - $10, y
                sta screen + .x * 40 + $7 - $10, y
                sta screen + .x * 40 + $8 - $10, y
                sta screen + .x * 40 + $9 - $10, y
                sta screen + .x * 40 + $a - $10, y
                sta screen + .x * 40 + $b - $10, y
                sta screen + .x * 40 + $c - $10, y
                sta screen + .x * 40 + $d - $10, y
                sta screen + .x * 40 + $e - $10, y
!if .x != 24 {
}
}

;0,28,50,78,a0,c8
;0,28,50,78,a0,c8
;0,28,50,78,a0,c8
;0,28,50,78,a0,c8
;0

;taby
;		!byte $00,$28,$50,$78,$a0,$c8
;		!byte $00,$28,$50,$78,$a0,$c8
;		!byte $00,$28,$50,$78,$a0,$c8
;		!byte $00,$28,$50,$78,$a0,$c8
;		!byte $00
;tabtgt
;		!byte <block0, <block0, <block0, <block0, <block0, <block0
;		!byte <block1, <block1, <block1, <block1, <block1, <block1
;		!byte <block2, <block2, <block2, <block2, <block2, <block2
;		!byte <block3, <block3, <block3, <block3, <block3, <block3
;		!byte <block4

;		taby + xoffset = xpos
;		endpos: set rts there, remove rts afterwards
;		lda tabtgt
;		sta blk1 + 1
;		sta blk2 + 1
;		sta blk3 + 1
;		sta blk4 + 1
;blk1
;		lda blockx,x
;		pha
;		lda #$60
;blk2
;		sta blockx,x
;blk3
;		jsr blockx
;		pla
;blk4
;		sta blockx,x

;block0
;		sta screen + $0000,y
;		sta screen + $0001,y
;		sta screen + $0002,y
;		sta screen + $0003,y
;		sta screen + $0004,y
;		sta screen + $0005,y
;		sta screen + $0006,y
;		sta screen + $0007,y
;		sta screen + $0008,y
;		sta screen + $0009,y
;		sta screen + $000a,y
;		sta screen + $000b,y
;		sta screen + $000c,y
;		sta screen + $000d,y
;		sta screen + $000e,y
;		sta screen + $000f,y
;		rts

;block1
;		sta screen + $00f0,y
;		sta screen + $00f1,y
;		sta screen + $00f2,y
;		sta screen + $00f3,y
;		sta screen + $00f4,y
;		sta screen + $00f5,y
;		sta screen + $00f6,y
;		sta screen + $00f7,y
;		sta screen + $00f8,y
;		sta screen + $00f9,y
;		sta screen + $00fa,y
;		sta screen + $00fb,y
;		sta screen + $00fc,y
;		sta screen + $00fd,y
;		sta screen + $00fe,y
;		sta screen + $00ff,y
;		rts

;block2
;		sta screen + $01e0,y
;		sta screen + $01e1,y
;		sta screen + $01e2,y
;		sta screen + $01e3,y
;		sta screen + $01e4,y
;		sta screen + $01e5,y
;		sta screen + $01e6,y
;		sta screen + $01e7,y
;		sta screen + $01e8,y
;		sta screen + $01e9,y
;		sta screen + $01ea,y
;		sta screen + $01eb,y
;		sta screen + $01ec,y
;		sta screen + $01ed,y
;		sta screen + $01ee,y
;		sta screen + $01ef,y
;		rts

;block3
;		sta screen + $02d0,y
;		sta screen + $02d1,y
;		sta screen + $02d2,y
;		sta screen + $02d3,y
;		sta screen + $02d4,y
;		sta screen + $02d5,y
;		sta screen + $02d6,y
;		sta screen + $02d7,y
;		sta screen + $02d8,y
;		sta screen + $02d9,y
;		sta screen + $02da,y
;		sta screen + $02db,y
;		sta screen + $02dc,y
;		sta screen + $02dd,y
;		sta screen + $02de,y
;		sta screen + $02df,y
;		rts

;block4
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		sta screen + $03c0,y
;		rts

;		sta screen +  0 * 40,y
;		sta screen +  1 * 40,y
;		sta screen +  2 * 40,y
;		sta screen +  3 * 40,y
;		sta screen +  4 * 40,y
;		sta screen +  5 * 40,y
;		sta screen +  6 * 40,y
;		sta screen +  7 * 40,y
;		sta screen +  8 * 40,y
;		sta screen +  9 * 40,y
;		sta screen + 10 * 40,y
;		sta screen + 11 * 40,y
;		sta screen + 12 * 40,y
;		sta screen + 13 * 40,y
;		sta screen + 14 * 40,y
;		sta screen + 15 * 40,y
;		sta screen + 16 * 40,y
;		sta screen + 17 * 40,y
;		sta screen + 18 * 40,y
;		sta screen + 19 * 40,y
;		sta screen + 20 * 40,y
;		sta screen + 21 * 40,y
;		sta screen + 22 * 40,y
;		sta screen + 23 * 40,y
;		sta screen + 24 * 40,y
;		rts


set_line_00
		+set_screen 0, ~set_bra_line_00
set_line_01
		+set_screen 1, ~set_bra_line_01
set_line_02
		+set_screen 2, ~set_bra_line_02
set_line_03
		+set_screen 3, ~set_bra_line_03
set_line_04
		+set_screen 4, ~set_bra_line_04
set_line_05
		+set_screen 5, ~set_bra_line_05
set_line_06
		+set_screen 6, ~set_bra_line_06
set_line_07
		+set_screen 7, ~set_bra_line_07
set_line_08
		+set_screen 8, ~set_bra_line_08
set_line_09
		+set_screen 9, ~set_bra_line_09
set_line_0a
		+set_screen 10, ~set_bra_line_10
set_line_0b
		+set_screen 11, ~set_bra_line_11
set_line_0c
		+set_screen 12, ~set_bra_line_12
set_line_0d
		+set_screen 13, ~set_bra_line_13
set_line_0e
		+set_screen 14, ~set_bra_line_14
set_line_0f
		+set_screen 15, ~set_bra_line_15
set_line_10
		+set_screen 16, ~set_bra_line_16
set_line_11
		+set_screen 17, ~set_bra_line_17
set_line_12
		+set_screen 18, ~set_bra_line_18
set_line_13
		+set_screen 19, ~set_bra_line_19
set_line_14
		+set_screen 20, ~set_bra_line_20
set_line_15
		+set_screen 21, ~set_bra_line_21
set_line_16
		+set_screen 22, ~set_bra_line_22
set_line_17
		+set_screen 23, ~set_bra_line_23
set_line_18
		+set_screen 24, ~set_bra_line_24
set_line_19
		rts

clear_line_00
		+clear_screen 0, ~clr_bra_line_00
clear_line_01
		+clear_screen 1, ~clr_bra_line_01
clear_line_02
		+clear_screen 2, ~clr_bra_line_02
clear_line_03
		+clear_screen 3, ~clr_bra_line_03
clear_line_04
		+clear_screen 4, ~clr_bra_line_04
clear_line_05
		+clear_screen 5, ~clr_bra_line_05
clear_line_06
		+clear_screen 6, ~clr_bra_line_06
clear_line_07
		+clear_screen 7, ~clr_bra_line_07
clear_line_08
		+clear_screen 8, ~clr_bra_line_08
clear_line_09
		+clear_screen 9, ~clr_bra_line_09
clear_line_0a
		+clear_screen 10, ~clr_bra_line_10
clear_line_0b
		+clear_screen 11, ~clr_bra_line_11
clear_line_0c
		+clear_screen 12, ~clr_bra_line_12
clear_line_0d
		+clear_screen 13, ~clr_bra_line_13
clear_line_0e
		+clear_screen 14, ~clr_bra_line_14
clear_line_0f
		+clear_screen 15, ~clr_bra_line_15
clear_line_10
		+clear_screen 16, ~clr_bra_line_16
clear_line_11
		+clear_screen 17, ~clr_bra_line_17
clear_line_12
		+clear_screen 18, ~clr_bra_line_18
clear_line_13
		+clear_screen 19, ~clr_bra_line_19
clear_line_14
		+clear_screen 20, ~clr_bra_line_20
clear_line_15
		+clear_screen 21, ~clr_bra_line_21
clear_line_16
		+clear_screen 22, ~clr_bra_line_22
clear_line_17
		+clear_screen 23, ~clr_bra_line_23
clear_line_18
		+clear_screen 24, ~clr_bra_line_24
clear_line_19
		rts


;!ifdef release {
;stackcode
;		sei
;		lda #$35
;		sta $01
;		jsr link_load_next_comp
;		jmp link_exit
;stackcode_end
;}



!warn "code + tabs from ", code, " to ", *
!ifdef release {
			;!src "data1.asm"
} else {
			!src "data1.asm"
}
!warn "data from ", data_init, " to ", *

;------------------------------------------------------------------------------
;gfxdata
;------------------------------------------------------------------------------

!ifdef DEBUG {
			*= sprites1
			!bin "gfx/test5x5_v3.spr",5*64,0
			*= sprites1+$200
			!bin "gfx/test5x5_v3.spr",5*64,5*64
			*= sprites1+$400
			!bin "gfx/test5x5_v3.spr",5*64,5*64*2
			*= sprites1+$600
			!bin "gfx/test5x5_v3.spr",5*64,5*64*3
			*= sprites1+$800
			!bin "gfx/test5x5_v3.spr",5*64,5*64*4
			*= sprites1+$a00
			!bin "gfx/test5x5_v3.spr",5*64,5*64*5

			*= sprites2
			!bin "gfx/test5x5_v3.spr",5*64,0
			*= sprites2+$200
			!bin "gfx/test5x5_v3.spr",5*64,5*64
			*= sprites2+$400
			!bin "gfx/test5x5_v3.spr",5*64,5*64*2
			*= sprites2+$600
			!bin "gfx/test5x5_v3.spr",5*64,5*64*3
			*= sprites2+$800
			!bin "gfx/test5x5_v3.spr",5*64,5*64*4
			*= sprites2+$a00
			!bin "gfx/test5x5_v3.spr",5*64,5*64*5

			} else {

			*= platebg0
			!bin "gfx/plate_base_20faces.spr",3*64,0
			*= platefg0a
			!bin "gfx/plate_overlay_20faces.spr",3*64,0
			*= platefg0b
			!bin "gfx/plate_overlay_20faces.spr",2*64,3*64

			*= platebg1
			!bin "gfx/plate_base_arschlochdither.spr",3*64,0
			*= platefg1a
			!bin "gfx/plate_overlay_arschlochdither.spr",3*64,0
			*= platefg1b
			!bin "gfx/plate_overlay_arschlochdither.spr",2*64,3*64

			*= platebg2
			!bin "gfx/plate_base_worlddomination.spr",3*64,0
			*= platefg2a
			!bin "gfx/plate_overlay_worlddomination.spr",3*64,0
			*= platefg2b
			!bin "gfx/plate_overlay_worlddomination.spr",2*64,3*64

			*= platebg3
			!bin "gfx/plate_base_performers.spr",3*64,0
			*= platefg3a
			!bin "gfx/plate_overlay_performers.spr",3*64,0
			*= platefg3b
			!bin "gfx/plate_overlay_performers.spr",2*64,3*64
}

			* = screen
!fill $0400,$ff
