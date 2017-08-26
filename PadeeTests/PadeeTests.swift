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
    
    var viewController: ViewController!
    
    override func setUp() {
        super.setUp()
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(identifier: "com.dstrokis.Padee"))
        guard let vc = storyboard.instantiateInitialViewController() as? ViewController else {
            fatalError()
        }
        
        viewController = vc
        viewController.loadViewIfNeeded()
    }
    
    override func tearDown() {
        viewController = nil
        
        super.tearDown()
    }
    
    func testFileManagerViewControllerExtension() {
        XCTAssertNotNil(viewController.fileManagerController)
    }
    
    func testShouldAutorotate() {
        XCTAssertFalse(viewController.shouldAutorotate)
    }
    
    func testDefaultToolSelected() {
        let toolButtons = viewController.toolButtons
        
        guard let pen = toolButtons?.filter({ $0.restorationIdentifier == Tool.Pen.rawValue }).first else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(pen.isSelected)
    }
    
    func testInitialSketch() {
        XCTAssertNotNil(viewController.currentSketch)
    }
    
    func testCreateNewSketch() {
        let sketch = viewController.currentSketch
        viewController.createNewSketch()
        XCTAssertNotEqual(sketch, viewController.currentSketch)
    }
    
    func testToolSelected() {
        guard let pencil = viewController.toolButtons?.filter({ $0.restorationIdentifier == Tool.Pencil.rawValue }).first else {
            XCTFail()
            return
        }
        viewController.toolSelected(pencil)
        XCTAssertTrue(pencil.isSelected)
        
        let view = (viewController.view as! CanvasView)
        XCTAssertEqual(view.currentTool, .Pencil)
    }
    
    func testSaveCurrentSketch() {
        let path = Path(color: .black, width: 3.0)
        viewController.currentSketch?.paths = [path]
        
        viewController.saveCurrentSketch()
    }
}
