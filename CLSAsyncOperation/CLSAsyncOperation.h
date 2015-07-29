//
//  CLSAsyncOperation.h
//  CrashlyticsKit
//
//  Created by Matt Massicotte on 12/7/14.
//  Copyright (c) 2014 Twitter. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CLSAsyncOperationCompletionBlock)(NSError* error);

@interface CLSAsyncOperation : NSOperation

@property (copy, nonatomic) CLSAsyncOperationCompletionBlock asyncCompletion;

@end
