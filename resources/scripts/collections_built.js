        $(document).ready(function() {
            /*$('#collections-list').DataTable({
                columnDefs: [{ type: 'natural', targets: 0 },
                    { targets: 1, orderable: false }
                ],
                "oLanguage": {"sSearch": "Filtra per testo libero:"},
                });*/

            $('.validate_built_collection').on('click', function(e){
                e.preventDefault();
                var url=$(this).attr('href');
                $('#action-box').empty().append('<span><img style="width:30px;" src="resources/img/ringred.gif"/></span>');
                $.ajax({
                    url: url,
                    method: "GET",
                    cache: false
                })
                    .done(function( html ) {
                $('#action-box').empty().append(html);//.find('.release_button_box'));

                })
                    .fail(function(jqXHR, textStatus, errorThrown) {
                        
                
                    var content = $(jqXHR.responseText).find("#content pre.error").html();
                    var decodedContent = $('<span/>').html(content).text();
                    var message = $(decodedContent).find("message").html();
                    //console.log(validation);
                    var error = '<div data-score="1" class="text-danger">error</div>';
                    $('#action-box' ).append( error );
                });
           });
        //});
        $('.publish_built_collection').on('click', function(e){
                e.preventDefault();
                var url=$(this).attr('href');
                $('#action-box').empty().append('<span><img style="width:30px;" src="resources/img/ringred.gif"/></span>');
                $.ajax({
                    url: url,
                    method: "GET",
                    cache: false
                })
                    .done(function( html ) {
                $('#action-box').empty().append(html);//.find('.release_button_box'));

                })
                    .fail(function(jqXHR, textStatus, errorThrown) {
                        
                
                    /*var content = $(jqXHR.responseText).find("#content pre.error").html();
                    var decodedContent = $('<span/>').html(content).text();
                    var message = $(decodedContent).find("message").html();*/
                    //console.log(validation);
                    var error = '<div data-score="1" class="text-danger">error</div>';
                    $('#action-box' ).append( error );
                });
           });
        });
