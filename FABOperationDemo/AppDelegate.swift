//
//  AppDelegate.swift
//  FABOperationDemo
//
//  Copyright © 2016 Twitter. All rights reserved.
//

import Cocoa

typealias OperationState = (description: String, color: NSColor, font: String)

let colors = [ NSColor.blackColor(), NSColor.blueColor(), NSColor.orangeColor(), NSColor.redColor(), NSColor.greenColor(), NSColor.grayColor(), NSColor.cyanColor(), NSColor.magentaColor(), NSColor.yellowColor() ]

let urls = [ "https://upload.wikimedia.org/wikipedia/commons/c/c5/Number-One.JPG", "https://upload.wikimedia.org/wikipedia/commons/1/18/Roman_Numeral_2.gif", "https://upload.wikimedia.org/wikipedia/commons/0/0a/Number-three.JPG" ]
var nextURLIndex = 0

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var urlField: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!

    private var output: [OperationState] = []
    private var queue = NSOperationQueue()
    private var syncOperationNumber = 1
    private var asyncOperationNumber = 1
    private var compoundOperationNumber = 1
    private var observationContext = 0
    private var currentColor = 0

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.tableView.setDataSource(self)
        self.tableView.setDelegate(self)
        self.queue.maxConcurrentOperationCount = 1
        self.queue.suspended = true
        self.stopButton.enabled = false
    }

    // MARK: IBActions

    @IBAction func startQueue(sender: AnyObject) {
        queue.suspended = false
        playButton.enabled = false
        stopButton.enabled = true
    }

    @IBAction func stopQueue(sender: AnyObject) {
        queue.suspended = true
        playButton.enabled = true
        stopButton.enabled = false
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
        syncOperationNumber = 1
        asyncOperationNumber = 1
        compoundOperationNumber = 1
        self.output.removeAll()
        self.tableView.reloadData()
    }

    // MARK: adding operations

    @IBAction func addSyncOperation(sender: NSButton) {
        dispatch_async(dispatch_get_main_queue(), {
            let syncOperation = SyncOperation(url: urls[nextURLIndex % 3], imageView: self.imageView, color: colors[Int(self.currentColor++ % colors.count)], delegate: self, name: "sync operation \(self.syncOperationNumber)")
            nextURLIndex += 1

            self.syncOperationNumber += 1
            self.addState(("\(syncOperation.name!) enqueued", syncOperation.color, "HelveticaNeue-Light"))
            self.queue.addOperation(syncOperation)
        })
    }

    @IBAction func addAsyncOperation(sender: NSButton) {
        dispatch_async(dispatch_get_main_queue(), {
            let name = "async operation \(self.asyncOperationNumber)"
            let color = colors[Int(rand()) % colors.count]
            let asyncOperation = AsyncOperation(url: urls[nextURLIndex % 3], imageView: self.imageView, color: color, delegate: self, name: name)
            nextURLIndex += 1

            self.asyncOperationNumber += 1
            self.addState(("\(asyncOperation.name!) enqueued", asyncOperation.color, "HelveticaNeue-Light"))
            self.queue.addOperation(asyncOperation)
        })
    }

    @IBAction func addCompoundOperation(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            let name = "compound operation \(self.compoundOperationNumber)"
            let compoundOperation = CompoundOperation(imageView: self.imageView, color: NSColor.blackColor(), delegate: self, name: name)
            
            self.addState(("\(name) enqueued", NSColor.blackColor(), "HelveticaNeue-Light"))
            self.compoundOperationNumber += 1
            self.queue.addOperation(compoundOperation)
        })
    }

    // MARK: helpers

    private func addState(state: OperationState) {
        dispatch_async(dispatch_get_main_queue(), {
            self.output.append(state)
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexes(NSIndexSet(index: self.output.count - 1), withAnimation: .SlideDown)
            self.tableView.endUpdates()
        })
    }
}

// MARK: NSTableViewDelegate

extension AppDelegate: NSTableViewDelegate {

    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {

        let view = tableView.makeViewWithIdentifier("kRowID", owner: tableView) as? NSTableRowView ?? NSTableRowView(frame: NSZeroRect)

        let label = NSTextView(frame: NSMakeRect(0, 0, 300, 24))
        label.textStorage?.appendAttributedString(NSAttributedString(string: self.output[row].description, attributes: [NSForegroundColorAttributeName: self.output[row].color, NSFontAttributeName: NSFont(name: output[row].font, size: 24)!]))

        return view
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 24
    }

}

// MARK: NSTableViewDataSource

extension AppDelegate: NSTableViewDataSource {

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.output.count
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return self.output[row].description
    }

    func tableView(tableView: NSTableView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        let cellObject = cell as? NSCell
        cellObject?.attributedStringValue = NSAttributedString(string: self.output[row].description, attributes: [NSForegroundColorAttributeName: self.output[row].color, NSFontAttributeName: NSFont(name: output[row].font, size: 18)!])

    }
}

// MARK: OperationStateChangeDelegate

extension AppDelegate: OperationStateChangeDelegate {
    func getColor(operation: NSOperation) -> NSColor {
        if let sync = operation as? SyncOperation {
            return sync.color
        }
        if let async = operation as? AsyncOperation {
            return async.color
        }
        return NSColor.blackColor()
    }

    func operationBeganExecuting(operation: NSOperation) {
        self.addState(("\(operation.name!) started", getColor(operation), "HelveticaNeue"))
    }

    func operationMainMethodFinished(operation: NSOperation) {
        self.addState(("\(operation.name!) main method finished", getColor(operation), "HelveticaNeue"))
    }

    func operationAsyncWorkFinished(operation: NSOperation) {
        self.addState(("\(operation.name!) async work finished", getColor(operation), "HelveticaNeue"))
    }

    func operationAsyncWorkCanceled(operation: NSOperation) {
        self.addState(("\(operation.name!) async work canceled", getColor(operation), "HelveticaNeue"))
    }

    func operationAsyncWorkFailed(operation: NSOperation) {
        self.addState(("\(operation.name!) async work failed", getColor(operation), "HelveticaNeue"))
    }

    func operationAsyncCompletionCalled(operation: NSOperation) {
        self.addState(("\(operation.name!) async completion", getColor(operation), "HelveticaNeue-BoldItalic"))
    }

    func operationSyncCompletionCalled(operation: NSOperation) {
        self.addState(("\(operation.name!) sync completion", getColor(operation), "HelveticaNeue-Italic"))
    }

    func operationAsyncCompletionCalled(operation: NSOperation, withError error: NSError) {
        self.addState(("\(operation.name!) async completion with error: \(error.localizedDescription)", getColor(operation), "HelveticaNeue-BoldItalic"))
    }
}

