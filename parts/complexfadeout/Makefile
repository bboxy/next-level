include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: triangle

toolchain:
ifndef release
	make -C ../../link toolchain
endif

triangle: triangle.asm
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0xf800 -o $@.prg $@
endif

clean:
	-rm triangle triangle.prg
