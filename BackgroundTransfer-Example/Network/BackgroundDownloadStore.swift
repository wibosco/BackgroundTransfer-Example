//
//  BackgroundDownloadStore.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 20/03/2025.
//  Copyright © 2025 William Boles. All rights reserved.
//

import Foundation

typealias BackgroundDownloadCompletion = (_ result: Result<URL, Error>) -> ()

class BackgroundDownloadStore {
    private var inMemoryStore = [String: BackgroundDownloadCompletion]()
    private let persistentStore = UserDefaults.standard
        
    private let queue = DispatchQueue(label: "com.williamboles.background.download.service",
                                      qos: .userInitiated,
                                      attributes: .concurrent)
    
    // MARK: - Store
    
    func storeMetadata(from fromURL: URL,
                       to toURL: URL,
                       completionHandler: @escaping BackgroundDownloadCompletion) {
        queue.async(flags: .barrier) { [weak self] in
            self?.inMemoryStore[fromURL.absoluteString] = completionHandler
            self?.persistentStore.set(toURL, forKey: fromURL.absoluteString)
        }
    }
    
    // MARK: - Retrieve
    
    func retrieveMetadata(for forURL: URL, 
                          completionHandler: @escaping ((URL?, BackgroundDownloadCompletion?) -> ())) {
        return queue.async { [weak self] in
            let key = forURL.absoluteString
            
            let toURL = self?.persistentStore.url(forKey: key)
            let metaDataCompletionHandler = self?.inMemoryStore[key]
            
            completionHandler(toURL, metaDataCompletionHandler)
        }
    }
    
    // MARK: - Remove
    
    func removeMetadata(for forURL: URL) {
        queue.async(flags: .barrier) { [weak self] in
            let key = forURL.absoluteString
            
            self?.inMemoryStore[key] = nil
            self?.persistentStore.removeObject(forKey: key)
        }
    }
}
