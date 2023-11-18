			!cpu 6510
;---------------------------------------
;SDI player v2.1 n50 (c)16/05/2014 SHAPE
;		Geir Tjelta & Glenn Rune Gallefoss
;---------------------------------------
sid		= $d400
mzero		= $fe		;player zeropage
;---------------------------------------
rem_4ch		= 1		;1 = ignore 4th channel
rem_det		= 0		;1 = ignore detune (z8/z9)
rem_gout	= 0		;1 = ignore gate timeout
rem_1wf		= 0		;1 = ignore 1st WFPRG byte
rem_wfd		= 1		;1 = ignore fe wf hold cmd
rem_adsr	= 1		;1 = ignore fd wf adsr cmd
rem_mp		= 1		;1 = ignore fb wf puls cmd
rem_wfr		= 1		;1 = ignore fa wfp rep cmd
rem_wf0		= 1		;1 = ignore f0-f7 wf d415
rem_puw		= 1		;1 = ignore eb-ee wf pulse
rem_pu		= 0		;1 = ignore pulse routine
rem_we2		= 1		;1 = ignore e2-e7 wf noise
rem_arp		= 0		;1 = ignore arp routine
rem_fi		= 0		;1 = ignore filter routine
rem_fspd	= 1		;1 = ignore filter speed
rem_glid	= 0		;1 = ignore glide routine
rem_vib		= 0		;1 = ignore vibrato rout
rem_cc		= 1		;1 = ignore crazy com vib
rem_fad		= 0		;1 = ignore fadeout routin
rem_gat		= 1		;1 = ignore seq GAT/FLGcmd
rem_f20		= 1		;1 = ignore seq 20 filtcmd
rem_wfo		= 1		;1 = ignore seq wf ora cmd
rem_voff	= 1		;1 = ignore voice on/off
rem_trkl	= 1		;1 = max $ff track size
rem_tp		= 0		;1 = ignore tempo programs
;NB!!^^ Enter song's tempo in offset "s"
;Save cycles if only single tempos used.
;---------------------------------------
frqsum		= rem_det*rem_cc
gatsum		= rem_gout*rem_adsr
addsum		= rem_glid*rem_vib

;------------------START OF DRIVER/DATA-

		;*= $0800
		
		jmp init		;Call with X
		jmp play
		
		!if rem_fad = 0 {
r_fad3		jmp fadeout ;negative # =down
		} ;*= *-((*-r_fad3)*rem_fad)

		!text "-PLAYER V2.1 "
		!text "BY GT+GRG-"

chanon		= *
chanoff		= *+1
trklo		= *+2
trkhi		= *+3
tdelay		= *+4
tracky		= *+5
trackhi		= *+6
		!byte $01,$fe,0,0,0,0,0
		!byte $02,$fd,0,0,0,0,0
		!byte $04,$fb,0,0,0,0,0
chanx		!byte $80,$7f,0,0,0,0,0

transp		= *+1
dur		= *+2
duration	= *+3
seqp		= *+4
sound2		= *+5
note2		= *+6
		!byte $00,0,0,0,0,0,0
		!byte $07,0,0,0,0,0,0
		!byte $0e,0,0,0,0,0,0
fadeco		!byte 0,0,0,0,0,0,0
release		= *
seqsust		= *+1
seqbyte		= *+2
filtre		= *+3
glidadd2	= *+4
wf_ora		= *+5
wf_ora2		= *+6
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0
arpnum2		= *
arple		= *+1
srco		= *+2
sound		= *+3
note		= *+4
gate		= *+5
gatedec		= *+6
		!byte $80,0,0,0,0,0,0
		!byte $80,0,0,0,0,0,0
		!byte $80,0,0,0,0,0,0
		!byte $00
arpnum		= *
attack		= *+1
sustain		= *+2
glidadd		= *+3
glidto		= *+4
addlo		= *+5
addhi		= *+6
		!byte $80,0,0,0,0,0,0
		!byte $80,0,0,0,0,0,0
		!byte $80,0,0,0,0,0,0
arpde		= *
addval_l	= *+1
addval_h	= *+2
vible		= *+3
vibwid		= *+4
vibdir		= *+5
vibdec		= *+6
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0

pulsco		= *
pulseor		= *+1
pulsdel		= *+2
pulsle		= *+3
pulsle2		= *+4
pulsdec		= *+5
pulsdec2	= *+6
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0
pulslo		= *
pulslo2		= *+1
pulshi		= *+2
pulshi2		= *+3
pulshld		= *+4 ;uses 2 but needs only 1
		;6 free
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0

wf		= *
wfp		= *+1
wf_del		= *+2
wf_repet	= *+3
detunlo		= *+4
detunhi		= *+5
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0

		!if rem_fspd = 0 {
filtspd		!byte 0
		}	;*= *-((*-filtspd)*rem_fspd)

		!if rem_voff = 0 {
clear_wav	sta sid+$04
		sta sid+$0b
		sta sid+$12
		jmp fade
		}	;*= *-((*-clear_wav)*rem_voff)

channels	= 3-rem_4ch

play		ldx #channels*7
		!if rem_voff = 0 {
voff		lda #0
		beq clear_wav
		}	;*= *-((*-voff)*rem_voff)
