/*
* Codemirror integration with TEI P5 
* tags implemented in eEdizioni delle fonti Aragonesi
* The script reads an XML File and creates a Schema for tag 
* rules in CodeMirror.
*
*/
/**
 * jQuery plugin to convert a given $.ajax response xml object to json.
 *
 * @example var json = $.xml2json(response);
 * 
 * source: GitHub: https://github.com/sparkbuzz/jquery-xml2json
 * 
 * modified for this script from Alfredo Cosco
 */
(function() {

	// default options based on https://github.com/Leonidas-from-XIV/node-xml2js
	var defaultOptions = {
		//attrkey: '$',
		url: '../resources/scripts/cm-tei-schema.xml',
		charkey: '_',
		normalize: false,
		explicitArray: false
	};

	// extracted from jquery
	function parseXML(data) {
		var xml, tmp;
		if (!data || typeof data !== "string") {
			return null;
		}
		try {
			if (window.DOMParser) { // Standard
				tmp = new DOMParser();
				xml = tmp.parseFromString(data, "text/xml");
			} else { // IE
				xml = new ActiveXObject("Microsoft.XMLDOM");
				xml.async = "false";
				xml.loadXML(data);
			}
		} catch (e) {
			xml = undefined;
		}
		if (!xml || !xml.documentElement || xml.getElementsByTagName("parsererror").length) {
			throw new Error("Invalid XML: " + data);
		}
		return xml;
	}

	function normalize(value, options){
		if (!!options.normalize){
			return (value || '').trim();
		}
		return value;
	}

	function cm_tei_schema2jsonImpl(xml, options) {
        
		var i, result = {}, attrs = {}, node, child, name;
		//result[options.attrkey] = attrs;

		if (xml.attributes && xml.attributes.length > 0) {
			for (i = 0; i < xml.attributes.length; i++){
				var item = xml.attributes.item(i);
				attrs[item.nodeName] = item.value;
			}
		}

		// element content
		if (xml.childElementCount === 0) {
		    
			result[options.charkey] = normalize(xml.textContent, options);
		}
        
        //console.log(xml.childNodes); 
        
		for (i = 0; i < xml.childNodes.length; i++) {
			node = xml.childNodes[i];
			if (node.nodeType === 1) {
			    
                    //console.log(node.length);
				if (node.attributes.length === 0 && node.childElementCount === 0){
					child = normalize(node.textContent, options);
				} else {
					child = cm_tei_schema2jsonImpl(node, options);
				}
                
				name = node.nodeName;
				if (result.hasOwnProperty(name)) {
				    
					// For repeating elements, cast/promote the node to array
					var val = result[name];
					if (!Array.isArray(val)) {
						val = [val];
						result[name] = val;
					}
					val.push(child);
					
				} else if(options.explicitArray === true) {
				    
					result[name] = [child];
				} else {
				    //
				    if(child.children){
				        if (typeof(child.children) === 'string' || child.children instanceof String)
                            {
                                //console.log(node.nodeName+"--"+child.children);
                                child={children:[child.children]};
                            }

				        }  

				    if(node.nodeName=='children' && child.length==0){child={children:[""]};}
					result[name] = child;
				}
				
			}
		}
        
		return result;
	}

	/**w
	 * Converts an xml document or string to a JSON object.
	 *
	 * @param xml
	 */
	function cm_tei_schema2json(xml, options) {
		var n;

		if (!xml) {
			return xml;
		}

		options = options || {};

		for(n in defaultOptions) {
			if(defaultOptions.hasOwnProperty(n) && options[n] === undefined) {
				options[n] = defaultOptions[n];
			}
		}

		if (typeof xml === 'string') {
			xml = parseXML(xml).documentElement;
		}

		var root = {};
		
		if (xml.attributes && xml.attributes.length === 0 && xml.childElementCount === 0){
		  root[xml.nodeName] = normalize(xml.textContent, options);
		} else {
		    
		  root[xml.nodeName] = cm_tei_schema2jsonImpl(xml, options);
		  
		}
		

        root=root['#document']['cm_tei_schema'];
                
        var topValue=root['top'];
        delete root['top'];
        root=Object.assign({ "!top": [topValue] },root);


		return root;
	}
	
	function cm_tei_schema(){
	    var tags;
        //Call the XML file
        $.ajax({
            'async': false,
            url: defaultOptions.url,
            dataType: 'xml',
                success: function(response) {
                //parse the xml schema to create a json Object according to CodeMirror style
                tags = $.cm_tei_schema2json(response);
            }
        });
	    return tags;
	    
	}

	if (typeof jQuery !== 'undefined') {
		jQuery.extend({cm_tei_schema2json: cm_tei_schema2json});
		jQuery.extend({cm_tei_schema: cm_tei_schema});
	} else if (typeof module !== 'undefined') {
		module.exports = cm_tei_schema2json;
		module.exports = cm_tei_schema;
	} else if (typeof window !== 'undefined') {
		window.cm_tei_schema2json = cm_tei_schema2json;
		window.cm_tei_schema = cm_tei_schema;
	}
})();


