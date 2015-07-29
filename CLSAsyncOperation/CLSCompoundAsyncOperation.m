//
//  CLSCompoundAsyncOperation.m
//  MacApp
//
//  Created by Andrew McKnight on 4/23/15.
//  Copyright (c) 2015 Crashlytics. All rights reserved.
//

#import "CLSCompoundAsyncOperation.h"
#import "CLSAsyncOperation_Private.h"

#import "CLSQueueAwareOperation.h"

static NSString *const CLSCompoundAsyncOperationErrorDomain = @"com.crashlytics.error.compound-async-operation";
NSString *const CLSCompoundAsyncOperationErrorUserInfoKeyUnderlyingErrors = @"com.crashlytics.error.user-info-key.underlying-errors";

@interface CLSCompoundAsyncOperation ()

@property (strong, nonatomic) NSOperationQueue *compoundQueue;
@property (assign, nonatomic) NSUInteger completedOperations;
@property (strong, nonatomic) NSMutableArray *errors;
@property (strong, nonatomic) dispatch_queue_t countingQueue;

@end

@implementation CLSCompoundAsyncOperation

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _compoundQueue = [[NSOperationQueue alloc] init];
    _completedOperations = 0;
    _errors = [NSMutableArray array];
    _countingQueue = dispatch_queue_create("operation counting queue", DISPATCH_QUEUE_SERIAL);
    
    return self;
}

- (void)main {
    for (CLSAsyncOperation *operation in self.operations) {
        CLSAsyncOperationCompletionBlock originalCompletion = [operation.asyncCompletion copy];

        [self addCompoundCompletionCheckToOriginalCompletion:originalCompletion operation:operation];

        if ([operation conformsToProtocol:@protocol(CLSQueueAwareOperation)]) {
            [(id<CLSQueueAwareOperation>)operation setOperationQueue:self.compoundQueue];
        }

        [self.compoundQueue addOperation:operation];
    }
}

- (void)addCompoundCompletionCheckToOriginalCompletion:(CLSAsyncOperationCompletionBlock)originalCompletion operation:(CLSAsyncOperation *)operation {
    __weak CLSCompoundAsyncOperation *weakSelf = self;
    CLSAsyncOperationCompletionBlock completion = ^(NSError *error) {
        __strong CLSCompoundAsyncOperation *strongSelf = weakSelf;

        NSUInteger completedOperations = [strongSelf updateCompletionCountsWithError:error];

        if (originalCompletion) {
            originalCompletion(error);
        }

        [strongSelf attemptCompoundCompletionWithCompletedOperations:completedOperations];
    };
    operation.asyncCompletion = completion;
}

- (NSUInteger)updateCompletionCountsWithError:(NSError *)error {
    __block NSUInteger completedOperations;
    dispatch_sync(self.countingQueue, ^{
        if (!error) {
            self.completedOperations++;
        } else {
            [self.errors addObject:error];
        }
        completedOperations = self.completedOperations;
    });
    return completedOperations;
}

- (void)attemptCompoundCompletionWithCompletedOperations:(NSUInteger)completedOperations {
    if (completedOperations + self.errors.count == self.operations.count) {
        if (self.asyncCompletion) {
            NSError *error = nil;
            if (self.errors.count > 0) {
                error = [NSError errorWithDomain:CLSCompoundAsyncOperationErrorDomain code:0 userInfo:@{ CLSCompoundAsyncOperationErrorUserInfoKeyUnderlyingErrors: self.errors }];
            }
            self.asyncCompletion(error);
        }
        [self markDone];
    }
}

@end
