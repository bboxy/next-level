include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: sbf

#toolchain:
#ifndef release
#	make -C ../../link toolchain
#endif

coords: coords.c
	$(CC) -o $@ $< $(CFLAGS) $(LDLIBS)

stream*.asm: coords
	./coords

gfx/map.scr: gfx/map.chr
gfx/map.col: gfx/map.chr
gfx/map.chr: gfx/map.png $(CHARCONV)
ifndef release
	make -C $(dir $(CHARCONV))
endif
	#$(CHARCONV) -1 12 -2 13 -b 9 -r 188 gfx/screen.png
	$(CHARCONV) -h -b 1 -r 188 $<

gfx/screen.scr: gfx/screen.chr
gfx/screen.col: gfx/screen.chr
gfx/screen.chr: gfx/screen.png $(CHARCONV)
ifndef release
	make -C $(dir $(CHARCONV))
endif
	#$(CHARCONV) -1 12 -2 13 -b 9 -r 188 gfx/screen.png
	$(CHARCONV) -h -b 1 -r 188 $<

gfx/help.scr: gfx/help.chr
gfx/help.col: gfx/help.chr
gfx/help.chr: gfx/help.png $(CHARCONV)
ifndef release
	make -C $(dir $(CHARCONV))
endif
	$(CHARCONV) -h -b 1 $<

gfx/sprites.spr: gfx/sprites.png $(SPRITECONV)
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	#$(SPRITECONV) -1 12 -2 9 -b 5 gfx/sprites.png
	$(SPRITECONV) -h -1 0 -b 1 $<

gfx/help_sprites.spr: gfx/help_sprites.png $(SPRITECONV)
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	#$(SPRITECONV) -1 12 -2 9 -b 5 gfx/sprites.png
	$(SPRITECONV) -h -b 0 $<

sbf: sbf.asm stream*.asm map.bin gfx/sprites.spr gfx/screen.scr gfx/screen.chr gfx/screen.col gfx/help.scr gfx/help.col gfx/help.chr gfx/help_sprites.spr gfx/map.col
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0xe3f8 -o $@.prg $@
endif

clean:
	-rm sbf sbf.prg coords stream*.asm
	-rm gfx/screen.chr gfx/screen.col gfx/screen.scr gfx/sprites.spr gfx/help.chr gfx/help.col gfx/help.scr gfx/help_sprites.spr gfx/map.col gfx/map.scr gfx/map.chr
ifndef release
	make -C $(dir $(SPRITECONV)) clean
	make -C $(dir $(CHARCONV)) clean
endif
