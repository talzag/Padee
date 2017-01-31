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
//      com.dstrokis.Padee.current          <= current sketch name
//      com.dstrokis.Padee.sketches/        <= archived sketches
//          sketch-<CREATE TIME>.paths      <= archived
//          sketch-<CREATE TIME>.png        <= rendered image

final class FileManagerController: NSObject {
    fileprivate let sketchPathExtension = "sketch"
    fileprivate let pngPathExtension = "png"
    
    private let fileManager = FileManager.default
    
    lazy var currentSketchURL: URL = {
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
    
    func archive(_ sketch: Sketch, with renderedImage: UIImage? = nil) -> Bool {
        let fileURL = archiveURLFor(sketch)
        let sketchURL = fileURL.appendingPathExtension(sketchPathExtension)
        
        if let image = renderedImage, let imageData = UIImagePNGRepresentation(image) {
            let imageFile = fileURL.appendingPathExtension(pngPathExtension)
            let imageWriteSuccess = fileManager.createFile(atPath: imageFile.path, contents: imageData, attributes: nil)
            if !imageWriteSuccess {
                print("Could not archive PNG representation of current image.")
            }
        }
        
        return NSKeyedArchiver.archiveRootObject(sketch, toFile: sketchURL.path) &&
               NSKeyedArchiver.archiveRootObject(sketch, toFile: currentSketchURL.path)
    }
    
    func lastSavedSketch() -> Sketch? {
        guard let sketch = NSKeyedUnarchiver.unarchiveObject(withFile: currentSketchURL.path) as? Sketch else {
            return nil
        }
        
        return sketch
    }
    
    func archivedSketches() throws -> [Sketch] {
        var sketches = [Sketch]()
        do {
            let pathURLs = try fileManager.contentsOfDirectory(atPath: sketchesDirectoryURL.path).filter({ $0.hasSuffix(sketchPathExtension) }).sorted(by: >)
            
            let mapped = pathURLs.map { (path: String) -> Sketch in
                let ext = path.range(of: ".\(self.sketchPathExtension)")!
                let name = path.substring(to: ext.lowerBound)
                var sketch = Sketch(withName: name)
                
                if let archiveData = try? Data(contentsOf: sketchesDirectoryURL.appendingPathComponent(path)),
                   let archive = NSKeyedUnarchiver.unarchiveObject(with: archiveData) as? Sketch {
                    sketch = archive
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
            let pngURLs = try fileManager.contentsOfDirectory(atPath: sketchesDirectoryURL.path).filter { $0.hasSuffix(pngPathExtension) }.sorted(by: >)
            
            let mapped = pngURLs.map {
                UIImage(contentsOfFile: sketchesDirectoryURL.appendingPathComponent($0).path)
            }
            
            images.append(contentsOf: mapped)
        } catch let error {
            print(error.localizedDescription)
        }
        
        return images
    }
    
    func deleteSketches(_ sketches: [Sketch]) {
        var sketchNames = [String]()
        
        for sketch in sketches {
            sketchNames.append(sketch.name)
            deleteSketch(sketch)
        }
        
        NotificationCenter.default.post(name: .FileManagerDidDeleteSketches,
                                        object: self,
                                        userInfo: ["sketches" : sketchNames])
    }
    
    func sketch(named sketchName: String) -> Sketch? {
        let filePath = sketchesDirectoryURL.appendingPathComponent(sketchName).appendingPathExtension(sketchPathExtension).path
        
        guard fileManager.fileExists(atPath: filePath),
              let pathData = fileManager.contents(atPath: filePath),
              let paths = NSKeyedUnarchiver.unarchiveObject(with: pathData) as? [Path] else {
            return nil
        }
        
        let sketch = Sketch(withName: sketchName)
        sketch.paths.append(contentsOf: paths)
        
        return sketch
    }
    
    func rename(sketch: Sketch, to newName: String) {
        let oldName = sketch.name ?? ""
        sketch.name = newName
        NotificationCenter.default.post(name: .FileManagerDidRenameSketch,
                                        object: self,
                                        userInfo: ["oldName": oldName, "newName": newName])
        
        // find sketch & image with oldName
        // update sketch & image with newName
    }
    
    private func deleteSketch(_ sketch: Sketch) {
        let sketchPath = archiveURLFor(sketch).appendingPathExtension(sketchPathExtension).path
        let imagePath = archiveURLFor(sketch).appendingPathExtension(pngPathExtension).path
        
        if fileManager.fileExists(atPath: sketchPath) {
            try? fileManager.removeItem(atPath: sketchPath)
        }
        
        if fileManager.fileExists(atPath: imagePath) {
            try? fileManager.removeItem(atPath: imagePath)
        }
    }
    
    private func archiveURLFor(_ sketch: Sketch) -> URL {
        return sketchesDirectoryURL.appendingPathComponent(sketch.name)
    }
}
