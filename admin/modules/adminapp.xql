xquery version "3.0";

module namespace adminapp="http://aracne/admin/templates";

declare namespace tei = "http://www.tei-c.org/ns/1.0";


import module namespace templates="http://exist-db.org/xquery/templates" ;

import module namespace config="http://aracne/config" at "../../modules/config.xqm";
import module namespace mainapp="http://aracne/mainapp" at "../../modules/mainapp.xql";

import module namespace functx="http://www.functx.com/functx" at "../../modules/functx.xql";



declare namespace cc="http://exist-db.org/collection-config/1.0";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare namespace xlink="http://www.w3.org/1999/xlink";

declare namespace json="http://www.json.org";

declare option exist:serialize "method=json media-type=application/json";

(: Site structure :)
declare variable $adminapp:structure:=doc(concat($config:app-root,"/admin/data/site_structure.xml"));



declare function adminapp:collection-button-create($node as node(), $model as map(*)){
    
    <a href="collection_form.html" class="btn btn-primary">New Collection</a>
    
};

declare function adminapp:collections($node as node(), $model as map(*)){

    let $collections:=$config:collections
    
    for $collection in $collections/collection

    return
        <tr>
            <td class="collection-id-column">{$collection/id}</td>
            <td><a class="collection-title" href="collection.html?id={$collection/id}">{$collection/ctitle}</a></td>
            <td>{$collection/docnum}</td>
            <td>{$collection/from}</td>
            <td>{$collection/to}</td>
            <td>
                <div class="actions">
                <a class="btn btn-primary btn-sm" href="collection_form.html?id={$collection/id}">Metadata</a>
                {adminapp:status-button($collection/id)}
                </div>
            </td>
        </tr>        
};


declare %templates:wrap function adminapp:collection-form-case($node as node()*,$model as map(*)){
    let $case:=if($model('id')) then ('edit') else ('new')
    return 
        $case
};

declare function adminapp:collection-form-input-case($node as node()*, $model as map(*)){
        <input name="case" readonly="readonly" type="hidden" class="templates:form-control form-control" value="{adminapp:collection-form-case($node,$model)}"/>
};

declare function adminapp:collection-create-id(){
    let $collections:=$config:collections
    let $last_id:=$collections/collection/id
    let $llast_id:=if($last_id[last()]) then ($last_id[last()]) else ('ara0')
    let $last_value:=xs:int(replace($llast_id, 'ara', ''))+1
    return
    $last_value
    
};

declare %templates:wrap function adminapp:collection-form-input-id($node as node()*, $model as map(*)) {
    let $id:=if($model('id')) then ($model('id')) else (
            concat('ara',adminapp:collection-create-id())
            )
    
    return
        <div class="form-group">
        <!--label for="id">Id *</label-->
    <input name="id" readonly="readonly" type="hidden" class="templates:form-control form-control" placeholder="id" required="required" value="{ $id }" /></div>
};

declare %templates:wrap function adminapp:collection-form-input-status($node as node()*, $model as map(*)) {
    let $status:=if($model('status')) then ($model('status')) else ("unassigned")
    return
        <div class="form-group">
        <!--label for="id">Id *</label-->
    <input name="status" readonly="readonly" type="hidden" class="templates:form-control form-control" placeholder="status" required="required" value="{ $status }" /></div>
};

