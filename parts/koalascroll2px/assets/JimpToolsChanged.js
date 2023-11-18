
var {bin,uniqueLabel, c64Val, c64Address, pc, tax, tay, clc, sec, dex, dey, inx, iny, txa, tya, nop, pha, pla, sei, cli, rol, 
ror, asl, lsr, cld, clv, php, rti, rts, sed, tsx, txs, bne, beq, bcc, bcs, bmi, bpl, bvc, bvs, adc_abs, 
cmp_abs, dec_abs, inc_abs, jmp_abs, lda_abs, ldx_abs, ldy_abs, sta_abs, stx_abs, sty_abs, cpx_abs, cpy_abs, rol_abs, ror_abs, asl_abs, lsr_abs, adc_abs_x, cmp_abs_x, dec_abs_x, inc_abs_x, 
jmp_abs_x, lda_abs_x, ldy_abs_x, sta_abs_x, stx_abs_x, sty_abs_x, cpx_abs_x, cpy_abs_x, rol_abs_x, ror_abs_x, asl_abs_x, lsr_abs_x, adc_abs_y, cmp_abs_y, dec_abs_y, inc_abs_y, jmp_abs_y, lda_abs_y, ldx_abs_y, sta_abs_y, 
stx_abs_y, sty_abs_y, cpx_abs_y, cpy_abs_y, cpx_imm, cpy_imm, jsr, lda_imm, ldx_imm, ldy_imm, mova_imm, mova_abs_x, mova_abs_y, forx, fory, irqSetup, fill, transfer, bank0000, bank4000, 
bank8000, bankC000, setScreenAndCharLocation, main, fromFile, showKoala,} = require("./Tools.js");

var Jimp = require("jimp");
Jimp.prototype.getSingleColorByte = function(x,y){
	var res = 0;
	for(var t = 0;t<8;t++){
		res = res << 1;
		if (this.getPixelColor(x+t, y) != 0x000000ff){
			res += 1;
		}
	}
	//console.log("ok" + this.getPixelColor(x, y))
	return res;
}

Jimp.prototype.getSingleColorSprite = function(x,y){
	var arr = [];
	for(var yy = 0;yy<21;yy++){
		arr.push(this.getSingleColorByte(x,yy+y));
		arr.push(this.getSingleColorByte(x+8,yy+y));
		arr.push(this.getSingleColorByte(x+16,yy+y));
	}
	arr.push(0);
	return arr;
}

Jimp.rgbaObjToInt = function(obj){
	return Jimp.rgbaToInt(obj.r, obj.g, obj.b, obj.a);
}

module.exports.Jimp = Jimp;

var c64Colors =module.exports.c64Colors = [// colodore
Jimp.intToRGBA(0x000000ff),
Jimp.intToRGBA(0xffffffff),
Jimp.intToRGBA(0x813338ff),
Jimp.intToRGBA(0x75cec8ff),
Jimp.intToRGBA(0x8e3c97ff),
Jimp.intToRGBA(0x56ac4dff), 
Jimp.intToRGBA(0x2e2c9bff),
Jimp.intToRGBA(0xedf171ff),
Jimp.intToRGBA(0x8e5029ff),
Jimp.intToRGBA(0x553800ff), 
Jimp.intToRGBA(0xc46c71ff),
Jimp.intToRGBA(0x4a4a4aff),
Jimp.intToRGBA(0x7b7b7bff),
Jimp.intToRGBA(0xa9ff9fff),
Jimp.intToRGBA(0x706debff),
Jimp.intToRGBA(0xb2b2b2ff)

];


var closestC64ColorIndex = module.exports.closestC64ColorIndex = function(color32, optionalAllowedColors){
	var colorObj = Jimp.intToRGBA(color32);
	var closest = 1000000000;
	var closestIndex = 0;
	if (!optionalAllowedColors) {
		optionalAllowedColors = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];
	}
	for(var t = 0;t<c64Colors.length && closest>0;t++){
		var current = c64Colors[t];
		var diffObj = {r:current.r - colorObj.r, g:current.g - colorObj.g, b:current.b - colorObj.b};
		var dist = Math.sqrt(diffObj.r * diffObj.r + diffObj.g * diffObj.g + diffObj.b * diffObj.b);
		if (dist<closest && optionalAllowedColors.indexOf(t) !=-1) {
			closestIndex = t;
			closest = dist;
		}
	}
	return closestIndex;
}

