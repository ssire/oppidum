<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  
	  <xsl:param name="oppidum.base">/db/www</xsl:param>
  
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
    	<xsl:variable name="lib-path"><xsl:value-of select="$oppidum.base"/><xsl:value-of select="substring-after(@href, '..')"/></xsl:variable>
    	<xsl:copy-of select="document(concat('xmldb:exist://', $lib-path))/xsl:stylesheet/xsl:template"/>
    </xsl:template>

    <xsl:template match="*|@*|processing-instruction()|text()|comment()">
        <xsl:copy>
            <xsl:apply-templates select="*|@*|processing-instruction()|text()|comment()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>