//
//  AppDelegate.m
//  SmokeTest-tvOS
//
//  Copyright © 2016 Twitter. All rights reserved.
//

#import "AppDelegate.h"

#import <FABOperation/FABOperation.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    FABAsyncOperation *operation = [[FABAsyncOperation alloc] init];
    [operation start];
    return YES;
}

@end
