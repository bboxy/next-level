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

Jimp.read('tiles.png', (err, img) => {
      img.crop(0,0,320,200)
      //img.resize(320,200, Jimp.RESIZE_NEAREST_NEIGHBOR)
         var koala = jimpToKoala(img,0)
         
         var fs = require("fs");
          var longInt8View = new Buffer(koala);
          fs.writeFileSync("tiles1" + ".kla", longInt8View);
         
         var jimp = jimpFromKoalaBytes(koala)
         jimp.write('tiles1.png')
         
   });
	
Jimp.read('tiles.png', (err, img) => {
      img.crop(320 - 16,0,320,200)
      //img.resize(320,200, Jimp.RESIZE_NEAREST_NEIGHBOR)
         var koala = jimpToKoala(img,0)
         
         var fs = require("fs");
          var longInt8View = new Buffer(koala);
          fs.writeFileSync("tiles2" + ".kla", longInt8View);
         
         var jimp = jimpFromKoalaBytes(koala)
         jimp.write('tiles2.png')
         
   });

Jimp.read('tiles.png', (err, img) => {
      img.crop(-16 + 320*2,0,20*8,200)
      var img2 = new Jimp(320,200, 0x000000ff);
      img2.blit(img, 0, 0)
      //img.resize(320,200, Jimp.RESIZE_NEAREST_NEIGHBOR)
         var koala = jimpToKoala(img2,0)
         
         var fs = require("fs");
          var longInt8View = new Buffer(koala);
          fs.writeFileSync("tiles3" + ".kla", longInt8View);
         
         var jimp = jimpFromKoalaBytes(koala)
         jimp.write('tiles3.png')
         
   });


