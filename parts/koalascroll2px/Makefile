include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: scroll

scroll: main.asm framework.asm init.asm irq.asm bgthread.asm
	$(JAVA) -jar $(KICKASS_JAR) $< $(KICKASSOPT) -o $@ -showmem -afo
ifndef release
	$(PACKER) $(PACKER_FLAGS) --sfx 0x5f40 -o $@.prg $@
endif

clean:
	-rm *.prg scroll *.sym *.txt
