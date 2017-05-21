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
    private let imageFile = "SketchImage.png"
    
    var sketch: Sketch?
    var prerenderedSketchImage: UIImage?
    
    override func contents(forType typeName: String) throws -> Any {
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])
        
        if let sketch = sketch {
            let data = NSKeyedArchiver.archivedData(withRootObject: sketch)
            wrapper.addRegularFile(withContents: data, preferredFilename: sketchFile)
        }
        
        if let image = prerenderedSketchImage, let imageData = UIImagePNGRepresentation(image) {
            wrapper.addRegularFile(withContents: imageData, preferredFilename: sketchFile)
        }
        
        return wrapper
    }
    
    // TODO: Populate error userInfo dicts
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let wrapper = contents as? FileWrapper else {
            throw NSError(domain: "com.dstrokis.Padee", code: 1, userInfo: nil)
        }
        
        guard let sketchWrapper = wrapper.fileWrappers?[sketchFile] else {
            throw NSError(domain: "com.dstrokis.Padee", code: 2, userInfo: nil)
        }
        
        guard let sketchDate = sketchWrapper.regularFileContents,
              let sketch = NSKeyedUnarchiver.unarchiveObject(with: sketchDate) as? Sketch else {
            throw NSError(domain: "com.dstrokis.Padee", code: 3, userInfo: nil)
        }
        
        self.sketch = sketch
        
        if let imageWrapper = wrapper.fileWrappers?[imageFile] {
            if let imageData = imageWrapper.regularFileContents, let image = UIImage(data: imageData) {
                prerenderedSketchImage = image
            }
        }
    }
}
