//
//  ViewController.swift
//  PhotoTaker
//
//  Created by Abubakar on 11/19/15.
//  Copyright © 2015 Tonespy. All rights reserved.
//

import UIKit
import Photos

class ViewController: UITableViewController, PHPhotoLibraryChangeObserver {
    
    var AllPhotosReuseIdentifier: String = "AllPhotosCell";
    var CollectionCellReuseIdentifier: String = "CollectionCell";
    var sectionFetchResults: NSArray = []
    var sectionLocalizedTitles: NSArray = []
    
    var AllPhotosSegue: String = "showAllPhotos";
    var CollectionSegue: String = "showCollection";
    
    override func awakeFromNib() {
        //Create a PHFetchResult object for each section in the table view
        let allPhotosOPtions = PHFetchOptions()
        allPhotosOPtions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let allPhotos: PHFetchResult = PHAsset.fetchAssetsWithOptions(allPhotosOPtions)
        let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .AlbumRegular, options: nil)
        let topLevelUserCollections: PHFetchResult = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
        
        //Store the PHFetchResult objects and localized titles for each section
        sectionFetchResults = [allPhotos, smartAlbums, topLevelUserCollections]
        sectionLocalizedTitles = ["", NSLocalizedString("Smart Albums", comment: ""), NSLocalizedString("Albums", comment: "")]
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (!segue.destinationViewController.isKindOfClass(AssetGridCollectionViewController)) {
            return
        }
        
        let assetGridViewController = segue.destinationViewController as? AssetGridCollectionViewController
        let cell = sender as? UITableViewCell
        
        //Set the title of the AssetGridViewController
        assetGridViewController!.title = cell!.textLabel?.text
        
        //print(sectionFetchResults)
        
        //Get the PHFetchResult for the selected section
        let indexPath: NSIndexPath = self.tableView.indexPathForCell(cell!)!
        let fetchResult = self.sectionFetchResults[indexPath.section] as! PHFetchResult
        //print("Second One", fetchResult)
        
        if segue.identifier == AllPhotosSegue {
            assetGridViewController?.assetsFetchResults = fetchResult
            print("AssetResult", fetchResult)
            //print("Accet Collection", assetCollection)
        } else if segue.identifier == CollectionSegue {
            let collection = fetchResult[indexPath.row] as! PHCollection
            if !collection.isKindOfClass(PHAssetCollection) {
                return
            }
            
            //Configure the AssetGridViewController with the asset collection
            let assetCollection = collection as! PHAssetCollection
            let assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(assetCollection, options: nil)
            
            print("AssetResult", assetsFetchResult)
            print("Accet Collection", assetCollection)
            assetGridViewController?.assetsFetchResults = assetsFetchResult
            assetGridViewController?.assetCollection = assetCollection
        }
    }
    
    //#pragma mark - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange) {
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            let updatedSectionFetchResults = self.sectionFetchResults.mutableCopy() as! NSMutableArray
            var reloadRequired: Bool = false
            self.sectionFetchResults.enumerateObjectsUsingBlock({(collectionsFetchResult: AnyObject, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                let changeDetails: PHFetchResultChangeDetails = changeInstance.changeDetailsForFetchResult(collectionsFetchResult as! PHFetchResult)!
                if changeDetails.hasIncrementalChanges || changeDetails.hasMoves {
                    updatedSectionFetchResults.replaceObjectAtIndex(index, withObject: changeDetails.fetchResultAfterChanges)
                    reloadRequired = true
                }
            })
            if reloadRequired {
                self.sectionFetchResults = updatedSectionFetchResults
                self.tableView.reloadData()
            }
        })
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows: NSInteger = 0
        
        if section == 0 {
            //The "All Photos" section only ever has a single view
            numberOfRows = 1
        } else {
            let fetchResult = self.sectionFetchResults[section] as! PHFetchResult
            numberOfRows = fetchResult.count
        }
        //print(section)
        //print(numberOfRows)
        return numberOfRows
    }
    
    //#pragma mark - UITableViewDataSource
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell =  UITableViewCell()
        
        if (indexPath.section == 0) {
            cell = tableView.dequeueReusableCellWithIdentifier(AllPhotosReuseIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("All Photos", comment: "")
        } else {
            let fetchResult = sectionFetchResults[indexPath.section] as! PHFetchResult
            let collection = fetchResult[indexPath.row] as! PHCollection
            
            cell = tableView.dequeueReusableCellWithIdentifier(CollectionCellReuseIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = collection.localizedTitle
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionLocalizedTitles[section] as? String
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.sectionFetchResults.count
    }

}

