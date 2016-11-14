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
    func operationBeganExecuting(operation: Operation)
    func operationMainMethodFinished(operation: Operation)
    func operationAsyncWorkCanceled(operation: Operation)
    func operationAsyncWorkFinished(operation: Operation)
    func operationAsyncWorkFailed(operation: Operation)
    func operationSyncCompletionCalled(operation: Operation)
    func operationAsyncCompletionCalled(operation: Operation)
    func operationAsyncCompletionCalled(operation: Operation, withError error: NSError)
}
