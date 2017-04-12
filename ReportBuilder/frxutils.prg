* Contains:
*
*	FormatExpressionParser
*	frxDeLoader
*	ErrorHandler
*	frxMetaData
*   frxDocProperties

#include frxBuilder.h

*=================================================
* Class: FormatExpressionParser
*=================================================
define class FormatExpressionParser as Custom

	TemplateString   = ""
	FormatCodes      = ""
	Value            = ""

	procedure Value_Access
		if not empty( THIS.FormatCodes )
			return "@" + alltrim(THIS.FormatCodes) + " " + alltrim(THIS.TemplateString)
		else
			return alltrim(THIS.TemplateString)
		endif
	endproc
	
	procedure Value_Assign
		lparameter lcFormatExpr

		THIS.Value = m.lcFormatExpr

		if left(m.lcFormatExpr, 1) == "@"
			if " " $ m.lcFormatExpr
				THIS.FormatCodes    = left(   m.lcFormatExpr, at(" ", m.lcFormatExpr)-1 )				
				THIS.TemplateString = substr( m.lcFormatExpr, at(" ", m.lcFormatExpr)+1 )
			else
				THIS.FormatCodes    = substr(m.lcFormatExpr,2)
				THIS.TemplateString = ""
			endif
		else
			THIS.FormatCodes    = ""				
			THIS.TemplateString = m.lcFormatExpr
		endif
	endproc

enddefine

*===========================================
* Class frxDeLoader
*
* Utility methods for loading a data environment
* into an FRX file.
*
*===========================================

define class frxDeLoader as custom

name         = "frxDeLoader"
deClass      = ""
deClassLib   = ""

* Fix for SP1: Report the error:
errorMessage = ""

* Fix for SP1: Support different modes of handling the path:
*              0 = full path is used in the code
*              1 = path is changed to relative path
*              2 = paths are stripped - assume class library is in scope
pathMode     = 0

*-------------------------------------------------------
* LoadFromReport( REPORTFILE )
*
* Replaces the current FRX cursor's DE records with ones 
* copied from another FRX file.
*
* Assumes: frx is currently selected
*
* Returns:
*	0 = Success
*   1 = error loading report
*-------------------------------------------------------
procedure LoadFromReport
lparameters cFrxFile

private iRetval, frxAlias
iRetVal = 0
frxAlias   = alias()

try 
	use (m.cFrxFile) again in 0 shared noupdate alias srcFrx
catch to oError
	iRetVal = 1
	* Maybe change this later:
	local cErrorMsg
	cErrorMsg = oError.message + c_CR + ;
	            "Line " + transform(oError.lineNo) + " in " + oError.procedure + "()"
	if not empty( oError.lineContents )
		cErrorMsg = m.cErrorMsg + ":" + c_CR + oError.lineContents
	endif
	if not empty( oError.userValue )
		cErrorMsg = m.cErrorMsg + c_CR + "Additional info: " + oError.userValue
	endif
	=messagebox( LOAD_DE_ERROR_LOC+c_CR+m.cErrorMsg, 0+48, DEFAULT_MBOX_TITLE_LOC )
endtry
if m.iRetVal = 0
	select (m.frxAlias)
	*--------------------------------------------
	* delete the current DE records in the FRX:
	*--------------------------------------------
	delete for inlist( OBJTYPE, FRX_OBJTYP_DATAENV, FRX_OBJTYP_DATAOBJ )

	select srcFrx
	scan for inlist( OBJTYPE, FRX_OBJTYP_DATAENV, FRX_OBJTYP_DATAOBJ )
		scatter memo to tmpRecord
		scatter memo name oTempRec
		insert into (frxAlias) from name oTempRec
	endscan			
	
endif
if used( "srcFrx" )
	use in srcFrx 
endif
select (m.frxAlias)
return m.iRetVal

endproc

*-------------------------------------------------------
* LoadFromClass( CLASS, CLASSLIB )
*
* Replaces the current FRX cursor's DE records with ones generated 
* from a DataEnvironment class. Records are linked to the DE class 
* through method code.
*
* Assumes: frx is currently selected
*
* Returns:
*	0 = Success
*   1 = error instantiating class
*   2 = invalid base class type
*-------------------------------------------------------
procedure LoadFromClass
lparameters cDEClass, cDeClasslib

local curSel
curSel = select(0)

* Used by GetMethodCode():
THIS.DEclass    = m.cDeClass
THIS.DEclasslib = m.cDeClasslib

*------------------------------------
* Helper class:
*------------------------------------
local ox
ox = newobject("frxClassUtil","frxBuilder.vcx")

*------------------------------------
* instantiate the DE class, with error trapping for any 
* possible silly init code. 
* (Note: Can't use NEWOBJECT(...,0) because that is not 
* supported under runtime.)
*------------------------------------
local oDe, oDeObj
oDe = ox.getInstanceOf( THIS.DEClass, THIS.DEClasslib )
if ox.errored
	*------------------------------------
	* Error instantiating class:
	*------------------------------------
	THIS.errorMessage = ox.ErrorMessage
	return 1
endif
	
if isnull( m.oDE )
	*------------------------------------
	* Error instantiating class:
	*------------------------------------
	THIS.errorMessage = ox.ErrorMessage
	return 1
endif

*------------------------------------
* Check the base class type:
*------------------------------------
if oDe.Baseclass <> "Dataenvironment"
	*------------------------------------
	* Error: invalid base class:
	*------------------------------------
	release oDe
	clear class (THIS.DEClass)
	return 2
endif

*--------------------------------------------
* Fix for SP1: Now that we've instantiated it
*              we can apply the path mode:
*--------------------------------------------
do case
case THIS.pathMode = 0
	* use full path (i.e. no change)
	*THIS.DEclasslib = THIS.DEclasslib
	
