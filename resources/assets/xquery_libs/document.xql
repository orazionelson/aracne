xquery version "3.0";
(: library namespace :)
module namespace document="http://site/document";
(: app namespaces :)
import module namespace config="http://site/config" at "config.xqm";
import module namespace search="http://site/search" at "search.xql";
import module namespace browse="http://site/browse" at "browse.xql";
(: external namespaces :)
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace functx = "http://www.functx.com/functx" at "functx.xql";
(: declare other namespaces :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";


declare function document:document($node as node(), $model as map(*)) {
   let $id := request:get-parameter("id", ())
   let $by := request:get-parameter("by", ())
   let $query := request:get-parameter("query", ())
   
   let $path:= $config:site-data-root || '/' || $id
   let $result :=
        let $doc:= doc($path)/tei:TEI
        return $doc
  
    return
       map { "id" := $id, "by" :=$by, "result" := $result, "query":=$query }  
};

declare function document:view($node as node(), $model as map(*)){
    let $result:= $model("result")
     
    return
        $result
    
};

declare function document:title($id){
    let $title := doc($config:site-data-root||"/"||$id)//tei:titleStmt/tei:title/text()
    return
        $title
};


declare function document:title($node as node(), $model as map(*)){
    let $title:= $model("result")//tei:titleStmt//tei:title/text()
    return
        $title
};

declare function document:date($id){
    let $date:=doc($config:site-data-root||"/"||$id)//tei:docDate/tei:date/text()
    return
        $date
};

declare function document:date($node as node(), $model as map(*)){
    let $date:= $model("result")//tei:docDate//tei:date/text()
    return
        $date
};

declare function document:msIdentifier($node as node(), $model as map(*)){
    let $msIdentifier:= $model("result")//tei:msIdentifier//tei:idno/text()
    return
        $msIdentifier
};

declare function document:summary($node as node(), $model as map(*)){
    let $summary:= $model("result")//tei:summary  
    let $res:=if(functx:has-empty-content($summary)) then () else (document:mark-text($node, $model, $summary))
    return
        $res

};

declare function document:protocollo($node as node(), $model as map(*)){
    let $protocollo:= $model("result")//tei:text/tei:body/tei:div[@type = "protocollo"]
    let $res:=if(functx:has-empty-content($protocollo)) then ($protocollo) else (document:mark-text($node, $model, $protocollo))
    return
        $res
};

declare function document:testo($node as node(), $model as map(*)){
    let $testo:= $model("result")//tei:text/tei:body/tei:div[@type = "testo"]
    let $res:=if (functx:has-empty-content($testo)) then ($testo) else (document:mark-text($node, $model, $testo))
    return
        $res
};

declare function document:escatocollo($node as node(), $model as map(*)){
    let $escatocollo:= $model("result")//tei:text/tei:body/tei:div[@type = "escatocollo"]
    let $res:=if (functx:has-empty-content($escatocollo)) then ($escatocollo) else (document:mark-text($node, $model, $escatocollo))
    return
        $res
};

declare function document:mark-text($node as node(), $model as map(*), $text as element()){
        let $by := $model("by")
        let $id := $model("id")
        let $result:=$model("result")
        let $query:= $model("query")
        
        let $queryExpr := if($query) then (search:create-query($query, 'phrase')) else ()
       
        let $doc:=
            if ($by and $query) then
                (
                    if(contains($by,"@")) then
                        (
                            document:mark-attr($text)
                            )
                        else  util:expand($text[ft:query(., $queryExpr)],"expand-xincludes=no")
                )
                
            else if(not($by) and $query) then
                (
                util:expand($text[ft:query(., $queryExpr)],"expand-xincludes=no")
                )
            else
                $text
        
        return
          if(count($doc) ne 0) then(
              document:mark-element(<div class="document {node-name($doc)} {if($doc/@type) then (data($doc/@type)) else ()}">{$doc}</div>)
          )
          else <div class="document {node-name($text)} {if($text/@type) then (data($text/@type)) else ()}">{$text}</div>
};

declare function document:mark-element($element as element()) as element() {
   element {node-name($element)}
      {$element/@*,
          for $child in $element/node()
              return
               if ($child instance of element(exist:match))
               then <mark>{$child/text()}</mark>
               else 
                   if ($child instance of element())
                   then document:mark-element($child)
                    else $child
      }
};


declare function document:mark-attr($element as element()) as element() {
    
    element {node-name($element)}
    
    {$element/@*,
        let $query:= request:get-parameter("query", ())
        let $param:= request:get-parameter("by", ())
        let $attr:=substring-after($param, '@')
        
        for $child in $element/node()

            return
               if ($child instance of element() and contains($child/@*[local-name(.) = $attr], $query) )
               then <exist:match>{$child/text()}</exist:match>
               else 
                   if ($child instance of element())
                   then document:mark-attr($child)
                    else $child
    }
};
