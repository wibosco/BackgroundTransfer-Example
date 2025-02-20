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
    private let inMemoryStore: DownloadItemStore
    private let persistentStore: DownloadItemStore
        
    // MARK: - Init
    
    init(inMemoryStore: DownloadItemStore = MemoryStore(),
         persistentStore: DownloadItemStore = UserDefaultsStore()) {
        self.inMemoryStore = inMemoryStore
        self.persistentStore = persistentStore
    }
    
    // MARK: - Load
    
    func loadDownloadItem(withURL url: URL) -> DownloadItem? {
        return inMemoryStore.loadDownloadItem(withURL: url) ?? persistentStore.loadDownloadItem(withURL: url)
    }

    // MARK: - Save
    
    func saveDownloadItem(_ downloadItem: DownloadItem) {
        inMemoryStore.saveDownloadItem(downloadItem)
        persistentStore.saveDownloadItem(downloadItem)
    }
    
    // MARK: - Delete
    
    func deleteDownloadItem(_ downloadItem: DownloadItem) {
        inMemoryStore.deleteDownloadItem(downloadItem)
        persistentStore.deleteDownloadItem(downloadItem)
    }
}
