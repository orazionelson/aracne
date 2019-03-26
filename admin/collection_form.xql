xquery version "3.0";

import module namespace config="http://aracne/config" at "../modules/config.xqm";

let $case := request:get-parameter('case', '')
let $id := request:get-parameter('id', '')
let $status := request:get-parameter('status', '')
let $ctitle := request:get-parameter('ctitle', '')
let $docnum := request:get-parameter('docnum', '')
let $from := request:get-parameter('from', '')
let $to := request:get-parameter('to', '')
let $main_editor := request:get-parameter('main_editor', '')
let $main_source := request:get-parameter('main_source', '')
let $publisher := request:get-parameter('publisher', '')

let $collections:=$config:collections
 (:let $a:=:)
   
let $item:=
    <collection id="{$id}">
        <id>{$id}</id>
        <ctitle>{$ctitle}</ctitle>
        <docnum>{$docnum}</docnum>
        <from>{$from}</from>
        <to>{$to}</to>
        <main_editor>{$main_editor}</main_editor>
        <main_source>{$main_source}</main_source>
        <publisher>{$publisher}</publisher>
        <status>{$status}</status>
    </collection>
     (:return
        $item:)    

let $target:='collections.html'

let $action:=
    if($case='new') then (
    let $append-result := update insert $item into $collections  
    let $create := xmldb:create-collection($config:data-root, $id)
    let $path:=$config:data-root||'/'||$id
    let $newgroup:=sm:chgrp($path, $config:editor-group)
    return "new"
    )
    else if ($case='edit') then(
        let $cid:=$collections/collection[@id = $id]
        let $edit:=update replace $cid with $item
       
        return 
            "edit"
        )
    else ()
let $return:=response:redirect-to(xs:anyURI($target))


return
    <div></div>