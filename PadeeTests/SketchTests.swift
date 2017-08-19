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
    
    func testSketchInit() {
        let sketch = Sketch()
        XCTAssertNotNil(sketch.name)
    }
    
    func testSketchInitWithName() {
        let name = "Test Sketch"
        let sketch = Sketch(withName: name)
        XCTAssertEqual(sketch.name, name)
    }
    
    func testSketchNSCoding() {
        let sketch = Sketch()
        
        let name = sketch.name
        
        let archiver = NSKeyedArchiver()
        sketch.encode(with: archiver)
        
        let data = archiver.encodedData
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        let decoded = Sketch(coder: unarchiver)
        
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.name, name)
    }
}
