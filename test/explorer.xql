xquery version "3.0";
(:~ 
 : Oppidum framework IDE
 :
 : Mapping explorer. Routes generation for table display.
 :
 : @author Stéphane Sire <s.sire@free.fr>
 :
 : August 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
 :
 :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=xml media-type=application/xml";

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

(: ======================================================================
   Checks GET defined at top level in imported module
   ====================================================================== 
:)
declare function local:import-has-method( $cur as element(), $module as xs:string, $method as xs:string ) {
  if ($cur/import) then 
    let $mod := fn:doc(concat('/db/www/', $module, '/config/modules.xml'))//module[@id eq $cur/import/@module]
    return 
      exists($mod/action[@name eq  $method])
  else
    false()
};

(: ======================================================================
   Checks GET model defined at top level in imported module
   ====================================================================== 
:)
declare function local:import-method-model( $cur as element(), $module as xs:string, $method as xs:string ) {
  if ($cur/import) then 
    let $mod := fn:doc(concat('/db/www/', $module, '/config/modules.xml'))//module[@id eq $cur/import/@module]
    return 
      attribute { 'model'} { string($mod/action[@name eq $method]/model/@src) }
  else
    ()
};

(: ======================================================================
   Checks GET view defined at top level in imported module
   ====================================================================== 
:)
declare function local:import-method-view( $cur as element(), $module as xs:string, $method as xs:string ) {
  if ($cur/import) then 
    let $mod := fn:doc(concat('/db/www/', $module, '/config/modules.xml'))//module[@id eq $cur/import/@module]
    return 
      attribute { 'view'} { string($mod/action[@name eq $method]/view/@src) }
  else
    ()
};

declare function local:gen-get( $cur as element(), $module as xs:string ) as element()? {
  <method>
    {
    if (local-name($cur) eq 'action') then
      attribute { 'name' } { '*' }
    else
      attribute { 'name' } { 'GET' },
    if ($cur/model/@src) then
      attribute { 'model' } { string($cur/model/@src) }
    else if ($cur/@resource) then
      attribute { 'model' }{ string($cur/@resource) }
    else
      local:import-method-model($cur, $module, 'GET'),
    if ($cur/view/@src) then
      attribute { 'view' } { string($cur/view/@src) }
    else
      local:import-method-view($cur, $module, 'GET'),
    if ($cur/@epilogue)
      then attribute { 'mesh' } { string($cur/@epilogue) }
      else ()
    }
  </method>
};

declare function local:gen-other-http-verbs( $cur as element(), $module as xs:string ) as element()* {
  for $m in tokenize($cur/@method, ' ')
  return
    <method name="{ upper-case($m) }">
      {
      if ($cur/action[@name eq $m]/model/@src) then
        attribute { 'model' } { string($cur/action[@name eq $m]/model/@src) }
      else 
        local:import-method-model($cur, $module, $m)
        (: @resource not supported on action ? :),
      if ($cur/action[@name eq $m]/view/@src) then
        attribute { 'view' } { string($cur/action[@name eq $m]/view/@src) }
      else
        local:import-method-view($cur, $module, $m),
      if ($cur/@epilogue)
        then attribute { 'mesh' } { string($cur/@epilogue) }
        else ()
      }
    </method>
};

declare function local:gen-row( $cur as element(), $path as xs:string, $module as xs:string ) as element()* {
  if (local-name($cur) eq 'import') then
    let $mod := fn:doc(concat('/db/www/', $module, '/config/modules.xml'))//module[@id eq $cur/@module]
    let $name := local:gen-name($cur/parent::*, false())
    let $verbs := tokenize($cur/@method, ' ')
    return
      local:iter-depth-fist(($mod/action[(@name ne 'GET') and not(@name = $verbs)], $mod/item, $mod/collection), concat($path, '/', $name), $module)
  else
    <Row type="{ local-name($cur) }">
      {
      let $name := local:gen-name($cur, true())
      let $new-path := concat($path, '/', local:gen-name($cur, false()))
      return (
        attribute { 'name'} { $name },
        attribute { 'extpath' } { concat($path, '/', $name) },
        attribute { 'path' } { $new-path },
        attribute { 'sortkey' } { replace($new-path, '\*', '***') },
        if (exists($cur/model) or exists($cur/view) or starts-with($cur/@resource, 'file:/') or starts-with($cur/variant/@resource, 'file:/') or local:import-has-method($cur, $module, 'GET')) then
          local:gen-get($cur, $module)
        else
          (),
        local:gen-other-http-verbs($cur, $module)
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
  let $verbs := tokenize($cur/@method, ' ')
  return (
    $row,
    local:iter-depth-fist(($cur/action[not(@name = $verbs)], $cur/item, $cur/collection), $row/@path, $module),
    if ($cur/import) then local:gen-row($cur/import, $path, $module) else ()
    )
};


let $module := request:get-parameter('m', 'oppidum')
let $config := fn:doc(concat('/db/www/', $module, '/config/mapping.xml'))/site
let $start := ($config/action[@name ne 'POST'], $config/item, $config/collection)
return
  <Mapping module="{$module}">
    <Modules>
      {
      for $c in xdb:get-child-collections('/db/www')
      return <Module>{ $c }</Module>
      }
    </Modules>
    { 
    let $rows := local:iter-depth-fist($start, '', $module) (: pre-order for XSLT toc construction :)
    return
      for $r in $rows
      let $index := substring($r/@path, 2, 1)
      group by $index
      order by lower-case($index)
      return
        <Range Letter="{$index}">
          { $r }
        </Range>
    }
  </Mapping>
