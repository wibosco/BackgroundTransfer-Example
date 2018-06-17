//
//  GalleryAssetCollectionViewCell.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import UIKit

class GalleryAssetCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var assetImageView: UIImageView!
    
    private var assetDataManager = GalleryAssetDataManager()
    private var asset: GalleryAsset?
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        assetImageView.image = UIImage(named: "icon-placeholder")
    }
    
    // MARK: - Configure
    
    func configure(asset: GalleryAsset) {
        self.asset = asset
        assetDataManager.load(galleryItemAsset: asset) { [weak self] (result) in
            switch result {
            case .success(let loadResult):
                if loadResult.asset == self?.asset {
                    self?.assetImageView.image = loadResult.image
                }
            case .failure(let error):
                //TODO: Handle
                print(error)
            }
        }
    }
}
