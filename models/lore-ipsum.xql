xquery version "1.0";
(: --------------------------------------
   Oppidum : lore ipsum generator (debug purpose)

   Author: Stéphane Sire <s.sire@oppidoc.fr>

   Generates random content
   If xquery.format parameter is equal to "view" wraps the result into a <site:view>

   January 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

declare namespace site = "http://oppidoc.com/oppidum/site";
declare namespace request = "http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=application/xml";

declare function local:gen ( $nb as xs:integer ) as element()
{
  <article>
    <h1>Lorem ipsum dolor sit amet</h1>
    {
    for $item in 1 to $nb
    return
      (
      <h2>Consectetur adipisicing elit</h2>,
      <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
      )
    }
  </article>
};

let $max := number(request:get-parameter('nb', ()))
let $nb := if (string($max) = "NaN") then 1 else if (($max) < 10) then $max else 10
let $format := request:get-attribute('xquery.format')
return
  if ($format = 'view') then
    <site:view>
      <site:content>
        { local:gen(1) }
      </site:content>
    </site:view>
  else
    local:gen($nb)
