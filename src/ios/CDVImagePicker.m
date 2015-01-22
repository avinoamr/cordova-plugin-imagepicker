//
//  CDVImagePicker.m
//  albums
//
//  Created by Roi Avinoam on 8/16/14.
//
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import <Cordova/NSData+Base64.h>
#import "CDVImagePicker.h"
#import "ELCImagePickerController.h"

@implementation CDVImagePicker

- (void) pick:(CDVInvokedUrlCommand *)command {
    ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
    elcPicker.maximumImagesCount = [command.arguments objectAtIndex:0]; //Set the maximum number of images to select, defaults to 4
    elcPicker.returnsOriginalImage = YES; //Only return the fullScreenImage, not the fullResolutionImage
    elcPicker.returnsImage = YES; //Return UIimage if YES. If NO, only return asset location information
    elcPicker.onOrder = YES; //For multiple image selection, display and return selected order of images
    elcPicker.imagePickerDelegate = self;
    
    self.callbackId = command.callbackId;
    self.targetWidth = [command.arguments objectAtIndex:1];
    self.targetHeight = [command.arguments objectAtIndex:2];
    
    [self.viewController presentViewController:elcPicker animated:YES completion:nil];
    return;
}

- (void) getData:(CDVInvokedUrlCommand *)command {
    [NSThread detachNewThreadSelector:@selector(getDataSync:) toTarget:self withObject:command];
}

- (void) getDataSync:(CDVInvokedUrlCommand *)command {
    NSString* urlString = [command.arguments objectAtIndex:0];
    NSURL* url = [NSURL URLWithString:urlString];
    CGFloat width = [[command.arguments objectAtIndex:1] floatValue];
    CGFloat height = [[command.arguments objectAtIndex:2] floatValue];
    NSString* destination = [command.arguments objectAtIndex:3];
    
    ALAssetsLibrary* lib = [[ALAssetsLibrary alloc] init];
    ALAssetsLibraryAssetForURLResultBlock onSuccess = ^( ALAsset* asset ) {
        NSMutableDictionary* results = [[NSMutableDictionary alloc] init];
        ALAssetRepresentation* repr = [asset defaultRepresentation];
        CGImageRef ref = [repr fullResolutionImage];
        
        // load the image
        UIImageOrientation orientation = (UIImageOrientation)[repr orientation];
        UIImage* image = [[UIImage alloc] initWithCGImage:ref scale:1.0f orientation:orientation];
        
        // resize the image
        if ( width > 0 && height > 0 ) {
            CGSize size = [repr dimensions];
            CGFloat scalew = width / size.width;
            CGFloat scaleh = height / size.height;
            CGFloat scale = ( scalew > scaleh ) ? scalew : scaleh;
            
            size = CGSizeMake( scale * size.width, scale * size.height );
            UIGraphicsBeginImageContext( size );
            [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        NSData* data = UIImageJPEGRepresentation(image, .5);
        [results setValue:[data base64EncodedString] forKey:@"base64"];

        if ( ![ destination isEqual:@"" ] ) {
            NSURL* url = [ NSURL URLWithString:destination];
            [ data writeToURL:url atomically:YES ];
            [ results setValue:destination forKey:@"url" ];
        }
        
        CLLocation* loc = [asset valueForProperty:ALAssetPropertyLocation];
        NSNumber* lat = [[NSNumber alloc] initWithDouble:loc.coordinate.latitude];
        NSNumber* lng = [[NSNumber alloc] initWithDouble:loc.coordinate.longitude];
        
        [results setObject:lat forKey:@"lat"];
        [results setObject:lng forKey:@"lng"];
        
        NSDate* date = [asset valueForProperty:ALAssetPropertyDate];
        NSLocale* en = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:en];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [results setObject:[formatter stringFromDate:date] forKey:@"date"];
    
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    };
    
    ALAssetsLibraryAccessFailureBlock onError = ^( NSError* err ) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    };
    
    [lib assetForURL:url resultBlock:onSuccess failureBlock:onError];
}

- (void) exists:(CDVInvokedUrlCommand *) command {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    NSMutableArray* results = [NSMutableArray array];
    for ( NSDictionary* dict in info ) {
        NSMutableDictionary* d = [[NSMutableDictionary alloc] init];
        NSURL* url = [dict objectForKey:UIImagePickerControllerReferenceURL];
        [d setValue: [url absoluteString] forKey:@"url"];
        [results addObject: d];
    }
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:results];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

- (void) didFinishWithResults:(NSArray*) results {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:results];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

- (void) elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    NSMutableArray* results = [NSMutableArray array];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:results];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

- (UIImage*) resizeImage:(UIImage *)image toWidth:(NSNumber *)w andHeight:(NSNumber *)h {
    CGFloat wf = [w floatValue];
    CGFloat hf = [h floatValue];
    CGFloat wScale = wf / image.size.width;
    CGFloat hScale = hf / image.size.height;
    CGFloat scale = ( wScale > hScale ) ? wScale : hScale;
    
    CGSize size = CGSizeMake( MIN( wf, scale * image.size.width ), MIN( hf, scale * image.size.height ) );
    
    UIGraphicsBeginImageContext(size); // this will resize
    [image drawInRect:CGRectMake( 0, 0, size.width, size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
