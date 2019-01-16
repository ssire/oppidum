xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum framework installation helpers

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Utility functions to copy Oppidum framework and applications to the
   database for pre-production and production. Some parts of this file
   inspired from eXist 1.4.1's admin/install.xqm module

   TODO:
   - implement install:fix-template-import to implement xt:include XTiger
     element as a post-deplopyment operation (see also filter-template.xsl)

   February 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace install = "http://oppidoc.com/oppidum/install";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace transform = "http://exist-db.org/xquery/transform";

import module namespace compat = "http://oppidoc.com/oppidum/compatibility" at "compat.xqm";

(: ======================================================================
   Resolves xsl:include statements in a source XSLT file stored in the database by inserting
   all the xsl:template rules from the included fragment into the source file. The included
   fragment must also be in the database.

   This is necessary because under Tomcat xsl:include in XSLT files does not seem to work.
   Previous versions of our fix only turned relative URLs in xsl:import statement into absolute URLs
   starting with xmldb:exist because relative URLs' didn't seem to work (at least with eXist 1.4.1)
   when hosting the application in the database.

   Param base-col-uri is the root of the collection from where the xs:include relative path starts

   Limitation: currently filter-transfo.xsl correctly expand only '../{folder}[{sub-folders}]/file.xsl'
   types of xsl:include

   Note: it MUST called after oppidum has been installed itself to /db/www/oppidum
  ======================================================================
:)
declare function install:fix-xsl-import( $col-uri as xs:string, $name as xs:string, $base-col-uri as xs:string ) {
  let
    $data := fn:doc(concat($col-uri, '/', $name)),
    $params := <parameters>
                 <param name="oppidum.base" value="{$base-col-uri}{if (not(ends-with($base-col-uri, '/'))) then '/' else ''}"/>
                 <param name="script.base" value="{$col-uri}{if (not(ends-with($col-uri, '/'))) then '/' else ''}"/>
                 <param name="exist:stop-on-warn" value="yes"/>
                 <param name="exist:stop-on-error" value="yes"/>
               </parameters>
  return
    if (doc-available('/db/www/oppidum/scripts/filter-transfo.xsl')) then
      let $filtered := transform:transform($data, 'xmldb:exist:///db/www/oppidum/scripts/filter-transfo.xsl', $params)
      let $res := xdb:store($col-uri, $name, $filtered)
      return
        <li>Fixed xsl:include in xslt file: {$res}</li>
    else
      <li style="color: red">Cannot fix xsl:include in xslt file: {$name} install Oppidum First !</li>
};

(: ======================================================================
   Returns path to application module code from EXIST-HOME/webapp
   (e.g. /projects/oppidum, /projects/oppidum, etc)
   Looks inside application module settings.xml file first (works in all situations)
   fallbacks to get-uri (works only if no proxy path URL rewrite)
   ====================================================================== 
:)
declare function install:get-project-path-for( $name as xs:string ) as xs:string {
  let $project := fn:doc(concat('/db/www/', $name, '/config/settings.xml'))/Settings/ProjectFolderName
  return
    if ($project ne '') then
      concat('/', $project, '/', $name)
    else  
      let $sub := tokenize(request:get-uri(), '/')[3]
      return
        concat('/', $sub, '/', $name)
};

(: ======================================================================
   This function MUST return the absolute path to the main folder
   containing the library or application to install
   FIXME: simplifier, à priori pas de raison de l'exécuter depuis tomcat (WEBINF)
   ======================================================================
:)
declare function install:webapp-home( $localPath as xs:string ) {
    let
      $home := system:get-exist-home(),
      $pathSep := util:system-property("file.separator"),
      $base := if (starts-with($localPath, '/')) then $localPath else concat('/', $localPath)
    return
      if (doc-available(concat($home, "/webapp", $base, "/controller.xql"))) then (: "file:///" error :)
        concat($home, $pathSep, "webapp", $base)
      else if (ends-with($home, "WEB-INF")) then
        concat(substring-before($home, "WEB-INF"), $pathSep, $base)
      else
        concat($home, $pathSep, "webapp", $base)
};

declare function install:create-collection($parent as xs:string, $collection as xs:string)
{
  if (xdb:collection-available(concat($parent, '/', $collection))) then
    <li>Collection {concat($parent, '/', $collection)} already exists, skip creation</li>
  else
    let $r := xdb:create-collection($parent, $collection)
    return
        <li>Created collection <span class="success">{$r}</span></li>
};

