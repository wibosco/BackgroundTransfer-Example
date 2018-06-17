//
//  BackgroundDownloader.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 02/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation
import UIKit

typealias ForegroundDownloadCompletionHandler = ((_ result: DataRequestResult<URL>) -> Void)

class BackgroundDownloader: NSObject {
    
    private var foregroundCompletionHandlers: [URL: ForegroundDownloadCompletionHandler] = [:]
    var backgroundCompletionHandler: (() -> Void)?
    
    private let sessionIdentifier = "background.session"
    private let fileManager = FileManager.default
    private var session: URLSession?
    
    // MARK: - Singleton
    
    static let shared = BackgroundDownloader()
    
    // MARK: - Init
    
    private override init() {
        super.init()
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        sessionConfiguration.isDiscretionary = false
        sessionConfiguration.sessionSendsLaunchEvents = true
        
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Download
    
    func download(remoteLocation: URL, localStorageLocation: URL, completionHandler: @escaping ForegroundDownloadCompletionHandler){
        if foregroundCompletionHandlers[remoteLocation] != nil {
            print("Already downloading: \(remoteLocation)")
            foregroundCompletionHandlers[remoteLocation] = completionHandler
        } else {
            print("Scheduling to download: \(remoteLocation)")
        
            foregroundCompletionHandlers[remoteLocation] = completionHandler
            guard let session = session else {
                return
            }
            
            let task = session.downloadTask(with: remoteLocation)
            BackgroundDownloadItem.save(intoStorageWithTaskIdentifier: task.taskIdentifier, remoteLocation: remoteLocation, localStorageLocation: localStorageLocation)
            task.earliestBeginDate = Date().addingTimeInterval(20)
            task.resume()
        }
    }
}

extension BackgroundDownloader: URLSessionDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}

extension BackgroundDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let originalRequestURL = downloadTask.originalRequest?.url else {
            return
        }
        
        let foregroundCompletionHandler = foregroundCompletionHandlers[originalRequestURL]
        guard let backgroundDownloadItem = BackgroundDownloadItem.load(fromStorageWithTaskIdentifier: downloadTask.taskIdentifier) else {
            foregroundCompletionHandler?(.failure(APIError.invalidData))
            return
        }
        
        print("Downloaded: \(backgroundDownloadItem.remoteLocation)")
        
        do {
            try fileManager.moveItem(at: location, to: backgroundDownloadItem.localStorageLocation)
            
            foregroundCompletionHandler?(.success(backgroundDownloadItem.localStorageLocation))
        } catch {
            foregroundCompletionHandler?(.failure(APIError.invalidData))
        }
        
        foregroundCompletionHandlers[originalRequestURL] = nil
    }
}
