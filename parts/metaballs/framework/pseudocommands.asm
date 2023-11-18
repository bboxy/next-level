#importonce

.pseudocommand f16 address:val {
	lda # <val.getValue()
	sta address.getValue()
	lda # >val.getValue()
	sta address.getValue() +1
}

.pseudocommand inc16 arg {
    inc arg
    bne over
    inc arg.getValue()+1
over:
}

.pseudocommand f address:end:val {	
	.if(val.getType()==AT_NONE){
		.var fillValue = end.getValue()		
		lda # fillValue
		sta address.getValue()
	}
	else{
		.if(end.getValue() - address.getValue() < 256){
			lda # val.getValue()
			ldx # end.getValue() - address.getValue()
			!:
			sta address.getValue() -1,x
			dex
			bne !-	
		}
		else{
			.var diff = end.getValue() - address.getValue()
			lda # val.getValue()
			ldx #$00
			!:
			.var t = 0;
			.for(;t<diff - $100;t+=$100){
				sta address.getValue() + t,x
			}
			.if( address.getValue() + t < end.getValue()){
				sta end.getValue() - $100,x
			}
			inx
			bne !-
		}		
	}	    
}

.pseudocommand m address:end:target {	
	.if(target.getType()==AT_NONE){
		lda address.getValue()
		sta end.getValue()
	}
	else{
		.if(end.getValue() - address.getValue() < 256){		
			ldx # end.getValue() - address.getValue()
			!:
			lda address.getValue() -1,x
			sta target.getValue(),x
			dex
			bne !-	
		}
		else{
			.var diff = end.getValue() - address.getValue()		
			ldx #$00
			!:
			.var t = 0;
			.for(;t<diff - $100;t+=$100){
				lda address.getValue() + t,x
				sta target.getValue() +t,x
			}
			.if( address.getValue() + t < end.getValue()){
				lda end.getValue() - $100,x
				sta target.getValue() + diff - $100,x

			}
			inx
			bne !-
		}		
	}   
}

.pseudocommand fi address:end:val {		
	ldx # val.getValue()
	ldy # 0
	!:
	txa
	sta address.getValue(),y
	inx
	iny
	cpy # end.getValue() - address.getValue()
	bne !-			    
}


