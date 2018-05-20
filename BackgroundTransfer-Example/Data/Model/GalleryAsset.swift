//
//  GalleryAsset.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 02/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

struct GalleryAsset: Equatable {
    
    let id: String
    let url: URL
    
    // MARK: - Location
    
    func cachedLocalAssetURL() -> URL {
        let cacheURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!
        let fileName = url.deletingPathExtension().lastPathComponent
        return cacheURL.appendingPathComponent(fileName)
    }
}
