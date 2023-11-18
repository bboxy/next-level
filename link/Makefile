CPUS ?= $(shell (nproc --all || sysctl -n hw.ncpu) 2>/dev/null || echo 1)
ifndef single
MAKEFLAGS += --jobs=$(CPUS)
endif

#RELEASE_FLAGS = release=1 ACME=$(ACME) DASM=$(DASM) KICKASS_JAR=$(KICKASS_JAR) JAVA=$(JAVA)
ifdef crt
RELEASE_FLAGS = crt=1 release=1
else
RELEASE_FLAGS = release=1
endif

BASEDIR := ..
include defines.mk

#ACME_EXE := $(shell command -v acme 2> /dev/null)
#DASM_EXE := $(shell command -v dasm 2> /dev/null)

.PHONY: all

all: toolchain
	$(MAKE) -C ./ images
	$(X64) -autostart image1.d64

images: image1.d64 image2.d64 image3.d64 image4.d64
	$(CRTWRITE) $(CRTWRITE_FLAGS) -o demo.bin -b demo $(SIDE1_FILES) $(SIDE2_FILES) $(SIDE3_FILES) $(SIDE4_FILES)

toolchain: dasm bitfire
	$(MAKE) -C $(dir $(SPRITECONV))
	$(MAKE) -C $(dir $(CHARCONV))

acme: force_look
ifndef ACME_EXE
	echo "Building acme..."
	$(MAKE) -C ../util/acme/
endif

dasm: force_look
ifndef DASM_EXE
	echo "Building dasm..."
	$(MAKE) -C ../util/dasm/
endif

bitfire: acme
	$(MAKE) -C ../bitfire $(RELEASE_FLAGS) ACME=$(ACME)

vice: all
	$(X64) -autostart image1.d64

vice1: toolchain
	$(MAKE) -C ./ image1.d64
	$(X64) -autostart image1.d64

vice2: toolchain
	$(MAKE) -C ./ image2.d64
	$(X64) -autostart image2.d64

vice3: toolchain
	$(MAKE) -C ./ image3.d64
	$(X64) -autostart image3.d64

vice4: toolchain
	$(MAKE) -C ./ image4.d64
	$(X64) -autostart image4.d64

##################### SIDE 1 ##################################

SIDE1_PARTS = \
	boot1.prg \
	music1.prg \
	vortex.prg \
	bunny.prg \
	intro.prg \
	balloon.prg \
	makenoise1.prg \
	makenoise2.prg \
	makenoise3.prg \
	makenoise4.prg \
	makenoise5.prg \
	banzai1.prg \
	banzai2.prg \
	banzai3.prg \
	banzai4.prg \
	banzai5.prg \
	banzai6.prg \
	music1b.prg \
	spaceship.prg \
	greetings1.prg \
	greetings2.prg \
	greetings3.prg \
	noisefader1.prg \
	noisefader2.prg \
	stay.prg \
	noisefader3.prg \
	noisefader4.prg \
	noisefader5.prg \
	noisefader6.prg \
	noisefader7.prg \
	noisefader8.prg \
	noisefader9.prg \
	noisefaderA.prg \
	textrotator1.prg \
	textrotator2.prg \
	textrotator3.prg \
	textrotator4.prg \
	textrotator5.prg \
	textrotator6.prg


SIDE1_FILES = $(foreach file, $(SIDE1_PARTS),-b $(file))

image1.d64: bitfire demo $(SIDE1_PARTS) note.prg
#	$(D64WRITE) $(D64WRITE_FLAGS) -c $@ --side 1 -a 21 ../dirart/side1.prg
ifndef crt
	$(D64WRITE) $(D64WRITE_FLAGS) -c $@ --side 1 -a 50 ../dirart/final1.png --boot demo $(SIDE1_FILES) -s note.prg 48
endif

##################### SIDE 2 ##################################
# This is the overload part, filling the whole image2.d64:

