//
//  GalleryParser.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

class GalleryParser: Parser<[GalleryAsset]> {
    
    // MARK: - Parse
    
    override func parseResponse(_ response: [String: Any]) -> [GalleryAsset] {
        var assets = [GalleryAsset]()
        
        guard let itemsResponse = response["data"] as? [[String: Any]] else {
            return assets
        }

        for itemResponse in itemsResponse {
            if let parsedAssets = parseItem(itemResponse) {
                if parsedAssets.count > 0 {
                    assets.append(contentsOf: parsedAssets)
                }
            }
        }
        
        return assets
    }
    
    private func parseItem(_ itemResponse: [String: Any]) -> [GalleryAsset]? {
        guard let isAlbum = itemResponse["is_album"] as? Bool else {
            return nil
        }
        
        if isAlbum {
            return parseItemAlbum(itemResponse)
        } else {
            return parseItemImage(itemResponse)
        }
    }
    
    func parseItemImage(_ itemResponse: [String: Any]) -> [GalleryAsset]? {
        guard let imageURLString = itemResponse["link"] as? String,
            let imageURL = URL(string: imageURLString)
            else {
                return nil
        }
        
        let asset = GalleryAsset(id: fileName(forURL: imageURL), url: imageURL)
                
        return [asset]
    }
    
    func parseItemAlbum(_ itemResponse: [String: Any]) -> [GalleryAsset]? {
        guard let imageResponses = itemResponse["images"] as? [[String: Any]]
            else {
            return nil
        }
        
        var assets = [GalleryAsset]()
        
        for imageResponse in imageResponses {
            if let linkURLString = imageResponse["link"] as? String {
                if let linkURL = URL(string: linkURLString) {
                    
                    let asset = GalleryAsset(id: fileName(forURL: linkURL), url: linkURL)

                    assets.append(asset)
                }
            }
        }
        
        return assets
    }
    
    func fileName(forURL url: URL) -> String {
        return url.deletingPathExtension().lastPathComponent
    }
}
