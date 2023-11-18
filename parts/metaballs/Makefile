include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: metaballs

createLoop.prg: createLoop.asm
	$(JAVA) -jar $(KICKASS_JAR) $< $(KICKASSOPT) -o $@ -showmem -afo

data: createDiffData.js createLoop.prg
	$(NODE) $<

metaballs: main.asm framework/*.asm codeGeneratorOutput.asm codeGenerator.asm
	$(JAVA) -jar $(KICKASS_JAR) $< $(KICKASSOPT) -o $@ -showmem -afo
ifndef release
	$(PACKER) $(PACKER_FLAGS) --sfx 0x0900 -o $@.prg $@
endif

clean:
	-rm *.prg metaballs *.sym *.txt createloop
