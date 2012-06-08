xquery version "1.0";  
(: -----------------------------------------------
   Oppidum framework pipeline generator

   Generates the pipeline to execute a command

   Author: Stéphane Sire <s.sire@free.fr>

   November 2011 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)
   
module namespace gen = "http://oppidoc.com/oppidum/generator";                          

import module namespace response="http://exist-db.org/xquery/response";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace text="http://exist-db.org/xquery/text";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "util.xqm";   
import module namespace command = "http://oppidoc.com/oppidum/command" at "command.xqm";   

(: ======================================================================
   Changes "/static/{name}/..." target URL to "resources/..." or
   "oppidum/resources/..." then expand this URL to an absolute or a relative
   path to the target resource (depending on hosting environment) This works
   with our site's code layout convention. URLs of the form
   "/static/{module}/... are easy to filter by a Proxy setting
   ======================================================================
:)
declare function gen:path-to-static-resource($app-root as xs:string, $exist-path as xs:string, $payload as xs:string, $mkey as xs:string) as xs:string
{
  let $local-path := concat('resources/', substring-after(substring-after($payload, '/static/'), '/'))
  return  
    (: currently we handle only one module for "oppidum" resources :) 
    if (starts-with($payload, '/static/oppidum')) then 
      gen:path-to-lib($app-root, $exist-path, $local-path, 'oppidum')
    else
      gen:path-to($app-root, $exist-path, $local-path, $mkey)
};

(: ======================================================================
   Generates a relative path pointing to the root segment of a given path :
   - the dot-path function of "page.html" is ""
   - the dot-path function of "/foo/page.html" is "../"
   - the dot-path function of "/foo/bar/page.html" is "../../"
   ======================================================================
:)
declare function gen:dot-path($exist-path as xs:string) as xs:string 
{
  let 
    $p := if (contains($exist-path, '?')) then substring-before($exist-path, '?') else $exist-path,
    $rel := replace(replace($p, "[^/]+/", "../"), "^/|[^/]*$", "")
  return
    if (contains($rel, "..")) then $rel else ''
};

(: ======================================================================
   Returns a path to the script depending on the execution environment :
   - when running from the database it's a relative path
   - otherwise it's an absolute path starting at $app-root
   ======================================================================
:)
declare function gen:path-to($app-root as xs:string, $exist-path as xs:string, $script as xs:string, $mkey as xs:string) as xs:string
{
  let $prefix :=
    if ($mkey) then
      if (starts-with($app-root, 'xmldb:')) then
        concat(gen:dot-path($exist-path), "../", $mkey, "/")
      else
        replace($app-root, "/[^/]+/?$", concat("/", $mkey, "/"))
    else
      if (starts-with($app-root, 'xmldb:')) then 
        gen:dot-path($exist-path)
      else 
        $app-root
  return
    concat($prefix, $script)
};

(: ======================================================================
   Generates a link to execute the corresponding Oppidum script. 
   It supposes one of the following code layout:
   a/ Oppidum is deployed in a sibling folder of the application code folder in an 'oppidum' folder
   b/ the site code is deployed at the webapp root and Oppidum in an 'oppidum'
   folder at the same level (e.g. production case with single site deployed at root)
   c/ Oppidum is deployed in the database at /db/www/oppidum and the application is at '/db/www/{app-name}'
   Case a/ and b/ generate a link with an absolute path
   Case c/ generates a link with a relative path (eXist URLRewriting seems buggy with absolute ones)
   Note: the application code folder is the one containing the controller.xql calling this module
   ======================================================================
:)
declare function gen:path-to-lib($app-root as xs:string, $exist-path as xs:string, $script as xs:string, $mkey as xs:string) as xs:string 
{                                                                                            
  let $base := 
    if ($app-root = '/') then (: file system, application served directly below webapp/ :)
      concat('/', $mkey, '/')
    else if (starts-with($app-root, 'xmldb:')) then (: application served from database :)
      (: in that case only relative URLs work, as URLRewriting will also automatically prefixes the URLs 
         with $exist:root/$exist:path we have to forge a relative URL that substracts $exist:path
         plus an additionnel level ("..") since this method is called from the application's controller
         to actually points to /db/www/:mkey collection :)
      concat(gen:dot-path($exist-path), concat('../', $mkey, '/'))
    else (: file system, application served somewhere below webapp/ :)
      replace($app-root, "/[^/]+/?$", concat('/', $mkey, '/'))
  return
    concat($base, $script)
};   

