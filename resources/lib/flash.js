(function () {

  function init() {
    var n = document.getElementById('message'),
        b = n ? n.getElementsByTagName('span').item(0) : null, // supposes 1st is close button
        to, dur;
    if (b) {
      to = b.getAttribute('data-timeout');
      if (to) {
        dur = parseInt(to, 10);
        if (!isNaN(dur)) {
          setTimeout(document.messageOff, dur);
        }
      }
    }
  }

  function discard ( name ) {
    var n = document.getElementById(name);
    n.style.display = 'none';
  }

  document.messageOff = function () { discard('message') };
  document.errorOff = function () { discard('error') };

  window.onload = init;
}());
