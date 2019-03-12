xquery version "1.0";
(: -----------------------------------------------
   Oppidum framework utilities

   Compatibility layer to develop portable XQuery applications

	 Author: Stéphane Sire <s.sire@oppidoc.fr>

   January 2017 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

module namespace compat = "http://oppidoc.com/oppidum/compatibility";

(: ======================================================================
   Changes owner, groups and permissions for a collection or resource
   NOTE: not implemented for eXist-1.4.3 !
   ======================================================================
:)
declare function compat:set-owner-group-permissions( $path as xs:string, $owner as xs:string, $group as xs:string, $mod as xs:string )  {
  if (starts-with(system:get-version(), '1')) then
    ()
  else
    let $module := util:import-module(
          xs:anyURI('http://exist-db.org/xquery/securitymanager'),
          'sm',
          xs:anyURI('securitymanager')
          )
    return (
      util:eval("sm:chown(xs:anyURI($path), $owner)"),
      util:eval("sm:chgrp(xs:anyURI($path), $group)"),
      util:eval("sm:chmod(xs:anyURI($path), $mod)")
      )
};
