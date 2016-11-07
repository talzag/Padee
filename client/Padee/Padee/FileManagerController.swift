//
//  FileManagerController.swift
//  Padee
//
//  Created by Daniel Strokis on 11/5/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

final class FileManagerController: NSObject {
    private let fileManager = FileManager.default
    
    lazy var currentImagePathURL: URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let currentImagePathURL = documentsDirectory.appendingPathComponent("com.dstrokis.Padee.current", isDirectory: false)
        return currentImagePathURL
    }()
    
    lazy var sketchesDirectoryURL: URL = {
        let documentsDirectory = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sketchesURL = documentsDirectory.appendingPathComponent("com.dstrokis.Padee.sketches", isDirectory: true)
        
        if !self.fileManager.fileExists(atPath: sketchesURL.path, isDirectory: nil) {
            do {
                try self.fileManager.createDirectory(at: sketchesURL, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                fatalError("Could not create sketches directory")
            }
        }
        
        return sketchesURL
    }()
    
    func archive(_ sketch: Sketch) {
        
    }
    
    func deleteSketch(named name: String) {
        
    }
    
    func drawingPaths(for sketchName: String) {
        
    }
}
