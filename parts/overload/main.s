  !cpu 6510
  !initmem $00

;### OVERLOAD by Pex "Mahoney" Tufvesson

;DISABLE_STABLE = 1
;DEBUG = 1

; * Erase text in charset nicely in frame #25 - #75

; * greetingstext is gone for 1 frame when switching from one game to another. Probably we haven't gotten the time to setup the sprite multiplexer yet. It is gone on the first frame of the next game.
;#03 - One sprtext is missing. Old sprtextdata is seen.

; Manual fixes:
;#13 - the number 13 is overwritten in the upper right corner.
;#16 - GROGSREV_3 lost wheel is visible outside of the playfield in the black below.
;#19 - TAPPER Text @ABCDEFG / HIJKLMNO in the middle banner on the wall should probably be something else.
;#22 - ARCHON 2. d010 seems to be wrong. The blinking dot should probably be blinking in the right center dot as well. (not at the left edge of the screen). 215 tracked registers. Too many?
;#26 - DRUID2   There is a completely black big sprite to the right that probably shouldn't be there.
;#26 - DRUID2 One byte of sprite garbage at the top off the sprites in the three upper left enemies. It's one byte that is $ff that should be $00 in one of the animation frames.
;#30 - KILLWATT game counter is hidden by border. If 40 char wide, errors in rightmost column.
;#36 - MARBLE Sprite garbage in the lowest row of the ball at start. At the end, sprite is completely wrong contents.
;#77 - hovver. No nice place to put text in

; Low priority fixes:
;#83 Attack mutant camels: "Greetingpart" text is too many sprites for the multiplexer.
;* Need to move the xdest and ydest and sprcol and charcol backwards half a game in all the files to make sure that we don't require next game to be ready at frame #75
;  Or, make them into a stand-alone list to be in memory all the time. 4*200 bytes


; * Check warnings and ERROR in logs
; d016 errors to check manually:
; 64: ###ERROR: game RASTAN, xoffset=4, addr=d008, value=-4


; * Packer d016 xoffset
;    sprite_xoffset_due_to_d016 = vic2_regs[0x16] & 0x07
;    Detect if it goes wrong in any game
;    Fix d010 when doing this

; * destination x0 and y1 and sprcol shall be used "earlier". So, in order to use this, need to move all these one step in the packer.
;   ...we don't know the 4 values for "next" game since we have not loaded it completely yet at frame50 of the current game.

; * Print sprtext "slower", and move sprtext_plotpos smooth anyway. When sprtext is too long, plot at full speed.

;### Known bugs:
; * When the sprite text is "too wide" and there's not enough free characters in the font, graphics glitches will occur
;   when the sprites are copied into the charset.

;### Missing features:
; * Gradual removal of copied text in chars to make room for the next one.
; * Copying of sprite text "at the start of each game"
; * Some kind of drums/music at the start for the silent games.
;* End the demo with Rambo3 tape loading of start image.
;  Grab the music, but show the bitmap gfx from e000-
;  Make a special display list for drawing this into chars.
;  Like from 02:16 into this video: https://www.youtube.com/watch?v=6NmknHO0J4I
;  Could grab the whole Ocean Loader song into memory, and place a sprite scroller on top of the screen
;  "Turn disk", but with the rules of the game-naming competition explained.
;  Print the whole multicol image as the loader did while the scroller rolls.


; Description:
; This is a replayer of recorded C64 games. Or a greetings part. Whatever.
; The recording is done in an Ubuntu virtual machine, with a modified version of Vice,
; Doing a "freeze" of memory contents and IO registers at one instance in time while playing a game,
; and then _every single_ memory write is traced and saved until another "freeze" is done, and all
; memory writes are stored in a binary format together with clock cycle "time".

; A python encoder takes 100 such recordings, and compresses them into a format that the code below
; is able to unpack in real-time with sufficient speed for disk loading at the same time.
; Each game snippet lasts 100 frames, which is 2 seconds.

; The encoder supports:
;  character mode, hires or multicolour
;  a single 1000-byte screen
;  d800 colours
;  sprites
;  animated sprites
;  changes to the screen
;  changes to the screen colours
;  changes to the charset
;  changes to the used sprites
;  SID music and sound effects

; The encoder does not support:
;  hires bitmap
;  multicolour bitmap
;  rastersplits
;  sprite multiplexers
;  2x SID songs
;  CIA SID timing (aka non-50Hz SID music)
;  Using the default C64 charset

;### Known issues:
;  Initial SID ADSR will be wrong. I cannot reproduce the SID state instantly from a freeze,
;  so any kind of sustained sounds will be wrong.

;### Features:
; The decoder switches from one game to another instantly without blanking the screen inbetween.
; On top of the recorded game is a sprite multiplexer showing up to 6 x-expanded sprites of text.
; The sprites are copied into chars and written into the screen one per second.

; The games are double buffered in bank #1 ($4000-$7fff)
; While a game is shown at the low memory location, the next game is loaded into the high memory location.
; The low memory location is at least $3800-$4c00, but a game with loads of sprites will use higher than $4c00.
;    And a game with loads of dynamic events will use mem lower than $3800.
; The high memory location is at least $7400-$8800, but a game with loads of sprites will use lower than $7400.
;    And a game with loads of dynamic events will user mem higher than $8800.
; The packer knows which games are "expensive" and what memory ranges a certain game uses.

; While a game is replayed, all writes to $d000 are also written into saved_d000 memory+$00-$2f.
; This makes the sprite text multiplexing much easier, since original $d000-$d02f-values can be used without saving them first.

; There are 100 games, which means 200 lines of text.


;### Things that easily goes wrong:
;   I'm not allowed to write into an area where the disk is loading right now. Decrunching goes wrong if I modify
;   memory that is currently loaded. So erasing of sprites and chars need to be done at the right time.
;   No clue on how much margin I have with disk loading speed. Right now it works, but I don't know why.


;### How to record a game:
; * Run the ubuntu virtual machine on pix.
; Open a Terminal on the virtual ubuntu:
; sudo vmhgfs-fuse .host:/ubuntu /mnt/ubuntu -o allow_other -o uid=1000
; cd /mnt/ubuntu/vice-3.3/src
  ; make -j7
; cd /mnt/ubuntu/games
; ../vice-3.3/src/x64sc -directory /mnt/ubuntu/c64 --autostart THINGSPR.D64 
; alt-W warp mode
; Play the game
; alt-E when recording shall start. -> snapshot0.vsf
; alt-E when recording is done.     -> snapshot1.vsf
;    ...is a >300kB file with the logging in it.
; alt-Q to quit
; * rename snapshot files and archive after vice has been run
; mv /mnt/ubuntu/games/snapshot0 new/THINGSPR.s0
; mv /mnt/ubuntu/games/snapshot1 new/THINGSPR.s1
; These files can be found in MacOS at /Volumes/Macintosh HD/Users/pex/Documents/c64/ubuntu/games/new


;### How to build:
;* git pull
;cd /Users/pex/Documents/c64/x2020/git/performers/current/mahoney/overload/packer
;./run_packer.py
;make
;
; Remove ; in front of DEBUG-section in the "; DEBUG: For compensating x and y in sprites when copying them to chars:"-section.
; run the whole part with warp speed in vice:
;cd /Users/pex/Documents/c64/x2020/git/performers/current/link
;make vicepex
; copy the contents of $f000-$f1ff into text.
;  $f000-$f0ff   into the yposdest_minus_ypos:
;  $f100-$f1ff   into the xposdest_minus_xpos:
; add the ; in front of the DEBUG-section again
; build again
;cd /Users/pex/Documents/c64/x2020/git/performers/current/link
;make vicepex



; Memory map:
; $0002-$000d zp registers
; $000e-$00d9 zp unpacking code
; $00da-$00dc unused ZP
; $00dd-$00f2 ZP used by jammer's music "anythingGEOS_fc00"
; $00f3-$00fd bitfire zp, only needed during loading. Can be trashed after and before loading
; $00fe-$00ff zp reserved for music
; $0200-$03ff CODE disk loader
; $0400-$16ff CODE unpacker
; FREE MEM - trashed by "big" low games
;Largest low range=$2ea5-$5c00
; $34c6-$4c00 first game data "krakout"
; FREE MEM - trashed by high games
; FREE MEM - trashed by "big" high games
;Largest high range=$6b00-$94a9
; $a800-$a82f mirror of $d000-$d02f registers
; $a830-$af00 greetings text
; $af00-$b300 CODE sprite text
; FREE MEM
; $bb00-$bfff GFX sprite charset
; FREE MEM
; $f000-$f0c7 DEBUG correction values for char y destination. Not needed in production version
; $f100-$f1c7 DEBUG correction values for char x destination. Not needed in production version
; FREE MEM
; $fc00-$fff7 jammer's music routine.

; If I want a sprite mat, place it safely at $5c00 - $6b00 = 15*4 = 60 sprites.
; A sprite map of 7*8 = 56 sprites = 140 pixels high, 192 pixels wide. Multicolor.
; Make this "sparse" to make sure that there are "holes" for games to shine through.
; Need to find a couple of games in a row that doesn't use sprites.

col_copy_poi2 = $02
col_copy_poi = $04
char_copy_poi2 = $06
char_copy_poi = $08
tmp_lsb_lo = $0a
tmp_msb_lo = $0b
tmp_lsb_hi = $0c
tmp_msb_hi = $0d

ZP_CODE = $0e
; - $d9
; $da- unused

  !src "../../bitfire/loader/loader_acme.inc"
  !src "../../bitfire/macros/link_macros_acme.inc"

  *= $0400
main:
  sei
  cld
  lda #$35
  sta $01
  ldx #$ff
  txs
  lda #0
  sta $d015

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

  ldx #0
erase2:
  lda #$0
  sta $d800,x
  sta $d900,x
  sta $da00,x
  sta $dae8,x
  dex
  bne erase2

;Erase all sprite texts, since we don't load/decrunch these anymore:
  lda #0
  tax
clrall4:
  sta sprtext_spr0_lo,x ; = $6000
  sta sprtext_spr0_lo+$100,x ; = $6100
  sta sprtext_spr1_lo,x ; = $6200
  sta sprtext_spr1_lo+$100,x ; = $6300
  sta sprtext_spr0_hi,x ; = $6400
  sta sprtext_spr0_hi+$100,x ; = $6500
  sta sprtext_spr1_hi,x ; = $6600
  sta sprtext_spr1_hi+$100,x ; = $6700
  inx
  bne clrall4

wait_sync2:
  bit $d011
  bpl wait_sync2
wait_sync3:
  bit $d011
  bmi wait_sync3
  lda #$01
  sta $d01a

  ; init the music:
  lda #0
  jsr the_music

  lda $d011
  ora #$13
  sta $d011
  lda #$0
  sta $d020
  sta $d021
  lda #$c8
  sta $d016

;  lda #$ff
;  sta $d015
;  lda #$fe
;  sta $d01c ; no multicol
;  lda #$fe
;  sta $d017
;  sta $d01d
;  lda #$fe
;  sta $d01b
;  lda #$0
;  sta $d027
;  lda #$b
;  sta $d028
;  sta $d029
;  sta $d02a
;  sta $d02b
;  sta $d02c
;  sta $d02d
;  sta $d02e
;  lda #$f
;  sta $d025
;  lda #$c
;  sta $d026


  lda #$2      ;bank $4000-$7fff
  sta $dd00
  lda #$20     ;Charset at $4000-$47ff, $f800-$fff7, screens at $c800-$f7ff
  sta $d018

  jsr init_zp
;  jsr init_extra
  jsr prepare_anim2_lo
  jsr init_anim2_lo
  lda #>(SCREEN_LO + $3f8) ;=$4bf8
  jsr set_spritemat_scr

;freeze:
;  inc $d020
;  jmp freeze

  lda #1
  sta anim_enabled+1

  lda #<irq_bottom
  sta $fffe
  lda #>irq_bottom
  sta $ffff
  ;lda #$17
  ;sta $d011
  lda #$fa
  sta $d012
  lda #$7f
  sta $dc0d
  lda $dc0d
  lda #1
  sta $d01a  ;IRQ Mask Register: 1 = Interrupt Enabled
  asl $d019
  cli
ever:
  ; Load the next scene "hi".
; When anim_enabled+1 is == $7f, only show the sprtext or the sprite_mat, but don't animate the game.
; When anim_enabled+1 is == $ff, only show the sprtext or the sprite_mat, but don't animate the game.
; When anim_enabled+1 is >= $80, a HI-game is shown. Then, we are only allowed to write into HI mem > $6000
; When anim_enabled+1 is <= $7f, a LO-game is shown. Then, we are only allowed to write into LO mem < $6000
; Otherwise, the decrunching of loaded data WILL BE CORRUPT.
  jsr link_load_next_comp
  ;jsr link_load_next_raw
  ;jsr link_decomp
  jsr prepare_anim2_hi

  lda do_mat+1
  bne dont_clear_sprtext_hi
  jsr init_sprtext_hi
dont_clear_sprtext_hi:
;  inc loaded_game_no+1

wait_for_anim_end:
copy_mat:
  lda #0
  beq anim_done
  jsr copy_a_sprite_mat
  lda #0
  sta copy_mat+1
anim_done:
  lda #0
  beq wait_for_anim_end
  lda #0
  sta anim_done+1

  lda #$ff
  sta anim_enabled+1
  lda #0
  sta anim_frame_no+1

game_no:
  ldx #0
  inx
  stx game_no+1

  cpx #1
  beq init_music
  cpx #23
  bne no_init_music
init_music:
  lda #1
  sta music_enabled+1
  lda #0
  sta $d404
  sta $d40b
  sta $d412
no_init_music:
  cpx #6
  beq stop_music
  cpx #24
  bne no_stop_music
stop_music:
  lda #0
  sta music_enabled+1
  ; Restart the music in preparation for next time it will be used. But don't touch $d400-$d418.
;  txa
;  pha
;  lda #0
;  LDX #$15
;nullify_music_pointers:
;  STA $DD,X
;  DEX
;  BPL nullify_music_pointers
;  lda #0
;  sta $d404
;  sta $d40b
;  sta $d412
;  pla
;  tax
no_stop_music:
  cpx #50
  beq end_part
  jsr init_anim2_hi
  lda #$81
  sta anim_enabled+1

ever2:
  ; Load the next scene "lo".
; When anim_enabled+1 is >= $80, a HI-game is shown. Then, we are only allowed to write into HI mem > $6000
; When anim_enabled+1 is <= $7f, a LO-game is shown. Then, we are only allowed to write into LO mem < $6000
; Otherwise, the decrunching of loaded data WILL BE CORRUPT.
  jsr link_load_next_comp
  ;jsr link_load_next_raw
  ;jsr link_decomp
  jsr prepare_anim2_lo

  lda do_mat+1
  bne dont_clear_sprtext_lo
  jsr init_sprtext_lo
dont_clear_sprtext_lo:
;  inc loaded_game_no+1

wait_for_anim_end2:
  lda copy_mat+1
  beq anim_done2
  jsr copy_a_sprite_mat
  lda #0
  sta copy_mat+1
anim_done2:
  lda anim_done+1
  beq wait_for_anim_end2
  lda #0
  sta anim_done+1

  lda #$7f
  sta anim_enabled+1
  lda #0
  sta anim_frame_no+1

  jsr init_anim2_lo
  lda #1
  sta anim_enabled+1
  jmp ever


end_part:
  jmp hard_exit


erase_sprites_task:
;  ;We may interrupt ourself so, we need to store registers on the stack:
  pha
  txa
  pha
  tya
  pha

; We want to do these:
;  jsr init_sprtext_lo
;  jsr init_sprtext_hi
; But let's unroll them a little:

  lda #0
  tax
clrall:
  sta sprtext_spr0_lo,x ; = $6000
  sta sprtext_spr0_lo+$100,x ; = $6100
  sta sprtext_spr1_lo,x ; = $6200
  sta sprtext_spr1_lo+$100,x ; = $6300
  sta sprtext_spr0_hi,x ; = $6400
  sta sprtext_spr0_hi+$100,x ; = $6500
  sta sprtext_spr1_hi,x ; = $6600
  sta sprtext_spr1_hi+$100,x ; = $6700
  inx
  bne clrall

  ;We may interrupt ourself so, we need to grab registers from the stack:
  pla
  tay
  pla
  tax
  pla
  rti


toggle_spritemat_scr:
  lda #>(SCREEN_HI + $3f8) ;=$77f8
the_other:
  ldx #>(SCREEN_LO + $3f8) ;=$4bf8
  sta the_other+1
  stx toggle_spritemat_scr+1
set_spritemat_scr:
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
  rts

irq_bottom:
  sta save_a+1
  stx save_x+1
  sty save_y+1
;  lda $01
;  sta save01+1
;  lda #$35
;  sta $01
  asl $d019 ;ack IRQ

;  lda #$a
;  sta $d020

; This is the frame_no where we will present a new greet:
sprtext_frame_offset = 25

anim_enabled:
  ldx #0
  bne yes_do_anim
  jmp no_anim
yes_do_anim:

do_mat:
  lda #0
  bne do_spritemat
  jmp do_sprtext_anim

do_spritemat:
  ldx anim_frame_no+1
  inx
  stx anim_frame_no+1
  cpx #100
  bne dont_switch_game
  dec do_mat+1
  lda #1
  sta anim_done+1
  jsr toggle_spritemat_scr

;  jsr forced_goto_next_greet
dont_switch_game:

  lda #0
frames_until_sprmat_visible:
  ldx #0
  dex
  bpl not_visible_yet:
  inx
  lda #$ff
not_visible_yet:
  stx frames_until_sprmat_visible+1
  sta $d015

; The screen is 320 pixels wide
; The spritemap is 192 pixels wide
; = 512 pixels needs to scroll
; We have 3 games without sprites in a row = 300 frames
; But, the first 50 frames are for the last text to settle.
; So, there's 250 frames left.
; Let's scroll 2 pixels per frame.

;Also, we copy the sprite data into $5c00-$6a00 before it enters the screen.

; Check if the spritemap is not visible anymore:
  lda sprmat_7x+1
;cmp #$2 would be "when sprmat is completely to the left of the screen".
;But, we need to finish earlier to have time to do another sprtext before the screen is gone,
;so we terminate the sprtext a "little early".
  cmp #$8
  bne sprmat_still_visible
  lda sprmat_d010+1
  bmi sprmat_still_visible
end_sprmat:
  lda #0
  sta do_mat+1
;We want to trigger a task here to erase the sprites as soon as possible:
  lda #>erase_sprites_task
  pha
  lda #<erase_sprites_task
  pha
  lda #$00   ;flags
  pha
;This will be run instead of the ever-loop directly after this irq is finished.
  jmp skip_moving
sprmat_still_visible:

;This is "outside of screen": first_sprmat_x = $56
;But we need to be finished scrolling a little quicker, to have time to do one sprtext before switching to the next game.
;So let's start the sprmat slightly visible at the right edge of screen:
first_sprmat_x = $4e
sprmat_0x:
  lda #first_sprmat_x + 0*24
  sec
  sbc #2
  sta sprmat_0x+1
  sta $d000
  bcs no_eor0
  lda sprmat_d010+1
  eor #1
  sta sprmat_d010+1
no_eor0:
sprmat_1x:
  lda #first_sprmat_x + 1*24
  sec
  sbc #2
  sta sprmat_1x+1
  sta $d002
  bcs no_eor1
  lda sprmat_d010+1
  eor #2
  sta sprmat_d010+1
no_eor1:
sprmat_2x:
  lda #first_sprmat_x + 2*24
  sec
  sbc #2
  sta sprmat_2x+1
  sta $d004
  bcs no_eor2
  lda sprmat_d010+1
  eor #4
  sta sprmat_d010+1
no_eor2:
sprmat_3x:
  lda #first_sprmat_x + 3*24
  sec
  sbc #2
  sta sprmat_3x+1
  sta $d006
  bcs no_eor3
  lda sprmat_d010+1
  eor #8
  sta sprmat_d010+1
no_eor3:
sprmat_4x:
  lda #first_sprmat_x + 4*24
  sec
  sbc #2
  sta sprmat_4x+1
  sta $d008
  bcs no_eor4
  lda sprmat_d010+1
  eor #16
  sta sprmat_d010+1
no_eor4:
sprmat_5x:
  lda #first_sprmat_x + 5*24
  sec
  sbc #2
  sta sprmat_5x+1
  sta $d00a
  bcs no_eor5
  lda sprmat_d010+1
  eor #32
  sta sprmat_d010+1
no_eor5:
sprmat_6x:
  lda #first_sprmat_x + 6*24
  sec
  sbc #2
  sta sprmat_6x+1
  sta $d00c
  bcs no_eor6
  lda sprmat_d010+1
  eor #64
  sta sprmat_d010+1
no_eor6:
sprmat_7x:
  lda #first_sprmat_x + 7*24
  sec
  sbc #2
  sta sprmat_7x+1
  sta $d00e
  bcs no_eor7
  lda sprmat_d010+1
  eor #128
  sta sprmat_d010+1
no_eor7:
sprmat_d010:
  lda #$ff
  sta $d010

bounce_cou:
  ldx #0
  lda bounce_table,x
  bne nowrbo
  ldx #0
  lda bounce_table
nowrbo:
  inx
  stx bounce_cou+1
  sta spr_ypos_msb+1

skip_moving:
  lda #0
  sta $d017
  sta $d01d
  sta $d01b
spritemat_d01c:
  lda #$ff
  sta $d01c
  ;lda #8
  ;sta $d020

  lda spr_ypos_msb+1
  sta $d001
  sta $d003
  sta $d005
  sta $d007
  sta $d009
  sta $d00b
  sta $d00d
  sta $d00f
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

spr_ypos_msb:
  lda #$42
  clc
  adc #18
  sta $d012
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
  clc
  adc #20
  sta irqpos6+1
  clc
  adc #20
  sta irqpos7+1  ; This is where we turn off the sprites and put them all at x-pos 0

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

