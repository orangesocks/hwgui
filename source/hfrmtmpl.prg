/*
 * $Id: hfrmtmpl.prg,v 1.11 2004-06-18 14:39:13 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HFormTmpl Class
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "HBClass.ch"
#include "guilib.ch"
#include "hxml.ch"

REQUEST HSTATIC
REQUEST HBUTTON
REQUEST HCHECKBUTTON
REQUEST HRADIOBUTTON
REQUEST HEDIT
REQUEST HGROUP
REQUEST HSAYBMP
REQUEST HSAYICON
REQUEST HRICHEDIT
REQUEST HDATEPICKER
REQUEST HUPDOWN
REQUEST HCOMBOBOX
REQUEST HLINE
REQUEST HPANEL
REQUEST HOWNBUTTON
REQUEST HBROWSE
REQUEST HMONTHCALENDAR
REQUEST HTRACKBAR
REQUEST HTAB

CLASS HCtrlTmpl

   DATA cClass
   DATA aControls INIT {}
   DATA aProp, aMethods

   METHOD New( oParent )   INLINE ( Aadd( oParent:aControls,Self ), Self )
ENDCLASS

CLASS HFormTmpl

   CLASS VAR aForms   INIT {}
   CLASS VAR maxId    INIT 0
   DATA oDlg
   DATA aControls     INIT {}
   DATA aProp
   DATA aMethods
   DATA aVars         INIT {}
   DATA aNames        INIT {}
   DATA aFuncs
   DATA id


   METHOD Read( fname )
   METHOD Show()
   METHOD Close()
   METHOD F( id )

ENDCLASS

METHOD Read( fname ) CLASS HFormTmpl
Local oDoc
Local i, j, aItems, o, aProp := {}, aMethods := {}

   IF Left( fname,5 ) == "<?xml"
      oDoc := HXMLDoc():ReadString( fname )
   ELSE
      oDoc := HXMLDoc():Read( fname )
   ENDIF

   IF Empty( oDoc:aItems )
      MsgStop( "Can't open "+fname )
      Return Nil
   ELSEIF oDoc:aItems[1]:title != "part" .OR. oDoc:aItems[1]:GetAttribute( "class" ) != "form"
      MsgStop( "Form description isn't found" )
      Return Nil
   ENDIF

   ::maxId ++
   ::id := ::maxId
   ::aProp := aProp
   ::aMethods := aMethods

   Aadd( ::aForms, Self )
   aItems := oDoc:aItems[1]:aItems
   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               IF !Empty( o:aItems )
                  Aadd( aProp, { Lower(o:GetAttribute("name")),o:aItems[1] } )
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         Aadd( aMethods, { Lower(aItems[i]:GetAttribute("name")),CompileMethod(aItems[i]:aItems[1]:aItems[1],Self) } )
      ELSEIF aItems[i]:title == "part"
         ReadCtrl( aItems[i],Self,Self )
      ENDIF
   NEXT

Return Self

METHOD Show( nMode ) CLASS HFormTmpl
Local i, j, cType
Local nLeft, nTop, nWidth, nHeight, cTitle, oFont, lClipper := .F., lExitOnEnter := .F., xProperty, block, bFormExit
Memvar oDlg
Private oDlg

   FOR i := 1 TO Len( ::aProp )
      xProperty := GetProperty( ::aProp[ i,2 ] )
      IF ::aProp[ i,1 ] == "geometry"
         nLeft   := Val(xProperty[1])
         nTop    := Val(xProperty[2])
         nWidth  := Val(xProperty[3])
         nHeight := Val(xProperty[4])
      ELSEIF ::aProp[ i,1 ] == "caption"
         cTitle := xProperty
      ELSEIF ::aProp[ i,1 ] == "font"
         oFont := FontFromXML( xProperty )
      ELSEIF ::aProp[ i,1 ] == "lclipper"
         lClipper := xProperty
      ELSEIF ::aProp[ i,1 ] == "lexitonenter"
         lExitOnEnter := xProperty
      ELSEIF ::aProp[ i,1 ] == "variables"
         FOR j := 1 TO Len( xProperty )
            __mvPrivate( xProperty[j] )
         NEXT
      ENDIF
   NEXT
   FOR i := 1 TO Len( ::aNames )
      __mvPrivate( ::aNames[i] )
   NEXT
   FOR i := 1 TO Len( ::aVars )
      __mvPrivate( ::aVars[i] )
   NEXT

   IF nMode == Nil .OR. nMode == 2
      INIT DIALOG ::oDlg TITLE cTitle         ;
          AT nLeft, nTop SIZE nWidth, nHeight ;
          STYLE DS_ABSALIGN+WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_SIZEBOX ;
          FONT oFont
      ::oDlg:lClipper := lClipper
      ::oDlg:lExitOnEnter := lExitOnEnter
      ::oDlg:oParent  := Self
   ELSEIF nMode == 1
      INIT WINDOW ::oDlg MAIN TITLE cTitle    ;
          AT nLeft, nTop SIZE nWidth, nHeight ;
          FONT oFont
   ENDIF

   oDlg := ::oDlg

   FOR i := 1 TO Len( ::aMethods )
      IF ( cType := Valtype( ::aMethods[ i,2 ] ) ) == "B"
         block := ::aMethods[ i,2 ]
      ELSEIF cType == "A"
         block := ::aMethods[ i,2,1 ]
      ENDIF
      IF ::aMethods[ i,1 ] == "ondlginit"
         ::oDlg:bInit := block
      ELSEIF ::aMethods[ i,1 ] == "onforminit"
         Eval( block,Self )
      ELSEIF ::aMethods[ i,1 ] == "onpaint"
         ::oDlg:bPaint := block
      ELSEIF ::aMethods[ i,1 ] == "ondlgexit"
         ::oDlg:bDestroy := block
      ELSEIF ::aMethods[ i,1 ] == "onformexit"
         bFormExit := block
      ELSEIF ::aMethods[ i,1 ] == "common"
         ::aFuncs := ::aMethods[ i,2,2 ]
      ENDIF
   NEXT

   FOR i := 1 TO Len( ::aControls )
      CreateCtrl( ::oDlg, ::aControls[i], Self )
   NEXT

   ::oDlg:Activate()

   IF bFormExit != Nil
      Eval( bFormExit )
   ENDIF

Return Nil

METHOD F( id ) CLASS HFormTmpl
Local i := Ascan( ::aForms, {|o|o:id==id} )
Return Iif( i==0, Nil, ::aForms[i] )

METHOD Close() CLASS HFormTmpl
Local i := Ascan( ::aForms, {|o|o:id==::id} )

   IF i != 0
      Adel( ::aForms,i )
      Asize( ::aForms, Len( ::aForms ) - 1 )
   ENDIF
Return Nil

// ------------------------------

Static Function CompileMethod( cMethod, oForm, oCtrl )
Local nPos1, nPos2, nLines := 1, arr[3], arrExe

   IF cMethod = Nil .OR. Empty( cMethod )
      Return Nil
   ENDIF
   IF ( nPos1 := At( Chr(10),cMethod ) ) == 0
      arr[1] := Alltrim( cMethod )
   ELSE
      arr[1] := Alltrim( Left( cMethod,nPos1-1 ) )
      DO WHILE .T.
         nLines ++
         IF ( nPos2 := At( Chr(10),cMethod,nPos1+1 ) ) == 0
            arr[nLines] := Substr( cMethod,nPos1+1 )
         ELSE
            arr[nLines] := Substr( cMethod,nPos1+1,nPos2-nPos1-1 )
         ENDIF
         IF Empty( arr[nLines] )
            nLines --
         ENDIF
         IF nPos2 == 0 .OR. nLines > 2
            EXIT
         ELSE
            nPos1 := nPos2
         ENDIF
      ENDDO
   ENDIF
   IF Right( arr[1],1 ) < " "
      arr[1] := Left( arr[1],Len(arr[1])-1 )
   ENDIF
   IF nLines == 1
      Return &( "{||" + arr[1] + "}" )
   ELSEIF Lower( Left( arr[1],11 ) ) == "parameters "
      IF nLines == 2
         IF Right( arr[2],1 ) < " "
            arr[2] := Left( arr[2],Len(arr[2])-1 )
         ENDIF
         Return &( "{|" + Ltrim( Substr( arr[1],12 ) ) + "|" + arr[2] + "}" )
      ELSE
         arrExe := Array(2)
         arrExe[1] := RdScript( ,cMethod,1 )
         arrExe[2] := Ltrim( Substr( arr[1],12 ) )
         Return arrExe
      ENDIF
   ENDIF

   arrExe := Array(2)
   arrExe[2] := RdScript( ,cMethod )
   arrExe[1] := &( "{||DoScript(HFormTmpl():F("+Ltrim(Str(oForm:id))+"):" + ;
      Iif( oCtrl==Nil,"aMethods["+Ltrim(Str(Len(oForm:aMethods)+1))+",2,2])", ;
           "aControls["+Ltrim(Str(Len(oForm:aControls)))+"]:aMethods["+   ;
             Ltrim(Str(Len(oCtrl:aMethods)+1))+",2,2])" ) + "}" )

Return arrExe

Static Function ReadCtrl( oCtrlDesc, oContainer, oForm )
Local oCtrl := HCtrlTmpl():New( oContainer )
Local i, j, o, cName, aProp := {}, aMethods := {}, aItems := oCtrlDesc:aItems

   oCtrl:cClass := oCtrlDesc:GetAttribute( "class" )
   oCtrl:aProp := aProp
   oCtrl:aMethods := aMethods

   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               IF ( cName := Lower( o:GetAttribute("name") ) ) == "varname"
                  Aadd( oForm:aVars, GetProperty(o:aItems[1]) )
               ELSEIF cName == "name"
                  Aadd( oForm:aNames, GetProperty(o:aItems[1]) )
               ENDIF
               Aadd( aProp, { cName,Iif( Empty(o:aItems),"",o:aItems[1] ) } )
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         Aadd( aMethods, { Lower(aItems[i]:GetAttribute("name")),CompileMethod(aItems[i]:aItems[1]:aItems[1],oForm,oCtrl) } )
      ELSEIF aItems[i]:title == "part"
         ReadCtrl( aItems[i],oCtrl,oForm )
      ENDIF
   NEXT

Return Nil

#define TBS_AUTOTICKS                1
#define TBS_TOP                      4
#define TBS_BOTH                     8
#define TBS_NOTICKS                 16

Static Function CreateCtrl( oParent, oCtrlTmpl, oForm )
Local aClass := { "label", "button", "checkbox",                    ;
                  "radiobutton", "editbox", "group", "radiogroup",  ;
                  "bitmap","icon",                                  ;
                  "richedit","datepicker", "updown", "combobox",    ;
                  "line", "toolbar", "ownerbutton","browse",        ;
                  "monthcalendar","trackbar","page" ;
                }
Local aCtrls := { ;
  "HStatic():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,ctoolt,TextColor,BackColor,lTransp)", ;
  "HButton():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctoolt,TextColor,BackColor)",  ;
  "HCheckButton():New(oPrnt,nId,lInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctoolt,TextColor,BackColor,bwhen)", ;
  "HRadioButton():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctoolt,TextColor,BackColor)", ;
  "HEdit():New(oPrnt,nId,cInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onGetFocus,onLostFocus,ctoolt,TextColor,BackColor,cPicture,lNoBorder)", ;
  "HGroup():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor)", ;
  "RadioNew(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor,nInitValue,bSetGet)", ;
  "HSayBmp():New(oPrnt,nId,nLeft,nTop,nWidth,nHeight,Bitmap,lResource,onInit,onSize,ctoolt)", ;
  "HSayIcon():New(oPrnt,nId,nLeft,nTop,nWidth,nHeight,Icon,lResource,onInit,onSize,ctoolt)", ;
  "HRichEdit():New(oPrnt,nId,cInitValue,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onGetFocus,onLostFocus,ctoolt,TextColor,BackColor)", ;
  "HDatePicker():New(oPrnt,nId,dInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onGetFocus,onLostFocus,onChange,ctoolt,TextColor,BackColor)", ;
  "HUpDown():New(oPrnt,nId,nInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onGetFocus,onLostFocus,ctoolt,TextColor,BackColor,nUpDWidth,nLower,nUpper)", ;
  "HComboBox():New(oPrnt,nId,nInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,Items,oFont,onInit,onSize,onPaint,onChange,cToolt,lEdit,lText,bWhen)", ;
  "HLine():New(oPrnt,nId,lVertical,nLeft,nTop,nLength,onSize)", ;
  "HPanel():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,onInit,onSize,onPaint,lDocked )", ;
  "HOwnButton():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,onInit,onSize,onPaint,onClick,flat,caption,TextColor,oFont,TextLeft,TextTop,widtht,heightt,BtnBitmap,lResource,BmpLeft,BmpTop,widthb,heightb,lTr,cTooltip)", ;
  "Hbrowse():New(BrwType,oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onEnter,onGetfocus,onLostfocus,lNoVScroll,lNoBorder,lAppend,lAutoedit,bUpdate,onKeyDown,onPosChg )", ;
  "HMonthCalendar():New(oPrnt,nId,dInitValue,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onChange,cToolt,lNoToday,lNoTodayCircle,lWeekNumbers)", ;
  "HTrackBar():New(oPrnt,nId,nInitValue,nStyle,nLeft,nTop,nWidth,nHeight,onInit,cToolt,onChange,nLower,nUpper,lVertical,TickStyle,TickMarks )", ;
  "HTab():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,Tabs,onChange,aImages,lResource)" ;
                }
Local i, j, oCtrl, stroka, varname, xProperty, block, cType, cPName
Local nCtrl := Ascan( aClass, oCtrlTmpl:cClass ), xInitValue, cInitName
MEMVAR oPrnt, nStyle, nLeft, nTop, nWidth, nHeight, oFont, lNoBorder, bSetGet
MEMVAR name, nMaxLines, nLength, lVertical, brwType, TickStyle, TickMarks, Tabs

   IF nCtrl == 0
      IF Lower( oCtrlTmpl:cClass ) == "pagesheet"
         oParent:StartPage()
         FOR i := 1 TO Len( oCtrlTmpl:aControls )
            CreateCtrl( oParent, oCtrlTmpl:aControls[i], oForm )
         NEXT
         oParent:EndPage()
      ENDIF
      Return Nil
   ENDIF

   /* Declaring of variables, which are in the appropriate 'New()' function */
   i := At( "New(", aCtrls[nCtrl] )
   stroka := Substr( aCtrls[nCtrl],i+4 )
   stroka := Left( stroka,Len(stroka)-1 )
   DO WHILE !Empty( varName := getNextVar( @stroka ) )
      __mvPrivate( varname )
      IF Substr( varname, 2 ) == "InitValue"
         cInitName  := varname
      ENDIF
   ENDDO
   oPrnt := oParent
   nStyle := 0

   FOR i := 1 TO Len( oCtrlTmpl:aProp )
      xProperty := GetProperty( oCtrlTmpl:aProp[ i,2 ] )
      cPName := oCtrlTmpl:aProp[ i,1 ]
      IF cPName == "geometry"
         nLeft   := Val(xProperty[1])
         nTop    := Val(xProperty[2])
         nWidth  := Val(xProperty[3])
         nHeight := Val(xProperty[4])
         IF __ObjHasMsg( oParent,"ID")
            nLeft -= oParent:nLeft
            nTop -= oParent:nTop
            IF __ObjHasMsg( oParent:oParent,"ID")
               nLeft -= oParent:oParent:nLeft
               nTop -= oParent:oParent:nTop
            ENDIF
         ENDIF
      ELSEIF cPName == "font"
         oFont := FontFromXML( xProperty )
      ELSEIF cPName == "border"
         IF xProperty
            nStyle += WS_BORDER
         ELSE
            lNoBorder := .T.
         ENDIF
      ELSEIF cPName == "justify"
         nStyle += Iif( xProperty=="Center",SS_CENTER,Iif( xProperty=="Right",SS_RIGHT,0 ) )
      ELSEIF cPName == "multiline"
         IF xProperty
            nStyle += ES_MULTILINE
         ENDIF
      ELSEIF cPName == "password"
         IF xProperty
            nStyle += ES_PASSWORD
         ENDIF
      ELSE
         /* Assigning the value of the property to the variable with 
            the same name as the property */
         __mvPut( cPName, xProperty )

         IF cPName == "varname"
            bSetGet := &( "{|v|Iif(v==Nil,"+xProperty+","+xProperty+":=v)}" )
            IF __mvGet( xProperty ) == Nil
               /* If the variable with 'varname' name isn't initialized
                  while onFormInit procedure, we assign her the init value */
               __mvPut( xProperty, xInitValue )
            ELSEIF cInitName != Nil
               /* If it is initialized, we assign her value to the 'init' 
                  variable ( cInitValue, nInitValue, ... ) */
               __mvPut( cInitName, __mvGet( xProperty ) )
            ENDIF
         ELSEIF Substr( cPName, 2 ) == "initvalue"
            xInitValue := xProperty
         ENDIF
      ENDIF
   NEXT
   FOR i := 1 TO Len( oCtrlTmpl:aMethods )
      IF ( cType := Valtype( oCtrlTmpl:aMethods[ i,2 ] ) ) == "B"
         __mvPut( oCtrlTmpl:aMethods[ i,1 ], oCtrlTmpl:aMethods[ i,2 ] )
      ELSEIF cType == "A"
         __mvPut( oCtrlTmpl:aMethods[ i,1 ], oCtrlTmpl:aMethods[ i,2,1 ] )
      ENDIF
   NEXT

   IF oCtrlTmpl:cClass == "combobox"
      IF ( i := Ascan( oCtrlTmpl:aProp,{|a|Lower(a[1])=="nmaxlines"} ) ) > 0
         nHeight := nHeight * nMaxLines
      ELSE
         nHeight := nHeight * 4
      ENDIF
   ELSEIF oCtrlTmpl:cClass == "line"
      nLength := Iif( lVertical==Nil.OR.!lVertical, nWidth, nHeight )
   ELSEIF oCtrlTmpl:cClass == "browse"
      brwType := Iif( brwType == "Dbf",BRW_DATABASE,BRW_ARRAY )
   ELSEIF oCtrlTmpl:cClass == "trackbar"
      IF TickStyle == Nil .OR. TickStyle == "Auto"
         TickStyle := TBS_AUTOTICKS
      ELSEIF TickStyle == "None"
         TickStyle := TBS_NOTICKS
      ELSE
         TickStyle := 0
      ENDIF
      IF TickMarks == Nil .OR. TickMarks == "Bottom"
         TickMarks := 0
      ELSEIF TickMarks == "Both"
         TickMarks := TBS_BOTH
      ELSE
         TickMarks := TBS_TOP
      ENDIF
   ENDIF
   oCtrl := &( aCtrls[nCtrl] )
   IF Type( "m->name" ) == "C"
      __mvPut( name, oCtrl )
   ENDIF
   IF !Empty( oCtrlTmpl:aControls )
      FOR i := 1 TO Len( oCtrlTmpl:aControls )
         CreateCtrl( Iif( oCtrlTmpl:cClass=="group".OR.oCtrlTmpl:cClass=="radiogroup",oParent,oCtrl ), oCtrlTmpl:aControls[i], oForm )
      NEXT
      IF oCtrlTmpl:cClass=="radiogroup"
         HRadioGroup():EndGroup()
      ENDIF
   ENDIF

