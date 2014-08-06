function saveSuccessCb (response, status, xhr) {
  $('#results').text(xhr.responseText);
}
function saveErrorCb (xhr, status, e) {
  $('#results').html('ERROR (' + xhr.status + ') : ' + xhr.responseText);
}
function run(goal) {
  var url = document.forms[0]['base-url'].value + document.forms[0].path.value,
      data = document.getElementById('data').value;
  if (goal === 'get') {
    window.open(url);
  } else {
    $.ajax({
      url : url,
      type : goal,
      data : data,
      dataType : 'xml',
      cache : false,
      timeout : 10000,
      contentType : "application/xml; charset=UTF-8",
      success : saveSuccessCb,
      error : saveErrorCb
      });
  }
}
function duplicateProject() {
  var n = document.getElementById('project'),
      m = document.getElementById('base-url');
  m.value = '/exist/projets/' + n.value + '/';
  m = document.getElementById('confbase');
  m.value = '/db/www/' + n.value;
  return false;
}
