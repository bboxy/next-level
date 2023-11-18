
include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: lazy

toolchain:
ifndef release
	make -C ../../link toolchain
endif

lazy: main.s
ifndef release
	$(ACME) $(ACMEOPT) --report $@.report --vicelabels $@.vicelabels -o $@ $<
	$(PACKER) $(PACKER_FLAGS) --sfx 0x0c00 -o $@.prg $@
else
	$(ACME) $(ACMEOPT) --report $@.report -o $@ $<
endif

run: lazy
	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc

fast: lazy
#	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc -pal -model c64c +confirmonexit -autostart ~/Documents/c64/x2023/git/perfromance/parts/lazy/lazy_packed.prg
	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc -remotemonitor

# "fast 2"-version, with netcat and remotemonitor at 6510:
fast2: lazy
	echo 'bank ram\nf 0802 cfff 0\nl "/Users/pex/Documents/c64/x2023/git/perfromance/parts/lazy/lazy" 0\ng 0c00\n' | /usr/bin/nc localhost 6510

clean:
	-rm lazy lazy.prg lazy.report
