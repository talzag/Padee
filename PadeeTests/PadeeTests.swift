//
//  PadeeTests.swift
//  PadeeTests
//
//  Created by Daniel Strokis on 6/14/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import XCTest
@testable import Padee

class PadeeTests: XCTestCase {
    
    var delegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        
        delegate = UIApplication.shared.delegate as! AppDelegate
    }
    
    override func tearDown() {
        delegate = nil
        
        super.tearDown()
    }
    
    func testIsGeneratingDeviceNotifications() {
        _ = delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
        XCTAssertTrue(UIDevice.current.isGeneratingDeviceOrientationNotifications)
    }
    
    func testEndDeviceNotificationsOnBackground() {
        XCTAssertTrue(UIDevice.current.isGeneratingDeviceOrientationNotifications)
        delegate.applicationDidEnterBackground(UIApplication.shared)
        XCTAssertFalse(UIDevice.current.isGeneratingDeviceOrientationNotifications)
    }
    
    func testEndDeviceNotificationOnTerminate() {
        XCTAssertTrue(UIDevice.current.isGeneratingDeviceOrientationNotifications)
        delegate.applicationWillTerminate(UIApplication.shared)
    }
    
    func testSaveSketchOnBackground() {
        let vc = UIApplication.shared.keyWindow?.rootViewController as! ViewController
        
        let paths = Path(color: .black, width: 3.0)
        (vc.view as! CanvasView).restoreImage(using: [paths])
        
        XCTAssertEqual(vc.currentSketch!.paths.count, 0)
        
        delegate.applicationDidEnterBackground(UIApplication.shared)
        
        XCTAssertEqual(vc.currentSketch!.paths, [paths])
    }
    
    func testNewSketchShortCut() {
        let vc = delegate.window?.rootViewController as? ViewController
        let canvas = (vc?.view) as? CanvasView
        let path = Path(color: .black, width: 3.0)
        canvas?.restoreImage(using: [path])
        
        let sketch = vc?.currentSketch
        
        delegate.startNewSketchForShortcutAction()
        XCTAssertEqual(canvas?.pathsForRestoringCurrentImage.count, 0)
        XCTAssertNotEqual(sketch, vc?.currentSketch)
    }
    
    func testLaunchFromNewSketchShortcut() {
        let vc = delegate.window?.rootViewController as? ViewController
        let canvas = (vc?.view) as? CanvasView
        let path = Path(color: .black, width: 3.0)
        canvas?.restoreImage(using: [path])
        let sketch = vc?.currentSketch
        
        let shortcutAction = UIApplicationShortcutItem(type: "com.dstrokis.Padee.new-sketch", localizedTitle: "New Sketch")
        let result = delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: [.shortcutItem : shortcutAction])
        
        XCTAssertTrue(result)
        XCTAssertEqual(canvas?.pathsForRestoringCurrentImage.count, 0)
        XCTAssertNotEqual(sketch, vc?.currentSketch)
    }
    
    func testLaunchFromInvalidShortcut() {
        let shortcutAction = UIApplicationShortcutItem(type: "com.dstrokis.Padee.invalid", localizedTitle: "New Sketch")
        let result = delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: [.shortcutItem : shortcutAction])
        
        XCTAssertFalse(result)
    }
    
    func testPerformActionForShortcutItem() {
        let vc = delegate.window?.rootViewController as? ViewController
        let canvas = (vc?.view) as? CanvasView
        let path = Path(color: .black, width: 3.0)
        canvas?.restoreImage(using: [path])
        let sketch = vc?.currentSketch
        
        let shortcutAction = UIApplicationShortcutItem(type: "com.dstrokis.Padee.new-sketch", localizedTitle: "New Sketch")
        
        delegate.application(UIApplication.shared, performActionFor: shortcutAction) { (success) in
            XCTAssertTrue(success)
            XCTAssertEqual(canvas?.pathsForRestoringCurrentImage.count, 0)
            XCTAssertNotEqual(sketch, vc?.currentSketch)
        }
    }
    
    func testPerformActionForInvalidShortcutItem() {
        let shortcutAction = UIApplicationShortcutItem(type: "com.dstrokis.Padee.invalid", localizedTitle: "New Sketch")
        
        delegate.application(UIApplication.shared, performActionFor: shortcutAction) { (success) in
            XCTAssertFalse(success)
        }
    }
    
    func testiCloudAvailabilityChangeHandler() {
        delegate.iCloudAvailabilityDidChange()
    }
}
