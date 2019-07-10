xquery version "3.0";
(: -----------------------------------------------
   Oppidum framework utilities

   Compatibility layer to develop portable XQuery applications

	 Author: Stéphane Sire <s.sire@oppidoc.fr>

   January 2017 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

module namespace compat = "http://oppidoc.com/oppidum/compatibility";
import module namespace sm = 'http://exist-db.org/xquery/securitymanager';

(:~
 : Changes owner, groups and permissions for a collection or resource
 :
 :)
declare function compat:set-owner-group-permissions( $path as xs:string, $owner as xs:string, $group as xs:string, $mod as xs:string ) {
  sm:chown(xs:anyURI($path), $owner),
  sm:chgrp(xs:anyURI($path), $group),
  sm:chmod(xs:anyURI($path), $mod)
};

(:~
 : Return name of the current user executing script on database.
 : This should be the Surrogate user if you are using oppidum security.xml layer. 
 :
 :)
declare function compat:username() as xs:string? {
  let $id := sm:id()/sm:id
  return
    if ($id/sm:effective) then 
      $id/sm:effective/sm:username
    else
      $id/sm:real/sm:username
};

(:~
 : Return name of the owner of a collection or resource or throws
 : an exception if it does not exist.
 :
 :)
declare function compat:owner( $path as xs:string ) as xs:string {
  string(sm:get-permissions(xs:anyURI($path))/sm:permission/@owner)
};
