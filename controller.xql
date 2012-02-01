xquery version "1.0";         
(: --------------------------------------
   Oppidum framework : sample controller

   Sample Oppidum controller. When deployed as an application it just define 
   a home page URL that shows Oppidum version, a scaffold page and the admin
   module. The admin module can then be used to replace the application itself 
   with another from a ZIP file.

   NOTE: gen:process() still serves Oppidum static resources. The convention is 
   that these resources should be addressed with a URL  ending in '/static/*' 
   (usually generated in the site's epilogue). However we recommend not to use it
   and to use an Apache proxy or NGINX proxy configured to directly take all 
   the '/oppidum/static/*' resources from the file system.

   Author: Stéphane Sire <s.sire@free.fr>

   January 2012 - (C) 2012 Oppidoc SARL
   -------------------------------------- :)

import module namespace gen = "http://oppidoc.com/oppidum/generator" at "lib/pipeline.xqm";

(: ======================================================================
                  Site default access rights
   ====================================================================== :)                 
declare variable $access := <access>
  <rule method="POST" role="u:admin" message="super admin"/>
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

(: ======================================================================
                  Site mappings
   ====================================================================== :)                 
declare variable $mapping := <site startref="home" supported="login logout install" db="/db/www/oppidum" confbase="/db/www/oppidum">
  <item name="home">
    <model src="oppidum:models/version.xql"/>
  </item>
  <!-- Oppidum administration module (backup / restore) -->  
  <item name="admin" resource="none" method="POST">
    <access>
      <rule action="GET POST" role="u:admin" message="admin"/>
    </access>    
    <model src="oppidum:modules/admin/restore.xql"/>
    <view src="oppidum:modules/admin/restore.xsl"/>
    <action name="POST">
      <model src="oppidum:modules/admin/restore.xql"/>
      <view src="oppidum:modules/admin/restore.xsl"/>   
    </action>
  </item>
  <item name="scaffold" resource="none">
    <model src="oppidum:models/scaffold.xql"/>
    <view src="oppidum:views/scaffold.xsl"/>
  </item> 
</site>;
                          
(: NOTE : call oppidum:process with false() to disable ?debug=true mode :)
gen:process($exist:root, $exist:prefix, $exist:controller, $exist:path, 'fr', true(), $access, $actions, $mapping)

    
  
