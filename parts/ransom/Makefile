include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: ransom

toolchain:
ifndef release
	make -C ../../link toolchain
endif

ransom: ransom.asm bitmap.prg
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0x3f40 -o $@.prg $@
endif

clean:
	-rm ransom ransom.prg
