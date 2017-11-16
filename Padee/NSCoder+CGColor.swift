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
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let convertedColor = color.converted(to: colorSpace, intent: .perceptual, options: nil) else {
            fatalError()
        }
        
        let colorData = zip(NSCoder.cgColorComponentKeys, convertedColor.components!)
        
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
        
        // TODO: Did this commit make it out in a build? Want to check before releasing a solution to a problem that might not exist
        // Fixing an encoding error I made in a previous commit
        if  colors[0] > 0.0 || colors[1] > 0.0 {
            let grayColorSpace = CGColorSpaceCreateDeviceGray()
            let grayColor = CGColor(colorSpace: grayColorSpace, components: [colors[0], colors[1]])!
            let correctColor = grayColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .perceptual, options: nil)!
            
            return correctColor
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let color = CGColor(colorSpace: colorSpace, components: colors)!
        
        return color
    }
}

