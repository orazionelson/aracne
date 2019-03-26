xquery version "3.0";
(: library namespace :)
module namespace browse="http://site/browse";
(: app namespaces :)
import module namespace config="http://site/config" at "config.xqm";
import module namespace search="http://site/search" at "search.xql";
import module namespace document="http://site/document" at "document.xql";
(: external namespaces :)
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace functx = "http://www.functx.com/functx" at "functx.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
(: declare other namespaces :)
declare namespace cc="http://exist-db.org/collection-config/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
(: library config :)
declare variable $browse:by:=doc(concat($config:app-root,"/config/browse.xml"));

declare function browse:browse($node as node(), $model as map(*)) as map(*){
    let $by := request:get-parameter("by", ())
    let $collection:=$config:app-root
    let $xconf-collection-name := concat('/db/system/config', $collection)
    let $xconf := collection('/db/system/config')/cc:collection[util:collection-name(.) = $xconf-collection-name]
    let $index-type:='lucene-index'
    let $lang:=browse:get-page-lang()
    

    return
        map { "by" := $by, "lang":=$lang, "collection":=$collection , "index-type":=$index-type, "xconf":=$xconf }
    

};

(: Transforms index definitions into HTML buttons. :)
declare function browse:xconf-to-buttons($node as node(), $model as map(*)) {
            <div class="well well-sm">
                <label>Browse by:</label>
                <div class="btn-group">
                {
                for $entry in ( 
                    browse:get-lucene-indexes($node, $model)
                )
                let $item := $entry/td[1]
                let $index := $entry/td[2]
                (: order by $index, $item :)
                return $entry
                }
                </div>
            </div>

};

(: Analyzes the Lucene indexes in an index definition :)
declare function browse:get-lucene-indexes($node as node(), $model as map(*)) {
    let $xconf:=$model('xconf')
    let $lang:=$model("lang")
    
    
    
    let $lucene := $xconf/cc:index/cc:lucene 
    return if (not($lucene) or not($lucene/cc:text)) then () else 
        (
            
        let $texts := $lucene//cc:text
        return
            (
            for $text in $texts
            let $qname := if ($text/@qname) then $text/@qname/string() else ()
            let $match := if ($text/@match) then $text/@match/string() else ()
            
            let $target:= if ($text/@qname) then $text/@qname/string() else ( $text/@match/string() )
            
            let $analyzer := if ($text/@analyzer) then $text/@analyzer/string() else ()
            let $collection := substring-after(util:collection-name($text), '/db/system/config')
            let $key:=if ($qname) then $qname else $match

            let $field:=for $f in $browse:by//by
                where  $f/lucene-index-query/text() eq $key
                return
                    $f/fieldName
                    
            let $label:=for $label in $browse:by//by
                where  $label/lucene-index-query/text() eq $key
                return
                    $label/fieldLabel[@lang eq $lang]    
            
            let $fname:=config:fnameLinkController('browse')
            (:if($label[@default eq "true"]) then ("browse.html")
                else ('browse.'||$lang||'.html'):)
                    
            where $browse:by//by/lucene-index-query = $key 
            return
                
                <a class="btn btn-xs btn-primary" href="{$fname}?{concat('by=', $field)}&amp;lang={$lang}&amp;{if ($qname) then concat('node-name=', $target) else concat('match=', $target)}">{$label[@lang=$lang]/text()}</a>

            )
        )
};

