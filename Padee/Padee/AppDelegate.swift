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
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(iCloudAvailabilityDidChange(_:)),
                                               name: .NSUbiquityIdentityDidChange,
                                               object: nil)
        
        configureApplicationForiCloudUsage()
        
        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            if shortcutItem.type.components(separatedBy: ".").last == newSketchShortcutType  {
                startNewSketchForShortcutAction()
                return true
            }
            
            return false
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        (window?.rootViewController as? ViewController)?.saveCurrentSketch()
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        (window?.rootViewController as? ViewController)?.saveCurrentSketch()
        (window?.rootViewController as? ViewController)?.clearCanvas({ success in  })
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type.components(separatedBy: ".").last == newSketchShortcutType {
            startNewSketchForShortcutAction()
        }
    }
    
    private func startNewSketchForShortcutAction() {
        (window?.rootViewController as? ViewController)?.createNewSketch()
    }
    
    // MARK: iCloud
    
    @objc private func iCloudAvailabilityDidChange(_ notification: Notification) {
        configureApplicationForiCloudUsage()
    }
    
    private func configureApplicationForiCloudUsage() {
//        let userDefaults = UserDefaults.standard
//        let iCloudToken = FileManager.default.ubiquityIdentityToken
//        
//        if let token = iCloudToken {
//            let tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
//            userDefaults.set(tokenData, forKey: iCloudTokenKey)
//            
//            let usingiCloud = userDefaults.bool(forKey: iCloudInUseKey)
//            if !usingiCloud {                
//                guard let controller = window?.rootViewController as? ViewController else {
//                    return
//                }
//                
//                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
//                    UserDefaults.standard.set(true, forKey: iCloudInUseKey)
//                })
//                
//                let iCloudAction = UIAlertAction(title: "Use iCloud", style: .default, handler: { (action) in
//                    UserDefaults.standard.set(true, forKey: iCloudInUseKey)
//                    controller.fileManagerController.moveSketchesToUbiquityContainer()
//                })
//                
//                let alert = UIAlertController(title: "Use iCloud?", message: "Would you like to store your documents in iCloud? This can be changed at any time in Settings.", preferredStyle: .alert)
//                
//                alert.addAction(cancel)
//                alert.addAction(iCloudAction)
//                
//                DispatchQueue.main.async {
//                    controller.present(alert, animated: true, completion: nil)
//                }
//            }
//        } else {
//            userDefaults.removeObject(forKey: iCloudTokenKey)
//            userDefaults.set(false, forKey: iCloudInUseKey)
//            self.fileManager.evictSketchesFromUbiquityContainer()
//        }
    }
}
