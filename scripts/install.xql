xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum framework installation script

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Loads Oppidum library into the database as '/db/www/oppidum'

   February 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace request = "http://exist-db.org/xquery/request";
import module namespace install = "http://oppidoc.com/oppidum/install" at "../lib/install.xqm";   

declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

(: WARNING: do not forget to set the correct path below webapp here ! :)
declare variable $local:base := "/projets/oppidum";

declare variable $policies := <policies xmlns="http://oppidoc.com/oppidum/install">
  <policy name="admin" owner="admin" group="dba" perms="rwur--r--"/>
</policies>;

declare variable $site := <site xmlns="http://oppidoc.com/oppidum/install">
  <collection name="/db/sites"/>
</site>;

declare variable $code := <code xmlns="http://oppidoc.com/oppidum/install">
  <collection name="/db/www" policy="admin" inherit="true"/>
  <group name="config" mandatory="true">
    <collection name="/db/www/oppidum/config">
      <files pattern="init/mapping.xml"/>
      <files pattern="init/modules.xml"/>
      <files pattern="init/errors.xml"/>
      <files pattern="init/skin.xml"/>
    </collection>
  </group>
  <group name="mesh" mandatory="true">
    <collection name="/db/www/oppidum/mesh">
      <files pattern="mesh/*.html"/>
    </collection>
  </group>
  <group name="code">
    <collection name="/db/www/oppidum">
      <files pattern="controller.xql"/>
      <files pattern="epilogue.xql"/>
      <files pattern="actions/*.xql" preserve="true"/>
      <files pattern="lib/*.xqm" preserve="true"/>
      <files pattern="models/*.xql" preserve="true"/>
      <files pattern="modules/**/*.xql" preserve="true"/>
      <files pattern="modules/**/*.xqm" preserve="true"/>
      <files pattern="modules/**/*.xsl" preserve="true"/>
      <files pattern="scripts/filter-transfo.xsl" preserve="true"/>
<!--  <files pattern="scripts/filter-template.xsl" preserve="true"/> -->
<!--  <files pattern="templates/**/*.xhtml" preserve="true"/> -->
      <files pattern="views/**/*.xsl" preserve="true"/>
    </collection>
  </group>
</code>;

declare variable $static := <static xmlns="http://oppidoc.com/oppidum/install">
  <group name="resources">
    <collection name="/db/www/oppidum">
      <files pattern="resources/**/*.css" preserve="true"/>
      <files pattern="resources/**/*.js" preserve="true"/>
      <files pattern="resources/**/*.png" preserve="true"/>
      <files pattern="resources/**/*.gif" preserve="true"/>
      <files pattern="resources/**/*.html" preserve="true"/>
      (: note this a trick because photo.xhtml is a forrest and cannot be imported as text/xml :)
      <files pattern="resources/lib/axel/bundles/photo/photo.xhtml" type="text/plain" preserve="true"/>
    </collection>
  </group>
</static>;

install:install($local:base, $policies, $site, $code, $static, "oppidum", ())

