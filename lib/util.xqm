xquery version "1.0";    
(: -----------------------------------------------
   Oppidum framework utilities

   Debug, Error, Message, Access rights, ...

	 Author: Stéphane Sire <s.sire@free.fr>

   November 2011 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)     

module namespace oppidum = "http://oppidoc.com/oppidum/util";            

import module namespace request="http://exist-db.org/xquery/request";
import module namespace response="http://exist-db.org/xquery/response";
import module namespace session="http://exist-db.org/xquery/session";      
import module namespace xdb = "http://exist-db.org/xquery/xmldb";                    

declare variable $oppidum:DB_ERR_LOCATION := '/db/oppidum/config/errors.xml';

declare function oppidum:path-to-ref () as xs:string
{         
  let $r := request:get-attribute('oppidum.command')/resource
  return string-join(($r/@db, $r/@collection, $r/@resource), '/')
}; 

declare function oppidum:path-to-ref-col () as xs:string
{         
  let $r := request:get-attribute('oppidum.command')/resource
  return concat($r/@db, '/', $r/@collection)
}; 

(: ======================================================================
   Asks epilogue to redirect
   ======================================================================
:) 
declare function oppidum:redirect( $url as xs:string ) as empty()
{                                                  
  request:set-attribute('oppidum.redirect.to', $url)
}; 
    
(: ======================================================================
   Shortcut to dump a message to the site's log file
   ======================================================================
:) 
declare function oppidum:log( $msg as xs:string ) as empty()
{                                                                       
  util:log-app('debug', 'webapp.site', $msg)
}; 

(: ======================================================================
   Dumps eXist variables related to the request URL to the site's log file
   ======================================================================
:) 
declare function oppidum:log-parameters( $params as element() ) as empty()
{   
  let $out := for $p in $params/param
              return concat($p/@name, ' = [', $p/@value, ']')
  return
    oppidum:log(string-join($out, codepoints-to-string(13)))
};

(: ======================================================================
   Asks epilogue to redirect
   ======================================================================
:) 
declare function oppidum:my-add-error-or-msg( 
  $from as xs:string, $type as xs:string, 
  $object as xs:string*, $sticky as xs:boolean ) as empty()
{                      
  if ($sticky) then
    let 
      $cur := session:get-attribute($from),
      $new := (for $e in $cur return $e, concat($type, ':', $object))
    return
      session:set-attribute($from, $new)
  else
    let 
      $cur := request:get-attribute($from),
      $new := (for $e in $cur return $e, concat($type, ':', $object))
    return
      request:set-attribute($from, $new)
};        

declare function oppidum:my-get-error-or-msg($from as xs:string) as xs:string*
{
  let 
    $flash := session:get-attribute($from),
    $empty := session:set-attribute($from, ())
  return ( request:get-attribute($from), $flash)
};

declare function oppidum:add-error( $type as xs:string, $object as xs:string*, $sticky as xs:boolean ) as empty()
{
  oppidum:my-add-error-or-msg('errors', $type, $object, $sticky)                      
};

declare function oppidum:has-error() as xs:boolean
{              
  let $res := (count(request:get-attribute('errors')) > 0) or (count(session:get-attribute('errors')) > 0)
  return $res
};

declare function oppidum:get-errors() as xs:string*
{        
  oppidum:my-get-error-or-msg('errors')  
};

declare function oppidum:add-message( $type as xs:string, $object as xs:string*, $sticky as xs:boolean ) as empty()
{
  oppidum:my-add-error-or-msg('flash', $type, $object, $sticky)                      
};

declare function oppidum:has-message() as xs:boolean
{              
  let $res := (count(request:get-attribute('flash')) > 0) or (count(session:get-attribute('flash')) > 0)
  return $res
};
 
declare function oppidum:get-messages() as xs:string*
{        
  oppidum:my-get-error-or-msg('flash')  
};  

declare function oppidum:render-error( 
  $db as xs:string,
  $err-type as xs:string, 
  $err-clue as xs:string*, 
  $lang as xs:string,
  $exec as xs:boolean) as element()
{
  let 
    $error := 
      let 
        $sitefile := concat($db, '/config/errors.xml')
      return        
        if (doc-available($sitefile) 
           and (not(empty(doc($sitefile)/errors/error[@type = $err-type])))) then
           doc($sitefile)/errors/error[@type = $err-type]
        else doc($oppidum:DB_ERR_LOCATION)/errors/error[@type = $err-type],
    $msgs := 
      if ($error/message[@lang = $lang]) then 
        $error/message[@lang = $lang] 
      else 
        $error/message, (: any language :)
    $msg := 
      if ($err-clue) then
        string($msgs[string(@noargs) != 'yes'][1])
      else 
        string($msgs[1]),
    $message := if ($msg) then $msg else concat("Error (", $err-type, ")"),     
    $arg := if ($err-clue) then $err-clue else '',
    $text : = if (contains($message, "%s")) then replace($message, "%s", $arg) else $message
    (: FIXME: substituer la clue :)
    
  return        
    <error>
      {
      if ($error/@code) then
        if ($exec) then
          response:set-status-code($error/@code)
        else
          attribute code { $error/@code }
      else (),
      <message>{$text}</message>
      }
    </error>
};

