/*
 *$Id: guilib.h,v 1.5 2004-03-16 11:54:30 alkresin Exp $
 */

#define	WND_MAIN		1
#define	WND_MDI 		2
#define WND_MDICHILD            3
#define WND_CHILD               4
#define	WND_DLG_RESOURCE       10
#define	WND_DLG_NORESOURCE     11

#define	OBTN_INIT               0
#define	OBTN_NORMAL             1
#define	OBTN_MOUSOVER           2
#define	OBTN_PRESSED            3

#define	BRW_ARRAY               1
#define	BRW_DATABASE            2

#ifndef __XHARBOUR__
#define	hb_stackReturn()        (&hb_stack.Return)
#endif
