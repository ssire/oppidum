xquery version "1.0";        
(: --------------------------------------
   Oppidum module: image 

   Author: Stéphane Sire <s.sire@free.fr>
 
   Serves images from the database. Sets a Cache-Control header.
   
   TODO:
   - improve Cache-Control (HTTP 1.1) with Expires / Date (HTTP 1.0)
   - (no need for must-revalidate / Last-Modified since images never change)
   - return a standard "NOT-FOUND" image when image not found

   September 2011
   -------------------------------------- :)

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace image = "http://exist-db.org/xquery/image";
(:import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../lib/util.xqm";:)

let 
  $cmd := request:get-attribute('oppidum.command'),
  $db := $cmd/resource/@db,
  $col-uri := concat($db, '/', $cmd/resource/@collection),
  $filename := concat($cmd/resource/@resource, '.', $cmd/@format)

return
  if ( xdb:collection-available($col-uri) )
  then
    let $image-uri := concat($col-uri, '/', $filename)
    return
      if (util:binary-doc-available($image-uri)) 
      then  
        let $image := util:binary-doc($image-uri)
        return (
          response:set-header('Pragma', 'x'),
          response:set-header('Cache-Control', 'public, max-age=900000'),
          response:stream-binary($image, concat('image/', $cmd/@format))
        )
      else (
        response:set-status-code(404),
        <error>not found</error>
        )
  else (
    response:set-status-code(404),
    <error>not found</error>
    )