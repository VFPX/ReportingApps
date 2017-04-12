<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="1.0" encoding="UTF-8" indent="no" doctype-public="-//W3C//DTD HTML 4.0//EN" doctype-system="http://www.w3.org/TR/REC-html40/strict.dtd"/>

  <xsl:param name="externalFileLocation"/>
  <!--select="'./whatever/'" or 'http://something/myimages/' or "'./'" or... -->
  <xsl:param name="copyImageFiles" select="0"/>
  <xsl:param name="generalFieldDPI" select="96"/>
  <xsl:param name="fillPatternShade" select="180*3"/>
  <xsl:param name="fillPatternOffset" select="128"/>
  <xsl:param name="numberPrecision" select="5"/>
  <xsl:param name="fieldAlphaOpacityOffset" select="75"/>
  <xsl:param name="fieldAlphaOpacityShade" select="180*3"/>
  <xsl:param name="useTextAreaForStretchingText" select="1"/>
  <xsl:param name="hideScrollbarsForTextAreas" select="0"/>
  <xsl:param name="PageTitlePrefix_LOC" select="''"/>
<!--    <xsl:param name="unpagedModeIncludesOnePageHeader" select="0"/> -->
  <xsl:param name="unpagedModeIncludesTitle" select="1"/>
  <xsl:param name="noBody" select="0"/>
  <xsl:param name="useDynamicTextAttributes" select="1"/>
  <xsl:param name="anchorAttrName" select="1"/>   
  <!-- id is theoretically better if you wanted to write
   script against this element, or in case name is 
   deprecated in a future version of the standard, 
   but a value of 1 forces name to be used instead. 
   Current-newer browsers will be okay with this, and older 
   browsers might prefer it. -->

  <xsl:variable name="FRUs" select="10000"/>
  <xsl:variable name="printDPI" select="960"/>
  <xsl:variable name="FRUsInPixelsat96DPI" select="104.167"/>
  <xsl:variable name="imagePixelRatio" select="$generalFieldDPI div $printDPI"/>
  <xsl:variable name="zeros" select="substring('0000000000000000000000000',1,$numberPrecision)"/>
  <xsl:variable name="thisPageHeight">
    <xsl:value-of select="number(/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXPrintJob/@pageheight  div $printDPI)"/>
  </xsl:variable>
  <xsl:variable name="lineNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[type=6]/name"/>
  <xsl:variable name="labelNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[type=5]/name"/>
  <xsl:variable name="fieldNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[type=8]/name"/>
  <xsl:variable name="shapeNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[type=7]/name"/>
  <xsl:variable name="pictureNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[type=17]/name"/>
  <xsl:variable name="detailNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=4]/name"/>
  <xsl:variable name="detailHeaderNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=9]/name"/>
  <xsl:variable name="detailFooterNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=10]/name"/>
  <xsl:variable name="pageHeaderNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=1]/name"/>
  <xsl:variable name="pageFooterNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=7]/name"/>
  <xsl:variable name="columnHeaderNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=2]/name"/>
  <xsl:variable name="columnFooterNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=6]/name"/>
  <xsl:variable name="groupHeaderNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=3]/name"/>
  <xsl:variable name="groupFooterNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=5]/name"/>
  <xsl:variable name="titleNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=0]/name"/>
  <xsl:variable name="summaryNodeName" select="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutNode[code=8]/name"/>
  <xsl:variable name="anchorAttr">
  <xsl:choose>
  <xsl:when test="$anchorAttrName=1">name</xsl:when>
  <xsl:otherwise>id</xsl:otherwise>
  </xsl:choose> 
  </xsl:variable>


  <xsl:key name="Layout" match="/Reports/VFP-Report/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[platform='WINDOWS']" use="concat(frxrecno,../../@id)"/>


  <xsl:template match="/">
      <xsl:choose>
        <xsl:when test="number($noBody)=1">
        <div>
         <meta http-equiv="Content-Type"  content="text/html; charset=UTF-8"/>        
          <xsl:call-template name="renderStyles"/>
          <xsl:call-template name="body"/>
         </div>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="/" mode="full"/>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:template>
  <xsl:template match="/" mode="full">
    <html>
       <xsl:if test="/Reports/VFP-Report[1]/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[objtype=1 and (fontcharset=177 or fontcharset=178)]">
       <xsl:attribute name="dir">rtl</xsl:attribute>
       </xsl:if>
      <head>
        <meta  http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<xsl:comment> 
the above repeated-explicit declaration is necessary because 
some versions of MSXML xslt processing don't include the 
charset as required by the XSLT standard when method="html".  
Explicitly including the META creates a doubled meta content-type tag, 
but we do need the encoding to be specified properly and the doubled tag is okay. 
</xsl:comment>
        <meta name="description" 
content="{/Reports/VFP-Report[1]/Run/property[@id='description']/.}"/>
        <meta name="author" 
content="{/Reports/VFP-Report[1]/Run/property[@id='author']/.}"/>
        <meta name="copyright" 
content="{/Reports/VFP-Report[1]/Run/property[@id='copyright']/.}"/>
        <meta name="date" 
