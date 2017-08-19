//
//  ToolTests.swift
//  Padee
//
//  Created by Daniel Strokis on 8/19/17.
//  Copyright © 2017 Daniel Strokis. All rights reserved.
//

import XCTest
@testable import Padee

class ToolTests: XCTestCase {
    
    var pencil: Tool!
    var pen: Tool!
    var eraser: Tool!
    
    override func setUp() {
        super.setUp()
        
        pencil = Tool.Pencil
        pen = Tool.Pen
        eraser = Tool.Eraser
    }
    
    override func tearDown() {
        pencil = nil
        pen = nil
        eraser = nil
        
        super.tearDown()
    }
    
    func testLineWidth() {
        XCTAssertEqual(pencil.lineWidth, 1.0)
        XCTAssertEqual(pen.lineWidth, 3.0)
        XCTAssertEqual(eraser.lineWidth, 20.0)
    }
    
    func testLineColor() {
        XCTAssertEqual(pencil.lineColor, .gray)
        XCTAssertEqual(pen.lineColor, .black)
        XCTAssertEqual(eraser.lineColor, .white)
    }
}
