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

LINE = 0
BG_COL		= $0f
SPR_COL1	= $01
SPR_COL2	= $02
SPR_COL3	= $00

;DEBUG = 1

buffer = $1c
joblist_pointer = $18
;joblist2_pointer = $1a
spr_pointer =$16
spr_xcounter = $15
spr_dst_counter = $14
spr_ycounter = spr_dst_counter
spr_y_high = $13
spr_y = $12
sprite_to_clear = $11
screen_addr = $0f

scroll_down_table = $7e00

MAX_HEIGHT = 137
MAX_HEIGHT_ROUNDED = 21+19+19+19+19+19+19+19

BASE_ZP = $02
BASE_ZP2 = $08

MASK_TAB = $fe00

actual_screen = $0e

MAIN_IRQ_LINE = 312-35

COPY_CODE_BASE = buffer + MAX_HEIGHT_ROUNDED + 6
irq_jmp = COPY_CODE_BASE-6
irq_jmp2 = irq_jmp+3
 
	!macro check_same_page_start {
	!set page_check_page_addr = * & $ff00
	}

	!macro check_same_page_end {
	!if (page_check_page_addr != ( * & $ff00)) {
		!error "not the same page"
	}
	}

        !MACRO align256 {
        !for i,1,256 {
                !if (* & $ff) <> 0 {
                    nop
                }
            }
        }

        !macro bmi .x {
        bpl +
        jmp .x
+
        }

        !macro bpl .x {
        bmi +
        jmp .x
+
        }

        !macro bcs .x {
        bcc +
        jmp .x
+
        }

        * = $8000        
start:
        sei
!ifndef release {
        lxa #$00
        sta $d021
        jsr $1000
} else {
	;+bus_lock
}
        lda #<snd_irq
        sta $fffe
        lda #>snd_irq
        sta $ffff
        lda #$ff
        sta $d012
        lda $d011
        and #$7f
        sta $d011
        lda #$7f
        sta $dc0d
        lda $dc0d
        inc $d019
        lda #$81
        sta $d01a
        lda #$35
        sta $01
        cli
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
        sta $dd0d
        sta $dc0d
        ldx #$ff
        lda $dc0d+1,x
        lda #%00000000
        sta $dd0f
        lda #%10000000
        sta $dd0e
	; 63 to zero because of 63 cycles per line
        lda #<(63-1)
        sta $dd04
        lda #>(63-1)
        sta $dd05
	; but not start it yet !

	+check_same_page_start
	lda $d012
-	cmp $d012
	beq -
	nop
	nop
	nop
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
	; start the timer now
        ldx #$06
-       dex
        bne -
        bit $ea
        sty $dd0e
	+check_same_page_end
        lda #$ff
        sta $dd06
        sta $dd07
        lda #%00010000
        sta $dd0f
	jmp start_

GENERATED = 1

    !ifndef GENERATED {
generated_code = $2500

        A = 0
        B = A + 21
        C = B + 19
        D = C + 19
        E = D + 19
        F = E + 19
        G = F + 19
        H = G + 19
        I = H + 19
        J = I + 19
        K = J + 19
        
converttab:
        !macro a .x {
        !byte A+.x -1 
        }
        !macro b .x {
        !byte B+.x -1 
        }
        !macro c .x {
        !byte C+.x -1 
        }
        !macro d .x {
        !byte D+.x -1 
        }
        !macro e .x {
        !byte E+.x -1 
        }
        !macro f .x {
        !byte F+.x -1 
        }
        !macro g .x {
        !byte G+.x -1 
        }
        !macro h .x {
        !byte H+.x -1 
        }
        !macro i .x {
        !byte I+.x -1 
        }
        !macro j .x {
        !byte J+.x -1 
        }
        !macro k .x {
        !byte K+.x -1 
        }


        !for i,1,21 {
        +a i
        }

        !for i,1,19 {
        +b i
        }
        +a 20
        +a 21

        !for i,3,19 {
        +c i
        }
        +b 18
        +b 19
        !for i,1,2 {
        +c i
        }

        !for i,5,19 {
        +d i
        }
        +c 18
        +c 19
        !for i,1,4 {
        +d i
        }
        
        !for i,7,19 {
        +e i
        }
        +d 18
        +d 19
        !for i,1,6 {
        +e i
        }
        
        !for i,9,19 {
        +f i
        }
        +e 18
        +e 19
        !for i,1,8 {
        +f i
        }

        !for i,11,19 {
        +g i
        }
        +f 18
        +f 19
        !for i,1,10 {
        +g i
        }
        
        !for i,13,19 {
        +h i
        }
        +g 18
        +g 19
        !for i,1,12 {
        +h i
        }

        !for i,15,19 {
        +i i
        }
        +h 18
        +h 19
        !for i,1,14 {
        +i i
        }

        !for i,17,19 {
        +j i
        }
        +i 18
        +i 19
        !for i,1,16 {
        +j i
        }

        !byte $fe
        +j 18
        +j 19
        !for i,1,18 {
        +k i
        }
        
        !byte $ff

offsetlow:
        !for j,0,11 {
        !for i,0,20 {
        !byte < (i*3 + j * 64)
        }
        }
NUMBER_OF_LINES = *-offsetlow

offsethigh:
        !for j,0,11 {
        !for i,0,20 {
        !byte > (i*3 + j * 64)
        }
        }

codegen:
        lda #<buffer
        sta $02
        lda #$00
        sta $03
--      lda #$a5
        jsr codestore
        lda $02
        jsr codestore
        
        ldy #$00
-       lda converttab,y
        cmp $03
        bne +
        
        lda #$a0
        jsr codestore
        lda offsetlow,y
        jsr codestore
        lda #$91
        jsr codestore
        lda offsethigh,y
        asl
        clc
        adc #BASE_ZP
        jsr codestore
        lda #$91
        jsr codestore
        lda offsethigh,y
        asl
        clc
        adc #BASE_ZP2
        jsr codestore
        
        
+       iny
        cmp #$ff
        bne -
                
        inc $02
        inc $03
        lda $03
        cmp #MAX_HEIGHT_ROUNDED
        bne --
        lda #$60
codestore:
        sta generated_code
        inc codestore+1
        bne +
        inc codestore+2
+       rts
    } else {
generated_code:
        !bin "generated",,2
    }
 
              
snd_irq:
        pha
        txa
        pha
        tya
        pha
        lda $01
        pha
        lda #$35
        sta $01
!ifdef release {
	jsr link_music_play_side1
} else {
        jsr $1003
}
        inc $d019
        pla
        sta $01
        pla
        tay
        pla
        tax
        pla
        rti        

        
start_:
-       lda $d011
        bpl -
        lda $d012
        bne - 
!ifndef release {
        lda #LINE+$08
        sta $d011
}
        lda #BG_COL
        sta $d020        
        lda #<joblist
        sta joblist_pointer
        lda #>joblist
        sta joblist_pointer+1
    !ifndef GENERATED {
        jsr codegen
    }
        ldx #$00
