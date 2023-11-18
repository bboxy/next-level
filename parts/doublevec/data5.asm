plate0		= <($6140 / $40)	;206
plate1		= <($6740 / $40)	;206
plate2		= <($7140 / $40)	;203
plate3		= <($7740 / $40)	;207

* = $2000
!byte <spe_data0,>spe_data0,<spe_xstart0,>spe_xstart0,<spe_ystart0,>spe_ystart0
!byte <spe_data0,>spe_data0,<spe_xstart0,>spe_xstart0,<spe_ystart0,>spe_ystart0

;bg_col
!byte $00

;spr cols
!byte $03,$0e,$06
;spr chr
!byte $01,$0d,$05

!byte $01,$0c,$08
;plate #
!byte plate3

;x-offset plate
!byte 207

;pattl
!byte %00000000
!byte %00000000 ;25     %00010001
!byte %01000100 ;50     %00010001
!byte %01000100 ;75     %01010101
!byte %01010101 ;100    %01010101
!byte %01010101 ;25     %01100110
!byte %10011001 ;50     %01100110
!byte %10011001 ;75     %10101010
!byte %10101010 ;100    %10101010
!byte %10101010 ;25     %10111011
!byte %11101110 ;50     %10111011
!byte %11101110 ;75     %11111111
!byte %11111111 ;100    %11111111

;patth
!byte %00000000 xor %00000000   ;00
!byte %00000000 xor %00010001
!byte %01000100 xor %00010001
!byte %01000100 xor %01010101
!byte %01010101 xor %01010101   ;00
!byte %01010101 xor %01100110
!byte %10011001 xor %01100110
!byte %10011001 xor %10101010
!byte %10101010 xor %10101010   ;00
!byte %10101010 xor %10111011
!byte %11101110 xor %10111011
!byte %11101110 xor %11111111
!byte %11111111 xor %11111111   ;00

!src "cone.asm"
!byte $ff

!align 255,0
spe_xstart0		= -240
spe_ystart0		= -90
spe_numcoords0	= 608

;8 bit delta x,y interleaved

