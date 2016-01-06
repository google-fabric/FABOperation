//
//  AppDelegate.m
//  SmokeTest-OSX
//
//  Copyright © 2016 Twitter. All rights reserved.
//

#import "AppDelegate.h"

#import <FABOperation/FABOperation.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    FABAsyncOperation *operation = [[FABAsyncOperation alloc] init];
    [operation start];
}

@end
