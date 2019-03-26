xquery version "3.0";

import module namespace dbutil="http://exist-db.org/xquery/dbutil" at "/db/apps/shared-resources/content/dbutils.xql";
import module namespace config="http://aracne/config" at "../modules/config.xqm";


let $root:=$config:data-root
let $name := request:get-parameter('name', 'anon')
let $id := request:get-parameter('id', '')

let $collections:=$config:collections

let $path:=$root||'/'||$id


let $a:=
    if($name!='anon' and $name!='admin' and $id) then(
        
        sm:chown($path, $name),
        sm:chgrp($path, $config:editor-group),
        dbutil:scan-resources(xs:anyURI($path), function($resource) {sm:chown($resource, $name),sm:chgrp($resource, $config:editor-group)}),
        update value $collections/collection[@id=$id]/status with 'assigned',
        response:redirect-to(xs:anyURI("assign.html?name="||$name))
    ) else (
        response:redirect-to(xs:anyURI("editors.html?message=error1"))
        )
    

return
    <p></p>