(: ======================================================================
   Converts a permission string like "rwur--r--" into an integer compatible
   with set-collection-permissions and set-resource-permissions
   ======================================================================
:)
declare function install:perms( $p as xs:string) as xs:integer
{
  util:base-to-integer(
    sum(
    for $i at $j in (1, 4, 7)
    let $ruw := substring($p, $i, 3)
    let $bits := (
     if (contains($ruw, 'r')) then 4 else 0,
     if (contains($ruw, 'w')) then 2 else 0,
     if (contains($ruw, 'u')) then 1 else 0
    )
    return sum($bits) * number(concat("10E", 3 - $j - 1))
  ), 8)
};

(: ======================================================================
   DEPRECATED [will be removed]
   Sets same permissions on the collection, its child resources 
   and all its descendants.
   ======================================================================
:)
declare function install:apply-permissions-to($col-uri as xs:string, $user-id as xs:string, $group-id as xs:string, $perms as xs:string)
{
  compat:set-owner-group-permissions($col-uri, $user-id, $group-id, $perms),
  for $c in xdb:get-child-resources($col-uri)
  return
    compat:set-owner-group-permissions(concat($col-uri, '/', $c), $user-id, $group-id, $perms),
  for $c in xdb:get-child-collections($col-uri)
  return
    install:apply-permissions-to(concat($col-uri, '/', $c), $user-id, $group-id, $perms)
};

(: ======================================================================
   DEPRECATED [may be removed]
   Sets permission on the collection and all its descendants (> eXist-2)
   as per an @inherit policy (collection, resource, both~yes)
   Pre-condition: inherit either on collection, resource or both !
   ======================================================================
:)
declare function install:apply-permissions-iter($col-uri as xs:string, $user-id as xs:string, $group-id as xs:string, $perms as xs:string, $inherit as xs:string?)
{
  if ($inherit = ('collection', 'both', 'yes')) then (: applies to self collection :)
    compat:set-owner-group-permissions($col-uri, $user-id, $group-id, $perms)
  else
    (),
  if ($inherit = ('resource', 'both', 'yes')) then (: applies to child resources :)
    for $c in xdb:get-child-resources($col-uri)
    return
      compat:set-owner-group-permissions(concat($col-uri, '/', $c), $user-id, $group-id, $perms)
  else
    (),
  for $c in xdb:get-child-collections($col-uri) (: applies to descendants :)
  return
    install:apply-permissions-iter(concat($col-uri, '/', $c), $user-id, $group-id, $perms, $inherit)
};

declare function install:store-files($collection as xs:string, $home as xs:string, $patterns as xs:string, $mimeType as xs:string?) as element()*
{
    let $stored :=
      if ($mimeType) then
        xdb:store-files-from-pattern($collection, $home, $patterns, $mimeType)
      else
        xdb:store-files-from-pattern($collection, $home, $patterns)
    return
      if (count($stored) > 0) then
        for $doc in $stored return
            <li>Uploaded: <span class="success">{$doc}</span></li>
      else
        <li style="color: red">No file uploaded from {$home} into {$collection} with pattern {$patterns}, please check your settings</li>

};

declare function install:store-files($collection as xs:string, $home as xs:string, $patterns as xs:string, $mimeType as xs:string, $preserve as xs:boolean) as element()*
{
    let $stored :=  xdb:store-files-from-pattern($collection, $home, $patterns, $mimeType, $preserve)
    return
      if (count($stored) > 0) then
        for $doc in $stored return
          <li>Uploaded: <span class="success">{$doc}</span></li>
      else
        <li>No file uploaded from {$home} into {$collection} with pattern {$patterns}, please check your settings</li>
};

declare function install:mime-for-suffix($suffix as xs:string) as xs:string
{
  if ($suffix = "html") then "text/html"
  else if ($suffix = ("xml", "xhtml")) then "text/xml"
  else if ($suffix = "xsl") then "application/xslt+xml"
  else if ($suffix = ("xql", "xqm")) then "application/xquery"
  else if ($suffix = "css") then "text/css"
  else if ($suffix = "js") then "application/x-javascript"
  else if ($suffix = ("png", "gif", "jpeg")) then concat("image/", $suffix)
  else if ($suffix = "jpg") then "image/jpeg"
  else if ($suffix = ("otf", "ttf")) then "application/octet-stream"
  else if ($suffix = "odf") then "application/pdf"
  else "application/octet-stream"
};

