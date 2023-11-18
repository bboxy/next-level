      !cpu 6510
      !initmem $00

; This is the textrotator part.

; #§# ToDo:
; * Invert NEXT LEVEL text in precalc.
; * Change to 24 pixels offset.

; * Highlight one of the "Next Level"-texts with 2 enlarged sprites.
;   Then, highlight 4 different texts with different colours.
;   Make the prototype with sprite animations in html first.

; * Highlight one of the "Next Level"-texts with 7 sprites "behind" the chars.
;   Do this for a static "centered text". Just make a sinus table with fitting distances, and
;   a multiply by 1/3 and 2/3 tables. The sprites should be a circle.
;   The x-position needs to be 9-bit.

; * Move the NEXT LEVEL layer around using d016 and d011. However, use which chars to copy into without moving contents of $6400.
;   Could use the copy-routine to do smooth in y-direction, keeping d011 independent of NEXT LEVEL movement.
;   Could use d016 for the x-movement.
; * Make sure that the sprite highlight follows one of the texts.

; * Use this highlight to move around with simulated physics bouncing into the border.
;   simulate using blender and export the path somehow. Or JavaScript.

; * Write a $d800-scroller that only sets the colors that change. Do this like a 
;   LDA #on colour
;   LDY #off colour
;   sta $d800,x
;   sty $d803,x
;   sta $d810,x
;   sty $d813,x
; Every frame, let x=x-1
; And, make sure that the code is JSR'ed into at the right line, and put an RTS where it should end.
; The code generator should set a label frame_no_XXX: where to jump into.
; Then make a jumptable, where frame_no_XXX+1 is used to insert the RTS.

; Sequence: From noisefader, go into rotating torus + rotating NEXT LEVEL + scrolling PERFORMERS logo in d800.


; Make a torus, with twisted stripes.
; Render into two sprite mats
; Alternate between them, and cycle their colours.
;   R G B
;    R G B
; ...and let RG be black, and B be white.


; Make a sprite with the text "TURN DISC" and put it in the lower border during noisefader.
; Then, transform it into "NEXT LEVEL", let it bounce into the screen, and fade in the next level texts with it.
; Then, add the torus on top of the rotating texts. And scroll PERFORMERS in the d800, 
; then fade away the NEXT LEVEL text, load the overload part, then make the torus two colors, and run an animation
; where it shrinks.

; Barber pole

; Make the rotating texts possible to move in x and y directions.
; Use d016 right/left and move what gets copied into chars, and d011 for smooth scrolling.
; Fix the copying of even/odd lines.

;release      equ 0

  colimage_poi = $10
  d800_poi = $11
  ghost_destpoi = $c0
  ghost_textpoi = $c2
  ghostbyte = $7fff


; memory map:
;$c100-$d000 init code. This will load the rest of the part. $2000-$5600
;And show the first two sprites on the screen.

;$0800-$2000 music

;$2000-$2fff code.

; The screen is calculated by 6502 code:
ghostscreen = $4000  ; This screen only uses the sprite pointers at $43f8-$43ff, so it's OK to overlap with charset which uses $4000-$40ff
screen0 = $4400
charset = $4000
charset1 = $4800

!ifndef release {
} else {
      !src "../../bitfire/loader/loader_acme.inc"
      !src "../../bitfire/macros/link_macros_acme.inc"
}

;DISABLE_STABLE = 1




  *= $1000
music:
!ifndef release {
  ;!bin "starquest.sid",,$7e
  ;!bin "../../music/true-north-17.prg",,2
  ;!bin "../../music/music.prg",,2
  ;!bin "../../music/PREV2.PRG",,2

  !bin "../../music/main05.prg",,2
musicend:
}

  * = $2000

maskscroller_row0:
  !byte %10000010,%00010000,%01000010,%00001000,%00101110,%10000100,%00010000,%01111111
  !byte %10010010,%01110010,%01001110,%01001001,%00100100,%10011100,%10010011,%11111111
  !byte %10000010,%00110000,%11000110,%01001000,%01100000,%10001100,%00110000,%01111111
  !byte %10011110,%01110010,%01001110,%01001001,%00100100,%10011100,%10011110,%01111111
  !byte %10011110,%00010010,%01001110,%00001001,%00100100,%10000100,%10010000,%01111111

copy_static_rotated_text:
rotated:
  lda #0
  beq copy_mirrored_not_rotated

; In here, we shall copy the rotated template into the correct X char-position ((x_pos/8)*8):
copy_rotated_not_mirrored:
  ldy #>charset
  lda desired_d018+1
  and #$2
  beq draw3
  ldy #>charset1
draw3:
  sty copy_dst_poi+2
  sty copy_dst_poi2+2

;anim_poi is a 16-bit pointer to the 128-byte block that is to be copied.
;We need to copy this in two parts:
  lda coloffset_x+1
  eor #$7
  and #$7
  asl
  asl
  asl
  asl
  clc
  adc #$f
  tax

  lda anim_poi+1
  sta anim_poi2+1
  sta anim_poi22+1
  lda anim_poi+2
  sta anim_poi2+2
  sta anim_poi22+2
  ldy #$0
copy_more2:
anim_poi2:
  lda the_anim,x   ;4
copy_dst_poi:
  sta charset,y    ;4
  iny              ;2
  dex              ;2
  bpl copy_more2   ;3 = 15

  cpy #$80
  beq already_copied_everything
;And now, we need to copy the remaining part:
  txa
  clc
  adc #$80
  tax
copy_more22:
anim_poi22:
  lda the_anim,x       ;4
copy_dst_poi2:
  sta charset,y        ;4
  dex                  ;2
  iny                  ;2
  bpl copy_more22      ;3 = 15
already_copied_everything:
  jmp done_copying

copy_mirrored_not_rotated:
;ToDo: compensate for coloffset_x+1. One char to the left when it increases by 1
; In here, we shall copy the rotated template into the correct X char-position ((x_pos/8)*8):

  ldy #>charset
  lda desired_d018+1
  and #$2
  beq draw4
  ldy #>charset1
draw4:
  sty copy_dst_poi_A+2
  sty copy_dst_poi2_A+2

;We need to copy this in two parts:
  lda coloffset_x+1
  eor #$7
  and #$7
  asl
  asl
  asl
  asl
  clc
  adc #$f
  tax
  sta how_many_more11+1

  lda coloffset_x+1
  and #$7
  asl
  asl
  asl
  asl
  clc
  adc anim_poi+1
  sta anim_poi1+1
  sta anim_poi11+1
  lda anim_poi+2
  sta anim_poi1+2

  lda coloffset_x+1
  eor #$7
  and #$7
  clc
  adc #1
  asl
  asl
  asl
  asl
  sta what_to_sub+1
  lda anim_poi+1
  sec
what_to_sub:
  sbc #0
  sta anim_poi11+1
  lda anim_poi+2
  sbc #0
  sta anim_poi11+2



copy_more1:
anim_poi1:
  ldy the_anim,x
  lda mirror,y
copy_dst_poi_A:
  sta charset,x
  dex
  bpl copy_more1

  lda coloffset_x+1
  and #$7
  beq no_need_to_copy_more

;And now, we need to copy the remaining part:
  ldx #$7f
copy_more11:
anim_poi11:
  ldy the_anim,x
  lda mirror,y
copy_dst_poi2_A:
  sta charset,x
  dex
how_many_more11
  cpx #0
  bne copy_more11
no_need_to_copy_more:




;; The original copy_mirrored_not_rotated:
;  ldx #$7f
;copy_more:
;anim_poi:
;  ldy the_anim,x
;  lda mirror,y
;  sta charset,x
;  dex
;  bpl copy_more

done_copying:

  lda left_anim_frac_delay+1
  cmp #$80
  beq no_increase_frac
  inc left_anim_frac_delay+1
no_increase_frac:
left_anim_frac_delay:
  lda #0
  clc
left_anim_frac:
  adc #1
  sta left_anim_frac+1
  bcs just_rts

do_left_anim:
left_anim_direction:
  lda #1
  bne add_anim
;sub_anim:

  lda anim_poi+1
  sec
  sbc #$80
  sta anim_poi+1
  lda anim_poi+2
  sbc #0

  cmp #$7f
  bne nowrrr2
  lda rotated+1
  eor #1
  sta rotated+1
  lda #$bf
nowrrr2:
  sta anim_poi+2

just_rts:
  rts

add_anim:
anim_poi:
  lda the_anim
  lda anim_poi+1
  clc
  adc #$80
  sta anim_poi+1
  lda anim_poi+2
  adc #0

  cmp #$c0
  bne nowrrr
  lda rotated+1
  eor #1
  sta rotated+1
  lda #$80
nowrrr:
  sta anim_poi+2
  rts







;late VIC-II luma
;0
;6, 9
;2, B
;4, 8
;C, E
;5, A
;3, F
;7, D
;1



sprite_pois:
  !byte (sprites-$4000) / $40 + 0
  !byte (sprites2-$4000) / $40 + 0
  !byte (sprites3-$4000) / $40 + 0
  !byte (sprites4-$4000) / $40 + 0

sprite_cols_0:
  !byte $6,$0,$0
sprite_cols_1:
  !byte $0,$0,$6
sprite_cols_2:
  !byte $0,$6,$0


irq_0:
  pha
; stable irq through timer dc04:
!ifndef DISABLE_STABLE {
  lda $dc04
  eor #7
  and #7
  sta *+4
  bpl *+2
  lda #$a9
  lda #$a9
  lda $eaa5
}
desired_d011:
  lda #$53
  sta $d011
  lda #$0
  sta $d021
;setup sprites
;  lda #$00
  sta $d015
  sta $d017
  lda #$ff
  sta $d010
  lda #$80
  sta $d000
  sta $d002
  sta $d004
  sta $d006
  sta $d008
  sta $d00a
  sta $d00c
  sta $d00e
  stx save_x0+1
  sty save_y0+1

  ;Now all stray sprites are hidden in the right border.
  ;We will need to wait here until they are finished a couple of lines further down.
  ;We will need to setup the spritey,x,col,etc, but we cannot set spritex until the last moment
  ;else there will be garbage on the screen.


;used to be $fa:
ghostsprite_ypos = $01

  lda #ghostsprite_ypos
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f

  lda #$fe
  sta $d015
  sta $d01c  ;All ghostsprites multicol
  lda #$1
  sta $d028
  sta $d029
  sta $d02a
  sta $d02b
  sta $d02c
  sta $d02d
  sta $d02e
  lda #$0
  sta $d026

  lda #$13     ;get the ghostbyte to $7fff instead of $7bff in extended background mode.
  sta $d011
  nop


;Moved these here since we've got clock cycles to burn:
amplitude_cou:
  ldx #0
  lda torus_amplitudes_left_0,x
  sta left_bounce_amplitude
  lda torus_amplitudes_left_1,x
  sta left_bounce_amplitude+1
  lda torus_amplitudes_right_0,x
  sta right_bounce_amplitude
  lda torus_amplitudes_right_1,x
  sta right_bounce_amplitude+1


  lda desired_ghostd016+1
  and #7
  ora #$c0
  sta $d016


  lda #$00    ;screen at $4000 "to get the sprite pointers right", charset at $4000
  sta $d018
  nop

  lda #0
  sta $d020
  ldx #$4
warjt:
  dex
  bne warjt
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
  lda #0
  sta $d01b


  jsr the_demo_ghostloop
  ldx #0
  nop
  stx $d021
  lda #$ff
  sta ghostbyte
  ; Make sure that the torus doesn't show up twice (at $132 and $032)
  stx $d015


  lda #$10    ;screen at $4400, charset at $4000
  sta $d018

  lda #spr_ypos_msb
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f


  ; sprxpos is valid from $18 (far left) to $e7 (far right).
  ; sprypos is valid from $06 (upper) to $9c (lower).


first_sprite_no = (sprites-$4000) / $40



torus_bounce_cou:
  ldx #120
  lda torus_bounce_table,x
  bne no_wrap_torus_cou
;Make toruses spin faster:
  lda #0
  sta anim_frac_delay+1
;And make them do in the other direction:
  lda anim_direction+1
  eor #1
  sta anim_direction+1
;And brifly flash the rotating text colours:
;  lda #11
;  sta rotating_text_flash_counter+1
;And change rotation of the left text:
  lda left_anim_direction+1
  eor #1
  sta left_anim_direction+1
  lda #0
  sta left_anim_frac_delay+1
;And make right rotation text bounce a little:
  lda #$80
  sta blit_yspd_lsb+1
  lda #1
  sta blit_yspd_msb+1


;And decide a new bounce speed:
bounce_speed_cou:
  ldy #0
  lda torus_bounce_speeds,y
  bne no_wrap_speeds
  ldy #0
  lda #1
no_wrap_speeds:
  sta bounce_speed+1
  iny
  sty bounce_speed_cou+1
;And decide new amplitudes:
  ldx amplitude_cou+1
  inx
  cpx #torus_amplitudes_left_1 - torus_amplitudes_left_0
  bne no_wrap_amplitudes
  ldx #0
no_wrap_amplitudes
  stx amplitude_cou+1
;And decide a new collision point:
collision_point_cou:
  ldy #0
  lda torus_collision_points,y
  sta torus_desired_meeting_point+1
  iny
  cpy #torus_collision_points_end - torus_collision_points
  bne no_wrap_collision_point
  ldy #0
no_wrap_collision_point:
  sty collision_point_cou+1

  ldx #$ff
no_wrap_torus_cou:
  txa
  clc
bounce_speed:
  adc #1
  tax
  stx torus_bounce_cou+1

;Sometimes, change the colour of the toruses:
;Do this when they are "far apart":
  cpx #120
  bne no_new_torus_colour
;And when at maximum amplitude both of them:
  lda amplitude_cou+1
  bne no_new_torus_colour
torus_colour_cou:
  ldy #0
  lda torus_colours,y
  sta sprite_cols_0
  sta sprite_cols_1+2
  sta sprite_cols_2+1
  lda torus_colours_2,y
  sta sprite_cols_0+1
  sta sprite_cols_1
  sta sprite_cols_2+2
  lda torus_colours_3,y
  sta sprite_cols_0+2
  sta sprite_cols_1+1
  sta sprite_cols_2
  iny
  cpy #torus_colours_end - torus_colours
  bne no_colour_wrap
  ldy #0
no_colour_wrap:
  sty torus_colour_cou+1
no_new_torus_colour:



  lda torus_bounce_table,x
left_bounce_amplitude:
  lsr
  lsr
  sta left_bounce_offset+1
torus_meeting_point:
  lda #42 + 3*48
  sec
left_bounce_offset:
  sbc #0
  sta desired_xpos_left_lsb
  lda #0
  sbc #0
  sta desired_xpos_left_msb

  lda #239
  sec
  sbc torus_bounce_cou+1
  tax
  lda torus_bounce_table,x
right_bounce_amplitude:
  lsr
  lsr
;A is the right_bounce_offset
  clc
  adc torus_meeting_point+1
  sta desired_xpos_right_lsb
  lda #0
  adc #0
  sta desired_xpos_right_msb


;Move the meeting point towards the desired meeting point:
  lda torus_meeting_point+1
torus_desired_meeting_point:
  cmp #42 + 3*48
  beq no_moving
  bcc increase_it
  dec torus_meeting_point+1
  jmp no_moving
increase_it:
  inc torus_meeting_point+1
no_moving:

;rotating_text_flash_counter:
;  ldx #0
;  bmi no_need_to_flash
;  lda left_rotating_text_flash_table,x
;  sta left_rotating_text_colour+1
;  lda right_rotating_text_flash_table,x
;  sta right_rotating_text_colour+1
;  dex
;  stx rotating_text_flash_counter+1
;no_need_to_flash:


anim_delay:
  ldy #1
  dey
  sty anim_delay+1
  bpl no_anim
  ldy #0
  sty anim_delay+1

anim_frac_delay:
  lda #0
  clc
anim_frac:
  adc #1
  sta anim_frac+1
  bcc no_more_waiit
  iny
  sty anim_delay+1
no_more_waiit:
  inc anim_frac_delay+1
  inc anim_frac_delay+1
  bne no_dirswap
  dec anim_frac_delay+1
  dec anim_frac_delay+1
no_dirswap:

anim_direction:
  lda #0
  beq anim_add
anim_sub:
  lda sprite_no+1
  sec
  sbc #1
  and #3
  sta sprite_no+1
  tax
  cmp #3
  bne anim_done
  lda col_pos+1
  sec
  sbc #1
  cmp #$ff
  bne no_cols_wrap2
  lda #2
no_cols_wrap2:
  sta col_pos+1
  jmp anim_done

anim_add:
sprite_no:
  lda #0
  clc
  adc #1
  and #3
  sta sprite_no+1
  tax
  bne anim_done
col_pos:
  ldy #0
  iny
  cpy #3
  bne no_cols_wrap
  ldy #0
no_cols_wrap:
  sty col_pos+1
anim_done:

no_move_cols:
  lda sprite_pois,x
  sta spritepoi_0+1
  clc
  adc #7
  sta spritepoi_1+1
  clc
  adc #7
  sta spritepoi_2+1
  clc
  adc #7
  sta spritepoi_3+1
  clc
  adc #7
  sta spritepoi_4+1
no_anim:

  lda #$31
  sta $d012
  lda #<irq_0b
  sta $fffe
  lda #>irq_0b
  sta $ffff
;  lda #$00
;  sta $d021

  ldx col_pos+1
  lda sprite_cols_0,x
  sta $d027
  sta $d028
  sta $d029
  sta $d02a
  sta $d02b
  sta $d02c
  sta $d02d
  lda sprite_cols_1,x
  sta $d025
  lda sprite_cols_2,x
  sta $d026

  jsr set_sprite_d000

;right_rotating_text_colour:
;  lda #$c
;  sta $d022  ;extended colour #1

spritepoi_0:
  ldx #first_sprite_no + $04
  stx screen0+$3f8
  inx
  stx screen0+$3f9
  inx
  stx screen0+$3fa
  inx
  stx screen0+$3fb
  inx
  stx screen0+$3fc
  inx
  stx screen0+$3fd
  inx
  stx screen0+$3fe

  lda #$5b
  sta $d011
  lda #$ff
  sta $d017


; WARNING: BUG alert! Not allowed to write to $d016 when ghostbyte is covering $d021:
;So make sure that $d021 is black.
;  lda #$0
;  sta $d021
  lda desired_d016+1
  sta $d016
left_rotating_text_colour:
  lda #$c
  sta $d021


  lda desired_d018+1
;  lda #$10    ;screen at $4400, charset at $4000
;  lda #$12   ;screen at $4400, charset at $4800
  sta $d018
  eor #2
  sta desired_d018+1

  ldy #>charset
  and #$2
  beq draw2
  ldy #>charset1
draw2:
  sty blit_dst+2
  sty blit_dst2+2
  sty blit_dst_A+2
  sty low_blit_dst_A+2

;end_irq_0:
  asl $d019
  cli
  ;We may be interrupted from these tasks:

;d800_scroller_part1:
  lda coloffset_x_d016+1
  sec
  sbc #$2
  and #$7
  sta coloffset_x_d016+1
  ora #$a0
  sta desired_d016+1
  cmp #$a7
  bne no_move_colsaa2
  inc coloffset_x+1
no_move_colsaa2:

spriteshadow_x_toggle:
  lda #0
  eor #1
  sta spriteshadow_x_toggle+1
  beq no_move_spriteshadow
  lda spriteshadow_x+1
  clc
spriteshadow_xdir:
  adc #1
  cmp #$ff
  bne no_left
  ldx #$ff
  stx spriteshadow_xdir+1
no_left:
  cmp #$28
  bne no_right
  ldx #$01
  stx spriteshadow_xdir+1
no_right:
  sta spriteshadow_x+1
no_move_spriteshadow:

  jsr update_split
  jsr do_ghostscroller
  jsr fine_tune
  jsr copy_static_rotated_text

save_x0:
  ldx #0
save_y0:
  ldy #0
  pla
  rti

torus_collision_points:
  !byte 42 + 3 * 48
  !byte 42 + 2 * 48
  !byte 42 + 1 * 48
  !byte 42 + 2 * 48
  !byte 42 + 3 * 48
  !byte 42 + 4 * 48
torus_collision_points_end:

torus_colours:
  !byte 11, 4,13,6
torus_colours_end:
torus_colours_2:
  !byte 12, 0, 3,0
torus_colours_3:
  !byte 15, 0, 5,0

;late VIC-II luma
;0
;6, 9
;2, B
;4, 8
;C, E
;5, A
;3, F
;7, D
;1

;left_rotating_text_flash_table:
;  !byte $1,$d,$3,$5,$e,$4,$b,$6,$0,$0,$1,$0
;right_rotating_text_flash_table:
;  !byte $c,$8,$8,$8,$2,$2,$9,$9,$0,$0,$0,$1

; $0030 is the first visible position to the left:
; $021d is the rightmost position that the positioning of "left" torus can handle:
; $0161 is when the left torus touches the right border:
desired_xpos_left_lsb: !byte $30
desired_xpos_left_msb: !byte 0

desired_xpos_right_lsb: !byte $50
desired_xpos_right_msb: !byte 1

torus_bounce_speeds:
  !byte 1,1,2,3,2,3,2,1,3,0

;Torus bounce amplitudes are: 1 + 1, 1 + 1/2, 1/4 + 1, 1/2 + 1/2, 1/4 + 1/2,    repeat. 
anop = $ea
alsr = $4a
torus_amplitudes_left_0:
  !byte anop,anop,alsr,alsr,alsr
torus_amplitudes_left_1:
  !byte anop,anop,alsr,anop,alsr
torus_amplitudes_right_0:
  !byte anop,alsr,anop,alsr,alsr
torus_amplitudes_right_1:
  !byte anop,anop,anop,anop,anop


set_sprite_d000:
;Compensate sprites' x-position for the animation being dithered in x-direction:
  lda sprite_no+1
  and #1
  asl
  ;clc
  adc desired_xpos_left_lsb
  sta used_xpos_left_lsb+1
  lda desired_xpos_left_msb
  adc #0
  sta used_xpos_left_msb+1

  lda sprite_no+1
  and #1
  asl
  ;clc
  adc desired_xpos_right_lsb
  sta used_xpos_right_lsb+1
  lda desired_xpos_right_msb
  adc #0
  sta used_xpos_right_msb+1

; https://ist.uwaterloo.ca/~schepers/MJK/ascii/VIC-Article.txt
;The X coordinates run up to $1ff (only $1f7 on the 6569)
;within a line, then comes X coordinate 0.

; Default, place them all outside screen:
  lda #$80
  sta $d000
  sta $d002
  sta $d004
  sta $d006
  sta $d008
  sta $d00a
  sta $d00c
  lda #$7f
  sta $d010

; Start with placing the left torus, starting with sprite #6 at the desired position:
  ldy #$c
set_yet_another_sprite_x:
used_xpos_left_lsb:
  lda #0
  clc
  adc sprite_offsets_left,y
  sta $d000,y
used_xpos_left_msb:
  lda #0
  adc sprite_offsets_left+1,y
  bmi not_visible
  cmp #2
  bcs not_visible
  sec
  jmp visible
not_visible:
  clc
visible:
  bcc done_with_left
;  rol $d015
  sta the_msb+1

  lda $d000,y
  sec
  sbc #$10
  sta $d000,y
the_msb:
  lda #0
  sbc #0
;if this gets negative, we should subtract another $08 from the $d000-position.
  bpl no_extra_sub
  pha
  lda $d000,y
  sec
  sbc #8
  sta $d000,y
  pla
no_extra_sub
  cmp #1
  rol $d010
  dey
  dey
  bpl set_yet_another_sprite_x

