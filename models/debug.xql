xquery version "1.0";
(: --------------------------------------
	 Oppidum : debug generator

	 Author: Stéphane Sire <s.sire@free.fr>

	 Outputs special Oppidum attributes added to the request and a few extra
   information for debug purpose as an XML document.
		
	 August 2011
	 -------------------------------------- :)
declare namespace request = "http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=application/xml";

let
  $base-url := request:get-attribute('oppidum.base-url'),
  $cmd := request:get-attribute('oppidum.command'),
  $pipeline := request:get-attribute('oppidum.pipeline'),
  $rights := request:get-attribute('oppidum.rights'),
  $granted := request:get-attribute('oppidum.granted'),
  $mesh := request:get-attribute('oppidum.mesh'),
  $implementation := request:get-attribute('oppidum.debug.implementation'),
  $def := request:get-attribute('oppidum.debug.default'),
  $err-type := request:get-attribute('oppidum.error.type'),
  $err-clue := request:get-attribute('oppidum.error.clue'),
  $rc := codepoints-to-string(13)

return	
  <result>
   {
   $rc,
   comment { 'oppidum.error.type' },
   $err-type,
   $rc,
   comment { 'oppidum.error.clue' },
   $err-clue,
   $rc,
   comment { 'oppidum.base-url (may be deprecated soon)' },
   $base-url,
   $rc,
   comment { 'oppidum.command' },
   $cmd,
   $rc,
   comment { 'oppidum.pipeline' },
   $pipeline,
   comment { 'oppidum.mesh' },
   $mesh,
   $rc,
   comment { 'oppidum.granted' },
   $granted,
   $rc,
   comment { 'oppidum.rights' },
   xs:string($rights),
   $rc,
   comment { 'exist generated pipeline (available only for debug)' },
   $implementation,
   $rc,
   comment { 'default actions (available only for debug)' },
   $def
   }
 </result>


