var fs = require('fs');


var inputFile = 'createLoop.prg';

var iterations = 64;
var unpackerAddress = 0xe400;

var binary = fs.readFileSync(inputFile);
var dataDestination = (binary[1] <<8) | binary[0];
binary = binary.slice(2);
var chunklength = binary.length/iterations;
if((binary.length/chunklength) > 0xff){
	console.log("WARNING, support for more than 255 iterations is not implemented")
}


var template = fs.readFileSync('codeGenerator.template', 'utf8');
var data = "";

var dirtyArr = [];
var changesArr= [];
var size = 0;
for(var t = 0;t<binary.length;t++){
	if(t>chunklength){
		var dirty = binary[t] != binary[t-chunklength];		
		if(dirty){
			dirtyArr[t%chunklength] = true;			
		}		
	}
	else{
		dirtyArr[t%chunklength] = false;
	}
}

for(var t = 0;t<binary.length;t++){	
	if(dirtyArr[t%chunklength] == true){
		if(changesArr[t%chunklength] == undefined){
				changesArr[t%chunklength] = [];
		}
		if(t>chunklength){
			var delta = binary[t] - binary[t-chunklength];
			while(delta<0){
				delta += 256;
			}
			changesArr[t%chunklength].push(delta);		
		}		
	}	
}




var dirtyAddressesHB = "dirtyAddressesHB: \n.byte "
var dirtyAddressesLB = "dirtyAddressesLB: \n.byte "
var d = 0
for(var t = 0;t<dirtyArr.length;t++){
	if(dirtyArr[t] == true){
		dirtyAddressesHB += "$" + ((dataDestination + t) >> 8).toString(16) + ", ";
		dirtyAddressesLB += "$" + ((dataDestination + t) & 0xff).toString(16) + ", ";
		size += 2;
		d++;
	}
}


dirtyAddressesHB = dirtyAddressesHB.slice(0, -2);
dirtyAddressesLB = dirtyAddressesLB.slice(0, -2); 
data += "\n" + dirtyAddressesHB;
data += "\n" + dirtyAddressesLB;
//console.log(dirtyAddressesHB);
//console.log(dirtyAddressesLB);

var changeLookupAddressesLB = "changeLookupAddressesLB: \n.byte "
var changeLookupAddressesHB = "changeLookupAddressesHB: \n.byte "
var dataPrefix = "data"

var dataList = "";

var processedChanges = [];
var numberOfDiffs = 0;
for(var t = 0;t<changesArr.length;t++){
	if(changesArr[t] != undefined){
		var changeString = changesArr[t].join(",");
		var found = false;
		var foundIndex = 0;
		for(var i = 0;i<processedChanges.length;i++){
			var savedString = processedChanges[i].join(",");
			if(savedString == changeString){
				found = true;
				foundIndex = i;
			}
		}
		if(!found){
			processedChanges.push(changesArr[t])
			foundIndex = processedChanges.length -1;
			dataList += dataPrefix + "" + foundIndex + ":\n.byte " + changesArr[t].join(",") + "\n";

		}
		changeLookupAddressesLB += "<" + dataPrefix + "" + foundIndex + ", ";
		changeLookupAddressesHB += ">" + dataPrefix + "" + foundIndex + ", ";
		size += 2;
		numberOfDiffs++;
	}	
}
changeLookupAddressesLB = changeLookupAddressesLB.slice(0, -2);
changeLookupAddressesHB = changeLookupAddressesHB.slice(0, -2); 

data += "\n" + changeLookupAddressesLB;
data += "\n" + changeLookupAddressesHB;
data += "\n" + dataList;
//console.log(changeLookupAddressesLB);
//console.log(changeLookupAddressesHB);
//console.log(dataList);
var repeatData = "repeatData: \n.byte "
for(var t = 0;t<chunklength;t++){
	repeatData += binary[t] +", " 
	size++;
}
repeatData = repeatData.slice(0, -2); 
//console.log(repeatData);

data += "\n" + repeatData;
var r = function(s1, s2){
	template = template.split(s1).join(s2);
}

var char = function(i){
	return String.fromCharCode(97 + i);
}

r("<%data%>", data);
r("<%chunklength%>", "$" + chunklength.toString(16));
r("<%datadestination%>", "$" + dataDestination.toString(16));
r("<%unpackerAddress%>", "$" +unpackerAddress.toString(16));
r("<%numberOfCodeLoops%>", "$" + (binary.length/chunklength).toString(16));
r("<%numberOfDiffs%>", "$" + numberOfDiffs.toString(16));


// create loop:
var loop = "ldy #$00" + "\n";
size +=2;
loop += "!:" + "\n";
var t = 0;
for(;t<chunklength;t+=256){

loop += "lda repeatData+ $100*" + (t/256) + ",y" + "\n";
size +=4;
loop += "!" +char(t/256) + ":" + "\n";
loop += "sta dataDestination+ $100*" + (t/256) + ",y" + "\n";
size +=4;
}
t-=256;
if(t<chunklength){
loop += "lda repeatData+ $100*" + (t/256) + "+ $" + (chunklength - t).toString(16) + ",y" + "\n";
size +=4;
loop += "!" + char((t/256)+1) + ":" + "\n";
loop += "sta dataDestination+ $100*" + (t/256)  + "+ $" + (chunklength - t).toString(16) + ",y" + "\n";
size +=4;
t+=256;
}

loop += "iny" + "\n";
size +=2;
loop += "bne !-" + "\n";
size +=2;
while(t >-1){
loop += ":addToLabel16(chunklength, !" + char(t/256) + "-)" + "\n";	
t -= 256;
size +=22;
}
r("<%copyloop%>", loop);




fs.writeFileSync( "codeGeneratorOutput.asm", template)
var newSize = (size + 0x397)// 0x397 from template
console.log("-----------------------------------------------")
console.log("----------     Codegenerator       ------------")
console.log("'codeGeneratorOutput.asm' created")
console.log("Old size: " + binary.length + " ($" + binary.length.toString(16) + ")")
console.log("New size: " + newSize + " ($" + (newSize< 0x1000 ? "0" : "") + newSize.toString(16) + ")")
console.log("Compression: " + Math.floor((newSize/binary.length)*10000)/100  + "% of original")
console.log("Uncompressed memory location: $" + dataDestination.toString(16) + " - $" + (dataDestination + binary.length).toString(16) )// 1175 from template
console.log("-----------------------------------------------")

var includeText = "";
includeText += ".var packedSpeedCodeSize = $" + newSize.toString(16) +"\n"
includeText += ".var unpackedSpeedCodeResident = $" + dataDestination.toString(16) +"\n"
includeText += ".var unpackedSpeedCodeSize = $" + binary.length.toString(16) +"\n"
includeText += ".var unpackerResident = $" + unpackerAddress.toString(16) +"\n"
fs.writeFileSync( "codeGeneratorInclude.asm", includeText)