case THIS.pathMode = 1
	* use relative path:
	THIS.DEclasslib = lower(sys(2014, THIS.DEclasslib ))
	
case THIS.pathMode = 2
	* strip path off completely:
	THIS.DEclasslib = justfname( THIS.DEclasslib )

endcase				

*--------------------------------------------
* Fix for SP1:
* Ensure that the workarea is restored:
*--------------------------------------------
select (m.curSel)

*--------------------------------------------
* delete the current DE records in the FRX:
*--------------------------------------------
delete for inlist( OBJTYPE, FRX_OBJTYP_DATAENV, FRX_OBJTYP_DATAOBJ )
go bottom

*------------------------------------
* Load up the report:
*------------------------------------

local cExpr, cName, cMethods
store "" to cExpr, cName, cMethods

*------------------------------------
* delete the current DE records in the FRX:
* insert new ones based on the DE object:
*------------------------------------

*------------------------------------
* Save the current textmerge delimiters
* and set to default:
*------------------------------------
local lcTextMergeDelims
lcTextMergeDelims = set("TEXTMERGE",1)
set textmerge delimiters

*-----------------------------------------------
* Insert the data environment record:
* We're using some default values here, should be ok
*-----------------------------------------------
cName = "dataenvironment"

text to m.cExpr textmerge noshow pretext 7
	Top = 100
	Left = 117
	Width = 522
	Height = 327
	InitialSelectedAlias = "<< oDE.InitialSelectedAlias >>"
	DataSource = .NULL.
	Name = "Dataenvironment"
endtext

cMethods = THIS.GetMethodCode("dataenvironment")

THIS.insertDERecord( FRX_OBJTYP_DATAENV, m.cName, m.cExpr, m.cMethods )

*-----------------------------------------------
* insert each object record:
*-----------------------------------------------

*-----------------------------------------------
* Fix for SP1:
* Fill the data environment window sequentially
* in rows, not exceeding the maximum scrollable 
* area of the window (1500 x 1400)
*-----------------------------------------------
local iCurrentRow, iTop, iLeft
iCurrentRow = 1
iTop  = DE_OFFSET_FROM_TOP
iLeft = DE_OFFSET_FROM_LEFT

*-----------------------------------------------
* Fix for SP1:
* Check LOWER(.BaseClass) rather than CLASS because
* there may be subclassed DE objects in the DE.
*-----------------------------------------------
for each oDeObj in oDE.Objects 

	do case
		
	case lower(oDeObj.BaseClass) == "cursor"
		*-----------------------------------------------
		* Insert the cursor object record:
		*-----------------------------------------------

		cName = "cursor"
		
		if not empty( oDeObj.Database )
			text to m.cExpr textmerge noshow pretext 7
				Top = << m.iTop >>
				Left = << m.iLeft >>
				Height = << DE_OBJECT_HEIGHT >>
				Width = << DE_OBJECT_WIDTH >>
				Alias = "<< oDeObj.Alias >>"
				Database = << oDeObj.Database >>
				CursorSource = "<< oDeObj.Cursorsource >>"
				Name = "<< oDeObj.Name >>"
			endtext
		else
			text to m.cExpr textmerge noshow pretext 7
				Top = << m.iTop >>
				Left = << m.iLeft >>
				Height = << DE_OBJECT_HEIGHT >>
				Width = << DE_OBJECT_WIDTH >>
				Alias = "<< oDeObj.Alias >>"
				CursorSource = << oDeObj.Cursorsource >>
				Name = "<< oDeObj.Name >>"
			endtext
		endif		

		cMethods = THIS.GetMethodCode("cursor")
		
		THIS.insertDERecord( FRX_OBJTYP_DATAOBJ, m.cName, m.cExpr, m.cMethods )

	case lower(oDeObj.BaseClass) == "cursoradapter"
		*-----------------------------------------------
		* Insert the adapter object record:
		*-----------------------------------------------

		cName = "cursoradapter"

		*-------------------------------------------------------
		* Fix for SP1:
		* if oDeObj.CursorSchema is empty, the report designer 
		* will throw an error when it tries to reload the layout
		*-------------------------------------------------------
		if not empty( oDeObj.Cursorschema )

			text to m.cExpr textmerge noshow pretext 7
				Top = << m.iTop >>
				Left = << m.iLeft >>
				Height = << DE_OBJECT_HEIGHT >>
				Width = << DE_OBJECT_WIDTH >>
				CursorSchema = << oDeObj.Cursorschema >>
				Alias = "<< oDeObj.Alias >>"
				Name = "<< oDeObj.Name >>"
			endtext

			cMethods = THIS.GetMethodCode("cursoradapter")

			THIS.insertDERecord( FRX_OBJTYP_DATAOBJ, m.cName, m.cExpr, m.cMethods )
		else
			=messagebox( LOAD_DE_ERR_ADAPTERSCHEMA, 0+48, DEFAULT_MBOX_TITLE_LOC )
		endif
		
	case lower(oDeObj.BaseClass) == "relation"
		*-----------------------------------------------
		* Insert the relation object record:
		*-----------------------------------------------

		cName = "relation"

		text to m.cExpr textmerge noshow pretext 7
			ParentAlias = "<< oDeObj.ParentAlias >>"
			RelationalExpr = "<< oDeObj.RelationalExpr >>"
			ChildAlias = "<< oDeObj.ChildAlias >>"
			ChildOrder = "<< oDeObj.ChildOrder >>"
			OneToMany = << oDeObj.OneToMany >>
			Name = "<< oDeObj.Name >>"
		endtext

		cMethods = THIS.GetMethodCode("relation")

		THIS.insertDERecord( FRX_OBJTYP_DATAOBJ, m.cName, alltrim(m.cExpr), m.cMethods )
	
	endcase
	
	*----------------------------------
	* Set location of next object:
	*----------------------------------
	m.iLeft = m.iLeft + DE_OBJECT_LEFT_INCR
	if m.iLeft > (DE_MAX_WIDTH - DE_OBJECT_WIDTH)
		m.iCurrentRow = m.iCurrentRow + 1
		m.iLeft       = DE_OFFSET_FROM_LEFT
	endif
	
	iTop = DE_OFFSET_FROM_TOP + DE_OBJECT_TOP_INCR*(m.iCurrentRow-1)

