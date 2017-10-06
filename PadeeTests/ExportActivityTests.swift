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
        XCTAssertEqual(exportActivity.activityType!, UIActivityType("com.dstrokis.Padee.export"))
        XCTAssertEqual(jpgExportActivity.activityType!, UIActivityType("com.dstrokis.Padee.export.jpg"))
        XCTAssertEqual(pngExportActivity.activityType!, UIActivityType("com.dstrokis.Padee.export.png"))
        XCTAssertEqual(pdfExportActivity.activityType!, UIActivityType("com.dstrokis.Padee.export.pdf"))
    }
    
    func testActivityTitles() {
        XCTAssertNil(exportActivity.activityTitle)
        XCTAssertEqual(jpgExportActivity.activityTitle!, "Save as JPG")
        XCTAssertEqual(pngExportActivity.activityTitle!, "Save as PNG")
        XCTAssertEqual(pdfExportActivity.activityTitle!, "Save as PDF")
    }
    
    func testActivityImages() {
        XCTAssertNil(exportActivity.activityImage)
        XCTAssertTrue(pngExportActivity.activityImage!.isEqual(UIImage(named: "PNG")))
        XCTAssertTrue(jpgExportActivity.activityImage!.isEqual(UIImage(named: "JPG")))
        XCTAssertTrue(pdfExportActivity.activityImage!.isEqual(UIImage(named: "PDF")))
    }
    
    func testActivityCategory() {
        XCTAssertEqual(ExportActivity.activityCategory, UIActivityCategory.action)
        XCTAssertEqual(PDFExportActivity.activityCategory, UIActivityCategory.action)
        XCTAssertEqual(JPGExportActivity.activityCategory, UIActivityCategory.action)
        XCTAssertEqual(PDFExportActivity.activityCategory, UIActivityCategory.action)
    }
    
    func testCanPerformWithItems() {
        XCTAssertTrue(exportActivity.canPerform(withActivityItems: [UIImage()]))
        XCTAssertFalse(pdfExportActivity.canPerform(withActivityItems: []))
        XCTAssertFalse(jpgExportActivity.canPerform(withActivityItems: ["hello"]))
        XCTAssertFalse(pdfExportActivity.canPerform(withActivityItems: [1,2,3]))
    }
    
    func testPrepareWithItems() {
        XCTAssertNil(exportActivity.image)
        exportActivity.prepare(withActivityItems: [UIImage()])
        XCTAssertNotNil(exportActivity.image)
    }
    
    func testPNGPrepareWithItems() {
        XCTAssertNil(pngExportActivity.image)
        pngExportActivity.prepare(withActivityItems: [UIImage()])
        XCTAssertNotNil(pngExportActivity.image)
    }
    
    func testJPGPrepareWithItems() {
        XCTAssertNil(jpgExportActivity.image)
        jpgExportActivity.prepare(withActivityItems: [UIImage()])
        XCTAssertNotNil(jpgExportActivity.image)
    }
    
    func testPDFPrepareWithItems() {
        XCTAssertNil(pdfExportActivity.image)
        pdfExportActivity.prepare(withActivityItems: [UIImage()])
        XCTAssertNotNil(pdfExportActivity.image)
    }
    
    func testJPGPerform() {
        jpgExportActivity.prepare(withActivityItems: [UIImage()])
        jpgExportActivity.perform()
        
        jpgExportActivity.prepare(withActivityItems: [UIImage(named: "JPG") as Any])
        jpgExportActivity.perform()
    }
    
    func testPNGPerform() {
        pngExportActivity.prepare(withActivityItems: [UIImage()])
        pngExportActivity.perform()
        
        pngExportActivity.prepare(withActivityItems: [UIImage(named: "PNG") as Any])
        pngExportActivity.perform()
    }
}
