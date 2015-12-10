//
//  AppDelegate.swift
//  FABOperationDemo
//
//  Copyright © 2015 Twitter. All rights reserved.
//

import Cocoa
import FABOperation

protocol OperationStateChangeDelegate {
    func operationBeganExecuting(operation: NSOperation)
    func operationMainMethodFinished(operation: NSOperation)
    func operationAsyncWorkCanceled(operation: NSOperation)
    func operationAsyncWorkFinished(operation: NSOperation)
}

class SyncOperation: NSOperation {
    var delegate: OperationStateChangeDelegate?

    override func main() {
        self.delegate?.operationBeganExecuting(self)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            self.finish()
        })
        self.delegate?.operationMainMethodFinished(self)
    }

    private func finish() {
        self.delegate?.operationAsyncWorkFinished(self)
    }
}

class AsyncOperation: FABAsyncOperation {
    var delegate: OperationStateChangeDelegate?

    override func main() {
        self.delegate?.operationBeganExecuting(self)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            self.finish()
        })
        self.delegate?.operationMainMethodFinished(self)
    }

    override func cancel() {
        self.delegate?.operationAsyncWorkCanceled(self)
        super.cancel()
    }

    private func finish() {
        self.delegate?.operationAsyncWorkFinished(self)
        self.markDone()
        var error: NSError?
        if self.cancelled {
            error = NSError(domain: "com.twitter.FABOperationDemo.AsyncOperation.error-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Operation cancelled"])
        }
        if let completion = self.asyncCompletion {
            completion(error)
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var tableView: NSTableView!

    private var output: [String] = []
    private var queue = NSOperationQueue()
    private var syncOperationNumber = 1
    private var asyncOperationNumber = 1
    private var observationContext = 0

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.tableView.setDataSource(self)
        self.queue.maxConcurrentOperationCount = 1
    }

    // MARK: IBActions

    @IBAction func addAsyncOperation(sender: NSButton) {
        dispatch_async(dispatch_get_main_queue(), {
            let asyncOperation = AsyncOperation()
            asyncOperation.name = "async operation \(self.asyncOperationNumber)"
            asyncOperation.completionBlock = {
                self.addState("\(asyncOperation.name!) sync completion")
            }
            asyncOperation.asyncCompletion = { errorOptional in
                if let error = errorOptional {
                    self.addState("\(asyncOperation.name!) async completion with error: \(error.localizedDescription)")
                } else {
                    self.addState("\(asyncOperation.name!) async completion")
                }
            }

            asyncOperation.delegate = self

            self.asyncOperationNumber++
            self.queue.addOperation(asyncOperation)
        })
    }

    private func addState(state: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.output.append(state)
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexes(NSIndexSet(index: self.output.count - 1), withAnimation: .SlideDown)
            self.tableView.endUpdates()
        })
    }

    @IBAction func addSyncOperation(sender: NSButton) {
        dispatch_async(dispatch_get_main_queue(), {
            let syncOperation = SyncOperation()
            syncOperation.name = "sync operation \(self.syncOperationNumber)"
            syncOperation.completionBlock = {
                self.addState("\(syncOperation.name!) sync completion")
            }

            syncOperation.delegate = self

            self.syncOperationNumber++
            self.queue.addOperation(syncOperation)
        })
    }

    @IBAction func queueConcurrencyChanged(sender: NSSegmentedControl) {
        let opCount = sender.selectedSegment == 0 ? 1 : NSOperationQueueDefaultMaxConcurrentOperationCount
        self.queue.maxConcurrentOperationCount = opCount
    }

    @IBAction func cancelCurrentOperation(sender: NSButton) {
        if let operation = self.queue.operations.first {
            operation.cancel()
        }
    }

    @IBAction func clearDisplay(sender: NSButton) {
        self.output.removeAll()
        self.tableView.reloadData()
    }
}

// MARK: NSTableViewDataSource

extension AppDelegate: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.output.count
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return self.output[row]
    }
}

// MARK: OperationStateChangeDelegate

extension AppDelegate: OperationStateChangeDelegate {
    func operationBeganExecuting(operation: NSOperation) {
        self.addState("\(operation.name!) started")
    }

    func operationMainMethodFinished(operation: NSOperation) {
        self.addState("\(operation.name!) main method finished")
    }

    func operationAsyncWorkFinished(operation: NSOperation) {
        self.addState("\(operation.name!) async work finished")
    }

    func operationAsyncWorkCanceled(operation: NSOperation) {
        self.addState("\(operation.name!) async work canceled")
    }
}

