  !cpu 6510
  !initmem $00
;release      equ 0



;Used memory right now:
;$0800 - $0d00  gets trashed.

;$e000 - $e713
;$eb5c - $f1a0
;$f1a1 - $f6a1   code that gets moved to $0800-$0cff
;$f700 - $f780

;...but this code unpacks at $e000-$f800, and then moves code into $0800-$0cff
;Start address is $f700


byte_A5 = $a5;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:loc_A5C↓r
                                              ; RAM:0A61↓w ...
byte_A6 = $A6;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:0A65↓w
                                              ; sub_CAB+38↓w
byte_A7 = $A7;        !BYTE 0 ; (uninited)    ; DATA XREF: sub_B1D+20↓w
                                              ; sub_B1D+38↓w ...
byte_A8 = $A8;        !BYTE 0 ; (uninited)    ; DATA XREF: sub_B1D+3C↓w
                                              ; sub_CAB+22↓w
byte_A9 = $A9;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:09DC↓w
                                              ; RAM:0ACE↓w ...
byte_AA = $AA;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:09E9↓w
                                              ; RAM:0AD2↓w ...
byte_AB = $AB;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:0A7F↓w
byte_AC = $AC;        !BYTE 0 ; (uninited)    ; DATA XREF: sub_C2F+16↓w
byte_AD = $AD;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:088E↓w
                                              ; RAM:0901↓w
byte_AE = $AE;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:08AF↓w
                                              ; RAM:0903↓w
byte_AF = $AF;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:loc_8B8↓r
                                              ; RAM:08CE↓w ...

byte_D1 = $d1;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:loc_83AE↓w
byte_D4 = $D4;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:loc_83A7↓r
byte_D5 = $D5;        !BYTE 0 ; (uninited)    ; DATA XREF: RAM:83A2↓r
byte_E0 = $E0;        !BYTE 0 ; (uninited)    ; DATA XREF: sub_7F6D+1↓r
                                              ; sub_7F6D+6↓r
byte_FC = $FC;        !BYTE 0 ; (uninited)    ; CODE XREF: RAM:839D↓p
                              ; 0 !BYTE uninited & unexplored
                              ; 0 !BYTE uninited & unexplored



* = $e000
                 !BYTE $20        ;E000
                 !BYTE   0        ;E001
                 !BYTE $A6        ;E002
                 !BYTE   2        ;E003
                 !BYTE $A8        ;E004
                 !BYTE   0        ;E005
                 !BYTE $1A        ;E006
                 !BYTE   3        ;E007
                 !BYTE $D2        ;E008
                 !BYTE   0        ;E009
                 !BYTE $5E ; ^    ;E00A
                 !BYTE   3        ;E00B
                 !BYTE $F2        ;E00C
                 !BYTE   0        ;E00D
                 !BYTE $92        ;E00E
                 !BYTE   3        ;E00F

;not needed:
;                 !BYTE $34 ; 4    ;E010
;                 !BYTE   1        ;E011
;                 !BYTE $C6        ;E012
;                 !BYTE   3        ;E013
;                 !BYTE $54 ; T    ;E014
;                 !BYTE   1        ;E015
;                 !BYTE $E6        ;E016
;                 !BYTE   3        ;E017
;                 !BYTE $88        ;E018
;                 !BYTE   1        ;E019
;                 !BYTE $6E ; n    ;E01A
;                 !BYTE   4        ;E01B
;                 !BYTE $8A        ;E01C
;                 !BYTE   1        ;E01D
;                 !BYTE $76 ; v    ;E01E
;                 !BYTE   4        ;E01F
;                 !BYTE $2D ; -    ;E020
;                 !BYTE   5        ;E021
;                 !BYTE $2B ; +    ;E022
;                 !BYTE $C5        ;E023
;                 !BYTE $21 ; !    ;E024
;                 !BYTE $C6        ;E025
;                 !BYTE $1B        ;E026
;                 !BYTE $D6        ;E027
;                 !BYTE $17        ;E028
;                 !BYTE $D5        ;E029
;                 !BYTE $11        ;E02A
;                 !BYTE $B7        ;E02B
;                 !BYTE $13        ;E02C
;                 !BYTE $A7        ;E02D
;                 !BYTE   5        ;E02E
;                 !BYTE $EA        ;E02F
;                 !BYTE  $D        ;E030
;                 !BYTE $D8        ;E031
;                 !BYTE  $F        ;E032
;                 !BYTE $D8        ;E033
;                 !BYTE $11        ;E034
;                 !BYTE $77 ; w    ;E035
;                 !BYTE  $F        ;E036
;                 !BYTE $B7        ;E037
;                 !BYTE  $D        ;E038
;                 !BYTE $B7        ;E039
;                 !BYTE  $B        ;E03A
;                 !BYTE $17        ;E03B
;                 !BYTE  $D        ;E03C
;                 !BYTE $77 ; w    ;E03D
;                 !BYTE  $E        ;E03E
;                 !BYTE $F7        ;E03F
;                 !BYTE $11        ;E040
;                 !BYTE $B7        ;E041
;                 !BYTE $11        ;E042
;                 !BYTE $D8        ;E043
;                 !BYTE $12        ;E044
;                 !BYTE $F7        ;E045
;                 !BYTE $13        ;E046
;                 !BYTE $B8        ;E047
;                 !BYTE $17        ;E048
;                 !BYTE $B8        ;E049
;                 !BYTE $1B        ;E04A
;                 !BYTE $68 ; h    ;E04B
;                 !BYTE $21 ; !    ;E04C
;                 !BYTE $48 ; H    ;E04D
;                 !BYTE $2D ; -    ;E04E
;                 !BYTE $89        ;E04F
;                 !BYTE $2C ; ,    ;E050
;                 !BYTE $78 ; x    ;E051
;                 !BYTE $2F ; /    ;E052
;                 !BYTE $28 ; (    ;E053
;                 !BYTE $3F ; ?    ;E054
;                 !BYTE $67 ; g    ;E055
;                 !BYTE $3D ; =    ;E056
;                 !BYTE $A5        ;E057
;                 !BYTE $29 ; )    ;E058
;                 !BYTE $98        ;E059
;                 !BYTE $2E ; .    ;E05A
;                 !BYTE $F6        ;E05B
;                 !BYTE $21 ; !    ;E05C
;                 !BYTE $E5        ;E05D
;                 !BYTE $1D        ;E05E
;                 !BYTE $B6        ;E05F
;                 !BYTE $19        ;E060
;                 !BYTE $96        ;E061
;                 !BYTE $13        ;E062
;                 !BYTE $B6        ;E063
;                 !BYTE  $F        ;E064
;                 !BYTE $E7        ;E065
;                 !BYTE  $F        ;E066
;                 !BYTE $76 ; v    ;E067
;                 !BYTE   7        ;E068
;                 !BYTE $D7        ;E069
;                 !BYTE   9        ;E06A
;                 !BYTE $D8        ;E06B
;                 !BYTE  $D        ;E06C
;                 !BYTE $EA        ;E06D
;                 !BYTE $11        ;E06E
;                 !BYTE $D6        ;E06F
;                 !BYTE   9        ;E070
;                 !BYTE $A9        ;E071
;                 !BYTE $17        ;E072
;                 !BYTE $9A        ;E073
;                 !BYTE $31 ; 1    ;E074
;                 !BYTE $29 ; )    ;E075
;                 !BYTE $4B ; K    ;E076
;                 !BYTE $B7        ;E077
;                 !BYTE   7        ;E078
;                 !BYTE $C8        ;E079
;                 !BYTE   9        ;E07A
;                 !BYTE $B7        ;E07B
;                 !BYTE  $B        ;E07C
;                 !BYTE $97        ;E07D
;                 !BYTE  $D        ;E07E
;                 !BYTE $67 ; g    ;E07F
;                 !BYTE  $F        ;E080
;                 !BYTE $B7        ;E081
;                 !BYTE $11        ;E082
;                 !BYTE $D7        ;E083
;                 !BYTE $13        ;E084
;                 !BYTE $B7        ;E085
;                 !BYTE $15        ;E086
;                 !BYTE $69 ; i    ;E087
;                 !BYTE $2D ; -    ;E088
;                 !BYTE $29 ; )    ;E089
;                 !BYTE $4D ; M    ;E08A
;                 !BYTE $CA        ;E08B
;                 !BYTE $67 ; g    ;E08C
;                 !BYTE $CC        ;E08D
;                 !BYTE $3D ; =    ;E08E
;                 !BYTE $BA        ;E08F
;                 !BYTE $49 ; I    ;E090
;                 !BYTE $A6        ;E091
;                 !BYTE $4A ; J    ;E092
;                 !BYTE $DA        ;E093
;                 !BYTE $8B        ;E094
;                 !BYTE $8A        ;E095
;                 !BYTE $BB        ;E096
;                 !BYTE $37 ; 7    ;E097
;                 !BYTE $79 ; y    ;E098
;                 !BYTE $D9        ;E099
;                 !BYTE $73 ; s    ;E09A
;                 !BYTE $73 ; s    ;E09B
;                 !BYTE $45 ; E    ;E09C
;                 !BYTE $55 ; U    ;E09D
;                 !BYTE $31 ; 1    ;E09E
;                 !BYTE $76 ; v    ;E09F
;                 !BYTE $2D ; -    ;E0A0
;                 !BYTE $77 ; w    ;E0A1
;                 !BYTE $27 ; '    ;E0A2
;                 !BYTE $37 ; 7    ;E0A3
;                 !BYTE $21 ; !    ;E0A4
;                 !BYTE $88        ;E0A5
;                 !BYTE $2D ; -    ;E0A6
;                 !BYTE $CC        ;E0A7
;                 !BYTE $29 ; )    ;E0A8
;                 !BYTE $96        ;E0A9
;                 !BYTE $21 ; !    ;E0AA
;                 !BYTE $D9        ;E0AB
;                 !BYTE $13        ;E0AC
;                 !BYTE $D7        ;E0AD
;                 !BYTE $15        ;E0AE
;                 !BYTE $C6        ;E0AF
;                 !BYTE $13        ;E0B0
;                 !BYTE $98        ;E0B1
;                 !BYTE $19        ;E0B2
;                 !BYTE $C7        ;E0B3
;                 !BYTE $1B        ;E0B4
;                 !BYTE $B7        ;E0B5
;                 !BYTE $1B        ;E0B6
;                 !BYTE $58 ; X    ;E0B7
;                 !BYTE $27 ; '    ;E0B8
;                 !BYTE $E9        ;E0B9
;                 !BYTE $2D ; -    ;E0BA
;                 !BYTE $7A ; z    ;E0BB
;                 !BYTE $10        ;E0BC
;                 !BYTE $BA        ;E0BD
;                 !BYTE $6B ; k    ;E0BE
;                 !BYTE $9F        ;E0BF
;                 !BYTE $5D ; ]    ;E0C0
;                 !BYTE $18        ;E0C1
;                 !BYTE $8A        ;E0C2
;                 !BYTE $C9        ;E0C3
;                 !BYTE $B1        ;E0C4
;                 !BYTE $84        ;E0C5
;                 !BYTE $70 ; p    ;E0C6
;                 !BYTE $F6        ;E0C7
;                 !BYTE $61 ; a    ;E0C8
;                 !BYTE $97        ;E0C9
;                 !BYTE $63 ; c    ;E0CA
;                 !BYTE $37 ; 7    ;E0CB
;                 !BYTE $6B ; k    ;E0CC
;                 !BYTE $BF        ;E0CD
;                 !BYTE $83        ;E0CE
;                 !BYTE $4A ; J    ;E0CF

* = $e0d0
                 !BYTE $B5        ;E0D0
                 !BYTE $AD        ;E0D1
                 !BYTE $57 ; W    ;E0D2
                 !BYTE $A3        ;E0D3
                 !BYTE $3F ; ?    ;E0D4
                 !BYTE $89        ;E0D5
                 !BYTE $55 ; U    ;E0D6
                 !BYTE $AD        ;E0D7
                 !BYTE $8F        ;E0D8
                 !BYTE   8        ;E0D9
                 !BYTE $77 ; w    ;E0DA
                 !BYTE $42 ; B    ;E0DB
                 !BYTE $39 ; 9    ;E0DC
                 !BYTE $45 ; E    ;E0DD
                 !BYTE $21 ; !    ;E0DE
                 !BYTE $86        ;E0DF
                 !BYTE $29 ; )    ;E0E0
                 !BYTE $47 ; G    ;E0E1
                 !BYTE $2B ; +    ;E0E2
                 !BYTE $88        ;E0E3
                 !BYTE $35 ; 5    ;E0E4
                 !BYTE $BA        ;E0E5
                 !BYTE $4B ; K    ;E0E6
                 !BYTE $DC        ;E0E7
                 !BYTE $43 ; C    ;E0E8
                 !BYTE $BA        ;E0E9
                 !BYTE $57 ; W    ;E0EA
                 !BYTE $BE        ;E0EB
                 !BYTE $87        ;E0EC
                 !BYTE $CD        ;E0ED
                 !BYTE $A9        ;E0EE
                 !BYTE $BA        ;E0EF
                 !BYTE $BF        ;E0F0
                 !BYTE $AC        ;E0F1
                 !BYTE   5        ;E0F2
                 !BYTE $C8        ;E0F3
                 !BYTE   7        ;E0F4
                 !BYTE $C8        ;E0F5
                 !BYTE   9        ;E0F6
                 !BYTE $B7        ;E0F7
                 !BYTE  $B        ;E0F8
                 !BYTE $97        ;E0F9
                 !BYTE  $D        ;E0FA
                 !BYTE $67 ; g    ;E0FB
                 !BYTE  $F        ;E0FC
                 !BYTE $B7        ;E0FD
                 !BYTE $11        ;E0FE
                 !BYTE $D7        ;E0FF
                 !BYTE $13        ;E100
                 !BYTE $B7        ;E101
                 !BYTE $14        ;E102
                 !BYTE $89        ;E103
                 !BYTE $47 ; G    ;E104
                 !BYTE $8C        ;E105
                 !BYTE $3D ; =    ;E106
                 !BYTE $BA        ;E107
                 !BYTE $49 ; I    ;E108
                 !BYTE $A6        ;E109
                 !BYTE $4A ; J    ;E10A
                 !BYTE $5A ; Z    ;E10B
                 !BYTE $B7        ;E10C
                 !BYTE $29 ; )    ;E10D
                 !BYTE $47 ; G    ;E10E
                 !BYTE $DD        ;E10F
                 !BYTE $59 ; Y    ;E110
                 !BYTE   6        ;E111
                 !BYTE $49 ; I    ;E112
                 !BYTE   5        ;E113
                 !BYTE $2A ; *    ;E114
                 !BYTE $A6        ;E115
                 !BYTE $17        ;E116
                 !BYTE $55 ; U    ;E117
                 !BYTE   3        ;E118
                 !BYTE $48 ; H    ;E119
                 !BYTE $45 ; E    ;E11A
                 !BYTE $64 ; d    ;E11B
                 !BYTE $1F        ;E11C
                 !BYTE $96        ;E11D
                 !BYTE $1D        ;E11E
                 !BYTE $B9        ;E11F
                 !BYTE $23 ; #    ;E120
                 !BYTE $86        ;E121
                 !BYTE $1D        ;E122
                 !BYTE $17        ;E123
                 !BYTE $17        ;E124
                 !BYTE $67 ; g    ;E125
                 !BYTE $19        ;E126
                 !BYTE $AA        ;E127
                 !BYTE $29 ; )    ;E128
                 !BYTE $A5        ;E129
                 !BYTE $21 ; !    ;E12A
                 !BYTE $79 ; y    ;E12B
                 !BYTE $33 ; 3    ;E12C
                 !BYTE $88        ;E12D
                 !BYTE $3A ; :    ;E12E
                 !BYTE $C9        ;E12F
                 !BYTE $43 ; C    ;E130
                 !BYTE $79 ; y    ;E131
                 !BYTE $57 ; W    ;E132
                 !BYTE $1A        ;E133
                 !BYTE $6D ; m    ;E134
                 !BYTE $A4        ;E135
                 !BYTE $51 ; Q    ;E136
                 !BYTE $A0        ;E137

