//
//  Point.swift
//  Padee
//
//  Created by Daniel Strokis on 11/12/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

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
