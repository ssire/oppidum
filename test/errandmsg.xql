xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum errors and messages utility

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Script to quickly display and test application errors and messages

   August 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Returns a list of errors type and status code
   ======================================================================
:)
declare function local:gen-errors( $doc-uri as xs:string ) {
  for $item in fn:doc($doc-uri)/errors/error
  return
    <Error>
      <Type>{string($item/@type)}</Type>
      <Code>{
        if ($item/@code) then
          string($item/@code)
        else
          'MISSING'
      }
      </Code>
    </Error>
};

(: ======================================================================
   Returns a list of messages type dans optional status code
   ======================================================================
:)
declare function local:gen-messages( $doc-uri as xs:string ) {
  for $item in fn:doc($doc-uri)/messages/info
  return
    <Message>
      <Type>{string($item/@type)}</Type>
      <Code>{
        if ($item/@code) then
          string($item/@code)
        else
          '---'
      }
      </Code>
    </Message>
};

let $cmd := request:get-attribute('oppidum.command')
let $code := request:get-parameter('code',())
let $app := request:get-parameter('app', 'oppidum')
let $res-uri := if ($cmd/resource/@name eq 'errors') then
                  concat('/db/www/', $app, '/config/errors.xml')
                else
                  concat('/db/www/', $app, '/config/messages.xml')

(: Actually throws error or message if test condition :)
let $thrown :=  if ($code) then
                  (
                  (: TRICKY : fakes Oppidum command to contain the target confbase :)
                  request:set-attribute('oppidum.command',
                    <command>
                      {(
                       $cmd/@*[local-name(.) ne 'confbase'],
                       attribute confbase { concat('/db/www/', $app) }
                      )}
                    </command>),
                  if ($cmd/resource/@name eq 'errors') then
                    oppidum:throw-error($code, ("#1", "#2", "#3", "#4", "#5"))
                  else
                    oppidum:throw-message($code, ("#1", "#2", "#3", "#4", "#5")),
                  request:set-attribute('oppidum.command', $cmd)
                  )
                else
                  ()

return
  if (($cmd/@format eq 'xml') and $code) then (: ajax test condition :)
    $thrown
  else
    <Display Type="{$cmd/resource/@name}" Resource="{$res-uri}" Application="{$app}">
      {(
      (: devtools way to simulate errors from another application inside oppidum application :)
      request:set-attribute('devtools.confbase', concat('/db/www/', $app)),
      $thrown,
      if ($cmd/resource/@name eq 'errors') then
        local:gen-errors($res-uri)
      else
        local:gen-messages($res-uri)
      )}
    </Display>
