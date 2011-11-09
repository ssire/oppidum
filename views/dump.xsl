<?xml version="1.0" encoding="UTF-8"?>
<!-- Oppidum : page view generation

    Author: Stéphane Sire <s.sire@free.fr>

    Shows a model by duplicating it. Manages a menu with a few actions (edit,
    archive, unarchive) if the user has the corresponding rights enabled.

    Returns 
      - a <site:view> with a <site:content> element containing all the model 
      - adds an optional <site:menu> element with buttons for allowed actions
      - <error> models are converted to a single <p> message inside the
        <site:content>

    July 2011
 -->

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:site="http://oppidoc.com/oppidum/site"
	xmlns="http://www.w3.org/1999/xhtml">

	<xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="no"/>
	
	<xsl:param name="xslt.rights"></xsl:param>	
	
	<xsl:template match="/">
		<site:view>     
		  <xsl:if test="$xslt.rights != ''">
		    <site:menu> 
          <xsl:if test="contains($xslt.rights, 'archive') and (not(*/@status) or (*/@status != 'archive'))">
            <button title="Archive page" onclick="javascript:window.location.href+='/archive'">Archive</button>            
          </xsl:if>  
          <xsl:if test="contains($xslt.rights, 'unarchive') and (*/@status = 'archive')">
            <button title="Unarchive page" onclick="javascript:window.location.href+='/unarchive'">Unarchive</button>            
          </xsl:if>  
          <xsl:if test="contains($xslt.rights, 'edit')">
            <button title="Edit page" onclick="javascript:window.location.href+='/edit'">Edit</button>
          </xsl:if>
		    </site:menu>
		  </xsl:if>
  		<xsl:apply-templates select="*"/>
		</site:view>	
	</xsl:template>             
                               
  <!-- Universal error template rule : relay low-level error messages to the epilogue -->
	<xsl:template match="/error">
		<site:error>          
	    <site:message><xsl:value-of select="message"/></site:message>
	  </site:error>
	</xsl:template>
	                        
  <!-- Special treatment to remove the root node from the model this allows to
  let the mesh decide how to wrap it (e.g. if <article> in the model, the mesh
  may change it to something else) -->
	<xsl:template match="*"> 
		<site:content>                       
      <xsl:if test="@status = 'archive'">
        <p style="color:red; background: yellow; margin: 0.5em 2em 0 0.5em; float: left">ARCHIVE</p>
      </xsl:if>
  		<xsl:copy-of select="*"/>     
	  </site:content>
	</xsl:template>  
	
</xsl:stylesheet>
