var exec = require( "cordova/exec" );

var exists;
var imagepicker = module.exports = {
    exists: function ( callback ) {
        if ( typeof exists == "undefined" ) {
            try {
                exec(function () {
                    exists = true;
                    callback( exists );
                }, function () {
                    exists = false;
                    callback( exists );
                }, "imagepicker", "exists" );
            } catch ( err ) {
                exists = false;
                callback( exists );
            }
        } else {
            callback( exists );
        }
    },

    pick: function ( success, error ) {
        imagepicker.exists(function ( exists ) {
            if ( !exists ) { 
                return error( "imagepicker is only available on iOS" ); 
            }
            exec(function ( results ) {
                success( results.map(function ( url ) {
                    return { localURL: url };
                }));
            }, error, "imagepicker", "pick" );
        })
    }
}