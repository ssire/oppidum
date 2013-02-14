xquery version "1.0";
(: -----------------------------------------------
   Oppidum maintenance screen

   Author: Stéphane Sire <s.sire@contact.fr>

   Returns a page that tells maintenance is in progress. To be used from 
   a temporary controller.xql file while (re-)installing an application.

   February 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare option exist:serialize "method=html media-type=text/html";
<html>
  <style type="text/css" media="screen">
body {{
  margin: 2em auto ;
  width: 400px;
}}
body p {{
  text-align: center;
}}
  </style>
  <body>
    <h1>Site en cours de maintenance</h1>
    <p>Nous sommes en train de mettre à jour le site</p>
    <p>Merci de revenir plus tard</p>
  </body>
</html>
