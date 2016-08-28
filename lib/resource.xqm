xquery version "1.0";
(: -----------------------------------------------
   Oppidum framework utilities

   REST extension for reference document and reference collection

   See also: models/resource.xql

   TODO: add generic sharding functions

	 Author: Stéphane Sire <s.sire@oppidoc.fr>

   August 2016 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

module namespace resource = "http://oppidoc.com/oppidum/resource";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace response="http://exist-db.org/xquery/response";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

(: ======================================================================
   Substitutes @@vars@@ inside a single string of text
   ======================================================================
:)
declare function local:replace-variables( $text as xs:string, $vars as element()? ) as xs:string {
  if (not(contains($text, "@@"))) then
    $text
  else
    string-join(
      for $t at $i in tokenize($text, '@@')
      return
        if ($i mod 2 eq 0) then
          $vars/var[@name eq $t]/text()
        else
          $t,
      ''
      )
};

declare function local:gen-variables-for(
  $cmd as element(), 
  $template as xs:string,
  $defs as element()* ) as element() 
{
  <vars>
    {
    let $keys := tokenize(string($template), '@@')[position() mod 2 = 0]
    return
      for $k in $keys
      return
        if ($defs/Variable[Name eq $k]) then
          let $d := $defs/Variable[Name eq $k]
          return 
            let $res := util:eval($d/Expression/text())
            return
              if ($res instance of element()+) then
                $res
              else
                <var name="{ $k }">{ string($res) }</var>
        else
          <var name="{ $k }">MISSING ({ $k })</var>
      }
  </vars>
};

declare function resource:path-to-ref ( $cmd as element() ) as xs:string
{
  let $r := $cmd/resource
  let $path := string-join(($r/@db, $r/@collection, $r/@resource), '/')
  return
    if (contains($path, '@@')) then (: with variables :)
      let $defs := fn:doc(concat($cmd/@confbase, '/config/resources.xml'))/Variables
      return 
        local:replace-variables(
          $path,
          local:gen-variables-for($cmd, $path, $defs)
          )
    else
      $path
};

declare function resource:path-to-ref-col ( $cmd as element() ) as xs:string
{
  let $r := $cmd/resource
  return
    string-join(($r/@db, $r/@collection), '/')
};

declare function resource:get-document ( $cmd as element() ) as element()? {
  let $path := resource:path-to-ref()
  return
    if (not(contains($path, 'MISSING (')) and fn:doc-available($path)) then
      fn:doc($path)
    else
      oppidum:throw-error("DB-NOT-FOUND", $path)
};
