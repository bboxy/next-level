include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: noisefader

toolchain:
ifndef release
	make -C ../../link toolchain
endif

noisefader: main.s
ifndef release
	$(ACME) $(ACMEOPT) --report $@.report --vicelabels $@.vicelabels -o $@ $<
	$(PACKER) $(PACKER_FLAGS) --small --sfx 0x0400 -o $@.prg $@
else
	$(ACME) $(ACMEOPT) --report $@.report --vicelabels $@.vicelabels -o $@ $<
endif

run: noisefader
	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc

fast: noisefader
#	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc -pal -model c64c +confirmonexit -autostart ~/Documents/c64/x2023/git/perfromance/parts/noisefader/noisefader_packed.prg
	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc -remotemonitor

# "fast 2"-version, with netcat and remotemonitor at 6510:
fast2: noisefader
	echo 'bank ram\nf 0002 ffff 0\nl "/Users/pex/Documents/c64/x2023/git/perfromance/parts/noisefader/noisefader" 0\ng 0400\n' | /usr/bin/nc localhost 6510

clean:
	-rm noisefader noisefader.prg noisefader.report noisefader.vicelabels
