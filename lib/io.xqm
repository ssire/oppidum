xquery version "1.0";    
(: -----------------------------------------------
   Oppidum framework utilities

   Input / Output utilities
   
   Depends on 'util.xqm'

   Author: Stéphane Sire <s.sire@free.fr>

   December 2011 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)     

module namespace io = "http://oppidoc.com/oppidum/io";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";                    
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "util.xqm";

(: ======================================================================
   Returns a unique identifier for naming a resource inside the $col-uri
   collection. The identifier is the biggest number that serves as a prefix
   for the existing resources + 1.
   ======================================================================
:) 
declare function io:gen-unique-id( $col-uri as xs:string ) as xs:integer 
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

(: ======================================================================
   Creates a new resource inside collection $col-uri using the biggest
   available number as a resource name and the '.xml' suffix. 
   Returns the resource name or empty, does not alter the response.
   ======================================================================
:) 
declare function io:create-resource( $col-uri as xs:string, $data as element(), $flash as xs:boolean ) as xs:string?
{
  if (xdb:collection-available($col-uri)) then (: sanity check :)    
    let $uid := io:gen-unique-id($col-uri)  
    let $name := concat($uid, '.xml')
    let $stored := xdb:store($col-uri, $name, $data)
    let $exec := if(not($stored eq ())) then
                   oppidum:add-message('ACTION-CREATE-SUCCESS', string($uid), $flash)
                 else        
                   oppidum:throw-error('DB-WRITE-INTERNAL-FAILURE', ())
    return
      $name
  else
    (oppidum:add-error('DB-WRITE-NO-COLLECTION', (), false()), ())[last()]
    
};