#include frxBuilder.h

*=================================================
* Class: DesignerEventHandler
*
* An abstract superclass for programmatic event handlers
*=================================================
define Class DesignerEventHandler as Custom

	procedure Execute( oEvent )
		* process the event
	endproc
enddefine

*=================================================
* Class: ExitHandler
*
* An example exit handler
* (use REC_TYPE="X" to process on builder exit)
*=================================================
define Class ExitHandler as DesignerEventHandler
	procedure Execute( oEvent )
		=messagebox("I'm an exit handler!",0+64,"Exit Handler")
	endproc
enddefine

*=================================================
* Class: EventHookAlert 
*
* a small, liteweight event handler class. 
*=================================================
define class EventHookAlert as DesignerEventHandler

	AllowToContinue = .T.
	
	procedure execute( oEvent )
		local cText
		cText = oEvent.toString()
		=messagebox(m.cText, 64, EVENT_INSPECTOR_TITLE_LOC )
		THIS.AllowToContinue = .F.
	endproc

enddefine

          
*=================================================
* Class: GroupObjHandler
*
* This class should be registered to FRX_BLDR_EVENT_PROPERTIES
* for grouped layout objects (10)
*=================================================
define class GroupObjHandler as DesignerEventHandler

procedure Execute( oEvent )

	*-------------------------------------------------------
	* Display a messagebox indicating that the group items 
	* can not be edited while grouped.
	*-------------------------------------------------------
		
	=messagebox( GROUPED_ITEM_PROPERTIES_LOC, 0+64, DEFAULT_MBOX_TITLE_LOC )

	*-------------------------------------------------------
	* Pass the event back to the report designer:
	*-------------------------------------------------------
	oEvent.setHandledByBuilder( .T. )

	*-------------------------------------------------------
	* Tell it to respect the changes we just made:
	*-------------------------------------------------------
	oEvent.setReloadChanges( .F. )
			
	return

endproc

enddefine


*=================================================
* Class: ObjectDeleteHandler
*
* This class should be registered to FRX_BLDR_EVENT_OBJECTREMOVE
* for report layout objects; respects protection.
*=================================================
define class ObjectDeleteHandler as DesignerEventHandler

procedure Execute( oEvent )

	*-------------------------------------------------------
	* Delete events are unusual in that the FRX pointer will be 
	* located on the report header record (1,53), and NOT the currently
	* selected object.
	*
	* The handler needs to locate all currently selected objects and
	* loop through them in turn. If they are not delete-protected, it 
	* should delete the record in the FRX and set the oEvent.returnFlags 
	* appropriately.
	*-------------------------------------------------------
		
	local iProtFlags, iProtected
	iProtected = 0
	
	select frx
	scan for CURPOS and recno()>1
		
		iProtFlags = val(frx.ORDER)		
		if bittest( m.iProtFlags, FRX_PROTECT_OBJECT_NO_DELETE )
			*-------------------------------------------------------
			* De-select the record so that it will not be deleted:
			*-------------------------------------------------------
			replace CURPOS with .F.
			iProtected = m.iProtected + 1
		endif
	endscan		

	if m.iProtected > 0
		=messagebox( ;
			strtran( DELETE_MBOX_MSG_LOC, "{%1}", trans(m.iProtected) ), ;
			0+64, DELETE_MBOX_TITLE_LOC )
	endif

	*-------------------------------------------------------
	* Pass the event back to the report designer:
	*-------------------------------------------------------
	oEvent.setHandledByBuilder( .F. )

	*-------------------------------------------------------
	* Tell it to respect the changes we just made:
	*-------------------------------------------------------
	oEvent.setReloadChanges( .T. )
			
	return

endproc

enddefine

*=================================================
* Class: PreviewFromDesignerHandler
*
* This class should be registered to FRX_BLDR_EVENT_PREVIEWMODE
*=================================================
define Class PreviewFromDesignerHandler as DesignerEventHandler
	procedure Execute( oEvent )
		if oEvent.SessionData.Get("draftwarning") == "hide"
			* do nothing, we've already shown it
		else
			if set("REPORTBEHAVIOR")<90
				=messagebox( DRAFT_MODE_PREVIEW_WARNING_LOC, 64, DEFAULT_MBOX_TITLE_LOC)
				oEvent.SessionData.Set("draftwarning","hide")
			else
				* do nothing
			endif
		endif
	endproc
enddefine

*=================================================
* Class GetExprWrapper
*
* This GetExpression wrapper is the default one used
* in the ReportBuilder. You could expand on this API
* to show different dialogs based on data type and 
* where it was invoked from:
*=================================================
define Class GetExprWrapper as Custom

