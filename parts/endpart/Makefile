include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: stage

toolchain:
ifndef release
	make -C ../../link toolchain
endif

stage: stage.asm
	$(DASM) $< -o$@ $(DASMOPT) -s$@.lst
ifndef release
	$(PACKER) $(PACKER_FLAGS) --sfx 0x80d -o $@.prg $@
endif

vice: all
	$(X64) -moncommands stage.lst stage

clean:
	-rm stage stage.prg stage.lst thc_channel*.*
