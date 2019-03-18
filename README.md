Oppidum - XQuery web application framework for eXist-db
=======

_Last update : 2019-03-12 (by Stéphane Sire)_

Oppidum is an XML-oriented MVC framework written in XQuery / XSLT / Javascript. It allows to develop web applications on top of the [eXist-db](http://exist-db.org/) native XML database.

Oppidum is developped and maintained by Stéphane Sire at [Oppidoc](http://www.oppidoc.com).

How does it work ?
------------------

Oppidum takes a declarative approach to web application development :

1. all the application REST mappings are declared in a special `mapping.xml` file
2. each mapping entry define a rendering pipeline to render the page
3. the first pipeline step generates a model with an XQuery script
4. the second pipeline step generates a view with an XSLT transformation
5. the last pipeline step injects view fragments of the previous step into a page template
6. all the steps above can be optional and the page template generation can trigger further actions

Besides the steps above, Oppidum provides support to skin applications (a skin is a set of CSS and JavaScript files), to implement access control rules with form-based identification and to manage a multi-phases development cycle (dev, test and prod).

Oppidum is designed to support the creation of reusable modules that can be aggregated together through the mapping mechanism to create complete web applications. Each module is a set of conventions (usually associated with XML vocabularies) and XQuery, XSLT, JavaScript, CSS files.

Compatibility and Branches
----------------

Oppidum runs out of the box on computers running Linux and Apple OS X. We haven't tested it on windows computer yet, there should be some issues with path separator in the library code. 

The *master* branch is the stable release branch. It contains the Oppidum current version. It is currently compatible with eXist-2.x, eXist-3.x and eXist-4.x

The *devel* branch is the development branch of Oppidum current version. You should not install it in production.

The *test* branch is a pre-release branch. You should not install it in production.

The *oppidum-1* branch is an archived branch on which we do not plan any evolution. It is required if your application is running with eXist-1.4.3.

Some specific branch may be used to prepare Oppidum next release in particular to adapt to new eXist-DB versions before they are supported in the *master* (or *devel*) branch.


How to install it ?
-------------------

1. install the latest stable release of [eXist-db](http://exist-db.org) on your system first

2. create a project folder that will contain your oppidum applications directly inside the `webapp` folder of your eXist installation, by default you should call it _projects_

3. clone Oppidum inside your projects folder. This should create an `oppidum` folder into your projects folder

4. start eXist-DB then go inside the `oppidum/scripts` folder and execute `./bootstrap.sh` to install some oppidum resources into the database, passing it the database admin password as a parameter

5. that's it ! You can now point your browser to `http://localhost:8080/exist/projects/oppidum` to open the Oppidum developer tools

In summary :

    cd {EXIST_HOME}/webapp
    mkdir projects
    cd projects
    git clone https://github.com/ssire/oppidum.git
    # or git clone git://github.com/ssire/oppidum.git if you have setup ssh with your github account
    cd oppidum/scripts
    ./bootstrap.sh password

### Special settings

You can install and run several eXist-DB instances on your computer, for that purpose you can edit the `EXIST_HOME/tools/jetty/etc/jetty.conf` configuration file for each installation so that they run on different ports.

The installer script from the developer tools deduces the project folder name (e.g. *projects*) from the request URI. In case you want to run it behind a forward proxy configured with path URL rewrite (i.e. to hide out `/exist` prefix in URLs), then you can manually create a `settings.xml` file with the name of you project folder inside a `ProjectFolderName` element  :

      <Settings>
        <ProjectFolderName>projects</ProjectFolderName>
      </Settings>

and store it inside your application `/db/www/{application}/config` collection. This should not be necessary since when using a forward proxy you usually access the Oppidum IDE (and installer) from an SSH tunnel.

How to get documentation ?
--------------------------

The Oppidum documentation contained in the `docs` folder is also published on the [Oppidum site](http://ssire.github.com/oppidum/) thanks to the Git Hub project pages mechanism. This is still a work in progress.

You can also visit the [Oppidum wiki](https://github.com/ssire/oppidum/wiki) to get more documentation and to learn about the roadmap.

There is a [tutorial repository](https://github.com/ssire/tutorial) that contains a simple web application written with Oppidum to get started.

We have also setup an [oppidum-dev](https://groups.google.com/forum/?fromgroups#!forum/oppidum-dev) Google group to share assistance and discuss new features.

As a general introduction you can read the [XML London 2013 presentation of Oppidum](http://xmllondon.com/2013/presentations/sire/). 

How to get most benefits of it ?
----------------

Oppidum has been developped to take benefits of [AXEL](https://github.com/ssire/axel) (Adaptable XML Editing Library). This is a JavaScript client-side library for generating document editors into web pages. It works by transforming XTiger XML document templates into editable documents. The templates are XHTML files enriched with instructions to control editing. It can be used together with the [AXEL-FORMS](https://github.com/ssire/axel-forms) extensions to create form-oriented user interfaces with dynamic constraints checking.

Some Oppidum modules are available as third party projects to speed up application development (e.g. image or file upload, forms generator, etc.). You are encouraged to develop and share your own modules. Please [contact us](mailto:s.sire@oppidoc.fr?subject=Oppidum specific needs) if you have specific needs.

License
-------

The source code of Oppidum is released as free software, under the terms of the LGPL, please make sure that you read the license file at [http://www.gnu.org/copyleft/lesser.html](http://www.gnu.org/copyleft/lesser.html).

Oppidum is Open Source and may be used in academic, non-commercial and commercial applications.

Third-party software
-------

Oppidum is standalone software written in XQuery, XSLT and JavaScript. The current version is tailored to run inside eXist-db environment.

[_DEPRECATED_] For convenience the repository includes the following pre-built libraries for web application development :

* AXEL ([http://ssire.github.com/axel/](http://ssire.github.com/axel/))
* AXEL-FORMS ([http://ssire.github.com/axel-forms/](http://ssire.github.com/axel-forms/))
* 960 grid system ([http://960.gs/](http://960.gs/))
* JQuery ([http://jquery.com/](http://jquery.com/))
* JQuery UI subset ([http://jqueryui.com/](http://jqueryui.com/))
* Modernizr subset ([http://modernizr.com/](http://modernizr.com/))

_As we plan to limit the use of the pre-built libraries to the one needed for the Oppidum developer tools, we advise you to directly embed the pre-built libraries that you need directly in you application directory / code depot, and not depend on the ones shipped with Oppidum._


 