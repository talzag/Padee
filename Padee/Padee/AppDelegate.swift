//
//  AppDelegate.swift
//  Padee
//
//  Created by Daniel Strokis on 6/14/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit


let iCloudTokenKey = "com.dstrokis.Padee.iCloud.token"
let iCloudInUseKey = "com.dstrokis.Padee.iCloud.using"

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
        
        NotificationCenter.default.addObserver(self, selector: #selector(iCloudAvailabilityDidChange(_:)), name: .NSUbiquityIdentityDidChange, object: nil)
        
        configureApplicationForiCloudUsage()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        (window?.rootViewController as? ViewController)?.saveCurrentSketch()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        (window?.rootViewController as? ViewController)?.saveCurrentSketch()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type.components(separatedBy: ".").last == newSketchShortcutType {
            startNewSketchForShortcutAction()
        }
    }
    
    // MARK: Helper methods
    
    @objc private func iCloudAvailabilityDidChange(_ notification: Notification) {
        configureApplicationForiCloudUsage()
    }
    
    private func configureApplicationForiCloudUsage() {
        let userDefaults = UserDefaults.standard
        let iCloudToken = FileManager.default.ubiquityIdentityToken
        
        if let token = iCloudToken {
            let tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
            userDefaults.set(tokenData, forKey: iCloudTokenKey)
            
            let usingiCloud = userDefaults.bool(forKey: iCloudInUseKey)
            if !usingiCloud {                
                guard let controller = window?.rootViewController as? ViewController else {
                    return
                }
                
                controller.shouldPromptForiCloudUse = true
            }
        } else {
            userDefaults.removeObject(forKey: iCloudTokenKey)
            self.fileManager.evictSketchesFromUbiquityContainer()
        }
    }
    
    private func startNewSketchForShortcutAction() {
        let viewController = window?.rootViewController as? ViewController
        viewController?.saveCurrentSketch()
        viewController?.clearCanvas()
    }
}
