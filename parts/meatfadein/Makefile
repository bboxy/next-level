include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: meat

toolchain:
ifndef release
	make -C ../../link toolchain
endif

meat: meat.asm sinus.bin
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) --sfx 0xf000 --01 0x35 $(PACKER_FLAGS) -o $@.prg $@
endif

sinus.bin: sinus
	./sinus

sinus: sinus.c
	$(CC) $^ -o $@ $(CFLAGS) $(LDLIBS)

clean:
	-rm meat meat.prg sinus.bin sinus
