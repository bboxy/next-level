include ../../link/paths.mk
include ../../link/defines.mk

#link_exit ?= 0
#release ?= 0
##ACME ?= acme
#ACME_OPTS ?= -v1 -f cbm -Drelease=$(release) -Dlink_exit=$(link_exit)

bootstrap1: boot.asm
	$(ACME) $(ACMEOPT) -DSIDE=1 -o $@ $<
bootstrap2: boot.asm
	$(ACME) $(ACMEOPT) -DSIDE=2 -o $@ $<
bootstrap3: boot.asm
	$(ACME) $(ACMEOPT) -DSIDE=3 -o $@ $<
bootstrap4: boot.asm
	$(ACME) $(ACMEOPT) -DSIDE=4 -o $@ $<

clean:
	-rm bootstrap*
