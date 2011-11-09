xquery version "1.0";
(: --------------------------------------
	 Oppidum : error model generator 

	 Author: Stéphane Sire <s.sire@free.fr>

   Serves the reference object as an XTiger XML template. Applies an XSLT
   filter if the reference collection also contains a 'filter.xsl' script.
   
   Some typical filters may adjust some template parameters for photo upload
   and/or auto-complete and suggestion services, to make them independent from
   the context part of the URL. You can also easily setup a filter to
   implement server-side xt:include.
   
   NOTE: we did this because using directly XSLTServlet in the pipeline led 
   to corruption of the "xt" prefixes in the template file !
		
	 November 2011
	 -------------------------------------- :)
declare option exist:serialize "method=xml media-type=application/xml";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace transform = "http://exist-db.org/xquery/transform";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(:::::::::::::  BODY  ::::::::::::::)

let $col-uri := oppidum:path-to-ref-col()
let $template-uri := oppidum:path-to-ref()
let $db := request:get-attribute('oppidum.command')/@db
return  
  if (doc-available(concat($col-uri, '/filter.xsl'))) then
    let $params := <parameters>
                      <param name="xslt.base-url" value="{request:get-attribute('oppidum.base-url')}"/>
                   </parameters>
    return
      transform:transform(doc($template-uri), concat('xmldb://', $col-uri, '/filter.xsl'), $params)
  else
    doc($template-uri)
    
    
    
    


  
