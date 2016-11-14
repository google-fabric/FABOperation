//
//  AppDelegate.swift
//  FABOperationDemo
//
//  Copyright © 2016 Twitter. All rights reserved.
//

import Cocoa

typealias OperationState = (description: String, color: NSColor, font: String)

let colors = [ NSColor.black, NSColor.blue, NSColor.orange, NSColor.red, NSColor.green, NSColor.gray, NSColor.cyan, NSColor.magenta ]

let urls = [
    "https://upload.wikimedia.org/wikipedia/commons/c/c5/Number-One.JPG",
    "https://upload.wikimedia.org/wikipedia/commons/1/18/Roman_Numeral_2.gif",
    "https://upload.wikimedia.org/wikipedia/commons/0/0a/Number-three.JPG"
]

var nextURLIndex = 0

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!

    fileprivate var output: [OperationState] = []
    fileprivate var queue = OperationQueue()
    fileprivate var syncOperationNumber = 1
    fileprivate var asyncOperationNumber = 1
    fileprivate var compoundOperationNumber = 1
    fileprivate var currentColor = 0

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        tableView.dataSource = self
        tableView.delegate = self
        queue.maxConcurrentOperationCount = 1
        setQueueSuspended(suspended: true)
    }

}

extension AppDelegate {

    // MARK: IBActions

    @IBAction func startQueue(sender: AnyObject) {
        setQueueSuspended(suspended: false)
    }

    @IBAction func stopQueue(sender: AnyObject) {
        setQueueSuspended(suspended: true)
    }

    @IBAction func queueConcurrencyChanged(sender: NSSegmentedControl) {
        let opCount = sender.selectedSegment == 0 ? 1 : OperationQueue.defaultMaxConcurrentOperationCount
        queue.maxConcurrentOperationCount = opCount
    }

    @IBAction func cancelCurrentOperation(sender: NSButton) {
        if let operation = queue.operations.first {
            operation.cancel()
        }
    }

    @IBAction func clearDisplay(sender: NSButton) {
        syncOperationNumber = 1
        asyncOperationNumber = 1
        compoundOperationNumber = 1
        output.removeAll()
        tableView.reloadData()
    }

    @IBAction func addSyncOperation(sender: NSButton) {
        DispatchQueue.main.async() {
            let syncOperation = SyncOperation(url: urls[nextURLIndex % 3], imageView: self.imageView, color: colors[Int(self.currentColor % colors.count)], delegate: self, name: "sync operation \(self.syncOperationNumber)")
            self.currentColor += 1
            nextURLIndex += 1

            self.syncOperationNumber += 1
            self.addState(state: ("\(syncOperation.name!) enqueued", syncOperation.color, "HelveticaNeue-Light"))
            self.queue.addOperation(syncOperation)
        }
    }

    @IBAction func addAsyncOperation(sender: NSButton) {
        DispatchQueue.main.async() {
            let name = "async operation \(self.asyncOperationNumber)"
            let color = colors[Int(self.currentColor % colors.count)]
            self.currentColor += 1
            let asyncOperation = AsyncOperation(url: urls[nextURLIndex % 3], imageView: self.imageView, color: color, delegate: self, name: name)
            nextURLIndex += 1

            self.asyncOperationNumber += 1
            self.addState(state: ("\(asyncOperation.name!) enqueued", asyncOperation.color, "HelveticaNeue-Light"))
            self.queue.addOperation(asyncOperation)
        }
    }

    @IBAction func addCompoundOperation(sender: AnyObject) {
        DispatchQueue.main.async() {
            let name = "compound operation \(self.compoundOperationNumber)"
            let compoundOperation = CompoundOperation(imageView: self.imageView, color: NSColor.black, delegate: self, name: name)
            
            self.addState(state: ("\(name) enqueued", NSColor.black, "HelveticaNeue-Light"))
            self.compoundOperationNumber += 1
            self.queue.addOperation(compoundOperation)
        }
    }

}

extension AppDelegate {

    // MARK: helpers

    func addState(state: OperationState) {
        DispatchQueue.main.async() {
            self.output.append(state)
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: NSIndexSet(index: self.output.count - 1) as IndexSet, withAnimation: .slideDown)
            self.tableView.endUpdates()
        }
    }

    func setQueueSuspended(suspended: Bool) {
        queue.isSuspended = suspended
        playButton.isEnabled = suspended
        stopButton.isEnabled = !suspended
    }
}

extension AppDelegate: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {

        let view = tableView.make(withIdentifier: "kRowID", owner: tableView) as? NSTableRowView ?? NSTableRowView(frame: NSZeroRect)

        let label = NSTextView(frame: NSMakeRect(0, 0, 300, 24))
        label.textStorage?.append(NSAttributedString(string: output[row].description, attributes: [NSForegroundColorAttributeName: output[row].color, NSFontAttributeName: NSFont(name: output[row].font, size: 24)!]))

        return view
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 24
    }

}

extension AppDelegate: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.output.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return output[row].description as AnyObject?
    }

    @objc(tableView:willDisplayCell:forTableColumn:row:) func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        let cellObject = cell as? NSCell
        cellObject?.attributedStringValue = NSAttributedString(string: output[row].description, attributes: [NSForegroundColorAttributeName: output[row].color, NSFontAttributeName: NSFont(name: output[row].font, size: 18)!])
    }
}

extension AppDelegate: OperationStateChangeDelegate {

    func getColor(operation: Operation) -> NSColor {
        if let sync = operation as? SyncOperation {
            return sync.color
        }
        if let async = operation as? AsyncOperation {
            return async.color
        }
        return NSColor.black
    }

    func operationBeganExecuting(operation: Operation) {
        self.addState(state: ("\(operation.name!) started", getColor(operation: operation), "HelveticaNeue"))
    }

    func operationMainMethodFinished(operation: Operation) {
        self.addState(state: ("\(operation.name!) main method finished", getColor(operation: operation), "HelveticaNeue"))
    }

    func operationAsyncWorkFinished(operation: Operation) {
        self.addState(state: ("\(operation.name!) async work finished", getColor(operation: operation), "HelveticaNeue"))
    }

    func operationAsyncWorkCanceled(operation: Operation) {
        self.addState(state: ("\(operation.name!) async work canceled", getColor(operation: operation), "HelveticaNeue"))
    }

    func operationAsyncWorkFailed(operation: Operation) {
        self.addState(state: ("\(operation.name!) async work failed", getColor(operation: operation), "HelveticaNeue"))
    }

    func operationAsyncCompletionCalled(operation: Operation) {
        self.addState(state: ("\(operation.name!) async completion", getColor(operation: operation), "HelveticaNeue-BoldItalic"))
    }

    func operationSyncCompletionCalled(operation: Operation) {
        self.addState(state: ("\(operation.name!) sync completion", getColor(operation: operation), "HelveticaNeue-Italic"))
    }

    func operationAsyncCompletionCalled(operation: Operation, withError error: NSError) {
        self.addState(state: ("\(operation.name!) async completion with error: \(error.localizedDescription)", getColor(operation: operation), "HelveticaNeue-BoldItalic"))
    }

}

