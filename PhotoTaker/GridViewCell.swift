//
//  GridViewCell.swift
//  PhotoTaker
//
//  Created by Abubakar on 11/19/15.
//  Copyright © 2015 Tonespy. All rights reserved.
//

import UIKit

class GridViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    var thumbnailImage = UIImage()
    var representedAssetIdentifier = NSString()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
    
    //func setThumbnailImage(thumbnailImage: UIImage) {
    //    self.imageView.image = thumbnailImage
    //}
}
