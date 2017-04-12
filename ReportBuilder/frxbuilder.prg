*=======================================================
* Report Builder - main program
*
* In VFP9, a program or app may be assigned as the 
* "Report Builder" application:
*
*    _REPORTBUILDER = "reportbuilder.app"
*
* This program is the main program of the application
* that forms the default report builder implementation.
*
* rnRetVal is passed by reference. It must be assigned
* the appropriate return code to the Designer before returning.
*
*=======================================================
#include frxBuilder.h

lparameters riReturnFlags, iEventType, oCmdClauses, iDefSessionId 

*--------------------------------------------------------------
* Ensure some essential files are built in:
*--------------------------------------------------------------
external table     frxbuilder.dbf
external class     frxhandlers.vcx
external procedure frxhandlers.prg
external procedure frxutils.prg
external procedure frxcommon.prg
external class     frxbuilder2.vcx

*--------------------------------------------------------------
* Scoped to datasession, no need to restore:
*--------------------------------------------------------------
set talk off

*--------------------------------------------------------------
* Put the entire processing inside a class to avoid 
* changing data sessions in a form with a private datasession.
* See below for class definition:
*--------------------------------------------------------------
local oRepBuilder
oRepBuilder = newobject("ReportBuilder","frxbuilder.prg")
riReturnFlags = oRepBuilder.ProcessEvent( pcount(), m.riReturnFlags, @m.iEventType, m.oCmdClauses, m.iDefSessionId )
	
*--------------------------------------------------------------
* rnRetVal (passed by reference) has been assigned. 
*--------------------------------------------------------------
return


*=======================================================
* ReportBuilder class definition
*
* It must accept the parameters passed to it from the 
* Report Designer, process the event, and set the value
* of the rnRetVal parameter (passed by reference) appropriately.
*
* It does this by instantiating the frxEvent class and 
* asking it to handle itself, passing it the parameters. 
*=======================================================
define class ReportBuilder as custom

procedure ProcessEvent( iParamCount, iParam1, iEventType, oCmdClauses, iDefSessionId )

	*--------------------------------------------------------------
	* Set up our return flags for returning to the Designer:
	*--------------------------------------------------------------
	local iReturnFlags
	iReturnFlags = 0

	*--------------------------------------------------------------
	* Need to SET TALK OFF in datasession 1 for the duration,
	* because we run some code there:
	*--------------------------------------------------------------
	local iFrxSessionId, lSetTalk
	iFrxSessionId = set("DATASESSION")
	set datasession to 1
	if set("TALK") = "ON"
		set talk off
		lSetTalk = .T.
	endif

	*--------------------------------------------------------------
	* Best to surround the whole thing in a TRY/CATCH block:
	*--------------------------------------------------------------
	try

		*--------------------------------------------------------------
		* Ensure the parameters are acceptable, generate warning
		* messagebox if not valid:
		*--------------------------------------------------------------	
		local lOkToContinue
		lOkToContinue = .F.
	
		do case
		case m.iParamCount < 1
			*--------------------------------------------
			*  Force the options dialog:
			*--------------------------------------------
			m.iParam1	= 1			
			lOkToContinue 	= .T.

		case type('m.iParam1') <> 'N'
			*--------------------------------------------
			*  invalid parameters :
			*--------------------------------------------
			=messagebox( RB_INVALID_PARAMETERS_LOC, 48, DEFAULT_MBOX_TITLE_LOC )
			iReturnFlags = 0
			lOkToContinue = .F.

		case m.iParamCount = 1 and ;
		     inlist(m.iParam1, 0, 1, 2, 5, 6, 7, 8 )
			*--------------------------------------------
			*  0 Instantiate the public _oReportBuilder variable (THIS)
			*  1 displays the options dialog
			*  2 prompts for a FRX file to browse
			*  5 prompts for a destination file copy of registry
			*  6 adds a prompt to the Tools menu for Options dialog
			*  7 Launch the Event Hander Registry Explorer window
			*  8 Band Object Explorer
			*--------------------------------------------
			lOkToContinue = .T.

		case m.iParamCount = 2 and m.iParam1 = 0
			*--------------------------------------------
			*  0, oRef  place oEvent instance reference in m.oRef
			*--------------------------------------------
			iEventType = newobject("frxEvent","frxBuilder.vcx")
			lOKToContinue = .F.
			
		case m.iParamCount = 2 and ;
		     inlist(m.iParam1, 2, 3, 4, 5, 8 )
			*--------------------------------------------
			*  2,<file> browses the file
			*  3,<file> sets the registry table
			*  4, n     sets the handle mode (1-4)
			*  5,<file> copies the internal registry table
			*  8, <frx> displays the Band Object Explorer
			*--------------------------------------------
			lOkToContinue = .T.
		     
		case m.iParamCount = 4 and ;
			type("oCmdClauses")="O" and ;
			m.iParam1 = -1
			*--------------------------------------------
			* This is normal operation, called from Designer
			*--------------------------------------------
			lOkToContinue = .T.
			
		otherwise
			*--------------------------------------------
			*  invalid parameters :
			*--------------------------------------------
			=messagebox( RB_INVALID_PARAMETERS_LOC, 48, DEFAULT_MBOX_TITLE_LOC )
			iReturnFlags = 0
			lOkToContinue = .F.

		endcase

		if m.lOkToContinue

			*--------------------------------------------------------------
			* Bug# 429815
			* Need to duplicate certain datasession-scoped, locale-specific settings
			* from the default datasession, if we have been passed one:
			*--------------------------------------------------------------
			if type("m.iDefSessionId") = "N"
				
				if m.iDefSessionId <> m.iFrxSessionId

					set datasession to (m.iDefSessionId)
					local lcPoint, lcSep, lcDate
					lcPoint = set("POINT")
					lcSep   = set("SEPARATOR")		
					lcDate  = set("DATE")

					set datasession to (m.iFrxSessionId)
					set point     to m.lcPoint
					set separator to m.lcSep
					set date      to &lcDate
					
				endif
			endif
			
			*--------------------------------------------------------------
			* Scoped to product, need to save/restore:
			*--------------------------------------------------------------
			local lSetNotify, lSetNotify2, lSetEsc, lSetProc, iSys3054
			lSetNotify  = (set("NOTIFY",1) = "ON")
			lSetNotify2 = (set("NOTIFY")   = "ON")
			lSetEsc     = (set("ESCAPE")   = "ON")
			iSys3054    = int(val(sys(3054)))
			if m.lSetNotify
				set notify cursor off
			endif
			if m.lSetNotify
				set notify off
			endif
			if m.lSetEsc
				set escape off
			endif
			if m.iSys3054 > 0
				sys(3054,0)
			endif

			*-------------------------------------
			* Fix in SP2: 
			*-------------------------------------
			local lSetCompat
			lSetCompat  = set("COMPATIBLE")  
			if m.lSetCompat <> "OFF"
				set compatible off
			endif

			*-------------------------------------
			* SP2: Scoped to datasession, so our pref:
			*-------------------------------------
