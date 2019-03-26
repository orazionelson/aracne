xquery version "3.0";

import module namespace dbutil="http://exist-db.org/xquery/dbutil" at "/db/apps/shared-resources/content/dbutils.xql";
import module namespace config="http://aracne/config" at "../modules/config.xqm";
import module namespace mess="/messages" at "../modules/messages.xql";



let $root:=$config:data-root

let $collection := request:get-parameter('collection', '')
let $collection_owner := request:get-parameter('collection_owner', '')

let $path:=$root||'/'||$collection


let $a:=sm:chown($path, 'admin')
let $b:=sm:chgrp($path, "arareleased")
let $c:=dbutil:scan-resources(xs:anyURI($path), function($resource) {sm:chown($resource, 'admin'),sm:chgrp($resource, "arareleased")})


let $message:=<message>
            <p>user: {$collection_owner}, action: release, collection: {$collection}</p>
            </message>
        let $wmess:=mess:write($collection_owner,'admin','release',$message)  

let $d:=response:redirect-to(xs:anyURI("index.html"))    

return
    $d
    
