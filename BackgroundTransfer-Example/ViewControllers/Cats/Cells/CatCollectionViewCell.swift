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
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        catImageView.image = UIImage(named: "icon-placeholder")
    }
}
