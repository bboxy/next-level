include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: spaceship

toolchain:
ifndef release
	make -C ../../link toolchain
endif

spaceship: spaceship.asm
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0x3f40 -o $@.prg $@
endif

clean:
	-rm spaceship spaceship.prg
