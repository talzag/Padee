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
//      com.dstrokis.Padee.current          <= current sketch name (will move to UserDefaults)
//      com.dstrokis.Padee.sketches/        <= archived sketches
//          <SKETCH NAME>                   <= Sketch file wrapper (regular file wrapper with paths archived as Data)

final class FileManagerController: NSObject {
    fileprivate let filesUpgradedKey = "com.dstrokis.Padee.files-upgraded"
    
    private let fileManager = FileManager.default
    
    private var isUsingiCloud = UserDefaults.standard.bool(forKey: iCloudInUseKey)
    private var iCloudContainerURL: URL?
    
    lazy var currentSketchURL: URL = {
        let documentsDirectory: URL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        let currentImagePathURL = documentsDirectory.appendingPathComponent("com.dstrokis.Padee.current")
        return currentImagePathURL
    }()
    
    lazy var sketchesDirectoryURL: URL = {
        let documentsDirectory: URL
        if self.isUsingiCloud, let url = self.iCloudContainerURL ?? FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            documentsDirectory = url
        } else {
            documentsDirectory = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        
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
        
        DispatchQueue.global().async {
            if let iCloudURL = manager.url(forUbiquityContainerIdentifier: nil) {
                self.iCloudContainerURL = iCloudURL
            }
        }

        if !UserDefaults.standard.bool(forKey: filesUpgradedKey) {
            performFileSystemUpgrade()
        }
    }
    
    func archive(_ sketch: Sketch, completionHandler: ((Bool) -> Void)? = nil) {
        let fileURL = archiveURLFor(sketch)
        
        let file = SketchPadFile(fileURL: fileURL)
        file.sketch = sketch
        
        file.save(to: fileURL, for: .forCreating) { (success) in
            completionHandler?(success)
        }
    }
    
    func lastSavedSketch() -> SketchPadFile? {
        guard fileManager.fileExists(atPath: currentSketchURL.path) else {
            return nil
        }
        
        let current = SketchPadFile(fileURL: currentSketchURL)
        return current
    }
    
