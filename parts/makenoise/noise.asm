;important after conversion!!!!

;delete loop info from header to save $80 bytes
;set endflag $00 of song at the end of sampledata

;to do:

;NUFLI label generator
;$d020 writes:
;99x black+white sample writes, 156 cyan clear writes
;1x purple write $0b to $d021
;all other colors are real $d020 writes!!!!

;coming from intro:

;load banzai in 5 parts
;$0400-$8280
;$8280-$9800
;$a000-$d000
;$d000-$fff0
;$9800-$a000

			processor 6502
			incdir "../../util/dasm/include"
			include "standard.asm"
;------------------------------------------------------------------------------
;global settings
;------------------------------------------------------------------------------
			ifnconst release

timingcolors		equ 0			;0=no colors 1=display rastertiming
			else
timingcolors		equ 0			;always 0, no colors wanted on release
			endif

extlabels		equ 0			;0=simulate NUFLI labels, 1=load external NUFLI labels

volumesupport		equ 0			;0=no global volume support 1=turn on global volume support

globalfilter		equ $00			;global filter setting for 6581 $d418 output + sid

use3bit			equ 0			;0=4bit output 1=3bit output volumes 8-15

detachmixer		equ 0			;0=mixing in main thread, no loading possible 1=detach mixer from irq, mustn't use more than one frame to mix!
						;set to 0 to avoid crashing of too long mixing times

fastjitter		equ 0			;0=use safe 8 cycle jitter 1=use faster 7 cycle jitter
						;might crash depending on sid replayer

external		equ 0			;0=use internal settings 1=include external settings

;------------------------------------------------------------------------------
;internal settings
;------------------------------------------------------------------------------
			if external=1
			include "thc_settings.asm"
			else			;external=1
preset			equ 0			;0 = user defined
						;1 = 4ch ProTracker
						;2 = MLC1
						;3 = SCC Loop Station
						;4 = Fast delay
						;5 = 4ch 8bit signed
						;6 = other specs
						;7 = Fantasmolytic
						;8 = MLC1+
						;9 = MLC1 Foldback

loops			equ 0			;0=no looped samples
includesid		equ 0			;0=no sid tune 1=play sid
volumeboost		equ 0			;possible values are 0-8 for 0, 25 ,50 , 75, 100 ,125, 150, 175, 200% boost, 9 for global volume / foldback tables
sampleoutput		equ 3			;0=waveform 8bit 1=digimax for emulator 2=4bit $d418  3=7bit $d418  4=$d020 colors  5=$d021 colors 6=pwm gate
						;if sampleoutput=2 or 3 then volumeboost has to be 0 !!!
replayrate		equ 0			;0=7812hz (1=11718hz 2=15624hz stablenmi has to be 0!)
bitdepth		equ 4			;0=4 bit samples 1=5 bit samples 2=6bit samples 3=7bit samples 4=8bit samples mixing
signed			equ 0			;0=unsigned samples 1=signed samples, needed for loop station mixing
loopstation		equ 0 			;0=disbale loop station 1=enable loop station with sample 31 as loop buffer
digivoices		equ 1			;2, 3 or 4 digi voices
sampleoffsetsupport	equ 1			;0=no global sampleoffset support 1=turn on global sampleoffset support
stablenmi		equ 0			;0=use normal nmi 1=use stable nmi
screen			equ 1			;0=screen off 1=screen on
controlchannel		equ 0			;0=no control channel 1=use last channel as control channel
siddelay		equ 8			;first delay of the modplay to sync goatracker sid and protracker module
			    			;values from 0 to 127 are valid
						;Fanta (Goat) uses delay of 7
						;Mahoney (Goat) uses delay of 1
						;LMan (Cheesecutter) uses delay of 4
multispeed		equ 1			;1=single speed, 2=double speed, 3=triple speed
rleimproved		equ 0			;enables better rle mode decompression
cc2patch		equ 0			;0=do nothing 1=try to prevent cheesecutter2 from playing 3rd voice
						;uses a simple check to identify a cheesecutter sid file, only set to 0 to save space
playinterleave		equ 0			;replay using interleaved data
playlzstream		equ 0			;replay lz compressed interleaved data, needs playinterleave=1
deltacoding		equ 0			;0=normal samples 1=delta packed samples

			endif	;external
;------------------------------------------------------------------------------
;zeropage
;------------------------------------------------------------------------------
zeropagecode		equ $02		;start of zeropage routines up to $ed

goatlo			equ $fe		;used by sid replayer
goathi			equ $ff

;------------------------------------------------------------------------------
;volumetable vars
;------------------------------------------------------------------------------
;replayer vars
zp			equ $80
clearstart		equ zp
samplefetch1a		equ zp+$00-1
samplefetch1b		equ zp+$02-1
samplefetch1c		equ zp+$04-1
samplefetch1d		equ zp+$06-1
voice1active		equ zp+$08				;4 bytes=4 voices - sample on $01, looped $ff or off $00
areg			equ zp+$09
xreg			equ zp+$0a
yreg			equ zp+$0b
lines 			equ zp+$0c
temp 			equ zp+$0d
srclo			equ zp+$0e
srchi			equ zp+$0f
destlo 			equ zp+$10
desthi 			equ zp+$11
dest2lo			equ zp+$12
dest2hi			equ zp+$13
adrlo			equ zp+$14
adrhi			equ zp+$15
d011temp		equ zp+$16				;needed for one cycle jitter

clearend		equ zp+$17

;------------------------------------------------------------------------------
;constants
;------------------------------------------------------------------------------
periodsteplength	equ 39				;39 stepbytes per note

mixingbufferlength	equ 156-periodsteplength	;312 rasterlines/2
nmifreq			equ $007d

samples			equ 31				;samples 0-31

plotypos		equ 18

thc_chn1vol		equ 0
thc_chn1per		equ 0
thc_chn1off		equ 1

;------------------------------------------------------------------------------
;tables
;------------------------------------------------------------------------------
;free mem during display
;$8000-$827f samples until $8214
;$82a8-$83f7 d418tab8580
;$8400-$87f7 songdata from $8400-$86f1 / silentbuffer @$8700
;$9742-$9fff nuflicode before / loading Goat @ $9800
;$b000-$b1ff free
;$b300-$b3ff d418tab
;$fa00-$fff7 main code

silentbuffer		equ $0800
mixingbuffer		equ $0800
;mixingbuffer1		equ $b000
;mixingbuffer2		equ $b100

;memory adresses
stack			equ $0100
stackcode		equ $0100

d418tab			equ $0400
resortbuffer		equ $0500

screen0line16		equ $8280
spritepointer0b		equ $83f8
spritepointer1		equ $87f8
screen1line16 		equ $a280
spritepointer0a		equ $a3f8
plotpointer		equ $bff8

bitmapfix0		equ $b3d8
bitmapfix1		equ $f3d8
spritepointer2		equ $fff8

sprite1colors 		equ $a400
sprite2colors 		equ $a480
sprite3colors 		equ $a800
sprite4colors 		equ $a880
sprite5colors 		equ $ac00
sprite6colors 		equ $ac80
vicinit 		equ $bfc0
spritemc1 		equ $bff0
spritemc2 		equ $bff1
sprite7color		equ $bff6
sprite0color		equ $bff7

nuflicode 		equ $8800	;generated rastercode

			ifnconst release
			org $0801
			;basic sys line
			dc.b $0b,$08,$00,$00,$9e,$32,$30,$36
			dc.b $31,$00,$00,$00
			sei
			lda #$35
			sta $01
			jmp main
			else
			include "../../bitfire/loader/loader_acme.inc"
			include "../../bitfire/macros/link_macros_dasm.inc"
			endif
			
			org $1b00

;------------------------------------------------------------------------------
;translate tables
;------------------------------------------------------------------------------
amplitude		= 96
shift			= 0
translate00
			ds.b (256-amplitude + shift) / 2, 0
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $00
x			set x+1
			repend
			ds.b (256-amplitude - shift) / 2,0 + 60

translate01
			ds.b (256-amplitude + shift) / 2,1
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $01
x			set x+1
			repend
			ds.b (256-amplitude - shift) / 2,1 + 60

			
translate02
			ds.b (256-amplitude + shift) / 2,2
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $02
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,2 + 60
			
translate40
			ds.b (256-amplitude + shift) / 2,$40
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $40
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,$40 + 60
			
translate41
			ds.b (256-amplitude + shift) / 2,$41
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $41
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,$41 + 60
			
translate42
			ds.b (256-amplitude + shift) / 2,$42
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $42
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,$42 + 60
			
translate80
			ds.b (256-amplitude + shift) / 2,$80
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $80
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,$80 + 60
			
translate81
			ds.b (256-amplitude + shift) / 2,$81
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $81
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,$81 + 60
			
