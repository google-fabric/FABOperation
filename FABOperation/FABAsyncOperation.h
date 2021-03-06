//
//  FABAsyncOperation.h
//  FABOperation
//
//  Copyright © 2016 Twitter. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Completion block that can be called in your subclass implementation. It is up to you when you want to call it.
 */
typedef void(^FABAsyncOperationCompletionBlock)(NSError *__nullable error);

/**
 *  FABAsyncOperation is a subclass of NSOperation that allows for asynchronous work to be performed, for things like networking, IPC or UI-driven logic. Create your own subclasses to encapsulate custom logic.
 *  @warning When subclassing to create your own operations, be sure to call -[finishWithError:] at some point, or program execution will hang. 
 *  @see -[finishWithError:] in FABAsyncOperation_Private.h
 */
@interface FABAsyncOperation : NSOperation

/**
 *  Add a callback method for consumers of your subclasses to set when the asynchronous work is marked as complete with -[finishWithError:].
 */
@property (copy, nonatomic, nullable) FABAsyncOperationCompletionBlock asyncCompletion;

@end
