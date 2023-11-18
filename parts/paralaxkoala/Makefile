include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: paralax

paralax: main.asm framework.asm init.asm irq.asm bgthread.asm IMAGE2k_q.kla IMAGE3k_q.kla we_drink_to.png
	$(JAVA) -jar $(KICKASS_JAR) $< $(KICKASSOPT) -o $@ -showmem -afo
ifndef release
	$(PACKER) $(PACKER_FLAGS) --sfx 0xc400 -o $@.prg $@
endif

clean:
	-rm *.prg paralax *.sym *.txt

