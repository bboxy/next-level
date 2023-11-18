
.PHONY: all

all: sprite_image_0.spr sprite_image_1.spr sprite_image_2.spr sprite_image_3.spr

sprite_image_0.spr: sprite_image_0.png
	../../../util/spriteconv/convert -1 1 -2 0 -3 2 -b 11 -d 1 -o 1 sprite_image_0.png
sprite_image_1.spr: sprite_image_1.png
	../../../util/spriteconv/convert -1 0 -b 1 -o 1 sprite_image_1.png
sprite_image_2.spr: sprite_image_2.png
	../../../util/spriteconv/convert -1 0 -b 1 -o 1 sprite_image_2.png
sprite_image_3.spr: sprite_image_3.png
	../../../util/spriteconv/convert -1 0 -b 1 -o 1 sprite_image_3.png

clean:
	-rm *.bin


# BEWARE! spriteconv/convert makes sprite in row #5 second from the left multicolour accidentially.
# So I manually patched the sprite data at $0640 to 
#
#(C:$a403) ms 6440
#>C:6440 ........................ 00 00 00
#>C:6443 ........................ 00 00 00
#>C:6446 ........................ 00 00 00
#>C:6449 ........................ 00 00 00
#>C:644c ........................ 00 00 00
#>C:644f ........................ 00 00 00
#>C:6452 ........................ 00 00 00
#>C:6455 ........................ 00 00 00
#>C:6458 ........................ 00 00 00
#>C:645b ........................ 00 00 00
#>C:645e ........................ 00 00 00
#>C:6461 ........................ 00 00 00
#>C:6464 ........................ 00 00 00
#>C:6467 ........................ 00 00 00
#>C:646a ........................ 00 00 00
#>C:646d ........................ 00 00 00
#>C:6470 ........................ 00 00 00
#>C:6473 .#.#.#.#.#.............. 55 40 00       <- this should be single colour
#>C:6476 .#.#.................... 50 00 00
#>C:6479 .#...................... 40 00 00
#>C:647c ........................ 00 00 00
#
#(C:$6480) ms 6240
#>C:6240 ...........##########... 00 1f f8
#>C:6243 ...........#########.... 00 1f f0
#>C:6246 ..........#########....# 00 3f e1
#>C:6249 #####.....#########....# f8 3f e1
#>C:624c #######.....#######....# fe 0f e1
#>C:624f ########.....######....# ff 07 e1
#>C:6252 ########.....#######.... ff 07 f0
#>C:6255 ..#######....#######.... 3f 87 f0
#>C:6258 ..#######....#######.... 3f 87 f0
#>C:625b ..#######.....######.... 3f 83 f0
#>C:625e #########.....#######... ff 83 f8
#>C:6261 #########.....#######... ff 83 f8
#>C:6264 ##.#######....########## df c3 ff
#>C:6267 #...######.....######### 8f c1 ff
#>C:626a #...########....######.. 8f f0 fc
#>C:626d ##..########............ cf f0 00
#>C:6270 ###########............. ff e0 00
#>C:6273 ##########.............. ff c0 00
#>C:6276 ...........######....... 00 1f 80
#>C:6279 ...........#######...... 00 1f c0
#>C:627c ...........#######.#.... 00 1f d0
#...sprite data in $6440 is wrong. It's wrong in the .spr file as well. It must be. It is.
#So, sprconv/convert does something iffy.
#Patched sprite_image_1.spr manually:   row 136 in Sublime text changed into:
#0000 00ff c000 f000 00c0 0000 0000 0000


