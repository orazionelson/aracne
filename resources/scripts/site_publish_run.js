var steps = ['one','two','three','four','five','six','seven','eight'];

function deferredPost(index, max,id){    
    var delay = Math.random()*100000;
    var target='site_publish_response.html?id='+id+'&step='+steps[index];
    var responsebox='#response .site.build.step.';
    var step=steps[index];
    var position=responsebox+step;
    
    
    if (index<max){
        return $.post(
            target, 
            {delay:delay}, 
            function(data){
                $('body').find(position).show().empty().append(data);
            })
        .then(function(){
                deferredPost(index+1, max,id);
        });
    } else {
        return $.post(
            target, 
            {delay:delay}, 
            function(data){
                $('body').find(position).show().empty().append(data);
        });
    }
}

