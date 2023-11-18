include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: double

toolchain:
ifndef release
	make -C ../../link toolchain
endif

gfx/plate_base_worlddomination.spr: gfx/plate_base_worlddomination.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 11 -1 1 -2 14 -3 4 $<

gfx/plate_overlay_worlddomination.spr: gfx/plate_overlay_worlddomination.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -h -b 1 $<

gfx/plate_base_20faces.spr: gfx/plate_base_20faces.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 11 -1 1 -2 14 -3 4 $<

gfx/plate_overlay_20faces.spr: gfx/plate_overlay_20faces.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -h -b 1 $<

gfx/plate_base_arschlochdither.spr: gfx/plate_base_arschlochdither.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 11 -1 1 -2 14 -3 4 $<

gfx/plate_overlay_arschlochdither.spr: gfx/plate_overlay_arschlochdither.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -h -b 1 $<

gfx/plate_base_performers.spr: gfx/plate_base_performers.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 11 -1 1 -2 14 -3 4 $<

gfx/plate_overlay_performers.spr: gfx/plate_overlay_performers.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -h -b 1 $<

octo: exporter.c octo.h
	$(CC) $(CFLAGS) -o $@ $< -include octo.h $(LDLIBS)

octo.asm: octo
	./$^ > $@

open: exporter.c open.h
	$(CC) $(CFLAGS) -o $@ $< -include open.h $(LDLIBS)

open.asm: open
	./$^ > $@

cone: exporter.c cone.h
	$(CC) $(CFLAGS) -o $@ $< -include cone.h $(LDLIBS)

cone.asm: cone
	./$^ > $@

iko: exporter.c iko.h
	$(CC) $(CFLAGS) -o $@ $< -include iko.h $(LDLIBS)

iko.asm: iko
	./$^ > $@

tetra: exporter.c tetra.h
	$(CC) $(CFLAGS) -o $@ $< -include tetra.h $(LDLIBS)

tetra.asm: tetra
	./$^ > $@

data1: data1.asm tetra.asm
	$(ACME) $(ACMEOPT) -o $@ $<

data2: data2.asm octo.asm
	$(ACME) $(ACMEOPT) -o $@ $<

data3: data3.asm iko.asm
	$(ACME) $(ACMEOPT) -o $@ $<

data4: data4.asm open.asm
	$(ACME) $(ACMEOPT) -o $@ $<

data5: data5.asm cone.asm
	$(ACME) $(ACMEOPT) -o $@ $<



double: player.asm data1 data2 data3 data4 data5 sinus.bin gfx/plate_base_arschlochdither.spr gfx/plate_overlay_arschlochdither.spr gfx/plate_base_worlddomination.spr gfx/plate_overlay_worlddomination.spr gfx/plate_base_20faces.spr gfx/plate_overlay_20faces.spr gfx/plate_base_performers.spr gfx/plate_overlay_performers.spr
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0x5000 -o $@.prg $@
endif


sinus.bin: makesinus
	./makesinus

makesinus: makesinus.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

clean:
	-rm double.prg double sinus.bin makesinus octo coords.asm octo.asm tetra tetra.asm iko iko.asm gfx/plate_base_*.spr gfx/plate_overlay_*.spr data1 data2 data3 data4 cone open data5 cone.asm open.asm
