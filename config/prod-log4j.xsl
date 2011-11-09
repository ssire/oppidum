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

    <!-- Convert log4j.xml for use in war-file -->
    <xsl:output method="xml" doctype-system="log4j.dtd" indent="yes"/>
    
    <xsl:param name="DEBUG">0</xsl:param>
    
    <xsl:template match="category[@name='org.mortbay']">
    </xsl:template>

    <xsl:template match="appender/param[@name='File']">
        <param name="File" value="logs/{substring-after(@value,'logs/')}"/>
    </xsl:template>                            
    
    <!-- add webapp.site appender  -->
    <xsl:template match="appender[position() = last()]">
      <xsl:copy>                                           
        <xsl:apply-templates select="@*|node()|comment()"/>
      </xsl:copy>
      <xsl:text>
      	
</xsl:text>   	
<appender name="webapp.site" class="org.apache.log4j.RollingFileAppender">
    <param name="File" value="logs/site.log"/>
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
    <xsl:choose>
      <xsl:when test="$DEBUG = '1'">
        <priority value="debug"/>
      </xsl:when>
      <xsl:otherwise>
        <priority value="debug"/>
      </xsl:otherwise>
    </xsl:choose>
    <appender-ref ref="webapp.site"/>
</category><xsl:text>
	
</xsl:text>  
    </xsl:template>     
                                 
    <!-- set priority -->   
    <xsl:template match="category/priority[@value='debug']|root/priority[@value='debug']">
      <xsl:choose>
        <xsl:when test="$DEBUG = '1'">
          <priority value="debug"/>
        </xsl:when>
        <xsl:otherwise>
          <priority value="warn"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>                            

    <xsl:template match="category/priority[@value='trace']">
      <xsl:choose>
        <xsl:when test="$DEBUG = '1'">
          <priority value="trace"/>
        </xsl:when>
        <xsl:otherwise>
          <priority value="warn"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>                                

    <xsl:template match="category/priority[@value='info']">
      <xsl:choose>
        <xsl:when test="$DEBUG = '1'">
          <priority value="info"/>
        </xsl:when>
        <xsl:otherwise>
          <priority value="warn"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>                                
    
    <!-- remove selected appenders... -->
    <xsl:template match="appender[@name='exist.ehcache']|category[appender-ref/@ref='exist.ehcache']">
    </xsl:template>

    <xsl:template match="*|@*|node()|comment()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()|comment()"/>
        </xsl:copy>
    </xsl:template>

</xsl:transform>
