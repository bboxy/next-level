; A volume table for 8580 with 32 values, and 16 of those are linear.
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
  dc.b 158
  dc.b 221
  dc.b 155
  dc.b 218
  dc.b 152
  dc.b 151
  dc.b 124
  dc.b 121
  dc.b 86
  dc.b 83
  dc.b 128
  dc.b 3
  dc.b 6
  dc.b 72
  dc.b 11
  dc.b 14
  dc.b 79
  dc.b 79
  dc.b 79
  dc.b 79
  dc.b 79
  dc.b 79
  dc.b 79
  dc.b 79
; End of generated data

