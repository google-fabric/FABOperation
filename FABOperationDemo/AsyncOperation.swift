//
//  AsyncOperation.swift
//  FABOperationDemo
//
//  Created by Andrew McKnight on 3/15/16.
//  Copyright © 2016 Twitter. All rights reserved.
//

import Cocoa
import FABOperation

class AsyncOperation: FABAsyncOperation {
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

        self.asyncCompletion = { errorOptional in
            if let error = errorOptional {
                self.delegate.operationAsyncCompletionCalled(operation: self, withError: error as NSError)
            } else {
                self.delegate.operationAsyncCompletionCalled(operation: self)
            }
        }
    }

    override func main() {
        self.delegate.operationBeganExecuting(operation: self)

        requestWithCompletion(completion: handleCompletion)

        self.delegate.operationMainMethodFinished(operation: self)
    }

    func requestWithCompletion(completion: @escaping (URL?, URLResponse?, Error?) -> Void) {
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: nil, delegateQueue: OperationQueue.main)
        let request = NSURLRequest(url: NSURL(string: self.url)! as URL)
        downloadTask = session.downloadTask(with: request as URLRequest, completionHandler: completion)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(arc4random_uniform(3) + 1))) {
            self.downloadTask.resume()
        }
    }

    func handleCompletion(location: URL?, response: URLResponse?, error: Error?) {
        self.session.invalidateAndCancel()
        if (response as? HTTPURLResponse)?.statusCode != 200 {
            self.delegate.operationAsyncWorkFailed(operation: self)
            self.finishWithError(error ?? NSError(domain: "com.twitter.FABOperationDemo.AsyncOperation.error-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Request 404'd"]))
        } else {
            self.delegate.operationAsyncWorkFinished(operation: self)
            if let path = location?.path, let data = NSData(contentsOfFile: path) {
                self.imageView.image = NSImage(data: data as Data)
            }
            self.finishWithError(nil)
        }
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
