
#include "windows.ch"
#include "guilib.ch"

REQUEST HTIMER
REQUEST DBCREATE
REQUEST DBUSEAREA
REQUEST DBCREATEINDEX
REQUEST DBSEEK
REQUEST SHELLABOUT

#include "example.frm"

Function Main
Local oForm := HFormTmpl():Read( "example.xml" )

 oForm:ShowMain()

Return Nil
