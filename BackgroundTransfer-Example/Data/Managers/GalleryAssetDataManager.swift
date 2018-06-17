//
//  AssetDataManager.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation
import UIKit

enum DataRequestResult<T> {
    case success(T)
    case failure(Error)
}

struct LoadAssetResult: Equatable {
    let asset: GalleryAsset
    let image: UIImage
}

class GalleryAssetDataManager {
    
    private let fileManager = FileManager.default
    
    // MARK: - GalleryItem
    
    func loadGalleryItemAsset(_ asset: GalleryAsset, completionHandler: @escaping ((_ result: DataRequestResult<LoadAssetResult>) -> ())) {
        if fileManager.fileExists(atPath: asset.cachedLocalAssetURL().path) {
            print("Found local asset; attempting to load")
            locallyLoadAsset(asset, completionHandler: completionHandler)
        } else {
            remotelyLoadAsset(asset, completionHandler: completionHandler)
        }
    }
    
    private func locallyLoadAsset(_ asset: GalleryAsset, completionHandler: @escaping ((_ result: DataRequestResult<LoadAssetResult>) -> ())) {
        do {
            let data = try Data(contentsOf: asset.cachedLocalAssetURL())
            
            guard let image = UIImage(data: data) else {
                completionHandler(.failure(APIError.invalidData))
                return
            }
            
            let loadResult = LoadAssetResult(asset: asset, image: image)
            let dataRequestResult = DataRequestResult<LoadAssetResult>.success(loadResult)
            
            DispatchQueue.main.async {
                completionHandler(dataRequestResult)
            }
        } catch {
            remotelyLoadAsset(asset, completionHandler: completionHandler)
        }
    }
    
    private func remotelyLoadAsset(_ asset: GalleryAsset, completionHandler: @escaping ((_ result: DataRequestResult<LoadAssetResult>) -> ())) {
        let downloader = BackgroundDownloader.shared
        
        downloader.download(remoteLocation: asset.url, localStorageLocation: asset.cachedLocalAssetURL()) { (result) in
            switch result {
            case .success(let url):
                var retrievedData: Data? = nil
                do {
                    retrievedData = try Data(contentsOf: url)
                } catch {
                    completionHandler(.failure(APIError.invalidData))
                }
                
                guard let imageData = retrievedData, let image = UIImage(data: imageData) else {
                    completionHandler(.failure(APIError.invalidData))
                    return
                }
                
                let loadResult = LoadAssetResult(asset: asset, image: image)
                let dataRequestResult = DataRequestResult<LoadAssetResult>.success(loadResult)
                
                DispatchQueue.main.async {
                    completionHandler(dataRequestResult)
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}