SIDE2_PARTS = \
	boot2.prg \
	overload.prg \
	overload2.prg \
	overload3.prg \
	01.bin \
	02.bin \
	03.bin \
	04.bin \
	05.bin \
	06.bin \
	07.bin \
	08.bin \
	09.bin \
	10.bin \
	11.bin \
	12.bin \
	13.bin \
	14.bin \
	15.bin \
	16.bin \
	17.bin \
	18.bin \
	19.bin \
	20.bin \
	21.bin \
	22.bin \
	23.bin \
	24.bin \
	25.bin \
	26.bin \
	27.bin \
	28.bin \
	29.bin \
	30.bin \
	31.bin \
	32.bin \
	33.bin \
	34.bin \
	35.bin \
	36.bin \
	37.bin \
	38.bin \
	39.bin \
	40.bin \
	41.bin \
	42.bin \
	43.bin \
	44.bin \
	45.bin \
	46.bin \
	47.bin \
	48.bin \
	49.bin \
	50.bin \
	51.bin \
	52.bin \
	53.bin \
	54.bin \
	55.bin \
	56.bin \
	57.bin \
	58.bin \
	59.bin \
	60.bin \
	61.bin \
	62.bin \
	63.bin \
	64.bin \
	65.bin \
	66.bin \
	67.bin \
	68.bin \
	69.bin \
	70.bin \
	71.bin \
	72.bin \
	73.bin \
	74.bin \
	75.bin \
	76.bin \
	77.bin \
	78.bin \
	79.bin \
	80.bin \
	81.bin \
	82.bin \
	83.bin \
	84.bin \
	85.bin \
	86.bin \
	87.bin \
	88.bin \
	89.bin \
	90.bin \
	91.bin \
	92.bin \
	93.bin \
	94.bin \
	95.bin \
	96.bin \
	97.bin \
	98.bin \
	99.bin \
	geos.prg

#add -b in front of each file for file-list needed with d64write
SIDE2_FILES = $(foreach file, $(SIDE2_PARTS),-b $(file))

image2.d64: bitfire demo $(SIDE2_PARTS)
ifndef crt
	$(D64WRITE) $(D64WRITE_FLAGS) -c $@ -h mahoney -i \<3 --side 2 --boot demo -a 30 ../dirart/final2.png $(SIDE2_FILES)
endif

##################### SIDE 3 ##################################

SIDE3_PARTS = \
	boot3.prg \
	faithless1.prg \
	faithless2.prg \
	faithless3.prg \
	faithless4.prg \
	basic.prg \
	music3.prg \
	bobvector1.prg \
	bobvector2.prg \
	bobvector3.prg \
	shadow1.prg \
	shadow2.prg \
	fadein1.prg \
	fadein2.prg \
	complex1.prg \
	complex2.prg \
	complexfadeout.prg \
	schwurbel.prg \
	ribbons_fadein.prg \
	ribbons.prg \
	meat.prg \
	metaballs.prg \
	doublevec1.prg \
	doublevec2.prg \
	doublevec3.prg \
	doublevec4.prg \
	doublevec5.prg \
	doublevec6.prg \
	doublevec7.prg \
	hunter1.prg \
	hunter2.prg

SIDE3_FILES = $(foreach file, $(SIDE3_PARTS),-b $(file))

# ToDo: image3.d64 endpart won't start without a proper basic.prg that isn't the same one as on image1.d64 / Pex
image3.d64: bitfire demo $(SIDE3_PARTS) ransom.prg
ifndef crt
	$(D64WRITE) $(D64WRITE_FLAGS) -c $@ --side 3 --boot demo -a 47 ../dirart/final3.png $(SIDE3_FILES) -s ransom.prg 46
endif

##################### SIDE 4 ##################################

SIDE4_PARTS = \
	boot4.prg \
	music4.prg \
	transbox.prg \
	2pxfade.prg \
	scroll1.prg \
	scroll2.prg \
	scroll3.prg \
	parafade1.prg \
	parafade2.prg \
	paralax1.prg \
	paralax2.prg \
	paralax3.prg \
	eagle.prg \
	endpart1.prg \
	endpart2.prg \
	endpart3.prg

SIDE4_FILES = $(foreach file, $(SIDE4_PARTS),-b $(file))

image4.d64: bitfire demo $(SIDE4_PARTS)
ifndef crt
	$(D64WRITE) $(D64WRITE_FLAGS) -c $@ --side 4 --boot demo -a 40 ../dirart/final4.png $(SIDE4_FILES)
