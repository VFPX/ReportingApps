* REPORTOUTPUT WRAPPER PRG

#INCLUDE REPORTOUTPUT.H

LPARAMETERS m.tvType, m.tvReference, m.tvUnload

EXTERNAL TABLE OUTPUTAPP_INTERNALDBF 

LOCAL m.oTemp, m.iType, m.iIndex, m.cType, m.cConfigTable, ;
   m.lSuccess, m.lSetTalkBackOn, m.lSafety, m.cFilter, m.cClass, m.cLib, m.cModule, ;
   m.oConfig, m.oError, m.lStringVar, m.lObjectMember, m.iParams, ;
   m.iUnload, m.iSelect, m.iSession, m.lSetTalkBackOnDefaultSession, m.vReturn, ;
   m.oSH
   
IF (SET("TALK") = "ON")
   SET TALK OFF
   m.lSetTalkBackOn = .T.
ENDIF

m.iParams = PARAMETERS()
m.iSession = SET("DATASESSION")

m.oSH = CREATEOBJECT("SH")

m.oSH.Execute(VFP_DEFAULT_DATASESSION)

m.iSelect = SELECT()

IF (SET("TALK") = "ON")
   SET TALK OFF
   m.lSetTalkBackOnDefaultSession = .T.
ENDIF


* if it is not integer, convert
* if it is lower than -1, 
* this is a value private to REPORTOUTPUT.APP, 
* potentially not even a ListenerType
* if it is not numeric, just set up the
* reference collection

DO CASE
CASE VARTYPE(m.tvType) # "N"
   m.vReturn = ReportOutputConfig(OUTPUTAPP_CONFIGTOKEN_SETTABLE, .F., .F., m.oSH)
   DO ReportOutputCleanup WITH ;
       m.iSelect, m.lSetTalkBackOnDefaultSession, ;
       m.iSession, m.lSetTalkBackOn, m.oSH
   RETURN m.vReturn
CASE ABS(m.tvType) # m.tvType AND m.tvType < LISTENER_TYPE_DEF 
   m.vReturn = ReportOutputConfig(m.tvType, @m.tvReference, m.tvUnload, m.oSH)
   DO ReportOutputCleanup WITH ;
       m.iSelect, m.lSetTalkBackOnDefaultSession, ;
       m.iSession, m.lSetTalkBackOn, m.oSH
   RETURN m.vReturn
OTHERWISE
  m.iType = INT(m.tvType)
ENDCASE

IF m.iParams = 3  
   m.iUnload = VAL(TRANSFORM(m.tvUnload))   
   IF VARTYPE(m.tvUnload) = "L" AND m.tvUnload
      m.vReturn = UnloadListener(m.iType)
      DO ReportOutputCleanup WITH ;
         m.iSelect, m.lSetTalkBackOnDefaultSession, ;
         m.iSession, m.lSetTalkBackOn, m.oSH
      RETURN m.vReturn
   ELSE 
      IF m.iUnload > 0 
         IF m.iUnload = OUTPUTAPP_LOADTYPE_UNLOAD
            m.vReturn = UnloadListener(m.iType)
            DO ReportOutputCleanup WITH ;
               m.iSelect, m.lSetTalkBackOnDefaultSession, ;
               m.iSession, m.lSetTalkBackOn, m.oSH
            RETURN m.vReturn
         ELSE
            DO UnloadListener WITH m.iType
         ENDIF
      ENDIF
   ENDIF
ENDIF

DO ReportOutputDeclareReference  WITH ;
   m.iParams, m.tvReference, m.lObjectMember, m.lStringVar


IF m.iType = LISTENER_TYPE_DEF
   * always provide the reference fresh,
   * do not use the collection
   m.oTemp = CREATEOBJECT("ReportListener")

