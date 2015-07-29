//
//  CLSCompoundAsyncOperation.h
//  MacApp
//
//  Created by Andrew McKnight on 4/23/15.
//  Copyright (c) 2015 Crashlytics. All rights reserved.
//

#import "CLSAsyncOperation.h"

OBJC_EXTERN NSString *const CLSCompoundAsyncOperationErrorUserInfoKeyUnderlyingErrors;

@interface CLSCompoundAsyncOperation : CLSAsyncOperation

@property (copy, nonatomic) NSArray *operations;

@end
