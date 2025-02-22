//
//  CatCollectionViewCell.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import UIKit
import os

class CatCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var catImageView: UIImageView!
    
    private var cat: Cat?
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        catImageView.image = UIImage(named: "icon-placeholder")
    }
    
    // MARK: - Configure
    
//    func configure(cat: Cat) {
//        self.cat = cat
////        let image = assetDataManager.load(galleryItemAsset: asset) { [weak self] (result) in
////            switch result {
////            case .success(let loadResult):
////                if loadResult.asset == self?.asset {
////                    self?.assetImageView.image = loadResult.image
////                }
////            case .failure(let error):
////                //TODO: Handle
////                os_log(.error, "Error when retrieving image: %{public}@", error.localizedDescription)
////            }
////        }
////        
////        if image != nil {
////            assetImageView.image = image
////        }
//    }
}
