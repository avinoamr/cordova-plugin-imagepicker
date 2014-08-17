//
//  CDVImagePicker.m
//  albums
//
//  Created by Roi Avinoam on 8/16/14.
//
//

#import "CDVImagePicker.h"
#import "ELCImagePickerController.h"
#import <Cordova/NSData+Base64.h>

@implementation CDVImagePicker

- (void) pick:(CDVInvokedUrlCommand *)command {
    ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
    elcPicker.maximumImagesCount = 10; //Set the maximum number of images to select, defaults to 4
    elcPicker.returnsOriginalImage = NO; //Only return the fullScreenImage, not the fullResolutionImage
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
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    NSMutableArray* results = [NSMutableArray array];
    for ( NSDictionary* dict in info ) {
        
        NSMutableDictionary* d = [[NSMutableDictionary alloc] init];
        NSString* url =[[dict objectForKey:UIImagePickerControllerReferenceURL] absoluteString];
        [d setValue:url forKey:@"url"];
        
        UIImage* image = [dict objectForKey:UIImagePickerControllerOriginalImage];
        if ( self.targetHeight > 0 && self.targetWidth > 0 ) {
            image = [self resizeImage:image toWidth:self.targetWidth andHeight:self.targetHeight];
        }
        
        NSData* data = UIImageJPEGRepresentation(image, .5);
        [d setObject:[data base64EncodedString] forKey:@"data"];
        [results addObject: d];
    }
    
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
    CGFloat wScale = image.size.width / wf;
    CGFloat hScale = image.size.height / hf;
    CGFloat scale = ( wScale > hScale ) ? wScale : hScale;
    
    CGSize size = CGSizeMake( MIN( wf, scale * image.size.width ), MIN( hf, scale * image.size.height ) );
    
    UIGraphicsBeginImageContext(size); // this will resize
    [image drawInRect:CGRectMake( 0, 0, size.width, size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
