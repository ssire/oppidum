xquery version "3.0";
(: -----------------------------------------------
   Oppidum framework utilities

   Compatibility layer to develop portable XQuery applications

	 Author: Stéphane Sire <s.sire@oppidoc.fr>

   January 2017 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

module namespace compat = "http://oppidoc.com/oppidum/compatibility";
import module namespace sm='http://exist-db.org/xquery/securitymanager';

(: ======================================================================
   Changes owner, groups and permissions for a collection or resource
   ======================================================================
:)
declare function compat:set-owner-group-permissions( $path as xs:string, $owner as xs:string, $group as xs:string, $mod as xs:string ) {
  sm:chown(xs:anyURI($path), $owner),
  sm:chgrp(xs:anyURI($path), $group),
  sm:chmod(xs:anyURI($path), $mod)
};
