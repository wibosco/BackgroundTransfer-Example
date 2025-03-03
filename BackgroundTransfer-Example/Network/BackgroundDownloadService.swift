//
//  BackgroundDownloadService.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 02/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation
import os

enum BackgroundDownloadServiceError: Error {
    case missingInstructionsError
    case fileSystemError(_ underlyingError: Error)
    case networkError(_ underlyingError: Error)
    case unknownError
}

class BackgroundDownloadService: NSObject {
    var backgroundCompletionHandler: (() -> Void)?
    
    private var session: URLSession!
    
    private var foregroundCompletionHandlers = [String: ((result: Result<URL, BackgroundDownloadServiceError>) -> ())]()
    
    private var userDefaults = UserDefaults.standard
    
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
                  completionHandler: @escaping ((_ result: Result<URL, BackgroundDownloadServiceError>) -> ())) {
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

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloadService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        queue.sync {
            guard let originalRequestURL = downloadTask.originalRequest?.url?.absoluteString else {
                os_log(.error, "Unexpected nil URL")
                // Unable to call the closure here as we use originalRequestURL as the key to retrieve the closure
                
                return
            }
            
            defer {
                self.foregroundCompletionHandlers[originalRequestURL] = nil
                self.userDefaults.removeObject(forKey: originalRequestURL)
            }
            
            os_log(.info, "Downloaded: %{public}@", originalRequestURL)
            
            let foregroundCompletionHandler = self.foregroundCompletionHandlers[originalRequestURL]
            
            guard let saveDownloadToURL = self.userDefaults.url(forKey: originalRequestURL) else {
                os_log(.error, "Unable to find existing download item for: %{public}@", originalRequestURL)
                foregroundCompletionHandler?(.failure(.missingInstructionsError))
                
                return
            }
            
            do {
                try FileManager.default.moveItem(at: location,
                                                 to: saveDownloadToURL)
                
                foregroundCompletionHandler?(.success(saveDownloadToURL))
            } catch {
                foregroundCompletionHandler?(.failure(.fileSystemError(error)))
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        queue.async { [weak self] in
            guard let originalRequestURL = task.originalRequest?.url?.absoluteString else {
                os_log(.error, "Unexpected nil URL")
                
                return
            }
            
            defer {
                self?.foregroundCompletionHandlers[originalRequestURL] = nil
                self?.userDefaults.removeObject(forKey: originalRequestURL)
            }
            
            os_log(.info, "Download failed for: %{public}@", originalRequestURL)
            
            let foregroundCompletionHandler = self?.foregroundCompletionHandlers[originalRequestURL]
            
            guard let error = error else {
                os_log(.error, "Unknown error caused download to fail for: %{public}@", originalRequestURL)
                foregroundCompletionHandler?(.failure(.unknownError))
                
                return
            }
            
            foregroundCompletionHandler?(.failure(.networkError(error)))
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            // needs to be called on the main queue
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}
