declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";
import module namespace skin = "http://oppidoc.com/oppidum/skin" at "../lib/skin.xqm";

declare option exist:serialize "method=html media-type=text/html";

let $cmd := request:get-attribute('oppidum.command')
let $pkg := request:get-parameter("pkg", 'oppidoc')
let $mesh := request:get-parameter("mesh", 'standard')
let $skin := request:get-parameter("skin", 'foobar')
let $confbase := request:get-parameter("confbase", '/db/www/oppidoc')
let $trail := request:get-parameter("trail", '')
let $mode := request:get-parameter("mode", 'test')
let $error := if (request:get-parameter("error", ())) then oppidum:add-error('ERROR', (), false()) else ()
let $message := if (request:get-parameter("message", ())) then oppidum:add-message('MESSAGE', (), false()) else ()
let $fakecommand := <command mode="{$mode}" trail="{$trail}" confbase="{$confbase}" base-url="{$cmd/@base-url}"/>
let $sideeffect := request:set-attribute('oppidum.command', $fakecommand)
let $result := skin:gen-skin($pkg, $mesh, $skin)
return 
  <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
      <title>Oppidum skin test</title>
      <style type="text/css">
      p {{
        margin: 0;
      }}
      p.source {{
        font-family: courrier;
      }}
      .error {{
        color:red
      }}
      </style>
      { $result }
    </head>
    <body style="margin: 2em 2em">
      <h1>Oppidum skin test</h1>
      <h2>Input parameters</h2>
      <p>package: {$pkg}</p>
      <p>mesh: {$mesh}</p>
      <p>skin: {$skin}</p>
      <h2>Skin output</h2>
      <div>
        {
        for $item in $result 
        return
          if (local-name($item) = 'link') then 
            <p class="code">link href="{$item/@href/string()}"</p>
          else if (local-name($item) = 'script') then
            if (not($item/@src)) then 
              if ($item/@data-error) then 
                <p class="code error">script error (see console)</p>
              else
                <p class="code">script with inline content</p>                
            else
              <p class="code">script src="{$item/@src/string()}"</p> 
          else
            <p class="code">{local-name($item)}</p>
        }
        <p><i>View window source to get exact content</i></p>
      </div>
      <h2>New parameters</h2>
      <form action="skin" method="get">
        <p>package: <input type="text" name="pkg" value="{$pkg}"/></p>
        <p>mesh: <input type="text" name="mesh" value="{$mesh}"/></p>
        <p>skin: <input type="text" name="skin" value="{$skin}"/></p>
        <fieldset>
          <legend>command</legend>
          <p>confbase: <input type="text" name="confbase" value="{$confbase}"/></p>
          <p>trail: <input type="text" name="trail" value="{$trail}"/></p>
          <p>mode: <input type="text" name="mode" value="{$mode}"/></p>
        </fieldset>
        <p>
          <label>
            <input type="checkbox" name="error" value="error">
              { if ($error) then attribute { 'checked' } { 'true'} else () }
            </input> 
            error
          </label>
          <label>
            <input type="checkbox" name="message" value="message">
              { if ($message) then attribute { 'checked' } { 'true'} else () }
            </input>
            message
          </label>
        </p>
        <p><input type="submit"/></p>
      </form>
    </body>
  </html>
    