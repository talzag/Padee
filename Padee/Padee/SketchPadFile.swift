//
//  SketchPadFile.swift
//  Padee
//
//  Created by Daniel Strokis on 5/16/17.
//  Copyright © 2017 Daniel Strokis. All rights reserved.
//

import UIKit

final class SketchPadFile: UIDocument {
    private let sketchFilename = "Sketch.path"
    private var thumbnailFilename = "Sketch.png"
    
    var sketch: Sketch!
    
    var thumbnail: UIImage {
        let image: UIImage
        
        if let sketch = sketch {
            let thumbnailSize = UIScreen.main.bounds
            UIGraphicsBeginImageContextWithOptions(thumbnailSize.size, true, 0.0)
            let context = UIGraphicsGetCurrentContext()
            
            UIColor.white.setFill()
            context?.fill(thumbnailSize)
            
            for path in sketch.paths {
                path.draw(in: context)
            }
            
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        } else if let data = FileManager.default.contents(atPath: fileURL.appendingPathComponent(thumbnailFilename).path), let preview = UIImage(data: data) {
            image = preview
        } else {
            image = #imageLiteral(resourceName: "File")
        }
        
        return image
    }
    
    override func contents(forType typeName: String) throws -> Any {
        guard let sketch = sketch else {
            throw NSError(domain: "com.dstrokis.Padee", code: 1, userInfo: nil)
        }
        
        let sketchData = NSKeyedArchiver.archivedData(withRootObject: sketch)
        let imageData = UIImagePNGRepresentation(thumbnail)!
        
        let sketchFileWrapper = FileWrapper(regularFileWithContents: sketchData)
        sketchFileWrapper.preferredFilename = sketchFilename
        
        let thumbnailFileWrapper = FileWrapper(regularFileWithContents: imageData)
        thumbnailFileWrapper.preferredFilename = thumbnailFilename
        
        return FileWrapper(directoryWithFileWrappers: [
            sketchFilename: sketchFileWrapper,
            thumbnailFilename: thumbnailFileWrapper
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