endif

##################### BOOTLOADER - GENERIC STUFF ##############

../parts/installer/installer: force_look
	$(MAKE) -C $(dir $@) $(RELEASE_FLAGS) link_exit=256
demo: ../parts/installer/installer
	$(PACKER) $(PACKER_FLAGS) --sfx 0x0900 -o $@ $<

boot1.prg: ../parts/bootstrap/bootstrap1
	cp $< $@

boot2.prg: ../parts/bootstrap/bootstrap2
	cp $< $@

boot3.prg: ../parts/bootstrap/bootstrap3
	cp $< $@

boot4.prg: ../parts/bootstrap/bootstrap4
	cp $< $@

../parts/bootstrap/bootstrap1: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=8192 #vortex

../parts/bootstrap/bootstrap2: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=1024 #overload

../parts/bootstrap/bootstrap3: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=2048	#faithless

../parts/bootstrap/bootstrap4: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=9664	#transbox

../parts/overload/overload: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) overload $(RELEASE_FLAGS) link_exit=0
overload.prg: ../parts/overload/overload
	$(PACKER) $(PACKER_FLAGS) --from 0xa000 --to 0xd000 -o $@ $<
overload2.prg: ../parts/overload/overload
	$(PACKER) $(PACKER_FLAGS) --from 0xe000 -o $@ $<
overload3.prg: ../parts/overload/overload
	$(PACKER) $(PACKER_FLAGS) --to 0x5000 --relocate-packed 0x7000 -o $@ $<

%.bin: ../parts/overload/packer/output/%.raw
	$(PACKER) -o $@ $<

music1.prg: ../music/intro08.prg
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../music/sdi/music.prg: force_look
	$(MAKE) -C $(dir $@) $(notdir $@)
music1b.prg: ../music/sdi/music.prg
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

music3.prg: ../music/Next-Level-OST.prg
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

music4.prg: ../music/JammicroV1_FinallyAsleepFC00.prg
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

#music3.prg: ../music/JammicroV1_FaithlessInsomniaPRG.prg
#	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/bunny/bunny: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=32768	#intro
bunny.prg: ../parts/bunny/bunny
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/bunny2/balloon: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=64000	#makenoise
balloon.prg: ../parts/bunny2/balloon
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/hunter/hunter: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=256	#bootloader side 4
hunter1.prg: ../parts/hunter/hunter
	$(PACKER) $(PACKER_FLAGS) --from 0x5000 --to 0x8000 -o $@ $<
hunter2.prg: ../parts/hunter/hunter
	$(PACKER) $(PACKER_FLAGS) --from 0x2000 --to 0x5000 -o $@ $<

../parts/spaceship/spaceship: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=8192	#greetz
spaceship.prg: ../parts/spaceship/spaceship
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/ransom/ransom: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=0		#bogus
ransom.prg: ../parts/ransom/ransom
	$(PACKER) $(PACKER_FLAGS) --sfx 0x3f40 -o $@ $<

../parts/note/note: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=0		#bogus
note.prg: ../parts/note/note
	$(PACKER) $(PACKER_FLAGS) --sfx 0x2000 -o $@ $<

../parts/geos/geos: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=257	#bootloader side 3
geos.prg: ../parts/geos/geos
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/schwurbel/schwurbel: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=39936	#ribbons fadein
schwurbel.prg: ../parts/schwurbel/schwurbel
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/meatfadein/meat: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=10368	#meatballs
meat.prg: ../parts/meatfadein/meat
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/basicfadeout/basic: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=58360	#bobvector
basic.prg: ../parts/basicfadeout/basic
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/bobvector/sbf: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=32768	#shadow
	#$(MAKE) -C $(dir $@) $(RELEASE_FLAGS) link_exit=16384	#complex
bobvector1.prg: ../parts/bobvector/sbf
	$(PACKER) $(PACKER_FLAGS) --from 0x4000 --to 0xc100 -o $@ $<
bobvector2.prg: ../parts/bobvector/sbf
	$(PACKER) $(PACKER_FLAGS) --from 0xe000 --to 0xffff -o $@ $<
