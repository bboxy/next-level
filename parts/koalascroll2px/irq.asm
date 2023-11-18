

IRQ1:
sta zpa
stx zpx
sty zpy
lda $01
sta zp1
lda #$35
sta $01
inc $d019
//inc framecount

/*inc $d020

ldx #$71
!:
dex 
bne !-
dec $d020*/
//inc $d020
//jsr music_play
#if release
//jsr link_music_play_side4_micro
#else
//jsr music_play
#endif
//dec $d020

dec d016count
lax d016count
bne !+
ldy #16
sty d016count
!:
ldy tabled016,x
sty $d016
cpy #$f6
beq !move+

lda zp1
sta $01
lda zpa
ldx zpx
ldy zpy
rti

!move:

block:// block first run
bit moveColorRam// becomes jump

lda #$4c
sta block 

lda zp1
sta $01
lda zpa
ldx zpx
ldy zpy
rti



tabled016:

.byte $f0, $f2, $f4, $f6, $f0, $f2, $f4, $f6, $f0, $f2, $f4, $f6, $f0, $f2, $f4, $f6

//    000, 001, 002, 003, 004, 005, 006, 007, 008, 009, 010, 011, 012, 013, 014, 015

//tableJump:
//.byte $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01 

tableDD00:
.byte $02, $02, $02, $02, $03, $03, $03, $03, $00, $00, $00, $00, $01, $01, $01, $01
tableD018:
.byte [[screen3 & $3FFF] / 64] | [[bitmap3 & $3FFF] / 1024] //0
.byte [[screen3 & $3FFF] / 64] | [[bitmap3 & $3FFF] / 1024] //0
.byte [[screen3 & $3FFF] / 64] | [[bitmap3 & $3FFF] / 1024] //0
.byte [[screen3 & $3FFF] / 64] | [[bitmap3 & $3FFF] / 1024] //0


.byte [[screen2 & $3FFF] / 64] | [[bitmap2 & $3FFF] / 1024] //0
.byte [[screen2 & $3FFF] / 64] | [[bitmap2 & $3FFF] / 1024] //0
.byte [[screen2 & $3FFF] / 64] | [[bitmap2 & $3FFF] / 1024] //0
.byte [[screen2 & $3FFF] / 64] | [[bitmap2 & $3FFF] / 1024] //0

.byte [[screen1 & $3FFF] / 64] | [[bitmap1 & $3FFF] / 1024] //0
.byte [[screen1 & $3FFF] / 64] | [[bitmap1 & $3FFF] / 1024] //0
.byte [[screen1 & $3FFF] / 64] | [[bitmap1 & $3FFF] / 1024] //0
.byte [[screen1 & $3FFF] / 64] | [[bitmap1 & $3FFF] / 1024] //0

.byte [[screen0 & $3FFF] / 64] | [[bitmap0 & $3FFF] / 1024] //0
.byte [[screen0 & $3FFF] / 64] | [[bitmap0 & $3FFF] / 1024] //0
.byte [[screen0 & $3FFF] / 64] | [[bitmap0 & $3FFF] / 1024] //0
.byte [[screen0 & $3FFF] / 64] | [[bitmap0 & $3FFF] / 1024] //0


// $DD00 = %xxxxxx11 -> bank0: $0000-$3fff
// $DD00 = %xxxxxx10 -> bank1: $4000-$7fff
// $DD00 = %xxxxxx01 -> bank2: $8000-$bfff
// $DD00 = %xxxxxx00 -> bank3: $c000-$ffff
