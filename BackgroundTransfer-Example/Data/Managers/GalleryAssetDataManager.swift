//
//  GalleryAssetDataManager.swift
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
    
    // MARK: - GalleryItem
    
    func load(galleryItemAsset asset: GalleryAsset, remoteLoadHandler: @escaping ((_ result: DataRequestResult<LoadAssetResult>) -> ())) -> UIImage? {
        if let image = UIImage(contentsOfFile: asset.cachedLocalAssetURL().path) {
            return image
        } else {
            remotelyLoadAsset(asset, remoteLoadHandler: remoteLoadHandler)
        }
        
        return nil
    }
    
    private func remotelyLoadAsset(_ asset: GalleryAsset, remoteLoadHandler: @escaping ((_ result: DataRequestResult<LoadAssetResult>) -> ())) {
        let downloader = BackgroundDownloader.shared
        
        downloader.download(remoteURL: asset.url, filePathURL: asset.cachedLocalAssetURL()) { (result) in
            switch result {
            case .success(let url):
                var retrievedData: Data? = nil
                do {
                    retrievedData = try Data(contentsOf: url)
                } catch {
                    remoteLoadHandler(.failure(APIError.invalidData))
                }
                
                guard let imageData = retrievedData, let image = UIImage(data: imageData) else {
                    remoteLoadHandler(.failure(APIError.invalidData))
                    return
                }
                
                let loadResult = LoadAssetResult(asset: asset, image: image)
                let dataRequestResult = DataRequestResult<LoadAssetResult>.success(loadResult)
                
                DispatchQueue.main.async {
                    remoteLoadHandler(dataRequestResult)
                }
            case .failure(let error):
                remoteLoadHandler(.failure(error))
            }
        }
    }
}
