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
import module namespace skin = "http://oppidoc.com/oppidum/skin" at "../oppidum/lib/skin.xqm";
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
 case element(site:skin) return site:skin($cmd, $view)
 case element(site:navigation) return site:navigation($cmd, $view)
 case element(site:error) return site:error($cmd, $view)
 case element(site:message) return site:message($cmd)
 default return $view/*[local-name(.) = local-name($source)]/*
 (: default treatment to implicitly manage other modules :)
};

(: ======================================================================
   Inserts CSS links and JS scripts to the page
   selection is defined by the current mesh, the optional skin attribute
   of the site:view element, and the site's 'skin.xml' resource
   ======================================================================
:)
declare function site:skin( $cmd as element(), $view as element() ) as node()*
{
  skin:gen-skin('oppidum', oppidum:get-epilogue($cmd), $view/@skin)
};

(: ======================================================================
   Generates <site:navigation> menu
   ======================================================================
:)
declare function site:navigation( $cmd as element(), $view as element() ) as element()*
{
  let $base := string($cmd/@base-url)
  return
    <ul class="nav">
      <li><a href="{$base}devtools">Home</a></li>
      <li><hr/></li>
      <li><a href="{$base}test/generator">Mapping simulator</a></li>
      <li><a href="{$base}test/explorer">Mapping explorer</a></li>
      <li><a href="{$base}test/skin">Skin simulator</a></li>
      <li><a href="{$base}test/inspect">Request dump</a></li>
      <li><hr/></li>
      <li><a href="{$base}test/errors">Errors</a></li>
      <li><a href="{$base}test/messages">Messages</a></li>
      <li><a href="{$base}localization/messages">Localization</a></li>
      <li><a href="{$base}localization/dictionary">Dictionary</a></li>
      <li><hr/></li>
      <li><a href="{$base}docs/toc">Docs</a></li>
      <li><a href="{$base}home">Version</a></li>
      <li><a href="{$base}install">Installer</a></li>
    </ul>
};

(: ======================================================================
   Generates error messages in <site:error>
   ======================================================================
:)
declare function site:error( $cmd as element(), $view as element() ) as node()*
{
  let $confbase := request:get-attribute('devtools.confbase')
  let $resolved := oppidum:render-errors(if ($confbase) then $confbase else $cmd/@confbase, $cmd/@lang)
  return (
    for $m in $resolved/*[1] (: cannot user $resolved/message because of default ns :)
    return <p>{$m/text()}</p>
    )
};

(: ======================================================================
   Generates information messages in <site:message>
   Be careful to call session:invalidate() to clear the flash after logout redirection !
   ======================================================================
:)
declare function site:message( $cmd as element() ) as node()*
{
  let $confbase := request:get-attribute('devtools.confbase')
  let $messages := oppidum:render-messages(if ($confbase) then $confbase else $cmd/@confbase, $cmd/@lang)
  return
    for $m in $messages
    return (
      (: trick because messages are stored inside session :)
      if ($m/@type = "ACTION-LOGOUT-SUCCESS") then session:invalidate() else (),
      <p>
        {(
        for $a in $m/@*[local-name(.) ne 'type']
        return attribute { concat('data-', local-name($a)) } { string($a) },
        $m/text() 
        )}
      </p>
      )
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
let $data := oppidum:get-data()
let $view := if ($data instance of document-node()) then (: since exist 2.0 :) $data/*[1] else (: exist 1.4.x:) $data
return
  if ($mesh) then
    local:render(request:get-attribute('oppidum.command'), $mesh, $view)
  else
    ()
