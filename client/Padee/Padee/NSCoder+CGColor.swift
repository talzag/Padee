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
        guard let components = color.components else {
            return
        }
        
        var colorValues = Array(repeating: components.first!, count: NSCoder.cgColorComponentKeys.count - 1)
        colorValues.append(components.last!)
        let colorData = zip(NSCoder.cgColorComponentKeys, colorValues)
        
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
        
        let color = withUnsafePointer(to: &colors, { (ptr) -> CGColor in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            return CGColor(colorSpace: colorSpace, components: ptr.pointee)!
        })
        
        return color
    }
}

