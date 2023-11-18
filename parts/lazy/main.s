      !cpu 6510
      !initmem $00

;### Endpart of the diskside #1 of Next Level

!ifndef release {
} else {
      !src "../../bitfire/loader/loader_acme.inc"
      !src "../../bitfire/macros/link_macros_acme.inc"
}

;May be max 5120 bytes packed. Is right now 3084 bytes long.

; Start address = $0c00
; Main

;$4900-$6c00 torus animation sprites. 4 frames * 7 columns * 5 rows * 64 bytes  = 8960 bytes = 35*256 = $2300 bytes
;$8000-$c000 animated rotated chars = 16384 bytes

;Put a new spritemat irq in here, but try to reuse the textrotation code from textrotator as is.
;Code for fine_tune is ~$c800-$ca00
;We need to be able to find blit_dst_A - to set the destination of when plotting chars
;We need to be able to find blit_dst - to set the destination of when plotting chars
; Default is to write into $4080-$40ff or $4880-$48f0

!ifdef release {
  fine_tune = $c103
}


;#§# ToDo:
;* First screen text
; <E>Welcome to the world of
;   <1>Lazy Jones
; <7>By David Whittaker
; <E>C <A>TERMINAL SOFTWAE INTL. LTD <E>MCMLXXXIV
;* Main Game now occupies $0000-$3cxx
;Try to fit the loader into below $4000 at least.
;* Make a fixed position for the part music.
;Always put this at for instance $3f00-
;...then it will be loaded at the start of loading. But cannot be overwritten
;before music pattern has changed when walking out of the room.
;So, could make a temp copy of the music to $3e00-$3eff before walking out,
;and start loading to $3f00- directly.
;* Bug: Music is turned off when entering room. Some glitch there.
;* Try to make the loader occupy:
;  $0000-$0400 (for Basic and Kernel operations)
;  $0400-$0800 (for screen)
;  $0800-$0fff (charset and sprites for lounge)
;  $1000-$1fff (useless for graphics, so here's game logic originally $0800-$1780)
;  $2000-$227f (more "lounge" sprites, those who didn't fit $0800-$0fff)
;  ...when Lazy walks into a room, "decrunch" over graphics $2000-
;  ...and when Lazy walk out of a room, "re-read" the lounge graphics $2000-$2280 from disk...!
;  Free memory for parts will be something like $2000-$fff8
;  ...but, if it want to use zero page, then it needs to swap zero page during the part.
;       $9000-$9fff is useless for graphics.
;  Current memmap:
;  $0000-$07ff Basic+screen
;  $0800-$1780 Game logic
;  $1780-$217f music data. Can be removed.
;  $2180-$2fff various subgame charsets. Can be removed.
;  $3000-$3a7f needed charsets and sprites for Lounge.
;  $3a80-$9d7f various sprites and subgame data. Can be removed.
;  $9d80-$9fff needed hiscore and menu texts.
;* "Fix" the screen scrolling issues, so scrolling gets smooth.
;* Separate the "Loader" from the subgames.
;* Make a disk-version of LazyJones.




;### Done:
;### 110925
;* Wrong speed: number of lives.
;Wait 3 vblanks, it's ok.
;* Wrong speed: Lazy entering room.
;Same as main game.
;* Wrong speed: Lazy walking out of room.
;Same as main game.
;* Wrong speed: main game.
;;Now, we need to waitALittleMore, depending on the currentGameSpeed...
;  LDA mainGameSpeed_3B7   ;#$c to start with, and then counting downwards.
;  asl
;  asl
;  asl
;  clc
;currSpeedLSB:
;  adc #0
;  sta currSpeedLSB+1
;  bcc noExtraWait
;  JSR waitAWhile
;noExtraWait:
;* Optimized the music play routine, and remove the pattern-length bug.
;* Wrong speed: Music. CIA-irq used wait = $0c.   Raster-irq set to $0a. Correct?
;   CIA=60Hz. Raster = 50Hz.    12 / 60 * 50 = 10. Correct!
;* Make main game IRQ-based instead of busy-wait-looping.
;   at least for the "walk in/out of subgameroom" and "walk in the hall" parts.
;   emulate the game speedup.
;   Music runs at normal IRQ speed, which is not frame based.
;    LDA #$C
;    STA musicSpeedCou_3E3
;    Should be able to change the music speed to be approximately right, eventhough we change the sync.
; Use pexFrameCou in the busywait-loop
; pexFrameCou:
;   .byt 0
; Use waitAWhile inside subgame as well.


; Nu tittar de flesta intressanta delar "inom" waitAWhile.
; När vi gör rts fortsätter programmet.

;lazyState:
; $00 = Power-on reset
; $01 = "Welcome to the world of Lazy Jones"
; $02 = "Controls are"
; $03 = "Select number of lives"
; $04 = "Main game demo"
; $05 = "Main hall center"
; $06 = "Main hall left"
; $07 = "Main hall right"
; $08 = "Door animation"
; $09 = "Lazy walking into room"
; $0a = "Get ready"
; $0b = "Game over"
; $0c = "Lazy walking out of room"
; $0d =
; $0e =
; $0f =
;lazyNextState: - what state we shall goto next when the current state is done.
;Not fun, takes a lot of time to implement.
;Better to have two stacks. One stack for the "game" thinking it is running in a main loop.
;...and one stack for the real world.
;
;When an irq occurs... check if we interrupt the "more than one frame" main game thread.
;...or if we interrupted the loader code.

;Start: set stack to #$ff
;Setup IRQ. Set "done" flag to 0.
;First IRQ: jump into main game code.
;  ...when getting to the busy wait loop, set "done flag" and do rti.
;At irq: check "done flag" - if not done, just play music and go back to the code we interrupted.
;  Else, do CLI (so we might interrupt ourselves).
;  If done, jump into "let's continue after the busy loop".
;At irq: increase "irq level".
;  If IRQ_level = 1, play music, CLI, "Setup fake stack" jump into main game code. at waitawhile "preserve fake stack". Get back to the real one. RTI.
;  If IRQ_level > 1. play music, decrease IRQ_level, rti

;### 110923
;Turned busy-wait into irq-synced wait.
;Removed music on/off keys, and pause keys.
;### 110916
;* Sprites occupy 2280-2fc0
;This is $0d40 with sprites. Not all will fit inside $0c00-$0fff
;Put sprites at $2000 for now.
;* Remap sprite pointers.
;   make sprite pointer writes relocateable.
;   make a table of current "spritepointer -> label"
;   Done:sprite0poi_7F8 = screenMem+$03F8
;   Done:sprite1poi_7F9 = screenMem+$03F9
;   Done:sprite2poi_7FA = screenMem+$03FA
;   sprite3poi_7FB = screenMem+$03FB
;   sprite4poi_7FC = screenMem+$03FC
;   sprite5poi_7FD = screenMem+$03FD
;   sprite6poi_7FE = screenMem+$03FE
;   sprite7poi_7FF = screenMem+$03FF
;* Remove subgames
;Only keep LazyNightmare or Toilet.
;Kept StarDust.
;Compressed binary down to 6607 bytes.
;* Rename sprites _3400, _3440, _3480 and _34c0 accordingly.

;### 110909
;* Try to relocate $2180-$3000
;  there are sprites in there, somewhere.
;* Check if the game is relocateable
;  remove internal "free memory" between subgames. Usually filled with 00 00 FF FF 00 00 FF FF
;  Sprites "invisible man" hamnar på fel ställe.
;  Behöver göra res på dessa. Men var är de?
;  $0800-$217f är relokerbart.
;  Städa denna minnesarea. Gjort. Inte mycket bytes ledigt där, inte...
;  Städa $4000-, verkar vara relokerbart också.
;* Fix this: "PexToDo: need to separate the text pointer stuff from D015 writing..."

;### 110908
;Removed absolute LDA's and STA's
;Charset $3000
;   LDA $3298,X
;   STA $3298,X
;Cocktail charset position $2180.
;* 16-bit pointers are not correct.
;Fixed all of them, I think.
;* 16-bit pointers are not correct.
; Remap "prints". $4000 at start of games.
;  check all jsr printTextAtFA
;  Need to add the labels for all "new" texts...
;* 16-bit pointers are not correct.
; Remap music pointers in Game00_xxx:
; ...everything writing to nextMusicPoiLSB_3E4
;* Let this be a skeleton, and let the lazy-asm be as "unmodified" as possible.


;These memory locations are kind of difficult to move:
Charset = $0800


byte_8D = $8D  ;Previous result of RND()
byte_8E = $8E  ;Previous result of RND()
byte_8F = $8F  ;Previous result of RND()

;currentMusicPoiLSB_B4 = $B4  ;Bit counter and stop bit switch during RS232 output. Bits:
;               ;* Bits #0-#6: Bit count.
;               ;* Bit #7: 0 = Data bit; 1 = Stop bit.
;               ;Bit counter during datasette input/output.
;currentMusicPoiMSB_B5 = $B5  ;Bit buffer (in bit #2) during RS232 output.
byte_C5 = $C5  ;Matrix code of key previously pressed. Values:
         ;* $00-$3F: Keyboard matrix code.
         ;* $40: No key was pressed at the time of previous check.
byte_F8 = $E8  ;Pointer to RS232 input buffer. Values:
         ;* $0000-$00FF: No buffer defined, a new buffer must be allocated upon RS232 input.
         ;* $0100-$FFFF: Buffer pointer.
byte_F9 = $E9  ;Pointer to RS232 output buffer. Values:
         ;* $0000-$00FF: No buffer defined, a new buffer must be allocated upon RS232 output.
         ;* $0100-$FFFF: Buffer pointer.
byte_FA = $EA  ;-"-
byte_FB = $EB
byte_FC = $EC
byte_FD = $ED
byte_FE = $EE
byte_FF = $EF  ;Buffer for conversion from floating point to string (12 bytes.)

currentPrintCharColour_286 = $00F0  ;Current color, cursor color. Values: $00-$0F, 0-15.
byte_28D = $003f  ;Shift key indicator. Bits:
          ;Bit #0: 1 = One or more of left Shift, right Shift or Shift Lock is currently being pressed or locked.
          ;Bit #1: 1 = Commodore is currently being pressed.
          ;Bit #2: 1 = Control is currently being pressed.

byte_2B0 = $0040  ;Temp storage, some 32 bytes or something...

IrqPoiLSB_314 = $0314
IrqPoiMSB_315 = $0315



screenMem = $0400
byte_4DA = screenMem+$00DA
byte_556 = screenMem+$0156
numberOfStartingLivesOnScreen_5A9 = screenMem+$01A9
byte_5C7 = screenMem+$01C7
byte_5F2 = screenMem+$01F2
byte_65A = screenMem+$025A
byte_66F = screenMem+$026F
subgameScore0onScreen_689 = screenMem+$0289
subgameScore1onScreen_68A = screenMem+$028A
subgameScore2onScreen_68B = screenMem+$028B
subgameTime3onScreen_693 = screenMem+$0293
subgameTime2onScreen_694 = screenMem+$0294
subgameTime1onScreen_695 = screenMem+$0295
subgameTime0onScreen_696 = screenMem+$0296
playerScore0onScreen_7C8 = screenMem+$03C8
playerScore1onScreen_7C9 = screenMem+$03C9
playerScore2onScreen_7CA = screenMem+$03CA
playerScore3onScreen_7CB = screenMem+$03CB
playerScore4onScreen_7CC = screenMem+$03CC
playerScore5onScreen_7CD = screenMem+$03CD
cocktailScore0onScreen_7CF = screenMem+$03CF
cocktailScore1onScreen_7D0 = screenMem+$03D0
cocktailScore2onScreen_7D1 = screenMem+$03D1
playerNumberOfLivesOnScreen_7D8 = screenMem+$03D8
cocktailTime0onScreen_7DC = screenMem+$03DC
cocktailTime1onScreen_7DD = screenMem+$03DD
cocktailTime2onScreen_7DE = screenMem+$03DE
hiScore0onScreen_7E0 = screenMem+$03E0
hiScore1onScreen_7E1 = screenMem+$03E1
hiScore2onScreen_7E2 = screenMem+$03E2
hiScore3onScreen_7E3 = screenMem+$03E3
hiScore4onScreen_7E4 = screenMem+$03E4
hiScore5onScreen_7E5 = screenMem+$03E5
sprite0poi_7F8 = screenMem+$03F8
sprite1poi_7F9 = screenMem+$03F9
sprite2poi_7FA = screenMem+$03FA
sprite3poi_7FB = screenMem+$03FB
sprite4poi_7FC = screenMem+$03FC
sprite5poi_7FD = screenMem+$03FD
sprite6poi_7FE = screenMem+$03FE
sprite7poi_7FF = screenMem+$03FF


;Main = $080D
;clearAudioLoop = $0819
;joystickMovementInMenus_846 = $0846
;notGameOver_859 = $0859
;moreAudioFxLoop_85E = $085E
;mainGameLoop_869 = $0869
;thisIsNotJustDemo_87E = $087E
;notDoingElevator_886 = $0886
;noCollision_891 = $0891
;noJumpingRightNow_8A1 = $08A1
;noNewJump_8AD = $08AD
;loc_8C1 = $08C1
;loc_8D0 = $08D0
;loc_8E3 = $08E3
;loc_903 = $0903
;loc_919 = $0919
;loc_922 = $0922
;noButtonPressed_92B = $092B
;loc_933 = $0933
;loc_949 = $0949
;loc_95F = $095F
;lifeLost = $0967
;gameOver = $0972
;noCollision_978 = $0978
;doRightScreen = $0986
;doLeftScreen_997 = $0997
;doElevatorScreen_9A8 = $09A8
;loc_9B0 = $09B0
;loc_9BA = $09BA
;loc_9C2 = $09C2
;loc_9D1 = $09D1
;loc_9DD = $09DD
;loc_9E9 = $09E9
;goingUp_A03 = $0A03
;goingDown_A13 = $0A13
;loc_A23 = $0A23
;loc_A34 = $0A34
;loc_A42 = $0A42
;doneWithTheElevator_A50 = $0A50
;initMainGame = $0A53
;selectNumberOfLives_B53 = $0B53
;loc_B6C = $0B6C
;loc_B8B = $0B8B
;decrementNumberOfStartingLives = $0B94
;incrementNumberOfStartingLives = $0BA5
;loc_BB6 = $0BB6
;titleMusicInit = $0BC0
;initRandomGameList = $0BEB
;loc_BED = $0BED
;loc_BF6 = $0BF6
;sub_C1A = $0C1A
;loc_C3C = $0C3C
;loc_C55 = $0C55
;loc_C6D = $0C6D
;loc_C7D = $0C7D
;loc_C92 = $0C92
;loc_CA7 = $0CA7
;animateLazyJones_CB4 = $0CB4
;loc_CC2 = $0CC2
;loc_CCB = $0CCB
;lazyJonesD010Toggle_CD3 = $0CD3
;moveMan_CDC = $0CDC
;loc_CF6 = $0CF6
;loc_D05 = $0D05
;loc_D20 = $0D20
;loc_D3B = $0D3B
;loc_D43 = $0D43
;loc_D4E = $0D4E
;loc_D54 = $0D54
;sub_D5C = $0D5C
;sub_D65 = $0D65
;sub_D70 = $0D70
;moveDustvan_D7B = $0D7B
;loc_D95 = $0D95
;loc_DA4 = $0DA4
;loc_DBF = $0DBF
;loc_DDA = $0DDA
;loc_DE2 = $0DE2
;loc_DEC = $0DEC
;loc_DF2 = $0DF2
;sub_DF6 = $0DF6
;sub_DFF = $0DFF
;sub_E0A = $0E0A
;moveInvisibleMan_E15 = $0E15
;loc_E2C = $0E2C
;loc_E3B = $0E3B
;loc_E56 = $0E56
;loc_E71 = $0E71
;loc_E79 = $0E79
;loc_E83 = $0E83
;loc_E89 = $0E89
;sub_E8D = $0E8D
;sub_E96 = $0E96
;sub_E9C = $0E9C
;doJumping_EA2 = $0EA2
;loc_EBB = $0EBB
;loc_EC4 = $0EC4
;locret_ECD = $0ECD
;loc_ECE = $0ECE
;loc_EE0 = $0EE0
;loc_EE9 = $0EE9
;locret_EF2 = $0EF2
;scrollScreenToTheLeft = $0EF3
;loc_EF8 = $0EF8
;loc_F11 = $0F11
;loc_F27 = $0F27
;loc_F3D = $0F3D
;loc_F50 = $0F50
;loc_F63 = $0F63
;scrollScreenToTheRight = $0F69
;loc_F6E = $0F6E
;loc_F87 = $0F87
;loc_F9D = $0F9D
;loc_FB3 = $0FB3
;loc_FC6 = $0FC6
;loc_FD9 = $0FD9
;lifeLostSequence = $0FDF
;audioEffectLoop = $0FF4
;waitLoop5 = $0FFF
;waitLoop3 = $100A
;waitLoop4 = $100F
;gameOverCleanup_101A = $101A
;makeGameSpeedFaster_102B = $102B
;locret_1036 = $1036
;menuStart = $1037
;loc_1047 = $1047
;loc_1050 = $1050
;loc_1066 = $1066
;loc_1075 = $1075
;showMenuWelcomeToTheWorldOfLazy = $107C
;loc_1091 = $1091
;loc_10A5 = $10A5
;loc_10C1 = $10C1
;loc_10D5 = $10D5
;waitAWhile_10E2 = $10E2
;waitLoop2_10E7 = $10E7
;waitLoop1_10E9 = $10E9
;animateDoorsMaybe_10F2 = $10F2
;loc_1119 = $1119
;loc_113D = $113D
;loc_1161 = $1161
;loc_1172 = $1172
;loc_117C = $117C
;loc_1186 = $1186
;loc_1190 = $1190
;loc_119A = $119A
;loc_11A4 = $11A4
;loc_11AE = $11AE
;loc_11B8 = $11B8
;loc_11C2 = $11C2
;loc_11D9 = $11D9
;loc_11EC = $11EC
;playAudioFx_Noise7 = $11F9
;calcWhichRoom9to11_120E = $120E
;loc_1226 = $1226
;loc_122F = $122F
;loc_1238 = $1238
;loc_1245 = $1245
;loc_124E = $124E
;loc_1257 = $1257
;loc_1264 = $1264
;loc_126D = $126D
;loc_1276 = $1276
;loc_127E = $127E
;loc_1286 = $1286
;loc_12A2 = $12A2
;calcWhichRoom0to8_12A5 = $12A5
;loc_12BD = $12BD
;loc_12C6 = $12C6
;loc_12CF = $12CF
;loc_12DC = $12DC
;loc_12E5 = $12E5
;loc_12EE = $12EE
;loc_12FB = $12FB
;loc_1304 = $1304
;loc_130D = $130D
;loc_1315 = $1315
;loc_131D = $131D
;loc_1339 = $1339
;loc_1357 = $1357
;loc_13A0 = $13A0
;loc_13BA = $13BA
;loc_13C2 = $13C2
;loc_13CA = $13CA
;loc_13D2 = $13D2
;loc_13DA = $13DA
;loc_13E2 = $13E2
;loc_13EA = $13EA
;loc_13F2 = $13F2
;loc_13FA = $13FA
;loc_1402 = $1402
;loc_140A = $140A
;loc_1412 = $1412
;loc_141A = $141A
;loc_1422 = $1422
;loc_142A = $142A
;loc_1432 = $1432
;loc_143A = $143A
;loc_1442 = $1442
;loc_1450 = $1450
;notGame00 = $1489
;notGame01 = $1493
;notGame02 = $149D
;notGame03 = $14A7
;notGame04 = $14B1
;notGame05 = $14BB
;notGame06 = $14C5
;notGame07 = $14CF
;notGame08 = $14D9
;notGame09 = $14E3
;notGame0a = $14ED
;notGame0b = $1501
;notGame0c = $150B
;notGame0d = $1515
;notGame0e = $151F
;notGame0f = $1529
;notGame10 = $1533
;SubGameFinished = $153A
;loc_1565 = $1565
;loc_156D = $156D
;loc_1579 = $1579
;loc_1581 = $1581
;setupSprColsLoop = $15EE
;loc_1617 = $1617
;waitAWhile = $163C
;busyLoop0 = $1641
;BusyLoop1 = $1645
;waitAWhile_1651 = $1651
;waitLoop2_1656 = $1656
;waitLoop1_165B = $165B
;playAudioFx_Noise8 = $1666
;sub_167B = $167B
;locret_168B = $168B
;sub_168C = $168C
;locret_169C = $169C
;sub_169D = $169D
;locret_16AD = $16AD
;checkCollisions_16AE = $16AE
;loc_16C8 = $16C8
;loc_16CD = $16CD
;loc_16DA = $16DA
;loc_16E3 = $16E3
;loc_16E8 = $16E8
;loc_16F5 = $16F5
;loc_16FE = $16FE
;loc_1703 = $1703
;loc_1710 = $1710
;locret_1716 = $1716
;musicDataStarDust_1780 = $1780
;musicDataLazerJones_1800 = $1800
;musicDataTheWall_1880 = $1880
;musicDataResQ_1900 = $1900
;musicDataTheHillsAreAlive_1980 = $1980
;musicDataScoot_1A00 = $1A00
;musicData99redBalloons = $1A80
;musicDataWipeout_1B00 = $1B00
;musicDataCleaning_1B80 = $1B80
;musicDataTitle_1C00 = $1C00
;musicDataEggieChuck_1D00 = $1D00
;musicDataTheReflex_1D80 = $1D80
;musicDataTheTurk_1E00 = $1E00
;musicDataJayWalk_1E80 = $1E80
;musicDataTheOutland_1F00 = $1F00
;musicDataLazyNightmare_1F80 = $1F80
;musicDataToilet_2000 = $2000
;musicDataCocktails_2080 = $2080
;musicDataWildWafers_2100 = $2100
;Charset_Cocktails_2180 = $2180
;textSubgameTheTurk_2B80 = $2B80
;Charset_3000 = $3000
;byte_3340 = $3340
;byte_3347 = $3347
;spriteJetmanLeft_3400 = $3400
;byte_3401 = $3401
;spriteJetmanRight_3440 = $3440
;byte_3441 = $3441
;spriteWavingMan0_3480 = $3480
;spriteWavingMan1_34c0 = $34C0
;spriteLazyJonesRightLight0_3580 = $3580
;spriteLazyJonesRightDark1_35c0 = $35C0
;spriteLazyJonesRightLight1_3600 = $3600
;spriteLazyJonesLeftDark0_3640 = $3640
;spriteLazyJonesLeftLight0_3680 = $3680
;spriteLazyJonesLeftDark1_36c0 = $36C0
;spriteLazyJonesLeftLight2_3700 = $3700
;spriteLazyJonesLeftDark2_3740 = $3740
;spriteLazyJonesLeftLight2_3780 = $3780
;spriteLazyJonesLeftDark3_37c0 = $37C0
;spriteLazyJonesLeftLight3_3800 = $3800
;spriteCleaningWaggonLeft0_3840 = $3840
;spriteCleaningWaggonLeft1_3880 = $3880
;spriteCleaningWaggonLeft2_38c0 = $38C0
;spriteCleaningWaggonRight0_3900 = $3900
;spriteCleaningWaggonRight1_3940 = $3940
;spriteCleaningWaggonRight2_3980 = $3980
;spriteCleaningWaggonBgColLeft_39c0 = $39C0
;spriteCleaningWaggonBgColRight_39c0 = $3A00
;spriteElevator_3a40 = $3A40
;spriteBaloon0_3a80 = $3A80
;spriteBaloon1_3ac0 = $3AC0
;spriteBaloonBroken_3b00 = $3B00
;spriteSmallManRight0_3b40 = $3B40
;spriteSmallManRight1_3b80 = $3B80
;spriteSmallManRight2_3bc0 = $3BC0
;spriteSmallManRight3_3c00 = $3C00
;spriteSmallManLeft0_3c40 = $3C40
;spriteSmallManLeft1_3c80 = $3C80
;spriteSmallManLeft2_3cc0 = $3CC0
;spriteSmallManLeft3_3d00 = $3D00
;spriteSmallBar_3d40 = $3D40
;spriteBow0_3d80 = $3D80
;spriteBow1_3dc0 = $3DC0
;spriteAirPlaneA_3e00 = $3E00
;spriteAirPlaneB_3e40 = $3E40
;spriteUfo0_3e80 = $3E80
;spriteUfo1_3ec0 = $3EC0
;spriteUfo2_3f00 = $3F00
;spriteScooterRight_3f40 = $3F40
;spriteScooterLeft_3f80 = $3F80
;spritePlatform_3fc0 = $3FC0
;textSubgameDefault = $4000
;textSubgameTVBorder = $4090
;textSubgameDefault2 = $4228
;textSubgame99RedBalloons_42F8 = $42F8
;textMainGameScreen = $4440
;textSubgameStarDustAndTheReflex_4790 = $4790
;textSubgameTheHillsAreAlive_48C8 = $48C8
;textGetReady_49E8 = $49E8
;textErasingGetReadyAndGameOver_4A08 = $4A08
;textSubgameLazerJones_4A28 = $4A28
;textSubgameScoot_4BA0 = $4BA0
;textGameOver_4CE8 = $4CE8
;textSubgameTheReflex_4E10 = $4E10
;textSubgameToilet_4E40 = $4E40
;textSubgameCleaning_4E98 = $4E98
;textSubgameTheWall_4F08 = $4F08
;textSubgameCocktails0_4F68 = $4F68
;textSubgameCocktails1_4F93 = $4F93
;textSubgameCocktails2_4F97 = $4F97
;textSubgameCocktails3_4FA4 = $4FA4
;textSubgameCocktails4_4FA8 = $4FA8
;textSubgameCocktails5_4FD2 = $4FD2
;sub_4FF8 = $4FF8
;scrollCharsToTheLeft = $5000
;loc_5010 = $5010
;loc_501A = $501A
;loc_5042 = $5042
;scrollCharsToTheRight = $5050
;loc_5060 = $5060
;loc_506A = $506A
;loc_5090 = $5090
;animateLazyJones_50A0 = $50A0
;loc_50AB = $50AB
;animateLazyJones_50B8 = $50B8
;loc_50C3 = $50C3
;sub_5140 = $5140
;sub_5170 = $5170
;sub_51A0 = $51A0
;sub_51D0 = $51D0
;sub_5200 = $5200
;sub_5208 = $5208
;sub_5220 = $5220
;sub_5250 = $5250
;sub_5274 = $5274
;sub_5298 = $5298
;sub_52B4 = $52B4
;sub_52D0 = $52D0
;sub_52E8 = $52E8
;sub_5310 = $5310
;sub_5342 = $5342
;sub_5374 = $5374
;sub_53A6 = $53A6
;sub_53D8 = $53D8
;byte_540C = $540C
;byte_540D = $540D
;byte_540E = $540E
;byte_540F = $540F
;cleanUpMemoryMovement_5410 = $5410
;loc_5421 = $5421
;loc_5427 = $5427
;loc_542B = $542B
;loc_5431 = $5431
;loc_5435 = $5435
;loc_543B = $543B
;loc_544D = $544D
;loc_5460 = $5460
;locret_5472 = $5472
;grabJoystickPos = $5480
;loc_54A0 = $54A0
;loc_54AD = $54AD
;loc_54BA = $54BA
;loc_54CA = $54CA
;locret_54D6 = $54D6
;increaseSubgameScore_54E0 = $54E0
;incSubgameScore_54E5 = $54E5
;decreaseSubgameTime_5510 = $5510
;loc_5515 = $5515
;printTextAtFA = $5550
;moreText_5552 = $5552
;textDone_5560 = $5560
;sub_5570 = $5570
;loc_5572 = $5572
;loc_557F = $557F
;loc_558C = $558C
;loc_5599 = $5599
;loc_55A6 = $55A6
;loc_55B3 = $55B3
;loc_55C0 = $55C0
;loc_55CD = $55CD
;loc_55DA = $55DA
;loc_55E7 = $55E7
;loc_55F4 = $55F4
;loc_5601 = $5601
;loc_560E = $560E
;lazyWalkingIntoSubgameRoom_5620 = $5620
;loc_5644 = $5644
;loc_566D = $566D
;loc_5671 = $5671
;loc_5675 = $5675
;loc_568D = $568D
;loc_569E = $569E
;rorChars_56B0 = $56B0
;loc_56B2 = $56B2
;loc_56BA = $56BA
;loc_56C0 = $56C0
;loc_56CF = $56CF
;increaseXby8_56D6 = $56D6
;printGetReady_56E0 = $56E0
;getReadyLoop_56F3 = $56F3
;getReadyWaitLoop_570C = $570C
;sub_5720 = $5720
;loc_5722 = $5722
;lazyWalkingOutOfSubgameRoom_5760 = $5760
;loc_5784 = $5784
;loc_5793 = $5793
;loc_5797 = $5797
;loc_579B = $579B
;loc_57B3 = $57B3
;loc_57C4 = $57C4
;printGameOverText = $57D0
;loc_57E3 = $57E3
;sub_5810 = $5810
;loc_5814 = $5814
;loc_581E = $581E
;loc_5820 = $5820
;loc_583A = $583A
;rolCharsLeft_5848 = $5848
;moreLines_584A = $584A
;origPoi_5852 = $5852
;destPoi_5858 = $5858
;endLoop_5867 = $5867
;decrementXwith8_586E = $586E
;textSubgameOutland_5878 = $5878
;playAudioFx_Toilet_59B0 = $59B0
;loc_59C1 = $59C1
;loc_59C6 = $59C6
;sub_59D0 = $59D0
;loc_59DE = $59DE
;locret_59E4 = $59E4
;loc_59E5 = $59E5
;loc_59E9 = $59E9
;loc_59EF = $59EF
;loc_59F5 = $59F5
;textSubgameWildWafers_5A00 = $5A00
;textSubgameCocktails6_5B38 = $5B38
;musicIrq = $5D30
;noNewNoteVoice1 = $5D58
;noNewNoteVoice2 = $5D7E
;musicPatternLength = $5D9A
;noMusic = $5DAD
;musicInit = $5DB0
;textSubgameLazyNightmare_5DD0 = $5DD0
;textSubgameWipeout0_5E38 = $5E38
;textSubgameWipeout1_5E50 = $5E50
;textSubgameEggieChuck_5FF0 = $5FF0
;textSubgameJayWalk_6160 = $6160
;textSubgameResQ_62E0 = $62E0
;Game00_99redBalloons_6410 = $6410
;loc_6484 = $6484
;loc_650A = $650A
;loc_6512 = $6512
;loc_651A = $651A
;loc_6522 = $6522
;loc_652A = $652A
;loc_6532 = $6532
;loc_6549 = $6549
;loc_6564 = $6564
;loc_6578 = $6578
;loc_6587 = $6587
;loc_659F = $659F
;loc_65C0 = $65C0
;sub_65CC = $65CC
;loc_65D0 = $65D0
;loc_65D4 = $65D4
;sub_65E0 = $65E0
;sub_65EF = $65EF
;loc_6604 = $6604
;loc_660E = $660E
;loc_6618 = $6618
;loc_662A = $662A
;loc_6636 = $6636
;loc_6642 = $6642
;locret_664C = $664C
;sub_664D = $664D
;loc_6659 = $6659
;locret_6665 = $6665
;sub_6666 = $6666
;loc_6678 = $6678
;loc_6682 = $6682
;loc_66A4 = $66A4
;locret_66B6 = $66B6
;sub_66B7 = $66B7
;loc_66C9 = $66C9
;loc_66D6 = $66D6
;loc_66DF = $66DF
;locret_6710 = $6710
;sub_6711 = $6711
;loc_6730 = $6730
;sub_6736 = $6736
;loc_6747 = $6747
;loc_674B = $674B
;loc_6751 = $6751
;sub_6755 = $6755
;loc_676E = $676E
;loc_6778 = $6778
;sub_677F = $677F
;locret_6793 = $6793
;loc_6794 = $6794
;sub_679E = $679E
;loc_67A9 = $67A9
;loc_67CF = $67CF
;sub_67E1 = $67E1
;loc_67F4 = $67F4
;loc_67F8 = $67F8
;loc_6817 = $6817
;loc_6820 = $6820
;sub_682C = $682C
;loc_683F = $683F
;loc_684B = $684B
;loc_684F = $684F
;loc_6873 = $6873
;sub_687C = $687C
;loc_688F = $688F
;loc_689B = $689B
;loc_689F = $689F
;loc_68BE = $68BE
;sub_68C7 = $68C7
;loc_68E3 = $68E3
;loc_68F6 = $68F6
;playAudioFx_Die = $68F9
;audioFx_Loop = $690A
;loc_690F = $690F
;locret_6915 = $6915
;sub_6916 = $6916
;loc_6926 = $6926
;loc_692A = $692A
;loc_693A = $693A
;sub_6947 = $6947
;loc_6959 = $6959
;loc_6970 = $6970
;sub_6989 = $6989
;loc_6994 = $6994
;loc_69A9 = $69A9
;sub_69B2 = $69B2
;loc_69B4 = $69B4
;loc_69C3 = $69C3
;loc_69C8 = $69C8
;loc_69D7 = $69D7
;Game01_StarDust_69E0 = $69E0
;loc_69FF = $69FF
;loc_6AC4 = $6AC4
;loc_6AD8 = $6AD8
;loc_6AE4 = $6AE4
;loc_6AEC = $6AEC
;loc_6AF4 = $6AF4
;loc_6B02 = $6B02
;loc_6B17 = $6B17
;loc_6B43 = $6B43
;loc_6B60 = $6B60
;sub_6B63 = $6B63
;locret_6B74 = $6B74
;loc_6B75 = $6B75
;playAudioFx_StarDust = $6B80
;locret_6BA8 = $6BA8
;sub_6BA9 = $6BA9
;sub_6BB4 = $6BB4
;loc_6BCD = $6BCD
;loc_6BD6 = $6BD6
;loc_6BDF = $6BDF
;loc_6BE8 = $6BE8
;loc_6BF1 = $6BF1
;loc_6BFA = $6BFA
;loc_6BFC = $6BFC
;sub_6C00 = $6C00
;locret_6C17 = $6C17
;sub_6C18 = $6C18
;loc_6C26 = $6C26
;sub_6C32 = $6C32
;loc_6C36 = $6C36
;loc_6C3A = $6C3A
;sub_6C46 = $6C46
;loc_6C4E = $6C4E
;loc_6C53 = $6C53
;loc_6C88 = $6C88
;loc_6CA0 = $6CA0
;loc_6CA4 = $6CA4
;loc_6CC1 = $6CC1
;loc_6CCB = $6CCB
;loc_6CDD = $6CDD
;loc_6CE1 = $6CE1
;playAudioFx_StarDust1 = $6CFA
;playAudioFx_Noise = $6D0F
;Game02_TheHillsAreAlive_6D30 = $6D30
;loc_6DF7 = $6DF7
;loc_6E0C = $6E0C
;loc_6E16 = $6E16
;loc_6E1E = $6E1E
;loc_6E28 = $6E28
;loc_6E30 = $6E30
;loc_6E38 = $6E38
;loc_6E45 = $6E45
;loc_6E4F = $6E4F
;loc_6E8D = $6E8D
;loc_6EA7 = $6EA7
;sub_6EAA = $6EAA
;loc_6EB9 = $6EB9
;loc_6EBD = $6EBD
;loc_6EC5 = $6EC5
;sub_6EC9 = $6EC9
;locret_6EFD = $6EFD
;loc_6EFE = $6EFE
;sub_6F04 = $6F04
;loc_6F12 = $6F12
;sub_6F1E = $6F1E
;loc_6F2D = $6F2D
;sub_6F35 = $6F35
;sub_6F46 = $6F46
;loc_6F61 = $6F61
;locret_6F64 = $6F64
;sub_6F65 = $6F65
;loc_6F7E = $6F7E
;locret_6F88 = $6F88
;sub_6F89 = $6F89
;loc_6F9B = $6F9B
;loc_6FAE = $6FAE
;loc_6FC7 = $6FC7
;loc_6FD9 = $6FD9
;sub_6FE1 = $6FE1
;loc_6FE5 = $6FE5
;loc_6FE9 = $6FE9
;sub_6FF5 = $6FF5
;sub_6FFC = $6FFC
;sub_7007 = $7007
;loc_7009 = $7009
;Game03_LazerJones_7020 = $7020
;loc_70C8 = $70C8
;loc_70D5 = $70D5
;loc_70DF = $70DF
;loc_70E7 = $70E7
;loc_70EF = $70EF
;loc_70F9 = $70F9
;loc_710B = $710B
;loc_711D = $711D
;loc_712F = $712F
;loc_713C = $713C
;loc_7153 = $7153
;loc_7160 = $7160
;sub_7166 = $7166
;loc_716E = $716E
;sub_7188 = $7188
;loc_7190 = $7190
;sub_71AA = $71AA
;loc_71C5 = $71C5
;loc_71CA = $71CA
;loc_71DA = $71DA
;loc_7222 = $7222
;loc_7229 = $7229
;loc_7243 = $7243
;loc_725D = $725D
;loc_7262 = $7262
;loc_727C = $727C
;loc_7296 = $7296
;loc_729C = $729C
;loc_729E = $729E
;loc_72B8 = $72B8
;loc_72D2 = $72D2
;loc_72D9 = $72D9
;loc_72F3 = $72F3
;loc_730D = $730D
;sub_7311 = $7311
;loc_7319 = $7319
;loc_731E = $731E
;loc_7343 = $7343
;loc_7368 = $7368
;loc_738D = $738D
;loc_73B6 = $73B6
;loc_73C0 = $73C0
;locret_73C8 = $73C8
;sub_73C9 = $73C9
;loc_73CF = $73CF
;sub_7404 = $7404
;loc_7436 = $7436
;loc_743F = $743F
;sub_7447 = $7447
;locret_7453 = $7453
;sub_7454 = $7454
;loc_7458 = $7458
;loc_745C = $745C
;sub_7468 = $7468
;sub_7474 = $7474
;loc_7476 = $7476
;sub_7488 = $7488
;sub_74D4 = $74D4
;loc_74D6 = $74D6
;loc_74E4 = $74E4
;loc_74F2 = $74F2
;loc_7503 = $7503
;Game04_Scoot_7510 = $7510
;loc_75D0 = $75D0
;loc_75EF = $75EF
;loc_75FD = $75FD
;loc_7601 = $7601
;loc_7621 = $7621
;loc_7648 = $7648
;loc_7662 = $7662
;loc_766D = $766D
;loc_7675 = $7675
;loc_767D = $767D
;loc_7685 = $7685
;sub_7688 = $7688
;loc_769B = $769B
;loc_76B9 = $76B9
;loc_76C3 = $76C3
;loc_76CD = $76CD
;loc_76D7 = $76D7
;loc_76F8 = $76F8
;locret_7701 = $7701
;sub_7702 = $7702
;loc_7722 = $7722
;loc_773F = $773F
;loc_775C = $775C
;loc_7777 = $7777
;loc_778E = $778E
;sub_7795 = $7795
;loc_77BA = $77BA
;sub_77C1 = $77C1
;loc_77C5 = $77C5
;loc_77C9 = $77C9
;sub_77D5 = $77D5
;loc_77D7 = $77D7
;Game05_TheReflex_77F0 = $77F0
;loc_78D8 = $78D8
;loc_78ED = $78ED
;loc_78F7 = $78F7
;loc_790F = $790F
;loc_7922 = $7922
;loc_7946 = $7946
;loc_795B = $795B
;sub_795E = $795E
;locret_7973 = $7973
;loc_7974 = $7974
;locret_7982 = $7982
;sub_7983 = $7983
;loc_7987 = $7987
;loc_7996 = $7996
;loc_79A5 = $79A5
;loc_79C3 = $79C3
;loc_79D5 = $79D5
;playAudioFx_SawTooth = $79EA
;sub_79FF = $79FF
;loc_7A10 = $7A10
;sub_7A1C = $7A1C
;loc_7A2D = $7A2D
;loc_7A3B = $7A3B
;locret_7A49 = $7A49
;playAudioFx_SawTooth2 = $7A4A
;sub_7A65 = $7A65
;sub_7A70 = $7A70
;loc_7A74 = $7A74
;loc_7A78 = $7A78
;Game06_Toilet_7A90 = $7A90
;loc_7ABF = $7ABF
;sub_7AD8 = $7AD8
;loc_7ADA = $7ADA
;Game0c_Cleaning_7AF0 = $7AF0
;loc_7B1F = $7B1F
;sub_7B38 = $7B38
;loc_7B3A = $7B3A
;Game07_Outland_7B50 = $7B50
;loc_7C0C = $7C0C
;loc_7C21 = $7C21
;loc_7C2B = $7C2B
;loc_7C33 = $7C33
;loc_7C3B = $7C3B
;loc_7C6A = $7C6A
;loc_7C7F = $7C7F
;loc_7CAC = $7CAC
;loc_7CC6 = $7CC6
;sub_7CC9 = $7CC9
;locret_7CDD = $7CDD
;loc_7CDE = $7CDE
;locret_7CEB = $7CEB
;sub_7CEC = $7CEC
;loc_7D07 = $7D07
;locret_7D1C = $7D1C
;sub_7D1D = $7D1D
;loc_7D28 = $7D28
;sub_7D2C = $7D2C
;loc_7D36 = $7D36
;sub_7D3A = $7D3A
;sub_7D46 = $7D46
;loc_7D50 = $7D50
;sub_7D84 = $7D84
;sub_7D91 = $7D91
;loc_7D93 = $7D93
;sub_7DA7 = $7DA7
;loc_7DB6 = $7DB6
;loc_7DBA = $7DBA
;loc_7DBF = $7DBF
;Game08_WildWafers_7DD0 = $7DD0
;loc_7E90 = $7E90
;loc_7EA5 = $7EA5
;loc_7EAF = $7EAF
;loc_7EC7 = $7EC7
;loc_7ECF = $7ECF
;loc_7F00 = $7F00
;loc_7F18 = $7F18
;loc_7F35 = $7F35
;loc_7F56 = $7F56
;sub_7F59 = $7F59
;loc_7F66 = $7F66
;loc_7F6E = $7F6E
;sub_7F76 = $7F76
;loc_7F86 = $7F86
;loc_7F96 = $7F96
;locret_7FBD = $7FBD
;loc_7FBE = $7FBE
;playAudioFx_SawTooth3 = $7FC7
;sub_7FDC = $7FDC
;loc_7FE6 = $7FE6
;sub_7FEA = $7FEA
;locret_8002 = $8002
;sub_8003 = $8003
;loc_8015 = $8015
;loc_802E = $802E
;loc_8035 = $8035
;loc_8047 = $8047
;sub_8071 = $8071
;loc_8074 = $8074
;loc_8091 = $8091
;sub_809E = $809E
;loc_80A3 = $80A3
;sub_80B0 = $80B0
;loc_80B7 = $80B7
;loc_80BB = $80BB
;sub_80C7 = $80C7
;loc_80D6 = $80D6
;loc_80E7 = $80E7
;loc_80EB = $80EB
;Game09_TheTurk_8100 = $8100
;loc_81C5 = $81C5
;loc_81DF = $81DF
;loc_81E9 = $81E9
;loc_8211 = $8211
;loc_8219 = $8219
;loc_8221 = $8221
;loc_8234 = $8234
;loc_825D = $825D
;loc_826D = $826D
;loc_8275 = $8275
;loc_8298 = $8298
;loc_82BC = $82BC
;sub_82BF = $82BF
;loc_82CC = $82CC
;loc_82D4 = $82D4
;sub_82DF = $82DF
;locret_82FF = $82FF
;sub_8300 = $8300
;loc_8316 = $8316
;loc_832E = $832E
;loc_833A = $833A
;loc_8352 = $8352
;locret_835E = $835E
;sub_835F = $835F
;sub_8373 = $8373
;loc_838B = $838B
;locret_83AD = $83AD
;sub_83AE = $83AE
;loc_83C5 = $83C5
;locret_83D0 = $83D0
;loc_83D1 = $83D1
;sub_840D = $840D
;loc_8416 = $8416
;loc_8422 = $8422
;loc_842B = $842B
;loc_8437 = $8437
;loc_844D = $844D
;sub_8483 = $8483
;loc_8487 = $8487
;loc_848B = $848B
;sub_8497 = $8497
;loc_84A1 = $84A1
;loc_84A7 = $84A7
;loc_84B2 = $84B2
;loc_84C1 = $84C1
;Game0a_TheWall_84D0 = $84D0
;loc_8513 = $8513
;loc_851F = $851F
;loc_852B = $852B
;loc_8537 = $8537
;loc_853C = $853C
;loc_8589 = $8589
;loc_8595 = $8595
;loc_85AC = $85AC
;loc_85BA = $85BA
;loc_85C8 = $85C8
;loc_85D6 = $85D6
;loc_85FC = $85FC
;loc_8603 = $8603
;loc_8607 = $8607
;loc_8626 = $8626
;loc_8678 = $8678
;loc_867D = $867D
;loc_8681 = $8681
;sub_8692 = $8692
;loc_86AB = $86AB
;loc_86C1 = $86C1
;loc_86D7 = $86D7
;locret_86EC = $86EC
;Game0b_Cocktails_86F0 = $86F0
;loc_8711 = $8711
;loc_8720 = $8720
;loc_8807 = $8807
;loc_8831 = $8831
;loc_8842 = $8842
;loc_885D = $885D
;loc_886E = $886E
;loc_887D = $887D
;loc_8880 = $8880
;loc_8888 = $8888
;loc_889D = $889D
;loc_88A4 = $88A4
;loc_88D2 = $88D2
;sub_88D5 = $88D5
;loc_88F7 = $88F7
;loc_8910 = $8910
;loc_891F = $891F
;loc_892E = $892E
;loc_8940 = $8940
;loc_8952 = $8952
;loc_895A = $895A
;loc_8965 = $8965
;sub_896D = $896D
;locret_8980 = $8980
;sub_8981 = $8981
;locret_8994 = $8994
;sub_8995 = $8995
;loc_89B6 = $89B6
;loc_89C9 = $89C9
;loc_89D1 = $89D1
;loc_89E3 = $89E3
;loc_89EE = $89EE
;loc_89F9 = $89F9
;sub_8A04 = $8A04
;loc_8A11 = $8A11
;loc_8A17 = $8A17
;loc_8A32 = $8A32
;sub_8A4D = $8A4D
;loc_8A56 = $8A56
;loc_8A58 = $8A58
;loc_8A5E = $8A5E
;loc_8A6D = $8A6D
;loc_8A7F = $8A7F
;sub_8A8C = $8A8C
;loc_8A8E = $8A8E
;sub_8A97 = $8A97
;loc_8A99 = $8A99
;sub_8AA2 = $8AA2
;loc_8AB5 = $8AB5
;loc_8ACA = $8ACA
;sub_8AD4 = $8AD4
;loc_8AD8 = $8AD8
;loc_8ADC = $8ADC
;sub_8AE8 = $8AE8
;loc_8AEA = $8AEA
;printCocktailTime_8AFE = $8AFE
;printCocktailScore_8B2F = $8B2F
;sub_8B61 = $8B61
;loc_8B6D = $8B6D
;Game0d_LazyNightmare_8B90 = $8B90
;loc_8C35 = $8C35
;loc_8C51 = $8C51
;loc_8C87 = $8C87
;sub_8C8D = $8C8D
;loc_8C91 = $8C91
;loc_8C95 = $8C95
;sub_8CA1 = $8CA1
;loc_8CA3 = $8CA3
;loc_8CB6 = $8CB6
;sub_8CC8 = $8CC8
;loc_8CCA = $8CCA
;Game0e_EggieChuck_8CE0 = $8CE0
;loc_8DB9 = $8DB9
;loc_8DD9 = $8DD9
;loc_8DE3 = $8DE3
;loc_8DEB = $8DEB
;loc_8DF3 = $8DF3
;loc_8E1A = $8E1A
;loc_8E27 = $8E27
;loc_8E46 = $8E46
;sub_8E49 = $8E49
;loc_8E54 = $8E54
;loc_8E5D = $8E5D
;loc_8E67 = $8E67
;loc_8E72 = $8E72
;loc_8E81 = $8E81
;loc_8E89 = $8E89
;loc_8EA1 = $8EA1
;loc_8EAA = $8EAA
;locret_8EAD = $8EAD
;sub_8EAE = $8EAE
;loc_8EBE = $8EBE
;sub_8EC4 = $8EC4
;loc_8ECC = $8ECC
;loc_8ED9 = $8ED9
;locret_8EE7 = $8EE7
;sub_8EE8 = $8EE8
;loc_8F01 = $8F01
;loc_8F0F = $8F0F
;loc_8F1E = $8F1E
;loc_8F24 = $8F24
;loc_8F27 = $8F27
;loc_8F40 = $8F40
;loc_8F4E = $8F4E
;loc_8F5D = $8F5D
;loc_8F63 = $8F63
;loc_8F66 = $8F66
;loc_8F7F = $8F7F
;loc_8F8D = $8F8D
;loc_8F9C = $8F9C
;loc_8FA2 = $8FA2
;locret_8FA5 = $8FA5
;sub_8FA6 = $8FA6
;loc_8FBF = $8FBF
;loc_8FCE = $8FCE
;loc_8FDD = $8FDD
;locret_8FEC = $8FEC
;loc_8FED = $8FED
;loc_9000 = $9000
;loc_900F = $900F
;loc_901E = $901E
;locret_902D = $902D
;loc_902E = $902E
;loc_9041 = $9041
;loc_9050 = $9050
;loc_905F = $905F
;locret_906E = $906E
;loc_906F = $906F
;loc_9082 = $9082
;loc_9091 = $9091
;locret_90A0 = $90A0
;loc_90A1 = $90A1
;locret_90C4 = $90C4
;sub_90C5 = $90C5
;loc_90CD = $90CD
;loc_90DB = $90DB
;loc_90E3 = $90E3
;locret_90EB = $90EB
;loc_90EC = $90EC
;sub_90FD = $90FD
;loc_9109 = $9109
;loc_9121 = $9121
;loc_912F = $912F
;sub_913E = $913E
;loc_9140 = $9140
;loc_9153 = $9153
;loc_9166 = $9166
;sub_9178 = $9178
;loc_917C = $917C
;loc_9180 = $9180
;playAudioFx_Noise4 = $918C
;Game0f_WipeOut_91B0 = $91B0
;loc_91F9 = $91F9
;loc_921F = $921F
;loc_922B = $922B
;loc_9237 = $9237
;loc_9243 = $9243
;loc_92A6 = $92A6
;loc_92CD = $92CD
;loc_92D7 = $92D7
;loc_92E6 = $92E6
;loc_92E9 = $92E9
;loc_9306 = $9306
;loc_932F = $932F
;sub_9332 = $9332
;locret_936F = $936F
;sub_9370 = $9370
;locret_93AD = $93AD
;sub_93AE = $93AE
;loc_93C9 = $93C9
;loc_93D2 = $93D2
;loc_93DB = $93DB
;loc_93E9 = $93E9
;loc_93F5 = $93F5
;loc_9408 = $9408
;loc_9416 = $9416
;loc_9427 = $9427
;loc_9438 = $9438
;loc_946A = $946A
;loc_948C = $948C
;loc_948F = $948F
;loc_94C8 = $94C8
;loc_94F6 = $94F6
;sub_9516 = $9516
;loc_9521 = $9521
;loc_9524 = $9524
;loc_952F = $952F
;locret_9532 = $9532
;sub_9533 = $9533
;sub_9545 = $9545
;sub_9557 = $9557
;sub_9569 = $9569
;playAudioFx_Noise5 = $957B
;sub_9590 = $9590
;loc_9594 = $9594
;loc_9598 = $9598
;playAudioFx_SawTooth4 = $95A4
;playAudioFx_SawTooth5 = $95B9
;Game10_JayWalk_95D0 = $95D0
;loc_9669 = $9669
;loc_9684 = $9684
;loc_9696 = $9696
;loc_96A8 = $96A8
;loc_96BA = $96BA
;loc_96CC = $96CC
;loc_96F6 = $96F6
;loc_9703 = $9703
;loc_971A = $971A
;sub_971D = $971D
;loc_9728 = $9728
;loc_9731 = $9731
;loc_973B = $973B
;loc_9746 = $9746
;loc_9755 = $9755
;loc_975D = $975D
;loc_9772 = $9772
;loc_9778 = $9778
;locret_977B = $977B
;sub_977C = $977C
;loc_978C = $978C
;sub_9792 = $9792
;loc_979D = $979D
;loc_97A6 = $97A6
;loc_97B0 = $97B0
;loc_97BB = $97BB
;loc_97CA = $97CA
;loc_97D2 = $97D2
;loc_97DC = $97DC
;loc_97E6 = $97E6
;loc_97F7 = $97F7
;locret_97FA = $97FA
;sub_97FB = $97FB
;locret_9811 = $9811
;sub_9812 = $9812
;loc_981E = $981E
;sub_9838 = $9838
;loc_9844 = $9844
;sub_9860 = $9860
;sub_9872 = $9872
;sub_9884 = $9884
;sub_9896 = $9896
;sub_98A8 = $98A8
;sub_98BA = $98BA
;loc_98E0 = $98E0
;loc_98EB = $98EB
;loc_98F3 = $98F3
;sub_98FA = $98FA
;loc_990E = $990E
;sub_991D = $991D
;locret_993B = $993B
;loc_993C = $993C
;sub_9956 = $9956
;loc_995A = $995A
;sub_9962 = $9962
;loc_9964 = $9964
;loc_9977 = $9977
;sub_9989 = $9989
;loc_998D = $998D
;loc_9991 = $9991
;Game11_ResQ_99A0 = $99A0
;loc_9A5E = $9A5E
;loc_9A79 = $9A79
;loc_9A95 = $9A95
;loc_9AB2 = $9AB2
;loc_9AC2 = $9AC2
;loc_9AD9 = $9AD9
;sub_9ADC = $9ADC
;loc_9AE7 = $9AE7
;loc_9AF5 = $9AF5
;loc_9B04 = $9B04
;sub_9B0F = $9B0F
;loc_9B1A = $9B1A
;loc_9B2B = $9B2B
;loc_9B35 = $9B35
;playAudioFx_Noise6 = $9B40
;sub_9B55 = $9B55
;loc_9B68 = $9B68
;loc_9B76 = $9B76
;loc_9B84 = $9B84
;loc_9B92 = $9B92
;locret_9BA0 = $9BA0
;loc_9BA1 = $9BA1
;loc_9BA8 = $9BA8
;loc_9BC0 = $9BC0
;loc_9BD6 = $9BD6
;sub_9BE9 = $9BE9
;loc_9BEB = $9BEB
;loc_9BF6 = $9BF6
;sub_9BFE = $9BFE
;loc_9C0A = $9C0A
;loc_9C22 = $9C22
;loc_9C2D = $9C2D
;sub_9C3B = $9C3B
;loc_9C43 = $9C43
;loc_9C4A = $9C4A
;loc_9C51 = $9C51
;loc_9C58 = $9C58
;loc_9C5F = $9C5F
;loc_9C71 = $9C71
;locret_9C78 = $9C78
;sub_9C79 = $9C79
;loc_9C84 = $9C84
;sub_9C8A = $9C8A
;sub_9C9D = $9C9D
;sub_9CB2 = $9CB2
;sub_9CC5 = $9CC5
;sub_9CD8 = $9CD8
;sub_9CEB = $9CEB
;sub_9D36 = $9D36
;loc_9D38 = $9D38
;loc_9D4B = $9D4B
;sub_9D5D = $9D5D
;loc_9D61 = $9D61
;loc_9D65 = $9D65
;isThisANewHiscore = $9D80
;thisIsANewHiscore = $9D9F
;noNewHiscore = $9DB1
;printScoreHiscoreLivesToScreen = $9DB2
;increasePlayerScore = $9E46
;textHowManyLives_9E78 = $9E78
;textWelcomeToTheWorldOfLazy_9EC8 = $9EC8
;textControlsAre_9F61 = $9F61










;The subgame screen:
* = $0400
  !byte $69,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$6c,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$69,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$6c,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$5c,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$5d,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$0e,$05,$18,$14,$00,$0c,$05,$16,$05,$0c,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$41,$42,$43,$44,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$45,$46,$47,$48,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$49,$4a,$4b,$4c,$4d,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$4e,$4f,$50,$51,$52,$20,$20,$20,$20,$20,$20,$20
  !byte $5b,$5b,$1e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $6d,$5b,$1e,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $20,$6d,$1e,$13,$03,$0f,$12,$05,$61,$30,$30,$30,$61,$61,$14,$09,$0d,$05,$61,$30,$30,$30,$39,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $20,$20,$5e,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$5f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$72,$73,$74,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$6d,$6e,$6f,$6c,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1b,$1c,$1d,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$71,$70,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1e,$5b,$1f,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$1e,$5b,$1f,$20,$20,$20,$20,$20,$20,$20,$20
  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$6d,$5b,$5b,$6c,$20,$20,$20,$20,$20,$20,$20

  !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
;The sprite pointers:
  !byte $9e,$9f,$a2,$ff,$ff,$ff,$00,$00


;---------------------------------------------------------------------------
* = $0800

* = Charset
Charset_3000:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $10
  !byte $38 ; 8
  !byte $10
  !byte 0
  !byte $3E ; >
  !byte $63 ; c
  !byte $63 ; c
  !byte $7F ; 
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $7E ; ~
  !byte $63 ; c
  !byte $63 ; c
  !byte $7E ; ~
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $7E ; ~
  !byte $3E ; >
  !byte $63 ; c
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $63 ; c
  !byte $3E ; >
  !byte $7E ; ~
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $7E ; ~
  !byte $7F ; 
  !byte $63 ; c
  !byte $60 ; `
  !byte $7C ; |
  !byte $60 ; `
  !byte $60 ; `
  !byte $63 ; c
  !byte $7F ; 
  !byte $7F ; 
  !byte $63 ; c
  !byte $60 ; `
  !byte $7C ; |
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $3E ; >
  !byte $63 ; c
  !byte $60 ; `
  !byte $60 ; `
  !byte $67 ; g
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $7F ; 
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $7E ; ~
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $7E ; ~
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $63 ; c
  !byte $66 ; f
  !byte $6C ; l
  !byte $78 ; x
  !byte $6C ; l
  !byte $66 ; f
  !byte $63 ; c
  !byte $63 ; c
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $63 ; c
  !byte $7F ; 
  !byte $63 ; c
  !byte $77 ; w
  !byte $7F ; 
  !byte $6B ; k
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $7E ; ~
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $7E ; ~
  !byte $63 ; c
  !byte $63 ; c
  !byte $7E ; ~
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $60 ; `
  !byte $3E ; >
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $7B ; {
  !byte $3E ; >
  !byte  $C
  !byte $7E ; ~
  !byte $63 ; c
  !byte $63 ; c
  !byte $7E ; ~
  !byte $78 ; x
  !byte $6C ; l
  !byte $66 ; f
  !byte $63 ; c
  !byte $3E ; >
  !byte $63 ; c
  !byte $60 ; `
  !byte $3E ; >
  !byte 3
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $7E ; ~
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $36 ; 6
  !byte $1C
  !byte 8
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $6B ; k
  !byte $7F ; 
  !byte $77 ; w
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $36 ; 6
  !byte $1C
  !byte $1C
  !byte $36 ; 6
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $3F ; ?
  !byte 3
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $7F ; 
  !byte $63 ; c
  !byte 6
  !byte  $C
  !byte $18
  !byte $30 ; 0
  !byte $63 ; c
  !byte $7F ; 
  !byte $FF
  !byte $C0 ; ¿
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $FF
  !byte 0
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte 3
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FC ; ¸
  !byte $FC ; ¸
  !byte $FF
  !byte $FF
  !byte $FF
  !byte 0
  !byte $36 ; 6
  !byte $36 ; 6
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $1F
  !byte $3F ; ?
  !byte $66 ; f
  !byte $36 ; 6
  !byte 6
  !byte 6
  !byte  $F
  !byte 0
  !byte $FF
  !byte $FF
  !byte $66 ; f
  !byte $66 ; f
  !byte $66 ; f
  !byte $66 ; f
  !byte $FF
  !byte 0
  !byte $F8 ; ¯
  !byte $FC ; ¸
  !byte $66 ; f
  !byte $6C ; l
  !byte $60 ; `
  !byte $60 ; `
  !byte $F0 ; 
  !byte 0
  !byte 0
  !byte 1
  !byte 7
  !byte  $C
  !byte $18
  !byte $31 ; 1
  !byte $33 ; 3
  !byte $1A
  !byte 1
  !byte $C7 ; «
  !byte $6D ; m
  !byte $38 ; 8
  !byte $19
  !byte $DB ; €
  !byte $78 ; x
  !byte $3B ; ;
  !byte $F0 ; 
  !byte $18
  !byte $88 ; à
  !byte $DC ; ‹
  !byte $B6 ; ∂
  !byte $33 ; 3
  !byte $E3 ; „
  !byte $E6 ; Ê
  !byte  $F
  !byte $18
  !byte $31 ; 1
  !byte $67 ; g
  !byte $6C ; l
  !byte $2D ; -
  !byte 7
  !byte 0
  !byte $1E
  !byte $9C ; ú
  !byte $D9 ; Ÿ
  !byte $7B ; {
  !byte $3E ; >
  !byte $1C
  !byte $18
  !byte $3C ; <
  !byte $30 ; 0
  !byte $18
  !byte  $C
  !byte $8C ; å
  !byte $C6 ; ∆
  !byte $6C ; l
  !byte $C0 ; ¿
  !byte $80 ; Ä
  !byte 7
  !byte 7
  !byte 3
  !byte 3
  !byte 3
  !byte 1
  !byte 1
  !byte 0
  !byte $FF
  !byte $FF
  !byte $55 ; U
  !byte $FF
  !byte $FF
  !byte $EA ; Í
  !byte $FF
  !byte 0
  !byte $E0 ; ‡
  !byte $E0 ; ‡
  !byte $40 ; @
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte 0
  !byte $80 ; Ä
  !byte 0
  !byte $C0 ; ¿
  !byte $60 ; `
  !byte $30 ; 0
  !byte $18
  !byte  $C
  !byte 6
  !byte 3
  !byte 1
  !byte $1C
  !byte $36 ; 6
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $36 ; 6
  !byte $1C
  !byte $18
  !byte $38 ; 8
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $3C ; <
  !byte $3E ; >
  !byte $63 ; c
  !byte 3
  !byte $3E ; >
  !byte $60 ; `
  !byte $60 ; `
  !byte $63 ; c
  !byte $7F ; 
  !byte $3E ; >
  !byte $63 ; c
  !byte 3
  !byte $1E
  !byte 3
  !byte 3
  !byte $63 ; c
  !byte $3E ; >
  !byte 6
  !byte  $E
  !byte $1E
  !byte $36 ; 6
  !byte $66 ; f
  !byte $7F ; 
  !byte 6
  !byte 6
  !byte $7F ; 
  !byte $63 ; c
  !byte $60 ; `
  !byte $7E ; ~
  !byte 3
  !byte 3
  !byte $63 ; c
  !byte $3E ; >
  !byte $3E ; >
  !byte $63 ; c
  !byte $60 ; `
  !byte $7E ; ~
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $7F ; 
  !byte $63 ; c
  !byte 6
  !byte  $C
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte $3E ; >
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $63 ; c
  !byte $63 ; c
  !byte $63 ; c
  !byte $3E ; >
  !byte $3E ; >
  !byte $63 ; c
  !byte $63 ; c
  !byte $3F ; ?
  !byte 3
  !byte 3
  !byte $63 ; c
  !byte $3E ; >
  !byte $FF
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $FF
  !byte 0
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $FF
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $FF
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte $E7 ; Á
  !byte $E7 ; Á
  !byte $E7 ; Á
  !byte $E7 ; Á
  !byte $E7 ; Á
  !byte $E7 ; Á
  !byte $E7 ; Á
  !byte $E7 ; Á
  !byte $F7 ; ˜
  !byte $F7 ; ˜
  !byte $F7 ; ˜
  !byte $F7 ; ˜
  !byte $F7 ; ˜
  !byte $F7 ; ˜
  !byte $F7 ; ˜
  !byte $F7 ; ˜
  !byte $3C ; <
  !byte $42 ; B
  !byte $99 ; ô
  !byte $A1 ; °
  !byte $A1 ; °
  !byte $99 ; ô
  !byte $42 ; B
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte 7
  !byte 7
  !byte  $E
  !byte  $E
  !byte $1C
  !byte $1C
  !byte 0
  !byte 0
  !byte  $E
  !byte $1F
  !byte $1B
  !byte $33 ; 3
  !byte $33 ; 3
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $3F ; ?
  !byte $3F ; ?
  !byte $33 ; 3
  !byte 3
  !byte 6
  !byte  $C
  !byte 0
  !byte 0
  !byte $33 ; 3
  !byte $33 ; 3
  !byte $33 ; 3
  !byte $63 ; c
  !byte $66 ; f
  !byte $7E ; ~
  !byte $38 ; 8
  !byte $38 ; 8
  !byte $70 ; p
  !byte $70 ; p
  !byte $FE ; ˛
  !byte $FE ; ˛
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte $66 ; f
  !byte $C6 ; ∆
  !byte $CC ; Ã
  !byte $CC ; Ã
  !byte $CC ; Ã
  !byte 0
  !byte 0
  !byte $18
  !byte $30 ; 0
  !byte $60 ; `
  !byte $CC ; Ã
  !byte $FC ; ¸
  !byte $FC ; ¸
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte  $C
  !byte $CC ; Ã
  !byte $D8 ; ÿ
  !byte $F8 ; ¯
  !byte $70 ; p
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $FC ; ¸
  !byte $7E ; ~
  !byte $18
  !byte $18
  !byte  $C
  !byte  $C
  !byte 0
  !byte 0
  !byte $78 ; x
  !byte $FC ; ¸
  !byte $CC ; Ã
  !byte $CC ; Ã
  !byte $CC ; Ã
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $F8 ; ¯
  !byte $FC ; ¸
  !byte $CC ; Ã
  !byte $CC ; Ã
  !byte $CC ; Ã
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte $FE ; ˛
  !byte $C6 ; ∆
  !byte $C0 ; ¿
  !byte $60 ; `
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte $FE ; ˛
  !byte $C6 ; ∆
  !byte $C6 ; ∆
  !byte $60 ; `
  !byte $38 ; 8
  !byte  $C
  !byte 6
  !byte 6
  !byte $63 ; c
  !byte $7F ; 
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $33 ; 3
  !byte $33 ; 3
  !byte $33 ; 3
  !byte $3F ; ?
  !byte $3F ; ?
  !byte $1E
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte $66 ; f
  !byte $33 ; 3
  !byte $33 ; 3
  !byte $33 ; 3
  !byte $33 ; 3
  !byte 0
  !byte 0
  !byte $38 ; 8
  !byte $60 ; `
  !byte $63 ; c
  !byte $63 ; c
  !byte $3F ; ?
  !byte $1E
  !byte 0
  !byte 0
  !byte  $C
  !byte 6
  !byte $63 ; c
  !byte $63 ; c
  !byte $7F ; 
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $FC ; ¸
  !byte $FC ; ¸
  !byte $FC ; ¸
  !byte $FC ; ¸
  !byte $FC ; ¸
  !byte $FC ; ¸
  !byte $FC ; ¸
  !byte $FC ; ¸
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $F0 ; 
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte $C0 ; ¿
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte 3
  !byte  $F
  !byte  $F
  !byte  $F
  !byte  $F
  !byte  $F
  !byte  $F
  !byte  $F
  !byte  $F
  !byte $3F ; ?
  !byte $3F ; ?
  !byte $3F ; ?
  !byte $3F ; ?
  !byte $3F ; ?
  !byte $3F ; ?
  !byte $3F ; ?
  !byte $3F ; ?
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $3C ; <
  !byte $3C ; <
  !byte $3C ; <
  !byte $3C ; <
  !byte $3C ; <
  !byte $3C ; <
  !byte $3C ; <
  !byte $3C ; <
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $3F ; ?
  !byte $7F ; 
  !byte $E0 ; ‡
  !byte $C7 ; «
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $FC ; ¸
  !byte $FE ; ˛
  !byte 7
  !byte $E3 ; „
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $CF ; œ
  !byte $C7 ; «
  !byte $E0 ; ‡
  !byte $7F ; 
  !byte $3F ; ?
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $F3 ; Û
  !byte $E3 ; „
  !byte 7
  !byte $FE ; ˛
  !byte $FC ; ¸
  !byte $FF
  !byte $FF
  !byte 0
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte 0
  !byte $FF
  !byte $FF
  !byte 0
  !byte 3
  !byte  $F
  !byte 7
  !byte $2B ; +
  !byte $11
  !byte 3
  !byte 7
  !byte 0
  !byte $C0 ; ¿
  !byte $F0 ; 
  !byte $E0 ; ‡
  !byte $D4 ; ‘
  !byte $88 ; à
  !byte $C0 ; ¿
  !byte $E0 ; ‡
  !byte  $D
  !byte $1B
  !byte 7
  !byte  $F
  !byte $1F
  !byte 1
  !byte 7
  !byte 0
  !byte $B0 ; ∞
  !byte $D8 ; ÿ
  !byte $E0 ; ‡
  !byte $F0 ; 
  !byte $F8 ; ¯
  !byte $80 ; Ä
  !byte $E0 ; ‡
  !byte 0
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $FF
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $C3 ; √
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
  !byte $FF
byte_3340:  !byte $FF   ; DATA XREF: sub_809E+Ew
  !byte $81 ; Å
  !byte $81 ; Å
  !byte $81 ; Å
  !byte $81 ; Å
  !byte $81 ; Å
  !byte $81 ; Å
byte_3347:  !byte $81   ; DATA XREF: sub_809Er
  !byte $7F ; 
  !byte $BF ; ø
  !byte $DF ; ﬂ
  !byte $EF ; Ô
  !byte $F7 ; ˜
  !byte $FB ; ˚
  !byte $FD ; ˝
  !byte $FE ; ˛
  !byte 1
  !byte 3
  !byte 7
  !byte  $F
  !byte $1F
  !byte $3F ; ?
  !byte $7F ; 
  !byte $FF
  !byte $FE ; ˛
  !byte $FC ; ¸
  !byte $F8 ; ¯
  !byte $F0 ; 
  !byte $E0 ; ‡
  !byte $C0 ; ¿
  !byte $80 ; Ä
  !byte 0
  !byte $80 ; Ä
  !byte $C0 ; ¿
  !byte $E0 ; ‡
  !byte $F0 ; 
  !byte $F8 ; ¯
  !byte $FC ; ¸
  !byte $FE ; ˛
  !byte $FF
  !byte $FF
  !byte $7F ; 
  !byte $3F ; ?
  !byte $1F
  !byte  $F
  !byte 7
  !byte 3
  !byte 1
  !byte $FF
  !byte $57 ; W
  !byte $FF
  !byte $92 ; í
  !byte $C9 ; …
  !byte $E2 ; ‚
  !byte $F1 ; Ò
  !byte $FF
  !byte $FF
  !byte $EF ; Ô
  !byte $FF
  !byte $57 ; W
  !byte $23 ; #
  !byte $49 ; I
  !byte $25 ; %
  !byte $FF
  !byte $10
  !byte $10
  !byte 8
  !byte 8
  !byte 4
  !byte $64 ; d
  !byte $98 ; ò
  !byte 0
  !byte 0
  !byte 0
  !byte  $C
  !byte  $C
  !byte  $C
  !byte $1E
  !byte $3F ; ?
  !byte $1E
  !byte 0
  !byte 0
  !byte $79 ; y
  !byte $61 ; a
  !byte $78 ; x
  !byte $61 ; a
  !byte $79 ; y
  !byte 0
  !byte 0
  !byte 0
  !byte $B3 ; ≥
  !byte $B3 ; ≥
  !byte $E3 ; „
  !byte $B3 ; ≥
  !byte $B3 ; ≥
  !byte 0
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte $18
  !byte $18
  !byte $18
  !byte $18
  !byte 0
  !byte $E0 ; ‡
  !byte $E0 ; ‡
  !byte $E0 ; ‡
  !byte $E0 ; ‡
  !byte $E0 ; ‡
  !byte $E0 ; ‡
  !byte $E0 ; ‡
  !byte $E0 ; ‡
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte $FF
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $F0 ; 
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte $1F
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte $10
  !byte $F0 ; 
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $10
  !byte $10
  !byte $10
  !byte $1F
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $EE ; Ó
  !byte $DD ; ›
  !byte 0
  !byte $26 ; &
  !byte $23 ; #
  !byte 0
  !byte $BB ; ª
  !byte $77 ; w
  !byte $E0 ; ‡
  !byte $D8 ; ÿ
  !byte $38 ; 8
  !byte $B8 ; ∏
  !byte $80 ; Ä
  !byte $38 ; 8
  !byte $F0 ; 
  !byte $70 ; p
  !byte $FF
  !byte $81 ; Å
  !byte $81 ; Å
  !byte $81 ; Å
  !byte $81 ; Å
  !byte $81 ; Å
  !byte $81 ; Å
  !byte $FF
  !byte $FF
  !byte $C3 ; √
  !byte $A5 ; •
  !byte $99 ; ô
  !byte $99 ; ô
  !byte $A5 ; •
  !byte $C3 ; √
  !byte $FF













;byte_8D: !byte 0 ; (uninited)  ; DATA XREF: initRandomGameList+15r
;   ; sub_65E0+3r ...
;byte_8E: !byte 0 ; (uninited)  ; DATA XREF: Game09_TheTurk_8100+152r
;byte_8F: !byte 0 ; (uninited)  ; DATA XREF: Game09_TheTurk_8100+162r
;currentMusicPoiLSB_B4:!byte 0 ;  (uninited) ; DATA XREF: titleMusicInit+14w
;   ; ROM:noNewNoteVoice1r ...
;currentMusicPoiMSB_B5:!byte 0 ;  (uninited) ; DATA XREF: titleMusicInit+1Bw
;   ; ROM:5D5Fr ...
;byte_C5: !byte 0 ; (uninited)  ; DATA XREF: grabJoystickPos+11r
;   ; sub_59D0r ...
;byte_F8: !byte 0 ; (uninited)  ; DATA XREF: animateDoorsMaybe_10F2+9w
;   ; animateDoorsMaybe_10F2+2Dw ...
;byte_F9: !byte 0 ; (uninited)  ; DATA XREF: animateDoorsMaybe_10F2+Dw
;   ; animateDoorsMaybe_10F2+31w ...
;byte_FA: !byte 0 ; (uninited)  ; DATA XREF: initMainGame+2w
;   ; selectNumberOfLives_B53+7w ...
;byte_FB: !byte 0 ; (uninited)  ; DATA XREF: initMainGame+6w
;   ; selectNumberOfLives_B53+Bw ...
;byte_FC: !byte 0 ; (uninited)  ; DATA XREF: animateDoorsMaybe_10F2+19w
;   ; animateDoorsMaybe_10F2+3Dw ...
;byte_FD: !byte 0 ; (uninited)  ; DATA XREF: animateDoorsMaybe_10F2+1Dw
;   ; animateDoorsMaybe_10F2+41w ...
;byte_FE: !byte 0 ; (uninited)  ; DATA XREF: animateDoorsMaybe_10F2+21w
;   ; animateDoorsMaybe_10F2+45w ...
;byte_FF: !byte 0 ; (uninited)  ; DATA XREF: selectNumberOfLives_B53+17w
;   ; selectNumberOfLives_B53+3Bw ...
;currentPrintCharColour_286:!byte 0 ; (uninited)  ; DATA XREF: printGetReady_56E0+17w
;   ; printGameOverText+17w ...
;byte_28D:  !byte 0 ; (uninited)  ; DATA XREF: grabJoystickPos:loc_54BAr
;IrqPoiLSB_314: !byte 0 ; (uninited)  ; DATA XREF: musicInit+10w
;IrqPoiMSB_315: !byte 0 ; (uninited)  ; DATA XREF: musicInit+15w
;currentJoystickPos_33C:!byte 0 ; (uninited)
;   ; DATA XREF: mainGameLoop_869:noJumpingRightNow_8A1r
;   ; mainGameLoop_869+71r ...
;subgameScore0_33D:!byte  0 ; (uninited)  ; DATA XREF: increaseSubgameScore_54E0+1r
;   ; increaseSubgameScore_54E0+7w ...
;subgameScore1_33E:!byte  0 ; (uninited)  ; DATA XREF: increaseSubgameScore_54E0+Ar
;   ; increaseSubgameScore_54E0+Fw ...
;subgameTimeLSB_33F:!byte 0 ; (uninited)  ; DATA XREF: decreaseSubgameTime_5510+1r
;   ; decreaseSubgameTime_5510+7w ...
;subgameTimeMSB_340:!byte 0 ; (uninited)  ; DATA XREF: decreaseSubgameTime_5510+Ar
;   ; decreaseSubgameTime_5510+Fw ...
;byte_341:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+5Dw
;   ; sub_679E+18r ...
;byte_342:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+6Cw
;   ; sub_65EFr ...
;byte_343:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+CFw
;   ; Game00_99redBalloons_6410:loc_650Ar ...
;byte_344:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+D4w
;   ; sub_6666+20r ...
;byte_345:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+D9w
;   ; Game00_99redBalloons_6410:loc_652Ar ...
;byte_346:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+DEw
;   ; Game00_99redBalloons_6410:loc_651Ar ...
;byte_347:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+E3w
;   ; sub_679Ew ...
;byte_348:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+E8w
;     ; Game00_99redBalloons_6410+127w ...
;byte_349:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+EDw
;     ; sub_65EF:loc_6618w ...
;byte_34A:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+62w
;     ; sub_679E+10r ...
;byte_34B:  !byte 0 ; (uninited)  ; DATA XREF: Game00_99redBalloons_6410+F2w
;     ; sub_6989w ...
;byte_34C:  !byte 0 ; (uninited)  ; DATA XREF: Game03_LazerJones_7020+9Fw
;     ; sub_71AA+4Ar ...
;byte_34D:  !byte 0 ; (uninited)  ; DATA XREF: Game03_LazerJones_7020+92w
;     ; sub_71AA+52r ...
;byte_34E:  !byte 0 ; (uninited)  ; DATA XREF: Game03_LazerJones_7020+A2w
;     ; sub_71AA+5Br ...
;byte_34F:  !byte 0 ; (uninited)  ; DATA XREF: Game03_LazerJones_7020+97w
;     ; sub_71AA+63r ...
;byte_350:  !byte 0 ; (uninited)  ; DATA XREF: Game03_LazerJones_7020+A5w
;     ; sub_71AA+6Cr ...
;byte_351:  !byte 0 ; (uninited)  ; DATA XREF: Game03_LazerJones_7020+6Fw
;     ; Game03_LazerJones_7020:loc_710Bw ...
;byte_352:  !byte 0 ; (uninited)  ; DATA XREF: Game03_LazerJones_7020+74w
;     ; Game03_LazerJones_7020:loc_711Dw ...
;   ; 0 !byte uninited & unexplored
;byte_354:  !byte 0 ; (uninited)  ; DATA XREF: Game03_LazerJones_7020+79w
;     ; sub_7311r ...
;playerScore2_360:!byte 0 ; (uninited)  ; DATA XREF: mainGameLoop_869-3Bw
;     ; isThisANewHiscore+18r ...
;playerScore1_361:!byte 0 ; (uninited)  ; DATA XREF: mainGameLoop_869-38w
;     ; isThisANewHiscore+Er ...
;playerScore0_362:!byte 0 ; (uninited)  ; DATA XREF: mainGameLoop_869-35w
;     ; isThisANewHiscore+4r ...
;hiScore2_363:  !byte 0 ; (uninited)  ; DATA XREF: ROM:0823w
;     ; isThisANewHiscore+15r ...
;hiScore1_364:  !byte 0 ; (uninited)  ; DATA XREF: ROM:0826w
;     ; isThisANewHiscore+Br ...
;hiScore0_365:  !byte 0 ; (uninited)  ; DATA XREF: ROM:0829w
;     ; isThisANewHiscorer ...
;playerNumberOfLives_366:!byte 0  ; (uninited) ; DATA XREF: mainGameLoop_869+101r
;     ; selectNumberOfLives_B53+69w ...
;whichMainGameScreen_367:!byte 0  ; (uninited) ; DATA XREF: mainGameLoop_869:noNewJump_8ADr
;     ; mainGameLoop_869+55w ...
;gameListPointerLSB_389:!byte 0 ; (uninited) ; DATA XREF: initRandomGameList+1Cw
;     ; calcWhichRoom9to11_120E:loc_1286r ...
;gameListPointerMSB_38A:!byte 0 ; (uninited) ; DATA XREF: initRandomGameList+21w
;     ; calcWhichRoom9to11_120E+81r ...
;currentGameNumber_38B:!byte 0 ;  (uninited) ; DATA XREF: calcWhichRoom9to11_120E+8Cw
;     ; calcWhichRoom0to8_12A5+8Cw ...
;nofRoomsVisited_38C:!byte 0 ; (uninited) ; DATA  XREF: initRandomGameList+26w
;     ; calcWhichRoom0to8_12A5+A3w ...
;doingElevatorFlag_38D:!byte 0 ;  (uninited)
;     ; DATA XREF: mainGameLoop_869:thisIsNotJustDemo_87Er
;     ; mainGameLoop_869+7Fr ...
;jumpFlag_38E:  !byte 0 ; (uninited)  ; DATA XREF: mainGameLoop_869+2Br
;     ; mainGameLoop_869+33r ...
;directionManD004_38F:!byte 0 ; (uninited) ; DATA XREF: initMainGame+C8w
;     ; moveMan_CDC+4r ...
;directionDustVanD008_390:!byte 0 ; (uninited) ;  DATA XREF: initMainGame+CBw
;     ; moveDustvan_D7B+4r ...
;directionInvisibleManD00C_391:!byte 0 ;  (uninited) ; DATA XREF: initMainGame+CEw
;     ; moveInvisibleMan_E15+4r ...
;   ; 0 !byte uninited & unexplored
;whichFloorIsLazyJonesOn_393:!byte 0 ; (uninited) ; DATA  XREF: mainGameLoop_869+ADw
;     ; mainGameLoop_869+B6w ...
;doingElevatorFlagDelayed_394:!byte 0 ; (uninited) ; DATA XREF: mainGameLoop_869+82w
;     ; initMainGame+D8w ...
;doorAnimationCou_395:!byte 0 ; (uninited) ; DATA XREF: mainGameLoop_869+8Aw
;     ; mainGameLoop_869:loc_9BAr ...
;doorAnimationInc_396:!byte 0 ; (uninited) ; DATA XREF: mainGameLoop_869+92w
;     ; initMainGame+E2w ...
;didWeCollideFlag_397:!byte 0 ; (uninited) ; DATA XREF: mainGameLoop_869+20r
;     ; mainGameLoop_869+F9r ...
;joystickStatus_398:!byte 0 ; (uninited)  ; DATA XREF: mainGameLoop_869+97w
;     ; mainGameLoop_869:loc_9B0r ...
;doorAnimationStatus_399:!byte 0  ; (uninited) ; DATA XREF: mainGameLoop_869+8Dw
;     ; initMainGame+EDw ...
;gameListPointerInc_39A:!byte 0 ; (uninited) ; DATA XREF: initMainGame+F2w
;     ; calcWhichRoom9to11_120E+8w ...
;allRoomsVisited_39B:!byte 0 ; (uninited) ; DATA  XREF: mainGameLoop_869+120r
;     ; mainGameLoop_869+131r ...
;savedD000_LazyXpos_39C:!byte 0 ; (uninited) ; DATA XREF: calcWhichRoom0to8_12A5+BAw
;     ; calcWhichRoom0to8_12A5+2F0r
;savedD001_LazyYpos_39D:!byte 0 ; (uninited) ; DATA XREF: calcWhichRoom0to8_12A5+C0w
;     ; calcWhichRoom0to8_12A5+2F9r
;savedD004_foe0Xpos_39E:!byte 0 ; (uninited) ; DATA XREF: calcWhichRoom0to8_12A5+C6w
;     ; calcWhichRoom0to8_12A5+302r
;savedD005_foe0Ypos_39F:!byte 0 ; (uninited) ; DATA XREF: calcWhichRoom0to8_12A5+CCw
;     ; calcWhichRoom0to8_12A5+30Er
;savedD008_foe1Xpos_3A0:!byte 0 ; (uninited) ; DATA XREF: calcWhichRoom0to8_12A5+D2w
;     ; calcWhichRoom0to8_12A5+317r
;saveddD009_foe1Ypos_3A1:!byte 0  ; (uninited) ; DATA XREF: calcWhichRoom0to8_12A5+D8w
;     ; calcWhichRoom0to8_12A5+323r
;savedD00C_foeInvisibleManXpos_3A2:!byte  0 ; (uninited)
;     ; DATA XREF: calcWhichRoom0to8_12A5+DEw
;     ; calcWhichRoom0to8_12A5+32Cr
;savedD00D_foeInvisibleManYpos_3A3:!byte  0 ; (uninited)
;     ; DATA XREF: calcWhichRoom0to8_12A5+E4w
;     ; calcWhichRoom0to8_12A5+335r
;savedD00E_elevatorXpos_3A4:!byte 0 ; (uninited)  ; DATA XREF: calcWhichRoom0to8_12A5+EAw
;     ; calcWhichRoom0to8_12A5+33Br
;savedD00F_ElevatorYpos_3A5:!byte 0 ; (uninited)  ; DATA XREF: calcWhichRoom0to8_12A5+F0w
;     ; calcWhichRoom0to8_12A5+341r
;savedD010_3A6: !byte 0 ; (uninited)  ; DATA XREF: calcWhichRoom0to8_12A5+F6w
;     ; calcWhichRoom0to8_12A5+2EAr
;savedD027_gameSprCols:;  0 !byte uninited & unexplored
;   ; 0 !byte uninited & unexplored
;   ; 0 !byte uninited & unexplored
;   ; 0 !byte uninited & unexplored
;   ; 0 !byte uninited & unexplored
;   ; 0 !byte uninited & unexplored
;   ; 0 !byte uninited & unexplored
;   ; 0 !byte uninited & unexplored
;mainGameSpeed_3B7:!byte  0 ; (uninited)  ; DATA XREF: mainGameLoop_869-21w
;     ; makeGameSpeedFaster_102Br ...
;whichMenuScreenIsShown_3C0:!byte 0 ; (uninited)  ; DATA XREF: mainGameLoop_869-1Br
;     ; mainGameLoop_869+Fr ...
;waitCounterMSB_3C1:!byte 0 ; (uninited)  ; DATA XREF: mainGameLoop_869-Ew
;     ; mainGameLoop_869-8w ...
;waitCounterLSB_3C2:!byte 0 ; (uninited)  ; DATA XREF: lifeLostSequence+2Dw
;     ; lifeLostSequence:waitLoop4w ...
;musicEnabled_3E0:!byte 0 ; (uninited)  ; DATA XREF: titleMusicInit+2w
;     ; sub_59D0+6r ...
;musicLengthCou_3E1:!byte 0 ; (uninited)  ; DATA XREF: titleMusicInit+7w
;     ; ROM:5D8Bw ...
;   ; 0 !byte uninited & unexplored
;musicSpeedCou_3E3:!byte  0 ; (uninited)  ; DATA XREF: titleMusicInit+Cw
;     ; ROM:5D35w ...
;nextMusicPoiLSB_3E4:!byte 0 ; (uninited) ; DATA  XREF: titleMusicInit+11w
;     ; calcWhichRoom0to8_12A5+2ACw ...
;nextMusicPoiMSB_3E5:!byte 0 ; (uninited) ; DATA  XREF: titleMusicInit+18w
;     ; calcWhichRoom0to8_12A5+2B1w ...
;byte_4DA:  !byte 0 ; (uninited)  ; DATA XREF: Game0f_WipeOut_91B0+98w
;byte_556:  !byte 0 ; (uninited)  ; DATA XREF: Game0f_WipeOut_91B0+DAw
;numberOfStartingLivesOnScreen_5A9:!byte  0 ; (uninited)
;     ; DATA XREF: selectNumberOfLives_B53+46r
;     ; selectNumberOfLives_B53+4Dw ...
;byte_5C7:  !byte 0 ; (uninited)  ; DATA XREF: Game0f_WipeOut_91B0+DFw
;byte_5F2:  !byte 0 ; (uninited)  ; DATA XREF: Game0f_WipeOut_91B0+9Bw
;byte_65A:  !byte 0 ; (uninited)  ; DATA XREF: Game0f_WipeOut_91B0+65w
;byte_66F:  !byte 0 ; (uninited)  ; DATA XREF: Game0f_WipeOut_91B0+6Aw
;subgameScore0onScreen_689:!byte  0 ; (uninited) ; DATA XREF: sub_4FF8+2w
;subgameScore1onScreen_68A:!byte  0 ; (uninited) ; DATA XREF: increaseSubgameScore_54E0+23w
;subgameScore2onScreen_68B:!byte  0 ; (uninited) ; DATA XREF: increaseSubgameScore_54E0+2Cw
;subgameTime3onScreen_693:!byte 0 ; (uninited) ;  DATA XREF: decreaseSubgameTime_5510+1Bw
;subgameTime2onScreen_694:!byte 0 ; (uninited) ;  DATA XREF: decreaseSubgameTime_5510+23w
;subgameTime1onScreen_695:!byte 0 ; (uninited) ;  DATA XREF: decreaseSubgameTime_5510+31w
;subgameTime0onScreen_696:!byte 0 ; (uninited) ;  DATA XREF: decreaseSubgameTime_5510+3Aw
;playerScore0onScreen_7C8:!byte 0 ; (uninited) ;  DATA XREF: printScoreHiscoreLivesToScreen+Bw
;playerScore1onScreen_7C9:!byte 0 ; (uninited)
;     ; DATA XREF: printScoreHiscoreLivesToScreen+14w
;playerScore2onScreen_7CA:!byte 0 ; (uninited)
;     ; DATA XREF: printScoreHiscoreLivesToScreen+22w
;playerScore3onScreen_7CB:!byte 0 ; (uninited)
;     ; DATA XREF: printScoreHiscoreLivesToScreen+2Bw
;playerScore4onScreen_7CC:!byte 0 ; (uninited)
;     ; DATA XREF: printScoreHiscoreLivesToScreen+39w
;playerScore5onScreen_7CD:!byte 0 ; (uninited)
;     ; DATA XREF: printScoreHiscoreLivesToScreen+42w
;   ; 0 !byte uninited & unexplored
;cocktailScore0onScreen_7CF:!byte 0 ; (uninited)  ; DATA XREF: printCocktailScore_8B2F+17w
;cocktailScore1onScreen_7D0:!byte 0 ; (uninited)  ; DATA XREF: printCocktailScore_8B2F+25w
;cocktailScore2onScreen_7D1:!byte 0 ; (uninited)  ; DATA XREF: printCocktailScore_8B2F+2Ew
;playerNumberOfLivesOnScreen_7D8:!byte 0  ; (uninited)
;     ; DATA XREF: printScoreHiscoreLivesToScreen+90w
;cocktailTime0onScreen_7DC:!byte  0 ; (uninited) ; DATA XREF: printCocktailTime_8AFE+16w
;cocktailTime1onScreen_7DD:!byte  0 ; (uninited) ; DATA XREF: printCocktailTime_8AFE+24w
;cocktailTime2onScreen_7DE:!byte  0 ; (uninited) ; DATA XREF: printCocktailTime_8AFE+2Dw
;   ; 0 !byte uninited & unexplored
;hiScore0onScreen_7E0:!byte 0 ; (uninited) ; DATA XREF: printScoreHiscoreLivesToScreen+50w
;hiScore1onScreen_7E1:!byte 0 ; (uninited) ; DATA XREF: printScoreHiscoreLivesToScreen+59w
;hiScore2onScreen_7E2:!byte 0 ; (uninited) ; DATA XREF: printScoreHiscoreLivesToScreen+67w
;hiScore3onScreen_7E3:!byte 0 ; (uninited) ; DATA XREF: printScoreHiscoreLivesToScreen+70w
;hiScore4onScreen_7E4:!byte 0 ; (uninited) ; DATA XREF: printScoreHiscoreLivesToScreen+7Ew
;hiScore5onScreen_7E5:!byte 0 ; (uninited) ; DATA XREF: printScoreHiscoreLivesToScreen+87w
;sprite0poi_7F8:  !byte 0 ; (uninited)  ; DATA XREF: initMainGame+52w
;     ; sub_C1A+1Aw ...
;sprite1poi_7F9:  !byte 0 ; (uninited)  ; DATA XREF: initMainGame+57w
;     ; sub_C1A+1Fw ...
;sprite2poi_7FA:  !byte 0 ; (uninited)  ; DATA XREF: initMainGame+5Cw
;     ; moveMan_CDC:loc_D43r ...
;sprite3poi_7FB:  !byte 0 ; (uninited)  ; DATA XREF: initMainGame+61w
;     ; moveMan_CDC+7Cw ...
;sprite4poi_7FC:  !byte 0 ; (uninited)  ; DATA XREF: initMainGame+66w
;     ; moveDustvan_D7B:loc_DE2r ...
;sprite5poi_7FD:  !byte 0 ; (uninited)  ; DATA XREF: initMainGame+6Bw
;     ; sub_DFF+7w ...
;sprite6poi_7FE:  !byte 0 ; (uninited)  ; DATA XREF: initMainGame+70w
;     ; moveInvisibleMan_E15:loc_E79r ...
;sprite7poi_7FF:  !byte 0 ; (uninited)  ; DATA XREF: initMainGame+75w
;     ; Game0d_LazyNightmare_8B90+34w ...
;; end of 'RAM'






; ===========================================================================

; Segment type: Pure code

Main:
  sei
  lda #$35
  sta $01
syncite5:
  lda $d011
  bpl syncite5
syncite6:
  lda $d011
  bmi syncite6
  lda #$0b
  sta $d011
  lda #$c8
  sta $d016

  LDA #0
  STA playerScore2_360
  STA playerScore1_361
  STA playerScore0_362
  STA $D020
  STA $D021

!ifndef release {
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
}


;invert rotation anim:
;  ldx #0
;invmore:
;invpoi1:
;  lda $8000,x
;  eor #$ff
;invpoi2:
;  sta $8000,x
;  dex
;  bne invmore
;  inc invpoi1+2
;  inc invpoi2+2
;  lda invpoi2+2
;  cmp #$c0
;  bne invmore

;Fill the masking sprite:
  ldx #$3e
  lda #$ff
fill_mores:
  sta filled_sprite,x
  dex
  bpl fill_mores
  lda #(filled_sprite-$4000) / $40
  sta screen0+$3f8

  ldx #$3e
copy_heart:
  lda sprite_heart_4240,x
  sta sprite_heart,x
  dex
  bpl copy_heart


  ldx #0
jkd:
  lda PexGame_d800,x
  sta $d800,x
  lda PexGame_d800+$100,x
  sta $d900,x
  lda PexGame_d800+$200,x
  sta $da00,x
  lda PexGame_d800+$300,x
  sta $db00,x
;480 bytes that needs to be copied:
  lda screen_to_4478,x
  sta $4478,x
  lda screen_to_4478+$100,x
  sta $4478+$100,x
  inx
  bne jkd

  ldx #$7f
copy_more_charset:
  lda chars_4000_to_407f,x
  sta $4000,x
  lda chars_4100_to_417f,x
  sta $4100,x
  dex
  bpl copy_more_charset

;  LDA #$1D  ;Charset at $3000
  LDA #$13
  STA $D018
;Bank $0000-$3fff
  lda #3
  sta $dd00

  LDX #$18
clearAudioLoop:     ; CODE XREF: ROM:081Fj
  LDA #0
  STA $D400,X
  DEX
  BPL clearAudioLoop

  lda #$ff
  sta $d015
  lda #0
  sta $d017
  sta $d01d
  lda #$06
  sta $d025
  lda #$0e
  sta $d026
  lda #0
  sta $d027
  sta $d028
  sta $d029
  sta $d02a
  sta $d02b
  sta $d02c
  sta $d02d
  sta $d02e
  lda #$ff
  sta $d01c

syncite59:
  lda $d011
  bpl syncite59
syncite69:
  lda $d011
  bmi syncite69
  lda #$1b
  sta $d011

  LDA #0
  STA hiScore2_363
  STA hiScore1_364
  STA hiScore0_365
  jsr irqInit

  lda #$80
  STA musicPatternLength+1
  JSR titleMusicInit

PexRoom:
  LDA #<musicDataStarDust_1780 ;$80 ; 'Ä'
  STA nextMusicPoiLSB_3E4
  LDA #>musicDataStarDust_1780 ;$17
  STA nextMusicPoiMSB_3E5
  LDA #0
  STA $D01D
  STA $D017
  LDA #0
  STA $D010
  LDX #0
  TXA
loc_69FF:     ; CODE XREF: Game01_StarDust_69E0+25j
  STA $D000,X
  INX
  CPX #$10
  BNE loc_69FF

  JSR lazyWalkingIntoSubgameRoom_5620
;  JSR printGetReady_56E0
  LDA #0
  STA $D010

  LDA #$0
  STA $D01B
  LDA #7
  STA $D029
  STA $D02A
  LDA #8
  STA $D02B
  LDA #2
  STA $D025
  LDA #$E
  STA $D026
  LDA $D01E
  LDA $D01E

;  LDA #spriteStardustFire_2F40 / $40 ;$BD ; 'Ω'
;  STA sprite3poi_7FB
;  LDA #spriteStardustBoulder0_2F80 / $40 ;$BE ; 'æ'
;  STA sprite4poi_7FC
  LDA #$1F
  STA currentJoystickPos_33C
  LDA #0
  STA subgameScore0_33D
  STA subgameScore1_33E
  LDA #$00 ; 'ô'
  STA subgameTimeLSB_33F
  LDA #$06 ; 'ô'
  STA subgameTimeMSB_340
  LDA #0
  STA byte_341
  LDA #0
  STA byte_343
  LDA #0
  STA byte_344
  LDA #0
  STA byte_345





PexRoom_Ever:
loc_6AC4:     ; CODE XREF: Game01_StarDust_69E0:loc_6B60j
  jsr waitAWhilePex
  jsr waitAWhilePex

;  JSR increaseSubgameScore_54E0

loc_6B17:     ; CODE XREF: Game01_StarDust_69E0+12Dj
  JSR decreaseSubgameTime_5510
  LDA subgameTimeLSB_33F
  beq perhaps_end


loc_6B43:     ; CODE XREF: Game01_StarDust_69E0+148j
  INC byte_345
  LDA byte_345
  CMP #$20 ; ' '
  BNE loc_6B60
  LDA #0
  STA byte_345
  LDA lazy_sprx+1
  EOR #2
  STA lazy_sprx+1

loc_6B60:     ; CODE XREF: Game01_StarDust_69E0+16Ej
  JMP PexRoom_Ever
; End of function Game01_StarDust_69E0

perhaps_end:
  LDA subgameTimeMSB_340
  BNE PexRoom_Ever

;Yes, we're done. time is 0000:
  LDA #3
  STA $D015

  lda #1
  sta switch_to_music_only_irq+1
  JSR printGameOverText


  LDA #0
  STA $D010
  LDA #0
  STA $D01C
  STA $D017
  STA $D01D
  LDA #$1F
  STA $D418
  LDA #0
  STA $D01B
  LDA #4
  STA $D413
  LDA #3
  STA $D40F
  LDA #3
  STA $D015
  LDA #spriteLazyJonesRightLight0_3440 / $40 ;$D1 ; '—'
  STA sprite0poi_7F8
  LDA #spriteLazyJonesRightDark0_3480 / $40 ;$D2 ; '“'
  STA sprite1poi_7F9

  lda #1
  sta let_jones_start_walking+1

!ifndef release {
flis:
  jmp flis
}

!ifdef release {

;Done. Let's load the bootcode from diskside #2:
  jsr link_load_next_raw
;And we don't want to jump into the bootcode.

  ;load overload part $a000-$cfff
  jsr link_load_next_comp

  ;load overload part $e000-$fxxx (=sprite mats)
  jsr link_load_next_comp

  ;load overload part $0400-$5000 to $7000
  jsr link_load_next_raw


  lda #2
still_walking:
  cmp let_jones_start_walking+1
  bne still_walking
  sei
  JSR sub_5810   ;Scroll screen contents to the left.

  lda #$0b
  sta $d011

  ldx #$40
copy_load_code:
  lda load_code,x
  sta $0100,x
  dex
  bpl copy_load_code
  jmp $0100

load_code:
  ;decrunch the last part, loaded at $7000, depacks to $0400-$5000:
  ;!macro set_depack_pointers $7000
  lda #<$7000
  sta bitfire_load_addr_lo
  lda #>$7000
  sta bitfire_load_addr_hi
  jsr link_decomp
  jmp link_exit


}







;freeze:
;  inc $d020
;  jmp freeze

; ---------------------------------------------------------------------------










printGameOverText:
  LDA #$C
  STA $D413
  LDA #$20 ; ' '
  STA $D412
  LDA #$21 ; '!'
  STA $D412
  LDA #$20 ; ' '
  STA byte_FC

loc_57E3:     ; CODE XREF: printGameOverText+2Aj
  LDA byte_FC
  AND #7
  STA currentPrintCharColour_286
  STA $D40F

  ldx #8
more_game_over:
  lda game_over_text,x
  sta $0400 + 9*40 + 8,x
  lda currentPrintCharColour_286
  sta $d800 + 9*40 + 8,x
  dex
  bpl more_game_over

  ldy #$30
  ldx #0
wajjt:
  dex
  bne wajjt
  dey
  bne wajjt

  DEC byte_FC
  BNE loc_57E3

;Erase game over text:
  ldx #8
more_game_over2:
  lda #$20
  sta $0400 + 9*40 + 8,x
  dex
  bpl more_game_over2
;  DEC byte_FC
;  BNE loc_57E3
  RTS



game_over_text:
  !scr "game over"








waitAWhile:     ; CODE XREF: mainGameLoop_869+3p
      ; calcWhichRoom0to8_12A5+1AEp ...
;  LDA mainGameSpeed_3B7

  ldy #5
  ldx #0
waj:
  dex
  bne waj
  dey
  bne waj
  rts

print_char_FFD2 = $F1CA
;  jsr $F1CA
;  rts



titleMusicInit:     ; CODE XREF: mainGameLoop_869-29p
  LDA #$0
  STA musicLengthCou_3E1
  LDA #$C
  STA musicSpeedCou_3E3
  LDX #<musicDataTitle_1C00 ;0
  STX nextMusicPoiLSB_3E4
  stx curMusPoi0+1
  inx
  stx curMusPoi1+1
  inx
  stx curMusPoi2+1
  inx
  stx curMusPoi3+1
  LDA #>musicDataTitle_1C00 ;$1C
  STA nextMusicPoiMSB_3E5
  sta curMusPoi0+2
  sta curMusPoi1+2
  sta curMusPoi2+2
  sta curMusPoi3+2
  LDA #$FF
  STA $D416
  LDA #3
  STA $D417
  rts
;   JSR musicInit
;   RTS
; End of function titleMusicInit




; =============== S U B R O U T I N E =======================================


sub_4FF8:     ; CODE XREF: increaseSubgameScore_54E0+15p
  ADC #$30 ; '0'
  STA subgameScore0onScreen_689
  RTS
; End of function sub_4FF8

; ---------------------------------------------------------------------------
  !byte 0
  !byte 0

; =============== S U B R O U T I N E =======================================


scrollCharsToTheLeft:   ; CODE XREF: scrollScreenToTheLeft:loc_EF8p
      ; calcWhichRoom0to8_12A5:loc_1565p
  LDA #$A0 ; '†'
  STA byte_FA
  STA byte_FD
  LDA #4
  STA byte_FB
  LDA #$D8 ; 'ÿ'
  STA byte_FE
  LDX #$12

loc_5010:     ; CODE XREF: scrollCharsToTheLeft+43j
  LDY #0
  LDA (byte_FA),Y
  STA byte_FC
  LDA (byte_FD),Y
  STA byte_FF

loc_501A:     ; CODE XREF: scrollCharsToTheLeft+29j
  INY
  LDA (byte_FA),Y
  DEY
  STA (byte_FA),Y
  INY
  LDA (byte_FD),Y
  DEY
  STA (byte_FD),Y
  INY
  CPY #$27 ; '''
  BNE loc_501A
  LDA byte_FC
  STA (byte_FA),Y
  LDA byte_FF
  STA (byte_FD),Y
  CLC
  LDA byte_FA
  ADC #$28 ; '('
  STA byte_FA
  STA byte_FD
  BCC loc_5042
  INC byte_FB
  INC byte_FE

loc_5042:     ; CODE XREF: scrollCharsToTheLeft+3Cj
  DEX
  BNE loc_5010
  RTS
; End of function scrollCharsToTheLeft

scrollCharsToTheRight:    ; CODE XREF: scrollScreenToTheRight:loc_F6Ep
      ; calcWhichRoom0to8_12A5:loc_1579p
  LDA #$A0 ; '†'
  STA byte_FA
  STA byte_FD
  LDA #4
  STA byte_FB
  LDA #$D8 ; 'ÿ'
  STA byte_FE
  LDX #$12

loc_5060:     ; CODE XREF: scrollCharsToTheRight+41j
  LDY #$27 ; '''
  LDA (byte_FA),Y
  STA byte_FC
  LDA (byte_FD),Y
  STA byte_FF

loc_506A:     ; CODE XREF: scrollCharsToTheRight+27j
  DEY
  LDA (byte_FA),Y
  INY
  STA (byte_FA),Y
  DEY
  LDA (byte_FD),Y
  INY
  STA (byte_FD),Y
  DEY
  BNE loc_506A
  LDA byte_FC
  STA (byte_FA),Y
  LDA byte_FF
  STA (byte_FD),Y
  CLC
  LDA byte_FA
  ADC #$28 ; '('
  STA byte_FA
  STA byte_FD
  BCC loc_5090
  INC byte_FB
  INC byte_FE

loc_5090:     ; CODE XREF: scrollCharsToTheRight+3Aj
  DEX
  BNE loc_5060
  RTS
; End of function scrollCharsToTheRight

animateLazyJones_50A0:    ; CODE XREF: lazyWalkingOutOfSubgameRoom_5760+50p
  LDX sprite0poi_7F8
  INX
  INX
  CPX #(spriteLazyJonesRightLight3_3600 / $40) + 1 ;$D9 ; 'Ÿ'
  BNE loc_50AB
  LDX #spriteLazyJonesRightLight0_3440 / $40 ;$D1 ; '—'

loc_50AB:     ; CODE XREF: animateLazyJones_50A0+7j
  STX sprite0poi_7F8
  INX
  STX sprite1poi_7F9
  RTS
; End of function animateLazyJones_50A0

animateLazyJones_50B8:    ; CODE XREF: lazyWalkingIntoSubgameRoom_5620+6Ap
  LDX sprite0poi_7F8
  INX
  INX
  CPX #(spriteLazyJonesLeftLight3_3800 / $40) + 1 ;$E1 ; '·'
  BNE loc_50C3
  LDX #spriteLazyJonesLeftDark0_3640 / $40 ;$D9 ; 'Ÿ'

loc_50C3:     ; CODE XREF: animateLazyJones_50B8+7j
  STX sprite0poi_7F8
  INX
  STX sprite1poi_7F9
  RTS
; End of function animateLazyJones_50B8

sub_5140:     ; CODE XREF: animateDoorsMaybe_10F2+7Dp
  LDY #0
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$53 ; 'S'
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  INY
  LDA #$59 ; 'Y'
  JSR sub_5208
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$55 ; 'U'
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$58 ; 'X'
  STA (byte_FA),Y
  RTS
; End of function sub_5140


; =============== S U B R O U T I N E =======================================


sub_5170:     ; CODE XREF: animateDoorsMaybe_10F2+87p
  LDY #0
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$54 ; 'T'
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$57 ; 'W'
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  JSR sub_5208
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$54 ; 'T'
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$57 ; 'W'
  STA (byte_FA),Y
  RTS
; End of function sub_5170


; =============== S U B R O U T I N E =======================================


sub_51A0:     ; CODE XREF: animateDoorsMaybe_10F2+91p
  LDY #0
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$55 ; 'U'
  STA (byte_FA),Y
  INY
  LDA #$53 ; 'S'
  JSR sub_5200
  LDA #$5A ; 'Z'
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  JSR sub_5208
  INY
  LDA #$58 ; 'X'
  JSR sub_5200
  LDA #$5A ; 'Z'
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  RTS
; End of function sub_51A0


; =============== S U B R O U T I N E =======================================


sub_51D0:     ; CODE XREF: animateDoorsMaybe_10F2+9Bp
  LDY #0
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$20 ; ' '
  STA (byte_FA),Y
  INY
  LDA #$54 ; 'T'
  JSR sub_5200
  LDA #$54 ; 'T'
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  JSR sub_5208
  INY
  LDA #$57 ; 'W'
  JSR sub_5200
  LDA #$57 ; 'W'
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$20 ; ' '
  STA (byte_FA),Y
  RTS
; End of function sub_51D0


; =============== S U B R O U T I N E =======================================


sub_5200:     ; CODE XREF: sub_5140+4p sub_5140+Ep ...
  STA (byte_F8),Y
  STA (byte_FC),Y
  STA (byte_FE),Y
  RTS
; End of function sub_5200

sub_5208:     ; CODE XREF: sub_5140+18p sub_5170+18p ...
  STA (byte_F8),Y
  STA (byte_FA),Y
  STA (byte_FC),Y
  STA (byte_FE),Y
  RTS
; End of function sub_5208

sub_5220:     ; CODE XREF: animateDoorsMaybe_10F2+A5p
  LDY #0
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  INY
  LDA #$55 ; 'U'
  JSR sub_5200
  LDA #$55 ; 'U'
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  JSR sub_5208
  INY
  LDA #$56 ; 'V'
  JSR sub_5200
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$55 ; 'U'
  STA (byte_FA),Y
  RTS
; End of function sub_5220


; =============== S U B R O U T I N E =======================================


sub_5250:     ; CODE XREF: animateDoorsMaybe_10F2+AFp
  LDY #0
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$57 ; 'W'
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  LDA #$5B ; '['
  JSR sub_5200
  LDA #$54 ; 'T'
  STA (byte_FA),Y
  RTS
; End of function sub_5250


; =============== S U B R O U T I N E =======================================


sub_5274:     ; CODE XREF: animateDoorsMaybe_10F2+B9p
  LDY #0
  LDA #$53 ; 'S'
  JSR sub_5200
  LDA #$5A ; 'Z'
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  LDA #$58 ; 'X'
  JSR sub_5200
  LDA #$5A ; 'Z'
  STA (byte_FA),Y
  RTS
; End of function sub_5274


; =============== S U B R O U T I N E =======================================


sub_5298:     ; CODE XREF: animateDoorsMaybe_10F2+C3p
  LDY #0
  LDA #$54 ; 'T'
  JSR sub_5208
  INY
  LDA #$20 ; ' '
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  LDA #$57 ; 'W'
  JMP sub_5208
;   JSR sub_5208
;   RTS
; End of function sub_5298


; =============== S U B R O U T I N E =======================================


sub_52B4:     ; CODE XREF: animateDoorsMaybe_10F2+CDp
  LDY #0
  LDA #$55 ; 'U'
  JSR sub_5208
  INY
  LDA #$20 ; ' '
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  LDA #$56 ; 'V'
  JMP sub_5208
;   JSR sub_5208
;   RTS
; End of function sub_52B4


; =============== S U B R O U T I N E =======================================


sub_52D0:     ; CODE XREF: animateDoorsMaybe_10F2+D7p
  LDY #0
  LDA #$20 ; ' '
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  JSR sub_5208
  INY
  JMP sub_5208
;   JSR sub_5208
;   RTS
; End of function sub_52D0


; =============== S U B R O U T I N E =======================================


sub_52E8:     ; CODE XREF: animateDoorsMaybe_10F2+ECp
  LDY #0
  LDA #$5B ; '['
  JSR sub_5208
  INY
  JSR sub_5200
  LDA #$20 ; ' '
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  JSR sub_5208
  INY
  JSR sub_5200
  LDA #$20 ; ' '
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  JMP sub_5208
;   JSR sub_5208
;   RTS
; End of function sub_52E8

sub_5310:     ; CODE XREF: cleanUpMemoryMovement_5410+49p
  LDY #0
  LDA #$1B
  STA (byte_FA),Y
  INY
  LDA #$1C
  STA (byte_FA),Y
  INY
  LDA #$1D
  STA (byte_FA),Y
  LDY #$28 ; '('
  LDA #$1E
  STA (byte_FA),Y
  INY
  LDA #$21 ; '!'
  STA (byte_FA),Y
  INY
  LDA #$1F
  STA (byte_FA),Y
  LDY #$50 ; 'P'
  LDA #$1E
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  STA (byte_FA),Y
  INY
  LDA #$1F
  STA (byte_FA),Y
  RTS
; End of function sub_5310

sub_5342:     ; CODE XREF: cleanUpMemoryMovement_5410:loc_5421p
  LDY #0
  LDA #$1B
  STA (byte_FA),Y
  INY
  LDA #$1C
  STA (byte_FA),Y
  INY
  LDA #$3D ; '='
  STA (byte_FA),Y
  LDY #$28 ; '('
  LDA #$1E
  STA (byte_FA),Y
  INY
  LDA #$21 ; '!'
  STA (byte_FA),Y
  INY
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  LDY #$50 ; 'P'
  LDA #$1E
  STA (byte_FA),Y
  INY
  LDA #$5B ; '['
  STA (byte_FA),Y
  INY
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  RTS
; End of function sub_5342

sub_5374:     ; CODE XREF: cleanUpMemoryMovement_5410:loc_542Bp
  LDY #0
  LDA #$1B
  STA (byte_FA),Y
  INY
  LDA #$3B ; ';'
  STA (byte_FA),Y
  INY
  LDA #$3D ; '='
  STA (byte_FA),Y
  LDY #$28 ; '('
  LDA #$1E
  STA (byte_FA),Y
  INY
  LDA #$54 ; 'T'
  STA (byte_FA),Y
  INY
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  LDY #$50 ; 'P'
  LDA #$1E
  STA (byte_FA),Y
  INY
  LDA #$54 ; 'T'
  STA (byte_FA),Y
  INY
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  RTS
; End of function sub_5374

sub_53A6:     ; CODE XREF: cleanUpMemoryMovement_5410:loc_5435p
  LDY #0
  LDA #$1B
  STA (byte_FA),Y
  INY
  LDA #$3C ; '<'
  STA (byte_FA),Y
  INY
  LDA #$3D ; '='
  STA (byte_FA),Y
  LDY #$28 ; '('
  LDA #$1E
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  STA (byte_FA),Y
  INY
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  LDY #$50 ; 'P'
  LDA #$1E
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  STA (byte_FA),Y
  INY
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  RTS
; End of function sub_53A6

sub_53D8:     ; CODE XREF: cleanUpMemoryMovement_5410+2Fp
  LDY #0
  LDA #$3A ; ':'
  STA (byte_FA),Y
  INY
  LDA #$3C ; '<'
  STA (byte_FA),Y
  INY
  LDA #$3D ; '='
  STA (byte_FA),Y
  LDY #$28 ; '('
  LDA #$55 ; 'U'
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  STA (byte_FA),Y
  INY
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  LDY #$50 ; 'P'
  LDA #$55 ; 'U'
  STA (byte_FA),Y
  INY
  LDA #$20 ; ' '
  STA (byte_FA),Y
  INY
  LDA #$56 ; 'V'
  STA (byte_FA),Y
  RTS
; End of function sub_53D8

byte_540C:  !byte $E3   ; DATA XREF: calcWhichRoom0to8_12A5:loc_1442w
      ; cleanUpMemoryMovement_5410r
byte_540D:  !byte 5   ; DATA XREF: calcWhichRoom0to8_12A5+1A0w
      ; cleanUpMemoryMovement_5410+5r
byte_540E:  !byte 0   ; DATA XREF: calcWhichRoom0to8_12A5+1A5w
      ; calcWhichRoom0to8_12A5+1C8r ...
byte_540F:  !byte 0   ; DATA XREF: calcWhichRoom0to8_12A5+1A8w
      ; calcWhichRoom0to8_12A5+36Fw ...

; =============== S U B R O U T I N E =======================================


cleanUpMemoryMovement_5410:   ; CODE XREF: calcWhichRoom0to8_12A5:loc_1450p
      ; calcWhichRoom0to8_12A5:loc_1617p
  LDA byte_540C
  STA byte_FA
  LDA byte_540D
  STA byte_FB
  LDA byte_540F
  CMP #1
  BNE loc_5427

loc_5421:     ; CODE XREF: cleanUpMemoryMovement_5410+47j
  JSR sub_5342
  JMP loc_5460
; ---------------------------------------------------------------------------

loc_5427:     ; CODE XREF: cleanUpMemoryMovement_5410+Fj
  CMP #2
  BNE loc_5431

loc_542B:     ; CODE XREF: cleanUpMemoryMovement_5410+43j
  JSR sub_5374
  JMP loc_5460
; ---------------------------------------------------------------------------

loc_5431:     ; CODE XREF: cleanUpMemoryMovement_5410+19j
  CMP #3
  BNE loc_543B

loc_5435:     ; CODE XREF: cleanUpMemoryMovement_5410+3Fj
  JSR sub_53A6
  JMP loc_5460
; ---------------------------------------------------------------------------

loc_543B:     ; CODE XREF: cleanUpMemoryMovement_5410+23j
  CMP #4
  BNE loc_544D
  JSR sub_53D8
  LDA $D01B
  EOR #3
  STA $D01B
  JMP loc_5460
; ---------------------------------------------------------------------------

loc_544D:     ; CODE XREF: cleanUpMemoryMovement_5410+2Dj
  CMP #5
  BEQ loc_5435
  CMP #6
  BEQ loc_542B
  CMP #7
  BEQ loc_5421
  JSR sub_5310
  NOP
  NOP
  NOP
  NOP

loc_5460:     ; CODE XREF: cleanUpMemoryMovement_5410+14j
      ; cleanUpMemoryMovement_5410+1Ej ...
  INC byte_540F
  LDA byte_540F
  CMP #9
  BNE locret_5472
  LDA #0
  STA byte_540E
  STA byte_540F

locret_5472:    ; CODE XREF: cleanUpMemoryMovement_5410+58j
  RTS
; End of function cleanUpMemoryMovement_5410

grabJoystickPos:    ; CODE XREF: mainGameLoop_869p
      ; selectNumberOfLives_B53:loc_B6Cp ...
  SEI
  LDA $DC00
  AND $DC01
  CLI
  AND #$1F
  STA currentJoystickPos_33C
  CMP #$1F
  BNE locret_54D6
  LDA byte_C5
  TAY
  CMP #$36 ; '6'
  BNE loc_54A0
  LDA currentJoystickPos_33C
  AND #$1E
  STA currentJoystickPos_33C

loc_54A0:     ; CODE XREF: grabJoystickPos+16j
  TYA
  CMP #$35 ; '5'
  BNE loc_54AD
  LDA currentJoystickPos_33C
  AND #$1D
  STA currentJoystickPos_33C

loc_54AD:     ; CODE XREF: grabJoystickPos+23j
  TYA
  CMP #1
  BNE loc_54BA
  LDA currentJoystickPos_33C
  AND #$F
  STA currentJoystickPos_33C

loc_54BA:     ; CODE XREF: grabJoystickPos+30j
  LDA byte_28D
  CMP #1
  BNE loc_54CA
  LDA currentJoystickPos_33C
  AND #$17
  STA currentJoystickPos_33C
  RTS
; ---------------------------------------------------------------------------

loc_54CA:     ; CODE XREF: grabJoystickPos+3Fj
  CMP #2
  BNE locret_54D6
  LDA currentJoystickPos_33C
  AND #$1B
  STA currentJoystickPos_33C

locret_54D6:    ; CODE XREF: grabJoystickPos+Fj
      ; grabJoystickPos+4Cj
  RTS
; End of function grabJoystickPos

increaseSubgameScore_54E0:  ; CODE XREF: sub_68C7:loc_68F6p
      ; sub_6C46+11p ...
  SED
  LDA subgameScore0_33D
  CLC

incSubgameScore_54E5:   ; DATA XREF: Game0a_TheWall_84D0+A1w
      ; Game0a_TheWall_84D0+152w ...
  ADC #$10
  STA subgameScore0_33D
  LDA subgameScore1_33E
  ADC #0
  STA subgameScore1_33E
  CLD
  AND #$F
  JSR sub_4FF8
  LDA subgameScore0_33D
  TAY
  LSR
  LSR
  LSR
  LSR
  CLC
  ADC #$30 ; '0'
  STA subgameScore1onScreen_68A
  TYA
  AND #$F
  CLC
  ADC #$30 ; '0'
  STA subgameScore2onScreen_68B
  RTS
; End of function increaseSubgameScore_54E0


; =============== S U B R O U T I N E =======================================


decreaseSubgameTime_5510:   ; CODE XREF: Game00_99redBalloons_6410:loc_659Fp
      ; Game01_StarDust_69E0+142p ...
  SED
  LDA subgameTimeLSB_33F
  SEC

loc_5515:     ; DATA XREF: Game0e_EggieChuck_8CE0+Aw
      ; Game0e_EggieChuck_8CE0+14Cw ...
  SBC #3
  STA subgameTimeLSB_33F
  LDA subgameTimeMSB_340
  SBC #0
  STA subgameTimeMSB_340
  CLD
  TAY
  LSR
  LSR
  LSR
  LSR
  CLC
  ADC #$30 ; '0'
  STA subgameTime3onScreen_693
  TYA
  AND #$F
  ADC #$30 ; '0'
  STA subgameTime2onScreen_694
  LDA subgameTimeLSB_33F
  TAY
  LSR
  LSR
  LSR
  LSR
  CLC
  ADC #$30 ; '0'
  STA subgameTime1onScreen_695
  TYA
  AND #$F
  CLC
  ADC #$30 ; '0'
  STA subgameTime0onScreen_696
  RTS
; End of function decreaseSubgameTime_5510

printTextAtFA:    ; CODE XREF: initMainGame+8p
      ; selectNumberOfLives_B53+Dp ...
  LDY #0

moreText_5552:    ; CODE XREF: printTextAtFA+Aj
      ; printTextAtFA+Ej
  LDA (byte_FA),Y
  BEQ textDone_5560
  JSR print_char_FFD2
  INY
  BNE moreText_5552
  INC byte_FB
  BNE moreText_5552

textDone_5560:    ; CODE XREF: printTextAtFA+4j
  RTS
; End of function printTextAtFA

sub_5570:     ; CODE XREF: Game01_StarDust_69E0+134p
      ; sub_6C46:loc_6C88p ...
  LDX #0

loc_5572:     ; CODE XREF: sub_5570+Bj
  LDA screenMem+$233,X
  STA byte_2B0,X
  INX
  CPX #$14
  BNE loc_5572
  LDX #0

loc_557F:     ; CODE XREF: sub_5570+18j
  LDA screenMem+$20B,X
  STA screenMem+$233,X
  INX
  CPX #$14
  BNE loc_557F
  LDX #0

loc_558C:     ; CODE XREF: sub_5570+25j
  LDA screenMem+$1E3,X
  STA screenMem+$20B,X
  INX
  CPX #$14
  BNE loc_558C
  LDX #0

loc_5599:     ; CODE XREF: sub_5570+32j
  LDA screenMem+$1BB,X
  STA screenMem+$1E3,X
  INX
  CPX #$14
  BNE loc_5599
  LDX #0

loc_55A6:     ; CODE XREF: sub_5570+3Fj
  LDA screenMem+$193,X
  STA screenMem+$1BB,X
  INX
  CPX #$14
  BNE loc_55A6
  LDX #0

loc_55B3:     ; CODE XREF: sub_5570+4Cj
  LDA screenMem+$16B,X
  STA screenMem+$193,X
  INX
  CPX #$14
  BNE loc_55B3
  LDX #0

loc_55C0:     ; CODE XREF: sub_5570+59j
  LDA screenMem+$143,X
  STA screenMem+$16B,X
  INX
  CPX #$14
  BNE loc_55C0
  LDX #0

loc_55CD:     ; CODE XREF: sub_5570+66j
  LDA screenMem+$11B,X
  STA screenMem+$143,X
  INX
  CPX #$14
  BNE loc_55CD
  LDX #0

loc_55DA:     ; CODE XREF: sub_5570+73j
  LDA screenMem+$F3,X
  STA screenMem+$11B,X
  INX
  CPX #$14
  BNE loc_55DA
  LDX #0

loc_55E7:     ; CODE XREF: sub_5570+80j
  LDA screenMem+$CB,X
  STA screenMem+$F3,X
  INX
  CPX #$14
  BNE loc_55E7
  LDX #0

loc_55F4:     ; CODE XREF: sub_5570+8Dj
  LDA screenMem+$A3,X
  STA screenMem+$CB,X
  INX
  CPX #$14
  BNE loc_55F4
  LDX #0

loc_5601:     ; CODE XREF: sub_5570+9Aj
  LDA screenMem+$7B,X
  STA screenMem+$A3,X
  INX
  CPX #$14
  BNE loc_5601
  LDX #0

loc_560E:     ; CODE XREF: sub_5570+A7j
  LDA byte_2B0,X
  STA screenMem+$7B,X
  INX
  CPX #$14
  BNE loc_560E
  RTS
; End of function sub_5570



lazyWalkingIntoSubgameRoom_5620:   ; CODE XREF: Game00_99redBalloons_6410+30p
      ; Game01_StarDust_69E0+4Dp ...
;  LDA #$1F
;  STA $D418
  LDA #0
  STA $D01B
  STA $D017
  STA $D01D
;  LDA #4
;  STA $D413
;  LDA #3
;  STA $D40F

loc_5644:     ; DATA XREF: Game0d_LazyNightmare_8B90+3Ew
      ; Game0d_LazyNightmare_8B90+F0w
  LDA #3
  STA $D015
;  LDA #$FF
;  STA $D000
;  STA $D002
  LDA #$DC ; '‹'
  STA $D001
  STA $D003
  LDA #spriteLazyJonesLeftDark0_3640 / $40 ;$D9 ; 'Ÿ'
  STA sprite0poi_7F8
  LDA #spriteLazyJonesLeftLight0_3680 / $40 ;$DA ; '⁄'
  STA sprite1poi_7F9
  LDA #9
  STA $D027
  LDA #$A
  STA $D028
  lda #$96 ; 'ñ'
  sta $d000
  sta $d002
  LDA #spriteLazyJonesLeftDark2_3740 / $40 ;$DD ; '›'
  STA sprite0poi_7F8
  LDA #spriteLazyJonesLeftLight2_3780 / $40 ;$DE ; 'ﬁ'
  STA sprite1poi_7F9
  RTS
; End of function lazyWalkingIntoSubgameRoom_5620

; ---------------------------------------------------------------------------


;printGetReady_56E0:   ; CODE XREF: Game00_99redBalloons_6410+33p
;      ; Game01_StarDust_69E0+50p ...
;  LDA #$C
;  STA $D413
;  LDA #$20 ; ' '
;  STA $D412
;  LDA #$21 ; '!'
;  STA $D412
;  LDA #0
;  STA byte_FC
;
;getReadyLoop_56F3:    ; CODE XREF: printGetReady_56E0+32j
;  LDA byte_FC
;  AND #$F
;  STA currentPrintCharColour_286
;  STA $D40F
;  LDA #<textGetReady_49E8 ;$E8 ; 'Ë'    ; text "Get ready"
;  STA byte_FA
;  LDA #>textGetReady_49E8 ;$49 ; 'I'
;  STA byte_FB
;  JSR printTextAtFA
;  LDA #0
;  STA byte_FD
;
;getReadyWaitLoop_570C:    ; CODE XREF: printGetReady_56E0+2Ej
;  DEC byte_FD
;  BNE getReadyWaitLoop_570C
;  INC byte_FC
;  BNE getReadyLoop_56F3
;  LDA #<textErasingGetReadyAndGameOver_4A08 ;8  ; erasing "Get ready"
;  STA byte_FA
;  LDA #>textErasingGetReadyAndGameOver_4A08 ;$4A ; 'J'
;  STA byte_FB
;  JSR printTextAtFA
;  RTS
;; End of function printGetReady_56E0


; =============== S U B R O U T I N E =======================================


lazyWalkingOutOfSubgameRoom_5760:     ; CODE XREF: Game00_99redBalloons_6410+1A4p
      ; Game01_StarDust_69E0+157p ...
  LDA #0
  STA $D010
  LDA #0
  STA $D01C
  STA $D017
  STA $D01D
  LDA #$1F
  STA $D418
  LDA #0
  STA $D01B
  LDA #4
  STA $D413
  LDA #3
  STA $D40F

loc_5784:     ; DATA XREF: Game0d_LazyNightmare_8B90+41w
      ; Game0d_LazyNightmare_8B90+F3w
  LDA #3
  STA $D015
  LDA #spriteLazyJonesRightLight0_3440 / $40 ;$D1 ; '—'
  STA sprite0poi_7F8
  LDA #spriteLazyJonesRightDark0_3480 / $40 ;$D2 ; '“'
  STA sprite1poi_7F9

loc_5793:
  jsr waitAWhilePex
  jsr waitAWhilePex

  INC $D000
  INC $D002
  LDA $D000
  AND #1
  BEQ loc_57B3
  JSR animateLazyJones_50A0

loc_57B3:     ; CODE XREF: lazyWalkingOutOfSubgameRoom_5760+4Ej
  LDA sprite0poi_7F8
  CMP #spriteLazyJonesRightLight2_3540 / $40 ;$D5 ; '’'
  BNE loc_57C4
  LDA #$80 ; 'Ä'
  STA $D412
  LDA #$81 ; 'Å'
  STA $D412

loc_57C4:     ; CODE XREF: lazyWalkingOutOfSubgameRoom_5760+58j
  LDA $D000
  CMP #$FF
  BNE loc_5793
  RTS
; End of function lazyWalkingOutOfSubgameRoom_5760


sub_5810:     ; CODE XREF: calcWhichRoom0to8_12A5+1D4p
      ; Game00_99redBalloons_6410+1ACp ...
  LDA #$28 ; '('
  STA byte_FD

loc_5814:     ; CODE XREF: sub_5810+2Fj
  LDA #0
  LDX #$19
  STA byte_FB
  LDA #4
  STA byte_FC

loc_581E:     ; CODE XREF: sub_5810+2Bj
  LDY #0

loc_5820:     ; CODE XREF: sub_5810+1Dj
  INY
  LDA (byte_FB),Y
  DEY
  STA (byte_FB),Y
  INY
  LDA #$20 ; ' '
  STA (byte_FB),Y
  CPY #$27 ; '''
  BNE loc_5820
  LDA byte_FB
  CLC
  ADC #$28 ; '('
  STA byte_FB
  BCC loc_583A
  INC byte_FC

loc_583A:     ; CODE XREF: sub_5810+26j
  DEX
  BNE loc_581E
  DEC byte_FD
  BNE loc_5814
  RTS
; End of function sub_5810


waitAWhileMainGame:
  jsr waitAWhile
  LDA mainGameSpeed_3B7   ;#$c to start with, and then counting downwards.
  asl
  asl
  asl
  clc
  adc #$20          ;$c -> $a0
                    ;$0 -> $20
currSpeedLSB3:
  adc #0
  sta currSpeedLSB3+1
  bcc noExtraWait3
  JSR waitAWhile
noExtraWait3:
  rts


; =============== S U B R O U T I N E =======================================


playAudioFx_Toilet_59B0:  ; CODE XREF: mainGameLoop_869:moreAudioFxLoop_85Ep
      ; Game06_Toilet_7A90:loc_7ABFp ...
  LDA #8
  STA $D413
  LDA #$10
  STA $D412
  LDA #$11
  STA $D412
  LDX #0

loc_59C1:     ; CODE XREF: playAudioFx_Toilet_59B0+1Aj
  STX $D40F
  LDY #$40 ; '@'

loc_59C6:     ; CODE XREF: playAudioFx_Toilet_59B0+17j
  DEY
  BNE loc_59C6
  DEX
  BNE loc_59C1
  RTS
; End of function playAudioFx_Toilet_59B0

; ---------------------------------------------------------------------------

musicPlay:
  DEC musicSpeedCou_3E3
  BNE noMusic
  LDA #$A                    ;With CIA irq, this value was "$C", but with raster IRQ, $A is more like it.
; Music. CIA-irq used wait = $0c.   Raster-irq set to $0a. Correct?
;   CIA=60Hz. Raster = 50Hz.    12 / 60 * 50 = 10. Correct!
  STA musicSpeedCou_3E3
  LDY musicLengthCou_3E1
curMusPoi0:
  LDA $1234,Y
  BEQ noNewNoteVoice1
  STA $D400
curMusPoi1:
  LDA $1235,Y
  STA $D401
  LDA #$20 ; ' '
  STA $D404
  LDA #$21 ; '!'
  STA $D404
noNewNoteVoice1:    ; CODE XREF: ROM:5D43j
curMusPoi2:
  LDA $1236,Y
  BEQ noNewNoteVoice2
  STA $D407
curMusPoi3:
  LDA $1237,Y
  STA $D408
  LDA #$20 ; ' '
  STA $D40B
  LDA #$21 ; '!'
  STA $D40B

noNewNoteVoice2:    ; CODE XREF: ROM:5D69j
  iny
  iny
  iny
  iny
currentMusicPatternLength:   ; DATA XREF: mainGameLoop_869-2Cw
      ; calcWhichRoom0to8_12A5+B4w ...
  cpy #$80
  BNE noMusicWrap
  LDX nextMusicPoiLSB_3E4
;  STA currentMusicPoiLSB_B4
  stx curMusPoi0+1
  inx
  stx curMusPoi1+1
  inx
  stx curMusPoi2+1
  inx
  stx curMusPoi3+1
  LDA nextMusicPoiMSB_3E5
;  STA currentMusicPoiMSB_B5
  sta curMusPoi0+2
  sta curMusPoi1+2
  sta curMusPoi2+2
  sta curMusPoi3+2

  lda musicPatternLength+1
  sta currentMusicPatternLength+1

  ldy #0
noMusicWrap:
  sty musicLengthCou_3E1
noMusic:    ; CODE XREF: ROM:5D33j ROM:5D38j ...
  rts

musicPatternLength: !byte 0,0

; =============== S U B R O U T I N E =======================================


;musicInit:    ; CODE XREF: titleMusicInit+27p
;  LDA #$1F
;  STA $D418
;  LDA #$66 ; 'f'
;  STA $D405
;  STA $D40C
;  SEI
;  LDA #<musicIrq_5D30 ;$30 ; '0'
;  STA IrqPoiLSB_314
;  LDA #>musicIrq_5D30 ;$5D ; ']'
;  STA IrqPoiMSB_315
;  CLI
;  RTS
;; End of function musicInit


;Pex Irq:
irqInit:
  LDA #$1F
  STA $D418
  LDA #$66 ; 'f'
  STA $D405
  STA $D40C
  SEI
;Setup raster:
  lda #$7F   ;Set NMI mask to 0 for all NMIs
  sta $dc0d  ;CIA Interrupt Control Register (Read NMls/Write Mask)
  lda $dc0d  ;Clear all pending NMI flags
  lda #169
  sta $d012
  lda #$1b
  sta $d011
  lda #1
  sta $d01a  ;IRQ Mask Register: 1 = Interrupt Enabled
  inc $d019

  LDA #<irq_5
  STA $fffe
  LDA #>irq_5
  STA $ffff
  CLI
  RTS

;This is where we switch bank at the top of the torus/rotating text:
irq_0:
  pha
  txa
  pha
  tya
  pha

sprx = $20
  lda #$ff
  sta $d015
  lda #$00
  sta $d010
torus_d000:
  lda #$18
  sta $d000
torus_d002:
  lda #sprx + $18
  sta $d002
torus_d004:
  lda #sprx + $18 * 2
  sta $d004
torus_d006:
  lda #sprx + $18 * 3
  sta $d006
torus_d008:
  lda #sprx + $18 * 4
  sta $d008
torus_d00a:
  lda #sprx + $18 * 5
  sta $d00a
torus_d00c:
  lda #sprx + $18 * 6
  sta $d00c
torus_d00e:
  lda #sprx + $18 * 7
  sta $d00e

irqpos1:
  lda #$aa
  sta $d012
  lda #<irq_1
  sta $fffe
  lda #>irq_1
  sta $ffff

  ; Torus in front of chars, but sprite #0 is used to mask the left edge of the screen.
  ; So Sprite #0 is behind chars, which means that the chars are seen where sprite #0 has pixels.
  lda #$fe
  sta $d01c
  lda #1
  sta $d01b
  lda #0
  sta $d027

  ldx #8
just_wait:
  dex
  bne just_wait

  lda #$2     ;Bank $4000-$7fff
  sta $dd00
  lda #$10    ;screen at $4400, charset at $4000
  sta $d018
  lda #$5b    ;Extended background mode on
  sta $d011

  lda #$c     ;Extra background colour #1
  sta $d022
  lda #$f     ;Extra background colour #2
  sta $d023
  lda #$1     ;Extra background colour #3
  sta $d024

  jsr musicPlay

  inc $d019 ;ack IRQ
  pla
  tay
  pla
  tax
  pla
  rti



sprite_mat = $5c00
first_sprite_no = (sprite_mat-$4000) / $40
screen0 = $4400

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
  ldx #first_sprite_no + $04
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
  inx
  stx screen0+$3ff
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
  ldx #first_sprite_no + $04
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
  inx
  stx screen0+$3ff
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
  ldx #first_sprite_no + $04
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
  inx
  stx screen0+$3ff
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
  ldx #first_sprite_no + $04
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
  inx
  stx screen0+$3ff
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

; Turn off the sprites to make sure that garbage
;in the lower part of the sprites isn't seen:
  LDA #$13    ;screen at $0400, charset at $0800
  nop
  ldx #$00
;  sta $d015
  stx $d010
  stx $d000
  stx $d002
  stx $d004
  stx $d006
  stx $d008
  stx $d00a
  stx $d00c
  stx $d00e
  sta $d018
  ldx #$3     ;Bank $0000-$3fff
  stx $dd00
;  lda #$1b

;It's ok to write $13 into $d011 to get rid of Extended Background mode:
  sta $d011
  lda #$1b
  sta $d011

  sty save_y5+1

  lda #$c0
  sta $d012
  lda #<irq_6
  sta $fffe
  lda #>irq_6
  sta $ffff

  asl $d019
; And allow ourselves to be interrupted by irq_6:
  cli

;rotate those chars in $4080-$40ff:
  jsr fine_tune

save_y5:
  ldy #0
save_x5:
  ldx #0
  pla
  rti


irq_6:
  pha
  txa
  pha
  tya
  pha
;our only task here is to enable lazy jones by the computer:
;Now, let's show the Lazy Jones guy:

  lda #$3
  sta $d015
  lda #0
  sta $d01c
  sta $d01b
  lda #$40
  sta $d000
  LDA #$DC ; '‹'
  STA $D001
  STA $D003
  LDA #9
  STA $D027
  LDA #$A
  STA $D028
lazy_sprx:
  lda #$96
  sta $d000
  sta $d002


  lda #$ff
  sta $d012
  lda #<irq_7
  sta $fffe
  lda #>irq_7
  sta $ffff

anim_delay:
  lda #0
  eor #1
  sta anim_delay+1
  beq no_anim

sprite_no:
  lda #0
  sec
  sbc #1
  and #3
  sta sprite_no+1
  cmp #3
  bne anim_done
col_pos:
  lda #0
  sec
  sbc #1
  cmp #$ff
  bne no_cols_wrap
  lda #2
no_cols_wrap:
  sta col_pos+1
anim_done:
no_anim:

no_move_cols:
  ldx sprite_no+1
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


  lda #0
  sta torus_d00c+1
  sta torus_d00a+1
  sta torus_d008+1
  sta torus_d006+1
  sta torus_d004+1
  sta torus_d002+1

  lda sprite_no+1
  and #1
  clc
desired_xpos_left_lsb:
  adc #$00
  sta torus_d00e+1
  sec
  sbc #$18
  bcc outside_of_screen
  sta torus_d00c+1
  sec
  sbc #$18
  bcc outside_of_screen
  sta torus_d00a+1
  sec
  sbc #$18
  bcc outside_of_screen
  sta torus_d008+1
  sec
  sbc #$18
  bcc outside_of_screen
  sta torus_d006+1
  sec
  sbc #$18
  bcc outside_of_screen
  sta torus_d004+1
  sec
  sbc #$18
  bcc outside_of_screen
  sta torus_d002+1
  sbc #$30
  bcc outside_of_screen
  inc torus_d000+1
  lda #(sprite_heart - $4000) / $40
  sta screen0+$3f8
  lda #2
  sta mask_colour+1

outside_of_screen:

  lda desired_xpos_left_lsb+1
  cmp #$cb
  beq move_no_more
  clc
  adc #1
  sta desired_xpos_left_lsb+1
move_no_more:

  asl $d019
  pla
  tay
  pla
  tax
  pla
  rti


irq_7:
  pha
  txa
  pha
  tya
  pha
;our only task here is to setup the torus sprites:

  LDX #<irq_0
  LDY #>irq_0
switch_to_music_only_irq:
  lda #0
  beq no_music_only
  LDX #<irq_0_music_only
  LDY #>irq_0_music_only
no_music_only:
  STX $fffe
  STY $ffff

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

spr_ypos_msb:
  lda #$4a
  sec
  sbc #2
  sta $d012
  clc
  adc #20
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
  adc #17
  sta irqpos5+1  ; This is where we turn off the sprites and put them all at x-pos 0

spritepoi_0:
  ldx #first_sprite_no + $04
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
  inx
  stx screen0+$3ff

  ldx col_pos+1
  lda sprite_cols_0,x
  sta $d028
  sta $d029
  sta $d02a
  sta $d02b
  sta $d02c
  sta $d02d
  sta $d02e
  lda sprite_cols_1,x
  sta $d025
  lda sprite_cols_2,x
  sta $d026

mask_colour:
  lda #0
  sta $d027


  asl $d019
  pla
  tay
  pla
  tax
  pla
  rti



irq_0_music_only:
  pha
  txa
  pha
  tya
  pha

;  lda #$3
;  sta $d015
  lda #0
  sta $d01c
  LDA #$DC ; '‹'
  STA $D001
  STA $D003
  LDA #9
  STA $D027
  LDA #$A
  STA $D028
;  lda lazy_sprx+1
;  sta $d000
;  sta $d002

;  jsr musicPlay

let_jones_start_walking:
  lda #0
  cmp #1
  bne dont_walk

toggle_walk:
  lda #0
  eor #1
  sta toggle_walk+1
  bne dont_walk
  INC $D000
  INC $D002
  LDA $D000
  AND #1
  BEQ loc_57B3_2
  JSR animateLazyJones_50A0
loc_57B3_2:
  LDA sprite0poi_7F8
  CMP #spriteLazyJonesRightLight2_3540 / $40
  BNE loc_57C4_2
  LDA #$80
  STA $D412
  LDA #$81
  STA $D412
loc_57C4_2:
  LDA $D000
  CMP #$FF
  BNE not_finished_yet
  lda #2
  sta let_jones_start_walking+1
  lda #0
  sta $d015
not_finished_yet:

dont_walk:
  inc $d019 ;ack IRQ
  pla
  tay
  pla
  tax
  pla
  rti


sprite_pois:
  !byte (sprites-$4000) / $40 + 0
  !byte (sprites2-$4000) / $40 + 0
  !byte (sprites3-$4000) / $40 + 0
  !byte (sprites4-$4000) / $40 + 0

sprite_cols_0:
  !byte $6,$e,$6
sprite_cols_1:
  !byte $e,$6,$6
sprite_cols_2:
  !byte $6,$6,$e





; =============== S U B R O U T I N E =======================================

waitAWhilePex:
ev5:
  lda $d012
  bpl ev5
ev6:
  lda $d012
  bmi ev6
  rts





; =============== S U B R O U T I N E =======================================


sub_6C32:     ; CODE XREF: Game01_StarDust_69E0:loc_6B02p
  jmp waitAWhile
;  LDA #4
;  STA byte_FA
;
;loc_6C36:     ; CODE XREF: sub_6C32+Ej
;  LDA #0
;  STA byte_FB
;
;loc_6C3A:     ; CODE XREF: sub_6C32+Aj
;  DEC byte_FB
;  BNE loc_6C3A
;  DEC byte_FA
;  BNE loc_6C36
;  rts
;   JSR sub_59D0
;   RTS
; End of function sub_6C32



; =============== S U B R O U T I N E =======================================


playAudioFx_StarDust1:    ; CODE XREF: Game01_StarDust_69E0+A1p
      ; sub_6BB4+5p ...
  LDA #$80 ; 'Ä'
  STA $D40F
  LDA #$80 ; 'Ä'
  STA $D412
  LDA $D41B
  SEC
  CMP #$8D ; 'ç'
  BCS playAudioFx_StarDust1
  ADC #$28 ; '('
  RTS
; End of function playAudioFx_StarDust1


; =============== S U B R O U T I N E =======================================


playAudioFx_Noise:    ; CODE XREF: sub_6C46+45p
      ; sub_6C46:loc_6CE1p
  LDA #$C
  STA $D413
  LDA $D41B
  AND #3
  CLC
  ADC #1
  STA $D40F
  LDA #$80 ; 'Ä'
  STA $D412
  LDA #$81 ; 'Å'
  STA $D412
  RTS
; End of function playAudioFx_Noise



; =============== S U B R O U T I N E =======================================

textSubgameStarDustAndTheReflex_4790:!byte $13
  !byte $9E ; û
  !byte $11
  !byte $11
  !byte $11
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20 ; @
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20 ; @
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20 ; @
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20 ; @
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20 ; @
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20 ; @
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $1D
  !byte $1D
  !byte $1D
  !byte 5

;  !byte $53 ; S
;  !byte $54 ; T
;  !byte $41 ; A
;  !byte $52 ; R
  !scr "NEXT"
;  !byte $46 ; F
;  !byte $52 ; R
;  !byte $41 ; A
;  !byte $47 ; G

  !byte $9E ; û
  !byte $40 ; @

;  !byte $44 ; D
;  !byte $55 ; U
;  !byte $53 ; S
;  !byte $54 ; T
;  !byte $4d ; M
;  !byte $45 ; E
;  !byte $4e ; N
;  !byte $54 ; T

  !scr "LEVEL"


  !byte $8D ; ç
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $8D ; ç
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $8D ; ç
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $8D ; ç
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $8D ; ç
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $8D ; ç
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $8D ; ç
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $8D ; ç
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $8D ; ç
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $40 ; @
;  !byte $20
;  !byte $20
;  !byte $20
;  !byte $13
  !byte 0

nC3 = $045a
nC3b = $046a
nF3 = $05ce
nF3b = $05df
nG3 = $0685
nG3b = $0684
nA3 = $0751
nA3b = $0770
nB3 = $0837
nC4 = $08b4
nC4b = $08d4
nF4 = $0B9C
nF4b = $0Ba3
nG4 = $0D09
nG4b = $0D19
nA4 = $0EA3
nA4b = $0Ec0
nB4 = $106E

nE5 = $15eb
nF5 = $1739
nG5 = $1a13
nA5 = $1d46
nB5 = $20dc

;Note C       C#      D       D#       E       F       F#      G        G#      A       A#      B
 !byte $16,$01,$27,$01,$38,$01,$4b,$01, $5f,$01,$73,$01,$8a,$01,$a1,$01, $ba,$01,$d4,$01,$f0,$01,$0e,$02
 !byte $2d,$02,$4e,$02,$71,$02,$96,$02, $bd,$02,$e7,$02,$13,$03,$42,$03, $74,$03,$a9,$03,$e0,$03,$1b,$04
 !byte $5a,$04,$9b,$04,$e2,$04,$2c,$05, $7b,$05,$ce,$05,$27,$06,$85,$06, $e8,$06,$51,$07,$c1,$07,$37,$08
 !byte $b4,$08,$37,$09,$c4,$09,$57,$0a, $f5,$0a,$9c,$0b,$4e,$0c,$09,$0d, $d0,$0d,$a3,$0e,$82,$0f,$6e,$10
 !byte $68,$11,$6e,$12,$88,$13,$af,$14, $eb,$15,$39,$17,$9c,$18,$13,$1a, $a1,$1b,$46,$1d,$04,$1f,$dc,$20
 !byte $d0,$22,$dc,$24,$10,$27,$5e,$29, $d6,$2b,$72,$2e,$38,$31,$26,$34, $42,$37,$8c,$3a,$08,$3e,$b8,$41
 !byte $a0,$45,$b8,$49,$20,$4e,$bc,$52, $ac,$57,$e4,$5c,$70,$62,$4c,$68, $84,$6e,$18,$75,$10,$7c,$70,$83
 !byte $40,$8b,$70,$93,$40,$9c,$78,$a5, $58,$af,$c8,$b9,$e0,$c4,$98,$d0, $08,$dd,$30,$ea,$20,$f8,$2e,$fd


;Magnar tune:  C C G G A A A F B
;              G   B  E      A F

musicDataTitle_1C00:
musicDataStarDust_1780:
  !byte <nC3, >nC3,  <nG5, >nG5
  !byte <nC4, >nC4,  <nC4b, >nC4b
  !byte <nC3, >nC3,  <nC3b, >nC3b
  !byte <nC4, >nC4,  <nC4b, >nC4b
  !byte <nC3, >nC3,  <nC3b, >nC3b
  !byte <nC4, >nC4,  <nC3b, >nC3b
  !byte <nC3, >nC3,  <nC3b, >nC3b
  !byte <nC4, >nC4,  <nC3b, >nC3b

  !byte <nG3, >nG3,  <nB5, >nB5
  !byte <nG4, >nG4,  <nG4b, >nG4b
  !byte <nG3, >nG3,  <nG3b, >nG3b
  !byte <nG4, >nG4,  <nG4b, >nG4b
  !byte <nG3, >nG3,  <nG3b, >nG3b
  !byte <nG4, >nG4,  <nG4b, >nG4b
  !byte <nG3, >nG3,  <nE5, >nE5
  !byte <nG4, >nG4,  <nG4b, >nG4b

  !byte <nA3, >nA3,  <nA3b, >nA3b
  !byte <nA4, >nA4,  <nA4b, >nA4b
  !byte <nA3, >nA3,  <nA3b, >nA3b
  !byte <nA4, >nA4,  <nA4b, >nA4b
  !byte <nA3, >nA3,  <nA3b, >nA3b
  !byte <nA4, >nA4,  <nA4b, >nA4b
  !byte <nA3, >nA3,  <nA3b, >nA3b
  !byte <nA4, >nA4,  <nA4b, >nA4b

  !byte <nF3, >nF3,  <nA4, >nA4
  !byte <nF4, >nF4,  <nF4b, >nF4b
  !byte <nF3, >nF3,  <nF3b, >nF3b
  !byte <nF4, >nF4,  <nF4b, >nF4b
  !byte <nG3, >nG3,  <nF5, >nF5
  !byte <nG4, >nG4,  <nG4b, >nG4b
  !byte <nG3, >nG3,  <nG3b, >nG3b
  !byte <nG4, >nG4,  <nG4b, >nG4b



;Music data:
;!byte $0 = $d400 contents. If 0, no new note.
;!byte $1 = $d401 contents
;!byte $2 = $d407 contents. If 0, no new note.
;!byte $3 = $d408 contents






;textGetReady_49E8:  !byte $13
;  !byte $11
;  !byte $11
;  !byte $11
;  !byte $11
;  !byte $11
;  !byte $11
;  !byte $11
;  !byte $11
;  !byte $11
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $1D
;  !byte $47 ; G
;  !byte $45 ; E
;  !byte $54 ; T
;  !byte $20
;  !byte $52 ; R
;  !byte $45 ; E
;  !byte $41 ; A
;  !byte $44 ; D
;  !byte $59 ; Y
;  !byte $13
;  !byte 0

textGameOver_4CE8:  !byte $13
  !byte $11
  !byte $11
  !byte $11
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $47 ; G
  !byte $41 ; A
  !byte $4D ; M
  !byte $45 ; E
  !byte $20
  !byte $20
  !byte $4F ; O
  !byte $56 ; V
  !byte $45 ; E
  !byte $52 ; R
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $8D ; ç
  !byte $1D
  !byte $1D
  !byte $1D
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $20
  !byte $13
  !byte 0












currentJoystickPos_33C: !byte 0
subgameScore0_33D: !byte 0
subgameScore1_33E: !byte 0
subgameTimeLSB_33F: !byte 0
subgameTimeMSB_340: !byte 0
byte_341: !byte 0
byte_342: !byte 0
byte_343: !byte 0
byte_344: !byte 0
byte_345: !byte 0
byte_346: !byte 0
byte_347: !byte 0
byte_348: !byte 0
byte_349: !byte 0
byte_34A: !byte 0
byte_34B: !byte 0
byte_34C: !byte 0
byte_34D: !byte 0
byte_34E: !byte 0
byte_34F: !byte 0
byte_350: !byte 0
byte_351: !byte 0
byte_352: !byte 0
byte_354: !byte 0
playerScore2_360: !byte 0
playerScore1_361: !byte 0
playerScore0_362: !byte 0
hiScore2_363: !byte 0
hiScore1_364: !byte 0
hiScore0_365: !byte 0
playerNumberOfLives_366: !byte 0
whichMainGameScreen_367: !byte 0
randomizedGameList_368: !byte 0
byte_37A: !byte 0
gameListPointerLSB_389: !byte 0
gameListPointerMSB_38A: !byte 0
currentGameNumber_38B: !byte 0
nofRoomsVisited_38C: !byte 0
doingElevatorFlag_38D: !byte 0
jumpFlag_38E: !byte 0
directionManD004_38F: !byte 0
directionDustVanD008_390: !byte 0
directionInvisibleManD00C_391: !byte 0
whichFloorIsLazyJonesOn_393: !byte 0
doingElevatorFlagDelayed_394: !byte 0
doorAnimationCou_395: !byte 0
doorAnimationInc_396: !byte 0
didWeCollideFlag_397: !byte 0
joystickStatus_398: !byte 0
doorAnimationStatus_399: !byte 0
gameListPointerInc_39A: !byte 0
allRoomsVisited_39B: !byte 0
savedD000_LazyXpos_39C: !byte 0
savedD001_LazyYpos_39D: !byte 0
savedD004_foe0Xpos_39E: !byte 0
savedD005_foe0Ypos_39F: !byte 0
savedD008_foe1Xpos_3A0: !byte 0
saveddD009_foe1Ypos_3A1: !byte 0
savedD00C_foeInvisibleManXpos_3A2: !byte 0
savedD00D_foeInvisibleManYpos_3A3: !byte 0
savedD00E_elevatorXpos_3A4: !byte 0
savedD00F_ElevatorYpos_3A5: !byte 0
savedD010_3A6: !byte 0
saved07F8_gameSprPois: !byte 0
savedD027_gameSprCols: !byte 0
mainGameSpeed_3B7: !byte 0
whichMenuScreenIsShown_3C0: !byte 0
waitCounterMSB_3C1: !byte 0
waitCounterLSB_3C2: !byte 0
musicEnabled_3E0: !byte 0
musicLengthCou_3E1: !byte 0
musicSpeedCou_3E3: !byte 0
nextMusicPoiLSB_3E4: !byte 0
nextMusicPoiMSB_3E5: !byte 0










;Sprites cannot be located $1000-$2000
*=$2000
  !align $40,0,0
spriteWalkingManRightLight0_2700:
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 0
  !byte $64 ; d
  !byte 0
  !byte 0
  !byte $62 ; b
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $34 ; 4
  !byte 0
  !byte 0
  !byte $1E
  !byte 0
  !byte 0
  !byte $1C
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManRightDark0_2740:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $1C
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 8
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $60 ; `
  !byte 0
  !byte 0
  !byte $60 ; `
  !byte 0
  !byte 0
  !byte $40 ; @
  !byte 0
  !byte 0
  !byte $58 ; X
  !byte 0
  !byte 0
  !byte $1E
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManRightLight1_2780:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 0
  !byte $64 ; d
  !byte 0
  !byte 0
  !byte $62 ; b
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $36 ; 6
  !byte 0
  !byte 0
  !byte $1F
  !byte 0
  !byte 0
  !byte $1B
  !byte 0
  !byte 0
  !byte $30 ; 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManRightDark1_27C0:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $1C
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 8
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 3
  !byte 0
  !byte 0
  !byte $33 ; 3
  !byte $C0 ; ¿
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManRightLight2_2800:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 0
  !byte $64 ; d
  !byte 0
  !byte 0
  !byte $62 ; b
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $36 ; 6
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $C1 ; ¡
  !byte $80 ; Ä
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManRightDark2_2840:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $1C
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 8
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 1
  !byte $81 ; Å
  !byte $80 ; Ä
  !byte 1
  !byte $E1 ; ·
  !byte $E0 ; ‡
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManRightLight3_2880:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 0
  !byte $64 ; d
  !byte 0
  !byte 0
  !byte $62 ; b
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $59 ; Y
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $34 ; 4
  !byte 0
  !byte 0
  !byte $FC ; ¸
  !byte 0
  !byte 0
  !byte $EC ; Ï
  !byte 0
  !byte 0
  !byte 6
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManRightDark3_28C0:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $1C
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 8
  !byte 0
  !byte 3
  !byte 0
  !byte 0
  !byte 3
  !byte 0
  !byte 0
  !byte 2
  !byte 0
  !byte 0
  !byte 2
  !byte 6
  !byte 0
  !byte 0
  !byte 7
  !byte $80 ; Ä
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManLeftLight0_2900:
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $26 ; &
  !byte 0
  !byte 0
  !byte $46 ; F
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $2C ; ,
  !byte 0
  !byte 0
  !byte $78 ; x
  !byte 0
  !byte 0
  !byte $38 ; 8
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManLeftDark0_2940:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $38 ; 8
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 6
  !byte 0
  !byte 0
  !byte 6
  !byte 0
  !byte 0
  !byte 2
  !byte 0
  !byte 0
  !byte $1A
  !byte 0
  !byte 0
  !byte $78 ; x
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManLeftLight1_2980:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $26 ; &
  !byte 0
  !byte 0
  !byte $46 ; F
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $6C ; l
  !byte 0
  !byte 0
  !byte $F8 ; ¯
  !byte 0
  !byte 0
  !byte $D8 ; ÿ
  !byte 0
  !byte 0
  !byte  $C
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManLeftDark1_29C0:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $38 ; 8
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $C0 ; ¿
  !byte 0
  !byte 3
  !byte $CC ; Ã
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManLeftLight2_2A00:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $26 ; &
  !byte 0
  !byte 0
  !byte $46 ; F
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $6C ; l
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 1
  !byte $83 ; É
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManLeftDark2_2A40:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $38 ; 8
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 1
  !byte $81 ; Å
  !byte $80 ; Ä
  !byte 7
  !byte $87 ; á
  !byte $80 ; Ä
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManLeftLight3_2A80:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $3E ; >
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $26 ; &
  !byte 0
  !byte 0
  !byte $46 ; F
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $9A ; ö
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $2C ; ,
  !byte 0
  !byte 0
  !byte $3F ; ?
  !byte 0
  !byte 0
  !byte $67 ; g
  !byte 0
  !byte 0
  !byte $60 ; `
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteWalkingManLeftDark3_2AC0:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $38 ; 8
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte $7C ; |
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte $C0 ; ¿
  !byte 0
  !byte 0
  !byte $C0 ; ¿
  !byte 0
  !byte 0
  !byte $40 ; @
  !byte 0
  !byte $60 ; `
  !byte $40 ; @
  !byte 1
  !byte $E0 ; ‡
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteLazyJonesRightLight0_3440:
  !byte 0  ; DATA XREF: Game11_ResQ_99A0+17w
      ; sub_9C8A+Aw ...
byte_3441:  !byte $78   ; DATA XREF: Game11_ResQ_99A0+1Cw
      ; sub_9C8A+Fw ...
  !byte 0
  !byte 0
  !byte $E7 ; Á
  !byte 0
  !byte 0
  !byte $C0 ; ¿
  !byte $80 ; Ä
  !byte 0
  !byte $67 ; g
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $FF
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $34 ; 4
  !byte 0
  !byte 0
  !byte $1E
  !byte 0
  !byte 0
  !byte $1C
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesRightDark0_3480:
spriteWavingMan0_3480:!byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $3F ; ?
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 8
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $60 ; `
  !byte 0
  !byte 0
  !byte $60 ; `
  !byte 0
  !byte 0
  !byte $40 ; @
  !byte 0
  !byte 0
  !byte $58 ; X
  !byte 0
  !byte 0
  !byte $1E
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesRightLight1_34c0:
spriteWavingMan1_34c0:
  !byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte $78 ; x
  !byte 0
  !byte 0
  !byte $E7 ; Á
  !byte 0
  !byte 0
  !byte $C0 ; ¿
  !byte $80 ; Ä
  !byte 0
  !byte $67 ; g
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $FF
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $36 ; 6
  !byte 0
  !byte 0
  !byte $1F
  !byte 0
  !byte 0
  !byte $1B
  !byte 0
  !byte 0
  !byte $30 ; 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesRightDark1_3500:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $3F ; ?
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 8
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 3
  !byte 0
  !byte 0
  !byte $33 ; 3
  !byte $C0 ; ¿
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesRightLight2_3540:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $78 ; x
  !byte 0
  !byte 0
  !byte $E7 ; Á
  !byte 0
  !byte 0
  !byte $C0 ; ¿
  !byte $80 ; Ä
  !byte 0
  !byte $67 ; g
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $FF
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $36 ; 6
  !byte 0
  !byte 0
  !byte $7F ; 
  !byte 0
  !byte 0
  !byte $C1 ; ¡
  !byte $80 ; Ä
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesRightLight2_3580:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $3F ; ?
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 8
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 1
  !byte $81 ; Å
  !byte $80 ; Ä
  !byte 1
  !byte $E1 ; ·
  !byte $E0 ; ‡
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesRightDark3_35c0:
  !byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte $78 ; x
  !byte 0
  !byte 0
  !byte $E7 ; Á
  !byte $80 ; Ä
  !byte 0
  !byte $C0 ; ¿
  !byte $80 ; Ä
  !byte 0
  !byte $67 ; g
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $FF
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $34 ; 4
  !byte 0
  !byte 0
  !byte $FC ; ¸
  !byte 0
  !byte 0
  !byte $EC ; Ï
  !byte 0
  !byte 0
  !byte 6
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesRightLight3_3600:
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $3F ; ?
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 8
  !byte 0
  !byte 3
  !byte 0
  !byte 0
  !byte 3
  !byte 0
  !byte 0
  !byte 2
  !byte 0
  !byte 0
  !byte 2
  !byte 6
  !byte 0
  !byte 0
  !byte 7
  !byte $80 ; Ä
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesLeftDark0_3640:!byte   0
  !byte $1E
  !byte 0
  !byte 0
  !byte $E7 ; Á
  !byte 0
  !byte 1
  !byte 3
  !byte 0
  !byte 0
  !byte $E6 ; Ê
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $FF
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $2C ; ,
  !byte 0
  !byte 0
  !byte $78 ; x
  !byte 0
  !byte 0
  !byte $38 ; 8
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesLeftLight0_3680:!byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $FC ; ¸
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 6
  !byte 0
  !byte 0
  !byte 6
  !byte 0
  !byte 0
  !byte 2
  !byte 0
  !byte 0
  !byte $1A
  !byte 0
  !byte 0
  !byte $78 ; x
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesLeftDark1_36c0:!byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte $1E
  !byte 0
  !byte 0
  !byte $E7 ; Á
  !byte 0
  !byte 1
  !byte 3
  !byte 0
  !byte 0
  !byte $E6 ; Ê
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $FF
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $6C ; l
  !byte 0
  !byte 0
  !byte $F8 ; ¯
  !byte 0
  !byte 0
  !byte $D8 ; ÿ
  !byte 0
  !byte 0
  !byte  $C
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesLeftLight2_3700:!byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $FC ; ¸
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $40 ; @
  !byte 0
  !byte 3
  !byte $CC ; Ã
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesLeftDark2_3740:!byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $1E
  !byte 0
  !byte 0
  !byte $E7 ; Á
  !byte 0
  !byte 1
  !byte 3
  !byte 0
  !byte 0
  !byte $E6 ; Ê
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $FF
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $6C ; l
  !byte 0
  !byte 0
  !byte $FE ; ˛
  !byte 0
  !byte 1
  !byte $83 ; É
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesLeftLight2_3780:!byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $FC ; ¸
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 1
  !byte $81 ; Å
  !byte $80 ; Ä
  !byte 7
  !byte $87 ; á
  !byte $80 ; Ä
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesLeftDark3_37c0:!byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte $1E
  !byte 0
  !byte 0
  !byte $E7 ; Á
  !byte 0
  !byte 1
  !byte 3
  !byte 0
  !byte 0
  !byte $E6 ; Ê
  !byte 0
  !byte 0
  !byte $24 ; $
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $42 ; B
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $99 ; ô
  !byte 0
  !byte 0
  !byte $FF
  !byte 0
  !byte 0
  !byte $66 ; f
  !byte 0
  !byte 0
  !byte $2C ; ,
  !byte 0
  !byte 0
  !byte $3F ; ?
  !byte 0
  !byte 0
  !byte $67 ; g
  !byte 0
  !byte 0
  !byte $60 ; `
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
spriteLazyJonesLeftLight3_3800:!byte   0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $FC ; ¸
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $3C ; <
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte $7E ; ~
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte $18
  !byte 0
  !byte 0
  !byte $10
  !byte 0
  !byte 0
  !byte 0
  !byte $C0 ; ¿
  !byte 0
  !byte 0
  !byte $C0 ; ¿
  !byte 0
  !byte 0
  !byte $40 ; @
  !byte 0
  !byte $60 ; `
  !byte $40 ; @
  !byte 1
  !byte $E0 ; ‡
  !byte 0
  !byte 0
  !byte 0
  !byte 0
  !byte 0

spriteDuck:
spriteStardustStarship_2F00:
  !byte %00000000,%00000000,%00000000
  !byte %00000000,%00000111,%11000000
  !byte %00000000,%00011111,%11100000
  !byte %00000000,%00111111,%11100000
  !byte %00000000,%00111111,%11110000
  !byte %00000000,%00011111,%11111111
  !byte %01000000,%00000111,%11111100
  !byte %11100000,%11111111,%11100000
  !byte %11111111,%11111111,%11110000
  !byte %11111111,%11111111,%11110000
  !byte %11111111,%11111111,%11111000
  !byte %01111111,%11111111,%11111000
  !byte %01111111,%11111111,%11111000
  !byte %00111111,%11111111,%11110000
  !byte %00011111,%11111111,%11100000
  !byte %00000111,%11111111,%11000000
  !byte %00000001,%11111111,%00000000
  !byte %00000000,%01111100,%00000000
  !byte %00000000,%00000000,%00000000
  !byte %00000000,%00000000,%00000000
  !byte %00000000,%00000000,%00000000
  !byte 0

bo = $4
fg = $7
sh = $0
oo = $b

PexGame_d800:
  !byte $b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b
  !byte $b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b
  !byte $b,$b,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,bo,$8,$8,$1,$1,$1,$1,$7,$7,$7,$7,$7,$7,$8,$8,$8,$8
  !byte $b,$b,bo,oo,fg,fg,fg,oo,fg,fg,oo,fg,oo,fg,oo,fg,fg,oo,fg,fg,fg,oo,fg,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,fg,sh,fg,sh,fg,sh,sh,fg,sh,fg,sh,fg,sh,sh,fg,sh,fg,sh,fg,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,fg,fg,fg,sh,fg,fg,oo,oo,fg,sh,sh,fg,fg,oo,fg,sh,fg,sh,fg,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,fg,sh,sh,sh,fg,sh,sh,fg,sh,fg,oo,fg,sh,sh,fg,sh,fg,sh,fg,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,fg,sh,oo,oo,fg,fg,oo,fg,sh,fg,sh,fg,sh,oo,fg,fg,fg,sh,fg,bo,$8,$8,$8,$8,$2,$2,$2,$2,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,oo,sh,oo,oo,oo,sh,sh,oo,sh,oo,sh,oo,sh,oo,oo,sh,sh,sh,oo,bo,$8,$8,$8,$8,$7,$7,$7,$7,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,bo,$8,$8,$8,$8,$2,$2,$2,$2,$2,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,bo,$8,$8,$8,$8,$7,$7,$7,$7,$7,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,oo,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $b,$b,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $8,$b,bo,$7,$7,$7,$7,$7,bo,$f,$f,$f,bo,bo,$7,$7,$7,$7,bo,$f,$f,$f,$f,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $8,$8,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,bo,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$5,$5,$5,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$c,$c,$c,$c,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$2,$2,$2,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$2,$1,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$2,$2,$2,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$2,$2,$2,$8,$8,$8,$8,$8,$8,$8,$8
  !byte $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$b,$b,$b,$b,$8,$8,$8,$8,$8,$8,$8


;The special chars that are needed here as well (copied from Lazy Jones charset manually):
chars_4000_to_407f:
  !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;Filled               ;$00
  !byte $cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf ;Left edge of screen  ;$01
  !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3 ;Right edge of screen ;$02
  !byte $7e,$63,$63,$63,$63,$63,$63,$63 ;      N = char $0e   ;$03
  !byte $7f,$63,$60,$7c,$60,$60,$63,$7f ;      E = char $05   ;$04
  !byte $63,$63,$36,$1c,$1c,$36,$63,$63 ;      X = char $18   ;$05
  !byte $7e,$18,$18,$18,$18,$18,$18,$18 ;      T = char $14   ;$06
  !byte $00,$00,$00,$00,$10,$38,$10,$00 ;      . = char $00   ;$07
  !byte $60,$60,$60,$60,$60,$60,$63,$7f ;      L = char $0c   ;$08
  !byte $63,$63,$63,$63,$63,$36,$1c,$08 ;      V = char $16   ;$09
  !byte $00,$00,$07,$07,$0e,$0e,$1c,$1c ;upper L = char $41   ;$0a
  !byte $00,$00,$0e,$1f,$1b,$33,$33,$7e ;upper A = char $42   ;$0b
  !byte $00,$00,$3f,$3f,$33,$03,$06,$0c ;upper Z = char $43   ;$0c
  !byte $00,$00,$33,$33,$33,$63,$66,$7e ;upper Y = char $44   ;$0d
  !byte $38,$38,$70,$70,$fe,$fe,$00,$00 ;lower L = char $45   ;$0e
  !byte $7e,$66,$c6,$cc,$cc,$cc,$00,$00 ;lower A = char $46   ;$0f
;$4080-$40ff is where we blit rotated texts into.
chars_4100_to_417f:
  !byte 0,0,0,0,0,0,0,0                                       ;$20
  !byte $18,$30,$60,$cc,$fc,$fc,$00,$00 ;lower Z = char $47   ;$21
  !byte $3e,$0c,$cc,$d8,$f8,$70,$00,$00 ;lower Y = char $48   ;$22
  !byte $00,$00,$fc,$7e,$18,$18,$0c,$0c ;upper J = char $49   ;$23
  !byte $00,$00,$78,$fc,$cc,$cc,$cc,$66 ;upper O = char $4a   ;$24
  !byte $00,$00,$f8,$fc,$cc,$cc,$cc,$66 ;upper N = char $4b   ;$25
  !byte $00,$00,$7c,$fe,$c6,$c0,$60,$3c ;upper E = char $4c   ;$26
  !byte $00,$00,$7c,$fe,$c6,$c6,$60,$38 ;upper S = char $4d   ;$27
  !byte $0c,$06,$06,$63,$7f,$3e,$00,$00 ;lower J = char $4e   ;$28
  !byte $33,$33,$33,$3f,$3f,$1e,$00,$00 ;lower O = char $4f   ;$29
  !byte $66,$66,$33,$33,$33,$33,$00,$00 ;lower N = char $50   ;$2a
  !byte $38,$60,$63,$63,$3f,$1e,$00,$00 ;lower E = char $51   ;$2b
  !byte $0c,$06,$63,$63,$7f,$3e,$00,$00 ;lower S = char $52   ;$2c

sprite_heart_4240:
  !byte %01111111,%11111111,%11110000
  !byte %00111111,%11111111,%11100000
  !byte %00111111,%11111111,%11100000
  !byte %00011111,%11111111,%11000000
  !byte %00001111,%11111111,%10000000
  !byte %00000111,%11111111,%00000000
  !byte %00000011,%11111110,%00000000
  !byte %00000001,%11111100,%00000000
  !byte %00000000,%11111000,%00000000
  !byte %00000000,%01110000,%00000000
  !byte %00000000,%00100000,%00000000
  !byte %00000110,%00000011,%00000000
  !byte %00011111,%10001111,%11000000
  !byte %00111111,%11011111,%11100000
  !byte %01111111,%11111111,%11110000
  !byte %01111111,%11111111,%11110000
  !byte %11111111,%11111111,%11111000
  !byte %11111111,%11111111,%11111000
  !byte %01111111,%11111111,%11110000
  !byte %01111111,%11111111,%11110000
  !byte %01111111,%11111111,%11110000


;Filled sprite $4200-$4240
filled_sprite = $4200
sprite_heart = $4240

;The whole Lazy Jones charset:
;>C:0800  !byte $00,$00,$00,$00,$10,$38,$10,$00
;         !byte $3e,$63,$63,$7f,$63,$63,$63,$63
;>C:0810  !byte $7e,$63,$63,$7e,$63,$63,$63,$7e
;         !byte $3e,$63,$60,$60,$60,$60,$63,$3e
;>C:0820  !byte $7e,$63,$63,$63,$63,$63,$63,$7e
;         !byte $7f,$63,$60,$7c,$60,$60,$63,$7f
;>C:0830  !byte $7f,$63,$60,$7c,$60,$60,$60,$60
;         !byte $3e,$63,$60,$60,$67,$63,$63,$3e
;>C:0840  !byte $63,$63,$63,$7f,$63,$63,$63,$63
;         !byte $7e,$18,$18,$18,$18,$18,$18,$7e
;>C:0850  !byte $03,$03,$03,$03,$63,$63,$63,$3e
;         !byte $63,$66,$6c,$78,$6c,$66,$63,$63
;>C:0860  !byte $60,$60,$60,$60,$60,$60,$63,$7f char $0c
;         !byte $63,$77,$7f,$6b,$63,$63,$63,$63
;>C:0870  !byte $7e,$63,$63,$63,$63,$63,$63,$63  $0e
;         !byte $3e,$63,$63,$63,$63,$63,$63,$3e
;>C:0880  !byte $7e,$63,$63,$7e,$60,$60,$60,$60
;         !byte $3e,$63,$63,$63,$63,$7b,$3e,$0c
;>C:0890  !byte $7e,$63,$63,$7e,$78,$6c,$66,$63
;         !byte $3e,$63,$60,$3e,$03,$63,$63,$3e
;>C:08a0  !byte $7e,$18,$18,$18,$18,$18,$18,$18
;         !byte $63,$63,$63,$63,$63,$63,$63,$3e
;>C:08b0  !byte $63,$63,$63,$63,$63,$36,$1c,$08
;         !byte $63,$63,$63,$63,$6b,$7f,$77,$63
;>C:08c0  !byte $63,$63,$36,$1c,$1c,$36,$63,$63
;         !byte $63,$63,$63,$3f,$03,$63,$63,$3e
;>C:08d0  !byte $7f,$63,$06,$0c,$18,$30,$63,$7f
;         !byte $ff,$c0,$cf,$cf,$cf,$cf,$cf,$cf
;>C:08e0  !byte $ff,$00,$ff,$ff,$ff,$ff,$ff,$ff
;         !byte $ff,$03,$f3,$f3,$f3,$f3,$f3,$f3
;>C:08f0  !byte $cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf
;         !byte $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3
;>C:0900  !byte $00,$00,$00,$00,$00,$00,$00,$00  ;char $20
;         !byte $ff,$ff,$ff,$fc,$fc,$ff,$ff,$ff
;>C:0910  !byte $00,$36,$36,$24,$00,$00,$00,$00
;         !byte $1f,$3f,$66,$36,$06,$06,$0f,$00
;>C:0920  !byte $ff,$ff,$66,$66,$66,$66,$ff,$00
;         !byte $f8,$fc,$66,$6c,$60,$60,$f0,$00
;>C:0930  !byte $00,$01,$07,$0c,$18,$31,$33,$1a
;         !byte $01,$c7,$6d,$38,$19,$db,$78,$3b
;>C:0940  !byte $f0,$18,$88,$dc,$b6,$33,$e3,$e6
;         !byte $0f,$18,$31,$67,$6c,$2d,$07,$00
;>C:0950  !byte $1e,$9c,$d9,$7b,$3e,$1c,$18,$3c
;         !byte $30,$18,$0c,$8c,$c6,$6c,$c0,$80
;>C:0960  !byte $07,$07,$03,$03,$03,$01,$01,$00
;         !byte $ff,$ff,$55,$ff,$ff,$ea,$ff,$00
;>C:0970  !byte $e0,$e0,$40,$c0,$c0,$00,$80,$00
;         !byte $c0,$60,$30,$18,$0c,$06,$03,$01
;>C:0980  !byte $1c,$36,$63,$63,$63,$63,$36,$1c
;         !byte $18,$38,$18,$18,$18,$18,$18,$3c
;>C:0990  !byte $3e,$63,$03,$3e,$60,$60,$63,$7f
;         !byte $3e,$63,$03,$1e,$03,$03,$63,$3e
;>C:09a0  !byte $06,$0e,$1e,$36,$66,$7f,$06,$06
;         !byte $7f,$63,$60,$7e,$03,$03,$63,$3e
;>C:09b0  !byte $3e,$63,$60,$7e,$63,$63,$63,$3e
;         !byte $7f,$63,$06,$0c,$18,$18,$18,$18
;>C:09c0  !byte $3e,$63,$63,$3e,$63,$63,$63,$3e
;         !byte $3e,$63,$63,$3f,$03,$03,$63,$3e
;>C:09d0  !byte $ff,$c0,$c0,$c0,$c0,$c0,$c0,$c0
;         !byte $ff,$00,$f0,$f0,$f0,$f0,$f0,$f0
;>C:09e0  !byte $ff,$00,$00,$00,$00,$00,$00,$00
;         !byte $ff,$03,$03,$03,$03,$03,$03,$03
;>C:09f0  !byte $e7,$e7,$e7,$e7,$e7,$e7,$e7,$e7
;         !byte $f7,$f7,$f7,$f7,$f7,$f7,$f7,$f7
;>C:0a00  !byte $3c,$42,$99,$a1,$a1,$99,$42,$3c  ;char $40
;         !byte $00,$00,$07,$07,$0e,$0e,$1c,$1c
;>C:0a10  !byte $00,$00,$0e,$1f,$1b,$33,$33,$7e
;         !byte $00,$00,$3f,$3f,$33,$03,$06,$0c
;>C:0a20  !byte $00,$00,$33,$33,$33,$63,$66,$7e
;         !byte $38,$38,$70,$70,$fe,$fe,$00,$00
;>C:0a30  !byte $7e,$66,$c6,$cc,$cc,$cc,$00,$00
;         !byte $18,$30,$60,$cc,$fc,$fc,$00,$00
;>C:0a40  !byte $3e,$0c,$cc,$d8,$f8,$70,$00,$00
;         !byte $00,$00,$fc,$7e,$18,$18,$0c,$0c
;>C:0a50  !byte $00,$00,$78,$fc,$cc,$cc,$cc,$66
;         !byte $00,$00,$f8,$fc,$cc,$cc,$cc,$66
;>C:0a60  !byte $00,$00,$7c,$fe,$c6,$c0,$60,$3c
;         !byte $00,$00,$7c,$fe,$c6,$c6,$60,$38
;>C:0a70  !byte $0c,$06,$06,$63,$7f,$3e,$00,$00
;         !byte $33,$33,$33,$3f,$3f,$1e,$00,$00
;>C:0a80  !byte $66,$66,$33,$33,$33,$33,$00,$00
;         !byte $38,$60,$63,$63,$3f,$1e,$00,$00
;>C:0a90  !byte $0c,$06,$63,$63,$7f,$3e,$00,$00
;         !byte $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
;>C:0aa0  !byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
;         !byte $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
;>C:0ab0  !byte $03,$03,$03,$03,$03,$03,$03,$03
;         !byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
;>C:0ac0  !byte $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f
;         !byte $c3,$c3,$c3,$c3,$c3,$c3,$c3,$c3
;>C:0ad0  !byte $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c
;         !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
;>C:0ae0  !byte $3f,$7f,$e0,$c7,$cf,$cf,$cf,$cf
;         !byte $fc,$fe,$07,$e3,$f3,$f3,$f3,$f3
;>C:0af0  !byte $cf,$cf,$cf,$cf,$c7,$e0,$7f,$3f
;         !byte $f3,$f3,$f3,$f3,$e3,$07,$fe,$fc
;>C:0b00  !byte $ff,$ff,$00,$ff,$ff,$ff,$ff,$ff  ;char $60
;         !byte $ff,$ff,$ff,$ff,$ff,$00,$ff,$ff
;>C:0b10  !byte $00,$03,$0f,$07,$2b,$11,$03,$07
;         !byte $00,$c0,$f0,$e0,$d4,$88,$c0,$e0
;>C:0b20  !byte $0d,$1b,$07,$0f,$1f,$01,$07,$00
;         !byte $b0,$d8,$e0,$f0,$f8,$80,$e0,$00
;>C:0b30  !byte $c3,$c3,$c3,$ff,$c3,$c3,$c3,$c3
;         !byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
;>C:0b40  !byte $ff,$81,$81,$81,$81,$81,$81,$81
;         !byte $7f,$bf,$df,$ef,$f7,$fb,$fd,$fe
;>C:0b50  !byte $01,$03,$07,$0f,$1f,$3f,$7f,$ff
;         !byte $fe,$fc,$f8,$f0,$e0,$c0,$80,$00
;>C:0b60  !byte $80,$c0,$e0,$f0,$f8,$fc,$fe,$ff
;         !byte $ff,$7f,$3f,$1f,$0f,$07,$03,$01
;>C:0b70  !byte $ff,$57,$ff,$92,$c9,$e2,$f1,$ff
;         !byte $ff,$ef,$ff,$57,$23,$49,$25,$ff
;>C:0b80  !byte $10,$10,$08,$08,$04,$64,$98,$00
;         !byte $00,$00,$0c,$0c,$0c,$1e,$3f,$1e
;>C:0b90  !byte $00,$00,$79,$61,$78,$61,$79,$00
;         !byte $00,$00,$b3,$b3,$e3,$b3,$b3,$00
;>C:0ba0  !byte $00,$00,$7e,$18,$18,$18,$18,$00
;         !byte $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
;>C:0bb0  !byte $10,$10,$10,$10,$10,$10,$10,$10
;         !byte $00,$00,$00,$ff,$00,$00,$00,$00
;>C:0bc0  !byte $00,$00,$00,$f0,$10,$10,$10,$10
;         !byte $00,$00,$00,$1f,$10,$10,$10,$10
;>C:0bd0  !byte $10,$10,$10,$f0,$00,$00,$00,$00
;         !byte $10,$10,$10,$1f,$00,$00,$00,$00
;>C:0be0  !byte $ee,$dd,$00,$26,$23,$00,$bb,$77
;         !byte $e0,$d8,$38,$b8,$80,$38,$f0,$70
;>C:0bf0  !byte $ff,$81,$81,$81,$81,$81,$81,$ff
;         !byte $ff,$c3,$a5,$99,$99,$a5,$c3,$ff

;This is 480 bytes to copy into the "textrotator bank screen":
screen_to_4478:
  !byte $00,$00,$01, $56,$58,$5a,$5c, $9e,$90,$92,$94, $d6,$d8,$da,$dc, $9e,$90,$92,$94, $56,$58,$5a,$5c, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $57,$59,$5b,$5d, $9f,$91,$93,$95, $d7,$d9,$db,$dd, $9f,$91,$93,$95, $57,$59,$5b,$5d, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $50,$52,$54,$56, $98,$9a,$9c,$9e, $d0,$d2,$d4,$d6, $98,$9a,$9c,$9e, $50,$52,$54,$56, $02, $20,$20,$03,$04, $05,$06,$07,$08, $04,$09,$04,$08, $20,$20,$20,$20
  !byte $00,$00,$01, $51,$00,$00,$00, $99,$00,$00,$9f, $00,$d3,$00,$d7, $00,$00,$9d,$00, $00,$00,$55,$00, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $5a,$00,$5e,$00, $92,$00,$96,$98, $00,$dc,$00,$d0, $00,$94,$96,$00, $5a,$00,$5e,$00, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $5b,$00,$00,$00, $93,$00,$00,$99, $db,$00,$df,$d1, $00,$00,$97,$00, $5b,$00,$5f,$00, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $54,$00,$58,$5a, $9c,$00,$90,$92, $00,$d6,$00,$da, $00,$9e,$90,$00, $54,$00,$58,$00, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $55,$00,$59,$5b, $9d,$00,$00,$93, $00,$d7,$00,$db, $00,$9f,$91,$00, $00,$00,$59,$00, $02, $20,$20,$20,$20, $0a,$0b,$0c,$0d, $20,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $5e,$50,$52,$54, $96,$98,$9a,$9c, $de,$d0,$d2,$d4, $96,$98,$9a,$9c, $5e,$50,$52,$54, $02, $20,$20,$20,$20, $0e,$0f,$21,$22, $20,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $5f,$51,$53,$55, $97,$99,$9b,$9d, $df,$d1,$d3,$d5, $97,$99,$9b,$9d, $5f,$51,$53,$55, $02, $20,$20,$20,$20, $23,$24,$25,$26, $27,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $58,$5a,$5c,$5e, $90,$92,$94,$96, $d8,$da,$dc,$de, $90,$92,$94,$96, $58,$5a,$5c,$5e, $02, $20,$20,$20,$20, $28,$29,$2a,$2b, $2c,$20,$20,$20, $20,$20,$20,$20
  !byte $00,$00,$01, $59,$5b,$5d,$5f, $91,$93,$95,$97, $d9,$db,$dd,$df, $91,$93,$95,$97, $59,$5b,$5d,$5f, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20

;Without Extended Background mode colours:
;screen_to_4478:
;  !byte $00,$00,$01, $16,$18,$1a,$1c, $1e,$10,$12,$14, $16,$18,$1a,$1c, $1e,$10,$12,$14, $16,$18,$1a,$1c, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $17,$19,$1b,$1d, $1f,$11,$13,$15, $17,$19,$1b,$1d, $1f,$11,$13,$15, $17,$19,$1b,$1d, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $10,$12,$14,$16, $18,$1a,$1c,$1e, $10,$12,$14,$16, $18,$1a,$1c,$1e, $10,$12,$14,$16, $02, $20,$20,$03,$04, $05,$06,$07,$08, $04,$09,$04,$08, $20,$20,$20,$20
;  !byte $00,$00,$01, $11,$00,$00,$00, $19,$00,$00,$1f, $00,$13,$00,$17, $00,$00,$1d,$00, $00,$00,$15,$00, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $1a,$00,$1e,$00, $12,$00,$16,$18, $00,$1c,$00,$10, $00,$14,$16,$00, $1a,$00,$1e,$00, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $1b,$00,$00,$00, $13,$00,$00,$19, $1b,$00,$1f,$11, $00,$00,$17,$00, $1b,$00,$1f,$00, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $14,$00,$18,$1a, $1c,$00,$10,$12, $00,$16,$00,$1a, $00,$1e,$10,$00, $14,$00,$18,$00, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $15,$00,$19,$1b, $1d,$00,$00,$13, $00,$17,$00,$1b, $00,$1f,$11,$00, $00,$00,$19,$00, $02, $20,$20,$20,$20, $0a,$0b,$0c,$0d, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $1e,$10,$12,$14, $16,$18,$1a,$1c, $1e,$10,$12,$14, $16,$18,$1a,$1c, $1e,$10,$12,$14, $02, $20,$20,$20,$20, $0e,$0f,$21,$22, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $1f,$11,$13,$15, $17,$19,$1b,$1d, $1f,$11,$13,$15, $17,$19,$1b,$1d, $1f,$11,$13,$15, $02, $20,$20,$20,$20, $23,$24,$25,$26, $27,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $18,$1a,$1c,$1e, $10,$12,$14,$16, $18,$1a,$1c,$1e, $10,$12,$14,$16, $18,$1a,$1c,$1e, $02, $20,$20,$20,$20, $28,$29,$2a,$2b, $2c,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $19,$1b,$1d,$1f, $11,$13,$15,$17, $19,$1b,$1d,$1f, $11,$13,$15,$17, $19,$1b,$1d,$1f, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20

;With all chars shown:
;* = $4400 + 3*40
;  !byte $00,$00,$01, $16,$18,$1a,$1c, $1e,$10,$12,$14, $16,$18,$1a,$1c, $1e,$10,$12,$14, $16,$18,$1a,$1c, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $17,$19,$1b,$1d, $1f,$11,$13,$15, $17,$19,$1b,$1d, $1f,$11,$13,$15, $17,$19,$1b,$1d, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $10,$12,$14,$16, $18,$1a,$1c,$1e, $10,$12,$14,$16, $18,$1a,$1c,$1e, $10,$12,$14,$16, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $11,$13,$15,$17, $19,$1b,$1d,$1f, $11,$13,$15,$17, $19,$1b,$1d,$1f, $11,$13,$15,$17, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $1a,$1c,$1e,$10, $12,$14,$16,$18, $1a,$1c,$1e,$10, $12,$14,$16,$18, $1a,$1c,$1e,$10, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $1b,$1d,$1f,$11, $13,$15,$17,$19, $1b,$1d,$1f,$11, $13,$15,$17,$19, $1b,$1d,$1f,$11, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $14,$16,$18,$1a, $1c,$1e,$10,$12, $14,$16,$18,$1a, $1c,$1e,$10,$12, $14,$16,$18,$1a, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $15,$17,$19,$1b, $1d,$1f,$11,$13, $15,$17,$19,$1b, $1d,$1f,$11,$13, $15,$17,$19,$1b, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $1e,$10,$12,$14, $16,$18,$1a,$1c, $1e,$10,$12,$14, $16,$18,$1a,$1c, $1e,$10,$12,$14, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $1f,$11,$13,$15, $17,$19,$1b,$1d, $1f,$11,$13,$15, $17,$19,$1b,$1d, $1f,$11,$13,$15, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $18,$1a,$1c,$1e, $10,$12,$14,$16, $18,$1a,$1c,$1e, $10,$12,$14,$16, $18,$1a,$1c,$1e, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20
;  !byte $00,$00,$01, $19,$1b,$1d,$1f, $11,$13,$15,$17, $19,$1b,$1d,$1f, $11,$13,$15,$17, $19,$1b,$1d,$1f, $02, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20, $20,$20,$20,$20




; charset0 = $4000-$40ff
; screen = $4400-$47ff
; charset1 = $4800-$48ff


!ifdef release {
  sprites = $4900
  sprites2 = $51c0
  sprites3 = $5a80
  sprites4 = $6340
}

!ifndef release {
  *= $4900
sprites:
  !bin "../textrotator/blender/pex_torus5_1.spr"
sprites2:
  !bin "../textrotator/blender/pex_torus5_2.spr"
sprites3:
  !bin "../textrotator/blender/pex_torus5_3.spr"
sprites4:
  !bin "../textrotator/blender/pex_torus5_4.spr"








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



;THE CODE BELOW IS NORMALLY "LEFTOVERS" IN MEMORY from the textrotator parts.
;The vital code (jmp $c103) is preserved here to be able to compile a standalone version of Lazy:

charset = $4000
charset1 = $4800

* = $c100

;When we get here, there's a sprite mat with the karate girl going, and a ghostbytescroller in the lower border.
;We need to play nice with the ghostbytescroller to make sure that it's not interrupted.

  nop
  nop
  nop

;This is at $c103, where the lazy part can find it:
  jmp fine_tune


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
  and #$70
  ora anim_poiR+1
  sta blit_poi_A+1
  clc
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
  and #$f
  sta low_how_many+1
  eor #$f
  clc
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
  and #$70
  ora anim_poiR+1
  sta blit_poi+1
  clc
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
  lda blit_ypos+1
  clc
  adc #$ff
  sta blit_ypos+1

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

}


