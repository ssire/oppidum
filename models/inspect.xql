xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum requestion inspection

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Serializes the request

   POST test using : curl -X POST -d '<record><name>Bob</name><age>22</age></record>' -H "Content-Type: application/xml" http://localhost:8080/exist/projects/oppidum/test/inspect

   May 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=application/xml indent=yes";      

<request>
 {
 for $name in request:get-header-names()
 let $value := request:get-header($name)
 return
  <header name="{$name}" value="{$value}"/>
 }
 { <get-context-path>{request:get-context-path()}</get-context-path> }
 { <get-uri>{request:get-uri()}</get-uri> }
 { <get-query-string>{request:get-query-string()}</get-query-string> }
 { <get-query-string>{request:get-query-string()}</get-query-string> } 
 <method>{ request:get-method() }</method>
 {
 if (request:get-method() eq 'POST') then
   <POST>{ request:get-data() }</POST>
 else
   () 
  } 
</request>
 