(: ------------------------------------------------------------------
   Oppidum framework skin

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Test file for command.xqm and pipeline.xqm

   July 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=application/xml";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";
import module namespace command = "http://oppidoc.com/oppidum/command" at "../lib/command.xqm";
import module namespace gen = "http://oppidoc.com/oppidum/generator" at "../lib/pipeline.xqm";

declare function local:gen-error( $cmd as element() ) {
  if (oppidum:has-error()) then
    <div class="error">
      {
      let $resolved := oppidum:render-errors($cmd/@confbase, $cmd/@lang)
      return (
        for $m in $resolved/message
        return <p>{$m/text()}</p>
        )
      }
    </div>
  else
    ()
};

(: saves pipeline in case it will be overwritten during pipeline simulation :)
let $saved-pl := request:get-attribute('oppidum.pipeline')

(: start timer :)
let $type := request:get-parameter("type", 'Command') (: 'Command' or 'Pipeline' :)

(: test :)
let $start := util:system-time()
let $cmd := request:get-attribute('oppidum.command')
let $_path := request:get-parameter("path", 'test')
let $path := if (normalize-space($_path) = '') then '/' else normalize-space($_path)
let $project := request:get-parameter("project", 'oppidum')
let $confbase := request:get-parameter("confbase", '/db/www/oppidum')
let $base-url := request:get-parameter("base-url", $cmd/@base-url/string())
let $mode := request:get-parameter("mode", 'dev')
let $method := request:get-parameter("method", 'GET')
let $mapping-path := concat($confbase, '/config/mapping.xml')
let $modules-path := concat($confbase, '/config/modules.xml')
let $mapping := fn:doc($mapping-path)/site
let $command := if ($mapping) then
                  command:parse-url($base-url, $cmd/@app-root, $path, $path, $method, $mapping, 'fr', ())
                else
                  <error>could not find "{concat($confbase, '/config/mapping.xml')}"</error>
let $result := if ((local-name($command) = 'error') or ($type = 'Command')) then
                 $command
               else
                 let $default := <actions/>
                 return
                   gen:pipeline($command, $default, string($mapping/@key), '', true())

(: end timer :)
let $end := util:system-time()
let $runtimems := (($end - $start) div xs:dayTimeDuration('PT1S'))  * 1000

(: restores pipeline (in case simulating pipeline generation :)
let $restore-pl := request:set-attribute('oppidum.pipeline', $saved-pl)

(: print result :)
return
  <site:view skin="generator">
    <site:title><title>Oppidum mapping simulator</title></site:title>
    <site:content>
      <h1>Mapping simulator</h1>
      {
      if ($type = 'Command') then
        <p><b>{$type}</b> generated in <b>{$runtimems} ms</b> from “{$mapping-path}” and “{$modules-path}”</p>
      else
        <p><b>{$type}</b> generated in <b>{$runtimems} ms</b> from “{$mapping-path}” and “{$modules-path}” (version w/o default actions)</p>
      }
      <p><b>Current path</b>: {$path}</p>
      <div class="code">
        <pre id="results">
          { replace(util:serialize($result, ()), '<', '&lt;') }
        </pre>
      </div>
      { local:gen-error($cmd) }
      <h2>New simulation</h2>
      <div id="left">
        <form action="generator" method="post" onkeypress="return event.keyCode != 13;">
          <p style="margin: 1em 0">path: <input type="text" name="path" value="{$path}"/></p>
          <fieldset>
            <legend>Configuration</legend>
            <p><span class="label">project</span> <input onblur="javascript:duplicateProject()" id="project" type="text" name="project" value="{$project}"/></p>
            <p><span class="label">base-url</span> <input type="text" id="base-url" name="base-url" value="{$base-url}" data-project="{ tokenize($base-url, '/')[3] }"/></p>
            <p><span class="label">confbase</span> <input type="text" id="confbase" name="confbase" value="{$confbase}"/></p>
            <p><span class="label">method</span> <input type="text" name="method" value="{$method}"/></p>
            <p><span class="label">mode</span> <input type="text" name="mode" value="{$mode}"/></p>
            <p>Generate : <input type="submit" name="type" value="Command"/> <input type="submit" name="type" value="Pipeline"/></p>
            <p>Display : <button onclick="javascript:mapping()">mapping.xml</button> (dev only)</p>
          </fieldset>
        </form>
      </div>
      <fieldset id="right">
        <legend>Execute</legend>
        <p>This panel allows to send GET or POST requests to the application independently of <i>Configuration</i> parameters.</p>
        <p>
          <button onclick="javascript:run('get')">GET</button> will open the path URL in a new window
        </p>
        <p>
          <button onclick="javascript:run('post')">POST</button> will send the XML data below to the path URL :
        </p>
        <p>
          <button onclick="javascript:run('delete')">DELETE</button> will send a DELETE to the path URL
        </p>
        <p>
          <button onclick="javascript:prefill('service')">SERVICE</button> pre-fill content with empty XML Payload in XML service envelope
        </p>
        <p><textarea id="data"></textarea></p>
        <form id="file" method="POST" enctype="multipart/form-data" onsubmit="return false">
          <input type="file" name="xt-file"/>
          <input type="submit" value="POST" onclick="javascript:file()"/> will send the File on the left to the path URL
        </form>
      </fieldset>
    </site:content>
  </site:view>
