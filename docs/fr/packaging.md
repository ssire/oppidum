Packager et déployer une application avec Oppidum
===

Par Stéphane Sire (Oppidoc), <s.sire@oppidoc.fr>, Janvier 2013

Le développement de l'application s'effectue directement avec la configuration par défaut d'eXist qui fonctionne avec le serveur d'application Jetty. Pour la mise en production vous pouvez au choix conserver celle-ci (cf. [mail](http://exist-open.markmail.org/thread/bwhv3c2rk7gpmfui)) ou bien utiliser un autre serveur d'application tel que Tomcat. Dans ce dernier cas il faut générer un fichier WAR contenant eXist-DB et des archives ZIP contenant Oppidum, le code de votre application et les données de votre application.

Ce document est basé sur l'utilisation de eXist 1.4.x, il est en cours de mis à jour pour eXist-2.0.

À noter que concernant le choix eXist en mode standalone ou eXist dans Tomcat, voici ce que recommande Dannes Wessels, l'un des développeurs de eXist-DB ([mail](http://markmail.org/message/tm4saqgztsslaqkj)) :

  > For good reasons we do not recommend running exist-db for production in tomcat. The main risk is that you share memory with other applications, an out-of-memory exception can be fatal for eXist.
  > Besides, you miss all kind of nice tooling (e.g. recovery tooling) when running in Tomcat and alike.

Configuration
-------------

Les fichiers suivants sont déterminants pour la configuration de eXist :

* `web.xml` : choix des servlets, vous pouvez en désactiver un certain nombre en production (e.g. WebDAV)
* `controller-config.xml` : pointe vers le fichier `controller.xql` lui même point d'entrée pour traiter les requêtes de l'utilisateur et interpréter les URLs
* `conf.xml` : choix des modules XQuery activés, suivant les cas vérifiez bien que certains modules optionnels sont activés (e.g. images ou mail)
* `log4j.xml` : niveaux de log

Attention ces fichiers sont situés à des emplacements différents suivant que l'on utilise eXist en standalone (configuration par défaut sous Jetty) ou que l'on fabrique un fichier WAR pour exécuter l'application sous tomcat.

Par ailleurs il peut être nécessaire de toucher aux paramètres suivants :

1. sur le choix de la JVM noter cette remarque d'un développeur eXist : _"please do not use an openjdk6 for existdb.... Prefer to use a std oracle JVM instead"_ ([mail](http://markmail.org/message/22jscrhj63mwevtw))

2. augmenter la mémoire allouée à la JVM (utiliser la variable d'environnement `JAVA_OPTIONS`, par défaut `JAVA_OPTIONS="-Xms128m -Xmx512m -Dfile.encoding=UTF-8"`)

### Configuration en développement 

Elle ne nécessite pas de modification par rapport à la configuration par défaut de eXist, sauf si vous utilisez des modules optionnels non activés par défaut (cf. le fichier `conf.xml`).

Le script `scripts/start.sh` permet de démarrer eXist directement depuis le répertoire d'Oppidum. Le script `scripts/stop.sh` permet de l'arrêter (n'oubliez pas de mettre à jour le mot de passe _admin_ de la BD dans le script).

### Configuration en production

En production Oppidum et l'application sont placés dans la BD plutôt que dans le système de fichier. Il faut alors modifier le fichier `controller-config.xml` pour qu'il pointe vers le contrôleur situé dans `xmldb:exist:///db/www/root` (cf. ci-dessous _Génération du fichier WAR_) :

Nous conseillons vivement de désactiver les servlets inutiles (ex. WebDAV) dans le fichier `web.xml`. Nous conseillons vivement de mettre tous les niveaux de log sur "error" dans le fichier `log4j.xml`.

A noter qu'en production il faut aussi couper l'accès à l'API REST de eXist qui est par ailleurs nécessaire pour exécuter l'application depuis la base de données. Pour cela il faut modifier le fichier `web.xml` et metttre le paramètre *hidden* à `true` du servlet EXistServlet :

    <init-param>
       <param-name>hidden</param-name>
       <param-value>true</param-value>
    </init-param>

Nous conseillons de créer les fichiers de configuration correspondant aux différents environnement dans le répertoire *config* et à utiliser ces fichiers pour le packaging.

Génération du fichier WAR
---

Le répertoire `scripts` de Oppidum défini une cible `package` pour générer le fichier WAR avec ant. La commande suivante :

    cd scripts
    ant package

génère un fichier `oppidum-uni-v{nb}.war` dans le répertoire `dist` de eXist. Éditez le fichier `scripts/ant.properties` si vous souhaitez modifier le nom du fichier généré et d'autres méta-données (product.author, product.name, product.version, pkg.war.name).

Le fichier WAR généré contient une distribution minimale de eXist avec un minimum de modules XQuery. Par défaut les modules XQuery _Mail_ et _Images_ sont inclus.

Le module `http://expath.org/ns/http-client` est désactivé car les fichiers jar correspondant ne sont pas inclus (`extensions/expath/lib`, *c'est peut-être un bug dans la distribution actuelle* signalé sur le forum).

Pour changer la distribution générée vous devez modifier les fichiers suivants fournis avec Oppidum:

- `config/web.xml` : pour changer la liste des servlets lancés
- `config/prod/conf.xml` : pour changer les paramètres de eXist tels que les modules XQuery embarqués
- `config/prod/log4j.xml` : pour changer la génération des logs

Les logs sont mis sur le niveau `error` en production, vous pouvez si vous le souhaitez les mettre sur le niveau `warn` plus verbeux.

Si vous modifiez les servlets dans `web.xml` ou les modules XQuery dans `conf.xml`, il se peut que vous deviez également modifier la liste des fichiers jar inclus dans le fichier WAR en éditant `scripts/build.xml`.

Le fichier `config/controller-config.xml` définissant le contrôleur de l'application contient la ligne suivante :

    <root pattern=".*" path="xmldb:exist:///db/www/root"/>

Notons que ce fichier WAR ne contient pas de BD initiale (le répertoire `WEB-INF/data` est vide), celle-ci sera créée lors du premier lancement de l'application sous Tomcat. Une fois le fichier WAR déployé il faut donc encore **restorer** le code source de **la distribution Oppidum** depuis une archive ZIP. La restoration s'effectue avec le client d'administation de eXist.

Génération des fichiers archives ZIP
---

Pour packager l'application il convient d'installer le code source et les données initiales de l'application dans les collections suivantes :

* `/db/www/oppidum` : code source de Oppidum
* `/db/www/{:application}` : code source de l'application
* `/db/sites/{:application}` : toutes les données initiales de l'application

où _application_ est le nom de l'application.

La distribution Oppidum contient un **script d'installation** pour simplifier l'installation de la distribution Oppidum et de l'application depuis le système de fichier vers la BD. Celui-ci devrait être disponible par défaut à l'URL `http://localhost:80/exist/projets/oppidum/install` en ce qui concerne Oppidum, et `http://localhost:80/exist/projets/{:application}/install` en ce qui concerne l'application. Ouvrez l'URL et suivez les instructions (il faut de connecter comme _admin_ de la BD pour pouvoir exécuter ces scripts).

Au besoin consultez le <a href="guide.html">guide du développeur</a> pour apprendre comment créer le script d'installation `scripts/install.xql` pour votre application.

Une fois les collections créées dans la BD, vous devez : 

2. exporter l'archive `db-www-oppidum.zip` contenant le code source de Oppidum
3. exporter l'archive `db-www-{:application}.zip` contenant le code de l'application
4. exporter l'archive `db-sites-{:application}.zip` contenant les données de l'application

Vous pouvez au choix utiliser le client d'administration de eXist ou bien le ***module d'administration Oppidum***. Ce module est installé par défaut avec le framework Oppidum. Il est disponible à l'adresse `http://localhost:8080/exist/projets/oppidum/admin` (si vous avez installé Oppidum en suivant les conventions).

Vous aurez besoin de 3 archives si vous voulez découper finement l'application (Oppidum, le code de l'application, les données de l'application), qui se trouvent dans des collections mentionnées dans la première section.

**ATTENTION** nous recommandons de fabriquer les archives ZIP et de les restorer sur une BD eXist pour laquelle le compte _admin_ possède le même mot de passe. Au besoin changez le avant de procéder à la génération des ZIP pour qu'il corresponde à celui du serveur sur lequel vous allez le restorer.

Vous pouvez alternativement créer une seule archive de la collection `/db` qui contiendra alors l'ensemble de l'application. Attention cependant si vous procédez de la sorte depuis un environnement de développement, vous risquez d'embarquer toutes les applications fournies avec eXist ainsi que la documentation eXist, ce qu'il faut éviter sur un site en production. Il est alors préférable d'effectuer le packaging depuis un environnement eXist vierge.

Installation de l'application sur le serveur de production
---

Une fois le fichier WAR déployé sur le serveur de production, l'application devrait retourner une erreur puisque la base de donnée est vide et le fichier contrôleur `/db/www/root/controller.xql` n'existe pas. Vous devez alors procéder en 2 temps pour le créer **à l'aide du client d'administration eXist** :

1. restorer l'archive `db-www-oppidum.zip` sur la base de donnée
2. recopier le fichier `/db/www/oppidum/controller.xql` de oppidum à l'emplacement du contrôleur de l'application `/db/www/root/controller.xql`

Le **module d'administration Oppidum** contenu dans la distribution peut servir pour restorer les archives ZIP de l'application. Alternativement vous pouvez aussi utiliser le client d'administration de eXist. Le module d'administration Oppidum devrait être disponible à l'URL suivante : `http://{:serveur}/{:contexte}/admin`. Par exemple si l'application a été déployée dans le contexte ROOT :  `http://{:serveur}/admin`.

Vous pouvez alors transférer par FTP les archives `db-www-{:application}.zip` et `db-sites-{:application}.zip` à l'emplacement défini par le module d'administration Oppidum, et utiliser le module d'administration pour les restorer.

**ATTENTION** si votre application nécessite des utilisateurs spécifiques et des groupes spécifiques (typiquement il devrait y a voir un utilisateur _siteadmin_ ainsi que des groupes 'site-admin' et 'site-member, vous devez créez ces utilisateurs et ces groupes à l'aide du client d'administration eXist avant la restoration des archives ZIP ou vous risquez d'avoir des erreurs lors de la restoration si les propriétaires de fichiers n'existent pas dans la base. La raison est que (au moins pour eXist 1.4.x), les utilisateurs et les groupes sont définis dans la resource `/db/system/users.xml` qui ne fait pas partie des archives si vous suivez nos instructions.

Pour terminer l'installation vous devrez remplacer le fichier `/db/www/root/controller.xql` provenant de Oppidum, par le fichier `controller.xql` provenant de votre application. Vous pouvez le recopier à l'aide du client d'administration eXist depuis le fichier `/db/www/{:application}/controller.xql`. 

Une fois le fichier `controller.xql` de votre application recopié, n'oubliez pas d'éditer le mapping (`/db/www/{:application}/mapping.xml`) pour **mettre l'attribut `mode` à `prod`** (ou `test` suivant le type d'environnement d'exécution). Ceci affecte la manière dont Oppidum générera les URLs statiques, les conventions étants différentes pour une exécution hors tomcat (mode `dev`) et avec tomcat (mode `test` ou `dev`). Il est également recommandé de supprimer l'entrée `install` du mapping, puisque l'application en production ne nécessite pas d'installation depuis le système de fichier local.

Mises à jour de l'application
---

Les mises à jour ultérieures s'effectuent toujours sur le cycle :

* génération d'une archive ZIP contenant le nouveau code depuis la version de développement ou de test de l'application (et/ou des nouvelles données)
* restoration de l'archive ZIP du nouveau code sur la version en test ou en production de l'application

Cette méthode de travail permet de ne pas modifier le fichier WAR déployé, et d'éviter les coûteuse opérations de redéploiement de l'application sous Tomcat qui entrainent parfois des fuites mémoire (PermGen Space).

Pour la seconde étape nous avons observé qu'il vaut mieux **utiliser le même mot de passe admin pour créer l'archive ZIP que celui de la BD sur laquelle s'effectue la restoration**.

Astuce pour le test
----

Nous recommandons de réaliser et d'installer 2 distributions sous Tomcat :

1. une distribution de test
2. une distribution de production

La distribution de test sert à tester l'application complète sur une machine de test. La distribution de production est la version mise en ligne.

Dans la plupart des cas la seule différence entre ces 2 distributions étant le niveau de log défini dans le fichier `log4j.xml` (qui fait partie du WAR), si vous ne souhaitez pas packager 2 fois le fichier WAR, vous pouvez alors simplement déployer la version destinée à la production sur le serveur de test, l'arrêter, modifier à la main le fichier de configuration des logs et redémarrer l'application. Vous éviterez ainsi de devoir générer 2 fichiers WAR différents.


Procédure détaillée de packaging / déploiement
---

Pré-requis :

- ant
- installer eXist en local (répertoire `{:home}/{:exist-home}`)
- créer un répertoire `database` au même niveau que le précédent (répertoire `{:home}/database`)
- récupérer les sources de Oppidum en local (répertoire `{:exist-home}/webapps/projets/oppidum`)
- récupérer ou développer l'application en local (répertoire `{:exist-home}/webapps/projets/{:application}`)
- le moment venu installez Oppidum et votre application dans la BD de développement (utilisez le module d'installation de Oppidum, éventuellement complétez à la main avec le client d'administration eXist ou l'éditeur Oxygen)
- utilisez la console d'administration de Oppidum et celle de votre application pour créer les archives ZIP

Résultats :

- fichier WAR contenant eXist dans `{:exist-home}`/dist
- archives de Oppidum, de l'application et des données initiales de l'application à déployer dans `{:home}/database/*.zip`


### 1 : installation d'eXist

Lors de l'installation d'eXist utilisez le mot de passe pour la BD que vous utiliserez en production.

Vous pouvez choisir de mettre la BD où vous voulez (question posée par le programme d'installation de eXist)

NOTE: si vous partez d'une installation de eXist existante, nous vous conseillons alors d'effacer le contenu du répertoire `data` (mais pas le répertoire lui-même) de façon à repartir d'une base de données vierge lors du premier lancement.

### 2 : récupération des sources

Pour Oppidum, avec un accès GitHub configuré :

    cd {:exist-home}/webapps
    mkdir projets
    cd projets
    git clone git://github.com/ssire/oppidum.git
    # git clone git@bitbucket.org:ssire/oppidum.git (variante bitbucket)

Une fois Oppidum copié, éditez la première ligne du fichier `scripts/stop.sh` pour y mettre le mot de passe utilisé par la BD.

Si les sources de l'application sont aussi sur GitHub :

    cd {:exist-home}/webapps/projets
    git clone git://github.com/ssire/{:application}.git
    # git clone git@bitbucket.org:ssire/{:application}.git (variante bitbucket)


### 3 : création du fichier WAR

Pour créer le fichier oppidoc-{:version}.war dans le répertoire `{:exist-home}/dist` :

    cd {:exist-home}/webapps/projets/oppidum/scripts
    ant package

### 4 : création de l'archive ZIP de l'application avec Oppidum

Lancez eXist, vous pouvez utiliser le script de démarrage fourni avec Oppidum :

    cd {:exist-home}/webapps/projets/oppidum/scripts
    ./start.sh

Notez que vous pouvez utiliser le script `stop.sh` pour arrêter eXist.

Ensuite installez Oppidum dans la BD, pour cela:

- accédez à l'URL `http://localhost:8080/exist/projets/oppidum/install`
- cochez toutes les cases (sauf les ressources si vous utilisez un proxy) si et appuyez sur le bouton *Install*
- accédez à l'URL `http://localhost:8080/exist/projets/{:application}/install`
- cochez toutes les cases (sauf les ressources si vous utilisez un proxy) et appuyez sur le bouton *Install*

Pour créer les archives ZIP avec le module d'administration de Oppidum :

- accédez à l'URL `http://localhost:8080/exist/projets/oppidum/admin`
- sélectionnez les collections à exporter
- appuyez sur le bouton `Backup` et suivez les instructions

Les archives `db-{:collection}-{:date}.zip` seront créées dans le répertoire {:home}/database par défaut.

### 5 : Installation d'une application avec Oppidum pour Tomcat

Démarrer Tomcat et déployer le fichier WAR.

* lancer le client d'administration de eXist
  * restorer l'archive `db-www-oppidum.zip`
  * recopier `/db/www/oppidum/controller.xql` dans `/db/www/root/controller.xql`
  * mettre l'attribut `mode` à `prod` dans le mapping
  * créer les utilisateurs et les groupes requis par défaut pour l'application
  
* lancer un client FTP
  * recopier `db-sites-{:application}.zip`
  * recopier `db-www-{:application}.zip` 
  * utiliser l'emplacement prévu par le module administration de Oppidum  (par défaut. un répertoire `database` à la racine)
  
* ouvrir `http://{:serveur}/{:context}/admin`
  * restorer les données `db-sites-{:application}.zip`
  * restorer le code `db-www-{:application}.zip`
  
* reprendre le client d'administration de eXist
  * recopier `/db/www/{:application}/controller.xql` dans `/db/www/root/controller.xql`
  * mettre l'attribut `mode` à `prod` dans le mapping

### 6 : Mise à jour d'une application avec Oppidum pour Tomcat

La méthode de mise à jour ci-dessous n'est possible que si le mapping de l'application (`/db/www/{:application}/config/mapping.xml`) contient le module d'administration de Oppidum, c'est à dire que si le bloc de code suivant est dans le mapping du site :

    <!-- Oppidum administration module (backup / restore) -->
    <item name="admin" resource="none" method="POST">
      <access>
        <rule action="GET POST" role="u:admin" message="admin"/>
      </access>
      <model src="oppidum:modules/admin/restore.xql"/>
      <view src="oppidum:modules/admin/restore.xsl"/>
      <action name="POST">
        <model src="oppidum:modules/admin/restore.xql"/>
        <view src="oppidum:modules/admin/restore.xsl"/>
      </action>
    </item>

Au besoin vous pouvez l'ajouter avec le client d'amdministration eXist en éditant directement le mapping.

* ouvrez l'URL `http://{:app-url}/admin` du serveur de production
  * effectuez une backup de la collection `/db` de manière å posséder une copie de sauvegarde de la BD
  * pour plus de sûreté vous pouvez également restorer en local cette copie sur une installation d'eXist vierge pour la tester

* ouvrez l'URL `http://localhost:8080/exist/oppidum/install` du serveur de développement
  * installez la dernière version de Oppidum

* ouvrez l'URL `http://localhost:8080/exist/oppidum/admin` du serveur de développement
  * générez l'archive `db-www-oppidum.zip` de la nouvelle version d'Oppidum que vous souhaitez utiliser

* lancez un client FTP vers le serveur
  * recopiez `db-www-oppidum.zip` sur l'emplacement prévu par le module administration de Oppidum  (par défaut. un répertoire `database` à la racine)
  
* ouvrez l'URL `http://{:app-url}/admin` du serveur de production
  * restorez `db-www-oppidum.zip`

Pour mettre à jour l'application, procédez de même.

Notez que les restorations sont non-destructive, c'est-à-dire qu'elles ne font que modifier les fichiers existants ou ajouter de nouveaux fichiers, si vous souhaitez supprimmer des fichiers vous devez le faire manuellement avant la restoration.


Optimisations
-------------

### Utilisation d'un proxy pour servir les ressources statiques

En plus d'augmenter la sécurité de l'application, le proxy peut servir les ressources statiques. En production le framework Oppidum s'arrange en effet pour que toutes les URLs vers les ressources statiques (CSS, JS) soient de la forme:

    /static/{module}/reste-du-chemin-vers-ressources-statique

Avec {module} égal soit à "oppidum", soit au nom de l'application

En développement les ressources statiques sont servies directement depuis le système de fichier. En test et en production elles sont servies par la BD. Pour cette raison elles doivent être recopiées dans les collections `/db/www/{modules}/resources/`). Cependant **il est fortement recommandé de configurer un serveur Proxy** (e.g. NGINX, ou Apache avec mod_jk) pour servir directement ces ressources depuis :

    /{static}/{module}/reste-du-chemin-vers-ressources-statique

où {static} est un répertoire en dehors de l'application, accessible par FTP, où copier les fichiers des ressource statiques

### Backups 

Pour la sécurité il faut au minimum prévoir une backup périodique de tout le répertoire `WEBINF/data` qui contient la base de donnée eXist et ses journaux (l'emplacement de ce répertoire est fixé par le fichier `conf.xml` de eXist).

Nous recommandons de définir un répertoire `database` en dehors du répertoire tomcat, sur lequel l'application peut écrire et accessible par FTP. Le module d'administration de Oppidum permet de faire manuellement une backup sélective (et une restoration) de tout ou partie de la BD dans une archive .ZIP dans un répertoire externe. Nous utilisons cette procédure lors des mises à jour.

Il est aussi possible de configurer l'application (via le fichier `conf.xml`) pour effectuer périodiquement une backup dans une répertoire défini à l'avance. Voir la documentation de eXist-DB.