;-----------------------CONDUCTOR/TEMPO-
	!if rem_4ch = 0 {
		!if rem_voff = 0 {
r_4ch1
		bpl noc2
		}	;*= *-((*-r_4ch1)*rem_voff)

		ldy duration+21
		bpl no_conduct
		lda tempo+1
		beq cond_dur
		cmp cur_tem+1
		beq cond_seq
noc2		jmp no_conduct

cond_dur	lda dur+21
		sta duration+21

		!if rem_fi = 0 {
r_fi8		lda release+21
		asl
		asl
		asl
		asl
		sta setfi+1

		lda glidadd2+21
		bmi no_conduct
		sty glidadd2+21
		beq restfi
		sty filtsnd+1
		lsr
		lsr
		sta filtle+1
		lda #0
		sta filtdec+1
		!if rem_fspd = 0 {
f_spd3		sta filtspd
		}	;*= *-((*-f_spd3)*rem_fspd)
		beq no_conduct
restfi		sta filtre
		sta filtre+7
		sta filtre+14
		}	;*= *-((*-r_fi8)*rem_fi)
		bpl no_conduct

cond_seq	stx x+1
		lda #$7f
		sta arpnum2+21
		jmp seq_cond
cond_ret
		!if rem_voff = 0 {
r_voff1		lda voff+1
		bmi cond_on
		lda #0
		sta trk_tran+1
		beq no_conduct
		}	;*= *-((*-r_voff1)*rem_voff)
cond_on		lda arpnum2+21
		bmi set_tem
		cmp #$7f
		beq no_conduct
		cmp #$40
		bcs setband
		lsr
set_tem		sta tem_prg+1
		lda #0
		sta tem_y+1
		!if rem_fi = 0 {
r_fi9		beq no_conduct
		}	;*= *-((*-r_fi9)*rem_fi)
setband
		!if rem_fi = 0 {
r_fi10		asl
		asl
		asl
		sta band+1
		}	;*= *-((*-r_fi10)*rem_fi)
no_conduct
		ldx #(channels-1)*7
	}	;*= *-((*-r_4ch1)*rem_4ch)

;-----------------------PLAYER LOOP POS-
part1		stx x+1
		!if gatsum = 0 {
r_gout1		lda gatedec,x
		beq bn71
		dec gatedec,x
		bne bn71
		lda #$fe
		sta gate,x
bn71
		}	;*= *-((*-r_gout1)*gatsum)
		lda duration,x
		bpl bn33
tempo		lda #0
		beq setval

cur_tem		cmp #0
		beq *+5
bn33		jmp part2
		jmp sequ2

;-------------------SET TIE/GLIDE/NOTE--
setval		lda dur,x
		sta duration,x

		!if rem_voff = 0 {
r_voff2		lda voff+1
		and chanon,x
		beq bn33
		}	;*= *-((*-r_voff2)*rem_voff)

		ldy note2,x
		!if rem_gat = 0 {
r_gat2		bmi r_gat1
		}	;*= *-((*-r_gat2)*rem_gat)
		cpy #$5f
		beq forcevib

		!if rem_glid = 0 {
r_gli1		lda glidadd2,x
		sta glidadd,x
		bne r_gli2
		}	;*= *-((*-r_gli1)*rem_glid)

	!if addsum = 0 {
		!if rem_glid = 1 {
fcode4		lda #0
		}	;*= *-((*-fcode4)*(1-rem_glid))

		sta addlo,x
		sta addhi,x
	}	;*= *-((*-fcode4)*addsum)

		tya
		sta note,x

		!if rem_vib = 0 {
bn27		lda #0
		sta vibdec,x
		}	;*= *-((*-bn27)*rem_vib)

		!if rem_arp = 0 {
r_arp1		lda arpnum2,x
		sta arpnum,x
		bmi tie_note
		sta arpde,x
		tay
		lda ad,y
		sta arple,x
		}	;*= *-((*-r_arp1)*rem_arp)

;--------------------SET INSTRUMENTS----
tie_note	lda srco,x
		bne set_snd
		jmp wfrout

		!if rem_gat = 0 {
r_gat1		tya
		sta gate,x
		jmp part2
		}	;*= *-((*-r_gat1)*rem_gat)

forcevib	lda glidadd2,x
		beq bn33
		!if rem_vib = 0 {
r_vib1		lsr
		lsr
		sta vible,x
		lda #0
		sta vibdec,x
		}	;*= *-((*-r_vib1)*rem_vib)
		jmp glide

		!if rem_glid = 0 {
r_gli2		tya
		sta glidto,x
		bpl bn27
		}	;*= *-((*-r_gli2)*rem_glid)

set_snd		sta gate,x
		ldy sound2,x
		lda seqsust,x
		cmp #1
		lda z2,y
		bcc bn21
		and #$0f
		ora seqsust,x
bn21		sta mzero+1
		and #$f0
		sta sustain,x
		ora #$0f
		sta sid+6,x

		lda wf,x
		ora #1
		sta sid+4,x

		!if rem_det = 0 {
r_det1		lda z8,y
		sta detunhi,x
		lda z9,y
		sta detunlo,x
		}	;*= *-((*-r_det1)*rem_det)

		!if gatsum = 0 {
r_gout2		lda z3,y
		and #$1f
		asl
		sta gatedec,x
		}	;*= *-((*-r_gout2)*gatsum)

		!if rem_fi = 0 {
r_fi1		lda filtre,x
		bmi bn37
		lda z6,y
		sta filtre,x
		asl
		bne bn45
		bcs bn37
		lda filtch+1
		and chanoff,x
		bcc bn37-3

bn45		lsr
		sta filtle+1
		lda #0
		sta filtdec+1
		!if rem_fspd = 0 {
f_spd4		sta filtspd
		}	;*= *-((*-f_spd4)*rem_fspd)
		sty filtsnd+1
		lda filtch+1
		ora chanon,x
		sta filtch+1
		}	;*= *-((*-r_fi1)*rem_fi)

		!if rem_vib = 0 {
bn37		lda z4,y
		sta vible,x
		}	;*= *-((*-bn37)*rem_vib)

		lda z5,y
		beq no_puls
		!if rem_pu = 0 {
r_pu1		bpl pulw_val
		}	;*= *-((*-r_pu1)*rem_pu)

		and #$7f
		sta sid+2,x
		sta sid+3,x
		!if rem_mp = 0 {
r_op3		lda #0
		sta pulsle2,x
		}	;*= *-((*-r_op3)*rem_mp)
