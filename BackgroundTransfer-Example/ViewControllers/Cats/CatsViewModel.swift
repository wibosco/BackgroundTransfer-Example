//
//  CatsViewModel.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 21/02/2025.
//  Copyright © 2025 William Boles. All rights reserved.
//

import Foundation
import os
import UIKit

class CatsViewModel {
    private var cats: [Cat] = []
    
    private let networkService = NetworkService()
    private let imageLoader = ImageLoader()
        
    // MARK: - Retrieval
    
    func retrieveCats(completion: @escaping (() -> ())) {        
        networkService.retrieveCats { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case let .success(cats):
                    self?.cats = cats
                    
                    completion()
                case let .failure(error):
                    // TODO: Handle
                    os_log(.error, "Error when retrieving json: %{public}@", error.localizedDescription)
                }
            }
        }
    }
    
    func numberOfCats() -> Int {
        return cats.count
    }
    
    // MARK: - Image
    
    func loadCatImage(at indexPath: IndexPath,
                      completion: @escaping (((UIImage, IndexPath)) -> ())) {
        let cat = cats[indexPath.row]
        
        imageLoader.loadImage(name: cat.id,
                              url: cat.url) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(image):
                    completion((image, indexPath))
                case let .failure(error):
                    // TODO: Handle
                    os_log(.error, "Error when loading image: %{public}@", error.localizedDescription)
                }
            }
        }
    }
}
