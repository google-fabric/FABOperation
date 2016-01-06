//
//  FABAsyncOperation.h
//  FABOperation
//
//  Copyright © 2015 Twitter. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Completion block that can be called in your subclass implementation. It is up to you when you want to call it.
 */
typedef void(^FABAsyncOperationCompletionBlock)(NSError *__nullable error);

/**
 *  FABAsyncOperation is a subclass of NSOperation that allows for asynchronous work to be performed, for things like networking, IPC or UI-driven logic. Create your own subclasses to encapsulate custom logic.
 *  @warning When subclassing to create your own operations, be sure to call -[markDone] at some point, or program execution will hang. 
 *  @see -[markDone] in FABAsyncOperation_Private.h
 */
@interface FABAsyncOperation : NSOperation

/**
 *  Add a callback method for consumers of your subclasses to set when the asynchronous work is marked as complete with -[markDone].
 */
@property (copy, nonatomic, nullable) FABAsyncOperationCompletionBlock asyncCompletion;

@end
