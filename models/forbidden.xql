xquery version "1.0";
(: --------------------------------------
   Oppidum : error model generator 

   Author: Stéphane Sire <s.sire@free.fr>

   -------------------------------------- :)
declare option exist:serialize "method=xml media-type=application/xml";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

oppidum:throw-error('FORBIDDEN', ())
