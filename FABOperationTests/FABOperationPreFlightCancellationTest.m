//
//  FABOperationPreFlightCancellationTest.m
//  FABOperationTests
//
//  Copyright © 2016 Twitter. All rights reserved.
//
//  This test class checks the behavior of an operation that is cancelled before
//  it begins execution. It observes the operation's isExecuting property and fails
//  the test if that property is ever set to true. The completionBlock should execute,
//  but asyncCompletion should not.

#import <FABOperation/FABOperation.h>
#import <XCTest/XCTest.h>

#import "FABTestAsyncOperation.h"
#import "FABTestExpectations.h"

@interface FABOperationPreFlightCancellationTest : XCTestCase

@end

@implementation FABOperationPreFlightCancellationTest

- (void)testAsyncCancellationPreFlight {
    FABTestAsyncOperation *cancelledOperation = [[FABTestAsyncOperation alloc] init];
    cancelledOperation.name = @"cancelledOperation";

    [FABTestExpectations addPreFlightCancellationCompletionExpectationsToOperation:cancelledOperation testCase:self asyncAssertionBlock:^(NSString *operationName, NSError *error) {
        XCTFail(@"asyncCompletion should not have executed for %@", operationName);
    }];

    FABTestExpectationObserver *observer = [FABTestExpectations addPreFlightCancellationKVOExpectationsToOperation:cancelledOperation testCase:self];
    observer.assertionBlock = ^{
        XCTFail(@"%@ should never have begun executing", cancelledOperation.name);
    };

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    [cancelledOperation cancel];
    [queue addOperation:cancelledOperation];

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        XCTAssertNil(error, @"expectations failed: %@", error);
    }];
}

// This test case adds several async operations to a compound operation and cancels the compound operation before it can execute. All suboperations and the compound operation are tested using pre-flight cancellation checks.
- (void)testCompoundCancellationPreFlight {
    FABCompoundOperation *cancelledCompoundOperation = [[FABCompoundOperation alloc] init];
    cancelledCompoundOperation.name = @"cancelled compound operation";
    cancelledCompoundOperation.compoundQueue.maxConcurrentOperationCount = 1;

    NSMutableArray<NSOperation *> *cancelledSuboperations = [NSMutableArray array];
    NSMutableArray *observers = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        FABTestAsyncOperation *subOperation = [[FABTestAsyncOperation alloc] init];
        subOperation.name = [NSString stringWithFormat:@"cancelledOperation %i", i];
        [cancelledSuboperations addObject:subOperation];
        [FABTestExpectations addPreFlightCancellationCompletionExpectationsToOperation:subOperation testCase:self asyncAssertionBlock:^(NSString *operationName, NSError *error) {
            XCTFail(@"asyncCompletion should not have executed for %@", operationName);
        }];
        FABTestExpectationObserver *observer = [FABTestExpectations addPreFlightCancellationKVOExpectationsToOperation:subOperation testCase:self];
        observer.assertionBlock = ^{
            XCTFail(@"%@ should not have begun executing", subOperation.name);
        };
        [observers addObject:observer];
    }
    cancelledCompoundOperation.operations = cancelledSuboperations;

    [FABTestExpectations addPreFlightCancellationCompletionExpectationsToOperation:cancelledCompoundOperation testCase:self asyncAssertionBlock:^(NSString *operationName, NSError *error) {
        XCTAssertNotNil(error, @"Should have received error for cancellation of %@.", operationName);
        XCTAssertEqual(error.code, FABCompoundOperationErrorCodeCancelled, @"Unexpected error code from %@.", operationName);
    }];
    FABTestExpectationObserver *observer = [FABTestExpectations addPreFlightCancellationKVOExpectationsToOperation:cancelledCompoundOperation testCase:self];
    observer.assertionBlock = ^{
        XCTFail(@"%@ should not have begun executing", cancelledCompoundOperation.name);
    };

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [cancelledCompoundOperation cancel];
    [queue addOperation:cancelledCompoundOperation];

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        XCTAssertNil(error, @"expectations failed: %@", error);
    }];
}

@end
