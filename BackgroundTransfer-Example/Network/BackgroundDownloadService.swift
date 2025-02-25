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
    
    private var session: URLSession!
    
    private let fileManager = FileManager.default
    private var userDefaults = UserDefaults.standard
    
    private var foregroundCompletionHandlers = [String: ((result: Result<URL, Error>) -> ())]()
    
    private let queue = DispatchQueue(label: "com.williamboles.background.download.service")
    
    // MARK: - Singleton
    
    static let shared = BackgroundDownloadService()
    
    // MARK: - Init
    
    private override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.williamboles.background.download.session")
        configuration.sessionSendsLaunchEvents = true
        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: nil)
        self.session = session
    }
    
    // MARK: - Download
    
    func download(from remoteURL: URL,
                  saveDownloadTo localURL: URL,
                  completionHandler: @escaping ((_ result: Result<URL, Error>) -> ())) {
        queue.async { [weak self] in
            os_log(.info, "Scheduling to download: %{public}@", remoteURL.absoluteString)
            
            self?.foregroundCompletionHandlers[remoteURL.absoluteString] = completionHandler
            self?.userDefaults.set(localURL, forKey: remoteURL.absoluteString)
            
            let task = self?.session.downloadTask(with: remoteURL)
            task?.earliestBeginDate = Date().addingTimeInterval(2) // Remove this in production, the delay was added for demonstration purposes only
            task?.resume()
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
        queue.sync { [weak self] in
            guard let originalRequestURL = downloadTask.originalRequest?.url?.absoluteString else {
                os_log(.error, "Unexpected nil URL")
                
                return
            }
            
            os_log(.info, "Downloaded: %{public}@", originalRequestURL)
            
            guard let saveDownloadToURL = self?.userDefaults.url(forKey: originalRequestURL) else {
                os_log(.error, "Unable to find existing download item for: %{public}@", originalRequestURL)
                
                return
            }
            
            do {
                try self?.fileManager.moveItem(at: location,
                                               to: saveDownloadToURL)
                
                self?.foregroundCompletionHandlers[originalRequestURL]?(.success(saveDownloadToURL))
            } catch {
                self?.foregroundCompletionHandlers[originalRequestURL]?(.failure(error))
            }
            
            self?.userDefaults.removeObject(forKey: originalRequestURL)
        }
    }
}
