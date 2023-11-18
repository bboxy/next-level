.pc = $4880
.var screen1 = $0400
.var screen2 = $2400

.var charset = $2000
.var charoffset = $0c
.var bankswitch = $0b
.var byteHolder1 = $1e
.var byteHolder2 = $0e
.var byteHolder3 = $20
.var byteHolder4 = $21
.var byteHolder5 = $22
.var byteHolder6 = $23
.var byteHolder7 = $24
.var byteHolder8 = $25
.var byteHolder9 = $26
.var counter1 = $10
.var counter2 = $11
.var counter3 = $14
.var sineValue1 = $12
.var sineValue2 = $13
.var blobLookup = $e000
.macro doWeigth(t,y,u,byteHolder){
		.if(u != 0 && u != 7){
			lda blobLookup + (t*8 + 0)*65 + (u + y*8),y
			adc blobLookup + (t*8 + 0) + (u + y*8)*65,x
			rol byteHolder
		}

		.if(u == 7){
			lsr byteHolder1
			lsr byteHolder1
			rol byteHolder
		}

		lda blobLookup + (t*8 + 1)*65 + (u + y*8),y
		adc blobLookup + (t*8 + 1) + (u + y*8)*65,x
		rol byteHolder

		lda blobLookup + (t*8 + 2)*65 + (u + y*8),y
		adc blobLookup + (t*8 + 2) + (u + y*8)*65,x
		rol byteHolder

		lda blobLookup + (t*8 + 3)*65 + (u + y*8),y
		adc blobLookup + (t*8 + 3) + (u + y*8)*65,x
		rol byteHolder

		lda blobLookup + (t*8 + 4)*65 + (u + y*8),y
		adc blobLookup + (t*8 + 4) + (u + y*8)*65,x
		rol byteHolder

		lda blobLookup + (t*8 + 5)*65 + (u + y*8),y
		adc blobLookup + (t*8 + 5) + (u + y*8)*65,x
		rol byteHolder

		lda blobLookup + (t*8 + 6)*65 + (u + y*8),y
		adc blobLookup + (t*8 + 6) + (u + y*8)*65,x
		.if(u != 0 && u != 7){
			rol byteHolder
			lda blobLookup + (t*8 + 7)*65 + (u + y*8),y
			adc blobLookup + (t*8 + 7) + (u + y*8)*65,x
			rol byteHolder
		}
		.if(u == 0 || u == 7){
			rol byteHolder
		}
		

}
.for(var t = 0;t < 8;t++){
	.for(var y =0;y<8;y++){
		// these two bits are saved for later (last row of char)
		lda blobLookup + (t*8 + 7)*65 + (7 + y*8),y
		adc blobLookup + (t*8 + 7) + (7 + y*8)*65,x
		rol byteHolder1
		lda blobLookup + (t*8 + 0)*65 + (7 + y*8),y
		adc blobLookup + (t*8 + 0) + (7 + y*8)*65,x
		rol byteHolder1

		// these two bits are saved for later (first row of char)
		lda blobLookup + (t*8 + 7)*65 + (0 + y*8),y
		adc blobLookup + (t*8 + 7) + (0 + y*8)*65,x
		rol byteHolder1
		lda blobLookup + (t*8 + 0)*65 + (0 + y*8),y
		adc blobLookup + (t*8 + 0) + (0 + y*8)*65,x
		lda byteHolder1
		rol

		and	#%00001111
		beq !set+
		cmp #%00001111
		bne !+
		//lda #%11111111
		adc #$ef		//clear carry again, else set due to compare
		!set:

		tsx
		/* // save $350 bytes, use more cycles
			ldy #$08
			!r:
			sta charset + t*8 +0 + y*8*16,x

			inx
			dey
			bne !r-
			ldy sineValue1
			*/
		
			
			sta charset + t*8 +0 + y*8*16,x
			sta charset + t*8 +1 + y*8*16,x
			sta charset + t*8 +2 + y*8*16,x
			sta charset + t*8 +3 + y*8*16,x
			sta charset + t*8 +4 + y*8*16,x
			sta charset + t*8 +5 + y*8*16,x
			sta charset + t*8 +6 + y*8*16,x
			
			//sta charset + t*8 +7 + y*8*16,x - is reused from last doWeight
		

		
		jmp !cont+		//will make use of the sta charset,x and ldx sineValue2 from last doWeight(t,y,7)
		!:
		
		sta byteHolder2	
		:doWeigth(t,y,0,byteHolder2)
		:doWeigth(t,y,1,byteHolder3)
		:doWeigth(t,y,2,byteHolder4)
		:doWeigth(t,y,3,byteHolder5)
		:doWeigth(t,y,4,byteHolder6)
		:doWeigth(t,y,5,byteHolder7)
		:doWeigth(t,y,6,byteHolder8)
		:doWeigth(t,y,7,byteHolder9)

		tsx
		lda byteHolder2
		cmp #$80 // copy bit #7 to carry
		rol
		sta charset + t*8 + 0 + y*8*16,x
		lda byteHolder3
		sta charset + t*8 + 1 + y*8*16,x
		lda byteHolder4
		sta charset + t*8 + 2 + y*8*16,x
		lda byteHolder5
		sta charset + t*8 + 3 + y*8*16,x
		lda byteHolder6
		sta charset + t*8 + 4 + y*8*16,x
		lda byteHolder7
		sta charset + t*8 + 5 + y*8*16,x
		lda byteHolder8
		sta charset + t*8 + 6 + y*8*16,x
		
		lsr byteHolder1
		lda byteHolder9
		rol
	!cont:
		sta charset + t*8 + 7 + y*8*16,x
		
		ldx sineValue2
	}
}

//			lda byteHolder2
//			cmp #$80 // copy bit #7 to carry
//			rol
//			sta charset + t*8 +0 + y*8*16,x
//			lda byteHolder3
//			rol
//			sta charset + t*8 +1 + y*8*16,x
//			lda byteHolder4
//			rol
//			sta charset + t*8 +2 + y*8*16,x
//			lda byteHolder5
//			rol
//			sta charset + t*8 +3 + y*8*16,x
//			lda byteHolder6
//			rol
//			sta charset + t*8 +4 + y*8*16,x
//			lda byteHolder7
//			rol
//			sta charset + t*8 +5 + y*8*16,x
//			lda byteHolder8
//			rol
//			sta charset + t*8 +6 + y*8*16,x
//			lsr byteHolder1
//			lda byteHolder9
//			rol
//			sta charset + t*8 +7 + y*8*16,x
