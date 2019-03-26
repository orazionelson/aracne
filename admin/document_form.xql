xquery version "3.0";

import module namespace dbutil="http://exist-db.org/xquery/dbutil" at "/db/apps/shared-resources/content/dbutils.xql";

import module namespace config="http://aracne/config" at "../modules/config.xqm";


let $post-data := request:get-data()

let $case := request:get-parameter('case', '')
let $collection_id := request:get-parameter('collection_id', '')
let $docid := request:get-parameter('docid', '')

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
let $cpath:=$root||'/'||$collection_id

let $action:=
    if($case='new') then (
        if (xmldb:collection-available($cpath)) 
        then (
            let $fnum:=count(xmldb:get-child-resources($cpath))
            let $docname:= if($fnum=0) then (
                                concat($collection_id,".1.xml")
                            )
                        else (
                            let $fid:=xs:int($fnum)+1
                            return
                                concat($collection_id,".",$fid,".xml")
                            )
            let $store-return-status := xmldb:store($cpath, $docname, $tei) 
            let $doc := doc(concat($cpath,"/",$docname))/TEI
            (:let $addns := update insert attribute namespace {'http://www.tei-c.org/ns/1.0'} into $doc:)
            return
                response:redirect-to(xs:anyURI(concat("collection.html?id=",$collection_id)))
                
        )
        else (response:redirect-to(xs:anyURI("collections.html")))
        
        )
    else (
        if (xmldb:collection-available($cpath)) 
        then (
            let $path:= $root || '/' || $collection_id || '/' || $docid
            
            let $remove-return-status := xmldb:remove($cpath, $docid)
            let $store-return-status := xmldb:store($cpath, $docid, $tei)
            let $doc := doc(concat($cpath,"/",$docid))/TEI
            (:let $addns := update insert attribute namespace {'http://www.tei-c.org/ns/1.0'} into $doc:)
            return
                response:redirect-to(xs:anyURI(concat("collection.html?id=",$collection_id)))
            )
        else()
        )

(:  fileDesc
let $collections:=$config:collections

   
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
    </collection>
     (:return
        $item:)    

let $target:=concat('collection_form.html?id=',$id)

let $action:=
    if($case='new') then (
    let $append-result := update insert $item into $collections  
    let $create := xmldb:create-collection($config:data-root, $id)
    
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
:)

return
<p>{$biblio_source}<br/>{$action} <br/> {$tei} <br/> </p>
