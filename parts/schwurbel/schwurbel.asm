use_sprites	= 1
!ifdef release {
                !src "../../bitfire/loader/loader_acme.inc"
                !src "../../bitfire/macros/link_macros_acme.inc"
}
!ifndef release {
         *= $0801
        !by $0b,$08,$00,$00,$9e,$32,$30,$36,$31,$00,$00,$00
	jmp start
}

        !cpu 6510

	!macro check_same_page_start {
	!set page_check_page_addr = * & $ff00
	} 

	!macro check_same_page_end {
	!if (page_check_page_addr != ( * & $ff00)) {
		!error "not the same page"
	}
	}

	!macro asr {
	cmp #$80
	ror
	}

	!macro align16 {
		* = (*+$f) & $fff0
	}

	!macro align256 {
		* = (*+$ff) & $ff00
	}

        !macro align256WithLeaks {
            +align256
            !if ((* & $7ff) < $400) {
                * = (*+$400)
            }
            !if ((* & $3fff) >= $3c00) {
                * = (*+$800)
            }
            !if (* = $9400) {
                * = $a400
            }
        }

	!macro align512 {
		* = (*+$1ff) & $fe00
	}

        !macro sprite_line .x {
        !byte ^.x, >.x, <.x
        }

* = $3c00
!ifdef use_sprites {
sprdat
P = (* / 64) + 0
R = (* / 64) + 1
O = (* / 64) + 2
F = (* / 64) + 3
I = (* / 64) + 4
S = (* / 64) + 5
M = (* / 64) + 6
A = (* / 64) + 7
C = (* / 64) + 8
H = (* / 64) + 9
E = (* / 64) + 10
N = (* / 64) + 11
D = (* / 64) + 12
_ = (* / 64) + 13

!bin "profis.spr"
!fill 64,0
} else {

P = * / 64
        +sprite_line %###################.....
        +sprite_line %#####################...
        +sprite_line %####..............####..
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####..............####..
        +sprite_line %#####################...
        +sprite_line %###################.....
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        !byte 0

R = * / 64
        +sprite_line %###################.....
        +sprite_line %#####################...
        +sprite_line %####..............####..
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####..............####..
        +sprite_line %#####################...
        +sprite_line %###################.....
        +sprite_line %########................
        +sprite_line %####.####...............
        +sprite_line %####...####.............
        +sprite_line %####.....####...........
        +sprite_line %####........####........
        +sprite_line %####..........####......
        +sprite_line %####............####....
        +sprite_line %####..............####..
        +sprite_line %####................#### 
        !byte 0

O = * / 64
        +sprite_line %.....##############.....
        +sprite_line %...##################...
        +sprite_line %.####..............####.
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %.####..............####.
        +sprite_line %...##################...
        +sprite_line %.....##############.....
        !byte 0

F = * / 64
        +sprite_line %########################
        +sprite_line %########################
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %###############.........
        +sprite_line %###############.........
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        !byte 0

I = * / 64
        +sprite_line %.......##########.......
        +sprite_line %........########........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %..........####..........
        +sprite_line %........########........
        +sprite_line %.......##########.......
        !byte 0

S = * / 64
        +sprite_line %........########........
        +sprite_line %......############......
        +sprite_line %....####........####....
        +sprite_line %...####...........####..
        +sprite_line %..####.............####.
        +sprite_line %.####...................
        +sprite_line %.####...................
        +sprite_line %.####...................
        +sprite_line %...####.................
        +sprite_line %.....####...............
        +sprite_line %.......##########.......
        +sprite_line %.........#########......
        +sprite_line %................####....
        +sprite_line %..................####..
        +sprite_line %..####..............####
        +sprite_line %..####..............####
        +sprite_line %..####..............####
        +sprite_line %..####..............####
        +sprite_line %...####...........####..
        +sprite_line %.....####.......####....
        +sprite_line %.......###########......
        !byte 0

M = * / 64
        +sprite_line %####................####
        +sprite_line %#####..............#####
        +sprite_line %######............######
        +sprite_line %########.........#######
        +sprite_line %####.####......####.####
        +sprite_line %####..####....####..####
        +sprite_line %####...####..####...####
        +sprite_line %####....########....####
        +sprite_line %####.....######.....####
        +sprite_line %####......####......####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        !byte 0

A = * / 64
        +sprite_line %........########........
        +sprite_line %.......##########.......
        +sprite_line %......####....####......
        +sprite_line %.....####......####.....
        +sprite_line %....####........####....
        +sprite_line %...####..........####...
        +sprite_line %..####............####..
        +sprite_line %.####..............####.
        +sprite_line %####................####
        +sprite_line %########################
        +sprite_line %########################
        +sprite_line %########################
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        !byte 0

C = * / 64
        +sprite_line %.....##############.....
        +sprite_line %...##################...
        +sprite_line %.####..............####.
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %.####..............####.
        +sprite_line %...##################...
        +sprite_line %.....##############.....
        !byte 0

H = * / 64
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %########################
        +sprite_line %########################
        +sprite_line %########################
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        !byte 0

E = * / 64
        +sprite_line %########################
        +sprite_line %########################
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %###############.........
        +sprite_line %###############.........
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %####....................
        +sprite_line %########################
        +sprite_line %########################
        !byte 0

N = * / 64
        +sprite_line %####................####
        +sprite_line %#####...............####
        +sprite_line %######..............####
        +sprite_line %########............####
        +sprite_line %####.####...........####
        +sprite_line %####..####..........####
        +sprite_line %####...####.........####
        +sprite_line %####....####........####
        +sprite_line %####.....####.......####
        +sprite_line %####......####......####
        +sprite_line %####.......####.....####
        +sprite_line %####........####....####
        +sprite_line %####.........####...####
        +sprite_line %####..........####..####
        +sprite_line %####...........####.####
        +sprite_line %####............########
        +sprite_line %####.............#######
        +sprite_line %####..............######
        +sprite_line %####...............#####
        +sprite_line %####................####
        +sprite_line %####................####
        !byte 0


D = * / 64
        +sprite_line %###################.....
        +sprite_line %####################....
        +sprite_line %####.............####...
        +sprite_line %####..............####..
        +sprite_line %####...............####.
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................####
        +sprite_line %####................###.
        +sprite_line %####...............####.
        +sprite_line %####..............####..
        +sprite_line %####.............####...
        +sprite_line %####################....
        +sprite_line %###################.....
        !byte 0

_ = * / 64
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        +sprite_line %........................
        !byte 0
}

        * = $3400
        +align256
