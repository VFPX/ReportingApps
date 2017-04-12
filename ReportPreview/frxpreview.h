*=======================================================
* Report Preview compile constants
*=======================================================

#include foxpro_reporting.h
#include frxpreview_loc.h

#define PREVIEW_VERSION		"9.2.0.3"

*-------------------------------------------------------
* Debug compile switches:
*  - double-check these before each release build:
*-------------------------------------------------------
#define PREVIEW_WILL_HAVE_TOOLBAR	.T.
#define DEBUG_SUSPEND_ON_ERROR      .T.
#define DEBUG_MENU_INFO_OPTION      .F. 
#define DEBUG_METHOD_LOGGING        .F. 

*-------------------------------------------------------
* Setting font name and size for handler dialogs:
* (see frxBaseForm class, .AdjustForLargeFonts() method)
*-------------------------------------------------------
#define DIALOG_ADJUST_FOR_LARGE_FONTS		.T.		&& This enables a default font size adjustment if DPI >= 120. Recommended value: .T.
#define DIALOG_FONTNAME_OVERRIDE			""		&& Anything other than empty will force a specific fontname in handler dialogs, and ignore any default font face adjustment code.
#define DIALOG_FONTSIZE_OVERRIDE             0		&& Anything other than 0 will force a specific font size in handler dialogs, and ignore any default font size adjustment code.

*-------------------------------------------------------
* Debug switches for testing out the above settings:
*-------------------------------------------------------
#define DEBUG_FORCE_LARGE_FONTS				.F.		&& Normally, a DPI>=120 check is used before switching to large fonts. This bypasses the check. Recommended value: .F. (unless you are running at 96dpi and you need to check how it will look when DIALOG_ADJUST_FOR_LARGE_FONTS=.T.)
#define DEBUG_FORCE_SEGOE_UI                .F.		&& Normally, an OS(3)=6 check is used before testing for availability of the Segoe UI font. This bypasses the check and uses Segoe UI regardless of OS. Recommended value: .F. (unless testing and you know it's available.)

*-------------------------------------------------------
* File names and locations:
*-------------------------------------------------------

#define FRXCOMMON_PRG_CLASSLIB  "frxcommon.prg"

*-------------------------------------------------------
* Resource Keys
*-------------------------------------------------------

#define REPORTPREVIEW_RESOURCE_ID		"92REPREVIEW"   

*-------------------------------------------------------
* Magic Numbers
*-------------------------------------------------------

#define ZOOM_LEVEL_PROMPT	1
#define ZOOM_LEVEL_PERCENT  2
#define ZOOM_LEVEL_CANVAS   3

#define CANVAS_LEFT			1
#define CANVAS_TOP			2

#define SHOW_TOOLBAR_ENABLED	.T.
#define SHOW_TOOLBAR_DISABLED	.F.

#define SHOWWINDOW_IN_SCREEN	0
#define SHOWWINDOW_IN_TOPFORM 	1
#define SHOWWINDOW_AS_TOPFORM	2

#define WINDOWTYPE_MODELESS		0
#define WINDOWTYPE_MODAL		1

*-------------------------------------------------------
* Canvas Offsets
*-------------------------------------------------------

#define CANVAS_TOP_OFFSET_PIXELS          15		
#define CANVAS_LEFT_OFFSET_PIXELS         15
#define CANVAS_VERTICAL_GAP_PIXELS        10
#define CANVAS_HORIZONTAL_GAP_PIXELS      10

*-------------------------------------------------------
* Page Layout:
*-------------------------------------------------------

#define ORIENTATION_PORTRAIT	0
#define ORIENTATION_LANDSCAPE	1

