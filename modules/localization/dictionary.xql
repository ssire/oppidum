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

declare option exist:serialize "method=xml media-type=application/xml indent=yes";

declare variable $local:master-csv-dictionary-uri := '/db/import/dictionary.csv';
declare variable $local:fallback-csv-dictionary-uri := '/db/import/fallback.csv';
declare variable $local:dico := fn:doc('/db/www/ctracker/config/dictionary.xml')/site:Dictionary;

(: ======================================================================
   Return available site:Translations dictionaries
   ====================================================================== 
:)
declare function local:get-dictionaries( $app_name as xs:string ) as element()* {
  let $base-uri := concat('/db/www/', $app_name, '/')
  let $dico-uri := concat($base-uri, 'dictionary.xml')
  return
    if (fn:doc-available($dico-uri)) then
      fn:doc($dico-uri)//site:Translations
    else
      fn:collection(concat($base-uri, 'dictionaries'))//site:Translations
};

declare function local:check-csv( $languages as xs:string*, $uri as xs:string ) as element() {
  if (some $l in $languages satisfies string-length($l) > 2) then
    <error><message>invalid master csv file { $uri } (found { count($languages) } language keys)</message></error>
  else
    <success/>
};

declare function local:timestamp() {
  let $date := current-dateTime()
  return
    concat(
      substring($date,9,2), '/', substring($date,6,2), '/', substring($date,1,4),
      ' at ',
      substring($date,12,5)
      )
};

(: ======================================================================
   Removes extra double quotes introduced by CSV
   ====================================================================== 
:)

declare function local:cleanup( $s as xs:string ) {
  replace(
    replace(
      replace($s, '""', '"'),
      '^"', 
      ''),
    '"$',
    ''
  )
};

(: ======================================================================
   Export current appplication dictionaries to table row format 
   Export only keys available in the locale $driver_lang
   ====================================================================== 
:)
declare function local:plain_export ( $app_name as xs:string, $driver_lang as xs:string ) as element() {
  let $dicos := local:get-dictionaries($app_name)
  let $languages := for $d in $dicos order by number($d/@priority) return  $d/string(@lang)
  let $driver := $dicos[@lang eq $driver_lang]
  return
    <table languages="{ normalize-space(string-join($languages, ' ')) }">
      {
      for $l in $driver/site:Translation
      let $key := string($l/@key)
      (: TODO: document order or alphabetical order ? :)
      return 
        <row>
          <Key>{ $key }</Key>
          {
          for $l at $i in $languages
          let $term := $dicos[@lang eq $l]//site:Translation[@key eq $key]
          return
            element { $l } {
              $term/text()
            }
          }
        </row>
      }
    </table>
};

(: ======================================================================
   Find table entry using dummy <found> empty namespace request to avoid
   default namespace in XPath
   ====================================================================== 
:)
declare function local:get-translation-for( $key as xs:string, $lang as xs:string, $import-table as element() ) as xs:string? {
  let $found := <found>{  head($import-table/row[Key eq $key]/*[local-name() eq $lang]) }</found>
  return
    if (exists($found/*)) then
      normalize-space($found/*)
    else
      ()
};

(: ======================================================================
   Generates a dictionary.xml file (including comments) using :

   1) the same structure (incl. comments) and keys as defined in the 
      reference language (en) of the passed dictionary

   2) the values from the import table when available, with fallback 
      to the values from the passed dictionary, with fallback to the values
      from the import table in the reference language prefixed 
      with an annotation, with fallback to the values from the passed dictionary
      in the reference language prefixed with an annotation

   Use this with an empty import table to just regenerate the application 
   dictionary synchonized on the refence language.

   Set do-new to true to generate in addition all the keys from the import 
   table missing from the passed dictionary.

   FIXME: remove $fallback-dico
   ======================================================================
:)
declare function local:regenerate-dictionary( $dico as element(), $import-table as element(), $do-new as xs:boolean, $target-lang as xs:string )
{
  let $reference-lang := 'en'
  let $crlf := codepoints-to-string((13, 10))
  let $languages := tokenize($import-table/@languages, ' ')
  let $debug-new := if (exists(request:get-parameter('debug', ()))) then attribute { 'src' } { 'new' } else ()
  let $debug-fallback := if (exists(request:get-parameter('debug', ()))) then attribute { 'src' } { 'fallback' } else ()
  let $fallback-dico := fn:doc('/db/import/fallback.xml')/site:Dictionary
  return
    <Dictionary xmlns="http://oppidoc.com/oppidum/site">
      {
      for $l in $languages
      return
        <Translations lang="{ $l }">
          {
          for $legacy in $dico/Translations[@lang eq $reference-lang]/(*|comment())
          return
            if ($legacy instance of comment()) then
              (
              $crlf, "       ", $legacy
              )
            else
              let $new := local:get-translation-for($legacy/@key, $l, $import-table)
              return
                if ($new and $new != '') then
                  <Translation key="{ $legacy/@key }">{ $debug-new, $new }</Translation>
                else 
                  let $legacy-lang := $dico/Translations[@lang eq $l]/Translation[@key eq $legacy/@key][. ne '']
                  return 
                    if ($legacy-lang) then
                      $legacy-lang
                    else 
                      let $new-ref := local:get-translation-for($legacy/@key, 'en', $import-table)
                      return
                        <Translation key="{ $legacy/@key }">TRADUIRE : {if ($new-ref) then $new-ref else $legacy/text()}</Translation>,
            if ($do-new) then (
              (: introduces new keys from master :)
              concat($crlf, "        "),
              comment { "************************************************" }, concat($crlf, "        "),
              comment { concat(" New vocabulary imported on ", local:timestamp(), " ") }, concat($crlf, "        "),
              comment { "************************************************" }, $crlf,  
              let $keys := distinct-values($import-table/*/*[local-name() eq 'Key'])
              return
                for $k in $keys
                where not(starts-with($k, '#')) and not(starts-with($k, 'ENGLISH ONLY')) and empty($dico/Translations[@lang eq $reference-lang]/Translation[@key eq $k])
                return
                  let $new := local:get-translation-for($k, $l, $import-table)
                  return
                    if ($new) then
                      <Translation key="{ $k }">{ $debug-new, $new }</Translation>
                    else
                      let $fallback := $fallback-dico/Translations[@lang eq $l]//Translation[@key eq $k]
                      return
                        if ($fallback) then
                          <Translation key="{ $k }">{ $debug-fallback, normalize-space($fallback) }</Translation>
                        else
                          ()
              )
            else
              ()
          }
        </Translations>
      }
    </Dictionary>
};


