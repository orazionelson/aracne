xquery version "3.0";

import module namespace functx="http://www.functx.com/functx" at "../modules/functx.xql";
import module namespace config="http://aracne/config" at "../modules/config.xqm";

let $username := request:get-parameter('username', 'anon')
let $password := request:get-parameter('password', '')
let $fullname := request:get-parameter('fullname', '')
let $description := request:get-parameter('description', '')

let $editors:=sm:get-group-members($config:editor-group)

 let $a:=
    if($username!='anon' and $username!='admin') then(
    
     let $res:=functx:is-value-in-sequence($username,$editors)
     return
     if($res=false()) then (
         let $cr := sm:create-account($username, $password, $config:editor-group, '', $fullname, $description)
 
         return
             response:redirect-to(xs:anyURI("editors.html"))
         
     ) else (
         response:redirect-to(xs:anyURI("editors.html?message=error3"))
         )
     

    ) else (
        response:redirect-to(xs:anyURI("editors.html?message=error2"))
        )
    

return
    <div>
        <p>{$a}</p>
    </div>