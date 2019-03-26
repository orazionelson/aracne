$(document).ready(function() {
    $('.json2Table').each(function(index){
        var json=$(this).text();
        var data = JSON.parse(json);
        var header=data[0];

        var table_header;
        var table_footer;
        var x=0;
        while(header[x]){
            table_header+='<th>'+header[x].val+'</th>';
            table_footer+='<td>'+header[x].val+'</td>';
        x++;
        }
        
        var table_body;
        var y=1;
        while(data[y]){
           var z=0;
           table_body+='<tr>';
           
           while(data[y][z]){
               table_body+='<td class="row_'+y+'_cell_'+z+'">';
               table_body+=data[y][z].val;
               table_body+='</td>';
            z++   
           }
           
           table_body+='</tr>'; 
        
        y++    
        }
        
        
        $(this)
            .after('<table id="table_'+index+'" class="table table-striped table-hover jsontotable"/>')
            .next()
            .append("<thead/>")
            .append("<tfoot/>")
            .append("<tbody/>");
        
        $(this).next().find('thead,tfoot').append('<tr/>');
        $(this).next().find('thead tr').append(table_header);
        $(this).next().find('tfoot tr').append(table_footer);
        $(this).next().find('tbody').append(table_body);
    });
});