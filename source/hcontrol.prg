/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HControl, HStatus, HStatic, HButton, HGroup, HLine classes
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  CONTROL_FIRST_ID   34000
#define TRANSPARENT 1

//- HControl

CLASS HControl INHERIT HCustomWindow

   DATA   id
   DATA   tooltip
   DATA   lInit           INIT .F.
   DATA   lnoValid        INIT .F.
   DATA   lnoWhen         INIT .F.
   DATA   nGetSkip        INIT 0
   DATA   Anchor          INIT 0
   DATA   BackStyle       INIT OPAQUE
   DATA   lNoThemes       INIT .F.
   DATA   DisablebColor
   DATA   DisableBrush
   DATA   xControlSource
   DATA   xName           HIDDEN
   ACCESS Name            INLINE ::xName
   ASSIGN Name( cName )   INLINE ::AddName( cName )

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   METHOD Init()
   METHOD AddName( cName ) HIDDEN
   // METHOD SetColor( tcolor, bColor, lRepaint )
   METHOD NewId()
   METHOD Show( nShow ) INLINE ::Super:Show( nShow ), IIF( ::oParent:lGetSkipLostFocus,;
         PostMessage(  GetActiveWindow() , WM_NEXTDLGCTL, IIF( ::oParent:FindControl(, GetFocus() ) != NIL, 0, ::handle ), 1 ) , .T. )
   METHOD Hide() INLINE ( ::oParent:lGetSkipLostFocus := .F., ::Super:Hide() )
   // METHOD Disable()     INLINE EnableWindow( ::handle, .F. )
   METHOD Disable() INLINE ( IIF( SELFFOCUS( ::Handle ), SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, 0, 0 ) , ), EnableWindow( ::handle, .F. ) )
   METHOD Enable()
   METHOD IsEnabled() INLINE IsWindowEnabled( ::Handle )
   METHOD Enabled( lEnabled ) SETGET
   METHOD SetFont( oFont )
   METHOD SetFocus( lValid )
   METHOD GetText()     INLINE GetWindowText( ::handle )
   METHOD SetText( c )  INLINE SetWindowText( ::Handle, c ), ::title := c, ::Refresh()
   METHOD Refresh()     VIRTUAL
   METHOD onAnchor( x, y, w, h )
   METHOD SetToolTip( ctooltip )
   METHOD ControlSource( cControlSource ) SETGET
   METHOD DisableBackColor( DisableBColor ) SETGET
   METHOD END()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HControl

   ::oParent := IIf( oWndParent == NIL, ::oDefaultParent, oWndParent )
   ::id      := IIf( nId == NIL, ::NewId(), nId )
   ::style   := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
         WS_VISIBLE + WS_CHILD )
   ::nLeft   := IIF( nLeft = NIL ,0, nLeft )
   ::nTop    := IIF( nTop = NIL ,0, nTop )
   ::nWidth  := IIF( nWidth = NIL ,0, nWidth )
   ::nHeight := IIF( nHeight = NIL ,0, nHeight )
   ::oFont   := oFont
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := cTooltip
   ::SetColor( tcolor, bColor )
   ::oParent:AddControl( Self )

   RETURN Self

METHOD NewId() CLASS HControl
   LOCAL oParent := ::oParent, i := 0, nId

   DO WHILE oParent != NIL
      nId := CONTROL_FIRST_ID + 1000 * i + Len( ::oParent:aControls )
      oParent := oParent:oParent
      i ++
   ENDDO
   IF AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
      nId --
      DO WHILE nId >= CONTROL_FIRST_ID .AND. ;
         AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
         nId --
      ENDDO
   ENDIF

   RETURN nId

METHOD AddName( cName ) CLASS HControl
   LOCAL nPos
   
   IF !EMPTY( cName ) .AND. VALTYPE( cName) == "C" .AND. ::oParent != Nil .AND. ! "[" $ cName
      IF ( nPos :=  RAt( ":", cName ) ) > 0 .OR. ( nPos :=  RAt( ">", cName ) ) > 0
         cName := SubStr( cName, nPos + 1 )
      ENDIF
      ::xName := cName
      __objAddData( ::oParent, cName )
      ::oParent: & ( cName ) := Self
   ENDIF

   RETURN NIL

METHOD INIT() CLASS HControl
   LOCAL oForm := hwg_GetParentForm( Self )

   IF ! ::lInit
      //IF ::tooltip != NIL
      //   AddToolTip( ::oParent:handle, ::handle, ::tooltip )
      //ENDIF
      ::oparent:lSuspendMsgsHandling := .T.
      IF Len( ::aControls) = 0 .AND. ::winclass != "SysTabControl32" .AND. VALTYPE( oForm ) != "N"
         AddToolTip( oForm:handle, ::handle, ::tooltip )
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
      IF ::oFont != NIL .AND. VALTYPE( ::oFont ) != "N" .AND. ::oParent != NIL
         SetCtrlFont( ::oParent:handle, ::id, ::oFont:handle )
      ELSEIF oForm != NIL  .AND. VALTYPE( oForm ) != "N" .AND. oForm:oFont != NIL
         SetCtrlFont( ::oParent:handle, ::id, oForm:oFont:handle )
      ELSEIF ::oParent != NIL .AND. ::oParent:oFont != NIL
         SetCtrlFont( ::handle, ::id, ::oParent:oFont:handle )
      ENDIF
      IF oForm != NIL .AND. oForm:Type != WND_DLG_RESOURCE  .AND. ( ::nLeft + ::nTop + ::nWidth + ::nHeight  != 0 )
         // fix init position in FORM reduce  flickering
         SetWindowPos( ::Handle, NIL, ::nLeft, ::nTop, ::nWidth, ::nHeight, SWP_NOACTIVATE + SWP_NOSIZE + SWP_NOZORDER + SWP_NOOWNERZORDER + SWP_NOSENDCHANGING ) //+ SWP_DRAWFRAME )
      ENDIF
      IF ISBLOCK( ::bInit )
        ::oparent:lSuspendMsgsHandling := .T.
        Eval( ::bInit, Self )
        ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
      IF ::lnoThemes
          HWG_SETWINDOWTHEME( ::handle, 0 )
      ENDIF
      ::lInit := .T.
   ENDIF

   RETURN NIL

