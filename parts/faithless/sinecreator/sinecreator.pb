EnableExplicit

;#MinValue = 0
;#MaxValue = 1200-336
#Offset = 256+16

#MinValue = 0
#MaxValue = 1200-336


#Count = 256

#ImageX = 2560
#ImageY = 1440

;******************************************************************************
Define.f x = 0
Define.f y = 0

Define.i xs = 0
Define.i xs2 = 0
Define.i ys = 0
Define.i i = 0

Define.i Event
Define.i z

Define Posxlo.i
Define Posxhi.i
Define Posylo.i
Define Posyhi.i
Define Posmix.i

Define.s Table
Define.s sinesprlo
Define.s sinesprhi
Define.s sinescrlo
Define.s sinescrhi
Define.s sinesprhiscrlo

sinesprlo.s = #TAB$ + #TAB$ + #TAB$ + "align 256,0" + #CRLF$ + "sinesprlo" + #CRLF$
sinesprhi.s = #TAB$ + #TAB$ + #TAB$ + "align 256,0" + #CRLF$ + "sinesprhi" + #CRLF$

sinescrlo.s =  #TAB$ + #TAB$ + #TAB$ + "align 256,0" + #CRLF$ + "sinescrlo" + #CRLF$
sinescrhi.s =  #TAB$ + #TAB$ + #TAB$ + "align 256,0" + #CRLF$ + "sinescrhi" + #CRLF$

;sprhi << 3 or scrlo
sinesprhiscrlo.s =  #TAB$ + #TAB$ + #TAB$ + "align 256,0" + #CRLF$ + "sinesprhiscrlo" + #CRLF$


Posxlo.i=0
Posxhi.i=0
Posylo.i=0
Posyhi.i=0
Posmix.i=0

