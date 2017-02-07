//  ImageGalleryCollectionViewController.swift
//  Padee
//
//  Created by Daniel Strokis on 8/18/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit
import MobileCoreServices

fileprivate let reuseIdentifier = "ImageThumbnailCell"

final class ThumbnailImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
}

final class SketchNameSupplementaryView: UICollectionReusableView {
    @IBOutlet weak var nameLabel: UILabel!
}

final class ImageGalleryCollectionViewController: UICollectionViewController, UITextFieldDelegate {

    var selectedSketch: Sketch?
    var thumbnails = [(Sketch?, UIImage?)]()
    var noSketchesMessageLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.allowsMultipleSelection = true
        
        if thumbnails.count > 0 {
            navigationItem.rightBarButtonItem = editButtonItem
        } else {
            addNoSketchesMessageLabel()
        }
        
        NotificationCenter.default.addObserver(forName: .FileManagerDidDeleteSketches, object: nil, queue: nil) { (notification) in
            guard let names = notification.userInfo?["sketches"] as? [String] else {
                return
            }
            
            self.remove(namedItems: names, from: self.collectionView!)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            let deleteBarButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteSketches(_:)))
            deleteBarButton.isEnabled = false;
            navigationItem.setLeftBarButton(deleteBarButton, animated: true)
        } else {
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didFinishViewingImageGallery(_:)))
            navigationItem.setLeftBarButton(cancelBarButton, animated: true)
            
            guard let indexPaths = collectionView?.indexPathsForSelectedItems else {
                return
            }
            
            for indexPath in indexPaths {
                collectionView?.deselectItem(at: indexPath, animated: true)
                
                let cell = collectionView?.cellForItem(at: indexPath) as? ThumbnailImageCollectionViewCell
                cell?.selectedImageView.alpha = 0.0
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return thumbnails.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbnailImageCollectionViewCell
    
        let thumbnail = thumbnails[indexPath.section]
        cell.imageView.image = thumbnail.1
        
        if !isEditing {
            cell.selectedImageView.alpha = 0.0
        }
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sketchNameView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SketchNameView", for: indexPath) as! SketchNameSupplementaryView
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(renameSketch))
        sketchNameView.addGestureRecognizer(tapRecognizer)
        
        let thumbnail = thumbnails[indexPath.section]
        sketchNameView.nameLabel.text = thumbnail.0?.name
        
        return sketchNameView
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? ThumbnailImageCollectionViewCell
        
        if isEditing {
            cell?.selectedImageView.alpha = 1.0
            
            updateStateForLeftToolBarItem()
            
            return
        }
        
        performSegue(withIdentifier: "RestoreImageUnwind", sender: collectionView)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if !isEditing {
            return
        }
        
        let cell = collectionView.cellForItem(at: indexPath) as? ThumbnailImageCollectionViewCell
        cell?.selectedImageView.alpha = 0.0
        
        updateStateForLeftToolBarItem()
    }
    
    // MARK: UIPasteboard Functionality
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        // FIXME: UIPasteboard-related commands
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        let allowedActions = [
            #selector(UIResponderStandardEditActions.copy(_:))
        ]
        return allowedActions.contains(action)
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let sketch = thumbnails[indexPath.section]
        UIPasteboard.general.setValue(sketch.1!, forPasteboardType: kUTTypeImage as String)
    }
    
    // MARK: Navigation 
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let collectionView = sender as? UICollectionView,
              let destination = segue.destination as? ViewController else {
            fatalError()
        }
        
        guard let indexPath = collectionView.indexPathsForSelectedItems?.first else {
            return
        }
        
        guard let sketch = thumbnails[indexPath.section].0 else {
            fatalError("Sketch should not be nil")
        }
        
        destination.restore(sketch, savingCurrentSketch: true)
    }
    
    // MARK: UITextField delegate
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        guard let newName = textField.text?.trimmingCharacters(in: .whitespaces) else {
            return
        }
        
        guard reason == .committed,
              !newName.isEmpty,
              newName != selectedSketch?.name else {
            return
        }
        
        fileManagerController.rename(sketch: selectedSketch!, to: newName)
    }
    
    // MARK: Helper methods
    
    @IBAction func didFinishViewingImageGallery(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    func renameSketch(_ sender: UITapGestureRecognizer) {
        guard let supplementaryView = sender.view as? SketchNameSupplementaryView else {
            fatalError("Expected sender to be instance of SketchNameSupplementaryView. Instead got \(sender.view.self)")
        }
        
        selectedSketch =  thumbnails.first(where: { $0.0?.name == supplementaryView.nameLabel.text })?.0
        
        let alertController = UIAlertController(title: "Rename Sketch", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { [unowned self] (textField) in
            textField.delegate = self
            textField.text = supplementaryView.nameLabel.text
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let done = UIAlertAction(title: "Done", style: .default) { [unowned alertController, supplementaryView] (action) in
            let newName = alertController.textFields?.first?.text
            self.selectedSketch?.name = newName
            supplementaryView.nameLabel.text = newName
            alertController.textFields?.first!.resignFirstResponder()
        }
        
        alertController.addAction(cancel)
        alertController.addAction(done)
        
        present(alertController, animated: true, completion: nil)
    }

    func deleteSketches(_ sender: AnyObject) {
        guard let indexPaths = collectionView?.indexPathsForSelectedItems else {
            return
        }
        
        let pluralized = indexPaths.count > 1 ? "sketches" : "sketch"
        let alert = UIAlertController(title: "Delete \(pluralized)", message: "This action cannot be undone.", preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let deleteSketches = UIAlertAction(title: "Delete \(indexPaths.count) \(pluralized)", style: .destructive) { (action) in
            let sketches = indexPaths.map { indexPath -> Sketch? in
                let sektch = self.thumbnails[indexPath.section].0
                return sektch
            }
            
            self.fileManagerController.deleteSketches(sketches)
        }
        
        alert.addAction(deleteSketches)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
        
        let popover = alert.popoverPresentationController
        popover?.sourceView = (sender as? UIBarButtonItem)?.customView
        popover?.sourceRect = CGRect(x: 0, y: 5, width: 32, height: 32)
    }
    
    private func addNoSketchesMessageLabel() {
        noSketchesMessageLabel = UILabel(frame: view.frame)
        noSketchesMessageLabel?.text = "No sketches to display."
        noSketchesMessageLabel?.textAlignment = .center
        noSketchesMessageLabel?.textColor = UIColor.gray
        noSketchesMessageLabel?.minimumScaleFactor = 0.75
        view.addSubview(noSketchesMessageLabel!)
    }
    
    private func updateStateForLeftToolBarItem() {
        if !isEditing {
            navigationItem.leftBarButtonItem?.isEnabled = true
            return
        }
        
        guard let indexPaths = collectionView?.indexPathsForSelectedItems else {
            navigationItem.leftBarButtonItem?.isEnabled = false
            return
        }
        
        navigationItem.leftBarButtonItem?.isEnabled = indexPaths.count > 0
    }
    
    private func remove(namedItems names: [String], from collectionView: UICollectionView) {
        var indexes = [Int]()
        for x in 0..<self.thumbnails.count {
            if let name = self.thumbnails[x].0?.name {
                if names.contains(name) {
                    indexes.append(x)
                }
            }
        }
        
        let indexSet = IndexSet(indexes)
        
        self.thumbnails = self.thumbnails.filter {
            guard let name = $0.0?.name else {
                fatalError()
            }
            
            let delete = names.contains(name)
            
            
            return !delete
        }
        
        collectionView.performBatchUpdates({
            collectionView.deleteSections(indexSet)
        }) { (done) in
            self.isEditing = false
            
            if done && self.thumbnails.count == 0 {
                self.addNoSketchesMessageLabel()
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }
}
