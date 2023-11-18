include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: eagle

toolchain:
ifndef release
	make -C ../../link toolchain
endif

eagle: eagle.asm
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0x3f40 -o $@.prg $@
endif

clean:
	-rm eagle eagle.prg
