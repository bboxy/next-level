include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: transbox

transbox: TransBox.asm includes.asm assets/charset_box.prg
	$(JAVA) -jar $(KICKASS_JAR) $< $(KICKASSOPT) -o $@ -showmem -afo
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0x25c0 -o $@.prg $@
endif

clean:
	-rm *.prg transbox *.sym *.txt
