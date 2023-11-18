include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: stay

toolchain:
ifndef release
	make -C ../../link toolchain
endif

stay: main.s
ifndef release
	$(ACME) $(ACMEOPT) --report $@.report --vicelabels $@.vicelabels -o $@ $<
	$(PACKER) $(PACKER_FLAGS) --small --sfx 0xf700 -o $@.prg $@
else
	$(ACME) $(ACMEOPT) -o $@ $<
endif

run: stay
	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc

diff: stay
	hexdump stay > stay.hexdump
	hexdump stay4_0800_f1a0_s39ae.prg > stay4_0800_f1a0_s39ae.hexdump
	diff stay.hexdump stay4_0800_f1a0_s39ae.hexdump

fast: stay
#	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc -pal -model c64c +confirmonexit -autostart ~/Documents/c64/x2023/git/perfromance/parts/stay/stay_packed.prg
	/Applications/vice-arm64-gtk3-3.6.1/x64sc.app/Contents/MacOS/x64sc -remotemonitor

# "fast 2"-version, with netcat and remotemonitor at 6510:
fast2: stay
	echo 'bank ram\nf 0002 ffff 0\nl "/Users/pex/Documents/c64/x2023/git/perfromance/parts/stay_a_while/stay" 0\ng f700\n' | /usr/bin/nc localhost 6510

clean:
	-rm stay stay.prg
