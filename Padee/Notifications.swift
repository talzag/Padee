//
//  Notifications.swift
//  Padee
//
//  Created by Daniel Strokis on 1/8/17.
//  Copyright © 2017 Daniel Strokis. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let FileManagerDidSaveSketchPadFile = Notification.Name(rawValue: "FileManagerDidSaveSketchPadFile")
    static let FileManagerDidDeleteSketches = NSNotification.Name(rawValue: "FileManagerDidDeleteSketches")
}