; make sure that irq_above and irq_below isn't run.
  lda #<irq_1
  sta $fffe
  lda #>irq_1
  sta $ffff

  jmp skip_sprtext_anim

do_sprtext_anim:
anim_frame_no:
  ldx #0
  inx
  stx anim_frame_no+1
  cpx #sprtext_frame_offset - 4
  bne dont_copy_spr0
  jsr copy_spr0_into_chars1_0
dont_copy_spr0:
  cpx #sprtext_frame_offset - 3
  bne dont_copy_spr0_1
  jsr copy_spr0_into_chars1_1
dont_copy_spr0_1:
  cpx #sprtext_frame_offset - 2
  bne dont_copy_spr0_2
  jsr copy_spr0_into_chars1_2
dont_copy_spr0_2:
  cpx #sprtext_frame_offset - 1
  bne dont_copy_spr0_3
  jsr copy_spr0_into_chars1_3
dont_copy_spr0_3:
  cpx #sprtext_frame_offset
  bne not_another_name0
  jsr put_text0_on_screen
  jsr goto_next_greet_or_spritemat

  ; Initialize sprtext dest for the second text in a game screen:
  lda anim_enabled+1
  bmi were_doing_hi_right_now
  ; Setup sprtext_ypos for a new destination:
  ; The greetingstext charcol:
  lda CCOL1_LO
  sta charcols1 + 1
  ; The greetingstext sprcol:
  lda SCOL1_LO
  sta sprtext_col + 1
  lda SPRY1_LO
  sta sprtext_ypos_dest
  lda SPRX1_LO
  sta sprtext_xpos_dest
  jmp done_initializing_second_text

were_doing_hi_right_now:
  ; Setup sprtext_ypos for a new destination:
  ; The greetingstext charcol:
  lda CCOL1_HI
  sta charcols1 + 1
  ; The greetingstext sprcol:
  lda SCOL1_HI
  sta sprtext_col + 1
  lda SPRY1_HI
  sta sprtext_ypos_dest
  lda SPRX1_HI
  sta sprtext_xpos_dest
done_initializing_second_text:

not_another_name0:

  cpx #sprtext_frame_offset + 50 - 5
  bne dont_erase_text0_chars
  jsr erase_text0_chars_from_screen
dont_erase_text0_chars:
  cpx #sprtext_frame_offset + 50 - 4
  bne dont_copy_spr1
  jsr copy_spr1_into_chars1_0
dont_copy_spr1:
  cpx #sprtext_frame_offset + 50 - 3
  bne dont_copy_spr1_1
  jsr copy_spr1_into_chars1_1
dont_copy_spr1_1:
  cpx #sprtext_frame_offset + 50 - 2
  bne dont_copy_spr1_2
  jsr copy_spr1_into_chars1_2
dont_copy_spr1_2:
  cpx #sprtext_frame_offset + 50 - 1
  bne dont_copy_spr1_3
  jsr copy_spr1_into_chars1_3
dont_copy_spr1_3:


  cpx #sprtext_frame_offset + 50
  bne not_another_name1
  jsr put_text1_on_screen
  jsr goto_next_greet_or_spritemat

  ; Initialize sprtext dest for the second text in a game screen:
  lda anim_enabled+1
  bmi were_doing_hi_right_now1
  ; Setup sprtext_ypos for a new destination:
  ; The greetingstext charcol:
  lda CCOL0_HI
  sta charcols0 + 1
  ; The greetingstext sprcol:
  lda SCOL0_HI
  sta sprtext_col + 1
  lda SPRY0_HI
  sta sprtext_ypos_dest
  lda SPRX0_HI
  sta sprtext_xpos_dest
  jmp done_initializing_second_text1

were_doing_hi_right_now1:
  ; Setup sprtext_ypos for a new destination:
  ; The greetingstext charcol:
  lda CCOL0_LO
  sta charcols0 + 1
  ; The greetingstext sprcol:
  lda SCOL0_LO
  sta sprtext_col + 1
  lda SPRY0_LO
  sta sprtext_ypos_dest
  lda SPRX0_LO
  sta sprtext_xpos_dest
done_initializing_second_text1:

not_another_name1:



  ;cpx #95
  ;bcs dont_erase_in_chars
  ;lda #1
  ;sta $d020


;dont_erase_in_chars:
  cpx #100
  bne do_anim
  lda #1
  sta anim_done+1
  jsr toggle_spritemat_scr

do_anim:
  lda #<irq_above
  sta $fffe
  lda #>irq_above
  sta $ffff
  jsr write_another_char



; Do a 16-bit moving average to move the sprtext_ypos
  lda #sprtext_ypos_dest_lsb
  sec
  sbc sprtext_ypos_lsb
  sta sprtext_ydiff_lsb
  lda sprtext_ypos_dest
  sbc sprtext_ypos
  sta sprtext_ydiff_msb
; Sign extend 16-bit ydiff to 24 bits:
  lda #0
  sbc #0
  sta sprtext_ydiff_high

;; Sign extend 16-bit ydiff to 24 bits:
;  ldx #$00
;  lda sprtext_ydiff_msb
;  bpl its_positive
;  dex        ; decrement high byte to $ff for a negative delta
;its_positive:
;  stx sprtext_ydiff_high

; Multiply ydiff by 16:
  asl sprtext_ydiff_lsb
  rol sprtext_ydiff_msb
  rol sprtext_ydiff_high

  asl sprtext_ydiff_lsb
  rol sprtext_ydiff_msb
  rol sprtext_ydiff_high

  asl sprtext_ydiff_lsb
  rol sprtext_ydiff_msb
  rol sprtext_ydiff_high

  asl sprtext_ydiff_lsb
  rol sprtext_ydiff_msb
  rol sprtext_ydiff_high

; 16-bit addition
  lda sprtext_ydiff_msb
  clc
  adc sprtext_ypos_lsb
  sta sprtext_ypos_lsb
  lda sprtext_ydiff_high
  adc sprtext_ypos
  sta sprtext_ypos

  ldx misplacement_no+1
  clc
  adc yposdest_minus_ypos,x
  sta sprtext_ypos_compensated


; Do a 16-bit moving average to move the sprtext_xpos
  lda #sprtext_xpos_dest_lsb
  sec
  sbc sprtext_xpos_lsb
  sta sprtext_xdiff_lsb
  lda sprtext_xpos_dest
  sbc sprtext_xpos
  sta sprtext_xdiff_msb
; Sign extend 16-bit xdiff to 24 bits:
  lda #0
  sbc #0
  sta sprtext_xdiff_high

;; Sign extend 16-bit xdiff to 24 bits:
;  ldx #$00
;  lda sprtext_xdiff_msb
;  bpl its_positive2
;  dex        ; decrement high byte to $ff for a negative delta
;its_positive2:
;  stx sprtext_xdiff_high

; Multiply xdiff by 16:
  asl sprtext_xdiff_lsb
  rol sprtext_xdiff_msb
  rol sprtext_xdiff_high

  asl sprtext_xdiff_lsb
  rol sprtext_xdiff_msb
  rol sprtext_xdiff_high

  asl sprtext_xdiff_lsb
  rol sprtext_xdiff_msb
  rol sprtext_xdiff_high

  asl sprtext_xdiff_lsb
  rol sprtext_xdiff_msb
  rol sprtext_xdiff_high

; 16-bit addition
  lda sprtext_xdiff_msb
  clc
  adc sprtext_xpos_lsb
  sta sprtext_xpos_lsb
  lda sprtext_xdiff_high
  adc sprtext_xpos
  sta sprtext_xpos

  ldx misplacement_no+1
  clc
  adc xposdest_minus_xpos,x
  sta sprtext_xpos_compensated

  lda sprtext_ypos_compensated
  sec
  sbc #23
  sta $d012


skip_sprtext_anim:
  ;Make sure that we may be interrupted by the next irq:
  cli
  lda anim_done+1
  bne no_anim
  lda anim_enabled+1
  bpl do_anim_lo
  jmp do_anim_hi
do_anim_lo:
  cmp #$1
  bne dont_run_game_yet
values_to_track_lo = $10
nof_values_to_track_lo:
  ldx #values_to_track_lo
  jsr LO_START_ZP
dont_run_game_yet:
no_anim:
end_irq_bottom:

music_enabled:
  lda #0
  beq no_music_right_now
; The music right now uses same zp-locations as the zp-code.
  jsr the_music+3
no_music_right_now:

;save01:
;  lda #$35
;  sta $01
save_a:
  lda #0
save_x:
  ldx #0
save_y:
  ldy #0
  rti

do_anim_hi:
  cmp #$81
  bne dont_run_game_yet
values_to_track_hi = $10
nof_values_to_track_hi:
  ldx #values_to_track_hi
  jsr HI_START_ZP
  jmp no_anim

sprtext_ypos_lsb:
  !byte $00
sprtext_ypos:
  !byte $c0
sprtext_ypos_compensated:
  !byte $c0
; Allowed values $09 - 234

sprtext_ypos_dest_lsb = $80
sprtext_ypos_dest:
  !byte $80
sprtext_ydiff_lsb:
  !byte 0
sprtext_ydiff_msb:
  !byte 0
sprtext_ydiff_high:
  !byte 0

sprmasks:
  !byte $01,$01,$02,$02,$04,$04,$08,$08,$10,$10,$20,$20,$40,$40,$80,$80

bounce_table:
;Too little bounce:  !byte 80, 78, 76, 74, 72, 70, 68, 67, 65, 63, 62, 60, 59, 57, 56, 55, 54, 53, 52, 52, 51, 51, 50, 50, 50, 50, 50, 51, 51, 52, 52, 53, 54, 55, 56, 58, 59, 60, 62, 63, 65, 67, 69, 71, 72, 74, 76, 78, 0
;Too far down. IRQs collide:  !byte 124, 119, 114, 109, 104, 99, 95, 90, 86, 82, 78, 74, 71, 67, 64, 61, 59, 57, 55, 53, 51, 50, 50, 49, 49, 49, 50, 51, 52, 53, 55, 57, 59, 62, 65, 68, 71, 75, 79, 83, 87, 91, 96, 100, 105, 110, 115, 120, 0
;Nice height, too fast:  !byte 95, 92, 89, 86, 83, 80, 77, 74, 72, 69, 67, 64, 62, 60, 58, 57, 55, 54, 52, 51, 50, 50, 49, 49, 49, 49, 49, 50, 51, 52, 53, 54, 55, 57, 59, 61, 63, 65, 67, 70, 72, 75, 78, 80, 83, 86, 89, 92, 0
;One pixel hoo high up:  !byte 95, 92, 90, 88, 86, 84, 81, 79, 77, 75, 73, 71, 69, 67, 66, 64, 62, 61, 59, 58, 57, 55, 54, 53, 52, 52, 51, 50, 50, 49, 49, 49, 49, 49, 49, 50, 50, 50, 51, 52, 53, 54, 55, 56, 57, 58, 60, 61, 63, 64, 66, 68, 70, 72, 74, 76, 78, 80, 82, 84, 86, 89, 91, 93, 0
  !byte 95, 93, 90, 88, 86, 84, 82, 80, 78, 76, 74, 72, 70, 68, 66, 65, 63, 61, 60, 59, 57, 56, 55, 54, 53, 53, 52, 51, 51, 50, 50, 50, 50, 50, 50, 51, 51, 51, 52, 53, 54, 54, 55, 57, 58, 59, 60, 62, 63, 65, 67, 68, 70, 72, 74, 76, 78, 80, 82, 84, 86, 89, 91, 93, 0


sprtext_xpos_lsb:
  !byte $00
sprtext_xpos:
  !byte $b8
sprtext_xpos_compensated:
  !byte $b8
sprtext_xpos_dest_lsb = $80
sprtext_xpos_dest:
  !byte $80
sprtext_xdiff_lsb:
  !byte 0
sprtext_xdiff_msb:
  !byte 0
sprtext_xdiff_high:
  !byte 0


; This is where we set the sprites to show our moving text:
irq_above:
  sta save_aab+1
  stx save_xab+1
  sty save_yab+1
;  lda $01
;  sta save012+1
;  lda #$35
;  sta $01

;  lda #2
;  sta $d020
;  sta $d021

; This is where we determine which sprites that are "available" for text overlay
  lda $d015
  eor #$ff
  sta sprites_available+1
;  cmp #$ff
;  beq done_checking_availability



  ldy #0
check_another:
;Now, check $d001,y and see if this sprite is within the glitch range
;Check if this sprite is way "above" the sprtext, if so, the sprite is available:
  lda sprtext_ypos_compensated
  sec
;  sbc #31        ;21 + Nof rasterlines above sprtext for irq_above to finish swapping sprite poi/data/cols/etc
  sbc #42+10        ;42 + Nof rasterlines above sprtext for irq_above to finish swapping sprite poi/data/cols/etc
;If carry is set here, sprtext_ypos is so far up that no sprite can fit above:
  bcc this_sprite_is_not_above
  cmp $d001,y
  bcc this_sprite_is_not_above
this_sprite_is_above:
  lda sprmasks,y
  ora sprites_available+1
  sta sprites_available+1
  jmp this_sprcheck_done

this_sprite_is_not_above:
  lda sprtext_ypos_compensated
  clc
  adc #21+6        ;21 + Nof rasterlines below sprtext for irq_below to finish restoring sprite poi/data/cols/etc
;If carry is set here, sprtext_ypos is so far down that no sprite can fit below:
  bcs this_sprite_is_not_below
  cmp $d001,y
  bcs this_sprite_is_not_below
this_sprite_is_below:
  lda sprmasks,y
  ora sprites_available+1
  sta sprites_available+1

this_sprite_is_not_below:
this_sprcheck_done:
  iny
  iny
  cpy #$10
  bne check_another

done_checking_availability:
  lda anim_enabled+1
  beq done_saving
  bmi save_HI
save_LO:
  lda SCREEN_LO+$03f8
  sta old_03f8_LO+1
  lda SCREEN_LO+$03f9
  sta old_03f9_LO+1
  lda SCREEN_LO+$03fa
  sta old_03fa_LO+1
  lda SCREEN_LO+$03fb
  sta old_03fb_LO+1
  lda SCREEN_LO+$03fc
  sta old_03fc_LO+1
  lda SCREEN_LO+$03fd
  sta old_03fd_LO+1
  lda SCREEN_LO+$03fe
  sta old_03fe_LO+1
  lda SCREEN_LO+$03ff
  sta old_03ff_LO+1
  lda #>(SCREEN_LO+$03f8)
  sta where_to_write+2
  jmp done_saving
save_HI:
  lda SCREEN_HI+$03f8
  sta old_03f8_HI+1
  lda SCREEN_HI+$03f9
  sta old_03f9_HI+1
  lda SCREEN_HI+$03fa
  sta old_03fa_HI+1
  lda SCREEN_HI+$03fb
  sta old_03fb_HI+1
  lda SCREEN_HI+$03fc
  sta old_03fc_HI+1
  lda SCREEN_HI+$03fd
  sta old_03fd_HI+1
  lda SCREEN_HI+$03fe
  sta old_03fe_HI+1
  lda SCREEN_HI+$03ff
  sta old_03ff_HI+1
  lda #>(SCREEN_HI+$03f8)
  sta where_to_write+2
done_saving:


sprtext_x:
  lda sprtext_xpos_compensated      ; xpos=128 is in the middle of the screen.  #$b8 -> $d000 is in the middle as well
  clc
  adc #$38
  sec
  sbc sprtext_plotpos_x+1
  sta sprtext_x_tmp+1
where_the_sprtext_sprites_are:
  lda #$80
  sta sprtext_datapoi+1
;  lda #$a
;  sta $d020
;  sta $d021

; Here, go through all needed sprites, and write what's needed.
; Only write into sprites that are available
  lda sprites_available+1
  tax
  eor #$ff
  tay
;Make sprtext-sprites not yexpanded:
  tya
  and $d017
  sta $d017
;Make sprtext-sprites single colour:
  tya
  and $d01c
  sta $d01c
;Make sprtext-sprites xexpanded:
  txa
  ora $d01d
  sta $d01d
;Make sprtext-sprites in front of chars:
  tya
  and $d01b
  sta $d01b

;Put all sprtext-sprites to the left of screen:
  tya
  and $d010
  sta $d010

;Start with sprites to the left of xpos 255:
  lda #$80
  sta on_the_right+1

  lda sprites_available+1
  ldy #$0e
  ldx #7
next_sprite_to_write:
  asl
  bcc dont_use_this_sprite
  sta sprites_available+1
  txa
  asl
  tay
  lda sprtext_ypos_compensated
  sta $d001,y
sprtext_datapoi:
  lda #$80
where_to_write:
  sta SCREEN_LO+$03f8,x
  inc sprtext_datapoi+1
sprtext_col:
  lda #7
  sta $d027,x
sprtext_x_tmp:
  lda #$40
  sta $d000,y
  clc
  adc #$30
  sta sprtext_x_tmp + 1

on_the_right:
  lda #$80
  bmi not_on_the_right
  lda sprmasks,y
  ora $d010
  sta $d010
not_on_the_right:

  bcc no_toggle_d010
;All sprites after this are on the right:
  stx on_the_right+1
no_toggle_d010:



sprites_available:
  lda #0
dont_use_this_sprite:
  dex
  bpl next_sprite_to_write

  lda #0
  ldx frames_until_sprmat_visible+1
  dex
  bpl nothing_visible

;Make sprtext-sprites visible:
  lda #$ff
;  txa
;  ora $d015
nothing_visible:
  sta $d015

;  lda #1
;  sta $d020
;  sta $d021

  lda #<irq_below
  sta $fffe
  lda #>irq_below
  sta $ffff
  lda sprtext_ypos_compensated
  clc
  adc #19
  sta $d012

  asl $d019 ;ack IRQ
end_irq_above:
;save012:
;  lda #$35
;  sta $01
save_aab:
  lda #0
save_xab:
  ldx #0
save_yab:
  ldy #0
  rti


; This is where we restore the original sprites:
irq_below:
  sta save_abe+1
  stx save_xbe+1
  sty save_ybe+1
;  lda $01
;  sta save013+1
;  lda #$35
;  sta $01
  asl $d019 ;ack IRQ
  lda #<irq_bottom
  sta $fffe
  lda #>irq_bottom
  sta $ffff
  lda #$fa
  sta $d012

;  lda #$a
;  sta $d020
;  sta $d021

  lda saved_d000+$15
  sta $d015
  lda saved_d000+$01
  sta $d001
  lda saved_d000+$03
  sta $d003
  lda saved_d000+$05
  sta $d005
  lda saved_d000+$07
  sta $d007
  lda saved_d000+$09
  sta $d009
  lda saved_d000+$0b
  sta $d00b
  lda saved_d000+$0d
  sta $d00d
  lda saved_d000+$0f
  sta $d00f

;  lda #$2
;  sta $d020
;  sta $d021

  lda saved_d000+$10
  sta $d010
  lda saved_d000+$1b
  sta $d01b
  lda saved_d000+$1c
  sta $d01c
  lda saved_d000+$1d
  sta $d01d
  lda saved_d000+$17
  sta $d017
  lda saved_d000+$00
  sta $d000
  lda saved_d000+$02
  sta $d002
  lda saved_d000+$04
  sta $d004
  lda saved_d000+$06
  sta $d006
  lda saved_d000+$08
  sta $d008
  lda saved_d000+$0a
  sta $d00a
  lda saved_d000+$0c
  sta $d00c
  lda saved_d000+$0e
  sta $d00e
  lda saved_d000+$27
  sta $d027
  lda saved_d000+$28
  sta $d028
  lda saved_d000+$29
  sta $d029
  lda saved_d000+$2a
  sta $d02a
  lda saved_d000+$2b
  sta $d02b
  lda saved_d000+$2c
  sta $d02c
  lda saved_d000+$2d
  sta $d02d
  lda saved_d000+$2e
  sta $d02e


  lda anim_enabled+1
  beq done_restoring
  bmi restore_HI
restore_LO:
old_03f8_LO:
  lda #$40
  sta SCREEN_LO+$03f8
old_03f9_LO:
  lda #$40
  sta SCREEN_LO+$03f9
old_03fa_LO:
  lda #$40
  sta SCREEN_LO+$03fa
old_03fb_LO:
  lda #$40
  sta SCREEN_LO+$03fb
old_03fc_LO:
  lda #$40
  sta SCREEN_LO+$03fc
old_03fd_LO:
  lda #$40
  sta SCREEN_LO+$03fd
old_03fe_LO:
  lda #$40
  sta SCREEN_LO+$03fe
old_03ff_LO:
  lda #$40
  sta SCREEN_LO+$03ff
  jmp done_restoring
restore_HI:
old_03f8_HI:
  lda #$40
  sta SCREEN_HI+$03f8
old_03f9_HI:
  lda #$40
  sta SCREEN_HI+$03f9
old_03fa_HI:
  lda #$40
  sta SCREEN_HI+$03fa
old_03fb_HI:
  lda #$40
  sta SCREEN_HI+$03fb
old_03fc_HI:
  lda #$40
  sta SCREEN_HI+$03fc
old_03fd_HI:
  lda #$40
  sta SCREEN_HI+$03fd
old_03fe_HI:
  lda #$40
  sta SCREEN_HI+$03fe
old_03ff_HI:
  lda #$40
  sta SCREEN_HI+$03ff
done_restoring:


;  lda #0
;  sta $d020
;  sta $d021

end_irq_below:
;save013:
;  lda #$35
;  sta $01
save_abe:
  lda #0
save_xbe:
  ldx #0
save_ybe:
  ldy #0
  rti


;Copy these declarations into main.s:
output_d000_offset = $03e8
output_display_list_poi_offset = $03f6
output_sprite_pois_offset = $03f8
output_colmem_offset = $0400
output_d00e_offset = $07e8
output_d015_offset = $07ec
output_d01b_offset = $07ef
output_d020_offset = $07f2
output_d025_offset = $07f4
output_charset_offset = $0800
;...and stop copying here.


;----------------------
;- The anim2 version

init_zp:
  ldx #0
