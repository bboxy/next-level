


init:
sei
#if !release
lda #$35
sta $01
#endif



lda #$0
sta $9f
jsr initzp
#if !release
lda #$02
sta $dd00
lda #$0b
sta $d011
#endif
:SetScreenAndCharLocation(screen1location,image1location)
//:SetScreenAndCharLocation($6400,$4000)

lda #$d8
sta $d016

lda #0
sta $d020
lda #picture.getBackgroundColor()
sta $d021
ldx #0
!loop:

#if !release
lda colorRam+0*$100,x
sta $d800+0*$100,x
lda colorRam+1*$100,x
sta $d800+1*$100,x
lda colorRam+2*$100,x
sta $d800+2*$100,x
lda colorRam+2*$100 + $e8,x
sta $d800+2*$100 + $e8,x

inx
bne !loop-
#endif

dec $01
ldx #$07
!:
.for(var t = 0;t<25;t++){	
	lda cols1,x
	sta screen1location + 32 + t*40,x
	sta screen2location + 32 + t*40,x
}

dex
cpx #$ff
beq !+
jmp !-
!:
inc $01
ldx #$07
!:
.for(var t = 0;t<25;t++){	
	lda cols2,x
	sta $d800 + 32 + t*40,x
}
dex
cpx #$ff
beq !+
jmp !-
!:
dec $01
lda #$00
ldy #$12
ldx #$00
!:
sta logobuffer,x
inx
bne !-
inc !-+2
dey
bne !-
jsr mockupdate
inc $01

lda #$37
sta $d011
//lda #$35
//sta $01
//jmp *
lda #<IRQ1
sta $fffe
lda #>IRQ1
sta $ffff
lda #$fa
sta $d012
lda #$7f
sta $dc0d
lda $dc0d
lda #$01
sta $d019
sta $d01a
cli



