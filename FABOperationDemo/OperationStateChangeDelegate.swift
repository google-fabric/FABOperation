//
//  OperationStateChangeDelegate.swift
//  FABOperationDemo
//
//  Created by Andrew McKnight on 3/15/16.
//  Copyright © 2016 Twitter. All rights reserved.
//

import Cocoa
import FABOperation

protocol OperationStateChangeDelegate {
    func operationBeganExecuting(operation: NSOperation)
    func operationMainMethodFinished(operation: NSOperation)
    func operationAsyncWorkCanceled(operation: NSOperation)
    func operationAsyncWorkFinished(operation: NSOperation)
    func operationAsyncWorkFailed(operation: NSOperation)
    func operationSyncCompletionCalled(operation: NSOperation)
    func operationAsyncCompletionCalled(operation: NSOperation)
    func operationAsyncCompletionCalled(operation: NSOperation, withError error: NSError)
}