copy_zp:
  lda ZP_START,x
  sta ZP_CODE,x
  inx
  cpx #ZP_END-ZP_START
  bne copy_zp
  rts

prepare_anim2_lo:
;init tmp_LIST_STREAK_LO:
  ldx #0
  lda #0
clr_streak_lo:
  sta tmp_LIST_STREAK_LO,x
  dex
  bne clr_streak_lo

;init tmp_LIST_BASE_MSB_LO
;init tmp_LIST_BASE_LSB_LO
  lda #>(LIST_END_LO-1)
  sta tmp_msb_lo
  lda #<(LIST_END_LO-1)
  sta tmp_lsb_lo

  ldx #0
calc_list_pois_lo:
  lda tmp_lsb_lo
  sec
  sbc LIST_POI_LO,x
  sta tmp_LIST_BASE_LSB_LO,x
  sta tmp_lsb_lo
  lda tmp_msb_lo
  sbc #0
  sta tmp_LIST_BASE_MSB_LO,x
  sta tmp_msb_lo
  inx
  bne calc_list_pois_lo
  rts

init_anim2_lo:
  jsr init_SID_before_a_game
;screen at $4800, charset at $4000
  lda #$20
  sta $d018


  lda do_mat+1
  beq do_initialize_sprites_lo
  jmp skip_initialize_sprites_lo
do_initialize_sprites_lo:
  lda INITIAL_VALUES_LO + $00
  sta $d000
  sta saved_d000+$00
  lda INITIAL_VALUES_LO + $01
  sta $d001
  sta saved_d000+$01
  lda INITIAL_VALUES_LO + $02
  sta $d002
  sta saved_d000+$02
  lda INITIAL_VALUES_LO + $03
  sta $d003
  sta saved_d000+$03
  lda INITIAL_VALUES_LO + $04
  sta $d004
  sta saved_d000+$04
  lda INITIAL_VALUES_LO + $05
  sta $d005
  sta saved_d000+$05
  lda INITIAL_VALUES_LO + $06
  sta $d006
  sta saved_d000+$06
  lda INITIAL_VALUES_LO + $07
  sta $d007
  sta saved_d000+$07
  lda INITIAL_VALUES_LO + $08
  sta $d008
  sta saved_d000+$08
  lda INITIAL_VALUES_LO + $09
  sta $d009
  sta saved_d000+$09
  lda INITIAL_VALUES_LO + $0a
  sta $d00a
  sta saved_d000+$0a
  lda INITIAL_VALUES_LO + $0b
  sta $d00b
  sta saved_d000+$0b
  lda INITIAL_VALUES_LO + $0c
  sta $d00c
  sta saved_d000+$0c
  lda INITIAL_VALUES_LO + $0d
  sta $d00d
  sta saved_d000+$0d
  lda INITIAL_VALUES_LO + $0e
  sta $d00e
  sta saved_d000+$0e
  lda INITIAL_VALUES_LO + $0f
  sta $d00f
  sta saved_d000+$0f
  lda INITIAL_VALUES_LO + $10
  sta $d010
  sta saved_d000+$10
  lda INITIAL_VALUES_LO + $12
  sta $d015
  sta saved_d000+$15
  lda INITIAL_VALUES_LO + $14
  sta $d017
  sta saved_d000+$17
  lda INITIAL_VALUES_LO + $15
  sta $d01b
  sta saved_d000+$1b
  lda INITIAL_VALUES_LO + $16
  sta $d01c
  sta saved_d000+$1c
  lda INITIAL_VALUES_LO + $17
  sta $d01d
  sta saved_d000+$1d
  lda INITIAL_VALUES_LO + $1d
  sta $d025
  sta saved_d000+$25
  lda INITIAL_VALUES_LO + $1e
  sta $d026
  sta saved_d000+$26
  lda INITIAL_VALUES_LO + $1f
  sta $d027
  sta saved_d000+$27
  lda INITIAL_VALUES_LO + $20
  sta $d028
  sta saved_d000+$28
  lda INITIAL_VALUES_LO + $21
  sta $d029
  sta saved_d000+$29
  lda INITIAL_VALUES_LO + $22
  sta $d02a
  sta saved_d000+$2a
  lda INITIAL_VALUES_LO + $23
  sta $d02b
  sta saved_d000+$2b
  lda INITIAL_VALUES_LO + $24
  sta $d02c
  sta saved_d000+$2c
  lda INITIAL_VALUES_LO + $25
  sta $d02d
  sta saved_d000+$2d
  lda INITIAL_VALUES_LO + $26
  sta $d02e
  sta saved_d000+$2e
skip_initialize_sprites_lo:

  lda INITIAL_VALUES_LO + $1a
  sta $d022
  sta saved_d000+$22
  lda INITIAL_VALUES_LO + $1b
  sta $d023
  sta saved_d000+$23
  lda INITIAL_VALUES_LO + $1c
  sta $d024
  sta saved_d000+$24
  lda INITIAL_VALUES_LO + $11
  and #$07
  ora #$18
  sta $d011
  sta saved_d000+$11
  lda INITIAL_VALUES_LO + $13
  sta $d016
  sta saved_d000+$16

  lda music_enabled+1
  beq SID_init3
  jmp no_SID_init3
SID_init3:
  lda INITIAL_VALUES_LO + $27
  sta $d400
  lda INITIAL_VALUES_LO + $28
  sta $d401
  lda INITIAL_VALUES_LO + $29
  sta $d402
  lda INITIAL_VALUES_LO + $2a
  sta $d403
  lda INITIAL_VALUES_LO + $2c
  sta $d405
  lda INITIAL_VALUES_LO + $2d
  sta $d406
  lda INITIAL_VALUES_LO + $2e
  sta $d407
  lda INITIAL_VALUES_LO + $2f
  sta $d408
  lda INITIAL_VALUES_LO + $30
  sta $d409
  lda INITIAL_VALUES_LO + $31
  sta $d40a
  lda INITIAL_VALUES_LO + $33
  sta $d40c
  lda INITIAL_VALUES_LO + $34
  sta $d40d
  lda INITIAL_VALUES_LO + $35
  sta $d40e
  lda INITIAL_VALUES_LO + $36
  sta $d40f
  lda INITIAL_VALUES_LO + $37
  sta $d410
  lda INITIAL_VALUES_LO + $38
  sta $d411
  lda INITIAL_VALUES_LO + $3a
  sta $d413
  lda INITIAL_VALUES_LO + $3b
  sta $d414
  lda INITIAL_VALUES_LO + $3c
  sta $d416
  lda INITIAL_VALUES_LO + $3d
  sta $d417
  lda INITIAL_VALUES_LO + $3e
  sta $d418
  lda INITIAL_VALUES_LO + $2b
  sta $d404
  lda INITIAL_VALUES_LO + $32
  sta $d40b
  lda INITIAL_VALUES_LO + $39
  sta $d412
no_SID_init3:
  lda INITIAL_VALUES_LO + $3f
  sta nof_values_to_track_lo+1

  jsr do_another_game_counter_lo
  lda #game_counter_char
  sta SCREEN_LO + 40 + 38

; Copy screen colours
  ldy #$3f
morco0_lo:
  lda COLRAM_LO,y
  sta $d800,y
  lda COLRAM_LO+$40,y
  sta $d840,y
  dey
  bpl morco0_lo

;This is outside of the screen:
  lda INITIAL_VALUES_LO + $18
  sta $d020
  lda INITIAL_VALUES_LO + $19
  sta $d021

  ldy #$3f
morco0b_lo:
  lda COLRAM_LO+$80,y
  sta $d880,y
  lda COLRAM_LO+$c0,y
  sta $d8c0,y
  dey
  bpl morco0b_lo

  ldy #$3f
morco1_lo:
  lda COLRAM_LO+$100,y
  sta $d900,y
  lda COLRAM_LO+$140,y
  sta $d940,y
  lda COLRAM_LO+$180,y
  sta $d980,y
  lda COLRAM_LO+$1c0,y
  sta $d9c0,y
  dey
  bpl morco1_lo
  ldy #$3f
morco2_lo:
  lda COLRAM_LO+$200,y
  sta $da00,y
  lda COLRAM_LO+$240,y
  sta $da40,y
  lda COLRAM_LO+$280,y
  sta $da80,y
  lda COLRAM_LO+$2c0,y
  sta $dac0,y
  dey
  bpl morco2_lo
  ldy #$2f
morco3_lo:
  lda COLRAM_LO+$300,y
  sta $db00,y
  lda COLRAM_LO+$330,y
  sta $db30,y
  lda COLRAM_LO+$360,y
  sta $db60,y
  lda COLRAM_LO+$390,y
  sta $db90,y
  lda COLRAM_LO+$3c0,y
  sta $dbc0,y
  dey
  bpl morco3_lo

;  lda INITIAL_VALUES_LO + $2b
;  sta $d404
;  lda INITIAL_VALUES_LO + $32
;  sta $d40b
;  lda INITIAL_VALUES_LO + $39
;  sta $d412

; DEBUG print for knowing row and column:
;  lda #$1
;  sta $d800 +  1 * 40 + 5
;  sta $d800 +  3 * 40 + 5
;  sta $d800 +  5 * 40 + 5
;  sta $d800 +  7 * 40 + 5
;  sta $d800 +  9 * 40 + 5
;  sta $d800 + 11 * 40 + 5
;  sta $d800 + 13 * 40 + 5
;  sta $d800 + 15 * 40 + 5
;  sta $d800 + 17 * 40 + 5
;  sta $d800 + 19 * 40 + 5
;  sta $d800 + 21 * 40 + 5
;  sta $d800 + 23 * 40 + 5
;  lda #$1
;  sta $d800 +  2 * 40 + 4
;  sta $d800 +  3 * 40 + 4
;  sta $d800 +  6 * 40 + 4
;  sta $d800 +  7 * 40 + 4
;  sta $d800 + 10 * 40 + 4
;  sta $d800 + 11 * 40 + 4
;  sta $d800 + 14 * 40 + 4
;  sta $d800 + 15 * 40 + 4
;  sta $d800 + 18 * 40 + 4
;  sta $d800 + 19 * 40 + 4
;  sta $d800 + 22 * 40 + 4
;  sta $d800 + 23 * 40 + 4
;  lda #$1
;  sta $d800 +  4 * 40 + 3
;  sta $d800 +  5 * 40 + 3
;  sta $d800 +  6 * 40 + 3
;  sta $d800 +  7 * 40 + 3
;  sta $d800 + 12 * 40 + 3
;  sta $d800 + 13 * 40 + 3
;  sta $d800 + 14 * 40 + 3
;  sta $d800 + 15 * 40 + 3
;  sta $d800 + 20 * 40 + 3
;  sta $d800 + 21 * 40 + 3
;  sta $d800 + 22 * 40 + 3
;  sta $d800 + 23 * 40 + 3
;  lda #$1
;  sta $d800 +  8 * 40 + 2
;  sta $d800 +  9 * 40 + 2
;  sta $d800 + 10 * 40 + 2
;  sta $d800 + 11 * 40 + 2
;  sta $d800 + 12 * 40 + 2
;  sta $d800 + 13 * 40 + 2
;  sta $d800 + 14 * 40 + 2
;  sta $d800 + 15 * 40 + 2
;  sta $d800 + 24 * 40 + 2
;  lda #$1
;  sta $d800 + 16 * 40 + 1
;  sta $d800 + 17 * 40 + 1
;  sta $d800 + 18 * 40 + 1
;  sta $d800 + 19 * 40 + 1
;  sta $d800 + 20 * 40 + 1
;  sta $d800 + 21 * 40 + 1
;  sta $d800 + 22 * 40 + 1
;  sta $d800 + 23 * 40 + 1
;  sta $d800 + 24 * 40 + 1
;
;  lda #1
;  sta SCREEN_LO +  1 * 40 + 5
;  sta SCREEN_LO +  3 * 40 + 5
;  sta SCREEN_LO +  5 * 40 + 5
;  sta SCREEN_LO +  7 * 40 + 5
;  sta SCREEN_LO +  9 * 40 + 5
;  sta SCREEN_LO + 11 * 40 + 5
;  sta SCREEN_LO + 13 * 40 + 5
;  sta SCREEN_LO + 15 * 40 + 5
;  sta SCREEN_LO + 17 * 40 + 5
;  sta SCREEN_LO + 19 * 40 + 5
;  sta SCREEN_LO + 21 * 40 + 5
;  sta SCREEN_LO + 23 * 40 + 5
;  sta SCREEN_LO +  2 * 40 + 4
;  sta SCREEN_LO +  3 * 40 + 4
;  sta SCREEN_LO +  6 * 40 + 4
;  sta SCREEN_LO +  7 * 40 + 4
;  sta SCREEN_LO + 10 * 40 + 4
;  sta SCREEN_LO + 11 * 40 + 4
;  sta SCREEN_LO + 14 * 40 + 4
;  sta SCREEN_LO + 15 * 40 + 4
;  sta SCREEN_LO + 18 * 40 + 4
;  sta SCREEN_LO + 19 * 40 + 4
;  sta SCREEN_LO + 22 * 40 + 4
;  sta SCREEN_LO + 23 * 40 + 4
;  sta SCREEN_LO +  4 * 40 + 3
;  sta SCREEN_LO +  5 * 40 + 3
;  sta SCREEN_LO +  6 * 40 + 3
;  sta SCREEN_LO +  7 * 40 + 3
;  sta SCREEN_LO + 12 * 40 + 3
;  sta SCREEN_LO + 13 * 40 + 3
;  sta SCREEN_LO + 14 * 40 + 3
;  sta SCREEN_LO + 15 * 40 + 3
;  sta SCREEN_LO + 20 * 40 + 3
;  sta SCREEN_LO + 21 * 40 + 3
;  sta SCREEN_LO + 22 * 40 + 3
;  sta SCREEN_LO + 23 * 40 + 3
;  sta SCREEN_LO +  8 * 40 + 2
;  sta SCREEN_LO +  9 * 40 + 2
;  sta SCREEN_LO + 10 * 40 + 2
;  sta SCREEN_LO + 11 * 40 + 2
;  sta SCREEN_LO + 12 * 40 + 2
;  sta SCREEN_LO + 13 * 40 + 2
;  sta SCREEN_LO + 14 * 40 + 2
;  sta SCREEN_LO + 15 * 40 + 2
;  sta SCREEN_LO + 24 * 40 + 2
;  sta SCREEN_LO + 16 * 40 + 1
;  sta SCREEN_LO + 17 * 40 + 1
;  sta SCREEN_LO + 18 * 40 + 1
;  sta SCREEN_LO + 19 * 40 + 1
;  sta SCREEN_LO + 20 * 40 + 1
;  sta SCREEN_LO + 21 * 40 + 1
;  sta SCREEN_LO + 22 * 40 + 1
;  sta SCREEN_LO + 23 * 40 + 1
;  sta SCREEN_LO + 24 * 40 + 1
;
;  lda #1
;  sta $d800 + 12 * 40 + 10
;  sta $d800 + 12 * 40 + 20
;  sta $d800 + 12 * 40 + 30
;  lda #1
;  sta SCREEN_LO + 12 * 40 + 10
;  sta SCREEN_LO + 12 * 40 + 20
;  sta SCREEN_LO + 12 * 40 + 30
;  lda #0
;  sta $d800 + 12 * 40 + 9
;  sta $d800 + 12 * 40 + 19
;  sta $d800 + 12 * 40 + 29
;  lda #1
;  sta SCREEN_LO + 12 * 40 + 9
;  sta SCREEN_LO + 12 * 40 + 19
;  sta SCREEN_LO + 12 * 40 + 29
  rts



prepare_anim2_hi:
;init tmp_LIST_STREAK_HI:
  ldx #0
  lda #0
clr_streak_hi:
  sta tmp_LIST_STREAK_HI,x
  dex
  bne clr_streak_hi

;init tmp_LIST_BASE_MSB_HI
;init tmp_LIST_BASE_LSB_HI
  lda #>(LIST_START_HI-1)
  sta tmp_msb_hi
  sta tmp_LIST_BASE_MSB_HI
  lda #<(LIST_START_HI-1)
  sta tmp_lsb_hi
  sta tmp_LIST_BASE_LSB_HI

  ldx #1
calc_list_pois_hi:
  lda LIST_POI_HI-1,x
  clc
  adc tmp_lsb_hi
  sta tmp_LIST_BASE_LSB_HI,x
  sta tmp_lsb_hi
  lda tmp_msb_hi
  adc #0
  sta tmp_LIST_BASE_MSB_HI,x
  sta tmp_msb_hi
  inx
  bne calc_list_pois_hi
  rts

init_SID_before_a_game:
  lda music_enabled+1
  bne no_SID_init
; Init SID registers:
;Attack/Decay
  lda #$00
  sta $d405
  sta $d405+7
  sta $d405+14
;SUSTAIN/RELEASE
  lda #$00
  sta $d406
  sta $d406+7
  sta $d406+14
; Test-bit=1, release
  lda #$08
  sta $d404
  sta $d404+7
  sta $d404+14
;50% pulse width:
;  lda #8
;  sta $d403
;  sta $d403+7
;  sta $d403+14
;Attack/Decay
  lda #$0f
  sta $d405
  sta $d405+7
  sta $d405+14
;SUSTAIN/RELEASE
  lda #$FF
  sta $d406
  sta $d406+7
  sta $d406+14
; Test-bit=1, Start attack to get to full volume, no waveform
  lda #$01
  sta $d404
  sta $d404+7
  sta $d404+14
no_SID_init:
  rts

init_anim2_hi:
  jsr init_SID_before_a_game
;screen at $7400, charset at $7800
  lda #$de
  sta $d018

  lda do_mat+1
  beq do_initialize_sprites_hi
  jmp skip_initialize_sprites_hi

do_initialize_sprites_hi:
  lda INITIAL_VALUES_HI + $00
  sta $d000
  sta saved_d000+$00
  lda INITIAL_VALUES_HI + $01
  sta $d001
  sta saved_d000+$01
  lda INITIAL_VALUES_HI + $02
  sta $d002
  sta saved_d000+$02
  lda INITIAL_VALUES_HI + $03
  sta $d003
  sta saved_d000+$03
  lda INITIAL_VALUES_HI + $04
  sta $d004
  sta saved_d000+$04
  lda INITIAL_VALUES_HI + $05
  sta $d005
  sta saved_d000+$05
  lda INITIAL_VALUES_HI + $06
  sta $d006
  sta saved_d000+$06
  lda INITIAL_VALUES_HI + $07
  sta $d007
  sta saved_d000+$07
  lda INITIAL_VALUES_HI + $08
  sta $d008
  sta saved_d000+$08
  lda INITIAL_VALUES_HI + $09
  sta $d009
  sta saved_d000+$09
  lda INITIAL_VALUES_HI + $0a
  sta $d00a
  sta saved_d000+$0a
  lda INITIAL_VALUES_HI + $0b
  sta $d00b
  sta saved_d000+$0b
  lda INITIAL_VALUES_HI + $0c
  sta $d00c
  sta saved_d000+$0c
  lda INITIAL_VALUES_HI + $0d
  sta $d00d
  sta saved_d000+$0d
  lda INITIAL_VALUES_HI + $0e
  sta $d00e
  sta saved_d000+$0e
  lda INITIAL_VALUES_HI + $0f
  sta $d00f
  sta saved_d000+$0f
  lda INITIAL_VALUES_HI + $10
  sta $d010
  sta saved_d000+$10
  lda INITIAL_VALUES_HI + $12
  sta $d015
  sta saved_d000+$15
  lda INITIAL_VALUES_HI + $14
  sta $d017
  sta saved_d000+$17
  lda INITIAL_VALUES_HI + $15
  sta $d01b
  sta saved_d000+$1b
  lda INITIAL_VALUES_HI + $16
  sta $d01c
  sta saved_d000+$1c
  lda INITIAL_VALUES_HI + $17
  sta $d01d
  sta saved_d000+$1d
  lda INITIAL_VALUES_HI + $1d
  sta $d025
  sta saved_d000+$25
  lda INITIAL_VALUES_HI + $1e
  sta $d026
  sta saved_d000+$26
  lda INITIAL_VALUES_HI + $1f
  sta $d027
  sta saved_d000+$27
  lda INITIAL_VALUES_HI + $20
  sta $d028
  sta saved_d000+$28
  lda INITIAL_VALUES_HI + $21
  sta $d029
  sta saved_d000+$29
  lda INITIAL_VALUES_HI + $22
  sta $d02a
  sta saved_d000+$2a
  lda INITIAL_VALUES_HI + $23
  sta $d02b
  sta saved_d000+$2b
  lda INITIAL_VALUES_HI + $24
  sta $d02c
  sta saved_d000+$2c
  lda INITIAL_VALUES_HI + $25
  sta $d02d
  sta saved_d000+$2d
  lda INITIAL_VALUES_HI + $26
  sta $d02e
  sta saved_d000+$2e

skip_initialize_sprites_hi:
  lda INITIAL_VALUES_HI + $1a
  sta $d022
  sta saved_d000+$22
  lda INITIAL_VALUES_HI + $1b
  sta $d023
  sta saved_d000+$23
  lda INITIAL_VALUES_HI + $1c
  sta $d024
  sta saved_d000+$24
  lda INITIAL_VALUES_HI + $11
  and #$07
  ora #$18
  sta $d011
  sta saved_d000+$11
  lda INITIAL_VALUES_HI + $13
  sta $d016
  sta saved_d000+$16


  lda music_enabled+1
  beq SID_init2
  jmp no_SID_init2
