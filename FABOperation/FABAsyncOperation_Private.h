//
//  FABAsyncOperation_Private.h
//  FABOperation
//
//  Copyright © 2015 Twitter. All rights reserved.
//

#import "FABAsyncOperation.h"

@interface FABAsyncOperation (Private)

- (void)markStarted;
- (void)markDone;

- (BOOL)checkForCancellation;

@end
