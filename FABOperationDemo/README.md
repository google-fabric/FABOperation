# FABOperationDemo

This demo Mac application demonstrates the subtle difference in how asynchronous logic executes in both vanilla `NSOperations` and `FABAsyncOperations`. It has an `NSOperationQueue` that you can place both versions of operations into with the “Add sync” and “Add async” buttons. Both versions of operations will report when their `main` method begins and ends execution, and when the async work is complete (accomplished using a `dispatch_after` call to another method, which in the async operation's case then calls `markDone` to set the `isFinished` property to true). The async operation also then calls the `asyncCompletion` block. 

There is also a button to cancel the currently executing operation, in which case the async operations will return an error in their `asyncCompletion` callbacks. 

There is a control to set the concurrency of the operation queue as well, which toggles between serial queue or a maximally concurrent (`maxConcurrentOperationCount` of 1 or `NSOperationQueueDefaultMaxConcurrentOperationCount`, respectively).

The table view in the demo app displays all this information so you can see how the order changes between sync and async operations. 