//
//  UIViewController+FileManager.swift
//  Padee
//
//  Created by Daniel Strokis on 11/12/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

extension UIViewController {
    var fileManagerController: FileManagerController {
       return (UIApplication.shared.delegate as! AppDelegate).fileManager
    }
}
