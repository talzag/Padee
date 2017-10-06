//
//  PadeeUITests.swift
//  PadeeUITests
//
//  Created by Daniel Strokis on 6/14/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import XCTest

class PadeeUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func testToolSelection() {
        
        let canvasviewElement = XCUIApplication().otherElements["CanvasView"]
        canvasviewElement.swipeDown()
        canvasviewElement.tap()
        canvasviewElement.swipeDown()
        canvasviewElement.tap()
        canvasviewElement.swipeDown()
        
    }
}
