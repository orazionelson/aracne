var tags;
//Call the XML file
$.ajax({
    'async': false,
    url: '../resources/scripts/cm-tei-schema.xml',
    dataType: 'xml',
    success: function(response) {
        //parse the xml schema to create a json Object according to CodeMirror style
        tags = $.cm_tei_schema2json(response);
    }
});

//HELP TRIGGER, AUTOGEN HELP FROM TEI MANUAL JSON SOURCE
var raw_tags=Object.keys(tags);
raw_tags.shift();

var jsonsource="http://www.tei-c.org/release/xml/tei/odd/p5subset.json";
var elements = $();

   
//this clones the tag object   
var ntags = JSON.parse(JSON.stringify(tags));

delete ntags['!top']; // or use => delete test['blue'];
//console.log(ntags);
//console.log(tags);   
for(x = 0; x < raw_tags.length; x++) {
    
    url_it = 'http://www.tei-c.org/release/doc/tei-p5-doc/it/html/ref-'+raw_tags[x]+'.html';
    link_it= '<a href="'+url_it+'" target="_blank">it</a>';
    
    url_en = 'http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-'+raw_tags[x]+'.html';
    link_en= '<a href="'+url_en+'" target="_blank">en</a>';
    
    $('#allowed-tags').append('<a href="#" class="link-tag">'+raw_tags[x]+'</a> - ');
    
    var tg=ntags[raw_tags[x]];
    //jsObj['key' + i]
    //console.log(tg.attrs); 
    
    var tgattrs='';
    if(tg.attrs){

        var tgattrs='<p><strong>Allowed attributes</strong></p>';
        $.each(tg.attrs, function(key, value) {
            //console.log(key, value);
            if(value==null) value='<i>freetext</i>';
            //console.log(value);
            var val='';
            if(typeof(value)==='string') {val=value;}
            else {
                val+='<ul>'
                $.each(value,function (ky,va){
                val+='<li>'+va+'</li>';
                });
                val+='</ul>';
            }
            
            tgattrs+='<span class="text-danger"><strong>'+key+'</strong></span>: '+val+'<br/>';
        });
    }

    var tgchildren='';
    if(tg.children){

        var tgchildren='<p><strong>Allowed children</strong></p>';
        tgchildren+='<ul>'
        $.each(tg.children, function(key, value) {
            //console.log(key, value);
            //if(value==null) value='freetext';
            
            tgchildren+='<li>'+value+'</li>';//key+": "
        });
        tgchildren+='</ul>';
    }
    
    var panel_heading='<div class="panel-heading"><span class="lead text-primary"><strong>'+raw_tags[x]+'</strong></span> <a href="#" data-target="'+raw_tags[x]+'-desc" class="get-desc" data-ident="'+raw_tags[x]+'">: <strong>TEI DESCRIPTION</strong></a></div>';
    var panel_body='<div class="panel-body"><div id="'+raw_tags[x]+'-desc" style="display:none" class="desc well"><p class="lead desc-content"></p>(More info: '+link_it+', '+link_en+')</div><div class="row"><div class="col-md-6">'+tgattrs+'</div><div class="col-md-6">'+tgchildren+'</div></div>';

    elements = elements.add('<div class="panel panel-default tags-panel" id="'+raw_tags[x]+'-panel" data-ident="'+raw_tags[x]+'">'+panel_heading+panel_body+'</div>');
    
    };
    // or 
    // var element = $('<div>'+x+'</div>');
    // elements = elements.add(element);
//});
$('#tei-help').append(elements);  

$('.get-desc').on('click',function(e){
    e.preventDefault();
    var desklink=$(this);
    var target = $(this).data(target);
    var ident = $(this).data(ident);
    //console.log(ident.ident);
    
    $.getJSON(jsonsource,function(result){
    
    //console.log(help);
    var data=result.members;
    $.each(data, function(i,item){
        //for(x = 0; x < raw_tags.length; x++) { 
        if(item.ident==ident.ident){
            //console.log(item.desc);
            $('#'+target.target).find('.desc-content').empty().append(item.desc);
            $('#'+target.target).show();
            //help.push(item.desc);
            }  
        //}
        
        });
    
    });
    
});

$('.open-help').on("click",function(e){
     e.preventDefault();
     $('#help_panel').toggle();
});  
   
   
$('.allowed-tags').on("click",function(e){
     e.preventDefault();
     $('#allowed-tags').toggle();
}); 

$('.tips-and-examples').on("click",function(e){
     e.preventDefault();
     $('#tips-and-examples').toggle();
});

$( document ).on( 'keydown', function ( e ) {
    if ( e.keyCode === 27 ) { // ESC
        $( "#help_panel" ).hide();
    }
});   
    
//$('.contact-name').hide();
$('#search-tag').on("keyup",function(){
    $('.tags-panel').hide();
    var txt = $('#search-tag').val();
    $('.tags-panel').each(function(){
       if($(this).data('ident').indexOf(txt) != -1){
           $(this).show();
       }
    });
});

$('.link-tag').on("click",function(e){
    e.preventDefault();
    $('.tags-panel').hide();
    var txt = $(this).text();
    $('.tags-panel').each(function(){
       if($(this).data('ident').indexOf(txt) != -1){
           $(this).show();
       }
    });
});

