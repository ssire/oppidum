(: ------------------------------------------------------------------
   Oppidum framework skin

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Test file for skin.xqm

   July 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.  
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

declare namespace site = "http://oppidoc.com/oppidum/site";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";
import module namespace skin = "http://oppidoc.com/oppidum/skin" at "../lib/skin.xqm";

declare option exist:serialize "method=html5 media-type=text/html";

let $start := util:system-time()
let $saved-cmd := request:get-attribute('oppidum.command')
let $pkg := request:get-parameter("pkg", 'oppidum')
let $mesh := request:get-parameter("mesh", 'devtools')
let $skin := request:get-parameter("skin", ())
let $confbase := request:get-parameter("confbase", '/db/www/oppidum')
let $base-url := request:get-parameter("base-url", $saved-cmd/@base-url/string())
let $trail := request:get-parameter("trail", '')
let $mode := request:get-parameter("mode", 'dev')
let $error := if (request:get-parameter("error", ())) then oppidum:add-error('ERROR', (), false()) else ()
let $message := if (request:get-parameter("message", ())) then oppidum:add-message('MESSAGE', (), false()) else ()
let $fakecommand := 
  <command mode="{$mode}" trail="{$trail}" confbase="{$confbase}" base-url="{$base-url}">
    <resource epilogue="{$mesh}"/>
  </command>
let $fake-cmd := request:set-attribute('oppidum.command', $fakecommand)
let $result := skin:gen-skin($pkg, $mesh, $skin)
let $end := util:system-time()
let $runtimems := (($end - $start) div xs:dayTimeDuration('PT1S'))  * 1000 
let $restore-cmd := request:set-attribute('oppidum.command', $saved-cmd)
return 
  <site:view skin="skin">
    <site:title>Oppidum skin simulator</site:title>
    <site:content>
      <h1>Skin simulator</h1>
      <p><b>Current parameters</b>: package ({$pkg}), mesh: ({$mesh}), skin: ({$skin})</p>
      <p><b>Generated links and scripts</b> in {$runtimems} ms</p>
      <p><b>Summary</b></p>
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
      <p><b>Source</b></p>
      <div class="code">
        <pre>
          { replace(replace(fn:serialize($result, ()), '<', '&lt;'), 'xmlns="http://www.w3.org/1999/xhtml"', '') }
        </pre>
      </div>
      <h2>New simulation</h2>
      <form action="skin" method="get">
        <p>package: <input type="text" name="pkg" value="{$pkg}"/></p>
        <p>mesh: <input type="text" name="mesh" value="{$mesh}"/></p>
        <p>skin: <input type="text" name="skin" value="{$skin}"/></p>
        <fieldset>
          <legend>command</legend>
          <p>base-url: <input type="text" name="base-url" value="{$base-url}"/></p>
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
    </site:content>
  </site:view>
    