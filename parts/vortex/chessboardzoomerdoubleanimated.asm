; vortex aka schwurbel aka chessboard zoomer double animated
;
; ACME Format
;
; memory:
; 
; $0800 - $1FFF : loader & music
; $2000 - $3FFF : bitmap (used only in the first seconds)
; $4000 - $5B D1 : vortex grow datastream (used only in the first seconds)
; $5BD2 - $XXXX : background scroller datastream
; $XXXX - $97FF : code
; $9800 - $BFFF : free (possibility to move up background datastream & code for more loading space)
; $C000 - $DFFF : 8 screens 0-7 (vortex)
; $E000 - $FFFF : 4 charsets 1a 2a 1b 2b (only the first 40 chars are needed)
; $E180 - $E7FF : speedcode for colorram shift & sprites
; $E980 - $E7FF : speedcode for colorram shift & sprites
; $F180 - $E7FF : speedcode for colorram shift & sprites
; $F980 - $E7FF : speedcode for colorram shift & sprites

!cpu 6510
!initmem $00

!ifndef release {
nextpart	= flicker	; Placeholder
}
show_raster_time = 0		; 0/1
sprites		 = 0		; 0/1 reduce glitch in vortex center
d016thingy	 = 0
miniscroll	 = 0
shortrunlength	 = 0
mitteschnell	 = 0

bitmap 		= $2000
videoram_bm 	= $0400

vortex_screens	= $c000

code1		= $c000
code2		= $b000
speedcode	= $e180 ;

zoom_out_end	= $9e
d018		= $9f

atemp		= $a0
xtemp		= $a1
ytemp		= $a2

col		= $a6
cnt		= col ; reuse
cnt2		= $a7
cnt3		= $a8
cnt4		= $a9
cnt5		= $aa
colcol		= $ab
cntcol		= $ac
cnt6		= $ad
cnt7		= varspace+3

s_d020		= $a3
s_d021		= $a4
s_d018		= $a5


keepalive	= cnt6	; reuse

bmp_pointer	= $ae ; & $af
vram_pointer	= $c9 ; & $ca
fram_pointer	= bmp_pointer ; re-use
pnt_stream	= bmp_pointer ; re-use
charrom_pointer	= $cb ; & $fc
zp_tmp		= charrom_pointer ; re-use
pnt_speedcode	= charrom_pointer ; re-use

coltmp		= $b0 ; - $c8 (25 bytes) colors for column 39

!ifdef release {
!src "../../bitfire/loader/loader_acme.inc"
!src "../../bitfire/macros/link_macros_acme.inc"
}

!ifndef release {
* = $0801
		!byte <eob+1, >eob+1
		!byte $E7		; BASIC line number:  $E7=2023 etc.
		!byte $07, $9E 
		;!byte '0' + fixstart % 100000 / 10000
		!byte '0' + fixstart %  10000 /  1000
		!byte '0' + fixstart %   1000 /   100
		!byte '0' + fixstart %    100 /    10
		!byte '0' + fixstart %     10
		!byte $3a,$8f,$20 	; :rem
		!pet 30,"per",129,"mers",5,17,17,17
eob		!byte $00, $00, $00	; end of basic
}

* = $2000
fixstart	jmp start
vstream_load
!bin "vstream.bin" 	; data for growing vortex
eo_vstream_load

;vstream = vstream_load
vstream = $e000

* = $4000
vortex_screens_data
;!bin "vortexscreens.bin" ; 8 screens with rotating vortex
; todo: add first dots in the middle at the beginning
!bin "vortexscreens_straight.bin" ; 8 screens with rotating vortex
!fill 8,0 ; empty char at $6000

zs_zoom_out
!bin "zs_zoom_out.bin" 	; data charset zoom out animation (40 bytes / frame)

!by 00
rz_zoom_out
!fill $36,$00	; first $35 "01" switch to "00"
!by $01
!bin "rz_zoom_out.bin",,$37	; vertical rasterlines zoom out animation
eo_rz	!byte 1

cr_scrolldata
!src "bg.asm"		; fullscreen colorram scroller
!by 0,0
!warn "start @", *

start		; MAIN/CORE
		jsr init
		jsr start_vortex
		jsr change_to_chessboard
!if(sprites){	jsr placesprites}
		jsr chessboard
		; part is now running in IRQ
!ifdef release {
}
		
-		bit keepalive	; wait for part to finish. loading next part...
		bvs -
		; part end
.load		
		sei		
		; todo IRQ auf neutral setzen
		; hier gehts dann mit dem nächsten Part weiter
		;lda #$35
		;sta $01
!ifdef release {
		ldx #stackcode_end-stackcode
-
		lda stackcode,x
		sta $0100,x
		dex
		bpl -
		jmp $0100
stackcode
		;sei
		;lda #$00
		;sta $d01a
		;dec $d019
;            !pseudopc $0100 {
;                lda #<loader_irq
;                sta $fffe
;                lda #>loader_irq
;                sta $ffff
;                lda #$f0
;                sta $d012
;                inc $d019
;                cli
		+setup_sync $30
		jsr link_load_next_comp
		+sync
		;+stop_music_nmi
		jmp link_exit
;loader_irq:
;            inc $d019
;            rti
;            
;            }
stackcode_end		
} else {
		jmp nextpart ; Placeholder: flicker
		
flicker		inc $d002
		jmp *-3
}


start_music
!ifdef release {
		lxa #0
		tay
		jsr link_music_init_side1
		+start_music_nmi
}
		rts

