<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xt="http://ns.inria.org/xtiger">
    
   <!-- Possible implementation for a <install:fix-template-import> element inside a <group>
        for post-deployment inclusion of xt:import statements 
        See also install:fix-xsl-import in install.xqm -->

   <!-- FIXME: very slow (several seconds !) when executed from eXist - replace it 
        with a Typeswitch expression in XQuery ? -->

    <xsl:param name="script.base">/db/www/oppidum/</xsl:param>

    <!-- Replaces xt:import with the XTiger components declared in the xt:head element 
         of the included XTiger XML file. It only works if both template files are stored 
         in the database in the same {module}/templates folder  -->
    <xsl:template match="xt:import">
      <xsl:variable name="tplname">
        <xsl:call-template name="tail">
          <xsl:with-param name="path"><xsl:value-of select="@src"/></xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="doc-uri">
        <xsl:value-of select="concat(concat($script.base, 'templates/', $tplname)"/>
      </xsl:variable>
      <xsl:copy-of select="document(concat('xmldb:exist://', normalize-space($doc-uri)))//xt:head/xt:component"/>
    </xsl:template>

    <xsl:template name="tail">
      <xsl:param name="path"></xsl:param>
      <xsl:choose>
        <xsl:when test="contains($path, '/')">
          <xsl:call-template name="tail">
            <xsl:with-param name="path"><xsl:value-of select="substring-after($path, '/')"/></xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$path"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>    

    <xsl:template match="*|@*|processing-instruction()|text()|comment()">
        <xsl:copy>
            <xsl:apply-templates select="*|@*|processing-instruction()|text()|comment()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>