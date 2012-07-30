xquery version "1.0";      
(: -----------------------------------------------
   Oppidum framework command generator

   Parses the request URL and returns a command. Checks the command against
   the site's mapping to detect early errors (not-target, not-allowed).

   Author: Stéphane Sire <s.sire@free.fr>

   November 2011 - Copyright (c) Oppidoc S.A.R.L
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

declare function command:expand-paths( $exp as xs:string, $tokens as xs:string* ) as xs:string
{                                                                                
  let $expanded := replace($exp, "\$(\d)", "|var=$1|")
  return 
    string-join( 
      for $t in tokenize($expanded, "\|")
      let $index := substring-after($t, 'var=')
      return
        if ($index) then $tokens[xs:decimal($index)] else $t,
      '')
};

(: ======================================================================
   Rewrite the $source module to correctly set :
   - $__collection, $_resource, $__template, $__epilogue variables
   - $nb variables
   - <param> elements
   with their value inherited from the current context.
   ======================================================================
:)
declare function local:rewrite-module( $source, $vars, $delta, $param ) {
  element { node-name($source) }
  {
    for $attr in $source/@*
    return
      if (starts-with($attr, '$__')) then
        (: limited named variables substitution :)
        if (starts-with($attr, '$__collection')) then 
          attribute { name($attr) } { concat($vars[1], substring-after($attr, '$__collection')) }
        else if (starts-with($attr, '$__resource')) then 
          attribute { name($attr) } { concat($vars[2], substring-after($attr, '$__resource')) }
        else if (starts-with($attr, '$__template')) then 
          attribute { name($attr) } { concat($vars[3], substring-after($attr, '$__template')) }
        else if (starts-with($attr, '$__epilogue')) then 
          attribute { name($attr) } { concat($vars[4], substring-after($attr, '$__epilogue')) }
        else
          ()
      else if (matches($attr,'\$\d')) then
       let $log := oppidum:debug(('rewrite ',  name($attr), '=', string($attr), ' delta=', string($delta)))
       return
        (: path steps variables increment (e.g. '$2/images' becomes '$4/images') :)
        attribute  { name($attr) } { 
          string-join(
            for $t in tokenize($attr, '/') 
            return 
              if (starts-with($t, '$')) then 
                concat('$', number(substring-after($t, '$')) + $delta) 
              else $t
              , '/'
          )
        }
      else
        $attr,
    for $child in $source/node()
    return  
      if (local-name($child) eq 'param' ) then (: parameters value substitution :)
        let $key := concat($child/@name,'=')
        return
          if (contains($param, $key)) then
            let $preval := substring-after($param, $key)
            let $value := if (contains($preval, ';')) then substring-before($preval, ';') else $preval
            return
              element { node-name($child) } {
                $child/@name,
                attribute { 'value' } { normalize-space($value) }
              }
        else
          $child
      else 
        local:rewrite-module($child, $vars, $delta, $param)
  }
};

declare function local:dump-tree ( $source as node() ) 
as xs:string*
{
    concat(
      '<', local-name($source), ' ',
      for $attr in $source/@*
      return
        concat(name($attr), '=', string($attr), ' '), '>',
      for $child in $source/node()
      return  
        local:dump-tree($child),
      '</', local-name($source), '>')
};
  
(: ======================================================================
   Searches for an imported module that matches $curtoken
   Returns ($found, $import) where $found is the the module and $import
   is the corresponding import statement if a match was found, or the 
   empty sequence otherwise.
   ======================================================================
:)
declare function local:match-import-iter (
  $index as xs:integer,
  $curtoken as xs:string,
  $confbase as xs:string,
  $vars as xs:string*,
  $imports as element()*
) as element()* {
  if ($imports) then
    let $log := oppidum:debug(('match-import-iter for ',  $curtoken, ' inside ', concat($confbase,'/config/modules.xml'),' and #imports=', for $i in $imports return $i/@module))
    let $cur := $imports[1]
    let $mods := doc(concat($confbase,'/config/modules.xml'))/modules
    let $m := $mods/module[(@id = $cur/@module)]
(:    let $log := oppidum:debug(('*** found module ', local:dump-tree($m))):)
    let $found := 
      if ($m/(item|collection)[@name = $curtoken]) then 
        $m/(item|collection)[@name = $curtoken]
      else 
        if ($mods/module[(@id = $m/import/@module)]/(item|collection)[@name = $curtoken]) then 
          $mods/module[(@id = $m/import/@module)]/(item|collection)[@name = $curtoken]
        else 
          ()
    return
      if ($found) then 
        local:rewrite-module($found, $vars, $index, $cur/@param)
      else 
        local:match-import-iter($index, $curtoken, $confbase, $vars, subsequence($imports,2))
  else 
    let $log := oppidum:debug(('match-import-iter for ', $curtoken, ' and no imports'))
    return
      ()
};

declare function command:match-token-iter(
  $method as xs:string,
  $index as xs:integer,
  $tokens as xs:string*,
  $mapping as element(),
  $inherit-db as xs:string?,
  $inherit-resource as xs:string?,   
  $inherit-collection as xs:string?,
  $inherit-suffix as xs:string?,
  $inherit-access as xs:string?,
  $greedy as xs:boolean
) as node()*
{
  let
    $curtoken := $tokens[$index],
    $count := count($tokens),
    $last := $index = $count,
    $action-name := if ($last and ($curtoken = tokenize($mapping/@supported, ' '))) then $curtoken else '',
    $page := if ($action-name) then $mapping 
             else 
               let $match := $mapping/(item|collection)[@name = $curtoken]
               return 
                 if ($match) then $match
                 else  
                    let $match := $mapping/item[not(@name)]
                    return 
                      if ($match) then $match[1] else (),
                      (: maybe we ought to generate <item/> if $mapping is a 'collection'...? :)
    (: inherited attributes :)
    $db := if ($page/@db) then $page/@db else $inherit-db,
    $resource := if ($page/@resource) then $page/@resource else $inherit-resource,
    $collection : = if ($page/@collection) then $page/@collection else $inherit-collection,
    $suffix : = if ($page/@suffix) then $page/@suffix else $inherit-suffix,
    $access : = if ($page/@access) then $page/@access else $inherit-access
(:  $log := oppidum:debug(('match-token-iter with $cur', $tokens[$index], ' and $greedy=', if ($greedy) then 'true' else 'false', ' name=', string($mapping/@name), ' page=', string($page/@name))):)
  return 
    if (not($last)) then 
      if ($greedy) then
        if ($page[@name]) then (: switch to non greedy iteration on the new branch :)
          command:match-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $suffix, $access, false())
        else 
          let $nextok := $tokens[$index+1] (: look ahead 1 token :)
          return
            if ($page[not(@name)] and 
                (($page/(item|collection)[@name = $nextok]) or ($nextok = tokenize($page/@supported, ' ')))) then
              command:match-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $suffix, $access, false())
            else (: continue with greedy iteration same branch :)
              command:match-token-iter($method, $index + 1, $tokens, $mapping, $db, $resource, $collection, $suffix, $access, $greedy)
      else
        if ($page[not(@name)]) then (: switch to greedy iteration on the new branch :)
          command:match-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $suffix, $access, true())
        else 
          if ($page[@name]) then (: continue with greedy iteration on the new branch :)
            command:match-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $suffix, $access, false())
          else  (: no page and not greedy : failure :)
            ()
    else 
      if (not($page) and not($greedy)) then (: failure : backtracking :)
        ()
      else (: success : $page or $greedy :) 
        (
        (: either it's an identified resource / facet / action or a greedy method (GET or POST) :)
        command:gen-trail(boolean($action-name), $tokens, $count),
        let 
          $verb := if (($method = 'GET') or ($method = tokenize($page/@method, ' '))) then $method else 'not-supported',
          $action := if ($action-name) then $action-name else $verb
          (: actions :)
        return
          if ($action = 'not-supported') then
            attribute { 'error' } { 'not-supported' }
          else (
            attribute { 'action' } { $action },
            attribute { 'type' } { name($page) },
            element { 'resource' } {
              if (($count > 1) or ($action-name = '')) then 
                attribute { 'name' } { if ($action-name) then $tokens[$index - 1] else $tokens[$index] } 
              else 
                (),
              if ($db) then attribute { 'db' } { command:expand-paths($db, $tokens) } else (),
              if ($resource) then attribute { 'resource' } { command:expand-paths($resource, $tokens) } else (),
              if ($collection) then attribute { 'collection' } { command:expand-paths($collection, $tokens) } else (),
              if ($suffix) then attribute { 'suffix' } { $suffix } else (),
              if ($access) then attribute { 'access' } { $access } else (),
              $page/(@template | @check | @epilogue | @supported | @method),
              if ($page) then
                $page/(model | view)
              else 
                $mapping/(model | view),
              $page/(action[@name=$action] | collection | access | variant)
            }
          )
      ) 
};

