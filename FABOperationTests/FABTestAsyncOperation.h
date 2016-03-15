//
//  FABTestAsyncOperation.h
//  FABOperationTests
//
//  Copyright © 2016 Twitter. All rights reserved.
//

#import <FABOperation/FABOperation.h>

FOUNDATION_EXPORT const NSUInteger FABTestAsyncOperationErrorCodeCancelled;

/// Example subclass of FABAsyncOperation to use for test cases. It schedules a block using dispatch_after to mark itself as done after 2 seconds.
@interface FABTestAsyncOperation : FABAsyncOperation

@end
