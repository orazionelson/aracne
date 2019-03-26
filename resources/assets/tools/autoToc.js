/***********************
 * Tocfy plugin
 * by Alfredo Cosco 2016
 * @orazio_nelson
 * alfredo.cosco@gmail.com
 **********************/
(function ( $ ) {
	$.fn.autoToc = function (){
	    var section = $('body').find("#main-section");
	    var par = $('body').find("#main-section h3.paragtitle");
	    var side = "right";
	    var position = "sticky";
	    var col1 = '9'; 
	    var col2 = '3';
	/*	var s = $(this).data('tocSide');
	    if(!s) s='';*/
	
        var pull='';
	    if(side=='right'){pull='pull-right';}
	   
	    $(par).each(function(index,value){
	        $(this).attr('id','paragtitle_'+index)
	    });
	   
	    var fixed='';
	    if(position=='fixed') fixed=' data-spy = "affix"';
	   
	    $(section).wrapInner( '<div class="row cntRow"></div>' );
	    
	    $(section).find(".cntRow").wrapInner('<div class="col-md-'+col1+'" role="main" />');
	    $(section).find(".cntRow").prepend('<div id="toc" class="toc list-group"'+fixed+' />')

        $('.toc').wrap('<div class="col-md-'+col2+' '+pull+'" role="complementary" />');
	
		//var selector = '.toc-item';
	var all = $(par);
	var nodes = []; 
	for(var i = all.length; i--; nodes.unshift(all[i]));
	var result = document.createElement("ul");
	buildRec(nodes, result, 3);
	$(result).addClass('tocnav');
	$(".toc").append(result);
	
	   /* if(s=='top') {var col1='12'; var col2='12';}
	    else  {var col1='9'; var col2='3';}

	
	var p = $(this).data('tocPosition');
	var fixed='';
	if(p=='fixed') fixed=' data-spy = "affix"';
	
	//console.log(a);
	$(this).wrap( '<div class="row"></div>' )
	.before('<nav class="toc list-group hidden-print hidden-xs hidden-sm"'+fixed+' />')
	.wrap('<div class="col-md-'+col1+'" role="main" />');
	
	$('.toc').wrap('<div class="col-md-'+col2+' '+pull+'" role="complementary" />');
	//$(this).find(':header' ).clone().appendTo('.toc');
	var i=1;
	
	$(this).find(':header' ).each(function() {
		var id = $(this).closest( ".tocfy" ).attr('id');
		$(this).attr('id', id+i++);
		$(this).addClass('toc-item');
		});//.clone().appendTo('.toc');
	var selector = '.toc-item';
	var all = $(selector);
	var nodes = []; 
	for(var i = all.length; i--; nodes.unshift(all[i]));
	var result = document.createElement("ul");
	buildRec(nodes, result, 2);
	$(result).addClass('nav scrollnav nav-stacked');
	$(".toc").append(result);*/
	};
	
	/**
	 * Build Toc
	 * buildRec() http://jsfiddle.net/fA4EW/
	 * **/
	function buildRec(nodes, elm, lv) {
	    var node;
	    // filter
	    do {
	        node = nodes.shift();
	    } while(node && !(/^h[123456]$/i.test(node.tagName)));
	    // process the next node
	    
	    if(node) {
	        var ul, li, cnt;
	        var curLv = parseInt(node.tagName.substring(1));
	        
		        if(curLv == lv) { // same level append an il
		            cnt = 0;
		        } else if(curLv < lv) { // walk up then append il
		            cnt = 0;
		            do {
						//console.log(elm);
		                elm = elm.parentNode.parentNode;
		                cnt--;
		            } while(cnt > (curLv - lv));
		        } else if(curLv > lv) { // create children then append il
		            cnt = 0;
		            do {
		                li = elm.lastChild;
		                if(li == null)
		                    li = elm.appendChild(document.createElement("li"));
		                elm = li.appendChild(document.createElement("ul"));
		                cnt++;
		            } while(cnt < (curLv - lv));
		        }
		        li = elm.appendChild(document.createElement("li"));
		        
		        // replace the next line with archor tags or whatever you want
		        li.innerHTML = '<a href="#'+node.id+'" role="menuitem">'+node.innerHTML+'</a>';
		        // recursive call
		        buildRec(nodes, elm, lv + cnt);
	    }
	}	
}( jQuery ));

$(document).ready(function() {
    $('body').autoToc();
    $("#toc").sticky({topSpacing:70});
});