xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum default robots.txt file generator

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   March 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)
   
declare option exist:serialize "method=text media-type=text/plain";

import module namespace response = "http://exist-db.org/xquery/response";

let $res := concat('User-Agent: *', codepoints-to-string((13, 10)),'Disallow: /login')
return (
  response:set-header('Pragma', 'x'),
  response:set-header('Cache-Control', 'public, max-age=9000000'),
  $res
)
