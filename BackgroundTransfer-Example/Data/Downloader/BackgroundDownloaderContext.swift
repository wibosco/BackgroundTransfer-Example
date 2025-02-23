//
//  BackgroundDownloaderContext.swift
//  BackgroundTransfer-Example
//
//  Created by Boles, William (Developer) on 18/06/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

protocol DownloadItemStore {
    func loadDownloadItem(withURL url: URL) -> DownloadItem?
    func saveDownloadItem(_ downloadItem: DownloadItem)
    func deleteDownloadItem(_ downloadItem: DownloadItem)
}

class MemoryStore: DownloadItemStore {
    private var downloadItems: [URL: DownloadItem] = [:]
    
    // MARK: - Load
    
    func loadDownloadItem(withURL url: URL) -> DownloadItem? {
        return downloadItems[url]
    }
    
    // MARK: - Save
    
    func saveDownloadItem(_ downloadItem: DownloadItem) {
        downloadItems[downloadItem.remoteURL] = downloadItem
    }
    
    // MARK: - Delete
    
    func deleteDownloadItem(_ downloadItem: DownloadItem) {
        downloadItems[downloadItem.remoteURL] = nil
    }
}

class UserDefaultsStore: DownloadItemStore {
    private let userDefaults: UserDefaults
    
    // MARK: - Init
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Load
    
    func loadDownloadItem(withURL url: URL) -> DownloadItem? {
        guard let encodedData = userDefaults.object(forKey: url.path) as? Data else {
            return nil
        }
        
        let downloadItem = try? JSONDecoder().decode(DownloadItem.self, from: encodedData)
        return downloadItem
    }
    
    // MARK: - Save
    
    func saveDownloadItem(_ downloadItem: DownloadItem) {
        let data = try? JSONEncoder().encode(downloadItem)
        userDefaults.set(data, forKey: downloadItem.remoteURL.path)
        userDefaults.synchronize()
    }
    
    // MARK: - Delete
    
    func deleteDownloadItem(_ downloadItem: DownloadItem) {
        userDefaults.removeObject(forKey: downloadItem.remoteURL.path)
        userDefaults.synchronize()
    }
}

class BackgroundDownloaderContext {
    private let inMemoryStore = MemoryStore()
    private let persistentStore = UserDefaultsStore()
    
    private let queue = DispatchQueue(label: "com.williamboles.background.download.context", 
                                      attributes: .concurrent)

    // MARK: - Load
    
    func loadDownloadItem(withURL url: URL) -> DownloadItem? {
        queue.sync {
            return inMemoryStore.loadDownloadItem(withURL: url) ?? persistentStore.loadDownloadItem(withURL: url)
        }
    }

    // MARK: - Save
    
    func saveDownloadItem(_ downloadItem: DownloadItem) {
        queue.async(flags: .barrier) { [weak self] in
            self?.inMemoryStore.saveDownloadItem(downloadItem)
            self?.persistentStore.saveDownloadItem(downloadItem)
        }
    }
    
    // MARK: - Delete
    
    func deleteDownloadItem(_ downloadItem: DownloadItem) {
        queue.async(flags: .barrier) { [weak self] in
            self?.inMemoryStore.deleteDownloadItem(downloadItem)
            self?.persistentStore.deleteDownloadItem(downloadItem)
        }
    }
}
