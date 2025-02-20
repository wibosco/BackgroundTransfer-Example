//
//  BackgroundDownloadItem.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 30/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

typealias ForegroundDownloadCompletionHandler = ((_ result: DataRequestResult<URL>) -> Void)

class DownloadItem: Codable {
    let remoteURL: URL
    let filePathURL: URL
    var foregroundCompletionHandler: ForegroundDownloadCompletionHandler?
    
    private enum CodingKeys: String, CodingKey {
        case remoteURL
        case filePathURL
    }
    
    // MARK: - Init
    
    init(remoteURL: URL, filePathURL: URL) {
        self.remoteURL = remoteURL
        self.filePathURL = filePathURL
    }
}