endfor
release oDe
clear class (THIS.DEClass)

*------------------------------------
* Restore the original textmerge delimiters
* if necessary:
*------------------------------------
if m.lcTextMergeDelims <> set("TEXTMERGE",1)
	*-----------------------------------
	* They're using custom delimiters: 
	* Restore them
	*-----------------------------------
	local delimSize, leftDelim, rightDelim
	&& it's either 1 or 2:
	delimSize = int(len(m.lcTextMergeDelims)/2)
	leftDelim  = left(  m.lcTextMergeDelims, m.delimSize )
	rightDelim = right( m.lcTextMergeDelims, m.delimSize )
	set textmerge delimiters to m.leftDelim, m.rightDelim
endif

*------------------------------------
* Compile the TAG fields and place in TAG2:
*------------------------------------
local cSrcFile, cCmpCode
cSrcFile = addbs(sys(2023))+sys(3)

select (m.curSel)
locate for OBJTYPE = FRX_OBJTYP_DATAENV
scan rest

	=strtofile( TAG, m.cSrcFile+".PRG", 0 ) 
	compile (m.cSrcFile+".PRG")
	cCmpCode = filetostr( m.cSrcFile+".FXP" )
	replace tag2 with m.cCmpCode

	erase (m.cSrcFile+".PRG")
	erase (m.cSrcFile+".FXP")

endscan

return 0

endproc


*-------------------------------------------------------
* GetMethodCode( DATA_ENV_OBJECT_TYPE )
*
* Returns a string containing DE methods code
*-------------------------------------------------------
procedure GetMethodCode
lparameter lcObjectType

local cCode

do case
case upper(m.lcObjectType) == "DATAENVIRONMENT"

	*=====================	    
	text to m.cCode textmerge noshow pretext 6
	
	PROCEDURE AfterCloseTables
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	    *--------------------------------------------
	    * Fix for SP1: Add conditional test for valid object:
	    *--------------------------------------------
	    IF VARTYPE( THIS.BoundDE ) = "O" AND UPPER( THIS.BoundDE.BaseClass ) = "DATAENVIRONMENT"
	        IF THIS.BoundDE.AutoCloseTables
	            THIS.BoundDE.CloseTables()
	        endif
	    ENDIF
	ENDPROC	
	PROCEDURE BeforeOpenTables
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	    LOCAL loMember, laDEEvents[1], liMember, liMembers, loBoundMember
	    THIS.AddProperty( "BoundDE", NEWOBJECT( "<< THIS.DEClass >>", "<<THIS.DEClasslib >>" ))
	    IF VARTYPE( THIS.BoundDE ) = "O" AND UPPER( THIS.BoundDE.BaseClass ) = "DATAENVIRONMENT"
	        * Bind events here, skipping the Init and Destroy.
	        * The FRX DE and its members can only have base events,
	        * so not that much PEMSTATUS checking is necessary:
	        liMembers = AMEMBERS( laDEEvents, THIS, 1 )	    
	        FOR liMember = 1 TO m.liMembers
	            IF INLIST( UPPER( laDEEvents[ m.liMember, 1] ), "INIT", "DESTROY" )
	                LOOP
	            ENDIF
	            IF INLIST( UPPER( laDEEvents[ m.liMember, 2] ), "EVENT", "METHOD" )
	                BINDEVENT( THIS, ;
	                           laDEEvents[ m.liMember, 1], ;
	                           THIS.BoundDE, ;
	                           laDEEvents[ m.liMember, 1] )
	            ENDIF
	        ENDFOR
	        * Now do the members with appropriate checking,
	        * again skipping the Init and Destroy:
	        FOR EACH loMember IN THIS.Objects FOXOBJECT
	            IF PEMSTATUS( THIS.BoundDE, loMember.Name, 5 ) AND ;
	                UPPER( PEMSTATUS( THIS.BoundDE, loMember.Name, 3 )) = "OBJECT"
	                loBoundMember = EVAL( "THIS.BoundDE." + loMember.Name )
	                IF ( loBoundMember.BaseClass == loMember.BaseClass )
	                    liMembers = AMEMBERS( laDEEvents, m.loMember, 1 )
	                    FOR liMember = 1 to m.liMembers
	                        IF INLIST( UPPER( laDEEvents[ m.liMember, 1] ), "INIT", "DESTROY" )
	                            LOOP
	                        ENDIF
	                        IF INLIST( UPPER( laDEEvents[ m.liMember, 2] ), "EVENT", "METHOD" )
	                            BINDEVENT( THIS, ;
	                                       laDEEvents[ m.liMember, 1], ;
	                                       loBoundMember, ;
	                                       laDEEvents[ m.liMember, 1] )
	                        ENDIF
	                    ENDFOR
	                ENDIF
	            ENDIF            
	        ENDFOR
	        THIS.BoundDE.BeforeOpenTables()
	        *--------------------------------------------
	        * Fix for SP1: move inside condition:
	        *--------------------------------------------
	        IF THIS.BoundDE.AutoOpenTables
	            THIS.BoundDE.OpenTables()
	        ENDIF
	    ENDIF
	ENDPROC
	PROCEDURE Destroy
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	    LOCAL loMember
	    UNBIND( THIS )
	    FOR EACH loMember in THIS.Objects 
	        UNBIND( loMember )
	    ENDFOR
	    IF PEMSTATUS( THIS, "BoundDE", 5 ) AND UPPER( PEMSTATUS( THIS, "BoundDE", 3 )) = "PROPERTY"
	        THIS.BoundDE = NULL
	    ENDIF
	ENDPROC
	PROCEDURE Error
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	    LPARAMETERS nError, cMethod, nLine
	    DODEFAULT( m.nError, m.cMethod, m.nLine )
	ENDPROC	

	endtext
	*=====================	    

