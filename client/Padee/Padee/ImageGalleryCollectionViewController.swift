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
}

final class ImageGalleryCollectionViewController: UICollectionViewController {

    var thumbnails = [(String, UIImage?)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if thumbnails.count > 0 {
            navigationItem.rightBarButtonItem = editButtonItem
        }
        
        collectionView?.allowsMultipleSelection = true
    }
    
    @IBAction func didFinishViewingImageGallery(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
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
        }
    }
    
    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbnailImageCollectionViewCell
    
        let thumbnail = thumbnails[indexPath.row]
        cell.imageView.image = thumbnail.1
    
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
        
        let sketch = thumbnails[indexPath.row]
        performSegue(withIdentifier: "RestoreImageUnwind", sender: sketch.0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if !isEditing {
            return
        }
        
        let cell = collectionView.cellForItem(at: indexPath) as? ThumbnailImageCollectionViewCell
        cell?.selectedImageView.alpha = 0.0
        
        updateStateForLeftToolBarItem()
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
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
        guard let sketch = sender as? String,
              let destination = segue.destination as? ViewController else {
            fatalError()
        }
        
        destination.restoreSketch(named: sketch, savingCurrentSketch: true)
    }
    
    // MARK: 
    
    @objc func deleteSketches(_ sender: AnyObject) {
        guard let indexPaths = collectionView?.indexPathsForSelectedItems else {
            return
        }
        
        for index in indexPaths {
            print(thumbnails[index.row].0)
        }
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
