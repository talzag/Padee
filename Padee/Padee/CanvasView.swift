//
//  CanvasView.swift
//  Padee
//
//  Created by Daniel Strokis on 6/29/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

// When passing the [Path] back & forth to other objects,
// nothing needs to be adjusted as CoreGraphics will be 
// drawing in the same coordinate system each time; i.e.
// if a user draws an arrow pointing "up" (pointing towards
// the top of the device), when another CanvasView instance
// is given those paths to restore the sketch, the graphics
// context won't have to be rotated.
// 
// However, when rendering the sketch as a UIImage, the sketch
// will need to rotated so that it still appears right-side up.

final class CanvasView: UIView {
    
    var currentTool: Tool = Tool.Pen
    var canvasBackingImageNeedsClear = false
    var canvasImage: UIImage? {
        get {
            guard let image = canvasBackingImage else {
                return nil
            }
            
            UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0.0)
            let context = UIGraphicsGetCurrentContext()
            
            /*
             let size = pathsForRestoringCurrentImage.map { (p) -> CGRect in
             var rect = CGRect.zero
             for point in p.points {
             rect = rect.union(p.updateRectForPoint(point: point))
             }
             
             return rect
             }.reduce(CGRect.zero) { $0.0.union($0.1) }
             
             UIColor.white.setFill()
             context?.fill(size)
             
             context?.draw(image, in: size)
             */
            
            UIColor.white.setFill()
            context?.fill(UIScreen.main.bounds)
            
            context?.draw(image, in: UIScreen.main.bounds)
            context?.rotate(by: .pi)
            let generatedImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            return generatedImage
        }
        
        set {
            canvasBackingImage = newValue?.cgImage
            canvasBackingImageNeedsClear = false
        }
    }
    
    var pathsForRestoringCurrentImage: [Path] {
        return completedPaths
    }
    
    private var paths = [Path]()
    private var completedPaths = [Path]()
    private var activePaths: NSMapTable<UITouch, Path> = NSMapTable.strongToStrongObjects()
    private var updatingPaths: NSMapTable<UITouch, Path> = NSMapTable.strongToStrongObjects()
    
    private var canvasBackingImage: CGImage?
    private lazy var canvasBackingContext: CGContext? = {
        let scale = UIScreen.main.scale
        var size = self.bounds.size
        
        size.width *= scale
        size.height *= scale
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        context?.concatenate(transform)
        
        return context
    }()
    
    private var needsFullRedraw = true
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.interpolationQuality = .high
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        if needsFullRedraw {
            canvasBackingImage = canvasBackingImageNeedsClear ? nil : canvasBackingImage
            canvasBackingContext?.clear(bounds)
            
            for path in completedPaths {
                path.draw(in: canvasBackingContext)
            }
            
            needsFullRedraw = false
            canvasBackingImageNeedsClear = true
        }
        
        canvasBackingImage = canvasBackingImage ?? canvasBackingContext?.makeImage()
        
        if let image = canvasBackingImage {
            context.draw(image, in: bounds)
        }
        
        for path in paths {
            path.draw(in: context)
        }
    }
    
    func clear() {
        canvasBackingImage = nil
        canvasBackingContext?.clear(bounds)
        paths.removeAll()
        completedPaths.removeAll()
        activePaths.removeAllObjects()
        updatingPaths.removeAllObjects()
        
        needsFullRedraw = true
        
        setNeedsDisplay()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        drawForTouches(touches, withEvent: event)
        
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        drawForTouches(touches, withEvent: event)
        
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        drawForTouches(touches, withEvent: event)
        
        let touch = touches.first!
        guard let path = activePaths.object(forKey: touch) else { return }
        completePath(path: path, forTouch: touch)
        
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        for touch in touches {
            guard let path = activePaths.object(forKey: touch) else {
                return
            }
            
            path.updateWithTouch(touch)
        }
    }
    
    func drawForTouches(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        var updateRect = CGRect.null
        
        for touch in touches {
            let path = activePaths.object(forKey: touch) ?? addActivePath(for: touch)
            
            let rect = path.addPointsForTouch(touch, withEvent: event)
            updateRect = updateRect.union(rect)
        }
        
        setNeedsDisplay(updateRect)
    }
    
    func restoreImage(using paths: [Path]) {
        clear()
        completedPaths = paths
        setNeedsDisplay()
    }
    
    private func addActivePath(for touch: UITouch) -> Path {
        let path = Path(color: currentTool.lineColor, width: currentTool.lineWidth)
        
        activePaths.setObject(path, forKey: touch)
        paths.append(path)
        
        return path
    }
    
    private func completePath(path: Path, forTouch touch: UITouch) {
        activePaths.removeObject(forKey: touch)
        
        paths.remove(at: paths.index(of: path)!)
        completedPaths.append(path)
        
        path.draw(in: canvasBackingContext)
        canvasBackingImage = nil
    }
}
