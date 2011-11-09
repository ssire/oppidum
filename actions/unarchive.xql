xquery version "1.0";        
(: --------------------------------------
   UAP Web Site : main controller    

   Author: Stéphane Sire <s.sire@free.fr>
   
   Sets an item's status to 'archived'
   See also 'unarchive.xql'   
   Pre-condition: user has enough privileges
   and the document exists   
   
   Pre-conditions: 
   - resource exists in collection in database (as described per 'oppidum.command')
   
   March 2011
   -------------------------------------- :)
      
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";   
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";   

(:::::::::::::  BODY  ::::::::::::::)

let 
  $cmd := request:get-attribute('oppidum.command'),
  $db := $cmd/resource/@db,
  $col := $cmd/resource/@collection,
  $rsrc := $cmd/resource/@resource,  
  $doc-uri := concat($db, '/', $col, '/', $rsrc)  
return                 
  let 
    $data := doc($doc-uri)/*[1],
    $res := if ($data/@status) 
              then update delete $data/@status
              else (),
    $msg := oppidum:add-message('ACTION-UNARCHIVED', $cmd/@trail, true())    
  return
    <success><message>unarchived</message></success>
