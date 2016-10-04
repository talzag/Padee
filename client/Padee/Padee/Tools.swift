//
//  Tools.swift
//  Padee
//
//  Created by Daniel Strokis on 6/20/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

enum Tool: String {
    case Pencil
    case Pen
    case Eraser
    
    var lineWidth: CGFloat {
        get {
            switch self {
            case .Pencil:
                return 1.0
            case .Pen:
                return 3.0
            case .Eraser:
                return 20.0
            }
        }
    }
    
    var lineColor: UIColor {
        get {
            switch self {
            case .Pencil:
                return UIColor.gray
            case .Pen:
                return UIColor.black
            case .Eraser:
                return UIColor.white
            }
        }
    }
}

extension UIImageView {
    func drawComposite(with otherImage: UIImage?) {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
        image?.draw(in: frame)
        UIGraphicsGetCurrentContext()!.setBlendMode(.normal)
        otherImage?.draw(in: frame)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}
