xquery version "1.0";
(: --------------------------------------
   Oppidum Framework installation script

   Author: Stéphane Sire <s.sire@free.fr>

   Loads Oppidum library into the database as '/db/www/oppidum'
   Creates initial sites folder into the database as '/db/sites/platinn' 
   and stores Oppidum standards error files inside.
      
   September 2011
   -------------------------------------- :)
declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace request = "http://exist-db.org/xquery/request";
import module namespace install = "http://oppidoc.com/oppidum/install" at "../lib/install.xqm";   

declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

(: WARNING: do not forget to set the correct path below webapp here ! :)
declare variable $local:base := "/projets/oppidum";

declare function local:install-oppidum-data($dir as xs:string) as element()* {
  <ul>{ 
    install:create-collection("/db", "sites"),
    install:create-collection("/db", "oppidum"),

    (: config/errror :)
    install:create-collection("/db/oppidum", "config"),
    install:store-files("/db/oppidum/config", $dir, "init/errors.xml", "text/xml"),

    <li>Set permissions</li>,
    xdb:set-collection-permissions('/db/sites', 'admin', 'dba', util:base-to-integer(0744, 8)),  
    install:apply-permissions-to('/db/oppidum', 'admin', 'dba', util:base-to-integer(0744, 8))
  }</ul>
};

declare function local:install-oppidum-code( $dir as xs:string ) as element()* {
  <ul>{ 
    install:create-collection("/db", "www"),
    xdb:set-collection-permissions('/db/www', 'admin', 'dba', util:base-to-integer(0744, 8)), (: permissions set to rwur--r-- :)

    install:create-collection("/db/www", "oppidum"),
    install:store-files("/db/www/oppidum", $dir, "controller.xql", "application/xquery"),

    install:create-collection("/db/www/oppidum", "actions"),
    install:store-files("/db/www/oppidum/actions", $dir, "actions/*.xql", "application/xquery"),

    install:create-collection("/db/www/oppidum", "lib"),
    install:store-files("/db/www/oppidum/lib", $dir, "lib/*.xqm", "application/xquery"),

    install:create-collection("/db/www/oppidum", "models"),
    install:store-files("/db/www/oppidum/models", $dir, "models/*.xql", "application/xquery"),

    (:install:create-collection("/db/www/oppidum", "modules"),:)
    install:store-files("/db/www/oppidum", $dir, "modules/**/*.xql", "application/xquery", true()),

    (:install:create-collection("/db/www/oppidum", "resources"),:)
    install:store-files("/db/www/oppidum", $dir, "resources/**/*.css", "text/css", true()),
    install:store-files("/db/www/oppidum", $dir, "resources/**/*.js", "application/x-javascript", true()),
    install:store-files("/db/www/oppidum", $dir, "resources/**/*.html", "text/html", true()),
    install:store-files("/db/www/oppidum", $dir, "resources/**/*.png", "image/png", true()),
    install:store-files("/db/www/oppidum", $dir, "resources/**/*.gif", "image/gif", true()),
    (: there a trick because photo.xhtml is a forrest and cannot be imported as text/xml :)
    install:store-files("/db/www/oppidum/resources/lib/axel/bundles/photo", $dir, "resources/lib/axel/bundles/photo/photo.xhtml", "text/plain"),

    install:create-collection("/db/www/oppidum", "templates"),
    install:store-files("/db/www/oppidum/templates", $dir, "templates/*.xhtml", "text/xml"),

    install:create-collection("/db/www/oppidum", "views"),
    install:store-files("/db/www/oppidum/views", $dir, "views/*.xsl", "text/xml"),

    (: utility script(s) for post-installation processing :)
    install:create-collection("/db/www/oppidum", "scripts"),
    install:store-files("/db/www/oppidum/scripts", $dir, "scripts/filter-transfo.xsl", "text/xml"),

    <li>Set permissions to RWUR--R--</li>,
    install:apply-permissions-to('/db/www/oppidum', 'admin', 'dba', util:base-to-integer(0744, 8))
  }</ul>  
};  

let $install := request:get-parameter("go", ())
(:$login := xdb:login('/db', $login, $passwd):)
return 
  <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Oppidum DB installation script</title>
  </head>
  <body>
    <h1>Oppidum installation</h1>
    <div>
      {
      if ($install) then
        <div class="report">
          <p>Installation report:</p>
          {
            let $dir := install:webapp-home($local:base)
            let $target := request:get-parameter("target", ())
            return
              if ($target = 'code') then
                local:install-oppidum-code($dir)
              else if ($target = 'data') then
                local:install-oppidum-data($dir)
              else
                <p>Target {$target} unknown, use the installation form to select a target</p>
          }
        </div>
      else
        <form method="post" action="install.xql">
          <input type="hidden" name="go" value="yes"/>
          <p>Target : 
						<input id="code" type="radio" value="code" name="target" checked="true"/>
						<label for="code">Code (/db/www/oppidum)</label>
						<input id="data" type="radio" value="data" name="target"/>
						<label for="data">Data (/db/sites/oppidum)</label>
					</p>
          { 
          let $user :=  xdb:get-current-user()
          return (
            <p>You are logged in as <b>{$user}</b></p>,            
            if ($user != 'admin') then 
              <p>You MUST <a href="login">login</a> first as <b>admin</b> user using the application you plan to install !</p> 
            else (
              <p>Click on the install button to copy Oppidum from the file system to the '/db/www' collection</p>,
              <p style="margin-left: 10%"><input type="submit" value="Install"/></p>          
              )
            )
          }          
        </form>
      }
    </div>    
  </body>
  </html>