SID_init2:
  lda INITIAL_VALUES_HI + $27
  sta $d400
  lda INITIAL_VALUES_HI + $28
  sta $d401
  lda INITIAL_VALUES_HI + $29
  sta $d402
  lda INITIAL_VALUES_HI + $2a
  sta $d403
  lda INITIAL_VALUES_HI + $2c
  sta $d405
  lda INITIAL_VALUES_HI + $2d
  sta $d406
  lda INITIAL_VALUES_HI + $2e
  sta $d407
  lda INITIAL_VALUES_HI + $2f
  sta $d408
  lda INITIAL_VALUES_HI + $30
  sta $d409
  lda INITIAL_VALUES_HI + $31
  sta $d40a
  lda INITIAL_VALUES_HI + $33
  sta $d40c
  lda INITIAL_VALUES_HI + $34
  sta $d40d
  lda INITIAL_VALUES_HI + $35
  sta $d40e
  lda INITIAL_VALUES_HI + $36
  sta $d40f
  lda INITIAL_VALUES_HI + $37
  sta $d410
  lda INITIAL_VALUES_HI + $38
  sta $d411
  lda INITIAL_VALUES_HI + $3a
  sta $d413
  lda INITIAL_VALUES_HI + $3b
  sta $d414
  lda INITIAL_VALUES_HI + $3c
  sta $d416
  lda INITIAL_VALUES_HI + $3d
  sta $d417
  lda INITIAL_VALUES_HI + $3e
  sta $d418
  lda INITIAL_VALUES_HI + $2b
  sta $d404
  lda INITIAL_VALUES_HI + $32
  sta $d40b
  lda INITIAL_VALUES_HI + $39
  sta $d412
no_SID_init2:
  lda INITIAL_VALUES_HI + $3f
  sta nof_values_to_track_hi+1

game_counter_char = $02
  jsr do_another_game_counter_hi
  lda #game_counter_char
  sta SCREEN_HI + 40 + 38

; Copy screen colours
  ldy #$3f
morco0_hi:
  lda COLRAM_HI,y
  sta $d800,y
  lda COLRAM_HI+$40,y
  sta $d840,y
  dey
  bpl morco0_hi

;This is outside of the screen:
  lda INITIAL_VALUES_HI + $18
  sta $d020
  lda INITIAL_VALUES_HI + $19
  sta $d021

  ldy #$3f
morco0b_hi:
  lda COLRAM_HI+$80,y
  sta $d880,y
  lda COLRAM_HI+$c0,y
  sta $d8c0,y
  dey
  bpl morco0b_hi

  ldy #$3f
morco1_hi:
  lda COLRAM_HI+$100,y
  sta $d900,y
  lda COLRAM_HI+$140,y
  sta $d940,y
  lda COLRAM_HI+$180,y
  sta $d980,y
  lda COLRAM_HI+$1c0,y
  sta $d9c0,y
  dey
  bpl morco1_hi
  ldy #$3f
morco2_hi:
  lda COLRAM_HI+$200,y
  sta $da00,y
  lda COLRAM_HI+$240,y
  sta $da40,y
  lda COLRAM_HI+$280,y
  sta $da80,y
  lda COLRAM_HI+$2c0,y
  sta $dac0,y
  dey
  bpl morco2_hi
  ldy #$2f
morco3_hi:
  lda COLRAM_HI+$300,y
  sta $db00,y
  lda COLRAM_HI+$330,y
  sta $db30,y
  lda COLRAM_HI+$360,y
  sta $db60,y
  lda COLRAM_HI+$390,y
  sta $db90,y
  lda COLRAM_HI+$3c0,y
  sta $dbc0,y
  dey
  bpl morco3_hi



;  lda INITIAL_VALUES_HI + $2b
;  sta $d404
;  lda INITIAL_VALUES_HI + $32
;  sta $d40b
;  lda INITIAL_VALUES_HI + $39
;  sta $d412


; DEBUG print for knowing row and column:
;  lda #$1
;  sta $d800 +  1 * 40 + 5
;  sta $d800 +  3 * 40 + 5
;  sta $d800 +  5 * 40 + 5
;  sta $d800 +  7 * 40 + 5
;  sta $d800 +  9 * 40 + 5
;  sta $d800 + 11 * 40 + 5
;  sta $d800 + 13 * 40 + 5
;  sta $d800 + 15 * 40 + 5
;  sta $d800 + 17 * 40 + 5
;  sta $d800 + 19 * 40 + 5
;  sta $d800 + 21 * 40 + 5
;  sta $d800 + 23 * 40 + 5
;  lda #$1
;  sta $d800 +  2 * 40 + 4
;  sta $d800 +  3 * 40 + 4
;  sta $d800 +  6 * 40 + 4
;  sta $d800 +  7 * 40 + 4
;  sta $d800 + 10 * 40 + 4
;  sta $d800 + 11 * 40 + 4
;  sta $d800 + 14 * 40 + 4
;  sta $d800 + 15 * 40 + 4
;  sta $d800 + 18 * 40 + 4
;  sta $d800 + 19 * 40 + 4
;  sta $d800 + 22 * 40 + 4
;  sta $d800 + 23 * 40 + 4
;  lda #$1
;  sta $d800 +  4 * 40 + 3
;  sta $d800 +  5 * 40 + 3
;  sta $d800 +  6 * 40 + 3
;  sta $d800 +  7 * 40 + 3
;  sta $d800 + 12 * 40 + 3
;  sta $d800 + 13 * 40 + 3
;  sta $d800 + 14 * 40 + 3
;  sta $d800 + 15 * 40 + 3
;  sta $d800 + 20 * 40 + 3
;  sta $d800 + 21 * 40 + 3
;  sta $d800 + 22 * 40 + 3
;  sta $d800 + 23 * 40 + 3
;  lda #$1
;  sta $d800 +  8 * 40 + 2
;  sta $d800 +  9 * 40 + 2
;  sta $d800 + 10 * 40 + 2
;  sta $d800 + 11 * 40 + 2
;  sta $d800 + 12 * 40 + 2
;  sta $d800 + 13 * 40 + 2
;  sta $d800 + 14 * 40 + 2
;  sta $d800 + 15 * 40 + 2
;  sta $d800 + 24 * 40 + 2
;  lda #$1
;  sta $d800 + 16 * 40 + 1
;  sta $d800 + 17 * 40 + 1
;  sta $d800 + 18 * 40 + 1
;  sta $d800 + 19 * 40 + 1
;  sta $d800 + 20 * 40 + 1
;  sta $d800 + 21 * 40 + 1
;  sta $d800 + 22 * 40 + 1
;  sta $d800 + 23 * 40 + 1
;  sta $d800 + 24 * 40 + 1
;
;  lda #1
;  sta SCREEN_HI +  1 * 40 + 5
;  sta SCREEN_HI +  3 * 40 + 5
;  sta SCREEN_HI +  5 * 40 + 5
;  sta SCREEN_HI +  7 * 40 + 5
;  sta SCREEN_HI +  9 * 40 + 5
;  sta SCREEN_HI + 11 * 40 + 5
;  sta SCREEN_HI + 13 * 40 + 5
;  sta SCREEN_HI + 15 * 40 + 5
;  sta SCREEN_HI + 17 * 40 + 5
;  sta SCREEN_HI + 19 * 40 + 5
;  sta SCREEN_HI + 21 * 40 + 5
;  sta SCREEN_HI + 23 * 40 + 5
;  sta SCREEN_HI +  2 * 40 + 4
;  sta SCREEN_HI +  3 * 40 + 4
;  sta SCREEN_HI +  6 * 40 + 4
;  sta SCREEN_HI +  7 * 40 + 4
;  sta SCREEN_HI + 10 * 40 + 4
;  sta SCREEN_HI + 11 * 40 + 4
;  sta SCREEN_HI + 14 * 40 + 4
;  sta SCREEN_HI + 15 * 40 + 4
;  sta SCREEN_HI + 18 * 40 + 4
;  sta SCREEN_HI + 19 * 40 + 4
;  sta SCREEN_HI + 22 * 40 + 4
;  sta SCREEN_HI + 23 * 40 + 4
;  sta SCREEN_HI +  4 * 40 + 3
;  sta SCREEN_HI +  5 * 40 + 3
;  sta SCREEN_HI +  6 * 40 + 3
;  sta SCREEN_HI +  7 * 40 + 3
;  sta SCREEN_HI + 12 * 40 + 3
;  sta SCREEN_HI + 13 * 40 + 3
;  sta SCREEN_HI + 14 * 40 + 3
;  sta SCREEN_HI + 15 * 40 + 3
;  sta SCREEN_HI + 20 * 40 + 3
;  sta SCREEN_HI + 21 * 40 + 3
;  sta SCREEN_HI + 22 * 40 + 3
;  sta SCREEN_HI + 23 * 40 + 3
;  sta SCREEN_HI +  8 * 40 + 2
;  sta SCREEN_HI +  9 * 40 + 2
;  sta SCREEN_HI + 10 * 40 + 2
;  sta SCREEN_HI + 11 * 40 + 2
;  sta SCREEN_HI + 12 * 40 + 2
;  sta SCREEN_HI + 13 * 40 + 2
;  sta SCREEN_HI + 14 * 40 + 2
;  sta SCREEN_HI + 15 * 40 + 2
;  sta SCREEN_HI + 24 * 40 + 2
;  sta SCREEN_HI + 16 * 40 + 1
;  sta SCREEN_HI + 17 * 40 + 1
;  sta SCREEN_HI + 18 * 40 + 1
;  sta SCREEN_HI + 19 * 40 + 1
;  sta SCREEN_HI + 20 * 40 + 1
;  sta SCREEN_HI + 21 * 40 + 1
;  sta SCREEN_HI + 22 * 40 + 1
;  sta SCREEN_HI + 23 * 40 + 1
;  sta SCREEN_HI + 24 * 40 + 1
;
;  lda #1
;  sta $d800 + 12 * 40 + 10
;  sta $d800 + 12 * 40 + 20
;  sta $d800 + 12 * 40 + 30
;  lda #1
;  sta SCREEN_HI + 12 * 40 + 10
;  sta SCREEN_HI + 12 * 40 + 20
;  sta SCREEN_HI + 12 * 40 + 30
;  lda #0
;  sta $d800 + 12 * 40 + 9
;  sta $d800 + 12 * 40 + 19
;  sta $d800 + 12 * 40 + 29
;  lda #1
;  sta SCREEN_HI + 12 * 40 + 9
;  sta SCREEN_HI + 12 * 40 + 19
;  sta SCREEN_HI + 12 * 40 + 29
  rts



hard_exit:
  jsr init_anim2_hi
  lda #$81
  sta anim_enabled+1

  ; No need to load any more games, but we will need to wait for the last one to finish:
  ; And, we probably should fake some values regarding the last sprtext that normally would reside in the next loaded game:
  ; Normally, we would load the next scene here to "lo".
  ; so, initialize some "lo" values here:
  lda #0
  ; The greetingstext charcol:
  sta CCOL0_LO
  ; The greetingstext sprcol:
  sta SCOL0_LO
;  lda #0
;  sta SPRY0_LO
;  sta SPRX0_LO

  ; Clear the "next" sprtext, the one that starts 25 frames before the real end:
  jsr init_sprtext_lo
  jsr prepare_anim2_lo

wait_for_last_anim_end:
  lda anim_done+1
  beq wait_for_last_anim_end

  sei
  lda #0
  sta $d01a
  dec $d019
  lda #$7f
  sta $dd0d
  lda $dd0d
  sta $dc0d
  lda $dc0d
  lda #0
  sta $d015

;now, unpack "Another visitor. Stay a while. Stay forever" that is at $d000-$dfff.
; It was loaded during the noisefader ghostbytescroller intro 4 minutes ago.

  ;!macro set_depack_pointers $d000
  ; This is unpacked to $e000-$f800
  lda #<$d000
  sta bitfire_load_addr_lo
  lda #>$d000
  sta bitfire_load_addr_hi

; HOWEVER: If booting directly from disk #2, it's not there.
; So, we need to check if it's there.
  lda #$34
  sta $01
  lda $d000
  cmp #0         ;third byte in "stay.prg" (first byte after loading address)
  bne no_stay_was_loaded
  lda $d001
  cmp #$e0         ;fourth byte in "stay.prg" (second byte after loading address)
  bne no_stay_was_loaded
  jsr link_decomp
  lda #$35
  sta $01
  ;Play the sample:
  ; This trashes $0800-$0cff, $a5-$d5, I think
  jsr $f700
;Move PETSCII screen to $0400
  ldx #0
copy_screen:
  lda $2000,x
  sta $0400,x
  lda $2100,x
  sta $0500,x
  lda $2200,x
  sta $0600,x
  lda $2300,x
  sta $0700,x
  inx
  bne copy_screen
  jmp contimuue

no_stay_was_loaded:
  lda #$35
  sta $01
  lda #$0b
  sta $d011
;Clear the PETSCII screen, so if stay_a_while isn't loaded from disk#1, we'll have an empty screen:
;Move PETSCII screen to $0400
  ldx #0
empty_screen:
  lda #$20
  sta $0400,x
  sta $0500,x
  sta $0600,x
  sta $0700,x
  lda #$e
  sta $d800,x
  sta $d900,x
  sta $da00,x
  sta $db00,x
  inx
  bne empty_screen
  syncite555:
  lda $d011
  bpl syncite555
syncite666:
  lda $d011
  bmi syncite666
  lda #$6
  sta $d020
  lda #$e
  sta $d021
contimuue:

syncite55:
  lda $d011
  bpl syncite55
syncite66:
  lda $d011
  bmi syncite66
;Stop blinking the cursor:
  sei
;Show screen:
  lda #$1b
  sta $d011
;No multicolour:
  lda #$c8
  sta $d016
;Bank #0:
  lda #3
  sta $dd00

;Screen at $0400. Normal ROM font.
  lda #$15
  sta $d018
  jsr link_load_next_comp
  jmp $2000





  !align 255,0,0
tmp_LIST_STREAK_LO:   !fill $100,0
tmp_LIST_BASE_LSB_LO: !fill $100,0
tmp_LIST_BASE_MSB_LO: !fill $100,0

tmp_LIST_STREAK_HI:   !fill $100,0
tmp_LIST_BASE_LSB_HI: !fill $100,0
tmp_LIST_BASE_MSB_HI: !fill $100,0



ZP_START:
  ; dasm syntax:  RORG ZP_CODE
  ; ACME syntax:
  !pseudopc ZP_CODE {
; This routine is to be copied into zeropage, take approximately 0x60 bytes in memory:
no_more_wait_lo:
  lda LIST_ADDR_MSB_LO,x
  sta <(dest_poi_lo+2)
  cmp #$d0
  bne no_mirror_lo
  lda #>saved_d000
no_mirror_lo:
  sta <(dest_poi_lo2+2)
  lda LIST_ADDR_LSB_LO,x
  sta <(dest_poi_lo+1)
  sta <(dest_poi_lo2+1)

  lda tmp_LIST_BASE_LSB_LO,x
  sta <(this_list_poi_lo+1)
  sta <(this_list_poi2_lo+1)
  lda tmp_LIST_BASE_MSB_LO,x
  sta <(this_list_poi_lo+2)
  sta <(this_list_poi2_lo+2)

  ldy tmp_LIST_STREAK_LO,x
  beq streak_ended_lo
  dey
  tya
  sta tmp_LIST_STREAK_LO,x
  ldy LIST_POI_LO,x
  jmp grab_a_value_lo

streak_ended_lo:
;Get a value and see if it's a wait or a streak:
  ldy LIST_POI_LO,x
;If it's a zero, it's the end of the list:
  beq next_addr_please_lo
this_list_poi_lo:
  lda $1000,y
;If it's >$80 it's a streak
  bmi do_streak_lo
;It's a wait:
  sta LIST_WAIT_LO,x
;I want a jmp:
;  jmp inc_and_grab_lo
; But a bpl will do the same:
  bpl inc_and_grab_lo

do_streak_lo:
  and #$7f
  sta tmp_LIST_STREAK_LO,x
inc_and_grab_lo:
  dey

grab_a_value_lo:
this_list_poi2_lo:
  lda $1000,y
dest_poi_lo:
  sta $d000
; The write below is to keep mirrored registers of all $d000-$d0ff writes. Can grab these values from saved_d000+$00-$2f when needed
dest_poi_lo2:
  sta saved_d000

;move pointer:
  dey
  tya
  sta LIST_POI_LO,x

next_addr_please_lo:
  dex
  beq lo_rts
LO_START_ZP:
do_next_addr_lo:
  ldy LIST_WAIT_LO,x
  beq no_more_wait_lo
  dey
  tya
  sta LIST_WAIT_LO,x
  dex
  bne do_next_addr_lo
lo_rts:
  rts


LO_END_ZP:

; This routine is to be copied into zeropage, take approximately 0x60 bytes in memory:
no_more_wait_hi:
  lda LIST_ADDR_MSB_HI,x
  sta <(dest_poi_hi+2)
  cmp #$d0
  bne no_mirror_hi
  lda #>saved_d000
no_mirror_hi:
  sta <(dest_poi_hi2+2)
  lda LIST_ADDR_LSB_HI,x
  sta <(dest_poi_hi+1)
  sta <(dest_poi_hi2+1)

  lda tmp_LIST_BASE_LSB_HI,x
  sta <(this_list_poi_hi+1)
  sta <(this_list_poi2_hi+1)
  lda tmp_LIST_BASE_MSB_HI,x
  sta <(this_list_poi_hi+2)
  sta <(this_list_poi2_hi+2)

  ldy tmp_LIST_STREAK_HI,x
  beq streak_ended_hi
  dey
  tya
  sta tmp_LIST_STREAK_HI,x
  ldy LIST_POI_HI,x
  jmp grab_a_value_hi

streak_ended_hi:
;Get a value and see if it's a wait or a streak:
  ldy LIST_POI_HI,x
;If it's a zero, it's the end of the list:
  beq next_addr_please_hi
this_list_poi_hi:
  lda $1000,y
;If it's >$80 it's a streak
  bmi do_streak_hi
;It's a wait:
  sta LIST_WAIT_HI,x
;I want a jmp:
;  jmp inc_and_grab_hi
; But a bpl will do the same:
  bpl inc_and_grab_hi

do_streak_hi:
  and #$7f
  sta tmp_LIST_STREAK_HI,x
inc_and_grab_hi:
  dey

grab_a_value_hi:
this_list_poi2_hi:
  lda $1000,y
dest_poi_hi:
  sta $d000
; The write below is to keep mirrored registers of all $d000-$d0ff writes. Can grab these values from saved_d000+$00-$2f when needed
dest_poi_hi2:
  sta saved_d000

;move pointer:
  dey
  tya
  sta LIST_POI_HI,x

next_addr_please_hi:
  dex
  beq hi_rts
HI_START_ZP:
do_next_addr_hi:
  ldy LIST_WAIT_HI,x
  beq no_more_wait_hi
  dey
  tya
  sta LIST_WAIT_HI,x
  dex
  bne do_next_addr_hi
hi_rts:
  rts

HI_END_ZP:

; End of psuedopc ZP_CODE:
}
ZP_END:




  !align 255,0,0
spritemat0:
  !bin "spritemat/sprite_image_0.spr"
spritemat0_end:

; krakout starts at $34c6:
;  *= $34c6
; GAUNTLET starts at $3552:
;  *= $3552
;  !bin "packer/output/00.raw",,2
;Comic Bakery start:
  *= $3631
  !bin "packer/output/00.raw",,2



LIST_END_LO = $3800
LIST_ADDR_LSB_LO = $3800 ;addr0_lo, addr1_lo, addr2_lo
LIST_ADDR_MSB_LO = $3900 ;addr0_hi, addr1_hi,...
LIST_POI_LO = $3a00 ;list0_poi, list1_poi,   ...counts downwards to zero. Zero means done. At start=list_length
LIST_WAIT_LO = $3b00 ;list0_wait, list1_wait, list2_wait

COLRAM_LO = $3c00 ;-$3fe7
; The greetingstext charcol:
CCOL0_LO = $3fe8
; The greetingstext sprcol:
SCOL0_LO = $3fe9
; The destination x pos:
;     spr_x0  and spr_x1  are signed values from the middle of the screen  - capped at -128 to +127
;     Position 50 in $d000 is at the left edge of the screen
SPRX0_LO = $3fea
; The destination y pos:
;      spr_y0 is row_number * 8 + 50
;      23 * 8 = 184     so max value is 234
SPRY0_LO = $3feb
CCOL1_LO = $3fec
SCOL1_LO = $3fed
SPRX1_LO = $3fee
SPRY1_LO = $3fef


CHARSET_LO = $4000
;Need 40*2 = 80 chars for texts. Ideally, 160 of them. Too many = 1280 bytes. Only 768 bytes left for game chars.
;Instead, allocate dynamically from the "end of the charset". Which means that the games with few chars in may have 
;greetings with long names in them.
;Never put sprites in (some of them) parts.

;$4xx0-$47bf SPRITES_LO (some of them)
INITIAL_VALUES_LO = $47c0  ;-$47fe d000-d02e + d400-d418
SCREEN_LO = $4800 ;-$4be7 SCREEN_LO
SPRPOI_LO = $4bf8 ;-$4bff SPRPOI_LO
;$4c00-      SPRITES_LO_SECONDARY (the rest of them)

sprtext_spr0_lo = $6000
sprtext_spr1_lo = $6200
sprtext_spr0_hi = $6400
sprtext_spr1_hi = $6600

;-$73ff      SPRITES_HI_SECONDARY (the rest of them)
SCREEN_HI = $7400 ;-$77e7
SPRPOI_HI = $77f8 ;-$77ff
CHARSET_HI = $7800 ;-$7
;$7xx-       SPRITES_HI (some of them)
INITIAL_VALUES_HI = $7fc0 ;-$7ffe d000-d02e + d400-d418
COLRAM_HI = $8000 ;-$83e8
CCOL0_HI = $83e8
SCOL0_HI = $83e9
SPRX0_HI = $83ea
SPRY0_HI = $83eb
CCOL1_HI = $83ec
SCOL1_HI = $83ed
SPRX1_HI = $83ee
SPRY1_HI = $83ef

LIST_ADDR_LSB_HI = $8400 ;addr0_lo, addr1_lo, addr2_lo
LIST_ADDR_MSB_HI = $8500 ;addr0_hi, addr1_hi,...
LIST_POI_HI = $8600 ;list0_poi, list1_poi,   ...counts downwards to zero. Zero means done. At start=list_length
LIST_WAIT_HI = $8700 ;list0_wait, list1_wait, list2_wait
LIST_START_HI = $8800


  *= $a000
