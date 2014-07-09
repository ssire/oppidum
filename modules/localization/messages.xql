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

declare option exist:serialize "method=html media-type=text/html";

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

let $m := request:get-method()
return
  if ($m = 'POST') then
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
    <html>
    <head>
    </head>
    <body>
    <h1>Oppidum Assistant de Localisation</h1>
    <p>Copiez-collez vos traductions et appuyez sur "Intégrer" pour générer un nouveau fichier <tt>errors.xml</tt> ou <tt>messages.xml</tt> qui s'affichera dans une nouvelle fenêtre. L'élément racine de vos traductions détermine le choix du fichier à intégrer. L'intégration s'effectue avec les fichiers d'erreur ou de message d'information qui sont copiés dans la BD.</p>
    <form action="messages" method="post" enctype="multipart/form-data" accept-charset="UTF-8" target="_blank">
      <p><textarea id="data" name="data" style="width:100%;min-height:200px">Copiez vos traductions ici</textarea></p>
      <p>Application :
        <input type="text" name="module" value="oppidum"></input>
        <button type="submit">Intégrer</button>
      </p>
    </form>
    </body>
    </html>
