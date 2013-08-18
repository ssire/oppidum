(: ------------------------------------------------------------------
   Oppidum framework skin

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Test file for command.xqm and pipeline.xqm

   July 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";
import module namespace command = "http://oppidoc.com/oppidum/command" at "../lib/command.xqm";
import module namespace gen = "http://oppidoc.com/oppidum/generator" at "../lib/pipeline.xqm";

declare option exist:serialize "method=html5 media-type=text/html";

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
                   gen:pipeline($command, $default, string($mapping/@key))

(: end timer :)
let $end := util:system-time()
let $runtimems := (($end - $start) div xs:dayTimeDuration('PT1S'))  * 1000

(: print result :)
return
  <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
      <title>Oppidum Generator Test</title>
      <style language="text/css">
        div.code {{
          margin: 1em 2em 2em 1em;
          border: solid 1px black;
          padding: 1em 2em;
        }}
        pre {{
          white-space: pre-wrap; /* css-3 */
          white-space: -moz-pre-wrap !important; /* Mozilla, since 1999 */
          white-space: -pre-wrap; /* Opera 4-6 */
          white-space: -o-pre-wrap; /* Opera 7 */
          word-wrap: break-word; /* Internet Explorer 5.5+ */
        }}
        form p {{
          margin: 0;
        }}
        fieldset {{
          position: relative;
        }}
        #left {{
          float:left;
          width:300px;
        }}
        #right {{
          margin-left: 400px;
        }}
        #data {{
          width: 100%;
          min-height: 200px;
        }}
        fieldset {{
          padding: 1em 0.5em
        }}
        fieldset p {{
          margin: 0 0 0.5em 0;
          clear: both;
        }}
        span.label {{
          float: left;
          width: 100px;
        }}
      </style>
      <script type="text/javascript" charset="utf-8">
function saveSuccessCb (response, status, xhr) {{
  $('#results').text(xhr.responseText);
}}
function saveErrorCb (xhr, status, e) {{
  $('#results').text('POST error ' + status);
}}  
function run(goal) {{
  var url = document.forms[0]['base-url'].value + document.forms[0].path.value,
      data = document.getElementById('data').value;
  if (goal === 'get') {{
    window.open(url);
  }} else {{
    $.ajax({{
      url : url,
      type : 'post',
      data : data,
      dataType : 'xml',
      cache : false,
      timeout : 10000,
      contentType : "application/xml; charset=UTF-8",
      success : saveSuccessCb,
      error : saveErrorCb
      }});
  }}
}}
function duplicateProject() {{
  var n = document.getElementById('project'),
      m = document.getElementById('base-url');
  m.value = '/exist/projets/' + n.value + '/';
  m = document.getElementById('confbase');
  m.value = '/db/www/' + n.value;
  return false;
}}
      </script>
      <script type="text/javascript" src="../static/oppidum/contribs/jquery/js/jquery-1.7.1.min.js">//</script>
    </head>
    <body style="margin: 2em 2em">
      <h1>Oppidum Generator Test</h1>
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
              <p><span class="label">base-url</span> <input type="text" id="base-url" name="base-url" value="{$base-url}"/></p>
              <p><span class="label">confbase</span> <input type="text" id="confbase" name="confbase" value="{$confbase}"/></p>
              <p><span class="label">method</span> <input type="text" name="method" value="{$method}"/></p>
              <p><span class="label">mode</span> <input type="text" name="mode" value="{$mode}"/></p>
              <p>Generate : <input type="submit" name="type" value="Command"/> <input type="submit" name="type" value="Pipeline"/></p>
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
          <p><textarea id="data"></textarea></p>
        </fieldset>
    </body>
  </html>
