//
//  SketchPadFile.swift
//  Padee
//
//  Created by Daniel Strokis on 5/16/17.
//  Copyright © 2017 Daniel Strokis. All rights reserved.
//

import UIKit

final class SketchPadFile: UIDocument {
    
    static let pathAttributesKey = "com.dstrokis.Padee.path-count"
    
    private let sketchFilename = "Sketch.path"
    
    var sketch: Sketch!
    
    var thumbnail: UIImage {
        let image: UIImage
        
        let data = FileManager.default.contents(atPath: fileURL.appendingPathComponent(sketchFilename).path)
        
        if let sketchData = data, let sketch = NSKeyedUnarchiver.unarchiveObject(with: sketchData) as? Sketch {
            let thumbnailSize = UIScreen.main.bounds
            UIGraphicsBeginImageContextWithOptions(thumbnailSize.size, true, 0.0)
            
            guard let context = UIGraphicsGetCurrentContext() else {
                return UIImage()
            }
            
            UIColor.white.setFill()
            context.fill(thumbnailSize)
            
            for path in sketch.paths {
                path.draw(in: context)
            }
            
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        } else {
            image = UIImage()
        }
        
        return image
    }
    
    override func contents(forType typeName: String) throws -> Any {
        guard let sketch = sketch else {
            throw NSError(domain: "com.dstrokis.Padee", code: 1, userInfo: nil)
        }
        
        let sketchData = NSKeyedArchiver.archivedData(withRootObject: sketch)
        
        let sketchFileWrapper = FileWrapper(regularFileWithContents: sketchData)
        sketchFileWrapper.preferredFilename = sketchFilename
        
        return FileWrapper(directoryWithFileWrappers: [
            sketchFilename: sketchFileWrapper
        ])
    }
    
    // TODO: Populate error userInfo dict
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let wrapper = contents as? FileWrapper else {
            throw NSError(domain: "com.dstrokis.Padee", code: 2, userInfo: nil)
        }
        
        guard let sketchData = wrapper.fileWrappers?[sketchFilename]?.regularFileContents,
              let sketch = NSKeyedUnarchiver.unarchiveObject(with: sketchData) as? Sketch else {
            throw NSError(domain: "com.dstrokis.Padee", code: 3, userInfo: nil)
        }
        
        self.sketch = sketch
    }
    
    override func fileNameExtension(forType typeName: String?, saveOperation: UIDocumentSaveOperation) -> String {
        return "pad"
    }
}