/* moved to HCWINDOW
METHOD SetColor( tcolor, bColor, lRepaint ) CLASS HControl
   */

METHOD SetFocus( lValid ) CLASS HControl
   LOCAL lSuspend := ::oParent:lSuspendMsgsHandling

   IF ! IsWindowEnabled( ::Handle )
      ::oParent:lSuspendMsgsHandling  := .T.
      // GetSkip( ::oParent, ::handle, , 1 )
      SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, 0, 0 )
      ::oParent:lSuspendMsgsHandling  := lSuspend
   ELSE
      ::oParent:lSuspendMsgsHandling  := ! Empty( lValid )
      IF hwg_GetParentForm(Self):Type < WND_DLG_RESOURCE
         SetFocus( ::handle )
      ELSE
         SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, ::handle, 1 )
      ENDIF
      ::oParent:lSuspendMsgsHandling  := lSuspend
   ENDIF
   IF hwg_GetParentForm(Self):Type < WND_DLG_RESOURCE
      hwg_GetParentForm(Self):nFocus := ::Handle
   ENDIF

   RETURN NIL

METHOD Enable() CLASS HControl
   LOCAL lEnable := IsWindowEnabled( ::Handle ), nPos, nNext

   EnableWindow( ::handle, .T. )
   IF ::oParent:lGetSkipLostFocus .AND. ! lEnable .AND. Hwg_BitaND( HWG_GETWINDOWSTYLE( ::Handle ), WS_TABSTOP ) > 0
      nNext := Ascan( ::oParent:aControls, { | o | PtrtouLong( o:Handle ) = PtrtouLong( GetFocus() ) } )
      nPos  := Ascan( ::oParent:acontrols, { | o | PtrtouLong( o:Handle ) = PtrtouLong( ::handle ) } )
      IF nPos < nNext
         SendMessage(  GetActiveWindow() , WM_NEXTDLGCTL,::handle, 1)
      ENDIF
   ENDIF

   RETURN NIL

METHOD DisableBackColor( DisableBColor )

   IF DisableBColor != NIL
      ::DisableBColor := DisableBColor
      IF ::Disablebrush != NIL
         ::Disablebrush:Release()
      ENDIF
      ::Disablebrush := HBrush():Add( ::DisableBColor )
      IF ! ::IsEnabled() .AND. IsWindowVisible( ::Handle )
         InvalidateRect( ::Handle, 0 )
      ENDIF
   ENDIF

   RETURN ::DisableBColor

METHOD SetFont( oFont ) CLASS HControl

   IF oFont != NIL
      IF VALTYPE( oFont ) = "O"
         ::oFont := oFont:SetFontStyle()
         SetWindowFont( ::Handle, ::oFont:Handle, .T. )
      ENDIF
   ELSEIF ::oParent:oFont != NIL
      SetWindowFont( ::handle, ::oParent:oFont:handle, .T. )
   ENDIF

   RETURN ::oFont

METHOD SetToolTip ( cToolTip ) CLASS HControl

   IF VALTYPE( cToolTip ) = "C"  .AND. cToolTip != ::ToolTip
      SETTOOLTIPTITLE( hwg_GetparentForm(Self):handle, ::handle, ctooltip )
      ::Tooltip := cToolTip
   ENDIF

   RETURN ::tooltip

METHOD Enabled( lEnabled ) CLASS HControl

  IF lEnabled != NIL
     IF lEnabled
        ::enable()
     ELSE
        ::disable()
     ENDIF
  ENDIF

  RETURN ::isEnabled()

METHOD ControlSource( cControlSource ) CLASS HControl
  LOCAL temp

  IF cControlSource != NIL .AND. !EMPTY( cControlSource ) .AND. __objHasData( Self, "BSETGETFIELD")
     ::xControlSource := cControlSource
     temp := SUBSTR( cControlSource, AT( "->", cControlSource ) + 2 )
     ::bSetGetField := IIF( "->" $ cControlSource, FieldWBlock( temp, SELECT( SUBSTR( cControlSource, 1, AT( "->", cControlSource ) - 1 ))),FieldBlock( cControlSource ) )
  ENDIF

  RETURN ::xControlSource

METHOD END() CLASS HControl

   Super:END()
   IF ::tooltip != NIL
      DelToolTip( ::oParent:handle, ::handle )
      ::tooltip := NIL
   ENDIF

   RETURN NIL