translate82
			ds.b (256-amplitude + shift) / 2,$82
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $82
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,$82 + 60
			
translatec0
			ds.b (256-amplitude + shift) / 2,$c0
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $c0
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,$c0 + 60
			
translatec1
			ds.b (256-amplitude + shift) / 2,$c1
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $c1
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,$c1 + 60
			
translatec2
			ds.b (256-amplitude + shift) / 2,$c2
x			set 0
			repeat amplitude
			dc.b (((<(x)) * 21) / amplitude) * 3 + $c2
x			set x+1
			repend
			ds.b (256-amplitude-shift) / 2,$c2 + 60

;------------------------------------------------------------------------------
;mixer
;------------------------------------------------------------------------------
			
; clear0			equ $08f0
; clear1			equ $08f0
; clear2			equ $08f0
; clear3			equ $08f0
; clear4			equ $08f0
; clear5			equ $08f0
; clear6			equ $08f0
; clear7			equ $08f0
; clear8			equ $08f0
; clear9			equ $08f0
; clear10			equ $08f0
; clear11			equ $08f0
; clear12			equ $08f0
; clear13			equ $08f0
; clear14			equ $08f0
; clear15			equ $08f0
; clear16			equ $08f0
; clear17			equ $08f0
; clear18			equ $08f0
; clear19			equ $08f0
; clear20			equ $08f0
; clear21			equ $08f0
; clear22			equ $08f0
; clear23			equ $08f0
; clear24			equ $08f0
; clear25			equ $08f0
; clear26			equ $08f0
; clear27			equ $08f0
; clear28			equ $08f0
; clear29			equ $08f0
; clear30			equ $08f0
; clear31			equ $08f0
; clear32			equ $08f0
; clear33			equ $08f0
; clear34			equ $08f0
; clear35			equ $08f0
; clear36			equ $08f0
; clear37			equ $08f0
; clear38			equ $08f0
; clear39			equ $08f0
; clear40			equ $08f0
; clear41			equ $08f0
; clear42			equ $08f0
; clear43			equ $08f0
; clear44			equ $08f0
; clear45			equ $08f0
; clear46			equ $08f0
; clear47			equ $08f0
; clear48			equ $08f0
; clear49			equ $08f0
; clear50			equ $08f0
; clear51			equ $08f0
; clear52			equ $08f0
; clear53			equ $08f0
; clear54			equ $08f0
; clear55			equ $08f0
; clear56			equ $08f0
; clear57			equ $08f0
; clear58			equ $08f0
; clear59			equ $08f0
; clear60			equ $08f0
; clear61			equ $08f0
; clear62			equ $08f0
; clear63			equ $08f0
; clear64			equ $08f0
; clear65			equ $08f0
; clear66			equ $08f0
; clear67			equ $08f0
; clear68			equ $08f0
; clear69			equ $08f0
; clear70			equ $08f0
; clear71			equ $08f0
; clear72			equ $08f0
; clear73			equ $08f0
; clear74			equ $08f0
; clear75			equ $08f0
; clear76			equ $08f0
; clear77			equ $08f0
; clear78			equ $08f0
; clear79			equ $08f0
; clear80			equ $08f0
; clear81			equ $08f0
; clear82			equ $08f0
; clear83			equ $08f0
; clear84			equ $08f0
; clear85			equ $08f0
; clear86			equ $08f0
; clear87			equ $08f0
; clear88			equ $08f0
; clear89			equ $08f0
; clear90			equ $08f0
; clear91			equ $08f0
; clear92			equ $08f0
; clear93			equ $08f0
; clear94			equ $08f0
; clear95			equ $08f0
; clear96			equ $08f0
; clear97			equ $08f0
; clear98			equ $08f0
; clear99			equ $08f0
; clear100		equ $08f0
; clear101		equ $08f0
; clear102		equ $08f0
; clear103		equ $08f0
; clear104		equ $08f0
; clear105		equ $08f0
; clear106		equ $08f0
; clear107		equ $08f0
; clear108		equ $08f0
; clear109		equ $08f0
; clear110		equ $08f0
; clear111		equ $08f0
; clear112		equ $08f0
; clear113		equ $08f0
; clear114		equ $08f0
; clear115		equ $08f0
; clear116		equ $08f0
; clear117		equ $08f0
; clear118		equ $08f0
; clear119		equ $08f0
; clear120		equ $08f0
; clear121		equ $08f0
; clear122		equ $08f0
; clear123		equ $08f0
; clear124		equ $08f0
; clear125		equ $08f0
; clear126		equ $08f0
; clear127		equ $08f0
; clear128		equ $08f0
; clear129		equ $08f0
; clear130		equ $08f0
; clear131		equ $08f0
; clear132		equ $08f0
; clear133		equ $08f0
; clear134		equ $08f0
; clear135		equ $08f0
; clear136		equ $08f0
; clear137		equ $08f0
; clear138		equ $08f0
; clear139		equ $08f0
; clear140		equ $08f0
; clear141		equ $08f0
; clear142		equ $08f0
; clear143		equ $08f0
; clear144		equ $08f0
; clear145		equ $08f0
; clear146		equ $08f0
; clear147		equ $08f0
; clear148		equ $08f0
; clear149		equ $08f0
; clear150		equ $08f0
; clear151		equ $08f0
; clear152		equ $08f0
; clear153		equ $08f0
; clear154		equ $08f0
; clear155		equ $08f0
;------------------------------------------------------------------------------
; mix0			equ $0800
; mix1			equ $0801
; mix2			equ $0802
; mix3			equ $0803
; mix4			equ $0804
; mix5			equ $0805
; mix6			equ $0806
; mix7			equ $0807
; mix8			equ $0808
; mix9			equ $0809
; mix10			equ $080a
; mix11			equ $080b
; mix12			equ $080c
; mix13			equ $080d
; mix14			equ $080e
; mix15			equ $080f
; mix16			equ $0810
; mix17			equ $0811
; mix18			equ $0812
; mix19			equ $0813
; mix20			equ $0814
; mix21			equ $0815
; mix22			equ $0816
; mix23			equ $0817
; mix24			equ $0818
; mix25			equ $0819
; mix26			equ $081a
; mix27			equ $081b
; mix28			equ $081c
; mix29			equ $081d
; mix30			equ $081e
; mix31			equ $081f
; mix32			equ $0820
; mix33			equ $0821
; mix34			equ $0822
; mix35			equ $0823
; mix36			equ $0824
; mix37			equ $0825
; mix38			equ $0826
mix39			equ $0827-1
mix40			equ $0828-1
mix41			equ $0829-1
mix42			equ $082a-1
mix43			equ $082b-1
mix44			equ $082c-1
mix45			equ $082d-1
mix46			equ $082e-1
mix47			equ $082f-1
mix48			equ $0830-1
mix49			equ $0831-1
mix50			equ $0832-1
;mix51			equ $0833 IRQ1 
;mix52			equ $0834 IRQ1
;mix53			equ $0835 IRQ1
;mix54			equ $0836 IRQ1

; mix55			equ $0837 Nuflicode
; mix56			equ $0838
; mix57			equ $0839
; mix58			equ $083a
; mix59			equ $083b
; mix60			equ $083c
; mix61			equ $083d
; mix62			equ $083e
; mix63			equ $083f
; mix64			equ $0840
; mix65			equ $0841
; mix66			equ $0842
; mix67			equ $0843
; mix68			equ $0844
; mix69			equ $0845
; mix70			equ $0846
; mix71			equ $0847
; mix72			equ $0848
; mix73			equ $0849
; mix74			equ $084a
; mix75			equ $084b
; mix76			equ $084c
; mix77			equ $084d
; mix78			equ $084e
; mix79			equ $084f
; mix80			equ $0850
; mix81			equ $0851
; mix82			equ $0852
; mix83			equ $0853
; mix84			equ $0854
; mix85			equ $0855
; mix86			equ $0856
; mix87			equ $0857
; mix88			equ $0858
; mix89			equ $0859
; mix90			equ $085a
; mix91			equ $085b
; mix92			equ $085c
; mix93			equ $085d
; mix94			equ $085e
; mix95			equ $085f
; mix96			equ $0860
; mix97			equ $0861
; mix98			equ $0862
; mix99			equ $0863
; mix100			equ $0864
; mix101			equ $0865
; mix102			equ $0866
; mix103			equ $0867
; mix104			equ $0868
; mix105			equ $0869
; mix106			equ $086a
; mix107			equ $086b
; mix108			equ $086c
; mix109			equ $086d
; mix110			equ $086e
; mix111			equ $086f
; mix112			equ $0870
; mix113			equ $0871
; mix114			equ $0872
; mix115			equ $0873
; mix116			equ $0874
; mix117			equ $0875
; mix118			equ $0876
; mix119			equ $0877
; mix120			equ $0878
; mix121			equ $0879
; mix122			equ $087a
; mix123			equ $087b
; mix124			equ $087c
; mix125			equ $087d
; mix126			equ $087e
; mix127			equ $087f
; mix128			equ $0880
; mix129			equ $0881
; mix130			equ $0882
; mix131			equ $0883
; mix132			equ $0884
; mix133			equ $0885
; mix134			equ $0886
; mix135			equ $0887
; mix136			equ $0888
; mix137			equ $0889
; mix138			equ $088a
; mix139			equ $088b
; mix140			equ $088c
; mix141			equ $088d
; mix142			equ $088e
; mix143			equ $088f
; mix144			equ $0890
; mix145			equ $0891
; mix146			equ $0892
; mix147			equ $0893
; mix148			equ $0894
; mix149			equ $0895
; mix150			equ $0896
; mix151			equ $0897
; mix152			equ $0898
; mix153			equ $0899
; mix154			equ $089a

