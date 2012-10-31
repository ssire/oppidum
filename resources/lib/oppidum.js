/* Copyright (c) 2012 Oppidoc SARL, <contact@oppidoc.fr>
 *
 * author      : Stéphane Sire
 * contact     : s.sire@free.fr
 * license     : proprietary (this is part of the Oppidum framework)
 * last change : 2012-07-11
 *                         
 * Script to invoke inplace editing with AXEL + oppidum microformat
 *
 * Prerequisites: jQuery + AXEL (https://github.com/ssire/axel)
 *
 * DEPRECATED: replace with axel-forms.js instead !
 */   

// TODO
// - factorize mandatory attributes checking (add an array of mandatory to check
//   when calling registerCommand ?
// - rendre id obligatoire sur Editor
// - si pas de data-target, prendre le nom du 1er Editor disponible (? legacy avec data-role ?)

/*****************************************************************************\
|                                                                             |
|  Editor generation and command registration and management                  |
|  commands are related to editors through a key defined by the data-target   | 
|  of the hosted command and the hosted editor id attribute                   |
|    exposed as GLOBAL.$oppidum                                               |
|                                                                             |
|*****************************************************************************|
|                                                                             |
|  Command support:                                                           |
|    registerCommand                                                          |
|             register a new command constructor                              |
|                                                                             |
|  Generic methods:                                                           |
|    logError(msg)                                                            |
|             display an error message                                        |
|                                                                             |
\*****************************************************************************/
(function (GLOBAL) {

  /////////////////////////////////////////////////
  // <div> Hosted editor
  /////////////////////////////////////////////////
  function Editor (identifier, node, axelPath ) {
    var spec = $(node), 
        name;
    
    this.axelPath = axelPath;
    this.key = identifier;
    this.templateUrl = spec.attr('data-template');
    this.dataUrl = spec.attr('data-src');
    this.cancelUrl = spec.attr('data-cancel');
    this.transaction = spec.attr('data-transaction');
    this.spec = spec;
    
    if (this.templateUrl) {
      // 1. adds a class named after the template on 'body' element
      // FIXME: could be added to the div domContainer instead ?
      name = this.templateUrl.substring(this.templateUrl.lastIndexOf('/') + 1);
      if (name.indexOf('?') != -1) {
        name = name.substring(0, name.indexOf('?'));
      }
      $('body').addClass('edition').addClass(name);
      
      // 2. loads and transforms template and optionnal data
      this.initialize();
      
      // 3. registers optionnal unload callback if transactionnal style
      if (this.cancelUrl) {
        $(window).bind('unload', $.proxy(this, 'reportCancel'));
      }
    } else {
      $oppidum.logError('Missing data-template attribute to generate the editor "' + this.key + '"');
    }
    
    // 4. triggers completion event
    $(document).triggerHandler('AXEL-TEMPLATE-READY', [this]);
  };
  
  Editor.prototype = {
    
    attr : function (name) {
      return this.spec.attr(name);
    },
    
    initialize : function () {
      var errLog = new xtiger.util.Logger(),
          template, data, dataFeed,
          
      template = xtiger.debug.loadDocument(this.templateUrl, errLog);
      if (template) { 
        this.form = new xtiger.util.Form(this.axelPath);
        this.form.setTemplateSource(template);
        this.form.setTargetDocument(document, this.key, true); // FIXME: "untitled" does not work 
        this.form.enableTabGroupNavigation();
        this.form.transform(errLog);
        if (this.dataUrl) { 
          // loads XML data inside the editor
          data = xtiger.cross.loadDocument(this.dataUrl, errLog);
          if (data) {                                   
            if ($('error > message', data).size() > 0) {
              errLog.$oppidum.logError($('error > message', data).text());
              // FIXME: disable commands targeted at this editor ?
            } else {
              dataFeed = new xtiger.util.DOMDataSource(data);
              this.form.loadData(dataFeed, errLog);
            }
          }
        }                        
      }
      if (errLog.inError()) {
        $oppidum.logError(errLog.printErrors());
      }
    },
    
    // Removes all data in the editor and starts a new editing session
    // Due to limitations in AXEL it reloads the templates and transforms it again
    reset : function () {
      var errLog = new xtiger.util.Logger();
      if (this.form) {
        this.form.transform(errLog);
      }
      if (errLog.inError()) {
        $oppidum.logError(errLog.printErrors());
      }
    },
    
    serializeData : function (event) {
      var logger, res;
      if (this.form) {
        logger = new xtiger.util.DOMLogger();
        this.form.serializeData(logger);
        res = logger.dump();
      }
      return res;
    },
    
    reportCancel : function (event) {
      if (! this.hasBeenSaved) { // trick to avoid cancelling a transaction that has been saved
        $.ajax({
          url : this.cancelUrl,
          data : { transaction : this.transaction },
          type : 'GET', 
          async : false
          });
      }
    }
  };
  
  var sindex = 0, cindex = 0;
  var registry = {}; // Command class registry to instantiates commands
  var editors = {}; // 
  
  GLOBAL.$oppidum = {
      // FIXME: search for "#error" div to report errors
      logError : function (msg) {
        alert(msg);
      },
      
      // Adds a new command factory 
      registerCommand : function (name, factory) { 
        registry[name] = factory; 
      },
      
      // Creates a new editor from a DOM node and the path to use with AXEL
      createEditor : function (node, axelPath) {
        var key = $(node).attr('id') || 'untitled' + (sindex++);
        editors[key] = new Editor(key, node, axelPath);
      },
      
      // Creates a new command from a DOM node
      createCommand : function (node) {
        var type = $(node).attr('data-command'); // e.g. 'save', 'submit'
        var key =  $(node).attr('data-target') || 'untitled' + (cindex++);
        if (registry[type]) {
          new registry[type](key, node); // new command should be bound to 'click' event
        } else {
          logError('Attempt to create an unkown command "' + type + '"');
        }
      },
      
      getEditor : function (key) {
        return editors[key];
      }
  };
  
  function install () { 
    var axelPath = $('script[data-bundles-path]').attr('data-bundles-path'),
        editors = $('div[data-template]');
    // creates editors (div with 'data-template')
    if (editors.length > 0) {
      if (axelPath) {
        editors.each(
          function (index, elt) {
            $oppidum.createEditor(elt, axelPath);
          }
        );
      } else {
        $oppidum.logError('Cannot start editing because AXEL library path is unspecified');
      }
    }
    // creates commands
    $('*[data-command]').each(
      function (index, elt) {
        $oppidum.createCommand(elt);
      }
    );
  };
    
  // onDOMReady
  jQuery(function() { install(); });
}(window));
  
