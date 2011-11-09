<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: dist-war-log4j.xsl 5616 2007-04-07 13:19:18Z dizzzz $ -->
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
<!-- 
    priority levels:
    trace ? ... debug, info, warn, error, fatal
    
    The root logger is assigned the default priority level DEBUG. 
    All loggers inherit priority level from their parent or nearest existing ancestor 
    logger, which is in effect until they are assigned another priority level.     

    -->

    <xsl:output method="xml" doctype-system="log4j.dtd" indent="yes"/>
    
	<xsl:variable name="location">${exist.home}/webapp/WEB-INF/logs/site.log</xsl:variable>
	
	<xsl:template match="category[@name='org.exist.http.urlrewrite']/priority">
    <priority value="trace"/>
	</xsl:template>
	    
  <!-- add webapp.site appender  -->
  <xsl:template match="appender[position() = last()]">
    <xsl:copy>                                           
      <xsl:apply-templates select="@*|node()|comment()"/>
    </xsl:copy>
    <xsl:text>   
      	
</xsl:text>   	
<appender name="webapp.site" class="org.apache.log4j.RollingFileAppender">
    <param name="File" value="{$location}"/>
    <param name="MaxFileSize" value="500KB"/>
    <layout class="org.apache.log4j.PatternLayout">
        <param name="ConversionPattern" value="%d [%t] %-5p (%F [%M]:%L) - %m %n"/>
    </layout>
</appender><xsl:text>
	
</xsl:text>
    </xsl:template> 

    <xsl:template match="category[position() = last()]">
      <xsl:copy>                                           
        <xsl:apply-templates select="@*|node()|comment()"/>
      </xsl:copy>      
      <xsl:text>

</xsl:text>
<category name="webapp.site" additivity="false">
    <priority value="debug"/>
    <appender-ref ref="webapp.site"/>
</category><xsl:text>
	
</xsl:text>  
    </xsl:template>     
    
    <xsl:template match="*|@*|node()|comment()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()|comment()"/>
        </xsl:copy>
    </xsl:template>

</xsl:transform>
