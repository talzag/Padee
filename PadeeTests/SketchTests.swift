//
//  SketchTests.swift
//  Padee
//
//  Created by Daniel Strokis on 8/19/17.
//  Copyright © 2017 Daniel Strokis. All rights reserved.
//

import XCTest
@testable import Padee

class SketchTests: XCTestCase {
    
    var sketch: Sketch!
    
    override func setUp() {
        super.setUp()
        
        sketch = Sketch()
    }
    
    override func tearDown() {
        sketch = nil
        
        super.tearDown()
    }
    
    func testSketchName() {
        XCTAssertNotNil(sketch.name, "Sketch instances should always have a default name.")
    }
}
