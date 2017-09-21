//
//  ViewController.swift
//  Padee
//
//  Created by Daniel Strokis on 6/14/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit
import CoreGraphics
import StoreKit

final class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var toolButtons: [UIButton]!
    
    var currentSketch: Sketch?
    var feedbackGenerator: UISelectionFeedbackGenerator?
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolButtons.filter({ $0.restorationIdentifier == Tool.Pen.rawValue }).first?.isSelected = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.rotateToolButtons),
                                               name: .UIDeviceOrientationDidChange,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.didDeleteSketchesHandler(_:)),
                                               name: .FileManagerDidDeleteSketches,
                                               object: nil)
        
        restoreSketch()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        saveCurrentSketch()
        
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Touch Handling 
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        shrinkToolButtons()
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {        
        restoreToolButtons()
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        restoreToolButtons()
        super.touchesCancelled(touches, with: event)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        do {
            let sketches = try fileManagerController.archivedSketches()
            
            if let navController =  segue.destination as? UINavigationController {
                (navController.viewControllers.first! as! ImageGalleryCollectionViewController).files = sketches
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Sketch handling
    
    func saveCurrentSketch(completionHandler: ((Bool) -> Void)? = nil) {
        let paths = (view as! CanvasView).pathsForRestoringCurrentImage
        
        guard let current = currentSketch, paths.count > 0 else {
            return
        }
        
        current.paths = paths
        
        fileManagerController.archive(current, completionHandler: completionHandler)
    }
    
    func restoreSketch() {
        if let lastSketch = fileManagerController.lastSavedSketchFile {
            lastSketch.open { [unowned self] (success) in
                guard success, let sketch = lastSketch.sketch else {
                    self.createNewSketch()
                    return
                }
                
                self.currentSketch = sketch
                (self.view as! CanvasView).restoreImage(using: sketch.paths)
            }
        } else {
            createNewSketch()
        }
    }
    
    func restoreSketch(from file: SketchPadFile, savingCurrentSketch save: Bool) {
        if let current = currentSketch, file.fileURL.lastPathComponent == current.name {
            return
        }
        
        fileManagerController.lastSavedSketchFile = file
        
        clearCanvas()
        
        file.open { (success) in
            guard success else {
                self.createNewSketch()
                return
            }
            
            self.currentSketch = file.sketch
            (self.view as! CanvasView).restoreImage(using: self.currentSketch!.paths)
        }
    }
    
    func clearCanvas() {
        (view as! CanvasView).clear()
        fileManagerController.lastSavedSketchFile = nil
    }
    
    // MARK: - Button handling
    
    @objc func rotateToolButtons() {
        let transform =  transformForCurrentDeviceOrientation()
        
        UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: { [unowned self] in
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
    
    // MARK: - Notification handlers
    
    @objc private func didDeleteSketchesHandler(_ notification: Notification) {
        guard let sketchNames = notification.userInfo?["sketches"] as? [String],
              let sketch = currentSketch else {
            return
        }
        
        if sketchNames.contains(sketch.name) {
            clearCanvas()
            currentSketch = Sketch()
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func toolSelected(_ sender: UIButton) {
        if feedbackGenerator == nil {
            feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator?.prepare()
        }
        
        guard let id = sender.restorationIdentifier else {
            fatalError("Tool button missing restoration identifier: \(sender)")
        }
        
        if let tool = Tool(rawValue: id) {
            (view as! CanvasView).currentTool = tool
            
            for tool in toolButtons where tool.isSelected == true {
                tool.isSelected = false
            }
            
            sender.isSelected = true
            feedbackGenerator?.selectionChanged()
        }
        
        feedbackGenerator = nil
    }
    
    @IBAction func createNewSketch(_ sender: UIButton? = nil) {
        saveCurrentSketch()
        clearCanvas()
        currentSketch = Sketch()
    }
    
    @IBAction func exportCurrentImage(_ sender: UIButton) {
        guard let image = (view as! CanvasView).canvasImage else { return }
        
        let activities = [PNGExportActivity(), JPGExportActivity()]
        let shareViewController = UIActivityViewController(activityItems: [image], applicationActivities: activities)
        
        if #available(iOS 10.3, *) {
            shareViewController.completionWithItemsHandler = { (items, completed, returnedItems, error) in
                SKStoreReviewController.requestReview()
            }
        }
        
        present(shareViewController, animated: true, completion: nil)
       
        let popover = shareViewController.popoverPresentationController
        popover?.sourceView = sender
        popover?.sourceRect = CGRect(x: 0, y: 5, width: 32, height: 32)
    }
    
    /// Empty segue to allow unwinding from ImageGalleryViewController
    ///
    /// - Parameter sender: Storyboard segue from ImageGalleryViewController
    @IBAction func unwindSegue(sender: UIStoryboardSegue? = nil) { }
}
