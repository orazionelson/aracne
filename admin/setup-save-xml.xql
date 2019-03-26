xquery version "3.0";

let $fname := request:get-parameter('file-name', '')

let $fnameseq := tokenize($fname,"/")

let $doc := $fnameseq[last()]

let $fpath := replace($fname, '/'||$doc, '')

let $fcontent := request:get-parameter('file-content', '')

let $remove-return-status := xmldb:remove($fpath, $doc)
let $store-return-status := xmldb:store($fpath, $doc, $fcontent)

let $f:=response:redirect-to(xs:anyURI('setup.html'))

return
    <file>
    <name>{$doc}</name>
    <path>{$fpath}</path>
    <content>{$fcontent}</content>
    </file>
(:  let $remove-return-status := xmldb:remove($cpath, $docid)
    let $store-return-status := xmldb:store($cpath, $docid, $tei):)