spe_data0
; !byte $00,$00,$00,$02,$00,$02,$00,$03,$00,$03,$00,$03,$00,$03,$00,$04,$01,$03,$00,$04,$00,$04,$00,$04,$00,$04,$00,$03,$00,$04,$00,$04
; !byte $00,$00,$00,$02,$00,$02,$00,$03,$00,$03,$01,$03,$00,$03,$00,$04,$00,$03,$00,$04,$00,$04,$00,$04,$01,$04,$00,$03,$00,$04,$00,$04
; !byte $00,$03,$00,$04,$00,$03,$00,$04,$00,$03,$00,$04,$00,$03,$00,$04,$00,$04,$00,$03,$00,$04,$00,$03,$00,$03,$00,$04,$00,$03,$00,$03
; !byte $00,$02,$00,$03,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$01,$00,$02,$00,$01,$00,$02,$00,$01,$00,$02,$00,$01,$00,$02
; !byte $00,$01,$00,$02,$00,$01,$00,$02,$00,$01,$01,$02,$00,$01,$00,$02,$00,$01,$00,$01,$00,$02,$01,$01,$00,$01,$00,$01,$00,$01,$01,$01
; !byte $00,$01,$00,$01,$01,$01,$00,$00,$00,$01,$01,$01,$00,$00,$01,$01,$00,$00,$01,$01,$00,$00,$01,$00,$00,$01,$01,$00,$00,$00,$01,$01
; !byte $00,$00,$01,$00,$00,$01,$01,$00,$00,$00,$01,$01,$00,$00,$01,$00,$01,$01,$00,$00,$01,$00,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00
; !byte $00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00
; !byte $00,$00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$01,$01,$00,$00,$00,$01,$00,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00,$01,$00,$01,$00
; !byte $00,$00,$01,$00,$01,$FF,$01,$00,$00,$FF,$01,$00,$01,$FF,$01,$00,$01,$FF,$01,$00,$00,$FF,$01,$FF,$01,$00,$01,$FF,$01,$FF,$01,$FF
; !byte $01,$00,$01,$FF,$01,$FF,$02,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$FF,$02,$FF,$01,$FF,$01,$FF,$02,$FF,$01,$FF
; !byte $02,$FF,$01,$FF,$02,$FF,$02,$FE,$01,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$01,$FF,$02,$00,$02,$FF,$02,$FF,$02,$00
; !byte $02,$00,$02,$00,$02,$00,$01,$00,$02,$00,$02,$01,$02,$00,$02,$01,$02,$00,$02,$01,$02,$01,$02,$01,$02,$01,$01,$00,$02,$01,$01,$01
; !byte $02,$01,$01,$02,$01,$01,$02,$01,$01,$01,$01,$02,$01,$01,$01,$02,$01,$02,$01,$01,$01,$02,$00,$01,$01,$02,$01,$02,$00,$01,$01,$02
; !byte $00,$02,$00,$02,$01,$01,$00,$02,$00,$02,$00,$02,$00,$01,$00,$02,$FF,$02,$00,$02,$00,$02,$FF,$02,$00,$02,$FF,$01,$00,$02,$FF,$02
; !byte $00,$02,$FF,$02,$FF,$02,$00,$02,$FF,$01,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$01,$FF,$02,$FE,$02,$FF,$02,$FF,$01
; !byte $FE,$02,$FF,$01,$FE,$02,$FE,$02,$FF,$01,$FE,$02,$FE,$01,$FE,$01,$FE,$02,$FE,$01,$FE,$02,$FE,$01,$FE,$01,$FE,$01,$FD,$01,$FE,$02
; !byte $FE,$01,$FD,$01,$FD,$01,$FE,$01,$FD,$01,$FD,$00,$FD,$01,$FD,$01,$FD,$01,$FD,$00,$FD,$01,$FD,$01,$FD,$00,$FD,$01,$FD,$00,$FD,$01
; !byte $FD,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$FF,$FD,$00,$FD,$00
; !byte $FD,$00,$FD,$00,$FD,$FF,$FD,$00,$FC,$00,$FD,$00,$FD,$FF,$FD,$00,$FC,$00,$FD,$FF,$FD,$00,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF
; !byte $FD,$FF,$FD,$FF,$FD,$FF,$FD,$FE,$FD,$FF,$FE,$FE,$FD,$FE,$FD,$FF,$FD,$FE,$FE,$FE,$FD,$FE,$FE,$FE,$FD,$FE,$FE,$FD,$FE,$FE,$FE,$FE
; !byte $FF,$FD,$FE,$FE,$FF,$FD,$FE,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FC,$FF,$FD,$FF,$FD,$00,$FD,$FF,$FD,$00,$FC,$00,$FD,$00,$FD,$01,$FE
; !byte $01,$FD,$01,$FD,$01,$FD,$01,$FE,$02,$FD,$02,$FD,$02,$FE,$02,$FD,$02,$FD,$02,$FE,$03,$FE,$02,$FD,$03,$FE,$02,$FE,$03,$FF,$02,$FE
; !byte $03,$FF,$03,$FF,$03,$FF,$03,$FF,$03,$FF,$03,$00,$03,$FF,$03,$00,$03,$00,$04,$FF,$03,$00,$03,$00,$03,$01,$03,$00,$03,$00,$03,$01
; !byte $03,$01,$03,$00,$03,$01,$03,$01,$03,$01,$03,$02,$03,$01,$03,$02,$02,$01,$03,$02,$03,$02,$02,$01,$03,$02,$03,$02,$02,$02,$03,$02
; !byte $02,$02,$02,$02,$03,$02,$02,$02,$02,$02,$03,$02,$02,$02,$02,$03,$02,$02,$02,$02,$02,$03,$02,$02,$02,$03,$02,$02,$01,$03,$02,$03
; !byte $01,$02,$02,$03,$01,$03,$01,$03,$01,$03,$01,$02,$01,$03,$01,$03,$01,$03,$01,$03,$00,$04,$01,$03,$01,$03,$00,$03,$01,$03,$01,$03
; !byte $01,$03,$00,$03,$01,$03,$01,$03,$00,$03,$01,$03,$01,$03,$00,$03,$01,$03,$00,$03,$01,$03,$00,$03,$01,$04,$00,$03,$01,$03,$00,$03
; !byte $00,$03,$01,$03,$00,$03,$00,$03,$00,$03,$01,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$04,$01,$03,$00,$03,$00,$03,$00,$03,$00,$03
; !byte $00,$03,$00,$03,$00,$04,$00,$03,$00,$04,$00,$03,$00,$04,$00,$04,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$02,$00,$02,$00,$02
; !byte $80
spe_data0
; !byte $00,$00,$FF,$00,$FE,$00,$FE,$01,$FE,$00,$FD,$00,$FE,$01,$FD,$00,$FE,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$01
; !byte $FD,$00,$FD,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$00,$FC,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$00,$FC,$01,$FD,$00,$FD,$00,$FD,$00,$FD,$01
; !byte $FD,$00,$FD,$00,$FD,$01,$FD,$00,$FD,$00,$FE,$01,$FD,$00,$FD,$01,$FE,$00,$FD,$00,$FD,$01,$FE,$00,$FD,$01,$FD,$00,$FD,$00,$FE,$01
; !byte $FD,$00,$FD,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$01,$FD,$00
; !byte $FD,$00,$FD,$00,$FD,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$01,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$00
; !byte $FD,$00,$FE,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$FF,$FD,$00,$FD,$00,$FD,$00,$FD,$00,$FD,$FF,$FD,$00,$FD,$00,$FE,$00,$FD,$FF,$FD,$00
; !byte $FD,$00,$FE,$00,$FD,$FF,$FE,$00,$FD,$00,$FD,$FF,$FE,$00,$FD,$FF,$FE,$00,$FD,$00,$FE,$FF,$FD,$00,$FE,$00,$FE,$FF,$FD,$00,$FE,$00
; !byte $FD,$00,$FE,$00,$FE,$00,$FD,$00,$FE,$00,$FD,$00,$FE,$00,$FE,$00,$FD,$00,$FE,$00,$FE,$01,$FD,$00,$FE,$00,$FE,$01,$FE,$00,$FE,$01
; !byte $FD,$00,$FE,$01,$FE,$00,$FE,$01,$FE,$01,$FE,$01,$FE,$01,$FE,$01,$FE,$01,$FE,$01,$FE,$01,$FF,$01,$FE,$01,$FE,$01,$FF,$01,$FE,$01
; !byte $FF,$01,$FE,$02,$FF,$01,$FF,$01,$FE,$01,$FF,$01,$FF,$02,$FF,$01,$FF,$01,$FF,$02,$FF,$01,$FF,$01,$FF,$02,$00,$01,$FF,$02,$FF,$01
; !byte $00,$02,$FF,$01,$00,$02,$00,$01,$FF,$02,$00,$02,$00,$01,$00,$02,$00,$02,$00,$01,$00,$02,$00,$02,$00,$01,$00,$02,$01,$02,$00,$01
; !byte $00,$02,$00,$01,$01,$02,$00,$01,$01,$02,$00,$01,$01,$02,$00,$01,$01,$01,$01,$02,$01,$01,$00,$01,$01,$02,$01,$01,$01,$01,$01,$01
; !byte $00,$01,$01,$02,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$02,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01
; !byte $02,$00,$01,$01,$01,$00,$01,$00,$01,$01,$02,$00,$01,$00,$01,$00,$01,$01,$02,$00,$01,$00,$01,$00,$01,$00,$02,$00,$01,$00,$01,$00
; !byte $02,$00,$01,$00,$01,$00,$02,$00,$01,$00,$01,$00,$02,$00,$01,$00,$02,$00,$01,$00,$01,$00,$02,$00,$01,$FF,$02,$00,$01,$00,$01,$FF
; !byte $02,$00,$01,$FF,$02,$FF,$01,$00,$02,$FF,$01,$FF,$02,$FF,$01,$FF,$02,$FF,$01,$FF,$01,$FF,$02,$FF,$01,$FF,$02,$FF,$01,$FE,$01,$FF
; !byte $02,$FF,$01,$FF,$01,$FF,$02,$FF,$01,$FF,$01,$FF,$01,$FF,$02,$FE,$01,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$FF,$02,$FF,$01,$FF
; !byte $01,$00,$01,$FF,$01,$FF,$00,$00,$01,$FF,$01,$00,$01,$FF,$01,$00,$01,$00,$01,$FF,$00,$00,$01,$00,$01,$00,$01,$FF,$01,$00,$01,$00
; !byte $01,$00,$01,$00,$00,$00,$01,$00,$01,$00,$01,$FF,$01,$00,$01,$00,$01,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$02,$00
; !byte $01,$00,$01,$00,$01,$00,$01,$00,$02,$00,$01,$00,$01,$00,$02,$00,$01,$00,$01,$00,$02,$00,$01,$01,$01,$00,$02,$00,$01,$00,$02,$01
; !byte $01,$00,$02,$01,$01,$01,$02,$00,$01,$01,$02,$01,$01,$00,$02,$01,$02,$01,$01,$01,$02,$01,$01,$01,$02,$01,$01,$01,$01,$01,$02,$01
; !byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$02,$00,$01,$01,$01,$01,$01,$00,$01,$01,$02
; !byte $00,$01,$01,$01,$01,$02,$00,$01,$00,$01,$01,$02,$00,$01,$01,$02,$00,$01,$00,$01,$01,$02,$00,$01,$00,$02,$00,$01,$01,$01,$00,$02
; !byte $00,$01,$00,$01,$01,$02,$00,$01,$00,$01,$00,$02,$01,$01,$00,$01,$00,$02,$00,$01,$00,$01,$00,$02,$01,$01,$00,$01,$00,$01,$00,$02
; !byte $00,$01,$00,$01,$00,$02,$01,$01,$00,$01,$00,$01,$00,$02,$00,$01,$00,$01,$00,$01,$00,$02,$01,$01,$00,$01,$00,$02,$00,$01,$00,$02
; !byte $00,$01,$00,$02,$00,$02,$00,$01,$01,$02,$00,$02,$00,$01,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$01,$01,$00,$02,$00,$02,$00,$02
; !byte $00,$02,$00,$01,$00,$02,$00,$02,$01,$02,$00,$02,$00,$01,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$01,$02,$00,$02,$00,$02,$00,$02
; !byte $00,$02,$00,$03,$01,$02,$00,$03,$00,$03,$00,$03,$00,$02,$01,$03,$00,$03,$00,$03,$00,$02,$00,$03,$01,$02,$00,$02,$00,$02,$00,$01
; !byte $80
 !byte $00,$00,$01,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$01,$03,$00,$02,$00,$03,$00,$03,$00,$02,$00,$03,$00,$03,$01,$02,$00,$03,$00
 !byte $02,$00,$02,$00,$03,$00,$02,$00,$03,$00,$02,$01,$02,$00,$03,$00,$02,$00,$02,$00,$03,$00,$02,$00,$02,$00,$03,$01,$02,$00,$02,$00
 !byte $02,$00,$02,$00,$02,$00,$02,$01,$02,$00,$02,$00,$02,$00,$01,$00,$02,$01,$02,$00,$02,$00,$01,$00,$02,$00,$02,$01,$02,$00,$02,$00
 !byte $02,$00,$02,$00,$03,$00,$02,$00,$02,$01,$03,$00,$02,$00,$03,$00,$03,$00,$02,$00,$03,$00,$02,$00,$03,$00,$02,$01,$03,$00,$02,$00
 !byte $02,$00,$03,$00,$02,$00,$02,$01,$02,$00,$03,$00,$02,$00,$02,$00,$02,$01,$02,$00,$03,$00,$02,$00,$02,$00,$02,$01,$02,$00,$02,$00
 !byte $02,$00,$02,$00,$03,$00,$02,$00,$02,$01,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$01,$02,$00,$02,$00,$02,$00,$01,$00
 !byte $02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$02,$00,$01,$00,$02,$00,$02,$00,$02,$01,$02,$00,$01,$00,$02,$00,$02,$00,$02,$00
 !byte $01,$00,$02,$00,$02,$00,$02,$00,$02,$01,$01,$00,$02,$00,$02,$00,$02,$00,$02,$01,$01,$00,$02,$00,$02,$00,$02,$00,$01,$01,$02,$00
 !byte $01,$00,$02,$00,$01,$00,$02,$01,$01,$00,$02,$00,$01,$00,$02,$00,$01,$01,$01,$00,$02,$00,$01,$00,$01,$00,$01,$00,$02,$01,$01,$00
 !byte $01,$00,$02,$00,$01,$00,$01,$01,$02,$00,$01,$00,$01,$00,$02,$00,$01,$00,$01,$01,$01,$00,$02,$00,$01,$00,$01,$00,$01,$01,$01,$00
 !byte $01,$00,$01,$00,$01,$01,$01,$00,$01,$00,$01,$00,$01,$01,$01,$00,$01,$00,$01,$01,$01,$00,$01,$00,$01,$01,$01,$00,$01,$00,$00,$01
 !byte $01,$00,$01,$01,$01,$00,$01,$00,$01,$01,$01,$00,$01,$01,$01,$00,$01,$00,$00,$01,$01,$00,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01
 !byte $00,$00,$01,$01,$01,$00,$01,$01,$01,$00,$00,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$00,$00,$01,$01,$01,$01
 !byte $00,$00,$01,$01,$00,$01,$01,$01,$01,$00,$00,$01,$01,$01,$00,$01,$01,$01,$00,$00,$01,$01,$00,$01,$01,$01,$00,$01,$00,$01,$01,$01
 !byte $00,$00,$01,$01,$00,$01,$00,$01,$00,$01,$01,$01,$00,$01,$00,$00,$00,$01,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$01,$00,$01
 !byte $00,$00,$00,$01,$01,$01,$00,$01,$00,$01,$00,$01,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01
 !byte $00,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$FF,$01,$00,$00,$00,$01,$00,$01,$00,$01,$FF,$00,$00,$01,$00,$01,$00,$00,$FF,$01
 !byte $00,$00,$FF,$01,$00,$00,$FF,$01,$00,$00,$FF,$01,$00,$00,$FF,$00,$00,$00,$FF,$01,$FF,$00,$00,$00,$FF,$00,$FF,$01,$00,$00,$FF,$00
 !byte $00,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$FF,$00
 !byte $FF,$00,$00,$00,$FF,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$FF,$00,$FF,$FF,$FF,$00,$00,$FF,$FF,$00,$FF,$FF,$FF,$00,$FE,$00,$FF,$FF
 !byte $FF,$00,$FF,$FF,$FF,$00,$FE,$FF,$FF,$00,$FE,$FF,$FF,$00,$FE,$FF,$FF,$00,$FE,$FF,$FF,$00,$FE,$FF,$FE,$00,$FF,$FF,$FE,$00,$FE,$FF
 !byte $FF,$00,$FE,$FF,$FE,$00,$FE,$FF,$FF,$00,$FE,$00,$FE,$FF,$FE,$00,$FE,$FF,$FE,$00,$FE,$00,$FE,$FF,$FE,$00,$FE,$00,$FE,$FF,$FE,$00
 !byte $FE,$00,$FE,$00,$FE,$FF,$FE,$00,$FE,$00,$FE,$00,$FD,$FF,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FD,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00
 !byte $FE,$00,$FF,$00,$FE,$00,$FE,$00,$FE,$01,$FF,$00,$FE,$00,$FE,$00,$FF,$00,$FE,$01,$FE,$00,$FF,$01,$FE,$00,$FF,$01,$FF,$01,$FE,$01
 !byte $FF,$01,$FF,$01,$FE,$01,$FF,$02,$FF,$01,$FF,$02,$FE,$01,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$FF,$02,$00,$02,$FF,$02,$FF,$02
 !byte $FF,$02,$00,$02,$FF,$02,$00,$02,$00,$03,$FF,$02,$00,$02,$00,$03,$00,$02,$00,$03,$FF,$03,$00,$02,$00,$03,$00,$03,$00,$03,$00,$03
 !byte $00,$03,$00,$03,$00,$03,$00,$04,$00,$03,$00,$04,$01,$03,$00,$04,$00,$04,$00,$03,$00,$04,$01,$04,$00,$04,$00,$03,$00,$04,$00,$04
 !byte $00,$04,$00,$04,$00,$04,$00,$05,$00,$04,$00,$05,$00,$04,$00,$05,$00,$04,$FF,$05,$00,$04,$00,$04,$00,$03,$00,$03,$00,$03,$00,$02
 !byte $80