METHOD onAnchor( x, y, w, h ) CLASS HControl
   LOCAL nAnchor, nXincRelative, nYincRelative, nXincAbsolute, nYincAbsolute
   LOCAL x1, y1, w1, h1, x9, y9, w9, h9
   LOCAL nCxv := IIF( HWG_BITAND( ::style, WS_VSCROLL ) != 0, GetSystemMetrics( SM_CXVSCROLL ) + 1 , 3 )
   LOCAL nCyh := IIF( HWG_BITAND( ::style, WS_HSCROLL ) != 0, GetSystemMetrics( SM_CYHSCROLL ) + 1 , 3 )

   nAnchor := ::anchor
   x9 := ::nLeft
   y9 := ::nTop
   w9 := ::nWidth  //- IIF( ::winclass = "EDIT" .AND. __ObjHasMsg( Self,"hwndUpDown" ), GetClientRect( ::hwndUpDown)[ 3 ], 0 )
   h9 := ::nHeight
   x1 := ::nLeft
   y1 := ::nTop
   w1 := ::nWidth  //- IIF( ::winclass = "EDIT" .AND. __ObjHasMsg( Self,"hwndUpDown" ), GetClientRect( ::hwndUpDown)[ 3 ], 0 )
   h1 := ::nHeight
   // *- calculo relativo
   IF x > 0
      nXincRelative := w / x
   ENDIF
   IF y > 0
      nYincRelative := h / y
   ENDIF
   // *- calculo ABSOLUTE
   nXincAbsolute := ( w - x )
   nYincAbsolute := ( h - y )
   IF nAnchor >= ANCHOR_VERTFIX
      // *- vertical fixed center
      nAnchor := nAnchor - ANCHOR_VERTFIX
      y1 := y9 + Round( ( h - y ) * ( ( y9 + h9 / 2 ) / y ), 2 )
   ENDIF
   IF nAnchor >= ANCHOR_HORFIX
      // *- horizontal fixed center
      nAnchor := nAnchor - ANCHOR_HORFIX
      x1 := x9 + Round( ( w - x ) * ( ( x9 + w9 / 2 ) / x ), 2 )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTREL
      // relative - RIGHT RELATIVE
      nAnchor := nAnchor - ANCHOR_RIGHTREL
      x1 := w - Round( ( x - x9 - w9 ) * nXincRelative, 2 ) - w9
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMREL
      // relative - BOTTOM RELATIVE
      nAnchor := nAnchor - ANCHOR_BOTTOMREL
      y1 := h - Round( ( y - y9 - h9 ) * nYincRelative, 2 ) - h9
   ENDIF
   IF nAnchor >= ANCHOR_LEFTREL
      // relative - LEFT RELATIVE
      nAnchor := nAnchor - ANCHOR_LEFTREL
      IF x1 != x9
         w1 := x1 - ( Round( x9 * nXincRelative, 2 ) ) + w9
      ENDIF
      x1 := Round( x9 * nXincRelative, 2 )
   ENDIF
   IF nAnchor >= ANCHOR_TOPREL
      // relative  - TOP RELATIVE
      nAnchor := nAnchor - ANCHOR_TOPREL
      IF y1 != y9
         h1 := y1 - ( Round( y9 * nYincRelative, 2 ) ) + h9
      ENDIF
      y1 := Round( y9 * nYincRelative, 2 )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTABS
      // Absolute - RIGHT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_RIGHTABS
      IF HWG_BITAND( ::Anchor, ANCHOR_LEFTREL ) != 0
         w1 := INT( nxIncAbsolute ) - ( x1 - x9 ) + w9
      ELSE
         IF x1 != x9
            w1 := x1 - ( x9 +  INT( nXincAbsolute ) ) + w9
         ENDIF
         x1 := x9 +  INT( nXincAbsolute )
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMABS
      // Absolute - BOTTOM ABSOLUTE
      nAnchor := nAnchor - ANCHOR_BOTTOMABS
      IF HWG_BITAND( ::Anchor, ANCHOR_TOPREL ) != 0
         h1 := INT( nyIncAbsolute ) - ( y1 - y9 ) + h9
      ELSE
         IF y1 != y9
            h1 := y1 - ( y9 +  Int( nYincAbsolute ) ) + h9
         ENDIF
         y1 := y9 +  Int( nYincAbsolute )
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_LEFTABS
      // Absolute - LEFT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_LEFTABS
      IF x1 != x9
         w1 := x1 - x9 + w9
      ENDIF
      x1 := x9
   ENDIF
   IF nAnchor >= ANCHOR_TOPABS
      // Absolute - TOP ABSOLUTE
      // nAnchor := nAnchor - 1
      IF y1 != y9
         h1 := y1 - y9 + h9
      ENDIF
      y1 := y9
   ENDIF
   // REDRAW AND INVALIDATE SCREEN
   IF ( x1 != X9 .OR. y1 != y9 .OR. w1 != w9 .OR. h1 != h9 )
      IF isWindowVisible( ::handle )
         IF ( x1 != x9 .or. y1 != y9 ) .AND. x9 < ::oParent:nWidth
            InvalidateRect( ::oParent:handle, 1, MAX( x9 - 1, 0 ), MAX( y9 - 1, 0 ), ;
                  x9 + w9 + nCxv, y9 + h9 + nCyh )
         ELSE
            IF w1 < w9
               InvalidateRect( ::oParent:handle, 1, x1 + w1 - nCxv - 1, MAX( y1 - 2, 0 ), ;
                     x1 + w9 + 2 , y9 + h9 + nCxv + 1)
            ENDIF
            IF h1 < h9
               InvalidateRect( ::oParent:handle, 1, MAX( x1 - 5, 0 ) , y1 + h1 - nCyh - 1, ;
                     x1 + w9 + 2 , y1 + h9 + nCYh )
            ENDIF
         ENDIF
         // * ::Move( x1, y1, w1, h1,  HWG_BITAND( ::Style, WS_CLIPSIBLINGS + WS_CLIPCHILDREN ) = 0 )
         IF ( ( x1 != x9 .OR. y1 != y9 ) .AND. ( ISBLOCK( ::bPaint ) .OR. ;
               x9 + w9 > ::oParent:nWidth ) ) .OR. ( ::backstyle = TRANSPARENT .AND. ;
               ( ::Title != NIL .AND. ! Empty( ::Title ) ) ) .OR. __ObjHasMsg( Self,"oImage" )
            IF __ObjHasMsg( Self, "oImage" ) .OR.  ::backstyle = TRANSPARENT //.OR. w9 != w1
               InvalidateRect( ::oParent:handle, 1, MAX( x1 - 1, 0 ), MAX( y1 - 1, 0 ), x1 + w1 + 1 , y1 + h1 + 1 )
            ELSE
               RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT )
            ENDIF
         ELSE
            IF LEN( ::aControls ) = 0 .AND. ::Title != NIL
               InvalidateRect( ::handle, 0 )
            ENDIF
            IF w1 > w9
               InvalidateRect( ::oParent:handle, 1 , MAX( x1 + w9 - nCxv - 1, 0 ) ,;
                     MAX( y1 , 0 ) , x1 + w1 + nCxv  , y1 + h1 + 2  )
            ENDIF
            IF h1 > h9
               InvalidateRect( ::oParent:handle, 1 , MAX( x1 , 0 ) , ;
                     MAX( y1 + h9 - nCyh - 1 , 1 ) , x1 + w1 + 2 , y1 + h1 + nCyh )
            ENDIF
         ENDIF
         // redefine new position e new size
         ::Move( x1, y1, w1, h1,  HWG_BITAND( ::Style, WS_CLIPSIBLINGS + WS_CLIPCHILDREN ) = 0 )

         IF ( ::winClass == "ToolbarWindow32" .OR. ::winClass == "msctls_statusbar32" )
            ::Resize( nXincRelative, w1 != w9, h1 != h9 )
         ENDIF
      ELSE
         ::Move( x1, y1, w1, h1, 0 )
         IF ( ::winClass == "ToolbarWindow32" .OR. ::winClass == "msctls_statusbar32" )
            ::Resize( nXincRelative, w1 != w9, h1 != h9 )
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL

// - HStatus

CLASS HStatus INHERIT HControl

   CLASS VAR winclass INIT "msctls_statusbar32"
   DATA aParts
   DATA nStatusHeight INIT 0
   DATA bDblClick
   DATA bRClick

   METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint, bRClick, bDblClick, nHeight )
   METHOD Activate()
   METHOD Init()
   METHOD Notify( lParam )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
         bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )
   METHOD SetTextPanel( nPart, cText, lRedraw )
   METHOD GetTextPanel( nPart )
   METHOD SetIconPanel( nPart, cIcon, nWidth, nHeight )
   METHOD StatusHeight( nHeight )
   METHOD Resize( xIncrSize )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint, bRClick, bDblClick, nHeight ) CLASS HStatus

   bSize  := IIf( bSize != NIL, bSize, { | o, x, y | o:Move( 0, y - ::nStatusHeight, x, ::nStatusHeight ) } )
   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
         WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + WS_CLIPSIBLINGS )
   Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, ;
         bSize, bPaint )
   //::nHeight   := nHeight
   ::nStatusHeight := IIF( nHeight = NIL, ::nStatusHeight, nHeight )
   ::aParts    := aParts
   ::bDblClick := bDblClick
   ::bRClick   := bRClick

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HStatus

   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatusWindow( ::oParent:handle, ::id )
      ::StatusHeight( ::nStatusHeight )
      ::Init()
      /*
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         aCoors := GetWindowRect( ::handle )
         ::oParent:aOffset[ 4 ] := aCoors[ 4 ] - aCoors[ 2 ]
      ENDIF
      */
   ENDIF

   RETURN NIL

METHOD Init() CLASS HStatus

   IF ! ::lInit
      IF ! Empty( ::aParts )
         hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
      ENDIF
      Super:Init()
   ENDIF

   RETURN  NIL

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )  CLASS hStatus

   HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
         bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::aParts := aParts

   RETURN Self

METHOD Notify( lParam ) CLASS HStatus

   LOCAL nCode := GetNotifyCode( lParam )
   LOCAL nParts := GetNotifySBParts( lParam ) - 1

   //#define NM_FIRST     ( 0- 0)
   //#define NM_CLICK     (NM_FIRST-2)    // uses NMCLICK struct
   #define NM_DBLCLK    (NM_FIRST-3)
   #define NM_RCLICK    (NM_FIRST-5)    // uses NMCLICK struct
   #define NM_RDBLCLK   (NM_FIRST-6)

   DO CASE
   CASE nCode == NM_CLICK
   CASE nCode == NM_DBLCLK
      IF ::bdblClick != NIL
         Eval( ::bdblClick, Self, nParts )
      ENDIF
   CASE nCode == NM_RCLICK
      IF ::bRClick != NIL
         Eval( ::bRClick, Self, nParts )
      ENDIF
   ENDCASE

   RETURN NIL

METHOD StatusHeight( nHeight  ) CLASS HStatus
   LOCAL aCoors

   IF nHeight != NIL
      aCoors := GetWindowRect( ::handle )
      IF nHeight != 0
         IF ::lInit .AND. __ObjHasMsg( ::oParent, "AOFFSET" )
            ::oParent:aOffset[ 4 ] -= ( aCoors[ 4 ] - aCoors[ 2 ] )
         ENDIF
         SendMessage( ::handle,;           // (HWND) handle to destination control
               SB_SETMINHEIGHT, nHeight, 0 )      // (UINT) message ID  // = (WPARAM)(int) minHeight;
         SendMessage( ::handle, WM_SIZE, 0, 0 )
         aCoors := GetWindowRect( ::handle )
      ENDIF
      ::nStatusHeight := ( aCoors[ 4 ] - aCoors[ 2 ] ) - 1
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         ::oParent:aOffset[ 4 ] += ( aCoors[ 4 ] - aCoors[ 2 ]  )
      ENDIF
   ENDIF

   RETURN ::nStatusHeight