ELSE

   * check for public reference var (collection)
   * if it is not available create
  
  
   m.cType = TRANSFORM(m.iType)

   m.iIndex = -1
   
  
   DO CheckPublicListenerCollection WITH m.cType, m.iIndex
   
   IF m.iIndex > -1
      m.oTemp = OUTPUTAPP_REFVAR.ITEM[m.iIndex]
   ELSE
      * if they've passed in an existing object and 
      * it's not in the collection yet, add
      * (SP1 change)
      IF TestListenerReference(m.tvReference)
         OUTPUTAPP_REFVAR.ADD(m.tvReference,m.cType)         
         * synch this up, JIC:
         DO CheckPublicListenerCollection WITH m.cType, m.iIndex
         IF m.iIndex > -1
            m.oTemp = m.tvReference
         ENDIF   
      ENDIF      
   ENDIF

   IF NOT TestListenerReference(m.oTemp)

      * if it is not available,
      * look for config file, choosing between built-in and
      * on-disk

      m.oError = NULL
      STORE "" TO m.cClass, m.cLib, m.cModule

      * try to open, error handle for
      * unavailability
      
      DO GetConfigObject WITH m.oConfig
      
      TRY
         SELECT 0
         
         m.iIndex = -1
         DO CheckPublicListenerCollection WITH ;
           TRANSFORM(OUTPUTAPP_CONFIGTOKEN_SETTABLE), m.iIndex
         
         IF m.iIndex > -1
            m.cConfigTable = OUTPUTAPP_REFVAR.ITEM[m.iIndex]
         ELSE
            m.cConfigTable = m.oConfig.GetConfigTable()
            * the collection will have been created by 
            * CheckPublicListenerCollection
            OUTPUTAPP_REFVAR.ADD(m.cConfigTable,TRANSFORM(OUTPUTAPP_CONFIGTOKEN_SETTABLE))                      
         ENDIF

         USE (m.cConfigTable ) ALIAS OutputConfig SHARED 

         IF m.oConfig.VerifyConfigTable("OutputConfig")

            * look for filter records first:

            * OBJTYPE   110   identifies a configuration record
            * OBJCODE   1    Configuration item type. 1= registry filter
            * OBJNAME   not used
            * OBJVALUE   not used
            * OBJINFO   Filter expression
             
            SELECT OutputConfig  
            SET ORDER TO 0
            LOCATE && GO TOP
            LOCATE FOR ObjType = OUTPUTAPP_OBJTYPE_CONFIG AND ;
                       ObjCode = OUTPUTAPP_OBJCODE_FILTER AND ;
                       NOT (EMPTY(ObjInfo) OR DELETED())
            IF FOUND()
               m.cFilter = " AND (" + ALLTR(ObjInfo) + ")"
            ELSE
               m.cFilter = ""   
            ENDIF

            * check for type record for the passed type and 
            * not deleted and in the filter

            * OBJTYPE   100   identifies a Listener registry record
            * OBJCODE   Listener Type   values -1, 0, 1, and 2 supported by default
            * OBJNAME   Class to instantiate   may be ReportListener (base class)
            * OBJVALUE   Class library or procedure file   may be blank
            * OBJINFO   Module/Application containing library   may be blank

            LOCATE && GO TOP

            LOCATE FOR ObjType = OUTPUTAPP_OBJTYPE_LISTENER AND ;
                                 (ObjCode = m.iType)  ;
                                 &cFilter. AND (NOT DELETED())
            IF FOUND()
               * get values
               m.cClass = ALLTRIM(ObjName)
               m.cLib = ALLTRIM(ObjValue)
               m.cModule = ALLTR(ObjInfo)

            ELSE

               DO GetSupportedListenerInfo WITH ;
                  m.iType, m.cClass, m.cLib, m.cModule
            ENDIF                                 
            
         ELSE   
         
            IF ISNULL(m.oError) && should be
               m.oError = CREATEOBJECT("Exception")
               m.oError.Message = OUTPUTAPP_CONFIGTABLEWRONG_LOC 
            ENDIF   
            
            IF OUTPUTAPP_DEFAULTCONFIG_AFTER_CONFIGTABLEFAILURE
               DO GetSupportedListenerInfo WITH ;
                  m.iType, m.cClass, m.cLib, m.cModule         
            ENDIF

         ENDIF

         IF USED("OutputConfig")
            USE IN OutputConfig  
         ENDIF   

         IF NOT EMPTY(m.cClass)
            IF NOT INLIST(UPPER(JUSTEXT(m.cModule)),"APP","EXE", "DLL")
               * frxoutput can be built into the current app or exe
               m.cModule = ""
            ENDIF
            m.oTemp = NEWOBJECT(m.cClass, m.cLib, m.cModule)
         ENDIF
         
        
      CATCH TO m.oError
         EXIT  
      FINALLY
         * m.oSH.Execute(m.iSession)
         * SET DATASESSION TO (m.iSession)
      ENDTRY
      
      IF NOT ISNULL(m.oError)
         DO ReportOutputCleanup WITH ;
          m.iSelect, m.lSetTalkBackOnDefaultSession, ;
          m.iSession, m.lSetTalkBackOn, m.oSH
         HandleError(m.oError)
      ELSE   
       
         IF TestListenerReference(m.oTemp) AND ;
            PEMSTATUS(m.oTemp,"ListenerType",5)
            * see notes below, we don't
            * prevent the assignment if not
            * a listener but we do not want it
            * in the collection nonetheless

            #IF OUTPUTAPP_ASSIGN_TYPE 
             IF UPPER(m.oTemp.BaseClass) == UPPER(m.oTemp.Class)
                m.oTemp.ListenerType = m.iType
             ENDIF   
            #ENDIF   
            OUTPUTAPP_REFVAR.ADD(m.oTemp,m.cType)
         ENDIF   

      ENDIF   

      STORE NULL TO m.oConfig, m.oError

   ENDIF