(: ======================================================================
   Generates a path to an XQuery script to give to the XQUery servlet.
   This is tricky since absolute URLs work only in file system conditions, in database 
   hosting condition we must use relative URLs.
   ======================================================================
:)
declare function gen:path-to-model($app-root as xs:string, $exist-path as xs:string, $script as xs:string, $mkey as xs:string) as xs:string 
{
  if (contains($script, ":")) then
    gen:path-to-lib($app-root, $exist-path, substring-after($script, ':'), substring-before($script, ":"))
  else
    gen:path-to($app-root, $exist-path, $script, $mkey)
};

(: ======================================================================
   Generates a path to an XSLT script to give to the XSLT servlet.
   In that case absolute URLs works in both file system and database hosting conditions.
   Note: database hosting conditions does not allow '..' segments in the URL hence
   you must use the "xxx:" prefix to point to a script in the xxx libary
   ======================================================================
:) 
declare function gen:path-to-view($app-root as xs:string, $script as xs:string, $mkey as xs:string) as xs:string 
{
  if (contains($script, ":")) then
    let $lib := substring-before($script, ":")
    return
      concat(replace($app-root, "/[^/]+/?$", concat('/', $lib, '/')), 
        substring-after($script, concat($lib, ':')))
  else if ($mkey) then
    concat(replace($app-root, "/[^/]+/?$", concat('/', $mkey, '/')), $script)
  else
    concat($app-root, $script)
};
                                
(: ======================================================================
   Returns a pre-construction error pipeline specification. 
   Side effects :
   - sets "oppidum.error.type" to the error type
   - sets "oppidum.error.clue" to an optionnal error clue
   ======================================================================
:)             
declare function gen:error($cmd as element(), $type as xs:string, $clue as xs:string*) as element()
{               
  let 
    $pipeline := 
      <pipeline> 
        <model src="oppidum:models/error.xql"/>
        {                                                                                                    
        (: FIXME: maybe some POST request are not Ajax or debug request... :)  
        if ((string($cmd/@action) != 'POST') and (string($cmd/@format) != 'xml') and (string($cmd/@format) != 'raw')) then
          <epilogue mesh=""/>
          (: mesh may be an empty string anyway we force it to call epilogue :)
        else 
          () 
        }
      </pipeline>,
    $exec := (    
      (: sets attribute to be exploited by error.xql :)
      request:set-attribute('oppidum.error.type', $type),
      request:set-attribute('oppidum.error.clue', $clue)
      )
  return $pipeline
};
    
(: ======================================================================
   Returns a pre-construction error pipeline specification. 

   Returns either a redirection pipeline to a "/login" page or a
   pre-construction error pipeline created with gen:error.

   The design goal is to do the redirect when the request should result in a
   page directly viewable to the user, while the error response is targeted at
   AJAX requests or client-side library calls that should interpret it client-side.

   Side effects : 
   - in case or redirection stores error message in the flash using oppidum:add-error
   - in the other case same as gen:error

   This method should be called when authentication verification failed (i.e.
   oppidum:check-rights-for).
   ======================================================================
:)
declare function gen:must-authenticate($cmd as element()) as element()
{                                                          
  let 
    $uri := request:get-uri(),                             
    $method := request:get-method(),
    $grantee := request:get-attribute('oppidum.grantee')
      (: optional grantee should have been set when checking rights :)
    
  return              
    (: variant: if (($method = 'GET') and (not($cmd/@format) or ($cmd/@format = 'html'))) then :)
    if (($method = 'GET') and (not($cmd/@format) or (string($cmd/@format) != 'xml'))) then
      let 
        $goto := concat($cmd/@base-url, 'login?url=', $uri),
        $exec := (
          oppidum:add-error('UNAUTHORIZED-ACCESS', $grantee, true()),
          response:redirect-to(xs:anyURI($goto))
          )
      return                                    
        <pipeline redirect="{$goto}">
          <model src="oppidum:models/null.xql"/>
        </pipeline>
    else
      gen:error($cmd, 'UNAUTHORIZED-ACCESS', $grantee)
};  

(: ======================================================================
   Tests if the referent object for the command exists in the database.
   Returns 'yes' if it exists. 
   Returns the full path in the database of missing referent object if it does
   not exist. This allows to generate an error message with a clue.
   ======================================================================
:)
declare function gen:check-availability($cmd as element(), $pipeline as element()) as xs:string
{            
  let
    $db := $cmd/resource/@db,
    $col := $cmd/resource/@collection,
    $rsrc := $cmd/resource/@resource,
    $suffix := if ($cmd/resource/@suffix) then concat('.', $cmd/resource/@suffix) else '',
    $doc-uri := concat($db, '/', $col, '/', $rsrc, $suffix),
    $res := fn:doc-available($doc-uri)
  return 
    if ($res) then  (: ok, normal flow :)
      'yes'
    else 
      $doc-uri      
};        
                   
