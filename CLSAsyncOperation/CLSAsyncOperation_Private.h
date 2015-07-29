//
//  CLSAsyncOperation_Private.h
//  CrashlyticsKit
//
//  Created by Matt Massicotte on 12/7/14.
//  Copyright (c) 2014 Twitter. All rights reserved.
//

#import "CLSAsyncOperation.h"

@interface CLSAsyncOperation (Private)

- (void)markStarted;
- (void)markDone;

- (BOOL)checkForCancellation;

@end
