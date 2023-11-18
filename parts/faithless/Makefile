include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: faithless

toolchain:
ifndef release
	make -C ../../link toolchain
endif

gfx/ECM-Samplepartgfx-chars.col: gfx/ECM-Samplepartgfx-chars.png
gfx/ECM-Samplepartgfx-chars.scr: gfx/ECM-Samplepartgfx-chars.png
gfx/ECM-Samplepartgfx-chars.chr: gfx/ECM-Samplepartgfx-chars.png
ifndef release
	make -C $(dir $(CHARCONV))
endif
	$(CHARCONV) -b 1 -1 13 -2 8 -3 3 -e -t 48 -r 1 $<

gfx/font.col: gfx/font.png
gfx/font.scr: gfx/font.png
gfx/font.chr: gfx/font.png
ifndef release
	make -C $(dir $(CHARCONV))
endif
	$(CHARCONV) -b 1 -h -t 24 $<

gfx/ECM-Samplepartgfx-sprites.spr: gfx/ECM-Samplepartgfx-sprites.png
gfx/ECM-Samplepartgfx-sprites.map: gfx/ECM-Samplepartgfx-sprites.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h -m $<

faithless: faithless.asm gfx/ECM-Samplepartgfx-chars.col gfx/ECM-Samplepartgfx-chars.scr gfx/ECM-Samplepartgfx-chars.chr gfx/ECM-Samplepartgfx-sprites.spr gfx/ECM-Samplepartgfx-sprites.map gfx/font.col gfx/font.scr gfx/font.chr
	$(DASM) $< -o$@ $(DASMOPT) -s$@.lst
ifndef release
	$(PACKER) $(PACKER_FLAGS) --sfx 0x80d -o $@.prg $@
endif

vice: all
	$(X64) -moncommands faithless.lst faithless

clean:
	-rm faithless faithless.prg faithless.lst gfx/*.spr gfx/*.chr gfx/*.col gfx/*.scr gfx/*.map thc_channel*.*
