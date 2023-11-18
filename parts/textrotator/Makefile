include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: textrotator

toolchain:
ifndef release
	make -C ../../link toolchain
endif

textrotator: main.s
	$(ACME) $(ACMEOPT) --report $@.report --vicelabels $@.vicelabels -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --sfx 0x0400 -o $@.prg $@
endif

run: textrotator
	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc

fast: textrotator
#	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc -pal -model c64c +confirmonexit -autostart ~/Documents/c64/x2023/git/perfromance/parts/textrotator/textrotator_packed.prg
	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc -remotemonitor

# "fast 2"-version, with netcat and remotemonitor at 6510:
fast2: textrotator
	echo 'bank ram\nf 0002 ffff 0\nl "/Users/pex/Documents/c64/x2023/git/perfromance/parts/textrotator/textrotator" 0\ng 0400\n' | /usr/bin/nc localhost 6510

clean:
	-rm textrotator textrotator.prg *.report *.vicelabels
