xquery version "3.0";
(: ------------------------------------------------------------------
  Description :
    oppidum installation script for eXist v2.2 or superior
  
  Date : March 2018
   ------------------------------------------------------------------ :)

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace request = "http://exist-db.org/xquery/request";

(: ======================================================================
   Changes owner, groups and permissions for a collection or resource
   NOT compatible with exist-1.4.3
   ======================================================================
:)
declare function local:set-owner-group-permissions( $path as xs:string, $owner as xs:string, $group as xs:string, $mod as xs:string ) {
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

declare function local:create-and-update-coll( $targets as xs:string* ) {
for $uri in $targets 
return 
    if (xdb:collection-available(concat("/db", $uri))) 
    then local:set-owner-group-permissions(concat("/db", $uri), 'admin', 'guest', 'rwxr-xr-x')
    else (
        xdb:create-collection("/db", $uri),
        local:set-owner-group-permissions(concat("/db", $uri), 'admin', 'guest', 'rwxr-xr-x')
    )
};

let $targets := ( '/www/oppidum/config', '/www/oppidum/mesh' )
return 
    local:create-and-update-coll( $targets )
