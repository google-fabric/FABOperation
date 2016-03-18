# FABOperation

FABOperation is a small framework with classes that extend Apple's `NSOperation` API. `FABAsyncOperation` is an asynchronous implementation that you can subclass to encapsulate logic involving things like networking or interprocess communication (like working with XPC or `NSTask`). With regular `NSOperation` objects, you have no control over when the `completionBlock` is called–it always executes when `main` finishes–therefore you can't easily communicate the results of asynchronous work properly. With `FABAsyncOperation`, you have complete control over when the operation's `finished` property is set, which controls when the next waiting operation on the queue will be executed, as well as any dependant operations. Dependant operations can be cancelled if asynchronous work fails, and you can pass errors through the `error` parameter in the `asyncCompletion` block. (You can still also use the regular `completionBlock` as well, see `markDone` in `FABAsyncOperation_Private.h` for more on execution order).

`FABCompoundOperation` subclasses `FABAsyncOperation` which you can pass an array of operations, whether sync, async or both, that will execute them on a private array and return when finished. In addition to each suboperation's `completionBlock` and `asyncCompletion` being called, the compound operation's version of each is also called, allowing for a highly flexible way to handle completion of a complex system. 

## Why no Swift?

There are a huge amount of apps out there that have zero Swift in them. We didn't want to force those apps to include the Swift runtime libs. This is a trade-off, and it's one that we hope will become less and less necessary over time.

## Example Usage

Here's a simple way to subclass `FABAsyncOperation` and return either the error from the async work performed, or a message that the operation was cancelled.

```swift
import FABAsyncOperation

class AsyncOperation: FABAsyncOperation {

    override func main() {
        // start a network call, NSTask, etc. whose completion/callback is handled by finish(:)
    }

    private func finish(asyncError: NSError?) {
        // set this operation as done
        // NSOperation's completionBlock will execute immediately if one was provided
        // this could also be done after calling asyncCompletion, it's up to you
        self.markDone()
        
        // check for some possible failure modes
        var errorInfo: [String: AnyObject]
        if self.cancelled {
            errorInfo[NSLocalizedDescriptionKey] = "Operation cancelled"
        }
        if let asyncErrorValue = asyncError {
            errorInfo[NSLocalizedDescriptionKey] = "Async work failed"
            errorInfo[NSUnderlyingErrorKey] = asyncErrorValue
        }

        // package up the error, if there was one
        var error: NSError?
        if errorInfo.count > 0 {
            error = NSError(domain: "my.error.domain", code: 0, userInfo: errorInfo)
        }

        // call asyncCompletion if one was provided
        if let asyncCompletion = self.asyncCompletion {
            asyncCompletion(error)
        }
    }
}
```

## License

The project is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


## Notes

You need to `git submodule update --init --recursive` after cloning the repo.