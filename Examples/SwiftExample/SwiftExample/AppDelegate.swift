//
//  AppDelegate.swift
//  SwiftExample
//
//  Created by Cory Dolphin on 3/17/16.
//  Copyright © 2016 Twitter. All rights reserved.
//

import UIKit
import FABOperation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let operation = RandomDelayedOperation()
        operation.asyncCompletion = { error -> Void in
            print(error)
        }
        operation.start()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

class RandomDelayedOperation: FABAsyncOperation {
    override func main() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) { () -> Void in
            var error: NSError?
            if random() % 1 == 0 {
                error = NSError(domain: "Dummy", code: 0, userInfo: nil)
            }
            self.finish(error)
        }
    }

    private func finish(asyncError: NSError?) {
        // set this operation as done
        // NSOperation's completionBlock will execute immediately if one was provided
        // this could also be done after calling asyncCompletion, it's up to you
        self.markDone()

        // check for some possible failure modes
        var errorInfo = [String: AnyObject]()
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

