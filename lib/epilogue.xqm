xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum framework epilogue

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Utility functions for writing epilogue scripts in XQuery

   February 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace epilogue = "http://oppidoc.com/oppidum/epilogue";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace site = "http://oppidoc.com/oppidum/site";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "util.xqm";

(: ======================================================================
   Returns a URL prefix pointing to the static resources of a given package 
   ======================================================================
:) 
declare function epilogue:make-static-base-url-for( $package as xs:string ) as xs:string 
{
  let $cmd := request:get-attribute('oppidum.command')
  return 
    if (string($cmd/@mode) eq 'prod') then
      concat('/static/', $package, '/') (: MUST be served by a proxy :)
    else
      concat(string($cmd/@base-url), 'static/', $package, '/')
};

(: ======================================================================
   Returns static CSS link elements pointing to the given package 
   DEPRECATED: use skin:gen-skin() instead
   ======================================================================
:) 
declare function epilogue:css-link( $package as xs:string, $files as xs:string*, $predefs as xs:string* ) as node()*
{
  let $base := epilogue:make-static-base-url-for($package)
  return (
    for $f in $files
    return
      if (starts-with($f, '[')) then (: conditional :)
        let $cond := substring-before($f, ']')
        let $path := substring-after($f, ']')
        return
          comment { concat($cond, ']><link rel="stylesheet" href="', $base, $path, '" type="text/css" charset="utf-8" /><![endif]') }
      else
        <link rel="stylesheet" href="{$base}{$f}" type="text/css" charset="utf-8"/>,
    for $p in $predefs (: pre-defined modules coming with Oppidum :)
    return
      if ($p = 'favicon') then (: convention :)
        <link rel="shortcut icon" type="image/x-icon" href="{$base}images/favicon.ico" />
      else if ($p = 'flash') then
        <link rel="stylesheet" href="{$base}css/flash.css" type="text/css" />
      else if ($p = 'axel') then (
        <link rel="stylesheet" href="{$base}css/Preview.css" type="text/css" />,
        <link rel="stylesheet" href="{$base}lib/axel/axel.css" type="text/css" />
        )
      else if ($p = 'photo') then
        <link rel="stylesheet" href="{$base}lib/axel/bundles/photo/photo.css" type="text/css" />
      else if ($p = 'date') then
        <link rel="stylesheet" href="{$base}contribs/jquery/css/ui-lightness/jquery-ui-1.8.18.custom.css" type="text/css" />
      else if ($p = 'pro_dropdown_2') then
        <link rel="stylesheet" href="{$base}contribs/pro_dropdown_2/pro_dropdown_2.css" type="text/css" />
      else
        ()
  )
};

(: ======================================================================
   Returns static Javascript script elements pointing to the given package
   DEPRECATED: use skin:gen-skin() instead
   ======================================================================
:) 
declare function epilogue:js-link( $package as xs:string, $files as xs:string*, $predefs as xs:string* ) as node()*
{
  let $base := epilogue:make-static-base-url-for($package)
  return (
    for $f in $files
    return
      if (starts-with($f, 'http:')) then
        <script type="text/javascript" src="{$f}">//</script>
      else
        <script type="text/javascript" src="{$base}{$f}">//</script>,
    for $p in $predefs (: pre-defined modules coming with Oppidum :)
    return
      if ($p = 'flash') then
        <script type="text/javascript" src="{$base}lib/flash.js">//</script>
      else if ($p = 'jquery') then
        <script type="text/javascript" src="{$base}contribs/jquery/js/jquery-1.7.1.min.js">//</script>
      else if ($p = 'axel') then (
        <script type="text/javascript" src="{$base}lib/axel/axel.js">//</script>,
        <script data-bundles-path="{$base}lib/axel/bundles" type="text/javascript" src="{$base}lib/editor.js">//</script>
        )
      else if ($p = 'axel+oppi') then (
        <script type="text/javascript" src="{$base}contribs/modernizr/modernizr.custom.12261.js">//</script>,
        <script type="text/javascript" src="{$base}lib/axel/axel.js">//</script>,
        <script data-bundles-path="{$base}lib/axel/bundles" type="text/javascript" src="{$base}lib/oppidum.js">//</script>
        )
      else if ($p = 'photo') then
        <script type="text/javascript">
          function finishTransmission(status, result) {{ 
            // var pwin = window.parent; // iff template run from inside an iframe !
            var manager = window.xtiger.factory('upload').getInstance(document);
            if (manager) {{
              manager.reportEoT(status, result);
            }}
          }}
        </script>
      else if ($p = 'date') then
        <script type="text/javascript" src="{$base}contribs/jquery/js/jquery-ui-1.8.18.custom.min.js">//</script>
      else if ($p = 'style') then
        <script type="text/javascript" src="{$base}lib/moreaxel/style.js">//</script>
      else if ($p = 'ga') then
        let $cmd := request:get-attribute('oppidum.command')
        return 
          if (string($cmd/@mode) eq 'prod') then
            let $tracker := doc(concat($cmd/@confbase, '/config/ga.xml'))/xhtml:script
            return
              if ($tracker) then
                $tracker
              else
                comment { 'Google Analytics tracker code not found' }
          else
            comment { 'comment to be replaced with Google Analytics tracker code in production' }
      else if ($p = 'pro_dropdown_2') then
        <script type="text/javascript" src="{$base}contribs/pro_dropdown_2/stuHover.js">//</script>
      else
        ()
  )
};