; Not needed:
;                 !BYTE  $D        ;E138
;                 !BYTE $A5        ;E139
;                 !BYTE   3        ;E13A
;                 !BYTE $89        ;E13B
;                 !BYTE $17        ;E13C
;                 !BYTE $AB        ;E13D
;                 !BYTE $3A ; :    ;E13E
;                 !BYTE $CC        ;E13F
;                 !BYTE $61 ; a    ;E140
;                 !BYTE $53 ; S    ;E141
;                 !BYTE $21 ; !    ;E142
;                 !BYTE $75 ; u    ;E143
;                 !BYTE $13        ;E144
;                 !BYTE $19        ;E145
;                 !BYTE $34 ; 4    ;E146
;                 !BYTE $7B ; {    ;E147
;                 !BYTE  $F        ;E148
;                 !BYTE $A6        ;E149
;                 !BYTE   9        ;E14A
;                 !BYTE $D5        ;E14B
;                 !BYTE   3        ;E14C
;                 !BYTE $A7        ;E14D
;                 !BYTE   2        ;E14E
;                 !BYTE $87        ;E14F
;                 !BYTE   2        ;E150
;                 !BYTE $F9        ;E151
;                 !BYTE $22 ; "    ;E152
;                 !BYTE $CA        ;E153
;                 !BYTE   7        ;E154
;                 !BYTE $48 ; H    ;E155
;                 !BYTE $13        ;E156
;                 !BYTE $DB        ;E157
;                 !BYTE $23 ; #    ;E158
;                 !BYTE $57 ; W    ;E159
;                 !BYTE $23 ; #    ;E15A
;                 !BYTE $78 ; x    ;E15B
;                 !BYTE $31 ; 1    ;E15C
;                 !BYTE $96        ;E15D
;                 !BYTE $2F ; /    ;E15E
;                 !BYTE $B7        ;E15F
;                 !BYTE $35 ; 5    ;E160
;                 !BYTE $B9        ;E161
;                 !BYTE $43 ; C    ;E162
;                 !BYTE $96        ;E163
;                 !BYTE $3F ; ?    ;E164
;                 !BYTE $C6        ;E165
;                 !BYTE $41 ; A    ;E166
;                 !BYTE $E9        ;E167
;                 !BYTE $4B ; K    ;E168
;                 !BYTE $F7        ;E169
;                 !BYTE $61 ; a    ;E16A
;                 !BYTE $BF        ;E16B
;                 !BYTE $4D ; M    ;E16C
;                 !BYTE $A8        ;E16D
;                 !BYTE $59 ; Y    ;E16E
;                 !BYTE $AA        ;E16F
;                 !BYTE $57 ; W    ;E170
;                 !BYTE $D5        ;E171
;                 !BYTE $33 ; 3    ;E172
;                 !BYTE $AB        ;E173
;                 !BYTE $33 ; 3    ;E174
;                 !BYTE $CA        ;E175
;                 !BYTE $45 ; E    ;E176
;                 !BYTE $BA        ;E177
;                 !BYTE $41 ; A    ;E178
;                 !BYTE $AF        ;E179
;                 !BYTE $4B ; K    ;E17A
;                 !BYTE $7A ; z    ;E17B
;                 !BYTE $3F ; ?    ;E17C
;                 !BYTE $C8        ;E17D
;                 !BYTE $4B ; K    ;E17E
;                 !BYTE $BD        ;E17F







;* = $e340
;                 !BYTE $FA          ;E340
;                 !BYTE $48 ; H      ;E341
;                 !BYTE $F1          ;E342
;                 !BYTE $EA          ;E343
;                 !BYTE  $E          ;E344
;                 !BYTE $4A ; J      ;E345
;                 !BYTE $7F ;       ;E346
;                 !BYTE $F4          ;E347
;                 !BYTE   0          ;E348
;                 !BYTE $40 ; @      ;E349
;                 !BYTE $FF          ;E34A
;                 !BYTE $FA          ;E34B
;                 !BYTE $FE          ;E34C
;                 !BYTE $4A ; J      ;E34D
;                 !BYTE $FC          ;E34E
;                 !BYTE $EA          ;E34F
;                 !BYTE  $E          ;E350
;                 !BYTE  $B          ;E351
;                 !BYTE $FF          ;E352
;                 !BYTE $F2          ;E353
;                 !BYTE $4E ; N      ;E354
;                 !BYTE  $B          ;E355
;                 !BYTE $7F ;       ;E356
;                 !BYTE $DC          ;E357
* = $e358
                 !BYTE   0          ;E358
                 !BYTE $40 ; @      ;E359
                 !BYTE $76 ; v      ;E35A
                 !BYTE $F9          ;E35B
                 !BYTE $6A ; j      ;E35C
                 !BYTE $C6          ;E35D
                 !BYTE $FB          ;E35E
                 !BYTE $EA          ;E35F
                 !BYTE $12          ;E360
                 !BYTE $4C ; L      ;E361
                 !BYTE $F9          ;E362
                 !BYTE $EA          ;E363
                 !BYTE $62 ; b      ;E364
                 !BYTE  $C          ;E365
                 !BYTE $7E ; ~      ;E366
                 !BYTE $F1          ;E367
                 !BYTE $5E ; ^      ;E368
                 !BYTE $4B ; K      ;E369
                 !BYTE $FC          ;E36A
                 !BYTE $EA          ;E36B
                 !BYTE $D2          ;E36C
                 !BYTE $4C ; L      ;E36D
                 !BYTE $BB          ;E36E
                 !BYTE $E2          ;E36F
                 !BYTE $A6          ;E370
                 !BYTE $4B ; K      ;E371
                 !BYTE $7C ; |      ;E372
                 !BYTE $F9          ;E373
                 !BYTE $62 ; b      ;E374
                 !BYTE $4D ; M      ;E375
                 !BYTE $79 ; y      ;E376
                 !BYTE $E2          ;E377
                 !BYTE $6E ; n      ;E378
                 !BYTE $4B ; K      ;E379
                 !BYTE $7A ; z      ;E37A
                 !BYTE $F9          ;E37B
                 !BYTE $6A ; j      ;E37C
                 !BYTE $46 ; F      ;E37D
                 !BYTE $BD          ;E37E
                 !BYTE $EA          ;E37F
                 !BYTE $E2          ;E380
                 !BYTE $4B ; K      ;E381
                 !BYTE $BF          ;E382
                 !BYTE $FA          ;E383
                 !BYTE   6          ;E384
                 !BYTE  $C          ;E385
                 !BYTE $7F ;       ;E386
                 !BYTE $EC          ;E387
                 !BYTE   0          ;E388
                 !BYTE $40 ; @      ;E389
                 !BYTE $7E ; ~      ;E38A
                 !BYTE $F1          ;E38B
                 !BYTE   2          ;E38C
                 !BYTE $47 ; G      ;E38D
                 !BYTE $FB          ;E38E
                 !BYTE $EA          ;E38F
                 !BYTE $12          ;E390
                 !BYTE $CD          ;E391
                 !BYTE $78 ; x      ;E392
                 !BYTE $F1          ;E393
                 !BYTE $6A ; j      ;E394
                 !BYTE $46 ; F      ;E395
                 !BYTE $7F ;       ;E396
                 !BYTE $D4          ;E397
                 !BYTE   0          ;E398
                 !BYTE $40 ; @      ;E399
                 !BYTE $7E ; ~      ;E39A
                 !BYTE $F9          ;E39B
                 !BYTE   2          ;E39C
                 !BYTE $47 ; G      ;E39D
                 !BYTE $71 ; q      ;E39E
                 !BYTE $DA          ;E39F
                 !BYTE $52 ; R      ;E3A0
                 !BYTE $50 ; P      ;E3A1
                 !BYTE $F3          ;E3A2
                 !BYTE $E2          ;E3A3
                 !BYTE $CA          ;E3A4
                 !BYTE $50 ; P      ;E3A5
                 !BYTE $7E ; ~      ;E3A6
                 !BYTE $44 ; D      ;E3A7
                 !BYTE   0          ;E3A8
                 !BYTE $40 ; @      ;E3A9
                 !BYTE $76 ; v      ;E3AA
                 !BYTE $F1          ;E3AB
                 !BYTE $6A ; j      ;E3AC
                 !BYTE $46 ; F      ;E3AD
                 !BYTE $7F ;       ;E3AE
                 !BYTE $E4          ;E3AF
                 !BYTE   0          ;E3B0
                 !BYTE $40 ; @      ;E3B1
                 !BYTE $7E ; ~      ;E3B2
                 !BYTE $F9          ;E3B3
                 !BYTE   2          ;E3B4
                 !BYTE $47 ; G      ;E3B5
                 !BYTE $F0          ;E3B6
                 !BYTE $DA          ;E3B7
                 !BYTE $F2          ;E3B8
                 !BYTE $4E ; N      ;E3B9
                 !BYTE $75 ; u      ;E3BA
                 !BYTE $F9          ;E3BB
                 !BYTE $62 ; b      ;E3BC
                 !BYTE $4D ; M      ;E3BD
                 !BYTE $A6          ;E3BE
                 !BYTE $E2          ;E3BF
                 !BYTE $BA          ;E3C0
                 !BYTE $4D ; M      ;E3C1
                 !BYTE $FA          ;E3C2
                 !BYTE $E2          ;E3C3
                 !BYTE $F2          ;E3C4
                 !BYTE $CF          ;E3C5
                 !BYTE $FE          ;E3C6
                 !BYTE $E2          ;E3C7
;                 !BYTE  $E          ;E3C8
;                 !BYTE $53 ; S      ;E3C9
;                 !BYTE $F5          ;E3CA
;                 !BYTE $E2          ;E3CB
;                 !BYTE $2E ; .      ;E3CC
;                 !BYTE $13          ;E3CD
;                 !BYTE $7D ; }      ;E3CE
;                 !BYTE $54 ; T      ;E3CF
;                 !BYTE   0          ;E3D0
;                 !BYTE $40 ; @      ;E3D1
;                 !BYTE $B1          ;E3D2
;                 !BYTE $E2          ;E3D3
;                 !BYTE $9A          ;E3D4
;                 !BYTE $51 ; Q      ;E3D5
;                 !BYTE $7D ; }      ;E3D6
;                 !BYTE $5C ; \      ;E3D7
;                 !BYTE   0          ;E3D8
;                 !BYTE $40 ; @      ;E3D9
;                 !BYTE $BE          ;E3DA
;                 !BYTE $D2          ;E3DB
;                 !BYTE $9A          ;E3DC
;                 !BYTE $51 ; Q      ;E3DD
;                 !BYTE $B5          ;E3DE
;                 !BYTE $E2          ;E3DF
;                 !BYTE $4E ; N      ;E3E0
;                 !BYTE $12          ;E3E1
;                 !BYTE $BB          ;E3E2
;                 !BYTE $E2          ;E3E3
;                 !BYTE $D2          ;E3E4
;                 !BYTE $92          ;E3E5
;                 !BYTE $7C ; |      ;E3E6
;                 !BYTE $F1          ;E3E7
;                 !BYTE $82          ;E3E8
;                 !BYTE $48 ; H      ;E3E9
;                 !BYTE $BD          ;E3EA
;                 !BYTE $DA          ;E3EB
;                 !BYTE $F6          ;E3EC
;                 !BYTE $53 ; S      ;E3ED
;                 !BYTE $7E ; ~      ;E3EE
;                 !BYTE $F9          ;E3EF
;                 !BYTE $DE          ;E3F0
;                 !BYTE $53 ; S      ;E3F1
;                 !BYTE $7F ;       ;E3F2
;                 !BYTE $FC          ;E3F3
;                 !BYTE   0          ;E3F4
;                 !BYTE $40 ; @      ;E3F5
;                 !BYTE $7C ; |      ;E3F6
;                 !BYTE $F1          ;E3F7
;                 !BYTE $82          ;E3F8
;                 !BYTE $48 ; H      ;E3F9
;                 !BYTE $BB          ;E3FA
;                 !BYTE $E2          ;E3FB
;                 !BYTE $1A          ;E3FC
;                 !BYTE $54 ; T      ;E3FD
;                 !BYTE $7D ; }      ;E3FE
;                 !BYTE $F9          ;E3FF



;* = $e640
;                 !BYTE $4D ; M   ;E640
;                 !BYTE $B6       ;E641
;                 !BYTE $55 ; U   ;E642
;                 !BYTE $AD       ;E643
;                 !BYTE $AC       ;E644
;                 !BYTE $B6       ;E645
;                 !BYTE $AD       ;E646
;                 !BYTE $A6       ;E647
;                 !BYTE $69 ; i   ;E648
;                 !BYTE $B3       ;E649
;                 !BYTE $55 ; U   ;E64A
;                 !BYTE $A5       ;E64B
;                 !BYTE $A6       ;E64C
;                 !BYTE $99       ;E64D
;                 !BYTE $65 ; e   ;E64E
;                 !BYTE $AA       ;E64F
;                 !BYTE $66 ; f   ;E650
;                 !BYTE $A7       ;E651
;                 !BYTE $AD       ;E652
;                 !BYTE $35 ; 5   ;E653
;                 !BYTE $A5       ;E654
;                 !BYTE $AC       ;E655
;                 !BYTE $64 ; d   ;E656
;                 !BYTE $AA       ;E657
;                 !BYTE $49 ; I   ;E658
;                 !BYTE $56 ; V   ;E659
;                 !BYTE $67 ; g   ;E65A
;                 !BYTE $46 ; F   ;E65B
;                 !BYTE $35 ; 5   ;E65C
;                 !BYTE $B3       ;E65D
;                 !BYTE $59 ; Y   ;E65E
;                 !BYTE $A5       ;E65F
;                 !BYTE $26 ; &   ;E660
;                 !BYTE $B5       ;E661
;                 !BYTE $49 ; I   ;E662
;                 !BYTE $2E ; .   ;E663
;                 !BYTE $CD       ;E664
;                 !BYTE $8D       ;E665
;                 !BYTE $1D       ;E666
;                 !BYTE $67 ; g   ;E667
* = $e668
                 !BYTE $6C ; l   ;E668
                 !BYTE $E1       ;E669
                 !BYTE $1B       ;E66A
                 !BYTE $75 ; u   ;E66B
                 !BYTE $EC       ;E66C
                 !BYTE $38 ; 8   ;E66D
                 !BYTE $5D ; ]   ;E66E
                 !BYTE $59 ; Y   ;E66F
                 !BYTE $2B ; +   ;E670
                 !BYTE $66 ; f   ;E671
                 !BYTE $55 ; U   ;E672
                 !BYTE $15       ;E673
                 !BYTE $EB       ;E674
                 !BYTE  $D       ;E675
                 !BYTE $1F       ;E676
                 !BYTE $55 ; U   ;E677
                 !BYTE $AD       ;E678
                 !BYTE $6A ; j   ;E679
                 !BYTE $5B ; [   ;E67A
                 !BYTE $B5       ;E67B
                 !BYTE $C2       ;E67C
                 !BYTE $66 ; f   ;E67D
                 !BYTE $71 ; q   ;E67E
                 !BYTE $C5       ;E67F
                 !BYTE  $D       ;E680
                 !BYTE $2B ; +   ;E681
                 !BYTE   7       ;E682
                 !BYTE $2E ; .   ;E683
                 !BYTE $D5       ;E684
                 !BYTE $9A       ;E685
                 !BYTE $51 ; Q   ;E686
                 !BYTE $E7       ;E687
                 !BYTE $B8       ;E688
                 !BYTE $82       ;E689
                 !BYTE $4F ; O   ;E68A
                 !BYTE $35 ; 5   ;E68B
                 !BYTE $C3       ;E68C
                 !BYTE $AA       ;E68D
                 !BYTE $1A       ;E68E
                 !BYTE $1D       ;E68F
                 !BYTE $2A ; *   ;E690
                 !BYTE $62 ; b   ;E691
                 !BYTE $DD       ;E692
                 !BYTE $68 ; h   ;E693
                 !BYTE $D5       ;E694
                 !BYTE $62 ; b   ;E695
                 !BYTE   7       ;E696
                 !BYTE $AF       ;E697
                 !BYTE $71 ; q   ;E698
                 !BYTE $65 ; e   ;E699
                 !BYTE $13       ;E69A
                 !BYTE $57 ; W   ;E69B
                 !BYTE $CD       ;E69C
                 !BYTE $1E       ;E69D
                 !BYTE $55 ; U   ;E69E
                 !BYTE $31 ; 1   ;E69F
                 !BYTE $6E ; n   ;E6A0
                 !BYTE $A8       ;E6A1
                 !BYTE $55 ; U   ;E6A2
                 !BYTE $C7       ;E6A3
                 !BYTE $8E       ;E6A4
                 !BYTE $B9       ;E6A5
                 !BYTE $66 ; f   ;E6A6
                 !BYTE $4D ; M   ;E6A7
                 !BYTE $B2       ;E6A8
                 !BYTE $52 ; R   ;E6A9
                 !BYTE $93       ;E6AA
                 !BYTE $7A ; z   ;E6AB
                 !BYTE $D1       ;E6AC
                 !BYTE $74 ; t   ;E6AD
                 !BYTE $D4       ;E6AE
                 !BYTE $A9       ;E6AF
                 !BYTE $72 ; r   ;E6B0
                 !BYTE $95       ;E6B1
                 !BYTE $F1       ;E6B2
                 !BYTE $D5       ;E6B3
                 !BYTE $79 ; y   ;E6B4
                 !BYTE $8A       ;E6B5
                 !BYTE $55 ; U   ;E6B6
                 !BYTE $A5       ;E6B7
                 !BYTE $2C ; ,   ;E6B8
                 !BYTE $7D ; }   ;E6B9
                 !BYTE $6C ; l   ;E6BA
                 !BYTE $A9       ;E6BB
                 !BYTE $9B       ;E6BC
                 !BYTE $56 ; V   ;E6BD
                 !BYTE $65 ; e   ;E6BE
                 !BYTE $43 ; C   ;E6BF