;mix155			equ $089b end of IRQ1
			endif
			
;------------------------------------------------------------------------------
			mac plotmix
			ldy #{1}%39
			
			if {1}/39=0
			lax (samplefetch1a+1),y
			endif
			if {1}/39=1
			lax (samplefetch1b+1),y
			endif
			if {1}/39=2
			lax (samplefetch1c+1),y
			endif
			if {1}/39=3
			lax (samplefetch1d+1),y
			endif
			
			if {1}/39=0
			sta $d418
			else
			sta mix{1}+1
			endif
			
	
			if {1} < 8
			ldy translate00,x
			else
			if {1} < 16
			ldy translate01,x
			else
			if {1} < 24
			ldy translate02,x
			else
			if {1} < 32
			ldy translate40,x
			else
			if {1} < 40
			ldy translate41,x
			else
			if {1} < 48
			ldy translate42,x
			else
			if {1} < 56
			ldy translate80,x
			else
			if {1} < 64
			ldy translate81,x
			else
			if {1} < 72
			ldy translate82,x
			else
			if {1} < 80
			ldy translatec0,x
			else
			if {1} < 88
			ldy translatec1,x
			else
			if {1} < 96
			ldy translatec2,x
			else
			if {1} < 104
			ldy translate00,x
			else
			if {1} < 112
			ldy translate01,x
			else
			if {1} < 120
			ldy translate02,x
			else
			if {1} < 128
			ldy translate40,x
			else
			if {1} < 136
			ldy translate41,x
			else
			if {1} < 144
			ldy translate42,x
			else
			if {1} < 152
			ldy translate80,x
			else
			ldy translate81,x
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			endif
			
;			if {1}%8=1
;			lsr
;			else
;			if {1}%8!=7 
			lda #[1<<[7-[{1}&7]]]
;			endif
;			endif

			if {1}<96 
;			if {1}%8 = 7
;			inc plotsprites,x
;			else
;			if {1}%8 != 0 
			ora plotsprites,y
;			endif
			sta plotsprites,y
;			endif
			
			else
			
;			if {1}%8=7
;			inc plotsprites+$100,x
;			else
;			if {1}%8!=0
			ora plotsprites+$100,y
;			endif
			sta plotsprites+$100,y
;			endif
			endif
			sty clear{1}+1
			endm

mixdelay		equ 5

mixer			subroutine
			plotmix 0
			plotmix 39
			plotmix 78
			plotmix 117
			delay mixdelay
;-----------------------			
			plotmix 1
			plotmix 40
			plotmix 79
			plotmix 118
			delay mixdelay
;-----------------------			
			plotmix 2
			plotmix 41
			plotmix 80
			plotmix 119
			delay mixdelay
;-----------------------			
			plotmix 3
			plotmix 42
			plotmix 81
			plotmix 120
			delay mixdelay
;-----------------------			
			plotmix 4
			plotmix 43
			plotmix 82
			plotmix 121
			delay mixdelay
;-----------------------			
			plotmix 5
			plotmix 44
			plotmix 83
			plotmix 122
			delay mixdelay
;-----------------------			
			plotmix 6
			plotmix 45
			plotmix 84
			plotmix 123
			delay mixdelay
;-----------------------			
			plotmix 7
			plotmix 46
			plotmix 85
			plotmix 124
			delay mixdelay
;-----------------------			
			plotmix 8
			plotmix 47
			plotmix 86
			plotmix 125
			delay mixdelay
;-----------------------			
			plotmix 9
			plotmix 48
			plotmix 87
			plotmix 126
			delay mixdelay
;-----------------------			
			plotmix 10
			plotmix 49
			plotmix 88
			plotmix 127
			delay mixdelay
;-----------------------			
			plotmix 11
			plotmix 50
			plotmix 89
			plotmix 128
			delay mixdelay
;-----------------------			
			plotmix 12
			plotmix 51
			plotmix 90
			plotmix 129
			delay mixdelay
;-----------------------			
			plotmix 13
			plotmix 52
			plotmix 91
			plotmix 130
			delay mixdelay
;-----------------------			
			plotmix 14
			plotmix 53
			plotmix 92
			plotmix 131
			delay mixdelay
;-----------------------			
			plotmix 15
			plotmix 54
			plotmix 93
			plotmix 132
			delay mixdelay
;-----------------------			
			plotmix 16
			plotmix 55
			plotmix 94
			plotmix 133
			delay mixdelay
;-----------------------			
			plotmix 17
			plotmix 56
			plotmix 95
			plotmix 134
			delay mixdelay
;-----------------------			
			plotmix 18
			plotmix 57
			plotmix 96
			plotmix 135
			delay mixdelay
;-----------------------			
			plotmix 19
			plotmix 58
			plotmix 97
			plotmix 136
			delay mixdelay
;-----------------------			
			plotmix 20
			plotmix 59
			plotmix 98
			plotmix 137
;			delay mixdelay
			lda #plotypos
			sta $d001
;-----------------------			
			plotmix 21
			plotmix 60
			plotmix 99
			plotmix 138
;			delay mixdelay
			lda #plotypos
			sta $d003
;-----------------------			
			plotmix 22
			plotmix 61
			plotmix 100
			plotmix 139
;			delay mixdelay
			lda #plotypos
			sta $d005
;-----------------------			
			plotmix 23
			plotmix 62
			plotmix 101
			plotmix 140
;			delay mixdelay
			lda #plotypos
			sta $d007
;-----------------------			
			plotmix 24
			plotmix 63
			plotmix 102
			plotmix 141
;			delay mixdelay
			lda #plotypos
			sta $d009
;-----------------------			
			plotmix 25
			plotmix 64
			plotmix 103
			plotmix 142
;			delay mixdelay
			lda #plotypos
			sta $d00b
;-----------------------			
			plotmix 26
			plotmix 65
			plotmix 104
			plotmix 143
;			delay mixdelay
			lda #plotypos
			sta $d00d
;-----------------------	
			plotmix 27
			plotmix 66
			plotmix 105
			plotmix 144
;			delay mixdelay
d015switch		lda #$7f
			sta $d015
;-----------------------			
			plotmix 28
			plotmix 67
			plotmix 106
			plotmix 145
			delay mixdelay
;-----------------------			
			plotmix 29
			plotmix 68
			plotmix 107
			plotmix 146
			delay mixdelay
;-----------------------			
			plotmix 30
			plotmix 69
			plotmix 108
			plotmix 147
			delay mixdelay
;-----------------------			
			plotmix 31
			plotmix 70
			plotmix 109
			plotmix 148
			delay mixdelay
;-----------------------			
			plotmix 32
			plotmix 71
			plotmix 110
			plotmix 149
			delay mixdelay
;-----------------------			
			plotmix 33
			plotmix 72
			plotmix 111
			plotmix 150
			delay mixdelay
;-----------------------			
			plotmix 34
			plotmix 73
			plotmix 112
			plotmix 151
			delay mixdelay
;-----------------------			
			plotmix 35
			plotmix 74
			plotmix 113
			plotmix 152
			delay mixdelay
;-----------------------			
			plotmix 36
			plotmix 75
			plotmix 114
			plotmix 153
			delay mixdelay
;-----------------------			
			plotmix 37
			plotmix 76
			plotmix 115
			plotmix 154
			lda #39			;nmi plays sample 39 bis 50
			sta fetch+1
;-----------------------			
lastm			plotmix 38		;line 15 sample 038
			plotmix 77
			plotmix 116
			plotmix 155
;-----------------------
			rts

;------------------------------------------------------------------------------
;nmi-replayer
;------------------------------------------------------------------------------
nmi_start
	 		rorg zeropagecode
;------------------------------------------------------------------------------
nmiplay			subroutine
;------------------------------------------------------------------------------
nmiplaybuf		sta abuf+1
fetch			lda mixingbuffer
			sta $d418
			inc fetch+1