METHOD GetTextPanel( nPart ) CLASS HStatus
   LOCAL ntxtLen, cText := ""

   ntxtLen := SendMessage( ::handle, SB_GETTEXTLENGTH, nPart - 1, 0 )
   cText := Replicate( Chr( 0 ), ntxtLen )
   SendMessage( ::handle, SB_GETTEXT, nPart - 1, @cText )

   RETURN cText

METHOD SetTextPanel( nPart, cText, lRedraw ) CLASS HStatus
   //WriteStatusWindow( ::handle,nPart-1,cText )
   SendMessage( ::handle, SB_SETTEXT, nPart - 1, cText )
   IF lRedraw != NIL .AND. lRedraw
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN NIL

METHOD SetIconPanel( nPart, cIcon, nWidth, nHeight ) CLASS HStatus
   LOCAL oIcon

   DEFAULT nWidth := 16
   DEFAULT nHeight := 16
   DEFAULT cIcon := ""

   IF HB_IsNumeric( cIcon ) .OR. At( ".", cIcon ) = 0
      //oIcon := HIcon():addResource( cIcon, nWidth, nHeight )
      oIcon := HIcon():addResource( cIcon, nWidth, nHeight, LR_LOADMAP3DCOLORS + ;
            IIF( Empty( HWG_GETWINDOWTHEME( ::handle ) ), LR_LOADTRANSPARENT, 0 ) )
   ELSE
      oIcon := HIcon():addFile( cIcon, nWidth, nHeight )
   ENDIF
   IF ! EMPTY( oIcon )
      SendMessage( ::handle, SB_SETICON, nPart - 1, oIcon:handle )
   ENDIF

   RETURN NIL

METHOD Resize( xIncrSize ) CLASS HStatus
   LOCAL i

   IF ! Empty( ::aParts )
      FOR i := 1 TO LEN( ::aParts )
         ::aParts[ i ] := ROUND( ::aParts[ i ] * xIncrSize, 0 )
      NEXT
      hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
   ENDIF

   RETURN NIL

// - HStatic

CLASS HStatic INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA AutoSize INIT .F.
   //DATA lTransparent  INIT .F. HIDDEN
   DATA nStyleHS
   DATA bClick, bDblClick
   DATA hBrushDefault  HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
         bColor, lTransp, bClick, bDblClick, bOther )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
         bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther )
   METHOD Activate()
   // METHOD SetValue( value ) INLINE SetDlgItemText( ::oParent:handle, ::id, ;
   METHOD SetText( value ) INLINE ::SetValue( value )
   METHOD SetValue( cValue )
   METHOD Auto_Size( cValue )  HIDDEN
   METHOD Init()
   METHOD PAINT( lpDis )
   METHOD onClick()
   METHOD onDblClick()
   METHOD OnEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
      bColor, lTransp, bClick, bDblClick, bOther ) CLASS HStatic


   nStyle := IIF( nStyle = Nil, 0, nStyle )
   ::nStyleHS := nStyle - Hwg_BitAND( nStyle,  WS_VISIBLE + WS_DISABLED + WS_CLIPSIBLINGS + ;
                                               WS_CLIPCHILDREN + WS_BORDER + WS_DLGFRAME + ;
                                               WS_VSCROLL + WS_HSCROLL + WS_THICKFRAME + WS_TABSTOP )
   nStyle += SS_NOTIFY + WS_CLIPCHILDREN  //- ::nStyleHS

   ::BackStyle := OPAQUE
   IF ( lTransp != NIL .AND. lTransp )
      ::BackStyle := TRANSPARENT
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      nStyle += SS_OWNERDRAW - ::nStyleHS
   ELSEIF ::nStyleHS > 32 .OR. ::nStyleHS = 2
      bPaint := { | o, p | o:paint( p ) }
      nStyle +=  SS_OWNERDRAW - ::nStyleHS
   ENDIF
   
   /*
   LOCAL nStyles
   // Enabling style for tooltips
   //IF ValType( cTooltip ) == "C"
   //   IF nStyle == NIL
   //      nStyle := SS_NOTIFY
   //   ELSE
   nStyles := IIF(Hwg_BitAND( nStyle, WS_BORDER ) != 0, WS_BORDER, 0 )
   nStyles += IIF(Hwg_BitAND( nStyle, WS_DLGFRAME ) != 0, WS_DLGFRAME , 0 )
   nStyles += IIF(Hwg_BitAND( nStyle, WS_DISABLED ) != 0, WS_DISABLED , 0 )
   nStyles += IIF(Hwg_BitAND( nStyle, WS_TABSTOP ) != 0, WS_TABSTOP , 0 )
   nStyle  := Hwg_BitOr( nStyle, SS_NOTIFY ) - nStyles
   //    ENDIF
   // ENDIF
   //
   ::nStyleHS := IIf( nStyle == NIL, 0, nStyle )
   ::BackStyle := OPAQUE
   IF ( lTransp != NIL .AND. lTransp ) //.OR. ::lOwnerDraw
      ::BackStyle := TRANSPARENT
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      nStyle := SS_OWNERDRAW + Hwg_Bitand( nStyle, SS_NOTIFY )
   ELSEIF nStyle - SS_NOTIFY > 32 .OR. ::nStyleHS - SS_NOTIFY = 2
      bPaint := { | o, p | o:paint( p ) }
      nStyle := SS_OWNERDRAW + Hwg_Bitand( nStyle, SS_NOTIFY )
   ENDIF
   */
   ::hBrushDefault := HBrush():Add( GetSysColor( COLOR_BTNFACE ) )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
         bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   ::bOther := bOther
   ::title := cCaption

   ::Activate()

   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent( STN_CLICKED, Self, { || ::onClick() } )
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, Self, { || ::onDblClick() } )

   RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther ) CLASS HStatic

   IF ( lTransp != NIL .AND. lTransp )  //.OR. ::lOwnerDraw
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      ::BackStyle := TRANSPARENT
   ENDIF

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
         bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   // Enabling style for tooltips
   //IF ValType( cTooltip ) == "C"
   ::Style := SS_NOTIFY
   //ENDIF
   ::bOther := bOther
   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent( STN_CLICKED, Self, { || ::onClick() } )
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, Self, { || ::onDblClick() } )

   RETURN Self

