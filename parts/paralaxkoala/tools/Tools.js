var labelCounter = 0;
module.exports.bin = function(inv){
	return parseInt(inv, 2);
}

var uniqueLabel = module.exports.uniqueLabel = function(){
	
	labelCounter++;
	return "label" + labelCounter;

}

var c64Val = module.exports.c64Val = function(n){
	if (typeof n == "string") {
		return n;
	}
	n = n.toString(16);
	while(n.length<2){
		n = "0" + n;
	}
	return "#$" + n;
}
var c64Address = module.exports.c64Address = function(n){
	
	if (typeof n == "string") {
		return n;
	}
	else if (n.label != undefined) {
		return n.label;
	}
	var numDigits = n <256 ? 2 : 4;
	n = n.toString(16);
	while(n.length<numDigits){
		n = "0" + n;
	}
	return "$" +n;
}
var pc = module.exports.pc = function(address){
	return `.pc = ${c64Address(address)}`;
}
var nop = module.exports.nop = function(num){
	if (!num) {
		num = 1;
	}
	i = "";
	for(var t = 0;t<num;t++){
		i+= "nop\n";
	}
	return i;
}

var simple = ["tax", "tay","clc", "sec", "dex", "dey", "inx", "iny", "txa", "tya",  
"pha", "pla", "sei", "cli", "rol", "ror", "asl", "lsr", "cld", "clv", "php", "rti", "rts", "sed", "tsx", "txs"];
for(var t = 0;t<simple.length;t++){
	this[simple[t]] = module.exports[simple[t]] = Function(`return "${simple[t]}"`);
}
var branch = ["bne", "beq", "bcc", "bcs", "bmi", "bpl", "bvc", "bvs"];
for(var t = 0;t<branch.length;t++){
	eval("this[branch[t]] = module.exports[branch[t]] = function(address){ return '" + branch[t] +" '+ c64Address(address)}");
}
var abs = ["adc", "cmp", "dec", "inc", "jmp", "lda", "ldx", "ldy", "sta", "stx", "sty", "cpx", "cpy", "rol", "ror", "asl", "lsr"];
for(var t = 0;t<abs.length;t++){
	eval("this[abs[t] + '_abs'] = module.exports[abs[t] + '_abs'] = function(address){ return '" + abs[t] +" '+ c64Address(address)}");
}

var abs_x = ["adc", "cmp", "dec", "inc", "jmp", "lda", "ldy", "sta", "stx", "sty", "cpx", "cpy", "rol", "ror", "asl", "lsr"];
for(var t = 0;t<abs_x.length;t++){
	eval("this[abs_x[t] + '_abs_x'] = module.exports[abs_x[t] + '_abs_x'] = function(address){ return '" + abs_x[t] +" '+ c64Address(address) + ',x'}");
}

var abs_y = ["adc", "cmp", "dec", "inc", "jmp", "lda", "ldx", "sta", "stx", "sty", "cpx", "cpy"];
for(var t = 0;t<abs_y.length;t++){
	eval("this[abs_y[t] + '_abs_y'] = module.exports[abs_y[t] + '_abs_y'] = function(address){ return '" + abs_y[t] +" '+ c64Address(address) + ',y'}");
}

var lda_zp_y = module.exports.lda_zp_y = function(address){
	return `lda (${c64Address(address)}),y`;
}
var sta_zp_y = module.exports.sta_zp_y = function(address){
	return `sta (${c64Address(address)}),y`;
}

var cpx_imm = module.exports.cpx_imm = function(value){
	return `cpx ${c64Val(value)}`;
}
var cpy_imm = module.exports.cpy_imm = function(value){
	return `cpy ${c64Val(value)}`;
}

var jsr = module.exports.jsr =  function(address){
	return `jsr ${c64Address(address)}`;
}

var lda_imm = module.exports.lda_imm = function(value){
	return `lda ${c64Val(value)}`;
}

var ldx_imm = module.exports.ldx_imm = function(value){
	return `ldx ${c64Val(value)}`;
}

var ldy_imm = module.exports.ldy_imm = function(value){
	return `ldy ${c64Val(value)}`;
}



var e = module.exports;