;                 !BYTE $96       ;E6C0
;                 !BYTE $FC       ;E6C1
;                 !BYTE $7C ; |   ;E6C2
;                 !BYTE $AA       ;E6C3
;                 !BYTE $7A ; z   ;E6C4
;                 !BYTE $64 ; d   ;E6C5
;                 !BYTE $77 ; w   ;E6C6
;                 !BYTE $33 ; 3   ;E6C7
;                 !BYTE $84       ;E6C8
;                 !BYTE $FD       ;E6C9
;                 !BYTE $7C ; |   ;E6CA
;                 !BYTE $CB       ;E6CB
;                 !BYTE $7B ; {   ;E6CC
;                 !BYTE $10       ;E6CD
;                 !BYTE $84       ;E6CE
;                 !BYTE $87       ;E6CF
;                 !BYTE $98       ;E6D0
;                 !BYTE $FB       ;E6D1
;                 !BYTE $6C ; l   ;E6D2
;                 !BYTE $77 ; w   ;E6D3
;                 !BYTE $67 ; g   ;E6D4
;                 !BYTE $52 ; R   ;E6D5
;                 !BYTE $87       ;E6D6
;                 !BYTE $65 ; e   ;E6D7
;                 !BYTE $A7       ;E6D8
;                 !BYTE $FD       ;E6D9
;                 !BYTE $6C ; l   ;E6DA
;                 !BYTE $66 ; f   ;E6DB
;                 !BYTE $66 ; f   ;E6DC
;                 !BYTE $55 ; U   ;E6DD
;                 !BYTE $76 ; v   ;E6DE
;                 !BYTE $88       ;E6DF
;                 !BYTE $98       ;E6E0
;                 !BYTE $FB       ;E6E1
;                 !BYTE $E3       ;E6E2
;                 !BYTE $71 ; q   ;E6E3
;                 !BYTE $1C       ;E6E4
;                 !BYTE $C7       ;E6E5
;                 !BYTE $E1       ;E6E6
;                 !BYTE $38 ; 8   ;E6E7
;                 !BYTE $3E ; >   ;E6E8
;                 !BYTE $7C ; |   ;E6E9
;                 !BYTE $E3       ;E6EA
;                 !BYTE $E3       ;E6EB
;                 !BYTE $1C       ;E6EC
;                 !BYTE $C7       ;E6ED
;                 !BYTE $E3       ;E6EE
;                 !BYTE $3C ; <   ;E6EF
;                 !BYTE $1E       ;E6F0
;                 !BYTE $A7       ;E6F1
;                 !BYTE $C7       ;E6F2
;                 !BYTE $F1       ;E6F3
;                 !BYTE $20       ;E6F4
;                 !BYTE $87       ;E6F5
;                 !BYTE $63 ; c   ;E6F6
;                 !BYTE $3C ; <   ;E6F7
;                 !BYTE $8C       ;E6F8
;                 !BYTE $C3       ;E6F9
;                 !BYTE $79 ; y   ;E6FA
;                 !BYTE $DC       ;E6FB
;                 !BYTE $19       ;E6FC
;                 !BYTE $87       ;E6FD
;                 !BYTE $E3       ;E6FE
;                 !BYTE $70 ; p   ;E6FF
* = $e700
                 !BYTE $1C       ;E700
                 !BYTE $3B ; ;   ;E701
                 !BYTE $93       ;E702
                 !BYTE $6B ; k   ;E703
                 !BYTE $E6       ;E704
                 !BYTE $8C       ;E705
                 !BYTE $19       ;E706
                 !BYTE $67 ; g   ;E707
                 !BYTE $AD       ;E708
                 !BYTE $A9       ;E709
                 !BYTE $33 ; 3   ;E70A
                 !BYTE $63 ; c   ;E70B
                 !BYTE $CC       ;E70C
                 !BYTE $6E ; n   ;E70D
                 !BYTE $55 ; U   ;E70E
                 !BYTE $55 ; U   ;E70F
                 !BYTE $CA       ;E710
                 !BYTE $98       ;E711
                 !BYTE $F1       ;E712
                 !BYTE $1C       ;E713
;                 !BYTE  $E       ;E714
;                 !BYTE $C7       ;E715
;                 !BYTE $E3       ;E716
;                 !BYTE $70 ; p   ;E717
;                 !BYTE $3C ; <   ;E718
;                 !BYTE $7C ; |   ;E719
;                 !BYTE $3F ; ?   ;E71A
;                 !BYTE $3C ; <   ;E71B
;                 !BYTE $8E       ;E71C
;                 !BYTE $E3       ;E71D
;                 !BYTE $E3       ;E71E
;                 !BYTE $70 ; p   ;E71F
;                 !BYTE $38 ; 8   ;E720
;                 !BYTE  $F       ;E721
;                 !BYTE $D3       ;E722
;                 !BYTE $A5       ;E723
;                 !BYTE $A5       ;E724
;                 !BYTE $B5       ;E725
;                 !BYTE $A5       ;E726
;                 !BYTE $A5       ;E727
;                 !BYTE $2D ; -   ;E728
;                 !BYTE $63 ; c   ;E729
;                 !BYTE $7C ; |   ;E72A
;                 !BYTE $57 ; W   ;E72B
;                 !BYTE $65 ; e   ;E72C
;                 !BYTE $77 ; w   ;E72D
;                 !BYTE $86       ;E72E
;                 !BYTE $BA       ;E72F
;                 !BYTE $99       ;E730
;                 !BYTE $BA       ;E731
;                 !BYTE $7C ; |   ;E732
;                 !BYTE $66 ; f   ;E733
;                 !BYTE $77 ; w   ;E734
;                 !BYTE $88       ;E735
;                 !BYTE $56 ; V   ;E736
;                 !BYTE $97       ;E737
;                 !BYTE $99       ;E738
;                 !BYTE $DA       ;E739
;                 !BYTE $6C ; l   ;E73A
;                 !BYTE $76 ; v   ;E73B
;                 !BYTE $77 ; w   ;E73C
;                 !BYTE $77 ; w   ;E73D
;                 !BYTE $77 ; w   ;E73E
;                 !BYTE $87       ;E73F
;                 !BYTE $99       ;E740
;                 !BYTE $CA       ;E741
;                 !BYTE $6C ; l   ;E742
;                 !BYTE $77 ; w   ;E743
;                 !BYTE $77 ; w   ;E744
;                 !BYTE $77 ; w   ;E745
;                 !BYTE $77 ; w   ;E746
;                 !BYTE $87       ;E747
;                 !BYTE $99       ;E748
;                 !BYTE $BA       ;E749
;                 !BYTE $6C ; l   ;E74A
;                 !BYTE $66 ; f   ;E74B
;                 !BYTE $76 ; v   ;E74C
;                 !BYTE $77 ; w   ;E74D
;                 !BYTE $77 ; w   ;E74E
;                 !BYTE $88       ;E74F
;                 !BYTE $99       ;E750
;                 !BYTE $AA       ;E751
;                 !BYTE $6C ; l   ;E752
;                 !BYTE $66 ; f   ;E753
;                 !BYTE $55 ; U   ;E754
;                 !BYTE $75 ; u   ;E755
;                 !BYTE $88       ;E756
;                 !BYTE $99       ;E757
;                 !BYTE $99       ;E758
;                 !BYTE $BA       ;E759
;                 !BYTE $6C ; l   ;E75A
;                 !BYTE $77 ; w   ;E75B
;                 !BYTE $66 ; f   ;E75C
;                 !BYTE $55 ; U   ;E75D
;                 !BYTE $75 ; u   ;E75E
;                 !BYTE $88       ;E75F
;                 !BYTE $97       ;E760
;                 !BYTE $FC       ;E761
;                 !BYTE $8C       ;E762
;                 !BYTE $67 ; g   ;E763
;                 !BYTE $88       ;E764
;                 !BYTE $46 ; F   ;E765
;                 !BYTE $73 ; s   ;E766
;                 !BYTE $79 ; y   ;E767
;                 !BYTE $65 ; e   ;E768
;                 !BYTE $FB       ;E769
;                 !BYTE $4C ; L   ;E76A
;                 !BYTE $B5       ;E76B
;                 !BYTE $9E       ;E76C
;                 !BYTE $34 ; 4   ;E76D
;                 !BYTE $55 ; U   ;E76E
;                 !BYTE $76 ; v   ;E76F
;                 !BYTE $76 ; v   ;E770
;                 !BYTE $FA       ;E771
;                 !BYTE $6C ; l   ;E772
;                 !BYTE $D8       ;E773
;                 !BYTE $8F       ;E774
;                 !BYTE $12       ;E775
;                 !BYTE $64 ; d   ;E776
;                 !BYTE $97       ;E777
;                 !BYTE $88       ;E778
;                 !BYTE $D9       ;E779
;                 !BYTE $8C       ;E77A
;                 !BYTE $65 ; e   ;E77B
;                 !BYTE $98       ;E77C
;                 !BYTE $67 ; g   ;E77D
;                 !BYTE $44 ; D   ;E77E
;                 !BYTE $96       ;E77F
;                 !BYTE $78 ; x   ;E780
;                 !BYTE $FA       ;E781
;                 !BYTE $7C ; |   ;E782
;                 !BYTE $66 ; f   ;E783
;                 !BYTE $77 ; w   ;E784
;                 !BYTE $87       ;E785
;                 !BYTE $77 ; w   ;E786
;                 !BYTE $A8       ;E787
;                 !BYTE $9A       ;E788
;                 !BYTE $B9       ;E789
;                 !BYTE $6C ; l   ;E78A
;                 !BYTE $55 ; U   ;E78B
;                 !BYTE $66 ; f   ;E78C
;                 !BYTE $76 ; v   ;E78D
;                 !BYTE $87       ;E78E
;                 !BYTE $98       ;E78F
;                 !BYTE $99       ;E790
;                 !BYTE $CA       ;E791
;                 !BYTE $6C ; l   ;E792
;                 !BYTE $66 ; f   ;E793
;                 !BYTE $66 ; f   ;E794
;                 !BYTE $76 ; v   ;E795
;                 !BYTE $88       ;E796
;                 !BYTE $88       ;E797
;                 !BYTE $99       ;E798
;                 !BYTE $BA       ;E799
;                 !BYTE $6C ; l   ;E79A
;                 !BYTE $66 ; f   ;E79B
;                 !BYTE $66 ; f   ;E79C
;                 !BYTE $76 ; v   ;E79D
;                 !BYTE $88       ;E79E
;                 !BYTE $99       ;E79F
;                 !BYTE $99       ;E7A0
;                 !BYTE $BA       ;E7A1
;                 !BYTE $6C ; l   ;E7A2
;                 !BYTE $66 ; f   ;E7A3
;                 !BYTE $65 ; e   ;E7A4
;                 !BYTE $66 ; f   ;E7A5
;                 !BYTE $87       ;E7A6
;                 !BYTE $98       ;E7A7
;                 !BYTE $A9       ;E7A8
;                 !BYTE $CB       ;E7A9
;                 !BYTE $7C ; |   ;E7AA
;                 !BYTE $66 ; f   ;E7AB
;                 !BYTE $98       ;E7AC
;                 !BYTE $24 ; $   ;E7AD
;                 !BYTE $75 ; u   ;E7AE
;                 !BYTE $77 ; w   ;E7AF
;                 !BYTE $97       ;E7B0
;                 !BYTE $FB       ;E7B1
;                 !BYTE $9C       ;E7B2
;                 !BYTE $78 ; x   ;E7B3
;                 !BYTE $A9       ;E7B4
;                 !BYTE $14       ;E7B5
;                 !BYTE $72 ; r   ;E7B6
;                 !BYTE $97       ;E7B7
;                 !BYTE $99       ;E7B8
;                 !BYTE $FA       ;E7B9
;                 !BYTE $9C       ;E7BA
;                 !BYTE $29 ; )   ;E7BB
;                 !BYTE $94       ;E7BC
;                 !BYTE $49 ; I   ;E7BD
;                 !BYTE $54 ; T   ;E7BE
;                 !BYTE $85       ;E7BF
;                 !BYTE $9A       ;E7C0
;                 !BYTE $FA       ;E7C1
;                 !BYTE $8C       ;E7C2
;                 !BYTE $57 ; W   ;E7C3
;                 !BYTE $85       ;E7C4
;                 !BYTE $67 ; g   ;E7C5
;                 !BYTE $45 ; E   ;E7C6
;                 !BYTE $94       ;E7C7
;                 !BYTE $8B       ;E7C8
;                 !BYTE $F9       ;E7C9
;                 !BYTE $8C       ;E7CA
;                 !BYTE $76 ; v   ;E7CB
;                 !BYTE $66 ; f   ;E7CC
;                 !BYTE $65 ; e   ;E7CD
;                 !BYTE $56 ; V   ;E7CE
;                 !BYTE $96       ;E7CF
;                 !BYTE $99       ;E7D0
;                 !BYTE $FC       ;E7D1
;                 !BYTE $8C       ;E7D2
;                 !BYTE $77 ; w   ;E7D3
;                 !BYTE $56 ; V   ;E7D4
;                 !BYTE $55 ; U   ;E7D5
;                 !BYTE $65 ; e   ;E7D6
;                 !BYTE $97       ;E7D7
;                 !BYTE $BA       ;E7D8
;                 !BYTE $FC       ;E7D9
;                 !BYTE $7C ; |   ;E7DA
;                 !BYTE $67 ; g   ;E7DB
;                 !BYTE $65 ; e   ;E7DC
;                 !BYTE $66 ; f   ;E7DD
;                 !BYTE $76 ; v   ;E7DE
;                 !BYTE $97       ;E7DF
;                 !BYTE $BA       ;E7E0
;                 !BYTE $DC       ;E7E1
;                 !BYTE $8C       ;E7E2
;                 !BYTE $66 ; f   ;E7E3
;                 !BYTE $56 ; V   ;E7E4
;                 !BYTE $75 ; u   ;E7E5
;                 !BYTE $77 ; w   ;E7E6
;                 !BYTE $A8       ;E7E7
;                 !BYTE $AA       ;E7E8
;                 !BYTE $CA       ;E7E9
;                 !BYTE $7C ; |   ;E7EA
;                 !BYTE $77 ; w   ;E7EB
;                 !BYTE $77 ; w   ;E7EC
;                 !BYTE $76 ; v   ;E7ED
;                 !BYTE $77 ; w   ;E7EE
;                 !BYTE $67 ; g   ;E7EF
;                 !BYTE $76 ; v   ;E7F0
;                 !BYTE $77 ; w   ;E7F1
;                 !BYTE $77 ; w   ;E7F2
;                 !BYTE $A7       ;E7F3
;                 !BYTE $A9       ;E7F4
;                 !BYTE $DA       ;E7F5
;                 !BYTE $7C ; |   ;E7F6
;                 !BYTE $97       ;E7F7
;                 !BYTE $77 ; w   ;E7F8
;                 !BYTE $66 ; f   ;E7F9
;                 !BYTE $87       ;E7FA
;                 !BYTE $57 ; W   ;E7FB
;                 !BYTE $97       ;E7FC
;                 !BYTE $77 ; w   ;E7FD
;                 !BYTE $64 ; d   ;E7FE
;                 !BYTE $B5       ;E7FF





