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
  return 
    if (not($last) and $page) then 
      (: recurse :)
      command:parse-token-iter($method, $index + 1, $tokens, $page, $db, $resource, $collection, $suffix, $access)       
    else (
      (: terminate, either it is an error or a recognized command :)    
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
      if ($mapping/error/@mesh) then attribute error-mesh { $mapping/error/@mesh } else (),
      if ($format) then attribute format { $format } else (),
      command:parse-token-iter($method, 1, $tokens, $mapping, 
        $mapping/@db, $mapping/@resource, $mapping/@collection, $mapping/@suffix, $mapping/@access)
      }
    </command>
};