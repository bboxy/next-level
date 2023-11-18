include ../../link/paths.mk
include ../../link/defines.mk

all: pex_install

toolchain:
ifndef release
	make -C ../../link toolchain
endif

#RAW_FILES = $(shell find packer/output -name '*.raw')
#PACKED_FILES_ = $(patsubst output, packed, $(RAW_FILES))
#PACKED_FILES = $(patsubst %.raw, %.bin, $(PACKED_FILES_))
PACKED_FILES = ./packer/packed/01.bin \
	./packer/packed/02.bin \
	./packer/packed/03.bin \
	./packer/packed/04.bin \
	./packer/packed/05.bin \
	./packer/packed/06.bin \
	./packer/packed/07.bin \
	./packer/packed/08.bin \
	./packer/packed/09.bin \
	./packer/packed/10.bin \
	./packer/packed/11.bin \
	./packer/packed/12.bin \
	./packer/packed/13.bin \
	./packer/packed/14.bin \
	./packer/packed/15.bin \
	./packer/packed/16.bin \
	./packer/packed/17.bin \
	./packer/packed/18.bin \
	./packer/packed/19.bin \
	./packer/packed/20.bin \
	./packer/packed/21.bin \
	./packer/packed/22.bin \
	./packer/packed/23.bin \
	./packer/packed/24.bin \
	./packer/packed/25.bin \
	./packer/packed/26.bin \
	./packer/packed/27.bin \
	./packer/packed/28.bin \
	./packer/packed/29.bin \
	./packer/packed/30.bin \
	./packer/packed/31.bin \
	./packer/packed/32.bin \
	./packer/packed/33.bin \
	./packer/packed/34.bin \
	./packer/packed/35.bin \
	./packer/packed/36.bin \
	./packer/packed/37.bin \
	./packer/packed/38.bin \
	./packer/packed/39.bin \
	./packer/packed/40.bin \
	./packer/packed/41.bin \
	./packer/packed/42.bin \
	./packer/packed/43.bin \
	./packer/packed/44.bin \
	./packer/packed/45.bin \
	./packer/packed/46.bin \
	./packer/packed/47.bin \
	./packer/packed/48.bin \
	./packer/packed/49.bin \
	./packer/packed/50.bin \
	./packer/packed/51.bin \
	./packer/packed/52.bin \
	./packer/packed/53.bin \
	./packer/packed/54.bin \
	./packer/packed/55.bin \
	./packer/packed/56.bin \
	./packer/packed/57.bin \
	./packer/packed/58.bin \
	./packer/packed/59.bin \
	./packer/packed/60.bin \
	./packer/packed/61.bin \
	./packer/packed/62.bin \
	./packer/packed/63.bin \
	./packer/packed/64.bin \
	./packer/packed/65.bin \
	./packer/packed/66.bin \
	./packer/packed/67.bin \
	./packer/packed/68.bin \
	./packer/packed/69.bin \
	./packer/packed/70.bin \
	./packer/packed/71.bin \
	./packer/packed/72.bin \
	./packer/packed/73.bin \
	./packer/packed/74.bin \
	./packer/packed/75.bin \
	./packer/packed/76.bin \
	./packer/packed/77.bin \
	./packer/packed/78.bin \
	./packer/packed/79.bin \
	./packer/packed/80.bin \
	./packer/packed/81.bin \
	./packer/packed/82.bin \
	./packer/packed/83.bin \
	./packer/packed/84.bin \
	./packer/packed/85.bin \
	./packer/packed/86.bin \
	./packer/packed/87.bin \
	./packer/packed/88.bin \
	./packer/packed/89.bin \
	./packer/packed/90.bin \
	./packer/packed/91.bin \
	./packer/packed/92.bin \
	./packer/packed/93.bin \
	./packer/packed/94.bin \
	./packer/packed/95.bin \
	./packer/packed/96.bin \
	./packer/packed/97.bin \
	./packer/packed/98.bin \
	./packer/packed/99.bin

#add -b in front of each file for file-list needed with d64write
D64_FILES = $(foreach file, $(PACKED_FILES), -b $(file))

packer/output/%.raw: packer/packer.py
	make -C packer

packer/packed/%.bin: packer/output/%.raw
	$(PACKER) -o $@ $^

overload: main.s
	make -C ../../bitfire/
	$(ACME) $(ACMEOPT) -v3 --report $@.report --vicelabels $@.vicelabels -o $@ $<

overload.prg: overload
	$(PACKER) -o $@ $<

pex_install: pex_install.asm overload.prg Makefile $(PACKED_FILES)
	make -C ../../bitfire
	$(ACME) $(ACMEOPT) -o $@ $<
	$(PACKER) --sfx 0x0800 -o $@.lz $@
	$(D64WRITE) -c image2.d64 -h mahoney -i \<3 --side 1 --boot $@.lz -b ./overload.prg $(D64_FILES)

	#~/repo/vice-emu-code/vice/src/x64 side1.d64
	#x64 side1.d64
	#x64 /Users/pex/Documents/c64/x2020/git/performers/current/framework/orig_mapping/overload2/side1.d64
	#x64 -pal -truedrive +confirmonexit -model c64c side1.d64
#	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc -pal -model c64c +confirmonexit -autostart ~/Documents/c64/x2023/git/perfromance/parts/overload/image2.d64
#	rm $@ $@.lz

clean:
	-rm image2.d64 pex_install pex_install.lz
	-rm packer/packed/*.bin
	-rm overload.*
	-rm overload
	#make -C ../ clean
