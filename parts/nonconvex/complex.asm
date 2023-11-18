;TODO:	- if we find the time, replace macros (GENLERP, ROTPOINT, CULLFACE, CALCEDGESTEP, DOTRI) with codegen and show multiple objects

!cpu 6510

;main
screen1			= $0400 ;$0400
!ifndef release {
music			= $1000 ;$1800
} else {
music			= $0800 ;$1800
}
charset1		= $2000	;$0800
charset2		= $2800 ;$0800
initcode		= $2c00 ;$0400
xbits1inv		= $3000	;$0100
sprites1		= $3100	;$0180
logobitmap		= $3400	;$0b40
sprites2		= $3f40	;$00c0
maincode		= $4000	;$1c00
skiptab			= $6000 ;$0100
negtab			= $6100 ;$0100
lsr3tab			= $6200	;$0100
xbits2inv		= $6300	;$0100
rezitab			= $6400	;$0200
rezilo			= rezitab+$0000 
rezihi			= rezitab+$0100
movesin			= $6600	;$0200
persptab		= $6800	;$0100
logoscreen		= $6900 ;$0168
logocolram		= $6a80 ;$0168
sintab			= $6c00	;$0400
sinlo			= sintab+$0000
coslo			= sintab+$0040
sinhi			= sintab+$0200
coshi			= sintab+$0240
multabs 		= $7000	;$0800
multablo 		= multabs+$0000
multabhi 		= multabs+$0200
multab2lo 		= multabs+$0400
multab2hi 		= multabs+$0600
lerptab			= $8000	;$0800
fillcode		= $8800	;$3200
clearcode1		= $ba00	;$128e
scrollxoff		= $ccf4
frame			= $ccf5	;16 bit
fps				= $ccf7
rx				= $ccf8
ry				= $ccf9
rz				= $ccfa
incx			= $ccfb
incy			= $ccfc
incz			= $ccfd

clearcode2		= $cd00	;$1300
colram			= $d800 ;$0400
xhis11			= $e000	;$0080
xhis12			= $e100	;$0080
xlos1			= $e200	;$0080
xbits1			= $e300	;$0100
xbits2			= $e400	;$0100
upshifttab		= $e700	;$0200
upshiftlos		= upshifttab+$0000
upshifthis1		= upshifttab+$0100
;upshifthis2		= upshifttab+$0200
coltab			= $e900	;$0600
fillpois		= $ef00	;$1000
posx			= $42	;$0010	interleaved with mat
posy			= $a2	;$0010  interleaved with mat
culls			= $52	;$0010	shared with mat
edgelos			= $62	;$0020	shared with mat
edgehis			= $82	;$0020	shared with mat

regsave		= $02	;4 bytes
page		= $06
tmp20		= $07
scrollxspd	= $08
pagejmplo	= $09
zoff		= $0a
scrolllo	= $0b
scrollhi	= $0c
oldscrollhi	= $0d
x1lo		= $0e
x2lo		= $0f
tmp1		= $10	;16 bit
tmp7		= $11
tmp2		= $12	;16 bit
tmp8		= $13
tmp3		= $14	;16 bit
tmp9		= $15
tmp4		= $16	;16 bit
tmp10		= $17
tmp5		= $18	;16 bit
tmp11		= $19
tmp6		= $1a	;16 bit
tmp12		= $1b
tmp13		= $1c
tmp14		= $1d
tmp15		= $1e
tmp16		= $1f
tmp17		= $20
tmp18		= $21
tmp19		= $22
sprxoff		= $23	;16 bit
mathzp		= $25 	;8 bytes
polyposidxs	= $2d	;4 bytes
polyedgeidxs= $31	;4 bytes
scrpoi		= $35	;16 bit
irqframe	= $37	;16 bit
mat			= $39	;$90 bytes
zp_code		= $c9	;$2a bytes

col0		= $02
col3		= $0d
col2		= $03
col1		= $05
sprcol3		= $01
barcol0 	= $01
barcol1 	= $01
barcol2 	= $01
logocol		= $0a
bordercol 	= $09

endframe	= $0600

!ifdef release {
                !src "../../bitfire/loader/loader_acme.inc"
                !src "../../bitfire/macros/link_macros_acme.inc"
}

*=maincode

part:

!zone init {

!ifndef release {
		sei
		lda #$35
		sta $01
	
		lda #$0b
		sta $d011
		
		lda #0
		tax
		tay
		jsr music+0
}
		
!ifndef release {
		ldx #0
inl1:		
		lda logocolram+$0000,x
		sta colram+$0280,x
		lda logocolram+$0068,x
		sta colram+$02e8,x
		lda logoscreen+$0000,x
		sta screen1+$0280,x
		lda logoscreen+$0068,x
		sta screen1+$02e8,x
		inx
		bne inl1
}
		jsr vsync		
		jsr initirq

		lda #0
		sta frame
		sta frame+1
		sta irqframe
		sta irqframe+1
		sta fps
		sta page
		sta scrollhi
		sta oldscrollhi
		sta sprxoff
		sta sprxoff+1
		lda #$18
		sta scrolllo
		lda #$74
		sta scrollxoff
		lda #$ff
		sta scrollxspd

		lda #$06
		sta rx
		sta ry
		sta rz
		lda #$01
		sta incx
		lda #$02
		sta incy
		lda #$ff
		sta incz
		inc page
		
		jsr gentabs
		jsr copyzp
		jsr	genfill
		jsr	genmath
		
		jsr fullclear
		dec page
		jsr dopage

		
		ldx #0
		lda #col0+8
inl00:
		sta colram+$0000,x
		inx
		bne inl00

inl01:
		sta colram+$0100,x
		inx
		bne inl01

inl02:
		sta colram+$0200,x
		inx
		bpl inl02

		ldx #0
		lda #0
inl2:
		sta screen1+$0000,x
		sta screen1+$0100,x
		sta screen1+$0180,x
		inx
		bne inl2
				
		;lda #1
		;sta $d020
		lda #col1
		sta $d022
		lda #col2
		sta $d023

		lda #$03
		sta $dd00
		lda #$1b
		sta $d011
		lda #$1a
		sta $d018
		lda #$18
		sta $d016
		
		lda #0
		ldx #17-1
.l5:
		sta $d000,x
		dex
		bpl .l5

		ldx #8-1
inl6:
		lda #sprcol3
		sta $d027,x
		lda #sprites1/64
		sta screen1+$3f8,x
		dex
		bpl inl6
		
		lda #$00
		sta $d017
		sta $d01b
		sta $d01d
		sta $d01c

		lda #$01
		sta $d015

		dec $01
		jsr genclear
		inc $01

	;	jsr init_donut4
		jsr init_sierpinsky
		
		dec skipscroll
}

