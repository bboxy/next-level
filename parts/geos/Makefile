include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: geos

toolchain:
ifndef release
	make -C ../../link toolchain
endif

dustbin_bright.spr: dustbin_bright.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

dustbin_dark.spr: dustbin_dark.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

pumpkin_bright.spr: pumpkin_bright.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

pumpkin2.spr: pumpkin2.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 6 -1 10 -2 8 -3 2 $<

pumpkin1.spr: pumpkin1.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 1 -h $<

pumpkin_dark.spr: pumpkin_dark.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

geos_pointer.spr: geos_pointer.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

bonzai_icon.spr: bonzai_icon.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

#fade: fade.c
#	$(CC) $< -o $@ $(CCFLAGS)
#
#geos_clean.prg: geos_desktop.prg fade
#	./fade $< $@
#
#csdb_clean.prg: csdb2.prg fade
#	./fade $< $@

geos: geos.asm dustbin_dark.spr dustbin_bright.spr pumpkin_dark.spr pumpkin_bright.spr geos_pointer.spr bonzai_icon.spr geos_popup.prg csdb2.prg csdb_vote.prg csdb_done.prg pumpkin1.spr pumpkin2.spr
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --sfx 0x2000 -o $@.prg $@
endif

clean:
	-rm geos.prg geos *.spr