;* = $eb00
;                 !BYTE $66       ;EB00
;                 !BYTE $87       ;EB01
;                 !BYTE $99       ;EB02
;                 !BYTE $AA       ;EB03
;                 !BYTE $89       ;EB04
;                 !BYTE $77 ; w   ;EB05
;                 !BYTE $77 ; w   ;EB06
;                 !BYTE $66 ; f   ;EB07
;                 !BYTE $66 ; f   ;EB08
;                 !BYTE $66 ; f   ;EB09
;                 !BYTE $66 ; f   ;EB0A
;                 !BYTE $86       ;EB0B
;                 !BYTE $A9       ;EB0C
;                 !BYTE $CB       ;EB0D
;                 !BYTE $7C ; |   ;EB0E
;                 !BYTE $67 ; g   ;EB0F
;                 !BYTE $66 ; f   ;EB10
;                 !BYTE $86       ;EB11
;                 !BYTE $99       ;EB12
;                 !BYTE $A9       ;EB13
;                 !BYTE $9A       ;EB14
;                 !BYTE $77 ; w   ;EB15
;                 !BYTE $77 ; w   ;EB16
;                 !BYTE $77 ; w   ;EB17
;                 !BYTE $66 ; f   ;EB18
;                 !BYTE $55 ; U   ;EB19
;                 !BYTE $55 ; U   ;EB1A
;                 !BYTE $86       ;EB1B
;                 !BYTE $A9       ;EB1C
;                 !BYTE $DC       ;EB1D
;                 !BYTE $9C       ;EB1E
;                 !BYTE $78 ; x   ;EB1F
;                 !BYTE $66 ; f   ;EB20
;                 !BYTE $76 ; v   ;EB21
;                 !BYTE $87       ;EB22
;                 !BYTE $99       ;EB23
;                 !BYTE $89       ;EB24
;                 !BYTE $87       ;EB25
;                 !BYTE $78 ; x   ;EB26
;                 !BYTE $77 ; w   ;EB27
;                 !BYTE $78 ; x   ;EB28
;                 !BYTE $66 ; f   ;EB29
;                 !BYTE $45 ; E   ;EB2A
;                 !BYTE $64 ; d   ;EB2B
;                 !BYTE $A8       ;EB2C
;                 !BYTE $EC       ;EB2D
;                 !BYTE $AC       ;EB2E
;                 !BYTE $78 ; x   ;EB2F
;                 !BYTE $56 ; V   ;EB30
;                 !BYTE $65 ; e   ;EB31
;                 !BYTE $87       ;EB32
;                 !BYTE $88       ;EB33
;                 !BYTE $88       ;EB34
;                 !BYTE $88       ;EB35
;                 !BYTE $88       ;EB36
;                 !BYTE $88       ;EB37
;                 !BYTE $78 ; x   ;EB38
;                 !BYTE $56 ; V   ;EB39
;                 !BYTE $44 ; D   ;EB3A
;                 !BYTE $75 ; u   ;EB3B
;                 !BYTE $98       ;EB3C
;                 !BYTE $DB       ;EB3D
;                 !BYTE $9C       ;EB3E
;                 !BYTE $78 ; x   ;EB3F
;                 !BYTE $66 ; f   ;EB40
;                 !BYTE $66 ; f   ;EB41
;                 !BYTE $87       ;EB42
;                 !BYTE $88       ;EB43
;                 !BYTE $88       ;EB44
;                 !BYTE $88       ;EB45
;                 !BYTE $88       ;EB46
;                 !BYTE $88       ;EB47
;                 !BYTE $78 ; x   ;EB48
;                 !BYTE $56 ; V   ;EB49
;                 !BYTE $44 ; D   ;EB4A
;                 !BYTE $75 ; u   ;EB4B
;                 !BYTE $98       ;EB4C
;                 !BYTE $CB       ;EB4D
;                 !BYTE $8C       ;EB4E
;                 !BYTE $88       ;EB4F
;                 !BYTE $77 ; w   ;EB50
;                 !BYTE $77 ; w   ;EB51
;                 !BYTE $88       ;EB52
;                 !BYTE $98       ;EB53
;                 !BYTE $88       ;EB54
;                 !BYTE $77 ; w   ;EB55
;                 !BYTE $66 ; f   ;EB56
;                 !BYTE $77 ; w   ;EB57
;                 !BYTE $87       ;EB58
;                 !BYTE $77 ; w   ;EB59
;                 !BYTE $66 ; f   ;EB5A
;                 !BYTE $76 ; v   ;EB5B
* = $eb5c
                 !BYTE $98       ;EB5C
                 !BYTE $CA       ;EB5D
                 !BYTE $63 ; c   ;EB5E
                 !BYTE $3E ; >   ;EB5F
                 !BYTE $36 ; 6   ;EB60
                 !BYTE $C7       ;EB61
                 !BYTE $E1       ;EB62
                 !BYTE $E1       ;EB63
                 !BYTE $78 ; x   ;EB64
                 !BYTE $B0       ;EB65
                 !BYTE $79 ; y   ;EB66
                 !BYTE $7C ; |   ;EB67
                 !BYTE $38 ; 8   ;EB68
                 !BYTE  $F       ;EB69
                 !BYTE $FC       ;EB6A
                 !BYTE $E0       ;EB6B
                 !BYTE $87       ;EB6C
                 !BYTE $CD       ;EB6D
                 !BYTE $5C ; \   ;EB6E
                 !BYTE $76 ; v   ;EB6F
                 !BYTE $67 ; g   ;EB70
                 !BYTE $86       ;EB71
                 !BYTE $AA       ;EB72
                 !BYTE $99       ;EB73
                 !BYTE $AA       ;EB74
                 !BYTE $DB       ;EB75
                 !BYTE $4C ; L   ;EB76
                 !BYTE $64 ; d   ;EB77
                 !BYTE $77 ; w   ;EB78
                 !BYTE $87       ;EB79
                 !BYTE $98       ;EB7A
                 !BYTE $CB       ;EB7B
                 !BYTE $8A       ;EB7C
                 !BYTE $EA       ;EB7D
                 !BYTE $4C ; L   ;EB7E
                 !BYTE $74 ; t   ;EB7F
                 !BYTE $77 ; w   ;EB80
                 !BYTE $87       ;EB81
                 !BYTE $98       ;EB82
                 !BYTE $CA       ;EB83
                 !BYTE $8B       ;EB84
                 !BYTE $E9       ;EB85
                 !BYTE $5C ; \   ;EB86
                 !BYTE $64 ; d   ;EB87
                 !BYTE $77 ; w   ;EB88
                 !BYTE $77 ; w   ;EB89
                 !BYTE $88       ;EB8A
                 !BYTE $CA       ;EB8B
                 !BYTE $8A       ;EB8C
                 !BYTE $FB       ;EB8D
                 !BYTE $5C ; \   ;EB8E
                 !BYTE $64 ; d   ;EB8F
                 !BYTE $77 ; w   ;EB90
                 !BYTE $76 ; v   ;EB91
                 !BYTE $88       ;EB92
                 !BYTE $CA       ;EB93
                 !BYTE $9B       ;EB94
                 !BYTE $EB       ;EB95
                 !BYTE $4C ; L   ;EB96
                 !BYTE $75 ; u   ;EB97
                 !BYTE $68 ; h   ;EB98
                 !BYTE $75 ; u   ;EB99
                 !BYTE $99       ;EB9A
                 !BYTE $B9       ;EB9B
                 !BYTE $AB       ;EB9C
                 !BYTE $EB       ;EB9D
                 !BYTE $6C ; l   ;EB9E
                 !BYTE $76 ; v   ;EB9F
                 !BYTE $78 ; x   ;EBA0
                 !BYTE $87       ;EBA1
                 !BYTE $A8       ;EBA2
                 !BYTE $A9       ;EBA3
                 !BYTE $A9       ;EBA4
                 !BYTE $EB       ;EBA5
                 !BYTE $8C       ;EBA6
                 !BYTE $56 ; V   ;EBA7
                 !BYTE $65 ; e   ;EBA8
                 !BYTE $87       ;EBA9
                 !BYTE $89       ;EBAA
                 !BYTE $66 ; f   ;EBAB
                 !BYTE $67 ; g   ;EBAC
                 !BYTE $87       ;EBAD
                 !BYTE $67 ; g   ;EBAE
                 !BYTE $66 ; f   ;EBAF
                 !BYTE $97       ;EBB0
                 !BYTE $DB       ;EBB1
                 !BYTE $8C       ;EBB2
                 !BYTE $56 ; V   ;EBB3
                 !BYTE $55 ; U   ;EBB4
                 !BYTE $76 ; v   ;EBB5
                 !BYTE $88       ;EBB6
                 !BYTE $67 ; g   ;EBB7
                 !BYTE $77 ; w   ;EBB8
                 !BYTE $77 ; w   ;EBB9
                 !BYTE $67 ; g   ;EBBA
                 !BYTE $66 ; f   ;EBBB
                 !BYTE $98       ;EBBC
                 !BYTE $DB       ;EBBD
                 !BYTE $8C       ;EBBE
                 !BYTE $66 ; f   ;EBBF
                 !BYTE $66 ; f   ;EBC0
                 !BYTE $76 ; v   ;EBC1
                 !BYTE $77 ; w   ;EBC2
                 !BYTE $67 ; g   ;EBC3
                 !BYTE $76 ; v   ;EBC4
                 !BYTE $77 ; w   ;EBC5
                 !BYTE $77 ; w   ;EBC6
                 !BYTE $77 ; w   ;EBC7
                 !BYTE $98       ;EBC8
                 !BYTE $DB       ;EBC9
                 !BYTE $7C ; |   ;EBCA
                 !BYTE $77 ; w   ;EBCB
                 !BYTE $67 ; g   ;EBCC
                 !BYTE $76 ; v   ;EBCD
                 !BYTE $67 ; g   ;EBCE
                 !BYTE $66 ; f   ;EBCF
                 !BYTE $76 ; v   ;EBD0
                 !BYTE $88       ;EBD1
                 !BYTE $78 ; x   ;EBD2
                 !BYTE $87       ;EBD3
                 !BYTE $A9       ;EBD4
                 !BYTE $CB       ;EBD5
                 !BYTE $7C ; |   ;EBD6
                 !BYTE $67 ; g   ;EBD7
                 !BYTE $66 ; f   ;EBD8
                 !BYTE $66 ; f   ;EBD9
                 !BYTE $66 ; f   ;EBDA
                 !BYTE $66 ; f   ;EBDB
                 !BYTE $76 ; v   ;EBDC
                 !BYTE $77 ; w   ;EBDD
                 !BYTE $88       ;EBDE
                 !BYTE $88       ;EBDF
                 !BYTE $A9       ;EBE0
                 !BYTE $BA       ;EBE1
                 !BYTE $7C ; |   ;EBE2
                 !BYTE $67 ; g   ;EBE3
                 !BYTE $34 ; 4   ;EBE4
                 !BYTE $86       ;EBE5
                 !BYTE $13       ;EBE6
                 !BYTE $83       ;EBE7
                 !BYTE $68 ; h   ;EBE8
                 !BYTE $76 ; v   ;EBE9
                 !BYTE $98       ;EBEA
                 !BYTE $AA       ;EBEB
                 !BYTE $AA       ;EBEC
                 !BYTE $EB       ;EBED
                 !BYTE $6C ; l   ;EBEE
                 !BYTE $89       ;EBEF
                 !BYTE $33 ; 3   ;EBF0
                 !BYTE $76 ; v   ;EBF1
                 !BYTE $34 ; 4   ;EBF2
                 !BYTE $44 ; D   ;EBF3
                 !BYTE $75 ; u   ;EBF4
                 !BYTE $78 ; x   ;EBF5
                 !BYTE $75 ; u   ;EBF6
                 !BYTE $FC       ;EBF7
                 !BYTE $6B ; k   ;EBF8
                 !BYTE $F9       ;EBF9
                 !BYTE $7C ; |   ;EBFA
                 !BYTE $98       ;EBFB
                 !BYTE $36 ; 6   ;EBFC
                 !BYTE $86       ;EBFD
                 !BYTE $34 ; 4   ;EBFE
                 !BYTE $65 ; e   ;EBFF
                 !BYTE $55 ; U   ;EC00
                 !BYTE $88       ;EC01
                 !BYTE $65 ; e   ;EC02
                 !BYTE $EC       ;EC03
                 !BYTE $59 ; Y   ;EC04
                 !BYTE $F9       ;EC05
                 !BYTE $7C ; |   ;EC06
                 !BYTE $77 ; w   ;EC07
                 !BYTE $66 ; f   ;EC08
                 !BYTE $67 ; g   ;EC09
                 !BYTE $55 ; U   ;EC0A
                 !BYTE $66 ; f   ;EC0B
                 !BYTE $66 ; f   ;EC0C
                 !BYTE $77 ; w   ;EC0D
                 !BYTE $77 ; w   ;EC0E
                 !BYTE $A9       ;EC0F
                 !BYTE $89       ;EC10
                 !BYTE $DA       ;EC11
                 !BYTE $7C ; |   ;EC12
                 !BYTE $88       ;EC13
                 !BYTE $77 ; w   ;EC14
                 !BYTE $88       ;EC15
                 !BYTE $88       ;EC16
                 !BYTE $79 ; y   ;EC17
                 !BYTE $65 ; e   ;EC18
                 !BYTE $77 ; w   ;EC19
                 !BYTE $77 ; w   ;EC1A
                 !BYTE $67 ; g   ;EC1B
                 !BYTE $86       ;EC1C
                 !BYTE $88       ;EC1D
                 !BYTE $56 ; V   ;EC1E
                 !BYTE $66 ; f   ;EC1F
                 !BYTE $97       ;EC20
                 !BYTE $FD       ;EC21
                 !BYTE $8C       ;EC22
                 !BYTE $78 ; x   ;EC23
                 !BYTE $87       ;EC24
                 !BYTE $88       ;EC25
                 !BYTE $88       ;EC26
                 !BYTE $67 ; g   ;EC27
                 !BYTE $56 ; V   ;EC28
                 !BYTE $76 ; v   ;EC29
                 !BYTE $78 ; x   ;EC2A
                 !BYTE $66 ; f   ;EC2B
                 !BYTE $66 ; f   ;EC2C
                 !BYTE $87       ;EC2D
                 !BYTE $57 ; W   ;EC2E
                 !BYTE $75 ; u   ;EC2F
                 !BYTE $A8       ;EC30
                 !BYTE $FD       ;EC31
                 !BYTE $9C       ;EC32
                 !BYTE $99       ;EC33
                 !BYTE $78 ; x   ;EC34
                 !BYTE $88       ;EC35
                 !BYTE $88       ;EC36
                 !BYTE $67 ; g   ;EC37
                 !BYTE $56 ; V   ;EC38
                 !BYTE $65 ; e   ;EC39
                 !BYTE $77 ; w   ;EC3A
                 !BYTE $66 ; f   ;EC3B
                 !BYTE $66 ; f   ;EC3C
                 !BYTE $77 ; w   ;EC3D
                 !BYTE $57 ; W   ;EC3E
                 !BYTE $75 ; u   ;EC3F
                 !BYTE $A9       ;EC40
                 !BYTE $FC       ;EC41
                 !BYTE $8C       ;EC42
                 !BYTE $88       ;EC43
                 !BYTE $88       ;EC44
                 !BYTE $88       ;EC45
                 !BYTE $88       ;EC46
                 !BYTE $77 ; w   ;EC47
                 !BYTE $56 ; V   ;EC48
                 !BYTE $65 ; e   ;EC49
                 !BYTE $77 ; w   ;EC4A
                 !BYTE $77 ; w   ;EC4B
                 !BYTE $66 ; f   ;EC4C
                 !BYTE $76 ; v   ;EC4D
                 !BYTE $87       ;EC4E
                 !BYTE $88       ;EC4F
                 !BYTE $99       ;EC50
                 !BYTE $CA       ;EC51
                 !BYTE $8C       ;EC52
                 !BYTE $88       ;EC53
                 !BYTE $78 ; x   ;EC54
                 !BYTE $77 ; w   ;EC55
                 !BYTE $77 ; w   ;EC56
                 !BYTE $77 ; w   ;EC57
                 !BYTE $66 ; f   ;EC58
                 !BYTE $66 ; f   ;EC59
                 !BYTE $66 ; f   ;EC5A
                 !BYTE $66 ; f   ;EC5B
                 !BYTE $76 ; v   ;EC5C
                 !BYTE $87       ;EC5D
                 !BYTE $88       ;EC5E
                 !BYTE $98       ;EC5F
                 !BYTE $A9       ;EC60
                 !BYTE $BA       ;EC61
                 !BYTE $9C       ;EC62
                 !BYTE $89       ;EC63
                 !BYTE $88       ;EC64
                 !BYTE $78 ; x   ;EC65
                 !BYTE $77 ; w   ;EC66
                 !BYTE $66 ; f   ;EC67
                 !BYTE $66 ; f   ;EC68
                 !BYTE $66 ; f   ;EC69
                 !BYTE $66 ; f   ;EC6A
                 !BYTE $66 ; f   ;EC6B
                 !BYTE $66 ; f   ;EC6C
                 !BYTE $77 ; w   ;EC6D
                 !BYTE $88       ;EC6E
                 !BYTE $99       ;EC6F
                 !BYTE $A9       ;EC70
                 !BYTE $AA       ;EC71
                 !BYTE $9C       ;EC72
                 !BYTE $89       ;EC73
                 !BYTE $88       ;EC74
                 !BYTE $77 ; w   ;EC75
                 !BYTE $77 ; w   ;EC76
                 !BYTE $66 ; f   ;EC77
                 !BYTE $66 ; f   ;EC78
                 !BYTE $56 ; V   ;EC79
                 !BYTE $66 ; f   ;EC7A
                 !BYTE $66 ; f   ;EC7B
                 !BYTE $76 ; v   ;EC7C
                 !BYTE $77 ; w   ;EC7D
                 !BYTE $98       ;EC7E
                 !BYTE $99       ;EC7F
                 !BYTE $A9       ;EC80
                 !BYTE $BA       ;EC81
                 !BYTE $8C       ;EC82
                 !BYTE $88       ;EC83
                 !BYTE $88       ;EC84
                 !BYTE $78 ; x   ;EC85
                 !BYTE $77 ; w   ;EC86
                 !BYTE $67 ; g   ;EC87
                 !BYTE $66 ; f   ;EC88
                 !BYTE $66 ; f   ;EC89
                 !BYTE $66 ; f   ;EC8A
                 !BYTE $66 ; f   ;EC8B
                 !BYTE $76 ; v   ;EC8C
                 !BYTE $87       ;EC8D
                 !BYTE $88       ;EC8E
                 !BYTE $99       ;EC8F
                 !BYTE $99       ;EC90
                 !BYTE $AA       ;EC91
                 !BYTE $7C ; |   ;EC92
                 !BYTE $98       ;EC93
                 !BYTE $89       ;EC94
                 !BYTE $88       ;EC95
                 !BYTE $67 ; g   ;EC96
                 !BYTE $77 ; w   ;EC97
                 !BYTE $66 ; f   ;EC98
                 !BYTE $76 ; v   ;EC99
                 !BYTE $88       ;EC9A
                 !BYTE $78 ; x   ;EC9B
                 !BYTE $45 ; E   ;EC9C
                 !BYTE $75 ; u   ;EC9D
                 !BYTE $88       ;EC9E
                 !BYTE $88       ;EC9F
                 !BYTE $77 ; w   ;ECA0
                 !BYTE $EB       ;ECA1
                 !BYTE $8C       ;ECA2
                 !BYTE $88       ;ECA3
                 !BYTE $77 ; w   ;ECA4
                 !BYTE $98       ;ECA5
                 !BYTE $78 ; x   ;ECA6
                 !BYTE $77 ; w   ;ECA7
                 !BYTE $66 ; f   ;ECA8
                 !BYTE $76 ; v   ;ECA9
                 !BYTE $77 ; w   ;ECAA
                 !BYTE $77 ; w   ;ECAB
                 !BYTE $77 ; w   ;ECAC
                 !BYTE $88       ;ECAD
                 !BYTE $78 ; x   ;ECAE
                 !BYTE $55 ; U   ;ECAF
                 !BYTE $86       ;ECB0
                 !BYTE $EB       ;ECB1
                 !BYTE $8C       ;ECB2
                 !BYTE $88       ;ECB3
                 !BYTE $77 ; w   ;ECB4
                 !BYTE $98       ;ECB5
                 !BYTE $78 ; x   ;ECB6
                 !BYTE $77 ; w   ;ECB7
                 !BYTE $66 ; f   ;ECB8
                 !BYTE $77 ; w   ;ECB9
                 !BYTE $77 ; w   ;ECBA
                 !BYTE $77 ; w   ;ECBB
                 !BYTE $67 ; g   ;ECBC
                 !BYTE $86       ;ECBD
                 !BYTE $68 ; h   ;ECBE
                 !BYTE $66 ; f   ;ECBF
                 !BYTE $97       ;ECC0
                 !BYTE $EC       ;ECC1
                 !BYTE $7C ; |   ;ECC2
                 !BYTE $88       ;ECC3
                 !BYTE $87       ;ECC4
                 !BYTE $88       ;ECC5
                 !BYTE $77 ; w   ;ECC6
                 !BYTE $77 ; w   ;ECC7
                 !BYTE $77 ; w   ;ECC8
                 !BYTE $77 ; w   ;ECC9
                 !BYTE $67 ; g   ;ECCA
                 !BYTE $76 ; v   ;ECCB
                 !BYTE $77 ; w   ;ECCC
                 !BYTE $77 ; w   ;ECCD
                 !BYTE $67 ; g   ;ECCE
                 !BYTE $65 ; e   ;ECCF
                 !BYTE $97       ;ECD0
                 !BYTE $FC       ;ECD1
                 !BYTE $8C       ;ECD2
                 !BYTE $78 ; x   ;ECD3
                 !BYTE $87       ;ECD4
                 !BYTE $99       ;ECD5
                 !BYTE $98       ;ECD6
                 !BYTE $79 ; y   ;ECD7
                 !BYTE $66 ; f   ;ECD8
                 !BYTE $88       ;ECD9
                 !BYTE $67 ; g   ;ECDA
                 !BYTE $45 ; E   ;ECDB
                 !BYTE $54 ; T   ;ECDC
                 !BYTE $87       ;ECDD
                 !BYTE $77 ; w   ;ECDE
                 !BYTE $66 ; f   ;ECDF
                 !BYTE $A8       ;ECE0
                 !BYTE $EC       ;ECE1
                 !BYTE $7C ; |   ;ECE2
                 !BYTE $88       ;ECE3
                 !BYTE $77 ; w   ;ECE4
                 !BYTE $99       ;ECE5
                 !BYTE $98       ;ECE6
                 !BYTE $89       ;ECE7
                 !BYTE $56 ; V   ;ECE8
                 !BYTE $86       ;ECE9
                 !BYTE $68 ; h   ;ECEA
                 !BYTE $66 ; f   ;ECEB
                 !BYTE $55 ; U   ;ECEC
                 !BYTE $87       ;ECED
                 !BYTE $57 ; W   ;ECEE
                 !BYTE $75 ; u   ;ECEF
                 !BYTE $97       ;ECF0
                 !BYTE $FD       ;ECF1
                 !BYTE $9C       ;ECF2
                 !BYTE $88       ;ECF3
                 !BYTE $77 ; w   ;ECF4
                 !BYTE $88       ;ECF5
                 !BYTE $88       ;ECF6
                 !BYTE $67 ; g   ;ECF7
                 !BYTE $66 ; f   ;ECF8
                 !BYTE $97       ;ECF9
                 !BYTE $78 ; x   ;ECFA
                 !BYTE $66 ; f   ;ECFB
                 !BYTE $45 ; E   ;ECFC
                 !BYTE $97       ;ECFD
                 !BYTE $67 ; g   ;ECFE
                 !BYTE $55 ; U   ;ECFF
                 !BYTE $A7       ;ED00
                 !BYTE $EC       ;ED01
                 !BYTE $8C       ;ED02
                 !BYTE $78 ; x   ;ED03
                 !BYTE $77 ; w   ;ED04
                 !BYTE $99       ;ED05
                 !BYTE $88       ;ED06
                 !BYTE $66 ; f   ;ED07
                 !BYTE $56 ; V   ;ED08
                 !BYTE $87       ;ED09
                 !BYTE $88       ;ED0A
                 !BYTE $56 ; V   ;ED0B
                 !BYTE $77 ; w   ;ED0C
                 !BYTE $97       ;ED0D
                 !BYTE $58 ; X   ;ED0E
                 !BYTE $65 ; e   ;ED0F
                 !BYTE $97       ;ED10
                 !BYTE $EB       ;ED11
                 !BYTE $7C ; |   ;ED12
                 !BYTE $87       ;ED13
                 !BYTE $88       ;ED14
                 !BYTE $88       ;ED15
                 !BYTE $98       ;ED16
                 !BYTE $89       ;ED17
                 !BYTE $78 ; x   ;ED18
                 !BYTE $77 ; w   ;ED19
                 !BYTE $77 ; w   ;ED1A
                 !BYTE $67 ; g   ;ED1B
                 !BYTE $45 ; E   ;ED1C
                 !BYTE $65 ; e   ;ED1D
                 !BYTE $77 ; w   ;ED1E
                 !BYTE $77 ; w   ;ED1F
                 !BYTE $98       ;ED20
                 !BYTE $FB       ;ED21
                 !BYTE $8C       ;ED22
                 !BYTE $77 ; w   ;ED23
                 !BYTE $87       ;ED24
                 !BYTE $88       ;ED25
                 !BYTE $98       ;ED26
                 !BYTE $79 ; y   ;ED27
                 !BYTE $86       ;ED28
                 !BYTE $88       ;ED29
                 !BYTE $77 ; w   ;ED2A
                 !BYTE $67 ; g   ;ED2B
                 !BYTE $44 ; D   ;ED2C
                 !BYTE $76 ; v   ;ED2D
                 !BYTE $77 ; w   ;ED2E
                 !BYTE $66 ; f   ;ED2F
                 !BYTE $86       ;ED30
                 !BYTE $FC       ;ED31
                 !BYTE $8C       ;ED32
                 !BYTE $77 ; w   ;ED33
                 !BYTE $77 ; w   ;ED34
                 !BYTE $88       ;ED35
                 !BYTE $88       ;ED36
                 !BYTE $78 ; x   ;ED37
                 !BYTE $77 ; w   ;ED38
                 !BYTE $88       ;ED39
                 !BYTE $77 ; w   ;ED3A
                 !BYTE $77 ; w   ;ED3B
                 !BYTE $55 ; U   ;ED3C
                 !BYTE $77 ; w   ;ED3D
                 !BYTE $67 ; g   ;ED3E
                 !BYTE $66 ; f   ;ED3F
                 !BYTE $98       ;ED40
                 !BYTE $EB       ;ED41
                 !BYTE $7C ; |   ;ED42
                 !BYTE $77 ; w   ;ED43
                 !BYTE $76 ; v   ;ED44
                 !BYTE $88       ;ED45
                 !BYTE $88       ;ED46
                 !BYTE $78 ; x   ;ED47
                 !BYTE $76 ; v   ;ED48
                 !BYTE $88       ;ED49
                 !BYTE $88       ;ED4A
                 !BYTE $67 ; g   ;ED4B
                 !BYTE $65 ; e   ;ED4C
                 !BYTE $88       ;ED4D
                 !BYTE $67 ; g   ;ED4E
                 !BYTE $66 ; f   ;ED4F
                 !BYTE $97       ;ED50
                 !BYTE $DB       ;ED51
                 !BYTE $8C       ;ED52
                 !BYTE $87       ;ED53
                 !BYTE $78 ; x   ;ED54
                 !BYTE $87       ;ED55
                 !BYTE $77 ; w   ;ED56
                 !BYTE $87       ;ED57
                 !BYTE $77 ; w   ;ED58
                 !BYTE $77 ; w   ;ED59
                 !BYTE $87       ;ED5A
                 !BYTE $78 ; x   ;ED5B
                 !BYTE $66 ; f   ;ED5C
                 !BYTE $77 ; w   ;ED5D
                 !BYTE $77 ; w   ;ED5E
                 !BYTE $87       ;ED5F
                 !BYTE $87       ;ED60
                 !BYTE $DA       ;ED61
                 !BYTE $1D       ;ED62
                 !BYTE $8F       ;ED63
                 !BYTE $37 ; 7   ;ED64
                 !BYTE $9E       ;ED65
                 !BYTE $D1       ;ED66
                 !BYTE $17       ;ED67
                 !BYTE $F3       ;ED68
                 !BYTE $39 ; 9   ;ED69
                 !BYTE $21 ; !   ;ED6A
                 !BYTE $F3       ;ED6B
                 !BYTE $C3       ;ED6C
                 !BYTE $87       ;ED6D
                 !BYTE $D5       ;ED6E
                 !BYTE $38 ; 8   ;ED6F
                 !BYTE $18       ;ED70
                 !BYTE $C3       ;ED71
                 !BYTE $27 ; '   ;ED72
                 !BYTE $3E ; >   ;ED73
                 !BYTE $6A ; j   ;ED74
                 !BYTE $1C       ;ED75
                 !BYTE  $D       ;ED76
                 !BYTE $59 ; Y   ;ED77
                 !BYTE $74 ; t   ;ED78
                 !BYTE $51 ; Q   ;ED79
                 !BYTE $8B       ;ED7A
                 !BYTE $93       ;ED7B
                 !BYTE $C5       ;ED7C
                 !BYTE $69 ; i   ;ED7D
                 !BYTE $D9       ;ED7E
                 !BYTE $C1       ;ED7F
                 !BYTE $67 ; g   ;ED80
                 !BYTE $BA       ;ED81
                 !BYTE $87       ;ED82
                 !BYTE $3A ; :   ;ED83
                 !BYTE $D6       ;ED84
                 !BYTE $C5       ;ED85
                 !BYTE $D4       ;ED86
                 !BYTE $4D ; M   ;ED87
                 !BYTE $72 ; r   ;ED88
                 !BYTE $F0       ;ED89
                 !BYTE $8F       ;ED8A
                 !BYTE $1B       ;ED8B
                 !BYTE $76 ; v   ;ED8C
                 !BYTE $81       ;ED8D
                 !BYTE   3       ;ED8E
                 !BYTE $76 ; v   ;ED8F
                 !BYTE $70 ; p   ;ED90
                 !BYTE $58 ; X   ;ED91
                 !BYTE $55 ; U   ;ED92
                 !BYTE $72 ; r   ;ED93
                 !BYTE $3C ; <   ;ED94
                 !BYTE $5D ; ]   ;ED95
                 !BYTE $B1       ;ED96
                 !BYTE $31 ; 1   ;ED97
                 !BYTE $37 ; 7   ;ED98
                 !BYTE $E7       ;ED99
                 !BYTE $A5       ;ED9A
                 !BYTE $76 ; v   ;ED9B
                 !BYTE $9C       ;ED9C
                 !BYTE $C6       ;ED9D
                 !BYTE $61 ; a   ;ED9E
                 !BYTE $74 ; t   ;ED9F
                 !BYTE $5A ; Z   ;EDA0
                 !BYTE $F1       ;EDA1
                 !BYTE $D3       ;EDA2
                 !BYTE $61 ; a   ;EDA3
                 !BYTE $31 ; 1   ;EDA4
                 !BYTE $C7       ;EDA5
                 !BYTE $1B       ;EDA6
                 !BYTE $9C       ;EDA7
                 !BYTE $85       ;EDA8
                 !BYTE $23 ; #   ;EDA9
                 !BYTE $93       ;EDAA
                 !BYTE $59 ; Y   ;EDAB
                 !BYTE $F2       ;EDAC
                 !BYTE $A4       ;EDAD
                 !BYTE  $F       ;EDAE
                 !BYTE $DB       ;EDAF
                 !BYTE $98       ;EDB0
                 !BYTE $9C       ;EDB1
                 !BYTE $9D       ;EDB2
                 !BYTE $C9       ;EDB3
                 !BYTE $98       ;EDB4
                 !BYTE $98       ;EDB5
                 !BYTE $1D       ;EDB6
                 !BYTE $59 ; Y   ;EDB7
                 !BYTE $93       ;EDB8
                 !BYTE $27 ; '   ;EDB9
                 !BYTE $9C       ;EDBA
                 !BYTE $99       ;EDBB
                 !BYTE $89       ;EDBC
                 !BYTE $77 ; w   ;EDBD
                 !BYTE $66 ; f   ;EDBE
                 !BYTE $65 ; e   ;EDBF
                 !BYTE $66 ; f   ;EDC0
                 !BYTE $76 ; v   ;EDC1
                 !BYTE $87       ;EDC2
                 !BYTE $98       ;EDC3
                 !BYTE $99       ;EDC4
                 !BYTE $99       ;EDC5
                 !BYTE $9C       ;EDC6
                 !BYTE $99       ;EDC7
                 !BYTE $89       ;EDC8
                 !BYTE $77 ; w   ;EDC9
                 !BYTE $56 ; V   ;EDCA
                 !BYTE $55 ; U   ;EDCB
                 !BYTE $55 ; U   ;EDCC
                 !BYTE $76 ; v   ;EDCD
                 !BYTE $88       ;EDCE
                 !BYTE $99       ;EDCF
                 !BYTE $99       ;EDD0
                 !BYTE $98       ;EDD1
                 !BYTE $8C       ;EDD2
                 !BYTE $88       ;EDD3
                 !BYTE $78 ; x   ;EDD4
                 !BYTE $87       ;EDD5
                 !BYTE $78 ; x   ;EDD6
                 !BYTE $77 ; w   ;EDD7
                 !BYTE $57 ; W   ;EDD8
                 !BYTE $55 ; U   ;EDD9
                 !BYTE $55 ; U   ;EDDA
                 !BYTE $76 ; v   ;EDDB
                 !BYTE $A9       ;EDDC
                 !BYTE $DB       ;EDDD
                 !BYTE $8C       ;EDDE
                 !BYTE $99       ;EDDF
                 !BYTE $78 ; x   ;EDE0
                 !BYTE $77 ; w   ;EDE1
                 !BYTE $77 ; w   ;EDE2
                 !BYTE $88       ;EDE3
                 !BYTE $67 ; g   ;EDE4
                 !BYTE $56 ; V   ;EDE5
                 !BYTE $44 ; D   ;EDE6
                 !BYTE $75 ; u   ;EDE7
                 !BYTE $A8       ;EDE8
                 !BYTE $EC       ;EDE9
                 !BYTE $8C       ;EDEA
                 !BYTE $A9       ;EDEB
                 !BYTE $9A       ;EDEC
                 !BYTE $78 ; x   ;EDED
                 !BYTE $55 ; U   ;EDEE
                 !BYTE $87       ;EDEF
                 !BYTE $77 ; w   ;EDF0
                 !BYTE $78 ; x   ;EDF1
                 !BYTE $35 ; 5   ;EDF2
                 !BYTE $64 ; d   ;EDF3
                 !BYTE $A8       ;EDF4
                 !BYTE $EC       ;EDF5
                 !BYTE $7C ; |   ;EDF6
                 !BYTE $A9       ;EDF7
                 !BYTE $79 ; y   ;EDF8
                 !BYTE $88       ;EDF9
                 !BYTE $46 ; F   ;EDFA
                 !BYTE $75 ; u   ;EDFB
                 !BYTE $78 ; x   ;EDFC
                 !BYTE $87       ;EDFD
                 !BYTE $67 ; g   ;EDFE
                 !BYTE $55 ; U   ;EDFF
                 !BYTE $86       ;EE00
                 !BYTE $FC       ;EE01
                 !BYTE $8C       ;EE02
                 !BYTE $89       ;EE03
                 !BYTE $86       ;EE04
                 !BYTE $9B       ;EE05
                 !BYTE $56 ; V   ;EE06
                 !BYTE $67 ; g   ;EE07
                 !BYTE $33 ; 3   ;EE08
                 !BYTE $B9       ;EE09
                 !BYTE $38 ; 8   ;EE0A
                 !BYTE $84       ;EE0B
                 !BYTE $78 ; x   ;EE0C
                 !BYTE $FA       ;EE0D
                 !BYTE $AC       ;EE0E
                 !BYTE $7A ; z   ;EE0F
                 !BYTE $75 ; u   ;EE10
                 !BYTE $9A       ;EE11
                 !BYTE $66 ; f   ;EE12
                 !BYTE $79 ; y   ;EE13
                 !BYTE $21 ; !   ;EE14
                 !BYTE $D9       ;EE15
                 !BYTE $38 ; 8   ;EE16
                 !BYTE $95       ;EE17
                 !BYTE $68 ; h   ;EE18
                 !BYTE $F9       ;EE19
                 !BYTE $6C ; l   ;EE1A
                 !BYTE $99       ;EE1B
                 !BYTE $B8       ;EE1C
                 !BYTE $4B ; K   ;EE1D
                 !BYTE $81       ;EE1E
                 !BYTE $8E       ;EE1F
                 !BYTE $42 ; B   ;EE20
                 !BYTE $67 ; g   ;EE21
                 !BYTE $85       ;EE22
                 !BYTE $9A       ;EE23
                 !BYTE $45 ; E   ;EE24
                 !BYTE $F9       ;EE25
                 !BYTE $4C ; L   ;EE26
                 !BYTE $A8       ;EE27
                 !BYTE $AA       ;EE28
                 !BYTE $39 ; 9   ;EE29
                 !BYTE $A2       ;EE2A
                 !BYTE $8F       ;EE2B
                 !BYTE $41 ; A   ;EE2C
                 !BYTE $88       ;EE2D
                 !BYTE $66 ; f   ;EE2E
                 !BYTE $87       ;EE2F
                 !BYTE $67 ; g   ;EE30
                 !BYTE $D9       ;EE31
                 !BYTE $6C ; l   ;EE32
                 !BYTE $77 ; w   ;EE33
                 !BYTE $C8       ;EE34
                 !BYTE $4C ; L   ;EE35
                 !BYTE $71 ; q   ;EE36
                 !BYTE $BE       ;EE37
                 !BYTE $55 ; U   ;EE38
                 !BYTE $55 ; U   ;EE39
                 !BYTE $86       ;EE3A
                 !BYTE $8A       ;EE3B
                 !BYTE $34 ; 4   ;EE3C
                 !BYTE $F9       ;EE3D
                 !BYTE $5C ; \   ;EE3E
                 !BYTE $97       ;EE3F
                 !BYTE $9A       ;EE40
                 !BYTE $69 ; i   ;EE41
                 !BYTE $64 ; d   ;EE42
                 !BYTE $EC       ;EE43
                 !BYTE $17       ;EE44
                 !BYTE $95       ;EE45
                 !BYTE $56 ; V   ;EE46
                 !BYTE $99       ;EE47
                 !BYTE $44 ; D   ;EE48
                 !BYTE $FA       ;EE49
                 !BYTE $4C ; L   ;EE4A
                 !BYTE $BA       ;EE4B
                 !BYTE $78 ; x   ;EE4C
                 !BYTE $68 ; h   ;EE4D
                 !BYTE $94       ;EE4E
                 !BYTE $CE       ;EE4F
                 !BYTE $34 ; 4   ;EE50
                 !BYTE $86       ;EE51
                 !BYTE $47 ; G   ;EE52
                 !BYTE $85       ;EE53
                 !BYTE $57 ; W   ;EE54
                 !BYTE $F9       ;EE55
                 !BYTE $6C ; l   ;EE56
                 !BYTE $88       ;EE57
                 !BYTE $66 ; f   ;EE58
                 !BYTE $A9       ;EE59
                 !BYTE $78 ; x   ;EE5A
                 !BYTE $AA       ;EE5B
                 !BYTE $24 ; $   ;EE5C
                 !BYTE $B7       ;EE5D
                 !BYTE $37 ; 7   ;EE5E
                 !BYTE $65 ; e   ;EE5F
                 !BYTE $75 ; u   ;EE60
                 !BYTE $FD       ;EE61
                 !BYTE $6C ; l   ;EE62
                 !BYTE $99       ;EE63
                 !BYTE $77 ; w   ;EE64
                 !BYTE $9A       ;EE65
                 !BYTE $55 ; U   ;EE66
                 !BYTE $68 ; h   ;EE67
                 !BYTE $65 ; e   ;EE68
                 !BYTE $A9       ;EE69
                 !BYTE $37 ; 7   ;EE6A
                 !BYTE $63 ; c   ;EE6B
                 !BYTE $88       ;EE6C
                 !BYTE $FB       ;EE6D
                 !BYTE $7C ; |   ;EE6E
                 !BYTE $77 ; w   ;EE6F
                 !BYTE $77 ; w   ;EE70
                 !BYTE $67 ; g   ;EE71
                 !BYTE $55 ; U   ;EE72
                 !BYTE $76 ; v   ;EE73
                 !BYTE $78 ; x   ;EE74
                 !BYTE $98       ;EE75
                 !BYTE $68 ; h   ;EE76
                 !BYTE $86       ;EE77
                 !BYTE $88       ;EE78
                 !BYTE $CA       ;EE79
                 !BYTE $7C ; |   ;EE7A
                 !BYTE $88       ;EE7B
                 !BYTE $77 ; w   ;EE7C
                 !BYTE $77 ; w   ;EE7D
                 !BYTE $45 ; E   ;EE7E
                 !BYTE $86       ;EE7F
                 !BYTE $78 ; x   ;EE80
                 !BYTE $97       ;EE81
                 !BYTE $48 ; H   ;EE82
                 !BYTE $84       ;EE83
                 !BYTE $79 ; y   ;EE84
                 !BYTE $FA       ;EE85
                 !BYTE $6C ; l   ;EE86
                 !BYTE $A7       ;EE87
                 !BYTE $7A ; z   ;EE88
                 !BYTE $A7       ;EE89
                 !BYTE $59 ; Y   ;EE8A
                 !BYTE $85       ;EE8B
                 !BYTE $58 ; X   ;EE8C
                 !BYTE $96       ;EE8D
                 !BYTE $27 ; '   ;EE8E
                 !BYTE $73 ; s   ;EE8F
                 !BYTE $89       ;EE90
                 !BYTE $FB       ;EE91
                 !BYTE $5C ; \   ;EE92
                 !BYTE $85       ;EE93
                 !BYTE $AA       ;EE94
                 !BYTE $AA       ;EE95
                 !BYTE $48 ; H   ;EE96
                 !BYTE $94       ;EE97
                 !BYTE $79 ; y   ;EE98
                 !BYTE $97       ;EE99
                 !BYTE $27 ; '   ;EE9A
                 !BYTE $51 ; Q   ;EE9B
                 !BYTE $87       ;EE9C
                 !BYTE $FC       ;EE9D
                 !BYTE $5C ; \   ;EE9E
                 !BYTE $96       ;EE9F
                 !BYTE $89       ;EEA0
                 !BYTE $99       ;EEA1
                 !BYTE $67 ; g   ;EEA2
                 !BYTE $87       ;EEA3
                 !BYTE $89       ;EEA4
                 !BYTE $88       ;EEA5
                 !BYTE $36 ; 6   ;EEA6
                 !BYTE $42 ; B   ;EEA7
                 !BYTE $97       ;EEA8
                 !BYTE $FC       ;EEA9
                 !BYTE $5C ; \   ;EEAA
                 !BYTE $86       ;EEAB
                 !BYTE $99       ;EEAC
                 !BYTE $99       ;EEAD
                 !BYTE $68 ; h   ;EEAE
                 !BYTE $86       ;EEAF
                 !BYTE $89       ;EEB0
                 !BYTE $88       ;EEB1
                 !BYTE $36 ; 6   ;EEB2
                 !BYTE $42 ; B   ;EEB3
                 !BYTE $96       ;EEB4
                 !BYTE $FC       ;EEB5
                 !BYTE $5C ; \   ;EEB6
                 !BYTE $86       ;EEB7
                 !BYTE $89       ;EEB8
                 !BYTE $99       ;EEB9
                 !BYTE $68 ; h   ;EEBA
                 !BYTE $86       ;EEBB
                 !BYTE $99       ;EEBC
                 !BYTE $88       ;EEBD
                 !BYTE $36 ; 6   ;EEBE
                 !BYTE $42 ; B   ;EEBF
                 !BYTE $87       ;EEC0
                 !BYTE $FB       ;EEC1
                 !BYTE $5C ; \   ;EEC2
                 !BYTE $86       ;EEC3
                 !BYTE $98       ;EEC4
                 !BYTE $99       ;EEC5
                 !BYTE $68 ; h   ;EEC6
                 !BYTE $76 ; v   ;EEC7
                 !BYTE $88       ;EEC8
                 !BYTE $89       ;EEC9
                 !BYTE $36 ; 6   ;EECA
                 !BYTE $43 ; C   ;EECB
                 !BYTE $96       ;EECC
                 !BYTE $FC       ;EECD
                 !BYTE $5C ; \   ;EECE
                 !BYTE $76 ; v   ;EECF
                 !BYTE $98       ;EED0
                 !BYTE $9A       ;EED1
                 !BYTE $78 ; x   ;EED2
                 !BYTE $76 ; v   ;EED3
                 !BYTE $88       ;EED4
                 !BYTE $88       ;EED5
                 !BYTE $36 ; 6   ;EED6
                 !BYTE $63 ; c   ;EED7
                 !BYTE $87       ;EED8
                 !BYTE $FB       ;EED9
                 !BYTE $5C ; \   ;EEDA
                 !BYTE $86       ;EEDB
                 !BYTE $99       ;EEDC
                 !BYTE $9A       ;EEDD
                 !BYTE $67 ; g   ;EEDE
                 !BYTE $77 ; w   ;EEDF
                 !BYTE $87       ;EEE0
                 !BYTE $89       ;EEE1
                 !BYTE $46 ; F   ;EEE2
                 !BYTE $54 ; T   ;EEE3
                 !BYTE $87       ;EEE4
                 !BYTE $EB       ;EEE5
                 !BYTE $5C ; \   ;EEE6
                 !BYTE $87       ;EEE7
                 !BYTE $99       ;EEE8
                 !BYTE $99       ;EEE9
                 !BYTE $67 ; g   ;EEEA
                 !BYTE $76 ; v   ;EEEB
                 !BYTE $88       ;EEEC
                 !BYTE $88       ;EEED
                 !BYTE $46 ; F   ;EEEE
                 !BYTE $54 ; T   ;EEEF
                 !BYTE $97       ;EEF0
                 !BYTE $DB       ;EEF1
                 !BYTE $7C ; |   ;EEF2
                 !BYTE $77 ; w   ;EEF3
                 !BYTE $87       ;EEF4
                 !BYTE $88       ;EEF5
                 !BYTE $88       ;EEF6
                 !BYTE $78 ; x   ;EEF7
                 !BYTE $87       ;EEF8
                 !BYTE $78 ; x   ;EEF9
                 !BYTE $65 ; e   ;EEFA
                 !BYTE $77 ; w   ;EEFB
                 !BYTE $66 ; f   ;EEFC
                 !BYTE $66 ; f   ;EEFD
                 !BYTE $87       ;EEFE
                 !BYTE $89       ;EEFF
                 !BYTE $87       ;EF00
                 !BYTE $CA       ;EF01
                 !BYTE $6C ; l   ;EF02
                 !BYTE $77 ; w   ;EF03
                 !BYTE $77 ; w   ;EF04
                 !BYTE $88       ;EF05
                 !BYTE $98       ;EF06
                 !BYTE $89       ;EF07
                 !BYTE $88       ;EF08
                 !BYTE $89       ;EF09
                 !BYTE $66 ; f   ;EF0A
                 !BYTE $77 ; w   ;EF0B
                 !BYTE $67 ; g   ;EF0C
                 !BYTE $66 ; f   ;EF0D
                 !BYTE $86       ;EF0E
                 !BYTE $99       ;EF0F
                 !BYTE $77 ; w   ;EF10
                 !BYTE $C9       ;EF11
                 !BYTE $6C ; l   ;EF12
                 !BYTE $77 ; w   ;EF13
                 !BYTE $77 ; w   ;EF14
                 !BYTE $88       ;EF15
                 !BYTE $98       ;EF16
                 !BYTE $89       ;EF17
                 !BYTE $97       ;EF18
                 !BYTE $79 ; y   ;EF19
                 !BYTE $66 ; f   ;EF1A
                 !BYTE $77 ; w   ;EF1B
                 !BYTE $66 ; f   ;EF1C
                 !BYTE $56 ; V   ;EF1D
                 !BYTE $85       ;EF1E
                 !BYTE $9A       ;EF1F
                 !BYTE $77 ; w   ;EF20
                 !BYTE $C9       ;EF21
                 !BYTE $7C ; |   ;EF22
                 !BYTE $77 ; w   ;EF23
                 !BYTE $88       ;EF24
                 !BYTE $77 ; w   ;EF25
                 !BYTE $98       ;EF26
                 !BYTE $89       ;EF27
                 !BYTE $87       ;EF28
                 !BYTE $78 ; x   ;EF29
                 !BYTE $66 ; f   ;EF2A
                 !BYTE $76 ; v   ;EF2B
                 !BYTE $77 ; w   ;EF2C
                 !BYTE $66 ; f   ;EF2D
                 !BYTE $76 ; v   ;EF2E
                 !BYTE $A9       ;EF2F
                 !BYTE $68 ; h   ;EF30
                 !BYTE $D8       ;EF31
                 !BYTE $7C ; |   ;EF32
                 !BYTE $77 ; w   ;EF33
                 !BYTE $88       ;EF34
                 !BYTE $78 ; x   ;EF35
                 !BYTE $98       ;EF36
                 !BYTE $89       ;EF37
                 !BYTE $77 ; w   ;EF38
                 !BYTE $77 ; w   ;EF39
                 !BYTE $66 ; f   ;EF3A
                 !BYTE $76 ; v   ;EF3B
                 !BYTE $77 ; w   ;EF3C
                 !BYTE $66 ; f   ;EF3D
                 !BYTE $76 ; v   ;EF3E
                 !BYTE $B9       ;EF3F
                 !BYTE $59 ; Y   ;EF40
                 !BYTE $E7       ;EF41
                 !BYTE $8C       ;EF42
                 !BYTE $77 ; w   ;EF43
                 !BYTE $98       ;EF44
                 !BYTE $89       ;EF45
                 !BYTE $88       ;EF46
                 !BYTE $78 ; x   ;EF47
                 !BYTE $66 ; f   ;EF48
                 !BYTE $77 ; w   ;EF49
                 !BYTE $66 ; f   ;EF4A
                 !BYTE $66 ; f   ;EF4B
                 !BYTE $66 ; f   ;EF4C
                 !BYTE $77 ; w   ;EF4D
                 !BYTE $76 ; v   ;EF4E
                 !BYTE $B9       ;EF4F
                 !BYTE $6A ; j   ;EF50
                 !BYTE $D7       ;EF51
                 !BYTE $8C       ;EF52
                 !BYTE $88       ;EF53
                 !BYTE $88       ;EF54
                 !BYTE $88       ;EF55
                 !BYTE $78 ; x   ;EF56
                 !BYTE $77 ; w   ;EF57
                 !BYTE $67 ; g   ;EF58
                 !BYTE $77 ; w   ;EF59
                 !BYTE $56 ; V   ;EF5A
                 !BYTE $77 ; w   ;EF5B
                 !BYTE $66 ; f   ;EF5C
                 !BYTE $88       ;EF5D
                 !BYTE $66 ; f   ;EF5E
                 !BYTE $B9       ;EF5F
                 !BYTE $69 ; i   ;EF60
                 !BYTE $D8       ;EF61
                 !BYTE $8C       ;EF62
                 !BYTE $88       ;EF63
                 !BYTE $88       ;EF64
                 !BYTE $88       ;EF65
                 !BYTE $77 ; w   ;EF66
                 !BYTE $78 ; x   ;EF67
                 !BYTE $76 ; v   ;EF68
                 !BYTE $56 ; V   ;EF69
                 !BYTE $66 ; f   ;EF6A
                 !BYTE $76 ; v   ;EF6B
                 !BYTE $67 ; g   ;EF6C
                 !BYTE $87       ;EF6D
                 !BYTE $67 ; g   ;EF6E
                 !BYTE $C9       ;EF6F
                 !BYTE $59 ; Y   ;EF70
                 !BYTE $D8       ;EF71
                 !BYTE $9C       ;EF72
                 !BYTE $89       ;EF73
                 !BYTE $88       ;EF74
                 !BYTE $88       ;EF75
                 !BYTE $77 ; w   ;EF76
                 !BYTE $77 ; w   ;EF77
                 !BYTE $66 ; f   ;EF78
                 !BYTE $66 ; f   ;EF79
                 !BYTE $66 ; f   ;EF7A
                 !BYTE $77 ; w   ;EF7B
                 !BYTE $66 ; f   ;EF7C
                 !BYTE $88       ;EF7D
                 !BYTE $77 ; w   ;EF7E
                 !BYTE $B8       ;EF7F
                 !BYTE $6A ; j   ;EF80
                 !BYTE $D7       ;EF81
                 !BYTE $9C       ;EF82
                 !BYTE $89       ;EF83
                 !BYTE $88       ;EF84
                 !BYTE $89       ;EF85
                 !BYTE $77 ; w   ;EF86
                 !BYTE $77 ; w   ;EF87
                 !BYTE $66 ; f   ;EF88
                 !BYTE $66 ; f   ;EF89
                 !BYTE $55 ; U   ;EF8A
                 !BYTE $66 ; f   ;EF8B
                 !BYTE $66 ; f   ;EF8C
                 !BYTE $88       ;EF8D
                 !BYTE $77 ; w   ;EF8E
                 !BYTE $B9       ;EF8F
                 !BYTE $7A ; z   ;EF90
                 !BYTE $C8       ;EF91
                 !BYTE $9C       ;EF92
                 !BYTE $89       ;EF93
                 !BYTE $88       ;EF94
                 !BYTE $78 ; x   ;EF95
                 !BYTE $87       ;EF96
                 !BYTE $68 ; h   ;EF97
                 !BYTE $66 ; f   ;EF98
                 !BYTE $56 ; V   ;EF99
                 !BYTE $66 ; f   ;EF9A
                 !BYTE $67 ; g   ;EF9B
                 !BYTE $65 ; e   ;EF9C
                 !BYTE $89       ;EF9D
                 !BYTE $76 ; v   ;EF9E
                 !BYTE $A9       ;EF9F
                 !BYTE $99       ;EFA0
                 !BYTE $BA       ;EFA1
                 !BYTE $8C       ;EFA2
                 !BYTE $99       ;EFA3
                 !BYTE $78 ; x   ;EFA4
                 !BYTE $88       ;EFA5
                 !BYTE $77 ; w   ;EFA6
                 !BYTE $77 ; w   ;EFA7
                 !BYTE $66 ; f   ;EFA8
                 !BYTE $66 ; f   ;EFA9
                 !BYTE $66 ; f   ;EFAA
                 !BYTE $66 ; f   ;EFAB
                 !BYTE $66 ; f   ;EFAC
                 !BYTE $88       ;EFAD
                 !BYTE $77 ; w   ;EFAE
                 !BYTE $A9       ;EFAF
                 !BYTE $89       ;EFB0
                 !BYTE $C9       ;EFB1
                 !BYTE $9C       ;EFB2
                 !BYTE $88       ;EFB3
                 !BYTE $88       ;EFB4
                 !BYTE $78 ; x   ;EFB5
                 !BYTE $86       ;EFB6
                 !BYTE $68 ; h   ;EFB7
                 !BYTE $75 ; u   ;EFB8
                 !BYTE $56 ; V   ;EFB9
                 !BYTE $76 ; v   ;EFBA
                 !BYTE $67 ; g   ;EFBB
                 !BYTE $75 ; u   ;EFBC
                 !BYTE $89       ;EFBD
                 !BYTE $76 ; v   ;EFBE
                 !BYTE $A9       ;EFBF
                 !BYTE $89       ;EFC0
                 !BYTE $B9       ;EFC1
                 !BYTE $9C       ;EFC2
                 !BYTE $89       ;EFC3
                 !BYTE $87       ;EFC4
                 !BYTE $88       ;EFC5
                 !BYTE $77 ; w   ;EFC6
                 !BYTE $67 ; g   ;EFC7
                 !BYTE $66 ; f   ;EFC8
                 !BYTE $66 ; f   ;EFC9
                 !BYTE $66 ; f   ;EFCA
                 !BYTE $76 ; v   ;EFCB
                 !BYTE $66 ; f   ;EFCC
                 !BYTE $88       ;EFCD
                 !BYTE $76 ; v   ;EFCE
                 !BYTE $B9       ;EFCF
                 !BYTE $79 ; y   ;EFD0
                 !BYTE $C8       ;EFD1
                 !BYTE $9C       ;EFD2
                 !BYTE $88       ;EFD3
                 !BYTE $89       ;EFD4
                 !BYTE $88       ;EFD5
                 !BYTE $77 ; w   ;EFD6
                 !BYTE $78 ; x   ;EFD7
                 !BYTE $66 ; f   ;EFD8
                 !BYTE $66 ; f   ;EFD9
                 !BYTE $56 ; V   ;EFDA
                 !BYTE $76 ; v   ;EFDB
                 !BYTE $76 ; v   ;EFDC
                 !BYTE $78 ; x   ;EFDD
                 !BYTE $86       ;EFDE
                 !BYTE $A9       ;EFDF
                 !BYTE $89       ;EFE0
                 !BYTE $B8       ;EFE1
                 !BYTE $8C       ;EFE2
                 !BYTE $88       ;EFE3
                 !BYTE $88       ;EFE4
                 !BYTE $78 ; x   ;EFE5
                 !BYTE $77 ; w   ;EFE6
                 !BYTE $78 ; x   ;EFE7
                 !BYTE $76 ; v   ;EFE8
                 !BYTE $67 ; g   ;EFE9
                 !BYTE $66 ; f   ;EFEA
                 !BYTE $76 ; v   ;EFEB
                 !BYTE $67 ; g   ;EFEC
                 !BYTE $76 ; v   ;EFED
                 !BYTE $88       ;EFEE
                 !BYTE $88       ;EFEF
                 !BYTE $88       ;EFF0
                 !BYTE $C9       ;EFF1
                 !BYTE $8C       ;EFF2
                 !BYTE $98       ;EFF3
                 !BYTE $89       ;EFF4
                 !BYTE $67 ; g   ;EFF5
                 !BYTE $45 ; E   ;EFF6
                 !BYTE $86       ;EFF7
                 !BYTE $99       ;EFF8
                 !BYTE $AA       ;EFF9
                 !BYTE $68 ; h   ;EFFA
                 !BYTE $76 ; v   ;EFFB
                 !BYTE $77 ; w   ;EFFC
                 !BYTE $88       ;EFFD
                 !BYTE $56 ; V   ;EFFE
                 !BYTE $54 ; T   ;EFFF
                 !BYTE $96       ;F000
                 !BYTE $DB       ;F001
                 !BYTE $8C       ;F002
                 !BYTE $98       ;F003
                 !BYTE $78 ; x   ;F004
                 !BYTE $67 ; g   ;F005
                 !BYTE $55 ; U   ;F006
                 !BYTE $87       ;F007
                 !BYTE $88       ;F008
                 !BYTE $99       ;F009
                 !BYTE $78 ; x   ;F00A
                 !BYTE $77 ; w   ;F00B
                 !BYTE $87       ;F00C
                 !BYTE $78 ; x   ;F00D
                 !BYTE $56 ; V   ;F00E
                 !BYTE $54 ; T   ;F00F
                 !BYTE $97       ;F010
                 !BYTE $DB       ;F011
                 !BYTE $8C       ;F012
                 !BYTE $88       ;F013
                 !BYTE $78 ; x   ;F014
                 !BYTE $67 ; g   ;F015
                 !BYTE $66 ; f   ;F016
                 !BYTE $86       ;F017
                 !BYTE $98       ;F018
                 !BYTE $99       ;F019
                 !BYTE $78 ; x   ;F01A
                 !BYTE $87       ;F01B
                 !BYTE $88       ;F01C
                 !BYTE $78 ; x   ;F01D
                 !BYTE $46 ; F   ;F01E
                 !BYTE $54 ; T   ;F01F
                 !BYTE $97       ;F020
                 !BYTE $CB       ;F021
                 !BYTE $8C       ;F022
                 !BYTE $88       ;F023
                 !BYTE $88       ;F024
                 !BYTE $67 ; g   ;F025
                 !BYTE $66 ; f   ;F026
                 !BYTE $77 ; w   ;F027
                 !BYTE $98       ;F028
                 !BYTE $99       ;F029
                 !BYTE $78 ; x   ;F02A
                 !BYTE $76 ; v   ;F02B
                 !BYTE $88       ;F02C
                 !BYTE $88       ;F02D
                 !BYTE $56 ; V   ;F02E
                 !BYTE $54 ; T   ;F02F
                 !BYTE $97       ;F030
                 !BYTE $CB       ;F031
                 !BYTE $8C       ;F032
                 !BYTE $88       ;F033
                 !BYTE $78 ; x   ;F034
                 !BYTE $67 ; g   ;F035
                 !BYTE $66 ; f   ;F036
                 !BYTE $87       ;F037
                 !BYTE $88       ;F038
                 !BYTE $88       ;F039
                 !BYTE $78 ; x   ;F03A
                 !BYTE $77 ; w   ;F03B
                 !BYTE $88       ;F03C
                 !BYTE $77 ; w   ;F03D
                 !BYTE $56 ; V   ;F03E
                 !BYTE $65 ; e   ;F03F
                 !BYTE $98       ;F040
                 !BYTE $BA       ;F041
                 !BYTE $8C       ;F042
                 !BYTE $88       ;F043
                 !BYTE $78 ; x   ;F044
                 !BYTE $77 ; w   ;F045
                 !BYTE $66 ; f   ;F046
                 !BYTE $87       ;F047
                 !BYTE $88       ;F048
                 !BYTE $88       ;F049
                 !BYTE $77 ; w   ;F04A
                 !BYTE $87       ;F04B
                 !BYTE $88       ;F04C
                 !BYTE $67 ; g   ;F04D
                 !BYTE $66 ; f   ;F04E
                 !BYTE $76 ; v   ;F04F
                 !BYTE $98       ;F050
                 !BYTE $BA       ;F051
                 !BYTE $6C ; l   ;F052
                 !BYTE $66 ; f   ;F053
                 !BYTE $56 ; V   ;F054
                 !BYTE $76 ; v   ;F055
                 !BYTE $98       ;F056
                 !BYTE $99       ;F057
                 !BYTE $79 ; y   ;F058
                 !BYTE $D9       ;F059
                 !BYTE $7C ; |   ;F05A
                 !BYTE $66 ; f   ;F05B
                 !BYTE $57 ; W   ;F05C
                 !BYTE $75 ; u   ;F05D
                 !BYTE $88       ;F05E
                 !BYTE $99       ;F05F
                 !BYTE $67 ; g   ;F060
                 !BYTE $FA       ;F061
                 !BYTE $8C       ;F062
                 !BYTE $87       ;F063
                 !BYTE $46 ; F   ;F064
                 !BYTE $54 ; T   ;F065
                 !BYTE $86       ;F066
                 !BYTE $A9       ;F067
                 !BYTE $69 ; i   ;F068
                 !BYTE $F9       ;F069
                 !BYTE $8C       ;F06A
                 !BYTE $87       ;F06B
                 !BYTE $47 ; G   ;F06C
                 !BYTE $43 ; C   ;F06D
                 !BYTE $65 ; e   ;F06E
                 !BYTE $A9       ;F06F
                 !BYTE $79 ; y   ;F070
                 !BYTE $FA       ;F071
                 !BYTE $7C ; |   ;F072
                 !BYTE $87       ;F073
                 !BYTE $68 ; h   ;F074
                 !BYTE $34 ; 4   ;F075
                 !BYTE $53 ; S   ;F076
                 !BYTE $B8       ;F077
                 !BYTE $7A ; z   ;F078
                 !BYTE $F9       ;F079
                 !BYTE $6C ; l   ;F07A
                 !BYTE $87       ;F07B
                 !BYTE $68 ; h   ;F07C
                 !BYTE $34 ; 4   ;F07D
                 !BYTE $53 ; S   ;F07E
                 !BYTE $B9       ;F07F
                 !BYTE $7A ; z   ;F080
                 !BYTE $F9       ;F081
                 !BYTE $7C ; |   ;F082
                 !BYTE $77 ; w   ;F083
                 !BYTE $47 ; G   ;F084
                 !BYTE $32 ; 2   ;F085
                 !BYTE $75 ; u   ;F086
                 !BYTE $BB       ;F087
                 !BYTE $78 ; x   ;F088
                 !BYTE $FA       ;F089
                 !BYTE $7C ; |   ;F08A
                 !BYTE $75 ; u   ;F08B
                 !BYTE $67 ; g   ;F08C
                 !BYTE $34 ; 4   ;F08D
                 !BYTE $63 ; c   ;F08E
                 !BYTE $BA       ;F08F
                 !BYTE $79 ; y   ;F090
                 !BYTE $FA       ;F091
                 !BYTE $6C ; l   ;F092
                 !BYTE $56 ; V   ;F093
                 !BYTE $65 ; e   ;F094
                 !BYTE $46 ; F   ;F095
                 !BYTE $64 ; d   ;F096
                 !BYTE $A9       ;F097
                 !BYTE $88       ;F098
                 !BYTE $FC       ;F099
                 !BYTE $6C ; l   ;F09A
                 !BYTE $45 ; E   ;F09B
                 !BYTE $75 ; u   ;F09C
                 !BYTE $35 ; 5   ;F09D
                 !BYTE $94       ;F09E
                 !BYTE $9B       ;F09F
                 !BYTE $97       ;F0A0
                 !BYTE $FC       ;F0A1
                 !BYTE $6C ; l   ;F0A2
                 !BYTE $56 ; V   ;F0A3
                 !BYTE $54 ; T   ;F0A4
                 !BYTE $35 ; 5   ;F0A5
                 !BYTE $83       ;F0A6
                 !BYTE $CC       ;F0A7
                 !BYTE $68 ; h   ;F0A8
                 !BYTE $FB       ;F0A9
                 !BYTE $6C ; l   ;F0AA
                 !BYTE $89       ;F0AB
                 !BYTE $45 ; E   ;F0AC
                 !BYTE $34 ; 4   ;F0AD
                 !BYTE $84       ;F0AE
                 !BYTE $BC       ;F0AF
                 !BYTE $46 ; F   ;F0B0
                 !BYTE $F9       ;F0B1
                 !BYTE $AC       ;F0B2
                 !BYTE $36 ; 6   ;F0B3
                 !BYTE $32 ; 2   ;F0B4
                 !BYTE $54 ; T   ;F0B5
                 !BYTE $86       ;F0B6
                 !BYTE $89       ;F0B7
                 !BYTE $66 ; f   ;F0B8
                 !BYTE $FA       ;F0B9
                 !BYTE $6C ; l   ;F0BA
                 !BYTE $34 ; 4   ;F0BB
                 !BYTE $64 ; d   ;F0BC
                 !BYTE $78 ; x   ;F0BD
                 !BYTE $54 ; T   ;F0BE
                 !BYTE $87       ;F0BF
                 !BYTE $98       ;F0C0
                 !BYTE $EC       ;F0C1
                 !BYTE $6C ; l   ;F0C2
                 !BYTE $55 ; U   ;F0C3
                 !BYTE $55 ; U   ;F0C4
                 !BYTE $56 ; V   ;F0C5
                 !BYTE $65 ; e   ;F0C6
                 !BYTE $97       ;F0C7
                 !BYTE $AA       ;F0C8
                 !BYTE $EC       ;F0C9
                 !BYTE $8C       ;F0CA
                 !BYTE $88       ;F0CB
                 !BYTE $78 ; x   ;F0CC
                 !BYTE $77 ; w   ;F0CD
                 !BYTE $77 ; w   ;F0CE
                 !BYTE $77 ; w   ;F0CF
                 !BYTE $67 ; g   ;F0D0
                 !BYTE $66 ; f   ;F0D1
                 !BYTE $76 ; v   ;F0D2
                 !BYTE $77 ; w   ;F0D3
                 !BYTE $76 ; v   ;F0D4
                 !BYTE $77 ; w   ;F0D5
                 !BYTE $77 ; w   ;F0D6
                 !BYTE $98       ;F0D7
                 !BYTE $AA       ;F0D8
                 !BYTE $BA       ;F0D9
                 !BYTE $7C ; |   ;F0DA
                 !BYTE $87       ;F0DB
                 !BYTE $88       ;F0DC
                 !BYTE $77 ; w   ;F0DD
                 !BYTE $77 ; w   ;F0DE
                 !BYTE $77 ; w   ;F0DF
                 !BYTE $77 ; w   ;F0E0
                 !BYTE $77 ; w   ;F0E1
                 !BYTE $77 ; w   ;F0E2
                 !BYTE $77 ; w   ;F0E3
                 !BYTE $66 ; f   ;F0E4
                 !BYTE $76 ; v   ;F0E5
                 !BYTE $77 ; w   ;F0E6
                 !BYTE $98       ;F0E7
                 !BYTE $AA       ;F0E8
                 !BYTE $BA       ;F0E9
                 !BYTE $7C ; |   ;F0EA
                 !BYTE $77 ; w   ;F0EB
                 !BYTE $77 ; w   ;F0EC
                 !BYTE $88       ;F0ED
                 !BYTE $98       ;F0EE
                 !BYTE $99       ;F0EF
                 !BYTE $89       ;F0F0
                 !BYTE $78 ; x   ;F0F1
                 !BYTE $56 ; V   ;F0F2
                 !BYTE $55 ; U   ;F0F3
                 !BYTE $44 ; D   ;F0F4
                 !BYTE $65 ; e   ;F0F5
                 !BYTE $66 ; f   ;F0F6
                 !BYTE $98       ;F0F7
                 !BYTE $BA       ;F0F8
                 !BYTE $CB       ;F0F9
                 !BYTE $7C ; |   ;F0FA
                 !BYTE $77 ; w   ;F0FB
                 !BYTE $67 ; g   ;F0FC
                 !BYTE $87       ;F0FD
                 !BYTE $88       ;F0FE
                 !BYTE $A9       ;F0FF
                 !BYTE $89       ;F100
                 !BYTE $98       ;F101
                 !BYTE $79 ; y   ;F102
                 !BYTE $77 ; w   ;F103
                 !BYTE $56 ; V   ;F104
                 !BYTE $55 ; U   ;F105
                 !BYTE $44 ; D   ;F106
                 !BYTE $75 ; u   ;F107
                 !BYTE $B9       ;F108
                 !BYTE $EC       ;F109
                 !BYTE $9C       ;F10A
                 !BYTE $78 ; x   ;F10B
                 !BYTE $66 ; f   ;F10C
                 !BYTE $65 ; e   ;F10D
                 !BYTE $87       ;F10E
                 !BYTE $98       ;F10F
                 !BYTE $99       ;F110
                 !BYTE $88       ;F111
                 !BYTE $88       ;F112
                 !BYTE $77 ; w   ;F113
                 !BYTE $77 ; w   ;F114
                 !BYTE $67 ; g   ;F115
                 !BYTE $45 ; E   ;F116
                 !BYTE $64 ; d   ;F117
                 !BYTE $98       ;F118
                 !BYTE $EB       ;F119
                 !BYTE $8C       ;F11A
                 !BYTE $89       ;F11B
                 !BYTE $77 ; w   ;F11C
                 !BYTE $56 ; V   ;F11D
                 !BYTE $65 ; e   ;F11E
                 !BYTE $87       ;F11F
                 !BYTE $99       ;F120
                 !BYTE $99       ;F121
                 !BYTE $79 ; y   ;F122
                 !BYTE $76 ; v   ;F123
                 !BYTE $88       ;F124
                 !BYTE $78 ; x   ;F125
                 !BYTE $46 ; F   ;F126
                 !BYTE $54 ; T   ;F127
                 !BYTE $96       ;F128
                 !BYTE $EB       ;F129
                 !BYTE $9C       ;F12A
                 !BYTE $78 ; x   ;F12B
                 !BYTE $77 ; w   ;F12C
                 !BYTE $77 ; w   ;F12D
                 !BYTE $66 ; f   ;F12E
                 !BYTE $76 ; v   ;F12F
                 !BYTE $87       ;F130
                 !BYTE $AA       ;F131
                 !BYTE $8A       ;F132
                 !BYTE $66 ; f   ;F133
                 !BYTE $76 ; v   ;F134
                 !BYTE $87       ;F135
                 !BYTE $77 ; w   ;F136
                 !BYTE $56 ; V   ;F137
                 !BYTE $75 ; u   ;F138
                 !BYTE $EB       ;F139
                 !BYTE $9C       ;F13A
                 !BYTE $78 ; x   ;F13B
                 !BYTE $77 ; w   ;F13C
                 !BYTE $66 ; f   ;F13D
                 !BYTE $76 ; v   ;F13E
                 !BYTE $78 ; x   ;F13F
                 !BYTE $87       ;F140
                 !BYTE $99       ;F141
                 !BYTE $99       ;F142
                 !BYTE $78 ; x   ;F143
                 !BYTE $66 ; f   ;F144
                 !BYTE $66 ; f   ;F145
                 !BYTE $77 ; w   ;F146
                 !BYTE $67 ; g   ;F147
                 !BYTE $65 ; e   ;F148
                 !BYTE $EA       ;F149
                 !BYTE $9C       ;F14A
                 !BYTE $78 ; x   ;F14B
                 !BYTE $67 ; g   ;F14C
                 !BYTE $77 ; w   ;F14D
                 !BYTE $87       ;F14E
                 !BYTE $67 ; g   ;F14F
                 !BYTE $76 ; v   ;F150
                 !BYTE $A9       ;F151
                 !BYTE $9A       ;F152
                 !BYTE $67 ; g   ;F153
                 !BYTE $76 ; v   ;F154
                 !BYTE $88       ;F155
                 !BYTE $77 ; w   ;F156
                 !BYTE $66 ; f   ;F157
                 !BYTE $75 ; u   ;F158
                 !BYTE $DA       ;F159
                 !BYTE $8C       ;F15A
                 !BYTE $78 ; x   ;F15B
                 !BYTE $77 ; w   ;F15C
                 !BYTE $77 ; w   ;F15D
                 !BYTE $77 ; w   ;F15E
                 !BYTE $87       ;F15F
                 !BYTE $99       ;F160
                 !BYTE $89       ;F161
                 !BYTE $77 ; w   ;F162
                 !BYTE $77 ; w   ;F163
                 !BYTE $77 ; w   ;F164
                 !BYTE $77 ; w   ;F165
                 !BYTE $56 ; V   ;F166
                 !BYTE $65 ; e   ;F167
                 !BYTE $97       ;F168
                 !BYTE $CB       ;F169
                 !BYTE $7C ; |   ;F16A
                 !BYTE $77 ; w   ;F16B
                 !BYTE $87       ;F16C
                 !BYTE $88       ;F16D
                 !BYTE $88       ;F16E
                 !BYTE $88       ;F16F
                 !BYTE $88       ;F170
                 !BYTE $88       ;F171
                 !BYTE $88       ;F172
                 !BYTE $77 ; w   ;F173
                 !BYTE $66 ; f   ;F174
                 !BYTE $66 ; f   ;F175
                 !BYTE $66 ; f   ;F176
                 !BYTE $77 ; w   ;F177
                 !BYTE $98       ;F178
                 !BYTE $BA       ;F179
                 !BYTE $7C ; |   ;F17A
                 !BYTE $77 ; w   ;F17B
                 !BYTE $87       ;F17C
                 !BYTE $88       ;F17D
                 !BYTE $88       ;F17E
                 !BYTE $88       ;F17F
                 !BYTE $88       ;F180
                 !BYTE $88       ;F181
                 !BYTE $78 ; x   ;F182
                 !BYTE $77 ; w   ;F183
                 !BYTE $66 ; f   ;F184
                 !BYTE $55 ; U   ;F185
                 !BYTE $66 ; f   ;F186
                 !BYTE $87       ;F187
                 !BYTE $99       ;F188
                 !BYTE $AA       ;F189
                 !BYTE $6C ; l   ;F18A
                 !BYTE $77 ; w   ;F18B
                 !BYTE $87       ;F18C
                 !BYTE $88       ;F18D
                 !BYTE $88       ;F18E
                 !BYTE $88       ;F18F
                 !BYTE $88       ;F190
                 !BYTE $78 ; x   ;F191
                 !BYTE $77 ; w   ;F192
                 !BYTE $67 ; g   ;F193
                 !BYTE $66 ; f   ;F194
                 !BYTE $66 ; f   ;F195
                 !BYTE $76 ; v   ;F196
                 !BYTE $88       ;F197
                 !BYTE $99       ;F198
                 !BYTE $BA       ;F199
                 !BYTE $7C ; |   ;F19A
                 !BYTE $77 ; w   ;F19B
                 !BYTE $66 ; f   ;F19C
                 !BYTE $66 ; f   ;F19D
                 !BYTE $77 ; w   ;F19E
                 !BYTE $67 ; g   ;F19F
                 !BYTE   0       ;F1A0







