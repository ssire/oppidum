<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" media-type="text/csv" omit-xml-declaration="yes" indent="yes"/>
  <!-- <xsl:output method="text" media-type="text/plain" omit-xml-declaration="yes" indent="yes"/> -->
  
  <xsl:param name="delim" select="';'" />
  <xsl:param name="quote" select="'&quot;'" />
  <xsl:param name="break" select="'&#xA;'" />

  <xsl:template match="/">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="/error">
    <xsl:value-of select="message"/>
  </xsl:template>

  <!-- *********************************************** -->
  <!-- Plain table/row/* input model conversion to CSV -->
  <!-- *********************************************** -->

  <xsl:template match="/table" priority="1">
    <xsl:apply-templates select="row[1]" mode="headers"/>
    <xsl:apply-templates select="row"/>
  </xsl:template>

  <xsl:template match="row[1]" mode="headers">
    <xsl:for-each select="*">
      <xsl:value-of select="concat($quote, normalize-space(local-name(.)), $quote)"/>
      <xsl:if test="following-sibling::*">
        <xsl:value-of select="$delim" />
      </xsl:if>
    </xsl:for-each>
    <xsl:value-of select="$break" />
  </xsl:template>

  <xsl:template match="row">
    <xsl:for-each select="*">
      <xsl:value-of select="concat($quote, normalize-space(.), $quote)"/>
      <xsl:if test="following-sibling::*">
        <xsl:value-of select="$delim" />
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="following-sibling::*">
      <xsl:value-of select="$break" />
    </xsl:if>
  </xsl:template>

  <!-- *********************************************** -->
  <!-- Display with Error or Message elements  -->
  <!-- actually generated from errandmsg.xql -->
  <!-- *********************************************** -->
  <xsl:template match="Display">
    <xsl:text>Key</xsl:text><xsl:apply-templates select="Languages/Language"/><xsl:value-of select="$break" />
    <xsl:apply-templates select="Error|Message"/>
  </xsl:template>

  <xsl:template match="Language"><xsl:value-of select="$delim" /><xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="Error">
    <xsl:variable name="pos"><xsl:value-of select="count(preceding-sibling::Error) + 1" /></xsl:variable>
    <xsl:value-of select="Type"/>
    <xsl:for-each select="/Display/Languages/Language">
      <xsl:variable name="lang"><xsl:value-of select="."/></xsl:variable>
      <xsl:value-of select="$delim" /><xsl:value-of select="concat($quote, normalize-space(/Display/Error[position() = $pos]/message[@lang = $lang]), $quote)" />
    </xsl:for-each>
    <xsl:if test="following-sibling::*">
      <xsl:value-of select="$break" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="Message">
    <xsl:variable name="pos"><xsl:value-of select="count(preceding-sibling::Message) + 1" /></xsl:variable>
    <xsl:value-of select="Type"/>
    <xsl:for-each select="/Display/Languages/Language">
      <xsl:variable name="lang"><xsl:value-of select="."/></xsl:variable>
      <xsl:value-of select="$delim" /><xsl:value-of select="concat($quote, normalize-space(/Display/Message[position() = $pos]/message[@lang = $lang]), $quote)" />
    </xsl:for-each>
    <xsl:if test="following-sibling::*">
      <xsl:value-of select="$break" />
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>