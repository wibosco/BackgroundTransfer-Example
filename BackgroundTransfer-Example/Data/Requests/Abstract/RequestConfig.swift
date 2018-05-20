//
//  RequestConfig.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

enum HTTPRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

class RequestConfig {
    
    static let shared = RequestConfig()
    
    // MARK: - Client
    
    lazy var clientID: String = {
        let clientID = ""
        assert(!clientID.isEmpty, "You need to provide a clientID hash, you get this from [insert imgur url]")
        return clientID
    }()
    
    // MARK: - Networking
    
    lazy var APIHost: String = {
        return "https://api.imgur.com/3"
    }()
    
    lazy var timeInterval: TimeInterval = {
        return 45
    }()
    
    lazy var cachePolicy: NSURLRequest.CachePolicy = {
        return .useProtocolCachePolicy
    }()
}