declare 
%templates:wrap 
%templates:default("type", 'text')
%templates:default("required", 'false')
%templates:default("class", '')
function adminapp:collection-generic-form-input($node as node()*, $model as map(*), $field as xs:string?, $type as xs:string, $required as xs:string, $class as xs:string) {
    let $root:=$config:data-root
    
    let $field_value:=if($model('id')) then (
        let $path:= $root || '/collections.xml'
        let $cid:=$model('id')
        let $basequery:=concat("doc('",$path,"')/collections/collection[@id='",$cid,"']/",$field)
        
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







declare %templates:wrap function adminapp:list-editors($node as node(), $model as map(*)) {
    let $editors:=sm:get-group-members($config:editor-group)
    for $editor in $editors
    return
        if($editor!='admin') then
        <tr>
            <td>{$editor}</td>
            <td>{sm:get-account-metadata($editor, xs:anyURI('http://axschema.org/namePerson'))}</td>
            <td><a href="assign.html?name={$editor}" class="btn btn-primary">Manage</a></td>                
        </tr>
        else ()
};

declare %templates:wrap function adminapp:errors($node as node(), $model as map(*), $message as xs:string?) {
    let $errormsg:=
        if($message='error1') then "It is not possible to assign the collection, contact administrator."
        else if($message='error2') then "Unvalid editor."
        else if($message='error3') then "The editor exists."
        else ()
    return    
    $errormsg
};

declare function adminapp:status-button($child){
    let $status:=adminapp:collection-status($child)
    let $collectionpath:=$config:data-root||'/'||$child
    
    let $res:=
        if(xmldb:collection-available($collectionpath)=true()) then 
            let $permissions:=sm:get-permissions($collectionpath)
            let $owner:=data($permissions/sm:permission/@owner)
            let $group:=data($permissions/sm:permission/@group)
            return
               
                if($status='assigned' and $group='arareleased') then (
                    <a class="btn btn-sm btn-warning collection_build" href="build.html?id={$child}">Released > Build</a> 
                    )
                else if($status='assigned') then (<a class="btn btn-sm btn-danger" href="assign.html?name={$owner}">Check owner: {$owner}</a>) 
                else if($status='built') then (<span><a class="btn btn-sm btn-success" href="collections_built.html">Built: Validate and Publish</a><a class="btn btn-sm btn-warning collection_build" href="build.html?id={$child}">Build Again</a></span> ) 
                else (
                    <a class="btn btn-sm btn-success" href="assign.html">Assign</a>
                    )
            
        else()
    
    return
        $res
    
};

declare function adminapp:collection-status($id as xs:string) {
    let $collections:=$config:collections
    for $collection in $collections/collection
    where $collection/id=$id
    return
        $collection/status
    
};


declare function adminapp:assigned-to-user($node as node(), $model as map(*), $name as xs:string?) {
    let $root:=$config:data-root
    (:let $root:='/db/apps/ratest/data':)
    let $children := xmldb:get-child-collections($root)
    
    let $assigned:=
        for $child in $children
        let $collectionpath:=$root||'/'||$child
        let $permissions:=sm:get-permissions($collectionpath)
        order by $child ascending
        return
            if(data($permissions/sm:permission/@owner)=$name) then $child else ()
        
    return
        if(count($assigned)=0) then <p class="lead text-center">There are no collection for {$name}</p> 
        else
        for $partizione in $assigned
        return
        <tr>
            <td>{$partizione}</td><td>{ let $collections:=$config:collections
                                        for $collection in $collections/collection
                                            where $collection/id=$partizione
                                        return
                                            $collection/ctitle
                                    }</td>
            <td><a href="collection.html?id={$partizione}" class="btn btn-success">Verify</a></td>                        

        </tr>
};

declare function adminapp:assigned-to-others($node as node(), $model as map(*), $name as xs:string?) {
    
    let $root:=$config:data-root
    let $children := xmldb:get-child-collections($root)
    
    let $assigned:=
        for $child in $children
        let $collectionpath:=$root||'/'||$child
        let $permissions:=sm:get-permissions($collectionpath)
        order by $child ascending
        return
            if(data($permissions/sm:permission/@owner)!=$name and data($permissions/sm:permission/@owner)!='admin') then $child else ()
        
    return
        if(count($assigned)=0) then <p class="lead text-center">There aren't collections assigned to other users</p> 
        else
        for $partizione in $assigned
        
        let $collectionpath:=$root||'/'||$partizione
        let $permissions:=sm:get-permissions($collectionpath)
        return
        <tr>
            <form id="{$name}{$partizione}" action="assign.xql" method="POST" class="form">
            <td><input type="checkbox" id="{$partizione}" name="id" value="{$partizione}"/></td>
            <td>{$partizione}</td>
            <td>{ let $collections:=$config:collections
                                        for $collection in $collections/collection
                                            where $collection/id=$partizione
                                        return
                                            $collection/ctitle
                                    }</td>
            <td>{data($permissions/sm:permission/@owner)}</td>
            <td><input type="hidden" name="name" value="{$name}" /><button type="submit" class="btn btn-primary" disabled="disabled">Change assign</button></td>
            </form>
        </tr>
};


declare function adminapp:assigned-free($node as node(), $model as map(*), $name as xs:string?) {
    
    let $root:=$config:data-root
    
    let $collections_toc:=$config:collections
    
    let $children := xmldb:get-child-collections($root)
    
    let $assigned:=
        for $child in $children
        let $collectionpath:=$root||'/'||$child
        let $permissions:=sm:get-permissions($collectionpath)
        return
            if(data($permissions/sm:permission/@owner)='admin' 
            and data($permissions/sm:permission/@group)=$config:editor-group 
            and $child!='temp' 
            and $child!='built'
            and $child!='messages'
            and $child!='published'
            ) then $child else()
            
            (:if(data($permissions/sm:permission/@owner)='admin') then $child else ():)
        
    return
        if(count($assigned)=0) then <p class="lead text-center">All collections are assigned</p> 
        else

        for $partizione in $assigned
        (:let $query:= concat("doc('",$prod_root,"/",$partizione,"/",$partizione,".1.xml')//REG-ORIG"):)
        let $collectionpath:=$root||'/'||$partizione
        let $permissions:=sm:get-permissions($collectionpath)
        return
        <tr>
            <form id="{$name}{$partizione}_assign" action="assign.xql" method="POST" class="form">
            <td><input type="checkbox" id="{$partizione}" name="id" value="{$partizione}"/></td>
            <td class="owner_{data($permissions/sm:permission/@group)}">{$partizione}</td>
            <td>{ let $collections:=$config:collections
                                        for $collection in $collections/collection
                                            where $collection/id=$partizione
                                        return
                                            $collection/ctitle
                                    }</td>
            <td><input type="hidden" name="name" value="{$name}" /><button type="submit" class="btn btn-primary" disabled="disabled">Assign</button></td>
            </form>
            <!--td>{data($permissions/sm:permission/@owner)}</td>
            <td>{data($permissions/sm:permission/@group)}</td>
            <td>{data($permissions/sm:permission/@mode)}</td-->
        </tr>
};

declare function adminapp:collection-build-button($node as node(), $model as map(*)){
       let $root:=$config:data-root

        let $id := request:get-parameter("id", ())  
       
        
        let $cpath:=$root||'/'||$id
        let $owner:=xmldb:get-owner($cpath)
    
    return
        if($owner!='admin')
        then(<span>Collection not released</span>)
        else (
        <a class="btn btn-warning collection_build" href="build.html?id={$id}">Released > Build</a>
        )
};

declare function adminapp:collection-build($node as node(), $model as map(*)){
    let $root:=$config:data-root
    let $built-root:=$config:built-root
    
    let $collections:=$config:collections

    let $id := request:get-parameter("id", ())  
       
    let $cpath:=$root||'/'||$id
    let $bpath:=$built-root||'/'||$id
        
    let $owner:=xmldb:get-owner($cpath)
  
    let $remove-old-collection:=if(collection($bpath)) then (xmldb:remove($bpath)) else ()
  
    let $cp:=xmldb:copy($cpath, $built-root)
    
    let $documents := xmldb:get-child-resources($bpath)
    
    (:Get Metadata:)
    let $publicationStmt:=mainapp:join-publicationStmt($id)
    
    let $main_editor:=adminapp:join-mainEditor($id)

    let $main_source:=adminapp:join-mainSource($id)

    let $parse-documents:=for $document in $documents
        let $dpath:=$bpath||'/'||$document
        let $basequery:=concat("doc('",$dpath,"')")
        
        let $q:=util:eval($basequery) 
        (:Join Metadata:)
        let $me:=update insert $main_editor into $q//titleStmt

        let $ms:=update insert $main_source into $q//listBibl
        
        let $ps:=update insert $publicationStmt following $q//titleStmt
        let $li:=update insert adminapp:joinLicence() into $q//publicationStmt
        
        (:Correzione dell'errore in noteStmt
        Queste operazioni ora sono in questo build, devono essere spostate/corrette nella generazione
        del documento da parte dell'editor e deve quindi essere corretto il validatore
        1) Se count(noteStmt/*)>0
        :)
        let $ntst:=if (count($q//noteStmt/*)>0) then (
            update insert <notesStmt>{$q//noteStmt/*}</notesStmt> following $q//publicationStmt
            )
            else (update insert <notesStmt/> following $q//publicationStmt)
        (:
        2) Cancella noteStmt che è sbagliato :)    
        let $delntst:= update delete $q//noteStmt
        
        (:3) Cancella il nuovo tag notesStmt se è vuoto :) 
        let $delnotesStmt:=if (count($q//notesStmt/*)=0) then (
            update delete $q//notesStmt
            ) else ()
    
        (:Add Namespace and remove empty elements:)
        let $teidoc:=mainapp:addNamespaceToXML($q/TEI, "http://www.tei-c.org/ns/1.0")
        let $teidoc:=mainapp:replace-elements($teidoc)
    
        (:Remove and restore the new file with namespace:)
        let $remove-old-file:=xmldb:remove($bpath, $document)
        let $store-new:=xmldb:store($bpath, $document, $teidoc)
        
        
        (:Check body:)
        (:let $ndocument := doc($bpath||'/'||$document)
        let $is_body:=$ndocument//tei:body/tei:div/*
        let $body_check:=if($is_body) then () else (update insert <tei:div type="empty"/> into $ndocument//tei:body):)
        
        return 
            <p>{$document}</p>
            
    let $update_collection_status:=update value $collections/collection[@id=$id]/status with 'built'        
    return
        response:redirect-to(xs:anyURI('collections_built.html'))
};



declare function adminapp:join-mainEditor($id) {
    let $collections:=$config:collections

    for $collection in $collections/collection
    where $collection/id=$id
    return
        <respStmt>
            <resp>main editor</resp>
            <name>{$collection/main_editor/text()}</name>
        </respStmt>
};


declare function adminapp:join-mainSource($id) {
    let $collections:=$config:collections

    for $collection in $collections/collection
    where $collection/id=$id
    return
        <bibl type="main_source">{$collection/main_source/text()}</bibl>
};

declare function adminapp:joinLicence(){
    let $a:='b'
    return
        <availability>
            <licence target="http://creativecommons.org/licenses/by-nc-sa/4.0/"> Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)</licence>
        </availability>    
    
};

declare function adminapp:collections-built($node as node(), $model as map(*)){
    
    let $built-root:=$config:built-root
    
    let $res:=if(xmldb:collection-available($built-root)=true())then(
    let $children := xmldb:get-child-collections($built-root)
    
    
     for $child in $children
   
   (:let $coll:=concat($root,"/",$child)
    let $consistenza:=count(collection($coll))
    let $from:=browse:collection-from(util:eval($query))
    order by $child ascending:)
    return
        <tr>
            <td class="collection-id-column">{$child}</td>
            <!--td><a class="collection-title" href="collection.html?id={$collection/id}">{$collection/ctitle}</a></td>
            <td>{$collection/docnum}</td>
            <td>{$collection/from}</td>
            <td>{$collection/to}</td-->
            <td>
                <div class="actions">
                <a class="btn btn-primary btn-sm validate_built_collection" href="validate_built_collection.html?id={$child}">Validate</a>
                <a class="btn btn-success btn-sm publish_built_collection" href="publish_built_collection.html?id={$child}">Publish</a>
                <!--a class="btn btn-primary btn-sm" href="collection_form.html?id={$collection/id}">Metadata</a>
                {app:status-button($collection/id)}
                -->
                </div>
            </td>
        </tr>   
        )
        else
            ()
    return
        $res
};

declare function adminapp:validate-built-collection($node as node(), $model as map(*)){
    let $built-root:=$config:built-root
    let $id := request:get-parameter('id', '')
    let $x:="y"
    
    let $cpath:=$built-root||'/'||$id
    let $resources := xmldb:get-child-resources($cpath)
    
    let $docs:=for $resource in $resources
                order by $resource ascending
                return
                    <p>{adminapp:validate-built-document($id,$resource)}</p>
    
    return
        <div>
            <p>Collection: {$id}</p>
            <div>
            {$docs}
            </div>
        </div>
    
};

declare function adminapp:validate-built-document($id as xs:string,$docid as xs:string){
    (:Z - And finally the validation process:)
    let $built-root:=$config:built-root
    
    let $document := doc($built-root||'/'||$id||'/'||$docid)
    
    (:let $ns:=functx:namespaces-in-use($document):)
    
    let $root:=$config:data-root
    let $schema := doc($root||'/tei_all.xsd')
    
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
        <div>{$docid}:
        <span class="{$status_class}" style="margin-right:20px; text-transform:uppercase"><strong>{$validation//status}</strong></span> 
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

declare function adminapp:publish-built-collection($node as node(), $model as map(*)){
    let $published-root:=$config:published-root
    let $built-root:=$config:built-root
    let $sites-root:=$config:sites
    let $id := request:get-parameter('id', '')
    let $status:=adminapp:collection-status($id)
    
    let $published-site-path:=$sites-root||'/'||$id
    
    let $published_db_path:=$config:sites||"/"||$id||"/data"
    
    let $res:=
        if(xmldb:document($published-root||'/'||$id||'.xml')//default_lang) then(
                <div><p>Collection and website configured you can:</p>
                    <div class="btn-group-vertical">
                        <a class="btn btn-info" href="site_publish_form.html?id={$id}"><i class="fa fa-gear"></i> Configure</a>
                        <a class="btn btn-success" href="site_publish_run.html?id={$id}"><i class="fa fa-sitemap"></i> Publish entire site</a>
                        { if(xmldb:collection-available($published_db_path)=true()) 
                        then(
                            <a class="btn btn-danger" href="site_publish_upgrade_db.html?id={$id}"><i class="fa fa-database"></i> Upgrade only xml-db</a>
                            )
                        else()
                        }
                    </div>
                </div> 
            ) else (
                <div><p>Collection built but website not configured:</p>
                    <div class="btn-group-vertical">
                        <a class="btn btn-info" href="site_publish_form.html?id={$id}"><i class="fa fa-gear"></i> Configure</a>
                    </div>
                </div>
            )
    
    return
        <div>
        <p>What'sabout: {$id}</p>
        <p>Status:{$status}</p>
        <div>
            {$res}
        </div>
        </div>
};


declare function adminapp:site-get-menu-structure($node as node(),$model as map()){
    let $s:=$adminapp:structure
    return
        $s
};

declare function adminapp:site-model($node as node(), $model as map(*)){
    let $built-root:=$config:built-root
    let $published-ledgers:=$config:published-root
    
    let $collections:=$config:collections
    
    let $sites-root:=$config:sites
    
    let $id := request:get-parameter("id", ()) 
    
    let $check_id:=if(not($id)) 
    then (response:redirect-to(xs:anyURI('collections_built.html'))) 
    else ()
    
    let $create-ledger:=if(doc($published-ledgers||"/"||$id||".xml")) then(
        'esiste'
        ) else(
            let $contents:="<site></site>"
        return
            xmldb:store($published-ledgers, $id||".xml", $contents)
            )  
    
    
    (:let $title:= mainapp:collection-title($node, $model,$id):)
    
    let $collection:= if($id) then 
        for $collection in $collections/collection
        where $collection/id=$id
        return
        $collection
        else ()
        
    let $site:=if($id) then (
        let $basequery:=concat("doc('",$published-ledgers,"/",$id,".xml')/site")
        
        let $q:=util:eval($basequery) 
        return
            $q
        ) 
        else ()
        
    
    return
       map { "id" := $collection/id, "ctitle":=$collection/ctitle, "docnum":=$collection/docnum, "from":=$collection/from, "to":=$collection/to, "type" := $collection/type, "main_editor":=$collection/main_editor, "main_source":=$collection/main_source, "publisher":=$collection/publisher, "status" := $collection/status, "default_lang":=$site/default_lang, "languages":=$site/languages, "theme":=$site/theme,"site_css":=$site/site_css/text(),"site_js":=$site/site_js/text(),"logo" := $site/logo, "favicon":=$site/favicon,"title":=$site/meta/title, "keywords" := $site//keywords, "description" := $site//description,'order':=$site/order, "pages":=$site/pages,"footer":=$site/footer  } 
    
};

declare function adminapp:site-header($node as node(),$model as map(*)){
    let $id:=$model('id')
    let $ctitle:=$model('ctitle')
    return
        <section class="content-header">
            <h1>
                Site publish flow: {$id}: {$ctitle}
            </h1>
        </section>
    
};

declare function adminapp:site-ajax-settings($node as node(), $model as map(*)){
    let $ordered_pages:=for $pg in $model('order') return $pg/item
    let $ctitle:=$model('ctitle')
    let $languages:= for $lang in $model('languages') return $lang
    return
    <div id="settings" data-id="{$model('id')}" data-ver_default_lang="{count($model('default_lang'))}" data-default_lang="{$model('default_lang')}" data-pages="{$ordered_pages}" data-languages="{$languages/lang}" data-title="{$ctitle}" />

};

declare %templates:default("type", 'text') function adminapp:site-publish-query($id as xs:string,$instance as xs:string,$type as xs:string){
    let $published-ledgers:=$config:published-root
    let $media-root:=$config:media
    
    let $path:=$published-ledgers||'/'||$id||'.xml'
    
    let $filequery:=concat("doc('",$path,"')")
    let $file:=util:eval($filequery) 
    
    let $basequery:=concat("doc('",$path,"')//",$instance)
    let $q:=util:eval($basequery) 
    

    let $value:= if($type='text')
            then (
                request:get-parameter($instance, '')
                )
            else if($type='file')
            then (
                let $store:=xmldb:store($media-root, $id||"_"||request:get-uploaded-file-name($instance), request:get-uploaded-file-data($instance))
                return
                $id||"_"||request:get-uploaded-file-name($instance)
            )
            else ()
            
    
    
    let $p:=if(count($q)=0) then 
    (   update insert element {$instance} {$value} into $file/site
        ) 
    else (
        update value $q with $value
        )
   return
       $p
};

declare function adminapp:site-publish-response($node as node(), $model as map(*)){
    let $id := request:get-parameter("id", ())
    
    let $built-root:=$config:built-root
    let $bpath:=$built-root||'/'||$id
    

    
    let $spath:=$config:sites||"/"||$id
    
    
    let $step := request:get-parameter("step", ())
    
    let $langsNotDefault:=adminapp:site-publish-getlangsNotDefault($id)
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    
    let $steps:=
        if($step='one') 
        then(
            <div>
                {adminapp:step-one($id)}
            </div>
            )
        else if ($step='two')
        then (
        <div>    
            {adminapp:step-two($id)}
        </div>
        )
        else if ($step='three')
        then (
        <div> 
            {adminapp:step-three($id)}
        </div>
        )
        else if ($step='four')
        then (
        <div> 
            {adminapp:step-four($id)}
        </div>
        )
        else if ($step='five')
        then (
        <div> 
            {adminapp:step-five($id)}
        </div>
        )
        else if ($step='six')
        then (
        <div> 
            {adminapp:step-six($id)}
        </div>
        )
        else if ($step='seven')
        then (
        <div> 
            {adminapp:step-seven($id)}
        </div>
        )  
        else if ($step='eight')
        then (
        <div> 
            <p class="lead">Success: <a href="../sites/{$id}" target="_blank">View Site</a></p>
            <img src="../resources/img/spider.png" />
            
        </div>
        ) 
        else ()    
    
    return
        <div>
            
            <p>{$steps}</p>
        </div>
};

declare function adminapp:steps-detail-button($step){
    <button class="btn btn-primary btn-sm" data-toggle="collapse" data-target="#step-{$step}-details">Details</button>
    
};

(: Step one: make backup and create directories :)
declare function adminapp:step-one($id as xs:string){
    (:Make backup :) 
    let $backup:= if(adminapp:site-publish-backupold($id)) then ("Backup the old site")
        else ("Instantiate a new site")
        
    let $root:= if(xmldb:create-collection($config:sites,$id)) then ("Create site root "||$id) else ("Can't create site root"||$id)    
    
        
    return
        <div>
            <p>1) Make backup and site structure {adminapp:steps-detail-button('one')}</p>
            <div id="step-one-details" class="collapse">
                <ul>
                    <li>{$backup}</li>
                    <li>{$root}
                        <ul>
                        {adminapp:site-publish-directories($id)}
                        </ul>
                    </li>
                </ul>
            </div>
        </div>
};

(: Step 2 add assets :)
declare function adminapp:step-two($id as xs:string){
    let $published-root:=$config:published-root
    let $siteConfigPath:=$published-root||'/'||$id||'.xml'
    let $siteXml:=doc($siteConfigPath)/site
    
    let $theme:=$siteXml/theme/text()
    let $themesPath:=$config:themes||"/"||$theme
    let $bootswatchPath:=$config:assets||"/bootswatch"
    let $boostrapPath:=$config:assets||"/bootstrap"
    let $jqueryPath:=$config:assets||"/jquery"
    let $toolsPath:=$config:assets||"/tools"
    let $pluginsPath:=$config:assets||"/plugins"
    let $fontsPath:=$config:assets||"/fonts"   
    let $xqueryLibsPath:=$config:assets||"/xquery_libs"   
    
    let $cssPath:=$config:sites||"/"||$id||"/css"
    let $jsPath:=$config:sites||"/"||$id||"/js"
    let $jsPluginsPath:=$config:sites||"/"||$id||"/js/plugins"
    let $siteFontsPath:=$config:sites||"/"||$id||"/fonts"
    
    
    return
        <div>
            <p>2) Add assets {adminapp:steps-detail-button('two')}</p>
            <div id="step-two-details" class="collapse">
            <ul>
                <li>{if(xmldb:copy($themesPath, $cssPath,'bootstrap.css')) then ("Don't add") else ("Add")} Bootswatch bootstrap.css</li>
                <li>{if(xmldb:copy($bootswatchPath, $cssPath,'custom.min.css')) then ("Don't add") else ("Add")} Bootswatch custom.min.css</li>
            </ul>
            <ul>
                <li>{if(xmldb:copy($boostrapPath, $jsPath,'bootstrap.min.js')) then ("Don't add") else ("Add")} Bootstrap bootstrap.min.js</li>
                <li>{if(xmldb:copy($jqueryPath, $jsPath,'jquery.min.js')) then ("Don't add") else ("Add")} jQuery jquery.min.js</li>
                <li>{if(xmldb:copy($bootswatchPath, $jsPath,'custom.js')) then ("Don't add") else ("Add")} Bootswatch custom.js</li>
            </ul>
            <ul>
                {let $tools:=distinct-values($siteXml//tool)
                    for $tool in $tools
                    
                    return
                        <li>{if(xmldb:copy($toolsPath, $jsPath,$tool||'.js')) then ("Don't add ") else ("Add ")} {$tool}</li>
                }
            </ul>
            <ul>
                {
                let $plugins:=xmldb:get-child-resources($pluginsPath)
                for $plugin in $plugins
                return
                    <li>{if(xmldb:copy($pluginsPath, $jsPluginsPath,$plugin)) then ("Don't add ") else ("Add ")} {$plugin}</li>
                }
            </ul>
            <ul>
                <li>Add fonts</li>
                {
                let $fonts:=xmldb:get-child-resources($fontsPath)
                for $font in $fonts
                return
                    xmldb:copy($fontsPath, $siteFontsPath,$font)
                }
            </ul>
            </div>
        </div>
};

(: Step 3 add xquery libraries and templates and config.xqm :)
declare function adminapp:step-three($id as xs:string){
    let $xqueryLibsPath:=$config:assets||"/xquery_libs" 
    let $xqueryControllerPath:=$config:assets||"/xquery_controller"

    let $xqueryTplPath:=$config:assets||"/xquery_templates"  
    let $xqueryConfigModulePath:=$config:assets||"/xquery_config_module"
    
    (:let $xqueryConfigModule:=util:binary-doc($xqueryConfigModulePath||"/config.xqm"):)
    let $sitePath:=$config:sites||"/"||$id 
    let $siteModulesPath:=$config:sites||"/"||$id||"/modules"
    let $siteTplPath:=$config:sites||"/"||$id||"/templates"
    return
        <div>
            <p>3) Add xquery modules, libraries and templates {adminapp:steps-detail-button('three')}</p>
            <div id="step-three-details" class="collapse">
            <ul>
                <li>Add controller.xql, collection.xconf and error_page.html to site root</li>
                {
                let $controllers:=xmldb:get-child-resources($xqueryControllerPath)
                for $controller in $controllers
                 
                return
                    xmldb:copy($xqueryControllerPath, $sitePath,$controller)
                }
                {xmldb:chmod-resource($sitePath, "controller.xql",  util:base-to-integer(0755, 8))}
            </ul>
            <ul>
                <li>Add xql files to site /modules</li>
                {
                let $libs:=xmldb:get-child-resources($xqueryLibsPath)
                for $lib in $libs
                let $copy:=xmldb:copy($xqueryLibsPath, $siteModulesPath,$lib)
                return
                    xmldb:chmod-resource($siteModulesPath,$lib,util:base-to-integer(0755, 8))
                }
                
            </ul>
            <ul>
                <li>Add html template files to site /templates </li>
                {
                let $tpls:=xmldb:get-child-resources($xqueryTplPath)
                for $tpl in $tpls
                return
                    xmldb:copy($xqueryTplPath, $siteTplPath,$tpl)
                }
            </ul> 
            </div>
        </div>
};

(: Step 4 add Database :)
declare function adminapp:step-four($id as xs:string){
    let $builtDbPath:=$config:built-root||"/"||$id
    let $siteDbPath:=$config:sites||"/"||$id||"/data"
    return
    <div>
        <p>4) Add Database</p>
        {
        let $files:=xmldb:get-child-resources($builtDbPath)
        for $file in $files
        return
            xmldb:copy($builtDbPath, $siteDbPath,$file)
        }
    </div>
};

(: Step 5 add Images :)
declare function adminapp:step-five($id as xs:string){
    let $published-root:=$config:published-root
    let $siteConfigPath:=$published-root||'/'||$id||'.xml'
    let $siteXml:=doc($siteConfigPath)/site
    
    
    let $langpath:=$config:assets||"/lang"
    let $imgpath:=$config:sites||"/"||$id||"/images"
    
    let $langs:=adminapp:site-publish-getlangs($id)
    let $lang:=for $lang in $langs
                return
                    xmldb:copy($langpath, $imgpath,$lang||'.png')
        
    (: Useless all images has the id as prefix
    let $logo:=$siteXml/logo/text()
    let $favicon:=$siteXml/favicon/text()    
    let $copyfavicon:=xmldb:copy($config:media, $imgpath,$favicon)
    let $copylogo:=xmldb:copy($config:media, $imgpath,$logo):)        
    
    let $images:=xmldb:get-child-resources($config:media)
    
    return
    <div>
        <p>5) Add images {adminapp:steps-detail-button('five')}</p>
        <div id="step-five-details" class="collapse">
        <ul>
            <li>Copy Flags</li>
            <li>Copy logo, favicon and all site images: 
                {for $img in $images
                where starts-with($img,$id)
                return
                    xmldb:copy($config:media, $imgpath,$img)
                }
                <ul>{
                for $img in $images
                where starts-with($img,$id)
                return
                    <li>{$img}</li>
                }</ul>
            </li>
        </ul>
        </div>
    </div>
};

declare function adminapp:step-six($id as xs:string){    
    <div>
        <p>6) Add pages {adminapp:steps-detail-button('six')}</p>
        <div id="step-six-details" class="collapse">
        {adminapp:site-publish-makePages($id)}
        </div>
    </div>
};

declare function adminapp:step-seven($id as xs:string){
    let $path:=$config:sites||"/"||$id
    return
    <div>
        <p>7) Lucene Indexes {adminapp:steps-detail-button('seven')}</p>
        <div id="step-seven-details" class="collapse">
        <ul>
            <li>Edit collection.xconf</li>
            <li>{adminapp:site-config-updateXconf($id)}
        Reindex the collection: {adminapp:collection-reindex($path)}</li>
        </ul>
        </div>
    </div>
};

declare function adminapp:collection-reindex($collection){
(:  :let $collection := request:get-parameter("collection", ())
let $xconf := request:get-parameter("config", ()):)
let $xconf := "collection.xconf"
let $target := "/db/system/config" || $collection
return
    if (xmldb:is-admin-user(xmldb:get-current-user())) 
    then
    (
       try {
            (
                <response json:literal="true">true</response>,
                if (not(starts-with($collection, "/db/system/config/"))) then (
                    adminapp:mkcol("/db/system/config", $collection),
                    let $config := doc($collection || "/" || $xconf)
                    return
                        xmldb:store($target, $xconf, $config)
                ) else
                    ()
                   ,
                let $reindex :=
                    if (starts-with($collection, "/db/system/config")) then
                        substring-after($collection, "/db/system/config")
                    else
                        $collection
                return
                    xmldb:reindex($reindex)
                    
            )[1]
        } catch * {
            <response>
                <error>{ $err:description }</error>
            </response>
        }
        )
    else
        <response>
            <error>You need to have dba rights</error>
        </response>
};

declare function adminapp:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            adminapp:mkcol-recursive($newColl, tail($components))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function adminapp:mkcol($collection, $path) {
    adminapp:mkcol-recursive($collection, tokenize($path, "/"))
};

declare function adminapp:site-publish-backupold($id as xs:string){
    let $spath:=$config:sites||"/"||$id
    let $bpath:=$config:sitesbackup||"/"||$id
    let $backup:=if(xmldb:collection-available($spath)=true()) then (
            
            let $time:=datetime:timestamp(current-dateTime()) 
            let $bkid:= $id||"."||$time
            let $bkdir:=xmldb:create-collection($config:sitesbackup,$bkid)
            let $mv:=xmldb:move($spath, $bkdir)
            (:let $rn:=xmldb:rename($bpath, $bkid):)
            return
                $bkdir
            )
        else()    

    return
        $backup
};

declare function adminapp:site-publish-directories($id as xs:string){
    let $dirs:=('config','css','data','fonts','images','js','js/plugins','modules','templates')
    let $basePath:=concat($config:sites,"/",$id)

    for $dir in $dirs
    let $path:=tokenize($dir, '/')
    let $container:= 
        if(contains($dir, '/')) then (
            concat($basePath,'/',$path[1])
        )
        else (
             $basePath
        )
    let $newdir:=if(contains($dir, '/')) then (  
            $path[2]
        )
        else (
             $dir
        )
        
    return
        <li>{if(xmldb:create-collection($container,$newdir)) then ("Create dir") else ("Can't create")}: {$container}/{$newdir}</li>
};

declare function adminapp:site-publish-getdefaultlang($id as xs:string){
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    let $siteXml:=doc($path)/site
    return
       $siteXml/default_lang 
};

declare function adminapp:site-publish-getlangs($id as xs:string){
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    let $siteXml:=doc($path)/site
    return
       $siteXml/languages/lang 
};

declare function adminapp:site-publish-getlangsNotDefault($id as xs:string){
    let $langs:=adminapp:site-publish-getlangs($id)
    let $default:=adminapp:site-publish-getdefaultlang($id)
    
    (:let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site:)

    for $lang in $langs
    where not($lang/text()=$default/text())
    return
       $lang 
};

declare function adminapp:site-publish-makePages($id as xs:string){
    
    
    
    let $spath:=$config:sites||"/"||$id
    
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    let $siteLanguages:=adminapp:site-publish-getlangsNotDefault($id)
    let $allSiteLanguages:=adminapp:site-publish-getlangs($id)
    
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site
    
    let $siteJs:=$siteXml/site_js/text()
    
    let $logo:=$siteXml/logo/text()

    return
        <div>
        <ul>
            <li><b>Id</b>,<b>Lang</b>,<b>File</b></li>
        {
        let $langs:=
            for $lang in $allSiteLanguages
            return
                for $page in $siteXml/pages/page
                let $baseFilename:=if($page/name='homePage') then ('index') else ($page/name)
                let $langExt:=if($lang ne $defaultLang) then (concat(".",$lang)) else ()
                let $fname:=concat($baseFilename,$langExt,".html")
                let $html:=adminapp:site-publish-makeHtml($id,$lang,$fname,$page)
                    
                let $saved:=xmldb:store($spath, $fname, $html)
                
                return
                <li>{$id}, {$lang}, {$fname}</li>
        return
            $langs
            
        }</ul>
        
        </div>
};

declare function adminapp:site-publish-makeHtml($id as xs:string,$lang as xs:string,$filename as xs:string,$page){
    <html lang="{$lang}">
        {adminapp:site-publish-makeHead($id,$lang)}
        {adminapp:site-publish-makeBody($id,$lang,$filename,$page)}
    </html>
};

declare function adminapp:site-publish-makeHead($id as xs:string,$lang as xs:string){
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site
    let $siteCss:=$siteXml/site_css/text()
    let $meta:=$siteXml/meta
    return
    <head>
        <title>{$meta/title[@lang=$lang]/text()}</title>
        <meta charset="UTF-8"/>
        <meta name="description" content="{$meta/description[@lang=$lang]}"/>
        <meta name="keywords" content="{$meta/keywords[@lang=$lang]}"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <link rel="shortcut icon" href="images/{$siteXml/favicon/text()}" />
        <!--Add CSS and JS: bootstrap & jquery & more-->
        <!--CSS-->
        <!--bootstrap themed by bootswatch-->
        <link rel="stylesheet" type="text/css" href="css/bootstrap.css" />
        <link rel="stylesheet" type="text/css" href="css/custom.min.css" />
        {if($siteCss) then(
            <style>
                {$siteCss}
            </style>)
            else ()
        }
    </head>
};

declare function adminapp:site-publish-makeBody($id as xs:string,$lang as xs:string,$filename as xs:string,$page){
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site
    let $logo:=$siteXml/logo/text()
    let $title:=$page/pagetitle[@lang=$lang]/text()
    return
    <body>
        {adminapp:site-publish-makeNavbar($id, $lang,$filename)}
        <div class="container">
            <div class="main-container">
            {adminapp:site-publish-makeJumbotron($logo,$title,$page/name)}
            {adminapp:site-publish-makeContent($id,$lang,$page)}
            </div>
        {adminapp:site-publish-makeFooter($id,$lang)}
        </div>
        {adminapp:site-publish-makeAssets($id,$lang,$page)}
    </body>    
    
};

declare function adminapp:site-publish-makeNavbar($id, $lang,$filename){
    <div class="navbar navbar-default navbar-fixed-top">
        <div class="container">
            <div class="navbar-header">
                <button class="navbar-toggle" type="button" data-toggle="collapse" data-target="#navbar-main">
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
            </div>
            <div class="navbar-collapse collapse" id="navbar-main">
                {adminapp:site-publish-makeMenu($id,$lang,$filename)}
                {adminapp:site-publish-makeLanguageBox($id,$lang,$filename)}
            </div>
        </div>
    </div> 
};


declare function adminapp:site-publish-makeMenu($id as xs:string,$lang as xs:string,$filename as xs:string){
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site
    
    
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    
    let $order:=$siteXml/order
    let $menuitems:= for $item in $order/item
                    let $fname:= if($item='homePage') then ('index') else ($item)
                    let $label:= $siteXml/pages/page/label[@lang=$lang][../name=$item/text()]
                   
                    let $link:=if($lang eq $defaultLang) 
                            then ($fname) 
                            else ($fname||"."||$lang)
                    
                    return
                    <li><a href="{$link}.html">{$label}</a></li>
    return
        <ul class="nav navbar-nav">
            {$menuitems}
        </ul>
};

declare function adminapp:site-publish-makeLanguageBox($id as xs:string,$lang as xs:string,$filename as xs:string){
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $filename:=tokenize($filename,"\.")
    let $basefilename:=$filename[1]
    
    let $siteLanguages:=adminapp:site-publish-getlangs($id)
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    let $siteLanguagesNotDefault:=adminapp:site-publish-getlangsNotDefault($id)
    return
        <ul class="nav navbar-nav navbar-right">
        {   if (count($siteLanguages)>1)
            then (
                <li><a href="{$basefilename}.html"><img src="images/{$defaultLang}.png"/></a></li>,
                for $lang in $siteLanguagesNotDefault
                return
                    <li><a href="{$basefilename}.{$lang}.html"><img src="images/{$lang}.png"/></a></li>
                )
            else ()
        }
        </ul>
};

declare function adminapp:site-publish-makeContent($id as xs:string,$lang as xs:string ,$page){
let $controller:=$page/name
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site
    
    
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    
    let $blocks:= $page/content
            (:if($siteXml/pages/page[@lang=$lang]/content/*[../../name=$page/name]) 
            then ($page/content/*)
            else ($siteXml/pages/page[@lang=$defaultLang]/content/*[../../name=$page/name]):)
    
    
    (:let $controller2:=if($page/name/content) then ($page/content/*) else ($page/content/*)    
    let $parsedPage:= adminapp:functx-change-element-names-deep($page/content, xs:QName('paragtitle') ,xs:QName('h3')):)
    
    (:let $parsedPage:=replace($page/content,"&amp;nbsp;"," ")
    let $parsedPage:=replace($parsedPage,"br&gt;", "br/&gt;") 
    
    let $parsedPage:=parse-xml-fragment(replace($parsedPage,"&amp;nbsp;"," "))
    
    let $parsedPage:= adminapp:functx-change-element-names-deep( $parsedPage, xs:QName('textarea') ,xs:QName('div'))
    :)
    
    
    
    (:let $parsedPage:= adminapp:functx-change-element-names-deep( $parsedPage, xs:QName('table') ,xs:QName('div')):)
    
 return   
    
       
        <div id="main-section" class="section">
        
            {
            if($controller eq 'browse') then (
                let $browse_conf:=adminapp:site-publish-makeBrowseConfig($id)
                let $browse_by:=adminapp:site-publish-makeBrowseByPage($id,$lang)
                let $document:=adminapp:site-publish-makeDocumentPage($id,$lang)
                return
                    adminapp:site-publish-browseInterface()

                
                )
            else if ($controller eq 'browse_by') then (
                adminapp:site-publish-browseByInterface()
                ) 
            else if ($page/name eq 'search') then (
                let $searchres:=adminapp:site-publish-makeSearchResPage($id,$lang)
                return
                adminapp:site-publish-searchForm($id,$lang)
                ) 
            else if ($page/name eq 'searchres') then (
                adminapp:site-publish-searchResInterface()
                )
            else if ($page/name eq 'document') then (
                adminapp:site-publish-documentInterface()
                )    
            else(
            for $token at $seq in $blocks/block/*
            return
                if(name($token)='paragtitle') 
                   then (
                       if($token[@lang=$lang]) then (
                       adminapp:site-publish-parse-paragtitle($token[@lang=$lang]/text())
                       )
                       else ()
                       )
                   else if(name($token)='textarea') 
                   then (
                       if($token[@lang=$lang]) then (
                       adminapp:site-publish-parse-textarea($token[@lang=$lang])
                       )
                       else ()
                       )
                    else if(name($token)='table')   
                    then (
                        if($token[@lang=$lang]) then (
                        adminapp:site-publish-parse-table($token[@lang=$lang]/text())
                        )
                        else()
                        ) 
                    else if(name($token)='citation')   
                    then (
                        <div class="citation row">
                            <div class="citkey col-md-2">{$token//citkey/text()}</div>
                            <div class="cititem col-md-10">{$token//cititem/text()}</div>
                        </div>
                        )
                    else ()    
                    (:else (<div>{$token}</div>):)
            )    

            }
        </div>
};

declare function adminapp:site-publish-parse-paragtitle($token){
    <h3 class="paragtitle">{$token}</h3>
};

declare function adminapp:site-publish-parse-textarea($token){
    let $token:=replace($token, 'img src="../resources/', 'img src="')
    return
        <div class="section">{util:parse-html($token)}</div>
};

declare function adminapp:site-publish-parse-table($token){
    <div class="json2Table">{$token}</div>
};

declare function adminapp:site-publish-makeBrowseConfig($id as xs:string){
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    
    let $sitePath:=$config:sites||"/"||$id
    
    let $confPath:=$config:sites||"/"||$id||"/config"
    
    let $siteXml:=doc($path)/site
    
    let $originalXml:=$siteXml/pages/page//browse

    
    let $baseXml:=for $block in $originalXml
                
                return
                    <by>{for $sub in $block/*
                        return
                            if(data($sub/@lang) eq $defaultLang) 
                            then (adminapp:add-attributes($sub,xs:QName('default'), 'true'))
                            else ($sub)    
                        
                    }</by>

               
    let $conf:= <pages>
                {
                $baseXml
                }
                </pages>
    
      
    return
        xmldb:store($confPath, 'browse.xml', $conf)
                
};

declare function adminapp:site-config-updateXconf($id as xs:string){
    let $siteConf:=$config:published-root||'/'||$id||'.xml'
    let $siteXml:=doc($siteConf)/site
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    let $originalXml:=$siteXml/pages/page[@lang=$defaultLang]//browse
    
    let $browseConf:=$config:sites||"/"||$id||"/config/browse.xml"
    let $browseXml:=doc($browseConf)/pages
    
    let $sitePath:=$config:sites||"/"||$id
    let $xconf:=$sitePath||"/collection.xconf"
    let $xconfQuery:=concat("doc('",$xconf,"')")
    let $xconfDoc:=util:eval($xconfQuery) 
     
    for $element at $seq in $browseXml/*
    
    (:element {QName($tei_ns, 'new')} {''}:)
    
            let $t:=
                element{QName("http://exist-db.org/collection-config/1.0", 'text')}
                {
                if($element/lucene-index-type eq 'http://exist-db.org/collection-config/1.0') 
                then (attribute match { $element//lucene-index-query })
                else (attribute qname { $element//lucene-index-query }),
                
                if(count($element//lucene-index-analyzer/text()) ne 0) 
                then (attribute analyzer {$element//lucene-index-analyzer}) 
                else (),
                
                
                ''
                    
                }
            return
                update insert $t into $xconfDoc//cc:lucene 
    
};


declare function adminapp:functx-change-element-names-deep
  ( $nodes as node()* ,
    $oldNames as xs:QName* ,
    $newNames as xs:QName* )  as node()* {

  if (count($oldNames) != count($newNames))
  then error(xs:QName('functx:Different_number_of_names'))
  else
   for $node in $nodes
   return if ($node instance of element())
          then element
                 {adminapp:functx-if-empty
                    ($newNames[index-of($oldNames,
                                           node-name($node))],
                     node-name($node)) }
                 {$node/@*,
                  adminapp:functx-change-element-names-deep($node/node(),
                                           $oldNames, $newNames)}
          else if ($node instance of document-node())
          then adminapp:functx-change-element-names-deep($node/node(),
                                           $oldNames, $newNames)
          else $node
 } ;
 
 declare function adminapp:functx-if-empty
  ( $arg as item()? ,
    $value as item()* )  as item()* {

  if (string($arg) != '')
  then data($arg)
  else $value
 } ;

declare function adminapp:add-attributes
  ( $elements as element()* ,
    $attrNames as xs:QName* ,
    $attrValues as xs:anyAtomicType* )  as element()? {

   for $element in $elements
   return element { node-name($element)}
                  { for $attrName at $seq in $attrNames
                    return if ($element/@*[node-name(.) = $attrName])
                           then ()
                           else attribute {$attrName}
                                          {$attrValues[$seq]},
                    $element/@*,
                    $element/node() }
 } ;

declare function adminapp:add-attributes-to-node
  ( 
    $nodes as node()* ,
    $myElement,
    $attrNames as xs:QName* ,
    $attrValues as xs:anyAtomicType* )  as node()* {

    let $newnode:=for $node in $nodes
        return 
            element {node-name($node)}{
        for $element in $node/*
            return 
               if(name($element) eq name($myElement))
                then element { node-name($element)}
                  { for $attrName at $seq in $attrNames
                    return if ($element/@*[node-name(.) = $attrName])
                           then ()
                           else attribute {$attrName}
                                          {$attrValues[$seq]},
                    $element/@*,
                    $element/node() }
                else ($element)  
            }
               
    return
        $newnode
 } ;


declare function adminapp:site-publish-makeBrowseByPage($id as xs:string, $lang as xs:string){
    let $spath:=$config:sites||"/"||$id
    
    let $published-root:=$config:published-root
    
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site
    
    let $siteLanguages:=adminapp:site-publish-getlangs($id)
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    let $siteLanguagesNotDefault:=adminapp:site-publish-getlangsNotDefault($id)
    
    let $filename:="browse_by"
    
    let $page:=
                    <page>
                        <name>browse_by</name>
                {for $ln in $siteLanguages
                return
                        <label lang="{$ln}">Browse by</label>,
                for $ln in $siteLanguages
                return        
                        <pagetitle lang="{$ln}">Browse by {$ln}</pagetitle>
                }
                    </page>
                
    
    let $flang:=if($lang ne $defaultLang) then ("."||$lang) else ()
    
    let $fname:=concat($filename,$flang,'.html')
    
    (:for $page in $pages/page:)
    let $html:=adminapp:site-publish-makeHtml($id,$lang,$filename,$page)
    return
        xmldb:store($spath, $fname, $html)
};


declare function adminapp:site-publish-makeDocumentPage($id as xs:string, $lang as xs:string){
    let $spath:=$config:sites||"/"||$id
    
    let $published-root:=$config:published-root
    
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site
    
    let $siteLanguages:=adminapp:site-publish-getlangs($id)
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    let $siteLanguagesNotDefault:=adminapp:site-publish-getlangsNotDefault($id)
    
    let $filename:="document"
    
    let $page:=
                    <page>
                        <name>document</name>
                {for $ln in $siteLanguages
                return
                        <label lang="{$ln}">Document</label>,
                for $ln in $siteLanguages
                return        
                        <pagetitle lang="{$ln}">Document {$ln}</pagetitle>
                }
                    </page>
    
    let $flang:=if($lang ne $defaultLang) then ("."||$lang) else ()
    
    let $fname:=concat($filename,$flang,'.html')
    
    (:for $page in $pages/page:)
    let $html:=adminapp:site-publish-makeHtml($id,$lang,$filename,$page)
    return
        xmldb:store($spath, $fname, $html)
};

declare function adminapp:site-publish-makeSearchResPage($id as xs:string, $lang as xs:string){
    let $spath:=$config:sites||"/"||$id
    
    let $published-root:=$config:published-root
    
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site
    
    let $siteLanguages:=adminapp:site-publish-getlangs($id)
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    let $siteLanguagesNotDefault:=adminapp:site-publish-getlangsNotDefault($id)
    
    let $filename:="searchres"
    
    let $page:=
                    <page>
                        <name>searchres</name>
                {for $ln in $siteLanguages
                return
                        <label lang="{$ln}">Search</label>,
                for $ln in $siteLanguages
                return        
                        <pagetitle lang="{$ln}">Search {$ln}</pagetitle>
                }
                    </page>
    
    let $flang:=if($lang ne $defaultLang) then ("."||$lang) else ()
    
    let $fname:=concat($filename,$flang,'.html')
    
    (:for $page in $pages/page:)
    let $html:=adminapp:site-publish-makeHtml($id,$lang,$filename,$page)
    return
        xmldb:store($spath, $fname, $html)
};


declare function adminapp:site-publish-makeJumbotron($logo,$title,$pagename){
    if($pagename eq "homePage") then (
     <div class="jumbotron">
            <div class="row">
                <div class="col-md-3">
                    <img src="images/{$logo}" class="img-responsive" />
                </div>
                <div class="col-md-9">
                    <h1>{$title}</h1>
                </div>
            </div>
        </div>
    )
    else (
     <div class="jumbotron" style="padding:30px;">
            <div class="row">
                <div class="col-md-3">
                    <img src="images/{$logo}" style="max-height:120px" class="img-responsive" />
                </div>
                <div class="col-md-9">
                    <h1 style="font-size:2em">{$title}</h1>
                </div>
            </div>
        </div>   
        )
};





declare function adminapp:site-publish-makeFooter($id,$lang){
    
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    
    let $siteXml:=doc($path)/site
    
    let $columns:=if($siteXml/footer[@lang=$lang]) then ($siteXml/footer[@lang=$lang]/col)
                else ($siteXml/footer[@lang=$defaultLang]/col)
    
    (:let $columns:=$siteXml/footer[@lang=$lang]/col:)
    let $parsedCols:=for $column in $columns
        let $column:=replace($column,"&amp;nbsp;"," ")
        let $column:=replace($column,"br&gt;", "br/&gt;") 
        let $class:=12 div count($columns)
        return
            <div class="col-md-{$class}">{util:parse-html($column)}</div>
    
    return
        <footer>
            <div class="row">
            {$parsedCols}
            </div>
        </footer>
};

declare function adminapp:site-publish-makeAssets($id,$lang,$page){
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    
    let $siteXml:=doc($path)/site

    let $siteJs:=$siteXml/site_js/text()
    return
    <span>
        <!--Js Area-->&#10;
        <!--jQuery-->&#10;
        <script type="text/javascript" src="js/jquery.min.js"></script>&#10;
        <!-- Bootstrap -->&#10;
        <script type="text/javascript" src="js/bootstrap.min.js"></script>&#10;
        <!--Tools-->&#10;
        {let $tools:=$page/tools/tool
            for $tool in $tools
            let $script:=<script type="text/javascript" src="js/{$tool/text()}.js"></script>
            return
                $script
              
        }
        &#10;
        <!--Plugins-->
        {
            let $jsplpath:=$config:sites||"/"||$id||"/js/plugins"
                    
            let $plugins:=xmldb:get-child-resources($jsplpath)
                    
            for $plugin in $plugins
            let $script:=<script type="text/javascript" src="js/plugins/{$plugin}"></script>
                return
                    $script
        }
        &#10;
        <!--Custom.js-->&#10;
        <script type="text/javascript" src="js/json2Table.js"/>
        <script type="text/javascript" src="js/custom.js"></script>&#10;
        <!--Site JS-->&#10;
        {
        if($siteJs) 
            then(
            <script>
                {$siteJs}
            </script>)
            else ()
        }
    </span>
};

declare function adminapp:site-publish-documentInterface(){
<div class="templates:surround?with=templates/document.html&amp;at=document">
	<div data-template="document:document">
		<h3 class="document title">
			<span data-template="document:title"/>
		</h3>
		<p class="document date">
			<span data-template="document:date"/>
		</p>
		<p class="document identifier">
			<span data-template="document:msIdentifier"/>
		</p>
		<div class="document summary">
			<span data-template="document:summary"/>
		</div>
		<hr/>
		<div class="document text">
			<span data-template="document:protocollo"/>
			<span data-template="document:testo"/>
			<span data-template="document:escatocollo"/>
		</div>
		<hr/>
		<!--div datatemplate="document:view"/-->
	</div>
</div>

};

declare function adminapp:site-publish-browseInterface(){
    <div class="templates:surround?with=templates/browse.html&amp;at=browse">
        <div data-template="browse:browse">
            <div>
            <span data-template="browse:xconf-to-buttons"/>
            </div>
            <span data-template="browse:table"/>
        </div>
    </div>
};


declare function adminapp:site-publish-browseByInterface(){
    <div class="templates:surround?with=templates/browse_by.html&amp;at=browse_by_result">
                        <div data-template="browse:browse-by">
                            <div id="content">
                                <div class="well well-sm well-default">
                                    <p>Found: 
                                        <span class="label label-primary">
                                            <span id="hit-count" data-template="search:hit-count"/>
                                        </span>  
                                        results for 
                                        <span data-template="search:show-query"/>.
                                    </p>
                                </div>
                                <!-- results -->
                                <table data-template="browse:show-hits" data-template-per-page="5" id="results" class="table table-striped table-hover"/>
                            </div>
                        </div><!-- end of data-template=browse:browse -->
                    </div>
};

declare function adminapp:site-publish-searchResInterface(){
<div class="templates:surround?with=templates/searchres.html&amp;at=searchres">
    <div data-template="search:search">
        <div id="content">
            {adminapp:site-publish-searchInfoBox()}
            {adminapp:site-publish-searchPagination('top')}
            <table data-template="search:show-hits" data-template-per-page="5" id="results" class="table table-striped table-hover"/>
            {adminapp:site-publish-searchPagination('bottom')}
        </div>
    </div>
</div>

    
};

declare function adminapp:site-publish-searchInfoBox(){
<div class="well well-sm well-default">
    <p>Found: 
    <span class="label label-primary">
        <span id="hit-count" data-template="search:hit-count"/>
    </span>  
    results for 
    <span data-template="search:show-query"/> 
    with mode 
    <span data-template="search:show-mode"/>.
    </p>
</div>    
};

declare function adminapp:site-publish-searchPagination($position as xs:string){
<div class="pagination-{$position}">
    <div class="hidden-md hidden-lg hidden-sm">
        <ul class="pagination" data-template="search:paginate" data-template-per-page="5" data-template-max-pages="5" data-template-min-hits="5"/>
    </div>
    <div class="hidden-xs">
        <ul class="pagination" data-template="search:paginate" data-template-per-page="5" data-template-max-pages="9" data-template-min-hits="5"/>
    </div>
</div>    
};


declare function adminapp:site-publish-searchForm($id as xs:string,$lang as xs:string){
    let $defaultLang:=adminapp:site-publish-getdefaultlang($id)
    
    let $fname:=if($lang eq $defaultLang) then "searchres.html" else "searchres."||$lang||".html"
    return
    <form id="search_form" method="post" action="{$fname}" class="form form-horizontal">
        <div class="col-md-12">
            <div class="well well-sm">
                <div class="form-group">
                    <div class="col-md-12 col-xs-12">
                        <span class="input-group">
                            <input name="query" type="search" class="templates:form-control form-control" placeholder="Search String"/>
                            <span class="input-group-btn">
                                <button id="f-btn-search" type="submit" class="btn btn-primary">
                                    <span class="glyphicon glyphicon-search"/>
                                </button>
                            </span>
                        </span>
                        <input type="hidden" name="field" value="text"/>
                    </div>
                </div>
                <div class="form-group" data-toggle="tooltip" data-placement="left" title="Search Mode">
                    <div class="col-md-12 col-xs-12">
                        <select name="mode" class="form-control" data-template="templates:form-control">
                            <option value="phrase" selected="selected">Phrase Search</option>
                            <option value="any">Any Search Term</option>
                            <option value="all">All Search Terms</option>
                            <option value="near-ordered">Proximity Search (Ordered)</option>
                            <option value="near-unordered">Proximity Search (Unordered)</option>
                            <option value="fuzzy">Fuzzy Search</option>
                            <option value="wildcard">Wildcard Search</option>
                            <option value="regex">Regex Search</option>
                        </select>
                    </div>
                </div>
            </div>
        </div>
    </form>
};

declare function adminapp:functx-change-element-names-deep
  ( $nodes as node()* ,
    $oldNames as xs:QName* ,
    $newNames as xs:QName* )  as node()* {

  if (count($oldNames) != count($newNames))
  then error(xs:QName('functx:Different_number_of_names'))
  else
   for $node in $nodes
   return if ($node instance of element())
          then element
                 {adminapp:functx-if-empty
                    ($newNames[index-of($oldNames,
                                           node-name($node))],
                     node-name($node)) }
                 {$node/@*,
                  adminapp:functx-change-element-names-deep($node/node(),
                                           $oldNames, $newNames)}
          else if ($node instance of document-node())
          then adminapp:functx-change-element-names-deep($node/node(),
                                           $oldNames, $newNames)
          else $node
 } ;
 

 declare function adminapp:functx-if-empty
  ( $arg as item()? ,
    $value as item()* )  as item()* {

  if (string($arg) != '')
  then data($arg)
  else $value
 } ;


(: Check if a value or a sequence exists in site config, return an empty string if false :)
declare function adminapp:site-form-parse-data($data){
    let $mydata:=if(count($data)=0) then (let $d:='' return $d) else (let $d:=$data return $d)
    return
        $mydata
};

(: Site Structure Form :)
declare function adminapp:site-form-structure($node as node(), $model as map(*)){
    let $published-ledgers:=$config:published-root

    
    let $id:=$model('id')
    let $title:=$model('title')
   
    return
    <div style="min-height:600px">
        <form id="site_publish_form_structure" enctype="multipart/form-data" method="post" action="site_publish_form_structure.xql">
        <input name="id" type="hidden" value="{$id}"/>
        <input name="title" type="hidden" value="{$title}"/>
        <div class="text-center">
            <input class="btn btn-warning" type="submit" value="Save Structure"/>
        </div>
        <div class="tabfy" id="site_structure">
            <h3>Languages</h3>
            <div>
                <table class="table table-striped table-languages">
                    <tr><th>Language flag and code</th><th>Default Language*</th><th>Active Languages</th></tr>
                    {adminapp:site-form-structure-lang($node,$model)}
                </table>
            </div>
            <h3>Theme</h3>
            <div>
                <ul class="themes">
                {adminapp:site-form-structure-themes($node,$model)}
                </ul>
            </div>
            <h3>CSS</h3>
            <div>
                Site CSS
                <textarea id="site_css" name="site_css">{$model('site_css')}</textarea>
            </div>
            <h3>JS</h3>
            <div>
                Site JS
                <textarea id="site_js" name="site_js">{$model('site_js')}</textarea>
            </div>
            
        </div>

        </form>
    </div>    
    
};

declare function adminapp:site-form-structure-lang($node as node(),$model as map(*)){
    let $default_lang:=adminapp:site-form-parse-data($model('default_lang'))
    let $languages:=$model('languages')
    
    let $lang-icons-path:=$config:app-root ||"/resources/assets/lang"
    let $langs := xmldb:get-child-resources($lang-icons-path)
    let $lang:= for $lang-icon in $langs
                let $lang:=	replace($lang-icon, '.png', '')
                let $radio:=if($default_lang=$lang) 
                        then(<input type="radio" value="{$lang}" name="default_lang" checked="checked" required="required"/>)
                        else(<input type="radio" value="{$lang}" name="default_lang" required="required" />)
                
                let $checkbox:=if (index-of($languages/lang, $lang)) 
                        then(<input type="checkbox" value="{$lang}" checked="checked" name="languages[]"/>)
                        else(<input type="checkbox" value="{$lang}" name="languages[]"/>)        
                        
                order by $lang ascending
                return
                    <tr>
                        <td><img src="../resources/assets/lang/{$lang-icon}" /> - {$lang}</td>
                        <td>{$radio}</td>
                        <td>{$checkbox}</td>
                    </tr>
    return
        $lang
    
};

declare function adminapp:site-form-structure-themes($node as node(), $model as map(*)){
    
    let $in_use_theme:=$model('theme')
    
    let $themes := xmldb:get-child-collections($config:themes)
    
    let $theme:= for $theme in $themes
                let $radio:= if($theme=$in_use_theme) 
                            then(<input type="radio" id="bootswatch_{$theme}" checked="checked" value="{$theme}" name="theme" />)
                            else(<input type="radio" id="bootswatch_{$theme}" value="{$theme}" name="theme" />)
                where $theme!="fonts"
                order by $theme ascending
                return
                    <li>{$radio}
                        <label for="bootswatch_{$theme}"><img src="../resources/assets/bootswatch/{$theme}/thumbnail.png" /></label>
                    </li>
    
    return
        $theme
};

(: Site Contents form :)
declare function adminapp:site-form-content($node as node(), $model as map(*)){
    
    let $id:=$model('id')
    let $title:=$model('title')
    return
    <div style="min-height:600px">
       
        <form id="site_publish_form_content" enctype="multipart/form-data" method="post" action="site_publish_form_content.xql">
            <div class="text-center">
                <input class="btn btn-success" type="submit" value="Save Contents"/>
            </div>
            <input name="id" type="hidden" value="{$id}"/>
            <input name="title" type="hidden" value="{$title}"/>
            <div class="tabfy" id="site_structure">
                <h3>Metadata</h3>
                {adminapp:site-form-content-metadata-tab($node,$model)}
                <h3>Pages</h3>
                <div><div id="site-form-content-pages-tab"></div></div>
                <h3>Footer</h3>
                {adminapp:site-form-content-footer-tab($node,$model)}
            </div>    
        </form>
    </div>    
    
};

declare function adminapp:site-form-content-lang-navigator($node as node(),$model as map(*),$prefix){
    let $lang-icons-path:=$config:app-root ||"/resources/assets/lang"
    let $langs := xmldb:get-child-resources($lang-icons-path)
    
    let $default_lang:=$model('default_lang')
    let $languages:=$model('languages')
    
    
    let $languages_a:=for $lang in $languages/lang
                let $def:=if($lang=$default_lang) then(<span style="margin-left:5px" class="glyphicon glyphicon-asterisk"/>) else ('')
                let $active:=if($lang=$default_lang) then('active') else ('')
                order by $lang ascending
                return
                    <a href="#{$prefix}_{$lang}" data-target="homePage" data-lang="{$lang}" class="btn btn-flat btn-default {$lang}"><img src="../resources/assets/lang/{$lang}.png" />{$def}</a>
    
    return
        <div class="btn-group language_nav">{$languages_a}</div>

};
(: Metadata Tab :)
declare function adminapp:site-form-content-metadata-tab($node as node(),$model as map(*)){
    let $id:=$model('id')
    
    let $media-root:=$config:media
    
    let $languages:=$model('languages')
    let $logo := $model('logo')
    let $favicon := $model('favicon')
    
    let $title:= $model('title')
    let $keywords:=$model('keywords')
    let $description:=$model('description')
    return
    <div>
        <div class="well">
            <div class="row">
                <div class="col-md-6">
                    <!--logo-->
                    <label cass="btn btn-primary">Logo
                    <input class="form-control" type="file" name="logo" value=""/>
                    {if($logo) then (
                        <span><p class="label-success">In use: {$logo}</p>
                        <img style="max-height:200px" src="../resources/images/{$logo}"/></span>
                        ) else ()
                    }
                    
                    </label>
                </div>
                <div class="col-md-6">
                    <!--favicon-->
                    <label cass="btn btn-primary">Favicon
                    <input class="form-control" type="file" name="favicon" value=""/>
                    {if($logo) then (
                        <span><p class="label-success">In use: {$favicon}</p>
                        <img src="../resources/images/{$favicon}"/></span>
                        ) else ()
                    }
                    </label>
                </div>
            </div>
        </div>
        <div class="panel">{adminapp:site-form-content-lang-navigator($node,$model,'metadata')}</div>
        <div id="metadata-box">
           {for $lang in $languages/lang
            let $tit:=if($title[@lang=$lang]) then ($title[@lang=$lang]) else ('')
            let $key:=if($keywords[@lang=$lang]) then ($keywords[@lang=$lang]) else ('')
            let $desc:=if($description[@lang=$lang]) then ($description[@lang=$lang]) else ('')
            return
                <div id="metadata_{$lang}" class="metadata-lang-box">
                    <p class="breadcrumb">{$id||"/metadata/"||$lang}</p>
                    <div><label class="control-label" for="sitetitle_{$lang}">Site title</label>
        <input class="form-control" name="sitetitle_{$lang}" id="sitetitle_{$lang}" value="{$tit}" />
                    </div>
                    <div>{adminapp:site-form-content-textarea($node,$model,'keywords_'||$lang,'',$key)}</div>
                    <div>{adminapp:site-form-content-textarea($node,$model,'description_'||$lang,'',$desc)}</div>
                </div>
            }
        </div>
    </div>
};

(: Pages Tab :)
declare function adminapp:site-form-content-pages-tab($node as node(),$model as map(*)){
    let $id:=$model('id')
    let $order:=$model('order')
    let $pages:=$model('pages')
    let $default_lang:=$model('default_lang')
    let $languages:=$model('languages')
    
    let $lang-icons-path:=$config:app-root ||"/resources/assets/lang"
    
    
    
    (:let $mitems:=for $mitem in $adminapp:structure
                return
                    $mitem:)
    
    let $ordered_menu:=for $ord in $order
                    return 
                        $ord/item/text()
                    
    let $plang:=for $page in $pages/page
                let $page_lang:=data($page/label/@lang)
                return
                    $page_lang
    let $plang:=distinct-values($plang)                
    

    (:let $menu_opt:=for $itm in $mitems//name
            where $itm[not(.=$order/item)]
            return
            $itm/text():)
    
    let $menu_options:= adminapp:site-form-content-pages-tab-menu-options()
                        
    let $menu_built:=adminapp:site-form-content-pages-tab-menu-built($node,$model)

    
    let $menu_select:=  <div class="menu_select">{$menu_options}{$menu_built}</div>   
    
    (:let $menu_lang:=<div class="panel">{adminapp:site-form-content-lang-navigator($node,$model,'pages')}</div>
    let $help:=adminapp:site-form-content-pages-tab-page-help($name)
    let $tools:=adminapp:site-form-content-pages-tab-page-tools($name,$lang,$pages)
    let $elements:=adminapp:site-form-content-pages-tab-page-raw-content($name,$lang,$pages)
    let $move-delete-bar:=adminapp:snippet-edit-bar($node,$model):)
 
   return
        <div>
           {$menu_select}
           {
               for $page in $pages/page
               
               (:let $titles:= for $l in $page//pagetitle
                            return
                                <p>{$l}</p>:)
                return
                    <div class="form-group page-form {$page//name}">
                    {adminapp:site-form-content-pages-tab-page-help($page//name)}
                    {adminapp:site-form-content-pages-tab-input-group($default_lang,"Menu Item",$page//name,
                        adminapp:site-form-content-pages-tab-rebuild-multilang-element($page//label,$languages)
                    )
                    }
                    {adminapp:site-form-content-pages-tab-input-group($default_lang,"Page Title",$page//name,
                        adminapp:site-form-content-pages-tab-rebuild-multilang-element($page//pagetitle,$languages)
                    )}
                    {adminapp:site-form-content-pages-tab-page-tools($page//name,$page//tools)}
                    
                        <div class="edit-area-block">
                        {adminapp:site-form-content-pages-tab-page-content-buttons($id,$page//name)}
                            <div class="edit-area">
                            {for $block in $page//content/block
                            let $rnd:=util:random()
                            let $rand:=(floor(util:random() * 10000)+1)
                            return
                            <div class="panel panel-default form-group block {name($block)||"_"||$rand}">
                                {adminapp:snippet-edit-bar($node,$model)}
                                {
                                    
                                adminapp:site-form-content-pages-tab-page-content-parsed($default_lang,$languages, $page//name,name($block/*[1]),$block/*,$rand)
                                    
                                }
                                <p class="editarea-box-title"><strong>{name($block)} -xq- {$rand}</strong></p>    
                                <div class="clearfix"></div>
                                
                            </div>
                            }
                            </div>
                        </div>
                    </div>
                    
           }
          

            
        </div>
};


declare function adminapp:site-form-content-pages-tab-page-content-parsed($default_lang,$languages, $pagename as xs:string,$type,$block,$rand){
let $deep:="content_block_"
let $parsed-block:=
                if($type='paragtitle') 
                then (
                    let $x:=adminapp:site-form-content-pages-tab-input-group($default_lang,"Paragraph Title",$pagename,
                    adminapp:site-form-content-pages-tab-rebuild-multilang-element($block,$languages),
                    $rand,$deep)
                    return
                        $x
                )
                else if ($type='textarea') 
                then (
                    let $x:=adminapp:site-form-content-pages-tab-textarea-group($default_lang,"Paragraph",$pagename,
                    adminapp:site-form-content-pages-tab-rebuild-multilang-element($block,$languages),
                    $rand,$deep)
                    return
                        $x
                ) 
                else if ($type='table') 
                then(
                    let $x:=adminapp:site-form-content-pages-tab-table-group($default_lang,"Table",$pagename,
                    adminapp:site-form-content-pages-tab-rebuild-multilang-element($block,$languages),
                    $rand,$deep)
                    return
                        $x
                )
                else if ($type='browse') 
                then(
                    let $x:=adminapp:site-form-content-pages-tab-browse-group($default_lang,$languages,"Browse by",$pagename,$block,$rand)
                    return
                        $x        
                )
                else if ($type='citation') 
                then(
                    let $x:=adminapp:site-form-content-pages-tab-citation-group($default_lang,"Citation",$pagename,$block,$rand)
                    return
                        $x        
                )   
                else ()    
return
    $parsed-block
    
};


declare function adminapp:site-form-content-pages-tab-page-tools($name as xs:string,$pagetools){
    let $templates:=$adminapp:structure//template
    let  $tools:=for $tpl in $templates
            where $tpl/name=$name
            return
                <div class="page_tools panel panel-default">
                <label>Tools:</label>
                {
                    for $tool in $tpl/tool
                    let $checkbox:=if (index-of($pagetools, $tool/text())) 
                        then(<label>
                            {$tool/text()}
                            <input type="checkbox" value="{$tool/text()}" name="page_{$name}_tools[]" checked="checked"/>
                            </label>)
                        else(<label>
                            {$tool/text()}
                            <input type="checkbox" value="{$tool/text()}" name="page_{$name}_tools[]"/>
                            </label>) 
                    return
                        $checkbox
                }</div>
    return
        $tools
};

declare function adminapp:site-form-content-pages-tab-page-content-buttons($id as xs:string,$name as xs:string){
    let $templates:=$adminapp:structure/*
    
    let $buttons:=
            for $tpl in $templates/*
            where $tpl/name=$name and $tpl/proto
            return
                <div class="template-buttons panel panel-info">
                <div class="btn-group">{
                    for $proto in $tpl/proto
                    return
                        <button class="btn btn-default page_template" data-container="page_{$tpl/name}_content_block" data-proto="{$proto}">{$proto/text()}</button>
                }</div>
                </div>
    return
        $buttons
};

declare function adminapp:site-form-content-pages-tab-rebuild-multilang-element($element,$languages){
    for $lang in $languages/lang
        return
        if(exists($element[@lang=$lang]))
        then($element[@lang=$lang])
        else (element {name($element[1])}{attribute lang {$lang}, name($element[1])||": "||$lang})
};

declare function adminapp:site-form-content-pages-tab-input-group($default_lang as xs:string,$label as xs:string,$pagename as xs:string,$element){
    
                <div class="form-group multilangInput {$pagename||name($element[@lang=$default_lang])}">
                    <label class="control-label">{$label}</label>
                    <div class="input-group defaultLang">
                        <div class="input-group-addon"><img class="defaultLangImg" src="../resources/assets/lang/{$default_lang||'.png'}"/></div>
                        <input type="text" class="form-control" name="page_{$pagename}_{name($element[@lang=$default_lang])}_{$default_lang}" value="{$element[@lang=$default_lang]}"/>
                    </div>
                    <div class="otherLangs">
                    {for $pageElem in $element[@lang ne $default_lang]
                    order by data($pageElem/@lang) ascending    
                    return
                    <div class="input-group" style="display:none">
                        <div class="input-group-addon"><img src="../resources/assets/lang/{data($pageElem/@lang)||'.png'}"/></div>
                        <input class="form-control" name="page_{$pagename}_{name($pageElem)}_{data($pageElem/@lang)}" value="{$pageElem}"/>
                    </div>
                    }
                    </div>
                </div>
    
};

declare function adminapp:site-form-content-pages-tab-textarea-group($default_lang as xs:string,$label as xs:string,$pagename as xs:string,$element,$rand,$deep){
    let $languagePills:=<ul class="nav nav-pills">
                        <li class="active"><a data-toggle="pill" href="#page_{$pagename}_{$deep}{name($element[@lang=$default_lang])}_{$default_lang}_{$rand}"><img src="../resources/assets/lang/{$default_lang||'.png'}"/></a></li>
                        {for $pageElem in $element[@lang ne $default_lang]
                    order by data($pageElem/@lang) ascending
                    return
                       <li><a data-toggle="pill" href="#page_{$pagename}_{$deep}{name($pageElem)}_{data($pageElem/@lang)}_{$rand}"><img src="../resources/assets/lang/{data($pageElem/@lang)||'.png'}"/></a></li>
                        }
                       </ul>
    return
                <div class="form-group multilangTextarea">
                    {$languagePills}
                    <div class="tab-content">
                        <div id="page_{$pagename}_{$deep}{name($element[@lang=$default_lang])}_{$default_lang}_{$rand}" class="tab-pane fade in active">
                        <textarea class="content-textarea saved nest defaultLang" name="page_{$pagename}_{$deep}{name($element[@lang=$default_lang])}_{$default_lang}_{$rand}">
                        {$element[@lang=$default_lang]/text()}
                        </textarea>
                    </div>
       
                    {for $pageElem in $element[@lang ne $default_lang]
                    order by data($pageElem/@lang) ascending    
                    return
                    <div id="page_{$pagename}_{$deep}{name($pageElem)}_{data($pageElem/@lang)}_{$rand}" class="tab-pane fade">
                    <textarea class="content-textarea saved nest"  name="page_{$pagename}_{$deep}{name($pageElem)}_{data($pageElem/@lang)}_{$rand}">{$pageElem/text()}</textarea>   
                    </div>
                    }
          
                    </div>
                </div>
    
};

declare function adminapp:site-form-content-pages-tab-input-group($default_lang as xs:string,$label as xs:string,$pagename as xs:string,$element,$rand,$deep){
                <div class="form-group multilangInput">
                    <label class="control-label">{$label}</label>
                    <div class="input-group defaultLang">
                        <div class="input-group-addon">
                            <img class="defaultLangImg" src="../resources/assets/lang/{$default_lang||'.png'}"/>
                        </div>
                        <input type="text" class="form-control" name="page_{$pagename}_{$deep}{name($element[@lang=$default_lang])}_{$default_lang}_{$rand}" value="{$element[@lang=$default_lang]}"/>
                    </div>
                    <div class="otherLangs">
                    {for $pageElem in $element[@lang ne $default_lang]
                    order by data($pageElem/@lang) ascending    
                    return
                    <div class="input-group" style="display:none">
                        <div class="input-group-addon"><img src="../resources/assets/lang/{data($pageElem/@lang)||'.png'}"/></div>
                        <input type="text" class="form-control" name="page_{$pagename}_{$deep}{name($pageElem)}_{data($pageElem/@lang)}_{$rand}" value="{$pageElem}"/>
                    </div>
                    }
                    </div>
                </div>
    
};


declare function adminapp:site-form-content-pages-tab-table-group($default_lang as xs:string,$label as xs:string,$pagename as xs:string,$element,$rand,$deep){
    let $languagePills:=<ul class="nav nav-pills">
                        <li class="active"><a data-toggle="pill" href="#page_{$pagename}_{$deep}{name($element[@lang=$default_lang])}_{$default_lang}_{$rand}"><img src="../resources/assets/lang/{$default_lang||'.png'}"/></a></li>
                        {for $pageElem in $element[@lang ne $default_lang]
                    order by data($pageElem/@lang) ascending
                    return
                       <li><a data-toggle="pill" href="#page_{$pagename}_{$deep}{name($pageElem)}_{data($pageElem/@lang)}_{$rand}"><img src="../resources/assets/lang/{data($pageElem/@lang)||'.png'}"/></a></li>
                        }
                       </ul>
    return
                <div class="form-group multilangTable">
                    {$languagePills}
                    <div class="tab-content">
                        <div id="page_{$pagename}_{$deep}{name($element[@lang=$default_lang])}_{$default_lang}_{$rand}" class="tab-pane fade in active">
                        <textarea class="table-textarea saved nest hidden defaultLang" name="page_{$pagename}_{$deep}{name($element[@lang=$default_lang])}_{$default_lang}_{$rand}">
                        {$element[@lang=$default_lang]/text()}
                        </textarea>
                    </div>
  
                    {for $pageElem in $element[@lang ne $default_lang]
                    order by data($pageElem/@lang) ascending    
                    return
                    <div id="page_{$pagename}_{$deep}{name($pageElem)}_{data($pageElem/@lang)}_{$rand}" class="tab-pane fade">
                    <textarea class="table-textarea saved nest hidden"  name="page_{$pagename}_{$deep}{name($pageElem)}_{data($pageElem/@lang)}_{$rand}">{ if($pageElem/text() eq name($pageElem)||": "||data($pageElem/@lang)) then (
                        let $d:='[[{"val":"head 1"}, {"val":"head 2"}, {"val":"head 3","settings":{"class":"danger"}} ],[ {"val":"value"}, {"val":"value"}, {"val":"value","settings":{"class":"warning"}} ],[ {"val":"value"}, {"val":"value"}, {"val":"value","settings":{"class":"warning"}} ]]'
                return
                    $d)
                        else ($pageElem/text())
                        
                        
                    }</textarea>   
                    </div>
                    }
                   
                    </div>
                </div>
    
};

declare function adminapp:site-form-content-pages-tab-citation-group($default_lang as xs:string,$label as xs:string,$pagename as xs:string,$element,$rand){
    <div class="panel panel-default form-group singleLang block">
        <label class="col-sm-1 control-label" for="page_{$pagename}_content_block_citation_citkey_{$rand}" style="padding-right:0">Key</label>
        <div class="col-sm-1" style="padding-left:0">
            <input type="text" name="page_{$pagename}_content_block_citation_citkey_{$rand}" class="form-control col-sm-1" value="{$element/citkey}" style="padding:0"/>
        </div>
        <label class="col-sm-1 control-label" for="page_{$pagename}_content_block_citation_cititem_{$rand}" style="padding-right:0">Citation</label>
            <div class="col-sm-9">
                <input type="text" name="page_{$pagename}_content_block_citation_cititem_{$rand}" class="form-control col-sm-8 nest" value="{$element/cititem}"/>
                <p class="editarea-box-title">
                    <strong>Citation</strong>
                </p>
            </div>
        <div class="clearfix"/>
    </div>
    
};

declare function adminapp:site-form-content-pages-tab-browse-group($default_lang as xs:string,$languages, $label as xs:string,$pagename as xs:string,$element,$rand){
        adminapp:site-form-content-pages-tab-input-group($default_lang,"Label",$pagename,
            adminapp:site-form-content-pages-tab-rebuild-multilang-element($element/fieldLabel,$languages),
            $rand,"content_block_browse_"),
        <div class="cluster">
        <div class="row">
                <div class="col-md-4">
                    <label>fieldName</label>
                    <input class="form-control item-browse" data-element="fieldName" name="page_{$pagename}_content_block_browse_fieldName_{$rand}" type="text" value="{$element/fieldName}"/>
                </div>
                <div class="col-md-4">
                    <label>lucene-index-query</label>
                    <input class="form-control item-browse" data-element="lucene-index-query" name="page_{$pagename}_content_block_browse_lucene-index-query_{$rand}" type="text" value="{$element/lucene-index-query}"/>
                </div>
                <div class="col-md-4">
                    <label>lucene-index-type</label>
                    <input class="form-control item-browse" data-element="lucene-index-type" name="page_{$pagename}_content_block_browse_lucene-index-type_{$rand}" type="text" value="{$element/lucene-index-type}"/>
                </div>                
        </div>
        <div class="row">

                <div class="col-md-4">
                    <label>lucene-index-analyzer</label>
                    <input class="form-control item-browse" data-element="lucene-index-analyzer" name="page_{$pagename}_content_block_browse_lucene-index-analyzer_{$rand}" type="text" value="{$element/lucene-index-analyzer}"/>
                </div>
                <div class="col-md-4">
                    <label>target</label>
                    <input class="form-control item-browse" data-element="target" name="page_{$pagename}_content_block_browse_target_{$rand}" type="text" value="{$element/target}"/>
                </div>
                <div class="col-md-4">
                    <label>node</label>
                    <input class="form-control item-browse" data-element="node" name="page_{$pagename}_content_block_browse_node_{$rand}" type="text" value="{$element/node}"/>
                </div>
        </div>
    </div>
};

declare function adminapp:site-form-content-pages-tab-menu-options(){
    
    
    let $menu-box:=adminapp:site-form-content-pages-tab-menu-box($adminapp:structure/*,'inverse','Select','menu_options')                
       
    return
        $menu-box
};

declare function adminapp:site-form-content-pages-tab-menu-built($node as node(),$model as map(*)){
    let $order:=$model('order')
    let $str:=$adminapp:structure
    
    let $menu-options:=
            for $itm in $order
            return
            $str/items/*[./name=$itm/item]
            

    let $menu-box:=adminapp:site-form-content-pages-tab-menu-box(<items>{$menu-options}</items>,'default','Edit','menu_built')
             
    return
        $menu-box
};

declare function adminapp:site-form-content-pages-tab-menu-box($source, $navbar-class as xs:string, $navbar-title as xs:string, $list-class as xs:string){
    let $menu-items:=
            for $item in $source/*
            let $req:=
                if(data($item/@required)='false') 
                then (
                    <a href="#" class="btn btn-sm btn-default action remove">
                        <span class="glyphicon glyphicon-remove"></span>
                    </a>) 
                else ()
        
            return
            <li class="unique" data-name="{$item/name}" data-type="{name($item)}" data-label="{$item/label/text()}">
                <a href="#" class="btn btn-default btn-sm btn-block action sort" style="padding-top: 2px;padding-bottom: 2px;"><span class="glyphicon glyphicon-sort"></span></a>
                <div class="clearfix"></div>
                <div class="btn-group item_options">
                    <a href="#" class="btn btn-sm btn-default menu_item" data-name="{$item/name}" data-type="{name($item)}">
                        <span class="action edit glyphicon glyphicon-edit"></span>
                        <span>{$item/label/text()}</span>
                    </a>
                    {$req}
                </div>
                <input class="pages_checkbox" type="checkbox" value="{$item/name}" name="order[]" />
            </li> 
    

    let $menu-box:=  <div class="navbar navbar-{$navbar-class}">
                    <div class="navbar-header">
                        <a class="navbar-brand" href="#">{$navbar-title}: </a>
                    </div>
                    <ul id="{$list-class}" class="nav navbar-nav connectedSortable">
                        {$menu-items}  
                    </ul>
                </div>
    return
        $menu-box
    
};

declare function adminapp:site-form-content-pages-tab-page($node as node(),$model as map(*),$type as xs:string,$name as xs:string,$lang as xs:string,$label as xs:string,$pagetitle as xs:string){
    let $id:=$model('id')
    let $pages:=$model('pages')
    let $field:='page_'||$lang||'_'||$name
    
    
    (:let $buttons:= adminapp:site-form-content-pages-tab-page-content-buttons($id,$name,$lang)
    let $help:=adminapp:site-form-content-pages-tab-page-help($name):)
    (:let $tools:=adminapp:site-form-content-pages-tab-page-tools($name,$lang,$pages):)
    let $elements:=adminapp:site-form-content-pages-tab-page-raw-content($name,$lang,$pages)
    let $move-delete-bar:=adminapp:snippet-edit-bar($node,$model)
    return
    <div class="form-group page-form {$name} {$lang}" style="display:none">
        <p class="breadcrumb">{$id||"/page/"||$lang||'/'||$name}</p>
        {adminapp:snippet-common-page-fields($field,$label,$pagetitle)}
        {$tools}
        {$help}
        <div class="edit-area-block">
            {$buttons}
            <div class="edit-area {$type}">
 
            {for $item in $elements
            let $rnd:=util:random()
            let $rand:=(floor(util:random() * 10000)+1)
            return
               <div class="{name($item)}">    
                    <div class="panel panel-default form-group block {name($item)}">
                        {$move-delete-bar} 
                        <!--adminapp:site-form-content-pages-tab-page-content-parsed($name,$lang,$item,$rand)-->
                        <p class="editarea-box-title"><strong>{name($item)} -xq- {$rand}</strong></p>    
                        <div class="clearfix"></div>
                    </div>
                </div>
            }
            </div>
        </div>
    </div>
}; 

(: Useless 
declare function adminapp:site-form-content-pages-tab-emptypage($node as node(),$model as map(*), $lang as xs:string){
    let $id:=$model('id')
    let $title:=$model('title')
    let $pages:=$model('pages')
    
    let $config:=$adminapp:structure
    
    let $pg:=for $page in $pages/page
                return
                    $page/name
                    
    let $instanced_pages:=distinct-values($pages/page/name)                
    
    let $base_items:=
            for $item in $instanced_pages
            let $label:=for $itm in $config/*
                        return
                        if($itm//name/text()=$item) then ($itm//label) else ()
                        
            let $type:=for $itm in $config/*
                        return
                        if($itm//name/text()=$item) then (name($itm)) else ()
            let $field:='page_'||$lang||'_'||$item
            let $pagetitle_default:=$title||": "||$lang||": "||$label||": "||$type
            return
                adminapp:site-form-content-pages-tab-page($node,$model,$type,$item,$lang,$label,$pagetitle_default)
    return
        $base_items
};
:)

declare function adminapp:site-form-content-pages-tab-page-raw-content($name,$lang,$pages){
    for $page in $pages/page[@lang=$lang]
    let $content:=$page/content/*
    where $page/name=$name    
    return
        $content   
};




declare function adminapp:site-form-content-pages-tab-page-help($name){
    let $pagetypes:=$adminapp:structure/*
    for $int in $pagetypes/*
    where $int//name=$name
    return
        <div class="aracne_help">
            <button class="btn btn-default" data-toggle="collapse" data-target="#help_{$name}"><span class="glyphicon glyphicon-comment" aria-hidden="true"></span> Help</button>
            <div id="help_{$name}" class="collapse">
            {$int//help/*}
            </div>
        </div>
};


(: Footer Tab :)
declare function adminapp:site-form-content-footer-tab($node as node(),$model as map(*)){
    let $id:=$model('id')
    let $languages:=$model('languages')
    let $footer:=$model('footer')
    
    let $help:=<p class="araweb_help">Define the footer by adding or removing columns. Each column contains a summernote lite version: few essentials buttons. You can define a footer for each of language or use just one for all languages, just adding the default_language footer.</p>
    let $panel:=<div class="panel">
                    {adminapp:site-form-content-lang-navigator($node,$model,'footer')}
                     <button id="footer_add_column" class="btn btn-danger">Add a column</button> 
                </div>
    
    let $box:=
            <div id="footer-box">
            {
                for $lang in $languages/lang
                return
                    <div id="footer_{$lang}" class="footer-lang-box">
                        <p class="breadcrumb">{$id||"/footer/"||$lang}</p>
                        <div class="footer-edit-area {$lang}">
                            <div class="row">
                            {
                                for $col in $footer[@lang=$lang]/col
                                let $colNum:=12 div count($footer[@lang=$lang]/col)
                                return
                                    <div class="footer-col form-group col-md-{$colNum}">
                                        {adminapp:snippet-footer-edit-bar($node,$model)}
                                        {adminapp:site-form-content-textarea($node,$model,'footer_'||$lang||"[]",'form-control footer_textarea saved',$col/node())}
                
                                    </div>
                                }                            
                            </div>
                        </div>
                    </div>
            }
            </div>
    let $footer:=$help||$panel||$box        
    
    return 
        <div>{$help}{$panel}{$box}</div>
    
};

(: Textarea template for Site Content Area:)
declare %templates:default("class", '') function adminapp:site-form-content-textarea($node as node(), $model as map(*),$field as xs:string?, $class as xs:string?,$value as xs:string) {

    <div class="form-group">
        <label class="control-label" for="{$field}" id="{$field}label">{$field}</label>
        <div>
            <textarea class="form-control {$class}" rows="8" name="{$field}" id="{$field}">
                
             {$value}   
 
            </textarea>
        </div>
    </div>

};

(: SNIPPETS :)
declare function adminapp:snippet-site-structure-contents-buttons($node as node(), $model as map(*)){
        <div class="btn-group text-center">
            <button class="btn btn-warning step_one site_structure" disabled="disabled">Structure</button>
            <button class="btn btn-success step_one site_contents">Contents</button> 
        </div>
    
};

declare function adminapp:snippet-edit-bar($node as node(), $model as map(*)){
    <div class="nav navbar-editarea">
        <ul class="nav navbar-nav">
            <li class="up">
                <a href="#up" style="">
                    <span class="glyphicon glyphicon-arrow-up"/>
                </a>
            </li>
            <li class="down">
                <a href="#down">
                    <span class="glyphicon glyphicon-arrow-down"/>
                </a>
            </li>
        </ul>
        <ul class="nav navbar-nav">
            <li class="editbar-box-title"></li>
        </ul>
        <ul class="nav navbar-nav navbar-right">
            <li class="remove_field_item pull-right">
                <a href="#" class="remove_field">
                    <span class="glyphicon glyphicon-remove"/>
                </a>
            </li>
        </ul>
    </div>
};

declare function adminapp:snippet-footer-edit-bar($node as node(), $model as map(*)){
    <div class="nav navbar-editarea">
        <ul class="nav navbar-nav navbar-right">
            <li class="remove_field_item pull-right">
                <a href="#" class="remove_footer_field">
                    <span class="glyphicon glyphicon-remove"/>
                </a>
            </li>
        </ul>
    </div>
};

declare function adminapp:page-simple-element-return($name as xs:string,$pagename, $pages){
    
    for $pg in $pages
        let $tok_pg:=tokenize($pg,"_")
        (:let $base:='page_'||$tok_page[1]||'_'||$tok_page[2]||'_'
        let $selector:=$base||$name
        
        
        return element {$name} {$value}:)
        let $value:= request:get-parameter($pg, '')
        where $name eq $tok_pg[3] and $pagename eq $tok_pg[2]
        return
            element {$name}{ attribute lang { $tok_pg[last()] },$value}
    
};

declare function adminapp:snippet-common-page-fields($field as xs:string,$label as xs:string,$pagetitle as xs:string){
    <div>    
        <label class="control-label" for="{$field}_label">Menu Item</label>
        <input class="form-control" name="{$field}_label" id="{$field}_label" value="{$label}" />    
        <label class="control-label" for="{$field}_pagetitle">Page title</label>
        <input class="form-control" name="{$field}_pagetitle" id="{$field}_pagetitle" value="{$pagetitle}" />
    </div>
    
};


declare function adminapp:site-publish-default-order(){
    let $mitems:=$adminapp:structure
                
    
                    
    let $default:=element {'order'} {
        for $required in $mitems//*[@required="true"]
        let $item:=$required/name
        return
         <item>{$item/text()}</item>
    }
    
    return
        $default
    
};

declare function adminapp:site-publish-default-meta-title($id,$lang){
    let $ctitle:=mainapp:collection-title($id)
    let $default_title:= <title lang="{$lang}">{$ctitle/text()}:{$lang/text()}</title>
    return
        $default_title
};

declare function adminapp:site-publish-default-meta-keywords($lang){
    let $default_keywords:=<keywords lang="{$lang}">Lorem, ipsum, dolor, sit, amet</keywords>
    return
        $default_keywords
};

declare function adminapp:site-publish-default-meta-description($lang){
    let $default_description:=<description lang="{$lang}">Lorem ipsum dolor sit amet</description>
    return
        $default_description
};

declare function adminapp:site-publish-default-pages($id,$languages){
    let $collections:=$config:collections
    let $collection:= if($id) then 
        for $collection in $collections/collection
        where $collection/id=$id
        return
        $collection
        else ()
    
    let $published-ledgers:=$config:published-root
    let $path:=$published-ledgers||'/'||$id||'.xml'
    let $basequery:=concat("doc('",$path,"')")
    let $q:=util:eval($basequery)
    
    let $mitems:=$adminapp:structure
    
                    
    let $default:=
        for $required in $mitems//*[@required="true"]
        return
         <page>
            {$required/name}
            {
            for $lang in $languages
            return
            <label lang="{$lang}">{$required/label/text()}</label>
                    
            }
            {
            for $lang in $languages
            return
            <pagetitle lang="{$lang}">{$collection/ctitle||": "||$lang||": "||$required/label}</pagetitle>        
            }
            <content/>
        </page>    
    return
        $default
};



declare function adminapp:site-resume-info($node as node(), $model as map(*)){
    let $id := request:get-parameter("id", ()) 
    return
    if(not($id)) then () 
    else (
    
    let $built-root:=$config:built-root
    let $bpath:=$built-root||'/'||$id
    
    let $published-root:=$config:published-root
    let $path:=$published-root||'/'||$id||'.xml'
    let $siteXml:=doc($path)/site
    
    let $spath:=$config:sites||"/"||$id
    
    let $tools:=distinct-values($siteXml//tool)
    
    let $check_lang_pages:=if(count($siteXml/languages/lang)*count($siteXml/order/item)=count($siteXml/pages/page/label))
                then(<p class="text-success">Langs x Pages is ok</p>)
                else(<p class="text-danger">Langs x Pages is: {count($siteXml/languages/lang)*count($siteXml/order/item)} but count of pages is {count($siteXml/pages/page)}: please review your settings.</p>)
    
    let $check_footer:=if(count($siteXml/languages/lang)=count($siteXml/footer))
                then(<p class="text-success">Footers are ok</p>)
                else(
                    if(count($siteXml/languages/lang) < count($siteXml/footer))
                    then(<p class="text-danger">Langs a less than Footers: please review your settings</p>)
                    else(<p class="text-warning">Footers are less than Langs: default lang footer will be used for unsetted footers</p>)
                    )
                  
    return
    <div>
            <p><small>The database is stored in: {$bpath}</small></p>
            <p><small>The site configuration file is: {$path}</small></p>
            <p><strong>Configurations</strong></p>
            <p>default language: {$siteXml/default_lang}</p>
            <p>theme: {$siteXml/theme}</p>
            <p>logo: {$siteXml/logo}</p>
            <p>favicon: {$siteXml/favicon}</p>
            <p>Languages:
            {$siteXml/languages}
            </p>
            <p>The site contains {count($siteXml/order/item)} pages.</p>
            <p>Pages are named as (and in this order): {$siteXml/order}</p>
            {$check_lang_pages}
            {$check_footer}
            <p>Those tools will be imported in the site: {
                for $tool in $tools
                return
                    <u>{$tool}</u>
                
            }</p>
            
            <p>Tables in pages</p>
            <!--{ (_ let $tables:=$siteXml//page/content/table
            return
                $tables
                
            :) } -->

            <p>The website will be stored in the directory: {$spath}</p> 
            {
                 if(xmldb:collection-available($spath)=true()) 
                 then (<p class="text-danger">BE CAREFUL. This site exists. A backup will be performed before the new site creation</p>)
                 else ()
                
            }
            <p class="text-success">
                 <a href="#" data-id="{$id}" id="create_site" class="btn btn-primary btn-lg">Create the site</a>         
            </p>
    </div>
    )
};

declare function adminapp:setup-links($node as node(), $model as map(*)){
    let $root:=$config:app-root
    return
    <ul>
        <li>
            <a class="setup_link" href="setup.html?file={$root}/resources/scripts/cm-tei-schema.xml">Codemirror Tei Schema</a>
        </li>
        <li>
            <a class="setup_link" href="setup.html?file={$root}/admin/data/site_structure.xml">Site builder configuration</a>
        </li>
    </ul>
};

declare function adminapp:setup-xmleditor($node as node(), $model as map(*)){
    if(request:get-parameter("file", ()))
    then
    (
    let $file := request:get-parameter("file", ())
    let $basequery:=concat("doc('",$file,"')")
    let $file-content:=util:eval($basequery) 
    return
    <form id="xml-form" action="setup-save-xml.xql" method="POST" class="form">
        <input type="hidden" name="file-name" class="form-control" value="{$file}" />
        <!-- Hidden fields-->
        <div class="form-group">
            <textarea class="form-control editor xml" name="file-content" id="fileContent">
             {$file-content}   
            </textarea>
        </div>
        <button id="xml-form-button" type="submit" class="btn btn-primary">Save <span class="glyphicon glyphicon-file"/>
        </button>
    </form>
    )
    else
        ()
};

declare function adminapp:setup-interface($node as node(), $model as map(*)) as map(*){
    let $file := request:get-parameter("file", ())
    return
        map { "file" := $file, "class" := "xml"}
};

declare function adminapp:setup-interface-input($node as node(), $model as map(*)) {
    let $file:=$model('file')
    return
        <input type="hidden" name="file-name" class="form-control" value="{$file}" />
};


declare 
%templates:wrap 
%templates:default("class", '')
function adminapp:setup-interface-textarea($node as node(), $model as map(*)) {
    let $file:=$model('file')
    let $class:=$model('class')
    let $basequery:=concat("doc('",$file,"')")
    let $file-content:=util:eval($basequery) 

    return    
    <div class="form-group">
        <textarea class="form-control editor {$class}" name="file-content" id="fileContent">
             {$file-content}   
        </textarea>
    </div>
};

declare function adminapp:site-publish-upgrade-db($node as node(), $model as map(*)){
    let $id := request:get-parameter("id", ())

    let $res:=if($id) then(
    let $builtDbPath:=$config:built-root||"/"||$id
    let $siteDbPath:=$config:sites||"/"||$id||"/data"
    
    let $backupold-db:=adminapp:site-publish-backupold-db($id)
    
    let $dbdir:= if(xmldb:create-collection($config:sites||"/"||$id,'data')) then ("Create db dir for "||$id) else ("Can't create db dir for "||$id) 
    
    return
    <div class="text-center">
        <p>Upgrading database</p>
        
        {
        let $files:=xmldb:get-child-resources($builtDbPath)
        for $file in $files
        return
            xmldb:copy($builtDbPath, $siteDbPath,$file)
        }
        <img style="width:70px;" src="../resources/img/ringred.gif"/>
        <p><i class="fa fa-lg fa-database"></i></p>
        <p>Database upgraded</p>
    </div>
    )
    else (
        response:redirect-to(xs:anyURI("collections_built.html"))
        )
    return
        $res
};

declare function adminapp:site-publish-backupold-db($id as xs:string){
    let $spath:=$config:sites||"/"||$id||"/data"
    let $bpath:=$config:sitesbackup||"/"||$id
    let $backup:=if(xmldb:collection-available($spath)=true()) then (
            
            let $time:=datetime:timestamp(current-dateTime()) 
            let $bkid:= $id||".onlyDb."||$time
            let $bkdir:=xmldb:create-collection($config:sitesbackup,$bkid)
            let $mv:=xmldb:move($spath, $bkdir)
            (:let $rn:=xmldb:rename($bpath, $bkid):)
            return
                $bkdir
            )
        else()    

    return
        $backup
};


(:<page lang="it">
            <name>homePage</name>
            <label>Home Page</label>
            <pagetitle>Test: it: Home Page</pagetitle>
            <tools>
                <tool>autoToc</tool>
            </tools>
            <content>
                <paragtitle>It Lorem ipsum</paragtitle>
                <textarea>it Lorem &lt;b&gt;ipsum&lt;/b&gt; dolor sit amet &lt;b&gt;ah ben&lt;/b&gt; proviamo</textarea>
                <paragtitle>It2 Lorem ipsum</paragtitle>
                <textarea>it2 Lorem &lt;b&gt;ipsum&lt;/b&gt; dolor sit amet</textarea>
                <table>                [
                    [ {"val":"Lorem"}, {"val":"Ipsum"}, {"val":"Dolor","settings":{"class":"danger"}} ],
                    [ {"val":"1"}, {"val":"234"}, {"val":"Amet","settings":{"class":"warning"}} ],
                    [ {"val":"0,1"}, {"val":"usque"}, {"val":"333","settings":{"class":"warning"}} ]
                ]
                </table>
            </content>
        </page>
 : 
 :  UNUSED functx functions, for now they stay here 
 declare function adminapp:camel-case-to-words
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   concat(substring($arg,1,1),
             replace(substring($arg,2),'(\p{Lu})',
                        concat($delim, '$1')))
 } ;
 
 declare function adminapp:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;
 

 
:) 