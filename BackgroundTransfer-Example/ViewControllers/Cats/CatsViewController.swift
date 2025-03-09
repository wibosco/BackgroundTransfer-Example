//
//  CatsViewController.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import UIKit
import os

class CatsViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loadingActivityIndicatorView: UIActivityIndicatorView!
        
    private let viewModel = CatsViewModel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingActivityIndicatorView.startAnimating()
        viewModel.retrieveCats {
            self.loadingActivityIndicatorView.stopAnimating()
            self.collectionView.reloadData()
        }
    }
}

extension CatsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfCats()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CatCollectionViewCell.className, for: indexPath) as? CatCollectionViewCell else {
            fatalError("Expected cell of type: \(CatCollectionViewCell.className)")
        }

        viewModel.loadCatImage(at: indexPath) { (image, imageIndexPath) in
            guard let cellCurrentIndexPath = collectionView.indexPath(for: cell), 
                    cellCurrentIndexPath == imageIndexPath else {
                return
            }
            
            cell.catImageView.image = image
        }
        
        return cell
    }
}

extension CatsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (view.frame.size.width - 12.0)/3.0
        return CGSize(width: cellWidth, height: cellWidth)
    }
}