main:	
		;inc $d020
		dec $01
		jsr	update
		inc $01
		;dec $d020
		lda fps
		;sta $d020
		lda #0
		sta fps
		
		;jsr vsync
		jsr dopage
		
		inc frame
		bne .incf
		inc frame+1
.incf:	
		sec
		lda irqframe
		sbc #<endframe
		lda irqframe+1
		sbc #>endframe
		bcc main

end:
		lda #0
		sta $d015
		
!ifdef release {
		ldx #jumpcode_ - jumpcode
-
		lda jumpcode,x
		sta $0100,x
		dex
		bpl -
		jmp $0100
jumpcode
		lda #$0c
		sta stop1
		sta stop2
		+setup_sync $30
		jsr link_load_next_comp
		+sync
		jmp link_exit
jumpcode_
} else {

		sei
		lda #$0b
		sta $d011
		jmp *
}

;p1=y
;p2=x
;reslo=x
;reshi=a
mul:

!zone mul {
		tya
		bmi .l2
		sta mathzp+0
		sta mathzp+2
		eor #$ff
		sta mathzp+4
		sta mathzp+6
		txa
		bmi .l1
		tay
		sec
		lda (mathzp+0),y
		sbc (mathzp+4),y
		tax
		lda (mathzp+2),y
		sbc (mathzp+6),y
		rts
.l1:	
		ldy negtab,x
		lda (mathzp+4),y
		sbc (mathzp+0),y
		tax
		lda (mathzp+6),y
		sbc (mathzp+2),y
		rts
.l2:
		lda negtab,y
		sta mathzp+0
		sta mathzp+2
		eor #$ff
		sta mathzp+4
		sta mathzp+6
		txa
		bmi .l3	
		tay
		lda (mathzp+4),y
		sbc (mathzp+0),y
		tax
		lda (mathzp+6),y
		sbc (mathzp+2),y			
		rts
.l3:
		ldy negtab,x
		lda (mathzp+0),y
		sbc (mathzp+4),y
		tax
		lda (mathzp+2),y
		sbc (mathzp+6),y
		rts	
}		
		
;dx=x
;dy=a
;lo=a
;hi=x	
div:

!zone div {

		bcc .l2

		ldy rezihi,x
		sta mathzp+0
		sta mathzp+2
		eor #$ff
		sta mathzp+4
		sta mathzp+6
		;sec			;is already set
		lda (mathzp+0),y
		sbc (mathzp+4),y
		sta tmp1		
		lda (mathzp+2),y
		sbc (mathzp+6),y
		ldy rezilo,x
		tax
		sec
		lda (mathzp+0),y
		sbc (mathzp+4),y
		lda (mathzp+2),y
		sbc (mathzp+6),y
		clc
		adc tmp1
		bcc .ni1
		inx		
.ni1:
		rts
		
.l2:
		ldy rezihi,x
		sta mathzp+4
		sta mathzp+6
		eor #$ff
		sta mathzp+0
		sta mathzp+2
		sec
		lda (mathzp+4),y
		sbc (mathzp+0),y
		sta tmp1
		lda (mathzp+6),y
		sbc (mathzp+2),y
		ldy rezilo,x
		tax
		clc
		lda (mathzp+4),y
		sbc (mathzp+0),y
		lda (mathzp+6),y
		sbc (mathzp+2),y
		clc
		adc tmp1
		bcs .ni2
		dex
.ni2:
		rts
}
		
update:
		jsr	clear
		
		jsr makemat	
		;rotate, cull, calcedges, dopolys, all in a row as code-wurst
		;jmp update_donut4	
		jmp update_sierpinsky
		
xrots:
		!byte $02,$01,$00,$ff,$fe,$ff,$00,$01
yrots:                              
		!byte $00,$ff,$fe,$ff,$00,$01,$02,$01
zrots:                              
		!byte $ff,$01,$01,$02,$01,$01,$ff,$fe		

;xpos=a
;ypos=x
;resx=tmp1
;resy=a
dopersp:
		tay
		bpl dp1
		lda negtab,y
		tay		
		lda (mathzp+4),y
		sbc (mathzp+0),y
		lda (mathzp+6),y
		sbc (mathzp+2),y
		jmp dp2
		
dp1:
		lda (mathzp+0),y
		sbc (mathzp+4),y
		lda (mathzp+2),y
		sbc (mathzp+6),y

dp2:
		clc
		adc #$40
		sta tmp1
		
		txa
		bpl dp3
		ldy negtab,x
		lda (mathzp+4),y
		sbc (mathzp+0),y
		lda (mathzp+6),y
		sbc (mathzp+2),y
		clc
		adc #$40
		ldx tmp1
		rts
		
dp3:
		tay
		lda (mathzp+0),y
		sbc (mathzp+4),y
		lda (mathzp+2),y
		sbc (mathzp+6),y
		clc
		adc #$40
		ldx tmp1
		rts	
		
!macro ROTPOINT .offx, .offy, .offz, .dstoff {

		lda mat+2+.offx*9
		clc
		adc mat+5+.offy*9
		clc
		adc mat+8+.offz*9
		clc
		adc zoff
		tay			
		
		lda persptab,y
		sta mathzp+0		
		sta mathzp+2
		eor #$ff	
		sta mathzp+4
		sta mathzp+6
		
		lda mat+0+.offx*9
		clc
		adc mat+3+.offy*9
		clc
		adc mat+6+.offz*9
		tax			
		
		lda mat+1+.offx*9
		clc              
		adc mat+4+.offy*9
		clc              
		adc mat+7+.offz*9

		jsr dopersp	
		sta posy+.dstoff	
		stx posx+.dstoff
}

