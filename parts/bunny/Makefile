include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: bunny

toolchain:
ifndef release
	make -C ../../link toolchain
endif

bunny.spr: bunny.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 13 -1 0 -2 8 -3 10 $<

bunny: bunny.asm bunny.spr
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0x2000 -o $@.prg $@
endif

clean:
	-rm bunny bunny.prg bunny.spr
