* Contains:
*
*	NameValuePairManager
*   ResourceManager


*=================================================
* Class: NameValuePairManager
*
* This Name-Value pair manager class is used
* by frxEvent to store session-level data. It is 
* also very useful when you need to take a memo
* of name-value pairs (say, the header EXPR field)
* and get at the individual data items easily.
*=================================================

define class NameValuePairManager as Custom
	
*------------------------------------------------- 
* Properties:
*------------------------------------------------- 
dimension keys[1]
dimension values[1]
	
stripDelimiters = .T.

*------------------------------------------
function get
*------------------------------------------
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
endfunc

*------------------------------------------
function set
*------------------------------------------
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

endfunc

*------------------------------------------
function getMemo
* returns a CRLF delimited string 
*------------------------------------------
local iPair, cText
cText = ""
for iPair = 2 to alen( this.keys )
	cText = m.cText + strextract(this.keys[m.iPair],"|","|") + " = " + transform(this.values[m.iPair]) + chr(13)+chr(10)
endfor
return m.cText
endfunc

*------------------------------------------
procedure reset
*------------------------------------------
dimension this.keys[1]
dimension this.values[1]
this.keys   = .F.
this.values = .F.
endproc

*------------------------------------------
function loadMemo
* expects a CRLF delimited string
* Values will be stored as strings
*------------------------------------------
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
for i = 1 to iLineCount
	if empty( aTemp[m.i] ) ;
	or inlist( left( aTemp[m.i], 1 ), "[", ";", "*" )
		* do nothing
	else
		iKeyCount  = m.iKeyCount + 1
		
		* extract the key:
		cBuff = alltrim(aTemp[m.i])
		q = min( at(" ",m.cBuff+" "), at("=",m.cBuff+"="), at(chr(9),m.cBuff+chr(9)) )
		cKey = alltrim(left(m.cBuff,q-1))
		
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
endfunc
	
enddefine

*=================================================
* Class: ResourceManager
*
* This class is derived from NameValuePairManager
* and contains additional logic for saving and
* restoring name-value pairs to the resource file
*=================================================
define class ResourceManager as NameValuePairManager

	currentWorkArea  = 0
	resourceWorkArea = 0

*-----------------------------------------------
* OpenResourceFile()
*   returns .T. if successfully opened the resource file
*-----------------------------------------------
procedure OpenResourceFile

if file( set("RESOURCE",1) ) and set("RESOURCE")="ON"

	THIS.currentWorkArea = select(0)

	select 0
	use (set("RESOURCE",1)) again shared 
	*-----------------------------------------------
	* Fix for SP2: If the resource file is built-in
	* to the Application/Exe, it may not have an 
	* index available!
	*-----------------------------------------------
	if upper(key(1))="TYPE+ID+PADR(NAME,24)"
		set order to 1
	endif
	THIS.resourceWorkArea = select(0)
	
	return .T.
endif
return .F.
endproc
	
*-----------------------------------------------
* LoadResource( ID, NAME )
* locates and loads a specified resource record
*    into the name-value pairs. 
* Currently leaves resource file open.
*-----------------------------------------------
procedure LoadResource
lparameter cID, cNAME

if THIS.OpenResourceFile()
	*-----------------------------------------------
	* Fix for SP2: If the resource file is built-in
	* to the Application/Exe, it may not have an 
	* index available! So use LOCATE instead of SEEK:
	*-----------------------------------------------
	* if seek( padr("PREFW",12)+padr(m.cID,12) + m.cNAME )
	locate for TYPE+ID+PADR(NAME,24) = padr("PREFW",12)+padr(m.cID,12) + m.cNAME
	if found()

		THIS.loadMemo( DATA )	

	endif
		
	select (THIS.currentWorkArea)	
	return
endif
return .F.
endproc

*-----------------------------------------------
* SaveResource( ID, NAME )
* locates and saves the current name-value pairs 
*    to a specified resource record.
* Opens the resource file if necessary.
* Closes the resource file when finished.
*-----------------------------------------------
procedure SaveResource
lparameter cID, cNAME

if empty( THIS.ResourceWorkArea )
	if not THIS.OpenResourceFile()
		return .F.
	endif
else
	select (THIS.ResourceWorkArea )
endif

