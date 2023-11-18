EnableExplicit

;******************************************************************************
;- Constants
;******************************************************************************
#LineOffset = 40
#FileOffset = 40*25     ;animations start after inital screen
#MaxWrites = 1999       ;Full Screen + Full Color ram worst case

;******************************************************************************
;- Variables
;******************************************************************************
;Zeiger allozierter Speicher
Define.i *screenmap
Define.i *colormap


;Trash-Variablen für Schleifen etc.
Define.i AnimCount
Define.i	i, s, d, t, h, j, l, x, y
Define.i xsize, ysize, xdest, ydest,xoffset, yoffset, yadd, rtsflag, LastFrame, linkanim
Define.a ScreenValue, ColorValue
Define.i ValueSum
Define.i Same
Define.i LastValue
Define.i WritesCount

;******************************************************************************
;- Strings
;******************************************************************************
Define.s Source = ""
Define.s Anim = ""
Define.s Filename = ""

;******************************************************************************
;- Structures
;******************************************************************************
Structure Writes
  Adress.i
  Value.i
EndStructure

;******************************************************************************
;- Arrays
;******************************************************************************
Dim WritesList.Writes (#MaxWrites)

;******************************************************************************
;- Lists
;******************************************************************************
Define NewList Flds(), NewList Opts(), NewList Typs()

;******************************************************************************
;- Procedures
;******************************************************************************
Procedure   MySortArray(AdressOfArray, SizeOfStructure, List FldOffset.i(), List FldOption.i(), List FldType.i(), RangeStart, RangeEnd)
  ; generic, multi-fields, bottom-up iterative, stable merge-sort
  ; usage: MySortArray(@Ary(0), SizeOf(ary_structre), Flds(), Opts(), Typs(), RangeStart, RangeEnd)
  Protected   n,i,j,m, k, s1,e1,s2,e2, z, srt_asc, tmp, mode, res, dlt
  Protected   *a, *b, *pi, *pj, *p, *q
  Protected   Fld_Adr, Fld_Opt, Fld_Typ, iFld, nFld, Dim FAdr(0), Dim FOpt(0), Dim FTyp(0)
  
  n  = RangeEnd - RangeStart + 1
  If n <= 0 : ProcedureReturn : EndIf
  If ListSize(FldOffset()) = 0 : ProcedureReturn : EndIf
  *a = AdressOfArray
  *b = AllocateMemory(n * SizeOfStructure)
  z  = SizeOfStructure
  
  ; converting lists into arrays, faster access (guarantee all 3 lists have same size)
  nFld = ListSize(FldOffset()) - 1
  Dim FAdr(nFld)
  Dim FOpt(nFld)
  Dim FTyp(nFld)
  ForEach FldOffset()
    FAdr(iFld) = FldOffset()
    If SelectElement(FldOption(), ListIndex(FldOffset()))   : FOpt(iFld) = FldOption()  : EndIf
    If SelectElement(FldType(), ListIndex(FldOffset()))     : FTyp(iFld) = FldType()    : EndIf
    iFld + 1
  Next
  
  k = 1       ; at each run, k is the nbr of elements in each half
  While k < n
    s1 = RangeStart
    While s1 <= RangeEnd
      e1 = s1 + (k-1) : If e1 > RangeEnd : e1 = RangeEnd : EndIf
      e2 = -1
      s2 = e1 + 1
      If s2 <= RangeEnd
        e2 = s2 + (k-1) : If e2 > RangeEnd : e2 = RangeEnd : EndIf
      EndIf
      m = s1 - RangeStart : i = s1 : j = s2
      
      While (i <= e1 And j <= e2)
        For iFld = 0 To nFld
          Fld_Adr = FAdr(iFld)
          Fld_Opt = FOpt(iFld)
          Fld_Typ = FTyp(iFld)
          srt_asc = Bool( (Fld_Opt & #PB_Sort_Descending) = 0 )
          *pi = AdressOfArray + (SizeOfStructure * i) + Fld_Adr
          *pj = AdressOfArray + (SizeOfStructure * j) + Fld_Adr
          Select Fld_Typ
            Case #PB_Byte       : dlt = PeekB(*pi) - PeekB(*pj)
            Case #PB_Ascii      : dlt = PeekA(*pi) - PeekA(*pj)
            Case #PB_Character  : dlt = PeekC(*pi) - PeekC(*pj)
            Case #PB_Unicode    : dlt = PeekU(*pi) - PeekU(*pj)
            Case #PB_Long       : dlt = PeekL(*pi) - PeekL(*pj)
            Case #PB_Integer    : dlt = PeekI(*pi) - PeekI(*pj)
            Case #PB_Float      : dlt = Sign(PeekF(*pi) - PeekF(*pj))
            Case #PB_Quad       : dlt = Sign(PeekQ(*pi) - PeekQ(*pj))
            Case #PB_Double     : dlt = Sign(PeekD(*pi) - PeekD(*pj))
            Case #PB_String
              mode = #PB_String_CaseSensitive
              If (Fld_Opt & #PB_Sort_NoCase) : mode = #PB_String_NoCase : EndIf
              
              tmp = CompareMemoryString(PeekI(*pi), PeekI(*pj), mode)
              If tmp = #PB_String_Equal   : dlt =  0 : EndIf
              If tmp = #PB_String_Lower   : dlt = -1 : EndIf
              If tmp = #PB_String_Greater : dlt =  1 : EndIf
          EndSelect
          If srt_asc
            If dlt <= 0 : res = -1 : Else : res = 1 : EndIf
          Else
            If dlt >= 0 : res = -1 : Else : res = 1 : EndIf
          EndIf
          If dlt <> 0 : Break : EndIf
        Next
        If res <= 0
          *p = *a + (z * i) : *q = *b + (z * m) : CopyMemory(*p, *q, z) : i+1
        Else
          *p = *a + (z * j) : *q = *b + (z * m) : CopyMemory(*p, *q, z) : j+1
        EndIf
        m+1
      Wend
      If i <= e1
        *p = *a + (z * i) : *q = *b + (z * m) : CopyMemory(*p, *q, (e1-i+1)*z)
        m = m + (e1-i+1)
      EndIf
      If j <= e2
        *p = *a + (z * j) : *q = *b + (z * m) : CopyMemory(*p, *q, (e2-j+1)*z)
        m = m + (e2-j+1)
      EndIf
      s1 = e1+1
      If e2 > 0 : s1 = e2 + 1 : EndIf
    Wend
    *p = *a + (z * RangeStart) : CopyMemory(*b, *p, n*z)
    k = k << 1 ; k * 2
  Wend
  FreeMemory(*b)
EndProcedure
;******************************************************************************
Procedure lda(Value.a)
  Shared Anim.s
  Anim.s=Anim.s+#TAB$+#TAB$+#TAB$+"lda #$"+LCase(RSet(Hex(Value.a), 2, "0"))+#CRLF$
EndProcedure

;******************************************************************************
Procedure ldx(Value.a)
  Shared Anim.s
  Anim.s=Anim.s+#TAB$+#TAB$+#TAB$+"ldx #$"+LCase(RSet(Hex(Value.a), 2, "0"))+#CRLF$
EndProcedure

;******************************************************************************
Procedure stx(Offset.i)
  Shared Anim.s
  If Offset.i > 999
    Anim.s=Anim.s+#TAB$+#TAB$+#TAB$+"stx colorram+$"+LCase(RSet(Hex(Offset-1000), 4, "0"))+#CRLF$
  Else
    Anim.s=Anim.s+#TAB$+#TAB$+#TAB$+"stx stagescreen+$"+LCase(RSet(Hex(Offset), 4, "0"))+#CRLF$
  EndIf
  
EndProcedure

;******************************************************************************
Procedure sax(Offset.i)
  Shared Anim.s
  If Offset.i > 999
    Anim.s=Anim.s+#TAB$+#TAB$+#TAB$+"sax colorram+$"+LCase(RSet(Hex(Offset-1000), 4, "0"))+#CRLF$
  Else
    Anim.s=Anim.s+#TAB$+#TAB$+#TAB$+"sax stagescreen+$"+LCase(RSet(Hex(Offset), 4, "0"))+#CRLF$
  EndIf
  
EndProcedure

;******************************************************************************
Procedure rts()
  Shared Anim.s
  Anim.s=Anim.s+#TAB$+#TAB$+#TAB$+"rts"+#CRLF$
  ; Source.s=Source.s+#TAB$+#TAB$+#TAB$+"jmp jumpback"+#CRLF$
EndProcedure

;******************************************************************************
Procedure link(AnimNo.i,FrameNo.i)
  Shared Anim.s
  Anim.s+#TAB$+#TAB$+#TAB$+"ldx #$01"+#CRLF$
  Anim.s+#TAB$+#TAB$+#TAB$+"jmp anim"+RSet(Str(AnimNo.i),2,"0")+"_"+RSet(Str(FrameNo.i),2,"0")+#CRLF$
  ; Source.s=Source.s+#TAB$+#TAB$+#TAB$+"jmp jumpback"+#CRLF$
EndProcedure

;******************************************************************************
Procedure setrowlabel(AnimNo.i,FrameNo.i)
  Shared Anim.s
  Anim.s=Anim.s+"anim"+RSet(Str(AnimNo.i),2,"0")+"_"+RSet(Str(FrameNo.i),2,"0")+#CRLF$
EndProcedure

;******************************************************************************
Procedure setlabel(String.s)
  Shared Source.s
  Source.s=Source.s+String.s+#CRLF$
EndProcedure

;******************************************************************************
;- Main
;******************************************************************************
Source.s=""

;initsort
; then field: Int1 Desc
AddElement(Flds()) : Flds() = OffsetOf(Writes\Value.i)
AddElement(Typs()) : Typs() = TypeOf(Writes\Value.i)
AddElement(Opts()) : Opts() = #PB_Sort_Ascending

; then field: Int2 Asc
AddElement(Flds()) : Flds() = OffsetOf(Writes\Adress.i)
AddElement(Typs()) : Typs() = TypeOf(Writes\Adress.i)
AddElement(Opts()) : Opts() = #PB_Sort_Ascending

AnimCount=0
LastFrame=3     ;all anims have 4 frames

;Hand links 00a,00b,00c,00d
;dest 13,0
Filename.s="_stage_split_1.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_1.col" : Gosub LoadColormap
xsize=5
ysize=6
xdest=12
ydest=0
yoffset=0
xoffset=12
rtsflag=#True
yadd=ysize
Gosub CreateAnim

;Hand rechts 01a,01b,01c,01d
;dest 24,0
Filename.s="_stage_split_1.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_1.col" : Gosub LoadColormap
xsize=5
ysize=6
xdest=24
ydest=0
yoffset=0
xoffset=24
rtsflag=#True
yadd=ysize
Gosub CreateAnim

;Flammen links 02a,02b,02c,02d (link with 10)
;dest 6,6
Filename.s="_stage_split_2.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_2.col" : Gosub LoadColormap
xsize=6
ysize=4
xdest=6
ydest=6
yoffset=0
xoffset=6
rtsflag=#False
linkanim=10
yadd=ysize
Gosub CreateAnim

;Flammen rechts 03a,03b,03c,03d
;dest 28,6
Filename.s="_stage_split_2.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_2.col" : Gosub LoadColormap
xsize=6
ysize=4
xdest=29
ydest=6
yoffset=0
xoffset=29
rtsflag=#True
yadd=ysize
Gosub CreateAnim

;Lautsprecher links 04a,04b,04c,04d
;dest 12,6
Filename.s="_stage_split_2.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_2.col" : Gosub LoadColormap
xsize=4
ysize=4
xdest=12
ydest=6
yoffset=0
xoffset=12
rtsflag=#True
yadd=ysize
Gosub CreateAnim

;Lautsprecher rechts 05a,05b,05c,05d
;dest 6,6
Filename.s="_stage_split_2.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_2.col" : Gosub LoadColormap
xsize=4
ysize=4
xdest=25
ydest=6
yoffset=0
xoffset=25
rtsflag=#True
yadd=ysize
Gosub CreateAnim

;Lautsprecher Flammen links 06a,06b,06c,06d
;dest 4,10
Filename.s="_stage_split_3.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_3.col" : Gosub LoadColormap
xsize=6
ysize=3
xdest=4
ydest=10
yoffset=0
xoffset=4
rtsflag=#False
linkanim=11
yadd=4                 ;frames are 3 chars high, anim frames have 4 chars offset
Gosub CreateAnim

;Lautsprecher Flammen rechts 07a,07b,07c,07d
;dest 31,10
Filename.s="_stage_split_3.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_3.col" : Gosub LoadColormap
xsize=5
ysize=3
xdest=31
ydest=10
yoffset=0
xoffset=31
rtsflag=#True
yadd=4
Gosub CreateAnim

;Lautsprecher links unten 08a,08b,08c,08d
;dest 10,10
Filename.s="_stage_split_3.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_3.col" : Gosub LoadColormap
xsize=5
ysize=4
xdest=10
ydest=10
yoffset=0
xoffset=10
rtsflag=#True
yadd=ysize
Gosub CreateAnim

;Lautsprecher rechts unten 09a,09b,09c,09d
;dest 26,10
Filename.s="_stage_split_3.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_3.col" : Gosub LoadColormap
xsize=5
ysize=4
xdest=26
ydest=10
yoffset=0
xoffset=26
rtsflag=#True
yadd=ysize
Gosub CreateAnim

;Hunter Fackel oben 10a,10b,10c,10d
;dest 16,8
Filename.s="_stage_split_2.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_2.col" : Gosub LoadColormap
xsize=2
ysize=2
xdest=16
ydest=8
yoffset=2
xoffset=16
rtsflag=#True
yadd=ysize+2
Gosub CreateAnim

;Hunter Fackel unten 11a,11b,11c,11d
;dest 15,10
Filename.s="_stage_split_3.scr" : Gosub LoadScreenmap
Filename.s="_stage_split_3.col" : Gosub LoadColormap
xsize=3
ysize=4
xdest=15
ydest=10
yoffset=0
xoffset=15
rtsflag=#True
yadd=ysize
Gosub CreateAnim

;******************************************************************************
;- saved code
;******************************************************************************
SaveSource:

If CreateFile(0, "animcode.asm")
  
  WriteString(0, Source.s, #PB_Ascii)
  
  CloseFile(0)
Else
  MessageRequester("Error!", "Couldn't write file!")
  End 1
EndIf

End

;******************************************************************************
;- generate animcode
;******************************************************************************
; setrowlabel(9999)
; ldxim (0)
; ldaim (128)
; ldyim (255)
; stascx (1024)
; stacox (999)
; setlabel ("sucks")
; rts()
;todo:
;done - optimize $00 To sta, normal writes With x, And use inx

CreateAnim:

For t = 0 To LastFrame
  Anim.s=""
  
  For i = 0 To #MaxWrites
    WritesList(i)\Adress.i=0
    WritesList(i)\Value.i=0
  Next i
  
  setrowlabel(AnimCount.i,t)
  WritesCount.i=0
  
  ;collect and sort all writes
  
  For y = 0 To ysize-1
    For x = 0 To xsize-1
      
      Same.i=#True
      ScreenValue.a = PeekA(*screenmap+#FileOffset+(yoffset+y+yadd*t)*#LineOffset+xoffset+x)
      
      ;Debug "x: " + Str(x) + " y: " + Str(x) + " Val: " + Str(ScreenValue.a) + " Adress: " + Str(#FileOffset+(yoffset+y+yadd*t)*#LineOffset+xoffset+x)
      
      For i = 0 To LastFrame
        
        If ScreenValue.a <> PeekA(*screenmap+#FileOffset+(yoffset+y+yadd*i)*#LineOffset+xoffset+x)
          Same.i=#False
        EndIf
        
      Next i      
      
      If Same.i=#False
        WritesList(WritesCount.i)\Adress.i=(y+ydest)*#LineOffset+x+xdest
        WritesList(WritesCount.i)\Value.i=ScreenValue.a
        WritesCount.i=WritesCount.i+1
      EndIf
      
      ;-------------------------------
      
      Same.i=#True
      ColorValue.a = PeekA(*colormap+#FileOffset+(yoffset+y+yadd*t)*#LineOffset+xoffset+x)
      
      For i = 0 To LastFrame
        
        If ColorValue.a <> PeekA(*colormap+#FileOffset+(yoffset+y+yadd*i)*#LineOffset+xoffset+x)
          Same.i=#False
        EndIf
        
      Next i      
      
      If ScreenValue.a = 0    ;no need to update colorram if an empty char is displayed
        Same.i=#True
      EndIf
      
      If Same.i=#False
        WritesList(WritesCount.i)\Adress.i=(y+ydest)*#LineOffset+x+xdest+1000
        WritesList(WritesCount.i)\Value.i=ColorValue.a
        WritesCount.i=WritesCount.i+1
      EndIf
      
    Next x
  Next y
  Debug "WritesCount: " + Str(WritesCount.i)
  
  WritesCount.i=WritesCount.i-1     ;set to last element in list
   
  ; sorting
  MySortArray(@WritesList(0), SizeOf(Writes), Flds(), Opts(), Typs(), 0, WritesCount.i)
  
  ;SortStructuredArray(WritesList(),#PB_Sort_Ascending,OffsetOf(Writes\Value.i),TypeOf(Writes\Value.i),0,#MaxWrites)
  ;SortStructuredArray(WritesList(),#PB_Sort_Ascending,OffsetOf(Writes\Adress.i),TypeOf(Writes\Adress.i),0,#MaxWrites)
  
  LastValue.i=1   ;ldx #$01
  
  For i = 0 To WritesCount.i
    If WritesList(i)\Value.i & %11111110 <> LastValue.i &%11111110  ;if value hasn't changed, the load can be left out
      ldx(WritesList(i)\Value.i | %1)
      LastValue.i=WritesList(i)\Value.i | %1
    EndIf
    
    If WritesList(i)\Value.i % 2 = 0
      sax(WritesList(i)\Adress.i)
    Else
      stx(WritesList(i)\Adress.i)
    EndIf
    
  Next i
  
  If rtsflag = #True
    rts()
  Else
    link(linkanim.i,t)
  EndIf
  
  Source.S=Source.S + Anim.s
  
Next t

AnimCount=AnimCount+1
FreeMemory(*screenmap)
FreeMemory(*colormap)
Return
;******************************************************************************
;- Load Screenmap
;******************************************************************************
LoadScreenmap:
i = 0
If ReadFile(0, Filename.s)
  t = Lof(0)
  Debug "FileLength: " + Str(t)
  
  *screenmap = AllocateMemory(t)
  
  If *screenmap = 0
    MessageRequester("Error!", "Couldn't allocate workspace!", 0)
    End 1
  EndIf
  t = ReadData(0,*screenmap,t)
  CloseFile(0)
Else
  MessageRequester("Error!","Couldn't open file!")
  End 1
EndIf
Return
;******************************************************************************
;- Load Colormap
;******************************************************************************
LoadColormap:
i = 0
If ReadFile(0, Filename.s)
  t = Lof(0)
  Debug "FileLength: " + Str(t)
  
  *colormap = AllocateMemory(t)
  
  If *colormap = 0
    MessageRequester("Error!", "Couldn't allocate workspace!", 0)
    End 1
  EndIf
  t = ReadData(0,*colormap,t)
  CloseFile(0)
Else
  MessageRequester("Error!","Couldn't open file!")
  End 1
EndIf
Return
; IDE Options = PureBasic 6.02 LTS (Windows - x64)
; ExecutableFormat = Console
; CursorPosition = 197
; FirstLine = 191
; Folding = --
; Markers = 432
; EnableXP
; Executable = codegen.exe
; Watchlist = h;t