case upper(m.lcObjectType) == "CURSOR"
	* Basically, the only events are:
	*  Destroy, Error, Init

	*=====================	    
	text to m.cCode textmerge noshow pretext 6

	PROCEDURE Error
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	    LPARAMETERS nError, cMethod, nLine
	    DODEFAULT( m.nError, m.cMethod, m.nLine )
	ENDPROC	

	endtext
	*=====================	    
	

case upper(m.lcObjectType) == "CURSORADAPTER"

	*=====================	    
	text to m.cCode textmerge noshow pretext 6

	PROCEDURE AfterCursorAttach
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cAlias, lResult
		DODEFAULT( m.cAlias, m.lResult )
	ENDPROC
	PROCEDURE AfterCursorClose
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cAlias, lResult
		DODEFAULT( m.cAlias, m.lResult )
	ENDPROC
	PROCEDURE AfterCursorDetach
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cAlias, lResult
		DODEFAULT( m.cAlias, m.lResult )
	ENDPROC
	PROCEDURE AfterCursorFill
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS luseCursorSchema, lNoDataOnLoad, cSelectCmd, lResult
		DODEFAULT( m.luseCursorSchema, m.lNoDataOnLoad, m.cSelectCmd, m.lResult )
	ENDPROC
	PROCEDURE AfterCursorRefresh
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cSelectCmd, lResult
		DODEFAULT( m.cSelectCmd, m.lResult )
	ENDPROC
	PROCEDURE AfterCursorUpdate
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS nRows, lTableUpdateResult, cErrorArray
		DODEFAULT( m.nRows, m.lTableUpdateResult, m.cErrorArray )
	ENDPROC
	PROCEDURE AfterDelete
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cFldState, lForce, cDeleteCmd, lResult
		DODEFAULT( m.cFldState, m.lForce, m.cDeleteCmd, m.lResult )
	ENDPROC
	PROCEDURE AfterInsert
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cFldState, lForce, cInsertCmd, lResult
		DODEFAULT( m.cFldState, m.lForce, m.cInsertCmd, m.lResult )
	ENDPROC
	PROCEDURE AfterRecordRefresh
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
		DODEFAULT()
	ENDPROC
	PROCEDURE AfterUpdate
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cFldState, lForce, nUpdateType, cUpdateInsertCmd, cDeleteCmd, lResult
		DODEFAULT( m.cFldState, m.lForce, m.nUpdateType, m.cUpdateInsertCmd, m.cDeleteCmd, m.lResult )
	ENDPROC
	PROCEDURE BeforeCursorAttach
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cAlias
		DODEFAULT( m.cAlias )
	ENDPROC
	PROCEDURE BeforeCursorClose
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cAlias
		DODEFAULT( m.cAlias )
	ENDPROC
	PROCEDURE BeforeCursorDetach
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cAlias
		DODEFAULT( m.cAlias )
	ENDPROC
	PROCEDURE BeforeCursorFill
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS luseCursorSchema, lNoDataOnLoad, cSelectCmd
		DODEFAULT( m.luseCursorSchema, m.lNoDataOnLoad, m.cSelectCmd )
	ENDPROC
	PROCEDURE BeforeCursorRefresh
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cSelectCmd
		DODEFAULT( m.cSelectCmd )
	ENDPROC
	PROCEDURE BeforeCursorUpdate
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS nRows, lForce
		DODEFAULT( m.nRows, m.lForce )
	ENDPROC
	PROCEDURE BeforeDelete
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cFldState, lForce, cDeleteCmd
		DODEFAULT( m.cFldState, m.lForce, m.cDeleteCmd )
	ENDPROC
	PROCEDURE BeforeInsert
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cFldState, lForce, cInsertCmd
		DODEFAULT( m.cFldState, m.lForce, m.cInsertCmd )
	ENDPROC
	PROCEDURE BeforeRecordRefresh
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
		DODEFAULT()
	ENDPROC
	PROCEDURE BeforeUpdate
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	LPARAMETERS cFldState, lForce, nUpdateType, cUpdateInsertCmd, cDeleteCmd
		DODEFAULT( m.cFldState, m.lForce, m.nUpdateType, m.cUpdateInsertCmd, m.cDeleteCmd )
	ENDPROC
	PROCEDURE Error
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	    LPARAMETERS nError, cMethod, nLine
	    DODEFAULT( m.nError, m.cMethod, m.nLine )
	ENDPROC	

	endtext
	*=====================	    

case upper(m.lcObjectType) == "RELATION"

	*=====================	    
	text to m.cCode textmerge noshow pretext 6

	PROCEDURE Error
	*-----------------------------------------------------*
	<< DE_METHOD_HEADER_COMMENT_LOC >>
	*-----------------------------------------------------*
	    LPARAMETERS nError, cMethod, nLine
	    DODEFAULT( m.nError, m.cMethod, m.nLine )
	ENDPROC	

	endtext
	*=====================	    
	