Return Nil

Function RadioNew( oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor,nInitValue,bSetGet )
Local oCtrl := HGroup():New( oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor )
   HRadioGroup():New( nInitValue,bSetGet )
Return oCtrl

Function FontFromXML( oXmlNode )
Local width  := oXmlNode:GetAttribute( "width" )
Local height := oXmlNode:GetAttribute( "height" )
Local weight := oXmlNode:GetAttribute( "weight" )
Local charset := oXmlNode:GetAttribute( "charset" )
Local ita   := oXmlNode:GetAttribute( "italic" )
Local under := oXmlNode:GetAttribute( "underline" )

  IF width != Nil
     width := Val( width )
  ENDIF
  IF height != Nil
     height := Val( height )
  ENDIF
  IF weight != Nil
     weight := Val( weight )
  ENDIF
  IF charset != Nil
     charset := Val( charset )
  ENDIF
  IF ita != Nil
     ita := Val( ita )
  ENDIF
  IF under != Nil
     under := Val( under )
  ENDIF

Return HFont():Add( oXmlNode:GetAttribute( "name" ),  ;
                    width, height, weight, charset,   ;
                    ita, under )

Function Font2XML( oFont )
Local aAttr := {}

   Aadd( aAttr, { "name",oFont:name } )
   Aadd( aAttr, { "width",Ltrim(Str(oFont:width,5)) } )
   Aadd( aAttr, { "height",Ltrim(Str(oFont:height,5)) } )
   IF oFont:weight != 0
      Aadd( aAttr, { "weight",Ltrim(Str(oFont:weight,5)) } )
   ENDIF
   IF oFont:charset != 0
      Aadd( aAttr, { "charset",Ltrim(Str(oFont:charset,5)) } )
   ENDIF
   IF oFont:Italic != 0
      Aadd( aAttr, { "italic",Ltrim(Str(oFont:Italic,5)) } )
   ENDIF
   IF oFont:Underline != 0
      Aadd( aAttr, { "underline",Ltrim(Str(oFont:Underline,5)) } )
   ENDIF