no_puls
	!if rem_pu = 0 {
r_pu2		lda pulsle,x
		ora #$80
		bne puls_off
pulw_val	asl
		asl
		tay
		bcc puls_on
		lda sound2,x
		cmp sound,x
		beq puls_end

puls_on		lda #0
		!if rem_mp = 0 {
r_mp4		sta pulsle2,x
		}	;*= *-((*-r_mp4)*rem_mp)
		sta pulsdec,x
		lda p-4,y
		sta sid+2,x
		sta sid+3,x
		tya
		lsr
		lsr
puls_off	sta pulsle,x
puls_end
	}	;*= *-((*-r_pu2)*rem_pu)

		ldy sound2,x
		lda z1,y
		ldy attack,x
		bne setatt
		ldy seqsust,x
		beq newsust
		lda #0
		beq newsust
setatt		lda #0
		sta attack,x
		sta seqsust,x
		!if gatsum = 0 {
r_gout3		sta gatedec,x
		}	;*= *-((*-r_gout3)*gatsum)
		tya
newsust		sta sid+5,x
		lda mzero+1
		sta sid+6,x

		lda #0
		sta srco,x
		!if rem_wfd = 0 {
r_wfd3		sta wf_del,x
		}	;*= *-((*-r_wfd3)*rem_wfd)
		!if rem_wfr= 0 {
r_wfr3		sta wf_repet,x
		}	;*= *-((*-r_wfr3)*rem_wfr)

		!if rem_pu = 0 {
r_pu3		lda sound2,x
		sta sound,x
		tay
		} else {	;*= *-((*-r_pu3)*rem_pu)
r_pu4		ldy sound2,x
		}	;*= *-((*-r_pu4)*(1-rem_pu))
		lda z0,y

		!if rem_1wf = 0 {
r_1wf1		tay
		iny
		tya
		} else {	;*= *-((*-r_1wf1)*rem_1wf)
r_1wf2		clc
		adc #1
		}	;*= *-((*-r_1wf2)*(1-rem_1wf))
		sta wfp,x

	!if rem_1wf = 0 {
r_1wf3		lda w-1,y
		!if rem_arp = 0 {
r_arp2		cmp #$90
		bcc *+4
		and #$7f
		}	;*= *-((*-r_arp2)*rem_arp)
		sta sid+4,x

		lda f-1,y
		bmi frq_lock
		clc
		adc note,x
frq_lock	and #$7f
		tay
		lda freqlo,y
		!if rem_det = 0 {
r_det2		clc
		adc detunlo,x
		}	;*= *-((*-r_det2)*rem_det)
		sta sid+0,x
		lda freqhi,y
		!if rem_det = 0 {
r_det3		adc detunhi,x
		}	;*= *-((*-r_det3)*rem_det)
		sta sid+1,x
	}	;*= *-((*-r_1wf3)*rem_1wf)
		jmp sid_next


;----------------SEQUENCER--------------
sequ2		lda #0
		sta glidadd2,x
seq_cond
		ldy seqbyte,x
	!if rem_voff = 0 {
r_voff3		bpl bn54
		lda voff+1
		and chanoff,x
		sta voff+1

		!if rem_4ch = 0 {
r_4ch5		cpx #21
		bne sequ2-3
		jmp cond_ret
		} else {	;*= *-((*-r_4ch5)*rem_4ch)
r_4ch6		jmp sid_next
		}	;*= *-((*-r_4ch6)*(1-rem_4ch))
	}	;*= *-((*-r_voff3)*rem_voff)

bn54		lda sl,y
		sta mzero
		lda sh,y
		sta mzero+1

		!if rem_wfo = 0 {
r_wfo1		lda #$ff
		sta wf_ora2,x
		}	;*= *-((*-r_wfo1)*rem_wfo)

		!if rem_f20 = 0 {
r201		lda #bn32-fxjmp-2
		sta fxjmp+1
		}	;*= *-((*-r201)*rem_f20)

		ldy seqp,x
		lda (mzero),y
		cmp #$5f
		beq bn6
		cmp #$f0
		bcc bn4
		and #$0f
		sta release,x
		bpl bn6

bn4		cmp #$c0
		bcc bn13
		and #$3f
		asl
		sta arpnum2,x
		tax
		lda ad+1,x
		and #$3f
x		ldx #0
		bpl bn15

bn13		cmp #$a0
		bcc bn14
		and #$1f
		asl
		asl
		sta glidadd2,x
		!if rem_f20 = 1 {
r202		bpl bn6
		} else {	;*= *-((*-r202)*(1-rem_f20))

com20		bne bn6
		lda #comfx-fxjmp-2
		sta fxjmp+1
		bne bn6
		}	;*= *-((*-com20)*rem_f20)

bn14		cmp #$80
		bcc bn7
		sta arpnum2,x
		and #$3f
		!if rem_wfo = 0 {
r_wfo2		sta wf_ora2,x
		}	;*= *-((*-r_wfo2)*rem_wfo)

bn15		sta sound2,x
		!if rem_fi = 0 {
r_fi2		sta filtre,x
		}	;*= *-((*-r_fi2)*rem_fi)

		lda #0
		!if rem_wfo = 0 {
r_wfo3		sta wf_ora,x
		}	;*= *-((*-r_wfo3)*rem_wfo)

		sta seqsust,x
bn6		iny
		lda (mzero),y
		cmp #$df
		bcc bn7
		beq dur_20
		and #$3f
		bne bn12
dur_20		iny
		lda (mzero),y
		bne bn12

		!if rem_4ch = 0 {
r_4ch7		cmp #$5f
		beq note2ch4
		and #$7f
		sta note2ch4+1
note2ch4	lda #0
		clc
		adc transp+21
		sta trk_tran+1
		jmp track_conduct
		}	;*= *-((*-r_4ch7)*rem_4ch)

