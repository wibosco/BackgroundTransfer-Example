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
    case invalidImageData
}

class ImageLoader {
    private let backgroundDownloadService: BackgroundDownloadService
    private let fileManager: FileManager
    private let documentsDirectoryURL: URL
    private let imageLoadingQueue = DispatchQueue(label: "com.williamboles.image.loader",
                                                  qos: .userInitiated)
    
    // MARK: - Init
    
    init(backgroundDownloadService: BackgroundDownloadService = .shared,
         fileManager: FileManager = .default) {
        self.backgroundDownloadService = backgroundDownloadService
        self.fileManager = fileManager
        self.documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Load
    
    func loadImage(name: String,
                   url: URL,
                   completionHandler: @escaping ((_ result: Result<UIImage, Error>) -> ())) {
        imageLoadingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let localImageURL = self.documentsDirectoryURL.appendingPathComponent(name)
                
            if let imageData = loadLocalImage(from: localImageURL) {
                reportOutcome(imageData: imageData,
                              completionHandler: completionHandler)
            } else {
                loadRemoteImage(from: url,
                                to: localImageURL) { [weak self] imageData in
                    self?.reportOutcome(imageData: imageData,
                                        completionHandler: completionHandler)
                }
            }
        }
    }
    
    private func reportOutcome(imageData: Data?,
                       completionHandler: @escaping ((_ result: Result<UIImage, Error>) -> ())) {
        DispatchQueue.main.async {
            guard let imageData, let image = UIImage(data: imageData) else {
                completionHandler(.failure(ImageLoaderError.invalidImageData))
                return
            }
            completionHandler(.success(image))
        }
    }
    
    private func loadLocalImage(from fromURL: URL) -> Data? {
        try? Data(contentsOf: fromURL)
    }
    
    private func loadRemoteImage(from fromURL: URL,
                                 to toURL: URL,
                                 completionHandler: @escaping ((Data?) -> ())) {
        backgroundDownloadService.download(from: fromURL,
                                           saveDownloadTo: toURL) { _ in
            let imageData = try? Data(contentsOf: toURL)
            completionHandler(imageData)
        }
    }
}