-
        lda #SPR_COL1 << 4 | SPR_COL3
        sta $6000,x
        sta $6100,x
        sta $6200,x
        sta $6300,x
        sta $e000,x
        sta $e100,x
        sta $e200,x
        sta $e300,x
        lda #$00
        sta $e400,x
        sta $e500,x
        sta $e600,x
        sta $e700,x
        sta $e800,x
        sta $e900,x
        sta $ea00,x
        sta $eb00,x
        sta $ec00,x
        sta $ed00,x
        sta $ee00,x
        sta $ef00,x
        sta $f000,x
        sta $f100,x
        sta $f200,x
        sta $f300,x
        sta $f400,x
        sta $f500,x
        
        sta $2000,x
        sta $2100,x
        sta $2200,x
        sta $2300,x
        
        inx
        bne -
        
        jsr init_masktab
            
        ldx #$07
        lda #$2380/64
-       sta $23f8,x
        dex
        bpl -

        ldx #copy_code_len
-       lda copy_code-1,x
        sta COPY_CODE_BASE-1,x
        dex
        bne -
                
        !for i,0,7 {
        lda #$90+i*9
        sta $63f8+i
        }
        ldx #$07
        lda #$00;SPR_COL3
-       sta $d027,x
        dex
        bpl -
        lda #$05
        sta $d025
        lda #$0a
        sta $d026
        
-       lda $d011
        bpl -
        lda $d012
        bne - 
        lda #BG_COL
        sta $d020        
        lda #$ff
        sta $d015
        sta $d01c
        lda #$02
        sta $dd00
        lda #$38+LINE+$80
        sta $d011
        lda #$d9
        sta $d016
        lda #$80
        sta $d018
        lda #BG_COL
        sta $d021
        ldx #$00
        lda #SPR_COL2
-       sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $db00,x
        inx
        bne -
        lda #$50
        ldy #$0a
        jsr set_color_tree
        sei
        lda #$4c
        sta <irq_jmp
        sta <irq_jmp2
        lda #YS
        sta spr_y
        lda #$01
        sta spr_y_high
        lda #<irq_main
        sta <irq_jmp+1
        sta <irq_jmp2+1
        lda #>irq_main
        sta <irq_jmp+2
        sta <irq_jmp2+2
        lda #<irq_jmp
        sta $fffe
        lda #>irq_jmp
        sta $ffff
        sta $7fff
        lda #<(MAIN_IRQ_LINE)
        sta $d012
        ;lda #$81
        ;sta $d01a
        ;inc $d019
        ;lda #$7f
        ;sta $dc0d
        ;lda $dc0d
        ;lda #$35
        ;sta $01
        ldx #$ff
        lda $dc0d+1,x
        jsr setup_nmi
        cli
        ldy #$00
        jsr copy_sprite_to_dest

big_jobcontrol:
        lda big_jobadress+1
        beq big_jobcontrol
big_jobadress = *+1
        jsr $0000
        lda #$00
        sta big_jobadress+1
        jmp big_jobcontrol

make_sprite_white:
        ldx #$07
        lda #SPR_COL3
-       sta $d027,x
        dex
        bpl -
        lda #SPR_COL1
        sta $d025
        lda #SPR_COL2
        sta $d026
        rts

joblist:
        ;bonsai
        !byte 1
        !word prepare_sprite_to_screen, nothing
        !byte 53    ; 80
        !word fall_down_init, fall_down ;sprite_move_up
        !byte 30
        !word bounce_init, fall_down
        !byte 1
        !word switch_sprite, nothing
        !byte 1       
        !word prepare_next_sprite, make_sprite_white
        !byte 30
        !word nothing, nothing

        ;size
        
        !byte 1
        !word prepare_sprite_to_screen, nothing
        !byte 52
        !word fall_down_init, fall_down
        !byte 30
        !word bounce_init, fall_down
        !byte 1
        !word switch_sprite, nothing
        !byte 16
        !word prepare_next_sprite, nothing

        ;matters

        !byte 1
        !word prepare_sprite_to_screen, nothing
        !byte 52
        !word fall_down_init, fall_down
        !byte 31
        !word bounce_init_with_flat_tree, fall_down
        !byte 1
        !word switch_sprite, set_color_tree_to_red
        !byte 1
        !word prepare_next_sprite, nothing

        ;next 
        
        !byte 41
        !word fall_down_init, fall_down
        !byte 36
        !word bounce_init, fall_down
        !byte 8+16+16
        !word move_down, nothing
        !byte 14
        !word copy_sprite_to_visible_screen, nothing
        !byte 1
        !word disable_sprite, nothing
        !byte 1
        !word prepare_next_sprite, nothing

        ;level
        
        !byte 45
        !word fall_down_init, fall_down
        !byte 36
        !word bounce_init, fall_down
        !byte 9+16+16
        !word move_down, nothing
        !byte 20
        !word copy_sprite_to_visible_screen, nothing
        !byte 1
        !word disable_sprite, nothing
        !byte 1
        !word prepare_next_sprite, nothing

        ; per
        
        !byte 42
        !word fall_down_init, fall_down
        !byte 34
        !word bounce_init, fall_down
        !byte 9+16+16
        !word move_down, nothing
        !byte 9
        !word copy_sprite_to_visible_screen, nothing
        !byte 1
        !word disable_sprite, nothing
        !byte 1
        !word prepare_next_sprite, nothing

        ;ers

        !byte 39
        !word fall_down_init, fall_down
        !byte 35
        !word bounce_init, fall_down
        !byte 9+16+16
        !word move_down, nothing
        !byte 13
        !word copy_sprite_to_visible_screen, nothing
        !byte 1
        !word disable_sprite, nothing
        !byte 1
        !word prepare_next_sprite, nothing

        ;form
        
        !byte 40
        !word fall_down_init, fall_down
        !byte 30
        !word bounce_init, fall_down
        !byte 16+16+16
        !word move_down, nothing
        
        
        !byte 255
        !word do_load_part_before_scroll,nothing
        !byte 32
        !word do_scroll_down_slow, nothing        
        !byte 16+16+32
        !word do_scroll_down_fast, nothing        
        !byte 32
        !word prepare_sprite_to_screen, scroll_to_3b
        ;!byte 16
        ;!word copy_sprite_to_visible_screen, nothing
        !byte 1
        ;!word disable_sprite, nothing
        !word switch_sprite, nothing
        !byte 1
        !word disable_sprite, nothing
        !byte 2
        !word prepare_gfx_for_end, nothing
        !byte 1
        !word do_end_part,nothing
                
falldown_table:
        !byte 140    ;x bonsai
        !byte $d6   ;$00    ;y (y_high = 1 !)
        !byte 0      ;not used
        !byte 12     ;x size
        !byte $6e    ;y (y_high = 1 !)
        !byte 0      ;scroll by bounce
        !byte 80     ;x matters
        !byte $8e    ;y (y_high = 1 !)
        !byte 0      ;scroll by bounce
        !byte 12     ;x next
        !byte $94    ;y (y_high = 1 !)
        !byte 32+16+16  ;scroll by bounce
        !byte 84     ;x level
        !byte $93    ;y (y_high = 1 !)
        !byte 32+16+16  ;scroll by bounce
        !byte 12     ;x per
        !byte $96    ;y (y_high = 1 !)
        !byte 32+16    ;scroll by bounce
        !byte 120    ;x ers
        !byte $91    ;y (y_high = 1 !)
        !byte 32+16   ;scroll by bounce
        !byte 52     ;x form
        !byte $7f    ;y (y_high = 1 !)
        !byte 0      ;scroll by bounce


scroll_to_3b:
scroll_to_3b_slowdown = *+1
        lda #$00
        clc
        adc #$01
        sta scroll_to_3b_slowdown
        and #$03
        bne +
        lda d011_val
        cmp #$13
        beq +
        clc
        adc #$01
        sta d011_val
        jsr do_clear_jmp
        inc spr_y
