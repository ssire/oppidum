xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum framework sample epilogue

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   February 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.  
   ------------------------------------------------------------------ :)

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace site = "http://oppidoc.com/oppidum/site";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace session = "http://exist-db.org/xquery/session";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../oppidum/lib/util.xqm";
import module namespace epilogue = "http://oppidoc.com/oppidum/epilogue" at "../oppidum/lib/epilogue.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=yes";
(:     doctype-public=-//W3C//DTD&#160;XHTML&#160;1.1//EN
     doctype-system=http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"; :) 
     
(: ======================================================================
   Typeswitch function 
   -------------------
   Plug all the <site:{module}> functions here and define them below  
   ======================================================================
:)
declare function site:branch( $cmd as element(), $source as element(), $view as element()* ) as node()*
{
 typeswitch($source)
 case element(site:error) return site:error($cmd, $view)
 case element(site:message) return site:message($view)
 default return $view/*[local-name(.) = local-name($source)]/*  
 (: default treatment to implicitly manage other modules :)
};  

(: ======================================================================
   Generates error essages in <site:error>
   ======================================================================
:) 
declare function site:error( $cmd as element(), $view as element() ) as node()*
{    
  let $resolved := oppidum:render-errors($cmd/@db, $cmd/@lang)
  return (
    for $m in $resolved/*[1] (: cannot user $resolved/message because of default ns :)
    return <p>{$m/text()}</p>
    )    
};                 

(: ======================================================================
   Generates information messages in <site:message>
   Be careful to call session:invalidate() to clear the flash after logout
   redirection !
   TODO: store messages in a database 
   ======================================================================
:) 
declare function site:message( $view as element() ) as node()*
{                          
  <p>To be done</p>
};   
 
(: ======================================================================
   Recursive rendering function 
   ----------------------------
   Copy this function as is inside your epilogue to render a mesh
   ======================================================================
:)
declare function local:render( $cmd as element(), $source as element(), $view as element()* ) as element()
{    
  element { node-name($source) }
  {
    $source/@*,
    for $child in $source/node()
    return           
      if ($child instance of text()) then
        $child
      else
        (: FIXME: hard-coded 'site:' prefix we should better use namespace-uri :)
        if (starts-with(xs:string(node-name($child)), 'site:')) then
          (                      
            if (($child/@force) or 
                ($view/*[local-name(.) = local-name($child)])) then
                 site:branch($cmd, $child, $view)
            else
              ()
          )
        else if ($child/*) then
          if ($child/@condition) then
          let $go :=  
            if (string($child/@condition) = 'has-error') then
              oppidum:has-error()
            else if (string($child/@condition) = 'has-message') then
              oppidum:has-message()
            else if ($view/*[local-name(.) = substring-after($child/@condition, ':')]) then 
                true()
            else 
              false()
          return
            if ($go) then        
              local:render($cmd, $child, $view)
            else 
              () 
        else 
           local:render($cmd, $child, $view)            
        else
         $child
  }
};

(: ======================================================================
   Epilogue entry point
   --------------------
   Copy this code as is inside your epilogue
   ======================================================================
:)
let $mesh := epilogue:finalize()
return
  if ($mesh) then
    local:render(request:get-attribute('oppidum.command'), $mesh, request:get-data())
  else 
    ()
