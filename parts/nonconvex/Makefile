include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: complex

toolchain:
ifndef release
	make -C ../../link toolchain
endif

complex: complex.asm sierpinsky.asm data/*
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --sfx 0x4000 -o $@.prg $@
endif

clean:
	-rm complex complex.prg
