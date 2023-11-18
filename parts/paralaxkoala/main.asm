//#define release
.import source "framework/framework.asm"
#if !release
.pc = $0801 "Basic Upstart"
:BasicUpstart(init)
#endif
.var picture = LoadBinary("tools/pwl-branch.kla", BF_KOALA)
 

.var image1location = $4000
.var screen1location = $6000
.var image2location = $c000
.var screen2location = $e000

#if release
.var link_exit = cmdLineVars.get("link_exit").asNumber();
.import source "../../bitfire/macros/link_macros_kickass.inc"
.import source "../../bitfire/loader/loader_kickass.inc"
#endif

*=screen1location;  


.fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$cc00; colorRam:  .fill picture.getColorRamSize(), picture.getColorRam(i)
*=image1location;   //.fill picture.getBitmapSize(), picture.getBitmap(i)
.for(var t = 0;t<picture.getBitmapSize();t++){
	.if(true || mod(t,8*40) < 8*33){
		.byte picture.getBitmap(t)
	}
	else{
		.byte 0
	}
}
.var logobuffer = $e500

.var logostart = $2000

*=$1c00 "Init"
start:
.import source "init.asm"

.pc = * "Bgthread"
.import source "bgthread.asm"

*=$e400 "IRQ"
.import source "irq.asm"


bufferswitch:
.byte 0

cols1:
//.byte $6e,$6e,$6e,$6e,$6e,$6e,$6e,$6e,$6e 
.byte $b6,$be, $b3, $b3, $bd, $b7, $ba, $b8, $111
cols2:
.byte $0e,$03, $0d, $0d, $07, $01, $07, $a, $11
//.byte $03,$03,$03,$03,$03,$03,$03,$03,$03

.var colors = List().add(


List().add($0, $4a4a4a, $332799, $7064d6),//$0 ,$b ,$6 ,$e
List().add($0, $4a4a4a, $7064d6, $6eb7c1),//$0 ,$b ,$e ,$3
List().add($0, $4a4a4a, $6eb7c1, $a3e77c),//$0 ,$b ,$3 ,$d
List().add($0, $4a4a4a, $6eb7c1, $a3e77c),//$0 ,$b ,$3 ,$d
List().add($0, $4a4a4a, $a3e77c, $cbd765),//$0 ,$b ,$d ,$7
List().add($0, $4a4a4a, $cbd765, $ffffff),//$0 ,$b ,$7 ,$1
List().add($0, $4a4a4a, $b46b61, $cbd765),//$0 ,$b ,$a ,$7
List().add($0, $4a4a4a, $85531c, $b46b61)//$0 ,$b ,$8 ,$a
	)

.var tt= 0;
.for(var t = 0;t<8;t+=1){
	.pc = logostart + t*$200
	.var pic = LoadPicture("./tools/column" + t + ".png", colors.get(t))

	.fill 512, pic.getMulticolorByte(0, i)
	
}
