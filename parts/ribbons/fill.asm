!cpu 6510

sprite_dat	= $6400
screen		= $6000
hires		= $4000
main		= $6a00

;XXX TODO start with sprites form $5f40 on, need $5c0 bytes
;6500 -> place $300 bytes of tables, then screen, then code

reg_a		= $10
reg_x		= $11
reg_y		= $12
reg_io		= $13

;illegal mode, $7b in letzter zeile in $d011 -> dadurch alle d011 sets weg
;dann 6 + 6 cycles frei, auch: strech von sprite weglassen und per d00x die sprites in y verschieben
;[16:48:03] axis/oxyron: hehe
;[16:48:10] axis/oxyron: ne, is sogar noch einfacher
;[16:48:23] axis/oxyron: erste zeile screen bildschirm an (#$1b)
;[16:48:28] axis/oxyron: und kurz vor end aus
;[16:48:30] axis/oxyron: #$0b
;make sinusses 100 long and store them at doubled size
;-> no overrun of index happens

rcol		= $18
spr_col		= $48

BGCOL		= $00

!ifdef release {
                !src "../../bitfire/loader/loader_acme.inc"
                !src "../../bitfire/macros/link_macros_acme.inc"
}

!ifndef release {
		* = hires
!bin "clean.kla",$1f40
		* = screen
		!fill $3f8,0
		!byte ((sprite_dat & $3fff) / 64) + 0
		!byte ((sprite_dat & $3fff) / 64) + 0
		!byte ((sprite_dat & $3fff) / 64) + 0
		!byte ((sprite_dat & $3fff) / 64) + 0
		!byte ((sprite_dat & $3fff) / 64) + 0
		!byte ((sprite_dat & $3fff) / 64) + 0
		!byte ((sprite_dat & $3fff) / 64) + 0
		!byte ((sprite_dat & $3fff) / 64) + 0
}

		* = main

		ldx #39
-
		lda spr_col_,x
		sta spr_col,x
		lda rcol_tab,x
		sta rcol,x
		dex
		bpl -

		ldx #$ff
		txs
		inx
		lda #$00
		txa
-
		sta sprite_dat + $000,x
		sta sprite_dat + $100,x
		sta sprite_dat + $200,x
		sta sprite_dat + $300,x
		sta sprite_dat + $400,x
		sta sprite_dat + $500,x
!ifndef release {
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
}
		dex
		bne -

		lda #((sprite_dat & $3fff) / 64) + 0
		sta screen + $3f8
		sta screen + $3f9
		sta screen + $3fa
		sta screen + $3fb
		sta screen + $3fc
		sta screen + $3fd
		sta screen + $3fe
		sta screen + $3ff

!ifndef release {
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		lda #$0b
		sta $d011

		lda #BGCOL
		sta $d020
		sta $d021
}
		jsr initirq

!ifndef release {
		ldx #$27
-
		lda screen_,x
		sta screen,x
		lda colram,x
		sta $d800,x
		dex
		bpl -
}

!ifdef release {
		+setup_sync $a0
}

-
.wait		lda #$00
		beq -
--
-
.y1		ldy #$fd
		iny
		iny
		iny
		sty .y1 + 1
		cpy #$24
		beq +
		jsr set_spr_size
		jmp -
+
!ifdef release {
		+sync
		+setup_sync $200
		jsr link_load_next_comp
		+sync
		+setup_sync $a0
} else {
		lda #$10
		bit $dc01
		bne *-3
		bit $dc01
		beq *-3
}
-
		ldy .y1 + 1
		dey
		dey
		dey
		sty .y1 + 1
		cpy #$fd
		beq +
		jsr set_spr_size
		jmp -
+
!ifdef release {
		+sync
}

		lda #$4c
		sta .fade

!ifndef release {
		jmp *
}

!ifdef release {
		; ldx #jumpcode_ - jumpcode
; -
		; lda jumpcode,x
		; sta $0100,x
		; dex
		; cpx #$ff
		; bne -

		ldx #$00
		lda #$20
-
		sta $0400,x
		sta $0500,x
		sta $0600,x
		sta $0700,x
		dex
		bne -

-		ldx .state + 1
		cpx #$38
		bne -

		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		sei
		lda #$1b
		sta $d011
		lda #$14
		sta $d018
		lda #$03
		sta $dd00
;		jmp $0100

;jumpcode
;		+stop_music_nmi
;		lda #$00
;		sta $d418
		;lda #$34
		;sta $01
		;jsr link_decomp
		;inc $01
		lda #$00
		sta $d015
		;jsr link_load_next_comp
		jmp link_exit
;jumpcode_
}

fadeout
.state		ldx #$00
		cpx #$38
		bcs ++
		inc .state + 1
		cpx #$28
		bcs +
		lda #$ee
		sta $d800,x
		sta screen,x
		bne ++
+
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
		lda fadeout_col_b - $28,x
		sta .border
		sta $d020
		lda fadeout_col_c - $28,x
		sta .line1 + 1
		lda fadeout_col_bg - $28,x
		sta $d021
		ldx #$27
-
		sta $d800,x
		sta screen,x
		dex
		bpl -
++
		jmp .fade_back

fadeout_col_bg
		!byte $ee,$ee,$ee,$ee
		!byte $44,$44,$44,$44
		!byte $88,$88,$88,$88
		!byte $88,$88,$88,$88

fadeout_col_b
		!byte $05,$05,$05,$05
		!byte $0f,$0f,$0f,$0f
		!byte $0d,$0d,$0d,$0d
		!byte $01,$01,$01,$01

fadeout_col_c
		!byte $00,$00,$00,$00
		!byte $09,$09,$08,$08
		!byte $0a,$0a,$0f,$0f
		!byte $07,$07,$01,$01


initirq
		bit $d011
		bpl *-3
		bit $d011
		bmi *-3
!ifndef release {
		lda #$0e
		sta $d021
}
		sei
		lda #$35
		sta $01
		lda #$32
		sta $d001
		sta $d003
		sta $d005
		sta $d007
		sta $d009
		sta $d00b
		sta $d00d
		sta $d00f

		lda #$ff
		sta $d015
		sta $d017
		lda #$00
		sta $d01d
		sta $d01b
		sta $d01c
		lda #$aa
		sta $3fff
		lda #$03
		sta $d010
		lda #$7f
		sta $dc0d
!ifndef release {
		sta $dd0d
}
		lda $dc0d
!ifndef release {
		lda $dd0d
}
		lda #$01
		sta $d019
		sta $d01a
		lda #<irq1
		sta $fffe
		lda #>irq1
		sta $ffff
		lda #$30
		sta $d012
		lda #$3b
		sta $d011
!ifndef release {
		lda #$80
		sta $d018
		lda #$02
		sta $dd00
		lda #$18
		sta $d016
}
		cli
		rts

!align 255,0
irq1
		sta reg_a
		stx reg_x
		lda $01
		sta reg_io
		lda #$35
		sta $01
		dec $d019
		lda #<irq2
		sta $fffe
		inc $d012
		tsx
		cli

		!byte $ea,$ea,$ea,$ea,$ea,$ea,$ea,$ea
		!byte $ea,$ea,$ea,$ea,$ea,$ea,$ea,$ea
		!byte $ea,$ea,$ea,$ea,$ea,$ea,$ea,$ea
		!byte $ea,$ea,$ea,$ea,$ea,$ea,$ea,$ea

!macro even ~.c1, ~.c2, ~.c3, ~.c4, .row {
	!if (((.row + 3) & 7) == 0) {
		lda #$38
		sta $d011
	} else {
		inc $d011
	}
.c1 = * + 1
		lda #$30
		sta $d00e
.c3 = * + 1
		lda #$00 ;sinus2+(.row/2),y
		sta $d00a
;.c3 = * + 1
		lda sinus4+(.row/2),y
		sta $d006
;.c4 = * + 1
		lda sinus6+(.row/2),y
		sta $d002
.c2 = * + 1
		!if (.row % 10) = 9 {
		lda #$00
	!if (.row = 199) {
	} else {
		sta (spr_col + ((.row) / 5) - 1,x)
		nop
	}
		} else {
		stx $d017
		dec $d017
		}
}

;$21 bytes
!macro odd ~.c1, ~.c2, ~.c3, ~.c4, .row {
		;XXX TODO cycle stealing somehow does not worky on x64sc, dammit
		;XXX TODO could we also do inc $d011 on some occasions??
	!if (.row == 0) {
		lda #$3b
		sta $d011
	} else {
		inc $d011
	}
.c1 = * + 1
		lda #$60
		sta $d00c
.c3 = * + 1
		lda #$00 ;sinus3+(.row/2),y
		sta $d008
;.c4 = * + 1
		lda sinus7+(.row/2),y
		sta $d000
;.c3 = * + 1
		lda sinus5+(.row/2),y
		sta $d004
.c2 = * + 1
		stx $d017
		dec $d017
}

irq2
		dec $d019
		sty reg_y
		txs
		nop
		nop

		ldx #$05
-
		dex
		bpl -

		lda $d012
		cmp $d012
		beq +
+
.line1		ldx #BGCOL
		stx $d020
		bit $ea
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		ldx #0
		ldy sin3+1
displaycode
		;XXX TODO unroll code for doubled amount of lines -> end code and enter code at right position to simulate rolling buffer. use index for offsetting a second buffer, can even use 2 indices?
		+odd   ~x1_001,~x2_001,~x3_001,~x4_001, 0
		+even  ~x5_001,~x6_001,~x7_001,~x8_001, 1
		+odd   ~x1_002,~x2_002,~x3_002,~x4_002, 2
		+even  ~x5_002,~x6_002,~x7_002,~x8_002, 3
		+odd   ~x1_003,~x2_003,~x3_003,~x4_003, 4
		+even  ~x5_003,~x6_003,~x7_003,~x8_003, 5
		+odd   ~x1_004,~x2_004,~x3_004,~x4_004, 6
		+even  ~x5_004,~x6_004,~x7_004,~x8_004, 7
		+odd   ~x1_005,~x2_005,~x3_005,~x4_005, 8
		+even  ~x5_005,~x6_005,~x7_005,~x8_005, 9
		+odd   ~x1_006,~x2_006,~x3_006,~x4_006, 10
		+even  ~x5_006,~x6_006,~x7_006,~x8_006, 11
		+odd   ~x1_007,~x2_007,~x3_007,~x4_007, 12
		+even  ~x5_007,~x6_007,~x7_007,~x8_007, 13
		+odd   ~x1_008,~x2_008,~x3_008,~x4_008, 14
		+even  ~x5_008,~x6_008,~x7_008,~x8_008, 15

		+odd   ~x1_009,~x2_009,~x3_009,~x4_009, 16
		+even  ~x5_009,~x6_009,~x7_009,~x8_009, 17
		+odd   ~x1_010,~x2_010,~x3_010,~x4_010, 18
		+even  ~x5_010,~x6_010,~x7_010,~x8_010, 19
		+odd   ~x1_011,~x2_011,~x3_011,~x4_011, 20
		+even  ~x5_011,~x6_011,~x7_011,~x8_011, 21
		+odd   ~x1_012,~x2_012,~x3_012,~x4_012, 22
		+even  ~x5_012,~x6_012,~x7_012,~x8_012, 23
		+odd   ~x1_013,~x2_013,~x3_013,~x4_013, 24
		+even  ~x5_013,~x6_013,~x7_013,~x8_013, 25
		+odd   ~x1_014,~x2_014,~x3_014,~x4_014, 26
		+even  ~x5_014,~x6_014,~x7_014,~x8_014, 27
		+odd   ~x1_015,~x2_015,~x3_015,~x4_015, 28
		+even  ~x5_015,~x6_015,~x7_015,~x8_015, 29
		+odd   ~x1_016,~x2_016,~x3_016,~x4_016, 30
		+even  ~x5_016,~x6_016,~x7_016,~x8_016, 31

		+odd   ~x1_017,~x2_017,~x3_017,~x4_017, 32
		+even  ~x5_017,~x6_017,~x7_017,~x8_017, 33
		+odd   ~x1_018,~x2_018,~x3_018,~x4_018, 34
		+even  ~x5_018,~x6_018,~x7_018,~x8_018, 35
		+odd   ~x1_019,~x2_019,~x3_019,~x4_019, 36
		+even  ~x5_019,~x6_019,~x7_019,~x8_019, 37
		+odd   ~x1_020,~x2_020,~x3_020,~x4_020, 38
		+even  ~x5_020,~x6_020,~x7_020,~x8_020, 39
		+odd   ~x1_021,~x2_021,~x3_021,~x4_021, 40
		+even  ~x5_021,~x6_021,~x7_021,~x8_021, 41
		+odd   ~x1_022,~x2_022,~x3_022,~x4_022, 42
		+even  ~x5_022,~x6_022,~x7_022,~x8_022, 43
		+odd   ~x1_023,~x2_023,~x3_023,~x4_023, 44
		+even  ~x5_023,~x6_023,~x7_023,~x8_023, 45
		+odd   ~x1_024,~x2_024,~x3_024,~x4_024, 46
		+even  ~x5_024,~x6_024,~x7_024,~x8_024, 47

		+odd   ~x1_025,~x2_025,~x3_025,~x4_025, 48
		+even  ~x5_025,~x6_025,~x7_025,~x8_025, 49
		+odd   ~x1_026,~x2_026,~x3_026,~x4_026, 50
		+even  ~x5_026,~x6_026,~x7_026,~x8_026, 51
		+odd   ~x1_027,~x2_027,~x3_027,~x4_027, 52
		+even  ~x5_027,~x6_027,~x7_027,~x8_027, 53
		+odd   ~x1_028,~x2_028,~x3_028,~x4_028, 54
		+even  ~x5_028,~x6_028,~x7_028,~x8_028, 55
		+odd   ~x1_029,~x2_029,~x3_029,~x4_029, 56
		+even  ~x5_029,~x6_029,~x7_029,~x8_029, 57
		+odd   ~x1_030,~x2_030,~x3_030,~x4_030, 58
		+even  ~x5_030,~x6_030,~x7_030,~x8_030, 59
		+odd   ~x1_031,~x2_031,~x3_031,~x4_031, 60
		+even  ~x5_031,~x6_031,~x7_031,~x8_031, 61
		+odd   ~x1_032,~x2_032,~x3_032,~x4_032, 62
		+even  ~x5_032,~x6_032,~x7_032,~x8_032, 63

		+odd   ~x1_033,~x2_033,~x3_033,~x4_033, 64
		+even  ~x5_033,~x6_033,~x7_033,~x8_033, 65
		+odd   ~x1_034,~x2_034,~x3_034,~x4_034, 66
		+even  ~x5_034,~x6_034,~x7_034,~x8_034, 67
		+odd   ~x1_035,~x2_035,~x3_035,~x4_035, 68
		+even  ~x5_035,~x6_035,~x7_035,~x8_035, 69
		+odd   ~x1_036,~x2_036,~x3_036,~x4_036, 70
		+even  ~x5_036,~x6_036,~x7_036,~x8_036, 71
		+odd   ~x1_037,~x2_037,~x3_037,~x4_037, 72
		+even  ~x5_037,~x6_037,~x7_037,~x8_037, 73
		+odd   ~x1_038,~x2_038,~x3_038,~x4_038, 74
		+even  ~x5_038,~x6_038,~x7_038,~x8_038, 75
		+odd   ~x1_039,~x2_039,~x3_039,~x4_039, 76
		+even  ~x5_039,~x6_039,~x7_039,~x8_039, 77
		+odd   ~x1_040,~x2_040,~x3_040,~x4_040, 78
		+even  ~x5_040,~x6_040,~x7_040,~x8_040, 79

		+odd   ~x1_041,~x2_041,~x3_041,~x4_041, 80
		+even  ~x5_041,~x6_041,~x7_041,~x8_041, 81
		+odd   ~x1_042,~x2_042,~x3_042,~x4_042, 82
		+even  ~x5_042,~x6_042,~x7_042,~x8_042, 83
		+odd   ~x1_043,~x2_043,~x3_043,~x4_043, 84
		+even  ~x5_043,~x6_043,~x7_043,~x8_043, 85
		+odd   ~x1_044,~x2_044,~x3_044,~x4_044, 86
		+even  ~x5_044,~x6_044,~x7_044,~x8_044, 87
		+odd   ~x1_045,~x2_045,~x3_045,~x4_045, 88
		+even  ~x5_045,~x6_045,~x7_045,~x8_045, 89
		+odd   ~x1_046,~x2_046,~x3_046,~x4_046, 90
		+even  ~x5_046,~x6_046,~x7_046,~x8_046, 91
		+odd   ~x1_047,~x2_047,~x3_047,~x4_047, 92
		+even  ~x5_047,~x6_047,~x7_047,~x8_047, 93
		+odd   ~x1_048,~x2_048,~x3_048,~x4_048, 94
		+even  ~x5_048,~x6_048,~x7_048,~x8_048, 95

		+odd   ~x1_049,~x2_049,~x3_049,~x4_049, 96
		+even  ~x5_049,~x6_049,~x7_049,~x8_049, 97
		+odd   ~x1_050,~x2_050,~x3_050,~x4_050, 98
		+even  ~x5_050,~x6_050,~x7_050,~x8_050, 99
		+odd   ~x1_051,~x2_051,~x3_051,~x4_051, 100
		+even  ~x5_051,~x6_051,~x7_051,~x8_051, 101
		+odd   ~x1_052,~x2_052,~x3_052,~x4_052, 102
		+even  ~x5_052,~x6_052,~x7_052,~x8_052, 103
		+odd   ~x1_053,~x2_053,~x3_053,~x4_053, 104
		+even  ~x5_053,~x6_053,~x7_053,~x8_053, 105
		+odd   ~x1_054,~x2_054,~x3_054,~x4_054, 106
		+even  ~x5_054,~x6_054,~x7_054,~x8_054, 107
		+odd   ~x1_055,~x2_055,~x3_055,~x4_055, 108
		+even  ~x5_055,~x6_055,~x7_055,~x8_055, 109
		+odd   ~x1_056,~x2_056,~x3_056,~x4_056, 110
		+even  ~x5_056,~x6_056,~x7_056,~x8_056, 111

		+odd   ~x1_057,~x2_057,~x3_057,~x4_057, 112
		+even  ~x5_057,~x6_057,~x7_057,~x8_057, 113
		+odd   ~x1_058,~x2_058,~x3_058,~x4_058, 114
		+even  ~x5_058,~x6_058,~x7_058,~x8_058, 115
		+odd   ~x1_059,~x2_059,~x3_059,~x4_059, 116
		+even  ~x5_059,~x6_059,~x7_059,~x8_059, 117
		+odd   ~x1_060,~x2_060,~x3_060,~x4_060, 118
		+even  ~x5_060,~x6_060,~x7_060,~x8_060, 119
		+odd   ~x1_061,~x2_061,~x3_061,~x4_061, 120
		+even  ~x5_061,~x6_061,~x7_061,~x8_061, 121
		+odd   ~x1_062,~x2_062,~x3_062,~x4_062, 122
		+even  ~x5_062,~x6_062,~x7_062,~x8_062, 123
		+odd   ~x1_063,~x2_063,~x3_063,~x4_063, 124
		+even  ~x5_063,~x6_063,~x7_063,~x8_063, 125
		+odd   ~x1_064,~x2_064,~x3_064,~x4_064, 126
		+even  ~x5_064,~x6_064,~x7_064,~x8_064, 127

		+odd   ~x1_065,~x2_065,~x3_065,~x4_065, 128
		+even  ~x5_065,~x6_065,~x7_065,~x8_065, 129
		+odd   ~x1_066,~x2_066,~x3_066,~x4_066, 130
		+even  ~x5_066,~x6_066,~x7_066,~x8_066, 131
		+odd   ~x1_067,~x2_067,~x3_067,~x4_067, 132
		+even  ~x5_067,~x6_067,~x7_067,~x8_067, 133
		+odd   ~x1_068,~x2_068,~x3_068,~x4_068, 134
		+even  ~x5_068,~x6_068,~x7_068,~x8_068, 135
		+odd   ~x1_069,~x2_069,~x3_069,~x4_069, 136
		+even  ~x5_069,~x6_069,~x7_069,~x8_069, 137
		+odd   ~x1_070,~x2_070,~x3_070,~x4_070, 138
		+even  ~x5_070,~x6_070,~x7_070,~x8_070, 139
		+odd   ~x1_071,~x2_071,~x3_071,~x4_071, 140
		+even  ~x5_071,~x6_071,~x7_071,~x8_071, 141
		+odd   ~x1_072,~x2_072,~x3_072,~x4_072, 142
		+even  ~x5_072,~x6_072,~x7_072,~x8_072, 143

		+odd   ~x1_073,~x2_073,~x3_073,~x4_073, 144
		+even  ~x5_073,~x6_073,~x7_073,~x8_073, 145
		+odd   ~x1_074,~x2_074,~x3_074,~x4_074, 146
		+even  ~x5_074,~x6_074,~x7_074,~x8_074, 147
		+odd   ~x1_075,~x2_075,~x3_075,~x4_075, 148
		+even  ~x5_075,~x6_075,~x7_075,~x8_075, 149
		+odd   ~x1_076,~x2_076,~x3_076,~x4_076, 150
		+even  ~x5_076,~x6_076,~x7_076,~x8_076, 151
		+odd   ~x1_077,~x2_077,~x3_077,~x4_077, 152
		+even  ~x5_077,~x6_077,~x7_077,~x8_077, 153
		+odd   ~x1_078,~x2_078,~x3_078,~x4_078, 154
		+even  ~x5_078,~x6_078,~x7_078,~x8_078, 155
		+odd   ~x1_079,~x2_079,~x3_079,~x4_079, 156
		+even  ~x5_079,~x6_079,~x7_079,~x8_079, 157
		+odd   ~x1_080,~x2_080,~x3_080,~x4_080, 158
		+even  ~x5_080,~x6_080,~x7_080,~x8_080, 159

		+odd   ~x1_081,~x2_081,~x3_081,~x4_081, 160
		+even  ~x5_081,~x6_081,~x7_081,~x8_081, 161
		+odd   ~x1_082,~x2_082,~x3_082,~x4_082, 162
		+even  ~x5_082,~x6_082,~x7_082,~x8_082, 163
		+odd   ~x1_083,~x2_083,~x3_083,~x4_083, 164
		+even  ~x5_083,~x6_083,~x7_083,~x8_083, 165
		+odd   ~x1_084,~x2_084,~x3_084,~x4_084, 166
		+even  ~x5_084,~x6_084,~x7_084,~x8_084, 167
		+odd   ~x1_085,~x2_085,~x3_085,~x4_085, 168
		+even  ~x5_085,~x6_085,~x7_085,~x8_085, 169
		+odd   ~x1_086,~x2_086,~x3_086,~x4_086, 170
		+even  ~x5_086,~x6_086,~x7_086,~x8_086, 171
		+odd   ~x1_087,~x2_087,~x3_087,~x4_087, 172
		+even  ~x5_087,~x6_087,~x7_087,~x8_087, 173
		+odd   ~x1_088,~x2_088,~x3_088,~x4_088, 174
		+even  ~x5_088,~x6_088,~x7_088,~x8_088, 175

		+odd   ~x1_089,~x2_089,~x3_089,~x4_089, 176
		+even  ~x5_089,~x6_089,~x7_089,~x8_089, 177
		+odd   ~x1_090,~x2_090,~x3_090,~x4_090, 178
		+even  ~x5_090,~x6_090,~x7_090,~x8_090, 179
		+odd   ~x1_091,~x2_091,~x3_091,~x4_091, 180
		+even  ~x5_091,~x6_091,~x7_091,~x8_091, 181
		+odd   ~x1_092,~x2_092,~x3_092,~x4_092, 182
		+even  ~x5_092,~x6_092,~x7_092,~x8_092, 183
		+odd   ~x1_093,~x2_093,~x3_093,~x4_093, 184
		+even  ~x5_093,~x6_093,~x7_093,~x8_093, 185
		+odd   ~x1_094,~x2_094,~x3_094,~x4_094, 186
		+even  ~x5_094,~x6_094,~x7_094,~x8_094, 187
		+odd   ~x1_095,~x2_095,~x3_095,~x4_095, 188
		+even  ~x5_095,~x6_095,~x7_095,~x8_095, 189
		+odd   ~x1_096,~x2_096,~x3_096,~x4_096, 190
		+even  ~x5_096,~x6_096,~x7_096,~x8_096, 191

		+odd   ~x1_097,~x2_097,~x3_097,~x4_097, 192
		+even  ~x5_097,~x6_097,~x7_097,~x8_097, 193
		+odd   ~x1_098,~x2_098,~x3_098,~x4_098, 194
		+even  ~x5_098,~x6_098,~x7_098,~x8_098, 195
		+odd   ~x1_099,~x2_099,~x3_099,~x4_099, 196
		+even  ~x5_099,~x6_099,~x7_099,~x8_099, 197
		+odd   ~x1_100,~x2_100,~x3_100,~x4_100, 198
		+even  ~x5_100,~x6_100,~x7_100,~x8_100, 199
.border = * + 1
		lda #$05
		nop
		nop
		inc $d011
		sta $d020

.fade
		bit fadeout
sin1
		ldy #$00
		lda sinus0+001,y
		sta x1_001
		lda sinus0+002,y
		sta x1_002
		lda sinus0+003,y
		sta x1_003
		lda sinus0+004,y
		sta x1_004
		lda sinus0+005,y
		sta x1_005
		lda sinus0+006,y
		sta x1_006
		lda sinus0+007,y
		sta x1_007
		lda sinus0+008,y
		sta x1_008
		lda sinus0+009,y
		sta x1_009
		lda sinus0+010,y
		sta x1_010
		lda sinus0+011,y
		sta x1_011
		lda sinus0+012,y
		sta x1_012
		lda sinus0+013,y
		sta x1_013
		lda sinus0+014,y
		sta x1_014
		lda sinus0+015,y
		sta x1_015
		lda sinus0+016,y
		sta x1_016
		lda sinus0+017,y
		sta x1_017
		lda sinus0+018,y
		sta x1_018
		lda sinus0+019,y
		sta x1_019
		lda sinus0+020,y
		sta x1_020
		lda sinus0+021,y
		sta x1_021
		lda sinus0+022,y
		sta x1_022
		lda sinus0+023,y
		sta x1_023
		lda sinus0+024,y
		sta x1_024
		lda sinus0+025,y
		sta x1_025
		lda sinus0+026,y
		sta x1_026
		lda sinus0+027,y
		sta x1_027
		lda sinus0+028,y
		sta x1_028
		lda sinus0+029,y
		sta x1_029
		lda sinus0+030,y
		sta x1_030
		lda sinus0+031,y
		sta x1_031
		lda sinus0+032,y
		sta x1_032
		lda sinus0+033,y
		sta x1_033
		lda sinus0+034,y
		sta x1_034
		lda sinus0+035,y
		sta x1_035
		lda sinus0+036,y
		sta x1_036
		lda sinus0+037,y
		sta x1_037
		lda sinus0+038,y
		sta x1_038
		lda sinus0+039,y
		sta x1_039
		lda sinus0+040,y
		sta x1_040
		lda sinus0+041,y
		sta x1_041
		lda sinus0+042,y
		sta x1_042
		lda sinus0+043,y
		sta x1_043
		lda sinus0+044,y
		sta x1_044
		lda sinus0+045,y
		sta x1_045
		lda sinus0+046,y
		sta x1_046
		lda sinus0+047,y
		sta x1_047
		lda sinus0+048,y
		sta x1_048
		lda sinus0+049,y
		sta x1_049
		lda sinus0+050,y
		sta x1_050
		lda sinus0+051,y
		sta x1_051
		lda sinus0+052,y
		sta x1_052
		lda sinus0+053,y
		sta x1_053
		lda sinus0+054,y
		sta x1_054
		lda sinus0+055,y
		sta x1_055
		lda sinus0+056,y
		sta x1_056
		lda sinus0+057,y
		sta x1_057
		lda sinus0+058,y
		sta x1_058
		lda sinus0+059,y
		sta x1_059
		lda sinus0+060,y
		sta x1_060
		lda sinus0+061,y
		sta x1_061
		lda sinus0+062,y
		sta x1_062
		lda sinus0+063,y
		sta x1_063
		lda sinus0+064,y
		sta x1_064
		lda sinus0+065,y
		sta x1_065
		lda sinus0+066,y
		sta x1_066
		lda sinus0+067,y
		sta x1_067
		lda sinus0+068,y
		sta x1_068
		lda sinus0+069,y
		sta x1_069
		lda sinus0+070,y
		sta x1_070
		lda sinus0+071,y
		sta x1_071
		lda sinus0+072,y
		sta x1_072
		lda sinus0+073,y
		sta x1_073
		lda sinus0+074,y
		sta x1_074
		lda sinus0+075,y
		sta x1_075
		lda sinus0+076,y
		sta x1_076
		lda sinus0+077,y
		sta x1_077
		lda sinus0+078,y
		sta x1_078
		lda sinus0+079,y
		sta x1_079
		lda sinus0+080,y
		sta x1_080
		lda sinus0+081,y
		sta x1_081
		lda sinus0+082,y
		sta x1_082
		lda sinus0+083,y
		sta x1_083
		lda sinus0+084,y
		sta x1_084
		lda sinus0+085,y
		sta x1_085
		lda sinus0+086,y
		sta x1_086
		lda sinus0+087,y
		sta x1_087
		lda sinus0+088,y
		sta x1_088
		lda sinus0+089,y
		sta x1_089
		lda sinus0+090,y
		sta x1_090
		lda sinus0+091,y
		sta x1_091
		lda sinus0+092,y
		sta x1_092
		lda sinus0+093,y
		sta x1_093
		lda sinus0+094,y
		sta x1_094
		lda sinus0+095,y
		sta x1_095
		lda sinus0+096,y
		sta x1_096
		lda sinus0+097,y
		sta x1_097
		lda sinus0+098,y
		sta x1_098
		lda sinus0+099,y
		sta x1_099
		lda sinus0+100,y
		sta x1_100
		lda sinus0,y
		sta $d00c

		iny
		cpy #100
		bne +
		ldy #$00
+
		sty sin1+1

sin2
		ldy #$00
		lda sinus1+001,y
		sta x5_001
		lda sinus1+002,y
		sta x5_002
		lda sinus1+003,y
		sta x5_003
		lda sinus1+004,y
		sta x5_004
		lda sinus1+005,y
		sta x5_005
		lda sinus1+006,y
		sta x5_006
		lda sinus1+007,y
		sta x5_007
		lda sinus1+008,y
		sta x5_008
		lda sinus1+009,y
		sta x5_009
		lda sinus1+010,y
		sta x5_010
		lda sinus1+011,y
		sta x5_011
		lda sinus1+012,y
		sta x5_012
		lda sinus1+013,y
		sta x5_013
		lda sinus1+014,y
		sta x5_014
		lda sinus1+015,y
		sta x5_015
		lda sinus1+016,y
		sta x5_016
		lda sinus1+017,y
		sta x5_017
		lda sinus1+018,y
		sta x5_018
		lda sinus1+019,y
		sta x5_019
		lda sinus1+020,y
		sta x5_020
		lda sinus1+021,y
		sta x5_021
		lda sinus1+022,y
		sta x5_022
		lda sinus1+023,y
		sta x5_023
		lda sinus1+024,y
		sta x5_024
		lda sinus1+025,y
		sta x5_025
		lda sinus1+026,y
		sta x5_026
		lda sinus1+027,y
		sta x5_027
		lda sinus1+028,y
		sta x5_028
		lda sinus1+029,y
		sta x5_029
		lda sinus1+030,y
		sta x5_030
		lda sinus1+031,y
		sta x5_031
		lda sinus1+032,y
		sta x5_032
		lda sinus1+033,y
		sta x5_033
		lda sinus1+034,y
		sta x5_034
		lda sinus1+035,y
		sta x5_035
		lda sinus1+036,y
		sta x5_036
		lda sinus1+037,y
		sta x5_037
		lda sinus1+038,y
		sta x5_038
		lda sinus1+039,y
		sta x5_039
		lda sinus1+040,y
		sta x5_040
		lda sinus1+041,y
		sta x5_041
		lda sinus1+042,y
		sta x5_042
		lda sinus1+043,y
		sta x5_043
		lda sinus1+044,y
		sta x5_044
		lda sinus1+045,y
		sta x5_045
		lda sinus1+046,y
		sta x5_046
		lda sinus1+047,y
		sta x5_047
		lda sinus1+048,y
		sta x5_048
		lda sinus1+049,y
		sta x5_049
		lda sinus1+050,y
		sta x5_050
		lda sinus1+051,y
		sta x5_051
		lda sinus1+052,y
		sta x5_052
		lda sinus1+053,y
		sta x5_053
		lda sinus1+054,y
		sta x5_054
		lda sinus1+055,y
		sta x5_055
		lda sinus1+056,y
		sta x5_056
		lda sinus1+057,y
		sta x5_057
		lda sinus1+058,y
		sta x5_058
		lda sinus1+059,y
		sta x5_059
		lda sinus1+060,y
		sta x5_060
		lda sinus1+061,y
		sta x5_061
		lda sinus1+062,y
		sta x5_062
		lda sinus1+063,y
		sta x5_063
		lda sinus1+064,y
		sta x5_064
		lda sinus1+065,y
		sta x5_065
		lda sinus1+066,y
		sta x5_066
		lda sinus1+067,y
		sta x5_067
		lda sinus1+068,y
		sta x5_068
		lda sinus1+069,y
		sta x5_069
		lda sinus1+070,y
		sta x5_070
		lda sinus1+071,y
		sta x5_071
		lda sinus1+072,y
		sta x5_072
		lda sinus1+073,y
		sta x5_073
		lda sinus1+074,y
		sta x5_074
		lda sinus1+075,y
		sta x5_075
		lda sinus1+076,y
		sta x5_076
		lda sinus1+077,y
		sta x5_077
		lda sinus1+078,y
		sta x5_078
		lda sinus1+079,y
		sta x5_079
		lda sinus1+080,y
		sta x5_080
		lda sinus1+081,y
		sta x5_081
		lda sinus1+082,y
		sta x5_082
		lda sinus1+083,y
		sta x5_083
		lda sinus1+084,y
		sta x5_084
		lda sinus1+085,y
		sta x5_085
		lda sinus1+086,y
		sta x5_086
		lda sinus1+087,y
		sta x5_087
		lda sinus1+088,y
		sta x5_088
		lda sinus1+089,y
		sta x5_089
		lda sinus1+090,y
		sta x5_090
		lda sinus1+091,y
		sta x5_091
		lda sinus1+092,y
		sta x5_092
		lda sinus1+093,y
		sta x5_093
		lda sinus1+094,y
		sta x5_094
		lda sinus1+095,y
		sta x5_095
		lda sinus1+096,y
		sta x5_096
		lda sinus1+097,y
		sta x5_097
		lda sinus1+098,y
		sta x5_098
		lda sinus1+099,y
		sta x5_099
		lda sinus1+100,y
		sta x5_100
		lda sinus1,y
		sta $d00e

		iny
		iny
		cpy #120
		bne +
		ldy #$00
+
		sty sin2+1

sin3		ldy #$00
		iny
		iny
		cpy #156
		bne +
		ldy #$00
+
		sty sin3+1

sin4
		ldy #$00
		lda sinus2+001,y
		sta x3_001
		lda sinus2+002,y
		sta x3_002
		lda sinus2+003,y
		sta x3_003
		lda sinus2+004,y
		sta x3_004
		lda sinus2+005,y
		sta x3_005
		lda sinus2+006,y
		sta x3_006
		lda sinus2+007,y
		sta x3_007
		lda sinus2+008,y
		sta x3_008
		lda sinus2+009,y
		sta x3_009
		lda sinus2+010,y
		sta x3_010
		lda sinus2+011,y
		sta x3_011
		lda sinus2+012,y
		sta x3_012
		lda sinus2+013,y
		sta x3_013
		lda sinus2+014,y
		sta x3_014
		lda sinus2+015,y
		sta x3_015
		lda sinus2+016,y
		sta x3_016
		lda sinus2+017,y
		sta x3_017
		lda sinus2+018,y
		sta x3_018
		lda sinus2+019,y
		sta x3_019
		lda sinus2+020,y
		sta x3_020
		lda sinus2+021,y
		sta x3_021
		lda sinus2+022,y
		sta x3_022
		lda sinus2+023,y
		sta x3_023
		lda sinus2+024,y
		sta x3_024
		lda sinus2+025,y
		sta x3_025
		lda sinus2+026,y
		sta x3_026
		lda sinus2+027,y
		sta x3_027
		lda sinus2+028,y
		sta x3_028
		lda sinus2+029,y
		sta x3_029
		lda sinus2+030,y
		sta x3_030
		lda sinus2+031,y
		sta x3_031
		lda sinus2+032,y
		sta x3_032
		lda sinus2+033,y
		sta x3_033
		lda sinus2+034,y
		sta x3_034
		lda sinus2+035,y
		sta x3_035
		lda sinus2+036,y
		sta x3_036
		lda sinus2+037,y
		sta x3_037
		lda sinus2+038,y
		sta x3_038
		lda sinus2+039,y
		sta x3_039
		lda sinus2+040,y
		sta x3_040
		lda sinus2+041,y
		sta x3_041
		lda sinus2+042,y
		sta x3_042
		lda sinus2+043,y
		sta x3_043
		lda sinus2+044,y
		sta x3_044
		lda sinus2+045,y
		sta x3_045
		lda sinus2+046,y
		sta x3_046
		lda sinus2+047,y
		sta x3_047
		lda sinus2+048,y
		sta x3_048
		lda sinus2+049,y
		sta x3_049
		lda sinus2+050,y
		sta x3_050
		lda sinus2+051,y
		sta x3_051
		lda sinus2+052,y
		sta x3_052
		lda sinus2+053,y
		sta x3_053
		lda sinus2+054,y
		sta x3_054
		lda sinus2+055,y
		sta x3_055
		lda sinus2+056,y
		sta x3_056
		lda sinus2+057,y
		sta x3_057
		lda sinus2+058,y
		sta x3_058
		lda sinus2+059,y
		sta x3_059
		lda sinus2+060,y
		sta x3_060
		lda sinus2+061,y
		sta x3_061
		lda sinus2+062,y
		sta x3_062
		lda sinus2+063,y
		sta x3_063
		lda sinus2+064,y
		sta x3_064
		lda sinus2+065,y
		sta x3_065
		lda sinus2+066,y
		sta x3_066
		lda sinus2+067,y
		sta x3_067
		lda sinus2+068,y
		sta x3_068
		lda sinus2+069,y
		sta x3_069
		lda sinus2+070,y
		sta x3_070
		lda sinus2+071,y
		sta x3_071
		lda sinus2+072,y
		sta x3_072
		lda sinus2+073,y
		sta x3_073
		lda sinus2+074,y
		sta x3_074
		lda sinus2+075,y
		sta x3_075
		lda sinus2+076,y
		sta x3_076
		lda sinus2+077,y
		sta x3_077
		lda sinus2+078,y
		sta x3_078
		lda sinus2+079,y
		sta x3_079
		lda sinus2+080,y
		sta x3_080
		lda sinus2+081,y
		sta x3_081
		lda sinus2+082,y
		sta x3_082
		lda sinus2+083,y
		sta x3_083
		lda sinus2+084,y
		sta x3_084
		lda sinus2+085,y
		sta x3_085
		lda sinus2+086,y
		sta x3_086
		lda sinus2+087,y
		sta x3_087
		lda sinus2+088,y
		sta x3_088
		lda sinus2+089,y
		sta x3_089
		lda sinus2+090,y
		sta x3_090
		lda sinus2+091,y
		sta x3_091
		lda sinus2+092,y
		sta x3_092
		lda sinus2+093,y
		sta x3_093
		lda sinus2+094,y
		sta x3_094
		lda sinus2+095,y
		sta x3_095
		lda sinus2+096,y
		sta x3_096
		lda sinus2+097,y
		sta x3_097
		lda sinus2+098,y
		sta x3_098
		lda sinus2+099,y
		sta x3_099
		lda sinus2+100,y
		sta x3_100
		lda sinus2,y
		sta $d008

		iny
		iny
		cpy #90
		bne +
		ldy #$00
+
		sty sin4+1

sin5
		ldy #$00
		lda sinus3+001,y
		sta x7_001
		lda sinus3+002,y
		sta x7_002
		lda sinus3+003,y
		sta x7_003
		lda sinus3+004,y
		sta x7_004
		lda sinus3+005,y
		sta x7_005
		lda sinus3+006,y
		sta x7_006
		lda sinus3+007,y
		sta x7_007
		lda sinus3+008,y
		sta x7_008
		lda sinus3+009,y
		sta x7_009
		lda sinus3+010,y
		sta x7_010
		lda sinus3+011,y
		sta x7_011
		lda sinus3+012,y
		sta x7_012
		lda sinus3+013,y
		sta x7_013
		lda sinus3+014,y
		sta x7_014
		lda sinus3+015,y
		sta x7_015
		lda sinus3+016,y
		sta x7_016
		lda sinus3+017,y
		sta x7_017
		lda sinus3+018,y
		sta x7_018
		lda sinus3+019,y
		sta x7_019
		lda sinus3+020,y
		sta x7_020
		lda sinus3+021,y
		sta x7_021
		lda sinus3+022,y
		sta x7_022
		lda sinus3+023,y
		sta x7_023
		lda sinus3+024,y
		sta x7_024
		lda sinus3+025,y
		sta x7_025
		lda sinus3+026,y
		sta x7_026
		lda sinus3+027,y
		sta x7_027
		lda sinus3+028,y
		sta x7_028
		lda sinus3+029,y
		sta x7_029
		lda sinus3+030,y
		sta x7_030
		lda sinus3+031,y
		sta x7_031
		lda sinus3+032,y
		sta x7_032
		lda sinus3+033,y
		sta x7_033
		lda sinus3+034,y
		sta x7_034
		lda sinus3+035,y
		sta x7_035
		lda sinus3+036,y
		sta x7_036
		lda sinus3+037,y
		sta x7_037
		lda sinus3+038,y
		sta x7_038
		lda sinus3+039,y
		sta x7_039
		lda sinus3+040,y
		sta x7_040
		lda sinus3+041,y
		sta x7_041
		lda sinus3+042,y
		sta x7_042
		lda sinus3+043,y
		sta x7_043
		lda sinus3+044,y
		sta x7_044
		lda sinus3+045,y
		sta x7_045
		lda sinus3+046,y
		sta x7_046
		lda sinus3+047,y
		sta x7_047
		lda sinus3+048,y
		sta x7_048
		lda sinus3+049,y
		sta x7_049
		lda sinus3+050,y
		sta x7_050
		lda sinus3+051,y
		sta x7_051
		lda sinus3+052,y
		sta x7_052
		lda sinus3+053,y
		sta x7_053
		lda sinus3+054,y
		sta x7_054
		lda sinus3+055,y
		sta x7_055
		lda sinus3+056,y
		sta x7_056
		lda sinus3+057,y
		sta x7_057
		lda sinus3+058,y
		sta x7_058
		lda sinus3+059,y
		sta x7_059
		lda sinus3+060,y
		sta x7_060
		lda sinus3+061,y
		sta x7_061
		lda sinus3+062,y
		sta x7_062
		lda sinus3+063,y
		sta x7_063
		lda sinus3+064,y
		sta x7_064
		lda sinus3+065,y
		sta x7_065
		lda sinus3+066,y
		sta x7_066
		lda sinus3+067,y
		sta x7_067
		lda sinus3+068,y
		sta x7_068
		lda sinus3+069,y
		sta x7_069
		lda sinus3+070,y
		sta x7_070
		lda sinus3+071,y
		sta x7_071
		lda sinus3+072,y
		sta x7_072
		lda sinus3+073,y
		sta x7_073
		lda sinus3+074,y
		sta x7_074
		lda sinus3+075,y
		sta x7_075
		lda sinus3+076,y
		sta x7_076
		lda sinus3+077,y
		sta x7_077
		lda sinus3+078,y
		sta x7_078
		lda sinus3+079,y
		sta x7_079
		lda sinus3+080,y
		sta x7_080
		lda sinus3+081,y
		sta x7_081
		lda sinus3+082,y
		sta x7_082
		lda sinus3+083,y
		sta x7_083
		lda sinus3+084,y
		sta x7_084
		lda sinus3+085,y
		sta x7_085
		lda sinus3+086,y
		sta x7_086
		lda sinus3+087,y
		sta x7_087
		lda sinus3+088,y
		sta x7_088
		lda sinus3+089,y
		sta x7_089
		lda sinus3+090,y
		sta x7_090
		lda sinus3+091,y
		sta x7_091
		lda sinus3+092,y
		sta x7_092
		lda sinus3+093,y
		sta x7_093
		lda sinus3+094,y
		sta x7_094
		lda sinus3+095,y
		sta x7_095
		lda sinus3+096,y
		sta x7_096
		lda sinus3+097,y
		sta x7_097
		lda sinus3+098,y
		sta x7_098
		lda sinus3+099,y
		sta x7_099
		lda sinus3+100,y
		sta x7_100
		lda sinus3,y
		sta $d00a

		iny
		iny
		cpy #140
		bne +
		ldy #$00
+
		sty sin5+1


		ldy sin3 + 1
		lda sinus4,y
		sta $d006
		lda sinus5,y
		sta $d004
		lda sinus6,y
		sta $d002
		lda sinus7,y
		sta $d000
.fade_back
		lda #$25
		sta spr_col + 00
		sta spr_col + 02
		sta spr_col + 04
		sta spr_col + 06
		sta spr_col + 08
		sta spr_col + 10
		sta spr_col + 12
		sta spr_col + 14
		sta spr_col + 16
		sta spr_col + 18
		sta spr_col + 20
		sta spr_col + 22
		sta spr_col + 24
		sta spr_col + 26
		sta spr_col + 28
		sta spr_col + 30
		sta spr_col + 32
		sta spr_col + 34
		sta spr_col + 36
		sta spr_col + 38


.sp1		ldy #$11
		lda animtab,y
		sta screen + $03f8

.col1_1		lda #$05
		ldx postab8 + 12,y	;$21
		bpl +
		ldx .col1_2 + 1
		sta .col1_2 + 1
		stx .col1_1 + 1
		jmp ++
+
		sta (rcol,x)

		lda #$2e
		sta spr_col,x
.col1_2		lda #$0f
++
		sta $d02e

		iny
		cpy #21
		bne +
		ldy #$00
+
		sty .sp1 + 1


.sp2		ldy #$06
		lda animtab,y
		sta screen + $03f9

.col2_1		lda #$0c
		ldx postab8 + 13,y  ;$13
		bpl +
		ldx .col2_2 + 1
		sta .col2_2 + 1
		stx .col2_1 + 1
		jmp ++
+
		sta (rcol,x)
		lda #$2d
		sta spr_col,x
.col2_2		lda #$0b
++
		sta $d02d

		iny
		cpy #21
		bne +
		ldy #$00
+
		sty .sp2 + 1


.sp3		ldy #$0c
		lda animtab,y
		sta screen + $03fa

.col3_1		lda #$01
		ldx postab8 + 18,y	;$23
		bpl +
		ldx .col3_2 + 1
		sta .col3_2 + 1
		stx .col3_1 + 1
		jmp ++
+
		sta (rcol,x)

		lda #$2c
		sta spr_col,x
.col3_2		lda #$07
++
		sta $d02c

		iny
		cpy #21
		bne +
		ldy #$00
+
		sty .sp3 + 1


.sp4		ldy #$14
		lda animtab,y
		sta screen + $03fb

.col4_1		lda #$0a
		ldx postab8 + 5,y	;$19
		bpl +
		ldx .col4_2 + 1
		sta .col4_2 + 1
		stx .col4_1 + 1
		jmp ++
+
		sta (rcol,x)

		lda #$2b
		sta spr_col,x
.col4_2		lda #$04
++
		sta $d02b

		iny
		cpy #21
		bne +
		ldy #$00
+
		sty .sp4 + 1


.sp5		ldy #$03
		lda animtab,y
		sta screen + $03fc

.col5_1		lda #$0d
		ldx postab8 + 18,y ;$16
		bpl +
		ldx .col5_2 + 1
		sta .col5_2 + 1
		stx .col5_1 + 1
		jmp ++
+
		sta (rcol,x)

		lda #$2a
		sta spr_col,x
.col5_2		lda #$03
++
		sta $d02a

		iny
		cpy #21
		bne +
		ldy #$00
+
		sty .sp5 + 1


.sp6		ldy #$08
		lda animtab,y
		sta screen + $03fd

.col6_1		lda #$06
		ldx postab8 + 05,y    ;$11
		bpl +
		ldx .col6_2 + 1
		sta .col6_2 + 1
		stx .col6_1 + 1
		jmp ++
+
		sta (rcol,x)

		lda #$29
		sta spr_col,x
.col6_2		lda #$04
++
		sta $d029

		iny
		cpy #21
		bne +
		ldy #$00
+
		sty .sp6 + 1

.sp7		ldy #$12
		lda animtab,y
		sta screen + $03fe

.col7_1		lda #$08
		ldx postab8 + 10,y    ;$1d
		bpl +
		ldx .col7_2 + 1
		sta .col7_2 + 1
		stx .col7_1 + 1
		jmp ++
+
		sta (rcol,x)

		lda #$28
		sta spr_col,x
.col7_2		lda #$0a
++
		sta $d028

		iny
		cpy #21
		bne +
		ldy #$00
+
		sty .sp7 + 1


.sp8		ldy #$07
		lda animtab,y
		sta screen + $03ff

.col8_1		lda #$0b
		ldx postab8 + 11,y	;$15
		bpl +
		ldx .col8_2 + 1
		sta .col8_2 + 1
		stx .col8_1 + 1
		jmp ++
+
		sta (rcol,x)

		lda #$27
		sta spr_col,x
.col8_2		lda #$00
++
		sta $d027

		iny
		cpy #21
		bne +
		ldy #$00
+
		sty .sp8 + 1

		lda #<irq1
		sta $fffe
		lda #$30
		sta $d012

		inc .wait + 1
		lda reg_io
		sta $01
		ldy reg_y
		ldx reg_x
		lda reg_a
		rti

animtab
		!byte ((sprite_dat & $3fff) / 64) + 0
		!byte ((sprite_dat & $3fff) / 64) + 1
		!byte ((sprite_dat & $3fff) / 64) + 2
		!byte ((sprite_dat & $3fff) / 64) + 3
		!byte ((sprite_dat & $3fff) / 64) + 4
		!byte ((sprite_dat & $3fff) / 64) + 5
		!byte ((sprite_dat & $3fff) / 64) + 6
		!byte ((sprite_dat & $3fff) / 64) + 7
		!byte ((sprite_dat & $3fff) / 64) + 8
		!byte ((sprite_dat & $3fff) / 64) + 9
		!byte ((sprite_dat & $3fff) / 64) + 10
		!byte ((sprite_dat & $3fff) / 64) + 11
		!byte ((sprite_dat & $3fff) / 64) + 12
		!byte ((sprite_dat & $3fff) / 64) + 13
		!byte ((sprite_dat & $3fff) / 64) + 14
		!byte ((sprite_dat & $3fff) / 64) + 15
		!byte ((sprite_dat & $3fff) / 64) + 16
		!byte ((sprite_dat & $3fff) / 64) + 17
		!byte ((sprite_dat & $3fff) / 64) + 18
		!byte ((sprite_dat & $3fff) / 64) + 19
		!byte ((sprite_dat & $3fff) / 64) + 20
		!byte ((sprite_dat & $3fff) / 64) + 21

		;on pos + 10 should be val 0
postab8
		!byte $80
		!byte 38
		!byte 36
		!byte 34
		!byte 32
		!byte 30
		!byte 28
		!byte 26
		!byte 24
		!byte 22
		!byte 20
		!byte 18
		!byte 16
		!byte 14
		!byte 12
		!byte 10
		!byte 08
		!byte 06
		!byte 04
		!byte 02
		!byte 00

		!byte $80
		!byte 38
		!byte 36
		!byte 34
		!byte 32
		!byte 30
		!byte 28
		!byte 26
		!byte 24
		!byte 22
		!byte 20
		!byte 18
		!byte 16
		!byte 14
		!byte 12
		!byte 10
		!byte 08
		!byte 06
		!byte 04
		!byte 02
		!byte 00

spr_col_
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025
		!word $d025

rcol_tab
		!word x6_005
		!word x6_010
		!word x6_015
		!word x6_020
		!word x6_025
		!word x6_030
		!word x6_035
		!word x6_040
		!word x6_045
		!word x6_050
		!word x6_055
		!word x6_060
		!word x6_065
		!word x6_070
		!word x6_075
		!word x6_080
		!word x6_085
		!word x6_090
		!word x6_095
		!word x6_100

sprite_
		!byte $00,$14,$00
		!byte $00,$36,$00
		!byte $00,$77,$00
		!byte $00,$ef,$80
		!byte $01,$ef,$c0
		!byte $03,$ef,$e0
		!byte $07,$ef,$f0
		!byte $0f,$e7,$f8
		!byte $1f,$e7,$fc
		!byte $3f,$e7,$fe
		!byte $7f,$e7,$ff

!ifndef release {
colram
!bin "clean.kla",$28,$1f40 + $28
screen_
!bin "clean.kla",$28,$1f40
}

set_spr_size
		sty .spr_size + 1
		tya
		beq .skip
		ldx #$00
		ldy #$00
-
		lda sprite_ + 0,x
		sta sprite_dat + 0,y
		lda sprite_ + 1,x
		sta sprite_dat + 1,y
		lda sprite_ + 2,x
		sta sprite_dat + 2,y
		inx
		inx
		inx
		iny
		iny
		iny
.spr_size	cpy #$03
		bne -
-
		lda sprite_ - 3,x
		sta sprite_dat + 0,y
		lda sprite_ - 2,x
		sta sprite_dat + 1,y
		lda sprite_ - 1,x
		sta sprite_dat + 2,y
		iny
		iny
		iny
		cpy #$42
		beq +
		dex
		dex
		dex
		bne -

		lda #$00
.skip
-
		sta sprite_dat + 0,y
		iny
		cpy #$3f
		bne -
+
!for .x,0,21 {
		ldx #$00
-
		lda sprite_dat + .x * $40,x
		sta sprite_dat + .x * $40 + $7c,x
		inx
		cpx #$03
		bne -
-
		lda sprite_dat + .x * $40,x
		sta sprite_dat + .x * $40 + $3d,x
		inx
		cpx #$3f
		bne -
}
		rts


!align 255,0
sinus0 = * + 0 * 256
sinus1 = * + 1 * 256
sinus2 = * + 2 * 256
sinus3 = * + 3 * 256
sinus4 = * + 4 * 256
sinus5 = * + 5 * 256
sinus6 = * + 6 * 256
sinus7 = * + 7 * 256
!bin "sinus.bin"


;immer dicker werdende ribbons einkopieren?
;00
;010
;01210
;0123210
;jeweils passend für alle 21 stk?


;XXX two sines can have different length as they are setup directly



;  |                  1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 3 3 3 3 4 4 4 4 4 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 6 6 6 6 |
;0 |1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 |
;  |                   |===========010203040506070809101112131415161718192021222324252627282930313233343536373839:40===========|   |
;--|------------------------------------------------------------------------------------------------------------------------------|
;  |                     x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x W W w            |
;  |                    r r r r r g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g g                 |
;ss|3sss4sss5sss6sss7sss                                                                                              0sss1sss2sss|
;  |                                                                                                              i i             |
;--|------------------------------------------------------------------------------------------------------------------------------|
;  |                                ^(close sideborder)                                                           ^(open sideborder)
;  |                           ^---FLI----------------->                                                      ^-----^(double line)
;  |                             ^---DMA Delay--------------------------------------------------------------^
;
; sprenable=ff
;CPU: 44 (+ 2=46)
;VIC: 16 (+ 1=17)
;     63
;
;x    - CPU regular cycles
;W    - CPU write cycles
;w    - CPU 3rd write cycle
;c    - VIC video ram
;g    - VIC color ram
;0..7 - VIC sprite pointer fetches
;s    - VIC sprite data accesses
;i    - VIC idle accesses