bn7		cmp #$80
		bcs bn56
		cmp #$60
		bcc bn56
		and #$1f
bn12		sta dur,x
		iny
		lda (mzero),y
		cmp #$f0
		bcc bn56
		and #$0f
		sta release,x
		lda #$5f
bn56
		!if rem_4ch = 0 {
r_4ch2		cpx #21
		beq r_4ch7
		}	;*= *-((*-r_4ch2)*rem_4ch)

		cmp #$5f
fxjmp		bne bn32
		sta ack+1
		sta note2,x
		lda release,x
		bmi track_conduct
		ora sustain,x
		sta sid+6,x
		lda #$fe
		sta gate,x
		sta release,x
		bne track_conduct

		!if rem_f20 = 0 {
comfx		lsr
		lda filtena+1
		bcs disafi
		ora chanon,x
		bne disaf2
disafi		and chanoff,x
disaf2		sta filtena+1
		lda #$5f
		sta ack+1
		bne note_5f
		}	;*= *-((*-comfx)*rem_f20)

		!if rem_gat = 0 {
r_gat4		adc #0
		eor #$ff
		sta note2,x
		lda #$5f
		sta ack+1
		bne track_conduct
		}	;*= *-((*-r_gat4)*rem_gat)

bn32		sta ack+1
		and #$7f
		!if rem_gat = 0 {
r_gat3		beq r_gat4
		}	;*= *-((*-r_gat3)*rem_gat)
		clc
		!if rem_4ch = 0 {
trk_tran	adc #0
		clc
		}	;*= *-((*-trk_tran)*rem_4ch)
		adc transp,x
note_5f		sta note2,x

track_conduct
		iny
		lda (mzero),y
		beq *+3
		tya
		sta seqp,x
		bne trk_end

track_init
		ldy tdelay,x
		beq bn61
		dec tdelay,x
		bpl trk_end

bn61		!if rem_trkl = 0 {
		lda tracky,x ;16-bit
		sta mzero
		lda trackhi,x
		sta mzero+1
		} else {	;*= *-((*-bn61)*rem_trkl)
r_trkl1		lda trklo,x		;8-bit
		sta mzero
		lda trkhi,x
		sta mzero+1
		ldy tracky,x
		}	;*= *-((*-r_trkl1)*(1-rem_trkl))

		lda (mzero),y
		bpl bn28
		cmp #$f7
		bcc t_del
		!if rem_voff = 0 {
r_stop		beq bn28
		}	;*= *-((*-r_stop)*rem_voff)

		!if rem_trkl = 0 {
r_trkl2		and #7
		sta bn36+1
		iny
		clc
		lda trklo,x
		adc (mzero),y
		sta mzero
		lda trkhi,x
bn36		adc #0
		sta mzero+1
		dey
		} else {	;*= *-((*-r_trkl2)*rem_trkl)
r_trkl3		iny
		lda (mzero),y
		tay
		}	;*= *-((*-r_trkl3)*(1-rem_trkl))
		lda (mzero),y
t_del		cmp #$c0
		bcc bn62
		and #$3f
		sta tdelay,x
		iny
		lda (mzero),y
		bpl bn28
bn62		sec
		sbc #$a0
		sta transp,x
		iny
		lda (mzero),y
bn28		sta seqbyte,x
		!if rem_trkl = 0 {
r_trkl4		tya
		sec
		adc mzero
		sta tracky,x
		lda #0
		adc mzero+1
		sta trackhi,x
		} else {	;*= *-((*-r_trkl4)*rem_trkl)
r_trkl5		iny
		tya
		sta tracky,x
		}	;*= *-((*-r_trkl5)*(1-rem_trkl))
trk_end		!if rem_4ch = 0 {
		cpx #21
		beq rrts
		}	;*= *-((*-trk_end)*rem_4ch)

ack		lda #0
		cmp #$5f
		beq bn66
		lda release,x
		bcs tie_att
		bmi no_sust
		asl
		asl
		asl
		asl
		sta seqsust,x
no_sust		lda #$ff
		sta release,x
		sta srco,x

		ldy sound2,x
		lda z3,y
		asl
		bmi no_rls
		and #$40
		beq no_hard
		adc #$e0
		sta sid+6,x
		lda #$0f
		sta sid+5,x
no_hard		lda #$fe
		sta gate,x
		and wf,x
		!if rem_wfo = 0 {
r_wfo5		ora wf_ora,x
		}	;*= *-((*-r_wfo5)*rem_wfo)
		sta sid+4,x
no_rls		jmp sid_next
		!if rem_4ch = 0 {
rrts		jmp cond_ret
		}	;*= *-((*-rrts)*rem_4ch)
tie_att		bmi r_wfo4
		asl
		asl
		asl
		asl
		sta attack,x
		lda #$f0
		bne no_sust-3

r_wfo4		!if rem_wfo = 0 {
		lda wf_ora2,x
		bmi bn66
		sta wf_ora,x
		}	;*= *-((*-r_wfo4)*rem_wfo)
bn66		jmp wfrout

