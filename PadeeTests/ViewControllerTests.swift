//
//  ViewControllerTests.swift
//  Padee
//
//  Created by Daniel Strokis on 9/14/17.
//  Copyright © 2017 Daniel Strokis. All rights reserved.
//

import XCTest
@testable import Padee

class ViewControllerTests: XCTestCase {
    
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
        (viewController.view as! CanvasView).restoreImage(using: [path])
        
        let expectation = self.expectation(description: "Saving a sketch from main view controller")
        
        viewController.saveCurrentSketch { (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSaveCurrentSketchNotification() {
        let path = Path(color: .black, width: 3.0)
        (viewController.view as! CanvasView).restoreImage(using: [path])
        
        _ = self.expectation(forNotification: "FileManagerDidSaveSketchPadFile", object: viewController.fileManagerController)
        
        viewController.saveCurrentSketch()
        
        waitForExpectations(timeout: 1)
    }
}
