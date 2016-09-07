(function () {

  function init() {
    $('a.top').click( function(ev) { //  skip Oppidum developer tools static header
      $('html, body').animate( { scrollTop : 0 }, 800 );
      ev.preventDefault();
      }
    );
    $('a.toc').click( function(ev) { //  vertical shift of Oppidum developer tools static header height
      var l = $(ev.target).attr('data-letter');
      var sel = 'a[name="ancre_' + l + '"]';
      var target = $(sel);
      $('html, body').animate( { scrollTop : target.offset().top - 50 }, 800 );
      ev.preventDefault();
      }
    );
    $('#ide-explorer a.path').click(
      function(ev) { 
        var t, s, _count = 1; 
        s = $(ev.target).attr('href-cache') || $(ev.target).attr('href'); 
        if (s.indexOf('*') != '-1') { 
          $(ev.target).attr('href-cache',s);
          $(ev.target).attr('href', 
            s.replace(
              /\*/g, 
              function() { return prompt('step ' + _count++); }
            ) 
          );
        } 
      }
    );
  }

  jQuery(function() { init(); });
}());
