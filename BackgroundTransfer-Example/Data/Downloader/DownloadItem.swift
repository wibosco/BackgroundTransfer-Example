//
//  BackgroundDownloadItem.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 30/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

typealias ForegroundDownloadCompletionHandler = ((_ result: Result<URL, Error>) -> Void)

class DownloadItem: Codable {
    let remoteURL: URL
    let localURL: URL
    var foregroundCompletionHandler: ForegroundDownloadCompletionHandler?
    
    private enum CodingKeys: String, CodingKey {
        case remoteURL
        case localURL
    }
    
    // MARK: - Init
    
    init(remoteURL: URL, 
         localURL: URL) {
        self.remoteURL = remoteURL
        self.localURL = localURL
    }
}