var jimpFromKoalaBytes = module.exports.jimpFromKoalaBytes = function(img){	
var png = new Jimp(320, 200, 0x000000FF);
var imgIndex = 2;
var screenColorIndex = imgIndex+40*25*8;
var colorRamIndex = screenColorIndex + 40*25;
var bgColorIndex = colorRamIndex + 40*25;

for(var y = 0;y<25;y++){
	for(var x = 0;x<40;x++){
		var screenColor = img[screenColorIndex];
		var colorRam = img[colorRamIndex];

		var colors;
		if(!false){
			colors = [img[bgColorIndex], (screenColor & bin("11110000"))>>4, (screenColor & bin("00001111")),colorRam];
		}
		else{
			colors = [0,1,1,1]
		}
		screenColorIndex++;
		colorRamIndex++;
		for(var yy = 0;yy<8;yy++){
			
			var currentByte = img[imgIndex];
			var pixel0 = (currentByte & bin("11000000")) >>6;
			var pixel1 = (currentByte & bin("00110000")) >>4;
			var pixel2 = (currentByte & bin("00001100")) >>2;
			var pixel3 = (currentByte & bin("00000011")) >>0;
			
			var color0 = Jimp.rgbaObjToInt(c64Colors[colors[pixel0]]);
			var color1 = Jimp.rgbaObjToInt(c64Colors[colors[pixel1]]);
			var color2 = Jimp.rgbaObjToInt(c64Colors[colors[pixel2]]);
			var color3 = Jimp.rgbaObjToInt(c64Colors[colors[pixel3]]);


			png.setPixelColor(color0, 8*x,8*y + yy);
			png.setPixelColor(color0, 8*x+1,8*y + yy);
			png.setPixelColor(color1, 8*x+2,8*y + yy);
			png.setPixelColor(color1, 8*x+3,8*y + yy);
			png.setPixelColor(color2, 8*x+4,8*y + yy);
			png.setPixelColor(color2, 8*x+5,8*y + yy);
			png.setPixelColor(color3, 8*x+6,8*y + yy);
			png.setPixelColor(color3, 8*x+7,8*y + yy);
			imgIndex++;
		}
		
	}
}
return png;

}

var jimpFromKoalaPath = module.exports.jimpFromKoalaPath = function(path){	
var fs = require('fs');
var img = fs.readFileSync(path);
return jimpFromKoalaBytes(img)

}




var colorsInChar = function(image,x,y, bgcolor){
	var colors = [bgcolor];
	var use = [];
	for(var yy = 0;yy<8;yy++){
		for(var xx = 0;xx<8;xx++){
			var col = image.getPixelColor(x + xx,y + yy);
			var closestColor = closestC64ColorIndex(col/*, [0,0xe,0x5, 0xa,0x3, 0x2,0x1,0x6,0x7,0x4]*/);
			if (colors.indexOf(closestColor) == -1) {
				colors.push(closestColor);				
			}
			use[closestColor] = use[closestColor] ? use[closestColor]+1 : 1;
		}
	}
	use[0] = 64;
	colors.sort(
          function(x, y){
             return use[y] - use[x];
          }
        );
	while(colors.length>4){
		colors.pop();
	}
	return colors;
}


var jimpToKoala = module.exports.jimpToKoala = function(jimp, bgcolor){
	var d800colors = [];
	var screenColors = [];
	var image = [];
	for(var y = 0;y<25;y++){
		for(var x = 0;x<40;x++){
			var colors = colorsInChar(jimp, x*8, y*8, bgcolor);
			for(var yy = 0;yy<8;yy++){
				var color1 = closestC64ColorIndex(jimp.getPixelColor(8*x,y*8 + yy), colors);
				var color2 = closestC64ColorIndex(jimp.getPixelColor(8*x+2,y*8 + yy), colors);
				var color3 = closestC64ColorIndex(jimp.getPixelColor(8*x+4,y*8 + yy), colors);
				var color4 = closestC64ColorIndex(jimp.getPixelColor(8*x+6,y*8 + yy), colors);
				var bit1 = (colors.indexOf(color1) <<6);
				var bit2 = (colors.indexOf(color2) <<4);
				var bit3 = (colors.indexOf(color3) <<2);
				var bit4 = colors.indexOf(color4);
				image.push((bit1 | bit2 | bit3 | bit4));				
			}
			
			screenColors.push((colors[1])<<4 | colors[2]);
			d800colors.push(colors[3]);
		}
	}
	var bytes = [0x00, 0x60];
	bytes = bytes.concat(image);
	bytes = bytes.concat(screenColors);
	bytes = bytes.concat(d800colors);
	bytes.push(bgcolor);

	return bytes;
}
/*
var test = jimpFromKoala("../jsimg/IMAGE2k_q.kla");
var test2 = jimpFromKoala("../jsimg/IMAGE3k_q.kla");
var combined = new Jimp(320,200,0x000000ff);
for(var y =0;y<200;y++){
	for(var x = 0;x<320;x+=2){
		if(((x-160)*(x-160) + (y-100)*(y-100)) >9000){
			combined.setPixelColor(test.getPixelColor(x,y), x,y);
			combined.setPixelColor(test.getPixelColor(x,y), x+1,y);
		}
		else{
			combined.setPixelColor(test2.getPixelColor(x,y), x,y);
			combined.setPixelColor(test2.getPixelColor(x,y), x+1,y);
		}
	}
}

combined.write("out2.png");


var arr = jimpToKoala(combined, 0);
var fs = require("fs");
var longInt8View = new Buffer(arr);
fs.writeFileSync("test.kla", longInt8View);
//console.log(closestC64ColorIndex(0x1020ebff));
var test2 = jimpFromKoala("test.kla");
test2.write("out.png");*/
