Packager et déployer  une application pour Tomcat avec Oppidum
===

Par Stéphane Sire (Oppidoc), <s.sire@free.fr>, Février 2012

De manière générale suivre les étapes suivantes :

  1. Générer le fichier WAR contenant eXist
  2. Générer l'archive db-www-oppidum.zip contenant la librairie Oppidum
  3. Générer l'archive db-www-app.zip contenant le code de l'application
  4. Générer l'archive db-sites-app.zip contenant les données de l'application
  5. Déployer le fichier WAR
  6. Restorer db-www-oppidum.zip avec le client d'administration de eXist
  7. Installer le contrôleur de l'application dans `/db/www/root`
  8. Restorer db-www-app.zip et db-sites-app.zip avec la console d'administration Oppidum
  
Il est possible de grouper les étapes 2 à 4 et 6 à 8 en: 

  - Générer une archive de toute l'application db.zip
  - Restorer l'archive de toute l'application avec le client d'administration eXist
  
Cette variante plus compacte peut néanmoins prendre beaucoup plus de temps suivant la qualité de la liaison entre le site de développement et le site de production.
  
Distribution de l'application sous Tomcat
---

La convention d'Oppidum en mode production est de stocker l'application dans la BD. Le code de la librairie Oppidum, le code de l'application et les données de l'application sont situés respectivement dans les collections suivantes :

- `/db/www/oppidum` pour librairie Oppidum
- `/db/www/{app}` pour code de l'application (y compris messages d'erreurs et gabarits)
- `/db/sites/{app}` pour les données de l'application

où _app_ est le nom de l'application.

