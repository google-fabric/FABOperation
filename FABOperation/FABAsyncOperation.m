//
//  FABAsyncOperation.m
//  FABOperation
//
//  Copyright © 2016 Twitter. All rights reserved.
//

#import "FABAsyncOperation.h"
#import "FABAsyncOperation_Private.h"

@interface FABAsyncOperation () {
    BOOL _internalExecuting;
    BOOL _internalFinished;
}

@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation FABAsyncOperation

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _internalExecuting = NO;
    _internalFinished = NO;

    _lock = [[NSRecursiveLock alloc] init];
    _lock.name = [NSString stringWithFormat:@"com.twitter.%@-lock", [self class]];;

    return self;
}

#pragma mark - NSOperation Overrides
- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    [self.lock lock];
    BOOL result = _internalExecuting;
    [self.lock unlock];

    return result;
}

- (BOOL)isFinished {
    [self.lock lock];
    BOOL result = _internalFinished;
    [self.lock unlock];

    return result;
}

- (void)start {
    if ([self checkForCancellation]) {
        return;
    }

    [self markStarted];

    [self main];
}

#pragma mark - Utilities
- (void)changeValueForKey:(NSString *)key inBlock:(void (^)(void))block {
    [self willChangeValueForKey:key];
    block();
    [self didChangeValueForKey:key];
}

- (void)lock:(void (^)(void))block {
    [self.lock lock];
    block();
    [self.lock unlock];
}

- (BOOL)checkForCancellation {
    if ([self isCancelled]) {
        [self markDone];
        return YES;
    }

    return NO;
}

#pragma mark - State Management
- (void)unlockedMarkFinished {
    [self changeValueForKey:@"isFinished" inBlock:^{
        _internalFinished = YES;
    }];
}

- (void)unlockedMarkStarted {
    [self changeValueForKey:@"isExecuting" inBlock:^{
        _internalExecuting = YES;
    }];
}

- (void)unlockedMarkComplete {
    [self changeValueForKey:@"isExecuting" inBlock:^{
        _internalExecuting = NO;
    }];
}

- (void)markStarted {
    [self lock:^{
        [self unlockedMarkStarted];
    }];
}

- (void)markDone {
    [self lock:^{
        [self unlockedMarkComplete];
        [self unlockedMarkFinished];
    }];
}

#pragma mark - Protected
- (void)finish:(NSError *)error {
    if (self.asyncCompletion) {
        self.asyncCompletion(error);
    }
    [self markDone];
}

@end