(: ======================================================================
   Returns an implementation independent pipeline to execute the given 
   command and defaults.
   ======================================================================
 :)                                        
declare function gen:resolve($cmd as element(), $default as element()*) as element()
{
  let
    $inline-action := 
      if (string($cmd/@action) = 'GET') then
        if ($cmd/@format and not(string($cmd/@format) = ('debug', 'xml', 'raw'))) then (: look for a format variant :)
          let $variant := $cmd/resource/variant[(@name = 'GET') and (@format = $cmd/@format)]
          return 
            if ($variant) then
              <action>
              {
              if ($variant/@epilogue) then $variant/@epilogue else $cmd/resource/@epilogue,
              if ($variant/@check) then $variant/@check else $cmd/resource/@check,
              if ($variant/model) then $variant/model else $cmd/resource/model,
              if ($variant/view) then $variant/view else $cmd/resource/view
              }
              </action> 
            else  
              <action/> (: no variant for the given format, that's an error unless there is a default action - FIXME Issue #16 :)   
        else  
          (: syntactic sugar : implicit action :)
          <action>
          {
          $cmd/resource/@epilogue,
          $cmd/resource/@check,
          $cmd/resource/model,
          $cmd/resource/view
          }
          </action> 
      else        
        $cmd/resource/action
       
  return
    <pipeline>   
      {      
        (: REDIRECTION :)
        let $src := 
          if ($inline-action/@redirect) 
            then string($inline-action/@redirect) 
            else string($default/@redirect)
        return
          if ($src) then attribute { 'redirect' } { $src } else (),
          
        (: CHECK
           Sets @check='true' iff it exists in scope and its value is not 'false'
         :)
        let $src := 
          if ($inline-action/@check = 'false') then false() else (($inline-action/@check = 'true') or ($default/@check = 'true'))
        return
          if ($src) then attribute { 'check' } { 'true' } else (),
        
        (: MODEL :)
        let $src := 
          if ((string($cmd/@action) = 'GET') and (starts-with($cmd/resource/@resource, 'file:///'))) then
            (: special case to store resources to local file system :)
            (substring-after($cmd/resource/@resource, 'file:///'), ())
          else if ($inline-action/model) then 
            (string($inline-action/model/@src), $inline-action/model)
          else 
            (string($default/model/@src), $default/model)
        return
          if ($src[1]) then <model src="{$src[1]}">{$src[2]/param}</model> else (),
          
        (: VIEW :)  
        let $src-node :=  
          if ($inline-action/view) then 
            $inline-action/view
          else 
            $default/view
        return
          if (string($src-node/@src)) then 
            <view>{
              $src-node/@src,
              $src-node/@onerror,
              $src-node/param
            }</view> 
          else 
            (),
          
        (: EPILOGUE :)
        let $src :=  if ($inline-action/@epilogue) then 
            string($inline-action/@epilogue)
          else 
            string($default/@epilogue)
        return
          if ($src) then <epilogue mesh="{$src}"/> else ()
      }
    </pipeline>
};


(: ======================================================================
   Does all the pre-construction checks that may break normal pipeline rendering.
   Returns an error pipeline implementation in case there are some errors, 
   or () otherwise.                
   In case of error, sets "oppidum.pipeline" with the rendered error pipeline.
   ======================================================================
 :)                                        
declare function gen:check($cmd as element(), $pipeline as element()) as element()*
{
  if ($cmd/@error) then                
    if ($cmd/@error = 'not-found') then
      gen:error($cmd, 'URI-NOT-FOUND', ())
    else 
      gen:error($cmd, 'URI-NOT-SUPPORTED', ())
  else
    if (not($pipeline/(model | view | epilogue))) then
      if ((string($cmd/@action) = 'GET') and ($cmd/@format and ($cmd/@format != 'debug'))) then
        gen:error($cmd, 'FORMAT-NOT-AVAILABLE', $cmd/@format)
      else        
        gen:error($cmd, 'NO-PIPELINE-ERROR', ())
    else 
      let $granted := request:get-attribute('oppidum.granted')
      return 
        if (not($granted)) then
          gen:must-authenticate($cmd)
        else
          ()
};

declare function gen:expand-paths( $exp as xs:string, $trail as xs:string ) as xs:string
{      
  let $tokens := tokenize($trail, '/')
  let $expanded := replace($exp, "\$(\d)", "|var=$1|")
  return 
    string-join( 
      for $t in tokenize($expanded, "\|")
      let $index := substring-after($t, 'var=')
      return
        if ($index) then $tokens[xs:decimal($index)] else $t,
      '')
};

(: FIXME: currently it does not support the value="$nb" syntax in parameters value
          because $cmd/trail contains all the info and is accessible from the code
 :)
declare function gen:model_parameters($cmd as element(), $pipeline as element()) as element()*
{
  for $p in $pipeline/model/param
  return
    <set-attribute name="{concat('xquery.', $p/@name)}" value="{$p/@value}"/>
};

declare function gen:more_view_parameters($cmd as element(), $pipeline as element()) as element()*
{
  (: some paramater names are reserved, see "URL Rewriting and MVC Framework" in eXist-db doc :)
  let $reserved := ("user", "password", "stylesheet", "rights", "base-url", "format", "input")
  return (
    if ($cmd/@format) then <set-attribute name="xslt.format" value="{$cmd/@format}"/> else (),
    <set-attribute name="xslt.base-url" value="{$cmd/@base-url}"/>,
    for $var in request:get-parameter-names() 
    return
      if (not($var = $reserved)) then
        <set-attribute name="{concat('xslt.', $var)}" value="{request:get-parameter($var, ())}"/>
      else (),
    for $p in $pipeline/view/param
    return
      if (not($p/@name = $reserved)) then
        <set-attribute name="{concat('xslt.', $p/@name)}" value="{gen:expand-paths($p/@value, $cmd/@trail)}"/>
      else ()
    )
};

(: ======================================================================
   Transforms the independent pipeline for the command given as parameters
   into an implementation pipeline executable by eXist-db. 
   As a side effect sets "oppidum.pipeline" with the rendered pipeline.
   ======================================================================
:)     
declare function gen:render($cmd as element(), $pipeline as element(), $mkey as xs:string) as element()*
{
  let 
    $avail := if (not($pipeline/@check)) then 'yes' else gen:check-availability($cmd, $pipeline),
    $void := request:set-attribute('oppidum.pipeline', $pipeline)
    
  return 
    <exist:dispatch xmlns:exist="http://exist.sourceforge.net/NS/exist">
    {                
      (: MODEL :)  
      if ($pipeline/model) then
        (: FIXME: turn DB-NOT-FOUND into a pre-construction error ? :)
        if ($avail = 'yes') then
          <forward url="{gen:path-to-model($cmd/@app-root, $cmd/@exist-path, $pipeline/model/@src, $mkey)}" xmlns="http://exist.sourceforge.net/NS/exist">
            <set-header name="Cache-Control" value="no-cache"/>
            <set-header name="Pragma" value="no-cache"/>
            { gen:model_parameters($cmd, $pipeline) }
          </forward>          
        else              
          <exist:forward url="{gen:path-to-lib($cmd/@app-root, $cmd/@exist-path, 'models/error.xql', 'oppidum')}">
            <exist:set-attribute name="oppidum.error.type" value="DB-NOT-FOUND"/>
            <exist:set-attribute name="oppidum.error.clue" value="{$cmd/resource/@name}"/>
            <exist:set-header name="Cache-Control" value="no-cache"/>
            <exist:set-header name="Pragma" value="no-cache"/>
          </exist:forward>
      else
        (),
      (: VIEW :)  
      let $hide := (string($cmd/@format) = 'xml') or 
                   (($avail != 'yes') and (string($pipeline/view/@onerror) != 'render') and not($pipeline/epilogue))
                   or (not($pipeline/(view | epilogue)) and (not(string($pipeline/@redirect) = ('resource', 'parent'))))
      return         
        if ($hide) then 
          ()
        else
          <exist:view>
            {                  
            if ($pipeline/@redirect = 'resource') then
              <exist:redirect url="{concat($cmd/@base-url, $cmd/@trail)}"/>
            else if ($pipeline/@redirect = 'parent') then
              <exist:redirect url="{concat($cmd/@base-url, string-join((tokenize($cmd/@trail, '/')[. ne ''])[position() < last()], '/'))}"/>
            else
              if ($pipeline/view and (($avail = 'yes') or (string($pipeline/view/@onerror) = "render"))) then
                let 
                  $src := $pipeline/view/@src,
                  $rights := request:get-attribute('oppidum.rights')
                return
                  <forward servlet="XSLTServlet" xmlns="http://exist.sourceforge.net/NS/exist">
                    <set-attribute name="xslt.stylesheet" value="{gen:path-to-view($cmd/@app-root, $src, $mkey)}"/>
                    <set-attribute name="xslt.rights" value="{$rights}"/>
                    { gen:more_view_parameters($cmd, $pipeline) }
                  </forward>
              else 
                (),        
              (: EPILOGUE :)  
              if ($pipeline/epilogue and (string($cmd/@format) != 'raw')) then 
                <exist:forward url="{gen:path-to($cmd/@app-root, $cmd/@exist-path, 'epilogue.xql', $mkey)}"/>
              else
                ()   
            }
          </exist:view>
      }
      <exist:cache-control cache="false"/>
    </exist:dispatch>                                                               
    (: FIXME : control cache control with mapping / default actions too ?:)    
};  

(: ======================================================================
   Returns an eXist-db pipeline to execute the command with the given 
   defaults. $mkey is the application name to resolve mapping URIs.
   ======================================================================
:)     
declare function gen:pipeline($cmd as element(), $default as element()*, $mkey as xs:string ) as element()*
{     
  (: tries to resolve the command into a pipeline specification :)
  let $pipeline := gen:resolve($cmd, $default)
  return
    (: checks the resolved pipeline is executable, 
       otherwise replaces it with an error pipeline specification :)
    let $error := gen:check($cmd, $pipeline)
    return
      if ($error) then 
        gen:render($cmd, $error, $mkey)
      else 
        gen:render($cmd, $pipeline, $mkey)
};           

(: ======================================================================
   Helper method to return a pipeline implementation to display Oppidum
   computed paramters instead of executing the request.   
   ======================================================================
:)
declare function gen:debug-command($cmd as element()) as element() 
{                           
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{gen:path-to-lib($cmd/@app-root, $cmd/@exist-path, 'models/debug.xql', 'oppidum')}"/>
    <cache-control cache="no"/>
  </dispatch>
};

(: ======================================================================
   Main Oppidum entry point
   ------------------------
   Parses the URL and returns the generated executable pipeline for eXist
   The URL is passed through eXist root, prefix, controller and path variables
   ======================================================================
:)
declare function gen:process(
  $root as xs:string, $prefix as xs:string, $controller as xs:string, $path as xs:string, 
  $lang as xs:string, $debug as xs:boolean,
  $access as element(), $actions as element(), $mapping as element()) as element() 
{    
  let $base-url := concat(request:get-context-path(), $prefix, $controller, '/')
  let $app-root := if (not($controller)) then concat($root, '/') else concat($controller, '/')
  return
    (: Web site root redirection :)
    if ($path = ('', '/')) then
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{$base-url}{$mapping/@startref}"/>   
        <cache-control cache="yes"/>
      </dispatch>   

    (: Note: in production the proxy should serve static/* directly :)
    else if (starts-with($path, "/static/")) then
      (: as an alternative we could set WEB-INF/controller-config.xml to rewrite /static :)
       <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
          <forward url="{gen:path-to-static-resource($app-root, $path, $path, string($mapping/@key))}"/>
          <cache-control cache="yes"/>
       </dispatch>
     
    else
      (: si on utilise pas le prefix remapping alors passer $exist:controller, $exist:controller
         si on l'utilise passer $exist:root, $exist:prefix  :)
      let 
        $cmd := command:parse-url($base-url, $app-root, $path, $path, request:get-method(), $mapping, $lang),
        $default := command:get-default-action($cmd, $actions),
        $set1 := request:set-attribute('oppidum.base-url', $base-url),      
        $set2 := request:set-attribute('oppidum.command', $cmd),      
        $rights := request:set-attribute('oppidum.rights', oppidum:get-rights-for($cmd, $access)),
        $granted := request:set-attribute('oppidum.granted', oppidum:check-rights-for($cmd, $access)),
        $pipeline := gen:pipeline($cmd, $default, string($mapping/@key))
      return 
        (: debug :)
        if ($debug and (($cmd/@format = 'debug') or (request:get-parameter('debug', '') = 'true'))) then
          let 
            $dbg1 := request:set-attribute('oppidum.debug.implementation', $pipeline),
            $dbg2 := request:set-attribute('oppidum.debug.default', $default)
          return
             gen:debug-command($cmd)            
        else
          $pipeline  
};

(:let $null := oppidum:log-parameters( <parameters>
      <param name="exist:prefix" value="{$exist:prefix}"/>
      <param name="exist:root" value="{$exist:root}"/>
      <param name="exist:controller" value="{$exist:controller}"/>
      <param name="exist:path" value="{$exist:path}"/>
      <param name="exist:resource" value="{$exist:resource}"/>
      <param name="base-url" value="{$base-url}"/>
      <param name="app-root" value="{$app-root}"/>
      <param name="context" value="{request:get-context-path()}"/>
    </parameters>  ):)
