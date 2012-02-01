<?xml version="1.0" encoding="UTF-8"?>
<!-- Oppidum framework

    Turns a scaffold content model into a view.

    Author: Stéphane Sire <s.sire@free.fr>

    December 2011 - Copyright (c) Oppidoc S.A.R.L
 -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns:file="http://exist-db.org/xquery/file"
  xmlns:system="http://exist-db.org/xquery/system"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="no"/>

  <!-- <xsl:param name="xslt.rights">none</xsl:param>   -->
  
  <xsl:template match="/">
    <site:view>     
      <site:content>
        <xsl:apply-templates select="data | confirm | backup | system:restore"/>
      </site:content>
    </site:view>  
  </xsl:template>

  <xsl:template match="confirm[@action = 'restore']"> 
    <div style="text-align:center; margin: 2em auto 0 auto">
      <form action="admin" method="post">
        <p>
          Please confirm that you want to restore the archive<br/>“<xsl:value-of select="file"/>”<br/>from<br/>“<xsl:value-of select="path"/>” ?
        </p>
        <p>
          <label for="mdp">Password</label> : <input id="mdp" type="text" name="mdp" value=""/>
        </p>
        <p>
          <xsl:if test="not(@pwd)">
            <input type="checkbox" name="keeplast" value="true" checked="true">use last password entered</input>
          </xsl:if>
        </p>
        <p>
          <input type="hidden" name="path" value="{path}"/>
          <input type="hidden" name="file" value="{file}"/>
          <input type="submit" name="list" value="Cancel" style="margin-right: 1em"/>
          <input type="submit" name="restore" value="Restore"/>
        </p>
      </form>
    </div>
  </xsl:template>

  <xsl:template match="confirm[@action = 'backup']"> 
    <div style="text-align:center; margin: 2em auto 0 auto">
      <form action="admin" method="post">
        <p >
          Please confirm that you want to backup the collection<br/>“<xsl:value-of select="collection"/>”<br/>to the directory<br/>“<xsl:value-of select="path"/>” ?
        </p>
        <p>
          <label for="mdp">Password</label> : <input id="mdp" type="text" name="mdp" value=""/>
        </p>
        <p>
          <xsl:if test="not(@pwd)">
            <input type="checkbox" name="keeplast" value="true" checked="true">use last password entered</input>
          </xsl:if>
        </p>
        <p>
          <input type="hidden" name="path" value="{path}"/>
          <input type="hidden" name="collection" value="{collection}"/>
          <input type="submit" name="list" value="Cancel" style="margin-right: 1em"/>
          <input type="submit" name="backup" value="Backup"/>
        </p>
      </form>
  </div>
  </xsl:template>

  <xsl:template match="data[@error]"> 
    <div style="text-align:center; margin: 2em auto 0 auto">
      <form action="admin" method="post">
        <p>
        <span style="width: 10%">Path : </span><input style="width:80%" name="path" type="text" value="{file:list/@directory}"/> <span style="width: 10%;margin-left:1em"><input type="submit" name="list" value="List"/></span>
        </p>      
        <xsl:apply-templates select="." mode="explain"/>
      </form>
    </div>
  </xsl:template>

  <xsl:template match="data[@error = 'path-not-found']" mode="explain"> 
    <p style="color:red">“<xsl:value-of select="file:list/@directory"/>” not found</p>
    <p>You must enter a correct path before being able to backup or restore</p>
  </xsl:template>

  <xsl:template match="data[@error = 'collection-not-found']" mode="explain"> 
    <p style="color:red">Collection “<xsl:value-of select="collection"/>” not found inside the database</p>
    <p>You must enter a valid collection for backup</p>
  </xsl:template>
  
  <xsl:template match="data[@error = 'password-missing']" mode="explain"> 
    <p style="color:red">You must give a password</p>
    <p>Please try again</p>
  </xsl:template>  

  <xsl:template match="data[@error = 'backup-exception']" mode="explain">
    <p>Could not backup collection “<xsl:value-of select="param"/>” to directory “<xsl:value-of select="file:list/@directory"/>”</p>
    <p style="color:red"><xsl:value-of select="message"/></p>
    <p>Please try again</p>
  </xsl:template>

  <xsl:template match="data[@error = 'restore-exception']" mode="explain">
    <p>Could not restore file “<xsl:value-of select="param"/>” from directory “<xsl:value-of select="file:list/@directory"/>”</p>
    <p style="color:red"><xsl:value-of select="message"/></p>
    <p>Please try again</p>
  </xsl:template>
  
  <xsl:template match="data"> 
    <form action="admin" method="post">
      <input type="hidden" name="state" value="confirm"/>
      <div style="position:relative">
        <p>
        <span style="width: 10%">Path : </span><input style="width:80%" name="path" type="text" value="{file:list/@directory}"/> <span style="width: 10%;margin-left:1em"><input type="submit" name="list" value="List"/></span>
        </p>
        <div style="float:left;width:50%">
          <xsl:apply-templates select="file:list"/>
        </div>
        <div style="float:left;width:50%">
          <p>Pick up a collection to backup :</p>
          <ul style="padding:0">
            <xsl:apply-templates select="list/collection"/>
            <li style="list-style-type: none"><input type="radio" name="collection" value="custom"></input><input style="width:75%" name="custom" type="text" value="/db" size="30"/></li>            
          </ul>
          <p style="text-align:center">
            <input type="submit" name="backup" value="Backup"/>
          </p>
        </div>
      </div>
    </form>
  </xsl:template> 
  
  <xsl:template match="file:list[file:file]"> 
    <p>Pick up a ZIP file to restore :</p>
    <ul style="padding:0">
      <xsl:apply-templates select="file:file"/>
    </ul>
    <p style="text-align:center">
      <input type="submit" name="restore" value="Restore"/>
    </p>
  </xsl:template>

  <xsl:template match="file:list"> 
    <p style="margin-right:2em">This directory does not contain any ZIP archive to restore.</p>
  </xsl:template> 

  <xsl:template match="file:file"> 
    <li style="list-style-type: none"><input type="radio" name="file" value="{@name}"><xsl:value-of select="@name"/></input> (<xsl:value-of select="floor(@size div 1024)"/> KB)</li>
  </xsl:template>  

  <xsl:template match="collection"> 
    <li style="list-style-type: none"><input type="radio" name="collection" value="{.}"><xsl:value-of select="."/></input></li>
  </xsl:template>  
  
  <xsl:template match="system:restore"> 
    <p>Restoration of <xsl:value-of select="@name"/></p>
    <ul style="font-size: 12px; font-family: courrier">
      <xsl:apply-templates select="system:collection|system:resource"/>
    </ul>
    <p><a href="admin">Back</a> to admin</p>
  </xsl:template>
  
  <xsl:template match="system:collection"> 
    <li><b><xsl:value-of select="."/></b></li>
  </xsl:template>

  <xsl:template match="system:resource"> 
    <li><xsl:value-of select="."/></li>
  </xsl:template>

  <xsl:template match="backup"> 
    <div style="margin: 2em auto 0 auto; text-align: center; width: 30em">
      <p>The backup of collection “<xsl:value-of select="@collection"/>” to a ZIP archive<br/>inside “<xsl:value-of select="@path"/>” has been triggered on the server</p>
      <p>Refresh the view to see it when ready, check if a new ZIP file has been created because it is possible that some unreported errors prevented the task to succeed.</p>
      <form action="admin" method="post">
        <input type="hidden" name="path" value="{@path}"/>
        <p><input type="submit" name="list" value="Refresh"/></p>
      </form>
    </div>
  </xsl:template>

</xsl:stylesheet>
