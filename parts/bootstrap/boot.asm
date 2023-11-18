!cpu 6510
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
!src "../../bitfire/music.inc"
!src "../../bitfire/config.inc"

		* = $0100
		sei
	!if SIDE != 1 {
		+stop_music_nmi
	}
		;lda #$35
		;sta $01
	!if SIDE == 1 {
                ;load music
                jsr link_load_next_comp
                ;lda #$00
                ;tax
                ;tay
		;jsr link_music_init_side1
		;+start_music_nmi
                jsr link_load_next_comp
		;load first part
;                jsr link_load_next_comp
;                jsr link_load_next_comp
;                lda #$00
;                tax
;                tay
;		jsr link_music_init_side1
;		;add if music entry changes on current side
;		lda #>link_music_play_side1
;		sta link_music_addr + 1
;		+start_music_nmi
                jmp link_exit
	}
	!if SIDE == 2 {
		lda #0
		sta $d011
		sta $d020
		sta $d021
		;load overload part $a000-$cfff
                jsr link_load_next_comp
		;load overload part $e000-$fxxx (=sprite mats)
                jsr link_load_next_comp
;		;load overload part $0400-$5000
;                jsr link_load_next_comp
  ;load overload part $0400-$5000 to $7000-
  jsr link_load_next_raw
  ;decrunch the last part, loaded at $7000, depacks to $0400-$5000:
  ;!macro set_depack_pointers $7000
  lda #<$7000
  sta bitfire_load_addr_lo
  lda #>$7000
  sta bitfire_load_addr_hi
  jsr link_decomp

                jmp link_exit
	}
	!if SIDE == 3 {
		lda $d011
		bpl *-3
		and #$20
		bne +
		sta $d020
		sta $d011
+
		;load first part
		jsr link_load_next_raw
		dec $01
		jsr link_decomp
		inc $01

		lxa #0
		tay
		jsr link_music_init_side3

		ldx #<.nmi
		lda #>.nmi

		stx $fffa
		sta $fffb
		lda #$00
		sta $dd0e
		lda $dd0d
		lda #$c7
		sta $dd04
		lda #$4c
		sta $dd05
		lda #$81
		sta $dd0d

		lda #$ff
.l
		cmp $d012
		bne .l

		lda #$11
		sta $dd0e

                jsr link_load_next_comp
                jsr link_load_next_comp
		sei
--
		lda $d011
		bpl --
		lda $d011
		bmi *-3

		ldy #$00
		sty $d015
		ldx #$27
-
		tya
.bmp		sta $6000,x
		dex
		bpl -
		lda .bmp + 1
		clc
		adc #$28
		sta .bmp + 1
		bcc +
		inc .bmp + 2
+
		cmp #$e8
		bne --
		sty $d011
.skip
                jsr link_load_next_comp
                jmp link_exit
.nmi
		pha
		txa
		pha
		tya
		pha
		lda $01
		pha
		lda #$35
		sta $01
		lda $dd0d
		jsr link_music_play_side3
		pla
		sta $01
		pla
		tay
		pla
		tax
		pla
		rti
	}
	!if SIDE == 4 {
		+set_music_addr link_music_play_side4_micro
		jsr link_load_next_comp
		lxa #0
		tay
		jsr link_music_init_side4_micro

                        ldx #<.nmi_handler
                        lda #>.nmi_handler

                        stx $fffa
                        sta $fffb
                        lda #$00
                        sta $dd0e
                        lda $dd0d
                        lda #$c7
                        sta $dd04
                        lda #$4c
                        sta $dd05
                        lda #$81
                        sta $dd0d

                        lda #$ff
.l
                        cmp $d012
                        bne .l

                        lda #$11
                        sta $dd0e

                ;jsr link_load_next_raw
		;dec $01
		;jsr link_decomp
		;inc $01
		+setup_sync $38
                jsr link_load_next_comp
		+sync

                jmp link_exit
!align 127,0
.nmi_handler
		pha
		txa
		pha
		tya
		pha
		lda $01
		pha
		lda #$35
		sta $01
		jsr link_music_play
		top fade
		lda $dd0d
		pla
		sta $01
		pla
		tay
		pla
		tax
		pla
		rti
fade
		lda #$ff
		beq +
		lsr
		lsr
		lsr
		lsr
		ora #$30
		sta $d418
		dec fade + 1
		rts
+
		lda #$7f
		sta $dd0d
		rts
	}
