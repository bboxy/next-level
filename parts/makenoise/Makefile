include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all clean

all: makenoise

toolchain:
ifndef release
	make -C ../../link toolchain
endif

makenoise: noise.asm nufli_gen.asm
	$(DASM) $< -o$@ $(DASMOPT) -s$@.lst
ifndef release
	$(PACKER) --sfx 0x80d $(PACKER_FLAGS) -o $@.prg $@
endif

nufli_gen.asm: convert gfx/harle+raster.nuf
	./convert gfx/harle+raster.nuf > nufli_gen.asm

convert: convert.c
	$(CC) -o $@ $< $(CFLAGS) $(LDLIBS)

clean:
	-rm makenoise makenoise.prg makenoise.lst thc_channel*.* convert nufli_gen.asm