declare function install:install-file($home as xs:string, $col as xs:string, $file as element()) as element()*
{
  let $pattern := if (contains($file/@pattern, ":")) then
                    substring-after($file/@pattern, ':')
                  else string($file/@pattern)
  let $srcdir := if (contains($file/@pattern, ":")) then
                   replace($home, "/[^/]*$", concat("/", substring-before($file/@pattern, ':')))
                 else $home
  let $preserve := if (string($file/@preserve) = 'true') then true() else false()
  let $type := if ($file/@type) then string($file/@type) else install:mime-for-suffix(substring-after($pattern, '.'))
  return (
    <li>Attempt to upload file(s) "{$pattern}" inside {$col} from {$srcdir} with type {$type} {if ($preserve) then ' (preserve)' else ()}</li>,
    if ($preserve) then
      install:store-files($col, $srcdir, $pattern, $type, true())
    else
      install:store-files($col, $srcdir, $pattern, $type)
    )
};

declare function install:install-collection($home as xs:string, $col as element(), $module as xs:string?) as element()*
{
  let $col-name := if ($module) then replace($col/@name, $module, "/db/www/root") else string($col/@name)
  return (
    let $tokens := tokenize($col-name, '/')[. != '']
    for $i in 2 to count($tokens)
    let $cur := concat('/', string-join($tokens[position() <= $i], '/'))
    where ($i = count($tokens)) or not(xdb:collection-available($cur))
    return
      install:create-collection(concat("/", string-join($tokens[position() <= ($i - 1)], '/')), $tokens[$i]),
    for $f in $col/install:files
    return
      install:install-file($home, $col-name, $f)
    )
};

declare function install:install-group(
  $home as xs:string,
  $group as element(),
  $module as xs:string?) as element()*
{
  let $name := string($group/@name)
  return (
    <p>{$name} :</p>,
    <ul>{
      for $c in $group/install:collection
      return
        install:install-collection($home, $c, $module),
      for $f in $group/install:fix-xsl-import
      return
        if ($module) then
          let $col-uri := replace($f/@collection, $module, "/db/www/root")
          let $base-col-uri := replace($f/@base, $module, "/db/www/root")
          return
            install:fix-xsl-import($col-uri, $f/@file, $base-col-uri)
        else
          install:fix-xsl-import($f/@collection, $f/@file, $f/@base)
    }</ul>
  )
};

(: ======================================================================
   When $module is defined it contains the path of the home database
   collection that contains the application and that will be rewritten
   to /db/www/root for a universal WAR compatible installation
   ======================================================================
:)
declare function install:install-targets(
  $dir as xs:string,
  $targets as xs:string*,
  $specs as element(),
  $module as xs:string?) as element()*
{
  let $default := if (('default' = $targets) and ($specs/install:collection)) then
                    <group name="default">{$specs/install:collection}</group>
                  else ()
  return
    for $g in ( $default, $specs/install:group[@name = $targets] )
    return install:install-group($dir, $g, $module)
};

(: DEPRECATED [may be removed] :)
declare function install:install-user($user as element())
{
  let $groups := if (string($user/@groups) != '') then tokenize(string($user/@groups), ' ') else ()
  let $home := if (string($user/@home) != '') then string($user/@home) else ()
  return
    if (xdb:exists-user($user/@name)) then
      (
        xdb:change-user($user/@name, $user/@password, $groups, $home),
        <li>Updated existing user “{string($user/@name)}” with group “{string($user/@groups)}” and {if ($home) then concat("“", $home, "”") else "no home"}</li>
      )
    else
      (
        xdb:create-user($user/@name, $user/@password, $groups, $home),
        <li>Created user “{string($user/@name)}” with group “{string($user/@groups)}” and {if ($home) then "“{$home}”" else "no home"}</li>
      )
};

declare function install:install-users($policies as element()) as element()
{
  <ul>
    {
    for $u in $policies/install:user
    return
      install:install-user($u)
    }
  </ul>
};