init		sei
		lda #$35
		sta $01
		jsr init_screen
		jsr copy_vstream
		jsr copy_vortex_screens
		jsr screen_to_bitmap	; overwriting $2000-$3fff
		jsr start_music
		;jsr makesprites		; for patching glitch in vortex center
		rts ;jmp code2 ; at $b000

init_screen	lda $d018	; einige aktuelle IO-werte speichern
		sta s_d018
		lda $d020
		and #$0f
		sta s_d020
		lda $d021
		and #$0f
		sta s_d021
					
!if(mitteschnell){
		lda #$a0
		sta $0400+19+11*40
		sta $0400+20+11*40
		sta $0400+19+12*40
		sta $0400+20+12*40

		; $77,$99,$88,$dd ; vortex colors

		lda coltab+3
		sta $d800+19+11*40
		lda coltab+0
		sta $d800+20+11*40
		lda coltab+1
		sta $d800+19+12*40
		lda coltab+2
		sta $d800+20+12*40
}

		
		ldx #$01
		stx cntcol
		; todo:
		; sprites off
		; 40 spalten
		; 25 zeilen
		; IRQ vektoren im RAM auf sicheres RTI setzen SPÄTER, WENN VSCREENS KOPIERT!
		; lda #$40 ; rti
		; sta irqrti
		; lda #<irqrti
		; sta $fffa
		; lda #>irqrti
		; sta $fffb
		rts	


copy_vstream	;
		ldy #$1c
		ldx #$00
ldavstream	lda vstream_load,x
		sta vstream,x
		inx
		bne ldavstream
		inc ldavstream+2
		inc ldavstream+5
		dey
		bpl ldavstream
		rts

!if(sprites){			
makesprites
		; clear sprites
		ldx #$c0
		lda #$00
-		sta $e740-1,x
		sta $ef40-1,x
		sta $f740-1,x
		dex
		bne -
		
		lda #$ff
		lda #$00
		sta cnt6
		
		; 3 rows
		;lda #%10101010
		lda #%01010101 ; invers!
		lda #$ff
		ldx #$00
-		eor cnt6 ;$ff
		sta $c000+$9e*$40+0,x
		sta $c000+$9e*$40+1,x
		sta $c000+$9f*$40+0,x
		sta $c000+$9f*$40+1,x
		sta $c000+$bd*$40+1,x
		sta $c000+$be*$40+0,x
		sta $c000+$bf*$40+1,x
		sta $c000+$bf*$40+2,x
		eor cnt6
		sta $c000+$dd*$40+1,x
		sta $c000+$dd*$40+2,x
		sta $c000+$de*$40+1,x
		sta $c000+$df*$40+2,x
		eor cnt6
		inx
		inx
		inx
		cpx cnt6
		bne -

		; 1.8 rows (5+8 pixel)
		;lda #%10101010
		lda #%01010101 ; invers!
		lda #$ff
		ldx #$00
-		eor cnt6
		sta $c000+$bd*$40+0,x
		sta $c000+$bd*$40+2,x
		sta $c000+$be*$40+1,x
		sta $c000+$be*$40+2,x
		eor cnt6
		sta $c000+$de*$40+0+8*3,x
		sta $c000+$de*$40+2+8*3,x
		sta $c000+$df*$40+1+8*3,x
		sta $c000+$df*$40+0+8*3,x
		eor cnt6
		inx
		inx
		inx
		cpx #$27
		bne -
		
		; 1 row
		;lda #%10101010
		lda #%01010101 ; invers!
		lda #$ff
		ldx #$00
-		eor cnt6
		sta $c000+$9d*$40+1+(5+0)*3,x
		sta $c000+$9d*$40+1+(5+8)*3,x
		sta $c000+$9d*$40+2+(5+0)*3,x
		sta $c000+$9d*$40+2+(5+8)*3,x
		eor cnt6
		sta $c000+$dd*$40+0+(0)*3,x
		sta $c000+$9e*$40+2+(5+2)*3,x
		sta $c000+$bf*$40+0+(8-1)*3,x
		sta $c000+$9f*$40+2+(5+8)*3,x
		eor cnt6
		inx
		inx
		inx
		cpx #$18
		bne -	
		rts

placesprites	lda #$00
		lda #%00001111
		sta $d015
		
		ldx #$00
		stx $d017
		stx $d01c
		stx $d01d
		dex ; $ff
		stx $d01b
}
		lda coltab+0 ; gelb 23
		;sta $d022
		sta $d029
		lda coltab+1 ; braun 21
		;sta $d024
		sta $d027
		lda coltab+2 ; orange 24
		;sta $d023
		sta $d02a
		lda coltab+3 ; hellgrün 22
		;sta $d021
		sta $d028

!if(1=2){		
		lda #$34
		sta $01
		lda #$9d
		ldx #$07
-		sta $c000+$03f8+$0000,x
		sta $c000+$03f8+$0400,x
		sta $c000+$03f8+$0800,x
		sta $c000+$03f8+$0c00,x
		sta $c000+$03f8+$1000,x
		sta $c000+$03f8+$1400,x
		sta $c000+$03f8+$1800,x
		sta $c000+$03f8+$1c00,x
		dex
		bpl -
		inc $01
}
		
xm = $b0+8 ; $9f+17
ym = $8d-1 ; $78+16+5
		lda #xm
		sta $d000
		lda #ym-$10
		sta $d001
		
		lda #xm
		sta $d002
		lda #ym
		sta $d003
		
		lda #xm-$10
		sta $d004
		lda #ym
		sta $d005
		
		lda #xm-$10
		sta $d006
		lda #ym-$10
		sta $d007	
		rts



copy_vortex_screens
		; copy all 8 screens from $4xxx to $c000-$dfff
		lda #$34
		sta $01
		ldx #$20
		ldy #$00