content="{/Reports/VFP-Report[1]/Run/property[@id='date']/.}"/>
        <xsl:if test="/Reports/VFP-Report/Run/property[@id='keywords']">
        <meta name="keywords">
        <xsl:attribute name="content">
         <xsl:for-each select="/Reports/VFP-Report/Run/property[@id='keywords']">
         <xsl:value-of select="."/><xsl:if test="not(position()=last())">,</xsl:if>
        </xsl:for-each>
        </xsl:attribute>
        </meta> 
        </xsl:if>
        <xsl:if test="/Reports/VFP-Report/Run/property[@id='http-equiv']">
            <xsl:for-each select="/Reports/VFP-Report/Run/property[@id='http-equiv']//meta">
          <xsl:variable name="thisMeta" select="concat(ancestor-or-self::*[@id='http-equiv']/@id ,'.',@name)"/>
          <!-- the extra Run nodes being looked up are potentially evaluated, not original values of the property, 
          so we can account for expressions -->
          <meta  http-equiv="{@name}" content="{/Reports/VFP-Report/Run/property[@id=$thisMeta]}"/>
          </xsl:for-each>
        </xsl:if>

        <title>
          <xsl:choose>
          <xsl:when test="/Reports/VFP-Report[1]/Run/property[@id='title']">
            <xsl:value-of select="/Reports/VFP-Report[1]/Run/property[@id='title']/."/>
          </xsl:when>
          <xsl:otherwise>
            <!-- default/VFP 9.0 RTM handling -->
             <xsl:value-of select="$PageTitlePrefix_LOC"/>
             <xsl:if test="string-length(/Reports/VFP-Report[1]/VFP-RDL/VFPDataSet/VFPFRXPrintJob/@name) = 0">
               <xsl:value-of select="/Reports/VFP-Report[1]/VFP-RDL/@id"/>
             </xsl:if>
             <xsl:value-of select="/Reports/VFP-Report[1]/VFP-RDL/VFPDataSet/VFPFRXPrintJob/@name"/>
          </xsl:otherwise>
          </xsl:choose>
        </title>
        <xsl:call-template name="renderStyles"/>
      </head>
      <body>
        <xsl:call-template name="body"/>
      </body>
    </html>
  </xsl:template>
  <xsl:template name="renderStyles">
     <xsl:call-template name="DocumentStyles"/>
    <xsl:for-each select="/Reports/VFP-Report">
      <xsl:call-template name="Styles">
        <xsl:with-param name="thisReport" select="position()"/>
        <xsl:with-param name="thisReportID" select="./VFP-RDL/@id"/>
      </xsl:call-template>
      <!--        <xsl:call-template name="Script"/> avoid security problems: no script, not even a lone comment indicating TBD -->
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="body">
    <xsl:for-each select="/Reports/VFP-Report">
      <xsl:variable name="thisReport" select="position()"/>
      <xsl:variable name="thisReportID" select="./VFP-RDL/@id"/>
      <xsl:variable name="thisReportRangeFrom" select="number(./VFP-RDL/VFPDataSet/VFPFRXCommand/@RANGEFROM)"/>
      <xsl:variable name="separateTitlePage" select="./Data/*[name()=$titleNodeName] and ./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[bandtype='0' and pagebreak='true']"/>
      <xsl:variable name="separateSummaryPage" select="./Data/*[name()=$summaryNodeName] and ./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[bandtype='8' and pagebreak='true' and ejectbefor='false']"/>
      <xsl:variable name="reportPages" select="count(./Data/*[(name()=$pageHeaderNodeName) or (name()=$titleNodeName and $separateTitlePage=true()) or  (name()=$summaryNodeName and $separateSummaryPage=true())])"/>
      <div>
        <xsl:if test="number($noBody)=1">
          <xsl:attribute name="style">
               position=relative;height=<xsl:value-of select="$reportPages * $thisPageHeight"/>in;
               </xsl:attribute>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="./Data/*[name() = $pageHeaderNodeName]">
            <xsl:if test="$separateTitlePage">
              <xsl:apply-templates select="./Data/*[name()=$titleNodeName]" mode="titlesummarypage">
                <xsl:with-param name="thisReport" select="$thisReport"/>
                <xsl:with-param name="thisReportID" select="$thisReportID"/>
              </xsl:apply-templates>
            </xsl:if>
            <xsl:apply-templates select="./Data/*[name()=$pageHeaderNodeName]" mode="page">
              <xsl:with-param name="thisReport" select="$thisReport"/>
              <xsl:with-param name="thisReportID" select="$thisReportID"/>
              <xsl:with-param name="thisReportRangeFrom" select="$thisReportRangeFrom"/>
            </xsl:apply-templates>
            <xsl:if test="$separateSummaryPage">
              <xsl:apply-templates select="./Data/*[name()=$summaryNodeName]" mode="titlesummarypage">
                <xsl:with-param name="thisReport" select="$thisReport"/>
                <xsl:with-param name="thisReportID" select="$thisReportID"/>
              </xsl:apply-templates>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <!-- unpaginated-->
            <xsl:variable name="thisPageHeaderHeight" select="/Reports/VFP-Report[$thisReport]/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[bandlabel='Page Header'][1]/height  div $FRUs"/>
            <xsl:variable name="thisReportPageHeight" select="number($thisPageHeight - ( $thisPageHeaderHeight +  (/Reports/VFP-Report[$thisReport]/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[bandlabel='Page Footer'][1]/height div $FRUs)) )"/>
            <xsl:if test="./Data/Pages/*[name() = $pageHeaderNodeName]"> <!-- $unpagedModeIncludesOnePageHeader=1" -->
              <!-- show the contents of the first page header -->
              <xsl:apply-templates mode="formattingBand" select="./Data/Pages/*[@idref = /Reports/VFP-Report[$thisReport]/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[bandlabel='Page Header']/frxrecno][1]">
                <xsl:with-param name="thisReport" select="$thisReport"/>
                <xsl:with-param name="thisReportID" select="$thisReportID"/>
                <xsl:with-param name="thisReportPageHeight" select="$thisReportPageHeight"/>
                <xsl:with-param name="thisPageHeight" select="$thisPageHeight"/>
              </xsl:apply-templates>
            </xsl:if>
            
            <!-- the @id criteria below leaves out the Pages and Columns collections, if any -->
            <!-- we could add in an initial page header but then we'd have to do the additional work to handle any title, etc; all the height offsets will change -->
            <xsl:apply-templates select="./Data/*[@idref and ($unpagedModeIncludesTitle=1 or not(name() = $titleNodeName))]" mode="unpagedBand">
              <xsl:with-param name="thisReport" select="$thisReport"/>
              <xsl:with-param name="thisReportID" select="$thisReportID"/>
              <xsl:with-param name="thisPageHeight" select="$thisPageHeight"/>
              <xsl:with-param name="thisReportPageHeight" select="$thisReportPageHeight"/>
              <xsl:with-param name="thisPageHeaderHeight" select="$thisPageHeaderHeight"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="/Reports/VFP-Report/Data/*" mode="titlesummarypage">
    <xsl:param name="thisReport" select="1"/>
    <xsl:param name="thisReportID"/>
    <xsl:param name="thisReportRangeFrom" select="1"/>
    <xsl:variable name="thisBand" select="@id"/>
    <div>
      <xsl:attribute name="style"> width:100%;top:<xsl:value-of select="$thisPageHeight * (number( ./@idref) -$thisReportRangeFrom)"/>in; position:absolute; </xsl:attribute>
      <xsl:apply-templates select="." mode="band">
        <xsl:with-param name="thisReport" select="$thisReport"/>
        <xsl:with-param name="thisReportID" select="$thisReportID"/>
      </xsl:apply-templates>
      <xsl:if test="/Reports/VFP-Report[$thisReport]/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[frxrecno=$thisBand and ejectafter='true']">
        <!-- page footer for this summary page -->
        <xsl:apply-templates select="/Reports/VFP-Report[$thisReport]/Data/*[name()=$pageFooterNodeName][position()=last()]" mode="band">
          <xsl:with-param name="thisReport" select="$thisReport"/>
          <xsl:with-param name="thisReportID" select="$thisReportID"/>
        </xsl:apply-templates>
      </xsl:if>
    </div>
  </xsl:template>
  <xsl:template match="/Reports/VFP-Report/Data/*" mode="page">
    <xsl:param name="thisReport" select="1"/>
    <xsl:param name="thisReportID"/>
    <xsl:param name="thisReportRangeFrom" select="1"/>
    <xsl:variable name="thisPage" select="@id"/>
    <div>
      <xsl:attribute name="style"> width:100%;top:<xsl:value-of select="$thisPageHeight * ($thisPage -$thisReportRangeFrom)"/>in;position:absolute; </xsl:attribute>
      <xsl:apply-templates select="." mode="band">
        <xsl:with-param name="thisReport" select="$thisReport"/>
        <xsl:with-param name="thisReportID" select="$thisReportID"/>
      </xsl:apply-templates>
      <xsl:if test="$thisPage = 1 and /Reports/VFP-Report[$thisReport]/Data/*[name()=$titleNodeName] and /Reports/VFP-Report[$thisReport]/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[bandtype='0' and pagebreak='false']">
        <xsl:apply-templates select="/Reports/VFP-Report[$thisReport]/Data/*[name()=$titleNodeName]" mode="band">
          <xsl:with-param name="thisReport" select="$thisReport"/>
          <xsl:with-param name="thisReportID" select="$thisReportID"/>
        </xsl:apply-templates>
      </xsl:if>
      <xsl:apply-templates select="/Reports/VFP-Report/Data/*[( (@id=$thisPage and contains(concat('|',$pageFooterNodeName,'|',$columnHeaderNodeName,'|',$columnFooterNodeName,'|'),concat('|',name(),'|'))) or (@idref=$thisPage and contains(concat('|',$detailHeaderNodeName,'|',$detailFooterNodeName,'|',$detailNodeName,'|',$groupHeaderNodeName,'|',$groupFooterNodeName,'|',$summaryNodeName,'|'),concat('|',name(),'|'))) )]" mode="band">
        <xsl:with-param name="thisReport" select="$thisReport"/>
        <xsl:with-param name="thisReportID" select="$thisReportID"/>
      </xsl:apply-templates>
    </div>
  </xsl:template>
  <xsl:template match="/Reports/VFP-Report/Data/Pages/*" mode="formattingBand">
    <xsl:param name="thisReport" select="1"/>
    <xsl:param name="thisReportID"/>
    <xsl:param name="thisPageHeight"/>
    <xsl:param name="thisReportPageHeight"/>
    <xsl:variable name="thisPage" select="@id"/>
    <xsl:variable name="thisPageRenderOffset" select="(($thisPage - 1) * $thisReportPageHeight)  + sum((/Reports/VFP-Report[position() &lt; $thisReport]/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[bandlabel='Page Header']/height) ) "/>
    <xsl:for-each select="./*">
      <xsl:variable name="thisID" select="translate(@id,'+','')"/>
      <xsl:call-template name="Render">
        <xsl:with-param name="thisID" select="$thisID"/>
        <xsl:with-param name="thisZ" select="position()"/>
        <xsl:with-param name="thisPage" select="../@idref"/>
        <xsl:with-param name="thisReport" select="$thisReport"/>
        <xsl:with-param name="thisReportID" select="$thisReportID"/>
        <xsl:with-param name="topOffset" select="number($thisPageRenderOffset) * $printDPI"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="/Reports/VFP-Report/Data/*" mode="unpagedBand">
      <xsl:param name="thisReport" select="1"/>
    <xsl:param name="thisReportID"/>
    <xsl:param name="thisPageHeight"/>
    <xsl:param name="thisReportPageHeight"/>
    <xsl:param name="thisPageHeaderHeight"/>
    <xsl:variable name="thisPage" select="@idref"/>
    <xsl:variable name="thisPageRenderOffset">
      <xsl:choose>
        <xsl:when test="../Pages/*[name() = $pageHeaderNodeName]"> <!-- $unpagedModeIncludesOnePageHeader=1" -->
          <xsl:value-of select="(($thisPage - 1) * $thisReportPageHeight) + (sum(/Reports/VFP-Report[position() &lt; $thisReport]/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[bandlabel='Page Header'][1]/height)div $FRUs)  + $thisPageHeaderHeight "/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="(($thisPage - 1) * $thisReportPageHeight) -($thisPageHeaderHeight*$thisPage)  "/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="addAnchor"/>
    <xsl:for-each select="./*">
      <xsl:variable name="thisID" select="translate(@id,'+','')"/>
      <xsl:call-template name="Render">
        <xsl:with-param name="thisID" select="$thisID"/>
        <xsl:with-param name="thisZ" select="position()"/>
        <xsl:with-param name="thisPage" select="../@idref"/>
        <xsl:with-param name="thisReport" select="$thisReport"/>
        <xsl:with-param name="thisReportID" select="$thisReportID"/>
        <xsl:with-param name="topOffset" select="number($thisPageRenderOffset) * $printDPI"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="/Reports/VFP-Report/Data/*" mode="band">
    <xsl:param name="thisReport" select="1"/>
    <xsl:param name="thisReportID"/>
    <xsl:call-template name="addAnchor"/>
    <xsl:for-each select="./*">
      <xsl:variable name="thisID" select="translate(@id,'+','')"/>
      <!--        <xsl:if test="key('Layout',concat($thisID, $thisReportID))/vpos &gt; key('Layout',preceding-sibling::*/concat(@id,$thisReportID))/vpos"><div style="position=absolute;"/></xsl:if>  -->
      <xsl:call-template name="Render">
        <xsl:with-param name="thisID" select="$thisID"/>
        <xsl:with-param name="thisZ" select="position()"/>
        <xsl:with-param name="thisPage" select="../@idref"/>
        <xsl:with-param name="thisReport" select="$thisReport"/>
        <xsl:with-param name="thisReportID" select="$thisReportID"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="Render">
    <xsl:param name="thisID"/>
    <xsl:param name="thisZ"/>
    <xsl:param name="thisPage"/>
    <xsl:param name="thisReport" select="1"/>
    <xsl:param name="thisReportID" select="1"/>
    <xsl:param name="topOffset" select="0"/>
    <xsl:call-template name="addAnchor"/>
    <xsl:choose>
      <xsl:when test="name()=$lineNodeName and key('Layout',concat($thisID, $thisReportID))/height &lt;  key('Layout',concat($thisID, $thisReportID))/width">
        <hr>
          <xsl:call-template name="addClassAttribute">
        <xsl:with-param name="default" select="concat('FRX',$thisReport,'_',$thisID)"/> 
        </xsl:call-template>
        <xsl:call-template name="addTitleAttribute"/>
          <xsl:call-template name="addStyleAttribute">
            <xsl:with-param name="topOffset" select="$topOffset"/>
            <xsl:with-param name="thisZ" select="$thisZ"/>
            <xsl:with-param name="thisReportID" select="$thisReportID"/>
           <xsl:with-param name="thisID" select="$thisID"/>
           <xsl:with-param name="styleType" select="'HR'"/>
          </xsl:call-template>
        </hr>
      </xsl:when>
      <xsl:when test="name()=$lineNodeName">
        <!-- vertical line -->
        <span>
          <xsl:call-template name="addClassAttribute">
            <xsl:with-param name="default" select="concat('FRX',$thisReport,'_',$thisID)"/> 
        </xsl:call-template>
          <xsl:call-template name="addTitleAttribute"/>
          <xsl:call-template name="addStyleAttribute">
            <xsl:with-param name="topOffset" select="$topOffset"/>
            <xsl:with-param name="thisZ" select="$thisZ"/>
            <xsl:with-param name="thisReportID" select="$thisReportID"/>
           <xsl:with-param name="thisID" select="$thisID"/>
              <xsl:with-param name="styleType" select="'VR'"/>
          </xsl:call-template>
        </span>
      </xsl:when>
      <xsl:when test="$useTextAreaForStretchingText=1 and string-length(@hlink) = 0  and name()=$fieldNodeName and key('Layout',concat($thisID, $thisReportID))[stretch='true']">
        <textarea readonly="readonly" rows="0" cols="0">
          <xsl:call-template name="addClassAttribute">
             <xsl:with-param name="default" select="concat('FRX',$thisReport,'_',$thisID)"/> 
        </xsl:call-template>
          <xsl:call-template name="addTitleAttribute"/>
          <xsl:call-template name="addStyleAttribute">
            <xsl:with-param name="topOffset" select="$topOffset"/>
            <xsl:with-param name="thisZ" select="$thisZ"/>
            <xsl:with-param name="thisReportID" select="$thisReportID"/>
          <xsl:with-param name="thisID" select="$thisID"/>
          <xsl:with-param name="styleType" select="'TextArea'"/>
          </xsl:call-template>
          <xsl:value-of select="."/>
        </textarea>
      </xsl:when>
      <xsl:otherwise>
        <div>
          <xsl:call-template name="addClassAttribute">
            <xsl:with-param name="default" select="concat('FRX',$thisReport,'_',$thisID)"/> 
        </xsl:call-template>
          <xsl:call-template name="addTitleAttribute"/>
          <xsl:call-template name="addStyleAttribute">
            <xsl:with-param name="topOffset" select="$topOffset"/>
            <xsl:with-param name="thisZ" select="$thisZ"/>
            <xsl:with-param name="thisReportID" select="$thisReportID"/>
          <xsl:with-param name="thisID" select="$thisID"/>
          <xsl:with-param name="styleType" select="'Div'"/>
          </xsl:call-template>
          <xsl:choose>
            <xsl:when test="name()=$shapeNodeName or name()=$lineNodeName">
              <!-- nothing -->
            </xsl:when>
            <xsl:when test="name()=$pictureNodeName and string-length(@hlink) &gt; 0">
              <a href="{@hlink}">
                <xsl:call-template name="renderPicture">
            <xsl:with-param name="thisReportID" select="$thisReportID"/>
            <xsl:with-param name="thisID" select="$thisID"/>
                </xsl:call-template>
              </a>
            </xsl:when>
            <xsl:when test="name()=$pictureNodeName and string-length(@PLINK) &gt; 0">
              <a href="{translate(@PLINK,'\','/')}"  target="blank">
                <xsl:call-template name="renderPicture">
            <xsl:with-param name="thisReportID" select="$thisReportID"/>
            <xsl:with-param name="thisID" select="$thisID"/>
                </xsl:call-template>
              </a>
            </xsl:when>
            <xsl:when test="name()=$pictureNodeName">
              <xsl:call-template name="renderPicture">
            <xsl:with-param name="thisReportID" select="$thisReportID"/>
            <xsl:with-param name="thisID" select="$thisID"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="string-length(@hlink) &gt; 0">
              <a href="{@hlink}">
                <xsl:call-template name="replaceText"/>
              </a>
            </xsl:when>
            <xsl:when test="string-length(@PLINK) &gt; 0">
              <a href="{translate(@PLINK,'\','/')}" target="blank">
                <xsl:call-template name="replaceText"/>
              </a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="replaceText"/>
            </xsl:otherwise>
          </xsl:choose>
        </div>
      </xsl:otherwise>
    </xsl:choose>
    <!-- /xsl:if -->
  </xsl:template>
  <xsl:template name="getCSSName">
  <xsl:param name="thisReport" select="1"/>
  <xsl:param name="thisItem" select="0"/>
  <xsl:param name="firstPass" select="1"/>
  <xsl:variable name="subst" select="/Reports/VFP-Report[$thisReport]/Data/*/*[@id=$thisItem]/@css"/>
    <xsl:choose>
     <xsl:when test="number($firstPass)=1 or string-length($subst) = 0"><xsl:value-of select="concat('.FRX',$thisReport,'_',$thisItem)"/></xsl:when>
     <xsl:otherwise>.<xsl:value-of select="$subst"/></xsl:otherwise>
     </xsl:choose>
  </xsl:template>
  <xsl:template match="VFPFRXLayoutObject" mode="imagestyles">
    <xsl:param name="thisReport" select="1"/>
    <xsl:param name="firstPass" select="1"/>
     <xsl:call-template name="getCSSName">
     <xsl:with-param name="thisReport" select="$thisReport"/>
     <xsl:with-param name="thisItem" select="frxrecno"/>
     <xsl:with-param name="firstPass" select="$firstPass"/>
     </xsl:call-template>{
  position: absolute;overflow: hidden;width: <xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="width div $FRUs"/></xsl:call-template>in;height: <xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="height div $FRUs"/></xsl:call-template>in;
  }
  <!-- <xsl:if test="offset=0">
