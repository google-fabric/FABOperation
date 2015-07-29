//
//  CLSAsyncOperation.m
//  CrashlyticsKit
//
//  Created by Matt Massicotte on 12/7/14.
//  Copyright (c) 2014 Twitter. All rights reserved.
//

#import "CLSAsyncOperation.h"

@interface CLSAsyncOperation () {
    BOOL _internalExecuting;
    BOOL _internalFinished;
}

@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation CLSAsyncOperation

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _internalExecuting = NO;
    _internalFinished = NO;

    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = @"com.crashlytics.async-operation-lock";

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

@end