otherwise
	cCode = ""
	
endcase
return m.cCode

endproc

*-------------------------------------------------------
* InsertDERecord( ID, NAME, EXPR, CODE )
*
* Inserts a data-environment object record into an FRX. 
* Assumes that the record pointer is located appropriately.
*-------------------------------------------------------
procedure InsertDERecord
lparameters liObjType, lcName, lcExpr, lcMethods

insert blank
replace ;
	PLATFORM 	with FRX_PLATFORM_WINDOWS, ;
	OBJTYPE  	with m.liObjType, ;
	NAME		with m.lcName, ;
	EXPR		with m.lcExpr, ;
	TAG         with m.lcMethods, ;
	ENVIRON		with .F., ;
	CURPOS		with .F.

return

endproc

enddefine

*===========================================
* Class ErrorHandler
*
* A basic error handler.
*
* Useage:
* x = newobject("ErrorHandler","frxUtils.prg")
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

cErrorMsg = m.cErrorMsg + c_CR + ;
			"Line " + transform(m.iLine) + " in " + m.cMethod + "()"

if not empty( message(1) )
	cErrorMsg = m.cErrorMsg + ":" + c_CR + message(1) 
endif
*if not empty( sys(2018) )
*	cErrorMsg = m.cErrorMsg + c_CR + sys(2018) 
*endif
if parameters() > 3
	cErrorMsg = m.cErrorMsg + c_CR2 + oRef.Name + ".Error()"
endif	

*------------------------------------------------------
* Save the error message so that it can be retrieved
*------------------------------------------------------
THIS.errorText = m.cErrorMsg

if DEBUG_SUSPEND_ON_ERROR
	cErrorMsg = m.cErrorMsg + c_CR2 + "Do you want to suspend execution?"

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

*===========================================
* Class frxMetaData
*
* Reading and writing metadata from the 
* STYLE field of the frx
*
* DEPRECATED: This class is no longer used.
*===========================================
define class frxMetaData as custom

	errorMsg   = ""
	declass    = ""
	declasslib = ""
	execute    = ""
	execwhen   = ""
	tag        = "frx"
	xpath      = XPATH_REPORTDATA_DEFAULT  && "/VFPData/reportdata[@type='R']"
	
*-------------------------------------------------
* procedure LoadFromFrx()
*
* Reads the XML metadata from the STYLE column of the 
* alias specified by the TAG property, and populates the 
* .DeClass, .DeClassLib, .Execute, and .ExecWhen properties.
*
* Assumes: we are located on the right record.
*-------------------------------------------------
procedure LoadFromFrx
lparameter lcFrxAlias

THIS.errorMsg = ""

if empty(m.lcFrxAlias)
	lcFrxAlias = THIS.Tag
endif	

local cursel, cXml, oDom, oNode
cursel = select(0)
select (m.lcFrxAlias)

*------------------------------------------------------
* Initialise to default:
*------------------------------------------------------
THIS.declass 	= ""
THIS.declasslib	= ""
THIS.execute    = ""
THIS.execwhen	= ""

*------------------------------------------------------
* If the STYLE field is empty, we don't need to 
* try reading it with the DOM. We'll use the default
* values.
*------------------------------------------------------
if empty( STYLE )
	return 
endif

*------------------------------------------------------
* Create a DomDocument:
*------------------------------------------------------
oDom = null
try 
	try 
		oDom = createobject("MSXml.DomDocument")
	catch 
		*-------------------------------------------
		*  "Unable to create MSXml.DomDocument instance. 
		*   Metadata XML may not be available."
		*-------------------------------------------
		error METADATA_DOM_CREATE_FAILED_LOC
	endtry

	*------------------------------------------------------
	* We have a valid DOM. 
	*------------------------------------------------------
	
	*------------------------------------------------------
	* Read the XML metadata out of the STYLE tag:
	*------------------------------------------------------
	cXml = alltrim(STYLE)

	if oDom.loadXML( m.cXml )
		
		*------------------------------------
		* Check for valid root node/schema:
		*------------------------------------
		
		if oDom.firstChild.nodeName = "VFPData"
	
			*------------------------------------
			* look for our element:
			*------------------------------------		
			oNode = oDom.selectSingleNode( THIS.xpath )
			
			if isnull ( m.oNode )
				*---------------------------------------------
				* Looks like our node isn't in the structure.
				* We'll use default values for now, and the 
				* .SaveToFrx() will create the node later.
				*---------------------------------------------
			else	
				*---------------------------------------
				* We have our element. Read out the 
				* attributes we're interested in:
				*---------------------------------------
				THIS.declass    = nvl( oNode.getAttribute("declass"),    "" )
				THIS.declasslib = nvl( oNode.getAttribute("declasslib"), "" )	
				THIS.execute    = nvl( oNode.getAttribute("execute"),    "" )	
				THIS.execwhen   = nvl( oNode.getAttribute("execwhen"),   "" )	
			endif				
		else
			*------------------------------------------
			* Root node is not "VFPData". 
			* Error:
			*    "Metadata XML does not validate 
			*     against the MemberData XSD."
			*------------------------------------------
			error METADATA_XML_INVALID_LOC
		endif
	else
		*------------------------------------------
		* oDom.LoadXml() failed.
		* Error:
		*    "Metadata XML does not validate 
		*     against the MemberData XSD."
		*------------------------------------------
		error METADATA_XML_INVALID_LOC
	endif

catch to oErr
	*------------------------------------------
	* An error occurred somewhere in that previous 
	*------------------------------------------
	THIS.errorMsg = oErr.message
endtry
select (m.cursel)
return empty(THIS.errorMsg)