part2
	!if rem_pu = 0 {
pulse
;----------------------MULTI PULSE ROUT-
		!if rem_mp = 0 {
r_mp1		lda pulsle2,x
		beq pulse3
		dec pulsco,x
		bne pulse2
		lda pulsdel,x
		sta pulsco,x
		lda pulseor,x
		eor #1
		sta pulseor,x
pulse2		lda pulseor,x
		beq pulse3
		inx
		}	;*= *-((*-r_mp1)*rem_mp)
;----------------------PULSE PROGRAM----
pulse3		lda pulsle,x
		bmi no_pulse
		bne go_pulse
no_pulse
		!if rem_mp = 0 {
r_mp7		ldx x+1
		}	;*= *-((*-r_mp7)*rem_mp)
		jmp glide
go_pulse	asl
		asl
		tay
		stx mzero+1
		lda pulsdec,x
		bne bn22
		sta pulshld,x
		lda #2
		sta pulsdec,x
		bcs bn22
		lda p+1-4,y
		bne ph1
		lda p+2-4,y
		sta pulshld,x
ph1
		lda p-4,y
		and #$f0
		sta pulslo,x
		lda p-4,y
		and #$0f
		sta pulshi,x
		jmp set_puls

bn22		lda pulshld,x
		beq ph2
		dec pulshld,x
		bne set_puls
		beq ph3

ph2
		lda p+1-4,y
		lsr
		lsr
		lsr
		lsr
		tax
		stx upper2+1
		lda p+1-4,y
		and #$0f
		cmp upper2+1
		bcc bn24+1
		sta upper2+1
bn24		lda #$aa
		stx lower2+1
		ldx mzero+1
		lda #$90
		dec pulsdec,x
		bne *+4
		lda #$b0
		sta branch2
		inc pulsdec,x
		lda pulslo,x
branch2		bcc bn26
		clc
		adc p+2-4,y
		sta pulslo,x
		lda pulshi,x
		adc #0
		sta pulshi,x
upper2		cmp #0
		bcs bn29
		bcc set_puls
bn26		sec
		sbc p+2-4,y
		sta pulslo,x
		lda pulshi,x
		sbc #0
		sta pulshi,x
		bcc *+6
lower2		cmp #0
		bcs set_puls
		inc pulshi,x
bn29		lda #0
		sta pulslo,x
ph3		lda p+3-4,y
		bpl *+5
		dec pulsdec,x
		dec pulsdec,x
		bne set_puls
		and #$7f
		sta pulsle,x
;----------------------SET PULSE VALUES-
set_puls
		!if rem_mp = 1 {
r_mp5		lda pulslo,x
		sta sid+2,x
		lda pulshi,x
		sta sid+3,x
		} else {	;*= *-((*-r_mp5)*(1-rem_mp))

r_mp6		txa
		tay
		ldx x+1
		lda pulslo,y
		sta sid+2,x
		lda pulshi,y
		sta sid+3,x
		}	;*= *-((*-r_mp6)*rem_mp)

	}	;*= *-((*-pulse)*rem_pu)

;----------------------GLIDE ROUTINE----
		!if rem_glid = 0 {
glide		lda glidadd,x
		bmi glide_it
		bne *+5
		jmp vibrato
		ora #$80
		sta glidadd,x
		jmp getadd
glide_it	ldy note,x
		sty mzero+1
		lda addlo,x
		clc
		adc freqlo,y
		sta mzero
		lda addhi,x
		adc freqhi,y
		pha
		ldy glidto,x
		lda mzero
		cmp freqlo,y
		pla
		sbc freqhi,y

bn65		lda addlo,x
		bcc bn11
		sbc addval_l,x
		sta addlo,x
		lda #$b0
		sta addor
		lda addhi,x
		sbc addval_h,x
		jmp bn19

bn11		adc addval_l,x
		sta addlo,x
		lda #$90
		sta addor
		lda addhi,x
		adc addval_h,x
bn19		sta addhi,x
		sta mzero

		lda addlo,x
		ldx mzero+1
		clc
		adc freqlo,x
		php
		cmp freqlo,y
		lda mzero
		adc freqhi,x
		plp
		sbc freqhi,y
		ldx x+1
addor		bcc bn60
		tya
		sta note,x
		lda #0
		sta glidadd,x
		sta addlo,x
		sta addhi,x
bn60		jmp wfrout

		}	;*= *-((*-glide)*rem_glid)

;----------------------VIBRATO ROUTINE--

	!if rem_vib = 0 {
vibrato		lda vible,x
		beq bn63
		asl
		adc vible,x
		tay
		lda vibdec,x
		bne bn16
		sta addlo,x
		sta addhi,x
		lda v-3,y
		!if rem_det = 0 {
r_det4		beq detun
		cmp #$fe
		beq detun2
		}	;*= *-((*-r_det4)*rem_det)

		sta vibdec,x
		lda v+1-3,y
		cmp #$80
		and #$7f
		sta vibwid,x
		ror
		sta vibdir,x
		lda v+2-3,y
	}	;*= *-((*-vibrato)*rem_vib)

	!if addsum = 0 {
getadd		and #$7f
		sta mzero
		lda note,x
		lsr
		clc
		adc mzero
		cmp #$60
		bcc *+6
		and #$1f
		ora #$60
		tay
		lda #0
		bcc bn17
		lda freqhi-$60,y
bn17		sta addval_h,x
		lda freqhi,y
		sta addval_l,x
		!if rem_vib = 0 {
bn63		jmp wfrout
		}	;*= *-((*-bn63)*rem_vib)
	}	;*= *-((*-getadd)*addsum)

	!if rem_vib = 0 {
		!if rem_det = 0 {
detun		inc vible,x
detun2		lda v+1-3,y
		sta detunlo,x
		lda v+2-3,y
		sta detunhi,x
		jmp wfrout
		}	;*= *-((*-detun)*rem_det)

bn16		cmp #$ff
		beq bn53
		dec vibdec,x
		bne bn53
		inc vible,x
bn53
;----------------------CRAZY COMET FX---
		!if rem_cc = 0 {
cc1		lda v+2-3,y
		bpl bn59
		and #3
andcount	and #0
		bne bn59
		sta frq_l+1
		beq wfrout2-3

		}	;*= *-((*-cc1)*rem_cc)
;----------------------ADD/SUB FREQUENCY
bn59		lda addlo,x
		ldy vibdir,x
		bmi bn1
		clc
		adc addval_l,x
		sta addlo,x
		lda addhi,x
		adc addval_h,x
		jmp bn2
bn1		sec
		sbc addval_l,x
		sta addlo,x
		lda addhi,x
		sbc addval_h,x
bn2		sta addhi,x
		dey
		tya
		sta mzero
		bit mzero
		bvc bn3
		eor #$7f
		ora vibwid,x
bn3		sta vibdir,x
	}	;*= *-((*-detun)*rem_vib)

