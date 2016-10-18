//
//  CompoundOperation.swift
//  FABOperationDemo
//
//  Created by Andrew McKnight on 3/15/16.
//  Copyright © 2016 Twitter. All rights reserved.
//

import Cocoa
import FABOperation

class CompoundOperation: FABCompoundOperation {
    var delegate: OperationStateChangeDelegate!
    var imageView: NSImageView
    var color: NSColor

    init(imageView: NSImageView, color: NSColor, delegate: OperationStateChangeDelegate, name: String) {
        self.imageView = imageView
        self.color = color
        self.delegate = delegate

        super.init()

        self.completionBlock = {
            delegate.operationSyncCompletionCalled(operation: self)
        }

        self.asyncCompletion = { errorOptional in
            if let error = errorOptional {
                delegate.operationAsyncCompletionCalled(operation: self, withError: error as NSError)
            } else {
                delegate.operationAsyncCompletionCalled(operation: self)
            }
        }

        self.name = name
        self.compoundQueue.maxConcurrentOperationCount = 1

        let op1 = AsyncOperation(url: "https://upload.wikimedia.org/wikipedia/commons/c/c5/Number-One.JPG", imageView: imageView, color: NSColor.blue, delegate: delegate, name: "\(name) async suboperation 1")
        op1.asyncCompletion = { error in
            delegate.operationAsyncCompletionCalled(operation: op1)
        }
        op1.completionBlock = {
            delegate.operationSyncCompletionCalled(operation: op1)
        }

        let op2 = AsyncOperation(url: "https://upload.wikimedia.org/wikipedia/commons/1/18/Roman_Numeral_2.gif", imageView: imageView, color: NSColor.red, delegate: delegate, name: "\(name) async suboperation 2")
        op2.asyncCompletion = { error in
            delegate.operationAsyncCompletionCalled(operation: op2)
        }
        op2.completionBlock = {
            delegate.operationSyncCompletionCalled(operation: op2)
        }

        let op3 = AsyncOperation(url: "https://upload.wikimedia.org/wikipedia/commons/0/0a/Number-three.JPG", imageView: imageView, color: NSColor.orange, delegate: delegate, name: "\(name) async suboperation 3")
        op3.asyncCompletion = { error in
            delegate.operationAsyncCompletionCalled(operation: op3)
        }
        op3.completionBlock = {
            delegate.operationSyncCompletionCalled(operation: op3)
        }
        
        self.operations = [ op1, op2, op3 ]
    }
}