sintab3:
        !bin "sintab3"
        !bin "sintab3"
sintab2:
        !bin "sintab2"
sintab1:
        !bin "sintab"
        !bin "sintab"

copy500:
        ldx #$00
-       lda code0500,x
        sta $0500,x
        lda code0500+$100,x
        sta $0600,x
        inx
        bne -
        jmp verteilpic

code0500:
        !pseudopc $0500 {
fadein:
        jsr do_fadein
        jsr do_fadein
        jsr do_fadein
do_fadein: 
fadein_offset = *+1       
        ldx #$00
        lda tablelow,x
        sta fadein_ptr
        sta fadein_ptr2
        lda tablehigh,x
        sta fadein_ptr+1
        sta fadein_ptr2+1
fadein_ptr = *+1
        lda $fff9
        and #$1f
fadein_ptr2 = *+1
        sta $fff9
        inx
        stx fadein_offset
        cpx #$c0
        bne +
        lda #$2c
        sta fadeinptr 
+       rts     

fadeout:
        jsr do_fadeout
do_fadeout:
fadeout_offset = *+1
        ldx #$00
        lda tablelow,x
        sta fadeout_ptr
        sta fadeout_ptr2
        lda tablehigh,x
        sta fadeout_ptr+1
        sta fadeout_ptr2+1
fadeout_ptr = *+1
        lda $fff9
        ora #$60
fadeout_ptr2 = *+1
        sta $fff9
fadeout_inx:
        inx
        inx
        stx fadein_offset
        cpx #$c0
        bne +
        dex
        lda #$ca
        sta fadeout_inx
        sta fadeout_inx+1
+
        cpx #$ff
        bne +
        inc readyflag
        rts
+       stx fadeout_offset
        rts

        ; hier platz fuer den faker
                
tablelow:
        !fill 192,$f9
tablehigh:
        !fill 192,$ff

        !if * > $07ff {
            !error no space left
        }
        }
