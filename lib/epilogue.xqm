xquery version "1.0";
(: -----------------------------------------------
   Oppidum framework epilogue

   Utility functions for writing epilogue scripts in XQuery

   Author: Stéphane Sire <s.sire@free.fr>

   November 2011 - Copyright (c) Oppidoc S.A.R.L
   ----------------------------------------------- :)

module namespace epilogue = "http://oppidoc.com/oppidum/epilogue";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";                                                                       
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace site = "http://oppidoc.com/oppidum/site";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../oppidum/lib/util.xqm";

(: ======================================================================
   Returns a URL prefix pointing to the static resources of a given package 
   ======================================================================
:) 
declare function epilogue:make-static-base-url-for( $package as xs:string ) as xs:string 
{
  concat(request:get-attribute('oppidum.base-url'), 'static/', $package, '/')
};

(: ======================================================================
   Returns static CSS link elements pointing to the given package 
   ======================================================================
:) 
declare function epilogue:css-link( $package as xs:string, $files as xs:string*, $predefs as xs:string* ) as element()*
{
  let $base := concat(request:get-attribute('oppidum.base-url'), 'static/', $package, '/')
  return (
    for $f in $files
    return
      <link rel="stylesheet" href="{$base}{$f}" type="text/css" charset="utf-8"/>,
    for $p in $predefs (: pre-defined modules coming with Oppidum :)
    return
      if ($p = 'axel') then (
        <link rel="stylesheet" href="{$base}css/Preview.css" type="text/css" />,
        <link rel="stylesheet" href="{$base}lib/axel/axel.css" type="text/css" />
        )
      else if ($p = 'photo') then
        <link rel="stylesheet" href="{$base}lib/axel/bundles/photo/photo.css" type="text/css" />
      else
        ()
  )
};

(: ======================================================================
   Returns static Javascript script elements pointing to the given package
   ======================================================================
:) 
declare function epilogue:js-link( $package as xs:string, $files as xs:string*, $predefs as xs:string* ) as element()*
{
  let $base := concat(request:get-attribute('oppidum.base-url'), 'static/', $package, '/')
  return (
    for $f in $files
    return
      <script type="text/javascript" src="{$base}{$f}">//</script>,    
    for $p in $predefs (: pre-defined modules coming with Oppidum :)
    return
      if ($p = 'jquery') then
        <script type="text/javascript" src="{$base}lib/jquery-1.5.1.min.js">//</script>
      else if ($p = 'axel') then (
        <script type="text/javascript" src="{$base}lib/axel/axel.js">//</script>,
        <script data-bundles-path="{$base}lib/axel/bundles" type="text/javascript" src="{$base}lib/editor.js">//</script>
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
      else
        ()
  )
};

(: ======================================================================
   Returns a static image element pointing to the given package 
   ======================================================================
:) 
declare function epilogue:img-link( $package as xs:string, $files as xs:string* ) as element()*
{
  let $base := concat(request:get-attribute('oppidum.base-url'), 'static/', $package, '/')
  for $f in $files
  return
    <img src="{$base}{$f}"/>
};

(: ======================================================================
   Retrieves the name of the mesh to render the page from the pipeline
   parameter and returns the mesh file root node if it exists. Pre-condition :
   called from the epilogue iff the pipeline defines a non-empty mesh
   ======================================================================
:) 
declare function epilogue:get-mesh( $cmd as element(), $pipeline as element() ) as element()* 
{
  let $filename := 
    if ($cmd/@error) then (: pre-generation error : 'not-found', 'not-supported' - see command.xqm :)
      if ($cmd/@error-mesh) 
        then string($cmd/@error-mesh) (: there is an error mesh defined in the mapping :)
        else string($cmd/@error) (: no error mesh in mapping :)
    else
      string($pipeline/epilogue/@mesh)
  return
    if ($filename != '') then
      let $path := concat($cmd/@db, '/mesh/', $filename, '.html')
      let $root := fn:doc($path)/*[1]
      return                 
        if ($root) 
          then $root
          else epilogue:my-gen-mesh-error($filename)
    else
      epilogue:my-gen-error-no-mesh()      
};  

(: ======================================================================
   Returns an error when the mesh to render a page is missing
   ======================================================================
:) 
declare function epilogue:my-gen-mesh-error( $name as xs:string ) as element()
{  
  (:  FIXME: let $err := oppidum:throw-error('DB-MISSING-MESH', $name):)
  <html>
    <body>
      <site:error force="true"/>
      <p>Note : additionally you can tell the Webmaster that mesh “{$name}” is missing to present the error</p>
    </body>
  </html>
}; 

(: ======================================================================
   Returns a fake mesh to display the error and a note that there is no mesh
   ======================================================================
:) 
declare function epilogue:my-gen-error-no-mesh() as element()
{  
  (:  FIXME: let $err := oppidum:throw-error('DB-MISSING-MESH', $name):)
  <root>
    <site:error force="true"/>
  </root>
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