+       rts

schigger_tab:
        !byte $d8,$d9,$da,$d9,$d8,$d8,$d9,$d9,$da,$da,$d9
schigger_end = * - schigger_tab
        !byte $00


        ;%11011000
        ;%11011011

init_masktab:
        ldx #$00
--      lda #$00
        sta $02
        ldy #$04
        txa
-
        asl
        bcc upper_cleared
        rol $02
        asl
        rol $02
        jmp +
upper_cleared:
        asl
        bcs case_01
        sec
        rol $02
        sec
        rol $02
        jmp +
case_01:
        asl $02
        sec
        rol $02
+       dey
        bne -
        lda $02
        sta MASK_TAB,x
        inx
        bne --
        rts
        
       

schigger:
schigger_index = *+1
        ldx #schigger_end
        lda schigger_tab,x
        beq +
        sta $d016
        inx
        stx schigger_index
+       rts

small_job:
small_job_counter = *+1
        lda #$00
        beq small_next_job
        dec small_job_counter
small_jobaddress = *+1
        jmp nothing

small_next_job:
        ldy #$00
        lda (joblist_pointer),y
        beq nothing
        sta small_job_counter
        iny
        lda (joblist_pointer),y
        sta small_jobinit
        iny
        lda (joblist_pointer),y
        sta small_jobinit+1
        iny
        lda (joblist_pointer),y
        sta small_jobaddress
        iny
        lda (joblist_pointer),y
        sta small_jobaddress+1
        tya
        sec
        adc joblist_pointer
        sta joblist_pointer
        bcc +
        inc joblist_pointer+1
+
small_jobinit = *+1
       jsr $0000
       jmp small_job
        
        

move_down:
        inc move_down_flag
        rts

switch_bank:
        lda dd00_copy
        and #$03
        beq +
        lda #$00
        sta dd00_copy
        lda #<irq_jmp2
        sta $fffe
nothing:
        rts
+              
        lda #$02
        sta dd00_copy
        lda #<irq_jmp
        sta $fffe
        rts

do_scroll_down_fast:
        lda #32+16+16
        sta scroll_down_counter
        sta move_down_flag
        bne scrolldown_init

do_scroll_down_slow:
        lda #32
        sta scroll_down_counter
        sta move_down_flag

scrolldown_init:
        lda dd00_copy
        and #$03
        bne scroll_to_c0
        ldx #<scroll_screen_to_40
        ldy #>scroll_screen_to_40
        bne +
scroll_to_c0:
        ldx #<scroll_screen_to_c0
        ldy #>scroll_screen_to_c0
+       stx big_jobadress
        sty big_jobadress+1
        rts

scroll_down_exit_clear:
        sta move_down_flag
scroll_down_exit:
        rts


scroll_down_func:
scroll_down_counter = *+1
        lda #$00
        beq scroll_down_exit_clear
        dec scroll_down_counter
        cmp #32+1
        bcc scroll_down_slow
        jmp scroll_down

scroll_down_slow:
scroll_down_slowdown2 = *+1
        lda #$00
        clc
        adc #$01
        and #$03
        sta scroll_down_slowdown2
        beq do_scroll_down
        rts
        
scroll_down:

scroll_down_slowdown = *+1
        lda #$00
scroll_down_slowdown_disable = *+1
        eor #$01
        sta scroll_down_slowdown
        bne scroll_down_exit
do_scroll_down:
        lda d011_val
        and #$07
        bne +
+

move_down_flag = *+1
        lda #$00
        beq +
        inc spr_y
+
        lda d011_val
        clc
        adc #$01
        cmp #$18
        bne ++
        jsr switch_bank
        lda #$10
        sta d011_val
        lda scroll_down_counter
        cmp #32
        bcc +
        jmp scrolldown_init
+       rts
++
        sta d011_val
do_clear_jmp:
        and #$07
        asl
        asl
        tax
        lda dd00_copy
        and #$03
        bne +
        inx
        inx
+       lda clearcodetab,x
        sta clearcodejmp
        lda clearcodetab+1,x
        sta clearcodejmp+1
clearcodejmp = *+1
        jmp 0

clearcodetab:
        !word nothing,nothing
        !word clearline7_40,clearline7_c0
        !word clearline6_40,clearline6_c0
        !word clearline5_40,clearline5_c0
        !word clearline4_40,clearline4_c0
        !word clearline3_40,clearline3_c0
        !word clearline2_40,clearline2_c0
        !word clearline1_40,clearline1_c0

!macro clearline .addr {
        lda #$30
        sta $01
        lda #$00
        !for i,0,39 {
        sta .addr+8*i
        }
        lda #$35
        sta $01
        rts
}

CLR_LINE = 184

clearline7_40:
        +clearline $4000+CLR_LINE*40+7
clearline7_c0:
        +clearline $c000+CLR_LINE*40+7
clearline6_40:
        +clearline $4000+CLR_LINE*40+6
clearline6_c0:
        +clearline $c000+CLR_LINE*40+6
clearline5_40:
        +clearline $4000+CLR_LINE*40+5
clearline5_c0:
        +clearline $c000+CLR_LINE*40+5
clearline4_40:
        +clearline $4000+CLR_LINE*40+4
clearline4_c0:
        +clearline $c000+CLR_LINE*40+4
clearline3_40:
        +clearline $4000+CLR_LINE*40+3
clearline3_c0:
        +clearline $c000+CLR_LINE*40+3
clearline2_40:
        +clearline $4000+CLR_LINE*40+2
clearline2_c0:
        +clearline $c000+CLR_LINE*40+2
clearline1_40:
        +clearline $4000+CLR_LINE*40+1
clearline1_c0:
        +clearline $c000+CLR_LINE*40+1


fall_down_init:
fall_down_init_index = *+1
        ldx #00
        lda falldown_table,x
        sta $d000
        !for i,1,7 {        
        clc
        adc #24/2
        sta $d000+i*2
        }
        lda #$00
        !for i,0,7 {
        sec
        rol $d000+(7-i)*2
        rol
        }
        sta $d010
        
                
        lda falldown_table+1,x
        sta spr_y
        lda falldown_table+2,x
        sta bounce_scroll        
        ldx #$01
;        stx disable_highbit
        stx spr_y_high
        dex
        stx speed_y_low
        stx speed_y_high
        stx spr_y_low
        stx speed_y_high_high
        lax fall_down_init_index
        sbx #$100-3
        stx fall_down_init_index
        ;lda #$11
        ;sta accelerate
        rts

;sprite_move_up:
;        lda spr_y_low
;        sec
;        sbc #$80
;        sta spr_y_low
;        lda spr_y
;        sbc #$00
;        sta spr_y
;        lda spr_y_high
;        sbc #$00
;        and #$01
;        sta spr_y_high
;        rts
               
fall_down:
spr_y_low = *+1
        lda #00
        clc
speed_y_low = *+1
        adc #$00
        sta spr_y_low
        lda spr_y
speed_y_high = *+1
        adc #$00
        sta spr_y
        lda spr_y_high
speed_y_high_high = *+1
        adc #$00
        and #$01
        sta spr_y_high

        lda speed_y_low
        clc