declare function command:parse-token-iter(
  $method as xs:string,
  $index as xs:integer,
  $tokens as xs:string*,
  $mapping as element(),
  $inherit-db as xs:string?,
  $inherit-resource as xs:string?,   
  $inherit-collection as xs:string?,
  $inherit-suffix as xs:string?,
  $inherit-access as xs:string?
) as node()*
{ 
  let
    $curtoken := $tokens[$index],
    $count := count($tokens),
    $last := $index = $count,
    $action-name := if ($last and ($curtoken = tokenize($mapping/@supported, ' '))) then $curtoken else '',
    $page := if ($action-name) then $mapping 
             else 
               let $match := $mapping/(item|collection)[@name = $curtoken]
               return 
                if ($match) then $match
                else
                 (: tries to resolve within import statements :)
                 let $vars := (
                   if ($mapping/@collection) then $mapping/@collection else $inherit-collection,
                   if ($mapping/@resource) then $mapping/@resource else $inherit-resource,
                   $mapping/@template,
                   $mapping/@epilogue
                   )
                 let $match := local:match-import-iter($index - 1, $curtoken, '/db/www/oppidoc', $vars, $mapping/import)
                 return
                   if ($match) then $match
                   else
                    let $match := $mapping/(item|collection)[@name = $curtoken]
                    return
                      if ($match) then $match
                      else
                        let $match := $mapping/item[not(@name)]
                        return 
                          if ($match) then $match[1] 
                          else
                            let $match := $mapping/(item|collection)[@name = '*']
                            return
                              if ($match) then $match[1] else (),
                          (: maybe we ought to generate <item/> if $mapping is a 'collection'...? :)
    (: inherited attributes :)
    $db := if ($page/@db) then $page/@db else $inherit-db,
    $resource := if ($page/@resource) then $page/@resource else $inherit-resource,
    $collection : = if ($page/@collection) then $page/@collection else $inherit-collection,
    $suffix : = if ($page/@suffix) then $page/@suffix else $inherit-suffix,
    $access : = if ($page/@access) then $page/@access else $inherit-access
  return 
    if ($page[@name = '*']) then (: recurse in greedy mode starting at self :)
      let $res := command:match-token-iter($method, $index, $tokens, $page, $db, $resource, $collection, $suffix, $access, true())
      return
        if ($res) then $res else attribute { 'error' } { 'not-found' }
    else if (not($last) and $page) then (: recurse :)
      command:parse-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $suffix, $access)
    else (: terminate, either it is an error or a recognized command :)    
      (
      command:gen-trail(boolean($action-name), $tokens, $count),
      if (not($page)) then
        attribute { 'error' } { 'not-found' }
      else (: that branch assumes $last is true :)
        let
          $verb := if (($method = 'GET') or ($method = tokenize($page/@method, ' '))) then $method else 'not-supported',
          $action := if ($action-name) then $action-name else $verb     
          (: actions :)
        return
          if ($action = 'not-supported') then
            attribute { 'error' } { 'not-supported' }
          else (
            attribute { 'action' } { $action },
            attribute { 'type' } { name($page) },
            element { 'resource' } {
              if (($count > 1) or ($action-name = '')) then 
                attribute { 'name' } { if ($action-name) then $tokens[$index - 1] else $tokens[$index] } 
              else 
                (),
              if ($db) then attribute { 'db' } { command:expand-paths($db, $tokens) } else (),
              if ($resource) then attribute { 'resource' } { command:expand-paths($resource, $tokens) } else (),
              if ($collection) then attribute { 'collection' } { command:expand-paths($collection, $tokens) } else (),
              if ($suffix) then attribute { 'suffix' } { $suffix } else (),
              if ($access) then attribute { 'access' } { $access } else (),
              $page/@template,
              $page/@check,          
              $page/@epilogue,        
              $page/@supported,        
              $page/@method,        
              $page/model,
              $page/view,
              $page/action[@name=$action],
              $page/collection,
              $page/access,
              $page/variant
            }
          )
    )
};

