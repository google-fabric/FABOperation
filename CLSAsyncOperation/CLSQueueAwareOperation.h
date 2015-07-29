//
//  CLSQueueAwareOperation.h
//  MacApp
//
//  Created by Andrew McKnight on 7/27/15.
//  Copyright (c) 2015 Crashlytics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Protocol specifying that the conforming object (which should be an NSOperation subclass) can know about the operation queue it is waiting in, in case it is responsible for enqueueing new operations.
 */
@protocol CLSQueueAwareOperation <NSObject>

@property (weak, nonatomic) NSOperationQueue *operationQueue;

@end
