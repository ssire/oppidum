Créer des sites Web avec Oppidum
================================

Par Stéphane Sire (Oppidoc), <s.sire@free.fr>, 21-01-2001

Ce document présente le framework Oppidum pour le développeur de sites Web.

1. Introduction
------------

Oppidum est un framework léger conçu pour faciliter le développement de sites Web ou d'applications Web d'édition et de publication de documents. Oppidum repose sur 3 piliers: un moteur d'éxécution en 2 temps, une architecture 2/3 et des conventions.

### 1.1 Moteur d'exécution en 2 temps

Le schéma suivant représente une vue synoptique du fonctionnement d'Oppidum : dans un premier temps la requête de l'utilisateur sert à générer un *pipeline*; dans un deuxième temps l'environnement hôte exécute le pipeline dont la sortie forme la réponse HTTP.

<img src="../images/synoptique.png" style="max-width: 16cm" alt="Vue synoptique"/>

Oppidum doit donc s'exécuter dans un environnement hôte possédant un moteur d'éxécution de pipeline. Actuellement la librairie de base Oppidum est écrite en XQuery et nécessite également une base de donnée XML munie d'un interpéteur XQuery. Nous utilisons la base de données [eXist-db](http://exist-db.org/) qui possède aussi un moteur d'exécution de pipeline basé sur un mini-language de pipeline.

### 1.2 Architecture 2/3

À la différence des applications 3-tiers classiques où l'application s'exécute dans son propre environnement (Perl, PHP, Ruby, Java, etc.) séparé de la base de données qui sert au stockage des données, les applications écrites avec Oppidum et la base de données eXist s'exécutent dans le même environnement.

