//
//  BackgroundDownloadService.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 02/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation
import os

class BackgroundDownloadService: NSObject {
    var backgroundCompletionHandler: (() -> Void)?
    
    private let fileManager = FileManager.default
    private let store = BackgroundDownloadItemStore()
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.williamboles.background.download.session")
        configuration.sessionSendsLaunchEvents = true
        let session = URLSession(configuration: configuration, 
                                 delegate: self,
                                 delegateQueue: nil)
        
        return session
    }()
    
    // MARK: - Singleton
    
    static let shared = BackgroundDownloadService()
    
    // MARK: - Download
    
    func download(remoteURL: URL, 
                  localURL: URL,
                  completionHandler: @escaping ((_ result: Result<URL, Error>) -> Void)) {
        if let existingDownloadItem = store.downloadItem(withURL: remoteURL) {
            os_log(.info, "Already downloading: %{public}@", remoteURL.absoluteString)

            existingDownloadItem.foregroundCompletionHandler = completionHandler
        } else {
            os_log(.info, "Scheduling to download: %{public}@", remoteURL.absoluteString)
            
            let downloadItem = BackgroundDownloadItem(remoteURL: remoteURL, localURL: localURL)
            downloadItem.foregroundCompletionHandler = completionHandler
            store.saveDownloadItem(downloadItem)
            
            let task = session.downloadTask(with: remoteURL)
            task.earliestBeginDate = Date().addingTimeInterval(2) // Remove this in production, the delay was added for demonstration purposes only
            task.resume()
        }
    }
}

// MARK: - URLSessionDelegate

extension BackgroundDownloadService: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            // needs to be called on the main queue
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloadService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let originalRequestURL = downloadTask.originalRequest?.url else {
            os_log(.error, "Unexpected nil URL")
            
            return
        }
        
        guard let existingDownloadItem = store.downloadItem(withURL: originalRequestURL) else {
            os_log(.error, "Unable to find existing download item for: %{public}@", originalRequestURL.absoluteString)
            
            return
        }
        
        os_log(.info, "Downloaded: %{public}@", originalRequestURL.absoluteString)
        
        do {
            try fileManager.moveItem(at: location, 
                                     to: existingDownloadItem.localURL)
            
            existingDownloadItem.foregroundCompletionHandler?(.success(existingDownloadItem.localURL))
        } catch {
            existingDownloadItem.foregroundCompletionHandler?(.failure(error))
        }
        
       store.deleteDownloadItem(existingDownloadItem)
    }
}
