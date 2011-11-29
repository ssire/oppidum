xquery version "1.0";
(: --------------------------------------
   Oppidum: write a resource to the DB

   Author: Stéphane Sire <s.sire@free.fr>
  
   Writes a resource to a collection and returns an XML success or error
   message. This design is adapted for simple XML pipeline (no view, no
   epilogue) to be called from an Ajax request.
 
   TODO:       
   - manage image collections associated with the resource
     (delete dandling images)   
     
   NOTE: as an alternative it should be possible to use eXist-db REST API
   instead of this ?
   
   August 2011
   -------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";   
import module namespace xdb = "http://exist-db.org/xquery/xmldb";                    
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(:::::::::::::  BODY  ::::::::::::::)
let 
  $cmd := request:get-attribute('oppidum.command'),
  $col-uri := oppidum:path-to-ref-col(),
  $filename := $cmd/resource/@resource
return           
  if (xdb:collection-available($col-uri)) then (: sanity check :)
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
        oppidum:throw-error('DB-WRITE-INTERNAL-FAILURE', ())
  else
    oppidum:throw-error('DB-WRITE-NO-COLLECTION', ())