abuf			lda #$00
			jmp $dd0c

;------------------------------------------------------------------------------
;8bit mixing
;------------------------------------------------------------------------------
; samplefetch1a		lda silentbuffer,x
; mixswitch1		sta mixingbuffer,x
; samplefetch1b		lda silentbuffer,x
; mixswitch2		sta mixingbuffer+periodsteplength,x
; samplefetch1c		lda silentbuffer,x
; mixswitch3		sta mixingbuffer+periodsteplength*2,x
; samplefetch1d		lda silentbuffer,x
; mixswitch4		sta mixingbuffer+periodsteplength*3,x
									; ;12*4=48
			; dex						;2
			; bpl samplefetch1a				;3
; .exit			rts

			rend
nmi_end

;---------------------------------------
;mixing routine
;bcs springt wenn 1. wert größer oder gleich
;bcc springt wenn 1. wert kleiner ist

;wenn voiceactive=0 spiele silentbuffer
;wenn voiceactive=1 prüfe ob neue note getriggered wurde bzw. spiele alt note weiter
;
;------------------------------------------------------------------------------
;mixer macros
;{1}=voice number
;{2]=0 - volume off 1=volume on
;{3}=0 - period always 453 1 - periods on
;{4}=0 - sampleoffset off  1 - sampleoffset on

;------------------------------------------------------------------------------
			mac mixvoice
			if {3}=1	;period on
period{1}delay		lda #$00
			bne .exitperioddelay

			if playinterleave=0
period{1}datapointer	lax $1000
			else
			jsr lzsgetbyte
			tax
			endif

			bmi .setperioddelay

			sta note{1}+1
			lda notestablelo,x
			sta notefetch{1}+1
			lda notestablehi,x
			sta notefetch{1}+2

			if playinterleave=0
			inc period{1}datapointer+1
			bne .volumedepack
			inc period{1}datapointer+2
			bne .volumedepack
			else
			jmp .volumedepack
			endif

.setperioddelay		and #%01111111
;			sec
;			sbc #$01
			sta period{1}delay+1

			if playinterleave=0
			inc period{1}datapointer+1
			bne .volumedepack
			inc period{1}datapointer+2
			bne .volumedepack
			else
			jmp .volumedepack
			endif

.exitperioddelay	dec period{1}delay+1

			endif	;{3}=1	period on
.volumedepack
;------------------------------------------------------------------------------
			if {2}=1
volume{1}delay		lda #$00
			bne .exitvolumedelay

			if playinterleave=0
volume{1}datapointer	lax $1000
			else
			jsr lzsgetbyte
			tax
			endif

			if rleimproved=1
			bpl .setvolume
			else
			bpl .setvolume3
			endif

			and #%01111111
			sta volume{1}delay+1

			if playinterleave=0
			inc volume{1}datapointer+1
			bne .offsetdepack
			inc volume{1}datapointer+2
			bne .offsetdepack
			else
			jmp .offsetdepack
			endif

			if rleimproved=1
prev{1}volume1		dc.b $00
prev{1}volume2		dc.b $00
prev{1}volume3		dc.b $00

.setvolume		and #%01100000
			beq .setvolume2
			asl
			asl
			rol
			rol
			stx .xsave1+1
			tax
			lda prev{1}volume1-1,x
			sta .storevolume+1
.xsave1			ldx #$00
			inx
			lda #%00011111
			sax volume{1}delay+1
			jmp .storevolume

.setvolume2		lda prev{1}volume2
			sta prev{1}volume3
			lda prev{1}volume1
			sta prev{1}volume2
			stx prev{1}volume1
			stx .storevolume+1

.storevolume		lda #$00
			endif			;rleimproved=1

.setvolume3		clc
			adc #>volumetable
			sta mix{1}a+2
			sta mix{1}b+2
			sta mix{1}c+2
			sta mix{1}d+2
			if replayrate>0
			sta mix{1}e+2
			sta mix{1}f+2
			endif
			if replayrate>1
			sta mix{1}g+2
			sta mix{1}h+2
			endif

			if playinterleave=0
			inc volume{1}datapointer+1
			bne .offsetdepack
			inc volume{1}datapointer+2
			bne .offsetdepack
			else
			jmp .offsetdepack
			endif

.exitvolumedelay	dec volume{1}delay+1

			endif	;{2]=1
;------------------------------------------------------------------------------
.offsetdepack		if sampleoffsetsupport=1
			if {4}=1
			lda #$00
			sta offsethi{1}+1
			sta offsetlo{1}+1

offset{1}delay		lda #$00
			bne .exitoffsetdelay
			if playinterleave=0
offset{1}datapointer	lda $1000
			else
			jsr lzsgetbyte
			tax
			endif

			bpl .setoffset

			and #%01111111
;			sec
;			sbc #$01
			sta offset{1}delay+1

			if playinterleave=0
			inc offset{1}datapointer+1
			bne .sampledepack
			inc offset{1}datapointer+2
			bne .sampledepack
			else
			jmp .sampledepack
			endif

.setoffset		sta offsethi{1}+1

			if playinterleave=0
			lda offset{1}datapointer+1
			sta goatlo
			lda offset{1}datapointer+2
			sta goathi

			ldy #$01
			lda (goatlo),y
			else
			jsr lzsgetbyte
			endif

			sta offsetlo{1}+1

			if playinterleave=0
			lda offset{1}datapointer+1
			clc
			adc #$02
			sta offset{1}datapointer+1
			bcc .sampledepack
			inc offset{1}datapointer+2
			bne .sampledepack
			else
			jmp .sampledepack
			endif

.exitoffsetdelay	dec offset{1}delay+1
			endif	;{4}=1
			endif	;sampleoffsetsupport=1
;------------------------------------------------------------------------------
.sampledepack

sample{1}delay		lda #$00
			if rleimproved=1
			beq preserve{1}sample
			else
			beq sample{1}datapointer
			endif

			dec sample{1}delay+1
			jmp .nonewnote

			if {1}=1
.endofsong		lda #$60		;rts
			sta replayer
			sta mixer
			lda #$00
			sta d015switch+1
			rts
			endif			;{1}=1

			if rleimproved=1
prev{1}sample1		dc.b $00
prev{1}sample2		dc.b $00
prev{1}sample3		dc.b $00

preserve{1}sample	lda #$00
			beq sample{1}datapointer
			ldx #$00
			stx preserve{1}sample+1
			jmp .storesample
			endif

			if playinterleave=0
sample{1}datapointer	lax $1000
			if {1}=1
			beq .endofsong
			endif
			else
sample{1}datapointer	jsr lzsgetbyte
			tax
			endif

			if rleimproved=1
			bpl .triggersample
			else
			bpl .setsample
			endif

			and #%01111111
			sta sample{1}delay+1

			if rleimproved=1
			jmp .zeroinc2

.triggersample		and #%01100000
			beq .setsample
			asl
			asl
			rol
			rol
			stx .xsave2+1
			tax
			lda prev{1}sample1-1,x
			sta preserve{1}sample+1
.xsave2			ldx #$00
			lda #%00011111
			sax sample{1}delay+1
			endif				;rleimproved=1

.zeroinc2		if playinterleave=0
			inc sample{1}datapointer+1
			bne .nonewnote
			inc sample{1}datapointer+2
			bne .nonewnote
			else
			jmp .nonewnote
			endif				;playinterleave=0

.setsample		
;			cmp #$07			;end marker empty sample
;			beq .endofsong
			if rleimproved=1
			txa
			endif

			if playinterleave=0
			inc sample{1}datapointer+1
			bne .noinc2
			inc sample{1}datapointer+2
			endif

.noinc2			if rleimproved=1
			ldx prev{1}sample2
			stx prev{1}sample3
			ldx prev{1}sample1
			stx prev{1}sample2
			sta prev{1}sample1
			endif

.storesample		sta sound{1}+1
			tax

;------------------------------------------------------------------------------

			if sampleoffsetsupport=1

			if {4}=1
			lda samplestartlo,x
			clc
offsetlo{1}		adc #$00
			sta samplefetch{1}a+1
			lda samplestarthi,x
offsethi{1}		adc #$00
			sta samplefetch{1}a+2
			else
			lda samplestarthi,x
			sta samplefetch{1}a+2
			lda samplestartlo,x
			sta samplefetch{1}a+1
			endif	;{4}=1

			else	;sampleoffset=0

			lda samplestarthi,x
			sta samplefetch{1}a+2
			lda samplestartlo,x
			sta samplefetch{1}a+1

			endif	;sampleoffset=1

			if playlzstream=1
			sty lzsysave{1}+1
			endif
			
			if loops=1
			lda loopposhi,x
			beq .noloop2

			if {3}=1
			lda #$00
			sta sample{1}frac
			endif
			lda #$ff
			sta voice{1}active
			jmp .preppart2
			else
			lda #$00
			endif

