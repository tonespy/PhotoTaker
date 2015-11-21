//
//  AssetGridCollectionViewController.swift
//  PhotoTaker
//
//  Created by Abubakar on 11/19/15.
//  Copyright © 2015 Tonespy. All rights reserved.
//

import UIKit
import Photos
import SDWebImage

class AssetGridCollectionViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {
    
    var assetsFetchResults = PHFetchResult()
    var assetCollection = PHAssetCollection()
    var prevoiusPreheatRect = CGRect()
    var imageManager = PHCachingImageManager()
    var CellReuseIdentifier: String = "Cell"
    var AssetGridThumbnailSize = CGSize()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetCachedAssets()
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)

    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale: CGFloat = UIScreen.mainScreen().scale
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            let cellSize: CGSize = UICollectionViewFlowLayout.collectionViewContentSize(layout)()
            AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale)
        }
        
        //Add button to the navigation bar if the asset collection supports adding content
        //if self.assetCollection || self.assetCollection.canPerformEditOperation(.AddContent) {
        //    self.navigationItem.rightBarButtonItem = self.add
        //}
    }
    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        self.updateCachedAssets()
//    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.destinationViewController.isKindOfClass(ViewController) {
//            assets
//        }
//    }
    
    // #pragma mark - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange) {
        
        //Check if there are changes to the assets we are showing.
        let collectionChanges: PHFetchResultChangeDetails = changeInstance.changeDetailsForFetchResult(self.assetsFetchResults)!
        //if collectionChanges {
        //    return
        //}
        
        //Change notifications may be made on a background queue. Re-dispatch to the main queue before acting on the change as we'll be updating the UI.
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            
            // Get the new fetch result
            self.assetsFetchResults = collectionChanges.fetchResultAfterChanges
            
            let collectionView: UICollectionView = self.collectionView!
            
            if collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                collectionView.reloadData()
            } else {
                // Tell the collection view to animate insertions and deletions if we have incremental diffs
                collectionView.performBatchUpdates({() -> Void in
                    let removedIndexes: NSIndexSet = collectionChanges.removedIndexes!
                    if removedIndexes.count > 0 {
                        collectionView.deleteItemsAtIndexPaths([removedIndexes .aapl_indexPathsFromIndexesWithSection(0) as AnyObject as! NSIndexPath])
                    }
                    
                    let insertedIndexes: NSIndexSet = collectionChanges.removedIndexes!
                    if insertedIndexes.count > 0 {
                        collectionView.deleteItemsAtIndexPaths([insertedIndexes .aapl_indexPathsFromIndexesWithSection(0) as AnyObject as! NSIndexPath])
                    }
                    
                    let changedIndexes: NSIndexSet = collectionChanges.removedIndexes!
                    if changedIndexes.count > 0 {
                        collectionView.deleteItemsAtIndexPaths([changedIndexes .aapl_indexPathsFromIndexesWithSection(0) as AnyObject as! NSIndexPath])
                    }
                    }, completion: nil)
            }
            //self.resetCacheAssets()
        })
    }
    
    // #pragma mark - UICollectionViewDataSource
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(assetsFetchResults.count)
        return self.assetsFetchResults.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let asset = self.assetsFetchResults[indexPath.item] as! PHAsset
        
        //Deque an GridViewCell
        let cell: GridViewCell = (collectionView.dequeueReusableCellWithReuseIdentifier(CellReuseIdentifier, forIndexPath: indexPath) as? GridViewCell)!
        //cell.representedAssetIdentifier = asset.localIdentifier
        //cell.imageView.image = assetsFetchResults.objectAtIndex(indexPath.row) as? UIImage
        
        //Request an image for the asset from the PHCachingImageManager
        self.imageManager.requestImageForAsset(asset, targetSize: AssetGridThumbnailSize, contentMode: PHImageContentMode.AspectFill, options: nil) { (result: UIImage?, info: [NSObject : AnyObject]?) -> Void in
            //cell.thumbnailImage = result!
            //print(result)
            if let imageResult = result {
                cell.imageView.sd_setImageWithURL(NSURL(string: ""), placeholderImage: imageResult)
             }
//            if result != nil {
//                if let result = result {
//                    cell.thumbnailImage = result
//                }
//            }
        }
        return cell
    }
    
    //UIScrollViewDelelgate
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.updateCachedAssets()
    }
    
    // #pragma mark - Asset Caching
    func resetCachedAssets() {
        self.imageManager.stopCachingImagesForAllAssets()
        self.prevoiusPreheatRect = CGRectZero
    }
    
    func updateCachedAssets() -> Void {
        let isViewVisible: Bool = self.isViewLoaded() && self.view.window != nil
        if !isViewVisible { return }
        
        //The preheat window is twice the height of the visible rect
        var preheatRect: CGRect = (self.collectionView?.bounds)!
        preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect))
        
        //Check if the collection view is showing an area that is significantly diferent to the last preheated area
        let delta: CGFloat = abs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.prevoiusPreheatRect))
        if delta > CGRectGetHeight((self.collectionView?.bounds)!)/3.0 {
            
            //Compute the assets to start caching and to stop caching
            let addedIndexPaths = NSMutableArray()
            let removedIndexPaths = NSMutableArray()
            
            self.computeDifferenceBetweenRect(self.prevoiusPreheatRect, andRect: preheatRect, removedHandler: { (removedRect) -> Void in
                let indexPaths: NSArray = [self.collectionView! .aapl_indexPathsForElementsInRect(removedRect)]
                removedIndexPaths.addObjectsFromArray(indexPaths as [AnyObject])
                }, addedHandler: { (addedRect) -> Void in
                    let indexPaths: NSArray = [self.collectionView! .aapl_indexPathsForElementsInRect(addedRect)]
                    addedIndexPaths.addObjectsFromArray(indexPaths as [AnyObject])
            })
            
            //print("AssetAtIndex", self.assetsAtIndexPaths(addedIndexPaths))
            let assetsToStartCaching: NSArray = self.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching: NSArray = self.assetsAtIndexPaths(removedIndexPaths)
            
            //Update the assets the PHCachingImageManager is caching.
            self.imageManager.startCachingImagesForAssets(assetsToStartCaching as! [PHAsset], targetSize: AssetGridThumbnailSize, contentMode: .AspectFill, options: nil)
            self.imageManager.stopCachingImagesForAssets(assetsToStopCaching as! [PHAsset], targetSize: AssetGridThumbnailSize, contentMode: .AspectFill, options: nil)
            self.prevoiusPreheatRect = preheatRect
        }
    }
    
    func computeDifferenceBetweenRect(oldRect: CGRect, andRect newRect:CGRect, removedHandler: ((removedRect: CGRect) -> Void), addedHandler: ((addedRect: CGRect) -> Void)) {
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY: CGFloat = CGRectGetMaxY(oldRect)
            let oldMinY: CGFloat = CGRectGetMinY(oldRect)
            let newMaxY: CGFloat = CGRectGetMaxY(newRect)
            let newMinY: CGFloat = CGRectGetMinY(newRect)
            
            if newMaxY > oldMaxY {
                let rectToAdd: CGRect = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY))
                addedHandler(addedRect: rectToAdd)
            }
            
            if oldMinY > newMinY {
                let rectToAdd: CGRect = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY))
                addedHandler(addedRect: rectToAdd)
            }
            
            if newMaxY > oldMaxY {
                let rectToRemove: CGRect = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY))
                removedHandler(removedRect: rectToRemove)
            }
            
            if oldMinY > newMinY {
                let rectToRemove: CGRect = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY))
                removedHandler(removedRect: rectToRemove)
            }
        }
    }
    
    func assetsAtIndexPaths(indexPaths: NSArray) -> NSArray {
        if indexPaths.count == 0 {return []}
        
        let assets = NSMutableArray(capacity: indexPaths.count)
        for indexPath in indexPaths {
            //print(indexPath)
            if let asset = self.assetsFetchResults[indexPath.item] as? PHAsset {
                assets.addObject(asset)
            }

        }
        return assets
    }

}
