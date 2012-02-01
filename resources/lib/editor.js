/* Copyright (c) 2011-2012 Oppidoc SARL, <contact@oppidoc.fr> 
 *
 * author      : Stéphane Sire
 * contact     : s.sire@free.fr
 * license     : proprietary (this is part of the Oppidum framework)
 * last change : 2011-10-28
 *                         
 * Script to generate an editor for editing or creating a page
 *
 * Prerequisites: jQuery + AXEL (https://github.com/ssire/axel)
 *
 * TODO:
 * - use jQuery for initial XML resource loading to trap error 401
 *
 */   

(function () { 
  
var 
  form = undefined; // AXEL form object  
  errLog = undefined; 
  saved = false;
  
function isResponseAnOppidumError (xhr) {
  return $('error > message', xhr.responseXML).size() > 0;
}  

function getOppidumErrorMsg (xhr) {
  return $('error > message', xhr.responseXML).text();
}  

// FIXME: use an hypothetical "error" div to display errors
function logError (msg) {
  alert(msg);
  // var n = spec.logId ? document.getElementById(spec.logId) : undefined;
  // if (n) {
  //   n.innerHTML = '<p class="error">' + msg + '</p>';
  //   xtdom.removeClassName(n, 'noshow');
  // } else {
  //   alert(msg);
  // }
}
        
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
}

function saveSuccessCb (response, status, xhr) {
  if (xhr.status = 201) {
    window.location.href = xhr.getResponseHeader('Location');
  } else {
    logError('Unexpected response from server (' + xhr.status + '). Save action may have failed');
  }
}

function saveErrorCb (xhr, status, e) {    
  var s;
  if (status === 'timeout') {
    logError("Save action taking too much time, it has been aborted");
  } else if ((xhr.status === 500) && isResponseAnOppidumError(xhr)) { // Internal error
    logError(getOppidumErrorMsg(xhr));
  } else if (xhr.status === 409) { // 409 (Conflict)
    s = xhr.getResponseHeader('Location');
    if (s) {
      window.location.href = s;          
    } else {
      logError(getOppidumErrorMsg(xhr));      
    }
  } else if (xhr.status === 401) { // 401 as returned by Oppidum access control
    logError(getOppidumErrorMsg(xhr));
  } else if ((xhr.status === 400) && isResponseAnOppidumError(xhr)) {
    logError(getOppidumErrorMsg(xhr));
  } else if (xhr.responseText.search('Error</title>') != -1) { // eXist-db error (empirical)
    logError(getExistErrorMsg(xhr));
  } else if (e) {
    logError('Exception : ' + e.name + ' / ' + e.message + "\n" + ' (line ' + e.lineNumber + ')');
  } else {
    logError('Error (' + xhr.status + ')');
  }
}
                 
function save (event) {
  var logger = new xtiger.util.DOMLogger();
  var url = event.data.url;
  form.serializeData(logger);
  if (event.data.transaction) {
    url = url + '?transaction=' + event.data.transaction;
  }
  $.ajax({
    url : url,
    type : 'POST', // FIXME: event.data.method
    data : logger.dump(),
    dataType : 'xml',
    cache : false,
    timeout : 5000,
    contentType : "application/xml; charset=UTF-8",
    success : saveSuccessCb,
    error : saveErrorCb
    });
    saved = true; // we could aswell unsubscribe from 'unload'
    // FIXME: include jQuery UI buttons to be able to call
    // $('#oppidum-save').button('disable');
}     

function cancel (event) {
  if (! saved) {
    $.ajax({
      url : event.data.url,
      data : { transaction : event.data.transaction},
      type : 'GET', 
      async : false,
      });
  }
}

function togglePreview (event) {
  var 
    body = $('body'),
    gotoPreview = ! body.hasClass('preview');
  
  $(event.target).text(event.data[gotoPreview ? 'edit' : 'preview']);
  body.toggleClass('preview', gotoPreview);
}      

function install () {  
  var                               
    spec = $('div[data-template]').first(),
    containerId = spec.attr('id'),
    templateSrc = spec.attr('data-template'),
    dataSrc = spec.attr('data-src'),
    cancelUrl = spec.attr('data-cancel'),
    transaction = spec.attr('data-transaction'),
    axelPath = $('script[data-bundles-path]').attr('data-bundles-path'),
    saveBtn = $('button[data-role="save"]').first(),
    errLog = new xtiger.util.Logger(),
    template, data, tmp;
    
  if (templateSrc && axelPath && containerId) {                
    // 1. load template and generate editor
    template = xtiger.debug.loadDocument(templateSrc, errLog);
    if (template) { 
      form = new xtiger.util.Form(axelPath);
      form.setTemplateSource(template);
      form.setTargetDocument(document, containerId, true); // FIXME: use spec.get(0) instead of containerId
      form.enableTabGroupNavigation();
      form.transform(errLog);
      if (dataSrc) { 
        // 2.1 editing an existing page
        data = xtiger.cross.loadDocument(dataSrc, errLog);
        if (data) {                                   
          if ($('error > message', data).size() > 0) {
            errLog.logError($('error > message', data).text());
            $('#oppidum-save').hide();
          } else {
            dataFeed = new xtiger.util.DOMDataSource(data);
            form.loadData(dataFeed, errLog);
            $('#oppidum-save').bind('click', { url : dataSrc, method : 'PUT', transaction : transaction  }, save);
          }
        }
      } else {
        // 2.2 creating a new page
        $('#oppidum-save').bind('click', { url : '.', method : 'POST', transaction : transaction }, save);
      }                        
      // 3. install Preview button
      tmp = $('#oppidum-preview');
      tmp.bind('click', 
        { preview : tmp.attr('data-preview-label') || tmp.text(), 
          edit : tmp.attr('data-edit-label') || 'Edit'},
        togglePreview);
    } else {
      $('#oppidum-save').hide();
    }
    if (cancelUrl) {
      $(window).bind('unload', { url : cancelUrl, transaction : transaction, }, cancel)
    }
  } else {
    errLog.logError('Wrong parameters for loading the editor');
  }
  if (errLog.inError()) {
    logError(errLog.printErrors());
  }
  $(document).triggerHandler('AXEL-TEMPLATE-READY');
}     
                               
// onDOMReady
jQuery(function() { install(); });

/*****************************************************************************\
|                                                                             |
|  Public API                                                                 |
|                                                                             |
|*****************************************************************************/

document.getXTigerFormForDocument = function () {
  return form;
}
    
})();