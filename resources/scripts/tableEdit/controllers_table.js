jQuery(document).ready(function($){

    if( !$.TableEdit ) return;

    $.TableEdit.plugin = {

        /**
         * 
         * @@ this method use @toLowerCase
         * return an actual name of group like Element.nodeName
         */
        'provideGroup': function( group ) {
            switch( group.toLowerCase() ) {
                case 'tbodyarray':
                // short aliases
                case 'tbody': case 'b':
                 return 'tbody';
                  break;

                case 'theadarray':
                // short aliases
                case 'thead': case 'h':
                 return 'thead';
                  break;

                case 'tfootarray':
                // short aliases
                case 'tfoot': case 'f':
                 return 'tfoot';
                  break;

                default:
                 console.error('failed to provide ' + group);
            }
        },

        /**
         * 
         * @@ this method use @toLowerCase
         * return an actual link to HTML Element
         */
        'getNodeGroup': function( group ) {
            switch( group.toLowerCase() ) {
                case 'tbodyarray':
                // short aliases
                case 'tbody': case 'b':
                 return this.tbody;
                  break;

                case 'theadarray':
                // short aliases
                case 'thead': case 'h':
                 return this.thead;
                  break;

                case 'tfootarray':
                // short aliases
                case 'tfoot': case 'f':
                 return this.tfoot;
                  break;

                default:
                 console.error('failed to define ' + group);
            }
        },

        /**
         * 
         * @group - must be actual link to data // use method @getGroup before call
         * return object contain @rowIndex, @colIndex, @cell
         */
        'getParent': function( group, rowIndex, colIndex ) {
            var checkedCell;
            while( true ) {
                checkedCell = group[ +rowIndex ][ +colIndex ];
                if( checkedCell.mx == 1 ) {
                    return {
                        // absolute link on rowIndex in matrix
                        'rowIndex': rowIndex,

                        // same on colIndex
                        'colIndex': colIndex,

                        // back-end cell
                        'cell': checkedCell,
                    }
                    break; // just
                }
                if( checkedCell.mx == 4 ) {
                    rowIndex--;
                    colIndex--;
                    continue;
                }
                if( checkedCell.mx == 2 ) {
                    colIndex--;
                    continue;
                }
                if( checkedCell.mx == 3 ) {
                    rowIndex--;
                    continue;
                }
            }
        },

        'addNewRows': function( options ) {
            var o = {
                    'condition': true,
                    'count':     1,
                    'direction': 'bottom',
                    'scene':     0,         // front index
                    'shiftIndex':0,         // data index    
                    'group':     '',
                    'data':      null,
                    'newRow':    undefined, // array must (one row only)
                    'td':        '',
                };
            $.extend(true, o, options);
            if( o.direction === 'bottom' ) o.scene += 1;
            o.shiftIndex = o.scene;

            if( this.getNodeGroup( o.group ).nodeName.toLowerCase() == 'thead' )
                o.shiftIndex -= this.thead.querySelectorAll('tr[data-controls]').length;

            o.data = this.getGroup( o.group );
            o.checkedRow = o.data[ o.shiftIndex ];
            while( o.count-- > 0 ) {
                if( o.newRow === undefined ) o.newRow = new Array( this.getNumOfCols() );
                this.doMethod('_addNewRow', o);
            }
        },

        '_addNewRow': function( o ) {
            if( o.condition === false ) return;
            for( var col = 0; col < o.newRow.length; col++ ) {
                if( o.checkedRow !== undefined && ( o.checkedRow[col].mx == 3 || o.checkedRow[col].mx == 4 ) ) {
                    o.newRow[col] = {'mx': o.checkedRow[col].mx};
                    if( o.checkedRow[col].mx == 3 ) {
                        this.doMethod('_correctCell', {
                            'rowIndex': (o.shiftIndex - 1),
                            'colIndex': col,
                            'correct': 1,
                            'property': 'rowspan',
                            'group': o.group
                        });
                    }
                }
                else {
                    o.newRow[col] = this.newCell( o.newRow[ col ], {'group': o.group, 'rowIndex': o.shiftIndex, 'colIndex': col} );
                }
            }
            o.data.splice( o.shiftIndex, 0, o.newRow );
            var add = this.doMethod('_getFrontRow', {'rowIndex': o.shiftIndex, 'group': o.group});
            if( add !== undefined ) {
                $( add ).before( this.doMethod('_createRow', {'tr':this.createEL('tr'),'row':o.data[o.shiftIndex],'index':o.shiftIndex,'group':o.data,'td':o.td}) );
            }
            else {
                this.getNodeGroup( o.group ).appendChild( this.doMethod('_createRow', {'tr':this.createEL('tr'),'row':o.data[o.shiftIndex],'index':o.shiftIndex,'group':o.data,'td':o.td}) );
            }
        },

        /**
         * 
         * @param   object   initial  Input for the new cell.
         * @param   object   options  Options passed to work with cell.
         * 
         * @return  object   New cell.
         */
        'newCell': function( initial, options ) {

            var params = {
                'group': undefined,
                'rowIndex': undefined,
                'colIndex': undefined,
            };

            // ? need copy cell : new obj
            if( options.copy === undefined || options.copy === true ) {
                params.cell = ( initial ? $.extend( true, {}, initial ) : {} );
            }
            else {
                params.cell = ( initial ? initial : {} );
            }

            $.extend( true, params, options || {} );

            return this.doMethod('_newCell', params);
        },

        /**
         *  
         * @return  object  New cell
         */
        '_newCell': function( params ) {
            if( ! params.cell.hasOwnProperty('val') ) params.cell.val = '';
            return params.cell;
        },

        /**
         * 
         * @group
         * @rowIndex
         * @colIndex
         * @correct
         * @property
         * 
         */
        '_correctCell': function( params ) {
            var parent = this.getParent( this.getGroup( params.group ), params.rowIndex, params.colIndex );
            var node = this.doMethod('_getFrontCell', {'row': parent.rowIndex, 'col': parent.colIndex, 'group': params.group});

            parent.cell.attr[ params.property ] += params.correct;
            this.attr( node,
                params.property,
                (+this.attr( node, params.property ) + params.correct)
            );
        },

        /**
         * This method shift cell & reduce col or rowspan
         * 
         * @group {string}
         * @rowIndex {number}
         * @colIndex {number}
         * @direction {string}
         * 
         */
        'shiftCell': function( group, rowIndex, colIndex, direction, count ) {
            return this.doMethod('_shiftCell', {

                'group': group,
                'rowIndex': +rowIndex,
                'colIndex': +colIndex,
                'direction': direction,

            });
        },

        '_shiftCell': function( params ) {

            var data = this.getGroup( params.group ),

                movable, wanted,
                rowIndex, colIndex;

            if( params.direction === 'rowspan' ) {
                data[ params.rowIndex ][ params.colIndex ].attr.rowspan -= 1;
                data[ params.rowIndex + 1 ][ params.colIndex ] = $.extend( true, {}, data[ params.rowIndex ][ params.colIndex ] );
                movable = this.doMethod('_getFrontCell', {'row': params.rowIndex, 'col': params.colIndex, 'group': params.group});
                wanted = this.doMethod('_getFrontCell', {'row': (params.rowIndex + 1), 'col': (params.colIndex + (+this.attr( movable, 'colspan' ) || 1)), 'group': params.group});
                if( wanted == undefined ) {
                    if( this.controlOrientation == 'right' ) {
                        $( this.doMethod('_getFrontRow', {'rowIndex': (params.rowIndex + 1), 'group': params.group}) )
                            .find('td:not([data-real-index])')
                            .before( this.attr( movable, 'rowspan', (+this.attr( movable, 'rowspan' ) - 1) ) );
                    }
                    else {
                        this.doMethod('_getFrontRow', {'rowIndex': (params.rowIndex + 1), 'group': params.group}).
                            appendChild( this.attr( movable, 'rowspan', (+this.attr( movable, 'rowspan' ) - 1) ) );
                    }
                }
                else {
                    $( wanted ).before( this.attr( movable, 'rowspan', (+this.attr( movable, 'rowspan' ) - 1) ) );
                }

                colIndex = params.colIndex;
                while( data[ params.rowIndex ][ ++colIndex ] && data[ params.rowIndex ][ colIndex ].mx == 2 ) {

                    data[ params.rowIndex + 1 ][ colIndex ].mx = 2;

                }
            }

            if( params.direction === 'colspan' ) {
                data[ params.rowIndex ][ params.colIndex ].attr.colspan -= 1;
                data[ params.rowIndex ][ params.colIndex + 1 ] = $.extend( true, {}, data[ params.rowIndex ][ params.colIndex ] );
                wanted = this.doMethod('_getFrontCell', {'row': params.rowIndex, 'col': params.colIndex, 'group': params.group});
                this.attr( wanted, 'colspan', (+this.attr( wanted, 'colspan') - 1) );

                rowIndex = params.rowIndex;
                while( data[ ++rowIndex ] && data[ rowIndex ][ params.colIndex ] && data[ rowIndex ][ params.colIndex ].mx == 3 ) {

                    data[ rowIndex ][ params.colIndex + 1 ].mx = 3;

                }
            }

        },

        'deleteSomeRows': function( options ) {
            var result = [], // will contain deleted rows
                o = {
                    'condition':    true,
                    'count':        1,
                    'direction':    'bottom',
                    'scene':        0,
                    'group':        '',
                    'data':         null,
                    'pullOutIndex': 0,
                    'pullOutRow':   null,
                    'nextRow':      null,
                    'deleted':      null,
                };
            $.extend(true, o, options);
            o.pullOutIndex = o.scene;

            if( this.getNodeGroup( o.group ).nodeName.toLowerCase() == 'thead' )
                o.pullOutIndex -= $( this.thead ).find('tr[data-controls]').length;

            o.data = this.getGroup( o.group );
            while( o.count-- > 0 && o.data[ o.pullOutIndex ] !== undefined ) {
                o.pullOutRow = o.data[ o.pullOutIndex ];
                o.nextRow = o.data[ o.pullOutIndex + 1 ];
                result.push( this.doMethod('_deleteRow', o) );
            }

            return result;
        },

        '_deleteRow': function( o ) {
            if( o.condition === false ) return;
            for( var col = 0; col < o.pullOutRow.length; col++ ) {
                if( o.pullOutRow[ col ].hasOwnProperty('attr') && o.pullOutRow[ col ].attr.hasOwnProperty('rowspan') && o.pullOutRow[ col ].attr.rowspan > 1 ) {

                    this.shiftCell( o.group, o.pullOutIndex, col, 'rowspan' );
                }
                if( o.pullOutRow[col].mx == 3 ) {
                    this.doMethod('_correctCell', {
                        'rowIndex': o.pullOutIndex,
                        'colIndex': col,
                        'correct': -1,
                        'property': 'rowspan',
                        'group': o.group
                    });
                }
            }
            o.deleted = o.data.splice( o.pullOutIndex, 1 ) /* get first coz count equal one */[0];
            $( this.doMethod('_getFrontRow', {'rowIndex': o.pullOutIndex, 'group': o.group}) ).remove();
            if( o.count && o.direction === 'top' ) o.pullOutIndex--;
            return o.deleted;
        },

        'addNewCols': function( options ) {
            var o = {
                    'condition': true,
                    'count': 1,
                    'scene': 0,
                    'part': true,
                    'newCol': {
                        'thead': undefined,
                        'tfoot': undefined,
                        'tbody': undefined
                    },
                    'checkedCell': null,
                    'rowIndex': 0,
                    'group': '',
                    'data': null,
                    'tr': null,
                    'td': ''
                };
            $.extend(true, o, options);
            while( o.count-- > 0 ) {
                this.doMethod('_addNewColumn', o);
            }
        },

        '_addNewColumn': function( o ) {
            if( o.condition === false ) return;
            this._numberOfColumns += 1;
            var method = this.controlOrientation == 'left' ? 'after' : 'before';
            $( this.thead ).find('tr[data-controls]').find('td').eq( o.scene )[ method ]( this.html( this.createEL('td'), this.topControlsElements ) );
            $( this.tfoot ).find('tr[data-controls]').find('td').eq( o.scene )[ method ]( this.html( this.createEL('td'), this.bottomControlsElements ) );
            var row, length, groups = {
                'thead': 'th',
                'tfoot': 'th',
                'tbody': 'td'
            };
            for( var group in groups ) {
                o.group = group;
                o.data = this.getGroup( o.group );
                if( o.newCol[ o.group ] === undefined ) o.newCol[ o.group ] = new Array( o.data.length );
                o.td = groups[ o.group ];
                if( o.part && this.hasOwnProperty('maxRowsOutDelay') && o.newCol.length > this.maxRowsOutDelay ) {
                    this.addNewDelayedCols( o );
                }
                else {
                    for( row = 0, length = o.newCol[ o.group ].length; row < length; row++ ) {
                        o.checkedCell = o.data[ row ][ o.scene ];
                        o.rowIndex = row;
                        o.tr = this.doMethod('_getFrontRow', {'rowIndex': o.rowIndex, 'group': o.group});
                        this.doMethod('_addNewCol', o);
                    }
                }
            }
        },

        'addNewDelayedCols': function( o ) {
            if(! this.hasOwnProperty('howCreateOnce')) return;
            var that = this,
                times = Math.ceil( o.newCol[ o.group ].length / this.howCreateOnce ),
                interation = 0;
            setTimeout(function generateCol(){
                var save = that.howCreateOnce * interation,
                    length = (o.newCol[ o.group ].length - save) < that.howCreateOnce ? o.newCol[ o.group ].length - save : that.howCreateOnce;
                for( var row = 0; row < length; row++ ) {
                    o.checkedCell = o.data[ (row + save) ][ o.scene ];
                    o.rowIndex = (row + save);
                    o.tr = that.doMethod('_getFrontRow', {'rowIndex': o.rowIndex, 'group': o.group});
                    that.doMethod('_addNewCol', o);
                }
                if( ++interation < times ) {
                    setTimeout(generateCol,0);
                }
                else {
                    this.doAction('addNewColumnAfter', o);
                }
            },0);
        },

        '_addNewCol': function( o ) {
            if( o.checkedCell !== undefined && (o.checkedCell.mx == 2 || o.checkedCell.mx == 4) ) {
                if( o.newCol[ o.group ][ o.rowIndex ] === undefined || o.newCol[ o.group ][ o.rowIndex ].mx === undefined ) {
                    o.newCol[ o.group ][ o.rowIndex ] = {'mx': o.checkedCell.mx};
                }
                if( o.checkedCell.mx == 2 ) {
                    this.doMethod('_correctCell', {'rowIndex':o.rowIndex,'colIndex':o.scene,'correct':1,'property':'colspan','group':o.group});
                }
            }
            else {
                o.newCol[ o.group ][ o.rowIndex ] = this.newCell( o.newCol[ o.group ][ o.rowIndex ], {'group': o.group, 'rowIndex': o.rowIndex, 'colIndex': o.scene} );
            }
            o.data[ o.rowIndex ].splice( o.scene, 0, o.newCol[ o.group ][o.rowIndex] );
            var cell = o.data[ o.rowIndex ][ o.scene ];
            var that = this;
            $( o.tr ).find('td[data-real-index],th[data-real-index]').each(function(){
                if( that.attr( this, 'data-real-index' ) >= o.scene )
                    that.attr( this, 'data-real-index', (+that.attr( this, 'data-real-index' ) + 1) );
            });
            if( cell.mx && cell.mx > 1 ) return; // exit if no need to create front cell

            var d = o.scene;
            while( --d >= 0 ) { // shift to left
                // try to find close left parent cell
                if( o.data[ o.rowIndex ][ d ].mx == 1 ) break;
            }
            if( d >= 0 ) {
                var destination = this.doMethod('_getFrontCell', {'row': o.tr, 'col': d, 'group': o.group});
                if( destination !== undefined ) {
                    $( destination ).after( this.createCell( o.tr, o.data[o.rowIndex], cell, o.rowIndex, o.scene, o.data, o.td ) );
                }
            }
            if( d == -1 && this.controlOrientation == 'right' ) $( o.tr ).prepend( this.createCell( o.tr, o.data[o.rowIndex], cell, o.rowIndex, o.scene, o.data, o.td ) );
            else if( d == -1 && this.controlOrientation == 'left' ) {
                var destination = $( o.tr ).find('td:first');
                if( destination.length ) destination.after( this.createCell( o.tr, o.data[o.rowIndex], cell, o.rowIndex, o.scene, o.data, o.td ) );
                else $( o.tr ).prepend( this.createCell( o.tr, o.data[o.rowIndex], cell, o.rowIndex, o.scene, o.data, o.td ) );
            }
        },

        'deleteSomeCols': function( options ) {
            var result = [], // will contain deleted columns
                o = {
                    'condition':    true,
                    'count':        1,
                    'counter':      0,
                    'scene':        0,
                    'part':         true,
                    'checkedCell':  null,
                    'rowIndex':     0,
                    'pullOutIndex': 0,
                    'group':        '',
                    'data':         null,
                    'tr':           null,
                    'deletedColumn':{},
                    'deleted':      null,
                    'getDeleted':   undefined,
                };
            $.extend(true, o, options);
            o.pullOutIndex = o.scene;
            while( o.count-- > 0 ) {
                o.deletedColumn = {};
                result.push( this.doMethod('_deleteColumn', o) );
                if( o.getDeleted && typeof o.getDeleted == 'function' ) {
                    o.getDeleted.call( this, result[ o.counter ] );
                }
                o.counter++;
            }

            return result;
        },

        '_deleteColumn': function( o ) {
            if( o.condition === false ) return;
            this._numberOfColumns -= 1;
            $( this.thead ).find('tr[data-controls]').find('td').eq( o.pullOutIndex ).remove();
            $( this.tfoot ).find('tr[data-controls]').find('td').eq( o.pullOutIndex ).remove();
            if( this.controlOrientation == 'left' ) o.pullOutIndex -= 1;
            var row, length, groups = {
                'thead': 'th',
                'tfoot': 'th',
                'tbody': 'td'
            };
            for( var group in groups ) {
                o.group = group;
                o.data = this.getGroup( o.group );
                o.deletedColumn[ o.group ] = new Array( o.data.length );
                if( o.part && o.group === 'tbody' && this.hasOwnProperty('maxRowsOutDelay') && o.data.length > this.maxRowsOutDelay ) {
                    this.deleteDelayedCols( o );
                }
                else {
                    for( row = 0, length = o.data.length; row < length; row++ ) {
                        o.checkedCell = o.data[ row ][ o.pullOutIndex ];
                        o.rowIndex = row;
                        o.tr = this.doMethod('_getFrontRow', {'rowIndex': o.rowIndex, 'group': o.group});
                        o.deletedColumn[ o.group ][ row ] = this.doMethod('_deleteCol', o);
                    }
                }
            }

            return o.deletedColumn;
        },

        'deleteDelayedCols': function( o ) {
            if(! this.hasOwnProperty('howCreateOnce')) return;
            var that = this,
                times = Math.ceil( (o.data.length - 1) / this.howCreateOnce ),
                interation = 0,
                deletedColumn = o.deletedColumn,
                i = o.counter;
            setTimeout(function delCol(){
                var save = that.howCreateOnce * interation,
                    length = (o.data.length - save) < that.howCreateOnce ? o.data.length - save : that.howCreateOnce;
                for( var row = 0; row < length; row++ ) {
                    o.tr = that.doMethod('_getFrontRow', {'rowIndex': (row + save), 'group': o.group});
                    o.checkedCell = o.data[ (row + save) ][ o.pullOutIndex ];
                    o.rowIndex = (row + save);
                    deletedColumn[ o.group ][ (row + save) ] = that.doMethod('_deleteCol', o);
                }
                if( ++interation < times ) {
                    setTimeout(delCol,0);
                }
                else {
                    o.deletedColumn = $.extend( true, {}, deletedColumn );
                    that.doAction('deleteColumnAfter', o);
                    if( o.getDeleted && typeof o.getDeleted == 'function' ) {
                        o.getDeleted.call( that, deletedColumn, i );
                    }
                }
            },0);
        },

        '_deleteCol': function( o ) {
            var remove = true;
            if( o.checkedCell.hasOwnProperty('attr') && o.checkedCell.attr.hasOwnProperty('colspan') && o.checkedCell.attr.colspan > 1 ) {

                this.shiftCell( o.group, o.rowIndex, o.pullOutIndex, 'colspan' );
                remove = false;
            }
            if( o.checkedCell.mx == 2 ) {
                this.doMethod('_correctCell', {'rowIndex':o.rowIndex,'colIndex':o.pullOutIndex,'correct':-1,'property':'colspan','group':o.group});
                remove = false;
            }
            o.deleted = o.data[ o.rowIndex ].splice( o.pullOutIndex, 1 ) /* get first coz count equal one */[0];
            if( remove ) $( this.doMethod('_getFrontCell', {'row': o.tr, 'col': o.pullOutIndex, 'group': o.group}) ).remove();
            var that = this;
            $( o.tr ).find('td[data-real-index],th[data-real-index]').each(function(){
                if( that.attr( this, 'data-real-index' ) > o.pullOutIndex )
                    that.attr( this, 'data-real-index', (+that.attr( this, 'data-real-index') - 1) );
            });
            return o.deleted;
        },

        /**
         * 
         * @@ Method use jQuery extend( true ) for deep extends
         * 
         * @rowIndex - 
         * @colIndex - 
         * @saving - string separate .(dot) / will convert to array for callback
         * @newValue - 
         * @group - string for define chain in @dataTableObject
         * 
         * return ?
         */
        'saveBackCell': function( rowIndex, colIndex, saving, newValue, group ) {
            var chain = saving.split('.');
            this.doMethod('_saveBackCell', {
                'rowIndex': rowIndex,
                'colIndex': colIndex,
                'saving': chain,
                'newValue': newValue,
                'group': ( typeof group === 'string' ) ? this.getGroup( group ) : group,
            });
        },

        '_saveBackCell': function( params ) {
            var tmp = [],
                o = {};
            for(var i = params.saving.length - 1, lastKey = params.saving.length - 1; i >= 0; i--  ) {
                var a = {};
                if( i == lastKey ) {
                    a[ params.saving[i] ] = params.newValue;
                    tmp.push( a );
                } else {
                    var b = tmp.pop();
                    a[ params.saving[i] ] = b;
                    tmp.push( a );
                }
            }
            o = tmp.pop();
            
            $.extend(true, params.group[ params.rowIndex ][ params.colIndex ], o);
            //var nv=JSON.stringify(params.group);
            //console.log(nv);
        },

        /**
         * @group - 
         * @rowIndex - 
         * @@ stabilize - this method will 
         * return HTML Element 
         */
        '_getFrontRow': function( params ) {
            if( params.group.nodeName ) {
                if( params.group.nodeName.toLowerCase() === 'thead' ) {
                    params.rowIndex += params.group.querySelectorAll('tr[data-controls]').length;
                }
                return params.tr = params.group.rows[ +params.rowIndex ];
            }

            if( params.group instanceof jQuery ) {
                if( params.group.is('thead') ) {
                    params.rowIndex += params.group.find('tr[data-controls]').length;
                }
                return params.tr = params.group.find('tr').eq( +params.rowIndex )[ 0 ];
            }

            if( typeof params.group === 'string' ) {
                if( this.provideGroup(params.group) === 'thead' ) {
                    params.rowIndex += this.getNodeGroup( params.group ).querySelectorAll('tr[data-controls]').length;
                }
                return params.tr = this.getNodeGroup( params.group ).rows[ +params.rowIndex ];
            }

            if( Array.isArray( params.group ) ) {
                // so difficult
            }
        },

        /**
         * @group - 
         * @row - ( int || string || jQuery )
         * @col -  
         * return HTML Element 
         */
        '_getFrontCell': function( params ) {
            if( params.row instanceof jQuery ) {
                return params.td = params.row.find('td[data-real-index="'+ +params.col +'"],th[data-real-index="'+ +params.col +'"]')[ 0 ];
            }

            if( params.row.nodeName ) {
                return params.td = params.row.querySelector('td[data-real-index="'+ +params.col +'"],th[data-real-index="'+ +params.col +'"]');
            }

                return params.td = this.doMethod('_getFrontRow', {'rowIndex': params.row, 'group': params.group})
                    .querySelector('td[data-real-index="'+ +params.col +'"],th[data-real-index="'+ +params.col +'"]');

        },

        /**
         * 
         * @group - string
         * @rowIndex - 
         * @colIndex - 
         * @newData - object
         * 
         * return ? 
         */
        'change': function( group, rowIndex, colIndex, newData ) {
            var params = {
                    'group': group,
                    'data': this.getGroup( group ),
                    'rowIndex': +rowIndex,
                    'colIndex': +colIndex,
                    'newData': newData || {},
                    'adding': [],
                    'remove': [],
                    'cell': this.getGroup( group )[ +rowIndex ][ +colIndex ],
                    'stretchError': {
                        'colspan': [],
                        'rowspan': []
                    },
                    'getTune': function( interest, obj, replace ) {
                        replace = replace || 1;
                        return obj.attr && obj.attr[interest] ? +obj.attr[interest] : replace;
                    },
                    'isStretched': function( cell ) {
                        if( cell === undefined ) return true;
                        if( cell.mx && cell.mx > 1 ) return true;
                        if( this.getTune('colspan',cell) > 1 ) return true;
                        if( this.getTune('rowspan',cell) > 1 ) return true;
                        return false;
                    }
                };
            return this.doMethod('_change', params);
        },

        '_change': function( params ) {
            var countCol,
                countRow;

            if( params.newData.hasOwnProperty('attr') ) {
                if( params.newData.attr.hasOwnProperty('colspan') && params.getTune('colspan',params.newData) < params.getTune('colspan',params.cell) ) {
                    countCol = params.getTune('colspan',params.cell) - params.getTune('colspan',params.newData);
                    countRow = params.getTune('rowspan',params.cell);
                    for( var row = 0; row < countRow; row++ ) {
                        for( var col = 0; col < countCol; col++ ) {
                            params.adding.push({
                                'group': params.group,
                                'rowIndex': (params.rowIndex + row),
                                'colIndex': (params.colIndex + params.getTune('colspan',params.cell) - 1 - col),
                                'cell': params.data[ (params.rowIndex + row) ][ (params.colIndex + params.getTune('colspan',params.cell) - 1 - col) ],
                            });
                        }
                    }
                }
                if( params.newData.attr.hasOwnProperty('rowspan') && params.getTune('rowspan',params.newData) < params.getTune('rowspan',params.cell) ) {
                    countCol = params.getTune('colspan',params.cell) - params.getTune('colspan',params.newData) > 0 ? params.getTune('colspan',params.newData) : params.getTune('colspan',params.cell);
                    countRow = params.getTune('rowspan',params.cell) - params.getTune('rowspan',params.newData);
                    for( var row = 0; row < countRow; row++ ) {
                        for( var col = 0; col < countCol; col++ ) {
                            params.adding.push({
                                'group': params.group,
                                'rowIndex': (params.rowIndex + params.getTune('rowspan',params.cell) - 1 - row),
                                'colIndex': (params.colIndex + col),
                                'cell': params.data[ (params.rowIndex + params.getTune('rowspan',params.cell) - 1 - row) ][ (params.colIndex + col) ],
                            });
                        }
                    }
                }
                if( params.newData.attr.hasOwnProperty('colspan') && params.getTune('colspan',params.newData) > params.getTune('colspan',params.cell) ) {
                    countCol = params.getTune('colspan',params.newData) - params.getTune('colspan',params.cell);
                    countRow = params.getTune('rowspan',params.cell) - params.getTune('rowspan',params.newData) > 0 ? params.getTune('rowspan',params.newData) : params.getTune('rowspan',params.cell);
                    for( var row = 0; row < countRow; row++ ) {
                        for( var col = 0; col < countCol; col++ ) {
                            var checkCell = params.data[ (params.rowIndex + row) ][ (params.colIndex + params.getTune('colspan',params.cell) + col) ];
                            params.remove.push({
                                'group': params.group,
                                'rowIndex': (params.rowIndex + row),
                                'colIndex': (params.colIndex + params.getTune('colspan',params.cell) + col),
                                'cell': checkCell,
                            });
                            if( params.isStretched(checkCell) ) {
                                params.stretchError.colspan.push({
                                    'group': params.group,
                                    'rowIndex': (params.rowIndex + row),
                                    'colIndex': (params.colIndex + params.getTune('colspan',params.cell) + col),
                                    'cell': checkCell,
                                });
                            }
                        }
                    }
                }
                if( params.newData.attr.hasOwnProperty('rowspan') && params.getTune('rowspan',params.newData) > params.getTune('rowspan',params.cell) ) {
                    countCol = params.newData.attr.colspan ? params.getTune('colspan',params.newData) : params.getTune('colspan',params.cell);
                    countRow = params.getTune('rowspan',params.newData) - params.getTune('rowspan',params.cell);
                    for( var row = 0; row < countRow; row++ ) {
                        for( var col = 0; col < countCol; col++ ) {
                            var checkCell = params.data[ (params.rowIndex + params.getTune('rowspan',params.cell) + row) ] ? params.data[ (params.rowIndex + params.getTune('rowspan',params.cell) + row) ][ (params.colIndex + col) ] : undefined;
                            params.remove.push({
                                'group': params.group,
                                'rowIndex': (params.rowIndex + params.getTune('rowspan',params.cell) + row),
                                'colIndex': (params.colIndex + col),
                                'cell': checkCell,
                            });
                            if( params.isStretched(checkCell) ) {
                                params.stretchError.rowspan.push({
                                    'group': params.group,
                                    'rowIndex': (params.rowIndex + params.getTune('rowspan',params.cell) + row),
                                    'colIndex': (params.colIndex + col),
                                    'cell': checkCell,
                                });
                            }
                        }
                    }
                }
            }

            if( params.adding.length ) this.doMethod('_handleContraction', params );
            if( params.remove.length ) this.doMethod('_handleStretching', params );
            if( params.newData.hasOwnProperty('val') ) this.doMethod('_handleValueChanging', params );
        },

        '_handleValueChanging': function( params ) {
            if( params.cell.hasOwnProperty('val') && params.cell.val != params.newData.val ) {
                this.saveBackCell( params.rowIndex, params.colIndex, 'val', params.newData.val, params.group );
                params.td = this.html( this.doMethod('_getFrontCell', {'row': params.rowIndex, 'col': params.colIndex, 'group': params.group}), params.newData.val );
            }
        },

        '_handleContraction': function( params ) {
            if( params.stretchError.rowspan.length == 0 && params.stretchError.colspan.length == 0 ) {
                for( var i = 0; i < params.adding.length; i++ ) {
                    var el = params.adding[i];
                    var col = el.colIndex + 1;
                    delete el.cell.mx;
                    this.newCell( el.cell, {'group': el.group, 'rowIndex': el.rowIndex, 'colIndex': el.colIndex, 'copy': false} );
                    var $tr = $( this.doMethod('_getFrontRow', {'rowIndex': el.rowIndex, 'group': params.group}) );
                    do {
                        if( params.data[ el.rowIndex ][ col ] === undefined ) {
                            if( this.controlOrientation === 'left' ) {
                                $tr.append( this.createCell( $tr[0], params.data[el.rowIndex], el.cell, el.rowIndex, el.colIndex, params.data, (this.provideGroup( params.group ) === 'tbody' ? 'td' : 'th') ) );
                                break;
                            }
                            $tr.find('td,th').eq( -1 ).before( this.createCell( $tr[0], params.data[el.rowIndex], el.cell, el.rowIndex, el.colIndex, params.data, (this.provideGroup( params.group ) === 'tbody' ? 'td' : 'th') ) );
                            break;
                        }
                        if( params.data[ el.rowIndex ][ col ].mx == 1 ) {
                            
                            $( this.doMethod('_getFrontCell', {'row': $tr, 'col': col, 'group': params.group}) ).before(
                                this.createCell( $tr[0], params.data[el.rowIndex], el.cell, el.rowIndex, el.colIndex, params.data, (this.provideGroup( params.group ) === 'tbody' ? 'td' : 'th') )
                            );
                            break;
                        }
                    }while( col++ < this._numberOfColumns );
                }
                if( params.getTune('colspan',params.newData) < params.getTune('colspan',params.cell) ) {
                    this.saveBackCell( params.rowIndex, params.colIndex, 'attr.colspan', +params.newData.attr.colspan, params.group );
                    this.attr( this.doMethod('_getFrontCell', {'row': params.rowIndex, 'col': params.colIndex, 'group': params.group}), 'colspan', params.cell.attr.colspan );
                }
                if( params.getTune('rowspan',params.newData) < params.getTune('rowspan',params.cell) ) {
                    this.saveBackCell( params.rowIndex, params.colIndex, 'attr.rowspan', +params.newData.attr.rowspan, params.group );
                    this.attr( this.doMethod('_getFrontCell', {'row': params.rowIndex, 'col': params.colIndex, 'group': params.group}), 'rowspan', params.cell.attr.rowspan );
                }
            }
        },

        '_handleStretching': function( params ) {
            if( params.stretchError.rowspan.length == 0 && params.stretchError.colspan.length == 0 ) {
                for( var i = 0; i < params.remove.length; i++ ) {
                    var el = params.remove[i];
                    this.doMethod('_emptyCell', el.cell);
                    $( this.doMethod('_getFrontCell', {'row': el.rowIndex, 'col': el.colIndex, 'group': params.group}) ).remove();
                    if( el.rowIndex == params.rowIndex ) {
                        el.cell.mx = 2;
                    }
                    else if( el.colIndex == params.colIndex ) {
                        el.cell.mx = 3;
                    }
                    else {
                       el.cell.mx = 4; 
                    }
                }
                if( params.getTune('colspan',params.newData) > params.getTune('colspan',params.cell) ) {
                    this.saveBackCell( params.rowIndex, params.colIndex, 'attr.colspan', +params.newData.attr.colspan, params.group );
                    this.attr( this.doMethod('_getFrontCell', {'row': params.rowIndex, 'col': params.colIndex, 'group': params.group}), 'colspan', params.cell.attr.colspan );
                }
                if( params.getTune('rowspan',params.newData) > params.getTune('rowspan',params.cell) ) {
                    this.saveBackCell( params.rowIndex, params.colIndex, 'attr.rowspan', +params.newData.attr.rowspan, params.group );
                    this.attr( this.doMethod('_getFrontCell', {'row': params.rowIndex, 'col': params.colIndex, 'group': params.group}), 'rowspan', params.cell.attr.rowspan );
                }
            }
        },

        '_emptyCell': function( cell ) {
            for( var key in cell) {
                delete cell[key];
            }
        },

    };

});
