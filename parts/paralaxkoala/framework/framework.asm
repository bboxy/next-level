#if !release
	.var music = LoadSid("music.sid")
	.var music_init = music.init
	.var music_play = music.play
	
	*=music.location "Music"
   // .fill music.size, music.getData(i)
   rts
   nop
   rts
#endif
.var framecount = $02
.import source "pseudocommands.asm"
.import source "macros.asm"

