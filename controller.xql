xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum framework sample controller

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Sample Oppidum controller. It just define a home page URL that shows
   Oppidum version, a scaffold page and the admin module. The admin module can
   then be used to update the Oppidum applications installed inside the DB.

   NOTE: gen:process() still serves Oppidum static resources. The convention is
   that these resources should be addressed with a URL ending in '/static/*'
   (usually generated in the site's epilogue). However we recommend not to use it
   and to use an Apache proxy or NGINX proxy configured to directly serve all
   '/oppidum/static/*' resources directly from the file system.

   To use this script you must first execute scripts/bootstrap.sh to intialize 
   the /db/www/oppidum/config and /db/www/oppidum/mesh collections

   February 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

import module namespace xdb="http://exist-db.org/xquery/xmldb"; (: only for 'curtain' mode :)
import module namespace gen = "http://oppidoc.com/oppidum/generator" at "../oppidum/lib/pipeline.xqm";

(: ======================================================================
                  Site default access rights
   ====================================================================== :)
declare variable $access := <access>
  <rule action="POST" role="u:admin" message="database administrator"/>
</access>;

(: ======================================================================
                  Site default actions
   ====================================================================== :)
declare variable $actions := <actions error="models/error.xql">
  <action name="login" depth="0"> <!-- may be GET or POST -->
    <model src="oppidum:actions/login.xql"/>
    <view src="oppidum:views/login.xsl"/>
  </action>
  <action name="logout" depth="0">
    <model src="oppidum:actions/logout.xql"/>
  </action>
  <!-- NOTE: unplug this action from @supported on mapping's root node in production -->
  <action name="install" depth="0">
    <model src="oppidum:scripts/install.xql"/>
  </action>
</actions>;

declare variable $curtain := (); 
(:declare variable $curtain := <site startref="home" supported="login" db="/db/www/oppidum" confbase="/db/www/oppidum" key="oppidum" mode="test">
   <item name="*">
   <model src="models/maintenance.xql"/>
 </item>
</site>;:)

let $mapping := fn:doc('/db/www/oppidum/config/mapping.xml')/site
return
  if ($curtain and (xdb:get-current-user() != 'admin')) then 
    gen:process($exist:root, $exist:prefix, $exist:controller, $exist:path, 'fr', true(), $access, $actions, $curtain)
  else
    gen:process($exist:root, $exist:prefix, $exist:controller, $exist:path, 'fr', true(), $access, $actions, $mapping)