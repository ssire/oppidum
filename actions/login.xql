xquery version "1.0";
(: --------------------------------------
   UAP Web Site

   Author: Stéphane Sire <s.sire@free.fr>
   
   Either generates the login page model to ask the user to login or tries to login 
   the user if credentials are supplied and redirects on success.                   
   
   The optional request parameter 'url' contains the full path of a site page
   to redirect the user after a successful login.
   
   July 2011
   -------------------------------------- :)

import module namespace xdb = "http://exist-db.org/xquery/xmldb";  
import module namespace session = "http://exist-db.org/xquery/session";  
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";   
                                              
let   
  $ref := request:get-attribute('oppidum.command')/resource,      
  $user := request:get-parameter('user', ''),
  $goto-url := request:get-parameter('url', 'login'),
  $method := request:get-method()
  
return
  <Login>
  {
    if ($method = 'POST') then
      (: tries to login, ask oppidum to redirect on success :)
      let $password := request:get-parameter('password', '')
      return
        (: check that user account has not been disabled using oppidum conventions to locate account file :)
        (: check before attempting to login / create the sesssion :)
        let $home-uri := concat($ref/@db, '/users/', $user, '/user.xml')
        let $status := 
          if (doc-available($home-uri)) then
            string(fn:doc($home-uri)/User/@Status)
          else
            'dont-care'
        return
          if ($status != 'inactive') then
            if (xdb:login('/db', $user, $password, true())) then 
            (                                        
            oppidum:add-message('ACTION-LOGIN-SUCCESS', $user, true()),
            oppidum:redirect($goto-url),
            <Redirected>{$goto-url}</Redirected>        
            )
            else (: login page model, asks again, keeps user because wrong password in most cases :)          
              oppidum:add-error('ACTION-LOGIN-FAILED', (), true())
          else
            oppidum:add-error('ACTION-LOGIN-DESACTIVATED', (), true())
    else                    
      (),
    <User>{ if (($user != '') and xdb:exists-user($user)) then $user else () }</User>,
    <To>{ $goto-url }</To>
  }
  </Login>    