ENDIF


m.lSuccess = TestListenerReference(m.oTemp)

   * we don't test for listener baseclass --
   * they could hide the property --
   * also we get a more consistent
   * error message letting the product
   * handle things if the object does
   * not descend from ReportListener
   * however, we have to assign type as needed,
   * and that will require a test.


IF m.lSuccess

   #IF OUTPUTAPP_ASSIGN_OUTPUTTYPE
       TRY
         m.oTemp.OutputType =m.iType
       CATCH WHEN .T.
         * in case they
         * hid or protected it,
         * or have an assign method that errored
       ENDTRY  
   #ENDIF

   DO CASE
   CASE m.iParams = 1
      * nothing to assign, just store in the collection
   CASE m.lStringVar OR m.lObjectMember
      IF m.lStringVar AND TYPE(m.tvReference) = "U"
         PUBLIC &tvReference.   
      ENDIF   
      STORE m.oTemp TO (m.tvReference)
      #IF OUTPUTAPP_ASSIGN_TYPE 
      IF PEMSTATUS(&tvReference.,"ListenerType",5) AND ;
         UPPER(m.oTemp.BaseClass) == UPPER(m.oTemp.Class)
         &tvReference..ListenerType = m.iType
      ENDIF   
      #ENDIF
   OTHERWISE
      m.tvReference = m.oTemp
      #IF OUTPUTAPP_ASSIGN_TYPE 
      IF PEMSTATUS(m.tvReference,"ListenerType",5) AND ;
         UPPER(m.oTemp.BaseClass) == UPPER(m.oTemp.Class)
         m.tvReference.ListenerType = m.iType
      ENDIF   
      #ENDIF
   ENDCASE
ELSE
   DO CASE
   CASE m.iParams = 1
      * nothing to assign   
   CASE m.lStringVar OR m.lObjectMember
      STORE NULL TO (m.tvReference)
   OTHERWISE
      m.tvReference = NULL
   ENDCASE
ENDIF

DO ReportOutputCleanup WITH ;
      m.iSelect, m.lSetTalkBackOnDefaultSession, ;
      m.iSession, m.lSetTalkBackOn,m.oSH

RETURN m.lSuccess  && not used by the product but might be used by somebody

PROC ReportOutputCleanup( ;
   m.tiSelect, m.tlResetTalkDefaultSession, m.tiSession,m.tlResetTalk,m.toSH )
   m.toSH.Execute(VFP_DEFAULT_DATASESSION)  && JIC
   SELECT (m.tiSelect)
   IF m.tlResetTalkDefaultSession
      SET TALK ON
   ENDIF
   toSH.Execute(m.tiSession)
   IF m.tlResetTalk
      SET TALK ON
   ENDIF
   m.toSH = NULL
ENDPROC   