(: ======================================================================
   Set permissions on the collection itself then iterate on its 
   descendants as per the $inherit scope
   ======================================================================
:)
declare function local:collection-permissions-iter($col-uri as xs:string, $user-id as xs:string, $group-id as xs:string, $perms as xs:string, $inherit as xs:string?)
{
  if (xdb:collection-available($col-uri)) then (
    compat:set-owner-group-permissions($col-uri, $user-id, $group-id, $perms),
    if ($inherit = ('collection', 'both', 'yes')) then
      for $c in xdb:get-child-collections($col-uri)
      return
        local:collection-permissions-iter(concat($col-uri, '/', $c), $user-id, $group-id, $perms, $inherit)
    else
      ()
    )
  else
    <li style="color:red">Failed to apply collection policies on “{$col-uri}” because it does not exists</li>
};

(: ======================================================================
   Set permissions on the direct resources inside the collection itself 
   then iterate on its descendants as per the $inherit scope
   ======================================================================
:)
declare function local:resource-permissions-iter($col-uri as xs:string, $user-id as xs:string, $group-id as xs:string, $perms as xs:string, $inherit as xs:string?)
{
  if (xdb:collection-available($col-uri)) then (
    for $c in xdb:get-child-resources($col-uri)
    return
      compat:set-owner-group-permissions(concat($col-uri, '/', $c), $user-id, $group-id, $perms),
    if ($inherit = ('resource', 'both', 'yes')) then
      for $c in xdb:get-child-collections($col-uri)
      return
        local:resource-permissions-iter(concat($col-uri, '/', $c), $user-id, $group-id, $perms, $inherit)
    else
      ()
    )
  else
    <li style="color:red">Failed to apply resource policies on “{$col-uri}” because it does not exists</li>
};

(: ======================================================================
   Implement @collection-policy, @resource-policy and 
   @inherit="collection | resource | both | yes | no" on host element.
   "yes" is DEPRECATED use "both" instead.
   ====================================================================== 
:)
declare function install:install-policy($host as element(), $policies as element()) {
  if (local-name($host) eq 'collection') then
    let $col-uri := string($host/@name)
    let $scope := $host/@inherit
    return
      if (empty($scope) or not($scope = ('collection', 'resource', 'yes', 'both', 'no'))) then
        <li style="color:red">Failed to apply policies on collection “{string($col-uri)}” because mandatory inherit attribute is missing or has wrong value</li>
      else (
        (: 1. launch process with collection permissions :)
        if (exists($host/@collection-policy)) then
          let $policy := $policies/install:policy[@name = $host/@collection-policy]
          return
            if ($policy) then 
              let $perms := string($policy/@perms)
              let $owner := string($policy/@owner)
              let $group := string($policy/@group)
              let $p := install:perms($perms)
              return
                if (not(xdb:exists-user($owner))) then
                  <li style="color:red">Failed to apply policy “{string($policy/@name)}” to collection “{$col-uri}” because there is no user “{$owner}”</li>
                else (
                  <li>Set owner “{$owner}” on collection “{$col-uri}” with group “{$group}” and permissions “{$perms}”{ if ($scope = ('resource', 'both', 'yes')) then " iterate on descendants" else () }</li>,
                  local:collection-permissions-iter($col-uri, $owner, $group, $perms, $scope)
                  )
            else
              <li style="color:red">Failed to apply policy “{string($host/@collection-policy)}” to collection “{$col-uri}” because there is no such policy</li>
        else
          (),
        (: 2. launch process with resource permissions :)
        if (exists($host/@resource-policy)) then
          let $policy := $policies/install:policy[@name = $host/@resource-policy]
          return
            if ($policy) then 
              let $perms := string($policy/@perms)
              let $owner := string($policy/@owner)
              let $group := string($policy/@group)
              let $p := install:perms($perms)
              return
                if (not(xdb:exists-user($owner))) then
                  <li style="color:red">Failed to apply policy “{string($policy/@name)}” to resources of collection “{$col-uri}” because there is no user “{$owner}”</li>
                else (
                  <li>Set owner “{$owner}” on resources  “{$col-uri}” with group “{$group}” and permissions “{$perms}”{ if ($scope = ('resource', 'both', 'yes')) then " iterate on descendants" else () }</li>,
                  local:resource-permissions-iter($col-uri, $owner, $group, $perms, $scope)
                  )
            else
              <li style="color:red">Failed to apply policy “{string($host/@resource-policy)}” to resources of collection “{$col-uri}” because there is no such policy</li>
        else
          ()
        )
  else if (local-name($host) eq 'resource') then
    (: apply to explicit individual resource :)
    let $policy := $policies/install:policy[@name = $host/@resource-policy]
    return
      if (exists($policy)) then
        compat:set-owner-group-permissions($host/@name, $policy/@owner, $policy/@group, $policy/@perms)
      else
        <li style="color:red">Failed to apply policies on resource “{string($host/@name)}” because unkown policy "{local-name($host/@resource-policy)}"</li>
  else
    <li style="color:red">Failed to apply policies on “{string($host/@name)}” because unkown target type "{local-name($host)}"</li>
};

