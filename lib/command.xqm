xquery version "1.0";
(: -----------------------------------------------
   Oppidum framework command generator

   Oppidum HTTP request parser that generates the <command>
   from the mapping. Detects two types of early errors:
   - not-found when the URL has no mapping entry
   - not-supported when the URL refers to an action not supported
     by the target mapping entry

   Author: Stéphane Sire <s.sire@free.fr>

   TODO :
   - merge param fields when rewriting importing modules
     (currently only keep top level param)
   - implement a @method attribute on <action> as currently
     an action may implement any HTTP verb
   - DEPRECATE default action in favour of module importation ?

   August 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace command = "http://oppidoc.com/oppidum/command";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace text="http://exist-db.org/xquery/text";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "util.xqm";

(: ======================================================================
   Recreates the local part of the URI as string, removing the last token if it
   has been recognized as an action
   ======================================================================
:)
declare function command:gen-trail(
  $is-action as xs:boolean,
  $tokens as xs:string*,
  $count as xs:integer ) as attribute()
{
  attribute { 'trail' } {
    if ($is-action) then
      string-join($tokens[position() < $count], '/')
    else
      string-join($tokens, '/')
  }
};

(: ======================================================================
   pre-condition: $from and $to same size
   ======================================================================
:)
declare function command:star-distance-iter(
  $index as xs:decimal,
  $from as xs:string*,
  $to as xs:string*,
  $sum as xs:decimal ) as xs:decimal
{
  if ($index > count($from)) then
    $sum
  else
    if ($from[$index] = '*') then
      command:star-distance-iter($index + 1, $from, $to, $sum)
    else if ($from[$index] = $to[$index]) then
      command:star-distance-iter($index + 1, $from, $to, $sum + 1)
    else
      command:star-distance-iter($index + 1, $from, $to, $sum - 1000)
      (: -1000 to get a negative result in all cases :)
};

declare function command:get-default-action( $cmd as element(), $actions as element() ) as element()*
{
  let $tokens := tokenize($cmd/@trail, '/')[. != '']
  return
    (
    for $c in $actions/action[(@name = $cmd/@action) and (@depth = count($tokens))]
    let
      $slash := ends-with($c/@trail, '/'),
      $compatible := not($slash) or (name($cmd/*[1]) = 'collection'),
      $bonus := if ($slash and $compatible) then 1 else 0,
      $d := command:star-distance-iter(1, tokenize($c/@trail, '/')[. != ''], $tokens, 0) + $bonus
    where ($d >= 0) and $compatible
    order by $d
    return
      $c
    )[last()]
};

declare function command:expand-paths( $exp as xs:string, $tokens as xs:string*, $lang as xs:string ) as xs:string
{
  let $expanded := replace($exp, "\$(\d)", "|var=$1|")
  return
    let $subst :=  
        string-join(
          for $t in tokenize($expanded, "\|")
          let $index := substring-after($t, 'var=')
          return
            if ($index) then $tokens[xs:decimal($index)] else $t,
          '')
   return
      replace($subst, "\$lang", $lang)
};

(: ======================================================================
   Rewrites the $source module to correctly set :
   - $__collection, $_resource, $__template, $__epilogue variables
   - $nb variables
   - <param> elements
   with their value inherited from the current context.
   ======================================================================
:)
declare function local:rewrite-module(
  $source as element(),
  $vars as xs:string*,
  $delta as xs:integer,
  $param as xs:string?
  ) as element()
{
  element { local-name($source) }
  {
    for $attr in $source/@*
    return
      if (starts-with($attr, '$__')) then
        (: limited named variables substitution :)
        if (starts-with($attr, '$__resource')) then
          attribute { name($attr) } { concat($vars[1], substring-after($attr, '$__resource')) }
        else if (starts-with($attr, '$__collection')) then
          attribute { name($attr) } { concat($vars[2], substring-after($attr, '$__collection')) }
        else if (starts-with($attr, '$__template')) then
          attribute { name($attr) } { concat($vars[3], substring-after($attr, '$__template')) }
        else if (starts-with($attr, '$__epilogue')) then
          attribute { name($attr) } { concat($vars[4], substring-after($attr, '$__epilogue')) }
        else
          ()
      else if (matches($attr,'\$\d')) then
        (: path steps variables increment (e.g. '$2/images' becomes '$4/images', '$1.xml' becomes '$3.xml') :)
        attribute  { name($attr) } {
          string-join(
            for $t in tokenize($attr, '/')
            return
              if (starts-with($t, '$')) then
                if (contains($t, '.')) then
                  concat('$', number(substring-after(substring-before($t, '.'), '$')) + $delta, '.', substring-after($t, '.'))
                else
                  concat('$', number(substring-after($t, '$')) + $delta)
              else $t
              , '/'
          )
        }
      else if (local-name($attr) = 'param') then
        if ($param) then (: propagates param from the current import statement :)
          attribute { 'param' } { $param } (: FIXME: merge $param with $attr instead :)
        else
          $attr
      else
        $attr,
    if ((local-name($source) = 'import') and not($source/@param) and $param) then
      attribute { 'param' } { $param } (: generates it in case it was not defined :)
    else
      (),
    for $child in $source/*
    return
      if (local-name($child) eq 'param') then (: parameters value substitution :)
        let $key := concat($child/@name,'=')
        return
          if (contains($param, $key)) then
            let $preval := substring-after($param, $key)
            let $value := if (contains($preval, ';')) then substring-before($preval, ';') else $preval
            return
              element { local-name($child) } {
                $child/@name,
                attribute { 'value' } { normalize-space($value) }
              }
          else
            $child
      else
        local:rewrite-module($child, $vars, $delta, $param)
  }
};

(: ======================================================================
   Searches for an <action> in $mapping imported modules matching $name
   Returns it or the empty sequence.
   ======================================================================
:)
declare function command:import-action(
  $index as xs:integer,
  $name as xs:string,
  $mapping as element(),
  $inres as xs:string?,
  $incol as xs:string?,
  $confbase as xs:string
  ) as element()?
{
  let $imports := $mapping/import
  let $match := if ($imports) then local:import-action-iter($name, $confbase, $imports) else ()
  return
    if ($match) then
      let $vars := (
                    if ($mapping/@resource) then $mapping/@resource else if ($inres) then $inres else '-1',
                    if ($mapping/@collection) then $mapping/@collection else if ($incol) then $incol else '-1',
                    if ($mapping/@template) then $mapping/@template else '-1',
                    if ($mapping/@epilogue) then $mapping/@epilogue else '-1'
                   )
      return local:rewrite-module($match[1], $vars, $index - 1, $match[2]) else ()
};

declare function local:import-action-iter( $name as xs:string, $confbase as xs:string, $imports as element()* ) as item()*
{
  let $cur := $imports[1]
  let $mods := doc(concat($confbase,'/config/modules.xml'))/modules
  let $m := $mods/module[(@id = $cur/@module)]
  (: search in the imported module or in an imported module inside it - NO MORE :)
  let $found :=
    if ($m/action[@name = $name]) then
      ($m/action[@name = $name])
    else
      $mods/module[(@id = $m/import/@module)]/action[@name = $name]
  return
    if ($found) then
      ($found, $cur/@param/string())
    else
      let $next := subsequence($imports,2)
      return
        if ($next) then local:import-action-iter($name, $confbase, $next) else ()
};

(: ======================================================================
   Generates @error(not-supported) if $method HTTP verb is not supported
   by $page item or collection (note that GET is always supported),
   otherwise returns an @action, @type and <resource> element
   generated from the mapping $page.
   Takes into account the implicit GET action of $page if present;
   search missing actions inside any $page <import>.
   It may return an empty <resource> element if no action definition
   is found, which should be interpreted as NO-PIPELINE-ERROR later.
   ======================================================================
:)
declare function command:gen-resource(
  $method as xs:string,
  $action-token as xs:string?,
  $index as xs:integer,
  $tokens as xs:string*,
  $page as element(),
  $db as xs:string?,
  $resource as xs:string?,
  $collection as xs:string?,
  $confbase as xs:string,
  $lang as xs:string
) as node()*
{
  (: check HTTP verb is supported by target item or collection :)
  if (($method = 'GET') or $action-token or ($method = tokenize($page/@method, ' '))) then
    (: build action specification taking implicit GET action into account :)
    let $action-spec :=
      if ($action-token) then
        if ($page/action[@name=$action-token]) then
          $page/action[@name=$action-token]
        else
          command:import-action($index, $action-token, $page, $resource, $collection, $confbase)
      else
        (: request is an HTTP verb on item or collection :)
        if (($method = 'GET') and (count($page/(model |view))>0)) then (: implicit 'GET' action :)
          $page/(model | view)
        else
          if ($page/action[@name=$method]) then
            $page/action[@name=$method]
          else
            command:import-action($index, $method, $page, $resource, $collection, $confbase)
    return
      (
        attribute { 'action' } { if ($action-token) then $action-token else $method },
        attribute { 'type' } { name($page) }, (: item or collection :)
        element { 'resource' } {
          let $name :=  if ($action-token) then $tokens[$index - 1] else $tokens[$index]
          return (: resource name :)
            if ($name) then attribute { 'name' } {  $name } else (),
          (: inherited attributes @db, @resource, @collection :)
          if ($db) then attribute { 'db' } { command:expand-paths($db, $tokens, $lang) } else (),
          if ($resource) then attribute { 'resource' } { command:expand-paths($resource, $tokens, $lang) } else (),
          if ($collection) then attribute { 'collection' } { command:expand-paths($collection, $tokens, $lang) } else (),
          (: optional attributes from target item or collection :)
          $page/(@access | @template | @check | @epilogue | @supported | @method | @redirect),
          $page/(access|variant),
          $action-spec
          (: debug :)
(:          $page/access,
          $page/variant,
          <tokens>{$tokens}</tokens>,
          <index>{$index}</index>,
          <action-token>{$action-token}</action-token>,
          <actiontoken>{($method = 'GET') and (count($page/(model |view))>0)}</actiontoken>,
          $page
:)        }
      )
  else
    attribute { 'error' } { 'not-supported' }
};

(: ======================================================================
   Searches for an <item> or <collection> in $mapping matching $name.
   Does consecutive trials:
   - direct children exact match
   - imported modules with exact match, anonymous item or star collection
   - direct children anonymous item
   Does not trial direct children star collection
   ======================================================================
:)
declare function command:find-item-or-collection(
  $index as xs:integer,
  $name as xs:string,
  $mapping as element(),
  $inres as xs:string?,
  $incol as xs:string?,
  $confbase as xs:string
  ) as element()?
{
  if ($mapping/(item|collection)[@name = $name]) then (: exact match :)
    $mapping/(item|collection)[@name = $name]
  else
    let $imports := $mapping/import
    let $match := if ($imports) then local:import-iter($name, $confbase, $imports) else ()
    return
      if ($match) then
        let $vars := (
                     if ($mapping/@resource) then $mapping/@resource else if ($inres) then $inres else '-1',
                     if ($mapping/@collection) then $mapping/@collection else if ($incol) then $incol else '-1',
                     if ($mapping/@template) then $mapping/@template else '-1',
                     if ($mapping/@epilogue) then $mapping/@epilogue else '-1'
                     )
        return
          local:rewrite-module($match[1], $vars, $index - 1, $match[2])
      else
        let $match := $mapping/item[not(@name)] (: anonymous item :)
        return
          if ($match) then $match[1] else ()
};

(: ======================================================================
   Searches for an <item> or <collection> in $mapping imported modules
   matching $name. Returns it or the empty sequence.
   ======================================================================
:)
declare function local:import-iter ( $name as xs:string, $confbase as xs:string, $imports as element()* ) as item()*
{
  (:  let $log := oppidum:debug(('import-iter for ',  $name, ' inside ', concat($confbase,'/config/modules.xml'),' and #imports=', for $i in $imports return $i/@module/string())):)
  let $cur := $imports[1]
  let $mods := doc(concat($confbase,'/config/modules.xml'))/modules
  let $m := $mods/module[(@id = $cur/@module)]
  (:  let $log := oppidum:debug(('*** found module ', util:serialize($m, ()))) :)
  (: search in the imported module or in an imported module inside it - NO MORE :)
  let $found :=
    if ($m/(item|collection)[@name = $name]) then (: exact match :)
      $m/(item|collection)[@name = $name][1]
    else if ($mods/module[(@id = $m/import/@module)]/(item|collection)[@name = $name]) then (: exact match :)
      $mods/module[(@id = $m/import/@module)]/(item|collection)[@name = $name][1]
    else if ($m/item[not(@name)]) then (: anonymous item :)
      $m/(item[not(@name)])[1]
    else if ($m/collection[@name = '*']) then (: star collection :)
      $m/(collection[@name = '*'])[1]
    else (: FIXME : does not look for 2nd level anonymous item or star collection :)
      ()
  return
    if ($found) then
      ($found, $cur/@param/string())
    else
      let $next := subsequence($imports,2)
      return
        if ($next) then local:import-iter($name, $confbase, $next) else ()
};

(: ======================================================================
   Star collection (<collection name="*">) parser
   ======================================================================
:)
declare function command:match-token-iter(
  $method as xs:string,
  $index as xs:integer,
  $tokens as xs:string*,
  $mapping as element(),
  $indb as xs:string?,
  $inres as xs:string?,
  $incol as xs:string?,
  $confbase as xs:string,
  $greedy as xs:boolean,
  $lang as xs:string
) as node()*
{
  let $curtoken := $tokens[$index]
  let $count := count($tokens)
  let $last := $index >= $count
  let $action := if ($last and ($curtoken = tokenize($mapping/@supported, ' ')))
                  then $curtoken
                  else ''
  let $page :=  if ($action)
                  then $mapping
                  else command:find-item-or-collection($index, $curtoken, $mapping, $inres, $incol, $confbase)
  (: "inherits"" attributes :)
  let $db := if ($page/@db) then $page/@db else $indb
  let $resource := if ($page/@resource) then $page/@resource else $inres
  let $collection : = if ($page/@collection) then $page/@collection else $incol
  (:  $log := oppidum:debug(('match-token-iter with $cur', $tokens[$index], ' and $greedy=', if ($greedy) then 'true' else 'false', ' name=', string($mapping/@name), ' page=', string($page/@name))):)
  return
    if (not($last)) then
      if ($greedy) then
        if ($page[@name]) then (: switch to non greedy iteration on the new branch :)
          command:match-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $confbase, false(), $lang)
        else
          let $nextok := $tokens[$index+1] (: look ahead 1 token :)
          return
            if ($page[not(@name)] and
                (($page/(item|collection)[@name = $nextok]) or ($nextok = tokenize($page/@supported, ' ')))) then
              command:match-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $confbase, false(), $lang)
            else (: continue with greedy iteration same branch :)
              command:match-token-iter($method, $index + 1, $tokens, $mapping, $db, $resource, $collection, $confbase, $greedy, $lang)
      else
        if ($page[not(@name)]) then (: switch to greedy iteration on the new branch :)
          command:match-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $confbase, true(), $lang)
        else
          if ($page[@name]) then (: continue with greedy iteration on the new branch :)
            command:match-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $confbase, false(), $lang)
          else  (: no page and not greedy : failure :)
            ()
    else
      if (not($page) and not($greedy)) then (: failure : backtracking :)
        ()
      else (: success : $page or $greedy :)
        (
        command:gen-trail(boolean($action), $tokens, $count),
        if (not($page)) then
          command:gen-resource($method, $action, $index, $tokens, $mapping, $db, $resource, $collection, $confbase, $lang)
        else
          command:gen-resource($method, $action, $index, $tokens, $page, $db, $resource, $collection, $confbase, $lang)
        )
};

declare function command:parse-token-iter(
  $method as xs:string,
  $index as xs:integer,
  $tokens as xs:string*,
  $mapping as element(),
  $indb as xs:string?,
  $inres as xs:string?,
  $incol as xs:string?,
  $confbase as xs:string,
  $lang as xs:string
) as node()*
{
  let $curtoken := $tokens[$index]
  let $count := count($tokens)
  let $last := $index = $count
  let $action := if ($last and ($curtoken = tokenize($mapping/@supported, ' '))) then $curtoken else ()
  let $page := if ($action) then
                 $mapping
               else
                 let $match := command:find-item-or-collection($index, $curtoken, $mapping, $inres, $incol, $confbase)
                 return
                   if ($match) then $match[1] else  $mapping/(item|collection)[@name = '*'][1] (: star collection :)
  (: compute inherited attributes :)
  let $db := if ($page/@db) then $page/@db else $indb
  let $resource := if ($page/@resource) then $page/@resource else $inres
  let $collection : = if ($page/@collection) then $page/@collection else $incol
  return
    if ($page[@name = '*']) then
      (: recurse in greedy mode starting at self :)
      let $res := command:match-token-iter($method, $index, $tokens, $page, $db, $resource, $collection, $confbase, true(), $lang)
      return
        if ($res) then $res else attribute { 'error' } { 'not-found' }
    else if (not($last) and $page) then
      (: recurse :)
      command:parse-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $confbase, $lang)
    else (: assumes $last is true :)
      (
      command:gen-trail(boolean($action), $tokens, $count),
      if (not($page)) then
        attribute { 'error' } { 'not-found' }
      else
        command:gen-resource($method, $action, $index, $tokens, $page, $db, $resource, $collection, $confbase, $lang)
      )
};

(: ========================================================================
   Main entry point of the request parser.
   Pre-condition: space in $url has been normalized and minimal url is '/'
   ========================================================================
:)
declare function command:parse-url(
  $base-url as xs:string,
  $exist-root as xs:string,
  $exist-path as xs:string,
  $url as xs:string,
  $method as xs:string,
  $mapping as element(),
  $lang as xs:string,
  $def-lang as xs:string? ) as element()
{
  let $extension := if (contains($url, '.')) then substring-after($url, '.') else ''
  let $raw-payload := if ($extension != '') then substring-before($url, '.') else $url
  let $payload := if ($raw-payload = '/') then $mapping/@startref else $raw-payload (: although we SHOULD have redirected before reaching that line :)
  let $tokens := tokenize($payload, '/')[. != '']
  let $format := if ($extension) then $extension else request:get-parameter('format', '')
  return
    <command>
      {
      attribute base-url {
        if ($mapping/@languages) then (: build a multilingual base URL including language code if not default :)
          if ($def-lang and ($lang = $def-lang)) then
            $base-url
          else 
            concat($base-url, $lang, '/')
        else
          $base-url
      },
      attribute app-root { $exist-root },
      attribute exist-path { $exist-path },
      attribute lang { $lang },
      attribute db { $mapping/@db },
      if ($def-lang) then attribute def-lang { $def-lang } else (),
      $mapping/@confbase,
      $mapping/@mode,
      if ($mapping/error/@mesh) then attribute error-mesh { $mapping/error/@mesh } else (),
      if ($format) then attribute format { $format } else (),
      command:parse-token-iter($method, 1, $tokens, $mapping,
        $mapping/@db, $mapping/@resource, $mapping/@collection, $mapping/@confbase, $lang)
      }
    </command>
};
