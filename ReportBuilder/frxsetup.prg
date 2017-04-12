* FrxSetup.prg
*
* Contains:
*
*	frxSetupUtils
*   frxNVPmanager

#include frxbuilder.h

*========================================
* Class: frxSetupUtils
*========================================
define class frxSetupUtils as custom

*------------------------------------------------- 
* Properties:
*------------------------------------------------- 
RegistryLocationLog   = ""
UsingInternalRegistry = .F.
LoggingComplete       = .F.

*------------------------------------------------- 
* GetApplicationPath()
*
* returns the path (with backslash) of the 
* current application
*------------------------------------------------- 
procedure GetApplicationPath

local cProgramStack, cProgram, i, cAppPath
cProgramStack = ""
cProgram      = ""
cAppPath      = ""

*--------------------------------------------------------
* Work backwards through the procedure stack,
* looking for the first APP or EXE so that 
* we can locate the "base" directory of the 
* application:
*--------------------------------------------------------
for i = program(-1) to 1 step -1
	cProgramStack = sys(16,m.i)
	cProgram      = program(m.i)
	
	if right(alltrim(m.cProgramStack),4) = ".EXE" ;
	or right(alltrim(m.cProgramStack),4) = ".APP" 
		exit
	endif
endfor
if "PROCEDURE" $ m.cProgramStack
	cProgramStack = substr( m.cProgramStack, len("PROCEDURE "+m.cProgram)+2 )
endif
cAppPath = addbs(justpath( m.cProgramStack ))

return m.cAppPath

endproc

*------------------------------------------------- 
* GetBuilderRegistryTableName()
*
* returns the fully qualified path of the 
* registry table. Also documents how the 
* table was located.
*------------------------------------------------- 
procedure GetBuilderRegistryTableName()
*-------------------------------------------------------
* Fix for SP2: uses slightly improved search algorithm
* that allows for a setting in CONFIG.FPW
*-------------------------------------------------------
local cAppPath, cFile, lFound

cAppPath = THIS.GetApplicationPath() 
cFile    = ""
lFound   = .F.

*--------------------------------------------------------
* First, check the .sessionData store to see if a specific
* table has been configured programmatically
* (i.e. DO ReportBuilder.App WITH 3,<filename>)
* It will either be non-empty, or have "*" for internal 
*--------------------------------------------------------
if type( "_screen.reportbuilderdata" ) = "O"
	* can get table name from here?
	cFile = _screen.reportbuilderdata.Get("registry")	
endif

if not empty( m.cFile )
else
	THIS.AppendToLog( SETUP_CHK_SCREEN_SETTING_LOC + SETUP_CHK_RESULT_EMPTY_LOC, .T. )
endif

if not empty( m.cFile )
	do case
	case m.cFile = "*"
		*--------------------------------------------------------
		* Internal version override. We've been forced to 
		* use the internal version.
		* Should be in the same directory as this VCX:
		* IS THIS ALWAYS TRUE? 
		*--------------------------------------------------------
		THIS.AppendToLog( SETUP_CHK_SCREEN_SETTING_LOC + SETUP_CHK_RESULT_FOUND_LOC, .T. )
		THIS.usingInternalRegistry = .T.
		cFile = addbs(justpath( THIS.Classlibrary )) + INT_REGISTRY_TABLE
		* if the file can be located:
		lFound = file( m.cFile )
		THIS.AppendToLog( SETUP_USING_RESULT_LOC + SETUP_USING_INTERNAL_LOC )

	case file( m.cFile )
		*--------------------------------------------------------
		* ok to continue, it's valid.
		*--------------------------------------------------------
		THIS.AppendToLog( SETUP_CHK_SCREEN_SETTING_LOC + SETUP_CHK_RESULT_FOUND_LOC, .T. )
		THIS.usingInternalRegistry = .F.
		cFile = lower(fullpath( m.cFile ))
		lFound = .T.

	otherwise
		THIS.AppendToLog( SETUP_CHK_SCREEN_SETTING_LOC + SETUP_CHK_RESULT_EMPTY_LOC, .T. )
		lFound = .F.
	endcase

endif
if not m.lFound
	*--------------------------------------------------------
	* Look in the CONFIG.FPW for a preset
	*--------------------------------------------------------

	local lcConfigFpw
	lcConfigFpw = lower(sys(2019))
	if not empty( m.lcConfigFpw ) 
		if file( m.lcConfigFpw )
