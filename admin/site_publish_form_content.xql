xquery version "3.0";

import module namespace config="http://aracne/config" at "../modules/config.xqm";

import module namespace adminapp="http://aracne/admin/templates" at "modules/adminapp.xql";


let $published-ledgers:=$config:published-root
(:  :let $media-root:=$config:media:)

let $id := request:get-parameter('id', '')
let $title := request:get-parameter('title', '')

let $logo := request:get-parameter('logo', '')
let $favicon := request:get-parameter('favicon', '')



let $sitetitle:=for $par in request:get-parameter-names()
            let $tok_par:=tokenize($par,"_")
            where starts-with($par, 'sitetitle')
            return
                <title lang="{$tok_par[2]}">{request:get-parameter($par, '')}</title>

let $keywords:=for $par in request:get-parameter-names()
            let $tok_par:=tokenize($par,"_")
            where starts-with($par, 'keywords')
            return
                <keywords lang="{$tok_par[2]}">{request:get-parameter($par, '')}</keywords>

let $description:=for $desc in request:get-parameter-names()
            let $tok_desc:=tokenize($desc,"_")
            where starts-with($desc, 'description')
            return
                <description lang="{$tok_desc[2]}">{request:get-parameter($desc, '')}</description>


let $default_lang:=request:get-parameter('default_lang','')
(:  :let $languages:=request:get-parameter('languages[]',''):)

let $path:=$published-ledgers||'/'||$id||'.xml'
let $basequery:=concat("doc('",$path,"')")
let $q:=util:eval($basequery)     

let $logofilename := request:get-uploaded-file-name('logo')
let $faviconfilename := request:get-uploaded-file-name('favicon')


let $logo_replace := if($logofilename) then (
    adminapp:site-publish-query($id,'logo','file')
    )
    else ()
    
let $favicon_replace := if($faviconfilename) then (
    adminapp:site-publish-query($id,'favicon','file')
    )
    else ()
    
let $order:=element {'order'} {
            for $item in request:get-parameter('order[]', '')
            return
                <item>{$item}</item>}

let $pages:=for $page in request:get-parameter-names()
            where starts-with($page, 'page')
            return
                $page
                
let $pagenames:=for $page in request:get-parameter-names()
            let $tok_page:=tokenize($page,"_")
            where starts-with($page, 'page') 
                (:and index-of($q//languages/lang, $tok_page[2]):) 
                and index-of($order/item, $tok_page[2])
            return
                <page>{$tok_page[2]}</page>

let $pagenames:=distinct-values($pagenames)

let $pagestr:=<pages>
            {for $page in $pagenames
            let $tok_page:=tokenize($page,"_")
            
            return
                <page>
                    <name>{$page}</name>
                    
                    {
                        adminapp:page-simple-element-return('label',$page, $pages)
                    }
                    {
                        adminapp:page-simple-element-return('pagetitle',$page, $pages)
                    }
                    {
                    (:Parse Tools:)    
                    for $pg in $pages
                        let $tok_pg:=tokenize($pg,"_")
                        let $value:= request:get-parameter($pg, '')    
                        where ends-with($pg, 'tools[]') and $page eq $tok_pg[2]
                        return
                            element {'tools'}{for $tool in $value
                                return element {'tool'} {$tool}
                            }
                            
                    }
                    <content>
                    {
                    let $blocks:=for $pg at $seq in $pages
                            let $tok_pg:=tokenize($pg,"_")
                            let $idno:=$tok_pg[last()]   
                            where contains($pg, "content_block") and $page eq $tok_pg[2]
                            return
                                $tok_pg[5]||"_"||$idno
                    
                    let $blocks:=distinct-values($blocks)            
                        
                    (:Parse Content:)
                    let $elems:=for $pg at $seq in $pages
                        let $tok_pg:=tokenize($pg,"_")
                        let $value:= request:get-parameter($pg, '')
                        where contains($pg, "content_block") and $page eq $tok_pg[2]
                        return
                            if($tok_pg[5] eq "browse") then (
                                    element{"browse"}{attribute idno { $tok_pg[last()] },element {$tok_pg[6]}{
                                        attribute idno { $tok_pg[last()] },
                                        if($tok_pg[6] eq 'fieldLabel') then (attribute lang {$tok_pg[7]}) else(),
                                        $value}}
                                    )
                             else if($tok_pg[5] eq "citation") then (
                                    element{"citation"}{attribute idno { $tok_pg[last()] },element {$tok_pg[6]}{
                                        attribute idno { $tok_pg[last()] },
                                        $value}}
                                    )        
                            else (
                            element {$tok_pg[5]}{attribute lang { $tok_pg[6] },attribute idno { $tok_pg[last()] }, $value}
                            )
                    return
                        for $block in $blocks
                        let $tok_bl:=tokenize($block,"_")   
                        
                            return
                            if($tok_bl[1] eq 'browse' or $tok_bl[1] eq 'citation') 
                            then (    
                                element{'block'}{
                                    attribute idno {$tok_bl[2]},
                                    element{$tok_bl[1]}{
                                        for $elem in $elems[@idno=$tok_bl[2]]
                                        return
                                        $elem/*
                                        }
                                    }
                            )
                            else (
                                element {'block'}{
                                    attribute idno {$tok_bl[2]},
                                    for $elem in $elems[@idno=$tok_bl[2]]
                                    return
                                        $elem
                                }    
                            )
                    }    
                    </content>  
                </page>
            }
            </pages>

let $footer:=for $foot in request:get-parameter-names()
            let $tok_foot:=tokenize($foot,"_")
            let $flang:=substring($tok_foot[2], 1, string-length($tok_foot[2]) - 2)
            let $value:=request:get-parameter($foot, '')
            where starts-with($foot, 'foot')
            return
                <footer lang="{$flang}">{
                    for $col in $value
                    return element {'col'} {$col}
                            
                    
                }</footer>

(:  Write XML :)
(: Metatags: sitetitle, keywords and descriptions :)
let $remove_sitetitle:=update delete $q//meta/title    
let $update_sitetitle := update insert $sitetitle into $q//meta 
let $remove_keywords:=update delete $q//keywords    
let $update_keywords := update insert $keywords into $q//meta
let $remove_description:=update delete $q//description    
let $update_description := update insert $description into $q//meta

(: Pages Order :)
let $remove_order:=update delete $q//order    
let $update_order := update insert $order into $q//site

(: Pages :)
let $remove_pages:=update delete $q//pages    
let $update_pages := update insert $pagestr into $q//site

(: Footer :)
let $remove_footer:=update delete $q//footer 
let $update_footer := if($footer) then ( update insert $footer into $q/site ) else ()

(: Redirect :)
let $redirect:=response:redirect-to(xs:anyURI('site_publish_form.html?id='||$id))


return
<results>
    {$pages}
    {$pagestr}
<!--    
<p>{$pagenames}</p>
    <p>{$id}</p>
    <p>{$title}</p>
    <logo>{$logofilename}</logo>
    <favicon>{$faviconfilename}</favicon>
    <p>{$order}</p>
    <meta>
        {$sitetitle}
        {$keywords}
        {$description}
    </meta>
    {$pagestr}
    {$footer}
    -->
</results>
