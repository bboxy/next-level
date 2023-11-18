include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: balloon

toolchain:
ifndef release
	make -C ../../link toolchain
endif

bunny.spr: bunny.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 13 -1 0 -2 8 -3 10 $<

balloon.spr: balloon.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 3 -h $<

balloon: balloon.asm bunny.spr balloon.spr
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0x2400 -o $@.prg $@
endif

clean:
	-rm balloon balloon.prg bunny.spr balloon.spr
