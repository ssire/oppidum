xquery version "1.0";
(: --------------------------------------
   Oppidum: basic read action

   Author: Stéphane Sire <s.sire@free.fr>
  
   Dumps an XML resource from the database unless it has been archived 
   and the user does not have the 'create' right in which case it returns <archive/>. 
   
   The XML resource may be a page or an item in a collection
   
   Pre-conditions: 
   - resource exists in collection in database (as described per 'oppidum.command')

   May 2011
   -------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(:::::::::::::  BODY  ::::::::::::::)

let $doc-uri := oppidum:path-to-ref()
let $rights := request:get-attribute('oppidum.rights')
return  
  let $data := fn:doc($doc-uri)
  return
    if (($data/*[1]/@status = 'archive') and not(contains($rights, 'unarchive'))) then
      <error code="410">
        <message>The resource has been archived and is no longer available</message>
      </error>
    else
      $data
