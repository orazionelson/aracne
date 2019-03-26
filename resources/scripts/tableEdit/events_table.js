jQuery(document).ready(function($){

    if( !$.TableEdit ) return;

    $.TableEdit.plugin = {

        '_eventsBind': function() {
            var $table = $( this.table );
            var $tbody = $( this.tbody );
            var $tfoot = $( this.tfoot );
            var $thead = $( this.thead );

            if( ! this.uniqueID ) this.uniqueID = this.getNumOfCols() + this.getGroup('B').length + Math.floor(Math.random() * 900 + 100);

            $thead.on(
                'click._addRow',
                '.addrow',
                this,
                function(e) {
                    e.data.addNewRows({
                        'scene': $(this).closest('tr').index(),
                        'group': 'H', // coz event for thead
                        'td': 'th'
                    });
                }
            );

            $tbody.on(
                'click._addRow',
                '.addrow',
                this,
                function(e) {
                    e.data.addNewRows({
                        'scene': $(this).closest('tr').index(),
                        'group': 'B' // coz event for tbody
                    });
                }
            );

            $tfoot.on(
                'click._addRow',
                '.addrow',
                this,
                function(e) {
                    e.data.addNewRows({
                        'scene': $(this).closest('tr').index(),
                        'group': 'F', // coz event for tfoot
                        'td': 'th'
                    });
                }
            );

            $thead.on(
                'click._delRow',
                '.delrow',
                this,
                function(e) {
                    e.data.deleteSomeRows({
                        'scene': $(this).closest('tr').index(),
                        'group': 'H' // coz event for thead
                    });
                }
            );

            $tbody.on(
                'click._delRow',
                '.delrow',
                this,
                function(e) {
                    e.data.deleteSomeRows({
                        'scene': $(this).closest('tr').index(),
                        'group': 'B' // coz event for tbody
                    });
                }
            );

            $tfoot.on(
                'click._delRow',
                '.delrow',
                this,
                function(e) {
                    e.data.deleteSomeRows({
                        'scene': $(this).closest('tr').index(),
                        'group': 'F' // coz event for tfoot
                    });
                }
            );

            $thead.on(
                'click._addCol',
                '.addCol',
                this,
                this.addCol
            );

            $tfoot.on(
                'click._addCol',
                '.addCol',
                this,
                this.addCol
            );

            $thead.on(
                'click._delCol',
                '.delCol',
                this,
                this.delCol
            );

            $tfoot.on(
                'click._delCol',
                '.delCol',
                this,
                this.delCol
            );

            $thead.on(
                'dblclick._editCell',
                'td[data-real-index],th[data-real-index]',
                this,
                this.editingStart
            );

            $tbody.on(
                'dblclick._editCell',
                'td[data-real-index],th[data-real-index]',
                this,
                this.editingStart
            );

            $tfoot.on(
                'dblclick._editCell',
                'td[data-real-index],th[data-real-index]',
                this,
                this.editingStart
            );

            $('body').on(
                'click._editCell contextmenu._editCell',
                this,
                function(e) {
                    if( e.data.cache && e.data.cache.isEditCell && ! $(e.target).closest('.edit-cell').length ) {
                        var group = e.data.cache.editableCell.parent().parent().prop('nodeName').toLowerCase();
                        e.data.cache.isEditCell = false;
                        $( e.data.table ).trigger('cell:editing:stop', {
                            'that': e.data,
                            'target': e.data.cache.editableCell,
                            'group': group
                        });
                    }
                }
            );

            $table.on(
                'cell:editing:start',
                this.cellEditingStart
            );

            $table.on(
                'cell:editing:stop',
                this.cellEditingStop
            );

        },
        
        'editingStart': function( e, extra ) {
            var $this = $(this);
            var that = e.data;
            if( that.cache && that.cache.editableCell && that.cache.isEditCell && that.cache.editableCell.is( $this ) ) return;
            if(! that.cache ) that.cache = {};
            that.cache.editableCell = $this;
            that.cache.isEditCell = true;
            var group = e.delegateTarget.nodeName.toLowerCase();
            $( that.table ).trigger('cell:editing:start', {
                'that': that,
                'target': $this,
                'group': group,
                'extra': extra,
            });
        },

        'addCol': function(e) {
            var thisColIndex = $(this).closest('td').index();
            e.data.addNewCols({'scene':thisColIndex});
        },

        'delCol': function(e) {
            var thisColIndex = $(this).closest('td').index();
            e.data.deleteSomeCols({'scene':thisColIndex});
        },

        'cellEditingStart': function( event, object ) {
            var rowIndex = +object.target.closest('tr').index();
            if( object.target.closest('tr').parent().is('thead') ) {
                rowIndex -= object.target.closest('tr').parent().find('tr[data-controls]').length;
            }
            var that = object.that,
                params = {
                    'condition': true,
                    'event': event,
                    '$target': object.target,
                    'group': object.group,
                    'extra': object.extra,
                    'data': that.getGroup( object.group ),
                    'rowIndex': rowIndex,
                    'colIndex': +object.target.attr('data-real-index'),
                    'targetOffset': object.target.offset(),
                    'content': function( html ) {
                        return html;
                    },
                    '$targetCss': {
                        'height': function() {
                            return object.target.height();
                        }
                    },
                    '$menuContainer': $('body'),
                    '$menuContent': $('' +
                        '<div class="edit-cell edit-cell-content" data-group="'+ object.group +'" data-row="'+ rowIndex +'" data-col="'+ object.target.attr('data-real-index') +'" data-uniq="'+ that.uniqueID +'">' +
                            // '<button type="button" class="btn btn-default btn-xs edit-cell" data-toggle="modal" data-target="#TableEditModal"><span class="glyphicon glyphicon-pencil"></span></button>' +
                        '</div>' +
                    ''),
                    '$menuCss': {
                        'top': function() {
                            return params.targetOffset.top - 1;
                        },
                        'left': function() {
                            if( that.controlOrientation == 'right' )
                                return (params.targetOffset.left + object.target.outerWidth(true) + 1);
                            return (params.targetOffset.left - $(this).outerWidth(true) - 1);
                        },
                        'min-height': object.target.outerHeight(true) + 2,
                    }
                };
                params.$targetContent = $('<textarea/>', {text: function() {
                    return params.content( object.target.html(), params );
                }});
            that.doMethod('_cellEditingStart', params);
        },

        '_cellEditingStart': function( params ) {
            if( params.condition === false ) return;
            params.$target.html( params.$targetContent.css( params.$targetCss ) )
            .addClass('edit-cell')
            .find( params.$targetContent ).focus(function(){
                var $thisVal = $(this).val();
                $(this).val('').val($thisVal);
            }).focus();
            params.$menuContainer.append( params.$menuContent );
            params.$menuContent.css( params.$menuCss );
        },

        'cellEditingStop': function( event, object ) {
            var rowIndex = +object.target.closest('tr').index();
            if( object.target.closest('tr').parent().is('thead') ) {
                rowIndex -= object.target.closest('tr').parent().find('tr[data-controls]').length;
            }
            var that = object.that,
                params = {
                    'condition': true,
                    'event': event,
                    '$target': object.target,
                    'rowIndex': rowIndex,
                    'colIndex': +object.target.attr('data-real-index'),
                    'group': object.group,
                    'formElement': 'textarea'
                };
            params.newValue = object.target.find( params.formElement ).val();
            that.doMethod('_cellEditingStop', params);
        },

        '_cellEditingStop': function( params ) {
            if( params.condition === false ) return;
            this.saveBackCell( params.rowIndex, params.colIndex, 'val', params.newValue, params.group );
            params.$target.html( params.newValue ).removeClass('edit-cell');
            $('body').find( '.edit-cell-content' ).remove();
        },

    };

    $.TableEdit.init = function() {
        this.doMethod('_eventsBind');
    };

});
