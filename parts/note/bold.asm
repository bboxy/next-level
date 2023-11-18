* = 0
; first create "as-is" table
; now exchange upper and lower case characters
!for i,0,255 {!byte (i + 128) & $ff}
* = 65, overlay
!for i, 1, 26 {!byte i + 128 + 64}
* = 97, overlay
!for i, 1, 26 {!byte i + 128}