.noloop2		if {3}=1
			sta sample{1}frac
			endif
			lda #$01
			sta voice{1}active
			jmp .preppart2

.nonewnote		if playlzstream=1
			sty lzsysave{1}+1
			endif
			ldx voice{1}active
			bne .preppart1

.stopvoice1		lda #>silentbuffer
			stx samplefetch{1}a+1
			sta samplefetch{1}a+2
.stopvoice2		stx samplefetch{1}b+1
			sta samplefetch{1}b+2
.stopvoice3		stx samplefetch{1}c+1
			sta samplefetch{1}c+2
.stopvoice4		stx samplefetch{1}d+1
			sta samplefetch{1}d+2
			if replayrate>0
.stopvoice5		stx samplefetch{1}e+1
			sta samplefetch{1}e+2
.stopvoice6		stx samplefetch{1}f+1
			sta samplefetch{1}f+2
			endif	;replayrate=0
			if replayrate>1
.stopvoice7		stx samplefetch{1}g+1
			sta samplefetch{1}g+2
.stopvoice8		stx samplefetch{1}h+1
			sta samplefetch{1}h+2
			endif
			stx voice{1}active
			jmp .nextvoice

.preppart1
sound{1}		ldy #$00

			if {3}=1
note{1}			ldx #$00
			lda sample{1}frac
			clc
			adc notesaddfrac,x
			sta sample{1}frac

			if replayrate=0
			lda samplefetch{1}d+1
			adc notesaddlo,x
			sta samplefetch{1}a+1
			lda samplefetch{1}d+2
			adc #$00
			sta samplefetch{1}a+2
			endif

			if replayrate=1
			lda samplefetch{1}f+1
			adc notesaddlo,x
			sta samplefetch{1}a+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}a+2
			endif

			if replayrate=2
			lda samplefetch{1}h+1
			adc notesaddlo,x
			sta samplefetch{1}a+1
			lda samplefetch{1}h+2
			adc #$00
			sta samplefetch{1}a+2
			endif

			else	;{3}=0

			if replayrate=0
			lda samplefetch{1}d+1
			clc
			adc #periodsteplength
			sta samplefetch{1}a+1
			lda samplefetch{1}d+2
			adc #$00
			sta samplefetch{1}a+2
			endif
			if replayrate=1
			lda samplefetch{1}f+1
			clc
			adc #periodsteplength
			sta samplefetch{1}a+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}a+2
			endif
			if replayrate=2
			lda samplefetch{1}h+1
			clc
			adc #periodsteplength
			sta samplefetch{1}a+1
			lda samplefetch{1}h+2
			adc #$00
			sta samplefetch{1}a+2
			endif
			endif	;{3}=0

			lda samplefetch{1}a+1
			cmp sampleendlo,y
			lda samplefetch{1}a+2
			sbc sampleendhi,y
			bcc .preppart2

			if loops=1
			lda voice{1}active
			bmi .loop1
			endif
			
			ldx #$00
			jmp .stopvoice1
			
			if loops=1
.loop1			lda samplefetch{1}a+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}a+1
			lda samplefetch{1}a+2
			sbc looplengthhi,y
			sta samplefetch{1}a+2
			clc
			endif
			
.preppart2		ldy sound{1}+1

			if {3}=1
			ldx note{1}+1

			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}a+1
			adc notesaddlo,x
			sta samplefetch{1}b+1
			lda samplefetch{1}a+2
			adc #$00
			sta samplefetch{1}b+2

			else	;{3}=0

			lda samplefetch{1}a+1		;always playing period 453
			adc #periodsteplength
			sta samplefetch{1}b+1
			lda samplefetch{1}a+2
			adc #$00
			sta samplefetch{1}b+2
			endif	;{3}=0

			lda samplefetch{1}b+1
			cmp sampleendlo,y
			lda samplefetch{1}b+2
			sbc sampleendhi,y
			bcc .preppart3

			if loops=1
			lda voice{1}active
			bmi .loop2
			endif
			
			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice2

			if loops=1
.loop2			lda samplefetch{1}b+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}b+1
			lda samplefetch{1}b+2
			sbc looplengthhi,y
			sta samplefetch{1}b+2
			clc
			endif
;------------------------------------------------------------------------------
.preppart3		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}b+1
			adc notesaddlo,x
			sta samplefetch{1}c+1
			lda samplefetch{1}b+2
			adc #$00
			sta samplefetch{1}c+2

			else	;{3}=0

			lda samplefetch{1}b+1
			adc #periodsteplength
			sta samplefetch{1}c+1
			lda samplefetch{1}b+2
			adc #$00
			sta samplefetch{1}c+2
			endif	;{3}=0

			lda samplefetch{1}c+1
			cmp sampleendlo,y
			lda samplefetch{1}c+2
			sbc sampleendhi,y
			bcc .preppart4

			if loops=1
			lda voice{1}active
			bmi .loop3
			endif
			
			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice3

			if loops=1
.loop3			lda samplefetch{1}c+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}c+1
			lda samplefetch{1}c+2
			sbc looplengthhi,y
			sta samplefetch{1}c+2
			clc
			endif
;------------------------------------------------------------------------------
.preppart4		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}c+1
			adc notesaddlo,x
			sta samplefetch{1}d+1
			lda samplefetch{1}c+2
			adc #$00
			sta samplefetch{1}d+2

			else	;{3}=0

			lda samplefetch{1}c+1
			adc #periodsteplength
			sta samplefetch{1}d+1
			lda samplefetch{1}c+2
			adc #$00
			sta samplefetch{1}d+2
			endif	;{3}=0

			lda samplefetch{1}d+1
			cmp sampleendlo,y
			lda samplefetch{1}d+2
			sbc sampleendhi,y

			if replayrate>0
			bcc .preppart5
			else
			bcc .nextvoice
			endif

			if loops=1
			lda voice{1}active
			bmi .loop4
			endif
			
			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice4

			if loops=1
.loop4			lda samplefetch{1}d+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}d+1
			lda samplefetch{1}d+2
			sbc looplengthhi,y
			sta samplefetch{1}d+2
			endif
			
			if replayrate>0
			clc
;------------------------------------------------------------------------------
.preppart5		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}d+1
			adc notesaddlo,x
			sta samplefetch{1}e+1
			lda samplefetch{1}d+2
			adc #$00
			sta samplefetch{1}e+2

			else	;{3}=0

			lda samplefetch{1}d+1
			adc #periodsteplength
			sta samplefetch{1}e+1
			lda samplefetch{1}d+2
			adc #$00
			sta samplefetch{1}e+2
			endif	;{3}=0

			lda samplefetch{1}e+1
			cmp sampleendlo,y
			lda samplefetch{1}e+2
			sbc sampleendhi,y
			bcc .preppart6

			if loops=1
			lda voice{1}active
			bmi .loop5
			endif
			
			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice5

			if loops=1
.loop5			lda samplefetch{1}e+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}e+1
			lda samplefetch{1}e+2
			sbc looplengthhi,y
			sta samplefetch{1}e+2
			clc
			endif
;------------------------------------------------------------------------------
.preppart6		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}e+1
			adc notesaddlo,x
			sta samplefetch{1}f+1
			lda samplefetch{1}e+2
			adc #$00
			sta samplefetch{1}f+2

			else	;{3}=0

			lda samplefetch{1}e+1
			adc #periodsteplength
			sta samplefetch{1}f+1
			lda samplefetch{1}e+2
			adc #$00
			sta samplefetch{1}f+2
			endif	;{3}=0

			lda samplefetch{1}f+1
			cmp sampleendlo,y
			lda samplefetch{1}f+2
			sbc sampleendhi,y

			if replayrate>1
			bcc .preppart7
			else
			bcc .nextvoice
			endif

			if loops=1
			lda voice{1}active
			bmi .loop6
			endif
			
			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice6

			if loops=1
.loop6			lda samplefetch{1}f+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}f+1
			lda samplefetch{1}f+2
			sbc looplengthhi,y
			sta samplefetch{1}f+2
			endif
			endif	;replayrate>0

			if replayrate>1
			clc
;------------------------------------------------------------------------------
.preppart7		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}f+1
			adc notesaddlo,x
			sta samplefetch{1}g+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}g+2

			else	;{3}=0

			lda samplefetch{1}f+1
			adc #periodsteplength
			sta samplefetch{1}g+1
			lda samplefetch{1}f+2
			adc #$00
			sta samplefetch{1}g+2
			endif	;{3}=0

			lda samplefetch{1}g+1
			cmp sampleendlo,y
			lda samplefetch{1}g+2
			sbc sampleendhi,y
			bcc .preppart8

			if loops=1
			lda voice{1}active
			bmi .loop7
			endif
			
			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice7

			if loops=1