(: ======================================================================
   DEPRECATED [may be removed]
   Apply permissions to a collection element. Does not make distinction 
   between collection or resource policy for the inner resources !
   TODO: replace deprecated xdb:exists-user
   ====================================================================== 
:)
declare function install:install-policy($policy as element(), $collection as element(), $module as xs:string?)
{
  let $perms := string($policy/@perms)
  let $owner := string($policy/@owner)
  let $group := string($policy/@group)
  let $col := if ($module) then replace($collection/@name, $module, "/db/www/root") else string($collection/@name)
  let $p := install:perms($perms)
  return
    if (not(xdb:exists-user($owner))) then
      <li style="color:red">Failed to apply policy “{string($policy/@name)}” to collection “{$col}” because there is no user “{$owner}”</li>
    else
      if ($collection/@inherit= ('collection', 'resource', 'both', 'yes')) then (
        install:apply-permissions-iter($col, $owner, $group, $perms, $collection/@inherit),
        <li>Set owner “{$owner}” on collection “{$col}” with group “{$group}” and permissions “{$perms}” and its content, iterates on {string($collection/@inherit)}</li>
        )
      else (
        compat:set-owner-group-permissions($col, $owner, $group, $perms),
        <li>Set owner “{$owner}” on collection “{$col}” with group “{$group}” and permissions “{$perms}”</li>
        )
};

(: DEPRECATED [may be removed] :)
declare function install:install-policies(
  $targets as xs:string*,
  $policies as element(),
  $specs as element(),
  $module as xs:string?) as element()*
{
  <p>Set permissions :</p>,
  <ul>
    {
    for $c in ($specs/install:collection[@policy] | $specs/install:group[@name = $targets]/install:collection[@policy])
    let $p := $policies/install:policy[@name = $c/@policy]
    return
      if ($p) then
        install:install-policy($p, $c, $module)
      else
        <li style="color: red">Cannot apply unkown policy “{string($c/@policy)}” onto collection “{string($c/@name)}”</li>
    }
  </ul>
};

(: DEPRECATED [will be removed, exist-1 only] :)
declare function install:_login_form() as element()
{
  <div style="width: 400px">
    <p>You MUST login first as <b>admin</b> user using the application you plan to install :</p>
    <form action="login?url=install" method="post" style="margin: 0 auto 0 2em; width: 20em;">
      <p style="text-align: right">
        <label for="login-user">User name</label>
        <input id="login-user" type="text" name="user" value="admin"/>
      </p>
      <p style="text-align: right">
        <label for="login-passwd">Password</label>
        <input id="login-passwd" type="password" name="password"/>
      </p>
      <p style="text-align: right; margin-right: 30px">
        <input type="submit"/>
      </p>
    </form>
  </div>
};

(: DEPRECATED [will be removed, exist-1 only] :)
declare function install:gen-form-for-bundle( $bundle as element() ) as element()
{
  <p>
    <b>{string($bundle/@name)}</b> :
    {
    for $g in $bundle/install:group
    let $n := string($g/@name)
    return
      <span>
        { if ($g/@mandatory) then attribute style { 'color: green '} else () }
        <input id="{$n}" type="checkbox" value="{$n}" name="{$bundle/@name}-target">
          { if ($g/@mandatory) then attribute checked { 'true'} else () }
        </input>
        <label for="{$n}">{$n}</label>
      </span>
    }
  </p>
};