Return HXMLNode():New( "font", HBXML_TYPE_SINGLE, aAttr )

Function Str2Arr( stroka )
Local arr := {}, pos, cItem

   stroka := Substr( stroka,2,Len(stroka)-2 )
   IF !Empty( stroka )
      DO WHILE .T. 
         pos := Find_Z( stroka )
         Aadd( arr, cItem := Iif( pos > 0, Left( stroka,pos-1 ), stroka ) )
         IF pos > 0
            stroka := Substr( stroka,pos+1 )
         ELSE
            EXIT
         ENDIF
      ENDDO
   ENDIF

Return arr

Function Arr2Str( arr )
Local stroka := "{", i, cType

   FOR i := 1 TO Len( arr )
      IF i > 1
         stroka += ","
      ENDIF
      cType := Valtype( arr[i] )
      IF cType == "C"
         stroka += arr[i]
      ELSEIF cType == "N"
         stroka += Ltrim( Str( arr[i] ) )
      ENDIF
   NEXT

Return stroka + "}"

Function GetProperty( xProp )
Local c

   IF Valtype( xProp ) == "C"
      c := Left( xProp,1 )
      IF c == "["
         xProp := Substr( xProp,2,Len(xProp)-2 )
      ELSEIF c == "."
         xProp := ( Substr( xProp,2,1 ) == "T" )
      ELSEIF c == "{"
         xProp := Str2Arr( xProp )
      ELSE
         xProp := Val( xProp )
      ENDIF
   ENDIF

Return xProp