*			THIS.AppendToLog("SYS(2019) = " + m.lcConfigFpw + "," )
		
			local loNvpMgr
			loNvpMgr = newobject("frxNVPManager", "frxsetup.prg" )
			loNvpMgr.LoadMemo(filetostr(m.lcConfigFpw))
		    cFile = loNvpMgr.Get(CONFIG_FILE_REGISTRY_TOKEN)
		    cFile = lower(m.cFile)
			do case
			case empty( m.cFile )
				THIS.AppendToLog( SETUP_CHK_CONFIG_SETTING_LOC + SETUP_CHK_RESULT_EMPTY_LOC )
			
			case file( m.cFile )
				*--------------------------------------------------------
				* ok to continue, it's valid.
				*--------------------------------------------------------
				THIS.AppendToLog( SETUP_CHK_CONFIG_SETTING_LOC + SETUP_CHK_RESULT_FOUND_LOC )

				THIS.usingInternalRegistry = .F.
				cFile = lower(fullpath( m.cFile ))
				if type( "_screen.reportbuilderdata" ) = "O"
					*--------------------------------------------------------
					* Setting it in the CONFIG.FPW should be equivalent to 
					* setting it programmatically:
					*--------------------------------------------------------
*					THIS.AppendToLog("_screen.ReportBuilderData.Set('registry', '" + m.cFile + "')" )
					_screen.reportbuilderdata.Set("registry", m.cFile)
				endif
				lFound = .T.

			otherwise
				THIS.AppendToLog( SETUP_CHK_CONFIG_SETTING_LOC + SETUP_CHK_RESULT_INVALID_LOC )
				
			endcase
		else
			THIS.AppendToLog( SETUP_CHK_CONFIG_SETTING_LOC + SETUP_CHK_RESULT_EMPTY_LOC )
		endif
	else
		THIS.AppendToLog( SETUP_CHK_CONFIG_SETTING_LOC + SETUP_CHK_RESULT_EMPTY_LOC )
	endif
endif
if not m.lFound

	if file( EXT_REGISTRY_TABLE )	
		*--------------------------------------------------------
		* found on path, so use this one
		*--------------------------------------------------------
		THIS.AppendToLog( SETUP_CHK_PATHDIR_DBF_LOC + SETUP_CHK_RESULT_FOUND_LOC )

		THIS.usingInternalRegistry = .F.
		cFile = lower(fullpath( EXT_REGISTRY_TABLE ))
		lFound = .T.
	else
		THIS.AppendToLog( SETUP_CHK_PATHDIR_DBF_LOC + SETUP_CHK_RESULT_EMPTY_LOC )
		
		cFile = lower( m.cAppPath + EXT_REGISTRY_TABLE )
			
		if file( m.cFile )
			*--------------------------------------------------------
			* found in the application path/HOME()
			*--------------------------------------------------------
			THIS.AppendToLog( SETUP_CHK_HOMEDIR_DBF_LOC + SETUP_CHK_RESULT_FOUND_LOC )

			THIS.usingInternalRegistry = .F.
			lFound = .T.
		else		
			THIS.AppendToLog( SETUP_CHK_HOMEDIR_DBF_LOC + SETUP_CHK_RESULT_EMPTY_LOC )
			THIS.AppendToLog( SETUP_USING_RESULT_LOC + SETUP_USING_INTERNAL_LOC )
			*--------------------------------------------------------
			* use the internal version.
			* Should be in the same directory as this VCX:
			* Not necessarily. What to do?
			*--------------------------------------------------------
			THIS.usingInternalRegistry = .T.
			cFile = addbs(justpath( THIS.Classlibrary )) + INT_REGISTRY_TABLE
			lFound = .T.
		endif
	endif
endif

if not file( m.cFile )
	lFound = .F.
	*----------------------------
	* Still can't find the file?
	* Prompt the user:
	* TODO: replace these with _LOCs
	*----------------------------
	if messagebox(LOCATE_REGISTRY_MANUALLY_MSG_LOC, 4+64, DEFAULT_MBOX_TITLE_LOC)=6
		cFile = lower(getfile("DBF"))
		if not file( m.cFile )
			THIS.AppendToLog( SETUP_CHK_ASKUSER_DBF_LOC + SETUP_CHK_RESULT_INVALID_LOC )
			cFile = ""
		else
			THIS.AppendToLog( SETUP_CHK_ASKUSER_DBF_LOC + SETUP_CHK_RESULT_FOUND_LOC )
		endif
	else
		cFile = ""
	endif
endif

