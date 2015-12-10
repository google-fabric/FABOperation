//
//  FABTestExpectations.h
//  FABOperationTests
//
//  Copyright © 2015 Twitter. All rights reserved.
//

#import <Foundation/Foundation.h>

/// These blocks provide mechanisms to indirectly call XCTestCase assertion macros, since they require 'self' to be an XCTestCase. So, the test case adding expectations can pass along calls to XCTAssert... and XCTFail into the methods of this class.
typedef void(^FABAsyncCompletionAssertionBlock)(NSString *operationName, NSError *error);
typedef void(^FABPreFlightCancellationFailureAssertionBlock)(void);

@interface FABTestExpectationObserver : NSObject

@property (copy, nonatomic) FABPreFlightCancellationFailureAssertionBlock assertionBlock;

@end

@interface FABTestExpectations : NSObject

/*
 The two following methods add XCTestExpectations for async operations that will be cancelled after they begin executing.
 */
+ (void)addInFlightCancellationCompletionExpectationsToOperation:(FABAsyncOperation *)operation testCase:(XCTestCase *)testCase assertionBlock:(FABAsyncCompletionAssertionBlock)assertionBlock;
+ (void)addInFlightCancellationKVOExpectationsToOperation:(FABAsyncOperation *)operation testCase:(XCTestCase *)testCase;

/*
 The two following methods add XCTestExpectations for async operations that will be cancelled before they begin executing.
 */
+ (void)addPreFlightCancellationCompletionExpectationsToOperation:(FABAsyncOperation *)operation testCase:(XCTestCase *)testCase asyncAssertionBlock:(FABAsyncCompletionAssertionBlock)asyncAssertionBlock;
+ (FABTestExpectationObserver *)addPreFlightCancellationKVOExpectationsToOperation:(FABAsyncOperation *)operation testCase:(XCTestCase *)testCase;

@end
