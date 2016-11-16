//
//  FileManagerController.swift
//  Padee
//
//  Created by Daniel Strokis on 11/5/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit


// Padee file storage layout:
// Documents/
//      com.dstrokis.Padee.current          <= current image data (used for quickly saving/restoring user's last sketch)
//      com.dstrokis.Padee.sketches/        <= archived sketches
//          sketch-<CREATE TIME>.paths      <= archived
//          sketch-<CREATE TIME>.png        <= rendered image

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
    
    func archivedSketches() throws -> [Sketch] {
        var sketches = [Sketch]()
        do {
            let pathURLs = try fileManager.contentsOfDirectory(atPath: sketchesDirectoryURL.path).filter({ $0.hasSuffix("paths") }).sorted(by: <)
            let mapped = pathURLs.map { (path: String) -> Sketch in
                let ext = path.range(of: ".paths")!
                let name = path.substring(to: ext.lowerBound)
                let sketch = Sketch(withName: name)
                
                if let pathData = try? Data(contentsOf: sketchesDirectoryURL.appendingPathComponent(path)) {
                    if let paths = NSKeyedUnarchiver.unarchiveObject(with: pathData) as? [Path] {
                        sketch.paths.append(contentsOf: paths)
                    }
                }
                
                return sketch
            }
            
            sketches.append(contentsOf: mapped)
        } catch let error {
            print(error.localizedDescription)
        }
        
        return sketches
    }
    
    func renderedImages() throws -> [UIImage?] {
        var images = [UIImage?]()
        do {
            let pngURLs = try fileManager.contentsOfDirectory(atPath: sketchesDirectoryURL.path).filter { $0.hasSuffix("png") }.sorted(by: <)
            let mapped = pngURLs.map {
                UIImage(contentsOfFile: sketchesDirectoryURL.appendingPathComponent($0).path)
            }
            
            images.append(contentsOf: mapped)
        } catch let error {
            print(error.localizedDescription)
        }
        
        return images
    }
    
    func archive(_ sketch: Sketch) {
        
    }
    
    func deleteSketch(named sketch: Sketch) {
        let sketchPath = archiveURLFor(sketch).appendingPathExtension("paths").path
        let imagePath = archiveURLFor(sketch).appendingPathExtension("png").path
        
        if fileManager.fileExists(atPath: sketchPath) {
            try? fileManager.removeItem(atPath: sketchPath)
        }
        
        if fileManager.fileExists(atPath: imagePath) {
            try? fileManager.removeItem(atPath: imagePath)
        }
    }
    
    func deleteSketches(_ sketches: [Sketch]) {
        for sketch in sketches {
            deleteSketch(named: sketch)
        }
    }
    
    func sketch(named sketchName: String) -> Sketch? {
        let filePath = sketchesDirectoryURL.appendingPathComponent(sketchName).appendingPathExtension("paths").path
        
        guard fileManager.fileExists(atPath: filePath),
              let pathData = fileManager.contents(atPath: filePath),
              let paths = NSKeyedUnarchiver.unarchiveObject(with: pathData) as? [Path] else {
            return nil
        }
        
        let sketch = Sketch(withName: sketchName)
        sketch.paths.append(contentsOf: paths)
        
        return sketch
    }
    
    private func archiveURLFor(_ sketch: Sketch) -> URL {
        return sketchesDirectoryURL.appendingPathComponent(sketch.name)
    }
}
