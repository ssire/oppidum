xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum framework skin

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Utility function to generate <link> and <script> tags 
   from on a skin.xml configuration file

   July 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.  
   ------------------------------------------------------------------ :)

module namespace skin = "http://oppidoc.com/oppidum/skin";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "util.xqm";
import module namespace epilogue = "http://oppidoc.com/oppidum/epilogue" at "epilogue.xqm";

declare function skin:_script-error( $msg as xs:string ) as element()
{
  <script type="text/javascript" data-error="true">window.console.log('{$msg}')</script>
};

declare function skin:_css-link( $link as element(), $base as xs:string ) as node()*
{
  if (starts-with($link/@href, '[')) then (: conditional link inside comment for IE :)
    let $cond := substring-before($link/@href, ']')
    let $path := substring-after($link/@href, ']')
    return
      comment { concat($cond, ']><link  href="', $base, $path, '" type="text/css" charset="utf-8" /><![endif]') }
  else
    <link>
      {
      if (starts-with($link/@href,'http')) then $link/@href else attribute { 'href' } { concat($base, $link/@href) },
      if ($link/@rel) then $link/@rel else attribute { 'rel' } { 'stylesheet' },
      if ($link/@type) then $link/@type else attribute { 'type' } { 'text/css' }
      }
    </link>
};

declare function skin:_js-link( $script as element(), $cmd as element(), $base as xs:string ) as node()*
{
  if ($script/@resource) then (: script element pulled from database :)
    let $src := concat($cmd/@confbase,'/',$script/@resource)
    let $code := doc($src)/xhtml:script
    return
      if ($code) then
        $code
      else
        let $msg := concat('script "', $src, '" not found')
        return
          skin:_script-error($msg)
  else
    <script>
      {
      if ($script/@src) then 
        if (starts-with($script/@src,'http')) then $script/@src else attribute { 'src' } { concat($base, $script/@src) } 
      else 
        (),
      $script/@data-bundles-path,
      attribute { 'type' } { 'text/javascript' }, 
      if (not($script/@src)) then 
        $script/text()
      else
        '//'
      }
    </script>
};

declare function skin:_eval-condition( $str as xs:string, $cmd as element(), $tokens as xs:string* ) as xs:boolean*
{
  for $t in tokenize($str, '\s+')
  let $p := if (contains($t, '(')) then substring-before($t, '(') else $t
  let $a := if (contains($t, ')')) then substring-before(substring-after($t, '('), ')') else ''
  return 
    (: predicates evaluation :)
    if ($p = 'mode') then 
      string($cmd/@mode) = $a
    else if ($p = 'error') then 
      oppidum:has-error()
    else if ($p = 'message') then 
      oppidum:has-message()
    else if (($p = 'trail') and $a) then
      matches($a, $cmd/@trail)
    else if (($p = 'skin') and $a) then 
      $tokens = $a
    else
      false()
};

declare function skin:_test-condition( $item as element(), $cmd as element(),$tokens as xs:string* ) as xs:boolean
{
  let $meet := not($item/@meet) or (skin:_eval-condition(string($item/@meet), $cmd, $tokens) = true())
  let $avoid := not($item/@avoid) or not(skin:_eval-condition(string($item/@meet), $cmd, $tokens) = true())
  return
    $meet and $avoid
};

declare function skin:_gen-profile ( 
  $profile as element(), 
  $cmd as element(), 
  $base as xs:string, 
  $tokens as xs:string* ) as node()*
{
  for $item in $profile/*
  where skin:_test-condition($item, $cmd, $tokens)
  return 
    if (local-name($item) = 'link') then
      skin:_css-link($item, $base)
    else if (local-name($item) = 'script') then
      skin:_js-link($item, $cmd, $base)
    else 
      $item (: should be expanded in phase II :)
};

declare function skin:_render-profiles( $pkg as xs:string, $profiles as element()*, $tokens as xs:string* ) as node()*
{
  let $cmd := request:get-attribute('oppidum.command')
  let $base := epilogue:make-static-base-url-for($pkg)
  return
    for $p in $profiles
    return 
      if ($p/@missing) then 
        skin:_script-error(concat('profile "', $p/@missing, '" not found'))
      else 
        skin:_gen-profile($p, $cmd, $base, $tokens)
};

declare function skin:_gen-skin-I( $pkg as xs:string, $mesh as xs:string?, $tokens as xs:string* ) as node()*
{
  let $skin := doc(concat('/db/www/', $pkg, '/config/skin.xml'))/skin
  let $mprofdef := $skin/profile[(@type = 'mesh') and (@name = '*')]
  let $mprof := 
    if ($mesh) then 
      let $found := $skin/profile[(@type = 'mesh') and (@name = $mesh)]
      return
        if ($found) then $found else <profile missing="{$mesh} (mesh)"/>
    else 
      ()
  let $profdef := $skin/profile[not(@type) and (@name = '*')]
  let $prof := 
    for $n in $tokens
    let $found := ($skin/profile[not(@type) and ($n = @name)])
    return
      if ($found) then $found else <profile missing="{$n}"/>
  return
    let $all := ($mprofdef, $mprof, $profdef, $prof)
    return skin:_render-profiles($pkg, $all, $tokens)
};

declare function skin:_gen-skin-II( $pkg as xs:string, $names as xs:string*, $tokens as xs:string* ) as node()*
{
  if (count($names) > 0) then
    let $skin := doc(concat('/db/www/', $pkg, '/config/skin.xml'))/skin
    let $profiles := 
      for $n in $names
      let $found := $skin/profile[(@type = 'predef') and ($n = @name)]
      return
        if ($found) then $found else <profile missing='{$n} ("{$pkg}" predef)'/>
    return
      skin:_render-profiles($pkg, $profiles, $tokens)
  else 
    ()
};

declare function skin:gen-skin( $pkg as xs:string, $mesh as xs:string?, $skin as xs:string? ) as node()*
{
  let $tokens := if ($skin) then tokenize($skin, '\s+') else ()
  let $pass1 := skin:_gen-skin-I($pkg, $mesh, $tokens)
  let $pass2 := 
      (
      skin:_gen-skin-II($pkg, $pass1[(local-name(.) = 'predef') and not(@module)]/text(), $tokens),
      for $mod in distinct-values($pass1/@module)
      let $items := $pass1[@module = $mod]/text()
      return 
        skin:_gen-skin-II($mod, $items, $tokens)
      )
  return (: returns link elements before script elements :)
    (
    $pass2[local-name(.) = 'link'],
    $pass1[local-name(.) = 'link'],
    $pass2[local-name(.) = 'script'],
    $pass1[local-name(.) = 'script'],
    $pass2[./self::comment()],
    $pass1[./self::comment()]
    )
};