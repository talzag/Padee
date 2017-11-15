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
        
        updateRect = removePointsOfType(.predicted)
        
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
        
        let predictedTouches = event?.predictedTouches(for: touch) ?? []
        for touch in predictedTouches {
            let point = Point(withTouch: touch, andType: .predicted)
            
            let pointRect = updateRectForPoint(point: point)
            updateRect = updateRect.union(pointRect)
            
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
        
        let magnitude: CGFloat = -100.0
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
    
    /// Cached `CGPath` to prevent creating new `CGPath`'s on each `draw(in:)` call
    private var _cachedCGPath: CGPath?
    
    /// The last point in `self._cachedCGPath`. Used as a starting point in `self.points` iteration, instead of having to iterate from the beginning of the collection
    private var _lastPointForCachedPath: Point?
    
    var cgPath: CGPath {
        var i = 0
        var curvePoints = Array<CGPoint?>(repeating: nil, count: 5)
        
        let mutablePath = CGMutablePath()
        
        var iteratePoints = points
        
        if let cachedPath = _cachedCGPath {
            mutablePath.addPath(cachedPath)

            if let lastPoint = _lastPointForCachedPath {
                mutablePath.move(to: lastPoint.location)

                if let index = points.index(of: lastPoint) {
                    iteratePoints = Array(points.suffix(from: index - 1))
                }
            }
        }
        
        for point in iteratePoints {
            guard let start = curvePoints[0] else {
                curvePoints[0] = point.location
                mutablePath.move(to: point.location)
                i += 1
                continue
            }
            
            if point.location.distance(from: start) < 1.0 {
                continue
            }
            
            _lastPointForCachedPath = point
            curvePoints[i] = point.location
            i += 1
            
            if i < 5 {
                continue
            }
            
            guard let c1 = curvePoints[1],
                let c2 = curvePoints[2],
                let next = curvePoints[4] else {
                    fatalError()
            }
            
            let x = (c2.x + next.x) / 2.0
            let y = (c2.y + next.y) / 2.0
            let end = CGPoint(x: x, y: y)
            mutablePath.addCurve(to: end, control1: c1, control2: c2)
            
            curvePoints[0] = end
            curvePoints[1] = next
            
            mutablePath.move(to: end)
            
            i = 1
        }
        
        _cachedCGPath = mutablePath
        
        return mutablePath
    }

    
    func draw(in context: CGContext) {
        context.saveGState()
        
        context.setLineCap(lineCap)
        context.setLineJoin(lineJoin)
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor)
        
        context.beginPath()
        context.addPath(cgPath)
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

extension CGPoint {
    /// Caclulates the quadrance of two points
    ///
    /// - Parameter point: Other point
    /// - Returns: Quadrance of `self` and another point.
    func distance(from point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        
        return pow(dx, 2) + pow(dy, 2)
    }
}
