//
//  SketchPadFile.swift
//  Padee
//
//  Created by Daniel Strokis on 5/16/17.
//  Copyright © 2017 Daniel Strokis. All rights reserved.
//

import UIKit

final class SketchPadFile: UIDocument {
    private let sketchFile = "SketchPaths.path"
    
    var sketch: Sketch?
    
    override func contents(forType typeName: String) throws -> Any {
        
        guard let sketch = sketch else {
            fatalError()
        }
        
        let data = NSKeyedArchiver.archivedData(withRootObject: sketch)
        
        return FileWrapper(regularFileWithContents: data)
    }
    
    // TODO: Populate error userInfo dicts
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let wrapper = contents as? FileWrapper else {
            throw NSError(domain: "com.dstrokis.Padee", code: 1, userInfo: nil)
        }
        
        guard let sketchData = wrapper.regularFileContents,
              let sketch = NSKeyedUnarchiver.unarchiveObject(with: sketchData) as? Sketch else {
            throw NSError(domain: "com.dstrokis.Padee", code: 2, userInfo: nil)
        }
        
        self.sketch = sketch
    }
    
    override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocumentSaveOperation) throws -> [AnyHashable : Any] {
        let thumbnailSize = CGSize(width: 10240.0, height: 1024.0)
        
        UIGraphicsBeginImageContext(thumbnailSize)
        
        let context = UIGraphicsGetCurrentContext()
        if let sketch = sketch {
            for path in sketch.paths {
                path.draw(in: context)
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        
        UIGraphicsEndImageContext()
        
        return [
            URLResourceKey.nameKey: sketch?.name ?? "",
            URLResourceKey.thumbnailDictionaryKey: [
                URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey: image
            ]
        ]
    }
}
