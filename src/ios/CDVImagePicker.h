//
//  CDVImagePicker.h
//  albums
//
//  Created by Roi Avinoam on 8/16/14.
//
//

#import <Cordova/CDVPlugin.h>
#import "ELCImagePickerController.h"

@interface CDVImagePicker : CDVPlugin

@property NSString* callbackId;
@property NSNumber* targetWidth;
@property NSNumber* targetHeight;

// quick command to check if the plugin exists and is available
- (void) exists: (CDVInvokedUrlCommand*) command;
- (void) pick: (CDVInvokedUrlCommand*) command;
- (void) elcImagePickerController: (ELCImagePickerController *) picker didFinishPickingMediaWithInfo:(NSArray *)info;
- (void) elcImagePickerControllerDidCancel: ( ELCImagePickerController* ) picker;

@end
