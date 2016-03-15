//
//  FABCompoundAsyncOperation.m
//  FABOperation
//
//  Copyright © 2016 Twitter. All rights reserved.
//

#import "FABCompoundOperation.h"
#import "FABAsyncOperation_Private.h"

#define FAB_DISPATCH_QUEUES_AS_OBJECTS OS_OBJECT_USE_OBJC_RETAIN_RELEASE

const NSUInteger FABCompoundOperationErrorCodeCancelled = UINT_MAX - 1;
const NSUInteger FABCompoundOperationErrorCodeSuboperationFailed = UINT_MAX - 2;

NSString *const FABCompoundOperationErrorUserInfoKeyUnderlyingErrors = @"com.twitter.FABCompoundOperation.error.user-info-key.underlying-errors";

static NSString *const FABCompoundOperationErrorDomain = @"com.twitter.FABCompoundOperation.error";
static char *const FABCompoundOperationCountingQueueLabel = "com.twitter.FABCompoundOperation.dispatch-queue.counting-queue";

@interface FABCompoundOperation ()

@property (strong, nonatomic, readwrite) NSOperationQueue *compoundQueue;
@property (assign, nonatomic) NSUInteger completedOperations;
@property (strong, nonatomic) NSMutableArray *errors;
#if FAB_DISPATCH_QUEUES_AS_OBJECTS
@property (strong, nonatomic) dispatch_queue_t countingQueue;
#else
@property (assign, nonatomic) dispatch_queue_t countingQueue;
#endif

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

#if !FAB_DISPATCH_QUEUES_AS_OBJECTS
- (void)dealloc {
    if (_countingQueue) {
        dispatch_release(_countingQueue);
    }
}
#endif

- (void)main {
    for (FABAsyncOperation *operation in self.operations) {
        [self injectCompoundAsyncCompletionInOperation:operation];
        [self injectCompoundSyncCompletionInOperation:operation];

        [self.compoundQueue addOperation:operation];
    }
}

- (void)cancel {
    if (self.compoundQueue.operations.count > 0) {
        [self.compoundQueue cancelAllOperations];
        [self attemptCompoundCompletion];
    } else {
        for (NSOperation *operation in self.operations) {
            [operation cancel];
        }

        // we have to add the operations to the queue in order for their isFinished property to be set to true... gross.
        [self.compoundQueue addOperations:self.operations waitUntilFinished:NO];
    }
    [super cancel];
}

- (void)injectCompoundAsyncCompletionInOperation:(FABAsyncOperation *)operation {
    __weak FABCompoundOperation *weakSelf = self;
    FABAsyncOperationCompletionBlock originalAsyncCompletion = [operation.asyncCompletion copy];
    FABAsyncOperationCompletionBlock completion = ^(NSError *error) {
        __strong FABCompoundOperation *strongSelf = weakSelf;

        if (originalAsyncCompletion) {
            originalAsyncCompletion(error);
        }

        [strongSelf updateCompletionCountsWithError:error];
    };
    operation.asyncCompletion = completion;
}

- (void)injectCompoundSyncCompletionInOperation:(FABAsyncOperation *)operation {
    __weak FABCompoundOperation *weakSelf = self;
    void(^originalSyncCompletion)(void) = [operation.completionBlock copy];
    void(^completion)(void) = ^{
        __strong FABCompoundOperation *strongSelf = weakSelf;

        if (originalSyncCompletion) {
            originalSyncCompletion();
        }

        [strongSelf attemptCompoundCompletion];
    };
    operation.completionBlock = completion;
}

- (void)updateCompletionCountsWithError:(NSError *)error {
    dispatch_sync(self.countingQueue, ^{
        if (!error) {
            self.completedOperations += 1;
        } else {
            [self.errors addObject:error];
        }
    });
}

- (void)attemptCompoundCompletion {
    if (self.isCancelled) {
        [self markDone];
        if (self.asyncCompletion) {
            self.asyncCompletion([NSError errorWithDomain:FABCompoundOperationErrorDomain code:FABCompoundOperationErrorCodeCancelled userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ cancelled", self.name]}]);
            self.asyncCompletion = nil;
        }
    } else if (self.completedOperations + self.errors.count == self.operations.count) {
        [self markDone];
        if (self.asyncCompletion) {
            NSError *error = nil;
            if (self.errors.count > 0) {
                error = [NSError errorWithDomain:FABCompoundOperationErrorDomain code:FABCompoundOperationErrorCodeSuboperationFailed userInfo:@{ FABCompoundOperationErrorUserInfoKeyUnderlyingErrors: self.errors }];
            }
            self.asyncCompletion(error);
        }
    }
}

@end
