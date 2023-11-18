const {Jimp, jimpFromKoalaPath, jimpFromKoalaBytes, jimpToKoala, closestC64ColorIndex} = require("./JimpToolsChanged.js");

/*var t = 1

var convert = function(t){
	var tt = t + ""
	while (tt.length<4){
		tt = "0"+ tt
	}
	Jimp.read('out/' + tt + '.png', (err, img) => {
		img.resize(320,200, Jimp.RESIZE_NEAREST_NEIGHBOR)
   		var koala = jimpToKoala(img,256)
   		if(t == 1){
   			var fs = require("fs");
		    var longInt8View = new Buffer(koala);
		    fs.writeFileSync("firstframe" + ".kla", longInt8View);
   		}
   		var jimp = jimpFromKoalaBytes(koala)
   		jimp.write('out/m' + t + '.png')
   		t = t+1
   		if (t<212){
   			console.log("k" + t)
   			convert(t)
   		}
	});
}

convert(t)*/


//tileset1

Jimp.read('stam-4.bmp', (err, img) => {
      img.crop(0,0,320,200)
      //img.resize(320,200, Jimp.RESIZE_NEAREST_NEIGHBOR)
         var koala = jimpToKoala(img,256)
         
         var fs = require("fs");
          var longInt8View = new Buffer(koala);
          fs.writeFileSync("stam" + ".kla", longInt8View);
         
         var jimp = jimpFromKoalaBytes(koala)
         jimp.write('convert.png')
         
   });

var k = jimpFromKoalaPath("side-logo-1.kla")
k.write('logo1.png')

	


