xquery version "1.0";         
(: --------------------------------------
   Oppidum framework universal default controller

   This controller must be installed inside '/db/www/root'. It is to be
   replaced by the root application controller in the universal Oppidum
   distribution. It just displays the oppidum version information page for any
   URL. It works with the universal controller-config.xml configuration that
   redirects .* to '/db/www/root'.
   
   Author: Stéphane Sire <s.sire@free.fr>
  
   January 2012
   -------------------------------------- :)
import module namespace gen = "http://oppidoc.com/oppidum/generator" at "../oppidum/lib/pipeline.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../oppidum/lib/util.xqm";

let $app-root := if (not($exist:controller)) then concat($exist:root, '/') else concat($exist:controller, '/')
return
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{gen:path-to-lib($app-root, $exist:path, 'models/version.xql', 'oppidum')}">
      <set-header name="Cache-Control" value="no-cache"/>
      <set-header name="Pragma" value="no-cache"/>
    </forward>
  	<cache-control cache="no"/>
  </dispatch>