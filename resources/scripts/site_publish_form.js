$(document).ready(function() {
        
        //1) Tabfy the two blocks: Structure and Contents
        // Alert: doesn't work well, it acts on unneeded parts of code 
        $('#site_form_structure_box .tabfy').tabfy('h3');
        //$('#site_form_content_box .tabfy').tabfy('h3');
        
        //Initial settings written in #settings
        var default_lang=$('#settings').data('default_lang');
        var ver_default_lang=$('#settings').data('ver_default_lang');
        if(!ver_default_lang){
            $(".step_one.site_contents").hide();
            }
        else{
            //console.log('default lang is setted')
            }

        var languages=$('#settings').data('languages').split(" ");
        var pages_setted=$('#settings').data('pages').split(" ");
        
        var title=$('#settings').data('title');
        var collectionid=$('#settings').data('id');


        //Import as xml menu structure and options from #menu_prototype
        var menu_pr=$('#menu_prototype').html();
        var xmlDoc = $.parseXML( menu_pr );
        var xml = $( xmlDoc );
        //var interfaces = xml.find( "interface" );
        //var templates = xml.find( "template" );
        var names = xml.find( "name" );
        
        $("body").on('focus',".defaultLang input", function(){
            $(this).closest(".multilangInput").find(".otherLangs .input-group").toggle();
        });

        //METADATA TAB
        //Set default position for metadata tab
        //tab_default('Metadata',default_lang);
        
        //PAGES TAB
        //Set default position for the pages tab
        //pages_tab_default(default_lang);
        
        //Check on the options menu the setted pages
        //If the menu voice is setted then clone to #menu_built list and hide from #menu_options 
        /*("#menu_options li").each(function(){
            var name= $(this).data('name');
            //console.log(name)
            if(pages_setted.indexOf(name)!= -1){
                $(this).hide();
            }
   
        });
        
        $('#menu_built li').find('.pages_checkbox').attr('checked','checked');
        
        make_browse_items_readonly(default_lang)
        
        
        //Make the two lists connected and sortable    
        $( "#menu_options,#menu_built" ).sortable({ 
            connectWith: ".connectedSortable"
        }).disableSelection();
        
        $( "#menu_options" ).sortable({
            cancel: ".list-group-item"
        });
        
        //When page loads push the tite at the top of every content box
        $('.edit-area .form-group').each(function(){edit_box_title(this)}); 

        //When page loads set summernote for page content textareas
        load_summernote('body','textarea.content-textarea.saved');

        //When page loads set tablesctipt for tables
        tables_script('body','textarea.table-textarea.saved');

        //Manage up down arrows for page parts
         up_down_manage();
        
        
        //FOOTER TAB
        //Set default position for Footer tab
        tab_default('Footer',default_lang); 
        
        //When page loads set data-lang as default_lang in footer add button
        $('#footer_add_column').data('lang', default_lang).attr('data-lang',default_lang);
        
        

        //Load a lite verion of summernote for the footer
        load_summernote_light('body','.footer_textarea.saved'); 
         
        */ 
         
        //ACTIONS
        //Structure/Contents editor toggle
        $("body").on('click','.step_one',function(e){
            e.preventDefault();
            $('.site_form_box').toggle();
            $('.step_one').removeAttr('disabled');
            $(this).attr('disabled','disabled')  
        });
        
        $("body").one('click',".site_contents", function(){
            var id=$('#settings').data('id');
            $("#site_form_content_box").load('site_publish_form_content.html?id='+id);    
            
        });
        
        
        
        //Create a page (#menu_options buttons) events
        $( 'body').on('click',"#menu_options li",function(){
            var name=$(this).data('name');
            //var label=$(this).data('label');
            var type=$(this).data('type');
            
            $(this).clone().appendTo( "#menu_built" );
            if($(this).hasClass("unique")){
                $(this).hide();
            }
            
            $('#menu_built li[data-name='+name+']').find('.pages_checkbox').attr('checked','checked');//append(checkbox);
            
            var tools=[];
            names.each(function(){
                if($(this).text()==name){
                    $(this).parent().find('tool').each(function(){
                        tools.push($(this).text());
                    });
                }
            });
            
            var proto=[];
            names.each(function(){
                if($(this).text()==name){
                    $(this).parent().find('proto').each(function(){
                        proto.push($(this).text());
                    });
                }
            });

            var score=0;
            $('body').find('.page-form').each(function(){
                if($(this).hasClass(name)) {score=score+1}
            });
             
            if(score===0){
                //$.each(languages, function( index, value ) {
                    var pagetoolbox='';
                    if(type==="template"){
                        for (i = 0; i < tools.length; i++) { 
                        pagetoolbox+='<label>'+tools[i]+'<input type="checkbox" value="'+tools[i]+'" name="page_'+name+'_tools[]"/></label>';
                        }
                      
                    }

                    //TEMPLATE BUTTONS
                    var btnproto='';
                    for (i = 0; i < proto.length; i++) { 
                        btnproto+='<button class="btn btn-default page_template" data-container="page_'+name+'_content_block" data-proto="'+proto[i]+'">'+proto[i]+'</button>';
                        
                    }
                
                    $('body').find('#Pages').append('<div class="form-group page-form '+name+'" style="display:none" />');
                    $('body').find('.page-form.'+name)
                        //.append('<p class="breadcrumb">'+collectionid+'/page/'+value+'/'+name+'</p>')
                        //.append('<div/>')
                        .append('<div class="form-group multilangInput '+name+'label"/>')
                        .append('<div class="form-group multilangInput '+name+'pagetitle"/>')
                        //.append('<div/>')
                        .append('<div class="page_tools panel panel-default">Tools:</div>')
                        .append('<div class="aracne_help"></div>')
                        .append('<div class="edit-area-block"/>');
                    
                    $('body').find('.page-form.'+name+' .edit-area-block')
                    .append('<div class="template-buttons"><div class="btn-group /></div>')
                    .append('<div class="edit-area" />');
                        
                        ;
                    
                    /*Set label/menu item*/
                    /*
                    $('body').find('.multilangInput.'+name+'label')
                    .append('<label class="control-label">Menu Item</label>')
                    .append('<div class="input-group defaultLang"><div class="input-group-addon"><img class="defaultLangImg" src="../resources/img/lang/it.png"/></div><input type="text" class="form-control" name="page_'+name+'_label_'+default_lang+'" value=""/></div>')
                    .append('<div class="otherLangs"/>')*/
                    
                    var target='.multilangInput.'+name+'label';
                    make_default_lang_input(default_lang,target,name,'label', 'Menu Item');
                    append_other_languages(languages,default_lang,target,name,'label');
                    
                    
                    target='.multilangInput.'+name+'pagetitle'
                    make_default_lang_input(default_lang,target,name,'pagetitle', 'Page title');
                    append_other_languages(languages,default_lang,target,name,'pagetitle')
                    
                    
                    $('body').find('.page-form.'+name+' .template-buttons')
                        .append(btnproto)
                        ;
                   
                    if(tools.length===0){
                         $('body').find('.page-form.'+name+' .page_tools').hide()
                    }
                    else{
                    $('body').find('.page-form.'+name+' .page_tools')
                        .append(pagetoolbox)
                        ;
                    }
                //});//end ao .each
            }//end of if:score    
        });

        $("body").on('click','.menu_item, .action',function(e){
            e.preventDefault();
        });
        
        $("body").on('click','.aracne_help button',function(e){
            e.preventDefault();
        });
        
        
        //Remove a page
        $("body").on('click','.remove',function(e){
            e.preventDefault();
            //console.log(default_lang);
            if($(this).closest('li').hasClass("unique")){
                var name=$(this).closest('li').data('name');
                $('#menu_options li[data-name='+name+']').show();
            }
            $(this).closest('li').remove();
            pages_tab_default(default_lang)
        });
        
        
        //Select a page, the view sets to <page> at default_language
        $("body").on('click','#menu_built .menu_item',function(e){
            e.preventDefault();
            $('.page-form').fadeOut();
            $('.menu_item').removeClass('active');
            $(this).addClass('active');
            var name=$(this).data('name');//alert();
            /*$('body').find('#Pages .language_nav a')
                .removeClass('active')
                .blur()
                .data('target', name)
                .attr('data-target',name);*/
            //$('body').find('#Pages .language_nav a.'+default_lang).addClass('active');
            $('body').find(".page-form."+name).show();
            
        });
        
        
        //Get page parts according to template instructions
        $("body").on('click','.template-buttons .btn', function(e){
            e.preventDefault();
            //alert('ciao');
            var default_lang=$('#settings').data('default_lang');
            var container=$(this).data('container');
            //var lang=$(this).data('lang');
            var proto=$(this).data('proto');
            var editarea=$(this).closest(".template-buttons").next('.edit-area');
            
            var edit_bar=$('#edit-bar-prototype div').clone();
            
            var html=$('#prototypes .proto.'+proto).clone().removeClass('proto').find('.block').unwrap();
            
            $(html).each(function(){
                $(this).prepend(edit_bar);
                var r=Math.random();
                var rnd=Math.floor((r * 90000) + 10000);
                
               console.log(this);
            if($(this).hasClass("multiLang")){
                //console.log('pippo');
                /*var dlImgPath=$(this).find('.defaultLangImg').attr('src');
                dlImgPath=dlImgPath.replace("default_lang", default_lang);
                $(this).find('.defaultLangImg').attr('src', dlImgPath);*/
                
                add_default_lang_img(this, default_lang)
               
                //var rename=$(this).find('.defaultLang').attr('name');
                //$(this).find('.defaultLang input,.defaultLang textarea').attr('name', rename+'_'+default_lang);       
                //$(this).find('.defaultLang input,.defaultLang textarea').attr('id', rename+'_'+default_lang); 
               
                var fieldname=$(this).find('.defaultLang input').attr('name')
                $(this).find('.defaultLang input, textarea.defaultLang').attr('name', container+'_'+proto+'_'+default_lang+'_'+rnd);
                $(this).find('div.defaultLangContent').attr('id', container+'_'+proto+'_'+default_lang+'_'+rnd);
               
                $(this).find('.nav .defaultLangPill a').attr('href','#'+container+'_'+proto+'_'+default_lang+'_'+rnd)
               
                var pills=$(this).find('.nav.nav-pills');
               
                var textareaTabs=$(this).find('.multilangTextarea .tab-content');
               
                var tableTabs=$(this).find('.multilangTable .tab-content');
                
                var tableProto=$(this).find('.multilangTable .table-textarea').text();
                
                //console.log(tableProto);
                
                //append_other_languages(languages,default_lang,this,container,proto)
                
                var otherLangs=$(this).find('.otherLangs');
               
               $.each(languages, function( index, lang ) {
                    if(lang!=default_lang){    
                    var l='<div class="input-group" style="display:none"><div class="input-group-addon"><img src="../resources/assets/lang/'+lang+'.png" /></div><input class="form-control" name="'+container+'_'+proto+'_'+lang+'_'+rnd+'" value="Paragraph title: '+proto+'_'+lang+'"/></div>';   
                    
                    $(otherLangs).append(l);
                        
                    var p='<li><a data-toggle="pill" href="#'+container+'_'+proto+'_'+lang+'_'+rnd+'"><img src="../resources/assets/lang/'+lang+'.png"></a></li>';
                    
                    var t='<div id="'+container+'_'+proto+'_'+lang+'_'+rnd+'" class="tab-pane fade"><textarea class="content-textarea form-control nest" rows="8" name="'+container+'_'+proto+'_'+lang+'_'+rnd+'">Paragraph Content '+lang+'</textarea></div>';
                    
                    var tt='<div id="'+container+'_'+proto+'_'+lang+'_'+rnd+'" class="tab-pane fade"><textarea class="table-textarea form-control nest hidden" rows="8" name="'+container+'_'+proto+'_'+lang+'_'+rnd+'">'+tableProto+'</textarea></div>';
                    
                    $(textareaTabs).append(t);
                    $(tableTabs).append(tt);
                    $(pills).append(p);
                    
                    }
                });
            }
            else if($(this).hasClass("singleLang")) {
                
                $(this).find('input').each(function(){
                    var cname=$(this).attr('name');
                    $(this).attr('name',container+'_'+cname+'_'+rnd);
                });
                //var fieldname=$(this).find('input').attr('value');
                //$(this).find('input').attr('id',container+'_'+slname.slice(0,-2)+'_'+fieldname+'_'+rnd);
                
                //$(this).find('.defaultLang input, textarea.defaultLang').attr('name', container+'_'+proto+'_'+default_lang+'_'+rnd);
                //$(this).find('.defaultLang input, div.defaultLangContent').attr('id', container+'_'+proto+'_'+default_lang+'_'+rnd)
                
            }
            else if($(this).hasClass("mixedLangs")) {
            
                //add_default_lang_img(this,default_lang);
                
                make_multilang_input(this,languages,default_lang,container,proto,rnd)
                $(this).find('.cluster input').each(function(){
                var name=$(this).attr('name');
                $(this).attr('name',container+'_'+proto+'_'+name+'_'+rnd);
                    
                });
                
            }

               /* var name=$(this).find('.defaultLang input').attr('name');
               
                
               if(name.slice(-2)!='[]'){
                    var id=$(this).find('input, textarea').attr('id');
                    $(this).find('input, textarea').attr('id',container+'_'+name+'_'+rnd);
                    $(this).find('input, textarea').attr('name',container+'_'+name+'_'+rnd);
                    
                }
                else{
                    //$(this).attr('id',container+'_'+id+'_'+rnd);
                    $(this).find('input, textarea').attr('id',container+'_'+name.slice(0,-2)+'_'+rnd);
                    $(this).find('input, textarea').attr('name',container+'_'+name.slice(0,-2)+'_'+rnd+'[]');
                    //name="page_{$lang}_{$template}_content_citation_{$rand}[]"
                }*/
                
                /*$(this).find('input.item-browse').addClass(lang).each(function(){
                    var element = $(this).data('element')
                    if(element!="label" && lang!=default_lang){
                        $(this).attr('readonly','readonly');
                    };
                    });
                    
                $(this).find('input.item-citation').addClass(lang).each(function(){
                    if(lang!=default_lang){
                        $(this).attr('readonly','readonly');
                    };
                    }); */   
                
                
                //$(this).find('.editarea-box-title').append('block -js- '+rnd);
                //if($(this).find('input, textarea').hasClass('nest')){
                
                //var pt=$(this).find('.editarea-box-title').text();
                //console.log(pt)
                $(this).find('.editbar-box-title').append('block -js- '+rnd);//.append(pt); 
                    
                //}
                
            });
            
            //console.log($(html).html());
            //load summernote if page part is pagetextarea
            if(proto==='textarea'){
                load_summernote(html,'textarea.content-textarea')
                //$(html).find('textarea.content-textarea').summernote();
            }
            
            $(editarea).append($(html)); 
            
            //load tables script id page part is a table
            if(proto==='table'){
                tables_script(html,'textarea.table-textarea');
            }
            
            up_down_manage();
            
        });
        

        //Footer Buttons
        //Add column
        $("body").on('click','#footer_add_column', function(e){
            e.preventDefault();
            var lang = $(this).data('lang');
            var colNum=$('body').find('.footer-edit-area.'+lang+' .row').children().length;
            //console.log(colNum);
            
            if(colNum+1>=4){
                $(this).attr('disabled','diabled')
            }
            
            var bsColNum=12/(colNum+1);
            var edit_bar=$('#footer-edit-bar-prototype').clone().html();
            //console.log(edit_bar);
            //$(html).prepend(edit_bar);
            
            $('body')
                .find('.footer-edit-area.'+lang+' .row')
                //.append('<div class="row"/>')
                    //.find('.row')
                    .append('<div class="footer-col form-group col-md-'+bsColNum+'">'+edit_bar+'<textarea name="footer_'+lang+'[]" class="form-control footer_textarea"/></div>')
                    //.find('.footer-col');//.prepend(edit_bar)
                    ;
            $('body')
                .find('.footer-edit-area.'+lang+' .footer-col')
                .attr('class', function(i, c){return c.replace(/(^|\s)col-md-\S+/g, ' col-md-'+bsColNum);});
            
            load_summernote_light('body','.footer_textarea');    
        });
        
        //Footer remove a column
        $('body').on("click",".remove_footer_field", function(e){ //user click on remove text
            e.preventDefault(); 
             
             var colNum=$('body').find(this).closest('.footer-edit-area .row').children().length;
            //console.log(colNum);
            if(colNum-1<4){
                $('#footer_add_column').removeAttr('disabled')
            }
            
             var bsColNum=12/(colNum-1);
            $('body').find(this).closest('.footer-edit-area')
                .find('.footer-col')
                .attr('class', function(i, c){return c.replace(/(^|\s)col-md-\S+/g, ' col-md-'+bsColNum);});    
                
            
            $(this).closest('div.form-group').remove();    

        });
        
        
        //Remove a part of page
        $('body').on("click",".remove_field", function(e){ //user click on remove text
            e.preventDefault(); 
            $(this).closest('.block').remove();
            up_down_manage();
        });
        

        
        //Push up a part of page
        $('body').on("click","li.up a", function(e){ 
            e.preventDefault(); 
            
            var current = $(this).closest('.block');
            var clone = current.clone();
            current.fadeOut('slow');
            clone.hide().insertBefore(current.prev()).fadeIn('slow');
            current.remove();
            up_down_manage();
        });
        
        //Pushdown
        $('body').on("click","li.down a", function(e){ 
            e.preventDefault(); 
            var current = $(this).closest('.block');
            var clone = current.clone();
            current.fadeOut('slow');
            clone.hide().insertAfter(current.next()).fadeIn('slow');
            current.remove();
            up_down_manage();
        });
        

 
        
        //Language Navigator
        // In Metadata Tab
        $('body').on('click','#Metadata .language_nav .btn', function(e){
            e.preventDefault();
            $('#metadata-box .metadata-lang-box').hide();
            $('#Metadata .language_nav .btn').blur().removeClass('active');
            $(this).addClass('active');
            var target=$(this).attr('href');
            $('body').find(target).fadeIn();
        });
        
        
        
        //In #Pages tab
        /*$('body').on('click','#Pages .language_nav .btn', function(e){
            e.preventDefault();
            $('#Pages .language_nav .btn').removeClass('active');
            
            $(this).addClass('active');
            //console.log($('body').find($(this)).data('target'));
            //console.log($(this).data('lang'));
             
            var target = $('body').find($(this)).data('target');
            var lang = $(this).data('lang');
            //console.log(target);
            $('.page-form').fadeOut();
            $('body').find('.'+target+'.'+lang).fadeIn();
            
        });
        */
        
        //In Footer Tab 
        $('body').on('click','#Footer .language_nav .btn', function(e){
            e.preventDefault();
            $('#footer-box .footer-lang-box').hide();
            $('#Footer .language_nav .btn').blur().removeClass('active');
            $(this).addClass('active');
            
            $('#footer_add_column').hide().data('lang', $(this).data('lang')).attr('data-lang',$(this).data('lang')).show();
            
            var target=$(this).attr('href');
            $('body').find(target).fadeIn();
        });
        
        $('body').on('keyup change paste', '#site_form_structure_box', function(){
            //console.log('Form changed!');
            $('body').find('.step_one').attr("disabled","disabled");
        });
    
    });
    
    function add_default_lang_img(selector, default_lang){
    var dlImgPath=$(selector).find('.defaultLangImg').attr('src');
    dlImgPath=dlImgPath.replace("default_lang", default_lang);
    $(selector).find('.defaultLangImg').attr('src', dlImgPath);
    }
    
    function make_multilang_input(selector, languages, default_lang,container,proto,rnd){
        
        add_default_lang_img(selector, default_lang)
        
        var field=$(selector).find('.defaultLang input').attr('name')
        
        $(selector).find('.defaultLang input').attr('name', container+'_'+proto+'_'+field+'_'+default_lang+'_'+rnd);
        //$(selector).find('.defaultLang input').attr('id', container+'_'+proto+'_'+default_lang+'_'+rnd);
        
        var otherLangs=$(selector).find('.otherLangs');
        $.each(languages, function( index, lang ) {
            if(lang!=default_lang){    
            var input='<div class="input-group" style="display:none"><div class="input-group-addon"><img src="../resources/assets/lang/'+lang+'.png" /></div><input  type="text" class="form-control" name="'+container+'_'+proto+'_'+lang+'_'+rnd+'" value=""/></div>';   
            $(otherLangs).append(input);
            }
        });
    }
    
    function make_default_lang_input(default_lang,target,path, field, label){
        $('body').find(target)
            .append('<label class="control-label">'+label+'</label>')
            .append('<div class="input-group defaultLang"><div class="input-group-addon"><img class="defaultLangImg" src="../resources/assets/lang/'+default_lang+'.png"/></div><input type="text" class="form-control" name="page_'+path+'_'+field+'_'+default_lang+'" value=""/></div>')
            .append('<div class="otherLangs"/>')
        
    }
    
    function append_other_languages(languages,default_lang,target,path,field){
        $.each(languages, function( index, lang ) {
            if(lang!=default_lang)    
            $('body').find(target).find('.otherLangs')
                .append('<div class="input-group" style="display:none"><div class="input-group-addon"><img src="../resources/assets/lang/'+lang+'.png"></div><input class="form-control" name="page_'+path+'_'+field+'_'+lang+'" value=""/></div>');
        });
    }
    
    function edit_box_title(sel){
        var pt=$(sel).find('.editarea-box-title').text();
                //console.log(pt)
        $(sel).find('.editbar-box-title').append(pt);  
    }
    
    function tab_default(sel, lang){
        $('body').find('#'+sel+' .language_nav .btn.'+lang).addClass('active');
        $('body').find('#'+sel.toLowerCase()+'_'+lang).show();
        
    }
    
    function pages_tab_default(lang){
        $(".page-form").hide();
        $(".page-form.homePage").show();
        $('#menu_built li[data-name=homePage]').find('.menu_item').addClass('active'); 
        $('#Pages .language_nav .btn').removeClass('active').blur();
        $('#Pages .language_nav .btn.'+lang).addClass('active');
    }
    

    
    function up_down_manage(){
        $('.edit-area').each(function(){
            $(this).find('.up').show();
            $(this).find('.up:first').hide();
            $(this).find('.down').show();
            $(this).find('.down:last').hide();
        });
    }
    
    /*function make_browse_items_readonly(default_lang){
        $("body").find(".edit-area.interface input.item-browse").not("."+default_lang).each(function(){
            var element = $(this).data('element')
            if(element!="label"){
                $(this).attr('readonly','readonly');
            }
        });
        
    }*/
    
    /*function make_citation_items_readonly(default_lang){
        $("body").find(".edit-area.template input.item-citation").not("."+default_lang).each(function(){
           
                $(this).attr('readonly','readonly');
                $(this).closest(".citation").find(".up,.down").css('visibility','hidden');//.hide()
            
        });
        
    }*/
    
    function load_summernote(sel,find){
        $(sel).find(find)
            //.each(function(){$(this)
                .summernote({
                    minHeight: "300px",
                    followingToolbar: false,
                    tooltip: false,
                    callbacks: {
                        onImageUpload: function(files, editor) {
                            editor = $(this);
                            sendFile(files[0],editor);
                        }
                    }
                });
            //});    
        }
    
    function load_summernote_light(sel,find){
        $(sel).find(find).each(function(){
            $(this).summernote({
                //airMode: true
                height: "250px",
                followingToolbar: false,
                tooltip: false,
                toolbar: [
                    ['style', ['bold', 'italic', 'underline', 'clear']],
                    ['para', ['ul', 'ol', 'paragraph']],
                ]
            });
        });
    }    
    
    function tables_script(sel,find){
        
        $(sel).find(find).each(function(){
            
        var pid=$(this).parent().attr('id');    
            
           $(this).tableEdit({
            compileTableAfter: function() {
                $(this.table).addClass('table table-striped table-hover table-bordered');
                return true;
                },
            cellEditingStopAfter: function(params) {
                var val=this.dataTableObject.tbodyArray;
                $('body').find('#'+pid+' textarea').empty().append( JSON.stringify(val) )
                return true;
                }
            }); 
        }); 
    }
    
    function sendFile(file,editor) {
        var time=$.now();
        var id=$('body #settings').data('id')
        data = new FormData();
        
        data.append("id", id);
        data.append("file", file);
        data.append("time",time);

        $.ajax({
            data: data,
            type: "POST",
            url: "site_publish_form_add_image.xql",
            cache: false,
            contentType: false,
            processData: false,
            })
            .done(function(data) {
                //console.log(data);
                var media="../resources/images/";
                var newfname=id+"_"+time+"_"+file.name;
                editor.summernote('insertImage', media+newfname, '');
            });
    }