(: ========================================================================
   Converts the path entered by the user on the URL to an XML description
   of the targeted resources and actions.
   
   Enforces minimum semantic rules in the request syntax (to be described)
   
   Relies on a gobal $command:actions string listing all the allowed actions. 
   ========================================================================
:)
declare function command:parse-url( 
  $base-url as xs:string,
  $exist-root as xs:string,
  $exist-path as xs:string,
  $url as xs:string, 
  $method as xs:string,
  $mapping as element(),
  $lang as xs:string ) as element()
{         
  let
    $extension := if (contains($url, '.')) then substring-after($url, '.') else '',
    $raw-payload := if ($extension != '') then substring-before($url, '.') else $url,  
    $payload := if ($raw-payload = '/') then $mapping/@startref else $raw-payload, (: although we SHOULD have redirected before reaching that line :)
    $tokens := tokenize($payload, '/')[. != ''],
    $format := if ($extension) then $extension else request:get-parameter('format', '')
  return
    <command>
      {     
      attribute base-url { $base-url },
      attribute app-root { $exist-root },
      attribute exist-path { $exist-path },
      attribute lang { $lang },      
      attribute db { $mapping/@db },
      $mapping/@confbase,
      $mapping/@mode,
      if ($mapping/error/@mesh) then attribute error-mesh { $mapping/error/@mesh } else (),
      if ($format) then attribute format { $format } else (),
      command:parse-token-iter($method, 1, $tokens, $mapping, 
        $mapping/@db, $mapping/@resource, $mapping/@collection, $mapping/@suffix, $mapping/@access)
      }
    </command>
};