accelerate = *+1
        adc #$30
        sta speed_y_low
        lda speed_y_high
        adc #$00
        sta speed_y_high
        lda speed_y_high_high
        adc #$00
        sta speed_y_high_high
        
+       rts

bounce_init_with_flat_tree:
        jsr flat_tree
bounce_init:
        lda #$ff
        sta speed_y_high_high
        lda #$fd
        sta speed_y_high
;        lda #$00
;        sta disable_highbit
        lda #$40
        sta speed_y_low
        ;lda #$11
        ;sta accelerate
        lda #$00
        sta schigger_index
bounce_scroll = *+1
        lda #$00
        sta scroll_down_counter
        beq +
        jmp scrolldown_init
+
        rts

switch_sprite:
        jsr switch_bank
disable_sprite:
        lda #$ff
        sta spr_y
        lda #$00
        sta spr_y_high
        rts

prepare_next_sprite:
        lda #<job_prepare_next_sprite
        sta big_jobadress
        lda #>job_prepare_next_sprite
        sta big_jobadress+1
        rts

job_prepare_next_sprite:
        ldy sprite_to_prepare
        lda #$00
        cpy #$03
        beq ++
        cpy #$04
        beq ++
        cpy #$06
        bne +
++      lda #$ff
+       sta $d01b
        jmp copy_sprite_to_dest
               
prepare_sprite_to_screen:
        lda #<job_prepare
        sta big_jobadress
        lda #>job_prepare
        sta big_jobadress+1
        rts

job_prepare:
        lda dd00_copy
        and #$02
        beq +
        jsr copy_screen_to_c0
        jmp ++
+
        jsr copy_screen_to_40
++
        lda #$f0        ; beq
        sta copy_sprite_to_screen_invert
        sta copy_sprite_to_screen_invert2
sprite_to_prepare = *+1
        ldy #$00
        inc sprite_to_prepare
        jmp copy_sprite_to_screen
        
do_end_part:
        lda #<end_part
        sta big_jobadress
        lda #>end_part
        sta big_jobadress+1
        rts
        
end_part:
        pla
        pla
        lda #$3b
        sta $d011
        lda #$80
        sta $d018
        lda #$02
        sta $dd00
        lda #$fe
        ldx #$07
-       sta $e3f8-$8000,x
        dex
        bpl -
        ldx #$fd
        stx $e3f8-$8000
        stx $e3ff-$8000
        dex
        stx $e3fe-$8000
        ldy #$0e
        ldx #<48*8+3
-       lda #$ef
        sta $d001,y
        txa
        sbx #48
        txa
        sta $d000,y
        dey
        dey
        bpl -
        lda #$c0
        sta $d010
        lda #BG_COL
        sta $d025
        lda #$00
        sta $d026
        lda #$ff
        sta $d01c
        sta $d01d
        sta $d015
        sei
        lda #$7f
        sta $dd0d
        lda $dd0d
        ;lda #$00
        ;sta $d01a
        ;inc $d019
        lda #$30
        sta $d012
        lda #<scroll_down_irq
        sta <irq_jmp+1
        lda #>scroll_down_irq
        sta <irq_jmp+2
        cli

!ifdef release {
        ;hier soll faker nach $e000 laden
	jsr link_load_next_raw
}
-
wait_for_scroll_down = *+1
        lda #$00
        beq -
        
        ldx #$00
        lda #BG_COL
-       sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $db00,x
        inx
        bne -
        txa
	ldx #$27
-
	sta $d800 + 23 * 40,x
	dex
	bpl -
        
-       lda $d011
        bpl -
-       lda $d011
        bmi -
               
;-       lda $ff85-$8000
;        cmp #$55
;        bne -
        lda #$15
        sta $d018
        lda #$12
        sta $d011
        lda #$03
        sta $dd00
        lda #$c0
        sta $d016
        lda #$00
        sta $d015
        sta $d01a
        inc $d019
        
!ifdef release {
	ldx #stackcode_end-stackcode
-
	lda stackcode,x
	sta $0100,x
	dex
	bpl -
	jmp $0100
stackcode
	sei
        +start_music_nmi
	;jsr link_decomp
	jmp link_exit
stackcode_end
} else {        
-       inc $d020
        jmp -        
}

do_load_part_before_scroll:
        lda #<load_part_before_scroll
        sta big_jobadress
        lda #>load_part_before_scroll
        sta big_jobadress + 1
        rts

load_part_before_scroll:
!ifndef release {
        ;simulate loading of data
        lda #$00
        tay
        sta $f3
        lda #$24
        sta $f4
        ldx #$3f-$24
-       sta ($f3),y
        iny
        bne -
        inc $f4
        dex
        bne -
} else {
        ;hier koennte der Faker von 2400-3ffe Daten laden.
	jsr link_load_next_comp
	jsr link_load_next_comp
	jsr link_load_next_comp
        ;und auch b000-bfff
        !if 0 { ; only for test
        lda #$00
        tay
        sta $f3
        lda #$b0
        sta $f4
        ldx #$10
-       sta ($f3),y
        iny
        bne -
        inc $f4
        dex
        bne -
        }
}
        ;restore $f3
        ldx #copy_code_len
-       lda copy_code-1,x
        sta COPY_CODE_BASE-1,x
        dex
        bne -
        rts
        
scroll_down_table_values:
        !byte $3c
        !byte $3d
        !byte $3e
        !byte $3f
        !byte $38
        !byte $39
        !byte $3a
        !byte $3b


scroll_down_snd:
        pha
        txa
        pha
        tya
        pha
!ifdef release {
	jsr link_music_play_side1
} else {
        jsr $1003
}
        inc $d019
        lda #$3b
        sta $d011
        lda #$30
        sta $d012
        lda #<scroll_down_irq
        sta <irq_jmp+1
        lda #>scroll_down_irq
        sta <irq_jmp+2
        pla
        tay
        pla
        tax
        pla
        rti
                
prepare_gfx_for_end:
        !if 0 {
        ldx #40
        lda #<($c000+184*40+0-$8000)
        sta screen_addr
        lda #>($c000+184*40+0-$8000)
        sta screen_addr+1
        ldy #$05
-       
        jsr wait_for_disable_01_fast

        lda #$00
        sta (screen_addr),y
        iny
        lda #$aa
        sta (screen_addr),y
        lda #$00
        iny
        sta (screen_addr),y
        lda screen_addr
        clc
        adc #$38
        sta screen_addr
        bcc +
        inc screen_addr+1
+       inc screen_addr+1
        lda #$00
        iny
        sta (screen_addr),y        
        iny
        sta (screen_addr),y        
        iny
        sta (screen_addr),y
        iny
        sta (screen_addr),y
        iny
        sta (screen_addr),y
        iny
        sta (screen_addr),y
        lda screen_addr
        sec
        sbc #$38
        sta screen_addr
        bcs +
        dec screen_addr+1
+       dec screen_addr+1
        ;tya
        ;clc
        ;adc #$08-7
        ;tay
        tya
        bpl +
        sec
        sbc #$80
        tay
        lda screen_addr
        clc
        adc #$80
        sta screen_addr
        bcc +
        inc screen_addr+1
+
        lda #$35
        sta $01     
        dex
        bne -
        }
        lda #$00
        sta $d015
        ldx #$bf
        lda #$55
-       sta $ff00-$8000-1,x
        dex
        bne -
        ldx #$00
        ldy #$00
