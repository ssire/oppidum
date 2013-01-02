xquery version "1.0";
(: -----------------------------------------------
   Oppidum mire

   Returns Oppidum version message

   Author: Stéphane Sire <sire@oppidoc.fr>

   January 2012 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

(:declare option exist:serialize "method=html media-type=text/html";:)

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace file="http://exist-db.org/xquery/file";

declare namespace session = "http://exist-db.org/xquery/session";
declare namespace system="http://exist-db.org/xquery/system";

(: Returns the path to the directory with the ZIP archives :)
declare function local:get-path() as xs:string {
  let $path := request:get-parameter('path', ())
  return
    if ($path) then
      $path
    else
      let $exist-home := system:get-exist-home()
      let $home := replace($exist-home, '/webapps', '')
          (: some mutualized Tomcat servers such as EDSI-TECH does not have the /webapps part :)
      let $tokens := tokenize($home, '/')
      let $count := count($tokens)
      let $base := 
        if (local:is-tomcat($exist-home)) then
          (: converts :root/:tomcat/:context/:WEB-INF to :root/database :)
          string-join(subsequence($tokens, -2, $count), '/')
        else
          (: converts :root/:exist to :root/database :)
          string-join(subsequence($tokens, 0, $count), '/')
      let $dbpath := concat($base, '/database')
      return
        if (file:is-directory($dbpath)) then $dbpath else $base
};

declare function local:is-tomcat( $home as xs:string ) as xs:boolean {   
  if (ends-with($home, "WEB-INF")) then true() else false()
};

declare function local:retrieve-password() as xs:string? {
  if (request:get-parameter('keeplast', ())) then
    session:get-attribute('oppidum.admin.pwd')
  else
    let $pwd := request:get-parameter('mdp', ())
    return
      if ($pwd) then
        let $do := session:set-attribute('oppidum.admin.pwd', $pwd)
        return $pwd
      else
        ()
};

(: $dir is relative to the application WEB-INF :)
declare function local:backup-collection( $col as xs:string, $dir as xs:string ) as element() {
  let $prefix := replace(substring($col, 2), '/', '-')
  let $pwd := local:retrieve-password()
  return
    if ($pwd) then
      let $params :=<parameters>
                      <param name='user' value='admin'/>
                      <param name='password' value='{$pwd}'/>
                      <param name='dir' value='{$dir}'/>
                      <param name='prefix' value='{concat($prefix, "-")}'/>
                      <param name="suffix" value=".zip"/>
                      <param name='collection' value='{$col}'/>
                    </parameters>
      return
        util:catch('*', local:call-system-task($params, $col, $dir), local:report-exception('backup', $col, $dir))
    else
      <data error="password-missing">
        <file:list directory="{$dir}"/>
      </data>
};

(: Always return true ? cf. http://exist-open.markmail.org/thread/xgjqhbvx3ihciej2 :)
declare function local:call-system-task( $params as element(), $col as xs:string, $dir as xs:string ) as element() {
  <backup collection="{$col}" path="{$dir}">
    { system:trigger-system-task('org.exist.storage.BackupSystemTask', $params) }
  </backup>
};

declare function local:restore-collection( $dir as xs:string, $fn as xs:string ) as element() {
  let $pwd := local:retrieve-password()
  let $fp := concat($dir, '/', $fn)
  return
    if ($pwd) then
      util:catch('*', local:call-restore($fp, $pwd),  local:report-exception('restore', $fn, $dir))
    else
      <data error="password-missing">
        <file:list directory="{$dir}"/>
      </data>      
};

declare function local:call-restore( $fp as xs:string, $pwd as xs:string ) as element() {
  <system:restore name="{$fp}">
    {
    let $res := system:restore($fp, $pwd, ())
    return $res/*
    }
  </system:restore>
};

declare function local:report-exception( $name as xs:string, $param as xs:string, $dir as xs:string ) as element() {
  <data error="{$name}-exception">
    <message>{$util:exception-message}</message>
    <param>{$param}</param>
    <file:list directory="{$dir}"/>
  </data>
};

declare function local:collection-list() as element() {
  <list>
    <collection>/db</collection>
    {
    local:list-one('/db/sites'),
    local:list-one('/db/www')
    }
  </list>
};

declare function local:list-one( $col-uri as xs:string ) as element()* {
  if (xdb:collection-available($col-uri)) then
    (
    <collection>{$col-uri}</collection>,
    for $n in xdb:get-child-collections($col-uri) 
    return <collection>{$col-uri}/{$n}</collection>  
    )
  else ()
};

let $dir := local:get-path()
let $archive := if (request:get-parameter('restore', ())) then request:get-parameter('file', ()) else ()
let $backup := 
  if (request:get-parameter('backup', ())) then
    let $col := request:get-parameter('collection', ())
    return
      if ($col eq 'custom') then request:get-parameter('custom', ()) else $col
  else ()
return
  if ($backup) then
    if (not(file:is-directory($dir))) then 
      <data error="path-not-found">
        <file:list directory="{$dir}"/>
      </data>
    else if (not(xdb:collection-available($backup))) then
      <data error="collection-not-found">
        <collection>{$backup}</collection>
        <file:list directory="{$dir}"/>
      </data>
    else if (request:get-parameter('state', '') eq 'confirm') then
      <confirm action="backup">
        { if (not(session:get-attribute('oppidum.admin.pwd'))) then attribute pwd { 'required' } else () }
        <collection>{$backup}</collection>
        <path>{$dir}</path>
      </confirm>
    else (: do it ! :)
      local:backup-collection($backup, $dir)
  else if ($archive) then (: TODO: test file exists :)
    if (request:get-parameter('state', '') eq 'confirm') then
      <confirm action="restore">
        { if (not(session:get-attribute('oppidum.admin.pwd'))) then attribute pwd { 'required' } else ()}
        <file>{$archive}</file>
        <path>{$dir}</path>
      </confirm>
    else 
      if (true()) then (: FIXME: check filename is a zip :)
        local:restore-collection($dir, $archive)
      else
        <system:restore>
          <error>Wrong archive file format</error>
        </system:restore>
  else
    (: default view : list archive files and collections :)
    <data>
      { 
      if (not(file:is-directory($dir))) then attribute error { 'path-not-found' } else (),
      file:directory-list($dir, '*.zip'), 
      local:collection-list()
      }
    </data>
      
      
    

 