//
//  GalleryViewController.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import UIKit

class GalleryViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loadingActivityIndicatorView: UIActivityIndicatorView!
    
    let dataManager = GalleryDataManager()
    var assets = [GalleryAsset]()
    let fileManager = FileManager.default
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retrieveAlbums()
    }
    
    // MARK: - Albums
    
    func retrieveAlbums() {
        loadingActivityIndicatorView.startAnimating()
        
        dataManager.retrieveGallery(forSearchTerms: "cats") { (searchTerms, result) in
            self.loadingActivityIndicatorView.stopAnimating()
            
            switch result {
            case .success(let assets):
                self.assets = assets
                self.collectionView.reloadData()
            case .failure(let error):
                //TODO: Handle
                print("\(error)")
            }
        }
    }
    
    // MARK: - Reset
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        loadingActivityIndicatorView.startAnimating()
        
        for asset in assets {
            try? fileManager.removeItem(at: asset.cachedLocalAssetURL())
        }
        
        assets.removeAll()
        collectionView.reloadData()
        retrieveAlbums()
    }
}

extension GalleryViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryAssetCollectionViewCell.className, for: indexPath) as? GalleryAssetCollectionViewCell else {
            fatalError("Expected cell of type: \(GalleryAssetCollectionViewCell.className)")
        }
        
        let asset = assets[indexPath.row]
        
        cell.configure(asset: asset)
        
        return cell
    }
}

extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (view.frame.size.width - 12.0)/3.0
        return CGSize(width: cellWidth, height: cellWidth)
    }
}
