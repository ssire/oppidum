/* AXEL 'width' filter
 *
 * author      : Stéphane Sire
 * contact     : s.sire@oppidoc.fr
 * license     : proprietary (this is part of the Oppidum framework)
 *
 * April 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
 */

/** Requires JQUery
  *
  */
 var _WidthFilter  = (function _WidthFilter () {    
   
   var _getTarget = function (me) {
     var rootcn = me.getParam('width_root_class');
     var targetcn = me.getParam('width_target_class');
     var root = $(me.getHandle(true)).closest('.' + rootcn);
     var res = targetcn ? root.find('.' + targetcn).first() : root;
     if (! res) {
       xtiger.cross.log('debug', "'width' filter could not find target node");
     }
     return res;
   }

  return {  

     ///////////////////////////////////////////////////
     /////     Instance Clear Mixin Part    ////////
     ///////////////////////////////////////////////////

    // Property remapping for chaining
    '->': {
      'set': '__WidthFilterSet', 
      'clear': '__WidthFilterClear'
    },   

    set : function(doPropagate) {
      var val, target = _getTarget(this); 
      if (target) {
        val = this.getData();
        xtiger.cross.log('debug', "'width' filter val " + val);
        if (/^\d+$/.test(val)) {
          val = val + 'px';
        } else {
          val="auto";
        }
        xtiger.cross.log('debug', "'width' filter val " + val);
        target.css('width', val);
      }
      this.__WidthFilterSet(doPropagate);
    },
    
    clear : function (doPropagate) {
      xtiger.cross.log('debug', "'width' filter clear");
      var target = _getTarget(this);
      if (target) {
        target.css('width', '');
      }
      this.__WidthFilterClear(doPropagate);
    }

    // unset : function (doPropagate) {
    // }
    // FIXME: there is one case where unset is called and not clear (unchek through checkbox)

   }
 })();

 // Do not forget to register your filter on any compatible primitive editor plugin
 xtiger.editor.Plugin.prototype.pluginEditors['text'].registerFilter('width', _WidthFilter);
 
 /**
   * Class _StyleFilter (mixin filter)
   *
   * Filter that works ONLY for an optional text editor (option="...") :
   * adds the 'optclass_name' class name to the parent of the handle 
   * when the handle is selected
   */
  var _StyleFilter  = (function _StyleFilter () {    

    var _getTarget = function (me) {
      var rootcn = me.getParam('style_root_class');
      var targetcn = me.getParam('style_target_class');
      var root = $(me.getHandle(true)).closest('.' + rootcn);
      var res = targetcn ? root.find('.' + targetcn).first() : root;
      if (! res) {
        xtiger.cross.log('debug', "'style' filter could not find target node");
      }
      return res;
    }

   return {  

      ///////////////////////////////////////////////////
      /////     Instance Clear Mixin Part    ////////
      ///////////////////////////////////////////////////

     // Property remapping for chaining
     '->': {
       'init' : '__StyleSuperInit',
       'set': '__StyleSuperSet', 
       'unset': '__StyleSuperUnset'
     },   

     init : function (aDefaultData, aParams, aOption, aUniqueKey, aRepeater) { 
       this.__StyleSuperInit(aDefaultData, aParams, aOption, aUniqueKey, aRepeater);
       this._CurStyleValue = aDefaultData; // works with 'select' iff aDefaultData is the target XML value (not the i18n one)
     },
    
     set : function(doPropagate) {
       var value, prop, values, target;
       this.__StyleSuperSet(doPropagate);
       values = this.getParam('values');
       target = _getTarget(this);
       if (target) {
         prop = this.getParam('style_property') || 'class';         
         if (values) { // this is a 'select' plugin
          value = this.getData();
          if (this._CurStyleValue) {
            if (prop === 'class') {
              target.removeClass(this._CurStyleValue);
            }
          }
          this._CurStyleValue = value;
         } else {
          value = this.getParam('style_value') || this.getData();
         }
        (prop === 'class') ? target.addClass(value) : target.css(prop, value);
       }
     },

     unset : function (doPropagate) {
       var value, prop, target;
       this.__StyleSuperUnset(doPropagate);
       prop = this.getParam('style_property') || 'class';
       target = _getTarget(this); 
       if (target) {
         prop = this.getParam('style_property') || 'class';         
         if (this.getParam('values')) { // this is a 'select' plugin
           value = this._CurStyleValue;
         } else {
           value = this.getParam('style_value') || this.getData();
         }
         if (value) {
           (prop === 'class') ? target.removeClass(value) : target.css(prop, '');
           // FIXME: remember original css value in set and restore it ?
         }
       }
     }

    }
  })();

  // Do not forget to register your filter on any compatible primitive editor plugin
  xtiger.editor.Plugin.prototype.pluginEditors['text'].registerFilter('style', _StyleFilter);
  xtiger.editor.Plugin.prototype.pluginEditors['select'].registerFilter('style', _StyleFilter);
