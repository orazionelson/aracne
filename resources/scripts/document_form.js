$('.html').each(function() {
    $(this).summernote({
  toolbar: [
    // [groupName, [list of button]]
    ['style', ['bold', 'italic', 'underline', 'clear']],
    ['font', ['strikethrough', 'superscript', 'subscript']],
    ['fontsize', ['fontsize']],
    ['color', ['color']],
    ['para', ['ul', 'ol', 'paragraph']],
    ['height', ['height']]
    ]
    });
});


$('.datepicker').datepicker({ 
    minDate: new Date($('#mindate').data('date')+"/01/01"), 
    maxDate: new Date($('#maxdate').data('date')+"/12/31"), 
    changeMonth: true,
    changeYear: true,
    dateFormat: "yy-mm-dd"
});

    

      
        $('.document-respstmt-container').each(function(){
            //var label=$( this ).data( 'idcontainer' );
            var kw=$( this ).data( 'teinode' );
            var x=0;
            var y=0;
            //$(this).addClass('form-group');
            //$(this).children('div').addClass('multiple-input col-sm-10');
            //$(this).prepend('<label class="col-sm-2 control-label" for="'+label+'" id="'+label+'label">'+label+'</label>');
            $(this).find('.form-group select')
                .attr('name', 'resp[]') 
                .each(function(){
                    
                    x++
                    $(this).attr('id', kw+'_resp_'+x);
                    $(this).after('<a href="#" class="remove_field">Remove</a>');
                    
                });
            $(this).find('.form-group input')
                .attr('name','name[]')
                //.addClass('form-control')
                .each(function(){
                    
                    y++
                    $(this).attr('id', kw+'_name_'+y);
                    
                    
                });
           
            $('#'+kw+'_resp_1').css('margin-bottom','5px').next('a').hide();
                
            $(this).append('<button class="btn btn-primary add-resp-button" style="margin-top:5px;">Add More</button>')
        });
        
        $(".add-resp-button").click(function(e){ //on add input button click
            e.preventDefault();
            
            var x=$(this).prevAll().length;
            
            //var label=$( this ).closest('div.multiple-input-container').data( 'idcontainer' );
            var kw=$( this ).closest('div.document-respstmt-container').data( 'teinode' );
            
            var options=$(this).parent('div').find('div.form-group:first select').html();
            
            x++; //text box 
          
            var select = '<select name="resp[]" id="'+kw+'_resp_'+x+'" class="form-control">'+options+'</select>';
            var remove = '<a href="#" class="remove-resp-field">Remove</a>'
            var selcol='<div class="col-md-6">'+select+remove+'</div>';
            var input = '<input name="name[]" type="text" id="'+kw+'_name_'+x+'" class="form-control"/>';
            var inputcol='<div class="col-md-6">'+input+'</div>';
            //var inputcol=$( input ).wrap( '<div class="col-md-6"/>' );
           
            
            //console.log(selcol);
            //console.log($(this).parent('div').find('div.form-group:last').css('border', '1px solid red'));
           
            $(this).parent('div').find('div.form-group:last').after('<div class="form-group row">'+selcol+inputcol+'</div>'); //add input box
            
        });

        $('form').on("click",".remove-resp-field", function(e){ //user click on remove text
            e.preventDefault(); 
            var x=1;
            var y=1;
            var kw=$( this ).closest('div.document-respstmt-container').data( 'teinode' );
            var container = $( this ).closest('div.document-respstmt-container');
        
            $(this).closest('div.form-group').remove();
        
        $(container).find('select').each(function(){
                $(this).attr('id',kw+'_resp_'+x++)
        });
        
        $(container).find('input').each(function(){
                $(this).attr('id',kw+'_name_'+y++)
        });
    })
    
    
    $('.multiple-input-container').each(function(){
        var x=0;
        var label=$( this ).data( 'teinode' );
        $(this).find('label').attr('for',label);
        
        $(this).find('input')
                .attr('name',label+'[]')
                //.addClass('form-control')
                .each(function(){
                    
                    x++
                    $(this).attr('id', label+'_'+x);
                    //$(this).after('<a href="#" class="remove_field">Remove</a>');
                    
                });
        $(this).find("a.remove_field:first").hide();
        $(this).find("label:not(:first)").empty();
            
        }); 
        
        $(".add_field_button").click(function(e){ //on add input button click
            e.preventDefault();
             
            var x=$(this).prevAll().length;
            //alert(x);
            var label=$( this ).closest('div.multiple-input-container').data( 'teinode' );
            //var kw=$( this ).closest('div.multiple-input-container').data( 'idkw' );
            //alert(kw);
            x++; //text box increment
            var emptycol = '<label class="col-sm-2"/>';
            var input = '<input name="'+label+'[]" type="text" id="'+label+'_'+x+'" class="form-control"/>';
            var remove = '<a href="#" class="remove_field">Remove</a>'
            var formgroup=emptycol+'<div class="multiple-input col-sm-10">'+input+' '+remove+'</div>';
            $(this).parent('div').find('div.form-group:last').after('<div class="form-group">'+formgroup+'</div>'); //add input box
            
        });
        
        $('form').on("click",".remove_field", function(e){ //user click on remove text
            e.preventDefault(); 
            var x=1;
            //var y=1;
            var kw=$( this ).closest('div.multiple-input-container').data( 'teinode' );
            var container = $( this ).closest('div.multiple-input-container');
        
            $(this).closest('div.form-group').remove();
        
        
        
            $(container).find('input').each(function(){
                $(this).attr('id',kw+'_name_'+x++)
            });
        });
        
        $('.multiple-textarea-container').each(function(){
            var x=0;
            var label=$( this ).data( 'teinode' );
            $(this).find('label').attr('for',label);
             $(this).find('textarea')
                //.attr('name',label+'[]')
                //.addClass('form-control')
                .each(function(){
                    
                    x++
                    $(this).find("textarea").attr('id', label+'_'+x);
                    //$(this).after('<a href="#" class="remove_field">Remove</a>');
                    
                });
            
            $(this).find('.remove_textarea:first').hide();    
                
        });

  // add_textarea_button
        $(".add_textarea_button").click(function(e){ //on add input button click
            e.preventDefault();
             
            var x=$(this).prevAll().length;
            //alert(x);
            var label=$( this ).closest('div.multiple-textarea-container').data( 'teinode' );
            var textarea_class=$( this ).closest('div.multiple-textarea-container').data( 'class' );
            //var kw=$( this ).closest('div.multiple-input-container').data( 'idkw' );
            //alert(kw);
            x++; //text box increment
            var emptycol = '<label class="col-sm-2"/>';
            var textarea = '<textarea class="form-control '+textarea_class+'" rows="8" name="'+label+'[]" type="text"/>';
            var remove = '<a href="#" class="remove_textarea">Remove</a>'
            var formgroup=emptycol+'<div class="col-sm-10">'+textarea+' '+remove+'</div>';
            $(this).parent('div').find('div.form-group:last').after('<div class="form-group">'+formgroup+'</div>'); //add input box
            
             $(this).parent('div').find('.html:last').wysihtml5(toolbar);
             
        });
    
    //remove textarea link    
        $('form').on("click",".remove_textarea", function(e){ //user click on remove text
            e.preventDefault(); 
            var x=1;
            //var y=1;
            var kw=$( this ).closest('div.multiple-textarea-container').data( 'teinode' );
            var container = $( this ).closest('div.multiple-textarea-container');
        
            $(this).closest('div.form-group').remove();
        
        
        
            $(container).find('textarea').each(function(){
                $(this).attr('id',kw+'_note_'+x++)
            });
        });