/***********************
 * Tabfy plugin
 * by Alfredo Cosco 2016
 * @orazio_nelson
 * alfredo.cosco@gmail.com
 **********************/
(function ( $ ) {
	$.fn.tabfy = function (selector){
		var nav = $(this).data('tabNav');
		if(!nav) nav='tab';

		var fade = $(this).data('tabFade');
		
		var fading='';
		if(fade==true) {fading='fade';}

		var labels = [];
		var contents = [];
		var i=0;

		$(this).wrapInner('<div class="original-text" />')
		.prepend('<ul class="nav nav-'+nav+'s" role="tablist" />')
		.find('ul.nav').after('<div class="tab-content" />');

		$(this).find(selector).each(function() {
			var label = '<li role="presentation"><a href="#'+$(this).text()+'" class="'+$(this).text()+'tab" aria-controls="'+$(this).text()+'" role="tab" data-toggle="'+nav+'">'+$(this).text()+'</a></li>';		
			var content= '<div role="tabpanel" class="tab-pane '+fading+'" id="'+$(this).text()+'">'+$(this).next().html()+'</div>';	
			labels.push(label);
			contents.push(content);
			i++
		});
		
		var tabs = labels.join('');
		var tcont = contents.join('');

		$(this).find('ul.nav').append(tabs);
		$(this).find('.tab-content').append(tcont);	
		
		$(this).find('ul.nav a:first').tab('show');

		$(this).find( ".original-text" ).remove();
	}	
}( jQuery ));


