*=======================================================
* Report Preview localization constants
*=======================================================

#define c_CR	chr(13)
#define c_LF    chr(10)
#define c_CRLF  chr(13)+chr(10)
#define c_CR2	chr(13)+chr(13)
#define c_TAB	chr(9)

*-------------------------------------------------------
* Dialog Captions: 
*-------------------------------------------------------
#define DEFAULT_MBOX_TITLE_LOC      	"Report Preview"
#define REPORT_PREVIEW_CAPTION			"Report Preview"
#define REPORT_PREVIEW_PAGE_CAPTION     " - Page "
#define REPORT_PREVIEW_GOTO_PAGE_LOC    "Go to page number:"
#define TOOLBAR_CAPTION					"Print Preview"

*-------------------------------------------------------
* Message box strings: 
*-------------------------------------------------------
#define RP_INVALID_PARAMETERS_LOC		"ReportPreview.app has been called with invalid parameters."
#define RP_INVALID_INITIALIZATION_LOC	"Report Preview has not been initialized correctly. It requires a ReportListener reference."
#define RP_INVALID_PAGE_NUMBER_LOC		"Page number must be in range "
#define RP_NO_OUTPUT_PAGES_LOC          "There are no pages available to preview."
#define RP_OUTPUTPAGE_ERROR_LOC         "An exception ocurred invoking .OutputPage():"

*-------------------------------------------------------
* Zoom Level prompts:
*-------------------------------------------------------
#define ZOOM_LEVEL_PROMPT_10_LOC           "10%"
#define ZOOM_LEVEL_PROMPT_25_LOC           "25%"
#define ZOOM_LEVEL_PROMPT_50_LOC           "50%"
#define ZOOM_LEVEL_PROMPT_75_LOC           "75%"
#define ZOOM_LEVEL_PROMPT_100_LOC          "100%"
#define ZOOM_LEVEL_PROMPT_150_LOC          "150%"
#define ZOOM_LEVEL_PROMPT_200_LOC          "200%"
#define ZOOM_LEVEL_PROMPT_300_LOC          "300%"
#define ZOOM_LEVEL_PROMPT_500_LOC          "500%"
#define ZOOM_LEVEL_PROMPT_FIT_WIDTH_LOC    "Fit to Width"
#define ZOOM_LEVEL_PROMPT_WHOLE_PAGE_LOC   "Whole Page"

*-------------------------------------------------------
* Context menu prompts:
*-------------------------------------------------------
#define CONTEXT_MENU_PROMPT_FIRST_PAGE_LOC         "First page"
#define CONTEXT_MENU_PROMPT_PREVIOUS_LOC           "Previous"
#define CONTEXT_MENU_PROMPT_NEXT_LOC               "Next"
#define CONTEXT_MENU_PROMPT_LAST_PAGE_LOC          "Last page"
#define CONTEXT_MENU_PROMPT_GO_TO_PAGE_LOC         "Go to page..."
#define CONTEXT_MENU_PROMPT_ZOOM_LOC               "Zoom"
#define CONTEXT_MENU_PROMPT_PAGES_TO_DISPLAY_LOC   "Pages to display"
#define CONTEXT_MENU_PROMPT_TOOLBAR_LOC            "Toolbar"
#define CONTEXT_MENU_PROMPT_PRINT_LOC              "Print"
#define CONTEXT_MENU_PROMPT_CLOSE_LOC              "Close"
#define CONTEXT_MENU_PROMPT_INFODEBUG_LOC          "About..."
#define CONTEXT_MENU_PROMPT_1PAGE_LOC              "1 page"
#define CONTEXT_MENU_PROMPT_2PAGES_LOC             "2 pages"
#define CONTEXT_MENU_PROMPT_4PAGES_LOC             "4 pages"

*-------------------------------------------------------
* UI control captions (not already LOC'd) :
*-------------------------------------------------------
#define USE_LOC_STRINGS_IN_UI				.F.    && Set this .T. to enable these LOC strings in UI controls

#define UI_CMD_OK_LOC						"OK"
#define UI_CMD_CANCEL_LOC					"Cancel"

#define UI_TOOLBAR_GOTOPAGE_LOC				"Go to page"
#define UI_TOOLBAR_CLOSE_LOC				"Close"
#define UI_TOOLBAR_PRINT_LOC				"Print"

#define UI_TOOLBAR_TT_FIRST_LOC				"First page"
#define UI_TOOLBAR_TT_BACK_LOC				"Previous page"
#define UI_TOOLBAR_TT_GOTOPAGE_LOC			"Go to page"
#define UI_TOOLBAR_TT_NEXT_LOC				"Next page"
#define UI_TOOLBAR_TT_LAST_LOC				"Last page"
#define UI_TOOLBAR_TT_ZOOMLEVEL_LOC			"Choose page magnification"
#define UI_TOOLBAR_TT_1PAGE_LOC				"One page"
#define UI_TOOLBAR_TT_2PAGES_LOC			"Two pages"
#define UI_TOOLBAR_TT_4PAGES_LOC			"Four pages"
#define UI_TOOLBAR_TT_CLOSE_LOC				"Close preview window"
#define UI_TOOLBAR_TT_PRINT_LOC				"Print report"