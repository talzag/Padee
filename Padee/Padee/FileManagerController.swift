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
//          <SKETCH NAME>.pad/              <= Sketch file wrapper
//              <SKETCH NAME>.paths         <= archived
//              <SKETCH NAME>.png           <= rendered image

final class FileManagerController: NSObject {
    fileprivate let sketchPathExtension = "sketch"
    fileprivate let pngPathExtension = "png"
    
    private let fileManager = FileManager.default
    
    private var isUsingiCloud = UserDefaults.standard.bool(forKey: iCloudInUseKey)
    private var iCloudContainerURL: URL?
    
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
    
    override init() {
        super.init()
        
        let manager = fileManager
        
        DispatchQueue.global(qos: .default).async {
            if let iCloudURL = manager.url(forUbiquityContainerIdentifier: nil) {
                self.iCloudContainerURL = iCloudURL
            }
        }
        
        performFileSystemUpgrade()
    }
    
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
    
    func archivedSketches() throws -> [Sketch?] {
        var sketches = [Sketch?]()
        do {
            let pathURLs = try fileManager.contentsOfDirectory(atPath: sketchesDirectoryURL.path).filter({ $0.hasSuffix(sketchPathExtension) }).sorted(by: >)
            
            let mapped = pathURLs.map { (path: String) -> Sketch? in
                let ext = path.range(of: ".\(self.sketchPathExtension)")!
                let name = path.substring(to: ext.lowerBound)
                var sketch: Sketch?
                
                if let archiveData = try? Data(contentsOf: sketchesDirectoryURL.appendingPathComponent(path)),
                   let archive = NSKeyedUnarchiver.unarchiveObject(with: archiveData) as? Sketch {
                    sketch = archive
                    sketch?.name = name
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
    
    func deleteSketches(_ sketches: [Sketch?], _ completionHandler: ((_ deleted: [String]) -> ())?) {
        var sketchNames = [String]()
        
        for sketch in sketches {
            if let sketch = sketch {
                sketchNames.append(sketch.name)
                deleteSketch(sketch)
            }
        }
        
        if let handler = completionHandler {
            handler(sketchNames)
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
        guard let oldName = sketch.name else {
            fatalError("Trying to call rename(_:,_:) with a Sketch that hasn't been named yet.")
        }
        
        let originalURL = archiveURLFor(sketch)
        
        sketch.name = newName
        let newURL = archiveURLFor(sketch)
        
        let oldSketchURL = originalURL.appendingPathExtension(sketchPathExtension)
        let oldPNGURL = originalURL.appendingPathExtension(pngPathExtension)
        
        do {
            if fileManager.fileExists(atPath: oldSketchURL.path) {
                let newSketchURL = newURL.appendingPathExtension(sketchPathExtension)
                try fileManager.moveItem(at: oldSketchURL, to: newSketchURL)
            }
            
            if fileManager.fileExists(atPath: oldPNGURL.path) {
                let newPNGURL = newURL.appendingPathExtension(pngPathExtension)
                try fileManager.moveItem(at: oldPNGURL, to: newPNGURL)
            }
            
            NotificationCenter.default.post(name: .FileManagerDidRenameSketch,
                                            object: self,
                                            userInfo: ["oldName": oldName, "newName": newName])
        
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func moveSketchesToUbiquityContainer() {
        let manager = fileManager
        
        DispatchQueue.global(qos: .default).async {
            guard let ubiquityURL = manager.url(forUbiquityContainerIdentifier: nil) else {
                return
            }
            
            do {
                let sketches = try self.archivedSketches()
                for sketch in sketches {
                    if let sketch = sketch {
                        let url = self.archiveURLFor(sketch)
                        // FIXME: Need to change file system representation of Sketches
                        try manager.setUbiquitous(true, itemAt: url, destinationURL: ubiquityURL)
                    }
                }
            } catch {
                // try again later?
                print(error.localizedDescription)
            }
        }
    }
    
    func evictSketchesFromUbiquityContainer() {
        let manager = fileManager
        
        DispatchQueue.global(qos: .default).async {
            do {
                let sketches = try self.archivedSketches()
                for sketch in sketches {
                    if let sketch = sketch {
                        // FIXME: Replace archive URL with iCloud archive URL
                        let url = self.archiveURLFor(sketch)
                        try manager.evictUbiquitousItem(at: url)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
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
    
    fileprivate func performFileSystemUpgrade() {
        if UserDefaults.standard.bool(forKey: "com.dstrokis.Padee.hasNewFS") {
            return
        }
        
        do {
            let sketches = try archivedSketches()
            let images = try renderedImages()
            
            let zipped = zip(sketches, images)
            let packaged = Array(zipped)
            
            let directoryURL: URL
            if isUsingiCloud {
                directoryURL = fileManager.url(forUbiquityContainerIdentifier: nil)!
            } else {
                directoryURL = sketchesDirectoryURL
            }
            
            for (sketch, thumbnail) in packaged {
                let docURL = directoryURL.appendingPathComponent(sketch!.name).appendingPathExtension(".pad")
                try fileManager.createDirectory(at: docURL, withIntermediateDirectories: false, attributes: nil)
                
                let document = SketchPadFile(fileURL: docURL)
                document.prerenderedSketchImage = thumbnail
                document.sketch = sketch
                
                document.save(to: document.fileURL, for: .forCreating) { (success) in
                    if !success {
                        print("Error saving document")
                    }
                }
            }
            
            UserDefaults.standard.set(true, forKey: "com.dstrokis.Padee.hasNewFS")
        } catch {
            
        }
    }
}
