xquery version "1.0";
(: --------------------------------------
   Oppidum framework: Logout model

   Author: Stéphane Sire <s.sire@free.fr>
   
   Logout user from database and session.
   
   The request parameter 'url' contains the full path of a site page
   to redirect the user after a successful login.    
   
   WARNING: directly calls response:redirect-to() so it must be used in a
   pipeline with no view and no epilogue !
   
   August 2011
   -------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";  
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";   
import module namespace response="http://exist-db.org/xquery/response";
                                              
let $goto-url := request:get-parameter('url', '.')
return
  <Redirected>
    {                               
    xdb:login("/db", "guest", "guest"),
    (: do not forget to call session:invalidate() in a second time 
       in the epilogue as add-message may use the session :)
    oppidum:add-message('ACTION-LOGOUT-SUCCESS', (), true()),                        
    response:redirect-to(xs:anyURI($goto-url))    
    }
  </Redirected>
