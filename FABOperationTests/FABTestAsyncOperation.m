//
//  FABTestAsyncOperation.m
//  FABOperationTests
//
//  Copyright © 2016 Twitter. All rights reserved.
//

#import "FABTestAsyncOperation.h"

const NSUInteger FABTestAsyncOperationErrorCodeCancelled = 12345;

@implementation FABTestAsyncOperation

- (void)main {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_current_queue(), ^{
        [self finishWork];
    });
}

- (void)finishWork {
    if (self.asyncCompletion) {
        NSError *error;
        if (self.isCancelled) {
            error = [NSError errorWithDomain:@"com.FABInFlightCancellationTests.error-domain" code:FABTestAsyncOperationErrorCodeCancelled userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ cancelled", self.name]}];
        }
        [self finishWithError:error];
    }
}

@end