METHOD Activate() CLASS HStatic

   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
            ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
            ::extStyle )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HStatic

   IF ! ::lInit
      Super:init()
      IF ::nHolder != 1
         ::nHolder := 1
         SetWindowObject( ::handle, Self )
         Hwg_InitStaticProc( ::handle )
      ENDIF
      IF ::classname == "HSTATIC"
         ::Auto_Size( ::Title )
      ENDIF
      IF ::title != NIL
         SetWindowText( ::handle, ::title )
      ENDIF
   ENDIF

   RETURN  NIL

METHOD OnEvent( msg, wParam, lParam ) CLASS  HStatic
   LOCAL nEval, pos

   IF ::bOther != NIL
      IF ( nEval := Eval( ::bOther, Self, msg, wParam, lParam ) ) != - 1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg = WM_KEYUP
      IF wParam = VK_DOWN
         Getskip( ::oParent, ::handle,, 1 )
      ELSEIF wParam = VK_UP
         Getskip( ::oParent, ::handle,, - 1 )
      ELSEIF wParam = VK_TAB
         GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1 ) )
      ENDIF
      RETURN 0
   ELSEIF msg == WM_SYSKEYUP
      IF ( pos := At( "&", ::title ) ) > 0 .and. wParam == Asc( Upper( SubStr( ::title, ++ pos, 1 ) ) )
         getskip( ::oparent, ::handle,, 1 )
         RETURN  0
      ENDIF
   ELSEIF msg = WM_GETDLGCODE
      RETURN DLGC_WANTARROWS + DLGC_WANTTAB // +DLGC_STATIC   //DLGC_WANTALLKEYS //DLGC_WANTARROWS  + DLGC_WANTCHARS
   ENDIF

   RETURN - 1

METHOD SetValue( cValue )  CLASS HStatic

   ::Auto_Size( cValue )
   IF ::backstyle = TRANSPARENT .AND. ::Title != cValue .AND. isWindowVisible( ::handle )
      SetDlgItemText( ::oParent:handle, ::id, cValue )
      IF ::backstyle = TRANSPARENT .AND. ::Title != cValue .AND. isWindowVisible( ::handle )
         RedrawWindow( ::oParent:Handle, RDW_ERASE + RDW_INVALIDATE + RDW_ERASENOW + RDW_INTERNALPAINT , ::nLeft, ::nTop, ::nWidth , ::nHeight )
         *-InvalidateRect( ::oParent:Handle, 0, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
         UpdateWindow( ::oParent:Handle )
      ENDIF
   ELSEIF ::backstyle != TRANSPARENT
      SetDlgItemText( ::oParent:handle, ::id, cValue )
   ENDIF
   ::Title := cValue

   RETURN NIL

METHOD Paint( lpDis ) CLASS HStatic
   LOCAL drawInfo := GetDrawItemInfo( lpDis )
   LOCAL client_rect, szText
   LOCAL dwtext, nstyle, brBackground
   LOCAL dc := drawInfo[ 3 ]

   client_rect := CopyRect( { drawInfo[ 4 ] , drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )
   //client_rect := GetClientRect( ::handle )
   szText := GetWindowText( ::handle )

   // Map "Static Styles" to "Text Styles"
   nstyle := ::nStyleHS  // ::style
   IF nStyle - SS_NOTIFY < DT_SINGLELINE
      SetAStyle( @nstyle, @dwtext )
   ELSE
       dwtext := nStyle - DT_NOCLIP
   ENDIF

   // Set transparent background
   SetBkMode( dc, ::backstyle )
   IF ::BackStyle = OPAQUE
      brBackground := IIF( ! EMPTY( ::brush ), ::brush, ::hBrushDefault )
      FillRect( dc, client_rect[ 1 ], client_rect[ 2 ], client_rect[ 3 ], client_rect[ 4 ], brBackground:handle )
   ENDIF

   IF ::tcolor != NIL .AND. ::isEnabled()
      SetTextColor( dc, ::tcolor )
   ELSEIF ! ::isEnabled()
      SetTextColor( dc, 16777215 ) //GetSysColor( COLOR_WINDOW ) )
      DrawText( dc, szText, { client_rect[ 1 ] + 1, client_rect[ 2 ] + 1, client_rect[ 3 ] + 1, client_rect[ 4 ] + 1 }, dwtext )
      SetBkMode( dc, TRANSPARENT )
      SetTextColor( dc, 10526880 ) //GetSysColor( COLOR_GRAYTEXT ) )
   ENDIF
   // Draw the text
   DrawText( dc, szText, client_rect, dwtext )

   RETURN NIL

METHOD onClick()  CLASS HStatic

   IF ::bClick != NIL
      //::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN NIL

METHOD onDblClick()  CLASS HStatic

   IF ::bDblClick != NIL
      //::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bDblClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN NIL

METHOD Auto_Size( cValue ) CLASS HStatic
   LOCAL  ASize, nLeft, nAlign

   IF ::autosize  //.OR. ::lOwnerDraw
      nAlign := ::nStyleHS - SS_NOTIFY
      ASize :=  TxtRect( cValue, Self )
      // ajust VCENTER
      // ::nTop := ::nTop + Int( ( ::nHeight - ASize[ 2 ] + 2 ) / 2 )
      IF nAlign == SS_RIGHT
         nLeft := ::nLeft + ( ::nWidth - ASize[ 1 ] - 2 )
      ELSEIF nAlign == SS_CENTER
         nLeft := ::nLeft + Int( ( ::nWidth - ASize[ 1 ] - 2 ) / 2 )
      ELSEIF nAlign == SS_LEFT
         nLeft := ::nLeft
      ENDIF
      ::nWidth := ASize[ 1 ] + 2
      ::nHeight := ASize[ 2 ]
      ::nLeft := nLeft
      ::move( ::nLeft, ::nTop )
   ENDIF

   RETURN NIL

// - HButton

CLASS HButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA bClick
   DATA cNote  HIDDEN
   DATA lFlat INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
         tcolor, bColor, bGFocus )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
         cTooltip, tcolor, bColor, cCaption, bGFocus )
   METHOD Init()
   METHOD onClick()
   METHOD onGetFocus()
   METHOD onLostFocus()
   METHOD onEvent( msg, wParam, lParam )
   METHOD NoteCaption( cNote )  SETGET

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, bGFocus ) CLASS HButton

   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), BS_PUSHBUTTON + BS_NOTIFY )
   ::title := cCaption
   ::bClick := bClick
   ::bGetFocus := bGFocus
   ::lFlat := Hwg_BitAND( nStyle, BS_FLAT ) != 0

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
         IIf( nWidth  == NIL, 90, nWidth  ), ;
         IIf( nHeight == NIL, 30, nHeight ), ;
         oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   ::Activate()
   //IF bGFocus != NIL
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_SETFOCUS, Self, { || ::onGetFocus() } )
   ::oParent:AddEvent( BN_KILLFOCUS, self, {|| ::onLostFocus()})
   //ENDIF
    /*
   IF ::oParent:oParent != NIL .and. ::oParent:ClassName == "HTAB"
      //::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::Notify( WM_KEYDOWN ) } )
      IF bClick != NIL
         ::oParent:oParent:AddEvent( 0, Self, { || ::onClick() } )
      ENDIF
   ENDIF
   */
   IF ::id > IDCANCEL .OR. ::bClick != NIL
      IF ::id < IDABORT
         hwg_GetParentForm(Self):AddEvent( BN_CLICKED, Self, { || ::onClick() } )
      ENDIF
      IF hwg_GetParentForm(Self):Classname != ::oParent:Classname  .OR. ::id > IDCANCEL
         ::oParent:AddEvent( BN_CLICKED, Self, { || ::onClick() } )
      ENDIF
   ENDIF

   RETURN Self