SEGMENT_0800_START:
  !pseudopc $0800 {
; Insert code that will be moved to $0800 here:
;* = $0800
                !BYTE $10
                !BYTE $10
                !BYTE $10
                !BYTE $10
                !BYTE  $E
                !BYTE  $E
                !BYTE $10
                !BYTE $12
                !BYTE $10
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $C
                !BYTE  $C
                !BYTE  $C
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE $10
                !BYTE $10
                !BYTE $10
                !BYTE  $E
                !BYTE  $A
                !BYTE  $A
                !BYTE  $C
                !BYTE $10
                !BYTE $16
                !BYTE $1C
                !BYTE $10
                !BYTE $10
                !BYTE $11
                !BYTE $11
                !BYTE  $F
                !BYTE  $F
                !BYTE $10
                !BYTE $12
                !BYTE $10
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $C
                !BYTE  $C
                !BYTE  $E
                !BYTE  $E
                !BYTE  $F
                !BYTE  $F
                !BYTE  $F
                !BYTE  $E
                !BYTE  $E
                !BYTE  $D
                !BYTE  $D
                !BYTE $10
                !BYTE $10
                !BYTE  $D
                !BYTE  $C
                !BYTE  $C
                !BYTE  $E
                !BYTE $12
                !BYTE $18
                !BYTE $1C
                !BYTE $10
                !BYTE $10
                !BYTE $10
                !BYTE $10
                !BYTE  $E
                !BYTE  $E
                !BYTE $10
                !BYTE $12
                !BYTE $10
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $C
                !BYTE  $C
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $C
                !BYTE  $C
                !BYTE $10
                !BYTE $10
                !BYTE  $C
                !BYTE  $C
                !BYTE  $C
                !BYTE  $E
                !BYTE $12
                !BYTE $18
                !BYTE $1C
                !BYTE $10
                !BYTE $10
                !BYTE $11
                !BYTE $11
                !BYTE  $F
                !BYTE  $F
                !BYTE $10
                !BYTE $12
                !BYTE $10
                !BYTE  $E
                !BYTE  $E
                !BYTE  $E
                !BYTE  $C
                !BYTE  $C
                !BYTE  $D
                !BYTE  $E
                !BYTE  $F
                !BYTE  $F
                !BYTE  $F
                !BYTE  $E
                !BYTE  $E
                !BYTE  $D
                !BYTE  $E
                !BYTE $10
                !BYTE $10
                !BYTE  $E
byte_87A:       !BYTE $C                ; DATA XREF: RAM:loc_8A5↓r
                !BYTE  $C
                !BYTE  $E
                !BYTE $11
                !BYTE $17
byte_87F:       !BYTE $1C               ; DATA XREF: RAM:loc_884↓r

; =============== S U B R O U T I N E =======================================
; Attributes: thunk
sub_880:                                ; CODE XREF: sub_BED9+1E↓p
                                        ; sub_BED9+2F↓p
                JMP     sub_C2F
; End of function sub_880
; ---------------------------------------------------------------------------
                PHA
loc_884:                                ; DATA XREF: RAM:0892↓w
                                        ; RAM:089C↓r ...
                LDA     byte_87F
                LSR
                STA     $d418
                CMP     $dd0d
                DEC     byte_AD
                BEQ     loc_897
                INC     loc_884+1
                PLA
                RTI
; ---------------------------------------------------------------------------
loc_897:                                ; CODE XREF: RAM:0890↑j
                LDA     #$A4
                STA     byte_FFFA
                LDA     loc_884+1
                STA     loc_8A5+1
                PLA
                RTI
; ---------------------------------------------------------------------------
                PHA
loc_8A5:                                ; DATA XREF: RAM:089F↑w
                                        ; RAM:08B3↓w
                LDA     byte_87A
                LSR
                STA     $d418
                CMP     $dd0d
                DEC     byte_AE
                BEQ     loc_8B8
                DEC     loc_8A5+1
                PLA
                RTI
; ---------------------------------------------------------------------------
loc_8B8:                                ; CODE XREF: RAM:08B1↑j
                LDA     byte_AF
                BEQ     loc_8F2
                LDA     #$C3
                STA     byte_FFFA
                PLA
                RTI
; ---------------------------------------------------------------------------
                PHA
                NOP
                LDA     #$E
                LSR
                STA     $d418
                CMP     $dd0d
                DEC     byte_AF
                BEQ     loc_8F2
                LDA     #$D9
                STA     byte_FFFA
                PLA
                RTI
; ---------------------------------------------------------------------------
                CMP     $dd0d
                DEC     byte_AF
                BEQ     loc_8F1
                RTI
; ---------------------------------------------------------------------------
                PHA
                LDA     #$90
                STA     $dd0f
                LDA     #7
                STA     $d418
                CMP     $dd0d
                PLA
                RTI
; ---------------------------------------------------------------------------
loc_8F1:                                ; CODE XREF: RAM:08DE↑j
                PHA
loc_8F2:                                ; CODE XREF: RAM:08BA↑j
                                        ; RAM:08D0↑j
                LDA     byte_CF1
                STA     byte_FFFA
                LDA     byte_CF2
                STA     loc_884+1
                LDA     byte_CF3
                STA     byte_AD
                STA     byte_AE
                LDA     byte_CF4
                STA     byte_AF
                CLD
                INC     byte_CF7
                BEQ     loc_913
loc_910:                                ; DATA XREF: RAM:0A10↓w
                                        ; RAM:0A36↓w ...
                JMP     loc_939
; ---------------------------------------------------------------------------
loc_913:                                ; CODE XREF: RAM:090E↑j
                TXA
                PHA
                TYA
                PHA
                INC     byte_CF5
                BNE     loc_91F
                JSR     loc_9B6
loc_91F:                                ; CODE XREF: RAM:091A↑j
                LDA     byte_CF6
                STA     byte_CF7
                LDA     byte_CF2
                AND     #$40 ; '@'
                EOR     #$40 ; '@'
                TAX
                CLC
loc_92E:                                ; DATA XREF: RAM:09BC↓w
                                        ; RAM:loc_A1E↓w ...
                JSR     sub_998
                PLA
                TAY
                PLA
                TAX
                PLA
                RTI
; ---------------------------------------------------------------------------
                PLA
                RTI
; ---------------------------------------------------------------------------
loc_939:                                ; CODE XREF: RAM:loc_910↑j
                TXA
                PHA
                TYA
                PHA
                LDA     byte_CFA
                CMP     byte_CF2
                BEQ     loc_948
                JSR     loc_BFD
loc_948:                                ; CODE XREF: RAM:0943↑j
                JSR     sub_B1D
                PLA
                TAY
                PLA
                TAX
                PLA
                RTI
; ---------------------------------------------------------------------------
                LDA     byte_CF3
                CMP     #$10
                BEQ     loc_96B
                SEC
                SBC     byte_CF9
                STA     byte_CF3
                LDA     byte_CF2
                CLC
                ADC     byte_CF9
                STA     byte_CF2
                PLA
                RTI
; ---------------------------------------------------------------------------
loc_96B:                                ; CODE XREF: RAM:0956↑j
                LDA     byte_CF2
                AND     #$40 ; '@'
                STA     byte_CF2
                LDA     byte_CF8
                STA     byte_CF3
                PLA
                RTI
; ---------------------------------------------------------------------------
                LDA     #$E1
                STA     byte_CF1
                RTS
; =============== S U B R O U T I N E =======================================
sub_981:                                ; CODE XREF: sub_C89+A↓p
                LDA     #$C3
                STA     byte_CF1
                LDA     #$80
                STA     byte_CF4
                RTS
; End of function sub_981
; ---------------------------------------------------------------------------
                JMP     loc_B73
; ---------------------------------------------------------------------------
                JMP     loc_BE3
; ---------------------------------------------------------------------------
                JSR     loc_A68
                JMP     loc_99B
; =============== S U B R O U T I N E =======================================
sub_998:                                ; CODE XREF: RAM:loc_92E↑p
                JSR     loc_AE5
loc_99B:                                ; CODE XREF: RAM:0995↑j
                LDA     loc_9B6+1
                ASL
                BPL     loc_9B0
                ROR
                EOR     #$40 ; '@'
                STA     loc_9B6+1
                LDA     byte_CFA
                STA     byte_CF2
                JMP     sub_B1D
; ---------------------------------------------------------------------------
loc_9B0:                                ; CODE XREF: sub_998+7↑j
                JSR     loc_BFD
                JMP     sub_B1D
; End of function sub_998
; ---------------------------------------------------------------------------
loc_9B6:                                ; CODE XREF: RAM:091C↑p
                                        ; DATA XREF: sub_998:loc_99B↑r ...
                LDA     #$C
                BPL     loc_9C0
                LDA     #$7B ; '{'
                STA     loc_92E+1
                RTS
; ---------------------------------------------------------------------------
loc_9C0:                                ; CODE XREF: RAM:09B8↑j
                LDY     #0
                LDA     ($A5),Y
                ORA     #$C0
                STA     byte_CF5
                INY
                LDA     ($A5),Y
                LSR
                LSR
                LSR
                ORA     #$E0
                STA     byte_CF6
                BCS     loc_A4B
                INY
                LDA     ($A5),Y
                ADC     byte_CFE
                STA     byte_A9
                INY
                LDA     ($A5),Y
                STA     loc_9B6+1
                AND     #$3F ; '?'
                ADC     byte_CFF
                STA     byte_AA
                LDA     #$83
                STA     byte_CF1
                LDY     #1
                LDA     ($A5),Y
                AND     #3
                TAX
                CMP     #2
                BPL     loc_A24
                LDY     #0
                LDA     ($A5),Y
                AND     #$40 ; '@'
                BNE     loc_A05
                LDA     #$20 ; ' '
loc_A05:                                ; CODE XREF: RAM:0A01↑j
                STA     byte_CF8
                LSR
                LSR
                LSR
                STA     byte_CF9
                LDA     #$51 ; 'Q'
                STA     loc_910+1
                STY     byte_CF4
                TXA
                LSR
                LDA     #$8C
                BCS     loc_A1E
                LDA     #$8F
loc_A1E:                                ; CODE XREF: RAM:0A1A↑j
                STA     loc_92E+1
                JMP     loc_A5C
; ---------------------------------------------------------------------------
loc_A24:                                ; CODE XREF: RAM:09F9↑j
                LDY     #0
                LDA     ($A5),Y
                ROL
                ROL
                ROL
                AND     #3
                TAY
                LDA     $A47,Y
                STA     byte_CF3
                LDA     #$39 ; '9'
                STA     loc_910+1
                TXA
                LSR
                LDA     #$92
                BCS     loc_A41
                LDA     #$98
loc_A41:                                ; CODE XREF: RAM:0A3D↑j
                STA     loc_92E+1
                JMP     loc_A5C
; ---------------------------------------------------------------------------
                !BYTE   8
                !BYTE $10
                !BYTE $18
                !BYTE $20
; ---------------------------------------------------------------------------
loc_A4B:                                ; CODE XREF: RAM:09D4↑j
                LDY     #3
                LDA     ($A5),Y
                STA     loc_9B6+1
                LDA     #$37 ; '7'
                STA     loc_910+1
                LDA     #$81
                STA     loc_92E+1
loc_A5C:                                ; CODE XREF: RAM:0A21↑j
                                        ; RAM:0A44↑j
                LDA     byte_A5
                CLC
                ADC     #4
                STA     byte_A5
                BCC     locret_A67
                INC     byte_A6
locret_A67:                             ; CODE XREF: RAM:0A63↑j
loc_A68:                                ; CODE XREF: RAM:0992↑p
loc_A75:                                ; CODE XREF: RAM:0BFA↓j
loc_A92:                                ; CODE XREF: RAM:0AD6↓j
loc_AA2:                                ; DATA XREF: RAM:loc_A75↑w
loc_AAB:                                ; CODE XREF: RAM:0A8F↑j
loc_AD4:                                ; CODE XREF: RAM:0AD0↑j
                RTS


;0a68:
  !BYTE 0,0,0,0,0,0,0,0
;0a70:
  !BYTE 0,0,0,0,0,0,0,0
  !BYTE 0,0,0,0,0,0,0,0
;0a80:
  !BYTE 0,0,0,0,0,0,0,0
  !BYTE 0,0,0,0,0,0,0,0
;0a90:
  !BYTE 0,0,0,0,0,0,0,0
  !BYTE 0,0,0,0,0,0,0,0
;0aa0:
  !BYTE 0,0,0,0,0,0,0,0
  !BYTE 0,0,0,0,0,0,0,0
;0ab0:
  !BYTE 0,0,0,0,0,0,0,0
  !BYTE 0,0,0,0,0,0,0,0
;0ac0:
  !BYTE 0,0,0,0,0,0,0,0
  !BYTE 0,0,0,0,0,0,0,0
;0ad0:
  !BYTE 0,0,0,0,0,0,0,0
  !BYTE 0

;* = $ad9
; ---------------------------------------------------------------------------
at_AD9:         !BYTE  $C
                !BYTE  $E
                !BYTE $10
                !BYTE $12
                !BYTE   8
                !BYTE  $C
                !BYTE $10
                !BYTE $14
                !BYTE   2
                !BYTE  $A
                !BYTE $12
                !BYTE $1A
; ---------------------------------------------------------------------------
loc_AE5:                                ; CODE XREF: sub_998↑p
                ADC     byte_CF3
                STA     loc_B18+1
                STX     byte_CFA
                LDY     #0
                LDA     ($A9),Y
                LSR
                LSR
                LSR
                AND     #$1E
                STA     $800,X
                INX
                JMP     loc_B0E
; ---------------------------------------------------------------------------
loc_AFE:                                ; CODE XREF: RAM:0B1A↓j
                LDA     ($A9),Y
                ASL
                AND     #$1E
                STA     $800,X
                INX
                LDA     ($A9),Y
                LSR
                LSR
                LSR
                AND     #$1E
loc_B0E:                                ; CODE XREF: RAM:0AFB↑j
                STA     $800,X
                INX
                INC     byte_A9
                BNE     loc_B18
                INC     byte_AA
loc_B18:                                ; CODE XREF: RAM:0B14↑j
                                        ; DATA XREF: RAM:0AE8↑w
                CPX     #$60 ; '`'
                BNE     loc_AFE
                RTS
; =============== S U B R O U T I N E =======================================
sub_B1D:                                ; CODE XREF: RAM:loc_948↑p
                                        ; sub_998+15↑j ...
                INC     byte_CFB
                BEQ     loc_B31
                LDA     byte_CFC
                CLC
                ADC     byte_CFD
                STA     byte_CFC
                LSR
                STA     byte_CF4
                RTS
; ---------------------------------------------------------------------------
loc_B31:                                ; CODE XREF: sub_B1D+3↑j
                LDY     #0
                LDA     ($A7),Y
                TAX
                AND     #$FE
                STA     byte_CFC
                TXA
                LSR
                INC     byte_A7
                LDA     ($A7),Y
                ROR
                ROR
                ROR
                ROR
                ORA     #$E0
                STA     byte_CFB
                LDA     ($A7),Y
                AND     #$F
                TAY
                LDA     $B63,Y
                STA     byte_CFD
                INC     byte_A7
                BNE     loc_B5B
                INC     byte_A8
loc_B5B:                                ; CODE XREF: sub_B1D+3A↑j
                LDA     byte_CFC
                LSR
                STA     byte_CF4
                RTS
; End of function sub_B1D
; ---------------------------------------------------------------------------

at_B63:
                !BYTE $F4
                !BYTE $F6
                !BYTE $F8
                !BYTE $FA
                !BYTE $FC
                !BYTE $FE
                !BYTE $FF
                !BYTE   0
                !BYTE   1
                !BYTE   2
                !BYTE   4
                !BYTE   6
                !BYTE   8
                !BYTE  $A
                !BYTE  $C
                !BYTE  $E
; ---------------------------------------------------------------------------
loc_B73:                                ; CODE XREF: RAM:098C↑j
                STA     byte_CF2
                ADC     byte_CF8
                STA     loc_BAA+1
                LDA     byte_CF8
                STA     byte_CF3
                LDY     #0
                LDA     ($A9),Y
                LSR
                LSR
                TAY
                LDA     #$E
                BCC     loc_B8F
                LDA     #$10
loc_B8F:                                ; CODE XREF: RAM:0B8B↑j
                STA     $800,X
                INX
                JSR     sub_BC4
                JMP     loc_BA0
; ---------------------------------------------------------------------------
loc_B99:                                ; CODE XREF: RAM:0BAC↓j
                LDY     #0
                LDA     ($A9),Y
                JSR     sub_BAF
loc_BA0:                                ; CODE XREF: RAM:0B96↑j
                TYA
                JSR     sub_BAF
                INC     byte_A9
                BNE     loc_BAA
                INC     byte_AA
loc_BAA:                                ; CODE XREF: RAM:0BA6↑j
                                        ; DATA XREF: RAM:0B79↑w
                CPX     #$80
                BNE     loc_B99
                RTS
; =============== S U B R O U T I N E =======================================
sub_BAF:                                ; CODE XREF: RAM:0B9D↑p
                                        ; RAM:0BA1↑p
                LSR
                TAY
                LDA     #$E
                BCC     loc_BB7
                LDA     #$10
loc_BB7:                                ; CODE XREF: sub_BAF+4↑j
                STA     $800,X
                INX
                TYA
                LSR
                TAY
                LDA     #$E
                BCC     sub_BC4
                LDA     #$10
; End of function sub_BAF
; =============== S U B R O U T I N E =======================================
sub_BC4:                                ; CODE XREF: RAM:0B93↑p
                                        ; sub_BAF+11↑j
                STA     $800,X
                INX
                TYA
                LSR
                TAY
                LDA     #$E
                BCC     loc_BD1
                LDA     #$10
loc_BD1:                                ; CODE XREF: sub_BC4+9↑j
                STA     $800,X
                INX
                TYA
                LSR
                TAY
                LDA     #$E
                BCC     loc_BDE
                LDA     #$10
loc_BDE:                                ; CODE XREF: sub_BC4+16↑j
                STA     $800,X
                INX
                RTS
; End of function sub_BC4
; ---------------------------------------------------------------------------
loc_BE3:                                ; CODE XREF: RAM:098F↑j
                STA     byte_CF2
                ADC     byte_CF8
                STA     loc_AD4+1
                LDA     byte_CF8
                STA     byte_CF3
                LDY     #0
                LDA     ($A9),Y
                AND     #$FC
                ORA     #1
                JMP     loc_A75
; ---------------------------------------------------------------------------
loc_BFD:                                ; CODE XREF: RAM:0945↑p
                                        ; sub_998:loc_9B0↑p
                LDX     #0
                LDA     byte_CF2
                STA     loc_C1B+1
                LDA     byte_CFA
                STA     loc_C17+1
                LDA     byte_CF2
                AND     #$40 ; '@'
                EOR     #$40 ; '@'
                ORA     #$20 ; ' '
                STA     loc_C1F+1
loc_C17:                                ; CODE XREF: RAM:0C26↓j
                                        ; DATA XREF: RAM:0C08↑w
                LDA     $840,X
                SEC
loc_C1B:                                ; DATA XREF: RAM:0C02↑w
                ADC     $860,X
                ROR
loc_C1F:                                ; DATA XREF: RAM:0C14↑w
                                        ; RAM:0C28↓r
                STA     $820,X
                INX
                CPX     byte_CF3
                BNE     loc_C17
                LDA     loc_C1F+1
                STA     byte_CF2
                RTS
; =============== S U B R O U T I N E =======================================
sub_C2F:                                ; CODE XREF: sub_880↑j
; FUNCTION CHUNK AT RAM:0C68 SIZE 00000009 BYTES
                CMP     #$FF
                BEQ     loc_C52
                CMP     #$FE
                BEQ     sub_C60
                CMP     #$FD
                BEQ     loc_C68
                JSR     sub_CAB
                JSR     sub_C60
                BMI     locret_C5F
                LDA     #$A
                STA     byte_AC
                LDA     #8
                STA     byte_FFFB
                JSR     sub_C89
                JSR     sub_C71
loc_C52:                                ; CODE XREF: sub_C2F+2↑j
                                        ; sub_C60+5↓j ...
                LDA     $01
                LSR
                LSR
                LDA     #$80
                BCS     locret_C5F
                LDA     $dd0f
                AND     #1
locret_C5F:                             ; CODE XREF: sub_C2F+12↑j
                                        ; sub_C2F+29↑j
                RTS
; End of function sub_C2F
; =============== S U B R O U T I N E =======================================
sub_C60:                                ; CODE XREF: sub_C2F+6↑j
                                        ; sub_C2F+F↑p
                LDA     #$90
                STA     $dd0f
                JMP     loc_C52
; End of function sub_C60
; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR sub_C2F
loc_C68:                                ; CODE XREF: sub_C2F+A↑j
                STX     byte_CFE
                STY     byte_CFF
                JMP     loc_C52
; END OF FUNCTION CHUNK FOR sub_C2F
; =============== S U B R O U T I N E =======================================
sub_C71:                                ; CODE XREF: sub_C2F+20↑p
                LDA     #$91
                STA     $dd0f
                LDA     #$64 ; 'd'
                STA     $dd06
                LDA     #0
                STA     $dd07
                LDA     #$82
                STA     $dd0d
                LDA     $dd0d
                RTS
; End of function sub_C71
; =============== S U B R O U T I N E =======================================
sub_C89:                                ; CODE XREF: sub_C2F+1D↑p
                LDA     #$37 ; '7'
                STA     loc_910+1
                LDA     #$81
                STA     loc_92E+1
                JSR     sub_981
                LDA     #$FE
                STA     byte_CF6
                STA     byte_CF7
                STA     byte_CF5
                LDA     #$C3
                STA     byte_FFFA
                LDA     #1
                STA     byte_AF
                RTS
; End of function sub_C89
; =============== S U B R O U T I N E =======================================
sub_CAB:                                ; CODE XREF: sub_C2F+C↑p
                ROL
                ROL
                TAX
                AND     #$FC
                CLC
                ADC     byte_CFE
                STA     byte_A9
                TXA
                AND     #3
                ADC     byte_CFF
                STA     byte_AA
                LDY     #0
                LDA     ($A9),Y
                ADC     byte_CFE
                STA     byte_A7
                INY
                LDA     ($A9),Y
                ADC     byte_CFF
                STA     byte_A8
                LDA     #$FF
                STA     byte_CFB
                INY
                LDA     ($A9),Y
                CLC
                ADC     byte_CFE
                STA     byte_A5
                INY
                LDA     ($A9),Y
                ADC     byte_CFF
                STA     byte_A6
                LDA     #0
                STA     loc_9B6+1
                RTS
; End of function sub_CAB
; ---------------------------------------------------------------------------
at_CEB:         !BYTE $50 ; P
                !BYTE $54 ; T
                !BYTE $52 ; R
                !BYTE $20
                !BYTE $20
                !BYTE $20
byte_CF1:       !BYTE $83               ; DATA XREF: RAM:loc_8F2↑r
                                        ; RAM:097D↑w ...
byte_CF2:       !BYTE $20               ; DATA XREF: RAM:08F8↑r
                                        ; RAM:0925↑r ...
byte_CF3:       !BYTE $20               ; DATA XREF: RAM:08FE↑r
                                        ; RAM:0951↑r ...
byte_CF4:       !BYTE $4C               ; DATA XREF: RAM:0905↑r
                                        ; sub_981+7↑w ...
byte_CF5:       !BYTE $FE               ; DATA XREF: RAM:0917↑w
                                        ; RAM:09C6↑w ...
byte_CF6:       !BYTE $FD               ; DATA XREF: RAM:loc_91F↑r
                                        ; RAM:09D1↑w ...
byte_CF7:       !BYTE $FE               ; DATA XREF: RAM:090B↑w
                                        ; RAM:0922↑w ...
byte_CF8:       !BYTE $40               ; DATA XREF: RAM:0973↑r
                                        ; RAM:loc_A05↑w ...
byte_CF9:       !BYTE 8                 ; DATA XREF: RAM:0959↑r
                                        ; RAM:0963↑r ...
byte_CFA:       !BYTE $40               ; DATA XREF: RAM:093D↑r
                                        ; sub_998+F↑r ...
byte_CFB:       !BYTE $FB               ; DATA XREF: sub_B1D↑w
                                        ; sub_B1D+2A↑w ...
byte_CFC:       !BYTE $99               ; DATA XREF: sub_B1D+5↑r
                                        ; sub_B1D+C↑w ...
byte_CFD:       !BYTE 1                 ; DATA XREF: sub_B1D+9↑r
                                        ; sub_B1D+35↑w
byte_CFE:       !BYTE 0                 ; DATA XREF: RAM:09D9↑r
                                        ; sub_C2F:loc_C68↑w ...
byte_CFF:       !BYTE $E0               ; DATA XREF: RAM:09E6↑r
                                        ; sub_C2F+3C↑w ...


; End of psuedopc ZP_CODE:
}
SEGMENT_0800_END:


