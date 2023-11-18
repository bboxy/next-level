include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

ADDR ?= 0x800

all: music.prg

toolchain:
ifndef release
	make -C ../../link toolchain
endif

music.prg: player.asm songdata.asm
	$(ACME) $(ACMEOPT) --setpc $(ADDR) -o $@ $<

songdata.asm: main.seq
	./convert.sh $< > $@

clean:
	-rm music.prg songdata.asm
