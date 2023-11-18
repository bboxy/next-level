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
var compareLightness = function(a,b){
   var aA = Jimp.intToRGBA(a);
   var bB = Jimp.intToRGBA(b);

   return  (aA.r + aA.g + aA.b)- (bB.r + bB.g + bB.b);

}

//tileset1
var colorsInImageSorted = function(img){
   var colors = [];
   for(var y = 0;y<img.bitmap.height;y++){
      for(var x = 0;x<img.bitmap.width;x++){
         if(colors.indexOf(img.getPixelColor(x,y)) == -1){
            colors.push(img.getPixelColor(x,y));
            if(colors.length > 4){
               console.log("stray pixel at: " + x+ ":" + y);
            }
         }
      }
   }
   colors.sort(compareLightness);
   return colors;
}

var kickassFormatColors = function(a){
   var formatted = [];
   var comment = [];
   for(var t = 0;t<a.length;t++){
      var aA = Jimp.intToRGBA(a[t]);
      var withoutAlpha = a[t]; 
      withoutAlpha = Math.floor(withoutAlpha/256);
      formatted.push("$" + withoutAlpha.toString(16))
      comment.push("$" + closestC64ColorIndex(a[t]).toString(16));

   }

   return "List().add(" + formatted.join(", ") + ")," + "//" + comment.join(" ,");
}

//Jimp.intToRGBA(
Jimp.read('upscroll6d.png', (err, img) => {
      for(var t = 0;t<8;t++){
         var p = img.clone();
         p.crop(p.bitmap.width - (8-t)*8, 0, 8, p.bitmap.height);
         console.log(kickassFormatColors(colorsInImageSorted(p)));
         p.write("column" + t + ".png");
      }
      
         
   });


	


