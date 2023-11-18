  !cpu 6510
  !initmem $00

; This is the noisefader part.
; Shortly, a lot of noisy chars trying to gradually fade from "empty" to "filled", to fade between $d800-based gfx to sprite-based gfx.

; The biggest trick here to save rastertime is that
; the noise in the chars is only changed when $d800-$dbea IS NOT WRITTEN.
; Instead, another screen is chosen which moves the chars around.
; If colimage is moved around really fast, the noise will "get stuck"
; at it's current fade level, and repeat after 7 screens.

;done:
; Make sprite multiplexer.
;https://codebase64.org/doku.php?id=base:sprite_interleave

;todo:
; Make init code $0400-$0800 load slightly less. Start with fading in a single sprite, so move
; first colimage away, and gather the stuff needed so that sprite data2 and the code are close to eachother.
; Load less than $2000-$cfff in noisefader2.prg
; Make code load the rest of the part from disk. noisefader3.prg
; Add disk loading to the part, so add a few more sprimages and bgcols.
; Load textrotator animation $bf80-$ff7f.


; Turbo 250  https://csdb.dk/gfx/releases/20000/20633.png
; Copy 190   https://csdb.dk/release/?id=21141
; Action replay 6
; Turbo tape 64:  https://csdb.dk/gfx/releases/21000/21139.gif
; FROG! https://www.myabandonware.com/game/frog-5fj
; Fast Hack'em 2.4       https://csdb.dk/release/viewpic.php?id=101177&zoom=1
; Action replay 5:    https://www.c64-wiki.de/images/f/f4/AR6_Freezemenu.png
; cyberload 2.0 now loading cauldron   https://www.c64-wiki.de/wiki/CyberLoad     https://www.c64-wiki.de/images/0/01/CyberLoad_Cauldron.gif
; U.S. Gold loading screen
; Stroker 64

; Replace the 64-resetscreen with something funnier. Petscii, but something you can recognize.
; Make a 16-bit calc of sprite x positions. To make smaller gradual adjustments. When triggering, shrink it and make it large again.
; "Fix" colimage ypos against xpos. xpos=128 makes ypos+=8.
; Make a complete sequencer for demo bumps:
;   let each type of bump be configurable. Border colour, sprite colour, etc.
;   maybe just a "delay" + list of what kind of effect to trigger.
;   Let's have Delay = $e0-$fe
;   $ff = end
;   effect = high nybble
;     effect bonus data = low nybble
;   ...and that's all. Then we can sequence all of desired_noise_level and sprthings from there.
;   need more than $ff steps for this.
; More bumps to the music:
; + Background "bounce towards the middle of the colimage". Just a table with a bump with offset from its normal movement.
; + Sprite colour bump, replace colours to be brighter.
; + Background colour map, replace with a completely different colimage, one that isn't scrolling.
; + Sprite image bump. Set $d021, $d020 to something completely different, 
;   and four sprites in the middle of the screen with some image.
; + Show snippets of c64 games, but just static frames with ROM-font:
;    show original c64 reset screen - a little boring.
;    show turbo 250 - ok
;    show turboloader german - ok
;    show sam speaking.
;    show action replay 6?
; Sequence the bumps. Add more gradually.
; Load sprmap in ever when needed, loading another sprite map into the unused one.
; Load two interleaved new colbg in ever when needed.
; Do a "normal logo scroller" in chars. The same size as the sprite map:
;   24 chars wide, 18 chars high. Make it possible to move freely at any speed.
;   Use this somewhere to double the logo and make a trailing one.
;   Do this with or without colours - move the chars one frame ahead and the colours
;   when needed. Use this while loading two new colbg.
; colbg: bruce lee. gul gubbe, grön gubbe, svart gubbe med lite annan bakgrund från spelet, 64*32 pixels.
; colbg: fisk. Stor fjällig fisk som simmar åt höger.
; colbg: a "turn disk" colbg.
; Make some other colbg routine while loading the 2 new.
;    Perhaps a "noise chars", "empty chars", "filled chars" performers logo?
;    Can make a performers logo with some kind of corner chars.
; move always, even when c64reset screen is seen
; different movements for different colbg
;  colbg0: låt denna "studsa i takt" till musiken.
;  colbg1: Sinewave up/down
;  colbg2: in circles going to the left
;  colbg3: fast looping left scroll 4pix/frame
; different movements for different sprmaps
; sprite_image: a "turn disk" col_bg


; When x-pos is "larger than 1 screen", let any further x move y 8 pixels "up" gradually, so that endless x-scroll can be done by jumping from "2" back to "1" in the x-dir only.
; Put A number of sprite_images and colour_images in memory, and swap them in
; cycle through the last 3 during "turn disk".

; Make a double height sprite multiplexer as well. Keep the unexpanded one.
; 240 pixels wide * 168 pixels high, multicolour
; Make the colour image "repeatable", so it can scroll infinitely left
; Prepare to do disk loading during the part. Load the next sprites.

; Try to make it with full resolution sprites. ESCOS, but inside the screen.
; This means copy the sprite data from next sprite into the previous sprite.
; Set the new y beforehand.
; and adjust the $3f8 as good as possible.
; then restore the sprite data.
; Need 6 irqs for this.

; Set sprites behind chars.
; Some part of the demo, let the sprite image be on top of the chars, fading in the chars "behind the sprites". Can use full resolution sprites for this.


; Create part sequence:
; Fade from black to white through 7 colours. d800 + d021 only
; Fade from white to first sprite_image with white background
; Fade into color_image_0

; sprite_image_0: "You just need to"
; color_image_0: GET READY
; sprite_image_1: "stay a while"
; color_image_1: POWER UP
; sprite_image_2: "stay forever"
; color_image_2: INSERT COIN
; sprite_image_3: "to get to the"
; color_image_2: NEXT LEVEL

; Then fade into the rotating Next Level in textrotator

; Discarded:
; EXTRA LIFE
;Directly show static sprites small 4x2 sprite "TURN!". Calc screens.
;Load the rest of the part into memory.
;Fade sprites it into black slowly.
;  When it's 50%:
;Show larger color_image_0 "TURN!". Fade it into 100%.
;Fade in sprite_image_0 "TURN DISK!"
;Fade in larger color_image_1 "TURN the DISK!". Fade it into 100%.
;Fade in sprite_image_1 "Turn the disk, please!"
;Fade in larger color_image_2 "Colourful background". Fade it into 100%.
;Fade in sprite_image_1 "Turn the disk, please!", expanded
;Fade in larger color_image_3 "Colourful background". Fade it into 100%.
;Fade in sprite_image_1 "Turn the disk, please!", expanded
;Fade in larger color_image_4 "Colourful background". Fade it into 100%.
;Fade in sprite_image_1 "Turn the disk, please!", expanded
;repeat until disk is changed.
;Fade in larger color_image_5 "THANKS!". Fade it into 100%.
;Fade in larger sprite_image_2 "Heart, with a rose." Expanded. Fade it into 100%.
;Fade in larger color_image_6 "Heart". Fade it into 100%.
;Fade in larger sprite_image_2 "Heart, with a rose" non-expanded. Fade it into 100%.





; Fade in static sprite_image_0 from black "with bouncing alpha value"
; Fade in slow moving infinite colour_image_0 "behind" sprite_image_0
; Start moving the sprite_image_0
; Erase the data in the sprites "row by row"
; Fade colour_image_0 to expanded sprite_image_1
; Fade sprite_image_1 to colour_image_1
; Fade colour_image_1 unexpanded sprite_image_2
; Fade into "blue"
; Fade quite quickly blue -> light_blue -> white -> yellow -> brown -> black


;release      equ 0

!ifdef release {
    !src "../../bitfire/loader/loader_acme.inc"
    !src "../../bitfire/macros/link_macros_acme.inc"
}

  colimage_poi = $10
  d800_poi = $11
  task_pending = $12
  task_running = $13
  ghost_destpoi = $c0
  ghost_textpoi = $c2
  ghostbyte = $7fff

; memory map:
;$0400-$0800 init code. This will load the rest of the part. $2000-$5600
;And show the first two sprites on the screen.

;$0800-$2000 music

;$2000-$337f is the colimage0  with another one in the high nybbles.
;$3400-3500 is nybble swap table

;Table that needs to be loaded:

;$4000-$40ff charset (only chars 00-0f, $4000-$40ff is used)
charset = $4000
; sprites, width:  8 sprites * 3 bytes * 8 pixels per byte * 2 x-expanded = 8*3*8*2 = 384 pixels = 48 "chars"
; sprites, height: 7 sprites * 21 bytes * 2 y-expanded = 7*21*2 = 294 pixels = 36 "chars"
; in total 8*7 = 3584 bytes = $0e00 bytes
;Free space for 28 initial "preloaded" sprites = $4100-$4800

;ghostscreen uses sprite pointers at $47f8-$47ff
ghostscreen = $4400
;sprites = $4800 - $55ff
;sprites2 = $5600-$63ff

ghostscreen_intro = $6000

; These screens are calculated/randomized by 6502 code:
screen0 = $6400
screen1 = $6800
screen2 = $6c00
screen3 = $7000
screen4 = $7400
;screen5 = $7800
;screen6 = $7c00

;The ghostsprites are here:
ghostsprites = $7a00  ; - $7fff


;$8000-$b400 turbo tape screens: turbo 250. turbo tape 64, etc. With colours, some of them.
;$9000-$9fff is the Floyd-Steinberg table

;$b400- code

;DISABLE_STABLE = 1

  *= $0400
main:
;Start plotting the rasterbar colours:
;  sei
  cld
;  lda #$35
;  sta $01

;When we get here, the screen is blanked, and completely black.

  ldx #$ff
  txs
  lda #0
  sta $d015
  sta $d017
  lda $d011
  and #$7f
  ora #$0b
  sta $d011

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

  lda #0
  sta $d020
  sta $d021

  ldx #$4f
fill_cols:
  lda #$0
  sta $d800,x
  sta $d800-$28+ 2*$50,x
  sta $d800-$28+ 4*$50,x
  sta $d800-$28+ 6*$50,x
  sta $d800-$28+ 8*$50,x
  sta $d800-$28+10*$50,x
  sta $d800-$28+12*$50,x
  lda #$11
  sta $d800-$28+ 1*$50,x
  lda #$77
  sta $d800-$28+ 3*$50,x
  lda #$aa
  sta $d800-$28+ 5*$50,x
  lda #$dd
  sta $d800-$28+ 7*$50,x
  lda #$ee
  sta $d800-$28+ 9*$50,x
  lda #$44
  sta $d800-$28+11*$50,x
  dex
  bpl fill_cols

row_no:
  ldx #$ff
  inx
  stx row_no+1
  cpx #25
  beq done_initchars
  lda char_offsets,x
  tax
  ldy #39
writechars:
  txa
screnpoi:
  sta ghostscreen_intro+ 0*40,y
  dex
  dey
  bpl writechars
  lda screnpoi+1
  clc
  adc #$28
  sta screnpoi+1
  lda screnpoi+2
  adc #0
  sta screnpoi+2
  jmp row_no
done_initchars:


;Make blank chars:
  ldx #0
  lda #0
morefillchar:
  sta $4100,x
  sta $4200,x
  inx
  bne morefillchar

  lda #%11111111
  ldx #0
fill_sprites:
  sta ghostsprites+$000,x
  sta ghostsprites+$100,x
  sta ghostsprites+$200,x
  sta ghostsprites+$300,x
  sta ghostsprites+$400,x
  sta ghostsprites+$4ff,x
  inx
  bne fill_sprites

syncite5:
  lda $d011
  bpl syncite5
syncite6:
  lda $d011
  bmi syncite6

  lda #2      ;Bank at $4000-$7fff
  sta $dd00
  lda #$80    ;screen at $6000, charset at $4000
  sta $d018
  lda #$c0
  sta $d016

  sei
  lda #$7f
  sta $dc0d  ;disable timer interrupts which can be generated by the two CIA chips
  sta $dd0d  ;the kernal uses such an interrupt to flash the cursor and scan the keyboard, so we better stop it.
  lda $dc0d  ;by reading this two registers we negate any pending CIA irqs.
  lda $dd0d  ;if we don't do this, a pending CIA irq might occur after we finish setting up our irq.
  ;we don't want that to happen.
  lda #<irq_init
  sta $fffe
  lda #>irq_init
  sta $ffff
  lda #$f9
  sta $d012
  lda #$1b
  sta $d011

  ldx #1
  stx $d01a     ; enable raster interrupt
  lda $dc0d     ; acknowledge CIA interrupts
  lsr $d019     ; and video interrupts
  cli


!ifdef release {
;Load the Ghostbytescroller code at $e000-$fff7
  jsr link_load_next_comp
}
!ifndef release {
  lda #$3
  ldx #$ff
  ldy #$ff
loppan:
  dex
  bne loppan
  dey
  bne loppan
  sec
  sbc #1
  bne loppan
}
;Start the ghostscroller:
  lda #1
  sta done_loading_ghost+1


!ifdef release {
    ;Load the overload end part "stay_a_while" and put it under $d000-$dfff to be unpacked
    ;4 minutes later:
    ;load the "another visitor. stay a while. Stay forever"-sample to $8000-
                jsr link_load_next_raw
    ;Move the recently loaded file $8000-$8fff  and hide it under $d000-$dfff

    ; When safe_to_move_under_d000+1 gets incremented, we have rastertime between row $40 - $f7
    ; before another IRQ kicks in and $01 needs to be #$35 again for stable IRQ to work.
    ; So only perform memory move that fits in $c7 raster lines <= 12000 clock cycles
    ; One 256-byte block takes ~4000 clock cycles, so let's move 512 bytes every time
    ; we get a chance.

    ldy #$f
move_more:
safe_to_move_under_d000_now:
    lda #0
wait_until_safe:
    cmp safe_to_move_under_d000_now+1
    beq wait_until_safe
;    lda #$2
;    sta $d020
    lda #$34
    sta $01
    jsr move_one
    dey
    jsr move_one
    lda #$35
    sta $01
;    lda #$0
;    sta $d020
    dey
    bpl move_more
    jmp continue

move_one:
    ldx #0
poi1:
    lda $8000,x
poi2:
    sta $d000,x
    inx
    bne poi1
    inc poi1+2
    inc poi2+2
    rts
continue:

}


!ifdef release {
;Load the rest of Noisefader code at $8000-$cfff
  jsr link_load_next_comp
}
!ifndef release {
  lda #$5
  ldx #$ff
  ldy #$ff
loppan2:
  dex
  bne loppan2
  dey
  bne loppan2
  sec
  sbc #1
  bne loppan2
}
; No need to start anything here - completely busy reading the scrolltext anyway.
;  lda #4
;  sta $d020

!ifdef release {
;Load the sprite_image_0 at $4800-$5600
  jsr link_load_next_comp
}
!ifndef release {
  lda #$3
  ldx #$ff
  ldy #$ff
loppan3:
  dex
  bne loppan3
  dey
  bne loppan3
  sec
  sbc #1
  bne loppan3
}

;  lda #7
;  sta $d020
  jmp start_demo

; How the first initial fade in chars are spread in x-dir:
char_offsets:
  !byte $2e+39
  !byte $29+39
  !byte $2c+39
  !byte $30+39
  !byte $2b+39
  !byte $2f+39
  !byte $28+39
  !byte $2c+39
  !byte $23+39
  !byte $28+39
  !byte $26+39
  !byte $29+39
  !byte $24+39
  !byte $25+39
  !byte $29+39
  !byte $26+39
  !byte $28+39
  !byte $22+39
  !byte $25+39
  !byte $21+39
  !byte $24+39
  !byte $26+39
  !byte $23+39
  !byte $25+39
  !byte $20+39

irq_init:
  sta save_ai+1
  sty save_yi+1
  stx save_xi+1

  jsr preintro_fillchars
!ifdef release {
  jsr link_music_play
} else {
  jsr music+3
}

done_loading_ghost:
  lda #0
  beq dont_advance
  lda #<ghostsprites
  sta ghost_destpoi
  lda #>ghostsprites
  sta ghost_destpoi+1

  lda #<scrolltext
  sta ghost_textpoi
  lda #>scrolltext
  sta ghost_textpoi+1
;$d012 is #$f9 already:
;  lda #$f9
;  sta $d012
  lda $d011
  and #$7f
  sta $d011
  lda #<irq_ghost_0
  sta $fffe
  lda #>irq_ghost_0
  sta $ffff
dont_advance:

  asl $d019
save_ai:
  lda #0
save_yi:
  ldy #0
save_xi:
  ldx #0
  rti

preintro_fillchars:
  lda #$ff
  ldx #$7
clop:
  ldy offsets,x
chpoi:
  sta $42b0,y
  dex
  bpl clop
  lda chpoi+1
  sec
  sbc #8
  sta chpoi+1
  lda chpoi+2
  sbc #0
  and #$3
  ora #$40
  sta chpoi+2
  rts

offsets:
  !byte $00, $98+1, $50+2, $d8+3, $30+4, $78+5, $f0+6, $18+7

  !align 255,0,0
nybbleswap_table:
  !byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$a0,$b0,$c0,$d0,$e0,$f0
  !byte $01,$11,$21,$31,$41,$51,$61,$71,$81,$91,$a1,$b1,$c1,$d1,$e1,$f1
  !byte $02,$12,$22,$32,$42,$52,$62,$72,$82,$92,$a2,$b2,$c2,$d2,$e2,$f2
  !byte $03,$13,$23,$33,$43,$53,$63,$73,$83,$93,$a3,$b3,$c3,$d3,$e3,$f3
  !byte $04,$14,$24,$34,$44,$54,$64,$74,$84,$94,$a4,$b4,$c4,$d4,$e4,$f4
  !byte $05,$15,$25,$35,$45,$55,$65,$75,$85,$95,$a5,$b5,$c5,$d5,$e5,$f5
  !byte $06,$16,$26,$36,$46,$56,$66,$76,$86,$96,$a6,$b6,$c6,$d6,$e6,$f6
  !byte $07,$17,$27,$37,$47,$57,$67,$77,$87,$97,$a7,$b7,$c7,$d7,$e7,$f7
  !byte $08,$18,$28,$38,$48,$58,$68,$78,$88,$98,$a8,$b8,$c8,$d8,$e8,$f8
  !byte $09,$19,$29,$39,$49,$59,$69,$79,$89,$99,$a9,$b9,$c9,$d9,$e9,$f9
  !byte $0a,$1a,$2a,$3a,$4a,$5a,$6a,$7a,$8a,$9a,$aa,$ba,$ca,$da,$ea,$fa
  !byte $0b,$1b,$2b,$3b,$4b,$5b,$6b,$7b,$8b,$9b,$ab,$bb,$cb,$db,$eb,$fb
  !byte $0c,$1c,$2c,$3c,$4c,$5c,$6c,$7c,$8c,$9c,$ac,$bc,$cc,$dc,$ec,$fc
  !byte $0d,$1d,$2d,$3d,$4d,$5d,$6d,$7d,$8d,$9d,$ad,$bd,$cd,$dd,$ed,$fd
  !byte $0e,$1e,$2e,$3e,$4e,$5e,$6e,$7e,$8e,$9e,$ae,$be,$ce,$de,$ee,$fe
  !byte $0f,$1f,$2f,$3f,$4f,$5f,$6f,$7f,$8f,$9f,$af,$bf,$cf,$df,$ef,$ff

!warn "end of Noisefader loader code 0400-0800, must be less than 2048 ($0800): ",*

  *= $0800
music:
!ifndef release {
  ;!bin "starquest.sid",,$7e
  ;!bin "../../music/true-north-17.prg",,2
  !bin "../../music/music.prg",,2
  ;!bin "../../music/PREV2.PRG",,2
musicend:
}




  *= $2000
; A 128 colours wide and 41 colours high image that is to be copied into $d800:
colimage0:
;  !bin "colour_images/colimage_0.png.bin"
;one colimage is 42 rows (but only 41 rows are visible) and 128 columns. Two rows are packed into 128 bytes. 42*128/2 = 2688 bytes.
;-$2a80

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

;Least Significant Nybble is shown above Most Significant Nybble, so:
;  !fill 128,$10
;  !fill 128,$32
;  !fill 128,$54

;Rainbow:
;  !fill 128,$60
;  !fill 128,$42
;  !fill 128,$5c
;  !fill 128,$73
;  !fill 128,$d1
;  !fill 128,$fa
;  !fill 128,$e8
;  !fill 128,$b9
;  !fill 128,$60
;  !fill 128,$42
;  !fill 128,$5c
;  !fill 128,$73
;  !fill 128,$d1
;  !fill 128,$fa
;  !fill 128,$e8
;  !fill 128,$b9
;  !fill 128,$60
;  !fill 128,$42
;  !fill 128,$5c
;  !fill 128,$73
;  !fill 128,$d1

  !fill 128,$00
  !fill 128,$11
  !fill 128,$00
  !fill 128,$77
  !fill 128,$00
  !fill 128,$aa
  !fill 128,$00
  !fill 128,$dd
  !fill 128,$00
  !fill 128,$ee
  !fill 128,$00
  !fill 128,$44
  !fill 128,$00
  !fill 128,$77
  !fill 128,$00
  !fill 128,$33
  !fill 128,$00
  !fill 128,$11
  !fill 128,$00
  !fill 128,$44
  !fill 128,$00

  *= $2a80
  !align 255,0,0
;-$2b00
colimage1:
  !bin "colour_images/colimage_0.png.bin"
;-$3580












;$4000-$4200 charset

  *= $4800
sprites:
  !bin "sprite_images/sprite_image_0.spr"

  *= $5600
sprites2:
  !bin "sprite_images/sprite_image_1.spr"


  *= $8000