*-------------------------------------------------
* procedure SaveToFrx()
*
* Re-writes the XML metadata into the STYLE column of the 
* alias specified by the TAG property.
*
* Assumes: we are located on the right record.
*-------------------------------------------------
procedure SaveToFrx

lparameter lcFrxAlias

THIS.errorMsg = ""

if empty(m.lcFrxAlias)
	lcFrxAlias = THIS.Tag
endif	

local cursel, cXml, oDom, oNode, oNewNode
cursel = select(0)
select (m.lcFrxAlias)

*------------------------------------------------------
* If the STYLE field is empty, populate it with a 
* good default XML block:
*------------------------------------------------------
if empty( STYLE )
	replace STYLE with ;
		THIS.getDefaultXml()
endif

*------------------------------------------------------
* Create a DomDocument:
*------------------------------------------------------
oDom = null
try 
	try 
		oDom = createobject("MSXml.DomDocument")
	catch 
		*-------------------------------------------
		*  "Unable to create MSXml.DomDocument instance. 
		*   Metadata XML may not be available."
		*-------------------------------------------
		error METADATA_DOM_CREATE_FAILED_LOC
	endtry

	*------------------------------------------------------
	* We have a valid DOM. 
	*------------------------------------------------------
	
	*------------------------------------------------------
	* Read the XML metadata out of the STYLE tag:
	*------------------------------------------------------
	cXml = alltrim(STYLE)

	if oDom.loadXML( m.cXml )
		
		*------------------------------------
		* Check for valid root node/schema:
		*------------------------------------
		
		if oDom.firstChild.nodeName = "VFPData"
	
			*------------------------------------
			* look for our element:
			*------------------------------------		
			oNode = oDom.selectSingleNode( THIS.xpath )
			
			if isnull ( m.oNode )
				*---------------------------------------------
				* looks like our node doesn't exist. Let's create it:
				*---------------------------------------------
				oNewNode = oDom.createElement("reportdata")
				oNewNode.setAttribute("name","")
				oNewNode.setAttribute("type","R")
				oNewNode.setAttribute("script","")
				oNewNode.setAttribute("execute","")
				oNewNode.setAttribute("execwhen","")
				oNewNode.setAttribute("class","")
				oNewNode.setAttribute("classlib","")
				oNewNode.setAttribute("declass","" )
				oNewNode.setAttribute("declasslib","" )

				oDom.firstChild.appendChild( oNewNode )

				oNode = oDom.selectSingleNode( XPATH_REPORTDATA_DEFAULT )
			
			endif
			*---------------------------------------
			* We have our element. Save the changes:
			*---------------------------------------
			oNode.setAttribute("execute",    THIS.execute )
			oNode.setAttribute("execwhen",   THIS.execwhen )
			oNode.setAttribute("declass",    THIS.declass )
			oNode.setAttribute("declasslib", THIS.declasslib )

			*------------------------------------------------------
			* Write the XML back to the table:
			*------------------------------------------------------
			cXml = oDom.xml
			replace STYLE with m.cXml

		else
			*------------------------------------------
			* Root node is not "VFPData". 
			* Error:
			*    "Metadata XML does not validate 
			*     against the MemberData XSD."
			*------------------------------------------
			error METADATA_XML_INVALID_LOC
		endif
	else
		*------------------------------------------
		* oDom.LoadXml() failed.
		* Error:
		*    "Metadata XML does not validate 
		*     against the MemberData XSD."
		*------------------------------------------
		error METADATA_XML_INVALID_LOC
	endif

catch to oErr
	*------------------------------------------
	* An error occurred somewhere in that previous 
	*------------------------------------------
	THIS.errorMsg = oErr.message
endtry
select (m.curSel)
return empty(THIS.errorMsg)

endproc

*-------------------------------------------------
* procedure getDefaultXml()
*
* Returns a default block of XML 
*-------------------------------------------------
procedure getDefaultXml

	return 	[<VFPData>] ;
		+   [<reportdata name="" type="R" script="" execute="" execwhen="" class="" classlib="" declass="" declasslib=""/>] ;
		+	[</VFPData>]
endproc

enddefine

#define UI_COMBO_PROMPT_TRUE   ".T. - True"
#define UI_COMBO_PROMPT_FALSE  ".F. - False"

*====================================================
* PropertyDefinition - Abstract Class definition for
*                      multiple-select property
*====================================================
define class PropertyDefinition as custom

	PropertyName         = "Property Name"
	ValueType            = ADVPROP_EDITMODE_COMBOLIST
	ValueCount           = 1
	DefaultValue         = 1
	PropertyCursor       = "<to be assigned>"
	VisibleWhenProtected = .T.

	protected ValueCaption[1], ActualValue[1]

	dimension ValueCaption[1]
	ValueCaption[1] = ''

	dimension ActualValue[1]
	ActualValue[1] = ''
	
	procedure GetDefaultValue
		return THIS.ActualValue[THIS.DefaultValue]
	endproc

	procedure GetDefaultCaption
		return THIS.ValueCaption[THIS.DefaultValue]
	endproc

	procedure AppliesTo
		lparameters liObjType, liObjCode
		return .T.
	endproc

	procedure GetDisplayValue
		lparameter iIndex
		return THIS.ValueCaption[m.iIndex]
	endproc

	procedure GetActualValue
		lparameter iIndex
		return THIS.ActualValue[m.iIndex]
	endproc
	
	procedure GetValueFromDisplay
		lparameter cDisplayValue
		local iPos
		iPos = ascan( THIS.ValueCaption, alltrim(m.cDisplayValue) )
		if m.iPos>0
			return THIS.GetActualValue(m.iPos)
		endif
		return .NULL.
	endproc

	procedure StripCaption
		* Remove hotkey metachars and colons from label captions
		* in order to re-use the localization constants:
		lparameters cCaption
		local newCaption
		newCaption = strtran(alltrim(m.cCaption),'\<','')
		if right(m.newCaption,1)=':'
			newCaption = substr(m.newCaption,1,len(m.newCaption)-1)
		endif
		return m.newCaption
	endproc	
	
	procedure PropertyName_Assign
		lparameters cNewValue
		this.PropertyName = this.StripCaption( m.cNewValue )
		return
	endproc

	procedure SaveToFrx
		lparameters tcNewValue
		* frx cursor is open alias frx on the right record
		* put code here:		
		* ...
	endproc

	procedure DisplayEditor
		* launch/show the editor for this property
		* GetExpression?
	endproc
		