ldav1		lda vortex_screens_data,y
stav1		sta vortex_screens,y
		and #%11000000
		;ora #$7d ; char at $43e8-$43ef
ldav2		sta vortex_screens_data,y
		iny
		bne ldav1
		inc ldav1+2
		inc ldav2+2
		inc stav1+2
		dex
		bne ldav1		
		inc $01	; $35
		rts
		
screen_to_bitmap
		lda #<bitmap ; 0
		sta bmp_pointer
		sta vram_pointer
		lda #>bitmap
		sta bmp_pointer+1
		lda #$04 ; hi von $0400, start aktueller screenram
		sta vram_pointer+1
	
		; screen ab $0400 zeichenweise aus charrom in bitmap kopieren
		ldx #$1a ; hi anfangsadresse charrom (vor rol)
		lda s_d018 ; $d018 bit 1 (and 2) 0=normal, 1=lowercase: chars ab d800
		and #$02 ;kleinschreibung aktiv?
		beq charloop
		inx ; $1b
		
charloop	ldy #$00
		stx charrom_pointer+1
		lda (vram_pointer),y
		asl
		rol charrom_pointer+1
		asl
		rol charrom_pointer+1
		asl
		rol charrom_pointer+1
		sta charrom_pointer		
		ldy #$07
charread	lda #$31 ; char rom
		sta $01
		lda (charrom_pointer),y
		sta (bmp_pointer),y
		dey
		bpl charread
		
		lda bmp_pointer
		clc
		adc #$08 ; nächstes zeichen in bitmap
		bcc +
		inc bmp_pointer+1
+		sta bmp_pointer

		ldy vram_pointer
		iny
		bne +
		inc vram_pointer+1
+		sty vram_pointer
		cpy #$e8		
		bne charloop
		ldy vram_pointer+1
		cpy #$07 ; $07e8 ende screenram, wichtig, damit IRQ vektoren bei $fffa etc nicht überschrieben werden  ???
		bne charloop
screen_to_bitmap_2		
		; farbram übernehmen
		ldy #$00
		sty vram_pointer
		sty fram_pointer
		lda #$d8
		sta fram_pointer+1
		lda #>videoram_bm 
		sta vram_pointer+1
	
		lda #$35
		sta $01 

		ldx #$40
-		cpx $d012
		bne -
		jsr colorram512 ; first half	
		;Bitmap-Modus aktivieren
		lda $D011                      ;VIC-II Register 17 in den Akku
		ora #%00100000                 ;Bitmap-Modus
		sta $D011                      ;aktivieren
		lda $D018
		;and #%00000111                 ;Mit BIT-3
		ora #%00001000               ; bitmap @ $2000
		sta $D018
		jsr colorram512 ; second half

		; make colorram black
!if(1=2){	;ldx #$00
		txa
-		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		inx
		bne -
}
		rts

colorram512	ldx #$02
d8read		lda (fram_pointer),y
		asl
		asl
		asl
		asl
		ora s_d021
vrwrite		sta (vram_pointer),y
		iny
		bne d8read
		inc fram_pointer+1
		inc vram_pointer+1
		dex
		bne d8read
		rts
	
makespeedcode	; 4 * 6 rows of colorram in unused charset ram ($e000 + $180)
		; AE 01 D8   ldx $d801
		; 8E 00 D8   stx $d800
		; A6 40      ldx $40
		; 8E 27 d8   stx $d827
		; 60         rts

		lda #$04
		sta cnt2		
		lda #$01
		sta fram_pointer
		lda #$d8
		sta fram_pointer+1
		lda #<speedcode
		ldy #>speedcode
sc_loop_outer	sta pnt_speedcode
		sty pnt_speedcode+1 
		lda #$06 ; 6 rows
		sta cnt
sc_loop		ldy #$00
		ldx #$00
-		lda #$ae
		sta (pnt_speedcode),y
		iny
		lda fram_pointer
+		sta (pnt_speedcode),y
		sta cnt4
		iny
		iny
		iny
		sec
		sbc #01
		sta (pnt_speedcode),y
		dey
		dey
		lda fram_pointer+1
		sta (pnt_speedcode),y
		sta cnt5
		iny
		iny
		iny
		sbc #0
		sta (pnt_speedcode),y
		dey
		dey
		lda #$8e
		sta (pnt_speedcode),y
		iny
		iny
		iny
		inc fram_pointer
		bne +
		inc fram_pointer+1
+		inx
		cpx #$27
		bne -
		inc fram_pointer
		bne +
		inc fram_pointer+1
+
		lda #$a6
		sta (pnt_speedcode),y
		iny
read_coltmp	lda #coltmp
		sta (pnt_speedcode),y
		iny
		lda #$8e
		sta (pnt_speedcode),y
		iny
		iny		
		lda cnt5 ; (hi)
		sta (pnt_speedcode),y
		dey
		lda cnt4 ; (lo)
		sta (pnt_speedcode),y
		; pnt_speedcode + $ef+6 for next row
		lda pnt_speedcode
		clc
		adc #$ef
		sta pnt_speedcode
		bcc +
		inc pnt_speedcode+1
+		;
		inc read_coltmp+1
		dec cnt		
		bne sc_loop
		
		ldy #$00
		lda #$60 ; RTS @ $x59a
		sta (pnt_speedcode),y
		ldy pnt_speedcode+1
		lda pnt_speedcode
		; +0266
		iny
		iny
		clc
		adc #$66
		bcc +
		iny
+		dec cnt2
		beq +
		jmp sc_loop_outer
+		rts