(: DEPRECATED [will be removed, exist-1 only] :)
declare function install:gen-forms-for-bundles( $bundles as element()*, $hasCtrl as xs:boolean  ) as element()
{
  let $user :=  xdb:get-current-user()
  return
    <div>
      <p>Select the files to copy to the database below;
         <span style="color:green">green</span> ones are mandatory even when running the application from the file system (dev mode).
      </p>
      <form method="post" action="install">
        <input type="hidden" name="go" value="yes"/>
        {
          for $b in $bundles return install:gen-form-for-bundle($b)
        }
        {
          if ($hasCtrl) then
            <p><b>Root</b> :
              <input type="checkbox" value="true" name="root-controller"/>
              <label>controller</label>
              <br/><span style="font-size: smaller; font-style:italic">Check this flag if you want to set the <tt>controller.xql</tt> of this application as the main controller (i.e. copy it to the <tt>/db/www/root</tt> collection)</span>
            </p>
          else
            ()
        }
        <p>You are logged in as <b>{$user}</b></p>
        {
        if ($user = 'admin') then (
          <p>Click on the install button to proceed</p>,
          <p style="margin-left: 10%"><input type="submit" value="Install"/></p>
          )
        else ()
        }
      </form>
      <hr/>
      <p>NOTE : once you have installed the application to the database, if it declares the Oppidum <em>admin</em> module in its controller,
      you can use the admin panel to archive the application to one or more ZIP files which can be used to deploy or to upgrade it on other servers.
      Alternatively you can use the eXist administration client. To bootstrap an application from an empty universal Oppidum WAR file,
      you only need to install first the Oppidum ZIP archive using the eXist administration client, then you can use the embedded <em>admin</em> module
      to update the database.</p>
      {
        if ($user != 'admin') then install:_login_form() else ()
      }
    </div>
};

(: DEPRECATED [may be removed, exist-1 only] :)
declare function install:do-install-bundle(
  $base as xs:string,
  $policies as element(),
  $bundle as element(),
  $title as xs:string
) as element()*
{
  let $dir := install:webapp-home($base)
  let $targets := request:get-parameter(concat($bundle/@name, "-target"), ())
  return (
    <h2>Installation report for Users</h2>,
    install:install-users($policies),
    <h2>Installation report for {string($bundle/@name)}</h2>,
    if (count($targets) > 0) then (
      install:install-targets($dir, $targets, $bundle, ()),
      install:install-policies($targets, $policies, $bundle, ())
      )
    else
      <ul>
        <li>Nothing to install because no targets were selected</li>
      </ul>
    )
};


(: DEPRECATED [will be removed, exist-1 only] :)
declare function install:install-bundle(
  $base as xs:string,
  $policies as element(),
  $bundle as element(),
  $title as xs:string
)
{
  <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
      <title>{$title} DB installation</title>
      {
        element style {
          attribute type { "text/css" },
          ".success { color: green }"
        }
      }
    </head>
    <body style="margin: 2em 2em">
      <h1>{$title} DB installation</h1>
      <div>
        {
        if (request:get-parameter("go", ())) then (: could as well test for method 'POST' :)
          <div class="report">
            {
            install:do-install-bundle($base, $policies, $bundle, $title)
            }
            <p>Goto : <a href="install">installation</a> | <a href=".">home</a>  | <a href="../oppidum/devtools">devtools</a></p>
          </div>
        else
          install:gen-forms-for-bundles(($bundle), false())
        }
      </div>
    </body>
  </html>
};

