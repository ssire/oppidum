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
declare function compat:set-owner-group-permissions( $path as xs:string, $owner as xs:string, $group as xs:string, $mod as xs:string ) as empty-sequence() {
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


(: ======================================================================
   Converts a permission integer into a string like like "rwur--r--"
   r = 4, w = 2, x = 1.
   644 --> rw-r--r--
   ======================================================================
:)
declare function compat:permsIntegerToString( $p as xs:integer) as xs:string
{
    let $perm := xs:string(util:integer-to-base($p, 8))
    let $u := xs:integer(substring($p,1,1))
    let $g := xs:integer(substring($p,2,1))
    let $o := xs:integer(substring($p,3,1))
    
    let $u1 := if (($u eq 7) or ($u eq 6) or ($u eq 5) or ($u eq 4)) then "r" else "-"
    let $u2 := if (($u eq 7) or ($u eq 6) or ($u eq 3) or ($u eq 2)) then "w" else "-"
    let $u3 := if (($u eq 7) or ($u eq 5) or ($u eq 3) or ($u eq 1)) then "u" else "-"
    let $g1 := if (($g eq 7) or ($g eq 6) or ($g eq 5) or ($g eq 4)) then "r" else "-"
    let $g2 := if (($g eq 7) or ($g eq 6) or ($g eq 3) or ($g eq 2)) then "w" else "-"
    let $g3 := if (($g eq 7) or ($g eq 5) or ($g eq 3) or ($g eq 1)) then "u" else "-"
    let $o1 := if (($o eq 7) or ($o eq 6) or ($o eq 5) or ($o eq 4)) then "r" else "-"
    let $o2 := if (($o eq 7) or ($o eq 6) or ($o eq 3) or ($o eq 2)) then "w" else "-"
    let $o3 := if (($o eq 7) or ($o eq 5) or ($o eq 3) or ($o eq 1)) then "u" else "-"
    
    return concat($u1, $u2, $u3, $g1, $g2, $g3, $o1, $o2, $o3)
};