-       lda scroll_down_table_values,y
        sta scroll_down_table,x
        iny
        cpy #$08
        bne +
        ldy #$00
+       inx
        bne -
        lda #$ff
        sta $ff83-$8000
        sta $ff84-$8000
        sta $ff85-$8000
        sta $ff03-$8000
        sta $ff04-$8000        
        sta $ff45-$8000
        lda #$fd
        sta $ff05-$8000        
        lda #$57
        sta $ff44-$8000
        
        ;lda #$0f
        ;sta $ff43-$8000
        rts
                
copy_screen_to_40:
        ldx #$c0
        ldy #$40
        bne copy_screen

copy_screen_to_c0:
        ldx #$40
        ldy #$c0
copy_screen:
        stx <COPY_CODE_BASE_SRC+1
        sty <COPY_CODE_BASE_DST+1
       
        lda #$00
        sta <COPY_CODE_BASE_SRC
        sta <COPY_CODE_BASE_DST        
        ldx #200*40/128
        jmp COPY_CODE_BASE_WITH_X

scroll_screen_to_40:
        ldx #$c0
        ldy #$40
        bne scroll_screen ; unconditional        

scroll_screen_to_c0:
        ldx #$40
        ldy #$c0

scroll_screen: 
        stx <COPY_CODE_BASE_SRC+1
        sty <COPY_CODE_BASE_DST+1
       
        ldy #$00
        sty <COPY_CODE_BASE_SRC
        sty <COPY_CODE_BASE_DST
        lda #$00
-       sta (COPY_CODE_BASE_DST),y
        iny
        bne -
        inc <COPY_CODE_BASE_DST+1
        ldy #$3f
-       sta (COPY_CODE_BASE_DST),y
        dey
        bpl -
        lda <COPY_CODE_BASE_DST
        clc
        adc #$40
        sta <COPY_CODE_BASE_DST
        bcc +
        inc <COPY_CODE_BASE_DST+1
+       
        jmp COPY_CODE_BASE

        XS = $30
        YS = $80

spr_table_low:
        !byte <spr_bonsai
        !byte <spr_size
        !byte <spr_matters
        !byte <spr_next
        !byte <spr_level
        !byte <spr_per
        !byte <spr_ers
        !byte <spr_form

spr_table_high:
        !byte >spr_bonsai
        !byte >spr_size
        !byte >spr_matters
        !byte >spr_next
        !byte >spr_level
        !byte >spr_per
        !byte >spr_ers
        !byte >spr_form

SPR_X_BONSAI = 256
SPR_X_SIZE = 0
SPR_X_MATTERS = 136
SPR_X_NEXT = 0
SPR_X_LEVEL = 144
SPR_X_PER = 0
SPR_X_ERS = 216
SPR_X_FORM = 80

SPR_Y_BONSAI = 168
SPR_Y_SIZE = 55
SPR_Y_MATTERS = 87
SPR_Y_NEXT = 24
SPR_Y_LEVEL = 55
SPR_Y_PER = 24
SPR_Y_ERS = 0
SPR_Y_FORM = 01

!macro screen_offset_low .x, .y {
        !byte <((.y / 8) * $140 + (.x & $1f8) + (.y & 7))
}

!macro screen_offset_high .x, .y {
        !byte >((.y / 8) * $140 + (.x & $1f8) + (.y & 7))
}

dest_pointer_low:
        +screen_offset_low SPR_X_BONSAI, SPR_Y_BONSAI
        +screen_offset_low SPR_X_SIZE, SPR_Y_SIZE
        +screen_offset_low SPR_X_MATTERS, SPR_Y_MATTERS
        +screen_offset_low SPR_X_NEXT, SPR_Y_NEXT
        +screen_offset_low SPR_X_LEVEL, SPR_Y_LEVEL
        +screen_offset_low SPR_X_PER, SPR_Y_PER
        +screen_offset_low SPR_X_ERS, SPR_Y_ERS
        +screen_offset_low SPR_X_FORM, SPR_Y_FORM

dest_pointer_high:
        +screen_offset_high SPR_X_BONSAI, SPR_Y_BONSAI
        +screen_offset_high SPR_X_SIZE, SPR_Y_SIZE
        +screen_offset_high SPR_X_MATTERS, SPR_Y_MATTERS
        +screen_offset_high SPR_X_NEXT, SPR_Y_NEXT
        +screen_offset_high SPR_X_LEVEL, SPR_Y_LEVEL
        +screen_offset_high SPR_X_PER, SPR_Y_PER
        +screen_offset_high SPR_X_ERS, SPR_Y_ERS
        +screen_offset_high SPR_X_FORM, SPR_Y_FORM

!macro read_sprite {
        inc spr_pointer
        bne +
        inc spr_pointer+1
+
        lda (spr_pointer,x)
}

copy_sprite_to_visible_screen:
        lda #<do_copy_sprite_to_visible_screen
        sta big_jobadress
        lda #>do_copy_sprite_to_visible_screen
        sta big_jobadress+1
        rts

do_copy_sprite_to_visible_screen:
        lda #$d0
        sta copy_sprite_to_screen_invert
        sta copy_sprite_to_screen_invert2
        ldy sprite_to_prepare
        inc sprite_to_prepare
        
copy_sprite_to_screen:
        cpy #$03
        beq do_version2
        cpy #$04
        beq do_version2
        cpy #$06
        bne version1
do_version2:
        jmp version2
version1:

!macro copy_sprite_to_screen_macro .variante {
        ;in y number
        lax spr_table_low,y
        sbx #$01
        stx spr_pointer
        lda spr_table_high,y
        sbc #$00
        sta spr_pointer+1
        lax dest_pointer_low,y
        and #$f8
        sta screen_addr
        lda dest_pointer_high,y
        clc
        adc #$40
        sta screen_addr+1
        lda dd00_copy
        and #$02
        !if .variante = 1 {
copy_sprite_to_screen_invert:
        } else {
copy_sprite_to_screen_invert2:
        }
        beq +
        lda screen_addr+1
        ora #$80
        sta screen_addr+1
+
        txa
        and #$07
        tay
        ldx #$00
        stx .spr_pointer_local
        +read_sprite
        sta spr_xcounter
        +read_sprite
        sta spr_ycounter

        ldx spr_pointer
        lda spr_pointer+1
        sta .spr_pointer_local+1
        
.copy_sprite_to_screen_loop_big:
        jsr wait_for_disable_01
        lda screen_addr+1
        pha
        lda screen_addr
        pha
        lda spr_ycounter
        pha
        tya
        pha


.copy_sprite_to_screen_loop:
        inx
        bne +
        inc .spr_pointer_local+1
+
.spr_pointer_local = *+1
        lda $ff00,x
        beq .no_sprite_or
     
        !if .variante = 1 {   
        sta .mask_value
.mask_value = *+1
        lda MASK_TAB
        and (screen_addr),y
        ora .mask_value
        sta (screen_addr),y
    } else {
        sta .mask_or
        lda (screen_addr),y
        sta .mask_value
.mask_or = *+1
        lda #$00
.mask_value = *+1
        and MASK_TAB
        ora .mask_value
        sta (screen_addr),y
        }              
.no_sprite_or:                
        iny
        cpy #$08
        bne +
        lda screen_addr
        adc #$40-1
        sta screen_addr
        lda screen_addr+1
        adc #$01
        sta screen_addr+1
        ldy #$00
+       dec spr_ycounter
        bne .copy_sprite_to_screen_loop
        
        pla
        tay
        pla
        sta spr_ycounter
        pla
        clc
        adc #$08
        sta screen_addr
        pla
        adc #$00
        sta screen_addr+1
        lda #$35
        sta $01
        dec spr_xcounter
        bne .copy_sprite_to_screen_loop_big
        rts
        }

        +copy_sprite_to_screen_macro 1