saved_d000:
  !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

numbers_hires1:
  !byte %00000000
  !byte %00000000
  !byte %00001111
  !byte %00001001
  !byte %00001001
  !byte %00001001
  !byte %00001001
  !byte %00001111

  !byte %00000000
  !byte %00000000
  !byte %00000010
  !byte %00000110
  !byte %00000010
  !byte %00000010
  !byte %00000010
  !byte %00000111

  !byte %00000000
  !byte %00000000
  !byte %00000110
  !byte %00001001
  !byte %00000010
  !byte %00000010
  !byte %00000100
  !byte %00001111

  !byte %00000000
  !byte %00000000
  !byte %00001111
  !byte %00000001
  !byte %00000110
  !byte %00000001
  !byte %00001001
  !byte %00000110

  !byte %00000000
  !byte %00000000
  !byte %00000011
  !byte %00000101
  !byte %00001001
  !byte %00001111
  !byte %00000001
  !byte %00000001

  !byte %00000000
  !byte %00000000
  !byte %00001111
  !byte %00001000
  !byte %00001110
  !byte %00000001
  !byte %00001001
  !byte %00000110

  !byte %00000000
  !byte %00000000
  !byte %00000110
  !byte %00001001
  !byte %00001000
  !byte %00001110
  !byte %00001001
  !byte %00000110

  !byte %00000000
  !byte %00000000
  !byte %00001111
  !byte %00000001
  !byte %00000010
  !byte %00001111
  !byte %00000100
  !byte %00000100

  !byte %00000000
  !byte %00000000
  !byte %00000110
  !byte %00001001
  !byte %00001001
  !byte %00000110
  !byte %00001001
  !byte %00000110

  !byte %00000000
  !byte %00000000
  !byte %00000110
  !byte %00001001
  !byte %00000111
  !byte %00000001
  !byte %00001001
  !byte %00000110



numbers_hires10:
;  !byte %00000000
;  !byte %11100000
;  !byte %10100000
;  !byte %10100000
;  !byte %10100000
;  !byte %10100000
;  !byte %11100000
;  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000

  !byte %00000000
  !byte %01000000
  !byte %11000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %11100000
  !byte %00000000

  !byte %00000000
  !byte %11100000
  !byte %00100000
  !byte %00100000
  !byte %11100000
  !byte %10000000
  !byte %11100000
  !byte %00000000

  !byte %00000000
  !byte %11100000
  !byte %00100000
  !byte %00100000
  !byte %11100000
  !byte %00100000
  !byte %11100000
  !byte %00000000

  !byte %00000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %00100000
  !byte %00100000
  !byte %00000000

  !byte %00000000
  !byte %11100000
  !byte %10000000
  !byte %11000000
  !byte %00100000
  !byte %10100000
  !byte %01000000
  !byte %00000000

  !byte %00000000
  !byte %11100000
  !byte %10000000
  !byte %10000000
  !byte %11100000
  !byte %10100000
  !byte %11100000
  !byte %00000000

  !byte %00000000
  !byte %11100000
  !byte %00100000
  !byte %00100000
  !byte %01100000
  !byte %00100000
  !byte %00100000
  !byte %00000000

  !byte %00000000
  !byte %11100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %10100000
  !byte %11100000
  !byte %00000000

  !byte %00000000
  !byte %11100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %00100000
  !byte %11100000
  !byte %00000000


do_another_game_counter_hi:
game_number_1:
  lda #0
  clc
  adc #1
  cmp #10
  bne nowwwr
  inc game_number_10+1
  lda #0
nowwwr:
  sta game_number_1 + 1
  asl
  asl
  asl
  tax
game_number_10:
  lda #0
  cmp #10
  beq do_100
  asl
  asl
  asl
  tay
  lda numbers_hires1,x
  ora numbers_hires10,y
  eor CHARSET_HI + game_counter_char * 8 + 0
  sta CHARSET_HI + game_counter_char * 8 + 0
  lda numbers_hires1  + 1,x
  ora numbers_hires10 + 1,y
  eor CHARSET_HI + game_counter_char * 8 + 1
  sta CHARSET_HI + game_counter_char * 8 + 1
  lda numbers_hires1  + 2,x
  ora numbers_hires10 + 2,y
  eor CHARSET_HI + game_counter_char * 8 + 2
  sta CHARSET_HI + game_counter_char * 8 + 2
  lda numbers_hires1  + 3,x
  ora numbers_hires10 + 3,y
  eor CHARSET_HI + game_counter_char * 8 + 3
  sta CHARSET_HI + game_counter_char * 8 + 3
  lda numbers_hires1  + 4,x
  ora numbers_hires10 + 4,y
  eor CHARSET_HI + game_counter_char * 8 + 4
  sta CHARSET_HI + game_counter_char * 8 + 4
  lda numbers_hires1  + 5,x
  ora numbers_hires10 + 5,y
  eor CHARSET_HI + game_counter_char * 8 + 5
  sta CHARSET_HI + game_counter_char * 8 + 5
  lda numbers_hires1  + 6,x
  ora numbers_hires10 + 6,y
  eor CHARSET_HI + game_counter_char * 8 + 6
  sta CHARSET_HI + game_counter_char * 8 + 6
  lda numbers_hires1  + 7,x
  ora numbers_hires10 + 7,y
  eor CHARSET_HI + game_counter_char * 8 + 7
  sta CHARSET_HI + game_counter_char * 8 + 7
  rts
do_100:
  lda #%10000000
  eor CHARSET_HI + game_counter_char * 8 + 0
  sta CHARSET_HI + game_counter_char * 8 + 0
  lda #%10111000
  eor CHARSET_HI + game_counter_char * 8 + 1
  sta CHARSET_HI + game_counter_char * 8 + 1
  lda #%10101000
  eor CHARSET_HI + game_counter_char * 8 + 2
  sta CHARSET_HI + game_counter_char * 8 + 2
  lda #%10101111
  eor CHARSET_HI + game_counter_char * 8 + 3
  sta CHARSET_HI + game_counter_char * 8 + 3
  lda #%10101101
  eor CHARSET_HI + game_counter_char * 8 + 4
  sta CHARSET_HI + game_counter_char * 8 + 4
  lda #%00111101
  eor CHARSET_HI + game_counter_char * 8 + 5
  sta CHARSET_HI + game_counter_char * 8 + 5
  lda #%00000101
  eor CHARSET_HI + game_counter_char * 8 + 6
  sta CHARSET_HI + game_counter_char * 8 + 6
  lda #%00000111
  eor CHARSET_HI + game_counter_char * 8 + 7
  sta CHARSET_HI + game_counter_char * 8 + 7
  rts


do_another_game_counter_lo:
  lda game_number_1+1
  clc
  adc #1
  cmp #10
  bne nowwwr_lo
  inc game_number_10+1
  lda #0
nowwwr_lo:
  sta game_number_1 + 1
  asl
  asl
  asl
  tax
  lda game_number_10 + 1
  cmp #10
  beq do_100_lo
  asl
  asl
  asl
  tay
  lda numbers_hires1,x
  ora numbers_hires10,y
  eor CHARSET_LO + game_counter_char * 8 + 0
  sta CHARSET_LO + game_counter_char * 8 + 0
  lda numbers_hires1  + 1,x
  ora numbers_hires10 + 1,y
  eor CHARSET_LO + game_counter_char * 8 + 1
  sta CHARSET_LO + game_counter_char * 8 + 1
  lda numbers_hires1  + 2,x
  ora numbers_hires10 + 2,y
  eor CHARSET_LO + game_counter_char * 8 + 2
  sta CHARSET_LO + game_counter_char * 8 + 2
  lda numbers_hires1  + 3,x
  ora numbers_hires10 + 3,y
  eor CHARSET_LO + game_counter_char * 8 + 3
  sta CHARSET_LO + game_counter_char * 8 + 3
  lda numbers_hires1  + 4,x
  ora numbers_hires10 + 4,y
  eor CHARSET_LO + game_counter_char * 8 + 4
  sta CHARSET_LO + game_counter_char * 8 + 4
  lda numbers_hires1  + 5,x
  ora numbers_hires10 + 5,y
  eor CHARSET_LO + game_counter_char * 8 + 5
  sta CHARSET_LO + game_counter_char * 8 + 5
  lda numbers_hires1  + 6,x
  ora numbers_hires10 + 6,y
  eor CHARSET_LO + game_counter_char * 8 + 6
  sta CHARSET_LO + game_counter_char * 8 + 6
  lda numbers_hires1  + 7,x
  ora numbers_hires10 + 7,y
  eor CHARSET_LO + game_counter_char * 8 + 7
  sta CHARSET_LO + game_counter_char * 8 + 7
  rts
do_100_lo:
  lda #%10000000
  eor CHARSET_LO + game_counter_char * 8 + 0
  sta CHARSET_LO + game_counter_char * 8 + 0
  lda #%10111000
  eor CHARSET_LO + game_counter_char * 8 + 1
  sta CHARSET_LO + game_counter_char * 8 + 1
  lda #%10101000
  eor CHARSET_LO + game_counter_char * 8 + 2
  sta CHARSET_LO + game_counter_char * 8 + 2
  lda #%10101111
  eor CHARSET_LO + game_counter_char * 8 + 3
  sta CHARSET_LO + game_counter_char * 8 + 3
  lda #%10101101
  eor CHARSET_LO + game_counter_char * 8 + 4
  sta CHARSET_LO + game_counter_char * 8 + 4
  lda #%00111101
  eor CHARSET_LO + game_counter_char * 8 + 5
  sta CHARSET_LO + game_counter_char * 8 + 5
  lda #%00000101
  eor CHARSET_LO + game_counter_char * 8 + 6
  sta CHARSET_LO + game_counter_char * 8 + 6
  lda #%00000111
  eor CHARSET_LO + game_counter_char * 8 + 7
  sta CHARSET_LO + game_counter_char * 8 + 7
  rts







sprite_mat = $5c00
first_sprite_no = (sprite_mat-$4000) / $40
;first_sprite_no = 0
screen0 = $4800
;SCREEN_LO = $4800 ;-$4be7 SCREEN_LO
;sprtext_spr0_lo = $6000
;sprtext_spr1_lo = $6200
;sprtext_spr0_hi = $6400
;sprtext_spr1_hi = $6600
;SCREEN_HI = $7400 ;-$77e7


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
;;set sprite pointers:
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
save_x1:
  ldx #0
  pla
  rti

