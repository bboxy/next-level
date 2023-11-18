include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: fadein

toolchain:
ifndef release
	make -C ../../link toolchain
endif

fadein: fadein.asm fade_gen1.asm clean1.kla
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) --sfx 0xc000 $(PACKER_FLAGS) -o $@.prg $@
endif

clean1.kla:
fade_gen1.asm: logo1.kla fade
	./fade -f $@ -t 0xa -l coltab1 -o clean1.kla logo1.kla

#fade_gen2.asm: logo2.kla fade
#	./fade -f $@ -t 0x1 -l coltab2 -o clean2.kla logo2.kla

fade: fade.c
	$(CC) $^ -o $@ $(CFLAGS) $(LDLIBS)
#sanitize: sanitize.c
#	$(CC) $^ -o $@ $(CFLAGS) $(LDLIBS)

#clean.kla: sanitize logo.png
#	./sanitize

clean:
	-rm fadein fade_gen*.asm clean*.kla fade fade.prg
