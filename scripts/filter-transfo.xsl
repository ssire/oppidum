<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  
    <xsl:param name="oppidum.base">/db/www/</xsl:param>
    <xsl:param name="script.base">/db/www/views/</xsl:param>
  
  <!-- Expands relative URL into absolute xmldb: URL because relative does not work in database hosting condition -->
    <!-- <xsl:template match="xsl:include">
        <xsl:copy>
            <xsl:attribute name="href">
                <xsl:value-of select="concat('xmldb:exist://', $oppidum.base, substring-after(@href, '..'))"/>
            </xsl:attribute>
        </xsl:copy>
    </xsl:template>    -->

    <!-- Replaces xsl:include with xsl:template rules from the included XSLT file because xsl:include does not work 
         in Tomcat hosting conditions  -->
    <xsl:template match="xsl:include">
      <xsl:variable name="lib-path">
        <xsl:call-template name="resolve">
          <xsl:with-param name="url"><xsl:value-of select="@href"/></xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="doc-uri">
        <xsl:choose>
          <xsl:when test="starts-with(@href, '../')">
            <xsl:value-of select="concat($oppidum.base, $lib-path)"/>                       
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($script.base, $lib-path)"/>                        
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:copy-of select="document(concat('xmldb:exist://', normalize-space($doc-uri)))/xsl:stylesheet/*"/>
    </xsl:template>
  
    <xsl:template name="resolve">
      <xsl:param name="url"></xsl:param>
      <xsl:choose>
        <xsl:when test="starts-with($url, '../')">
          <xsl:call-template name="resolve">
            <xsl:with-param name="url"><xsl:value-of select="substring-after($url, '../')"/></xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$url"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>     

    <xsl:template match="*|@*|processing-instruction()|text()|comment()">
        <xsl:copy>
            <xsl:apply-templates select="*|@*|processing-instruction()|text()|comment()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>