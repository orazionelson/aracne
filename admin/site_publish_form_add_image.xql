xquery version "3.0";

import module namespace config="http://aracne/config" at "../modules/config.xqm";

let $published-ledgers:=$config:published-root
let $media-root:=$config:media

let $id := request:get-parameter('id','')
let $time:=request:get-parameter('time','')
let $filename := request:get-uploaded-file-name('file')



let $newfilename:=$id||"_"||$time||"_"||$filename
let $store := xmldb:store($media-root, $newfilename, request:get-uploaded-file-data('file'))
let $r:=request:get-parameter-names()
return
<results>
    <p>{$newfilename}</p>
</results>