enddefine


*====================================================
* Justification/Alignment:
*====================================================
define class Justification as PropertyDefinition
	
	PropertyName = "Justification"

	procedure Init()
		this.PropertyName = UI_FORMAT_LBL_JUSTIFY_LOC
		dimension this.ValueCaption[3]
		this.ValueCaption[1] = this.StripCaption(UI_FORMAT_OPT_JUST_LEFT_LOC)
		this.ValueCaption[2] = this.StripCaption(UI_FORMAT_OPT_JUST_RIGHT_LOC)
		this.ValueCaption[3] = this.StripCaption(UI_FORMAT_OPT_JUST_CENTER_LOC)

		dimension this.ActualValue[3]
		this.ActualValue[1] = 0		&& 0=Left
		this.ActualValue[2] = 1		&& 1=Right
		this.ActualValue[3] = 2		&& 2=Center

		this.ValueType    = ADVPROP_EDITMODE_COMBOLIST
		this.ValueCount   = 3
		this.DefaultValue = 1
	endproc

	procedure AppliesTo
		lparameters liObjType, liObjCode
		return ( m.liObjType=FRX_OBJTYP_FIELD )
	endproc

	procedure SaveToFrx
		lparameters tcNewValue
		*---------------------------------------------------
		* frx cursor is open alias frx on the right record:
		*---------------------------------------------------
		local liNewValue 
		liNewValue = THIS.GetValueFromDisplay( m.tcNewValue )
		replace OFFSET with m.liNewValue
	endproc

enddefine

*====================================================
* Format Expression (Picture string)
*====================================================
define class FormatExpression as PropertyDefinition

	PropertyName = "Format Expression"

	procedure Init()
		this.PropertyName = UI_FORMAT_LBL_CAPTION_LOC
		this.ValueType    = ADVPROP_EDITMODE_TEXT
	endproc

	procedure AppliesTo
		lparameters liObjType, liObjCode
		return ( m.liObjType=FRX_OBJTYP_FIELD )
	endproc

	procedure SaveToFrx
		lparameters tcNewValue
		*---------------------------------------------------
		* frx cursor is open alias frx on the right record:
		*---------------------------------------------------
		replace PICTURE with ["] + alltrim(m.tcNewValue) + ["]
	endproc
	
enddefine

*====================================================
* Print When expression
*====================================================
define class PrintWhen as PropertyDefinition

	PropertyName = "Print When"

	procedure Init()
		this.PropertyName = UI_MULTIPRINTWHEN_LBL_CAPTION_LOC
		this.ValueType    = ADVPROP_EDITMODE_TEXT
	endproc

	procedure SaveToFrx
		lparameters tcNewValue
		*---------------------------------------------------
		* frx cursor is open alias frx on the right record:
		*---------------------------------------------------
		if OBJTYPE <> FRX_OBJTYP_GROUP
			*----------------------------------
			* Ignore aggregated element groups:
			*----------------------------------
			replace SUPEXPR with trim(m.tcNewValue)
		endif

	endproc	

enddefine

*====================================================
* Remove blank space if appropriate
*====================================================
define class RemoveLineIfBlank as PropertyDefinition

	PropertyName = "Remove line if blank"

	procedure Init()
		this.PropertyName = UI_PRINTWHEN_CHK_REMOVE_BLANK_LOC
		this.ValueType    = ADVPROP_EDITMODE_COMBOLIST
		this.ValueCount   = 2
		this.DefaultValue = 2

		dimension this.ValueCaption[2]
		this.ValueCaption[1] = ".T. - True"
		this.ValueCaption[2] = ".F. - False"

		dimension this.ActualValue[2]
		this.ActualValue[1] = .T.
		this.ActualValue[2] = .F.
	endproc

	procedure SaveToFrx
		lparameters tcNewValue
		*---------------------------------------------------
		* frx cursor is open alias frx on the right record:
		*---------------------------------------------------
		
		*----------------------------
		* Remove line/space if blank. 
		* This value can only be set if the object does not span bands 
		* and is not in a Column Footer.
		*----------------------------
		select objects

		*----------------------------------------- Does it span between bands?
		locate for UNIQUEID = frx.UNIQUEID
		if objects.START_BAND_ID = objects.END_BAND_ID

			select bands

			*------------------------------------- Is it in a column footer?
			locate for UNIQUEID = objects.START_BAND_ID
			if not inlist( bands.OBJCODE, FRX_OBJCOD_COLFOOTER )
				select frx
				replace NOREPEAT with THIS.GetValueFromDisplay( m.tcNewValue )
			endif

		endif						
		select frx
		
	endproc

enddefine