//FUNCTIONS FOR CODEMIRROR XML - DO NOT TOUCH 
    function completeAfter(cm, pred) {
        var cur = cm.getCursor();
        if (!pred || pred()) setTimeout(function() {
          if (!cm.state.completionActive)
            cm.showHint({completeSingle: false});
        }, 100);
        return CodeMirror.Pass;
    }

    function completeIfAfterLt(cm) {
        return completeAfter(cm, function() {
          var cur = cm.getCursor();
          return cm.getRange(CodeMirror.Pos(cur.line, cur.ch - 1), cur) == "<";
        });
    }

    function completeIfInTag(cm) {
        return completeAfter(cm, function() {
          var tok = cm.getTokenAt(cm.getCursor());
          if (tok.type == "string" && (!/['"]/.test(tok.string.charAt(tok.string.length - 1)) || tok.string.length == 1)) return false;
          var inner = CodeMirror.innerMode(cm.getMode(), tok.state).state;
          return inner.tagName;
        });
    }



//Let's start: Create the Schema (a Javascript Object) for Codemirror
//Import the the XML file in a Ojbect schema for CodeMirror
var tags=$.cm_tei_schema();
        
//CODEMIRROR TRIGGER FOR REGESTO, NOTES, PROTOCOLLO, TESTO & ESCATOCOLLO TEXTAREAS
var resp=$('.pte').each(function(index, myeditor) {
    //console.log($(this).attr('id'));
    myeditor.value = vkbeautify.xml(myeditor.value);

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
        },
        //parse the Schema
        hintOptions: {schemaInfo: tags}
      });

    // on and off handler like in jQuery
    editor.on('change',function(cm){
        cm.save()
    });
    
    //Trigger with bootstrap tab change
    $('a[data-toggle="tab"]').on('shown.bs.tab', function(e) {
        setTimeout(function() {
            editor.refresh();
        }, 1);

    });
});

// Retrieve a CodeMirror Instance via native JavaScript.
function getCodeMirrorNative(target) {
    var _target = target;
    if (typeof _target === 'string') {
        _target = document.querySelector(_target);
    }
    if (_target === null || !_target.tagName === undefined) {
        throw new Error('Element does not reference a CodeMirror instance.');
    }
    
    if (_target.className.indexOf('CodeMirror') > -1) {
        return _target.CodeMirror;
    }

    if (_target.tagName === 'TEXTAREA') {
        return _target.nextSibling.CodeMirror;
    }
    
    return null;
};

//Trigger the Button to validate documents
$('#document-validate-button').on("click",function(e){
  
    e.preventDefault();
   
    var xmldata={};
    
    xmldata['id'] = $(this).data('id');
    xmldata['docid'] = $(this).data('docid');
    
    $( "#validation" ).empty();
    $( "#validation-tei" ).empty();
    $('.pte').each(function(index, myeditor) {
        var id=this.id;
        
        //var orig=editor.getTextArea();
        //var origid=orig.id;
    
        var myid = id.replace("[@", "_");
        var myid = myid.replace("=#", "_");
        var myid = myid.replace("#]", "");
    
        
        var edited=getCodeMirrorNative(this).getValue();
        if(edited.length>0){
           xmldata[myid] = edited;
           
        }
        
    });
    

    //console.log(xml2);
    $.ajax({
            url: "validate.html",
            method: "POST",
            data : xmldata,
            //data: { id: "ara3", docid: "ara3.6.xml"} ,
                //parts: JSON.stringify(scorez) },
            cache: false
        })
        .done(function( html ) {
            $( "#validation" ).append( html );
            
            //console.log(html)
            //score='1';
            //scores.push(html)
        })
        .fail(function(jqXHR, textStatus, errorThrown) {
            var error = '<div data-score="1" class="text-danger">error cm-tei-schema.js</div>';
            $( "#validation" ).append( error );
            
        });

});



    
    
  




