//
//  Path.swift
//  Padee
//
//  Created by Daniel Strokis on 7/31/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

final class Path: NSObject, NSCoding {
    
    private struct PathPropertyKey {
        static let pointsKey = "points"
        static let colorKey = "lineColor"
        static let widthKey = "lineWidth"
        static let joinKey = "lineJoin"
        static let capKey = "lineCap"
        static var colorComponentKeys = ["greyscale", "alpha"]
    }
    
    var points = [Point]()
    var pointsWaitingForUpdate = [NSNumber : Point]()
    
    var lineColor: CGColor
    let lineWidth: CGFloat
    var lineJoin: CGLineJoin
    var lineCap: CGLineCap
    
    init(color: UIColor, width: CGFloat, join: CGLineJoin = .round, cap: CGLineCap = .round) {
        lineColor = color.cgColor
        lineWidth = width
        lineJoin = join
        lineCap = cap
    }
    
    func addPointsForTouch(_ touch: UITouch, withEvent event: UIEvent?) -> CGRect {
        var updateRect = CGRect.null
        
        let coalescedTouches = event?.coalescedTouches(for: touch) ?? []
        for (index, touch) in coalescedTouches.enumerated() {
            let type: PointType
            
            if index == coalescedTouches.count - 1 {
                type = .default
            } else {
                type = .coalesced
            }
            
            let point = Point(withTouch: touch, andType: type)
            
            if let updateIndex = point.estimationUpdateIndex {
                pointsWaitingForUpdate[updateIndex] = point
            }
            
            let pointRect = updateRectForPoint(point: point)
            updateRect = updateRect.union(pointRect)
            
            if let last = points.last {
                let rect = updateRectForPoint(point: last)
                updateRect = updateRect.union(rect)
            }
            
            points.append(point)
        }
    
        return updateRect
    }
    
    func updateWithTouch(_ touch: UITouch) {
        guard let updateIndex = touch.estimationUpdateIndex,
              let point = pointsWaitingForUpdate[updateIndex] else {
            return
        }
        
        point.updateWithTouch(touch)
        
        guard let properties = point.propertiesExpectingUpdates,
              properties.isEmpty else {
            return
        }
        
        pointsWaitingForUpdate.removeValue(forKey: updateIndex)
    }
    
    func updateRectForPoint(point: Point) -> CGRect {
        var rect = CGRect(origin: point.location, size: CGSize.zero)
        
        let magnitude: CGFloat = -10.0
        rect = rect.insetBy(dx: magnitude, dy: magnitude)
        
        return rect
    }
    
    func removePointsOfType(_ type: PointType) -> CGRect {
        var updateRect = CGRect.null
        var previous: Point?
        
        points = points.filter { (point) -> Bool in
            let keep = point.type != type
            
            if !keep {
                var rect = self.updateRectForPoint(point: point)
                
                if let prev = previous {
                    let prevRect = self.updateRectForPoint(point: prev)
                    rect = rect.union(prevRect)
                }
                
                updateRect = updateRect.union(rect)
            }
            
            previous = point
            
            return keep
        }
        
        return updateRect
    }
    
    func draw(in context: CGContext?) {
        guard let context = context else {
            return
        }
        
        context.saveGState()
        
        context.setLineCap(lineCap)
        context.setLineJoin(lineJoin)
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor)
        
        var previousPoint: Point?
        
        context.beginPath()
        
        for point in points {
            guard let previous = previousPoint else {
                previousPoint = point
                continue
            }
            
            context.move(to: CGPoint(x: previous.location.x, y: previous.location.y))
            context.addLine(to: CGPoint(x: point.location.x, y: point.location.y))
            
            previousPoint = point
        }
        
        context.strokePath()
        
        context.restoreGState()
    }
    
    // MARK: NSCoding
    
    init?(coder aDecoder: NSCoder) {
        lineWidth =  CGFloat(aDecoder.decodeDouble(forKey: PathPropertyKey.widthKey))
        lineJoin = CGLineJoin(rawValue: aDecoder.decodeCInt(forKey: PathPropertyKey.joinKey))!
        lineCap = CGLineCap(rawValue: aDecoder.decodeCInt(forKey: PathPropertyKey.capKey))!
        points = aDecoder.decodeObject(forKey: PathPropertyKey.pointsKey) as? [Point] ?? []
        lineColor = aDecoder.decodeColor()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(Double(lineWidth), forKey: PathPropertyKey.widthKey)
        aCoder.encode(lineCap.rawValue, forKey: PathPropertyKey.capKey)
        aCoder.encode(lineJoin.rawValue, forKey: PathPropertyKey.joinKey)
        
        if points.count > 0 {
            aCoder.encode(points, forKey: PathPropertyKey.pointsKey)
        }
        
        aCoder.encodeColor(lineColor)
    }
}

enum PointType: Int {
    case `default`
    case coalesced
    case predicted
}

final class Point: NSObject, NSCoding {
    
    private struct PointPropertyKey {
        static let type = "type"
        static let location = "location"
    }
    
    var location: CGPoint
    let type: PointType
    var estimationUpdateIndex: NSNumber?
    var propertiesExpectingUpdates: UITouchProperties?
    
    init(withTouch touch: UITouch, andType type: PointType) {
        let view = touch.view
        location = touch.preciseLocation(in: view)
        self.type = type
        estimationUpdateIndex = touch.estimationUpdateIndex
        propertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
    }
    
    func updateWithTouch(_ touch: UITouch) {
        guard let updateIndex = touch.estimationUpdateIndex,
              estimationUpdateIndex == updateIndex else {
                return
        }
        
        propertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
        location = touch.preciseLocation(in: touch.view)
    }
    
    // MARK: NSCoding
    
    init?(coder aDecoder: NSCoder) {
        location = aDecoder.decodeCGPoint(forKey: PointPropertyKey.location)
        
        if let pointType = PointType(rawValue: aDecoder.decodeInteger(forKey:  PointPropertyKey.type)) {
            type = pointType
        } else {
            type = .default
        }
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(type.rawValue, forKey:  PointPropertyKey.type)
        aCoder.encode(location, forKey:  PointPropertyKey.location)
    }
}
