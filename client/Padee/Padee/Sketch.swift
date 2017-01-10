//
//  Sketch.swift
//  Padee
//
//  Created by Daniel Strokis on 11/12/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import Foundation

final class Sketch: NSObject, NSCoding {
    
    private struct SketchPropertyKey {
        static let nameKey = "name"
        static let pathsKey = "paths"
    }
    
    var name: String!
    var paths = [Path]()
    
    init(withName name: String) {
        super.init()
        self.name = name
    }
    
    override init() {
        super.init()
        
        let creationTime = Int(Date.timeIntervalSinceReferenceDate)
        self.name = "sketch-\(creationTime)"
    }
    
    init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: SketchPropertyKey.nameKey) as! String
        self.paths = aDecoder.decodeObject(forKey: SketchPropertyKey.pathsKey) as! [Path]
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: SketchPropertyKey.nameKey)
        aCoder.encode(paths, forKey: SketchPropertyKey.pathsKey)
    }
}