local lRetVal
if not isreadonly()

	local cData
	cData = THIS.getMemo()

	*-----------------------------------------------
	* Fix for SP2: If the resource file is built-in
	* to the Application/Exe, it may not have an 
	* index available! So use LOCATE instead of SEEK:
	*-----------------------------------------------
	* if not seek( padr("PREFW",12) + padr(m.cID,12) + m.cNAME )
	locate for TYPE+ID+PADR(NAME,24) = padr("PREFW",12) + padr(m.cID,12) + m.cNAME
	if not found()

		append blank
		replace ;
			TYPE		with "PREFW",;
			ID			with m.cID, ;
			NAME		with m.cNAME, ;
			READONLY 	with .F.
	endif

	if not READONLY
		replace	DATA 	with m.cData, ;
				CKVAL 	with val(sys(2007, m.cData )), ;
				UPDATED with date()
	endif

	m.lRetVal = .T.
else
	m.lRetVal = .F.
endif

*-------------------------------- Close the resource file:
use in (THIS.ResourceWorkArea)
THIS.ResourceWorkArea = 0

*-------------------------------- Restore the current workarea:
select (THIS.currentWorkArea)	
return (m.lRetVal)
endproc

*-----------------------------------------------
* Destroy()
* Close the resource file if open
*-----------------------------------------------
procedure Destroy

if not empty( THIS.ResourceWorkArea )
	use in (THIS.ResourceWorkArea) 
	THIS.ResourceWorkArea = 0
endif
if not empty( THIS.CurrentWorkArea )
	select (THIS.CurrentWorkArea)
endif
endproc

*-----------------------------------------------
* SaveFontState( THIS )
* Saves Font Style properties into the specified 
* resource file record
*   THIS  - object reference that has FontXxxx properties
*-----------------------------------------------
procedure SaveFontState
lparameters oRef

THIS.Set(oRef.Name + ".FontName",   oRef.FontName )
THIS.Set(oRef.Name + ".FontSize",   oRef.FontSize )
THIS.Set(oRef.Name + ".FontBold",   oRef.FontBold )
THIS.Set(oRef.Name + ".FontItalic", oRef.FontItalic )

endproc


*-----------------------------------------------
* RestoreFontState( THIS )
* Restores form properties from the specified 
* resource file record
*   THIS  - object reference that has FontXxxx properties
*-----------------------------------------------
procedure RestoreFontState
lparameters oRef

local cValue
cValue = THIS.Get(oRef.Name + ".FontName")
if not empty( m.cValue )
	oRef.FontName = m.cValue 
endif
cValue = THIS.Get(oRef.Name + ".FontSize")
if not empty( m.cValue )
	oRef.FontSize = int(val(m.cValue ))
endif
cValue = THIS.Get(oRef.Name + ".FontBold")
if not empty( m.cValue )
	oRef.FontBold = (upper(m.cValue)=".T.")
endif
cValue = THIS.Get(oRef.Name + ".FontItalic")
if not empty( m.cValue )
	oRef.FontItalic = (upper(m.cValue)=".T.")
endif

endproc

*-----------------------------------------------
* SaveWindowState( THIS )
* Saves form properties into the specified 
* resource file record
*   THIS  - object reference to form
*-----------------------------------------------
procedure SaveWindowState
lparameters oRef

local iCurrentState
iCurrentState = oRef.WindowState
if oRef.WindowState <> 0
	*----------------------------------
	* Fixed for SP1: was "THIS." instead of ".oRef"
	*----------------------------------
	oRef.WindowState = 0
endif

THIS.Set(oRef.Name + ".Top", oRef.Top )
THIS.Set(oRef.Name + ".Left", oRef.Left )
THIS.Set(oRef.Name + ".Width", oRef.Width )
THIS.Set(oRef.Name + ".Height", oRef.Height )
THIS.Set(oRef.Name + ".WindowState", m.iCurrentState )

endproc

*-----------------------------------------------
* RestoreWindowState( THIS )
* Restores form properties from the specified 
* resource file record
*   THIS  - object reference to form
*-----------------------------------------------
procedure RestoreWindowState
lparameters oRef

local cValue

cValue = THIS.Get(oRef.Name + ".Top")
if not empty( m.cValue )
	oRef.Top = int(val( m.cValue ))
endif
cValue = THIS.Get(oRef.Name + ".Left")
if not empty( m.cValue )
	oRef.Left = int(val( m.cValue ))
endif
cValue = THIS.Get(oRef.Name + ".Width")
if not empty( m.cValue )
	oRef.Width = int(val( m.cValue ))
endif
cValue = THIS.Get(oRef.Name + ".Height")
if not empty( m.cValue )
	oRef.Height = int(val( m.cValue ))
endif
cValue = THIS.Get(oRef.Name + ".WindowState")
if not empty( m.cValue )
	oRef.WindowState = int(val( m.cValue ))
endif
endproc

enddefine
