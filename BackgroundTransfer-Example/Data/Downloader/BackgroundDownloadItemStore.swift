//
//  BackgroundDownloaderContext.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 18/06/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

protocol DownloadItemStore {
    func loadDownloadItem(withURL url: URL) -> BackgroundDownloadItem?
    func saveDownloadItem(_ downloadItem: BackgroundDownloadItem)
    func deleteDownloadItem(_ downloadItem: BackgroundDownloadItem)
}

class MemoryStore: DownloadItemStore {
    private var downloadItems: [URL: BackgroundDownloadItem] = [:]
    
    // MARK: - Load
    
    func loadDownloadItem(withURL url: URL) -> BackgroundDownloadItem? {
        return downloadItems[url]
    }
    
    // MARK: - Save
    
    func saveDownloadItem(_ downloadItem: BackgroundDownloadItem) {
        downloadItems[downloadItem.remoteURL] = downloadItem
    }
    
    // MARK: - Delete
    
    func deleteDownloadItem(_ downloadItem: BackgroundDownloadItem) {
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
    
    func loadDownloadItem(withURL url: URL) -> BackgroundDownloadItem? {
        guard let encodedData = userDefaults.object(forKey: url.path) as? Data else {
            return nil
        }
        
        let downloadItem = try? JSONDecoder().decode(BackgroundDownloadItem.self, from: encodedData)
        return downloadItem
    }
    
    // MARK: - Save
    
    func saveDownloadItem(_ downloadItem: BackgroundDownloadItem) {
        let data = try? JSONEncoder().encode(downloadItem)
        userDefaults.set(data, forKey: downloadItem.remoteURL.path)
    }
    
    // MARK: - Delete
    
    func deleteDownloadItem(_ downloadItem: BackgroundDownloadItem) {
        userDefaults.removeObject(forKey: downloadItem.remoteURL.path)
    }
}

class BackgroundDownloadItemStore {
    private var inMemoryStore: DownloadItemStore
    private var persistentStore: DownloadItemStore
    
    private let queue = DispatchQueue(label: "com.williamboles.background.download.context", 
                                      attributes: .concurrent)
    
    // MARK: - Init
    
    init(inMemoryStore: DownloadItemStore = MemoryStore(),
         persistentStore: DownloadItemStore = UserDefaultsStore()) {
        self.inMemoryStore = inMemoryStore
        self.persistentStore = persistentStore
    }

    // MARK: - Load
    
    func downloadItem(withURL url: URL) -> BackgroundDownloadItem? {
        queue.sync {
            return inMemoryStore.loadDownloadItem(withURL: url) ?? persistentStore.loadDownloadItem(withURL: url)
        }
    }

    // MARK: - Save
    
    func saveDownloadItem(_ downloadItem: BackgroundDownloadItem) {
        queue.async(flags: .barrier) { [weak self] in
            self?.inMemoryStore.saveDownloadItem(downloadItem)
            self?.persistentStore.saveDownloadItem(downloadItem)
        }
    }
    
    // MARK: - Delete
    
    func deleteDownloadItem(_ downloadItem: BackgroundDownloadItem) {
        queue.async(flags: .barrier) { [weak self] in
            self?.inMemoryStore.deleteDownloadItem(downloadItem)
            self?.persistentStore.deleteDownloadItem(downloadItem)
        }
    }
}