bobvector3.prg: ../parts/bobvector/sbf
	$(PACKER) $(PACKER_FLAGS) --from 0x2000 --to 0x4000 -o $@ $<

../parts/vortex/vortex: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=8192	#bunny
vortex.prg: ../parts/vortex/vortex
	$(PACKER) $(PACKER_FLAGS) --from 0x2000 --to 0xffff -o $@ $<

../parts/logofadein/fadein: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=16384	#complex
fadein1.prg: ../parts/logofadein/fadein
	$(PACKER) $(PACKER_FLAGS) --from 0x2000 --to 0x4000 -o $@ $<
fadein2.prg: ../parts/logofadein/fadein
	$(PACKER) $(PACKER_FLAGS) --from 0xc000 --to 0xcfff -o $@ $<

../parts/nonconvex/complex: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=63488	#complexfadeout
complex1.prg: ../parts/nonconvex/complex
	$(PACKER) $(PACKER_FLAGS) --from 0x3f40 --to 0xcfff -o $@ $<
complex2.prg: ../parts/nonconvex/complex
	$(PACKER) $(PACKER_FLAGS) --relocate-packed 0xe000 --from 0x2c00 --to 0x3400 -o $@ $<

../parts/complexfadeout/triangle: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=17408	#schwurbel
complexfadeout.prg: ../parts/complexfadeout/triangle
	$(PACKER) $(PACKER_FLAGS) --from 0xf800 --to 0xffff -o $@ $<

../parts/shadowscroll/shadow: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=49152	#schwurbel
shadow1.prg: ../parts/shadowscroll/shadow
	$(PACKER) $(PACKER_FLAGS) --from 0xcd00 --to 0xfff0 -o $@ $<
shadow2.prg: ../parts/shadowscroll/shadow
	$(PACKER) $(PACKER_FLAGS) --from 0x4800 --to 0x9d00 -o $@ $<

#../parts/shadowscroll/shadow_fadeout: ../parts/shadowscroll/shadow force_look
#	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=49152	#complex
#shadow_fadeout.prg: ../parts/shadowscroll/shadow_fadeout
#	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/ribbons/fill: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=61440	#metaballs
ribbons.prg: ../parts/ribbons/fill
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/ribbons/ribbons_fadein: ../parts/ribbons/fill force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=61440	#metaballs
ribbons_fadein.prg: ../parts/ribbons/ribbons_fadein
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/intro/intro: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=2048	#bunny balloon
intro.prg: ../parts/intro/intro
	$(PACKER) $(PACKER_FLAGS) --from 0x2000 --to 0xffff -o $@ $<

../parts/banzai/banzai: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=16192	#spaceship62912	#transbox
banzai1.prg: ../parts/banzai/banzai
	$(PACKER) $(PACKER_FLAGS) --from 0x2400 --to 0x8280 -o $@ $<
banzai2.prg: ../parts/banzai/banzai
	$(PACKER) $(PACKER_FLAGS) --from 0x0400 --to 0x2400 -o $@ $<
banzai3.prg: ../parts/banzai/banzai
	$(PACKER) $(PACKER_FLAGS) --prefix-from 0x0400 --from 0x8280 --to 0x9800 -o $@ $<
banzai4.prg: ../parts/banzai/banzai
	$(PACKER) $(PACKER_FLAGS) --from 0xa000 --to 0xd000 -o $@ $<
banzai5.prg: ../parts/banzai/banzai
	$(PACKER) $(PACKER_FLAGS) --prefix-from 0xa000 --from 0xd000 --to 0xfff0 -o $@ $<
banzai6.prg: ../parts/banzai/banzai
	$(PACKER) $(PACKER_FLAGS) --prefix-from 0x0400 --from 0x9800 --to 0xa000 -o $@ $<

../parts/makenoise/makenoise: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=2048	#banzai
makenoise1.prg: ../parts/makenoise/makenoise
	$(PACKER) $(PACKER_FLAGS) --from 0x2400 --to 0x3ffe -o $@ $<
makenoise2.prg: ../parts/makenoise/makenoise
	$(PACKER) $(PACKER_FLAGS) --from 0xb000 --to 0xc000 -o $@ $<
