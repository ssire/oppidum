xquery version "1.0";
(: -----------------------------------------------
   Oppidum framework utilities

   Debug, Error, Message, Access rights, ...

	 Author: Stéphane Sire <s.sire@free.fr>

   November 2011 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

module namespace oppidum = "http://oppidoc.com/oppidum/util";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace response="http://exist-db.org/xquery/response";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

declare variable $oppidum:DEFAULT_ERR_LOC := '/db/www/oppidum/config/errors.xml';

declare function oppidum:get-command () as element()
{
  request:get-attribute('oppidum.command')
};

declare function oppidum:path-to-ref () as xs:string
{
  let $r := request:get-attribute('oppidum.command')/resource
  return string-join(($r/@db, $r/@collection, $r/@resource), '/')
};

declare function oppidum:path-to-ref-col () as xs:string
{
  let $r := request:get-attribute('oppidum.command')/resource
  return concat($r/@db, '/', $r/@collection)
};

declare function oppidum:path-to-config ( $fn as xs:string? ) as xs:string
{
  let $cb := request:get-attribute('oppidum.command')/@confbase
  return if ($fn) then concat($cb, '/config/', $fn) else concat($cb, '/config')
};

(: ======================================================================
   Returns the resource element from the command
   FIXME: this is a trick for epilogue scripts which often declare
   an XHTML default namespace and thus cannot address $cmd/resource
   axis because the command has no namespace !
   ======================================================================
:)
declare function oppidum:get-resource ( $cmd as element() ) as element()?
{
  $cmd/resource
};

declare function oppidum:get-epilogue ( $cmd as element() ) as xs:string?
{
  if ($cmd/resource/@epilogue) then
    string($cmd/resource/@epilogue)
  else if ($cmd/resource/action) then
    string($cmd/resource/action/@epilogue)
  else (: FIXME: special case when pipeline is inherited from a default action :)
    let $pipeline := request:get-attribute('oppidum.pipeline')
    return 
      if ($pipeline/epilogue) then 
        string($pipeline/epilogue/@mesh)
      else 
        ()
};

(: ======================================================================
   Asks epilogue to redirect
   ======================================================================
:)
declare function oppidum:redirect( $url as xs:string ) as xs:string
{
  let $exec := request:set-attribute('oppidum.redirect.to', $url)
  return $url
};

(: ======================================================================
   Shortcut to dump a message to the site's log file
   ======================================================================
:)
declare function oppidum:log( $msg as xs:string ) as empty()
{
  util:log-app('debug', 'webapp.site', $msg)
};

declare function oppidum:debug( $msg as xs:string* ) as empty()
{
  util:log-app('debug', 'webapp.site', string-join($msg, ' '))
};

(: ======================================================================
   Dumps eXist variables related to the request URL to the site's log file
   ======================================================================
:)
declare function oppidum:log-parameters( $params as element() ) as empty()
{
  let $out := for $p in $params/param
              return concat($p/@name, ' = [', $p/@value, ']')
  return
    oppidum:log(string-join($out, codepoints-to-string(13)))
};

(: ======================================================================
   Asks epilogue to redirect
   ======================================================================
:)
declare function oppidum:my-add-error-or-msg(
  $from as xs:string, $type as xs:string,
  $object as xs:string*, $sticky as xs:boolean ) as empty()
{
  if ($sticky) then
    let
      $cur := session:get-attribute($from),
      $new := (for $e in $cur return $e, concat($type, ':', $object))
    return
      session:set-attribute($from, $new)
  else
    let
      $cur := request:get-attribute($from),
      $new := (for $e in $cur return $e, concat($type, ':', $object))
    return
      request:set-attribute($from, $new)
};

declare function oppidum:my-get-error-or-msg($from as xs:string) as xs:string*
{
  let
    $flash := session:get-attribute($from),
    $empty := session:set-attribute($from, ())
  return ( request:get-attribute($from), $flash)
};

declare function oppidum:add-error( $type as xs:string, $object as xs:string*, $sticky as xs:boolean ) as element()
{
  let $null := oppidum:my-add-error-or-msg('errors', $type, $object, $sticky)
  return
    <error>{
      if ($object) then attribute object { $object } else (),
      $type
    }</error>
};

declare function oppidum:has-error() as xs:boolean
{
  let $res := (count(request:get-attribute('errors')) > 0) or (count(session:get-attribute('errors')) > 0)
  return $res
};

declare function oppidum:get-errors() as xs:string*
{
  oppidum:my-get-error-or-msg('errors')
};

declare function oppidum:add-message( $type as xs:string, $object as xs:string*, $sticky as xs:boolean ) as element()
{
  let $null := oppidum:my-add-error-or-msg('flash', $type, $object, $sticky)
  return
    <success>{
      if ($object) then attribute object { $object } else (),
      $type
    }</success>
};

declare function oppidum:has-message() as xs:boolean
{
  let $res := (count(request:get-attribute('flash')) > 0) or (count(session:get-attribute('flash')) > 0)
  return $res
};

declare function oppidum:get-messages() as xs:string*
{
  oppidum:my-get-error-or-msg('flash')
};

(: ======================================================================
   Returns the full error message for an error with a given type and clue
   Uses /config/errors.xml database(s) to expand error messages
   Returns an <error code=""><message/></error> fragment
   Eventually sets the response status code if $exec is true()
   ======================================================================
:)
declare function oppidum:render-error(
  $db as xs:string,
  $err-type as xs:string,
  $err-clue as xs:string*,
  $lang as xs:string,
  $exec as xs:boolean) as element()
{
  let
    $error :=
      let
        $sitefile := concat($db, '/config/errors.xml')
      return
        if (doc-available($sitefile)
           and (not(empty(fn:doc($sitefile)/errors/error[@type = $err-type])))) then
           fn:doc($sitefile)/errors/error[@type = $err-type]
        else fn:doc($oppidum:DEFAULT_ERR_LOC)/errors/error[@type = $err-type],
    $msgs :=
      if ($error/message[@lang = $lang]) then
        $error/message[@lang = $lang]
      else
        $error/message, (: any language :)
    $msg :=
      if ($err-clue) then
        string($msgs[string(@noargs) != 'yes'][1])
      else
        string($msgs[1]),
    $message := if ($msg) then $msg else concat("Error (", $err-type, ")"),
    $arg := if ($err-clue) then $err-clue else '',
    $text := if (contains($message, "%s")) then replace($message, "%s", $arg) else $message
    (: FIXME: substituer la clue :)

  return
    <error>
      {
      if ($error/@code) then
        if ($exec) then
          response:set-status-code($error/@code)
        else
          attribute code { $error/@code }
      else (),
      <message>{$text}</message>
      }
    </error>
};

(: ======================================================================
   Returns the full error message for an error with a given type and clue
   Uses /config/errors.xml database(s) to expand error messages
   Returns an <error code=""><message/></error> fragment
   Eventually sets the response status code if $exec is true()
   ======================================================================
:)
declare function oppidum:render-message(
  $db as xs:string,
  $type as xs:string,
  $clues as xs:string*,
  $lang as xs:string) as element()
{
  let $msg-uri := concat($db, '/config/messages.xml')
  let $found := fn:doc($msg-uri)/messages/info[@type = $type] 
                (: FIXME: fallback to Oppidum default messages :)
  let $candidates := if ($found/message[@lang = $lang]) then $found/message[@lang = $lang] else $found/message
  let $preferred := if ($clues) then string($candidates[string(@noargs) != 'yes'][1]) else string($candidates[1])
  let $src := if ($preferred) then $preferred else concat("Message (", $type, ")")
  let $arg := if ($clues) then $clues else ''
  let $text := if (contains($src, "%s")) then replace($src, "%s", $arg) else $src
               (: FIXME: extend to multiple clues !!! :)
  return
    <message type="{$type}">{ $text }</message>
};

(: ======================================================================
   Introspection method that returns an integer representing the type
   of the current pipeline : 1 means model only, 2 model and view,
   and 3 model, view and epilogue
   ======================================================================
:)
declare function oppidum:get-pipeline-type( $cmd as element() ) as xs:integer
{
  let $pipeline := request:get-attribute('oppidum.pipeline')
  return
    if (string($pipeline/@redirect)) then 
      (: special case with redirection :)
      4
    else if ((string($cmd/@format) = 'xml') or not($pipeline/(view | epilogue))) then  1
    else if ((string($cmd/@format) = 'raw') or not($pipeline/epilogue)) then  2
    else 3
};

(: ======================================================================
   Throws an error during the execution of the model stage of the current
   pipeline. Depending on the type of pipeline this may lead to the immediate
   error message expansion or to its postponing for the epilogue. In the
   former case this may also lead to the setting of the response status code
   that will cause eXist to terminate the pipeline rendering.
   ======================================================================
:)
declare function oppidum:throw-error( $err-type as xs:string, $err-clue as xs:string? ) as element()
{
  let $cmd := request:get-attribute('oppidum.command')
  let $level := oppidum:get-pipeline-type($cmd)
  return
    if ($level < 3) then (: expands the error message :)
      let $pipeline := request:get-attribute('oppidum.pipeline')
      let $set-status := ($level = 1) or (($level = 2) and empty($pipeline/view[@onerror]))
      (: because a model-view pipeline may ask to execute the view even in case of error with onerror="render" :)
      return oppidum:render-error($cmd/@confbase, $err-type, $err-clue, $cmd/@lang, $set-status)
    else
      (: stores error message for later rendering in the epilogue :)
      oppidum:add-error($err-type, $err-clue, if (($level = 4) or (request:get-attribute('oppidum.redirect.to'))) then true() else false())
};

(: ======================================================================
   Consumes the current error stack filled with oppidum:add-error
   and returns a list of expanded <error> messages
   Sets the response status code (so it must be called at the end of a pipeline)
   ======================================================================
:)
declare function oppidum:render-errors( $db as xs:string, $lang as xs:string ) as node()*
{
  for $e in oppidum:get-errors()
  let $type := substring-before($e, ':')
  let $clue := substring-after($e, ':')
  return
   oppidum:render-error($db, $type, if ($clue != '') then $clue else (), $lang, true())
};

(: ======================================================================
   Consumes the current message stack filled with oppidum:add-error
   and returns a list of expanded <message> messages
   ======================================================================
:)
declare function oppidum:render-messages( $db as xs:string, $lang as xs:string ) as node()*
{
  for $e in oppidum:get-messages()
  let $type := substring-before($e, ':')
  let $clue := substring-after($e, ':')
  return
    oppidum:render-message($db, $type, if ($clue != '') then $clue else (), $lang)
};

(: ======================================================================
   Checks if the current user is allowed to execute the action in the command.
   Returns true or false. In the later case, it also registers an
   UNAUTHORIZED-ACCESS in Oppidum error flash.
   ======================================================================
:)
declare function oppidum:check-rights-for( $cmd as element(), $defaults as element()* ) as xs:boolean
{
  let $target := $cmd/resource
  return
    if (($target/@access) and ($cmd/@action = 'GET')) then
      (: syntactic sugar for 'GET' access control :)
      oppidum:my-access-control(oppidum:test-role-for-command($target/@access, $cmd), $target)
    else
      let $rules := if ($target/access) then $target/access else $defaults
      return
        let $rule := $rules/rule[$cmd/@action = tokenize(@action, ' ')]
        return
          if ($rule) then
            oppidum:my-access-control(oppidum:test-role-for-command($rule/@role, $cmd), $rule)
          else
            true()
};

declare function oppidum:my-access-control( $granted as xs:boolean, $info as element() ) as xs:boolean
{
  let $error :=
    if (not($granted)) then
      request:set-attribute('oppidum.grantee', $info/@message)
    else ()
  return $granted
};

(: ======================================================================
   Returns a whitespace separated list of all the actions allowed
   for the current user on the page targeted by the command.
   ======================================================================
:)
declare function oppidum:get-rights-for( $cmd as element(), $defaults as element()* ) as xs:string
{
  if (not($cmd/resource/@supported) and not($cmd/resource/@method)) then
    '' (: pure resource w/o actions :)
  else
    let
      $actions := tokenize(string-join($cmd/resource/(@supported | @method), ' '), ' '),
      $rules := if ($cmd/resource/access) then $cmd/resource/access else $defaults
    return string-join(
      for $a in $actions
      let $rule := $rules/rule[$a = tokenize(@action, ' ')]
      return if (not($rule) or (oppidum:test-role-for-command($rule/@role, $cmd))) then $a else (), ' ')
};

(: ======================================================================
   Tests an access rule against the current user and the command.
   Returns true if the user is granted access and false otherwise.
   ======================================================================
:)
declare function oppidum:test-role-for-command( $role as xs:string,  $cmd as element() ) as xs:boolean
{
  let $roles := tokenize($role, ' ')
  return oppidum:my-test-role-iter(1, $roles, $cmd)
};

declare function oppidum:my-test-role-iter( $index as xs:integer, $roles as xs:string*, $cmd as element() ) as xs:boolean
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
          oppidum:check-group(substring-after($role, 'g:'))
        else if ('owner' = $role) then
          oppidum:check-owner($cmd)
        else
          false()
    return
     if ($res) then $res else oppidum:my-test-role-iter($index + 1, $roles, $cmd)
};

declare function oppidum:check-user( $name as xs:string ) as xs:boolean
{
  let $user := xdb:get-current-user()
  return $user = $name
};

declare function oppidum:check-group( $name as xs:string ) as xs:boolean
{
  let $user := xdb:get-current-user()
  return $name = xdb:get-user-groups($user)
};

(: ======================================================================
   Return true if the user is the owner of the reference object in $cmd
   and false otherwise
   ======================================================================
:)
declare function oppidum:check-owner( $cmd as element() ) as xs:boolean
{
  let $r := $cmd/resource
  let $col-uri := concat($r/@db, '/', $r/@collection)
  let $doc-uri := concat($col-uri, '/', $r/@resource)
  return
    if (doc-available($doc-uri)) then
      xdb:get-current-user() = xdb:get-owner($col-uri, $r/@resource)
    else
      false() (: in case user forged a URL to a resource that does not exists :)
};

