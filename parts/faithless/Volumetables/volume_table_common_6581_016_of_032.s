; A volume table for 6581 with 32 values, and 16 of those are linear.
; Generated on the 22-Jan-2014
; Pex Mahoney Tufvesson, 2014

;How? Take the desired amplitude in the range of 0-32 (with zero level at 16),
;then grab the value in this table and do a single, jittered(!) write to $d418.
;Where does the magic come from?
;- You will need to setup the SID voices according to what is described in the
;  readme file. It includes filter, test-bits and other fun stuff.

  dc.b 159
  dc.b 159
  dc.b 159
  dc.b 159
  dc.b 159
  dc.b 159
  dc.b 159
  dc.b 159
  dc.b 159
  dc.b 158
  dc.b 155
  dc.b 152
  dc.b 215
  dc.b 213
  dc.b 179
  dc.b 241
  dc.b 65
  dc.b 67
  dc.b 36
  dc.b 38
  dc.b 74
  dc.b 108
  dc.b 44
  dc.b 46
  dc.b 15
  dc.b 15
  dc.b 15
  dc.b 15
  dc.b 15
  dc.b 15
  dc.b 15
  dc.b 15
; End of generated data

