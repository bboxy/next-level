include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all clean

all: greetz

toolchain:
ifndef release
	make -C ../../link toolchain
endif

greetz: greetz.asm
	$(DASM) $< -o$@ $(DASMOPT) -s$@.lst
ifndef release
	$(PACKER) --sfx 0x80d $(PACKER_FLAGS) -o $@.prg $@
endif

clean:
	-rm greetz greetz.prg greetz.lst
