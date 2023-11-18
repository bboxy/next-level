!convtab scr
!cpu 6510

RAW = 1
CHECKSUM = 1
REQDISC = 1

!src "../bitfire/loader/loader_acme.inc"
!src "../bitfire/macros/link_macros_acme.inc"

    * = $1000
!bin "../bitfire/loader/installer",,2
    * = $0800
    lda #$0b
    sta $d020
    sta $d021

    jsr bitfire_install_

    sei
    lda #$35
    sta $01

    lda #$04
    sta $d020
    sta $d021

    ldx #$40
copy_more:
    lda super_cool_bootloader,x
    sta $cf00,x
    dex
    bpl copy_more
    jmp $cf00

super_cool_bootloader:
    lda #$00
    sta $d020
    sta $d021
    ldx #0
clrcols:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $dae8,x
    inx
    bne clrcols

; The part below is supposed to load packed code from overload.lz into $0400-$bfff. / Pex

    lda #$00
    jsr bitfire_loadcomp_

;freeze:
;    inc $d020
;    lda #0
;    beq freeze

    jmp $0400
