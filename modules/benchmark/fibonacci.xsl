<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="html" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="base-url">/</xsl:param>

  <xsl:template match="/results">
    <h1>Suite de fibonacci</h1>
    <p>Durée : <xsl:value-of select="@duration"/> ms</p>
    <p>Mémoire avant : <xsl:value-of select="@free-mem-before"/></p>
    <p>Mémoire après : <xsl:value-of select="@free-mem-after"/></p>
    <p>Nom d'éléments : <xsl:value-of select="@max"/></p>
    <h2>Élément</h2>
    <xsl:apply-templates select="value"/>
  </xsl:template>
  
  <xsl:template match="/error">
    <h1>Suite de fibonacci</h1>
    <p><xsl:value-of select="."/></p>
  </xsl:template>  

  <xsl:template match="value">
    <p>Fib(<xsl:value-of select="@rank"/>) = <xsl:value-of select="."/></p>
  </xsl:template>

</xsl:stylesheet>
