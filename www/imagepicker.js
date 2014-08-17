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

    pick: function ( success, error, options ) {
        options || ( options = {} );
        imagepicker.exists(function ( exists ) {
            if ( !exists ) { 
                return error( "imagepicker is only available on iOS" ); 
            }

            var args = [
                options.targetWidth || 0,
                options.targetHeight || 0
            ];

            exec( success, error, "imagepicker", "pick", args );
        })
    }
}
