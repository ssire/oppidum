xquery version "1.0";
(: --------------------------------------
	 Oppidum : oppidum low level error model

	 Author: Stéphane Sire <s.sire@free.fr>
	 
	 Generates an XML error message or registers an XML error to be rendered 
	 in the epilogue.
	 
	 Calls set-status-code to set the HTTP response code if the error has a
   status code. Note that this will terminate the pipeline rendering, hence it
   is done only if the pipeline specification in "oppidum.pipeline" does not
   specify a view nor an epilogue.
	 
	 Error messages are retrieved from Oppidum's internal error message
   database. The language is taken from the command lang attribute and
   defaults to 'en'.
   
   This generator is only used to signal errors that happens before the
   pipeline generation. To signal errors that happens within your model
   generator script in a pipeline, you should use the util:render-error
   function the same way it is used by this script.
   
   TODO: 
   - look for message first into '/db/sites/{site}/config/errors.xml to
     bypass Oppidum's default error messages - add a hook to
   
   August 2011
   -------------------------------------- :) 
    
declare option exist:serialize "method=xml media-type=application/xml";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";

(:::::::::::::  BODY  ::::::::::::::)

let 
  $cmd := request:get-attribute('oppidum.command'),
  $pipeline := request:get-attribute('oppidum.pipeline'),
  $err-type := request:get-attribute('oppidum.error.type'),
  $err-clue := request:get-attribute('oppidum.error.clue')    

return               
  (: test also 'xml' and 'raw' in case the error is raised during pipeline generation (e.g. DB-NOT-FOUND)
     when it is no more possible to change the pipeline specification
     FIXME: turn DB-NOT-FOUND into a pre-construction error :)   
  let $short-pipeline := ((string($cmd/@format) = 'xml') or (string($cmd/@format) = 'raw') or ($pipeline/view[@onerror]) or not($pipeline/(view | epilogue)))
  return            
    if ($short-pipeline) then
      (: generates a meaningful error message :)  
      let 
        $err-data := oppidum:render-error($cmd/@db, $err-type, $err-clue, $cmd/@lang, false()),
        $go := empty($pipeline/view[@onerror]),
        $exec := 
          if (($err-data/@code) and $go) then
            response:set-status-code($err-data/@code)
          else ()
      return 
        $err-data
    else (
      (: stores an error message using Oppidum API, for rendering in the epilogue :)
      oppidum:add-error($err-type, $err-clue, false()),
      <error/>                                   
      )[last()]