tablecopylow = * -$c0-$c0
tablecopyhigh = * - $c0

        
!ifndef release {
        * = $1000
        !bin "Negative_Karma.sid",,126
}
        
gfx_hardware_table = $9100
gfx_table = $08

d016tab = $9200
agsptab = $9400

spr_yoff_low = $0700

	* = $4400
	+align256
        jmp start
init_stable_timer:
        lda $d012
        bne init_stable_timer
        lda $d011
        bmi init_stable_timer

	; make a stable timer on CIA A
	; this is needed for stable interrupts
	; must be done only once at start

	; no interrupts please in this function !
	; reset timer
        lda #$7f
        sta $dc0d
        lda $dc0d
        lda #%00000000
        sta $dc0f
        lda #%10000000
        sta $dc0e
	; 63 to zero because of 63 cycles per line
        lda #<(63-1)
        sta $dc04
        lda #>(63-1)
        sta $dc05
	; but not start it yet !

	+check_same_page_start
	lda $d012
-	cmp $d012
	beq -
	lda (00,x)
        ldy #%10000001
again:
	;make a loop with 62 cycles
	ldx #10   ; 2
-	dex	  ; 2
	bne -     ; 3 (last one 2) -> 2+(10*5)-1
	lda $d012 ; 4
	;if the compare is not equal the first time, we are in sync with VIC !
-	cmp $d012 ; 4
	beq again ; 3 -> 4+4+3 + (2+(10*5)-1) = 62 (63-1 !)
        
        ldx #10
-       dex
        bne -
        nop
	; start the timer now
        sty $dc0e
	+check_same_page_end
	rts


start:
!ifndef release {
        lxa #$00
        jsr $1000
} else {
	+bus_lock
}
        ldx #$07
-       lda $03f8,x
        sta save_space,x
        dex
        bpl -
        jsr copy500 ;jsr verteilpic
       	jsr init_stable_timer

        ldx #$00
        ldy #$00
        sty $02
-       lda table_for_line_select,x
        sta gfx_hardware_table,y
        !for i,1,2 {
        lda $02
        clc
        adc #table_for_line_select_len*3
        sta $02
        bcc +
        inx
        cpx #table_for_line_select_len
        bne +
        ldx #$00
+
        }
        iny
        bne -
        
        ldx #$00
--      txa
        sta gfx_table,x
        inx
        cpx #192
        bne --


        ldx #$00
        lda #$00
-       asl
        clc
        adc #80
        sta $d000,x
        sec
        sbc #80
        lsr
        adc #$30
        sta $d001,x
        sec
        sbc #$30
        clc
        adc #19
        inx
        inx
        cpx #$0c
        bne -
        lda #$20
        sta $d010
        ldx #$02
        ldy #$04
-
src = *+2
        lda $3bfe,x
dst1 = *+2
        sta $7bfe,x
dst2 = *+2
        sta $bbfe,x
dst3 = *+2
        sta $fbfe,x
        inx
        bne -
        inc src
        inc dst1
        inc dst2
        inc dst3
        dey
        bne -

        lda #$7f
        sta $dc0d
        lda $dc0d
	;lda #$08
	;sta $d011
	lda #$03
	sta $dd00
	lda #$10
	sta $d018
	ldx #$00
	ldy #$40
-	tya
	sta $0400,x
	sta $0440,x
	iny
	inx
	cpx #$40
	bne -

        ldx #$27
-
;       txa
;        and #$03
;        tay
;        lda coltab,y
        lda #$0c
        sta $d800,x
        ;lda #$02
        sta $d828,x
        dex
        bpl -

        ldx #$05
        lda #$00
-       sta spr_yoff_low,x
        dex
        bpl -

	lda #$00
-	cmp $d012
	bne -

        ldx #$00
        ldy #$00
        lda #$d7
-       sta d016tab,x
        pha
        tya
        ora #$40
        sta agsptab,x
        pla
        sec
        sbc #$01
        cmp #$cf
        bne +
        iny
        lda #$d7
+       inx
        bne -

	lda #$00
        sta $d020
	lda #$00
        sta $d021
        lda #$00
        sta $d022
	lda #$08
	sta $d011
  	!ifdef RELEASE {
        lda #$4c
        sta PLAY_MUSIC                       
	}