*-------------------------------------------------
function GetExpression
*-------------------------------------------------
* Possible values of m.lcCalledFrom, just in case you want 
* to customize the dialog that is shown for a given situation.
*
*	"LabelCaption"
* 	"PrintWhenExpression"
* 	"FieldExpression"
* 	"OleboundField"
* 	"OleboundExpression"
* 	"BandGroupOnExpression"
* 	"VariableValueToStore"
* 	"VariableInitialValue"
*   "BandOnEntryExpression"     && new in SP1
*   "BandOnExitExpression"      && new in SP1
*   "TargetAliasExpression"     && new in SP1
*
* Possible useful properties of loEvent:
*
*   .FrxSessionId
*   .DefaultSessionId
* 
*-------------------------------------------------
lparameter lcDefaultExpr, lcDataType, lcCalledFrom, loEvent
local cExpression, cCaptionText
if empty(m.lcCalledFrom)
	lcCalledFrom = ""
endif
do case
case m.lcCalledFrom = "LabelCaption"
	*----------------------------------------------------------------
	* Launch a multi-line edit window for "LabelCaption"
	*----------------------------------------------------------------
	* Fix for SP1: 
	* Use "loMemoEditor" instead of "x" and use the FRX data session
	*----------------------------------------------------------------
	set datasession to (loEvent.FrxSessionId)

	local loMemoEditor
	loMemoEditor = newobject("frxMemoEditForm","frxBuilder.vcx")
	with loMemoEditor
		.Caption 		= LABEL_EDIT_CAPTION_LOC
		.FixedWidthFont = .F.
		.Text 			= m.lcDefaultExpr
		.setHelperText( LABEL_EDIT_COMMENT_LOC )
		.Execute()
	endwith
	cExpression = left( loMemoEditor.Text, 254 )

otherwise
	*-------------------------------------------------------
	* We're using GETEXPR, which has a 254 character limit:
	*-------------------------------------------------------
	lcDefaultExpr = left( m.lcDefaultExpr, 254 )

	*-------------------------------------------------------
	* Fix for SP1: allow specific caption text, localizable:
	*-------------------------------------------------------
	do case
	case m.lcCalledFrom = "PrintWhenExpression"
		cCaptionText = GETEXPR_PRINT_WHEN_LOC
		
	case m.lcCalledFrom = "FieldExpression"
		cCaptionText = GETEXPR_FIELD_EXPR_LOC
		
	case m.lcCalledFrom = "OleboundField"
		cCaptionText = GETEXPR_OLEB_FIELD_LOC
		
	case m.lcCalledFrom = "OleboundExpression"
		cCaptionText = GETEXPR_OLEB_EXPR_LOC
		
	case m.lcCalledFrom = "BandGroupOnExpression"
		cCaptionText = GETEXPR_GROUP_ON_LOC
		
	case m.lcCalledFrom = "VariableValueToStore"
		cCaptionText = GETEXPR_VALUE_TO_STORE_LOC
		
	case m.lcCalledFrom = "VariableInitialValue"
		cCaptionText = GETEXPR_INITIAL_VALUE_LOC
		
	case m.lcCalledFrom = "BandOnEntryExpression"
		cCaptionText = GETEXPR_BAND_ON_ENTRY_LOC
		
	case m.lcCalledFrom = "BandOnExitExpression" 
		cCaptionText = GETEXPR_BAND_ON_EXIT_LOC
		
	case m.lcCalledFrom = "TargetAliasExpression"
		cCaptionText = GETEXPR_TARGET_ALIAS_LOC

	otherwise
		*------------------------------
		* Fix for SP2:
		*------------------------------
		*cCaptionText = ""
		cCaptionText = m.lcCalledFrom

	endcase

	*-------------------------------------
	* Use the right data session to see any open tables:
	*-------------------------------------
	set datasession to (loEvent.defaultSessionId)

	if empty(m.lcDataType )
		if empty( m.lcDefaultExpr )
			getexpr m.cCaptionText ;
				to m.cExpression
		else
			getexpr m.cCaptionText ;
				to m.cExpression ;
				default m.lcDefaultExpr
		endif
	else	
		if empty( m.lcDefaultExpr )
			getexpr m.cCaptionText ;
				to m.cExpression ;
				type m.lcDataType 
		else
			getexpr m.cCaptionText ;
				to m.cExpression ;
				type m.lcDataType ;
				default m.lcDefaultExpr
		endif
	endif
	
	*-------------------------------------
	* Go back to the FRX data session:
	*-------------------------------------
	set datasession to (loEvent.FrxSessionId)

