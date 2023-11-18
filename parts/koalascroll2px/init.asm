init:
lda #$1b
sta $d011
jsr waitframe
lda #$35
sta $01
lda #<IRQ1
sta $fffe
lda #>IRQ1
sta $ffff
lda #$fa
sta $d012