; TURBO TAPE 64 screen. Black background, all chars green:
  !byte $20,$20,$20,$20,$20,$20,$20,$55,$43,$43,$43,$43,$43,$43,$43,$43   ;       UCCCCCCCC
  !byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43   ;CCCCCCCCCCCCCCCC
  !byte $43,$49,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42   ;CI             B
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$42,$20,$20,$20,$20,$20,$20   ;         B      
  !byte $20,$20,$20,$20,$20,$20,$20,$42,$20,$20,$20,$20,$20,$20,$14,$15   ;       B      ..
  !byte $12,$02,$0f,$20,$14,$01,$10,$05,$20,$36,$34,$20,$20,$20,$20,$20   ;... .... 64     
  !byte $20,$42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42   ; B             B
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$17,$12,$09,$14,$14,$05,$0e,$20   ;        ....... 
  !byte $02,$19,$20,$20,$20,$20,$20,$20,$20,$42,$20,$20,$20,$20,$20,$20   ;..       B      
  !byte $20,$20,$20,$20,$20,$20,$20,$42,$20,$20,$13,$14,$05,$10,$08,$01   ;       B  ......
  !byte $0e,$20,$13,$05,$0e,$1a,$20,$06,$12,$05,$09,$02,$15,$12,$07,$20   ;. .... ........ 
  !byte $20,$42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42   ; B             B
  !byte $20,$20,$20,$31,$39,$38,$33,$20,$20,$04,$05,$15,$14,$13,$03,$08   ;   1983  .......
  !byte $05,$20,$36,$34,$05,$12,$20,$20,$20,$42,$20,$20,$20,$20,$20,$20   ;. 64..   B      
  !byte $20,$20,$20,$20,$20,$20,$20,$42,$20,$20,$20,$20,$20,$20,$20,$20   ;       B        
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$4a   ; B             J
  !byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43   ;CCCCCCCCCCCCCCCC
  !byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$4b,$20,$20,$20,$20,$20,$20   ;CCCCCCCCCK      
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$13,$01,$16,$05,$20,$0c,$0f,$01   ;        .... ...
  !byte $04,$20,$16,$05,$12,$09,$06,$19,$20,$20,$03,$01,$20,$31,$30,$0d   ;. ......  .. 10.
  !byte $01,$0c,$20,$13,$03,$08,$0e,$05,$0c,$0c,$05,$12,$20,$21,$20,$20   ;.. ......... !  
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$0f,$12,$09,$07,$09,$0e,$01,$0c   ;        ........
  !byte $20,$03,$0f,$0d,$0d,$0f,$04,$0f,$12,$05,$20,$20,$42,$20,$20,$14   ; .........  B  .
  !byte $15,$12,$02,$0f,$20,$14,$01,$10,$05,$20,$36,$34,$20,$20,$20,$20   ;.... .... 64    
  !byte $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40   ;@@@@@@@@@@@@@@@@
  !byte $40,$40,$40,$40,$5b,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40   ;@@@@[@@@@@@@@@@@
  !byte $40,$40,$40,$40,$40,$40,$40,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;@@@@@@@         
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42,$20,$20,$20   ;            B   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$13,$01,$16,$05,$27,$10,$12,$07,$2e,$0e,$01,$0d,$05   ;   ....'........
  !byte $27,$20,$20,$20,$42,$20,$20,$20,$1f,$13,$27,$10,$12,$07,$2e,$0e   ;'   B   ..'.....
  !byte $01,$0d,$05,$27,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;...'            
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42,$20,$20,$20   ;            B   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$0c,$0f,$01,$04,$27,$10,$12,$07,$2e,$0e,$01,$0d,$05   ;   ....'........
  !byte $27,$20,$20,$20,$42,$20,$20,$20,$1f,$0c,$27,$10,$12,$07,$2e,$0e   ;'   B   ..'.....
  !byte $01,$0d,$05,$27,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;...'            
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42,$20,$20,$20   ;            B   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$16,$05,$12,$09,$06,$19,$27,$10,$12,$07,$2e,$0e,$01   ;   ......'......
  !byte $0d,$05,$27,$20,$42,$20,$20,$20,$1f,$16,$27,$10,$12,$07,$2e,$0e   ;..' B   ..'.....
  !byte $01,$0d,$05,$27,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;...'            
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42,$20,$20,$20   ;            B   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$03,$3d,$20,$14,$01,$13,$14,$05,$20,$20,$20,$20,$20   ;   .= .....     
  !byte $20,$20,$20,$20,$42,$20,$20,$20,$0c,$05,$05,$12,$14,$01,$13,$14   ;    B   ........
  !byte $05,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;.               
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$92,$85,$94,$95,$92,$8e,$20   ;         ...... 
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;        ..����..
  !byte $00,$00,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;..����....����..

  *= $8400
; MrZ Turbo 250:           $d020 = $e   $d021 = $6    $d800 = $e
  !byte $70,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43   ;pCCCCCCCCCCCCCCC
  !byte $43,$43,$43,$43,$6e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;CCCCn           
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$42,$20,$14,$15,$12,$02,$0f,$20   ;        B ..... 
  !byte $32,$35,$30,$20,$02,$19,$20,$0d,$12,$2e,$1a,$20,$42,$20,$20,$20   ;250 .. .... B   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $42,$03,$01,$0e,$20,$08,$01,$0e,$04,$0c,$05,$20,$10,$12,$0f,$07   ;B... ...... ....
  !byte $12,$01,$0d,$13,$42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;....B           
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$42,$02,$05,$14,$17,$05,$05,$0e   ;        B.......
  !byte $20,$24,$30,$38,$30,$31,$2d,$24,$06,$06,$33,$02,$42,$20,$20,$20   ; $0801-$..3.B   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $6b,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43   ;kCCCCCCCCCCCCCCC
  !byte $43,$43,$43,$43,$73,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;CCCCs           
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$42,$1f,$0c,$20,$20,$20,$20,$20   ;        B..     
  !byte $20,$20,$20,$0c,$0f,$01,$04,$20,$10,$12,$0f,$07,$42,$20,$20,$20   ;   .... ....B   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $42,$1f,$13,$20,$28,$0e,$01,$0d,$05,$29,$20,$13,$01,$16,$05,$20   ;B.. (....) .... 
  !byte $10,$12,$0f,$07,$42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;....B           
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$6d,$43,$43,$43,$43,$43,$43,$43   ;        mCCCCCCC
  !byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$7d,$20,$20,$20   ;CCCCCCCCCCCC}   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $12,$05,$01,$04,$19,$2e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;......          
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$a0,$20,$20,$20,$20,$20,$20,$20   ;        �       
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;        ..����..
  !byte $00,$00,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;..����....����..

  *= $8800
; COPY 190 screen. $d020=1, $d021=1, Color #6 at top $d800-$d9bb, Color #8 at bottom. $d9bc-
  !byte $20,$20,$20,$20,$e9,$a0,$a0,$20,$e9,$a0,$df,$20,$a0,$a0,$df,$20   ;       頠 ��� ��� 
  !byte $a0,$20,$a0,$20,$20,$20,$20,$20,$20,$e9,$a0,$20,$e9,$a0,$df,$20   ;   � �      �� ��� 
  !byte $e9,$a0,$df,$20,$20,$20,$20,$20,$20,$20,$20,$20,$a0,$20,$20,$20   ;   ���         �   
  !byte $a0,$20,$a0,$20,$a0,$20,$a0,$20,$5f,$20,$69,$20,$20,$20,$20,$20   ;   � � � � _ i     
  !byte $e9,$69,$a0,$20,$a0,$20,$a0,$20,$a0,$e9,$a0,$20,$20,$20,$20,$20   ;   �i� � � ���     
  !byte $20,$20,$20,$20,$a0,$20,$20,$20,$a0,$20,$a0,$20,$a0,$a0,$69,$20   ;       �   � � ��i 
  !byte $20,$a0,$20,$20,$20,$20,$20,$20,$20,$20,$a0,$20,$5f,$a0,$a0,$20   ;    �        � _�� 
  !byte $a0,$a0,$a0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$a0,$20,$20,$20   ;   ���         �   
  !byte $a0,$20,$a0,$20,$a0,$20,$20,$20,$20,$a0,$20,$20,$20,$20,$20,$20   ;   � � �    �      
  !byte $20,$20,$a0,$20,$20,$20,$a0,$20,$a0,$69,$a0,$20,$20,$20,$20,$20   ;     �   � �i�     
  !byte $20,$20,$20,$20,$5f,$a0,$a0,$20,$5f,$a0,$69,$20,$a0,$20,$20,$20   ;       _�� _�i �   
  !byte $20,$a0,$20,$20,$20,$20,$20,$20,$20,$20,$a0,$20,$5f,$a0,$69,$20   ;    �        � _�i 
  !byte $5f,$a0,$69,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;   _�i             
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$28,$03,$29,$20   ;               (.) 
  !byte $95,$ae,$a0,$93,$94,$81,$88,$8c,$a0,$a0,$a8,$b0,$b2,$b0,$b1,$af   ;   .��.....��������
  !byte $b7,$b9,$b0,$b5,$b9,$b6,$a9,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;   �������         
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$31,$29,$20,$14   ;               1) .
  !byte $01,$10,$05,$20,$14,$0f,$20,$14,$01,$10,$05,$20,$20,$20,$20,$20   ;   ... .. ....     
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$32,$29,$20,$14   ;               2) .
  !byte $01,$10,$05,$20,$14,$0f,$20,$04,$09,$13,$0b,$20,$20,$20,$20,$20   ;   ... .. ....     
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$33,$29,$20,$04   ;               3) .
  !byte $09,$13,$0b,$20,$14,$0f,$20,$04,$09,$13,$0b,$20,$20,$20,$20,$20   ;   ... .. ....     
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$34,$29,$20,$04   ;               4) .
  !byte $09,$13,$0b,$20,$14,$0f,$20,$14,$01,$10,$05,$20,$20,$20,$20,$20   ;   ... .. ....     
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$13,$05,$0c,$05   ;               ....
  !byte $03,$14,$20,$0d,$0f,$04,$05,$21,$20,$20,$20,$20,$20,$20,$20,$20   ;   .. ....!        
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;           ..����..
  !byte $00,$00,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;   ..����....����..


;;C64 reset screen:     $d020 = $e   $d021 = $6    $d800 = $e
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$2a,$2a,$2a,$2a   ;            ****
;  !byte $20,$03,$0f,$0d,$0d,$0f,$04,$0f,$12,$05,$20,$36,$34,$20,$02,$01   ; ......... 64 ..
;  !byte $13,$09,$03,$20,$16,$32,$20,$2a,$2a,$2a,$2a,$20,$20,$20,$20,$20   ;... .2 ****     
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$36,$34,$0b,$20,$12,$01,$0d   ;         64. ...
;  !byte $20,$13,$19,$13,$14,$05,$0d,$20,$20,$33,$38,$39,$31,$31,$20,$02   ; ......  38911 .
;  !byte $01,$13,$09,$03,$20,$02,$19,$14,$05,$13,$20,$06,$12,$05,$05,$20   ;.... ..... .... 
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$12,$05,$01,$04,$19,$2e,$20,$20   ;        ......  
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $a0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;�               
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;        ..����..
;  !byte $00,$00,$ff,$ff,$ff,$ff,$40,$00,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;..����@...����..


;Action replay 5: d020=6 d021=6 d800=1
;>C:0400  20 20 20 20  01 03 14 09  0f 0e 20 12  05 10 0c 01       ...... .....
;>C:0410  19 20 16 35  2e 30 20 20  10 12 0f 06  05 13 13 09   . .5.0  ........
;>C:0420  0f 0e 01 0c  20 20 20 20  20 20 20 20  20 20 20 28   ....           (
;>C:0430  03 29 20 04  01 14 05 0c  20 05 0c 05  03 14 12 0f   .) ..... .......
;>C:0440  0e 09 03 13  20 31 39 38  38 20 20 20  20 20 20 20   .... 1988       
;>C:0450  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0460  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0470  20 20 20 20  20 20 20 20  20 63 63 63  63 63 63 63            ccccccc
;>C:0480  63 63 63 63  63 63 63 63  63 63 63 63  63 63 63 63   cccccccccccccccc
;>C:0490  63 63 63 63  63 63 63 63  63 63 63 63  63 63 63 20   ccccccccccccccc 
;>C:04a0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:04b0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:04c0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:04d0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:04e0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:04f0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0500  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0510  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0520  20 20 06 31  20 2d 20 03  0f 0e 06 09  07 15 12 05     .1 - .........
;>C:0530  20 0d 05 0d  0f 12 19 20  20 20 20 20  20 20 20 20    ......         
;>C:0540  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0550  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0560  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0570  20 20 06 33  20 2d 20 0e  0f 12 0d 01  0c 20 12 05     .3 - ...... ..
;>C:0580  13 05 14 20  20 20 20 20  20 20 20 20  20 20 20 20   ...             
;>C:0590  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:05a0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:05b0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:05c0  20 20 06 35  20 2d 20 15  14 09 0c 09  14 09 05 13     .5 - .........
;>C:05d0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:05e0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:05f0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0600  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0610  20 20 06 37  20 2d 20 09  0e 13 14 01  0c 0c 20 06     .7 - ....... .
;>C:0620  01 13 14 0c  0f 01 04 20  20 20 20 20  20 20 20 20   .......         
;>C:0630  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0640  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0650  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0660  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0670  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0680  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0690  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:06a0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:06b0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:06c0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:06d0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:06e0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:06f0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0700  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0710  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0720  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0730  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0740  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0750  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0760  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0770  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0780  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:0790  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:07a0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:07b0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:07c0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:07d0  20 20 20 20  20 20 20 20  20 20 20 20  20 20 20 20                   
;>C:07e0  20 20 20 20  20 20 20 20  00 00 bf ff  ff ff 00 00           ..����..
;>C:07f0  00 00 ff ff  ff ff 00 00  00 00 ff ff  ff ff 00 00   ..����....����..






; Action replay 6: d020=1 d021=1
  *= $8c00
  !byte $20,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77   ; wwwwwwwwwwwwwww
  !byte $77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77   ;wwwwwwwwwwwwwwww
  !byte $77,$77,$77,$77,$77,$77,$77,$20,$20,$20,$20,$20,$01,$03,$14,$09   ;wwwwwww     ....
  !byte $0f,$0e,$20,$12,$05,$10,$0c,$01,$19,$20,$10,$12,$0f,$06,$05,$13   ;.. ...... ......
  !byte $13,$09,$0f,$0e,$01,$0c,$20,$20,$16,$36,$2e,$30,$20,$20,$20,$20   ;......  .6.0    
  !byte $20,$20,$20,$20,$20,$20,$20,$28,$03,$29,$20,$04,$01,$14,$05,$0c   ;       (.) .....
  !byte $20,$05,$0c,$05,$03,$14,$12,$0f,$0e,$09,$03,$13,$20,$31,$39,$38   ; ........... 198
  !byte $39,$20,$20,$20,$20,$20,$20,$20,$20,$6f,$6f,$6f,$6f,$6f,$6f,$6f   ;9        ooooooo
  !byte $6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f   ;oooooooooooooooo
  !byte $6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$20   ;ooooooooooooooo 
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$0e   ;               .
  !byte $0f,$14,$09,$03,$05,$20,$31,$39,$38,$38,$20,$03,$0f,$10,$19,$12   ;..... 1988 .....
  !byte $09,$07,$08,$14,$20,$01,$03,$14,$20,$20,$20,$20,$20,$20,$20,$20   ;.... ...        
  !byte $20,$20,$20,$20,$20,$20,$20,$63,$63,$63,$63,$63,$63,$63,$63,$63   ;       ccccccccc
  !byte $63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63   ;cccccccccccccccc
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$01,$14,$05   ;            ....
  !byte $0c,$20,$05,$0c,$05,$03,$14,$12,$0f,$0e,$09,$03,$13,$20,$20,$0c   ;. ...........  .
  !byte $14,$04,$20,$20,$0e,$05,$09,$14,$08,$05,$12,$20,$20,$20,$20,$20   ;..  .......     
  !byte $20,$20,$20,$01,$15,$14,$08,$0f,$12,$09,$1a,$05,$13,$20,$0f,$12   ;   .......... ..
  !byte $20,$03,$0f,$0e,$04,$0f,$0e,$05,$13,$20,$14,$08,$05,$20,$15,$13   ; ........ ... ..
  !byte $05,$20,$0f,$06,$20,$20,$20,$20,$20,$20,$09,$14,$13,$20,$10,$12   ;. ..      ... ..
  !byte $0f,$04,$15,$03,$14,$13,$20,$14,$0f,$20,$12,$05,$10,$12,$0f,$04   ;...... .. ......
  !byte $15,$03,$05,$20,$03,$0f,$10,$19,$12,$09,$07,$08,$14,$20,$20,$20   ;... .........   
  !byte $20,$20,$20,$0d,$01,$14,$05,$12,$09,$01,$0c,$2e,$20,$09,$14,$20   ;   ......... .. 
  !byte $09,$13,$20,$20,$09,$0c,$0c,$05,$07,$01,$0c,$20,$14,$0f,$20,$20   ;..  ....... ..  
  !byte $0d,$01,$0b,$05,$20,$20,$20,$20,$20,$20,$20,$20,$03,$0f,$10,$09   ;....        ....
  !byte $05,$13,$20,$0f,$06,$20,$13,$15,$03,$08,$20,$0d,$01,$14,$05,$12   ;.. .. .... .....
  !byte $09,$01,$0c,$20,$17,$09,$14,$08,$0f,$15,$14,$20,$20,$20,$20,$20   ;... .......     
  !byte $20,$20,$20,$20,$20,$14,$08,$05,$20,$03,$0f,$0e,$13,$05,$0e,$14   ;     ... .......
  !byte $20,$20,$0f,$06,$20,$14,$08,$05,$20,$03,$0f,$10,$19,$12,$09,$07   ;  .. ... .......
  !byte $08,$14,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$0f   ;..             .
  !byte $17,$0e,$05,$12,$13,$20,$0f,$12,$20,$14,$08,$05,$09,$12,$20,$0c   ;..... .. ..... .
  !byte $09,$03,$05,$0e,$03,$05,$05,$13,$2e,$20,$20,$20,$20,$20,$20,$20   ;.........       
  !byte $20,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f   ; ooooooooooooooo
  !byte $6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f   ;oooooooooooooooo
  !byte $6f,$6f,$6f,$6f,$6f,$6f,$6f,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;ooooooo         
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$06,$31,$20,$2d,$20,$03,$0f   ;         .1 - ..
  !byte $0e,$06,$09,$07,$15,$12,$05,$20,$0d,$05,$0d,$0f,$12,$19,$20,$20   ;....... ......  
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$06,$33,$20,$2d,$20,$0e,$0f   ;         .3 - ..
  !byte $12,$0d,$01,$0c,$20,$12,$05,$13,$05,$14,$20,$20,$20,$20,$20,$20   ;.... .....      
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$06,$35,$20,$2d,$20,$15,$14   ;         .5 - ..
  !byte $09,$0c,$09,$14,$09,$05,$13,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;.......         
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$06,$37,$20,$2d,$20,$09,$0e   ;         .7 - ..
  !byte $13,$14,$01,$0c,$0c,$20,$06,$01,$13,$14,$0c,$0f,$01,$04,$20,$20   ;..... ........  
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$6f,$6f,$6f,$6f,$6f,$6f,$6f   ;         ooooooo
  !byte $6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f   ;oooooooooooooooo
  !byte $6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$20   ;ooooooooooooooo 
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;        ..����..
  !byte $00,$00,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;..����....����..

; Action replay 6 colors:  $d8cf - $da29 = 2 
;>C:d800  01 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:d810  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:d820  00 00 00 00  00 00 00 01  00 00 00 00  00 00 00 00   ................
;>C:d830  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:d840  00 00 00 00  00 00 00 00  00 00 00 00  01 01 01 01   ................
;>C:d850  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:d860  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:d870  00 01 01 01  01 01 01 01  01 00 00 00  00 00 00 00   ................
;>C:d880  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:d890  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 01   ................
;>C:d8a0  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:d8b0  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:d8c0  01 01 01 01  01 01 01 01  00 00 00 00  00 00 00 02   ................
;>C:d8d0  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:d8e0  02 02 02 02  02 02 02 02  01 01 01 01  01 01 01 01   ................
;>C:d8f0  01 01 01 01  01 01 01 00  00 00 00 00  00 00 00 00   ................
;>C:d900  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:d910  01 01 01 01  01 01 01 01  02 02 02 02  02 02 02 02   ................
;>C:d920  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:d930  02 02 02 02  02 02 02 02  02 02 02 01  01 01 01 01   ................
;>C:d940  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:d950  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:d960  02 02 02 02  01 01 01 01  02 02 02 02  02 02 02 02   ................
;>C:d970  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:d980  02 02 02 02  02 02 02 02  02 02 02 02  02 01 01 01   ................
;>C:d990  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:d9a0  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:d9b0  02 02 02 02  01 01 01 01  02 02 02 02  02 02 02 02   ................
;>C:d9c0  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:d9d0  02 02 02 02  02 02 02 02  02 02 02 01  01 01 01 01   ................
;>C:d9e0  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:d9f0  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:da00  02 02 01 01  01 01 01 01  02 02 02 02  02 02 02 02   ................
;>C:da10  02 02 02 02  02 02 02 02  02 02 02 02  02 02 02 02   ................
;>C:da20  02 02 02 02  02 02 02 02  02 01 01 01  01 01 01 01   ................
;>C:da30  01 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:da40  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:da50  00 00 00 00  00 00 00 01  01 01 01 01  01 01 01 01   ................
;>C:da60  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:da70  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:da80  01 01 01 01  01 01 01 01  01 00 00 00  00 00 00 00   ................
;>C:da90  00 00 00 00  00 00 00 00  00 00 00 00  00 00 01 01   ................
;>C:daa0  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:dab0  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:dac0  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:dad0  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:dae0  00 00 00 00  00 00 00 00  00 00 01 01  01 01 01 01   ................
;>C:daf0  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:db00  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:db10  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:db20  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:db30  00 00 00 00  00 00 00 01  01 01 01 01  01 01 01 01   ................
;>C:db40  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:db50  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:db60  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:db70  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:db80  00 00 00 00  00 00 00 00  00 00 00 00  00 00 01 01   ................
;>C:db90  01 01 01 01  01 01 01 01  01 00 00 00  00 00 00 00   ................
;>C:dba0  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
;>C:dbb0  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 01   ................
;>C:dbc0  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:dbd0  01 01 01 01  01 01 01 01  01 01 01 01  01 01 01 01   ................
;>C:dbe0  01 01 01 01  01 01 01 01  00 00 00 00  00 00 00 00   ................
;>C:dbf0  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................



; This one has loads of colours, so perhaps skip this:
;; Fast Hack'em 2.0B, d020=2  d021=0
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$86,$81,$93,$94,$a0   ;           ....�
;  !byte $88,$81,$83,$8b,$a7,$85,$8d,$a0,$96,$b2,$ae,$b0,$82,$20,$20,$20   ;....�..�.���.   
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78   ;   xxxxxxxxxxxxx
;  !byte $78,$78,$78,$78,$78,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;xxxxx           
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$02,$19,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;   ..           
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$0d,$09,$0b,$05,$20,$0a,$2e,$20,$08,$05   ;      .... .. ..
;  !byte $0e,$12,$19,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;...             
;  !byte $20,$20,$20,$20,$20,$28,$03,$29,$31,$39,$38,$36,$20,$13,$0d,$01   ;     (.)1986 ...
;  !byte $13,$08,$05,$04,$20,$02,$19,$20,$0f,$15,$14,$13,$09,$04,$05,$12   ;.... .. ........
;  !byte $27,$38,$36,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;'86             
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$14,$08   ;              ..
;  !byte $05,$20,$31,$35,$34,$31,$20,$0d,$05,$0e,$15,$20,$20,$20,$20,$20   ;. 1541 ....     
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63   ;      cccccccccc
;  !byte $63,$63,$63,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;ccc             
;  !byte $20,$81,$29,$20,$13,$09,$0e,$07,$0c,$05,$20,$02,$01,$03,$0b,$15   ; .) ...... .....
;  !byte $10,$20,$20,$20,$20,$89,$29,$20,$01,$15,$14,$0f,$20,$0e,$09,$02   ;.    .) .... ...
;  !byte $02,$0c,$05,$12,$20,$32,$2e,$30,$20,$82,$29,$20,$04,$0f,$15,$02   ;.... 2.0 .) ....
;  !byte $0c,$05,$20,$02,$01,$03,$0b,$15,$10,$20,$20,$20,$20,$8a,$29,$20   ;.. ......    .) 
;  !byte $01,$12,$14,$27,$13,$20,$02,$01,$03,$0b,$15,$10,$20,$32,$2e,$31   ;...'. ...... 2.1
;  !byte $20,$83,$29,$20,$04,$0f,$15,$02,$0c,$05,$20,$28,$16,$05,$12,$09   ; .) ...... (....
;  !byte $06,$19,$29,$20,$20,$8b,$29,$20,$06,$01,$14,$20,$14,$12,$01,$03   ;..)  .) ... ....
;  !byte $0b,$13,$20,$20,$20,$20,$20,$20,$20,$84,$29,$20,$13,$09,$0e,$07   ;..       .) ....
;  !byte $0c,$05,$20,$0e,$09,$02,$02,$0c,$05,$12,$20,$20,$20,$8c,$29,$20   ;.. .......   .) 
;  !byte $10,$01,$12,$01,$0d,$05,$14,$05,$12,$20,$03,$0f,$10,$09,$05,$12   ;......... ......
;  !byte $20,$85,$29,$20,$04,$0f,$15,$02,$0c,$05,$20,$0e,$09,$02,$02,$0c   ; .) ...... .....
;  !byte $05,$12,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;..              
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$0d,$13,$04,$20,$0e,$09,$02   ;         ... ...
;  !byte $02,$0c,$05,$12,$13,$20,$28,$16,$32,$2e,$33,$20,$12,$0f,$0d,$29   ;..... (.2.3 ...)
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63   ; ccccccccccccccc
;  !byte $63,$63,$63,$63,$63,$63,$63,$63,$20,$20,$20,$20,$20,$20,$20,$20   ;cccccccc        
;  !byte $20,$86,$29,$20,$13,$04,$32,$20,$16,$32,$2e,$30,$20,$20,$20,$20   ; .) ..2 .2.0    
;  !byte $20,$20,$20,$20,$20,$8d,$29,$20,$13,$04,$32,$20,$16,$33,$2e,$30   ;     .) ..2 .3.0
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$01,$15,$14,$0f,$20,$02   ;          .... .
;  !byte $01,$03,$0b,$15,$10,$20,$16,$05,$12,$13,$09,$0f,$0e,$13,$20,$20   ;..... ........  
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63   ;  cccccccccccccc
;  !byte $63,$63,$63,$63,$63,$63,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;cccccc          
;  !byte $20,$87,$29,$20,$04,$0f,$15,$02,$0c,$05,$20,$20,$20,$20,$20,$20   ; .) ......      
;  !byte $20,$20,$20,$20,$20,$8e,$29,$20,$04,$0f,$15,$02,$0c,$05,$20,$28   ;     .) ...... (
;  !byte $16,$05,$12,$09,$06,$19,$29,$20,$20,$88,$29,$20,$13,$04,$32,$20   ;......)  .) ..2 
;  !byte $16,$32,$2e,$30,$20,$20,$20,$20,$20,$20,$20,$20,$20,$8f,$29,$20   ;.2.0         .) 
;  !byte $13,$04,$32,$20,$16,$33,$2e,$30,$20,$20,$20,$20,$20,$20,$20,$20   ;..2 .3.0        
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$02,$0f,$0f,$14,$20,$17,$08,$09,$03,$08,$20,$12,$0f,$15   ;  .... ..... ...
;  !byte $14,$09,$0e,$05,$3f,$20,$a0,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;....? �         
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
;  !byte $20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;        ..����..
;  !byte $00,$00,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$bf,$ff,$ff,$ff,$00,$00   ;..����....����..

