<?xml version="1.0" encoding="UTF-8"?>
<!-- Oppidum framework

    Turns a scaffold content model into a view.

    Author: Stéphane Sire <s.sire@free.fr>

    December 2011 - Copyright (c) Oppidoc S.A.R.L
 -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="no"/>

  <!-- <xsl:param name="xslt.rights">none</xsl:param>   -->
  
  <xsl:template match="/">
    <site:view>     
      <site:content>
        <xsl:apply-templates select="scaffold"/>
      </site:content>
    </site:view>  
  </xsl:template>             
                               
  <xsl:template match="scaffold"> 
    <div>
    Page : <xsl:value-of select="meta/page"/><br/>
    Action : <xsl:value-of select="meta/action"/><br/>
    Reference : <span style="color: blue"><xsl:value-of select="meta/reference/collection"/></span><span style="color: red"><xsl:value-of select="meta/reference/resource"/></span>
    </div>
    
    <xsl:apply-templates select="content"/>
  </xsl:template>  

  <xsl:template match="content"> 
    <xsl:copy-of select="*"/>
  </xsl:template>  

  
</xsl:stylesheet>