makenoise3.prg: ../parts/makenoise/makenoise
	$(PACKER) $(PACKER_FLAGS) --from 0xc000 --to 0xffff -o $@ $<
makenoise4.prg: ../parts/makenoise/makenoise
	$(PACKER) $(PACKER_FLAGS) --from 0x3ffe --to 0xb000 -o $@ $<
makenoise5.prg: ../parts/makenoise/makenoise
	$(PACKER) $(PACKER_FLAGS) --from 0x0400 --to 0x2400 -o $@ $<

../parts/metaballs/metaballs: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=20480	#doublevec
metaballs.prg: ../parts/metaballs/metaballs
	$(PACKER) $(PACKER_FLAGS) --from 0x2000 --to 0xcfff -o $@ $<

../parts/faithless/faithless: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=8192	#basic
faithless1.prg: ../parts/faithless/faithless
	$(PACKER) $(PACKER_FLAGS) --from 0xd000 --to 0xfff0 -o $@ $<
faithless2.prg: ../parts/faithless/faithless
	$(PACKER) $(PACKER_FLAGS) --from 0x6700 --to 0xd000 -o $@ $<
faithless3.prg: ../parts/faithless/faithless
	$(PACKER) $(PACKER_FLAGS) --from 0x0400 --to 0x4000 -o $@ $<
faithless4.prg: ../parts/faithless/faithless
	$(PACKER) $(PACKER_FLAGS) --prefix-from 0x0400 --from 0x4000 --to 0x6700 -o $@ $<

../parts/koalascroll2px/scroll: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=1024	#parafade
scroll1.prg: ../parts/koalascroll2px/scroll
	$(PACKER) $(PACKER_FLAGS) --from 0x0800 --to 0x2000 -o $@ $<
scroll2.prg: ../parts/koalascroll2px/scroll
	$(PACKER) $(PACKER_FLAGS) --from 0x3f40 --to 0xc000 -o $@ $<
scroll3.prg: ../parts/koalascroll2px/scroll
	$(PACKER) $(PACKER_FLAGS) --from 0xe400 --to 0xfc00 -o $@ $<

../parts/eagle/eagle: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=62464	#endpart
eagle.prg: ../parts/eagle/eagle
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/2pxfade/fade: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=24384	#2px scroll
2pxfade.prg: ../parts/2pxfade/fade
	$(PACKER) $(PACKER_FLAGS) --relocate-packed 0x8000 -o $@ $<

../parts/parallaxfade/fade: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=7168	#paralax
parafade1.prg: ../parts/parallaxfade/fade
	$(PACKER) $(PACKER_FLAGS) --from 0x400 --to 0xe00 -o $@ $<
parafade2.prg: ../parts/parallaxfade/fade
	$(PACKER) $(PACKER_FLAGS) --from 0x4000 --to 0x63e8 -o $@ $<

../parts/paralaxkoala/paralax: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=16192	#eagle
paralax1.prg: ../parts/paralaxkoala/paralax
	$(PACKER) $(PACKER_FLAGS) --from 0x0800 --to 0x4000 -o $@ $<
paralax2.prg: ../parts/paralaxkoala/paralax
	$(PACKER) $(PACKER_FLAGS) --from 0xe000 --to 0xfc00 -o $@ $<
paralax3.prg: ../parts/paralaxkoala/paralax
	$(PACKER) $(PACKER_FLAGS) --from 0x63e8 --to 0xd000 -o $@ $<


../parts/endpart/stage: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=8192
endpart1.prg: ../parts/endpart/stage
	$(PACKER) $(PACKER_FLAGS) --relocate-packed 0x8000 --from 0xd000 --to 0xfc00 -o $@ $<
endpart2.prg: ../parts/endpart/stage
	$(PACKER) $(PACKER_FLAGS) --from 0x5500 --to 0xd000 -o $@ $<
endpart3.prg: ../parts/endpart/stage
	$(PACKER) $(PACKER_FLAGS) --from 0x0808 --to 0x5500 -o $@ $<