-       lda $d011
        bpl -
        sei
        ldx #$05
-       lda #$0d
        sta $d027,x
        lda #_
        sta $03f8,x
        sta $07f8,x
        sta $43f8,x
        sta $83f8,x
        sta $c3f8,x
        sta $c7f8,x
        dex
        bpl -
	lda #$00
	sta $d025
	lda #$05
	sta $d026
        lda #$2f
        sta $d012
        lda #<irq
        sta $fffe
        lda #>irq
        sta $ffff
        lda #$81
        sta $d01a
        sta $d019
        lda #$ff
        sta $39ff
	sta $d01c
;	lda $3fff
;	sta old_3fff+1
 	cli
-	
readyflag = *+1
        lda #$00
        cmp #$08
        bcc -

        ldx #$07
-       
        lda save_space,x
        sta $03f8,x
        dex
        bpl -

end:
        ;----> here the part stops
!ifndef release {
	jmp *
} else {
	ldx #$7f
-
	lda .stack,x
	sta $0100,x
	dex
	bpl -
	jmp $0100
.stack
	sei
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	sta $dd0d
	+bus_unlock
	lda #$fe
-
	cmp $d012
	bne -

	ldx #<link_player
	lda #>link_player

	stx $fffe
	sta $ffff
	lda #$ff
	sta $d012
        cli
	;jsr link_music_play

	+setup_sync $68
	jsr link_load_next_comp
	+sync
	jmp link_exit
}

save_space:
        !byte 0,0,0,0,0,0,0,0

coltab:
        !byte    $07,$05,$0e,$0d

text:
        !byte _,_,_,_,_,_
        !byte _,_,_,_,_,_
        !byte P,R,O,F,I,S
        !byte M,A,C,H,E,N
        !byte D,A,S,_,S,O
        !byte _,_,_,_,_,_
        !byte 0
        
text_index: !byte 0

        !set OFFSET = 0

	+align256
	; avoid page cross !
irq:    sta irq_old_a+1
        stx irq_old_x+1
        lda #$78
        sta $d011
	lda #$25
        sec
        sbc $dc04
	sta bpl_addr2+1
bpl_addr2:
	bpl bpl_addr2

	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	bit $ea
        ;stable here
	sty irq_old_y+1
        
	;lda $f7
	;sta $f2	; old_f7
d016value = *+1
        lda #$d7
	sta $d016
        lda #$15
        sta $d018
	lda #$79
	sta $d011
        lda (00,x)
        lda (00,x)
        lda (00,x)
        lda (00,x)
        lda #$05
        sta $d018

        ldx #$05
-
        lda d016value
        and #$ef
        sta $d016

        lda #$26
        sec
        sbc $dc04
        sta + +1
+
        bpl +
+
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	bit $ea
        dex
        bne -

        lda #$31
        sec
        sbc $dc04
        sta + +1
+
        bpl +
+
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	bit $ea
        
        ldy gfx_table
        lda gfx_hardware_table,y ; 4
        tay
        lsr                         ; 2
        ldx #$0e
        sty $dd00                   ; 4
        sax $d018                   ; 4
        and #$40                    ; 2 
        
	!for i,1,191 {
        !if i = 191 {
	ora #$78 + ((i) & 7)
        } else {
        !set OLD_PC = *
        * = OFFSET + tablecopylow
        !byte <(OLD_PC+1)
        * = OFFSET + tablecopyhigh
        !byte >(OLD_PC+1)
        !set OFFSET = OFFSET + 1
        * =OLD_PC
	ora #$78 + ((i) & 7) ;ora #$18 + ((i) & 7)
        }
	sta $d011

        ldy gfx_table+i

        lda #$32
        sec
        sbc $dc04
        sta + +1
+
        bpl +
+
        !byte $c9
	cmp #$c9
	cmp #$c9
	cmp #$c9
	bit $ea

	!if ((* & 0xff) < 0xc0) {
	bit $ea
	} else {
	jmp +
	+align256WithLeaks
+
	}
        ;lda #$00
        ;sta $d03f
        !if (i=40) {
        ;lda #$00
        ;sta $d01b
        lda (00,x)
        } else {
        !if (i=1) {
disable_sprites_forever = *+1
        lda #$3f
        sta $d015 
        } else {
        lda (00,x)
        }
        }
        
        lda gfx_hardware_table,y ; 4
        tay
        lsr                         ; 2
        ldx #$0e
        sty $dd00                   ; 4
        sax $d018                   ; 4
        and #$40                    ; 2 
	}
	inc $d019
        cli
        lda #$03
        sta $dd00
        lda #$05
        sta $d018
        lda #$73+$80
        sta $d011
        lda #$37-21-23
        sta $d012
        lda #<irq2
        sta $fffe
        lda #>irq2
        sta $ffff
        
        lda #$00
        sta $05
        dec $06
	!if ((* & 0xff) < 0xc0) {
	nop
	nop
	nop
	} else {
	bit $ea
	jmp +
	+align256WithLeaks
+
	}
        
