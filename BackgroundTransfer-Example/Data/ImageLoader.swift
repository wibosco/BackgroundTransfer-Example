//
//  ImageLoader.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 21/02/2025.
//  Copyright © 2025 William Boles. All rights reserved.
//

import Foundation
import UIKit

enum ImageLoaderError: Error {
    case missingData
    case invalidImageData
}

class ImageLoader {
    private let backgroundDownloader = BackgroundDownloadService()
    
    // MARK: - Load
    
    func loadImage(name: String,
                   url: URL,
                   completionHandler: @escaping ((_ result: Result<UIImage, Error>) -> ())) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let fileManager = FileManager.default
            let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectoryURL = paths[0]
            let localImageURL = documentsDirectoryURL.appendingPathComponent(name)
                
            if fileManager.fileExists(atPath: localImageURL.path) {
                self?.loadLocalImage(localImageURL: localImageURL,
                                     completionHandler: completionHandler)
            } else {
                self?.loadRemoteImage(remoteImageURL: url,
                                      localImageURL: localImageURL,
                                      completionHandler: completionHandler)
            }
        }
    }
    
    private func loadLocalImage(localImageURL: URL,
                                completionHandler: @escaping ((_  result: Result<UIImage, Error>) -> ())) {
        guard let imageData = try? Data(contentsOf: localImageURL) else {
            completionHandler(.failure(ImageLoaderError.missingData))
            return
        }
        
        DispatchQueue.main.async {
            guard let image = UIImage(data: imageData) else {
                completionHandler(.failure(ImageLoaderError.invalidImageData))
                return
            }
            completionHandler(.success(image))
        }
    }
    
    private func loadRemoteImage(remoteImageURL: URL,
                                 localImageURL: URL,
                                 completionHandler: @escaping ((_  result: Result<UIImage, Error>) -> ())) {
        backgroundDownloader.download(remoteURL: remoteImageURL,
                                      localURL: localImageURL) { [weak self] result in
            switch result {
            case let .success(url):
                self?.loadLocalImage(localImageURL: url,
                                     completionHandler: completionHandler)
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }
}
