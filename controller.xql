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
    (: FIXME: should display forbidden :)
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
      <cache-control cache="yes"/>
    </ignore>   
    
  
