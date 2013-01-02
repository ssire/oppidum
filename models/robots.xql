xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum default robots.txt file generator

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   March 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)
   
declare option exist:serialize "method=text media-type=text/plain";

import module namespace response = "http://exist-db.org/xquery/response";
import module namespace request = "http://exist-db.org/xquery/request";

declare function local:gen-disallow() as xs:string {
  let $disallow := request:get-attribute('xquery.disallow')
  return
    if ($disallow) then
      string-join(
        for $s in tokenize($disallow, ' ') 
        return concat('Disallow: ', $s),
        codepoints-to-string((13, 10))
      )
    else 
      'Disallow: /login'
};

let $res := concat('User-Agent: *', codepoints-to-string((13, 10)), local:gen-disallow())
let $age := request:get-attribute('xquery.max-age')
let $max-age := if ($age) then $age else '604800' (: 1 week :) 
return (
  response:set-header('Pragma', 'x'),
  response:set-header('Cache-Control', concat('public, max-age=', $max-age)), 
  $res
)
