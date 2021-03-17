(: ------------------------------------------------------------------
   Oppidum framework skin

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Mapping explorer model generation

   August 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
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
   Checks GET defined at top level in imported module
   ====================================================================== 
:)
declare function local:import-method-model( $cur as element(), $module as xs:string, $method as xs:string ) {
  if ($cur/import) then 
    let $mod := fn:doc(concat('/db/www/', $module, '/config/modules.xml'))//module[@id eq $cur/import/@module]
    return 
      attribute { 
        if ($method eq 'GET') then 
          'Gmodel'
        else
          'Pmodel'
      }
      {
        string($mod/action[@name eq $method]/model/@src)
      }
  else
    ()
};

declare function local:gen-row( $cur as element(), $path as xs:string, $module as xs:string ) as element()* {
  if (local-name($cur) eq 'import') then
    let $mod := fn:doc(concat('/db/www/', $module, '/config/modules.xml'))//module[@id eq $cur/@module]
    let $name := local:gen-name($cur/parent::*, false())
    return
      local:iter-depth-fist(($mod/action[(@name ne 'GET') and (@name ne 'POST')], $mod/item, $mod/collection), concat($path, '/', $name), $module)
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
          attribute { 'GET' } { '1' }
        else
          (),
        if ($cur/action[@name eq 'POST'] or local:import-has-method($cur, $module, 'POST')) then
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
          local:import-method-model($cur, $module, 'GET'),
        if ($cur/action[@name eq 'POST']/model/@src) then
          attribute { 'Pmodel' } { string($cur/action[@name eq 'POST']/model/@src) }
        else
          local:import-method-model($cur, $module, 'POST')
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

(:

<rest:resource-function xquery-uri="/db/apps/tennis/api.xql">
    <rest:identity namespace="http://unifr.ch/ssd/w13" local-name="tournaments" arity="1"/>
    <rest:annotations>
        <rest:GET/>
        <rest:produces>
            <rest:internet-media-type>application/xml</rest:internet-media-type>
        </rest:produces>
        <rest:path specificity-metric="14">
            <rest:segment>api</rest:segment>
            <rest:segment>tournaments</rest:segment>
            <rest:segment>{$Id}</rest:segment>
        </rest:path>
        <output:media-type xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">application/xml</output:media-type>
        <output:method xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">xml</output:method>
    </rest:annotations>
</rest:resource-function>

:)
let $restroutes := try{
    for $rr in rest:resource-functions()/rest:resource-function
    let $type := "rest"
    let $name := data($rr//@local-name)
    let $extpath := "//exist/restxq/" || string-join($rr//rest:segment,"/")
    let $path := $extpath
    let $sortkey := "/" || $name
    let $get := 0
    let $post := 0
    let $model := data($rr/@xquery-uri)
    let $pmodel := data($rr/@xquery-uri)
    let $amodel := $rr//rest:internet-media-type
    return
        <Row type="{$type}" name="{$name}" extpath="{$extpath}" path="{$path}" sortkey="{$sortkey}" Amodel="{$amodel}">
        {
        if (exists($rr//rest:GET)) then
            (
            attribute { 'GET'} { 1 },
            attribute { 'Gmodel'} { $model }
            )
        else (),
        if (exists($rr//rest:POST)) then
            (
            attribute { 'POST'} { 1 },
            attribute { 'Pmodel'} { $model }
            )
        else ()
        }
        </Row>
} catch *{
    ()
}
return
  <Mapping module="{$module}">
    <Modules>
      {
      for $c in xdb:get-child-collections('/db/www')
      return <Module>{ $c }</Module>
      }
      <Module>RestXQ</Module>
    </Modules>
    { 
    let $rows := local:iter-depth-fist($start, '', $module) (: pre-order for XSLT toc construction :)
    return
    for $r in $rows
    order by $r/@sortkey
    return $r
    }
    {
    $restroutes
    }
    {
    rest:resource-functions()
    }
  </Mapping>