if not empty( m.cFile )
	THIS.AppendToLog( SETUP_USING_RESULT_LOC + m.cFile )
endif		
THIS.LoggingComplete = .T.
return m.cFile	

endproc

*------------------------------------------------- 
* AppendToLog( string, reset )   PROTECTED
*------------------------------------------------- 
protected procedure AppendToLog
lparameter lcText, llReset

if not THIS.LoggingComplete
	if m.llReset
		THIS.registrylocationlog = m.lcText
	else
		THIS.registrylocationlog = THIS.registrylocationlog + chr(13) + m.lcText
	endif
endif
return

endproc

enddefine

*========================================
* Class: frxNVPmanager
*========================================
define class frxNVPmanager as custom

*------------------------------------------------- 
* Properties:
*------------------------------------------------- 
dimension keys[1]
dimension values[1]
	
stripDelimiters = .T.

*----------------------------------------
* Set( key, value )
*----------------------------------------
procedure Set
lparameters cKey, vValue 

local iIndex, iKeyCount
if not empty( m.cKey )
	*iIndex = ascan(this.keys, "|"+alltrim(upper(m.cKey))+"|" )
	iIndex = ascan(this.keys, "|"+alltrim(m.cKey)+"|", 1, alen(this.keys), 1, 7)
	if m.iIndex > 0
		this.values[m.iIndex] = m.vValue
	else
		iKeyCount = alen(this.keys,1)+1
		
		dimension this.keys[m.iKeyCount]
		dimension this.values[m.iKeyCount]
		this.keys[m.iKeyCount]   = "|"+m.cKey+"|"
		this.values[m.iKeyCount] = m.vValue
	endif
endif

endproc
	
*----------------------------------------
* Get( key )
*----------------------------------------
procedure Get
lparameter cToken 

local retVal
retVal = ""
if not empty( m.cToken )
	*iIndex = ascan(this.keys, "|"+alltrim(upper(m.cToken))+"|" )
	iIndex = ascan(this.keys, "|"+alltrim(m.cToken)+"|", 1, alen(this.keys), 1, 7)
	if m.iIndex > 0
		return this.values[m.iIndex]
	endif
endif
return m.retVal

endproc
	
*----------------------------------------
* Reset()
*----------------------------------------
procedure Reset

dimension this.keys[1]
dimension this.values[1]
this.keys   = .F.
this.values = .F.

endproc
	
*----------------------------------------
* LoadMemo( string )
*
* expects a CRLF delimited string
* Values will be stored as strings
*----------------------------------------
procedure LoadMemo
lparameter cText 

if empty( m.cText )
	return .F.
endif

* populate arrays:
*
local i, iLineCount, iKeyCount, cBuff, q, cKey, cValue
private aTemp

iLineCount = alines( aTemp, m.cText )
iKeyCount  = 0
for i = 1 to m.iLineCount
	if empty( aTemp[m.i] ) ;
	or inlist( left( aTemp[m.i], 1 ), "[", ";", "*" )
		* do nothing
	else
		iKeyCount  = m.iKeyCount + 1
		
		* extract the key:
		cBuff = alltrim(aTemp[m.i])
		q = min( at(" ",m.cBuff+" "), at("=",m.cBuff+"="), at(chr(9),m.cBuff+chr(9)) )
		cKey = alltrim(left(m.cBuff,m.q-1))
		
		* extract the value:
		cBuff  = alltrim( aTemp[m.i])
		cValue = alltrim( substr( m.cBuff, at("=", m.cBuff)+1 ) )

		if this.stripDelimiters
			* quote removal:
			if left( m.cValue ,1) = ["] and right(m.cValue ,1) = ["]
				cValue  = substr( m.cValue , 2, len(m.cValue )-2)
			endif
			if left( m.cValue ,1) = ['] and right(m.cValue ,1) = [']
				cValue  = substr( m.cValue , 2, len(m.cValue )-2)
			endif
		endif
		cValue = alltrim(m.cValue )
		
		* load them into the property:
		*
		this.set( m.cKey, m.cValue )
	endif
endfor
return .T.

endproc
	
*----------------------------------------
* GetMemo()
*
* Returns the list of keys and values as
* a text string
*----------------------------------------
procedure GetMemo
local iPair, cText
cText = ""
for iPair = 2 to alen( this.keys )
	cText = m.cText + strextract(this.keys[m.iPair],"|","|") + " = " + transform(this.values[m.iPair]) + chr(13)+chr(10)
endfor
return m.cText
endproc
	
enddefine