xquery version "1.0";        
(: --------------------------------------
   UAP Web Site : main controller    

   Author: Stéphane Sire <s.sire@free.fr>
   
   Sets an item's status to 'archived' See also 'unarchive.xql'  
   
   Pre-conditions: 
   - resource exists in collection in database (as described per
     'oppidum.command')
   
   March 2011
   -------------------------------------- :)
      
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";   

declare option exist:serialize "method=xml media-type=text/xml";

(:::::::::::::  BODY  ::::::::::::::)

let $cmd := request:get-attribute('oppidum.command')
let $doc-uri := oppidum:path-to-ref()
return                 
  let $data := doc($doc-uri)/*[1]
  return
    (   
    if ($data/@status and (string($data/@status) != 'archive')) then
      update value $data/@status
      with 'archive'
    else
      update insert attribute { 'status' } { 'archive' } 
      into $data,
    oppidum:add-message('ACTION-ARCHIVED', $cmd/@trail, true()),
    <success><message>archived</message></success>
    )[last()]
