(: ------------------------------------------------------------------
   Oppidum framework skin

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Mapping explorer model generation

   August 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare function local:gen-name( $cur as element(), $show-variant as xs:boolean ) {
  if ($show-variant and exists($cur/variant)) then
    concat(
      if ($cur/@name) then $cur/@name else '*',
      '.[',
      string-join($cur/variant/string(@format), ','),
      ']'
      )
  else if ($cur/@name) then
    string($cur/@name)
  else
    '*'
};

declare function local:gen-row( $cur as element(), $path as xs:string, $module as xs:string ) as element()* {
  if (local-name($cur) eq 'import') then
    let $mod := fn:doc(concat('/db/www/', $module, '/config/modules.xml'))//module[@id eq $cur/@module]
    let $name := local:gen-name($cur/parent::*, false())
    return
      local:iter-depth-fist(($mod/action[@name ne 'POST'], $mod/item, $mod/collection), concat($path, '/', $name), $module)
  else
    <Row type="{ local-name($cur) }">
      {
      let $name := local:gen-name($cur, true())
      return (
        attribute { 'name'} { $name },
        attribute { 'extpath' } { concat($path, '/', $name) },
        attribute { 'path' } { concat($path, '/', local:gen-name($cur, false())) },
        if (exists($cur/model) or exists($cur/view) or starts-with($cur/@resource, 'file:/') or starts-with($cur/variant/@resource, 'file:/')) then
          attribute { 'GET' } { '1' }
        else
          (),
        if ($cur/action[@name eq 'POST']) then
          attribute { 'POST' } { '1' }
        else
          (),
        if ($cur/model/@src) then
          attribute 
          { 
            if (local-name($cur) eq 'action') then 
              'Amodel' 
            else
              'Gmodel' 
          } 
          { 
            string($cur/model/@src) 
          }
        else
          (),
        if ($cur/action[@name eq 'POST']/model/@src) then
          attribute { 'Pmodel' } { string($cur/action[@name eq 'POST']/model/@src) }
        else
          ()
        )
      }
    </Row>
};

(: ======================================================================
   FIXME: why $cur/import does not work when directly added to the first iter-depth-first ?
   ====================================================================== 
:)
declare function local:iter-depth-fist( $items as element()*, $path as xs:string, $module as xs:string ) as element()* {
  for $cur in $items
  let $row := local:gen-row($cur, $path, $module)
  return (
    $row,
    local:iter-depth-fist(($cur/action[@name ne 'POST'], $cur/item, $cur/collection), $row/@path, $module),
    if ($cur/import) then local:gen-row($cur/import, $path, $module) else ()
    )
};


let $module := request:get-parameter('m', 'oppidum')
let $config := fn:doc(concat('/db/www/', $module, '/config/mapping.xml'))/site
let $start := ($config/action[@name ne 'POST'], $config/item, $config/collection)
return
  <Mapping module="{$module}">
   { local:iter-depth-fist($start, '', $module) }
  </Mapping>
