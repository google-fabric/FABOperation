//
//  FABCompoundAsyncOperation.m
//  FABOperation
//
//  Copyright © 2015 Twitter. All rights reserved.
//

#import "FABCompoundOperation.h"
#import "FABAsyncOperation_Private.h"

#import "FABQueueAwareOperation.h"

NSString *const FABCompoundOperationErrorUserInfoKeyUnderlyingErrors = @"com.twitter.FABCompoundOperation.error.user-info-key.underlying-errors";

static NSString *const FABCompoundOperationErrorDomain = @"com.twitter.FABCompoundOperation.error";
static char *const FABCompoundOperationCountingQueueLabel = "com.twitter.FABCompoundOperation.dispatch-queue.counting-queue";

@interface FABCompoundOperation ()

@property (strong, nonatomic) NSOperationQueue *compoundQueue;
@property (assign, nonatomic) NSUInteger completedOperations;
@property (strong, nonatomic) NSMutableArray *errors;
@property (strong, nonatomic) dispatch_queue_t countingQueue;

@end

@implementation FABCompoundOperation

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _compoundQueue = [[NSOperationQueue alloc] init];
    _completedOperations = 0;
    _errors = [NSMutableArray array];
    _countingQueue = dispatch_queue_create(FABCompoundOperationCountingQueueLabel, DISPATCH_QUEUE_SERIAL);
    
    return self;
}

- (void)main {
    for (FABAsyncOperation *operation in self.operations) {
        FABAsyncOperationCompletionBlock originalCompletion = [operation.asyncCompletion copy];

        [self addCompoundCompletionCheckToOriginalCompletion:originalCompletion operation:operation];

        if ([operation conformsToProtocol:@protocol(FABQueueAwareOperation)]) {
            [(id<FABQueueAwareOperation>)operation setOperationQueue:self.compoundQueue];
        }

        [self.compoundQueue addOperation:operation];
    }
}

- (void)addCompoundCompletionCheckToOriginalCompletion:(FABAsyncOperationCompletionBlock)originalCompletion operation:(FABAsyncOperation *)operation {
    __weak FABCompoundOperation *weakSelf = self;
    FABAsyncOperationCompletionBlock completion = ^(NSError *error) {
        __strong FABCompoundOperation *strongSelf = weakSelf;

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
                error = [NSError errorWithDomain:FABCompoundOperationErrorDomain code:0 userInfo:@{ FABCompoundOperationErrorUserInfoKeyUnderlyingErrors: self.errors }];
            }
            self.asyncCompletion(error);
        }
        [self markDone];
    }
}

@end
