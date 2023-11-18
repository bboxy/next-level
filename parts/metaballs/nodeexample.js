var Jimp = require('jimp');


function weight(x,y, px, py){

	var dist = 1/((px-x)*(px-x) + (py-y)*(py-y))
	var factor = 2.0*192000;
	var w = factor*dist
	w = Math.floor(w);
	if(w >255){
		w = 255
	}
	if(w<32){
		w = 32
	}
	return Math.floor(w)
}

function charweight(x,y, px, py, www){

	if (www == 3){
		www = 3
	}
	else if(www ==2){
		www = 2
	}
	else if(www==1){
		www = 0.5
	}
	
	
	var dist = 1.0/((px-x)*(px-x) + (py-y)*(py-y))
	var factor = www*0.0085*192000;
	var w = factor*dist
	w = Math.floor(w);
	if(w >555){
		w = 555
	}
	if(w<0){
		w = 0
	}
	return Math.floor(w)
}

function inside(point, vs) {
	if(vs == undefined)return false;
    // ray-casting algorithm based on
    // https://wrf.ecse.rpi.edu/Research/Short_Notes/pnpoly.html/pnpoly.html
    
    var x = point[0], y = point[1];
    
    var inside = false;
    for (var i = 0, j = vs.length - 1; i < vs.length; j = i++) {
        var xi = vs[i][0], yi = vs[i][1];
        var xj = vs[j][0], yj = vs[j][1];
        
        var intersect = ((yi > y) != (yj > y))
            && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
        if (intersect) inside = !inside;
    }
    
    return inside;
};


function getChar(ww1,ww2,ww3,ww4){
	/*var fac = 3.00
	ww1*=fac;
	ww2*=fac;
	ww3*=fac;
	ww4*=fac;*/
	var testChar = new Jimp(8, 8,0xffffffff);
	var poly1 = [[-1,-1], [-1, ww1],[8,ww2], [8,-1],[-1,-1]];
	var poly2 = [[-1,-1], [ww1,-1],[ww3,8], [-1,8],[-1,-1]];
	var poly3 = [[-1,8], [-1,8-ww3],[8,8-ww4], [8,8],[-1,8]];
	var poly4 = [[8,-1], [8-ww2,-1],[8-ww4,8], [8,8],[8,-1]];

	for(var y = 0;y<8;y++){
		for(var x = 0;x<8;x++){
			var w1 = charweight(x,y,0,0,ww1)
			var w2 = charweight(x,y,7,0,ww2)
			var w3 = charweight(x,y,0,7,ww3)
			var w4 = charweight(x,y,7,7,ww4)

			var wt = w1+w2+w3+w4  //+x1+x2+x3+x4

			if(wt>255){ 
				var c = Jimp.rgbaToInt(0, 0,0, 0xff);
				testChar.setPixelColor(c,x,y);
			}
/*


			var p = [x,y];
			var pinside = false;
			if(ww1 != 0 && ww2 !=0) pinside |= inside(p,poly1)
			if(ww1 != 0 && ww3 !=0) pinside |= inside(p,poly2)
			if(ww3 != 0 && ww4 !=0) pinside |= inside(p,poly3)
			if(ww2 != 0 && ww4 !=0) pinside |= inside(p,poly4)
			if(pinside){ 
				var c = Jimp.rgbaToInt(0, 0,0, 0xff);
				testChar.setPixelColor(c,x,y);
			}
			else{
				
				var ppoly1,ppoly2,ppoly3,ppoly4
				if(ww1 != 0){
					ppoly1 = [[-1,-1], [-1,ww1+1], [ww1+1,-1], [-1,-1] ];
				}
				if(ww2 != 0){
					ppoly2 = [[8,-1], [8,ww2+1], [7-ww2,-1], [8,-1] ];
				}
				if(ww3 !=0){
					ppoly3 = [[-1,8], [-1,7-ww3], [ww3+1,8], [-1,8] ];
				}
				if(ww4 !=0){
					ppoly4 = [[8,8], [8,7-ww4], [7-ww4,8], [8,8] ];
				}
				pinside = false;
				pinside |= inside(p,ppoly1)
				pinside |= inside(p,ppoly2)
				pinside |= inside(p,ppoly3)
				pinside |= inside(p,ppoly4)
				if(pinside){ 
					var c = Jimp.rgbaToInt(0, 0,0, 0xff);
					testChar.setPixelColor(c,x,y);
				}
			}
*/
		}
	}
	return testChar;
}

