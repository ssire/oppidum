xquery version "1.0";   
(: --------------------------------------
   UAP Web Site : photo upload controller    

   Author: Stéphane Sire <s.sire@free.fr>
   
   Manages photo upload
   
   !!! Due to an eXist bug, it is not possible yet to pass parameter trough request's parameters. 
   Request's attributes are used instead.
   
   DEPRECATED: use Oppistore images module instead
   
   March 2011
   -------------------------------------- :)

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace image = "http://exist-db.org/xquery/image";
import module namespace text="http://exist-db.org/xquery/text";
import module namespace util="http://exist-db.org/xquery/util";

(: This is the accepted format :)
declare variable $accepted-mime-types := ('image/jpeg', 'image/png', 'image/tiff', 'image/gif');
declare variable $pmaxwidth := 192;
declare variable $pmaxheight := 192;
declare variable $lmaxwidth := 280;
declare variable $lmaxheight := 156;

declare function local:get-extension( $file-name as xs:string ) as xs:string
{
  let $unparsed-extension := lower-case( (analyze-string($file-name, '\.(\w+)')//fn:group)[2] )
  return 
    replace(replace($unparsed-extension, 'jpg', 'jpeg'), 'tif', 'tiff')
};  

(:
  Checks MIME-TYPE is a compatible image type.
  Returns 'ok' or an error message.
:)
declare function local:check-mime-type( $mime-type as xs:string ) as xs:string
{
  if ( empty(fn:index-of($accepted-mime-types, $mime-type)) ) 
  then concat('Les images format ', $mime-type, ' ne sont actuellement pas supportées')
  else 'ok'
};            

(:
  Returns a number to be used for generating a file name to store 
  uploaded data into the collection ($col-uri) associated with the current item. 
  Returns the first number after the bigger number used to name a file inside
  the collection.
:)
declare function local:get-free-resource-name( $col-uri as xs:string )
  as xs:integer 
{
  let $files := xdb:get-child-resources($col-uri)
  return 
    if (count($files) = 0) then
       1
    else 
      max(for $name in $files
          let $nb := analyze-string($name, '((\d+)\.\w{2,5})$')//fn:group[3]
          return 
          xs:integer($nb)) + 1
};

(: 
   WARNING: as we use double-quotes to generate the Javascript string
   do not use double-quotes in the $msg parameter !
":)
declare function local:gen-error( $msg as xs:string ) as element() {
  let 
    $exec := response:set-header('Content-Type', 'text/html')      
  return
    <html>
      <body>
        <script type='text/javascript'>window.parent.finishTransmission(0, "{$msg}")</script>
     </body>
    </html>      
};

(:<script type='text/javascript'>window.parent.finishTransmission(1, {{url: "{$full-path}{$id}.{$ext}", resource_id: "{$id}"}})</script>:)
declare function local:gen-success( $id as xs:integer, $ext as xs:string ) as element() {
  let 
    $full-path := 'images/',
    $exec := response:set-header('Content-Type', 'text/html')      
  return
    <html>
      <body>
        <script type='text/javascript'>window.parent.finishTransmission(1, "{$full-path}{$id}.{$ext}")</script>
     </body>
    </html>
};

(:::::::::::::  BODY  ::::::::::::::)

let 
  $cmd := request:get-attribute('oppidum.command'),
  $col-uri := concat($cmd/resource/@db, '/', $cmd/resource/@collection),
  $user := xdb:get-current-user(), 
  $group := 'site-member'
return
  (: get uploaded photo binary stream :)
  let $data := request:get-uploaded-file-data('xt-photo-file')
  return        
    if (not($data instance of xs:base64Binary)) 
    then local:gen-error('Le fichier téléchargé est invalide')
    else
      
      (: check photo binary stream has compatible MIME-TYPE :)        
      let $filename := request:get-uploaded-file-name('xt-photo-file'),
        $extension := local:get-extension($filename),
        $mime-type := concat('image/', $extension),
        $mime-check := local:check-mime-type($mime-type)
      return                            
        if ( $mime-check != 'ok' ) 
        then local:gen-error($mime-check)
        else 
        
          if (not(xdb:collection-available($col-uri)))
          then local:gen-error("Erreur sur le serveur: pas de collection pour recevoir l'image")
          else
          
            (: scale and store the uploaded image file :)
            let 
              $image-id := local:get-free-resource-name($col-uri),
              $image-name := concat($image-id, '.', $extension),           
              $scaled-image := $data
  (:            $width := image:get-width($data),
              $height := image:get-height($data),             
              $target-size := if ($is-double) then ($pmaxheight*2, $pmaxwidth*2) else if ($filetype = 'logo') then ($lmaxheight, $lmaxwidth) else ($pmaxheight, $pmaxwidth),
              $need-scaling := if ($filetype = 'logo') then if (($width > $lmaxwidth) or ($height > $lmaxheight)) then true() else false() else true(),
              $scaled-image := if ($need-scaling) then image:scale($data, $target-size, $mime-type) else $data
  :)          return   
          
              if ($scaled-image instance of xs:base64Binary) then (               
  (:              util:log-app('info', 'webapp.site', concat('Saving ', $image-name, ' mime type and size: ', $mime-type, ' [', $width, 'px, ', $height, 'px]', 'scaled :', $need-scaling)),
  :)              xdb:store($col-uri, $image-name, $scaled-image, $mime-type),
                  xdb:set-resource-permissions($col-uri, $image-name, $user, $group, util:base-to-integer(0774, 8)),
                  local:gen-success($image-id, $extension)
                )[last()]      
              else  
                local:gen-error("Erreur pendant la remise à l'échelle de l'image, réessayez avec une autre")    
                