start_vortex
!if(1=2){
		ldx #$f1
-		cpx $d012
		bne - 				
-		cpx $d012
		beq -
}
		lda #<(vstream)
		sta pnt_stream
		lda #>(vstream)
		sta pnt_stream+1
		ldy #$00
vloop		lda (pnt_stream),y
		bne new_adr
		; wechsel (frame, ende?)
		iny
		bne +
		inc pnt_stream+1
+		lda (pnt_stream),y
		beq end_of_stream
		; frame
	
		ldx #$ff
-		cpx $d012
		bne - 				
-		cpx $d012
		beq -

new_adr		; ist hi-byte + farbe
		and #$0f
		tax
		lda adrtab,x
		sta colsta+2
		txa
		and #$03
		tax
		lda coltab,x
		tax
		iny
		bne +
		inc pnt_stream+1
+		lda (pnt_stream),y
		sta colsta+1
colsta		stx $0400
		iny
		beq over01
-		lda (pnt_stream),y
		beq next_adr
		; diff
		clc
		adc colsta+1
		sta colsta+1
		bcc +
		inc colsta+2
+		bne colsta ; jmp
		beq colsta ; jmp
end_of_stream	rts
over01		inc pnt_stream+1
		bne -

next_adr 	iny
		bne +
		inc pnt_stream+1
+		bne vloop ; jmp


irq0init	sei
		lda #$7f
		sta $dc0d
		lda $dc0d
		ldx #$01
		stx $d01a

		lda #startirqline
		sta $d012

		lda #<irq0
		sta $fffe 
		lda #>irq0
		sta $ffff

		;LDA #$03
		;STA $DD02		

		lda #$02
		sta $dd00

		; charset
		;LDA $D018
		;AND #%11110001                     ; Bits 3..1 
		;ORA #%00001000                     ; $6000
		; *** Start of the Screen-Memory *** 
		;AND #%00001111                     ; Bits 7..4
		;STA $d018

		lda #$5b
		sta $d011
		lda #%00011000 ; charset $6000, screen $4x
		lda #%01101000 ; charset $6000, screen $4x
		;clc
		;adc #$10
		sta $d018

		;lda #$00
		;sta $d020
		lda coltab+2 ; orange 24
		sta $d023
		;sta $d029
		lda coltab+0 ; gelb 23
		sta $d022
		;sta $d028
		lda coltab+3 ; hellgrün 22
		sta $d021
		;sta $d027
		lda coltab+1 ; braun 21
		sta $d024
		;sta $d02a
		cli
		rts

irq0		sta atemp
		lsr $d019
		lda $d018
		sec
		sbc #$10
		bpl +

		lda $d023
		pha
		lda $d024
		sta $d023
		lda $d021
		sta $d024
		lda $d022
		sta $d021
		pla
		sta $d022

		lda #%01111000 ; charset $6000, screen $4000
+		sta $d018
		lda atemp
		rti

change_to_chessboard
		jsr irq0init
		jsr makespeedcode

		; colorram to light blue
		lda #$06
		ldx #$00
-		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
		inx
		bne -
		
		lda #$0f ; light grey border
		sta $d020
		
		;lda #$34
		;sta $01
		ldx #$60	; clear charset 0
		lda #$00
-		sta $e000-$60,x
		sta $e0a0-$60,x
		sta $e800-$60,x
		sta $e8a0-$60,x
		inx
		bne -
		;lda #$ff
		sta zoom_out_end
		; todo: fill charset 1
!if(sprites){		
		; reassemble		
		ldy #$04
ra_loop		
		ldx #$00
-		lda $c3f8,x
		pha
		lda $c7f8,x
		sta $c3f8,x
		lda $cbf8,x
		sta $c7f8,x
		lda $cff8,x
		sta $cbf8,x
		lda $d3f8,x
		sta $cff8,x
		lda $d7f8,x
		sta $d3f8,x
		lda $dbf8,x
		sta $d7f8,x
		lda $dff8,x
		sta $dbf8,x
		pla
		sta $dff8,x
		inx
		cpx #$08
		bne -

		lda spr_0_x
		pha
		lda spr_0_y
		pha
		lda spr_1_x
		pha
		lda spr_1_y
		pha
		lda spr_2_x
		pha
		lda spr_2_y
		pha
		lda spr_3_x
		pha
		lda spr_3_y
		pha
		
		ldx #$00
-		lda spr_0_x+1,x
		sta spr_0_x,x
		lda spr_0_y+1,x
		sta spr_0_y,x
		lda spr_1_x+1,x
		sta spr_1_x,x
		lda spr_1_y+1,x
		sta spr_1_y,x
		lda spr_2_x+1,x
		sta spr_2_x,x
		lda spr_2_y+1,x
		sta spr_2_y,x
		lda spr_3_x+1,x
		sta spr_3_x,x
		lda spr_3_y+1,x
		sta spr_3_y,x
		inx
		cpx #$07
		bne -

		pla
		sta spr_3_y,x
		pla
		sta spr_3_x,x
		pla
		sta spr_2_y,x
		pla
		sta spr_2_x,x
		pla
		sta spr_1_y,x
		pla
		sta spr_1_x,x
		pla
		sta spr_0_y,x
		pla
		sta spr_0_x,x

		dey
		beq +
		jmp ra_loop
+		
		;inc $01 ; $35
}
no_reassemble		
		; todo: ev. auf günstige rasterposition zum umschalten warten?
		lda #$fc
