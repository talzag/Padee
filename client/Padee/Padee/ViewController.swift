//
//  ViewController.swift
//  Padee
//
//  Created by Daniel Strokis on 6/14/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit
import CoreGraphics

final class ViewController: UIViewController {

    @IBOutlet var toolButtons: [UIButton]!
    
    private var currentSketch = Sketch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restoreLastSketch()
        toolButtons.filter({ $0.restorationIdentifier == Tool.Pen.rawValue }).first?.isSelected = true
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.rotateToolButtons),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        super.viewWillDisappear(animated)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        shrinkToolButtons()
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {        
        restoreToolButtons()
        super.touchesEnded(touches, with: event)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        do {
            let sketches = try fileManagerController.archivedSketches()
            let images = try fileManagerController.renderedImages()
            
            let zipped = zip(sketches, images)
            let thumbnails = zipped.map { ($0, $1) }
            if let navController =  segue.destination as? UINavigationController {
                (navController.viewControllers.first! as! ImageGalleryCollectionViewController).thumbnails = thumbnails
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func saveCurrentSketch() {
        let paths = (view as! CanvasView).pathsForRestoringCurrentImage
        guard paths.count > 0 else {
            return
        }
        
        currentSketch.paths = paths
        let image = (view as! CanvasView).canvasImage
        guard fileManagerController.archive(currentSketch, with: image) else {
            fatalError("Could not archive sketch")
        }
    }
    
    func restore(_ sketch: Sketch, savingCurrentSketch save: Bool) {
        let paths = (view as! CanvasView).pathsForRestoringCurrentImage
        if save && paths.count > 0 {
            saveCurrentSketch()
        }
        
        (view as! CanvasView).clear()
        
        currentSketch = sketch
        (view as! CanvasView).restoreImage(using: sketch.paths)
    }
    
    func restoreLastSketch() {
        if let sketch = fileManagerController.lastSavedSketch()  {
            currentSketch = sketch
        }
    }
    
    func clearCanvas() {
        (view as! CanvasView).clear()
        currentSketch = Sketch()
    }
    
    func rotateToolButtons() {
        let transform =  transformForCurrentDeviceOrientation()
        
        UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
            for button in self.toolButtons {
                button.transform = transform
            }
        }, completion: nil)
    }
    
    private func transformForCurrentDeviceOrientation() -> CGAffineTransform {
        // Overriding shouldAutorotate on iPad has no effect.
        if UIDevice.current.userInterfaceIdiom == .pad {
            return CGAffineTransform.identity
        }
        
        let angle: CGFloat
        
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            angle = 90.0
        case .portraitUpsideDown:
            angle = 180.0
        case .landscapeRight:
            angle = 270.0
        case .portrait:
            fallthrough
        default:
            angle = 0.0
        }
        
        let transform:CGAffineTransform
        
        if angle > 0.0 {
            transform = CGAffineTransform.identity.rotated(by: angle * .pi / 180)
        } else {
            transform = CGAffineTransform.identity
        }
        
        return transform
    }
    
    private func shrinkToolButtons() {
        let toolButton = toolButtons.first!
        let transform = toolButton.transform
            .scaledBy(x: 0.5, y: 0.5)
            .translatedBy(
                x: toolButton.frame.size.width / -2.0,
                y: toolButton.frame.size.height / -2.0
            )
        
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
            for button in self.toolButtons {
                button.transform = transform
                button.alpha = 0.4
            }
        }, completion: nil)
        
    }
    
    private func restoreToolButtons() {
        let transform = transformForCurrentDeviceOrientation()
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
            for button in self.toolButtons {
                button.transform = transform
                button.alpha = 1.0
            }
        }, completion: nil)
    }
    
    @IBAction func toolSelected(_ sender: UIButton) {
        guard let id = sender.restorationIdentifier else {
            fatalError("Tool button missing restoration identifier: \(sender)")
        }
        
        if let tool = Tool(rawValue: id) {
            (view as! CanvasView).currentTool = tool
            
            for tool in toolButtons where tool.isSelected == true {
                tool.isSelected = false
            }
            
            sender.isSelected = true
        }
    }
    
    @IBAction func createNewSketch(_ sender: UIButton?) {
        guard (view as! CanvasView).pathsForRestoringCurrentImage.count > 0 else {
            return
        }
        
        let alert = UIAlertController(title: "Create new sketch", message: "Save current sketch?", preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let saveSketch = UIAlertAction(title: "Save sketch", style: .default) { (action) in
            self.saveCurrentSketch()
            self.clearCanvas()
        }
        
        let clearCanvas = UIAlertAction(title: "Clear canvas", style: .destructive) { (action) in
            self.clearCanvas()
        }
        
        alert.addAction(saveSketch)
        alert.addAction(clearCanvas)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
        
        let popover = alert.popoverPresentationController
        popover?.sourceView = sender
        popover?.sourceRect = CGRect(x: 0, y: 5, width: 32, height: 32)
    }
    
    @IBAction func exportCurrentImage(_ sender: UIButton) {
        guard let image = (view as! CanvasView).canvasImage else { return }
        
        let shareSheet = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(shareSheet, animated: true, completion: nil)
       
        let popover = shareSheet.popoverPresentationController
        popover?.sourceView = sender
        popover?.sourceRect = CGRect(x: 0, y: 5, width: 32, height: 32)
    }
    
    @IBAction func unwindSegue(sender: UIStoryboardSegue) {
        // Empty segue to allow unwinding from ImageGalleryViewController
    }
}
