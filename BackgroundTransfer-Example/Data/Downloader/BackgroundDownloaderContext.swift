//
//  BackgroundDownloaderContext.swift
//  BackgroundTransfer-Example
//
//  Created by Boles, William (Developer) on 18/06/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

class BackgroundDownloaderContext {
    
    private var inMemoryDownloadItems: [URL: DownloadItem] = [:]
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Load
    
    func loadDownloadItem(withURL url: URL) -> DownloadItem? {
        if let downloadItem = inMemoryDownloadItems[url] {
            return downloadItem
        } else if let downloadItem = loadDownloadItemFromStorage(withURL: url) {
             inMemoryDownloadItems[downloadItem.remoteURL] = downloadItem
            
            return downloadItem
        }
        
        return nil
    }
    
    private func loadDownloadItemFromStorage(withURL url: URL) -> DownloadItem? {
        guard let encodedData = userDefaults.object(forKey: url.path) as? Data else {
            return nil
        }
        
        let downloadItem = try? JSONDecoder().decode(DownloadItem.self, from: encodedData)
        return downloadItem
    }
    
    // MARK: - Save
    
    func saveDownloadItem(_ downloadItem: DownloadItem) {
        inMemoryDownloadItems[downloadItem.remoteURL] = downloadItem
        
        let encodedData = try? JSONEncoder().encode(downloadItem)
        userDefaults.set(encodedData, forKey: downloadItem.remoteURL.path)
        userDefaults.synchronize()
    }
    
    // MARK: - Delete
    
    func deleteDownloadItem(_ downloadItem: DownloadItem) {
        inMemoryDownloadItems[downloadItem.remoteURL] = nil
        userDefaults.removeObject(forKey: downloadItem.remoteURL.path)
        userDefaults.synchronize()
    }
}