!macro CULLFACE .off1, .off2, .off3, .dstoff {

		lda posx+.off2
		sec
		sbc posx+.off1
		sta tmp1
				
		lda posy+.off2
		sec
		sbc posy+.off1
		sta tmp3
		
		lda posy+.off3
		sec
		sbc posy+.off1
		sta tmp2
				
		lda posx+.off3
		sec
		sbc posx+.off1
		sta tmp4
		
		eor tmp1
		eor tmp2
		eor tmp3
		bmi .fast

		ldy tmp3
		ldx tmp4
		jsr mul
		stx tmp5
		sta tmp6
		
		ldy tmp1
		ldx tmp2
		jsr mul
		tay
		txa
		sec
		sbc tmp5
		tya
		sbc tmp6
		jmp .end
		
.fast:
		lda tmp1
		eor tmp2

.end:			
		sta culls+.dstoff
}				

fullclear:
		lda #<charset1
		sta tmp1
		lda #>charset1
		sta tmp1+1
		lda #$ff
		ldx #8
		jsr memset

		lda #<charset2
		sta tmp1
		lda #>charset2
		sta tmp1+1
		lda #$ff
		ldx #8
		jmp memset

;tmp1=lobyte
;tmp1+1=hibyte
;a=value
;x=numblocks
memset:
		dex
		bmi nomemset
mems0:
		ldy #0
mems1:
		sta (tmp1),y
		iny
		bne mems1

		inc tmp1+1

		dex
		bpl mems0
nomemset:
		rts

clear:	

!zone clr {

		lda #$ff
		ldy page
		bne .l1
		
		jmp clearcode1
		
.l1:
		jmp clearcode2
}

!macro CALCEDGESTEP .off1, .off2, .plane1, .plane2, .dstoff {

		lda culls+.plane1
		ora culls+.plane2
		bpl	.end

		sec
		lda posy+.off2
		sbc posy+.off1
		beq .end
		bcc .swap
		tax

		;sec
		lda posx+.off2
		sbc posx+.off1
		jmp .dodiv
.swap:
		eor #$ff
		tax
		inx
		
		sec
		lda posx+.off1
		sbc posx+.off2
.dodiv:
		jsr div
		eor #$ff
		sta edgelos+.dstoff
		stx edgehis+.dstoff
.end:
}
		
!align 3,0	;take care table stays on single page
dotritgts
		!word dotricase1
		!word dotricase2
		!word dotricase3
		!word dotricase4
		!word dotricase5
		!word dotricase6
		
		!align 7,0
combotabtri:
		!byte 	$00+<dotritgts
		!byte 	$02+<dotritgts
		!byte 	$00+<dotritgts
		!byte 	$04+<dotritgts
		!byte 	$06+<dotritgts
		!byte 	$00+<dotritgts
		!byte 	$08+<dotritgts
		!byte 	$0a+<dotritgts
	
!macro COPYPOLYDATATRI .pos, .edge, .dstoff {
		
		lda #.pos
		sta polyposidxs+.dstoff
		lda #.edge
		sta polyedgeidxs+.dstoff
}	
	
!macro DOTRI .off3, .off2, .off1, .planeid, .edge2, .edge1, .edge3, .color {
		lda culls+.planeid
		bpl	.skip

		lda #0
		ldx posy+.off1
		cpx posy+.off2
		rol

		cpx posy+.off3
		rol

		ldx posy+.off2
		cpx posy+.off3
		rol

		tay
		lda combotabtri,y
		sta dotrijmp + 1
		
		+COPYPOLYDATATRI .off1, .edge1, 0
		+COPYPOLYDATATRI .off2, .edge2, 1
		+COPYPOLYDATATRI .off3, .edge3, 2
		
		lda #.color+>coltab
		
		jsr dotri
.skip:
}

!macro LERPPOLYSEG {

		;ldy y1
		cpy <y2lo+1
		beq .end

		ldx <x2lo
		
		;lda <x2hi+1
		;asl
		;sta <lpspagesmc1+1
		
		jsr lerppolyseg

		;lda <y2lo+1
		;sty y1
.end:
}
	
!macro NEWPOLYSEGLEFT .newy, .newx, .newxstep {

		ldx polyposidxs+.newy
		lda posy,x
		sta <y2lo+1
		ldx polyposidxs+.newx
		lda posx,x
		tax
		lda upshiftlos,x
		sta <x1lo
		lda upshifthis1,x
		sta <x1hi+2
		ldx polyedgeidxs+.newxstep
		lda edgelos,x
		sta <xstep1lo+1
		lda edgehis,x
		tax
		sta <xstep1hi+1
		lda skiptab,x
		ldx #$f0
		sax <x1skip+0
		and #$06
		sta <x1skip+1
		
		+LERPPOLYSEG
}

!macro NEWPOLYSEGRIGHT .newy, .newx, .newxstep {

		ldx polyposidxs+.newy
		lda posy,x
		sta <y2lo+1
		ldx polyposidxs+.newx
		lda posx,x
		tax
		lda lsr3tab,x
		ora pagejmplo
		sta <x2hi+1
		asl
		sta <lpspagesmc1+1
		lda upshiftlos,x
		sta <x2lo
		ldx polyedgeidxs+.newxstep
		lda edgelos,x
		sta <xstep2lo+1
		lda edgehis,x
		tax
		sta <xstep2hi+1
		lda skiptab,x
		ldx #$f0
		sax <x2skip+0
		and #$09
		sta <x2skip+1
						
		+LERPPOLYSEG
}

dotri:
		sta <lpsbitsmc1+2

dotrijmp:	
		jmp (dotritgts)
		;old version needed 15 cycles + aligned table

!macro TRICASE1 .off1, .off2, .off3 {
		ldx polyedgeidxs+.off3
		lda edgelos,x
		sta <xstep1lo+1
		ldy edgehis,x
		sty <xstep1hi+1
		lda skiptab,y
		ldx #$f0
		sax <x1skip+0
		and #$06
		sta <x1skip+1

		ldx polyposidxs+.off1
		ldy posx,x
		lda upshiftlos,y
		sta <x1lo
		lda upshifthis1,y
		sta <x1hi+2
		ldy posy,x

		+NEWPOLYSEGRIGHT .off2, .off1, .off1
		+NEWPOLYSEGRIGHT .off3, .off2, .off2
		rts
}

