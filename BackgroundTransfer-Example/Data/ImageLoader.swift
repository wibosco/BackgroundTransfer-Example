//
//  ImageLoader.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 21/02/2025.
//  Copyright © 2025 William Boles. All rights reserved.
//

import Foundation
import UIKit

class ImageLoader {
    private let backgroundDownloader = BackgroundDownloader()
    
    // MARK: - Load
    
    func loadImage(name: String,
                   url: URL,
                   completionHandler: @escaping ((_ result: Result<UIImage, Error>) -> ())) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectoryURL = paths[0]
        let localImageURL = documentsDirectoryURL.appendingPathComponent(name)
            
        if let image = loadLocalImage(localImageURL: localImageURL) {
            completionHandler(.success(image))
        } else {
            loadRemoteImage(remoteImageURL: url,
                            localImageURL: localImageURL,
                            completionHandler: completionHandler)
        }
    }
    
    private func loadLocalImage(localImageURL: URL) -> UIImage? {
        return UIImage(contentsOfFile: localImageURL.path)
    }
    
    private func loadRemoteImage(remoteImageURL: URL,
                                 localImageURL: URL,
                                 completionHandler: @escaping ((_  result: Result<UIImage, Error>) -> ())) {
        backgroundDownloader.download(remoteURL: remoteImageURL,
                                      localURL: localImageURL) { [weak self] result in
            switch result {
            case let .success(url):
                guard  let image = self?.loadLocalImage(localImageURL: url) else {
                    // TODO: Handle error
                    return
                }
                completionHandler(.success(image))
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }
}
