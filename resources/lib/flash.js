(function () {

  function init() {
    var n = document.getElementById('message'),
        b = n ? n.getElementsByTagName('span').item(0) : null, // supposes 1st is close button
        set = n ? n.getElementsByTagName('p') : { length: 0 },
        timeout = -1,
        i, tmp, dur;
    // extracts optional global timeout from 1st span
    if (b) {
      tmp = b.getAttribute('data-timeout');
      if (tmp) {
        dur = parseInt(tmp, 10);
        if (!isNaN(dur)) {
          timeout = dur;
        }
      }
    }
    // extracts max of individual timeout from p
    for (i = 0; (i < set.length) && (timeout !== -1); ++i) {
      tmp = set.item(i).getAttribute('data-timeout');
      if (tmp) {
        dur = parseInt(tmp, 10);
        if (!isNaN(dur) && ((dur > timeout) || (dur === -1))) {
          timeout = dur;
        }
      }
    }
    if (timeout > 0) {
      setTimeout(document.messageOff, timeout);
    }
  }

  function discard ( name ) {
    var n = document.getElementById(name);
    n.style.display = 'none';
  }

  document.messageOff = function () { discard('message'); };
  document.errorOff = function () { discard('error'); };

  window.onload = init;
}());
