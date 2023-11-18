include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: note

toolchain:
ifndef release
	make -C ../../link toolchain
endif

font_note.chr: font_note.png
ifndef release
	make -C $(dir $(CHARCONV))
endif
	$(CHARCONV) -b 1 -h -p $<

font5.chr: font5.png
ifndef release
	make -C $(dir $(CHARCONV))
endif
	$(CHARCONV) -b 1 -h -p $<

dustbin_bright_single.spr: dustbin_bright_single.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

dustbin_dark_single.spr: dustbin_dark_single.png
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

bold.ct: bold.asm
	$(ACME) -f plain -o $@ $<

note: note.asm dustbin_dark_single.spr dustbin_bright_single.spr geos_pointer.spr bonzai_icon.spr pumpkin1.spr pumpkin2.spr geos_desktop.prg font5.chr font_note.chr bold.ct
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --sfx 0x2000 -o $@.prg $@
endif

clean:
	-rm note.prg note *.spr *.chr *.col *.scr bold.ct
