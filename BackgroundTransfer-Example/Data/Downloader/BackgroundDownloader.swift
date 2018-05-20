//
//  BackgroundDownloader.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 02/05/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation
import UIKit

typealias ForegroundDownloadCompletionHandler = ((_ result: DataRequestResult<Data>) -> Void)

class BackgroundDownloader: NSObject {
    
    var foregroundCompletionHandler: ForegroundDownloadCompletionHandler?
    var backgroundCompletionHandler: (() -> Void)?
    
    private let sessionIdentifier: String
    private let fileManager = FileManager.default
    private var session: URLSession?
    
    // MARK: - Init
    
    init(sessionIdentifier: String = UUID().uuidString) {
        self.sessionIdentifier = sessionIdentifier
        
        super.init()
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        sessionConfiguration.isDiscretionary = false
        sessionConfiguration.sessionSendsLaunchEvents = true
        
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Download
    
    func download(remoteLocation: URL, localStorageLocation: URL, completionHandler: @escaping ForegroundDownloadCompletionHandler) {
        self.foregroundCompletionHandler = completionHandler
        
        print("Scheduling to download: \(remoteLocation)")
        
        BackgroundDownloadItem.save(intoStorageWithSessionIdentifier: sessionIdentifier, remoteLocation: remoteLocation, localStorageLocation: localStorageLocation)
        
        let task = session?.downloadTask(with: remoteLocation)
        task?.earliestBeginDate = Date().addingTimeInterval(25)
        task?.resume()
    }
}

extension BackgroundDownloader: URLSessionDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
            
            self.session?.finishTasksAndInvalidate() // needed as session delegate is strong rather than the usual weak
        }
    }
}

extension BackgroundDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let sessionIdentifier = session.configuration.identifier, let backgroundDownloadItem = BackgroundDownloadItem.load(fromStorageWithSessionIdentifier: sessionIdentifier) else {
                foregroundCompletionHandler?(.failure(APIError.invalidData))
                return
            }
            
            print("Completing download of: \(backgroundDownloadItem.remoteLocation)")

            let data = try Data(contentsOf: location)
            try fileManager.moveItem(at: location, to: backgroundDownloadItem.localStorageLocation)
            
            foregroundCompletionHandler?(.success(data))
        } catch {
            foregroundCompletionHandler?(.failure(APIError.invalidData))
        }
        
        session.finishTasksAndInvalidate() // needed as session delegate is strong rather than the usual weak
    }
}
