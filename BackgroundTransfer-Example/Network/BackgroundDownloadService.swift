//
//  BackgroundDownloadService.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 02/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation
import os

enum BackgroundDownloadError: Error {
    case missingInstructionsError
    case fileSystemError(_ underlyingError: Error)
    case networkError(_ underlyingError: Error?)
    case unexpectedResponseError
    case unexpectedStatusCode
}

class BackgroundDownloadService: NSObject {
    var backgroundCompletionHandler: (() -> Void)?
    
    private var session: URLSession!
    private let store = BackgroundDownloadStore()
    
    // MARK: - Singleton
    
    static let shared = BackgroundDownloadService()
    
    // MARK: - Init
    
    override init() {
        super.init()
        
        configureSession()
    }
    
    private func configureSession() {
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
                  completionHandler: @escaping BackgroundDownloadCompletion) {
        os_log(.info, "Scheduling to download: %{public}@", remoteURL.absoluteString)
        
        store.storeMetadata(from: remoteURL,
                            to: localURL,
                            completionHandler: completionHandler)

        let task = session.downloadTask(with: remoteURL)
        task.earliestBeginDate = Date().addingTimeInterval(2) // Remove this in production, the delay was added for demonstration purposes only
        task.resume()
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloadService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let fromURL = downloadTask.originalRequest?.url else {
            os_log(.error, "Unexpected nil URL")
            // Unable to call the closure here as we use originalRequestURL as the key to retrieve the closure
            return
        }
        
        defer {
            store.removeMetadata(for: fromURL)
        }
        
        let fromURLAbsoluteString = fromURL.absoluteString
        
        os_log(.info, "Download request completed for: %{public}@", fromURLAbsoluteString)
        
        store.retrieveMetadata(for: fromURL) { toURL, completionHandler in
            guard let toURL else {
                os_log(.error, "Unable to find existing download item for: %{public}@", fromURLAbsoluteString)
                completionHandler?(.failure(BackgroundDownloadError.missingInstructionsError))
                return
            }
            
            guard let response = downloadTask.response as? HTTPURLResponse else {
                os_log(.error, "Unexpected response for: %{public}@", fromURLAbsoluteString)
                completionHandler?(.failure(BackgroundDownloadError.unexpectedResponseError))
                return
            }
            
            guard response.statusCode == 200 else {
                os_log(.error, "Unexpected status code of: %{public}d, for: %{public}@", response.statusCode, fromURLAbsoluteString)
                completionHandler?(.failure(BackgroundDownloadError.unexpectedStatusCode))
                return
            }
            
            os_log(.info, "Download successful for: %{public}@", fromURLAbsoluteString)
            
            do {
                try FileManager.default.moveItem(at: location,
                                                 to: toURL)
                
                completionHandler?(.success(toURL))
            } catch {
                completionHandler?(.failure(BackgroundDownloadError.fileSystemError(error)))
            }
        }
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let error = error else {
            return
        }
        
        guard let fromURL = task.originalRequest?.url else {
            os_log(.error, "Unexpected nil URL")
            return
        }
        
        defer {
            store.removeMetadata(for: fromURL)
        }
        
        let fromURLAbsoluteString = fromURL.absoluteString
        
        os_log(.info, "Download failed for: %{public}@", fromURLAbsoluteString)
        
        store.retrieveMetadata(for: fromURL) { _, completionHandler in
            completionHandler?(.failure(BackgroundDownloadError.networkError(error)))
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
