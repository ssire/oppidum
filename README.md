Oppidum - Open source XML MVC framework for eXist-db
=======

Oppidum is an XML-oriented MVC framework written in XQuery / XSLT / Javascript. It allows to develop applications on top of the [eXist-db]([http://exist-db.org/) native XML database. It is designed to create custom content management solutions (CMS) involving lighweight XML authoring chains.

Oppidum is developped and maintained by Stéphane Sire at [Oppidoc](http://www.oppidoc.com).

How does it work ?
------------------

Oppidum takes a declarative approach to web application development :

1. all the application REST mappings are declared in a special `mapping.xml` file
2. each mapping entry define a rendering pipeline to render the page
3. the first pipeline step generates a model with an XQuery script
4. the second pipeline step generates a view with an XSLT transformation
5. the last pipeline step integrates the result of the previous step into a mesh
6. all the steps above can be optional and the mesh can trigger further actions

Besides the steps above, Oppidum provides support to skin applications (a skin is a set of CSS and JavaScript files), to implement access control rules with form-based identification and to manage a multi-phases development cycle (dev, test and prod).

Oppidum is designed to support the creation of reusable modules that can be aggregated together through the mapping mechanism to create complete web applications. Each module is a set of conventions (usually associated with XML vocabularies) and XQuery, XSLT, JavaScript, CSS files.

How to get documentation ?
--------------------------

The Oppidum documentation contained in the `docs` folder is also published on the [Oppidum site](http://ssire.github.com/oppidum/) thanks to the Git Hub project pages mechanism. This is still a work in progress.

You can also visit the [Oppidum wiki](https://github.com/ssire/oppidum/wiki) to get more documentation and to learn about the roadmap.

There is a [tutorial repository](https://github.com/ssire/tutorial) that contains a simple web application written with Oppidum to get started.

We have also setup an [oppidum-dev](https://groups.google.com/forum/?fromgroups#!forum/oppidum-dev) Google group to share assistance and discuss new features.

How to test it ?
----------------

You need to install [eXist-db](http://exist-db.org/exist/download.xml) on your system first. 

Then clone Oppidum from this repository directly inside the `webapp` folder of your eXist installation. We strongly advise to create a `projets` folder inside the `webapp` folder and to checkout oppidum within that folder (actually you MUST name this folder `projets` in french for the automatic installation scripts to work - _this will be corrected_) :

    cd {eXist-Home}/webapp
    mkdir projets
    cd projects
    git clone git://github.com/ssire/oppidum.git

For convenience Oppidum distribution contains a `script/start.sh` shell script that you can use to start eXist-db. Then you can point your browser to `http://localhost:8080/exist/projets/oppidum` to see a version screen. You can use the `script/stop.sh` to stop it (edit the file to set your database password within it). 

You should then develop your application in a sibling folder of the `oppidum` folder inside the `projets` folder.

Oppidum is compatible with exist 1.4.x versions out of the box. We are actually doing efforts to fully integrate it with the new eXist 2.0 release integrated development environment.

How to get most benefits of it ?
----------------

Oppidum has been developped to take benefits of [AXEL]([https://github.com/ssire/axel) (Adaptable XML Editing Library). This is a JavaScript client-side library for generating document editors into web pages. It works by transforming XTiger XML document templates into editable documents. The templates are XHTML files enriched with instrutions to control editing. It can be used together with the [AXEL-FORMS](https://github.com/ssire/axel-forms) extensions to create form-oriented user interfaces with dynamic constraints checking.

Some Oppidum modules are available in different editions to speed up application development (e.g. image or file upload, etc.). You are encouraged to develop and share your own modules.

Editions
--------

Oppidum comes in three editions:

* Public Edition (PE)
* Academic Edition (AE)
* Enterprise Edition (EE)

The public edition is available to everyone free of charge and does not involve any support. This is the edition publicly available on GitHub in this repository.

The academic and the enterprise editions offer special support and development packages targeted at academic institutions or enterprises. Please [contact us](mailto:s.sire@oppidoc.fr?subject=Oppidum editions) for further inquiries.

License
-------

The source code of Oppidum is released as free software, under the terms of the LGPL, please make sure that you read the license file at [http://www.gnu.org/copyleft/lesser.html](http://www.gnu.org/copyleft/lesser.html).

Third-party software
-------

Oppidum is standalone software written in XQuery, XSLT and JavaScript. The current version is tailored to run inside eXist-db environment.

For convenience the repository includes the following pre-built libraries which are often used in web development :

* AXEL ([http://ssire.github.com/axel/](http://ssire.github.com/axel/))
* AXEL-FORMS ([http://ssire.github.com/axel-forms/](http://ssire.github.com/axel-forms/))
* 960 grid system ([http://960.gs/](http://960.gs/))
* JQuery ([http://jquery.com/](http://jquery.com/))
* JQuery UI subset ([http://jqueryui.com/](http://jqueryui.com/))
* Modernizr subset ([http://modernizr.com/](http://modernizr.com/))

however you are totally free to use or not these libraries.
 