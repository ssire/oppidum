<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xt="http://ns.inria.org/xtiger" version="1.0">
<!-- 

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Rewrites photo_URL parameter and generates a photo_base parameter of an XTiger XML template
     
     Rewrites photo_URL to :
     - concat($xslt.base-url, $xsl.photo-base, '/images') when $xsl.photo-base is defined
     - concat($xslt.base-url, 'images') otherwise

     Rewrites photo_base to concat($xslt.base-url, $xsl.photo-base)
     
     DO NOT REWRITE if the photo_URL starts with './' (e.g. ./images) : this way it is possible to
     store in the "templates" folder some templates that need rewriting and some templates that do
     not (for instance this is the case when using the oppistore "collection" module with one
     collection for each resource configured to keep images inside an "images" sub-collection)
     
     FIXME: currently discards all parameters of the photo plugin instead of preserving them
     (e.g. param="photo_URL=images;trigger=click")
     
     April 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
  -->
    <xsl:output method="xml" media-type="text/xml" omit-xml-declaration="yes" indent="no"/>
    <xsl:param name="xslt.base-url">/</xsl:param>
    <xsl:param name="xslt.photo-base">$</xsl:param>

   <!-- Replaces photo_URL and adds photo_base in attribute param in order 
        to use a single image collection for the whole site rooted at site's top level -->
   <xsl:template match="@param[(parent::xt:use[(@types='photo')] or parent::xt:attribute[@types='photo']) and not(starts-with(normalize-space(substring-after(., 'photo_URL=')),'./'))]">
        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="$xslt.photo-base = '$'">
                    <xsl:value-of select="substring-before(.,'photo_URL')"/>photo_URL=<xsl:value-of select="concat($xslt.base-url, 'images')"/>;photo_base=<xsl:value-of select="$xslt.base-url"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring-before(.,'photo_URL')"/>photo_URL=<xsl:value-of select="concat($xslt.base-url, concat($xslt.photo-base, '/images'))"/>;photo_base=<xsl:value-of select="concat($xslt.base-url, $xslt.photo-base)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:attribute name="param">
            <xsl:value-of select="normalize-space($value)"/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- copy all -->
    <xsl:template match="*|@*|processing-instruction()|text()|comment()">
        <xsl:copy>
            <xsl:apply-templates select="*|@*|processing-instruction()|text()|comment()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>