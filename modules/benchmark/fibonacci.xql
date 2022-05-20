xquery version "1.0";
(: --------------------------------------
   Oppidum benchmark function

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   To test server performance

   November 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

(:declare default element namespace "http://www.w3.org/1999/xhtml";:)

import module namespace request="http://exist-db.org/xquery/request";

declare function local:fibonacci-iter ( $set as xs:integer*, $max as xs:integer ) {
  if (count($set) = $max) then 
    $set
  else
    let $next-step := ($set, $set[last()] + $set[last() - 1] )
    return 
      local:fibonacci-iter($next-step, $max)
};

declare function local:fibonacci ( $max as xs:integer ) {
  let $seed := ( 0, 1 )
  return 
    if ($max = 1) then
      subsequence($seed, 1, 1)
    else if ($max = 2) then 
      $seed
    else
      local:fibonacci-iter($seed, $max)
};

let $free-before := system:get-memory-free()
let $start := util:system-time()
let $max := request:get-parameter('max', 10)
return
  if ($max castable as xs:integer) then
    if ((number($max) > 0) and (number($max) < 1000)) then 
      let $results := local:fibonacci(xs:integer(number($max)))
      let $free-after := system:get-memory-free()
      let $end := util:system-time()
      let $runtimems := (($end - $start) div xs:dayTimeDuration('PT1S'))  * 1000
      return
        <results duration="{$runtimems}" max="{count($results)}" free-mem-before="{$free-before}" free-mem-after="{$free-after}">
        {
        for $n at $i in $results
        order by $n descending 
        return <value rank="{$i}">{$n}</value>
        }
        </results>
    else
      <error>vous êtes sûr ?</error>
  else
    <error>choisissez un nombre entier plutôt que "{$max}"</error>