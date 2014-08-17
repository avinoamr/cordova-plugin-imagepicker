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
    elcPicker.maximumImagesCount = 10; //Set the maximum number of images to select, defaults to 4
    elcPicker.returnsOriginalImage = YES; //Only return the fullScreenImage, not the fullResolutionImage
    elcPicker.returnsImage = YES; //Return UIimage if YES. If NO, only return asset location information
    elcPicker.onOrder = YES; //For multiple image selection, display and return selected order of images
    elcPicker.imagePickerDelegate = self;
    
    self.callbackId = command.callbackId;
    self.targetWidth = [command.arguments objectAtIndex:0];
    self.targetHeight = [command.arguments objectAtIndex:1];
    
    [self.viewController presentViewController:elcPicker animated:YES completion:nil];
    return;
}

- (void) exists:(CDVInvokedUrlCommand *) command {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    ALAssetsLibrary* lib = [[ALAssetsLibrary alloc] init];
    NSLocale* en = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:en];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"]; // ISO-8601
    
    NSMutableArray* results = [NSMutableArray array];
    __block int done = [info count];
    for ( NSDictionary* dict in info ) {
        
        NSMutableDictionary* d = [[NSMutableDictionary alloc] init];
        NSURL* url = [dict objectForKey:UIImagePickerControllerReferenceURL];
        [d setValue: [url absoluteString] forKey:@"url"];
        
        UIImage* image = [dict objectForKey:UIImagePickerControllerOriginalImage];
        if ( self.targetHeight > 0 && self.targetWidth > 0 ) {
            image = [self resizeImage:image toWidth:self.targetWidth andHeight:self.targetHeight];
        }
        
        NSData* data = UIImageJPEGRepresentation(image, .5);
        [d setObject:[data base64EncodedString] forKey:@"data"];
        
        
        ALAssetsLibraryAssetForURLResultBlock onSuccess = ^(ALAsset* asset) {
            CLLocation* loc = [asset valueForProperty:ALAssetPropertyLocation];
            NSNumber* lat = [[NSNumber alloc] initWithDouble:loc.coordinate.latitude];
            NSNumber* lng = [[NSNumber alloc] initWithDouble:loc.coordinate.longitude];
            
            [d setObject:lat forKey:@"lat"];
            [d setObject:lng forKey:@"lng"];
            
            NSDate* date = [asset valueForProperty:ALAssetPropertyDate];
            [d setObject:[formatter stringFromDate:date] forKey:@"date"];
            
            done -= 1;
            if ( done <= 0 ) {
                [self didFinishWithResults:results];
            }
        };
        
        ALAssetsLibraryAccessFailureBlock onError = ^(NSError* err) {
            // do nothing - no metadata exists
            done -= 1;
            if ( done <= 0 ) {
                [self didFinishWithResults:results];
            }
        };
        
        [lib assetForURL:url resultBlock:onSuccess failureBlock:onError];
        [results addObject: d];
    }
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
