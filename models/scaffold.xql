xquery version "1.0";
(: ------------------------------------------------------------------
	 Oppidum framework

	 Returns a message saying the functionality will be available soon. You can
   use this a model place holder while building a new application.

	 Author: Stéphane Sire <s.sire@free.fr>

	 December 2011 - Copyright (c) Oppidoc S.A.R.L
	 ------------------------------------------------------------------ :)

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=xml media-type=application/xml";

let $cmd := request:get-attribute('oppidum.command')
let $ref-col-uri := oppidum:path-to-ref-col()
return          
  <scaffold>
    <meta>
      <page>{string($cmd/resource/@name)}</page>
      <action>{string($cmd/@action)}</action>
      <reference>
        <collection>{$ref-col-uri}</collection>
        <resource>{string($cmd/resource/@resource)}</resource>
      </reference>      
    </meta>
    <content>
    {
    if ($cmd/@lang = 'fr') then 
      <p>Cette fonctionnalité sera bientôt disponible...</p>
    else 
      <p>This functionality will be available soon...</p>
    }
    </content>
  </scaffold>
