xquery version "1.0";
(: --------------------------------------
	 Oppidum : error model generator 

	 Author: Stéphane Sire <s.sire@free.fr>

   Returns an empty <Error/> model
   To be used in conjunction with oppidum:add-error() to describe the error
		
	 June 2011
	 -------------------------------------- :)
declare option exist:serialize "method=xml media-type=application/xml";

<error>
  <message>Not implemented</message>
</error>
  