done_with_left:
;When we come here, y is either $c = no visible sprites from left                      $d010 needs to be shifted 0 steps to the left
;                               $a = 1 visible sprite from left (spr #6)               $d010 needs to be shifted 6 steps to the left
;                               $8 = 2 visible sprites from left (spr #6,5)            $d010 needs to be shifted 5 steps to the left
;                               $6 = 3 visible sprites from left (spr #6,5,4)          $d010 needs to be shifted 4 steps to the left
;                               $4 = 4 visible sprites from left (spr #6,5,4,3)        $d010 needs to be shifted 3 steps to the left
;                               $2 = 5 visible sprites from left (spr #6,5,4,3,2)      $d010 needs to be shifted 2 steps to the left
;                               $0 = 6 visible sprites from left (spr #6,5,4,3,2,1)    $d010 needs to be shifted 1 steps to the left
;                               $fe = 7 visible sprites from left (spr #6,5,4,3,2,1,0) $d010 needs to be shifted 0 steps to the left

  tya
  bmi no_need_to_fix_anything_left
;The last "out-of-screen"-sprite, make sure that the $d000-value we wrote above gets "unwritten"
  lda #$ff
  sta $d000,y
shift_more_left:
  sec
  rol $d010
  dey
  dey
  bpl shift_more_left
no_need_to_fix_anything_left:


;  lda desired_xpos_left_lsb
;  clc
;  adc #1
;  sta desired_xpos_left_lsb
;  lda desired_xpos_left_msb
;  adc #0
;  and #$3
;  sta desired_xpos_left_msb
;
;  lda desired_xpos_right_lsb
;  sec
;  sbc #1
;  sta desired_xpos_right_lsb
;  lda desired_xpos_right_msb
;  sbc #0
;  and #$1
;  sta desired_xpos_right_msb



; Now place the right torus, starting with sprite #0 at the desired position
  lda #$ff
  sta right_d010+1
  ldy #$0
set_yet_another_sprite_x_right:
used_xpos_right_lsb:
  lda #0
  clc
  adc sprite_offsets_right,y
  sta d000_lsb_right+1
used_xpos_right_msb:
  lda #0
  adc sprite_offsets_right+1,y
  cmp #1
  beq check_if_were_done
  clc
  ror right_d010+1
  jmp visible2
check_if_were_done:
  sec
  ror right_d010+1
d000_lsb_right:
  lda #0
  cmp #$60
  bcs done_with_right
visible2:
  lda d000_lsb_right+1
  sta $d000,y
  iny
  iny
  cpy #$e
  bne set_yet_another_sprite_x_right
done_with_right:

right_d010:
  lda #0
shift_d010_correctly:
  cpy #$0e
  beq done_shifting_d010
  sec
  ror
  iny
  iny
  bne shift_d010_correctly
done_shifting_d010:
  and $d010
  sta $d010


;Make sure that sprites are not enabled by mistake in the upper border:
  lda #$00
  sta $d015

  ;Add the last sprite to cover the border between the two rotating fields.
spriteshadow = $4100
spriteshadow_x:
  ldy #$0
  sty $d00e

  lda #<((spriteshadow-$4000) / $40)
  sta screen0+$3ff
  lda #$0
  sta $d02e
  lda #$00
  sta $d01b
  lda #$7f
  sta $d01c
  lda $d010
  and #$7f
  sta $d010

  rts

mask0: !byte $ff
mask1: !byte $ff
mask2: !byte $ff
mask3: !byte $ff
mask4: !byte $ff


;global_offset = $feb0
global_offset_left = $feb0
sprite_offsets_left:
  !byte <(global_offset_left + $30*0)
  !byte >(global_offset_left + $30*0)
  !byte <(global_offset_left + $30*1)
  !byte >(global_offset_left + $30*1)
  !byte <(global_offset_left + $30*2)
  !byte >(global_offset_left + $30*2)
  !byte <(global_offset_left + $30*3)
  !byte >(global_offset_left + $30*3)
  !byte <(global_offset_left + $30*4)
  !byte >(global_offset_left + $30*4)
  !byte <(global_offset_left + $30*5)
  !byte >(global_offset_left + $30*5)
  !byte <(global_offset_left + $30*6)
  !byte >(global_offset_left + $30*6)
; This decides the margin between the toruses. $ffe4 does not work. $0000 works, but the toruses don't touch:
global_offset_right = $ffe6
sprite_offsets_right:
  !byte <(global_offset_right + $30*0)
  !byte >(global_offset_right + $30*0)
  !byte <(global_offset_right + $30*1)
  !byte >(global_offset_right + $30*1)
  !byte <(global_offset_right + $30*2)
  !byte >(global_offset_right + $30*2)
  !byte <(global_offset_right + $30*3)
  !byte >(global_offset_right + $30*3)
  !byte <(global_offset_right + $30*4)
  !byte >(global_offset_right + $30*4)
  !byte <(global_offset_right + $30*5)
  !byte >(global_offset_right + $30*5)
  !byte <(global_offset_right + $30*6)
  !byte >(global_offset_right + $30*6)
;sprite_offsets:
;  !byte <(global_offset + $30*0)
;  !byte >(global_offset + $30*0)
;  !byte <(global_offset + $30*1)
;  !byte >(global_offset + $30*1)
;  !byte <(global_offset + $30*2)
;  !byte >(global_offset + $30*2)
;  !byte <(global_offset + $30*3)
;  !byte >(global_offset + $30*3)
;  !byte <(global_offset + $30*4)
;  !byte >(global_offset + $30*4)
;  !byte <(global_offset + $30*5)
;  !byte >(global_offset + $30*5)
;  !byte <(global_offset + $30*6)
;  !byte >(global_offset + $30*6)
;  !byte <(global_offset + $30*7)
;  !byte >(global_offset + $30*7)



irq_0b:
  pha
;; stable irq through timer dc04:
;!ifndef DISABLE_STABLE {
;  lda $dc04
;  eor #7
;  and #7
;  sta *+4
;  bpl *+2
;  lda #$a9
;  lda #$a9
;  lda $eaa5
;}
  lda #$ff
  sta $d015

irqpos1:
  lda #$5c
  sta $d012
  lda #<irq_1
  sta $fffe
  lda #>irq_1
  sta $ffff
  asl $d019
  pla
  rti



irq_1:
  pha
;; stable irq through timer dc04:
;!ifndef DISABLE_STABLE {
;  lda $dc04
;  eor #7
;  and #7
;  sta *+4
;  bpl *+2
;  lda #$a9
;  lda #$a9
;  lda $eaa5
;}
sprypos1:
  lda #$5f
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f
irqpos2:
  lda #$70
  sta $d012
spritepoi_1:
  lda #first_sprite_no + $04
  sta screen0+$3f8
  clc
  adc #1
  sta screen0+$3f9
  adc #1
  sta screen0+$3fa
  adc #1
  sta screen0+$3fb
  adc #1
  sta screen0+$3fc
  adc #1
  sta screen0+$3fd
  adc #1
  sta screen0+$3fe
  lda #<irq_2
  sta $fffe
  lda #>irq_2
  sta $ffff
  asl $d019
  pla
  rti

irq_2:
  pha
;; stable irq through timer dc04:
;!ifndef DISABLE_STABLE {
;  lda $dc04
;  eor #7
;  and #7
;  sta *+4
;  bpl *+2
;  lda #$a9
;  lda #$a9
;  lda $eaa5
;}
sprypos2:
  lda #$74
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f
irqpos3:
  lda #$84
  sta $d012
spritepoi_2:
  lda #first_sprite_no + $04
  sta screen0+$3f8
  clc
  adc #1
  sta screen0+$3f9
  adc #1
  sta screen0+$3fa
  adc #1
  sta screen0+$3fb
  adc #1
  sta screen0+$3fc
  adc #1
  sta screen0+$3fd
  adc #1
  sta screen0+$3fe
  lda #<irq_3
  sta $fffe
  lda #>irq_3
  sta $ffff
  asl $d019
  pla
  rti

irq_3:
  pha
;; stable irq through timer dc04:
;!ifndef DISABLE_STABLE {
;  lda $dc04
;  eor #7
;  and #7
;  sta *+4
;  bpl *+2
;  lda #$a9
;  lda #$a9
;  lda $eaa5
;}
sprypos3:
  lda #$89
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f
irqpos4:
  lda #$98
  sta $d012

  txa
  pha
  tya
  pha

spritepoi_3:
  ldx #first_sprite_no + $04
  stx screen0+$3f8
  inx
  stx screen0+$3f9
  inx
  stx screen0+$3fa
  inx
  stx screen0+$3fb
  inx
  stx screen0+$3fc
  inx
  stx screen0+$3fd
  inx
  stx screen0+$3fe
  lda #<irq_4
  sta $fffe
  lda #>irq_4
  sta $ffff
  asl $d019
  cli

;  lda #2
;  sta $d020
!ifdef release {
  jsr link_music_play
} else {
  jsr music+3
}
  jsr d800_scroller_part2
;  lda #$a
;  sta $d020

  pla
  tay
  pla
  tax
  pla
  rti

irq_4:
  pha
;; stable irq through timer dc04:
;!ifndef DISABLE_STABLE {
;  lda $dc04
;  eor #7
;  and #7
;  sta *+4
;  bpl *+2
;  lda #$a9
;  lda #$a9
;  lda $eaa5
;}
sprypos4:
  lda #$9e
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f
irqpos5:
  lda #$ac
  sta $d012
spritepoi_4:
  lda #first_sprite_no + $04
  sta screen0+$3f8
  clc
  adc #1
  sta screen0+$3f9
  adc #1
  sta screen0+$3fa
  adc #1
  sta screen0+$3fb
  adc #1
  sta screen0+$3fc
  adc #1
  sta screen0+$3fd
  adc #1
  sta screen0+$3fe

  lda #$fa
  sta $d012
  lda #<irq_0
  sta $fffe
  lda #>irq_0
  sta $ffff
  asl $d019
  pla
  rti



; HOW HIGH CAN YOU GET?      TURN DISK
; HOW LOW  CAN YOU FALL?     TURN DISK
;
;                                                                                                                                                                                                                                                                                xx  xx xx xxxxxx xx  xx                                                                                                                                                                                                                                                                                 
;                                                                                                                                                                                                                                                                                xx  xx xx xx     xx  xx                                                                                                                                                                                                                                                                                 
;                                                                                                                                                                                                                                                                                xxxxxx xx xx xxx xxxxxx                                                                                                                                                                                                                                                                                 
;                                                                                                                                                                                                                                                                                xx  xx xx xx  xx xx  xx                                                                                                                                                                                                                                                                                 
;                                                                                                                                                                                                                                                                                xx  xx xx xxxxxx xx  xx                                                                                                                                                                                                                                                                                 
;                                                                                                                                                                                                                                                                                6                                                                                                                                                                                                                                                                                                       xxxxxx xxxxxx xxxxxx
;                                                                                                                                                                                                                                                                                C                                                                                                                                                                                                                                                                                                       xx     xx       xx  
;                                                                                                                                                                                                                                                                                5                                                                                                                                                                                                                                                                                                       xx xxx xxxx     xx  
;                                                                                                                                                                                                                                                                                3                                                                                                                                                                                                                                                                                                       xx  xx xx       xx  
;                                                                                                                                                                                                                                                                                7                                                                                                                                                                                                                                                                                                       xxxxxx xxxxxx   xx  
;                                                                                                                                                                                                                                                                                1                                                                                                                                                                                                                                                                                                       
;                                                                                                                                                                                                                                                                                xx     xxxxx0x  xx   xx                                                                                                                                                                                                                                                                                 xxxxx  xxx  xx   xx  
;                                                                                                                                                                                                                                                                                xx    xxxxx0xxx xx x xx                                                                                                                                                                                                                                                                                 xx    xx xx xx   xx  
;                                                                                                                                                                                                                                                                                xx    xxxx0xxxx xxx xxx                                                                                                                                                                                                                                                                                 xxxx  xxxxx xx   xx  
;                                                                                                                                                                                                                                                                                xx    xxx0xxxxx xx   xx                                                                                                                                                                                                                                                                                 xx    xx xx xx   xx  
;                                                                                                                                                                                                                                                                                xxxxx  x0xxxxx  x     x                                                                                                                                                                                                                                                                                 xx    xx xx xxxx xxxx

  !align 255,0,0
row0:
  !byte $fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$47,$47,$fb,$fb,$47,$47,$fb,$fb,$47,$47,$47,$47,$fb,$fb,$47,$47,$fb,$fb,$fb,$47,$47,$fb,$fb,$fb,$fb,$47,$47,$fb,$fb,$f7,$f7,$fb,$67,$e7,$5b,$4b,$77,$17,$77,$f7,$f7,$4b,$47,$f7,$fb,$fb,$47,$47,$fb,$fb,$fb,$fb,$fb,$47,$47,$47,$47,$fb,$fb,$fb,$47,$47,$47,$47,$fb,$fb,$47,$fb,$fb,$fb,$47,$47,$fb,$fb,$fb,$47,$47,$fb,$fb,$47,$47,$fb,$fb,$47,$47,$47,$47,$fb,$fb,$47,$47,$fb,$fb,$47,$47,$fb,$fb,$fb,$fb,$4b,$47,$47,$47,$47,$fb,$fb,$47,$47,$47,$f7,$f7,$47,$4b,$f7,$f7,$f7,$47,$47,$f7,$fb,$fb,$47,$47,$47,$47,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$47,$47,$47,$47,$47,$47,$fb,$47,$47,$fb,$fb,$47,$47,$fb,$47,$47,$47,$47,$47,$47,$fb,$47,$fb,$fb,$fb,$47,$47,$fb,$fb,$fb,$fb,$47,$47,$47,$47,$47,$fb,$fb,$47,$47,$fb,$47,$47,$47,$47,$47,$47,$fb,$47,$47,$fb,$fb,$47,$47,$fb,$47,$47,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb
row1:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  !byte $fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$00,$47,$47,$fb,$47,$47,$fb,$47,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$fb,$f7,$f7,$60,$e7,$57,$40,$77,$17,$70,$40,$50,$f0,$40,$47,$07,$40,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$00,$47,$47,$fb,$47,$47,$00,$00,$47,$47,$fb,$47,$47,$fb,$fb,$47,$47,$00,$fb,$fb,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$00,$47,$47,$fb,$47,$47,$00,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$00,$00,$00,$4b,$47,$07,$40,$40,$f0,$40,$40,$0b,$f0,$f7,$47,$40,$00,$f0,$47,$47,$00,$00,$47,$47,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$00,$47,$47,$00,$00,$00,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$00,$47,$47,$00,$47,$47,$fb,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$fb,$47,$47,$fb,$47,$47,$00,$47,$47,$00,$00,$00,$00,$00,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb
row2:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  !byte $fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$47,$47,$47,$47,$47,$47,$00,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$47,$00,$47,$47,$47,$00,$fb,$fb,$fb,$47,$47,$07,$f7,$f7,$f7,$e0,$57,$47,$70,$17,$77,$40,$57,$e7,$07,$4b,$47,$47,$07,$47,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$fb,$fb,$00,$00,$47,$47,$47,$47,$47,$47,$00,$47,$47,$47,$fb,$47,$47,$00,$fb,$fb,$47,$47,$47,$47,$47,$47,$00,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$40,$47,$f7,$f7,$4b,$47,$47,$47,$47,$0b,$4b,$4b,$0b,$fb,$f7,$47,$40,$0b,$fb,$fb,$00,$00,$47,$47,$00,$00,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$47,$47,$00,$fb,$fb,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$47,$47,$47,$00,$00,$47,$47,$47,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$47,$47,$47,$47,$47,$47,$fb,$47,$47,$47,$47,$47,$00,$00,$47,$47,$00,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb
row3:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  !byte $fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$47,$47,$00,$00,$47,$47,$00,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$fb,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$f0,$f7,$f7,$50,$47,$77,$10,$77,$47,$50,$eb,$67,$07,$40,$47,$07,$00,$f0,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$fb,$47,$47,$fb,$47,$47,$00,$00,$47,$47,$00,$47,$47,$00,$47,$47,$47,$00,$fb,$fb,$fb,$00,$47,$47,$00,$00,$00,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$0b,$07,$f7,$40,$47,$07,$40,$40,$00,$4b,$4b,$0b,$fb,$f7,$47,$40,$0b,$fb,$fb,$fb,$fb,$fb,$00,$00,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$47,$47,$00,$fb,$fb,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$00,$47,$47,$fb,$47,$47,$00,$47,$47,$47,$00,$fb,$fb,$fb,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$fb,$00,$00,$00,$47,$47,$00,$47,$47,$00,$00,$47,$47,$fb,$fb,$00,$00,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb
row4:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  !byte $fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$47,$47,$00,$fb,$47,$47,$00,$fb,$47,$47,$47,$47,$00,$00,$47,$00,$00,$fb,$fb,$fb,$47,$00,$fb,$fb,$fb,$47,$47,$40,$4b,$47,$f7,$f0,$77,$17,$70,$4b,$57,$e7,$67,$07,$07,$40,$07,$07,$f0,$fb,$f7,$47,$00,$fb,$fb,$fb,$fb,$47,$47,$47,$47,$00,$00,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$fb,$47,$47,$00,$fb,$fb,$fb,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$47,$47,$00,$00,$fb,$47,$47,$47,$47,$00,$00,$fb,$fb,$fb,$4b,$47,$07,$f7,$f7,$f7,$40,$47,$07,$47,$47,$07,$47,$4b,$4b,$4b,$f7,$47,$40,$4b,$4b,$fb,$fb,$47,$47,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$47,$47,$00,$00,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$00,$fb,$47,$47,$00,$fb,$fb,$fb,$47,$47,$47,$47,$47,$00,$00,$47,$47,$00,$47,$47,$47,$47,$47,$47,$00,$47,$47,$00,$fb,$47,$47,$00,$47,$47,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb
row5:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  !byte $fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$00,$00,$fb,$fb,$00,$00,$fb,$fb,$00,$00,$00,$00,$fb,$fb,$00,$fb,$fb,$fb,$fb,$fb,$00,$fb,$fb,$fb,$fb,$00,$00,$0b,$0b,$00,$f0,$fb,$00,$00,$0b,$00,$00,$00,$00,$f0,$f0,$0b,$f0,$f0,$fb,$fb,$f0,$00,$fb,$fb,$fb,$fb,$fb,$00,$00,$00,$00,$fb,$fb,$00,$00,$fb,$fb,$00,$00,$fb,$00,$00,$fb,$fb,$00,$00,$fb,$fb,$fb,$fb,$fb,$00,$00,$fb,$fb,$fb,$fb,$00,$00,$00,$00,$fb,$fb,$fb,$00,$00,$00,$00,$fb,$fb,$fb,$fb,$fb,$0b,$00,$f0,$f0,$f0,$f0,$0b,$00,$f0,$00,$00,$f0,$00,$0b,$0b,$0b,$f0,$00,$0b,$0b,$0b,$fb,$fb,$00,$00,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$00,$00,$fb,$fb,$fb,$fb,$00,$00,$00,$00,$fb,$fb,$00,$00,$fb,$fb,$00,$00,$fb,$00,$00,$fb,$fb,$00,$00,$fb,$fb,$fb,$fb,$00,$00,$00,$00,$00,$fb,$fb,$00,$00,$fb,$00,$00,$00,$00,$00,$00,$fb,$00,$00,$fb,$fb,$00,$00,$fb,$00,$00,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb



d800_scroller_part2:
  lda coloffset_x_d016+1
  cmp #$7
  beq do_move_cols2
  jmp update_split2
do_move_cols2:
  lda $d800 + 9*40 +       1
  sta $d800 + 9*40 +  0     
  lda $d800 + 9*40 +       2
  sta $d800 + 9*40 +  1     
  lda $d800 + 9*40 +       3
  sta $d800 + 9*40 +  2     
  lda $d800 + 9*40 +       4
  sta $d800 + 9*40 +  3     
  lda $d800 + 9*40 +       5
  sta $d800 + 9*40 +  4     
  lda $d800 + 9*40 +       6
  sta $d800 + 9*40 +  5     
  lda $d800 + 9*40 +       7
  sta $d800 + 9*40 +  6     
  lda $d800 + 9*40 +       8
  sta $d800 + 9*40 +  7     
  lda $d800 + 9*40 +       9
  sta $d800 + 9*40 +  8     
  lda $d800 + 9*40 +      10
  sta $d800 + 9*40 +  9     
  lda $d800 + 9*40 +      11
  sta $d800 + 9*40 + 10     
  lda $d800 + 9*40 +      12
  sta $d800 + 9*40 + 11     
  lda $d800 + 9*40 +      13
  sta $d800 + 9*40 + 12     
  lda $d800 + 9*40 +      14
  sta $d800 + 9*40 + 13     
  lda $d800 + 9*40 +      15
  sta $d800 + 9*40 + 14     
  lda $d800 + 9*40 +      16
  sta $d800 + 9*40 + 15     
  lda $d800 + 9*40 +      17
  sta $d800 + 9*40 + 16     
  lda $d800 + 9*40 +      18
  sta $d800 + 9*40 + 17     
  lda $d800 + 9*40 +      19
  sta $d800 + 9*40 + 18     
  lda $d800 + 9*40 +      20
  sta $d800 + 9*40 + 19     
  lda $d800 + 9*40 +      21
  sta $d800 + 9*40 + 20     
  lda $d800 + 9*40 +      22
  sta $d800 + 9*40 + 21     
  lda $d800 + 9*40 +      23
  sta $d800 + 9*40 + 22     
  lda $d800 + 9*40 +      24
  sta $d800 + 9*40 + 23     
  lda $d800 + 9*40 +      25
  sta $d800 + 9*40 + 24     
  lda $d800 + 9*40 +      26
  sta $d800 + 9*40 + 25     
  lda $d800 + 9*40 +      27
  sta $d800 + 9*40 + 26     
  lda $d800 + 9*40 +      28
  sta $d800 + 9*40 + 27     
  lda $d800 + 9*40 +      29
  sta $d800 + 9*40 + 28     
  lda $d800 + 9*40 +      30
  sta $d800 + 9*40 + 29     
  lda $d800 + 9*40 +      31
  sta $d800 + 9*40 + 30     
  lda $d800 + 9*40 +      32
  sta $d800 + 9*40 + 31     
  lda $d800 + 9*40 +      33
  sta $d800 + 9*40 + 32     
  lda $d800 + 9*40 +      34
  sta $d800 + 9*40 + 33     
  lda $d800 + 9*40 +      35
  sta $d800 + 9*40 + 34     
  lda $d800 + 9*40 +      36
  sta $d800 + 9*40 + 35     
  lda $d800 + 9*40 +      37
  sta $d800 + 9*40 + 36     
  lda $d800 + 9*40 +      38
  sta $d800 + 9*40 + 37     

  lda $d800 + 10*40 +       1
  sta $d800 + 10*40 +  0     
  lda $d800 + 10*40 +       2
  sta $d800 + 10*40 +  1     
  lda $d800 + 10*40 +       3
  sta $d800 + 10*40 +  2     
  lda $d800 + 10*40 +       4
  sta $d800 + 10*40 +  3     
  lda $d800 + 10*40 +       5
  sta $d800 + 10*40 +  4     
  lda $d800 + 10*40 +       6
  sta $d800 + 10*40 +  5     
  lda $d800 + 10*40 +       7
  sta $d800 + 10*40 +  6     
  lda $d800 + 10*40 +       8
  sta $d800 + 10*40 +  7     
  lda $d800 + 10*40 +       9
  sta $d800 + 10*40 +  8     
  lda $d800 + 10*40 +      10
  sta $d800 + 10*40 +  9     
  lda $d800 + 10*40 +      11
  sta $d800 + 10*40 + 10     
  lda $d800 + 10*40 +      12
  sta $d800 + 10*40 + 11     
  lda $d800 + 10*40 +      13
  sta $d800 + 10*40 + 12     
  lda $d800 + 10*40 +      14
  sta $d800 + 10*40 + 13     
  lda $d800 + 10*40 +      15
  sta $d800 + 10*40 + 14     
  lda $d800 + 10*40 +      16
  sta $d800 + 10*40 + 15     
  lda $d800 + 10*40 +      17
  sta $d800 + 10*40 + 16     
  lda $d800 + 10*40 +      18
  sta $d800 + 10*40 + 17     
  lda $d800 + 10*40 +      19
  sta $d800 + 10*40 + 18     
  lda $d800 + 10*40 +      20
  sta $d800 + 10*40 + 19     
  lda $d800 + 10*40 +      21
  sta $d800 + 10*40 + 20     
  lda $d800 + 10*40 +      22
  sta $d800 + 10*40 + 21     
  lda $d800 + 10*40 +      23
  sta $d800 + 10*40 + 22     
  lda $d800 + 10*40 +      24
  sta $d800 + 10*40 + 23     
  lda $d800 + 10*40 +      25
  sta $d800 + 10*40 + 24     
  lda $d800 + 10*40 +      26
  sta $d800 + 10*40 + 25     
  lda $d800 + 10*40 +      27
  sta $d800 + 10*40 + 26     
  lda $d800 + 10*40 +      28
  sta $d800 + 10*40 + 27     
  lda $d800 + 10*40 +      29
  sta $d800 + 10*40 + 28     
  lda $d800 + 10*40 +      30
  sta $d800 + 10*40 + 29     
  lda $d800 + 10*40 +      31
  sta $d800 + 10*40 + 30     
  lda $d800 + 10*40 +      32
  sta $d800 + 10*40 + 31     
  lda $d800 + 10*40 +      33
  sta $d800 + 10*40 + 32     
  lda $d800 + 10*40 +      34
  sta $d800 + 10*40 + 33     
  lda $d800 + 10*40 +      35
  sta $d800 + 10*40 + 34     
  lda $d800 + 10*40 +      36
  sta $d800 + 10*40 + 35     
  lda $d800 + 10*40 +      37
  sta $d800 + 10*40 + 36     
  lda $d800 + 10*40 +      38
  sta $d800 + 10*40 + 37     

  lda $d800 + 11*40 +       1
  sta $d800 + 11*40 +  0     
  lda $d800 + 11*40 +       2
  sta $d800 + 11*40 +  1     
  lda $d800 + 11*40 +       3
  sta $d800 + 11*40 +  2     
  lda $d800 + 11*40 +       4
  sta $d800 + 11*40 +  3     
  lda $d800 + 11*40 +       5
  sta $d800 + 11*40 +  4     
  lda $d800 + 11*40 +       6
  sta $d800 + 11*40 +  5     
  lda $d800 + 11*40 +       7
  sta $d800 + 11*40 +  6     
  lda $d800 + 11*40 +       8
  sta $d800 + 11*40 +  7     
  lda $d800 + 11*40 +       9
  sta $d800 + 11*40 +  8     
  lda $d800 + 11*40 +      10
  sta $d800 + 11*40 +  9     
  lda $d800 + 11*40 +      11
  sta $d800 + 11*40 + 10     
  lda $d800 + 11*40 +      12
  sta $d800 + 11*40 + 11     
  lda $d800 + 11*40 +      13
  sta $d800 + 11*40 + 12     
  lda $d800 + 11*40 +      14
  sta $d800 + 11*40 + 13     
  lda $d800 + 11*40 +      15
  sta $d800 + 11*40 + 14     
  lda $d800 + 11*40 +      16
  sta $d800 + 11*40 + 15     
  lda $d800 + 11*40 +      17
  sta $d800 + 11*40 + 16     
  lda $d800 + 11*40 +      18
  sta $d800 + 11*40 + 17     
  lda $d800 + 11*40 +      19
  sta $d800 + 11*40 + 18     
  lda $d800 + 11*40 +      20
  sta $d800 + 11*40 + 19     
  lda $d800 + 11*40 +      21
  sta $d800 + 11*40 + 20     
  lda $d800 + 11*40 +      22
  sta $d800 + 11*40 + 21     
  lda $d800 + 11*40 +      23
  sta $d800 + 11*40 + 22     
  lda $d800 + 11*40 +      24
  sta $d800 + 11*40 + 23     
  lda $d800 + 11*40 +      25
  sta $d800 + 11*40 + 24     
  lda $d800 + 11*40 +      26
  sta $d800 + 11*40 + 25     
  lda $d800 + 11*40 +      27
  sta $d800 + 11*40 + 26     
  lda $d800 + 11*40 +      28
  sta $d800 + 11*40 + 27     
  lda $d800 + 11*40 +      29
  sta $d800 + 11*40 + 28     
  lda $d800 + 11*40 +      30
  sta $d800 + 11*40 + 29     
  lda $d800 + 11*40 +      31
  sta $d800 + 11*40 + 30     
  lda $d800 + 11*40 +      32
  sta $d800 + 11*40 + 31     
  lda $d800 + 11*40 +      33
  sta $d800 + 11*40 + 32     
  lda $d800 + 11*40 +      34
  sta $d800 + 11*40 + 33     
  lda $d800 + 11*40 +      35
  sta $d800 + 11*40 + 34     
  lda $d800 + 11*40 +      36
  sta $d800 + 11*40 + 35     
  lda $d800 + 11*40 +      37
  sta $d800 + 11*40 + 36     
  lda $d800 + 11*40 +      38
  sta $d800 + 11*40 + 37     

  lda $d800 + 12*40 +       1
  sta $d800 + 12*40 +  0     
  lda $d800 + 12*40 +       2
  sta $d800 + 12*40 +  1     
  lda $d800 + 12*40 +       3
  sta $d800 + 12*40 +  2     
  lda $d800 + 12*40 +       4
  sta $d800 + 12*40 +  3     
  lda $d800 + 12*40 +       5
  sta $d800 + 12*40 +  4     
  lda $d800 + 12*40 +       6
  sta $d800 + 12*40 +  5     
  lda $d800 + 12*40 +       7
  sta $d800 + 12*40 +  6     
  lda $d800 + 12*40 +       8
  sta $d800 + 12*40 +  7     
  lda $d800 + 12*40 +       9
  sta $d800 + 12*40 +  8     
  lda $d800 + 12*40 +      10
  sta $d800 + 12*40 +  9     
  lda $d800 + 12*40 +      11
  sta $d800 + 12*40 + 10     
  lda $d800 + 12*40 +      12
  sta $d800 + 12*40 + 11     
  lda $d800 + 12*40 +      13
  sta $d800 + 12*40 + 12     
  lda $d800 + 12*40 +      14
  sta $d800 + 12*40 + 13     
  lda $d800 + 12*40 +      15
  sta $d800 + 12*40 + 14     
  lda $d800 + 12*40 +      16
  sta $d800 + 12*40 + 15     
  lda $d800 + 12*40 +      17
  sta $d800 + 12*40 + 16     
  lda $d800 + 12*40 +      18
  sta $d800 + 12*40 + 17     
  lda $d800 + 12*40 +      19
  sta $d800 + 12*40 + 18     
  lda $d800 + 12*40 +      20
  sta $d800 + 12*40 + 19     
  lda $d800 + 12*40 +      21
  sta $d800 + 12*40 + 20     
  lda $d800 + 12*40 +      22
  sta $d800 + 12*40 + 21     
  lda $d800 + 12*40 +      23
  sta $d800 + 12*40 + 22     
  lda $d800 + 12*40 +      24
  sta $d800 + 12*40 + 23     
  lda $d800 + 12*40 +      25
  sta $d800 + 12*40 + 24     
  lda $d800 + 12*40 +      26
  sta $d800 + 12*40 + 25     
  lda $d800 + 12*40 +      27
  sta $d800 + 12*40 + 26     
  lda $d800 + 12*40 +      28
  sta $d800 + 12*40 + 27     
  lda $d800 + 12*40 +      29
  sta $d800 + 12*40 + 28     
  lda $d800 + 12*40 +      30
  sta $d800 + 12*40 + 29     
  lda $d800 + 12*40 +      31
  sta $d800 + 12*40 + 30     
  lda $d800 + 12*40 +      32
  sta $d800 + 12*40 + 31     
  lda $d800 + 12*40 +      33
  sta $d800 + 12*40 + 32     
  lda $d800 + 12*40 +      34
  sta $d800 + 12*40 + 33     
  lda $d800 + 12*40 +      35
  sta $d800 + 12*40 + 34     
  lda $d800 + 12*40 +      36
  sta $d800 + 12*40 + 35     
  lda $d800 + 12*40 +      37
  sta $d800 + 12*40 + 36     
  lda $d800 + 12*40 +      38
  sta $d800 + 12*40 + 37     

  lda $d800 + 13*40 +       1
  sta $d800 + 13*40 +  0     
  lda $d800 + 13*40 +       2
  sta $d800 + 13*40 +  1     
  lda $d800 + 13*40 +       3
  sta $d800 + 13*40 +  2     
  lda $d800 + 13*40 +       4
  sta $d800 + 13*40 +  3     
  lda $d800 + 13*40 +       5
  sta $d800 + 13*40 +  4     
  lda $d800 + 13*40 +       6
  sta $d800 + 13*40 +  5     
  lda $d800 + 13*40 +       7
  sta $d800 + 13*40 +  6     
  lda $d800 + 13*40 +       8
  sta $d800 + 13*40 +  7     
  lda $d800 + 13*40 +       9
  sta $d800 + 13*40 +  8     
  lda $d800 + 13*40 +      10
  sta $d800 + 13*40 +  9     
  lda $d800 + 13*40 +      11
  sta $d800 + 13*40 + 10     
  lda $d800 + 13*40 +      12
  sta $d800 + 13*40 + 11     
  lda $d800 + 13*40 +      13
  sta $d800 + 13*40 + 12     
  lda $d800 + 13*40 +      14
  sta $d800 + 13*40 + 13     
  lda $d800 + 13*40 +      15
  sta $d800 + 13*40 + 14     
  lda $d800 + 13*40 +      16
  sta $d800 + 13*40 + 15     
  lda $d800 + 13*40 +      17
  sta $d800 + 13*40 + 16     
  lda $d800 + 13*40 +      18
  sta $d800 + 13*40 + 17     
  lda $d800 + 13*40 +      19
  sta $d800 + 13*40 + 18     
  lda $d800 + 13*40 +      20
  sta $d800 + 13*40 + 19     
  lda $d800 + 13*40 +      21
  sta $d800 + 13*40 + 20     
  lda $d800 + 13*40 +      22
  sta $d800 + 13*40 + 21     
  lda $d800 + 13*40 +      23
  sta $d800 + 13*40 + 22     
  lda $d800 + 13*40 +      24
  sta $d800 + 13*40 + 23     
  lda $d800 + 13*40 +      25
  sta $d800 + 13*40 + 24     
  lda $d800 + 13*40 +      26
  sta $d800 + 13*40 + 25     
  lda $d800 + 13*40 +      27
  sta $d800 + 13*40 + 26     
  lda $d800 + 13*40 +      28
  sta $d800 + 13*40 + 27     
  lda $d800 + 13*40 +      29
  sta $d800 + 13*40 + 28     
  lda $d800 + 13*40 +      30
  sta $d800 + 13*40 + 29     
  lda $d800 + 13*40 +      31
  sta $d800 + 13*40 + 30     
  lda $d800 + 13*40 +      32
  sta $d800 + 13*40 + 31     
  lda $d800 + 13*40 +      33
  sta $d800 + 13*40 + 32     
  lda $d800 + 13*40 +      34
  sta $d800 + 13*40 + 33     
  lda $d800 + 13*40 +      35
  sta $d800 + 13*40 + 34     
  lda $d800 + 13*40 +      36
  sta $d800 + 13*40 + 35     
  lda $d800 + 13*40 +      37
  sta $d800 + 13*40 + 36     
  lda $d800 + 13*40 +      38
  sta $d800 + 13*40 + 37     

;  lda #1
;  sta $d020

  lda $d800 + 14*40 +       1
  sta $d800 + 14*40 +  0     
  lda $d800 + 14*40 +       2
  sta $d800 + 14*40 +  1     
  lda $d800 + 14*40 +       3
  sta $d800 + 14*40 +  2     
  lda $d800 + 14*40 +       4
  sta $d800 + 14*40 +  3     
  lda $d800 + 14*40 +       5
  sta $d800 + 14*40 +  4     
  lda $d800 + 14*40 +       6
  sta $d800 + 14*40 +  5     
  lda $d800 + 14*40 +       7
  sta $d800 + 14*40 +  6     
  lda $d800 + 14*40 +       8
  sta $d800 + 14*40 +  7     
  lda $d800 + 14*40 +       9
  sta $d800 + 14*40 +  8     
  lda $d800 + 14*40 +      10
  sta $d800 + 14*40 +  9     
  lda $d800 + 14*40 +      11
  sta $d800 + 14*40 + 10     
  lda $d800 + 14*40 +      12
  sta $d800 + 14*40 + 11     
  lda $d800 + 14*40 +      13
  sta $d800 + 14*40 + 12     
  lda $d800 + 14*40 +      14
  sta $d800 + 14*40 + 13     
  lda $d800 + 14*40 +      15
  sta $d800 + 14*40 + 14     
  lda $d800 + 14*40 +      16
  sta $d800 + 14*40 + 15     
  lda $d800 + 14*40 +      17
  sta $d800 + 14*40 + 16     
  lda $d800 + 14*40 +      18
  sta $d800 + 14*40 + 17     
  lda $d800 + 14*40 +      19
  sta $d800 + 14*40 + 18     
  lda $d800 + 14*40 +      20
  sta $d800 + 14*40 + 19     
  lda $d800 + 14*40 +      21
  sta $d800 + 14*40 + 20     
  lda $d800 + 14*40 +      22
  sta $d800 + 14*40 + 21     
  lda $d800 + 14*40 +      23
  sta $d800 + 14*40 + 22     
  lda $d800 + 14*40 +      24
  sta $d800 + 14*40 + 23     
  lda $d800 + 14*40 +      25
  sta $d800 + 14*40 + 24     
  lda $d800 + 14*40 +      26
  sta $d800 + 14*40 + 25     
  lda $d800 + 14*40 +      27
  sta $d800 + 14*40 + 26     
  lda $d800 + 14*40 +      28
  sta $d800 + 14*40 + 27     
  lda $d800 + 14*40 +      29
  sta $d800 + 14*40 + 28     
  lda $d800 + 14*40 +      30
  sta $d800 + 14*40 + 29     
  lda $d800 + 14*40 +      31
  sta $d800 + 14*40 + 30     
  lda $d800 + 14*40 +      32
  sta $d800 + 14*40 + 31     
  lda $d800 + 14*40 +      33
  sta $d800 + 14*40 + 32     
  lda $d800 + 14*40 +      34
  sta $d800 + 14*40 + 33     
  lda $d800 + 14*40 +      35
  sta $d800 + 14*40 + 34     
  lda $d800 + 14*40 +      36
  sta $d800 + 14*40 + 35     
  lda $d800 + 14*40 +      37
  sta $d800 + 14*40 + 36     
  lda $d800 + 14*40 +      38
  sta $d800 + 14*40 + 37     

;  lda #$b
;  sta $d020

  lax coloffset_x+1
  sbx #-38
  ;clc
  ;adc #38
  ;tax
  lda row0,x
  sta $d800 + 9*40 + 38
  lda row1,x
  sta $d800 + 10*40 + 38
  lda row2,x
  sta $d800 + 11*40 + 38
  lda row3,x
  sta $d800 + 12*40 + 38
  lda row4,x
  sta $d800 + 13*40 + 38
  lda row5,x
  sta $d800 + 14*40 + 38

update_split2:
;  lda desired_d016
  lda $d016
  anc #$7
  eor #$7
  ;clc
  adc spriteshadow_x+1
  sec
  sbc #11
  bcs do_something_now2
  rts
do_something_now2:
  lsr
  lsr
  asr #$fe
  tay
  ;clc
  adc coloffset_x+1
  tax
  lda row0,x
  lsr
  lsr
  lsr
  lsr
  sta $d800 + 9*40,y
  lda row1,x
  lsr
  lsr
  lsr
  lsr
  sta $d800 + 10*40,y
  lda row2,x
  lsr
  lsr
  lsr
  lsr
  sta $d800 + 11*40,y
  lda row3,x
  lsr
  lsr
  lsr
  lsr
  sta $d800 + 12*40,y
  lda row4,x
  lsr
  lsr
  lsr
  lsr
  sta $d800 + 13*40,y
  lda row5,x
  lsr
  lsr
  lsr
  lsr
  sta $d800 + 14*40,y
  rts


; This is 240 bytes ended with a 0, that can be traversed with speeds 1,2,3,4,5,6 and still end up evenly on 240
torus_bounce_table:
  !byte 1, 4, 7, 11, 14, 17, 21, 24, 27, 31, 34, 37, 41, 44, 47, 50, 54, 57, 60, 63, 67, 70, 73, 76, 80, 83, 86, 89, 92, 95, 98, 101, 104, 107, 111, 114, 116, 119, 122, 125, 128, 131, 134, 137, 140, 142, 145, 148, 151, 153, 156, 159, 161, 164, 166, 169, 171, 174, 176, 179, 181, 183, 186, 188, 190, 192, 195, 197, 199, 201, 203, 205, 207, 209, 211, 213, 214, 216, 218, 220, 221, 223, 225, 226, 228, 229, 231, 232, 233, 235, 236, 237, 238, 240, 241, 242, 243, 244, 245, 246, 247, 247, 248, 249, 250, 250, 251, 251, 252, 253, 253, 253, 254, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 254, 254, 253, 253, 253, 252, 252, 251, 251, 250, 249, 248, 248, 247, 246, 245, 244, 243, 242, 241, 240, 239, 238, 236, 235, 234, 232, 231, 230, 228, 227, 225, 223, 222, 220, 219, 217, 215, 213, 211, 209, 208, 206, 204, 202, 199, 197, 195, 193, 191, 189, 186, 184, 182, 179, 177, 175, 172, 170, 167, 165, 162, 159, 157, 154, 151, 149, 146, 143, 141, 138, 135, 132, 129, 126, 123, 120, 117, 114, 111, 108, 105, 102, 99, 96, 93, 90, 87, 84, 81, 77, 74, 71, 68, 65, 61, 58, 55, 52, 48, 45, 42, 38, 35, 32, 28, 25, 22, 18, 15, 12, 8, 5, 2, 0




; charset0 = $4000-$40ff
; screen = $4400-$47ff
; charset1 = $4800-$48ff

  *= $4900
sprites:
  !bin "blender/pex_torus5_1.spr"
sprites2:
  !bin "blender/pex_torus5_2.spr"
sprites3:
  !bin "blender/pex_torus5_3.spr"
sprites4:
  !bin "blender/pex_torus5_4.spr"

  *= $6c00
;$6d00 - $7800 is free memory.


ghostsprites = $7a00  ; - $7dff

;late VIC-II luma
;0
;6, 9
;2, B
;4, 8
;C, E
;5, A
;3, F
;7, D
;1




; Ghostbyte is at $7fff
  *= $8000
the_anim:
  !byte $ff,$4e,$4e,$4c,$4c,$08,$00,$20,$20,$24,$fc,$fc,$e0,$c0,$ff,$ff
  !byte $ff,$40,$00,$7e,$fe,$e0,$e0,$ff,$7f,$00,$00,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$0e,$24,$e0,$f0,$f8,$f0,$e2,$e6,$cf,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$c0,$c0,$f9,$f9,$f9,$f9,$f9,$f8,$fc,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$fb,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$81,$81,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$00,$80,$fc,$f0,$80,$fc,$fc,$e0,$80,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$3e,$3c,$9c,$9c,$c9,$c9,$e1,$e3,$e3,$f7,$ff,$ff,$ff
  !byte $ff,$3f,$3f,$3d,$00,$04,$3c,$00,$00,$3c,$fc,$80,$80,$ff,$ff,$ff
  !byte $ce,$4e,$4c,$4c,$49,$49,$00,$20,$24,$2c,$fc,$fc,$fc,$e0,$c0,$ff
  !byte $ff,$40,$40,$fe,$f0,$e0,$fe,$7f,$20,$00,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$5e,$0e,$e4,$f0,$f1,$f0,$f0,$e6,$c7,$cf,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$c0,$c1,$f9,$f9,$f9,$f9,$f9,$f8,$fc,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$fb,$f1,$f9,$f9,$f9,$f9,$f9,$f9,$81,$81,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$80,$00,$fc,$fc,$80,$c4,$fc,$f8,$80,$cf,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$fe,$3c,$1c,$9c,$8c,$c9,$c9,$e1,$e3,$f3,$ff,$ff,$ff
  !byte $3f,$3f,$3f,$3f,$00,$00,$3c,$3c,$00,$c0,$fc,$fc,$00,$81,$ff,$ff
  !byte $4e,$4c,$4c,$49,$49,$43,$00,$24,$24,$fc,$fc,$fc,$fe,$fe,$e0,$e0
  !byte $c0,$40,$7e,$fe,$e0,$e0,$fe,$7e,$00,$01,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$0e,$04,$e4,$f1,$f1,$f0,$e0,$e6,$c7,$cf,$ff,$ff,$ff,$ff,$7f
  !byte $ff,$fc,$c0,$c1,$f9,$f9,$f9,$f9,$f9,$f8,$fd,$ff,$ff,$ff,$ff,$fe
  !byte $ff,$ff,$fb,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$81,$81,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$c0,$80,$fc,$fc,$80,$80,$fc,$fc,$80,$80,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$3c,$3c,$9c,$9c,$c9,$c9,$e1,$e1,$f3,$ff,$ff,$ff
  !byte $3f,$3f,$3f,$3f,$3f,$00,$00,$3c,$b0,$80,$dc,$7c,$60,$00,$5f,$ff
  !byte $4c,$4c,$49,$49,$43,$43,$27,$24,$7c,$fc,$fc,$fc,$fc,$fc,$fe,$e0
  !byte $40,$4e,$fe,$e0,$c0,$fe,$7f,$60,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fe,$0c,$44,$e0,$f1,$f0,$f0,$e6,$e7,$cf,$ff,$ff,$ff,$ff,$7f,$7f
  !byte $ff,$f8,$c0,$c9,$f9,$f9,$f9,$f9,$f9,$f8,$fd,$ff,$ff,$ff,$fe,$4e
  !byte $ff,$ff,$fb,$f3,$f3,$f9,$f9,$f9,$f9,$f9,$41,$01,$7f,$ff,$ff,$f8
  !byte $ff,$ff,$ff,$fd,$80,$84,$fc,$e0,$80,$dc,$fc,$e0,$80,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$fe,$3c,$1c,$9c,$8c,$c9,$c1,$e1,$71,$73,$7f,$ff
  !byte $7f,$3f,$3f,$3f,$3f,$3d,$00,$84,$fc,$e0,$80,$dc,$7c,$60,$00,$ff
  !byte $4c,$48,$49,$41,$43,$43,$27,$2f,$fc,$fc,$fc,$fc,$fc,$fc,$fe,$fe
  !byte $40,$fe,$fe,$c0,$c2,$fe,$7e,$00,$03,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fe,$0c,$44,$e1,$f1,$f0,$f0,$e6,$e7,$cf,$ff,$ff,$ff,$7f,$7f,$7f
  !byte $ff,$f0,$c0,$c9,$f9,$f9,$f9,$f9,$fc,$fc,$fd,$ff,$ff,$ff,$de,$4c
  !byte $7f,$ff,$fb,$f3,$f3,$f3,$f9,$f9,$f9,$f9,$c1,$01,$7f,$ff,$ff,$c0
  !byte $e0,$ff,$ff,$fd,$80,$80,$fc,$f0,$80,$cc,$fc,$f0,$80,$df,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$fc,$3c,$1c,$9c,$c9,$c9,$61,$61,$73,$7f,$ff
  !byte $7f,$3f,$3f,$3f,$3f,$3f,$20,$80,$9c,$fc,$c0,$c0,$7e,$7e,$40,$41
  !byte $48,$49,$41,$43,$43,$27,$27,$ff,$ff,$fc,$fc,$fc,$fc,$fe,$fe,$fe
  !byte $4e,$fe,$e0,$c0,$fe,$fe,$60,$00,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $dc,$0c,$40,$e1,$f1,$f0,$e0,$e6,$c7,$cf,$ff,$ff,$ff,$7f,$7f,$7f
  !byte $ff,$e0,$c0,$d9,$f9,$f9,$f9,$f9,$fc,$fc,$fd,$ff,$ff,$de,$9c,$cc
  !byte $47,$ff,$ff,$f3,$f3,$f1,$f9,$f9,$f9,$f9,$f9,$01,$0f,$ff,$f8,$80
  !byte $e0,$e3,$ff,$ff,$c1,$00,$bc,$fc,$80,$80,$fc,$fc,$c0,$c3,$ff,$fe
  !byte $ff,$ff,$ff,$ff,$ff,$fc,$3c,$3c,$9c,$8c,$c9,$e1,$61,$71,$71,$7f
  !byte $7f,$3f,$3f,$3f,$3f,$3f,$ff,$80,$80,$fc,$f8,$c0,$44,$7e,$78,$40
  !byte $48,$41,$43,$43,$47,$27,$3f,$ff,$ff,$ff,$fc,$fc,$fc,$fe,$fe,$fe
  !byte $fe,$fc,$c0,$c2,$fe,$fc,$20,$03,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1c,$08,$c1,$e1,$f1,$f0,$e6,$e7,$c7,$df,$ff,$ff,$7f,$7f,$7f,$7f
  !byte $ff,$e0,$80,$d9,$f9,$f9,$f9,$f9,$fc,$fc,$ff,$ff,$fe,$9c,$9c,$88
  !byte $40,$7f,$ff,$f3,$f3,$f3,$f9,$f9,$f9,$f9,$79,$01,$07,$ff,$e0,$80
  !byte $fc,$e0,$f3,$ff,$f1,$80,$8c,$fc,$e0,$80,$dc,$fe,$e0,$c0,$ff,$fc
  !byte $ff,$ff,$ff,$ff,$ff,$fe,$fc,$3c,$1c,$9c,$c9,$c9,$61,$61,$71,$7f
  !byte $7f,$3f,$3f,$3f,$3f,$ff,$ff,$f8,$80,$8c,$fc,$e0,$40,$5e,$7e,$60
  !byte $92,$42,$43,$47,$47,$6f,$ff,$ff,$ff,$ff,$fe,$fc,$fc,$fe,$fe,$fe
  !byte $fc,$e0,$c0,$fe,$fe,$60,$01,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1c,$09,$e1,$f1,$f0,$e0,$e6,$e7,$cf,$ff,$ff,$ff,$ff,$7f,$7f,$7f
  !byte $7e,$c0,$81,$f1,$f9,$f9,$f9,$f9,$fc,$fc,$ff,$fc,$bc,$98,$98,$98
  !byte $40,$03,$7f,$f3,$f3,$f3,$f3,$f9,$f9,$f9,$f9,$41,$07,$f0,$80,$8c
  !byte $fe,$f8,$f0,$f7,$f9,$81,$04,$fc,$f0,$80,$dc,$fe,$f0,$c0,$df,$fc
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$fc,$3c,$3c,$9c,$8c,$cd,$61,$61,$71,$79
  !byte $7f,$3f,$3f,$3f,$ff,$ff,$ff,$ff,$e0,$80,$9c,$fc,$40,$42,$7e,$7c
  !byte $c2,$43,$47,$47,$6f,$7f,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$fc,$fe,$fe
  !byte $fc,$c0,$c6,$fe,$fc,$40,$03,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $19,$41,$e1,$f1,$f0,$e4,$e7,$e7,$cf,$ff,$ff,$ff,$ff,$7f,$7f,$7f
  !byte $3c,$40,$83,$f3,$f9,$f9,$f9,$f9,$fc,$fc,$fc,$fc,$98,$98,$98,$92
  !byte $3c,$20,$23,$73,$f3,$f3,$f9,$f9,$f9,$f9,$78,$40,$45,$60,$80,$bc
  !byte $fe,$ff,$f8,$f0,$f5,$c1,$00,$bc,$f8,$c0,$c6,$fe,$f8,$c0,$c4,$fc
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$fe,$fc,$3c,$1c,$9c,$cc,$64,$61,$71,$79
  !byte $7f,$3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$e0,$80,$9c,$7c,$40,$42,$7e
  !byte $86,$47,$47,$4f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$fe,$fe
  !byte $e0,$c0,$de,$fe,$e0,$01,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $19,$81,$e3,$f1,$f0,$e6,$e7,$e7,$cf,$ff,$ff,$ff,$ff,$7f,$7f,$7f
  !byte $38,$00,$83,$f3,$f9,$f9,$f9,$f9,$fc,$fc,$f8,$38,$38,$90,$92,$92
  !byte $7f,$38,$20,$23,$73,$f3,$f1,$f9,$f9,$f9,$f8,$40,$41,$00,$8c,$fc
  !byte $fe,$ff,$ff,$f8,$f0,$f1,$01,$0c,$fc,$e0,$80,$de,$fe,$e0,$c0,$f8
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$3c,$3c,$9c,$8c,$44,$65,$71,$71
  !byte $7f,$3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$f8,$c0,$84,$fe,$78,$40,$4e
  !byte $c7,$47,$47,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$fe
  !byte $c0,$ce,$fe,$f8,$40,$0f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $09,$c1,$e3,$f0,$e0,$e6,$e7,$c7,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$7f
  !byte $38,$00,$03,$f3,$f1,$f9,$f9,$f8,$fc,$f8,$38,$38,$30,$92,$92,$86
  !byte $7f,$3e,$30,$21,$33,$f3,$f3,$f9,$f9,$f9,$78,$40,$01,$01,$7c,$f0
  !byte $fe,$ff,$ff,$ff,$f8,$f0,$81,$0c,$fc,$f0,$c0,$ce,$fe,$f0,$c0,$29
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$3c,$1c,$8c,$4c,$64,$70,$70
  !byte $3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f0,$80,$8c,$7e,$70,$40
  !byte $c7,$4f,$4f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fe
  !byte $80,$de,$fc,$e0,$03,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $89,$c3,$e1,$f0,$e4,$e7,$e7,$cf,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$7f
  !byte $30,$01,$03,$73,$f1,$f9,$f9,$f8,$f8,$f9,$30,$30,$30,$92,$86,$86
  !byte $63,$3f,$3c,$30,$03,$13,$f3,$f9,$f9,$f9,$fc,$60,$01,$19,$fc,$e0
  !byte $fe,$ff,$ff,$ff,$ff,$f8,$c0,$00,$3c,$f8,$c0,$c6,$fe,$f8,$e0,$01
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fc,$fc,$3c,$9c,$4c,$44,$60,$70
  !byte $7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$e0,$80,$9e,$7c,$60
  !byte $cf,$4f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc
  !byte $8c,$fe,$f0,$41,$0f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $83,$c3,$e1,$e0,$e6,$e7,$cf,$cf,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$7f
  !byte $30,$00,$03,$13,$f1,$f9,$f9,$f8,$f0,$71,$71,$30,$24,$04,$86,$86
  !byte $60,$27,$3f,$30,$00,$13,$13,$f9,$f9,$f9,$70,$00,$01,$19,$70,$80
  !byte $fe,$fe,$ff,$ff,$ff,$fd,$e0,$00,$1c,$f8,$c0,$c6,$fe,$f8,$e0,$03
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$3c,$1c,$8c,$44,$60,$70
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f8,$c0,$86,$fe,$78
  !byte $cf,$5f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe
  !byte $9c,$fc,$e0,$43,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $83,$e3,$e0,$e4,$e6,$e7,$cf,$df,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$ff
  !byte $20,$00,$03,$13,$31,$f9,$f9,$f0,$f0,$61,$61,$24,$24,$06,$8e,$8f
  !byte $70,$21,$3f,$26,$80,$91,$13,$31,$f9,$f8,$e0,$00,$01,$09,$60,$84
  !byte $fe,$ff,$ff,$ff,$ff,$ff,$f0,$80,$0c,$fc,$f0,$c2,$cc,$f8,$70,$01
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fc,$fc,$1c,$8c,$44,$64,$70
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$f0,$c0,$0e,$7e
  !byte $5f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fc,$f0,$c1,$0f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $83,$e3,$e0,$e4,$e6,$e7,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$ff,$ff
  !byte $20,$00,$00,$93,$13,$79,$f1,$e0,$e0,$61,$61,$24,$0c,$0e,$8e,$8f
  !byte $7c,$30,$23,$37,$86,$90,$81,$09,$38,$f0,$00,$00,$41,$01,$00,$8c
  !byte $fe,$fe,$ff,$ff,$ff,$ff,$f1,$c0,$0c,$bc,$f0,$c0,$c8,$f0,$70,$01
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$bc,$1c,$0c,$44,$60
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$f0,$c2,$4e
  !byte $7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fc,$e0,$c3,$1f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $83,$61,$60,$e4,$e7,$cf,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $20,$00,$00,$93,$13,$11,$e1,$e0,$e0,$61,$49,$0c,$0c,$0e,$8f,$9f
  !byte $5e,$38,$20,$37,$87,$90,$c0,$c0,$08,$20,$00,$10,$01,$01,$04,$9c
  !byte $fe,$fe,$ff,$ff,$ff,$ff,$f9,$e1,$80,$1c,$f8,$e0,$c2,$f3,$70,$10
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$fc,$1c,$8c,$44,$60
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f8,$e0,$c2
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $f0,$c3,$4f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $41,$61,$60,$e6,$e7,$cf,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$00,$00,$92,$93,$01,$21,$c0,$c0,$49,$49,$0c,$0c,$0f,$9f,$9f
  !byte $c6,$7e,$38,$31,$07,$83,$80,$c0,$80,$00,$10,$70,$61,$01,$1c,$7c
  !byte $ff,$fe,$fe,$ff,$ff,$ff,$ff,$f1,$c1,$0c,$bc,$f0,$c2,$c3,$32,$00
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fc,$fc,$bc,$9e,$4e,$60
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$f8,$e0
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $e1,$87,$1f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $41,$60,$64,$4f,$cf,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $02,$00,$00,$12,$81,$81,$00,$00,$c1,$49,$48,$1c,$1f,$9f,$9f,$ff
  !byte $e0,$47,$3e,$38,$81,$83,$c0,$c0,$c0,$00,$10,$70,$01,$01,$3c,$78
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$f1,$c0,$8c,$bc,$f0,$60,$67,$26,$00
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$fe,$9e,$0e,$40
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$f0
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $c3,$8f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $40,$60,$64,$4f,$4f,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $42,$00,$00,$00,$81,$c1,$80,$00,$11,$19,$1c,$1d,$1f,$9f,$ff,$ff
  !byte $f0,$c3,$2f,$3c,$00,$83,$c1,$c0,$80,$00,$00,$00,$01,$01,$38,$30
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$f9,$e1,$80,$1c,$f0,$60,$47,$27,$04
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fc,$fe,$fe,$9c,$40
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $07,$1f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $40,$40,$0e,$0f,$4f,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $46,$00,$00,$00,$02,$81,$81,$00,$11,$19,$19,$1f,$1f,$bf,$ff,$ff
  !byte $f8,$f0,$e3,$2f,$04,$80,$81,$81,$00,$20,$e0,$00,$00,$21,$00,$23
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$f9,$e1,$c0,$84,$a4,$60,$63,$27,$04
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$98,$00
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $0f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $40,$00,$0f,$0f,$0f,$df,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $06,$03,$00,$80,$02,$01,$80,$80,$01,$39,$3f,$3f,$3f,$ff,$ff,$ff
  !byte $fe,$f8,$e1,$e7,$26,$80,$81,$01,$00,$60,$40,$00,$00,$01,$01,$07
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$fd,$f0,$c0,$80,$84,$60,$63,$07,$02
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fc,$f8,$82
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $40,$08,$0b,$0f,$0f,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $07,$03,$01,$00,$02,$01,$20,$20,$03,$1b,$3f,$3f,$7f,$ff,$ff,$ff
  !byte $ff,$fc,$f8,$e3,$a7,$82,$80,$01,$40,$e0,$c0,$10,$20,$01,$03,$07
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f0,$e0,$80,$8c,$48,$41,$07,$03
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fc,$f0,$82
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$08,$09,$0f,$0f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $8f,$03,$01,$00,$00,$01,$20,$20,$23,$07,$1f,$3f,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$fc,$f8,$e3,$83,$00,$00,$c0,$c0,$00,$30,$30,$21,$87,$0f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$f8,$e0,$c4,$8e,$08,$41,$03,$03
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$f8,$f0,$e2
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $0f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $08,$0c,$08,$8f,$1f,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $0f,$07,$01,$00,$00,$01,$00,$21,$73,$43,$0f,$1f,$7f,$ff,$ff,$ff
  !byte $fe,$fe,$fe,$ec,$e0,$02,$00,$00,$c0,$80,$00,$70,$30,$00,$83,$07
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$fe,$fc,$f1,$e1,$c0,$8e,$0c,$08,$01,$40
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$f8,$f2,$c6
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $07,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $08,$0c,$88,$8d,$1f,$1f,$9f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $0f,$07,$01,$00,$00,$41,$04,$03,$71,$61,$47,$0f,$9f,$ff,$ff,$ff
  !byte $fe,$fe,$fe,$ce,$e0,$20,$02,$80,$80,$00,$20,$70,$20,$00,$10,$03
  !byte $ff,$ff,$ff,$ff,$ff,$fe,$fc,$f8,$f1,$d1,$c0,$c4,$8c,$08,$01,$00
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f8,$e6,$c7
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $11,$37,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1c,$1e,$9c,$9d,$1f,$0f,$9f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $0f,$0f,$03,$00,$00,$40,$44,$03,$11,$79,$63,$47,$8f,$9f,$7f,$ff
  !byte $fc,$fc,$cc,$cc,$66,$00,$00,$90,$08,$20,$60,$60,$00,$10,$10,$88
  !byte $ff,$ff,$ff,$ff,$ff,$fc,$f8,$f1,$e7,$98,$80,$84,$8e,$18,$01,$00
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f9,$f8,$e6,$c7
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $88,$31,$77,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $17,$1e,$9c,$9c,$5f,$0f,$8f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1f,$0f,$07,$81,$00,$48,$e4,$c3,$11,$39,$71,$63,$c7,$9f,$7f,$7f
  !byte $fc,$fc,$9c,$cc,$64,$00,$00,$80,$00,$60,$e0,$40,$08,$10,$12,$8c
  !byte $ff,$ff,$ff,$ff,$fe,$fc,$f1,$e3,$e7,$98,$90,$80,$8e,$1c,$00,$00
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f9,$f0,$e6,$8f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fd,$fc
  !byte $7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $8e,$38,$79,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $13,$9f,$9e,$9c,$cf,$0f,$0f,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1f,$0f,$07,$81,$80,$08,$45,$e3,$c1,$98,$38,$71,$63,$47,$4f,$3f
  !byte $f8,$b8,$98,$cd,$64,$00,$20,$10,$00,$c0,$c0,$00,$18,$38,$92,$8f
  !byte $ff,$ff,$ff,$fe,$fc,$f8,$e3,$e7,$ae,$38,$30,$a0,$86,$0c,$00,$11
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f9,$f0,$c7,$8f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f9,$f8
  !byte $3f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $cf,$1e,$3c,$7d,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $13,$9f,$9e,$9c,$ce,$0f,$0f,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1f,$0f,$07,$83,$d0,$88,$05,$63,$e1,$c0,$1c,$3c,$71,$63,$67,$3f
  !byte $f8,$b8,$18,$89,$41,$01,$01,$00,$40,$e0,$c0,$90,$38,$38,$12,$8f
  !byte $ff,$ff,$ff,$fc,$f8,$f0,$e3,$ce,$3c,$38,$39,$30,$26,$02,$00,$19
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f0,$e0,$c7,$8f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fb,$f1,$f0
  !byte $9f,$3f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $cf,$9f,$3e,$7c,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $11,$9b,$9f,$8e,$ce,$2f,$07,$c7,$ff,$ff,$7f,$7f,$ff,$ff,$ff,$ff
  !byte $1f,$0f,$07,$83,$f0,$c8,$85,$23,$71,$e0,$4c,$1c,$f8,$f1,$63,$37
  !byte $f0,$32,$18,$89,$41,$01,$01,$01,$c0,$c0,$80,$10,$38,$38,$12,$cf
  !byte $ff,$ff,$ff,$f8,$f0,$e2,$c7,$ce,$7c,$39,$39,$30,$22,$00,$00,$38
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f0,$e0,$cf,$9f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f3,$f1,$f0
  !byte $8f,$8f,$1f,$3f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $c7,$8f,$1f,$3e,$7e,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $39,$9b,$9f,$ce,$ce,$67,$07,$87,$e7,$ff,$7f,$7f,$7f,$ff,$ff,$ff
  !byte $1f,$0f,$07,$e3,$f1,$c8,$86,$03,$31,$60,$44,$0e,$1c,$78,$31,$13
  !byte $64,$32,$10,$83,$c3,$63,$03,$83,$c0,$88,$1c,$38,$78,$38,$18,$cf
  !byte $fe,$fe,$ff,$f9,$f0,$e6,$ce,$dc,$79,$73,$7d,$38,$12,$01,$00,$3c
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$ff,$ff,$e0,$e8,$cf,$9f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$e7,$e3,$e1,$e0
  !byte $8b,$cf,$8f,$1f,$3f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $c7,$8f,$1f,$3f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $39,$9b,$9f,$cf,$ce,$e7,$07,$03,$e7,$ff,$7f,$3f,$3f,$7f,$ff,$ff
  !byte $1f,$0f,$07,$e3,$f1,$f0,$cc,$83,$11,$38,$70,$26,$4e,$dc,$78,$31
  !byte $e4,$24,$04,$83,$c3,$63,$03,$83,$81,$18,$3c,$7e,$78,$38,$18,$cf
  !byte $fe,$fe,$fb,$f1,$e4,$ce,$9c,$b9,$73,$77,$7c,$78,$00,$01,$0a,$1c
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$e0,$c8,$8f,$1f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$c7,$c3,$e1,$e0
  !byte $89,$c7,$e7,$cf,$9f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $e7,$cf,$8f,$1f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1c,$19,$8f,$cf,$e7,$e7,$13,$83,$e3,$ff,$7f,$3f,$3f,$7f,$7f,$ff
  !byte $1f,$0f,$c7,$e3,$f1,$f0,$ec,$c3,$81,$18,$30,$32,$67,$ce,$7c,$18
  !byte $64,$24,$04,$87,$c3,$23,$07,$83,$91,$38,$7c,$fe,$7c,$3c,$18,$4b
  !byte $fc,$fe,$f3,$e1,$c4,$8c,$98,$f1,$f3,$77,$7c,$78,$00,$00,$06,$0e
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$e0,$c8,$9f,$3f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$df,$c7,$c3,$c1,$c8
  !byte $88,$c7,$e3,$e7,$cf,$9f,$9f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $e7,$c7,$8f,$9f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1c,$18,$8d,$cf,$e7,$e7,$33,$03,$c1,$ff,$7f,$3f,$1f,$3f,$7f,$7f
  !byte $1f,$8f,$c7,$e3,$f1,$f9,$f8,$e3,$c1,$88,$18,$30,$73,$e7,$6e,$3c
  !byte $cc,$2c,$05,$87,$c7,$27,$0f,$83,$31,$78,$7c,$fe,$7e,$3c,$18,$42
  !byte $fc,$f6,$e3,$c1,$88,$18,$31,$f3,$e7,$fe,$7c,$7c,$00,$02,$27,$0e
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fc,$fc,$fe,$e2,$e0,$9e,$9f,$3f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$9f,$8f,$83,$c1,$c8
  !byte $8c,$c4,$e3,$f3,$e7,$c7,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $63,$e7,$cf,$9f,$1f,$bf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $2c,$1c,$8d,$cf,$e7,$e7,$73,$03,$c1,$fb,$7f,$3f,$1f,$9f,$3f,$3f
  !byte $1f,$8f,$c7,$e3,$f1,$fd,$f8,$f4,$e3,$c0,$0c,$18,$39,$f3,$67,$1e
  !byte $cc,$0c,$0d,$87,$c7,$3f,$07,$23,$71,$78,$fc,$fe,$7e,$3c,$08,$05
  !byte $f8,$e6,$c3,$81,$98,$30,$73,$e7,$ee,$fc,$f8,$7c,$00,$40,$23,$26
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$fc,$fc,$e0,$c0,$9e,$1f,$3f
  !byte $7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$bf,$1f,$0f,$83,$91,$98
  !byte $0e,$c6,$e3,$f1,$f3,$e3,$c7,$ef,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fb
  !byte $63,$e7,$cf,$8f,$1f,$bf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $2e,$1c,$cd,$cf,$e7,$e3,$f3,$09,$81,$f1,$7f,$3f,$1f,$8f,$9f,$3f
  !byte $3f,$1f,$c7,$e3,$f1,$f9,$fc,$fc,$f3,$e0,$04,$0c,$18,$b9,$73,$37
  !byte $9c,$0c,$09,$8f,$cf,$3f,$0f,$63,$71,$f8,$fc,$fe,$7e,$3c,$08,$04
  !byte $f8,$c4,$83,$91,$30,$70,$67,$ce,$ec,$fc,$f9,$00,$00,$70,$73,$26
  !byte $ff,$ff,$ff,$ff,$ff,$fe,$ff,$fd,$fc,$fc,$fc,$e0,$c0,$9e,$1e,$3f
  !byte $3f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$0f,$03,$91,$98
  !byte $0f,$c6,$e3,$f0,$f8,$f9,$f3,$e7,$ff,$ff,$fe,$fe,$fe,$fe,$ff,$f3
  !byte $63,$67,$c7,$cf,$9f,$bf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $26,$1c,$cc,$c7,$e7,$f3,$f3,$19,$00,$f0,$7f,$3f,$0f,$cf,$cf,$9f
  !byte $3f,$1f,$87,$e3,$f1,$fb,$fc,$fc,$fb,$f0,$20,$06,$4c,$18,$f9,$3b
  !byte $9c,$1c,$09,$8f,$7f,$3f,$0f,$47,$f1,$f8,$fc,$fe,$7e,$3c,$0c,$05
  !byte $d8,$c4,$83,$31,$30,$66,$c6,$ce,$fc,$f9,$f9,$00,$00,$78,$73,$27
  !byte $ff,$ff,$ff,$ff,$fe,$fe,$ff,$f9,$f9,$fc,$fc,$c0,$c0,$be,$3e,$7f
  !byte $3f,$3f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$0f,$23,$31,$38
  !byte $0f,$c7,$e1,$f8,$fc,$fc,$f9,$f3,$f3,$ff,$fe,$fc,$fe,$fe,$fe,$e3
  !byte $23,$73,$e7,$c7,$cf,$9f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $27,$46,$cc,$c6,$e7,$f3,$f9,$19,$00,$e0,$7f,$3f,$0f,$47,$c7,$cf
  !byte $3f,$0f,$c7,$e3,$f1,$ff,$ff,$fc,$fe,$f9,$30,$22,$66,$4c,$dc,$b9
  !byte $1c,$1c,$19,$9f,$7f,$7f,$4f,$c7,$e1,$f8,$fc,$fe,$7e,$3c,$0c,$05
  !byte $d8,$8c,$03,$31,$60,$e6,$ce,$dc,$f8,$f9,$fb,$07,$04,$78,$79,$73
  !byte $ff,$ff,$ff,$ff,$fe,$fc,$fb,$fb,$f9,$f9,$f8,$c0,$80,$3e,$3e,$7e
  !byte $9f,$1f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$07,$63,$33,$3e
  !byte $9d,$87,$e3,$f0,$fc,$fc,$fc,$f9,$f9,$ff,$f8,$f8,$fc,$fc,$ee,$c6
  !byte $23,$73,$63,$e7,$cf,$cf,$ff,$ff,$ff,$7f,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $73,$e6,$ce,$c6,$e3,$f3,$f9,$38,$00,$c0,$7e,$3f,$0f,$47,$67,$c7
  !byte $3f,$1f,$87,$e3,$f1,$ff,$ff,$fe,$fe,$f9,$38,$32,$23,$66,$cc,$fc
  !byte $3c,$38,$19,$bf,$7f,$7f,$cf,$c7,$e1,$f8,$fc,$ff,$7e,$3e,$0c,$84
  !byte $98,$0c,$03,$61,$e0,$ce,$9c,$98,$f9,$f3,$87,$07,$fc,$7c,$79,$73
  !byte $ff,$ff,$ff,$fe,$fc,$fc,$fb,$f3,$f9,$f9,$f9,$80,$80,$3c,$3e,$7e
  !byte $cf,$9f,$9f,$bf,$7f,$7f,$ff,$ff,$ff,$ff,$7f,$1f,$8f,$43,$76,$3e
  !byte $dc,$87,$e3,$f0,$fc,$fe,$fe,$fc,$fc,$f9,$f8,$f8,$f8,$fc,$dc,$c6
  !byte $21,$31,$73,$67,$c7,$cf,$ff,$ff,$ff,$7f,$7f,$ff,$ff,$ff,$ff,$ff
  !byte $73,$f3,$ce,$c6,$e7,$f3,$f9,$f8,$04,$00,$7c,$3f,$0f,$07,$63,$67
  !byte $3f,$0f,$c7,$e1,$f9,$ff,$ff,$ff,$fe,$7d,$38,$38,$33,$73,$e6,$ee
  !byte $3c,$38,$39,$ff,$ff,$ff,$cf,$c7,$e1,$f8,$fc,$ff,$7e,$3e,$0c,$84
  !byte $10,$0c,$43,$e1,$c8,$9c,$99,$b9,$f3,$f3,$07,$0f,$fe,$fc,$79,$79
  !byte $ff,$fe,$fe,$fc,$fc,$fd,$f3,$f3,$f3,$f9,$f8,$80,$84,$3c,$7e,$7e
  !byte $e7,$cf,$8f,$9f,$3f,$3f,$7f,$ff,$ff,$ff,$7f,$1f,$8f,$c7,$7e,$7e
  !byte $fe,$c6,$e1,$f0,$fc,$ff,$ff,$fe,$fe,$f0,$f0,$f0,$f8,$f9,$9c,$84
  !byte $01,$31,$73,$67,$e7,$cf,$ff,$ff,$7f,$3f,$7f,$ff,$ff,$ff,$ff,$ff
  !byte $73,$f3,$ee,$e6,$e3,$f1,$f9,$fc,$06,$00,$f8,$3f,$0f,$87,$21,$33
  !byte $3e,$0f,$87,$e1,$fb,$ff,$ff,$ff,$fe,$ff,$3c,$3c,$39,$71,$f3,$e6
  !byte $7c,$39,$79,$ff,$ff,$ff,$df,$c7,$e1,$f8,$fc,$ff,$fe,$3e,$0c,$84
  !byte $38,$0c,$c3,$c1,$88,$98,$39,$b3,$f3,$e7,$0f,$0f,$fe,$fc,$78,$79
  !byte $ff,$fe,$fc,$fc,$f9,$f9,$f7,$e7,$f3,$f3,$f8,$80,$0c,$3c,$7c,$7e
  !byte $63,$e7,$cf,$cf,$3f,$1f,$3f,$7f,$7f,$ff,$7f,$1f,$87,$ef,$fe,$7c
  !byte $fb,$ef,$e3,$f0,$fc,$ff,$ff,$ff,$ff,$e2,$e0,$f0,$f2,$f9,$19,$84
  !byte $81,$39,$33,$73,$e7,$c7,$ef,$ff,$7f,$3f,$3f,$ff,$ff,$ff,$ff,$ff
  !byte $79,$f3,$f3,$e6,$e3,$f1,$f9,$fc,$1e,$00,$e0,$3f,$0f,$83,$81,$19
  !byte $3e,$1f,$87,$e3,$fb,$ff,$ff,$ff,$ff,$ff,$3e,$3e,$3c,$78,$79,$f3
  !byte $7c,$78,$f9,$fb,$ff,$ff,$df,$c7,$e1,$f0,$fc,$ff,$ff,$3e,$0c,$84
  !byte $30,$0c,$c3,$81,$99,$39,$33,$f3,$e7,$ef,$0f,$1f,$fe,$fc,$fc,$79
  !byte $fe,$fc,$fc,$f9,$f9,$fb,$e7,$e7,$e3,$f3,$f0,$80,$18,$7c,$7c,$fe
  !byte $31,$73,$e7,$e7,$2f,$1f,$9f,$1f,$3f,$7f,$7f,$1f,$8f,$fe,$fe,$fc
  !byte $f9,$ff,$e3,$f0,$fc,$ff,$ff,$ff,$ef,$c3,$e0,$e0,$f2,$73,$19,$81
  !byte $81,$99,$31,$33,$e3,$e7,$ef,$7f,$7f,$3f,$3f,$ff,$ff,$ff,$ff,$ff
  !byte $f9,$f1,$f3,$e7,$e3,$f1,$f8,$fc,$be,$00,$c0,$3f,$0f,$83,$c1,$98
  !byte $3e,$0f,$87,$e1,$fb,$ff,$ff,$ff,$ff,$ff,$3f,$3e,$3e,$7c,$7c,$f9
  !byte $fc,$f8,$f9,$fb,$ff,$ff,$ff,$c7,$c3,$f0,$fc,$ff,$ff,$3e,$0e,$80
  !byte $10,$0c,$83,$91,$39,$33,$63,$e7,$e7,$cf,$0f,$3f,$fe,$fe,$fc,$7c
  !byte $fc,$fc,$f9,$f1,$f3,$ff,$ef,$e7,$e7,$f3,$e0,$00,$19,$7c,$7c,$fe
  !byte $99,$39,$b3,$f3,$27,$0f,$cf,$8f,$9f,$3f,$3f,$1f,$9f,$fe,$fe,$fc
  !byte $f9,$ff,$f3,$f0,$f8,$fe,$ff,$ff,$cf,$c3,$c0,$e0,$e6,$73,$11,$01
  !byte $80,$99,$19,$33,$f3,$e7,$e7,$7f,$3f,$3f,$1f,$3f,$ff,$fe,$fe,$ff
  !byte $f9,$f9,$fb,$f7,$e3,$f1,$f8,$fc,$fe,$83,$80,$3f,$0f,$43,$c0,$c8
  !byte $3e,$0f,$83,$e3,$fb,$ff,$ff,$ff,$ff,$7f,$1f,$3f,$3e,$7e,$7c,$fc
  !byte $f8,$f8,$f3,$fb,$ff,$ff,$ff,$c7,$c1,$f0,$fc,$ff,$ff,$3e,$0e,$82
  !byte $30,$0d,$83,$31,$33,$63,$67,$c7,$cf,$1f,$1f,$ff,$ff,$fe,$fc,$fc
  !byte $fc,$f9,$f1,$f3,$f3,$fe,$ce,$cf,$e7,$e7,$e0,$00,$39,$78,$fc,$fc
  !byte $9c,$99,$b9,$f3,$33,$0f,$87,$cf,$cf,$9f,$1f,$3f,$bf,$fe,$fc,$fc
  !byte $fc,$fc,$ff,$f8,$f8,$fe,$ff,$ff,$9f,$83,$80,$c8,$e6,$67,$13,$01
  !byte $c0,$99,$99,$31,$33,$f3,$f7,$7f,$3f,$1f,$1f,$1f,$ff,$fe,$fc,$7f
  !byte $fc,$f9,$f9,$f7,$f3,$f1,$f8,$fc,$fe,$83,$80,$3e,$0f,$03,$60,$60
  !byte $3e,$0f,$83,$e3,$ff,$ff,$ff,$ff,$ff,$7f,$1f,$3f,$3f,$3e,$7e,$7e
  !byte $f8,$f8,$f3,$fb,$ff,$ff,$ff,$c7,$c1,$f0,$fc,$ff,$ff,$7e,$1e,$82
  !byte $39,$0f,$03,$63,$67,$e7,$cf,$cf,$df,$1f,$1f,$ff,$ff,$fe,$fc,$fc
  !byte $78,$f2,$f3,$e6,$e6,$fc,$ce,$cf,$c7,$e6,$c0,$01,$39,$78,$fc,$fc
  !byte $cc,$cc,$98,$f9,$39,$0f,$87,$e7,$e7,$cf,$0f,$5f,$fe,$fe,$fc,$fc
  !byte $fe,$fc,$ff,$f8,$f8,$fe,$ff,$ff,$1f,$07,$81,$88,$ce,$e7,$23,$03
  !byte $c0,$98,$99,$99,$b3,$f3,$f3,$7f,$3f,$9f,$0f,$1f,$ff,$fc,$fc,$7f
  !byte $fc,$f8,$f9,$f9,$f3,$f1,$f8,$fc,$ff,$df,$80,$f0,$9f,$03,$20,$60
  !byte $7f,$1f,$83,$e3,$ff,$ff,$ff,$ff,$ff,$7f,$1f,$1f,$3f,$3f,$7f,$7e
  !byte $f8,$f8,$f3,$f3,$ff,$ff,$ff,$cf,$c3,$f0,$fc,$ff,$ff,$7f,$1e,$82
  !byte $33,$0f,$47,$67,$e7,$cf,$cf,$9f,$ff,$3f,$3f,$ff,$ff,$fe,$fe,$fc
  !byte $70,$72,$e6,$e6,$cc,$fc,$9f,$8f,$cf,$e4,$c0,$03,$71,$f9,$fc,$fc
  !byte $66,$ce,$cc,$dc,$39,$0d,$83,$f3,$f3,$e7,$67,$6e,$fe,$fc,$fc,$f9
  !byte $ff,$fe,$ff,$fd,$fc,$fe,$ff,$7f,$1f,$07,$00,$98,$8f,$cf,$07,$03
  !byte $c0,$c8,$9c,$99,$99,$f3,$f3,$7f,$3e,$9e,$0f,$0f,$ff,$f8,$f8,$3f
  !byte $fc,$fc,$f9,$f9,$fb,$f9,$f8,$fe,$ff,$ff,$c0,$c0,$8f,$83,$80,$30
  !byte $7f,$0f,$83,$e3,$ff,$ff,$ff,$ff,$ff,$7f,$1f,$3f,$3f,$3f,$7f,$7f
  !byte $f8,$f8,$f3,$f3,$ff,$ff,$ff,$cf,$c1,$f0,$fc,$ff,$ff,$7f,$1e,$02
  !byte $3b,$0f,$47,$c7,$cf,$cf,$9f,$9f,$bf,$3f,$7f,$ff,$ff,$ff,$fe,$fe
  !byte $30,$26,$66,$4c,$cc,$fd,$9f,$9f,$cf,$c0,$80,$03,$71,$f9,$fc,$fc
  !byte $33,$67,$66,$ee,$3c,$0c,$81,$f1,$f1,$f3,$f3,$e6,$fe,$fc,$fc,$f9
  !byte $ff,$ff,$ff,$ff,$fe,$fe,$ff,$7f,$1f,$03,$21,$19,$9f,$cf,$07,$07
  !byte $40,$cc,$cc,$9c,$99,$f9,$fb,$3e,$1c,$8e,$07,$0f,$fb,$f0,$f8,$17
  !byte $fe,$fc,$fc,$fd,$fb,$f9,$f8,$fe,$ff,$ff,$e0,$c0,$df,$c3,$80,$98
  !byte $7f,$0f,$83,$f3,$ff,$ff,$ff,$ff,$ff,$7f,$1f,$1f,$3f,$3f,$7f,$7f
  !byte $f8,$f0,$f3,$f3,$ff,$ff,$ff,$cf,$c3,$e0,$fc,$ff,$ff,$7f,$1e,$02
  !byte $3f,$0f,$cf,$cf,$cf,$9f,$9f,$bf,$3f,$3f,$ff,$ff,$ff,$ff,$fe,$fe
  !byte $00,$24,$0c,$4c,$59,$79,$bf,$9f,$8f,$c0,$80,$03,$f3,$f9,$f9,$fd
  !byte $33,$33,$33,$e6,$3e,$0e,$81,$f0,$f9,$f9,$f9,$f2,$f8,$fc,$fc,$f9
  !byte $7f,$7f,$ff,$ff,$ff,$fe,$ff,$ff,$1f,$03,$41,$3b,$1f,$8f,$0f,$07
  !byte $60,$4c,$cc,$cc,$9c,$f9,$79,$3c,$1c,$8c,$06,$07,$f7,$f0,$78,$07
  !byte $fe,$fe,$fc,$fc,$fd,$f8,$fc,$fe,$ff,$ff,$f0,$e0,$ff,$c3,$c0,$98
  !byte $7f,$0f,$03,$e3,$ff,$ff,$ff,$ff,$ff,$7f,$1f,$9f,$3f,$3f,$3f,$7f
  !byte $f8,$f0,$f3,$f3,$ff,$ff,$ff,$cf,$c3,$e0,$fc,$ff,$ff,$ff,$1f,$03
  !byte $1f,$0f,$cf,$9f,$9f,$9f,$3f,$bf,$3f,$7f,$ff,$ff,$ff,$ff,$ff,$fe
  !byte $00,$8c,$0c,$19,$19,$7b,$3f,$1f,$9e,$c0,$01,$03,$f3,$f9,$f9,$fd
  !byte $99,$99,$33,$f3,$7f,$0f,$81,$e0,$fc,$fc,$fc,$f8,$f8,$fc,$f9,$f9
  !byte $7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$03,$63,$3f,$3f,$9f,$0f,$0f
  !byte $40,$60,$cc,$cc,$cc,$d9,$79,$38,$18,$c4,$c4,$06,$e7,$e0,$f8,$07
  !byte $fe,$fe,$fc,$fc,$fc,$f8,$fc,$fe,$ff,$ff,$ff,$e0,$e1,$e7,$c0,$c8
  !byte $7f,$0f,$83,$f7,$ff,$ff,$ff,$ff,$ff,$7f,$1f,$9f,$9f,$3f,$3f,$3f
  !byte $f0,$f0,$f3,$f7,$ff,$ff,$ff,$ff,$c3,$e0,$fc,$ff,$ff,$ff,$1f,$03
  !byte $1f,$1f,$9f,$9f,$3f,$3f,$3f,$ff,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$fe
  !byte $00,$98,$99,$93,$33,$33,$3f,$3f,$1c,$00,$03,$07,$f3,$f1,$f9,$fd
  !byte $cc,$99,$99,$99,$fb,$0f,$81,$f0,$fe,$fe,$fc,$fc,$fc,$f9,$f9,$f9
  !byte $7f,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$1f,$07,$e7,$7f,$3f,$1f,$0f,$0f
  !byte $40,$60,$66,$cc,$cc,$cc,$7d,$30,$10,$c0,$e0,$02,$06,$c0,$f0,$0f
  !byte $fe,$fe,$fe,$fc,$fc,$fc,$fc,$fe,$ff,$ff,$ff,$f0,$f0,$f7,$e0,$e0
  !byte $ff,$0f,$07,$e7,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$9f,$9f,$3f,$3f,$3f
  !byte $f0,$f0,$f3,$e7,$ff,$ff,$ff,$df,$c3,$e0,$fc,$ff,$ff,$ff,$1f,$03
  !byte $1f,$1f,$3f,$3f,$3f,$3f,$7f,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$88,$83,$03,$13,$17,$5e,$3f,$18,$00,$07,$27,$73,$f1,$f9,$ff
  !byte $e4,$cc,$cc,$cc,$fd,$8f,$80,$e0,$fe,$ff,$fe,$fc,$fc,$f9,$f9,$f9
  !byte $7f,$7f,$7f,$7f,$ff,$ff,$ff,$ff,$1f,$07,$ef,$7f,$7f,$3f,$1f,$1f
  !byte $00,$60,$66,$66,$4c,$cc,$7c,$21,$00,$c0,$e0,$00,$02,$c0,$f0,$0f
  !byte $ff,$fe,$fe,$fe,$fe,$fc,$fc,$fe,$ff,$ff,$ff,$f8,$f0,$ff,$f0,$f0
  !byte $7f,$0f,$07,$f7,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$9f,$9f,$3f,$3f,$3f
  !byte $f0,$f0,$e7,$e7,$ff,$ff,$ff,$ff,$c3,$c0,$fc,$ff,$ff,$ff,$3f,$03
  !byte $3f,$3f,$3f,$3f,$7f,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$22,$23,$03,$46,$c6,$5e,$1e,$10,$81,$0f,$07,$23,$f1,$f9,$ff
  !byte $e6,$e6,$e6,$ec,$ec,$ce,$c0,$f0,$fe,$ff,$fe,$fc,$f9,$f9,$f9,$f3
  !byte $7f,$3f,$7f,$7f,$7f,$7f,$ff,$ff,$1f,$0f,$ff,$ff,$7f,$3f,$1f,$3f
  !byte $00,$30,$26,$66,$66,$ee,$7c,$01,$80,$c2,$f1,$00,$00,$80,$f0,$0f
  !byte $ff,$ff,$ff,$fe,$fe,$fe,$fc,$fe,$ff,$ff,$ff,$fe,$f8,$f9,$f0,$f0
  !byte $7f,$07,$87,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$1f,$9f,$9f,$3f,$3f,$3f
  !byte $f0,$f0,$f3,$e7,$ff,$ff,$ff,$ff,$c7,$c0,$f8,$ff,$ff,$ff,$bf,$03
  !byte $3f,$7f,$7f,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$26,$66,$66,$66,$cc,$cc,$1c,$00,$03,$0f,$07,$83,$b3,$fb,$ff
  !byte $f2,$f2,$e6,$e6,$e6,$fe,$c0,$e0,$fe,$ff,$fc,$f8,$f9,$f9,$f9,$f3
  !byte $3f,$3f,$3f,$7f,$7f,$7f,$7f,$ff,$1f,$1f,$ff,$ff,$ff,$7f,$3f,$7f
  !byte $00,$30,$33,$26,$66,$66,$7e,$01,$80,$c2,$f1,$81,$00,$00,$e0,$0e
  !byte $ff,$ff,$ff,$ff,$fe,$ff,$fe,$fe,$ff,$ff,$ff,$ff,$f8,$f8,$f8,$f8
  !byte $ff,$07,$07,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$9f,$9f,$bf,$3f,$bf
  !byte $f0,$f0,$e7,$e7,$f7,$ff,$ff,$ff,$c3,$c0,$fc,$ff,$ff,$ff,$ff,$83
  !byte $7f,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$22,$22,$22,$44,$64,$e4,$0c,$01,$03,$0f,$47,$c7,$d3,$fb,$ff
  !byte $f2,$f2,$f2,$f2,$f2,$ff,$e0,$e0,$fe,$ff,$fe,$f8,$f9,$fb,$f3,$f3
  !byte $3f,$3f,$3f,$7f,$7f,$7f,$7f,$ff,$3f,$3f,$ff,$ff,$ff,$7f,$7f,$7f
  !byte $00,$30,$33,$26,$26,$66,$7e,$01,$80,$c2,$e0,$e0,$00,$00,$e0,$07
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$ff,$ff,$ff,$ff,$fc,$fc,$fc,$fc
  !byte $7f,$07,$07,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$9f,$9f,$9f,$3f,$bf
  !byte $f0,$e0,$e7,$e7,$ff,$ff,$ff,$ff,$c7,$c0,$f8,$ff,$ff,$ff,$ff,$83
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$00,$88,$00,$00,$31,$f1,$19,$01,$07,$07,$47,$e7,$e3,$f3,$ff
  !byte $f8,$f8,$f8,$f8,$f8,$fd,$f0,$f0,$fc,$ff,$fc,$f8,$f3,$f3,$f3,$f3
  !byte $3f,$3f,$3f,$3f,$3f,$7f,$7f,$ff,$7f,$7f,$ff,$7f,$ff,$ff,$ff,$ff
  !byte $80,$b0,$33,$33,$33,$37,$3e,$01,$00,$80,$c0,$e0,$00,$00,$c0,$07
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$ff,$fc
  !byte $ff,$07,$07,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$1f,$9f,$9f,$9f,$9f,$bf
  !byte $f0,$e0,$e7,$e7,$e7,$ff,$ff,$ff,$c7,$c0,$f0,$ff,$ff,$ff,$ff,$83
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$80,$88,$99,$99,$99,$f9,$01,$03,$03,$13,$83,$c3,$e3,$f7,$ff
  !byte $fc,$fc,$fc,$f8,$f8,$f9,$f9,$f8,$fc,$fe,$fc,$f0,$f3,$f3,$f3,$f3
  !byte $3f,$3f,$3f,$3f,$3f,$3f,$3f,$ff,$7f,$ff,$ff,$7f,$7f,$ff,$ff,$ff
  !byte $80,$90,$93,$b3,$33,$33,$7f,$01,$00,$00,$c0,$e0,$00,$00,$c0,$07
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$ff,$ff,$ff,$fc,$fc,$fe,$fc
  !byte $7f,$07,$07,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$0f,$9f,$9f,$9f,$9f,$9f
  !byte $e0,$e0,$e7,$e7,$e7,$ff,$ff,$ff,$ef,$c0,$e0,$ff,$ff,$ff,$ff,$83
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$80,$88,$88,$99,$d9,$f9,$03,$01,$01,$19,$89,$c3,$e3,$f7,$ff
  !byte $fc,$f8,$f8,$f8,$f8,$fc,$f9,$f8,$fc,$fe,$fc,$f0,$f3,$f3,$f3,$e7
  !byte $1f,$1f,$9f,$bf,$3f,$3f,$3f,$ff,$ff,$ff,$7f,$7f,$7f,$ff,$ff,$ff
  !byte $80,$90,$99,$99,$93,$93,$bf,$01,$00,$00,$88,$c0,$00,$01,$41,$07
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$fe,$fc,$fe,$ff,$ff,$ff,$fc,$fc,$ff,$f8
  !byte $ff,$0f,$0f,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$0f,$9f,$9f,$9f,$9f,$ff
  !byte $e0,$e0,$e6,$e7,$e7,$ff,$ff,$ff,$cf,$c0,$f0,$ff,$ff,$ff,$ff,$c7
  !byte $7f,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$00,$22,$22,$00,$40,$f8,$03,$00,$10,$1c,$8d,$c1,$e1,$f7,$ff
  !byte $f8,$f8,$f8,$f8,$f8,$fe,$f3,$f8,$fc,$fe,$fc,$f0,$f3,$f7,$e7,$e7
  !byte $1f,$1f,$9f,$9f,$bf,$3f,$3f,$ff,$ff,$ff,$3f,$3f,$7f,$ff,$ff,$ff
  !byte $80,$98,$99,$99,$99,$9b,$bf,$01,$01,$20,$0c,$c4,$00,$01,$23,$07
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc,$fc,$fe,$ff,$ff,$f8,$f8,$ff,$f8
  !byte $7f,$0f,$0f,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$0f,$df,$9f,$9f,$9f,$df
  !byte $e0,$e0,$e7,$e7,$ef,$ff,$ff,$ff,$ff,$c0,$e0,$ff,$ff,$ff,$ff,$83
  !byte $7f,$7f,$7f,$7f,$7f,$7f,$7f,$ff,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$20,$22,$22,$22,$66,$f6,$07,$00,$10,$3c,$1c,$84,$e4,$ff,$ff
  !byte $f3,$f3,$f3,$f3,$f2,$fe,$f3,$f0,$f8,$fc,$f8,$f1,$e3,$e7,$e7,$e7
  !byte $1f,$1f,$9f,$9f,$9f,$9f,$9f,$ff,$ff,$ff,$3f,$3f,$3f,$ff,$ff,$ff
  !byte $c0,$c0,$99,$99,$99,$99,$ff,$03,$03,$70,$1c,$8e,$40,$03,$87,$0f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$f8,$f8,$fc,$fe,$ff,$f0,$f0,$ff,$f0
  !byte $ff,$0f,$0f,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$0f,$cf,$df,$9f,$9f,$df
  !byte $e1,$e0,$e6,$ef,$ef,$ff,$ff,$ff,$ff,$c0,$c0,$ff,$ff,$ff,$ff,$c7
  !byte $3f,$3f,$3f,$3f,$3f,$3f,$7f,$ff,$7f,$7f,$7f,$7f,$7f,$7f,$ff,$ff
  !byte $00,$20,$23,$23,$23,$23,$e7,$07,$00,$20,$3e,$0e,$c6,$e6,$ff,$ff
  !byte $f3,$f3,$f3,$f2,$f2,$ff,$f7,$f1,$f8,$fc,$f8,$f1,$e3,$ef,$e7,$e7
  !byte $1f,$1f,$9f,$9f,$9f,$9f,$9f,$ff,$ff,$7f,$1f,$1f,$3f,$ff,$ff,$ff
  !byte $c0,$c0,$c9,$c9,$c9,$c9,$df,$07,$03,$70,$3c,$0e,$00,$01,$8f,$7f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$f0,$f0,$f8,$fe,$ff,$f0,$f0,$ff,$f0
  !byte $ff,$0f,$0f,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$0f,$cf,$cf,$df,$df,$ff
  !byte $e7,$e0,$c0,$cf,$cf,$ff,$ff,$ff,$ff,$c0,$c0,$ff,$ff,$ff,$ff,$ff
  !byte $1f,$1f,$9f,$9f,$bf,$3f,$3f,$ff,$3f,$3f,$3f,$3f,$3f,$3f,$ff,$ff
  !byte $00,$00,$01,$01,$01,$83,$a7,$87,$00,$00,$3f,$1f,$8f,$cf,$ff,$ff
  !byte $e6,$e6,$e6,$e6,$e6,$ff,$e7,$e3,$f1,$f8,$f8,$f1,$e3,$ef,$e7,$e7
  !byte $0f,$0f,$cf,$cf,$cf,$cf,$cf,$ff,$ff,$7f,$1f,$1f,$1f,$ff,$ff,$ff
  !byte $c0,$c0,$cc,$cc,$cc,$cc,$cd,$07,$01,$f0,$7c,$1f,$08,$00,$c7,$0f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$e0,$e0,$f8,$fc,$fe,$e0,$e0,$ff,$e0
  !byte $ff,$0f,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$0f,$cf,$cf,$cf,$cf,$ff
  !byte $c0,$c0,$cc,$cf,$cf,$ff,$ff,$ff,$ff,$c0,$c0,$ff,$ff,$ff,$ff,$ff
  !byte $1f,$1f,$9f,$9f,$9f,$9f,$9f,$ff,$1f,$1f,$9f,$9f,$9f,$9f,$ff,$ff
  !byte $c0,$c0,$c9,$c9,$c9,$c9,$cd,$8f,$00,$40,$3f,$1f,$8f,$cf,$ff,$ff
  !byte $e6,$e6,$e4,$e4,$e4,$ff,$ef,$e3,$f0,$f8,$f8,$e3,$e7,$ef,$cf,$cf
  !byte $1f,$1f,$df,$df,$df,$df,$df,$ff,$ff,$3f,$1f,$1f,$3f,$ff,$ff,$ff
  !byte $c0,$c0,$cc,$cc,$cc,$cc,$cf,$0f,$01,$f0,$7e,$3f,$18,$00,$c7,$1f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$c0,$c0,$e1,$f8,$fc,$c0,$c0,$ff,$c0
  !byte $ff,$1f,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$1f,$df,$df,$df,$df,$ff
  !byte $cf,$c0,$c0,$cf,$cf,$ff,$ff,$ff,$ff,$c0,$c0,$ff,$ff,$ff,$ff,$ff
  !byte $1f,$1f,$df,$df,$df,$df,$df,$ff,$1f,$1f,$df,$df,$df,$df,$ff,$ff
  !byte $80,$c0,$cc,$cc,$cc,$cc,$cf,$1f,$00,$40,$7f,$3f,$1f,$df,$ff,$ff
  !byte $cc,$cc,$cc,$cc,$cd,$ff,$df,$c7,$e2,$f0,$f0,$e2,$c7,$df,$cf,$cf
  !byte $0f,$0f,$cf,$cf,$cf,$cf,$cf,$ff,$ff,$3f,$0f,$8f,$1f,$7f,$ff,$ff
  !byte $e0,$e0,$ec,$ec,$ec,$e4,$ee,$07,$01,$f0,$fe,$3f,$1c,$10,$e3,$0f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$c0,$c0,$e3,$f0,$fc,$e0,$c0,$df,$ff
  !byte $ff,$0f,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$0f,$cf,$cf,$cf,$cf,$ff
  !byte $cf,$c0,$c0,$cf,$cf,$cf,$ff,$ff,$ff,$c0,$c0,$ff,$ff,$ff,$ff,$ff
  !byte $0f,$07,$67,$67,$67,$67,$e7,$ff,$0f,$07,$e7,$e7,$e7,$ef,$ff,$ff
  !byte $00,$80,$86,$86,$86,$c6,$86,$1f,$20,$60,$7f,$3f,$1f,$df,$ff,$ff
  !byte $c0,$c9,$c9,$c9,$cd,$cf,$df,$cf,$c2,$f0,$f0,$e2,$c7,$cf,$cf,$cf
  !byte $0f,$0f,$cf,$cf,$6f,$67,$ef,$ff,$ff,$3f,$07,$87,$0f,$7f,$ff,$ff
  !byte $e0,$e0,$e6,$e6,$e6,$e6,$e6,$2f,$21,$f0,$fe,$7f,$3e,$38,$e1,$27
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$80,$80,$c7,$e1,$f8,$fc,$80,$83,$e0
  !byte $1f,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$0f,$cf,$cf,$cf,$cf,$ff
  !byte $cf,$c0,$c0,$cf,$cf,$cf,$ff,$ff,$ff,$c0,$c0,$ff,$ff,$ff,$ff,$ff
  !byte $07,$07,$67,$67,$67,$67,$67,$ff,$07,$07,$e7,$e7,$f7,$f7,$ff,$ff
  !byte $90,$90,$92,$92,$92,$d2,$93,$1f,$30,$f0,$7f,$1f,$1f,$df,$ff,$ff
  !byte $89,$99,$99,$99,$99,$df,$df,$cf,$c0,$f0,$f0,$e2,$c7,$df,$cf,$cf
  !byte $0f,$0f,$6f,$67,$67,$67,$e7,$ff,$ff,$0f,$07,$87,$0f,$3f,$ff,$f7
  !byte $e0,$e0,$e6,$e6,$e6,$e6,$e6,$77,$70,$f8,$ff,$ff,$3e,$38,$f0,$37
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$87,$c3,$f0,$fc,$00,$03,$f8
  !byte $1f,$1f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$0f,$cf,$cf,$cf,$cf,$ef
  !byte $cf,$c0,$c0,$cf,$cf,$cf,$ff,$ff,$ff,$e0,$c0,$ff,$ff,$ff,$ff,$ff
  !byte $03,$03,$33,$33,$33,$33,$f3,$f3,$03,$03,$f3,$f3,$f3,$fb,$ff,$ff
  !byte $30,$30,$33,$33,$b3,$b3,$1b,$3f,$78,$f8,$7f,$3f,$1f,$df,$ff,$ff
  !byte $83,$93,$93,$9b,$9b,$9f,$ff,$8e,$84,$e0,$f0,$e0,$cf,$df,$df,$df
  !byte $07,$07,$67,$67,$67,$67,$67,$ff,$ff,$0f,$03,$c3,$0f,$3f,$ff,$ff
  !byte $e0,$e0,$e6,$e6,$e6,$f6,$f3,$77,$f0,$f0,$ff,$ff,$7f,$7c,$f0,$7b
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$0f,$83,$e1,$f8,$00,$01,$f8
  !byte $9f,$1f,$7f,$ff,$ff,$ff,$ff,$ff,$fe,$0f,$0f,$cf,$cf,$cf,$cf,$ef
  !byte $9f,$c0,$c0,$cf,$cf,$cf,$ff,$ff,$ff,$e0,$c0,$ff,$ff,$ff,$ff,$ff
  !byte $03,$03,$33,$b3,$99,$99,$bb,$c1,$01,$19,$f9,$f9,$f9,$ff,$ff,$ff
  !byte $78,$38,$39,$39,$39,$b9,$39,$3f,$78,$fc,$ff,$3f,$1f,$9f,$ff,$ff
  !byte $03,$33,$33,$33,$33,$3f,$ff,$9e,$84,$c0,$f0,$c4,$8f,$9f,$9f,$9f
  !byte $06,$26,$66,$66,$67,$33,$f7,$ff,$7f,$07,$83,$c3,$0f,$3f,$7f,$f1
  !byte $f0,$e0,$f2,$f2,$f3,$f3,$f3,$ff,$f0,$f8,$ff,$ff,$ff,$fc,$f8,$f9
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$01,$1f,$07,$c1,$f0,$00,$03,$f8
  !byte $9f,$1f,$7f,$ff,$ff,$ff,$ff,$ff,$fc,$0c,$0f,$cf,$cf,$ce,$ee,$c7
  !byte $9f,$80,$80,$cf,$cf,$cf,$ff,$ff,$ff,$f0,$c0,$ef,$ff,$ff,$ff,$ff
  !byte $01,$09,$99,$99,$d9,$cc,$fd,$f1,$00,$0c,$fc,$fc,$fc,$ff,$ff,$ff
  !byte $7c,$78,$7c,$7c,$7c,$7c,$3c,$7f,$fc,$fc,$ff,$3f,$3f,$bf,$ff,$ff
  !byte $02,$66,$66,$26,$26,$3f,$ff,$3c,$08,$c1,$e0,$c0,$8e,$9f,$bf,$9f
  !byte $06,$06,$66,$66,$32,$32,$7f,$ff,$7f,$03,$81,$e3,$87,$1f,$7f,$e1
  !byte $f0,$f0,$f2,$f3,$f3,$f3,$f3,$ff,$f8,$f8,$ff,$ff,$ff,$fe,$fc,$fc
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$01,$01,$3f,$0f,$83,$e0,$00,$03,$f8
  !byte $1f,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$0c,$0e,$cf,$cf,$ee,$ec,$c7
  !byte $9e,$80,$80,$df,$cf,$cf,$ff,$7f,$7f,$78,$60,$63,$7f,$ff,$ff,$ff
  !byte $00,$0c,$cc,$cc,$cc,$4c,$7f,$f0,$00,$0e,$fe,$fe,$fe,$ff,$ff,$ff
  !byte $fc,$7c,$7c,$7c,$7e,$7e,$7e,$7f,$fe,$fe,$ff,$7f,$3f,$bf,$ff,$ff
  !byte $00,$66,$66,$66,$66,$7f,$fe,$3c,$08,$81,$e1,$c0,$8e,$9f,$bf,$9f
  !byte $06,$04,$30,$30,$32,$32,$be,$fe,$1f,$01,$e1,$e1,$87,$1f,$3f,$f0
  !byte $f8,$f0,$f3,$f3,$f3,$fb,$f9,$fb,$f8,$fc,$ff,$ff,$ff,$ff,$fc,$fc
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$03,$03,$7f,$1f,$07,$c1,$01,$07,$f9
  !byte $3f,$1f,$ff,$ff,$ff,$ff,$ff,$ff,$e8,$08,$0c,$e7,$e7,$e6,$e4,$e5
  !byte $9e,$80,$80,$1f,$5f,$4f,$ff,$7f,$7f,$38,$20,$27,$3f,$ff,$ff,$ff
  !byte $00,$0c,$4c,$66,$66,$66,$7f,$e0,$00,$0f,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fe,$fe,$fe,$fe,$fe,$fe,$7e,$7f,$ff,$ff,$ff,$7f,$3f,$bf,$ff,$ff
  !byte $04,$cc,$cc,$4c,$4c,$6f,$fe,$7c,$18,$01,$c1,$c0,$8e,$9f,$bf,$9f
  !byte $03,$30,$30,$30,$30,$98,$fe,$fe,$3f,$00,$e0,$f1,$c7,$0f,$3f,$70
  !byte $f8,$f0,$f3,$fb,$f9,$f9,$f9,$ff,$f8,$fc,$ff,$ff,$ff,$ff,$fe,$fe
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$07,$07,$ff,$3f,$0f,$c3,$03,$0f,$f9
  !byte $3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$e0,$00,$08,$e6,$e7,$e6,$f0,$c1
  !byte $1e,$00,$00,$1f,$1f,$4f,$bf,$3f,$3f,$3c,$80,$83,$bf,$ff,$ff,$ff
  !byte $00,$06,$66,$26,$37,$33,$3f,$f0,$80,$8f,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$3f,$ff,$ff
  !byte $01,$dd,$cc,$cc,$cc,$4e,$fc,$fc,$39,$03,$c1,$c0,$8c,$1f,$3f,$bf
  !byte $03,$10,$30,$31,$99,$98,$bc,$fc,$0f,$00,$f0,$f1,$c3,$8f,$1f,$70
  !byte $fc,$f0,$f3,$f9,$f9,$f9,$f9,$fd,$fc,$fc,$ff,$ff,$ff,$ff,$fe,$fe
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$8f,$0f,$7f,$ff,$1f,$07,$03,$07,$ff
  !byte $3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$e8,$00,$00,$e4,$e7,$e7,$f0,$c0
  !byte $3e,$00,$00,$1f,$1f,$8f,$1f,$1f,$1f,$9c,$c0,$c1,$ff,$ff,$ff,$ff
  !byte $00,$07,$33,$33,$33,$93,$9f,$f0,$80,$cf,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$7f,$ff,$ff
  !byte $01,$19,$99,$99,$99,$dc,$fc,$f8,$71,$03,$83,$c0,$9c,$3f,$3f,$3f
  !byte $03,$30,$b8,$99,$99,$99,$fc,$fc,$03,$00,$f8,$f1,$e3,$8f,$1f,$30
  !byte $fc,$f8,$f9,$f9,$f9,$fd,$fc,$fd,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$0f,$7f,$ff,$3f,$07,$07,$0f,$ff
  !byte $3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$c0,$00,$01,$e0,$e6,$e7,$f0,$c0
  !byte $3e,$20,$80,$8f,$9f,$9f,$1f,$0f,$4f,$cc,$e0,$e3,$ff,$ff,$ff,$ff
  !byte $80,$83,$99,$99,$99,$c9,$cf,$f0,$c0,$c7,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$ff,$ff
  !byte $03,$33,$99,$99,$99,$9d,$fd,$f9,$73,$03,$03,$80,$98,$3f,$3f,$3f
  !byte $03,$18,$90,$91,$91,$c9,$f9,$f9,$03,$00,$fc,$f0,$e3,$c7,$0f,$b0
  !byte $fe,$f8,$f9,$f9,$fc,$fc,$fc,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$9f,$1f,$7f,$ff,$7f,$0f,$0f,$0f,$7f
  !byte $3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$c8,$00,$03,$c0,$e0,$e7,$f8,$c0
  !byte $1e,$10,$80,$8f,$8f,$9f,$0f,$07,$67,$e4,$e0,$e1,$ff,$ff,$ff,$ff
  !byte $80,$89,$c9,$cc,$cc,$cc,$ef,$f8,$e0,$e7,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$ff,$ff
  !byte $07,$33,$33,$33,$39,$99,$f9,$f9,$f3,$07,$07,$80,$98,$3f,$3f,$1f
  !byte $03,$18,$80,$80,$c0,$c1,$f3,$f9,$00,$00,$fc,$f8,$e3,$c7,$8e,$90
  !byte $fe,$f8,$f9,$f9,$fc,$fc,$fc,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$3f,$ff,$ff,$ff,$1f,$0f,$1f,$ff
  !byte $3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$c8,$00,$07,$80,$e0,$e6,$f0,$c0
  !byte $1e,$00,$00,$8f,$0f,$97,$87,$07,$73,$f2,$e0,$e1,$ff,$ff,$ff,$ff
  !byte $c0,$cc,$cc,$cc,$e6,$e6,$e7,$f8,$f0,$f3,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$ff,$ff,$ff
  !byte $07,$67,$67,$73,$33,$33,$f9,$f1,$e3,$27,$07,$80,$18,$3f,$1f,$1f
  !byte $01,$18,$80,$c0,$c4,$c2,$73,$73,$00,$00,$f8,$f8,$f1,$e3,$ce,$d0
  !byte $fe,$f8,$f8,$fc,$fc,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$ff,$ff,$ff,$3f,$1f,$1f,$ff
  !byte $7f,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$88,$00,$07,$03,$c0,$f4,$f8,$c0
  !byte $0e,$00,$00,$07,$1f,$93,$83,$03,$79,$f8,$e0,$e1,$ff,$ff,$ff,$ff
  !byte $c0,$c4,$e6,$e6,$e6,$f3,$f3,$fc,$f8,$fb,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $0f,$67,$67,$67,$73,$33,$73,$f3,$67,$07,$07,$80,$10,$3e,$1f,$0f
  !byte $01,$18,$c0,$c0,$cc,$66,$66,$72,$00,$00,$f8,$f8,$f0,$e3,$c6,$c8
  !byte $fe,$f8,$fc,$fc,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$3f,$ff
  !byte $7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$c8,$00,$03,$07,$00,$f0,$f8,$c0
  !byte $66,$20,$00,$03,$1f,$91,$81,$09,$3c,$fc,$f0,$e0,$ff,$ff,$ff,$ff
  !byte $e0,$e6,$e2,$f3,$f3,$f9,$fb,$fc,$fc,$fd,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1f,$4f,$cf,$e7,$67,$67,$73,$e3,$27,$0f,$0f,$01,$20,$0c,$0f,$0f
  !byte $01,$1c,$c0,$c0,$44,$44,$26,$66,$00,$80,$f0,$f8,$f0,$e3,$e6,$e8
  !byte $ff,$fc,$fc,$fc,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$ff
  !byte $7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$c9,$01,$07,$07,$03,$c0,$f8,$c0
  !byte $72,$30,$01,$03,$9d,$81,$80,$0c,$7c,$fe,$f8,$e0,$f6,$ff,$ff,$ff
  !byte $f0,$f2,$f3,$f9,$f9,$f9,$fd,$fc,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $1f,$1f,$cf,$cf,$67,$67,$77,$e7,$07,$0f,$1f,$01,$00,$4c,$07,$07
  !byte $01,$0c,$c0,$00,$00,$44,$0c,$44,$80,$80,$f2,$f0,$f8,$f1,$e2,$f0
  !byte $ff,$fc,$fc,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$ff
  !byte $7f,$7f,$ff,$ff,$ff,$ff,$7f,$7f,$09,$01,$07,$03,$03,$00,$f0,$c0
  !byte $32,$30,$01,$05,$1c,$90,$80,$0e,$3e,$fe,$f0,$e0,$f4,$fe,$ff,$ff
  !byte $f0,$f2,$f9,$f9,$fc,$fc,$ff,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $3f,$1f,$9f,$1f,$4f,$cf,$e7,$e7,$07,$0f,$1f,$01,$01,$45,$07,$13
  !byte $00,$0c,$40,$02,$01,$11,$0c,$cc,$80,$c3,$fe,$f0,$f0,$f1,$f2,$f4
  !byte $ff,$fc,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $7f,$7f,$ff,$ff,$7f,$7f,$3f,$3f,$8f,$03,$07,$13,$33,$00,$c0,$c0
  !byte $18,$10,$40,$07,$1c,$10,$83,$0f,$3f,$fe,$f8,$e0,$f0,$fc,$ff,$ff
  !byte $f8,$f8,$fc,$fc,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $3f,$3f,$1f,$1f,$0f,$cf,$ef,$07,$0f,$0f,$1f,$07,$01,$41,$03,$11
  !byte $00,$0c,$60,$03,$03,$31,$99,$98,$80,$c7,$ff,$e0,$f0,$f8,$f2,$fc
  !byte $ff,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $7f,$7f,$ff,$7f,$3f,$3f,$9f,$9f,$cf,$07,$07,$13,$73,$03,$00,$e0
  !byte $1c,$40,$40,$07,$1c,$10,$81,$87,$bf,$fe,$f8,$f0,$f0,$f8,$fe,$ff
  !byte $f8,$fc,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $7f,$7f,$3f,$3f,$1f,$9f,$ef,$0f,$0f,$9f,$1f,$07,$01,$41,$01,$19
  !byte $04,$04,$60,$02,$03,$13,$13,$90,$80,$cf,$cf,$e6,$e0,$f8,$f8,$fc
  !byte $ff,$fe,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $7f,$7f,$ff,$3f,$1f,$9f,$8f,$cf,$87,$07,$03,$13,$73,$0f,$00,$c0
  !byte $4c,$60,$41,$07,$1c,$10,$83,$8f,$ff,$fe,$f8,$f0,$f0,$f0,$f0,$ff
  !byte $fc,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $7f,$7f,$3f,$3f,$3f,$9f,$df,$0f,$0f,$9f,$3f,$1f,$01,$41,$04,$0c
  !byte $86,$04,$20,$02,$00,$03,$13,$10,$80,$9f,$cf,$fe,$e0,$f0,$fc,$fc
  !byte $ff,$fe,$fc,$fc,$ff,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $7f,$3f,$ff,$1f,$0f,$cf,$e7,$e7,$87,$07,$03,$33,$7b,$ff,$00,$80
  !byte $64,$60,$01,$07,$1c,$30,$83,$87,$ff,$fe,$fc,$f0,$f0,$e0,$e0,$ff
  !byte $fc,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
  !byte $7f,$7f,$3f,$3f,$3f,$3f,$9f,$07,$07,$8f,$1f,$1f,$01,$40,$04,$0e
  !byte $86,$05,$30,$00,$08,$06,$47,$20,$20,$9f,$9f,$ff,$e0,$e0,$fc,$fc
  !byte $ff,$fe,$fc,$f8,$ff,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
  !byte $3f,$bf,$df,$0f,$0f,$67,$e7,$e7,$87,$07,$13,$13,$79,$fd,$00,$00
  !byte $32,$30,$01,$07,$0c,$30,$81,$87,$ff,$ff,$fc,$f0,$f0,$e1,$c0,$e0
  !byte $f8,$fc,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$3f
  !byte $7f,$3f,$3f,$3f,$7f,$3f,$07,$07,$07,$0f,$1f,$3d,$00,$00,$86,$07
  !byte $86,$07,$31,$00,$88,$0e,$46,$60,$20,$37,$9f,$9f,$c0,$c0,$fc,$fc
  !byte $ff,$fe,$fc,$f8,$fb,$fe,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
  !byte $9f,$ff,$cf,$07,$27,$73,$f3,$ef,$87,$07,$33,$31,$79,$fc,$30,$02
  !byte $30,$98,$81,$07,$0c,$38,$91,$97,$ff,$fe,$fc,$f0,$f0,$e1,$c0,$c0
  !byte $f9,$f9,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$3f,$3f
  !byte $7f,$3f,$1f,$bf,$7f,$7f,$07,$07,$07,$0f,$1f,$3c,$00,$02,$87,$13
  !byte $07,$03,$33,$81,$88,$0c,$4e,$60,$60,$37,$3f,$9e,$fe,$c0,$e0,$fc
  !byte $c0,$ff,$fc,$f8,$f1,$fe,$fc,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f
  !byte $df,$e7,$c7,$03,$33,$f9,$f9,$ef,$87,$03,$33,$39,$79,$fc,$f8,$00
  !byte $98,$88,$c1,$07,$04,$38,$19,$9f,$ff,$ff,$fc,$f8,$f0,$f1,$c3,$80
  !byte $f9,$f9,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$3f,$1f,$9f
  !byte $3f,$3f,$9f,$ff,$ff,$7f,$03,$03,$27,$0f,$1f,$1c,$00,$03,$83,$11
  !byte $07,$13,$31,$81,$89,$09,$04,$c0,$e0,$67,$3f,$3e,$fe,$c0,$c0,$fc
  !byte $80,$ff,$fc,$f8,$f1,$f6,$fc,$f8,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f
  !byte $ff,$63,$c3,$09,$38,$7c,$ff,$ef,$87,$07,$33,$71,$fb,$fc,$f0,$02
  !byte $cc,$c0,$e3,$03,$1e,$38,$1d,$9f,$df,$ff,$fc,$f8,$f0,$e1,$c7,$80
  !byte $f9,$f9,$fc,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$3f,$9f,$8f,$cf
  !byte $3f,$9f,$9f,$ff,$ff,$f7,$03,$03,$27,$0f,$0e,$1c,$00,$03,$81,$98
  !byte $03,$11,$11,$80,$81,$01,$00,$80,$c8,$e6,$7e,$3e,$3c,$80,$c0,$f9
  !byte $00,$80,$fc,$f8,$f1,$e6,$fc,$f8,$fc,$fc,$fe,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$3f
  !byte $73,$61,$c1,$0c,$3c,$7e,$ff,$ef,$87,$07,$33,$f9,$fa,$fc,$f0,$e3
  !byte $c4,$e0,$e1,$c3,$0e,$3c,$3f,$9f,$9f,$ff,$fc,$f8,$f0,$f1,$c3,$8f
  !byte $f9,$fb,$f9,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$3f,$9f,$cf,$cf,$e7
  !byte $1f,$9f,$df,$ff,$ff,$f3,$03,$13,$67,$47,$4e,$9c,$08,$01,$c0,$cc
  !byte $03,$01,$19,$84,$86,$03,$30,$18,$88,$ce,$ee,$7e,$3c,$c0,$80,$f9
  !byte $00,$00,$fe,$f8,$f1,$e3,$ec,$f8,$f9,$f8,$fc,$fe,$ff,$ff,$ff,$ff
  !byte $ff,$fe,$ff,$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$3f
  !byte $31,$e1,$c4,$0e,$3e,$7f,$ff,$cf,$87,$03,$31,$f9,$fe,$fc,$f0,$e3
  !byte $e5,$f0,$e1,$c1,$0e,$3e,$3f,$9f,$9f,$ff,$fc,$f8,$f1,$f1,$c3,$8f
  !byte $f9,$fb,$f9,$fc,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$3f,$1f,$cf,$c7,$e7,$7f
  !byte $9f,$8f,$df,$ff,$ff,$c1,$01,$33,$67,$47,$4e,$9c,$00,$00,$c4,$c6
  !byte $03,$09,$1c,$cc,$87,$03,$70,$38,$19,$8e,$ce,$fc,$7c,$7c,$80,$80
  !byte $18,$00,$0c,$f8,$f1,$c2,$cc,$f8,$f1,$f9,$f8,$fc,$fe,$ff,$ff,$ff
  !byte $ff,$7e,$7e,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$3f
  !byte $b0,$e0,$c6,$8f,$1f,$7f,$ff,$cf,$87,$13,$31,$f9,$fe,$fc,$f0,$e3
  !byte $f1,$f1,$e0,$c7,$0f,$3f,$3f,$9f,$9f,$ff,$fe,$f8,$f9,$e1,$c7,$8f
  !byte $f9,$f3,$fb,$fc,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$1f,$4f,$e7,$63,$73,$3d
  !byte $9f,$cf,$ff,$ff,$fb,$c1,$01,$33,$63,$67,$ce,$cc,$90,$00,$66,$e3
  !byte $c1,$08,$0c,$c6,$87,$03,$62,$70,$39,$9e,$8c,$fc,$7c,$7c,$80,$80
  !byte $1f,$00,$00,$f8,$f1,$e2,$cc,$d8,$f1,$f3,$f9,$fc,$fc,$fe,$ff,$ff
  !byte $7f,$3e,$1c,$9f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$3f,$9f
  !byte $b0,$e2,$c7,$8f,$1f,$ff,$ff,$cf,$87,$13,$31,$79,$fe,$fc,$f1,$e3
  !byte $f9,$f8,$e0,$c7,$8f,$1f,$3f,$1f,$9f,$ff,$fe,$fc,$f9,$e3,$c7,$8f
  !byte $f9,$fb,$f3,$f9,$fc,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$0f,$47,$e7,$73,$3f,$9c
  !byte $cf,$cf,$ff,$7f,$f9,$c1,$09,$73,$f3,$e7,$e6,$cc,$c8,$02,$07,$f3
  !byte $c1,$08,$0c,$c6,$83,$03,$02,$60,$71,$38,$9c,$dc,$fc,$79,$e0,$00
  !byte $1f,$30,$00,$18,$f1,$e3,$ce,$98,$f0,$e3,$f3,$f9,$fc,$fe,$ff,$ff
  !byte $3f,$9e,$9c,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$3f,$9f
  !byte $f1,$63,$47,$8f,$9f,$ff,$ff,$c7,$87,$13,$39,$7d,$fe,$fc,$f8,$e3
  !byte $fc,$f0,$e2,$c7,$8f,$1f,$3f,$1f,$9f,$ff,$fe,$fc,$f9,$e3,$c7,$8f
  !byte $fb,$f3,$f3,$f9,$fc,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$9f,$0f,$07,$63,$71,$39,$9e,$d8
  !byte $cf,$ef,$7f,$7f,$f0,$80,$09,$79,$f3,$e7,$e6,$cc,$c8,$01,$03,$f9
  !byte $e1,$cc,$4e,$e7,$b3,$19,$4e,$e4,$73,$39,$1d,$99,$f9,$f9,$f8,$00
  !byte $1f,$3e,$00,$00,$f1,$e3,$c4,$88,$d0,$e2,$e3,$f1,$f9,$fc,$fe,$ff
  !byte $9f,$ce,$fc,$f8,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$9f,$8f
  !byte $71,$23,$c7,$cf,$ff,$ff,$ff,$c7,$83,$13,$39,$7d,$fe,$fc,$f8,$f1
  !byte $fa,$f1,$e3,$c7,$8f,$1f,$3f,$3f,$9f,$ff,$fe,$fc,$f8,$e9,$c7,$8f
  !byte $f3,$f3,$f3,$f1,$f8,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$8f,$07,$33,$31,$39,$9f,$ce,$e8
  !byte $c7,$ef,$7f,$7f,$f0,$80,$09,$79,$f3,$f3,$e6,$e4,$e8,$11,$09,$fc
  !byte $e0,$cc,$c6,$e3,$b1,$19,$0e,$c6,$e3,$73,$3d,$99,$f9,$f9,$f9,$80
  !byte $1f,$3f,$60,$00,$31,$e2,$c4,$88,$90,$e2,$e7,$f3,$f1,$f8,$fc,$ff
  !byte $cf,$ee,$fc,$f8,$f8,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$9f,$cf
  !byte $39,$a3,$c7,$cf,$ff,$ff,$ff,$cf,$87,$13,$39,$7d,$fe,$fc,$f9,$f1
  !byte $ff,$f1,$e3,$c7,$8f,$1f,$3f,$3f,$9f,$df,$fe,$fc,$f8,$f9,$cf,$8f
  !byte $f3,$f3,$f3,$f3,$f9,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$9f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$cf,$87,$03,$31,$38,$9d,$cf,$e6,$7c
  !byte $e7,$7f,$3f,$7c,$e0,$84,$19,$79,$f3,$f3,$f2,$e4,$f8,$19,$0c,$fe
  !byte $e4,$ce,$e7,$f3,$f9,$3d,$1e,$8f,$c7,$e7,$79,$39,$b9,$fb,$f3,$e0
  !byte $1f,$3f,$7f,$81,$01,$63,$c6,$8c,$19,$30,$e6,$e7,$f3,$f9,$fc,$ff
  !byte $e7,$fe,$fc,$f8,$f0,$f0,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$1f,$8f,$c7
  !byte $11,$a3,$e7,$ff,$ff,$ff,$ef,$c7,$83,$11,$39,$7f,$fe,$fc,$f9,$f1
  !byte $ff,$f3,$e3,$c7,$8f,$1f,$3f,$3f,$9f,$df,$fe,$fc,$f8,$fd,$ff,$9f
  !byte $33,$f3,$f3,$f7,$f1,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$0f,$c7
  !byte $ff,$ff,$ff,$7f,$7f,$ff,$ff,$c7,$83,$11,$38,$1c,$8f,$c6,$64,$38
  !byte $e7,$7f,$3f,$f8,$e0,$84,$1c,$79,$f9,$f3,$f2,$f4,$f8,$b8,$1c,$fe
  !byte $e4,$ce,$e7,$f3,$f9,$7c,$3e,$1f,$8f,$c7,$f3,$79,$3b,$f3,$f3,$f0
  !byte $1f,$3f,$7f,$e1,$01,$03,$c6,$8c,$99,$31,$e4,$ce,$e7,$f3,$f9,$fc
  !byte $ff,$fe,$fc,$f8,$f8,$f0,$f3,$ff,$ff,$ff,$ff,$7f,$3f,$1f,$8f,$c7
  !byte $d9,$f3,$f7,$ff,$ff,$ff,$ef,$c7,$83,$11,$39,$7f,$fe,$fc,$f9,$f1
  !byte $ff,$f3,$e3,$c7,$8f,$1f,$3f,$3f,$1f,$9f,$fe,$fc,$f8,$fd,$ff,$9f
  !byte $03,$f3,$f3,$f7,$f1,$f8,$fc,$fe,$ff,$ff,$7f,$ff,$1f,$0f,$47,$e3
  !byte $ff,$ff,$ff,$7f,$7f,$ff,$e7,$c3,$81,$18,$1c,$4e,$e7,$73,$3e,$1c
  !byte $f7,$7f,$3e,$f8,$e0,$84,$1c,$7c,$f9,$f9,$f3,$f2,$fc,$bc,$1e,$7f
  !byte $e0,$c7,$e3,$f1,$f8,$fe,$7f,$3f,$9f,$c7,$eb,$7b,$33,$f3,$f3,$f0
  !byte $3f,$3f,$7f,$f3,$03,$02,$c4,$88,$19,$31,$60,$cc,$c6,$e3,$f1,$f9
  !byte $ff,$fe,$fc,$f8,$f1,$f0,$e0,$ff,$ff,$ff,$ff,$7f,$1f,$8f,$c7,$e7
  !byte $f9,$f3,$ff,$ff,$ff,$ff,$ef,$c7,$83,$19,$3c,$7f,$fe,$fc,$f9,$f0
  !byte $ff,$f3,$e3,$c7,$8f,$1f,$3f,$3f,$1f,$9f,$fe,$fc,$fc,$fd,$ff,$ff
  !byte $03,$f3,$f3,$f7,$f3,$f8,$fc,$fe,$ff,$7f,$7f,$9f,$0f,$27,$73,$fb
  !byte $fe,$ff,$7f,$7f,$7f,$ff,$e7,$c1,$88,$1c,$0e,$47,$73,$3a,$1e,$8c
  !byte $7f,$3f,$bc,$f0,$c2,$0c,$3c,$fd,$f9,$f9,$f2,$fa,$fc,$fe,$1f,$3f
  !byte $e2,$e7,$f3,$f8,$fc,$fe,$ff,$7f,$1f,$8f,$cf,$f3,$73,$73,$f3,$f0
  !byte $3f,$3f,$7f,$ff,$c3,$03,$44,$88,$99,$33,$61,$c0,$8c,$c7,$e3,$f1
  !byte $ff,$fe,$fc,$f8,$f9,$f0,$e0,$e3,$ff,$ff,$fe,$3f,$1f,$8f,$e7,$f7
  !byte $f8,$f9,$ff,$ff,$ff,$ff,$ef,$c7,$83,$19,$3c,$7e,$fe,$fc,$f9,$f0
  !byte $ff,$f3,$e3,$c7,$8f,$1f,$3f,$7f,$1f,$9f,$fe,$fe,$fc,$fd,$ff,$ff
  !byte $03,$37,$e7,$e7,$e7,$f9,$f8,$fe,$7f,$3f,$5f,$8f,$03,$31,$79,$ff
  !byte $fe,$7f,$7f,$7f,$7f,$77,$e3,$c0,$8c,$0e,$07,$63,$39,$1f,$8e,$cc
  !byte $3f,$1f,$bc,$f0,$c2,$0e,$3c,$fc,$fd,$f9,$f8,$fe,$fe,$ff,$1f,$3f
  !byte $e2,$e3,$f1,$f8,$fc,$ff,$ff,$7f,$3f,$1f,$8f,$e7,$f3,$73,$f3,$f0
  !byte $ff,$7f,$7f,$ff,$e7,$07,$05,$88,$98,$33,$63,$41,$8c,$8e,$c7,$e3
  !byte $ff,$fe,$fc,$f8,$f9,$f3,$e0,$c0,$e7,$ff,$7e,$3e,$1f,$c7,$e3,$77
  !byte $f9,$ff,$ff,$ff,$ff,$ff,$cf,$c7,$91,$18,$3d,$7e,$fc,$fc,$f8,$f0
  !byte $ff,$f3,$e7,$c7,$8f,$1f,$3f,$7f,$1f,$9f,$fe,$fc,$fc,$fd,$ff,$ff
  !byte $03,$17,$e7,$e7,$e7,$f1,$f8,$7c,$3f,$3f,$cf,$83,$11,$39,$7f,$ff
  !byte $fe,$7e,$3f,$7f,$7f,$73,$60,$c4,$8e,$87,$23,$39,$1d,$8e,$e6,$f4
  !byte $3f,$1f,$fc,$f0,$42,$8e,$9e,$fc,$fc,$fc,$fd,$fe,$ff,$ff,$3f,$3f
  !byte $e2,$e3,$f1,$f8,$fe,$ff,$ff,$ff,$7f,$3f,$1f,$c7,$e7,$67,$e7,$e6
  !byte $ff,$ff,$7f,$ff,$ff,$87,$07,$09,$98,$32,$23,$43,$89,$9c,$8e,$c7
  !byte $ff,$fe,$fc,$f8,$f9,$f3,$e0,$c0,$c3,$ff,$7e,$3c,$0e,$c7,$e3,$7f
  !byte $fc,$ff,$ff,$ff,$ff,$ff,$cf,$c7,$91,$18,$3d,$7e,$fc,$fc,$f8,$f0
  !byte $ff,$f3,$e3,$c7,$cf,$9f,$3f,$3f,$3f,$9f,$de,$fe,$fc,$fd,$ff,$ff
  !byte $01,$07,$e7,$e7,$e7,$f1,$78,$3c,$1f,$ef,$c3,$81,$18,$3f,$7f,$7f
  !byte $fb,$3e,$3f,$3f,$7b,$71,$60,$c6,$87,$83,$31,$1c,$8f,$c7,$f2,$fc
  !byte $3f,$9e,$f8,$f1,$42,$8e,$fe,$fe,$fc,$fc,$ff,$ff,$ff,$ff,$3f,$3f
  !byte $e3,$e3,$f0,$fc,$fe,$ff,$ff,$ff,$ff,$7f,$1f,$8f,$e7,$e7,$e7,$e6
  !byte $ff,$ff,$ff,$ff,$ff,$cf,$0f,$09,$90,$30,$27,$43,$81,$98,$1e,$c7
  !byte $ff,$ff,$fc,$f8,$f9,$f3,$e6,$c0,$c0,$87,$3e,$1c,$0c,$c3,$f3,$3f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$cf,$c3,$91,$18,$3f,$7e,$fc,$fc,$f8,$f0
  !byte $ff,$f7,$e3,$c7,$cf,$9f,$1f,$3f,$3f,$1f,$df,$fe,$fc,$fc,$ff,$ff
  !byte $81,$07,$67,$e7,$e7,$63,$39,$1c,$a6,$e3,$c1,$8c,$1e,$3f,$7f,$7f
  !byte $33,$3e,$3e,$3f,$71,$70,$66,$47,$83,$91,$1c,$8f,$c7,$f3,$fa,$fe
  !byte $1f,$9e,$f8,$61,$47,$8e,$fe,$fe,$fc,$fc,$ff,$ff,$ff,$ff,$3f,$3f
  !byte $f3,$f1,$f8,$fe,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$1f,$e7,$e7,$e7,$e7
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$0f,$0f,$11,$30,$26,$47,$c3,$90,$1c,$8f
  !byte $ff,$ff,$fd,$f9,$f1,$f3,$e7,$c4,$c0,$83,$1e,$0e,$44,$e1,$7b,$3f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ef,$c3,$81,$18,$3f,$7e,$7e,$fc,$f8,$f0
  !byte $ff,$f7,$e7,$c7,$8f,$9f,$3f,$3f,$3f,$1f,$5f,$7e,$fc,$fc,$ff,$ff
  !byte $c0,$07,$27,$e7,$e7,$27,$11,$94,$e2,$c1,$cc,$9e,$1f,$3f,$7f,$7f
  !byte $13,$3b,$3e,$39,$30,$70,$67,$43,$41,$98,$8e,$c7,$e3,$f9,$fe,$ff
  !byte $8f,$dc,$f8,$23,$07,$cf,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$7f,$3f
  !byte $f3,$f0,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$1f,$8f,$cf,$cf,$ef
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$df,$0f,$13,$30,$24,$46,$c7,$81,$18,$1c
  !byte $ff,$ff,$ff,$f9,$f9,$f3,$e3,$e6,$c8,$81,$06,$0e,$40,$f0,$3d,$1f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$c7,$c3,$90,$1c,$3f,$7e,$7c,$fc,$f8,$f1
  !byte $ff,$f7,$e7,$c7,$cf,$9f,$1f,$3f,$3f,$1f,$1f,$fe,$fc,$fc,$ff,$ff
  !byte $e0,$03,$07,$e7,$67,$07,$81,$f0,$e0,$64,$ce,$8f,$9f,$3f,$3f,$ff
  !byte $03,$33,$3c,$38,$30,$33,$63,$41,$48,$9e,$87,$e3,$f1,$fd,$ff,$ff
  !byte $8e,$fc,$70,$23,$87,$cf,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$7f
  !byte $f1,$f8,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$cf,$cf,$cf
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$17,$31,$20,$44,$4f,$83,$11,$18
  !byte $ff,$ff,$ff,$ff,$fb,$f3,$e3,$e7,$cc,$00,$02,$06,$60,$70,$39,$0f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$c7,$83,$90,$1c,$3f,$7e,$7c,$fc,$f8,$f1
  !byte $ff,$e7,$e7,$cf,$8f,$9f,$3f,$3f,$3f,$1f,$9f,$fe,$fc,$fc,$ff,$ff
  !byte $c0,$83,$07,$67,$07,$87,$c1,$f0,$60,$66,$cf,$8f,$9f,$3f,$bf,$ff
  !byte $07,$03,$9c,$38,$30,$33,$21,$00,$4c,$8f,$e3,$f0,$fc,$ff,$ff,$ff
  !byte $ce,$fc,$38,$23,$c7,$ef,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
  !byte $f1,$f8,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$8f,$cf,$cf
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$bf,$1f,$33,$21,$40,$ce,$87,$83,$10
  !byte $ff,$ff,$ff,$ff,$f7,$f3,$e7,$e7,$ce,$00,$00,$06,$00,$78,$39,$09
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$c7,$c3,$98,$1c,$3f,$7e,$7c,$fc,$f8,$f9
  !byte $7f,$ef,$e7,$cf,$8f,$9f,$1f,$3f,$3f,$1f,$9f,$fe,$fe,$fc,$ff,$ff
  !byte $c0,$c1,$0f,$2f,$07,$c3,$e1,$70,$24,$c6,$cf,$8f,$9f,$bf,$ff,$ff
  !byte $0f,$81,$90,$38,$30,$33,$20,$24,$4e,$c3,$f1,$f8,$fe,$ff,$ff,$ff
  !byte $ce,$f8,$31,$03,$c7,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
  !byte $f1,$f8,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$1f,$cf,$cf
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$2f,$23,$40,$4c,$8f,$87,$01
  !byte $ff,$ff,$ff,$ff,$ff,$f7,$e7,$e7,$cf,$0c,$00,$02,$00,$3c,$19,$89
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$c7,$c1,$98,$1c,$3f,$3e,$7c,$fc,$f8,$f9
  !byte $7f,$ff,$e7,$c7,$cf,$9f,$1f,$1f,$3f,$1f,$8f,$fe,$fe,$fe,$ff,$ff
  !byte $c0,$41,$07,$0f,$c7,$e0,$20,$30,$e0,$e6,$4f,$cf,$9f,$ff,$ff,$ff
  !byte $1f,$84,$80,$98,$90,$b0,$20,$27,$c3,$f1,$f8,$fe,$ff,$ff,$ff,$ff
  !byte $ee,$78,$11,$83,$e7,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
  !byte $f8,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$5f,$df,$cf
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f,$27,$41,$48,$9e,$0f,$03
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$e7,$e7,$cf,$0c,$00,$00,$00,$1c,$09,$c8
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$c7,$c1,$98,$9e,$3e,$3e,$7c,$7c,$f8,$f9
  !byte $7f,$ef,$e7,$cf,$8f,$1f,$1f,$1f,$3f,$1f,$8f,$ff,$fe,$fe,$ff,$ff
  !byte $c8,$01,$07,$07,$60,$60,$00,$a1,$e0,$66,$4f,$cf,$ff,$ff,$ff,$ff
  !byte $1e,$0c,$80,$90,$90,$90,$a2,$a7,$e1,$f8,$fe,$ff,$ff,$ff,$ff,$ff
  !byte $fc,$38,$11,$c3,$e7,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $f8,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$1f,$9f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$2f,$43,$40,$9c,$0f,$07
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$e7,$0f,$0e,$00,$00,$00,$0c,$00,$e8
  !byte $ff,$ff,$ff,$ff,$ff,$cf,$c3,$80,$98,$1f,$3e,$3e,$7c,$7c,$f8,$f9
  !byte $7f,$ff,$c7,$cf,$0f,$1f,$1f,$3f,$3f,$1f,$0f,$de,$fe,$fe,$ff,$ff
  !byte $48,$00,$83,$05,$08,$20,$01,$e1,$e0,$24,$47,$cf,$ff,$ff,$ff,$ff
  !byte $48,$1c,$80,$81,$90,$90,$83,$e3,$f0,$fc,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $70,$18,$11,$e3,$f7,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $f8,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$1f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$4f,$c3,$80,$0c,$0e
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$cf,$0f,$0f,$00,$10,$20,$04,$00,$20
  !byte $ff,$ff,$ff,$ff,$ff,$cf,$c3,$80,$9c,$1f,$3e,$3e,$7e,$7c,$fc,$f8
  !byte $7f,$ff,$cf,$4f,$0f,$8f,$1f,$3f,$3f,$3f,$0f,$df,$fe,$fe,$ff,$ff
  !byte $18,$80,$c3,$0c,$08,$09,$c1,$e3,$20,$24,$e7,$ff,$ff,$ff,$ff,$ff
  !byte $00,$48,$18,$80,$80,$90,$c3,$f0,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $70,$18,$80,$e3,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $f8,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$1f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$47,$81,$08,$0e
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$07,$00,$10,$30,$00,$04,$18
  !byte $ff,$ff,$ff,$ff,$ff,$cf,$c3,$80,$9c,$9f,$3e,$3e,$7e,$7c,$fc,$f8
  !byte $ff,$ff,$4f,$0f,$8f,$9f,$9f,$3f,$3f,$3f,$0f,$cf,$fe,$fe,$ff,$ff
  !byte $0c,$80,$c0,$04,$09,$09,$e1,$23,$00,$e0,$f7,$ff,$ff,$ff,$ff,$ff
  !byte $00,$40,$0c,$08,$c0,$d0,$d0,$f8,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $30,$00,$c0,$f3,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$0f
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$cf,$83,$00,$0c
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$03,$01,$18,$38,$00,$00,$08
  !byte $ff,$ff,$ff,$ff,$ff,$cf,$c3,$80,$9c,$1f,$3e,$3e,$7e,$7c,$fc,$f8
  !byte $ff,$7f,$0f,$8f,$8f,$9f,$9f,$3f,$3f,$3f,$0f,$cf,$fe,$fe,$ff,$ff
  !byte $80,$90,$00,$04,$09,$09,$41,$03,$a0,$f0,$fe,$ff,$ff,$ff,$ff,$ff
  !byte $00,$40,$48,$08,$81,$c0,$f0,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $10,$00,$e0,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fc,$fc,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$0f,$03
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$df,$8f,$06,$00,$08
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$01,$11,$1f,$18,$00,$40,$08
  !byte $ff,$ff,$ff,$ff,$ff,$cf,$c3,$80,$9c,$9f,$3e,$3e,$3e,$7c,$fc,$f8
  !byte $7f,$1f,$07,$cf,$9f,$9f,$9f,$3f,$3f,$3f,$0f,$8f,$fe,$fe,$ff,$ff
  !byte $90,$98,$00,$04,$09,$09,$09,$83,$e1,$f0,$fe,$ff,$ff,$ff,$ff,$ff
  !byte $0c,$40,$40,$09,$01,$c0,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$80,$e0,$f4,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fe,$fc,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$07,$62
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$cf,$8f,$0e,$02,$00
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$07,$01,$19,$1f,$0c,$00,$20,$00
  !byte $ff,$ff,$ff,$ff,$ff,$c7,$c1,$98,$9f,$9f,$3e,$3e,$3e,$7c,$fc,$fc
  !byte $1f,$07,$c7,$cf,$8f,$9f,$9f,$1f,$3f,$3f,$0f,$8f,$ff,$fe,$ff,$ff
  !byte $3e,$18,$00,$84,$08,$09,$09,$c3,$e3,$f0,$fc,$ff,$ff,$ff,$ff,$ff
  !byte $0c,$00,$40,$69,$08,$00,$e4,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$40,$f2,$f4,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $fe,$fc,$fc,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$07,$41,$7a
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$df,$cf,$8f,$2e,$0e,$00
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$07,$01,$39,$3f,$07,$00,$70,$00
  !byte $ff,$ff,$ff,$ff,$ff,$c7,$c0,$98,$9f,$9f,$1e,$3e,$3e,$3c,$fc,$fc
  !byte $07,$e7,$df,$cf,$8f,$9f,$9f,$1f,$3f,$3f,$1f,$0f,$ff,$ff,$ff,$ff
  !byte $3e,$08,$80,$80,$09,$09,$09,$cb,$e7,$e0,$f8,$ff,$ff,$ff,$ff,$ff
  !byte $24,$04,$00,$61,$60,$0e,$84,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$00,$f2,$e6,$e4,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$1f
  !byte $fe,$fc,$fc,$fc,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$0f,$01,$72,$7e
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$cf,$87,$86,$26,$06,$02
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$1f,$01,$21,$3f,$1f,$03,$21,$70,$00
  !byte $ff,$ff,$ff,$ff,$ff,$c7,$80,$98,$9f,$9f,$3e,$3e,$3e,$7e,$fc,$fc
  !byte $47,$ff,$ff,$cf,$cf,$9f,$9f,$9f,$3f,$3f,$1f,$0f,$ef,$ff,$ff,$ff
  !byte $0e,$00,$30,$00,$08,$09,$09,$4f,$e7,$e0,$f8,$ff,$ff,$ff,$ff,$ff
  !byte $24,$24,$04,$40,$fc,$1f,$06,$e0,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$30,$72,$f2,$e4,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$07
  !byte $fe,$fe,$fc,$fc,$fc,$fc,$ff,$ff,$ff,$ff,$ff,$1f,$01,$60,$7e,$1e
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$c7,$87,$07,$26,$66,$06
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$07,$01,$39,$3f,$0f,$03,$33,$38,$00
  !byte $ff,$ff,$ff,$ff,$ff,$c7,$c0,$98,$9f,$9f,$1e,$3e,$3e,$3e,$fc,$fc
  !byte $7f,$ff,$ff,$cf,$9f,$9f,$9f,$9f,$3f,$3f,$1f,$0f,$ef,$ff,$ff,$ff
  !byte $06,$20,$30,$00,$00,$09,$0f,$4f,$cf,$e1,$f0,$fe,$ff,$ff,$ff,$ff
  !byte $20,$64,$04,$00,$f7,$7f,$06,$84,$f8,$ff,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $00,$10,$32,$72,$e4,$e4,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$07,$47
  !byte $fe,$fe,$fc,$fc,$fc,$fc,$ff,$ff,$ff,$ff,$3f,$03,$01,$7e,$7e,$06
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$c7,$c7,$87,$06,$26,$66,$26
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$bf,$03,$01,$3d,$3f,$03,$43,$7e,$1a,$00
  !byte $ff,$ff,$ff,$ff,$ff,$c3,$c0,$9c,$9f,$9f,$9e,$3e,$3e,$3e,$fc,$fe
  !byte $7f,$7f,$ff,$9f,$9f,$9f,$9f,$1f,$3f,$3f,$1f,$0f,$ef,$ff,$ff,$ff
  !byte $46,$7c,$30,$00,$04,$8d,$1f,$0f,$cf,$e1,$e0,$fe,$ff,$ff,$ff,$ff
  !byte $00,$70,$70,$06,$47,$ff,$3f,$06,$c0,$fd,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $40,$82,$12,$32,$e0,$e4,$e4,$fe,$ff,$ff,$ff,$ff,$7f,$07,$03,$7f
  !byte $fe,$fe,$fe,$fc,$fc,$fc,$fc,$ff,$ff,$ff,$0f,$01,$31,$7e,$0e,$02
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$c7,$87,$87,$26,$26,$76,$72
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$1f,$01,$31,$3f,$1f,$03,$73,$7e,$06,$00
  !byte $ff,$ff,$ff,$ff,$ff,$c3,$80,$9d,$9f,$9f,$1f,$3e,$3e,$3e,$fe,$fe
  !byte $7f,$ff,$ff,$9f,$9f,$9f,$9f,$9f,$3f,$3f,$3f,$07,$ef,$ff,$ff,$ff
  !byte $76,$7c,$00,$00,$84,$8f,$1f,$0f,$4f,$e7,$e0,$fc,$ff,$ff,$ff,$ff
  !byte $00,$70,$78,$0f,$07,$f7,$ff,$06,$84,$fc,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $60,$42,$82,$32,$72,$e4,$e4,$f4,$ff,$ff,$ff,$ff,$07,$03,$7f,$7f
  !byte $fe,$fe,$fe,$fc,$fc,$fc,$fc,$fc,$ff,$1f,$01,$31,$7f,$1e,$02,$72
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$c7,$c7,$87,$87,$26,$32,$72,$f2
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$0f,$01,$31,$3f,$0f,$03,$73,$7e,$06,$00
  !byte $ff,$ff,$ff,$ff,$ff,$c3,$80,$9f,$9f,$9f,$9e,$3e,$3e,$3e,$fe,$fe
  !byte $7f,$7f,$ff,$9f,$9f,$9f,$9f,$9f,$3f,$3f,$3f,$07,$cf,$ff,$ff,$ff
  !byte $7e,$06,$00,$30,$23,$8f,$1f,$0f,$4f,$c7,$e0,$f8,$ff,$ff,$ff,$ff
  !byte $02,$00,$7e,$7f,$07,$03,$ff,$3e,$04,$c4,$ff,$ff,$ff,$ff,$ff,$ff
  !byte $60,$42,$82,$12,$32,$72,$e4,$e4,$fc,$ff,$7f,$03,$03,$7f,$7f,$7f
  !byte $fe,$fe,$fc,$fc,$fc,$fc,$fc,$fc,$7c,$01,$01,$3f,$7e,$02,$02,$7e
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ef,$c7,$c7,$87,$07,$32,$72,$72,$f2
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$03,$01,$3d,$3f,$03,$03,$7f,$3e,$02,$c0
  !byte $ff,$ff,$ff,$ff,$df,$c0,$80,$9f,$9f,$9f,$9e,$9e,$3e,$3e,$fe,$fe
  !byte $7f,$7f,$7f,$9f,$9f,$9f,$9f,$9f,$1f,$3f,$3f,$07,$87,$ff,$ff,$ff
  !byte $1e,$02,$62,$71,$23,$07,$8f,$1f,$0f,$4f,$e0,$e0,$ff,$ff,$ff,$ff
  !byte $12,$00,$72,$7e,$1f,$07,$f7,$ff,$06,$04,$fc,$ff,$ff,$ff,$ff,$ff
  !byte $72,$62,$c2,$82,$12,$32,$64,$e4,$e4,$ff,$07,$03,$3f,$7f,$7f,$7f
  !byte $fe,$fe,$fc,$fc,$fc,$fc,$fc,$fc,$04,$00,$39,$3f,$06,$02,$7e,$7e
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$e7,$c7,$87,$87,$33,$32,$72,$72,$f8
  !byte $ff,$ff,$ff,$ff,$ff,$bf,$01,$01,$3f,$3f,$03,$43,$7f,$0e,$02,$f0
  !byte $ff,$ff,$ff,$ff,$df,$c0,$80,$9f,$9f,$9f,$9f,$9e,$9e,$be,$fe,$ff
  !byte $7f,$7f,$ff,$9f,$9f,$9f,$9f,$9f,$3f,$3f,$3f,$07,$07,$ff,$ff,$ff
  !byte $02,$82,$7b,$71,$23,$07,$8f,$1f,$0f,$47,$e1,$e0,$ff,$ff,$ff,$ff
  !byte $f8,$03,$02,$7e,$7f,$07,$07,$ff,$7e,$04,$c4,$ff,$ff,$ff,$ff,$ff
  !byte $73,$e2,$c2,$82,$92,$32,$64,$64,$e4,$04,$03,$3f,$3f,$7f,$7f,$7f
  !byte $ff,$fe,$fc,$fc,$fc,$fc,$fc,$0c,$00,$30,$3d,$0f,$02,$7a,$7e,$02
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ef,$c7,$87,$87,$07,$32,$32,$72,$72,$f8
  !byte $ff,$ff,$ff,$ff,$ff,$0f,$01,$39,$3f,$0f,$03,$3b,$7e,$02,$00,$fe
  !byte $ff,$ff,$ff,$ff,$df,$80,$91,$9f,$9f,$9f,$9f,$9f,$1e,$be,$ff,$ff
  !byte $7f,$7f,$ff,$9f,$9f,$9f,$9f,$9f,$9f,$3f,$3f,$07,$07,$ff,$ff,$ff
  !byte $02,$fe,$ff,$71,$63,$07,$0f,$1f,$0f,$4f,$e7,$e0,$fc,$ff,$ff,$ff
  !byte $fe,$1f,$00,$62,$7e,$1f,$07,$f7,$ff,$06,$04,$fd,$ff,$ff,$ff,$ff
  !byte $ff,$f2,$e2,$c2,$82,$10,$24,$64,$04,$00,$30,$3f,$7f,$7f,$7f,$7f
  !byte $ff,$ff,$fc,$fc,$fc,$fc,$fc,$00,$00,$38,$38,$03,$02,$7e,$0e,$02
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$cf,$c7,$87,$87,$33,$33,$32,$72,$78,$f8
  !byte $ff,$ff,$ff,$ff,$ff,$07,$01,$3d,$3f,$07,$03,$7f,$7e,$02,$00,$ff
  !byte $ff,$ff,$ff,$ff,$cf,$80,$99,$9f,$9f,$9f,$9f,$9e,$9e,$9e,$ff,$ff
  !byte $7f,$ff,$ff,$ff,$9f,$9f,$9f,$9f,$3f,$3f,$3f,$0f,$07,$ff,$ff,$ff
  !byte $f2,$ff,$ff,$71,$73,$27,$07,$8f,$0f,$0f,$67,$e0,$f0,$ff,$ff,$ff
  !byte $ff,$ff,$03,$00,$7e,$7f,$07,$07,$ff,$fe,$04,$84,$ff,$ff,$ff,$ff
  !byte $ff,$f7,$e2,$c2,$82,$86,$26,$24,$00,$20,$24,$3f,$3f,$7f,$7f,$7f
  !byte $ff,$ff,$ff,$fc,$fc,$fc,$00,$00,$3c,$3c,$00,$00,$3f,$3e,$02,$02
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$c7,$c7,$87,$93,$33,$33,$71,$78,$78,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$01,$01,$3f,$3f,$03,$03,$3f,$3e,$02,$e2,$ff
  !byte $ff,$ff,$ff,$ff,$c7,$80,$9d,$9f,$9f,$9f,$9f,$9f,$9e,$9e,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$9f,$9f,$9f,$9f,$9f,$9f,$3f,$0f,$07,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$f3,$63,$27,$0f,$8f,$1f,$0f,$47,$e4,$f0,$ff,$ff,$ff
  !byte $ff,$ff,$3f,$00,$62,$7e,$1f,$07,$f7,$fe,$06,$04,$ff,$ff,$ff,$ff
  !byte $ff,$ff,$f2,$e2,$c2,$82,$90,$00,$00,$24,$24,$34,$3f,$7f,$7f,$7f
  !byte $ff,$ff,$ff,$ff,$fc,$04,$00,$3c,$3c,$00,$00,$3c,$3c,$01,$01,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$cf,$c7,$c7,$87,$93,$33,$33,$39,$79,$f9,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$01,$01,$3f,$3f,$01,$23,$3f,$02,$00,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$83,$81,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$1f,$07,$f7,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$73,$63,$07,$0f,$9f,$0f,$07,$64,$f0,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$00,$00,$7e,$7f,$07,$07,$ff,$fe,$04,$04,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$e2,$e2,$c2,$02,$02,$26,$24,$24,$24,$3e,$3f,$3f,$ff
  !byte $ff,$ff,$ff,$ff,$fc,$00,$00,$3c,$3c,$00,$00,$3c,$00,$00,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$c7,$c7,$87,$93,$93,$31,$39,$79,$7c,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$01,$01,$3f,$3f,$03,$01,$3f,$3f,$00,$00,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$81,$81,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$1f,$07,$07,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$f3,$63,$07,$0f,$9f,$0f,$0f,$67,$e0,$fe,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$00,$44,$fe,$7f,$07,$ff,$fe,$06,$04,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$f7,$e0,$00,$00,$10,$10,$34,$24,$24,$34,$3f,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$83,$01,$3c,$3c,$00,$00,$3c,$3c,$00,$00,$fc,$ff
  !byte $ff,$ff,$ff,$ff,$ef,$c7,$c7,$87,$93,$33,$33,$39,$79,$7d,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$83,$01,$3f,$3f,$03,$01,$3f,$3f,$00,$00,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$c1,$81,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$bf,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$07,$07,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$fb,$f3,$67,$07,$0f,$9f,$0f,$07,$60,$f0,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$05,$00,$7e,$7e,$07,$07,$7f,$7e,$02,$00,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$06,$02,$06,$06,$06,$06,$26,$26,$26,$26,$ff,$ff
  !byte $ff,$ff,$ff,$01,$01,$3f,$3c,$00,$00,$3c,$3c,$00,$00,$fc,$fc,$ff
  !byte $ff,$ff,$ff,$ff,$cf,$c7,$87,$93,$93,$31,$39,$39,$7c,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$01,$01,$3f,$3f,$01,$03,$3f,$00,$00,$ff,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$81,$81,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$bf,$9f,$9f,$9f,$9f,$9f,$9f,$9f,$03,$03,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$f3,$67,$07,$0f,$9f,$0f,$07,$60,$70,$ff,$ff
  !byte $ff,$ff,$ff,$ff,$ff,$00,$0e,$7e,$7f,$07,$7f,$7f,$02,$00,$ff,$ff
  !byte $ff,$ff,$ff,$03,$03,$26,$06,$06,$06,$06,$32,$32,$32,$f2,$ff,$ff



  !align 255,0,0
mirror:
;A list of all bytes "mirrored" horizontally
  !byte $00, $80, $40, $c0, $20, $a0, $60, $e0
  !byte $10, $90, $50, $d0, $30, $b0, $70, $f0
  !byte $08, $88, $48, $c8, $28, $a8, $68, $e8
  !byte $18, $98, $58, $d8, $38, $b8, $78, $f8
  !byte $04, $84, $44, $c4, $24, $a4, $64, $e4
  !byte $14, $94, $54, $d4, $34, $b4, $74, $f4
  !byte $0c, $8c, $4c, $cc, $2c, $ac, $6c, $ec
  !byte $1c, $9c, $5c, $dc, $3c, $bc, $7c, $fc
  !byte $02, $82, $42, $c2, $22, $a2, $62, $e2
  !byte $12, $92, $52, $d2, $32, $b2, $72, $f2
  !byte $0a, $8a, $4a, $ca, $2a, $aa, $6a, $ea
  !byte $1a, $9a, $5a, $da, $3a, $ba, $7a, $fa
  !byte $06, $86, $46, $c6, $26, $a6, $66, $e6
  !byte $16, $96, $56, $d6, $36, $b6, $76, $f6
  !byte $0e, $8e, $4e, $ce, $2e, $ae, $6e, $ee
  !byte $1e, $9e, $5e, $de, $3e, $be, $7e, $fe
  !byte $01, $81, $41, $c1, $21, $a1, $61, $e1
  !byte $11, $91, $51, $d1, $31, $b1, $71, $f1
  !byte $09, $89, $49, $c9, $29, $a9, $69, $e9
  !byte $19, $99, $59, $d9, $39, $b9, $79, $f9
  !byte $05, $85, $45, $c5, $25, $a5, $65, $e5
  !byte $15, $95, $55, $d5, $35, $b5, $75, $f5
  !byte $0d, $8d, $4d, $cd, $2d, $ad, $6d, $ed
  !byte $1d, $9d, $5d, $dd, $3d, $bd, $7d, $fd
  !byte $03, $83, $43, $c3, $23, $a3, $63, $e3
  !byte $13, $93, $53, $d3, $33, $b3, $73, $f3
  !byte $0b, $8b, $4b, $cb, $2b, $ab, $6b, $eb
  !byte $1b, $9b, $5b, $db, $3b, $bb, $7b, $fb
  !byte $07, $87, $47, $c7, $27, $a7, $67, $e7
  !byte $17, $97, $57, $d7, $37, $b7, $77, $f7
  !byte $0f, $8f, $4f, $cf, $2f, $af, $6f, $ef
  !byte $1f, $9f, $5f, $df, $3f, $bf, $7f, $ff


* = $c100
main:

;When we get here, there's a sprite mat with the karate girl going, and a ghostbytescroller in the lower border.
;We need to play nice with the ghostbytescroller to make sure that it's not interrupted.

  jmp skip_irq_transition_code

;This is at $c103, where the lazy part can find it:
  jmp fine_tune

;We come here with a jsr from directly after the ghostbytescroller irq_8 in noisefader.
;Our only task is to setup new irq vectors that will continue the ghostbytescrolling and music.

setup_stuff_in_noisefader:
;Grab where we are (we get "sent" the scrolltext position in a and x from noisefader irq routine that jsr in here)
  sty desired_ghostd016+1
  tya
  anc #$f
  ;clc
  adc #$10
  sta ghost_d002+1
  ;clc
  adc #$30
  sta ghost_d004+1
  ;clc
  adc #$30
  sta ghost_d006+1
  ;clc
  adc #$30
  sta ghost_d008+1
  ;clc
  adc #$30
  sta ghost_d00a+1
  ;clc
  adc #$30
  sta ghost_d00c+1
  clc
  adc #$30
  sta ghost_d00e+1
  lda #$c0
  sta ghost_d010+1

;Copy sprite pointers from noisefader $4400 ghostscreen into textrotator's ghostscreen $4000
  lda $47f8
  sta $43f8
  lda $47f9
  sta $43f9
  lda $47fa
  sta $43fa
  lda $47fb
  sta $43fb
  lda $47fc
  sta $43fc
  lda $47fd
  sta $43fd
  lda $47fe
  sta $43fe
  lda $47ff
  sta $43ff

  lda noisefader_values_to_transfer+2 ;$f1c2 transfer_lsb_srcpoi
  sta ghost_lsb_srcpoi2+1
  sta ghost_lsb_srcpoi+1
  lda noisefader_values_to_transfer+3 ;$f1c3 transfer_lsb_srcpoi+1
  sta ghost_lsb_srcpoi2+2
  sta ghost_lsb_srcpoi+2
  lda noisefader_values_to_transfer+4 ;$f1c4 transfer_msb_srcpoi
  sta ghost_msb_srcpoi2+1
  sta ghost_msb_srcpoi+1
  lda noisefader_values_to_transfer+5 ;$f1c5 transfer_msb_dstpoi+1
  sta ghost_msb_srcpoi2+2
  sta ghost_msb_srcpoi+2
  lda noisefader_values_to_transfer+6 ;$f1c6
  sta sprite_sprite_offset+1
  lda noisefader_values_to_transfer+7 ;$f1c7
  sta sprite_set+1
  lda noisefader_values_to_transfer+8 ;$f1c8
  sta plot_next_char+1
  lda noisefader_values_to_transfer+9 ;$f1c9
  sta nof_nybbles_left+1

  lda $d011
  and #$7f
  sta $d011
  lda #$0
  sta $d012
  lda #<irq_loading
  sta $fffe
  lda #>irq_loading
  sta $ffff
;  lda #$00    ;screen at $4000, charset at $4000
;  sta $d018
  rts


ghostcols:
;  !byte 7,$f,$c,$a,$f,$c,$8,$c,$a,$f,$7,1,$d,$3,$5,$c,$4,$a,$e,$5,3

; Desert-färger:
;  !byte $1,$7,$c,$a,$8,$9,$8,$9,$3,$5,$e,$3,$e,$6,$b,$6,$b,$4,$e,$3,$e

; Redcrabs colours:
  !byte $8,$a,$7,$a,$8,$8,$b,$9,$9,$3,$3,$6,$6,$c,$6,$4,$6,$6,$6,$3,$3
;1  cyan (eller ljusgrå för buggens skull om det hjälper)
;2  cyan
;3  mörkblå
;4  mörkblå
;5  mörkblå
;6  magenta
;7  blå
;8  magenta
;9  blå
;10 blå
;11 cyan
;12 cyan
;13 mörkbrun
;14 mörkbrun
;15 mörkgrå
;16 ljusbrun (aka orange)
;17 ljusbrun
;18 ljusröd
;19 gul
;20 ljusröd
;21 ljusbrun


ghostlist:
;  !byte %11100000
;  !byte %00111000
;  !byte %01111100
;  !byte %01111110
;  !byte %01111110
;  !byte %00111000
;  !byte %00001111
;  !byte %01101111
;  !byte %01111110
;  !byte %01111110
;  !byte %01111100
;  !byte %01110000
;  !byte %01111100
;  !byte %01111110
;  !byte %01111111
;  !byte %01111000
;  !byte %01111110
;  !byte %01111110
;  !byte %01111100
;  !byte %00111000
;  !byte %00000011

; Inverted:
;  !byte %00011111
;  !byte %11000111
;  !byte %10000011
;  !byte %10000001
;  !byte %10000001
;  !byte %11000111
;  !byte %11110000
;  !byte %10010000
;  !byte %10000001
;  !byte %10000001
;  !byte %10000011
;  !byte %10001111
;  !byte %10000011
;  !byte %10000001
;  !byte %10000000
;  !byte %10000111
;  !byte %10000001
;  !byte %10000001
;  !byte %10000011
;  !byte %11000111
;  !byte %11111100

;and upside down:
  !byte %11111100
  !byte %11000111
  !byte %10000011
  !byte %10000001
  !byte %10000001
  !byte %10000111
  !byte %10000000
  !byte %10000001
  !byte %10000011
  !byte %10001111
  !byte %10000011
  !byte %10000001
  !byte %10000001
  !byte %10010000
  !byte %11110000
  !byte %11000111
  !byte %10000001
  !byte %10000001
  !byte %10000011
  !byte %11000111
  !byte %00011111


; This demopart is here so we are allowed to write into the code.
; Else, depacking would be destroyed if we write to code area while loading and decrunching.
the_demo_ghostloop:
ghost_d002:
  lda #$81
  sta $d002
ghost_d004:
  lda #$82
  sta $d004
ghost_d006:
  lda #$83
  sta $d006
ghost_d008:
  lda #$84
  sta $d008
ghost_d00a:
  lda #$85
  sta $d00a
ghost_d00c:
  lda #$86
  sta $d00c
ghost_d00e:
  lda #$87
  sta $d00e
ghost_d010:
  lda #$c0
  sta $d010

  ldx #20
ghostloop:
  lda ghostcols,x
  ldy ghostlist,x
  sta $d025
  sty ghostbyte
  sta $d021
  bit $00
  ; Now, copy one char (or, rather, write one byte into one of the three sets).
  ; This byte is off screen and will be scrolled into the screen "soon".
ghost_msb_srcpoi:
  ;lda char_46_nybble_0_msb,x   ;4
;HARDCODED values since we don't have access to noisefader's labels:
  lda $ee15,x
ghost_lsb_srcpoi:
  ;ora char_46_nybble_0,x       ;4
;HARDCODED values since we don't have access to noisefader's labels:
  ora $ee00,x       ;4
  ldy table_of_x3,x            ;4
  sta (ghost_destpoi),y        ;6
  dex
  bpl ghostloop
  rts



irq_loading:
  pha
  txa
  pha
  tya
  pha
  asl $d019
  lda $d011
  ora #$18
  sta $d011
  lda #$10   ;screen at $4400, charset at $4000
  sta $d018
  lda #0
  sta $d020
  sta $d021
!ifdef release {
  jsr link_music_play
} else {
  jsr music+3
}
  inc irq_loading_is_running+1
  lda #$32
  sta $d012
  lda #<irq_ghost_2
  sta $fffe
  lda #>irq_ghost_2
  sta $ffff
  pla
  tay
  pla
  tax
  pla
  rti


; The stand-alone IRQ that will run the ghostscroller during transitions:
irq_ghost_0:
  sta save_aghost_0+1
  lda $d011
  and #7
  ora #$d0   ;used to be $90
  sta $d011
  lda #$00
  sta $d012
  lda #<irq_ghost_1
  sta $fffe
  lda #>irq_ghost_1
  sta $ffff
  asl $d019
;setup sprites
  lda #ghostsprite_ypos
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f
  lda #$fe
  sta $d015
  sta $d01c  ;All ghostsprites multicol
  sta $d01d
  lda #$1
  sta $d028
  sta $d029
  sta $d02a
  sta $d02b
  sta $d02c
  sta $d02d
  sta $d02e
  lda #$0
  sta $d01b
  lda ghost_d002+1
  sta $d002
  lda ghost_d004+1
  sta $d004
  lda ghost_d006+1
  sta $d006
  lda ghost_d008+1
  sta $d008
  lda ghost_d00a+1
  sta $d00a
  lda ghost_d00c+1
  sta $d00c

save_aghost_0:
  lda #0
  rti

;used to be $fa:
ghostsprite_ypos = $01

irq_ghost_1:
  pha
; stable irq through timer dc04:
!ifndef DISABLE_STABLE {
  lda $dc04
  eor #7
  and #7
  sta *+4
  bpl *+2
  lda #$a9
  lda #$a9
  lda $eaa5
}
  stx save_xghost_1+1
  sty save_yghost_1+1

  ;We will need to wait here until they are finished a couple of lines further down.
  nop
  nop
  nop
  nop
  nop
  bit $ea

  lda desired_ghostd016+1
  and #7
  ora #$c0
  sta $d016
  lda $d011
  and #7
  ora #$18
  sta $d011

  lda #$00    ;screen at $4000, charset at $4000
  sta $d018
;  lda #0
  sta $d026
  lda ghost_d010+1
  sta $d010
  lda ghost_d00e+1
  sta $d00e

  ldx #20
ghostloop2:
  lda ghostcols,x
  ldy ghostlist,x
  sta $d025
  sty $7fff
  sta $d021
  bit $00
  ; Now, copy one char (or, rather, write one byte into one of the three sets).
  ; This byte is off screen and will be scrolled into the screen "soon".
ghost_msb_srcpoi2:
  ;lda char_46_nybble_0_msb,x   ;4
;HARDCODED values since we don't have access to noisefader's labels:
  lda $ee15,x
ghost_lsb_srcpoi2:
  ;ora char_46_nybble_0,x       ;4
;HARDCODED values since we don't have access to noisefader's labels:
  ora $ee00,x       ;4
  ldy table_of_x3,x            ;4
  sta (ghost_destpoi),y        ;6
  dex
  bpl ghostloop2

  nop
  nop
  lda #0
  nop
  nop
  sta $d021
  lda #$ff
  sta $7fff
  sta $d01b

  ; Make sure that sprites aren't doubled at the top of the screen:
  lda #0
  sta $d015

  ; x-expanded everywhere:
  lda #$ff
  sta $d01d

  jsr do_ghostscroller

  lda ghost_lsb_srcpoi+1
  sta ghost_lsb_srcpoi2+1
  lda ghost_lsb_srcpoi+2
  sta ghost_lsb_srcpoi2+2
  lda ghost_msb_srcpoi+1
  sta ghost_msb_srcpoi2+1
  lda ghost_msb_srcpoi+2
  sta ghost_msb_srcpoi2+2

  lda #$10   ;screen at $4400, charset at $4000
  sta $d018
  lda #$5b   ;Extended Colour Mode
  sta $d011

!ifdef release {
  jsr link_music_play
} else {
  jsr music+3
}

  lda #$32
  sta $d012
  lda #<irq_ghost_2
  sta $fffe
  lda #>irq_ghost_2
  sta $ffff
  asl $d019


enable_loading_rotation:
  lda #0
  bne yes_rotation
  jmp no_rotation
yes_rotation:

desired_d018:
  lda #$10    ;screen at $4400, charset at $4000
;  lda #$12   ;screen at $4400, charset at $4800
  sta $d018
  eor #2
  sta desired_d018+1
  cli

;Toggle $d016 to scroll $d800 4 pixels per frame to the left, and screen0-ECM-colours 4 pixels per frame to the right
;scroll rotating text 4 pixels per frame to the left:
coloffset_x_d016:
  lda #1
  eor #4
  sta coloffset_x_d016+1
  and #$7
  ora #$c0
  sta desired_d016+1

  anc #$4
  bne move_d800
;move_screen0:
  lda coloffset_x+1
  ;clc
  adc #1
  and #7
  sta coloffset_x+1
;ECM values are #$10-$1f to begin with
  ldy #$c0
ecm_where:
  ldx #$58
  jsr fill_ecm_diag
  inc ecm_where+1

;ECM values are #$c0 here
  ldy #$40
ecm_where2:
  ldx #$58 - 16*1
  jsr fill_ecm_diag
  inc ecm_where2+1

;ECM values are #$80 here
  ldy #$c0
ecm_where3:
  ldx #$58 - 16*2
  jsr fill_ecm_diag
  inc ecm_where3+1
  lda ecm_where3+1
  cmp #$98
  bne colours_are_not_done_yet
  lda #1
  sta colours_are_done+1
colours_are_not_done_yet:
  jmp done_moving_ECM_or_D800


move_d800:
;Fill the screen with colours:
  ldy #$1
col_where0:
  ldx #$a7
  jsr fill_col_diag
  dec col_where0+1

  ldy #$7
col_where1:
  ldx #$a7 + 5*1
  jsr fill_col_diag
  dec col_where1+1

  ldy #$3
col_where2:
  ldx #$a7 + 5*2
  jsr fill_col_diag
  dec col_where2+1

  ldy #$5
col_where3:
  ldx #$a7 + 5*3
  jsr fill_col_diag
  dec col_where3+1

  ldy #$e
col_where4:
  ldx #$a7 + 5*4
  jsr fill_col_diag
  dec col_where4+1

  ldy #$8
col_where5:
  ldx #$a7 + 5*5
  jsr fill_col_diag
  dec col_where5+1

  ldy #$b
col_where6:
  ldx #$a7 + 5*6
  jsr fill_col_diag
  dec col_where6+1

;late VIC-II luma
;0
;6, 9
;2, B
;4, 8
;C, E
;5, A
;3, F
;7, D
;1

done_moving_ECM_or_D800:

  ldy #>charset
  lda desired_d018+1
  and #$2
  beq draw25
  ldy #>charset1
draw25:
  sty blit_dst+2
  sty blit_dst2+2
  sty blit_dst_A+2
  sty low_blit_dst_A+2

  jsr fine_tune



no_rotation:
save_yghost_1:
  ldy #0
save_xghost_1:
  ldx #0
  pla
  rti


;ECM mode EOR in Y: $c0,$80,$40,$00
;Position in X
;  $80 is in the right of the screen, all colours are written.
;  $71 is in the left of the screen, all colours are written.
;  $70 is one step to the left, one 
fill_ecm_diag:
  cpx #$71
  bcs no_clip_left_edge2
  jmp clip_left_edge2
no_clip_left_edge2:
  cpx #$80
  bcc no_clip_right_edge2
  jmp clip_right_edge2
no_clip_right_edge2:

;All visible:
  txa
  anc #$1f
  ;clc
  adc #14
  tax
  jmp all_visible

too_much_clip:
  txa
  sec
  sbc #$13
  tax
  lda mul_by_7_table,x
  sta skip_length66+1
  txa
  and #$1f
  eor #$1f
  tax
skip_length66:
  bne skip_something66
skip_something66:
  tya
  eor screen0 - $1f + 0 + 40*5,x
  sta screen0 - $1f + 0 + 40*5,x
  tya
  eor screen0 - $1f + 1 + 40*4,x
  sta screen0 - $1f + 1 + 40*4,x
  tya
  eor screen0 - $1f + 2 + 40*3,x
  sta screen0 - $1f + 2 + 40*3,x
  tya
  eor screen0 - $1f + 3 + 40*2,x
  sta screen0 - $1f + 3 + 40*2,x
  tya
  eor screen0 - $1f + 4 + 40*1,x
  sta screen0 - $1f + 4 + 40*1,x
  tya
  eor screen0 - $1f + 5 + 40*0,x
  sta screen0 - $1f + 5 + 40*0,x
too_much_left:
  rts

clip_left_edge2:
  cpx #$59
  bcc too_much_left
;$71 means clip the lowest row
;$70 means clip 2 rows
  txa
  eor #$7f
  tax
  sbx #$e
  ;sec
  ;sbc #$e
  ;tax
  lda mul_by_7_table,x
  bmi too_much_clip
  sta branch_it+1
  txa
  and #$1f
  eor #$1f
  tax
branch_it:
  bne no_branch
no_branch:
all_visible:
  tya
  eor screen0 - $1f + 14 + 40*24 - 14,x
  sta screen0 - $1f + 14 + 40*24 - 14,x
  tya
  eor screen0 - $1f + 15 + 40*23 - 14,x
  sta screen0 - $1f + 15 + 40*23 - 14,x
  tya
  eor screen0 - $1f + 16 + 40*22 - 14,x
  sta screen0 - $1f + 16 + 40*22 - 14,x
  tya
  eor screen0 - $1f + 17 + 40*21 - 14,x
  sta screen0 - $1f + 17 + 40*21 - 14,x
  tya
  eor screen0 - $1f + 18 + 40*20 - 14,x
  sta screen0 - $1f + 18 + 40*20 - 14,x
  tya
  eor screen0 - $1f + 19 + 40*19 - 14,x
  sta screen0 - $1f + 19 + 40*19 - 14,x
  tya
  eor screen0 - $1f + 20 + 40*18 - 14,x
  sta screen0 - $1f + 20 + 40*18 - 14,x
  tya
  eor screen0 - $1f + 21 + 40*17 - 14,x
  sta screen0 - $1f + 21 + 40*17 - 14,x
  tya
  eor screen0 - $1f + 22 + 40*16 - 14,x
  sta screen0 - $1f + 22 + 40*16 - 14,x
  tya
  eor screen0 - $1f + 23 + 40*15 - 14,x
  sta screen0 - $1f + 23 + 40*15 - 14,x
  tya
  eor screen0 - $1f + 24 + 40*14 - 14,x
  sta screen0 - $1f + 24 + 40*14 - 14,x
  tya
  eor screen0 - $1f + 25 + 40*13 - 14,x
  sta screen0 - $1f + 25 + 40*13 - 14,x
  tya
  eor screen0 - $1f + 26 + 40*12 - 14,x
  sta screen0 - $1f + 26 + 40*12 - 14,x
  tya
  eor screen0 - $1f + 27 + 40*11 - 14,x
  sta screen0 - $1f + 27 + 40*11 - 14,x
  tya
  eor screen0 - $1f + 28 + 40*10 - 14,x
  sta screen0 - $1f + 28 + 40*10 - 14,x
  tya
  eor screen0 - $1f + 29 + 40*9 - 14,x
  sta screen0 - $1f + 29 + 40*9 - 14,x
  tya
  eor screen0 - $1f + 30 + 40*8 - 14,x
  sta screen0 - $1f + 30 + 40*8 - 14,x
  tya
  eor screen0 - $1f + 31 + 40*7 - 14,x
  sta screen0 - $1f + 31 + 40*7 - 14,x
  tya
  eor screen0 - $1f + 32 + 40*6 - 14,x
  sta screen0 - $1f + 32 + 40*6 - 14,x
  tya
  eor screen0 - $1f + 33 + 40*5 - 14,x
  sta screen0 - $1f + 33 + 40*5 - 14,x
  tya
  eor screen0 - $1f + 34 + 40*4 - 14,x
  sta screen0 - $1f + 34 + 40*4 - 14,x
  tya
  eor screen0 - $1f + 35 + 40*3 - 14,x
  sta screen0 - $1f + 35 + 40*3 - 14,x
  tya
  eor screen0 - $1f + 36 + 40*2 - 14,x
  sta screen0 - $1f + 36 + 40*2 - 14,x
  tya
  eor screen0 - $1f + 37 + 40*1 - 14,x
  sta screen0 - $1f + 37 + 40*1 - 14,x
  tya
  eor screen0 - $1f + 38 + 40*0 - 14,x
  sta screen0 - $1f + 38 + 40*0 - 14,x
  rts


overflow_error:
  lda #$7f
  sbx #19
  ;txa
  ;anc #$7f
  ;clc
  ;sbc #18
  ;tax
  lda mul_by_7_table,x
  sta skip_length6+1
skip_length6:
  bne skip_something6
skip_something6:
  tya
  eor screen0 + 20 + 40*19 + 19,x
  sta screen0 + 20 + 40*19 + 19,x
  tya
  eor screen0 + 19 + 40*20 + 19,x
  sta screen0 + 19 + 40*20 + 19,x
  tya
  eor screen0 + 18 + 40*21 + 19,x
  sta screen0 + 18 + 40*21 + 19,x
  tya
  eor screen0 + 17 + 40*22 + 19,x
  sta screen0 + 17 + 40*22 + 19,x
  tya
  eor screen0 + 16 + 40*23 + 19,x
  sta screen0 + 16 + 40*23 + 19,x
  tya
  eor screen0 + 15 + 40*24 + 19,x
  sta screen0 + 15 + 40*24 + 19,x
nothing_to_draw4:
  rts


clip_right_edge2:
;$80 means all visible
;$81 is clip 1 on the right edge
  cpx #$98
  bcs nothing_to_draw4
  lda #$7f
  sbx #$00
  ;txa
  ;and #$7f
  ;tax
  lda mul_by_7_table,x
  bmi overflow_error
  sta skip_length+1
skip_length:
  bne skip_something
skip_something:
  tya
  eor screen0 + 39 + 40*0,x
  sta screen0 + 39 + 40*0,x
  tya
  eor screen0 + 38 + 40*1,x
  sta screen0 + 38 + 40*1,x
  tya
  eor screen0 + 37 + 40*2,x
  sta screen0 + 37 + 40*2,x
  tya
  eor screen0 + 36 + 40*3,x
  sta screen0 + 36 + 40*3,x
  tya
  eor screen0 + 35 + 40*4,x
  sta screen0 + 35 + 40*4,x
  tya
  eor screen0 + 34 + 40*5,x
  sta screen0 + 34 + 40*5,x
  tya
  eor screen0 + 33 + 40*6,x
  sta screen0 + 33 + 40*6,x
  tya
  eor screen0 + 32 + 40*7,x
  sta screen0 + 32 + 40*7,x
  tya
  eor screen0 + 31 + 40*8,x
  sta screen0 + 31 + 40*8,x
  tya
  eor screen0 + 30 + 40*9,x
  sta screen0 + 30 + 40*9,x
  tya
  eor screen0 + 29 + 40*10,x
  sta screen0 + 29 + 40*10,x
  tya
  eor screen0 + 28 + 40*11,x
  sta screen0 + 28 + 40*11,x
  tya
  eor screen0 + 27 + 40*12,x
  sta screen0 + 27 + 40*12,x
  tya
  eor screen0 + 26 + 40*13,x
  sta screen0 + 26 + 40*13,x
  tya
  eor screen0 + 25 + 40*14,x
  sta screen0 + 25 + 40*14,x
  tya
  eor screen0 + 24 + 40*15,x
  sta screen0 + 24 + 40*15,x
  tya
  eor screen0 + 23 + 40*16,x
  sta screen0 + 23 + 40*16,x
  tya
  eor screen0 + 22 + 40*17,x
  sta screen0 + 22 + 40*17,x
  tya
  eor screen0 + 21 + 40*18,x
  sta screen0 + 21 + 40*18,x
  tya
  eor screen0 + 20 + 40*19,x
  sta screen0 + 20 + 40*19,x
  tya
  eor screen0 + 19 + 40*20,x
  sta screen0 + 19 + 40*20,x
  tya
  eor screen0 + 18 + 40*21,x
  sta screen0 + 18 + 40*21,x
  tya
  eor screen0 + 17 + 40*22,x
  sta screen0 + 17 + 40*22,x
  tya
  eor screen0 + 16 + 40*23,x
  sta screen0 + 16 + 40*23,x
  tya
  eor screen0 + 15 + 40*24,x
  sta screen0 + 15 + 40*24,x
  rts





;Colour in Y
;Position in X
;  $80 is in the left of the screen, all colours are written.
;  $95 is in the right of the screen, all colours are written.
;  $7f is one step to the left, one 
fill_col_diag:
  cpx #$80
  bcs no_clip_left_edge
  jmp clip_left_edge
no_clip_left_edge
  cpx #$8f
  bcs clip_right_edge
;All visible:
  lda #$7f
  sbx #$00
  ;txa
  ;and #$7f
  ;tax
  tya
  sta $d800 + 0 + 40*0,x
  sta $d800 + 1 + 40*1,x
  sta $d800 + 2 + 40*2,x
  sta $d800 + 3 + 40*3,x
  sta $d800 + 4 + 40*4,x
  sta $d800 + 5 + 40*5,x
  sta $d800 + 6 + 40*6,x
  sta $d800 + 7 + 40*7,x
  sta $d800 + 8 + 40*8,x
  sta $d800 + 9 + 40*9,x
  sta $d800 + 10 + 40*10,x
  sta $d800 + 11 + 40*11,x
  sta $d800 + 12 + 40*12,x
  sta $d800 + 13 + 40*13,x
  sta $d800 + 14 + 40*14,x
  sta $d800 + 15 + 40*15,x
  sta $d800 + 16 + 40*16,x
  sta $d800 + 17 + 40*17,x
  sta $d800 + 18 + 40*18,x
  sta $d800 + 19 + 40*19,x
  sta $d800 + 20 + 40*20,x
  sta $d800 + 21 + 40*21,x
  sta $d800 + 22 + 40*22,x
  sta $d800 + 23 + 40*23,x
  sta $d800 + 24 + 40*24,x
nothing_to_draw:
  rts

clip_right_edge:
  ;When x is $90, skip plotting the lowest row
  cpx #$a7
  bcs nothing_to_draw
  txa
  sbx #$8f
  ;sec
  ;sbc #$8f
  ;tax
  lda mul_by_3_table,x
  sta skip_branch+1
  tya
skip_branch:
  bne skip_a_little
skip_a_little:
  sta $d80f + 24 + 40*24,x
  sta $d80f + 23 + 40*23,x
  sta $d80f + 22 + 40*22,x
  sta $d80f + 21 + 40*21,x
  sta $d80f + 20 + 40*20,x
  sta $d80f + 19 + 40*19,x
  sta $d80f + 18 + 40*18,x
  sta $d80f + 17 + 40*17,x
  sta $d80f + 16 + 40*16,x
  sta $d80f + 15 + 40*15,x
  sta $d80f + 14 + 40*14,x
  sta $d80f + 13 + 40*13,x
  sta $d80f + 12 + 40*12,x
  sta $d80f + 11 + 40*11,x
  sta $d80f + 10 + 40*10,x
  sta $d80f + 9 + 40*9,x
  sta $d80f + 8 + 40*8,x
  sta $d80f + 7 + 40*7,x
  sta $d80f + 6 + 40*6,x
  sta $d80f + 5 + 40*5,x
  sta $d80f + 4 + 40*4,x
  sta $d80f + 3 + 40*3,x
  sta $d80f + 2 + 40*2,x
  sta $d80f + 1 + 40*1,x
  sta $d80f + 0 + 40*0,x
  rts

clip_left_edge:
  cpx #$68
  bcc nothing_to_draw
  txa
  eor #$7f
  tax
  lda mul_by_3_table,x
  sta skip_branch2+1
  txa
  eor #$1f
  tax
  tya
skip_branch2:
  bne skip_a_little2
skip_a_little2:
  sta $d7e0 + 0 + 40*0,x
  sta $d7e0 + 1 + 40*1,x
  sta $d7e0 + 2 + 40*2,x
  sta $d7e0 + 3 + 40*3,x
  sta $d7e0 + 4 + 40*4,x
  sta $d7e0 + 5 + 40*5,x
  sta $d7e0 + 6 + 40*6,x
  sta $d7e0 + 7 + 40*7,x
  sta $d7e0 + 8 + 40*8,x
  sta $d7e0 + 9 + 40*9,x
  sta $d7e0 + 10 + 40*10,x
  sta $d7e0 + 11 + 40*11,x
  sta $d7e0 + 12 + 40*12,x
  sta $d7e0 + 13 + 40*13,x
  sta $d7e0 + 14 + 40*14,x
  sta $d7e0 + 15 + 40*15,x
  sta $d7e0 + 16 + 40*16,x
  sta $d7e0 + 17 + 40*17,x
  sta $d7e0 + 18 + 40*18,x
  sta $d7e0 + 19 + 40*19,x
  sta $d7e0 + 20 + 40*20,x
  sta $d7e0 + 21 + 40*21,x
  sta $d7e0 + 22 + 40*22,x
  sta $d7e0 + 23 + 40*23,x
  sta $d7e0 + 24 + 40*24,x
  rts

mul_by_3_table:
  !byte 0*3
  !byte 1*3
  !byte 2*3
  !byte 3*3
  !byte 4*3
  !byte 5*3
  !byte 6*3
  !byte 7*3
  !byte 8*3
  !byte 9*3
  !byte 10*3
  !byte 11*3
  !byte 12*3
  !byte 13*3
  !byte 14*3
  !byte 15*3
  !byte 16*3
  !byte 17*3
  !byte 18*3
  !byte 19*3
  !byte 20*3
  !byte 21*3
  !byte 22*3
  !byte 23*3
  !byte 24*3
  !byte 25*3

mul_by_7_table:
  !byte 0*7
  !byte 1*7
  !byte 2*7
  !byte 3*7
  !byte 4*7
  !byte 5*7
  !byte 6*7
  !byte 7*7
  !byte 8*7
  !byte 9*7
  !byte 10*7
  !byte 11*7
  !byte 12*7
  !byte 13*7
  !byte 14*7
  !byte 15*7
  !byte 16*7
  !byte 17*7
  !byte 18*7
  !byte 19*7
  !byte 20*7
  !byte 21*7
  !byte 22*7
  !byte 23*7
  !byte 24*7
  !byte 25*7

irq_ghost_2:
  sta save_aghost2+1
  stx save_xghost2+1
  lda #<irq_ghost_0
  sta $fffe
  lda #>irq_ghost_0
  sta $ffff
desired_d016:
  lda #$a0
  sta $d016
  lda #$0
  sta $d021

  lda #$f9
  sta $d012
switch_to_demo_now:
  lda #0
  beq dont_switch_to_demo_now

  lda #$fa
  sta $d012
  lda #<irq_0
  sta $fffe
  lda #>irq_0
  sta $ffff
;Here, place 8 sprites on the lowest row, to maintain the timing in irq_0.
  lda #$ff
  sta $d015
  lda #$ff
  sta $d010
  lda #$80
  sta $d000
  sta $d002
  sta $d004
  sta $d006
  sta $d008
  sta $d00a
  sta $d00c
  sta $d00e
  lda #$ff
  sta $d017
;sprypos4:
  lda sprypos4+1
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f

dont_switch_to_demo_now:
  asl $d019
save_aghost2:
  lda #0
save_xghost2:
  ldx #0
  rti


; UGLY constants that depend on the assembly of the ghostbytescroller in the noisefader part:
fontdata_width_in_nybbles = $f100
fontdata_lsb = $f140
fontdata_msb = $f180
noisefader_values_to_transfer = $f1c0

do_ghostscroller:
desired_ghostd016:
  lda #$0
  sec
ghost_speed:
  sbc #3
  bcs no_change_set
  ldy #3
  sty plot_next_char+1
sprite_set:
  ldx #0
  inx
  cpx #3
  bne no_wrap_set
  ldx #0
sprite_sprite_offset:
  ldy #0
  iny
  cpy #8
  bne no_wrap_sprite_sprite_offset
  ldy #0
no_wrap_sprite_sprite_offset:
  sty sprite_sprite_offset+1
no_wrap_set:
  stx sprite_set+1
no_change_set:
  and #$f
  sta desired_ghostd016+1

;  lda desired_ghostd016+1
  anc #$f
  ;clc
  adc #$10
  sta ghost_d002+1
  ;clc
  adc #$30
  sta ghost_d004+1
  ;clc
  adc #$30
  sta ghost_d006+1
  ;clc
  adc #$30
  sta ghost_d008+1
  ;clc
  adc #$30
  sta ghost_d00a+1
  ;clc
  adc #$30
  sta ghost_d00c+1
  clc
  adc #$30
  sta ghost_d00e+1
;  lda #$c0
;  sta ghost_d010+1


plot_next_char:
  ldx #0
  dex
  bpl yes_plot_a_char
  jmp no_need_to_plot_a_char
yes_plot_a_char:
  stx plot_next_char+1

  cpx #2
  beq get_next_text_char
  jmp no_need_to_get_next_text_char
get_next_text_char:
nof_nybbles_left:
  ldx #1
  dex
  beq get_a_new_char
just_get_the_next_nybble:
  lda ghost_lsb_srcpoi+1
  clc
  adc #63
  sta ghost_msb_srcpoi+1
  lda ghost_lsb_srcpoi+2
  adc #0
  sta ghost_msb_srcpoi+2
;this is a jmp:
  bne find_nybble_lsb
get_a_new_char:
  ldy #0
  lda (ghost_textpoi),y
  tay
  bne no_wrap_scrolltext
;  lda #>scrolltext
;GRAB directly from noisefader memory:
  lda noisefader_values_to_transfer+1
  sta ghost_textpoi+1
;  lda #<scrolltext
;GRAB directly from noisefader memory:
  lda noisefader_values_to_transfer
  sta ghost_textpoi
  ldy #$20
no_wrap_scrolltext:
  inc ghost_textpoi
  bne no_inc2
  inc ghost_textpoi+1
no_inc2:
  lda fontdata_lsb,y
  clc
  adc #21   ; to get the "msb" version of this nybble
  sta ghost_msb_srcpoi+1
  lda fontdata_msb,y
  adc #0
  sta ghost_msb_srcpoi+2
  lda fontdata_width_in_nybbles,y
  tax

find_nybble_lsb:
  dex
  beq get_a_new_char2
just_get_the_next_nybble2:
  lda ghost_msb_srcpoi+1
  clc
  adc #21
  sta ghost_lsb_srcpoi+1
  lda ghost_msb_srcpoi+2
  adc #0
  sta ghost_lsb_srcpoi+2
;this is a jmp:
  bne done_finding_nybbles
get_a_new_char2:
  ldy #0
  lda (ghost_textpoi),y
  tay
  bne no_wrap_scrolltext2
;  lda #>scrolltext
;GRAB directly from noisefader memory:
  lda noisefader_values_to_transfer+1
  sta ghost_textpoi+1
;  lda #<scrolltext
;GRAB directly from noisefader memory:
  lda noisefader_values_to_transfer
  sta ghost_textpoi
  ldy #$20
no_wrap_scrolltext2:
  inc ghost_textpoi
  bne no_inc3
  inc ghost_textpoi+1
no_inc3:
  lda fontdata_lsb,y
  sta ghost_lsb_srcpoi+1
  lda fontdata_msb,y
  sta ghost_lsb_srcpoi+2
  lda fontdata_width_in_nybbles,y
  tax

done_finding_nybbles:
  stx nof_nybbles_left+1

no_need_to_get_next_text_char:

  ; Now, update where we're going to grab data from the font and store for the next time we run the ghostloop above.
;ghost_msb_srcpoi:
;  lda char_20_nybble_0_msb,x   ;4
;ghost_lsb_srcpoi:
;  ora char_20_nybble_1,x       ;4
;  ldy table_of_x3,x            ;4
;  sta (ghost_destpoi),y        ;6


; We need 21 sprites. 7 sprites, and then the scroller shifted one byte to the left, and shifted two bytes to the left.
; = 1344 bytes = $1c0 * 3 = $540 bytes.
; So set#0, sprites 0-7 contain:
;  ABC EFG HJK LNO PQR STU VXY Z3x
; set#1, sprites 8-15 contain:
;  BCE FGH JKL NOP QRS TUV XYZ 3xx
; set#2, sprites 16-23 contain:
;  CEF GHJ KLN OPQ RST UVX YZ3 xxx

; show set#0, 336 pixels wide. 304 of these are visible = 32 are outside of the screen.
; print the next two nybbles "Y" into set #0
; print the next two nybbles "Y" into set #1
; print the next two nybbles "Y" into set #2
; show set#1, 336 pixels wide. 304 of these are visible = 32 are outside of the screen.
; print the next two nybbles "Z" into set #0 (at the position of "A")
; print the next two nybbles "Z" into set #1
; print the next two nybbles "Z" into set #2
; show set#2, 336 pixels wide. 304 of these are visible = 32 are outside of the screen.
; print the next two nybbles "3" into set #0 (at the position of "B")
; print the next two nybbles "3" into set #1 (at the position of "B")
; print the next two nybbles "3" into set #2
; show set#0, but with sprite #1 "EFG" as the leftmost sprite.

; Determine which set we will plot into:
  ldx plot_next_char+1
  lda set_pointers_msb_table,x
  sta which_set_to_plot_into+1
  stx set_offset+1

; use sprite_sprite_offset * 3 + sprite_set + a_constant   and then wrap that modulo 24 to figure out
  ldx sprite_sprite_offset+1
  lda table_of_x3,x
  clc
  adc sprite_set+1
  clc
  adc #20
  sec
set_offset:
  sbc #0
  cmp #24
  bcc is_small_already
  ;sec
  sbc #24
is_small_already:
  ; Now a is "the column that we shall write into"
  ; Let's translate that into a sprite pointer.
  tax
  lda sprite_lsb_table,x
  sta ghost_destpoi
  lda sprite_msb_table,x
  clc
which_set_to_plot_into:
  adc #>ghostsprites
  sta ghost_destpoi+1


; The first sprite is (ghostsprites - $4000)/$40
; Next sprite set is +7
; Then, the sprite_sprite_offset is where we start within the 7 sprites.
; Let's use 8 sprites instead, to make this logic easier.
  lda sprite_set+1
  asl
  asl
  asl
  clc
  adc #(ghostsprites - $4000)/$40
  sta sprite_block+1

  ldx #0
  ldy sprite_sprite_offset+1
next_sprite_pointer:
  tya
  and #$7
sprite_block:
  ora #0
  sta ghostscreen+$3f9,x
  iny
  inx
  cpx #7
  bne next_sprite_pointer

no_need_to_plot_a_char:
  rts

;0
;6, 9
;2, B
;4, 8
;C, E
;5, A
;3, F
;7, D
;1



sprite_lsb_table:
  !byte $00,$01,$02,$40,$41,$42,$80,$81,$82,$c0,$c1,$c2,$00,$01,$02,$40,$41,$42,$80,$81,$82,$c0,$c1,$c2
sprite_msb_table:
  !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01

set_pointers_msb_table:
  !byte >ghostsprites
  !byte >(ghostsprites+$200)
  !byte >(ghostsprites+$400)


table_of_x3:
  !byte 0*3,1*3,2*3,3*3,4*3,5*3,6*3,7*3,8*3,9*3,10*3,11*3,12*3,13*3,14*3,15*3,16*3,17*3,18*3,19*3,20*3,21*3



skip_irq_transition_code:
;  lda #$7
;  sta $d020
;  sta $d021


  lda #$0
  ldx #0
fi0:
  sta $d800,x
  inx
  bne fi0
fi1:
  sta $d900,x
  inx
  bne fi1
fi2:
  sta $da00,x
  inx
  bne fi2
fi3:
  sta $db00,x
  inx
  bne fi3
  lda #0
  sta $d022
  sta $d023
  sta $d024

;We will hijack the IRQ just before the irq_bottom is supposed to run.
;This is done in the noisefader code. The last irq_8 run will do jsr $c103 (above)
;and that's where we switch to textrotator irq code somewhere $c100-$cfff

; In textrotator, the ghostsprites are at
; ghostsprites = $7a00  ; - $7fff
; In noisefader, that's exactly the same memory location.
; So let's keep them there.
; In the noisefader demo, the ghostscreen is at ;$4400 - which more or less only is using the $47f8-$47ff pointers.
; This is where the textrotator screen is located as well.


!ifndef release {
  sei
  cld
  lda #$35
  sta $01
  ldx #$ff
  txs
  lda #0
  sta $d015
}

;Make sure to set ghostbyte of Extended background mode to filled:
  lda #$ff
  sta $79ff

irq_loading_is_running:
  ldy #0
;Let's wait until our first irq has occurred here:
  beq irq_loading_is_running


!ifndef release {
colours_are_done:
  lda #0
}
!ifdef release {

;Clear one char:
  ldx #7
  lda #0
clrchar:
  sta charset,x
  dex
  bpl clrchar
;Clear the screen now:
  ldx #0
clrsc:
  sta screen0,x
  sta screen0+$100,x
  sta screen0+$200,x
  sta screen0+$2e8,x
  inx
  bne clrsc

;Load the Textrotator rotation data at $8000-$c100
  jsr link_load_next_comp
;  lda #6
;  sta $d020

  ;Now we can start rotating text, so let's init the screen:
  jsr init_screen0
  ;$d020 is 0, and $d800 are all 0.
  ;we can gradually "paint" with $d800, while we rotate in the charset
  ;To make update_split: -routine faster, we could "cache" this screen to $0400
  ;We only need the 8 leftmost chars   and #$0f   of the screen, all rows.
  ;We also need the same chars, but    ora #$10   stored.

;init charsets:
  ldx #0
  lda #$ff
fill_charsets:
  sta charset,x
  sta charset+$100,x
  sta charset1,x
  sta charset1+$100,x
  inx
  bne fill_charsets

;  lda #$b
;  ldx #0
;just_simple:
;  sta $d800 + 10*40,x
;  inx
;  bne just_simple

  lda #$c
  sta $d022  ;extended colour #1
  lda #$d
  sta $d023  ;extended colour #2
  lda #$4
  sta $d024  ;extended colour #3

;We shall end up with $b in $d800, and $c in extended colour.

  lda #1
  sta enable_loading_rotation+1


;Load the Lazy part #1 $6d00-$7800, but don't unpack it.
  jsr link_load_next_raw

;Load the Lazy part #2 $3a00-$4000, but don't unpack it.
  jsr link_load_next_raw

;Load the Textrotator code at $2000-$3a00
  jsr link_load_next_comp

;Load the Textrotator torus sprite animations at $4900-$6c00
  jsr link_load_next_comp

;Loading is ready, all systems ok.

;Wait until the $d800 and ECM char colours are all $c and $b:
colours_are_done:
  lda #0
  beq colours_are_done

;Just wait until the rotating x-position is zero, so the d800 scrolltext starts at the right place:
  lda #0
wait_for_coloffset:
  cmp coloffset_x+1
  bne wait_for_coloffset

;the rotating text will go from scrolling 4 pixels at a time to the left, directly to 2 pixels per frame.
;So to "hide" this, let it bounce a little:
  lda #0
  sta blit_yspd_lsb+1
  lda #2
  sta blit_yspd_msb+1
;  lda #$fe
;  sta yspd_maxspeed+1

}

!ifndef release {
  lda #0
  jsr music

init_timers:
  lda #$08
;  sei           ;we don't want lost cycles by IRQ calls :)
wait_sync:
  cmp $d012     ;scan for begin rasterline (A=$11 after first return)
  bne wait_sync ;wait if not reached rasterline #$11 yet
  ldy #8        ;the walue for cia timer fetch & for y-delay loop         2 cycles
  sty $dc04     ;CIA Timer will count from 8,8 down to 7,6,5,4,3,2,1      4 cycles
  dey           ;Y=Y-1 (8 iterations: 7,6,5,4,3,2,1,0)                    2 cycles*8
  bne *-1       ;loop needed to complete the poll-delay with 39 cycles    3 cycles*7+2 cycles*1
  sty $dc05     ;no need Hi-byte for timer at all (or it will mess up)    4 cycles
  sta $dc0e,y   ;forced restart of the timer to value 8 (set in dc04)     5 cycles
  lda #$11      ;value for d012 scan and for timerstart in dc0e           2 cycles
  cmp $d012     ;check if line ended (new line) or not (same line)
  sty $d015     ;switch off sprites, they eat cycles when fetched
  bne wait_sync ;if line changed after 63 cycles, resyncronize it!
                ;this is also a stable-timed point

  lda #$7f
  sta $dc0d  ;disable timer interrupts which can be generated by the two CIA chips
  sta $dd0d  ;the kernal uses such an interrupt to flash the cursor and scan the keyboard, so we better
  ;stop it.
  lda $dc0d  ;by reading this two registers we negate any pending CIA irqs.
  lda $dd0d  ;if we don't do this, a pending CIA irq might occur after we finish setting up our irq.
  ;we don't want that to happen.

wait_sync2:
  bit $d011
  bpl wait_sync2
wait_sync3:
  bit $d011
  bmi wait_sync3
  lda #$01
  sta $d01a
}

syncite5:
  lda $d011
  bpl syncite5
syncite6:
  lda $d011
  bmi syncite6
;  ldx #0
;wheer:
;  lda #$b
;  sta $d800,x
;  sta $d900,x
;  sta $da00,x
;  sta $dae8,x
;  inx
;  bne wheer

 ; lda #2      ;Bank at $4000-$7fff
 ; sta $dd00
 ; lda #$10    ;screen at $4400, charset at $4000
 ; sta $d018
 ; lda #$00   ;Sprites off
 ; sta $d015

;  lda #<ghostsprites
;  sta ghost_destpoi
;  lda #>ghostsprites
;  sta ghost_destpoi+1

;  lda #%11111111
;  ldx #0
;fill_sprites:
;  sta ghostsprites+$000,x
;  sta ghostsprites+$100,x
;  sta ghostsprites+$200,x
;  sta ghostsprites+$300,x
;  sta ghostsprites+$400,x
;  sta ghostsprites+$500,x
;  inx
;  bne fill_sprites


;Init spriteshadow:
  lda #$ff
  ldx #$3f
morewhite:
  lda spriteshadow_orig,x
  sta spriteshadow,x
  dex
  bpl morewhite

spr_ypos_msb = $32
  lda #spr_ypos_msb
  clc
  adc #42
  sta sprypos1+1
  ;clc
  adc #42
  sta sprypos2+1
  ;clc
  adc #42
  sta sprypos3+1
  ;clc
  adc #42
  sta sprypos4+1

  lda #spr_ypos_msb
  ;clc
  adc #39
  sta irqpos1+1
  ;clc
  adc #40
  sta irqpos2+1
  ;clc
  adc #40
  sta irqpos3+1
  ;clc
  adc #40
  sta irqpos4+1

  lda #$ff
  sta $d01d
;  sta $d017
;  sta $d01c
;  lda #$00
;  sta $d01b


;  ldx #0
;anoth_byte:
;  txa
;sprp2:
;  sta sprites,x
;  dex
;  bne anoth_byte
;  lda sprp2+2
;  clc
;  adc #1
;  sta sprp2+2
;  cmp #$64
;  bne anoth_byte


;Make sure that the IRQ gets switched:
  lda #1
  sta switch_to_demo_now+1

;  lda #$7f
;  sta $dc0d  ;disable timer interrupts which can be generated by the two CIA chips
;  sta $dd0d  ;the kernal uses such an interrupt to flash the cursor and scan the keyboard, so we better stop it.
;  lda $dc0d  ;by reading this two registers we negate any pending CIA irqs.
;  lda $dd0d  ;if we don't do this, a pending CIA irq might occur after we finish setting up our irq.
;  ;we don't want that to happen.
;  lda #<irq_0
;  sta $fffe
;  lda #>irq_0
;  sta $ffff
;  lda #$ff
;  sta $d012
;  lda #$1b
;  sta $d011
;  lda #0
;  sta $d020
;  lda #$c
;  sta $d021
;
;  ldx #1
;  stx $d01a     ; enable raster interrupt
;  lda $dc0d     ; acknowledge CIA interrupts
;  lsr $d019     ; and video interrupts
;  cli

!ifndef release {
ever:
  jmp ever
}

hard_exit:
!ifdef release {
;+request_disc 1
  ;simply do a bogus loadraw, this will call ld_pblock until eof is raised, nothing is loaded as block_ready never happens :-)
!ifdef crt {
  +crt_request_disk $251c
} else {
  lda #$f1
  jsr bitfire_loadraw_
}

  sei


syncite57:
  lda $d011
  bpl syncite57
syncite67:
  lda $d011
  bmi syncite67

;OK, time to start the Lazy Jones part.
  lda #$0
  sta $d020
  sta $d021
  lda #0
  sta $d011

  lda #0
  ldx #$17
clrSID:
  sta $d400,x
  dex
  bpl clrSID

  lda #$0f
  sta $d418
  jsr playAudioFx_Toilet
  jsr playAudioFx_Toilet
  jsr playAudioFx_Toilet
  jsr playAudioFx_Toilet

;We need to unpack two files:
;part #1 $6d00-$7800  - decrunches to $0800-$1e00
;part #2 $3a00-       - decrunches to $1e00-$2900
  ;!macro set_depack_pointers $d000
  lda #<$6c00
  sta bitfire_load_addr_lo
  lda #>$6c00
  sta bitfire_load_addr_hi
  jsr link_decomp

  lda #<$3a00
  sta bitfire_load_addr_lo
  lda #>$3a00
  sta bitfire_load_addr_hi
  jsr link_decomp

;Now, let's set the destination of plotting in the fine_tune routine, since the "lazy" part doesn't have access to our compiled addresses:
  lda #>charset
  sta blit_dst+2
  sta blit_dst2+2
  sta blit_dst_A+2
  sta low_blit_dst_A+2

;Now let the rotating chars "bounce" in y-direction so they don't fall too fast.
  lda #0
  sta blit_yspd_lsb+1
  lda #2
  sta blit_yspd_msb+1
  lda #$fe
  sta yspd_maxspeed+1


;Well, let's start Lazy Jones, then
  jmp link_exit

playAudioFx_Toilet:
  LDA #8
  STA $D413
  LDA #$10
  STA $D412
  LDA #$11
  STA $D412
  LDX #0
outer_loop:
  STX $D40F
  LDY #$40
inner_loop:
  DEY
  BNE inner_loop
  DEX
  BNE outer_loop
}

update_split:

  lda spriteshadow_xdir+1
  bpl move_shadow_right
  jmp move_shadow_left

move_shadow_right:
  lda $d016
  anc #$7
  eor #$7
  adc spriteshadow_x+1
  sec
  sbc #13
  bcs do_something_now_right
  rts
do_something_now_right:
  lsr
  lsr
  lsr
  tay

;sequence: 00,01,0a,0b,04,05,0e,0f,08,09,02,03,0c,0d,06,07,00,01
  lda screen0 + 0*40,y
  and #$f
  sta screen0 + 0*40,y
  lda screen0 + 1*40,y
  and #$f
  sta screen0 + 1*40,y
  lda screen0 + 2*40,y
  and #$f
  sta screen0 + 2*40,y
  lda screen0 + 3*40,y
  and #$f
  sta screen0 + 3*40,y
  lda screen0 + 4*40,y
  and #$f
  sta screen0 + 4*40,y
  lda screen0 + 5*40,y
  and #$f
  sta screen0 + 5*40,y
  lda screen0 + 6*40,y
  and #$f
  sta screen0 + 6*40,y
  lda screen0 + 7*40,y
  and #$f
  sta screen0 + 7*40,y
  lda screen0 + 8*40,y
  and #$f
  sta screen0 + 8*40,y
  lda screen0 + 9*40,y
  and #$f
  sta screen0 + 9*40,y
  lda screen0 +10*40,y
  and #$f
  sta screen0 +10*40,y
  lda screen0 +11*40,y
  and #$f
  sta screen0 +11*40,y
  lda screen0 +12*40,y
  and #$f
  sta screen0 +12*40,y
  lda screen0 +13*40,y
  and #$f
  sta screen0 +13*40,y
  lda screen0 +14*40,y
  and #$f
  sta screen0 +14*40,y
  lda screen0 +15*40,y
  and #$f
  sta screen0 +15*40,y
  lda screen0 +16*40,y
  and #$f
  sta screen0 +16*40,y
  lda screen0 +17*40,y
  and #$f
  sta screen0 +17*40,y
  lda screen0 +18*40,y
  and #$f
  sta screen0 +18*40,y
  lda screen0 +19*40,y
  and #$f
  sta screen0 +19*40,y
  lda screen0 +20*40,y
  and #$f
  sta screen0 +20*40,y
  lda screen0 +21*40,y
  and #$f
  sta screen0 +21*40,y
  lda screen0 +22*40,y
  and #$f
  sta screen0 +22*40,y
  lda screen0 +23*40,y
  and #$f
  sta screen0 +23*40,y
  lda screen0 +24*40,y
  and #$f
  sta screen0 +24*40,y

  lda #$f
  sta $d800 + 0*40,y
  sta $d800 + 1*40,y
  sta $d800 + 2*40,y
  sta $d800 + 3*40,y
  sta $d800 + 4*40,y
  sta $d800 + 5*40,y
  sta $d800 + 6*40,y
  sta $d800 + 7*40,y
  sta $d800 + 8*40,y
  sta $d800 +15*40,y
  sta $d800 +16*40,y
  sta $d800 +17*40,y
  sta $d800 +18*40,y
  sta $d800 +19*40,y
  sta $d800 +20*40,y
  sta $d800 +21*40,y
  sta $d800 +22*40,y
  sta $d800 +23*40,y
  sta $d800 +24*40,y
  rts

move_shadow_left:
  lda $d016
  anc #$7
  eor #$7
  adc spriteshadow_x+1
  sec
  sbc #11
  bcs do_something_now_left
  rts
do_something_now_left:
  lsr
  lsr
  lsr
  tay
  iny
  lda screen0 + 0*40,y
  ora #$50
  sta screen0 + 0*40,y
  lda screen0 + 1*40,y
  ora #$50
  sta screen0 + 1*40,y
  lda screen0 + 2*40,y
  ora #$50
  sta screen0 + 2*40,y
  lda screen0 + 3*40,y
  ora #$50
  sta screen0 + 3*40,y
  lda screen0 + 4*40,y
  ora #$50
  sta screen0 + 4*40,y
  lda screen0 + 5*40,y
  ora #$50
  sta screen0 + 5*40,y
  lda screen0 + 6*40,y
  ora #$50
  sta screen0 + 6*40,y
  lda screen0 + 7*40,y
  ora #$50
  sta screen0 + 7*40,y
  lda screen0 + 8*40,y
  ora #$50
  sta screen0 + 8*40,y
  lda screen0 + 9*40,y
  ora #$50
  sta screen0 + 9*40,y
  lda screen0 +10*40,y
  ora #$50
  sta screen0 +10*40,y
  lda screen0 +11*40,y
  ora #$50
  sta screen0 +11*40,y
  lda screen0 +12*40,y
  ora #$50
  sta screen0 +12*40,y
  lda screen0 +13*40,y
  ora #$50
  sta screen0 +13*40,y
  lda screen0 +14*40,y
  ora #$50
  sta screen0 +14*40,y
  lda screen0 +15*40,y
  ora #$50
  sta screen0 +15*40,y
  lda screen0 +16*40,y
  ora #$50
  sta screen0 +16*40,y
  lda screen0 +17*40,y
  ora #$50
  sta screen0 +17*40,y
  lda screen0 +18*40,y
  ora #$50
  sta screen0 +18*40,y
  lda screen0 +19*40,y
  ora #$50
  sta screen0 +19*40,y
  lda screen0 +20*40,y
  ora #$50
  sta screen0 +20*40,y
  lda screen0 +21*40,y
  ora #$50
  sta screen0 +21*40,y
  lda screen0 +22*40,y
  ora #$50
  sta screen0 +22*40,y
  lda screen0 +23*40,y
  ora #$50
  sta screen0 +23*40,y
  lda screen0 +24*40,y
  ora #$50
  sta screen0 +24*40,y

  lda #$b
  sta $d800 + 0*40,y
  sta $d800 + 1*40,y
  sta $d800 + 2*40,y
  sta $d800 + 3*40,y
  sta $d800 + 4*40,y
  sta $d800 + 5*40,y
  sta $d800 + 6*40,y
  sta $d800 + 7*40,y
  sta $d800 + 8*40,y
  sta $d800 +15*40,y
  sta $d800 +16*40,y
  sta $d800 +17*40,y
  sta $d800 +18*40,y
  sta $d800 +19*40,y
  sta $d800 +20*40,y
  sta $d800 +21*40,y
  sta $d800 +22*40,y
  sta $d800 +23*40,y
  sta $d800 +24*40,y
  rts

spriteshadow_orig:
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000
;  !byte %00000000,%00010000,%00000000

;  !byte %11111111,%11111111,%11111111
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %10000000,%00000000,%00000001
;  !byte %11111111,%11111111,%11111111

;  !byte %00000000,%11111111,%00000000
;  !byte %00000001,%11111111,%10000000
;  !byte %00000011,%11111111,%11000000
;  !byte %00000111,%11111111,%11100000
;  !byte %00001111,%11111111,%11110000
;  !byte %00011111,%11111111,%11111000
;  !byte %00111111,%11111111,%11111100
;  !byte %01111111,%11111111,%11111110
;  !byte %11111111,%11111111,%11111111
;  !byte %11111111,%11111111,%11111111
;  !byte %11111111,%11111111,%11111111
;  !byte %11111111,%11111111,%11111111
;  !byte %11111111,%11111111,%11111111
;  !byte %01111111,%11111111,%11111110
;  !byte %00111111,%11111111,%11111100
;  !byte %00011111,%11111111,%11111000
;  !byte %00001111,%11111111,%11110000
;  !byte %00000111,%11111111,%11100000
;  !byte %00000011,%11111111,%11000000
;  !byte %00000001,%11111111,%10000000
;  !byte %00000000,%11111111,%00000000

;  !byte %11111111,%11110000,%00000000
;  !byte %11111111,%11110000,%00000000
;  !byte %01111111,%11111000,%00000000
;  !byte %00111111,%11111100,%00000000
;  !byte %00011111,%11111110,%00000000
;  !byte %00001111,%11111111,%00000000
;  !byte %00000111,%11111111,%10000000
;  !byte %00000011,%11111111,%11000000
;  !byte %00000001,%11111111,%11100000
;  !byte %00000000,%11111111,%11110000
;  !byte %00000000,%11111111,%11110000
;  !byte %00000001,%11111111,%11110000
;  !byte %00000011,%11111111,%11110000
;  !byte %00000111,%11111111,%11100000
;  !byte %00001111,%11111111,%11000000
;  !byte %00011111,%11111111,%10000000
;  !byte %00111111,%11111111,%00000000
;  !byte %01111111,%11111110,%00000000
;  !byte %11111111,%11111100,%00000000
;  !byte %11111111,%11111000,%00000000
;  !byte %11111111,%11110000,%00000000

  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000
  !byte %00000000,%11111111,%00000000

;  !byte %00000000,%00111100,%00000000
;  !byte %00000000,%01111110,%00000000
;  !byte %00000000,%11111111,%00000000
;  !byte %00000001,%11111111,%10000000
;  !byte %00000011,%11111111,%11000000
;  !byte %00000111,%11111111,%11100000
;  !byte %00001111,%11111111,%11110000
;  !byte %00011111,%11111111,%11111000
;  !byte %00111111,%11111111,%11111100
;  !byte %01111111,%11111111,%11111110
;  !byte %11111111,%11111111,%11111111
;  !byte %01111111,%11111111,%11111110
;  !byte %00111111,%11111111,%11111100
;  !byte %00011111,%11111111,%11111000
;  !byte %00001111,%11111111,%11110000
;  !byte %00000111,%11111111,%11100000
;  !byte %00000011,%11111111,%11000000
;  !byte %00000001,%11111111,%10000000
;  !byte %00000000,%11111111,%00000000
;  !byte %00000000,%01111110,%00000000
;  !byte %00000000,%00111100,%00000000



fine_tune_rotated_not_mirrored:
  lda #$e
  sta blit_column_times2_A+1
  lda anim_poiR+1
  sta blit_poi_A+1
  sta low_blit_poi_A+1
  lda anim_poiR+2
  sta blit_poi_A+2
  sta low_blit_poi_A+2

;ToDo: flip upside down in y-dir. Either read upside down, or write upside down.
;      note that blit_poi_A and blit_dst_A are not static.
;      note that and low_blit_dst_A are not static.
;      low_blit_poi_A is static in the lowest 4 bits.
;  so it's more difficult than changing x or y direction.
; when blit_ypos increases, the text moves upwards.

  lda blit_ypos+1
  eor #$ff
  clc
  adc #1
  sta blit_ypos_A+1

blit_loop_A:
blit_column_times2_A:
  lda #0
  asl
  asl
  asl
  eor #$70
  ora #$80
  sta blit_dst_A+1
low_offset_A:
  ora #0
  sta low_blit_dst_A+1

coloffset_x:
  lda #0
  clc
  adc #7
  eor #$7
  and #$7
  asl
  asl
  asl
  asl
  sta extra_due_to_x_A+1

blit_ypos_A:
  lda #0
  lsr
  lsr
  lsr
  lsr
  and #$07
  tay
  lda blit_column_times2_A+1
  asl
  asl
  asl
  clc
  adc coarse_y_add,y
  clc
extra_due_to_x_A:
  adc #0
  anc #$70
  ora anim_poiR+1
  sta blit_poi_A+1
  ;clc
  adc #$50
  and #$70
  ora anim_poiR+1
  sta low_blit_poi_A+1


  lda blit_ypos_A+1
  eor #$f
  and #$f
  tax
  inx
  stx how_many_A+1
  lda blit_ypos_A+1
  and #$f
  ora blit_poi_A+1
  sta blit_poi_A+1
  ldy #$f
  ldx #0
fine_copy_more_A:
blit_poi_A:
  lda charset,x        ;4
blit_dst_A:
  sta charset+$80,y    ;4
  dey                  ;2
  inx                  ;2
how_many_A:
  cpx #$10             ;2
  bne fine_copy_more_A ;3 = 17

; Now, copy the LowLen and LowPoi
  cpx #$10
  beq we_are_done_A
  ldx #0
lower_loop_A:
low_blit_poi_A:
  lda charset,x       ;4
low_blit_dst_A:
  sta charset+$80,y   ;4
  inx                 ;2
  dey                 ;2
  bpl lower_loop_A    ;3 = 15

we_are_done_A:
  lda blit_column_times2_A+1
  sec
  sbc #2
  sta blit_column_times2_A+1
  bcc blit_loop_done_A
  jmp blit_loop_A
blit_loop_done_A:
  jmp done_fine_tuning

fine_tune:
  ; In here, we shall blit the text smoothly in x-pos (x_pos mod 8),
  ; and we shall move it smoothly in y-pos (y_pos mod 16)
  ; and mirror it in x-direction
  ; The 128 bytes to handle are at charset to charset+$7f
  ; Let's place the result at charset+$80 to $charset+$ff
  ; We need to swap the order of the char columns:
  ; so char0 goes into char 14
  ; so char1 goes into char 15
  ; so char2 goes into char 12
  ; so char3 goes into char 13
; This is the copy-routine for y=0:
; In here, we shall copy the rotated template into the correct X char-position ((x_pos/8)*8):
;  ldx #$7f
;fine_copy_more:
;  ldy charset,x
;  lda mirror,y
;  sta charset+$80,x
;  dex
;  bpl fine_copy_more
;  rts

; This is how one screen used to look (the order of the chars):
; Note that the right half of the screen has +$10 to each char ($10-$1f).
;06 08 0a 0c  0e 00 02 04  06 08 0a 0c  0e 00 02 04  06 08 0a 0c  1c 1a 18 16  14 12 10 1e  1c 1a 18 16  14 12 10 1e  1c 1a 18 16
;07 09 0b 0d  0f 01 03 05  07 09 0b 0d  0f 01 03 05  07 09 0b 0d  1d 1b 19 17  15 13 11 1f  1d 1b 19 17  15 13 11 1f  1d 1b 19 17
;00 02 04 06  08 0a 0c 0e  00 02 04 06  08 0a 0c 0e  00 02 04 06  16 14 12 10  1e 1c 1a 18  16 14 12 10  1e 1c 1a 18  16 14 12 10
;01 03 05 07  09 0b 0d 0f  01 03 05 07  09 0b 0d 0f  01 03 05 07  17 15 13 11  1f 1d 1b 19  17 15 13 11  1f 1d 1b 19  17 15 13 11
;0a 0c 0e 00  02 04 06 08  0a 0c 0e 00  02 04 06 08  0a 0c 0e 00  10 1e 1c 1a  18 16 14 12  10 1e 1c 1a  18 16 14 12  10 1e 1c 1a
;0b 0d 0f 01  03 05 07 09  0b 0d 0f 01  03 05 07 09  0b 0d 0f 01  11 1f 1d 1b  19 17 15 13  11 1f 1d 1b  19 17 15 13  11 1f 1d 1b
;04 06 08 0a  0c 0e 00 02  04 06 08 0a  0c 0e 00 02  04 06 08 0a  1a 18 16 14  12 10 1e 1c  1a 18 16 14  12 10 1e 1c  1a 18 16 14
;05 07 09 0b  0d 0f 01 03  05 07 09 0b  0d 0f 01 03  05 07 09 0b  1b 19 17 15  13 11 1f 1d  1b 19 17 15  13 11 1f 1d  1b 19 17 15
;0e 00 02 04  06 08 0a 0c  0e 00 02 04  06 08 0a 0c  0e 00 02 04  14 12 10 1e  1c 1a 18 16  14 12 10 1e  1c 1a 18 16  14 12 10 1e
;0f 01 03 05  07 09 0b 0d  0f 01 03 05  07 09 0b 0d  0f 01 03 05  15 13 11 1f  1d 1b 19 17  15 13 11 1f  1d 1b 19 17  15 13 11 1f
;08 0a 0c 0e  00 02 04 06  08 0a 0c 0e  00 02 04 06  08 0a 0c 0e  1e 1c 1a 18  16 14 12 10  1e 1c 1a 18  16 14 12 10  1e 1c 1a 18
;09 0b 0d 0f  01 03 05 07  09 0b 0d 0f  01 03 05 07  09 0b 0d 0f  1f 1d 1b 19  17 15 13 11  1f 1d 1b 19  17 15 13 11  1f 1d 1b 19
;02 04 06 08  0a 0c 0e 00  02 04 06 08  0a 0c 0e 00  02 04 06 08  18 16 14 12  10 1e 1c 1a  18 16 14 12  10 1e 1c 1a  18 16 14 12
;03 05 07 09  0b 0d 0f 01  03 05 07 09  0b 0d 0f 01  03 05 07 09  19 17 15 13  11 1f 1d 1b  19 17 15 13  11 1f 1d 1b  19 17 15 13
;0c 0e 00 02  04 06 08 0a  0c 0e 00 02  04 06 08 0a  0c 0e 00 02  12 10 1e 1c  1a 18 16 14  12 10 1e 1c  1a 18 16 14  12 10 1e 1c
;0d 0f 01 03  05 07 09 0b  0d 0f 01 03  05 07 09 0b  0d 0f 01 03  13 11 1f 1d  1b 19 17 15  13 11 1f 1d  1b 19 17 15  13 11 1f 1d
;06 08 0a 0c  0e 00 02 04  06 08 0a 0c  0e 00 02 04  06 08 0a 0c  1c 1a 18 16  14 12 10 1e  1c 1a 18 16  14 12 10 1e  1c 1a 18 16
;07 09 0b 0d  0f 01 03 05  07 09 0b 0d  0f 01 03 05  07 09 0b 0d  1d 1b 19 17  15 13 11 1f  1d 1b 19 17  15 13 11 1f  1d 1b 19 17
; After this, just repeat the chars endlessly.

; So, in order to move i y direction, we will handle chars $00 and $01 together.
; they will get data from $00+$01 at the top and from $0a+$0b at the bottom. So:
; Shift:     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
; UpLen:    10  f  e  d  c  b  a  9  8  7  6  5  4  3  2  1
; UpPoi:     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
; LowLen:    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
; LowPoi:      50 50 50 50 50 50 50 50 50 50 50 50 50 50 50

;  ldx #$7f
;  lda #$f0
;erase:
;  sta charset+$80,x
;  dex
;  bpl erase

; This is the copy-routine for any y:
rotatedR:
  lda #0
  bne fine_tune_mirrored_not_rotated
  jmp fine_tune_rotated_not_mirrored

fine_tune_mirrored_not_rotated:
  lda #$e
  sta blit_column_times2+1
  lda anim_poiR+1
  sta blit_poi+1
  sta blit_poi2+1
  lda anim_poiR+2
  sta blit_poi+2
  sta blit_poi2+2

blit_loop:
  lda blit_ypos+1
  anc #$f
  sta low_how_many+1
  eor #$f
  ;clc
  adc #1
  sta low_offset+1
blit_column_times2:
  lda #0
  asl
  asl
  asl
  ora #$80
  sta blit_dst+1
low_offset:
  ora #0
  sta blit_dst2+1

  lda coloffset_x+1
  and #$7
  asl
  asl
  asl
  asl
  sta extra_due_to_x+1

blit_ypos:
  lda #$0
  lsr
  lsr
  lsr
  lsr
  and #$07
  tay
  lda blit_column_times2+1
  asl
  asl
  asl
  clc
  adc coarse_y_add,y
  clc
extra_due_to_x:
  adc #0
  anc #$70
  ora anim_poiR+1
  sta blit_poi+1
  ;clc
  adc #$50
  and #$70
  ora anim_poiR+1
  sta blit_poi2+1


  lda blit_ypos+1
  and #$f
  eor #$f
  tax
  inx
  stx how_many+1
  dex
  lda blit_ypos+1
  and #$f
  ora blit_poi+1
  sta blit_poi+1
fine_copy_more:
blit_poi:
  ldy charset,x
  lda mirror,y
blit_dst:
  sta charset+$80,x
  dex
  bpl fine_copy_more

; Now, copy the LowLen and LowPoi

how_many:
  ldx #0
  cpx #$10
  beq we_are_done
  ldx #0
lower_loop:
blit_poi2:
  ldy charset,x
  lda mirror,y
blit_dst2:
  sta charset+$80,x
  inx
low_how_many:
  cpx #$10
  bne lower_loop
we_are_done:

  lda blit_column_times2+1
  sec
  sbc #2
  sta blit_column_times2+1
  bcc blit_loop_done
  jmp blit_loop
blit_loop_done:

done_fine_tuning:

; Move the right textrotator in y-dir:
;  lda blit_ypos+1
;  clc
;  adc #$ff
;  sta blit_ypos+1
blit_ypos_lsb:
  lda #0
  clc
blit_yspd_lsb:
  adc #$0
  sta blit_ypos_lsb+1
  lda blit_ypos+1
blit_yspd_msb:
  adc #$2
  sta blit_ypos+1

;Acceleration:
  lda blit_yspd_msb+1
yspd_maxspeed:
  cmp #$fd
  beq no_more_acceleration
  lda blit_yspd_lsb+1
  sec
  sbc #5
  sta blit_yspd_lsb+1
  lda blit_yspd_msb+1
  sbc #0
  sta blit_yspd_msb+1
no_more_acceleration:









  ;rotate the right textrotator:
;anim_poiR:
;  lda the_anim+$1000
;  lda anim_poiR+1
;  clc
;  adc #$80
;  sta anim_poiR+1
;  lda anim_poiR+2
;  adc #0
;
;  cmp #$c0
;  bne nowrrrR
;  lda rotatedR+1
;  eor #1
;  sta rotatedR+1
;  lda #$80
;nowrrrR:
;  sta anim_poiR+2

anim_poiR:
  lda the_anim+$1000
  lda anim_poiR+1
  sec
  sbc #$80
  sta anim_poiR+1
  lda anim_poiR+2
  sbc #0

  cmp #$7f
  bne nowrrrR
  lda rotatedR+1
  eor #1
  sta rotatedR+1
  lda #$bf
nowrrrR:
  sta anim_poiR+2
  rts

; When y is $10-$1f, upPoi is $50+table above   ($a*y_msb*8)
; When y is $20-$2f, upPoi is $20+table above   ($a*(y >> 4)*8) mod $80 = ($a* 2 *8) mod $80
; When y is $30-$3f, upPoi is $70+table above   ($a*(y >> 4)*8) mod $80 = ($a* 3 *8) mod $80
coarse_y_add:
  !byte $00,$50,$20,$70,$40,$10,$60,$30




init_screen0:
;y is row_no
  ldy #0
next_row:
  tya
  and #1
  sta toggle+1

  tya
  asr #$fe
  ;clc
  adc #7
  eor #7
  and #7

;  ;This *2 when displacement beetween animation is 16:
;  asl

  ;This *3 when displacement beetween animation is 24:
  sta add_one+1
  asl
  clc
add_one:
  adc #0

  asl
toggle:
  ora #0
  anc #$0f

;x is col_no
  ldx #0
next_char:
  ora #$10
scr_poi:
  sta screen0
  inc scr_poi+1
  bne nowrr
  inc scr_poi+2
nowrr:
  ;clc
  adc #2
  and #$0f
  inx
  cpx #40
  bne next_char
  iny
  cpy #25
  bne next_row
  rts

