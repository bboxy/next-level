include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: vortex

toolchain:
ifndef release
	make -C ../../link toolchain
endif

vortex: chessboardzoomerdoubleanimated.asm *.bin
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) --sfx 0x2000 $(PACKER_FLAGS) -o $@.prg $@
endif

clean:
	-rm vortex vortex.prg