*=$f700
start:
  sei
  lda #$35
  sta $01
  jsr init_big_petscii

  lda #$25
  sta $01

;Move code into $0800-$0cff
  ldx #0
copy_more:
  lda SEGMENT_0800_START,x
  sta $0800,x
  lda SEGMENT_0800_START + $100,x
  sta $0900,x
  lda SEGMENT_0800_START + $200,x
  sta $0a00,x
  lda SEGMENT_0800_START + $300,x
  sta $0b00,x
  lda SEGMENT_0800_START + $400,x
  sta $0c00,x
  inx
  bne copy_more

  jsr big_petscii_1

; init $dd03 to an "RTS"
  lda #$60
  sta $dd03

  lda #0
  ldx #$1c
zeroSID:
  sta $d400,x
  dex
  bpl zeroSID

  lda #$ff
  sta $d406
  sta $d406+7
  sta $d406+14
  lda #$49
  sta $d404
  sta $d404+7
  sta $d404+14

  lda #$7f
  sta $dc0d
  lda $dc0d
;  lda #$2f
;  sta $00

  lda #<the_IRQ
  sta $fffe
  lda #>the_IRQ
  sta $ffff
  lda #$ff
  sta $d012
  lda #$1b
  sta $d011
  lda #$01
  sta $d01a
  cli

