#importonce

// $DD00 = %xxxxxx11 -> bank0: $0000-$3fff
// $DD00 = %xxxxxx10 -> bank1: $4000-$7fff
// $DD00 = %xxxxxx01 -> bank2: $8000-$bfff
// $DD00 = %xxxxxx00 -> bank3: $c000-$ffff



.macro addToLabel16(value16, label){
	lda label + 1
	clc
	adc #<value16
	sta label +1
	lda label + 2
	adc #>value16
	sta label +2
}
.macro incLabel(label){
	inc label +1
	bne !+
	inc label +2
	!:
}

.macro ensureImmediateArgument(arg) {
	.if (arg.getType()!=AT_IMMEDIATE)	.error "The argument must be immediate!" 
}

.pseudocommand nop x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) nop
}

.pseudocommand pause cycles {
	:ensureImmediateArgument(cycles)
	.var x = floor(cycles.getValue())
	.if (x<2) .error "Cant make a pause on " + x + " cycles"

	// Take care of odd cyclecount	
	.if ([x&1]==1) {
		bit $00
		.eval x=x-3
	}	
	
	// Take care of the rest
	.if (x>0)
		:nop #x/2
}


.macro addToLabel(value, label){
	lda label + 1
	clc
	adc #value
	bcc !+
	inc label +2
	!:
	sta label +1
}

.macro subFromLabel(value, label){
	lda label + 1
	sec
	sbc #value
	bcs !+
	dec label +2
	!:
	sta label +1
}


.macro SetupMemory(list){
	.for(var t = 0;t<list.size();t+=2){
		f list.get(t) : list.get(t+1)
	}
}

.macro SetScreenAndCharLocation(screen, charset) {
	lda	#[[screen & $3FFF] / 64] | [[charset & $3FFF] / 1024]
	sta	$D018
}

.macro equalCharPack(filename, screenAdr, charsetAdr) {
	.var charMap = Hashtable()
	.var charNo = 0
	.var screenData = List()
	.var charsetData = List()
	.var pic = LoadPicture(filename)
	.for (var charY=0; charY<25; charY++) {
		.for (var charX=0; charX<40; charX++) {
			.var currentCharBytes = List()
			.var key = ""
			.for (var i=0; i<8; i++) {
				.var byteVal = pic.getSinglecolorByte(charX, charY*8 + i)
				.eval key = key + toHexString(byteVal) + ","
				.eval currentCharBytes.add(byteVal)
			}
			.var currentChar = charMap.get(key)
			.if (currentChar == null) {
				.eval currentChar = charNo
				.eval charMap.put(key, charNo)
				.eval charNo++
				.for (var i=0; i<8; i++) {
					.eval charsetData.add(currentCharBytes.get(i))
				}
			}
			.eval screenData.add(currentChar)
		}
	}
	.pc = screenAdr "screen"
	.fill screenData.size(), screenData.get(i)
	.pc = charsetAdr "charset"
	.fill charsetData.size(), charsetData.get(i)
}

//:equalCharPack("pic.png", $2800, $2000)


//Slammer's example, but adapted by Cruzer
//.var spriteData = $3000
//.pc = spriteData "spriteData"
//.var spritePic = LoadPicture("sprites.png", List().add($000000,$ffffff,$6c6c6c,$959595))
//.for (var i=0; i<8; i++)
//	:getSprite(spritePic, i)

.macro getSprite(spritePic, spriteNoX, spriteNoY) {
	.for (var y=0; y<21; y++){
		.for (var x=0; x<3; x++){
			.byte spritePic.getMulticolorByte(x + spriteNoX * 3, y + spriteNoY * 21)
		}			
	}	
	.byte 0
}

.var brkFile = createFile("breakpoints.txt") 

.macro break() {
    .eval brkFile.writeln("break " + toHexString(*))
}

.enum {
	SCREENMODE_HIRES_TEXT,
	SCREENMODE_MULTICOLOR_TEXT,
	SCREENMODE_HIRES_BITMAP,
	SCREENMODE_MULTICOLOR_BITMAP,
	SCREENMODE_ECM_TEXT
}

.macro SetScreenMode(mode){
	 .var d011Vals = List(SCREENMODE_ECM_TEXT +1)
	 .eval d011Vals.set(SCREENMODE_HIRES_TEXT, $1b)
	 .eval d011Vals.set(SCREENMODE_MULTICOLOR_TEXT, $1b)
	 .eval d011Vals.set(SCREENMODE_HIRES_BITMAP, $3b)
	 .eval d011Vals.set(SCREENMODE_MULTICOLOR_BITMAP, $3b)
	 .eval d011Vals.set(SCREENMODE_ECM_TEXT, $5b)

	.var d016Vals = List(SCREENMODE_ECM_TEXT +1)
	.eval d016Vals.set(SCREENMODE_HIRES_TEXT, $8)
	.eval d016Vals.set(SCREENMODE_MULTICOLOR_TEXT, $18)
	.eval d016Vals.set(SCREENMODE_HIRES_BITMAP, $8)
	.eval d016Vals.set(SCREENMODE_MULTICOLOR_BITMAP, $18)
	.eval d016Vals.set(SCREENMODE_ECM_TEXT, $8)
	f $d011 : d011Vals.get(mode)
	f $d016 : d016Vals.get(mode)

}
.macro OpenLowerBorder () {
	f $d011 : $13
	txa     
!:  inx
	bne !-
	f $d011 : $1b			
}

.macro Sprite4x2_Xpos (xpos) {
	.for(var t = 0;t<4;t++){
		f $d000 + t*2 : xpos + t*24
		f $d008 + t*2 : xpos + t*24		
	}			
}

.macro Sprite4x2_Ypos (ypos) {
	.for(var t = 0;t<4;t++){
		f $d001 +t*2 : ypos
		f $d009 +t*2 : ypos + 21
	}			
}

.macro Sprite4x2(xpos,ypos){
	:Sprite4x2_Xpos(xpos)
	:Sprite4x2_Ypos(ypos)

}
