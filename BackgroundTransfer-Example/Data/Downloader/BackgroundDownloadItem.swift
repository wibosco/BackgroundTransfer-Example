//
//  BackgroundDownloadItem.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 30/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

class BackgroundDownloadItem: Codable {

    let taskIdentifier: Int
    let remoteLocation: URL
    let localStorageLocation: URL
    
    // MARK: - Init
    
    init(taskIdentifier: Int, remoteLocation: URL, localStorageLocation: URL) {
        self.taskIdentifier = taskIdentifier
        self.remoteLocation = remoteLocation
        self.localStorageLocation = localStorageLocation
    }
    
    class func save(intoStorageWithTaskIdentifier taskIdentifier: Int, remoteLocation: URL, localStorageLocation: URL) {
        let userDefaults = UserDefaults.standard
        let downloadAsset = BackgroundDownloadItem(taskIdentifier: taskIdentifier, remoteLocation: remoteLocation, localStorageLocation: localStorageLocation)
        let encodedData = try? JSONEncoder().encode(downloadAsset)
        let key = BackgroundDownloadItem.key(fromTaskIdentifier: taskIdentifier)
        
        userDefaults.set(encodedData, forKey: key)
    }
    
    class func load(fromStorageWithTaskIdentifier taskIdentifier: Int) -> BackgroundDownloadItem? {
        let userDefaults = UserDefaults.standard
        let key = BackgroundDownloadItem.key(fromTaskIdentifier: taskIdentifier)
        guard let encodedData = userDefaults.object(forKey: key) as? Data else {
            return nil
        }
        
        let downloadAsset = try? JSONDecoder().decode(BackgroundDownloadItem.self, from: encodedData)
        return downloadAsset
    }
    
    // MARK: - Key
    
    private class func key(fromTaskIdentifier taskIdentifier: Int) -> String {
        return "\(taskIdentifier)"
    }
}