-		cmp $d012
		bne -
		
		;vic bank
		lda #%00000000	;Bank-3 (bank 0 wäre ...11) 
		sta $DD00
		; bitmap aus
		;lda $d011
		;and #%11011111
		;ora #%01000000
		lda #$db
		sta $d011
		lda #%00101000 ; charset $e000, screen $d000
		lda #%01111000 ; charset $e000, screen $d000
		;sta $d018

		;lda #$00
		;sta $d020
		lda coltab+1 ; braun 21
		sta $d023
		;sta $d029
		lda coltab+2 ; orange 24
		sta $d022
		;sta $d028
		lda coltab+0 ; gelb 23
		sta $d021
		;sta $d027
		lda coltab+3 ; hellgrün 22
		sta $d024
		;sta $d02a

return		rts	
		
chessboard	lda #$08 ; 02
!if(shortrunlength){
		lda #$02
}
		sta cnt5	
		lda #$05	
		sta cnt3

		lda #$ff
		sta+1 keepalive

		;lda #%10101010
		;lda #$7f
		;jsr next_a ; set bit pattern in charset
		lda #$3a-6 ; first d018 when irq active
		;eor #$02
		sta d018
		sta $d018
		
		sei
		lda #$7f
		sta $dc0d  ;disable timer interrupts which can be generated by the two CIA chips
		;sta $dd0d  ;the kernal uses such an interrupt to flash the cursor and scan the keyboard, so we better stop it.
		lda $dc0d  ;by reading this two registers we negate any pending CIA irqs.
		;lda $dd0d  ;if we don't do this, a pending CIA irq might occur after we finish setting up our irq.
		lda #$01   ;this is how to tell the VICII to generate a raster interrupt
		sta $d01a
		
		lda #startirqline   ;this is how to tell at which rasterline we want the irq to be triggered
		sta $d012

		lda $d011   ;as there are more than 256 rasterlines, the topmost bit of $d011 serves as
		and #%01111111
		sta $d011  ;the 9th bit for the rasterline we want our irq to be triggered.
			   ;here we simply set up a character screen, leaving the topmost bit 0.
		lda #<irq1  ;this is how we set up
		sta $fffe  ;the address of our interrupt code
		lda #>irq1
		sta $ffff
		
		lda #$ff
		sta cnt7
		cli        ;enable maskable interrupts again
		
		; make @ char for next part ($6000)
		lda #%11100001
		sta $6000
		sta $6001
		sta $6002
		sta $6003
		eor #$ff
		sta $6004
		sta $6005
		sta $6006
		sta $6007
		
zoomloop	ldx #$fe
-		cpx $d012
		bne -
		lda #startirqline
		sta $d012
		jsr oneframe
		; end of zoom out?
		bit zoom_out_end ;
		bvc zoomloop	; bvs	
		
		sei
		lda #<irq3
		sta $fffe 
		lda #>irq3
		sta $ffff	

		lda #$02
		sta $dd00

		lda #$5b
		sta $d011
		lda #%01001000 ; charset $6000, screen $4x
		clc
		adc #$10
		sta $d018

		lda #$fb
		sta $d012
		lda $d011		
		and #%01111111
		sta $d011		
		cli

jetzt_laden
vor_zoomloop3	; enable loading

		
		; afterwards, jmp here:
zoomloop3	lda cnt3
		cmp #$bb ; check for end of scroller
		bne zoomloop3
		lda cnt5
		cmp #$08
		bne zoomloop3

		; restore vram @ $c000
repair_l1	ldy #$00
		ldx #$00
-		tya
c0a2		ora $c000-$0000,x
c0b2		sta $c000-$0000,x
		iny
		cpy #40
		bne +
		ldy #$00
+		inx
		bne -

		; zoom out
		
!if(1=2) {	; first, present 2x2 char
		lda #%01100110 ; charset $6000, screen $4x
		sta charanimation_lf+0
		sta charanimation_lf+3
		sta charanimation_lf+4
		sta charanimation_lf+7
		eor #$ff
		sta charanimation_lf+1
		sta charanimation_lf+2
		sta charanimation_lf+5
		sta charanimation_lf+6
}

lp_zs_zoomin	ldx #$07
zs_zoomin	lda charanimation+5*8,x
		sta charanimation_lf,x
		dex
		bpl zs_zoomin

		ldy #$02		
		jsr wait_y_frames
		
		lda zs_zoomin+1
		sec
		sbc #$08
		bcs +
		dec zs_zoomin+2
+		sta zs_zoomin+1
		
		dec zi_count
		bne lp_zs_zoomin
		
		; switch to upper mem screens & irq with raster (zoom in!)
		sei
		;vic bank
		lda #%00000000	;Bank-3 (bank 0 wäre ...11) 
		sta $DD00
		; bitmap aus
		;lda $d011
		;and #%11011111
		;ora #%01000000
		lda #$db
		sta $d011
		;lda #%00101000 ; charset $e000, screen $d000
		;lda #%01111000 ; charset $e000, screen $d000		
		lda #$3a ; first d018 when irq active
		; ev. alten wert d018 +1 übernehmen?
		;eor #$02
		sta d018
		sta $d018		

		lda #startirqline 
		sta $d012
		lda $d011   
		and #%01111111
		sta $d011  
		lda #<irq1
		sta $fffe
		lda #>irq1
		sta $ffff
		
		lda #$ff
		sta cnt7   ;?
		cli

		;lda #$ff
		;sta+1 keepalive
		lda #$00
		sta+1 zoom_out_end
		sta+1 keepalive
		
zoomloop2	ldx #$fe
-		cpx $d012
		bne -
		lda #startirqline
		sta $d012
		jsr oneframe2
	
		bit zoom_out_end ; ; end of zoom out?
		bvc zoomloop2	; bvs	
			
