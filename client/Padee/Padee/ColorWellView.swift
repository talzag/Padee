//
//  ColorWellView.swift
//  Padee
//
//  Created by Daniel Strokis on 7/30/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

@IBDesignable
final class ColorWellView: UIControl {
    @IBInspectable var color: UIColor = UIColor.clear
    @IBInspectable var wellBorderColor: UIColor = UIColor.gray
    @IBInspectable var wellBorderWidth: CGFloat = 2.0
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        color.setFill()
        context?.fillEllipse(in: bounds)
        
        drawWellBorder(inBounds: bounds)
    }
    
    func drawWellBorder(inBounds boundingRect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.saveGState()
        
        wellBorderColor.setStroke()
        
        let width = wellBorderWidth / 2
        let inset = boundingRect.insetBy(dx: width, dy: width)
        context?.setLineWidth(wellBorderWidth)
        context?.strokeEllipse(in: inset)
        
        context?.restoreGState()
    }
}
