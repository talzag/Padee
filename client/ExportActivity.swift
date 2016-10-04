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
    
    override func activityType() -> String? {
        return "com.dstrokis.Padee.export"
    }
    
    override func activityTitle() -> String? {
        return nil
    }
    
    override func activityImage() -> UIImage? {
        return nil
    }
    
    override class func activityCategory() -> UIActivityCategory {
        return .Action
    }
    
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        guard activityItems.count == 1,
              let _ = activityItems.first as? UIImage else {
            return false
        }
        
        return true
    }
    
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        image = activityItems.first! as! UIImage
    }
}

class PNGExportActivity : ExportActivity {
    override func activityType() -> String? {
        return "com.dstrokis.Padee.export.png"
    }
    
    override func activityTitle() -> String? {
        return "Export PNG"
    }
    
    override func activityImage() -> UIImage? {
        return UIImage(named: "PNG")
    }
    
    override func performActivity() {
//        let imageData = UIImagePNGRepresentation(image)
    }
}

class JPGExportActivity: ExportActivity {
    override func activityType() -> String? {
        return "com.dstrokis.Padee.export.jpg"
    }
    
    override func activityTitle() -> String? {
        return "Export JPG"
    }
    
    override func activityImage() -> UIImage? {
        return UIImage(named: "JPG")
    }
    
    override func performActivity() {
//        let imageDate = UIImageJPEGRepresentation(image, 1.0)
    }
}

class PDFExportActivity: ExportActivity {
    override func activityType() -> String? {
        return "com.dstrokis.Padee.export.pdf"
    }
    
    override func activityTitle() -> String? {
        return "Export PDF"
    }
    
    override func activityImage() -> UIImage? {
        return UIImage(named: "PDF")
    }
    
    override func performActivity() {
        
    }
}