endcase

return m.cExpression
endfunc

enddefine 

#include frxBuilder.h

*=================================================
* Class: DesignerEventFilter
*
* An abstract superclass for programmatic Filters
*=================================================
define class DesignerEventFilter as Custom

	allowToContinue = .T.

	procedure execute( oEvent )
		*--------------------------------------------
		* decide whether or not to process the event
		*--------------------------------------------
		THIS.allowToContinue = .T.
		*--------------------------------------------
		* You can alter oEvent.returnFlags to suit
		*--------------------------------------------
		return 
	endproc
	
enddefine

	
*=================================================
* Class: ProtectionFilter
*
* Protection filter is instantiated up front 
* to handle some types of events immediately.
*=================================================
define class ProtectionFilter as DesignerEventFilter
	
procedure execute( oEvent )
	
	if not oEvent.Protected
		*----------------------------------------
		* Only process this filter if the MODIFY REPORT
		* command used the PROTECTED keyword:
		*----------------------------------------
		THIS.allowToContinue = .T.
		return 
	endif
	
	local ofrxHelper
	oFrxHelper = oEvent.frxCursor

	local nProtFlags
	
	*-----------------------------------------
	* check for Object-level protection:
	*-----------------------------------------

	if OBJTYPE <> FRX_OBJTYP_REPORTHEADER
	
		nProtFlags = ofrxHelper.BinstringToInt( frx.ORDER )
		
		do case
		case oEvent.eventType = FRX_BLDR_EVENT_PROPERTIES and ;
			 inlist( oEvent.objType, FRX_OBJTYP_LABEL, FRX_OBJTYP_FIELD, FRX_OBJTYP_RECTANGLE, FRX_OBJTYP_LINE, FRX_OBJTYP_PICTURE ) and ;
			 bittest( m.nProtFlags, FRX_PROTECT_OBJECT_HIDE )

			THIS.allowToContinue = .F.
		  	return

		case oEvent.eventType = FRX_BLDR_EVENT_PROPERTIES and ;
			 inlist( oEvent.objType, FRX_OBJTYP_LABEL, FRX_OBJTYP_FIELD, FRX_OBJTYP_RECTANGLE, FRX_OBJTYP_LINE, FRX_OBJTYP_PICTURE ) and ;
			 bittest( m.nProtFlags, FRX_PROTECT_OBJECT_NO_SELECT )
		 
			THIS.allowToContinue = .F.
		  	return

		endcase
	endif	

	*-----------------------------------------
	* Report Level Protection:
	*-----------------------------------------
	
	locate for OBJTYPE = FRX_OBJTYP_REPORTHEADER
	nProtFlags = ofrxHelper.BinstringToInt( frx.ORDER )
	go oEvent.defaultRecno in frx
	
	do case
	
	*----------------------------------------
	* Is "Open Data Environment" Protected ?
	*----------------------------------------
	case oEvent.eventType = FRX_BLDR_EVENT_DATAENV and ;
		 bittest( m.nProtFlags, FRX_PROTECT_REPORT_NO_DATAENV)
		 
		=messagebox( FEATURE_IS_PROTECTED_LOC, 0+64 )
		THIS.allowToContinue = .F.
	  	return
		
	*----------------------------------------
	* Is "Optional Bands" Protected ?
	*----------------------------------------
	case oEvent.eventType = FRX_BLDR_EVENT_OPTIONALBANDS and ;
		 bittest( m.nProtFlags, FRX_PROTECT_REPORT_NO_OPTBAND )
		 
		=messagebox( FEATURE_IS_PROTECTED_LOC, 0+64 )
		THIS.allowToContinue = .F.
	  	return

	*----------------------------------------
	* Is "Data Grouping" Protected ?
	*----------------------------------------
	case oEvent.eventType = FRX_BLDR_EVENT_DATAGROUPING and ;
		 bittest( m.nProtFlags, FRX_PROTECT_REPORT_NO_GROUP )
		 
		=messagebox( FEATURE_IS_PROTECTED_LOC, 0+64 )
		THIS.allowToContinue = .F.
	  	return

	*----------------------------------------
	* Is "Variables" Protected ?
	*----------------------------------------
	case oEvent.eventType = FRX_BLDR_EVENT_VARIABLES and ;
		 bittest( m.nProtFlags, FRX_PROTECT_REPORT_NO_VARIABLES )
		 
		=messagebox( FEATURE_IS_PROTECTED_LOC, 0+64 )
		THIS.allowToContinue = .F.
	  	return

	*----------------------------------------
	* Is "Switch to Preview Mode" Protected ?
	*----------------------------------------
	case oEvent.eventType = FRX_BLDR_EVENT_PREVIEWMODE and ;
		 bittest( m.nProtFlags, FRX_PROTECT_REPORT_NO_PREVIEW )
		 
		=messagebox( FEATURE_IS_PROTECTED_LOC, 0+64 )
		THIS.allowToContinue = .F.
	  	return

	*----------------------------------------
	* Is "Report->Import Data Environment" Protected ?
	*----------------------------------------
	case oEvent.eventType = FRX_BLDR_EVENT_IMPORTDE and ;         
		bittest( m.nProtFlags, FRX_PROTECT_REPORT_NO_DATAENV )

		=messagebox( FEATURE_IS_PROTECTED_LOC, 0+64 )
		THIS.allowToContinue = .F.
	  	return

	*----------------------------------------
	* Is "Run Report"/File->Print Protected ?
	*----------------------------------------
	case oEvent.eventType = FRX_BLDR_EVENT_PRINT and ;
		bittest( m.nProtFlags, FRX_PROTECT_REPORT_NO_PRINT )

		=messagebox( FEATURE_IS_PROTECTED_LOC, 0+64 )
		THIS.allowToContinue = .F.
	  	return
	
	*----------------------------------------
	* Is "Quick Report from menu" Protected ?
	*----------------------------------------
	case oEvent.eventType = FRX_BLDR_EVENT_QUICKREPORT and ;
		bittest( m.nProtFlags, FRX_PROTECT_REPORT_NO_QUICKREPORT )

		=messagebox( FEATURE_IS_PROTECTED_LOC, 0+64 )
		THIS.allowToContinue = .F.
	  	return


	* THIS IS CURRENTLY THE ONLY WAY TO GET AT REPORT PROPERTIES...

	*----------------------------------------
	* Is "Page Layout" Protected ?
	*----------------------------------------