(: ======================================================================
   Returns a static image element pointing to the given package 
   ======================================================================
:) 
declare function epilogue:img-link( $package as xs:string, $files as xs:string*, $width as xs:string?, $height as xs:string? ) as element()*
{
  let $base := epilogue:make-static-base-url-for($package)
  for $f in $files
  return
    <img src="{$base}{$f}">
      { if ($width) then attribute width { $width } else () }
      { if ($height) then attribute height { $height } else () }
    </img>
};

(: ======================================================================
   Retrieves the name of the mesh to render the page from the pipeline
   parameter and returns the mesh file root node if it exists. Pre-condition :
   called from the epilogue iff the pipeline defines a non-empty mesh
   ======================================================================
:) 
declare function epilogue:get-mesh( $cmd as element(), $pipeline as element() ) as element()?
{
  let $fn := string($pipeline/epilogue/@mesh)
  let $mesh := epilogue:my-make-mesh-uri($cmd, $fn)
  return
    if ($mesh) then
      (: there is an explicit mesh :)
      if (epilogue:mesh-available($mesh, $fn)) then
        fn:doc($mesh)/*[1]
      else
        epilogue:my-default-mesh()
    else
      (: some pre-gen error prevented pipeline generation e.g. 'not-found', 'not-supported' - see command.xqm :)
      if ($cmd/@error) then
        let $errmesh := epilogue:my-make-mesh-uri($cmd, string($cmd/@error-mesh))
        return
          if ($errmesh and epilogue:mesh-available($errmesh, string($cmd/@error-mesh))) then 
            fn:doc($errmesh)/*[1]
          else
            let $defmesh := epilogue:my-make-mesh-uri($cmd, string($cmd/@error))
            return
              if (epilogue:mesh-available($defmesh, ())) then
                fn:doc($defmesh)/*[1]
              else
                epilogue:my-pregen-error-mesh()
      else 
        epilogue:my-pregen-error-mesh()
};

declare function epilogue:my-make-mesh-uri( $cmd as element(), $fn as xs:string ) as xs:string?
{
  if ($fn != '') then
    concat($cmd/@confbase, '/mesh/', $fn, '.html')
  else
    ()
};
            
declare function epilogue:mesh-available( $mesh-uri as xs:string, $name as xs:string? ) as xs:boolean
{
  let $res := fn:doc-available($mesh-uri)
  let $exec := if (not($res) and $name) then oppidum:add-error('DB-MESH-NOT-FOUND', $name, false()) else ()
  return
    $res
};

(: ======================================================================
   Returns a default mesh in case the requested mesh is missing.
   The mesh has hooks for site's link(s), script(s) and a <site:content>.
   ======================================================================
:) 
declare function epilogue:my-default-mesh() as element()
{  
  <html xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <site:link force="true"/>
      <site:script force="true"/>
    </head>
    <body>
      <div id="error"><site:error force="true"/></div>
      <div id="message" condition="has-message"><site:message force="true"/></div>
      <site:content/>
    </body>
  </html>
}; 

(: ======================================================================
   Returns a default mesh to notify a pre-generation error when no error 
   mesh was specified or when it is missing. The mesh does not have hooks 
   for site's link(s) and script(s), if you want to style pre generation 
   errors then you must include a global <error-handler> for the site.
   ======================================================================
:) 
declare function epilogue:my-pregen-error-mesh() as element()
{  
  <html xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">
    <body>
      <div id="error"><site:error force="true"/></div>
      <div id="message" condition="has-message"><site:message force="true"/></div>
    </body>
  </html>
};

(: ======================================================================
   Returns the mesh to render the current page, or the empty element
   if the model has asked a redirection
   ======================================================================
:)
declare function epilogue:finalize() as element()*
{
  let $redirect := request:get-attribute('oppidum.redirect.to')
  return
    if ($redirect) then
      response:redirect-to(xs:anyURI($redirect))
    else
      epilogue:get-mesh(request:get-attribute('oppidum.command'), request:get-attribute('oppidum.pipeline'))
};