!macro TRICASE2 .off1, .off2, .off3 {
		ldx polyedgeidxs+.off1
		lda edgelos,x
		sta <xstep2lo+1
		lda edgehis,x
		tax
		sta <xstep2hi+1
		lda skiptab,x
		ldx #$f0
		sax <x2skip+0
		and #$09
		sta <x2skip+1

		ldx polyposidxs+.off1
		ldy posx,x
		lda lsr3tab,y
		ora pagejmplo
		sta <x2hi+1
		asl
		sta <lpspagesmc1+1
		lda upshiftlos,y
		sta <x2lo
		ldy posy,x
		
		+NEWPOLYSEGLEFT .off3, .off1, .off3
		+NEWPOLYSEGLEFT .off2, .off3, .off2
		rts
}

dotricase1:
		+TRICASE1 0,1,2
dotricase2:
		+TRICASE2 0,1,2
dotricase3:
		+TRICASE1 2,0,1
dotricase4:
		+TRICASE2 1,2,0
dotricase5:
		+TRICASE1 1,2,0
dotricase6:
		+TRICASE2 2,0,1
		
!macro MAKEMATFACTORPOS .lerpoff, .idx {
		ldy lerptab+.lerpoff*256,x
		sty mat+.lerpoff*18+.idx
}	

!macro MAKEMATFACTORNEG .lerpoff, .idx {
		ldy lerptab+.lerpoff*256,x
	
		lda negtab,y
		sta mat+.lerpoff*18+9+.idx
}	

!macro MAKEMATFACTORBOTH .lerpoff, .idx {
		ldy lerptab+.lerpoff*256,x
		sty mat+.lerpoff*18+.idx
	
		lda negtab,y
		sta mat+.lerpoff*18+9+.idx
}	

makemat:
		lda frame+1
		and #$07
		tax
		lda xrots,x
		sta incx
		lda yrots,x
		sta incy
		lda zrots,x
		sta incz
	
		lda frame
		clc
		adc #$18
		asl
		tax
		lda sinhi,x
		clc
		adc #$40
		lsr
		lsr
		eor #$80
		sta zoff
	
		lda rx
		clc 
		adc incx
		sta rx
	
		lda ry
		clc 
		adc incy
		sta ry
				
		lda rz
		clc 
		adc incz
		sta rz

		lda ry
		sec
		sbc rz
		tax
		clc
		adc rx
		sta tmp1
		
		lda ry
		clc
		adc rz
		tay
		clc
		adc rx
		sta tmp2
		
		lda sinlo+$c0,x
		sec
		sbc coslo,y
		lda sinhi+$c0,x
		sbc coshi,y
		sta mat+0

		lda sinlo,x
		sec
		sbc sinlo,y
		lda sinhi,x
		sbc sinhi,y
		sta mat+1
				
		ldx ry
		lda sinlo,x
		asl
		lda sinhi,x
		rol
		sta mat+2
		
		lda rx
		clc
		adc rz
		tax
		sec
		sbc ry
		sta tmp4
		 
		lda rx
		sec
		sbc rz
		tay
		sec
		sbc ry
		sta tmp3
		
		lda sinlo,x
		sec
		sbc sinlo,y
		sta tmp5
		lda sinhi,x
		sbc sinhi,y
		sta tmp6
		
		lda coslo,x
		clc
		adc coslo,y
		sta tmp7
		lda coshi,x
		adc coshi,y
		sta tmp8
		
		lda coslo,x
		sec
		sbc coslo,y
		sta tmp9
		lda coshi,x
		sbc coshi,y
		sta tmp10
		
		lda rz
		sec
		sbc rx
		tay
		lda sinlo,y
		sec
		sbc sinlo,x
		sta tmp11
		lda sinhi,y
		sbc sinhi,x
		sta tmp12
		
		ldx tmp3
		ldy tmp4
		lda coslo,x
		clc
		adc coslo,y
		sta tmp13
		lda coshi,x
		adc coshi,y
		sta tmp14
		asl
		ror tmp14
		ror tmp13
		
		ldx tmp1
		ldy tmp2
		lda sinlo,y
		sec
		sbc sinlo,x
		sta tmp15
		lda sinhi,y
		sbc sinhi,x
		sta tmp16
		asl
		ror tmp16
		ror tmp15
		
		lda coslo,x
		clc
		adc coslo+1,y
		sta tmp17
		lda coshi,x
		adc coshi+1,y
		sta tmp18
		asl
		ror tmp18
		lda tmp17
		ror
		sec
		sbc tmp13
		tax
		
		lda tmp18
		sbc tmp14
		tay
			
		txa
		clc
		adc tmp5
		tya
		adc tmp6
		sta mat+3

		ldx tmp3
		ldy tmp4
		lda sinlo,x
		sec
		sbc sinlo,y
		sta tmp17
		lda sinhi,x
		sbc sinhi,y	
		sta tmp18
		asl
		ror tmp18
		lda tmp17
		ror
		clc
		adc tmp15
		tax
		lda tmp18
		adc tmp16
		tay
		txa
		sec
		sbc tmp7
		tya
		sbc tmp8
		sta mat+4
			
		lda rx
		clc
		adc ry
		tay
		lda ry
		sec
		sbc rx
		tax
		lda sinlo,x
		sec
		sbc sinlo,y
		lda sinhi,x
		sbc sinhi,y
		sta mat+5
		
		lda rx
		sec
		sbc ry
		tax
		lda coslo,x
		clc
		adc coslo,y
		lda coshi,x
		adc coshi,y
		sta mat+8
		
		ldx tmp1
		ldy tmp3
		lda sinlo,x
		sec
		sbc sinlo,y
		sta tmp13
		lda sinhi,x
		sbc sinhi,y
		sta tmp14
		asl
		ror tmp14
		ror tmp13
		
		lda coslo,x
		sec
		sbc coslo,y
		sta tmp15
		lda coshi,x
		sbc coshi,y
		sta tmp16
		asl
		ror tmp16
		ror tmp15
		
		ldx tmp2
		ldy tmp4
		lda sinlo,x
		sec
		sbc sinlo+1,y
		sta tmp19
		lda sinhi,x
		sbc sinhi+1,y
		sta tmp20				
		asl
		ror tmp20
		ror tmp19
		
		lda tmp19
		clc
		adc tmp13
		sta tmp19
		lda tmp20
		adc tmp14
		sta tmp20
		
		lda tmp19
		sec
		sbc tmp9
		lda tmp20
		sbc tmp10
		sta mat+6
		
		ldx tmp2
		ldy tmp4
		lda coslo,y
		sec
		sbc coslo+1,x
		sta tmp19
		lda coshi,y
		sbc coshi+1,x
		sta tmp20
		asl
		ror tmp20
		lda tmp19
		ror 
		clc
		adc tmp15
		tax
		lda tmp20
		adc tmp16
		tay
		txa
		clc
		adc tmp11
		tya
		adc tmp12
		sta mat+7
		
		ldx mat+0
		+MAKEMATFACTORPOS  0, 0
		+MAKEMATFACTORBOTH 4, 0
		+MAKEMATFACTORBOTH 7, 0

		ldx mat+1
		+MAKEMATFACTORPOS  0, 1
		+MAKEMATFACTORBOTH 4, 1
		+MAKEMATFACTORBOTH 7, 1
	
		ldx mat+2
		+MAKEMATFACTORPOS  0, 2
		+MAKEMATFACTORBOTH 4, 2
		+MAKEMATFACTORBOTH 7, 2
		
		ldx mat+3
		+MAKEMATFACTORPOS  0, 3
		+MAKEMATFACTORBOTH 2, 3
		+MAKEMATFACTORBOTH 5, 3
		+MAKEMATFACTORNEG  6, 3
		
		ldx mat+4
		+MAKEMATFACTORPOS  0, 4
		+MAKEMATFACTORBOTH 2, 4
		+MAKEMATFACTORBOTH 5, 4
		+MAKEMATFACTORNEG  6, 4
		
		ldx mat+5
		+MAKEMATFACTORPOS  0, 5
		+MAKEMATFACTORBOTH 2, 5
		+MAKEMATFACTORBOTH 5, 5
		+MAKEMATFACTORNEG  6, 5
		
		ldx mat+6
		+MAKEMATFACTORNEG  1, 6
		+MAKEMATFACTORBOTH 3, 6
		
		ldx mat+7
		+MAKEMATFACTORNEG  1, 7
		+MAKEMATFACTORBOTH 3, 7
		
		ldx mat+8
		+MAKEMATFACTORNEG  1, 8
		+MAKEMATFACTORBOTH 3, 8
		rts

		!align 1,0
