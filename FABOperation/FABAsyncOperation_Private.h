//
//  FABAsyncOperation_Private.h
//  FABOperation
//
//  Copyright © 2015 Twitter. All rights reserved.
//

#import "FABAsyncOperation.h"

@interface FABAsyncOperation (Private)

/**
 *  Subclasses must call this method when they are done performing work. When it is called is up to you; it can be directly after kicking of a network request, say, or in the callback for its response. Once this method is called, the operation queue it is on will begin executing the next waiting operation. If you directly invoked -[start] on the instance, execution will proceed to the next code statement.
 *  @note as soon as this method is called, @c NSOperation's standard @c completionBlock will be executed if one exists. Keep this in mind when considering the order you call @c markDone and execute the @c asyncCompletion block.
 */
- (void)markDone;

@end
