<?xml version="1.0" encoding="UTF-8"?>

<!-- Oppidum errors and messages utility

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     August 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns:xhtml="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="/">
    <site:view>
      <site:title>Oppidum <xsl:value-of select="string(Display/@Type)"/> test tool</site:title>
      <site:content>
        <h1>Showing <xsl:value-of select="string(Display/@Type)"/> from <xsl:value-of select="string(Display/@Resource)"/></h1>
        <p>This page shows all <xsl:value-of select="string(Display/@Type)"/> defined by the <xsl:value-of select="string(Display/@Application)"/> application. Click on an type to simulate it in a full pipeline (incl. an epilogue). Click on the <sup>xml</sup> label to simulate it in a 1 step pipeline such as an Ajax submission pipeline.</p>
        <p>These <xsl:value-of select="string(Display/@Type)"/> are also available as a <a href="messages.csv?app={Display/@Application}">csv file</a>.</p>
        <p>Application :
          <input type="text" id="app" value="{Display/@Application}"></input>
          <button onclick="javascript:window.location.href='{Display/@Type}'+'?app='+$('#app').val()">reload</button>
          <button onclick="javascript:$('#app').val('oppidum')">reset</button>
          Switch to <button><xsl:attribute name="onclick">javascript:window.location.href='<xsl:apply-templates select="Display/@Type" mode="switch"/>?app='+$('#app').val()</xsl:attribute><xsl:apply-templates select="Display/@Type" mode="switch"/></button>
        </p>
        <table>
          <thead>
            <tr>
              <th>Type</th>
              <th>Code</th>
            </tr>
          </thead>
          <tbody>
            <xsl:apply-templates select="Display/Error | Display/Message"/>
          </tbody>
        </table>
      </site:content>
    </site:view>
  </xsl:template>

  <xsl:template match="@Type[.='errors']" mode="switch">messages</xsl:template>

  <xsl:template match="@Type[.='messages']" mode="switch">errors</xsl:template>

  <xsl:template match="Error|Message">
    <tr>
      <td><xsl:apply-templates select="Type"/></td>
      <td><xsl:apply-templates select="Code"/></td>
    </tr>
  </xsl:template>

  <xsl:template match="Type">
    <a href="?code={.}&amp;app={/Display/@Application}"><xsl:value-of select="."/></a> <sup><a href="{/Display/@Type}.xml?code={.}&amp;app={/Display/@Application}" class="ajax" target="_blank">xml</a></sup>
  </xsl:template>

  <xsl:template match="Code">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="Code[.='MISSING']">
    <span style="color:red">MISSING</span>
  </xsl:template>

</xsl:stylesheet>
