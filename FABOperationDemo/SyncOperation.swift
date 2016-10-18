//
//  SyncOperation.swift
//  FABOperationDemo
//
//  Created by Andrew McKnight on 3/15/16.
//  Copyright © 2016 Twitter. All rights reserved.
//

import Cocoa

class SyncOperation: Operation {
    var delegate: OperationStateChangeDelegate!
    var url: String
    var imageView: NSImageView
    var session: URLSession!
    var downloadTask: URLSessionDownloadTask!
    var color: NSColor

    init(url: String, imageView: NSImageView, color: NSColor, delegate: OperationStateChangeDelegate, name: String) {
        self.url = url
        self.imageView = imageView
        self.color = color
        self.delegate = delegate

        super.init()

        self.name = name

        self.completionBlock = {
            self.delegate.operationSyncCompletionCalled(operation: self)
        }
    }

    override func main() {
        self.delegate.operationBeganExecuting(operation: self)

        requestWithCompletion(completion: handleRequest)

        self.delegate.operationMainMethodFinished(operation: self)
    }

    func requestWithCompletion(completion: @escaping (URL?, URLResponse?, Error?) -> Void) {
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: nil, delegateQueue: OperationQueue.main)
        let request = NSURLRequest(url: NSURL(string: (self.url as NSString).trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))! as URL, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 10)
        downloadTask = session.downloadTask(with: request as URLRequest, completionHandler: completion)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(arc4random_uniform(3) + 1))) {
            self.downloadTask.resume()
        }
    }

    func handleRequest(location: URL?, response: URLResponse?, error: Error?) {
        self.session.invalidateAndCancel()
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 || error != nil {
                self.delegate.operationAsyncWorkFailed(operation: self)
                return
            }
        }
        if let path = location?.path, let data = NSData(contentsOfFile: path) {
            self.imageView.image = NSImage(data: data as Data)
        }
        self.delegate.operationAsyncWorkFinished(operation: self)

    }

    override func cancel() {
        if downloadTask != nil {
            downloadTask.cancel()
        }
        if session != nil {
            session.invalidateAndCancel()
        }
        self.delegate.operationAsyncWorkCanceled(operation: self)
        super.cancel()
    }
}