;NumPoints(0) = 39
;points(0,0)\x = 207
;points(0,0)\y = 70
;points(0,1)\x = 235
;points(0,1)\y = 126
;points(0,2)\x = 264
;points(0,2)\y = 189
;points(0,3)\x = 296
;points(0,3)\y = 247
;points(0,4)\x = 327
;points(0,4)\y = 279
;points(0,5)\x = 379
;points(0,5)\y = 306
;points(0,6)\x = 445
;points(0,6)\y = 319
;points(0,7)\x = 505
;points(0,7)\y = 325
;points(0,8)\x = 573
;points(0,8)\y = 326
;points(0,9)\x = 633
;points(0,9)\y = 320
;points(0,10)\x = 685
;points(0,10)\y = 292
;points(0,11)\x = 695
;points(0,11)\y = 224
;points(0,12)\x = 659
;points(0,12)\y = 186
;points(0,13)\x = 587
;points(0,13)\y = 184
;points(0,14)\x = 530
;points(0,14)\y = 209
;points(0,15)\x = 466
;points(0,15)\y = 247
;points(0,16)\x = 443
;points(0,16)\y = 283
;points(0,17)\x = 441
;points(0,17)\y = 350
;points(0,18)\x = 468
;points(0,18)\y = 383
;points(0,19)\x = 540
;points(0,19)\y = 405
;points(0,20)\x = 627
;points(0,20)\y = 407
;points(0,21)\x = 663
;points(0,21)\y = 386
;points(0,22)\x = 651
;points(0,22)\y = 342
;points(0,23)\x = 578
;points(0,23)\y = 313
;points(0,24)\x = 527
;points(0,24)\y = 332
;points(0,25)\x = 466
;points(0,25)\y = 358
;points(0,26)\x = 406
;points(0,26)\y = 369
;points(0,27)\x = 369
;points(0,27)\y = 357
;points(0,28)\x = 337
;points(0,28)\y = 327
;points(0,29)\x = 323
;points(0,29)\y = 265
;points(0,30)\x = 343
;points(0,30)\y = 213
;points(0,31)\x = 385
;points(0,31)\y = 175
;points(0,32)\x = 450
;points(0,32)\y = 164
;points(0,33)\x = 496
;points(0,33)\y = 216
;points(0,34)\x = 524
;points(0,34)\y = 283
;points(0,35)\x = 520
;points(0,35)\y = 351
;points(0,36)\x = 507
;points(0,36)\y = 405
;points(0,37)\x = 479
;points(0,37)\y = 447
;points(0,38)\x = 452
;points(0,38)\y = 503