.loop7			lda samplefetch{1}g+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}g+1
			lda samplefetch{1}g+2
			sbc looplengthhi,y
			sta samplefetch{1}g+2
			clc
			endif
;------------------------------------------------------------------------------
.preppart8		if {3}=1
			lda sample{1}frac
			adc notesaddfrac,x
			sta sample{1}frac

			lda samplefetch{1}g+1
			adc notesaddlo,x
			sta samplefetch{1}h+1
			lda samplefetch{1}g+2
			adc #$00
			sta samplefetch{1}h+2

			else	;{3}=0

			lda samplefetch{1}g+1
			adc #periodsteplength
			sta samplefetch{1}h+1
			lda samplefetch{1}g+2
			adc #$00
			sta samplefetch{1}h+2
			endif	;{3}=0

			lda samplefetch{1}h+1
			cmp sampleendlo,y
			lda samplefetch{1}h+2
			sbc sampleendhi,y
			bcc .nextvoice

			if loops=1
			lda voice{1}active
			bmi .loop8
			endif
			
			ldx #$00
			lda #>silentbuffer
			jmp .stopvoice8

			if loops=1
.loop8			lda samplefetch{1}h+1
			sec
			sbc looplengthlo,y
			sta samplefetch{1}h+1
			lda samplefetch{1}h+2
			sbc looplengthhi,y
			sta samplefetch{1}h+2
			endif
			endif	;replayrate>1

.nextvoice		if playlzstream=1
lzsysave{1}		if digivoices={1}
			lda #$00		;last channel usa akku to save 2 cycles
			else
			ldy #$00
			endif			;digivoices={1}
			endif			;playlzstream=1
			endm
;------------------------------------------------------------------------------
replayer		subroutine
;------------------------------------------------------------------------------
;{1}=voice number
;{2]=0 - volume off 1=volume on
;{3}=0 - period always 453 1 - periods on
;{4}=0 - sampleoffset off  1 - sampleoffset on
			mixvoice 1,thc_chn1vol,thc_chn1per,thc_chn1off
			rts

;------------------------------------------------------------------------------
;modfile - protracker module
;------------------------------------------------------------------------------
			echo "Samplestart: ",*
			include "thc_samples.asm"
			echo "Sampleend before $8200: ",*

			org $8200
			include "thc_sampleheader.asm"

;------------------------------------------------------------------------------
;Nufli display code
;------------------------------------------------------------------------------
			org $82a8	;-$83f8 free


			align 256,0
;------------------------------------------------------------------------------
initnmi			subroutine
;------------------------------------------------------------------------------
			lda #$40
			sta $dd0c
			lda #$00
;			sta .cia_type+1	;not needed if run once
			sta $dd05
			sta $dc0e	;stop all timers
			sta $dc0f
			sta $dd0e
			sta $dd0f
			ldy #$7f	;forbid all timer IRQs
			sty $dc0d
			lda $dc0d
			sty $dd0d
			lda $dd0d
			lda #$04	;prepare detection (timer=4 cycles)
			sta $dd04
;			jsr vblank

			lda #<.cia_detect
			sta $fffa
			lda #>.cia_detect
			sta $fffb
			lda #$81
			ldx #%00011001
			stx $dd0e
			sta $dd0d
			bit $dd0d
			dec .cia_type+1
.cia_detect		pla
			pla
			pla
			sty $dd0d	;deactivate NMI
			lda $dd0d

			ldx #$04
.waitline		cpx $d012
			bne .waitline
			jsr .waitcycles
			bit $ea
			nop
			cpx $d012
			beq .skip1
			nop
			nop
.skip1			jsr .waitcycles
			bit $ea
			nop
			cpx $d012
			beq .skip2
			bit $ea
.skip2			jsr .waitcycles
			nop
			nop
			nop
			cpx $d012
			bne .onecycle

.onecycle		lda .cia_type+1	;line 07 cycle3
			bpl .skip3

.skip3			lda #$07		;63-1
			sta $dc06
			lda #nmifreq
			sta $dd04
			lda #$00
			sta $dc07
			sta $dd05

			lda #<nmiplay
			sta $fffa
			lda #>nmiplay
			sta $fffb

			lda #$11
			jsr .wait12
			nop
;			jsr .wait12
;			jsr .wait16

sucks			sta $dd0e	;waveform stable @ line 8 cycle 23 (can be repositioned)

.cia_type		ldx #$00
			bmi .skip4
.skip4			delay 13

sucks2			sta $dc0f	;write must be stable @ line 8 cylce 34
			rts

.waitcycles		ldy #$06
.loop1		     	dey
			bne .loop1
			inx
.wait16			nop
.wait14			nop
.wait12			rts

			org $8400
;------------------------------------------------------------------------------
;java-replayer-init
;------------------------------------------------------------------------------
;{1}=voice number
;{2]=voice number - 1
			mac initvoice
			if playinterleave=0
			lda sampleslo+{2}
			sta sample{1}datapointer+1
			lda sampleshi+{2}
			sta sample{1}datapointer+2
			stx sample{1}delay+1
			else
			stx sample{1}delay+1
			endif

			if thc_chn{1}per=1
			if playinterleave=0
			lda periodslo+{2}	;voice2
			sta period{1}datapointer+1
			lda periodshi+{2}
			sta period{1}datapointer+2
			stx period{1}delay+1
			else
			stx period{1}delay+1
			endif
			endif

			if volumesupport=1 & thc_chn{1}vol=1
			if playinterleave=0
			lda volumeslo+{2}
			sta volume{1}datapointer+1
			lda volumeshi+{2}
			sta volume{1}datapointer+2
			stx volume{1}delay+1
			else
			stx volume{1}delay+1
			endif
			endif

			if sampleoffsetsupport=1 & thc_chn{1}off=1
			if playinterleave=0
			lda offsetslo+{2}
			sta offset{1}datapointer+1
			lda offsetshi+{2}
			sta offset{1}datapointer+2
			stx offset{1}delay+1
			else
			stx offset{1}delay+1
			endif
			endif
			endm
;------------------------------------------------------------------------------
sidinit			subroutine
;------------------------------------------------------------------------------

			jsr clearsid		;waveform or digimax

			lda #$49
			sta $d404
			sta $d40b
			sta $d412
			lda #$ff
			sta $d406
			sta $d40d
			sta $d414

			sta $d415
			sta $d416

			lda #$03   		;Enable filter on voice #1 and #2
			sta $d417
			rts
			
;------------------------------------------------------------------------------
javarestart		subroutine
;------------------------------------------------------------------------------
			ldx #$00

.loop2			lda nmi_start,x
			sta.wx nmiplay,x
			inx
			cpx #nmi_end-nmi_start
			bne .loop2

			ldx #$00
			lda d418tab+$80		;clear all mixingbuffers

.mixbuffer		sta mixingbuffer,x
			sta silentbuffer,x
			inx
			cpx #mixingbufferlength
			bne .mixbuffer

			ldx #$00
			initvoice 1,0

			rts

			echo "Songstart: ",*
			include "thc_init.asm"
			include "thc_header00.asm"
			include "thc_song00.asm"
			echo "Songend before $8500: ",*

			org $8500
plotsprites		ds.b 7*64

;------------------------------------------------------------------------------
;initnufli
;------------------------------------------------------------------------------
			org $8700
displaytable1		dc.b $00,$00,$00,$00,$00,$00,$00,$01
			dc.b $00,$00,$00,$00,$00,$00,$01,$00
			dc.b $00,$00,$00,$00,$01,$00,$00,$00
			dc.b $00,$01,$00,$00,$00,$01,$00,$00
			dc.b $01,$00,$01,$01,$02,$ff ;,$02,$02,$02,$02,$02

displaytable2		dc.b $00,$01,$00,$00,$01,$00,$00,$00
			dc.b $01,$00,$00,$00,$00,$01,$00,$00
			dc.b $00,$00,$00,$01,$00,$00,$00,$00
			dc.b $00,$00,$01,$00,$00,$00,$00,$00
			dc.b $00,$00,$01,$00,$00,$80

initnufli		subroutine
			ldx #$2e
.copy   		lda vicinit,x
			sta $d000,x  ;sprite 0 x pos
			dex
			bpl .copy
			lda #$3a
			sta d011temp

			ldx #$27
.copy3			lda screen1line16,x
			sta screen0line16,x
			lda bitmapfix1,x
			sta bitmapfix0,x
			dex
			bpl .copy3

			ldx #$07
.copy4  		lda spritepointer0a,x
			sta spritepointer0b,x
;			lda #$00
;			sta spritepointer2,x
			lda #$fe
			sta spritepointer1,x
			dex
			bpl .copy4
			rts