paged018:
		!byte $1a,$18
		
pagehis:
		!byte >xhis11
		!byte >xhis12
		
pagejmplos:
		!byte $00
		!byte $10
		
dopage:
		lda page
		eor #1
		sta page
		
		tax
		lda pagejmplos,x
		sta pagejmplo

		lda $d012
		cmp #$b2
		bcs paskip
		
		lda paged018,x
		sta $d018
paskip:
		rts
		
initirq:
		sei
		lda #<irq1
		sta $fffe
		lda #>irq1
		sta $ffff
		lda #$31
		sta $d012
		lda #$00
		sta $dc0e
		lda #$81
		sta $d01a
		lda #$1b
		sta $d011	
		cli		
		rts

!macro STARTIRQ {
		sta regsave+0
		stx regsave+1
		sty regsave+2	
		lda $01
		sta regsave+3
		lda #$35
		sta $01
		inc $d019
}	

!macro ENDIRQ .nextirq, .nextline {
		lda #<.nextirq
		sta $fffe
;		lda #>.nextirq
;		sta $ffff
		lda #.nextline
		sta $d012

!ifndef release {
		lda $dc0d
}
		lda regsave+3
		sta $01
		ldy regsave+2
		ldx regsave+1
		lda regsave+0
		rti		
}	

		!align 255,0

!zone ir1 {
irq1:
		+STARTIRQ

		ldy page
		lda paged018,y
		ldx #$1b
		ldy #barcol0
		sta $d018
		stx $d011
		sty $d021
		sty $d020
		lda scrolllo
		sta $d016

		ldx #8
.l0:
		dex
		bpl .l0
		nop

		lda #col0
		ldx #col3
		sta $d020
		stx $d021
	
!ifndef release {
		jsr music+3
}

		+ENDIRQ irq2, $b0
}
	
irq2:

!zone ir2 {
		+STARTIRQ

		ldx #1
.l0:
		dex
		bpl .l0
		nop
		nop
		
		lda #$18
		ldx #$3b
		ldy #barcol1
		sta $d018
		stx $d011
		sty $d020
		sty $d021
		lda #$18
		sta $d016
				
		ldx #7
.l3:
		dex
		bpl .l3
		
		ldy #logocol
		sty $d020
		sty $d021

		lda skipscroll
		bne	.l2

		inc irqframe
		bne .l1
		inc irqframe+1
.l1:	
		inc fps

stop1		jsr updatescroll
stop2		jsr updatesprites
.l2:

		+ENDIRQ irq3, $fc
}

irq3:

!zone ir3 {
		stx regsave+1
		ldx $01
		stx regsave+3
		ldx #$35
		stx $01
		inc $d019

		ldx #3
.l0:
		dex
		bpl .l0
		nop
		nop
		nop
		
		ldx #barcol2
		stx $d020
		stx $d021

		ldx #9
.l1:
		dex
		bpl .l1
		nop
		
		ldx #bordercol
		stx $d020
		stx $d021

		ldx #<irq1
		stx $fffe
		ldx #$31
		stx $d012

!ifndef release {
		ldx $dc0d
}
		ldx regsave+3
		stx $01
		ldx regsave+1
		rti		
}

skipscroll:
		!byte $1

sprpoitab:
		!byte sprites1/64+0
		!byte sprites1/64+1
		!byte sprites1/64+2
		!byte sprites1/64+3
		!byte sprites1/64+4
		!byte sprites1/64+5
		!byte sprites2/64+0
		!byte sprites2/64+1
		!byte sprites2/64+1
		!byte sprites2/64+0
		!byte sprites1/64+5
		!byte sprites1/64+4
		!byte sprites1/64+3
		!byte sprites1/64+2
		!byte sprites1/64+1
		!byte sprites1/64+0
		!byte sprites2/64+2

sprdata:
		!byte 16*4,0
		!byte 16*4,0
		
sprvertoff:		
		!byte 0
		
d010tab:
		!byte $01,$fe,$02,$fd

spridx:
		!byte 2
	
sprrndtab:
		!byte 37,97,53,73,61,83,47,89
		
sprnextframe:
		!byte 97
	
