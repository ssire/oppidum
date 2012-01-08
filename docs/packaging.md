Packager une application pour Tomcat avec Oppidum
=================================================

Par Stéphane Sire (Oppidoc), <s.sire@free.fr>, Janvier 2012

Suivre les étapes suivantes :
 
  1. Générer le fichier WAR contenant eXist
  2. Générer l'archive oppidum.zip contenant la librairie Oppidum
  3. Générer l'archive app-code.zip contenant le code de l'application
  4. Générer l'archive app-data.zip contenant les données de l'application
  
Distribution de l'application sous Tomcat
---
  
Sous Tomcat le code de la librairie Oppidum, le code de l'application et les données de l'application sont situés dans la BD dans les collections suivantes :

- `db/www/oppidum` : librairie Oppidum
- `db/www/monapp` (ou `/db/www/root` pour la variante universelle): code de l'application (y compris messages d'erreurs et gabarits)
- `/db/sites/monapp` : données de l'application

où *monapp* est le nom de l'application

Le fichier `controller-config.xml` qui se trouvera à la racine du `WEB-INF` redirigera les URLs vers le contrôleur de l'application dans  `/db/www/monapp/controller.xql` (ou bien vers `/db/www/root/controller.xql` pour la variante universelle, cf. les explications ci-dessous).

Le fichier WAR ne contient qu'une distribution minimale de eXist. Les mises à jour ultérieures de l'application s'effectuent directement avec le client d'administration de eXist en 2 étapes :

- génération d'une archive ZIP contenant le nouveau code depuis la version de développement ou de test de l'application

- restauration de l'archive ZIP du nouveau code sur la version en production de l'application

Cette méthode de travail permet de ne pas modifier le fichier WAR déployé, et d'éviter les coûteuse opérations de redéploiement de l'application sous Tomcat qui entrainent parfois des fuites mémoire (PermGen Space).

Astuce pour le test
----

Nous recommandons de réaliser et d'installer 2 distributions sous Tomcat :

1. une distribution de test
2. une distribution de production

La distribution de test sert à tester l'application complète sur une machine de test. La distribution de production est la version mise en ligne.

Dans la plupart des cas la seule différence entre ces 2 distributions étant le niveau de log défini dans le fichier `log4j.xml` (qui fait partie du WAR), si vous ne souhaitez pas packager 2 fois le fichier WAR, vous pouvez alors simplement déployer la version destinée à la production sur le serveur de test, l'arrêter, modifier à la main le fichier de configuration des logs et redémarrer l'application. Vous éviterez ainsi de devoir générer 2 fichiers WAR différents.

Génération du WAR
---

Le répertoire `scripts` de Oppidum défini une cible `package` pour générer le fichier WAR avec ant. La commande suivante :

    cd scripts
    ant package
    
génère un fichier `oppidum-v{nb}.war` dans le répertoire `dist` de eXist. Éditez le fichier `scripts/ant.properties` si vous souhaitez modifier le nom du fichier généré et d'autres méta-données (product.author, product.name, product.version, pkg.war.name).

Notez que à priori il est également possible de faire les même opérations depuis la distribution source de l'application si elle contient également le script ant issu de la distribution d'Oppidum (ou une version adaptée).

Le fichier WAR généré contient une distribution minimale de eXist avec un minimum de modules XQuery. Par défaut les modules XQuery suivants sont inclus :

- Mail
- Images

