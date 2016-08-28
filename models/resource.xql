xquery version "1.0";
(: --------------------------------------
   Oppidum : REST resource mapper

   Author: Stéphane Sire <s.sire@oppidoc.fr>

   Simple REST mapper to :
   - unreference reference document for a given application resource URL 
   - unreference reference document for a given application collection URL 
     when it is defined, or lists the reference collection content otherwise

   Usage : add the following entry to mapping.xml

     <item name="rest">
        <item name="*">
          <model src="models/resource.xql"/>
        </item>
     </item>

   for debug you can also add :

    <variant name="GET" format="parsed">
      <model src="models/resource.xql"/>
    </variant>

   See also: lib/resource.xqm (variables substitution in reference paths)

   August 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";
import module namespace command = "http://oppidoc.com/oppidum/command" at "../lib/command.xqm";
import module namespace resource = "http://oppidoc.com/oppidum/resource" at "../lib/resource.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Serializes a resource
   ====================================================================== 
:)
declare function local:get-resource( $path as xs:string ) as element() {
  <Resource Path="{ $path }">
    {
    if (not(contains($path, 'MISSING (')) and fn:doc-available($path)) then
      fn:doc($path)
    else
      oppidum:throw-error("DB-NOT-FOUND", $path)
    }
  </Resource>
};

(: ======================================================================
   Serializes a collection
   TODO: serializes reference document if defined and if it exists
   or collection content otherwise
   ====================================================================== 
:)
declare function local:get-collection( $path as xs:string ) as element() {
  <Collection Path="{ $path }">
    {
    if (xdb:collection-available($path)) then (
      for $iter in xdb:get-child-resources($path)
      return
        <resource Name="{ $iter }"/>,
      for $iter in xdb:get-child-collections($path)
      return
        <collection name="$iter"/>
      )
    else
      oppidum:throw-error("DB-NOT-FOUND", $path)
    }
  </Collection>
};

let $cmd := oppidum:get-command()
let $path := substring-after($cmd/@trail, 'rest')
let $mapping := fn:doc('/db/www/oppidum/config/mapping.xml')/site
let $parsed := command:parse-url($cmd/@base-url, $cmd/@app-root, $cmd/@exist-path, $path, 'GET', $mapping, 'en', ())
return
  if ($cmd/@format eq 'parsed') then
  <REST path="{ $path }">
    { $parsed }
  </REST>
  else
    if (exists($parsed/resource)) then
      let $r := $parsed/resource
      return 
        if (ends-with(request:get-uri(), '/')) then
          local:get-collection(resource:path-to-ref-col($parsed))
        else
          local:get-resource(resource:path-to-ref($parsed))
    else
      oppidum:throw-error("URI-NOT-FOUND", ())