If OpenWindow(0, 0, 0, #ImageX, #ImageY, "2D Drawing Test")
  
  If CreateImage(0, #ImageX, #ImageY)
    If StartDrawing(ImageOutput(0))
      For i = 0 To #Count-1
        
        x = Cos(Radian(i*(#Count-1)/180)) * ((#MaxValue-#Offset)-(#MinValue+#Offset)-1) / 2  + ((#MaxValue-#Offset)-(#MinValue+#Offset)-1) / 2    
        
;        x = i * (#MaxValue-#MinValue+1)/#Count
        
        ys = i
        xs = x + #Offset-120
        
        xs2 = xs + 7  ;fix difference between sprites for 38 column screen mode
        
        If xs2 < 0
          xs2 = 0
        EndIf
        
        If xs2 > #MaxValue
          xs2 = #MaxValue
        EndIf
        
        
        Debug xs
        
        If ys < 0
          ys = 0
        EndIf
        
        If ys > #ImageX-1
          ys = #ImageX-1
        EndIf
        
        Plot(xs+ #Imagex/2,(ys))
        
        ;-------        
        If Posxlo.i = 0
          sinesprlo.s = sinesprlo.s + " hex "
        EndIf
        
        sinesprlo.s = sinesprlo.s + RSet(Hex((48-(xs % 48)) & 255), 2, "0")
        
        Posxlo.i = Posxlo.i + 1
        
        If Posxlo.i = 8 Or Posxlo.i = 16 Or Posxlo.i = 24 Or Posxlo.i = 32 Or Posxlo.i = 40 Or Posxlo.i = 48 Or Posxlo.i = 56
          sinesprlo.s = sinesprlo.s + " "
        EndIf
        
        If Posxlo.i = 64
          Posxlo.i = 0
          sinesprlo.s = sinesprlo.s + #CRLF$
        EndIf
        
        ;        sinesprhi.s=AppendHex(sinesprhi.s,Posxhi.i, xs>>8)
        ;-------        
        If Posxhi.i = 0
          sinesprhi.s = sinesprhi.s + " hex "
        EndIf
        
        sinesprhi.s = sinesprhi.s + RSet(Hex(xs/48), 2, "0")
        
        Posxhi.i = Posxhi.i + 1
        
        If Posxhi.i = 8 Or Posxhi.i = 16 Or Posxhi.i = 24 Or Posxhi.i = 32 Or Posxhi.i = 40 Or Posxhi.i = 48 Or Posxhi.i = 56
          sinesprhi.s = sinesprhi.s + " "
        EndIf
        
        If Posxhi.i = 64
          Posxhi.i = 0
          sinesprhi.s = sinesprhi.s + #CRLF$
        EndIf
        ;-------        
        If Posylo.i = 0
          sinescrlo.s = sinescrlo.s + " hex "
        EndIf
        
        sinescrlo.s = sinescrlo.s + RSet(Hex(7-(xs2 & 7)), 2, "0")
        
        Posylo.i = Posylo.i + 1
        
        If Posylo.i = 8 Or Posylo.i = 16 Or Posylo.i = 24 Or Posylo.i = 32 Or Posylo.i = 40 Or Posylo.i = 48 Or Posylo.i = 56
          sinescrlo.s = sinescrlo.s + " "
        EndIf
        
        If Posylo.i = 64
          Posylo.i = 0
          sinescrlo.s = sinescrlo.s + #CRLF$
        EndIf
        
        ;-------        
        If Posyhi.i = 0
          sinescrhi.s = sinescrhi.s + " hex "
        EndIf
        
        sinescrhi.s = sinescrhi.s + RSet(Hex(xs2>>3), 2, "0")
        
        Posyhi.i = Posyhi.i + 1
        
        If Posyhi.i = 8 Or Posyhi.i = 16 Or Posyhi.i = 24 Or Posyhi.i = 32 Or Posyhi.i = 40 Or Posyhi.i = 48 Or Posyhi.i = 56
          sinescrhi.s = sinescrhi.s + " "
        EndIf
        
        If Posyhi.i = 64
          Posyhi.i = 0
          sinescrhi.s = sinescrhi.s + #CRLF$
        EndIf
        
        ;-------        
        If Posmix.i = 0
          sinesprhiscrlo.s = sinesprhiscrlo.s + " hex "
        EndIf
        
        sinesprhiscrlo.s = sinesprhiscrlo.s + RSet(Hex((xs/48)<<3 | (7-(xs2 & 7))), 2, "0")
        
        Posmix.i = Posmix.i + 1
        
        If Posmix.i = 8 Or Posmix.i = 16 Or Posmix.i = 24 Or Posmix.i = 32 Or Posmix.i = 40 Or Posmix.i = 48 Or Posmix.i = 56
          sinesprhiscrlo.s = sinesprhiscrlo.s + " "
        EndIf
        
        If Posmix.i = 64
          Posmix.i = 0
          sinesprhiscrlo.s = sinesprhiscrlo.s + #CRLF$
        EndIf
                
      Next i
      ImageGadget(0, 0, 0, 0, 0, ImageID(0))
      StopDrawing()
    EndIf
    
  EndIf
  
  ImageGadget(0, 0, 0, 0, 0, ImageID(0))
  
  Repeat
    Event = WaitWindowEvent()
  Until Event = #PB_Event_CloseWindow  ; If the user has pressed on the window close button
  
EndIf


;add endflag
;sinesprhi.s = sinesprhi.s + #CRLF$ + " hex FF"

Table.s = sinesprlo.s + #CRLF$ + #CRLF$ + sinescrhi.s + #CRLF$ + #CRLF$ + sinesprhiscrlo.s + #CRLF$
;Table.s = sinesprlo.s + #CRLF$ + #CRLF$  + sinesprhi.s + #CRLF$ + #CRLF$ + sinescrlo.s + #CRLF$ + #CRLF$ + sinescrhi.s + #CRLF$ + #CRLF$ + sinesprhiscrlo.s + #CRLF$


If OpenWindow(0, 0, 0, 1920, 1080, "TextGadget", #PB_Window_SystemMenu | #PB_Window_ScreenCentered|#PB_Window_SizeGadget) ;And CreateGadgetList(WindowID(0))
  EditorGadget(0, 8, 8, 1904, 1064,#PB_Editor_ReadOnly)
  
  If LoadFont(1,"Courier",10)
    SetGadgetFont(0, FontID(1))   ; geladenen Courier 10 Zeichensatz als neuen Standard festlegen
  EndIf
  SetGadgetColor(0, #PB_Gadget_BackColor, $FFFFFF)
  SetGadgetText(0, Table.s)
  Repeat : Until WaitWindowEvent() = #PB_Event_CloseWindow
EndIf

End   ; All the opened windows are closed automatically by PureBasic

; IDE Options = PureBasic 6.01 LTS (Windows - x64)
; CursorPosition = 67
; FirstLine = 64
; EnableXP