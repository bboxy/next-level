.import source "framework/pseudocommands.asm"
.import source "framework/macros.asm"

.pseudopc $e400{
.var chunklength = $25d
.var dataDestination = $4880
copySpeedCode:
	ldx #$40
        ldy #$00

!:
lda repeatData+ $100*0,y
!a:
sta dataDestination+ $100*0,y
lda repeatData+ $100*1,y
!b:
sta dataDestination+ $100*1,y
lda repeatData+ $100*2,y
!c:
sta dataDestination+ $100*2,y
iny
bne !-

lda !a- + 1
clc
adc #<chunklength
sta !a- + 1
sta !b- + 1
sta !c- + 1

lda !a- + 2
adc #>chunklength
sta !a- + 2
adc #1
sta !b- + 2
adc #1
sta !c- + 2

	dex
	bne !-
	lda #$4c
	sta dataDestination + chunklength*$40 + 0
	lda #<create_back
	sta dataDestination + chunklength*$40 + 1
	lda #>create_back
	sta dataDestination + chunklength*$40 + 2

propagateDiffs:



lookup1:
	ldx changeLookupAddressesLB
lookup2:
	lda changeLookupAddressesHB
	sta addValue +2

dirty1:
	lda dirtyAddressesLB
	sta fetch +1
	clc
	adc #<chunklength
	sta setValue +1
dirty2:
	lda dirtyAddressesHB
	sta fetch +2
	adc #>chunklength
	sta setValue +2


	ldy #<($40 -1)

loop:
fetch:
	lda $2000
addValue:
	adc $2000,x
setValue:
	sta $2000
	dey
	beq !c+
!:
	//stx fetch + 1
	//lda setValue + 2
	//sta fetch + 2

	clc
	lda setValue + 1
	sta fetch + 1
	adc #<chunklength
	sta setValue + 1
	lda setValue + 2
	sta fetch + 2
	adc #>chunklength
	sta setValue + 2
	inx
	bne loop
	inc addValue + 2
	jmp loop


!c:
dec outerCounter 
bne !c+
dec outerCounter +1
bmi !+
!c:
:incLabel(lookup1)
:incLabel(lookup2)
:incLabel(dirty1)
:incLabel(dirty2)
jmp lookup1
!:
rts


jmp lookup1
countDown:
.byte  <($40 -1), >($40 -1)
outerCounter:
.byte <$120, >$120



dirtyAddressesHB: 
.byte $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $49, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a
dirtyAddressesLB: 
.byte $81, $82, $84, $85, $89, $8a, $8c, $8d, $91, $92, $94, $95, $99, $9a, $9c, $9d, $ad, $ae, $b0, $b1, $b3, $b4, $b6, $b7, $b9, $ba, $bc, $bd, $bf, $c0, $c2, $c3, $c7, $c8, $ca, $cb, $cf, $d0, $d2, $d3, $d7, $d8, $da, $db, $df, $e0, $e2, $e3, $e7, $e8, $ea, $eb, $ef, $f0, $f2, $f3, $f7, $f8, $fa, $fb, $ff, $0, $2, $3, $7, $8, $a, $b, $f, $10, $12, $13, $17, $18, $1a, $1b, $1f, $20, $22, $23, $27, $28, $2a, $2b, $2f, $30, $32, $33, $37, $38, $3a, $3b, $3f, $40, $42, $43, $47, $48, $4a, $4b, $4f, $50, $52, $53, $57, $58, $5a, $5b, $5f, $60, $62, $63, $67, $68, $6a, $6b, $6f, $70, $72, $73, $77, $78, $7a, $7b, $7f, $80, $82, $83, $87, $88, $8a, $8b, $8f, $90, $92, $93, $97, $98, $9a, $9b, $9f, $a0, $a2, $a3, $a7, $a8, $aa, $ab, $af, $b0, $b2, $b3, $b7, $b8, $ba, $bb, $bf, $c0, $c2, $c3, $c7, $c8, $ca, $cb, $cf, $d0, $d2, $d3, $d7, $d8, $da, $db, $df, $e0, $e2, $e3, $e7, $e8, $ea, $eb, $ef, $f0, $f2, $f3, $f7, $f8, $fa, $fb, $ff, $0, $2, $3, $7, $8, $a, $b, $f, $10, $12, $13, $17, $18, $1a, $1b, $1f, $20, $22, $23, $27, $28, $2a, $2b, $2f, $30, $32, $33, $37, $38, $3a, $3b, $3f, $40, $42, $43, $47, $48, $4a, $4b, $4f, $50, $52, $53, $57, $58, $5a, $5b, $5f, $60, $62, $63, $67, $68, $6a, $6b, $6f, $70, $72, $73, $7d, $7e, $80, $81, $85, $86, $88, $89, $8d, $8e, $90, $91, $95, $96, $98, $99, $9d, $9e, $a0, $a1, $a5, $a6, $a8, $a9, $b3, $b4, $b8, $b9, $bd, $be, $c2, $c3, $c7, $c8, $cc, $cd, $d1, $d2, $d9, $da
changeLookupAddressesLB: 
.byte <data0, <data1, <data0, <data2, <data0, <data3, <data0, <data4, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data7, <data8, <data7, <data8, <data7, <data8, <data7, <data8, <data7, <data8, <data7, <data8, <data7, <data8, <data9, <data10, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data0, <data3, <data0, <data4, <data0, <data3, <data0, <data4, <data0, <data3, <data0, <data4, <data0, <data5, <data0, <data4, <data0, <data3, <data0, <data4, <data0, <data3, <data0, <data2, <data0, <data3, <data0, <data2, <data0, <data1, <data0, <data2, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data0, <data3, <data0, <data2, <data0, <data3, <data0, <data2, <data0, <data1, <data0, <data2, <data0, <data3, <data0, <data2, <data0, <data3, <data0, <data2, <data0, <data3, <data0, <data2, <data7, <data8, <data7, <data8, <data7, <data8, <data7, <data8, <data7, <data8, <data7, <data8, <data7, <data8, <data7, <data8
changeLookupAddressesHB: 
.byte >data0, >data1, >data0, >data2, >data0, >data3, >data0, >data4, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data7, >data8, >data7, >data8, >data7, >data8, >data7, >data8, >data7, >data8, >data7, >data8, >data7, >data8, >data9, >data10, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data0, >data3, >data0, >data4, >data0, >data3, >data0, >data4, >data0, >data3, >data0, >data4, >data0, >data5, >data0, >data4, >data0, >data3, >data0, >data4, >data0, >data3, >data0, >data2, >data0, >data3, >data0, >data2, >data0, >data1, >data0, >data2, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data0, >data3, >data0, >data2, >data0, >data3, >data0, >data2, >data0, >data1, >data0, >data2, >data0, >data3, >data0, >data2, >data0, >data3, >data0, >data2, >data0, >data3, >data0, >data2, >data7, >data8, >data7, >data8, >data7, >data8, >data7, >data8, >data7, >data8, >data7, >data8, >data7, >data8, >data7, >data8
data0:
.byte 8,8,8,8,8,8,8,208,8,8,8,8,8,8,8,208,8,8,8,8,8,8,8,208,8,8,8,8,8,8,8,208,8,8,8,8,8,8,8,208,8,8,8,8,8,8,8,208,8,8,8,8,8,8,8,208,8,8,8,8,8,8,8
data1:
.byte 0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,1,0,0,0,0,1,0,0,1,0,0,0,1,0,0,0,1,0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,1,0,0,0,0,0,0,2,0,0,0,0,0,0,0
data2:
.byte 2,2,2,2,2,2,3,241,2,2,2,2,2,3,2,241,2,2,2,2,3,2,2,241,2,2,2,3,2,2,2,241,2,2,3,2,2,2,2,241,2,3,2,2,2,2,2,241,3,2,2,2,2,2,2,242,2,2,2,2,2,2,2
data3:
.byte 0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0
data4:
.byte 2,2,2,2,2,2,2,242,2,2,2,2,2,2,3,241,2,2,2,2,2,3,2,241,2,2,2,2,3,2,2,241,2,2,2,3,2,2,2,241,2,2,3,2,2,2,2,241,2,3,2,2,2,2,2,241,3,2,2,2,2,2,2
data5:
.byte 0,0,0,0,0,0,0,2,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,1,0,0,0,0,1,0,0,1,0,0,0,1,0,0,0,1,0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,1,0,0,0,0,0,0
data6:
.byte 2,2,2,2,2,2,2,242,2,2,2,2,2,2,2,242,2,2,2,2,2,2,2,242,2,2,2,2,2,2,2,242,2,2,2,2,2,2,2,242,2,2,2,2,2,2,2,242,2,2,2,2,2,2,2,242,2,2,2,2,2,2,2
data7:
.byte 128,128,128,128,128,128,128,136,128,128,128,128,128,128,128,136,128,128,128,128,128,128,128,136,128,128,128,128,128,128,128,136,128,128,128,128,128,128,128,136,128,128,128,128,128,128,128,136,128,128,128,128,128,128,128,136,128,128,128,128,128,128,128
data8:
.byte 0,1,0,1,0,1,0,253,0,1,0,1,0,1,0,253,0,1,0,1,0,1,0,253,0,1,0,1,0,1,0,253,0,1,0,1,0,1,0,253,0,1,0,1,0,1,0,253,0,1,0,1,0,1,0,253,0,1,0,1,0,1,0
data9:
.byte 93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93,93
data10:
.byte 3,2,2,3,2,3,2,2,3,2,2,3,2,2,3,2,3,2,2,3,2,2,3,2,2,3,2,3,2,2,3,2,2,3,2,2,3,2,3,2,2,3,2,2,3,2,2,3,2,3,2,2,3,2,2,3,2,2,3,2,3,2,2

repeatData: 
.byte 185, 206, 225, 125, 206, 225, 38, 30, 185, 7, 224, 125, 199, 225, 38, 30, 185, 199, 225, 125, 7, 224, 38, 30, 185, 0, 224, 125, 0, 224, 165, 30, 42, 41, 15, 240, 6, 201, 15, 208, 27, 105, 239, 186, 157, 0, 32, 157, 1, 32, 157, 2, 32, 157, 3, 32, 157, 4, 32, 157, 5, 32, 157, 6, 32, 76, 216, 74, 133, 14, 185, 65, 224, 125, 1, 224, 38, 14, 185, 130, 224, 125, 2, 224, 38, 14, 185, 195, 224, 125, 3, 224, 38, 14, 185, 4, 225, 125, 4, 224, 38, 14, 185, 69, 225, 125, 5, 224, 38, 14, 185, 134, 225, 125, 6, 224, 38, 14, 185, 1, 224, 125, 65, 224, 38, 32, 185, 66, 224, 125, 66, 224, 38, 32, 185, 131, 224, 125, 67, 224, 38, 32, 185, 196, 224, 125, 68, 224, 38, 32, 185, 5, 225, 125, 69, 224, 38, 32, 185, 70, 225, 125, 70, 224, 38, 32, 185, 135, 225, 125, 71, 224, 38, 32, 185, 200, 225, 125, 72, 224, 38, 32, 185, 2, 224, 125, 130, 224, 38, 33, 185, 67, 224, 125, 131, 224, 38, 33, 185, 132, 224, 125, 132, 224, 38, 33, 185, 197, 224, 125, 133, 224, 38, 33, 185, 6, 225, 125, 134, 224, 38, 33, 185, 71, 225, 125, 135, 224, 38, 33, 185, 136, 225, 125, 136, 224, 38, 33, 185, 201, 225, 125, 137, 224, 38, 33, 185, 3, 224, 125, 195, 224, 38, 34, 185, 68, 224, 125, 196, 224, 38, 34, 185, 133, 224, 125, 197, 224, 38, 34, 185, 198, 224, 125, 198, 224, 38, 34, 185, 7, 225, 125, 199, 224, 38, 34, 185, 72, 225, 125, 200, 224, 38, 34, 185, 137, 225, 125, 201, 224, 38, 34, 185, 202, 225, 125, 202, 224, 38, 34, 185, 4, 224, 125, 4, 225, 38, 35, 185, 69, 224, 125, 5, 225, 38, 35, 185, 134, 224, 125, 6, 225, 38, 35, 185, 199, 224, 125, 7, 225, 38, 35, 185, 8, 225, 125, 8, 225, 38, 35, 185, 73, 225, 125, 9, 225, 38, 35, 185, 138, 225, 125, 10, 225, 38, 35, 185, 203, 225, 125, 11, 225, 38, 35, 185, 5, 224, 125, 69, 225, 38, 36, 185, 70, 224, 125, 70, 225, 38, 36, 185, 135, 224, 125, 71, 225, 38, 36, 185, 200, 224, 125, 72, 225, 38, 36, 185, 9, 225, 125, 73, 225, 38, 36, 185, 74, 225, 125, 74, 225, 38, 36, 185, 139, 225, 125, 75, 225, 38, 36, 185, 204, 225, 125, 76, 225, 38, 36, 185, 6, 224, 125, 134, 225, 38, 37, 185, 71, 224, 125, 135, 225, 38, 37, 185, 136, 224, 125, 136, 225, 38, 37, 185, 201, 224, 125, 137, 225, 38, 37, 185, 10, 225, 125, 138, 225, 38, 37, 185, 75, 225, 125, 139, 225, 38, 37, 185, 140, 225, 125, 140, 225, 38, 37, 185, 205, 225, 125, 141, 225, 38, 37, 70, 30, 70, 30, 38, 38, 185, 72, 224, 125, 200, 225, 38, 38, 185, 137, 224, 125, 201, 225, 38, 38, 185, 202, 224, 125, 202, 225, 38, 38, 185, 11, 225, 125, 203, 225, 38, 38, 185, 76, 225, 125, 204, 225, 38, 38, 185, 141, 225, 125, 205, 225, 38, 38, 186, 165, 14, 201, 128, 42, 157, 0, 32, 165, 32, 157, 1, 32, 165, 33, 157, 2, 32, 165, 34, 157, 3, 32, 165, 35, 157, 4, 32, 165, 36, 157, 5, 32, 165, 37, 157, 6, 32, 70, 30, 165, 38, 42, 157, 7, 32, 166, 19
}
