include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: hunter

toolchain:
ifndef release
	make -C ../../link toolchain
endif

hunter: hunter.asm clean.kla fade_gen.asm text.spr bubble.spr csign.spr sprinkle.spr lyric.chr lyric.scr
	$(ACME) $(ACMEOPT) -o $@ $<
ifndef release
	$(PACKER) $(PACKER_FLAGS) --01 0x35 --sfx 0x6548 -o $@.prg $@
endif

lyric.col: lyric.chr
lyric.scr: lyric.chr
lyric.chr: lyric.png
ifndef release
	make -C $(dir $(CHARCONV))
endif
	$(CHARCONV) -h -b 0 -p -y 0 -Y 16 $<

sprinkle.spr: sprinkle.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

text.spr: text.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

bubble.spr: bubble.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 0 -h $<

csign.spr: csign.png
ifndef release
	make -C $(dir $(SPRITECONV))
endif
	$(SPRITECONV) -b 1 -1 0 -2 6 - 3 11 $<

clean.kla: fade_gen.asm
fade_gen.asm: fadegen
	./fadegen

fadegen: fade.c shrine.koa
	$(CC) $< -o $@ $(CCFLAGS)

clean:
	-rm hunter hunter.prg clean.kla fade_gen.asm fadegen *.spr lyric.chr lyric.scr lyric.col
