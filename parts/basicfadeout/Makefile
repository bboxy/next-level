include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: basic

toolchain:
ifndef release
	make -C ../../link toolchain
endif

basic: basic.asm
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) --sfx 0x2000 $(PACKER_FLAGS) -o $@.prg $@
endif

clean:
	-rm basic basic.prg
