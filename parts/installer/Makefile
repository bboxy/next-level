include ../../link/paths.mk
include ../../link/defines.mk
#release ?= 0
#link_exit ?= 256
#ACME_OPTS ?= -f cbm -Drelease=$(release)

.PHONY: all

all: installer

installer: installer.asm ../../bitfire/loader/installer ../../bitfire/loader/loader_*.inc
	$(ACME) $(ACMEOPT) -o $@ $<

clean:
	-rm installer
