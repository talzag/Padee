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

final class ImagePreviewViewController: UIViewController {
    var shareActionCompletionHandler: ((UIImage) -> Void)?
    
    var image: UIImage? {
        didSet {
            (view as! UIImageView).image = image
        }
    }
    
    override func loadView() {
        view = UIImageView()
        view.frame = (CGRect(origin: .zero, size: preferredContentSize))
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        guard let image = image else {
            return []
        }
        
        let shareAction = UIPreviewAction(title: "Share", style: .default) { [unowned self] (action, controller) in
            self.shareActionCompletionHandler?(image)
        }
        
        return [shareAction]
    }
}

final class ImageGalleryCollectionViewController: UICollectionViewController, UITextFieldDelegate, UIViewControllerPreviewingDelegate {

    var selectedSketch: SketchPadFile?
    var files = [SketchPadFile]()
    var noSketchesMessageLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.allowsMultipleSelection = false
        
        if files.count > 0 {
            navigationItem.rightBarButtonItem = editButtonItem
        } else {
            addNoSketchesMessageLabel()
        }
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: collectionView!)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            collectionView?.allowsMultipleSelection = true
            
            let deleteBarButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteSketches(_:)))
            deleteBarButton.isEnabled = false;
            navigationItem.setLeftBarButton(deleteBarButton, animated: true)
        } else {
            collectionView?.allowsMultipleSelection = false
            
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
    
    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return files.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbnailImageCollectionViewCell
    
        let sketch = files[indexPath.section]
        cell.imageView.image = sketch.thumbnail

        if !isEditing {
            cell.selectedImageView.alpha = 0.0
        }
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sketchNameView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SketchNameView", for: indexPath) as! SketchNameSupplementaryView
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(renameSketch))
        sketchNameView.addGestureRecognizer(tapRecognizer)
        
        let sketch = files[indexPath.section]
        sketchNameView.nameLabel.text = sketch.fileURL.lastPathComponent
        
        return sketchNameView
    }

    // MARK: - UICollectionViewDelegate
    
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
    
    // MARK: - UIPasteboard Functionality
    // FIXME: UIPasteboard-related commands
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        let allowedActions = [
            #selector(UIResponderStandardEditActions.copy(_:))
        ]
        return allowedActions.contains(action)
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let sketch = files[indexPath.section]
        UIPasteboard.general.setValue(sketch.thumbnail, forPasteboardType: kUTTypeImage as String)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let collectionView = sender as? UICollectionView,
              let destination = segue.destination as? ViewController else {
            fatalError()
        }
        
        guard let indexPath = collectionView.indexPathsForSelectedItems?.first else {
            return
        }
        
        let sketch = files[indexPath.section]
        
        destination.restore(sketch, savingCurrentSketch: true)
    }
    
    // MARK: - UITextField delegate
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        guard let newName = textField.text?.trimmingCharacters(in: .whitespaces) else {
            return
        }
        
        guard reason == .committed,
              !newName.isEmpty,
              newName != selectedSketch?.sketch.name else {
            return
        }
        
        fileManagerController.rename(sketchPadFile: selectedSketch!, to: newName)
    }
    
    // MARK: - UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard !self.isEditing,
              let indexPath = collectionView?.indexPathForItem(at: location),
              let cell = collectionView?.cellForItem(at: indexPath) as? ThumbnailImageCollectionViewCell else {
            return nil
        }
        
        collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        
        previewingContext.sourceRect = cell.frame
        
        let sketch = files[indexPath.section]
        let attributes = try? sketch.fileAttributesToWrite(to: sketch.fileURL, for: .forOverwriting)
        guard let thumbnails = attributes?[URLResourceKey.thumbnailDictionaryKey] as? [AnyHashable: AnyObject?],
              let image = thumbnails[URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey] as? UIImage else {
            return nil
        }
        
        let imagePreviewViewController = ImagePreviewViewController()
        imagePreviewViewController.image = image
        imagePreviewViewController.shareActionCompletionHandler = shareImage(_:)
        imagePreviewViewController.preferredContentSize = CGSize(width: 0.0, height: 0.0)
        
        return imagePreviewViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        performSegue(withIdentifier: "RestoreImageUnwind", sender: collectionView)
    }
    
    // MARK: - Helper methods
    
    @IBAction func didFinishViewingImageGallery(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    func renameSketch(_ sender: UITapGestureRecognizer) {
        // TODO: Clean up this mess
        guard let supplementaryView = sender.view as? SketchNameSupplementaryView else {
            fatalError("Expected sender to be instance of SketchNameSupplementaryView. Instead got \(String(describing: sender.view.self))")
        }
        
        let sketchName = supplementaryView.nameLabel.text
        
        guard let indexPaths = collectionView?.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionElementKindSectionFooter) else {
            return
        }
        
        for index in indexPaths {
            let view = collectionView?.supplementaryView(forElementKind: UICollectionElementKindSectionFooter, at: index )as? SketchNameSupplementaryView
            if view?.nameLabel.text == sketchName {
                selectedSketch = files[index.section]
            }
        }
        
        guard selectedSketch != nil else {
            return
        }
        
        let alertController = UIAlertController(title: "Rename Sketch", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { [unowned self] (textField) in
            textField.delegate = self
            textField.text = supplementaryView.nameLabel.text
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let done = UIAlertAction(title: "Done", style: .default) { [unowned alertController, supplementaryView] (action) in
            if let newName = alertController.textFields?.first?.text {
                self.fileManagerController.rename(sketchPadFile: self.selectedSketch!, to: newName)
                supplementaryView.nameLabel.text = newName
            }
            
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
            let sketches = indexPaths.map { indexPath -> SketchPadFile in
                let sketch = self.files[indexPath.section]
                return sketch
            }
            
            self.fileManagerController.deleteSketches(sketches) { deleted in
                self.removeItems(deleted)
            }
        }
        
        alert.addAction(deleteSketches)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
        
        let popover = alert.popoverPresentationController
        popover?.sourceView = (sender as? UIBarButtonItem)?.customView
        popover?.sourceRect = CGRect(x: 0, y: 5, width: 32, height: 32)
    }
    
    func shareImage(_ image: UIImage) {
        let activities = [PNGExportActivity(), JPGExportActivity()]
        let shareViewController = UIActivityViewController(activityItems: [image], applicationActivities: activities)
        
        present(shareViewController, animated: true, completion: nil)
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
    
    private func removeItems(_ urls: [String]) {
        var indexes = [Int]()
        for x in 0..<self.files.count {
            let url = self.files[x].fileURL.path
            if urls.contains(url) {
                indexes.append(x)
            }
        }
        
        let indexSet = IndexSet(indexes)
        
        self.files = self.files.filter {
            let url = $0.fileURL.path
            
            let delete = urls.contains(url)
            
            return !delete
        }
        
        DispatchQueue.main.async {
            self.collectionView?.performBatchUpdates({
                self.collectionView?.deleteSections(indexSet)
            }) { (done) in
                self.isEditing = false
                
                if done && self.files.count == 0 {
                    self.addNoSketchesMessageLabel()
                    self.navigationItem.rightBarButtonItem = nil
                }
            }
        }
    }
}
