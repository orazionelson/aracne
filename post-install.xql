xquery version "3.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

import module namespace xrest="http://exquery.org/ns/restxq/exist" at "java:org.exist.extensions.exquery.restxq.impl.xquery.exist.ExistRestXqModule";

(: The following external variables are set by the repo:deploy function :)

(: the target collection into which the app is deployed :)
declare variable $target external;

(: Create 'sites' collection and then make writable :)
let $built:=xmldb:create-collection($target, "sites")
return(
    sm:chown($built, "admin"),
    sm:chgrp($built, "aracne"),
    sm:chmod($built, "rwxr-xr-x")
    ), 

(: Create 'edit/data/built' collection and then make writable :)
let $built:=xmldb:create-collection($target || "/edit/data", "built")
return(
    sm:chown($built, "admin"),
    sm:chgrp($built, "aracne"),
    sm:chmod($built, "rwxr-xr-x")
    ), 
    
(: Create 'edit/data/messages' collection and then make writable :)
let $messages:=xmldb:create-collection($target || "/edit/data", "messages")
return(
    sm:chown($messages, "admin"),
    sm:chgrp($messages, "aracne"),
    sm:chmod($messages, "rwxrwxrwx")
    ),
    
(: Create 'edit/data/published' collection and then make writable :)
let $published:=xmldb:create-collection($target || "/edit/data", "published")
return(
    sm:chown($published, "admin"),
    sm:chgrp($published, "aracne"),
    sm:chmod($published, "rwxr-xr-x")
    ),
    
(: Create 'edit/data/temp' collection and then make writable :)
let $temp:=xmldb:create-collection($target || "/edit/data", "temp")
return(
    sm:chown($temp, "admin"),
    sm:chgrp($temp, "aracne"),
    sm:chmod($temp, "rwxrwxrwx")
    ), 
(: Create 'admin/data/messages' collection and then make writable :)
let $amessages:=xmldb:create-collection($target || "/admin/data", "messages")
return(
    sm:chown($amessages, "admin"),
    sm:chgrp($amessages, "aracne"),
    sm:chmod($amessages, "rwxrwxrwx")
    ),    
(: Create 'admin/data/sitesbackup  ' collection and then make writable :)
let $sb:=xmldb:create-collection($target || "/admin/data", "sitesbackup")
return(
    sm:chown($sb, "admin"),
    sm:chgrp($sb, "aracne"),
    sm:chmod($sb, "rwxr-xr-x")
    )
