include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: fade

toolchain:
ifndef release
	make -C ../../link toolchain
endif

fade: fade.asm ../paralaxkoala/tools/stam.kla
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0x0400 -o $@.prg $@
endif

clean:
	-rm fade fade.prg