/**
 * Remove all specified keys from an object, no matter how deep they are.
 * The removal is done in place, so run it on a copy if you don't want to modify the original object.
 * This function has no limit so circular objects will probably crash the browser
 * 
 * @param obj The object from where you want to remove the keys
 * @param keys An array of property names (strings) to remove
 * 
 * Source: Gist: https://gist.github.com/aurbano/383e691368780e7f5c98
 
function removeKeys(obj, keys){
    
    var index;
    for (var prop in obj) {
        // important check that this is objects own property
        // not from prototype prop inherited
        if(obj.hasOwnProperty(prop)){
            switch(typeof(obj[prop])){
                case 'string':
                    index = keys.indexOf(prop);
                    if(index > -1){
                        delete obj[prop];
                    }
                    break;
                case 'object':
                    index = keys.indexOf(prop);
                    if(index > -1){
                        delete obj[prop];
                    }else{
                        removeKeys(obj[prop], keys);
                    }
                    break;
            }
        }
    }
}
*/
/*
$('#document-validate-button').on("click",function(e){
    var scores=[];
    $( "#validation" ).empty().one();
    e.preventDefault();
    var orig=editor.getTextArea();
    var origid=orig.id;
    
    var myid = origid.replace("[@", "_");
    var myid = myid.replace("=#", "_");
    var myid = myid.replace("#]", "");
    
    
    var edited=editor.getValue();
  // get value right from instance
  //console.log(edited.length);
  
  if(edited.length>0){
     
        var res=$.ajax({
            url: "validate.html",
            method: "POST",
            data: { id: "ara3", 
                docid: myid+"_ara3.6.xml", 
                doc: edited },
            cache: false
        })
        .done(function( html ) {
            $( "#validation" ).append( html );
            //var score=$(html).find('span').data('score');
            
            //scores.push(score);
            //var sum = scores.reduce(function(scores, b) { return scores + b; }, 0);
            //console.log(score);
        })
        .fail(function(jqXHR, textStatus, errorThrown) {
            //alert( "error" );
            var nmyid = myid.substr(myid.lastIndexOf("_") + 1);
            
            
            var content = $(jqXHR.responseText).find("#content pre.error").html();
            var decodedContent = $('<span/>').html(content).text();
            var message = $(decodedContent).find("message").html();
            var validation= message.substr(0, message.indexOf('Validated')); 
            
            //console.log(validation);
            var error = '<div data-score="0" class="text-danger">'+nmyid+': '+validation+'</div>';
            $( "#validation" ).append( error )
            //var score=$('#validation span').data('score');
            //scores.push(score);
            
           
        })
        .always(function() {
            
            //var score=$('#validation div').data('score');
            //var sc=scores.push(score);
             
            //alert( "complete" );
        });
    
    res.done(function() {
        var score=$('#validation div').data('score');
        scores.push(score)
        var sum = scores.reduce(function(scores, b) { return scores + b; }, 0);
        //console.log(scores.length);  
    //.html()); 
    });     
    
    } 
      
});
*/

 
//TAGS&RULES
/*
var pippo = {
    "!top":['p'],
    
};

var p= {
        children: ["dateline","date","geogName","list","orgName","persName","placeName","roleName","span"]
    };
    
var persName= {
      attrs: {
        //http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.canonical.html
        key: null,//nome normalizzato: es. "Hugo, Victor (1802-1885)"
        role: ["re", "conte", "barone", "giudice","milite","chierico"],
        //freeform: null
      },
      children: ["forename","geogName","orgName","placeName","roleName","surname","span"]
        };    
    
pippo.p = p;
pippo.persName = persName;

//pippo.push(p);
*/

/*
var xtags = {
    //"p": null,
        //"!item": ["item"],
    "!top":['p'],
    //"geogName":["geogName"],
    //"date":["date"],

    p : {
        children: ["dateline","date","geogName","list","orgName","persName","placeName","roleName","span"]
    },
    persName: {
      attrs: {
        //http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.canonical.html
        key: null,//nome normalizzato: es. "Hugo, Victor (1802-1885)"
        role: ["re", "conte", "barone", "giudice","milite","chierico"],
        //freeform: null
      },
      children: ["forename","geogName","orgName","placeName","roleName","surname","span"]
        },
        
    geogName: {
        children: ["orgName","persName","placeName","roleName","span"],
        attrs: {
            key: null,
            role:[]
          },
        },
    
    placeName: {
        children: ["geogName","orgName","persName","roleName","span"],
        attrs: {
            key: null,
            role:[]
          },
        },
        
    orgName: {
        children: ["geogName","persName","placeName","roleName","span"],
        attrs: {
            key: null,
            role:[]
          },
        },  
        
    roleName: {
        children: ["geogName", "orgName", "persName","placeName","span"],
        attrs: {
            key: null,
            role:[]
          },
        },     

    dateline: {
            children: ["date","placeName","geogName","span"]
        },
    date: {
            children: [],
            attrs: {
                when:["YYYY-MM-DD"]
            },
        },
    
    list: {
        attrs: {rend: ['blulleted', 'numbered']},
        children: ['item']
        },
    item: {
            children: ["date","persName","placeName","geogName","list","span"] 
        },
    forename: {children: []},
    surname: {children: []},
    span: {
        children:[],
        attrs: {
            rend:['sup', 'uppercase']
        }
    }
      };
*/

//console.log(xtags);

    /*
    var summary = 
    var doc = editor.getCode();//$( "#document-form" ).serialize();
    var summary=$('#teiHeader_fileDesc_sourceDesc_msDesc_msContents_summary').html()
    //alert(regesto);
    $.ajax({
        url: "validate.html",
        method: "POST",
        data: { id: "ara3", 
                docid: "ara3.6.xml", 
                doc: doc },
        cache: false
    })
    .done(function( html ) {
        $( "#validation" ).empty().append( html );
    })
    .fail(function() {
        alert( "error" );
    })
    .always(function() {
        alert( "complete" );
    });
})*/

//console.log(raw_tags);    
//var help=['mela'];
/*var src=$.getJSON(jsonsource,function(result){
    
    //console.log(help);
   var data=result.members;
   $.each(data, function(i,item){
        for(x = 0; x < raw_tags.length; x++) { 
        if(item.ident==raw_tags[x]){
            //console.log(item);
            help.push(item);
            }  
        }
        
    });
    
});*/
