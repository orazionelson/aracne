xquery version "3.0";

module namespace mainapp="http://aracne/mainapp";

declare namespace html="http://www.w3.org/1999/xhtml";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://aracne/config" at "config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

import module namespace functx="http://www.functx.com/functx" at "functx.xql";

import module namespace mess="/messages" at "messages.xql";

declare 
    %templates:default("instance", "localhost")
function mainapp:active-panel($node as node(), $model as map(*), $instance as xs:string) {
    let $items := templates:process($node/node(), $model)
    return
        
        element { node-name($node) } {
            $node/@*,
            let $panel := request:get-attribute("$exist:resource")
            for $li in $items
            let $active :=
                switch ($panel)
                    case "index.html" return
                        ($instance = "localhost" and $li/html:a/@href = "index.html") or
                        ($instance != "localhost" and $li/html:a/@href = "remotes.html")
                    case "collection.html" return 
                        $li/html:a/@href = "indexes.html"
                    default return
                        $li/html:a/@href = $panel
            return
                if ($active) then
                    <html:li class="active">
                    { $li/node() }
                    </html:li>
                else
                    $li
        }
};

declare function mainapp:form-action-to-current-url($node as node(), $model as map(*)) {
    <form action="{request:get-url()}">{
        $node/attribute()[not(name(.) = 'action')],
        $node/node()
    }</form>
};

declare %templates:wrap function mainapp:collection-form($node as node(), $model as map(*)){
    let $root:=$config:data-root
    let $collections:=$config:collections
    let $id := request:get-parameter("id", ()) 
    
    let $collection:= if($id) then 
        for $collection in $collections/collection
        where $collection/id=$id
        return
        $collection
        else ()
    
    let $cpath:=$root||'/'||$id
    
    let $collections:=$config:collections
    

    
    return
       map { "id" := $collection/id, "ctitle":=$collection/ctitle, "docnum":=$collection/docnum, "from":=$collection/from, "to":=$collection/to, "type" := $collection/type, "main_editor":=$collection/main_editor, "main_source":=$collection/main_source, "publisher":=$collection/publisher, "status" := $collection/status } 
    
};

declare function mainapp:check-username($node as node(), $model as map(*), $name as xs:string?) {
    let $editors:=sm:get-group-members('aracne')
    let $res:=functx:is-value-in-sequence($name,$editors)
    return
     if($res=false()) then (
         response:redirect-to(xs:anyURI("editors.html"))
         ) else ()
};

declare function mainapp:get-username($node as node(), $model as map(*), $name as xs:string?) {
    $name
};

declare 
%templates:default("id", 'null')
function mainapp:collection-title($node as node(), $model as map(*),$id as xs:string) {
    
    let $collections:=$config:collections
    
    
    let $cid := if($id='null') then (request:get-parameter("id", ())) else ($id) 
    
    for $collection in $collections/collection
    where $collection/id=$cid
    return
        $collection/ctitle
    
};

declare 
%templates:default("id", 'null')
function mainapp:collection-title($id as xs:string) {
    
    let $collections:=$config:collections
    
    
    let $cid := if($id='null') then (request:get-parameter("id", ())) else ($id) 
    
    for $collection in $collections/collection
    where $collection/id=$cid
    return
        $collection/ctitle
    
};


declare %templates:wrap function mainapp:collection-owner($node as node(), $model as map(*)){
    let $root:=$config:data-root
    
    let $id := request:get-parameter("id", ()) 
    
    let $verify:=if(not($id)) then (
        
            (:
            To do: check if id exist AND check if the user is the owner
            :)
            response:redirect-to(xs:anyURI("index.html"))
    )
    else ()
    
    let $cpath:=$root||'/'||$id
    
    let $res:=
        if(xmldb:collection-available($cpath)=true()) then 
            let $permissions:=sm:get-permissions($cpath)
            let $owner:=data($permissions/sm:permission/@owner)
            return
                $owner
        else(
            
            )
    
    return
        $res
    
};