declare function oppidum:render-errors( $db as xs:string, $lang as xs:string ) as node()*
{                          
  for $e in oppidum:get-errors()
  let $type := substring-before($e, ':')
  let $clue := substring-after($e, ':')
  return                      
   oppidum:render-error($db, $type, if ($clue != '') then $clue else (), $lang, true())
};                 
  
(: ======================================================================
   Checks if the current user is allowed to execute the action in the command.
   Returns true or false. In the later case, it also registers an
   UNAUTHORIZED-ACCESS in Oppidum error flash.
   ======================================================================
:) 
declare function oppidum:check-rights-for( $cmd as element(), $defaults as element()* ) as xs:boolean
{                                                                                          
  let $target := $cmd/resource
  return
    if (($target/@access) and ($cmd/@action = 'GET')) then
      (: syntactic sugar for 'GET' access control :)
      oppidum:my-access-control(oppidum:test-role-for-command($target/@access, $cmd), $target)
    else
      let $rules := if ($target/access) then $target/access else $defaults
      return                         
        let $rule := $rules/rule[$cmd/@action = tokenize(@action, ' ')]
        return     
          if ($rule) then
            oppidum:my-access-control(oppidum:test-role-for-command($rule/@role, $cmd), $rule)
          else
            true()
};

declare function oppidum:my-access-control( $granted as xs:boolean, $info as element() ) as xs:boolean 
{
  let $error := 
    if (not($granted)) then
      request:set-attribute('oppidum.grantee', $info/@message)
    else ()
  return $granted
};

(: ======================================================================
   Returns a whitespace separated list of all the actions allowed 
   for the current user on the page targeted by the command.
   ======================================================================
:) 
declare function oppidum:get-rights-for( $cmd as element(), $defaults as element()* ) as xs:string
{ 
  if (not($cmd/resource/@supported) and not($cmd/resource/@method)) then
    '' (: pure resource w/o actions :)
  else
    let 
      $actions := tokenize(string-join($cmd/resource/(@supported | @method), ' '), ' '),
      $rules := if ($cmd/resource/access) then $cmd/resource/access else $defaults
    return string-join(
      for $a in $actions
      let $rule := $rules/rule[$a = tokenize(@action, ' ')]
      return if (not($rule) or (oppidum:test-role-for-command($rule/@role, $cmd))) then $a else (), ' ')
};
                       
(: ======================================================================
   Tests an access rule against the current user and the command.
   Returns true if the user is granted access and false otherwise.   
   ======================================================================
:) 
declare function oppidum:test-role-for-command( $role as xs:string,  $cmd as element() ) as xs:boolean
{ 
  let $roles := tokenize($role, ' ')
  return oppidum:my-test-role-iter(1, $roles, $cmd)  
};                                                                            

declare function oppidum:my-test-role-iter( $index as xs:integer, $roles as xs:string*, $cmd as element() ) as xs:boolean
{ 
  if ($index > count($roles)) then 
    false()
  else
    let 
      $role := $roles[$index],
      $res :=                      
        if ($role = 'all') then 
          true()
        else if (starts-with($role, 'u:')) then
          oppidum:check-user(substring-after($role, 'u:'))
        else if (starts-with($role, 'g:')) then
          oppidum:check-group(substring-after($role, 'g:'))
        else if ('owner' = $role) then
          oppidum:check-owner($cmd)
        else
          false()  
    return
     if ($res) then $res else oppidum:my-test-role-iter($index + 1, $roles, $cmd)
};                    

declare function oppidum:check-user( $name as xs:string ) as xs:boolean
{
  let $user := xdb:get-current-user()
  return $user = $name  
};

declare function oppidum:check-group( $name as xs:string ) as xs:boolean
{
  let $user := xdb:get-current-user()
  return $name = xdb:get-user-groups($user)
};

(: ======================================================================
   Return true if the user is the owner of the reference object in $cmd 
   and false otherwise
   ======================================================================
:) 
declare function oppidum:check-owner( $cmd as element() ) as xs:boolean
{       
  (: TO BE DONE :)
  let $user := xdb:get-current-user()
  return true()
};

