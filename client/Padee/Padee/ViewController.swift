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
    
    private var currentSketchName: String?
    
    // Padee file storage layout:
    // Documents/
    //      com.dstrokis.Padee.current          <= current image data (used for quickly saving/restoring user's last sketch)
    //      com.dstrokis.Padee.sketches/        <= archived sketches
    //          sketch-<CREATE TIME>.paths      <= archived
    //          sketch-<CREATE TIME>.png        <= rendered image
    
    private lazy var currentImagePathsURL: URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let currentImagePathsURL = documentsDirectory.appendingPathComponent("com.dstrokis.Padee.current", isDirectory: false)
        return currentImagePathsURL
    }()
    
    private lazy var sketchesDirectoryURL: URL = {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sketchesURL = documentsDirectory.appendingPathComponent("com.dstrokis.Padee.sketches", isDirectory: true)
        
        if !fileManager.fileExists(atPath: sketchesURL.path, isDirectory: nil) {
            do {
                try fileManager.createDirectory(at: sketchesURL, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                fatalError("Could not create sketches directory")
            }
        }
        
        return sketchesURL
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restoreLastImage()
        toolButtons.filter({ $0.restorationIdentifier == "Pen"}).first?.isSelected = true
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.rotateToolButtons), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        print("Did recieve memory warning.")
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
            let fileManager = FileManager.default
            let urls = try fileManager.contentsOfDirectory(atPath: sketchesDirectoryURL.path).filter { $0.hasSuffix("png") }
            let thumbnails = urls.map { ($0, UIImage(contentsOfFile: sketchesDirectoryURL.appendingPathComponent($0).path)) }
            
            if let navController =  segue.destination as? UINavigationController {
                (navController.viewControllers.first! as! ImageGalleryCollectionViewController).thumbnails = thumbnails
            }
        } catch let error {
            print(error)
        }
    }
    
    func saveCurrentImage() {
        let paths = (view as! CanvasView).pathsForRestoringCurrentImage
        let pathData = NSKeyedArchiver.archivedData(withRootObject: paths)
        
        do {
            try pathData.write(to: currentImagePathsURL)
        } catch let error {
            print(error.localizedDescription)
            fatalError("Could not archive image drawing paths! This should not happen!")
        }
    }
    
    func archiveCurrentImage() {
        let fileManager = FileManager.default
        let creationTime = Int(Date.timeIntervalSinceReferenceDate)
        let basePath = "sketch-\(creationTime)"
        let fileURL = sketchesDirectoryURL.appendingPathComponent(basePath, isDirectory: false)
        
        let paths = (view as! CanvasView).pathsForRestoringCurrentImage
        let pathData = NSKeyedArchiver.archivedData(withRootObject: paths)
        let pathFile = fileURL.appendingPathExtension("paths")
        let pathWriteSuccess = fileManager.createFile(atPath: pathFile.path, contents: pathData, attributes: nil)
        if !pathWriteSuccess {
            print("Could not archive paths for current image.")
        }
        
        guard let image = (view as! CanvasView).canvasImage,
              let imageData = UIImagePNGRepresentation(image) else {
            return
        }
        let imageFile = fileURL.appendingPathExtension("png")
        let imageWriteSuccess = fileManager.createFile(atPath: imageFile.path, contents: imageData, attributes: nil)
        if !imageWriteSuccess {
            print("Could not archive PNG representation of current image.")
        }
    }
    
    func rotateToolButtons() {
        let transform =  transformForCurrentDeviceOrientation()
        
        UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: { 
            for button in self.toolButtons {
                button.transform = transform
            }
        }, completion: nil)
    }
    
    func restoreSketch(named: String, savingCurrentSketch save: Bool) {
        currentSketchName = named
        
        if save {
            archiveCurrentImage()
        }
        
        (self.view as! CanvasView).clear()
        self.deleteLastImageData()
    }
    
    func clearCanvas() {
        (view as! CanvasView).clear()
        deleteLastImageData()
        currentSketchName = nil
    }
    
    // MARK: Private 
    
    func restoreLastImage() {
        guard let pathData = try? Data(contentsOf: currentImagePathsURL),
              let paths = NSKeyedUnarchiver.unarchiveObject(with: pathData) as? [Path] else {
            return
        }
        
        (view as! CanvasView).restoreImage(using: paths)
    }
    
    private func deleteLastImageData() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: self.currentImagePathsURL.path) {
            do {
                try fileManager.removeItem(at: self.currentImagePathsURL)
            } catch let error {
                print(error)
            }
        }
    }
    
    private func transformForCurrentDeviceOrientation() -> CGAffineTransform {
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
                x: toolButton.frame.size.width / -2.0 ,
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
    
    // MARK: IBAction
    
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
        let alert = UIAlertController(title: "Create new sketch", message: "Save current sketch?", preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let saveSketch = UIAlertAction(title: "Save sketch", style: .default) { (action) in
            self.archiveCurrentImage()
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
    
    // MARK: Unwind segue
    
    @IBAction func unwindSegue(sender: UIStoryboardSegue) {
        guard sender.source is ImageGalleryCollectionViewController,
              let sketch = currentSketchName else {
            return
        }
        
        let range = sketch.range(of: ".png")!
        let base = sketch.substring(to: range.lowerBound)
        let filePath = sketchesDirectoryURL.appendingPathComponent(base).appendingPathExtension("paths").path
       
        guard let pathData = FileManager.default.contents(atPath: filePath),
              let paths = NSKeyedUnarchiver.unarchiveObject(with: pathData) as? [Path] else {
            return
        }
        
        (view as! CanvasView).restoreImage(using: paths)
    }
}
