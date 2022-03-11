xquery version "1.0";  
(: -----------------------------------------------
   Oppidum framework pipeline generator facade

   Facade to speed up oppidum in heavy loaded applications.
   Minimizes calls to oppidum:get-user-groups. Stores user
   groups inside the request command. Caches user groups
   inside a 'cas-groups' session attribute when there is 
   a session. Removes oppidum.rights / xslt.rights 
   request attribute.

   Removed multilingual path rewriting support for speed.

   Author: Stéphane Sire <s.sire@oppidoc.fr>

   November 2021 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

module namespace exec = "http://oppidoc.com/oppidum/executor";

declare namespace exist = "http://exist.sourceforge.net/NS/exist";

import module namespace gen = "http://oppidoc.com/oppidum/generator" at "pipeline.xqm";
import module namespace response="http://exist-db.org/xquery/response";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "util.xqm";   
import module namespace command = "http://oppidoc.com/oppidum/command" at "command.xqm";

declare function local:my-session-set-attribute( $key as xs:string, $value as element()? ) as element()? {
  let $done := request:set-attribute($key, $value)
  return $value
};

declare function local:get-user-groups( $confbase as xs:string, $key as xs:string, $realm as xs:string? ) as xs:string* {
  if ($realm) then (: remote authenticated Realm :)
    let $model := fn:doc(concat($confbase, '/config/security.xml'))//Realm[@Name eq $realm]
    let $exists := $model//Variable[Name eq 'Exists']/Expression
    let $solver:= $model//Variable[Name eq 'Groups']/Expression
    return
      if (exists($exists)) then (: group allocation enabled :)
        if (util:eval($exists) and exists($solver)) then
          fn:distinct-values(
            (sm:get-user-groups($model/Surrogate/User), (: TODO: check user exists :)
            util:eval($solver))
          )
        else
          let $fallback := $model//Variable[Name eq 'Guest']/Expression
          return
            if (exists($fallback)) then
              util:eval($fallback)
            else
              ()
      else
        ()
  else (: fallback internal Realm :)
    sm:get-user-groups($key)
};

declare function local:get-current-user-groups( $confbase as xs:string ) as xs:string* {
  if (session:exists()) then
    let $groups := session:get-attribute('cas-groups')
    return
      if (exists($groups)) then
        $groups
      else
        let $remote := session:get-attribute('cas-user')
        return
          if (exists($remote) and exists($remote/key) and exists($remote/@name)) then
            let $groups := local:get-user-groups($confbase, $remote/key, $remote/@name)
            return (
              if (exists($groups))
                then session:set-attribute('cas-groups', $groups)
                else (),
              $groups
              )
          else
            sm:get-user-groups(sm:id()//sm:real/sm:username/string()) (: or 'guest' ? :)
  else
    sm:get-user-groups(sm:id()//sm:real/sm:username/string()) (: or 'guest' ? :)
};

declare function local:my-test-role-iter( $index as xs:integer, $roles as xs:string*, $cmd as element() ) as xs:boolean
{
  if ($index > count($roles)) then
    false()
  else
    let
      $role := $roles[$index],
      $res :=
        if ($role = 'all') then
          true()
        else if (starts-with($role, 'u:')) then
          oppidum:check-user(substring-after($role, 'u:'))
        else if (starts-with($role, 'g:')) then
          $cmd/groups/group = substring-after($role, 'g:')
        else if ('owner' = $role) then
          oppidum:check-owner($cmd)
        else
          false()
    return
     if ($res) then $res else local:my-test-role-iter($index + 1, $roles, $cmd)
};

(: ======================================================================
   Tests an access rule against the current user and the command.
   Implements @role on role element
   Returns true if the user is granted access and false otherwise.
   ======================================================================
:)
declare function local:test-rule-for-command( $role as element(),  $cmd as element() ) as xs:boolean
{
  let $allow := tokenize($role/@role, ' ')
  return 
    local:my-test-role-iter(1, $allow, $cmd)
};

(: ======================================================================
   Checks if the current user is allowed to execute the action in the command.
   Returns true or false. In the later case, it also registers an
   UNAUTHORIZED-ACCESS in Oppidum error flash.
   ======================================================================
:)
declare function local:check-rights-for( $cmd as element(), $defaults as element()* ) as xs:boolean
{
  let $target := $cmd/resource
  let $rules := if ($target/access) then $target/access else $defaults
  return
    let $rule := $rules/rule[$cmd/@action = tokenize(@action, ' ')]
    return
      if ($rule) then
        oppidum:my-access-control(local:test-rule-for-command($rule, $cmd), $rule)
      else
        true()
};

(: ========================================================================
   Main entry point of the request parser.
   Pre-condition: space in $url has been normalized and minimal url is '/'
   ========================================================================
:)
declare function local:parse-url(
  $base-url as xs:string,
  $exist-root as xs:string,
  $exist-path as xs:string,
  $url as xs:string,
  $method as xs:string,
  $mapping as element(),
  $lang as xs:string,
  $def-lang as xs:string? ) as element()
{
  let $extension := if (contains($url, '.')) then replace ($url,concat('^.*','\.'),'') else ''
  let $raw-payload := if ($extension != '') then replace($url, concat('^(.*)', '\.','.*'), '$1') else $url
  let $payload := if ($raw-payload = '/') then $mapping/@startref else $raw-payload (: although we SHOULD have redirected before reaching that line :)
  let $tokens := tokenize($payload, '/')[. != '']
  let $format := if ($extension) then $extension else request:get-parameter('format', '')
  return
    <command>
      {
      attribute base-url {
        if ($mapping/@languages) then (: build a multilingual base URL including language code if not default :)
          if ($def-lang and ($lang = $def-lang)) then
            $base-url
          else 
            concat($base-url, $lang, '/')
        else
          $base-url
      },
      attribute app-root { $exist-root },
      attribute exist-path { $exist-path },
      attribute lang { $lang },
      attribute db { $mapping/@db },
      if ($def-lang) then attribute def-lang { $def-lang } else (),
      $mapping/@confbase,
      $mapping/@mode,
      if ($mapping/error/@mesh) then attribute error-mesh { $mapping/error/@mesh } else (),
      if ($format) then attribute format { $format } else (),
      command:parse-token-iter($method, 1, $tokens, $mapping,
        $mapping/@db, $mapping/@resource, $mapping/@collection, $mapping/@confbase, $lang)
      }
      <groups>
        { local:get-current-user-groups($mapping/@confbase) ! <group>{ . }</group> }
      </groups>
    </command>
};

(: ======================================================================
   Main Oppidum entry point
   ------------------------
   Parses the URL and returns the generated executable pipeline for eXist
   The URL is passed through eXist root, prefix, controller and path variables
   ======================================================================
:)
declare function exec:process(
  $root as xs:string, $prefix as xs:string, $controller as xs:string, $exist-path as xs:string, 
  $lang as xs:string, $debug as xs:boolean,
  $access as element(), $actions as element(), $mapping as element()) as element()
{
  (: second pass pass-through for file: model src protocol since eXist 2 :)
  if (session:get-attribute('oppidum.ignore') eq true()) then (
    session:set-attribute('oppidum.ignore', ()),
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
      <cache-control cache="no"/>
    </ignore>   
    )
  else   
    let $base-url := if ($mapping/@base-url) then
                       string($mapping/@base-url)
                     else 
                       concat(request:get-context-path(), $prefix, $controller, '/')
    let $app-root := if (not($controller)) then concat($root, '/') else concat($controller, '/')
    let $def-lang := $lang (: removed multilingual support - see gen:process in pipeline.xqm :)
    let $path := $exist-path (: removed multilingual support :)
    return
      (: Web site root redirection :)
      if ($path = ('', '/')) then
        let $xtra := if ($mapping/@languages) then 
                       if ($def-lang = $lang) then () else concat($lang,'/')
                     else 
                       ()
        return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
          <redirect url="{$base-url}{$xtra}{$mapping/@startref}"/>
          <cache-control cache="no"/>
        </dispatch>

      (: Note: in production the proxy should serve static/* directly :)
      else if (starts-with($path, "/static/")) then
        (: as an alternative we could set WEB-INF/controller-config.xml to rewrite /static :)
         <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{gen:path-to-static-resource($app-root, $path, $path, string($mapping/@key))}"/>
            <cache-control cache="yes"/>
         </dispatch>

      (: required for exist 2.x to serve static resources in second pass :)
      else if (starts-with($path, "/resources/")) then
        <ignore xmlns="http://exist.sourceforge.net/NS/exist">
          <cache-control cache="no"/>
        </ignore>

      else
        (: si on utilise pas le prefix remapping alors passer $exist:controller, $exist:controller
           si on l'utilise passer $exist:root, $exist:prefix  :)
        let 
          $cmd := local:my-session-set-attribute('oppidum.command',
                    local:parse-url($base-url, $app-root, $exist-path, $path,
                      request:get-method(), $mapping, $lang, $def-lang)
                  ),
          $default := command:get-default-action($cmd, $actions),
          $rights := 'deprecated', (:oppidum:get-rights-for($cmd, $access),:)
          $granted := local:check-rights-for($cmd, $access),
          $pipeline := gen:pipeline($cmd, $default, string($mapping/@key), $rights, $granted)
        return
          ( 
          if (not($pipeline/@selfie)) then
            (: sets oppidum "environment" variables for the pipeline scripts :)
            let $raw-ppl := request:get-attribute('oppidum.pipeline')
            return
              (
              request:set-attribute('oppidum.base-url', $base-url),
              request:set-attribute('oppidum.rights', $rights),
              request:set-attribute('oppidum.granted', $granted),
              request:set-attribute('oppidum.mesh', if ($raw-ppl/epilogue/@mesh) then string($raw-ppl/epilogue/@mesh) else ())
              )
          else (: first pass pass-through for file:///:self model src protocol :)
            (),
          (: debug :)
          if ($debug and (($cmd/@format = 'debug') or (request:get-parameter('debug', '') = 'true'))) then
            let 
              $dbg1 := request:set-attribute('oppidum.debug.implementation', $pipeline),
              $dbg2 := request:set-attribute('oppidum.debug.default', $default)
            return (
              (: only available to limited groups :)
              if ($cmd/groups/group = ('admin', 'admin-system', 'developer'))
                then request:set-attribute('oppidum.view-groups', true())
                else (),
              gen:debug-command($cmd)
              )
          else
            $pipeline
          )
};