*====================================================
* String Trimming Mode:
*====================================================
define class StringTrimmingMode as PropertyDefinition

	PropertyName = "String Trimming Mode"
	
	procedure Init()
		this.PropertyName = UI_FORMAT_LBL_TRIM_MODE_LOC
		this.ValueType    = ADVPROP_EDITMODE_COMBOLIST
		this.ValueCount   = 6
		this.DefaultValue = 1

		dimension this.ValueCaption[6]
		this.ValueCaption[1] = this.StripCaption(STRINGTRIM_DEFAULT_LOC)
		this.ValueCaption[2] = this.StripCaption(STRINGTRIM_CHAR_LOC)
		this.ValueCaption[3] = this.StripCaption(STRINGTRIM_WORD_LOC)
		this.ValueCaption[4] = this.StripCaption(STRINGTRIM_ELLIPSIS_CHAR_LOC)
		this.ValueCaption[5] = this.StripCaption(STRINGTRIM_ELLIPSIS_WORD_LOC)
		this.ValueCaption[6] = this.StripCaption(STRINGTRIM_ELLIPSIS_FILE_LOC)

		dimension this.ActualValue[6]
		this.ActualValue[1] = FRX_STRINGTRIM_DEFAULT        
		this.ActualValue[2] = FRX_STRINGTRIM_CHAR           
		this.ActualValue[3] = FRX_STRINGTRIM_WORD           
		this.ActualValue[4] = FRX_STRINGTRIM_ELLIPSIS_CHAR  
		this.ActualValue[5] = FRX_STRINGTRIM_ELLIPSIS_WORD  
		this.ActualValue[6] = FRX_STRINGTRIM_ELLIPSIS_PATH  
	endproc

	procedure AppliesTo
		lparameters liObjType, liObjCode
		return ( m.liObjType=FRX_OBJTYP_FIELD )
	endproc

	procedure SaveToFrx
		lparameters tcNewValue
		*---------------------------------------------------
		* frx cursor is open alias frx on the right record:
		*---------------------------------------------------
		local liNewValue 
		liNewValue = THIS.GetValueFromDisplay( m.tcNewValue )
		replace RULERLINES with m.liNewValue
	endproc

enddefine

*====================================================
* ProtectionDefinition - Ancestor class for Protection flags
* NOTE: These are not used. There is a dedicated panel
*       in multi-select for protection flags.
*====================================================
define class ProtectionDefinition as PropertyDefinition

	ProtectionFlag       = 0
	VisibleWhenProtected = .F.

	procedure Init()
		this.ValueType    = ADVPROP_EDITMODE_COMBOLIST
		this.ValueCount   = 2
		this.DefaultValue = 2

		dimension this.ValueCaption[2]
		this.ValueCaption[1] = ".T. - True"
		this.ValueCaption[2] = ".F. - False"

		dimension this.ActualValue[2]
		this.ActualValue[1] = .T.
		this.ActualValue[2] = .F.
	endproc

	procedure SaveToFrx
		lparameters tcNewValue
		*---------------------------------------------------
		* frx cursor is open alias frx on the right record:
		*---------------------------------------------------
		* read current protection value
		local iProtection
		iProtection = THIS.BinstringToInt(ORDER)

		if THIS.GetValueFromDisplay( m.tcNewValue )		
			* Set the flag:
			iProtection = bitset( m.iProtection, THIS.ProtectionFlag)
		else
			* Clear the flag:
			iProtection = bitclear( m.iProtection, THIS.ProtectionFlag)
		endif
		
		* save back to frx:
		replace ORDER with THIS.IntToBinString(m.iProtection)
	endproc

	*=======================================================
	* BinstringToInt( char )
	*
	* Identical to methods in frxCursor. Duplicated here for
	* convenience (but only really needed for protection flags)
	*=======================================================
	procedure BinStringToInt( cByte )
		local iReturn, i, b
		iReturn = 0

		for m.i = len( m.cByte ) to 1 step -1
			b = asc( substr( m.cByte, m.i, 1 ))

			iReturn = (m.iReturn*256) + m.b
		endfor
		return m.iReturn
	endproc
	
	*=======================================================
	* InttoBinString( int )
	*
	* Identical to methods in frxCursor. Duplicated here for
	* convenience (but only really needed for protection flags)
	*=======================================================
	procedure IntToBinString( i )

		local cBytes, b
		cBytes = ""

		do while m.i <> 0 
			b = m.i % 256
			i = floor( m.i/256 )
			cBytes = m.cBytes + chr(m.b)			
		enddo	
		return m.cBytes
	endproc	

enddefine

*====================================================
* Protection - Object cannot be moved or resized
*====================================================
define class LockProtection as ProtectionDefinition
	PropertyName = "Protection: Cannot be moved or resized"
	ProtectionFlag = FRX_PROTECT_OBJECT_LOCK
enddefine

*====================================================
* Protection - Properties Dialog is not available
*====================================================
define class NoEditProtection as ProtectionDefinition
	PropertyName = "Protection: Cannot see Properties dialog"
	ProtectionFlag = FRX_PROTECT_OBJECT_NO_EDIT
enddefine

*====================================================
* Protection - Object cannot be deleted
*====================================================
define class NoDeleteProtection as ProtectionDefinition
	PropertyName = "Protection: Cannot be deleted"
	ProtectionFlag = FRX_PROTECT_OBJECT_NO_DELETE
enddefine
	
*====================================================
* Protection - Object cannot be selected
*====================================================
define class NoSelectProtection as ProtectionDefinition
	PropertyName = "Protection: Cannot be selected"
	ProtectionFlag = FRX_PROTECT_OBJECT_NO_SELECT
enddefine

*====================================================
* Protection - Object is not visible
*====================================================
define class HideProtection as ProtectionDefinition
	PropertyName = "Protection: Not visible in layout"
	ProtectionFlag = FRX_PROTECT_OBJECT_HIDE
enddefine

