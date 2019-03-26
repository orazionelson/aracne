xquery version "3.0";

module namespace mess="/messages";
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://aracne/config" at "config.xqm";
(:  :import module namespace functx = "http://www.functx.com/functx" at "functx.xql"; :)
(:  :import module namespace raconfig="/rashared/config" at "config.xql";:)


declare function mess:form($node as node(), $model as map(*)) {
    let $name:=xmldb:get-current-user()
    return
        <form action="mess-write.html" method="post">
        <!--i class="fa fa-bell-o fa-5x"></i>
        <i class="fa fa-laptop fa-5x"></i>
        <i class="fa fa-exclamation-triangle fa-5x"></i>
        <i class="fa fa-asterisk fa-5x"></i-->
        
            <input type="hidden" class="form-control" readonly="readonly" name="from" id="from" value="{$name}" />
            
            <div class="form-group form-inline">
            <label for="to" class="control-label">To:</label>
            
            {mess:select-dest($config:editor-group)}
            
            <label for="type" class="control-label">Category:</label>    
            <select name="type" id="type" class="form-control">
                <option value="bell-o">news</option>
                <option value="laptop">upgrade</option>
                <option value="exclamation-triangle">maintenance</option>
                <option value="asterisk">alert</option>
            </select>
            </div>
            <div class="clearfix"/>
            <div class="form-group">
            <label class="control-label" for="message">Messagge</label>
            <textarea class="form-control" name="message" style="min-height:250px">
            </textarea>
            </div>
            <input type="submit" class="btn btn-warning" value="Send" />
        </form>   
    
};

declare function mess:select-dest($group) {
    let $editors:=sm:get-group-members($group)
    return 
        <select name="to" id="to" class="form-control">
        <option value="all">All editors</option>
        {
        for $editor in $editors
        return
        if($editor!='admin') then
            (<option>{$editor}</option>)
        else ()
        }
        </select>
};

(: This function is going to be dismissed :)
declare 
%templates:default("max", "10")
function mess:read($node as node(), $model as map(*), $max as xs:string) {
    
    let $name:=xmldb:get-current-user()
    
    let $path:=if($name='admin') then(
         $config:editor-mess
        )
    else ( $config:admin-mess)
    
     let $sorted-messages :=
        for $message in collection($path)/news
        let $time:=$message/time
        order by $time descending
        return $message 
    
    let $messages:=
        for $message in subsequence($sorted-messages,1,$max)
        let $from:=$message/from
        let $to:=$message/to
        let $time:=$message/time
        let $type:=$message/type
        let $action:=$message/action
        let $mess:=$message/message
        
        let $panel-type:=
                if($type='bell-o') then ('primary')
                else if ($type='laptop') then ('success')
                else if ($type='exclamation-triangle') then ('warning')
                else if ($type='asterisk') then ('danger')
                else if ($type='android') then ('success')
                else ('default')

        let $type-icon:=<i class="fa fa-{$type} fa-3x"></i>
        
        
        where $message/to=$name or $message/to='all'
        
        return
            <div class="panel panel-{$panel-type}">
            
                <div class="panel-heading">
                <span class="lead"><i>from:</i> <b>{$from}</b> -> <i>to:</i> <b>{$to}</b></span>
                <span class="pull-right">{datetime:timestamp-to-datetime($time)}</span> </div>
                <div class="panel-body">
                    <div class="row">
                        <div class="col-sm-2"><p class="text-{$panel-type}">{$type-icon}</p></div>
                        <div class="col-sm-10"><p>{$mess}</p></div>
                    </div>
                </div>
            </div>
    
    return
        <div>{$messages}</div>  
    
};

declare 
function mess:activity-log($node as node(), $model as map(*), $max as xs:string,$seq as xs:string,$messages) {
    
    let $name:=xmldb:get-current-user()
    
    let $path:=mess:interface-path($name)
    
    let $sorted-messages :=mess:first-sort-by-time($path)
    
    let $sequence:=if($seq="true") then(subsequence($sorted-messages,1,$max))
    else ($sorted-messages)
    
    let $filtered-messages:=mess:filter-by-name-all($sequence)
    return 
        $filtered-messages
};

declare
%templates:default("max", "10")
%templates:default("seq","true")
function mess:log-as-table($node as node(), $model as map(*), $max as xs:string,$seq as xs:string, $messages){
    let $log:=mess:activity-log($node, $model,$max,$seq,$messages)
    let $messages:= for $message in $log
        return
            <tr class="{mess:mess-class($message/type)}">
                <td>{$message/from}</td>
                <td>{$message/to}</td>
                <td>{$message/action}</td>
                <td>{datetime:timestamp-to-datetime($message/time)}</td>
                <td>{$message/message}</td>
            </tr>
    
    return
        <table class="table table-hover table-striped table-condensed">{$messages}</table> 
    
};

declare function mess:filter-by-name-all($sequence){
    let $name:=xmldb:get-current-user()
    let $messages:=
        for $message in $sequence
        where $message/to=$name or $message/to='all'
        return
            $message
    return
        $messages
    
};

declare function mess:interface-path($name as xs:string){
    
    let $path:=if($name='admin') then(
         $config:editor-mess
        )
    else ( $config:admin-mess)
    return
        $path
};

declare function mess:mess-class($type as xs:string){
    let $class:=
        if($type='bell-o') then ('primary')
        else if ($type='laptop') then ('success')
        else if ($type='exclamation-triangle') then ('warning')
        else if ($type='asterisk') then ('danger')
        else if ($type='android') then ('success')
        else ('default')
    return
        $class
};

declare function mess:first-sort-by-time($path as xs:string){
    let $sorted-messages :=
        for $message in collection($path)/news
        let $time:=$message/time
        order by $time descending
        return $message 
    return
        $sorted-messages
};

(: Write from Admin/System :)
declare function mess:write($from as xs:string, $to as xs:string, $action as xs:string, $message as node()) {
    
    let $path:=if($from!='admin') then(
         $config:editor-mess
        )
    else ( $config:admin-mess)
    
    let $date:=datetime:timestamp()
    let $file_name:=$date||".xml"
    
    let $data:=<news><from>{$from}</from><to>{$to}</to><type>android</type><action>{$action}</action><time>{$date}</time>{$message}</news>
    
    return
         xmldb:store($path, $file_name, $data)  
    
};

(: write generic :)
declare function mess:pwrite($node as node(), $model as map(*)) {
    let $from := request:get-parameter("from", '') 
    let $to := request:get-parameter("to", '') 
    let $type := request:get-parameter("type", '') 
    let $message := request:get-parameter("message", '') 
    
    let $path:=if($from!='admin') then(
         $config:editor-mess
        )
    else ( $config:admin-mess)
    
    let $date:=datetime:timestamp()
    let $file_name:=$date||".xml"
    
    let $data:=<news><from>{$from}</from><to>{$to}</to><type>{$type}</type><time>{$date}</time><message>{$message}</message></news>
    
    let $fwrite:=xmldb:store($path, $file_name, $data)
    return
         (:xmldb:store($path, $file_name, $data) :)
         <p class="lead text-center">Message sent to {$to}</p>

    
};