;------------------------------------------------------------------------------
initsamples		subroutine
;------------------------------------------------------------------------------
			ifconst release
			lda link_chip_types
			else
			lda #$01		;$00 old sid $01 new sid
			endif
			and #%00000001
			bne .newsid
			lda #>d418tab6581
			sta .copyloop+2
			
.newsid			ldx #$00		;switch to 6581 table
.copyloop		lda d418tab8580,x
			sta d418tab,x
			inx
			bne .copyloop

;convert sample data to direct $d418 values

			lxa #$00
			if >[samplememend-samplememstart]>0
			ldy #>[samplememend-samplememstart]
			sty temp
			
.load1			ldy samplememstart,x
			lda d418tab,y
.store1			sta samplememstart,x
			inx
			bne .load1
			inc .load1+2
			inc .store1+2
			dec temp
			bne .load1
			endif

			if <(samplememend-samplememstart)>0
			ldy #<(samplememend-samplememstart)
			sty temp
			
.load2			ldy samplememstart+[>[samplememend-samplememstart]*256],x
			lda d418tab,y
			sta samplememstart+[>[samplememend-samplememstart]*256],x
			inx
			dec temp
			bne .load2
			endif
;generate loopdata
; .goon			ldy #samples
; .loop			lda loopposhi,y
			; beq .nextsample
			; sta .getloop+2
			; lda loopposlo,y
			; sta .getloop+1

			; lda sampleendlo,y
			; sta .storeloop+1
			; lda sampleendhi,y
			; sta .storeloop+2

			; lda safetymargintable,y
			; sta .checker+1

			; ldx #$00
; .getloop		lda samplememstart,x
; .storeloop		sta samplememend,x
			; inx
; .checker		cpx #$00
			; bne .getloop

; .nextsample		dey
			; bpl .loop
			rts
clearsid		subroutine
			ldx #$18
			lda #$00
.loop1			sta $d400,x
			dex
			bpl .loop1
			rts
;------------------------------------------------------------------------------
vblank			subroutine
.1			bit $d011
			bpl .1
.2			bit $d011
			bmi .2
wait14			nop			
wait12			rts
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
			org nuflicode		;$8800
;------------------------------------------------------------------------------
			include "nufli_gen.asm"
;------------------------------------------------------------------------------
;resort tables
;------------------------------------------------------------------------------
			mac resorttab
			ldx #$00
.1			ldy d418tab,x
			lda {1},x
			sta resortbuffer,y
			inx
			bne .1
			endm

			mac copytab
			ldx #$00
.1			lda resortbuffer,x
			sta {1},x
			dex
			bne .1
			endm

resorttables		subroutine
			resorttab translate00
			copytab translate00
			resorttab translate01
			copytab translate01
			resorttab translate02
			copytab translate02
			resorttab translate40
			copytab translate40
			resorttab translate41
			copytab translate41
			resorttab translate42
			copytab translate42
			resorttab translate80
			copytab translate80
			resorttab translate81
			copytab translate81
			resorttab translate82
			copytab translate82
			resorttab translatec0
			copytab translatec0
			resorttab translatec1
			copytab translatec1
			resorttab translatec2
			copytab translatec2
			rts
			

;------------------------------------------------------------------------------
			org $9800
sidfile2		incbin "../../music/Party-Leben-Loader-9800-fe-ff.prg",2

			org $a000
			incbin "gfx/harle+raster.nuf",2,$1000

;------------------------------------------------------------------------------
			org $b000
d418tab8580		include "Volumetables/volume_table_common_8580_096_of_256.s"
d418tab6581		include "Volumetables/volume_table_common_6581_096_of_256.s"
;------------------------------------------------------------------------------
			org $b200	;sprites
			incbin "gfx/harle+raster.nuf",$1202,256
;------------------------------------------------------------------------------
			org $b300	;place for 3 plot sprites

;------------------------------------------------------------------------------
			org $b400
			incbin "gfx/harle+raster.nuf",$1402
			
;------------------------------------------------------------------------------
			org $fa00
			
;------------------------------------------------------------------------------
main			subroutine
;------------------------------------------------------------------------------
			sei
			cld
			ldx #$ff
			txs
			inx
			jsr vblank
			
			stx $d015
			stx $d011
			lda #$0f
			sta $d021
			sta $d020
			sta vicinit+$20
			sta vicinit+$21

			ldy #$7f
			sty $dd0d
			lda $dd0d
			sty $dc0d
			lda $dc0d
			
			ifconst release
			;jsr link_load_next_comp
			endif
			
			ldx #$00
			stx spritepointer2
			stx spritepointer2+1
			stx spritepointer2+4
			stx spritepointer2+5

			lda #$0f
.fill			sta $d800,x
			sta $d900,x
			sta $da00,x
			sta $db00,x
			inx
			bne .fill

			inx
			stx $dd00

			lda #$08
			sta vicinit+$11
			lda #$0f

			ldx #[plotsprites-$8000]/64
			stx plotpointer
			inx
			stx plotpointer+1
			inx
			stx plotpointer+2
			inx
			stx plotpointer+3
			inx
			stx plotpointer+4
			inx
			stx plotpointer+5
			inx
			stx plotpointer+6

			ldx #clearend-clearstart-1
.loop1			sta clearstart,x
			dex
			bpl .loop1

			jsr initsamples
			jsr resorttables
			jsr vblank
			jsr initnufli
;			jsr initsamplefill
			jsr vblank
			jsr initnmi
			jsr javarestart

			ifconst release
			ldx #$00
.stackloop		lda stackcodestart,x
			sta stackcode,x
			inx
			cpx #stackcodeend-stackcodestart
			bne .stackloop
			endif
			
			jsr vblank

			jsr sidinit

			lda #$28
			sta $d012
			lda #<irq1
			sta $fffe
			lda #>irq1
			sta $ffff

			lda #$01
			sta $d019
			sta $d01a

			ldy #$01
.again			ldx #$10
			lda #$f8
.3			cmp $d012
			bne .3
			stx $d011

			ldx #$18
			lda #$fc
.4			cmp $d012
			bne .4
			stx $d011
			dey
			bpl .again

			cli
			
startload		lda #$00
			beq startload

			jsr patchd418
			
			jsr vblank

			lda #$00
			ifnconst release
			jsr sidfile2
			else
			jsr link_music_init_side1b
			endif

			ifnconst release
			ldx #<[sidfile2+3]
			ldy #>[sidfile2+3]
			stx goon+1
			stx sidplay+1
			sty goon+2
			sty sidplay+2
			else
			ldx #<[link_music_play_side1b]
			ldy #>[link_music_play_side1b]
			stx goon+1
			stx link_music_addr+0
			sty goon+2
			sty link_music_addr+1
			endif

;-----------------------
			ifnconst release
			lda #$ef
.wait4			cmp $dc01
			bne .wait4
			else
			jsr link_load_next_comp		;$2400-$8280
			endif
			
			lda #<displaytable2
			sta fetchdisp+1
			lda #>displaytable2
			sta fetchdisp+2
		
			lda #goon-bneswitch-2
			sta bneswitch+1
	
			lda #$00
			sta startload+1

			ifnconst release
.endless		; inc $d020
			jmp .endless
			else
			jmp stackcode
			endif
			
;------------------------------------------------------------------------------
			ifconst release
stackcodestart		
			rorg stackcode
			subroutine
startload2		lda #$01
			bne startload2

			jsr link_load_next_comp	;$0400-$2400
			jsr link_load_next_comp	;8280-9800
			jsr link_load_next_comp	;a000-d000
			jsr link_load_next_raw	;d000-fff0
			
			dec $01
			jsr link_decomp
			inc $01

			ldx #$0c
.1			bit $d011
			bpl .1
.2			bit $d011
			bmi .2
			lda .fadeblack,x
			sta $d020
			sta $d021
			dex
			bpl .1
			sei
.newsid			ldx #$18
.loop1			sta $d400,x
			dex
			bpl .loop1

			jsr link_load_next_comp	;9800-a000
			
			jmp link_exit
			
.fadeblack		dc.b $00,$06,$09,$02,$0b,$04,$08,$0c,$0e,$05,$0a,$03
					
			
			rend
stackcodeend
			endif
;------------------------------------------------------------------------------
			align 256,0
irq1			subroutine
			stx xreg
			ldx #$7f
			stx $dd0d
;			lda $dd0d

displayflag		ldx #$00
			bne .display
			stx $d015
			ldx #$08
			stx $d011

			ldx #$f8
.waitbot		cpx $d012
			bne .waitbot
			ldx #$10
			stx $d011
			inc $d019
			sta areg
			sty yreg
			delay 62
			jmp .nmiswitch	;.nodisplay

.display		ldx #$ff
			stx $d015

			inc $d019
			inc $d012

			ldx #<.inter
			stx $fffe
			tsx
