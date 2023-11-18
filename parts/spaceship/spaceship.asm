!cpu 6510
bitmap			= $2000
screen 			= $0400
main			= $3f40

cnt			= $8b
atmp			= $8c
xtmp			= $8d
ytmp			= $8e
hi_tmp			= $8f

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}

* = bitmap		
			!bin "gekkigheid_005.koa",$1f40,2
			
* = main		
			sei
			lda #$35
			sta $01
			jsr fade_in
continue_a = *			
!ifdef release {
			+setup_sync $100
			jsr link_load_next_comp
			jsr link_load_next_raw
			dec $01
			jsr link_decomp
			inc $01
			+sync
			jsr fade_out
			ldx #stackcode_end - stackcode
-
			lda stackcode,x
			sta $0100,x
			dex
			bpl -
			jsr vsync
			lda #$00
			sta $d011
			jmp $0100
stackcode
!pseudopc $0100 {
			+setup_sync $70
			jsr link_load_next_comp
			+sync
			jmp link_exit
}
stackcode_end
} else {			
* = $0801
			!byte <eob+1, >eob+1
			!byte $E7		; BASIC line number:  $E7=2023 etc.
			!byte $07, $9E 
			!byte '0' + main % 100000 / 10000
			!byte '0' + main %  10000 /  1000
			!byte '0' + main %   1000 /   100
			!byte '0' + main %    100 /    10
			!byte '0' + main %     10
			!byte $3a,$8f,$20 	; :rem
			!pet 30,"per",129,"mers",5,17,17,17
eob			!byte $00, $00, $00	; end of basic
* = continue_a
			; wait some time while the pic is visible
			ldx #$00
-			jsr vsync
			inx
			bne -
			jsr fade_out
			jmp * ; end	
}

fade_in			jsr init
loop_fade_in		jsr plot
			jsr vsync
			lda cnt
			cmp #$90
			bne loop_fade_in			
			rts

fade_out		jsr invert_color_table
			lda #$06
			sta $d021
			ldx #$00
			stx cnt

-			jsr plot
			jsr vsync
			lda cnt
			cmp #$90
			bne -
			
			lda #$00
			sta $d011
			lda #$06
			;sta $d021
			sta $d020
			rts			
			
plot			ldx #$0f
-			stx xtmp
			txa
			clc
			adc cnt
			and #%00001111 ; 0-15
			tay
			sty ytmp	; die yte farbe für qab+x
			beq new_plots
			
after_new_plots		jsr reset_block ; set values for q1
			ldx xtmp
			txa
			clc
			adc cnt
			cmp #$90
			bcc +
			lda color_table+15 ; fadeout?
			cmp #$66
			bne noplot
			lda $daff
			sta $d020	; border transition
			jmp noplot
+			lda q1a,x	; Stelle
			jsr plot2
			lda q1b,x	; Stelle
			jsr plot2
			jsr next_block
			lda q2a,x	; Stelle
			jsr plot2
			lda q2b,x	; Stelle
			jsr plot2
			jsr next_block
			lda q3a,x	; Stelle
			jsr plot2
			lda q3b,x	; Stelle
			jsr plot2
			jsr next_block
			lda q4a,x	; Stelle
			jsr plot2
			lda q4b,x	; Stelle
			jsr plot2
noplot			dex
			cpx #$ff
			bne -
			inc cnt
			rts

new_plots		jsr rnd_q1
			sta q1a,x
			jsr rnd_q1
			sta q1b,x
			jsr rnd_q2
			sta q2a,x
			jsr rnd_q2
			sta q2b,x
			jsr rnd_q3
			sta q3a,x
			jsr rnd_q3
			sta q3b,x
			jsr rnd_q4
			sta q4a,x
			jsr rnd_q4
			sta q4b,x
			jmp after_new_plots
			
reset_block		lda #>col1
			sta a21+2
			lda #>$d800
			sta a22+2
			lda #>col3
			sta a23+2
			lda #>col2
			sta a24+2
			lda #>$0400
			sta a25+2
			rts
			
next_block		inc a21+2
			inc a22+2
			inc a23+2
			inc a24+2
			inc a25+2
			rts
			
plot2			tay			
a21			lda col1+$0000,y	; farbwert (col ram) an stelle y
			ora ytmp
			tax
			lda color_table,x
a22			sta $d800+$0000,y

a23			lda col3+$0000,y
			ora ytmp
			tax
			lda color_table,x
			and #%11110000
			sta hi_tmp			
a24			lda col2+$0000,y
			ora ytmp
			tax
			lda color_table,x
			and #%00001111
			ora hi_tmp
a25			sta $0400+$0000,y
			ldx xtmp
			rts

invert_color_table	ldy #$0f
loop_ict		sty ytmp
			ldx #$07
			ldy #$08
aict1			lda color_table,x
			pha
aict2			lda color_table,y
aict3			sta color_table,x
			pla
aict4			sta color_table,y
			iny
			dex
			bpl aict1 
			lda aict1+1
			clc
			adc #$10
			sta aict1+1
			sta aict2+1
			sta aict3+1
			sta aict4+1
			ldy ytmp
			dey
			bpl loop_ict
			rts

