include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: fill ribbons_fadein

toolchain:
ifndef release
	make -C ../../link toolchain
endif

ifdef release
fill: fill.asm sinus.bin
else
fill: fill.asm sinus.bin clean.kla
endif
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) --sfx 0x6a00 $(PACKER_FLAGS) -o $@.prg $@
endif

ribbons_fadein: ribbons_fadein.asm clean.kla
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) --sfx 0x9c00 $(PACKER_FLAGS) -o $@.prg $@
endif

makesinus: makesinus.c
	$(CC) $^ -o $@ $(CFLAGS) $(LDLIBS)

sanitize: sanitize.c
	$(CC) $^ -o $@ $(CFLAGS) $(LDLIBS)

clean.kla: sanitize waves_bgtest.png
	./sanitize

sinus.bin: makesinus
	./makesinus

clean:
	-rm fill fill.prg clean.kla makesinus sinus.bin sanitize ribbons_fadein.prg ribbons_fadein
