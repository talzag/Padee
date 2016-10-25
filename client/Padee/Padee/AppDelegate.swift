//
//  AppDelegate.swift
//  Padee
//
//  Created by Daniel Strokis on 6/14/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        (window?.rootViewController as? ViewController)?.saveCurrentImage()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        (window?.rootViewController as? ViewController)?.saveCurrentImage()
    }
}
