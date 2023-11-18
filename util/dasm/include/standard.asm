;Dasm standard macros


;---------------------------------------------------
;wait macro
;wait from 2 to 63 cycles supported
;needed in the main source:
;wait14			nop
;wait12			rts


			mac delay
			if {1}=1
			echo "delay = 1 not supported!"
			err
			endif
			if {1}=2
			nop
			endif
			if {1}=3
			dc.b $04,$03	;nop zp
			endif
			if {1}=4
			nop
			nop
			endif
			if {1}=5
			nop
			dc.b $04,$03	;nop zp
			endif
			if {1}=6
			nop
			nop
			nop
			endif
			if {1}=7
			pha
			pla
			endif
			if {1}=8
			nop
			nop
			nop
			nop
			endif
			if {1}=9
			nop
			pha
			pla
			endif
			if {1}=10
			dc.b $04,$03	;nop zp
			pha
			pla
			endif
			if {1}=11
			nop
			nop
			pha
			pla
			endif
			if {1}=12
			jsr wait12
			endif
			if {1}=13
			nop
			nop
			nop
			pha
			pla
			endif
			if {1}=14
			jsr wait14
			endif
			if {1}=15
			jsr wait12
			dc.b $04,$03	;nop zp
			endif
			if {1}=16
			nop
			jsr wait14
			endif
			if {1}=17
			jsr wait14
			dc.b $04,$03	;nop zp
			endif
			if {1}=18
			nop
			nop
			jsr wait14
			endif
			if {1}=19
			nop
			dc.b $04,$03	;nop zp
			jsr wait14
			endif
			if {1}=20
			nop
			nop
			nop
			jsr wait14
			endif
			if {1}=21
			pha
			pla
			jsr wait14
			endif
			if {1}=22
			nop
			nop
			nop
			nop
			jsr wait14
			endif
			if {1}=23
			nop
			pha
			pla
			jsr wait14
			endif
			if {1}=24
			dc.b $04,$03	;nop zp
			pha
			pla
			jsr wait14
			endif
			if {1}=25
			nop
			nop
			pha
			pla
			jsr wait14
			endif
			if {1}=26
			jsr wait12
			jsr wait14
			endif
			if {1}=27
			dc.b $04,$03	;nop zp
			jsr wait12
			jsr wait12
			endif
			if {1}=28
			jsr wait14
			jsr wait14
			endif
			if {1}=29
			dc.b $04,$03	;nop zp
			jsr wait12
			jsr wait14
			endif
			if {1}=30
			nop
			jsr wait14
			jsr wait14
			endif
			if {1}=31
			dc.b $04,$03	;nop zp
			jsr wait14
			jsr wait14
			endif
			if {1}=32
			nop
			nop
			jsr wait14
			jsr wait14
			endif
			if {1}=33
			nop
			dc.b $04,$03	;nop zp
			jsr wait14
			jsr wait14
			endif
			if {1}=34
			nop
			nop
			nop
			jsr wait14
			jsr wait14
			endif
			if {1}=35
			pha
			pla
			jsr wait14
			jsr wait14
			endif
			if {1}=36
			jsr wait12
			jsr wait12
			jsr wait12
			endif
			if {1}=37
			nop
			pha
			pla
			jsr wait14
			jsr wait14
			endif
			if {1}=38
			nop
			jsr wait12
			jsr wait12
			jsr wait12
			endif
			if {1}=39
			dc.b $04,$03	;nop zp
			jsr wait12
			jsr wait12
			jsr wait12
			endif
			if {1}=40
			jsr wait12
			jsr wait14
			jsr wait14
			endif
			if {1}=41
			dc.b $04,$03	;nop zp
			jsr wait12
			jsr wait12
			jsr wait14
			endif
			if {1}=42
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=43
			dc.b $04,$03	;nop zp
			jsr wait12
			jsr wait14
			jsr wait14
			endif
			if {1}=44
			nop
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=45
			dc.b $04,$03	;nop zp
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=46
			nop
			nop
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=47
			nop
			dc.b $04,$03	;nop zp
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=48
			nop
			nop
			nop
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=49
			pha
			pla
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=50
			nop
			nop
			nop
			nop
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=51
			nop
			pha
			pla
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=52
			dc.b $04,$03	;nop zp
			pha
			pla
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=53
			nop
			nop
			pha
			pla
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=54
			jsr wait12
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=55
			nop
			nop
			nop
			pha
			pla
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=56
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=57
			dc.b $04,$03	;nop zp
			jsr wait12
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=58
			nop
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=59
			dc.b $04,$03	;nop zp
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=60
			nop
			nop
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=61
			nop
			dc.b $04,$03	;nop zp
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=62
			nop
			nop
			nop
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=63
			pha
			pla
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=64
			nop
			nop
			nop
			nop
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=65
			nop
			pha
			pla
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=66
			dc.b $04,$03	;nop zp
			pha
			pla
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=67
			dc.b $04,$03	;nop zp
			nop
			nop
			pha
			pla
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}=68
			dc.b $04,$03	;nop zp
			jsr wait12
			jsr wait14
			jsr wait14
			jsr wait14
			jsr wait14
			endif
			if {1}>69
			echo "delay > 63 not supported!"
			err
			endif
			endm
;------------------------------------------------------------------------------
;test wait macro			
			; processor 6502

			; org $0801
			; ;basic sys line
			; dc.b $0b,$08,$00,$00,$9e,$32,$30,$36
			; dc.b $31,$00,$00,$00
			; sei
			
; .forever		wait 63
			; inc $d020
			; wait 12
			; inc $d020
			; wait 9
			; jmp .forever

; wait14			nop
; wait12			rts