*!*		case oEvent.eventType = FRX_BLDR_EVENT_PROPERTIES and ;
*!*			 oEvent.objType   = FRX_OBJTYP_REPORTHEADER and ;
*!*			 bittest( m.nProtFlags, FRX_PROTECT_REPORT_NO_PAGESETUP )
*!*			 
*!*			=messagebox( FEATURE_IS_PROTECTED_LOC, 0+64 )
*!*			THIS.allowToContinue = .F.
*!*		  	return

	endcase
	THIS.allowToContinue = .T.
  	return
endproc
		
enddefine

*=================================================
* Class: QuickReportFilter
*
* Performs QUICK REPORT event filtering.
* During a normal quick report, the Designer creates 
* a series of label and field objects automatically.
* We need to suppress the ReportBuilder's inclination 
* to pop up a dialog for each one as it is created.
*=================================================
define class QuickReportFilter as DesignerEventFilter

procedure execute( oEvent )
	
	if ;
		oEvent.commandClauses.IsQuickReportFromMenu ;
	or ;
		not empty( oEvent.commandClauses.From ) and ;
  		oEvent.eventType = FRX_BLDR_EVENT_OBJECTCREATE

		THIS.allowToContinue = .F.
	  	return
	endif
	THIS.allowToContinue = .T.
  	return
endproc
	
enddefine

*=================================================
* Class: PasteUnProtectFilter
*
* if in a PROTECTED design session, remove any 
* protection flags from a pasted object.
* This is so OBJECT_NO_DELETE objects that get copied 
* and pasted do not themselves have NO_DELETE protection
* (for example).
* Protection flags are stored in the frx.ORDER column.
*=================================================
define class PasteUnProtectFilter as DesignerEventFilter

procedure execute( oEvent )

	if not oEvent.Protected
		*----------------------------------------
		* No need to continue. This filter only
		* applies if the MODIFY REPORT command 
		* used the PROTECTED keyword:
		*----------------------------------------
		THIS.allowToContinue = .T.
	  	return
	endif

	if oEvent.eventType = FRX_BLDR_EVENT_OBJECTPASTE

		*--------------------------------------
		* Locate the object(s) with CURPOS = .T.
		* and replace the ORDER column with ""
		* to remove any existing protection flags:
		*--------------------------------------
		locate for CURPOS and recno() > 1
		do while found()
			replace frx.ORDER with ""

			*--------------------------------------
			* We updated the cursor. Set the reload flag:
			*--------------------------------------
			oEvent.setReloadChanges(.T.)

			continue
		enddo
		
		go oEvent.defaultRecno in frx
		
	endif
	 	
	*--------------------------------------
	* Now that we've done our job, continue:
	*--------------------------------------
	THIS.allowToContinue = .T.
  	return

endproc

enddefine