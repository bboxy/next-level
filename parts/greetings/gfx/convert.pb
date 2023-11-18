EnableExplicit

;******************************************************************************
;- Enumeration
;******************************************************************************
;Windows
Enumeration
  #Text01
EndEnumeration

;Fonts
Enumeration
  #Font01
EndEnumeration

;Gadgets
Enumeration
  #Editor01
EndEnumeration

;******************************************************************************
;- Constants
;******************************************************************************
#PicSizeX = 4096  ;muss durch 32 teilbar sein
#PicSizeY = 2048

#BlockSizeX = 4
#BlockSizeY = 2
#BlockSize = #BlockSizeX*#BlockSizeY*2

#CharsX = #PicSizeX/8 ;Anzahl Chars in x und y
#CharsY = #PicSizeY/16

#BlocksX = #CharsX/#BlockSizeX  ;Anzahl 4x4 char Blöcke in x und y
#BlocksY = #CharsY/#BlockSizeY

#EmptyChar = 0        ;normally 0
#ParX = 4             ;width of parallax in chars
#ParY = 2             ;heigth of parallax in chars
#FirstParChar = 256-#ParX*#ParY 
#ParCol = 4   ;Colorram for Parallax

Debug "First parallax char " + Str(#FirstParChar)
Debug "CharsX " + Str(#CharsX)
Debug "CharsY " + Str(#CharsY)
Debug "BlocksX " + Str(#BlocksX)
Debug "Blocksy " + Str(#BlocksY)

;******************************************************************************
;- Variables
;******************************************************************************
;Zeiger allozierter Speicher
Define.l  *ScrMap
Define.l  *ColMap
Define.l  *Buffer

Define.l BlockCount   ;Anzahl unterschiedlicher Blöcke

;Trash-Variablen für Schleifen etc.
Define.l	c,i,t,x,y,cx,cy,z

Define.a a

;******************************************************************************
;- Arrays
;******************************************************************************
Dim Charblocks.a(#BlocksX*#BlocksY-1,#BlockSizeX*#BlockSizeY*2-1)  ;max. 256 unterschiedliche Blöcke a 4x2 Chars + 4x2 Colorram
Dim TempBlock.a(#BlockSizeX*#BlockSizeY*2-1) ;temporärer Block für Vergleich
Dim BlockMap.a(#BlocksX*#BlocksY-1)
;******************************************************************************
;- Strings
;******************************************************************************
Define FileName.s  = ""
Define.s SaveName
Define.s Source
;******************************************************************************
;- Init
;******************************************************************************
FileName.s = "greetz"

;******************************************************************************
;- Load data
;******************************************************************************

;Load ScreenMap
i = 0
If ReadFile(0, FileName.s+".scr")
  t = Lof(0)
  Debug "FileLength: " + Str(t)

  *ScrMap = AllocateMemory(t)

  If *ScrMap = 0
    MessageRequester("Error!", "Couldn't allocate workspace!", 0)
    End 1
  EndIf
  t = ReadData(0,*ScrMap,t)
  CloseFile(0)
Else
  MessageRequester("Error!","Couldn't open file!")
  End 1
EndIf

;Load ColorMap
i = 0
If ReadFile(0, FileName.s+".col")
  t = Lof(0)
  Debug "FileLength: " + Str(t)

  *ColMap = AllocateMemory(t)

  If *ColMap = 0
    MessageRequester("Error!", "Couldn't allocate workspace!", 0)
    End 1
  EndIf
  t = ReadData(0,*ColMap,t)
  CloseFile(0)
Else
  MessageRequester("Error!","Couldn't open file!")
  End 1
EndIf

;******************************************************************************
;- patch endless parallax to screenmap
;******************************************************************************
;0,1,2,3    0,2,4,6
;4,5,6,7    1,3,5,7

y=1
For y = 0 To #CharsY-1
;  Debug "Line: " + Str(y)
  For x = 0 To #CharsX-1
    
    t=PeekA(*ScrMap+y*#CharsX+x)
 ;    Debug PeekA(*ScrMap+y*#CharsX+x)
    
    If t = #EmptyChar
      PokeA(*ScrMap+y*#CharsX+x, y % #ParY + (x % #ParX) * #ParY + #FirstParChar)
      PokeA(*ColMap+y*#CharsX+x, #ParCol)
    EndIf
  ; Debug PeekA(*ScrMap+y*#CharsX+x)
  Next x
Next y



;******************************************************************************
;- gen 4x4 blocks and mapdata
;******************************************************************************

BlockCount=0

For y = 0 To #Blocksy-1
For x = 0 To #BlocksX-1

  For cy = 0 To #BlockSizeY-1     ;hole aktuellen block für vergleich
    For cx = 0 To #BlockSizeX-1
      TempBlock.a(cy*#BlockSizeX+cx)=PeekA(*ScrMaP+cy*#CharsX+cx+y*#CharsX*#BlockSizeY+x*#BlockSizeX)
      TempBlock.a(cy*#BlockSizeX+cx+#BlockSizeX*#BlockSizeY)=PeekA(*ColMaP+cy*#CharsX+cx+y*#CharsX*#BlockSizeY+x*#BlockSizeX)
    Next cx
  Next cy

  If BlockCount = 0               ;kopiere immer den ersten Block
    For i = 0 To #BlockSize-1
      Charblocks.a(BlockCount,i) = TempBlock.a(i)
      Debug Str(TempBlock.a(i))
    Next i
    BlockCount=1
  Else                            ;prüfe ob der Block schon gespeichert wurde

    For t = 0 To BlockCount-1
      c=0

      For i = 0 To #BlockSize-1
        If Charblocks.a(t,i) <> TempBlock.a(i)
          c=1
          Break
        EndIf
      Next i

      If c=0
        BlockMap.a(y*#BlocksX+x)=t
        Break
      EndIf
    Next t
    If c = 1
      For i = 0 To #BlockSize-1
        Charblocks.a(BlockCount,i) = TempBlock.a(i)
      Next i

      BlockMap.a(y*#BlocksX+x)=BlockCount

      BlockCount=BlockCount+1
    EndIf

  EndIf

Next x
Next y

Debug "BlockCount: "+Str(BlockCount)
Debug "BlockMapSize: " +Str((#BlocksX*#BlocksY-1))

;******************************************************************************
;- Create Source
;******************************************************************************

Source=""
For t = 0 To #BlockSizeX*#BlockSizeY*2-1

If t < #BlockSizeX*#BlockSizeY

  Source.s = Source.s + "charblock" + RSet(Str(t), 1) + #CRLF$
Else
  Source.s = Source.s + "colorblock" + RSet(Str(t-#BlockSizeX*#BlockSizeY), 1) + #CRLF$
EndIf

z = 0	;Pointer für alle 32 Bytes ein Hex

For i = 0 To 255

  If z = 0
    Source.s = Source.s + " hex "
  EndIf

  Source.s = Source.s + RSet(Hex(Charblocks.a(i,t)), 2, "0")

  z = z + 1

  If z = 8 Or z = 16 Or z = 24 Or z = 32 Or z = 40 Or z = 48 Or z = 56
    Source.s = Source.s + " "
  EndIf

  If z = 64
    z = 0
    Source.s = Source.s + #CRLF$
  EndIf
Next i
Source.s = Source.s + #CRLF$
Next t

;blockmap

Source.s = Source.s + "blockmap" + #CRLF$

z = 0	;Pointer für alle 32 Bytes ein Hex

For i = 0 To #BlocksX*#BlocksY-1

If z = 0
  Source.s = Source.s + " hex "
EndIf

Source.s = Source.s + RSet(Hex(BlockMap.a(i)), 2, "0")

z = z + 1

If z = 8 Or z = 16 Or z = 24 Or z = 32 Or z = 40 Or z = 48 Or z = 56
  Source.s = Source.s + " "
EndIf

If z = 64
  z = 0
  Source.s = Source.s + #CRLF$
EndIf
Next i
Source.s = Source.s + #CRLF$


;******************************************************************************
;- DisplaySource
;******************************************************************************

If OpenWindow(#Text01, 0, 0, 1184, 992, "Mapdata Source - Close window to continue", #PB_Window_SystemMenu | #PB_Window_ScreenCentered|#PB_Window_SizeGadget)
EditorGadget(#Editor01, 8, 8, 1168, 976,#PB_Editor_ReadOnly)

If LoadFont(#Font01,"Courier",10)
  SetGadgetFont(#Editor01, FontID(#Font01))   ; geladenen Courier 10 Zeichensatz als neuen Standard festlegen
EndIf

SetGadgetColor(#Editor01, #PB_Gadget_BackColor, $FFFFFF)
SetGadgetText(#Editor01, Source.s)
Repeat : Until WaitWindowEvent() = #PB_Event_CloseWindow
EndIf



; For i = 0 To #BlockSize-1
;   Debug Str(Charblocks.a(1,i))
; Next i
;
; For i = 0 To #BlocksX*#BlocksY-1
;   Debug Str(BlockMap.a(i))
; Next i

End

; IDE Options = PureBasic 6.01 LTS (Windows - x64)
; CursorPosition = 25
; EnableXP
; Executable = convert.exe