irq_2:
; stable irq through timer dc04:
!ifndef DISABLE_STABLE {
  pha
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
save_x2:
  ldx #0
  pla
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
save_x3:
  ldx #0
  pla
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
save_x4:
  ldx #0
  pla
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
save_x5:
  ldx #0
  pla
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
  lda #<irq_7
  sta $fffe
  lda #>irq_7
  sta $ffff
save_x6:
  ldx #0
  pla
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
  lda #1
  sta $d025
  lda #$0
  sta $d026
spritemat_d027:
  lda #$2
  sta $d027
  sta $d028
  sta $d029
  sta $d02a
  sta $d02b
  sta $d02c
  sta $d02d
  sta $d02e

  lda #$fa
  sta $d012
  lda #<irq_bottom
  sta $fffe
  lda #>irq_bottom
  sta $ffff
  asl $d019
save_x7:
  ldx #0
  pla
  rti


copy_a_sprite_mat:
; Let's update the pointers to which spritemat to copy down into $5c00:
sprmat_no:
  ldy #$ff
  iny
  sty sprmat_no+1
  lda sprmat_d01c_table,y
  sta spritemat_d01c+1
  lda sprmat_d027_table,y
  sta spritemat_d027+1
  lda sprmatpois_msb,y
  tay
  sty sprmatpoi0+2
  iny
  sty sprmatpoi1+2
  iny
  sty sprmatpoi2+2
  iny
  sty sprmatpoi3+2
  iny
  sty sprmatpoi4+2
  iny
  sty sprmatpoi5+2
  iny
  sty sprmatpoi6+2
  iny
  sty sprmatpoi7+2
  iny
  sty sprmatpoi8+2
  iny
  sty sprmatpoi9+2
  iny
  sty sprmatpoiA+2
  iny
  sty sprmatpoiB+2
  iny
  sty sprmatpoiC+2
  iny
  sty sprmatpoiD+2

writt:
  ldx #$0
fisp:
sprmatpoi0:
  lda spritemat0,x
  sta sprite_mat,x ;row0
sprmatpoi1:
  lda spritemat0+$100,x
  sta sprite_mat+$100,x
sprmatpoi2:
  lda spritemat0+$200,x
  sta sprite_mat+$200,x ;row1
sprmatpoi3:
  lda spritemat0+$300,x
  sta sprite_mat+$300,x
sprmatpoi4:
  lda spritemat0+$400,x
  sta sprite_mat+$400,x ;row2
sprmatpoi5:
  lda spritemat0+$500,x
  sta sprite_mat+$500,x
sprmatpoi6:
  lda spritemat0+$600,x
  sta sprite_mat+$600,x ;row3
sprmatpoi7:
  lda spritemat0+$700,x
  sta sprite_mat+$700,x
sprmatpoi8:
  lda spritemat0+$800,x
  sta sprite_mat+$800,x ;row4
sprmatpoi9:
  lda spritemat0+$900,x
  sta sprite_mat+$900,x
sprmatpoiA:
  lda spritemat0+$a00,x
  sta sprite_mat+$a00,x ;row5
sprmatpoiB:
  lda spritemat0+$b00,x
  sta sprite_mat+$b00,x
sprmatpoiC:
  lda spritemat0+$c00,x
  sta sprite_mat+$c00,x ;row6
sprmatpoiD:
  lda spritemat0+$d00,x
  sta sprite_mat+$d00,x ;=$6900
  inx
  bne fisp
  rts












greetings:
;byte "!!##$$%%&&´´",0
;byte "(())**++,,--..//",0
;byte "0011223344556677",0
;byte "8899::;;<<==>>??",0
;byte "@@AABBCCDDEEFFGG",0
;byte "HHIIJJKKLLMMNNOO",0
;byte "PPQQRRSSTTUUVVWW",0
;byte "XXYYZZ[[\\]]^^__",0
;byte "``aabbccddeeffgg",0
;byte "hhiijjkkllmmnnoo",0
;byte "ppqqrrssttuuvvww",0
;byte "xxyyzz{{||}}~~",0


; These are the only games that are limited due to "many chars used on screen"
; 72 chars are needed for 6 sprites in a row copied to chars:
;018 nof_chars_free for game_no=15 in export 'MASTLAMP'
;037 nof_chars_free for game_no=34 in export 'MMADNESS'
;053 nof_chars_free for game_no=57 in export 'BOMBJACK'
;054 nof_chars_free for game_no=22 in export 'PITFALL2'
;054 nof_chars_free for game_no=98 in export 'YIEAR2'
;070 nof_chars_free for game_no=8 in export 'HOTWHEEL'
; Besides this, the sprite multiplexer can sometimes fail displaying sprites if the game has many sprites on the screen
; And, we need screen estate to put the text in.

;If I want to keep the text on screen, these are the games that have trouble with 2*full-length texts:
;091 nof_chars_free for game_no=13 in export 'ROBOCOP2'
;104 nof_chars_free for game_no=46 in export 'HIGHNOON'
;111 nof_chars_free for game_no=50 in export 'CKHAFKA2'
;113 nof_chars_free for game_no=25 in export 'GBUSTERS'
;115 nof_chars_free for game_no=39 in export 'CKHAFKA'
;118 nof_chars_free for game_no=37 in export 'ManiacMansion'
;128 nof_chars_free for game_no=85 in export 'AIRWOLF'
;135 nof_chars_free for game_no=89 in export 'BIGGLES'
;138 nof_chars_free for game_no=54 in export 'GHETTOBL'
;140 nof_chars_free for game_no=73 in export 'FPATROL2'
;143 nof_chars_free for game_no=65 in export 'Arkanoid'



;byte"hhiijjkkllmmnnoo",0














;byte"Abcdefghijklmnopq",0 ;02

!text " ",0                                 ;01 Comic Bakery
!text " ",0                                 ;01
!text " ",0                                 ;02 gauntlet
!text "You know why we are here",0          ;02
!text "Ritually skrambling with our",0      ;03 skramble
!text "vintage toys of childhood",0         ;03
!text "Performers are about",0              ;04 isoccer88
!text "to soccer your",0                    ;04
!text "nostalgic FRAK",0                    ;05 Frak
!text "into bliss and bless",0              ;05
!text "Getting together",0                  ;06 Skate or Die
!text "skate or joy",0                      ;06
!text "Hours after hours",0                 ;07 Bruce Lee
!text "with Bruce Lee",0                    ;07
!text "in",0                                ;08 Henry's house
!text "Henry's house",0                     ;08 
!text "For Performers",0                    ;09 Impossible Mission
!text "no mission is impossible!",0         ;09
!text "Taking our time,",0                  ;10 Oil's well
!text "if the oil is well",0                ;10
!text "for raids over Moscow",0             ;11 Raid over Moscow
!text "and trips",0                         ;11
!text "into the temple",0                   ;12 Temple of Apshai
!text "of Apshai",0                         ;12
!text "Performers go down",0                ;13 Krakout
!text "in a complete Krakout",0             ;13
!text "Rolands machen",0                    ;14 Roland's rat race
!text "das so!",0                           ;14

; THIS IS THE FIRST SPRITE MAT "the 100 best moments in our lives"
!text "There's no cure for Uridium",$ff     ;15 URIDIUM_2
!text " ",0                                 ;15
;!text " ",0                                ;16 Paperboy
;!text " ",0                                ;16
;!text " ",0                                ;17 ManiacMansion
;!text " ",0                                ;17
!text "We did escape",0                     ;18 CAVELON
!text "Cavelon",0                           ;18
!text "and saved our sweat for",0           ;19 new/AZTECCHA
!text "Aztec-fucking-challenge!!!",0        ;19
!text "Sometimes we all",0                  ;20 LOCO
!text "went LOCO, especially",0             ;20
!text "when something was brewin",0         ;21 new/CAULDRON_2
!text "in the Cauldron.",0                  ;21
!text "Beware of the robo",0                ;22 ROBOCOP2
!text "cop - we'd rather",0                 ;22
!text "fly",0                               ;23 MASTLAMP
!text "a mat",0                             ;23
!text "Bizarre, really.",0                  ;24 new/TBIZARRE
!text "How low can you fall?",0             ;24
!text "Performers",0                        ;25 MONTEZUM
!text "never fall",0                        ;25
!text "We know our beer",0                  ;26 TAPPER
!text "it's not about quantity",0           ;26
!text "quantity makes us",0                 ;27 LAZARIAN_
!text "lazarians",0                         ;27
!text "GOLD,",0                             ;28 HEROGOLD
!text "Hero!",0                             ;28
!text "Next level avoids all",0             ;29 PITFALL2
!text "pitfalls",0                          ;29
!text "We just grab a",0                    ;30 SPACETAX
!text "space taxi instead!",0               ;30
!text "Who you gonna",0                     ;31 GBUSTERS
!text "call? Performers!",0                 ;31
!text "Was there ever",0                    ;32 DRUID2
!text "a DRUID 1?",0                        ;32
!text "Dancing in the hall",0               ;33 MOUNKING
!text "of the mountain king",0              ;33
!text "with our",0                          ;34 JETPAC
!text "Jetpack",0                           ;34
!text "and Commodore 64",0                  ;35 KILLWATT
!text "to kill a Watt",0                    ;35
!text "Breakout those",0                    ;36 Arkanoid
!text "fart samples, Galway",0              ;36
!text "Forth is replaced with",0            ;37 FORTAPOC
!text "C and RUST apocalypse.",0            ;37
!text "Performers just",0                   ;38 BLAGGER
!text "don't blagger anymore.",0            ;38
!text "that's just",0                       ;39 MMADNESS
!text "madness, marble.",0                  ;39
!text "ZENJI! she said.",0                  ;40 ZENJI
!text "Bless you, we said",0                ;40
!text "Have you ever had a feeling",0       ;41 CAULDRN2_2
!text "of deja vu?",0                       ;41
!text "Revenge is best served",0            ;42 GROGSREV_3
!text "with a GROG!",0                      ;42

; THIS IS THE SECOND SPRITE MAT:
!text "Next Level by Performers",$ff        ;43 RAMBO
!text " ",0                                 ;43
;!text " ",0                                ;44 FLIPA737_2
;!text " ",0                                ;44
;!text " ",0                                ;45 new/DOTC
;!text " ",0                                ;45
!text "Guybrush wasn't",0                   ;46 PIRATES1
!text "invented yet",0                      ;46
!text "so playing World Cup",0              ;47 WORLDCUP
!text "soccer with friends",0               ;47
!text "or the elevator",0                   ;48 CKHAFKA
!text "in Khafka's cavern",0                ;48
!text "and shaking",0                       ;49 PENGO
!text "walls in Pengo",0                    ;49
!text "was Performers' Gold,",0             ;50 GILLGOLD
!text "Gillian",0                           ;50
!text "Or challenge us to duel",0           ;51 HIGHNOON
!text "at high noon",0                      ;51
!text "Flappy birds",0                      ;52 SHAMUS2_
!text "on a ladder, Shamus",0               ;52
!text "Kernkraft 400",0                     ;53 LAZYJONE
!text "Mr Jones",0                          ;53
!text "It's a",0                            ;54 THINGONA
!text "thing on a boing",0                  ;54
!text "Performers are making",0             ;55 new/PANIC64
!text "panic ketchup",0                     ;55
!text "but long after",0                    ;56 1942
!text "1942",0                              ;56
!text "Gubbdata sing-a-long",0              ;57 AIRWOLF
!text "theme song!",0                       ;57
!text "It's your saga,",0                   ;58 RASTAN
!text "Rastan",0                            ;58
!text "Nik Kershaw",0                       ;59 D64HUMA
!text "went human racing",0                 ;59

; THIS IS THE THIRD SPRITE MAT:
!text "Man, it's time to pac!",$ff          ;60 PacMan
!text " ",$0                                ;60
;!text " ",0                                ;61 CKHAFKA2
;!text " ",0                                ;61
;!text " ",0                                ;62 GHETTOBL
;!text " ",0                                ;62
!text "The first Spanish",0                 ;63 BoogaBoo
!text "game ever: Booga Boo",0              ;63
!text "Performers do games, too",0          ;64 Flaschbier
!text "Flaschbier by Peiselulli",0          ;64
!text "Don't get caught",0                  ;65 CROSSFIR
!text "in the crossfire",0                  ;65
!text "Can you disarm",0                    ;66 BOMBJACK
!text "bombs, Jack?",0                      ;66
!text "You can also go skiing,",0           ;67 HHORACE
!text "Horace. You hungry?",0               ;67
!text "I have a hunch you'll say",0         ;68 HUNCHBK2
!text "I'll be back, too!",0                ;68
!text "Beware of Gorgolytes,",0             ;69 Drelbs
!text "and Trollaboar, Drelb!",0            ;69
!text "She didn't even like men,",0         ;70 SAMFOX
!text "and not puberty boys either!",0      ;70
!text "Put on cyberpunk goggles,",0         ;71 BIGGLES
!text "Biggles!",0                          ;71
!text "Have you ever had a feeling",0       ;72 CAULDRN2
!text "of deja vu?",0                       ;72
!text "Beppel buppel bappel",0              ;73 BBOBBLE
!text "booble bubble bipple?",0             ;73
!text "That's dangerous, Dick!",0           ;74 RICKDAN2
!text "We're up to 74 games now!",0         ;74
!text "Performers says it's time",0         ;75 BURGRTIM
!text "for burgers!",0                      ;75
!text "Spoiler: 999 isn't even",0           ;76 PARADROI
!text "a stable paradroid.",0               ;76
!text "Roger, Falcon.",0                    ;77 FPATROL2
!text "Do your patrol.",0                   ;77
!text "Makaimura, said Guinevere",0         ;78 GGOBLINS
!text "Ghosts 'n Goblins, Arthur!",0        ;78
!text "Gianna Nannini",0                    ;79 GIANA
!text "has a brother.",0                    ;79
!text "Jeff Minter is God.",0               ;80 HOVERBOV
!text "So do your Hover, Bovver.",0         ;80
!text "Rescue snowbird Cora,",0             ;81 SNOKIE
!text "Snokie!",0                           ;81

; THIS IS THE FOURTH SPRITE MAT:
!text "Love is a special feeling",$ff       ;82 NEBULUS
!text " ",0                                 ;82
;!text " ",0                                ;83 WIZARDOW
;!text " ",0                                ;83
;!text " ",0                                ;84 NEVENDST2
;!text " ",0                                ;84
!text "Gnarp? Grub? Grof? Gulf? ",0         ;85 GORF
!text "Golf? GORF!",0                       ;85
!text "It's a BLUE",0                       ;86 BLUETHUN
!text "thunder MONDAY",0                    ;86
!text "You! Think about",0                  ;87 SPYHUNT
!text "this for a while:",0                 ;87
!text "How do you fit 100 games",0          ;88 MONTYRUN
!text "on a 175kB floppy disk?",0           ;88
!text "Optimize the shit",0                 ;89 AMC
!text "out of it!",0                        ;89
!text "Squeeze those bytes",0               ;90 TASK3
!text "make us proud",0                     ;90
!text "Commodore 64",0                      ;91 SPIPLIN
!text "- still rocking!",0                  ;91
!text "Performers can",0                    ;92 KETTLE
!text "Performers do",0                     ;92
!text "Always",0                            ;93 boulder1
!text "dash your boulders",0                ;93
!text "Is your desire for",0                ;94 SHAMUS
!text "nostalgia filled yet?",0             ;94
!text "We'll hit you with a few",0          ;95 URIDIUM
!text "more like Uridium,",0                ;95
!text "Dare Devil Dennis,",0                ;96 DDDENIS
!text "not to be forgotten",0               ;96
!text "the spiders of",0                    ;97 FBFOREST
!text "97. Forbidden Forest,",0             ;97
!text "the fights of",0                     ;98 YIEAR2
!text "98. Yie Ar Kunf-Fu II",0             ;98
!text "or 99. Revenge of",0                 ;99 Revenge
!text "those mutant camels",0               ;99
!text "100 THANKS",0                        ;100 Archon
!text "FOR WATCHING!",0                     ;100
!text " ",0 ; This text is never seen
!text " ",0 ;
!text " ",0 ;
!text " ",0 ;



init_sprtext_lo:
  ldx #0
  lda #$00
clrlomor:
  sta sprtext_spr0_lo,x ; = $6000
  sta sprtext_spr0_lo+$100,x ; = $6100
  sta sprtext_spr1_lo,x ; = $6200
  sta sprtext_spr1_lo+$100,x ; = $6300
  inx
  bne clrlomor
  rts

init_sprtext_hi:
  ldx #0
  lda #$00
clrhimor:
  sta sprtext_spr0_hi,x ; = $6400
  sta sprtext_spr0_hi+$100,x ; = $6500
  sta sprtext_spr1_hi,x ; = $6600
  sta sprtext_spr1_hi+$100,x ; = $6700
  inx
  bne clrhimor
done_with_chars:
  rts

write_another_char:
sprtext_textpoi:
  lda greetings
  bmi done_with_chars
  beq done_with_chars
  sec
  sbc #$20
  sta this_is_the_char+1
  ldy #sprtext_charset / 4 / 256
  sty charset_poi+2
  asl
  asl
  rol charset_poi+2
  asl
  rol charset_poi+2
  ora #$07
  sta charset_poi+1

sprtext_plotpos_x:
  lda #0
  lsr
  lsr
  lsr
  tax
  lda sprtext_offset_table_lsb,x
  sta sdest0+1
  sta sdest1+1
  sta sdest1b+1
  lda sprtext_offset_table_msb,x
current_sprtext_msb:
  ora #>sprtext_spr0_lo
  sta sdest0+2
  sta sdest1+2
  sta sdest1b+2
  inx
  lda sprtext_offset_table_lsb,x
  sta sdest2+1
  sta sdest2b+1
  sta sdest2c+1
  lda sprtext_offset_table_msb,x
  ora current_sprtext_msb+1
  sta sdest2+2
  sta sdest2b+2
  sta sdest2c+2

  ldx #7*6+3
grab_another_row:
  lda sprtext_plotpos_x+1
  and #07
  tay

charset_poi:
  lda sprtext_charset
  cpy #0
  beq done_moving
move_more:
  lsr
sdest2:
  ror sprtext_spr0_lo+1,x
  dey
  bne move_more

done_moving:
sdest0:
  ora sprtext_spr0_lo,x
sdest1:
  sta sprtext_spr0_lo,x
sdest2b:
  ldy sprtext_spr0_lo+1,x
  dex
  dex
  dex
sdest1b:
  sta sprtext_spr0_lo,x
  dec charset_poi+1
  tya
sdest2c:
  sta sprtext_spr0_lo+1,x
  dex
  dex
  dex
  bpl grab_another_row

  inc sprtext_textpoi+1
  bne nowrepp
  inc sprtext_textpoi+2
nowrepp:
  lda sprtext_plotpos_x+1
  clc
this_is_the_char:
  ldx #0
  adc char_widths,x
  sta sprtext_plotpos_x+1
  sta sprtochars_width
  rts

sprtext_offset_table_lsb:
  !byte 0,1,2,$40,$41,$42,$80,$81,$82,$c0,$c1,$c2,0,1,2,$40,$41,$42,$80,$81,$82,$c0,$c1,$c2
sprtext_offset_table_msb:
  !byte 0,0,0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1,1,1,  1,  1,  1,  1,  1,  1,  1,  1,  1

goto_next_greet_or_spritemat:

;check if (sprtext_textpoi) is $ff, if so,
;set do_mat to #1
  lda sprtext_textpoi+1
  sta check_mat+1
  lda sprtext_textpoi+2
  sta check_mat+2
check_mat:
  lda greetings
  cmp #$ff
  bne forced_goto_next_greet
; Let's continue with a sprite mat here:
  lda #3
  sta do_mat+1
  lda #1
  sta copy_mat+1
;Avoid having sprite garbage on screen for the first frame:
  lda #1
  sta frames_until_sprmat_visible+1

;Init the spritemat x-position to the right edge of the screen:
  lda #first_sprmat_x + 0*24
  sta sprmat_0x+1
  clc
  adc #24
  sta sprmat_1x+1
  clc
  adc #24
  sta sprmat_2x+1
  clc
  adc #24
  sta sprmat_3x+1
  clc
  adc #24
  sta sprmat_4x+1
  clc
  adc #24
  sta sprmat_5x+1
  clc
  adc #24
  sta sprmat_6x+1
  clc
  adc #24
  sta sprmat_7x+1
  lda #$ff
  sta sprmat_d010+1


forced_goto_next_greet:
;Not allowed to trash x-register here
  inc sprtext_textpoi+1
  bne nowrepp2
  inc sprtext_textpoi+2
nowrepp2:
  lda where_the_sprtext_sprites_are+1
  clc
  adc #8
  sta where_the_sprtext_sprites_are+1

  lda current_sprtext_msb+1
  clc
  adc #2
  cmp #>(sprtext_spr1_hi+$200)
  bne no_lolo
  lda #>sprtext_spr0_lo
  ldy #(sprtext_spr0_lo - $4000) / $40
  sty where_the_sprtext_sprites_are+1
no_lolo:
  sta current_sprtext_msb+1
  lda #0
  sta sprtext_plotpos_x+1
  rts

sprmatpois_msb:
  !byte >spritemat0
  !byte >spritemat1
  !byte >spritemat2
  !byte >spritemat3

sprmat_d01c_table:
  !byte $ff
  !byte $00
  !byte $00
  !byte $00

sprmat_d027_table:
  !byte $02
  !byte $0d
  !byte $07
  !byte $04



char_widths:
;         ! ""# $ % & ´ ( ) * + , - . /
  !byte 2,2,4,6,6,4,6,3,3,3,7,6,3,4,2,4
;       0 1 2 3 4 5 6 7 8 9 : ; < = > ?
  !byte 4,4,4,4,4,4,4,4,4,4,2,3,4,4,4,5
;       @ A B C D E F G H I J K L M N O
  !byte 9,4,4,4,4,4,4,5,4,4,4,5,4,6,6,4
;       P Q R S T U V W X Y Z [ \ ] ^ _
  !byte 4,4,4,4,4,4,6,6,4,4,4,3,6,3,4,4
;       ` a b c d e f g h i j k l m n o
  !byte 3,4,4,4,4,4,4,4,4,2,3,4,2,6,4,4
;       p q r s t u v w x y z { | } ~
  !byte 4,4,4,4,3,4,4,6,4,4,4,4,2,4,5,2


handle_misplacements:
misplacement_no:
  ldx #0

; Save the contents of x, y, d016 and d011 to be able to compensate for where the sprite is and where it should be.
!ifdef DEBUG {
; DEBUG: For compensating x and y in sprites when copying them to chars:
  ; This is where sprite 0 should be after compensation:
  lda $d011
  and #$07
  clc
  adc sprtext_ypos_dest
  sec
  sbc #3
  ; This is where sprite 0 is uncompensated:
  sec
  sbc sprtext_ypos
  ; This is the yoffset we will need to use to make a smooth transition from sprites to chars aften an "uncomplete" moving average:
  sta $f000,x

  ; This is where sprite 0 should be after compensation:
  lda sprtext_xpos_dest ; xpos=128 is in the middle of the screen.  #$b8 -> $d000 is in the middle as well
  clc
  adc #$38
  sec
  sbc sprtext_plotpos_x+1
  ;a is the spr x position
  sec
  sbc #$18
  lsr
  lsr
  lsr
  ;a is the char column
  asl
  asl
  asl
  clc
  adc #$18
  sta mispl_tmp0+1

  ; This is where sprite 0 is uncompensated:
  lda sprtext_xpos      ; xpos=128 is in the middle of the screen.  #$b8 -> $d000 is in the middle as well
  clc
  adc #$38
  sec
  sbc sprtext_plotpos_x+1
  sta mispl_tmp1+1

  ; This is the xoffset we will need to use to make a smooth transition from sprites to chars aften an "uncomplete" moving average:
mispl_tmp0:
  lda #0
  sec
mispl_tmp1:
  sbc #0
  sta $f100,x
}

  inx
  stx misplacement_no+1
dont_put_text1:
  rts


; Write chars into screen:
put_text1_on_screen:
  jsr handle_misplacements

  ;Check if the text it "too thin", which happens after every spritemat when the only char printed is a space " " = 2 pixels:
  lda sprtext_plotpos_x+1
  cmp #3
  bcc dont_put_text1

  lda anim_enabled+1
  bpl put_text1_on_screen_lo
;put_text1_on_screen_hi:
  ldx SPRY1_HI
  lda #>SCREEN_HI/4
  jmp put_cont

put_text1_on_screen_lo:
  ldx SPRY1_LO
  lda #>SCREEN_LO/4
put_cont:
  sta char_copy_poi+1
; between 50 and 208 currently
  txa
  sec
  sbc #50
  lsr
  lsr
  lsr
  ; Now we know which row to put the text in
  ; Multiply by $28 = 40 = 5*8
  sta the_one+1
  asl
  asl
  clc
the_one:
  adc #0
  ; Now multiply by 8, however, this is a 10-bit operation:
  asl
  asl
  rol char_copy_poi+1
  asl
  rol char_copy_poi+1
  sta char_copy_poi
  sta col_copy_poi
  clc
  adc #40
  sta char_copy_poi2
  sta col_copy_poi2

  lda char_copy_poi+1
  adc #0
  sta char_copy_poi2+1
  lda char_copy_poi+1
  and #$03
  ora #$d8
  sta col_copy_poi+1
  lda char_copy_poi2+1
  and #$03
  ora #$d8
  sta col_copy_poi2+1


  ; Find out how many chars we need to move due to x-pos:
  lda sprtext_xpos_dest ; xpos=128 is in the middle of the screen.  #$b8 -> $d000 is in the middle as well
  clc
  adc #$38
  sec
  sbc sprtext_plotpos_x+1
  ;a is the spr x position
  sec
  sbc #$18
  lsr
  lsr
  lsr
  ;a is the char column
  pha
  clc
  adc char_copy_poi
  sta char_copy_poi
  sta col_copy_poi
  bcc no_wrap44
  inc char_copy_poi+1
  inc col_copy_poi+1
no_wrap44:
  pla
  clc
  adc char_copy_poi2
  sta char_copy_poi2
  sta col_copy_poi2
  bcc no_wrap45
  inc char_copy_poi2+1
  inc col_copy_poi2+1
no_wrap45:

  ; Decide how many chars we need to write into the screen:
  lda sprtext_plotpos_x+1
  clc
  adc #3
  lsr
  lsr
  sta nof_chars_to_copy+1

  ldx #$ff
  ldy #0
loopit:
  txa
  sta (char_copy_poi2),y
  dex
  txa
  sta (char_copy_poi),y
charcols1:
  lda #4
  sta (col_copy_poi),y
  sta (col_copy_poi2),y
  dex
  iny
nof_chars_to_copy:
  cpy #24
  bne loopit
dont_put_text0:
  rts




; Write chars into screen:
put_text0_on_screen:
  jsr handle_misplacements

  ;Check if the text it "too thin", which happens after every spritemat when the only char printed is a space " " = 2 pixels:
  lda sprtext_plotpos_x+1
  cmp #3
  bcc dont_put_text0

  lda anim_enabled+1
  bpl put_text0_on_screen_lo
;put_text0_on_screen_hi:
  ldx SPRY0_HI
  lda #>SCREEN_HI/4
  jmp put_cont_0

put_text0_on_screen_lo:
  ldx SPRY0_LO
  lda #>SCREEN_LO/4
put_cont_0:
  sta char_copy_poi+1
; between 50 and 208 currently
  txa
  sec
  sbc #50
  lsr
  lsr
  lsr
  ; Now we know which row to put the text in
  ; Multiply by $28 = 40 = 5*8
  sta the_one_0+1
  asl
  asl
  clc
the_one_0:
  adc #0
  ; Now multiply by 8, however, this is a 10-bit operation:
  asl
  asl
  rol char_copy_poi+1
  asl
  rol char_copy_poi+1
  sta char_copy_poi
  sta col_copy_poi
  clc
  adc #40
  sta char_copy_poi2
  sta col_copy_poi2

  lda char_copy_poi+1
  adc #0
  sta char_copy_poi2+1
  lda char_copy_poi+1
  and #$03
  ora #$d8
  sta col_copy_poi+1
  lda char_copy_poi2+1
  and #$03
  ora #$d8
  sta col_copy_poi2+1


  ; Find out how many chars we need to move due to x-pos:
  lda sprtext_xpos_dest ; xpos=128 is in the middle of the screen.  #$b8 -> $d000 is in the middle as well
  clc
  adc #$38
  sec
  sbc sprtext_plotpos_x+1
  ;a is the spr x position
  sec
  sbc #$18
  lsr
  lsr
  lsr
  ;a is the char column
  pha
  clc
  adc char_copy_poi
  sta char_copy_poi
  sta col_copy_poi
  bcc no_wrap44_0
  inc char_copy_poi+1
  inc col_copy_poi+1
no_wrap44_0:
  pla
  clc
  adc char_copy_poi2
  sta char_copy_poi2
  sta col_copy_poi2
  bcc no_wrap45_0
  inc char_copy_poi2+1
  inc col_copy_poi2+1
no_wrap45_0:

  ; Save the screen position to know where to erase at frame_no #74:
  lda char_copy_poi
  sta erase_row0_char_poi+1
  lda char_copy_poi+1
  sta erase_row0_char_poi+2
  lda char_copy_poi2
  sta erase_row1_char_poi+1
  lda char_copy_poi2+1
  sta erase_row1_char_poi+2

  lda col_copy_poi
  sta erase_row0_col_poi+1
  lda col_copy_poi+1
  sta erase_row0_col_poi+2
  lda col_copy_poi2
  sta erase_row1_col_poi+1
  lda col_copy_poi2+1
  sta erase_row1_col_poi+2
  ldy #0
  lda (char_copy_poi),y
  sta erase_char+1
  lda (col_copy_poi),y
  sta erase_col+1

  ; Decide how many chars we need to write into the screen:
  lda sprtext_plotpos_x+1
  clc
  adc #3
  lsr
  lsr
  sta nof_chars_to_copy_0+1
  sta nof_chars_to_erase+1

  ldx #$ff
  ldy #0
loopit_0:
  txa
  sta (char_copy_poi2),y
  dex
  txa
  sta (char_copy_poi),y
charcols0:
  lda #4
  sta (col_copy_poi),y
  sta (col_copy_poi2),y
  dex
  iny
nof_chars_to_copy_0:
  cpy #24
  bne loopit_0
  rts






erase_text0_chars_from_screen:
nof_chars_to_erase:
  ldx #0
erase_more:
erase_char:
  lda #0
erase_row0_char_poi:
  sta $4800,x
erase_row1_char_poi:
  sta $4800,x
erase_col:
  lda #0
erase_row0_col_poi:
  sta $4800,x
erase_row1_col_poi:
  sta $4800,x
  dex
  bpl erase_more
  rts













; Copy one sprite every frame
;Here we save how many pixels we need to copy from sprites to chars:
sprtochars_width:
  !byte 0


; Not allowed to copy into wrong hi/lo memory if there is a packed file loading going on:
copy_spr0hi_into_chars1hi_0:
  ;lda #6
  ;sta $d020
  ldx #0
  ldy #12*8
  jmp do_another_6_chars_hi
copy_spr0hi_into_chars1hi_1:
  ;lda #5
  ;sta $d020
  ldx #$40
  ldy #0
  jmp do_another_6_chars_hi

  ;x is either 14*3+$00,14*3+$40,14*3+$80 or 14*3+$c0
  ;y is which char to copy into
  ldx #0
  ldy #0
do_another_6_chars_hi:
  lda sprtext_spr0_hi,x
  sta tab0_hi+1
  sta tab1_hi+1
tab0_hi:
  lda left_nybble_table
  sta CHARSET_HI + $f2*8,y
  sta CHARSET_HI + $f2*8+1,y
tab1_hi:
  lda right_nybble_table
  sta CHARSET_HI + $f0*8,y
  sta CHARSET_HI + $f0*8+1,y

  lda sprtext_spr0_hi+1,x
  sta tab2_hi+1
  sta tab3_hi+1
tab2_hi:
  lda left_nybble_table
  sta CHARSET_HI + $ee*8,y
  sta CHARSET_HI + $ee*8+1,y
tab3_hi:
  lda right_nybble_table
  sta CHARSET_HI + $ec*8,y
  sta CHARSET_HI + $ec*8+1,y

  lda sprtext_spr0_hi+2,x
  sta tab4_hi+1
  sta tab5_hi+1
tab4_hi:
  lda left_nybble_table
  sta CHARSET_HI + $ea*8,y
  sta CHARSET_HI + $ea*8+1,y
tab5_hi:
  lda right_nybble_table
  sta CHARSET_HI + $e8*8,y
  sta CHARSET_HI + $e8*8+1,y
  txa
  clc
  adc #6
  tax
  iny
  iny
  tya
  and #$0f
  bne do_another_6_chars_hi
  rts


; Chars for the first 4 sprites are arranged as, but +1 on every value below:
; fd fb f9 f7 f5 f3    f1 ef ed eb e9 e7    e5 e3 e1 df dd db    d9 d7 d5 d3 d1 cf
; fe fc fa f6 f6 f4    f2 f0 ee ec ea e8    e6 e4 e2 e0 de dc    da d8 d6 d4 d2 d0
; distance between chars for spr0 and spr1 = 12*8 = 96 
; Can only handle 2 sprites in each instance of the function below:
copy_spr0_into_chars1_0:
  lda anim_enabled+1
  bpl copy_spr0lo_into_chars1lo_0
  jmp copy_spr0hi_into_chars1hi_0
dont_do_copy1_1:
  rts

copy_spr0_into_chars1_1:
; If there's not enough text in the sprites, then don't copy them into chars. We might need the chars for graphics in the current game
  lda sprtext_plotpos_x+1
  cmp #$18
  bcc dont_do_copy1_1
  lda anim_enabled+1
  bpl copy_spr0lo_into_chars1lo_1
  jmp copy_spr0hi_into_chars1hi_1

; Not allowed to copy into wrong hi/lo memory if there is a packed file loading going on:
copy_spr0lo_into_chars1lo_0:
  ;lda #6
  ;sta $d020
  ldx #0
  ldy #12*8
  jmp do_another_6_chars_lo
copy_spr0lo_into_chars1lo_1:
  ;lda #5
  ;sta $d020
  ldx #$40
  ldy #0
  jmp do_another_6_chars_lo

  ;x is either 14*3+$00,14*3+$40,14*3+$80 or 14*3+$c0
  ;y is which char to copy into
  ldx #0
  ldy #0
do_another_6_chars_lo:
  lda sprtext_spr0_lo,x
  sta tab0+1
  sta tab1+1
tab0:
  lda left_nybble_table
  sta CHARSET_LO + $f2*8,y
  sta CHARSET_LO + $f2*8+1,y
tab1:
  lda right_nybble_table
  sta CHARSET_LO + $f0*8,y
  sta CHARSET_LO + $f0*8+1,y

  lda sprtext_spr0_lo+1,x
  sta tab2+1
  sta tab3+1
tab2:
  lda left_nybble_table
  sta CHARSET_LO + $ee*8,y
  sta CHARSET_LO + $ee*8+1,y
tab3:
  lda right_nybble_table
  sta CHARSET_LO + $ec*8,y
  sta CHARSET_LO + $ec*8+1,y

  lda sprtext_spr0_lo+2,x
  sta tab4+1
  sta tab5+1
tab4:
  lda left_nybble_table
  sta CHARSET_LO + $ea*8,y
  sta CHARSET_LO + $ea*8+1,y
tab5:
  lda right_nybble_table
  sta CHARSET_LO + $e8*8,y
  sta CHARSET_LO + $e8*8+1,y
  txa
  clc
  adc #6
  tax
  iny
  iny
  tya
  and #$0f
  bne do_another_6_chars_lo
dont_do_copy1_2:
dont_do_copy1_3:
  rts

copy_spr0_into_chars1_2:
; If there's not enough text in the sprites, then don't copy them into chars. We might need the chars for graphics in the current game
  lda sprtext_plotpos_x+1
  cmp #$30
  bcc dont_do_copy1_2
  lda anim_enabled+1
  bpl copy_spr0lo_into_chars1lo_2
  jmp copy_spr0hi_into_chars1hi_2

copy_spr0_into_chars1_3:
; If there's not enough text in the sprites, then don't copy them into chars. We might need the chars for graphics in the current game
  lda sprtext_plotpos_x+1
  cmp #$48
  bcc dont_do_copy1_3
  lda anim_enabled+1
  bpl copy_spr0lo_into_chars1lo_3
  jmp copy_spr0hi_into_chars1hi_3

; Not allowed to copy into wrong hi/lo memory if there is a packed file loading going on:
copy_spr0lo_into_chars1lo_2:
  ;lda #6
  ;sta $d020
  ldx #$80
  ldy #12*8
  jmp do_another_6_chars2_lo
copy_spr0lo_into_chars1lo_3:
  ;lda #5
  ;sta $d020
  ldx #$c0
  ldy #0
  jmp do_another_6_chars2_lo

  ;x is either 14*3+$00,14*3+$40,14*3+$80 or 14*3+$c0
  ;y is which char to copy into
  ldx #0
  ldy #0
do_another_6_chars2_lo:
  lda sprtext_spr0_lo,x
  sta tab0_2+1
  sta tab1_2+1
tab0_2:
  lda left_nybble_table
  sta CHARSET_LO - 24*8 + $f2*8,y
  sta CHARSET_LO - 24*8 + $f2*8+1,y
tab1_2:
  lda right_nybble_table
  sta CHARSET_LO - 24*8 + $f0*8,y
  sta CHARSET_LO - 24*8 + $f0*8+1,y

  lda sprtext_spr0_lo+1,x
  sta tab2_2+1
  sta tab3_2+1
tab2_2:
  lda left_nybble_table
  sta CHARSET_LO - 24*8 + $ee*8,y
  sta CHARSET_LO - 24*8 + $ee*8+1,y
tab3_2:
  lda right_nybble_table
  sta CHARSET_LO - 24*8 + $ec*8,y
  sta CHARSET_LO - 24*8 + $ec*8+1,y

  lda sprtext_spr0_lo+2,x
  sta tab4_2+1
  sta tab5_2+1
tab4_2:
  lda left_nybble_table
  sta CHARSET_LO - 24*8 + $ea*8,y
  sta CHARSET_LO - 24*8 + $ea*8+1,y
tab5_2:
  lda right_nybble_table
  sta CHARSET_LO - 24*8 + $e8*8,y
  sta CHARSET_LO - 24*8 + $e8*8+1,y
  txa
  clc
  adc #6
  tax
  iny
  iny
  tya
  and #$0f
  bne do_another_6_chars2_lo
  rts


; Not allowed to copy into wrong hi/lo memory if there is a packed file loading going on:
copy_spr0hi_into_chars1hi_2:
  ;lda #6
  ;sta $d020
  ldx #$80
  ldy #12*8
  jmp do_another_6_chars2_hi
copy_spr0hi_into_chars1hi_3:
  ;lda #5
  ;sta $d020
  ldx #$c0
  ldy #0
  jmp do_another_6_chars2_hi

  ;x is either 14*3+$00,14*3+$40,14*3+$80 or 14*3+$c0
  ;y is which char to copy into
  ldx #0
  ldy #0
do_another_6_chars2_hi:
  lda sprtext_spr0_hi,x
  sta tab0_2_hi+1
  sta tab1_2_hi+1
tab0_2_hi:
  lda left_nybble_table
  sta CHARSET_HI - 24*8 + $f2*8,y
  sta CHARSET_HI - 24*8 + $f2*8+1,y
tab1_2_hi:
  lda right_nybble_table
  sta CHARSET_HI - 24*8 + $f0*8,y
  sta CHARSET_HI - 24*8 + $f0*8+1,y

  lda sprtext_spr0_hi+1,x
  sta tab2_2_hi+1
  sta tab3_2_hi+1
tab2_2_hi:
  lda left_nybble_table
  sta CHARSET_HI - 24*8 + $ee*8,y
  sta CHARSET_HI - 24*8 + $ee*8+1,y
tab3_2_hi:
  lda right_nybble_table
  sta CHARSET_HI - 24*8 + $ec*8,y
  sta CHARSET_HI - 24*8 + $ec*8+1,y

  lda sprtext_spr0_hi+2,x
  sta tab4_2_hi+1
  sta tab5_2_hi+1
tab4_2_hi:
  lda left_nybble_table
  sta CHARSET_HI - 24*8 + $ea*8,y
  sta CHARSET_HI - 24*8 + $ea*8+1,y
tab5_2_hi:
  lda right_nybble_table
  sta CHARSET_HI - 24*8 + $e8*8,y
  sta CHARSET_HI - 24*8 + $e8*8+1,y
  txa
  clc
  adc #6
  tax
  iny
  iny
  tya
  and #$0f
  bne do_another_6_chars2_hi
  rts

;------------------


; Not allowed to copy into wrong hi/lo memory if there is a packed file loading going on:
copy_spr1hi_into_chars1hi_0:
  ;lda #6
  ;sta $d020
  ldx #0
  ldy #12*8
  jmp do_another_6_chars_hi1
copy_spr1hi_into_chars1hi_1:
  ;lda #5
  ;sta $d020
  ldx #$40
  ldy #0
  jmp do_another_6_chars_hi1

  ;x is either 14*3+$00,14*3+$40,14*3+$80 or 14*3+$c0
  ;y is which char to copy into
  ldx #0
  ldy #0
do_another_6_chars_hi1:
  lda sprtext_spr1_hi,x
  sta tab0_1_hi+1
  sta tab1_1_hi+1
tab0_1_hi:
  lda left_nybble_table
  sta CHARSET_HI + $f2*8,y
  sta CHARSET_HI + $f2*8+1,y
tab1_1_hi:
  lda right_nybble_table
  sta CHARSET_HI + $f0*8,y
  sta CHARSET_HI + $f0*8+1,y

  lda sprtext_spr1_hi+1,x
  sta tab2_1_hi+1
  sta tab3_1_hi+1
tab2_1_hi:
  lda left_nybble_table
  sta CHARSET_HI + $ee*8,y
  sta CHARSET_HI + $ee*8+1,y
tab3_1_hi:
  lda right_nybble_table
  sta CHARSET_HI + $ec*8,y
  sta CHARSET_HI + $ec*8+1,y

  lda sprtext_spr1_hi+2,x
  sta tab4_1_hi+1
  sta tab5_1_hi+1
tab4_1_hi:
  lda left_nybble_table
  sta CHARSET_HI + $ea*8,y
  sta CHARSET_HI + $ea*8+1,y
tab5_1_hi:
  lda right_nybble_table
  sta CHARSET_HI + $e8*8,y
  sta CHARSET_HI + $e8*8+1,y
  txa
  clc
  adc #6
  tax
  iny
  iny
  tya
  and #$0f
  bne do_another_6_chars_hi1
  rts


; Chars for the first 4 sprites are arranged as, but +1 on every value below:
; fd fb f9 f7 f5 f3    f1 ef ed eb e9 e7    e5 e3 e1 df dd db    d9 d7 d5 d3 d1 cf
; fe fc fa f6 f6 f4    f2 f0 ee ec ea e8    e6 e4 e2 e0 de dc    da d8 d6 d4 d2 d0
; distance between chars for spr0 and spr1 = 12*8 = 96 
; Can only handle 2 sprites in each instance of the function below:
copy_spr1_into_chars1_0:
  lda anim_enabled+1
  bpl copy_spr1lo_into_chars1lo_0
  jmp copy_spr1hi_into_chars1hi_0
dont_do_copy1_1_1:
  rts

copy_spr1_into_chars1_1:
; If there's not enough text in the sprites, then don't copy them into chars. We might need the chars for graphics in the current game
  lda sprtext_plotpos_x+1
  cmp #$18
  bcc dont_do_copy1_1_1
  lda anim_enabled+1
  bpl copy_spr1lo_into_chars1lo_1
  jmp copy_spr1hi_into_chars1hi_1

; Not allowed to copy into wrong hi/lo memory if there is a packed file loading going on:
copy_spr1lo_into_chars1lo_0:
  ;lda #6
  ;sta $d020
  ldx #0
  ldy #12*8
  jmp do_another_6_chars_lo1
copy_spr1lo_into_chars1lo_1:
  ;lda #5
  ;sta $d020
  ldx #$40
  ldy #0
  jmp do_another_6_chars_lo1

  ;x is either 14*3+$00,14*3+$40,14*3+$80 or 14*3+$c0
  ;y is which char to copy into
  ldx #0
  ldy #0
do_another_6_chars_lo1:
  lda sprtext_spr1_lo,x
  sta tab0_1+1
  sta tab1_1+1
tab0_1:
  lda left_nybble_table
  sta CHARSET_LO + $f2*8,y
  sta CHARSET_LO + $f2*8+1,y
tab1_1:
  lda right_nybble_table
  sta CHARSET_LO + $f0*8,y
  sta CHARSET_LO + $f0*8+1,y

  lda sprtext_spr1_lo+1,x
  sta tab2_1+1
  sta tab3_1+1
tab2_1:
  lda left_nybble_table
  sta CHARSET_LO + $ee*8,y
  sta CHARSET_LO + $ee*8+1,y
tab3_1:
  lda right_nybble_table
  sta CHARSET_LO + $ec*8,y
  sta CHARSET_LO + $ec*8+1,y

  lda sprtext_spr1_lo+2,x
  sta tab4_1+1
  sta tab5_1+1
tab4_1:
  lda left_nybble_table
  sta CHARSET_LO + $ea*8,y
  sta CHARSET_LO + $ea*8+1,y
tab5_1:
  lda right_nybble_table
  sta CHARSET_LO + $e8*8,y
  sta CHARSET_LO + $e8*8+1,y
  txa
  clc
  adc #6
  tax
  iny
  iny
  tya
  and #$0f
  bne do_another_6_chars_lo1
dont_do_copy1_2_1:
dont_do_copy1_3_1:
  rts

copy_spr1_into_chars1_2:
; If there's not enough text in the sprites, then don't copy them into chars. We might need the chars for graphics in the current game
  lda sprtext_plotpos_x+1
  cmp #$30
  bcc dont_do_copy1_2_1
  lda anim_enabled+1
  bpl copy_spr1lo_into_chars1lo_2
  jmp copy_spr1hi_into_chars1hi_2

copy_spr1_into_chars1_3:
; If there's not enough text in the sprites, then don't copy them into chars. We might need the chars for graphics in the current game
  lda sprtext_plotpos_x+1
  cmp #$48
  bcc dont_do_copy1_3_1
  lda anim_enabled+1
  bpl copy_spr1lo_into_chars1lo_3
  jmp copy_spr1hi_into_chars1hi_3

; Not allowed to copy into wrong hi/lo memory if there is a packed file loading going on:
copy_spr1lo_into_chars1lo_2:
  ;lda #6
  ;sta $d020
  ldx #$80
  ldy #12*8
  jmp do_another_6_chars2_lo1
copy_spr1lo_into_chars1lo_3:
  ;lda #5
  ;sta $d020
  ldx #$c0
  ldy #0
  jmp do_another_6_chars2_lo1

  ;x is either 14*3+$00,14*3+$40,14*3+$80 or 14*3+$c0
  ;y is which char to copy into
  ldx #0
  ldy #0
do_another_6_chars2_lo1:
  lda sprtext_spr1_lo,x
  sta tab0_2_1+1
  sta tab1_2_1+1
tab0_2_1:
  lda left_nybble_table
  sta CHARSET_LO - 24*8 + $f2*8,y
  sta CHARSET_LO - 24*8 + $f2*8+1,y
tab1_2_1:
  lda right_nybble_table
  sta CHARSET_LO - 24*8 + $f0*8,y
  sta CHARSET_LO - 24*8 + $f0*8+1,y

  lda sprtext_spr1_lo+1,x
  sta tab2_2_1+1
  sta tab3_2_1+1
tab2_2_1:
  lda left_nybble_table
  sta CHARSET_LO - 24*8 + $ee*8,y
  sta CHARSET_LO - 24*8 + $ee*8+1,y
tab3_2_1:
  lda right_nybble_table
  sta CHARSET_LO - 24*8 + $ec*8,y
  sta CHARSET_LO - 24*8 + $ec*8+1,y

  lda sprtext_spr1_lo+2,x
  sta tab4_2_1+1
  sta tab5_2_1+1
tab4_2_1:
  lda left_nybble_table
  sta CHARSET_LO - 24*8 + $ea*8,y
  sta CHARSET_LO - 24*8 + $ea*8+1,y
tab5_2_1:
  lda right_nybble_table
  sta CHARSET_LO - 24*8 + $e8*8,y
  sta CHARSET_LO - 24*8 + $e8*8+1,y
  txa
  clc
  adc #6
  tax
  iny
  iny
  tya
  and #$0f
  bne do_another_6_chars2_lo1
  rts


; Not allowed to copy into wrong hi/lo memory if there is a packed file loading going on:
copy_spr1hi_into_chars1hi_2:
  ;lda #6
  ;sta $d020
  ldx #$80
  ldy #12*8
  jmp do_another_6_chars2_hi1
copy_spr1hi_into_chars1hi_3:
  ;lda #5
  ;sta $d020
  ldx #$c0
  ldy #0
  jmp do_another_6_chars2_hi1

  ;x is either 14*3+$00,14*3+$40,14*3+$80 or 14*3+$c0
  ;y is which char to copy into
  ldx #0
  ldy #0
do_another_6_chars2_hi1:
  lda sprtext_spr1_hi,x
  sta tab0_2_1_hi+1
  sta tab1_2_1_hi+1
tab0_2_1_hi:
  lda left_nybble_table
  sta CHARSET_HI - 24*8 + $f2*8,y
  sta CHARSET_HI - 24*8 + $f2*8+1,y
tab1_2_1_hi:
  lda right_nybble_table
  sta CHARSET_HI - 24*8 + $f0*8,y
  sta CHARSET_HI - 24*8 + $f0*8+1,y

  lda sprtext_spr1_hi+1,x
  sta tab2_2_1_hi+1
  sta tab3_2_1_hi+1
tab2_2_1_hi:
  lda left_nybble_table
  sta CHARSET_HI - 24*8 + $ee*8,y
  sta CHARSET_HI - 24*8 + $ee*8+1,y
tab3_2_1_hi:
  lda right_nybble_table
  sta CHARSET_HI - 24*8 + $ec*8,y
  sta CHARSET_HI - 24*8 + $ec*8+1,y

  lda sprtext_spr1_hi+2,x
  sta tab4_2_1_hi+1
  sta tab5_2_1_hi+1
tab4_2_1_hi:
  lda left_nybble_table
  sta CHARSET_HI - 24*8 + $ea*8,y
  sta CHARSET_HI - 24*8 + $ea*8+1,y
tab5_2_1_hi:
  lda right_nybble_table
  sta CHARSET_HI - 24*8 + $e8*8,y
  sta CHARSET_HI - 24*8 + $e8*8+1,y
  txa
  clc
  adc #6
  tax
  iny
  iny
  tya
  and #$0f
  bne do_another_6_chars2_hi1
  rts


;--------------------

;This is a dump of ypos_where_it_should_be - ypos_where_it_ends_up_uncompensated   $f000 - $f0c7 when dumping
yposdest_minus_ypos:
;  !byte $d7,$02,$fe,$04,$fb,$07,$ff,$fb,$00,$03,$03,$00,$ff,$01,$fb,$03,$02,$fd,$fc,$01,$05,$fe,$fc,$06,$fd,$00,$02,$fc,$fe,$01,$04,$01,$f9,$00,$01,$04,$01,$00,$fa,$05,$fa,$00,$04,$01,$fc,$01,$ff,$04,$00,$01,$00,$01,$fb,$05,$f9,$02,$01,$fd,$05,$fc,$fe,$00,$01,$02,$ff,$fe,$00,$00,$01,$05,$fd,$03,$fb,$02,$02,$01,$fb,$05,$fa,$00,$02,$03,$fc,$06,$fb,$02,$fe,$02,$fc,$05,$00,$01,$f9,$06,$fc,$02,$fb,$02,$fe,$05,$fc,$04,$fc,$fe,$02,$fe,$03,$01,$fd,$06,$fa,$04,$fd,$ff,$03,$00,$03,$fd,$ff,$05,$fc,$01,$fc,$00,$01,$06,$fe,$ff,$03,$ff,$fd,$fd,$06,$01,$fa,$03,$03,$fb,$01,$03,$fc,$06,$fa,$00,$01,$fe,$02,$03,$01,$fc,$02,$fe,$01,$01,$00,$02,$fe,$fd,$05,$fe,$03,$fc,$05,$fd,$ff,$ff,$04,$fb,$02,$03,$00,$fc,$ff,$05,$fe,$00,$03,$01,$fe,$fd,$02,$fd,$04,$02,$fc,$04,$f9,$02,$ff,$01,$00,$02,$ff,$00,$00,$fe,$06,$fd,$fc,$07,$ff,$ff,$00,$00,$00,$00,$ff,$ff
;  !byte $d7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;  !byte $d7,$05,$fb,$06,$fd,$fd,$02,$00,$ff,$04,$fb,$01,$03,$03,$ff,$fc,$05,$fc,$fe,$ff,$06,$00,$00,$ff,$fb,$00,$01,$00,$05,$8d,$ff,$00,$02,$fc,$00,$01,$ff,$01,$fe,$00,$07,$fb,$04,$00,$fe,$03,$01,$00,$00,$00,$f9,$00,$04,$00,$fc,$04,$fd,$03,$00,$01,$fd,$03,$fe,$fe,$03,$fc,$05,$ff,$fe,$ff,$fd,$02,$fe,$00,$01,$05,$00,$fd,$04,$01,$fb,$34,$03,$01,$01,$fc,$fe,$05,$fd,$fd,$00,$06,$00,$00,$fc,$fd,$00,$00,$01,$03,$01,$fd,$01,$00,$01,$03,$fd,$fe,$02,$05,$f9,$fa,$02,$03,$fd,$05,$fb,$04,$fd,$ff,$03,$00,$03,$fd,$fe,$06,$fe,$ff,$02,$01,$fa,$03,$03,$fb,$01,$03,$fc,$06,$fa,$00,$01,$fe,$06,$fc,$02,$fe,$01,$01,$00,$02,$01,$91,$fb,$06,$fe,$fd,$03,$fc,$04,$fc,$02,$ff,$02,$00,$01,$fe,$02,$02,$fc,$04,$f9,$02,$ff,$01,$04,$fd,$00,$00,$00,$fe,$06,$fd,$fc,$00,$00,$00,$00,$00,$00,$f8,$03,$00,$c0,$ff,$ff,$00,$ff,$ff,$00,$ff,$ff,$00,$00,$00,$00,$00,$00,$00
; !byte $f3,$01,$fb,$06,$fe,$fc,$01,$00,$ff,$04,$fb,$01,$03,$03,$ff,$fc,$05,$fc,$fe,$ff,$06,$00,$00,$ff,$fc,$00,$01,$00,$04,$8c,$ff,$00,$02,$fc,$00,$01,$ff,$01,$fe,$00,$07,$fb,$03,$00,$fe,$03,$00,$01,$ff,$00,$fa,$00,$04,$00,$fd,$04,$fe,$03,$00,$01,$fc,$04,$fe,$fe,$03,$fc,$05,$ff,$fe,$ff,$fd,$02,$fe,$00,$01,$05,$00,$fe,$02,$01,$fb,$34,$03,$01,$01,$fc,$fe,$05,$fd,$fd,$00,$06,$00,$00,$fc,$fd,$00,$00,$01,$03,$01,$03,$fc,$01,$03,$01,$fc,$fe,$04,$fd,$ff,$ff,$04,$00,$fd,$05,$fb,$04,$fd,$ff,$03,$ff,$03,$fd,$fe,$06,$ff,$ff,$02,$01,$fc,$03,$01,$fb,$01,$03,$fc,$06,$fb,$00,$01,$fe,$06,$fc,$02,$ff,$00,$01,$00,$01,$02,$91,$fc,$03,$00,$01,$fe,$01,$01,$fc,$05,$00,$fd,$fe,$03,$fe,$02,$02,$fb,$02,$fd,$01,$00,$01,$fe,$02,$00,$00,$00,$fe,$02,$01,$fc,$07,$63,$f3,$e0,$77,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  !byte $f3,$01,$fb,$06,$fe,$fc,$01,$00,$ff,$04,$fb,$01,$03,$03,$ff,$fc,$05,$fc,$fe,$ff,$06,$00,$00,$ff,$fc,$00,$01,$00,$04,$8c,$ff,$00,$02,$fc,$00,$01,$ff,$01,$fe,$00,$07,$fb,$03,$00,$fe,$03,$00,$01,$ff,$00,$fa,$00,$04,$00,$fd,$04,$fe,$03,$00,$01,$fc,$04,$fe,$fe,$03,$fc,$05,$ff,$fe,$ff,$fd,$02,$fe,$00,$01,$05,$00,$fe,$02,$01,$fb,$34,$03,$01,$01,$fc,$fe,$05,$fd,$fd,$00,$06,$00,$00,$fc,$fd,$00,$00,$01,$03,$01,$03,$fc,$01,$03,$01,$fc,$fe,$04,$fd,$ff,$ff,$04,$00,$fd,$05,$fb,$04,$fd,$ff,$03,$ff,$03,$fd,$fe,$06,$ff,$ff,$02,$01,$fc,$03,$01,$fb,$01,$03,$fc,$06,$fb,$00,$01,$fe,$06,$fc,$02,$ff,$00,$01,$00,$01,$02,$91,$fc,$03,$00,$01,$fe,$01,$01,$fc,$05,$00,$fd,$fe,$03,$fe,$02,$02,$fb,$02,$fd,$01,$00,$01,$fe,$02,$00,$00,$00,$fe,$02,$01,$00,$04,$63,$f3,$e0,$77,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  *= $bc00
sprtext_charset:
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000

  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %00000000
  !byte %10000000
  !byte %00000000

  !byte %10100000
  !byte %10100000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %01010000
  !byte %11111000
  !byte %01010000
  !byte %11111000
  !byte %01010000
  !byte %00000000

  !byte %00100000
  !byte %11111000
  !byte %10100000
  !byte %10100000
  !byte %11111000
  !byte %00101000
  !byte %11111000
  !byte %00100000

  !byte %00000000
  !byte %00000000
  !byte %10100000
  !byte %00100000
  !byte %01000000
  !byte %10000000
  !byte %10100000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %01110000
  !byte %10001000
  !byte %01110000
  !byte %10011000
  !byte %01101000
  !byte %00000000

  !byte %01000000
  !byte %10000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000

  !byte %01000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %01000000
  !byte %00000000

  !byte %10000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %10000000
  !byte %00000000

  !byte %00100000
  !byte %10101000
  !byte %01110000
  !byte %11111100
  !byte %01110000
  !byte %10101000
  !byte %00100000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00100000
  !byte %00100000
  !byte %11111000
  !byte %00100000
  !byte %00100000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %01000000
  !byte %10000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %11100000
  !byte %00000000
  !byte %00000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %10000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00100000
  !byte %00100000
  !byte %01000000
  !byte %10000000
  !byte %10000000
  !byte %00000000


  !byte %11100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %00000000

  !byte %01000000
  !byte %11000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %11100000
  !byte %00000000

  !byte %11100000
  !byte %00100000
  !byte %00100000
  !byte %00100000
  !byte %11100000
  !byte %10000000
  !byte %11100000
  !byte %00000000

  !byte %11100000
  !byte %00100000
  !byte %00100000
  !byte %00100000
  !byte %11100000
  !byte %00100000
  !byte %11100000
  !byte %00000000

  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %00100000
  !byte %00100000
  !byte %00000000

  !byte %11100000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %11100000
  !byte %00100000
  !byte %11100000
  !byte %00000000

  !byte %11100000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %11100000
  !byte %10100000
  !byte %11100000
  !byte %00000000

  !byte %11100000
  !byte %00100000
  !byte %00100000
  !byte %00100000
  !byte %01100000
  !byte %00100000
  !byte %00100000
  !byte %00000000

  !byte %11100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %10100000
  !byte %11100000
  !byte %00000000

  !byte %11100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %00100000
  !byte %11100000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %10000000
  !byte %00000000
  !byte %10000000
  !byte %00000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %01000000
  !byte %00000000
  !byte %01000000
  !byte %01000000
  !byte %10000000

  !byte %00000000
  !byte %00000000
  !byte %00100000
  !byte %01000000
  !byte %10000000
  !byte %01000000
  !byte %00100000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %11100000
  !byte %00000000
  !byte %11100000
  !byte %00000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %10000000
  !byte %01000000
  !byte %00100000
  !byte %01000000
  !byte %10000000
  !byte %00000000

  !byte %01100000
  !byte %10010000
  !byte %00010000
  !byte %00100000
  !byte %01000000
  !byte %00000000
  !byte %01000000
  !byte %00000000

  !byte %00111110
  !byte %01000001
  !byte %10011101
  !byte %10100101
  !byte %10101101
  !byte %10010111
  !byte %01000000
  !byte %00111111

  !byte %01000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %10100000
  !byte %10100000
  !byte %00000000

  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11000000
  !byte %10100000
  !byte %11000000
  !byte %00000000

  !byte %01000000
  !byte %10100000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10100000
  !byte %01000000
  !byte %00000000

  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11000000
  !byte %00000000

  !byte %11100000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %11100000
  !byte %10000000
  !byte %11100000
  !byte %00000000

  !byte %11100000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %11100000
  !byte %10000000
  !byte %10000000
  !byte %00000000

  !byte %01100000
  !byte %10010000
  !byte %10000000
  !byte %10000000
  !byte %10110000
  !byte %10010000
  !byte %01110000
  !byte %00000000

  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %10100000
  !byte %10100000
  !byte %00000000

  !byte %11100000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %11100000
  !byte %00000000

  !byte %11100000
  !byte %00100000
  !byte %00100000
  !byte %00100000
  !byte %00100000
  !byte %00100000
  !byte %10100000
  !byte %01000000

  !byte %10010000
  !byte %10010000
  !byte %10100000
  !byte %10100000
  !byte %11000000
  !byte %10100000
  !byte %10010000
  !byte %00000000

  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %11100000
  !byte %00000000

  !byte %10001000
  !byte %11011000
  !byte %10101000
  !byte %10001000
  !byte %10001000
  !byte %10001000
  !byte %10001000
  !byte %00000000

  !byte %10001000
  !byte %11001000
  !byte %10101000
  !byte %10011000
  !byte %10001000
  !byte %10001000
  !byte %10001000
  !byte %00000000

  !byte %01000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %01000000
  !byte %00000000

  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11000000
  !byte %10000000
  !byte %10000000
  !byte %00000000

  !byte %01000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %01000000
  !byte %00100000

  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %00000000

  !byte %01000000
  !byte %10100000
  !byte %10000000
  !byte %10000000
  !byte %01000000
  !byte %00100000
  !byte %11000000
  !byte %00000000

  !byte %11100000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %00000000

  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %01000000
  !byte %00000000

  !byte %10001000
  !byte %10001000
  !byte %10001000
  !byte %10001000
  !byte %01010000
  !byte %01110000
  !byte %00100000
  !byte %00000000

  !byte %10001000
  !byte %10001000
  !byte %10001000
  !byte %10001000
  !byte %10101000
  !byte %11011000
  !byte %10001000
  !byte %00000000

  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %01000000
  !byte %10100000
  !byte %10100000
  !byte %00000000

  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %01100000
  !byte %00100000
  !byte %00100000
  !byte %11000000

  !byte %11100000
  !byte %10100000
  !byte %00100000
  !byte %00100000
  !byte %01000000
  !byte %10000000
  !byte %11100000
  !byte %00000000

  !byte %11000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %11000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %10000000
  !byte %01000000
  !byte %00100000
  !byte %00010000
  !byte %00001000
  !byte %00000000

  !byte %11000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %11000000
  !byte %00000000

  !byte %01000000
  !byte %11100000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %11100000

  !byte %10000000
  !byte %01000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %11000000
  !byte %00100000
  !byte %01100000
  !byte %10100000
  !byte %01100000
  !byte %00000000

  !byte %10000000
  !byte %10000000
  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %01000000
  !byte %10100000
  !byte %10000000
  !byte %10100000
  !byte %01000000
  !byte %00000000

  !byte %00100000
  !byte %00100000
  !byte %01100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %11100000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %01000000
  !byte %10100000
  !byte %11100000
  !byte %10000000
  !byte %01100000
  !byte %00000000

  !byte %01100000
  !byte %10000000
  !byte %11000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %01100000
  !byte %10100000
  !byte %10100000
  !byte %01100000
  !byte %00100000
  !byte %11000000

  !byte %10000000
  !byte %10000000
  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %00000000

  !byte %10000000
  !byte %00000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %00000000


  !byte %01000000
  !byte %00000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %01000000
  !byte %10000000

  !byte %10000000
  !byte %10000000
  !byte %10100000
  !byte %10100000
  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %00000000

  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %11110000
  !byte %10101000
  !byte %10101000
  !byte %10101000
  !byte %10101000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %01000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %01000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %11000000
  !byte %10100000
  !byte %10100000
  !byte %11000000
  !byte %10000000
  !byte %10000000

  !byte %00000000
  !byte %00000000
  !byte %01100000
  !byte %10100000
  !byte %10100000
  !byte %01100000
  !byte %00100000
  !byte %00100000

  !byte %00000000
  !byte %00000000
  !byte %11000000
  !byte %10100000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %01100000
  !byte %10000000
  !byte %01000000
  !byte %00100000
  !byte %11000000
  !byte %00000000

  !byte %10000000
  !byte %11000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %01000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %01100000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %01000000
  !byte %01000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %10001000
  !byte %10101000
  !byte %10101000
  !byte %10101000
  !byte %01111000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %10100000
  !byte %10100000
  !byte %01000000
  !byte %10100000
  !byte %10100000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %10100000
  !byte %10100000
  !byte %10100000
  !byte %01100000
  !byte %00100000
  !byte %11000000

  !byte %00000000
  !byte %00000000
  !byte %11100000
  !byte %00100000
  !byte %01000000
  !byte %10000000
  !byte %11100000
  !byte %00000000


  !byte %00100000
  !byte %01000000
  !byte %01000000
  !byte %10000000
  !byte %01000000
  !byte %01000000
  !byte %00100000
  !byte %00000000

  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %10000000
  !byte %00000000

  !byte %10000000
  !byte %01000000
  !byte %01000000
  !byte %00100000
  !byte %01000000
  !byte %01000000
  !byte %10000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %01010000
  !byte %10100000
  !byte %00000000
  !byte %00000000
  !byte %00000000

  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
  !byte %00000000
;-$bf00

;This is a dump of xpos_where_it_should_be - xpos_where_it_ends_up_uncompensated   $f100 - $f1c7 when dumping
xposdest_minus_xpos:
; !byte $ef,$01,$f8,$fe,$f7,$ff,$00,$03,$f6,$fb,$fd,$06,$fd,$fd,$f9,$fa,$ff,$fe,$fc,$fb,$f9,$02,$fd,$fd,$f8,$01,$fa,$fd,$f7,$04,$f9,$fe,$ff,$fa,$fb,$00,$f8,$04,$fd,$00,$f6,$03,$f8,$00,$fa,$fe,$fb,$f9,$fa,$00,$fe,$fc,$fb,$f8,$fd,$ff,$00,$fd,$00,$00,$fc,$f9,$01,$ff,$f8,$01,$fc,$fd,$fc,$ff,$f7,$00,$fb,$00,$fc,$ff,$f7,$00,$01,$02,$fc,$fb,$fd,$fc,$fb,$ff,$f9,$03,$fd,$ff,$00,$00,$fd,$ff,$fa,$ff,$06,$00,$f9,$fb,$f8,$fd,$fc,$fa,$f7,$fc,$fe,$fb,$fb,$fd,$f9,$fb,$00,$fb,$01,$04,$f8,$fa,$ff,$f5,$fe,$fb,$f7,$07,$fb,$fa,$fc,$fb,$f8,$fe,$f7,$00,$f9,$fb,$03,$fb,$fa,$fa,$00,$fb,$ff,$fb,$f9,$fe,$f9,$fb,$fb,$fb,$fb,$fb,$f9,$fd,$fc,$ff,$fd,$fe,$ff,$fd,$fc,$fb,$ff,$fb,$fb,$fb,$f7,$02,$f8,$fb,$fd,$f9,$fa,$00,$f5,$fe,$fa,$02,$f8,$fb,$01,$fc,$f8,$00,$fa,$fb,$fe,$00,$f8,$03,$f7,$fb,$fb,$01,$fb,$01,$f2,$06,$f4,$fe,$fb,$ff,$ff,$ff,$00,$00,$00,$00,$ff,$ff
; !byte $ef,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
; !byte $ee,$fc,$00,$fe,$fa,$02,$f4,$fe,$f7,$fa,$fc,$02,$f9,$fe,$f9,$fd,$fc,$00,$f7,$01,$fc,$04,$f7,$00,$ff,$00,$f8,$03,$fe,$fa,$fd,$f7,$ff,$fd,$02,$f7,$fb,$f9,$01,$f4,$00,$f4,$00,$fe,$fd,$fb,$fe,$f6,$ff,$f8,$01,$fc,$fc,$00,$f9,$fd,$fe,$fc,$fa,$fe,$f9,$ff,$04,$f8,$fe,$f4,$01,$f8,$ff,$fb,$f9,$fd,$02,$f6,$fd,$fe,$f9,$03,$fc,$f9,$fa,$fe,$fa,$fd,$fb,$01,$00,$01,$f9,$fd,$00,$fe,$f4,$07,$fa,$fc,$f6,$01,$ff,$fc,$fb,$fa,$fd,$fb,$fa,$fe,$fc,$fe,$f8,$0a,$fa,$fc,$fc,$fc,$fc,$01,$fc,$02,$05,$f9,$fb,$01,$6a,$aa,$55,$5a,$ff,$00,$ff,$00,$00,$ff,$00,$00,$ff,$00,$00,$ff,$00,$00,$ff,$00,$00,$ff,$00,$00,$ff,$00,$00,$bf,$00,$00,$3f,$00,$00,$3c,$00,$00,$0c,$00,$00,$50,$00,$00,$6a,$00,$00,$6a,$80,$00,$aa,$80,$00,$aa,$a0,$00,$9a,$a8,$00,$9a,$6a,$00,$aa,$59,$80,$9a,$59,$a0,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; !byte $ee,$fa,$fb,$fe,$00,$fe,$fa,$02,$f4,$fe,$f7,$fa,$fb,$fe,$f9,$fd,$fc,$00,$fd,$01,$fa,$00,$f7,$00,$ff,$01,$f8,$03,$f9,$fa,$00,$f6,$02,$fc,$fb,$fc,$f7,$fd,$fb,$04,$fb,$ff,$f6,$04,$f8,$fa,$f7,$01,$f8,$06,$f6,$03,$f4,$fe,$f8,$ff,$fb,$02,$fd,$fd,$f8,$fc,$00,$04,$ff,$fc,$f6,$fc,$fd,$fb,$fa,$fa,$f9,$03,$fd,$ff,$fc,$f7,$02,$fb,$fb,$fa,$fb,$fa,$fe,$00,$fa,$fb,$fc,$05,$fd,$fa,$f6,$ff,$fc,$ff,$f2,$03,$fa,$fd,$f7,$fe,$03,$00,$fe,$fa,$fe,$fe,$fb,$00,$f8,$40,$fd,$f9,$fc,$fe,$00,$ff,$00,$f8,$fb,$00,$fa,$f8,$fc,$fa,$fe,$fe,$fc,$fa,$fe,$00,$f5,$f8,$fe,$fc,$ff,$fc,$fa,$00,$f7,$fb,$00,$fa,$f9,$fb,$fb,$fd,$01,$03,$f8,$f9,$fa,$fb,$f8,$f9,$fb,$ff,$fe,$fe,$f0,$05,$f3,$01,$fd,$fa,$01,$fc,$fb,$02,$fd,$ff,$f5,$ff,$fd,$fa,$fb,$00,$f3,$04,$f2,$fc,$f9,$59,$80,$9a,$59,$a0,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; !byte $ee,$fa,$fc,$fe,$00,$fe,$fa,$02,$f4,$fe,$f7,$fa,$fc,$fe,$fa,$fd,$fc,$00,$fd,$01,$fa,$00,$f7,$00,$ff,$01,$f8,$03,$f9,$fa,$00,$f6,$00,$fc,$fb,$fc,$f7,$fd,$f8,$04,$f6,$03,$f7,$04,$f8,$fa,$fe,$fc,$fc,$04,$f7,$03,$f9,$fe,$f8,$ff,$fc,$02,$fd,$fd,$fa,$00,$fc,$04,$ff,$fc,$f7,$fc,$fd,$fb,$fb,$fa,$f9,$01,$fe,$ff,$fb,$f7,$02,$fb,$fb,$fa,$fb,$fa,$fe,$00,$fa,$fb,$00,$05,$fd,$fa,$f7,$fe,$fd,$fe,$f3,$04,$fa,$fd,$f7,$fc,$07,$00,$f7,$fb,$fc,$fe,$f9,$fe,$f9,$2b,$f7,$00,$f9,$fe,$00,$ff,$fb,$f8,$fc,$00,$fb,$f9,$fe,$fc,$fe,$f9,$fa,$fa,$fe,$00,$f9,$f9,$fe,$fc,$ff,$fc,$fa,$fc,$f8,$fb,$fe,$fa,$f9,$fb,$fb,$fd,$01,$03,$f9,$f9,$fa,$fc,$f7,$fa,$fa,$ff,$fe,$f8,$f9,$02,$f5,$00,$fc,$fb,$01,$fc,$fa,$fb,$00,$fe,$f8,$ff,$fd,$fa,$fb,$ff,$f5,$05,$f9,$ff,$f9,$01,$3c,$7c,$fc,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  !byte $ee,$fa,$fc,$fe,$00,$fe,$fa,$02,$f4,$fe,$f7,$fa,$fc,$fe,$fa,$fd,$fc,$00,$fd,$01,$fa,$00,$f7,$00,$ff,$01,$f8,$03,$f9,$fa,$00,$f6,$00,$fc,$fb,$fc,$f7,$fd,$f8,$04,$f6,$03,$f7,$04,$f8,$fa,$fe,$fc,$fc,$04,$f7,$03,$f9,$fe,$f8,$ff,$fc,$02,$fd,$fd,$fa,$00,$fc,$04,$ff,$fc,$f7,$fc,$fd,$fb,$fb,$fa,$f9,$01,$fe,$ff,$fb,$f7,$02,$fb,$fb,$fa,$fb,$fa,$fe,$00,$fa,$fb,$00,$05,$fd,$fa,$f7,$fe,$fd,$fe,$f3,$04,$fa,$fd,$f7,$fc,$07,$00,$f7,$fb,$fc,$fe,$f9,$fe,$f9,$2b,$f7,$00,$f9,$fe,$00,$ff,$fb,$f8,$fc,$00,$fb,$f9,$fe,$fc,$fe,$f9,$fa,$fa,$fe,$00,$f9,$f9,$fe,$fc,$ff,$fc,$fa,$fc,$f8,$fb,$fe,$fa,$f9,$fb,$fb,$fd,$01,$03,$f9,$f9,$fa,$fc,$f7,$fa,$fa,$ff,$fe,$f8,$f9,$02,$f5,$00,$fc,$fb,$01,$fc,$fa,$fb,$00,$fe,$f8,$ff,$fd,$fa,$fb,$ff,$f5,$05,$f9,$ff,$f9,$01,$3c,$7c,$fc,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  *= $c000
spritemat1:
  !bin "spritemat/sprite_image_1.spr"
spritemat1_end:
;-$ce00

  *= $ce00
; This is how a sprite data is transformed into double x-width and put into chars:
; $00 -> $00
; $10 -> $03
; $20 -> $0c
left_nybble_table:
  !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  !byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
  !byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
  !byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
  !byte $30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30,$30
  !byte $33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33
  !byte $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c
  !byte $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f
  !byte $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
  !byte $c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3
  !byte $cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc
  !byte $cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf
  !byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3
  !byte $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

  *= $cf00
; This is how a sprite data is transformed into double x-width and put into chars:
; $00 -> $00
; $10 -> $03
; $20 -> $0c
right_nybble_table:
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff
  !byte $00,$03,$0c,$0f,$30,$33,$3c,$3f,$c0,$c3,$cc,$cf,$f0,$f3,$fc,$ff

  *= $e000
spritemat2:
  !bin "spritemat/sprite_image_2.spr"
spritemat3:
  !bin "spritemat/sprite_image_3.spr"
spritemat3_end:
;-$fc00

the_music = $fc00
  *= $fc00
  !bin "../../music/JammicroV1_AnythingGEOSPRG_fc00_v2.prg",,2
