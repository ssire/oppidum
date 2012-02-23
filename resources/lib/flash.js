(function () { 
  
  function discard ( name ) {
    var n = document.getElementById(name);
    n.style.display = 'none';
  }
    
  document.messageOff = function () { discard('message') };
  document.errorOff = function () { discard('error') };
  
})();
