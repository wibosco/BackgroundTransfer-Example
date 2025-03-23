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
    case clientError(_ underlyingError: Error)
    case serverError(_ underlyingResponse: URLResponse?)
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
            // Unable to call the closure here as we use fromURL as the key to retrieve the closure
            return
        }
        
        let fromURLAsString = fromURL.absoluteString
        
        os_log(.info, "Download request completed for: %{public}@", fromURLAsString)
        
        let tempLocation = FileManager.default.temporaryDirectory.appendingPathComponent(location.lastPathComponent)
        try? FileManager.default.moveItem(at: location,
                                          to: tempLocation)
        
        store.retrieveMetadata(for: fromURL) { [weak self] toURL, completionHandler in
            defer {
                self?.store.removeMetadata(for: fromURL)
            }
            
            guard let toURL else {
                os_log(.error, "Unable to find existing download item for: %{public}@", fromURLAsString)
                completionHandler?(.failure(BackgroundDownloadError.missingInstructionsError))
                return
            }
            
            guard let response = downloadTask.response as? HTTPURLResponse, 
                        response.statusCode == 200 else {
                os_log(.error, "Unexpected response for: %{public}@", fromURLAsString)
                completionHandler?(.failure(BackgroundDownloadError.serverError(downloadTask.response)))
                return
            }
            
            os_log(.info, "Download successful for: %{public}@", fromURLAsString)
            
            do {
                try FileManager.default.moveItem(at: tempLocation,
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
        
        let fromURLAsString = fromURL.absoluteString
        
        os_log(.info, "Download failed for: %{public}@", fromURLAsString)
        
        store.retrieveMetadata(for: fromURL) { [weak self] _, completionHandler in
            completionHandler?(.failure(BackgroundDownloadError.clientError(error)))
            
            self?.store.removeMetadata(for: fromURL)
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
