xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum requestion inspection

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Serializes the request

   May 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=application/xml";      

<request>
 {
 for $name in request:get-header-names()
 let $value := request:get-header($name)
 return
  <header name="{$name}" value="{$value}"/>
 }
</request>
 