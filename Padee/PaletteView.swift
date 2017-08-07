//
//  PaletteView.swift
//  Padee
//
//  Created by Daniel Strokis on 7/30/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

@IBDesignable
final class PaletteView: UIView {
    @IBInspectable var borderColor: UIColor = UIColor.gray
    @IBInspectable var borderWidth: CGFloat = 3.0
    
    var currentColor = UIColor.clear
    var mixingColors = [UIColor]()
    
    var paintSurfaceRect: CGRect {
        return bounds.insetBy(dx: borderWidth / 2.0, dy: borderWidth / 2.0)
    }
    
    var needsFullRedraw = true
    
    lazy var currentPath: UIBezierPath = {
        let path = UIBezierPath()
        path.lineWidth = 45.0
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        return path
    }()
    
    var commitedPaths = [UIBezierPath: UIColor]()
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        if needsFullRedraw {
            context?.saveGState()
            
            context?.clear(bounds)
            backgroundColor?.setFill()
            context?.fill(paintSurfaceRect)
            drawBorder(in: rect)
            
            context?.restoreGState()
            needsFullRedraw = false
        }
        
        for (path, color) in commitedPaths {
            context?.saveGState()
            
            color.setStroke()
            path.stroke()
            
            context?.restoreGState()
        }
        
        currentColor.setStroke()
        currentPath.stroke()
    }
    
    func clear() {
        mixingColors = [];
        currentColor = UIColor.clear
        needsFullRedraw = true
    }
    
    func drawBorder(in rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.saveGState()
        
        borderColor.setStroke()
        let inset = rect.insetBy(dx: borderWidth / 2.0, dy: borderWidth / 2.0)
        context?.stroke(inset, width: borderWidth)
        
        context?.restoreGState()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.preciseLocation(in: self)
        currentPath.move(to: point)
        
        setNeedsDisplay(paintSurfaceRect)
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.preciseLocation(in: self)
        currentPath.addLine(to: point)
        
        setNeedsDisplay(paintSurfaceRect)
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.preciseLocation(in: self)
        currentPath.addLine(to: point)
        
        let finishedPath = UIBezierPath(cgPath: currentPath.cgPath)
        finishedPath.lineWidth = 45.0
        finishedPath.lineJoinStyle = .round
        finishedPath.lineCapStyle = .round
        currentPath.removeAllPoints()
        
        commitedPaths[finishedPath] = UIColor(cgColor: currentColor.cgColor)
        
        setNeedsDisplay(paintSurfaceRect)
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