zoomloop_x	;bit keepalive 	; (!wait for part to finish. loading next part...)
		;bvs zoomloop_x	;
		ldy #$01
		jsr wait_y_frames
		lda #$0f ; light grey screen
		sta $d020
		sta $d021
		lda #$00
		sta $d011		

		rts ; back to main

zi_count	!by 7 ; 6 steps of charanimation

wait_y_frames	bit $d011
		bpl wait_y_frames
-		bit $d011
		bmi -
		dey
		bne wait_y_frames
		rts

irq3		sta atemp
		sty ytemp
		stx xtemp
		lsr $d019
		lda $d018
		sec
		sbc #$10
		bpl +

		lda $d023
		pha
		lda $d024
		sta $d023
		lda $d021
		sta $d024
		lda $d022
		sta $d021
		pla
		sta $d022

		lda #%01111000 ; charset $6000, screen $4000
+		sta $d018
		
		inc cnt3
		bne +
		inc cnt5
+		lda cnt3
		and #$01
		beq +
		jsr shiftcolram
		jmp eo_irq3
+		jsr new_column

		; char animation up top 1x1
		dec cnt_at_wait
		bne eo_irq3
		lda #$02 ; pause between animation phases
		sta cnt_at_wait
		
		lda cnt_at_ani
		asl
		asl
		asl
		tax
		ldy #$00
-		lda charanimation,x
		sta $6000,y
		inx
		iny
		cpy #$08
		bne -

		cpx #$38
		beq eo_irq3

		inc cnt_at_ani

eo_irq3		lda atemp
		ldy ytemp
		ldx xtemp
		rti

cnt_at_wait	!by $01
cnt_at_ani	!by $00

charanimation
!by %01001110
!by %10110001
!by %10110001
!by %10110001
!by %01001110
!by %10110001
!by %10110001
!by %01001110

!by %10110001
!by %10110001
!by %01001110
!by %01001110
!by %01001110
!by %10110001
!by %01001110
!by %01001110

!by %00110011
!by %11001100
!by %11001100
!by %00110011
!by %00110011
!by %11001100
!by %11001100
!by %00110011

!by %00110011
!by %11001100
!by %11001100
!by %00110011
!by %00110011
!by %11001100
!by %11001100
!by %00110011

!by %00110011
!by %11001100
!by %11001100
!by %00110011
!by %00110011
!by %11001100
!by %11001100
!by %00110011

!by %10010110
!by %01101001
!by %01101001
!by %10010110
!by %01101001
!by %10010110
!by %10010110
!by %01101001

charanimation_lf
!by %01010101
!by %10101010
!by %01010101
!by %10101010
!by %01010101
!by %10101010
!by %01010101
!by %10101010



startirqline	= 47
-		;iny
		;sty xor+1
		ldy #startirqline
		bne next_r_line ; jmp
irq1		
		sty ytemp
		ldy $d012
		sta atemp
		lda d018
		;eor #$00 ; #$02
rrr		cpy $d012
		beq rrr
		sta $d018
		lsr $d019	; acknowledge/clear vic interrupt condition
xor		eor #$02
get_rasterline	ldy rz_zoom_out
		bne +
		;sty xor+1 ; a=0
		ldy #startirqline
+		cpy #$01
		beq -
next_r_line	sty $d012
		sta d018
		inc get_rasterline+1
		beq +
		lda atemp
		ldy ytemp
		rti
+		inc get_rasterline+2
		lda atemp
		ldy ytemp
		rti

irq2		pha
		lda d018
		and #%11111101
		sta $d018
		lsr $d019
		pla
		rti
					
irq		sta atemp
		stx xtemp
		sty ytemp

!if(show_raster_time) {
		lda cnt5
		sta $d020
}		
		lsr $d019	; acknowledge/clear vic interrupt condition
		lda cnt7
		;beq +
		jsr oneframe
		inc cnt7
+
!if(show_raster_time) {
		lda #$00
		sta $d020
}
		lda atemp
		ldx xtemp
		ldy ytemp
		rti		
tmptmp
!by		0,0,0

vortex_color_cycle
		lda cnt3
		;cmp #$09
		;beq next_a
		and #$07
		;pha
		;cmp #$04
		;bne +
!if(sprites){	; sprites
		ldx $d027+2
		ldy $d027+3
		sty $d027+2
		ldy $d027+0
		sty $d027+3
		ldy $d027+1
		sty $d027+0
		stx $d027+1
}		
+		cmp #$07
		bne +
		ldx $d023
		ldy $d024
		sty $d023
		ldy $d021
		sty $d024
		ldy $d022
		sty $d021
		stx $d022
		
+		asl
		asl
		asl
		asl
		ora #%00001000	; select screen
xor2		eor #$02	; select charset at top of screen
		sta d018
		;sta $d018
!if(sprites) {	; sprites
		pla
		;sta $d020
		tax
		lda spr_0_x,x
		sta $d000
		lda spr_0_y,x
		sta $d001
		lda spr_1_x,x
		sta $d002
		lda spr_1_y,x
		sta $d003
		lda spr_2_x,x
		sta $d004
		lda spr_2_y,x
		sta $d005
		lda spr_3_x,x
		sta $d006
		lda spr_3_y,x
		sta $d007
}		
		rts

oneframe_start	dec cnt3
		bne +
		dec cnt5
		bne +
		lda #$00		; ende
		sta+1 keepalive
		; check end of rasterline zoomer - todo: better implementation?
+		ldy get_rasterline+2
		ldx get_rasterline+1
		bne +
		dey
+		dex
		rts

counter01	!by 1