Le module `http://expath.org/ns/http-client` est désactivé car les fichiers jar correspondant ne sont pas inclus (`extensions/expath/lib`, *c'est peut-être un bug dans la distribution actuelle* signalé sur le forum).

Pour changer la distribution générée vous devez modifier les fichiers suivants:

- `config/web.xml` : pour changer la liste des servlets lancés
- `config/prod/conf.xml` : pour changer les paramètres de eXist tels que les modules XQuery embarqués
- `config/prod/log4j.xml` : pour changer la génération des logs

Si vous modifiez les servlets dans `web.xml` ou les modules XQuery dans `conf.xml`, il se peut que vous deviez également modifier la liste des fichiers jar inclus dans le fichier WAR en éditant `scripts/build.xml`.

Dans tous les cas vous devez modifier une ligne dans le fichier `config/controller-config.xml` :

    <root pattern=".*" path="xmldb:exist:///db/www/oppidum"/>
    
en remplaçant *opppidum* par le nom de votre application. Il est aussi possible de mettre des préfixes différents pour regrouper plusieurs applications dans un seul WAR.

Notons que ce fichier WAR ne contient pas de BD initiale (le répertoire `WEB-INF/data` est vide), celle-ci sera créée lors du premier lancement de l'application sous Tomcat.

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

Lancez le client d'administration eXist en vous connectant à l'application installée sous Tomcat. Par exemple, en test cela devrait être une URL de la forme `http://localhost:8000/monapp`.

Si votre application nécessite des utilisateurs spécifique et des groupes spécifiques (typiquement il devrait y a voir un utilisateur 'monapp' ainsi que des groupes 'site-admin' et 'site-member), alors créez à la main ces utilisateurs et ces groupes.

Procédez ensuite à la restoration des archives ZIP crées à l'étape précédente.

Note sur les droits
----

Nous recommandons de fabriquer les archives ZIP et de les restaurer sur une BD eXist pour laquelle le compte `admin` possède le même mot de passe. Au besoin changez le avant de procéder à la génération des ZIP pour qu'il corresponde à celui du serveur sur lequel vous allez le restorer.

À priori cette contrainte est indispensable si vous utilisez une seule archive ZIP embarquant tout la BD plutôt que le découpage indiqué ci-dessus.

Variante avec fichier WAR universel
----

Le répertoire scripts de Oppidum défini également une cible `universal` pour générer le fichier WAR avec ant. La commande suivante :

    cd scripts
    ant universal
    
génère un fichier `oppidum-uni-version.war` dans le répertoire `dist` de eXist. De même que pour le packaging WAR classique vous pouvez modifier le nom du fichier généré et d'autres méta-données (product.author, product.name, product.version, pkg.war.name) en éditant le fichier `scripts/ant.properties`.

Le fichier WAR universel contient une version spéciale du fichier `web.xml` avec le paramètrage suivant :

    <init-param>
      <param-name>config</param-name>
      <param-value>xmldb:exist:///db/www/universal/controller-config.xml</param-value>
    </init-param>

instruisant eXist de lire le fichier `controller-config.xml` depuis la collection `/db/www/universal` de la BD.

**Pour générer le fichier WAR universel il faut au préalable**:

1. invoquer le script ant depuis une installation d'eXist dans laquelle la BD (répertoire `data`) se situe dans `${exist-home}/webapp/WEB-INF/data`
2. avoir installé le fichier `controller-config.xml` universel dans la collection `/db/www/universal`

Le point 1 s'effectue au moment de l'installation de l'application eXist qui servira à générer le WAR, il faut bien préciser que la localisation du répertoire `data` sera celle indiquée ci-dessus (même si formellement elle n'existe pas encore au moment où l'on installe eXist).

Le point 2 nécessite, une fois le point 1 effectué, de copier Oppidum dans le répertoire `webapp` de eXist (par exemple dans le répertoire `{chemin}`), de lancer eXist, puis de copier Oppidum dans la base de données avec la page d'installation `http://localhost:8080/exist/{chemin}/oppidum/install` (cf. le point *Génération des archives ZIP*). 

Au moment de l'installation il faut sélectionner le module `root` dans le code, ce qui aura pour effet d'installer le fichier `controller-config.xml` universel dans la BD.

Le fichier WAR obtenu est universel car il permet d'éditer le mapping des URLs du site (par exemple pour ajouter des applications sur le site) sans modifier le WAR (et donc sans avoir à le redéployer), en modifiant directement la ressource `controller-config.xml` dans la BD. 

Notons cependant que comme les modifications de la ressource `controller-config.xml` ne sont pas prises en compte immédiatement par eXist (qui impose un redémarrage pour les prendre en compte). Pour y remédier le fichier `controller-config.xml` universel fait pointer toutes les URLs vers la collection `/db/www/root`. En respectant cette convention lors de la création du fichier ZIP pour le code d'une application (celui qui contient le `controller.xql`) il est ainsi possible de la déployer directement sur le fichier WAR universel sans avoir besoin de relancer eXist (donc Tomcat).

Pour produire le fichier ZIP universel du code de l'application (celui qui place le code de l'application dans `/db/www/root` et non pas dans la collection `/db/www/monapp`), nous avons ajouté une option *universal* à la page d'installation des applications. Il faut alors : 

1. sélectionner l'option `universal` lors de l'installation du code dans la BD
2. éditer le fichier `/db/www/root/controller.xql` et modifier l'attribute `confbase` du mapping en remplaçant `confbase="/db/www/monapp"` par `confbase="/db/www/root"`

Ensuite seulement vous pouvez générer le fichier monapp-uni-code.ZIP du code de  l'application comme expliqué ci-dessus.

Notons qu'alternativement vous pouvez faire une installation standard et renommer à la main la collection `/db/www/monapp` en `/db/www/root` sans omettre le point 2 ci-dessus avant de générer le ZIP.

Notons enfin qu'il est possible d'inclure dans le fichier WAR obtenu en suivant les instructions précédentes la librairie Oppidum pré-installée. Pour cela cochez tous les modules correspondants lors du point 1. Vous n'aurez ainsi pas besoin de restorer l'archive `oppidum.zip` avec le client Java d'eXist sur le WAR déployé.