declare 
%templates:default("interface", 'editor')
function mainapp:collection-list-docs($node as node(), $model as map(*),$interface as xs:string) {
       let $root:=$config:data-root

        let $id := request:get-parameter("id", ())  
       
        
        let $cpath:=$root||'/'||$id

        
        let $child-resources := xmldb:get-child-resources($cpath)
        
        let $xx:=if (empty($child-resources))
                then
                    <p>Collezione vuota</p>
         (: return the count of number of files in this collection :)
            else (  <p>Collezione non vuota</p>)
         (: for each subcollection call local:count-files-in-collection($child) :)
        
        let $rows:=for $collection in collection($cpath)/TEI
            let $fname:=util:document-name($collection)
            let $dname:=substring-before($fname, '.xml')
            let $title:=$collection/teiHeader//titleStmt/title/text()
            let $date:=$collection/text//docDate/date/text()
            let $docowner:=xmldb:get-owner($cpath,$fname)
            order by $title
            return
                    <tr>
                    <td>{$dname}</td>    
                    <td>{$date}</td>    
                    <td>{$title}</td>
                    <td>{
                        if($docowner!='admin' and $interface='editor' ) 
                            then(
                                <div class="actions">
                                    <a href="document_form.html?id={$id}&amp;docid={$dname}.xml" class="btn btn-primary btn-sm">Edit</a>
                                    <a class="release-document btn btn-danger btn-sm" data-id="{$id}" data-docid="{$dname}" href="#">Release</a>
                                </div>
                                ) 
                        else if($docowner='admin' and $interface='editor' ) then (
                            <div>No actions available</div>
                                )
                        else (
                            <div><a href="document_form.html?id={$id}&amp;docid={$dname}.xml" class="btn btn-primary btn-sm">Verify</a>
                                <!--a style="cursor: not-allowed; pointer-events: none;" disabled="disabled" href="reassign_form.html?id={$id}&amp;docid={$dname}" class="btn btn-danger btn-sm">Reassign</a-->
                                </div>
                            )        
                    }
                    </td>
                    </tr>
        return  
            $rows
            
};


declare 
%templates:wrap 
%templates:default("interface", 'editor')
function mainapp:document-form($node as node(), $model as map(*), $interface as xs:string){
    let $root:=$config:data-root
    let $collections:=$config:collections
    let $id := request:get-parameter("id", ()) 
    
    let $verify:=if(not($id)) then (
        
            (:
            To do: check if id exist AND check if the user is the owner
            :)
            response:redirect-to(xs:anyURI("index.html"))
        )
        else ()
    
    let $docid := request:get-parameter("docid", ()) 
    
    let $path:= $root || '/' || $id || '/' || $docid 
    let $document := if($docid) then
        doc($path)/TEI
            else ()
    

    
    return
       map { "id" := $id, "docid":=$docid, "interface":=$interface, "document":=$document } 
    
};

declare %templates:wrap function mainapp:document-form-case($node as node()*,$model as map(*)){
    let $case:=if($model('docid')) then (
        'edit'
        ) 
        else (
            'new'
            )
    return 
        $case
};


declare function mainapp:document-form-input-case($node as node()*, $model as map(*)){
        <div><input name="case" readonly="readonly" type="hidden" class="templates:form-control form-control" value="{mainapp:document-form-case($node,$model)}"/></div>
};

declare function mainapp:document-form-input-collectionId($node as node()*, $model as map(*)){
    let $id := request:get-parameter('id', '')
    return
        <input name="collection_id" readonly="readonly" type="hidden" class="templates:form-control form-control" value="{$id}"/>
};

declare function mainapp:document-form-input-documentId($node as node()*, $model as map(*)){
    let $docid := request:get-parameter('docid', '')
    
   let $input:= if($docid) then(
        <input name="docid" readonly="readonly" type="hidden" class="templates:form-control form-control" value="{$docid}"/>
        )
        else ()
    return
        $input
};


declare function mainapp:document-form-tabs($node as node()*, $model as map(*)){
    <ul class="nav nav-tabs" role="tablist">
                                <li role="presentation" class="active">
                                    <a href="#meta" aria-controls="meta" role="tab" data-toggle="tab">Meta</a>
                                </li>
                                <li role="presentation">
                                    <a href="#bibliography" aria-controls="bibliography" role="tab" data-toggle="tab">Bibliography</a>
                                </li>
                                <li role="presentation">
                                    <a href="#notes" aria-controls="notes" role="tab" data-toggle="tab">Notes</a>
                                </li>
                                <li role="presentation">
                                    <a href="#document" aria-controls="document" role="tab" data-toggle="tab">Document</a>
                                </li>
                            </ul>
}; 


declare function mainapp:document-form-input-collectionOwner($node as node()*, $model as map(*)){
    (:let $docid := request:get-parameter('docid', ''):)
    let $root:=$config:data-root
    let $path:= $root || '/' || $model('id')
    let $owner:=xmldb:get-owner($path)
   (:let $input:= if($docid) then( :)
        
       (: )
        else () :)
    return
        <input name="owner" readonly="readonly" type="hidden" class="templates:form-control form-control" value="{$owner}"/>
};