Par convention le fichier `WEB-INF/controller-config.xml` de eXist inclus dans le WAR redirige les URLs vers le contrôleur `/db/www/root/controller.xql` dans la BD. C'est donc ce fichier qui détermine l'application qui sera exécutée par Oppidum (c'est lui qui contient le mapping). Ce fichier sera en général créé lors d'une action post-installation en recopiant le fichier `/db/www/{app}/controller.xql`.

Pour simplifier le packaging, le fichier WAR universel d'Oppidum ne contient qu'une distribution minimale de eXist (principalement sous forme de fichiers .jar et de fichiers de configuration) et sa base de donnée est vide. Une fois le fichier WAR déployé il faut donc encore **restorer** la base de donnée contenant **l'installation minimale d'Oppidum** depuis une archive ZIP. La restoration s'effectue avec le client d'administation de eXist.

L'installation minimale d'Oppidum contient une **console d'administration Oppidum** qui peut servir ensuite pour mettre à jour Oppidum et/ou pour installer et/ou mettre à jour une ou plusieurs applications à partir d'archives ZIP. Alternativement à cette console d'administration, il est également possible d'utiliser le client d'administration de eXist.

Les mises à jour ultérieures s'effectuent toujours sur le cycle :

- génération d'une archive ZIP contenant le nouveau code depuis la version de développement ou de test de l'application (et/ou des nouvelles données)

- restoration de l'archive ZIP du nouveau code sur la version en production de l'application

Cette méthode de travail permet de ne pas modifier le fichier WAR déployé, et d'éviter les coûteuse opérations de redéploiement de l'application sous Tomcat qui entrainent parfois des fuites mémoire (PermGen Space).

Astuce pour le test
----

Nous recommandons de réaliser et d'installer 2 distributions sous Tomcat :

1. une distribution de test
2. une distribution de production

La distribution de test sert à tester l'application complète sur une machine de test. La distribution de production est la version mise en ligne.

Dans la plupart des cas la seule différence entre ces 2 distributions étant le niveau de log défini dans le fichier `log4j.xml` (qui fait partie du WAR), si vous ne souhaitez pas packager 2 fois le fichier WAR, vous pouvez alors simplement déployer la version destinée à la production sur le serveur de test, l'arrêter, modifier à la main le fichier de configuration des logs et redémarrer l'application. Vous éviterez ainsi de devoir générer 2 fichiers WAR différents.

Génération du fichier WAR universel d'Oppidum
---

Le répertoire `scripts` de Oppidum défini une cible `universal` pour générer le fichier WAR avec ant. La commande suivante :

    cd scripts
    ant universal
    
génère un fichier `oppidum-uni-v{nb}.war` dans le répertoire `dist` de eXist. Éditez le fichier `scripts/ant.properties` si vous souhaitez modifier le nom du fichier généré et d'autres méta-données (product.author, product.name, product.version, pkg.war.name).

Le fichier WAR généré contient une distribution minimale de eXist avec un minimum de modules XQuery. Par défaut les modules XQuery suivants sont inclus :

- Mail
- Images

Le module `http://expath.org/ns/http-client` est désactivé car les fichiers jar correspondant ne sont pas inclus (`extensions/expath/lib`, *c'est peut-être un bug dans la distribution actuelle* signalé sur le forum).

Pour changer la distribution générée vous devez modifier les fichiers suivants:

- `config/web.xml` : pour changer la liste des servlets lancés
- `config/prod/conf.xml` : pour changer les paramètres de eXist tels que les modules XQuery embarqués
- `config/prod/log4j.xml` : pour changer la génération des logs

Si vous modifiez les servlets dans `web.xml` ou les modules XQuery dans `conf.xml`, il se peut que vous deviez également modifier la liste des fichiers jar inclus dans le fichier WAR en éditant `scripts/build.xml`.

Le fichier `config/controller-config.xml` définissant le contrôleur de l'application contient la ligne suivante :

    <root pattern=".*" path="xmldb:exist:///db/www/root"/>
    
Il est aussi possible de mettre des préfixes différents pour regrouper plusieurs applications dans un seul WAR.

Notons que ce fichier WAR ne contient pas de BD initiale (le répertoire `WEB-INF/data` est vide), celle-ci sera créée lors du premier lancement de l'application sous Tomcat, raison pour laquelle il faudra restorer la librairie Oppidum et le contrôleur de l'application lors d'une procédure de post-installation.

Configuration des logs
----

Mettre le niveau `debug` (ou `info`) en test.

Mettre le niveau `error` (ou `warn` plus verbeux) en production.

Génération des archives ZIP
---

La librairie Oppidum ainsi que les applications contiennent un script d'installation pour copier le code et les données de l'application depuis le répertoire locale à leur emplacement pour le déploiement dans la BD.

Le script d'installation (qui se trouve dans `scripts/install.xql`) est associé par défaut avec l'URL `/oppidum/install` en ce qui concerne Oppidum, et `/monapp/install` pour l'application.

Ouvrez l'URL et suivez les instructions (il faut de connecter comme `admin` de la BD pour pouvoir exécuter ces scripts) pour charger le code et les données dans la BD. 

Lancez ensuite le client d'administration eXist pour générer les archives ZIP nécessaires.

Vous aurez besoin de 3 archives si vous voulez découper finement l'application (Oppidum, le code de l'application, les données de l'application), qui se trouvent dans des collections mentionnées dans la première section.

Vous pouvez alternativement créer une seule archive de la collection `/db` qui contiendra alors l'ensemble de l'application. Attention cependant si vous procédez de la sorte depuis un environnement de développement, vous risquez d'embarquer toutes les applications fournies avec eXist ainsi que la documentation eXist, ce qu'il faut éviter sur un site en production. Il est alors préférable d'effectuer le packaging depuis un environnement eXist vierge.

Restoration des archives ZIP
----

Déployez le WAR sour Tomcat et lancez le.

Lancez le client d'administration eXist en vous connectant à l'application installée sous Tomcat. Par exemple, en test cela devrait être une URL de la forme `http://localhost:8000/exist/projets/{app}`.

Si votre application nécessite des utilisateurs spécifique et des groupes spécifiques (typiquement il devrait y a voir un utilisateur 'monapp' ainsi que des groupes 'site-admin' et 'site-member), alors créez à la main ces utilisateurs et ces groupes.

Procédez ensuite à la restoration des archives ZIP crées à l'étape précédente.

Note sur les droits
----

Nous recommandons de fabriquer les archives ZIP et de les restaurer sur une BD eXist pour laquelle le compte `admin` possède le même mot de passe. Au besoin changez le avant de procéder à la génération des ZIP pour qu'il corresponde à celui du serveur sur lequel vous allez le restorer.

À priori cette contrainte est indispensable si vous utilisez une seule archive ZIP embarquant tout la BD plutôt que le découpage indiqué ci-dessus.

Procédure détaillée de déploiement
---

Pré-requis : 

- ant
- installer eXist en local (répertoire `{:home}/{:exist-home}`)
- créer un répertoire `database` au même niveau que le précédent (répertoire `{:home}/database`)
- récupérer les sources de Oppidum en local (répertoire `{:exist-home}/webapps/projets/oppidum`)
- récupérer ou développer l'application en local (répertoire `{:exist-home}/webapps/projets/{:app}`)

Résultats :

- fichier WAR Oppidum universel dans `{:exist-home}`/dist
- archive de l'application à déployer dans le fichier WAR universel dans `{:home}/database/{:app}.zip`


### 1 : installation d'eXist

Lors de l'installation d'eXist utilisez le mot de passe pour la BD que vous utiliserez en production.

Vous pouvez choisir de mettre la BD où vous voulez (question posée par le programme d'installation de eXist)

NOTE: vous pouvez aussi partir d'une installation de eXist existante, nous vous conseillons alors d'effacer le contenu du répertoire `data` (mais pas le répertoire lui-même) de façon à repartir d'une base de données vierge lors du premier lancement.

### 2 : récupération des sources

Pour Oppidum, avec un accès bitbucket configuré :

    cd {:exist-home}/webapps
    mkdir projets
    cd projets
    git clone git@bitbucket.org:ssire/oppidum.git
    
Une fois Oppidum copié, éditez la première ligne du fichier `scripts/stop.sh` pour y mettre le mot de passe utilisé par la BD.

Si les sources de l'application sont aussi sur bitbucket :

    cd {:exist-home}/webapps/projets
    git clone git@bitbucket.org:ssire/{:app}.git
    

### 3 : création du fichier WAR universel

Pour créer le fichier oppidoc-uni-{:version}.war dans le répertoire `{:exist-home}/dist` :

    cd {:exist-home}/webapps/projets/oppidum/scripts
    ant universal
    
### 4 : création de l'archive ZIP de l'application avec Oppidum

Lancez eXist, vous pouvez utiliser le script de démarrage fourni avec Oppidum :

    cd {:exist-home}/webapps/projets/oppidum/scripts
    ./start.sh
    
Notez que vous pouvez utiliser le script `stop.sh` pour arrêter eXist.

Ensuite installez Oppidum dans la BD, pour cela:

- accédez à l'URL `http://localhost:8080/exist/projets/oppidum/install`
- cochez toutes les cases et appuyez sur le bouton *Install*
- accédez à l'URL `http://localhost:8080/exist/projets/{:app}/install`
- cochez toutes les cases et appuyez sur le bouton *Install*
- appuyez ensuite sur le bouton *Set as root* pour copier le contrôleur de l'application dans le répertoire `/db/www/root`

Pour finir créez l'archive ZIP de toute la base de données: a) avec le client d'administration eXist (il faut choisir la collection `/db`) ou b) avec le module d'administration de Oppidum (cf ci-dessous).

Pour créer l'archive ZIP de toute l'application avec le module d'administration de Oppidum : 

- accédez à l'URL `http://localhost:8080/exist/projets/oppidum/admin`
- sélectionnez la collection `/db`
- appuyez sur le bouton `Backup` et suivez les instructions

L'archive `db-{:date}.zip` sera créée dans le répertoire {:home}/database par défaut.

Déploiement d'une application avec Oppidum pour Tomcat
---

Démarrer Tomcat et déployer le fichier WAR universel de Tomcat.

Il suffit ensuite de restorer l'archive `db-{:date}.zip` de l'application à l'aide du client d'administration de eXist.

### Variante

Il est possible d'utiliser une variante qui accélère le déploiement (moins de fichiers transférés entre le client d'administration eXist et l'application Tomcat). 

Pour cela à l'étape 4, commencez par créer 1 archive `db-{:date}.zip` immédiatement après avoir installé Oppidum et qui contiendra Oppidum seulement. Pensez à inclure le contrôleur d'Oppidum dans la collection `/db/www/root`, pour cela appuyer sur le bouton *Set as root* lorsque vous installez Oppidum dans la base de donnée, et non pas lorsque vous installez l'application dans la base de donnée. 

Ensuite continuez à installez l'application et créez 2 archives différentes avec le module d'administration de Oppidum :

- archive `db-sites-{:app}-{:date}.zip` ne contenant que les données de l'application
- archive `db-www-{:app}-{:date}.zip` ne contenant que le code de l'application

Une fois que vous aurez restoré l'archive `db-{:date}.zip` dans l'application sous Tomcat avec le client d'administration eXist, il vous restera alors à copier par FTP les 2 autres archives `db-sites-{:app}-{:date}.zip` et `db-www-{:app}-{:date}.zip` dans le répertoire `database` du domaine hébergé.

Vous pourrez ensuite les restorer directement depuis l'application en accédant à l'URL `http://{:app-url}/admin` et en utilisant le bouton *Restore* après avoir sélectionné le fichier des archives ZIP à restorer l'une après l'autre.

Mise à jour d'une application avec Oppidum pour Tomcat
---

La méthode de mise à jour ci-dessous n'est possible que si le contrôleur de l'application (`/db/www/root/controlle.xql`) contient le module d'administration de Oppidum, c'est à dire que si le bloc de code suivant est dans le mapping du site : 

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

Au besoin vous pouvez l'ajouter avec le client d'amdministration eXist en éditant directement le contrôleur.

Commencez par accéder à l'URL `http://{:app-url}/admin` et par effectuer une backup de la collection `/db` de manière å posséder une copie de sauvegarde de la BD. Pour plus de sûreté vous pouvez également restorer en local cette copie sur une installation d'eXist vierge afin de pouvoir revenir en arrière en cas de problème.

Pour mettre à jour Oppidum, créez l'archive `db-www-oppidum-{:date}.zip` de la nouvelle version d'Oppidum que vous souhaitez utiliser comme expiqué ci-dessus, puis copiez la par FTP dans le répertoire `database` du site hébergé. Vous pouvez alors la restorer en utilisant le bouton *Restore* de la console d'amdministration d'Oppidum. 

Pour mettre à jour l'application, procédez de même.

Notez que les restorations sont non-destructive, c'est-à-dire qu'elles ne font que modifier les fichiers existants ou ajouter de nouveaux fichiers, si vous souhaitez supprimmer des fichiers vous devez le faire manuellement avant la restoration.  





















