xquery version "1.0";
(: --------------------------------------
   DEPRECATED : VA ETRE SUPPRIME BIENTOT

   Oppidum: simple write

   Author: Stéphane Sire <s.sire@free.fr>
  
   Writes a resource to a collection.
   Should be called from an Ajax call (no rendering).
   
   TODO:       
   - add access control
   - manage image collections associated with the resource
     (delete dandling images)  
   - localize success/error messages 
   
   July 2012
   -------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";   
import module namespace xdb = "http://exist-db.org/xquery/xmldb";                    
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:error($code as xs:integer, $msg as xs:string) as element() 
{                                                                                 
  let $void := response:set-status-code($code)
  return 
    <error code="{$code}"><message>{$msg}</message></error>
};                                                                      

(:::::::::::::  BODY  ::::::::::::::)
let 
  $cmd := request:get-attribute('oppidum.command'),
  $col-uri := oppidum:path-to-ref-col(),
  $filename := $cmd/resource/@resource,  
  $rights := 'none'
(:  $rights := request:get-parameter('rights', ()):)
return           
  if (xdb:collection-available($col-uri)) then
    let                   
      $data := request:get-data(),
      $stored-path := xdb:store($col-uri, $filename, $data)
    return
      if(not($stored-path eq ())) then (
        oppidum:add-message('ACTION-UPDATE-SUCCESS', '', true()),
        response:set-status-code(201),
        response:set-header('Location', concat($cmd/@base-url, $cmd/@trail)), (: redirect info :)
        <success>
          <message>The resource has been saved</message>
        </success>                      
        )[last()]
      else
        local:error(500, 'Server error while saving the resource: write failed')
  else
    local:error(500, 'Server error while saving the resource: resource collection not available')
