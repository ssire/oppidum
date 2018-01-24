xquery version "1.0";
(: --------------------------------------
   Oppidum module: localization

   Author: Stéphane Sire <s.sire@oppidoc.fr>

   Utility module to help localize error and information messages.

   Default mapping : /localization/messages

   TODO :
   - complete with a module to extract a language placeholder file
   to be used with this tool for reintegration

   July 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

import module namespace util="http://exist-db.org/xquery/util";

declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=application/xml indent=yes";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../lib/util.xqm";

declare function local:gen-error() as element() {
  <error><message>Échec de la lecture des données XML fournies</message></error>
};

(: ======================================================================
   Merges two Oppidum errors or information message files in two languages
   ======================================================================
:)
declare function local:merge-messages($root-name as xs:string, $sample1 as element(), $sample2 as element())
{
  let $crlf := codepoints-to-string((13, 10))
  return
    element { $root-name } {
      for $rec in $sample1/(*|comment())
      return
        if ($rec instance of comment()) then
          (
          $crlf, "  ", $rec
          )
        else
          element { local-name($rec) } {
            (
            $rec/@*,
            (: test to replace existing translations :)
            for $m in $rec/*
            let $same := $sample2/*[@type eq string($rec/@type)]
            where not($same/*[string(@lang) = string($m/@lang)])
            return
              $m,
            $sample2/*[@type eq string($rec/@type)]/*
            )
          }
    }
};

(: ======================================================================
   Merges two Oppidum errors or information message files in two languages
   Limitation: $sample1 is the new master, it must contain definitions for 
   all languages because it does not recover legacy ones in case they are 
   missing
   ======================================================================
:)
declare function local:true-merge-messages($root-name as xs:string, $sample1 as element(), $sample2 as element())
{
  let $crlf := codepoints-to-string((13, 10))
  return
    element { $root-name } {
      for $legacy in $sample1/(*|comment())
      return
        if ($legacy instance of comment()) then
          (
          $crlf, "  ", $legacy
          )
        else
          let $new := ($sample2/*[@type eq string($legacy/@type)])[last()]
          return
            if ($new) then
              element { local-name($legacy) } {
                (
                $legacy/@*,
                for $m in $new/*
                let $same := $legacy/*[@lang eq string($m/@lang)]
                return
                  if ($m eq '') then
                    $same
                  else
                    $m
                )
              }
            else
              $legacy
    }
};

declare function local:gen-master( $name as xs:string, $tag as xs:string ) as element() {
    let $data := tokenize(
      util:binary-to-string(util:binary-doc(concat('/db/import/', $name, '.csv'))),
      codepoints-to-string((13))
      )
    let $languages := tokenize($data[1], ';')[position() > 1][. ne '']
    let $citation := concat('“', '%s', '”')
    return
      element { $name }
        {
        for $item in $data[position() > 1]
        let $tokens := tokenize($item, ';')
        let $key := normalize-space($tokens[1])
        return
          element { $tag }
            {
            attribute { 'type' } { $key },
            for $l at $i in $languages
            return
              <message lang="{ $l }">{ replace(replace($tokens[$i + 1], '"%s"', $citation), '"', '') }</message>
            }
        }
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
return
  if ($cmd/@action eq 'import') then
    let $name := request:get-parameter('t', 'errors')
    let $tag := if ($name eq 'errors') then 'error' else 'info'
    let $module := 'ctracker' (: use a parameter :)
    let $messages := fn:doc(concat("/db/www/", $module, "/config/", $name, ".xml"))/*[local-name(.) eq $name]
    return 
      (:$messages:)
      (:local:gen-master($name, $tag):)
      local:true-merge-messages($name, $messages, local:gen-master($name, $tag))
  else if ($m = 'POST') then
    let $module := request:get-parameter('module', 'oppidum')
    let $data := request:get-parameter('data', ())
    let $parsed := util:catch('*', util:parse($data), local:gen-error())
    let $submitted := $parsed/*[1]
    let $name := local-name($submitted)
    let $messages := fn:doc(concat("/db/www/", $module, "/config/", $name, ".xml"))/*[local-name(.) eq $name]
    return (
      util:declare-option("exist:serialize", "method=xml media-type=text/xml encoding=utf-8 indent=yes"),
      local:merge-messages($name, $messages, $submitted)
      )
  else
    <site:view>
      <site:title>Oppidum message localization assistant</site:title>
      <site:content>
        <h1>Message localization assistant</h1>
        <p>Copiez-collez vos traductions dans la langue de votre choix et appuyez sur "Intégrer" pour générer un nouveau fichier <tt>errors.xml</tt> ou <tt>messages.xml</tt> qui s'affichera dans une nouvelle fenêtre. L'élément racine de vos traductions détermine le choix du fichier à intégrer. L'intégration s'effectue avec les fichiers d'erreur ou de message d'information qui sont copiés dans la BD.</p>
        <form action="messages" method="post" enctype="multipart/form-data" accept-charset="UTF-8" target="_blank">
          <p><textarea id="data" name="data" style="width:100%;min-height:200px">&lt;messages>Copiez vos traductions ici&lt;/messages></textarea></p>
          <p>Application :
            <input type="text" name="module" value="oppidum"></input>
            <button type="submit">Intégrer</button>
          </p>
        </form>
        <hr/>
        <p>Copy your master error CSV file to <code>/db/import/errors.csv</code> then use the link below to manage the application error messages :</p>
        <ul>
          <li><a href="messages/import" target="_blank">import.xml?t=errors</a> : merges your master error CSV file with the application error messages (@code) and shows the XML file resulting in a new window that you can cut-and-paste to replace your application errors.xml</li>
        </ul>
        <p>Copy your master message CSV file to <code>/db/import/messages.csv</code> then use the link below to manage the application information messages :</p>
        <ul>
          <li><a href="messages/import" target="_blank">import.xml?t=messages</a> : merges your master information messages CSV file with the application information messages (@code) and shows the XML file resulting in a new window that you can cut-and-paste to replace your application information messages.xml</li>
        </ul>
      </site:content>
    </site:view>