left: <xsl:value-of select="hpos div $FRUs"/>in; 
</xsl:if>
<xsl:if test="offset=2">
left: <xsl:value-of select="hpos div $FRUs"/>in; 
</xsl:if> -->
 </xsl:template>
  <xsl:template match="VFPFRXLayoutObject" mode="shapestyles">
    <xsl:param name="thisReport" select="1"/>
   <xsl:param name="firstPass" select="1"/>
     <xsl:call-template name="getCSSName">
     <xsl:with-param name="thisReport" select="$thisReport"/>
     <xsl:with-param name="thisItem" select="frxrecno"/>
     <xsl:with-param name="firstPass" select="$firstPass"/>
     </xsl:call-template>{
   position: absolute ;font-size:1pt; border: <xsl:value-of select="pensize"/>px <xsl:call-template name="pattern"/><xsl:call-template name="pencolor"/>;<xsl:if test="(mode=0 and not(fillpat=0)) or (mode=1 and fillpat=1)">background-color:<xsl:call-template name="fillcolor"/>;</xsl:if>width: <xsl:call-template name="setPrecision"> <xsl:with-param name="theNumber" select="width div $FRUs"/></xsl:call-template>in;left: <xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="hpos div $FRUs"/></xsl:call-template>in;
      }
      <!--    <xsl:if test="stretch='true'">
