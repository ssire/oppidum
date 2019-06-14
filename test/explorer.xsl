<?xml version="1.0" encoding="UTF-8"?>

<!-- Oppidum mapping explorer

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     August 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns:xhtml="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="/Mapping">
    <site:view>
      <site:title>Oppidum mapping explorer tool for <xsl:value-of select="@module"/></site:title>
      <site:content>
        <h1>Oppidum mapping explorer tool <i><xsl:value-of select="@module"/></i> module</h1>
        <p>Explore module : <xsl:apply-templates select="Modules/Module"/></p>

        <!-- TOC construction implies pre-ordered input -->
        <table id="toc" style="width: 100%;">
          <tbody>
            <tr>
              <xsl:for-each select="Range">
                <td>
                  <h4>
                    <a class="toc" href="#ancre_{@Letter}" data-letter="{@Letter}"><xsl:value-of select="@Letter"/></a>
                  </h4>
                </td>
              </xsl:for-each>
            </tr>
          </tbody>
        </table>

        <div id="ide-explorer">
          <xsl:apply-templates select="Range"/>
        </div>
      </site:content>
    </site:view>
  </xsl:template>

  <xsl:template match="Module">
    <a href="?m={.}" style="text-decoration:none"><xsl:value-of select="."/></a><xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="Module[/Mapping/@module = .]">
    <b><xsl:value-of select="."/></b><xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="Range">
    <div class="letter">
      <td>
        <h1>
          <a name="ancre_{@Letter}"><xsl:value-of select="@Letter"/></a>
          <sup><a class="top" href="#toc"></a></sup>
        </h1>
      </td>
    </div>
    <table class="explorer">
      <thead>
        <th>Kind</th>
        <th>Verb</th>
        <th>URL</th>
        <th>Model</th>
        <th>View</th>
        <th>Mesh</th>
      </thead>
      <tbody>
        <xsl:apply-templates select="Row"/>
      </tbody>
    </table>
  </xsl:template>

  <!-- duplicate Row for method/upported verbs/actions-->
  <xsl:template match="Row">
    <xsl:apply-templates select="method"/>
  </xsl:template>

  <xsl:template match="method">
    <tr>
      <td><xsl:apply-templates select="../@type"/></td>
      <td><xsl:value-of select="substring(@name, 1, 1)"/></td>
      <td>
        <xsl:choose>
          <xsl:when test="@name eq 'GET'">
            <a class="path" href="../../{/Mapping/@module}{.}{../@path}" target="_blank"><xsl:value-of select="../@extpath"/></a>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="style">color:#111</xsl:attribute>
            <xsl:value-of select="../@extpath"/>
          </xsl:otherwise>
        </xsl:choose>
      </td>
      <td><xsl:apply-templates select="@model"/></td>
      <td><xsl:apply-templates select="@view"/></td>
      <td><xsl:apply-templates select="@mesh"/></td>
    </tr>
  </xsl:template>

  <xsl:template match="@type">
  </xsl:template>

  <xsl:template match="@type[. = 'action']" priority="1">~
  </xsl:template>

  <xsl:template match="@type[. = 'collection']" priority="1">+
  </xsl:template>

</xsl:stylesheet>