m1			cli
.next			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			jmp .next

.inter			txs
			sta areg
			sty yreg

			ldy #$00
			sty $fffa
			sty $fffe
			sty $ffff
			sty $dd00	;cia2: data port register a

mix51			ldx #$00	;write at line 41 cycle 36
			stx $d418

			lda #$18
			sta $d000
			lda #$30
			sta $d002
			
			nop

			ldx $d012
			cpx $d012
			beq .2
.2
stable1			lda #$c0
			sta $d008
			lda #$f0
			sta $d00a
			lda #$20
			sta $d00c

			lda #$40
			sta $d010

			lda #$28
			sta $d012
			inc $d019

			delay 27
			
			dey		;ldy #$ff
			sty $d018	;vic memory control register line $2b (43) cycle 005
			ldx #$2b
			stx $d001	;sprite 0 y pos
			stx $d003	;sprite 1 y pos
mix52			lda #$00	;write at line 43 cycle 25
			sta $d418
			stx $d005	;sprite 2 y pos
			stx $d007	;sprite 3 y pos
			stx $d009	;sprite 4 y pos
			stx $d00b	;sprite 5 y pos
			stx $d00d	;sprite 6 y pos
			stx $d00f	;sprite 7 y pos
			ldx sprite1colors
			stx $d028	;sprite 1 color
			ldx sprite2colors
			stx $d029	;sprite 2 color
			ldx sprite3colors
			stx $d02a	;sprite 3 color
			ldx sprite4colors
			stx $d02b	;sprite 4 color
			ldx sprite5colors
			stx $d02c	;sprite 5 color
			ldx sprite6colors
			stx $d02d	;sprite 6 color
			ldx #$aa
mix53			lda #$00	;write at line 45 cycle 17
			sta $d418
			stx $d001	;sprite 0 y pos
			stx $d003	;sprite 1 y pos
			stx $d005	;sprite 2 y pos
			stx $d007	;sprite 3 y pos
			stx $d009	;sprite 4 y pos
			stx $d00b	;sprite 5 y pos
			stx $d00d	;sprite 6 y pos
			stx $d00f	;sprite 7 y pos
			lda #$00
			sty $d017	;sprites expand 2x vertical (y)
			sta $d018,y	;vic memory control register
			sty $d017	;sprites expand 2x vertical (y)

			lda #%01111110
			sta $d01d

			lda #$60
			sta $d004
			lda #$90
			sta $d006
			
			delay 5

			lda spritemc1
			sta $d026	;sprite multi-color register 1
			lda spritemc2
			sta $d025	;sprite multi-color register 0
mix54			lda #$00	;write at line 47 cycle 18
			sta $d418
			lda sprite0color
			sta $d027	;sprite 0 color
			lda sprite7color
			sta $d02e	;sprite 7 color
			
			lda #$38
			ldy #$78
			sty $d018	;vic memory control register
			ldx #$3e
			jsr nuflicode

			lda #$0f
			bit $00
			sta $d021
			sta $d020
			lda #$00
			sta $d015
			sta $d017	;sprites expand 2x vertical (y)
			
			lda #%01111111
			sta $d01d
			
mix155			lda #$00	;write at line 249 cycle 22
			sta $d418

			lda #$00
			sta $d027
			sta $d028
			sta $d029
			sta $d02a
			sta $d02b
			sta $d02c
			sta $d02d

			lda #28
			sta $d000
			lda #28+48
			sta $d002
			lda #28+48*2
			sta $d004
			lda #28+48*3
			sta $d006
			lda #28+48*4
			sta $d008
			lda #<[28+48*5]
			sta $d00a
			lda #<[28+48*6]
			sta $d00c
			lda #%01100000
			sta $d010

			lda #<nmiplay
			sta $fffa
			lda #>nmiplay
			sta $fffb
			lda #<irq1
			sta $fffe
			lda #>irq1
			sta $ffff

			lda #%11110000	;$19
			sta $d018

			if timingcolors=1
			inc $d020
			endif
;			jsr mixer		;first sample 251 cycle 41
mixswitch		dc.b $0c,<mixer,>mixer	;top
			
			if timingcolors=1
			inc $d020
			endif
			
.nmiswitch		ldx #$7f	;nmi triggers in line 251 cycle 44
			stx $dd0d

.nodisplay		lda startload+1
			bne goon
			
fetchdisp		lda displaytable1
			bmi .done
			sta displayflag+1
			inc fetchdisp+1

			cmp #$02
bneswitch		bne .exitirq
			
			lda #$81
			sta .nmiswitch+1
			lda #$20
			sta mixswitch
			sta goon
			
goon			;jsr replayer
			dc.b $0c, <replayer,>replayer
			
.exitirq		if timingcolors=1
			lda #$0f
			sta $d020
			endif
			lda areg
			ldx xreg
			ldy yreg
			rti
			
.done			cmp #$80
			beq .endpart
			
			lda replayer
			cmp #$60
			bne goon

			lda #$7f
			sta $dd0d
			sta .nmiswitch+1
			lda $dd0d

			inc startload+1
			bne .exitirq
			
.endpart		ifnconst release
			lda #<sidirq
			sta $fffe
			lda #>sidirq
			sta $ffff
			ldx #$ff
			stx $d012
			inx
			stx $d011
			jmp .exitirq
			else
			to_irq
			lda #<link_player
			sta $fffe
			lda #>link_player
			sta $ffff
			ldx #$ff
			stx $d012
			inx
			stx $d011
			stx startload2+1
			jmp .exitirq
			endif
			
;------------------------------------------------------------------------------
			ifnconst release
sidirq			subroutine
			sta areg
			stx xreg
			sty yreg

;			inc $d020
sidplay			jsr sidfile2+3
;			dec $d020
			
			inc $d019
			lda areg
			ldx xreg
			ldy yreg
			rti
			endif
			
;------------------------------------------------------------------------------
patchd418		subroutine
			; lda #<nuflicode
			; sta srclo
			; lda #>nuflicode
			; sta srchi

			; ldy #$00
; .loop			lda (srclo),y
			; cmp #$60
			; beq .exit
			; cmp #$18
			; bne .over2
			; iny
			; lda (srclo),y
			; cmp #$d4
			; bne .over1
			; lda #$d8
			; sta (srclo),y
; .over1			dey			
; .over2			inc srclo
			; bne .loop
			; inc srchi
			; bne .loop
			
; .exit			
			lda #$d8
			sta mix51+4
			sta mix52+4
			sta mix53+4
			sta mix54+4
			sta mix55+4
			sta mix56+4
			sta mix57+4
			sta mix58+4
			sta mix59+4

			sta mix60+4
			sta mix61+4
			sta mix62+4
			sta mix63+4
			sta mix64+4
			sta mix65+4
			sta mix66+4
			sta mix67+4
			sta mix68+4
			sta mix69+4

			sta mix70+4
			sta mix71+4
			sta mix72+4
			sta mix73+4
			sta mix74+4
			sta mix75+4
			sta mix76+4
			sta mix77+4
			sta mix78+4
			sta mix79+4

			sta mix80+4
			sta mix81+4
			sta mix82+4
			sta mix83+4
			sta mix84+4
			sta mix85+4
			sta mix86+4
			sta mix87+4
			sta mix88+4
			sta mix89+4

			sta mix90+4
			sta mix91+4
			sta mix92+4
			sta mix93+4
			sta mix94+4
			sta mix95+4
			sta mix96+4
			sta mix97+4
			sta mix98+4
			sta mix99+4

			sta mix100+4
			sta mix101+4
			sta mix102+4
			sta mix103+4
			sta mix104+4
			sta mix105+4
			sta mix106+4
			sta mix107+4
			sta mix108+4
			sta mix109+4

			sta mix110+4
			sta mix111+4
			sta mix112+4
			sta mix113+4
			sta mix114+4
			sta mix115+4
			sta mix116+4
			sta mix117+4
			sta mix118+4
			sta mix119+4

			sta mix120+4
			sta mix121+4
			sta mix122+4
			sta mix123+4
			sta mix124+4
			sta mix125+4
			sta mix126+4
			sta mix127+4
			sta mix128+4
			sta mix129+4

			sta mix130+4
			sta mix131+4
			sta mix132+4
			sta mix133+4
			sta mix134+4
			sta mix135+4
			sta mix136+4
			sta mix137+4
			sta mix138+4
			sta mix139+4

			sta mix140+4
			sta mix141+4
			sta mix142+4
			sta mix143+4
			sta mix144+4
			sta mix145+4
			sta mix146+4
			sta mix147+4
			sta mix148+4
			sta mix149+4

			sta mix150+4
			sta mix151+4
			sta mix152+4
			sta mix153+4
			sta mix154+4
			sta mix155+4
			rts
;------------------------------------------------------------------------------
	
