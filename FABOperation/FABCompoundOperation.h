//
//  FABCompoundAsyncOperation.h
//  FABOperation
//
//  Copyright © 2015 Twitter. All rights reserved.
//

#import "FABAsyncOperation.h"

OBJC_EXTERN NSString *const FABCompoundOperationErrorUserInfoKeyUnderlyingErrors;

@interface FABCompoundOperation : FABAsyncOperation

@property (copy, nonatomic) NSArray *operations;

@end
