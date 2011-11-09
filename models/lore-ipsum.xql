xquery version "1.0";
(: --------------------------------------
	 Oppidum : lore ipsum generator (debug purpose)

	 Author: Stéphane Sire <s.sire@free.fr>
   
   Generates random content to test the site
		
	 June 2011
	 -------------------------------------- :)
declare namespace request = "http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=application/xml";

let 
  $max := number(request:get-parameter('nb', ())),
  $nb := if (string($max) = "NaN") then 1 else if (($max) < 10) then $max else 10
return	     
    <article>                                   
      <h1>Lorem ipsum dolor sit amet</h1>
      {
      for $item in 1 to ($nb cast as xs:integer)
      return 
      (
      <h2>Consectetur adipisicing elit</h2>,
      <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
      )
    }
    </article>
 