PROC TestListenerReference(m.toRef)

   RETURN (VARTYPE(m.toRef) = "O") && AND ;
     && (UPPER(toRef.BASECLASS) == "REPORTLISTENER")

PROC GetSupportedListenerInfo(m.tiType, m.tcClass, m.tcLib, m.tcModule)
   DO CASE 
   CASE OUTPUTAPP_XBASELISTENERS_FOR_BASETYPES AND ;
        m.tiType = LISTENER_TYPE_PRN
      m.tcClass = OUTPUTAPP_CLASS_PRINTLISTENER
      m.tcLib = OUTPUTAPP_BASELISTENER_CLASSLIB

   CASE OUTPUTAPP_XBASELISTENERS_FOR_BASETYPES AND ;
        m.tiType= LISTENER_TYPE_PRV
      m.tcClass = OUTPUTAPP_CLASS_PREVIEWLISTENER
      m.tcLib = OUTPUTAPP_BASELISTENER_CLASSLIB

   CASE INLIST(m.tiType,LISTENER_TYPE_PRN,;
                      LISTENER_TYPE_PRV, ;
                      LISTENER_TYPE_PAGED, ;
                      LISTENER_TYPE_ALLPGS)
      m.tcClass = "ReportListener"
   CASE m.tiType = LISTENER_TYPE_HTML
      m.tcClass = OUTPUTAPP_CLASS_HTMLLISTENER
      m.tcLib = OUTPUTAPP_BASELISTENER_CLASSLIB
   CASE m.tiType = LISTENER_TYPE_XML
      m.tcClass = OUTPUTAPP_CLASS_XMLLISTENER
      m.tcLib = OUTPUTAPP_BASELISTENER_CLASSLIB
   CASE m.tiType = LISTENER_TYPE_DEBUG
      m.tcClass = OUTPUTAPP_CLASS_DEBUGLISTENER
      m.tcLib = OUTPUTAPP_BASELISTENER_CLASSLIB
   OTHERWISE
      * ERROR here?  
      * No, let product handle it consistently. 
   ENDCASE

ENDPROC

PROC ReportOutputConfig(m.tnType, m.tvReference, m.tvUnload, m.toSH)
    * NB: early quit in case somebody
    * calls the thing improperly, 
    * even from the command line with a SET PROC
    IF VARTYPE(m.tnType) # "N"
       RETURN .F.
    ENDIF
    * can support other things besides writing the
    * table here
    LOCAL m.iSession, oSession, m.oError, m.oConfig, m.cDBF, m.lSuccess, m.cType, m.iIndex
    m.oError = NULL
    m.oConfig = NULL
    m.iSession = SET("DATASESSION")    
    m.lSuccess = .F.
    TRY        
       DO CASE
       CASE m.tnType = OUTPUTAPP_CONFIGTOKEN_SETTABLE AND ;
            VARTYPE(m.tvReference) = "C" AND ;
            FILE(FULLPATH(FORCEEXT(TRANSFORM(m.tvReference),"DBF"))) 
             * use FILE() because it can be in the app                         
       
            m.cDBF = FULLPATH(FORCEEXT(TRANSFORM(m.tvReference),"DBF"))
            m.iIndex = -1
            m.cType = TRANSFORM(OUTPUTAPP_CONFIGTOKEN_SETTABLE)             
            DO CheckPublicListenerCollection WITH m.cType, m.iIndex
            IF m.iIndex # -1
               OUTPUTAPP_REFVAR.REMOVE[m.iIndex]
            ENDIF
            OUTPUTAPP_REFVAR.ADD(m.cDBF,m.cType)          
            m.lSuccess = .T.
      CASE m.tnType = OUTPUTAPP_CONFIGTOKEN_WRITETABLE
            oSession = CREATEOBJECT("session")
            m.lSafety = SET("SAFETY") = "ON"
            m.toSH.Execute(oSession.DataSessionID)
            IF m.lSafety
               SET SAFETY ON
            ENDIF
            DO GetConfigObject WITH m.oConfig, .T.
            * use XML class, not config superclass, 
            * to write both sets of records, base config outline 
            * and base listener's nodenames
            m.cDBF = FORCEEXT(FORCEPATH(OUTPUTAPP_EXTERNALDBF, JUSTPATH(SYS(16,0))),"DBF")
            m.oConfig.CreateConfigTable(m.cDBF)
            IF NOT EMPTY(SYS(2000,m.cDBF))
               m.iIndex = -1
               m.cType = TRANSFORM(OUTPUTAPP_CONFIGTOKEN_SETTABLE)             
               DO CheckPublicListenerCollection WITH m.cType, m.iIndex               
               IF m.iIndex # -1
                  OUTPUTAPP_REFVAR.REMOVE[m.iIndex]
               ENDIF
               OUTPUTAPP_REFVAR.ADD(m.cDBF,m.cType)          
               USE (m.cDBF) 
               LOCATE FOR ObjType = OUTPUTAPP_OBJTYPE_LISTENER AND ;
                          ObjCode = LISTENER_TYPE_DEBUG AND ;
                          UPPER(ALLTRIM(ObjName)) == 'DEBUGLISTENER' AND ;
                          ObjValue = OUTPUTAPP_BASELISTENER_CLASSLIB AND ;
                          DELETED()
               IF EOF()           
                  INSERT INTO (ALIAS()) VALUES ;
                  (OUTPUTAPP_OBJTYPE_LISTENER ,LISTENER_TYPE_DEBUG,'DebugListener',OUTPUTAPP_BASELISTENER_CLASSLIB,SYS(16,0))
                  DELETE NEXT 1
               ENDIF   