../parts/transbox/transbox: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=58368	#2px scroll fade
transbox.prg: ../parts/transbox/transbox
	$(PACKER) $(PACKER_FLAGS) -o $@ $<

../parts/greetings/greetz: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=1024	#noisefader
	#$(MAKE) -C $(dir $@) $(RELEASE_FLAGS) link_exit=39936 # link_exit=17408	#schwurbel
greetings1.prg: ../parts/greetings/greetz
	$(PACKER) $(PACKER_FLAGS) --from 0x5000 --to 0xd000 -o $@ $<
greetings2.prg: ../parts/greetings/greetz
	$(PACKER) $(PACKER_FLAGS) --from 0xd000 --to 0xffff -o $@ $<
greetings3.prg: ../parts/greetings/greetz
	$(PACKER) $(PACKER_FLAGS) --from 0x2000 --to 0x5000 -o $@ $<

../parts/doublevec/double: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=25928 		#hunter
doublevec1.prg: ../parts/doublevec/double
	$(PACKER) $(PACKER_FLAGS) --from 0x5000 --to 0x9000 -o $@ $<
doublevec2.prg: ../parts/doublevec/double
	$(PACKER) $(PACKER_FLAGS) --from 0xe000 --to 0xfff0 -o $@ $<
doublevec3.prg: ../parts/doublevec/double
	$(PACKER) $(PACKER_FLAGS) --relocate-packed 0xa000 -o $@ ../parts/doublevec/data1
doublevec4.prg: ../parts/doublevec/double
	$(PACKER) $(PACKER_FLAGS) -o $@ ../parts/doublevec/data2
doublevec5.prg: ../parts/doublevec/double
	$(PACKER) $(PACKER_FLAGS) -o $@ ../parts/doublevec/data3
doublevec6.prg: ../parts/doublevec/double
	$(PACKER) $(PACKER_FLAGS) -o $@ ../parts/doublevec/data4
doublevec7.prg: ../parts/doublevec/double
	$(PACKER) $(PACKER_FLAGS) -o $@ ../parts/doublevec/data5

../parts/noisefader/noisefader: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=49408	#textrotator
noisefader1.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --from 0x0400 --to 0x0800 -o $@ $<
# Ghostscroller:
noisefader2.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --from 0xe000 -o $@ $<
# The ending of overload part "Another visitor. Stay a while. Stay forever":
../parts/stay_a_while/stay: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) stay $(RELEASE_FLAGS) link_exit=0
stay.prg: ../parts/stay_a_while/stay
	$(PACKER) $(PACKER_FLAGS) --relocate-packed 0x8000 -o $@ $<
# Glitch screens + floyd_steinberg + code:
noisefader3.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --from 0x8000 --to 0xd000 -o $@ $<
# This is the sprite_image0:
noisefader4.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --binfile --relocate-origin 0x4800 -o $@ ../parts/noisefader/sprite_images/sprite_image_0.spr
noisefader5.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --binfile --relocate-origin 0x2b00 -o $@ ../parts/noisefader/colour_images/colimage_0.png.bin
noisefader6.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --binfile --relocate-origin 0x5600 -o $@ ../parts/noisefader/sprite_images/sprite_image_1.spr
noisefader7.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --binfile --relocate-origin 0x2000 -o $@ ../parts/noisefader/colour_images/colimage_1.png.bin
noisefader8.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --binfile --relocate-origin 0x4800 -o $@ ../parts/noisefader/sprite_images/sprite_image_2.spr
noisefader9.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --binfile --relocate-origin 0x2b00 -o $@ ../parts/noisefader/colour_images/colimage_2.png.bin
noisefaderA.prg: ../parts/noisefader/noisefader
	$(PACKER) $(PACKER_FLAGS) --binfile --relocate-origin 0x5600 -o $@ ../parts/noisefader/sprite_images/sprite_image_3.spr

../parts/lazy/lazy: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=1024 #overload disk #2

../parts/textrotator/textrotator: force_look
	$(MAKE) -C $(dir $@) $(notdir $@) $(RELEASE_FLAGS) link_exit=3072	#lazy jones
textrotator1.prg: ../parts/textrotator/textrotator
	$(PACKER) $(PACKER_FLAGS) --from 0xc100 --to 0xd000 -o $@ $<
