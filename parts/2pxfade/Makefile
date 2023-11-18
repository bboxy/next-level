include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: fade

toolchain:
ifndef release
	make -C ../../link toolchain
endif

fade: fade.asm clean.kla fade_gen.asm
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0xe400 -o $@.prg $@
endif

clean.kla: fade_gen.asm
fade_gen.asm: fadegen
	./fadegen

fadegen: fade.c ../koalascroll2px/assets/tiles1.kla
	$(CC) $< -o $@ $(CCFLAGS)

clean:
	-rm fade fade.prg clean.kla fade_gen.asm fadegen