sprverttab:
		!byte 0,4,5,6
	
!macro DOSPRITESPR .sprid {
		lda sprdata+.sprid*2
		clc
		adc #1
		cmp #8*4
		bcc .clamp
		lda #8*4
.clamp:
		sta sprdata+.sprid*2
		lsr
		tay
		lda sprpoitab,y
		sta screen1+$3f8+.sprid
}
	
updatesprites:
		ldx #$0
		lda scrollhi
		cmp #$1d
		bcs us00
		ldx #$3
us00:			
		stx $d015

		lda irqframe
		cmp sprnextframe
		bne usskip

		lda spridx
		and #7
		tax
		lda sprrndtab,x
		clc
		adc sprnextframe
		sta sprnextframe
		
		lda spridx
		clc
		adc #1
		sta spridx
		ldx #0
		
		lda spridx
		and #3
		tay
		lda sprverttab,y
		sta sprvertoff
		
		sta sprdata+1,x
		lda #0
		sta sprdata+0,x
		
usskip:
		+DOSPRITESPR 0
		
		ldx #2-2
us1:		
		ldy sprdata+1,x
		lda posy,y
		clc
		adc #50-11
		cmp #$32
		bcs +
		lda #$32
+
		cmp #$b1-21
		bcc ussclipy
		lda #$b1-21
ussclipy:		
		sta $d001,x

		lda posx,y
		clc
		adc sprxoff+0
		sta $d000,x
		
		lda $d010
		and d010tab+1,x
		bcc usd010
		ora d010tab,x
usd010:
		sta $d010
		
		dex
		dex
		bpl us1 
		rts
		
vsync:	

!zone vs {

.l0:
		lda $d011
		bpl .l0
.l1:
		lda $d011
		bmi .l1
		rts
}

updatescroll:
		lda irqframe
		cmp #<(endframe-$78)
		bne usc00
		lda irqframe+1
		cmp #>(endframe-$78)
		bne usc00
		lda #1
		sta scrollxspd
usc00:			

		lda scrollxoff
		clc
		adc scrollxspd
		bpl usc0
		lda #0
usc0:
		sta scrollxoff

		lda irqframe+1
		and #1
		clc
		adc #>movesin
		sta uscsinsmc+2
		ldx irqframe
uscsinsmc:
		lda movesin,x
		clc
		adc scrollxoff
		sta sprxoff
		tay
		lda #0
		rol
		sta sprxoff+1
		asl
		asl
		asl
		asl
		asl
		sta ucsmc2+1
		tya
		and #$07
		ora #$10
		sta scrolllo
		tya
		lsr
		lsr
		lsr
ucsmc2:
		ora #0
		sta scrollhi
		cmp oldscrollhi
		beq uscskip
		sta oldscrollhi
		cmp #38
		bcs uscskip
		tax
		clc
		adc #17
		cmp #39
		bcc uscclip2
		lda #39
uscclip2:
		sta uscendsmc+1

		lda #$00
		jsr clrcharrow
		inx
uscl0:
		clc
		sta screen1+0*40,x
		adc #$01
		sta screen1+1*40,x
		adc #$01
		sta screen1+2*40,x
		adc #$01
		sta screen1+3*40,x
		adc #$01
		sta screen1+4*40,x
		adc #$01
		sta screen1+5*40,x
		adc #$01
		sta screen1+6*40,x
		adc #$01
		sta screen1+7*40,x
		adc #$01
		sta screen1+8*40,x
		adc #$01
		sta screen1+9*40,x
		adc #$01
		sta screen1+10*40,x
		adc #$01
		sta screen1+11*40,x
		adc #$01
		sta screen1+12*40,x
		adc #$01
		sta screen1+13*40,x
		adc #$01
		sta screen1+14*40,x
		adc #$01
		sta screen1+15*40,x
		adc #$01

		inx
uscendsmc:
		cpx #0
		bne uscl0
		
		lda #$00
		jsr clrcharrow
uscskip:
		lda sprxoff
		clc
		adc #12+8
		sta sprxoff
		bcc usccspr
		inc sprxoff+1
usccspr:
		rts
		
clrcharrow:
		sta screen1+0*40,x
		sta screen1+1*40,x
		sta screen1+2*40,x
		sta screen1+3*40,x
		sta screen1+4*40,x
		sta screen1+5*40,x
		sta screen1+6*40,x
		sta screen1+7*40,x
		sta screen1+8*40,x
		sta screen1+9*40,x
		sta screen1+10*40,x
		sta screen1+11*40,x
		sta screen1+12*40,x
		sta screen1+13*40,x
		sta screen1+14*40,x
		sta screen1+15*40,x
		rts

minys:
		!byte $2d,$1e,$12,$0b,$08,$03,$02,$01
		!byte $01,$02,$03,$08,$0e,$14,$20,$2c

maxys:
		!byte $5e,$6d,$6e,$72,$77,$7a,$7c,$7c
		!byte $7c,$7c,$7b,$76,$72,$6c,$63,$53
		
genclear:
		lda #<clearcode1
		sta $60
		lda #>clearcode1
		sta $61
		lda #<charset1
		sta $62
		lda #>charset1
		sta $63
		jsr genclear2
		
		lda #<clearcode2
		sta $60
		lda #>clearcode2
		sta $61
		lda #<charset2
		sta $62
		lda #>charset2
		sta $63
		jmp genclear2
				
genclear2:
		ldy #$00
gc1:		
		sty $66

		lda minys,y
		clc
		adc $62
		sta $64
		lda $63
		adc #$00
		sta $65
		
		lda maxys,y
		sec
		sbc minys,y
		tax
gc2:
		lda cleartmp+$00
		ldy #$00
		sta ($60),y
		lda $64
		iny	
		sta ($60),y
		lda $65
		iny	
		sta ($60),y

		lda $60
		clc
		adc #$03
		sta $60
		bcc gc3
		inc $61	
gc3:			
		inc $64
		
		dex
		bpl gc2
		
		lda $62
		clc
		adc #$80
		sta $62
		bcc gc4
		inc $63
gc4:		
		ldy $66
		iny
		cpy #$10
		bne gc1 

		ldy #$00
		lda #$60
		sta ($60),y
		rts
				
cleartmp:
		sta charset1+$0000

