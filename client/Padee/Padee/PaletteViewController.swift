//
//  PaletteViewController.swift
//  Padee
//
//  Created by Daniel Strokis on 7/30/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

final class PaletteViewController: UIViewController {
    @IBOutlet weak var paletteView: PaletteView!
    @IBOutlet weak var currentColorView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func colorWellWasSelected(_ sender: ColorWellView) {
        currentColorView.backgroundColor = sender.color
        paletteView.currentColor = sender.color
    }
    
    @IBAction func done(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}
