Packager une application pour Tomcat avec Oppidum
=================================================

Par Stéphane Sire (Oppidoc), <s.sire@free.fr>, Décembre 2011

Suivre les étapes suivantes :
 
  1. Générer le fichier WAR contenant eXist
  2. Générer l'archive oppidum.zip contenant la librairie Oppidum
  3. Générer l'archive app-code.zip contenant le code de l'application
  4. Générer l'archive app-data.zip contenant les données de l'application
  
Distribution de l'application sous Tomcat
---
  
Sous Tomcat le code de la librairie Oppidum, le code de l'application et les données de l'applications sont situés dans la BD dans les collections suivantes :

- `db/www/oppidum` : librairie Oppidum
- `db/www/monapp` : code de l'application
- `/db/sites/monapp` : configuration et données de l'application

où *monapp* est le nom de l'application

Le fichier `controller-config.xml` qui se trouvera à la racine du `WEB-INF` redirigera les URLs vers le contrôleur de l'application dans  `/db/www/monapp/controller.xql` (cf. les explications ci-dessous).

Le fichier WAR ne contient qu'une distribution minimale de eXist. Les mises à jour ultérieures de l'application s'effectuent directement avec le client d'administration de eXist en 2 étapes :

- génération d'une archive ZIP contenant le nouveau code depuis la version de développement ou de test de l'application

- restauration de l'archive ZIP du nouveau code sur la version en production de l'application

Cette méthode de travail permet de ne pas modifier le fichier WAR déployé, et d'éviter les coûteuse opérations de redéploiement de l'application sous Tomcat qui entrainent parfois des fuites  mémoire (PermGen Space).

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
    
génère un fichier `monapp-version.war` dans le répertoire `dist` de eXist. Éditez le fichier `scrtipts/ant.properties` si vous souhaitez modifier le nom du fichier généré et d'autres méta-données (product.author, product.name, product.version, pkg.war.name).

Notez que à priori il est également possible de faire les même opérations depuis la distribution source de l'application si elle contient également le script ant issus de la distribution d'Oppidum.

Le fichier WAR généré contient une distribution minimale de eXist avec un minimum de modules XQuery. Par défaut les modules XQuery suivants sont inclus :

- Mail
- Images

Le module `http://expath.org/ns/http-client` est désactivé car les fichiers jar correspondant ne sont pas inclus (`extensions/expath/lib`).

Pour changer la distribution générée vous devez modifier les fichiers suivants:

- `config/web.xml` : pour changer la liste des servlets lancés
- `config/conf.xml` : pour changer les paramètres de eXist tels que les modules XQuery embarqués
- `config/prod/log4j.xml` : pour changer la génération des logs

Si vous modifiez les servlets dans `web.xml` ou les modules XQuery dans `conf.xml`, il se peut que vous deviez également modifier la liste des fichiers jar inclus dans le fichier WAR en éditant `scripts/build.xml`.

Dans tous les cas vous devez modifier une ligne dans le fichier `config/controller-config.xml` :

    <root pattern=".*" path="xmldb:exist:///db/www/oppidum"/>
    
en remplaçant *opppidum* par le nom de votre application. Il est aussi possible de mette des préfixes différents pour regrouper plusieurs applications dans une seule.

Notons que ce fichier WAR ne contient pas de BD initiale, celle-ci sera donc initialisée lors de l'initialisation de l'application sous Tomcat.

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

NB: actuellement il faut aussi une 4e archive pour `/db/sites/oppidum` qui contient les messages d'erreur d'Oppidum.

Vous pouvez alternativement créer une seule archive de la collection `/db` qui contiendra alors l'ensemble de l'application. Attention cependant si vous procédez de la sorte depuis un environnement de développement, vous risquez d'embarquer toutes les applications fournies avec eXist ainsi que la documentation générée, ce qu'il faut éviter sur un site en production. Cette méthode est donc applicable depuis un environnement eXist vierge.

Restauration des archives ZIP
----

Déployez le WAR sour Tomcat et lancez le.

Lancez le client d'administration eXist en vous connectant à l'application installée sous Tomcat. Par exemple, en test cela devrait être une URL de la forme `http://localhost:8000/monapp`.

Si votre application nécessite des utilisateurs spécifique et des groupes spécifiques (typiquement il devrait y a voir un utilisateur 'monapp' ainsi que des groupes 'site-admin' et 'site-member), alors créez à la main ces utilisateurs et ces groupes.

Procédez ensuite à la restoration des archives ZIP crées à l'étape précédente.

Note sur les droits
----

Nous recommandons de fabriquer les archives ZIP et de les restaurer sur une BD eXist pour laquelle le compte `admin` possède le même mot de passe. Au besoin changez le avant de procéder à la génération des ZIP pour qu'il corresponde à celui du serveur sur lequel vous allez le restorer.

À priori cette contrainte est indispensable si vous utilisez une seule archive ZIP embarquant tout la BD plutôt que le découpage indiqué ci-dessus.

Optimisation: fichier WAR universel
----

Cette méthode est en cours d'expérimentation avec une cible ant `pkg-universal`.

Pour cela vous devez fabriquer le WAR depuis une version d'eXist vierge (pas de génération de la documentation) configurée lors de l'installation de eXist avec la BD dans le répertoire interne webapps/WEB-INF/data. 

Utilisez l'URL `oppidum/universal` pour copier le fichier `controller-config.xml` dans cette BD. 

La cible `pkg-universal` va utiliser une version spéciale du fichier `web.xml` qui contiendra le paramètre suivant :

    <init-param>
      <param-name>config</param-name>
      <param-value>xmldb:exist:///db/controller-config.xml</param-value>
    </init-param>

instruisant eXist de lire le fichire controller-config.xml depuis la racine de la BD.

Le fichier WAR obtenu sera alors un fichier universel, puisqu'il permettra d'éditer le mapping des URLs du site (par exemple pour ajouter des applications sur le site) sans modifier le WAR (en fait le controller-config.xml).

Notez que suivant le contenu de la BD au moment du packaging, il est possible de pré-remplir celle-ci avec la librairie Oppidum pour éviter d'avoir à restaurer l'archive `oppidum.zip`.


















