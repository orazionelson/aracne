xquery version "3.0";
(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://site/config";

declare namespace templates="http://exist-db.org/xquery/templates";


(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:site-data-root := $config:app-root||"/data";

declare variable $config:browse-by:=doc(concat($config:app-root,"/config/browse.xml"));


declare function config:fnameLinkController($fname as xs:string){
    let $lang:=config:get-page-lang()
    return
        config:fnameLinkController($fname,$lang)
};

declare function config:fnameLinkController($fname as xs:string,$lang as xs:string){
    let $lang:=if(not($lang)) then config:get-page-lang() else $lang
    let $label:=$config:browse-by//by/fieldLabel[@lang eq $lang][1]
    let $fname:=
            if($label[@default eq "true"]) then ($fname||".html")
            else ($fname||'.'||$lang||'.html')   
    return
        $fname
};



declare function config:get-page-lang(){
    let $filename:=tokenize(request:get-url(),"/")[last()]
    let $doc:=doc(concat($config:app-root,"/",$filename))
    return
        data($doc//html/@lang)
    
};


declare function config:redirect($fname as xs:string){
    let $fname:=config:fnameLinkController($fname)
    return
        response:redirect-to(xs:anyURI($fname))
};

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};