sintab2offset = *+1
        ldx sintab2
        lda d016tab,x
	sta d016value
        lda agsptab,x
        sta xhigh_coord
        inc sintab2offset
sinoffset2 = *+1
        lda #$00
        clc
        adc #$40
        sta sinoffset2
        bcc +
        dec sintab2offset
+
        lda #$03
        sta $dd00
        lda #$00
        sta $d018
!ifdef release {
	jsr link_music_play_side3b
} else {
        jsr $1003
}
        
xhigh_coord = *+1
        ldx #$00
        !for i,0,38 {
        stx $0400+i
        inx
        }
        stx $0400+39
        
point = *+1
        ldy #$00
        anc #0
adjust_value1 = *+1
        ldx #96+85
-       sty gfx_table-1,x
sinbase = *+1
        adc sintab3,x
        bcc +
        clc
        dey
+       dex
        bne -

        ldy point
        lxa #0
-       
sinbase2 = *+1
        adc sintab3,x
        bcc +
        clc
        dey
+       inx
adjust_value2 = *+1
        sty gfx_table+96+85-1,x
adjust_value3 = *+1
        cpx #96-85
        bne -

;sinbase = *+1
;        ldx #$00
;        !for i,0,191 {
;-       
;        sty gfx_table+i
;        adc sintab3,x
;        bcc +
;        iny
;+       inx
;	!if ((* & 0x3ff) < 0x3f0) {
;	} else {
;	jmp +
;	+align256WithLeaks
;+
;	}
;        }

	jmp +
	+align256WithLeaks
+
        
        ;inc $d020
sintabpoint = *+1
        lda sintab1
        sta point
        inc sintabpoint
        inc sinbase
        inc sinbase2
        
        inc time_value
time_value = *+1
        lda #$00
        and #$3f
        bne +
        lda directon
        eor #$01
        sta directon
+
directon = *+1
        lda #$00
        beq +
        inc adjust_value1
        inc adjust_value2
        dec adjust_value3
        jmp ++
        ;dec $d020
+
        dec adjust_value1
        dec adjust_value2
        inc adjust_value3
++        
irq_old_y:
	ldy #$00
irq_old_a:
	lda #$00
irq_old_x:
	ldx #$00
rti_addr:
        rti

        +align256WithLeaks
        
irq2:
        sta oldirq2_a
        stx oldirq2_x
        lda #$15
        sta $d018
        lda #$00
        sta $dd00
        ;lda #$00
        ;sta $d015
        lda #<irq3
        sta $fffe
        lda #>irq3
        sta $ffff
        lda #$7b
        sta $d011
        lda #$20
        sta $d012
        inc $d019
        ;lda #$ff
        ;sta $d01b

upoffset = *+1
        ldx #$00
        clc
        !for i,0,5 {
        lda $d001+i*2
        sta $03
        lda spr_yoff_low+i
        adc sintab1+$20*i,x
        bcc +
        dec $d001+i*2
        clc
+       adc sintab1+$20*i+1,x
        bcc +
        dec $d001+i*2
        clc
+       
        sta spr_yoff_low+i
        lda $d001+i*2
        and #$fe
        cmp #$08
        bne +
        lda $03
        and #$fe
        cmp #$08
        beq +
        ldx text_index
        lda text,x
        sta $03f8+i
        sta $07f8+i
        sta $43f8+i
        sta $83f8+i
        sta $c3f8+i
        inx
        lda text,x
        bne ++
        ldx #$00
        stx disable_sprites_forever
++      stx text_index
+       clc

	!if ((* & 0x3ff) < 0x3e0) {
	} else {
	jmp +
	+align256WithLeaks
+
        }
        }
        inc upoffset
        inc upoffset
        lda disable_sprites_forever
        bne +
        jsr fadeout
        ;inc readyflag