version2:
        +copy_sprite_to_screen_macro 2

DEST = $6400

copy_sprite_to_dest:
        ;in y sprite number
        lda spr_table_low,y
        sta spr_pointer
        lda spr_table_high,y
        sta spr_pointer+1
        lda #$00
        sta spr_dst_counter
        lda #<DEST
        sta BASE_ZP
        sta BASE_ZP+2
        sta BASE_ZP+4
        sta BASE_ZP2
        sta BASE_ZP2+2
        sta BASE_ZP2+4
        
        lda #$7f
        ldx #$80+>DEST
        sax BASE_ZP+1
        stx BASE_ZP2+1
        inx
        sax BASE_ZP+3
        stx BASE_ZP2+3
        inx
        sax BASE_ZP+5
        stx BASE_ZP2+5
        ldy #$00
        lda (spr_pointer),y
        sta spr_xcounter
        lda #8*3
        sec
        sbc spr_xcounter
        sta sprite_to_clear
        iny
        lda (spr_pointer),y
        sta ycounter
        lax spr_pointer
        sbx #$fe
        stx spr_pointer
        bcc +
        inc spr_pointer+1
+

copy_sprite_to_dest_copy_column:
        ldy #$00
        ldx #$00
-       lda (spr_pointer),y
        sta buffer,x
        inx
        iny
ycounter = *+1
        cpy #$00
        bne -
        lda #$00
-       sta buffer,x
        inx
        cpx #MAX_HEIGHT_ROUNDED
        bne -
        tya
        clc
        adc spr_pointer
        sta spr_pointer
        bcc +
        inc spr_pointer+1
+
        jsr generated_code
        jsr inc_zp
        dec spr_xcounter
        bne copy_sprite_to_dest_copy_column
        
        lda sprite_to_clear
        beq nothing_to_clear
        
        ldx #MAX_HEIGHT_ROUNDED
        lda #$00
-       sta buffer-1,x
        dex
        bne -

clear_sprite_to_dest_copy_column:
        jsr generated_code
        
        jsr inc_zp
        dec sprite_to_clear
        bne clear_sprite_to_dest_copy_column        
nothing_to_clear:
        !if 0 {
        ldy #$00
-
        !for i,0,$15-$04 {
        lda DEST+i*$100,y
        sta DEST+i*$100+$8000,y
        }
        iny
        bne -
        }
        rts

inc_zp:
        inc BASE_ZP2+2
        inc BASE_ZP2+4
        inc BASE_ZP2
        inc BASE_ZP+2
        inc BASE_ZP+4
        inc BASE_ZP
        bne +
        inc BASE_ZP+1
        inc BASE_ZP+3
        inc BASE_ZP+5
        inc BASE_ZP2+1
        inc BASE_ZP2+3
        inc BASE_ZP2+5
+       inc spr_dst_counter
        lda spr_dst_counter
        cmp #$03
        bne +
        lda #$00
        sta spr_dst_counter
        lda BASE_ZP
        clc
        adc #<(9*64-3)
        sta BASE_ZP
        sta BASE_ZP+2
        sta BASE_ZP+4
        sta BASE_ZP2
        sta BASE_ZP2+2
        sta BASE_ZP2+4
        lda BASE_ZP+1
        adc #$80+>(9*64-3)
        tax
        lda #$7f
        sax BASE_ZP+1
        stx BASE_ZP2+1
        inx
        sax BASE_ZP+3
        stx BASE_ZP2+3
        inx
        sax BASE_ZP+5
        stx BASE_ZP2+5
+        
        rts

!macro irqx .i,.p, .irq1, .irq2 {
        sta .irqx_a
        lda $01
        sta .irqx_01
        lda #$35
        sta $01
        inc $d019
        lda spr_y
        clc
        adc #21*.i
        !for i,0,7 {
        sta $d001+i*2
        }
        lda #<.irq1
        sta <irq_jmp+1
        lda #<.irq2
        sta <irq_jmp2+1
        lda #>.irq1
        sta <irq_jmp+2
        lda #>.irq2
        sta <irq_jmp2+2
        !for i,0,7 {
        lda #$90+i*9+.i
        sta .p*$8000+$63f8+i
        }
        !if (.i != 8) {
        lda spr_y
        clc
        adc #17+(19*.i)
        sta $d012
        } else {
        lda $d011
        ora #$80
        sta $d011
        lda #<MAIN_IRQ_LINE
        sta $d012
        }
.irqx_01 = *+1
        lda #$00
        sta $01
.irqx_a = *+1
        lda #$00
        rti
}
                
irq1:   
        +irqx 1,0, irq2, irq2_2

irq2:  
        +irqx 2,0,irq3,irq3_2

irq3:   
        +irqx 3,0,irq4,irq4_2

irq4:   
        +irqx 4,0,irq5,irq5_2

irq5:   
        +irqx 5,0, irq6, irq6_2

irq6:   
        +irqx 6,0, irq7, irq7_2

irq7:   
        +irqx 7,0, irq8, irq8_2

irq8:   
        +irqx 8,0, irq_main, irq_main

irq1_2: 
        +irqx 1,1,irq2,irq2_2

irq2_2: 
        +irqx 2,1,irq3,irq3_2

irq3_2: 
        +irqx 3,1,irq4,irq4_2

irq4_2: 
        +irqx 4,1,irq5, irq5_2

irq5_2: 
        +irqx 5,1,irq6, irq6_2

irq6_2: 
        +irqx 6,1,irq7, irq7_2

irq7_2: 
        +irqx 7,1,irq8, irq8_2

irq8_2: 
        +irqx 8,1,irq_main,irq_main

irq_main:
        sta irq_main_a
        stx irq_main_x
        sty irq_main_y
        lda $01
        sta irq_main_01

        lda #$35
        sta $01
        
        ;inc $d020
        inc $d019
        lda $d011
        +bpl skip_irq
        
        jsr small_job
        jsr schigger
        jsr scroll_down_func
        
        ;lda $dc01
        ;and #$10
        ;bne ++
        lda #$ff
        sta nmi4_sprite
        ldx #$00
        ldy #$00
        lda spr_y_high
        beq +
        ldy spr_y
        ldx irq_nr_tab,y
        +bmi no_sprite
        lda irq_spry_tab,y
        !for i,0,7 {
        sta $d001+i*2
        }
        lda irq_line_tab,y
        bpl irq_posi
        clc
        adc #56
        sta $d012
        lda $d011
        ora #$80
        sta $d011
        jmp irq_nega
            
+       lda spr_y
        cmp #$ef
        +bcs no_sprite
        cmp $d012
        bcc +
        sta nmi4_sprite
        bcs ++
+ 
        !for i,0,7 {
        sta $d001+i*2
        }
++      lda spr_y
        clc
        adc #17
irq_posi:
        sta $d012
        lda $d011
        anc #$7f
        sta $d011
