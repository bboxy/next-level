
.macro addToLabel16(value16, label){
	lda label + 1
	clc
	adc #<value16
	sta label +1
	lda label + 2
	adc #>value16
	sta label +2
}
.macro incLabel(label){
	inc label +1
	bne !+
	inc label +2
	!:
}

.pseudopc $e000{
.var chunklength = 606
.var dataDestination = $3280
copySpeedCode:
ldx #$40
ldy #$00
!:
lda repeatData+ $100*0,y
!a:
sta dataDestination + $100*0,y
lda repeatData+ $100*1,y
!b:
sta dataDestination+ $100*1,y
lda repeatData+ $100*2,y
!c:
sta dataDestination+ $100*2,y
lda repeatData+ $100*2 +($70),y
!d:
sta dataDestination+ $100*2+($70),y
iny
bne !-
:addToLabel16(chunklength, !a-)
:addToLabel16(chunklength, !b-)
:addToLabel16(chunklength, !c-)
:addToLabel16(chunklength, !d-)
dex
bne !-
lda #$4c
sta dataDestination + chunklength*$40
lda #<create_back
sta dataDestination + chunklength*$40 + 1
lda #>create_back
sta dataDestination + chunklength*$40 + 2

propagateDiffs:
outerCounter:
.byte $ad, <278, >278 //lda $0064//changeLookupAddressesHB[0].length


lookup1:
lda changeLookupAddressesLB
sta addValue +1
lookup2:
lda changeLookupAddressesHB
sta addValue +2

dirty1:
lda dirtyAddressesLB
sta setValue +1
sta fetch +1
dirty2:
lda dirtyAddressesHB
sta setValue +2
sta fetch +2
:addToLabel16(chunklength, setValue)


lda #< 63//binary.length/chunksize
sta countDown +1
lda #> 63//binary.length/chunksize
sta countDown +2

countDown:
.byte $ad, $10, $00 //lda $0064//changeLookupAddressesHB[0].length

fetch:
lda $2000
addValue:
adc $2000
setValue:
sta $2000
:addToLabel16(chunklength, fetch)
:addToLabel16(chunklength, setValue)
:incLabel(addValue)
dec countDown +1
bne fetch
dec countDown +2
lda countDown +2
cmp #$ff
bne fetch
:incLabel(lookup1)
:incLabel(lookup2)
:incLabel(dirty1)
:incLabel(dirty2)
dec outerCounter +1
beq !+
jmp lookup1
!:
dec outerCounter +2
lda outerCounter +2
cmp #$ff
bne !+
rts
!:
jmp lookup1


repeatData: 
.byte 185, 206, 225, 125, 206, 225, 38, 30, 185, 7, 224, 125, 199, 225, 38, 30, 185, 199, 225, 125, 7, 224, 38, 30, 185, 0, 224, 125, 0, 224, 165, 30, 42, 133, 14, 41, 15, 208, 18, 166, 12, 160, 8, 157, 0, 32, 232, 136, 208, 249, 164, 18, 166, 19, 76, 240, 52, 201, 15, 208, 5, 169, 255, 76, 167, 50, 185, 65, 224, 125, 1, 224, 38, 14, 185, 130, 224, 125, 2, 224, 38, 14, 185, 195, 224, 125, 3, 224, 38, 14, 185, 4, 225, 125, 4, 224, 38, 14, 185, 69, 225, 125, 5, 224, 38, 14, 185, 134, 225, 125, 6, 224, 38, 14, 165, 14, 201, 128, 42, 166, 12, 157, 0, 32, 166, 19, 185, 1, 224, 125, 65, 224, 38, 14, 185, 66, 224, 125, 66, 224, 38, 14, 185, 131, 224, 125, 67, 224, 38, 14, 185, 196, 224, 125, 68, 224, 38, 14, 185, 5, 225, 125, 69, 224, 38, 14, 185, 70, 225, 125, 70, 224, 38, 14, 185, 135, 225, 125, 71, 224, 38, 14, 185, 200, 225, 125, 72, 224, 165, 14, 42, 166, 12, 157, 1, 32, 166, 19, 185, 2, 224, 125, 130, 224, 38, 14, 185, 67, 224, 125, 131, 224, 38, 14, 185, 132, 224, 125, 132, 224, 38, 14, 185, 197, 224, 125, 133, 224, 38, 14, 185, 6, 225, 125, 134, 224, 38, 14, 185, 71, 225, 125, 135, 224, 38, 14, 185, 136, 225, 125, 136, 224, 38, 14, 185, 201, 225, 125, 137, 224, 165, 14, 42, 166, 12, 157, 2, 32, 166, 19, 185, 3, 224, 125, 195, 224, 38, 14, 185, 68, 224, 125, 196, 224, 38, 14, 185, 133, 224, 125, 197, 224, 38, 14, 185, 198, 224, 125, 198, 224, 38, 14, 185, 7, 225, 125, 199, 224, 38, 14, 185, 72, 225, 125, 200, 224, 38, 14, 185, 137, 225, 125, 201, 224, 38, 14, 185, 202, 225, 125, 202, 224, 165, 14, 42, 166, 12, 157, 3, 32, 166, 19, 185, 4, 224, 125, 4, 225, 38, 14, 185, 69, 224, 125, 5, 225, 38, 14, 185, 134, 224, 125, 6, 225, 38, 14, 185, 199, 224, 125, 7, 225, 38, 14, 185, 8, 225, 125, 8, 225, 38, 14, 185, 73, 225, 125, 9, 225, 38, 14, 185, 138, 225, 125, 10, 225, 38, 14, 185, 203, 225, 125, 11, 225, 165, 14, 42, 166, 12, 157, 4, 32, 166, 19, 185, 5, 224, 125, 69, 225, 38, 14, 185, 70, 224, 125, 70, 225, 38, 14, 185, 135, 224, 125, 71, 225, 38, 14, 185, 200, 224, 125, 72, 225, 38, 14, 185, 9, 225, 125, 73, 225, 38, 14, 185, 74, 225, 125, 74, 225, 38, 14, 185, 139, 225, 125, 75, 225, 38, 14, 185, 204, 225, 125, 76, 225, 165, 14, 42, 166, 12, 157, 5, 32, 166, 19, 185, 6, 224, 125, 134, 225, 38, 14, 185, 71, 224, 125, 135, 225, 38, 14, 185, 136, 224, 125, 136, 225, 38, 14, 185, 201, 224, 125, 137, 225, 38, 14, 185, 10, 225, 125, 138, 225, 38, 14, 185, 75, 225, 125, 139, 225, 38, 14, 185, 140, 225, 125, 140, 225, 38, 14, 185, 205, 225, 125, 141, 225, 165, 14, 42, 166, 12, 157, 6, 32, 166, 19, 70, 30, 70, 30, 38, 14, 185, 72, 224, 125, 200, 225, 38, 14, 185, 137, 224, 125, 201, 225, 38, 14, 185, 202, 224, 125, 202, 225, 38, 14, 185, 11, 225, 125, 203, 225, 38, 14, 185, 76, 225, 125, 204, 225, 38, 14, 185, 141, 225, 125, 205, 225, 38, 14, 70, 30, 165, 14, 42, 166, 12, 157, 7, 32, 166, 19

dirtyAddressesHB: 
.byte $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $33, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34
dirtyAddressesLB: 
.byte $81, $82, $84, $85, $89, $8a, $8c, $8d, $91, $92, $94, $95, $99, $9a, $9c, $9d, $ac, $ad, $b7, $b8, $c0, $c1, $c3, $c4, $c6, $c7, $cb, $cc, $ce, $cf, $d3, $d4, $d6, $d7, $db, $dc, $de, $df, $e3, $e4, $e6, $e7, $eb, $ec, $ee, $ef, $fa, $fb, $ff, $0, $2, $3, $7, $8, $a, $b, $f, $10, $12, $13, $17, $18, $1a, $1b, $1f, $20, $22, $23, $27, $28, $2a, $2b, $2f, $30, $32, $33, $37, $38, $3a, $3b, $42, $43, $47, $48, $4a, $4b, $4f, $50, $52, $53, $57, $58, $5a, $5b, $5f, $60, $62, $63, $67, $68, $6a, $6b, $6f, $70, $72, $73, $77, $78, $7a, $7b, $7f, $80, $82, $83, $8a, $8b, $8f, $90, $92, $93, $97, $98, $9a, $9b, $9f, $a0, $a2, $a3, $a7, $a8, $aa, $ab, $af, $b0, $b2, $b3, $b7, $b8, $ba, $bb, $bf, $c0, $c2, $c3, $c7, $c8, $ca, $cb, $d2, $d3, $d7, $d8, $da, $db, $df, $e0, $e2, $e3, $e7, $e8, $ea, $eb, $ef, $f0, $f2, $f3, $f7, $f8, $fa, $fb, $ff, $0, $2, $3, $7, $8, $a, $b, $f, $10, $12, $13, $1a, $1b, $1f, $20, $22, $23, $27, $28, $2a, $2b, $2f, $30, $32, $33, $37, $38, $3a, $3b, $3f, $40, $42, $43, $47, $48, $4a, $4b, $4f, $50, $52, $53, $57, $58, $5a, $5b, $62, $63, $67, $68, $6a, $6b, $6f, $70, $72, $73, $77, $78, $7a, $7b, $7f, $80, $82, $83, $87, $88, $8a, $8b, $8f, $90, $92, $93, $97, $98, $9a, $9b, $9f, $a0, $a2, $a3, $aa, $ab, $b5, $b6, $b8, $b9, $bd, $be, $c0, $c1, $c5, $c6, $c8, $c9, $cd, $ce, $d0, $d1, $d5, $d6, $d8, $d9, $dd, $de, $e0, $e1, $ec, $ed
changeLookupAddressesLB: 
.byte <data0, <data1, <data0, <data2, <data0, <data3, <data0, <data4, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data7, <data8, <data9, <data10, <data9, <data11, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data7, <data8, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data7, <data8, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data7, <data8, <data0, <data3, <data0, <data4, <data0, <data3, <data0, <data4, <data0, <data3, <data0, <data4, <data0, <data5, <data0, <data4, <data0, <data3, <data0, <data4, <data0, <data3, <data0, <data2, <data0, <data3, <data0, <data2, <data0, <data1, <data0, <data2, <data7, <data8, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data5, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data7, <data8, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data7, <data8, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data3, <data0, <data6, <data0, <data1, <data0, <data6, <data7, <data8, <data0, <data3, <data0, <data2, <data0, <data3, <data0, <data2, <data0, <data1, <data0, <data2, <data0, <data3, <data0, <data2, <data0, <data3, <data0, <data2, <data0, <data3, <data0, <data2, <data7, <data8
changeLookupAddressesHB: 
.byte >data0, >data1, >data0, >data2, >data0, >data3, >data0, >data4, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data7, >data8, >data9, >data10, >data9, >data11, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data7, >data8, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data7, >data8, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data7, >data8, >data0, >data3, >data0, >data4, >data0, >data3, >data0, >data4, >data0, >data3, >data0, >data4, >data0, >data5, >data0, >data4, >data0, >data3, >data0, >data4, >data0, >data3, >data0, >data2, >data0, >data3, >data0, >data2, >data0, >data1, >data0, >data2, >data7, >data8, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data5, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data7, >data8, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data7, >data8, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data3, >data0, >data6, >data0, >data1, >data0, >data6, >data7, >data8, >data0, >data3, >data0, >data2, >data0, >data3, >data0, >data2, >data0, >data1, >data0, >data2, >data0, >data3, >data0, >data2, >data0, >data3, >data0, >data2, >data0, >data3, >data0, >data2, >data7, >data8
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
.byte 112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112
data10:
.byte 3,2,3,2,3,2,3,2,2,3,2,3,2,3,2,2,3,2,3,2,3,2,3,2,2,3,2,3,2,3,2,2,3,2,3,2,3,2,3,2,2,3,2,3,2,3,2,2,3,2,3,2,3,2,3,2,2,3,2,3,2,3,2
data11:
.byte 3,2,2,3,2,3,2,3,2,3,2,2,3,2,3,2,3,2,2,3,2,3,2,3,2,3,2,2,3,2,3,2,3,2,2,3,2,3,2,3,2,3,2,2,3,2,3,2,3,2,2,3,2,3,2,3,2,3,2,2,3,2,3
}