Cette architecture parfois qualifée de 2/3 ne sépare donc pas la récupération des données et les traitements / génération des vues. Le code d'extraction des données dans la BD et le code de l'application s'exécutent dans le même programme. Cette architecture offre des avantages en terme de vitesse d'accès aux données puisqu'il n'y a pas de transfert entre un second et un troisième tiers pour lire les données ([lien](http://xquerywebappdev.wordpress.com/2011/11/18/node-js-is-good-for-solving-problems-i-dont-have/#comment-26056)).

Le moteur d'exécution d'Oppidum permet cependant de maintenir une séparation claire dans le code entre les requêtes dans la base de données et le code de génération des vues, puisqu'il permet de générer des pipelines où l'extraction s'effectue à l'aide d'un modèle écrit en XQuery et la génération à l'aide d'une vue écrite en XSLT, même si les deux seront exécutés par le même tiers.

### 1.3 Conventions

Oppidum repose sur des conventions pour organiser et structurer une application. Les conventions cristallisent des bonnes pratiques et facilitent la maintenance des projets.

Le point d'entrée d'une application est le fichier `controller.xql` qui se trouve à la racine de l'application et qui appelle Oppidum en lui transmettant la requête HTTP à décoder. Le fichier `epiloque.xql` qui se trouve aussi à la racine de l'application termine le traitement de toutes les requêtes et effectue les opérations répétitives telles que l'insertion d'un en-tête ou d'un menu de navigation sur les pages de l'application.

Par ailleurs Oppidum permet d'associer à chaque URL une _une collection de référence_ ainsi qu'une _ressource de référence_ dans la base de données XML. Lorsque l'URL représente une resource conservée dans la base de données, la collection et la ressource de référence qui servent de pointeur vers la base de données offrent un moyen de découpler le mapping REST de l'application de son implémentation dans la BD.

En production les données et le code de l'application sont en général placés dans la base de données, dans une collection `/db/sites/{app}` pour les données et dans une collection `/db/www/{app}` pour le code. En particuliers la collection `/db/www/{app}/config` contient les ressources XML avec les paramètres d'exécution de l'application.

### 1.4 Comparaison avec d'autres frameworks

Oppidum s'inspire des frameworks Orbeon et Ruby on Rails. Comme avec Orbeon le rendu des pages s'effectue par la transformation de données en une représentation à l'aide d'un pipeline (approche MVC). Le pipeline de rendu obéit toujours au même schéma à trois étages : le modèle est un script XQuery qui extrait des données; la vue est un script XSLT qui les transforme; le résultat peut-être inséré à la demande dans un *gabarit de site* (ou *mesh*) écrit avec un langage spécifique. Cette dernière opération est réalisée par un script appelé *epilogue*.

Comme avec RoR, l'architecture REST du site est explicite et la correspondance entre les URLs des ressources qui forment le site et leur implémentation, sous forme de pipeline, est décrite dans un langage spécifique : le *mapping* du site (plus ou moins équivalent aux routes de RoR). De manière plus annedoctique Oppidum fournit également une *flash* pour afficher des messages d'erreur ou d'information à l'utilisateur même après une redirection de page.

Oppidum contient également des modèles et vues de base pour réaliser des fonctionnalités comme un login et du contrôle d'accès, ou bien l'édition et la publication de pages avec les librairies Javascript [AXEL](http://ssire.github.com/axel/) et [AXEL-FORMS](http://ssire.github.com/axel-forms/) fournies avec. Ces librairies offrent un niveau de fonctionnalités similaires à XForms pour la plupart des projets avec une complexité bien moindre. Elles sont par ailleurs développées dans des projets séparés sur GitHub.

Enfin il est facile d'isoler des fonctionnalités dans des modules pouvant être recopiés d'application à application avec peu d'adaptations. Il existe par exemple un module de téléchargement d'images (lié avec la librairie AXEL) et
un module de gestion de comptes utilisateurs.

Oppidum et ses modules sont définis dans le namespace `"http://oppidoc.com/oppidum/"` et ses dérivés.

2. Installation
----

Commencez par installer eXist-db ([téléchargement](http://exist-db.org/exist/download.xml)). Installez pour le moment une version 1.4.3, la version 2.0 de eXist nécessite quelques petites modifications dans la façon de structurer les applications pour en tirer meilleur parti.

Lorsque eXist est installé, placez-vous dans le répertoire `{exist-home}/webapp`, créez un répertoire `projets` (pour le moment ce nom est fixé par convention) puis clonez le dépôt Github de Oppidum. Oppidum fournit une commande `scripts/start.sh` pour démarrer eXist, exécutez-la (ou bien démarrez eXist avec la procédure standard), soit :

    cd {exist-home}/webapp
    mkdir projets
    git clone https://github.com/ssire/oppidum.git
    cd oppidum/scripts
    ./start.sh

Vous devriez alors pouvoir pointer votre navigateur sur l'URL `localhost:8080/exist/projets/oppidum` et voir le message suivant :

     Oppidum
     Version Beta
     © 2011-2012 Oppidoc S.A.R.L

signifiant que Oppidum a été bien installé. Une fois cette vérification faite, pointez votre navigateur sur `localhost:8080/exist/projets/oppidum/install` et cochez au moins le groupe config du panneau Code pour installer les fichiers de configuration de Oppidum.

Vous pouvez utiliser le script `scripts/stop.sh` pour arrêter eXist, à condition de l'éditer et de mettre le bon mot de passe administrateur de la BD dedans (par défaut mis à _test_).

3. Architecture
------------

Le cycle de base d'Oppidum, détaillé sur le diagramme ci-dessous, est le suivant:

- convertir la requête HTTP en une commande
- valider la commande
- générer un pipeline (d'erreur ou d'exécution) pour représenter la ressource et/ou le résultat de l'action concernée
- exécuter le pipeline

La commande et le pipeline sont des documents XML manipulés en interne par le framework.

<img src="../images/architecture.png" style="max-width: 18cm" alt="Architecture"/>

Le script `controller.xql` doit se trouver à la racine de l'application et appeler les bonnes méthodes de `command.xqm` et de `pipeline.xqm`. Ce script contient actuellement le mapping déclaré en ligne dans une variable.

La meilleure manière d'écrire le contrôleur est de le recopier depuis une application existante et de l'adapter pour une nouvelle application. À terme le mapping sera sorti du script et placé dans la BD.

### 3.1 Modules

Le noyau de la librairie est formé de 5 modules XQuery situés dans le répertoire `lib` de la distribution :

- Le module `command.xqm` prend en entrée une requête HTTP, le fichier de mapping de l'application et génère un document XML représentant la commande de l'utilisateur (méthode `oppidum:parse-url`).

  Ce module est utilisé par le module suivant (`pipeline.xqm`), à priori vous n'avez pas besoin de l'utiliser directement.

- Le module `pipeline.xqm` prend en entrée une commande et génère une implémentation de pipeline pour le filtre de servlet XQueryURLRewrite d'eXist (méthode `oppidum:pipeline`). 

  Ce module doit être importé par votre script `controller.xql` pour invoquer le point d'entrée d'Oppidum `gen:process`.

- Le module `epilogue.xqm` contient des fonctions utilitaires pour simplifier la création de l'épilogue du site (cf. ci-dessous).

  Ce module est à importer dans votre script `epilogue.xql`.

- Le module `util.xqm` contient des fonctions de support pour gérer les message d'information ou d'erreur à l'utilisateur, des fonctions pour implémenter un pseudo-langage de gestion des droits d'accès, et divers autres utilitaires. 
  
  Ce module est à importer dans tout script XQuery qui souhaite utiliser les fonctions de support d'Oppidum.

- Le module `install.xqm` contient des fonctions pour packager les données du site mais aussi le code du site dans la base de données.

  Ce module est à importer dans votre script d'installation `script/install.xql`.

### 3.2 Exécution

Le pipeline généré est exécuté par le [filtre URLRewriter](http://www.exist-db.org/exist/urlrewrite.xml) d'eXist en faisant appel aux servlets XQuery et XSLT. Le diagramme ci-dessous montre différents modèles d'exécution du pipeline à trois étage pour obtenir  différents types de sorties :

<img src="../images/pipeline.png" style="max-width: 14cm" alt="Architecture"/>

Le modèle d'exécution le plus courant utilise les 3 étages du pipeline pour générer une page HTML en sortie : le script XQuery génère des données XML dans un format quelconque, par contre le script XSLT doit générer une vue à l'intérieur d'un document `<site:view>` spécifique. La vue est un modèle simple et modulaire conçu pour être ensuite inséré dans un gabarit de page par l'épilogue.

L'épilogue est un script `epilogue.xql` qui doit toujours s'appeler ainsi et être placé à la racine de l'application, au même niveau que le script  `controller.xql`. La meilleure manière d'écrire ce script est de le recopier depuis une application existante et de l'adapter pour une nouvelle application.

Il est possible de court-circuiter le modèle d'exécution à 3 étages de plusieurs manières.

En premier lieu, il est possible de spécifier une extension (.raw ou .xml) dans l'URL qui court-circuite le pipeline. L'extension .xml renvoie directement le résultat du premier étage tandis que l'extension .raw renvoie la sortie de la transformation XSLT. Cette 2e possibilité est surtout utilisée pour debugger l'application et devrait être désactivée en production.

En second lieu, le mapping peut également spécifier des pipelines incomplets, de manière à générer des représentations dans d'autres formats. Par exemple le passage par l'épilogue n'est pas nécessaire pour générer du JSON à partir du modèle ou de la vue, de même pour générer une réponse XML à une requête Ajax.

Finalement, il est également possible de spécifier dynamiquement à l'intérieur d'un modèle XQuery qu'un pipeline doit se terminer par une redirection (avec la méthode `oppidum:redirect`), dans ce cas l'exécution de l'épilogue se limite à appeler `response:redirect-to` sur la réponse.

4. Les langages spécifiques
------------------------

Oppidum introduit plusieurs languages XML pour décrire et découpler les différentes facettes d'une application web de manière déclarative. Le _mapping_ est le plus important du point de vue du développeur de site. Il représente l'espace d'entrée de l'utilisateur (les URLs) et son association avec les pipelines servant à générer les représentations des ressources associées. La _commande_ et le _pipeline_ sont utilisés en interne pour exécuter les requêtes. La connaissance du langage décrivant la commande est utile pour les développeurs des modèles XQuery car la commande est disponible aux scripts sous forme d'un attribut de la requête. Le pipeline est le moins important des trois, il peut être utile néanmoins de le connaître pour debugger. 

Les autres languages spécifiques servent à écrire des gabarits de pages (ou mesh) qui factorisent les blocs courants d'une application (en-tête, menu de navigation, etc.), à associer un ensemble de fichiers CSS et Javascripts baptisés _skin_ avec une URL, à lister les resources à installer dans la BD pour utiliser l'application, et à définir un mécanisme de contrôle d'accès.

### 4.1 Le mapping

Le mapping décrit l'architecture REST du site, c'est-à-dire qu'il définit l'ensemble des ressources, des contrôleurs et des actions qu'il est possible d'exprimer sous forme d'URLs et de méthodes HTTP. Il définit également les pipelines à mettre en oeuvre pour générer les représentation de ces resources ou effectuer les actions des contrôleurs.

Le mapping décrit l'arborescence du site par un arbre XML composé de deux types d'éléments: *item* et *collection*. Ces deux éléments portent un attribut *@name* qui correspond à un segment de l'URL identifiant une ressource.

Prenons l'exemple fictif suivant :

    <site>
      <item name="home"/>
      <item name="projets">
        <item name="axel"/>
        <item name="oppidum"/>
      </item>
    </site>

Il décrirait un site composé des ressources suivantes: `/home`, `/projets`, `/projets/axel`, `/projets/oppidum`.

L'élément collection définit des ressources contenant un nombre indéfini de ressources dont les noms sont également indéfinis. Un élément item anonyme (sans attribut name) représente les ressources contenues dans la collection.

Prenons l'exemple d'un annuaire de sociétés suivant :

    <site>
      <collection name="societes">
        <item/>
      </collection>
    </site>

Il pourrait contenir les ressources suivantes : `/societes/`, `/societes/1`, `/societes/2`.

Il pourrait tout aussi bien contenir les ressources suivantes, puisqu'aucune contrainte ne pèse sur le nom de l'item anonyme : `/societes/`, `/societes/edsi-tech`, `/societes/docetis`, `/societes/oppidoc`.

Il est également possible d'inclure des éléments item non anonymes au sein d'une collection. Dans ce cas ils décrivent la ressource de la collection de même nom qui n'est alors plus représentée par l'élément item anonyme.

Par exemple si l'annuaire concerne des sociétés installées en France ou en Suisse, il est possible de créer deux ressources pour représenter la liste des sociétés implantées respectivement dans chaque pays:

    <site>
      <collection name="societes">
        <item/>
        <item name="France"/>
        <item name="Suisse"/>
      </collection>
    </site>

La définition ci-dessus ajouterait les ressources `/societes/France` et `/societes/Suisse` au site.

Si le nombre de  pays couverts par l'annuaire n'est pas connu d'avance, il est  préférable de créer une nouvelle collection de pays au sein de la collection sociétés : la ressource associée à chaque pays représentera le catalogue des sociétés de ce pays. Dans ce cas il suffit d'ajouter une collection pays dans la collection sociétés contenant un item anonyme pour représenter le pays :

    <site>
      <collection name="societes">
        <item/>
        <collection name="pays">
          <item/>
        </collection>
      </collection>
    </site>

Avec la définition ci-dessus il devient possible, en plus des URLs déjà indiquées, d'utiliser des URLs de la forme : `/societes/pays/USA` ou bien `/societes/pays/Mexique`

Ces exemples montrent la souplesse de l'imbrication de seulement deux types d'éléments collection et item (anonyme ou non) pour modéliser une hiérarchie des ressources. **Tous les sites réalisés avec Oppidum doivent au préalable être modélisés suivant cette hiérarchie**.

#### Collection et ressource de référence

Chaque élément collection ou item du mapping peut définir explicitement une collection et une resource *de référence* dans la BD. La collection est identifiée avec l'attribut *@db* de la racine du mapping, obligatoire, et avec la valeur de l'attribut *@collection* de l'élément ou de son ancêtre le plus proche qui en possède un (héritage). De même la resource de référence au sein de la collection de référence est identifiée avec la valeur de l'attribut *@resource* de l'élément ou de son ancêtre le plus proche.

La collection et la ressource de référence sont un moyen simple pour communiquer au modèle la resource à extraire de la BD dans le cas d'un isomorphisme total ou partiel entre ressources du site (au sens REST) et ressources de la base de données (au sens stockage).

De plus, les attributs *collection* et *resource* peuvent contenir des variables `$NB` pour extraires les segments de rang *NB* de l'URL.

Ainsi avec l'exemple suivant (incomplet pour simplifier) :

    <site db="/db/sites/app">
       <collection name="blog" collection="blog">
          <item collection="blog/$2" resource="entry.xml">
            <collection name="images" collection="blog/$2/images" resource="$4">
               <item/>
            </collection>
          </item>
       </collection>
    </site>

L'URL `/blog/10-mai-2011` est associée avec la resource `entry.xml` située dans la collection `/db/sites/app/blog/10-mai-2011`.

L'URL `/blog/10-mai-2011/images/3.jpeg` est associée avec la resource `3.jpeg` dans la collection `/db/sites/app/blog/10-mai-2011/images`.

#### Déclaration du mapping

Le mapping est déclaré directement comme une variable dans le fichier `controller.xql` du site :

    declare variable $mapping := <site>...</site>

À l'avenir nous encourageons la déclaration du mapping dans un fichier `mapping.xml` à copier à l'emplacement `/db/www/{app}/config/mapping.xml` dans la BD. Il est alors possible de le déclarer avec:

    declare variable $mapping := fn:doc(`/db/www/{app}/config/mapping.xml`)

#### Attributs hérités dans le mapping

Les attributs suivants sont _hérités_ dans le mapping, c'est-à dire que lorsqu'ils sont déclarés sur un élement `site` (la racine), `collection` ou `item` ils sont copiés sur son élément fils, sauf si le fils redéfini l'attribut correspondant :

- attribut `db`
- attribut `collection` (la collection de référence)
- attribut `resource` (la ressource de référence)
- attribut `access` (les droits d'accès en lecture, c-a-d pour le GET)

### 4.2 La commande (_interne_)

La commande contient toutes les informations extraites par Oppidum de la requête HTTP et du mapping. Elle sert à générer le pipeline. Vous pouvez voir la commande en utilisant l'argument `?debug=true` dans n'importe quelle URL (voire la section *debugger*).

Exemple de commande:

    <command base-url="/exist/projets/platinn/" app-root="/projets/platinn/"
             exist-path="/revues/" lang="fr" db="/db/sites/platinn" error-mesh="standard" 
             trail="revues" action="GET" type="collection">
        <resource name="revues" db="/db/sites/platinn" collection="focus"
                  template="templates/form-focus" epilogue="standard" supported="ajouter" method="POST">
              <model src="models/revues.xql"/>
              <view src="views/revues.xsl"/>
        </resource>
    </command>

La commande est un élément *command* avec les attributs suivants :

- *base-url* contient la partie de l'URL menant à l'application, pour un site qui s'exécute directement sur la racine du site, elle vaut "/", cet attribut peut servir à générer des URLs absolues, entre autre dans l'épilogue

- *app-root* contient le chemin menant au fichier `controller.xql` de l'application, il est utilisé en interne par Oppidum pour indiquer le chemin des scripts à exécuter dans le pipeline

- *exist-path* est le contenu de la variable `$exist:path` transmise par eXist au contrôleur (cf. documentation eXist)

- *trail* indique la cible de la requête, c'est la partie de l'URL située après la base menant à l'application, cet attibut peut servir à générer des URLs, entre autre dans l'épilogue

- *type* est le type d'élément ciblé dans le mapping (collection ou item)

- *action* est l'action ciblée

- *lang* est la langue courante

- *error-mesh* est le nom du gabarit à utiliser pour restituer les erreurs de validation survenant en amont de la génération du pipeline, il est recopié de la racine du mapping

- *db* est la base de données utilisée par la site, il est recopié de la racine du mapping

La commande contient toujours un élément fils *resource* qui correspond à l'élément item ou collection ciblé par la requête de l'utilisateur. Celui-ci reprend les attributs portés par cet élément dans le mapping.

La commande est mise à disposition des scripts XQuery dans un paramètre `oppidum.command` de la requête accessible avec l'instruction suivante :

    let $ref := request:get-attribute('oppidum.command')
    
Le fait d'avoir renommée *collection* ou *item* en *resource* dans la commande permet de simplifier les expressions XPath utilisant la commande. Il est ainsi possible d'écrire `$ref/resource/@collection` au lieu de `$ref/(item|collection)/@collection` si le script attend l'un ou l'autre type de cible. L'API Oppidum en cours de finalisation offre des accesseurs pour accéder aux différentes parties de la commande, le but étant de rompre la dépendance entre une application et la structure de la commande. 

### 4.3 Les pipelines (_internes_)

L'arbre du site constitué des éléments collection et item sert aussi à déclarer les pipelines associés à chaque ressource. L'arbre est augmenté à cette fin avec de nouveaux éléments et attributs : les éléments fils *model* et *view*, ainsi que l'attribut *@epilogue*.

Prenons l'exemple suivant :

    <collection name="societes" epilogue="standard"/>
      <model src="models/societes.xql"/>
      <view src="views/societes.xsl"/>
    </collection>

Il déclare que pour une requête GET sur la ressource `/societes`, la représentation retournée est générée par l'exécution du script XQuery `models/societes.xql`, puis transformation du résultat par la feuille de style `views/societes.xsl`, et enfin par insertion dans le gabarit de page `standard.xhtml` par l'épilogue du site.

Les chemins d'accès aux scripts XQuery ou XSLT sont exprimés relativement au fichier `controller.xql` à la racine de l'application. Il est toutefois possible d'utiliser le préfixe `oppidum:` devant le chemin pour désigner un  scripts fourni en standard avec Oppidum. Par exemple le chemin `oppidum:models/lore-ipsum.xql` désigne le générateur de contenu *lore ipsum* fourni par Oppidum.

Il est également possible de définir des actions asociées avec une ressource à l'aide de l'attribut *@supported* et en utilisant l'élément fils *action*. Prenons la déclaration suivante :

    <collection name="societes" epilogue="standard" supported="ajouter"/>
      <model src="models/societes.xql"/>
      <view src="views/societes.xsl"/>
      <action name="ajouter" epilogue="standard">
        <model src="oppidum:actions/bootstrap.xql"/>
        <view src="views/ajouter.xsl"/>
      </action>
    </collection>

Elle transforme la ressource sociétés en un contrôleur acceptant une action "ajouter". L'action est invoquée par l'URL suivante: `/societes/ajouter`. Celle-ci peut servir à  retourne une page pour créer une nouvelle société en utilisant la librairie AXEL. Comme pour la requête GET, le pipeline de l'action est déclaré par un triplet *model*, *view* et *@epilogue*.

Oppidum convertit automatiquement les verbes HTTP en actions. Ils sont déclarés dans un attribut *@method* distinct de l'attribut *@supported*.

A titre d'exemple le traitement de la soumission d'une nouvelle société créée avec la page d'édition de société *ajotuer* est défini avec la déclaration suivante :

    <collection name="societes" epilogue="standard" supported="ajouter" method="POST"/>
      <action name="POST">
        <model src="actions/post.xql"/>
      </action>
    </collection>

Cette fois-ci le pipeline se compose d'un unique modèle, car il retourne un message de succès ou d'erreur (XML ou JSON) à la requête Ajax de la page d'édition.

#### Le pipeline abstrait

Oppidum génère en fait le pipeline en 2 passes. Dans la première passe il génère un pipeline *abstrait* qui n'est pas dépendant d'une implémentation. Dans la seconde passe il génère le pipeline exécutable par l'environnement hôte.

De manière succinte, le pipeline abstrait se compose des éléments suivants :

- un élément *model* qui désigne un script XQuery dans un attribut *@src*
- un élément *view* qui désigne une transformation XSLT dans un attribut *@src*
- un élément *epilogue* qui désigne le nom du gabarit à utiliser dans l'épilogue (un identifiant) dans un attribut *@mesh*

Ces éléments sont obtenus en combinant la commande et le mapping.

Voici un exemple de pipeline abstrait :

    <pipeline>
      <model src="models/revues.xql"/>
      <view src="views/revues.xsl"/>
      <epilogue mesh="standard"/>
    </pipeline>

#### Le pipeline  exécutable

Le pipeline exécutable est une traduction du pipeline abstrait exécutable dans la plateforme hôte. Avec eXist il utilise le langage du [filtre URLRewriter](http://www.exist-db.org/exist/urlrewrite.xml). 

### 4.4 Les gabarits de pages (ou mesh)

Le script `epilogue.xql` standard génère le contenu de la réponse HTTP en transformant le gabarit identifié par l'attribut `@epilogue` du mapping. Cette transformation consiste à recopier le gabarit et à remplacer les éléments qui sont dans le namespace `xmlns:site="http://oppidoc.com/oppidum/site"` soit par le contenu des éléments de nom équivalent fils directs de la racine `site:view` des données transmises à l'épilogue par le pipeline, soit par le résultat d'une fonction XQuery de nom équivalent définie dans l'épilogue.

Ce mécanisme est très pratique pour factoriser et insérer les composants classiques d'une application web tels que les bouton de LOGIN ou les menus primaires et secondaires. Notez que si le mapping ne définit pas d'attribut `epilogue`, l'épilogue standard recopie simplement son entrée dans la réponse HTTP.

### 4.5 Les skins

Le script `epilogue.xql` standard définit une méthode `site:skin` à invoquer via un élément `site:skin` à placer dans un gabarit pour insérer les fichiers CSS et les fichiers Javascript associés avec la représentation de l'URL courante. Cette méthode interprète l'attribut `@skin` de l'élément `site:view` transmis par le pipeline à l'épilogue comme une liste d'identifiants représentant les _skins_ à intéger dans la page. Chaque identifiant est associé avec un ensemble de fichiers CSS et Javascript qui sont déclarés un fichier `init/skin.xml` propre à l'application. Ce fichier doit être recopié à l'emplacement `/db/www/{app}/config/skin.xml` dans la BD. 

Notez que le fichier `skin.xml` d'une application peut faire appel à des _skins_ prédéfinies fournies avec la librairie Oppiduum et qui doivent être définies à l'emplacement `/db/www/oppidum/config/skin.xml` (installé par le script d'installation de Oppidum).

### 4.6 L'installation

Oppidum fourni un module pour créer des scripts d'installation de l'application dans la BD. Celui-ci s'appuie sur un langage XML décrivant les utilisateurs, les collections et les ressources à créer.

Le langage d'installation sert à déclarer plusieurs variables dans le scripts `/scripts/install.xql` dans le répertoire de l'application.

### 4.7 Le contrôle d'accès

Celui-ci ci est décrit dans la section *Gestion des erreurs et du contrôle d'accès* ci-dessous.

5. Structure recommandée d'une application
------------------------

Les premiers projets réalisés avec Oppidum nous ont amené à privilégier l'organisation des fichiers de chaque application de la manière suivante :

    actions/
    controller.xql
    epilogue.xql
    init/
    mesh/
    models/
    modules/
    ressources/
    scripts/
    templates/
    views/

Les fichiers `controller.xql` et `epilogue.xql` sont **obligatoires** et leur emplacement est fixe. Comme ils sont semblables d'un projet à l'autre, le plus simple est de partir d'un projet existant pour les copier et les adapter.

Le fichier *controller.xql* est imposé par eXist-DB. C'est le fichier qui recevra toutes les requêtes HTTP de l'utilisateur et qui appelera la librairie Oppidum pour générer le pipeline à exécuter. Dans la version actuelle il contient également la déclaration du mapping dans une variable.

Le fichier *epilogue.xql* est exécuté par le pipeline pour insérer le résultat du traitement de la requête dans un gabarit de site.

Les répertoires *models* et  *actions* contiennent les scripts XQuery qui implémentent respectivement les modèles des ressources et des actions de l'application.

Le répertoirs *views* contient les scripts XSLT qui implémentent les vues.

Le répertoire *modules* contient également des scripts de vues et de modèles, mais en les regroupant par modules fonctionnels de manière à simplifier le partage entre applications (pour le moment par recopie du répertoire contenant le module intéressant).

Le répertoire *init* contient les fichiers de configuration de l'application qui seront copiés dans la collection `/db/www/{app}/config` de l'application ainsi que les éventuels fichiers utilisés pour générer les données initiales dans `/db/sites/{app}/` ou pour tester l'application. Le contenu de ce répertoire sera copié dans la BD à l'aide du script d'installation.

Le répertoire *scripts* contient le script d'installation `install.xql` pour installer l'applications dans la BD et créer un jeu d'utilisateurs minimal. Il peut éventuellement contenir d'autres scripts utilisés pendant le développement (par exemple des scripts ant pour le packaging ou le déploiement).

Le répertoire *resources* contient toutes les ressources statiques du site regroupées en sous-répertoires (e.g. CSS, Javascript, images). Oppidum fournit quelques méthodes pour générer des URLs pointant vers ces ressources de la forme `/static/{app}` (ou `/static/oppidum` pour les ressources statiques partagées par Oppidum telles que la librairie AXEL). En production ces URLs devraient être servies directement par le proxy Web sans passer par la base de données pour bénéficier d'une politique de cache efficace.

Le répertoire *mesh* contient le ou les gabarits utilisés dans l'application (par exemple un gabarit spécifique pour les pages d'erreur). Chaque gabarit est un fichier XHTML. En se débrouillant bien chaque fichier gabarit devrait pouvoir s'afficher directement dans le navigateur Web pour tester les fichiers CSS correspondants.

Enfin le répertoire *templates* regroupe les templates XTiger XML utilisés par le site.

Notez que la librairie Oppidum contient en plus un répertoire *config* . Celui-ci contient des fichiers de configuration spécifiques de eXist-DB et de l'environnement servlet (`conf.xml`, `controller-config`, `log4j.xml` et `web.xml`) qui sont utilisés pour générer les fichiers WAR lors du packaging à destination de différents environnements d'exécution (e.g. Tomcat) pour la pré-production ou la production.

6. Cycle de développement
----------------------

### 6.1 Développement

Suivre les instructions pour l'installation ci-dessus.

Le développement s'effectue en créant un répertoire `projets` directement dans le répertoire `webapp` d'une installation d'eXist (pour le moment le nom `projets` est fixé). Ce répertoire projet contient le répertoire `oppidum` avec la distribution Oppidum. Placez vos applications en cours de développement dans des répertoires `{app}` du nom de l'application dans des répertoires frères du répertoire `oppidum`, vous devriez obtenir la structure suivante:

    {exist-home}/webapps
    {exist-home}/webapps/projets
    {exist-home}/webapps/projets/oppidum
    {exist-home}/webapps/projets/{app}

L'intérêt est ainsi de pouvoir accéder dans le même serveur à toute l'aide en ligne de eXist, à la sandbox (`http://localhost:8080/exist`) et à la ou les application(s) en cours de développement (`http://localhost:8080/exist/projet/{app}/`).

L'intérêt est aussi de pouvoir mettre le répertoire `/projet/{app}` sous contrôle du code source avec un système comme SVN ou GitGub.

### 6.2 Pré-production et production

Pour la pré-production et la production sous Tomcat, nous recommandons de placer toute l'application dans la base de donnée pour faciliter la maintenance et les évolutions. Voir à ce sujet le guide [Packager et déployer une application avec Oppidum](packaging.html).

### 6.3 Debug

Ajouter `.debug` ou `?debug=true` à une URL pour voir tous les attributs ajoutés par Oppidum à la requête et qui sont accessibles avec `request:get-attribute` dans les modèles XQuery. L'affichage en mode debug montre également la commande ainsi que les pipelines générés, c'est un bon moyen pour comprendre le fonctionnement d'Oppidum.

Ajouter `.raw` à une requête pour voir la sortie de l'étape 2 du pipeline (transformation XSLT).

Ajouter `.xml` à une requête pour voir la sortie de l'étape 1 du pipeline (modèle XQuery).

Utiliser les méthodes `oppidum:log` et `oppidum:log-parameters` du module `util.xqm` pour créer des traces d'exécution dans un fichier `site.log` conservé avec les autres fichiers de log (`exist.log` et `url-rewrite.log`).

7. Gestion des erreurs et contrôle d'accès
----------------

Oppidum est capable de détecter certaines erreurs ou situations particulières nécessitant d'interrompre le traitement de la requête. Dans ce cas Oppidum génère un pipeline d'erreur en lieu et place du pipeline qui aurait dû être généré.

Il est également possible de signaler une erreur pendant l'exécution d'un script XQuery faisant partie du pipeline généré (soit le modèle ou l'épilogue donc).

Dans tous les cas les messages d'erreurs sont conservés dans la base de données dans la ressource `/db/oppidum/config/errors.xml`, ceci pour simplifier la gestion multilingues et partager certains messages. Chaque application peut ajouter ses propres messages ou redéfinir ceux d'Oppidum en déclarant une resource `/db/sites/{app}/config/erros.xml`.

### 7.1 Génération automatique du pipeline d'erreur

Les cas suivants interrompent le processus standard de génération du pipeline et génère à la place un pipeline d'erreur :

- erreur dans l'URL ou le mapping
- validation des resources dans la base de données
- contrôle d'accès

#### Erreur dans l'URL ou le mapping

Si la requête porte sur une URL qui n'a pas d'entrée correspondante dans le mapping, ou si l'entrée correspondante est inexacte.

#### Validation des resources dans la base de données

Si le mapping correspondant à la ressource REST demandée porte un attribut *@check="true"*, alors Oppidum contrôle de l'existence de ressource de référence et génère une erreur si celle-ci nexiste pas.

#### Contrôle d'accès

Il est possible d'effectuer un contrôle d'accès en insérant des blocs `access` dans le mapping du site. Ce bloc définit des règles qui s'appliquent soit à l'item parent, soit à la collection parente suivant le contexte du bloc.

À titre d'exemple le bloc suivant indique que seul l'utilisateur dont le login est *focus* ou bien un utilisateur appartenant au groupe *site-member* est autorisé à lire une ressource (action *GET*). Seul l'utilisateur *focus* est autoriser à sauvegarder cette ressource (action *POST*) ou à effectuer l'action *ajouter* (i.e. ajouter une nouvelle page dans la collection en utilisant  AXEL pour l'éditer).

    <access>
      <rule action="GET" role="u:focus g:site-member" message="rédacteur"/>
      <rule action="POST ajouter" role="u:focus" message="administrateur du site"/>
    </access>

Les concepts de login ou de groupe sont équivalent au *user* ou au *group* de eXist.

Le role est défini par un pseudo-langage qui comporte 4 éléments:

- `u:name` : pour désigner l'utilisateur *name*
- `g:name` : pour désigner un membre du groupe *name*
- `all` : pour désigner n'importe qui
- `owner` : pour désigner le propriétaire de la ressource / collection de référence (PAS IMPLÉMENTÉ)

Par défaut le rôle `all` s'applique à toutes les ressources et à toutes les actions définies dans le mapping.

Ce pseudo-langage est implémenté dans le module `lib/util.xqm` d'Oppidum.

L'attribut `message` contient une indice qui peut s'insérer dans le message d'erreur (`ACTION-LOGIN-FAILED`) généré en cas d'accès refusé.

Notons qu'il est également possible de définir un bloc `access` par défaut à l'aide d'une variable dans le contrôleur :

    declare variable $access := <access>...</access>

Cette variable est passée au moment de la validation des droits et de l'autorisation d'accès aux méthodes `oppidum:get-rights-for` et `oppidum:check-rights-for` (cf. le contrôleur d'un site existant).

### 7.2 Génération d'erreur pendant l'exécution du pipeline généré

Méthode `oppidum:throw-error` du module `util.xqm`. _A REDIGER_

8. Créations de page éditables avec AXEL
--------------

Oppidum intègre la librairie AXEL et ses extensions AXEL-FORMS pour créer des formulaires.

9. Création de modules partagés
-------

Le préfixe `{module}:` dans les chemins spécifiés dans les mappings où _module_ est le nom d'un répertoire frère du répertoire `oppidum` a pour but de développer des modules partagés entre les applications basées sur Oppidum.

10. Évolutions futures
-------------

- **Intégration de XProc**

  Possibilité d'appeler un pipeline XProc comme modèle, vue ou épilogue d'un pipeline.


- **Internationalisation et localisation**

  Ajout d'un traitement post-epilogue pour localiser le texte.

- **Epilogue en XSLT**

  Possiblité de remplacer le script `epilogue.xql` par une transformation `epilogue.xsl`

- **Modélisation de vues partielles**

  Extension du mapping pour pouvoir réutiliser et combiner facilement plusieurs modèles / vues pour générer une seule resource. Par exemple pour faire un blog, les *latest comments* ou les *latest entries* affichés dans les colonnes latérales sont des blocs présents sur toutes les pages, chaque bloc pourrait être généré par un modèle/vue partiels (à prévoir en se basant sur l'intégration XProc). Actuellement ce type de vues partielles est en général réalisé à l'aide de fonctions XQuery spécifiques déclarées dans le script `epilogue.xql`.

- **Mettre en cache les pages pour éviter de les générer à chaque requête**

  Le mapping peut conduire à créer et mettre à jour une collection `/db/caches/{app}` mirroir de l'architecture REST et contenant des caches pour chaque page. Prévoir dans ce cas une extension de l'API `oppidum:invalidate()` par exemple pour invalider la page courante, et une version plus élaborée pour invalider plusieurs pages.

- **Alternatives à eXist-db**

  La version actuelle d'Oppidum est fortement lièe à la base de donnée eXist-DB, mais son architecture a été conçue pour qu'il soit possible de le porter à l'avenir sur d'autres environnements (XProc, Sausalito, MarkLogic).
