//
//  BackgroundDownloadItem.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 30/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

class BackgroundDownloadItem: Codable {
    let remoteURL: URL
    let localURL: URL
    var foregroundCompletionHandler: ((_ result: Result<URL, Error>) -> Void)?
    
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