var c = getChar(3,0,3,0)
c.write("char.png");


var charset = new Jimp(128, 128,0xffffffff);


for (var a = 0;a<4;a++){
	for (var b = 0;b<4;b++){
		for (var c = 0;c<4;c++){
			for (var d = 0;d<4;d++){
				var index = (a << 6) | (b << 4) | (c << 2) | d;
				var char = getChar(a, b, c, d);	
				var charX = index % 16;
			var charY = Math.floor(index/16);
				charset.blit(char, charX*8, charY*8, 0, 0, 8, 8 );
			}				
		}
	}
}



function normalize(wt0){
	if(wt0 < 0){
			wt0 = 0
		}
	//wt0 = wt0/10;
	if(wt0 >24){
		wt0 = 3
	}
	else if(wt0 >5){
		wt0 = 2
	}	
	else if(wt0 >1){
		wt0 = 1
	}
	else{
		wt0 = 0
	}
			 
		
		if(wt0>0)console.log(wt0)
	return wt0;
}

var p1x = 34;
var p1y = 34;
var p2x =  94;
var p2y =  165;



var canvas = new Jimp(256, 256,0xffffffff);

var canvas2 = new Jimp(256, 256,0xffffffff);
for(var y = 0;y<256;y+=8){
	for(var x = 0;x<256;x+=8){
		var wt0 = weight(x,y,p1x,p1y)+weight(x,y,p2x,p2y) - 255;
		wt0 = normalize(wt0);
		var wt1 = weight(x+7,y,p1x,p1y)+weight(x+7,y,p2x,p2y) - 255;
		wt1 = normalize(wt1);
		var wt2 = weight(x,y+7,p1x,p1y)+weight(x,y+7,p2x,p2y) - 255;
		wt2 = normalize(wt2);
		var wt3 = weight(x+7,y+7,p1x,p1y)+weight(x+7,y+7,p2x,p2y) - 255;
		wt3 = normalize(wt3);
		
		var index = (wt0 << 6) | (wt1 << 4) | (wt2 << 2) | wt3;

		var charX = index % 16;
		var charY = Math.floor(index/16);
		canvas.blit(charset, x,y , charX*8, charY*8, 8, 8 );
				
	}
}
for(var y = 0;y<256;y++){
	for(var x = 0;x<256;x++){

		var w1 = weight(x,y,p1x,p1y)
		var w2 = weight(x,y,p2x,p2y)
		var wt = w1+w2

		if(wt>255){
			var cw = wt - 255
			var c = 0x000000ff//cw  | 0x00000000
			//console.log(cw>>2)
			canvas2.setPixelColor(c,x,y);
		}

	}
}

canvas.write("out.png")
canvas2.write("out2.png")
charset.write("chars.png")



var fs = require('fs'),
    binary = fs.readFileSync('axischars');
    var axischars = new Jimp(256*8, 8,0xffffffff);

function charToColors(c){
	var colors = [];
	for(var m = 0;m<8;m++){
		if(c & 1 == 1){
			colors.push(0x000000ff)
		}else{
			colors.push(0xffffffff)
		}
		c = c >> 1
	}
	return colors;
}

for(var t = 0;t<binary.length;t+=8){
	//console.log(binary[t]);
	for(var k = 0;k<8;k++){
		var char = binary[t+k];
		var colors = charToColors(char)
		for(var g = 0;g <8;g++){
			axischars.setPixelColor(colors[g],t+g,k);
		}
	}

}
axischars.write("axischars.png");

    /*
clc //2
lda $2000,x //4
adc $2000,y //4
rol // set lowest bit, clear carry //2
sta !p1+ +2 //4
lda $2000,x //4
adc $2000,y //4
rol // set lowest bit, clear carry //2
sta !p2+ +2 //4
lda $2000,x //4
adc $2000,y //4
rol // set lowest bit, clear carry //2
sta !p3+ +2 //4
lda $2000,x //4
adc $2000,y //4
rol // set lowest bit, clear carry //2
tay //2
lda lookup4,y //4
p1:
ora lookup1 //4
p2:
ora lookup2 //4
p3:
ora lookup3 //4
ldx $offsetzp //3
sta $0400,x //4
*/
//79 cycles

/*lda #$00 //2
sta $fe//3

lda $2000,x//4
adc $2000,y//5
rol $fe//5
sju ganger
lda $2000,x//4
adc $2000,y//4
lda $fe//3
rol//2
sta $0400,x//4


*/


