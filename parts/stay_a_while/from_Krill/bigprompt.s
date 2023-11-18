#!/usr/bin/env -S 64tass --m6502 --ascii -o bigprompt.prg

; assumes any installed interrupt handler ($fffe/f) to buffer and restore $01

.weak
STANDALONE = 1
.endweak

SCREEN     = $0400
SCREEN2    = $0c00
ZP         = $02

SCREENPTR  = ZP
POINTER    = ZP + 2
ROWCOUNT   = ZP + 4
CHARUPPER  = ZP + 5
CHARLOWER  = CHARUPPER + 1

CHAREN     = $31
CHARDIS    = $35
CHARGEN    = $d000

IOPORT     = $01

.if STANDALONE
                * = $0801

LINENUMBER        = 2023

                .byte <zero, >zero, <LINENUMBER, >LINENUMBER, $9e
                .text format("%d", init)
zero            .byte 0

init            ldx #0

                sei
                jmp start
.else
                * = $f800
.endif

start           lda #CHAREN
                sta IOPORT

                ldx #<SCREEN
                stx SCREENPTR
                lda #>SCREEN
                sta SCREENPTR + 1
                lda #' '
-               sta SCREEN + 1000 - $0100,x
                inx
                bne -

row             lda #10
                sta ROWCOUNT

plot            lda text,x
                beq done

                ldy #>(CHARGEN >> 3)
                sty POINTER + 1

                asl
                rol POINTER + 1
                asl
                rol POINTER + 1
                asl
                rol POINTER + 1
                sta POINTER

char            ldy #0
                lda (POINTER),y
                sta CHARUPPER
                inc POINTER
                lda (POINTER),y
                sta CHARLOWER
                inc POINTER

doubleline      tya
                asl CHARUPPER
                rol
                asl CHARLOWER
                rol
                asl CHARUPPER
                rol
                asl CHARLOWER
                rol
                tay
                lda translate,y

                ldy #0
                sta (SCREENPTR),y
                inc SCREENPTR
                bne +
                inc SCREENPTR + 1
+
                lda #%00000011
                and SCREENPTR
                bne doubleline

                clc
                lda #40 - 4
                adc SCREENPTR
                sta SCREENPTR
                bcc +
                inc SCREENPTR + 1
+
                lda #%00000111
                and POINTER
                bne char

                sec
                lda SCREENPTR
                sbc #<((40 * 4) - 4)
                sta SCREENPTR
                bcs +
                dec SCREENPTR + 1
+
                inx

                dec ROWCOUNT
                bne plot

                clc
                lda #<(40 * 3)
                adc SCREENPTR
                sta SCREENPTR
                bcc row
                inc SCREENPTR + 1
                bcs row; jmp


done            lda #CHARDIS
                sta IOPORT

                ldx #0
-               lda SCREEN,x
                sta SCREEN2,x
                lda SCREEN + $0100,x
                sta SCREEN2 + $0100,x
                lda SCREEN + $0200,x
                sta SCREEN2 + $0200,x
                lda SCREEN + (5 * 40 * 4) - $0100,x
                sta SCREEN2 + (5 * 40 * 4) - $0100,x
                lda #' '
                sta SCREEN2 + (5 * 40 * 4) - $38,x
                inx
                bne -

                lda #$03
                sta $dd00

                lda #$06
                sta $d021
                lda #$0e
                sta $d020
-               sta $d800,x
                sta $d900,x
                sta $da00,x
                sta $db00,x
                inx
                bne -

                lda #$1b
                sta $d011
                lda #$08
                sta $d016
                lda #$14
                sta $d018

loop            ldx #(20 * 50 / 60) + 1
-               bit $d011
                bpl -
-               bit $d011
                bmi -
                dex
                bne --
                lda #$14 ^ $34
                eor $d018
                sta $d018
                jmp loop

translate       .byte ' ', $6c, $7c, $e1
                .byte $7b, $62, $ff, $fe
                .byte $7e, $7f, $e2, $fb
                .byte $61, $fc, $ec, $a0

                .enc "screen"

text            .text "ready.    "
                .text "next level"
                .text "?syntax  e"
                .text "ready.    "
                .text "performers"
                .byte $a0
                .text  "         "
                .byte 0
