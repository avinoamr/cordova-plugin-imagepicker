//
//  CDVImagePicker.m
//  albums
//
//  Created by Roi Avinoam on 8/16/14.
//
//

#import "CDVImagePicker.h"
#import "ELCImagePickerController.h"

@implementation CDVImagePicker

- (void) pick:(CDVInvokedUrlCommand *)command {
    ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
    elcPicker.maximumImagesCount = 10; //Set the maximum number of images to select, defaults to 4
    elcPicker.returnsOriginalImage = NO; //Only return the fullScreenImage, not the fullResolutionImage
    elcPicker.returnsImage = NO; //Return UIimage if YES. If NO, only return asset location information
    elcPicker.onOrder = YES; //For multiple image selection, display and return selected order of images
    elcPicker.imagePickerDelegate = self;
    
    self.callbackId = command.callbackId;
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
        [results addObject: [[dict objectForKey:UIImagePickerControllerReferenceURL] absoluteString]];
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

@end
