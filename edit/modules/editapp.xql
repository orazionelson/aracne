xquery version "3.0";

module namespace editapp="http://aracne/edit/templates";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

import module namespace templates="http://exist-db.org/xquery/templates" ;

import module namespace config="http://aracne/config" at "../../modules/config.xqm";
import module namespace mainapp="http://aracne/mainapp" at "../../modules/mainapp.xql";

import module namespace functx="http://www.functx.com/functx" at "../../modules/functx.xql";

import module namespace mess="/messages" at "../../modules/messages.xql";


declare %templates:wrap function editapp:assigned-to-editor-sidebar($node as node(), $model as map(*)) {
    
    let $root:=$config:data-root
    let $children := xmldb:get-child-collections($root)
    let $name:=xmldb:get-current-user()
    let $assigned:=
        for $child in $children
        let $collectionpath:=$root||'/'||$child
        let $permissions:=sm:get-permissions($collectionpath)
        return
            if(data($permissions//@owner)=$name) then $child else ()
        
    return
        if(count($assigned)=0) then <p class="lead text-center">No collections for: {$name}</p> 
        else
        for $collection in $assigned
        order by $collection ascending
        return
        <li><a href="collection.html?id={$collection}">{$collection}</a></li>
};



declare function editapp:button-create-document($node as node(), $model as map(*)){
    let $id := request:get-parameter('id', '')
    return
    <a href="document_form_new.html?id={$id}" class="btn btn-primary">New Document</a>
    
};



declare function editapp:button-release-collection($node as node(), $model as map(*)){
    let $root:=$config:data-root
    let $id := request:get-parameter("id", ())  
    let $cpath:=$root||'/'||$id
    
    let $collection-owner:=xmldb:get-owner($cpath)
    (:app:collection-owner($node,$model):)
    (:
    let $collection-created:=count(collection($cpath))
    let $rapporto-created:=number($collection-created) div number($collection-docnum)
    let $cpercent:=format-number($rapporto-created, '0%')
    let $collection-docnum:=mainapp:collection-docnum($node,$model)
    let $released:=mainapp:collection-released-percent($node, $model)
    let $rapporto-released:=count($released) div number($collection-docnum)
    :)
    
    let $rpercent:=mainapp:collection-released-percent($node, $model)    
    
    let $button:=if(number($rpercent)=100) then (
            <form id="{$id}_assign" action="collection_release.xql" method="POST" class="form">
            
            <input type="hidden" name="collection" value="{$id}" />
            <input type="hidden" name="collection_owner" value="{$collection-owner}" />
            <button type="submit" class="btn btn-primary">Release Collection</button>
            </form>
        ) else ()
    
    return
    <div>{$button}</div>
    
};


declare function editapp:release-document-or-collection($node as node()*, $model as map(*)){    
    let $root:=$config:data-root
    let $id := request:get-parameter("id", ())
    let $docid := request:get-parameter("docid", ())
    let $cpath:=$root||'/'||$id
    
    
    let $result:=if($docid) then (
        let $fname:=concat($docid,'.xml')
        let $dpath:=concat($cpath,'/',$docid,'.xml') 
        let $docowner:=xmldb:get-owner($cpath,$fname)
        let $doc-set-group:=sm:chown(xs:anyURI($dpath), 'admin:'||$config:editor-group)
        let $message:=<message>
                <p>user: {$docowner}, action: release, document: {$fname}</p>
            </message>
        let $wmess:=mess:write($docowner,'admin','release',$message)    
        return
            <span>Document released.</span>
        )
    else ()
    
    
    return
        $result
};


