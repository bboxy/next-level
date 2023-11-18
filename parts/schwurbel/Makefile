include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: schwurbel

toolchain:
ifndef release
	make -C ../../link toolchain
endif

profis.spr: profis.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 15 -1 0 -2 5 -3 13 $<

schwurbel: schwurbel.asm sintab profis.spr
ifndef release
	$(ACME) $(ACMEOPT) -o $@ --vicelabels labels.lab $<
	$(PACKER) --sfx 0x80d $(PACKER_FLAGS) -o $@.prg $@
else
	$(ACME) $(ACMEOPT) -o $@ $<
endif

schwurbel.prg: schwurbel
	exomizer3 sfx sys -m 256 -p 1 -n -o schwurbel.prg schwurbel_unpacked.prg

go:	schwurbel.prg
	x64 -moncommands mon_cmd.txt schwurbel.prg

convert:        convert.c
	gcc -g `sdl-config --cflags` -o convert convert.c  `sdl-config --libs` -lSDL -lSDL_image

clean:
	rm -rf *.prg schwurbel labels.lab profis.spr