;----------------------SET FREQUENCIES--
wfrout
	!if frqsum = 0 {
r_det5		lda addlo,x
		!if rem_det = 0 {
r_det6		clc
		adc detunlo,x
		}	;*= *-((*-r_det6)*rem_det)
		sta frq_l+1
		lda addhi,x
		!if rem_det = 0 {
r_det7		adc detunhi,x
		}	;*= *-((*-r_det7)*rem_det)
		sta frq_h+1
	}	;*= *-((*-r_det5)*frqsum)

;----------------------WAVEFORM PROGRAM-
wfrout2		ldy wfp,x
		lda w,y
		cmp #$ff
		bne wf_loop

		!if rem_wfr = 0 {
r_wfr1		lda wf_repet,x
		beq norep
		dec wf_repet,x
		bne norep
		iny
		bne wfrout2+3
		}	;*= *-((*-r_wfr1)*rem_wfr)
norep
		lda f,y
		tay
		lda w,y
wf_loop
;----------------------Program delay----
		!if rem_wfd = 0 {
r_wfd1		cmp #$fe
		bne wf_loop2
		lda f,y
		sta wf_del,x
		iny
		tya
		sta wfp,x
		lda w,y
		}	;*= *-((*-r_wfd1)*rem_wfd)
wf_loop2
;----------------------ADSR command-----
		!if rem_adsr = 0 {
r_adsr		cmp #$fd
		bne wf_loop3
		iny
		lda release,x
		lsr
		bcc no_adsr
		lda f-1,y
		cmp #$80
		and #$7f
		sta gatedec,x
		bcs *+7
		lda #$ff
		sta gate,x
		lda w,y
		sta sid+5,x
		lda f,y
		sta sid+6,x
no_adsr		iny
		lda w,y
		}	;*= *-((*-r_adsr)*rem_adsr)
wf_loop3
;----------------------Multi pulse------
		!if rem_mp = 0 {
r_mp2		cmp #$fb
		bne wf_loop5
		lda f,y
		sta pulsle2,x
		lda #1
		sta pulsco,x
		lsr
		sta pulsdec2,x
		iny
		lda w,y
		sta pulseor,x
		lda f,y
		sta pulsdel,x
		iny
		lda w,y
		}	;*= *-((*-r_mp2)*rem_mp)

;----------------------WF Repeat--------
wf_loop5
		!if rem_wfr = 0 {
r_wfr2		cmp #$fa
		bne wf_loop4
		lda f,y
		sta wf_repet,x
		iny
		lda w,y
		}	;*= *-((*-r_wfr2)*rem_wfr)

		!if rem_wf0 = 0 {
wf_loop4 cmp #$f0
		bcc wf_puls
		sta sid+$15
		iny
		lda w,y
		}	;*= *-((*-wf_loop4)*rem_wf0)

;----------------------GET WAVEFORM-----
		!if rem_puw = 0 {
wf_puls		cmp #$ee
		bne wf_puls2
		lda f,y
		sta pulslo,x
		sta sid+2,x
		and #$0f
		sta pulshi,x
		bpl wf_pulshi

wf_puls2	cmp #$ed
		bne wf_puls3
		lda pulslo,x
		sec
		sbc f,y
		sta pulslo,x
		sta sid+2,x
		bcs wf_pulshi+3
		dec pulshi,x
		bcc wf_pulsa

wf_puls3	cmp #$ec
		bne wf_puls4
		lda pulslo,x
		clc
		adc f,y
		sta pulslo,x
		sta sid+2,x
		bcc wf_pulshi+3
		inc pulshi,x
wf_pulsa	lda pulshi,x
		jmp wf_pulshi

wf_puls4	cmp #$eb
		bne wf_loop6
		lda f,y
		sta sid+2,x
wf_pulshi
		sta sid+3,x
		iny
		lda w,y
		}	;*= *-((*-wf_puls)*rem_puw)
wf_loop6
	!if rem_arp = 0 {
		!if rem_we2 = 0 {
r_arp3
		cmp #$e2
		bcs wf_kik
		}	;*= *-((*-r_arp3)*rem_we2)
		cmp #$90
		bcc *+4
		and #$7f
	}	;*= *-((*-r_arp3)*rem_arp)
wf_kik
		sta wf,x
		and gate,x
		!if rem_wfo = 0 {
r_wfo6		ora wf_ora,x
		}	;*= *-((*-r_wfo6)*rem_wfo)
		sta sid+4,x
		iny

;----------------------WF delay counter-
		!if rem_wfd = 0 {
r_wfd2		lda wf_del,x
		beq bn57
		dec wf_del,x
		jmp bn572
		}	;*= *-((*-r_wfd2)*rem_wfd)
bn57		tya
		sta wfp,x
bn572
		!if rem_arp = 0 {
r_arp4		bcc wf_stand
;----------------------Arpeggio PRG-----
		lda arpnum,x
		bmi wf_stand
		tay
		sec
		lda arpde,x
		sbc #$40
		bcs *+5
		lda ad+1,y
		sta arpde,x
		ldy arple,x
		bcs *+5
		inc arple,x
		lda a,y
		bpl bn48
		bcs bn48
		pha
		ldy arpnum,x
		lda ad,y
		sta arple,x
		pla
		bne bn48
		}	;*= *-((*-r_arp4)*rem_arp)