(: ======================================================================
   Return a new dictionary file serialization where keys in $import-table
   overwrite corresponding key.  Add a final new section with extra keys. 
   ====================================================================== 
:)
declare function local:merge-master-with-dictionary( $app_name as xs:string, $import-table as element(), $target-lang as xs:string )
{
  let $dicos := local:get-dictionaries($app_name)
  let $reference := $dicos[@lang eq $target-lang]
  let $crlf := codepoints-to-string((13, 10))
  let $debug-new := if (exists(request:get-parameter('debug', ()))) then attribute { 'src' } { 'new' } else ()
  return
    <Dictionary xmlns="http://oppidoc.com/oppidum/site">
      {
      <Translations>
        {
        $reference/@lang,
        $reference/@priority,
        for $legacy in $reference/(*|comment())
        return
          if ($legacy instance of comment()) then
            (
            $crlf, "       ", $legacy
            )
          else
            let $new := local:get-translation-for($legacy/@key, $target-lang, $import-table)
            return
              if ($new and $new != '') then
                <Translation key="{ $legacy/@key }">{ $debug-new, $new }</Translation>
              else 
                $reference/Translation[@key eq $legacy/@key],

            (: introduces new keys from master :)
            concat($crlf, "        "),
            comment { "************************************************" }, concat($crlf, "        "),
            comment { concat(" New vocabulary imported on ", local:timestamp(), " ") }, concat($crlf, "        "),
            comment { "************************************************" }, $crlf,  
            let $keys := distinct-values($import-table/*/*[local-name() eq 'Key'])
            return
              for $k in $keys
              where not(starts-with($k, '#')) and not(starts-with($k, 'ENGLISH ONLY')) and empty($reference/Translation[@key eq $k])
              return
                let $new := local:get-translation-for($k, $target-lang, $import-table)
                return
                  if ($new) then
                    <Translation key="{ $k }">{ $debug-new, $new }</Translation>
                  else
                    ()
        }
      </Translations>
      }
    </Dictionary>
};

(: ======================================================================
   Creates a master dictionary table to export to CSV taking keys
   from imported master dictionary and values from current application dictionray
   ====================================================================== 
:)
declare function local:regenerate_master () {
  let $data := tokenize(
    util:binary-to-string(util:binary-doc('/db/import/dictionary.csv')),
    codepoints-to-string((13))
    )
  let $languages := tokenize($data[1], ';')[position() > 3][. ne '']
  let $fallback := fn:doc('/db/import/fallback.xml')/site:Dictionary
  let $check-csv := local:check-csv($languages, '/db/import/dictionary.csv')
  return
    if (local-name($check-csv) eq 'success') then
      <table languages="{ normalize-space(string-join($languages, ' ')) }">
      {
      for $l in $data
      let $tokens := tokenize($l, ';')
      let $key := $tokens[3]
      where $tokens[1] ne 'Order'
      (:  where not(starts-with($tokens[3], '#')) :)
      return 
        <row>
          <Order>{ normalize-space($tokens[1]) }</Order> 
          <Formular>{ $tokens[2] }</Formular>
          <Key>{ $tokens[3] }</Key>
          {
          for $l at $i in $languages
          let $tmp := $tokens[3 + $i]
          let $cur := $local:dico/site:Translations[@lang eq $l]/site:Translation[@key eq $key][. ne '']
          return
            element { $l } {
              if ($cur) then
                $cur/text()
              else
                ()
            }
          }
        </row>
      }
      </table>
    else
      $check-csv
};

(: ======================================================================
   Return /db/import/dictionary.csv to table format
   Can read two types of tables :
     Order, Formular, Key, en, fr, etc
     or 
     Key, en, fr, etc
   ====================================================================== 
:)
declare function local:csv2table ( $name as xs:string) {
  let $master-csv-uri := concat('/db/import/', $name)
  let $data := tokenize(
    util:binary-to-string(util:binary-doc($master-csv-uri)),
    codepoints-to-string((13))
    )
  let $languages := tokenize($data[1], ';')[not(. = ('', 'Order', 'Key'))]
  let $check-csv := local:check-csv($languages, $master-csv-uri)
  let $skip := if (tokenize($data[1], ';') = 'Order') then 2 else 0
  return
    if (local-name($check-csv) eq 'success') then
      <table languages="{ normalize-space(string-join($languages, ' ')) }">
      {
      for $l in $data
      let $tokens := tokenize($l, ';')
      let $key := $tokens[1 + $skip]
      where not($tokens[1] = ('Order', 'Key')) and not(starts-with($tokens[1 + $skip], '#')) and not(starts-with($tokens[1 + $skip], 'ENGLISH ONLY'))
      return 
        <row>
          {
          if ($skip eq 2) then (
            <Order>{ normalize-space($tokens[1]) }</Order>,
            <Formular>{ $tokens[2] }</Formular>
            )
          else
            ()
          }
          <Key>{ normalize-space($tokens[$skip + 1]) }</Key>
          {
          for $l at $i in $languages
          let $tmp := $tokens[$skip + 1 + $i]
          let $new := if (exists($tmp) and normalize-space($tmp) ne '') then normalize-space($tmp) else ()
          return
            element { $l } {
              if ($new) then
                local:cleanup($new)
              else (: no translation available :)
                ()
            }
          }
        </row>
      }
      </table>
    else
      $check-csv
};

(: ======================================================================
   Returns dictionary table containing one row for every key in the driver
   language of the application dictionary passed as parameter which is not 
   defined in the master dictionary CSV file. 

   FIXME: to be removed : Completes using a fallback dictionary when available

   This is useful when developers create new keys in the application 
   dictionary and you want to add them to the master CSV dictionary
   ====================================================================== 
:)
declare function local:missing ( $app_name as xs:string, $driver_lang as xs:string ) as element() {
  let $dico := fn:doc(concat('/db/www/', $app_name, '/config/dictionary.xml'))/site:Dictionary
  let $data := tokenize(
    util:binary-to-string(util:binary-doc($local:master-csv-dictionary-uri)),
    codepoints-to-string((13))
    )
  let $languages := tokenize($data[1], ';')[. ne ''][position() > 3]
  let $check-csv := local:check-csv($languages, $local:master-csv-dictionary-uri)
  return
    if (local-name($check-csv) eq 'success') then
      let $keys := distinct-values(
                    for $l in $data
                    let $tokens := tokenize($l, ';')
                    return $tokens[3]
                    )
      let $fallback := fn:doc($local:fallback-csv-dictionary-uri)/site:Dictionary
      let $total-master := count($keys[not(starts-with(., '#'))])
      let $total-extra := count(for $k in $keys where count($dico/site:Translations[@lang eq $driver_lang]/site:Translation/@key = $k) eq 0 return $k)
      let $truth := $dico/site:Translations[@lang eq $driver_lang]/site:Translation/@key
      let $total-dico := count($truth)
      let $total-unique-dico := count(distinct-values($truth))
      return
        <table languages="{ $languages }" masterExtra="{$total-extra}" masterUniqueKeys="{ $total-master }" dicoUniqueKeys="{ $total-unique-dico }" dicoTotal="{ $total-dico }">
        {
        for $t at $i in $dico/site:Translations[@lang eq $driver_lang]/site:Translation
        let $key := string($t/@key)
        where not($key = $keys)
        return 
          <row>
            <Order>-</Order>
            <Formular>-</Formular>
            <Key>{ $key }</Key>
            {
            for $l in $languages
            let $found := $dico/site:Translations[@lang eq $l]/site:Translation[@key eq $key]
            let $fallback := $fallback/site:Translations[@lang eq $l]/site:Translation[@key eq $key]
            return
              element { $l } {
                if ($found) then
                  $found/text()
                else if ($fallback) then
                  $fallback/text()
                else
                  ()
              }
            }
          </row>
        }
        </table>
    else
      $check-csv
};

let $m := request:get-method()
let $dico := fn:doc('/db/www/ctracker/config/dictionary.xml')//site:Translations[@lang eq 'en']
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
let $target-lang := request:get-parameter('lang', 'en')
let $mode := request:get-parameter('m', 'run')
return
  if ($cmd/resource/@name eq 'regenerate') then
    let $empty-import := <table languages="en fr de"/>
    return
      local:regenerate-dictionary(fn:doc('/db/www/ctracker/config/dictionary.xml')/site:Dictionary, $empty-import, false(), $lang)
  else if ($cmd/resource/@name eq 'merge') then
    let $import-table := local:csv2table ('dictionary.csv')
    return
      if (local-name($import-table) eq 'table' and $mode ne 'table') then
        local:merge-master-with-dictionary('ctracker', $import-table, $target-lang)
      else
        $import-table
  else if ($cmd/resource/@name eq 'export') then
    local:regenerate_master () 
  else if ($cmd/resource/@name eq 'missing') then
    local:missing('ctracker', 'en')
  else if ($cmd/resource/@name eq 'convert') then
    local:plain_export('ctracker', $target-lang)
  else
    <site:view>
      <site:title>Oppidum dictionary localization assistant</site:title>
      <site:content>
        <h1>Dictionary localization assistant</h1>
        <p>Copy your <b>master dictionary CSV file</b> (<i>a CSV file with dictionary Key in first column and one column per localisation</i>) to <code>/db/import/dictionary.csv</code> then use the links below to manage the <b>application dictionary</b> inside <code>/db/www/[application]/config/dictionary.xml</code>.</p>

        <dl>
          <dt>Convert appplication dictionary to a CSV file</dt>
          <dd><a href="dictionary/convert.csv?lang=en">dictionary.csv?lang=en</a> turns the application dictionary into a <b>dictionary CSV file</b>. The keys are taken from the reference language lang.</dd>
        
          <dt>Generate application dictionary for lang with master dictionary updated keys</dt>
        <dd><a href="dictionary/merge?lang=en">merge.xml?lang=en</a> take the master dictionary CSV file available into <code>/db/import/dictionary.csv</code> as a reference and generate a new <b>application dictionary</b> file. The generated file has the same keys as the current dictionary of the application but their value is overwritten from the master dictionary if available. If the master CSV file contains more keys than the application dictionary, they will be added at the end after a special timestamped XML commentary. You can then copy back the generated file in your code depot and deploy it into the application. This script is useful to import back translatations done with a spreadsheet.</dd>
        </dl>

        <br/><b>TODO : to be fixed to work with 1 dictionary file per language</b>
        
        <dl>
          <dt>Regenerate application dictionary</dt>
          <dd><a href="dictionary/regenerate">dictionary.xml</a> regenerate a new <b>application dictionary</b> file using english localizations as a reference. Typical use is to update the dictionary in the reference language only then use this script to generate a complete file. Missing keys in the other languages will be added with an annotation (e.g. a <i>TRANSLATE :</i> prefix). You can then copy back the generated file in your code depot and deploy it into the application and use the other scripts to export it out for translation (e.g. using a spread sheet).</dd>

          <dt>Export master dictionary CSV file</dt>
          <dd><a href="dictionary/export.csv">dictionary.csv</a> generate a new <b>master dictionary CSV file</b> from the reference one available into <code>/db/import/dictionary.csv</code>. The generated file contains the keys from the reference file but the values from the current dictionary of the application. This script is useful to prepare a fresh master dictionary CSV file to be used for translations using external tools (i.e. a spreadsheet application).</dd>

          <dt>Export missing keys</dt>
          <dd><a href="dictionary/missing.csv">missing.csv</a> generate a <b>master dictionary CSV file</b> containing all the keys from the application dictionary which are actually not included in the reference master CSV dictionary file available into <code>/db/import/dictionary.csv</code>.</dd>


        </dl>
        <p>A typical localization workflow is :</p>
        <ol>
          <li>Convert appplication dictionary to a CSV file</li>
          <li>Take whole or parts of this file and translate it</li>
          <li>Upload this file as a master dictionary inside <code>/db/import/dictionary.csv</code></li>
          <li>Generate a new application dictionary for each lang with master dictionary updated keys and copy them back to your code depot to update translations</li>
        </ol>
      </site:content>
    </site:view>
