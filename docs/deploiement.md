Guide de déploiement d'une application réalisée avec Oppidum
============================================================

par Stéphane Sire (Oppidoc SARL)
le 13 février 2012

L'application Auteurs Platinn Focus est écrite en XQuery / XSLT / Javascript. Elle utilise le framework Oppidum, développé par Stéphane Sire (Oppidoc SARL), compatible avec la base de donnée eXist-DB 1.4.1 rev 15155 [[1][1]].

Le code et les données de l'application sont directement contenues dans la BD en production. Elles sont packagées sous la forme d'une archive .ZIP contenant le code et les données initiales. L'archive .ZIP s'installe dans la BD avec le client d'administration eXist. L'application fonctionne avec les modules standards de eXist-DB (le module image est activé par défaut dans le fichier conf.xml), donc pas besoin de modifier le fichier conf.xml par défaut de l'application. Vous pouvez par contre modifier le descripteur de déploiement web.xml pour supprimer des services inutilisés (comme WebDAV).

Instructions sommaires
----------------------

Pour déployer l'application en production : 

1. installer eXist-DB [[2][2]]

    1. sur le choix de la JVM noter cette remarque d'un développeur eXist : "please do not use an openjdk6 for existdb.... Prefer to use a std oracle JVM instead" [[3][3]]

    2. configurer le fichier controller-config.xml pour aller chercher le contrôleur de l'application dans la collection '/db/www/root' (mettre la ligne `<root pattern=".*" path="xmldb:exist:///db/www/root"/>`)

    3.  configurer le fichier conf.xml de eXist pour activer les modules XQuery optionnels (dans notre cas le seul module optionnel "images" est activé par défaut donc rien à faire)

    4.  configurer le fichier web.xml de eXist pour désactiver les éventuels servlets inutiles (ex. WebDAV)

    5.  ajuster les niveaux de log dans le fichier log4j.xml

    6.  augmenter la mémoire allouée à la JVM, nous recommandons 765Mo minimum (utiliser la variable d'environnement `JAVA_OPTIONS`, par défaut `JAVA_OPTIONS="-Xms128m -Xmx512m -Dfile.encoding=UTF-8"`)

2. lancer eXist-DB et utiliser le client d'administration [[4][4]] pour restaurer l'archive .ZIP de l'application (juste une contrainte: il vaut mieux utiliser le même mot de passe admin pour créer l'archive ZIP que celui de la BD sur laquelle s'effectue la restauration, donc communiquez le nous avant de manière à ce que nous packagions correctement l'archive .ZIP)

Pour l'étape 1 vous pouvez soit installer eXist en mode standalone (cf. [[5][5]], [[6][6]] et [[7][7]]), soit utiliser Tomcat. Si vous utilisez Tomcat, nous pouvons fournir un fichier .WAR contenant la BD eXist configurée pour l'application et duquel nous avons enlevé tout le superflu.

A noter que concernant le choix eXist en mode standalone ou eXist dans Tomcat, voici ce que recommande Dannes Wessels, l'un des développeurs de eXist-DB [[8][8]] :

For good reasons we do not recommend running exist-db for production in tomcat. The main risk is that you share memory with other applications, an out-of-memory exception can be fatal for eXist.

Besides, you miss all kind of nice tooling (e.g. recovery tooling) when running in Tomcat and alike.

Optimisations
-------------

### Utilisation d'un proxy pour servir les ressources statiques

En plus d'augmenter la sécurité de l'application [[5][5]], le proxy peut servir les ressources statiques. En production le framework Oppidum s'arrange en effet pour que toutes les URLs vers les ressources statiques (CSS, JS) soient de la forme:

    /static/{module}/reste-du-chemin-vers-ressources-statique

Avec {module} égal soit à "oppidum", soit au nom de l'application ("focus")

Par défaut, les ressources statiques sont servies par la BD (car elles sont dans les collections /db/www/{modules}/resources/), mais il est fortement recommandé de configurer le serveur Proxy (e.g. NGINX) pour servir directement ces ressources depuis :

    /{static}/{module}/reste-du-chemin-vers-ressources-statique

où {static} est un répertoire en dehors de l'application, accessible par FTP, où copier les fichiers des ressource statiques

### Backups 

Pour la sécurité il faut au minimum prévoir une backup périodique de tout le répertoire "data/" qui contient la base de donnée eXist et ses journaux (l'emplacement de ce répertoire est fixé dans un fichier conf.xml de eXist).

Nous recommandons de définir un répertoire "database/" en dehors de l'application, sur lequel l'application peut écrire et accessible par FTP. L'application contient en effet un tableau de bord qui permet de faire manuellement une backup sélective (et une restauration) de tout ou partie de la BD dans une archive .ZIP dans un répertoire externe. Nous utilisons cette procédure lors des mises à jour.

En option nous pouvons aussi configurer l'application pour effectuer périodiquement une backup dans une répertoire défini à l'avance (par exemple le répertoire "database/" ci-dessus). Dans ce cas vous pouvez prévoir un script qui efface les anciennes backups.

### Références

\[1\] [exist.sourceforge.net/download.html][1]  
\[2\] [exist.sourceforge.net/quickstart.html][2]  
\[3\] [markmail.org/message/22jscrhj63mwevtw][3]  
\[4\] [exist.sourceforge.net/client.html][4]  
\[5\] [exist.sourceforge.net/production\_web\_proxying.html][5]  
\[6\] [exist-open.markmail.org/thread/bwhv3c2rk7gpmfui][6]  
\[7\] [exist.sourceforge.net/production\_good\_practice.html][7]  
\[8\] [markmail.org/message/tm4saqgztsslaqkj][8]  

[1]: http://exist.sourceforge.net/download.html "exist.sourceforge.net/download.html"
[2]: http://exist.sourceforge.net/quickstart.html "exist.sourceforge.net/quickstart.html"
[3]: http://markmail.org/message/22jscrhj63mwevtw "markmail.org/message/22jscrhj63mwevtw"
[4]: http://exist.sourceforge.net/client.html "exist.sourceforge.net/client.html"
[5]: http://exist.sourceforge.net/production_web_proxying.html  "Production use - Proxying eXist behind a Web Server"
[6]: http://exist-open.markmail.org/thread/bwhv3c2rk7gpmfui "Installation d'eXist-DB sur Linux (date un peu)"
[7]: http://exist.sourceforge.net/production_good_practice.html "Production use - Good Practice"
[8]: http://markmail.org/message/tm4saqgztsslaqkj "markmail.org/message/tm4saqgztsslaqkj"
