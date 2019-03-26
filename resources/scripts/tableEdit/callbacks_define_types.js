jQuery(document).ready(function($){

    if( !$.TableEdit ) return;

    $.TableEdit.plugin = {

        '_getSettingsFromCell': function( params ) {
            if( params.$element.attr('rowspan') ) params.attr.rowspan = +params.$element.attr('rowspan');
            if( params.$element.attr('colspan') ) params.attr.colspan = +params.$element.attr('colspan');
            return params.attr;
        },

        'convertTableToArray': function( selector, search ) {
            params = {
               selector: selector,
               search: search,
               rows: [],
               row: null,
               cell: null,
            }
            return this.doMethod('_convertTableToArray', params);
        },

        '_convertTableToArray': function( params ) {
            var that = this;
            $( params.selector ).find( params.search ).each(function() {
                params.row = [];
                $(this).find('th,td').each(function() {
                    params.cell = {
                        'val': $(this).html(),
                        'attr': that.doMethod('_getSettingsFromCell', {'$element': $(this), attr: {}})
                    };
                    if( $.isEmptyObject(params.cell.attr) ) delete params.cell.attr;
                    params.row.push( params.cell );
                });
                params.rows.push( params.row );
            });
            return params.rows;
        }

    };

    $.TableEdit.callbacks.refresh();

    $.TableEdit.callbacks.defineTypeAfter = function(params) {
        
        if( this.dataTableObject.tbodyArray.length ) return true;

        // from textarea
        if( $(params.selector).is('textarea') ) {
            try {
                var data = JSON.parse($(params.selector).val());
                if( Array.isArray( data ) ) {
                    this.dataTableObject.tbodyArray = data;
                }
                else {
                    if( data.theadArray ) this.dataTableObject.theadArray = data.theadArray;
                    if( data.tbodyArray ) this.dataTableObject.tbodyArray = data.tbodyArray;
                    if( data.tfootArray ) this.dataTableObject.tfootArray = data.tfootArray;
                }
                // this.dataTbodyArray = JSON.parse($(params.selector).val());
                return true;
            } catch (e) {
                console.error(e);
                this.dataTableObject.tbodyArray = this.dataTableDefaultArray;
            }
        }

        // from table
        if( $(params.selector).is('table') ) {
            try {
                this.dataTableObject.theadArray = this.convertTableToArray( params.selector, 'thead > tr' );
                this.dataTableObject.tbodyArray = this.convertTableToArray( params.selector, 'tbody > tr' );
                this.dataTableObject.tfootArray = this.convertTableToArray( params.selector, 'tfoot > tr' );
                if( this.dataTableObject.tbodyArray.length ) return true;
            } catch (e) {
                console.error(e);
                this.dataTableObject.tbodyArray = this.dataTableDefaultArray;
            }
        }

        return true;
    };

    $.TableEdit.callbacks.addTableAfter = function( obj ) {
        if( $(obj.selector).is('table') ) $(obj.selector).addClass('hidden');
        return true;
    };

});
