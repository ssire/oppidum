xquery version "1.0";
(: --------------------------------------
   Oppidum standard actions

   Author: Stéphane Sire <s.sire@free.fr>
   
   Creates a new resource inside the reference collection
   
   TODO:
   - add a builtin.perms ("rwur--r--") mapping level parameter 
     to set permission of the freshly created resource
   
   November 2011 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";   
import module namespace xdb = "http://exist-db.org/xquery/xmldb";                    
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: Returns a unique identifier for naming a resource inside the $col-uri collection.
   The identifier is the biggest number that serves as a prefix for the existing resources + 1.
:)
declare function local:gen-unique-id( $col-uri as xs:string ) as xs:integer 
{
  let $files := xdb:get-child-resources($col-uri)
  return 
    if (count($files) = 0) then
       1
    else 
      max((0, 
          for $name in $files
          let $m := text:groups($name, '^(\d+)')
          where count($m) > 0
          return xs:integer($m[2]))) + 1
};

(:::::::::::::  BODY  ::::::::::::::)
let 
  $cmd := request:get-attribute('oppidum.command'),
  $col-uri := oppidum:path-to-ref-col()
return           
  if (xdb:collection-available($col-uri)) then (: sanity check :)    
    let $uid := local:gen-unique-id($col-uri)
    let $data := request:get-data()
    let $name := concat($uid, '.xml')
    let $stored-path := xdb:store($col-uri, $name, $data)
    return
      if(not($stored-path eq ())) then (
(:    xdb:set-resource-permissions($col-uri, $name, ?, ?, util:base-to-integer(0744, 8)), :)
        oppidum:add-message('ACTION-UPDATE-SUCCESS', '', true()),
        response:set-status-code(201),
        response:set-header('Location', concat($cmd/@base-url, $cmd/@trail, '/', $uid)), (: redirect info :)
        <success>
          <message>The resource has been saved</message>
        </success>                      
        )[last()]
      else        
        oppidum:throw-error('DB-WRITE-INTERNAL-FAILURE', ())
  else
    oppidum:throw-error('DB-WRITE-NO-COLLECTION', ())
