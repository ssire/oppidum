xquery version "3.0";
(: ------------------------------------------------------------------
  Description :
    oppidum installation script for eXist v2.2
  
  Date : March 2018
   ------------------------------------------------------------------ :)

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace request = "http://exist-db.org/xquery/request";

(: ======================================================================
   Changes owner, groups and permissions for a collection or resource
   NOTE: not implemented for eXist-1.4.3 !
   ======================================================================
:)
declare function local:set-owner-group-permissions( $path as xs:string, $owner as xs:string, $group as xs:string, $mod as xs:string ) as empty() {
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

(:
Description : 
    Replace the following code from bootstrap.xh
echo "xmldb:chmod-collection('/db/www/oppidum/config', util:base-to-integer(0775, 8))" | ../../../../bin/client.sh -u admin -P $1 -x
echo "xmldb:chmod-collection('/db/www/oppidum/mesh', util:base-to-integer(0775, 8))" | ../../../../bin/client.sh -u admin -P $1 -x
:)
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


let $targets := ( '/www/oppidum/config', '/db/www/oppidum/mesh' )
return 
    local:create-and-update-coll( $targets )
