var exec = require( "cordova/exec" );

function PickedImage( attrs ) {
    this.url = attrs.url;
}

PickedImage.prototype.getData = function ( success, error, options ) {
    var args = [
        this.url,
        options.width || 0,
        options.height || 0,
        options.destination || ""
    ];

    exec( success, error, "imagepicker", "getData", args );
    return this;
}

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

            exec( function ( results ) {
                success( results.map( function ( image ) {
                    return new PickedImage( image );
                }))
            }, error, "imagepicker", "pick", args );
        })
    }
}