;  lda $dd02
;  ora #3
;  sta $dd02
;  lda $dd00
;  and #$fc
;  ora #$02
;  sta $dd00

; Play "Another visitor"
  LDX     #2
  JSR     sub_BED9
  CLI
  jsr big_petscii_2

;  LDA     #$20
;  JSR     sub_7F6D

; Play "Stay a while. Stay forever."
  LDX     #3
  JSR     sub_BED9
  rts



; Decreasing jitter by making IRQ shorter:
;the_IRQ:
;                PHA
;                LDA     $d019
;                STA     $d019
;                JSR     byte_FC
;                PLA
;                RTI
the_IRQ:
  pha
  lda $01
  pha
  lda #$35
  sta $01
cursor_cou:
  lda #17
  sec
  sbc #1
  bne no_blink
  lda $d018
do_eor:
  eor #$10
  sta $d018
  lda #17
no_blink:
  sta cursor_cou+1
  asl $d019
  inc $e0
  pla
  sta $01
  pla
  rti



; =============== S U B R O U T I N E =======================================
sub_7F6D:                               ; CODE XREF: RAM:39B6↑p
                CLC
                ADC     byte_E0
loc_7F70:                               ; CODE XREF: sub_7F6D+8↓j
                JSR     $dd03
                CMP     byte_E0
                BNE     loc_7F70
                RTS
