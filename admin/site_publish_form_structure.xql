xquery version "3.0";

import module namespace config="http://aracne/config" at "../modules/config.xqm";

import module namespace adminapp="http://aracne/admin/templates" at "modules/adminapp.xql";


let $published-ledgers:=$config:published-root
let $media-root:=$config:media

let $id := request:get-parameter('id', '')
let $title := request:get-parameter('title', '')
let $default_lang:=request:get-parameter('default_lang','')
let $languages:=request:get-parameter('languages[]','')
let $theme:=request:get-parameter('theme','')
let $site_css:=request:get-parameter('site_css','')
let $site_js:=request:get-parameter('site_js','')



(: Working :)
let $default_lang_replace := adminapp:site-publish-query($id,'default_lang','text')

let $site_css_replace := adminapp:site-publish-query($id,'site_css','text')
let $site_js_replace := adminapp:site-publish-query($id,'site_js','text')

let $path:=$published-ledgers||'/'||$id||'.xml'
let $basequery:=concat("doc('",$path,"')")

let $q:=util:eval($basequery)  

(: Check theme or add default :)
let $theme_replace := if(string-length(normalize-space($theme)) eq 0) then(
                        update insert element {'theme'} {'cerulean'} into $q/site
                        )
                        else (adminapp:site-publish-query($id,'theme','text'))


(: Check langs: Add always default_lang if not specified :)
let $langs:=(if($default_lang=$languages) then () else (<lang>{$default_lang}</lang>),
            if(string-length(normalize-space(string-join($languages))) ne 0) 
                then (for $lang in $languages
                        return
                        <lang>{$lang}</lang>)
                else ()
            )

let $remlg:=update delete $q//languages
(:  let $delete_languages_if_exist:=if(count($q/languages/lang)>0) then (update delete $q/languages) else ():)
let $lg := update insert <languages>{$langs}</languages> into $q/site  

(: Set up default content fot Metatags, Menu Button, Pages :)
(: Check Meta :)
let $meta:=for $meta in $q//meta
            return
                $meta
                
let $add_default_meta:=if(count($meta/*)=0)
                    then(
                        let $empty_meta:=update insert <meta/> into $q/site
                        let $default_title:=
                            for $lang in $q//languages/lang
                            let $dt:=adminapp:site-publish-default-meta-title($id,$lang)
                            return
                                update insert $dt into $q//meta
                        
                        let $default_keywords:=
                            for $lang in $q//languages/lang
                            let $dk:=adminapp:site-publish-default-meta-keywords($lang)
                            return   
                                update insert $dk into $q//meta
                            
                            
                        let $default_description:=
                            for $lang in $q//languages/lang
                            let $dd:=adminapp:site-publish-default-meta-description($lang)
                            return    
                                update insert $dd into $q//meta 
                        return
                            <p>ok</p>
                    )
                    else()

(: Check pages order: if does not exist add default :)
let $order:=for $ord in $q//order/item
            return
                $ord

let $add_default_order:=if(count($order)=0)
                then (
                    let $default_xml:=adminapp:site-publish-default-order()
                    return
                        update insert $default_xml into $q/site
                    )
                else ()

(: Check pages if don't exist add default :)
let $pages:=for $page in $q//pages/page
            return
                $page
                
let $add_default_pages:=if(count($pages)=0) 
                then( 
                    let $languages:=$q//languages/lang
                    let $default_xml:=adminapp:site-publish-default-pages($id,$languages)
                    return
                    update insert <pages>{$default_xml}</pages> into $q/site 
                    ) else ()                
 
(: Redirect :)
let $redirect:=response:redirect-to(xs:anyURI('site_publish_form.html?id='||$id))


return
<results>
    <p>{string-length(normalize-space($theme))}</p>
    <p>{$id}</p>
    <p>{$title}</p>
    <p>{$default_lang}</p>
    <p>{$langs}</p>
    <p>{$theme}</p>
    <p>{$site_css}</p>
    <p>{$site_js}</p>
    <p>{count($meta/*)}</p>
</results>