textrotator2.prg: ../parts/textrotator/textrotator
	$(PACKER) $(PACKER_FLAGS) --from 0x8000 --to 0xc100 -o $@ $<
textrotator3.prg: ../parts/lazy/lazy     # This is the Lazy Jones cutscene after disk was inserted, part#1. May be MAX $0e00 = 3584 bytes long! Currently 2909 bytes.
	$(PACKER) $(PACKER_FLAGS) --from 0x0400 --to 0x1e00 --relocate-packed 0x6c00 -o $@ $<
textrotator4.prg: ../parts/lazy/lazy     # This is the Lazy Jones cutscene after disk was inserted, part#2. May be MAX $0600 bytes long! Currently 858 bytes.
	$(PACKER) $(PACKER_FLAGS) --from 0x1e00  --relocate-packed 0x3a00 -o $@ $<
textrotator5.prg: ../parts/textrotator/textrotator
	$(PACKER) $(PACKER_FLAGS) --from 0x2000 --to 0x3a00 -o $@ $<
textrotator6.prg: ../parts/textrotator/textrotator
	$(PACKER) $(PACKER_FLAGS) --from 0x4900 --to 0x6c00 -o $@ $<
#textrotator.prg: ../parts/textrotator/textrotator
#	$(PACKER) $(PACKER_FLAGS) -o $@ $<

###############################################################

force_look:
	@true

toolchain-clean: clean
	$(MAKE) -C ../util/acme clean
	$(MAKE) -C ../util/dasm clean
	$(MAKE) -C ../util/spriteconv clean
	$(MAKE) -C ../util/charconv clean

clean: toolchain-clean
	$(info PATH="$(PATH)")
	$(MAKE) -C ../bitfire/loader clean
	$(MAKE) -C ../parts/bootstrap clean
	$(MAKE) -C ../parts/installer clean
	$(MAKE) -C ../parts/basicfadeout clean
	$(MAKE) -C ../parts/bobvector clean
	$(MAKE) -C ../parts/doublevec clean
	$(MAKE) -C ../parts/nonconvex clean
	$(MAKE) -C ../parts/logofadein clean
	$(MAKE) -C ../parts/shadowscroll clean
	$(MAKE) -C ../parts/ribbons clean
	$(MAKE) -C ../parts/endpart clean
	$(MAKE) -C ../parts/greetings clean
	$(MAKE) -C ../parts/metaballs clean
	$(MAKE) -C ../parts/doublevec clean
	$(MAKE) -C ../parts/overload clean
	$(MAKE) -C ../parts/textrotator clean
	$(MAKE) -C ../parts/noisefader clean
	$(MAKE) -C ../parts/faithless clean
	$(MAKE) -C ../parts/meatfadein clean
	$(MAKE) -C ../parts/schwurbel clean
	$(MAKE) -C ../parts/complexfadeout clean
	$(MAKE) -C ../parts/intro clean
	$(MAKE) -C ../parts/geos clean
	$(MAKE) -C ../parts/vortex clean
	$(MAKE) -C ../parts/banzai clean
	$(MAKE) -C ../parts/makenoise clean
	$(MAKE) -C ../parts/hunter clean
	$(MAKE) -C ../parts/bunny clean
	$(MAKE) -C ../parts/bunny2 clean
	$(MAKE) -C ../parts/transbox clean
	$(MAKE) -C ../parts/spaceship clean
	$(MAKE) -C ../parts/eagle clean
	$(MAKE) -C ../parts/lazy clean
	$(MAKE) -C ../parts/stay_a_while clean
	$(MAKE) -C ../parts/2pxfade clean
	$(MAKE) -C ../parts/koalascroll2px clean
	$(MAKE) -C ../parts/paralaxkoala clean
	$(MAKE) -C ../parts/parallaxfade clean
	$(MAKE) -C ../parts/note clean
	$(MAKE) -C ../parts/ransom clean
	$(MAKE) -C ../music/sdi clean
	$(MAKE) -C ../bitfire clean
	-rm *.prg *.d64 *.bin *.lz src-* dict-*
	-rm demo
