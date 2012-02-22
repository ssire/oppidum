xquery version "1.0";
(: --------------------------------------
   Oppidum basic read action

   Returns the reference resource in the reference collection from the
   database unless it has been archived and the user does not have the right
   to activate it in which case it throws an Oppidum error.
   
   Pre-condition: 
   - the reference resource must exist (i.e. use check="true" in the mapping)
   
   TODO:
   - use a builtin.activate parameter to pass the name of the action giving the user
     the right to activate an archived resource

   Author: Stéphane Sire <s.sire@free.fr>

   November 2011 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(:::::::::::::  BODY  ::::::::::::::)

let $doc-uri := oppidum:path-to-ref()
let $rights := request:get-attribute('oppidum.rights')
let $activate := 'activer'
return  
  let $data := fn:doc($doc-uri)
  return
    if (($data/*[1]/@status = 'archive') and not(contains($rights, $activate))) then
      let $cmd := request:get-attribute('oppidum.command')
      return oppidum:throw-error('ARCHIVED', $cmd/resource/@name)
    else
      if ($data) then
        $data
      else
        <empty/>