overflow: auto;
   </xsl:if> -->
  </xsl:template>
  <xsl:template match="VFPFRXLayoutObject" mode="textstyles">
    <xsl:param name="thisReport" select="1"/>
    <xsl:param name="firstPass" select="1"/>
     <xsl:call-template name="getCSSName">
     <xsl:with-param name="thisReport" select="$thisReport"/>
     <xsl:with-param name="thisItem" select="frxrecno"/>
     <xsl:with-param name="firstPass" select="$firstPass"/>
     </xsl:call-template>{
  <xsl:call-template name="getTextAlignment"/>vertical-align: top; font-family: "<xsl:value-of select="fontface"/>"; font-size: <xsl:value-of select="fontsize"/>pt; border: 0px none; padding: 0px; margin: 0px;<xsl:call-template name="getFontAttributes"/>color:<xsl:call-template name="pencolor"/>;<xsl:choose>
      <xsl:when test="mode mod 2 = 1">background-color:transparent;</xsl:when>
      <xsl:otherwise>background-color: <xsl:call-template name="fillcolor"/>;</xsl:otherwise>
    </xsl:choose><xsl:choose>
      <xsl:when test="stretch='true' and objtype=8 and $useTextAreaForStretchingText=1 and $hideScrollbarsForTextAreas=1"> overflow:hidden;margin-top:4px;</xsl:when>
      <xsl:when test="stretch='true' and objtype=8 and $useTextAreaForStretchingText=1"> overflow: auto;margin-top:4px;</xsl:when>
      <xsl:otherwise>overflow:hidden;</xsl:otherwise>
    </xsl:choose> position: absolute;
   }   
    <!-- tbd, make vertical-align more dynamic -->  
  </xsl:template>
  <xsl:template match="VFPFRXLayoutObject" mode="linestyles">
    <xsl:param name="thisReport" select="1"/>
   <xsl:param name="firstPass" select="1"/>
     <xsl:call-template name="getCSSName">
     <xsl:with-param name="thisReport" select="$thisReport"/>
     <xsl:with-param name="thisItem" select="frxrecno"/>
      <xsl:with-param name="firstPass" select="$firstPass"/>
     </xsl:call-template>{
   position:absolute;font-size:1pt;border: <xsl:value-of select="pensize"/>px <xsl:call-template name="pattern"/><xsl:call-template name="pencolor"/>;left: <xsl:value-of select="hpos div $FRUs"/>in;
      <xsl:choose>
      <xsl:when test="height &lt; width"> width: <xsl:value-of select="width div $FRUs"/>in;
  height: <xsl:value-of select="floor(height div $FRUsInPixelsat96DPI)"/>px; margin: 0px;</xsl:when>
      <xsl:otherwise>  height: <xsl:value-of select="height div $FRUs"/>in;
  width: <xsl:value-of select="floor(width div $FRUsInPixelsat96DPI)"/>px;  </xsl:otherwise>
    </xsl:choose>
   }
  </xsl:template>
  <xsl:template name="pattern">
    <xsl:choose>
      <xsl:when test="penpat=0"> none </xsl:when>
      <xsl:when test="penpat=1"> dotted </xsl:when>
      <xsl:when test="penpat=2"> dashed </xsl:when>
      <xsl:otherwise> solid </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="pencolor">#<xsl:call-template name="getHexColorValue">
      <xsl:with-param name="theNumber" select="penred"/>
    </xsl:call-template>
    <xsl:call-template name="getHexColorValue">
      <xsl:with-param name="theNumber" select="pengreen"/>
    </xsl:call-template>
    <xsl:call-template name="getHexColorValue">
      <xsl:with-param name="theNumber" select="penblue"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="fillcolor">#<xsl:call-template name="getHexColorValue">
      <xsl:with-param name="theNumber" select="fillred"/>
      <xsl:with-param name="fill" select="1"/>
    </xsl:call-template>
    <xsl:call-template name="getHexColorValue">
      <xsl:with-param name="theNumber" select="fillgreen"/>
      <xsl:with-param name="fill" select="1"/>
    </xsl:call-template>
    <xsl:call-template name="getHexColorValue">
      <xsl:with-param name="theNumber" select="fillblue"/>
      <xsl:with-param name="fill" select="1"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="getFontAttributes">
    <xsl:param name="theStyles" select="0"/>
    <xsl:choose>
      <xsl:when test="fontbold='true'">font-weight: bold;</xsl:when>
      <xsl:otherwise>font-weight: normal;</xsl:otherwise>
    </xsl:choose>
    <xsl:if test="fontstrikethrough='true' or fontunderline='true'">text-decoration: <xsl:if test="fontstrikethrough='true'">line-through </xsl:if>
      <xsl:if test="fontunderline='true'">underline</xsl:if>;</xsl:if>
    <xsl:if test="fontitalic='true'">font-style: italic;</xsl:if>
  </xsl:template>
  <xsl:template name="getHexColorValue">
    <xsl:param name="theNumber" select="-1"/>
    <xsl:param name="fill" select="0"/>
    <xsl:variable name="useNumber">
      <xsl:choose>
        <xsl:when test="$fill=1 and fillpat &gt; 1 and ((fillred+fillblue+fillgreen) &lt; $fillPatternShade)">
          <xsl:choose>
            <xsl:when test="($fillPatternOffset + $theNumber) &gt; 254">255</xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$fillPatternOffset + $theNumber"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$theNumber"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$useNumber=-1 and $fill=1">FF</xsl:when>
      <xsl:when test="$useNumber=-1">00</xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="getHexForNumber">
          <xsl:with-param name="theNumber" select="floor($useNumber div 16)"/>
        </xsl:call-template>
        <xsl:call-template name="getHexForNumber">
          <xsl:with-param name="theNumber" select="round($useNumber mod 16)"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="setPrecision">
    <xsl:param name="theNumber" select="-1"/>
    <xsl:choose>
      <xsl:when test="$numberPrecision = -1 or not(contains(string($theNumber),'.'))">
        <xsl:value-of select="$theNumber"/>
      </xsl:when>
      <xsl:when test="$numberPrecision &gt; 0">
        <!--        <xsl:value-of select="concat(string(floor($theNumber)),'.',substring(substring-after(string($theNumber),'.'),1,$numberPrecision))"/>  -->
        <xsl:value-of select="format-number($theNumber,concat('##0.',$zeros))"/>
      </xsl:when>
      <xsl:when test="$numberPrecision=0">
        <xsl:value-of select="round($theNumber)"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- shouldn't happen-->
        <xsl:value-of select="$theNumber"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="getHexForNumber">
    <xsl:param name="theNumber" select="-1"/>
    <xsl:choose>
      <xsl:when test="$theNumber=-1">00</xsl:when>
      <xsl:when test="$theNumber &lt; 10">
        <xsl:value-of select="$theNumber"/>
      </xsl:when>
      <xsl:when test="$theNumber = 10">A</xsl:when>
      <xsl:when test="$theNumber = 11">B</xsl:when>
      <xsl:when test="$theNumber = 12">C</xsl:when>
      <xsl:when test="$theNumber = 13">D</xsl:when>
      <xsl:when test="$theNumber = 14">E</xsl:when>
      <xsl:when test="$theNumber = 15">F</xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="getTextAlignment">text-align:<xsl:choose>
      <xsl:when test="objtype=5"><!-- picture field empty for left (default), @I for centered and @J right -->
        <xsl:choose>
          <xsl:when test="string-length(picture) = 0">left;</xsl:when>
          <xsl:when test="contains(picture,'@J')">right;</xsl:when>
          <xsl:otherwise>center;</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="offset=0">left;</xsl:when>
          <xsl:when test="offset=1">right;</xsl:when>
          <xsl:otherwise>center;</xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    <!-- don't include direction at all if you want context -->
    <xsl:if test="mode &lt; 4">direction:<xsl:choose>
        <xsl:when test="mode &gt; 1">rtl;</xsl:when>
        <xsl:otherwise>ltr;</xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <xsl:template name="ExternalStyleSheets">
    <xsl:param name="thisReportNode" select="/Reports/VFP-Report[1]"/>
    <xsl:param name="thisReportID" select="'this report'"/>
   <xsl:if test="count($thisReportNode/Run/property[@id='css_sheet']) &gt; 0">
   <xsl:comment>
   External stylesheet(s) for <xsl:value-of select="$thisReportID"/>
   </xsl:comment>
   <xsl:for-each select="$thisReportNode/Run/property[@id='css_sheet']">
      <link type="text/css" href="{./text()}" rel="stylesheet"/>
   </xsl:for-each>
   </xsl:if>   
  </xsl:template>
  <xsl:template name="DocumentStyles">
  <xsl:comment>Global document styles, if any</xsl:comment>
    <style type="text/css">
     <xsl:comment><xsl:if test="/Reports/VFP-Report[1]/VFP-RDL/VFPDataSet/VFPFRXLayoutObject[objtype=1 and (fontcharset=177 or fontcharset=178)]">
     <xsl:if test="number($noBody)!=1">html{direction:rtl;} 
     body{direction:rtl;}</xsl:if>
     div{direction:rtl;} 
     span{direction:rtl;}
     </xsl:if>
     </xsl:comment>
    </style>
  
  </xsl:template>
  <xsl:template name="Styles">
    <xsl:param name="thisReport" select="1"/>
    <xsl:param name="thisReportID"/>
    <xsl:comment>
    Styles for report # <xsl:value-of select="$thisReport"/>  in this run, 
    <xsl:value-of select="$thisReportID"/>
    </xsl:comment>
    
    <style type="text/css">
    
      <xsl:comment>
    
        <xsl:apply-templates select="./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[objtype=6]" mode="linestyles">
          <xsl:with-param name="thisReport" select="$thisReport"/>
        </xsl:apply-templates>
      
      <xsl:for-each select="./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[objtype=6]">
        <xsl:variable name="frxrecno" select="frxrecno"/>
        <xsl:if test="/Reports/VFP-Report[$thisReport]/Data/*/*[@id=$frxrecno]/@css">
              <xsl:apply-templates select="." mode="linestyles">
              <xsl:with-param name="thisReport" select="$thisReport"/>
                 <xsl:with-param name="firstPass" select="0"/>
              </xsl:apply-templates>
        </xsl:if>
      </xsl:for-each>
        
        <xsl:apply-templates select="./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[objtype=7]" mode="shapestyles">
          <xsl:with-param name="thisReport" select="$thisReport"/>
        </xsl:apply-templates>

      <xsl:for-each select="./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[objtype=7]">
         <xsl:variable name="frxrecno" select="frxrecno"/>
        <xsl:if test="/Reports/VFP-Report[$thisReport]/Data/*/*[@id=$frxrecno]/@css">
              <xsl:apply-templates select="." mode="shapestyles">
              <xsl:with-param name="thisReport" select="$thisReport"/>
                 <xsl:with-param name="firstPass" select="0"/>
              </xsl:apply-templates>
        </xsl:if>
      </xsl:for-each>

        <xsl:apply-templates select="./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[contains('|5|8|',concat('|',./objtype,'|'))]" mode="textstyles">
          <xsl:with-param name="thisReport" select="$thisReport"/>
        </xsl:apply-templates>

      <xsl:for-each select="./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[contains('|5|8|',concat('|',./objtype,'|'))]">
        <xsl:variable name="frxrecno" select="frxrecno"/>
        <xsl:if test="/Reports/VFP-Report[$thisReport]/Data/*/*[@id=$frxrecno]/@css">
              <xsl:apply-templates select="." mode="textstyles">
              <xsl:with-param name="thisReport" select="$thisReport"/>
                 <xsl:with-param name="firstPass" select="0"/>
              </xsl:apply-templates>
        </xsl:if>
      </xsl:for-each>
        
        <xsl:apply-templates select="./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[objtype=17]" mode="imagestyles">
          <xsl:with-param name="thisReport" select="$thisReport"/>
        </xsl:apply-templates>

      <xsl:for-each select="./VFP-RDL/VFPDataSet/VFPFRXLayoutObject[objtype=17]">
        <xsl:variable name="frxrecno" select="frxrecno"/>
        <xsl:if test="/Reports/VFP-Report[$thisReport]/Data/*/*[@id=$frxrecno]/@css">
              <xsl:apply-templates select="." mode="imagestyles">
              <xsl:with-param name="thisReport" select="$thisReport"/>
                 <xsl:with-param name="firstPass" select="0"/>
              </xsl:apply-templates>
        </xsl:if>
      </xsl:for-each>

    
      </xsl:comment>
    
    </style>

   <xsl:call-template name="ExternalStyleSheets">
   <xsl:with-param name="thisReportNode" select="/Reports/VFP-Report[$thisReport]"/> 
   <xsl:with-param name="thisReportID" select="$thisReportID"/>
   </xsl:call-template>

  </xsl:template>
  <xsl:template name="replaceText">
    <xsl:choose>
      <xsl:when test="$useTextAreaForStretchingText=1">
        <xsl:value-of select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="replaceWhiteSpace">
          <xsl:with-param name="string" select="."/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="renderPicture">
  <xsl:param name="thisReportID"/>
  <xsl:param name="thisID"/>
    <img>
      <xsl:attribute name="alt"><xsl:choose><xsl:when test="@alt"><xsl:value-of select="@alt"/></xsl:when><xsl:otherwise><xsl:value-of select="key('Layout',concat($thisID, $thisReportID))/unpathedimg"/></xsl:otherwise></xsl:choose></xsl:attribute>
      <xsl:variable name="srcImage">
   <xsl:choose>
          <xsl:when test="@img and $externalFileLocation">
            <xsl:value-of select="translate(concat($externalFileLocation,@img),'\','/')"/>
          </xsl:when>
          <xsl:when test="@img and not(contains(./@img,':'))">
               <xsl:value-of select="translate(@img,'\','/')"/>
          </xsl:when>
          <xsl:when test="@img">
            <xsl:value-of select="concat('file://',translate(@img,'\','/'))"/>
          </xsl:when>
          <xsl:when test="$copyImageFiles = '1'">
            <xsl:value-of select="translate(concat($externalFileLocation,key('Layout',concat($thisID, $thisReportID))/unpathedimg),'\','/')"/>
          </xsl:when>
          <xsl:when test="string-length(./text()) &gt; 0 and not(contains(./text(),':')) ">
            <xsl:value-of select="translate(./text(),'\','/')"/>
          </xsl:when>
          <xsl:when test="string-length(./text()) &gt; 0">
            <xsl:value-of select="concat('file://',translate(./text(),'\','/'))"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('file://',translate(key('Layout',concat($thisID, $thisReportID))/pathedimg,'\','/'))"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:attribute name="src"><xsl:value-of select="$srcImage"/></xsl:attribute>
      <xsl:attribute name="style"><xsl:variable name="imgGeneral" select="key('Layout',concat($thisID, $thisReportID))"/><xsl:choose><xsl:when test="$imgGeneral/general='0' "><!-- clip top, right, bottom, left -->
 clip: rect(0in,<xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="@w div $printDPI"/></xsl:call-template>in,<xsl:value-of select="@h div $printDPI"/>in,0in);
 </xsl:when><xsl:when test="$imgGeneral/general='1'"><!-- scale and retain --><xsl:choose><xsl:when test="@h &gt; @w">
 width:100%;
 </xsl:when><xsl:otherwise>
 height:100%;
 </xsl:otherwise></xsl:choose></xsl:when><xsl:otherwise><!-- stretch to fill frame -->
 height: <xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="@h div $printDPI"/></xsl:call-template>in;    
width: <xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="@w div $printDPI"/></xsl:call-template>in;    
 </xsl:otherwise></xsl:choose></xsl:attribute>
    </img>
  </xsl:template>
  <xsl:template name="addClassAttribute">
  <xsl:param name="item" select="."/>
  <xsl:param name="default" select="''"/>
  <xsl:attribute name="class"><xsl:choose>
  <xsl:when test="string-length($item/@CSS) &gt; 0">
  <xsl:value-of select="$item/@CSS"/>
  </xsl:when>
  <xsl:when test="string-length($item/@css) = 0">
  <xsl:value-of select="$default"/>
  </xsl:when>
  <xsl:otherwise>
  <xsl:value-of select="$item/@css"/>
  </xsl:otherwise>
  </xsl:choose></xsl:attribute>
  </xsl:template>
  <xsl:template name="addTitleAttribute">
    <xsl:param name="item" select="."/>
    <xsl:if test="string-length($item/@title) &gt; 0">
      <xsl:attribute name="title"><xsl:value-of select="$item/@title"/></xsl:attribute>
    </xsl:if>
  </xsl:template>
  <xsl:template name="addAnchor">
    <xsl:param name="item" select="."/>
    <xsl:if test="string-length($item/@anchor) &gt; 0">
      <a>
	  <xsl:attribute name="{$anchorAttr}"><xsl:value-of select="$item/@anchor"/></xsl:attribute> 
        <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
      </a>
    </xsl:if>
  </xsl:template>
  <xsl:template name="addStyleAttribute">
    <xsl:param name="topOffset" select="0"/>
    <xsl:param name="thisZ" select="1"/>
    <xsl:param name="thisReportID"/>
    <xsl:param name="thisID"/>
    <xsl:param name="styleType" select="'Div'"/>
<!-- do NOT mess around with the white space in here, even though it 
looks ugly the way it is!! -->
<xsl:attribute name="style">z-Index:<xsl:value-of select="$thisZ"/>;left:<xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="@l div $printDPI"/></xsl:call-template>in;
top:<xsl:choose>
  <xsl:when test="styleType='TextArea'"><xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="((@t  + $topOffset) div $printDPI) - .1"/></xsl:call-template></xsl:when>
  <xsl:otherwise><xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="(@t +$topOffset) div $printDPI"/></xsl:call-template></xsl:otherwise>
</xsl:choose>in;<xsl:choose>
  <xsl:when test="$styleType='VR'">width:0in;</xsl:when>
  <xsl:when test="$styleType='TextArea'">width:<xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="@w div $printDPI"/></xsl:call-template>in;</xsl:when>
<xsl:when test="$styleType='Div'">width:<xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="@w div $printDPI"/></xsl:call-template>in;height:<xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="@h div $printDPI"/></xsl:call-template>in;</xsl:when></xsl:choose><xsl:if test="not($styleType='Div')">height:<xsl:call-template name="setPrecision"><xsl:with-param name="theNumber" select="@h div $printDPI"/></xsl:call-template>in;</xsl:if>
<xsl:if test="$useDynamicTextAttributes=1 and key('Layout',concat($thisID,$thisReportID))[objtype=5 or objtype=8]">
<xsl:call-template name="addDynamicTextStyleAttributes"/>
</xsl:if>
</xsl:attribute>
    </xsl:template>
    <xsl:template name="addDynamicTextStyleAttributes">
  <!-- dynamic values for font, omit these attributes if they don't appear on each object-->
  <xsl:if test="@FNAME">
    font-family:'<xsl:value-of select="@FNAME"/>';font-size:<xsl:value-of select="@FSIZE"/>pt;
    <xsl:if test="((@FSTYLE div 128) mod 2 = 1) or ( (@FSTYLE div 4) mod 2 = 1)">text-decoration:<xsl:if test="((@FSTYLE div 128) mod 2 = 1)">line-through</xsl:if><xsl:if test="( (@FSTYLE div 8) mod 2 = 1)">underline</xsl:if>;</xsl:if>
    font-weight:<xsl:choose><xsl:when test="@FSTYLE mod 2 = 1">bold</xsl:when><xsl:otherwise>normal</xsl:otherwise></xsl:choose>;
    font-style:<xsl:choose><xsl:when test="(@FSTYLE div 2) mod 2 =1">italic</xsl:when><xsl:otherwise>normal</xsl:otherwise></xsl:choose>;
   background-color:<xsl:call-template name="getAlphaColor">
   <xsl:with-param name="alpha" select="@FA"/>
   <xsl:with-param name="r" select="@FR"/>
   <xsl:with-param name="g" select="@FG"/>
   <xsl:with-param name="b" select="@FB"/>
   </xsl:call-template>;color:<xsl:call-template name="getAlphaColor"/>;
    </xsl:if>
    </xsl:template>

   <xsl:template name="getAlphaColor">
   <xsl:param name="alpha" select="@PA"/>
   <xsl:param name="r" select="@PR"/>
   <xsl:param name="g" select="@PG"/>
   <xsl:param name="b" select="@PB"/>
   <xsl:choose>
   <xsl:when test="$alpha=0">transparent</xsl:when>
   <xsl:when test="$alpha=255 or ($r+$g+$b &gt; $fieldAlphaOpacityShade)"><xsl:value-of select="concat('rgb(',$r,',',$g,',',$b,')')"/></xsl:when>
   <xsl:otherwise><xsl:value-of select="concat('rgb(',$r+$fieldAlphaOpacityOffset,',',$g+$fieldAlphaOpacityOffset,',',$b+$fieldAlphaOpacityOffset,')')"/></xsl:otherwise>
   </xsl:choose>


   </xsl:template>
  
    <xsl:template name="replaceWhiteSpace">
    <xsl:param name="string" select="."/>
    <xsl:choose>
      <xsl:when test="contains($string,'&#xA;')">
        <xsl:call-template name="replaceWhiteSpace">
          <xsl:with-param name="string" select="substring-before($string, '&#xA;')"/>
        </xsl:call-template>
        <br/>
        <xsl:call-template name="replaceWhiteSpace">
          <xsl:with-param name="string" select="substring-after($string, '&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="Script">
    <script language="JavaScript">
      <xsl:comment>
     //TBD
      </xsl:comment>
    </script>
  </xsl:template>
  <xsl:template match="*|@*" mode="debug">
   <xsl:copy-of select="."/>
  </xsl:template> 
</xsl:stylesheet>
