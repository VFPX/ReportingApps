*=======================================================
* Report Preview - main program
*
* In VFP9, a program or app may be assigned as the 
* "Report Preview" application:
*
*    _REPORTPREVIEW = home()+"reportpreview.app"
*
* This program is the main program of the application
* that forms the default "preview factory" implementation.
*
* roRef is passed by reference. It must be assigned
* a reference to a Preview form before returning.
*
*=======================================================
#include frxPreview.h

lparameters roRef

#IF DEBUG_METHOD_LOGGING 
	debugout space(program(-1)) + "frxpreview.prg::(main)"
#ENDIF

*--------------------------------------------------------------
* Ensure some essential files are built in:
*--------------------------------------------------------------
external class     frxPreview.vcx

*-----------------------------------------------------------
* We've been passed an object var to place the preview form 
* reference into. Called from inside the REPORT FORM ... command.
* Return a reference to the preview container:
*-----------------------------------------------------------
if set("TALK")="ON"	
	set talk off
	roRef = newobject("frxPreviewProxy","frxPreview.vcx")
	set talk on
else
	roRef = newobject("frxPreviewProxy","frxPreview.vcx")
endif
return


*===========================================
* Class ErrorHandler
*
* A basic error handler.
*
* Useage:
* x = newobject("ErrorHandler","frxPreview.prg")
* x.Handle( iError, cMethod, iLine, THIS ) 
* if x.cancelled
*  :
* if x.suspened
*  :
*
*===========================================
define Class ErrorHandler as Custom

suspended = .F.
cancelled = .F.
errorText = ""

*------------------------------------------
procedure Handle
*------------------------------------------
lparameters iError, cMethod, iLine, oRef

store .F. to this.cancelled, this.suspended

local cErrorMsg, iRetval
cErrorMsg = message() 

cErrorMsg = m.cErrorMsg + chr(13) + ;
			"Line " + transform(m.iLine) + " in " + m.cMethod + "()"

if not empty( message(1) )
	cErrorMsg = m.cErrorMsg + ":" + chr(13) + message(1) 
endif
*if not empty( sys(2018) )
*	cErrorMsg = m.cErrorMsg + chr(13) + sys(2018) 
*endif
if parameters() > 3
	cErrorMsg = m.cErrorMsg + chr(13) + oRef.Name + ".Error()"
endif	

*------------------------------------------------------
* Save the error message so that it can be retrieved
*------------------------------------------------------
THIS.errorText = m.cErrorMsg

if DEBUG_SUSPEND_ON_ERROR
	cErrorMsg = m.cErrorMsg + chr(13)+chr(13) + "Do you want to suspend execution?"

	iRetval = messagebox( m.cErrorMsg, 3+16+512, DEFAULT_MBOX_TITLE_LOC + " Error" )
	do case
	case m.iRetVal = 6 && yes
		this.suspended = .T.
		
	case m.iRetVal = 2 && cancel
		this.cancelled = .T.

	endcase
else
	=messagebox( m.cErrorMsg, 0+16, DEFAULT_MBOX_TITLE_LOC + " Error" )
	this.cancelled = .T.
endif

return .F.
endproc

enddefine
