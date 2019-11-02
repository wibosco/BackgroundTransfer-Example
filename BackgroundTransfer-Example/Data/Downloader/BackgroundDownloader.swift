//
//  BackgroundDownloader.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 02/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation
import UIKit

class BackgroundDownloader: NSObject {

    private var session: URLSession!
    private var downloadItems: [URL: DownloadItem] = [:]
    
    // MARK: - Singleton
    
    static let shared = BackgroundDownloader()
    
    // MARK: - Init
    
    private override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "background.download.session")
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Download
    
    func download(remoteURL: URL, filePathURL: URL, completionHandler: @escaping ForegroundDownloadCompletionHandler) {
        print("Scheduling to download: \(remoteURL)")
        
        let downloadItem = DownloadItem(remoteURL: remoteURL, filePathURL: filePathURL)
        downloadItem.foregroundCompletionHandler = completionHandler
        downloadItems[remoteURL] = downloadItem
        
        let task = session.downloadTask(with: remoteURL)
        task.resume()
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let originalRequestURL = downloadTask.originalRequest?.url, let downloadItem = downloadItems[originalRequestURL] else {
            return
        }
        
        print("Downloaded: \(downloadItem.remoteURL)")
        
        do {
            try FileManager.default.moveItem(at: location, to: downloadItem.filePathURL)
            
            downloadItem.foregroundCompletionHandler?(.success(downloadItem.filePathURL))
        } catch {
            downloadItem.foregroundCompletionHandler?(.failure(APIError.invalidData))
        }
        
        downloadItems[originalRequestURL] = nil
    }
}
