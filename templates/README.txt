Oppidum filter.xsl
==================

Sample templates filer

The original script has been written by S. Sire <s.sire@oppidoc.fr>

April 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.

DESCRIPTION
-----------

AXEL 'photo' plugin uses a "photo_URL" parameter to give the URL where to submit photos. It also uses a "photo_base" parameter to prefix the reference returned by the upload script to construct the src attribute of the img tag used to display the uploaded photo.

The purpose of the filter.xsl script is to rewrite the "photo_URL" and "photo_base" parameters so that they point to correct URLs as defined per the application's Oppidum mapping and execution context (servlet context).

It MUST be placed in the "templates" collection of an Oppidum application. Then it will be called for any template served by the "oppidum:model/templates.xql" model.

By default is copies the tempalte. It's filtering actions are triggered by some specific parameters of the template GET request.

The "?photo-rewrite=1" parameter instructs the filter to rewrite the "param" attribute of any <xt:use> or <xt:attribute> element that uses the 'photo' plugin.

If a "photo_URL" value inside the template is an absolute path (e.g. "param='photo_URL=/images'"), then the filter script will add Oppidum command's base-url (let's call it ${base-url}) in front of the path. 

If a "photo_URL" value is not an absolute path, then it's value will be entirely replaced by the "{$base-url}/images" path.

Similarly if a "photo-base" plugin parameter inside the template has an asbolute path it will be rewritten the same way. If it is not an absolute path or if it is not present, it will be replaced / generated with the "{$base-url}" path.

In addition, the optionnal "?photo-base=/path" request parameter is added right after {$base-url} when rewriting "photo_URL" and "photo_base". 

This way it is possible to precisely relocate the template photo plugin to use any collection in the application's mapping without having to write several versions of the template.

NOTE: the presence of photo-base implies photo-rewrite=1

SYNOPSIS
--------

For exemple if you declare : 

<item .. template="templates/foobar?photo-rewrite=1?photo-base=files">
..
<item name="templates" collection="templates"> 
  <model src="oppidum:models/templates.xql"/>
  <item name="foobar" collection="templates" resource="foobar-fr.xhtml">
   <model src="oppidum:models/template.xql"/>
  </item>
</item>

The following declaration inside foobar-fr.xhtml:

<xt:use types="photo" param="photo_URL=images"/>

will be replaced by (if current $base-url is "/exist/projets/demo")

<xt:use types="photo" param="photo_URL=/exist/projets/demo/files/images;photo_base=/exist/projets/demo/files"/>

for instance this supposes you have configured the mapping to handle the "/files/images" collection with oppistore image module.


TO BE DONE
----------

We plan to add a "photo_collection=images" argument to serve the template, to give a custom name to the collection that contains the images.

