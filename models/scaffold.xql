xquery version "1.0";
(: --------------------------------------
	 Oppidum framework

	 Returns a message saying the functionality will be available soon.
	 
	 The model is directly returned as a <site:view> element so that it can be
   rendered directly in the epilogue without an intermediate view
   transformation.

	 Author: Stéphane Sire <s.sire@free.fr>

	 August 2011
	 -------------------------------------- :)
declare namespace site="http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=application/xml";

let $cmd := request:get-attribute('oppidum.command')
return                                                  
  <site:view>
    <site:content>
    {
    if ($cmd/@lang = 'fr') then 
      <p>Cette fonctionnalité sera bientôt disponible...</p>
    else 
      <p>This functionality will be available soon...</p>
    }
    </site:content>
  </site:view>