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
              <xsl:for-each select="Row">
                <xsl:variable name="pos" select="position()"/>
                <xsl:variable name="initial" select="translate(substring(@sortkey, 2, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
                <xsl:variable name="prev_initial" select="translate(substring(../Row[$pos - 1]/@sortkey, 2, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
                <xsl:if test="$prev_initial != $initial">
                  <td>
                    <h4>
                      <a class="toc" href="#ancre_{$initial}" data-letter="{$initial}"><xsl:value-of select="$initial"/></a>
                    </h4>
                  </td>
                </xsl:if>
              </xsl:for-each>
            </tr>
          </tbody>
        </table>

        <table id="ide-explorer">
          <thead>
            <th>Kind</th>
            <th>URL</th>
            <th>Verbs</th>
            <th>GET</th>
            <th>POST</th>
            <th>Action</th>
          </thead>
          <tbody>
            <xsl:apply-templates select="Row">
              <!-- <xsl:sort select="@sortkey"/> -->
            </xsl:apply-templates>
          </tbody>
        </table>
        <script type="text/javascript">
          $('#ide-explorer a').bind('click', function(ev) { var t, s; s = $(ev.target).attr('href-cache') || $(ev.target).attr('href'); if (s.indexOf('*') != '-1') { $(ev.target).attr('href-cache',s); $(ev.target).attr('href', s.replace('*', prompt('step 1'))) } });
        </script>
      </site:content>
    </site:view>
  </xsl:template>

  <xsl:template match="Module">
    <a href="?m={.}" style="text-decoration:none"><xsl:value-of select="."/></a><xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="Module[/Mapping/@module = .]">
    <b><xsl:value-of select="."/></b><xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="Row">
    <xsl:variable name="initial" select="translate(substring(@sortkey,2,1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
    <xsl:variable name="pos" select="position()"/>
    <xsl:variable name="prev_initial" select="translate(substring(../Row[$pos - 1]/@sortkey,2, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
    <xsl:if test="$prev_initial != $initial">
      <tr class="letter" colspan="6">
        <td>
          <h1>
            <a name="ancre_{$initial}">
              <xsl:value-of select="$initial"/>
            </a>
            <sup>
              <a class="top" href="#toc"></a>
            </sup>
          </h1>
        </td>
      </tr>
    </xsl:if>
    <tr>
      <td><xsl:apply-templates select="@type"/></td>
      <td><xsl:apply-templates select="@path"/></td>
      <td><xsl:apply-templates select="@type" mode="GET"/><xsl:text> </xsl:text><xsl:apply-templates select="@type" mode="POST"/>
      </td>
      <td><xsl:apply-templates select="@Gmodel"/></td>
      <td><xsl:apply-templates select="@Pmodel"/></td>
      <td><xsl:apply-templates select="@Amodel"/></td>
    </tr>
  </xsl:template>

  <xsl:template match="@path"><xsl:value-of select="../@extpath"/>
  </xsl:template>

  <xsl:template match="@path[not(../@GET) and not(../@POST)]">
    <xsl:attribute name="style">color:#999</xsl:attribute>
    <xsl:value-of select="../@extpath"/>
  </xsl:template>

  <xsl:template match="@path[../@GET]"><a href="../../{/Mapping/@module}{.}" target="_blank"><xsl:value-of select="../@extpath"/></a>
  </xsl:template>

  <xsl:template match="@path[../@type = 'action']"><a href="../../{/Mapping/@module}{.}" target="_blank"><xsl:value-of select="../@extpath"/></a>
  </xsl:template>

  <xsl:template match="@type">
  </xsl:template>

  <xsl:template match="@type[. = 'action']">~
  </xsl:template>

  <xsl:template match="@type[. = 'collection']">+
  </xsl:template>

  <xsl:template match="@type" mode="GET">
  </xsl:template>

  <xsl:template match="@type[../@GET]" mode="GET">G
  </xsl:template>

  <xsl:template match="@type[. = 'action']" mode="GET">*
  </xsl:template>

  <xsl:template match="@type" mode="POST">
  </xsl:template>

  <xsl:template match="@type[../@POST]" mode="POST">P
  </xsl:template>

  <xsl:template match="@type[. = 'action']" mode="POST">
  </xsl:template>

  <xsl:template match="@Gmodel"><xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="@Pmodel"><xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="@Amodel"><xsl:value-of select="."/>
  </xsl:template>

</xsl:stylesheet>