!macro GENLERP .value, .offhi {

		ldy #.value
		lda #>(lerptab+.offhi*256)
		jsr dolerp

}

dolerp:
		sty tmp2+0
		sta tmp3+1
				
		lda #0
		sta tmp1+0
		sta tmp1+1
		sta tmp3+0
		
		ldx #0
.l5:
		txa
		tay

		lda tmp1+1
				
		sta (tmp3),y
		eor #$ff
		clc
		adc #1
		
		ldy negtab,x
		dey
		sta (tmp3),y
		
		clc
		lda tmp1+0
		adc tmp2+0
		sta tmp1+0
		lda tmp1+1
		adc #0
		sta tmp1+1

		inx
		bpl .l5
		rts

	;!src "donut4.asm"
	!src "sierpinsky.asm"

*=initcode
zp_begin
!pseudopc zp_code {

fpback:
		txa
xstep1lo:
		sbx #$00
		stx <x1lo
x1skip:
		bcc *+2

		lda <x1hi+2
xstep1hi:
		adc #0
		sta <x1hi+2

		lax <x2lo
xstep2lo:
		sbx #$00
		stx <x2lo
x2skip:
		bcc	*+2
		
x2hi:
		lda #0
xstep2hi:
		adc #0
		sta <x2hi+1
		asl
		sta <lpspagesmc1+1

		iny
y2lo:
		cpy #0
		beq .end

lerppolyseg:
lpsl0:

lpsbitsmc1:
		lda coltab,y
lpspagesmc1:
x1hi:
		jmp (fillpois)
.end
		rts
}

zp_end


genfill:
		lda #<fillpois
		sta tmp1+0
		lda #>fillpois
		sta tmp1+1
		ldx #$0f
gf00:
		ldy #0
gf01:
		lda #<fpback
		sta (tmp1),y
		iny
		lda #>fpback
		sta (tmp1),y
		iny
		bne gf01

		inc tmp1+1
		
		dex
		bpl gf00

		lda #<fillcode
		sta tmp1+0
		lda #>fillcode
		sta tmp1+1
		
		lda #<fillpois
		sta tmp1+2
		lda #>fillpois
		sta tmp1+3
		lda #>xhis11
		sta gfsmc0+2
		sta gfsmc1+2
		sta gfsmc2+2
		sta gfsmc3+2
		jsr genfill2
		
		lda #<(fillpois+$20)
		sta tmp1+2
		lda #>(fillpois+$20)
		sta tmp1+3
		lda #>xhis12
		sta gfsmc0+2
		sta gfsmc1+2
		sta gfsmc2+2
		sta gfsmc3+2
		;jmp genfill2
		
genfill2:
		lda tmp1+2
		sta tmp1+4

		ldx #0
gf0:
		stx tmp1+7
		
		ldx #0
gf1:
		stx tmp1+8

		lda tmp1+7
		clc
		adc tmp1+3
		sta tmp1+5
		
		lda tmp1+8
		asl
		tay
		
		lda tmp1+0
		sta (tmp1+4),y
		lda tmp1+1
		iny
		sta (tmp1+4),y
		
		inc tmp1+6
		
		ldx tmp1+8
		txa
		sec
		sbc tmp1+7
		bcc gf4
		bne gf2
		
		jsr	genfillzero
		jmp gf3
gf2:	
		jsr	genfillpos
		jmp gf3
gf4:
		jsr genfillempty
gf3:	
		ldx tmp1+8
		inx
		cpx #16
		bne gf1
		
		ldx tmp1+7
		inx
		cpx #16
		bne gf0
		rts

genfillzero:
		ldy #filltmpzerosize-1
gfz0:	
		lda filltmpzero,y
		sta (tmp1+0),y
		dey
		bpl gfz0
		
		lda tmp1+8
		asl
		asl
		asl
		tax
		lda xlos1,x
		ldy #1
		sta (tmp1+0),y
		ldy #12
		sta (tmp1+0),y
		ldy #15
		sta (tmp1+0),y
		iny
gfsmc0:
		lda xhis11,x
		ldy #2
		sta (tmp1+0),y
		ldy #13
		sta (tmp1+0),y
		ldy #16
		sta (tmp1+0),y
	
		lda tmp1+0
		clc
		adc #filltmpzerosize
		sta tmp1+0
		bcc gfz1
		inc tmp1+1
gfz1:
		jmp addrts

filltmpzerosize = 17
filltmpzero:
		eor charset1+0,y
		and xbits2,x
		ldx <x1lo
		and xbits1,x
		eor charset1+0,y
		sta charset1+0,y
		
genfillpos:
		ldx tmp1+7
		inx
		cpx tmp1+8
		beq gfp2
gfp3:	
		jsr	addfillinner
		
		inx
		cpx tmp1+8
		bne gfp3
gfp2:

		ldy #filltmppos1size-1
gfp0:	
		lda filltmppos1,y
		sta (tmp1+0),y
		dey
		bpl gfp0
		
		lda tmp1+8
		asl
		asl
		asl
		tax
		lda xlos1,x
		ldy #3
		sta (tmp1+0),y
		ldy #11
		sta (tmp1+0),y
		iny
gfsmc1:
		lda xhis11,x
		ldy #4
		sta (tmp1+0),y
		ldy #12
		sta (tmp1+0),y
		
		lda tmp1+0
		clc
		adc #filltmppos1size
		sta tmp1+0
		bcc gfp1
		inc tmp1+1
gfp1:		

		ldy #filltmppos2size-1
gfp02:	
		lda filltmppos2,y
		sta (tmp1+0),y
		dey
		bpl gfp02
		
		lda	tmp1+7
		asl
		asl
		asl
		tax
		lda xlos1,x
		ldy #1
		sta (tmp1+0),y
		ldy #13
		sta (tmp1+0),y
		iny
gfsmc2:
		lda xhis11,x
		ldy #2
		sta (tmp1+0),y
		ldy #14
		sta (tmp1+0),y
				
		lda tmp1+0
		clc
		adc #filltmppos2size
		sta tmp1+0
		bcc gfp12
		inc tmp1+1
gfp12:		
		jmp addrts

filltmppos1size = 13
filltmppos1:
		sta tmp1
		eor charset1+0,y
		and xbits2inv,x
		eor tmp1
		sta charset1+0,y
		
