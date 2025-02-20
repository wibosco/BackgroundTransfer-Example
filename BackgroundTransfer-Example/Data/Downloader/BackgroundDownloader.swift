//
//  BackgroundDownloader.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 02/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation
import os

class BackgroundDownloader: NSObject {
    var backgroundCompletionHandler: (() -> Void)?
    
    private let fileManager = FileManager.default
    private let context = BackgroundDownloaderContext()
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "background.download.session")
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    // MARK: - Singleton
    
    static let shared = BackgroundDownloader()
    
    // MARK: - Download
    
    func download(remoteURL: URL, filePathURL: URL, completionHandler: @escaping ForegroundDownloadCompletionHandler) {
        if let downloadItem = context.loadDownloadItem(withURL: remoteURL) {
            os_log(.info, "Already downloading: %{public}@", remoteURL.absoluteString)
            downloadItem.foregroundCompletionHandler = completionHandler
        } else {
            os_log(.info, "Scheduling to download: %{public}@", remoteURL.absoluteString)
            
            let downloadItem = DownloadItem(remoteURL: remoteURL, filePathURL: filePathURL)
            downloadItem.foregroundCompletionHandler = completionHandler
            context.saveDownloadItem(downloadItem)
            
            let task = session.downloadTask(with: remoteURL)
            task.earliestBeginDate = Date().addingTimeInterval(20) // Added a delay for demonstration purposes only
            task.resume()
        }
    }
}

// MARK: - URLSessionDelegate

extension BackgroundDownloader: URLSessionDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let originalRequestURL = downloadTask.originalRequest?.url, let downloadItem = context.loadDownloadItem(withURL: originalRequestURL) else {
            return
        }
    
        print("Downloaded: \(downloadItem.remoteURL)")
        
        do {
            try fileManager.moveItem(at: location, to: downloadItem.filePathURL)
            
            downloadItem.foregroundCompletionHandler?(.success(downloadItem.filePathURL))
        } catch {
            downloadItem.foregroundCompletionHandler?(.failure(APIError.invalidData))
        }
        
       context.deleteDownloadItem(downloadItem)
    }
}
