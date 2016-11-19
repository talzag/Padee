///Users/dstrokis/Developer/Padee/Padee/Padee/ImageGalleryCollectionViewController.swift
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
    @IBOutlet weak var imageNameLabel: UILabel!
}

final class ImageGalleryCollectionViewController: UICollectionViewController {

    var thumbnails = [(Sketch, UIImage?)]()
    var noSketchesMessageLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.allowsMultipleSelection = true
        
        if thumbnails.count > 0 {
            navigationItem.rightBarButtonItem = editButtonItem
        } else {
            addNoSketchesMessageLabel()
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

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbnailImageCollectionViewCell
    
        let thumbnail = thumbnails[indexPath.row]
        cell.imageView.image = thumbnail.1
        cell.imageNameLabel.text = thumbnail.0.name
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditing {
            let cell = collectionView.cellForItem(at: indexPath) as? ThumbnailImageCollectionViewCell
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
        // TODO: Fix UIPasteboard-related commands
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        let allowedActions = [
            #selector(UIResponderStandardEditActions.copy(_:))
        ]
        return allowedActions.contains(action)
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let sketch = thumbnails[indexPath.row]
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
        
        let sketch = thumbnails[indexPath.row].0
        destination.restore(sketch, savingCurrentSketch: true)
    }
    
    // MARK: Helper methods
    
    @IBAction func didFinishViewingImageGallery(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    func deleteSketches(_ sender: AnyObject) {
        guard let indexPaths = collectionView?.indexPathsForSelectedItems else {
            return
        }
        
        let alert = UIAlertController(title: "Delete Sketches", message: "This action cannot be undone.", preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let deleteSketches = UIAlertAction(title: "Delete \(indexPaths.count) sketches", style: .destructive) { (action) in
            let sketches = indexPaths.map { indexPath -> Sketch in
                let removed = self.thumbnails.remove(at: indexPath.row)
                return removed.0
            }
            
            self.fileManagerController.deleteSketches(sketches)
            
            self.collectionView?.performBatchUpdates({ 
                self.collectionView?.deleteItems(at: indexPaths)
            }) { (done) in
                self.isEditing = false
                
                if done && self.thumbnails.count == 0 {
                    self.addNoSketchesMessageLabel()
                    self.navigationItem.rightBarButtonItem = nil
                }
            }
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
        noSketchesMessageLabel?.text = "You have created any sketches yet 😣"
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
}
