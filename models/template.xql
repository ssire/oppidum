xquery version "1.0";
(: --------------------------------------
   Oppidum : template filtering 
   
   Author: Stéphane Sire <s.sire@free.fr>

   Serves the reference object as an XTiger XML template. Applies an XSLT
   filter if the reference collection also contains a 'filter.xsl' script.
   
   Some typical filters may adjust some template parameters for photo upload
   and/or auto-complete and suggestion services, to make them independent from
   the context part of the URL. You can also easily setup a filter to
   implement server-side xt:include.
   
   NOTE: we did this because using directly XSLTServlet in the pipeline led 
   to corruption of the "xt" prefixes in the template file !
   
   WARNING: template collection is interpreted relatively to @confbase 
  (instead of @db)
    
   January 2012 - Copyright (c) Oppidoc S.A.R.L
   -------------------------------------- :)
declare option exist:serialize "method=xml media-type=application/xml";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace transform = "http://exist-db.org/xquery/transform";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

(:declare option exist:serialize "method=xml media-type=text/xml";:)
declare option exist:serialize "method=xml media-type=application/xhtml+xml";

(:::::::::::::  BODY  ::::::::::::::)

(:let $col-uri := oppidum:path-to-ref-col()
let $template-uri := oppidum:path-to-ref() :)
let $cmd := request:get-attribute('oppidum.command')
let $col-uri := concat($cmd/@confbase, '/', $cmd/resource/@collection)
let $template-uri := concat($col-uri, '/', $cmd/resource/@resource)
return  
  if (doc-available(concat($col-uri, '/filter.xsl'))) then
    let $params := <parameters>
                      <param name="xslt.base-url" value="{request:get-attribute('oppidum.base-url')}"/>
                      {
                      (: some parameter names are reserved, see "URL Rewriting and MVC Framework" in eXist-db doc :)
                      let $reserved := ("user", "password", "stylesheet", "rights", "base-url", "format", "input")
                      return
                        for $var in request:get-parameter-names()
                        return
                          if (not($var = $reserved)) then
                            <param name="{concat('xslt.', $var)}" value="{request:get-parameter($var, ())}"/>
                          else ()
                      }
                   </parameters>
    return
      transform:transform(doc($template-uri), concat('xmldb:exist://', $col-uri, '/filter.xsl'), $params)
  else
    doc($template-uri)
    
    
    
    


  