wf_stand	lda f-1,y
		bmi bn44
bn48		clc
		adc note,x
bn44		and #$7f
		tay

		lda freqlo,y
		!if frqsum = 0 {
fcode		clc
frq_l		adc #0
		sta sid+0,x
		lda freqhi,y
frq_h		adc #0
		}	;*= *-((*-fcode)*frqsum)

	!if frqsum = 1 {
		!if addsum = 0 {
fcode2		clc
		adc addlo,x
		}	;*= *-((*-fcode2)*addsum)
		sta sid+0,x
		lda freqhi,y
		!if addsum = 0 {
fcode3		adc addhi,x
		}	;*= *-((*-fcode3)*addsum)
	}	;*= *-((*-fcode2)*(1-frqsum))
		sta sid+1,x

sid_next	lda chanx,x
		bmi cc2
		tax
		jmp part1

cc2		!if rem_cc = 0 {
		inc andcount+1
		}	;*= *-((*-cc2)*rem_cc)
	!if rem_fad = 0 {
r_fad4
fade		lda #0
		beq nofade
		dec fadeco
		bpl nofade
		clc
		adc #1
		lsr
		sta fadeco
		ldy #0
		bcc fadedwn
voiceon
		!if rem_voff = 0 {
r_voff4		lda #0
		sta voff+1
		}	;*= *-((*-r_voff4)*rem_voff)
		lda vol+1
		cmp #$0f
		bcc fadeup
		sty fade+1
		bcs nofade
fadedwn		dec vol+1
		bpl nofade
		!if rem_voff = 0 {
r_voff5		lda voff+1
		sta voiceon+1
		sty voff+1
		}	;*= *-((*-r_voff5)*rem_voff)
		sty fade+1
fadeup		inc vol+1

nofade
	}	;*= *-((*-r_fad4)*rem_fad)

	!if rem_fi = 0 {
r_fi3
		!if rem_4ch = 0 {
setfi		lda #0
		beq filtok
		!if rem_fspd = 0 {
f_spd6		ldx #0
		stx filtspd
		}	;*= *-((*-f_spd6)*rem_fspd)
		jmp fidir
		}	;*= *-((*-setfi)*rem_4ch)
filtok
		!if rem_fspd = 0 {
f_spd1		dec filtspd
		bmi fspeed
		jmp filtch
fspeed		lda #0
		sta filtspd
		}	;*= *-((*-f_spd1)*rem_fspd)

filtle		lda #0
		asl
		bne *+5
		jmp filtch
		asl
		tay
filtdec		lda #0
		bne bn38
		lda #2
		sta filtdec+1
		lda #$b0
		sta branch
		bcs bn38

filtsnd		ldx #0
		!if rem_4ch = 0 {
r_4ch4		bmi fivoice4
		}	;*= *-((*-r_4ch4)*rem_4ch)

		lda fi+1-4,y		;frame v2.1
		bne *+7		;
		lda fi+2-4,y		;
		bne *+5		;

		lda z7,x
		tax
		asl
		asl
		asl
		asl
		sta res+1
		txa
		and #$f0
		sta band+1
fivoice4	lda fi-4,y
		sta cutoff+1

bn38		lda fi+1-4,y
		bne *+8		;frame v2.1
		lda cutoff+1		;
		jmp bn42		;

		asl
		asl
		asl
		asl
		tax
		stx upper+1
		lda fi+1-4,y
		and #$f0
		cmp upper+1
		bcc bn43+1
		sta upper+1
bn43		lda #$aa
		stx lower+1

cutoff		lda #0
branch		bcc bn39
		clc
		adc fi+2-4,y
upper		cmp #0
		bcc bn40
		bcs bn42

bn39		sec
		sbc fi+2-4,y
		bcc *+6		;217
lower		cmp #0
		bcs bn40
		clc		;217
		adc fi+2-4,y	;217
bn42		ldx fi+3-4,y
		bpl *+5
		dec filtdec+1
		dec filtdec+1
		bne bn41
		stx filtle+1
bn41		ldx #$90
		stx branch
bn40		sta cutoff+1

fidir		sta sid+$16
filtch		lda #0
filtena		!if rem_f20 = 0 {
		ora #0
		}	;*= *-((*-filtena)*rem_f20)
res		ora #0
		sta sid+$17
	}	;*= *-((*-r_fi3)*rem_fi)

vol		lda #$0f
		!if rem_fi = 0 {
r_fi4
band		ora #0
		}	;*= *-((*-r_fi4)*rem_fi)
		sta sid+$18

		!if rem_voff = 0 {
r_voff6		lda voff+1
		beq bn8
		}	;*= *-((*-r_voff6)*rem_voff)

		dec tempo+1
		bpl bn8

		dec duration
		dec duration+7
		dec duration+14
		!if rem_4ch= 0 {
r_4ch3		dec duration+21
		}	;*= *-((*-r_4ch3)*rem_4ch)

tem_prg		lda #0

		!if rem_tp = 0 {
r_tp		bmi tem_num
		tay
		lda tem_p,y
		clc
tem_y		adc #0
		tay
		lda tem_d,y
		bpl tpl
		ldy #$ff
		sty tem_y+1
tpl		inc tem_y+1
tem_num		and #$7f
		}	;*= *-((*-r_tp)*rem_tp)

		sta tempo+1
		cmp #3
		bcc *+4
		lda #2
		sta cur_tem+1
bn8		rts

;pal tuned freqtable:
;(ntsc freqtable is on release disk)

