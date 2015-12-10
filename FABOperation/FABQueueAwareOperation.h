//
//  FABQueueAwareOperation.h
//  FABOperation
//
//  Copyright © 2015 Twitter. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Protocol specifying that the conforming object (which should be an NSOperation subclass) can know about the operation queue it is waiting in, in case it is responsible for enqueueing new operations.
 */
@protocol FABQueueAwareOperation <NSObject>

@property (weak, nonatomic) NSOperationQueue *operationQueue;

@end
