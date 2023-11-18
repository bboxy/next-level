include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: intro

toolchain:
ifndef release
	make -C ../../link toolchain
endif

intro: intro.asm
ifndef release
	$(ACME) $(ACMEOPT) -o $@ --vicelabels labels.lab $<
	$(PACKER) --sfx 0x80d $(PACKER_FLAGS) -o $@.prg $@
else
	$(ACME) $(ACMEOPT) -o $@ $<
endif

intro.prg: intro
	exomizer3 sfx sys -m 256 -p 1 -n -o intro.prg intro_unpacked.prg

go:	intro.prg
	x64sc -moncommands mon_cmd.txt intro.prg

convert:        convert.c
	gcc -g `sdl-config --cflags` -o convert convert.c  `sdl-config --libs` -lSDL -lSDL_image

clean:
	rm -rf *.prg intro labels.lab convert