freqhi		!byte $01,$01,$01,$01,$01,$01
		!byte $01,$01,$01,$01,$01,$02
		!byte $02,$02,$02,$02,$02,$02
		!byte $03,$03,$03,$03,$03,$04
		!byte $04,$04,$04,$05,$05,$05
		!byte $06,$06,$06,$07,$07,$08
		!byte $08,$09,$09,$0a,$0a,$0b
		!byte $0c,$0d,$0d,$0e,$0f,$10
		!byte $11,$12,$13,$14,$15,$17
		!byte $18,$1a,$1b,$1d,$1f,$20
		!byte $22,$24,$27,$29,$2b,$2e
		!byte $31,$34,$37,$3a,$3e,$41
		!byte $45,$49,$4e,$52,$57,$5c
		!byte $62,$68,$6e,$75,$7c,$83
		!byte $8b,$93,$9c,$a5,$af,$b9
		!byte $c4,$d0,$dd,$ea,$f8,$ff
freqlo		!byte $16,$27,$39,$4b,$5f,$74
		!byte $8a,$a1,$ba,$d4,$f0,$0e
		!byte $2d,$4e,$71,$96,$be,$e7
		!byte $14,$42,$74,$a9,$e0,$1b
		!byte $5a,$9c,$e2,$2d,$7b,$cf
		!byte $27,$85,$e8,$51,$c1,$37
		!byte $b4,$38,$c4,$59,$f7,$9d
		!byte $4e,$0a,$d0,$a2,$81,$6d
		!byte $67,$70,$89,$b2,$ed,$3b
		!byte $9c,$13,$a0,$45,$02,$da
		!byte $ce,$e0,$11,$64,$da,$76
		!byte $39,$26,$40,$89,$04,$b4
		!byte $9c,$c0,$23,$c8,$b4,$eb
		!byte $72,$4c,$80,$12,$08,$68
		!byte $39,$80,$45,$90,$68,$d6
		!byte $e3,$99,$00,$24,$10,$ff


init
	!if rem_voff = 0 {
r_voff7
		lda c,x
		sta voff+1
		!if rem_fad = 0 {
r_fad5		sta voiceon+1
		}	;*= *-((*-r_fad5)*rem_fad)
	}	;*= *-((*-r_voff7)*rem_voff)

		lda s,x
		sta tem_prg+1
		lda #1
		sta tempo+1
		sta cur_tem+1

	!if rem_fi = 0 {
r_fi5		lda fs,x
		!if rem_fspd = 0 {
f_spd2		tay
		and #$0f
		sta fspeed+1
		tya
		}	;*= *-((*-f_spd2)*rem_fspd)
		lsr
		lsr
		lsr
		lsr
		sta filtena+1
	}	;*= *-((*-r_fi5)*rem_fi)

		!if rem_fad = 0 {
r_fad2		lda fv,x
		pha
		and #$0f
		sta vol+1
		}	;*= *-((*-r_fad2)*rem_fad)

		lda #$60
		!if rem_4ch = 0 {
trin1		sta trk_end
		} else {	;*= *-((*-trin1)*rem_4ch)
trin2		sta ack
		}	;*= *-((*-trin2)*(1-rem_4ch))

		ldy tp,x
		ldx #channels*7
bn52		!if rem_voff = 0 {
		lda voff+1
		and chanon,x
		beq bn74
		}	;*= *-((*-bn52)*rem_voff)
		lda #0
		sta tdelay,x
		sta dur,x
		sta seqp,x
		sta transp,x
		!if rem_trkl = 1 {
r_trkl6		sta tracky,x
		}	;*= *-((*-r_trkl6)*(1-rem_trkl))
		!if rem_4ch = 0 {
t40		cpx #3*7
		bcs t44
		}	;*= *-((*-t40)*rem_4ch)
		sta pulsle2,x
		sta srco,x
		!if rem_fi = 0 {
r_fi6		sta filtre,x		;fi subtune fix
		}	;*= *-((*-r_fi6)*rem_fi)

		!if rem_wfr = 0 {
r_wfr4		sta wf_repet,x
		}	;*= *-((*-r_wfr4)*rem_wfr)
		lda #$fe		;217
		sta gate,x		;217
t44		lda #$fe
		sta note2,x
		sta duration,x
		sta sound,x
		lda tl,y
		sta trklo,x
		!if rem_trkl = 0 {
r_trkl7		sta tracky,x
		}	;*= *-((*-r_trkl7)*rem_trkl)
		lda th,y
		sta trkhi,x
		!if rem_trkl = 0 {
r_trkl8		sta trackhi,x
		}	;*= *-((*-r_trkl8)*rem_trkl)

		tya
		pha
		jsr track_init
		pla
		tay

t43		dey
bn74		lda chanx,x
		tax
		bpl bn52

		ldx #$14
		lda #0
		sta sid+0,x
		dex
		bpl *-4
		!if rem_cc = 0 {
cc3		sta andcount+1
		}	;*= *-((*-cc3)*rem_cc)
		!if rem_tp = 0 {
r_tp2		sta tem_y+1
		}	;*= *-((*-r_tp2)*rem_tp)

	!if rem_fi = 0 {
		!if rem_4ch = 0 {
r_fi7		sta setfi+1
		}	;*= *-((*-r_fi7)*rem_4ch)
		!if rem_fspd = 0 {
f_spd5		sta filtspd
		}	;*= *-((*-f_spd5)*rem_fspd)
		sta filtch+1
		ldy #$07
		sty sid+$15
	}	;*= *-((*-r_fi7)*rem_fi)

		!if rem_4ch = 0 {
trin3		sta trk_tran+1
		sta note2ch4+1
		lda #$e0
		sta trk_end
		} else {	;*= *-((*-trin3)*rem_4ch)

trin4		lda #$a9
		sta ack
		}	;*= *-((*-trin4)*(1-rem_4ch))

		!if rem_fad = 0 {
r_fad1		pla
		and #$f0
fadeout		sta fade+1
		sta fadeco
		}	;*= *-((*-r_fad1)*rem_fad)
		rts

!src "songdata.asm"
