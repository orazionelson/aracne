$(document).ready(function() {
    $('.editor.xml').each(function(index, myeditor) {
    //console.log($(this).attr('id'));
    //myeditor.value = vkbeautify.xml(myeditor.value);

    var editor = CodeMirror.fromTextArea(myeditor, {
        mode: 'application/xml',
          /*theme: 'eclipse',*/
        lineNumbers: true,
        lineWrapping: true,
        cursorBlinkRate: 1000,
        styleActiveLine: true,
        extraKeys: {
          "'<'": completeAfter,
          "'/'": completeIfAfterLt,
          "' '": completeIfInTag,
          "'='": completeIfInTag,
          "Ctrl-Space": "autocomplete"
        }
      });

    // on and off handler like in jQuery
    editor.on('change',function(cm){
        cm.save()
    });
    
    //Trigger with bootstrap tab change
    $('a.setup_link').on('click', function(e) {
        setTimeout(function() {
            editor.refresh();
        }, 1);

    });    
    
    editor.setSize(null, 500);
        
    });
})    