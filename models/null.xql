xquery version "1.0";
(: --------------------------------------
	 Oppidum framework
	 
	 Returns a <null/> model. This may be useful to initialize the model to an
   empty model in a pipeline (e.g. to render the epilogue together with some
   error or information messages stored in the request or in the flash; to
   build a fake pipeline with no output in case the response will be
   redirected).

	 Author: Stéphane Sire <s.sire@free.fr>

	 July 2011
	 -------------------------------------- :)
declare option exist:serialize "method=xml media-type=application/xml";

<null/>