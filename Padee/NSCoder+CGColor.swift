//
//  NSCoder+CGColor.swift
//  Padee
//
//  Created by Daniel Strokis on 9/6/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import Foundation
import CoreGraphics

extension NSCoder {
    private static let cgColorComponentKeys = ["r", "g", "b", "a"]
    
    func encodeColor(_ color: CGColor) {
        let colorData = zip(NSCoder.cgColorComponentKeys, color.components!)
        
        for (key, value) in colorData {
            self.encode(Double(value), forKey: key)
        }
    }
    
    func decodeColor() -> CGColor {
        var colors = [CGFloat]()
        for key in NSCoder.cgColorComponentKeys {
            let color = CGFloat(self.decodeDouble(forKey: key))
            colors.append(color)
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let color = CGColor(colorSpace: colorSpace, components: colors)!
        
        return color
    }
}

