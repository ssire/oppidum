xquery version "1.0";
(: --------------------------------------
	 Oppidum : test

	 Author: Stéphane Sire <s.sire@free.fr>
   
   Test access rights functions
		
	 July 2011
	 -------------------------------------- :)
declare namespace request = "http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";                    

import module namespace command = "http://oppidoc.com/oppidum/command" at "../lib/command.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=html media-type=text/html";

declare variable $access1 := <access>
  <rule action="archive unarchive" role="u:admin"/>
  <rule action="edit POST foo" role="u:admin" message="site administrator"/>
</access>;

declare variable $access2 := <access>
  <rule action="archive unarchive POST" role="all"/>
</access>;    
             
(: fake site mapping :)
declare variable $mapping := <site db="/db/aed" startref="home" supported="login logout">
  <item name="home" resource="home.xml" collection="resources/pages" 
    supported="archive unarchive edit foo" method="POST" template="templates/page" access="u:admin">
  </item>           
</site>;

declare function local:test-rights( $nb as xs:integer, $payload as xs:string, $method as xs:string, $access as element()?) 
{
  let 
    $cmd := command:parse-url('BASE', 'ROOT', 'PATH', $payload, $method, $mapping, 'fr', ()),
    $rights := oppidum:get-rights-for($cmd, $access)
  
  return 
    <p>test #{$nb} got rights: <span>{$rights}</span></p>
};

declare function local:test-access( $nb as xs:integer, $payload as xs:string, $method as xs:string, $access as element()?) 
{
  let 
    $cmd := command:parse-url('BASE', 'ROOT', 'PATH', $payload, $method, $mapping, 'fr', ()),
    $granted := oppidum:check-rights-for($cmd, $access),
    $msg := string-join(oppidum:get-errors(), ' ')
    
  return                                                                     
    <p>test #{$nb} : access <span>{if ($granted) then 'granted' else 'refused'}</span> {if ($msg) then <b>{$msg}</b> else ()}</p>
};
            
let 
  $user := xdb:get-current-user(),
  $my-url := request:get-uri()
  
return
  <div>                       
    <h1>Oppidum Test</h1>
    <p>
      <button onclick="javascript:window.location.href='../login?url={$my-url}'">login</button>
      <button onclick="javascript:window.location.href='../logout?url={$my-url}'">logout</button>
    </p>
    <p>with user : <b>{$user}</b></p>
    <h2>Authorized actions</h2>                       
    {
    local:test-rights(1, '/home', 'GET', $access1),
    local:test-rights(2, '/home', 'GET', $access2)
    }
    <hr/>
    <h2>Access control</h2>                       
    {                         
    local:test-access(3, '/home/foo', 'GET', $access1)
    }
    <hr/>
    <p>Run this page with / without being logged in as "admin"</p>
  </div>
    
 