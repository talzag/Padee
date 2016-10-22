///Users/dstrokis/Developer/Padee/Padee/Padee/ImageGalleryCollectionViewController.swift
//  ImageGalleryCollectionViewController.swift
//  Padee
//
//  Created by Daniel Strokis on 8/18/16.
//  Copyright © 2016 Daniel Strokis. All rights reserved.
//

import UIKit

fileprivate let reuseIdentifier = "ImageThumbnailCell"

final class ThumbnailImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}

final class ImageGalleryCollectionViewController: UICollectionViewController {

    var thumbnails = [(String, UIImage?)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didFinishViewingImageGallery(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
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
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let sketch = thumbnails[indexPath.row]
        
        let alert = UIAlertController(title: "Editing this sketch will erase your current drawing.", message: "Would you like to save your current sketch?", preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let saveSketch = UIAlertAction(title: "Save sketch", style: .default) { (action) in
            self.performSegue(withIdentifier: "RestoreImageUnwind", sender: (sketch.0, true))
        }
        
        let clearCanvas = UIAlertAction(title: "Clear canvas", style: .destructive) { (action) in
            self.performSegue(withIdentifier: "RestoreImageUnwind", sender: (sketch.0, false))
        }
        
        alert.addAction(saveSketch)
        alert.addAction(clearCanvas)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
        
        let popover = alert.popoverPresentationController
        popover?.sourceView = collectionView.cellForItem(at: indexPath)
        popover?.sourceRect = CGRect(x: 0, y: 5, width: 32, height: 32)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let sketchData = sender as? (String, Bool),
              let destination = segue.destination as? ViewController else {
            fatalError()
        }
        
        destination.prepareToRestoreSketch(name: sketchData.0, savingCurrentSketch: sketchData.1)
    }
}