filltmppos2size = 15
filltmppos2:	
		lda charset1+0,y
		eor tmp1
		ldx <x1lo
		and xbits1inv,x
		eor tmp1
		sta charset1+0,y

addfillinner:	
		txa
		asl
		asl
		asl
		tay
gfsmc3:
		lda xhis11,y
		sta tmp1+10
		lda xlos1,y
		ldy #1
		sta (tmp1+0),y

		lda tmp1+10
		iny
		sta (tmp1+0),y
		
		ldy #0
		lda filltmpinner,y
		sta (tmp1+0),y
		
		lda tmp1+0
		clc
		adc #filltmpinnersize
		sta tmp1+0
		bcc afi0
		inc tmp1+1
afi0:	
		rts
	
filltmpinnersize = 3
filltmpinner:
		sta charset1+0,y

genfillempty:
		ldy #filltmpemptysize-1
gfe0:
		lda filltmpempty,y
		sta (tmp1+0),y
		dey
		bpl gfe0

		lda tmp1+0
		clc
		adc #filltmpemptysize
		sta tmp1+0
		bcc gfe1
		inc tmp1+1
gfe1:
		ldy #0
		lda #$4c
		sta (tmp1+0),y
		lda #<fpback+1
		iny
		sta (tmp1+0),y 
		lda #>fpback+1
		iny
		sta (tmp1+0),y 
		jmp	addrts2
		
filltmpemptysize = 2
filltmpempty:
		lax <x1lo
	
addrts:
		ldy #0
		lda #$4c
		sta (tmp1+0),y
		lda #<fpback
		iny
		sta (tmp1+0),y 
		lda #>fpback
		iny
		sta (tmp1+0),y 

addrts2:
		lda tmp1+0
		clc
		adc #3
		sta tmp1+0
		bcc ar0
		inc tmp1+1
ar0:	
		rts
		
xbitssrc1:
		!byte $ff,$3f,$0f,$03

xbitssrc2:
		!byte $00,$c0,$f0,$fc
xbitssrc:
		!byte $80,$40,$20,$10,$08,$04,$02,$01
		
		;steeppos,steepneg,$00,$ff
skiptabsrc:
		!byte $90,$b0,$9f,$bf
;		!byte $9f,$bf,$9f,$bf
	
gentabs:

!zone gent {

		ldx #0
.l0:	
		txa
		asl
		asl
		asl
		asl
		and #$80
		sta xlos1,x
		
		txa
		lsr
		lsr
		lsr
		lsr
		tay
		ora #>charset1
		sta xhis11,x
		tya
		ora #>charset2
		sta xhis12,x
		
		txa
		lsr
		lsr
		lsr
		sta lsr3tab,x
		
		inx
		bpl .l0
		
		ldx	#0
.l1:
		txa
		lsr
		lsr
		lsr
		lsr
		lsr
		lsr
		tay
		lda xbitssrc1,y
		sta	xbits1,x
		eor #$ff
		sta xbits1inv,x
		lda xbitssrc2,y
		sta	xbits2,x
		eor #$ff
		sta xbits2inv,x
		
		txa
		asl
		asl
		asl
		asl
		asl
		ora #$10
		sta upshiftlos,x
		
		txa
		lsr
		lsr
		lsr
		clc
		adc #>fillpois
		sta upshifthis1,x

		ldy #0
		txa
		bpl .l6
		eor #$ff
		iny
.l6:
		cmp #0
		bne .l7
		iny
		iny
.l7:	
		lda skiptabsrc,y
		sta skiptab,x
		
		inx
		bne .l1
		
		ldx #0
.l4:		
		lda #%01100110
		sta coltab+$000,x
		lda #%01010101
		sta coltab+$001,x

		lda #%10011001
		sta coltab+$100,x
		lda #%01100110
		sta coltab+$101,x
		
		lda #%10011001
		sta coltab+$200,x
		lda #%10101010
		sta coltab+$201,x

		lda #%10001000
		sta coltab+$300,x
		lda #%10101010
		sta coltab+$301,x

		lda #%00100010
		sta coltab+$400,x
		lda #%10001000
		sta coltab+$401,x

		lda #%00100010
		sta coltab+$500,x
		lda #%00000000
		sta coltab+$501,x
			
		inx
		inx
		bpl .l4
		rts
}
			
copyzp:
		ldx #zp_end-zp_begin-1
cz0:
		lda zp_begin,x
		sta zp_code,x
		dex
		bpl cz0
		rts
			
genmath:

!zone genm {

		ldx #$00
		txa
		!byte $c9
.lb1:  
		tya
      	adc #$00
.ml1: 
		sta multabhi,x
      	tay
      	cmp #$40
      	txa
      	ror
.ml9:  
		adc #$00
      	sta .ml9+1
      	inx
.ml0:
	  	sta multablo,x
      	bne .lb1
      	inc .ml0+2
      	inc .ml1+2
      	clc
      	iny
      	bne .lb1
      	
      	ldx #$00
		ldy #$ff
.l0:
	   	lda multabhi+1,x
	   	sta multab2hi+$100,x
	   	lda multabhi,x
	   	sta multab2hi,y
	   	lda multablo+1,x
	   	sta multab2lo+$100,x
	   	lda multablo,x
	   	sta multab2lo,y
	   	dey
		
		txa
		eor #$ff
		clc
		adc #$01
		sta negtab,x

	  	inx
      	bne .l0
		
		lda #>(multabs+$0000)
		sta mathzp+1
		lda #>(multabs+$0200)
		sta mathzp+3
		lda #>(multabs+$0400)
		sta mathzp+5
		lda #>(multabs+$0600)
		sta mathzp+7
		rts		
}

*=sintab
	!bin "data/sin14bit.dat"

*=persptab
	!bin "data/persptab.dat"

!ifndef release {
*=logobitmap
	!bin "data/logo.kla",$0b40,$0002
	
*=logoscreen
	!bin "data/logo.kla",$0168,$1f42

*=logocolram
	!bin "data/logo.kla",$0168,$232a
}

*=sprites1
	!bin "data/starsprites2.dat",$180

*=sprites2
	!bin "data/starsprites2.dat",$0c0,$180

*=rezitab
	!bin "data/rezitab.dat"
		
*=movesin
	!bin "data/movesin.dat"

!ifndef release {
*=music
	!bin "data/music.prg",,2
}