declare function browse:get-page-lang(){
    let $filename:=tokenize(request:get-url(),"/")[last()]
    let $doc:=doc(concat($config:app-root,"/",$filename))
    return
        data($doc//html/@lang)
    
};

(: Get the main and browse-by tables :)
declare function browse:table($node as node(), $model as map(*)){

    let $by := $model("by")    
    let $table:=
            if(not($by)) then (
            <table class="table table-striped table-hover"> 
                <thead><tr><th>Date</th><th>Title</th></tr></thead>
                {
                browse:list-docs($node, $model)
                }
            </table>
            )
            else
            (
            browse:show-index-keys($node, $model)  
            )
        return 
        $table
    };

(: Main browse table content :)
declare function browse:list-docs($node as node(), $model as map(*)) {
    let $data-root:=$config:site-data-root   
    let $lang:=$model('lang')
    let $rows:=for $record in collection($data-root)/tei:TEI
            let $document:=util:document-name($record)    
            let $title:=$record//tei:titleStmt//tei:title/text()
            let $date:=$record//tei:docDate/tei:date/text()
            let $fname:=config:fnameLinkController('document')
            order by $date, $title ascending 
                return
                    <tr class="browse list-docs"><td>{$date}</td><td><a href="{$fname}?id={$document}">{$title}</a></td></tr>
        
                
    return
        $rows

};

(:  Index-Keys: browse-by table content :)
declare 
    %templates:wrap
function browse:show-index-keys($node as node(), $model as map(*)) {
    let $query-start-time := util:system-time()

    let $collection := $model('collection')
    
    let $node-name := request:get-parameter('node-name', '')
    let $match := request:get-parameter('match', '')
    
    
    let $start-value := request:get-parameter('start-value', '')
    let $max-number-returned := xs:integer(request:get-parameter('max', 100))
    let $index-type := $model("index-type")
    let $sortby := request:get-parameter('sortby', 'term')
    let $sortorder := request:get-parameter('sortorder', 'ascending')
    
    let $callback := browse:term-callback#2
    
    let $node-set := 
    if ($node-name ne '' and $collection ne '') then 
        browse:get-nodeset-from-qname($collection, $node-name) 
    else if ($match ne '' and $collection ne '') then 
        browse:get-nodeset-from-match($collection, $match) 
    else 
        ()
    
    let $keys := util:index-keys($node-set, $start-value, $callback, $max-number-returned, $index-type)

    
    let $sorted-keys :=
        if ($sortby eq 'term') then 
            if ($sortorder eq 'ascending') then
                for $key in $keys order by $key/td[1] ascending return $key
            else
                for $key in $keys order by $key/td[1] descending return $key
        else if ($sortby eq 'frequency') then 
            if ($sortorder eq 'ascending') then
                for $key in $keys order by xs:integer($key/td[2]) ascending, $key/td[1] ascending return $key
            else
                for $key in $keys order by xs:integer($key/td[2]) descending, $key/td[1] ascending return $key
        else if ($sortby eq 'documents') then 
            if ($sortorder eq 'ascending') then
                for $key in $keys order by xs:integer($key/td[3]) ascending, $key/td[1] ascending return $key
            else
                for $key in $keys order by xs:integer($key/td[3]) descending, $key/td[1] ascending return $key
        else if ($sortby eq 'position') then 
            if ($sortorder eq 'ascending') then
                for $key in $keys order by xs:integer($key/td[4]) ascending return $key
            else
                for $key in $keys order by xs:integer($key/td[4]) descending return $key
        else $keys
    
    let $query-end-time := util:system-time()
    let $query-duration := ($query-end-time - $query-start-time) div xs:dayTimeDuration('PT1S')

    return
    
        <div>
            <p>{count($keys)} keys returned in {$query-duration}s</p>
           

            <table class="table table-bordered table-striped dataTable">
                <tr>{
                    for $column in ('term', 'frequency', 'documents', 'position')
                    return
                        <th><a href="{browse:set-sortorder($column)}">{$column} {browse:sort-direction-indicator($column)}</a></th>
                }</tr>
                { $sorted-keys }
            </table>
        </div>
};

(:
    Callback function called used in browse:show-index-keys() for util:index-keys()
:)
declare function browse:term-callback($term as xs:string, $data as xs:int+) as element() {
    let $by := request:get-parameter("by", ())
    let $fname:=config:fnameLinkController('browse_by')
    return    
    
    <tr>
        <td name="key"><a href="{$fname}?by={$by}&amp;query={replace($term,' ','+')}">{$term}</a></td>
        <td name="frequency">{$data[1]}</td>
        <td name="documents">{$data[2]}</td>
        <td name="order">{$data[3]}</td>
    </tr>
};


(: Browse by :)
declare 
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function browse:browse-by($node as node()*, $model as map(*)) as map(*) {
    let $by:=request:get-parameter('by','')
    
    let $redirect:=if(not($by)) then (config:redirect("browse")) else ()
    
    
    let $lang:=browse:get-page-lang()
    let $node:=browse:get-node($by) (:if(contains($by,"@")) then ($by) else (".") :)
    
    let $query:=request:get-parameter('query','')
    
    
    let $target:= browse:get-target($by)
    

    
    let $context := collection($config:site-data-root)
    let $lucene-query:= concat("collection('",$config:site-data-root,"')",$target,'[ft:query(',$node,',<query><phrase>',$query,'</phrase></query>)]')
    let $context:=util:eval($lucene-query)
    
    let $hits :=for $hit in $context
                order by ft:score($hit) descending
                return $hit
        (:if ($mode eq 'default') 
            then (
                )

            else ( 
                for $hit in $context//*[ft:query(., $queryExpr)]
                order by ft:score($hit) descending
                return $hit
                       ):)
    return
    map { "by":= $by, "query" := $query, "lang":=$lang, "mode":= 'phrase', "hits":=$hits, "lucene-query":=$lucene-query  }

    
};


(: Show hist results of browsing search :)
declare 
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function browse:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer) {
    let $by:=$model("by")
    let $lang:=$model('lang')
    let $lucene-query:=$model("lucene-query")
    let $queryString := $model("query")

    let $hits:= $model("hits")
    let $fname:=config:fnameLinkController('document',$lang)
    
    let $res:=
    for $hit at $p in subsequence($hits, $start, $per-page)
        let $id:=util:document-name($hit)
        let $title := document:title($id)
        let $date := document:date($id)
        let $result := 
                    let $kwic := 
                    if (contains($by,'@')) then (
                        <a href="{$fname}?id={$id}&amp;by={$by}&amp;query={replace($queryString,' ','+')}">{$hit}</a>
                        (:kwic:summarize(document:mark-attr($hit), <config width="40" table="no" link="document.html?id={$id}&amp;by={$by}&amp;query={$queryString}&amp;mode={$mode}"/>,functx:filter#2):)
                        )
                    else (
            kwic:summarize($hit, <config width="40" table="no" link="{$fname}?id={$id}&amp;by={$by}&amp;query={replace($queryString,' ','+')}"/>,functx:filter#2)
                    )
                    
                      
                    let $loc:=search:results-panel($id,$by,$queryString,$start,$p,$title,$date,$kwic)
                    return
                        $loc
    order by $date, $title ascending
    return
       $result
 
return
    <div>
        <!--uncomment if you want to see the query on the index-->
        <!--p>{$lucene-query}</p-->
        <div>{$res}</div>
    </div>
    
};


(: Helper functions for handling parameters :)
declare function browse:remove-parameter-names($parameter-names-to-remove) {
    let $current-parameter-names := request:get-parameter-names()
    let $remaining-parameters :=
        browse:remove-parameter-names(
            for $current-parameter-name in $current-parameter-names 
            return 
                concat($current-parameter-name, '=', request:get-parameter( $current-parameter-name, () )[1])
            ,
            $parameter-names-to-remove
            )
    return 
        if (exists($remaining-parameters)) then 
            concat('?', string-join($remaining-parameters, '&amp;'))
        else 
            '?'
};

declare function browse:remove-parameter-names($current-parameters, $parameter-names-to-remove) {
    for $current-parameter in $current-parameters 
    return 
        if (substring-before($current-parameter, '=') = $parameter-names-to-remove) then
            ()
        else 
            $current-parameter
};

declare function browse:remove-parameter-names-except($parameter-names-to-keep) {
    let $current-parameter-names := request:get-parameter-names()
    return
        browse:remove-parameter-names($current-parameter-names[not(. = $parameter-names-to-keep)])
};

declare function browse:replace-parameters($new-parameters) {
    let $current-parameter-names := request:get-parameter-names()
    let $current-parameters := 
        for $name in $current-parameter-names
        return concat($name, '=', request:get-parameter($name, ())[1])
    return
        browse:replace-parameters($current-parameters, $new-parameters)
};

declare function browse:replace-parameters($current-parameters, $new-parameters) {
    let $new-parameter-names := for $new-parameter in $new-parameters return substring-before($new-parameter, '=')
    let $remaining-parameters := browse:remove-parameter-names($current-parameters, $new-parameter-names)
    let $result-parameters := for $param in ($remaining-parameters, $new-parameters) order by $param return $param
    return
        concat('?', string-join($result-parameters, '&amp;'))
};


(: Helper functions for handling configuration params (ie. $browse:by-index :)

declare function browse:get-target($by as xs:string){
    let $target:=
        for $p in $browse:by//by
        where $p/fieldName eq $by
        return
            if($p/target) then $p/target/text() else "//*"
    return
        $target
};

declare function browse:get-node($by as xs:string){
    let $node:=
        for $q in $browse:by//by
        where $q/fieldName eq $by
        return
            $q/node
    return
        $node
};

declare function browse:get-query($by as xs:string){
    let $query:=
        for $q in $browse:by//by
        where $q/fieldName eq $by
        return
            $q/query
    return
        $query
};

(: Helper function: Returns the index definition for a given collection :)
declare function browse:get-xconf($collection as xs:string) as document-node() {
    let $config-root := '/db/system/config'
    let $xconf-collection := concat($config-root, $collection)
    let $xconf-filename := xmldb:get-child-resources($xconf-collection)[ends-with(., '.xconf')]
    let $xconf := doc(concat($xconf-collection, '/', $xconf-filename))
    return $xconf
};

(: Helper function: Looks in the collection.xconf's collection and index elements for namespace URIs for a given node name :)
declare function browse:get-namespace-uri-from-node-name($node-name, $collection) {

    let $name := if (starts-with($node-name,'@')) then
                    substring-after( substring-before($node-name, ':'), '@' )
                else
                    substring-before($node-name, ':')
    
    let $xconf := browse:get-xconf($collection)
    let $uri := (namespace-uri-for-prefix($name, $xconf/cc:collection), namespace-uri-for-prefix($name, $xconf//cc:index))[1]
    return
        $uri
};

(: Helper function: Constructs a namespace declaration for use in util:eval() :)
declare function browse:get-namespace-declaration-from-node-name($node-name as xs:string, $collection as xs:string) as xs:string? {
    if (not(matches($node-name, 'xml:')) and contains($node-name, ':')) then
    
        let $name := if (starts-with($node-name,'@')) then
                        substring-after( substring-before($node-name, ':'), '@' )
                    else
                        substring-before($node-name, ':')
        
        let $uri := browse:get-namespace-uri-from-node-name($node-name, $collection)
        return
            concat('declare namespace ', $name, '="', $uri, '"; ') 
    else ()
};

(: Helper function: Returns a nodeset of instances of a node-name in a collection :)
declare function browse:get-nodeset-from-qname($collection as xs:string, $node-name as xs:string) as node()* {
    let $nodeset-expression := 
        concat(
            browse:get-namespace-declaration-from-node-name($node-name, $collection)
            ,
            'collection("', $collection, '")//', $node-name
        )

    return
        util:eval($nodeset-expression)
};

(: Helper function: Returns a nodeset of instances of a match expression in a collection :)
declare function browse:get-nodeset-from-match($collection as xs:string, $match as xs:string) as node()* {
    let $nodeset-expression := 
        concat(
            string-join(
                distinct-values(
                let $node-names := tokenize(replace($match, '//', '/'), '/')
                return
                    for $node-name in $node-names
                    return
                        browse:get-namespace-declaration-from-node-name($node-name, $collection)
                ), ' ')
            ,
            'collection("', $collection, '")', $match, if (contains($match, '@')) then () else ()
        )
    return
        util:eval($nodeset-expression) 
};


(: Helper functions for modifying the sort order used in indexes:show-index-keys()  :)
declare function browse:toggle-sortorder($current-sortorder) {
    browse:toggle-sortorder($current-sortorder, ('ascending'))
};

declare function browse:toggle-sortorder($current-sortorder, $other-new-parameters) {
    let $neworder := 
        if ($current-sortorder eq 'ascending') then
            'sortorder=descending'
        else 
            'sortorder=ascending'
    let $new-parameters := ($neworder, $other-new-parameters)
    return
        browse:replace-parameters($new-parameters)
};

declare function  browse:set-sortorder($current-sortorder, $current-sortby, $new-sortby) {
    if ($current-sortby eq $new-sortby) then 
        browse:toggle-sortorder($current-sortorder)
    else 
        browse:strip-param-from-param-string(browse:replace-parameters(concat('sortby=', $new-sortby)), 'sortorder')
};

declare function browse:set-sortorder($new-sortby) {
    let $sortby := request:get-parameter('sortby', 'term')
    let $sortorder := request:get-parameter('sortorder', 'ascending')
    return
        browse:set-sortorder($sortorder, $sortby, $new-sortby)
};

declare function browse:sort-direction-indicator($sortby as xs:string) {
     let $isortby := request:get-parameter('sortby', 'term')
     let $sortorder := request:get-parameter('sortorder', 'ascending')
     return
    if ($sortby eq $isortby) then
        if ($sortorder eq 'ascending') then
            ' ↓'
        else
            ' ↑'
    else ()
};

declare function browse:strip-param-from-param-string($param-string, $param) {
    replace($param-string, concat('&amp;?', $param, '=[^&amp;]*?&amp;?.*$'), '')
};