(: https://atheek.wordpress.com/2011/12/20/adding-namespace-using-xquery/ :)
declare function mainapp:addNamespaceToXML($noNamespaceXML as element(*),$namespaceURI as xs:string) as element(*)
{
element {QName($namespaceURI,fn:local-name($noNamespaceXML))}
{
$noNamespaceXML/@*,
for $node in $noNamespaceXML/node()
return
if (exists($node/node())) then mainapp:addNamespaceToXML($node,$namespaceURI)
else if ($node instance of element()) then element {QName($namespaceURI,fn:local-name($node))}{$node/@*}
else $node }
};

declare function mainapp:replace-elements($element as element()) as element()? {
if ($element/* or $element/text())
  then 
   element {node-name($element)}
      {$element/@*,
          for $child in $element/node()
              return
                $child
      }
    else ()
};

declare function mainapp:remove-empty-elements($element as element()) as element()? {
if ($element/* or $element/text())
  then 
   element {node-name($element)}
      {$element/@*,
          for $child in $element/node()
              return
               if ($child instance of element())
                 then mainapp:remove-empty-elements($child)
                 else $child
      }
    else ()
};


declare function mainapp:join-publicationStmt($id) {
    let $collections:=$config:collections

    for $collection in $collections/collection
    where $collection/id=$id
    return
        <publicationStmt>
            {$collection/publisher}
            <pubPlace>Napoli</pubPlace>
            <date>{year-from-date(current-date())}</date>
        </publicationStmt>
};



declare 
%templates:wrap 
%templates:default("type", 'text')
%templates:default("required", 'false')
%templates:default("class", '')
function mainapp:generic-form-input($node as node()*, $model as map(*), $field as xs:string?, $type as xs:string, $required as xs:string, $class as xs:string) {
    let $root:=$config:data-root
    
    let $field_value:=if($model('docid')) then (
        let $path:= $root || '/' || $model('id') || '/' || $model('docid')
        let $teipath:=replace($field, '_', '/')
        let $basequery:=concat("doc('",$path,"')/TEI//",$teipath)
        
        let $q:=util:eval($basequery) 
        return
            $q
        ) 
        else ()
    
    let $required_value:=if($required='true')
    then 'required'
    else ()
    
    let $label:=if($required='true')
    then concat(mainapp:form-labels($field),'*')
    else (mainapp:form-labels($field))
    
    return
        <div class="form-group">
            <label for="{$field}">{$label}</label>
            <input name="{$field}" data-required="{$required}" type="{$type}" class="templates:form-control form-control {$class}" placeholder="{$label}" value="{ $field_value }" />
                
        </div>
};

declare function mainapp:collection-mindate($node as node(), $model as map(*)){
    let $mindate:=$model('from')
    return
        <span id="mindate" data-date="{$mindate}" class="hidden">{$mindate}</span>
};

declare function mainapp:collection-maxdate($node as node(), $model as map(*)){
    let $maxdate:=$model('to')
    return
        <span id="maxdate" data-date="{$maxdate}" class="hidden">{$maxdate}</span>
};


declare 
%templates:wrap 
%templates:default("class", '')
function mainapp:generic-form-textarea($node as node(), $model as map(*),$field as xs:string?, $class as xs:string?) {
    let $root:=$config:data-root
    let $field_value:=
        if($model('docid')) then (
            let $path:= $root || '/' || $model('id') || '/' || $model('docid') 
            let $teipath:=replace($field, '_', '/')
            let $teipath:=replace($teipath, '#', "'")
            
        
            let $basequery:=concat("doc('",$path,"')/TEI//",$teipath,'/*')

            let $q:=util:eval($basequery) 
            return
                $q
            ) 
        else ()
    return    
    <div class="form-group">
        <label class="control-label" for="{$field}" id="{$field}label">{mainapp:form-labels($field)}</label>
        <div>
            <textarea class="form-control {$class}" rows="8" name="{$field}" id="{$field}">
                
             {$field_value}   
 
            </textarea>
        </div>
    </div>
};

declare 
%templates:wrap 
%templates:default("options", '1,2,3,4')
%templates:default("class", '')
function mainapp:generic-form-select($node as node()*, $model as map(*), $field as xs:string?, $options as xs:string, $class as xs:string) {
    let $root:=$config:data-root
    
    let $field_value:=if($model('docid')) then (
        let $path:= $root || '/' || $model('id') || '/' || $model('docid') 
        let $teipath:=replace($field, '_', '/')
        let $basequery:=concat("doc('",$path,"')/TEI//",$teipath)
        let $q:=util:eval($basequery)  
        
        let $res:=if(contains($teipath, '@')) then (data($q))
        else ($q)
        
        return
            $res
        
        ) 
        else ()
        
    (:$optList := tokenize($options, ','):)
        
    let $label := mainapp:form-labels($field)
    return
        <div class="form-group">
            <label for="{$field}">{$label}</label>
            <select class="form-control" name="{$field}" id="{$field}">
                {
                for $option in tokenize($options, ',')
                let $opt:=
                    if($option=$field_value) then (
                        <option selected="selected">{$option}</option>
                    ) else (
                        <option>{$option}</option>
                    )
                return
                    $opt
                }
            </select>
        </div>
    
};


declare function mainapp:form-labels($tag as xs:string){
    let $term:=
        if($tag='ctitle') 
        then "Collection Title"
        else if($tag='docnum')
        then "Number of documents"
        else if($tag='from')
        then "From"
        else if($tag='to')
        then "To" 
        else if($tag='teiHeader_fileDesc_titleStmt_title')
        then "Document title" 
        else if($tag='main_editor')
        then "Editor in chief" 
        else if($tag='main_source')
        then "Source"
        else if($tag='publisher')
        then "Publisher"
        else if($tag='teiHeader_fileDesc_sourceDesc_msDesc_msContents_summary')
        then "Summary/Regesto"
        else if($tag='teiHeader_fileDesc_noteStmt_note')
        then "Note"
        else if($tag="text_body_docDate_date")
        then "Date"
        else if($tag="text_body_div[@type=#protocollo#]")
        then "Protocollo"
        else if($tag="text_body_div[@type=#testo#]")
        then "Testo"
        else if($tag="text_body_div[@type=#escatocollo#]")
        then "Escatocollo"
        else if($tag="teiHeader_fileDesc_sourceDesc_msDesc_msIdentifier_idno")
        then "Archival ID"
        else if($tag="teiHeader_fileDesc_sourceDesc_msDesc_physDesc_objectDesc_@form")
        then "Document Type"
        else if($tag="teiHeader_fileDesc_sourceDesc_msDesc_physDesc_objectDesc")
        then "Notes"
        else ($tag)
    return
        $term
};

declare 
%templates:wrap 
function  mainapp:document-listBibl-bibl($node as node(), $model as map(*),$bibl_type as xs:string, $teinode as xs:string?) {
    let $a:='b'
    let $root:=$config:data-root
    let $teinode:=concat($teinode,"_bibl[@type=#",$bibl_type,"#]")
    let $field_value:=
        if($model('docid')) then (
            let $path:= $root || '/' || $model('id') || '/' || $model('docid') 
            let $teipath:=replace($teinode, '_', '/')
            let $teipath:=replace($teipath, '#', "'")
           
        
            let $basequery:=concat("doc('",$path,"')/TEI//",$teipath)

            let $q:=util:eval($basequery) 
            return
                $q
            ) 
        else ()
    return
        <div class="multiple-input-container" data-teinode="{$teinode}">
        {
            if (count($field_value)=0) then (
        
            <div class="form-group">
                <label class="col-sm-2 control-label">{$bibl_type}</label>
                <div class="multiple-input col-sm-10" style="margin-bottom:5px">
                    <input class="form-control" type="text" value=""/>
                </div>
            </div>

        
        )
        else (
            for $bibl in $field_value
            return
        
        
            <div class="form-group">
                <label class="col-sm-2 control-label">{$bibl_type}</label>
                <div class="multiple-input col-sm-10" style="margin-bottom:5px">
                    <input class="form-control" type="text" value="{$bibl}"/>
                    <a href="#" class="remove_field">Remove</a>
                </div>
            </div>
            )
        }
        <button class="btn btn-primary add_field_button" style="margin-top:7px;">Add More</button>
        </div>

      
};

declare 
%templates:wrap 
function mainapp:document-listBibl($node as node(), $model as map(*), $teinode as xs:string?) {
    <div>
    <span class="hide">{$teinode}</span>
    <h3>Source types</h3>
    {mainapp:document-listBibl-bibl($node, $model,'source', $teinode)}
    <hr/>
    {mainapp:document-listBibl-bibl($node, $model,'tradition', $teinode)}
    <hr/>
    {mainapp:document-listBibl-bibl($node, $model,'edition', $teinode)}
    <hr/>
    {mainapp:document-listBibl-bibl($node, $model,'bibliography', $teinode)}
    </div>
};


declare 
%templates:wrap 
function mainapp:document-respStmt($node as node(), $model as map(*),$teinode as xs:string?) {

    let $a:='b'
    let $root:=$config:data-root

    let $field_value:=
        if($model('docid')) then (
            let $path:= $root || '/' || $model('id') || '/' || $model('docid') 
            let $teipath:=replace($teinode, '_', '/')
            let $teipath:=replace($teipath, '#', "'")
           
        
            let $basequery:=concat("doc('",$path,"')/TEI//",$teipath)

            let $q:=util:eval($basequery) 
            return
                $q
            ) 
        else ()

   
    
    return
        
    <div class="document-respstmt-container" data-teinode="{$teinode}" data-idcontainer="">  
    {if (count($field_value)=0) then (
        let $user := request:get-attribute("org.exist.login.user")
        let $name := sm:get-account-metadata($user, xs:anyURI("http://axschema.org/namePerson"))
        return
        <div class="form-group row">
            <div class="col-md-6">
                <label>Role</label>
                <select class="form-control">
                    <option>transcription by</option>
                    <option>revision by</option>
                    <option>mark-up by</option>
                </select>
            </div>
            <div class="col-md-6">
                <label>Name</label>
                <input class="form-control" type="text"value="{$name}"/>
            </div>
        </div>
        )
        else (
        for $respStmt in $field_value
        let $transcription_by:=if ($respStmt/resp="transcription by") 
                                then (<option selected="selected">transcription by</option>) 
                                else (<option>transcription by</option>)
        
        let $revision_by:=if ($respStmt/resp="revision by") 
                                then (<option selected="selected">revision by</option>) 
                                else (<option>revision by</option>)
        let $mark-up_by:=if ($respStmt/resp="mark-up by") 
                                then (<option selected="selected">mark-up by</option>) 
                                else (<option>mark-up by</option>)
                return
                <div class="form-group row">
                    <div class="col-md-6">
                        <label>Role</label>
                        <select class="form-control">
                            {$transcription_by}
                            {$revision_by}
                            {$mark-up_by}
                        </select>
                    </div>
                    <div class="col-md-6">
                    <label>Name</label>
                    <input class="form-control" type="text"value="{$respStmt/name}"/>
                    </div>
                </div>
                    
            )
    }
    </div>
};


declare 
%templates:wrap 
function mainapp:document-noteStmt($node as node(), $model as map(*),$teinode as xs:string?, $class as xs:string) {
    
    let $root:=$config:data-root
    let $field_value:=
        if($model('docid')) then (
            let $path:= $root || '/' || $model('id') || '/' || $model('docid') 
            let $teipath:=replace($teinode, '_', '/')
            let $teipath:=replace($teipath, '#', "'")
           
        
            let $basequery:=concat("doc('",$path,"')/TEI//",$teipath,"/*")

            let $q:=util:eval($basequery) 
            return
                $q
            ) 
        else ()    
    return
        <div class="multiple-textarea-container" data-teinode="{$teinode}" data-class="{$class}">
        {
         if (count($field_value)=0) then (
    
        <div class="form-group">
            <label class="col-sm-2 control-label">{mainapp:form-labels($teinode)}</label>
            <div class="col-sm-10" style="margin-bottom:10px">
                <textarea class="form-control {$class}" name="{$teinode}" id="{$teinode}_1" rows="8">
                
                
 
                </textarea>
            </div>
        </div>
        
         )
         else (
          for $note in $field_value
          return 
        <div class="form-group">
            <label class="col-sm-2 control-label">{mainapp:form-labels($teinode)}</label>
            <div class="col-sm-10" style="margin-bottom:10px">
                <textarea class="form-control {$class}" name="{$teinode}[]" rows="8">
                {$note}
                
 
                </textarea>
                <a href="#" class="remove_textarea">Remove</a>
            </div>
        </div>
             )}            
         <button class="btn btn-primary add_textarea_button" style="margin-top:5px;">Add More</button>
    </div>
};

declare 
%templates:wrap 
function mainapp:document-text($node as node(), $model as map(*),$teinode as xs:string?) {
    
    let $protocollo:=concat($teinode,"[@type=#protocollo#]")
    let $testo:=concat($teinode,"[@type=#testo#]")
    let $escatocollo:=concat($teinode,"[@type=#escatocollo#]")
    return
    <div>
    {mainapp:generic-form-textarea($node,$model,$protocollo,'pte')}
    {mainapp:generic-form-textarea($node,$model,$testo,'pte')}
    {mainapp:generic-form-textarea($node,$model,$escatocollo,'pte')}
    </div>
};

declare function mainapp:document-form-help-panel($node as node(), $model as map(*)){
    <div id="help_panel" class="panel panel-primary" role="document" style="     display:none;     position: fixed;    top: 200px;    right: 0;    z-index: 10040;    height:450px;    width:600px;    ">
        <div class="panel-heading">
            <div class="row">
                <div class="col-sm-5">
                    <input id="search-tag" class="form-control" type="text" placeholder="Search tag"/>
                </div>
                <button type="button" style="margin-right:5px" class="btn btn-danger btn-sm open-help pull-right">
                    <span class="glyphicon glyphicon-off" aria-hidden="true"/>
                </button>
                <button type="button" style="margin-right:10px" class="btn btn-warning btn-sm pull-right allowed-tags">
                Allowed TAGS <i class="fa fa-code"/>
                </button>
                <button type="button" style="margin-right:10px" class="btn btn-success btn-sm pull-right tips-and-examples">
                Tips &amp; Examples <i class="fa fa-flag-o"/>
                </button>
            </div>
        </div>
        <div class="panel-body" style="position:absolute;width:100%;height:380px;overflow: auto; overflow-y: auto;">
            <div class="lead" id="allowed-tags" style="display:none"/>
            <div id="tips-and-examples" style="display:none">
                <p>Start any paragraph with <code>&lt;p</code>
                </p>
                <p>The XML emlements and attributes work with autocompletion: starting a tag (write <code> &lt; </code>) will show you a list of possible tags you can use.</p>
                <p>By adding a space after an element name you will be showed its own attributes.</p>
                <p> See the examples:</p>
                <p>Mark-up a person name:</p>
                <img src="resources/img/es1.gif" class="img-responsive"/>
                <hr/>
                <p>Mark-up document datatio</p>
                <img src="resources/img/es2.gif" class="img-responsive"/>
            </div>
            <div id="tei-help"/>
        </div><!-- /.panel-body  style="display:none"-->
    <!-- /#help_panel --> 
    </div>   
};


declare function mainapp:validate-tei($node as node()*, $model as map(*)){
    
    (:To validate the document against TEI a temporary end-copy is created :)
    
    (:Post params passed via validate-tei.js -> validate-tei.html:)
    
    let $collection_id := request:get-parameter('collection_id', '')
    let $docid := request:get-parameter('docid', '')
    let $owner := request:get-parameter('owner', 'anon')

    let $title := request:get-parameter('teiHeader_fileDesc_titleStmt_title', '')
    let $resp := request:get-parameter('resp[]', '')
    let $name := request:get-parameter('name[]', '')
    let $biblio_source := request:get-parameter('teiHeader_fileDesc_sourceDesc_listBibl_bibl[@type=#source#][]', '')
    let $biblio_tradition := request:get-parameter('teiHeader_fileDesc_sourceDesc_listBibl_bibl[@type=#tradition#][]', '')
    let $biblio_edition := request:get-parameter('teiHeader_fileDesc_sourceDesc_listBibl_bibl[@type=#edition#][]', '')
    let $biblio_bibliography := request:get-parameter('teiHeader_fileDesc_sourceDesc_listBibl_bibl[@type=#bibliography#][]', '')
    let $segnatura := request:get-parameter('teiHeader_fileDesc_sourceDesc_msDesc_msIdentifier_idno', '')
    let $date := request:get-parameter('text_body_docDate_date', '')
    let $summary := request:get-parameter('teiHeader_fileDesc_sourceDesc_msDesc_msContents_summary', '')
    let $objectDesc := request:get-parameter('teiHeader_fileDesc_sourceDesc_msDesc_physDesc_objectDesc', '')
    let $objectDescForm := request:get-parameter('teiHeader_fileDesc_sourceDesc_msDesc_physDesc_objectDesc_@form','')
    let $notes := request:get-parameter('teiHeader_fileDesc_noteStmt_note[]', '')

    let $protocollo := request:get-parameter('text_body_div[@type=#protocollo#]', '')
    let $testo := request:get-parameter('text_body_div[@type=#testo#]', '')
    let $escatocollo := request:get-parameter('text_body_div[@type=#escatocollo#]', '')

    (:RICORDA: add main editor and software author & copyright :)
    let $tei:=	
<TEI>
    <teiHeader>
        <fileDesc>
            <titleStmt>
                <title>
                {$title}
                </title>
            {
                for-each-pair($resp, $name, 
                    function($a, $b){
                    <respStmt>
                        <resp>{$a}</resp>
                        <name>{$b}</name>
                    </respStmt>
                    }
                )
            }
        </titleStmt>
        {mainapp:join-publicationStmt($collection_id)}
        <sourceDesc>
            <listBibl>
               {for $bibl in $biblio_source
                    return
                        if($bibl) then <bibl type="source">{$bibl}</bibl>
                        else ()}
               {for $bibl in $biblio_tradition
                    return
                        if($bibl) then <bibl type="tradition">{$bibl}</bibl>
                        else () }
               {for $bibl in $biblio_edition
                    return
                        if($bibl) then <bibl type="edition">{$bibl}</bibl>
                        else ()}
               {for $bibl in $biblio_bibliography
                    return
                        if($bibl) then <bibl type="bibliography">{$bibl}</bibl>
                        else ()    }
            </listBibl>
            <msDesc>
                <msIdentifier>
                    <idno>{$segnatura}</idno>
                </msIdentifier>
                <msContents>
                    <summary>
                        {parse-xml-fragment($summary)}
                    </summary>
                </msContents>
                <physDesc>
                    <objectDesc form="{$objectDescForm}">
                        {parse-xml-fragment($objectDesc)}
                    </objectDesc>
                 </physDesc>                
            </msDesc>
        </sourceDesc> 
        <noteStmt>
            {for $note in $notes
                return
                if($note) then <note>{parse-xml-fragment($note)}</note>
            else ()}
        </noteStmt>
    </fileDesc> 
</teiHeader>
<text>
    <body>
        <docDate><date>{$date}</date></docDate>
        <div type="protocollo">{parse-xml-fragment($protocollo)}</div>
        <div type="testo">{parse-xml-fragment($testo)}</div>
        <div type="escatocollo">{parse-xml-fragment($escatocollo)}</div>
        </body>
    </text>
</TEI>

    


    let $root:=$config:data-root
    let $cpath:=$root||'/temp'
    let $path:= $cpath || '/' || $docid
    let $schema := doc($root||'/tei_all.xsd')
    
    (:Remove old document temp copies:)
    let $remove-old-file:=if(doc($path)) then (xmldb:remove($cpath, $docid)) else ()
    let $store-first:=xmldb:store($cpath, $docid, $tei)
    let $doc := doc(concat($cpath,"/",$docid))
    
    (:E - Add namespaces to the new file:)
    (:
    I looked at this fu*kin function for months, it was difficult to realize that if you add namespeces to all the tree
    by default you will have it represented only on the first element
    :)
    let $teidoc:=mainapp:addNamespaceToXML($doc/TEI, "http://www.tei-c.org/ns/1.0")

    (: H - Remove empty elements:)
    (:Don't know why but TEI xsd doesn't like some empty elements, so: remove all:)
    let $teidoc:=mainapp:remove-empty-elements($teidoc)
    
    (:Remove and restore the new file with namescpace:)
    let $remove-old-file:=if(doc($path)) then (xmldb:remove($cpath, $docid)) else ()
    let $store-second:=xmldb:store($cpath, $docid, $teidoc)
    
    let $document := doc($root||'/temp/'||$docid)
    let $is_body:=$document//tei:body/tei:div/*
    let $body_check:=if($is_body) then () else (update insert <tei:div type="empty"/> into $document//tei:body)

    (:Z - And finally the validation process:)
    let $document := doc($root||'/temp/'||$docid)
    let $ns:=functx:namespaces-in-use($document)
    
    let $clear := validation:clear-grammar-cache()
    
    let $validation:=
    <validation timestamp="{current-dateTime()}" schema="{document-uri($schema)}">
        
        <div uri="{document-uri($document)}">
        {
            validation:validate-report($document,$schema)
        }<br/>
        </div>
    </validation>
    
    let $status_class:=if ($validation//status='valid') then 'text-success' else 'text-danger'
    return
    <div>
        <!--div>{$document}</div-->
        <div><span class="{$status_class}" style="margin-right:20px; text-transform:uppercase"><strong>{$validation//status}</strong></span>  
            {
                if(validation:validate($document)) then(
                    <button id="document-form-button" type="submit" class="btn btn-primary">Save <span class="glyphicon glyphicon-file"/></button>
                )
                else ()
            }
            
        </div>
        <!-- debug //form="document-form" 
        <p>namespace: {$ns}</p>
        <p>schema: {document-uri($schema)}</p>
        <p>grammar cache: {validation:show-grammar-cache()}</p>
        <p>risultato: {validation:validate($document)}</p>
        -->
        
    {for $message in $validation//message
    let $msg:=$message/text()
        return
            <div>
                <strong>{data($message/@level)}:</strong> at line {data($message/@line)} column {data($message/@column)}<br/>
                Search the error in Google: <a href="https://www.google.it/search?q={substring-before($message/text(), ':')}" target="_new">{substring-before($message/text(), ':')}</a>
                <!--p>{if(string-length($msg)<200) then ($msg) else(substring($msg, 1, 300))}</p-->
                <p>{$msg}</p>
                <br/> 
            </div>
    }
    
    </div>

    
};





declare function mainapp:validate-document-parts($node as node()*, $model as map(*)) {
    let $root:=$config:data-root
    let $data := request:get-data()
    let $id := request:get-parameter('id', '')
    let $docid := request:get-parameter('docid', '')
    
    let $params:=request:get-parameter-names()
    let $partnames:=for $param in $params
                    let $part:=if($param!='id' and $param!='docid') then ($param) else ()
                    return
                        $part
                        
    let $scores-fname:=concat('scores_',$docid)                    
    
    let $scores-path:=concat($root,'/temp/',$scores-fname)
    
    let $scores-remove-old:=if(doc($scores-path)) then (xmldb:remove($root||'/temp',  $scores-fname)) else ()
    
    let $scores-root:=<scores></scores>
    
    let $scores-store-new := xmldb:store($root||'/temp', $scores-fname, $scores-root)
    
    
    let $scores:=doc($scores-path)
    return
        <div><!--h3>{$docid}</h3-->
            {
            for $partname in $partnames
            let $value:=request:get-parameter($partname, '')
            let $humanPartName:=functx:substring-after-last($partname, '_')
            return 
                try {
		              let $doc := util:parse(concat('<pte>',$value,'</pte>'))
		              let $score0:= update insert <score>0</score> into $scores/scores
                        return
                            update insert <score>0</score> into $scores/scores
                        (:<li>
                            <p class="text-success">{$partname} is valid</p>
                        </li>:)
	                } catch * {
	                    (:exerr:EXXQDY0002:)
                    let $score1:= update insert <score>1</score> into $scores/scores
                    return
                        <ul class="list-group">
	                        <li class="list-group-item">
	                        <p class="text-danger" style="text-transform: capitalize;"><b>{$humanPartName}</b>: 
	                        {$err:description}: {$err:value}</p>
	                        <!--p class="text-danger">Error Code: {$err:code}</p-->
		                    <!--p>{$value}</p-->
		                    </li>
		              </ul>      

	            }
           
        }
            
        
            {let $sum:=fn:sum($scores//score)
                let $res:=if($sum=0) then (
                       
                        <script type="text/javascript" src="../resources/scripts/validate-tei.js"/>

                    ) 
                else ()
                let $scores-remove-old:=if(doc($scores-path)) then (xmldb:remove($root||'/temp',  $scores-fname)) else ()
                return
                    $res
            }
            
        </div>

    
};

declare function mainapp:validate-button($node as node()*, $model as map(*)){
    let $id := request:get-parameter('id', '')
    let $docid := if(request:get-parameter('docid', '')) 
                then (request:get-parameter('docid', ''))
                else (concat(floor(util:random() * 10000)+1,'.xml'))

    return
        <button id="document-validate-button" data-id="{$id}" data-docid="{$docid}" class="btn btn-success">Validate <span class="glyphicon glyphicon-ok"/></button>
    
};

declare function mainapp:collection-docnum($node as node(), $model as map(*)){
    let $collections:=$config:collections
    let $id := request:get-parameter("id", ()) 
    
    for $collection in $collections/collection
    where $collection/id=$id
    return
        $collection/docnum
};

declare function mainapp:collection-released($node as node(), $model as map(*)){
    let $root:=$config:data-root
    let $id := request:get-parameter("id", ())  
    let $cpath:=$root||'/'||$id
    
    let $released:=for $collection in collection($cpath)/TEI
        let $fname:=util:document-name($collection)
        let $docowner:=xmldb:get-owner($cpath,$fname)
        return
            if($docowner='admin') then (
                let $x:='x'
                return
                $fname
                ) 
                else ()
    
    return
        $released
};

declare function mainapp:collection-released-percent($node as node(), $model as map(*)){
    let $collection-docnum:=mainapp:collection-docnum($node,$model)
    
    let $released:=mainapp:collection-released($node, $model)
                
    let $rapporto-released:=count($released) div number($collection-docnum)
    let $rpercent:=format-number($rapporto-released, '0%')  
    
    return
        $rpercent
};

declare function mainapp:collection-stats($node as node(), $model as map(*)){
    let $root:=$config:data-root
    let $id := request:get-parameter("id", ())  
    let $cpath:=$root||'/'||$id
    
    let $collection-created:=count(collection($cpath))
    
    let $collection-docnum:=mainapp:collection-docnum($node,$model)
    let $rapporto-created:=number($collection-created) div number($collection-docnum)
    
    let $cpercent:=format-number($rapporto-created, '0%')
    
    (:let $collection-owner:=xmldb:get-owner($cpath)
    app:collection-owner($node,$model)
    
    let $rapporto-released:=count($released) div number($collection-docnum)
    :)
    let $released:=mainapp:collection-released($node, $model)
    let $rpercent:=mainapp:collection-released-percent($node, $model)                
    
    return
     <div><p>Created:{$collection-created} ({$cpercent}%)</p>
        <p>Released:{count($released)} ({$rpercent}%)</p>
    </div>  
};