write_get_rasterline
		ldy grl3+2
		inx			; adr. +1 (after 0/1)
		bne +
		iny
+		stx get_rasterline+1	
		sty get_rasterline+2
		rts

oneframe2	jsr oneframe_start
		; zurückspulen zur vorherigen raster-liste
		;
		;stx grl3+1 ; copy adress for checking before-byte for end flag (0/1)
		sty grl3+2
		lda #$02
		sta counter01
-		dex
		cpx #$ff
		bne grl3
		dec grl3+2
grl3		ldy $1000,x		
		beq at_rasterliststart0 ; check if 0 (for starting charset on top of screen)
		dey			; check if 1
		bne -
		; at rasterliststart with 1
		dec counter01
		bne -
		jsr write_get_rasterline
		ldx #$00		; first charset (A/B) at TOP
		beq after_at_start	; jmp
		
at_rasterliststart0 ; at rasterliststart with 0
		dec counter01
		bne -
		jsr write_get_rasterline
		ldx #$02		; first charset (A/B) at TOP
after_at_start	stx xor2+1
			
		jsr vortex_color_cycle
		
doshift2	lda cnt3
		and #$01 ; every second time
		bne +	; colorram scroll
		; no colorram scroll
		;
		; !bit zoom_out_end ; check for end
		; bvc go_zs_zoom ; do zs zoomer
		; falls noch nicht zu ende:		
		jsr rewind_sz_zoom
		;inc $d020
		jsr do_sz_zoom	; zoom in (charset) 
		;dec $d020
		jsr new_column	; prepare column39 in frame before colorram scroll
		rts
+		; yes, do colorram scroll

		; end?
		lda a_y+1
		cmp #$28
		bne +
		lda a_sz_zoom+2
		cmp #$60
		bne +
		lda #$ff
		sta zoom_out_end ; yes, this is the end
		
+		jsr shiftcolram
		rts
		
oneframe	jsr oneframe_start
		stx grl2+1 ; copy adress for checking before-byte for end flag (0/1)
		sty grl2+2
		
		cpx #<(eo_rz-1)
		bne +
		cpy #>(eo_rz-1)
		bne +
		
		ldy #$ff
		sty zoom_out_end
		ldx #<(eo_rz-$32)	; create endless loop, auf letzte rasterdarstellung zurück (alle 4 lines)	
		ldy #>(eo_rz-$32)
		sty get_rasterline+2
		stx get_rasterline+1		
				
+		ldx #$02
grl2		ldy xor2+1	; prüfe endkennung 0/1 und setze ZS entsprechend
		;sty tmptmp
		;sty $d020
		bne +
		ldx #$00
		;cpy #$01
		;bne +
		;ldx #$02
+		stx xor2+1

!if(miniscroll){ ; shift @ 1 nach unten (jedes frame)
		lda $e000
		pha
		lda $e007
		sta $e000
		lda $e006
		sta $e007
		lda $e005
		sta $e006
		lda $e004
		sta $e005
		lda $e003
		sta $e004
		lda $e002
		sta $e003
		lda $e001
		sta $e002
		pla
		sta $e001
}		
		; vortex color cycle
		jsr vortex_color_cycle

doshift
!if(show_raster_time) {
		lda #$02
		sta $d020
}		
		lda cnt3
		and #$01 ; every second time
		bne +	; colorram scroll
!if(d016thingy=1){
		lda #$c3
		sta $d016
}
		; no colorram scroll
		bit zoom_out_end
		bvc go_zs_zoom ; do zs zoomer
		; copy @
		ldy c0a+2
		cpy #$e0
		beq copy_at_c_fin ; copy "all @" finished
		iny
		sty c0a+2
		sty c0b+2
		cpy #$e0
		beq make_at	; 1 x at the end: make @

		sei
		dec $01
		ldx #$00
c0a		lda $c000-$0100,x
		and #%11000000
c0b		sta $c000-$0100,x
		inx
		bne c0a
		inc $01
		cli
		jmp after_zs_zoom

make_at		ldx #$03 ; 1 x
ldabitpat	lda #%11000011
		sta $e000,x
		eor #$ff
		sta $e004,x
		dex
		bpl ldabitpat
		;inc $d020
		sei
		lda #<irq2
		sta $fffe
		lda #>irq2
		sta $ffff
		lda d018
		and #%11111101
		sta d018
		lda #startirqline
		sta $d012
		cli	
		bne after_zs_zoom ; jmp
		
go_zs_zoom	;inc $d020
		jsr do_sz_zoom
		;dec $d020

after_zs_zoom		
		
do_new_column	jsr new_column
		rts ;jmp noshift
		
+		; do color scroll
		;lda #$0e ; first "a" (y?) for irq/frame
		;lda #%01001000 ; charset $e000, screen $d000
		;ldy #$00
		jsr shiftcolram
		rts		
		
copy_at_c_fin	jmp after_zs_zoom

!if(1=2) {
		; zs zoom in!
- 		inc a_sz_zoom2+2
		bne +
do_sz_zoom2	ldx #$00
a_y2		ldy #$00
a_sz_zoom2	lda zs_zoom_out,y
		iny
		beq -
+		sta $e000+0,x
		sta $e000+1,x
		sta $e000+2,x
		sta $e000+3,x
		sta $e000+4,x
		sta $e000+5,x
		sta $e000+6,x
		sta $e000+7,x
		eor #$ff
		sta $e800+0,x
		sta $e800+1,x
		sta $e800+2,x
		sta $e800+3,x
		sta $e800+4,x
		sta $e800+5,x
		sta $e800+6,x
		sta $e800+7,x
		txa
		sbx #-8
		bne a_sz_zoom2
		; copy adress place 1 to 2
		lda a_sz_zoom2+2
		sta a_sz_zoom2b+2
		rts

a_sz_zoom2b	lda $1111
}