; Fast Hack'em colours:
;>C:d800  fe fe fe fe  fe fe fe fe  fe fe fe f7  f7 f7 f7 f7   ����������������
;>C:d810  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 fe fe fe   ����������������
;>C:d820  fe fe fe fe  fe fe fe fe  f6 f6 f6 f6  f6 f6 f6 f6   ����������������
;>C:d830  f6 f6 f6 f6  f6 f6 f6 f6  f6 f6 f6 f6  f6 f6 f6 f6   ����������������
;>C:d840  f6 f6 f6 f6  f6 fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:d850  f6 f6 f6 f6  f6 f6 f6 f6  f6 f6 f6 f6  f6 f6 f6 f6   ����������������
;>C:d860  f6 f6 f6 ff  ff fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:d870  fe fe fe fe  fe fe fe fe  ff ff ff ff  ff ff ff ff   ����������������
;>C:d880  ff ff ff ff  ff ff ff ff  ff ff ff ff  ff ff ff ff   ����������������
;(C:$d890) m
;>C:d890  ff ff ff fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:d8a0  ff ff ff ff  ff ff f1 ff  f1 f1 f1 f1  f1 ff ff ff   ����������������
;>C:d8b0  ff ff ff ff  ff ff ff ff  ff ff ff ff  ff ff ff ff   ����������������
;>C:d8c0  ff ff ff fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:d8d0  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:d8e0  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:d8f0  ff ff ff ff  ff ff ff ff  ff ff ff ff  ff ff f5 f5   ����������������
;>C:d900  f5 f5 f5 f5  f5 f5 f5 f5  f5 f5 f5 fe  fe fe fe fe   ����������������
;>C:d910  fe fe fe fe  fe fe fe fe  f5 f5 f5 f5  f5 f5 f5 f5   ����������������
;(C:$d920) m
;>C:d920  f5 f5 f5 f5  f5 f5 f6 f6  f6 f6 f6 f6  f6 f6 f6 f6   ����������������
;>C:d930  f6 f6 f6 fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:d940  f6 f1 ff f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:d950  f7 f7 f7 f7  f7 f1 ff f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:d960  f7 f7 f7 f7  f7 f7 f7 f7  f7 f1 ff f7  f7 f7 f7 f7   ����������������
;>C:d970  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f1 ff f7   ����������������
;>C:d980  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:d990  f7 f1 ff f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:d9a0  f7 f7 f7 f7  f7 f1 ff f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;(C:$d9b0) m
;>C:d9b0  f7 f7 fe fe  fe fe fe fe  f7 f1 ff f7  f7 f7 f7 f7   ����������������
;>C:d9c0  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f1 ff f7   ����������������
;>C:d9d0  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:d9e0  f7 f1 ff f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:d9f0  f7 f7 fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:da00  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:da10  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:da20  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:da30  f7 f7 f7 f7  f7 f7 f7 f7  f7 f5 f5 f5  f5 f5 f5 f5   ����������������
;(C:$da40) m
;>C:da40  f5 f5 f5 f5  f5 f5 f5 f5  f5 f5 f5 f5  f5 f5 f5 f5   ����������������
;>C:da50  fe fe fe fe  fe fe fe fe  f5 f5 f5 f5  f5 f5 f5 f5   ����������������
;>C:da60  f5 f6 f6 f6  f6 f6 f6 f6  f6 f6 f6 f6  f6 f6 f6 f6   ����������������
;>C:da70  f6 f6 f6 f6  f6 f6 f6 f6  fe fe fe fe  fe fe fe fe   ����������������
;>C:da80  f6 f1 ff f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:da90  f7 f7 f7 f7  f7 f1 ff f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:daa0  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:dab0  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:dac0  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;(C:$dad0) m
;>C:dad0  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f5 f5  f5 f5 f5 f5   ����������������
;>C:dae0  f5 f5 f5 f5  f5 f5 f5 f5  f5 f5 f5 f5  f5 f5 fe fe   ����������������
;>C:daf0  fe fe fe fe  fe fe fe fe  f5 f5 f5 f5  f5 f5 f5 f5   ����������������
;>C:db00  f5 f5 f6 f6  f6 f6 f6 f6  f6 f6 f6 f6  f6 f6 f6 f6   ����������������
;>C:db10  f6 f6 f6 f6  f6 f6 fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:db20  f6 f1 ff f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:db30  f7 f7 f7 f7  f7 f1 ff f7  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:db40  f7 f7 f7 f7  f7 f7 f7 fe  f7 f1 ff f7  f7 f7 f7 f7   ����������������
;>C:db50  f7 f7 f7 f7  f7 f7 f7 f7  f7 f7 f7 f7  f7 f1 ff f7   ����������������
;(C:$db60) m
;>C:db60  f7 f7 f7 f7  f7 f7 f7 f7  fe fe fe fe  fe fe fe fe   ����������������
;>C:db70  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:db80  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:db90  fe fe fe fe  fe fe fe fe  f7 f7 f7 f7  f7 f7 f7 f7   ����������������
;>C:dba0  f7 f7 f3 f3  f3 f3 f3 f3  f3 f3 f3 f3  f3 f3 f3 f3   ����������������
;>C:dbb0  f3 f3 f3 f3  f3 f3 f1 fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:dbc0  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:dbd0  fe fe fe fe  fe fe fe fe  fe fe fe fe  fe fe fe fe   ����������������
;>C:dbe0  fe fe fe fe  fe fe fe fe  f0 f0 f0 f0  f0 f0 f0 f0   ����������������
;(C:$dbf0) m
;>C:dbf0  f0 f0 f0 f0  f0 f0 f0 f0  f0 f0 f0 f0  f0 f0 f0 f0   ����������������


; Cannot place any glitch screens under $9000-$a000, since the ROM font shadows these screens.
  *= $9000
; A 4kB Floyd-Steiberg dithered table gradually going from "empty" to "filled"
floyd_table:
  !bin "gradient_bw_cropped.bin"

  *= $a000
back_to_nature:
; Back to nature 1982: $d020=3  $d021=0, $d800 is complex
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$34,$30,$35,$20,$03,$01   ;          405 ..
  !byte $0c,$0f,$12,$09,$05,$13,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;......          
  !byte $20,$20,$20,$20,$20,$20,$38,$20,$20,$02,$15,$07,$13,$20,$20,$20   ;      8  ....   
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$64,$6f,$79,$6f,$20,$20,$20,$20,$20,$20,$20   ;     doyo       
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$e9,$a0,$a0,$a8   ;            頠�
  !byte $91,$df,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;.�              
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$e9,$a0,$a0,$a0,$a0,$a7,$a0,$d5,$40,$40,$40,$40,$40   ;   頠�����@@@@@
  !byte $40,$40,$40,$40,$40,$40,$40,$49,$20,$20,$20,$20,$20,$20,$20,$20   ;@@@@@@@I        
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$e9,$a0,$a0,$a0,$a0,$a0   ;          頠���
  !byte $a9,$a0,$69,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;��i             
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$e9,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$69,$20,$20,$20,$20,$20,$20   ; 頠�����i      
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$a0,$e3,$e3,$cd,$a0,$a0,$a0   ;         ���͠��
  !byte $a0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$2a,$20   ;�             * 
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$5f,$a0,$a0,$a0,$cd,$ac,$a0,$a9,$df,$20,$20,$20,$20,$20,$20   ; _���ͬ���      
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5f,$a0,$a0,$a8,$69,$20   ;          _���i 
  !byte $20,$5f,$d0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ; _�             
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$5f,$a0,$a0,$df,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;   _���         
  !byte $20,$20,$20,$20,$20,$20,$2a,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;      *         
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5f,$a0,$a0,$df   ;            _���
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20,$20,$20,$20   ;           ]    
  !byte $20,$20,$20,$20,$20,$5f,$a0,$a9,$20,$20,$20,$20,$20,$20,$20,$20   ;     _��        
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$2a,$20,$20,$20,$20,$20,$20   ;         *      
  !byte $20,$5d,$20,$a0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$e9,$a0,$69   ; ] �         ��i
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$a0,$20,$a0,$20,$5d,$20,$20   ;         � � ]  
  !byte $20,$20,$20,$20,$e9,$a0,$69,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;    ��i         
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$a0,$20,$a0,$20,$a0,$20,$20,$20,$20,$20,$e9,$a0,$69,$20,$20   ; � � �     ��i  
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$a0,$20,$a0,$20,$a0,$20,$20   ;         � � �  
  !byte $20,$20,$20,$a8,$a7,$e3,$e3,$e3,$e3,$df,$64,$64,$64,$64,$20,$20   ;   �������dddd  
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;                
  !byte $20,$a0,$20,$5d,$20,$a0,$20,$20,$e9,$e3,$77,$78,$78,$78,$5f,$cd   ; � ] �  ��wxxx_�
  !byte $cd,$cd,$df,$a0,$a0,$ce,$cc,$20,$20,$20,$20,$20,$20,$20,$20,$20   ;��ߠ���         
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20,$5d,$20,$a0,$20,$20   ;         ] ] �  
  !byte $c0,$cf,$d0,$c5,$cf,$d0,$cd,$f2,$cf,$77,$78,$cf,$e3,$e5,$e5,$4c   ;���������wx����L
  !byte $6f,$79,$62,$f8,$f7,$e3,$e3,$e3,$e3,$f7,$f7,$f8,$f8,$62,$79,$79   ;oyb����������byy
  !byte $6f,$5d,$6f,$5d,$6f,$5d,$64,$64,$e5,$e5,$e7,$a0,$e5,$e7,$a0,$dd   ;o]o]o]dd��������
  !byte $e5,$a0,$a0,$e5,$a0,$e5,$e7,$e7,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0   ;堠����砠������
  !byte $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$5d,$a0,$5d,$a0,$5d,$a0,$a0   ;���������]�]�]��
  !byte $e5,$e5,$a0,$a0,$e5,$e7,$a0,$dd,$a0,$a0,$a0,$e5,$a0,$e5,$e7,$e7   ;�堠���ݠ�������
  !byte $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0   ;����������������
  !byte $a0,$a0,$a0,$5d,$a0,$a0,$a0,$a0,$a0,$a0,$5f,$a0,$e5,$e7,$a0,$e4   ;���]������_�����
  !byte $f9,$e4,$a0,$69,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0   ;���i������������
  !byte $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0   ;����������������
  !byte $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$88,$89,$94   ;�������������...
  !byte $a0,$a7,$91,$a7,$a0,$94,$8f,$a0,$85,$8e,$84,$a0,$a0,$a0,$a0,$93   ;��.��..�...����.
  !byte $8b,$89,$8c,$8c,$a0,$b1,$a0,$a0,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;....����..����..
  !byte $00,$00,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$00,$00   ;..����....����..
;-$93ff

; Back to nature, 1982, colours:
back_to_nature_cols:
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f4,$f4,$f4,$f4,$f4,$f4,$f4   ;����������������
  !byte $f4,$f4,$f4,$f4,$f4,$f4,$f4,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f4,$f4,$f3,$f4,$f4,$f4,$f4,$f4,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f1,$f1,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd   ;����������������
  !byte $fd,$fd,$fd,$fd,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f2,$f1,$f1,$f2,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fa,$fa,$fa,$fa,$fa   ;����������������
  !byte $fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd   ;����������������
  !byte $fd,$fd,$fd,$fd,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f2,$f1,$f1,$f1,$f1   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f1,$f1,$f1,$f1,$f1,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd   ;����������������
  !byte $fd,$fd,$fd,$fd,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f1,$f2,$f1,$f1   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fa,$fa,$fa,$fa   ;����������������
  !byte $fa,$fa,$fa,$fa,$fa,$fa,$f1,$f1,$fa,$fa,$fa,$fa,$fa,$fa,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd   ;����������������
  !byte $fd,$fd,$fd,$fd,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f2,$f1,$f1   ;����������������
  !byte $f1,$f1,$f1,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f1,$f1,$f1,$f1,$f1,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd   ;����������������
  !byte $fd,$fd,$fd,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f1,$f1,$f1   ;����������������
  !byte $f1,$f1,$f1,$f1,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f8,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fa,$fa,$fa,$fa,$fa   ;����������������
  !byte $fa,$fa,$fa,$fa,$fa,$fa,$f1,$f1,$f1,$f1,$f1,$fa,$fa,$fa,$f3,$f3   ;����������������
  !byte $f3,$f8,$f8,$f8,$f3,$f3,$f3,$f3,$f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd   ;����������������
  !byte $fd,$fd,$fd,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f1,$f3   ;����������������
  !byte $f1,$f1,$f1,$f3,$f1,$f3,$f3,$f3,$f3,$f8,$f8,$f8,$f8,$f8,$f3,$f3   ;����������������
  !byte $f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f1,$f3,$f1,$f1,$f3,$f1,$f1,$f3,$f3   ;����������������
  !byte $f3,$f8,$f8,$f8,$f8,$f8,$f3,$f3,$f3,$fd,$fd,$fd,$fd,$fd,$fd,$fd   ;����������������
  !byte $fd,$fd,$fd,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f8,$f8,$f8,$f8,$f8,$f3,$f3   ;����������������
  !byte $f9,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$f9,$f9,$f9,$f9,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f8,$f8,$f8,$f8,$f8,$f3,$f3,$f9,$f9,$fd,$fd,$fd,$fd,$fd,$fd   ;����������������
  !byte $fd,$fd,$fd,$f9,$f9,$f9,$f9,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3   ;����������������
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f8,$f8,$f8,$f8,$f8,$f3,$f3   ;����������������
  !byte $f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$fd,$fd,$f9,$f9,$f9,$f9,$f9   ;����������������
  !byte $f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5   ;����������������
  !byte $f5,$f8,$f5,$f8,$f5,$f8,$f5,$f5,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9   ;����������������
  !byte $f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe   ;����������������
  !byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$f8,$fe,$f8,$fe,$f8,$fe,$fe   ;����������������
  !byte $f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9   ;����������������
  !byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe   ;����������������
  !byte $fe,$fe,$fe,$f8,$fe,$fe,$fe,$fe,$fe,$fe,$f9,$f9,$f9,$f9,$f9,$f9   ;����������������
  !byte $f9,$f9,$f9,$f9,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe   ;����������������
  !byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe   ;����������������
  !byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe   ;����������������
  !byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe   ;����������������
  !byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0   ;����������������
  !byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0   ;����������������


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
d020_beat_table:
  !byte 0,6,$b,$4,$c,$5,$f,$d,$1




start_demo:
;  lda #$ff   ;Sprites on
;  sta $d015
;  lda #$ff
;  sta $d01c  ;mc on
;  lda #$00
;  sta $d017
;  lda #$00
;  sta $d01d

  ldx #$7f
fill_colimage0:
  lda #$00
  sta colimage0+ 0*$80,x
  lda #$11
  sta colimage0+ 1*$80,x
  lda #$00
  sta colimage0+ 2*$80,x
  lda #$77
  sta colimage0+ 3*$80,x
  lda #$00
  sta colimage0+ 4*$80,x
  lda #$aa
  sta colimage0+ 5*$80,x
  lda #$00
  sta colimage0+ 6*$80,x
  lda #$dd
  sta colimage0+ 7*$80,x
  lda #$00
  sta colimage0+ 8*$80,x
  lda #$ee
  sta colimage0+ 9*$80,x
  lda #$00
  sta colimage0+10*$80,x
  lda #$44
  sta colimage0+11*$80,x
  lda #$00
  sta colimage0+12*$80,x
  lda #$77
  sta colimage0+13*$80,x
  lda #$00
  sta colimage0+14*$80,x
  lda #$33
  sta colimage0+15*$80,x
  lda #$00
  sta colimage0+16*$80,x
  lda #$11
  sta colimage0+17*$80,x
  lda #$00
  sta colimage0+18*$80,x
  lda #$44
  sta colimage0+19*$80,x
  lda #$00
  sta colimage0+20*$80,x
  dex
  bne fill_colimage0

;Erase the charset:
  ldx #0
  lda #0
loppa2:
  sta charset,x
  inx
  bne loppa2

  jsr precalc_screens
  jsr copy_noise_into_chars

  lda #(sprites - $4000)/$40
  ldx #7
setsp:
  sta screen0+$3f8,x
  sta screen1+$3f8,x
  sta screen2+$3f8,x
  sta screen3+$3f8,x
  sta screen4+$3f8,x
  dex
  bpl setsp

;  lda #$0
;  sta $d027
;  sta $d028
;  sta $d029
;  sta $d02a
;  sta $d02b
;  sta $d02c
;  sta $d02d
;  sta $d02e
;  lda #$1
;  sta $d025
;  lda #$0
;  sta $d026
;  lda #$ff
;  sta $d01b

  lda #1
  sta switch_to_demo_now+1

ever:
  ; This is where we'll do disk loading on demand.
  ; Loading new sprite maps

;We are now fading away striped colimage -1 that is in this source code.
;We are also fading in sprite_image_0 "Male karate fighter"
  ; LOAD colimage_0.png.bin into colimage1
!ifdef release {
    jsr link_load_next_comp
}
  ; LOAD sprite_image_1.spr "Stay a while" into sprite_image_$5600
!ifdef release {
    jsr link_load_next_comp
}

toggle_colimage_nybbles:
  ldx #0
  beq toggle_colimage_nybbles
  dex
  stx toggle_colimage_nybbles+1

;colimage -1 just disappeared
  ; Show colimage1
  lda #>colimage1
  sta colimage_poi_even_even+1
  sta colimage_poi_even_odd+1
  sta colimage_poi_odd_even+1
  sta colimage_poi_odd_odd+1
  ; LOAD colimage_1.png.bin into colimage0
!ifdef release {
    jsr link_load_next_comp
}

wait_until_sprite_image_1_is_visible:
  lda sprite_map_no+1
  beq wait_until_sprite_image_1_is_visible

;Sprite image just disappeared.

;Set the colours for sprite_image1: (Stay a while)
  lda #$a
  sta spritemat_d025+1
  lda #$4
  sta spritemat_d027_1+1
  lda #$7            ; Flash the cape
  sta spritemat_d027_2+1
  lda #%11111111     ; For the hunter, all sprites are multicolor.
  sta spritemat_d01c+1

;;Patch the code to d027 colours:
;  lda #$ad           ;insert a lda $d02c
;  sta karate_spr2
;  lda #$ea
;  sta stay_a_while_spr01
;  sta stay_a_while_spr01+1
;;stay_a_while_spr5:
;;  nop
;;  nop
;;  sta $d02c
;;stay_a_while_spr01:
;;  lda #$e        -> nop nop
;;  sta $d027
;;  sta $d028
;;  lda #$e
;;karate_spr2:
;;  sta $d029      -> lda $d029

  lda #$f
  sta stay_a_while_spr01+1
  lda #$f
  sta karate_spr2-1
;stay_a_while_spr5:
;  nop
;  nop
;  sta $d02c
;stay_a_while_spr01:
;  lda #$e        -> lda #1
;  sta $d027
;  sta $d028
;  lda #$e        -> lda #$e
;karate_spr2:
;  sta $d029

  ; LOAD sprite_image_2.spr "Slay forever" into sprite_image_$4800
!ifdef release {
    jsr link_load_next_comp
}

toggle_colimage_nybbles2:
  ldx toggle_colimage_nybbles+1
  beq toggle_colimage_nybbles2
  dex
  stx toggle_colimage_nybbles+1

  ; Show colimage0
  lda #>colimage0
  sta colimage_poi_even_even+1
  sta colimage_poi_even_odd+1
  sta colimage_poi_odd_even+1
  sta colimage_poi_odd_odd+1

  ; LOAD colimage_2.png.bin "Bruce Lee" into colimage1
!ifdef release {
    jsr link_load_next_comp
}

wait_until_sprite_image_0_is_visible:
  lda sprite_map_no+1
  bne wait_until_sprite_image_0_is_visible
;Sprite image just disappeared.

;Switch into showing the Stay forever sprite mat.
;Set the colours for sprite_image2: (Stay forever)
  lda #$1
  sta spritemat_d025+1
  lda #$b
  sta spritemat_d026+1
  lda #$f
  sta spritemat_d027_1+1
  lda #$7            ; Flash colour
  sta spritemat_d027_2+1

  ;Patch the code to make spr0 and spr1 light red:
  lda #$a9
  sta stay_a_while_spr01
  lda #$0a
  sta stay_a_while_spr01+1
  ;Patch the code to make spr5 light brown:
  lda #$a9
  sta stay_a_while_spr5
  lda #$08
  sta stay_a_while_spr5+1
  lda #$ad       ;lda
  sta karate_spr2
;stay_a_while_spr5:
;  nop          -> lda #$08
;  nop          ->
;  sta $d02c
;stay_a_while_spr01:
;  nop          -> lda #$0a
;  nop          ->
;  sta $d027
;  sta $d028
;  lda #$e
;karate_spr2:
;  lda $d029


  ; LOAD sprite_image_3.spr into sprite_image_$5600  "To get to the..."
!ifdef release {
    jsr link_load_next_comp
}

; Wait until we should switch into the "Bruce Lee" colimage 1:
toggle_colimage_nybbles3:
  ldx toggle_colimage_nybbles+1
  beq toggle_colimage_nybbles3
  dex
  stx toggle_colimage_nybbles+1

;Just restart the movement of the colimage sines to avoid having to display 
;position -2 when the adjustment for wrapping the x-coodinates:
;  lda #100
;  sta colsin_ycou+1
;  lda #30
;  sta colsin_xcou+1
; Stop bouncing in y-dir:
  lda #0
  sta stop_bouncing_in_y+1


  ; Show colimage1 "Bruce Lee"
  lda #>colimage1
  sta colimage_poi_even_even+1
  sta colimage_poi_even_odd+1
  sta colimage_poi_odd_even+1
  sta colimage_poi_odd_odd+1

  ; COULD PRELOAD anything into colimage0 here: $2000-$337f
  ;!ifdef release {
  ;    jsr link_load_next_comp
  ;}

  ; Let's preload the transition code + graphics from textrotator into $c100-$cfff:
!ifdef release {
  jsr link_load_next_comp
}


wait_until_sprite_image_1_is_visible2:
  lda sprite_map_no+1
  beq wait_until_sprite_image_1_is_visible2

;Start showing the female karate fighter:
;Set the colours for sprite_image3: (female karate figher has red dress, not white)
  lda #2
  sta spritemat_d025+1
  lda #0
  sta spritemat_d026+1
  lda #$a
  sta spritemat_d027_1+1
  lda #$a            ; Don't flash her face. Let it stay light red.
  sta spritemat_d027_2+1
  lda #%11111000     ; For the karate girl, the leftmost three sprites should be hires.
  sta spritemat_d01c+1

  ;Patch the code to make spr5 normal again:
  lda #$ea
  sta stay_a_while_spr5
  sta stay_a_while_spr5+1
;Patch the code to set d027 colours:
  lda #$ad
  sta karate_spr2
  lda #$5
  sta karate_spr2-1
;Patch the code to d027 colours:
  lda #$8d           ;insert a sta $d02c
  sta karate_spr2
  lda #$a9
  sta stay_a_while_spr01
  lda #$f
  sta stay_a_while_spr01+1
  lda #$f
  sta karate_spr2-1
;stay_a_while_spr5:
;  lda #$08       -> nop nop
;  sta $d02c
;stay_a_while_spr01:
;  lda #$0a       -> lda #$c
;  sta $d027
;  sta $d028
;  lda #$e        -> lda #$c
;karate_spr2:
;  lda $d029      -> sta $d029


  ; COULD PRELOAD anything into sprite_image_$4800 here: $4800-$5600
  ;!ifdef release {
  ;    jsr link_load_next_comp
  ;}
!ifndef release {
freeze:
  jmp freeze
}



; Wait until female karate fighter is 100% visible:

toggle_colimage_nybbles4:
  ldx toggle_colimage_nybbles+1
  beq toggle_colimage_nybbles4
  dex
  stx toggle_colimage_nybbles+1

;Now, don't switch to the next colimage:
;  ; Show colimage0
;  lda #>colimage0
;  sta colimage_poi_even_even+1
;  sta colimage_poi_even_odd+1
;  sta colimage_poi_odd_even+1
;  sta colimage_poi_odd_odd+1

  lda #1
  sta do_black_colimage+1

  lda #$fe
  sta direction + 1
  lda #$f6
  sta desired_noise_level