irq_nega:
        !for i,0,7 {
        txa
        adc #$90+9*i
        sta $63f8+i
        sta $e3f8+i
        }
        lda irq_vec_low,x
        sta <irq_jmp+1
        lda irq_vec_high,x
        sta <irq_jmp+2
        lda irq_vec2_low,x
        sta <irq_jmp2+1
        lda irq_vec2_high,x
        sta <irq_jmp2+2
        bne +
no_sprite:
        lda #$f8
        !for i,0,7 {
        sta $d001+i*2
        }

+
        lda d011_val
        ora #$08
        sta d011_val2
        ora #$30
        sta d011_val3
        inc $d019

        cli
!ifdef release {
	jsr link_music_play_side1
} else {
        jsr $1003
}
        ;lda #<test_job
        ;sta big_jobadress
        ;lda #>test_job
        ;sta big_jobadress+1
       
skip_irq:
        ;dec $d020
irq_main_01 = *+1
        lda #$00
        sta $01
irq_main_y = *+1
        ldy #$00
irq_main_x = *+1
        ldx #$00
irq_main_a = *+1
        lda #$00
        rti

        +align256

!macro do_ror .x {
        sec
        ror .x
        lsr .x
        }

        +check_same_page_start
scroll_down_irq:
        sta scroll_down_irq_a
        stx scroll_down_irq_x
        lda #$11
        sec
        sbc $dd04
        sta scroll_down_irq_bpl
scroll_down_irq_bpl = *+1
        bpl scroll_down_irq_bpl
        !for i,1,10 {
        !byte $c9
        }
        bit $ea
        ldx #$00
-       lda scroll_down_table,x
        sta $d011
        lda (00,x)
        lda (00,x)
        lda (00,x)
        lda (00,x)
        lda (00,x)
        lda (00,x)
        lda (00,x)
        lda (00,x)
        inx
scroll_down_cmp = *+1
        cpx #1
        bne -
scroll_down_low_value = *+1
        lda #$00
        clc
scroll_down_low_speed = *+1
        adc #$00
        sta scroll_down_low_value        
        lda scroll_down_cmp
scroll_down_add_value = *+1
        adc #$00
        cmp #198
        bcc +
        lda #$00
        sta scroll_down_add_value

        inc wait_for_scroll_down
;        +do_ror $ff83-$8000
;        +do_ror $ff84-$8000
;        +do_ror $ff85-$8000
;        +do_ror $ff03-$8000
;        +do_ror $ff04-$8000
;        +do_ror $ff45-$8000
;        +do_ror $ff05-$8000
;        +do_ror $ff44-$8000
        lda #198
+       sta scroll_down_cmp
        lda scroll_down_low_speed
        clc
        adc #$18
        sta scroll_down_low_speed
        bcc +
        inc scroll_down_add_value
+
        inc $d019
        lda #<scroll_down_snd
        sta <irq_jmp+1
        lda #>scroll_down_snd
        sta <irq_jmp+2
        lda #$ff
        sta $d012
scroll_down_irq_x = *+1
        ldx #$00
scroll_down_irq_a = *+1
        lda #$00
        rti        
        +check_same_page_end
                
irq_vec_low:
        !byte <irq1, <irq2, <irq3, <irq4, <irq5, <irq6,  <irq7,  <irq8
irq_vec_high:
        !byte >irq1, >irq2, >irq3, >irq4, >irq5, >irq6,  >irq7,  >irq8

irq_vec2_low:
        !byte <irq1_2, <irq2_2, <irq3_2, <irq4_2, <irq5_2, <irq6_2,  <irq7_2,  <irq8_2
irq_vec2_high:
        !byte >irq1_2, >irq2_2, >irq3_2, >irq4_2, >irq5_2, >irq6_2,  >irq7_2,  >irq8_2

irq_nr_tab:
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,7,7,7,7,7,7,7,7
!byte 7,7,7,7,7,7,7,7,7,7,7,7,7,6,6,6
!byte 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
!byte 6,6,5,5,5,5,5,5,5,5,5,5,5,5,5,5
!byte 5,5,5,5,5,5,5,4,4,4,4,4,4,4,4,4
!byte 4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3
!byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
!byte 3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
!byte 2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1
!byte 1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

irq_line_tab:
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,-18,-17,-16,-15,-14,-13,-12,-11
!byte -10,-9,-8,-7,-6,-5,-4,-3,-2,-2,-2,-2,-2,-16,-15,-14
!byte -13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-2,-2,-2,-2
!byte -2,4,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-2
!byte -2,-2,-2,-2,4,5,6,-12,-11,-10,-9,-8,-7,-6,-5,-4
!byte -3,-2,-2,-2,-2,-2,-2,4,5,6,7,8,-10,-9,-8,-7
!byte -6,-5,-4,-3,-2,-2,-2,-2,-2,-2,4,5,6,7,8,9
!byte 10,-8,-7,-6,-5,-4,-3,-2,-2,-2,-2,-2,-2,4,5,6
!byte 7,8,9,10,11,12,-6,-5,-4,-3,-2,-2,-2,-2,-2,-2
!byte 4,5,6,7,8,9,10,11,12,13,14,-4,-3,-2,-2,-2
!byte -2,-2,-2,4,5,6,7,8,9,10,11,12,13,14,15,16

irq_spry_tab:
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
!byte -1,-1,-1,-1,-1,-1,-1,-1,35,36,37,38,39,40,41,42
!byte 43,44,45,46,47,48,49,50,51,52,53,54,55,35,36,37
!byte 38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53
!byte 54,55,35,36,37,38,39,40,41,42,43,44,45,46,47,48
!byte 49,50,51,52,53,54,55,35,36,37,38,39,40,41,42,43
!byte 44,45,46,47,48,49,50,51,52,53,54,55,35,36,37,38
!byte 39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54
!byte 55,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49
!byte 50,51,52,53,54,55,35,36,37,38,39,40,41,42,43,44
!byte 45,46,47,48,49,50,51,52,53,54,55,35,01,02,38,39 ; 01 and 02 modified
!byte 40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55



setup_nmi:
        lda #$40
        sta $dd0c
        ldx #LINE
        lda nmi_lowtab,x
        sta $fffa
        lda nmi_hightab,x
        sta $fffb
        lda #0
        sta $dd07
        lda $d012
-       cmp $d012
        bne -
        lda nmi_linetab,x
        clc
        sbc $d012
        sta $dd06
        lda #$82
        sta $dd0d
        lda #%01011001
        sta $dd0f
        rts
        
        +align256
nmi0:
        sta nmi0_a
        lda #$3b+$80
        sta $d011
        lda #2-1
        sta $dd06
        lda #%01011001
        sta $dd0f
        lda #<nmi1
        sta $fffa
nmi0_a = *+1
        lda #$00
        jmp $dd0c

nmi1:
        sta nmi1_a
        lda #$2a
        sec
        sbc $dd04
        sta nmi1_bpl
nmi1_bpl = *+1
        bpl nmi1_bpl
        !for i,1,31 {
        !byte $c9
        }
        bit $ea
        lda #$d1 ; lda #$0a
        sta $d016 ;sta $d021
        lda #$f8
        sta $d011
        lda #$03
        sta $dd00
        lda #$00
        sta $d01c
        lda #$2a
        sec
        sbc $dd04
        sta nmi1_bpl2