    func archivedSketches() throws -> [SketchPadFile] {
        var sketches = [SketchPadFile]()
        do {
            let paths = try fileManager.contentsOfDirectory(at: sketchesDirectoryURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            for path in paths {
                let file = SketchPadFile(fileURL: path)
                sketches.append(file)
            }
        } catch let error {
            print(error.localizedDescription)
        }
        
        return sketches
    }
    
    func deleteSketches(_ sketches: [SketchPadFile?], _ completionHandler: ((_ deleted: [String]) -> ())?) {
        var sketchURLs = [String]()
        
        for sketch in sketches {
            if let sketch = sketch {
                sketchURLs.append(sketch.fileURL.path)
                deleteSketch(sketch)
            }
        }
        
        if let handler = completionHandler {
            handler(sketchURLs)
        }
        
        NotificationCenter.default.post(name: .FileManagerDidDeleteSketches,
                                        object: self,
                                        userInfo: ["sketches" : sketchURLs])
    }
    
    func sketch(named sketchName: String) -> SketchPadFile? {
        let fileURL = sketchesDirectoryURL.appendingPathComponent(sketchName)
        
        var sketch: SketchPadFile?
        if fileManager.fileExists(atPath: fileURL.path) {
            sketch = SketchPadFile(fileURL: fileURL)
        }
        
        return sketch
    }
    
    func rename(sketchPadFile: SketchPadFile, to newName: String) {
        let oldName = sketchPadFile.fileURL.lastPathComponent
        let originalURL = sketchPadFile.fileURL
        
        let newURL = sketchesDirectoryURL.appendingPathComponent(newName)
        
        do {
            if fileManager.fileExists(atPath: originalURL.path) {
                try fileManager.moveItem(at: originalURL, to: newURL)
            }
            
            NotificationCenter.default.post(name: .FileManagerDidRenameSketch,
                                            object: self,
                                            userInfo: ["oldName": oldName, "newName": newName])
        
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func moveSketchesToUbiquityContainer() {
        DispatchQueue.global().async { [unowned self] in
            let sketchesDirURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("com.dstrokis.Padee.sketches", isDirectory: true)
            guard let iCloudDirURL = self.fileManager.url(forUbiquityContainerIdentifier: nil) else {
                return
            }
            
            do {
                try self.fileManager.moveItem(at: sketchesDirURL, to: iCloudDirURL)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func evictSketchesFromUbiquityContainer() {
        let sketchesDirURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("com.dstrokis.Padee.sketches", isDirectory: true)
        guard let iCloudDirURL = self.fileManager.url(forUbiquityContainerIdentifier: nil) else {
            return
        }
        
        do {
            try self.fileManager.moveItem(at: iCloudDirURL, to: sketchesDirURL)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func deleteSketch(_ sketch: SketchPadFile) {
        if fileManager.fileExists(atPath: sketch.fileURL.path) {
            try? fileManager.removeItem(atPath: sketch.fileURL.path)
        }
    }
    
    private func archiveURLFor(_ sketch: Sketch) -> URL {
        return sketchesDirectoryURL.appendingPathComponent(sketch.name)
    }
    
    fileprivate func _archivedSketches() -> [Sketch?] {
        var sketches = [Sketch?]()
        
        do {
            let sketchesDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("com.dstrokis.Padee.upgrade-backup", isDirectory: true)
            let pathURLs = try fileManager.contentsOfDirectory(atPath: sketchesDirURL.path).filter({ $0.hasSuffix("sketch") }).sorted(by: >)

            let mapped = pathURLs.map { (path: String) -> Sketch? in
                let ext = path.range(of: ".sketch")!
                let name = path.substring(to: ext.lowerBound)
                var sketch: Sketch?

                if let archiveData = try? Data(contentsOf: sketchesDirURL.appendingPathComponent(path)),
                   let archive = NSKeyedUnarchiver.unarchiveObject(with: archiveData) as? Sketch {
                    sketch = archive
                    sketch?.name = name
                }

                return sketch
            }
            
            sketches.append(contentsOf: mapped)
        } catch {
            print(error.localizedDescription)
        }
        
        return sketches
    }
    
    fileprivate func _prerenderedSketches() -> [UIImage?] {
        var images = [UIImage?]()
        
        do {
            let sketchesDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("com.dstrokis.Padee.upgrade-backup", isDirectory: true)
            let pathURLs = try fileManager.contentsOfDirectory(atPath: sketchesDirURL.path).filter({ $0.hasSuffix("png") }).sorted(by: >)
            
            images = pathURLs.map { UIImage(contentsOfFile: sketchesDirURL.appendingPathComponent($0).path) }
        } catch {
            print(error.localizedDescription)
        }
        
        return images
    }
    
    fileprivate func performFileSystemUpgrade() {
        do {
            let sketchesDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("com.dstrokis.Padee.sketches", isDirectory: true)
            let backupDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("com.dstrokis.Padee.upgrade-backup", isDirectory: true)
            
            try fileManager.moveItem(at: sketchesDirURL, to: backupDirectory)
            try fileManager.createDirectory(at: sketchesDirURL, withIntermediateDirectories: false, attributes: nil)
            
            let sketches = _archivedSketches()
            let thumbnails = _prerenderedSketches()
            
            let zipped = zip(sketches, thumbnails)
            for (sketch, _) in zipped {
                guard let sketch = sketch else {
                    continue
                }
                
                let docURL = archiveURLFor(sketch)
                
                let document = SketchPadFile(fileURL: docURL)
                document.sketch = sketch
                
                document.save(to: docURL, for: .forCreating)
            }
            
            UserDefaults.standard.set(true, forKey: filesUpgradedKey)
        } catch {
            // TODO: Add error handling here
        }
    }
}
