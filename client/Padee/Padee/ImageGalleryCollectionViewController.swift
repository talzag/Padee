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
    var selectedSketchName: String?
    
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
        
        selectedSketchName = thumbnails[indexPath.row].0
    }
    
    // MARK: Unwind segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let indexPath = collectionView?.indexPath(for: sender as! ThumbnailImageCollectionViewCell)!
        selectedSketchName = thumbnails[indexPath!.row].0
    }
}
