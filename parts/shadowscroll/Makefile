include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: shadow

toolchain:
ifndef release
	make -C ../../link toolchain
endif

spr1.spr: spr1.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -h -b 3 $<

spr7.spr: spr7.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -y 21 -Y 42 -h -b 3 $<

sky.spr: sky.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -h -b 3 $<

shadow: zoom.asm font.chr font.scr font_hires.chr font_hires.scr sinus.bin sign.spr sign2.spr spr1.spr spr7.spr clean.prg fade_gen.asm coltab_defs.asm sky.spr
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) --sfx 0x8000 $(PACKER_FLAGS) -o $@.prg $@
endif

fadegen: fade.c hill.prg
	$(CC) $< -o $@ $(CCFLAGS)

clean.prg: fade_gen.asm
fade_gen.asm: fadegen
	./fadegen

sinus.bin: stretch
	./stretch

sign.spr: sign.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -h -b 10 $<

sign2.spr: sign2.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -h -b 10 $<

font_hires.chr: font_hires.scr
font_hires.scr: font_hires.png convert
	./convert -b 0 -h -r 0 -n 148 $<

font.chr: font.scr
font.scr: font.png convert
	./convert -b 3 -1 4 -2 14 $<

stretch: stretch.c
	$(CC) $< -o $@ $(CFLAGS) $(LDLIBS)

convert: convert.c
	$(CC) $< -o $@ $(CFLAGS) $(LDLIBS)

clean:
	-rm stretch sinus.bin shadow.prg shadow font.scr font.col font.chr font_hires.scr font_hires.col font_hires.chr convert fadegen fade_gen.asm clean.prg sign.spr sign2.spr spr1.spr spr7.spr light.spr sky.spr
ifndef release
	make -C $(dir $(SPRITECONV)) clean
endif