METHOD Activate() CLASS HButton

   IF ! Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
            ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
            ::title )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption, bGFocus ) CLASS HButton

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
         bSize, bPaint, cTooltip, tcolor, bColor )

   ::title   := cCaption
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_SETFOCUS, Self, { || ::onGetFocus() } )
   ::oParent:AddEvent( BN_KILLFOCUS, self, {|| ::onLostFocus()})
   ::bClick  := bClick
   IF ::id > IDCANCEL .OR. ::bClick != NIL
      IF ::id < IDABORT
         hwg_GetParentForm(Self):AddEvent( BN_CLICKED, Self, { || ::onClick() } )
      ENDIF
      IF hwg_GetParentForm(Self):Classname != ::oParent:Classname  .OR. ::id > IDCANCEL
         ::oParent:AddEvent( BN_CLICKED, Self, { || ::onClick() } )
      ENDIF
   ENDIF

   RETURN Self

METHOD Init() CLASS HButton

   IF ! ::lInit
      IF !( hwg_GetParentForm(Self):classname == ::oParent:classname .AND.;
            hwg_GetParentForm(Self):Type >= WND_DLG_RESOURCE ) .OR. ;
            ! hwg_GetParentForm(Self):lModal  .OR. ::nHolder = 1
         ::nHolder := 1
         SetWindowObject( ::handle, Self )
         HWG_INITBUTTONPROC( ::handle )
      ENDIF
      ::Super:init()
      /*
      IF ::Title != NIL
         SETWINDOWTEXT( ::handle, ::title )
      ENDIF
      */
   ENDIF

   RETURN  NIL

METHOD onevent( msg, wParam, lParam ) CLASS HButton

   IF msg = WM_SETFOCUS .AND. ::oParent:oParent = NIL
      // *- SENDMESSAGE( ::handle, BM_SETSTYLE , BS_PUSHBUTTON , 1 )
   ELSEIF msg = WM_KILLFOCUS
      IF hwg_GetParentForm(Self):handle != ::oParent:Handle
         // *- IF ::oParent:oParent != NIL
         InvalidateRect( ::handle, 0 )
         SENDMESSAGE( ::handle, BM_SETSTYLE , BS_PUSHBUTTON , 1 )
      ENDIF
   ELSEIF msg = WM_KEYDOWN
      IF ( wParam == VK_RETURN   .OR. wParam == VK_SPACE )
         SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
         RETURN 0
      ENDIF
      IF ! ProcKeyList( Self, wParam )
         IF wParam = VK_TAB
            GetSkip( ::oparent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1)  )
            RETURN 0
         ELSEIF wParam = VK_LEFT .OR. wParam = VK_UP
            GetSkip( ::oparent, ::handle, , -1 )
            RETURN 0
         ELSEIF wParam = VK_RIGHT .OR. wParam = VK_DOWN
            GetSkip( ::oparent, ::handle, , 1 )
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF msg == WM_KEYUP
      IF ( wParam == VK_RETURN .OR. wParam == VK_SPACE )
         SendMessage( ::handle, WM_LBUTTONUP, 0, MAKELPARAM( 1, 1 ) )
         RETURN 0
      ENDIF
   ELSEIF  msg = WM_GETDLGCODE .AND. ! EMPTY( lParam )
      IF wParam = VK_RETURN .OR. wParam = VK_TAB
      ELSEIF GETDLGMESSAGE( lParam ) = WM_KEYDOWN .AND.wParam != VK_ESCAPE
      ELSEIF GETDLGMESSAGE( lParam ) = WM_CHAR .OR.wParam = VK_ESCAPE
         RETURN -1
      ENDIF
      RETURN DLGC_WANTMESSAGE
   ENDIF

   RETURN -1

