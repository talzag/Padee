//
//  ExportActivityTests.swift
//  Padee
//
//  Created by Daniel Strokis on 9/14/17.
//  Copyright © 2017 Daniel Strokis. All rights reserved.
//

import XCTest
@testable import Padee

class ExportActivityTests: XCTestCase {
    
    var exportActivity: ExportActivity!
    var jpgExportActivity: JPGExportActivity!
    var pngExportActivity: PNGExportActivity!
    var pdfExportActivity: PDFExportActivity!
    
    override func setUp() {
        super.setUp()
        
        exportActivity = ExportActivity()
        jpgExportActivity = JPGExportActivity()
        pngExportActivity = PNGExportActivity()
        pdfExportActivity = PDFExportActivity()
    }
    
    override func tearDown() {
        exportActivity = nil
        jpgExportActivity = nil
        pngExportActivity = nil
        pdfExportActivity = nil
        
        super.tearDown()
    }
    
    func testActivityTypes() {
        
    }
    
    func testActivityTitles() {
        XCTAssertNil(exportActivity.activityTitle)
        XCTAssertEqual(jpgExportActivity.activityTitle!, "")
        XCTAssertEqual(pngExportActivity.activityTitle!, "")
        XCTAssertEqual(pdfExportActivity.activityTitle!, "")
    }
    
    func testActivityImages() {
        
    }
    
    func testPrepareWithItems() {
        
    }
    
    func testJPGPerform() {
        
    }
    
    func testPNGPerform() {
        
    }
}