var mova_imm = module.exports.mova_imm = function(value, moveto){
	return [
		lda_imm(value), 
		e.sta_abs(moveto)
	].join("\n");
}
var mova_abs_x = module.exports.mova_abs_x = function(movefrom, moveto){
	return [
		e.lda_abs_x(movefrom),
		e.sta_abs_x(moveto)
	].join("\n");
}
var mova_abs_y = module.exports.mova_abs_y = function(movefrom, moveto){
	return [
		e.lda_abs_y(movefrom),
		e.sta_abs_y(moveto)
	].join("\n");
}

var forx = module.exports.forx = function(from, to, operations){
	var valuechange = (from-to)<1 ? e.inx():e.dex();	
	operations = Array.isArray(operations) ? operations : [operations];
	operations.push(valuechange);
	var comparison = to == 0 ? [] : cpx_imm(to);	
	return {
				setup:ldx_imm(from),
				whilenot:comparison,
				do:operations
	}
}

var fory = module.exports.fory = function(from, to, operations){
	var valuechange = (from-to)<1 ? e.iny():e.dey();	
	operations = Array.isArray(operations) ? operations : [operations];
	operations.push(valuechange);
	var comparison = to == 0 ? [] : cpy_imm(to);	
	return {
				setup:ldy_imm(from),
				whilenot:comparison,
				do:operations
	}
}

var irqSetup = module.exports.irqSetup = function(irq){
	return [
		mova_imm("#<" + irq.label, 0xfffe),
		mova_imm("#>" + irq.label, 0xffff),
		mova_imm(irq.rasterpos, 0xd012)
	].join("\n");		
}

var fill = module.exports.fill = function(fromaddress, toaddress, value){
		var operations = [];
		var length = toaddress-fromaddress;
		var wholeHundreds =  (length - (length%256))/256;
		operations.push(lda_imm(value));
		if (wholeHundreds>0) {
			var setops = [];
			for(var t = 0;t<wholeHundreds;t++){
				setops.push(e.sta_abs_x(fromaddress + t*256));
			}
			operations.push(forx(0x00, 0x00, setops));			
		}		
		if(length%256 != 0){
			operations.push(forx(0x00, length%256, [e.sta_abs_x(fromaddress + wholeHundreds*256)]));			
		}
		return operations;
}

var transfer = module.exports.transfer = function(fromaddress, toaddress, length){
	var operations = [];
		var wholeHundreds =  (length - (length%256))/256;
		if (wholeHundreds>0) {
			var setops = [];
			for(var t = 0;t<wholeHundreds;t++){
				setops.push(mova_abs_x(fromaddress + t*256, toaddress + t*256));
			}
			operations.push(forx(0x00, 0x00, setops));			
		}		
		if(length%256 != 0){
			operations.push(forx(0x00, length%256, [mova_abs_x(fromaddress + wholeHundreds*256, toaddress + wholeHundreds*256)]));			
		}
		return operations;
}

var bank0000 = module.exports.bank0000 = function(){
	return mova_imm(0x03, 0xdd00);
}
var bank4000 = module.exports.bank4000 = function(){
	return mova_imm(0x02, 0xdd00);
}
var bank8000 = module.exports.bank8000 = function(){
	return mova_imm(0x01, 0xdd00);
}
var bankC000 = module.exports.bankC000 = function(){
	return mova_imm(0x00, 0xdd00);
}

var setScreenAndCharLocation = module.exports.setScreenAndCharLocation = function(screen, charset){
	var value = ((screen & 0x3FFF) / 64) | ((charset & 0x3FFF) / 1024);
	return mova_imm(value, 0xd018);
}

var main = module.exports.main = function (add){
	var address = add.label ? add.label : add.pc;
	var c = "";
	c+= ".pc = $0801 \"basic startup\"\n";
	c+= ":BasicUpstart(" + address + ")\n";
	c+=add.getCode();
	return c;
}

var fromFile = module.exports.fromFile = function (f) {
	var fs = require("fs");
	var text = "// included from file: " + f + "\n";
  	text+= fs.readFileSync(f).toString();
  	text+= "\n// end include \n";
  	return text;
}

var showKoala = module.exports.showKoala = function(){
	return [
		mova_imm(0xd8, 0xd016),
		mova_imm(0x3b, 0xd011),
	].join("\n");
}
var str = "";
var x = 21;
for(var t in module.exports){
	str += t + ", ";
	if (x++ %20 == 0) {
		str+= "\n";
	}
}
//console.log(str);