METHOD onClick()  CLASS HButton

   IF ::bClick != NIL
      Eval( ::bClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN NIL

METHOD NoteCaption( cNote )  CLASS HButton

   IF cNote != NIL
      IF Hwg_BitOr( ::Style, BS_COMMANDLINK ) > 0
         SENDMESSAGE( ::Handle, BCM_SETNOTE, 0, ANSITOUNICODE( cNote ) )
      ENDIF
      ::cNote := cNote
   ENDIF

   RETURN ::cNote

METHOD onGetFocus()  CLASS HButton
   LOCAL res := .t., nSkip

   IF ! CheckFocus( Self, .f. ) .OR. ::bGetFocus = NIL
      RETURN .t.
   ENDIF
   IF ::bGetFocus != NIL
      nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
      ::oParent:lSuspendMsgsHandling := .t.
      res := Eval( ::bGetFocus, ::title, Self )
      ::oParent:lSuspendMsgsHandling := .f.
      IF res != NIL .AND.  EMPTY( res )
         WhenSetFocus( Self, nSkip )
         IF ::lflat
            InvalidateRect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
         ENDIF
      ENDIF
   ENDIF

   RETURN res

METHOD onLostFocus()  CLASS HButton

   IF ::lflat
      InvalidateRect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
   ENDIF
   ::lnoWhen := .F.
   IF ::bLostFocus != NIL .AND. SelfFocus( GetParent( GetFocus() ), hwg_getparentform(Self):Handle )
      ::oparent:lSuspendMsgsHandling := .t.
      Eval( ::bLostFocus, ::title, Self)
      ::oparent:lSuspendMsgsHandling := .f.
   ENDIF

   RETURN NIL

// CLASS HGroup
CLASS HGroup INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor )
   METHOD Activate()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
            oFont, bInit, bSize, bPaint, tcolor, bColor ) CLASS HGroup

   nStyle := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), BS_GROUPBOX )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
              oFont, bInit, bSize, bPaint,, tcolor, bColor )

   ::title := cCaption
   ::Activate()

RETURN Self

METHOD Activate() CLASS HGroup
   IF !Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::title )
      ::Init()
   ENDIF
RETURN NIL

// HLine

CLASS HLine INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA lVert
   DATA LineSlant
   DATA nBorder
   DATA oPenLight, oPenGray

   METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize, bInit, tcolor, nHeight, cSlant, nBorder )
   METHOD Activate()
   METHOD Paint( lpDis )

ENDCLASS

METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize, bInit, tcolor, nHeight, cSlant, nBorder ) CLASS HLine

   Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop,,,,bInit, ;
         bSize, { | o, lp | o:Paint( lp ) } , , tcolor )

   ::title := ""
   ::lVert := IIf( lVert == NIL, .F., lVert )
   ::LineSlant := IIF( EMPTY( cSlant ) .OR. ! cSlant $ "/\", "", cSlant )
   ::nBorder := IIF( EMPTY( nBorder ), 1, nBorder )

   IF EMPTY( ::LineSlant )
      IF ::lVert
         ::nWidth  := ::nBorder + 1 //10
         ::nHeight := IIf( nLength == NIL, 20, nLength )
      ELSE
         ::nWidth  := IIf( nLength == NIL, 20, nLength )
         ::nHeight := ::nBorder + 1 //10
      ENDIF
      ::oPenLight := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
      ::oPenGray  := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DSHADOW  ) )
   ELSE
      ::nWidth  := nLength
      ::nHeight := nHeight
      ::oPenLight := HPen():Add( BS_SOLID, ::nBorder, tColor )
   ENDIF

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HLine

   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
            ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Paint( lpdis ) CLASS HLine
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ]
   LOCAL x1  := drawInfo[ 4 ], y1 := drawInfo[ 5 ]
   LOCAL x2  := drawInfo[ 6 ], y2 := drawInfo[ 7 ]

   SelectObject( hDC, ::oPenLight:handle )

   IF EMPTY( ::LineSlant )
      IF ::lVert
         DrawLine( hDC, x1 + 1, y1, x1 + 1, y2 )
      ELSE
         DrawLine( hDC, x1 , y1 + 1, x2, y1 + 1 )
      ENDIF
      SelectObject( hDC, ::oPenGray:handle )
      IF ::lVert
         DrawLine( hDC, x1, y1, x1, y2 )
      ELSE
         DrawLine( hDC, x1, y1, x2, y1 )
      ENDIF
   ELSE
      IF ( x2 - x1 ) <= ::nBorder
         DrawLine( hDC, x1, y1, x1, y2 )
      ELSEIF ( y2 - y1 ) <= ::nBorder
         DrawLine( hDC, x1, y1, x2, y1 )
      ELSEIF ::LineSlant == "/"
          DrawLine( hDC, x1  , y1 + y2 , x1 + x2 , y1  )
      ELSEIF ::LineSlant == "\"
          DrawLine( hDC, x1 , y1, x1 + x2 , y1 + y2 )
      ENDIF
    ENDIF

   RETURN NIL

INIT PROCEDURE starttheme()
   INITTHEMELIB()

EXIT PROCEDURE endtheme()
   ENDTHEMELIB()
