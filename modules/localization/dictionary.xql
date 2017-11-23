xquery version "3.0";
(: --------------------------------------
   Oppidum module: localization

   Author: Stéphane Sire <s.sire@oppidoc.fr>

   Utility module to help import / export translations inside dictionary.xml

   Default mapping : /localization/dictoinary

   November 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

declare namespace site = "http://oppidoc.com/oppidum/site";

import module namespace util="http://exist-db.org/xquery/util";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../lib/util.xqm";

declare option exist:serialize "method=xml media-type=application/xml";

declare variable $local:dico := fn:doc('/db/www/ctracker/config/dictionary.xml')/site:Dictionary;

(: ======================================================================
   Exports dictionary as CSV using current database dictionary content
   ====================================================================== 
:)
declare function local:export ( $dico as element()? ) {
  let $data := tokenize(
    util:binary-to-string(util:binary-doc('/db/import/dictionary.csv')),
    codepoints-to-string((13))
    )
  return
    <table>
    {
    for $l in $data
    let $tokens := tokenize($l, ';')
    let $key := $tokens[3]
    let $truth := $dico/site:Translation[@key eq $key]
    let $found := exists($truth)
    let $same := $found and ($truth eq $tokens[4])
    where $tokens[1] ne 'Order'
    (:  where not(starts-with($tokens[3], '#')) :)
    return 
        <row found="{$found }" same="{ $same }">
            <Order>{ normalize-space($tokens[1]) }</Order> 
            <Formular>{ $tokens[2] }</Formular>
            <Key>{ $tokens[3] }</Key>
            <!--<Legacy>{ $truth/text() }</Legacy>-->
            <en>
                { 
                if ($found) then
                  if ($same) then
                    string($truth)
                  else if ($tokens[4]) then
                    $tokens[4]
                  else
                    string($truth)
                else 
                  $tokens[4]
                }
            </en>
            <fr>{ $tokens[5] }</fr>
            <de>{ $tokens[6] }</de>
        </row>
    }
    </table>
};

(: ======================================================================
   Returns table with missing keys
   ====================================================================== 
:)
declare function local:missing ( $dico as element()? ) {
  let $data := tokenize(
    util:binary-to-string(util:binary-doc('/db/import/dictionary.csv')),
    codepoints-to-string((13))
    )
  let $keys := distinct-values(
                for $l in $data
                let $tokens := tokenize($l, ';')
                return $tokens[3]
                )
  return
    <table>
    {
    for $t at $i in $dico/site:Translation
    let $key := string($t/@key)
    where not($key = $keys)
    return 
        <row>
          <Order>{ $i }</Order>
          <Formular>shared</Formular>
          <Key>{ $key }</Key>
          <en>{ $t/text() }</en>
        </row>
    }
    </table>
};

declare function local:import-key( $key as xs:string, $value as xs:string?, $lang as xs:string ) {
  let $clean := normalize-space($value)
  let $truth := $local:dico/site:Translations[@lang eq $lang]/site:Translation[@key eq $key]
  return
    element { $lang } {
      (
      if (empty($value) or $clean eq '') then
        attribute { 'res' } { 'void' }
      else if (empty($truth)) then (
        attribute { 'res' } { 'add' },
        update insert
          <site:Translation key="{ $key }" src="+cvs">{ $clean }</site:Translation>
        into $local:dico/site:Translations[@lang eq $lang]
        )
      else if ($truth eq $clean) then
        attribute { 'res' } { 'same' }
      else (
        attribute { 'res' } { 'update' },
          update replace $truth with
            <site:Translation key="{ $key }" src="cvs">{ $clean }</site:Translation>
        ),
      $value
      )
    }
};

(: ======================================================================
   Imports dictionary table
   ====================================================================== 
:)
declare function local:import ( $dico as element()? ) {
  let $data := tokenize(
    util:binary-to-string(util:binary-doc('/db/import/dictionary.csv')),
    codepoints-to-string((13))
    )
  let $languages := tokenize($data[1], ';')[position() > 3]
  return
    <table languages="{ string-join($languages, ', ')}">
    {
    for $l in $data
    let $tokens := tokenize($l, ';')
    let $key := $tokens[3]
    where $tokens[1] ne 'Order' and not(starts-with($tokens[3], '#')) and not(starts-with($tokens[3], 'ENGLISH ONLY'))
    group by $key
    return 
      let $master := head($l)
      let $total := count($l)
      let $toks :=  tokenize($master, ';')
      return
        <row count="{ $total }">
            <Order>{ normalize-space($tokens[1]) }</Order> 
            <Formular>{ $tokens[2] }</Formular>
            <Key>{ $key }</Key>
            {
            for $lang at $i in $languages
            return local:import-key($key, $toks[3 + $i], $lang)
          }
        </row>
      }
      </table>
};

let $m := request:get-method()
let $dico := fn:doc('/db/www/ctracker/config/dictionary.xml')//site:Translations[@lang eq 'en']
let $cmd := oppidum:get-command()
return
  if ($cmd/resource/@name eq 'export') then
    local:export($dico)
  else if ($cmd/resource/@name eq 'import') then
    local:import($dico)
  else if ($cmd/resource/@name eq 'missing') then
    local:missing($dico)
  else
    <site:view>
      <site:title>Oppidum message localization assistant</site:title>
      <site:content>
        <h1>Dictionary localization assistant</h1>
        <p>Copy your master dictionary CSV file to <code>/db/import/dictionary.csv</code> then use the links below to manage the application dictionary inside <code>/db/www/[application]/config/dictionary.xml</code> :</p>
        <ul>
          <li>export <a href="dictionary/export.csv">dictionary.csv</a> : generate a new master dictionary from the current content of the application dictionary with failover to the master dictionary; this is convenient to prepare a fresh master dictionary to be used for translations using external tools (i.e. a spreadsheet application)</li>
          <li><a href="dictionary/import">import.xml</a> : updates the application dictionary from the content of the master dictionary</li>
          <li><a href="dictionary/missing.csv">extras.csv</a> : generate a partial master dictionary from the current content of the application dictionary which is not available in the master dictionary; this is convenient to identify missing keys to complete a master dictionary</li>
        </ul>
      </site:content>
    </site:view>