+
fadeinptr:
        jsr fadein
oldirq2_x = *+1
        ldx #$00
oldirq2_a = *+1
        lda #$00
        rti

irq3:
        pha
        lda #<irq
        sta $fffe
        lda #>irq
        sta $ffff
        lda #$2f
        sta $d012
        lda #$15
        sta $d018
        lda #$03
        sta $dd00
        inc $d019
        pla
        rti

	* = $9000

table_for_line_select:
        ;!byte $83
        ;!byte $03
        ;!byte $87
        ;!byte $07
        !byte $93
        !byte $13
        !byte $97
        !byte $17
        !byte $9b
        !byte $1b
        !byte $9f
        !byte $1f
        !byte $82
        !byte $02
        !byte $86
        !byte $06
        !byte $8a
        !byte $0a
        !byte $8e
        !byte $0e
        !byte $92
        !byte $12
        !byte $96
        !byte $16
        !byte $9a
        !byte $1a
        !byte $9e
        !byte $1e
        !byte $81
        !byte $01
        !byte $85
        !byte $05
        !byte $91
        !byte $11
        !byte $95
        !byte $15
        !byte $99
        !byte $19
        !byte $9d
        !byte $1d
        !byte $80
        !byte $00
        !byte $84
        !byte $04
        !byte $88
        !byte $08
        !byte $8c
        !byte $0c
        !byte $90
        !byte $10
        !byte $94
        !byte $14
        !byte $98
        !byte $18
        !byte $9c
        !byte $1c        
table_for_line_select_len = * - table_for_line_select

table_for_address_highbytes:
        ;!byte $00
        ;!byte $02
        ;!byte $08
        ;!byte $0a
        !byte $20
        !byte $22
        !byte $28
        !byte $2a
        !byte $30
        !byte $32
        !byte $38
        !byte $3a
        !byte $40
        !byte $42
        !byte $48
        !byte $4a
        !byte $50
        !byte $52
        !byte $58
        !byte $5a
        !byte $60
        !byte $62
        !byte $68
        !byte $6a
        !byte $70
        !byte $72
        !byte $78
        !byte $7a
        !byte $80
        !byte $82
        !byte $88
        !byte $8a
        !byte $a0
        !byte $a2
        !byte $a8
        !byte $aa
        !byte $b0
        !byte $b2
        !byte $b8
        !byte $ba
        !byte $c0
        !byte $c2
        !byte $c8
        !byte $ca
        !byte $d0
        !byte $d2
        !byte $d8
        !byte $da
        !byte $e0
        !byte $e2
        !byte $e8
        !byte $ea
        !byte $f0
        !byte $f2
        !byte $f8
        !byte $fa
        !if ((* - table_for_address_highbytes) != table_for_line_select_len) {
            !error "wrong size"
        }

picraw:
        !bin "pic.raw"
verteilpic:
        lda #$34
        sta $01
        lda #<picraw
        sta $04
        lda #>picraw
        sta $05
        lda #$00
        sta $06
--      ldx $06        
        lda table_for_address_highbytes,x
        sta $03
        lda #$07
        sta $02
        ldy #$00
-       lda ($04),y
        sta ($02),y
        lda $02
        clc
        adc #$07
        sta $02
        bcc +
        inc $03
+       iny
        cpy #64
        bne -
        tya
        clc
        adc $04
        sta $04
        bcc +
        inc $05
+
        inc $06
        lda $06
        cmp #table_for_line_select_len
        bne --
        
        !if 0 {
        lda #$00
        sta $04
        lda #$02
        sta $05
        ldy #$16
        ldx #40
-       lda #$ff
        sta ($04),y
        tya
        clc
        adc #$08
        tay
        bcc +
        inc $05
+       dex
        bne -
        }
        lda #$35
        sta $01
        rts