rnd_q1			lda #$1f
			beq eor_q1
			asl
			beq +
			bcc +
eor_q1			eor #$63
+			sta rnd_q1+1
			rts

rnd_q2			lda #$11
			beq eor_q2
			asl
			beq +
			bcc +
eor_q2			eor #$65
+			sta rnd_q2+1
			rts

rnd_q3			lda #$33
			beq eor_q3
			asl
			beq +
			bcc +
eor_q3			eor #$69
+			sta rnd_q3+1
			rts

rnd_q4			lda #$22
			beq eor_q4
			asl
			beq +
			bcc +
eor_q4			eor #$71
+			sta rnd_q4+1
			rts

init			jsr vsync
			lda #$00
			sta $d011
			lda #$03
			sta $dd00
			!byte $a9	; lda #
			!bin "gekkigheid_005.koa",1,$1f42 + $3e8 + $3e8
			sta $d021
			lda #$00
			sta $d020
			lda #$18
			sta $d018
			sta $d016
			jsr init_data
			
			jsr vsync
			lda #$3b
			sta $d011
			rts

init_data		ldy #$04
			ldx #$00
			stx cnt
-			
a01			lda col1,x
			and #$0f
			asl
			asl
			asl
			asl
a02			sta col1,x
a03			lda col2,x
			pha
			and #$0f
			asl
			asl
			asl
			asl
a04			sta col2,x
			pla
			and #%11110000
			;lsr
a05			sta col3,x
			lda #$00
a06			sta $0400,x
a07			sta $d800,x
			inx
			bne -			
			inc a01+2
			inc a02+2
			inc a03+2
			inc a04+2
			inc a05+2
			inc a06+2
			inc a07+2
			dey
			bne -
			rts
			
vsync			bit $d011
			bpl *-3
			bit $d011
			bmi *-3
			rts

q1a !fill 16, $3e
q1b !fill 16, $7c
q2a !fill 16, $22
q2b !fill 16, $44
q3a !fill 16, $66
q3b !fill 16, $cc
q4a !fill 16, $44
q4b !fill 16, $88

!align 255, 0
color_table
!by $66, $ff, $11, $ff, $ff, $cc, $ff, $cc, $cc, $bb, $cc, $bb, $00, $bb, $bb, $00  ; #0
!by $66, $bb, $99, $bb, $bb, $cc, $bb, $cc, $cc, $aa, $ff, $aa, $ff, $11, $ff, $11  ; #1
!by $66, $00, $99, $00, $99, $00, $99, $bb, $99, $bb, $bb, $bb, $22, $bb, $bb, $22  ; #2
!by $66, $bb, $66, $bb, $bb, $cc, $bb, $cc, $cc, $55, $cc, $55, $55, $33, $55, $33  ; #3
!by $66, $bb, $99, $bb, $bb, $99, $bb, $bb, $22, $bb, $22, $22, $44, $22, $44, $44  ; #4
!by $66, $bb, $66, $bb, $bb, $44, $bb, $44, $cc, $55, $ff, $dd, $11, $dd, $ff, $55  ; #5
!by $66, $ff, $11, $ff, $ff, $cc, $ff, $cc, $cc, $bb, $cc, $bb, $00, $bb, $bb, $66  ; #6
!by $66, $bb, $99, $bb, $bb, $cc, $bb, $cc, $cc, $aa, $ff, $aa, $ff, $11, $ff, $77  ; #7
!by $66, $bb, $99, $bb, $bb, $99, $bb, $bb, $22, $bb, $22, $22, $88, $22, $88, $88  ; #8 
!by $66, $ff, $11, $ff, $ff, $cc, $ff, $cc, $cc, $bb, $cc, $bb, $00, $bb, $22, $99  ; #9
!by $66, $bb, $99, $bb, $bb, $44, $bb, $44, $cc, $55, $ff, $dd, $11, $dd, $ff, $aa  ; #a
!by $66, $bb, $99, $bb, $bb, $cc, $dd, $ff, $11, $ff, $dd, $cc, $bb, $cc, $bb, $bb  ; #b
!by $66, $bb, $99, $bb, $cc, $dd, $ff, $11, $ff, $dd, $cc, $bb, $cc, $bb, $cc, $cc  ; #c
!by $66, $bb, $99, $bb, $bb, $cc, $bb, $cc, $cc, $aa, $ff, $aa, $ff, $11, $ff, $dd  ; #d
!by $66, $bb, $66, $bb, $44, $66, $bb, $44, $cc, $cc, $44, $cc, $cc, $ee, $ee, $ee  ; #e
!by $66, $bb, $99, $bb, $bb, $cc, $bb, $cc, $cc, $aa, $ff, $aa, $ff, $ff, $ff, $ff  ; #f

!align 255, 0		; color ram
col1			!bin "gekkigheid_005.koa",$3e8,$1f42 + $3e8
!align 255, 0		; screen lo
col2			!bin "gekkigheid_005.koa",$3e8,$1f42
!align 255, 0		; screen hi
col3			!fill 1024,00

!warn "q1a @", q1a
!warn "starship end @", *