nmi1_bpl2 = *+1
        bpl nmi1_bpl2
        !for i,1,31 {
        !byte $c9
        }
        bit $ea
        lda #$88
        sta $d018
        ;lda #$00
        ;sta $d020
        lda #$18
        sta $d011
        lda #$d9  ; lda #$07 ;
        sta $d016 ; sta $d021
        lda #$f9-$f3
        sta $dd06
        lda #%01011001
        sta $dd0f        
        lda #<nmi2
        sta $fffa
        lda #>nmi2
        sta $fffb
        
        
nmi1_a = *+1
        lda #$00
        jmp $dd0c

nmi2:
        sta nmi2_a
d011_val = *+1
        lda #$10 + LINE
        sta $d011
        lda #$ff-$f9
        sta $dd06
        lda #%01011001
        sta $dd0f        
        lda #<nmi3
        sta $fffa
        lda #>nmi3
        sta $fffb
nmi2_a = *+1
        lda #$00
        jmp $dd0c
        
nmi3:
        sta nmi3_a
        inc $01
d011_val2 = *+1
        lda #$18+LINE
        sta $d011
        lda #$10
        sta $dd06
        lda #%01011001
        sta $dd0f
        lda #<nmi5
        sta $fffa
        lda #>nmi5
        sta $fffb
        lda $dd0d
nmi3_a = *+1
        lda #$00
        dec $01
        rti

nmi5:
        sta nmi5_a
        inc $01
        lda #<(312-$12)
        sta $dd06
        lda #%01011001
        sta $dd0f
        lda #<nmi4
        sta $fffa
        lda #>nmi4
        sta $fffb
        lda $dd0d
        lda #<MAIN_IRQ_LINE
        sta $d012
        lda $d011
        ora #$80
        sta $d011
        lda #$80
        !for i,0,7 {
        sta $d001+i*2
        }
        inc $d019
        lda #<irq_main
        sta <irq_jmp+1
        sta <irq_jmp2+1
        lda #>irq_main
        sta <irq_jmp+2
        sta <irq_jmp2+2
        dec $01
nmi5_a = *+1
        lda #$00
        rti      

nmi4:
        sta nmi4_a
        stx nmi4_x
        inc $01
dd00_copy = *+1
        lda #$02
        sta $dd00 
        lda #$80
        sta $d018
        lda #$ff
        sta $d01c
        ;lda #$07
        ;sta $d020
        lda d011_val
        and #$07
        tax
        lda nmi_lowtab,x
        sta $fffa
        lda nmi_hightab,x
        sta $fffb
        lda $d012
-       cmp $d012
        beq -
        lda nmi_linetab,x
        sec
        sbc $d012
        sta $dd06
        lda #%01011001
        sta $dd0f
d011_val3 = *+1
        lda #$38+LINE
        sta $d011
nmi4_sprite = *+1
        lda #$ff
        cmp #$ff
        beq +
        !for i,0,7 {
        sta $d001+i*2
        }
+       lda $dd0d
        dec $01
nmi4_x = *+1
        ldx #$00
nmi4_a = *+1
        lda #$00
        rti

nmi_lowtab:
        !byte <nmi0,<nmi1, <nmi1,<nmi1,<nmi1,<nmi1,<nmi1,<nmi1
nmi_hightab:
        !byte >nmi0,>nmi1, >nmi1,>nmi1,>nmi1,>nmi1,>nmi1,>nmi1

nmi_linetab:
        !byte $ef-2,$ef,$ef,$ef,$ef,$ef,$ef,$ef

;nmi3_cont:
;        lda spr_y
;        sec
;        sbc #$03
;        sta $d012
;        inc $d019
;        lda #$81
;        sta $d01a
;        lda #<irq0
;        sta <irq_jmp+1
;        lda #>irq0
;        sta <irq_jmp+2
;        lda #<irq0_2
;        sta <irq_jmp2+1
;        lda #>irq0_2
;        sta <irq_jmp2+2

!ifdef release {
;	jsr link_music_play_side1
} else {
;        jsr $1003
}
;        lda #<test_job
;        ;sta jobadress
;        lda #>test_job
;        ;sta jobadress+1
;        pla
;        tay
;        pla
;        tax
;        pla
;        rti


copy_code:
!pseudopc COPY_CODE_BASE {
    ldx #192*40/128
COPY_CODE_BASE_WITH_X:
--  ldy #$7f
    jsr wait_for_disable_01_fast
-
COPY_CODE_BASE_SRC = *+1
    lda $4140,y
COPY_CODE_BASE_DST = *+1
    sta $4000,y
    dey
    lda (COPY_CODE_BASE_SRC),y
    sta (COPY_CODE_BASE_DST),y
    dey
    lda (COPY_CODE_BASE_SRC),y
    sta (COPY_CODE_BASE_DST),y
    dey
    lda (COPY_CODE_BASE_SRC),y
    sta (COPY_CODE_BASE_DST),y
    dey
    bpl -
    lda #$35
    sta $01
    lda <COPY_CODE_BASE_DST
    eor #$80
    sta <COPY_CODE_BASE_DST
    bmi +
    inc <COPY_CODE_BASE_DST+1
+
    lda <COPY_CODE_BASE_SRC
    eor #$80
    sta <COPY_CODE_BASE_SRC
    bmi +
    inc <COPY_CODE_BASE_SRC+1
+
    dex
    bne --
    rts
}

copy_code_len = *-copy_code

wait_for_disable_01_fast:
        lda $d011
        bmi +
        lda $d012
        cmp #$a0
        bcs wait_for_disable_01_fast
        sta $fffc
        lda #$00
        sta $fffd
+       lda #$34
        sta $01
        rts

wait_for_disable_01:
        lda $d011
        bmi +
        lda $d012
        cmp #$30
        bcs wait_for_disable_01
        sta $fffd
        lda #$00
        sta $fffc
+       lda #$34
        sta $01
        rts

set_color_tree_to_red:
        lda #SPR_COL1 << 4 | SPR_COL3
        ldy #SPR_COL2
set_color_tree:
        ldx #$06
-
        !for j,0,2 {
        sta $6000+40*(21+j)+32,x
        sta $e000+40*(21+j)+32,x
        pha
        tya
        sta $d800+40*(21+j)+32,x
        pla
        }
        dex
        bpl -
        rts

flat_tree:
        ldx #$08*7-1
        lda #$00
-       !for j,0,2 {
        sta $4000+320*(21+j)+32*8,x
        }
        dex
        bpl -
        ldy #$00
        ldx #$08*7-1
-       lda baumflach,y
        sta $4000+320*23+32*8-1,x
        lda baumflach2,y
        sta $4000+320*23+32*8-2,x
        iny
        txa
        sbx #$08
        bpl -
        rts

baumflach:
        !byte %01100000
        !byte %10010101
        !byte %01100101
        !byte %01010110
        !byte %01011001
        !byte %01100110
        !byte %00001001

baumflach2:
        !byte %10000000
        !byte %00101010
        !byte %10001010
        !byte %10101000
        !byte %10100010
        !byte %10001000
        !byte %00000010
                
spr_form:
        !bin "spr_form"
spr_size:
        !bin "spr_size"
spr_next:
        !bin "spr_next"
endgfx:

        * = $2400
spr_matters:
        !bin "spr_matters"
spr_level:
        !bin "spr_level"
spr_per:
        !bin "spr_per"
spr_ers:
        !bin "spr_ers"
spr_bonsai:
        !bin "spr_bonsai"

endgfx2:
!ifndef release {
        * = $1000
        !bin "Negative_Karma.sid",,126
}