*!*	            SELECT  ObjType, ObjCode, ObjName, ObjValue , ;
*!*	                    LEFT(ObjInfo,30) AS Info FROM (m.cDBF) ;
*!*	                    INTO CURSOR STRTRAN(OUTPUTAPP_CONFIGTABLEBROWSE_LOC," ","")
*!*	            SELECT (STRTRAN(OUTPUTAPP_CONFIGTABLEBROWSE_LOC," ",""))
*!*	            BROWSE TITLE OUTPUTAPP_CONFIGTABLEBROWSE_LOC  FIELDS ;
*!*	              ObjType, ObjCode, ObjName, ObjValue , Info = LEFT(ObjInfo,30), ObjInfo
               BROWSE TITLE OUTPUTAPP_CONFIGTABLEBROWSE_LOC  
               USE
               m.lSuccess = .T.
            ELSE
               m.lSuccess = .F.
            ENDIF   
       OTHERWISE 
            m.iIndex = -1
            m.cType = TRANSFORM(OUTPUTAPP_CONFIGTOKEN_SETTABLE)             
            DO CheckPublicListenerCollection WITH m.cType, m.iIndex
            IF m.iIndex = -1
               * don't disturb it if it's there
               DO GetConfigObject WITH m.oConfig
               m.cDBF = m.oConfig.GetConfigTable()
               OUTPUTAPP_REFVAR.ADD(m.cDBF,m.cType)                       
               m.tvReference = m.cDBF
            ELSE
               m.tvReference= OUTPUTAPP_REFVAR.ITEM[m.iIndex]   
            ENDIF
            m.lSuccess = .T.
       ENDCASE
    CATCH WHEN WTITLE() =  OUTPUTAPP_CONFIGTABLEBROWSE_LOC 
       * MESSAGEBOX("here")
       * error 57 on the browse -- no table open ad nauseum
    CATCH TO m.oError
       m.lSuccess = .F.
    FINALLY
       m.toSH.Execute(m.iSession)
    ENDTRY           
    
    IF NOT ISNULL(m.oError)
       HandleError(m.oError)
    ENDIF
    
    RETURN m.lSuccess   

ENDPROC

PROCEDURE GetConfigObject(m.toCfg, m.tXML)
   LOCAL m.lcModule
   m.lcModule = _REPORTOUTPUT
   IF NOT INLIST(UPPER(JUSTEXT(m.lcModule)),"EXE","APP","DLL")
      m.lcModule = SYS(16,0)
   ENDIF
   IF NOT INLIST(UPPER(JUSTEXT(m.lcModule)), "EXE","APP","DLL")
      m.lcModule = ""
   ENDIF
   IF m.tXML
      m.toCfg = NEWOBJECT(OUTPUTAPP_CLASS_XMLLISTENER,OUTPUTAPP_BASELISTENER_CLASSLIB, m.lcModule)         
   ELSE
      m.toCfg = NEWOBJECT(OUTPUTAPP_CLASS_UTILITYLISTENER,OUTPUTAPP_BASELISTENER_CLASSLIB, m.lcModule)   
   ENDIF            
   IF VARTYPE(toCfg) = "O"
      m.toCfg.QuietMode = .T.
      m.toCfg.AppName = OUTPUTAPP_APPNAME_LOC 
   ENDIF
