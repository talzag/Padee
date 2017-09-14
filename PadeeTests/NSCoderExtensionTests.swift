//
//  NSCoderExtensionTests.swift
//  Padee
//
//  Created by Daniel Strokis on 9/14/17.
//  Copyright © 2017 Daniel Strokis. All rights reserved.
//

import XCTest
@testable import Padee

class NSCoderExtensionTests: XCTestCase {
    
    func testColorCoding() {
        let blue = UIColor.blue.cgColor
        
        let encoder = NSKeyedArchiver()
        
        encoder.encodeColor(blue)
        let data = encoder.encodedData
        
        XCTAssertNotNil(data)
        
        let decoder = NSKeyedUnarchiver(forReadingWith: data)
        let test = decoder.decodeColor()
        
        XCTAssertNotNil(test)
        XCTAssertEqual(blue.components!, test.components!)
    }
}
