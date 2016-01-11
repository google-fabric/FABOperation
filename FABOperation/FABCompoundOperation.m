//
//  FABCompoundAsyncOperation.m
//  FABOperation
//
//  Copyright © 2015 Twitter. All rights reserved.
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
        FABAsyncOperationCompletionBlock originalCompletion = [operation.asyncCompletion copy];

        [self addCompoundCompletionCheckToOriginalCompletion:originalCompletion operation:operation];

        [self.compoundQueue addOperation:operation];
    }
}

- (void)cancel {
    if (self.compoundQueue.operations.count > 0) {
        [self.compoundQueue cancelAllOperations];
        [self attemptCompoundCompletionWithCompletedOperations:0];
    } else {
        for (NSOperation *operation in self.operations) {
            [operation cancel];
        }

        // we have to add the operations to the queue in order for their isFinished property to be set to true... gross.
        [self.compoundQueue addOperations:self.operations waitUntilFinished:NO];
    }
    [super cancel];
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
    if (self.isCancelled) {
        [self markDone];
        if (self.asyncCompletion) {
            self.asyncCompletion([NSError errorWithDomain:FABCompoundOperationErrorDomain code:FABCompoundOperationErrorCodeCancelled userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ cancelled", self.name]}]);
            self.asyncCompletion = nil;
        }
    } else if (completedOperations + self.errors.count == self.operations.count) {
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
