<?xml version="1.0" encoding="UTF-8"?>
<!-- Oppidum framework

    Login form generation

    Author: Stéphane Sire <s.sire@free.fr>
    
    Turns a <Login> model to a <site:content> module containing a login dialog
    box. Does nothing if the model contains a <Redirected> element (e.g. as a
    consequence of a successful login when handling a POST - see login.xql).

    July 2011
 -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <!-- integrated URL rewriting... -->
  <xsl:param name="xslt.base-url"></xsl:param>
                                    
  <xsl:template match="/">
    <site:view>       
      <xsl:apply-templates select="*"/>
    </site:view>
  </xsl:template>                        
                                  
  <!-- Login dialog box -->
  <xsl:template match="Login[not(Redirected)]">
    <site:content>   
      <div>
        <h1>Authentification</h1>
        <form action="{$xslt.base-url}login?url={To}" method="POST" style="margin: 0 auto 0 2em; width: 20em">
          <p style="text-align: right">
            <label for="login-user">Nom d'utilisateur</label>
            <input id="login-user" type="text" name="user" value="{User}"/>
          </p>
          <p style="text-align: right">
            <label for="login-passwd">Mot de passe</label>
            <input id="login-passwd" type="password" name="password"/>
          </p>                                   
          <p style="text-align: right; margin-right: 30px">
            <input type="submit"/>
          </p>
        </form>
      </div>        
    </site:content>
  </xsl:template>  
  
  <xsl:template match="Login[Redirected]">
    <p>Goto <a href="{Redirected}"><xsl:value-of select="Redirected"/></a></p>
  </xsl:template>
  
</xsl:stylesheet>