//
//  BackgroundDownloadItem.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 30/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

class BackgroundDownloadItem: Codable {

    let sessionIdentifier: String
    let remoteLocation: URL
    let localStorageLocation: URL
    
    // MARK: - Init
    
    init(sessionIdentifier: String, remoteLocation: URL, localStorageLocation: URL) {
        self.sessionIdentifier = sessionIdentifier
        self.remoteLocation = remoteLocation
        self.localStorageLocation = localStorageLocation
    }
    
    class func save(intoStorageWithSessionIdentifier sessionIdentifier: String, remoteLocation: URL, localStorageLocation: URL) {
        let userDefaults = UserDefaults.standard
        let downloadAsset = BackgroundDownloadItem(sessionIdentifier: sessionIdentifier, remoteLocation: remoteLocation, localStorageLocation: localStorageLocation)
        let encodedData = try? JSONEncoder().encode(downloadAsset)
        
        userDefaults.set(encodedData, forKey: sessionIdentifier)
    }
    
    class func load(fromStorageWithSessionIdentifier sessionIdentifier: String) -> BackgroundDownloadItem? {
        let userDefaults = UserDefaults.standard
        guard let encodedData = userDefaults.object(forKey: sessionIdentifier) as? Data else {
            return nil
        }
        
        let downloadAsset = try? JSONDecoder().decode(BackgroundDownloadItem.self, from: encodedData)
        return downloadAsset
    }
}