/*****************************************************************************\
|                                                                             |
|  'submit' command object (XML submission through a form)                    |
|                                                                             |
|*****************************************************************************|
|                                                                             |
|  Required attributes :                                                      |
|  - data-target : id of the editor's container                               |
|  - data-form : id of the form to use for submission                         |
|                                                                             |
\*****************************************************************************/
(function () {

  function SubmitCommand ( identifier, node ) {
    var spec = $(node);
    this.key = identifier; /* data-target */
    this.formid = spec.attr('data-form');
    if ($oppidum.getEditor(this.key)) { // checks editor existence
      if (this.formid && ($('form#' + this.formid).length > 0)) { // checks form element existence
        node.disabled = false;
        spec.bind('click', $.proxy(this, 'execute'));
      } else {
        node.disabled = true;
        $oppidum.logError('Missing or invalid data-form attribute in submit command ("' + this.formid + '")');
      }
    } else {
      node.disabled = true;
      $oppidum.logError('Missing or invalid data-target attribute in submit command ("' + this.key + '")');
    }
  };

  SubmitCommand.prototype = {
    // Saves using a pre-defined form element identified by its id
    // using a 'data' input field (both must be defined)
    // Note in that case there is no success/error feedback
    execute : function () {
      var f = $('#' + this.formid),
          d = $('#' + this.formid + ' > input[name="data"]' ),
          editor = $oppidum.getEditor(this.key);
      if (editor && (f.length > 0) && (d.length > 0)) {
        d.val(editor.serializeData());
        f.submit();
      } else {
        $oppidum.logError('Missing editor or malformed form element to submit data');
      }
    }
  };

  $oppidum.registerCommand('submit', SubmitCommand);
}());

/*****************************************************************************\
|                                                                             |
|  'preview' command object                                                   |
|                                                                             |
|*****************************************************************************|
|                                                                             |
|  Required attributes :                                                      |
|  - none : currently the command is targeted at all the editors through      |
|    the body tag                                                             |
|                                                                             |
\*****************************************************************************/
(function () {  
  function PreviewCommand ( identifier, node ) {
    var spec = $(node);
    this.label = {
      'preview' : spec.attr('data-preview-label') || spec.text(),
      'edit' : spec.attr('data-edit-label') || 'Edit'
    }
    spec.bind('click', $.proxy(this, 'execute'));
  };
  
  PreviewCommand.prototype = {
    execute : function (event) {
      var body = $('body'),
          gotoPreview = ! body.hasClass('preview');
      $(event.target).text(this.label[gotoPreview ? 'edit' : 'preview']);
      body.toggleClass('preview', gotoPreview);
    }
  };
  
  $oppidum.registerCommand('preview', PreviewCommand);
}());

/*****************************************************************************\
|                                                                             |
|  'reset' command object                                                   |
|                                                                             |
|*****************************************************************************|
|                                                                             |
|  Required attributes :                                                      |
|  - data-target : id of the editor's container                               |
|                                                                             |
\*****************************************************************************/
(function () {  
  function ResetCommand ( identifier, node ) {
    this.key = identifier; /* data-target */
    if ($oppidum.getEditor(this.key)) { // checks editor existence
      $(node).bind('click', $.proxy(this, 'execute'));
      node.disabled = false;
    } else {
      node.disabled = true;
      $oppidum.logError('Missing or invalid data-target attribute in reset command ("' + this.key + '")');
    }
  };
  
  ResetCommand.prototype = {
    execute : function (event) {
      var editor = $oppidum.getEditor(this.key);
      if (editor) {
        editor.reset();
      }
    }
  };
  
  $oppidum.registerCommand('reset', ResetCommand);
}());

