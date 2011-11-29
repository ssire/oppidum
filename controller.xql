xquery version "1.0";         
(: --------------------------------------
   Oppidum framework : controller
   
   Serves Oppidum static resources which can be shared between sites (e.g. AXEL library)
   
   The convention is that these resources should be addressed with a URL
   ending in '/static/*' (usually generated in the site's epilogue). 
   
   This controller should not be called in production use because the Apache
   proxy should be configured to directly take all the '/oppidum/static/*'
   resources inside the content of the 'resources/*' folder that contains
   them.

   DEPRECATED (except to start scrips/install.xql)

   Author: Stéphane Sire <s.sire@free.fr>
  
   August 2011
   -------------------------------------- :)

import module namespace gen = "http://oppidoc.com/oppidum/generator" at "lib/pipeline.xqm";

(: ======================================================================
                  Site default access rights
   ====================================================================== :)                 
declare variable $access := <access>
</access>;

(: ======================================================================
                  Site default actions
   ====================================================================== :)                 
declare variable $actions := <actions error="models/error.xql">
  <action name="login" depth="0"> <!-- may be GET or POST --> 
    <model src="actions/login.xql"/>
    <view src="views/login.xsl"/>
  </action>  
  <action name="logout" depth="0"> 
    <model src="actions/logout.xql"/>
  </action>
  <!-- NOTE: unplug this action from @supported on mapping's root node in production --> 
  <action name="install" depth="0"> 
    <model src="scripts/install.xql"/>
  </action>  
</actions>;

(: ======================================================================
                  Site mappings
   ====================================================================== :)                 
declare variable $mapping := <site startref="home" supported="login logout install">
  <item name="home">
    <model src="models/version.xql"/>
  </item> 
</site>;
                          
let 
  $url-payload := if ($exist:prefix = '') then $exist:path else substring-after($exist:path, $exist:root),
  $app-root := if ($exist:prefix = '') then concat($exist:controller, '/') else concat($exist:root, '/')
  
return
  if (starts-with($url-payload, "/static/")) then
    (: alternatively we could set WEB-INF/controller-config.xml to rewrite /static :)
     <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
     	  <forward url="{concat($app-root, substring-after($url-payload, '/static/'))}"/>
      	<cache-control cache="yes"/>
     </dispatch>                                                                         
     (: TODO: cache management for static resources... :)
     
  else      
    (: NOTE : call oppidum:process with false() to disable ?debug=true mode :)
    gen:process($exist:root, $exist:prefix, $exist:controller, $exist:path, 'fr', true(), $access, $actions, $mapping)
    
  (: TODO: test environment to return 'FORBIDDEN' in test and production 
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
      <cache-control cache="yes"/>
    </ignore>   :)
    
  
