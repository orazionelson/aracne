(function ($, window) {

    'use strict';

    if( ! window.jQuery ) {
        /**
         * This says that loading the plugin must happen after jQuery
         */
        return;
    }

    /**
     * register the object in jQuery framework
     */
    $.TableEdit = {};

    /**
     * Use @defineProperties for our object because
     * we need protected properties to use @setters & @getters methods
     * IE<9 not support @defineProperties!
     */
    Object.defineProperties($.TableEdit, {

        _plugin: {
            value: {

                doAction: function( name, args, context ) {
                    var callbacks = $.TableEdit.callbacks;
                    if( callbacks[name] && callbacks[name].length ) {
                        for(var i = 0; i < callbacks[name].length; i++ ) {
                            var fn = callbacks[name][i],
                                res = fn.apply((context || this),[args,callbacks[name],i,name]);
                            if(!res) break;
                        }
                    }
                },

                init: function( selector ) {
                    var arrInit = $.TableEdit.init;
                    if( arrInit.length ) {
                        for(var i = 0; i < arrInit.length; i++ ) {
                            try {
                                this[ arrInit[ i ] ].apply(this,[selector,arrInit,i]);
                            } catch (e) {
                                arrInit[ i ].apply(this,[selector,arrInit,i]);
                            }
                        }
                    }
                },

                doMethod: function( method, args ) {
                    if( ! this[ method ] ) return;
                    var name = method.charAt(0) == '_' ? method.substring(1) : method;
                    var result; // returnable from main function
                    var subResult; // a sub returnable value insted of main
                    this.doAction( name + 'Before', args );
                    if(this[name + 'Before'] && typeof this[name + 'Before'] == 'function' && this[name + 'Before'](args) == true || !this[name + 'Before']) {
                        result = this[ method ].call( this, args );
                    }
                    if(this[name + 'After'] && typeof this[name + 'After'] == 'function')
                        subResult = this[name + 'After'](args);
                    this.doAction( name + 'After', args );
                    if( subResult !== undefined ) return subResult;
                    if( result !== undefined ) return result;
                }

            }
        },

        plugin: {
            get: function() {
                return this._plugin;
            },
            set: function( newSettings ) {
                if( newSettings instanceof Object ) {
                    $.extend(true, this._plugin, newSettings);
                }
            }
        },

        _callbacks: {
            value: {

                refresh: function( object ) {
                    var obj = object || $.TableEdit.plugin;
                    var recent = [];
                    for( var method in obj ) {
                        if( method.charAt(0) == '_' && typeof obj[method] == 'function' ) {
                            if(! $.TableEdit.callbacks[method + 'Before'] ) {
                                (function( method ) {
                                    Object.defineProperty($.TableEdit.callbacks, method + 'Before', {
                                        value: []
                                    });
                                })(method);
                            }
                            if(! $.TableEdit.callbacks[method.substring(1) + 'Before'] ) {
                                (function( method ) {
                                    Object.defineProperty($.TableEdit.callbacks, method.substring(1) + 'Before', {
                                        get: function() {
                                            return this[method + 'Before'];
                                        },
                                        set: function( callback ) {
                                            if( typeof callback == 'function' ) {
                                                this[method + 'Before'].push(callback);
                                            }
                                            else if( Array.isArray(callback) && callback.length > 1 && typeof callback[0] == 'function' ) {
                                                this[method + 'Before'].splice( callback[1], 0, callback[0] );
                                            }
                                        }
                                    });
                                    recent.push( method.substring(1) + 'Before' );
                                })(method);
                            }
                            if(! $.TableEdit.callbacks[method + 'After'] ) {
                                (function( method ) {
                                    Object.defineProperty($.TableEdit.callbacks, method + 'After', {
                                        value: []
                                    });
                                })(method);
                            }
                            if(! $.TableEdit.callbacks[method.substring(1) + 'After'] ) {
                                (function( method ) {
                                    Object.defineProperty($.TableEdit.callbacks, method.substring(1) + 'After', {
                                        get: function() {
                                            return this[method + 'After'];
                                        },
                                        set: function( callback ) {
                                            if( typeof callback == 'function' ) {
                                                this[method + 'After'].push(callback);
                                            }
                                            else if( Array.isArray(callback) && callback.length > 1 && typeof callback[0] == 'function' ) {
                                                this[method + 'After'].splice( callback[1], 0, callback[0] );
                                            }
                                        }
                                    });
                                    recent.push( method.substring(1) + 'After' );
                                })(method);
                            }
                        }
                    }
                    return {
                        recent: recent,
                        eachCallback: function( fn, context ) {
                            for( var i = 0, length = this.recent.length; i < length; i++ ) {
                                fn.call((context || this), this.recent[i]);
                            }
                        }
                    }
                }

            }
        },

        callbacks: {
            get: function() {
                return this._callbacks;
            },
            set: function( newCallbacks ) {
                if( newCallbacks instanceof Object ) {
                    $.extend(true, this._callbacks, newCallbacks);
                }
            }
        },

        _init: {
            value: []
        },

        init: {
            get: function() {
                return this._init;
            },
            set: function( fName ) {
                if( typeof fName == 'function' || this.plugin[fName] && typeof this.plugin[ fName ] == 'function' ) {
                    this._init.push(fName);
                }
                else if( Array.isArray(fName) && fName.length > 1 && typeof fName[0] == 'function' || Array.isArray(fName) && fName.length > 1 && this.plugin[ fName[0] ] && typeof this.plugin[ fName[0] ] == 'function' ) {
                    this._init.splice( fName[1], 0, fName[0] );
                }
            }
        },

        _localPlugin: {
            value: {}
        },

        localPlugin: {
            get: function() {
                return this._localPlugin;
            },
            set: function( object ) {
                if( object instanceof Object ) {
                    $.extend(true, this._localPlugin, object);
                }
            }
        }

    });

    $.fn.tableEdit = function( options ) {

        if(
            /**
             * If a function called for an array
             * @this equal to an array like []
             */
            Array.isArray( this ) ||

            /**
             * Or, if a function called for an jQuery (single length) object
             * @this equal to an jQuery.fn.init(1) not jQuery.fn.init( 2 or more DOM elements contains )
             */
            this.length == 1 ||

            /**
             * Or, if a function called for object
             * @this equal to an object like {} not jQuery object
             */
            this instanceof Object && !(this instanceof jQuery)

        ) {

            var localPlugin = {};

            for( var property in $.TableEdit.localPlugin ) {
                if( typeof $.TableEdit.localPlugin[ property ] == 'function' ) {
                    localPlugin[ property ] = $.TableEdit.localPlugin[ property ]();
                }
                else {
                    localPlugin[ property ] = $.TableEdit.localPlugin[ property ];
                }
            }

            var options = options || {},
                that = $.extend(true,
                    localPlugin,
                    $.TableEdit.plugin,
                    options
                );

            that.init( this );
            return this;
        }

        /**
         * If @this equal to an jQuery.fn.init(2 or more DOM elements contains)
         * We sort each and call for each function @tableEdit recursively
         */
        return this.each(function() {
            // @this right here refers to an individual element of the jQuery collection
            $( this ).tableEdit( options );
        });

    };

    if(! Array.prototype.tableEdit) {

        Object.defineProperty(Array.prototype, "tableEdit", {
            value: $.fn.tableEdit
        });

    }

    if(! Object.prototype.tableEdit) {

        Object.defineProperty(Object.prototype, "tableEdit", {
            value: $.fn.tableEdit
        });

    }

})(jQuery, window);
