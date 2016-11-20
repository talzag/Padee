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
    let fileManager = FileManagerController()
    
    private let newSketchShortcutType = "new-sketch"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {

        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            if shortcutItem.type.components(separatedBy: ".").last == newSketchShortcutType  {
                startNewSketchForShortcutAction()
                return false
            }
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        (window?.rootViewController as? ViewController)?.saveCurrentImage()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        (window?.rootViewController as? ViewController)?.saveCurrentImage()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type.components(separatedBy: ".").last == newSketchShortcutType {
            startNewSketchForShortcutAction()
        }
    }
    
    // MARK: Helper methods
    
    private func startNewSketchForShortcutAction() {
        let viewController = window?.rootViewController as? ViewController
        viewController?.archiveCurrentImage()
        viewController?.clearCanvas()
    }
}
