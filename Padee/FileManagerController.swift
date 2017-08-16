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
//      com.dstrokis.Padee.sketches/        <= archived sketches
//          <SKETCH NAME>                   <= Sketch file wrapper (regular file wrapper with paths archived as Data)

/// Handles the creation, saving, deleting, and moving of `SketchPadFile`s in the application. 
/// Users of this class don't need to know if the files they are operating on are stored in
/// iCloud or not.
final class FileManagerController: NSObject {
    private let filesUpgradedKey = "com.dstrokis.Padee.files-upgraded"
    private let backupDirectoryPathComponent = "com.dstrokis.Padee.upgrade-backup"
    
    private let currentSketchKey = "com.dstrokis.Padee.current"
    private let sketchDirectoryPathComponent = "com.dstrokis.Padee.sketches"
    
    private let fileManager = FileManager.default
    
    private var isUsingiCloud = false // UserDefaults.standard.bool(forKey: iCloudInUseKey)
    private var iCloudContainerURL: URL?
    
    lazy var sketchesDirectoryURL: URL = {
        
//        let documentsDirectory: URL
//        if self.isUsingiCloud, let url = self.iCloudContainerURL ?? FileManager.default.url(forUbiquityContainerIdentifier: nil) {
//            documentsDirectory = url
//        } else {
//            documentsDirectory = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//        }
        
        let sketchesURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(self.sketchDirectoryPathComponent, isDirectory: true)
        
        if !self.fileManager.fileExists(atPath: sketchesURL.path, isDirectory: nil) {
            do {
                try self.fileManager.createDirectory(at: sketchesURL, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                fatalError("Could not create sketches directory")
            }
        }
        
        return sketchesURL
    }()
    
    var lastSavedSketchFile: SketchPadFile? {
        get {
            guard let fileName = UserDefaults.standard.string(forKey: currentSketchKey) else {
                return nil
            }
        
            let fileURL = sketchesDirectoryURL.appendingPathComponent(fileName, isDirectory: true)
            let current = SketchPadFile(fileURL: fileURL)
            return current
        }
        set {
            guard let file = newValue else {
                UserDefaults.standard.set(nil, forKey: currentSketchKey)
                return
            }
            
            UserDefaults.standard.set(file.fileURL.lastPathComponent, forKey: currentSketchKey)
        }
    }
    
    override init() {
        super.init()
        
//        DispatchQueue.global().async {
//            if let iCloudURL = manager.url(forUbiquityContainerIdentifier: nil) {
//                self.iCloudContainerURL = iCloudURL
//            }
//        }

        performFileSystemUpgrade()
    }
    
    /// Saves a `Sketch` in a SketchPadFile. If there is not a file for the sketch, a new file will be created.
    ///
    /// - Parameters:
    ///   - sketch: `Sketch` to save
    ///   - completionHandler: Optional completion handler. Will be called with the result of the file saving operation.
    func archive(_ sketch: Sketch, completionHandler: ((Bool) -> Void)? = nil) {
        if sketch.paths.count == 0 {
            completionHandler?(true)
            return
        }
        
        let fileURL = sketchesDirectoryURL.appendingPathComponent(sketch.name)
        
        let file = SketchPadFile(fileURL: fileURL)
        file.sketch = sketch
        
        let operation: UIDocumentSaveOperation
        if fileManager.fileExists(atPath: fileURL.path) {
            operation = .forOverwriting
        } else {
            operation = .forCreating
        }
        
        file.save(to: fileURL, for: operation) { (success) in
            completionHandler?(success)
            if success {
                NotificationCenter.default.post(name: .FileManagerDidSaveSketchPadFile,
                                                object: self,
                                                userInfo: [
                                                    "file": file
                                                ])
            }
        }
    }
    
    func archivedSketches() throws -> [SketchPadFile] {
        var sketches = [SketchPadFile]()
        do {
            let options = FileManager.DirectoryEnumerationOptions.skipsHiddenFiles
            let urls = try fileManager.contentsOfDirectory(at: sketchesDirectoryURL, includingPropertiesForKeys: nil, options: options)
            
            for url in urls {
                let file = SketchPadFile(fileURL: url)
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
                sketchURLs.append(sketch.fileURL.lastPathComponent)
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
    
    func moveSketchesToUbiquityContainer() throws {
        let sketchesDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(sketchDirectoryPathComponent, isDirectory: true)
        
        guard let iCloudDirURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            return
        }
        
        try fileManager.moveItem(at: sketchesDirURL, to: iCloudDirURL)
    }
    
    func evictSketchesFromUbiquityContainer() throws {
        let sketchesDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(sketchDirectoryPathComponent, isDirectory: true)
        
        guard let iCloudDirURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            return
        }
        
        try fileManager.moveItem(at: iCloudDirURL, to: sketchesDirURL)
    }
    
    private func deleteSketch(_ sketch: SketchPadFile) {
        if fileManager.fileExists(atPath: sketch.fileURL.path) {
            try? fileManager.removeItem(atPath: sketch.fileURL.path)
        }
    }
    
    /// Old implementation of the `archivedSketches` method. Used during the upgrade process to gather the archives of user sketches.
    ///
    /// - Returns: An array of `Sketch` instances.
    private func _oldArchivedSketches() -> [Sketch?] {
        var sketches = [Sketch?]()
        
        do {
            let sketchesDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(backupDirectoryPathComponent, isDirectory: true)
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
    
    /// Upgrades the "file system" of Padee. User sketches used to be stored as archives, but now they're wrapped in a `FileWrapper` and stored by `SketchPadFile`.
    private func performFileSystemUpgrade() {
        // if we've already performed upgrade
        if UserDefaults.standard.bool(forKey: filesUpgradedKey) {
            // check for any failed upgrades
            if let failedSketches = UserDefaults.standard.array(forKey: "com.dstrokis.Padee.failed-upgrades") as? [String] {
                if failedSketches.count > 0 {
                    recoverSketchesFromFailedUpgrade(failedSketches)
                } else {
                    cleanupBackupDirectory()
                }
            }
            
            return
        }
        
        let movedSuccessfully = moveSketches()
        if movedSuccessfully {
            upgradeSketches()
        }
        
        UserDefaults.standard.set(true, forKey: filesUpgradedKey)
    }
    
    private func moveSketches() -> Bool {
        // manually creating sketches dir URL so we don't lazily create it by accessing the property
        // if this directory doesn't exist, then this is a new install and we don't need to perform
        // a backup.
        let docDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sketchesDirURL = docDirURL.appendingPathComponent(sketchDirectoryPathComponent, isDirectory: true)
       
        if !fileManager.fileExists(atPath: sketchesDirURL.path) {
            return false
        }
        
        let backupDirectory = docDirURL.appendingPathComponent(backupDirectoryPathComponent, isDirectory: true)
        
        do {
            try fileManager.moveItem(at: sketchesDirURL, to: backupDirectory)
        } catch let error as NSError {
            UserDefaults.standard.set(false, forKey: filesUpgradedKey)
            print("Could not move sketches to backup directory.")
            print("Code: \(error.code)")
            print("Domain: \(error.domain)")
            print("Description: \(error.localizedDescription)")
            return false // will try again on next launch
        }
        
        do {
            try fileManager.createDirectory(at: sketchesDirURL, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            UserDefaults.standard.set(false, forKey: filesUpgradedKey)
            print("Could not create sketches directory.")
            print("Code: \(error.code)")
            print("Domain: \(error.domain)")
            print("Description: \(error.localizedDescription)")
            return false // will try again on next launch
        }
        
        return true
    }
    
    private func upgradeSketch(_ sketch: Sketch) {
        let docURL = sketchesDirectoryURL.appendingPathComponent(sketch.name)
        
        let document = SketchPadFile(fileURL: docURL)
        document.sketch = sketch
        
        document.save(to: docURL, for: .forCreating) { (success) in
            var failedSketches = UserDefaults.standard.array(forKey: "com.dstrokis.Padee.failed-upgrades") as? [String] ?? [String]()
            
            if success {
                if failedSketches.contains(sketch.name) {
                    failedSketches.remove(at: failedSketches.index(of: sketch.name)!)
                }
            } else {
                failedSketches.append(sketch.name)
            }
            
            UserDefaults.standard.set(failedSketches, forKey: "com.dstrokis.Padee.failed-upgrades")
        }
    }
    
    private func upgradeSketches() {
        let sketches = _oldArchivedSketches()
        
        for sketch in sketches {
            guard let sketch = sketch else {
                continue
            }
            
            upgradeSketch(sketch)
        }
    }
    
    private func recoverSketchesFromFailedUpgrade(_ sketchNames: [String]) {
        let docDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupDirectory = docDirURL.appendingPathComponent(backupDirectoryPathComponent, isDirectory: true)
        
        do {
            let options = FileManager.DirectoryEnumerationOptions.skipsHiddenFiles
            let urls = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil, options: options)
            
            let sketches = sketchNames.map { $0.appending(".sketch") }
            for url in urls {
                if sketches.contains(url.lastPathComponent) {
                    if let archiveData = try? Data(contentsOf: url),
                       let archive = NSKeyedUnarchiver.unarchiveObject(with: archiveData) as? Sketch {
                        upgradeSketch(archive)
                    }
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func cleanupBackupDirectory() {
        let docDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupDirectory = docDirURL.appendingPathComponent(backupDirectoryPathComponent, isDirectory: true)
        
        if !fileManager.fileExists(atPath: backupDirectory.path) {
            return
        }
        
        do {
            try fileManager.removeItem(at: backupDirectory)
            UserDefaults.standard.set(nil, forKey: "com.dstrokis.Padee.failed-upgrades")
        } catch let error as NSError {
            UserDefaults.standard.set(false, forKey: filesUpgradedKey)
            print("Could not remove backup directory.")
            print("Code: \(error.code)")
            print("Domain: \(error.domain)")
            print("Description: \(error.localizedDescription)")
        }
    }
}