;Now just wait until the red karate woman has faded away:

wait_until_sprite_image_0_is_visible6:
  lda sprite_map_no+1
  bne wait_until_sprite_image_0_is_visible6
;Sprite image just disappeared.


  ;When we come here everything is black.


  ; The rotating chars in textrotator are $8000-$c000


  ; First thing is to switch back into the ghostbyte scroller. Move IRQ to $e000-$fff7
  ; Loading $0400-$0800 is safe as well, that's unused memory.
  ; Then, copy some important pointers into $0400-$07ff (where do_ghostscroller_trans is, for instance)
  ; Then, jump to $0400, and let textrotator load $2000-$6000 + $6400-$cfff. (don't overload the ghostbytescroller sprites or screen)


  lda #1
  sta start_transition_into_textrotator+1

;  ; Let's load the init routine for textrotator into $c100-$d000:
;!ifdef release {
;  ;load textrotator init $c100-$d000
;  jsr link_load_next_comp
;  ;jump to $c100:
;}
hard_exit:
  jmp link_exit   ;$c100



desired_task_line = 112

ever_task:
  ;We may interrupt ourself so, we need to store registers on the stack:
  pha
  txa
  pha
  tya
  pha

run_another_task:

  ;lda #1
  ;sta $d020
  jsr copy_colimage_to_d800
  ;lda #2
  ;sta $d020

  ; The ever_task may interrupt itself, so the least visually important
  ; stuff goes last:

  lda desired_noise_level
  clc
direction:
  adc #$01
  sta desired_noise_level
  bne nobounce1
  ldx #$01
  stx direction+1
  ;Time to swap the sprite contents, if we'd like to:
  ldx #146
  stx spr_xdest_msb+1
  ldx #$e7
  stx spr_xpos_msb+1
  ldx #0
  stx spr_xspd_lsb+1
  ldx #0
  stx spr_xspd_msb+1
  ldx #75
  stx spr_ydest_msb+1
  ldx #75
  stx spr_ypos_msb+1
  ldx #$00
  stx spr_yspd_lsb+1
  ldx #$fe
  stx spr_yspd_msb+1

  ldy #(sprites-$4000) / $40
sprite_map_no:
  lda #0
  eor #1
  sta sprite_map_no+1
  beq use_sprmap0
  ldy #(sprites2-$4000) / $40
use_sprmap0:
  tya
  clc
  adc #4
  sta spritepoi_0+1
  clc
  adc #8
  sta spritepoi_1+1
  clc
  adc #8
  sta spritepoi_2+1
  clc
  adc #8
  sta spritepoi_3+1
  clc
  adc #8
  sta spritepoi_4+1
  clc
  adc #8
  sta spritepoi_5+1
  clc
  adc #8
  sta spritepoi_6+1

nobounce1:
  cmp #$f8
  bne nobounce
  ;Time to swap the colscreen contents, if we want to:
  lda #$ff
  sta direction+1
  lda #0
  sta colimage_xpos_lsb+1
  lda #0
  sta colimage_xpos_msb+1
  inc toggle_colimage_nybbles+1
nobounce:

; Check if we have another task waiting in line to be done already:
  dec task_running
  beq dont_run_another_task
  jmp run_another_task
dont_run_another_task:

  ;We may interrupt ourself so, we need to grab registers from the stack:
  pla
  tay
  pla
  tax
  pla
  rti


irq_0:
  sta save_a0+1
  stx save_x0+1
  sty save_y0+1

  ; Flag that we should do a ever_task this frame somewhere
  ; This can be triggered in any of the irq_1 ... irq_7 below.
  lda #1
  sta task_pending

  ;Check if we're doing any beats this frame:
beat_delay:
  ldx #$18
  dex
  stx beat_delay+1
  beq yes_new_beat
  jmp no_new_beat
yes_new_beat:
  ldx #$18
  stx beat_delay+1
do_beat:

  ldy #6
skip_d020_beat:
  ldx #0
  dex
  stx skip_d020_beat+1
  txa
  and #$1
  bne no_d020_beat_this_time
  ; This will start the $d020 beat
  ldy #3
no_d020_beat_this_time
  sty beat_cou_d020+1


skip_c64reset:
  ldx #8
  dex
  stx skip_c64reset+1
  txa
  and #$7
  beq c64reset_this_time
  jmp no_c64reset_this_time
c64reset_this_time
  ; This will start the "turbo tape 64 / turbo 250 / COPY 190 / Action Replay 6" beat:
  ; $05 = $8000: TURBO TAPE 64 screen. Black background, all chars green:
  ; $15 = $8400: MrZ Turbo 250:           $d020 = $e   $d021 = $6    $d800 = $e
  ; $25 = $8800: COPY 190 screen. $d020=1, $d021=1, Color #6 at top $d800-$d9bb, Color #8 at bottom. $d9bc-
  ; $35 = $8c00: Action replay 6: d020=1 d021=1,   $d800 = 0 and 2
  ; $45 = $9000: Back to nature: d020=3 d021=0,   colours: copy from back_to_nature_cols:

  lda #2
  sta beat_cou_c64reset+1
  lda #$01
  sta $dd00
  lda #0
  sta $d015
flash_screen_no:
  lda #$15   ;screen at $8000, chars at $9000    $d018 is #$15 normally
  clc
  adc #$10
  cmp #$45
  bne no_jump_to_back_to_nature
  lda #$85
no_jump_to_back_to_nature:
  cmp #$95
  bne no_reset_it
  lda #$05
no_reset_it:
  sta flash_screen_no+1
  sta $d018
  ldx #$1b
  stx $d011
  ldx #$c8
  stx $d016
  ldx #$6
  stx $d021
  ldx #$e
  stx $d020
  cmp #$35
  bne this_is_not_ar6
this_is_ar6:
  lda #1
  sta $d020
  sta $d021
  lda #0
  ; $35 = $8c00: Action replay 6: d020=1 d021=1,   $d800 = 0 and 2  $d8cf - $da29 = 2 
  ldx #0
fillcol0ar:
  sta $d800,x
  inx
  cpx #$cf
  bne fillcol0ar
  ldx #0
  lda #2
fillcol1ar:
  sta $d8cf,x
  inx
  bne fillcol1ar
fillcol2ar:
  sta $d9cf,x
  inx
  cpx #$29 + $31
  bne fillcol2ar
  ldx #0
  lda #0
fillcol3ar:
  sta $da29,x
  inx
  bne fillcol3ar
fillcol4ar:
  sta $db29,x
  inx
  cpx #$e8 - $29
  bne fillcol4ar
  jmp end_irq_0
this_is_not_ar6:
  cmp #$25
  bne this_is_not_copy190
this_is_copy190:
  lda #1
  sta $d020
  sta $d021
  lda #6
  ; $25 = $8800: COPY 190 screen. $d020=1, $d021=1, Color #6 at top $d800-$d9bb, Color #8 at bottom. $d9bc-
  ldx #0
fillcol0c190:
  sta $d800,x
  inx
  bne fillcol0c190
fillcol1c190:
  sta $d900,x
  inx
  cpx #$bb
  bne fillcol1c190
  lda #8
fillcol2c190:
  sta $d900,x
  inx
  bne fillcol2c190
fillcol3c190:
  sta $da00,x
  inx
  bne fillcol3c190
fillcol4c190:
  sta $db00,x
  inx
  bne fillcol4c190
  jmp end_irq_0
this_is_not_copy190:
  cmp #$15
  bne this_is_not_t250
this_is_t250:
  lda #$6
  sta $d021
  lda #$e
  sta $d020
  jmp same_colour_everywhere
this_is_not_t250:
  cmp #$b5
  bne this_is_turbo_tape
this_is_back_to_nature:
  lda #0
  sta $d021
  lda #3
  sta $d020
; Slightly optimized to run in one frame:
  lda #3
  ldx #$27
fillcol0bn:
  lda back_to_nature_cols,x
  sta $d828,x
  dex
  bpl fillcol0bn
  ldx #4*40
fillcol22bn:
  lda back_to_nature_cols,x
  sta $d800,x
  inx
  bne fillcol22bn
fillcol1bn:
  lda back_to_nature_cols+$100,x
  sta $d900,x
  inx
  bne fillcol1bn
fillcol2bn:
  lda back_to_nature_cols+$200,x
  sta $da00,x
  inx
  bne fillcol2bn
fillcol3bn:
  lda back_to_nature_cols+$300,x
  sta $db00,x
  inx
  bne fillcol3bn
  jmp end_irq_0
this_is_turbo_tape:
  lda #$0
  sta $d021
  sta $d020
  lda #$5
same_colour_everywhere:
  ldx #0
fillcol0:
  sta $d800,x
  inx
  bne fillcol0
fillcol1:
  sta $d900,x
  inx
  bne fillcol1
fillcol2:
  sta $da00,x
  inx
  bne fillcol2
fillcol3:
  sta $db00,x
  inx
  bne fillcol3
  jmp end_irq_0
no_c64reset_this_time:
  txa
  and #$7
  cmp #5
  bne no_screen_col_yup
  jmp screen_col_yup

no_screen_col_yup:
  txa
  and #$7
spritemat_d027_1:
  ldy #$8
  cmp #2
  bne no_sprcol_flash
spritemat_d027_2:
  ldy #$a
no_sprcol_flash:
  sty first_sprcol+1

  txa
  and #$7
  ldy #0
  cmp #6
  bne no_sprjumpy
  lda spr_yspd_msb+1
  bmi lets_add
  sec
  sbc #2
lets_add:
  clc
  adc #1 
  sta spr_yspd_msb+1
no_sprjumpy:

  txa
  and #$7
  ldy #0
  cmp #2
  bne no_sprjumpx
  lda spr_xspd_msb+1
  bmi lets_addx
  sec
  sbc #4
lets_addx:
  clc
  adc #2 
  sta spr_xspd_msb+1
no_sprjumpx:

  txa
  and #$7
  ldy #0
  cmp #4
  bne no_sprdist1
  lda #$15
  sta spr_xdist_01+1
  sta spr_xdist_12+1
  sta spr_xdist_23+1
  sta spr_xdist_34+1
  sta spr_xdist_45+1
  sta spr_xdist_56+1
  sta spr_xdist_67+1
no_sprdist1:

  txa
  and #$7
  ldy #0
  cmp #3
  bne no_sprdist2
  lda #$17
  sta spr_xdist_01+1
  sta spr_xdist_12+1
  sta spr_xdist_23+1
  sta spr_xdist_34+1
  sta spr_xdist_45+1
  sta spr_xdist_56+1
  sta spr_xdist_67+1
no_sprdist2:

  txa
  and #$7
  ldy #0
  cmp #2
  bne no_sprdist3
  lda #$18
  sta spr_xdist_01+1
  sta spr_xdist_12+1
  sta spr_xdist_23+1
  sta spr_xdist_34+1
  sta spr_xdist_45+1
  sta spr_xdist_56+1
  sta spr_xdist_67+1
no_sprdist3:


no_new_beat:

beat_cou_c64reset:
  ldx #0
  dex
  bmi no_c64reset_beat
  stx beat_cou_c64reset+1
  bne no_reset_of_c64reset
  ;make sure that all $d800 gets written next frame:
  lda #$ff
  sta last_ypos+1
  sta last_xpos+1
screen_col_yup:
  ;this is where we go from x64 reset screen to normal part again:

screen_col_no:
  ldy #0
  lda screen_col_sequence,y
  sta screen_col+1
  iny
  sty screen_col_no+1
  jmp beat_cou_d020
no_reset_of_c64reset:
  jmp end_irq_0
no_c64reset_beat:

beat_cou_d020:
  ldx #0
  dex
  bmi beat_done
  stx beat_cou_d020+1
  lda d020_beat_table,x
  sta $d020

beat_done:

screen_col:
  lda #2
  sta $d021

;Scroll sprite colours:
  lda $d02d
  sta $d02e
  lda $d02c
  sta $d02d
  lda $d02b
  sta $d02c
  lda $d02a
  sta $d02b
  lda $d029
  sta $d02a
  lda $d028
  sta $d029
  lda $d027
  sta $d028
first_sprcol:
  lda #8
  sta $d029
  sta $d02a
  sta $d02b
  sta $d02d
  sta $d02e
stay_a_while_spr5:
  nop
  nop
  sta $d02c
stay_a_while_spr01:
  lda #$f
;  nop
;  nop
  sta $d027
  sta $d028
  lda #$f
karate_spr2:
  sta $d029


spritemat_d025:
  lda #$1
  sta $d025
spritemat_d026:
  lda #$0
  sta $d026

  lda #$02   ;bank $4000-$7fff
  sta $dd00
desired_d011:
  lda #$1b
  sta $d011
desired_d016:
  lda #$90
  sta $d016

spr_xpos_min = $18
spr_xpos_max = $e7

  ; sprxpos is valid from $18 (far left) to $e7 (far right).
;dampen the xspd
damp = 2
  lda spr_xspd_msb+1
  bmi damp_xminus
  lda spr_xspd_lsb+1
  sec
  sbc #damp
  sta spr_xspd_lsb+1
  lda spr_xspd_msb+1
  sbc #0
  sta spr_xspd_msb+1
  bcs damp_xdone
  lda #0
  sta spr_xspd_msb+1
  sta spr_xspd_lsb+1
  jmp damp_xdone
damp_xminus:
  lda spr_xspd_lsb+1
  clc
  adc #damp
  sta spr_xspd_lsb+1
  lda spr_xspd_msb+1
  adc #0
  sta spr_xspd_msb+1
  bcc damp_xdone
  lda #0
  sta spr_xspd_msb+1
  sta spr_xspd_lsb+1
damp_xdone:

spr_xdest_msb:
  lda #146
spr_xpos_msb:
  sbc #$e7
  cmp #$80
  ror
  cmp #$80
  ror
  sta spr_xacc_lsb+1
  ldx #0
  asl
  bcc no_minus
  ldx #$ff
no_minus:
  stx spr_xacc_msb+1

spr_xacc_lsb:
  lda #0
  clc
spr_xspd_lsb:
  adc #0
  sta spr_xspd_lsb+1
spr_xacc_msb:
  lda #0
spr_xspd_msb:
  adc #0
  sta spr_xspd_msb+1

spr_xpos_lsb:
  lda #0
  clc
  adc spr_xspd_lsb+1
  sta spr_xpos_lsb+1
  lda spr_xpos_msb+1
  adc spr_xspd_msb+1
  sta spr_xpos_msb+1

; check if we should bounce at left edge:
  lda #spr_xpos_min
  cmp spr_xpos_msb+1
  bcc no_bounce_at_left
  sta spr_xpos_msb+1
  lda spr_xspd_msb+1
  bpl no_bounce_at_left
  lda #0
  sec
  sbc spr_xspd_lsb+1
  sta spr_xspd_lsb+1
  lda #0
  sbc spr_xspd_msb+1
  sta spr_xspd_msb+1
no_bounce_at_left:

; check if we should bounce at right edge:
  lda #spr_xpos_max
  cmp spr_xpos_msb+1
  bcs no_bounce_at_right
  sta spr_xpos_msb+1
  lda spr_xspd_msb+1
  bmi no_bounce_at_right
  lda #0
  sec
  sbc spr_xspd_lsb+1
  sta spr_xspd_lsb+1
  lda #0
  sbc spr_xspd_msb+1
  sta spr_xspd_msb+1
no_bounce_at_right:

spr_ypos_min = $36
spr_ypos_max = $64

  ; sprypos is valid from $06 (upper) to $9c (lower).
;dampen the yspd
  lda spr_yspd_msb+1
  bmi damp_yminus
  lda spr_yspd_lsb+1
  sec
  sbc #damp
  sta spr_yspd_lsb+1
  lda spr_yspd_msb+1
  sbc #0
  sta spr_yspd_msb+1
  bcs damp_ydone
  lda #0
  sta spr_yspd_msb+1
  sta spr_yspd_lsb+1
  jmp damp_ydone
damp_yminus:
  lda spr_yspd_lsb+1
  clc
  adc #damp
  sta spr_yspd_lsb+1
  lda spr_yspd_msb+1
  adc #0
  sta spr_yspd_msb+1
  bcc damp_ydone
  lda #0
  sta spr_yspd_msb+1
  sta spr_yspd_lsb+1
damp_ydone:

spr_ydest_msb:
  lda #75
spr_ypos_msb:
  sbc #75
  cmp #$80
  ror
  cmp #$80
  ror
  sta spr_yacc_lsb+1
  ldx #0
  asl
  bcc no_minusy
  ldx #$ff
no_minusy:
  stx spr_yacc_msb+1

spr_yacc_lsb:
  lda #$80
  clc
spr_yspd_lsb:
  adc #$00
  sta spr_yspd_lsb+1
spr_yacc_msb:
  lda #$0
spr_yspd_msb:
  adc #$fe
  sta spr_yspd_msb+1

spr_ypos_lsb:
  lda #0
  clc
  adc spr_yspd_lsb+1
  sta spr_ypos_lsb+1
  lda spr_ypos_msb+1
  adc spr_yspd_msb+1
  sta spr_ypos_msb+1

; check if we should bounce at upper edge:
  lda #spr_ypos_min
  cmp spr_ypos_msb+1
  bcc no_bounce_at_upper
  sta spr_ypos_msb+1
  lda spr_yspd_msb+1
  bpl no_bounce_at_upper
  lda #0
  sec
  sbc spr_yspd_lsb+1
  sta spr_yspd_lsb+1
  lda #0
  sbc spr_yspd_msb+1
  sta spr_yspd_msb+1
no_bounce_at_upper:

; check if we should bounce at lower edge:
  lda #spr_ypos_max
  cmp spr_ypos_msb+1
  bcs no_bounce_at_lower
  sta spr_ypos_msb+1
  lda spr_yspd_msb+1
  bmi no_bounce_at_lower
  lda #0
  sec
  sbc spr_yspd_lsb+1
  sta spr_yspd_lsb+1
  lda #0
  sbc spr_yspd_msb+1
  sta spr_yspd_msb+1
no_bounce_at_lower:


;togg:
;  lda #0
;  eor #1
;  sta togg+1
;  bne do_movs
;  jmp no_movs
;do_movs:
;
;  ; sprxpos is valid from $e9 (far left) to $b7 (far right).
;  lda sprxpos+1
;  clc
;directionxp:
;  adc #1
;  sta sprxpos+1
;  cmp #$e9
;  bne nobounce1xx
;  ldx #$01
;  stx directionxp+1
;nobounce1xx:
;  cmp #$b7
;  bne nobouncexx
;  ldx #$ff
;  stx directionxp+1
;nobouncexx:
;
;  ; sprypos is valid from $06 (upper) to $9c (lower).
;  lda sprypos+1
;  clc
;directionyp:
;  adc #1
;  sta sprypos+1
;  cmp #6
;  bne nobounce1yy
;  ldx #$01
;  stx directionyp+1
;nobounce1yy:
;  cmp #$9c
;  bne nobounceyy
;  ldx #$ff
;  stx directionyp+1
;nobounceyy:

  lda spr_ypos_msb+1
  clc
  adc #21
  sta sprypos1+1
  clc
  adc #21
  sta sprypos2+1
  clc
  adc #21
  sta sprypos3+1
  clc
  adc #21
  sta sprypos4+1
  clc
  adc #21
  sta sprypos5+1
  clc
  adc #21
  sta sprypos6+1

  lda spr_ypos_msb+1
  clc
  adc #$12
  sta irqpos1+1
  clc
  adc #20
  sta irqpos2+1
  clc
  adc #20
  sta irqpos3+1
  clc
  adc #20
  sta irqpos4+1
  clc
  adc #20
  sta irqpos5+1
  ldx #$0
  clc
  adc #20
  sta irqpos6+1
  bcc no_irqpos6_msb
  ldx #$80
no_irqpos6_msb:
  stx irqpos6_msb+1
  clc
  adc #20
  sta irqpos7+1  ; This is where we turn off the sprites and put them all at x-pos 0
  bcc no_irqpos7_msb
  ldx #$80
no_irqpos7_msb:
  stx irqpos7_msb+1

no_movs:

  lda spr_ypos_msb+1
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f

screen_no:
  lda #$80    ;screen at $6000, charset at $4000
  clc
  adc #$10
  cmp #$e0    ;is screen=$7800?
  bne do_not_discard_6000
  lda #$90    ;screen at $6400
do_not_discard_6000:
  ora #$80
  sta screen_no+1
  sta $d018
  ; need to calculate the screenX_msb from $d018:
  lsr
  lsr
  ora #$43  ;msb of the bank address
  sta scr_msb_00+2
  sta scr_msb_01+2
  sta scr_msb_02+2
  sta scr_msb_03+2
  sta scr_msb_04+2
  sta scr_msb_05+2
  sta scr_msb_06+2
  sta scr_msb_07+2
  sta scr_msb_10+2
  sta scr_msb_11+2
  sta scr_msb_12+2
  sta scr_msb_13+2
  sta scr_msb_14+2
  sta scr_msb_15+2
  sta scr_msb_16+2
  sta scr_msb_17+2
  sta scr_msb_20+2
  sta scr_msb_21+2
  sta scr_msb_22+2
  sta scr_msb_23+2
  sta scr_msb_24+2
  sta scr_msb_25+2
  sta scr_msb_26+2
  sta scr_msb_27+2
  sta scr_msb_30+2
  sta scr_msb_31+2
  sta scr_msb_32+2
  sta scr_msb_33+2
  sta scr_msb_34+2
  sta scr_msb_35+2
  sta scr_msb_36+2
  sta scr_msb_37+2
  sta scr_msb_40+2
  sta scr_msb_41+2
  sta scr_msb_42+2
  sta scr_msb_43+2
  sta scr_msb_44+2
  sta scr_msb_45+2
  sta scr_msb_46+2
  sta scr_msb_47+2
  sta scr_msb_50+2
  sta scr_msb_51+2
  sta scr_msb_52+2
  sta scr_msb_53+2
  sta scr_msb_54+2
  sta scr_msb_55+2
  sta scr_msb_56+2
  sta scr_msb_57+2
  sta scr_msb_60+2
  sta scr_msb_61+2
  sta scr_msb_62+2
  sta scr_msb_63+2
  sta scr_msb_64+2
  sta scr_msb_65+2
  sta scr_msb_66+2
  sta scr_msb_67+2

first_sprite_no = (sprites-$4000) / $40

spritepoi_0:
  ldx #first_sprite_no + $04
  lda #$fb
scr_msb_00:  sax screen0+$3f8
scr_msb_01:  stx screen0+$3fc
  inx
scr_msb_02:  sax screen0+$3f9
scr_msb_03:  stx screen0+$3fd
  inx
scr_msb_04:  sax screen0+$3fa
scr_msb_05:  stx screen0+$3fe
  inx
scr_msb_06:  sax screen0+$3fb
scr_msb_07:  stx screen0+$3ff

;set sprite x pos
; y is what goes into $d010
  ldy #0
  lda spr_xpos_msb+1
  sta $d004
  sec
spr_xdist_12:
  sbc #$18
  sta $d002
  bcs no1
  ldy #$03
no1:
  sec
spr_xdist_01:
  sbc #$18
  sta $d000
  bcs no0
  ldy #$01
no0:
  sty $d010
  ldy #0
  lda spr_xpos_msb+1
  clc
spr_xdist_23:
  adc #$18
  sta $d006
  clc
spr_xdist_34:
  adc #$18
  sta $d008
  bcc no4
  ldy #$f0
no4:
  clc
spr_xdist_45:
  adc #$18
  sta $d00a
  bcc no5
  ldy #$e0
no5:
  clc
spr_xdist_56:
  adc #$18
  sta $d00c
  bcc no6
  ldy #$c0
no6:
  clc
spr_xdist_67:
  adc #$18
  sta $d00e
  bcc no7
  ldy #$80
no7:
  tya
  ora $d010
  sta $d010

  lda #$ff
  sta $d015

  lda #$36
  sta $d012

  lda $d016
  and #7
  sta irq_0b_d016+1
  lda $d011
  and #7
  ora #$18
  sta irq_0b_d011+1
  and #$7
  cmp #6
  bne no_badline0b
yes_badline0b:
  lda #<irq_0b_bad
  sta $fffe
  lda #>irq_0b_bad
  sta $ffff
  jmp end_irq_0
no_badline0b:
  lda #<irq_0b
  sta $fffe
  lda #>irq_0b
  sta $ffff

end_irq_0:
  asl $d019

  cli
!ifdef release {
  jsr link_music_play
} else {
  jsr music+3
}

save_a0:
  lda #0
save_x0:
  ldx #0
save_y0:
  ldy #0
  rti


screen_col_sequence:
;Initial colour is 2:
;  !byte 2  ;Horizontal rasters -> You need to
  !byte $3
  !byte $4
  !byte $b  ;Peak of "You just need to" (mc_cols=1,0,8)
  !byte $6
  !byte $8  ;Almost not visible: "INSERT COIN/Robotron" peak
  !byte $2
  !byte $9
  !byte $6  ;Peak of "Stay a while" Hunter (mc_cols=$0,$4,$a)
  !byte $c
  !byte $e
  !byte $9  ;Almost not visible: "Impossible Mission" peak
  !byte $4
  !byte $2  ;Peak of "Stay Forever"
  !byte $5
  !byte $7  ;Almost not visible: "Bruce Lee" peak
  !byte $3
  !byte $4
  !byte $b  ;Peak of To get to the  (mc_cols=0,2,$a)
  !byte $b
  !byte $b
  !byte $b
  !byte $b
  !byte $b
  !byte $b
  !byte $b


irq_0b:
;Waste a couple of cycles since we're not on a badline:
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
  nop
  bit $00
irq_0b_bad:
  sta save_a0b+1
irq_0b_d011:
  lda #0
  sta $d011
irq_0b_d016:
  lda #$00
  sta $d016
irqpos1:
  lda #$5c
  sta $d012
  lda #<irq_1
  sta $fffe
  lda #>irq_1
  sta $ffff
  asl $d019
save_a0b:
  lda #0
  rti

irq_1:
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
  stx save_x1+1
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
  asl $d019
spritepoi_1:
  ldx #first_sprite_no + $0c
  lda #$fb
;set sprite pointers:
scr_msb_10:  sax screen0+$3f8
scr_msb_11:  stx screen0+$3fc
  inx
scr_msb_12:  sax screen0+$3f9
scr_msb_13:  stx screen0+$3fd
  inx
scr_msb_14:  sax screen0+$3fa
scr_msb_15:  stx screen0+$3fe
  inx
scr_msb_16:  sax screen0+$3fb
scr_msb_17:  stx screen0+$3ff

  lda #<irq_2
  sta $fffe
  lda #>irq_2
  sta $ffff
  pla
;WARNING - not allowed to change value of A below:

; Check if we should trigger the ever_task when this irq is done.
; We want the ever_task to be triggered at the desired_task_line
  ldx task_pending
  beq notask_1
  ldx $d012
  cpx #desired_task_line
  bcc notask_1
;Starting task after this irq:
  ; Saying that we don't need to trigger any more task this frame:
  dec task_pending
  inc task_running
  ; If task is already running, no need to trigger it here:
  ldx task_running
  cpx #1
  bne notask_1
  tax
  lda #>ever_task
  pha
  lda #<ever_task
  pha
  lda #$00   ;flags
  pha
  txa
notask_1:
save_x1:
  ldx #0
  rti

irq_2:
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
  stx save_x2+1
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
  asl $d019
spritepoi_2:
  ldx #first_sprite_no + $14
  lda #$fb
scr_msb_20:  sax screen0+$3f8
scr_msb_21:  stx screen0+$3fc
  inx
scr_msb_22:  sax screen0+$3f9
scr_msb_23:  stx screen0+$3fd
  inx
scr_msb_24:  sax screen0+$3fa
scr_msb_25:  stx screen0+$3fe
  inx
scr_msb_26:  sax screen0+$3fb
scr_msb_27:  stx screen0+$3ff

  lda #<irq_3
  sta $fffe
  lda #>irq_3
  sta $ffff
  pla
;WARNING - not allowed to change value of A below:

; Check if we should trigger the ever_task when this irq is done.
; We want the ever_task to be triggered at the desired_task_line
  ldx task_pending
  beq notask_2
  ldx $d012
  cpx #desired_task_line
  bcc notask_2
;Starting task after this irq:
  ; Saying that we don't need to trigger any more task this frame:
  dec task_pending
  inc task_running
  ; If task is already running, no need to trigger it here:
  ldx task_running
  cpx #1
  bne notask_2
  tax
  lda #>ever_task
  pha
  lda #<ever_task
  pha
  lda #$00   ;flags
  pha
  txa
notask_2:
save_x2:
  ldx #0
  rti

irq_3:
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
  stx save_x3+1
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
  asl $d019
spritepoi_3:
  ldx #first_sprite_no + $1c
  lda #$fb
scr_msb_30:  sax screen0+$3f8
scr_msb_31:  stx screen0+$3fc
  inx
scr_msb_32:  sax screen0+$3f9
scr_msb_33:  stx screen0+$3fd
  inx
scr_msb_34:  sax screen0+$3fa
scr_msb_35:  stx screen0+$3fe
  inx
scr_msb_36:  sax screen0+$3fb
scr_msb_37:  stx screen0+$3ff

  lda #<irq_4
  sta $fffe
  lda #>irq_4
  sta $ffff
  pla
;WARNING - not allowed to change value of A below:

; Check if we should trigger the ever_task when this irq is done.
; We want the ever_task to be triggered at the desired_task_line
  ldx task_pending
  beq notask_3
  ldx $d012
  cpx #desired_task_line
  bcc notask_3
;Starting task after this irq:
  ; Saying that we don't need to trigger any more task this frame:
  dec task_pending
  inc task_running
  ; If task is already running, no need to trigger it here:
  ldx task_running
  cpx #1
  bne notask_3
  tax
  lda #>ever_task
  pha
  lda #<ever_task
  pha
  lda #$00   ;flags
  pha
  txa
notask_3:
save_x3:
  ldx #0
  rti

irq_4:
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
  stx save_x4+1
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
  asl $d019
spritepoi_4:
  ldx #first_sprite_no + $24
  lda #$fb
scr_msb_40:  sax screen0+$3f8
scr_msb_41:  stx screen0+$3fc
  inx
scr_msb_42:  sax screen0+$3f9
scr_msb_43:  stx screen0+$3fd
  inx
scr_msb_44:  sax screen0+$3fa
scr_msb_45:  stx screen0+$3fe
  inx
scr_msb_46:  sax screen0+$3fb
scr_msb_47:  stx screen0+$3ff

  lda #<irq_5
  sta $fffe
  lda #>irq_5
  sta $ffff
  pla
;WARNING - not allowed to change value of A below:

; Check if we should trigger the ever_task when this irq is done.
; We want the ever_task to be triggered at the desired_task_line
  ldx task_pending
  beq notask_4
  ldx $d012
  cpx #desired_task_line
  bcc notask_4
;Starting task after this irq:
  ; Saying that we don't need to trigger any more task this frame:
  dec task_pending
  inc task_running
  ; If task is already running, no need to trigger it here:
  ldx task_running
  cpx #1
  bne notask_4
  tax
  lda #>ever_task
  pha
  lda #<ever_task
  pha
  lda #$00   ;flags
  pha
  txa
notask_4:
save_x4:
  ldx #0
  rti

irq_5:
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
  stx save_x5+1
sprypos5:
  lda #$b3
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f
irqpos6:
  lda #$c0
  sta $d012
  asl $d019
spritepoi_5:
  ldx #first_sprite_no + $2c
  lda #$fb
scr_msb_50:  sax screen0+$3f8
scr_msb_51:  stx screen0+$3fc
  inx
scr_msb_52:  sax screen0+$3f9
scr_msb_53:  stx screen0+$3fd
  inx
scr_msb_54:  sax screen0+$3fa
scr_msb_55:  stx screen0+$3fe
  inx
scr_msb_56:  sax screen0+$3fb
scr_msb_57:  stx screen0+$3ff

  lda #<irq_6
  sta $fffe
  lda #>irq_6
  sta $ffff
  lda $d011
irqpos6_msb:
  ora #$00
  sta $d011
  pla
;WARNING - not allowed to change value of A below:

; Check if we should trigger the ever_task when this irq is done.
; We want the ever_task to be triggered at the desired_task_line
  ldx task_pending
  beq notask_5
  ldx $d012
  cpx #desired_task_line
  bcc notask_5
;Starting task after this irq:
  ; Saying that we don't need to trigger any more task this frame:
  dec task_pending
  inc task_running
  ; If task is already running, no need to trigger it here:
  ldx task_running
  cpx #1
  bne notask_5
  tax
  lda #>ever_task
  pha
  lda #<ever_task
  pha
  lda #$00   ;flags
  pha
  txa
notask_5:
save_x5:
  ldx #0
  rti

irq_6:
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
  stx save_x6+1
sprypos6:
  lda #$c8
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f
irqpos7:
  lda #$d4
  sta $d012
  asl $d019
spritepoi_6:
  ldx #first_sprite_no + $34
  lda #$fb
scr_msb_60:  sax screen0+$3f8
scr_msb_61:  stx screen0+$3fc
  inx
scr_msb_62:  sax screen0+$3f9
scr_msb_63:  stx screen0+$3fd
  inx
scr_msb_64:  sax screen0+$3fa
scr_msb_65:  stx screen0+$3fe
  inx
scr_msb_66:  sax screen0+$3fb
scr_msb_67:  stx screen0+$3ff

  lda $d011
irqpos7_msb:
  ora #$00
  sta $d011
  lda #<irq_7
  sta $fffe
  lda #>irq_7
  sta $ffff
  pla
;WARNING - not allowed to change value of A below:

; Check if we should trigger the ever_task when this irq is done.
; We want the ever_task to be triggered at the desired_task_line
  ldx task_pending
  beq notask_6
  ldx $d012
  cpx #desired_task_line
  bcc notask_6
;Starting task after this irq:
  ; Saying that we don't need to trigger any more task this frame:
  dec task_pending
  inc task_running
  ; If task is already running, no need to trigger it here:
  ldx task_running
  cpx #1
  bne notask_6
  tax
  lda #>ever_task
  pha
  lda #<ever_task
  pha
  lda #$00   ;flags
  pha
  txa
notask_6:
save_x6:
  ldx #0
  rti

irq_7:
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
  stx save_x7+1
  sty save_y7+1
; Turn off the sprites to make sure that garbage
;in the lower part of the sprites isn't seen:
  lda #$00
;  sta $d015
  sta $d010
  sta $d000
  sta $d002
  sta $d004
  sta $d006
  sta $d008
  sta $d00a
  sta $d00c
  sta $d00e

  lda #$f7
  sta $d012
  asl $d019
  lda $d011
  and #$7f
  sta $d011
  and #$7
  cmp #7
  bne no_badline
yes_badline:
  lda #<irq_7b_bad
  sta $fffe
  lda #>irq_7b_bad
  sta $ffff
  jmp done_setting_irq
no_badline:
  lda #<irq_7b
  sta $fffe
  lda #>irq_7b
  sta $ffff
done_setting_irq:

  pla
;WARNING - not allowed to change value of A below:

; Check if we should trigger the ever_task when this irq is done.
; We want the ever_task to be triggered at the desired_task_line.
; But this is the last irq in this frame, so trigger it if it's not
; triggered already, regardless of $d012
  ldx task_pending
  beq notask_7
;Starting task after this irq:
  ; Saying that we don't need to trigger any more task this frame:
  dec task_pending
  inc task_running
  ; If task is already running, no need to trigger it here:
  ldx task_running
  cpx #1
  bne notask_7
  tax
  lda #>ever_task
  pha
  lda #<ever_task
  pha
  lda #$00   ;flags
  pha
  txa
notask_7:

end_irq:
save_x7:
  ldx #0
save_y7:
  ldy #0
  rti

irq_7b:
;Waste a couple of cycles since we're not on a badline:
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
  bit $00

irq_7b_bad:
  sta save_a7b+1
;; setup illegal graphics mode, to make pixels all black:
  lda $d011
  and #7
  ora #$c8      ;ECM mode
  sta $d011
;  lda $d016
;  ora #$10      ;multicolor mode
  lda #$10
  sta $d016
  lda #$00
  sta $d012
  sta $d021
  lda #<irq_8
  sta $fffe
  lda #>irq_8
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
  lda $d011
  and #7
  ora #$c0
  sta $d011
  lda #$fe
  sta $d015
  lda #$ff
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

save_a7b:
  lda #0
  rti


irq_8:
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
  stx save_x8+1
  sty save_y8+1

  ;We will need to wait here until they are finished a couple of lines further down.
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  lda desired_ghostd016+1
  and #7
  ora #$c0
  sta $d016
  ;stop doing ecm mode:
  lda $d011
  and #7
  ora #$10
  sta $d011

  lda #$10
  sta $d018 ;screen at $4400
;  lda #0
  sta $d026
  bit $00
ghost_d010:
  lda #$c0
  sta $d010
ghost_d00e:
  lda #$87
  sta $d00e

  ldx #20
ghostloop:
  lda ghostcols,x
  ldy ghostlist,x
  sta $d025
  sty $7fff
  sta $d021
  bit $00
  ; Now, copy one char (or, rather, write one byte into one of the three sets).
  ; This byte is off screen and will be scrolled into the screen "soon".
ghost_msb_srcpoi:
  lda char_46_nybble_0_msb,x   ;4
ghost_lsb_srcpoi:
  ora char_46_nybble_0,x       ;4
  ldy table_of_x3,x            ;4
  sta (ghost_destpoi),y        ;6
  dex
  bpl ghostloop

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

  ; Not x-expanded anymore:
  lda #0
  sta $d01d

  jsr do_ghostscroller

spritemat_d01c:
  lda #%11111000   ;For the first sprite mat, the three leftmost sprites are hires
  sta $d01c

start_transition_into_textrotator:
  lda #0
  beq no_transition

  ;Send the current scrolltext position to textrotator:
  lda ghost_lsb_srcpoi+1
  sta transfer_lsb_srcpoi
  lda ghost_lsb_srcpoi+2
  sta transfer_lsb_srcpoi+1
  lda ghost_msb_srcpoi+1
  sta transfer_msb_srcpoi
  lda ghost_msb_srcpoi+2
  sta transfer_msb_srcpoi+1
  lda sprite_sprite_offset+1
  sta transfer_sprite_sprite_offset
  lda sprite_set+1
  sta transfer_sprite_set
  lda plot_next_char+1
  sta transfer_plot_next_char
  lda nof_nybbles_left+1
  sta transfer_nof_nybbles_left


  ldy desired_ghostd016+1
; Yes it's hardcoded. Just live with it. It's in textrotator/main.s "setup_stuff_in_noisefader:"
  jsr $c106
  jmp yes_transition

no_transition:
  lda #$0
  sta $d012
  lda #<irq_0
  sta $fffe
  lda #>irq_0
  sta $ffff
yes_transition:
  asl $d019
save_y8:
  ldy #0
save_x8:
  ldx #0
  pla
  rti

;ghost_d002:
;  lda #0
;ghost_d004:
;  lda #0
;ghost_d006:
;  lda #0
;ghost_d008:
;  lda #0
;ghost_d00a:
;  lda #0
;ghost_d00c:
;  lda #0
;ghost_d00e:
;  lda #0
;ghost_d010:
;  lda #0
;ghost_lsb_srcpoi:
;  lda $1000
;ghost_msb_srcpoi:
;  lda $1000




; Copy from floyd_table into 16 chars:
desired_noise_level:
  !byte $00

copy_noise_into_chars:
  lda #>charset
  sta char_dest+2
  lda #<charset
  sta char_dest+1

;x is the char pixel row counter:
  ldx #$0

another_char:
  ldy #7

;Translate desired_noise_level into a pointer into floyd_table
  lda #0
  sta floyd_src+2
  lda desired_noise_level
  asl
  rol floyd_src+2
  asl
  rol floyd_src+2
  asl
  rol floyd_src+2
  asl
  rol floyd_src+2
  sta floyd_src+1

;add noise to the lsb:
seed:
  lda #$10
  beq doEor ;added this
  asl
  bcc noEor
doEor:
  eor #$1d
noEor:
  sta seed+1
  and #$3f
  clc
  adc floyd_src+1
  sta floyd_src+1

  lda floyd_src+2
  adc #>floyd_table
  sta floyd_src+2

copychar:
floyd_src:
  lda floyd_table+$800,y
char_dest:
  sta charset,x
  inx
  dey
  bpl copychar

  cpx #$80
  bne another_char
  rts


floyd_this_row_lsb: !byte 0,0,0,0,0,0,0,0,0,0,0,0,0
floyd_next_row_lsb: !byte 0,0,0,0,0,0,0,0,0,0,0,0,0
floyd_this_row_msb: !byte 0,0,0,0,0,0,0,0,0,0,0,0,0
floyd_next_row_msb: !byte 0,0,0,0,0,0,0,0,0,0,0,0,0
floyd_this_byte: !byte 0
quant_error_lsb: !byte 0
quant_error_msb: !byte 0
quant_error_1_lsb: !byte 0 ;quant_error * 1/16
quant_error_1_msb: !byte 0
quant_error_2_lsb: !byte 0 ;quant_error * 2/16
quant_error_2_msb: !byte 0
quant_error_3_lsb: !byte 0 ;quant_error * 3/16
quant_error_3_msb: !byte 0
quant_error_4_lsb: !byte 0 ;quant_error * 4/16
quant_error_4_msb: !byte 0
quant_error_5_lsb: !byte 0 ;quant_error * 5/16
quant_error_5_msb: !byte 0
quant_error_7_lsb: !byte 0 ;quant_error * 7/16
quant_error_7_msb: !byte 0

; A "white pixel" is $1000
; So all arithmetics are done using 4.12 fixed point calculations.

;https://en.wikipedia.org/wiki/Floyd%E2%80%93Steinberg_dithering
;for each y from top to bottom do
;    for each x from left to right do
;        oldpixel := pixels[x][y]
;        newpixel := find_closest_palette_color(oldpixel)
;        pixels[x][y] := newpixel
;        quant_error := oldpixel - newpixel
;        pixels[x + 1][y    ] := pixels[x + 1][y    ] + quant_error × 7 / 16
;        pixels[x - 1][y + 1] := pixels[x - 1][y + 1] + quant_error × 3 / 16
;        pixels[x    ][y + 1] := pixels[x    ][y + 1] + quant_error × 5 / 16
;        pixels[x + 1][y + 1] := pixels[x + 1][y + 1] + quant_error × 1 / 16


; The floyd table can also be done like this with imagemagick:
;magick -size 8x4096 -define gradient:angle=0 gradient:black-white gradient_grey.png
;convert gradient_grey.png -dither FloydSteinberg -remap pattern:gray50 gradient_bw.png
;...and then convert the png file to bytes.
;This image contains the most pixels "in the middle" of the image.

;So let's make a larger one, and crop it to avoid this:
;Use 16-bit gradient:
;magick -depth 16 -size 256x4096 -define gradient:angle=0 gradient:black-white gradient_grey.png
;convert gradient_grey.png -dither FloydSteinberg -remap pattern:gray50 gradient_bw.png
;convert gradient_bw.png -crop 8x4096+128+0 gradient_bw_cropped.png

;...and export as 1-bit raw:
;magick -depth 16 -size 256x4096 -define gradient:angle=0 gradient:black-white gradient_grey.png
;convert gradient_grey.png -dither FloydSteinberg -remap pattern:gray50 gradient_bw.png
;convert gradient_bw.png -crop 8x4096+128+0 gradient_bw_cropped.png
;magick gradient_bw_cropped.png -depth 1 -colorspace gray GRAY:gradient_bw_cropped.bin



;make_floyd_byte:
;  ldx #1  ;x is the horizontal pixel no. 1-8 is used. 0 is "spare memory", and 9 is also "spare memory"
;quantize_this_pixel:
;  lda floyd_this_row_msb,x
;  cmp #$10
;  bcc this_is_1
;  lda floyd_this_row_msb,x
;  sec
;  sbc #$10
;  sta floyd_this_row_msb,x
;  sec
;this_is_1:
;  lda floyd_this_byte
;  rol
;  sta floyd_this_byte
;;quant_error = floyd_this_row,x - resulting pixel.
;  lda floyd_this_row_lsb,x
;  sta quant_error_lsb
;  lda floyd_this_row_msb,x
;  sta quant_error_msb
;;create 1/16, 3/16, 5/16 and 7/16:
;
;  lda quant_error_msb
;  asl
;  ror quant_error_msb
;  ror quant_error_lsb
;  lda quant_error_msb
;  asl
;  ror quant_error_msb
;  ror quant_error_lsb
;;now divided by 4 = 4/16
;
;  lda quant_error_msb
;  sta quant_error_4_msb
;  lda quant_error_lsb
;  sta quant_error_4_lsb
;;4/16 is done
;
;  lda quant_error_msb
;  asl
;  ror quant_error_msb
;  ror quant_error_lsb
;; now divided by 8 = 2/16
;
;  lda quant_error_msb
;  sta quant_error_2_msb
;  lda quant_error_lsb
;  sta quant_error_2_lsb
;;2/16 and 4/16 are done
;
;  lda quant_error_msb
;  asl
;  ror quant_error_msb
;  ror quant_error_lsb
;; now divided by 16 = 1/16
;
;  lda quant_error_lsb
;  sta quant_error_1_lsb
;  clc
;  adc quant_error_2_lsb
;  sta quant_error_3_lsb
;  lda quant_error_msb
;  sta quant_error_1_msb
;  adc quant_error_2_msb
;  sta quant_error_3_msb
;;1/16, 2/16, 3/16 and 4/16 are done
;
;  lda quant_error_1_lsb
;  clc
;  adc quant_error_4_lsb
;  sta quant_error_5_lsb
;  lda quant_error_1_msb
;  adc quant_error_4_msb
;  sta quant_error_5_msb
;;1/16, 2/16, 3/16, 4/16 and 5/16 are done
;
;  lda quant_error_5_lsb
;  clc
;  adc quant_error_2_lsb
;  sta quant_error_7_lsb
;  lda quant_error_5_msb
;  adc quant_error_2_msb
;  sta quant_error_7_msb
;;1/16, 2/16, 3/16, 4/16, 5/16 and 7/16 are done
;
;
;;        pixels[x + 1][y    ] := pixels[x + 1][y    ] + quant_error × 7 / 16
;  lda floyd_this_row_lsb + 1,x
;  clc
;  adc quant_error_7_lsb
;  sta floyd_this_row_lsb + 1,x
;  lda floyd_this_row_msb + 1,x
;  adc quant_error_7_msb
;  sta floyd_this_row_msb + 1,x
;
;;        pixels[x - 1][y + 1] := pixels[x - 1][y + 1] + quant_error × 3 / 16
;  lda floyd_next_row_lsb - 1,x
;  clc
;  adc quant_error_3_lsb
;  sta floyd_next_row_lsb - 1,x
;  lda floyd_next_row_msb - 1,x
;  adc quant_error_3_msb
;  sta floyd_next_row_msb - 1,x
;
;;        pixels[x    ][y + 1] := pixels[x    ][y + 1] + quant_error × 5 / 16
;  lda floyd_next_row_lsb,x
;  clc
;  adc quant_error_5_lsb
;  sta floyd_next_row_lsb,x
;  lda floyd_next_row_msb,x
;  adc quant_error_5_msb
;  sta floyd_next_row_msb,x
;
;;        pixels[x + 1][y + 1] := pixels[x + 1][y + 1] + quant_error × 1 / 16
;  lda floyd_next_row_lsb + 1,x
;  clc
;  adc quant_error_1_lsb
;  sta floyd_next_row_lsb + 1,x
;  lda floyd_next_row_msb + 1,x
;  adc quant_error_1_msb
;  sta floyd_next_row_msb + 1,x
;
;  inx
;  cpx #12
;  beq this_row_is_done
;  jmp quantize_this_pixel
;
;this_row_is_done:
;;This row is done
;  ldx #11
;copy_next_row:
;  lda floyd_next_row_lsb,x
;  sta floyd_this_row_lsb,x
;  lda floyd_next_row_msb,x
;  sta floyd_this_row_msb,x
;  dex
;  bpl copy_next_row
;
;;Instead of alternating the direction, let's wrap around the rightmost pixel "outside of the byte" into the byte again:
;  lda floyd_this_row_lsb + 11
;  clc
;  adc floyd_this_row_lsb + 1
;  sta floyd_this_row_lsb + 1
;  lda floyd_this_row_msb + 11
;  adc floyd_this_row_msb + 1
;  sta floyd_this_row_msb + 1
;;...this didn't work very well.
;
;  lda floyd_this_byte
;  rts
;
;floyd_wanted_level_lsb: !byte 0
;floyd_wanted_level_msb: !byte 0
;
;make_floyd_table:
;  ldy #0
;make_more_bytes:
;
;  ; increase the wanted gray level:
;  lda floyd_wanted_level_lsb
;  clc
;  adc #1
;  sta floyd_wanted_level_lsb
;  lda floyd_wanted_level_msb
;  adc #0
;  sta floyd_wanted_level_msb
;
;  ; Fill in the next row with desired gray level:
;  ldx #11
;  lda floyd_wanted_level_lsb
;setmore:
;  sta floyd_next_row_lsb,x
;  dex
;  bpl setmore
;
;  ldx #11
;  lda floyd_wanted_level_msb
;setmore2:
;  sta floyd_next_row_msb,x
;  dex
;  bpl setmore2
;
;  jsr make_floyd_byte
;floyd_dest:
;  sta floyd_table,y
;  iny
;  bne make_more_bytes
;  lda floyd_dest+2
;  clc
;  adc #1
;  sta floyd_dest+2
;  sta $d020
;  cmp #>(floyd_table + $1000)
;  bne make_more_bytes
;  rts


scrpoi = $02

precalc_screens:
  lda #<(screen0-41)
  sta scrpoi
  lda #>(screen0-41)
  sta scrpoi+1

another_rnd:
rnd:
  lda #$10
  beq doEor2 ;added this
  asl
  bcc noEor2
doEor2:
  eor #$1d
noEor2:
  sta rnd+1
  and #$0f
  ldy #0
;Check if char to the up+left is equal:
  cmp (scrpoi),y
  beq another_rnd
;Check if char above is equal:
  iny
  cmp (scrpoi),y
  beq another_rnd
;Check if char to the up+right is equal:
  iny
  cmp (scrpoi),y
  beq another_rnd
;Check if char to the left is equal:
  ldy #40
  cmp (scrpoi),y
  beq another_rnd
  iny
  sta (scrpoi),y

  inc scrpoi
  bne nowraa
  inc scrpoi+1
nowraa:
  lda scrpoi
  cmp #<(screen4+$3e8-41)
  bne another_rnd
  lda scrpoi+1
  cmp #>(screen4+$3e8-41)
  bne another_rnd
  rts

colimage_ypos_msb:
  !byte 0

colimage_sin_table:
; Bounce:
;  !byte 0, 4, 8, 12, 16, 20, 24, 28, 32, 35, 39, 42, 45, 48, 51, 53, 55, 57, 59, 60, 62, 62, 63, 63, 63, 63, 63, 62, 61, 60, 58, 56, 54, 52, 49, 47, 44, 41, 37, 34, 30, 26, 22, 18, 14, 10, 6, 2, 255
;Sinus:
;  !byte 33, 35, 37, 39, 41, 43, 45, 47, 48, 50, 52, 53, 55, 56, 57, 59, 60, 61, 61, 62, 63, 63, 63, 63, 63, 63, 63, 63, 62, 61, 61, 60, 59, 58, 56, 55, 53, 52, 50, 48, 47, 45, 43, 41, 39, 37, 35, 33, 30, 28, 26, 24, 22, 20, 18, 16, 15, 13, 11, 10, 8, 7, 6, 4, 3, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 3, 4, 5, 7, 8, 10, 11, 13, 15, 16, 18, 20, 22, 24, 26, 28, 30, 255
;slow sinus:
;  !byte 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 47, 48, 49, 50, 51, 52, 53, 53, 54, 55, 56, 56, 57, 57, 58, 59, 59, 60, 60, 61, 61, 61, 62, 62, 62, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 62, 62, 62, 61, 61, 61, 60, 60, 59, 59, 58, 58, 57, 56, 56, 55, 54, 53, 53, 52, 51, 50, 49, 48, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 16, 15, 14, 13, 12, 11, 10, 10, 9, 8, 7, 7, 6, 6, 5, 4, 4, 3, 3, 2, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 7, 8, 9, 10, 10, 11, 12, 13, 14, 15, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 255
;slow sinus, amplitude 1-255, ends with 0:
  !byte 129, 133, 137, 141, 145, 150, 154, 158, 162, 166, 170, 174, 178, 181, 185, 189, 192, 196, 199, 203, 206, 210, 213, 216, 219, 222, 224, 227, 230, 232, 234, 237, 239, 241, 243, 244, 246, 248, 249, 250, 251, 252, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255, 254, 254, 253, 252, 251, 250, 248, 247, 245, 244, 242, 240, 238, 236, 234, 231, 229, 226, 223, 221, 218, 215, 211, 208, 205, 202, 198, 195, 191, 187, 184, 180, 176, 172, 168, 164, 160, 156, 152, 148, 144, 140, 136, 131, 127, 123, 119, 115, 111, 106, 102, 98, 94, 90, 86, 82, 78, 75, 71, 67, 64, 60, 57, 53, 50, 46, 43, 40, 37, 34, 32, 29, 26, 24, 22, 19, 17, 15, 13, 12, 10, 8, 7, 6, 5, 4, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4, 5, 6, 8, 9, 11, 12, 14, 16, 18, 20, 22, 25, 27, 30, 33, 35, 38, 41, 45, 48, 51, 54, 58, 61, 65, 69, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120, 125, 0



copy_colimage_to_d800:
do_black_colimage:
  ldx #0
  beq no_black_colimage
  ;Stop doing beats:
  lda #$80
  sta beat_delay+1
  cpx #1
  bne update_the_noise
  inx
  stx do_black_colimage+1
  ldx #0
  lda #0
fill_black0:
  sta $d800,x
  sta $d880,x
  inx
  bpl fill_black0
fill_black1:
  sta $d900,x
  sta $d980,x
  dex
  bpl fill_black1
fill_black2:
  sta $da00,x
  sta $da80,x
  inx
  bpl fill_black2
fill_black3:
  sta $db00,x
  sta $db80,x
  dex
  bpl fill_black3
  rts
update_the_noise:
  lda colimage_xpos_lsb+1
  clc
  adc #3
  sta colimage_xpos_lsb+1
  and #$7
  eor #$7
; Setup illegal display mode:
  ora #$10  ;multicolor
  sta desired_d016+1
  jmp copy_noise_into_chars
no_black_colimage:
  lda resulting_xpos_msb+1
  sta previous_xpos_msb+1
colsin_xcou:
  ldx #30
  lda colimage_sin_table,x
  bne nowrapty
  ldx #0
  lda colimage_sin_table,x
nowrapty:
  inx
  stx colsin_xcou+1

  lsr
  lsr
  clc
extra_x_lsb:
  adc #0
  sta resulting_xpos_lsb+1
extra_x_msb:
  lda #0
  adc #0
  and #3
  sta resulting_xpos_msb+1

; The colimage background is 128 chars wide = 1024 pixels = $0400
  sec
previous_xpos_msb:
  sbc #0
;00 -> 01   = $01
;01 -> 02   = $01
;02 -> 03   = $01
;03 -> 00   = $fd
  cmp #$fd
  bne no_wrap_this_time
;This is where the background wraps around, which also means that it "jumps up" 8 pixels.
;So, we will temporarily need to "add" 7 to the y-position to make this transition smoother.
  lda #31
  sta ypos_offset_due_to_wrap+1
no_wrap_this_time:

colsin_ycou:
  ldx #29
  lda colimage_sin_table,x
  bne nowrapt
  ldx #0
  lda sometimes_bounce_it_y+1
stop_bouncing_in_y:
  eor #$ff
  sta sometimes_bounce_it_y+1
  lda colimage_sin_table,x
nowrapt:
  inx
  stx colsin_ycou+1
sometimes_bounce_it_y:
  eor #$00
  sec
ypos_offset_due_to_wrap:
  sbc #0
  lsr
  eor #$7f
  sta colimage_ypos+1

  ldy ypos_offset_due_to_wrap+1
  dey
  bmi done_going_to_0
  sty ypos_offset_due_to_wrap+1
done_going_to_0:

;Move colimage in x-dir a little to the left
  lda extra_x_lsb+1
  clc
  adc #3
  sta extra_x_lsb+1
  lda extra_x_msb+1
  adc #0
  sta extra_x_msb+1

resulting_xpos_lsb:
  lda #0
  and #7
  sta colimage_xpos_lsb+1
resulting_xpos_msb:
  lda #0
  lsr
  ror resulting_xpos_lsb+1
  lsr
  ror resulting_xpos_lsb+1
  lsr
  ror resulting_xpos_lsb+1
  lda resulting_xpos_lsb+1
  sta colimage_xpos_msb+1


colimage_xpos_lsb:
  lda #$70
  and #$7
  eor #$7
; Setup illegal display mode:
  ora #$10  ;multicolor
  sta desired_d016+1
colimage_ypos:
  lda #0
  and #$7
  eor #7
;  ora #$18
; Setup illegal display mode:
  ora #$58   ;ECM
  sta desired_d011+1

  lda colimage_ypos+1
  lsr
  lsr
  lsr
  and #$0f
  tax

colimage_xpos_msb:
  lda #$00
  and #$7f
;  lsr
;  lsr
;  lsr
;  clc
;  adc #39
  tay

last_ypos:
  cpx #$ff
  bne yes_do_copy
last_xpos:
  cpy #$ff
  bne yes_do_copy
;no need to copy anything, the screen is at the same position as last time:
;so, let's randomize the noise instead:
  jmp copy_noise_into_chars
yes_do_copy:
  stx last_ypos+1
  sty last_xpos+1

; Can we use the upper nybble of colimage0?
; We have the two nybbles in A
;  lda colimage0 +  0*$80,x        ;4
;  sta $d800 +      0*$28,x        ;4

;We have the two nybbles in Y:
;  ldy colimage0 +  0*$80,x
;  tya
;  sta $d800 +      0*$28,x

; YES:
;  lax colimage0 +  0*$80,y        ;4
;  sta $d800 +      0*$28,y        ;4
;  lda shift_4_to_right_table,x
;  sta $d800 +      1*$28,y
; Problem is now we have to interleave the images so every second byte belongs to the other image.
; Difficult to load "every second byte". But can do this so that every second row is embedded in one byte.
; Now we need to copy routines, one for even y, and one for odd y. The odd y will need to read one byte more.

; With this, the image is only allowed to be 128-39 = 89 pixels wide, and the last 39 "pixels" need to be a copy of the 39 first ones.
; Like this, we don't get any page breaks.

  ;colimage_ypos+1   is 0 - 15
  ;colimage_xpos_msb:  is 0-127
  lda colimage_ypos+1
  lsr
  lsr
  lsr
  and #$0f
  lsr
  bcs copy_more_odd
  jmp copy_more_even
copy_more_odd:
  lsr
  bcs copy_more_odd_odd
  jmp copy_more_odd_even
copy_more_odd_odd:
;In here, we shall grab bytes starting from colimage0 + $x80 + xpos, and writing one nybble to $d800, then grab two nybbles and write to $d828+$d850...
  clc
colimage_poi_odd_odd:
  adc #>colimage0
  tay
  sty copy_more_odd_odd_0+2 +0*12
  iny
  sty copy_more_odd_odd_0+2 +9 +0*12
  sty copy_more_odd_odd_0+2 +9 +1*12
  iny
  sty copy_more_odd_odd_0+2 +9 +2*12
  sty copy_more_odd_odd_0+2 +9 +3*12
  iny
  sty copy_more_odd_odd_1+2 +0*12
  sty copy_more_odd_odd_1+2 +1*12
  iny
  sty copy_more_odd_odd_1+2 +2*12
  sty copy_more_odd_odd_1+2 +3*12
  iny
  sty copy_more_odd_odd_2+2 +0*12
  sty copy_more_odd_odd_2+2 +1*12
  iny
  sty copy_more_odd_odd_2+2 +2*12
  sty copy_more_odd_odd_2+2 +3*12
  lda colimage_xpos_msb+1
  and #$7f
  tay
  ora #$80
  sta copy_more_odd_odd_0+1 +0*12
  sty copy_more_odd_odd_0+1 +9 +0*12
  sta copy_more_odd_odd_0+1 +9 +1*12
  sty copy_more_odd_odd_0+1 +9 +2*12
  sta copy_more_odd_odd_0+1 +9 +3*12
  sty copy_more_odd_odd_1+1 +0*12
  sta copy_more_odd_odd_1+1 +1*12
  sty copy_more_odd_odd_1+1 +2*12
  sta copy_more_odd_odd_1+1 +3*12
  sty copy_more_odd_odd_2+1 +0*12
  sta copy_more_odd_odd_2+1 +1*12
  sty copy_more_odd_odd_2+1 +2*12
  sta copy_more_odd_odd_2+1 +3*12
  ldy #38
copy_more_odd_odd_0:
  lax colimage0 +    0*$80,y
  lda nybbleswap_table,x
  sta $d800 +      0*$28,y
  lax colimage0 +    1*$80,y
  sta $d800 +      1*$28,y
  lda nybbleswap_table,x
  sta $d800 +      2*$28,y
  lax colimage0 +    2*$80,y
  sta $d800 +      3*$28,y
  lda nybbleswap_table,x
  sta $d800 +      4*$28,y
  lax colimage0 +    3*$80,y
  sta $d800 +      5*$28,y
  lda nybbleswap_table,x
  sta $d800 +      6*$28,y
  lax colimage0 +    4*$80,y
  sta $d800 +      7*$28,y
  lda nybbleswap_table,x
  sta $d800 +      8*$28,y
  dey
  bpl copy_more_odd_odd_0
  ldy #38
copy_more_odd_odd_1:
  lax colimage0 +    5*$80,y
  sta $d800 +      9*$28,y
  lda nybbleswap_table,x
  sta $d800 +     10*$28,y
  lax colimage0 +    6*$80,y
  sta $d800 +     11*$28,y
  lda nybbleswap_table,x
  sta $d800 +     12*$28,y
  lax colimage0 +    7*$80,y
  sta $d800 +     13*$28,y
  lda nybbleswap_table,x
  sta $d800 +     14*$28,y
  lax colimage0 +    8*$80,y
  sta $d800 +     15*$28,y
  lda nybbleswap_table,x
  sta $d800 +     16*$28,y
  dey
  bpl copy_more_odd_odd_1
  ldy #38
copy_more_odd_odd_2:
  lax colimage0 +    8*$80,y
  sta $d800 +     17*$28,y
  lda nybbleswap_table,x
  sta $d800 +     18*$28,y
  lax colimage0 +    9*$80,y
  sta $d800 +     19*$28,y
  lda nybbleswap_table,x
  sta $d800 +     20*$28,y
  lax colimage0 +   10*$80,y
  sta $d800 +     21*$28,y
  lda nybbleswap_table,x
  sta $d800 +     22*$28,y
  lax colimage0 +   11*$80,y
  sta $d800 +     23*$28,y
  lda nybbleswap_table,x
  sta $d800 +     24*$28,y
  dey
  bpl copy_more_odd_odd_2
  rts

copy_more_odd_even:
;In here, we shall grab bytes starting from colimage0 + $x00 + xpos, and writing one nybble to $d800, then grab two nybbles and write to $d828+$d850...
  clc
colimage_poi_odd_even:
  adc #>colimage0
  tay
  sty copy_more_odd_even_0+2 +0*12
  sty copy_more_odd_even_0+2 +9 +0*12
  iny
  sty copy_more_odd_even_0+2 +9 +1*12
  sty copy_more_odd_even_0+2 +9 +2*12
  iny
  sty copy_more_odd_even_0+2 +9 +3*12
  sty copy_more_odd_even_1+2 +0*12
  iny
  sty copy_more_odd_even_1+2 +1*12
  sty copy_more_odd_even_1+2 +2*12
  iny
  sty copy_more_odd_even_1+2 +3*12
  sty copy_more_odd_even_2+2 +0*12
  iny
  sty copy_more_odd_even_2+2 +1*12
  sty copy_more_odd_even_2+2 +2*12
  iny
  sty copy_more_odd_even_2+2 +3*12
  lda colimage_xpos_msb+1
  and #$7f
  tay
  ora #$80
  sty copy_more_odd_even_0+1 +0*12
  sta copy_more_odd_even_0+1 +9 +0*12
  sty copy_more_odd_even_0+1 +9 +1*12
  sta copy_more_odd_even_0+1 +9 +2*12
  sty copy_more_odd_even_0+1 +9 +3*12
  sta copy_more_odd_even_1+1 +0*12
  sty copy_more_odd_even_1+1 +1*12
  sta copy_more_odd_even_1+1 +2*12
  sty copy_more_odd_even_1+1 +3*12
  sta copy_more_odd_even_2+1 +0*12
  sty copy_more_odd_even_2+1 +1*12
  sta copy_more_odd_even_2+1 +2*12
  sty copy_more_odd_even_2+1 +3*12
  ldy #38
copy_more_odd_even_0:
  lax colimage0 +    0*$80,y
  lda nybbleswap_table,x
  sta $d800 +      0*$28,y
  lax colimage0 +    1*$80,y
  sta $d800 +      1*$28,y
  lda nybbleswap_table,x
  sta $d800 +      2*$28,y
  lax colimage0 +    2*$80,y
  sta $d800 +      3*$28,y
  lda nybbleswap_table,x
  sta $d800 +      4*$28,y
  lax colimage0 +    3*$80,y
  sta $d800 +      5*$28,y
  lda nybbleswap_table,x
  sta $d800 +      6*$28,y
  lax colimage0 +    4*$80,y
  sta $d800 +      7*$28,y
  lda nybbleswap_table,x
  sta $d800 +      8*$28,y
  dey
  bpl copy_more_odd_even_0
  ldy #38
copy_more_odd_even_1:
  lax colimage0 +    5*$80,y
  sta $d800 +      9*$28,y
  lda nybbleswap_table,x
  sta $d800 +     10*$28,y
  lax colimage0 +    6*$80,y
  sta $d800 +     11*$28,y
  lda nybbleswap_table,x
  sta $d800 +     12*$28,y
  lax colimage0 +    7*$80,y
  sta $d800 +     13*$28,y
  lda nybbleswap_table,x
  sta $d800 +     14*$28,y
  lax colimage0 +    8*$80,y
  sta $d800 +     15*$28,y
  lda nybbleswap_table,x
  sta $d800 +     16*$28,y
  dey
  bpl copy_more_odd_even_1
  ldy #38
copy_more_odd_even_2:
  lax colimage0 +    8*$80,y
  sta $d800 +     17*$28,y
  lda nybbleswap_table,x
  sta $d800 +     18*$28,y
  lax colimage0 +    9*$80,y
  sta $d800 +     19*$28,y
  lda nybbleswap_table,x
  sta $d800 +     20*$28,y
  lax colimage0 +   10*$80,y
  sta $d800 +     21*$28,y
  lda nybbleswap_table,x
  sta $d800 +     22*$28,y
  lax colimage0 +   11*$80,y
  sta $d800 +     23*$28,y
  lda nybbleswap_table,x
  sta $d800 +     24*$28,y
  dey
  bpl copy_more_odd_even_2
  rts

copy_more_even:
  lsr
  bcs copy_more_even_odd
  jmp copy_more_even_even
copy_more_even_odd:
;In here, we shall grab bytes starting from colimage0 + $x80 + xpos, and writing two nybbles to $d800+$d828
  clc
colimage_poi_even_odd:
  adc #>colimage0
  tay
  sty copy_more_even_odd_0+2 +0*12
  iny
  sty copy_more_even_odd_0+2 +1*12
  sty copy_more_even_odd_0+2 +2*12
  iny
  sty copy_more_even_odd_0+2 +3*12
  sty copy_more_even_odd_1+2 +0*12
  iny
  sty copy_more_even_odd_1+2 +1*12
  sty copy_more_even_odd_1+2 +2*12
  iny
  sty copy_more_even_odd_1+2 +3*12
  sty copy_more_even_odd_2+2 +0*12
  iny
  sty copy_more_even_odd_2+2 +1*12
  sty copy_more_even_odd_2+2 +2*12
  iny
  sty copy_more_even_odd_2+2 +3*12
  sty copy_more_even_odd_2+2 +4*12
  lda colimage_xpos_msb+1
  and #$7f
  tay
  ora #$80
  sta copy_more_even_odd_0+1 +0*12
  sty copy_more_even_odd_0+1 +1*12
  sta copy_more_even_odd_0+1 +2*12
  sty copy_more_even_odd_0+1 +3*12
  sta copy_more_even_odd_1+1 +0*12
  sty copy_more_even_odd_1+1 +1*12
  sta copy_more_even_odd_1+1 +2*12
  sty copy_more_even_odd_1+1 +3*12
  sta copy_more_even_odd_2+1 +0*12
  sty copy_more_even_odd_2+1 +1*12
  sta copy_more_even_odd_2+1 +2*12
  sty copy_more_even_odd_2+1 +3*12
  sta copy_more_even_odd_2+1 +4*12
  ldy #38
copy_more_even_odd_0:
  lax colimage0 +    0*$80,y
  sta $d800 +      0*$28,y
  lda nybbleswap_table,x
  sta $d800 +      1*$28,y
  lax colimage0 +    1*$80,y
  sta $d800 +      2*$28,y
  lda nybbleswap_table,x
  sta $d800 +      3*$28,y
  lax colimage0 +    2*$80,y
  sta $d800 +      4*$28,y
  lda nybbleswap_table,x
  sta $d800 +      5*$28,y
  lax colimage0 +    3*$80,y
  sta $d800 +      6*$28,y
  lda nybbleswap_table,x
  sta $d800 +      7*$28,y
  dey
  bpl copy_more_even_odd_0
  ldy #38
copy_more_even_odd_1:
  lax colimage0 +    4*$80,y
  sta $d800 +      8*$28,y
  lda nybbleswap_table,x
  sta $d800 +      9*$28,y
  lax colimage0 +    5*$80,y
  sta $d800 +     10*$28,y
  lda nybbleswap_table,x
  sta $d800 +     11*$28,y
  lax colimage0 +    6*$80,y
  sta $d800 +     12*$28,y
  lda nybbleswap_table,x
  sta $d800 +     13*$28,y
  lax colimage0 +    7*$80,y
  sta $d800 +     14*$28,y
  lda nybbleswap_table,x
  sta $d800 +     15*$28,y
  dey
  bpl copy_more_even_odd_1
  ldy #38
copy_more_even_odd_2:
  lax colimage0 +    8*$80,y
  sta $d800 +     16*$28,y
  lda nybbleswap_table,x
  sta $d800 +     17*$28,y
  lax colimage0 +    9*$80,y
  sta $d800 +     18*$28,y
  lda nybbleswap_table,x
  sta $d800 +     19*$28,y
  lax colimage0 +   10*$80,y
  sta $d800 +     20*$28,y
  lda nybbleswap_table,x
  sta $d800 +     21*$28,y
  lax colimage0 +   11*$80,y
  sta $d800 +     22*$28,y
  lda nybbleswap_table,x
  sta $d800 +     23*$28,y
  lax colimage0 +   12*$80,y
  sta $d800 +     24*$28,y
  dey
  bpl copy_more_even_odd_2
  rts

copy_more_even_even:
;In here, we shall grab bytes starting from colimage0 + $x00 + xpos, and writing two nybbles to $d800+$d828
  clc
colimage_poi_even_even:
  adc #>colimage0
  tay
  sty copy_more_even_even_0+2 +0*12
  sty copy_more_even_even_0+2 +1*12
  iny
  sty copy_more_even_even_0+2 +2*12
  sty copy_more_even_even_0+2 +3*12
  iny
  sty copy_more_even_even_1+2 +0*12
  sty copy_more_even_even_1+2 +1*12
  iny
  sty copy_more_even_even_1+2 +2*12
  sty copy_more_even_even_1+2 +3*12
  iny
  sty copy_more_even_even_2+2 +0*12
  sty copy_more_even_even_2+2 +1*12
  iny
  sty copy_more_even_even_2+2 +2*12
  sty copy_more_even_even_2+2 +3*12
  iny
  sty copy_more_even_even_2+2 +4*12
  lda colimage_xpos_msb+1
  and #$7f
  tay
  ora #$80
  sty copy_more_even_even_0+1 +0*12
  sta copy_more_even_even_0+1 +1*12
  sty copy_more_even_even_0+1 +2*12
  sta copy_more_even_even_0+1 +3*12
  sty copy_more_even_even_1+1 +0*12
  sta copy_more_even_even_1+1 +1*12
  sty copy_more_even_even_1+1 +2*12
  sta copy_more_even_even_1+1 +3*12
  sty copy_more_even_even_2+1 +0*12
  sta copy_more_even_even_2+1 +1*12
  sty copy_more_even_even_2+1 +2*12
  sta copy_more_even_even_2+1 +3*12
  sty copy_more_even_even_2+1 +4*12
  ldy #38
copy_more_even_even_0:
  lax colimage0 +    0*$80,y
  sta $d800 +      0*$28,y
  lda nybbleswap_table,x
  sta $d800 +      1*$28,y
  lax colimage0 +    1*$80,y
  sta $d800 +      2*$28,y
  lda nybbleswap_table,x
  sta $d800 +      3*$28,y
  lax colimage0 +    2*$80,y
  sta $d800 +      4*$28,y
  lda nybbleswap_table,x
  sta $d800 +      5*$28,y
  lax colimage0 +    3*$80,y
  sta $d800 +      6*$28,y
  lda nybbleswap_table,x
  sta $d800 +      7*$28,y
  dey
  bpl copy_more_even_even_0
  ldy #38
copy_more_even_even_1:
  lax colimage0 +    4*$80,y
  sta $d800 +      8*$28,y
  lda nybbleswap_table,x
  sta $d800 +      9*$28,y
  lax colimage0 +    5*$80,y
  sta $d800 +     10*$28,y
  lda nybbleswap_table,x
  sta $d800 +     11*$28,y
  lax colimage0 +    6*$80,y
  sta $d800 +     12*$28,y
  lda nybbleswap_table,x
  sta $d800 +     13*$28,y
  lax colimage0 +    7*$80,y
  sta $d800 +     14*$28,y
  lda nybbleswap_table,x
  sta $d800 +     15*$28,y
  dey
  bpl copy_more_even_even_1
  ldy #38
copy_more_even_even_2:
  lax colimage0 +    8*$80,y
  sta $d800 +     16*$28,y
  lda nybbleswap_table,x
  sta $d800 +     17*$28,y
  lax colimage0 +    9*$80,y
  sta $d800 +     18*$28,y
  lda nybbleswap_table,x
  sta $d800 +     19*$28,y
  lax colimage0 +   10*$80,y
  sta $d800 +     20*$28,y
  lda nybbleswap_table,x
  sta $d800 +     21*$28,y
  lax colimage0 +   11*$80,y
  sta $d800 +     22*$28,y
  lda nybbleswap_table,x
  sta $d800 +     23*$28,y
  lax colimage0 +   12*$80,y
  sta $d800 +     24*$28,y
  dey
  bpl copy_more_even_even_2
  rts



* = $e000

  !align 255,0,0
;char A(char_output_no=0)(char_no=0) has x_offset=0 in the png and is 16 pixels wide
char_00_nybble_0:     !byte 13,2,1,1,1,0,3,3,3,3,3,2,1,1,3,3,3,3,3,3,15
char_00_nybble_0_msb: !byte 208,32,16,16,16,0,48,48,48,48,48,32,16,16,48,48,48,48,48,48,240
char_00_nybble_1:     !byte 0,8,8,4,4,1,13,13,13,13,9,5,5,13,13,13,13,13,13,13,12
char_00_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,208,208,144,80,80,208,208,208,208,208,208,208,192
;char B(char_output_no=1)(char_no=1) has x_offset=16 in the png and is 16 pixels wide
char_01_nybble_0:     !byte 13,2,1,1,1,0,3,3,3,3,3,2,1,1,3,3,3,3,2,1,13
char_01_nybble_0_msb: !byte 208,32,16,16,16,0,48,48,48,48,48,32,16,16,48,48,48,48,32,16,208
char_01_nybble_1:     !byte 0,8,8,4,4,1,13,13,12,12,8,4,4,12,13,13,12,0,4,4,7
char_01_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,192,192,128,64,64,192,208,208,192,0,64,64,112
;char C(char_output_no=2)(char_no=2) has x_offset=32 in the png and is 16 pixels wide
char_02_nybble_0:     !byte 13,2,1,1,5,4,7,7,3,3,3,3,3,3,3,3,3,3,2,1,13
char_02_nybble_0_msb: !byte 208,32,16,16,80,64,112,112,48,48,48,48,48,48,48,48,48,48,32,16,208
char_02_nybble_1:     !byte 0,8,8,4,4,1,13,15,15,15,15,15,15,15,15,15,12,0,4,4,7
char_02_nybble_1_msb: !byte 0,128,128,64,64,16,208,240,240,240,240,240,240,240,240,240,192,0,64,64,112
;char D(char_output_no=3)(char_no=3) has x_offset=48 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_03_nybble_0:     !byte 13,2,1,1,1,0,3,3,3,3,3,3,3,3,3,3,3,3,2,1,13
char_03_nybble_0_msb: !byte 208,32,16,16,16,0,48,48,48,48,48,48,48,48,48,48,48,48,32,16,208
char_03_nybble_1:     !byte 0,8,8,4,4,1,13,13,13,13,13,13,13,13,13,13,12,0,4,4,7
char_03_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,208,208,208,208,208,208,208,208,192,0,64,64,112
;char E(char_output_no=4)(char_no=4) has x_offset=64 in the png and is 16 pixels wide
char_04_nybble_0:     !byte 13,2,1,1,1,0,3,3,3,3,3,2,1,1,3,3,3,3,2,1,13
char_04_nybble_0_msb: !byte 208,32,16,16,16,0,48,48,48,48,48,32,16,16,48,48,48,48,32,16,208
char_04_nybble_1:     !byte 0,8,8,4,4,15,15,15,15,15,11,7,7,15,15,15,12,0,4,4,7
char_04_nybble_1_msb: !byte 0,128,128,64,64,240,240,240,240,240,176,112,112,240,240,240,192,0,64,64,112
;char F(char_output_no=5)(char_no=5) has x_offset=80 in the png and is 16 pixels wide
char_05_nybble_0:     !byte 13,2,1,1,1,0,3,3,3,3,3,2,1,1,3,3,3,3,3,3,15
char_05_nybble_0_msb: !byte 208,32,16,16,16,0,48,48,48,48,48,32,16,16,48,48,48,48,48,48,240
char_05_nybble_1:     !byte 0,8,8,4,4,15,15,15,15,15,11,7,7,15,15,15,15,15,15,15,15
char_05_nybble_1_msb: !byte 0,128,128,64,64,240,240,240,240,240,176,112,112,240,240,240,240,240,240,240,240
;char G(char_output_no=6)(char_no=6) has x_offset=96 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_06_nybble_0:     !byte 13,2,1,1,5,4,7,7,3,3,3,3,3,3,3,3,3,3,2,1,13
char_06_nybble_0_msb: !byte 208,32,16,16,80,64,112,112,48,48,48,48,48,48,48,48,48,48,32,16,208
char_06_nybble_1:     !byte 0,8,8,4,4,1,13,15,15,15,15,0,0,0,12,13,12,0,4,4,7
char_06_nybble_1_msb: !byte 0,128,128,64,64,16,208,240,240,240,240,0,0,0,192,208,192,0,64,64,112
;char H(char_output_no=7)(char_no=7) has x_offset=112 in the png and is 16 pixels wide
char_07_nybble_0:     !byte 15,3,3,7,7,7,7,7,3,3,3,2,1,1,3,3,3,3,3,3,15
char_07_nybble_0_msb: !byte 240,48,48,112,112,112,112,112,48,48,48,32,16,16,48,48,48,48,48,48,240
char_07_nybble_1:     !byte 15,15,12,12,12,13,13,13,13,13,9,5,5,13,13,13,13,13,13,13,12
char_07_nybble_1_msb: !byte 240,240,192,192,192,208,208,208,208,208,144,80,80,208,208,208,208,208,208,208,192
;char I(char_output_no=8)(char_no=8) has x_offset=128 in the png and is 8 pixels wide
char_08_nybble_0:     !byte 15,0,8,4,4,0,3,3,3,3,3,3,3,3,3,0,0,0,0,0,15
char_08_nybble_0_msb: !byte 240,0,128,64,64,0,48,48,48,48,48,48,48,48,48,0,0,0,0,0,240
;char .(char_output_no=9)(char_no=26) has x_offset=424 in the png and is 8 pixels wide
char_09_nybble_0:     !byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,14,13,13,13
char_09_nybble_0_msb: !byte 240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,224,208,208,208
;char J(char_output_no=10)(char_no=9) has x_offset=136 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_10_nybble_0:     !byte 15,2,1,1,1,0,3,15,15,15,15,15,15,15,15,15,15,3,2,1,13
char_10_nybble_0_msb: !byte 240,32,16,16,16,0,48,240,240,240,240,240,240,240,240,240,240,48,32,16,208
char_10_nybble_1:     !byte 15,8,9,5,5,13,13,13,13,13,13,13,13,13,13,13,12,0,4,4,7
char_10_nybble_1_msb: !byte 240,128,144,80,80,208,208,208,208,208,208,208,208,208,208,208,192,0,64,64,112
;char K(char_output_no=11)(char_no=10) has x_offset=152 in the png and is 16 pixels wide
char_11_nybble_0:     !byte 15,3,3,7,7,7,7,7,3,3,3,2,1,1,3,3,3,3,3,3,15
char_11_nybble_0_msb: !byte 240,48,48,112,112,112,112,112,48,48,48,32,16,16,48,48,48,48,48,48,240
char_11_nybble_1:     !byte 15,15,12,12,12,13,13,13,12,12,8,4,7,3,3,0,0,0,0,0,15
char_11_nybble_1_msb: !byte 240,240,192,192,192,208,208,208,192,192,128,64,112,48,48,0,0,0,0,0,240
;char L(char_output_no=12)(char_no=11) has x_offset=168 in the png and is 16 pixels wide
char_12_nybble_0:     !byte 15,3,3,7,7,7,7,7,3,3,3,3,3,3,3,3,3,3,2,1,13
char_12_nybble_0_msb: !byte 240,48,48,112,112,112,112,112,48,48,48,48,48,48,48,48,48,48,32,16,208
char_12_nybble_1:     !byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,8,4,4,7
char_12_nybble_1_msb: !byte 240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,128,64,64,112
;char M(char_output_no=13)(char_no=12) has x_offset=184 in the png and is 24 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_13_nybble_0:     !byte 13,2,1,1,1,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,15
char_13_nybble_0_msb: !byte 208,32,16,16,16,0,48,48,48,48,48,48,48,48,48,48,48,48,48,48,240
char_13_nybble_1:     !byte 1,9,9,5,4,1,13,13,13,13,13,13,13,13,13,13,13,13,13,13,12
char_13_nybble_1_msb: !byte 16,144,144,80,64,16,208,208,208,208,208,208,208,208,208,208,208,208,208,208,192
char_13_nybble_2:     !byte 0,8,4,4,4,1,13,13,13,13,13,13,13,13,13,13,13,13,13,13,12
char_13_nybble_2_msb: !byte 0,128,64,64,64,16,208,208,208,208,208,208,208,208,208,208,208,208,208,208,192
;char N(char_output_no=14)(char_no=13) has x_offset=208 in the png and is 16 pixels wide
char_14_nybble_0:     !byte 13,2,1,1,1,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,15
char_14_nybble_0_msb: !byte 208,32,16,16,16,0,48,48,48,48,48,48,48,48,48,48,48,48,48,48,240
char_14_nybble_1:     !byte 0,8,8,4,4,1,13,13,13,13,13,13,13,13,13,13,13,13,13,13,12
char_14_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,208,208,208,208,208,208,208,208,208,208,208,208,192
;char ,(char_output_no=15)(char_no=27) has x_offset=432 in the png and is 8 pixels wide
char_15_nybble_0:     !byte 15,15,15,15,15,15,15,15,15,15,15,15,15,12,13,13,12,12,12,0,15
char_15_nybble_0_msb: !byte 240,240,240,240,240,240,240,240,240,240,240,240,240,192,208,208,192,192,192,0,240
;char O(char_output_no=16)(char_no=14) has x_offset=224 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_16_nybble_0:     !byte 13,2,1,1,1,4,7,7,3,3,3,3,3,3,3,3,3,3,2,1,13
char_16_nybble_0_msb: !byte 208,32,16,16,16,64,112,112,48,48,48,48,48,48,48,48,48,48,32,16,208
char_16_nybble_1:     !byte 0,8,8,4,4,1,13,13,13,13,13,13,13,13,13,13,12,0,4,4,7
char_16_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,208,208,208,208,208,208,208,208,192,0,64,64,112
;char P(char_output_no=17)(char_no=15) has x_offset=240 in the png and is 16 pixels wide
char_17_nybble_0:     !byte 13,2,1,1,1,0,3,3,3,3,3,2,1,1,3,3,3,3,3,3,15
char_17_nybble_0_msb: !byte 208,32,16,16,16,0,48,48,48,48,48,32,16,16,48,48,48,48,48,48,240
char_17_nybble_1:     !byte 0,8,8,4,4,1,13,13,12,12,8,7,7,15,15,15,15,15,15,15,15
char_17_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,192,192,128,112,112,240,240,240,240,240,240,240,240
;char Q(char_output_no=18)(char_no=16) has x_offset=256 in the png and is 16 pixels wide
char_18_nybble_0:     !byte 13,2,1,1,1,4,7,7,7,7,7,7,7,7,7,4,0,0,13,15,15
char_18_nybble_0_msb: !byte 208,32,16,16,16,64,112,112,112,112,112,112,112,112,112,64,0,0,208,240,240
char_18_nybble_1:     !byte 0,8,8,4,4,1,13,13,13,13,13,13,13,13,13,0,1,0,0,0,3
char_18_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,208,208,208,208,208,208,208,0,16,0,0,0,48
;char R(char_output_no=19)(char_no=17) has x_offset=272 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_19_nybble_0:     !byte 13,2,1,1,1,0,3,3,3,3,2,1,1,3,3,3,3,3,3,3,15
char_19_nybble_0_msb: !byte 208,32,16,16,16,0,48,48,48,48,32,16,16,48,48,48,48,48,48,48,240
char_19_nybble_1:     !byte 0,8,8,4,4,1,13,13,12,12,0,8,7,7,3,0,0,0,0,0,15
char_19_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,192,192,0,128,112,112,48,0,0,0,0,0,240
;char S(char_output_no=20)(char_no=18) has x_offset=288 in the png and is 16 pixels wide
char_20_nybble_0:     !byte 13,2,1,1,5,4,7,7,7,7,2,1,13,15,15,3,3,3,2,1,13
char_20_nybble_0_msb: !byte 208,32,16,16,80,64,112,112,112,112,32,16,208,240,240,48,48,48,32,16,208
char_20_nybble_1:     !byte 0,8,8,4,4,1,13,13,12,15,15,8,4,4,13,13,12,0,4,4,7
char_20_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,192,240,240,128,64,64,208,208,192,0,64,64,112
;char T(char_output_no=21)(char_no=19) has x_offset=304 in the png and is 16 pixels wide
char_21_nybble_0:     !byte 15,2,1,1,1,0,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
char_21_nybble_0_msb: !byte 240,32,16,16,16,0,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240
char_21_nybble_1:     !byte 15,9,6,5,5,5,7,7,7,7,7,7,7,7,7,7,4,4,4,4,7
char_21_nybble_1_msb: !byte 240,144,96,80,80,80,112,112,112,112,112,112,112,112,112,112,64,64,64,64,112
;char U(char_output_no=22)(char_no=20) has x_offset=320 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_22_nybble_0:     !byte 15,3,3,3,7,7,7,7,3,3,3,3,3,3,3,3,3,3,2,1,13
char_22_nybble_0_msb: !byte 240,48,48,48,112,112,112,112,48,48,48,48,48,48,48,48,48,48,32,16,208
char_22_nybble_1:     !byte 15,15,12,12,12,13,13,13,13,13,13,13,13,13,13,13,12,0,4,4,7
char_22_nybble_1_msb: !byte 240,240,192,192,192,208,208,208,208,208,208,208,208,208,208,208,192,0,64,64,112
;char V(char_output_no=23)(char_no=21) has x_offset=336 in the png and is 16 pixels wide
char_23_nybble_0:     !byte 15,12,0,0,0,1,0,12,13,13,13,13,13,13,13,13,13,13,13,13,12
char_23_nybble_0_msb: !byte 240,192,0,0,0,16,0,192,208,208,208,208,208,208,208,208,208,208,208,208,192
char_23_nybble_1:     !byte 15,15,12,12,12,13,13,13,13,13,13,13,13,13,13,13,12,4,4,4,7
char_23_nybble_1_msb: !byte 240,240,192,192,192,208,208,208,208,208,208,208,208,208,208,208,192,64,64,64,112
;char X(char_output_no=24)(char_no=23) has x_offset=376 in the png and is 16 pixels wide
char_24_nybble_0:     !byte 15,3,3,7,7,7,7,7,3,0,14,1,0,3,3,3,3,3,3,3,15
char_24_nybble_0_msb: !byte 240,48,48,112,112,112,112,112,48,0,224,16,0,48,48,48,48,48,48,48,240
char_24_nybble_1:     !byte 15,15,12,12,12,13,13,13,12,8,4,4,0,12,13,13,13,13,13,13,12
char_24_nybble_1_msb: !byte 240,240,192,192,192,208,208,208,192,128,64,64,0,192,208,208,208,208,208,208,192
;char W(char_output_no=25)(char_no=22) has x_offset=352 in the png and is 24 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_25_nybble_0:     !byte 15,12,0,0,0,1,0,12,13,13,13,13,13,13,13,13,13,13,13,13,12
char_25_nybble_0_msb: !byte 240,192,0,0,0,16,0,192,208,208,208,208,208,208,208,208,208,208,208,208,192
char_25_nybble_1:     !byte 15,15,12,12,12,13,13,13,13,13,13,13,13,13,13,13,0,4,5,5,4
char_25_nybble_1_msb: !byte 240,240,192,192,192,208,208,208,208,208,208,208,208,208,208,208,0,64,80,80,64
char_25_nybble_2:     !byte 15,15,12,12,12,13,13,13,13,13,13,13,13,13,13,13,0,4,4,4,7
char_25_nybble_2_msb: !byte 240,240,192,192,192,208,208,208,208,208,208,208,208,208,208,208,0,64,64,64,112
;char Y(char_output_no=26)(char_no=24) has x_offset=392 in the png and is 16 pixels wide
char_26_nybble_0:     !byte 15,3,3,7,7,7,7,7,3,3,3,2,1,13,15,15,3,3,2,1,13
char_26_nybble_0_msb: !byte 240,48,48,112,112,112,112,112,48,48,48,32,16,208,240,240,48,48,32,16,208
char_26_nybble_1:     !byte 15,15,12,12,12,13,13,13,13,13,9,5,5,13,13,13,12,0,4,4,7
char_26_nybble_1_msb: !byte 240,240,192,192,192,208,208,208,208,208,144,80,80,208,208,208,192,0,64,64,112
;char !(char_output_no=27)(char_no=28) has x_offset=440 in the png and is 8 pixels wide
char_27_nybble_0:     !byte 14,13,13,13,13,13,13,13,13,13,13,13,13,12,15,15,15,14,13,13,13
char_27_nybble_0_msb: !byte 224,208,208,208,208,208,208,208,208,208,208,208,208,192,240,240,240,224,208,208,208
;char Z(char_output_no=28)(char_no=25) has x_offset=408 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_28_nybble_0:     !byte 13,2,1,1,1,0,3,15,15,15,15,14,1,1,3,3,3,3,2,1,13
char_28_nybble_0_msb: !byte 208,32,16,16,16,0,48,240,240,240,240,224,16,16,48,48,48,48,32,16,208
char_28_nybble_1:     !byte 4,8,8,4,4,13,12,12,12,12,8,7,7,15,15,15,12,0,4,4,7
char_28_nybble_1_msb: !byte 64,128,128,64,64,208,192,192,192,192,128,112,112,240,240,240,192,0,64,64,112
;char ?(char_output_no=29)(char_no=29) has x_offset=448 in the png and is 16 pixels wide
char_29_nybble_0:     !byte 13,2,1,1,1,0,3,15,15,15,15,14,13,13,13,15,15,14,13,13,13
char_29_nybble_0_msb: !byte 208,32,16,16,16,0,48,240,240,240,240,224,208,208,208,240,240,224,208,208,208
char_29_nybble_1:     !byte 4,8,8,4,4,13,12,12,12,12,8,7,7,15,15,15,15,15,15,15,15
char_29_nybble_1_msb: !byte 64,128,128,64,64,208,192,192,192,192,128,112,112,240,240,240,240,240,240,240,240
;char :(char_output_no=30)(char_no=30) has x_offset=464 in the png and is 8 pixels wide
char_30_nybble_0:     !byte 15,15,15,15,15,15,15,15,14,13,13,13,15,15,15,15,15,14,13,13,13
char_30_nybble_0_msb: !byte 240,240,240,240,240,240,240,240,224,208,208,208,240,240,240,240,240,224,208,208,208
;char 1(char_output_no=31)(char_no=36) has x_offset=528 in the png and is 8 pixels wide
char_31_nybble_0:     !byte 12,0,8,4,1,1,1,13,13,13,13,13,13,13,13,13,13,13,13,13,13
char_31_nybble_0_msb: !byte 192,0,128,64,16,16,16,208,208,208,208,208,208,208,208,208,208,208,208,208,208
;char -(char_output_no=32)(char_no=31) has x_offset=472 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_32_nybble_0:     !byte 15,15,15,15,15,15,15,15,15,15,15,14,13,13,13,15,15,15,15,15,15
char_32_nybble_0_msb: !byte 240,240,240,240,240,240,240,240,240,240,240,224,208,208,208,240,240,240,240,240,240
char_32_nybble_1:     !byte 15,15,15,15,15,15,15,15,15,15,11,7,7,7,15,15,15,15,15,15,15
char_32_nybble_1_msb: !byte 240,240,240,240,240,240,240,240,240,240,176,112,112,112,240,240,240,240,240,240,240
;char ((char_output_no=33)(char_no=32) has x_offset=488 in the png and is 8 pixels wide
char_33_nybble_0:     !byte 14,0,3,3,3,7,7,7,7,7,7,7,7,7,7,7,3,3,3,0,1
char_33_nybble_0_msb: !byte 224,0,48,48,48,112,112,112,112,112,112,112,112,112,112,112,48,48,48,0,16
;char )(char_output_no=34)(char_no=33) has x_offset=496 in the png and is 8 pixels wide
char_34_nybble_0:     !byte 8,0,12,12,12,13,13,13,13,13,13,13,13,13,13,13,12,12,12,0,7
char_34_nybble_0_msb: !byte 128,0,192,192,192,208,208,208,208,208,208,208,208,208,208,208,192,192,192,0,112
;char "(char_output_no=35)(char_no=34) has x_offset=504 in the png and is 16 pixels wide
char_35_nybble_0:     !byte 15,3,3,3,3,3,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
char_35_nybble_0_msb: !byte 240,48,48,48,48,48,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240
char_35_nybble_1:     !byte 15,3,3,3,3,3,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
char_35_nybble_1_msb: !byte 240,48,48,48,48,48,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240
;char '(char_output_no=36)(char_no=35) has x_offset=520 in the png and is 8 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_36_nybble_0:     !byte 15,3,3,3,3,3,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
char_36_nybble_0_msb: !byte 240,48,48,48,48,48,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240
;char 2(char_output_no=37)(char_no=37) has x_offset=536 in the png and is 16 pixels wide
char_37_nybble_0:     !byte 13,2,1,1,1,0,3,15,15,15,15,13,1,1,3,3,3,3,2,1,13
char_37_nybble_0_msb: !byte 208,32,16,16,16,0,48,240,240,240,240,208,16,16,48,48,48,48,32,16,208
char_37_nybble_1:     !byte 4,8,8,4,4,13,12,12,12,12,4,7,7,15,15,15,13,13,5,5,5
char_37_nybble_1_msb: !byte 64,128,128,64,64,208,192,192,192,192,64,112,112,240,240,240,208,208,80,80,80
;char 3(char_output_no=38)(char_no=38) has x_offset=552 in the png and is 16 pixels wide
char_38_nybble_0:     !byte 13,2,1,1,1,0,15,15,15,15,15,15,15,15,15,15,15,3,2,1,13
char_38_nybble_0_msb: !byte 208,32,16,16,16,0,240,240,240,240,240,240,240,240,240,240,240,48,32,16,208
char_38_nybble_1:     !byte 0,8,8,4,4,1,13,13,12,12,4,4,4,12,13,13,12,0,4,4,7
char_38_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,192,192,64,64,64,192,208,208,192,0,64,64,112
;char _(char_output_no=39)(char_no=54) has x_offset=776 in the png and is 8 pixels wide
char_39_nybble_0:     !byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,0,5,5
char_39_nybble_0_msb: !byte 240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,0,80,80
;char 4(char_output_no=40)(char_no=39) has x_offset=568 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_40_nybble_0:     !byte 15,3,3,7,7,7,7,7,3,3,3,2,1,13,15,15,15,15,15,15,15
char_40_nybble_0_msb: !byte 240,48,48,112,112,112,112,112,48,48,48,32,16,208,240,240,240,240,240,240,240
char_40_nybble_1:     !byte 12,15,12,12,12,13,13,13,13,13,9,5,5,13,13,13,13,13,13,13,12
char_40_nybble_1_msb: !byte 192,240,192,192,192,208,208,208,208,208,144,80,80,208,208,208,208,208,208,208,192
;char 5(char_output_no=41)(char_no=40) has x_offset=584 in the png and is 16 pixels wide
char_41_nybble_0:     !byte 13,6,5,5,5,7,7,7,3,3,1,1,13,15,15,3,3,3,2,1,13
char_41_nybble_0_msb: !byte 208,96,80,80,80,112,112,112,48,48,16,16,208,240,240,48,48,48,32,16,208
char_41_nybble_1:     !byte 0,8,8,4,15,15,15,15,15,15,15,4,4,4,13,13,12,0,4,4,7
char_41_nybble_1_msb: !byte 0,128,128,64,240,240,240,240,240,240,240,64,64,64,208,208,192,0,64,64,112
;char 6(char_output_no=42)(char_no=41) has x_offset=600 in the png and is 16 pixels wide
char_42_nybble_0:     !byte 13,2,1,1,1,4,7,7,7,7,6,5,5,7,7,7,3,3,2,1,13
char_42_nybble_0_msb: !byte 208,32,16,16,16,64,112,112,112,112,96,80,80,112,112,112,48,48,32,16,208
char_42_nybble_1:     !byte 0,8,8,4,4,1,1,12,15,15,15,8,4,4,13,13,12,0,4,4,7
char_42_nybble_1_msb: !byte 0,128,128,64,64,16,16,192,240,240,240,128,64,64,208,208,192,0,64,64,112
;char 7(char_output_no=43)(char_no=42) has x_offset=616 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_43_nybble_0:     !byte 13,2,1,1,1,0,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
char_43_nybble_0_msb: !byte 208,32,16,16,16,0,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240
char_43_nybble_1:     !byte 0,8,8,4,4,1,13,13,13,13,9,5,5,5,13,13,13,13,13,13,12
char_43_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,208,208,144,80,80,80,208,208,208,208,208,208,192
;char 8(char_output_no=44)(char_no=43) has x_offset=632 in the png and is 16 pixels wide
char_44_nybble_0:     !byte 13,2,1,1,5,4,7,7,7,7,0,1,13,1,1,3,3,3,2,1,13
char_44_nybble_0_msb: !byte 208,32,16,16,80,64,112,112,112,112,0,16,208,16,16,48,48,48,32,16,208
char_44_nybble_1:     !byte 0,8,8,4,4,1,13,13,12,12,0,4,4,4,13,13,12,0,4,4,7
char_44_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,192,192,0,64,64,64,208,208,192,0,64,64,112
;char 9(char_output_no=45)(char_no=44) has x_offset=648 in the png and is 16 pixels wide
char_45_nybble_0:     !byte 13,2,1,1,5,4,7,7,7,7,2,1,13,15,15,3,3,3,2,1,13
char_45_nybble_0_msb: !byte 208,32,16,16,80,64,112,112,112,112,32,16,208,240,240,48,48,48,32,16,208
char_45_nybble_1:     !byte 0,8,8,4,4,1,13,13,13,13,13,9,5,5,13,13,12,0,4,4,7
char_45_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,208,208,208,144,80,80,208,208,192,0,64,64,112
;char 0(char_output_no=46)(char_no=45) has x_offset=664 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_46_nybble_0:     !byte 13,2,1,1,1,4,7,7,3,3,3,3,3,3,3,3,3,3,2,1,13
char_46_nybble_0_msb: !byte 208,32,16,16,16,64,112,112,48,48,48,48,48,48,48,48,48,48,32,16,208
char_46_nybble_1:     !byte 0,8,8,4,4,1,13,13,13,13,13,13,13,13,13,13,12,0,4,4,7
char_46_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,208,208,208,208,208,208,208,208,192,0,64,64,112
;char  (char_output_no=47)(char_no=46) has x_offset=680 in the png and is 16 pixels wide
char_47_nybble_0:     !byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
char_47_nybble_0_msb: !byte 240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240
char_47_nybble_1:     !byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
char_47_nybble_1_msb: !byte 240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240
;char &(char_output_no=48)(char_no=47) has x_offset=696 in the png and is 16 pixels wide
char_48_nybble_0:     !byte 15,15,15,15,15,15,15,12,12,12,15,13,1,1,3,3,3,3,2,1,13
char_48_nybble_0_msb: !byte 240,240,240,240,240,240,240,192,192,192,240,208,16,16,48,48,48,48,32,16,208
char_48_nybble_1:     !byte 15,15,15,15,15,15,7,5,12,12,4,7,7,15,12,13,12,0,4,4,7
char_48_nybble_1_msb: !byte 240,240,240,240,240,240,112,80,192,192,64,112,112,240,192,208,192,0,64,64,112
;char %(char_output_no=49)(char_no=48) has x_offset=712 in the png and is 16 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_49_nybble_0:     !byte 13,2,1,1,5,4,7,7,7,7,0,13,15,15,15,15,13,1,1,0,15
char_49_nybble_0_msb: !byte 208,32,16,16,80,64,112,112,112,112,0,208,240,240,240,240,208,16,16,0,240
char_49_nybble_1:     !byte 0,8,8,4,4,1,13,13,12,12,0,4,15,15,15,4,4,4,15,15,15
char_49_nybble_1_msb: !byte 0,128,128,64,64,16,208,208,192,192,0,64,240,240,240,64,64,64,240,240,240
;char #(char_output_no=50)(char_no=49) has x_offset=728 in the png and is 16 pixels wide
char_50_nybble_0:     !byte 15,15,15,15,15,15,3,3,3,3,3,15,14,1,1,3,3,3,2,1,13
char_50_nybble_0_msb: !byte 240,240,240,240,240,240,48,48,48,48,48,240,224,16,16,48,48,48,32,16,208
char_50_nybble_1:     !byte 15,15,15,15,15,15,3,3,3,3,15,4,4,4,13,13,12,0,4,4,7
char_50_nybble_1_msb: !byte 240,240,240,240,240,240,48,48,48,48,240,64,64,64,208,208,192,0,64,64,112
;char /(char_output_no=51)(char_no=50) has x_offset=744 in the png and is 8 pixels wide
char_51_nybble_0:     !byte 15,0,0,0,0,0,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
char_51_nybble_0_msb: !byte 240,0,0,0,0,0,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240
;char =(char_output_no=52)(char_no=51) has x_offset=752 in the png and is 8 pixels wide
char_52_nybble_0:     !byte 15,15,15,15,15,0,5,5,4,4,0,15,15,15,15,15,15,15,15,15,15
char_52_nybble_0_msb: !byte 240,240,240,240,240,0,80,80,64,64,0,240,240,240,240,240,240,240,240,240,240
;char +(char_output_no=53)(char_no=52) has x_offset=760 in the png and is 8 pixels wide
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
  !byte 0 ;wasting some bytes to make sure that no page break occurs within one char fontdata
char_53_nybble_0:     !byte 15,15,15,15,15,15,15,15,15,15,0,1,5,5,1,0,15,15,15,15,15
char_53_nybble_0_msb: !byte 240,240,240,240,240,240,240,240,240,240,0,16,80,80,16,0,240,240,240,240,240
;char *(char_output_no=54)(char_no=53) has x_offset=768 in the png and is 8 pixels wide
char_54_nybble_0:     !byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,0,0,0,0,0,15
char_54_nybble_0_msb: !byte 240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,0,0,0,0,0,240
  !align 255,0,0
fontdata_width_in_nybbles: !byte 2,2,2,2,2,2,2,2,2,1,2,2,2,3,2,2,2,2,2,2,2,2,2,3,2,2,2,2,2,2,2,2,2,1,2,2,2,2,2,1,1,1,1,1,1,2,1,1,2,1,2,2,2,2,2,2,2,2,1,2,2,1,2,2
fontdata_lsb: !byte <char_47_nybble_0,<char_00_nybble_0,<char_01_nybble_0,<char_02_nybble_0,<char_03_nybble_0,<char_04_nybble_0,<char_05_nybble_0,<char_06_nybble_0,<char_07_nybble_0,<char_08_nybble_0,<char_10_nybble_0,<char_11_nybble_0,<char_12_nybble_0,<char_13_nybble_0,<char_14_nybble_0,<char_16_nybble_0,<char_17_nybble_0,<char_18_nybble_0,<char_19_nybble_0,<char_20_nybble_0,<char_21_nybble_0,<char_22_nybble_0,<char_23_nybble_0,<char_25_nybble_0,<char_24_nybble_0,<char_26_nybble_0,<char_28_nybble_0,<char_47_nybble_0,<char_47_nybble_0,<char_47_nybble_0,<char_47_nybble_0,<char_47_nybble_0,<char_47_nybble_0,<char_27_nybble_0,<char_35_nybble_0,<char_50_nybble_0,<char_47_nybble_0,<char_49_nybble_0,<char_48_nybble_0,<char_36_nybble_0,<char_33_nybble_0,<char_34_nybble_0,<char_54_nybble_0,<char_53_nybble_0,<char_15_nybble_0,<char_32_nybble_0,<char_09_nybble_0,<char_51_nybble_0,<char_46_nybble_0,<char_31_nybble_0,<char_37_nybble_0,<char_38_nybble_0,<char_40_nybble_0,<char_41_nybble_0,<char_42_nybble_0,<char_43_nybble_0,<char_44_nybble_0,<char_45_nybble_0,<char_30_nybble_0,<char_47_nybble_0,<char_47_nybble_0,<char_52_nybble_0,<char_47_nybble_0,<char_29_nybble_0
fontdata_msb: !byte >char_47_nybble_0,>char_00_nybble_0,>char_01_nybble_0,>char_02_nybble_0,>char_03_nybble_0,>char_04_nybble_0,>char_05_nybble_0,>char_06_nybble_0,>char_07_nybble_0,>char_08_nybble_0,>char_10_nybble_0,>char_11_nybble_0,>char_12_nybble_0,>char_13_nybble_0,>char_14_nybble_0,>char_16_nybble_0,>char_17_nybble_0,>char_18_nybble_0,>char_19_nybble_0,>char_20_nybble_0,>char_21_nybble_0,>char_22_nybble_0,>char_23_nybble_0,>char_25_nybble_0,>char_24_nybble_0,>char_26_nybble_0,>char_28_nybble_0,>char_47_nybble_0,>char_47_nybble_0,>char_47_nybble_0,>char_47_nybble_0,>char_47_nybble_0,>char_47_nybble_0,>char_27_nybble_0,>char_35_nybble_0,>char_50_nybble_0,>char_47_nybble_0,>char_49_nybble_0,>char_48_nybble_0,>char_36_nybble_0,>char_33_nybble_0,>char_34_nybble_0,>char_54_nybble_0,>char_53_nybble_0,>char_15_nybble_0,>char_32_nybble_0,>char_09_nybble_0,>char_51_nybble_0,>char_46_nybble_0,>char_31_nybble_0,>char_37_nybble_0,>char_38_nybble_0,>char_40_nybble_0,>char_41_nybble_0,>char_42_nybble_0,>char_43_nybble_0,>char_44_nybble_0,>char_45_nybble_0,>char_30_nybble_0,>char_47_nybble_0,>char_47_nybble_0,>char_52_nybble_0,>char_47_nybble_0,>char_29_nybble_0

;SOME values that we'll need to transfer into textrotator:
  !byte <scrolltext
  !byte >scrolltext
transfer_lsb_srcpoi: !byte 0,0
transfer_msb_srcpoi: !byte 0,0
transfer_sprite_sprite_offset: !byte 0
transfer_sprite_set: !byte 0
transfer_plot_next_char: !byte 0
transfer_nof_nybbles_left: !byte 0

;!convtab / !pet / !raw / !scr / !scrxor / !text
;...for converting and outputting strings.

; These are the valid chars in this scroller:
;  !scr "abcdefgh"
;  !scr "ijklmnop"
;  !scr "qrstuvwx"
;  !scr "yz.,!?:-"
;  !scr "()\"'1234"
;  !scr "567890 &"
;  !scr "%#/=+*_"

;;The order of the chars in Commodore 64 screen codes:
;@ABCDEFG
;HIJKLMNO
;PQRSTUVW
;XYZ[£]^<
; !"#$%&'
;()*+,-./
;01234567
;89:;<=>?


; Make sure that there are no page breaks in the font data _inside_ of those 21 bytes. So add an additional zero here and there when the continuous streak of font data crosses a page break.
; Not allowed to add a zero "inside" a char.
; Chars can be in any order in memory, though.
; An "A" uses 84 bytes in memory
; An "M" uses 126 bytes in memory
; An "!" uses 42 bytes in memory



;******************************************** GHOSTSCROLLER:

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

  lda desired_ghostd016+1
  and #$f
  clc
  adc #$10
  sta ghost_d002+1
  clc
  adc #$30
  sta ghost_d004+1
  clc
  adc #$30
  sta ghost_d006+1
  clc
  adc #$30
  sta ghost_d008+1
  clc
  adc #$30
  sta ghost_d00a+1
  clc
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
;Also write in to the intro IRQ:
  sta ghost_msb_srcpoi2+1
  lda ghost_lsb_srcpoi+2
  adc #0
  sta ghost_msb_srcpoi+2
;Also write in to the intro IRQ:
  sta ghost_msb_srcpoi2+2
;this is a jmp:
  bne find_nybble_lsb
get_a_new_char:
  ldy #0
  lda (ghost_textpoi),y
  tay
  bne no_wrap_scrolltext
  lda #>scrolltext
  sta ghost_textpoi+1
  lda #<scrolltext
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
;Also write into the intro scroller:
  sta ghost_lsb_srcpoi2+1
  lda ghost_msb_srcpoi+2
  adc #0
  sta ghost_lsb_srcpoi+2
;Also write into the intro scroller:
  sta ghost_lsb_srcpoi2+2
;this is a jmp:
  bne done_finding_nybbles
get_a_new_char2:
  ldy #0
  lda (ghost_textpoi),y
  tay
  bne no_wrap_scrolltext2
  lda #>scrolltext
  sta ghost_textpoi+1
  lda #<scrolltext
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
  sec
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
  clc
sprite_block:
  adc #0
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











do_ghostscroller_intro:
  lda desired_ghostd016+1
  sec
  sbc ghost_speed+1
  bcs no_change_set_i
  ldy #3
  sty plot_next_char+1
  ldx sprite_set+1
  inx
  cpx #3
  bne no_wrap_set_i
  ldx #0
  ldy sprite_sprite_offset+1
  iny
  cpy #8
  bne no_wrap_sprite_sprite_offset_i
  ldy #0
no_wrap_sprite_sprite_offset_i:
  sty sprite_sprite_offset+1
no_wrap_set_i:
  stx sprite_set+1
no_change_set_i:
  and #$f
  sta desired_ghostd016+1

  lda desired_ghostd016+1
  and #$f
  clc
  adc #$10
  sta ghost2_d002+1
  clc
  adc #$30
  sta ghost2_d004+1
  clc
  adc #$30
  sta ghost2_d006+1
  clc
  adc #$30
  sta ghost2_d008+1
  clc
  adc #$30
  sta ghost2_d00a+1
  clc
  adc #$30
  sta ghost2_d00c+1
  clc
  adc #$30
  sta ghost2_d00e+1
;  lda #$c0
;  sta ghost2_d010+1


plot_next_char_i:
  ldx plot_next_char+1
  dex
  bpl yes_plot_a_char_i
  jmp no_need_to_plot_a_char_i
yes_plot_a_char_i:
  stx plot_next_char+1

  cpx #2
  beq get_next_text_char_i
  jmp no_need_to_get_next_text_char_i
get_next_text_char_i:
  ldx nof_nybbles_left+1
  dex
  beq get_a_new_char_i
just_get_the_next_nybble_i:
  lda ghost_lsb_srcpoi2+1
  clc
  adc #63
  sta ghost_msb_srcpoi2+1
  lda ghost_lsb_srcpoi2+2
  adc #0
  sta ghost_msb_srcpoi2+2
;this is a jmp:
  bne find_nybble_lsb_i
get_a_new_char_i:
  ldy #0
  lda (ghost_textpoi),y
  tay
  bne no_wrap_scrolltext_i
  lda #>scrolltext
  sta ghost_textpoi+1
  lda #<scrolltext
  sta ghost_textpoi
  ldy #$20
no_wrap_scrolltext_i:
  inc ghost_textpoi
  bne no_inc2_i
  inc ghost_textpoi+1
no_inc2_i:
  lda fontdata_lsb,y
  clc
  adc #21   ; to get the "msb" version of this nybble
  sta ghost_msb_srcpoi2+1
  lda fontdata_msb,y
  adc #0
  sta ghost_msb_srcpoi2+2
  lda fontdata_width_in_nybbles,y
  tax

find_nybble_lsb_i:
  dex
  beq get_a_new_char2_i
just_get_the_next_nybble2_i:
  lda ghost_msb_srcpoi2+1
  clc
  adc #21
  sta ghost_lsb_srcpoi2+1
  lda ghost_msb_srcpoi2+2
  adc #0
  sta ghost_lsb_srcpoi2+2
;this is a jmp:
  bne done_finding_nybbles_i
get_a_new_char2_i:
  ldy #0
  lda (ghost_textpoi),y
  tay
  bne no_wrap_scrolltext2_i
  lda #>scrolltext
  sta ghost_textpoi+1
  lda #<scrolltext
  sta ghost_textpoi
  ldy #$20
no_wrap_scrolltext2_i:
  inc ghost_textpoi
  bne no_inc3_i
  inc ghost_textpoi+1
no_inc3_i:
  lda fontdata_lsb,y
  sta ghost_lsb_srcpoi2+1
  lda fontdata_msb,y
  sta ghost_lsb_srcpoi2+2
  lda fontdata_width_in_nybbles,y
  tax

done_finding_nybbles_i:
  stx nof_nybbles_left+1

no_need_to_get_next_text_char_i:
; Determine which set we will plot into:
  ldx plot_next_char+1
  lda set_pointers_msb_table,x
  sta which_set_to_plot_into_i+1
  stx set_offset_i+1

; use sprite_sprite_offset * 3 + sprite_set + a_constant   and then wrap that modulo 24 to figure out
  ldx sprite_sprite_offset+1
  lda table_of_x3,x
  clc
  adc sprite_set+1
  clc
  adc #20
  sec
set_offset_i:
  sbc #0
  cmp #24
  bcc is_small_already_i
  sec
  sbc #24
is_small_already_i:
  ; Now a is "the column that we shall write into"
  ; Let's translate that into a sprite pointer.
  tax
  lda sprite_lsb_table,x
  sta ghost_destpoi
  lda sprite_msb_table,x
  clc
which_set_to_plot_into_i:
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
  sta sprite_block_i+1

  ldx #0
  ldy sprite_sprite_offset+1
next_sprite_pointer_i:
  tya
  and #$7
  clc
sprite_block_i:
  adc #0
  sta ghostscreen_intro+$3f9,x
  iny
  inx
  cpx #7
  bne next_sprite_pointer_i

no_need_to_plot_a_char_i:
  rts





















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


; The stand-alone IRQ that will run the ghostscroller during transitions:

;setup_ghostIRQ:
;  lda #$f7
;  sta $d012
;  lda $d011
;  and #$7f
;  sta $d011
;  lda #<irq_ghost_0
;  sta $fffe
;  lda #>irq_ghost_0
;  sta $ffff
;  rts

irq_ghost_0:
  sta save_aghost_0+1
  lda $d011
  and #7
first_time_dont_open_border:
  ora #$98
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
ghost2_d002:
  lda #$81
  sta $d002
ghost2_d004:
  lda #$82
  sta $d004
ghost2_d006:
  lda #$83
  sta $d006
ghost2_d008:
  lda #$84
  sta $d008
ghost2_d00a:
  lda #$85
  sta $d00a
ghost2_d00c:
  lda #$86
  sta $d00c

  lda #$90
  sta first_time_dont_open_border+1

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
  nop
  nop

  lda desired_ghostd016+1
  and #7
  ora #$c0
  sta $d016
  lda $d011
  and #7
  ora #$18
  sta $d011

  lda #$80
  sta $d018 ;screen at $6000, charset at $4000
;  lda #0
  sta $d026
  bit $00
ghost2_d010:
  lda #$c0
  sta $d010
ghost2_d00e:
  lda #$87
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
  lda char_46_nybble_0_msb,x   ;4
ghost_lsb_srcpoi2:
  ora char_46_nybble_0,x       ;4
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

  ; Not x-expanded anymore:
  lda #0
  sta $d01d

  jsr preintro_fillchars
  jsr do_ghostscroller_intro
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
save_yghost_1:
  ldy #0
save_xghost_1:
  ldx #0
  pla
  rti

irq_ghost_2:
  sta save_aghost2+1
  stx save_xghost2+1
  lda #<irq_ghost_0
  sta $fffe
  lda #>irq_ghost_0
  sta $ffff
  lda #$c0
  sta $d016
  lda #$0     ;This is the transition colour from the previous part.
  sta $d021

  lda #$f9
  sta $d012
switch_to_demo_now:
  lda #0
  beq dont_switch_to_demo_now
;Last frame stuff to do when switching into the demo:
;Transfer the state of do_ghostscroller_intro into do_ghostscroller, to make the transition from 
;intro code for ghostscroller ok in demo:
  lda ghost_lsb_srcpoi2+1
  sta ghost_lsb_srcpoi+1
  lda ghost_lsb_srcpoi2+2
  sta ghost_lsb_srcpoi+2
  lda ghost_msb_srcpoi2+1
  sta ghost_msb_srcpoi+1
  lda ghost_msb_srcpoi2+2
  sta ghost_msb_srcpoi+2
  lda #0
  sta task_running
  sta task_pending
  lda #$f7
  sta $d012
  lda $d011
  and #$7f
  sta $d011
  lda #<irq_7b
  sta $fffe
  lda #>irq_7b
  sta $ffff

  ldx #7
same_sprites:
  lda ghostscreen_intro+$3f8,x ;$6000
  sta ghostscreen+$3f8,x ;$4400
  dex
  bpl same_sprites
  lda ghost2_d002+1
  sta ghost_d002+1
  lda ghost2_d004+1
  sta ghost_d004+1
  lda ghost2_d006+1
  sta ghost_d006+1
  lda ghost2_d008+1
  sta ghost_d008+1
  lda ghost2_d00a+1
  sta ghost_d00a+1
  lda ghost2_d00c+1
  sta ghost_d00c+1
  lda ghost2_d00e+1
  sta ghost_d00e+1
  lda ghost2_d010+1
  sta ghost_d010+1

dont_switch_to_demo_now:
  inc safe_to_move_under_d000_now+1

  asl $d019
save_aghost2:
  lda #0
save_xghost2:
  ldx #0
  rti


























scrolltext:
; & is an & sign
; % is an "o with a line under" in the font
; # is an "ö"
; / is a ball highest
; = is a ball upper
; + is a ball lower
; * is a ball lowest

  !scr " your commodore 64 got upgraded to next level by performers. your 41 year old computer does it all, again - pex mahoney tufvesson here and we've got the usual mix of chess zoomers, chiptunes, samples, alpha channels and nostalgia upgraded to next level - don't worry, we're stuck with 16 colours, 0.00000005 gigabyte of memory and this 0.001 ghz computer from 1982 to make you happy! no need to ask for more - next up is the 100 best moments of our lives - turn the disk when you're ready! beware of full nostalgia overload - we warn you! fun fact: we're still finding undocumented traits in our favourite childhood toy! you're watching next level by performers, released at the x party in 2023!"
  !scr " this demo was brought together through collaborative love of, if i got it right, 19 dedicated demo scene veterans: lman thcm bitbreaker pex knut yps redcrab devilock linus jammer facet axis veto peiselulli joe dk ptoing trap & krill. but that is actually quite far from the truth. the next level is standing on the shoulders of giants. 40 years of demo scene experience. we would not be here if it wasn't for a lot of scene heroes that gradually helped out in building the tools and the knowledge on how to use and abuse our favourite toy from our childhood. if i, pex mahoney, should try to make a list of them, it would be incomplete."
  !scr " the c64 demo scene is a big family, where we live, love and investigate the most hard-to-exploit hardware quirks for our demo making purposes."
  !scr " performer's next level demo is the collaborative result of five years of development using modern technology in creating visuals and sounds for pure entertainment only. performers is a team of dedicated enthusiasts with decades of experience with demo coding. please try this at home, we'll be happy to help you understand what we do and why, and there's plenty of friendly faces in the demo scene community. however, do note that demo making at this level is nothing you can accomplish using chatgpt or stack overflow. we do extreme optimizations for ancient hardware."
  !scr " what you see on this screen is the egg of columbus: a brilliant idea or discovery that seems simple or easy after the fact. the c64 demo scene is full of them. that's why the c64 scene is still alive and kicking, and that's why we're still in the game!"
  !scr " ?out of memory error  / pex mahoney tufvesson signing off!"


scrolltext_end:
  !byte 0



