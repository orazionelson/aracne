$(document).ready(function() {
    var mydata=$('#document-form').serialize();
        
     $.ajax({
            url: "validate-tei.html",
            method: "POST",
            data : mydata,
            //data: { id: "ara3", docid: "ara3.6.xml"} ,
                //parts: JSON.stringify(scorez) },
            cache: false
        })
        .done(function( html ) {
            $( "#validation-tei" ).append( html );
            //console.log(html)
            //console.log(html)
            //score='1';
            //scores.push(html)
        })
        .fail(function(jqXHR, textStatus, errorThrown) {
                        
            /*var nmyid = "XX"; //myid.substr(myid.lastIndexOf("_") + 1);
            var content = $(jqXHR.responseText).find("#content pre.error").html();
            var decodedContent = $('<span/>').html(content).text();
            var message = $(decodedContent).find("message").html();*/
            //var valid= message.substr(0, message.indexOf('Validated')); 
            
            //console.log(validation);
            var error = '<div data-score="1" class="text-danger">error vaidate-tei.js: '+errorThrown+'</div>';
            $( "#validation" ).append( error );
            
        });
});