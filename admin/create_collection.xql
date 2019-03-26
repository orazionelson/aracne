xquery version "3.0";

import module namespace config="http://aracne/config" at "../modules/config.xqm";

let $case := request:get-parameter('case', '')
let $id := request:get-parameter('id', '')
let $ctitle := request:get-parameter('ctitle', '')
let $docnum := request:get-parameter('docnum', '')
let $from := request:get-parameter('from', '')
let $to := request:get-parameter('to', 'to')


let $collections:=$config:collections
 (:let $a:=:)
   
let $item:=
    <collection id="{$id}">
        <id>{$id}</id>
        <ctitle>{$ctitle}</ctitle>
        <docnum>{$docnum}</docnum>
        <from>{$from}</from>
        <to>{$to}</to>
    </collection>
     (:return
        $item:)    

let $action:=
    if($case='new') then (
    let $append-result := update insert $item into $collections  
    let $create := xmldb:create-collection($config:data-root, $id)
    let $return:=response:redirect-to(xs:anyURI("collections.html"))
    return "new"
    )
    else if ($case='edit') then(
        let $cid:=$collections/collection[@id = $id]
        let $edit:=update replace $cid with $item
        let $return:=response:redirect-to(xs:anyURI("collections.html"))
        return 
            "edit"
        )
    else ()


return
    <div>
        <!--p>{$case}</p>
        <p>{$item}</p>
        <hr/>
            <p>{$action}</p-->
    </div>