; End of function sub_7F6D


sub_7F78:                               ; CODE XREF: sub_BED9↓p
                                        ; sub_BED9:loc_BF22↓p
                LDA     #$AB
loc_7F7A:                               ; CODE XREF: sub_7F78+5↓j
                CMP     $d012
                BCS     loc_7F7A
                PHP
                SEI
loc_7F81:                               ; CODE XREF: sub_7F78+11↓j
                LDA     $d012
loc_7F84:                               ; CODE XREF: sub_7F78+F↓j
                CMP     $d012
                BEQ     loc_7F84
                BMI     loc_7F81
                PLP
                RTS


byte_BED8:      !BYTE 2                 ; DATA XREF: sub_BED9+1B↓w
                                        ; sub_BED9+21↓r ...
; =============== S U B R O U T I N E =======================================
sub_BED9:                               ; CODE XREF: RAM:39B0↑p
                                        ; RAM:39BB↑p
                JSR     sub_7F78
                SEI
;                LDA     #8
;                STA     $d404
;                STA     $d40b
;                STA     $d412
                lda     #<the_IRQ
                sta     $fffe
                lda     #>the_IRQ
                sta     $ffff
                CLI
                TXA
                STA     byte_BED8
                JSR     sub_880

loc_BF06:                               ; CODE XREF: sub_BED9+2A↑j
                                        ; sub_BED9+33↓j
                LDA     #$FF
                JSR     sub_880
                LSR
                BCS     loc_BF06
                RTS


;---------------------------------------------------------------
; BIG PETSCII-code by Krill
; assumes any installed interrupt handler ($fffe/f) to buffer and restore $01

SCREEN     = $2000
SCREEN2    = $2400
ZP         = $02

SCREENPTR  = ZP
POINTER    = ZP + 2
ROWCOUNT   = ZP + 4
CHARUPPER  = ZP + 5
CHARLOWER  = CHARUPPER + 1

CHAREN     = $31
CHARDIS    = $35
CHARGEN    = $d000

IOPORT     = $01


big_petscii_1:
                lda #<(SCREEN + 4*40)
                sta SCREENPTR
                lda #>(SCREEN + 4*40)
                sta SCREENPTR + 1
                ldx #0
                jsr bit_petscii_plot
                lda #$20
                sta cursor_1
                lda #<(SCREEN2 + 4*40)
                sta SCREENPTR
                lda #>(SCREEN2 + 4*40)
                sta SCREENPTR + 1
                ldx #0
                jmp bit_petscii_plot

big_petscii_2:

;Stop blinking:
  lda #0
  sta do_eor+1
  lda #$84   ;Screen at $2000
  sta $d018

;Write "PERFORMER"...slowly:
  ldx #0
more_chars:

  txa
  asl
  asl
  clc
  adc #<(SCREEN + 8*40)
  sta SCREENPTR
  lda #>(SCREEN + 8*40)
  adc #0
  sta SCREENPTR + 1

;Switch letter to print:
  lda textB,x
  sta text2

  txa
  pha
  pha

  ldx #text2-text
  jsr bit_petscii_plot
  pla
  tax
;Kind of randomized delay:
  lda bit_petscii_plot,x
  and #$3f
  clc
  adc #$40
  tax
  ldy #0
waj:
  dey
  bne waj
  dex
  bne waj
  pla
  tax
  inx
  cpx #9
  bne more_chars

  ldx #0
  ldy #0
waj2:
  dey
  bne waj2
  dex
  bne waj2

;Write all the text again, to make a blinking cursor in the other screen:
                lda #<(SCREEN + 8*40)
                sta SCREENPTR
                lda #>(SCREEN + 8*40)
                sta SCREENPTR + 1
                ldx #textB - text
                jsr bit_petscii_plot
                lda #<(SCREEN2 + 8*40)
                sta SCREENPTR
                lda #>(SCREEN2 + 8*40)
                sta SCREENPTR + 1
                ldx #textB - text
                jsr bit_petscii_plot
                lda #$a0
                sta SCREEN2 + 24*40
                sta SCREEN2 + 1 + 24*40
                sta SCREEN2 + 2 + 24*40
                sta SCREEN2 + 3 + 24*40

;Start blinking again:
  lda #$10
  sta do_eor+1
                rts


bit_petscii_plot:
row             lda #10
                sta ROWCOUNT
single_char_plot:
                lda #CHAREN
                sta $01

plot            lda text,x
                beq done

                ldy #>(CHARGEN >> 3)
                sty POINTER + 1

                asl
                rol POINTER + 1
                asl
                rol POINTER + 1
                asl
                rol POINTER + 1
                sta POINTER

char            ldy #0
                lda (POINTER),y
                sta CHARUPPER
                inc POINTER
                lda (POINTER),y
                sta CHARLOWER
                inc POINTER

doubleline      tya
                asl CHARUPPER
                rol
                asl CHARLOWER
                rol
                asl CHARUPPER
                rol
                asl CHARLOWER
                rol
                tay
                lda translate,y

                ldy #0
                sta (SCREENPTR),y
                inc SCREENPTR
                bne +
                inc SCREENPTR + 1
+
                lda #%00000011
                and SCREENPTR
                bne doubleline

                clc
                lda #40 - 4
                adc SCREENPTR
                sta SCREENPTR
                bcc +
                inc SCREENPTR + 1
+
                lda #%00000111
                and POINTER
                bne char

                sec
                lda SCREENPTR
                sbc #<((40 * 4) - 4)
                sta SCREENPTR
                bcs +
                dec SCREENPTR + 1
+
                inx

                dec ROWCOUNT
                bne plot

                clc
                lda #<(40 * 3)
                adc SCREENPTR
                sta SCREENPTR
                bcc row
                inc SCREENPTR + 1
                bcs row; jmp

done            lda #CHARDIS
                sta IOPORT
                rts



init_big_petscii:
-               lda $d011
                bpl -
-               lda $d011
                bmi -
                lda #$03
                sta $dd00
                lda #$06
                sta $d021
                lda #$0e
                sta $d020
                lda #$0b
                sta $d011
                ldx #0
                stx $d015
-
                lda #$0e
                sta $d800,x
                sta $d900,x
                sta $da00,x
                sta $db00,x
                lda #' '
                sta SCREEN,x
                sta SCREEN2,x
                sta SCREEN + $0100,x
                sta SCREEN2 + $0100,x
                sta SCREEN + $0200,x
                sta SCREEN2 + $0200,x
                sta SCREEN + $02e8,x
                sta SCREEN2 + $02e8,x
                inx
                bne -

-               lda $d011
                bpl -
-               lda $d011
                bmi -
                lda #$1b
                sta $d011
                lda #$08   ;ROM charset
                sta $d016
;                lda #$14   ;Screen at $0400
                lda #$84   ;Screen at $2000
                sta $d018
                rts

; Blinking cursor:
;loop            ldx #(20 * 50 / 60) + 1
;wait_more:
;                bit $d011
;                bpl -
;-               bit $d011
;                bmi -
;                dex
;                bne wait_more
;                lda #$84 ^ $94
;                eor $d018
;                sta $d018
;                jmp loop

translate       !byte ' ', $6c, $7c, $e1
                !byte $7b, $62, $ff, $fe
                !byte $7e, $7f, $e2, $fb
                !byte $61, $fc, $ec, $a0

text
                !scr "ready.    "
cursor_1:
                !scr $a0,0
text2
                !scr "p",$a0,0
textB
                !scr "performers"
                !scr "          "
                !scr "?syntax  e"
                !scr "ready.",0

;                !scr "performers"
;                !scr "          "
;                !scr "?syntax  e"
;                !scr "ready.    "
;                !scr "next level"
;                !byte $a0
;                !scr  "         "
;                !byte 0



* = $fffa
byte_FFFA = $fffa ;      !BYTE 0 ; (uninited)    ; DATA XREF: RAM:0899↑w
;RAM:FFFA                                         ; RAM:08BE↑w ...
byte_FFFB = $fffb ;      !BYTE 0 ; (uninited)    ; DATA XREF: sub_C2F+1A↑w
;RAM:FFFB                                         ; RAM:BED4↑w

byte_FFFE = $fffe ;      !BYTE 0 ; (uninited)    ; DATA XREF: sub_BED9+11↑w
byte_FFFF = $ffff ;     !BYTE 0 ; (uninited)    ; DATA XREF: sub_BED9+16↑w

