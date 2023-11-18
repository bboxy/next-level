
.PHONY: all

all: sprite_image_0.spr sprite_image_1.spr sprite_image_2.spr sprite_image_3.spr

sprite_image_0.spr: sprite_image_0.png
	../../../util/spriteconv/convert -1 1 -2 0 -b 11 -o 1 sprite_image_0.png
sprite_image_1.spr: sprite_image_1.png
	../../../util/spriteconv/convert -1 10 -2 0 -3 4 -b 12 -o 1 sprite_image_1.png
sprite_image_2.spr: sprite_image_2.png
	../../../util/spriteconv/convert -1 1 -2 11 -b 5 -o 1 sprite_image_2.png
sprite_image_3.spr: sprite_image_3.png
	../../../util/spriteconv/convert -1 2 -2 0 -b 11 -o 1 sprite_image_3.png

clean:
	-rm *.spr