/*****************************************************************************\
|                                                                             |
|  'save' command object (XML submission with Ajax a form)                    |
|                                                                             |
|*****************************************************************************|
|                                                                             |
|  Required attributes :                                                      |
|  - data-target : id of the editor's container                               |
|                                                                             |
\*****************************************************************************/
(function () {
  function SaveCommand ( identifier, node ) {
    this.spec = $(node);
    this.key = identifier;
    if ($oppidum.getEditor(this.key)) { // checks editor's existence
      node.disabled = false;
      this.spec.bind('click', $.proxy(this, 'execute'));
    } else {
      node.disabled = true;
      $oppidum.logError('Missing editor in save command ("' + this.key + '")');
    }
  };
  
  SaveCommand.prototype = (function () {
    
    function isResponseAnOppidumError (xhr) {
      return $('error > message', xhr.responseXML).size() > 0;
    };
    
    function getOppidumErrorMsg (xhr) {
      var text = $('error > message', xhr.responseXML).text();
      return text || xhr.status;
    };
    
    // Tries to extract more info from a server error. Returns a basic error message 
    // if it fails, otherwise returns an improved message
    // Compatible with eXist 1.4.x server error format
    function getExistErrorMsg (xhr) {
      var text = xhr.responseText, status = xhr.status;
      var msg = 'Error ! Result code : ' + status;
      var details = "";
      var m = text.match('<title>(.*)</title>','m');
      if (m) {
        details = '\n' + m[1];
      }                  
      m = text.match('<h2>(.*)</h2>','m');
      if (m) {
        details = details + '\n' + m[1];
      } else if ($('div.message', xhr.responseXML).size() > 0) {
        details = details + '\n' + $('div.message', xhr.responseXML).get(0).textContent;
        if ($('div.description', xhr.responseXML).size() > 0) {
          details = details + '\n' + $('div.description', xhr.responseXML).get(0).textContent;    
        }
      }
      return msg + details;
    };

    function saveSuccessCb (response, status, xhr) {
      var loc = xhr.getResponseHeader('Location');
      if (xhr.status = 201) {
        if (loc) {
          window.location.href = loc;
        } else {
          $oppidum.logError(getOppidumErrorMsg(xhr));
        }
      } else {
        $oppidum.logError('Unexpected response from server (' + xhr.status + '). Save action may have failed');
      }
    };

    function saveErrorCb (xhr, status, e) {    
      var s;
      if (status === 'timeout') {
        $oppidum.logError("Save action taking too much time, it has been aborted, however it is possible that your page has been saved");
      } else if (xhr.status === 409) { // 409 (Conflict)
        s = xhr.getResponseHeader('Location');
        if (s) {
          window.location.href = s;
        } else {
          $oppidum.logError(getOppidumErrorMsg(xhr));
        }
      } else if (isResponseAnOppidumError(xhr)) {
        // Oppidum may generate 500 Internal error, 400, 401, 404
        $oppidum.logError(getOppidumErrorMsg(xhr));
      } else if (xhr.responseText.search('Error</title>') != -1) { // eXist-db error (empirical)
        $oppidum.logError(getExistErrorMsg(xhr));
      } else if (e) {
        $oppidum.logError('Exception : ' + e.name + ' / ' + e.message + "\n" + ' (line ' + e.lineNumber + ')');
      } else {
        $oppidum.logError('Error while connecting to "' + this.url + '" (' + xhr.status + ')');
      }
    };
    
    return {
      execute : function (event) {
        var editor = $oppidum.getEditor(this.key),
            method, dataUrl, transaction, data;
        if (editor) {
          url = editor.attr('data-src') || this.spec.attr('data-src') || '.'; // last case to create a new page in a collection
          if (url) {
            data = editor.serializeData();
            if (data) {
              method = editor.attr('data-method') || this.spec.attr('data-method') || 'post';
              transaction = editor.attr('data-transaction') || this.spec.attr('data-transaction');
              if (transaction) {
                url = url + '?transaction=' + transaction;
              }              
              $.ajax({
                url : url,
                type : method,
                data : data,
                dataType : 'xml',
                cache : false,
                timeout : 10000,
                contentType : "application/xml; charset=UTF-8",
                success : saveSuccessCb,
                error : saveErrorCb
                });
                editor.hasBeenSaved = true; // trick to cancel the "cancel" transaction handler
                // FIXME: shouldn't we disable the button while saving ? 
            } else {
              $oppidum.logError('The editor did not generate any data');
            }
          } else {
            $oppidum.logError('The command does not know where to send the data')
          }
        } else {
          $oppidum.logError('There is no editor associated with this command');
        }
      }
    };
  }());
  
  $oppidum.registerCommand('save', SaveCommand);
}());