rewind_sz_zoom
		lda a_y+1
		sec
		sbc #80
		bcs +
		dec a_sz_zoom+2
+		sta a_y+1
		rts

		; zs zoom out! (and later: zoom in!)
- 		inc a_sz_zoom+2
		bne +
do_sz_zoom	ldx #$00
a_y		ldy #$00
a_sz_zoom	lda zs_zoom_out,y
		iny
		beq -
+		sta $e000+0,x
		sta $e000+1,x
		sta $e000+2,x
		sta $e000+3,x
		sta $e000+4,x
		sta $e000+5,x
		sta $e000+6,x
		sta $e000+7,x
		eor #$ff
		sta $e800+0,x
		sta $e800+1,x
		sta $e800+2,x
		sta $e800+3,x
		sta $e800+4,x
		sta $e800+5,x
		sta $e800+6,x
		sta $e800+7,x
		txa
		sbx #-8
		bne a_sz_zoom
		; copy adress place 1 to 2
		lda a_sz_zoom+2
		sta a_sz_zoomb+2
		bne a_sz_zoomb ; always true

- 		inc a_sz_zoomb+2
		bne +
a_sz_zoomb	lda zs_zoom_out,y
		iny
		beq -	
+		; todo unterscheidung dubble buffer charsets
		sta $e100+0,x
		sta $e100+1,x
		sta $e100+2,x
		sta $e100+3,x
		sta $e100+4,x
		sta $e100+5,x
		sta $e100+6,x
		sta $e100+7,x
		eor #$ff
		sta $e900+0,x
		sta $e900+1,x
		sta $e900+2,x
		sta $e900+3,x
		sta $e900+4,x
		sta $e900+5,x
		sta $e900+6,x
		sta $e900+7,x
		txa
		sbx #-8
		cpx #$40
		bne a_sz_zoomb
		; copy adress again to place 1
		sty a_y + 1
		lda a_sz_zoomb+2
		sta a_sz_zoom+2
		rts
!if(sprites){
; todo tab verschieben vor spritepointer in screens
spr_0_x		!by xm-16,xm-16,xm-16,xm-16,xm-16,xm-16,xm-16,xm-16
spr_0_y		!by ym-15,ym-5+11-8,ym-8,ym-8,ym-$10+8-2,ym-15,ym-15,ym-15
spr_1_x		!by xm,xm-8,xm,xm,xm,xm,xm,xm
spr_1_y		!by ym-24+9,ym-16,ym-16,ym-16,ym-16,ym-24+9,ym-24+9,ym-24+9
spr_2_x		!by xm,xm+8,xm+8,xm+8,xm+8,xm,xm,xm
spr_2_y		!by ym+1,ym+5-16-3+6,ym-3,ym-3,ym-3-3+4,ym+1,ym+1,ym+1
spr_3_x		!by xm-16,xm,xm-8,xm-8,xm-8,xm-16,xm-16,xm-16
spr_3_y		!by ym+1,ym+5,ym+5,ym+5,ym+5,ym+1,ym+1,ym+1
}
next_a		ldy #$e0	; set bit pattern in charset (first 40 chars)
		sty bmp_pointer+1
		ldy #$00
		sty bmp_pointer+0
		sta col
		
looprowb	lda col
		sta cnt4
		clc
		ldx #$08
		
looprow		bcs c_set
		; c=0
		lsr cnt4
		bcc +
-		eor #$ff
+ 		jmp nextrow		
c_set		; c=1
		lsr cnt4
		bcc -
nextrow		sta (bmp_pointer),y
		iny
		dex
		bne looprow
		cpy #$00
		bne looprowb
		
		inc bmp_pointer+1
		
looprowb2	lda col
		sta cnt4
		clc
		ldx #$08
		
looprow2	bcs c_set2
		; c=0
		lsr cnt4
		bcc +
-		eor #$ff
+ 		jmp nextrow2		
c_set2		; c=1
		lsr cnt4
		bcc -
nextrow2	sta (bmp_pointer),y
		iny
		dex
		bne looprow2
		cpy #$40
		bne looprowb2	
		
		;jmp doshift
		rts


shiftcolram	
		jsr speedcode
		jsr speedcode+$0800*1
		jsr speedcode+$0800*2
		jsr speedcode+$0800*3	
		; jsr new_column
		; besser in teilen schon im speedcode? - dabei auf spritedaten aufpassen!
!for x,0,38 	{
		ldx $d800+24*$28+x+1
		stx $d800+24*$28+x
		}
		ldx coltmp+24
		stx $d800+24*$28+39
		rts

prepare_column39		
new_column	ldy #00
		ldx cntcol
		lda colcol
-
		dex
		beq newcol
lpcol
		sta coltmp,y
		iny
		cpy #25
		bne -
		stx cntcol
		rts
		
newcol		inc ldacol+1
		bne ldacol
		inc ldacol+2
ldacol		lda cr_scrolldata-1
		sta colcol
		lsr
		lsr
		lsr
		lsr
		tax
		inx
		lda colcol
		jmp lpcol

!align 255, 0
adrtab
!fill 4,$04
!fill 4,$05
!fill 4,$06
!fill 4,$07

coltab	!by	$77,$99,$88,$dd ; vortex colors
;coltab	!by	$ee,$66,$55,$44
;coltab	!by	$11,$cc,$bb,$ff

varspace
!fill $0f,00
eof
;!warn(eof)
