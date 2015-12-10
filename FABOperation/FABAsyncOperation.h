//
//  FABAsyncOperation.h
//  FABOperation
//
//  Copyright © 2015 Twitter. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^FABAsyncOperationCompletionBlock)(NSError* error);

@interface FABAsyncOperation : NSOperation

@property (copy, nonatomic) FABAsyncOperationCompletionBlock asyncCompletion;

@end
