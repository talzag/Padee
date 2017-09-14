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
    
    func X_testEndDeviceNotificationsOnBackground() {
        XCTAssertTrue(UIDevice.current.isGeneratingDeviceOrientationNotifications)
        delegate.applicationDidEnterBackground(UIApplication.shared)
        XCTAssertFalse(UIDevice.current.isGeneratingDeviceOrientationNotifications)
    }
    
    func X_testEndDeviceNotificationOnTerminate() {
        XCTAssertTrue(UIDevice.current.isGeneratingDeviceOrientationNotifications)
        delegate.applicationWillTerminate(UIApplication.shared)
        XCTAssertFalse(UIDevice.current.isGeneratingDeviceOrientationNotifications)
    }
    
    func testSaveSketchOnBackground() {
        let vc = UIApplication.shared.keyWindow?.rootViewController as! ViewController
        
        let paths = Path(color: .black, width: 3.0)
        (vc.view as! CanvasView).restoreImage(using: [paths])
        
        XCTAssertEqual(vc.currentSketch!.paths.count, 0)
        
        delegate.applicationDidEnterBackground(UIApplication.shared)
        
        XCTAssertEqual(vc.currentSketch!.paths, [paths])
    }
}
