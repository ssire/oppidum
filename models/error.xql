xquery version "3.0";
(: --------------------------------------
	 Oppidum : oppidum low level error reporting

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
   generator script in a pipeline, you should use the util:throw-error
   function the same way it is used by this script.
   
   November 2011
   -------------------------------------- :) 
    
declare option exist:serialize "method=xml media-type=application/xml";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";
import module namespace request="http://exist-db.org/xquery/request";

let $cmd := oppidum:get-command()
let $err-type := request:get-attribute('oppidum.error.type')
let $err-clue := request:get-attribute('oppidum.error.clue')
let $err-method := request:get-attribute('oppidum.error.method')
return (
  oppidum:throw-error($err-type, $err-clue),
  if (string($cmd/@format) ne 'xml' and $err-method eq 'json' or starts-with(request:get-header('Accept'), 'application/json')) then
    util:declare-option("exist:serialize", "method=json media-type=application/json")
  else
    ()
  )