(: ======================================================================
   DEPRECATED [will be removed, exist-1 only]
   Generates an HTML page to handle site installation to the database
   Proceed with installation in case of a submission
   ======================================================================
:)
declare function install:install(
  $base as xs:string,
  $policies as element(),
  $data as element()?,
  $code as element()?,
  $static as element()?,
  $title as xs:string,
  $module as xs:string?) as element()
{
  let $install := request:get-parameter("go", ())
  let $user :=  xdb:get-current-user()
  (:$login := xdb:login('/db', $login, $passwd):)
  return
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        <title>{$title} DB installation script</title>
        {
          element style {
            attribute type { "text/css" },
            ".success { color: green }"
          }
        }
      </head>
      <body style="margin: 2em 2em">
        <h1>{$title} DB installation</h1>
        <div>
          {
          if ($install) then
            <div class="report">
              {
                let $dir := install:webapp-home($base)
                let $data-targets := request:get-parameter("data-target", ())
                let $code-targets:= request:get-parameter("code-target", ())
                let $static-targets:= request:get-parameter("static-target", ())
                return (
                  <h2>Installation report for Users</h2>,
                  install:install-users($policies),
                  <h2>Installation report for Data</h2>,
                  if (count($data-targets) > 0) then (
                    install:install-targets($dir, $data-targets, $data, ()),
                    install:install-policies($data-targets, $policies, $data, ())
                    )
                  else (),
                  <h2>Installation report for Code</h2>,
                  if (count($code-targets) > 0) then
                    let $m := if (request:get-parameter("code-location", "module") = "root") then $module else ()
                    return
                      (
                      install:install-targets($dir, $code-targets, $code, $m),
                      install:install-policies($code-targets, $policies, $code, $m)
                      )
                  else (),
                  <h2>Installation report for Static resources</h2>,
                  if (count($static-targets) > 0) then
                    (
                    install:install-targets($dir, $static-targets, $static, ()),
                    install:install-policies($static-targets, $policies, $static, ())
                    )
                  else ()
                  )
              }
              <p>Goto : <a href="install">installation</a> | <a href=".">home</a> | <a href="../oppidum/devtools">devtools</a></p>
            </div>
          else (
            <p>Select the files to copy to the database below; <span
            style="color:green">green</span> ones are mandatory even when
            running the application from the file system (dev mode).
            By convention the <em>default</em> targets usually create required empty collections.</p>,
            <form method="post" action="install">
              <input type="hidden" name="go" value="yes"/>
              <p><b>Data</b> :
                <input id="data-default" type="checkbox" value="default" name="data-target"/>
                <label for="data-default">default</label>
                {
                for $g at $i in $data/install:group
                let $n := string($g/@name)
                return
                  <span>
                    { if ($g/@mandatory) then attribute style { 'color: green '} else () }
                    <input id="{$n}" type="checkbox" value="{$n}" name="data-target">
                      { if ($g/@mandatory) then attribute checked { 'true'} else () }
                    </input>
                    <label for="{$n}">{$n}</label>
                  </span>
                }
              </p>
              <p><b>Code</b> :
                <input id="code-default" type="checkbox" value="default" name="code-target"/>
                <label for="code-default">default</label>
                {
                for $g in $code/install:group
                let $n := string($g/@name)
                return
                  <span>
                    { if ($g/@mandatory) then attribute style { 'color: green '} else () }
                    <input id="{$n}" type="checkbox" value="{$n}" name="code-target">
                      { if ($g/@mandatory) then attribute checked { 'true'} else () }
                    </input>
                    <label for="{$n}">{$n}</label>
                  </span>
                }
                {
                  if ($module) then
                    <span>
                      [<span style="color:blue">installation type</span> :
                      <input id="universal" type="radio" value="root" name="code-location" checked="true"/>
                      <label for="universal">root (universal)</label>
                      <input id="module" type="radio" value="module" name="code-location"/>
                      <label for="module">module</label>]
                    </span>
                  else ()
                }
              </p>
              <fieldset>
                <legend>Unlikely / Deprecated</legend>
                <p><b>Static resources</b> :
                  {
                  for $g in $static/install:group
                  let $n := string($g/@name)
                  return (
                    <input id="{$n}" type="checkbox" value="{$n}" name="static-target"/>,
                    <label for="{$n}">{$n}</label>
                    )
                  }
                  <br/><span style="font-size: smaller; font-style:italic">In
                  test or production we strongly advise you to setup a proxy
                  (e.g. NGINX) to directly serve static resources so you do not
                  need to load them inside the database</span>
                </p>
                <p><b>Root</b> :
                  <input type="checkbox" value="true" name="root-controller"/>
                  <label>controller</label>
                  <br/><span style="font-size: smaller; font-style:italic">Check this flag if you want to set the <tt>controller.xql</tt> of this application as the main controller (i.e. copy it to the <tt>/db/www/root</tt> collection)</span>
                </p>
              </fieldset>
              <p>You are logged in as <b>{$user}</b></p>
              {
              if ($user = 'admin') then (
                <p>Click on the install button to proceed</p>,
                <p style="margin-left: 10%"><input type="submit" value="Install"/></p>
                )
              else ()
              }
            </form>,
            <hr/>,
            <p>NOTE : once you have installed the application to the database,
            if it declares the Oppidum <em>admin</em> module in its controller,
            you can use the admin panel to archive the application to one or more
            ZIP files which can be used to deploy or to upgrade it on other servers.
            Alternatively you can use the eXist administration client.
            To bootstrap an application from an empty
            universal Oppidum WAR file, you only need to install first the
            Oppidum ZIP archive using the eXist administration client, then you
            can use the embedded <em>admin</em> module to update the databse.
            </p>
            ,
            if ($user != 'admin') then install:_login_form() else ()
            )
          }
        </div>
      </body>
    </html>
};