ENDPROC

PROCEDURE ReportOutputDeclareReference( ;
   m.tiParams, m.tvReference, m.tlObjectMember, m.tlStringVar)
   LOCAL m.iDotPos
   IF m.tiParams > 1 AND ;
      TYPE("m.tvReference") = "C" 
      m.iDotPos = RAT(".",m.tvReference)
      IF m.iDotPos > 1 AND ;
         m.iDotPos < LEN(m.tvReference)
         IF TYPE(m.tvReference) = "U"
           IF TYPE(LEFT(m.tvReference,m.iDotPos-1)) = "O"
              AddProperty(EVAL(LEFT(m.tvReference,m.iDotPos-1)),SUBSTR(m.tvReference,m.iDotPos+1))
              m.tlObjectMember = .T.
           ENDIF
         ELSE
           m.tlObjectMember = .T.      
         ENDIF
      ELSE
         m.tlStringVar = .T.
      ENDIF    
   ENDIF   
ENDPROC

PROCEDURE UnloadListener(m.tiType)
   LOCAL m.lUnload, m.cType
   
   IF VARTYPE(OUTPUTAPP_REFVAR) # "O" OR ;
      NOT (UPPER(OUTPUTAPP_REFVAR.CLASS) == ;
      UPPER(OUTPUTAPP_REFVARCLASS))
      
      * nothing to do

   ELSE
      m.cType = TRANSFORM(m.tiType)
      * look for reference to a listener of the appropriate type
      FOR m.iIndex = 1 TO OUTPUTAPP_REFVAR.COUNT 
         IF OUTPUTAPP_REFVAR.GETKEY(m.iIndex) == m.cType
            OUTPUTAPP_REFVAR.Remove(m.iIndex)
            m.lUnload = .T.
            EXIT
         ENDIF
      NEXT

   ENDIF
  
   RETURN m.lUnload
ENDPROC

PROCEDURE HandleError(m.toE)
  DO CASE
  CASE NOT ISNULL(m.toE) 
     IF EMPTY(toE.ErrorNo)
        ERROR toE.Message
     ELSE
        ERROR toE.ErrorNo, toE.Details
     ENDIF
  CASE NOT EMPTY(MESSAGE())
     ERROR MESSAGE()
  OTHERWISE
     ERROR OUTPUTAPP_UNKNOWN_ERROR_LOC
  ENDCASE   
ENDPROC

PROCEDURE CheckPublicListenerCollection(m.tcType, m.tiIndex)

    LOCAL m.iIndex

   IF VARTYPE(OUTPUTAPP_REFVAR) # "O" OR ;
         NOT (UPPER(OUTPUTAPP_REFVAR.CLASS) == ;
              UPPER(OUTPUTAPP_REFVARCLASS))
      * could be a collection subclass
      * in which case look for
      * AINSTANCE(aTemp, <classname>)

      PUBLIC OUTPUTAPP_REFVAR
      STORE CREATEOBJECT(OUTPUTAPP_REFVARCLASS) TO ([OUTPUTAPP_REFVAR])

   ENDIF
   
   IF NOT EMPTY(m.tcType)

       FOR m.iIndex = 1 TO OUTPUTAPP_REFVAR.COUNT
           IF OUTPUTAPP_REFVAR.GETKEY(m.iIndex) == m.tcType
              m.tiIndex = m.iIndex
              EXIT
            ENDIF
       NEXT
       
    ENDIF   

ENDPROC

DEFINE CLASS SH AS Custom
   PROCEDURE Execute(m.tiSession)
      SET DATASESSION TO (m.tiSession)
   ENDPROC
ENDDEFINE