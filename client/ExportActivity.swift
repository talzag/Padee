//
//  ExportActivity.swift
//  Padee
//
//  Created by Daniel Strokis on 6/17/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

class ExportActivity: UIActivity {
    var image : UIImage!
    
    override var activityType: UIActivityType? {
        return UIActivityType("com.dstrokis.Padee.export")
    }
    
    override var activityTitle: String? {
        return nil
    }
    
    override var activityImage: UIImage? {
        return nil
    }
    
    override class var activityCategory: UIActivityCategory {
        return .action
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard activityItems.count == 1,
              let _ = activityItems.first as? UIImage else {
            return false
        }
        
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        image = activityItems.first! as! UIImage
    }
}

class PNGExportActivity : ExportActivity {
    override var activityType: UIActivityType? {
        return UIActivityType("com.dstrokis.Padee.export.png")
    }
    
    override var activityTitle: String? {
        return "Save as PNG"
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "PNG")
    }
    
    override func perform() {
        if let imageData = UIImagePNGRepresentation(image) {
            image = UIImage(data: imageData)
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
}

class JPGExportActivity: ExportActivity {
    override var activityType: UIActivityType? {
        return UIActivityType("com.dstrokis.Padee.export.jpg")
    }
    
    override var activityTitle: String? {
        return "Save as JPG"
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "JPG")
    }
    
    override func perform() {
        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
            image = UIImage(data: imageData)
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
}

class PDFExportActivity: ExportActivity {
    override var activityType: UIActivityType? {
        return UIActivityType("com.dstrokis.Padee.export.pdf")
    }
    
    override var activityTitle: String? {
        return "Save as PDF"
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "PDF")
    }
    
    override func perform() {
        
    }
}
