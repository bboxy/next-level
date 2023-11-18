include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all clean

all: banzai

toolchain:
ifndef release
	make -C ../../link toolchain
endif

banzai: banzai.asm
	$(DASM) $< -o$@ $(DASMOPT) -s$@.lst
ifndef release
	$(PACKER) --sfx 0x80d $(PACKER_FLAGS) -o $@.prg $@
endif

clean:
	-rm banzai banzai.prg banzai.lst thc_channel*.*
