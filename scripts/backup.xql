xquery version "1.0";
(: -----------------------------------------------
   Oppidum utility

   Cut and paste this script using the exist-db Java admin 
   client to backup a collection inside the 'database' 
   folder on EDSI-TECH server.
   
   Note that you can also use the "/admin" URL
   to do the same if it has been wired in the mapping.

   Author: Stéphane Sire <sire@oppidoc.fr>

   August 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
   
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace file="http://exist-db.org/xquery/file";
declare namespace system="http://exist-db.org/xquery/system";

(: $dir is relative to the application WEB-INF :)
declare function local:backup-collection( $col as xs:string, $dir as xs:string, $pwd as xs:string ) {
 let $prefix := replace(substring($col, 2), '/', '-')
 return
   let $params :=<parameters>
                   <param name='user' value='admin'/>
                   <param name='password' value='{$pwd}'/>
                   <param name='dir' value='{$dir}'/>
                   <param name='prefix' value='{concat($prefix, "-")}'/>
                   <param name="suffix" value=".zip"/>
                   <param name='collection' value='{$col}'/>
                 </parameters>
   return
     system:trigger-system-task('org.exist.storage.BackupSystemTask', $params)
};

declare function local:consistency-check( $col as xs:string, $dir as xs:string, $pwd as xs:string ) {
 let $prefix := replace(substring($col, 2), '/', '-')
 return
  let $params := <parameters>
                   <param name="output" value="{$dir}"/>
                   <param name="backup" value="yes"/>
                   <param name="incremental" value="no"/>
                   <param name="zip" value="yes"/>
                 </parameters>
   return
     system:trigger-system-task('org.exist.storage.ConsistencyCheckTask', $params)
};

let $col := '/db/sites/oppidoc' 
let $path := '/mnt/domains/oppidoc.fr/database'
(:let $path := '/Users/stephane/Home/apps/database':)
let $pwd := 'test' 
let $action := 'backup' (: 'check', 'list', 'backup' or 'jobs' :)
return 
  if ($action = 'list') then
    file:directory-list($path, '*.zip')
  else if ($action = 'backup') then
    local:backup-collection($col, $path, $pwd)
  else if ($action = 'check') then
    local:consistency-check($col, $path, $pwd)
  else 
    system:get-scheduled-jobs() 
    