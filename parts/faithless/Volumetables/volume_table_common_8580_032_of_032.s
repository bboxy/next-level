; A volume table for 8580 with 32 values, and 32 of those are linear.
; Generated on the 22-Jan-2014
; Pex Mahoney Tufvesson, 2014

;How? Take the desired amplitude in the range of 0-32 (with zero level at 16),
;then grab the value in this table and do a single, jittered(!) write to $d418.
;Where does the magic come from?
;- You will need to setup the SID voices according to what is described in the
;  readme file. It includes filter, test-bits and other fun stuff.

  dc.b 223
  dc.b 158
  dc.b 157
  dc.b 156
  dc.b 220
  dc.b 219
  dc.b 154
  dc.b 153
  dc.b 217
  dc.b 216
  dc.b 63
  dc.b 126
  dc.b 60
  dc.b 123
  dc.b 57
  dc.b 88
  dc.b 22
  dc.b 85
  dc.b 19
  dc.b 82
  dc.b 240
  dc.b 1
  dc.b 66
  dc.b 4
  dc.b 69
  dc.b 70
  dc.b 8
  dc.b 9
  dc.b 74
  dc.b 44
  dc.b 13
  dc.b 78
; End of generated data