*** DH 11/26/2009: this sets DELETED off when
*** called with "register table" (3) so we'll
*** save and restore the current value
			local lSetDeleted
			lSetDeleted = set('DELETED') = 'ON'
*** DH 11/26/2009: end of new code
			set deleted off

			*--------------------------------------------
			* Instantiate the frxEvent class,
			* pass it the parameters, and ask it to 
			* handle itself.
			* (see frxEvent.prg for more information)
			*--------------------------------------------
			local oEvent
			oEvent   = newobject("frxEvent","frxBuilder.vcx")
			iReturnFlags = oEvent.Execute( m.iParam1, m.iEventType, m.oCmdClauses, m.iDefSessionId )
			release oEvent

			if DEBUG_WAITMSG_WHILE_EXECUTING
				wait clear
			endif

			*-------------------------------------
			* Fix in SP2: 
			*-------------------------------------
			if m.lSetCompat <> "OFF"
				set Compatible &lSetCompat
			endif

			*--------------------------------------------------------------
			* Restore product-scoped SET commands:
			*--------------------------------------------------------------
			if m.iSys3054 > 0
				sys(3054,m.iSys3054)
			endif
			if m.lSetNotify
				set notify cursor on
			endif
			if m.lSetNotify2
				set notify on
			endif
			if m.lSetEsc
				set escape on
			endif
*** DH 11/26/2009: restore DELETED
			if m.lSetDeleted
				set deleted on
			endif m.lSetDeleted
*** DH 11/26/2009: end of new code

		endif
		
	*--------------------------------------------------------------
	* Any error or exception handled here
	*--------------------------------------------------------------
	catch to oError

		*--------------------------------------------------------------
		* Build up the error message string - not completely localized. 
		*--------------------------------------------------------------
		local cErrorMsg
		cErrorMsg = oError.message + c_CR + ;
		            "Line " + transform(oError.lineNo) + " in " + oError.procedure + "()"

		if not empty( oError.lineContents )
			cErrorMsg = m.cErrorMsg + ":" + c_CR + oError.lineContents
		endif

		*------------------------------------------------------
		* Was there a user value thrown?
		*------------------------------------------------------
		if not empty( oError.userValue )
			cErrorMsg = m.cErrorMsg + c_CR + "Additional info: " + oError.userValue
		endif

		=messagebox( RB_EXCEPTION_HEADER_LOC + c_CR2 + m.cErrorMsg, 0+16, DEFAULT_MBOX_TITLE_LOC )

		do case
		case type("m.iEventType") = "N" and ;
			 inlist( m.iEventType, ;
					 FRX_BLDR_EVENT_REPORTSAVE, ;
					 FRX_BLDR_EVENT_REPORTCLOSE  )
			*--------------------------------------------------------------
			* Allow event to proceed:
			*--------------------------------------------------------------
			iReturnFlags = FRX_REPBLDR_IGNORE_EVENT + FRX_REPBLDR_DISCARD_CHANGES
			
		otherwise
			*--------------------------------------------------------------
			* This is most likely to be the correct response 
			* in this situation:
			*--------------------------------------------------------------
			iReturnFlags = FRX_REPBLDR_HANDLE_EVENT + FRX_REPBLDR_DISCARD_CHANGES

		endcase

	finally
		*--------------------------------------------------------------
		* Need to restore SET TALK in datasession 1:
		*--------------------------------------------------------------
		if m.lSetTalk
			set datasession to 1
			set talk on	
			set datasession to (m.iFrxSessionId)
		endif
		
	endtry

	*--------------------------------------------------------------
	* Return the result flags to the Designer:
	*--------------------------------------------------------------
	return m.iReturnFlags
	
endproc
	
enddefine